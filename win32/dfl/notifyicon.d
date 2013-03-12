// Written by Christopher E. Miller
// See the included license.txt for copyright and license details.


///
module dfl.notifyicon;

private import dfl.internal.winapi, dfl.base, dfl.drawing;
private import dfl.control, dfl.form, dfl.application;
private import dfl.event, dfl.internal.utf, dfl.internal.dlib;

version(DFL_NO_MENUS)
{
}
else
{
	private import dfl.menu;
}


///
class NotifyIcon // docmain
{
	version(DFL_NO_MENUS)
	{
	}
	else
	{
		///
		final @property void contextMenu(ContextMenu menu) // setter
		{
			this.cmenu = menu;
		}
		
		/// ditto
		final @property ContextMenu contextMenu() // getter
		{
			return cmenu;
		}
	}
	
	
	///
	final @property void icon(Icon ico) // setter
	{
		_icon = ico;
		nid.hIcon = ico ? ico.handle : null;
		
		if(visible)
		{
			nid.uFlags = NIF_ICON;
			Shell_NotifyIconA(NIM_MODIFY, &nid);
		}
	}
	
	/// ditto
	final @property Icon icon() // getter
	{
		return _icon;
	}
	
	
	///
	// Must be less than 64 chars.
	// To-do: hold reference to setter's string, use that for getter.. ?
	final @property void text(Dstring txt) // setter
	{
		if(txt.length >= nid.szTip.length)
			throw new DflException("Notify icon text too long");
		
		// To-do: support Unicode.
		
		txt = unsafeAnsi(txt); // ...
		nid.szTip[txt.length] = 0;
		nid.szTip[0 .. txt.length] = txt[];
		tipLen = txt.length;
		
		if(visible)
		{
			nid.uFlags = NIF_TIP;
			Shell_NotifyIconA(NIM_MODIFY, &nid);
		}
	}
	
	/// ditto
	final @property Dstring text() // getter
	{
		//return nid.szTip[0 .. tipLen]; // Returning possibly mutated text!
		//return nid.szTip[0 .. tipLen].dup;
		//return nid.szTip[0 .. tipLen].idup; // Needed in D2. Doesn't work in D1.
		return cast(Dstring)nid.szTip[0 .. tipLen].dup; // Needed in D2. Doesn't work in D1.
	}
	
	
	///
	final @property void visible(bool byes) // setter
	{
		if(byes)
		{
			if(!nid.uID)
			{
				nid.uID = allocNotifyIconID();
				assert(nid.uID);
				allNotifyIcons[nid.uID] = this;
			}
			
			_forceAdd();
		}
		else if(nid.uID)
		{
			_forceDelete();
			
			//delete allNotifyIcons[nid.uID];
			allNotifyIcons.remove(nid.uID);
			nid.uID = 0;
		}
	}
	
	/// ditto
	final @property bool visible() // getter
	{
		return nid.uID != 0;
	}
	
	
	///
	final void show()
	{
		visible = true;
	}
	
	/// ditto
	final void hide()
	{
		visible = false;
	}
	
	
	//EventHandler click;
	Event!(NotifyIcon, EventArgs) click; ///
	//EventHandler doubleClick;
	Event!(NotifyIcon, EventArgs) doubleClick; ///
	//MouseEventHandler mouseDown;
	Event!(NotifyIcon, MouseEventArgs) mouseDown; ///
	//MouseEventHandler mouseUp;
	Event!(NotifyIcon, MouseEventArgs) mouseUp; ///
	//MouseEventHandler mouseMove;
	Event!(NotifyIcon, MouseEventArgs) mouseMove; ///
	
	
	this()
	{
		if(!ctrlNotifyIcon)
			_init();
		
		nid.cbSize = nid.sizeof;
		nid.hWnd = ctrlNotifyIcon.handle;
		nid.uID = 0;
		nid.uCallbackMessage = WM_NOTIFYICON;
		nid.hIcon = null;
		nid.szTip[0] = '\0';
	}
	
	
	~this()
	{
		if(nid.uID)
		{
			_forceDelete();
			//delete allNotifyIcons[nid.uID];
			allNotifyIcons.remove(nid.uID);
		}
		
		//delete allNotifyIcons[nid.uID];
		//allNotifyIcons.remove(nid.uID);
		
		/+
		if(!allNotifyIcons.length)
		{
			delete ctrlNotifyIcon;
			ctrlNotifyIcon = null;
		}
		+/
	}
	
	
	///
	// Extra.
	void minimize(IWindow win)
	{
		LONG style;
		HWND hwnd;
		
		hwnd = win.handle;
		style = GetWindowLongA(hwnd, GWL_STYLE);
		
		if(style & WS_VISIBLE)
		{
			ShowOwnedPopups(hwnd, FALSE);
			
			if(!(style & WS_MINIMIZE) && _animation())
			{
				RECT myRect, areaRect;
				
				GetWindowRect(hwnd, &myRect);
				_area(areaRect);
				DrawAnimatedRects(hwnd, 3, &myRect, &areaRect);
			}
			
			ShowWindow(hwnd, SW_HIDE);
		}
	}
	
	
	///
	// Extra.
	void restore(IWindow win)
	{
		LONG style;
		HWND hwnd;
		
		hwnd = win.handle;
		style = GetWindowLongA(hwnd, GWL_STYLE);
		
		if(!(style & WS_VISIBLE))
		{
			if(style & WS_MINIMIZE)
			{
				ShowWindow(hwnd, SW_RESTORE);
			}
			else
			{
				if(_animation())
				{
					RECT myRect, areaRect;
					
					GetWindowRect(hwnd, &myRect);
					_area(areaRect);
					DrawAnimatedRects(hwnd, 3, &areaRect, &myRect);
				}
				
				ShowWindow(hwnd, SW_SHOW);
				
				ShowOwnedPopups(hwnd, TRUE);
			}
		}
		else
		{
			if(style & WS_MINIMIZE)
				ShowWindow(hwnd, SW_RESTORE);
		}
		
		SetForegroundWindow(hwnd);
	}
	
	
	private:
	
	NOTIFYICONDATA nid;
	int tipLen = 0;
	version(DFL_NO_MENUS)
	{
	}
	else
	{
		ContextMenu cmenu;
	}
	Icon _icon;
	
	
	package final void _forceAdd()
	{
		nid.uFlags = NIF_MESSAGE | NIF_ICON | NIF_TIP;
		Shell_NotifyIconA(NIM_ADD, &nid);
	}
	
	
	package final void _forceDelete()
	{
		Shell_NotifyIconA(NIM_DELETE, &nid);
	}
	
	
	// Returns true if min/restore animation is on.
	static bool _animation()
	{
		ANIMATIONINFO ai;
		
		ai.cbSize = ai.sizeof;
		SystemParametersInfoA(SPI_GETANIMATION, ai.sizeof, &ai, 0);
		
		return ai.iMinAnimate ? true : false;
	}
	
	
	// Gets the tray area.
	static void _area(out RECT rect)
	{
		HWND hwTaskbar, hw;
		
		hwTaskbar = FindWindowExA(null, null, "Shell_TrayWnd", null);
		if(hwTaskbar)
		{
			hw = FindWindowExA(hwTaskbar, null, "TrayNotifyWnd", null);
			if(hw)
			{
				GetWindowRect(hw, &rect);
				return;
			}
		}
		
		APPBARDATA abd;
		
		abd.cbSize = abd.sizeof;
		if(SHAppBarMessage(ABM_GETTASKBARPOS, &abd))
		{
			switch(abd.uEdge)
			{
				case ABE_LEFT:
				case ABE_RIGHT:
					rect.top = abd.rc.bottom - 100;
					rect.bottom = abd.rc.bottom - 16;
					rect.left = abd.rc.left;
					rect.right = abd.rc.right;
					break;
				
				case ABE_TOP:
				case ABE_BOTTOM:
					rect.top = abd.rc.top;
					rect.bottom = abd.rc.bottom;
					rect.left = abd.rc.right - 100;
					rect.right = abd.rc.right - 16;
					break;
				
				default:
			}
		}
		else if(hwTaskbar)
		{
			GetWindowRect(hwTaskbar, &rect);
			if(rect.right - rect.left > 150)
				rect.left = rect.right - 150;
			if(rect.bottom - rect.top > 30)
				rect.top = rect.bottom - 30;
		}
		else
		{
			SystemParametersInfoA(SPI_GETWORKAREA, 0, &rect, 0);
			rect.left = rect.right - 150;
			rect.top = rect.bottom - 30;
		}
	}
}


package:


enum UINT WM_NOTIFYICON = WM_USER + 34; // -wparam- is id, -lparam- is the mouse message such as WM_LBUTTONDBLCLK.
UINT wmTaskbarCreated;
NotifyIcon[UINT] allNotifyIcons; // Indexed by ID.
UINT lastId = 1;
NotifyIconControl ctrlNotifyIcon;


class NotifyIconControl: Control
{
	override void createHandle()
	{
		//if(created)
		if(isHandleCreated)
			return;
		
		if(killing)
		{
			create_err:
			throw new DflException("Notify icon initialization failure");
		}
		
		Application.creatingControl(this);
		hwnd = CreateWindowExA(wexstyle, CONTROL_CLASSNAME.ptr, "NotifyIcon", 0, 0, 0, 0, 0, null, null,
			Application.getInstance(), null);
		if(!hwnd)
			goto create_err;
	}
	
	
	protected override void wndProc(ref Message msg)
	{
		if(msg.msg == WM_NOTIFYICON)
		{
			if(cast(UINT)msg.wParam in allNotifyIcons)
			{
				NotifyIcon ni;
				Point pt;
				
				ni = allNotifyIcons[cast(UINT)msg.wParam];
				
				switch(cast(UINT)msg.lParam) // msg.
				{
					case WM_MOUSEMOVE:
						pt = Cursor.position;
						ni.mouseMove(ni, new MouseEventArgs(Control.mouseButtons(), 0, pt.x, pt.y, 0));
						break;
					
					case WM_LBUTTONUP:
						pt = Cursor.position;
						ni.mouseUp(ni, new MouseEventArgs(MouseButtons.LEFT, 1, pt.x, pt.y, 0));
						
						ni.click(ni, EventArgs.empty);
						break;
					
					case WM_RBUTTONUP:
						pt = Cursor.position;
						ni.mouseUp(ni, new MouseEventArgs(MouseButtons.RIGHT, 1, pt.x, pt.y, 0));
						
						version(DFL_NO_MENUS)
						{
						}
						else
						{
							if(ni.cmenu)
								ni.cmenu.show(ctrlNotifyIcon, pt);
						}
						break;
					
					case WM_LBUTTONDOWN:
						pt = Cursor.position;
						ni.mouseDown(ni, new MouseEventArgs(MouseButtons.LEFT, 0, pt.x, pt.y, 0));
						break;
					
					case WM_RBUTTONDOWN:
						pt = Cursor.position;
						ni.mouseDown(ni, new MouseEventArgs(MouseButtons.RIGHT, 0, pt.x, pt.y, 0));
						break;
					
					case WM_LBUTTONDBLCLK:
						ni.doubleClick(ni, EventArgs.empty);
						break;
					
					default:
				}
			}
		}
		else if(msg.msg == wmTaskbarCreated)
		{
			// Show all visible NotifyIcon's.
			foreach(NotifyIcon ni; allNotifyIcons)
			{
				if(ni.visible)
					ni._forceAdd();
			}
		}
		
		super.wndProc(msg);
	}
}


static ~this()
{
	// Due to all items not being destructed at program exit,
	// remove all visible notify icons because the OS won't.
	foreach(NotifyIcon ni; allNotifyIcons)
	{
		if(ni.visible)
			ni._forceDelete();
	}
	
	allNotifyIcons = null;
}


UINT allocNotifyIconID()
{
	UINT prev;
	prev = lastId;
	for(;;)
	{
		lastId++;
		if(lastId == ushort.max)
			lastId = 1;
		if(lastId == prev)
			throw new DflException("Too many notify icons");
		
		if(!(lastId in allNotifyIcons))
			break;
	}
	return lastId;
}


void _init()
{
	wmTaskbarCreated = RegisterWindowMessageA("TaskbarCreated");
	
	ctrlNotifyIcon = new NotifyIconControl;
	ctrlNotifyIcon.visible = false;
}

