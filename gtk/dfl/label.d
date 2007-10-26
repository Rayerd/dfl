// Copyright (C) 2007 Christopher E. Miller
// See the included license.txt for license details.


///
module dfl.label;

import dfl.internal.dlib;
import dfl.control, dfl.base, dfl.drawing;
import dfl.internal.gtk;


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
			type = gtk_label_get_type();
		}
	}
	
	
	protected override void gtkSetTextCore(char[] txt)
	{
		gtk_label_set_text(cast(GtkLabel*)wid, stringToStringz(txt));
	}
	
	protected override char[] gtkGetTextCore()
	{
		char[] result;
		result = stringFromStringz(gtk_label_get_text(cast(GtkLabel*)wid));
		if(result.length)
			result = result.dup;
		return result;
	}
}

