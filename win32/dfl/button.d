// Written by Christopher E. Miller
// See the included license.txt for copyright and license details.


///
module dfl.button;

private import dfl.base, dfl.control, dfl.application, dfl.internal.winapi;
private import dfl.event, dfl.drawing, dfl.internal.dlib;


private extern(Windows) void _initButton();


///
abstract class ButtonBase: ControlSuperClass // docmain
{
	///
	@property void textAlign(ContentAlignment calign) // setter
	{
		LONG wl = _bstyle() & ~(BS_BOTTOM | BS_CENTER | BS_TOP | BS_RIGHT | BS_LEFT | BS_VCENTER);
		
		final switch(calign)
		{
			case ContentAlignment.TOP_LEFT:
				wl |= BS_TOP | BS_LEFT;
				break;
			
			case ContentAlignment.BOTTOM_CENTER:
				wl |= BS_BOTTOM | BS_CENTER;
				break;
			
			case ContentAlignment.BOTTOM_LEFT:
				wl |= BS_BOTTOM | BS_LEFT;
				break;
			
			case ContentAlignment.BOTTOM_RIGHT:
				wl |= BS_BOTTOM | BS_RIGHT;
				break;
			
			case ContentAlignment.MIDDLE_CENTER:
				wl |= BS_CENTER | BS_VCENTER;
				break;
			
			case ContentAlignment.MIDDLE_LEFT:
				wl |= BS_VCENTER | BS_LEFT;
				break;
			
			case ContentAlignment.MIDDLE_RIGHT:
				wl |= BS_VCENTER | BS_RIGHT;
				break;
			
			case ContentAlignment.TOP_CENTER:
				wl |= BS_TOP | BS_CENTER;
				break;
			
			case ContentAlignment.TOP_RIGHT:
				wl |= BS_TOP | BS_RIGHT;
				break;
		}
		
		_bstyle(wl);
		
		_crecreate();
	}
	
	/// ditto
	@property ContentAlignment textAlign() // getter
	{
		LONG wl = _bstyle();
		
		if(wl & BS_VCENTER) // Middle.
		{
			if(wl & BS_CENTER)
				return ContentAlignment.MIDDLE_CENTER;
			if(wl & BS_RIGHT)
				return ContentAlignment.MIDDLE_RIGHT;
			return ContentAlignment.MIDDLE_LEFT;
		}
		else if(wl & BS_BOTTOM) // Bottom.
		{
			if(wl & BS_CENTER)
				return ContentAlignment.BOTTOM_CENTER;
			if(wl & BS_RIGHT)
				return ContentAlignment.BOTTOM_RIGHT;
			return ContentAlignment.BOTTOM_LEFT;
		}
		else // Top.
		{
			if(wl & BS_CENTER)
				return ContentAlignment.TOP_CENTER;
			if(wl & BS_RIGHT)
				return ContentAlignment.TOP_RIGHT;
			return ContentAlignment.TOP_LEFT;
		}
	}
	
	
	// Border stuff...
	
	
	/+
	override void createHandle()
	{
		if(isHandleCreated)
			return;
		
		createClassHandle(BUTTON_CLASSNAME);
		
		onHandleCreated(EventArgs.empty);
	}
	+/
	
	
	protected override void createParams(ref CreateParams cp)
	{
		super.createParams(cp);
		
		cp.className = BUTTON_CLASSNAME;
		if(isdef)
		{
			cp.menu = cast(HMENU)IDOK;
			if(!(cp.style & WS_DISABLED))
				cp.style |= BS_DEFPUSHBUTTON;
		}
		else if(cp.style & WS_DISABLED)
		{
			cp.style &= ~BS_DEFPUSHBUTTON;
		}
	}
	
	
	protected override void prevWndProc(ref Message msg)
	{
		//msg.result = CallWindowProcA(buttonPrevWndProc, msg.hWnd, msg.msg, msg.wParam, msg.lParam);
		msg.result = dfl.internal.utf.callWindowProc(buttonPrevWndProc, msg.hWnd, msg.msg, msg.wParam, msg.lParam);
	}
	
	
	protected override void onReflectedMessage(ref Message m)
	{
		super.onReflectedMessage(m);
		
		switch(m.msg)
		{
			case WM_COMMAND:
				assert(cast(HWND)m.lParam == handle);
				
				switch(HIWORD(m.wParam))
				{
					case BN_CLICKED:
						onClick(EventArgs.empty);
						break;
					
					default:
				}
				break;
			
			default:
		}
	}
	
	
	protected override void wndProc(ref Message msg)
	{
		switch(msg.msg)
		{
			case WM_LBUTTONDOWN:
				onMouseDown(new MouseEventArgs(MouseButtons.LEFT, 0, cast(short)LOWORD(msg.lParam), cast(short)HIWORD(msg.lParam), 0));
				break;
			
			case WM_LBUTTONUP:
				onMouseUp(new MouseEventArgs(MouseButtons.LEFT, 1, cast(short)LOWORD(msg.lParam), cast(short)HIWORD(msg.lParam), 0));
				break;
			
			default:
				super.wndProc(msg);
				return;
		}
		prevWndProc(msg);
	}
	
	
	/+
	protected override void onHandleCreated(EventArgs ea)
	{
		super.onHandleCreated(ea);
		
		/+
		// Done in createParams() now.
		if(isdef)
			SetWindowLongA(handle, GWL_ID, IDOK);
		+/
	}
	+/
	
	
	this()
	{
		_initButton();
		
		wstyle |= WS_TABSTOP /+ | BS_NOTIFY +/;
		ctrlStyle |= ControlStyles.SELECTABLE;
		wclassStyle = buttonClassStyle;
	}
	
	
	protected:
	
	///
	final @property void isDefault(bool byes) // setter
	{
		isdef = byes;
	}
	
	/// ditto
	final @property bool isDefault() // getter
	{
		//return (_bstyle() & BS_DEFPUSHBUTTON) == BS_DEFPUSHBUTTON;
		//return GetDlgCtrlID(m.hWnd) == IDOK;
		return isdef;
	}
	
	
	protected override bool processMnemonic(dchar charCode)
	{
		if(canSelect)
		{
			if(isMnemonic(charCode, text))
			{
				select();
				//Application.doEvents(); // ?
				//performClick();
				onClick(EventArgs.empty);
				return true;
			}
		}
		return false;
	}
	
	
	///
	override @property Size defaultSize() // getter
	{
		return Size(75, 23);
	}
	
	
	private:
	bool isdef = false;
	
	
	package:
	final:
	// Automatically redraws button styles, unlike _style().
	// Don't use with regular window styles ?
	void _bstyle(LONG newStyle)
	{
		if(isHandleCreated)
			//SendMessageA(handle, BM_SETSTYLE, LOWORD(newStyle), MAKELPARAM(TRUE, 0));
			SendMessageA(handle, BM_SETSTYLE, newStyle, MAKELPARAM(TRUE, 0));
		
		wstyle = newStyle;
		//_style(newStyle);
	}
	
	
	LONG _bstyle()
	{
		return _style();
	}
}


///
class Button: ButtonBase, IButtonControl // docmain
{
	this()
	{
	}
	
	
	///
	@property DialogResult dialogResult() // getter
	{
		return dresult;
	}
	
	/// ditto
	@property void dialogResult(DialogResult dr) // setter
	{
		dresult = dr;
	}
	
	
	///
	// True if default button.
	void notifyDefault(bool byes)
	{
		isDefault = byes;
		
		if(byes)
		{
			if(enabled) // Only show thick border if enabled.
				_bstyle(_bstyle() | BS_DEFPUSHBUTTON);
		}
		else
		{
			_bstyle(_bstyle() & ~BS_DEFPUSHBUTTON);
		}
	}
	
	
	///
	void performClick()
	{
		if(!enabled || !visible || !isHandleCreated) // ?
			return; // ?
		
		// This is actually not so good because it sets focus to the control.
		//SendMessageA(handle, BM_CLICK, 0, 0); // So that wndProc() gets it.
		
		onClick(EventArgs.empty);
	}
	
	
	protected override void onClick(EventArgs ea)
	{
		super.onClick(ea);
		
		if(!(Application._compat & DflCompat.FORM_DIALOGRESULT_096))
		{
			if(DialogResult.NONE != this.dialogResult)
			{
				auto xx = cast(IDialogResult)topLevelControl;
				if(xx)
					xx.dialogResult = this.dialogResult;
			}
		}
	}
	
	
	protected override void wndProc(ref Message m)
	{
		switch(m.msg)
		{
			case WM_ENABLE:
				{
					// Fixing the thick border of a default button when enabling and disabling it.
					
					// To-do: check if correct implementation.
					
					DWORD bst;
					bst = _bstyle();
					if(bst & BS_DEFPUSHBUTTON)
					{
						//_bstyle(bst); // Force the border to be updated. Only works when enabling.
						if(!m.wParam)
						{
							_bstyle(bst & ~BS_DEFPUSHBUTTON);
						}
					}
					else if(m.wParam)
					{
						//if(GetDlgCtrlID(m.hWnd) == IDOK)
						if(isdef)
						{
							_bstyle(bst | BS_DEFPUSHBUTTON);
						}
					}
				}
				break;
			
			default:
		}
		
		super.wndProc(m);
	}
	
	
	override @property void text(Dstring txt) // setter
	{
		if(txt.length)
			assert(!this.image, "Button image with text not supported");
		
		super.text = txt;
	}
	
	alias Control.text text; // Overload.
	
	
	///
	final @property Image image() // getter
	{
		return _img;
	}
	
	/// ditto
	final @property void image(Image img) // setter
	in
	{
		if(img)
			assert(!this.text.length, "Button image with text not supported");
	}
	body
	{
		/+
		if(_picbm)
		{
			_picbm.dispose();
			_picbm = null;
		}
		+/
		
		_img = null; // In case of exception.
		LONG imgst = 0;
		if(img)
		{
			/+
			if(cast(Bitmap)img)
			{
				imgst = BS_BITMAP;
			}
			else if(cast(Icon)img)
			{
				imgst = BS_ICON;
			}
			else
			{
				if(cast(Picture)img)
				{
					_picbm = (cast(Picture)img).toBitmap();
					imgst = BS_BITMAP;
					goto not_unsupported;
				}
				
				throw new DflException("Unsupported image format");
				not_unsupported: ;
			}
			+/
			switch(img._imgtype(null))
			{
				case 1:
					imgst = BS_BITMAP;
					break;
				
				case 2:
					imgst = BS_ICON;
					break;
				
				default:
					throw new DflException("Unsupported image format");
					not_unsupported: ;
			}
		}
		
		_img = img;
		_style((_style() & ~(BS_BITMAP | BS_ICON)) | imgst); // Redrawn manually in setImg().
		if(img)
		{
			if(isHandleCreated)
				setImg(imgst);
		}
		//_bstyle((_bstyle() & ~(BS_BITMAP | BS_ICON)) | imgst);
	}
	
	
	private void setImg(LONG bsImageStyle)
	in
	{
		assert(isHandleCreated);
	}
	body
	{
		WPARAM wparam = 0;
		LPARAM lparam = 0;
		
		/+
		if(bsImageStyle & BS_BITMAP)
		{
			wparam = IMAGE_BITMAP;
			lparam = cast(LPARAM)(_picbm ? _picbm.handle : (cast(Bitmap)_img).handle);
		}
		else if(bsImageStyle & BS_ICON)
		{
			wparam = IMAGE_ICON;
			lparam = cast(LPARAM)((cast(Icon)(_img)).handle);
		}
		else
		{
			return;
		}
		+/
		if(!_img)
			return;
		HGDIOBJ hgo;
		switch(_img._imgtype(&hgo))
		{
			case 1:
				wparam = IMAGE_BITMAP;
				break;
			
			case 2:
				wparam = IMAGE_ICON;
				break;
			
			default:
				return;
		}
		lparam = cast(LPARAM)hgo;
		
		//assert(lparam);
		SendMessageA(handle, BM_SETIMAGE, wparam, lparam);
		invalidate();
	}
	
	
	protected override void onHandleCreated(EventArgs ea)
	{
		super.onHandleCreated(ea);
		
		setImg(_bstyle());
	}
	
	
	protected override void onHandleDestroyed(EventArgs ea)
	{
		super.onHandleDestroyed(ea);
		
		/+
		if(_picbm)
		{
			_picbm.dispose();
			_picbm = null;
		}
		+/
	}
	
	
	private:
	DialogResult dresult = DialogResult.NONE;
	Image _img = null;
	//Bitmap _picbm = null; // If -_img- is a Picture, need to keep a separate Bitmap.
}


///
class CheckBox: ButtonBase // docmain
{
	///
	final @property void appearance(Appearance ap) // setter
	{
		final switch(ap)
		{
			case Appearance.NORMAL:
				_bstyle(_bstyle() & ~BS_PUSHLIKE);
				break;
			
			case Appearance.BUTTON:
				_bstyle(_bstyle() | BS_PUSHLIKE);
				break;
		}
		
		_crecreate();
	}
	
	/// ditto
	final @property Appearance appearance() // getter
	{
		if(_bstyle() & BS_PUSHLIKE)
			return Appearance.BUTTON;
		return Appearance.NORMAL;
	}
	
	
	///
	final @property void autoCheck(bool byes) // setter
	{
		if(byes)
			_bstyle((_bstyle() & ~BS_CHECKBOX) | BS_AUTOCHECKBOX);
		else
			_bstyle((_bstyle() & ~BS_AUTOCHECKBOX) | BS_CHECKBOX);
		// Enabling/disabling the window before creation messes
		// up the autocheck style flag, so handle it manually.
		_autocheck = byes;
	}
	
	/// ditto
	final @property bool autoCheck() // getter
	{
		/+
		return (_bstyle() & BS_AUTOCHECKBOX) == BS_AUTOCHECKBOX;
		+/
		return _autocheck;
	}
	
	
	this()
	{
		wstyle |= BS_AUTOCHECKBOX | BS_LEFT | BS_VCENTER; // Auto check and MIDDLE_LEFT by default.
	}
	
	
	/+
	protected override void onClick(EventArgs ea)
	{
		_updateState();
		
		super.onClick(ea);
	}
	+/
	
	
	///
	final @property void checked(bool byes) // setter
	{
		if(byes)
			_check = CheckState.CHECKED;
		else
			_check = CheckState.UNCHECKED;
		
		if(isHandleCreated)
			SendMessageA(handle, BM_SETCHECK, cast(WPARAM)_check, 0);
	}
	
	/// ditto
	// Returns true for indeterminate too.
	final @property bool checked() // getter
	{
		if(isHandleCreated)
			_updateState();
		return _check != CheckState.UNCHECKED;
	}
	
	
	///
	final @property void checkState(CheckState st) // setter
	{
		_check = st;
		
		if(isHandleCreated)
			SendMessageA(handle, BM_SETCHECK, cast(WPARAM)st, 0);
	}
	
	/// ditto
	final @property CheckState checkState() // getter
	{
		if(isHandleCreated)
			_updateState();
		return _check;
	}
	
	
	protected override void onHandleCreated(EventArgs ea)
	{
		super.onHandleCreated(ea);
		
		if(_autocheck)
			_bstyle((_bstyle() & ~BS_CHECKBOX) | BS_AUTOCHECKBOX);
		else
			_bstyle((_bstyle() & ~BS_AUTOCHECKBOX) | BS_CHECKBOX);
		
		SendMessageA(handle, BM_SETCHECK, cast(WPARAM)_check, 0);
	}
	
	
	private:
	CheckState _check = CheckState.UNCHECKED; // Not always accurate.
	bool _autocheck = true;
	
	
	void _updateState()
	{
		_check = cast(CheckState)SendMessageA(handle, BM_GETCHECK, 0, 0);
	}
}


///
class RadioButton: ButtonBase // docmain
{
	///
	final @property void appearance(Appearance ap) // setter
	{
		final switch(ap)
		{
			case Appearance.NORMAL:
				_bstyle(_bstyle() & ~BS_PUSHLIKE);
				break;
			
			case Appearance.BUTTON:
				_bstyle(_bstyle() | BS_PUSHLIKE);
				break;
		}
		
		_crecreate();
	}
	
	/// ditto
	final @property Appearance appearance() // getter
	{
		if(_bstyle() & BS_PUSHLIKE)
			return Appearance.BUTTON;
		return Appearance.NORMAL;
	}
	
	
	///
	final @property void autoCheck(bool byes) // setter
	{
		/+
		if(byes)
			_bstyle((_bstyle() & ~BS_RADIOBUTTON) | BS_AUTORADIOBUTTON);
		else
			_bstyle((_bstyle() & ~BS_AUTORADIOBUTTON) | BS_RADIOBUTTON);
		// Enabling/disabling the window before creation messes
		// up the autocheck style flag, so handle it manually.
		+/
		_autocheck = byes;
	}
	
	
	/// ditto
	final @property bool autoCheck() // getter
	{
		/+ // Also commented out when using BS_AUTORADIOBUTTON.
		return (_bstyle() & BS_AUTOCHECKBOX) == BS_AUTOCHECKBOX;
		+/
		return _autocheck;
	}
	
	
	this()
	{
		wstyle &= ~WS_TABSTOP;
		//wstyle |= BS_AUTORADIOBUTTON | BS_LEFT | BS_VCENTER; // MIDDLE_LEFT by default.
		wstyle |= BS_RADIOBUTTON | BS_LEFT | BS_VCENTER; // MIDDLE_LEFT by default.
	}
	
	
	protected override void onClick(EventArgs ea)
	{
		if(autoCheck)
		{
			if(parent) // Sanity.
			{
				foreach(Control ctrl; parent.controls)
				{
					if(ctrl is this)
						continue;
					if((ctrl._rtype() & (1 | 8)) == (1 | 8)) // Radio button + auto check.
					{
						(cast(RadioButton)ctrl).checked = false;
					}
				}
			}
			checked = true;
		}
		
		super.onClick(ea);
	}
	
	
	/+
	protected override void onClick(EventArgs ea)
	{
		_updateState();
		
		super.onClick(ea);
	}
	+/
	
	
	///
	final @property void checked(bool byes) // setter
	{
		if(byes)
			_check = CheckState.CHECKED;
		else
			_check = CheckState.UNCHECKED;
		
		if(isHandleCreated)
			SendMessageA(handle, BM_SETCHECK, cast(WPARAM)_check, 0);
	}
	
	/// ditto
	// Returns true for indeterminate too.
	final @property bool checked() // getter
	{
		if(isHandleCreated)
			_updateState();
		return _check != CheckState.UNCHECKED;
	}
	
	
	///
	final @property void checkState(CheckState st) // setter
	{
		_check = st;
		
		if(isHandleCreated)
			SendMessageA(handle, BM_SETCHECK, cast(WPARAM)st, 0);
	}
	
	/// ditto
	final @property CheckState checkState() // getter
	{
		if(isHandleCreated)
			_updateState();
		return _check;
	}
	
	
	///
	void performClick()
	{
		//onClick(EventArgs.empty);
		SendMessageA(handle, BM_CLICK, 0, 0); // So that wndProc() gets it.
	}
	
	
	protected override void onHandleCreated(EventArgs ea)
	{
		super.onHandleCreated(ea);
		
		/+
		if(_autocheck)
			_bstyle((_bstyle() & ~BS_RADIOBUTTON) | BS_AUTORADIOBUTTON);
		else
			_bstyle((_bstyle() & ~BS_AUTORADIOBUTTON) | BS_RADIOBUTTON);
		+/
		
		SendMessageA(handle, BM_SETCHECK, cast(WPARAM)_check, 0);
	}
	
	
	/+
	protected override void onReflectedMessage(ref Message m)
	{
		super.onReflectedMessage(m);
		
		switch(m.msg)
		{
			/+
			// Without this, with XP styles, the background just ends up transparent; not the requested color.
			// This erases the text when XP styles aren't enabled.
			case WM_CTLCOLORSTATIC:
			case WM_CTLCOLORBTN:
				{
					//if(hasVisualStyle)
					{
						RECT rect;
						rect.right = width;
						rect.bottom = height;
						FillRect(cast(HDC)m.wParam, &rect, hbrBg);
					}
				}
				break;
			+/
			
			default:
		}
	}
	+/
	
	
	/+ package +/ /+ protected +/ override int _rtype() // package
	{
		if(autoCheck)
			return 1 | 8; // Radio button + auto check.
		return 1; // Radio button.
	}
	
	
	private:
	CheckState _check = CheckState.UNCHECKED; // Not always accurate.
	bool _autocheck = true;
	
	
	void _updateState()
	{
		_check = cast(CheckState)SendMessageA(handle, BM_GETCHECK, 0, 0);
	}
}

