// Written by Christopher E. Miller
// See the included license.txt for copyright and license details.


///
module dfl.colordialog;

private import dfl.commondialog, dfl.base, dfl.internal.winapi, dfl.internal.wincom;
private import dfl.internal.utf, dfl.application, dfl.drawing;


///
class ColorDialog: CommonDialog // docmain
{
	this()
	{
		Application.ppin(cast(void*)this);
		
		cc.lStructSize = cc.sizeof;
		cc.Flags = INIT_FLAGS;
		cc.rgbResult = Color.empty.toArgb();
		cc.lCustData = cast(typeof(cc.lCustData))cast(void*)this;
		cc.lpfnHook = cast(typeof(cc.lpfnHook))&ccHookProc;
		_initcust();
	}
	
	
	///
	void allowFullOpen(bool byes) // setter
	{
		if(byes)
			cc.Flags &= ~CC_PREVENTFULLOPEN;
		else
			cc.Flags |= CC_PREVENTFULLOPEN;
	}
	
	/// ditto
	bool allowFullOpen() // getter
	{
		return (cc.Flags & CC_PREVENTFULLOPEN) != CC_PREVENTFULLOPEN;
	}
	
	
	///
	void anyColor(bool byes) // setter
	{
		if(byes)
			cc.Flags |= CC_ANYCOLOR;
		else
			cc.Flags &= ~CC_ANYCOLOR;
	}
	
	/// ditto
	bool anyColor() // getter
	{
		return (cc.Flags & CC_ANYCOLOR) == CC_ANYCOLOR;
	}
	
	
	///
	void solidColorOnly(bool byes) // setter
	{
		if(byes)
			cc.Flags |= CC_SOLIDCOLOR;
		else
			cc.Flags &= ~CC_SOLIDCOLOR;
	}
	
	/// ditto
	bool solidColorOnly() // getter
	{
		return (cc.Flags & CC_SOLIDCOLOR) == CC_SOLIDCOLOR;
	}
	
	
	///
	final void color(Color c) // setter
	{
		cc.rgbResult = c.toRgb();
	}
	
	/// ditto
	final Color color() // getter
	{
		return Color.fromRgb(cc.rgbResult);
	}
	
	
	///
	final void customColors(COLORREF[] colors) // setter
	{
		if(colors.length >= _cust.length)
			_cust[] = colors[0 .. _cust.length];
		else
			_cust[0 .. colors.length] = colors;
	}
	
	/// ditto
	final COLORREF[] customColors() // getter
	{
		return _cust;
	}
	
	
	///
	void fullOpen(bool byes) // setter
	{
		if(byes)
			cc.Flags |= CC_FULLOPEN;
		else
			cc.Flags &= ~CC_FULLOPEN;
	}
	
	/// ditto
	bool fullOpen() // getter
	{
		return (cc.Flags & CC_FULLOPEN) == CC_FULLOPEN;
	}
	
	
	///
	void showHelp(bool byes) // setter
	{
		if(byes)
			cc.Flags |= CC_SHOWHELP;
		else
			cc.Flags &= ~CC_SHOWHELP;
	}
	
	/// ditto
	bool showHelp() // getter
	{
		return (cc.Flags & CC_SHOWHELP) == CC_SHOWHELP;
	}
	
	
	///
	override DialogResult showDialog()
	{
		return runDialog(GetActiveWindow()) ?
			DialogResult.OK : DialogResult.CANCEL;
	}
	
	/// ditto
	override DialogResult showDialog(IWindow owner)
	{
		return runDialog(owner ? owner.handle : GetActiveWindow()) ?
			DialogResult.OK : DialogResult.CANCEL;
	}
	
	
	///
	override void reset()
	{
		cc.Flags = INIT_FLAGS;
		cc.rgbResult = Color.empty.toArgb();
		_initcust();
	}
	
	
	///
	protected override bool runDialog(HWND owner)
	{
		if(!_runDialog(owner))
		{
			if(!CommDlgExtendedError())
				return false;
			_cantrun();
		}
		return true;
	}
	
	
	private BOOL _runDialog(HWND owner)
	{
		if(cc.rgbResult == Color.empty.toArgb())
			cc.Flags &= ~CC_RGBINIT;
		else
			cc.Flags |= CC_RGBINIT;
		cc.hwndOwner = owner;
		cc.lpCustColors = _cust.ptr;
		return ChooseColorA(&cc);
	}
	
	
	private:
	const DWORD INIT_FLAGS = CC_ENABLEHOOK;
	
	CHOOSECOLORA cc;
	COLORREF[16] _cust;
	
	
	void _initcust()
	{
		COLORREF cdef;
		cdef = Color(0xFF, 0xFF, 0xFF).toRgb();
		foreach(ref COLORREF cref; _cust)
		{
			cref = cdef;
		}
	}
}


private extern(Windows) UINT ccHookProc(HWND hwnd, UINT msg, WPARAM wparam, LPARAM lparam)
{
	const char[] PROP_STR = "DFL_ColorDialog";
	ColorDialog cd;
	UINT result = 0;
	
	try
	{
		if(msg == WM_INITDIALOG)
		{
			CHOOSECOLORA* cc;
			cc = cast(CHOOSECOLORA*)lparam;
			SetPropA(hwnd, PROP_STR.ptr, cast(HANDLE)cc.lCustData);
			cd = cast(ColorDialog)cast(void*)cc.lCustData;
		}
		else
		{
			cd = cast(ColorDialog)cast(void*)GetPropA(hwnd, PROP_STR.ptr);
		}
		
		if(cd)
		{
			result = cast(UINT)cd.hookProc(hwnd, msg, wparam, lparam);
		}
	}
	catch(Object e)
	{
		Application.onThreadException(e);
	}
	
	return result;
}

