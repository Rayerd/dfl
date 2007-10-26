// Copyright (C) 2007 Christopher E. Miller
// See the included license.txt for license details.


///
module dfl.control;

import dfl.base, dfl.drawing;

import dfl.internal.gtk, dfl.internal.gtkcontainer;


/// Control creation parameters.
struct CreateParams
{
	GType type; ///
	GtkContainer* parent; /// ditto
	char[] text; /// ditto
}


// May be OR'ed together.
/// Style flags of a control.
enum ControlStyles: uint
{
	NONE = 0, ///
	
	CONTAINER_CONTROL =                0x1, /// ditto
	
	// TODO: implement.
	USER_PAINT =                       0x2, /// ditto
	
	OPAQUE =                           0x4, /// ditto
	RESIZE_REDRAW =                    0x10, /// ditto
	//FIXED_WIDTH =                      0x20, // TODO: implement.
	//FIXED_HEIGHT =                     0x40, // TODO: implement.
	STANDARD_CLICK =                   0x100, /// ditto
	SELECTABLE =                       0x200, /// ditto
	
	// TODO: implement.
	USER_MOUSE =                       0x400, ///  ditto
	
	//SUPPORTS_TRANSPARENT_BACK_COLOR =  0x800, // Only if USER_PAINT and parent is derived from Control. TODO: implement.
	STANDARD_DOUBLE_CLICK =            0x1000, /// ditto
	ALL_PAINTING_IN_WM_PAINT =         0x2000, /// ditto
	CACHE_TEXT =                       0x4000, /// ditto
	//ENABLE_NOTIFY_MESSAGE =            0x8000, // deprecated. Calls onNotifyMessage() for every message.
	//DOUBLE_BUFFER =                    0x10000, // TODO: implement.
	
	WANT_TAB_KEY = 0x01000000,
}


class Control
{
	///
	final HWindow handle() // IWindow getter
	{
		if(!isHandleCreated)
		{
			debug(APP_PRINT)
				printf("Control created due to handle request.\n");
			
			createHandle();
		}
		
		return wid;
	}
	
	
	///
	protected Size defaultSize() // getter
	{
		return Size(0, 0);
	}
	
	
	///
	// Force creation of the window and its child controls.
	final void createControl()
	{
		createHandle();
		
		createChildren();
	}
	
	
	package final void createChildren()
	{
		// ...
	}
	
	
	protected void gtkRequest(GtkWidget* w, GtkRequisition* req)
	{
		printf("GTKREQUEST\n");
		
		req.width = 100;
		req.height = 100;
	}
	
	private void _gtkRequest(GtkWidget* w, GtkRequisition* req)
	{
		return gtkRequest(w, req);
	}
	
	
	protected void gtkAllocate(GtkWidget* w, GtkAllocation* a)
	{
		// GTK reporting the position...
		
		printf("GTKALLOCATE x=%d; y=%d; width=%d; height=%d\n", a.x, a.y, a.width, a.height);
		
		//w.allocation.width = 200;
		//w.allocation.height = 200;
	}
	
	private void _gtkAllocate(GtkWidget* w, GtkAllocation* a)
	{
		return gtkAllocate(w, a);
	}
	
	
	package void _createcontainer()
	{
		if(wcontainer)
			return;
		
		assert(wid);
		
		wcontainer = cast(DflGtkContainer*)dflGtkContainer_new();
		if(!wcontainer)
			throw new DflException("Unable to create child control container");
		wcontainer.sizeRequest = &_gtkRequest;
		wcontainer.sizeAllocate = &_gtkAllocate;
		gtk_container_add(cast(GtkContainer*)wid, cast(GtkWidget*)wcontainer);
		
		gtk_widget_realize(cast(GtkWidget*)wcontainer);
		gtk_widget_show(cast(GtkWidget*)wcontainer);
	}
	
	
	///
	// Override to change the creation parameters.
	// Be sure to call super.createParams() or all the create params will need to be filled.
	protected void createParams(inout CreateParams cp)
	{
		with(cp)
		{
			type = gtk_widget_get_type();
			//parent = wparent ? wparent.wid : null;
			parent = null;
			if(wparent)
			{
				wparent._createcontainer();
				parent = &wparent.wcontainer.parent;
			}
			text = wtext;
		}
	}
	
	
	///
	protected void createHandle()
	{
		// Note: if modified, Form.createHandle() should be modified as well.
		
		if(isHandleCreated)
			return;
		
		// Need the parent's handle to exist.
		if(wparent)
			wparent.createHandle();
		
		// This is here because wparent.createHandle() might create me.
		//if(created)
		if(isHandleCreated)
			return;
		
		CreateParams cp;
		
		createParams(cp);
		assert(!isHandleCreated); // Make sure the handle wasn't created in createParams().
		
		wid = gtk_widget_new(cp.type, null);
		if(!wid)
		{
			create_err:
			throw new DflException("Control creation failure");
		}
		
		gtk_widget_set_size_request(wid, defaultSize.width, defaultSize.height); // ...
		
		postcreateinit(cp);
	}
	
	
	package void postcreateinit(inout CreateParams cp)
	{
		if(!(ctrlStyle & ControlStyles.CACHE_TEXT))
			wtext = null;
		gtkSetTextCore(cp.text);
		
		if(cp.parent)
		{
			//gtk_container_add(cast(GtkContainer*)cp.parent, wid);
			gtk_container_add(cp.parent, wid);
		}
		
		gtk_widget_realize(wid); // ...
		gtk_widget_show(wid); // ...
	}
	
	
	protected void gtkSetTextCore(char[] txt)
	{
		wtext = txt;
	}
	
	
	protected char[] gtkGetTextCore()
	{
		return wtext;
	}
	
	
	///
	void text(char[] txt) // setter
	{
		if(isHandleCreated)
		{
			if(ctrlStyle & ControlStyles.CACHE_TEXT)
			{
				//if(wtext == txt)
				//	return;
				wtext = txt;
			}
			
			gtkSetTextCore(txt);
		}
		else
		{
			wtext = txt;
		}
	}
	
	/// ditto
	char[] text() // getter
	{
		if(isHandleCreated)
		{
			if(ctrlStyle & ControlStyles.CACHE_TEXT)
				return wtext;
			
			return gtkGetTextCore();
		}
		else
		{
			return wtext;
		}
	}
	
	
	///
	final void parent(Control c) // setter
	{
		// ...
		
		wparent = c;
	}
	
	/// ditto
	final Control parent() // getter
	{
		return wparent;
	}
	
	
	///
	final bool isHandleCreated() // getter
	{
		return wid != wid.init;
	}
	
	
	// Note: true if no children, even if this not created.
	package final bool areChildrenCreated() // getter
	{
		return isHandleCreated; // ...
	}
	
	
	///
	final bool created() // getter
	{
		return isHandleCreated && areChildrenCreated;
	}
	
	
	///
	final void hide()
	{
		//setVisibleCore(false);
		
		// ...
	}
	
	/// ditto
	final void show()
	{
		//setVisibleCore(true);
		
		createControl(); // ...
	}
	
	
	package:
	
	GtkWidget* wid;
	DflGtkContainer* wcontainer;
	Control wparent;
	char[] wtext;
	ControlStyles ctrlStyle = ControlStyles.STANDARD_CLICK | ControlStyles.STANDARD_DOUBLE_CLICK /+ | ControlStyles.RESIZE_REDRAW +/ ;
}

