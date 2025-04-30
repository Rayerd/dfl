// Written by Christopher E. Miller
// See the included license.txt for copyright and license details.


///
module dfl.notifyicon;

import dfl.application;
import dfl.base;
import dfl.control;
import dfl.drawing;
import dfl.event;
import dfl.form;

version(DFL_NO_MENUS)
{
}
else
{
	import dfl.menu;
}

import dfl.internal.dlib;
import dfl.internal.utf;
import dfl.internal.dpiaware;

import core.sys.windows.basetyps : GUID;
import core.sys.windows.shellapi;
import core.sys.windows.windef;
import core.sys.windows.winuser;


// NOTE: Shell_NotifyIcon workaround >>>

enum NOTIFYICON_VERSION_4 = 4;                     ///
enum NIF_SHOWTIP          = 0x00000080;            ///
enum NIIF_USER            = 0x00000004;            ///
enum NINF_KEY             = 1;                     ///
enum NIN_SELECT           = (WM_USER+0);           ///
enum NIN_KEYSELECT        = (NIN_SELECT|NINF_KEY); /// WM_USER+1
enum NIN_BALLOONSHOW      = (WM_USER+2);           ///
enum NIN_BALLOONHIDE      = (WM_USER+3);           ///
enum NIN_BALLOONTIMEOUT   = (WM_USER+4);           ///
enum NIN_BALLOONUSERCLICK = (WM_USER+5);           ///
enum NIN_POPUPOPEN        = (WM_USER+6);           ///
enum NIN_POPUPCLOSE       = (WM_USER+7);           ///


///
struct DFL_NOTIFYICONDATAA
{
	DWORD cbSize = DFL_NOTIFYICONDATAA.sizeof;
	HWND hWnd;
	UINT uID;
	UINT uFlags;
	UINT uCallbackMessage;
	HICON hIcon;
	CHAR[128] szTip = 0;
	DWORD dwState;
	DWORD dwStateMask;
	CHAR[256] szInfo = 0;
	union
	{
		UINT uTimeout;
		UINT uVersion;
	}
	CHAR[64] szInfoTitle = 0;
	DWORD dwInfoFlags;
	GUID guidItem;
	HICON hBalloonIcon;
}
///
alias DFL_PNOTIFYICONDATAA = DFL_NOTIFYICONDATAA*;


///
struct DFL_NOTIFYICONDATAW
{
	DWORD cbSize = DFL_NOTIFYICONDATAW.sizeof;
	HWND hWnd;
	UINT uID;
	UINT uFlags;
	UINT uCallbackMessage;
	HICON hIcon;
	WCHAR[128] szTip = 0;
	DWORD dwState;
	DWORD dwStateMask;
	WCHAR[256] szInfo = 0;
	union
	{
		UINT uTimeout;
		UINT uVersion;
	}
	WCHAR[64] szInfoTitle = 0;
	DWORD dwInfoFlags;
	GUID guidItem;
	HICON hBalloonIcon;
}
///
alias DFL_PNOTIFYICONDATAW = DFL_NOTIFYICONDATAW*;


///
struct NOTIFYICONIDENTIFIER
{
	DWORD cbSize;
	HWND hWnd;
	UINT uID;
	GUID guidItem;
}
///
alias PNOTIFYICONIDENTIFIER = NOTIFYICONIDENTIFIER*;


extern(Windows) @nogc nothrow
{
	///
	HRESULT Shell_NotifyIconGetRect(const NOTIFYICONIDENTIFIER* nii, RECT* rect);
}


static if (useUnicode)
{
	///
	alias DFL_NOTIFYICONDATA = DFL_NOTIFYICONDATAW;
	///
	alias DFL_PNOTIFYICONDATA = DFL_PNOTIFYICONDATAW;

	///
	BOOL DFL_Shell_NotifyIcon(DWORD dw, DFL_PNOTIFYICONDATA notif)
	{
		return Shell_NotifyIcon(dw, cast(PNOTIFYICONDATAW)notif);
	}
}
else
{
	///
	alias DFL_NOTIFYICONDATA = DFL_NOTIFYICONDATAA;
	///
	alias DFL_PNOTIFYICONDATA = DFL_PNOTIFYICONDATAA;

	///
	BOOL DFL_Shell_NotifyIcon(DWORD dw, DFL_PNOTIFYICONDATA notif)
	{
		return Shell_NotifyIcon(dw, cast(PNOTIFYICONDATAA)notif);
	}
}

// Shell_NotifyIcon workaround <<<


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
			this._cmenu = menu;
		}
		
		/// ditto
		final @property ContextMenu contextMenu() // getter
		{
			return _cmenu;
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
	Event!(NotifyIcon, EventArgs) balloonTipShown; ///
	Event!(NotifyIcon, EventArgs) balloonTipClosed; ///
	Event!(NotifyIcon, EventArgs) balloonTipClicked; ///
	Event!(NotifyIcon, EventArgs) balloonTipTimeout; ///
	Event!(NotifyIcon, MouseEventArgs) select; ///
	Event!(NotifyIcon, MouseEventArgs) keySelect; ///
	Event!(NotifyIcon, MouseEventArgs) popupShown; ///
	Event!(NotifyIcon, EventArgs) popupClosed; ///
	
	
	///
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
		_nid.szInfo[0] = '\0';
		_nid.szInfoTitle[0] = '\0';
		_nid.uVersion = NOTIFYICON_VERSION_4;
	}
	
	
	///
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
	
	DFL_NOTIFYICONDATA _nid; ///
	int _tipLen = 0;         ///
	version(DFL_NO_MENUS)
	{
	}
	else
	{
		ContextMenu _cmenu; ///
	}
	Icon _icon;           /// Task tray icon
	Icon _balloonTipIcon; /// Balloon tip icon
	
	
	///
	package final void _forceAdd()
	{
		_nid.uFlags |= NIF_MESSAGE | NIF_ICON | NIF_TIP | NIF_SHOWTIP;
		if (_nid.hIcon)
			_nid.uFlags |= NIF_ICON;
		else
			_nid.uFlags &= ~NIF_ICON;
		DFL_Shell_NotifyIcon(NIM_ADD, &_nid);
		DFL_Shell_NotifyIcon(NIM_SETVERSION, &_nid);
	}
	
	
	///
	package final void _forceDelete()
	{
		DFL_Shell_NotifyIcon(NIM_DELETE, &_nid);
	}
	
	
	/// Returns true if min/restore animation is on.
	static bool _animation()
	{
		ANIMATIONINFO ai;
		
		ai.cbSize = ai.sizeof;
		SystemParametersInfoA(SPI_GETANIMATION, ai.sizeof, &ai, 0);
		
		return ai.iMinAnimate ? true : false;
	}
	
	
	/// Gets the tray area.
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


enum UINT WM_NOTIFYICON = WM_USER + 34; /// -wparam- is id, -lparam- is the mouse message such as WM_LBUTTONDBLCLK.
UINT wmTaskbarCreated; ///
NotifyIcon[UINT] allNotifyIcons; /// Indexed by ID.
UINT lastId = 1; ///
NotifyIconControl ctrlNotifyIcon; ///


///
class NotifyIconControl: Control
{
	///
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
	
	
	///
	protected override void wndProc(ref Message msg)
	{
		if(msg.msg == WM_NOTIFYICON)
		{
			ushort nid = HIWORD(msg.lParam);
			NotifyIcon ni = allNotifyIcons[nid];
			ushort notifyMessage = LOWORD(msg.lParam);
			Point pt;

			switch (notifyMessage)
			{
				case NIN_BALLOONSHOW:
					ni.balloonTipShown(ni, EventArgs.empty);
					break;

				case NIN_BALLOONHIDE:
					ni.balloonTipClosed(ni, EventArgs.empty);
					break;

				case NIN_BALLOONTIMEOUT:
					ni.balloonTipTimeout(ni, EventArgs.empty);
					break;

				case NIN_BALLOONUSERCLICK:
					ni.balloonTipClicked(ni, EventArgs.empty);
					break;

				case NIN_KEYSELECT:
				{
					pt = Point(GET_X_LPARAM(msg.wParam), GET_Y_LPARAM(msg.wParam));
					ni.keySelect(ni, new MouseEventArgs(Control.mouseButtons(), 0, pt.x, pt.y, 0));
					Point contextMenuPoint = getNotifyIconRect(ctrlNotifyIcon.handle, nid).location;
					if (ni.contextMenu)
						ni.contextMenu.show(ctrlNotifyIcon, contextMenuPoint);
					
					break;
				}

				case NIN_POPUPCLOSE:
					ni.popupClosed(ni, EventArgs.empty);
					break;

				case NIN_POPUPOPEN:
					pt = Point(GET_X_LPARAM(msg.wParam), GET_Y_LPARAM(msg.wParam));
					ni.popupShown(ni, new MouseEventArgs(Control.mouseButtons(), 0, pt.x, pt.y, 0));
					break;

				case NIN_SELECT:
					pt = Point(GET_X_LPARAM(msg.wParam), GET_Y_LPARAM(msg.wParam));
					ni.select(ni, new MouseEventArgs(Control.mouseButtons(), 0, pt.x, pt.y, 0));
					break;

				case WM_CONTEXTMENU:
					pt = Cursor.position;
					if (ni.contextMenu)
						ni.contextMenu.show(ctrlNotifyIcon, pt);
					break;

				case WM_MOUSEMOVE:
					pt = Cursor.position;
					ni.mouseMove(ni, new MouseEventArgs(Control.mouseButtons(), 0, pt.x, pt.y, 0));
					break;

				case WM_LBUTTONUP:
					pt = Cursor.position;
					ni.mouseUp(ni, new MouseEventArgs(MouseButtons.LEFT, 1, pt.x, pt.y, 0));
					break;

				case WM_RBUTTONUP:
					pt = Cursor.position;
					ni.mouseUp(ni, new MouseEventArgs(MouseButtons.RIGHT, 1, pt.x, pt.y, 0));
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
		else if (msg.msg == wmTaskbarCreated)
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


///
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


///
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


///
void _init()
{
	wmTaskbarCreated = RegisterWindowMessageA("TaskbarCreated");
	
	ctrlNotifyIcon = new NotifyIconControl;
	ctrlNotifyIcon.visible = false;
}


///
Rect getNotifyIconRect(HWND notifyIconControlHandle, ushort notifyIconID)
{
	import dfl.drawing;

	NOTIFYICONIDENTIFIER nii;
	nii.cbSize = nii.sizeof;
	nii.guidItem = GUID(); // GUID_NULL
	nii.hWnd = notifyIconControlHandle;
	nii.uID = notifyIconID;

	RECT iconRect;
	Shell_NotifyIconGetRect(&nii, &iconRect);

	// Graphics g = Graphics.getScreen();
	// g.drawRectangle(new Pen(Color.red, 3), Rect(&iconRect));

	POINT topLeft = POINT(iconRect.left, iconRect.top);
	POINT bottomRight = POINT(iconRect.right, iconRect.bottom);
	PhysicalToLogicalPointForPerMonitorDPI(null, &topLeft);
	PhysicalToLogicalPointForPerMonitorDPI(null, &bottomRight);
	ClientToScreen(notifyIconControlHandle, &topLeft);
	ClientToScreen(notifyIconControlHandle, &bottomRight);

	return Rect(topLeft.x, topLeft.y, bottomRight.x, bottomRight.y);
}
