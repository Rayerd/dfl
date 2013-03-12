// Written by Christopher E. Miller
// See the included license.txt for copyright and license details.


///
module dfl.progressbar;

private import dfl.base, dfl.control, dfl.drawing, dfl.application,
	dfl.event;
private import dfl.internal.winapi;


private extern(Windows) void _initProgressbar();


///
class ProgressBar: ControlSuperClass // docmain
{
	this()
	{
		_initProgressbar();
		
		wexstyle |= WS_EX_CLIENTEDGE;
		wclassStyle = progressbarClassStyle;
	}
	
	
	///
	final @property void maximum(int max) // setter
	{
		if(max <= 0 /+ || max < _min +/)
		{
			//bad_max:
			//throw new DflException("Unable to set progress bar maximum value");
			if(max)
				return;
		}
		
		if(created)
		{
			prevwproc(PBM_SETRANGE, 0, MAKELPARAM(_min, max));
		}
		
		_max = max;
		
		if(_val > max)
			_val = max; // ?
	}
	
	/// ditto
	final @property int maximum() // getter
	{
		return _max;
	}
	
	
	///
	final @property void minimum(int min) // setter
	{
		if(min < 0 /+ || min > _max +/)
		{
			//bad_min:
			//throw new DflException("Unable to set progress bar minimum value");
			return;
		}
		
		if(created)
		{
			prevwproc(PBM_SETRANGE, 0, MAKELPARAM(min, _max));
		}
		
		_min = min;
		
		if(_val < min)
			_val = min; // ?
	}
	
	/// ditto
	final @property int minimum() // getter
	{
		return _min;
	}
	
	
	///
	final @property void step(int stepby) // setter
	{
		if(stepby <= 0 /+ || stepby > _max +/)
		{
			//bad_max:
			//throw new DflException("Unable to set progress bar step value");
			if(stepby)
				return;
		}
		
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
			//throw new DflException("Progress bar value out of minimum/maximum range");
			//return;
			if(setval > _max)
				setval = _max;
			else
				setval = _min;
		}
		
		if(created)
		{
			prevwproc(PBM_SETPOS, setval, 0);
		}
		
		_val = setval;
	}
	
	/// ditto
	final @property int value() // getter
	{
		return _val;
	}
	
	
	///
	final void increment(int incby)
	{
		int newpos = _val + incby;
		if(newpos < _min)
			newpos = _min;
		if(newpos > _max)
			newpos = _max;
		
		if(created)
		{
			prevwproc(PBM_SETPOS, newpos, 0);
		}
		
		_val = newpos;
	}
	
	
	///
	final void performStep()
	{
		increment(_step);
	}
	
	
	protected override void onHandleCreated(EventArgs ea)
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
		
		if(_val != VAL_INIT)
		{
			prevwproc(PBM_SETPOS, _val, 0);
		}
	}
	
	
	protected override @property Size defaultSize() // getter
	{
		return Size(100, 23);
	}
	
	
	static @property Color defaultForeColor() // getter
	{
		return SystemColors.highlight;
	}
	
	
	protected override void createParams(ref CreateParams cp)
	{
		super.createParams(cp);
		
		cp.className = PROGRESSBAR_CLASSNAME;
	}
	
	
	protected override void prevWndProc(ref Message msg)
	{
		//msg.result = CallWindowProcA(progressbarPrevWndProc, msg.hWnd, msg.msg, msg.wParam, msg.lParam);
		msg.result = dfl.internal.utf.callWindowProc(progressbarPrevWndProc, msg.hWnd, msg.msg, msg.wParam, msg.lParam);
	}
	
	
	private:
	
	enum MIN_INIT = 0;
	enum MAX_INIT = 100;
	enum STEP_INIT = 10;
	enum VAL_INIT = 0;
	
	int _min = MIN_INIT, _max = MAX_INIT, _step = STEP_INIT, _val = VAL_INIT;
	
	
	package:
	final:
	LRESULT prevwproc(UINT msg, WPARAM wparam, LPARAM lparam)
	{
		//return CallWindowProcA(progressbarPrevWndProc, hwnd, msg, wparam, lparam);
		return dfl.internal.utf.callWindowProc(progressbarPrevWndProc, hwnd, msg, wparam, lparam);
	}
}

