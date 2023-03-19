// Written by Christopher E. Miller
// See the included license.txt for copyright and license details.


///
module dfl.timer;

private import dfl.application;
private import dfl.base;
private import dfl.event;

private import dfl.internal.dlib;
debug(APP_PRINT)
{
	private import dfl.internal.clib;
}

private import core.sys.windows.windows;


///
class Timer // docmain
{
public:
	//EventHandler tick;
	Event!(Timer, EventArgs) tick; ///
	
	
	///
	@property void enabled(bool on) // setter
	{
		if(on)
			start();
		else
			stop();
	}
	
	/// ditto
	@property bool enabled() const // getter
	{
		return timerId != 0;
	}
	
	
	///
	final @property void interval(uint timeout) // setter
	{
		if(!timeout)
			throw new DflException("Invalid timer interval");
		
		if(this._timeout != timeout)
		{
			this._timeout = timeout;
			
			if(timerId)
			{
				// I don't know if this is the correct behavior.
				// Reset the timer for the new timeout...
				stop();
				start();
			}
		}
	}
	
	/// ditto
	final @property uint interval() const // getter
	{
		return _timeout;
	}
	
	
	///
	final void start()
	{
		if(timerId)
			return;
		
		assert(_timeout > 0);
		
		timerId = SetTimer(null, 0, _timeout, &timerProc);
		if(!timerId)
			throw new DflException("Unable to start timer");
		allTimers[timerId] = this;
	}
	
	/// ditto
	final void stop()
	{
		if(timerId)
		{
			//delete allTimers[timerId];
			allTimers.remove(timerId);
			KillTimer(null, timerId);
			timerId = 0;
		}
	}
	
	
	///
	this()
	{
	}
	
	/// ditto
	this(void delegate(Timer) dg)
	{
		this();
		if(dg)
		{
			this._dg = dg;
			tick ~= &_dgcall;
		}
	}
	
	/// ditto
	this(void delegate(Object, EventArgs) dg)
	{
		assert(dg !is null);
		
		this();
		tick ~= dg;
	}
	
	/// ditto
	this(void delegate(Timer, EventArgs) dg)
	{
		assert(dg !is null);
		
		this();
		tick ~= dg;
	}
	
	
	~this()
	{
		dispose();
	}
	
	
protected:
	void dispose()
	{
		stop();
	}
	
	
	///
	void onTick(EventArgs ea)
	{
		tick(this, ea);
	}
	
	
private:
	DWORD _timeout = 100;
	UINT_PTR timerId = 0;
	void delegate(Timer) _dg;
	
	
	void _dgcall(Object sender, EventArgs ea)
	{
		assert(_dg !is null);
		_dg(this);
	}
}


private:

Timer[UINT_PTR] allTimers;


extern(Windows) void timerProc(HWND hwnd, UINT uMsg, UINT_PTR idEvent, DWORD dwTime) nothrow
{
	try
	{
		if(idEvent in allTimers)
		{
			allTimers[idEvent].onTick(EventArgs.empty);
		}
		else
		{
			debug(APP_PRINT)
				cprintf("Unknown timer 0x%X.\n", idEvent);
		}
	}
	catch(DThrowable e)
	{
		Application.onThreadException(e);
	}
}

