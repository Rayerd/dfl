///
module dfl.sharedcontrol;

private import dfl.base;
private import dfl.control;
private import dfl.application;

private import dfl.internal.winapi;
private import dfl.internal.dlib;
private import dfl.internal.clib : malloc, free;

private import core.atomic;

///
synchronized shared class SharedControl
{
private:
	Control _ctrl;
	
	void makeParam(ARGS...)(ref void function(Control, ARGS) func, ref ARGS args, ref DflInvokeParam* dflInvokeParam)
		if (ARGS.length)
	{
		static struct FunctionInvokeParam
		{
			ARGS args;
			void function(Control, ARGS) func; // NOTE: This function pointer must be after "args", why?
		}

		auto invokeParam = cast(FunctionInvokeParam*)malloc(FunctionInvokeParam.sizeof);
		if (!invokeParam)
			throw new OomException();
		invokeParam.func.atomicStore(func.atomicLoad());
		static foreach (i, e; args)
		{
			invokeParam.args[i].atomicStore(e.atomicLoad());
		}
		
		static void funcEntry(Control c, size_t[] p)
		{
			auto param = cast(FunctionInvokeParam*)p[0];
			param.func(c, param.args);
			free(param);
		}
		
		dflInvokeParam.fp.atomicStore(&funcEntry);
		dflInvokeParam.exception.atomicStore(null);
		dflInvokeParam.nparams.atomicStore(1);
		dflInvokeParam.params[0].atomicStore(cast(size_t)invokeParam);
	}
	
	void makeParamNoneArgs(ref void function(Control) func, ref DflInvokeParam* dflInvokeParam)
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

		if (LRESULT_DFL_INVOKE != SendMessageA(hwnd.atomicLoad(), wmDfl.atomicLoad(), WPARAM_DFL_INVOKE_PARAMS.atomicLoad(), cast(LPARAM)dflInvokeParam))
			throw new DflException("Invoke failure");

		if (dflInvokeParam.exception)
			throw dflInvokeParam.exception;
	}
	
	///
	void invoke(ARGS...)(void function(Control, ARGS) func, ARGS args)
		if (!ARGS.length)
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

		if (LRESULT_DFL_INVOKE != SendMessageA(hwnd.atomicLoad(), wmDfl.atomicLoad(), WPARAM_DFL_INVOKE_NOPARAMS.atomicLoad(), cast(LPARAM)dflInvokeParam))
			throw new DflException("Invoke failure");
		
		if (dflInvokeParam.exception)
			throw dflInvokeParam.exception;
	}
	
	///
	void delayInvoke(ARGS...)(void function(Control, ARGS) func, ARGS args)
		if (ARGS.length && !hasLocalAliasing!(ARGS))
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
		PostMessageA(hwnd.atomicLoad(), wmDfl.atomicLoad(), WPARAM_DFL_DELAY_INVOKE_PARAMS.atomicLoad(), cast(LPARAM)dflInvokeParam);
	}
	
	///
	void delayInvoke(ARGS...)(void function(Control, ARGS) func, ARGS args)
		if (!ARGS.length)
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
		PostMessageA(hwnd.atomicLoad(), wmDfl.atomicLoad(), WPARAM_DFL_DELAY_INVOKE_NOPARAMS.atomicLoad(), cast(LPARAM)dflInvokeParam);
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
