// Written by Christopher E. Miller
// See the included license.txt for copyright and license details.


///
module dfl.statusbar;


import dfl.application;
import dfl.base;
import dfl.collections;
import dfl.control;
import dfl.event;

import dfl.internal.dlib;
import dfl.internal.dpiaware;
import dfl.internal.utf;

import core.sys.windows.windows;
import core.sys.windows.commctrl;


private extern(Windows) void _initStatusbar();


/+
enum StatusBarPanelAutoSize: ubyte
{
	NONE,
	CONTENTS,
	SPRING,
}
+/


///
enum StatusBarPanelBorderStyle: ubyte
{
	NONE, ///
	SUNKEN, /// ditto
	RAISED /// ditto
}


///
class StatusBarPanel: DObject
{
	///
	this(Dstring text)
	{
		this._txt = text;
	}
	
	/// ditto
	this(Dstring text, int width)
	{
		this._txt = text;
		this._width = width;
	}
	
	/// ditto
	this()
	{
	}
	
	
	///
	override Dstring toString() const
	{
		return _txt;
	}
	
	
	///
	override Dequ opEquals(Object o) const
	{
		return _txt == getObjectString(o); // TODO: ?
	}
	
	/// ditto
	Dequ opEquals(StatusBarPanel pnl) const
	{
		return _txt == pnl._txt;
	}
	
	/// ditto
	Dequ opEquals(Dstring val) const
	{
		return _txt == val;
	}
	
	
	///
	override int opCmp(Object o) const
	{
		return stringICmp(_txt, getObjectString(o)); // TODO: ?
	}
	
	/// ditto
	int opCmp(StatusBarPanel pnl) const
	{
		return stringICmp(_txt, pnl._txt);
	}
	
	/// ditto
	int opCmp(Dstring val) const
	{
		return stringICmp(_txt, val);
	}


	///
	override size_t toHash() const nothrow @safe
	{
		return hashOf(_txt);
	}
	
	
	/+
	///
	final @property void alignment(HorizontalAlignment ha) // setter
	{
		
	}
	
	/// ditto
	final @property HorizontalAlignment alignment() // getter
	{
		//LEFT
	}
	+/
	
	
	/+
	///
	final @property void autoSize(StatusBarPanelAutoSize asize) // setter
	{
		
	}
	
	/// ditto
	final @property StatusBarPanelAutoSize autoSize() // getter
	{
		//NONE
	}
	+/
	
	
	///
	final @property void borderStyle(StatusBarPanelBorderStyle bs) // setter
	{
		switch(bs)
		{
			case StatusBarPanelBorderStyle.NONE:
				_utype = (_utype & ~SBT_POPOUT) | SBT_NOBORDERS;
				break;
			
			case StatusBarPanelBorderStyle.RAISED:
				_utype = (_utype & ~SBT_NOBORDERS) | SBT_POPOUT;
				break;
			
			case StatusBarPanelBorderStyle.SUNKEN:
				_utype &= ~(SBT_NOBORDERS | SBT_POPOUT);
				break;
			
			default:
				assert(0);
		}
		
		if(_parent && _parent.isHandleCreated)
		{
			_parent.panels._fixTexts(); // Also fixes styles.
		}
	}
	
	/// ditto
	final @property StatusBarPanelBorderStyle borderStyle() const // getter
	{
		if(_utype & SBT_POPOUT)
			return StatusBarPanelBorderStyle.RAISED;
		if(_utype & SBT_NOBORDERS)
			return StatusBarPanelBorderStyle.NONE;
		return StatusBarPanelBorderStyle.RAISED;
	}
	
	
	// icon
	
	
	/+
	///
	final @property void minWidth(int mw) // setter
	in
	{
		assert(mw >= 0);
	}
	do
	{
		
	}
	
	/// ditto
	final @property int minWidth() // getter
	{
		//10
	}
	+/
	
	
	///
	final @property inout(StatusBar) parent() inout // getter
	{
		return _parent;
	}
	
	
	// style
	
	
	///
	final @property void text(Dstring txt) // setter
	{
		if(_parent && _parent.isHandleCreated)
		{
			int idx = _parent.panels.indexOf(this);
			assert(-1 != idx);
			_parent._sendidxtext(idx, _utype, txt);
		}
		
		this._txt = txt;
	}
	
	/// ditto
	final @property Dstring text() const // getter
	{
		return _txt;
	}
	
	
	/+
	///
	final @property void toolTipText(Dstring txt) // setter
	{
		
	}
	
	/// ditto
	final @property Dstring toolTipText() // getter
	{
		//null
	}
	+/
	
	
	///
	final @property void width(int w) // setter
	{
		_width = w;
		
		if(_parent && _parent.isHandleCreated)
		{
			_parent.panels._fixWidths();
		}
	}
	
	/// ditto
	final @property int width() const // getter
	{
		return _width;
	}
	
	
private:
	
	Dstring _txt = null;
	int _width = 100;
	StatusBar _parent = null;
	WPARAM _utype = 0; // StatusBarPanelBorderStyle.SUNKEN.
}


/+
///
class StatusBarPanelClickEventArgs: MouseEventArgs
{
	///
	this(StatusBarPanel sbpanel, MouseButtons btn, int clicks, int x, int y)
	{
		this._sbpanel = sbpanel;
		super(btn, clicks, x, y, 0);
	}
	
	
	private:
	StatusBarPanel _sbpanel;
}
+/


///
class StatusBar: ControlSuperClass // docmain
{
	///
	class StatusBarPanelCollection
	{
		protected this(StatusBar sb)
		in
		{
			assert(sb._lpanels is null);
		}
		do
		{
			this._statusBar = sb;
		}
		
		
	private:
		
		StatusBar _statusBar;
		package StatusBarPanel[] _panels;
		
		
		///
		void _fixWidthsCore(uint newDpi)
		{
			assert(isHandleCreated);
			
			UINT[20] panelWidthsStatic = void;
			UINT[] panelWidths = panelWidthsStatic;
			if(_panels.length > panelWidthsStatic.length)
				panelWidths = new UINT[_panels.length];
			UINT rightEdge = 0;
			foreach(index, panel; _panels)
			{
				if(-1 == panel.width)
				{
					panelWidths[index] = -1;
				}
				else
				{
					rightEdge += MulDiv(panel.width, newDpi, USER_DEFAULT_SCREEN_DPI);
					panelWidths[index] = rightEdge;
				}
			}
			sendMessage(_hwnd, SB_SETPARTS, cast(WPARAM)_panels.length, cast(LPARAM)panelWidths.ptr);
		}

		/// ditto
		void _fixWidths()
		{
			_fixWidthsCore(dpi);
		}

		/// ditto
		void _fixWidthsWithDpi(uint newDpi)
		{
			_fixWidthsCore(newDpi);
		}
		
		
		void _fixTexts()
		{
			assert(isHandleCreated);
			
			if(dfl.internal.utf.useUnicode)
			{
				foreach(idx, pnl; _panels)
				{
					_statusBar.prevwproc(SB_SETTEXTW, cast(WPARAM)idx | pnl._utype, cast(LPARAM)dfl.internal.utf.toUnicodez(pnl._txt));
				}
			}
			else
			{
				foreach(idx, pnl; _panels)
				{
					_statusBar.prevwproc(SB_SETTEXTA, cast(WPARAM)idx | pnl._utype, cast(LPARAM)dfl.internal.utf.toAnsiz(pnl._txt));
				}
			}
		}
		
		
		void _setCurrentParts()
		{
			assert(isHandleCreated);
			
			_fixWidths();
			
			_fixTexts();
		}
		
		
		void _removed(size_t idx, Object val)
		{
			if(size_t.max == idx) // Clear all.
			{
				if(_statusBar.isHandleCreated)
				{
					_statusBar.prevwproc(SB_SETPARTS, 0, 0); // 0 parts.
				}
			}
			else
			{
				if(_statusBar.isHandleCreated)
				{
					_setCurrentParts();
				}
			}
		}
		
		
		void _added(size_t idx, StatusBarPanel val)
		{
			if(val._parent)
				throw new DflException("StatusBarPanel already belongs to a StatusBar");
			
			val._parent = _statusBar;
			
			if(_statusBar.isHandleCreated)
			{
				_setCurrentParts();
			}
		}
		
		
		void _adding(size_t idx, StatusBarPanel val)
		{
			if(_panels.length >= 254) // Since SB_SETTEXT with 255 has special meaning.
				throw new DflException("Too many status bar panels");
		}
		
		
	public:
		
		mixin ListWrapArray!(StatusBarPanel, _panels,
			_adding, _added,
			_blankListCallback!(StatusBarPanel), _removed,
			true, /+true+/ false, false) _wraparray;
	}
	
	
	///
	this()
	{
		_initStatusbar();
		
		_issimple = true;
		_windowStyle |= SBARS_SIZEGRIP;
		_windowClassStyle = statusbarClassStyle;
		//height = ?;
		dock = DockStyle.BOTTOM;
		
		_lpanels = new StatusBarPanelCollection(this);
	}
	
	
	// backColor / font / foreColor ...
	
	
	///
	override @property void dock(DockStyle ds) // setter
	{
		switch(ds)
		{
			case DockStyle.BOTTOM:
			case DockStyle.TOP:
				super.dock = ds;
				break;
			
			default:
				throw new DflException("Invalid status bar dock");
		}
	}
	
	alias dock = Control.dock; // Overload.
	
	
	///
	final @property inout(StatusBarPanelCollection) panels() inout // getter
	{
		return _lpanels;
	}
	
	
	///
	final @property void showPanels(bool byes) // setter
	{
		if(!byes == _issimple)
			return;
		
		if(isHandleCreated)
		{
			prevwproc(SB_SIMPLE, cast(WPARAM)!byes, 0);
			
			/+ // It's kept in sync even if simple.
			if(byes)
			{
				panels._setcurparts();
			}
			+/
			
			if(!byes)
			{
				_sendidxtext(255, 0, _simpletext);
			}
		}
		
		_issimple = !byes;
	}
	
	/// ditto
	final @property bool showPanels() const // getter
	{
		return !_issimple;
	}
	
	
	///
	final @property void sizingGrip(bool byes) // setter
	{
		if(byes == sizingGrip)
			return;
		
		if(byes)
			_style(_style() | SBARS_SIZEGRIP);
		else
			_style(_style() & ~SBARS_SIZEGRIP);
	}
	
	/// ditto
	final @property bool sizingGrip() const // getter
	{
		if(_windowStyle & SBARS_SIZEGRIP)
			return true;
		return false;
	}
	
	
	///
	override @property void text(Dstring txt) // setter
	{
		if(isHandleCreated && !showPanels)
		{
			_sendidxtext(255, 0, txt);
		}
		
		this._simpletext = txt;
		
		onTextChanged(EventArgs.empty);
	}
	
	/// ditto
	override @property Dstring text() const // getter
	{
		return this._simpletext;
	}
	
	
	protected override void onHandleCreated(EventArgs ea)
	{
		super.onHandleCreated(ea);
		
		if(_issimple)
		{
			prevwproc(SB_SIMPLE, cast(WPARAM)true, 0);
			panels._setCurrentParts();
			if(_simpletext.length)
				_sendidxtext(255, 0, _simpletext);
		}
		else
		{
			panels._setCurrentParts();
			prevwproc(SB_SIMPLE, cast(WPARAM)false, 0);
		}
	}
	
	
	protected override void createParams(ref CreateParams cp)
	{
		super.createParams(cp);
		
		cp.className = STATUSBAR_CLASSNAME;
	}
	
	
	protected override void prevWndProc(ref Message msg)
	{
		//msg.result = CallWindowProcA(statusbarPrevWndProc, msg.hWnd, msg.msg, msg.wParam, msg.lParam);
		msg.result = dfl.internal.utf.callWindowProc(statusbarPrevWndProc, msg.hWnd, msg.msg, msg.wParam, msg.lParam);
	}


	protected override void onDpiChanged(uint newDpi)
	{
		_lpanels._fixWidthsWithDpi(newDpi);
	}
	

	/+
	protected override void createHandle()
	{
		//CreateStatusWindow
	}
	+/
	
	
	//Event!(StatusBar, StatusBarPanelClickEventArgs) panelClick; ///
	
	
protected:
	
	// onDrawItem ...
	
	
	/+
	///
	void onPanelClick(StatusBarPanelClickEventArgs ea)
	{
		panelClick(this, ea);
	}
	+/
	
	
private:
	
	StatusBarPanelCollection _lpanels;
	Dstring _simpletext = null;
	bool _issimple = true;
	
	
package:
final:
	
	LRESULT prevwproc(UINT msg, WPARAM wparam, LPARAM lparam)
	{
		//return CallWindowProcA(statusbarPrevWndProc, hwnd, msg, wparam, lparam);
		return dfl.internal.utf.callWindowProc(statusbarPrevWndProc, _hwnd, msg, wparam, lparam);
	}
	
	
	void _sendidxtext(int idx, WPARAM utype, Dstring txt)
	{
		assert(isHandleCreated);
		
		if(dfl.internal.utf.useUnicode)
			prevwproc(SB_SETTEXTW, cast(WPARAM)idx | utype, cast(LPARAM)dfl.internal.utf.toUnicodez(txt));
		else
			prevwproc(SB_SETTEXTA, cast(WPARAM)idx | utype, cast(LPARAM)dfl.internal.utf.toAnsiz(txt));
	}
}
