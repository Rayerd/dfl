// Written by Christopher E. Miller
// See the included license.txt for copyright and license details.


///
module dfl.groupbox;

private import dfl.control, dfl.base, dfl.button, dfl.drawing;
private import dfl.internal.winapi, dfl.application, dfl.event;


private extern(Windows) void _initButton();


///
class GroupBox: ControlSuperClass // docmain
{
	override Rect displayRectangle() // getter
	{
		// Should only calculate this upon setting the text ?
		
		int xw = GetSystemMetrics(SM_CXFRAME);
		int yw = GetSystemMetrics(SM_CYFRAME);
		//const int _textHeight = 13; // Hack.
		return Rect(xw, yw + _textHeight, clientSize.width - xw * 2, clientSize.height - yw - _textHeight - yw);
	}
	
	
	override Size defaultSize() // getter
	{
		return Size(200, 100);
	}
	
	
	version(NO_DRAG_DROP) {} else
	{
		void allowDrop(bool dyes) // setter
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
			_recalcTextHeight(defaultFont);
			_defTextHeight = _textHeight;
		}
		_textHeight = _defTextHeight;
		
		wstyle |= BS_GROUPBOX /+ | WS_TABSTOP +/; // Should WS_TABSTOP be set?
		//wstyle |= BS_GROUPBOX | WS_TABSTOP;
		wexstyle |= WS_EX_CONTROLPARENT;
		wclassStyle = buttonClassStyle;
		ctrlStyle |= ControlStyles.CONTAINER_CONTROL;
	}
	
	
	protected void onFontChanged(EventArgs ea)
	{
		_dispChanged();
		
		super.onFontChanged(ea);
	}
	
	
	protected void onHandleCreated(EventArgs ea)
	{
		super.onHandleCreated(ea);
		
		_dispChanged();
	}
	
	
	protected override void createParams(inout CreateParams cp)
	{
		super.createParams(cp);
		
		cp.className = BUTTON_CLASSNAME;
	}
	
	
	protected override void wndProc(inout Message msg)
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
	
	
	protected override void prevWndProc(inout Message msg)
	{
		//msg.result = CallWindowProcA(buttonPrevWndProc, msg.hWnd, msg.msg, msg.wParam, msg.lParam);
		msg.result = dfl.internal.utf.callWindowProc(buttonPrevWndProc, msg.hWnd, msg.msg, msg.wParam, msg.lParam);
	}
	
	
	private:
	
	const int DEFTEXTHEIGHT_INIT = -1;
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

