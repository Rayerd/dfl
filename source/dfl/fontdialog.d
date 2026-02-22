// Written by Christopher E. Miller
// See the included license.txt for copyright and license details.


///
module dfl.fontdialog;

import dfl.application;
import dfl.base;
import dfl.control;
import dfl.drawing;
import dfl.event;
import dfl.commondialog;

import dfl.internal.dlib;
import dfl.internal.utf;

import core.sys.windows.winbase;
import core.sys.windows.winuser;
import core.sys.windows.windef;
import core.sys.windows.commdlg;


private extern(Windows) nothrow
{
	alias ChooseFontWProc = BOOL function(LPCHOOSEFONTW lpcf);
}


///
class FontDialog: CommonDialog
{
	this()
	{
		Application.ppin(cast(void*)this);

		_font = Control.defaultFont;
		_chooseFont.lStructSize = _chooseFont.sizeof;
		_chooseFont.Flags = INIT_FLAGS;
		_chooseFont.lpLogFont = &_logFont.lf;
		_chooseFont.lCustData = cast(typeof(_chooseFont.lCustData))cast(void*)this;
		_chooseFont.lpfnHook = &fontHookProc;
		_chooseFont.rgbColors = 0;
	}
	
	
	override void reset()
	{
		_font = Control.defaultFont;
		_chooseFont.Flags = INIT_FLAGS;
		_chooseFont.rgbColors = 0;
		_chooseFont.nSizeMin = 0;
		_chooseFont.nSizeMax = 0;
	}
	
	
	///
	final @property void allowSimulations(bool byes) // setter
	{
		if (byes)
			_chooseFont.Flags &= ~CF_NOSIMULATIONS;
		else
			_chooseFont.Flags |= CF_NOSIMULATIONS;
	}
	
	/// ditto
	final @property bool allowSimulations() const // getter
	{
		if (_chooseFont.Flags & CF_NOSIMULATIONS)
			return false;
		return true;
	}
	
	
	///
	final @property void allowVectorFonts(bool byes) // setter
	{
		if (byes)
			_chooseFont.Flags &= ~CF_NOVECTORFONTS;
		else
			_chooseFont.Flags |= CF_NOVECTORFONTS;
	}
	
	/// ditto
	final @property bool allowVectorFonts() const // getter
	{
		if (_chooseFont.Flags & CF_NOVECTORFONTS)
			return false;
		return true;
	}
	
	
	///
	final @property void allowVerticalFonts(bool byes) // setter
	{
		if (byes)
			_chooseFont.Flags &= ~CF_NOVERTFONTS;
		else
			_chooseFont.Flags |= CF_NOVERTFONTS;
	}
	
	/// ditto
	final @property bool allowVerticalFonts() const // getter
	{
		if (_chooseFont.Flags & CF_NOVERTFONTS)
			return false;
		return true;
	}
	
	
	///
	final @property void color(Color c) // setter
	{
		_chooseFont.rgbColors = c.toRgb();
	}
	
	/// ditto
	final @property Color color() const // getter
	{
		return Color.fromRgb(_chooseFont.rgbColors);
	}
	
	
	///
	final @property void fixedPitchOnly(bool byes) // setter
	{
		if (byes)
			_chooseFont.Flags |= CF_FIXEDPITCHONLY;
		else
			_chooseFont.Flags &= ~CF_FIXEDPITCHONLY;
	}
	
	/// ditto
	final @property bool fixedPitchOnly() const // getter
	{
		if (_chooseFont.Flags & CF_FIXEDPITCHONLY)
			return true;
		return false;
	}
	
	
	///
	final @property void font(Font f) // setter
	{
		_font = f;
	}
	
	/// ditto
	final @property inout(Font) font() inout // getter
	{
		return _font;
	}
	
	
	///
	final @property void fontMustExist(bool byes) // setter
	{
		if (byes)
			_chooseFont.Flags |= CF_FORCEFONTEXIST;
		else
			_chooseFont.Flags &= ~CF_FORCEFONTEXIST;
	}
	
	/// ditto
	final @property bool fontMustExist() const // getter
	{
		if (_chooseFont.Flags & CF_FORCEFONTEXIST)
			return true;
		return false;
	}
	
	
	///
	final @property void maxSize(int max) // setter
	{
		if (max > 0)
		{
			if(max > _chooseFont.nSizeMin)
				_chooseFont.nSizeMax = max;
			_chooseFont.Flags |= CF_LIMITSIZE;
		}
		else
		{
			_chooseFont.Flags &= ~CF_LIMITSIZE;
			_chooseFont.nSizeMax = 0;
			_chooseFont.nSizeMin = 0;
		}
	}
	
	/// ditto
	final @property int maxSize() const // getter
	{
		if (_chooseFont.Flags & CF_LIMITSIZE)
			return _chooseFont.nSizeMax;
		return 0;
	}
	
	
	///
	final @property void minSize(int min) // setter
	{
		if (min > _chooseFont.nSizeMax)
			_chooseFont.nSizeMax = min;
		_chooseFont.nSizeMin = min;
		_chooseFont.Flags |= CF_LIMITSIZE;
	}
	
	/// ditto
	final @property int minSize() const // getter
	{
		if (_chooseFont.Flags & CF_LIMITSIZE)
			return _chooseFont.nSizeMin;
		return 0;
	}
	
	
	///
	final @property void scriptsOnly(bool byes) // setter
	{
		if (byes)
			_chooseFont.Flags |= CF_SCRIPTSONLY;
		else
			_chooseFont.Flags &= ~CF_SCRIPTSONLY;
	}
	
	/// ditto
	final @property bool scriptsOnly() const // getter
	{
		if (_chooseFont.Flags & CF_SCRIPTSONLY)
			return true;
		return false;
	}
	
	
	///
	final @property void showApply(bool byes) // setter
	{
		if (byes)
			_chooseFont.Flags |= CF_APPLY;
		else
			_chooseFont.Flags &= ~CF_APPLY;
	}
	
	/// ditto
	final @property bool showApply() const // getter
	{
		if (_chooseFont.Flags & CF_APPLY)
			return true;
		return false;
	}
	
	
	///
	final @property void showHelp(bool byes) // setter
	{
		if (byes)
			_chooseFont.Flags |= CF_SHOWHELP;
		else
			_chooseFont.Flags &= ~CF_SHOWHELP;
	}
	
	/// ditto
	final @property bool showHelp() const // getter
	{
		if (_chooseFont.Flags & CF_SHOWHELP)
			return true;
		return false;
	}
	
	
	///
	final @property void showEffects(bool byes) // setter
	{
		if (byes)
			_chooseFont.Flags |= CF_EFFECTS;
		else
			_chooseFont.Flags &= ~CF_EFFECTS;
	}
	
	/// ditto
	final @property bool showEffects() const // getter
	{
		if (_chooseFont.Flags & CF_EFFECTS)
			return true;
		return false;
	}
	
	
	override DialogResult showDialog()
	{
		return runDialog(GetActiveWindow()) ?
			DialogResult.OK : DialogResult.CANCEL;
	}
	
	
	override DialogResult showDialog(IWindow owner)
	{
		return runDialog(owner ? owner.handle : GetActiveWindow()) ?
			DialogResult.OK : DialogResult.CANCEL;
	}
	
	
	///
	Event!(FontDialog, EventArgs) apply;
	
	
	protected override UINT_PTR hookProc(HWND hwnd, UINT msg, WPARAM wparam, LPARAM lparam)
	{
		switch (msg)
		{
			case WM_COMMAND:
				switch (LOWORD(wparam))
				{
					case CF_APPLY: // TODO: ?
						_update();
						onApply(EventArgs.empty);
						break;
					
					default:
				}
				break;
			
			default:
		}
		
		return super.hookProc(hwnd, msg, wparam, lparam);
	}
	
	
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
		BOOL result = FALSE;
		
		_chooseFont.hwndOwner = owner;
		
		static if (useUnicode)
		{
			font._getLogFont(_logFont); // -font- gets default font if not set.
			
			enum NAME = "ChooseFontW";
			static ChooseFontWProc proc = null;
			
			if (!proc)
			{
				proc = cast(ChooseFontWProc)GetProcAddress(GetModuleHandleA("comdlg32.dll"), NAME.ptr);
				if (!proc)
					throw new Exception("Unable to load procedure " ~ NAME ~ ".");
			}
			
			result = proc(&_chooseFont);
		}
		else
		{
			font._getLogFont(_logFont); // -font- gets default font if not set.
			
			result = ChooseFontA(&_chooseFont);
		}
		
		if (result)
		{
			_update();
			return result;
		}
		return FALSE;
	}
	
	
	private void _update()
	{
		_font = new Font(Font.createHFont(_logFont), true);
	}
	
	
	///
	protected void onApply(EventArgs ea)
	{
		apply(this, ea);
	}
	
	
private:
	
	CHOOSEFONT _chooseFont;
	LogicalFont _logFont;
	Font _font;
	
	
	enum UINT INIT_FLAGS = CF_EFFECTS | CF_ENABLEHOOK | CF_INITTOLOGFONTSTRUCT | CF_SCREENFONTS;
}


// WM_CHOOSEFONT_SETFLAGS to update flags after dialog creation ... ?


private extern(Windows) UINT_PTR fontHookProc(HWND hwnd, UINT msg, WPARAM wparam, LPARAM lparam) nothrow
{
	enum PROP_STR = "DFL_FontDialog";
	FontDialog fd;
	UINT_PTR result = 0;
	
	try
	{
		if (msg == WM_INITDIALOG)
		{
			CHOOSEFONT* cf = cast(CHOOSEFONT*)lparam;
			static if (useUnicode)
				SetPropW(hwnd, toUnicodez(PROP_STR), cast(HANDLE)cf.lCustData);
			else
				SetPropA(hwnd, toAnsiz(PROP_STR), cast(HANDLE)cf.lCustData);
			fd = cast(FontDialog)cast(void*)cf.lCustData;
		}
		else
		{
			static if (useUnicode)
				fd = cast(FontDialog)cast(void*)GetPropW(hwnd, toUnicodez(PROP_STR));
			else
				fd = cast(FontDialog)cast(void*)GetPropA(hwnd, toAnsiz(PROP_STR));
		}
		
		if (fd)
			result = fd.hookProc(hwnd, msg, wparam, lparam);
	}
	catch (DThrowable e)
	{
		Application.onThreadException(e);
	}
	
	return result;
}
