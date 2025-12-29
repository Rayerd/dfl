// Written by Christopher E. Miller
// See the included license.txt for copyright and license details.


///
module dfl.splitter;

import dfl.base;
import dfl.control;
import dfl.drawing;
import dfl.event;

import dfl.internal.dpiaware;

import core.sys.windows.windef;
import core.sys.windows.wingdi;
import core.sys.windows.winuser;


///
class SplitterEventArgs: EventArgs
{
	///
	this(int x, int y, int splitX, int splitY)
	{
		_x = x;
		_y = y;
		_splitX = splitX;
		_splitY = splitY;
	}
	
	
	///
	final @property int x() const // getter
	{
		return _x;
	}
	
	
	///
	final @property int y() const // getter
	{
		return _y;
	}
	
	
	///
	final @property void splitX(int val) // setter
	{
		_splitX = val;
	}
	
	/// ditto
	final @property int splitX() const // getter
	{
		return _splitX;
	}
	
	
	///
	final @property void splitY(int val) // setter
	{
		_splitY = val;
	}
	
	/// ditto
	final @property int splitY() const // getter
	{
		return _splitY;
	}
	
	
private:
	int _x;
	int _y;
	int _splitX;
	int _splitY;
}


///
class Splitter: Control // docmain
{
	this()
	{
		dock = DockStyle.LEFT;
		
		if (HBRUSH.init == _hbrxor)
			_inithbrxor();
	}
	
	
	/+
	override @property void anchor(AnchorStyles a) // setter
	{
		throw new DflException("Splitter cannot be anchored");
	}
	
	alias Control.anchor anchor; // Overload.
	+/
	
	
	override @property void dock(DockStyle ds) // setter
	{
		switch (ds)
		{
			case DockStyle.LEFT:
			case DockStyle.RIGHT:
				cursor = Cursors.vSplit;
				break;
			
			case DockStyle.TOP:
			case DockStyle.BOTTOM:
				cursor = Cursors.hSplit;
				break;
			
			default:
				throw new DflException("Invalid splitter dock");
		}
		
		super.dock(ds);
	}
	
	alias dock = Control.dock; // Overload.
	
	
	package void initSplit(int sx, int sy)
	{
		capture = true;
		_downing = true;
		
		switch (dock)
		{
			case DockStyle.TOP:
			case DockStyle.BOTTOM:
				_downPos = sy * dpi / USER_DEFAULT_SCREEN_DPI;
				_lastPos = 0;
				_drawxorClient(0, _lastPos);
				break;
			
			default: // LEFT / RIGHT.
				_downPos = sx * dpi / USER_DEFAULT_SCREEN_DPI;
				_lastPos = 0;
				_drawxorClient(_lastPos, 0);
		}
	}
	
	
	final void resumeSplit(int sx, int sy) // package
	{
		if (Control.mouseButtons & MouseButtons.LEFT)
		{
			initSplit(sx, sy); // Convert to dpi-scaled point in initSplit().
			
			if (cursor)
				Cursor.current = cursor;
		}
	}
	
	// /// ditto
	final void resumeSplit() // package
	{
		Point pt = pointToClient(Cursor.position);
		return resumeSplit(pt.x, pt.y); // Convert to dpi-scaled point in resumeSplit().
	}
	
	
	///
	@property void movingGrip(bool byes) // setter
	{
		if (_mgrip == byes)
			return;
		
		this._mgrip = byes;
		
		if (created)
		{
			invalidate();
		}
	}
	
	/// ditto
	@property bool movingGrip() const // getter
	{
		return _mgrip;
	}
	
	
	protected override void onPaint(PaintEventArgs ea)
	{
		super.onPaint(ea);
		
		if (_mgrip)
		{
			ea.graphics.drawMoveGrip(
				displayRectangle * dpi / USER_DEFAULT_SCREEN_DPI,
				DockStyle.LEFT == dock || DockStyle.RIGHT == dock);
		}
	}
	
	
	protected override void onResize(EventArgs ea)
	{
		if (_mgrip)
		{
			invalidate();
		}
		
		resize(this, ea);
	}
	
	
	protected override void onMouseDown(MouseEventArgs mea)
	{
		super.onMouseDown(mea);
		
		if (mea.button == MouseButtons.LEFT && 1 == mea.clicks)
		{
			initSplit(mea.x, mea.y); // Convert to dpi-scaled point in initSplit().
		}
	}
	
	
	protected override void onMouseMove(MouseEventArgs mea)
	{
		super.onMouseMove(mea);
		
		if (_downing)
		{
			// mea.x is dpi-scaled.
			// mea.y is dpi-scaled.
			// _downPos is dpi-scaled.
			// _lastPos is dpi-scaled.
			switch (dock)
			{
				case DockStyle.TOP:
				case DockStyle.BOTTOM:
					_drawxorClient(0, mea.y - _downPos, 0, _lastPos);
					_lastPos = mea.y - _downPos;
					break;
				
				default: // LEFT / RIGHT.
					_drawxorClient(mea.x - _downPos, 0, _lastPos, 0);
					_lastPos = mea.x - _downPos;
			}
			
			scope sea = new SplitterEventArgs(
				mea.x * USER_DEFAULT_SCREEN_DPI / dpi,
				mea.y * USER_DEFAULT_SCREEN_DPI / dpi,
				left,
				top);
			onSplitterMoving(sea);
		}
	}
	
	
	protected override void onMove(EventArgs ea)
	{
		super.onMove(ea);
		
		if (_downing)
		{
			// curPos is dpi-scaled.
			Point curPos = pointToClient(Cursor.position);
			scope sea = new SplitterEventArgs(
				curPos.x * USER_DEFAULT_SCREEN_DPI / dpi,
				curPos.y * USER_DEFAULT_SCREEN_DPI / dpi,
				left,
				top);
			onSplitterMoved(sea);
		}
	}
	
	
	final Control getSplitControl() // package
	{
		Control splat; // Splitted.
		final switch (dock)
		{
			case DockStyle.LEFT:
				foreach (Control ctrl; parent.controls())
				{
					if (DockStyle.LEFT != ctrl.dock)
						continue;
					if (ctrl == cast(Control)this)
						return splat;
					splat = ctrl;
				}
				break;
			
			case DockStyle.RIGHT:
				foreach (Control ctrl; parent.controls())
				{
					if (DockStyle.RIGHT != ctrl.dock)
						continue;
					if (ctrl == cast(Control)this)
						return splat;
					splat = ctrl;
				}
				break;
			
			case DockStyle.TOP:
				foreach (Control ctrl; parent.controls())
				{
					if (DockStyle.TOP != ctrl.dock)
						continue;
					if (ctrl == cast(Control)this)
						return splat;
					splat = ctrl;
				}
				break;
			
			case DockStyle.BOTTOM:
				foreach (Control ctrl; parent.controls())
				{
					if (DockStyle.BOTTOM != ctrl.dock)
						continue;
					if (ctrl == cast(Control)this)
						return splat;
					splat = ctrl;
				}
				break;
			
			case DockStyle.FILL:
				assert(0, "DockStyle.FILL is not allowed in Splitter");
				break;
			
			case DockStyle.NONE:
				assert(0, "DockStyle.NONE is not allowed in Splitter");
				break;
		}
		return null;
	}
	
	
	protected override void onMouseUp(MouseEventArgs mea)
	{
		if (_downing)
		{
			capture = false;
			_downing = false;
			
			if (mea.button != MouseButtons.LEFT)
			{
				// _lastPos is dpi-scaled.

				// Abort.
				switch (dock)
				{
					case DockStyle.TOP:
					case DockStyle.BOTTOM:
						_drawxorClient(0, _lastPos);
						break;
					
					default: // LEFT / RIGHT.
						_drawxorClient(_lastPos, 0);
				}
				super.onMouseUp(mea);
				return;
			}
			
			int adj, val, vx;
			auto splat = getSplitControl(); // Splitted.
			if (splat)
			{
				switch (dock)
				{
					case DockStyle.LEFT:
						// _lastPos is dpi-scaled.
						// left and splat.left is NOT dpi-scaled.
						// mea.x is dpi-scaled.
						// _downPos is dpi-scaled.
						// val is dpi-scaled.
						// _minSize is NOT dpi-scaled.
						// splat.width is NOT dpi-scaled.
						_drawxorClient(_lastPos, 0);
						val = (left - splat.left) * dpi / USER_DEFAULT_SCREEN_DPI + mea.x - _downPos;
						if (val < _minSize * dpi / USER_DEFAULT_SCREEN_DPI)
							val = _minSize * dpi / USER_DEFAULT_SCREEN_DPI;
						splat.width = val * USER_DEFAULT_SCREEN_DPI / dpi;
						break;
					
					case DockStyle.RIGHT:
						// _lastPos is dpi-scaled.
						// right and splat.left is NOT dpi-scaled.
						// mea.x is dpi-scaled.
						// _downPos is dpi-scaled.
						// val is dpi-scaled.
						// vx is dpi-scaled.
						// _minSize is NOT dpi-scaled.
						// splat.width is NOT dpi-scaled.
						_drawxorClient(_lastPos, 0);
						adj = (right - splat.left) * dpi / USER_DEFAULT_SCREEN_DPI + mea.x - _downPos;
						val = splat.width * dpi / USER_DEFAULT_SCREEN_DPI - adj;
						vx = splat.left * dpi / USER_DEFAULT_SCREEN_DPI + adj;
						if (val < _minSize * dpi / USER_DEFAULT_SCREEN_DPI)
						{
							vx -= _minSize * dpi / USER_DEFAULT_SCREEN_DPI - val;
							val = _minSize * dpi / USER_DEFAULT_SCREEN_DPI;
						}
						splat.bounds = Rect(
							vx * USER_DEFAULT_SCREEN_DPI / dpi,
							splat.top,
							val * USER_DEFAULT_SCREEN_DPI / dpi,
							splat.height);
						break;
					
					case DockStyle.TOP:
						// _lastPos is dpi-scaled.
						// top and splat.top is NOT dpi-scaled.
						// mea.y is dpi-scaled.
						// _downPos is dpi-scaled.
						// val is dpi-scaled.
						// _minSize is NOT dpi-scaled.
						// splat.height is NOT dpi-scaled.
						_drawxorClient(0, _lastPos);
						val = (top - splat.top) * dpi / USER_DEFAULT_SCREEN_DPI + mea.y - _downPos;
						if (val < _minSize * dpi / USER_DEFAULT_SCREEN_DPI)
							val = _minSize * dpi / USER_DEFAULT_SCREEN_DPI;
						splat.height = val * USER_DEFAULT_SCREEN_DPI / dpi;
						break;
					
					case DockStyle.BOTTOM:
						// _lastPos is dpi-scaled.
						// bottom and splat.bottom is NOT dpi-scaled.
						// mea.y is dpi-scaled.
						// _downPos is dpi-scaled.
						// val is dpi-scaled.
						// _minSize is NOT dpi-scaled.
						// splat.bounds is NOT dpi-scaled.
						// vx is dpi-scaled.
						_drawxorClient(0, _lastPos);
						adj = (bottom - splat.top) * dpi / USER_DEFAULT_SCREEN_DPI + mea.y - _downPos;
						val = splat.height * dpi / USER_DEFAULT_SCREEN_DPI - adj;
						vx = splat.top * dpi / USER_DEFAULT_SCREEN_DPI + adj;
						if (val < _minSize * dpi / USER_DEFAULT_SCREEN_DPI)
						{
							vx -= _minSize * dpi / USER_DEFAULT_SCREEN_DPI - val;
							val = _minSize * dpi / USER_DEFAULT_SCREEN_DPI;
						}
						splat.bounds = Rect(
							splat.left,
							vx * USER_DEFAULT_SCREEN_DPI / dpi,
							splat.width,
							val * USER_DEFAULT_SCREEN_DPI / dpi);
						break;
					
					default:
				}
			}
			
			// This is needed when the moved control first overlaps the splitter and the splitter
			// gets bumped over, causing a little area to not be updated correctly.
			// I'll fix it someday.
			parent.invalidate(true);
			
			// Event..
		}
		
		super.onMouseUp(mea);
	}
	
	
	/+
	// NOTE: Not quite sure how to implement this yet.
	// Might need to scan all controls until one of:
	//    Control with opposite dock (right if left dock): stay -_mextra- away from it,
	//    Control with fill dock: that control can't have less than -mextra- width,
	//    Reached end of child controls: stay -_mextra- away from the edge.
	
	///
	final @property void minExtra(int min) // setter
	{
		_mextra = min;
	}
	
	/// ditto
	final @property int minExtra() // getter
	{
		return _mextra;
	}
	+/
	
	
	///
	final @property void minSize(int min) // setter
	{
		// _minSize and min are NOT dpi-scaled.
		_minSize = min;
	}
	
	/// ditto
	final @property int minSize() const // getter
	{
		// _minSize is NOT dpi-scaled.
		return _minSize;
	}
	
	
	///
	final @property void splitPosition(int pos) // setter
	{
		// pos is NOT dpi-scaled.
		// splat.width is NOT dpi-scaled.
		// splat.height is NOT dpi-scaled.

		auto splat = getSplitControl(); // Splitted.
		if (splat)
		{
			switch (dock)
			{
				case DockStyle.LEFT:
				case DockStyle.RIGHT:
					splat.width = pos;
					break;
				
				case DockStyle.TOP:
				case DockStyle.BOTTOM:
					splat.height = pos;
					break;
				
				default:
			}
		}
	}
	
	/// ditto
	// -1 if not docked to a control.
	final @property int splitPosition() // getter
	{
		// splat.width is NOT dpi-scaled.
		// splat.height is NOT dpi-scaled.

		auto splat = getSplitControl(); // Splitted.
		if (splat)
		{
			switch (dock)
			{
				case DockStyle.LEFT:
				case DockStyle.RIGHT:
					return splat.width;
				
				case DockStyle.TOP:
				case DockStyle.BOTTOM:
					return splat.height;
				
				default:
			}
		}
		return -1;
	}
	
	
	Event!(Splitter, SplitterEventArgs) splitterMoved; ///
	Event!(Splitter, SplitterEventArgs) splitterMoving; ///
	
	
protected:
	
	override @property Size defaultSize() const // getter
	{
		// sx and sy are dpi-scaled.
		int sx = GetSystemMetricsForDpi(SM_CXSIZEFRAME, dpi);
		int sy = GetSystemMetricsForDpi(SM_CYSIZEFRAME, dpi);
		
		// Need a bit extra room for the move-grips.
		int bit = 5 * dpi / USER_DEFAULT_SCREEN_DPI;
		if (sx < bit)
			sx = bit;
		if (sy < bit)
			sy = bit;
		return Size(sx, sy) * USER_DEFAULT_SCREEN_DPI / dpi;
	}
	
	
	///
	void onSplitterMoving(SplitterEventArgs sea)
	{
		splitterMoving(this, sea);
	}
	
	
	///
	void onSplitterMoved(SplitterEventArgs sea)
	{
		splitterMoving(this, sea);
	}
	
	
private:
	
	bool _downing = false;
	bool _mgrip = true;
	int _downPos;
	int _lastPos;
	int _minSize = 25; // Min size of control that's being sized from the splitter.
	// int _mextra = 25; // NOTE: Not implemented yet. Min size of the control on the opposite side.
	
	static HBRUSH _hbrxor;
	
	
	static void _inithbrxor()
	{
		static ubyte[] bmbits = [0xAA, 0, 0x55, 0, 0xAA, 0, 0x55, 0,
			0xAA, 0, 0x55, 0, 0xAA, 0, 0x55, 0, ];
		
		HBITMAP hbm = CreateBitmap(8, 8, 1, 1, bmbits.ptr);
		_hbrxor = CreatePatternBrush(hbm);
		DeleteObject(hbm);
	}
	
	
	static void _drawxor(HDC hdc, Rect r)
	{
		SetBrushOrgEx(hdc, r.x, r.y, null);
		HGDIOBJ hbrold = SelectObject(hdc, _hbrxor);
		PatBlt(hdc, r.x, r.y, r.width, r.height, PATINVERT);
		SelectObject(hdc, hbrold);
	}
	
	
	void _drawxorClient(HDC hdc, int x, int y)
	{
		POINT pt = POINT(x, y);
		MapWindowPoints(handle, parent.handle, &pt, 1);

		uint dpi = GetDpiForWindow(WindowFromDC(hdc));
		int w = width * dpi / USER_DEFAULT_SCREEN_DPI;
		int h = height * dpi / USER_DEFAULT_SCREEN_DPI;

		_drawxor(hdc, Rect(pt.x, pt.y, w, h));
	}
	
	
	void _drawxorClient(int x, int y, int xold = int.min, int yold = int.min)
	{
		HDC hdc = GetDCEx(parent.handle, null, DCX_CACHE);
		
		if (xold != int.min)
			_drawxorClient(hdc, xold, yold);
		
		_drawxorClient(hdc, x, y);
		
		ReleaseDC(null, hdc);
	}
}
