// Copyright (C) 2007 Christopher E. Miller
// See the included license.txt for license details.


///
module dfl.label;

import dfl.internal.dlib;
import dfl.control, dfl.base, dfl.drawing;
import dfl.internal.gtk;


//version = DFLGTK_LABEL_BOX;


///
class Label: Control
{
	protected override Size defaultSize() // getter
	{
		return Size(100, 23);
	}
	
	
	protected override void createParams(inout CreateParams cp)
	{
		super.createParams(cp);
		
		with(cp)
		{
			version(DFLGTK_LABEL_BOX)
			{
				type = gtk_hbox_get_type();
			}
			else
			{
				type = gtk_label_get_type();
			}
		}
	}
	
	
	protected override void gtkSetTextCore(char[] txt)
	{
		gtk_label_set_text(cast(GtkLabel*)labelwid, stringToStringz(txt));
	}
	
	protected override char[] gtkGetTextCore()
	{
		char[] result;
		result = stringFromStringz(gtk_label_get_text(cast(GtkLabel*)labelwid));
		if(!result.length)
			return "";
		return result.dup;
	}
	
	package override void postcreateinit(inout CreateParams cp)
	{
		version(DFLGTK_LABEL_BOX)
		{
			labelwid = gtk_widget_new(gtk_label_get_type(), null);
			if(!labelwid)
			{
				throw new DflException("Control creation failure");
			}
		}
		
		//gtk_label_set_justify(cast(GtkLabel*)labelwid, GtkJustification.GTK_JUSTIFY_LEFT);
		
		//gtk_misc_set_alignment(pmisc, xalign, yalign)
		// 0.5 is centered, 0 is left, 1 is right.
		gtk_misc_set_alignment(cast(GtkMisc*)labelwid, 0.0, 0.0);
		
		super.postcreateinit(cp);
		
		version(DFLGTK_LABEL_BOX)
		{
			//gtk_container_add(cast(GtkContainer*)wid, labelwid);
			gtk_box_pack_start(cast(GtkBox*)wid, labelwid, false, false, 0);
			
			gtk_widget_realize(labelwid);
			gtk_widget_show(labelwid);
		}
	}
	
	version(DFLGTK_LABEL_BOX)
	{
		GtkWidget* labelwid;
	}
	else
	{
		alias wid labelwid;
	}
	
}

