// Written by Christopher E. Miller
// See the included license.txt for copyright and license details.


///
module dfl.socket;

import dfl.application;
import dfl.base;
import dfl.event;

import dfl.internal.clib;
import dfl.internal.dlib;
import dfl.internal.utf;
import dfl.internal.winapi : WSACancelAsyncRequest, WSAAsyncGetHostByName, WSAAsyncGetHostByAddr;

import core.sys.windows.winbase;
import core.sys.windows.windef;
import core.sys.windows.winuser;

import core.bitop;
import core.sys.windows.winsock2;

public import std.socket;
import std.container.rbtree;


///
private socket_t getSocketHandle(Socket sock) nothrow @nogc
{
	return sock.handle;
}


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
	
	
	extern(Windows) int WSAAsyncSelect(socket_t s, HWND hWnd, UINT wMsg, int lEvent) nothrow @nogc;
}


///
// Can be OR'ed.
enum SocketEventType
{
	NONE = 0, ///
	
	READ             = FD_READ, /// ditto
	WRITE            = FD_WRITE, /// ditto
	OUT_OF_BAND_DATA = FD_OOB, /// ditto
	ACCEPT           = FD_ACCEPT, /// ditto
	CONNECT          = FD_CONNECT, /// ditto
	CLOSE            = FD_CLOSE, /// ditto
	
	QUALITY_OF_SERVICE       = FD_QOS,
	GROUP_QUALITY_OF_SERVICE = FD_GROUP_QOS,
}


///
// Calling this twice on the same socket cancels out previously
// registered events for the socket.
// Requires Application.run() or Application.doEvents() loop.
void asyncSelect(AsyncSocket sock)
{
	assert(sock !is null, "registerEvent: socket cannot be null");
	
	if (!g_hwNet)
		_init();
	
	sock.blocking = false; // So the getter will be correct.

	SocketEventType events;
	if (sock.read.hasHandlers)
		events |= SocketEventType.READ;
	if (sock.written.hasHandlers)
		events |= SocketEventType.WRITE;
	if (sock.outOfBandData.hasHandlers)
		events |= SocketEventType.OUT_OF_BAND_DATA;
	if (sock.accepted.hasHandlers)
		events |= SocketEventType.ACCEPT;
	if (sock.connected.hasHandlers)
		events |= SocketEventType.CONNECT;
	if (sock.closed.hasHandlers)
		events |= SocketEventType.CLOSE;
	if (sock.qualityOfService.hasHandlers)
		events |= SocketEventType.QUALITY_OF_SERVICE;

	if (WSAAsyncSelect(getSocketHandle(sock), g_hwNet, WM_DFL_NETEVENT, cast(int)events) == SOCKET_ERROR)
		throw new DflException("Unable to register socket events");

	EventInfo ei;
	ei.sock = sock;
	ei.exception = null;

	_registerEventInfo(getSocketHandle(sock), ei);
}

///
int unregisterEvent(AsyncSocket sock) @nogc nothrow
{
	if (WSAAsyncSelect(getSocketHandle(sock), g_hwNet, 0, 0) != 0)
		return SOCKET_ERROR; // Unable to register socket events
	
	_unregisterEventInfo(getSocketHandle(sock));

	return 0;
}


///
class AsyncSocket: Socket // docmain
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
	protected this() pure @safe nothrow
	{
	}
	
	
	///
	override AsyncSocket accept() @trusted
	{
		return cast(AsyncSocket)super.accept();
	}


	///
	void asyncSelect()
	{
		.asyncSelect(this);
	}
	

	///
	// See std.socket.Socket.accepting().
	protected override AsyncSocket accepting()
	{
		return new AsyncSocket;
	}
	
	
	///
	override void close() scope @trusted nothrow @nogc
	{
		if (unregisterEvent(this) != 0)
			assert(0);
		super.close();
	}
	
	
	///
	override @property bool blocking() const // getter
	{
		return false;
	}
	
	
	/// ditto
	override @property void blocking(bool byes) // setter
	{
		if (byes)
			assert(0);
	}
	

	Event!(AsyncSocket, AsyncSocketEventArgs) read; /// FD_READ
	Event!(AsyncSocket, AsyncSocketEventArgs) written; /// FD_WRITE
	Event!(AsyncSocket, AsyncSocketEventArgs) outOfBandData; /// FD_OOB
	Event!(AsyncSocket, AsyncSocketEventArgs) accepted; /// FD_ACCEPT
	Event!(AsyncSocket, AsyncSocketEventArgs) connected; /// FD_CONNECT
	Event!(AsyncSocket, AsyncSocketEventArgs) closed; /// FD_CLOSE
	Event!(AsyncSocket, AsyncSocketEventArgs) qualityOfService; /// FD_QOS

	
	///
	void onRead(AsyncSocket as, AsyncSocketEventArgs ea)
	{
		read(as, ea);
	}


	///
	void onWritten(AsyncSocket as, AsyncSocketEventArgs ea)
	{
		written(as, ea);
	}


	///
	void onOutOfBandData(AsyncSocket as, AsyncSocketEventArgs ea)
	{
		outOfBandData(as, ea);
	}


	///
	void onAccepted(AsyncSocket as, AsyncSocketEventArgs ea)
	{
		accepted(as, ea);
	}


	///
	void onConnected(AsyncSocket as, AsyncSocketEventArgs ea)
	{
		connected(as, ea);
	}


	///
	void onClosed(AsyncSocket as, AsyncSocketEventArgs ea)
	{
		closed(as, ea);
	}


	///
	void onQualityOfService(AsyncSocket as, AsyncSocketEventArgs ea)
	{
		qualityOfService(as, ea);
	}
}


/// 
class AsyncSocketEventArgs : EventArgs
{
	///
	this(SocketEventType eventType, int error)
	{
		this.eventType = eventType;
		this.error = error;
	}

	SocketEventType eventType; ///
	int error; ///
}


///
class AsyncTcpSocket: AsyncSocket // docmain
{
	///
	this(AddressFamily family)
	{
		super(family, SocketType.STREAM, ProtocolType.TCP);
	}

	///
	// For use with accepting().
	protected this() pure @safe nothrow
	{
	}

	///
	// See std.socket.Socket.accepting().
	protected override AsyncTcpSocket accepting()
	{
		return new AsyncTcpSocket;
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
	
	///
	// For use with accepting().
	protected this() pure @safe nothrow
	{
	}

	///
	// See std.socket.Socket.accepting().
	protected override AsyncUdpSocket accepting()
	{
		return new AsyncUdpSocket;
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


///
private void _getHostErr()
{
	throw new DflException("Get host failure"); // Needs a better message.. ?
}


///
private class _InternetHost: InternetHost
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
alias GetHostCallback = void delegate(InternetHost inetHost, int err);


///
class GetHost // docmain
{
	///
	void cancel()
	{
		WSACancelAsyncRequest(_handle);
		_handle = null;
	}
	
	
private:
	HANDLE _handle;
	GetHostCallback _callback;
	DThrowable _exception;
	ubyte[/+MAXGETHOSTSTRUCT+/ 1024] _hostentBytes;
	
	
	///
	void _gotEvent(LPARAM lparam)
	{
		_handle = null;
		
		int err = HIWORD(lparam);
		if (err)
			_callback(null, err);
		else
			_callback(new _InternetHost(_hostentBytes.ptr), 0);
	}
	
	
	///
	this()
	{
	}
}


///
GetHost asyncGetHostByName(Dstring name, GetHostCallback callback) // docmain
{
	if (!g_hwNet)
		_init();
	
	GetHost result = new GetHost;
	HANDLE handle = WSAAsyncGetHostByName(g_hwNet, WM_DFL_HOSTEVENT, unsafeStringz(name), cast(char*)result._hostentBytes, result._hostentBytes.length);
	if (!handle)
		_getHostErr();
	
	result._handle = handle;
	result._callback = callback;
	_registerGetHost(handle, result);
	
	return result;
}


///
GetHost asyncGetHostByAddr(uint32_t addr, GetHostCallback callback) // docmain
{
	if (!g_hwNet)
		_init();
	
	GetHost result = new GetHost;
	version(LittleEndian)
		addr = bswap(addr);
	HANDLE handle = WSAAsyncGetHostByAddr(g_hwNet, WM_DFL_HOSTEVENT, cast(char*)&addr, addr.sizeof, AddressFamily.INET, cast(char*)result._hostentBytes, result._hostentBytes.length);
	if (!handle)
		_getHostErr();
	
	result._handle = handle;
	result._callback = callback;
	_registerGetHost(handle, result);
	
	return result;
}

/// ditto
// Shortcut.
GetHost asyncGetHostByAddr(Dstring addr, GetHostCallback callback) // docmain
{
	uint uiaddr = InternetAddress.parse(addr);
	if (InternetAddress.ADDR_NONE == uiaddr)
		_getHostErr();
	return asyncGetHostByAddr(uiaddr, callback);
}


///
class SocketQueue // docmain
{
	enum MAX_SEND_CHUNK_SIZE = 4096; //
	enum MIN_READ_BUFFER_FREE_SPACE = 1024; //
	enum READ_BUFFER_GROW_SIZE = 2048; //

	///
	this(Socket sock)
	in
	{
		assert(sock !is null);
	}
	do
	{
		this._sock = sock;
	}
	
	
	///
	final @property Socket socket() // getter
	{
		return _sock;
	}
	
	
	///
	void reset()
	{
		_writebuf = null;
		_readbuf = null;
	}
	
	
	///
	void[] peek()
	{
		return _readbuf[0 .. _readPosition];
	}
	
	/// ditto
	void[] peek(uint len)
	{
		if (len >= _readPosition)
			return peek();
		
		return _readbuf[0 .. len];
	}
	
	
	///
	void[] receive()
	{
		ubyte[] result = _readbuf[0 .. _readPosition];
		_readbuf = null;
		_readPosition = 0;
		
		return result;
	}
	
	/// ditto
	void[] receive(uint len)
	{
		if (len >= _readPosition)
			return receive();
		
		ubyte[] result = _readbuf[0 .. len];
		_readbuf = _readbuf[len .. _readbuf.length];
		_readPosition -= len;
		
		return result;
	}
	
	
	///
	void send(void[] buf)
	{
		if (canwrite)
		{
			assert(!_writebuf.length);
			
			const size_t sendChunkSize = {
				if (buf.length > MAX_SEND_CHUNK_SIZE)
					return MAX_SEND_CHUNK_SIZE;
				else
					return buf.length;
			}();
			
			const size_t actuallySentBytes = _sock.send(buf[0 .. sendChunkSize]);
			if (actuallySentBytes > 0)
			{
				if (actuallySentBytes < buf.length)
				{
					// dup so it can be appended to.
					_writebuf = (cast(ubyte[])buf)[actuallySentBytes .. buf.length].dup;
				}
			}
			else
			{
				// dup so it can be appended to.
				_writebuf = (cast(ubyte[])buf).dup;
			}
		}
		else
		{
			_writebuf ~= cast(ubyte[])buf;
		}
	}
	
	
	///
	// Number of bytes in send queue.
	@property size_t sendBytes() // getter
	{
		return _writebuf.length;
	}
	
	
	///
	// Number of bytes in recv queue.
	@property uint receiveBytes() // getter
	{
		return _readPosition;
	}
	
	
	///
	// Call on a read event so that incoming data may be buffered.
	void readEvent()
	{
		if (_readbuf.length - _readPosition < MIN_READ_BUFFER_FREE_SPACE)
			_readbuf.length = _readbuf.length + READ_BUFFER_GROW_SIZE;
		
		const ptrdiff_t actuallyReceivedBytes = _sock.receive(_readbuf[_readPosition .. _readbuf.length]);
		if (actuallyReceivedBytes > 0)
			_readPosition += cast(uint)actuallyReceivedBytes;
	}
	
	
	///
	// Call on a write event so that buffered outgoing data may be sent.
	void writeEvent()
	{
		if (_writebuf.length > 0)
		{
			const ubyte[] buf = {
				if (_writebuf.length > MAX_SEND_CHUNK_SIZE)
					return _writebuf[0 .. MAX_SEND_CHUNK_SIZE];
				else
					return _writebuf;
			}();

			const ptrdiff_t actuallySentBytes = _sock.send(buf);
			if (actuallySentBytes > 0)
				_writebuf = _writebuf[actuallySentBytes .. _writebuf.length];
		}
	}
	
private:
	ubyte[] _writebuf; ///
	ubyte[] _readbuf; ///
	uint _readPosition; ///
	Socket _sock; ///
	
	
	///
	@property bool canwrite() // getter
	{
		return _writebuf.length == 0;
	}
}


private:

///
struct EventInfo
{
	AsyncSocket sock;
	DThrowable exception;
}


///
struct EventEntry
{
	socket_t key;
	EventInfo value;
}


///
bool _lessEventEntry(const ref EventEntry lhs, const ref EventEntry rhs)
{
	return lhs.key < rhs.key;
}


///
EventInfo* _findEventInfo(socket_t key) @nogc nothrow
{
	foreach (ref entry; g_allEvents[])
	{
		if (entry.key == key)
			return &entry.value;
	}
	return null;
}


///
void _registerEventInfo(socket_t key, EventInfo info)
{
	if (auto p = _findEventInfo(key))
	{
		*p = info;
		return;
	}
	g_allEvents.insert(EventEntry(key, info));
}


///
void _unregisterEventInfo(socket_t key) @nogc nothrow
{
	auto r = g_allEvents[];
	
	while (!r.empty)
	{
		if (r.front.key == key)
		{
			g_allEvents.remove(r);
			return;
		}

		r.popFront();
	}
}


///
struct GetHostEntry
{
	HANDLE key;
	GetHost value;
}


///
bool _lessGetHostEntry(const ref GetHostEntry lhs, const ref GetHostEntry rhs)
{
	return lhs.key < rhs.key;
}


///
GetHost* _findGetHost(HANDLE key) @nogc nothrow
{
	foreach (ref entry; g_allGetHosts[])
	{
		if (entry.key == key)
			return &entry.value;
	}
	return null;
}


///
void _registerGetHost(HANDLE key, GetHost host)
{
	if (auto p = _findGetHost(key))
	{
		*p = host;
		return;
	}
	g_allGetHosts.insert(GetHostEntry(key, host));
}


///
void _unregisterGetHost(HANDLE key) @nogc nothrow
{
	auto r = g_allGetHosts[];
	
	while (!r.empty)
	{
		if (r.front.key == key)
		{
			g_allGetHosts.remove(r);
			return;
		}

		r.popFront();
	}
}


enum UINT WM_DFL_NETEVENT = WM_USER + 104; ///
enum UINT WM_DFL_HOSTEVENT = WM_USER + 105; ///
enum NETEVENT_CLASSNAME = "DFL_NetEvent"; ///

HWND g_hwNet; ///

__gshared RedBlackTree!(EventEntry, _lessEventEntry) g_allEvents; ///
__gshared RedBlackTree!(GetHostEntry, _lessGetHostEntry) g_allGetHosts; ///


///
extern(Windows) LRESULT netWndProc(HWND hwnd, UINT msg, WPARAM wparam, LPARAM lparam) nothrow
{
	switch(msg)
	{
		case WM_DFL_NETEVENT:
		{
			EventInfo* ei = _findEventInfo(cast(socket_t)wparam);
			if (ei)
			{
				try
				{
					// ei.callback(ei.sock, cast(SocketEventType)LOWORD(lparam), HIWORD(lparam));

					AsyncSocket socket = ei.sock;
					auto type = cast(SocketEventType)LOWORD(lparam);
					int error = HIWORD(lparam);
					auto ea = new AsyncSocketEventArgs(type, error);

					final switch (type)
					{
						case SocketEventType.READ:
							socket.onRead(socket, ea);
							break;
						case SocketEventType.WRITE:
							socket.onWritten(socket, ea);
							break;
						case SocketEventType.OUT_OF_BAND_DATA:
							socket.onOutOfBandData(socket, ea);
							break;
						case SocketEventType.ACCEPT:
							socket.onAccepted(socket, ea);
							break;
						case SocketEventType.CONNECT:
							socket.onConnected(socket, ea);
							break;
						case SocketEventType.CLOSE:
							socket.onClosed(socket, ea);
							break;
						case SocketEventType.QUALITY_OF_SERVICE:
							socket.onQualityOfService(socket, ea);
							break;
						case SocketEventType.NONE:
							// TODO: Do nothing?
							break;
						case SocketEventType.GROUP_QUALITY_OF_SERVICE:
							// TODO: Do nothing?
					}
				}
				catch (DThrowable e)
				{
					ei.exception = e;
				}
			}
			break;
		}
		
		case WM_DFL_HOSTEVENT:
		{
			HANDLE handle = cast(HANDLE)wparam;
			GetHost* gh = _findGetHost(handle);
			if (gh)
			{
				_unregisterGetHost(handle);
				try
				{
					gh._gotEvent(lparam);
				}
				catch (DThrowable e)
				{
					gh._exception = e;
				}
			}
			break;
		}
		default:
	}
	
	return 1;
}


///
void _init()
{
	g_allEvents = new RedBlackTree!(EventEntry, _lessEventEntry)();
	g_allGetHosts = new RedBlackTree!(GetHostEntry, _lessGetHostEntry)();

	WNDCLASSEXA wce;
	wce.cbSize = wce.sizeof;
	wce.lpszClassName = NETEVENT_CLASSNAME.ptr;
	wce.lpfnWndProc = &netWndProc;
	wce.hInstance = GetModuleHandleA(null);
	
	if (!RegisterClassExA(&wce))
	{
		debug(APP_PRINT)
			cprintf("RegisterClassEx() failed for network event class.\n");
		
	init_err:
		throw new DflException("Unable to initialize asynchronous socket library");
	}
	
	g_hwNet = CreateWindowExA(0, NETEVENT_CLASSNAME.ptr, "", 0, 0, 0, 0, 0, HWND_MESSAGE, null, wce.hInstance, null);
	if (g_hwNet) return;

	// Guess it doesn't support HWND_MESSAGE, so just try null parent.
	
	g_hwNet = CreateWindowExA(0, NETEVENT_CLASSNAME.ptr, "", 0, 0, 0, 0, 0, null, null, wce.hInstance, null);
	if (!g_hwNet)
	{
		debug(APP_PRINT)
			cprintf("CreateWindowEx() failed for network event window.\n");
		
		goto init_err;
	}
}
