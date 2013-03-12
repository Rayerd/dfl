// Written by Christopher E. Miller
// See the included license.txt for copyright and license details.


///
module dfl.socket;


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
	private import std.socket, core.bitop;
	private import std.c.windows.winsock;
	
	alias InternetHost DInternetHost;
	alias InternetAddress DInternetAddress;
	
	socket_t getSocketHandle(Socket sock)
	{
		return sock.handle;
	}
}

alias std.socket.Socket DflSocket; ///

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
	
	sock.blocking = false; // So the getter will be correct.
	
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
		super.blocking = false;
	}
	
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
	
	/// ditto
	// For use with accept().
	protected this()
	{
	}
	
	
	///
	void event(EventType events, RegisterEventCallback callback)
	{
		registerEvent(this, events, callback);
	}
	
	
	protected override AsyncSocket accepting()
	{
		return new AsyncSocket;
	}
	
	
	override void close()
	{
		unregisterEvent(this);
		super.close();
	}
	
	
	override @property bool blocking() const // getter
	{
		return false;
	}
	
	
	override @property void blocking(bool byes) // setter
	{
		if(byes)
			assert(0);
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
	
	override @property void handle(HANDLE h) // setter
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
	
	
	@property WaitHandle asyncWaitHandle() // getter
	{
		return wh;
	}
	
	
	@property bool completedSynchronously() // getter
	{
		return false;
	}
	
	
	@property bool isCompleted() // getter
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
	DThrowable exception;
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
	final @property DflSocket socket() // getter
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
			
			st = sock.send(buf[0 .. st]);
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
	@property uint sendBytes() // getter
	{
		return writebuf.length;
	}
	
	
	///
	// Number of bytes in recv queue.
	@property uint receiveBytes() // getter
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
			
			default:
		}
	}
	
	
	///
	// Call on a read event so that incoming data may be buffered.
	void readEvent()
	{
		if(readbuf.length - rpos < 1024)
			readbuf.length = readbuf.length + 2048;
		
		int rd = sock.receive(readbuf[rpos .. readbuf.length]);
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
			
			int st = sock.send(buf);
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
	
	
	@property bool canwrite() // getter
	{
		return writebuf.length == 0;
	}
}


private:

struct EventInfo
{
	DflSocket sock;
	RegisterEventCallback callback;
	DThrowable exception;
}


enum UINT WM_DFL_NETEVENT = WM_USER + 104;
enum UINT WM_DFL_HOSTEVENT = WM_USER + 105;
enum NETEVENT_CLASSNAME = "DFL_NetEvent";

EventInfo[socket_t] allEvents;
GetHost[HANDLE] allGetHosts;
HWND hwNet;


extern(Windows) LRESULT netWndProc(HWND hwnd, UINT msg, WPARAM wparam, LPARAM lparam) nothrow
{
	switch(msg)
	{
		case WM_DFL_NETEVENT:
			if(cast(socket_t)wparam in allEvents)
			{
				EventInfo ei = allEvents[cast(socket_t)wparam];
				try
				{
					ei.callback(ei.sock, cast(EventType)LOWORD(lparam), HIWORD(lparam));
				}
				catch (DThrowable e)
				{
					ei.exception = e;
				}
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
				try
				{
					gh._gotEvent(lparam);
				}
				catch (DThrowable e)
				{
					gh.exception = e;
				}
			}
			break;
		
		default:
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

