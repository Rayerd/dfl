// Written by Christopher E. Miller
// See the included license.txt for copyright and license details.


///
module dfl.form;

private import dfl.internal.dlib;

private import dfl.control, dfl.internal.winapi, dfl.event, dfl.drawing;
private import dfl.application, dfl.base, dfl.internal.utf;
private import dfl.collections;

version(DFL_NO_MENUS)
{
}
else
{
	private import dfl.menu;
}

version(NO_DFL_PARK_WINDOW)
{
}
else
{
	version = DFL_PARK_WINDOW;
}


version = DFL_NO_ZOMBIE_FORM;


private extern(Windows) void _initMdiclient();


///
enum FormBorderStyle: ubyte //: BorderStyle
{
	NONE = BorderStyle.NONE, ///
	
	FIXED_3D = BorderStyle.FIXED_3D, /// ditto
	FIXED_SINGLE = BorderStyle.FIXED_SINGLE, /// ditto
	FIXED_DIALOG, /// ditto
	SIZABLE, /// ditto
	FIXED_TOOLWINDOW, /// ditto
	SIZABLE_TOOLWINDOW, /// ditto
}


///
deprecated enum SizeGripStyle: ubyte
{
	AUTO, ///
	HIDE, /// ditto
	SHOW, /// ditto
}


///
enum FormStartPosition: ubyte
{
	CENTER_PARENT, ///
	CENTER_SCREEN, /// ditto
	MANUAL, /// ditto
	DEFAULT_BOUNDS, /// ditto
	WINDOWS_DEFAULT_BOUNDS = DEFAULT_BOUNDS, // deprecated
	DEFAULT_LOCATION, /// ditto
	WINDOWS_DEFAULT_LOCATION = DEFAULT_LOCATION, // deprecated
}


///
enum FormWindowState: ubyte
{
	MAXIMIZED, ///
	MINIMIZED, /// ditto
	NORMAL, /// ditto
}


///
enum MdiLayout: ubyte
{
	ARRANGE_ICONS, ///
	CASCADE, /// ditto
	TILE_HORIZONTAL, /// ditto
	TILE_VERTICAL, /// ditto
}


///
// The Form's shortcut was pressed.
class FormShortcutEventArgs: EventArgs
{
	///
	this(Keys shortcut)
	{
		this._shortcut = shortcut;
	}
	
	
	///
	final @property Keys shortcut() // getter
	{
		return _shortcut;
	}
	
	
	private:
	Keys _shortcut;
}


// DMD 0.93 crashes if this is placed in Form.
//private import dfl.button;


version = OLD_MODAL_CLOSE; // New version destroys control info.


///
class Form: ContainerControl, IDialogResult // docmain
{
	///
	final @property void acceptButton(IButtonControl btn) // setter
	{
		if(acceptBtn)
			acceptBtn.notifyDefault(false);
		
		acceptBtn = btn;
		
		if(btn)
			btn.notifyDefault(true);
	}
	
	/// ditto
	final @property IButtonControl acceptButton() // getter
	{
		return acceptBtn;
	}
	
	
	///
	final @property void cancelButton(IButtonControl btn) // setter
	{
		cancelBtn = btn;
		
		if(btn)
		{
			if(!(Application._compat & DflCompat.FORM_DIALOGRESULT_096))
			{
				btn.dialogResult = DialogResult.CANCEL;
			}
		}
	}
	
	/// ditto
	final @property IButtonControl cancelButton() // getter
	{
		return cancelBtn;
	}
	
	
	///
	// An exception is thrown if the shortcut was already added.
	final void addShortcut(Keys shortcut, void delegate(Object sender, FormShortcutEventArgs ea) pressed)
	in
	{
		assert(shortcut & Keys.KEY_CODE); // At least one key code.
		assert(pressed !is null);
	}
	body
	{
		if(shortcut in _shortcuts)
			throw new DflException("Shortcut key conflict");
		
		_shortcuts[shortcut] = pressed;
	}
	
	/// ditto
	// Delegate parameter contravariance.
	final void addShortcut(Keys shortcut, void delegate(Object sender, EventArgs ea) pressed)
	{
		return addShortcut(shortcut, cast(void delegate(Object sender, FormShortcutEventArgs ea))pressed);
	}
	
	/// ditto
	final void removeShortcut(Keys shortcut)
	{
		//delete _shortcuts[shortcut];
		_shortcuts.remove(shortcut);
	}
	
	
	///
	static @property Form activeForm() // getter
	{
		return cast(Form)fromHandle(GetActiveWindow());
	}
	
	
	///
	final @property Form getActiveMdiChild() // getter
	{
		return cast(Form)fromHandle(cast(HWND)SendMessageA(handle, WM_MDIGETACTIVE, 0, 0));
	}
	
	
	protected override @property Size defaultSize() // getter
	{
		return Size(300, 300);
	}
	
	
	// Note: the following 2 functions aren't completely accurate;
	// it sounds like it should return the center point, but it
	// returns the point that would center the current form.
	
	final @property Point screenCenter() // getter
	{
		Rect area;
		version(DFL_MULTIPLE_SCREENS)
		{
			if(wparent && wparent.created)
			{
				area = Screen.fromControl(wparent).workingArea;
			}
			else
			{
				if(this.left != 0 && this.top != 0)
				{
					area = Screen.fromRectangle(this.bounds).workingArea;
				}
				else
				{
					area = Screen.fromPoint(Control.mousePosition).workingArea;
				}
			}
		}
		else
		{
			area = Screen.primaryScreen.workingArea;
		}
		
		Point pt;
		pt.x = area.x + ((area.width - this.width) / 2);
		pt.y = area.y + ((area.height - this.height) / 2);
		return pt;
	}
	
	
	final @property Point parentCenter() // getter
	{
		Control cwparent;
		if(wstyle & WS_CHILD)
			cwparent = wparent;
		else
			cwparent = wowner;
		
		if(!cwparent || !cwparent.visible)
			return screenCenter;
		
		Point pt;
		pt.x = cwparent.left + ((cwparent.width - this.width) / 2);
		pt.y = cwparent.top + ((cwparent.height - this.height) / 2);
		return pt;
	}
	
	
	///
	final void centerToScreen()
	{
		location = screenCenter;
	}
	
	
	///
	final void centerToParent()
	{
		location = parentCenter;
	}
	
	
	protected override void createParams(ref CreateParams cp)
	{
		super.createParams(cp);
		
		Control cwparent;
		if(cp.style & WS_CHILD)
			cwparent = wparent;
		else
			cwparent = wowner;
		
		cp.className = FORM_CLASSNAME;
		version(DFL_NO_MENUS)
		{
			cp.menu = HMENU.init;
		}
		else
		{
			cp.menu = wmenu ? wmenu.handle : HMENU.init;
		}
		
		//cp.parent = wparent ? wparent.handle : HWND.init;
		//if(!(cp.style & WS_CHILD))
		//	cp.parent = wowner ? wowner.handle : HWND.init;
		cp.parent = cwparent ? cwparent.handle : HWND.init;
		if(!cp.parent)
			cp.parent = sowner;
		version(DFL_PARK_WINDOW)
		{
			if(!cp.parent && !showInTaskbar)
				cp.parent = getParkHwnd();
		}
		
		if(!recreatingHandle)
		{
			switch(startpos)
			{
				case FormStartPosition.CENTER_PARENT:
					if(cwparent && cwparent.visible)
					{
						cp.x = cwparent.left + ((cwparent.width - cp.width) / 2);
						cp.y = cwparent.top + ((cwparent.height - cp.height) / 2);
						
						// Make sure part of the form isn't off the screen.
						RECT area;
						SystemParametersInfoA(SPI_GETWORKAREA, 0, &area, FALSE);
						if(cp.x < area.left)
							cp.x = area.left;
						else if(cp.x + cp.width > area.right)
							cp.x = area.right - cp.width;
						if(cp.y < area.top)
							cp.y = area.top;
						else if(cp.y + cp.height > area.bottom)
							cp.y = area.bottom - cp.height;
						break;
					}
					break;
				
				case FormStartPosition.CENTER_SCREEN:
					{
						// TODO: map to client coords if MDI child.
						
						RECT area;
						SystemParametersInfoA(SPI_GETWORKAREA, 0, &area, FALSE);
						
						cp.x = area.left + (((area.right - area.left) - cp.width) / 2);
						cp.y = area.top + (((area.bottom - area.top) - cp.height) / 2);
					}
					break;
				
				case FormStartPosition.DEFAULT_BOUNDS:
					// WM_CREATE fixes these.
					cp.width = CW_USEDEFAULT;
					cp.height = CW_USEDEFAULT;
					//break; // DEFAULT_BOUNDS assumes default location.
					goto case FormStartPosition.DEFAULT_LOCATION;
				
				case FormStartPosition.DEFAULT_LOCATION:
					// WM_CREATE fixes these.
					cp.x = CW_USEDEFAULT;
					//cp.y = CW_USEDEFAULT;
					cp.y = visible ? SW_SHOW : SW_HIDE;
					break;
				
				default:
			}
		}
	}
	
	
	protected override void createHandle()
	{
		// This code is reimplemented to allow some tricks.
		
		if(isHandleCreated)
			return;
		
		debug
		{
			Dstring er;
		}
		if(killing)
		{
			/+
			create_err:
			throw new DflException("Form creation failure");
			//throw new DflException(Object.toString() ~ " creation failure"); // ?
			+/
			debug
			{
				er = "the form is being killed";
			}
			
			debug(APP_PRINT)
			{
				cprintf("Creating Form handle while killing.\n");
			}
			
			create_err:
			Dstring kmsg = "Form creation failure";
			if(name.length)
				kmsg ~= " (" ~ name ~ ")";
			debug
			{
				if(er.length)
					kmsg ~= " - " ~ er;
			}
			throw new DflException(kmsg);
			//throw new DflException(Object.toString() ~ " creation failure"); // ?
		}
		
		// Need the owner's handle to exist.
		if(wowner)
		//	wowner.createHandle(); // DMD 0.111: class dfl.control.Control member createHandle is not accessible
			wowner._createHandle();
		
		// This is here because wowner.createHandle() might create me.
		//if(created)
		if(isHandleCreated)
			return;
		
		//DWORD vis;
		CBits vis;
		CreateParams cp;
		
		createParams(cp);
		assert(!isHandleCreated); // Make sure the handle wasn't created in createParams().
		
		with(cp)
		{
			wtext = caption;
			//wrect = Rect(x, y, width, height); // Avoid CW_USEDEFAULT problems. This gets updated in WM_CREATE.
			wclassStyle = classStyle;
			wexstyle = exStyle;
			wstyle = style;
			
			// Use local var to avoid changing -cp- at this point.
			int ly;
			ly = y;
			
			// Delay setting visible.
			//vis = wstyle;
			vis = cbits;
			vis |= CBits.FVISIBLE;
			if(!(vis & CBits.VISIBLE))
				vis &= ~CBits.FVISIBLE;
			if(x == CW_USEDEFAULT)
				ly = SW_HIDE;
			
			Application.creatingControl(this);
			hwnd = dfl.internal.utf.createWindowEx(exStyle, className, caption, wstyle & ~WS_VISIBLE,
				x, ly, width, height, parent, menu, inst, param);
			if(!hwnd)
			{
				debug
				{
					er = std.string.format("CreateWindowEx failed {className=%s;exStyle=0x%X;style=0x%X;parent=0x%X;menu=0x%X;inst=0x%X;}",
						className, exStyle, style, cast(void*)parent, cast(void*)menu, cast(void*)inst);
				}
				goto create_err;
			}
		}
		
		if(setLayeredWindowAttributes)
		{
			BYTE alpha = opacityToAlpha(opa);
			DWORD flags = 0;
			
			if(alpha != BYTE.max)
				flags |= LWA_ALPHA;
			
			if(transKey != Color.empty)
				flags |= LWA_COLORKEY;
			
			if(flags)
			{
				//_exStyle(_exStyle() | WS_EX_LAYERED); // Should already be set.
				setLayeredWindowAttributes(hwnd, transKey.toRgb(), alpha, flags);
			}
		}
		
		if(!nofilter)
			Application.addMessageFilter(mfilter); // To process IsDialogMessage().
		
		//createChildren();
		try
		{
			createChildren(); // Might throw.
		}
		catch(DThrowable e)
		{
			Application.onThreadException(e);
		}
		
		alayout(this, false); // ?
		
		if(!recreatingHandle) // This stuff already happened if recreating...
		{
			if(autoScale)
			{
				//Application.doEvents(); // ?
				
				_scale();
				
				// Scaling can goof up the centering, so fix it..
				switch(startpos)
				{
					case FormStartPosition.CENTER_PARENT:
						centerToParent();
						break;
					case FormStartPosition.CENTER_SCREEN:
						centerToScreen();
						break;
					default:
				}
			}
			
			if(Application._compat & DflCompat.FORM_LOAD_096)
			{
				// Load before shown.
				// Not calling if recreating handle!
				onLoad(EventArgs.empty);
			}
		}
		
		//assert(!visible);
		//if(vis & WS_VISIBLE)
		//if(vis & CBits.VISIBLE)
		if(vis & CBits.FVISIBLE)
		{
			cbits |= CBits.VISIBLE;
			wstyle |= WS_VISIBLE;
			if(recreatingHandle)
				goto show_normal;
			// These fire onVisibleChanged as needed...
			switch(windowState)
			{
				case FormWindowState.NORMAL: show_normal:
					ShowWindow(hwnd, SW_SHOW);
					// Possible to-do: see if non-MDI is "main form" and use SHOWNORMAL or doShow.
					break;
				case FormWindowState.MAXIMIZED:
					ShowWindow(hwnd, SW_SHOWMAXIMIZED);
					break;
				case FormWindowState.MINIMIZED:
					ShowWindow(hwnd, SW_SHOWMINIMIZED);
					break;
				default:
					assert(0);
			}
		}
		//cbits &= ~CBits.FVISIBLE;
	}
	
	
	/+
	///
	// Focused children are scrolled into view.
	override @property void autoScroll(bool byes) // setter
	{
		super.autoScroll(byes);
	}
	
	/// ditto
	override @property bool autoScroll() // getter
	{
		return super.autoScroll(byes);
	}
	+/
	
	
	// This only works if the windows version is
	// set to 4.0 or higher.
	
	///
	final @property void controlBox(bool byes) // setter
	{
		if(byes)
			_style(_style() | WS_SYSMENU);
		else
			_style(_style() & ~WS_SYSMENU);
		
		// Update taskbar button.
		if(isHandleCreated)
		{
			if(visible)
			{
				//hide();
				//show();
				// Do it directly so that DFL code can't prevent it.
				cbits |= CBits.RECREATING;
				scope(exit)
					cbits &= ~CBits.RECREATING;
				doHide();
				doShow();
			}
		}
	}
	
	/// ditto
	final @property bool controlBox() // getter
	{
		return (_style() & WS_SYSMENU) != 0;
	}
	
	
	///
	final @property void desktopBounds(Rect r) // setter
	{
		RECT rect;
		if(r.width < 0)
			r.width = 0;
		if(r.height < 0)
			r.height = 0;
		r.getRect(&rect);
		
		//Control par = parent;
		//if(par) // Convert from screen coords to parent coords.
		//	MapWindowPoints(HWND.init, par.handle, cast(POINT*)&rect, 2);
		
		setBoundsCore(rect.left, rect.top, rect.right - rect.left, rect.bottom - rect.top, BoundsSpecified.ALL);
	}
	
	/// ditto
	final @property Rect desktopBounds() // getter
	{
		RECT r;
		GetWindowRect(handle, &r);
		return Rect(&r);
	}
	
	
	///
	final @property void desktopLocation(Point dp) // setter
	{
		//Control par = parent;
		//if(par) // Convert from screen coords to parent coords.
		//	MapWindowPoints(HWND.init, par.handle, &dp.point, 1);
		
		setBoundsCore(dp.x, dp.y, 0, 0, BoundsSpecified.LOCATION);
	}
	
	/// ditto
	final @property Point desktopLocation() // getter
	{
		RECT r;
		GetWindowRect(handle, &r);
		return Point(r.left, r.top);
	}
	
	
	///
	final @property void dialogResult(DialogResult dr) // setter
	{
		fresult = dr;
		
		if(!(Application._compat & DflCompat.FORM_DIALOGRESULT_096))
		{
			if(modal && DialogResult.NONE != dr)
				close();
		}
	}
	
	/// ditto
	final @property DialogResult dialogResult() // getter
	{
		return fresult;
	}
	
	
	override @property Color backColor() // getter
	{
		if(Color.empty == backc)
			return defaultBackColor; // Control's.
		return backc;
	}
	
	alias Control.backColor backColor; // Overload.
	
	
	///
	final @property void formBorderStyle(FormBorderStyle bstyle) // setter
	{
		FormBorderStyle curbstyle;
		curbstyle = formBorderStyle;
		if(bstyle == curbstyle)
			return;
		
		bool vis = false;
		
		if(isHandleCreated && visible)
		{
			vis = true;
			cbits |= CBits.RECREATING;
			// Do it directly so that DFL code can't prevent it.
			//doHide();
			ShowWindow(hwnd, SW_HIDE);
		}
		scope(exit)
			cbits &= ~CBits.RECREATING;
		
		LONG st;
		LONG exst;
		//Size csz;
		st = _style();
		exst = _exStyle();
		//csz = clientSize;
		
		enum DWORD STNOTNONE = ~(WS_BORDER | WS_THICKFRAME | WS_CAPTION | WS_DLGFRAME);
		enum DWORD EXSTNOTNONE = ~(WS_EX_TOOLWINDOW | WS_EX_CLIENTEDGE
			| WS_EX_DLGMODALFRAME | WS_EX_STATICEDGE | WS_EX_WINDOWEDGE);
		
		// This is needed to work on Vista.
		if(FormBorderStyle.NONE != curbstyle)
		{
			_style(st & STNOTNONE);
			_exStyle(exst & EXSTNOTNONE);
		}
		
		final switch(bstyle)
		{
			case FormBorderStyle.FIXED_3D:
				st &= ~(WS_BORDER | WS_THICKFRAME | WS_DLGFRAME);
				exst &= ~(WS_EX_TOOLWINDOW | WS_EX_STATICEDGE);
				
				st |= WS_CAPTION;
				exst |= WS_EX_CLIENTEDGE | WS_EX_DLGMODALFRAME | WS_EX_WINDOWEDGE;
				break;
			
			case FormBorderStyle.FIXED_DIALOG:
				st &= ~(WS_BORDER | WS_THICKFRAME);
				exst &= ~(WS_EX_TOOLWINDOW | WS_EX_CLIENTEDGE | WS_EX_STATICEDGE);
				
				st |= WS_CAPTION | WS_DLGFRAME;
				exst |= WS_EX_DLGMODALFRAME | WS_EX_WINDOWEDGE;
				break;
			
			case FormBorderStyle.FIXED_SINGLE:
				st &= ~(WS_THICKFRAME | WS_DLGFRAME);
				exst &= ~(WS_EX_TOOLWINDOW | WS_EX_CLIENTEDGE | WS_EX_WINDOWEDGE | WS_EX_STATICEDGE);
				
				st |= WS_BORDER | WS_CAPTION;
				exst |= WS_EX_DLGMODALFRAME;
				break;
			
			case FormBorderStyle.FIXED_TOOLWINDOW:
				st &= ~(WS_BORDER | WS_THICKFRAME | WS_DLGFRAME);
				exst &= ~(WS_EX_CLIENTEDGE | WS_EX_STATICEDGE);
				
				st |= WS_CAPTION;
				exst |= WS_EX_TOOLWINDOW | WS_EX_WINDOWEDGE | WS_EX_DLGMODALFRAME;
				break;
			
			case FormBorderStyle.SIZABLE:
				st &= ~(WS_BORDER | WS_DLGFRAME);
				exst &= ~(WS_EX_TOOLWINDOW | WS_EX_CLIENTEDGE | WS_EX_DLGMODALFRAME | WS_EX_STATICEDGE);
				
				st |= WS_THICKFRAME | WS_CAPTION;
				exst |= WS_EX_WINDOWEDGE;
				break;
			
			case FormBorderStyle.SIZABLE_TOOLWINDOW:
				st &= ~(WS_BORDER | WS_DLGFRAME);
				exst &= ~(WS_EX_CLIENTEDGE | WS_EX_DLGMODALFRAME | WS_EX_STATICEDGE);
				
				st |= WS_THICKFRAME | WS_CAPTION;
				exst |= WS_EX_TOOLWINDOW | WS_EX_WINDOWEDGE;
				break;
			
			case FormBorderStyle.NONE:
				st &= STNOTNONE;
				exst &= EXSTNOTNONE;
				break;
		}
		
		_style(st);
		_exStyle(exst);
		//clientSize = csz;
		
		// Update taskbar button.
		if(isHandleCreated)
		{
			if(vis)
			{
				//hide();
				//show();
				SetWindowPos(hwnd, HWND.init, 0, 0, 0, 0, SWP_FRAMECHANGED | SWP_NOMOVE
					| SWP_NOSIZE | SWP_NOZORDER); // Recalculate the frame while hidden.
				_resetSystemMenu();
				// Do it directly so that DFL code can't prevent it.
				doShow();
				invalidate(true);
			}
			else
			{
				SetWindowPos(hwnd, HWND.init, 0, 0, 0, 0, SWP_FRAMECHANGED | SWP_NOMOVE
					| SWP_NOSIZE | SWP_NOZORDER | SWP_NOACTIVATE); // Recalculate the frame.
				_resetSystemMenu();
			}
		}
	}
	
	/// ditto
	final @property FormBorderStyle formBorderStyle() // getter
	{
		LONG st = _style();
		LONG exst = _exStyle();
		
		if(exst & WS_EX_TOOLWINDOW)
		{
			if(st & WS_THICKFRAME)
				return FormBorderStyle.SIZABLE_TOOLWINDOW;
			else
				return FormBorderStyle.FIXED_TOOLWINDOW;
		}
		else
		{
			if(st & WS_THICKFRAME)
			{
				return FormBorderStyle.SIZABLE;
			}
			else
			{
				if(exst & WS_EX_CLIENTEDGE)
					return FormBorderStyle.FIXED_3D;
				
				if(exst & WS_EX_WINDOWEDGE)
					return FormBorderStyle.FIXED_DIALOG;
				
				if(st & WS_BORDER)
					return FormBorderStyle.FIXED_SINGLE;
			}
		}
		
		return FormBorderStyle.NONE;
	}
	
	
	///
	// Ignored if min and max buttons are enabled.
	final @property void helpButton(bool byes) // setter
	{
		if(byes)
			_exStyle(_exStyle() | WS_EX_CONTEXTHELP);
		else
			_exStyle(_exStyle() & ~WS_EX_CONTEXTHELP);
		
		redrawEntire();
	}
	
	/// ditto
	final @property bool helpButton() // getter
	{
		return (_exStyle() & WS_EX_CONTEXTHELP) != 0;
	}
	
	
	private void _setIcon()
	{
		HICON hico, hicoSm;
		
		if(wicon)
		{
			hico = wicon.handle;
			
			int smx, smy;
			smx = GetSystemMetrics(SM_CXSMICON);
			smy = GetSystemMetrics(SM_CYSMICON);
			hicoSm = CopyImage(hico, IMAGE_ICON, smx, smy, LR_COPYFROMRESOURCE);
			if(!hicoSm)
				hicoSm = CopyImage(hico, IMAGE_ICON, smx, smy, 0);
			if(hicoSm)
			{
				wiconSm = new Icon(hicoSm);
			}
			else
			{
				wiconSm = null;
				hicoSm = hico;
			}
		}
		else
		{
			hico = HICON.init;
			hicoSm = HICON.init;
			
			wiconSm = null;
		}
		
		SendMessageA(hwnd, WM_SETICON, ICON_BIG, cast(LPARAM)hico);
		SendMessageA(hwnd, WM_SETICON, ICON_SMALL, cast(LPARAM)hicoSm);
		
		if(visible)
			redrawEntire();
	}
	
	
	///
	final @property void icon(Icon ico) // setter
	{
		wicon = ico;
		
		if(isHandleCreated)
			_setIcon();
	}
	
	/// ditto
	final @property Icon icon() // getter
	{
		return wicon;
	}
	
	
	// TODO: implement.
	// keyPreview
	
	
	///
	final @property bool isMdiChild() // getter
	{
		return (_exStyle() & WS_EX_MDICHILD) != 0;
	}
	
	
	version(NO_MDI)
	{
		private alias Control MdiClient; // ?
	}
	
	///
	// Note: keeping this here for NO_MDI to keep the vtable.
	protected MdiClient createMdiClient()
	{
		version(NO_MDI)
		{
			assert(0, "MDI disabled");
		}
		else
		{
			return new MdiClient();
		}
	}
	
	
	version(NO_MDI) {} else
	{
		///
		final @property void isMdiContainer(bool byes) // setter
		{
			if(mdiClient)
			{
				if(!byes)
				{
					// Remove MDI client.
					mdiClient.dispose();
					//mdiClient = null;
					_mdiClient = null;
				}
			}
			else
			{
				if(byes)
				{
					// Create MDI client.
					//mdiClient = new MdiClient;
					//_mdiClient = new MdiClient;
					//mdiClient = createMdiClient();
					_mdiClient = createMdiClient();
					mdiClient.parent = this;
				}
			}
		}
		
		/// ditto
		final @property bool isMdiContainer() // getter
		{
			version(NO_MDI)
			{
				return false;
			}
			else
			{
				return !(mdiClient is null);
			}
		}
		
		
		///
		final Form[] mdiChildren() // getter
		{
			version(NO_MDI)
			{
				return null;
			}
			else
			{
				/+
				if(!mdiClient)
					return null;
				+/
				
				return _mdiChildren;
			}
		}
		
		
		// parent is the MDI client and mdiParent is the MDI frame.
		
		
		version(NO_MDI) {} else
		{
			///
			final @property void mdiParent(Form frm) // setter
			in
			{
				if(frm)
				{
					assert(frm.isMdiContainer);
					assert(!(frm.mdiClient is null));
				}
			}
			/+out
			{
				if(frm)
				{
					bool found = false;
					foreach(Form elem; frm._mdiChildren)
					{
						if(elem is this)
						{
							found = true;
							break;
						}
					}
					assert(found);
				}
			}+/
			body
			{
				if(wmdiparent is frm)
					return;
				
				_removeFromOldOwner();
				wowner = null;
				wmdiparent = null; // Safety in case of exception.
				
				if(frm)
				{
					if(isHandleCreated)
					{
						frm.createControl(); // ?
						frm.mdiClient.createControl(); // Should already be done from frm.createControl().
					}
					
					// Copy so that old mdiChildren arrays won't get overwritten.
					Form[] _thisa = new Form[1]; // DMD 0.123: this can't be a static array or the append screws up.
					_thisa[0] = this;
					frm._mdiChildren = frm._mdiChildren ~ _thisa;
					
					_style((_style() | WS_CHILD) & ~WS_POPUP);
					_exStyle(_exStyle() | WS_EX_MDICHILD);
					
					wparent = frm.mdiClient;
					wmdiparent = frm;
					if(isHandleCreated)
						SetParent(hwnd, frm.mdiClient.hwnd);
				}
				else
				{
					_exStyle(_exStyle() & ~WS_EX_MDICHILD);
					_style((_style() | WS_POPUP) & ~WS_CHILD);
					
					if(isHandleCreated)
						SetParent(hwnd, HWND.init);
					wparent = null;
					
					//wmdiparent = null;
				}
			}
		}
		
		/// ditto
		final @property Form mdiParent() // getter
		{
			version(NO_MDI)
			{
				return null;
			}
			else
			{
				//if(isMdiChild)
					return wmdiparent;
				//return null;
			}
		}
	}
	
	
	///
	final @property void maximizeBox(bool byes) // setter
	{
		if(byes == maximizeBox)
			return;
		
		if(byes)
			_style(_style() | WS_MAXIMIZEBOX);
		else
			_style(_style() & ~WS_MAXIMIZEBOX);
		
		if(isHandleCreated)
		{
			redrawEntire();
			
			_resetSystemMenu();
		}
	}
	
	/// ditto
	final @property bool maximizeBox() // getter
	{
		return (_style() & WS_MAXIMIZEBOX) != 0;
	}
	
	
	///
	final @property void minimizeBox(bool byes) // setter
	{
		if(byes == minimizeBox)
			return;
		
		if(byes)
			_style(_style() | WS_MINIMIZEBOX);
		else
			_style(_style() & ~WS_MINIMIZEBOX);
		
		if(isHandleCreated)
		{
			redrawEntire();
			
			_resetSystemMenu();
		}
	}
	
	/// ditto
	final @property bool minimizeBox() // getter
	{
		return (_style() & WS_MINIMIZEBOX) != 0;
	}
	
	
	protected override void onHandleCreated(EventArgs ea)
	{
		super.onHandleCreated(ea);
		
		version(DFL_NO_MENUS)
		{
		}
		else
		{
			if(wmenu)
				wmenu._setHwnd(handle);
		}
		
		_setIcon();
		
		//SendMessageA(handle, DM_SETDEFID, IDOK, 0);
	}
	
	
	protected override void onResize(EventArgs ea)
	{
		super.onResize(ea);
		
		if(_isPaintingSizeGrip())
		{
			RECT rect;
			_getSizeGripArea(&rect);
			InvalidateRect(hwnd, &rect, TRUE);
		}
	}
	
	
	private void _getSizeGripArea(RECT* rect)
	{
		rect.right = clientSize.width;
		rect.bottom = clientSize.height;
		rect.left = rect.right - GetSystemMetrics(SM_CXVSCROLL);
		rect.top = rect.bottom - GetSystemMetrics(SM_CYHSCROLL);
	}
	
	
	private bool _isPaintingSizeGrip()
	{
		if(grip)
		{
			if(wstyle & WS_THICKFRAME)
			{
				return !(wstyle & (WS_MINIMIZE | WS_MAXIMIZE |
					WS_VSCROLL | WS_HSCROLL));
			}
		}
		return false;
	}
	
	
	protected override void onPaint(PaintEventArgs ea)
	{
		super.onPaint(ea);
		
		if(_isPaintingSizeGrip())
		{
			/+
			RECT rect;
			_getSizeGripArea(&rect);
			DrawFrameControl(ea.graphics.handle, &rect, DFC_SCROLL, DFCS_SCROLLSIZEGRIP);
			+/
			
			ea.graphics.drawSizeGrip(clientSize.width, clientSize.height);
		}
	}
	
	
	version(DFL_NO_MENUS)
	{
	}
	else
	{
		///
		final @property void menu(MainMenu menu) // setter
		{
			if(isHandleCreated)
			{
				HWND hwnd;
				hwnd = handle;
				
				if(menu)
				{
					SetMenu(hwnd, menu.handle);
					menu._setHwnd(hwnd);
				}
				else
				{
					SetMenu(hwnd, HMENU.init);
				}
				
				if(wmenu)
					wmenu._setHwnd(HWND.init);
				wmenu = menu;
				
				DrawMenuBar(hwnd);
			}
			else
			{
				wmenu = menu;
				_recalcClientSize();
			}
		}
		
		/// ditto
		final @property MainMenu menu() // getter
		{
			return wmenu;
		}
		
		
		/+
		///
		final @property MainMenu mergedMenu() // getter
		{
			// Return menu belonging to active MDI child if maximized ?
		}
		+/
	}
	
	
	///
	final @property void minimumSize(Size min) // setter
	{
		if(!min.width && !min.height)
		{
			minsz.width = 0;
			minsz.height = 0;
			return;
		}
		
		if(maxsz.width && maxsz.height)
		{
			if(min.width > maxsz.width || min.height > maxsz.height)
				throw new DflException("Minimum size cannot be bigger than maximum size");
		}
		
		minsz = min;
		
		bool ischangesz = false;
		Size changesz;
		changesz = size;
		
		if(width < min.width)
		{
			changesz.width = min.width;
			ischangesz = true;
		}
		if(height < min.height)
		{
			changesz.height = min.height;
			ischangesz = true;
		}
		
		if(ischangesz)
			size = changesz;
	}
	
	/// ditto
	final @property Size minimumSize() // getter
	{
		return minsz;
	}
	
	
	///
	final @property void maximumSize(Size max) // setter
	{
		if(!max.width && !max.height)
		{
			maxsz.width = 0;
			maxsz.height = 0;
			return;
		}
		
		//if(minsz.width && minsz.height)
		{
			if(max.width < minsz.width || max.height < minsz.height)
				throw new DflException("Maximum size cannot be smaller than minimum size");
		}
		
		maxsz = max;
		
		bool ischangesz = false;
		Size changesz;
		changesz = size;
		
		if(width > max.width)
		{
			changesz.width = max.width;
			ischangesz = true;
		}
		if(height > max.height)
		{
			changesz.height = max.height;
			ischangesz = true;
		}
		
		if(ischangesz)
			size = changesz;
	}
	
	/// ditto
	final @property Size maximumSize() // getter
	{
		return maxsz;
	}
	
	
	///
	final @property bool modal() // getter
	{
		return wmodal;
	}
	
	
	///
	// If opacity and transparency are supported.
	static @property bool supportsOpacity() // getter
	{
		return setLayeredWindowAttributes != null;
	}
	
	
	private static BYTE opacityToAlpha(double opa)
	{
		return cast(BYTE)(opa * BYTE.max);
	}
	
	
	///
	// 1.0 is 100%, 0.0 is 0%, 0.75 is 75%.
	// Does nothing if not supported.
	final @property void opacity(double opa) // setter
	{
		if(setLayeredWindowAttributes)
		{
			BYTE alpha;
			
			if(opa >= 1.0)
			{
				this.opa = 1.0;
				alpha = BYTE.max;
			}
			else if(opa <= 0.0)
			{
				this.opa = 0.0;
				alpha = BYTE.min;
			}
			else
			{
				this.opa = opa;
				alpha = opacityToAlpha(opa);
			}
			
			if(alpha == BYTE.max) // Disable
			{
				if(transKey == Color.empty)
					_exStyle(_exStyle() & ~WS_EX_LAYERED);
				else
					setLayeredWindowAttributes(handle, transKey.toRgb(), 0, LWA_COLORKEY);
			}
			else
			{
				_exStyle(_exStyle() | WS_EX_LAYERED);
				if(isHandleCreated)
				{
					//_exStyle(_exStyle() | WS_EX_LAYERED);
					if(transKey == Color.empty)
						setLayeredWindowAttributes(handle, 0, alpha, LWA_ALPHA);
					else
						setLayeredWindowAttributes(handle, transKey.toRgb(), alpha, LWA_ALPHA | LWA_COLORKEY);
				}
			}
		}
	}
	
	/// ditto
	final @property double opacity() // getter
	{
		return opa;
	}
	
	
	/+
	///
	final @property Form[] ownedForms() // getter
	{
		// TODO: implement.
	}
	+/
	
	
	// the "old owner" is the current -wowner- or -wmdiparent-.
	// If neither are set, nothing happens.
	private void _removeFromOldOwner()
	{
		int idx;
		
		if(wmdiparent)
		{
			idx = findIsIndex!(Form)(wmdiparent._mdiChildren, this);
			if(-1 != idx)
				wmdiparent._mdiChildren = removeIndex!(Form)(wmdiparent._mdiChildren, idx);
			//else
			//	assert(0);
		}
		else if(wowner)
		{
			idx = findIsIndex!(Form)(wowner._owned, this);
			if(-1 != idx)
				wowner._owned = removeIndex!(Form)(wowner._owned, idx);
			//else
			//	assert(0);
		}
	}
	
	
	///
	final @property void owner(Form frm) // setter
	/+out
	{
		if(frm)
		{
			bool found = false;
			foreach(Form elem; frm._owned)
			{
				if(elem is this)
				{
					found = true;
					break;
				}
			}
			assert(found);
		}
	}+/
	body
	{
		if(wowner is frm)
			return;
		
		// Remove from old owner.
		_removeFromOldOwner();
		wmdiparent = null;
		wowner = null; // Safety in case of exception.
		_exStyle(_exStyle() & ~WS_EX_MDICHILD);
		_style((_style() | WS_POPUP) & ~WS_CHILD);
		
		// Add to new owner.
		if(frm)
		{
			if(isHandleCreated)
			{
				frm.createControl(); // ?
			}
			
			// Copy so that old ownedForms arrays won't get overwritten.
			Form[] _thisa = new Form[1]; // DMD 0.123: this can't be a static array or the append screws up.
			_thisa[0] = this;
			frm._owned = frm._owned ~ _thisa;
			
			wowner = frm;
			if(isHandleCreated)
			{
				if(CCompat.DFL095 == _compat)
					SetParent(hwnd, frm.hwnd);
				else
					_crecreate();
			}
		}
		else
		{
			if(isHandleCreated)
			{
				if(showInTaskbar || CCompat.DFL095 == _compat)
					SetParent(hwnd, HWND.init);
				else
					_crecreate();
			}
		}
		
		//wowner = frm;
	}
	
	/// ditto
	final @property Form owner() // getter
	{
		return wowner;
	}
	
	
	///
	// This function does not work in all cases.
	final @property void showInTaskbar(bool byes) // setter
	{
		if(isHandleCreated)
		{
			bool vis;
			vis = visible;
			
			if(vis)
			{
				//hide();
				// Do it directly so that DFL code can't prevent it.
				cbits |= CBits.RECREATING;
				doHide();
			}
			scope(exit)
				cbits &= ~CBits.RECREATING;
			
			if(byes)
			{
				_exStyle(_exStyle() | WS_EX_APPWINDOW);
				
				version(DFL_PARK_WINDOW)
				{
					if(_hwPark && GetParent(handle) == _hwPark)
						SetParent(handle, HWND.init);
				}
			}
			else
			{
				_exStyle(_exStyle() & ~WS_EX_APPWINDOW);
				
				version(DFL_PARK_WINDOW)
				{
					/+ // Not working, the form disappears (probably stuck as a child).
					if(!GetParent(handle))
					{
						//_style((_style() | WS_POPUP) & ~WS_CHILD);
						
						SetParent(handle, getParkHwnd());
					}
					+/
					_crecreate();
				}
			}
			
			if(vis)
			{
				//show();
				// Do it directly so that DFL code can't prevent it.
				doShow();
			}
		}
		else
		{
			if(byes)
				wexstyle |= WS_EX_APPWINDOW;
			else
				wexstyle &= ~WS_EX_APPWINDOW;
		}
	}
	
	/// ditto
	final @property bool showInTaskbar() // getter
	{
		return (_exStyle() & WS_EX_APPWINDOW) != 0;
	}
	
	
	///
	final @property void sizingGrip(bool byes) // setter
	{
		if(grip == byes)
			return;
		
		this.grip = byes;
		
		if(isHandleCreated)
		{
			RECT rect;
			_getSizeGripArea(&rect);
			
			InvalidateRect(hwnd, &rect, TRUE);
		}
	}
	
	/// ditto
	final @property bool sizingGrip() // getter
	{
		return grip;
	}
	
	deprecated alias sizingGrip sizeGrip;
	
	
	///
	final @property void startPosition(FormStartPosition startpos) // setter
	{
		this.startpos = startpos;
	}
	
	/// ditto
	final @property FormStartPosition startPosition() // getter
	{
		return startpos;
	}
	
	
	///
	final @property void topMost(bool byes) // setter
	{
		/+
		if(byes)
			_exStyle(_exStyle() | WS_EX_TOPMOST);
		else
			_exStyle(_exStyle() & ~WS_EX_TOPMOST);
		+/
		
		if(isHandleCreated)
		{
			SetWindowPos(handle, byes ? HWND_TOPMOST : HWND_NOTOPMOST, 0, 0, 0, 0, SWP_NOMOVE | SWP_NOSIZE);
		}
		else
		{
			if(byes)
				wexstyle |= WS_EX_TOPMOST;
			else
				wexstyle &= ~WS_EX_TOPMOST;
		}
	}
	
	/// ditto
	final @property bool topMost() // getter
	{
		return (_exStyle() & WS_EX_TOPMOST) != 0;
	}
	
	
	///
	final @property void transparencyKey(Color c) // setter
	{
		if(setLayeredWindowAttributes)
		{
			transKey = c;
			BYTE alpha = opacityToAlpha(opa);
			
			if(c == Color.empty) // Disable
			{
				if(alpha == BYTE.max)
					_exStyle(_exStyle() & ~WS_EX_LAYERED);
				else
					setLayeredWindowAttributes(handle, 0, alpha, LWA_ALPHA);
			}
			else
			{
				_exStyle(_exStyle() | WS_EX_LAYERED);
				if(isHandleCreated)
				{
					//_exStyle(_exStyle() | WS_EX_LAYERED);
					if(alpha == BYTE.max)
						setLayeredWindowAttributes(handle, c.toRgb(), 0, LWA_COLORKEY);
					else
						setLayeredWindowAttributes(handle, c.toRgb(), alpha, LWA_COLORKEY | LWA_ALPHA);
				}
			}
		}
	}
	
	/// ditto
	final @property Color transparencyKey() // getter
	{
		return transKey;
	}
	
	
	///
	final @property void windowState(FormWindowState state) // setter
	{
		// Not sure if visible should be checked here..
		if(isHandleCreated && visible)
		{
			final switch(state)
			{
				case FormWindowState.MAXIMIZED:
					ShowWindow(handle, SW_MAXIMIZE);
					//wstyle = wstyle & ~WS_MINIMIZE | WS_MAXIMIZE;
					break;
				
				case FormWindowState.MINIMIZED:
					ShowWindow(handle, SW_MINIMIZE);
					//wstyle = wstyle | WS_MINIMIZE & ~WS_MAXIMIZE;
					break;
				
				case FormWindowState.NORMAL:
					ShowWindow(handle, SW_RESTORE);
					//wstyle = wstyle & ~(WS_MINIMIZE | WS_MAXIMIZE);
					break;
			}
			//wstyle = GetWindowLongA(hwnd, GWL_STYLE);
		}
		else
		{
			final switch(state)
			{
				case FormWindowState.MAXIMIZED:
					_style(_style() & ~WS_MINIMIZE | WS_MAXIMIZE);
					break;
				
				case FormWindowState.MINIMIZED:
					_style(_style() | WS_MINIMIZE & ~WS_MAXIMIZE);
					break;
				
				case FormWindowState.NORMAL:
					_style(_style() & ~(WS_MINIMIZE | WS_MAXIMIZE));
					break;
			}
		}
	}
	
	/// ditto
	final @property FormWindowState windowState() // getter
	{
		LONG wl;
		//wl = wstyle = GetWindowLongA(hwnd, GWL_STYLE);
		wl = _style();
		
		if(wl & WS_MAXIMIZE)
			return FormWindowState.MAXIMIZED;
		else if(wl & WS_MINIMIZE)
			return FormWindowState.MINIMIZED;
		else
			return FormWindowState.NORMAL;
	}
	
	
	protected override void setVisibleCore(bool byes)
	{
		if(isHandleCreated)
		{
			if(visible == byes)
				return;
			
			version(OLD_MODAL_CLOSE)
			{
				if(!wmodal)
				{
					if(byes)
					{
						cbits &= ~CBits.NOCLOSING;
					}
				}
			}
			
			//if(!visible)
			if(byes)
			{
				version(DFL_NO_ZOMBIE_FORM)
				{
				}
				else
				{
					nozombie();
				}
				
				if(wstyle & WS_MAXIMIZE)
				{
					ShowWindow(hwnd, SW_MAXIMIZE);
					cbits |= CBits.VISIBLE; // ?
					wstyle |= WS_VISIBLE; // ?
					onVisibleChanged(EventArgs.empty);
					return;
				}
				/+else if(wstyle & WS_MINIMIZE)
				{
					ShowWindow(handle, SW_MINIMIZE);
					onVisibleChanged(EventArgs.empty);
					cbits |= CBits.VISIBLE; // ?
					wstyle |= WS_VISIBLE; // ?
					return;
				}+/
			}
		}
		
		return super.setVisibleCore(byes);
	}
	
	
	protected override void onVisibleChanged(EventArgs ea)
	{
		version(OLD_MODAL_CLOSE)
		{
			if(!wmodal)
			{
				if(visible)
				{
					cbits &= ~CBits.NOCLOSING;
				}
			}
		}
		
		if(!(Application._compat & DflCompat.FORM_LOAD_096))
		{
			if(visible)
			{
				if(!(cbits & CBits.FORMLOADED))
				{
					cbits |= CBits.FORMLOADED;
					onLoad(EventArgs.empty);
				}
			}
		}
		
		// Ensure Control.onVisibleChanged is called AFTER onLoad, so onLoad can set the selection first.
		super.onVisibleChanged(ea);
	}
	
	
	///
	final void activate()
	{
		if(!isHandleCreated)
			return;
		
		//if(!visible)
		//	show(); // ?
		
		version(NO_MDI)
		{
		}
		else
		{
			if(isMdiChild)
			{
				// Good, make sure client window proc handles it too.
				SendMessageA(mdiParent.mdiClient.handle, WM_MDIACTIVATE, cast(WPARAM)handle, 0);
				return;
			}
		}
		
		//SetActiveWindow(handle);
		SetForegroundWindow(handle);
	}
	
	
	override void destroyHandle()
	{
		if(!isHandleCreated)
			return;
		
		if(isMdiChild)
			DefMDIChildProcA(hwnd, WM_CLOSE, 0, 0);
		DestroyWindow(hwnd);
	}
	
	
	///
	final void close()
	{
		if(wmodal)
		{
			/+
			if(DialogResult.NONE == fresult)
			{
				fresult = DialogResult.CANCEL;
			}
			+/
			
			version(OLD_MODAL_CLOSE)
			{
				cbits |= CBits.NOCLOSING;
				//doHide();
				setVisibleCore(false);
				//if(!visible)
				if(!wmodal)
					onClosed(EventArgs.empty);
			}
			else
			{
				scope CancelEventArgs cea = new CancelEventArgs;
				onClosing(cea);
				if(!cea.cancel)
				{
					wmodal = false; // Must be false or will result in recursion.
					destroyHandle();
				}
			}
			return;
		}
		
		scope CancelEventArgs cea = new CancelEventArgs;
		onClosing(cea);
		if(!cea.cancel)
		{
			//destroyHandle();
			dispose();
		}
	}
	
	
	///
	final void layoutMdi(MdiLayout lay)
	{
		final switch(lay)
		{
			case MdiLayout.ARRANGE_ICONS:
				SendMessageA(handle, WM_MDIICONARRANGE, 0, 0);
				break;
			
			case MdiLayout.CASCADE:
				SendMessageA(handle, WM_MDICASCADE, 0, 0);
				break;
			
			case MdiLayout.TILE_HORIZONTAL:
				SendMessageA(handle, WM_MDITILE, MDITILE_HORIZONTAL, 0);
				break;
			
			case MdiLayout.TILE_VERTICAL:
				SendMessageA(handle, WM_MDITILE, MDITILE_VERTICAL, 0);
				break;
		}
	}
	
	
	///
	final void setDesktopBounds(int x, int y, int width, int height)
	{
		desktopBounds = Rect(x, y, width, height);
	}
	
	
	///
	final void setDesktopLocation(int x, int y)
	{
		desktopLocation = Point(x, y);
	}
	
	
	///
	final DialogResult showDialog()
	{
		// Use active window as the owner.
		this.sowner = GetActiveWindow();
		if(this.sowner == this.hwnd) // Possible due to fast flash?
			this.sowner = HWND.init;
		showDialog2();
		return fresult;
	}
	
	/// ditto
	final DialogResult showDialog(IWindow iwsowner)
	{
		//this.sowner = iwsowner ? iwsowner.handle : GetActiveWindow();
		if(!iwsowner)
			return showDialog();
		this.sowner = iwsowner.handle;
		showDialog2();
		return fresult;
	}
	
	
	// Used internally.
	package final void showDialog2()
	{
		version(DFL_NO_ZOMBIE_FORM)
		{
		}
		else
		{
			nozombie();
		}
		
		LONG wl = _style();
		sownerEnabled = false;
		
		if(wl & WS_DISABLED)
		{
			debug
			{
				throw new DflException("Unable to show dialog because it is disabled");
			}
			no_show:
			throw new DflException("Unable to show dialog");
		}
		
		if(isHandleCreated)
		{
			//if(wl & WS_VISIBLE)
			if(visible)
			{
				if(!wmodal && owner && sowner == owner.handle)
				{
				}
				else
				{
					debug
					{
						throw new DflException("Unable to show dialog because it is already visible");
					}
					else
					{
						goto no_show;
					}
				}
			}
			
			if(sowner == hwnd)
			{
				bad_owner:
				debug
				{
					throw new DflException("Invalid dialog owner");
				}
				else
				{
					goto no_show;
				}
			}
			
			//owner = null;
			//_exStyle(_exStyle() & ~WS_EX_MDICHILD);
			//_style((_style() | WS_POPUP) & ~WS_CHILD);
			//SetParent(hwnd, sowner);
		}
		
		try
		{
			if(sowner)
			{
				LONG owl = GetWindowLongA(sowner, GWL_STYLE);
				if(owl & WS_CHILD)
					goto bad_owner;
				
				wowner = cast(Form)fromHandle(sowner);
				
				if(!(owl & WS_DISABLED))
				{
					sownerEnabled = true;
					EnableWindow(sowner, false);
				}
			}
			
			show();
			
			wmodal = true;
			for(;;)
			{
				if(!Application.doEvents())
				{
					wmodal = false;
					//dialogResult = DialogResult.ABORT; // ?
					// Leave it at DialogResult.NONE ?
					break;
				}
				if(!wmodal)
					break;
				/+
				//assert(visible);
				if(!visible)
				{
					wmodal = false;
					break;
				}
				+/
				Application.waitForEvent();
			}
		}
		finally
		{
			if(sownerEnabled)
			{
				EnableWindow(sowner, true); // In case of exception.
				SetActiveWindow(sowner);
				//SetFocus(sowner);
			}
			
			//if(!wmodal)
			//	DestroyWindow(hwnd);
			
			wmodal = false;
			sowner = HWND.init;
			
			//hide();
			// Do it directly so that DFL code can't prevent it.
			doHide();
			
			version(DFL_NO_ZOMBIE_FORM)
			{
			}
			else
			{
				Application.doEvents();
				Application.zombieHwnd(this); // Zombie; allows this to be GC'd but keep state until then.
			}
		}
	}
	
	
	version(DFL_NO_ZOMBIE_FORM)
	{
	}
	else
	{
		package final bool nozombie()
		{
			if(this.hwnd)
			{
				if(!Application.lookupHwnd(this.hwnd))
				{
					// Zombie!
					Application.unzombieHwnd(this);
					return true;
				}
			}
			return false;
		}
	}
	
	
	//EventHandler activated;
	Event!(Form, EventArgs) activated; ///
	//EventHandler deactivate;
	Event!(Form, EventArgs) deactivate; ///
	//EventHandler closed;
	Event!(Form, EventArgs) closed; ///
	//CancelEventHandler closing;
	Event!(Form, CancelEventArgs) closing; ///
	//EventHandler load;
	Event!(Form, EventArgs) load; ///
	
	
	///
	protected void onActivated(EventArgs ea)
	{
		activated(this, ea);
	}
	
	
	///
	protected void onDeactivate(EventArgs ea)
	{
		deactivate(this, ea);
	}
	
	
	/+
	///
	protected void onInputLanguageChanged(InputLanguageChangedEventArgs ilcea)
	{
		inputLanguageChanged(this, ilcea);
	}
	
	
	///
	protected void onInputLanguageChanging(InputLanguageChangingEventArgs ilcea)
	{
		inputLanguageChanging(this, ilcea);
	}
	+/
	
	
	///
	protected void onLoad(EventArgs ea)
	{
		load(this, ea);
		
		if(!(Application._compat & DflCompat.FORM_LOAD_096))
		{
			// Needed anyway because MDI client form needs it.
			HWND hwfocus = GetFocus();
			if(!hwfocus || !IsChild(hwnd, hwfocus))
				_selectNextControl(this, null, true, true, true, false);
		}
	}
	
	
	private void _init()
	{
		_recalcClientSize();
		
		//wicon = new Icon(LoadIconA(HINSTANCE.init, IDI_APPLICATION), false);
		wicon = SystemIcons.application;
		transKey = Color.empty;
	}
	
	
	this()
	{
		super();
		
		mfilter = new FormMessageFilter(this);
		
		// Default border: FormBorderStyle.SIZABLE.
		// Default visible: false.
		wstyle = WS_OVERLAPPEDWINDOW | WS_CLIPCHILDREN | WS_CLIPSIBLINGS;
		wexstyle = /+ WS_EX_CONTROLPARENT | +/ WS_EX_WINDOWEDGE | WS_EX_APPWINDOW;
		cbits |= CBits.FORM;
		
		_init();
	}
	
	
	/+
	// Used internally.
	this(HWND hwnd)
	{
		super(hwnd);
		_init();
	}
	+/
	
	
	protected override void wndProc(ref Message msg)
	{
		switch(msg.msg)
		{
			case WM_COMMAND:
				// Don't let Control handle the WM_COMMAND if it's a default or cancel button;
				// otherwise, the events will be fired twice.
				switch(LOWORD(msg.wParam))
				{
					case IDOK:
						if(acceptBtn)
						{
							if(HIWORD(msg.wParam) == BN_CLICKED)
								acceptBtn.performClick();
							return;
						}
						break;
						//return;
					
					case IDCANCEL:
						if(cancelBtn)
						{
							if(HIWORD(msg.wParam) == BN_CLICKED)
								cancelBtn.performClick();
							return;
						}
						break;
						//return;
					
					default:
				}
				break;
			
			//case WM_CREATE: // WM_NCCREATE seems like a better choice.
			case WM_NCCREATE:
				// Make sure Windows doesn't magically change the styles.
				SetWindowLongA(hwnd, GWL_EXSTYLE, wexstyle);
				SetWindowLongA(hwnd, GWL_STYLE, wstyle & ~WS_VISIBLE);
				
				SetWindowPos(hwnd, HWND.init, 0, 0, 0, 0, SWP_FRAMECHANGED | SWP_NOMOVE
					| SWP_NOSIZE | SWP_NOZORDER | SWP_NOACTIVATE); // Recalculate the frame.
				
				_setSystemMenu();
				break;
			
			case WM_WINDOWPOSCHANGING:
				{
					WINDOWPOS* wp = cast(WINDOWPOS*)msg.lParam;
					
					if(wp.flags & SWP_HIDEWINDOW)
					{
						if(wmodal)
						{
							version(OLD_MODAL_CLOSE)
							{
								scope CancelEventArgs cea = new CancelEventArgs;
								onClosing(cea);
								if(cea.cancel)
								{
									wp.flags &= ~SWP_HIDEWINDOW; // Cancel.
								}
							}
							else
							{
								wp.flags &= ~SWP_HIDEWINDOW; // Don't hide because we're destroying or canceling.
								close();
							}
						}
					}
					
					version(DFL_NO_ZOMBIE_FORM)
					{
					}
					else
					{
						if(wp.flags & SWP_SHOWWINDOW)
						{
							nozombie();
						}
					}
				}
				break;
			
			case WM_CLOSE:
				if(!recreatingHandle)
				{
					// Check for this first because defWndProc() will destroy the window.
					/+ // Moved to close().
					// version(OLD_MODAL_CLOSE) ...
					fresult = DialogResult.CANCEL;
					if(wmodal)
					{
						doHide();
					}
					else+/
					{
						close();
					}
				}
				return;
			
			default:
		}
		
		super.wndProc(msg);
		
		switch(msg.msg)
		{
			case WM_NCHITTEST:
				//if(msg.result == HTCLIENT || msg.result == HTBORDER)
				if(msg.result != HTNOWHERE && msg.result != HTERROR)
				{
					if(_isPaintingSizeGrip())
					{
						RECT rect;
						_getSizeGripArea(&rect);
						
						Point pt;
						pt.x = LOWORD(msg.lParam);
						pt.y = HIWORD(msg.lParam);
						pt = pointToClient(pt);
						
						if(pt.x >= rect.left && pt.y >= rect.top)
							msg.result = HTBOTTOMRIGHT;
					}
				}
				break;
			
			case WM_ACTIVATE:
				switch(LOWORD(msg.wParam))
				{
					case WA_ACTIVE:
					case WA_CLICKACTIVE:
						onActivated(EventArgs.empty);
						break;
					
					case WA_INACTIVE:
						onDeactivate(EventArgs.empty);
						break;
					
					default:
				}
				break;
			
			case WM_WINDOWPOSCHANGING:
				{
					WINDOWPOS* wp = cast(WINDOWPOS*)msg.lParam;
					
					/+ // Moved to WM_GETMINMAXINFO.
					if(minsz.width && minsz.height)
					{
						if(wp.cx < minsz.width)
							wp.cx = minsz.width;
						if(wp.cy < minsz.height)
							wp.cy = minsz.height;
					}
					if(maxsz.width && maxsz.height)
					{
						if(wp.cx > minsz.width)
							wp.cx = minsz.width;
						if(wp.cy > minsz.height)
							wp.cy = minsz.height;
					}
					+/
					
					/+
					if(_closingvisible)
					{
						wp.flags &= ~SWP_HIDEWINDOW;
					}
					+/
					
					if(!(wp.flags & SWP_NOSIZE))
					{
						if(_isPaintingSizeGrip())
						{
							// This comparison is needed to prevent some painting glitches
							// when moving the window...
							if(width != wp.cx || height != wp.cy)
							{
								RECT rect;
								_getSizeGripArea(&rect);
								InvalidateRect(hwnd, &rect, TRUE);
							}
						}
					}
					
					if(wp.flags & SWP_HIDEWINDOW)
					{
						if(sownerEnabled)
						{
							EnableWindow(sowner, true);
							SetActiveWindow(sowner);
							//SetFocus(sowner);
						}
						
						wmodal = false;
					}
				}
				break;
			
			case WM_GETMINMAXINFO:
				{
					super.wndProc(msg);
					
					MINMAXINFO* mmi;
					mmi = cast(MINMAXINFO*)msg.lParam;
					
					if(minsz.width && minsz.height)
					{
						if(mmi.ptMinTrackSize.x < minsz.width)
							mmi.ptMinTrackSize.x = minsz.width;
						if(mmi.ptMinTrackSize.y < minsz.height)
							mmi.ptMinTrackSize.y = minsz.height;
					}
					if(maxsz.width && maxsz.height)
					{
						if(mmi.ptMaxTrackSize.x > maxsz.width)
							mmi.ptMaxTrackSize.x = maxsz.width;
						if(mmi.ptMaxTrackSize.y > maxsz.height)
							mmi.ptMaxTrackSize.y = maxsz.height;
					}
					
					// Do this again so that the user's preference isn't
					// outside the Windows valid min/max bounds.
					super.wndProc(msg);
				}
				return;
			
			case WM_DESTROY:
				/+
				if(_closingvisible)
				{
					assert(wstyle & WS_VISIBLE);
				}
				+/
				if(!recreatingHandle)
				{
					if(!(cbits & CBits.NOCLOSING))
					{
						onClosed(EventArgs.empty);
					}
				}
				break;
			
			default:
		}
	}
	
	
	package final void _setSystemMenu()
	{
		HMENU hwm;
		assert(isHandleCreated);
		hwm = GetSystemMenu(handle, FALSE);
		
		switch(formBorderStyle)
		{
			case FormBorderStyle.FIXED_3D:
			case FormBorderStyle.FIXED_SINGLE:
			case FormBorderStyle.FIXED_DIALOG:
			case FormBorderStyle.FIXED_TOOLWINDOW:
				// Fall through.
			case FormBorderStyle.NONE:
				RemoveMenu(hwm, SC_SIZE, MF_BYCOMMAND);
				RemoveMenu(hwm, SC_MAXIMIZE, MF_BYCOMMAND);
				//RemoveMenu(hwm, SC_MINIMIZE, MF_BYCOMMAND);
				RemoveMenu(hwm, SC_RESTORE, MF_BYCOMMAND);
				break;
			
			//case FormBorderStyle.SIZABLE:
			//case FormBorderStyle.SIZABLE_TOOLWINDOW:
			default:
		}
		
		if(!maximizeBox)
		{
			RemoveMenu(hwm, SC_MAXIMIZE, MF_BYCOMMAND);
		}
		if(!minimizeBox)
		{
			RemoveMenu(hwm, SC_MINIMIZE, MF_BYCOMMAND);
		}
	}
	
	
	package final void _resetSystemMenu()
	{
		assert(isHandleCreated);
		GetSystemMenu(handle, TRUE); // Reset.
		_setSystemMenu();
	}
	
	
	/+ package +/ override void _destroying() // package
	{
		_removeFromOldOwner();
		//wowner = null;
		wmdiparent = null;
		
		Application.removeMessageFilter(mfilter);
		//mfilter = null;
		
		version(DFL_NO_MENUS)
		{
		}
		else
		{
			if(wmenu)
				wmenu._setHwnd(HWND.init);
		}
		
		super._destroying();
	}
	
	
	/+ package +/ /+ protected +/ override int _rtype() // package
	{
		return isMdiChild ? 2 : 0;
	}
	
	
	package BOOL _isNonMdiChild(HWND hw)
	{
		assert(isHandleCreated);
		
		if(!hw || hw == this.hwnd)
			return false;
		
		if(IsChild(this.hwnd, hw))
		{
			version(NO_MDI)
			{
			}
			else
			{
				if(mdiClient && mdiClient.isHandleCreated)
				{
					if(IsChild(mdiClient.hwnd, hw))
						return false; // !
				}
			}
			return true;
		}
		return false;
	}
	
	
	package HWND _lastSelBtn; // Last selected button (not necessarily focused), excluding accept button!
	package HWND _lastSel; // Last senected and focused control.
	package HWND _hadfocus; // Before being deactivated.
	
	
	// Returns if there was a selection.
	package final bool _selbefore()
	{
		bool wasselbtn = false;
		if(_lastSelBtn)
		{
			wasselbtn = true;
			//if(IsChild(this.hwnd, _lastSelBtn))
			if(_isNonMdiChild(_lastSelBtn))
			{
				auto lastctrl = Control.fromHandle(_lastSelBtn);
				if(lastctrl)
				{
					auto lastibc = cast(IButtonControl)lastctrl;
					if(lastibc)
						lastibc.notifyDefault(false);
				}
			}
		}
		return wasselbtn;
	}
	
	package final void _selafter(Control ctrl, bool wasselbtn)
	{
		_lastSelBtn = _lastSelBtn.init;
		auto ibc = cast(IButtonControl)ctrl;
		if(ibc)
		{
			if(acceptButton)
			{
				if(ibc !is acceptButton)
				{
					acceptButton.notifyDefault(false);
					_lastSelBtn = ctrl.hwnd;
				}
				//else don't set _lastSelBtn to accept button.
			}
			else
			{
				_lastSelBtn = ctrl.hwnd;
			}
			
			ibc.notifyDefault(true);
		}
		else
		{
			if(wasselbtn) // Only do it if there was a different button; don't keep doing this.
			{
				if(acceptButton)
					acceptButton.notifyDefault(true);
			}
		}
	}
	
	package final void _seldeactivate()
	{
		if(!_selbefore())
		{
			if(acceptButton)
				acceptButton.notifyDefault(false);
		}
		//_lastSel = GetFocus(); // Not reliable, especially when minimizing.
	}
	
	package final void _selactivate()
	{
		if(_lastSel && _isNonMdiChild(_lastSel))
		{
			Control ctrl = Control.fromChildHandle(_lastSel);
			if(ctrl && ctrl._hasSelStyle())
			{
				auto ibc = cast(IButtonControl)ctrl;
				if(ibc)
				{
					//ibc.notifyDefault(true);
					ctrl.select();
					return;
				}
				ctrl.select();
			}
			else
			{
				SetFocus(ctrl.hwnd);
			}
		}
		if(acceptButton)
		{
			acceptButton.notifyDefault(true);
		}
	}
	
	// Child can be nested at any level.
	package final void _selectChild(Control ctrl)
	{
		if(ctrl.canSelect)
		{
			bool wasselbtn = _selbefore();
			
			// Need to do some things, like select-all for edit.
			DefDlgProcA(this.hwnd, WM_NEXTDLGCTL, cast(WPARAM)ctrl.hwnd, MAKELPARAM(true, 0));
			
			_selafter(ctrl, wasselbtn);
			
			_lastSel = ctrl.hwnd;
		}
	}
	
	package final void _selectChild(HWND hw)
	{
		Control ctrl = Control.fromHandle(hw);
		if(ctrl)
			_selectChild(ctrl);
	}
	
	
	private void _selonecontrol()
	{
		HWND hwfocus = GetFocus();
		if(!hwfocus || hwfocus == hwnd)
		{
			_selectNextControl(this, null, true, true, true, false);
			if(!GetFocus())
				select();
		}
	}
	
	
	package alias dfl.internal.utf.defDlgProc _defFormProc;
	
	protected override void defWndProc(ref Message msg)
	{
		switch(msg.msg)
		{
			/+
			// Not handled by defWndProc() anymore..
			
			case WM_PAINT:
			case WM_PRINT:
			case WM_PRINTCLIENT:
			case WM_ERASEBKGND:
				// DefDlgProc() doesn't let you use a custom background
				// color, so call the default window proc instead.
				super.defWndProc(msg);
				break;
			+/
			
			case WM_SETFOCUS:
				/+
				{
					bool didf = false;
					enumChildWindows(msg.hWnd,
						(HWND hw)
						{
							auto wl = GetWindowLongA(hw, GWL_STYLE);
							if(((WS_VISIBLE | WS_TABSTOP) == ((WS_VISIBLE | WS_TABSTOP) & wl))
								&& !(WS_DISABLED & wl))
							{
								DefDlgProcA(msg.hWnd, WM_NEXTDLGCTL, cast(WPARAM)hw, MAKELPARAM(true, 0));
								didf = true;
								return FALSE;
							}
							return TRUE;
						});
					if(!didf)
						SetFocus(msg.hWnd);
				}
				+/
				//_selonecontrol();
				
				version(NO_MDI)
				{
				}
				else
				{
					if(isMdiChild)
					{
						// ?
						//msg.result = DefMDIChildProcA(msg.hWnd, msg.msg, msg.wParam, msg.lParam);
						msg.result = dfl.internal.utf.defMDIChildProc(msg.hWnd, msg.msg, msg.wParam, msg.lParam);
						return;
					}
				}
				
				// Prevent DefDlgProc from getting this message because it'll focus controls it shouldn't.
				return;
			
			case WM_NEXTDLGCTL:
				if(LOWORD(msg.lParam))
				{
					_selectChild(cast(HWND)msg.wParam);
				}
				else
				{
					_dlgselnext(this, GetFocus(), msg.wParam != 0);
				}
				return;
			
			case WM_ENABLE:
				if(msg.wParam)
				{
					if(GetActiveWindow() == msg.hWnd)
					{
						_selonecontrol();
					}
				}
				break;
			
			case WM_ACTIVATE:
				switch(LOWORD(msg.wParam))
				{
					case WA_ACTIVE:
					case WA_CLICKACTIVE:
						_selactivate();
						
						/+
						version(NO_MDI)
						{
						}
						else
						{
							if(isMdiContainer)
							{
								auto amc = getActiveMdiChild();
								if(amc)
									amc._selactivate();
							}
						}
						+/
						break;
					
					case WA_INACTIVE:
						/+
						version(NO_MDI)
						{
						}
						else
						{
							if(isMdiContainer)
							{
								auto amc = getActiveMdiChild();
								if(amc)
									amc._seldeactivate();
							}
						}
						+/
						
						_seldeactivate();
						break;
					
					default:
				}
				return;
			
			// Note: WM_MDIACTIVATE here is to the MDI child forms.
			case WM_MDIACTIVATE:
				if(cast(HWND)msg.lParam == hwnd)
				{
					_selactivate();
				}
				else if(cast(HWND)msg.wParam == hwnd)
				{
					_seldeactivate();
				}
				goto def_def;
			
			default: def_def:
				version(NO_MDI)
				{
					//msg.result = DefDlgProcA(msg.hWnd, msg.msg, msg.wParam, msg.lParam);
					msg.result = _defFormProc(msg.hWnd, msg.msg, msg.wParam, msg.lParam);
				}
				else
				{
					if(mdiClient && mdiClient.isHandleCreated && msg.msg != WM_SIZE)
						//msg.result = DefFrameProcA(msg.hWnd, mdiClient.handle, msg.msg, msg.wParam, msg.lParam);
						msg.result = dfl.internal.utf.defFrameProc(msg.hWnd, mdiClient.handle, msg.msg, msg.wParam, msg.lParam);
					else if(isMdiChild)
						//msg.result = DefMDIChildProcA(msg.hWnd, msg.msg, msg.wParam, msg.lParam);
						msg.result = dfl.internal.utf.defMDIChildProc(msg.hWnd, msg.msg, msg.wParam, msg.lParam);
					else
						//msg.result = DefDlgProcA(msg.hWnd, msg.msg, msg.wParam, msg.lParam);
						msg.result = _defFormProc(msg.hWnd, msg.msg, msg.wParam, msg.lParam);
				}
		}
	}
	
	
	protected:
	
	///
	void onClosing(CancelEventArgs cea)
	{
		closing(this, cea);
	}
	
	
	///
	void onClosed(EventArgs ea)
	{
		closed(this, ea);
	}
	
	
	override void setClientSizeCore(int width, int height)
	{
		RECT r;
		
		r.left = 0;
		r.top = 0;
		r.right = width;
		r.bottom = height;
		
		LONG wl = _style();
		version(DFL_NO_MENUS)
		{
			enum hasmenu = null;
		}
		else
		{
			auto hasmenu = wmenu;
		}
		AdjustWindowRectEx(&r, wl, !(wl & WS_CHILD) && hasmenu !is null, _exStyle());
		
		setBoundsCore(0, 0, r.right - r.left, r.bottom - r.top, BoundsSpecified.SIZE);
	}
	
	
	protected override void setBoundsCore(int x, int y, int width, int height, BoundsSpecified specified)
	{
		if(isHandleCreated)
		{
			super.setBoundsCore(x, y, width, height, specified);
		}
		else
		{
			if(specified & BoundsSpecified.X)
				wrect.x = x;
			if(specified & BoundsSpecified.Y)
				wrect.y = y;
			if(specified & BoundsSpecified.WIDTH)
			{
				if(width < 0)
					width = 0;
				
				wrect.width = width;
			}
			if(specified & BoundsSpecified.HEIGHT)
			{
				if(height < 0)
					height = 0;
				
				wrect.height = height;
			}
			
			_recalcClientSize();
		}
	}
	
	
	// Must be called before handle creation.
	protected final void noMessageFilter() // package
	{
		nofilter = true;
	}
	
	
	version(NO_MDI) {} else
	{
		protected final @property MdiClient mdiClient() // getter
		{ return _mdiClient; }
	}
	
	
	private:
	IButtonControl acceptBtn, cancelBtn;
	bool autoscale = true;
	Size autoscaleBase;
	DialogResult fresult = DialogResult.NONE;
	Icon wicon, wiconSm;
	version(DFL_NO_MENUS)
	{
	}
	else
	{
		MainMenu wmenu;
	}
	Size minsz, maxsz; // {0, 0} means none.
	bool wmodal = false;
	bool sownerEnabled;
	HWND sowner;
	double opa = 1.0; // Opacity.
	Color transKey;
	bool grip = false;
	FormStartPosition startpos = FormStartPosition.DEFAULT_LOCATION;
	FormMessageFilter mfilter;
	//const FormMessageFilter mfilter;
	bool _loaded = false;
	void delegate(Object sender, FormShortcutEventArgs ea)[Keys] _shortcuts;
	Form[] _owned, _mdiChildren; // Always set because they can be created and destroyed at any time.
	Form wowner = null, wmdiparent = null;
	//bool _closingvisible;
	bool nofilter = false;
	
	version(NO_MDI) {} else
	{
		MdiClient _mdiClient = null; // null == not MDI container.
	}
	
	
	package static bool wantsAllKeys(HWND hwnd)
	{
		return (SendMessageA(hwnd, WM_GETDLGCODE, 0, 0) &
			DLGC_WANTALLKEYS) != 0;
	}
	
	
	private static class FormMessageFilter: IMessageFilter
	{
		protected bool preFilterMessage(ref Message m)
		{
			version(NO_MDI)
				enum bool mdistuff = false;
			else
				bool mdistuff = form.mdiClient && form.mdiClient.isHandleCreated
					&& (form.mdiClient.handle == m.hWnd || IsChild(form.mdiClient.handle, m.hWnd));
			
			if(mdistuff)
			{
			}
			else if(m.hWnd == form.handle || IsChild(form.handle, m.hWnd))
			{
				{
					HWND hwfocus = GetFocus();
					// Don't need _isNonMdiChild here; mdistuff excludes MDI stuff.
					if(hwfocus != form._lastSel && IsChild(form.handle, hwfocus))
						form._lastSel = hwfocus; // ?
				}
				
				switch(m.msg)
				{
					// Process shortcut keys.
					// This should be better than TranslateAccelerator().
					case WM_SYSKEYDOWN:
					case WM_KEYDOWN:
						{
							void delegate(Object sender, FormShortcutEventArgs ea)* ppressed;
							Keys k;
							
							k = cast(Keys)m.wParam | Control.modifierKeys;
							ppressed = k in form._shortcuts;
							
							if(ppressed)
							{
								scope FormShortcutEventArgs ea = new FormShortcutEventArgs(k);
								(*ppressed)(form, ea);
								return true; // Prevent.
							}
						}
						break;
					
					default:
				}
				
				switch(m.msg)
				{
					case WM_KEYDOWN:
					case WM_KEYUP:
					case WM_CHAR:
						switch(cast(Keys)m.wParam)
						{
							case Keys.ENTER:
								if(form.acceptButton)
								{
									dfl.internal.utf.isDialogMessage(form.handle, &m._winMsg);
									return true; // Prevent.
								}
								return false;
							
							case Keys.ESCAPE:
								if(form.cancelButton)
								{
									//dfl.internal.utf.isDialogMessage(form.handle, &m._winMsg); // Closes the parent; bad for nested controls.
									if(m.hWnd == form.handle || IsChild(form.handle, m.hWnd))
									{
										if(WM_KEYDOWN == m.msg)
										{
											Message mesc;
											mesc.hWnd = form.handle;
											mesc.msg = WM_COMMAND;
											mesc.wParam = MAKEWPARAM(IDCANCEL, 0);
											//mesc.lParam = form.cancelButton.handle; // handle isn't here, isn't guaranteed to be, and doesn't matter.
											form.wndProc(mesc);
										}
										return true; // Prevent.
									}
								}
								return false;
							
							case Keys.UP, Keys.DOWN, Keys.RIGHT, Keys.LEFT:
								//if(dfl.internal.utf.isDialogMessage(form.handle, &m._winMsg)) // Stopped working after removing controlparent.
								//	return true; // Prevent.
								{
									LRESULT dlgc;
									dlgc = SendMessageA(m.hWnd, WM_GETDLGCODE, 0, 0);
									if(!(dlgc & (DLGC_WANTALLKEYS | DLGC_WANTARROWS)))
									{
										if(WM_KEYDOWN == m.msg)
										{
											switch(cast(Keys)m.wParam)
											{
												case Keys.UP, Keys.LEFT:
													// Backwards...
													Control._dlgselnext(form, m.hWnd, false, false, true);
													break;
												case Keys.DOWN, Keys.RIGHT:
													// Forwards...
													Control._dlgselnext(form, m.hWnd, true, false, true);
													break;
												default:
													assert(0);
											}
										}
										return true; // Prevent.
									}
								}
								return false; // Continue.
							
							case Keys.TAB:
								{
									LRESULT dlgc;
									Control cc;
									dlgc = SendMessageA(m.hWnd, WM_GETDLGCODE, 0, 0);
									cc = fromHandle(m.hWnd);
									if(cc)
									{
										if(cc._wantTabKey())
											return false; // Continue.
									}
									else
									{
										if(dlgc & DLGC_WANTALLKEYS)
											return false; // Continue.
									}
									//if(dlgc & (DLGC_WANTTAB | DLGC_WANTALLKEYS))
									if(dlgc & DLGC_WANTTAB)
										return false; // Continue.
									if(WM_KEYDOWN == m.msg)
									{
										if(GetKeyState(VK_SHIFT) & 0x8000)
										{
											// Backwards...
											//DefDlgProcA(form.handle, WM_NEXTDLGCTL, 1, MAKELPARAM(FALSE, 0));
											_dlgselnext(form, m.hWnd, false);
										}
										else
										{
											// Forwards...
											//DefDlgProcA(form.handle, WM_NEXTDLGCTL, 0, MAKELPARAM(FALSE, 0));
											_dlgselnext(form, m.hWnd, true);
										}
									}
								}
								return true; // Prevent.
							
							default:
						}
						break;
					
					case WM_SYSCHAR:
						{
							/+
							LRESULT dlgc;
							dlgc = SendMessageA(m.hWnd, WM_GETDLGCODE, 0, 0);
							/+ // Mnemonics bypass want-all-keys!
							if(dlgc & DLGC_WANTALLKEYS)
								return false; // Continue.
							+/
							+/
							
							bool pmnemonic(HWND hw)
							{
								Control cc = Control.fromHandle(hw);
								//cprintf("mnemonic for ");
								if(!cc)
								{
									// To-do: check dlgcode for static/button and process.
									return false;
								}
								//cprintf("'%.*s' ", cc.name);
								return cc._processMnemonic(cast(dchar)m.wParam);
							}
							
							bool foundmhw = false;
							bool foundmn = false;
							eachGoodChildHandle(form.handle,
								(HWND hw)
								{
									if(foundmhw)
									{
										if(pmnemonic(hw))
										{
											foundmn = true;
											return false; // Break.
										}
									}
									else
									{
										if(hw == m.hWnd)
											foundmhw = true;
									}
									return true; // Continue.
								});
							if(foundmn)
								return true; // Prevent.
							
							if(!foundmhw)
							{
								// Didn't find current control, so go from top-to-bottom.
								eachGoodChildHandle(form.handle,
									(HWND hw)
									{
										if(pmnemonic(hw))
										{
											foundmn = true;
											return false; // Break.
										}
										return true; // Continue.
									});
							}
							else
							{
								// Didn't find mnemonic after current control, so go from top-to-this.
								eachGoodChildHandle(form.handle,
									(HWND hw)
									{
										if(pmnemonic(hw))
										{
											foundmn = true;
											return false; // Break.
										}
										if(hw == m.hWnd)
											return false; // Break.
										return true; // Continue.
									});
							}
							if(foundmn)
								return true; // Prevent.
						}
						break;
					
					case WM_LBUTTONUP:
					case WM_MBUTTONUP:
					case WM_RBUTTONUP:
						if(m.hWnd != form.hwnd)
						{
							Control ctrl = Control.fromChildHandle(m.hWnd);
							if(ctrl.focused && ctrl.canSelect)
							{
								bool wasselbtn = form._selbefore();
								form._selafter(ctrl, wasselbtn);
							}
						}
						break;
					
					default:
				}
			}
			
			return false; // Continue.
		}
		
		
		this(Form form)
		{
			this.form = form;
		}
		
		
		private:
		Form form;
	}
	
	
	/+
	package final bool _dlgescape()
	{
		if(cancelBtn)
		{
			cancelBtn.performClick();
			return true;
		}
		return false;
	}
	+/
	
	
	final void _recalcClientSize()
	{
		RECT r;
		r.left = 0;
		r.right = wrect.width;
		r.top = 0;
		r.bottom = wrect.height;
		
		LONG wl = _style();
		version(DFL_NO_MENUS)
		{
			enum hasmenu = null;
		}
		else
		{
			auto hasmenu = wmenu;
		}
		AdjustWindowRectEx(&r, wl, hasmenu !is null && !(wl & WS_CHILD), _exStyle());
		
		// Subtract the difference.
		wclientsz = Size(wrect.width - ((r.right - r.left) - wrect.width), wrect.height - ((r.bottom - r.top) - wrect.height));
	}
}


version(NO_MDI) {} else
{
	///
	class MdiClient: ControlSuperClass
	{
		private this()
		{
			_initMdiclient();
			
			wclassStyle = mdiclientClassStyle;
			wstyle |= WS_VSCROLL | WS_HSCROLL;
			wexstyle |= WS_EX_CLIENTEDGE /+ | WS_EX_CONTROLPARENT +/;
			
			dock = DockStyle.FILL;
		}
		
		
		///
		@property void borderStyle(BorderStyle bs) // setter
		{
			final switch(bs)
			{
				case BorderStyle.FIXED_3D:
					_style(_style() & ~WS_BORDER);
					_exStyle(_exStyle() | WS_EX_CLIENTEDGE);
					break;
					
				case BorderStyle.FIXED_SINGLE:
					_exStyle(_exStyle() & ~WS_EX_CLIENTEDGE);
					_style(_style() | WS_BORDER);
					break;
					
				case BorderStyle.NONE:
					_style(_style() & ~WS_BORDER);
					_exStyle(_exStyle() & ~WS_EX_CLIENTEDGE);
					break;
			}

			if(isHandleCreated)
			{
				redrawEntire();
			}
		}

		/// ditto
		@property BorderStyle borderStyle() // getter
		{
			if(_exStyle() & WS_EX_CLIENTEDGE)
				return BorderStyle.FIXED_3D;
			else if(_style() & WS_BORDER)
				return BorderStyle.FIXED_SINGLE;
			return BorderStyle.NONE;
		}
		
		
		///
		final @property void hScroll(bool byes) // setter
		{
			LONG wl = _style();
			if(byes)
				wl |= WS_HSCROLL;
			else
				wl &= ~WS_HSCROLL;
			_style(wl);
			
			if(isHandleCreated)
				redrawEntire();
		}


		/// ditto
		final @property bool hScroll() // getter
		{
			return (_style() & WS_HSCROLL) != 0;
		}


		///
		final @property void vScroll(bool byes) // setter
		{
			LONG wl = _style();
			if(byes)
				wl |= WS_VSCROLL;
			else
				wl &= ~WS_VSCROLL;
			_style(wl);
			
			if(isHandleCreated)
				redrawEntire();
		}
		
		
		/+
		override void createHandle()
		{
			//if(created)
			if(isHandleCreated)
				return;
			
			if(!wowner || killing)
			{
				create_err:
				throw new DflException("MDI client creation failure");
			}
			
			CLIENTCREATESTRUCT ccs;
			ccs.hWindowMenu = HMENU.init; //wowner.menu ? wowner.menu.handle : HMENU.init;
			ccs.idFirstChild = 10000;
			
			Application.creatingControl(this);
			hwnd = dfl.internal.utf.createWindowEx(wexstyle, MDICLIENT_CLASSNAME, wtext, wstyle, wrect.x, wrect.y,
				wrect.width, wrect.height, wparent.handle, HMENU.init, Application.getInstance(), &ccs);
			if(!hwnd)
				goto create_err;
			
			onHandleCreated(EventArgs.empty);
		}
		+/
		
		
		protected override void createParams(ref CreateParams cp)
		{
			if(!wparent)
				throw new DflException("Invalid MDI child parent");
			
			super.createParams(cp);
			
			cp.className = MDICLIENT_CLASSNAME;
			
			ccs.hWindowMenu = HMENU.init; //wowner.menu ? wowner.menu.handle : HMENU.init;
			ccs.idFirstChild = 10000;
			cp.param = &ccs;
		}
		
		
		static @property Color defaultBackColor() // getter
		{
			return Color.systemColor(COLOR_APPWORKSPACE);
		}
		
		
		override @property Color backColor() // getter
		{
			if(Color.empty == backc)
				return defaultBackColor;
			return backc;
		}
		
		alias Control.backColor backColor; // Overload.
		
		
		/+
		static @property Color defaultForeColor() //getter
		{
			return Color.systemColor(COLOR_WINDOWTEXT);
		}
		+/
		
		
		protected override void prevWndProc(ref Message msg)
		{
			//msg.result = CallWindowProcA(mdiclientPrevWndProc, msg.hWnd, msg.msg, msg.wParam, msg.lParam);
			msg.result = dfl.internal.utf.callWindowProc(mdiclientPrevWndProc, msg.hWnd, msg.msg, msg.wParam, msg.lParam);
		}
		
		
		private:
		CLIENTCREATESTRUCT ccs;
	}
}


private:

version(DFL_PARK_WINDOW)
{
	HWND getParkHwnd()
	{
		if(!_hwPark)
		{
			synchronized
			{
				if(!_hwPark)
					_makePark();
			}
		}
		return _hwPark;
	}
	
	
	void _makePark()
	{
		WNDCLASSEXA wce;
		wce.cbSize = wce.sizeof;
		wce.style = CS_DBLCLKS;
		wce.lpszClassName = PARK_CLASSNAME.ptr;
		wce.lpfnWndProc = &DefWindowProcA;
		wce.hInstance = Application.getInstance();
		
		if(!RegisterClassExA(&wce))
		{
			debug(APP_PRINT)
				cprintf("RegisterClassEx() failed for park class.\n");
			
			init_err:
			//throw new DflException("Unable to initialize forms library");
			throw new DflException("Unable to create park window");
		}
		
		_hwPark = CreateWindowExA(WS_EX_TOOLWINDOW, PARK_CLASSNAME.ptr, "",
			WS_OVERLAPPEDWINDOW, 0, 0, 0, 0,
			HWND.init, HMENU.init, wce.hInstance, null);
		if(!_hwPark)
		{
			debug(APP_PRINT)
				cprintf("CreateWindowEx() failed for park window.\n");
			
			goto init_err;
		}
	}
	
	
	enum PARK_CLASSNAME = "DFL_Parking";
	
	HWND _hwPark; // Don't use directly; use getParkHwnd().
}

