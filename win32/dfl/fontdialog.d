// Written by Christopher E. Miller
// See the included license.txt for copyright and license details.


///
module dfl.fontdialog;

private import dfl.base, dfl.commondialog, dfl.internal.winapi, dfl.application,
	dfl.control, dfl.drawing, dfl.event;


private extern(Windows)
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
		cf.lpLogFont = cast(typeof(cf.lpLogFont))&lf;
		cf.lCustData = cast(typeof(cf.lCustData))cast(void*)this;
		cf.lpfnHook = &fondHookProc;
		cf.rgbColors = 0;
	}
	
	
	override void reset()
	{
		_fon = null;
		//lf = lf.init; // It's completely updated when needed.
		cf.Flags = INIT_FLAGS;
		cf.rgbColors = 0;
		cf.nSizeMin = 0;
		cf.nSizeMax = 0;
	}
	
	
	///
	final void allowSimulations(bool byes) // setter
	{
		if(byes)
			cf.Flags &= ~CF_NOSIMULATIONS;
		else
			cf.Flags |= CF_NOSIMULATIONS;
	}
	
	/// ditto
	final bool allowSimulations() // getter
	{
		if(cf.Flags & CF_NOSIMULATIONS)
			return false;
		return true;
	}
	
	
	///
	final void allowVectorFonts(bool byes) // setter
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
	final void allowVerticalFonts(bool byes) // setter
	{
		if(byes)
			cf.Flags &= ~CF_NOVERTFONTS;
		else
			cf.Flags |= CF_NOVERTFONTS;
	}
	
	/// ditto
	final bool allowVerticalFonts() // getter
	{
		if(cf.Flags & CF_NOVERTFONTS)
			return false;
		return true;
	}
	
	
	///
	final void color(Color c) // setter
	{
		cf.rgbColors = c.toRgb();
	}
	
	/// ditto
	final Color color() // getter
	{
		return Color.fromRgb(cf.rgbColors);
	}
	
	
	///
	final void fixedPitchOnly(bool byes) // setter
	{
		if(byes)
			cf.Flags |= CF_FIXEDPITCHONLY;
		else
			cf.Flags &= ~CF_FIXEDPITCHONLY;
	}
	
	/// ditto
	final bool fixedPitchOnly() // getter
	{
		if(cf.Flags & CF_FIXEDPITCHONLY)
			return true;
		return false;
	}
	
	
	///
	final void font(Font f) // setter
	{
		_fon = f;
	}
	
	/// ditto
	final Font font() // getter
	{
		if(!_fon)
			_fon = Control.defaultFont; // ?
		return _fon;
	}
	
	
	///
	final void fontMustExist(bool byes) // setter
	{
		if(byes)
			cf.Flags |= CF_FORCEFONTEXIST;
		else
			cf.Flags &= ~CF_FORCEFONTEXIST;
	}
	
	/// ditto
	final bool fontMustExist() // getter
	{
		if(cf.Flags & CF_FORCEFONTEXIST)
			return true;
		return false;
	}
	
	
	///
	final void maxSize(int max) // setter
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
	final int maxSize() // getter
	{
		if(cf.Flags & CF_LIMITSIZE)
			return cf.nSizeMax;
		return 0;
	}
	
	
	///
	final void minSize(int min) // setter
	{
		if(min > cf.nSizeMax)
			cf.nSizeMax = min;
		cf.nSizeMin = min;
		cf.Flags |= CF_LIMITSIZE;
	}
	
	/// ditto
	final int minSize() // getter
	{
		if(cf.Flags & CF_LIMITSIZE)
			return cf.nSizeMin;
		return 0;
	}
	
	
	///
	final void scriptsOnly(bool byes) // setter
	{
		if(byes)
			cf.Flags |= CF_SCRIPTSONLY;
		else
			cf.Flags &= ~CF_SCRIPTSONLY;
	}
	
	/// ditto
	final bool scriptsOnly() // getter
	{
		if(cf.Flags & CF_SCRIPTSONLY)
			return true;
		return false;
	}
	
	
	///
	final void showApply(bool byes) // setter
	{
		if(byes)
			cf.Flags |= CF_APPLY;
		else
			cf.Flags &= ~CF_APPLY;
	}
	
	/// ditto
	final bool showApply() // getter
	{
		if(cf.Flags & CF_APPLY)
			return true;
		return false;
	}
	
	
	///
	final void showHelp(bool byes) // setter
	{
		if(byes)
			cf.Flags |= CF_SHOWHELP;
		else
			cf.Flags &= ~CF_SHOWHELP;
	}
	
	/// ditto
	final bool showHelp() // getter
	{
		if(cf.Flags & CF_SHOWHELP)
			return true;
		return false;
	}
	
	
	///
	final void showEffects(bool byes) // setter
	{
		if(byes)
			cf.Flags |= CF_EFFECTS;
		else
			cf.Flags &= ~CF_EFFECTS;
	}
	
	/// ditto
	final bool showEffects() // getter
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
					
					default: ;
				}
				break;
			
			default: ;
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
		
		font._info(&lf); // -font- gets default font if not set.
		cf.hwndOwner = owner;
		
		// TODO: fix this when LOGFONTW is implemented.
		/+if(dfl.internal.utf.useUnicode)
		{
			const char[] NAME = "ChooseFontW";
			static ChooseFontWProc proc = null;
			
			if(!proc)
			{
				proc = cast(ChooseFontWProc)GetProcAddress(GetModuleHandleA("comdlg32.dll"), NAME);
				if(!proc)
					throw new Exception("Unable to load procedure " ~ NAME ~ ".");
			}
			
			result = proc(&cfw);
		}
		else+/
		{
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
		_fon = new Font(Font._create(&lf), true);
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
	
	LOGFONTA lf;
	Font _fon;
	
	
	const UINT INIT_FLAGS = CF_EFFECTS | CF_ENABLEHOOK | CF_INITTOLOGFONTSTRUCT | CF_SCREENFONTS;
}


// WM_CHOOSEFONT_SETFLAGS to update flags after dialog creation ... ?


private extern(Windows) UINT fondHookProc(HWND hwnd, UINT msg, WPARAM wparam, LPARAM lparam)
{
	const char[] PROP_STR = "DFL_FontDialog";
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
	catch(Object e)
	{
		Application.onThreadException(e);
	}
	
	return result;
}

