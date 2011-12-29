// Written by Christopher E. Miller
// See the included license.txt for copyright and license details.


///
module dfl.textbox;

private import dfl.internal.dlib;

private import dfl.control, dfl.base, dfl.internal.winapi, dfl.application;
private import dfl.drawing, dfl.event, dfl.internal.utf;

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
abstract class TextBoxBase: ControlSuperClass // docmain
{
	///
	final @property void acceptsTab(bool byes) // setter
	{
		atab = byes;
		setStyle(ControlStyles.WANT_TAB_KEY, atab);
	}
	
	/// ditto
	final @property bool acceptsTab() // getter
	{
		return atab;
	}
	
	
	///
	@property void borderStyle(BorderStyle bs) // setter
	{
		final switch(bs)
		{
			case BorderStyle.FIXED_3D:
				_style(_style() & ~WS_BORDER);
				_exStyle(_exStyle() | WS_EX_CLIENTEDGE);
				break;
				
			case BorderStyle.FIXED_SINGLE:
				_exStyle(_exStyle() & ~WS_EX_CLIENTEDGE);
				_style(_style() | WS_BORDER);
				break;
				
			case BorderStyle.NONE:
				_style(_style() & ~WS_BORDER);
				_exStyle(_exStyle() & ~WS_EX_CLIENTEDGE);
				break;
		}
		
		if(created)
		{
			redrawEntire();
		}
	}
	
	/// ditto
	@property BorderStyle borderStyle() // getter
	{
		if(_exStyle() & WS_EX_CLIENTEDGE)
			return BorderStyle.FIXED_3D;
		else if(_style() & WS_BORDER)
			return BorderStyle.FIXED_SINGLE;
		return BorderStyle.NONE;
	}
	
	
	///
	final @property bool canUndo() // getter
	{
		if(!created)
			return false;
		return SendMessageA(handle, EM_CANUNDO, 0, 0) != 0;
	}
	
	
	///
	final @property void hideSelection(bool byes) // setter
	{
		if(byes)
			_style(_style() & ~ES_NOHIDESEL);
		else
			_style(_style() | ES_NOHIDESEL);
	}
	
	/// ditto
	final @property bool hideSelection() // getter
	{
		return (_style() & ES_NOHIDESEL) == 0;
	}
	
	
	///
	final @property void lines(Dstring[] lns) // setter
	{
		Dstring result;
		foreach(Dstring s; lns)
		{
			result ~= s ~ "\r\n";
		}
		if(result.length) // Remove last \r\n.
			result = result[0 .. result.length - 2];
		text = result;
	}
	
	/// ditto
	final @property Dstring[] lines() // getter
	{
		return stringSplitLines(text);
	}
	
	
	///
	@property void maxLength(uint len) // setter
	{
		if(!len)
		{
			if(multiline)
				lim = 0xFFFFFFFF;
			else
				lim = 0x7FFFFFFE;
		}
		else
		{
			lim = len;
		}
		
		if(created)
		{
			Message m;
			m = Message(handle, EM_SETLIMITTEXT, cast(WPARAM)lim, 0);
			prevWndProc(m);
		}
	}
	
	/// ditto
	@property uint maxLength() // getter
	{
		if(created)
			lim = cast(uint)SendMessageA(handle, EM_GETLIMITTEXT, 0, 0);
		return lim;
	}
	
	
	///
	final uint getLineCount()
	{
		if(!multiline)
			return 1;
		
		if(created)
		{
			return cast(uint)SendMessageA(handle, EM_GETLINECOUNT, 0, 0);
		}
		
		Dstring s;
		size_t iw = 0;
		uint count = 1;
		s = text;
		for(; iw != s.length; iw++)
		{
			if('\r' == s[iw])
			{
				if(iw + 1 == s.length)
					break;
				if('\n' == s[iw + 1])
				{
					iw++;
					count++;
				}
			}
		}
		return count;
	}
	
	
	///
	final @property void modified(bool byes) // setter
	{
		if(created)
			SendMessageA(handle, EM_SETMODIFY, byes, 0);
	}
	
	/// ditto
	final @property bool modified() // getter
	{
		if(!created)
			return false;
		return SendMessageA(handle, EM_GETMODIFY, 0, 0) != 0;
	}
	
	
	///
	@property void multiline(bool byes) // setter
	{
		/+
		if(byes)
			_style(_style() & ~ES_AUTOHSCROLL | ES_MULTILINE);
		else
			_style(_style() & ~ES_MULTILINE | ES_AUTOHSCROLL);
		+/
		
		// TODO: check if correct implementation.
		
		LONG st;
		
		if(byes)
		{
			st = _style() | ES_MULTILINE | ES_AUTOVSCROLL;
			
			if(_wrap)
				st &= ~ES_AUTOHSCROLL;
			else
				st |= ES_AUTOHSCROLL;
		}
		else
		{
			st = _style() & ~(ES_MULTILINE | ES_AUTOVSCROLL);
			
			// Always H-scroll when single line.
			st |= ES_AUTOHSCROLL;
		}
		
		_style(st);
		
		_crecreate();
	}
	
	/// ditto
	@property bool multiline() // getter
	{
		return (_style() & ES_MULTILINE) != 0;
	}
	
	
	///
	final @property void readOnly(bool byes) // setter
	{
		if(created)
		{
			SendMessageA(handle, EM_SETREADONLY, byes, 0); // Should trigger WM_STYLECHANGED.
			invalidate(); // ?
		}
		else
		{
			if(byes)
				_style(_style() | ES_READONLY);
			else
				_style(_style() & ~ES_READONLY);
		}
	}
	
	/// ditto
	final @property bool readOnly() // getter
	{
		return (_style() & ES_READONLY) != 0;
	}
	
	
	///
	@property void selectedText(Dstring sel) // setter
	{
		/+
		if(created)
			SendMessageA(handle, EM_REPLACESEL, FALSE, cast(LPARAM)unsafeStringz(sel));
		+/
		
		if(created)
		{
			//dfl.internal.utf.sendMessage(handle, EM_REPLACESEL, FALSE, sel);
			dfl.internal.utf.sendMessageUnsafe(handle, EM_REPLACESEL, FALSE, sel);
		}
	}
	
	/// ditto
	@property Dstring selectedText() // getter
	{
		/+
		if(created)
		{
			uint v1, v2;
			SendMessageA(handle, EM_GETSEL, cast(WPARAM)&v1, cast(LPARAM)&v2);
			if(v1 == v2)
				return null;
			assert(v2 > v1);
			Dstring result = new char[v2 - v1 + 1];
			result[result.length - 1] = 0;
			result = result[0 .. result.length - 1];
			result[] = text[v1 .. v2];
			return result;
		}
		return null;
		+/
		
		if(created)
			return dfl.internal.utf.getSelectedText(handle);
		return null;
	}
	
	
	///
	@property void selectionLength(uint len) // setter
	{
		if(created)
		{
			uint v1, v2;
			SendMessageA(handle, EM_GETSEL, cast(WPARAM)&v1, cast(LPARAM)&v2);
			v2 = v1 + len;
			SendMessageA(handle, EM_SETSEL, v1, v2);
		}
	}
	
	/// ditto
	// Current selection length, in characters.
	// This does not necessarily correspond to the length of chars; some characters use multiple chars.
	// An end of line (\r\n) takes up 2 characters.
	@property uint selectionLength() // getter
	{
		if(created)
		{
			uint v1, v2;
			SendMessageA(handle, EM_GETSEL, cast(WPARAM)&v1, cast(LPARAM)&v2);
			assert(v2 >= v1);
			return v2 - v1;
		}
		return 0;
	}
	
	
	///
	@property void selectionStart(uint pos) // setter
	{
		if(created)
		{
			uint v1, v2;
			SendMessageA(handle, EM_GETSEL, cast(WPARAM)&v1, cast(LPARAM)&v2);
			assert(v2 >= v1);
			v2 = pos + (v2 - v1);
			SendMessageA(handle, EM_SETSEL, pos, v2);
		}
	}
	
	/// ditto
	// Current selection starting index, in characters.
	// This does not necessarily correspond to the index of chars; some characters use multiple chars.
	// An end of line (\r\n) takes up 2 characters.
	@property uint selectionStart() // getter
	{
		if(created)
		{
			uint v1, v2;
			SendMessageA(handle, EM_GETSEL, cast(WPARAM)&v1, cast(LPARAM)&v2);
			return v1;
		}
		return 0;
	}
	
	
	///
	// Number of characters in the textbox.
	// This does not necessarily correspond to the number of chars; some characters use multiple chars.
	// An end of line (\r\n) takes up 2 characters.
	// Return may be larger than the amount of characters.
	// This is a lot faster than retrieving the text, but retrieving the text is completely accurate.
	@property uint textLength() // getter
	{
		if(!(ctrlStyle & ControlStyles.CACHE_TEXT) && created())
			//return cast(uint)SendMessageA(handle, WM_GETTEXTLENGTH, 0, 0);
			return cast(uint)dfl.internal.utf.sendMessage(handle, WM_GETTEXTLENGTH, 0, 0);
		return wtext.length;
	}
	
	
	///
	@property final void wordWrap(bool byes) // setter
	{
		/+
		if(byes)
			_style(_style() | ES_AUTOVSCROLL);
		else
			_style(_style() & ~ES_AUTOVSCROLL);
		+/
		
		// TODO: check if correct implementation.
		
		if(_wrap == byes)
			return;
		
		_wrap = byes;
		
		// Always H-scroll when single line.
		if(multiline)
		{
			if(byes)
			{
				_style(_style() & ~(ES_AUTOHSCROLL | WS_HSCROLL));
			}
			else
			{
				LONG st;
				st = _style();
				
				st |=  ES_AUTOHSCROLL;
				
				if(_hscroll)
					st |= WS_HSCROLL;
				
				_style(st);
			}
		}
		
		_crecreate();
	}
	
	/// ditto
	final @property bool wordWrap() // getter
	{
		//return (_style() & ES_AUTOVSCROLL) != 0;
		
		return _wrap;
	}
	
	
	///
	final void appendText(Dstring txt)
	{
		if(created)
		{
			selectionStart = textLength;
			selectedText = txt;
		}
		else
		{
			text = text ~ txt;
		}
	}
	
	
	///
	final void clear()
	{
		/+
		// WM_CLEAR only clears the selection ?
		if(created)
			SendMessageA(handle, WM_CLEAR, 0, 0);
		else
			wtext = null;
		+/
		
		text = null;
	}
	
	
	///
	final void clearUndo()
	{
		if(created)
			SendMessageA(handle, EM_EMPTYUNDOBUFFER, 0, 0);
	}
	
	
	///
	final void copy()
	{
		if(created)
		{
			SendMessageA(handle, WM_COPY, 0, 0);
		}
		else
		{
			// There's never a selection if the window isn't created; so just empty the clipboard.
			
			if(!OpenClipboard(null))
			{
				debug(APP_PRINT)
					cprintf("Unable to OpenClipboard().\n");
				//throw new DflException("Unable to set clipboard data.");
				return;
			}
			EmptyClipboard();
			CloseClipboard();
		}
	}
	
	
	///
	final void cut()
	{
		if(created)
		{
			SendMessageA(handle, WM_CUT, 0, 0);
		}
		else
		{
			// There's never a selection if the window isn't created; so just empty the clipboard.
			
			if(!OpenClipboard(null))
			{
				debug(APP_PRINT)
					cprintf("Unable to OpenClipboard().\n");
				//throw new DflException("Unable to set clipboard data.");
				return;
			}
			EmptyClipboard();
			CloseClipboard();
		}
	}
	
	
	///
	final void paste()
	{
		if(created)
		{
			SendMessageA(handle, WM_PASTE, 0, 0);
		}
		else
		{
			// Can't do anything because there's no selection ?
		}
	}
	
	
	///
	final void scrollToCaret()
	{
		if(created)
			SendMessageA(handle, EM_SCROLLCARET, 0, 0);
	}
	
	
	///
	final void select(uint start, uint length)
	{
		if(created)
			SendMessageA(handle, EM_SETSEL, start, start + length);
	}
	
	alias Control.select select; // Overload.
	
	
	///
	final void selectAll()
	{
		if(created)
			SendMessageA(handle, EM_SETSEL, 0, -1);
	}
	
	
	override Dstring toString()
	{
		return text; // ?
	}
	
	
	///
	final void undo()
	{
		if(created)
			SendMessageA(handle, EM_UNDO, 0, 0);
	}
	
	
	/+
	override void createHandle()
	{
		if(isHandleCreated)
			return;
		
		createClassHandle(TEXTBOX_CLASSNAME);
		
		onHandleCreated(EventArgs.empty);
	}
	+/
	
	
	override void createHandle()
	{
		if(!isHandleCreated)
		{
			Dstring txt;
			txt = wtext;
			
			super.createHandle();
			
			//dfl.internal.utf.setWindowText(hwnd, txt);
			text = txt; // So that it can be overridden.
		}
	}
	
	
	protected override void createParams(ref CreateParams cp)
	{
		super.createParams(cp);
		
		cp.className = TEXTBOX_CLASSNAME;
		cp.caption = null; // Set in createHandle() to allow larger buffers.
	}
	
	
	protected override void onHandleCreated(EventArgs ea)
	{
		super.onHandleCreated(ea);
		
		//SendMessageA(hwnd, EM_SETLIMITTEXT, cast(WPARAM)lim, 0);
		maxLength = lim; // Call virtual function.
	}
	
	
	private
	{
		version(DFL_NO_MENUS)
		{
		}
		else
		{
			void menuUndo(Object sender, EventArgs ea)
			{
				undo();
			}
			
			
			void menuCut(Object sender, EventArgs ea)
			{
				cut();
			}
			
			
			void menuCopy(Object sender, EventArgs ea)
			{
				copy();
			}
			
			
			void menuPaste(Object sender, EventArgs ea)
			{
				paste();
			}
			
			
			void menuDelete(Object sender, EventArgs ea)
			{
				// Only clear selection.
				SendMessageA(handle, WM_CLEAR, 0, 0);
			}
			
			
			void menuSelectAll(Object sender, EventArgs ea)
			{
				selectAll();
			}
			
			
			bool isClipboardText()
			{
				if(!OpenClipboard(handle))
					return false;
				
				bool result;
				result = GetClipboardData(CF_TEXT) != null;
				
				CloseClipboard();
				
				return result;
			}
			
			
			void menuPopup(Object sender, EventArgs ea)
			{
				int slen, tlen;
				bool issel;
				
				slen = selectionLength;
				tlen = textLength;
				issel = slen != 0;
				
				miundo.enabled = canUndo;
				micut.enabled = !readOnly() && issel;
				micopy.enabled = issel;
				mipaste.enabled = !readOnly() && isClipboardText();
				midel.enabled = !readOnly() && issel;
				misel.enabled = tlen != 0 && tlen != slen;
			}
			
			
			MenuItem miundo, micut, micopy, mipaste, midel, misel;
		}
	}
	
	
	this()
	{
		_initTextBox();
		
		wstyle |= WS_TABSTOP | ES_AUTOHSCROLL;
		wexstyle |= WS_EX_CLIENTEDGE;
		ctrlStyle |= ControlStyles.SELECTABLE;
		wclassStyle = textBoxClassStyle;
		
		version(DFL_NO_MENUS)
		{
		}
		else
		{
			MenuItem mi;
			
			cmenu = new ContextMenu;
			cmenu.popup ~= &menuPopup;
			
			miundo = new MenuItem;
			miundo.text = "&Undo";
			miundo.click ~= &menuUndo;
			miundo.index = 0;
			cmenu.menuItems.add(miundo);
			
			mi = new MenuItem;
			mi.text = "-";
			mi.index = 1;
			cmenu.menuItems.add(mi);
			
			micut = new MenuItem;
			micut.text = "Cu&t";
			micut.click ~= &menuCut;
			micut.index = 2;
			cmenu.menuItems.add(micut);
			
			micopy = new MenuItem;
			micopy.text = "&Copy";
			micopy.click ~= &menuCopy;
			micopy.index = 3;
			cmenu.menuItems.add(micopy);
			
			mipaste = new MenuItem;
			mipaste.text = "&Paste";
			mipaste.click ~= &menuPaste;
			mipaste.index = 4;
			cmenu.menuItems.add(mipaste);
			
			midel = new MenuItem;
			midel.text = "&Delete";
			midel.click ~= &menuDelete;
			midel.index = 5;
			cmenu.menuItems.add(midel);
			
			mi = new MenuItem;
			mi.text = "-";
			mi.index = 6;
			cmenu.menuItems.add(mi);
			
			misel = new MenuItem;
			misel.text = "Select &All";
			misel.click ~= &menuSelectAll;
			misel.index = 7;
			cmenu.menuItems.add(misel);
		}
	}
	
	
	override @property Color backColor() // getter
	{
		if(Color.empty == backc)
			return defaultBackColor;
		return backc;
	}
	
	alias Control.backColor backColor; // Overload.
	
	
	static @property Color defaultBackColor() // getter
	{
		return Color.systemColor(COLOR_WINDOW);
	}
	
	
	override @property Color foreColor() // getter
	{
		if(Color.empty == forec)
			return defaultForeColor;
		return forec;
	}
	
	alias Control.foreColor foreColor; // Overload.
	
	
	static @property Color defaultForeColor() //getter
	{
		return Color.systemColor(COLOR_WINDOWTEXT);
	}
	
	
	override @property Cursor cursor() // getter
	{
		if(!wcurs)
			return _defaultCursor;
		return wcurs;
	}
	
	alias Control.cursor cursor; // Overload.
	
	
	///
	int getFirstCharIndexFromLine(int line)
	{
		if(!isHandleCreated)
			return -1; // ...
		if(line < 0)
			return -1;
		return SendMessageA(hwnd, EM_LINEINDEX, line, 0);
	}
	
	/// ditto
	int getFirstCharIndexOfCurrentLine()
	{
		if(!isHandleCreated)
			return -1; // ...
		return SendMessageA(hwnd, EM_LINEINDEX, -1, 0);
	}
	
	
	///
	int getLineFromCharIndex(int charIndex)
	{
		if(!isHandleCreated)
			return -1; // ...
		if(charIndex < 0)
			return -1;
		return SendMessageA(hwnd, EM_LINEFROMCHAR, charIndex, 0);
	}
	
	
	///
	Point getPositionFromCharIndex(int charIndex)
	{
		if(!isHandleCreated)
			return Point(0, 0); // ...
		if(charIndex < 0)
			return Point(0, 0);
		POINT point;
		SendMessageA(hwnd, EM_POSFROMCHAR, cast(WPARAM)&point, charIndex);
		return Point(point.x, point.y);
	}
	
	/// ditto
	int getCharIndexFromPosition(Point pt)
	{
		if(!isHandleCreated)
			return -1; // ...
		if(!multiline)
			return 0;
		auto lresult = SendMessageA(hwnd, EM_CHARFROMPOS, 0, MAKELPARAM(pt.x, pt.y));
		if(-1 == lresult)
			return -1;
		return cast(int)cast(short)(lresult & 0xFFFF);
	}
	
	
	package static @property Cursor _defaultCursor() // getter
	{
		static Cursor def = null;
		
		if(!def)
		{
			synchronized
			{
				if(!def)
					def = new SafeCursor(LoadCursorA(null, IDC_IBEAM));
			}
		}
		
		return def;
	}
	
	
	protected:
	protected override void onReflectedMessage(ref Message m)
	{
		super.onReflectedMessage(m);
		
		switch(m.msg)
		{
			case WM_COMMAND:
				switch(HIWORD(m.wParam))
				{
					case EN_CHANGE:
						onTextChanged(EventArgs.empty);
						break;
					
					default:
				}
				break;
			
			/+
			case WM_CTLCOLORSTATIC:
			case WM_CTLCOLOREDIT:
				/+
				//SetBkColor(cast(HDC)m.wParam, backColor.toRgb()); // ?
				SetBkMode(cast(HDC)m.wParam, OPAQUE); // ?
				+/
				break;
			+/
			
			default:
		}
	}
	
	
	override void prevWndProc(ref Message msg)
	{
		version(DFL_NO_MENUS)
		{
			// Don't prevent WM_CONTEXTMENU so at least it'll have a default menu.
		}
		else
		{
			if(msg.msg == WM_CONTEXTMENU) // Ignore the default context menu.
				return;
		}
		
		//msg.result = CallWindowProcA(textBoxPrevWndProc, msg.hWnd, msg.msg, msg.wParam, msg.lParam);
		msg.result = dfl.internal.utf.callWindowProc(textBoxPrevWndProc, msg.hWnd, msg.msg, msg.wParam, msg.lParam);
	}
	
	
	protected override bool processKeyEventArgs(ref Message msg) // package
	{
		switch(msg.msg)
		{
			case WM_KEYDOWN:
			case WM_KEYUP:
			case WM_CHAR:
				if('\t' == msg.wParam)
				{
					// TODO: fix this. This case shouldn't be needed.
					if(atab)
					{
						if(super.processKeyEventArgs(msg))
							return true; // Handled.
						if(WM_KEYDOWN == msg.msg)
						{
							if(multiline) // Only multiline textboxes can have real tabs..
							{
								//selectedText = "\t";
								//SendMessageA(handle, EM_REPLACESEL, TRUE, cast(LPARAM)"\t".ptr); // Allow undo. // Crashes DMD 0.161.
								auto str = "\t".ptr;
								SendMessageA(handle, EM_REPLACESEL, TRUE, cast(LPARAM)str); // Allow undo.
							}
						}
						return true; // Handled.
					}
				}
				break;
			
			default:
		}
		return super.processKeyEventArgs(msg);
	}
	
	
	override void wndProc(ref Message msg)
	{
		switch(msg.msg)
		{
			case WM_GETDLGCODE:
				super.wndProc(msg);
				if(atab)
				{
					//if(GetKeyState(Keys.TAB) & 0x8000)
					{
						//msg.result |= DLGC_WANTALLKEYS;
						msg.result |= DLGC_WANTTAB;
					}
				}
				else
				{
					msg.result &= ~DLGC_WANTTAB;
				}
				return;
			
			default:
				super.wndProc(msg);
		}
	}
	
	
	override @property Size defaultSize() // getter
	{
		return Size(120, 23); // ?
	}
	
	
	private:
	package uint lim = 30_000; // Documented as default.
	bool _wrap = true;
	bool _hscroll;
	
	bool atab = false;
	
	/+
	@property bool atab() // getter
	{
		if(_style() & X)
			return true;
		return false;
	}
	
	@property void atab(bool byes) // setter
	{
		if(byes)
			_style(_style() | X);
		else
			_style(_style() & ~X);
	}
	+/
	
	
	@property void hscroll(bool byes) // setter
	{
		_hscroll = byes;
		
		if(byes && (!_wrap || !multiline))
			_style(_style() | WS_HSCROLL | ES_AUTOHSCROLL);
	}
	
	
	@property bool hscroll() // getter
	{
		return _hscroll;
	}
}


///
class TextBox: TextBoxBase // docmain
{
	///
	final @property void acceptsReturn(bool byes) // setter
	{
		if(byes)
			_style(_style() | ES_WANTRETURN);
		else
			_style(_style() & ~ES_WANTRETURN);
	}
	
	/// ditto
	final @property bool acceptsReturn() // getter
	{
		return (_style() & ES_WANTRETURN) != 0;
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
		
		passchar = pwc;
	}
	
	/// ditto
	final @property dchar passwordChar() // getter
	{
		if(created)
			//passchar = cast(dchar)SendMessageA(handle, EM_GETPASSWORDCHAR, 0, 0);
			passchar = dfl.internal.utf.emGetPasswordChar(handle);
		return passchar;
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
	
	
	protected override @property void onHandleCreated(EventArgs ea)
	{
		super.onHandleCreated(ea);
		
		if(passchar)
		{
			SendMessageA(hwnd, EM_SETPASSWORDCHAR, passchar, 0);
		}
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
	
	
	private:
	dchar passchar = 0;
}

