// See the included license.txt for copyright and license details.


///
module dfl.control;

import dfl.internal.dlib, dfl.internal.clib, dfl.internal.gtk;

import dfl.event, dfl.drawing, dfl.base;


/// Flags for setting control bounds.
enum BoundsSpecified: ubyte
{
	NONE = 0, ///
	X = 1, /// ditto
	Y = 2, /// ditto
	LOCATION = 1 | 2, /// ditto
	WIDTH = 4, /// ditto
	HEIGHT = 8, /// ditto
	SIZE = 4 | 8, /// ditto
	ALL = 1 | 2 | 4 | 8, /// ditto
}


/// Layout docking style.
enum DockStyle: ubyte
{
	NONE, ///
	BOTTOM, ///
	FILL, ///
	LEFT, ///
	RIGHT, ///
	TOP, ///
}


// May be OR'ed together.
/// Style flags of a control.
enum ControlStyles: uint
{
	NONE = 0, ///
	
	CONTAINER_CONTROL =                0x1, /// ditto
}


/// Control creation parameters.
struct CreateParams
{
	GType type; ///
}


///
class ControlEventArgs: EventArgs
{
	///
	this(Control ctrl)
	{
		this.ctrl = ctrl;
	}
	
	
	///
	final Control control() // getter
	{
		return ctrl;
	}
	
	
	private:
	Control ctrl;
}


///
class HelpEventArgs: EventArgs
{
	///
	this(Point mousePos)
	{
		mpos = mousePos;
	}
	
	
	///
	final void handled(bool byes) // setter
	{
		hand = byes;
	}
	
	/// ditto
	final bool handled() // getter
	{
		return hand;
	}
	
	
	///
	final Point mousePos() // getter
	{
		return mpos;
	}
	
	
	private:
	Point mpos;
	bool hand = false;
}


///
class InvalidateEventArgs: EventArgs
{
	///
	this(Rect invalidRect)
	{
		ir = invalidRect;
	}
	
	
	///
	final Rect invalidRect() // getter
	{
		return ir;
	}
	
	
	private:
	Rect ir;
}


///
class LayoutEventArgs: EventArgs
{
	///
	this(Control affectedControl)
	{
		ac = affectedControl;
	}
	
	
	///
	final Control affectedControl() // getter
	{
		return ac;
	}
	
	
	private:
	Control ac;
}


/+
///
enum ControlFont: ubyte
{
	COMPATIBLE, ///
	OLD, /// ditto
	NATIVE, /// ditto
}
+/


class Control: IWindow
{
	package final void createChildren()
	{
		/+
		assert(isHandleCreated);
		
		Control[] ctrls;
		ctrls = ccollection.children;
		ccollection.children = null;
		
		foreach(Control ctrl; ctrls)
		{
			assert(ctrl.parent is this);
			assert(!(ctrl is null));
			assert(ctrl);
			ctrl.createControl();
		}
		+/
	}
	
	
	package final bool areChildrenCreated() // getter
	{
		return true; // To-do: fix.
	}
	
	
	///
	final bool isHandleCreated() // getter
	{
		return hwnd != null;
	}
	
	
	///
	// Override to change the creation parameters.
	// Be sure to call super.createParams() or all the create params will need to be filled.
	protected void createParams(inout CreateParams cp)
	{
		with(cp)
		{
			//cp.type = 
		}
	}
	
	
	///
	protected void createHandle()
	{
		// Note: if modified, Form.createHandle() should be modified as well.
		
		if(isHandleCreated)
			return;
		
		// GTK_TYPE_* (GTK_TYPE_LABEL = gtk_label_get_type() ...)
		//gtk_widget_new(GType gtype, const gchar*propname, = value, ... , NULL)
	}
	
	
	///
	// Force creation of the window and its child controls.
	final void createControl()
	{
		createHandle();
		
		// Called in WM_CREATE also.
		createChildren();
	}
	
	
	///
	final void parent(Control c) // setter
	{
		/+ // To-do: ...
		if(c is wparent)
			return;
		
		if(!(_style() & WS_CHILD) || (_exStyle() & WS_EX_MDICHILD))
			throw new DflException("Cannot add a top level control to a control");
		
		Control oldparent;
		_FixAmbientOld oldinfo;
		
		oldparent = wparent;
		
		if(oldparent)
		{
			oldinfo.set(oldparent);
			
			if(!oldparent.created)
			{
				int oi = oldparent.controls.indexOf(this);
				//assert(-1 != oi); // Fails if the parent (and thus this) handles destroyed.
				if(-1 != oi)
					oldparent.controls._removeNotCreated(oi);
			}
		}
		else
		{
			oldinfo.set(this);
		}
		
		scope ControlEventArgs cea = new ControlEventArgs(this);
		
		if(c)
		{
			wparent = c;
			
			// I want the destroy notification. Don't need it anymore.
			//c._exStyle(c._exStyle() & ~WS_EX_NOPARENTNOTIFY);
			
			if(c.created)
			{
				cbits &= ~CBits.NEED_INIT_LAYOUT;
				
				if(created)
				{
					SetParent(hwnd, c.hwnd);
				}
				else
				{
					// If the parent is created, create me!
					createControl();
				}
				
				onParentChanged(EventArgs.empty);
				if(oldparent)
					oldparent.onControlRemoved(cea);
				c._ctrladded(cea);
				_fixAmbient(&oldinfo);
				
				initLayout();
			}
			else
			{
				// If the parent exists and isn't created, need to add
				// -this- to its children array.
				c.ccollection.children ~= this;
				
				onParentChanged(EventArgs.empty);
				if(oldparent)
					oldparent.onControlRemoved(cea);
				c._ctrladded(cea);
				_fixAmbient(&oldinfo);
				
				cbits |= CBits.NEED_INIT_LAYOUT;
			}
		}
		else
		{
			assert(c is null);
			//wparent = c;
			wparent = null;
			
			if(created)
				SetParent(hwnd, HWND.init);
			
			onParentChanged(EventArgs.empty);
			assert(oldparent !is null);
			oldparent.onControlRemoved(cea);
			_fixAmbient(&oldinfo);
		}
		+/
	}
	
	
	///
	final HWindow handle() // IWindow getter
	{
		if(!created)
		{
			debug(APP_PRINT)
				printf("Control created due to handle request.\n");
			
			createHandle();
		}
		
		return hwnd;
	}
	
	
	///
	final bool created() // getter
	{
		return isHandleCreated && areChildrenCreated;
	}
	
	
	/// ditto
	final Control parent() // getter
	{
		return wparent;
	}
	
	
	package:
	GtkWidget* hwnd;
	Control wparent;
}

