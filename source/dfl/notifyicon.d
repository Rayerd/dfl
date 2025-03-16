// Written by Christopher E. Miller
// See the included license.txt for copyright and license details.


///
module dfl.notifyicon;

private import core.sys.windows.winbase;
private import core.sys.windows.windef;
private import core.sys.windows.winuser;
private import core.sys.windows.basetyps : GUID;
private import core.sys.windows.shellapi;

private import dfl.base, dfl.drawing;
private import dfl.control, dfl.form, dfl.application;
private import dfl.event, dfl.internal.utf, dfl.internal.dlib;

version(DFL_NO_MENUS)
{
}
else
{
	private import dfl.menu;
}


// NOTE: Workaround for shellapi.h
enum NOTIFYICON_VERSION_4 = 4;
enum NIF_SHOWTIP = 0x00000080;
enum NIIF_USER = 0x00000004;

struct DFL_NOTIFYICONDATAA {
	DWORD cbSize = DFL_NOTIFYICONDATAA.sizeof;
	HWND  hWnd;
	UINT  uID;
	UINT  uFlags;
	UINT  uCallbackMessage;
	HICON hIcon;
	CHAR[128] szTip = 0;
	DWORD     dwState;
	DWORD     dwStateMask;
	CHAR[256] szInfo = 0;
	union {
		UINT  uTimeout;
		UINT  uVersion;
	}
	CHAR[64]  szInfoTitle = 0;
	DWORD     dwInfoFlags;
	GUID      guidItem;
	HICON     hBalloonIcon;
}
alias DFL_PNOTIFYICONDATAA = DFL_NOTIFYICONDATAA*;

struct DFL_NOTIFYICONDATAW {
	DWORD cbSize = DFL_NOTIFYICONDATAW.sizeof;
	HWND  hWnd;
	UINT  uID;
	UINT  uFlags;
	UINT  uCallbackMessage;
	HICON hIcon;
	WCHAR[128] szTip = 0;
	DWORD      dwState;
	DWORD      dwStateMask;
	WCHAR[256] szInfo = 0;
	union {
		UINT   uTimeout;
		UINT   uVersion;
	}
	WCHAR[64]  szInfoTitle = 0;
	DWORD      dwInfoFlags;
	GUID       guidItem;
	HICON      hBalloonIcon;
}
alias DFL_PNOTIFYICONDATAW = DFL_NOTIFYICONDATAW*;

static if (useUnicode)
{
	BOOL DFL_Shell_NotifyIcon(DWORD dw, DFL_PNOTIFYICONDATAW notif)
	{
		return Shell_NotifyIcon(dw, cast(PNOTIFYICONDATAW)notif);
	}
}
else
{
	BOOL DFL_Shell_NotifyIcon(DWORD dw, DFL_PNOTIFYICONDATAA notif)
	{
		return Shell_NotifyIcon(dw, cast(PNOTIFYICONDATAA)notif);
	}
}


///
enum BalloonTipIconStyle
{
	NONE,
	INFO,
	WARNING,
	ERROR,
	USER
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
	final @property void icon(Icon icon) // setter
	{
		_icon = icon;
		_nid.hIcon = icon ? icon.handle : null;
		
		if(visible)
		{
			_nid.uFlags |= NIF_ICON;
			DFL_Shell_NotifyIcon(NIM_MODIFY, &_nid);
		}
	}
	
	/// ditto
	final @property Icon icon() // getter
	{
		return _icon;
	}
	
	
	///
	final @property void text(Dstring txt) // setter
	{
		if(txt.length >= _nid.szTip.length)
			throw new DflException("Notify icon text too long");
		
		static if (useUnicode)
			Dwstring str = toUnicode(txt);
		else
			Dstring str = unsafeAnsi(txt);
		_nid.szTip[str.length] = 0;
		_nid.szTip[0 .. str.length] = str[];
		_tipLen = str.length.toI32;
		
		if(visible)
		{
			_nid.uFlags |= NIF_TIP;
			DFL_Shell_NotifyIcon(NIM_MODIFY, &_nid);
		}
	}
	
	/// ditto
	final @property Dstring text() // getter
	{
		static if (useUnicode)
			return fromUnicodez(_nid.szTip[0 .. _tipLen].ptr);
		else
			return cast(Dstring)_nid.szTip[0 .. _tipLen].dup;
	}
	
	
	///
	final @property void visible(bool byes) // setter
	{
		if(byes)
		{
			if(!_nid.uID)
			{
				_nid.uID = allocNotifyIconID();
				assert(_nid.uID);
				allNotifyIcons[_nid.uID] = this;
			}
			
			_forceAdd();
		}
		else if(_nid.uID)
		{
			_forceDelete();
			
			allNotifyIcons.remove(_nid.uID);
			_nid.uID = 0;
		}
	}
	
	/// ditto
	final @property bool visible() // getter
	{
		return _nid.uID != 0;
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


	///
	final void showBalloonTip()
	{
		_nid.uFlags |= NIF_INFO;
		DFL_Shell_NotifyIcon(NIM_MODIFY, &_nid);
	}


	///
	final @property void balloonTipTitle(Dstring title) // setter
	{
		Dwstring str = toUnicode(title ~ '\0');
		_nid.szInfoTitle[0 .. str.length] = str[];
	}


	///
	final @property void balloonTipText(Dstring text) // setter
	{
		Dwstring str = toUnicode(text ~ '\0');
		_nid.szInfo[0 .. str.length] = str[];
	}


	///
	final @property void balloonTipIconStyle(BalloonTipIconStyle style) // setter
	{
		_nid.dwInfoFlags &= ~NIIF_ICON_MASK;
		final switch (style)
		{
			case BalloonTipIconStyle.NONE:
				_nid.dwInfoFlags |= NIIF_NONE;
				break;
			case BalloonTipIconStyle.INFO:
				_nid.dwInfoFlags |= NIIF_INFO;
				break;
			case BalloonTipIconStyle.WARNING:
				_nid.dwInfoFlags |= NIIF_WARNING;
				break;
			case BalloonTipIconStyle.ERROR:
				_nid.dwInfoFlags |= NIIF_ERROR;
				break;
			case BalloonTipIconStyle.USER:
				_nid.dwInfoFlags |= NIIF_USER;
		}
	}

	
	///
	final @property void balloonTipIcon(Icon icon) // setter
	{
		_balloonTipIcon = icon;
		_nid.hBalloonIcon = icon ? icon.handle : null;
	}


	///
	final @property void balloonTipSound(bool byes) // setter
	{
		if (byes)
			_nid.dwInfoFlags &= ~NIIF_NOSOUND;
		else
			_nid.dwInfoFlags |= NIIF_NOSOUND;
	}


	Event!(NotifyIcon, EventArgs) click; ///
	Event!(NotifyIcon, EventArgs) doubleClick; ///
	Event!(NotifyIcon, MouseEventArgs) mouseDown; ///
	Event!(NotifyIcon, MouseEventArgs) mouseUp; ///
	Event!(NotifyIcon, MouseEventArgs) mouseMove; ///
	
	
	this()
	{
		if(!ctrlNotifyIcon)
			_init();
		
		_nid.cbSize = _nid.sizeof;
		_nid.hWnd = ctrlNotifyIcon.handle;
		_nid.uID = 0;
		_nid.uCallbackMessage = WM_NOTIFYICON;
		_nid.hIcon = null;
		_nid.szTip[0] = '\0';
	}
	
	
	~this()
	{
		if(_nid.uID)
		{
			_forceDelete();
			allNotifyIcons.remove(_nid.uID);
		}
	}
	
	
	///
	// Extra.
	void minimize(IWindow win)
	{
		HWND hwnd = win.handle;
		LONG style = GetWindowLongPtrA(hwnd, GWL_STYLE).toI32;
		
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
		HWND hwnd = win.handle;
		LONG style = GetWindowLongPtrA(hwnd, GWL_STYLE).toI32;
		
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
	
	static if (useUnicode)
		DFL_NOTIFYICONDATAW _nid;
	else
		DFL_NOTIFYICONDATAA _nid;
	int _tipLen = 0;
	version(DFL_NO_MENUS)
	{
	}
	else
	{
		ContextMenu cmenu;
	}
	Icon _icon;           /// Task tray icon
	Icon _balloonTipIcon; /// Balloon tip icon
	
	
	package final void _forceAdd()
	{
		_nid.uFlags |= NIF_MESSAGE | NIF_ICON | NIF_TIP | NIF_SHOWTIP;
		if (_nid.hIcon)
			_nid.uFlags |= NIF_ICON;
		else
			_nid.uFlags &= ~NIF_ICON;
		DFL_Shell_NotifyIcon(NIM_ADD, &_nid);
	}
	
	
	package final void _forceDelete()
	{
		DFL_Shell_NotifyIcon(NIM_DELETE, &_nid);
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
		HWND hwTaskbar = FindWindowExA(null, null, "Shell_TrayWnd", null);
		
		if(hwTaskbar)
		{
			HWND hw = FindWindowExA(hwTaskbar, null, "TrayNotifyWnd", null);
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
		hwnd = CreateWindowExA(wexstyle, CONTROL_CLASSNAME.ptr, "NotifyIcon", 0, 0, 0, 0, 0, null, null, Application.getInstance(), null);
		if(!hwnd)
			goto create_err;
	}
	
	
	protected override void wndProc(ref Message msg)
	{
		if(msg.msg == WM_NOTIFYICON)
		{
			if(cast(UINT)msg.wParam in allNotifyIcons)
			{
				NotifyIcon ni = allNotifyIcons[cast(UINT)msg.wParam];
				Point pt;
				
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
	UINT prev = lastId;
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

