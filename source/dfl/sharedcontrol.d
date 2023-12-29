// Written by Christopher E. Miller
// See the included license.txt for copyright and license details.


///
module dfl.sharedcontrol;

private import dfl.control;
private import dfl.application;

private import dfl.internal.winapi;
private import dfl.internal.dlib;
private import dfl.internal.clib;

///
shared class SharedControl
{
private:
	Control _ctrl;
	
	LPARAM makeParam(ARGS...)(void function(Control, ARGS) fn, Tuple!(ARGS)* args)
		if (ARGS.length)
	{
		static assert((DflInvokeParam*).sizeof <= LPARAM.sizeof);
		static struct InvokeParam
		{
			void function(Control, ARGS) fn;
			ARGS args;
		}
		alias malloc = dfl.internal.clib.malloc;
		alias free = dfl.internal.clib.free;
	
		auto param = cast(InvokeParam*)malloc(InvokeParam.sizeof);
		param.fn = fn;
		param.args = args.field;
		
		if (!param)
			throw new OomException();
		
		auto p = cast(DflInvokeParam*)malloc(DflInvokeParam.sizeof);
		
		if (!p)
			throw new OomException();
		
		
		static void fnentry(Control c, size_t[] p)
		{
			auto param = cast(InvokeParam*)p[0];
			param.fn(c, param.args);
			free(param);
		}
		
		p.fp = &fnentry;
		p.nparams = 1;
		p.params[0] = cast(size_t)param;
		
		return cast(LPARAM)p;
	}
	
	
	LPARAM makeParamNoneArgs(void function(Control) fn)
	{
		static assert((DflInvokeParam*).sizeof <= LPARAM.sizeof);
		alias malloc = dfl.internal.clib.malloc;
		alias free = dfl.internal.clib.free;
		
		auto p = cast(DflInvokeParam*)malloc(DflInvokeParam.sizeof);
		
		if (!p)
			throw new OomException();
		
		static void fnentry(Control c, size_t[] p)
		{
			auto fn = cast(void function(Control))p[0];
			fn(c);
		}
		
		p.fp = &fnentry;
		p.nparams = 1;
		p.params[0] = cast(size_t)fn;
		
		return cast(LPARAM)p;
	}
	
	
	
public:
	///
	this(Control ctrl)
	{
		assert(ctrl);
		_ctrl = cast(shared)ctrl;
	}
	
	///
	void invoke(ARGS...)(void function(Control, ARGS) fn, ARGS args)
		if (ARGS.length && !hasLocalAliasing!(ARGS))
	{
		auto ctrl = cast(Control)_ctrl;
		auto hwnd = ctrl.handle;
		
		if(!hwnd)
			Control.badInvokeHandle();
		
		auto t = tuple(args);
		auto p = makeParam(fn, &t);
		SendMessageA(hwnd, wmDfl, WPARAM_DFL_DELAY_INVOKE_PARAMS, p);
	}
	
	///
	void invoke(ARGS...)(void function(Control, ARGS) fn, ARGS args)
		if (!ARGS.length)
	{
		auto ctrl = cast(Control)_ctrl;
		auto hwnd = ctrl.handle;
		
		if(!hwnd)
			Control.badInvokeHandle();
		
		auto p = makeParamNoneArgs(fn);
		SendMessageA(hwnd, wmDfl, WPARAM_DFL_DELAY_INVOKE_PARAMS, p);
	}
	
	///
	void delayInvoke(ARGS...)(void function(Control, ARGS) fn, ARGS args)
		if (ARGS.length && !hasLocalAliasing!(ARGS))
	{
		auto ctrl = cast(Control)_ctrl;
		auto hwnd = ctrl.handle;
		
		if(!hwnd)
			Control.badInvokeHandle();
		
		auto t = tuple(args);
		auto p = makeParam(fn, &t);
		PostMessageA(hwnd, wmDfl, WPARAM_DFL_DELAY_INVOKE_PARAMS, p);
	}
	
	///
	void delayInvoke(ARGS...)(void function(Control, ARGS) fn, ARGS args)
		if (!ARGS.length)
	{
		auto ctrl = cast(Control)_ctrl;
		auto hwnd = ctrl.handle;
		
		if(!hwnd)
			Control.badInvokeHandle();
		
		auto p = makeParamNoneArgs(fn);
		PostMessageA(hwnd, wmDfl, WPARAM_DFL_DELAY_INVOKE_PARAMS, p);
	}
}
