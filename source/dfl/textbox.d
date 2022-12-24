// Written by Christopher E. Miller
// See the included license.txt for copyright and license details.


///
module dfl.textbox;

private import dfl.control, dfl.base, dfl.application;
private import dfl.drawing, dfl.event;
private import dfl.textboxbase;

private import dfl.internal.dlib;
private import dfl.internal.winapi;
private import dfl.internal.utf;

debug(APP_PRINT)
{
	private import dfl.internal.clib;
}

version(DFL_NO_MENUS)
{
}
else
{
	private import dfl.menu;
}


private extern(Windows) void _initTextBox();


// Note: ControlStyles.CACHE_TEXT might not work correctly with a text box.
// It's not actually a bug, but a limitation of this control.

///
class TextBox: TextBoxBase // docmain
{
	///
	final @property void acceptsReturn(bool byes) // setter
	{
		// if(byes)
		// {
		// 	_style(_style() | ES_WANTRETURN);
		// }
		// else
		// {
		// 	_style(_style() & ~ES_WANTRETURN);
		// }
		if (_acceptsReturn == byes) return;
		_acceptsReturn = byes;
		if (multiline)
		{
			if (byes)
			{
				_style = _style | ES_WANTRETURN;
			}
			else
			{
				_style = _style & ~ES_WANTRETURN;
			}
		}
	}
	
	/// ditto
	final @property bool acceptsReturn() // getter
	{
		// return (_style() & ES_WANTRETURN) != 0;
		return _acceptsReturn;
	}
	
	
	///
	final @property void characterCasing(CharacterCasing cc) // setter
	{
		LONG wl = _style() & ~(ES_UPPERCASE | ES_LOWERCASE);
		
		final switch(cc)
		{
			case CharacterCasing.UPPER:
				wl |= ES_UPPERCASE;
				break;
			
			case CharacterCasing.LOWER:
				wl |= ES_LOWERCASE;
				break;
			
			case CharacterCasing.NORMAL:
				break;
		}
		
		_style(wl);
	}
	
	/// ditto
	final @property CharacterCasing characterCasing() // getter
	{
		LONG wl = _style();
		if(wl & ES_UPPERCASE)
			return CharacterCasing.UPPER;
		else if(wl & ES_LOWERCASE)
			return CharacterCasing.LOWER;
		return CharacterCasing.NORMAL;
	}
	
	
	///
	// Set to 0 (NUL) to remove.
	final @property void passwordChar(dchar pwc) // setter
	{
		if(pwc)
		{
			// When the EM_SETPASSWORDCHAR message is received by an edit control,
			// the edit control redraws all visible characters by using the
			// character specified by the ch parameter.
			
			if(created)
				//SendMessageA(handle, EM_SETPASSWORDCHAR, pwc, 0);
				dfl.internal.utf.emSetPasswordChar(handle, pwc);
			else
				_style(_style() | ES_PASSWORD);
		}
		else
		{
			// The style ES_PASSWORD is removed if an EM_SETPASSWORDCHAR message
			// is sent with the ch parameter set to zero.
			
			if(created)
				//SendMessageA(handle, EM_SETPASSWORDCHAR, 0, 0);
				dfl.internal.utf.emSetPasswordChar(handle, 0);
			else
				_style(_style() & ~ES_PASSWORD);
		}
		
		_passchar = pwc;
	}
	
	/// ditto
	final @property dchar passwordChar() // getter
	{
		if(created)
			//_passchar = cast(dchar)SendMessageA(handle, EM_GETPASSWORDCHAR, 0, 0);
			_passchar = dfl.internal.utf.emGetPasswordChar(handle);
		return _passchar;
	}
	
	
	///
	final @property void scrollBars(ScrollBars sb) // setter
	{
		/+
		switch(sb)
		{
			case ScrollBars.BOTH:
				_style(_style() | WS_HSCROLL | WS_VSCROLL);
				break;
			
			case ScrollBars.HORIZONTAL:
				_style(_style() & ~WS_VSCROLL | WS_HSCROLL);
				break;
			
			case ScrollBars.VERTICAL:
				_style(_style() & ~WS_HSCROLL | WS_VSCROLL);
				break;
			
			case ScrollBars.NONE:
				_style(_style() & ~(WS_HSCROLL | WS_VSCROLL));
				break;
		}
		+/
		final switch(sb)
		{
			case ScrollBars.BOTH:
				_style(_style() | WS_VSCROLL);
				hscroll = true;
				break;
			
			case ScrollBars.HORIZONTAL:
				_style(_style() & ~WS_VSCROLL);
				hscroll = true;
				break;
			
			case ScrollBars.VERTICAL:
				_style(_style() | WS_VSCROLL);
				hscroll = false;
				break;
			
			case ScrollBars.NONE:
				_style(_style() & ~WS_VSCROLL);
				hscroll = false;
				break;
		}
		
		if(created)
			redrawEntire();
	}
	
	/// ditto
	final @property ScrollBars scrollBars() // getter
	{
		LONG wl = _style();
		
		//if(wl & WS_HSCROLL)
		if(hscroll)
		{
			if(wl & WS_VSCROLL)
				return ScrollBars.BOTH;
			return ScrollBars.HORIZONTAL;
		}
		if(wl & WS_VSCROLL)
			return ScrollBars.VERTICAL;
		return ScrollBars.NONE;
	}
	
	
	///
	final @property void textAlign(HorizontalAlignment ha) // setter
	{
		LONG wl = _style() & ~(ES_RIGHT | ES_CENTER | ES_LEFT);
		
		final switch(ha)
		{
			case HorizontalAlignment.RIGHT:
				wl |= ES_RIGHT;
				break;
			
			case HorizontalAlignment.CENTER:
				wl |= ES_CENTER;
				break;
			
			case HorizontalAlignment.LEFT:
				wl |= ES_LEFT;
				break;
		}
		
		_style(wl);
		
		_crecreate();
	}
	
	/// ditto
	final @property HorizontalAlignment textAlign() // getter
	{
		LONG wl = _style();
		
		if(wl & ES_RIGHT)
			return HorizontalAlignment.RIGHT;
		if(wl & ES_CENTER)
			return HorizontalAlignment.CENTER;
		return HorizontalAlignment.LEFT;
	}
	
	
	this()
	{
		wstyle |= ES_LEFT;
	}
	
	/// 
	protected override @property void onHandleCreated(EventArgs ea)
	{
		super.onHandleCreated(ea);
		
		if(_passchar)
		{
			SendMessageA(hwnd, EM_SETPASSWORDCHAR, _passchar, 0);
		}
	}
	
	/// isInputKey returns true when keyData is a regular input key.
	// If keyData is input key, then window message is sended to wndProc()
	// such as WM_KEYDOWN, WM_KEYUP, WM_CHAR and so on.
	protected override bool isInputKey(Keys keyData)
	{
		if (multiline && (keyData & Keys.ALT) == 0)
		{
			switch (keyData & Keys.KEY_CODE)
			{
				case Keys.RETURN:
					{
						IButtonControl b = findForm.acceptButton;
						if(b is null)
							return true; // When Form's default button is none, RETURN is always input key.
						else if(b !is null && _acceptsReturn == false)
							return super.isInputKey(keyData);
						else if(b !is null && _acceptsReturn == true)
							return true;
						else
							assert(0);
					}
				default:
					// Fall through
			}
		}

		return super.isInputKey(keyData);
	}

	// Process dialog key (TAB, RETURN, ESC, UP, DOWN, LEFT, RIGHT and so on).
	// Returns true when processed, otherwise call super class.
	protected override bool processDialogKey(Keys keyData)
	{
		Keys keyCode = cast(Keys)keyData & Keys.KEY_CODE;
		
		if (keyCode == Keys.RETURN)
		{
			if (_acceptsReturn && (keyData & Keys.CONTROL) != 0)
			{
				// When this control accepts Returns, Ctrl-Return is treated exactly like Return.
				keyData &= ~Keys.CONTROL;
			}

			IButtonControl b = findForm.acceptButton;
			if(b is null)
				return true; // When Form's default button is none, RETURN is always input key.
			else if(b !is null && _acceptsReturn == false)
				return super.processDialogKey(keyData);
			else if(b !is null && _acceptsReturn == true)
				return true;
			else
				assert(0);
		}
		return super.processDialogKey(keyData);
	}

	/// Process shortcut key (ctrl+A etc).
	// Returns true when processed, false when not.
	protected override bool processCmdKey(ref Message m, Keys keyData)
	{
		bool isProcessed = super.processCmdKey(m, keyData);

		// TODO: Implement ShortcutsEnabled
		if (!isProcessed && multiline /+&& ShortcutsEnabled+/ && (keyData == (Keys.CONTROL | Keys.A)))
		{
			selectAll();
			return true;
		}

		return isProcessed;
	}

	/+
	override @property void wndProc(ref Message msg)
	{
		switch(msg.msg)
		{
			/+
			case WM_GETDLGCODE:
				if(!acceptsReturn && (GetKeyState(Keys.RETURN) & 0x8000))
				{
					// Hack.
					msg.result = DLGC_HASSETSEL | DLGC_WANTCHARS | DLGC_WANTARROWS;
					return;
				}
				break;
			+/
			
			default:
		}
		
		super.wndProc(msg);
	}
	+/
	protected override void wndProc(ref Message msg)
	{
		switch(msg.msg)
		{
			case WM_KEYDOWN:
			case WM_SYSKEYDOWN:
			case WM_CHAR:
			case WM_SYSCHAR:
			case WM_KEYUP:
			case WM_SYSKEYUP:
				Keys keyCode = cast(Keys)msg.wParam & Keys.KEY_CODE;
		
				if (keyCode == Keys.RETURN)
				{
					IButtonControl b = findForm.acceptButton;
					if(b is null)
						super.wndProc(msg);
					else if(b !is null && _acceptsReturn == false)
						return;
					else if(b !is null && _acceptsReturn == true)
						super.wndProc(msg);
					else
						assert(0);
				}
				else
				{
					super.wndProc(msg);
				}
				return;

			case WM_GETDLGCODE:
				Keys keyCode = cast(Keys)msg.wParam & Keys.KEY_CODE;
				if(keyCode == Keys.RETURN)
				{
					// DLGC_WANTARROWS = 1
					//   Want VK_LEFT, VK_RIGHT, VK_UP and VK_DOWN in WM_KEYDOWN.
					// DLGC_WANTTAB = 2
					//   Want VK_TAB in WM_KEYDOWN.
					// DLGC_WANTALLKEYS = 4
					//   Want VK_RETURN, VK_EXECUTE, VK_ESCAPE and VK_CANCEL in WM_KEYDOWN.
					// DLGC_WANTCHARS = 0x80
					//   Want WM_CHAR.
					if(_acceptsReturn)
					{
						msg.result |= DLGC_WANTCHARS | DLGC_WANTALLKEYS | DLGC_WANTARROWS;
					}
					else
					{
						msg.result &= ~(DLGC_WANTCHARS | DLGC_WANTALLKEYS | DLGC_WANTARROWS);
					}
					return; // Do not call super.wndProc() because processing RETURN was done.
				}
				else
				{
					msg.result |= DLGC_WANTCHARS | DLGC_WANTARROWS;
					super.wndProc(msg);
					return;
				}

			default:
				super.wndProc(msg);
		}
	}
	
	
	private:
	dchar _passchar = 0;
	bool _acceptsReturn = false;
}

