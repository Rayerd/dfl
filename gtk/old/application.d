// See the included license.txt for copyright and license details.


///
module dfl.application;

import dfl.base, dfl.event;
import dfl.form;
import dfl.internal.clib, dfl.internal.dlib, dfl.internal.gtk;


///
class ApplicationContext // docmain
{
	///
	this()
	{
	}
	
	
	///
	// If onMainFormClose isn't overridden, the message
	// loop terminates when the main form is destroyed.
	this(Form mainForm)
	{
		mform = mainForm;
		mainForm.closed ~= &onMainFormClosed;
	}
	
	
	///
	final void mainForm(Form mainForm) // setter
	{
		if(mform)
			mform.closed.removeHandler(&onMainFormClosed);
		
		mform = mainForm;
		
		if(mainForm)
			mainForm.closed ~= &onMainFormClosed;
	}
	
	/// ditto
	final Form mainForm() // getter
	{
		return mform;
	}
	
	
	///
	//EventHandler threadExit;
	Event!() threadExit;
	
	
	///
	final void exitThread()
	{
		exitThreadCore();
	}
	
	
	protected:
	
	///
	void exitThreadCore()
	{
		threadExit(this, EventArgs.empty);
	}
	
	
	///
	void onMainFormClosed(Object sender, EventArgs args)
	{
		exitThreadCore();
	}
	
	
	private:
	Form mform; // The context form.
	void delegate() _whileIdle;
}


private extern(C) gboolean _dflMainWhileIdle(gpointer data)
{
	ApplicationContext appcon = cast(ApplicationContext)data;
	appcon._whileIdle();
	return true; // Continue.
}


///
final class Application // docmain
{
	private this() {}
	
	
	static:
	
	void enableVisualStyles()
	{
	}
	
	
	/+
	/// Path of the executable including its file name.
	char[] executablePath() // getter
	{
	}
	
	
	/// Directory containing the executable.
	char[] startupPath() // getter
	{
	}
	+/
	
	
	/+
	///
	bool messageLoop() // getter
	{
		return (threadFlags & TF.RUNNING) != 0;
	}
	+/
	
	
	/+
	///
	void addMessageFilter(IMessageFilter mf)
	{
		//filters ~= mf;
		
		IMessageFilter[] fs = filters;
		fs ~= mf;
		filters = fs;
	}
	
	/// ditto
	void removeMessageFilter(IMessageFilter mf)
	{
		uint i;
		for(i = 0; i != filters.length; i++)
		{
			if(mf is filters[i])
			{
				if(!i)
					filters = filters[1 .. filters.length];
				else if(i == filters.length - 1)
					filters = filters[0 .. i];
				else
					filters = filters[0 .. i] ~ filters[i + 1 .. filters.length];
				break;
			}
		}
	}
	+/
	
	
	/// Process all events in the mainloop. Returns false if the application should exit.
	bool doEvents()
	{
		while(gtk_events_pending())
		{
			if(gtk_main_iteration())
			{
				if(threadFlags & TF.QUIT)
					return false;
			}
		}
		return true;
	}
	
	
	package void run2(ApplicationContext appcon)
	{
		if(threadFlags & TF.RUNNING)
		{
			//throw new DflException("Can only have one mainloop at a time");
			assert(0, "Can only have one mainloop at a time");
			return;
		}
		
		if(threadFlags & TF.QUIT)
		{
			assert(0, "The application is shutting down");
			return;
		}
		
		
		void threadJustExited(Object sender, EventArgs ea)
		{
			exitThread();
		}
		
		
		ctx = appcon;
		ctx.threadExit ~= &threadJustExited;
		try
		{
			threadFlags = threadFlags | TF.RUNNING;
			
			if(ctx.mainForm)
			{
				//ctx.mainForm.createControl();
				ctx.mainForm.show();
			}
			
			if(ctx._whileIdle)
				g_idle_add(&_dflMainWhileIdle, cast(gpointer)ctx);
			
			for(;;)
			{
				try
				{
					gtk_main();
					
					// Stopped running.
					threadExit(Thread.getThis(), EventArgs.empty);
					threadFlags = threadFlags & ~(TF.RUNNING | TF.STOP_RUNNING);
					return;
				}
				catch(Object e)
				{
					onThreadException(e);
				}
			}
		}
		finally
		{
			threadFlags = threadFlags & ~(TF.RUNNING | TF.STOP_RUNNING);
			
			if(ctx._whileIdle)
				g_idle_remove_by_data(cast(gpointer)ctx);
			
			ApplicationContext tctx;
			tctx = ctx;
			ctx = null;
			
			tctx.threadExit.removeHandler(&threadJustExited);
		}
	}
	
	
	/// Run the application.
	void run()
	{
		run2(new ApplicationContext);
	}
	
	/// ditto
	void run(void delegate() whileIdle)
	{
		run(new ApplicationContext, whileIdle);
	}
	
	/// ditto
	void run(ApplicationContext appcon)
	{
		run2(appcon);
	}
	
	/// ditto
	void run(ApplicationContext appcon, void delegate() whileIdle)
	{
		assert(whileIdle !is null);
		appcon._whileIdle = whileIdle;
		run2(appcon);
	}
	
	/// ditto
	void run(Form mainForm)
	{
		ApplicationContext appcon = new ApplicationContext(mainForm);
		run2(appcon);
	}
	
	/// ditto
	void run(Form mainForm, void delegate() whileIdle)
	{
		ApplicationContext appcon = new ApplicationContext(mainForm);
		run(appcon, whileIdle);
	}
	
	
	///
	void exit()
	{
		threadFlags = threadFlags | TF.QUIT;
		
		gtk_main_quit();
	}
	
	
	/// Exit the thread's mainloop and return from run.
	// Actually only stops the current run() loop.
	void exitThread()
	{
		threadFlags = threadFlags | TF.STOP_RUNNING;
		
		gtk_main_quit();
	}
	
	
	// Will be null if not in a successful Application.run.
	package ApplicationContext context() // getter
	{
		return ctx;
	}
	
	
	/+
	///
	HINSTANCE getInstance()
	{
		if(!hinst)
			_initInstance();
		return hinst;
	}
	
	/// ditto
	void setInstance(HINSTANCE inst)
	{
		if(hinst)
		{
			if(inst != hinst)
				throw new DflException("Instance is already set");
			return;
		}
		
		if(inst)
		{
			_initInstance(inst);
		}
		else
		{
			_initInstance(); // ?
		}
	}
	+/
	
	
	//private static class ErrForm: Form
	
	
	/+
	///
	bool showDefaultExceptionDialog(Object e)
	{
	}
	+/
	
	
	///
	void onThreadException(Object e)
	{
		// To-do: showDefaultExceptionDialog if no handlers.
		
		threadException(Thread.getThis(), new ThreadExceptionEventArgs(e));
	}
	
	
	///
	Event!(ThreadExceptionEventArgs) threadException;
	///
	Event!() threadExit;
	
	
	/+ // ?
	///
	Resources resources() // getter
	{
	}
	+/
	
	
	///
	void autoCollect(bool byes) // setter
	{
		// To-do...
		//assert(0, "Not implemented");
	}
	
	/// ditto
	bool autoCollect() // getter
	{
		 // To-do...
		return false;
	}
	
	
	/+
	///
	// Because waiting for an event enters an idle state,
	// this function fires the -idle- event.
	void waitForEvent()
	{
		// Don't forget the autoCollect stuff.
	}
	+/
	
	
	private:
	//IMessageFilter[] filters;
	ApplicationContext ctx = null;
	uint threadFlags;
	
	
	enum TF: uint
	{
		RUNNING = 1, // Application.run is in affect.
		STOP_RUNNING = 2, // Application.exitThread was called.
		QUIT = 4, // Application.exit was called.
	}
}


package:

int dflargc = 0;
char*[1] _dflargva;
char** dflargv;

static this()
{
	_dflargva[0] = null;
	dflargv = _dflargva.ptr;
	
	if(!gtk_init_check(&dflargc, &dflargv))
		throw new DflException("Unable to initialize GUI library");
}

