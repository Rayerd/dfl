// Not actually part of forms, but is needed.
// This code is public domain.

/// Event handling.
module dfl.event;

import dfl.internal.dlib;
import std.functional;


// Create an event handler; old style.
deprecated template Event(TArgs : EventArgs = EventArgs)
{
	alias Event!(Object, TArgs) Event;
}


/** Managing event handlers.
    Params:
		T1 = the sender type.
		T2 = the event arguments type.
**/
template Event(T1, T2) // docmain
{
	/// Managing event handlers.
	struct Event // docmain
	{
		alias void delegate(T1, T2) Handler; /// Event handler type.
		
		
		/// Add an event handler with the exact type.
		void addHandlerExact(Handler handler)
		in
		{
			assert(handler);
		}
		body
		{
			if(!_array.length)
			{
				_array = new Handler[2];
				_array[1] = handler;
				unsetHot();
			}
			else
			{
				if(!isHot())
				{
					_array ~= handler;
				}
				else // Hot.
				{
					_array = _array ~ (&handler)[0 .. 1]; // Force duplicate.
					unsetHot();
				}
			}
		}
		
		
		/// Add an event handler with parameter contravariance.
		void addHandler(TDG)(TDG handler)
		in
		{
			assert(handler);
		}
		body
		{
			mixin _validateHandler!(TDG);
			
			addHandlerExact(cast(Handler)toDelegate(handler));
		}
		
		
		/// Shortcut for addHandler().
		void opCatAssign(TDG)(TDG handler)
		{
			addHandler(toDelegate(handler));
		}
		
		
		/// Remove the specified event handler with the exact Handler type.
		void removeHandlerExact(Handler handler)
		{
			if(!_array.length)
				return;
			
			size_t iw;
			for(iw = 1; iw != _array.length; iw++)
			{
				if(handler == _array[iw])
				{
					if(iw == 1 && _array.length == 2)
					{
						_array = null;
						break;
					}
					
					if(iw == _array.length - 1)
					{
						_array[iw] = null;
						_array = _array[0 .. iw];
						break;
					}
					
					if(!isHot())
					{
						_array[iw] = _array[_array.length - 1];
						_array[_array.length - 1] = null;
						_array = _array[0 .. _array.length - 1];
					}
					else // Hot.
					{
						_array = _array[0 .. iw] ~ _array[iw + 1 .. _array.length]; // Force duplicate.
						unsetHot();
					}
					break;
				}
			}
		}
		
		
		/// Remove the specified event handler with parameter contravariance.
		void removeHandler(TDG)(TDG handler)
		{
			mixin _validateHandler!(TDG);
			
			removeHandlerExact(cast(Handler)toDelegate(handler));
		}
		
		
		/// Fire the event handlers.
		void opCall(T1 v1, T2 v2)
		{
			if(!_array.length)
				return;
			setHot();
			
			Handler[] local;
			local = _array[1 .. _array.length];
			foreach(Handler handler; local)
			{
				handler(v1, v2);
			}
			
			if(!_array.length)
				return;
			unsetHot();
		}
		
		
		///
		int opApply(int delegate(Handler) dg)
		{
			if(!_array.length)
				return 0;
			setHot();
			
			int result = 0;
			
			Handler[] local;
			local = _array[1 .. _array.length];
			foreach(Handler handler; local)
			{
				result = dg(handler);
				if(result)
					break;
			}
			
			if(_array.length)
				unsetHot();
			
			return result;
		}
		
		
		///
		@property bool hasHandlers() pure nothrow // getter
		{
			return _array.length > 1;
		}
		
		
		// Use opApply and hasHandlers instead.
		deprecated @property Handler[] handlers() pure nothrow // getter
		{
			if(!hasHandlers)
				return null;
			try
			{
				return _array[1 .. _array.length].dup; // Because _array can be modified. Function is deprecated anyway.
			}
			catch (DThrowable e)
			{
				return null;
			}
		}
		
		
		private:
		Handler[] _array; // Not what it seems.
		
		
		void setHot()
		{
			assert(_array.length);
			_array[0] = cast(Handler)&setHot; // Non-null, GC friendly.
		}
		
		
		void unsetHot()
		{
			assert(_array.length);
			_array[0] = null;
		}
		
		
		Handler isHot()
		{
			assert(_array.length);
			return _array[0];
		}
		
		
		// Thanks to Tomasz "h3r3tic" Stachowiak for his assistance.
		template _validateHandler(TDG)
		{
			static assert(is(typeof(toDelegate(TDG.init))), "DFL: Event handler must be a callable");
			
			alias ParameterTypeTuple!(TDG) TDGParams;
			static assert(TDGParams.length == 2, "DFL: Event handler needs exactly 2 parameters");
			
			static if(is(TDGParams[0] : Object))
			{
				static assert(is(T1: TDGParams[0]), "DFL: Event handler parameter 1 type mismatch");
			}
			else
			{
				static assert(is(T1 == TDGParams[0]), "DFL: Event handler parameter 1 type mismatch");
			}
			
			static if(is(TDGParams[1] : Object))
			{
				static assert(is(T2 : TDGParams[1]), "DFL: Event handler parameter 2 type mismatch");
			}
			else
			{
				static assert(is(T2 == TDGParams[1]), "DFL: Event handler parameter 2 type mismatch");
			}
		}
	}
}


/// Base event arguments.
class EventArgs // docmain
{
	/+
	private static byte[] buf;
	private import std.gc; // <-- ...
	
	
	new(uint sz)
	{
		void* result;
		
		// synchronized // Slows it down a lot.
		{
			if(sz > buf.length)
				buf = new byte[100 + sz];
			
			result = buf[0 .. sz];
			buf = buf[sz .. buf.length];
		}
		
		// std.gc.addRange(result, result + sz); // So that it can contain pointers.
		return result;
	}
	+/
	
	
	/+
	delete(void* p)
	{
		std.gc.removeRange(p);
	}
	+/
	
	
	//private static const EventArgs _e;
	private static EventArgs _e;
	
	
	static this()
	{
		_e = new EventArgs;
	}
	
	
	/// Property: get a reusable, _empty EventArgs.
	static @property EventArgs empty() nothrow // getter
	{
		return _e;
	}
}


// Simple event handler.
alias Event!(Object, EventArgs) EventHandler; // deprecated


///
class ThreadExceptionEventArgs: EventArgs
{
	///
	// The exception that occured.
	this(DThrowable theException) pure nothrow
	{
		except = theException;
	}
	
	
	///
	final @property DThrowable exception() pure nothrow // getter
	{
		return except;
	}
	
	
	private:
	DThrowable except;
}

