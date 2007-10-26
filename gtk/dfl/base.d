// Copyright (C) 2007 Christopher E. Miller
// See the included license.txt for license details.


///
module dfl.base;

import dfl.internal.gtk;


alias GtkWidget* HWindow;


///
interface IWindow // docmain
{
	///
	HWindow handle(); // getter
}


///
class DflException: Exception // docmain
{
	///
	this(char[] msg)
	{
		super(msg);
	}
}

