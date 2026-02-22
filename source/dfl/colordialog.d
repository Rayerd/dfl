// Written by Christopher E. Miller
// See the included license.txt for copyright and license details.


///
module dfl.colordialog;

import dfl.application;
import dfl.base;
import dfl.drawing;
import dfl.commondialog;

import dfl.internal.dlib;
import dfl.internal.utf;

import core.sys.windows.commdlg;
import core.sys.windows.winbase;
import core.sys.windows.windef;
import core.sys.windows.wingdi;
import core.sys.windows.winuser;


///
class ColorDialog: CommonDialog // docmain
{
	this()
	{
		Application.ppin(cast(void*)this);
		
		_chooseColor.lStructSize = _chooseColor.sizeof;
		_chooseColor.Flags = INIT_FLAGS;
		_chooseColor.rgbResult = Color.empty.toArgb();
		_chooseColor.lCustData = cast(typeof(_chooseColor.lCustData))cast(void*)this;
		_chooseColor.lpfnHook = &ccHookProc;
		_initcust();
	}
	
	
	///
	@property void allowFullOpen(bool byes) // setter
	{
		if (byes)
			_chooseColor.Flags &= ~CC_PREVENTFULLOPEN;
		else
			_chooseColor.Flags |= CC_PREVENTFULLOPEN;
	}
	
	/// ditto
	@property bool allowFullOpen() const // getter
	{
		return (_chooseColor.Flags & CC_PREVENTFULLOPEN) != CC_PREVENTFULLOPEN;
	}
	
	
	///
	@property void anyColor(bool byes) // setter
	{
		if (byes)
			_chooseColor.Flags |= CC_ANYCOLOR;
		else
			_chooseColor.Flags &= ~CC_ANYCOLOR;
	}
	
	/// ditto
	@property bool anyColor() const // getter
	{
		return (_chooseColor.Flags & CC_ANYCOLOR) == CC_ANYCOLOR;
	}
	
	
	///
	@property void solidColorOnly(bool byes) // setter
	{
		if (byes)
			_chooseColor.Flags |= CC_SOLIDCOLOR;
		else
			_chooseColor.Flags &= ~CC_SOLIDCOLOR;
	}
	
	/// ditto
	@property bool solidColorOnly() const // getter
	{
		return (_chooseColor.Flags & CC_SOLIDCOLOR) == CC_SOLIDCOLOR;
	}
	
	
	///
	final @property void color(Color c) // setter
	{
		_chooseColor.rgbResult = c.toRgb();
	}
	
	/// ditto
	final @property Color color() const // getter
	{
		return Color.fromRgb(_chooseColor.rgbResult);
	}
	
	
	///
	final @property void customColors(COLORREF[] colors) // setter
	{
		if (colors.length >= _customColors.length)
			_customColors[] = colors[0 .. _customColors.length];
		else
			_customColors[0 .. colors.length] = colors[];
	}
	
	/// ditto
	final @property inout(COLORREF[]) customColors() inout // getter
	{
		return _customColors;
	}
	
	
	///
	@property void fullOpen(bool byes) // setter
	{
		if (byes)
			_chooseColor.Flags |= CC_FULLOPEN;
		else
			_chooseColor.Flags &= ~CC_FULLOPEN;
	}
	
	/// ditto
	@property bool fullOpen() const // getter
	{
		return (_chooseColor.Flags & CC_FULLOPEN) == CC_FULLOPEN;
	}
	
	
	///
	@property void showHelp(bool byes) // setter
	{
		if (byes)
			_chooseColor.Flags |= CC_SHOWHELP;
		else
			_chooseColor.Flags &= ~CC_SHOWHELP;
	}
	
	/// ditto
	@property bool showHelp() const // getter
	{
		return (_chooseColor.Flags & CC_SHOWHELP) == CC_SHOWHELP;
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
		_chooseColor.Flags = INIT_FLAGS;
		_chooseColor.rgbResult = Color.empty.toArgb();
		_initcust();
	}
	
	
	///
	protected override UINT_PTR hookProc(HWND hwnd, UINT msg, WPARAM wparam, LPARAM lparam)
	{
		return super.hookProc(hwnd, msg, wparam, lparam);
	}
	
	
	///
	protected override bool runDialog(HWND owner)
	{
		if (!_runDialog(owner))
		{
			if (!CommDlgExtendedError())
				return false;
			_cantRun();
		}
		return true;
	}
	
	
	private BOOL _runDialog(HWND owner)
	{
		if (_chooseColor.rgbResult == Color.empty.toArgb())
			_chooseColor.Flags &= ~CC_RGBINIT;
		else
			_chooseColor.Flags |= CC_RGBINIT;
		_chooseColor.hwndOwner = owner;
		_chooseColor.lpCustColors = _customColors.ptr;
		return ChooseColor(&_chooseColor);
	}
	
	
private:
	enum DWORD INIT_FLAGS = CC_ENABLEHOOK;
	
	CHOOSECOLOR _chooseColor;
	COLORREF[16] _customColors;
	
	
	void _initcust()
	{
		COLORREF cdef = Color(0xFF, 0xFF, 0xFF).toRgb();
		foreach (ref COLORREF cref; _customColors)
		{
			cref = cdef;
		}
	}
}


package extern(Windows) UINT_PTR ccHookProc(HWND hwnd, UINT msg, WPARAM wparam, LPARAM lparam) nothrow
{
	enum PROP_STR = "DFL_ColorDialog";
	ColorDialog cd;
	UINT_PTR result = 0;
	
	try
	{
		if (msg == WM_INITDIALOG)
		{
			CHOOSECOLOR* cc = cast(CHOOSECOLOR*)lparam;
			static if (dfl.internal.utf.useUnicode)
				SetPropW(hwnd, toUnicodez(PROP_STR), cast(HANDLE)cc.lCustData);
			else
				SetPropA(hwnd, toAnsiz(PROP_STR), cast(HANDLE)cc.lCustData);
			cd = cast(ColorDialog)cast(void*)cc.lCustData;
		}
		else
		{
			static if (dfl.internal.utf.useUnicode)
				cd = cast(ColorDialog)cast(void*)GetPropW(hwnd, toUnicodez(PROP_STR));
			else
				cd = cast(ColorDialog)cast(void*)GetPropA(hwnd, toAnsiz(PROP_STR));
		}
		
		if (cd)
		{
			result = cd.hookProc(hwnd, msg, wparam, lparam);
		}
	}
	catch (DThrowable e)
	{
		Application.onThreadException(e);
	}
	
	return result;
}
