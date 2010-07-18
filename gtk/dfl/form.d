// Copyright (C) 2007 Christopher E. Miller
// See the included license.txt for license details.


///
module dfl.form;

import dfl.internal.dlib;
import dfl.control, dfl.base, dfl.drawing;
import dfl.internal.gtk;


///
class Form: Control
{
	protected override void createParams(inout CreateParams cp)
	{
		super.createParams(cp);
		
		with(cp)
		{
			type = gtk_window_get_type();
		}
	}
	
	
	protected override void createHandle()
	{
		if(isHandleCreated)
			return;
		
		// wowner..?
		
		// This is here because wparent.createHandle() might create me.
		//if(created)
		if(isHandleCreated)
			return;
		
		CreateParams cp;
		
		createParams(cp);
		assert(!isHandleCreated); // Make sure the handle wasn't created in createParams().
		
		wid = gtk_window_new(GtkWindowType.GTK_WINDOW_TOPLEVEL);
		if(!wid)
		{
			create_err:
			throw new DflException("Form creation failure");
		}
		auto win = cast(GtkWindow*)wid;
		
		gtk_window_set_default_size(win, 300, 300);
		
		postcreateinit(cp);
	}
	
	
	// Used internally
	protected override void gtkSetTextCore(char[] txt) // package
	{
		gtk_window_set_title(cast(GtkWindow*)wid, stringToStringz(txt));
	}
	
	// Used internally
	protected override char[] gtkGetTextCore() // package
	{
		char[] result;
		result = stringFromStringz(gtk_window_get_title(cast(GtkWindow*)wid));
		if(!result.length)
			return "";
		return result.dup;
	}
}

