// Written by Christopher E. Miller
// See the included license.txt for copyright and license details.


///
module dfl.groupbox;

import dfl.application;
import dfl.base;
import dfl.button;
import dfl.control;
import dfl.drawing;
import dfl.event;

import dfl.internal.dpiaware;
import dfl.internal.winapi;
static import dfl.internal.utf;


private extern(Windows) void _initButton();


version(NO_DRAG_DROP)
	version = DFL_NO_DRAG_DROP;


///
class GroupBox: ControlSuperClass // docmain
{
	this()
	{
		_initButton();
		
		if (DEFAULT_TEXT_HEIGHT_INIT == _defaultTextHeight)
		{
			//_recalcTextHeight(defaultFont);
			_recalcTextHeight(font);
			_defaultTextHeight = _textHeight;
		}
		_textHeight = _defaultTextHeight;
		
		_windowStyle |= BS_GROUPBOX /+ | WS_TABSTOP +/; // Should WS_TABSTOP be set?
		//wstyle |= BS_GROUPBOX | WS_TABSTOP;
		//wexstyle |= WS_EX_CONTROLPARENT; // ?
		_windowClassStyle = buttonClassStyle;
		_controlStyle |= ControlStyles.CONTAINER_CONTROL;
	}


	///
	override @property Rect displayRectangle() const // getter
	{
		// Should only calculate this upon setting the text ?
		
		int xw = GetSystemMetricsForDpi(SM_CXFRAME, dpi);
		int yw = GetSystemMetricsForDpi(SM_CYFRAME, dpi);
		//const int _textHeight = 13; // Hack.
		return Rect(xw, yw + _textHeight, clientSize.width - xw * 2, clientSize.height - yw - _textHeight - yw);
	}
	
	
	///
	override @property Size defaultSize() const // getter
	{
		return Size(200, 100);
	}
	
	
	version(DFL_NO_DRAG_DROP) {} else
	{
		///
		override @property void allowDrop(bool dyes) // setter
		{
			//if(dyes)
			//	throw new DflException("Cannot drop on a group box");
			assert(!dyes, "Cannot drop on a group box");
		}
		
		alias allowDrop = Control.allowDrop; // Overload.
	}
	
	
	///
	protected override void onFontChanged(EventArgs ea)
	{
		_dispChanged();
		
		super.onFontChanged(ea);
	}
	
	
	///
	protected override void onHandleCreated(EventArgs ea)
	{
		super.onHandleCreated(ea);
		
		_dispChanged();
	}
	
	
	///
	protected override void createParams(ref CreateParams cp)
	{
		super.createParams(cp);
		
		cp.className = BUTTON_CLASSNAME;
	}
	
	
	///
	protected override void wndProc(ref Message msg)
	{
		switch (msg.msg)
		{
			case WM_NCHITTEST:
				Control._defWndProc(msg);
				break;
			
			default:
				super.wndProc(msg);
		}
	}
	
	
	///
	protected override void onPaintBackground(PaintEventArgs ea)
	{
		Control.onPaintBackground(ea);
	}
	
	
	///
	protected override void prevWndProc(ref Message msg)
	{
		msg.result = dfl.internal.utf.callWindowProc(buttonPrevWndProc, msg.hWnd, msg.msg, msg.wParam, msg.lParam);
	}
	
	
private:
	
	enum int DEFAULT_TEXT_HEIGHT_INIT = -1; /// 
	static int _defaultTextHeight = DEFAULT_TEXT_HEIGHT_INIT; /// 
	int _textHeight = -1; /// 
	
	
	///
	void _recalcTextHeight(Font f)
	{
		HDC hdc = GetDC(_hwnd);
		scope(exit) ReleaseDC(_hwnd, hdc);
		_textHeight = cast(int)f.getSize(hdc, GraphicsUnit.PIXEL);
	}
	
	
	///
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

