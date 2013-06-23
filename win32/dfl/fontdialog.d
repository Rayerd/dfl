// Written by Christopher E. Miller
// See the included license.txt for copyright and license details.


///
module dfl.fontdialog;

private import dfl.base, dfl.commondialog, dfl.internal.winapi, dfl.application,
	dfl.control, dfl.drawing, dfl.event, dfl.internal.utf,
	dfl.internal.dlib;


private extern(Windows) nothrow
{
	alias BOOL function(LPCHOOSEFONTW lpcf) ChooseFontWProc;
}


///
class FontDialog: CommonDialog
{
	this()
	{
		Application.ppin(cast(void*)this);
		
		cf.lStructSize = cf.sizeof;
		cf.Flags = INIT_FLAGS;
		cf.lpLogFont = cast(typeof(cf.lpLogFont))&lfw;
		cf.lCustData = cast(typeof(cf.lCustData))cast(void*)this;
		cf.lpfnHook = &fondHookProc;
		cf.rgbColors = 0;
	}
	
	
	override void reset()
	{
		_fon = null;
		cf.Flags = INIT_FLAGS;
		cf.rgbColors = 0;
		cf.nSizeMin = 0;
		cf.nSizeMax = 0;
	}
	
	
	///
	final @property void allowSimulations(bool byes) // setter
	{
		if(byes)
			cf.Flags &= ~CF_NOSIMULATIONS;
		else
			cf.Flags |= CF_NOSIMULATIONS;
	}
	
	/// ditto
	final @property bool allowSimulations() // getter
	{
		if(cf.Flags & CF_NOSIMULATIONS)
			return false;
		return true;
	}
	
	
	///
	final @property void allowVectorFonts(bool byes) // setter
	{
		if(byes)
			cf.Flags &= ~CF_NOVECTORFONTS;
		else
			cf.Flags |= CF_NOVECTORFONTS;
	}
	
	/// ditto
	final bool allowVectorFonts() // getter
	{
		if(cf.Flags & CF_NOVECTORFONTS)
			return false;
		return true;
	}
	
	
	///
	final @property void allowVerticalFonts(bool byes) // setter
	{
		if(byes)
			cf.Flags &= ~CF_NOVERTFONTS;
		else
			cf.Flags |= CF_NOVERTFONTS;
	}
	
	/// ditto
	final @property bool allowVerticalFonts() // getter
	{
		if(cf.Flags & CF_NOVERTFONTS)
			return false;
		return true;
	}
	
	
	///
	final @property void color(Color c) // setter
	{
		cf.rgbColors = c.toRgb();
	}
	
	/// ditto
	final @property Color color() // getter
	{
		return Color.fromRgb(cf.rgbColors);
	}
	
	
	///
	final @property void fixedPitchOnly(bool byes) // setter
	{
		if(byes)
			cf.Flags |= CF_FIXEDPITCHONLY;
		else
			cf.Flags &= ~CF_FIXEDPITCHONLY;
	}
	
	/// ditto
	final @property bool fixedPitchOnly() // getter
	{
		if(cf.Flags & CF_FIXEDPITCHONLY)
			return true;
		return false;
	}
	
	
	///
	final @property void font(Font f) // setter
	{
		_fon = f;
	}
	
	/// ditto
	final @property Font font() // getter
	{
		if(!_fon)
			_fon = Control.defaultFont; // ?
		return _fon;
	}
	
	
	///
	final @property void fontMustExist(bool byes) // setter
	{
		if(byes)
			cf.Flags |= CF_FORCEFONTEXIST;
		else
			cf.Flags &= ~CF_FORCEFONTEXIST;
	}
	
	/// ditto
	final @property bool fontMustExist() // getter
	{
		if(cf.Flags & CF_FORCEFONTEXIST)
			return true;
		return false;
	}
	
	
	///
	final @property void maxSize(int max) // setter
	{
		if(max > 0)
		{
			if(max > cf.nSizeMin)
				cf.nSizeMax = max;
			cf.Flags |= CF_LIMITSIZE;
		}
		else
		{
			cf.Flags &= ~CF_LIMITSIZE;
			cf.nSizeMax = 0;
			cf.nSizeMin = 0;
		}
	}
	
	/// ditto
	final @property int maxSize() // getter
	{
		if(cf.Flags & CF_LIMITSIZE)
			return cf.nSizeMax;
		return 0;
	}
	
	
	///
	final @property void minSize(int min) // setter
	{
		if(min > cf.nSizeMax)
			cf.nSizeMax = min;
		cf.nSizeMin = min;
		cf.Flags |= CF_LIMITSIZE;
	}
	
	/// ditto
	final @property int minSize() // getter
	{
		if(cf.Flags & CF_LIMITSIZE)
			return cf.nSizeMin;
		return 0;
	}
	
	
	///
	final @property void scriptsOnly(bool byes) // setter
	{
		if(byes)
			cf.Flags |= CF_SCRIPTSONLY;
		else
			cf.Flags &= ~CF_SCRIPTSONLY;
	}
	
	/// ditto
	final @property bool scriptsOnly() // getter
	{
		if(cf.Flags & CF_SCRIPTSONLY)
			return true;
		return false;
	}
	
	
	///
	final @property void showApply(bool byes) // setter
	{
		if(byes)
			cf.Flags |= CF_APPLY;
		else
			cf.Flags &= ~CF_APPLY;
	}
	
	/// ditto
	final @property bool showApply() // getter
	{
		if(cf.Flags & CF_APPLY)
			return true;
		return false;
	}
	
	
	///
	final @property void showHelp(bool byes) // setter
	{
		if(byes)
			cf.Flags |= CF_SHOWHELP;
		else
			cf.Flags &= ~CF_SHOWHELP;
	}
	
	/// ditto
	final @property bool showHelp() // getter
	{
		if(cf.Flags & CF_SHOWHELP)
			return true;
		return false;
	}
	
	
	///
	final @property void showEffects(bool byes) // setter
	{
		if(byes)
			cf.Flags |= CF_EFFECTS;
		else
			cf.Flags &= ~CF_EFFECTS;
	}
	
	/// ditto
	final @property bool showEffects() // getter
	{
		if(cf.Flags & CF_EFFECTS)
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
	EventHandler apply;
	
	
	protected override LRESULT hookProc(HWND hwnd, UINT msg, WPARAM wparam, LPARAM lparam)
	{
		switch(msg)
		{
			case WM_COMMAND:
				switch(LOWORD(wparam))
				{
					case CF_APPLY: // ?
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
		BOOL result = FALSE;
		
		cf.hwndOwner = owner;
		
		if(dfl.internal.utf.useUnicode)
		{
			font._info(&lfw); // -font- gets default font if not set.
			
			enum NAME = "ChooseFontW";
			static ChooseFontWProc proc = null;
			
			if(!proc)
			{
				proc = cast(ChooseFontWProc)GetProcAddress(GetModuleHandleA("comdlg32.dll"), NAME.ptr);
				if(!proc)
					throw new Exception("Unable to load procedure " ~ NAME ~ ".");
			}
			
			result = proc(&cfw);
		}
		else
		{
			font._info(&lfa); // -font- gets default font if not set.
			
			result = ChooseFontA(&cfa);
		}
		
		if(result)
		{
			_update();
			return result;
		}
		return FALSE;
	}
	
	
	private void _update()
	{
		LogFont lf;
		
		if(dfl.internal.utf.useUnicode)
			Font.LOGFONTWtoLogFont(lf, &lfw);
		else
			Font.LOGFONTAtoLogFont(lf, &lfa);
		
		_fon = new Font(Font._create(lf), true);
	}
	
	
	///
	protected void onApply(EventArgs ea)
	{
		apply(this, ea);
	}
	
	
	private:
	
	union
	{
		CHOOSEFONTW cfw;
		CHOOSEFONTA cfa;
		alias cfw cf;
		
		static assert(CHOOSEFONTW.sizeof == CHOOSEFONTA.sizeof);
		static assert(CHOOSEFONTW.Flags.offsetof == CHOOSEFONTA.Flags.offsetof);
		static assert(CHOOSEFONTW.nSizeMax.offsetof == CHOOSEFONTA.nSizeMax.offsetof);
	}
	
	union
	{
		LOGFONTW lfw;
		LOGFONTA lfa;
		
		static assert(LOGFONTW.lfFaceName.offsetof == LOGFONTA.lfFaceName.offsetof);
	}
	
	Font _fon;
	
	
	enum UINT INIT_FLAGS = CF_EFFECTS | CF_ENABLEHOOK | CF_INITTOLOGFONTSTRUCT | CF_SCREENFONTS;
}


// WM_CHOOSEFONT_SETFLAGS to update flags after dialog creation ... ?


private extern(Windows) UINT fondHookProc(HWND hwnd, UINT msg, WPARAM wparam, LPARAM lparam) nothrow
{
	enum PROP_STR = "DFL_FontDialog";
	FontDialog fd;
	LRESULT result = 0;
	
	try
	{
		if(msg == WM_INITDIALOG)
		{
			CHOOSEFONTA* cf;
			cf = cast(CHOOSEFONTA*)lparam;
			SetPropA(hwnd, PROP_STR.ptr, cast(HANDLE)cf.lCustData);
			fd = cast(FontDialog)cast(void*)cf.lCustData;
		}
		else
		{
			fd = cast(FontDialog)cast(void*)GetPropA(hwnd, PROP_STR.ptr);
		}
		
		if(fd)
		{
			result = fd.hookProc(hwnd, msg, wparam, lparam);
		}
	}
	catch(DThrowable e)
	{
		Application.onThreadException(e);
	}
	
	return result;
}

