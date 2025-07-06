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
	// Create client socket.
	auto address = new InternetAddress("127.0.0.1", 12345);
	auto socket = new AsyncTcpSocket(address.addressFamily());

	// Register socket event for client.
	socket.connected ~= (AsyncSocket sock, AsyncSocketEventArgs ea) {
		if (ea.error != 0)
		{
			writeln("Socket error: ", ea.error);
			return;
		}
		writeln("Connected!");
		// Send text after connected.
		sock.send("Hello from D client!".dup);
		sock.send(" / Send messages from Client.".dup);
		sock.send(" / This is last message.".dup);
	};

	socket.read ~= (AsyncSocket sock, AsyncSocketEventArgs ea) {
		if (ea.error != 0)
		{
			writeln("Socket error: ", ea.error);
			return;
		}
		ubyte[1024] buf;
		ptrdiff_t len = sock.receive(buf[]);
		if (len > 0)
		{
			writeln("Received: ", cast(string)buf[0 .. len]);
		}
	};

	socket.closed ~= (AsyncSocket sock, AsyncSocketEventArgs ea) {
		if (ea.error != 0)
		{
			writeln("Socket error: ", ea.error);
			return;
		}
		writeln("Connection closed by server.");
	};

	socket.asyncSelect();

	// Start connect.
	socket.connect(address);

	// Event loop.
	Application.run();
}
