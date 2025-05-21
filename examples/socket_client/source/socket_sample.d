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
	socket.event(
		SocketEventType.CONNECT | SocketEventType.READ | SocketEventType.CLOSE,
		(Socket sock, SocketEventType event, int err) {
			if (err != 0)
			{
				writeln("Socket error: ", err);
				return;
			}

			switch (event)
			{
			case SocketEventType.CONNECT:
				writeln("Connected!");
				// Send text after connected.
				sock.send("Hello from D client!".dup);
				break;

			case SocketEventType.READ:
				ubyte[1024] buf;
				auto len = sock.receive(buf[]);
				if (len > 0)
				{
					writeln("Received: ", cast(string)buf[0 .. len]);
				}
				break;

			case SocketEventType.CLOSE:
				writeln("Connection closed by server.");
				break;

			default:
				break;
			}
		}
	);

	// Start connect.
	socket.connect(address);

	// Event loop.
	Application.run();
}
