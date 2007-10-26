// See the included license.txt for copyright and license details.


///
module dfl.base;

import dfl.internal.dlib, dfl.internal.clib, dfl.internal.gtk;

import dfl.event, dfl.drawing;


alias GtkWidget* HWindow;


///
interface IWindow // docmain
{
	///
	HWindow handle(); // getter
}

deprecated alias IWindow IWin32Window; // deprecated


///
class DflException: Exception // docmain
{
	///
	this(char[] msg)
	{
		super(msg);
	}
}


///
class StringObject: DObject
{
	///
	char[] value;
	
	
	///
	this(char[] str)
	{
		this.value = str;
	}
	
	
	override char[] toString()
	{
		return value;
	}
	
	
	override int opEquals(Object o)
	{
		return value == getObjectString(o); // ?
	}
	
	
	int opEquals(StringObject s)
	{
		return value == s.value;
	}
	
	
	override int opCmp(Object o)
	{
		return stringICmp(value, getObjectString(o)); // ?
	}
	
	
	int opCmp(StringObject s)
	{
		return stringICmp(value, s.value);
	}
}


///
enum Keys: uint // docmain
{
	NONE =     0, /// No keys specified.
	
	///
	SHIFT =    0x10000, /// Modifier keys.
	CONTROL =  0x20000, /// ditto
	ALT =      0x40000, /// ditto
	
	// GDK_a ...
	A = 'a', /// Letters.
	B, /// ditto
	C, /// ditto
	D, /// ditto
	E, /// ditto
	F, /// ditto
	G, /// ditto
	H, /// ditto
	I, /// ditto
	J, /// ditto
	K, /// ditto
	L, /// ditto
	M, /// ditto
	N, /// ditto
	O, /// ditto
	P, /// ditto
	Q, /// ditto
	R, /// ditto
	S, /// ditto
	T, /// ditto
	U, /// ditto
	V, /// ditto
	W, /// ditto
	X, /// ditto
	Y, /// ditto
	Z, /// ditto
	
	D0 = '0', /// Digits.
	D1 = '1', /// ditto
	D2 = '2', /// ditto
	D3 = '3', /// ditto
	D4 = '4', /// ditto
	D5 = '5', /// ditto
	D6 = '6', /// ditto
	D7 = '7', /// ditto
	D8 = '8', /// ditto
	D9 = '9', /// ditto
	
	// GDK_F1 ...
	F1 = 0xFFBE, /// F - function keys.
	F2, /// ditto
	F3, /// ditto
	F4, /// ditto
	F5, /// ditto
	F6, /// ditto
	F7, /// ditto
	F8, /// ditto
	F9, /// ditto
	F10, /// ditto
	F11, /// ditto
	F12, /// ditto
	F13, /// ditto
	F14, /// ditto
	F15, /// ditto
	F16, /// ditto
	F17, /// ditto
	F18, /// ditto
	F19, /// ditto
	F20, /// ditto
	F21, /// ditto
	F22, /// ditto
	F23, /// ditto
	F24, /// ditto
	
	// GDK_KP_0 ...
	NUM_PAD0 = 0xFFB0, /// Numbers on keypad.
	NUM_PAD1, /// ditto
	NUM_PAD2, /// ditto
	NUM_PAD3, /// ditto
	NUM_PAD4, /// ditto
	NUM_PAD5, /// ditto
	NUM_PAD6, /// ditto
	NUM_PAD7, /// ditto
	NUM_PAD8, /// ditto
	NUM_PAD9, /// ditto
	
	//ADD = , ///
	//APPS = , /// Application.
	//ATTN = , ///
	BACK = 0xFF08, /// Backspace.
	CANCEL = 0xFF69, ///
	CAPITAL = 0xFFE5, ///
	CAPS_LOCK = 0xFFE5, /// ditto
	CLEAR = 0xFF0B, ///
	
	// GDK_Control_L (Note: skipping GDK_Control_R)
	CONTROL_KEY = 0xFFE3, ///
	
	// GDK_3270_CursorSelect ?
	CRSEL = 0xFD1C, ///
	
	// GDK_KP_Decimal
	DECIMAL = 0xFFAE, ///
	
	// GDK_Delete
	DEL = 0xFFFF, ///
	DELETE = DEL, ///
	
	// GDK_period
	PERIOD = 0x02E, ///
	DOT = PERIOD, /// ditto
	
	/+ // Not converted yet...
	DIVIDE = 111, ///
	DOWN = 40, /// Down arrow.
	END = 35, ///
	ENTER = 13, ///
	ERASE_EOF = 249, ///
	ESCAPE = 27, ///
	EXECUTE = 43, ///
	EXSEL = 248, ///
	FINAL_MODE = 4, /// IME final mode.
	HANGUL_MODE = 21, /// IME Hangul mode.
	HANGUEL_MODE = 21, /// ditto
	HANJA_MODE = 25, /// IME Hanja mode.
	HELP = 47, ///
	HOME = 36, ///
	IME_ACCEPT = 30, ///
	IME_CONVERT = 28, ///
	IME_MODE_CHANGE = 31, ///
	IME_NONCONVERT = 29, ///
	INSERT = 45, ///
	JUNJA_MODE = 23, ///
	KANA_MODE = 21, ///
	KANJI_MODE = 25, ///
	LEFT_CONTROL = 162, /// Left Ctrl.
	LEFT = 37, /// Left arrow.
	LINE_FEED = 10, ///
	LEFT_MENU = 164, /// Left Alt.
	LEFT_SHIFT = 160, ///
	LEFT_WIN = 91, /// Left Windows logo.
	MENU = 18, /// Alt.
	MULTIPLY = 106, ///
	NEXT = 34, /// Page down.
	NO_NAME = 252, // Reserved for future use.
	NUM_LOCK = 144, ///
	OEM8 = 223, // OEM specific.
	OEM_CLEAR = 254,
	PA1 = 253,
	PAGE_DOWN = 34, ///
	PAGE_UP = 33, ///
	PAUSE = 19, ///
	PLAY = 250, ///
	PRINT = 42, ///
	PRINT_SCREEN = 44, ///
	PROCESS_KEY = 229, ///
	RIGHT_CONTROL = 163, /// Right Ctrl.
	RETURN = 13, ///
	RIGHT = 39, /// Right arrow.
	RIGHT_MENU = 165, /// Right Alt.
	RIGHT_SHIFT = 161, ///
	RIGHT_WIN = 92, /// Right Windows logo.
	SCROLL = 145, /// Scroll lock.
	SELECT = 41, ///
	SEPARATOR = 108, ///
	SHIFT_KEY = 16, ///
	SNAPSHOT = 44, /// Print screen.
	SPACE = 32, ///
	SPACEBAR = SPACE, // Extra.
	SUBTRACT = 109, ///
	TAB = 9, ///
	UP = 38, /// Up arrow.
	ZOOM = 251, ///
	
	BROWSER_BACK = 166, ///
	BROWSER_FAVORITES = 171, /// ditto
	BROWSER_FORWARD = 167, /// ditto
	BROWSER_HOME = 172, /// ditto
	BROWSER_REFRESH = 168, /// ditto
	BROWSER_SEARCH = 170, /// ditto
	BROWSER_STOP = 169, /// ditto
	LAUNCH_APPLICATION1 = 182, ///
	LAUNCH_APPLICATION2 = 183, /// ditto
	LAUNCH_MAIL = 180, /// ditto
	MEDIA_NEXT_TRACK = 176, ///
	MEDIA_PLAY_PAUSE = 179, /// ditto
	MEDIA_PREVIOUS_TRACK = 177, /// ditto
	MEDIA_STOP = 178, /// ditto
	OEM_BACKSLASH = 226, // OEM angle bracket or backslash.
	OEM_CLOSE_BRACKETS = 221,
	OEM_COMMA = 188,
	OEM_MINUS = 189,
	OEM_OPEN_BRACKETS = 219,
	OEM_PERIOD = 190,
	OEM_PIPE = 220,
	OEM_PLUS = 187,
	OEM_QUESTION = 191,
	OEM_QUOTES = 222,
	OEM_SEMICOLON = 186,
	OEM_TILDE = 192,
	SELECT_MEDIA = 181, ///
	VOLUME_DOWN = 174, ///
	VOLUME_MUTE = 173, /// ditto
	VOLUME_UP = 175, /// ditto
	+/
	
	/// Bit mask to extract key code from key value.
	KEY_CODE = 0xFFFF,
	
	/// Bit mask to extract modifiers from key value.
	MODIFIERS = 0xFFFF0000,
}


///
enum MouseButtons: uint // docmain
{
	/// No mouse buttons specified.
	NONE =      0,
	
	LEFT = GdkModifierType.GDK_BUTTON1_MASK, ///
	RIGHT = GdkModifierType.GDK_BUTTON3_MASK, /// ditto
	MIDDLE = GdkModifierType.GDK_BUTTON2_MASK, /// ditto
}


///
interface IButtonControl // docmain
{
	///
	DialogResult dialogResult(); // getter
	/// ditto
	void dialogResult(DialogResult); // setter
	
	///
	void notifyDefault(bool); // True if default button.
	
	///
	void performClick(); // Raise click event.
}


///
enum DialogResult: ubyte // docmain
{
	NONE, ///
	
	ABORT, ///
	CANCEL, ///
	IGNORE, ///
	NO, ///
	OK, ///
	RETRY, ///
	YES, ///
	
	// Extra.
	CLOSE,
	HELP,
}


///
enum SortOrder: ubyte
{
	NONE, ///
	
	ASCENDING, ///
	DESCENDING, /// ditto
}


///
enum View: ubyte
{
	LARGE_ICON, ///
	SMALL_ICON, ///
	LIST, ///
	DETAILS, ///
}


///
enum ItemBoundsPortion: ubyte
{
	ENTIRE, ///
	ICON, ///
	ITEM_ONLY, /// Excludes other stuff like check boxes.
	LABEL, /// Item's text.
}


///
enum ItemActivation: ubyte
{
	STANDARD, ///
	ONE_CLICK, ///
	TWO_CLICK, ///
}


///
enum ColumnHeaderStyle: ubyte
{
	CLICKABLE, ///
	NONCLICKABLE, ///
	NONE, /// No column header.
}


///
enum BorderStyle: ubyte
{
	NONE, ///
	
	FIXED_3D, ///
	FIXED_SINGLE, /// ditto
}


///
enum FlatStyle: ubyte
{
	STANDARD, ///
	FLAT, /// ditto
	POPUP, /// ditto
	SYSTEM, /// ditto
}


///
enum Appearance: ubyte
{
	NORMAL, ///
	BUTTON, ///
}


///
enum ContentAlignment: ubyte
{
	TOP_LEFT, ///
	BOTTOM_CENTER, ///
	BOTTOM_LEFT, ///
	BOTTOM_RIGHT, ///
	MIDDLE_CENTER, ///
	MIDDLE_LEFT, ///
	MIDDLE_RIGHT, ///
	TOP_CENTER, ///
	TOP_RIGHT, ///
}


///
enum CharacterCasing: ubyte
{
	NORMAL, ///
	LOWER, ///
	UPPER, ///
}


///
// Not flags.
enum ScrollBars: ubyte
{
	NONE, ///
	
	HORIZONTAL, ///
	VERTICAL, /// ditto
	BOTH, /// ditto
}


///
enum HorizontalAlignment: ubyte
{
	LEFT, ///
	RIGHT, /// ditto
	CENTER, /// ditto
}


///
enum DrawMode: ubyte
{
	NORMAL, ///
	OWNER_DRAW_FIXED, ///
	OWNER_DRAW_VARIABLE, /// ditto
}


///
enum DrawItemState: uint
{
	NONE = 0, ///
	SELECTED = 1, /// ditto
	DISABLED = 2, /// ditto
	CHECKED = 8, /// ditto
	FOCUS = 0x10, /// ditto
	DEFAULT = 0x20, /// ditto
	HOT_LIGHT = 0x40, /// ditto
	NO_ACCELERATOR = 0x80, /// ditto
	INACTIVE = 0x100, /// ditto
	NO_FOCUS_RECT = 0x200, /// ditto
	COMBO_BOX_EDIT = 0x1000, /// ditto
}


///
enum RightToLeft: ubyte
{
	INHERIT = 2, ///
	YES = 1, /// ditto
	NO = 0, /// ditto
}


///
class PaintEventArgs: EventArgs
{
	///
	this(Graphics graphics, Rect clipRect)
	{
		g = graphics;
		cr = clipRect;
	}
	
	
	///
	final Graphics graphics() // getter
	{
		return g;
	}
	
	
	///
	final Rect clipRectangle() // getter
	{
		return cr;
	}
	
	
	private:
	Graphics g;
	Rect cr;
}


///
class CancelEventArgs: EventArgs
{
	///
	// Initialize cancel to false.
	this()
	{
		cncl = false;
	}
	
	/// ditto
	this(bool cancel)
	{
		cncl = cancel;
	}
	
	
	///
	final void cancel(bool byes) // setter
	{
		cncl = byes;
	}
	
	/// ditto
	final bool cancel() // getter
	{
		return cncl;
	}
	
	
	private:
	bool cncl;
}


///
class KeyEventArgs: EventArgs
{
	///
	this(Keys keys)
	{
		ks = keys;
	}
	
	
	///
	final bool alt() // getter
	{
		return (ks & Keys.ALT) != 0;
	}
	
	
	///
	final bool control() // getter
	{
		return (ks & Keys.CONTROL) != 0;
	}
	
	
	///
	final void handled(bool byes) // setter
	{
		hand = byes;
	}
	
	///
	final bool handled() // getter
	{
		return hand;
	}
	
	
	///
	final Keys keyCode() // getter
	{
		return ks & Keys.KEY_CODE;
	}
	
	
	///
	final Keys keyData() // getter
	{
		return ks;
	}
	
	
	///
	// -keyData- as an int.
	final int keyValue() // getter
	{
		return cast(int)ks;
	}
	
	
	///
	final Keys modifiers() // getter
	{
		return ks & Keys.MODIFIERS;
	}
	
	
	///
	final bool shift() // getter
	{
		return (ks & Keys.SHIFT) != 0;
	}
	
	
	private:
	Keys ks;
	bool hand = false;
}


///
class MouseEventArgs: EventArgs
{
	///
	// -delta- is mouse wheel rotations.
	this(MouseButtons button, int clicks, int x, int y, int delta)
	{
		btn = button;
		clks = clicks;
		_x = x;
		_y = y;
		dlt = delta;
	}
	
	
	///
	final MouseButtons button() // getter
	{
		return btn;
	}
	
	
	///
	final int clicks() // getter
	{
		return clks;
	}
	
	
	///
	final int delta() // getter
	{
		return dlt;
	}
	
	
	///
	final int x() // getter
	{
		return _x;
	}
	
	
	///
	final int y() // getter
	{
		return _y;
	}
	
	
	private:
	MouseButtons btn;
	int clks;
	int _x, _y;
	int dlt;
}


///
class LabelEditEventArgs: EventArgs
{
	///
	this(int index)
	{
		
	}
	
	/// ditto
	this(int index, char[] labelText)
	{
		this.idx = index;
		this.ltxt = labelText;
	}
	
	
	///
	final void cancelEdit(bool byes) // setter
	{
		cancl = byes;
	}
	
	/// ditto
	final bool cancelEdit() // getter
	{
		return cancl;
	}
	
	
	///
	// The text of the label's edit.
	final char[] label() // getter
	{
		return ltxt;
	}
	
	
	///
	// Gets the item's index.
	final int item() // getter
	{
		return idx;
	}
	
	
	private:
	int idx;
	char[] ltxt;
	bool cancl = false;
}


///
class ColumnClickEventArgs: EventArgs
{
	///
	this(int col)
	{
		this.col = col;
	}
	
	
	///
	final int column() // getter
	{
		return col;
	}
	
	
	private:
	int col;
}


///
class DrawItemEventArgs: EventArgs
{
	///
	this(Graphics g, Font f, Rect r, int i, DrawItemState dis)
	{
		this(g, f, r, i , dis, Color.empty, Color.empty);
	}
	
	/// ditto
	this(Graphics g, Font f, Rect r, int i, DrawItemState dis, Color fc, Color bc)
	{
		gpx = g;
		fnt = f;
		rect = r;
		idx = i;
		distate = dis;
		fcolor = fc;
		bcolor = bc;
	}
	
	
	///
	final Color backColor() // getter
	{
		return bcolor;
	}
	
	
	///
	final Rect bounds() // getter
	{
		return rect;
	}
	
	
	///
	final Font font() // getter
	{
		return fnt;
	}
	
	
	///
	final Color foreColor() // getter
	{
		return fcolor;
	}
	
	
	///
	final Graphics graphics() // getter
	{
		return gpx;
	}
	
	
	///
	final int index() // getter
	{
		return idx;
	}
	
	
	///
	final DrawItemState state() // getter
	{
		return distate;
	}
	
	
	///
	void drawBackground()
	{
		gpx.fillRectangle(bcolor, rect);
	}
	
	
	///
	void drawFocusRectangle()
	{
		if(distate & DrawItemState.FOCUS)
		{
			/+ // To-do: ...
			RECT _rect;
			rect.getRect(&_rect);
			DrawFocusRect(gpx.handle, &_rect);
			+/
		}
	}
	
	
	private:
	Graphics gpx;
	Font fnt; // Suggestion; the parent's font.
	Rect rect;
	int idx;
	DrawItemState distate;
	Color fcolor, bcolor; // Suggestion; depends on item state.
}


///
class MeasureItemEventArgs: EventArgs
{
	///
	this(Graphics g, int index, int itemHeight)
	{
		gpx = g;
		idx = index;
		iheight = itemHeight;
	}
	
	/// ditto
	this(Graphics g, int index)
	{
		this(g, index, 0);
	}
	
	
	///
	final Graphics graphics() // getter
	{
		return gpx;
	}
	
	
	///
	final int index() // getter
	{
		return idx;
	}
	
	
	///
	final void itemHeight(int height) // setter
	{
		iheight = height;
	}
	
	/// ditto
	final int itemHeight() // getter
	{
		return iheight;
	}
	
	
	///
	final void itemWidth(int width) // setter
	{
		iwidth = width;
	}
	
	/// ditto
	final int itemWidth() // getter
	{
		return iwidth;
	}
	
	
	private:
	Graphics gpx;
	int idx, iheight, iwidth = 0;
}


/+
///
class Cursor // docmain
{
	private static Cursor _cur;
	
	
	/+
	// Used internally.
	this(HCURSOR hcur, bool owned = true)
	{
		this.hcur = hcur;
		this.owned = owned;
	}
	+/
	
	
	~this()
	{
		if(owned)
			dispose();
	}
	
	
	///
	void dispose()
	{
		//DestroyCursor(hcur);
		// To-do: ...
		hcur = HCURSOR.init;
	}
	
	
	///
	static void current(Cursor cur) // setter
	{
		// Keep a reference so that it doesn't get garbage collected until set again.
		_cur = cur;
		
		//SetCursor(cur ? cur.hcur : HCURSOR.init);
		// To-do: ...
	}
	
	/// ditto
	static Cursor current() // getter
	{
		/+
		HCURSOR hcur = GetCursor();
		return hcur ? new Cursor(hcur, false) : null;
		+/
		// To-do: ...
	}
	
	
	///
	static void clip(Rect r) // setter
	{
		RECT rect;
		r.getRect(&rect);
		//ClipCursor(&rect);
		// To-do: ...
	}
	
	/// ditto
	static Rect clip() // getter
	{
		RECT rect;
		//GetClipCursor(&rect);
		// To-do: ...
		return Rect(&rect);
	}
	
	
	///
	final HCURSOR handle() // getter
	{
		return hcur;
	}
	
	
	///
	// Uses the actual size.
	final void draw(Graphics g, Point pt)
	{
		//DrawIconEx(g.handle, pt.x, pt.y, hcur, 0, 0, 0, HBRUSH.init, DI_NORMAL);
		// To-do: ...
	}
	
	
	///
	final void drawStretched(Graphics g, Rect r)
	{
		/+
		// DrawIconEx operates differently if the width or height is zero
		// so bail out if zero and pretend the zero size cursor was drawn.
		int width = r.width;
		if(!width)
			return;
		int height = r.height;
		if(!height)
			return;
		
		DrawIconEx(g.handle, r.x, r.y, hcur, width, height, 0, HBRUSH.init, DI_NORMAL);
		+/
		// To-do: ...
	}
	
	
	override int opEquals(Object o)
	{
		Cursor cur = cast(Cursor)o;
		if(!cur)
			return 0; // Not equal.
		return opEquals(cur);
	}
	
	
	int opEquals(Cursor cur)
	{
		return hcur == cur.hcur;
	}
	
	
	/// Show/hide the current mouse cursor; reference counted.
	// show/hide are ref counted.
	static void hide()
	{
		//ShowCursor(false);
		// To-do: ...
	}
	
	/// ditto
	// show/hide are ref counted.
	static void show()
	{
		//ShowCursor(true);
		// To-do: ...
	}
	
	
	/// The position of the current mouse cursor.
	static void position(Point pt) // setter
	{
		//SetCursorPos(pt.x, pt.y);
		// To-do: ...
	}
	
	/// ditto
	static Point position() // getter
	{
		Point pt;
		//GetCursorPos(&pt.point);
		// To-do: ...
		return pt;
	}
	
	
	private:
	//HCURSOR hcur;
	bool owned = true;
}
+/


/+
///
class Cursors // docmain
{
	private this() {}
	
	
	static:
	
	/+ // To-do: ...
	///
	Cursor appStarting() // getter
	{ return new Cursor(LoadCursorA(HINSTANCE.init, IDC_APPSTARTING), false); }
	
	///
	Cursor arrow() // getter
	{ return new Cursor(LoadCursorA(HINSTANCE.init, IDC_ARROW), false); }
	
	///
	Cursor cross() // getter
	{ return new Cursor(LoadCursorA(HINSTANCE.init, IDC_CROSS), false); }
	
	///
	//Cursor default() // getter
	Cursor defaultCursor() // getter
	{ return arrow; }
	
	///
	Cursor hand() // getter
	{
		version(SUPPORTS_HAND_CURSOR) // Windows 98+
		{
			return new Cursor(LoadCursorA(HINSTANCE.init, IDC_HAND), false);
		}
		else
		{
			static HCURSOR hcurHand;
			
			if(!hcurHand)
			{
				hcurHand = LoadCursorA(HINSTANCE.init, IDC_HAND);
				if(!hcurHand) // Must be Windows 95, so load the cursor from winhlp32.exe.
				{
					UINT len;
					char[MAX_PATH] winhlppath = void;
					
					len = GetWindowsDirectoryA(winhlppath.ptr, winhlppath.length - 16);
					if(!len || len > winhlppath.length - 16)
					{
						load_failed:
						return arrow; // Just fall back to a normal arrow.
					}
					strcpy(winhlppath.ptr + len, "\\winhlp32.exe");
					
					HINSTANCE hinstWinhlp;
					hinstWinhlp = LoadLibraryExA(winhlppath.ptr, HANDLE.init, LOAD_LIBRARY_AS_DATAFILE);
					if(!hinstWinhlp)
						goto load_failed;
					
					HCURSOR hcur;
					hcur = LoadCursorA(hinstWinhlp, cast(char*)106);
					if(!hcur) // No such cursor resource.
					{
						FreeLibrary(hinstWinhlp);
						goto load_failed;
					}
					hcurHand = CopyCursor(hcur);
					if(!hcurHand)
					{
						FreeLibrary(hinstWinhlp);
						//throw new DflException("Unable to copy cursor resource");
						goto load_failed;
					}
					
					FreeLibrary(hinstWinhlp);
				}
			}
			
			assert(hcurHand);
			// Copy the cursor and own it here so that it's safe to dispose it.
			return new Cursor(CopyCursor(hcurHand));
		}
	}
	
	///
	Cursor help() // getter
	{
		HCURSOR hcur;
		hcur = LoadCursorA(HINSTANCE.init, IDC_HELP);
		if(!hcur) // IDC_HELP might not be supported on Windows 95, so fall back to a normal arrow.
			return arrow;
		return new Cursor(hcur);
	}
	
	///
	Cursor hSplit() // getter
	{
		// ...
		return sizeNS;
	}
	
	/// ditto
	Cursor vSplit() // getter
	{
		// ...
		return sizeWE;
	}
	
	
	///
	Cursor iBeam() // getter
	{ return new Cursor(LoadCursorA(HINSTANCE.init, IDC_IBEAM), false); }
	
	///
	Cursor no() // getter
	{ return new Cursor(LoadCursorA(HINSTANCE.init, IDC_NO), false); }
	
	
	///
	Cursor sizeAll() // getter
	{ return new Cursor(LoadCursorA(HINSTANCE.init, IDC_SIZEALL), false); }
	
	/// ditto
	Cursor sizeNESW() // getter
	{ return new Cursor(LoadCursorA(HINSTANCE.init, IDC_SIZENESW), false); }
	
	/// ditto
	Cursor sizeNS() // getter
	{ return new Cursor(LoadCursorA(HINSTANCE.init, IDC_SIZENS), false); }
	
	/// ditto
	Cursor sizeNWSE() // getter
	{ return new Cursor(LoadCursorA(HINSTANCE.init, IDC_SIZENWSE), false); }
	
	/// ditto
	Cursor sizeWE() // getter
	{ return new Cursor(LoadCursorA(HINSTANCE.init, IDC_SIZEWE), false); }
	
	
	/+
	///
	// Insertion point.
	Cursor upArrow() // getter
	{
		// ...
	}
	+/
	
	///
	Cursor waitCursor() // getter
	{ return new Cursor(LoadCursorA(HINSTANCE.init, IDC_WAIT), false); }
	+/
}
+/

