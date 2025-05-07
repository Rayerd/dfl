// Written by Christopher E. Miller
// See the included license.txt for copyright and license details.


///
module dfl.richtextbox;

import dfl.application;
import dfl.base;
import dfl.control;
import dfl.data;
import dfl.drawing;
import dfl.event;
import dfl.textboxbase;
import dfl.menu;

import dfl.internal.winapi;
import dfl.internal.dlib;
import dfl.internal.utf;

import core.sys.windows.richedit : GETTEXTEX, GETTEXTLENGTHEX, GTL_CLOSE, SF_UNICODE;

import std.utf;


private extern(C) char* strcpy(char*, char*);


private extern(Windows) void _initRichtextbox();


///
class LinkClickedEventArgs: EventArgs
{
	///
	this(Dstring linkText)
	{
		_linktxt = linkText;
	}
	
	
	///
	final @property Dstring linkText() // getter
	{
		return _linktxt;
	}
	
	
private:
	Dstring _linktxt;
}


///
enum RichTextBoxScrollBars: ubyte
{
	NONE, ///
	HORIZONTAL, /// ditto
	VERTICAL, /// ditto
	BOTH, /// ditto
	FORCED_HORIZONTAL, /// ditto
	FORCED_VERTICAL, /// ditto
	FORCED_BOTH, /// ditto
}


///
class RichTextBox: TextBoxBase // docmain
{
	///
	this()
	{
		super();
		
		_initRichtextbox();
		
		enum ES_SAVESEL = 0x00008000; // New edit control style.
		wstyle |= ES_MULTILINE | ES_WANTRETURN | ES_AUTOHSCROLL | ES_AUTOVSCROLL | WS_HSCROLL | WS_VSCROLL | ES_SAVESEL;
		wcurs = null; // So that the control can change it accordingly.
		wclassStyle = richtextboxClassStyle;

		with (miredo = new MenuItem)
		{
			text = "&Redo";
			click ~= &menuRedo;
			contextMenu.menuItems.insert(1, miredo);
		}
		
		contextMenu.popup ~= &menuPopup2;
	}
	
	
	private
	{
		///
		void menuRedo(Object sender, EventArgs ea)
		{
			redo();
		}
		
		
		///
		void menuPopup2(Object sender, EventArgs ea)
		{
			miredo.enabled = canRedo;
		}
		
		
		MenuItem miredo;
	}
	
	
	///
	override @property Cursor cursor() // getter
	{
		return wcurs; // Do return null and don't inherit.
	}
	
	/// ditto
	alias cursor = TextBoxBase.cursor; // Overload.
	
	
	///
	override @property Dstring selectedText() // getter
	{
		if (created)
			return dfl.internal.utf.emGetSelText(hwnd, selectionLength + 1);
		return null;
	}
	
	/// ditto
	alias selectedText = TextBoxBase.selectedText; // Overload.
	
	
	///
	override @property void selectionLength(uint len) // setter
	{
		if(created)
		{
			CHARRANGE chrg;
			SendMessageA(handle, EM_EXGETSEL, 0, cast(LPARAM)&chrg);
			chrg.cpMax = chrg.cpMin + len;
			SendMessageA(handle, EM_EXSETSEL, 0, cast(LPARAM)&chrg);
		}
	}
	
	// Current selection length, in characters.
	// This does not necessarily correspond to the length of chars; some characters use multiple chars.
	// An end of line (\r\n) takes up 2 characters.
	override @property uint selectionLength() // getter
	{
		if(created)
		{
			CHARRANGE chrg;
			SendMessageA(handle, EM_EXGETSEL, 0, cast(LPARAM)&chrg);
			assert(chrg.cpMax >= chrg.cpMin);
			return chrg.cpMax - chrg.cpMin;
		}
		return 0;
	}
	
	
	///
	override @property void selectionStart(uint pos) // setter
	{
		if(created)
		{
			CHARRANGE chrg;
			SendMessageA(handle, EM_EXGETSEL, 0, cast(LPARAM)&chrg);
			assert(chrg.cpMax >= chrg.cpMin);
			chrg.cpMax = pos + (chrg.cpMax - chrg.cpMin);
			chrg.cpMin = pos;
			SendMessageA(handle, EM_EXSETSEL, 0, cast(LPARAM)&chrg);
		}
	}
	
	
	// Current selection starting index, in characters.
	// This does not necessarily correspond to the index of chars; some characters use multiple chars.
	// An end of line (\r\n) takes up 2 characters.
	override @property uint selectionStart() // getter
	{
		if(created)
		{
			CHARRANGE chrg;
			SendMessageA(handle, EM_EXGETSEL, 0, cast(LPARAM)&chrg);
			return chrg.cpMin;
		}
		return 0;
	}
	
	
	///
	override @property void maxLength(uint len) // setter
	{
		_lim = len;
		
		if(created)
			SendMessageA(handle, EM_EXLIMITTEXT, 0, cast(LPARAM)len);
	}
	
	/// ditto
	alias maxLength = TextBoxBase.maxLength; // Overload.
	
	
	///
	override @property Size defaultSize() // getter
	{
		return Size(100, 96);
	}
	
	
	///
	private void _setBackColor(Color c)
	{
		if(created)
		{
			if(c._systemColorIndex == COLOR_WINDOW)
				SendMessageA(handle, EM_SETBKGNDCOLOR, 1, 0);
			else
				SendMessageA(handle, EM_SETBKGNDCOLOR, 0, cast(LPARAM)c.toRgb());
		}
	}
	
	
	///
	override @property void backColor(Color c) // setter
	{
		_setBackColor(c);
		super.backColor(c);
	}
	
	/// ditto
	alias backColor = TextBoxBase.backColor; // Overload.
	
	
	///
	private void _setForeColor(Color c)
	{
		if(created)
		{
			CHARFORMAT2A cf;
			
			cf.cbSize = cf.sizeof;
			cf.dwMask = CFM_COLOR;
			if(c._systemColorIndex == COLOR_WINDOWTEXT)
				cf.dwEffects = CFE_AUTOCOLOR;
			else
				cf.crTextColor = c.toRgb();
			
			_setFormat(&cf, SCF_ALL);
		}
	}
	
	
	///
	override @property void foreColor(Color c) // setter
	{
		_setForeColor(c);
		super.foreColor(c);
	}
	
	/// ditto
	alias foreColor = TextBoxBase.foreColor; // Overload.
	
	
	///
	final @property bool canRedo() // getter
	{
		if(!created)
			return false;
		return SendMessageA(handle, EM_CANREDO, 0, 0) != 0;
	}
	
	
	///
	final bool canPaste(DataFormats.Format df)
	{
		if(created)
		{
			if(SendMessageA(handle, EM_CANPASTE, df.id, 0))
				return true;
		}
		
		return false;
	}
	
	
	///
	final void redo()
	{
		if(created)
			SendMessageA(handle, EM_REDO, 0, 0);
	}
	
	
	///
	// "Paste special."
	final void paste(DataFormats.Format df)
	{
		if(created)
		{
			SendMessageA(handle, EM_PASTESPECIAL, df.id, cast(LPARAM)0);
		}
	}
	
	/// ditto
	alias paste = TextBoxBase.paste; // Overload.
	
	
	///
	final @property void selectionCharOffset(int yoffset) // setter
	{
		if(!created)
			return;
		
		CHARFORMAT2A cf;
		
		cf.cbSize = cf.sizeof;
		cf.dwMask = CFM_OFFSET;
		cf.yOffset = yoffset;
		
		_setFormat(&cf);
	}
	
	/// ditto
	final @property int selectionCharOffset() // getter
	{
		if(created)
		{
			CHARFORMAT2A cf;
			cf.cbSize = cf.sizeof;
			cf.dwMask = CFM_OFFSET;
			_getFormat(&cf);
			return cf.yOffset;
		}
		return 0;
	}
	
	
	///
	final @property void selectionColor(Color c) // setter
	{
		if(!created)
			return;
		
		CHARFORMAT2A cf;
		
		cf.cbSize = cf.sizeof;
		cf.dwMask = CFM_COLOR;
		if(c._systemColorIndex == COLOR_WINDOWTEXT)
			cf.dwEffects = CFE_AUTOCOLOR;
		else
			cf.crTextColor = c.toRgb();
		
		_setFormat(&cf);
	}
	
	/// ditto
	final @property Color selectionColor() // getter
	{
		if(created)
		{
			CHARFORMAT2A cf;
			
			cf.cbSize = cf.sizeof;
			cf.dwMask = CFM_COLOR;
			_getFormat(&cf);
			
			if(cf.dwMask & CFM_COLOR)
			{
				if(cf.dwEffects & CFE_AUTOCOLOR)
					return Color.systemColor(COLOR_WINDOWTEXT);
				return Color.fromRgb(cf.crTextColor);
			}
		}
		return Color.empty;
	}
	
	
	///
	final @property void selectionBackColor(Color c) // setter
	{
		if(!created)
			return;
		
		CHARFORMAT2A cf;
		
		cf.cbSize = cf.sizeof;
		cf.dwMask = CFM_BACKCOLOR;
		if(c._systemColorIndex == COLOR_WINDOW)
			cf.dwEffects = CFE_AUTOBACKCOLOR;
		else
			cf.crBackColor = c.toRgb();
		
		_setFormat(&cf);
	}
	
	/// ditto
	final @property Color selectionBackColor() // getter
	{
		if(created)
		{
			CHARFORMAT2A cf;
			
			cf.cbSize = cf.sizeof;
			cf.dwMask = CFM_BACKCOLOR;
			_getFormat(&cf);
			
			if(cf.dwMask & CFM_BACKCOLOR)
			{
				if(cf.dwEffects & CFE_AUTOBACKCOLOR)
					return Color.systemColor(COLOR_WINDOW);
				return Color.fromRgb(cf.crBackColor);
			}
		}
		return Color.empty;
	}
	
	
	///
	final @property void selectionSubscript(bool byes) // setter
	{
		if(!created)
			return;
		
		CHARFORMAT2A cf;
		
		cf.cbSize = cf.sizeof;
		cf.dwMask = CFM_SUPERSCRIPT | CFM_SUBSCRIPT;
		if(byes)
		{
			cf.dwEffects = CFE_SUBSCRIPT;
		}
		else
		{
			// Make sure it doesn't accidentally unset superscript.
			CHARFORMAT2A cf2get;
			cf2get.cbSize = cf2get.sizeof;
			cf2get.dwMask = CFM_SUPERSCRIPT | CFM_SUBSCRIPT;
			_getFormat(&cf2get);
			if(cf2get.dwEffects & CFE_SUPERSCRIPT)
				return; // Superscript is set, so don't bother.
			if(!(cf2get.dwEffects & CFE_SUBSCRIPT))
				return; // Don't need to unset twice.
		}
		
		_setFormat(&cf);
	}
	
	/// ditto
	final @property bool selectionSubscript() // getter
	{
		if(created)
		{
			CHARFORMAT2A cf;
			
			cf.cbSize = cf.sizeof;
			cf.dwMask = CFM_SUPERSCRIPT | CFM_SUBSCRIPT;
			_getFormat(&cf);
			
			return (cf.dwEffects & CFE_SUBSCRIPT) == CFE_SUBSCRIPT;
		}
		return false;
	}
	
	
	///
	final @property void selectionSuperscript(bool byes) // setter
	{
		if(!created)
			return;
		
		CHARFORMAT2A cf;
		
		cf.cbSize = cf.sizeof;
		cf.dwMask = CFM_SUPERSCRIPT | CFM_SUBSCRIPT;
		if(byes)
		{
			cf.dwEffects = CFE_SUPERSCRIPT;
		}
		else
		{
			// Make sure it doesn't accidentally unset subscript.
			CHARFORMAT2A cf2get;
			cf2get.cbSize = cf2get.sizeof;
			cf2get.dwMask = CFM_SUPERSCRIPT | CFM_SUBSCRIPT;
			_getFormat(&cf2get);
			if(cf2get.dwEffects & CFE_SUBSCRIPT)
				return; // Subscript is set, so don't bother.
			if(!(cf2get.dwEffects & CFE_SUPERSCRIPT))
				return; // Don't need to unset twice.
		}
		
		_setFormat(&cf);
	}
	
	/// ditto
	final @property bool selectionSuperscript() // getter
	{
		if(created)
		{
			CHARFORMAT2A cf;
			
			cf.cbSize = cf.sizeof;
			cf.dwMask = CFM_SUPERSCRIPT | CFM_SUBSCRIPT;
			_getFormat(&cf);
			
			return (cf.dwEffects & CFE_SUPERSCRIPT) == CFE_SUPERSCRIPT;
		}
		return false;
	}
	
	
	///
	private enum DWORD FONT_MASK = CFM_BOLD | CFM_ITALIC | CFM_STRIKEOUT |
		CFM_UNDERLINE | CFM_CHARSET | CFM_FACE | CFM_SIZE | CFM_UNDERLINETYPE | CFM_WEIGHT;
	
	///
	final @property void selectionFont(Font f) // setter
	{
		if(created)
		{
			// TODO: support Unicode font names.
			
			CHARFORMAT2A cf;
			LOGFONTA lf;
			
			f._info(&lf);
			
			cf.cbSize = cf.sizeof;
			cf.dwMask = FONT_MASK;
			
			//cf.dwEffects = 0;
			if(lf.lfWeight >= FW_BOLD)
				cf.dwEffects |= CFE_BOLD;
			if(lf.lfItalic)
				cf.dwEffects |= CFE_ITALIC;
			if(lf.lfStrikeOut)
				cf.dwEffects |= CFE_STRIKEOUT;
			if(lf.lfUnderline)
				cf.dwEffects |= CFE_UNDERLINE;
			cf.yHeight = cast(typeof(cf.yHeight))Font.getEmSize(lf.lfHeight, GraphicsUnit.TWIP);
			cf.bCharSet = lf.lfCharSet;
			cf.szFaceName = lf.lfFaceName;
			cf.bUnderlineType = CFU_UNDERLINE;
			cf.wWeight = cast(WORD)lf.lfWeight;
			
			_setFormat(&cf);
		}
	}
	
	/// ditto
	// Returns null if the selection has different fonts.
	final @property Font selectionFont() // getter
	{
		if(created)
		{
			CHARFORMAT2A cf;
			
			cf.cbSize = cf.sizeof;
			cf.dwMask = FONT_MASK;
			_getFormat(&cf);
			
			if((cf.dwMask & FONT_MASK) == FONT_MASK)
			{
				LOGFONTA lf;
				with(lf)
				{
					lfHeight = -Font.getLfHeight(cast(float)cf.yHeight, GraphicsUnit.TWIP);
					lfWidth = 0; // TODO: ?
					lfEscapement = 0; // TODO: ?
					lfOrientation = 0; // TODO: ?
					lfWeight = cf.wWeight;
					if(cf.dwEffects & CFE_BOLD)
					{
						if(lfWeight < FW_BOLD)
							lfWeight = FW_BOLD;
					}
					lfItalic = (cf.dwEffects & CFE_ITALIC) != 0;
					lfUnderline = (cf.dwEffects & CFE_UNDERLINE) != 0;
					lfStrikeOut = (cf.dwEffects & CFE_STRIKEOUT) != 0;
					lfCharSet = cf.bCharSet;
					lfFaceName = cf.szFaceName;
					lfOutPrecision = OUT_DEFAULT_PRECIS;
					lf.lfClipPrecision = CLIP_DEFAULT_PRECIS;
					lf.lfQuality = DEFAULT_QUALITY;
					lf.lfPitchAndFamily = DEFAULT_PITCH | FF_DONTCARE;
				}
				//return new Font(Font._create(&lf));
				LogFont _lf;
				Font.LOGFONTAtoLogFont(_lf, &lf);
				return new Font(Font._create(_lf));
			}
		}
		
		return null;
	}
	
	
	///
	final @property void selectionBold(bool byes) // setter
	{
		if(!created)
			return;
		
		CHARFORMAT2A cf;
		
		cf.cbSize = cf.sizeof;
		cf.dwMask = CFM_BOLD;
		if(byes)
			cf.dwEffects |= CFE_BOLD;
		else
			cf.dwEffects &= ~CFE_BOLD;
		_setFormat(&cf);
	}
	
	/// ditto
	final @property bool selectionBold() // getter
	{
		if(created)
		{
			CHARFORMAT2A cf;
			
			cf.cbSize = cf.sizeof;
			cf.dwMask = CFM_BOLD;
			_getFormat(&cf);
			
			return (cf.dwEffects & CFE_BOLD) == CFE_BOLD;
		}
		return false;
	}
	
	
	///
	final @property void selectionUnderline(bool byes) // setter
	{
		if(!created)
			return;
		
		CHARFORMAT2A cf;
		
		cf.cbSize = cf.sizeof;
		cf.dwMask = CFM_UNDERLINE;
		if(byes)
			cf.dwEffects |= CFE_UNDERLINE;
		else
			cf.dwEffects &= ~CFE_UNDERLINE;
		_setFormat(&cf);
	}
	
	/// ditto
	final @property bool selectionUnderline() // getter
	{
		if(created)
		{
			CHARFORMAT2A cf;
			
			cf.cbSize = cf.sizeof;
			cf.dwMask = CFM_UNDERLINE;
			_getFormat(&cf);
			
			return (cf.dwEffects & CFE_UNDERLINE) == CFE_UNDERLINE;
		}
		return false;
	}
	
	
	///
	final @property void scrollBars(RichTextBoxScrollBars sb) // setter
	{
		LONG st = _style() & ~(ES_DISABLENOSCROLL | WS_HSCROLL | WS_VSCROLL |
			ES_AUTOHSCROLL | ES_AUTOVSCROLL);
		
		final switch(sb)
		{
			case RichTextBoxScrollBars.FORCED_BOTH:
				st |= ES_DISABLENOSCROLL;
				goto case RichTextBoxScrollBars.BOTH;
			case RichTextBoxScrollBars.BOTH:
				st |= WS_HSCROLL | WS_VSCROLL | ES_AUTOHSCROLL | ES_AUTOVSCROLL;
				break;
			
			case RichTextBoxScrollBars.FORCED_HORIZONTAL:
				st |= ES_DISABLENOSCROLL;
				goto case RichTextBoxScrollBars.HORIZONTAL;
			case RichTextBoxScrollBars.HORIZONTAL:
				st |= WS_HSCROLL | ES_AUTOHSCROLL;
				break;
			
			case RichTextBoxScrollBars.FORCED_VERTICAL:
				st |= ES_DISABLENOSCROLL;
				goto case RichTextBoxScrollBars.VERTICAL;
			case RichTextBoxScrollBars.VERTICAL:
				st |= WS_VSCROLL | ES_AUTOVSCROLL;
				break;
			
			case RichTextBoxScrollBars.NONE:
				break;
		}
		
		_style(st);
		
		_crecreate();
	}
	
	/// ditto
	final @property RichTextBoxScrollBars scrollBars() // getter
	{
		LONG wl = _style();
		
		if(wl & WS_HSCROLL)
		{
			if(wl & WS_VSCROLL)
			{
				if(wl & ES_DISABLENOSCROLL)
					return RichTextBoxScrollBars.FORCED_BOTH;
				return RichTextBoxScrollBars.BOTH;
			}
			
			if(wl & ES_DISABLENOSCROLL)
				return RichTextBoxScrollBars.FORCED_HORIZONTAL;
			return RichTextBoxScrollBars.HORIZONTAL;
		}
		
		if(wl & WS_VSCROLL)
		{
			if(wl & ES_DISABLENOSCROLL)
				return RichTextBoxScrollBars.FORCED_VERTICAL;
			return RichTextBoxScrollBars.VERTICAL;
		}
		
		return RichTextBoxScrollBars.NONE;
	}
	
	
	///
	override int getLineFromCharIndex(int charIndex)
	{
		if(!isHandleCreated)
			return -1; // ...
		if(charIndex < 0)
			return -1;
		return SendMessageA(hwnd, EM_EXLINEFROMCHAR, 0, charIndex).toI32;
	}
	
	
	///
	private void _getFormat(CHARFORMAT2A* cf, BOOL selection = TRUE)
	in
	{
		assert(created);
	}
	do
	{
		//SendMessageA(handle, EM_GETCHARFORMAT, selection, cast(LPARAM)cf);
		//CallWindowProcA(richtextboxPrevWndProc, hwnd, EM_GETCHARFORMAT, selection, cast(LPARAM)cf);
		dfl.internal.utf.callWindowProc(richtextboxPrevWndProc, hwnd, EM_GETCHARFORMAT, selection, cast(LPARAM)cf);
	}
	
	
	///
	private void _setFormat(CHARFORMAT2A* cf, WPARAM scf = SCF_SELECTION)
	in
	{
		assert(created);
	}
	do
	{
		/+
		//if(!SendMessageA(handle, EM_SETCHARFORMAT, scf, cast(LPARAM)cf))
		//if(!CallWindowProcA(richtextboxPrevWndProc, hwnd, EM_SETCHARFORMAT, scf, cast(LPARAM)cf))
		if(!dfl.internal.utf.callWindowProc(richtextboxPrevWndProc, hwnd, EM_SETCHARFORMAT, scf, cast(LPARAM)cf))
			throw new DflException("Unable to set text formatting");
		+/
		dfl.internal.utf.callWindowProc(richtextboxPrevWndProc, hwnd, EM_SETCHARFORMAT, scf, cast(LPARAM)cf);
	}
	
	
	///
	private struct _StreamStr
	{
		Dstring str;
	}
	
	
	///
	private void _streamIn(UINT fmt, Dstring str)
	in
	{
		assert(created);
	}
	do
	{
		_StreamStr si;
		si.str = str;

		EDITSTREAM es;
		es.dwCookie = cast(DWORD_PTR)&si;
		es.dwError = 0;
		es.pfnCallback = &_streamingInStr;
		
		//if(SendMessageW(handle, EM_STREAMIN, cast(WPARAM)fmt, cast(LPARAM)&es) != str.length)
		//	throw new DflException("Unable to set RTF");
		
		SendMessageW(handle, EM_STREAMIN, cast(WPARAM)fmt, cast(LPARAM)&es);
		assert(es.dwError == 0);
	}
	
	
	///
	private Dstring _streamOut(UINT fmt)
	in
	{
		assert(created);
	}
	do
	{
		_StreamStr so;

		EDITSTREAM es;
		es.dwCookie = cast(DWORD_PTR)&so;
		es.dwError = 0;
		es.pfnCallback = &_streamingOutStr;

		SendMessageW(handle, EM_STREAMOUT, cast(WPARAM)fmt, cast(LPARAM)&es);
		assert(es.dwError == 0);

		return so.str;
	}
	
	
	///
	final @property void selectedRtf(Dstring newRtf) // setter
	{
		_streamIn(SF_RTF | SF_UNICODE | SFF_SELECTION, newRtf);
	}
	
	/// ditto
	final @property Dstring selectedRtf() // getter
	{
		return _streamOut(SF_RTF | SF_UNICODE | SFF_SELECTION);
	}
	
	
	///
	final @property void rtf(Dstring newRtf) // setter
	{
		_streamIn(SF_RTF | SF_UNICODE, newRtf);
	}
	
	/// ditto
	final @property Dstring rtf() // getter
	{
		return _streamOut(SF_RTF | SF_UNICODE);
	}
	
	
	///
	final @property void detectUrls(bool byes) // setter
	{
		_autoUrl = byes;
		
		if(created)
		{
			SendMessageA(handle, EM_AUTOURLDETECT, byes, 0);
		}
	}
	
	/// ditto
	final @property bool detectUrls() // getter
	{
		return _autoUrl;
	}
	
	
	/+
	override void createHandle()
	{
		if(isHandleCreated)
			return;
		
		createClassHandle(RICHTEXTBOX_CLASSNAME);
		
		onHandleCreated(EventArgs.empty);
	}
	+/
	
	
	/+
	override void createHandle()
	{
		/+ // TextBoxBase.createHandle() does this.
		if(!isHandleCreated)
		{
			Dstring txt;
			txt = wtext;
			
			super.createHandle();
			
			//dfl.internal.utf.setWindowText(hwnd, txt);
			text = txt; // So that it can be overridden.
		}
		+/
	}
	+/
	
	
	Event!(RichTextBox, LinkClickedEventArgs) linkClicked; ///
	
	
protected:
	
	///
	override void createParams(ref CreateParams cp)
	{
		super.createParams(cp);
		
		cp.className = RICHTEXTBOX_CLASSNAME;
		//cp.caption = null; // Set in createHandle() to allow larger buffers. // TextBoxBase.createHandle() does this.
	}


	///
	void onLinkClicked(LinkClickedEventArgs ea)
	{
		linkClicked(this, ea);
	}
	
	
	///
	// min : Index of start on text, not bytes.
	// max : Index of end on text, not bytes.
	private Dstring _getRange(in LONG min, in LONG max)
	in
	{
		assert(created);
		assert(min >= 0);
		assert(max >= -1); // When -max- == -1, contains all text in range.
	}
	do
	{
		if(min == max)
			return null; // Empty range.
		else if (max != -1 && min > max)
			return null; // Illigal range.
		
		const size_t textLength = {
			if (max >= 0)
			{
				return max - min + 1; // 1 : null terminate.
			}
			else if (max == -1)
			{
				// When -max- == -1, contains all text in range.
				return text.length - min + 1; // 1 : null terminate.
			}
			else
			{
				assert(0);
			}
		}();

		static if (dfl.internal.utf.useUnicode)
		{
			TEXTRANGEW tr;
			tr.chrg.cpMin = min;
			tr.chrg.cpMax = max;
			wchar[] s = new wchar[textLength];
			tr.lpstrText = s.ptr;
			const uint copiedLength = SendMessageW(handle, EM_GETTEXTRANGE, 0, cast(LPARAM)&tr).toI32;
			Dstring result = fromUnicode(s.ptr, copiedLength);
			return result;
		}
		else
		{
			TEXTRANGEA tr;
			tr.chrg.cpMin = min;
			tr.chrg.cpMax = max;
			char[] s = new char[textLength];
			tr.lpstrText = s.ptr;
			const uint copiedLength = SendMessageA(handle, EM_GETTEXTRANGE, 0, cast(LPARAM)&tr).toI32;
			Dstring result = fromAnsi(s.ptr, copiedLength);
			return result;
		}
	}

	///
	override void onReflectedMessage(ref Message m)
	{
		super.onReflectedMessage(m);
		
		switch (m.msg)
		{
			case WM_NOTIFY:
			{
				NMHDR* nmh = cast(NMHDR*)m.lParam;
				assert(nmh.hwndFrom == handle);
				switch (nmh.code)
				{
					case EN_LINK:
					{
						ENLINK* enl = cast(ENLINK*)m.lParam;
						if (enl.msg == WM_LBUTTONUP)
						{
							Dstring linkText = _getRange(enl.chrg.cpMin, enl.chrg.cpMax);
							onLinkClicked(new LinkClickedEventArgs(linkText));
							m.result = 1;
						}
						break;
					}
					default:
					{
						// DO nothing.
					}
				}
				break;
			}
			default:
			{
				// Do nothing.
			}
		}
	}
	
	
	///
	override void onHandleCreated(EventArgs ea)
	{
		super.onHandleCreated(ea);
		
		SendMessageA(handle, EM_AUTOURLDETECT, _autoUrl, 0);
		SendMessageA(handle, EM_SETEVENTMASK, 0, ENM_LINK);
		
		_setBackColor(this.backColor);
		
		//Application.doEvents(); // foreColor won't work otherwise.. seems to work now
		_setForeColor(this.foreColor);
	}
	
	
	///
	override void prevWndProc(ref Message m)
	{
		// m.result = CallWindowProcA(richtextboxPrevWndProc, m.hWnd, m.msg, m.wParam, m.lParam);
		m.result = dfl.internal.utf.callWindowProc(richtextboxPrevWndProc, m.hWnd, m.msg, m.wParam, m.lParam);
	}


	///
	final LRESULT prevwproc(UINT msg, WPARAM wparam, LPARAM lparam)
	{
		return dfl.internal.utf.callWindowProc(richtextboxPrevWndProc, hwnd, msg, wparam, lparam);
	}
	
	
private:
	bool _autoUrl = true;
}


///
// dwCookie : Value of the dwCookie member of the EDITSTREAM structure.
// pbBuff   : Pointer to a buffer to read from or write to.
// cb       : Number of bytes to read or write.
// pcb      : Pointer to a variable that the callback function sets to the number of bytes actually read or written.
private extern(Windows) DWORD _streamingInStr(DWORD_PTR dwCookie, LPBYTE pbBuff, LONG cb, LONG* pcb) nothrow
{
	RichTextBox._StreamStr* si = cast(RichTextBox._StreamStr*)dwCookie;
	
	if (!si || !si.str.length)
	{
		*pcb = 0;
		return 1; // Non-zero is error code.
	}
	
	if (cb >= si.str.length)
	{
		pbBuff[0 .. si.str.length] = (cast(BYTE[])si.str)[];
		*pcb = si.str.length.toI32;
		si.str = null;
	}
	else
	{
		pbBuff[0 .. cb] = (cast(BYTE[])si.str)[0 .. cb];
		*pcb = cb;
		si.str = si.str[cb .. si.str.length];
	}
	
	return 0;
}


///
// dwCookie : Value of the dwCookie member of the EDITSTREAM structure.
// pbBuff   : Pointer to a buffer to read from or write to.
// cb       : Number of bytes to read or write.
// pcb      : Pointer to a variable that the callback function sets to the number of bytes actually read or written.
extern(Windows) DWORD _streamingOutStr(DWORD_PTR dwCookie, LPBYTE pbBuff, LONG cb, LONG* pcb) nothrow
{
	RichTextBox._StreamStr* so = cast(RichTextBox._StreamStr*)dwCookie;
	so.str ~= cast(Dstring)pbBuff[0 .. cb];
	*pcb = cb;
	return 0;
}


private DialogResult _msgBoxNothrow(Dstring msg) nothrow
{
	import dfl.messagebox;
	try
	{
		return msgBox(msg);
	}
	catch (Exception e)
	{
		return DialogResult.NONE;
	}
}