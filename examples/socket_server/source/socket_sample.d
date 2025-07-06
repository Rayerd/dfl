import dfl.application;
import dfl.socket;
import std.stdio : writeln;

version (Have_dfl) // For DUB.
{
}
else
{
	pragma(lib, "dfl.lib");
}

void main()
{
	// Sample 1.
	GetHost host1 = asyncGetHostByName("localhost", (InternetHost inetHost, int err){
		if (err != 0)
		{
			writeln("GetHostByName error: ", err);
			return;
		}
		else
			writeln(inetHost.name);
	});
	
	// Sample 2.
	// 0x7F_00_00_01 is 127.0.0.1
	GetHost host2 = asyncGetHostByAddr(0x7F_00_00_01, (InternetHost inetHost, int err){
		if (err != 0)
		{
			writeln("GetHostByAddr error: ", err);
			return;
		}
		else
			writeln(inetHost.name);
	});

	// Sample 3.
	// Create server socket.
	auto server = new AsyncTcpSocket(AddressFamily.INET);
	auto bindAddr = new InternetAddress("0.0.0.0", 12345);
	server.bind(bindAddr);
	server.listen(10);

	writeln("Server listening on port 12345...");

	// Register socket event for server.
	// registerSocketEvent1(server);
	registerSocketEvent2(server);

	// Event loop.
	Application.run();
}

void registerSocketEvent1(AsyncSocket server)
{
	server.accepted ~= (AsyncSocket socket, AsyncSocketEventArgs sea) {
		if (sea.error != 0)
		{
			writeln("Accept error: ", sea.error);
			return;
		}

		// Get connected socket.
		AsyncSocket client = socket.accept();
		writeln("Client connected: ", client.remoteAddress());

		// Register event for client.
		client.read ~= (AsyncSocket socket, AsyncSocketEventArgs ea) {
			if (ea.error != 0)
			{
				writeln("Client socket error: ", ea.error);
				return;
			}
			enum BufferSize = 1024;
			ubyte[BufferSize] buf;
			ptrdiff_t len = socket.receive(buf[]);
			if (len > 0)
			{
				auto msg = cast(string)buf[0 .. len];
				writeln("Received from client: ", msg);

				// Echo.
				socket.send(buf[0 .. len]);
			}
		};
		
		client.written ~= (AsyncSocket sock, AsyncSocketEventArgs ea) {
			if (ea.error != 0)
			{
				writeln("Client socket error: ", ea.error);
				return;
			}
			writeln("Client done wrote.");
		};

		client.closed ~= (AsyncSocket socket, AsyncSocketEventArgs ea) {
			if (ea.error != 0)
			{
				writeln("Client socket error: ", ea.error);
				return;
			}
			writeln("Client disconnected.");
		};

		client.asyncSelect();
	};

	server.asyncSelect();
}

void registerSocketEvent2(AsyncSocket server)
{
	server.accepted ~= (AsyncSocket sock, AsyncSocketEventArgs sea) {
		if (sea.error != 0)
		{
			writeln("Accept error: ", sea.error);
			return;
		}

		// Get connected socket.
		AsyncTcpSocket client = cast(AsyncTcpSocket)sock.accept();
		writeln("Client connected: ", client.remoteAddress());

		// Register event for client.
		SocketQueue queue = new SocketQueue(client);

		client.read ~= (AsyncSocket sock, AsyncSocketEventArgs ea) {
			if (ea.error != 0)
			{
				writeln("Client socket error: ", ea.error);
				return;
			}
			queue.readEvent();
			if (queue.receiveBytes > 0)
			{
				auto msg = cast(string)queue.receive();
				writeln("Received from client: ", msg);

				// Echo.
				queue.send(msg.dup);
				// Forced write.
				queue.writeEvent();
			}
		};

		client.written ~= (AsyncSocket sock, AsyncSocketEventArgs ea) {
			if (ea.error != 0)
			{
				writeln("Client socket error: ", ea.error);
				return;
			}
			writeln("Client done wrote.");
		};

		client.closed ~= (AsyncSocket sock, AsyncSocketEventArgs ea) {
			if (ea.error != 0)
			{
				writeln("Client socket error: ", ea.error);
				return;
			}
			writeln("Client disconnected.");
		};

		client.asyncSelect();
	};

	server.asyncSelect();
}
