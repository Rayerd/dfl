// Written by Christopher E. Miller
// See the included license.txt for copyright and license details.


///
module dfl.sharedcontrol;

private import dfl.base;
private import dfl.control;
private import dfl.application;

private import dfl.internal.winapi;
private import dfl.internal.dlib;
private import dfl.internal.clib : malloc, free;

///
shared class SharedControl
{
private:
	Control _ctrl;
	
	void makeParam(ARGS...)(void function(Control, ARGS) func, ARGS args, DflInvokeParam* dflInvokeParam)
		if (ARGS.length)
	{
		static struct FunctionInvokeParam
		{
			void function(Control, ARGS) func;
			ARGS args;
		}

		auto invokeParam = cast(FunctionInvokeParam*)malloc(FunctionInvokeParam.sizeof);
		if (!invokeParam)
			throw new OomException();
		invokeParam.func = func;
		invokeParam.args = args;
		
		static void funcEntry(Control c, size_t[] p)
		{
			auto param = cast(FunctionInvokeParam*)p[0];
			param.func(c, param.args);
			free(param);
		}
		
		dflInvokeParam.fp = &funcEntry;
		dflInvokeParam.exception = null;
		dflInvokeParam.nparams = 1;
		dflInvokeParam.params[0] = cast(size_t)invokeParam;
	}
	
	void makeParamNoneArgs(void function(Control) func, DflInvokeParam* dflInvokeParam)
	{
		static void funcEntry(Control c, size_t[] p)
		{
			auto func = cast(void function(Control))p[0];
			func(c);
		}
		
		dflInvokeParam.fp = &funcEntry;
		dflInvokeParam.exception = null;
		dflInvokeParam.nparams = 0;
		dflInvokeParam.params[0] = cast(size_t)func;
	}
	
	
public:
	///
	this(Control ctrl)
	{
		assert(ctrl);
		_ctrl = cast(shared)ctrl;
	}

	///
	void invoke(ARGS...)(void function(Control, ARGS) func, ARGS args)
		if (ARGS.length && !hasLocalAliasing!(ARGS))
	{
		synchronized
		{
			auto ctrl = cast(Control)_ctrl;
			auto hwnd = ctrl.handle;
			
			if(!hwnd)
				throw new DflException("Must invoke with created handle"); // Control.badInvokeHandle();
			
			static assert((DflInvokeParam*).sizeof <= LPARAM.sizeof);

			auto dflInvokeParam = cast(DflInvokeParam*)malloc(DflInvokeParam.sizeof);
			if (!dflInvokeParam)
				throw new OomException();

			makeParam(func, args, dflInvokeParam);
			scope(exit)
			{
				free(dflInvokeParam);
			}

			if (LRESULT_DFL_INVOKE != SendMessageA(hwnd, wmDfl, WPARAM_DFL_INVOKE_PARAMS, cast(LPARAM)dflInvokeParam))
				throw new DflException("Invoke failure");

			if (dflInvokeParam.exception)
				throw dflInvokeParam.exception;
		}
	}
	
	///
	void invoke(ARGS...)(void function(Control, ARGS) func, ARGS args)
		if (!ARGS.length)
	{
		synchronized
		{
			auto ctrl = cast(Control)_ctrl;
			auto hwnd = ctrl.handle;
			
			if(!hwnd)
				throw new DflException("Must invoke with created handle"); // Control.badInvokeHandle();
			
			static assert((DflInvokeParam*).sizeof <= LPARAM.sizeof);
			
			auto dflInvokeParam = cast(DflInvokeParam*)malloc(DflInvokeParam.sizeof);
			if (!dflInvokeParam)
				throw new OomException();
			
			makeParamNoneArgs(func, dflInvokeParam);
			scope(exit)
			{
				free(dflInvokeParam);
			}

			if (LRESULT_DFL_INVOKE != SendMessageA(hwnd, wmDfl, WPARAM_DFL_INVOKE_NOPARAMS, cast(LPARAM)dflInvokeParam))
				throw new DflException("Invoke failure");
			
			if (dflInvokeParam.exception)
				throw dflInvokeParam.exception;
		}
	}
	
	///
	void delayInvoke(ARGS...)(void function(Control, ARGS) func, ARGS args)
		if (ARGS.length && !hasLocalAliasing!(ARGS))
	{
		synchronized
		{
			auto ctrl = cast(Control)_ctrl;
			auto hwnd = ctrl.handle;
			
			if(!hwnd)
				throw new DflException("Must invoke with created handle"); // Control.badInvokeHandle();
			
			static assert((DflInvokeParam*).sizeof <= LPARAM.sizeof);
			
			auto dflInvokeParam = cast(DflInvokeParam*)malloc(DflInvokeParam.sizeof); // NOTE: You must free memory in window procedure.
			if (!dflInvokeParam)
				throw new OomException();
			
			makeParam(func, args, dflInvokeParam);
			PostMessageA(hwnd, wmDfl, WPARAM_DFL_DELAY_INVOKE_PARAMS, cast(LPARAM)dflInvokeParam);
		}
	}
	
	///
	void delayInvoke(ARGS...)(void function(Control, ARGS) func, ARGS args)
		if (!ARGS.length)
	{
		synchronized
		{
			auto ctrl = cast(Control)_ctrl;
			auto hwnd = ctrl.handle;
			
			if(!hwnd)
				throw new DflException("Must invoke with created handle"); // Control.badInvokeHandle();
			
			static assert((DflInvokeParam*).sizeof <= LPARAM.sizeof);
			
			auto dflInvokeParam = cast(DflInvokeParam*)malloc(DflInvokeParam.sizeof); // NOTE: You must free memory in window procedure.
			if (!dflInvokeParam)
				throw new OomException();
			
			makeParamNoneArgs(func, dflInvokeParam);
			PostMessageA(hwnd, wmDfl, WPARAM_DFL_DELAY_INVOKE_NOPARAMS, cast(LPARAM)dflInvokeParam);
		}
	}
}

private template hasLocalAliasing(T...)
{
	import std.traits : hasUnsharedAliasing;
	
	static if (!T.length)
		enum hasLocalAliasing = false;
	else
		enum hasLocalAliasing = std.traits.hasUnsharedAliasing!(T[0]) || dfl.sharedcontrol.hasLocalAliasing!(T[1 .. $]);
}
