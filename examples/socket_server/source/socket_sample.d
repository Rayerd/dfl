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

// version = DONT_USE_SOCKET_QUEUE;

void main()
{
	// Create server socket.
	auto server = new AsyncTcpSocket(AddressFamily.INET);
	auto bindAddr = new InternetAddress("0.0.0.0", 12345);
	server.bind(bindAddr);
	server.listen(10);

	writeln("Server listening on port 12345...");

	// Register socket event for server.
	version (DONT_USE_SOCKET_QUEUE)
		registerSocketEvent1(server);
	else
		registerSocketEvent2(server);

	// Event loop.
	Application.run();
}

void registerSocketEvent1(AsyncSocket server)
{
	server.event(
		SocketEventType.ACCEPT,
		(Socket sock, SocketEventType event, int err) {
			if (err != 0)
			{
				writeln("Accept error: ", err);
				return;
			}

			// Get connected socket.
			AsyncTcpSocket client = cast(AsyncTcpSocket)sock.accept();
			writeln("Client connected: ", client.remoteAddress());

			// Register event for client.
			client.event(
				SocketEventType.READ | SocketEventType.CLOSE,
				(s, ev, e) {
					if (e != 0)
					{
						writeln("Client socket error: ", e);
						return;
					}

					switch (ev)
					{
					case SocketEventType.READ:
						ubyte[1024] buf;
						auto len = s.receive(buf[]);
						if (len > 0)
						{
							auto msg = cast(string)buf[0 .. len];
							writeln("Received from client: ", msg);

							// Echo
							s.send(buf[0 .. len]);
						}
						break;

					case SocketEventType.CLOSE:
						writeln("Client disconnected.");
						break;
					
					default:
						break;
					}
				}
			);
		}
	);
}

void registerSocketEvent2(AsyncSocket server)
{
	server.event(
		SocketEventType.ACCEPT,
		(Socket sock, SocketEventType event, int err) {
			if (err != 0)
			{
				writeln("Accept error: ", err);
				return;
			}

			// Get connected socket.
			AsyncTcpSocket client = cast(AsyncTcpSocket)sock.accept();
			writeln("Client connected: ", client.remoteAddress());

			// Register event for client.
			SocketQueue queue = new SocketQueue(client);
			client.event(
				SocketEventType.READ | SocketEventType.CLOSE,
				(Socket socket, SocketEventType event, int err) {
					queue.event(socket, event, err);

					if (event == SocketEventType.READ && queue.receiveBytes > 0)
					{
						auto msg = cast(string)queue.receive();
						writeln("Received from client: ", msg);

						// Echo
						queue.send(msg.dup);
					}
					else if (event == SocketEventType.CLOSE)
					{
						writeln("Client disconnected.");
					}
				}
			);
		}
	);
}
