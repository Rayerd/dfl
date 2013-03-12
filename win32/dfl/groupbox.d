// Written by Christopher E. Miller
// See the included license.txt for copyright and license details.


///
module dfl.groupbox;

private import dfl.control, dfl.base, dfl.button, dfl.drawing;
private import dfl.internal.winapi, dfl.application, dfl.event;


private extern(Windows) void _initButton();


version(NO_DRAG_DROP)
	version = DFL_NO_DRAG_DROP;


///
class GroupBox: ControlSuperClass // docmain
{
	override @property Rect displayRectangle() // getter
	{
		// Should only calculate this upon setting the text ?
		
		int xw = GetSystemMetrics(SM_CXFRAME);
		int yw = GetSystemMetrics(SM_CYFRAME);
		//const int _textHeight = 13; // Hack.
		return Rect(xw, yw + _textHeight, clientSize.width - xw * 2, clientSize.height - yw - _textHeight - yw);
	}
	
	
	override @property Size defaultSize() // getter
	{
		return Size(200, 100);
	}
	
	
	version(DFL_NO_DRAG_DROP) {} else
	{
		override @property void allowDrop(bool dyes) // setter
		{
			//if(dyes)
			//	throw new DflException("Cannot drop on a group box");
			assert(!dyes, "Cannot drop on a group box");
		}
		
		alias Control.allowDrop allowDrop; // Overload.
	}
	
	
	this()
	{
		_initButton();
		
		if(DEFTEXTHEIGHT_INIT == _defTextHeight)
		{
			//_recalcTextHeight(defaultFont);
			_recalcTextHeight(font);
			_defTextHeight = _textHeight;
		}
		_textHeight = _defTextHeight;
		
		wstyle |= BS_GROUPBOX /+ | WS_TABSTOP +/; // Should WS_TABSTOP be set?
		//wstyle |= BS_GROUPBOX | WS_TABSTOP;
		//wexstyle |= WS_EX_CONTROLPARENT; // ?
		wclassStyle = buttonClassStyle;
		ctrlStyle |= ControlStyles.CONTAINER_CONTROL;
	}
	
	
	protected override void onFontChanged(EventArgs ea)
	{
		_dispChanged();
		
		super.onFontChanged(ea);
	}
	
	
	protected override void onHandleCreated(EventArgs ea)
	{
		super.onHandleCreated(ea);
		
		_dispChanged();
	}
	
	
	protected override void createParams(ref CreateParams cp)
	{
		super.createParams(cp);
		
		cp.className = BUTTON_CLASSNAME;
	}
	
	
	protected override void wndProc(ref Message msg)
	{
		switch(msg.msg)
		{
			case WM_NCHITTEST:
				Control._defWndProc(msg);
				break;
			
			default:
				super.wndProc(msg);
		}
	}
	
	
	protected override void onPaintBackground(PaintEventArgs ea)
	{
		//Control.onPaintBackground(ea); // DMD 0.106: not accessible.
		
		RECT rect;
		ea.clipRectangle.getRect(&rect);
		FillRect(ea.graphics.handle, &rect, hbrBg);
	}
	
	
	protected override void prevWndProc(ref Message msg)
	{
		//msg.result = CallWindowProcA(buttonPrevWndProc, msg.hWnd, msg.msg, msg.wParam, msg.lParam);
		msg.result = dfl.internal.utf.callWindowProc(buttonPrevWndProc, msg.hWnd, msg.msg, msg.wParam, msg.lParam);
		
		// Work around a Windows issue...
		if(WM_PAINT == msg.msg)
		{
			auto hmuxt = GetModuleHandleA("uxtheme.dll");
			if(hmuxt)
			{
				auto isAppThemed = cast(typeof(&IsAppThemed))GetProcAddress(hmuxt, "IsAppThemed");
				if(isAppThemed && isAppThemed())
				{
					auto txt = text;
					if(txt.length)
					{
						auto openThemeData = cast(typeof(&OpenThemeData))GetProcAddress(hmuxt, "OpenThemeData");
						HTHEME htd;
						if(openThemeData
							&& HTHEME.init != (htd = openThemeData(msg.hWnd, "Button")))
						{
							HDC hdc = cast(HDC)msg.wParam;
							//PAINTSTRUCT ps;
							bool gotdc = false;
							if(!hdc)
							{
								//hdc = BeginPaint(msg.hWnd, &ps);
								gotdc = true;
								hdc = GetDC(msg.hWnd);
							}
							try
							{
								scope g = new Graphics(hdc, false); // Not owned.
								auto f = font;
								scope tfmt = new TextFormat(TextFormatFlags.SINGLE_LINE);
								
								Color c;
								COLORREF cr;
								auto getThemeColor = cast(typeof(&GetThemeColor))GetProcAddress(hmuxt, "GetThemeColor");
								auto gtcState = enabled ? (1 /*PBS_NORMAL*/) : (2 /*GBS_DISABLED*/);
								if(getThemeColor
									&& 0 == getThemeColor(htd, 4 /*BP_GROUPBOX*/, gtcState, 3803 /*TMT_TEXTCOLOR*/, &cr))
									c = Color.fromRgb(cr);
								else
									c = enabled ? foreColor : SystemColors.grayText; // ?
								
								Size tsz = g.measureText(txt, f, tfmt);
								
								g.fillRectangle(backColor, 8, 0, 2 + tsz.width + 2, tsz.height + 2);
								g.drawText(txt, f, c, Rect(8 + 2, 0, tsz.width, tsz.height), tfmt);
							}
							finally
							{
								//if(ps.hdc)
								//	EndPaint(msg.hWnd, &ps);
								if(gotdc)
									ReleaseDC(msg.hWnd, hdc);
								
								auto closeThemeData = cast(typeof(&CloseThemeData))GetProcAddress(hmuxt, "CloseThemeData");
								assert(closeThemeData !is null);
								closeThemeData(htd);
							}
						}
					}
				}
			}
		}
	}
	
	
	private:
	
	enum int DEFTEXTHEIGHT_INIT = -1;
	static int _defTextHeight = DEFTEXTHEIGHT_INIT;
	int _textHeight = -1;
	
	
	void _recalcTextHeight(Font f)
	{
		_textHeight = cast(int)f.getSize(GraphicsUnit.PIXEL);
	}
	
	
	void _dispChanged()
	{
		int old = _textHeight;
		_recalcTextHeight(font);
		if(old != _textHeight)
		{
			//if(isHandleCreated)
			{
				// Display area changed...
				// ?
				suspendLayout();
				resumeLayout(true);
			}
		}
	}
}

