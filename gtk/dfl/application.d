// Copyright (C) 2007 Christopher E. Miller
// See the included license.txt for license details.


///
module dfl.application;

import dfl.form, dfl.base;
import dfl.internal.gtk;


///
class Application
{
	static:
	
	///
	void run(Form mainForm)
	{
		if(mainForm)
			mainForm.show();
		
		gtk_main();
	}
	
	/// ditto
	void run()
	{
		return run(null);
	}
	
	
	///
	void exitThread()
	{
		gtk_main_quit();
	}
}


static this()
{
	gtk_init(null, null); // ...
}

