// trackbar.d
//
// The original is TrackBar.cs in Windows Forms Liblary.
// Licensed to the .NET Foundation under one or more agreements.
// The .NET Foundation licenses this file to you under the MIT license.
// See https://opensource.org/licenses/MIT
//
// Translations and modifications by haru-s/Rayerd in 2022.

///
module dfl.trackbar;

import dfl.application;
import dfl.base;
import dfl.control;
import dfl.drawing;
import dfl.event;
static import dfl.internal.utf;

import core.sys.windows.commctrl;
import core.sys.windows.windef;
import core.sys.windows.winuser;

static import std.algorithm.comparison;


extern(Windows) void _initTrackbar();


///
enum TickStyle : ubyte
{
	NONE         = 0, ///
	TOP_LEFT     = 1, /// ditto
	BOTTOM_RIGHT = 2, /// ditto
	BOTH         = 3, /// ditto
}


///
class TrackBar : ControlSuperClass
{
	///
	Event!(TrackBar, EventArgs) scroll;
	///
	Event!(TrackBar, EventArgs) valueChanged;
	
	private bool _autoSize = true; /// AutoSize flag
	private int _largeChange = 5; /// large change step
	private int _maximum = 10; /// max range
	private int _minimum; /// min range
	private Orientation _orientation = Orientation.HORIZONTAL; /// slider orientation
	private int _value; /// thumb position
	private int _smallChange = 1; /// small change step
	private int _tickFrequency = 1; /// tick frequency
	private TickStyle _tickStyle = TickStyle.BOTTOM_RIGHT; /// tick style

	private int _requestedDim;

	// Mouse wheel movement
	private int _cumulativeWheelData;

	// TODO: Implement
	// Disable value range checking while initializing the control
	// private bool _initializing;

	private bool _rightToLeftLayout;


	///
	this()
	{
		_initTrackbar();
		
		setStyle(ControlStyles.USER_PAINT, false);
		setStyle(ControlStyles.USE_TEXT_FOR_ACCESSIBILITY, false);
		_requestedDim = _preferredDimension;

		_windowStyle |= WS_CHILD | WS_VISIBLE | WS_TABSTOP | TBS_AUTOTICKS;
		_controlStyle |= ControlStyles.SELECTABLE;
		_windowClassStyle = trackbarClassStyle;

		super(); // call for defaultSize()
	}


	///
	@property bool autoSize() const // getter
	{
		return _autoSize;
	}

	/// ditto
	@property void autoSize(bool v) // setter
	{
		// Intentionally do not call super.autoSize.
		if (_autoSize != v)
		{
			_autoSize = v;
			if (_orientation == Orientation.HORIZONTAL)
			{
				setStyle(ControlStyles.FIXED_HEIGHT, _autoSize);
				setStyle(ControlStyles.FIXED_WIDTH, false);
			}
			else
			{
				setStyle(ControlStyles.FIXED_WIDTH, _autoSize);
				setStyle(ControlStyles.FIXED_HEIGHT, false);
			}

			_adjustSize();
			// TODO: Implement
			//onAutoSizeChanged(EventArgs.EMPTY);
		}
	}
	

	///
	protected void onScroll(EventArgs ea)
	{
		scroll(this, ea);
	}


	///
	protected override void onMouseWheel(MouseEventArgs e)
	{
		super.onMouseWheel(e);

		if (is(e == HandledMouseEventArgs))
		{
			HandledMouseEventArgs hme = cast(HandledMouseEventArgs)e;
			if (hme.handled)
			{
				return;
			}

			hme.handled = true;
		}

		if ((modifierKeys & (Keys.SHIFT | Keys.ALT)) != 0 || mouseButtons != MouseButtons.NONE)
		{
			// Do not scroll when Shift or Alt key is down, or when a mouse button is down.
			return;
		}

		// PInvoke.SystemParametersInfoInt(SPI_GETWHEELSCROLLLINES);
		int wheelScrollLines = SystemInformation.mouseWheelScrollLines();
		if (wheelScrollLines == 0)
		{
			// Do not scroll when the user system setting is 0 lines per notch
			return;
		}

		assert(_cumulativeWheelData > -WHEEL_DELTA, "cumulativeWheelData is too small");
		assert(_cumulativeWheelData < WHEEL_DELTA, "cumulativeWheelData is too big");
		_cumulativeWheelData += e.delta;

		float partialNotches;
		partialNotches = cast(float)_cumulativeWheelData / cast(float)WHEEL_DELTA;

		if (wheelScrollLines == -1)
		{
			wheelScrollLines = tickFrequency;
		}

		// Evaluate number of bands to scroll
		int scrollBands = cast(int)(cast(float)wheelScrollLines * partialNotches);

		if (scrollBands != 0)
		{
			int absScrollBands;
			if (scrollBands > 0)
			{
				absScrollBands = scrollBands;
				value = std.algorithm.comparison.min(absScrollBands + value, maximum);
				_cumulativeWheelData
					-= cast(int)(cast(float)scrollBands * (cast(float)WHEEL_DELTA / cast(float)wheelScrollLines));
			}
			else
			{
				absScrollBands = -scrollBands;
				value = std.algorithm.comparison.max(value - absScrollBands, minimum);
				_cumulativeWheelData
					-= cast(int)(cast(float)scrollBands * (cast(float)WHEEL_DELTA / cast(float)wheelScrollLines));
			}
		}

		if (e.delta != value)
		{
			onScroll(EventArgs.empty);
			onValueChanged(EventArgs.empty);
		}
	}
	

	///
	protected void onValueChanged(EventArgs ea)
	{
		valueChanged(this, ea);
	}


	///
	@property TickStyle tickStyle() const // getter
	{
		return _tickStyle;
	}
	
	/// ditto
	@property void tickStyle(TickStyle v) // setter
	{
		if (v < TickStyle.NONE || v > TickStyle.BOTH)
		{
			// throw new InvalidEnumArgumentException(nameof(value), (int)value, typeof(TickStyle));
			throw new DflException("TrackBar TickStyle Failure");
		}

		if (_tickStyle == v)
		{
			return;
		}

		_tickStyle = v;
		recreateHandle();
	}


	///
	@property int tickFrequency() const // getter
	{
		return _tickFrequency;
	}
	
	/// ditto
	@property void tickFrequency(int v) // setter
	{
		if (_tickFrequency == v)
		{
			return;
		}

		_tickFrequency = v;
		if (isHandleCreated)
		{
			// PInvoke.SendMessage(this, (User32.WM)PInvoke.TBM_SETTICFREQ, (WPARAM)value);
			prevwproc(TBM_SETTICFREQ, v, 0);
			invalidate();
		}
	}
	

	///
	@property int value() // getter
	{
		_getTrackBarValue();
		return _value;
	}

	/// ditto
	@property void value(int v) // setter
	{
		if (v == _value)
		{
			return;
		}

		// TODO: Implement
		// 
		// if (!_initializing && ((v < _minimum) || (v > _maximum)))
		// {
		// 	throw new ArgumentOutOfRangeException(
		// 			nameof(v), v,
		// 			string.Format(
		// 				SR.InvalidBoundArgument, nameof(v), v, "min'", "max"));
		// }

		_value = v;
		_setTrackBarPosition();
		onValueChanged(EventArgs.empty);
	}


	///
	@property int largeChange() const // getter
	{
		return _largeChange;
	}

	/// ditto
	@property void largeChange(int v) // setter
	{
		if (v < 0)
		{
			// throw new ArgumentOutOfRangeException(nameof(value), value, string.Format(SR.TrackBarLargeChangeError, value));
			throw new DflException("TrackBar LargeChange Failure");
		}

		if (_largeChange == v)
		{
			return;
		}

		_largeChange = v;
		if (isHandleCreated)
		{
			// PInvoke.SendMessage(this, (User32.WM)PInvoke.TBM_SETPAGESIZE, 0, value);
			prevwproc(TBM_SETPAGESIZE, 0, v);
		}
	}
	

	///
	@property int smallChange() // setter
	{
		return _smallChange;
	}

	/// ditto
	@property void smallChange(int v) // getter
	{
		if (v < 0)
		{
			// throw new ArgumentOutOfRangeException(nameof(value), value, string.Format(SR.TrackBarSmallChangeError, value));
			throw new DflException("TrackBar SmallChange Failure");
		}

		if (_smallChange == v)
		{
			return;
		}

		_smallChange = v;
		if (isHandleCreated)
		{
			// PInvoke.SendMessage(this, (User32.WM)PInvoke.TBM_SETLINESIZE, 0, value);
			prevwproc(TBM_SETLINESIZE, 0, v);
		}
	}


	///
	@property int maximum() const // getter
	{
		return _maximum;
	}

	/// ditto
	@property void maximum(int v) // setter
	{
		if (_maximum == v)
		{
			return;
		}

		if (v < _minimum)
		{
			_minimum = v;
		}

		setRange(_minimum, v);
	}


	///
	@property int minimum() const // getter
	{
		return _minimum;
	}

	/// ditto
	@property void minimum(int v) // setter
	{
		if (_minimum == v)
		{
			return;
		}

		if (v > _maximum)
		{
			_maximum = v;
		}

		setRange(v, _maximum);
	}
	

	///
	@property Orientation orientation() const // getter
	{
		return _orientation;
	}

	/// ditto
	@property void orientation(Orientation v) // setter
	{
		if (v < Orientation.HORIZONTAL || v > Orientation.VERTICAL)
		{
			// throw new InvalidEnumArgumentException(nameof(v), (int)v, typeof(Orientation));
			throw new DflException("TrackBar Orientation Failure");
		}

		if (_orientation == v)
		{
			return;
		}

		_orientation = v;

		if (_orientation == Orientation.HORIZONTAL)
		{
			setStyle(ControlStyles.FIXED_HEIGHT, _autoSize);
			setStyle(ControlStyles.FIXED_WIDTH, false);
			width = _requestedDim;
		}
		else
		{
			setStyle(ControlStyles.FIXED_HEIGHT, false);
			setStyle(ControlStyles.FIXED_WIDTH, _autoSize);
			height = _requestedDim;
		}

		if (isHandleCreated)
		{
			Rect r = bounds;
			recreateHandle();
			setBounds(r.x, r.y, r.height, r.width, BoundsSpecified.ALL);
			_adjustSize();
		}
	}

	
	///
	void setRange(int minValue, int maxValue)
	{
		if (_minimum != minValue || _maximum != maxValue)
		{
			if (minValue > maxValue)
			{
				maxValue = minValue;
			}

			_minimum = minValue;
			_maximum = maxValue;

			if (isHandleCreated)
			{
				prevwproc(TBM_SETRANGEMIN, false, _minimum);
				prevwproc(TBM_SETRANGEMAX, true, _maximum); // WPARAM is true for repaint.
				invalidate();
			}

			// When we change the range, the comctl32 trackbar's internal position can change
			// (because of the reflection that occurs with vertical trackbars)
			// so we make sure to explicitly set the trackbar position.
			if (_value < _minimum)
			{
				_value = _minimum;
			}

			if (_value > _maximum)
			{
				_value = _maximum;
			}

			_setTrackBarPosition();
			onValueChanged(EventArgs.empty); // For call event handler when we change the range
		}
	}


	///
	protected override void setBoundsCore(int x, int y, int width, int height, BoundsSpecified specified)
	{
		_requestedDim = (_orientation == Orientation.HORIZONTAL) ? height : width;

		if (_autoSize)
		{
			if (_orientation == Orientation.HORIZONTAL)
			{
				if ((specified & BoundsSpecified.HEIGHT) != BoundsSpecified.NONE)
				{
					height = _preferredDimension;
				}
			}
			else
			{
				if ((specified & BoundsSpecified.WIDTH) != BoundsSpecified.NONE)
				{
					width = _preferredDimension;
				}
			}
		}

		super.setBoundsCore(x, y, width, height, specified);
	}
	

	///
	private static @property int _preferredDimension()
	{
		int cyhscroll = GetSystemMetrics(SM_CYHSCROLL);
		return ((cyhscroll * 8) / 3);
	}


	///
	@property bool rightToLeftLayout() const // getter
	{
		return _rightToLeftLayout;
	}

	/// ditto
	@property void rightToLeftLayout(bool v) // setter
	{
		if (v == _rightToLeftLayout)
		{
			return;
		}

		_rightToLeftLayout = v;
		// TODO: Throw exception because do not implement yet.
		{
			throw new DflException("TrackBar RightToLeftLayout Failure");
			// using (new LayoutTransaction(this, this, PropertyNames.RIGHT_TO_LEFT_LAYOUT))
			// {
			// 	onRightToLeftLayoutChanged(EventArgs.EMPTY);
			// }
		}
	}


	///
	private void _adjustSize()
	{
		if (!isHandleCreated)
		{
			return;
		}

		int saveDim = _requestedDim;
		try
		{
			if (_orientation == Orientation.HORIZONTAL)
			{
				height = _autoSize ? _preferredDimension : saveDim;
			}
			else
			{
				width = _autoSize ? _preferredDimension : saveDim;
			}
		}
		finally
		{
			_requestedDim = saveDim;
		}
	}


	///
	private void _getTrackBarValue()
	{
		if (isHandleCreated)
		{
			// _value = (int)PInvoke.SendMessage(this, User32.WM.USER);
			LRESULT pos = prevwproc(TBM_GETPOS, 0, 0);
			_value = cast(int)pos;

			// See SetTrackBarValue() for a description of why we sometimes reflect the trackbar value
			if (_orientation == Orientation.VERTICAL)
			{
				// Reflect value
				_value = minimum + maximum - _value;
			}

			// TODO: Implememt
			//
			// Reflect for a RightToLeft horizontal trackbar
			// if (_orientation == Orientation.HORIZONTAL && rightToLeft == RightToLeft.YES && !isMirrored)
			// {
			// 	_value = minimum + maximum - _value;
			// }
		}
	}


	///
	private void _setTrackBarPosition()
	{
		if (isHandleCreated)
		{
			// There are two situations where we want to reflect the track bar position:
			//
			// 1. For a vertical trackbar, it seems to make more sense for the trackbar to increase in value
			//    as the slider moves up the trackbar (this is opposite what the underlying winctl control does)
			// 2. For a RightToLeft horizontal trackbar, we want to reflect the position.
			int reflectedValue = _value;

			// 1. Reflect for a vertical trackbar
			if (_orientation == Orientation.VERTICAL)
			{
				reflectedValue = minimum + maximum - _value;
			}

			// TODO: Implememt
			//
			// 2. Reflect for a RightToLeft horizontal trackbar
			// if (_orientation == Orientation.HORIZONTAL && rightToLeft == RightToLeft.YES && !isMirrored)
			// {
			// 	reflectedValue = minimum + maximum - _value;
			// }

			// PInvoke.SendMessage(this, (User32.WM)PInvoke.TBM_SETPOS, (WPARAM)(BOOL)true, (LPARAM)reflectedValue);
			prevwproc(TBM_SETPOS, true, reflectedValue);
		}
	}
	

	/// Handling special input keys, such as PageUp, PageDown, Home, End, etc.
	protected override bool isInputKey(Keys keyData)
	{
		if ((keyData & Keys.ALT) == Keys.ALT)
		{
			return false;
		}
	
		switch (keyData & Keys.KEY_CODE)
		{
			case Keys.PAGE_UP:
			case Keys.PAGE_DOWN:
			case Keys.HOME:
			case Keys.END:
				return true;
			
			default:
		}
	
		return super.isInputKey(keyData);
	}


	///
	protected override void onHandleCreated(EventArgs ea)
	{
		super.onHandleCreated(ea);

		if (!isHandleCreated)
		{
			return;
		}

		prevwproc(TBM_SETRANGEMIN, false, _minimum);
		prevwproc(TBM_SETRANGEMAX, false, _maximum);
		prevwproc(TBM_SETTICFREQ, _tickFrequency, 0);
		prevwproc(TBM_SETPAGESIZE, 0, _largeChange);
		prevwproc(TBM_SETLINESIZE, 0, _smallChange);
		_setTrackBarPosition();
		_adjustSize();
	}
	

	///
	protected override void createParams(ref CreateParams cp)
	{
		super.createParams(cp);
		
		cp.className = TRACKBAR_CLASSNAME;

		void _clearTicksFlag(ref CreateParams c)
		{
			c.style &= ~(TBS_TOP | TBS_BOTTOM | TBS_LEFT | TBS_RIGHT | TBS_BOTH | TBS_NOTICKS);
		}
		
		final switch (_tickStyle)
		{
			case TickStyle.NONE:
				_clearTicksFlag(cp); // For recreateHandle().
				cp.style |= cast(int)TBS_NOTICKS;
				break;
			case TickStyle.TOP_LEFT:
				_clearTicksFlag(cp); // For recreateHandle().
				cp.style |= cast(int)(TBS_AUTOTICKS | TBS_TOP);
				break;
			case TickStyle.BOTTOM_RIGHT:
				_clearTicksFlag(cp); // For recreateHandle().
				cp.style |= cast(int)(TBS_AUTOTICKS | TBS_BOTTOM);
				break;
			case TickStyle.BOTH:
				_clearTicksFlag(cp); // For recreateHandle().
				cp.style |= cast(int)(TBS_AUTOTICKS | TBS_BOTH);
				break;
		}

		if (_orientation == Orientation.VERTICAL)
		{
			cp.style |= TBS_VERT;
			cp.style &= ~TBS_HORZ;
		}
		else // For recreateHandle().
		{
			cp.style |= TBS_HORZ;
			cp.style &= ~TBS_VERT;
		}

		// TODO: Implement
		// if (rightToLeft == RightToLeft.YES && rightToLeftLayout)
		// {
			// We want to turn on mirroring for Trackbar explicitly.
			// Don't need these styles when mirroring is turned on.

		 	// cp.exStyle |= cast(int)(WS_EX_LAYOUTRTL | WS_EX_NOINHERITLAYOUT);
		 	// cp.exStyle &= ~cast(int)(WS_EX_RTLREADING | WS_EX_RIGHT | WS_EX_LEFTSCROLLBAR);
		// }
	}


	///
	protected override @property Size defaultSize() const // getter
	{
		return Size(104, _preferredDimension);
	}


	protected override void onReflectedMessage(ref Message msg)
	{
		switch(msg.msg)
		{
			case WM_HSCROLL:
			case WM_VSCROLL:
				switch(LOWORD(msg.wParam))
				{
					case TB_BOTTOM:
					case TB_TOP:
					case TB_ENDTRACK:
					case TB_LINEDOWN:
					case TB_LINEUP:
					case TB_PAGEDOWN:
					case TB_PAGEUP:
					case TB_THUMBPOSITION:
					case TB_THUMBTRACK:
					{
						if (_value != value) // For messages are received twice.
						{
							onScroll(EventArgs.empty);
							onValueChanged(EventArgs.empty);
							// Should return zero, if an application processes this message.
							msg.result = 0;
						}
						return;
					}
					default:
				}
				return;

			default:
				// Call super.onReflectedMessage() in order to procces the below:
				// WM_CTLCOLORSTATIC
				// WM_CTLCOLORLISTBOX
				// WM_CTLCOLOREDIT
				// WM_CTLCOLORSCROLLBAR
				// WM_CTLCOLORBTN
				super.onReflectedMessage(msg);
		}
	}


	///
	protected override void wndProc(ref Message msg)
	{
		switch(msg.msg)
		{
			case WM_GETDLGCODE:
				msg.result = DLGC_WANTALLKEYS | DLGC_WANTARROWS;
				return;

			default:
				// Call super.wndProc() In order to call onHandleCreated() and others on WM_CREATE.
				// Must set DLGC_WANTALLKEYS on WM_GETDLGCODE,
				// because cannot input arrow key if call super.wndProc()
				super.wndProc(msg);
		}
	}


	///
	protected override void prevWndProc(ref Message msg)
	{
		msg.result = dfl.internal.utf.callWindowProc(trackbarPrevWndProc, msg.hWnd, msg.msg, msg.wParam, msg.lParam);
	}
	
	
	///
	final LRESULT prevwproc(UINT msg, WPARAM wparam, LPARAM lparam)
	{
		return dfl.internal.utf.callWindowProc(trackbarPrevWndProc, _hwnd, msg, wparam, lparam);
	}
}
