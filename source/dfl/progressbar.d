// Written by Christopher E. Miller
// See the included license.txt for copyright and license details.


///
module dfl.progressbar;

import dfl.application;
import dfl.base;
import dfl.control;
import dfl.drawing;
import dfl.event;

static import dfl.internal.utf;

import core.sys.windows.commctrl;
import core.sys.windows.windows;


private extern(Windows) void _initProgressbar();

///
enum ProgressBarStyle
{
	BLOCKS = 0, // On visual styles, same as CONTINUOUS.
	CONTINUOUS = 1, // Classic Styles only.
	MARQUEE = 2, // Visual styles only.
}

///
class ProgressBar: ControlSuperClass // docmain
{
	this()
	{
		_initProgressbar();
		
		_windowStyleEx |= WS_EX_CLIENTEDGE;
		_windowClassStyle = progressbarClassStyle;
	}
	
	
	///
	final @property void maximum(int max) // setter
	{
		if(max < 0)
		{
			throw new DflException("Unable to set progress bar maximum value");
		}
		
		if(created)
		{
			prevwproc(PBM_SETRANGE, 0, MAKELPARAM(_min, max));
		}
		
		_max = max;
		
		if(_value > max)
			value = max;
	}
	
	/// ditto
	final @property int maximum() // getter
	{
		return _max;
	}
	
	
	///
	final @property void minimum(int min) // setter
	{
		if(min < 0)
		{
			throw new DflException("Unable to set progress bar minimum value");
		}
		
		if(created)
		{
			prevwproc(PBM_SETRANGE, 0, MAKELPARAM(min, _max));
		}
		
		_min = min;
		
		if(_value < min)
			value = min;
	}
	
	/// ditto
	final @property int minimum() // getter
	{
		return _min;
	}
	
	
	///
	final @property void step(int stepby) // setter
	{
		if(created)
		{
			prevwproc(PBM_SETSTEP, stepby, 0);
		}
		
		_step = stepby;
	}
	
	/// ditto
	final @property int step() // getter
	{
		return _step;
	}
	
	
	///
	final @property void value(int setval) // setter
	{
		if(setval < _min || setval > _max)
		{
			if(setval > _max)
				setval = _max;
			else
				setval = _min;
		}
		
		if(created)
		{
			prevwproc(PBM_SETPOS, setval, 0);
		}
		
		_value = setval;
	}
	
	/// ditto
	final @property int value() // getter
	{
		return _value;
	}
	
	
	///
	final @property void style(ProgressBarStyle newStyle) // setter
	{
		LONG_PTR currentStyle = GetWindowLongPtrA(handle, GWL_STYLE);
		final switch (newStyle)
		{
			case ProgressBarStyle.BLOCKS:
				SetWindowLongPtrA(handle, GWL_STYLE, (currentStyle & ~PBS_SMOOTH) & ~PBS_MARQUEE);
				recreateHandle(); // Apply PBS_SMOOTH
				prevwproc(PBM_SETMARQUEE, false, 0);
				break;
			case ProgressBarStyle.CONTINUOUS:
				SetWindowLongPtrA(handle, GWL_STYLE, (currentStyle | PBS_SMOOTH) & ~PBS_MARQUEE);
				recreateHandle(); // Apply PBS_SMOOTH
				prevwproc(PBM_SETMARQUEE, false, 0);
				break;
			case ProgressBarStyle.MARQUEE:
				SetWindowLongPtrA(handle, GWL_STYLE, currentStyle | PBS_MARQUEE);
				prevwproc(PBM_SETMARQUEE, true, _marqueeAnimationSpeed);
		}
	}

	/// ditto
	final @property ProgressBarStyle style() // getter
	{
		LONG_PTR currentStyle = GetWindowLongPtrA(handle, GWL_STYLE);
		if (currentStyle & PBS_MARQUEE)
			return ProgressBarStyle.MARQUEE;
		else if (currentStyle & PBS_SMOOTH)
			return ProgressBarStyle.CONTINUOUS;
		else
			return ProgressBarStyle.BLOCKS;
	}


	///
	final @property void marqueeAnimationSpeed(int speed) // setter
	{
		_marqueeAnimationSpeed = speed;
		if (style == ProgressBarStyle.MARQUEE)
			prevwproc(PBM_SETMARQUEE, true, _marqueeAnimationSpeed);
		else
			prevwproc(PBM_SETMARQUEE, false, _marqueeAnimationSpeed);
	}

	/// ditto
	final @property int marqueeAnimationSpeed() // getter
	{
		return _marqueeAnimationSpeed;
	}


	///
	final void increment(int incby)
	{
		int newpos = _value + incby;
		if(newpos < _min)
			newpos = _min;
		if(newpos > _max)
			newpos = _max;
		
		if(created)
		{
			prevwproc(PBM_SETPOS, newpos, 0);
		}
		
		_value = newpos;
	}
	
	
	///
	final void performStep()
	{
		increment(_step);
	}
	
	
protected:
	override void onHandleCreated(EventArgs ea)
	{
		super.onHandleCreated(ea);
		
		if(_min != MIN_INIT || _max != MAX_INIT)
		{
			prevwproc(PBM_SETRANGE, 0, MAKELPARAM(_min, _max));
		}
		
		if(_step != STEP_INIT)
		{
			prevwproc(PBM_SETSTEP, _step, 0);
		}
		
		if(_value != VALUE_INIT)
		{
			prevwproc(PBM_SETPOS, _value, 0);
		}
	}
	
	
	override @property Size defaultSize() const // getter
	{
		return Size(100, 23);
	}
	
	
	static @property Color defaultForeColor() // getter
	{
		return SystemColors.highlight;
	}
	
	
	override void createParams(ref CreateParams cp)
	{
		super.createParams(cp);
		
		cp.className = PROGRESSBAR_CLASSNAME;
	}
	
	
	override void prevWndProc(ref Message msg)
	{
		msg.result = dfl.internal.utf.callWindowProc(progressbarPrevWndProc, msg.hWnd, msg.msg, msg.wParam, msg.lParam);
	}
	
	
private:
	enum MIN_INIT = 0;
	enum MAX_INIT = 100;
	enum STEP_INIT = 10;
	enum VALUE_INIT = 0;
	
	int _min = MIN_INIT;
	int _max = MAX_INIT;
	int _step = STEP_INIT;
	int _value = VALUE_INIT;
	int _marqueeAnimationSpeed = 0; // Default; 30 ms
	
	
package:
	final LRESULT prevwproc(UINT msg, WPARAM wparam, LPARAM lparam)
	{
		return dfl.internal.utf.callWindowProc(progressbarPrevWndProc, _hwnd, msg, wparam, lparam);
	}
}

