// Written by Christopher E. Miller
// See the included license.txt for copyright and license details.


///
module dfl.textboxbase;

import dfl.application;
import dfl.base;
import dfl.control;
import dfl.drawing;
import dfl.event;
import dfl.menu;

import dfl.internal.dlib;
import dfl.internal.utf;

import core.sys.windows.windef;
import core.sys.windows.winuser;

debug(APP_PRINT)
{
	import dfl.internal.clib;
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
		if (_acceptsTab != byes)
		{
			_acceptsTab = byes;
			// setStyle(ControlStyles.WANT_TAB_KEY, _acceptsTab); // Do not call here

			// TODO: implement
			// onAcceptsTabChanged(EventArgs.empty);
		}
	}
	
	/// ditto
	final @property bool acceptsTab() // getter
	{
		return _acceptsTab;
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
			result = result[0 .. $ - 2];
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
				_lim = 0xFFFFFFFF;
			else
				_lim = 0x7FFFFFFE;
		}
		else
		{
			_lim = len;
		}
		
		if(created)
		{
			Message m;
			m = Message(handle, EM_SETLIMITTEXT, cast(WPARAM)_lim, 0);
			prevWndProc(m);
		}
	}
	
	/// ditto
	@property uint maxLength() // getter
	{
		if(created)
			_lim = cast(uint)SendMessageA(handle, EM_GETLIMITTEXT, 0, 0);
		return _lim;
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
			dfl.internal.utf.sendMessageUnsafe(handle, EM_REPLACESEL, TRUE, sel);
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
		if(!(_controlStyle & ControlStyles.CACHE_TEXT) && created())
			//return cast(uint)SendMessageA(handle, WM_GETTEXTLENGTH, 0, 0);
			return cast(uint)dfl.internal.utf.sendMessage(handle, WM_GETTEXTLENGTH, 0, 0);
		return _windowText.length.toI32;
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
	
	alias select = Control.select; // Overload.
	
	
	///
	final void selectAll()
	{
		if(created)
			SendMessageA(handle, EM_SETSEL, 0, -1);
	}
	
	
	override Dstring toString() const
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
			Dstring txt = _windowText;
			
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
		maxLength = _lim; // Call virtual function.
	}
	
	
	private
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
			
			_miundo.enabled = canUndo;
			_micut.enabled = !readOnly() && issel;
			_micopy.enabled = issel;
			_mipaste.enabled = !readOnly() && isClipboardText();
			_midel.enabled = !readOnly() && issel;
			_misel.enabled = tlen != 0 && tlen != slen;
		}
		
		
		MenuItem _miundo, _micut, _micopy, _mipaste, _midel, _misel;
	}
	
	
	this()
	{
		_initTextBox();
		
		_windowStyle |= WS_TABSTOP | ES_AUTOHSCROLL;
		_windowStyleEx |= WS_EX_CLIENTEDGE;
		_controlStyle |= ControlStyles.SELECTABLE;
		_windowClassStyle = textBoxClassStyle;
		
		MenuItem mi;
		
		_contextMenu = new ContextMenu;
		_contextMenu.popup ~= &menuPopup;
		
		_miundo = new MenuItem;
		_miundo.text = "&Undo";
		_miundo.click ~= &menuUndo;
		_miundo.index = 0;
		_contextMenu.menuItems.add(_miundo);
		
		mi = new MenuItem;
		mi.text = "-";
		mi.index = 1;
		_contextMenu.menuItems.add(mi);
		
		_micut = new MenuItem;
		_micut.text = "Cu&t";
		_micut.click ~= &menuCut;
		_micut.index = 2;
		_contextMenu.menuItems.add(_micut);
		
		_micopy = new MenuItem;
		_micopy.text = "&Copy";
		_micopy.click ~= &menuCopy;
		_micopy.index = 3;
		_contextMenu.menuItems.add(_micopy);
		
		_mipaste = new MenuItem;
		_mipaste.text = "&Paste";
		_mipaste.click ~= &menuPaste;
		_mipaste.index = 4;
		_contextMenu.menuItems.add(_mipaste);
		
		_midel = new MenuItem;
		_midel.text = "&Delete";
		_midel.click ~= &menuDelete;
		_midel.index = 5;
		_contextMenu.menuItems.add(_midel);
		
		mi = new MenuItem;
		mi.text = "-";
		mi.index = 6;
		_contextMenu.menuItems.add(mi);
		
		_misel = new MenuItem;
		_misel.text = "Select &All";
		_misel.click ~= &menuSelectAll;
		_misel.index = 7;
		_contextMenu.menuItems.add(_misel);
	}
	
	
	override @property Color backColor() const // getter
	{
		if(Color.empty == _backColor)
			return defaultBackColor;
		return _backColor;
	}
	
	alias backColor = Control.backColor; // Overload.
	
	
	static @property Color defaultBackColor() // getter
	{
		return Color.systemColor(COLOR_WINDOW);
	}
	
	
	override @property Color foreColor() const // getter
	{
		if(Color.empty == _foreColor)
			return defaultForeColor;
		return _foreColor;
	}
	
	alias foreColor = Control.foreColor; // Overload.
	
	
	static @property Color defaultForeColor() //getter
	{
		return Color.systemColor(COLOR_WINDOWTEXT);
	}
	
	
	override @property inout(Cursor) cursor() inout // getter
	{
		if(!_windowCursor)
			return cast(inout(Cursor))_defaultCursor;
		return cast(inout(Cursor))_windowCursor;
	}
	
	alias cursor = Control.cursor; // Overload.
	
	
	///
	int getFirstCharIndexFromLine(int line)
	{
		if(!isHandleCreated)
			return -1; // ...
		if(line < 0)
			return -1;
		return SendMessageA(_hwnd, EM_LINEINDEX, line, 0).toI32;
	}
	
	/// ditto
	int getFirstCharIndexOfCurrentLine()
	{
		if(!isHandleCreated)
			return -1; // ...
		return SendMessageA(_hwnd, EM_LINEINDEX, -1, 0).toI32;
	}
	
	
	///
	int getLineFromCharIndex(int charIndex)
	{
		if(!isHandleCreated)
			return -1; // ...
		if(charIndex < 0)
			return -1;
		return SendMessageA(_hwnd, EM_LINEFROMCHAR, charIndex, 0).toI32;
	}
	
	
	///
	Point getPositionFromCharIndex(int charIndex)
	{
		if(!isHandleCreated)
			return Point(0, 0); // ...
		if(charIndex < 0)
			return Point(0, 0);
		POINT point;
		SendMessageA(_hwnd, EM_POSFROMCHAR, cast(WPARAM)&point, charIndex);
		return Point(point.x, point.y);
	}
	
	/// ditto
	int getCharIndexFromPosition(Point pt)
	{
		if(!isHandleCreated)
			return -1; // ...
		if(!multiline)
			return 0;
		auto lresult = SendMessageA(_hwnd, EM_CHARFROMPOS, 0, MAKELPARAM(pt.x, pt.y));
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
					def = new SafeCursor(LoadCursor(null, IDC_IBEAM));
			}
		}
		
		return def;
	}
	
	
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
	

	// processCmdKey returns true when keyData is a shortcut key (ctrl+C etc).
	protected override bool processCmdKey(ref Message msg, Keys keyData)
	{
		// First call parent's ProcessCmdKey, since we don't to eat up
		// the shortcut key we are not supported in TextBox.
		bool returnedValue = super.processCmdKey(msg, keyData);

		// TODO: Implement

		// if (shortcutsEnabled == false && s_shortcutsToDisable !is null)
		// {
		// 	foreach (int shortcutValue in s_shortcutsToDisable)
		// 	{
		// 		if (keyData == shortcutValue ||
		// 			keyData == (shortcutValue | Keys.SHIFT))
		// 		{
		// 			return true;
		// 		}
		// 	}
		// }

		// //
		// // There are a few keys that change the alignment of the text, but that
		// // are not ignored by the native control when the ReadOnly property is set.
		// // We need to workaround that.
		// if (_textBoxFlags[readOnly])
		// {
		// 	int k = keyData;
		// 	if (k == Shortcut.CtrlL        // align left
		// 		|| k == Shortcut.CtrlR     // align right
		// 		|| k == Shortcut.CtrlE     // align centre
		// 		|| k == Shortcut.CtrlJ)
		// 	{  // align justified
		// 		return true;
		// 	}
		// }

		// if (!ReadOnly && (keyData == (Keys.CONTROL | Keys.BACK) || keyData == (Keys.CONTROL | Keys.SHIFT | Keys.BACK)))
		// {
		// 	if (selectionLength != 0)
		// 	{
		// 		SetSelectedTextInternal(string.Empty, clearUndo: false);
		// 	}
		// 	else if (SelectionStart != 0)
		// 	{
		// 		int boundaryStart = ClientUtils.GetWordBoundaryStart(Text, SelectionStart);
		// 		int length = SelectionStart - boundaryStart;
		// 		BeginUpdateInternal();
		// 		SelectionStart = boundaryStart;
		// 		SelectionLength = length;
		// 		EndUpdateInternal();
		// 		SetSelectedTextInternal(string.Empty, clearUndo: false);
		// 	}

		// 	return true;
		// }

		return returnedValue;
	}	
	
	/// isInputKey returns true when keyData is a regular input key.
	// If keyData is input key, then window message is sended to wndProc()
	// such as WM_KEYDOWN, WM_KEYUP, WM_CHAR and so on.
	protected override bool isInputKey(Keys keyData)
	{
		if ((keyData & Keys.ALT) != Keys.ALT)
		{
			// In order to excepted for modifiers,
			// do bit mask to extract only key code from key value. 
			switch (keyData & Keys.KEY_CODE)
			{
				case Keys.TAB:
					// Single-line RichTextBox's want tab characters (see WM_GETDLGCODE),
					// so we don't ask it
					bool m = multiline;
					bool a = _acceptsTab;
					bool k = ((keyData & Keys.CONTROL) == 0);
					if (m && a)
					{
						if (k)
							return true; // TAB is input key because CONTROL is relesed.
						else
							return false; // TAB is not input key because CONTROL is pressed.
					}
					else
					{
						return false; // TAB is not input key.
					}
					
				case Keys.ESCAPE:
					if (multiline)
					{
						return false;
					}

					break;
				case Keys.BACK:
					// TODO: implement
					// if (!ReadOnly)
					// {
					//     return true;
					// }

					break;
				case Keys.PAGE_UP:
				case Keys.PAGE_DOWN:
				case Keys.HOME:
				case Keys.END:
					return true;
				default:
					// Fall through to super.isInputKey()
			}
		}

		return super.isInputKey(keyData);
	}

	/// Process dialog key (TAB, RETURN, ESC, UP, DOWN, LEFT, RIGHT and so on).
	// Returns true when processed, otherwise call super class.
	protected override bool processDialogKey(Keys keyData)
	{
		Keys keyCode = keyData & Keys.KEY_CODE;

		if (keyCode == Keys.TAB && _acceptsTab)
		{
			if ((keyData & Keys.CONTROL) != 0)
			{
				// Changes focus because pressed ctrl+TAB in accepts-tab mode.
				return super.processDialogKey(keyData);
			}
			else
			{
				return true; // processed.
			}
		}

		// if (keyCode == Keys.TAB && _acceptsTab) && (keyData & Keys.CONTROL) != 0)
		// {
		// 	// When this control accepts Tabs, Ctrl-Tab is treated exactly like Tab.
		// 	keyData &= ~Keys.CONTROL;
		// }
		
		return super.processDialogKey(keyData);
	}


	protected override void prevWndProc(ref Message msg)
	{
		if(msg.msg == WM_CONTEXTMENU) // Ignore the default context menu.
			return;
		
		//msg.result = CallWindowProcA(textBoxPrevWndProc, msg.hWnd, msg.msg, msg.wParam, msg.lParam);
		msg.result = dfl.internal.utf.callWindowProc(textBoxPrevWndProc, msg.hWnd, msg.msg, msg.wParam, msg.lParam);
	}
	

	protected override void wndProc(ref Message msg)
	{
		switch(msg.msg)
		{
			case WM_GETDLGCODE:
				// DLGC_WANTARROWS = 1
				//   Want VK_LEFT, VK_RIGHT, VK_UP and VK_DOWN in WM_KEYDOWN.
				// DLGC_WANTTAB = 2
				//   Want VK_TAB in WM_KEYDOWN.
				// DLGC_WANTALLKEYS = 4
				//   Want VK_RETURN, VK_EXECUTE, VK_ESCAPE and VK_CANCEL in WM_KEYDOWN.
				// DLGC_WANTCHARS = 0x80
				//   Want WM_CHAR.

				// If this code is commented out,
				// do not able to change focus and input TAB char by TAB key.
				if(_acceptsTab)
				{
					msg.result |= DLGC_WANTTAB;
				}
				else
				{
					msg.result &= ~(DLGC_WANTTAB | DLGC_WANTALLKEYS);
				}

				return; // Do not call super.wndProc() because processing TAB was done.

			default:
		}
		super.wndProc(msg);
	}
	
	
	protected override @property Size defaultSize() const // getter
	{
		return Size(120, 23); // ?
	}
	

	protected final @property void hscroll(bool byes) // setter
	{
		_hscroll = byes;
		
		if(byes && (!_wrap || !multiline))
			_style(_style() | WS_HSCROLL | ES_AUTOHSCROLL);
	}
	
	
	protected final @property bool hscroll() // getter
	{
		return _hscroll;
	}
	
	private:
	package uint _lim = 30_000; // Documented as default.
	bool _wrap = true;
	bool _hscroll;	
	bool _acceptsTab = false;
}
