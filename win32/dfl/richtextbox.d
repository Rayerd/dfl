// Written by Christopher E. Miller
// See the included license.txt for copyright and license details.


///
module dfl.richtextbox;

private import dfl.textbox, dfl.internal.winapi, dfl.event, dfl.application;
private import dfl.base, dfl.drawing, dfl.data;
private import dfl.control, dfl.internal.utf, dfl.internal.dlib;

version(DFL_NO_MENUS)
{
}
else
{
	private import dfl.menu;
}


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
	this()
	{
		super();
		
		_initRichtextbox();
		
		wstyle |= ES_MULTILINE | ES_WANTRETURN | ES_AUTOHSCROLL | ES_AUTOVSCROLL | WS_HSCROLL | WS_VSCROLL;
		wcurs = null; // So that the control can change it accordingly.
		wclassStyle = richtextboxClassStyle;
		
		version(DFL_NO_MENUS)
		{
		}
		else
		{
			with(miredo = new MenuItem)
			{
				text = "&Redo";
				click ~= &menuRedo;
				contextMenu.menuItems.insert(1, miredo);
			}
			
			contextMenu.popup ~= &menuPopup2;
		}
	}
	
	
	private
	{
		version(DFL_NO_MENUS)
		{
		}
		else
		{
			void menuRedo(Object sender, EventArgs ea)
			{
				redo();
			}
			
			
			void menuPopup2(Object sender, EventArgs ea)
			{
				miredo.enabled = canRedo;
			}
			
			
			MenuItem miredo;
		}
	}
	
	
	override @property Cursor cursor() // getter
	{
		return wcurs; // Do return null and don't inherit.
	}
	
	alias TextBoxBase.cursor cursor; // Overload.
	
	
	override @property Dstring selectedText() // getter
	{
		if(created)
		{
			/+
			uint len = selectionLength + 1;
			Dstring result = new char[len];
			len = SendMessageA(handle, EM_GETSELTEXT, 0, cast(LPARAM)cast(char*)result);
			assert(!result[len]);
			return result[0 .. len];
			+/
			
			return dfl.internal.utf.emGetSelText(hwnd, selectionLength + 1);
		}
		return null;
	}
	
	alias TextBoxBase.selectedText selectedText; // Overload.
	
	
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
	
	
	override @property void maxLength(uint len) // setter
	{
		lim = len;
		
		if(created)
			SendMessageA(handle, EM_EXLIMITTEXT, 0, cast(LPARAM)len);
	}
	
	alias TextBoxBase.maxLength maxLength; // Overload.
	
	
	override @property Size defaultSize() // getter
	{
		return Size(120, 120); // ?
	}
	
	
	private void _setbk(Color c)
	{
		if(created)
		{
			if(c._systemColorIndex == COLOR_WINDOW)
				SendMessageA(handle, EM_SETBKGNDCOLOR, 1, 0);
			else
				SendMessageA(handle, EM_SETBKGNDCOLOR, 0, cast(LPARAM)c.toRgb());
		}
	}
	
	
	override @property void backColor(Color c) // setter
	{
		_setbk(c);
		super.backColor(c);
	}
	
	alias TextBoxBase.backColor backColor; // Overload.
	
	
	private void _setfc(Color c)
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
	
	
	override @property void foreColor(Color c) // setter
	{
		_setfc(c);
		super.foreColor(c);
	}
	
	alias TextBoxBase.foreColor foreColor; // Overload.
	
	
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
			SendMessageA(handle, EM_PASTESPECIAL, df.id, cast(LPARAM)null);
		}
	}
	
	alias TextBoxBase.paste paste; // Overload.
	
	
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
	
	
	private enum DWORD FONT_MASK = CFM_BOLD | CFM_ITALIC | CFM_STRIKEOUT |
		CFM_UNDERLINE | CFM_CHARSET | CFM_FACE | CFM_SIZE | CFM_UNDERLINETYPE | CFM_WEIGHT;
	
	///
	final @property void selectionFont(Font f) // setter
	{
		if(created)
		{
			// To-do: support Unicode font names.
			
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
			strcpy(cf.szFaceName.ptr, lf.lfFaceName.ptr);
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
					lfWidth = 0; // ?
					lfEscapement = 0; // ?
					lfOrientation = 0; // ?
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
					strcpy(lfFaceName.ptr, cf.szFaceName.ptr);
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
		LONG st;
		st = _style() & ~(ES_DISABLENOSCROLL | WS_HSCROLL | WS_VSCROLL |
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
		return SendMessageA(hwnd, EM_EXLINEFROMCHAR, 0, charIndex);
	}
	
	
	private void _getFormat(CHARFORMAT2A* cf, BOOL selection = TRUE)
	in
	{
		assert(created);
	}
	body
	{
		//SendMessageA(handle, EM_GETCHARFORMAT, selection, cast(LPARAM)cf);
		//CallWindowProcA(richtextboxPrevWndProc, hwnd, EM_GETCHARFORMAT, selection, cast(LPARAM)cf);
		dfl.internal.utf.callWindowProc(richtextboxPrevWndProc, hwnd, EM_GETCHARFORMAT, selection, cast(LPARAM)cf);
	}
	
	
	private void _setFormat(CHARFORMAT2A* cf, WPARAM scf = SCF_SELECTION)
	in
	{
		assert(created);
	}
	body
	{
		/+
		//if(!SendMessageA(handle, EM_SETCHARFORMAT, scf, cast(LPARAM)cf))
		//if(!CallWindowProcA(richtextboxPrevWndProc, hwnd, EM_SETCHARFORMAT, scf, cast(LPARAM)cf))
		if(!dfl.internal.utf.callWindowProc(richtextboxPrevWndProc, hwnd, EM_SETCHARFORMAT, scf, cast(LPARAM)cf))
			throw new DflException("Unable to set text formatting");
		+/
		dfl.internal.utf.callWindowProc(richtextboxPrevWndProc, hwnd, EM_SETCHARFORMAT, scf, cast(LPARAM)cf);
	}
	
	
	private struct _StreamStr
	{
		Dstring str;
	}
	
	
	// Note: RTF should only be ASCII so no conversions are necessary.
	// TODO: verify this; I'm not certain.
	
	private void _streamIn(UINT fmt, Dstring str)
	in
	{
		assert(created);
	}
	body
	{
		_StreamStr si;
		EDITSTREAM es;
		
		si.str = str;
		es.dwCookie = cast(DWORD)&si;
		es.pfnCallback = &_streamingInStr;
		
		//if(SendMessageA(handle, EM_STREAMIN, cast(WPARAM)fmt, cast(LPARAM)&es) != str.length)
		//	throw new DflException("Unable to set RTF");
		
		SendMessageA(handle, EM_STREAMIN, cast(WPARAM)fmt, cast(LPARAM)&es);
	}
	
	
	private Dstring _streamOut(UINT fmt)
	in
	{
		assert(created);
	}
	body
	{
		_StreamStr so;
		EDITSTREAM es;
		
		so.str = null;
		es.dwCookie = cast(DWORD)&so;
		es.pfnCallback = &_streamingOutStr;
		
		SendMessageA(handle, EM_STREAMOUT, cast(WPARAM)fmt, cast(LPARAM)&es);
		return so.str;
	}
	
	
	///
	final @property void selectedRtf(Dstring rtf) // setter
	{
		_streamIn(SF_RTF | SFF_SELECTION, rtf);
	}
	
	/// ditto
	final @property Dstring selectedRtf() // getter
	{
		return _streamOut(SF_RTF | SFF_SELECTION);
	}
	
	
	///
	final @property void rtf(Dstring newRtf) // setter
	{
		_streamIn(SF_RTF, rtf);
	}
	
	/// ditto
	final @property Dstring rtf() // getter
	{
		return _streamOut(SF_RTF);
	}
	
	
	///
	final @property void detectUrls(bool byes) // setter
	{
		autoUrl = byes;
		
		if(created)
		{
			SendMessageA(handle, EM_AUTOURLDETECT, byes, 0);
		}
	}
	
	/// ditto
	final @property bool detectUrls() // getter
	{
		return autoUrl;
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
	
	
	protected override void createParams(ref CreateParams cp)
	{
		super.createParams(cp);
		
		cp.className = RICHTEXTBOX_CLASSNAME;
		//cp.caption = null; // Set in createHandle() to allow larger buffers. // TextBoxBase.createHandle() does this.
	}
	
	
	//LinkClickedEventHandler linkClicked;
	Event!(RichTextBox, LinkClickedEventArgs) linkClicked; ///
	
	
	protected:
	
	///
	void onLinkClicked(LinkClickedEventArgs ea)
	{
		linkClicked(this, ea);
	}
	
	
	private Dstring _getRange(LONG min, LONG max)
	in
	{
		assert(created);
		assert(max >= 0);
		assert(max >= min);
	}
	body
	{
		if(min == max)
			return null;
		
		TEXTRANGEA tr;
		char[] s;
		
		tr.chrg.cpMin = min;
		tr.chrg.cpMax = max;
		max = max - min + 1;
		if(dfl.internal.utf.useUnicode)
			max = cast(uint)max << 1;
		s = new char[max];
		tr.lpstrText = s.ptr;
		
		//max = SendMessageA(handle, EM_GETTEXTRANGE, 0, cast(LPARAM)&tr);
		max = dfl.internal.utf.sendMessage(handle, EM_GETTEXTRANGE, 0, cast(LPARAM)&tr);
		Dstring result;
		if(dfl.internal.utf.useUnicode)
			result = fromUnicode(cast(wchar*)s.ptr, max);
		else
			result = fromAnsi(s.ptr, max);
		return result;
	}
	
	
	protected override void onReflectedMessage(ref Message m)
	{
		super.onReflectedMessage(m);
		
		switch(m.msg)
		{
			case WM_NOTIFY:
				{
					NMHDR* nmh;
					nmh = cast(NMHDR*)m.lParam;
					
					assert(nmh.hwndFrom == handle);
					
					switch(nmh.code)
					{
						case EN_LINK:
							{
								ENLINK* enl;
								enl = cast(ENLINK*)nmh;
								
								if(enl.msg == WM_LBUTTONUP)
								{
									if(!selectionLength)
										onLinkClicked(new LinkClickedEventArgs(_getRange(enl.chrg.cpMin, enl.chrg.cpMax)));
								}
							}
							break;
							
						default:
					}
				}
				break;
			
			default:
		}
	}
	
	
	override void onHandleCreated(EventArgs ea)
	{
		super.onHandleCreated(ea);
		
		SendMessageA(handle, EM_AUTOURLDETECT, autoUrl, 0);
		
		_setbk(this.backColor);
		
		//Application.doEvents(); // foreColor won't work otherwise.. seems to work now
		_setfc(this.foreColor);
		
		SendMessageA(handle, EM_SETEVENTMASK, 0, ENM_CHANGE | ENM_CHANGE | ENM_LINK | ENM_PROTECTED);
	}
	
	
	override void prevWndProc(ref Message m)
	{
		m.result = CallWindowProcA(richtextboxPrevWndProc, m.hWnd, m.msg, m.wParam, m.lParam);
		//m.result = dfl.internal.utf.callWindowProc(richtextboxPrevWndProc, m.hWnd, m.msg, m.wParam, m.lParam);
	}
	
	
	private:
	bool autoUrl = true;
}


private extern(Windows) DWORD _streamingInStr(DWORD dwCookie, LPBYTE pbBuff, LONG cb, LONG* pcb) nothrow
{
	RichTextBox._StreamStr* si;
	si = cast(typeof(si))dwCookie;
	
	if(!si.str.length)
	{
		*pcb = 0;
		return 1; // ?
	}
	else if(cb >= si.str.length)
	{
		pbBuff[0 .. si.str.length] = (cast(BYTE[])si.str)[];
		*pcb = si.str.length;
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


private extern(Windows) DWORD _streamingOutStr(DWORD dwCookie, LPBYTE pbBuff, LONG cb, LONG* pcb) nothrow
{
	RichTextBox._StreamStr* so;
	so = cast(typeof(so))dwCookie;
	
	so.str ~= cast(Dstring)pbBuff[0 .. cb];
	*pcb = cb;
	
	return 0;
}

