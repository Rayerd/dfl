// Written by Christopher E. Miller
// See the included license.txt for copyright and license details.


///
module dfl.socket;


version(Tango)
{
	version(DFL_TangoNetDeviceBerkeley)
	{
		version = _DFL_TangoBerkeleySocket;
	}
	else version(Old)
	{
		version = _DFL_TangoHasOldSocket;
	}
	else
	{
		version = _DFL_TangoSocketConduit;
	}
}


version(WINE)
{
	version = DFL_NoSocket;
}


version(DFL_NoSocket)
{
}
else
{

private import dfl.internal.dlib, dfl.internal.clib;

private
{
	version(Tango)
	{
		
		version(_DFL_TangoBerkeleySocket)
		{
			private import std.intrinsic;
			private import tango.net.device.Berkeley;
			
			alias NetHost DInternetHost;
			alias IPv4Address DInternetAddress;
			
			socket_t getSocketHandle(DflSocket sock)
			{
				return sock.fileHandle;
			}
		}
		else version(_DFL_TangoHasOldSocket)
		{
			private import std.intrinsic;
			private import tango.net.Socket;
			
			alias NetHost DInternetHost;
			alias IPv4Address DInternetAddress;
			
			socket_t getSocketHandle(DflSocket sock)
			{
				return sock.fileHandle;
			}
		}
		else version(_DFL_TangoSocketConduit)
		{
			private import std.intrinsic;
			private import tango.net.device.Socket;
			private import tango.net.device.Berkeley;
			
			alias NetHost DInternetHost;
			alias IPv4Address DInternetAddress;
			
			socket_t getSocketHandle(DflSocket sock)
			{
				return sock.native.handle;
			}
		}
		
	}
	else
	{
		private import std.socket, std.intrinsic;
		private import std.c.windows.winsock;
		
		alias InternetHost DInternetHost;
		alias InternetAddress DInternetAddress;
		
		socket_t getSocketHandle(Socket sock)
		{
			return sock.handle;
		}
	}
}

version(Tango)
{
	version(_DFL_TangoBerkeleySocket)
	{
		class DflSocket ///
		{
			Berkeley berkeley;
			
			package this()
			{
			}
			
			this(AddressFamily family, SocketType type, ProtocolType protocol, bool create = true)
			{
				berkeley.open(family, type, protocol, create);
			}
			
			socket_t handle()
			{
				return berkeley.handle();
			}
			
			socket_t fileHandle()
			{
				return berkeley.handle();
			}
			
			bool isAlive()
			{
				return berkeley.isAlive();
			}
			
			bool blocking() // getter
			{
				return berkeley.blocking();
			}
			
			void blocking(bool byes) // setter
			{
				berkeley.blocking(byes);
			}
			
			DflSocket bind(Address addr)
			{
				berkeley.bind(addr);
				return this;
			}
			
			DflSocket connect(Address to)
			{
				berkeley.connect(to);
				return this;
			}
			
			DflSocket listen (int backlog)
			{
				berkeley.listen(backlog);
				return this;
			}
			
			DflSocket accept()
			{
				return accept(new DflSocket());
			}
			
			DflSocket accept(DflSocket sock)
			{
				berkeley.accept(sock.berkeley);
				return sock;
			}
			
			void initialize(socket_t sock = socket_t.init)
			{
				berkeley.reopen(sock);
			}
			
			void reopen(socket_t sock = socket_t.init)
			{
				initialize(sock);
			}
			
			DflSocket shutdown(SocketShutdown how)
			{
				berkeley.shutdown(how);
				return this;
			}
			
			Address remoteAddress()
			{
				return berkeley.remoteAddress();
			}
			
			Address localAddress()
			{
				return berkeley.localAddress();
			}
			
			void detach()
			{
				berkeley.detach();
			}
			
			const int ERROR = Berkeley.ERROR;
			
			int send(void[] buf, SocketFlags flags = SocketFlags.NONE)
			{
				return berkeley.send(buf, flags);
			}
			
			int sendTo(void[] buf, SocketFlags flags, Address to)
			{
				return berkeley.sendTo(buf, flags, to);
			}
			
			int sendTo(void[] buf, Address to)
			{
				return berkeley.sendTo(buf, to);
			}
			
			int sendTo(void[] buf, SocketFlags flags = SocketFlags.NONE)
			{
				return berkeley.sendTo(buf, flags);
			}
			
			int receive(void[] buf, SocketFlags flags = SocketFlags.NONE)
			{
				return berkeley.receive(buf, flags);
			}
			
			int receiveFrom(void[] buf, SocketFlags flags, Address from)
			{
				return berkeley.receiveFrom(buf, flags, from);
			}
			
			int receiveFrom(void[] buf, Address from)
			{
				return berkeley.receiveFrom(buf, from);
			}
			
			int receiveFrom(void[] buf, SocketFlags flags = SocketFlags.NONE)
			{
				return berkeley.receiveFrom(buf, flags);
			}
			
			int getOption(SocketOptionLevel level, SocketOption option, void[] result)
			{
				return berkeley.getOption(level, option, result);
			}
			
			DflSocket setOption(SocketOptionLevel level, SocketOption option, void[] value)
			{
				berkeley.setOption(level, option, value);
				return this;
			}
			
			DflSocket linger(int period)
			{
				berkeley.linger(period);
				return this;
			}
			
			DflSocket addressReuse(bool enabled)
			{
				berkeley.addressReuse(enabled);
				return this;
			}
			
			DflSocket noDelay(bool enabled)
			{
				berkeley.noDelay(enabled);
				return this;
			}
			
			
		}
	}
	else version(_DFL_TangoHasOldSocket)
	{
		
		alias tango.net.Socket.Socket DflSocket; ///
		
	}
	else version(_DFL_TangoSocketConduit)
	{
		
		alias tango.net.device.Socket.Socket DflSocket; ///
		
	}
}
else
{
	alias std.socket.Socket DflSocket; ///
}

private import dfl.internal.winapi, dfl.application, dfl.base, dfl.internal.utf;


private
{
	enum
	{
		FD_READ =       0x01,
		FD_WRITE =      0x02,
		FD_OOB =        0x04,
		FD_ACCEPT =     0x08,
		FD_CONNECT =    0x10,
		FD_CLOSE =      0x20,
		FD_QOS =        0x40,
		FD_GROUP_QOS =  0x80,
	}
	
	
	extern(Windows) int WSAAsyncSelect(socket_t s, HWND hWnd, UINT wMsg, int lEvent);
}


///
// Can be OR'ed.
enum EventType
{
	NONE = 0, ///
	
	READ =       FD_READ, /// ditto
	WRITE =      FD_WRITE, /// ditto
	OOB =        FD_OOB, /// ditto
	ACCEPT =     FD_ACCEPT, /// ditto
	CONNECT =    FD_CONNECT, /// ditto
	CLOSE =      FD_CLOSE, /// ditto
	
	QOS =        FD_QOS,
	GROUP_QOS =  FD_GROUP_QOS,
}


///
// -err- will be 0 if no error.
// -type- will always contain only one flag.
alias void delegate(DflSocket sock, EventType type, int err) RegisterEventCallback;


// Calling this twice on the same socket cancels out previously
// registered events for the socket.
// Requires Application.run() or Application.doEvents() loop.
void registerEvent(DflSocket sock, EventType events, RegisterEventCallback callback) // deprecated
{
	assert(sock !is null, "registerEvent: socket cannot be null");
	assert(callback !is null, "registerEvent: callback cannot be null");
	
	if(!hwNet)
		_init();
	
	version(Tango)
	{
		version(_DFL_TangoBerkeleySocket)
		{
			sock.blocking = false; // So the getter will be correct.
		}
		else version(_DFL_TangoHasOldSocket)
		{
			sock.blocking = false; // So the getter will be correct.
		}
	}
	else
	{
		sock.blocking = false; // So the getter will be correct.
	}
	
	// SOCKET_ERROR
	if(-1 == WSAAsyncSelect(getSocketHandle(sock), hwNet, WM_DFL_NETEVENT, cast(int)events))
		throw new DflException("Unable to register socket events");
	
	EventInfo ei;
	
	ei.sock = sock;
	ei.callback = callback;
	allEvents[getSocketHandle(sock)] = ei;
}


void unregisterEvent(DflSocket sock) // deprecated
{
	WSAAsyncSelect(getSocketHandle(sock), hwNet, 0, 0);
	
	//delete allEvents[getSocketHandle(sock)];
	allEvents.remove(getSocketHandle(sock));
}


///
class AsyncSocket: DflSocket // docmain
{
	///
	this(AddressFamily af, SocketType type, ProtocolType protocol)
	{
		super(af, type, protocol);
		version(_DFL_TangoSocketConduit)
		{
			this.native.blocking = false;
		}
		else
		{
			super.blocking = false;
		}
	}
	
	version(Tango)
	{
		version(_DFL_TangoSocketConduit)
		{
			
			this()
			{
				super();
				this.native.blocking = false;
			}
			
		}
	}
	else
	{
		/// ditto
		this(AddressFamily af, SocketType type)
		{
			super(af, type);
			super.blocking = false;
		}
		
		/// ditto
		this(AddressFamily af, SocketType type, Dstring protocolName)
		{
			super(af, type, protocolName);
			super.blocking = false;
		}
	}
	
	version(_DFL_TangoSocketConduit)
	{
	}
	else
	{
		/// ditto
		// For use with accept().
		protected this()
		{
		}
	}
	
	
	///
	void event(EventType events, RegisterEventCallback callback)
	{
		registerEvent(this, events, callback);
	}
	
	
	version(Tango)
	{
		version(_DFL_TangoBerkeleySocket)
		{
			override DflSocket accept()
			{
				return accept(new AsyncSocket());
			}
			
			DflSocket accept(AsyncSocket sock)
			{
				return super.accept(sock);
			}
		}
	}
	else
	{
		protected override AsyncSocket accepting()
		{
			return new AsyncSocket;
		}
	}
	
	
	version(Tango)
	{
		override void detach()
		{
			unregisterEvent(this);
			super.detach();
		}
	}
	else
	{
		override void close()
		{
			unregisterEvent(this);
			super.close();
		}
	}
	
	
	version(_DFL_TangoSocketConduit)
	{
	}
	else
	{
		override bool blocking() // getter
		{
			return false;
		}
		
		
		override void blocking(bool byes) // setter
		{
			if(byes)
				assert(0);
		}
	}
	
}


///
class AsyncTcpSocket: AsyncSocket // docmain
{
	///
	this(AddressFamily family)
	{
		super(family, SocketType.STREAM, ProtocolType.TCP);
	}
	
	/// ditto
	this()
	{
		this(cast(AddressFamily)AddressFamily.INET);
	}
	
	/// ditto
	// Shortcut.
	this(Address connectTo, EventType events, RegisterEventCallback eventCallback)
	{
		this(connectTo.addressFamily());
		event(events, eventCallback);
		connect(connectTo);
	}
}


///
class AsyncUdpSocket: AsyncSocket // docmain
{
	///
	this(AddressFamily family)
	{
		super(family, SocketType.DGRAM, ProtocolType.UDP);
	}
	
	/// ditto
	this()
	{
		this(cast(AddressFamily)AddressFamily.INET);
	}
}


/+
private class GetHostWaitHandle: WaitHandle
{
	this(HANDLE h)
	{
		super.handle = h;
	}
	
	
	final:
	
	alias WaitHandle.handle handle; // Overload.
	
	override void handle(HANDLE h) // setter
	{
		assert(0);
	}
	
	override void close()
	{
		WSACancelAsyncRequest(handle);
		super.handle = INVALID_HANDLE;
	}
	
	
	private void _gotEvent()
	{
		super.handle = INVALID_HANDLE;
	}
}


private class GetHostAsyncResult, IAsyncResult
{
	this(HANDLE h, GetHostCallback callback)
	{
		wh = new GetHostWaitHandle(h);
		this.callback = callback;
	}
	
	
	WaitHandle asyncWaitHandle() // getter
	{
		return wh;
	}
	
	
	bool completedSynchronously() // getter
	{
		return false;
	}
	
	
	bool isCompleted() // getter
	{
		return wh.handle != WaitHandle.INVALID_HANDLE;
	}
	
	
	private:
	GetHostWaitHandle wh;
	GetHostCallback callback;
	
	
	void _gotEvent(LPARAM lparam)
	{
		wh._gotEvent();
		
		callback(bla, HIWORD(lparam));
	}
}
+/


private void _getHostErr()
{
	throw new DflException("Get host failure"); // Needs a better message.. ?
}


private class _InternetHost: DInternetHost
{
	private:
	this(void* hostentBytes)
	{
		super.validHostent(cast(hostent*)hostentBytes);
		super.populate(cast(hostent*)hostentBytes);
	}
}


///
// If -err- is nonzero, it is a winsock error code and -inetHost- is null.
alias void delegate(DInternetHost inetHost, int err) GetHostCallback;


///
class GetHost // docmain
{
	///
	void cancel()
	{
		WSACancelAsyncRequest(h);
		h = null;
	}
	
	
	private:
	HANDLE h;
	GetHostCallback callback;
	ubyte[/+MAXGETHOSTSTRUCT+/ 1024] hostentBytes;
	
	
	void _gotEvent(LPARAM lparam)
	{
		h = null;
		
		int err;
		err = HIWORD(lparam);
		if(err)
			callback(null, err);
		else
			callback(new _InternetHost(hostentBytes.ptr), 0);
	}
	
	
	this()
	{
	}
}


///
GetHost asyncGetHostByName(Dstring name, GetHostCallback callback) // docmain
{
	if(!hwNet)
		_init();
	
	HANDLE h;
	GetHost result;
	
	result = new GetHost;
	h = WSAAsyncGetHostByName(hwNet, WM_DFL_HOSTEVENT, unsafeStringz(name),
		cast(char*)result.hostentBytes, result.hostentBytes.length);
	if(!h)
		_getHostErr();
	
	result.h = h;
	result.callback = callback;
	allGetHosts[h] = result;
	
	return result;
}


///
GetHost asyncGetHostByAddr(uint32_t addr, GetHostCallback callback) // docmain
{
	if(!hwNet)
		_init();
	
	HANDLE h;
	GetHost result;
	
	result = new GetHost;
	version(LittleEndian)
		addr = bswap(addr);
	h = WSAAsyncGetHostByAddr(hwNet, WM_DFL_HOSTEVENT, cast(char*)&addr, addr.sizeof,
		AddressFamily.INET, cast(char*)result.hostentBytes, result.hostentBytes.length);
	if(!h)
		_getHostErr();
	
	result.h = h;
	result.callback = callback;
	allGetHosts[h] = result;
	
	return result;
}

/// ditto
// Shortcut.
GetHost asyncGetHostByAddr(Dstring addr, GetHostCallback callback) // docmain
{
	uint uiaddr;
	uiaddr = DInternetAddress.parse(addr);
	if(DInternetAddress.ADDR_NONE == uiaddr)
		_getHostErr();
	return asyncGetHostByAddr(uiaddr, callback);
}


///
class SocketQueue // docmain
{
	///
	this(DflSocket sock)
	in
	{
		assert(sock !is null);
	}
	body
	{
		this.sock = sock;
	}
	
	
	///
	final DflSocket socket() // getter
	{
		return sock;
	}
	
	
	///
	void reset()
	{
		writebuf = null;
		readbuf = null;
	}
	
	
	/+
	// DMD 0.92 says error: function toString overrides but is not covariant with toString
	override Dstring toString()
	{
		return cast(Dstring)peek();
	}
	+/
	
	
	///
	void[] peek()
	{
		return readbuf[0 .. rpos];
	}
	
	/// ditto
	void[] peek(uint len)
	{
		if(len >= rpos)
			return peek();
		
		return readbuf[0 .. len];
	}
	
	
	///
	void[] receive()
	{
		ubyte[] result;
		
		result = readbuf[0 .. rpos];
		readbuf = null;
		rpos = 0;
		
		return result;
	}
	
	/// ditto
	void[] receive(uint len)
	{
		if(len >= rpos)
			return receive();
		
		ubyte[] result;
		
		result = readbuf[0 .. len];
		readbuf = readbuf[len .. readbuf.length];
		rpos -= len;
		
		return result;
	}
	
	
	///
	void send(void[] buf)
	{
		if(canwrite)
		{
			assert(!writebuf.length);
			
			int st;
			if(buf.length > 4096)
				st = 4096;
			else
				st = buf.length;
			
			version(_DFL_TangoSocketConduit)
			{
				st = sock.write(buf[0 .. st]);
			}
			else
			{
				st = sock.send(buf[0 .. st]);
			}
			if(st > 0)
			{
				if(buf.length - st)
				{
					// dup so it can be appended to.
					writebuf = (cast(ubyte[])buf)[st .. buf.length].dup;
				}
			}
			else
			{
				// dup so it can be appended to.
				writebuf = (cast(ubyte[])buf).dup;
			}
			
			//canwrite = false;
		}
		else
		{
			writebuf ~= cast(ubyte[])buf;
		}
	}
	
	
	///
	// Number of bytes in send queue.
	uint sendBytes() // getter
	{
		return writebuf.length;
	}
	
	
	///
	// Number of bytes in recv queue.
	uint receiveBytes() // getter
	{
		return rpos;
	}
	
	
	///
	// Same signature as RegisterEventCallback for simplicity.
	void event(DflSocket _sock, EventType type, int err)
	in
	{
		assert(_sock is sock);
	}
	body
	{
		switch(type)
		{
			case EventType.READ:
				readEvent();
				break;
			
			case EventType.WRITE:
				writeEvent();
				break;
			
			default: ;
		}
	}
	
	
	///
	// Call on a read event so that incoming data may be buffered.
	void readEvent()
	{
		if(readbuf.length - rpos < 1024)
			readbuf.length = readbuf.length + 2048;
		
		version(_DFL_TangoSocketConduit)
		{
			int rd = sock.read(readbuf[rpos .. readbuf.length]);
		}
		else
		{
			int rd = sock.receive(readbuf[rpos .. readbuf.length]);
		}
		if(rd > 0)
			rpos += cast(uint)rd;
	}
	
	
	///
	// Call on a write event so that buffered outgoing data may be sent.
	void writeEvent()
	{
		if(writebuf.length)
		{
			ubyte[] buf;
			
			if(writebuf.length > 4096)
				buf = writebuf[0 .. 4096];
			else
				buf = writebuf;
			
			version(_DFL_TangoSocketConduit)
			{
				int st = sock.write(buf);
			}
			else
			{
				int st = sock.send(buf);
			}
			if(st > 0)
				writebuf = writebuf[st .. writebuf.length];
		}
		else
		{
			//canwrite = true;
		}
	}
	
	
	deprecated
	{
		alias receiveBytes recvBytes;
		alias receive recv;
	}
	
	
	private:
	ubyte[] writebuf;
	ubyte[] readbuf;
	uint rpos;
	DflSocket sock;
	//bool canwrite = false;
	
	
	bool canwrite() // getter
	{
		return writebuf.length == 0;
	}
}


private:

struct EventInfo
{
	DflSocket sock;
	RegisterEventCallback callback;
}


const UINT WM_DFL_NETEVENT = WM_USER + 104;
const UINT WM_DFL_HOSTEVENT = WM_USER + 105;
const Dstring NETEVENT_CLASSNAME = "DFL_NetEvent";

EventInfo[socket_t] allEvents;
GetHost[HANDLE] allGetHosts;
HWND hwNet;


extern(Windows) LRESULT netWndProc(HWND hwnd, UINT msg, WPARAM wparam, LPARAM lparam)
{
	switch(msg)
	{
		case WM_DFL_NETEVENT:
			if(cast(socket_t)wparam in allEvents)
			{
				EventInfo ei = allEvents[cast(socket_t)wparam];
				ei.callback(ei.sock, cast(EventType)LOWORD(lparam), HIWORD(lparam));
			}
			break;
		
		case WM_DFL_HOSTEVENT:
			if(cast(HANDLE)wparam in allGetHosts)
			{
				GetHost gh;
				gh = allGetHosts[cast(HANDLE)wparam];
				assert(gh !is null);
				//delete allGetHosts[cast(HANDLE)wparam];
				allGetHosts.remove(cast(HANDLE)wparam);
				gh._gotEvent(lparam);
			}
			break;
		
		default: ;
	}
	
	return 1;
}


void _init()
{
	WNDCLASSEXA wce;
	wce.cbSize = wce.sizeof;
	wce.lpszClassName = NETEVENT_CLASSNAME.ptr;
	wce.lpfnWndProc = &netWndProc;
	wce.hInstance = GetModuleHandleA(null);
	
	if(!RegisterClassExA(&wce))
	{
		debug(APP_PRINT)
			cprintf("RegisterClassEx() failed for network event class.\n");
		
		init_err:
		throw new DflException("Unable to initialize asynchronous socket library");
	}
	
	hwNet = CreateWindowExA(0, NETEVENT_CLASSNAME.ptr, "", 0, 0, 0, 0, 0, HWND_MESSAGE, null, wce.hInstance, null);
	if(!hwNet)
	{
		// Guess it doesn't support HWND_MESSAGE, so just try null parent.
		
		hwNet = CreateWindowExA(0, NETEVENT_CLASSNAME.ptr, "", 0, 0, 0, 0, 0, null, null, wce.hInstance, null);
		if(!hwNet)
		{
			debug(APP_PRINT)
				cprintf("CreateWindowEx() failed for network event window.\n");
			
			goto init_err;
		}
	}
}

}

