// Written by Christopher E. Miller
// See the included license.txt for copyright and license details.


///
module dfl.control;

private import dfl.internal.dlib, dfl.internal.clib;
	
private import dfl.base, dfl.form, dfl.drawing;
private import dfl.internal.winapi, dfl.application, dfl.event, dfl.label;
private import dfl.internal.wincom, dfl.internal.utf, dfl.collections, dfl.internal.com;
private import core.memory;

version(NO_DRAG_DROP)
	version = DFL_NO_DRAG_DROP;

version(DFL_NO_DRAG_DROP)
{
}
else
{
	private import dfl.data;
}

version(DFL_NO_MENUS)
{
}
else
{
	private import dfl.menu;
}

//version = RADIO_GROUP_LAYOUT;
version = DFL_NO_ZOMBIE_FORM;


///
enum AnchorStyles: ubyte
{
	NONE = 0, ///
	TOP = 1, /// ditto
	BOTTOM = 2, /// ditto
	LEFT = 4, /// ditto
	RIGHT = 8, /// ditto
	
	/+
	// Extras:
	VERTICAL = TOP | BOTTOM,
	HORIZONTAL = LEFT | RIGHT,
	ALL = TOP | BOTTOM | LEFT | RIGHT,
	DEFAULT = TOP | LEFT,
	TOP_LEFT = TOP | LEFT,
	TOP_RIGHT = TOP | RIGHT,
	BOTTOM_LEFT = BOTTOM | LEFT,
	BOTTOM_RIGHT = BOTTOM | RIGHT,
	+/
}


/// Flags for setting control bounds.
enum BoundsSpecified: ubyte
{
	NONE = 0, ///
	X = 1, /// ditto
	Y = 2, /// ditto
	LOCATION = 1 | 2, /// ditto
	WIDTH = 4, /// ditto
	HEIGHT = 8, /// ditto
	SIZE = 4 | 8, /// ditto
	ALL = 1 | 2 | 4 | 8, /// ditto
}


/// Layout docking style.
enum DockStyle: ubyte
{
	NONE, ///
	BOTTOM, ///
	FILL, ///
	LEFT, ///
	RIGHT, ///
	TOP, ///
}


private
{
	struct GetZIndex
	{
		Control find;
		int index = -1;
		private int _tmp = 0;
	}
	
	
	extern(Windows) BOOL getZIndexCallback(HWND hwnd, LPARAM lparam)
	{
		GetZIndex* gzi = cast(GetZIndex*)lparam;
		if(hwnd == gzi.find.hwnd)
		{
			gzi.index = gzi._tmp;
			return FALSE; // Stop, found it.
		}
		
		Control ctrl;
		ctrl = Control.fromHandle(hwnd);
		if(ctrl && ctrl.parent is gzi.find.parent)
		{
			gzi._tmp++;
		}
		
		return TRUE; // Keep looking.
	}
}


/// Effect flags for drag/drop operations.
enum DragDropEffects: DWORD
{
	NONE = 0, ///
	COPY = 1, /// ditto
	MOVE = 2, /// ditto
	LINK = 4, /// ditto
	SCROLL = 0x80000000, /// ditto
	ALL = COPY | MOVE | LINK | SCROLL, /// ditto
}


/// Drag/drop action.
enum DragAction: HRESULT
{
	CONTINUE = S_OK, ///
	CANCEL = DRAGDROP_S_CANCEL, /// ditto
	DROP = DRAGDROP_S_DROP, /// ditto
}


// Flags.
deprecated enum UICues: uint
{
	NONE = 0,
	SHOW_FOCUS = 1,
	SHOW_KEYBOARD = 2,
	SHOWN = SHOW_FOCUS | SHOW_KEYBOARD,
	CHANGE_FOCUS = 4,
	CHANGE_KEYBOARD = 8, // Key mnemonic underline cues are on.
	CHANGED = CHANGE_FOCUS | CHANGE_KEYBOARD,
}


// May be OR'ed together.
/// Style flags of a control.
enum ControlStyles: uint
{
	NONE = 0, ///
	
	CONTAINER_CONTROL =                0x1, /// ditto
	
	// TODO: implement.
	USER_PAINT =                       0x2, /// ditto
	
	OPAQUE =                           0x4, /// ditto
	RESIZE_REDRAW =                    0x10, /// ditto
	//FIXED_WIDTH =                      0x20, // TODO: implement.
	//FIXED_HEIGHT =                     0x40, // TODO: implement.
	STANDARD_CLICK =                   0x100, /// ditto
	SELECTABLE =                       0x200, /// ditto
	
	// TODO: implement.
	USER_MOUSE =                       0x400, ///  ditto
	
	//SUPPORTS_TRANSPARENT_BACK_COLOR =  0x800, // Only if USER_PAINT and parent is derived from Control. TODO: implement.
	STANDARD_DOUBLE_CLICK =            0x1000, /// ditto
	ALL_PAINTING_IN_WM_PAINT =         0x2000, /// ditto
	CACHE_TEXT =                       0x4000, /// ditto
	ENABLE_NOTIFY_MESSAGE =            0x8000, // deprecated. Calls onNotifyMessage() for every message.
	//DOUBLE_BUFFER =                    0x10000, // TODO: implement.
	
	WANT_TAB_KEY = 0x01000000,
	WANT_ALL_KEYS = 0x02000000,
}


/// Control creation parameters.
struct CreateParams
{
	Dstring className; ///
	Dstring caption; /// ditto
	void* param; /// ditto
	HWND parent; /// ditto
	HMENU menu; /// ditto
	HINSTANCE inst; /// ditto
	int x; /// ditto
	int y; /// ditto
	int width; /// ditto
	int height; /// ditto
	DWORD classStyle; /// ditto
	DWORD exStyle; /// ditto
	DWORD style; /// ditto
}


deprecated class UICuesEventArgs: EventArgs
{
	deprecated:
	
	this(UICues uic)
	{
		chg = uic;
	}
	
	
	final UICues changed() // getter
	{
		return chg;
	}
	
	
	final bool changeFocus()
	{
		return (chg & UICues.CHANGE_FOCUS) != 0;
	}
	
	
	final bool changeKeyboard()
	{
		return (chg & UICues.CHANGE_KEYBOARD) != 0;
	}
	
	
	final bool showFocus()
	{
		return (chg & UICues.SHOW_FOCUS) != 0;
	}
	
	
	final bool showKeyboard()
	{
		return (chg & UICues.SHOW_KEYBOARD) != 0;
	}
	
	
	private:
	UICues chg;
}


///
class ControlEventArgs: EventArgs
{
	///
	this(Control ctrl)
	{
		this.ctrl = ctrl;
	}
	
	
	///
	final @property Control control() // getter
	{
		return ctrl;
	}
	
	
	private:
	Control ctrl;
}


///
class HelpEventArgs: EventArgs
{
	///
	this(Point mousePos)
	{
		mpos = mousePos;
	}
	
	
	///
	final @property void handled(bool byes) // setter
	{
		hand = byes;
	}
	
	/// ditto
	final @property bool handled() // getter
	{
		return hand;
	}
	
	
	///
	final @property Point mousePos() // getter
	{
		return mpos;
	}
	
	
	private:
	Point mpos;
	bool hand = false;
}


///
class InvalidateEventArgs: EventArgs
{
	///
	this(Rect invalidRect)
	{
		ir = invalidRect;
	}
	
	
	///
	final @property Rect invalidRect() // getter
	{
		return ir;
	}
	
	
	private:
	Rect ir;
}


// ///
// New dimensions before resizing.
deprecated class BeforeResizeEventArgs: EventArgs
{
	deprecated:
	
	///
	this(int width, int height)
	{
		this.w = width;
		this.h = height;
	}
	
	
	///
	void width(int cx) // setter
	{
		w = cx;
	}
	
	/// ditto
	int width() // getter
	{
		return w;
	}
	
	
	///
	void height(int cy) // setter
	{
		h = cy;
	}
	
	/// ditto
	int height() // getter
	{
		return h;
	}
	
	
	private:
	int w, h;
}


///
class LayoutEventArgs: EventArgs
{
	///
	this(Control affectedControl)
	{
		ac = affectedControl;
	}
	
	
	///
	final @property Control affectedControl() // getter
	{
		return ac;
	}
	
	
	private:
	Control ac;
}


version(DFL_NO_DRAG_DROP) {} else
{
	///
	class DragEventArgs: EventArgs
	{
		///
		this(dfl.data.IDataObject dataObj, int keyState, int x, int y,
			DragDropEffects allowedEffect, DragDropEffects effect)
		{
			_dobj = dataObj;
			_keyState = keyState;
			_x = x;
			_y = y;
			_allowedEffect = allowedEffect;
			_effect = effect;
		}
		
		
		///
		final @property DragDropEffects allowedEffect() // getter
		{
			return _allowedEffect;
		}
		
		
		///
		final @property void effect(DragDropEffects newEffect) // setter
		{
			_effect = newEffect;
		}
		
		
		/// ditto
		final @property DragDropEffects effect() // getter
		{
			return _effect;
		}
		
		
		///
		final @property dfl.data.IDataObject data() // getter
		{
			return _dobj;
		}
		
		
		///
		// State of ctrl, alt, shift, and mouse buttons.
		final @property int keyState() // getter
		{
			return _keyState;
		}
		
		
		///
		final @property int x() // getter
		{
			return _x;
		}
		
		
		///
		final @property int y() // getter
		{
			return _y;
		}
		
		
		private:
		dfl.data.IDataObject _dobj;
		int _keyState;
		int _x, _y;
		DragDropEffects _allowedEffect, _effect;
	}
	
	
	///
	class GiveFeedbackEventArgs: EventArgs
	{
		///
		this(DragDropEffects effect, bool useDefaultCursors)
		{
			_effect = effect;
			udefcurs = useDefaultCursors;
		}
		
		
		///
		final @property DragDropEffects effect() // getter
		{
			return _effect;
		}
		
		
		///
		final @property void useDefaultCursors(bool byes) // setter
		{
			udefcurs = byes;
		}
		
		/// ditto
		final @property bool useDefaultCursors() // getter
		{
			return udefcurs;
		}
		
		
		private:
		DragDropEffects _effect;
		bool udefcurs;
	}
	
	
	///
	class QueryContinueDragEventArgs: EventArgs
	{
		///
		this(int keyState, bool escapePressed, DragAction action)
		{
			_keyState = keyState;
			escp = escapePressed;
			_action = action;
		}
		
		
		///
		final @property void action(DragAction newAction) // setter
		{
			_action = newAction;
		}
		
		/// ditto
		final @property DragAction action() // getter
		{
			return _action;
		}
		
		
		///
		final @property bool escapePressed() // getter
		{
			return escp;
		}
		
		
		///
		// State of ctrl, alt and shift.
		final @property int keyState() // getter
		{
			return _keyState;
		}
		
		
		private:
		int _keyState;
		bool escp;
		DragAction _action;
	}
}


version(NO_WINDOWS_HUNG_WORKAROUND)
{
}
else
{
	version = WINDOWS_HUNG_WORKAROUND;
}
debug
{
	version=_DFL_WINDOWS_HUNG_WORKAROUND;
}
version(WINDOWS_HUNG_WORKAROUND)
{
	version=_DFL_WINDOWS_HUNG_WORKAROUND;
}

version(_DFL_WINDOWS_HUNG_WORKAROUND)
{
	class WindowsHungDflException: DflException
	{
		this(Dstring msg)
		{
			super(msg);
		}
	}
}

alias BOOL delegate(HWND) EnumWindowsCallback;
package struct EnumWindowsCallbackData
{
	EnumWindowsCallback callback;
	DThrowable exception;
}


// Callback for EnumWindows() and EnumChildWindows().
private extern(Windows) BOOL enumingWindows(HWND hwnd, LPARAM lparam) nothrow
{
	auto cbd = *(cast(EnumWindowsCallbackData*)lparam);
	try
	{
		return cbd.callback(hwnd);
	}
	catch (DThrowable e)
	{
		cbd.exception = e;
		return FALSE;
	}
	assert(0);
}


private struct Efi
{
	HWND hwParent;
	EnumWindowsCallbackData cbd;
}


// Callback for EnumChildWindows(). -lparam- = pointer to Efi;
private extern(Windows) BOOL enumingFirstWindows(HWND hwnd, LPARAM lparam) nothrow
{
	auto efi = cast(Efi*)lparam;
	if(efi.hwParent == GetParent(hwnd))
	{
		try
		{
			return efi.cbd.callback(hwnd);
		}
		catch (DThrowable e)
		{
			efi.cbd.exception = e;
			return FALSE;
		}
	}
	return TRUE;
}


package BOOL enumWindows(EnumWindowsCallback dg)
{
	EnumWindowsCallbackData cbd;
	cbd.callback = dg;
	scope (exit) if (cbd.exception) throw cbd.exception;
	static assert((&cbd).sizeof <= LPARAM.sizeof);
	return EnumWindows(&enumingWindows, cast(LPARAM)&cbd);
}


package BOOL enumChildWindows(HWND hwParent, EnumWindowsCallback dg)
{
	EnumWindowsCallbackData cbd;
	cbd.callback = dg;
	scope (exit) if (cbd.exception) throw cbd.exception;
	static assert((&cbd).sizeof <= LPARAM.sizeof);
	return EnumChildWindows(hwParent, &enumingWindows, cast(LPARAM)&cbd);
}


// Only the parent's children, not its children.
package BOOL enumFirstChildWindows(HWND hwParent, EnumWindowsCallback dg)
{
	Efi efi;
	efi.hwParent = hwParent;
	efi.cbd.callback = dg;
	scope (exit) if (efi.cbd.exception) throw efi.cbd.exception;
	return EnumChildWindows(hwParent, &enumingFirstWindows, cast(LPARAM)&efi);
}


///
enum ControlFont: ubyte
{
	COMPATIBLE, ///
	OLD, /// ditto
	NATIVE, /// ditto
}


debug
{
	import std.string;
}


/// Control class.
class Control: DObject, IWindow // docmain
{
	///
	static class ControlCollection
	{
		protected this(Control owner)
		{
			_owner = owner;
		}
		
		
		deprecated alias length count;
		
		///
		@property int length() // getter
		{
			if(_owner.isHandleCreated)
			{
				// Inefficient :(
				uint len = 0;
				foreach(Control ctrl; this)
				{
					len++;
				}
				return len;
			}
			else
			{
				return children.length;
			}
		}
		
		
		///
		@property Control opIndex(int i) // getter
		{
			if(_owner.isHandleCreated)
			{
				int oni = 0;
				foreach(Control ctrl; this)
				{
					if(oni == i)
						return ctrl;
					oni++;
				}
				// Index out of bounds, bad things happen.
				assert(0);
			}
			else
			{
				return children[i];
			}
		}
		
		
		///
		void add(Control ctrl)
		{
			ctrl.parent = _owner;
		}
		
		
		///
		// opIn ?
		bool contains(Control ctrl)
		{
			return indexOf(ctrl) != -1;
		}
		
		
		///
		int indexOf(Control ctrl)
		{
			if(_owner.isHandleCreated)
			{
				int i = 0;
				int foundi = -1;
				
				
				BOOL enuming(HWND hwnd)
				{
					if(hwnd == ctrl.handle)
					{
						foundi = i;
						return false; // Stop.
					}
					
					i++;
					return true; // Continue.
				}
				
				
				enumFirstChildWindows(_owner.handle, &enuming);
				return foundi;
			}
			else
			{
				foreach(int i, Control onCtrl; children)
				{
					if(onCtrl == ctrl)
						return i;
				}
				return -1;
			}
		}
		
		
		///
		void remove(Control ctrl)
		{
			if(_owner.isHandleCreated)
			{
				_removeCreated(ctrl.handle);
			}
			else
			{
				int i = indexOf(ctrl);
				if(i != -1)
					_removeNotCreated(i);
			}
		}
		
		
		private void _removeCreated(HWND hwnd)
		{
			DestroyWindow(hwnd); // ?
		}
		
		
		package void _removeNotCreated(int i)
		{
			if(!i)
				children = children[1 .. children.length];
			else if(i == children.length - 1)
				children = children[0 .. i];
			else
				children = children[0 .. i] ~ children[i + 1 .. children.length];
		}
		
		
		///
		void removeAt(int i)
		{
			if(_owner.isHandleCreated)
			{
				int ith = 0;
				HWND hwndith;
				
				
				BOOL enuming(HWND hwnd)
				{
					if(ith == i)
					{
						hwndith = hwnd;
						return false; // Stop.
					}
					
					ith++;
					return true; // Continue.
				}
				
				
				enumFirstChildWindows(_owner.handle, &enuming);
				if(hwndith)
					_removeCreated(hwndith);
			}
			else
			{
				_removeNotCreated(i);
			}
		}
		
		
		protected final @property Control owner() // getter
		{
			return _owner;
		}
		
		
		///
		int opApply(int delegate(ref Control) dg)
		{
			int result = 0;
			
			if(_owner.isHandleCreated)
			{
				BOOL enuming(HWND hwnd)
				{
					Control ctrl = fromHandle(hwnd);
					if(ctrl)
					{
						result = dg(ctrl);
						if(result)
							return false; // Stop.
					}
					
					return true; // Continue.
				}
				
				
				enumFirstChildWindows(_owner.handle, &enuming);
			}
			else
			{
				foreach(Control ctrl; children)
				{
					result = dg(ctrl);
					if(result)
						break;
				}
			}
			
			return result;
		}
		
		mixin OpApplyAddIndex!(opApply, Control);
		
		
		package:
		Control _owner;
		Control[] children; // Only valid if -owner- isn't created yet (or is recreating).
		
		
		/+
		final void _array_swap(int ifrom, int ito)
		{
			if(ifrom == ito ||
				ifrom < 0 || ito < 0 ||
				ifrom >= length || ito >= length)
				return;
			
			Control cto;
			cto = children[ito];
			children[ito] = children[ifrom];
			children[ifrom] = cto;
		}
		+/
		
		
		final void _simple_front_one(int i)
		{
			if(i < 0 || i >= length - 1)
				return;
			
			children = children[0 .. i] ~ children[i + 1 .. i + 2] ~ children[i .. i + 1] ~ children[i + 2 .. children.length];
		}
		
		
		final void _simple_front_one(Control c)
		{
			return _simple_front_one(indexOf(c));
		}
		
		
		final void _simple_back_one(int i)
		{
			if(i <= 0 || i >= length)
				return;
			
			children = children[0 .. i - 1] ~ children[i + 1 .. i + 2] ~ children[i .. i + 1] ~ children[i + 2 .. children.length];
		}
		
		
		final void _simple_back_one(Control c)
		{
			return _simple_back_one(indexOf(c));
		}
		
		
		final void _simple_back(int i)
		{
			if(i <= 0 || i >= length)
				return;
			
			children = children[i .. i + 1] ~ children[0 .. i] ~ children[i + 1 .. children.length];
		}
		
		
		final void _simple_back(Control c)
		{
			return _simple_back(indexOf(c));
		}
		
		
		final void _simple_front(int i)
		{
			if(i < 0 || i >= length - 1)
				return;
			
			children = children[0 .. i] ~ children[i + 1 .. children.length] ~ children[i .. i + 1];
		}
		
		
		final void _simple_front(Control c)
		{
			return _simple_front(indexOf(c));
		}
	}
	
	
	private void _ctrladded(ControlEventArgs cea)
	{
		if(Application._compat & DflCompat.CONTROL_PARENT_096)
		{
			if(!(_exStyle() & WS_EX_CONTROLPARENT))
			{
				if(!(cbits & CBits.FORM))
				{
					//if((cea.control._style() & WS_TABSTOP) || (cea.control._exStyle() & WS_EX_CONTROLPARENT))
						_exStyle(_exStyle() | WS_EX_CONTROLPARENT);
				}
			}
		}
		else
		{
			assert(getStyle(ControlStyles.CONTAINER_CONTROL), "Control added to non-container parent");
		}
		
		onControlAdded(cea);
	}
	
	
	private void _ctrlremoved(ControlEventArgs cea)
	{
		alayout(cea.control);
		
		onControlRemoved(cea);
	}
	
	
	///
	protected void onControlAdded(ControlEventArgs cea)
	{
		controlAdded(this, cea);
	}
	
	
	///
	protected void onControlRemoved(ControlEventArgs cea)
	{
		controlRemoved(this, cea);
	}
	
	
	///
	@property final HWindow handle() // IWindow getter
	{
		if(!isHandleCreated)
		{
			debug(APP_PRINT)
				cprintf("Control created due to handle request.\n");
			
			createHandle();
		}
		
		return hwnd;
	}
	
	
	version(DFL_NO_DRAG_DROP) {} else
	{
		///
		@property void allowDrop(bool byes) // setter
		{
			/+
			if(dyes)
				_exStyle(_exStyle() | WS_EX_ACCEPTFILES);
			else
				_exStyle(_exStyle() & ~WS_EX_ACCEPTFILES);
			+/
			
			if(byes)
			{
				if(!droptarget)
				{
					droptarget = new DropTarget(this);
					if(isHandleCreated)
					{
						switch(RegisterDragDrop(hwnd, droptarget))
						{
							case S_OK:
							case DRAGDROP_E_ALREADYREGISTERED: // Hmm.
								break;
							
							default:
								droptarget = null;
								throw new DflException("Unable to register drag-drop");
						}
					}
				}
			}
			else
			{
				delete droptarget;
				droptarget = null;
				RevokeDragDrop(hwnd);
			}
		}
		
		/// ditto
		@property bool allowDrop() // getter
		{
			/+
			return (_exStyle() & WS_EX_ACCEPTFILES) != 0;
			+/
			
			return droptarget !is null;
		}
	}
	
	
	/+
	deprecated void anchor(AnchorStyles a) // setter
	{
		/+
		anch = a;
		if(!(anch & (AnchorStyles.LEFT | AnchorStyles.RIGHT)))
			anch |= AnchorStyles.LEFT;
		if(!(anch & (AnchorStyles.TOP | AnchorStyles.BOTTOM)))
			anch |= AnchorStyles.TOP;
		+/
		
		sdock = DockStyle.NONE; // Can't be set at the same time.
	}
	
	
	deprecated AnchorStyles anchor() // getter
	{
		//return anch;
		return cast(AnchorStyles)(AnchorStyles.LEFT | AnchorStyles.TOP);
	}
	+/
	
	
	private void _propagateBackColorAmbience()
	{
		Color bc;
		bc = backColor;
		
		
		void pa(Control pc)
		{
			foreach(Control ctrl; pc.ccollection)
			{
				if(Color.empty == ctrl.backc) // If default.
				{
					if(bc == ctrl.backColor) // If same default.
					{
						ctrl.deleteThisBackgroundBrush(); // Needs to be recreated with new color.
						ctrl.onBackColorChanged(EventArgs.empty);
						
						pa(ctrl); // Recursive.
					}
				}
			}
		}
		
		
		pa(this);
	}
	
	
	///
	protected void onBackColorChanged(EventArgs ea)
	{
		debug(EVENT_PRINT)
		{
			cprintf("{ Event: onBackColorChanged - Control %.*s }\n", name);
		}
		
		backColorChanged(this, ea);
	}
	
	
	///
	@property void backColor(Color c) // setter
	{
		if(backc == c)
			return;
		
		deleteThisBackgroundBrush(); // Needs to be recreated with new color.
		backc = c;
		onBackColorChanged(EventArgs.empty);
		
		_propagateBackColorAmbience();
		if(isHandleCreated)
			invalidate(true); // Redraw!
	}
	
	/// ditto
	@property Color backColor() // getter
	{
		if(Color.empty == backc)
		{
			if(parent)
			{
				return parent.backColor;
			}
			return defaultBackColor;
		}
		return backc;
	}
	
	
	///
	final @property int bottom() // getter
	{
		return wrect.bottom;
	}
	
	
	///
	final @property void bounds(Rect r) // setter
	{
		setBoundsCore(r.x, r.y, r.width, r.height, BoundsSpecified.ALL);
	}
	
	/// ditto
	final @property Rect bounds() // getter
	{
		return wrect;
	}
	
	
	/+
	final @property Rect originalBounds() // getter package
	{
		return oldwrect;
	}
	+/
	
	
	///
	protected void setBoundsCore(int x, int y, int width, int height, BoundsSpecified specified)
	{
		// Make sure at least one flag is set.
		//if(!(specified & BoundsSpecified.ALL))
		if(!specified)
			return;
		
		if(isHandleCreated)
		{
			UINT swpf = SWP_NOZORDER | SWP_NOACTIVATE | SWP_NOOWNERZORDER | SWP_NOMOVE | SWP_NOSIZE;
			
			if(specified & BoundsSpecified.X)
			{
				if(!(specified & BoundsSpecified.Y))
					y = this.top();
				swpf &= ~SWP_NOMOVE;
			}
			else if(specified & BoundsSpecified.Y)
			{
				x = this.left();
				swpf &= ~SWP_NOMOVE;
			}
			
			if(specified & BoundsSpecified.WIDTH)
			{
				if(!(specified & BoundsSpecified.HEIGHT))
					height = this.height();
				swpf &= ~SWP_NOSIZE;
			}
			else if(specified & BoundsSpecified.HEIGHT)
			{
				width = this.width();
				swpf &= ~SWP_NOSIZE;
			}
			
			SetWindowPos(hwnd, HWND.init, x, y, width, height, swpf);
			// Window events will update -wrect-.
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
				wclientsz.width = width;
			}
			if(specified & BoundsSpecified.HEIGHT)
			{
				if(height < 0)
					height = 0;
				
				wrect.height = height;
				wclientsz.height = height;
			}
			
			//oldwrect = wrect;
		}
	}
	
	
	///
	final @property bool canFocus() // getter
	{
		/+
		LONG wl = _style();
		return /+ hwnd && +/ (wl & WS_VISIBLE) && !(wl & WS_DISABLED);
		+/
		//return visible && enabled;
		// Don't need to check -isHandleCreated- because IsWindowVisible() will fail from a null HWND.
		return /+ isHandleCreated && +/ IsWindowVisible(hwnd) && IsWindowEnabled(hwnd);
	}
	
	
	///
	final @property bool canSelect() // getter
	out(result)
	{
		if(result)
		{
			assert(isHandleCreated);
		}
	}
	body
	{
		// All parent controls need to be visible and enabled, too.
		// Don't need to check -isHandleCreated- because IsWindowVisible() will fail from a null HWND.
		return /+ isHandleCreated && +/ (ctrlStyle & ControlStyles.SELECTABLE) &&
			IsWindowVisible(hwnd) && IsWindowEnabled(hwnd);
	}
	
	
	package final bool _hasSelStyle()
	{
		return getStyle(ControlStyles.SELECTABLE);
	}
	
	
	///
	// Returns true if this control has the mouse capture.
	final @property bool capture() // getter
	{
		return isHandleCreated && hwnd == GetCapture();
	}
	
	/// ditto
	final @property void capture(bool cyes) // setter
	{
		if(cyes)
			SetCapture(hwnd);
		else
			ReleaseCapture();
	}
	
	
	// When true, validating and validated events are fired when the control
	// receives focus. Typically set to false for controls such as a Help button.
	// Default is true.
	deprecated final bool causesValidation() // getter
	{
		//return cvalidation;
		return false;
	}
	
	
	deprecated protected void onCausesValidationChanged(EventArgs ea)
	{
		//causesValidationChanged(this, ea);
	}
	
	
	deprecated final void causesValidation(bool vyes) // setter
	{
		/+
		if(cvalidation == vyes)
			return;
		
		cvalidation = vyes;
		
		onCausesValidationChanged(EventArgs.empty);
		+/
	}
	
	
	///
	final @property Rect clientRectangle() // getter
	{
		return Rect(Point(0, 0), wclientsz);
	}
	
	
	///
	final bool contains(Control ctrl)
	{
		//return ccollection.contains(ctrl);
		return ctrl && ctrl.parent is this;
	}
	
	
	///
	final @property Size clientSize() // getter
	{
		return wclientsz;
	}
	
	/// ditto
	final @property void clientSize(Size sz) // setter
	{
		setClientSizeCore(sz.width, sz.height);
	}
	
	
	///
	protected void setClientSizeCore(int width, int height)
	{
		/+
		if(isHandleCreated)
			setBoundsCore(0, 0, width, height, BoundsSpecified.SIZE);
		
		//wclientsz = Size(width, height);
		+/
		
		RECT r;
		
		r.left = 0;
		r.top = 0;
		r.right = width;
		r.bottom = height;
		
		AdjustWindowRectEx(&r, _style(), FALSE, _exStyle());
		
		setBoundsCore(0, 0, r.right - r.left, r.bottom - r.top, BoundsSpecified.SIZE);
	}
	
	
	///
	// This window or one of its children has focus.
	final @property bool containsFocus() // getter
	{
		if(!isHandleCreated)
			return false;
		
		HWND hwfocus = GetFocus();
		return hwfocus == hwnd || IsChild(hwnd, hwfocus);
	}
	
	
	version(DFL_NO_MENUS)
	{
	}
	else
	{
		///
		protected void onContextMenuChanged(EventArgs ea)
		{
			contextMenuChanged(this, ea);
		}
		
		
		///
		@property void contextMenu(ContextMenu menu) // setter
		{
			if(cmenu is menu)
				return;
			
			cmenu = menu;
			
			if(isHandleCreated)
			{
				onContextMenuChanged(EventArgs.empty);
			}
		}
		
		/// ditto
		@property ContextMenu contextMenu() // getter
		{
			return cmenu;
		}
	}
	
	
	///
	final @property ControlCollection controls() // getter
	{
		//return new ControlCollection(this);
		return ccollection;
	}
	
	
	///
	final @property bool created() // getter
	{
		// To-do: only return true when createHandle finishes.
		// Will also need to update uses of created/isHandleCreated.
		// Return false again when disposing/killing.
		//return isHandleCreated;
		return isHandleCreated || recreatingHandle;
	}
	
	
	private void _propagateCursorAmbience()
	{
		Cursor cur;
		cur = cursor;
		
		
		void pa(Control pc)
		{
			foreach(Control ctrl; pc.ccollection)
			{
				if(ctrl.wcurs is null) // If default.
				{
					if(cur is ctrl.cursor) // If same default.
					{
						ctrl.onCursorChanged(EventArgs.empty);
						
						pa(ctrl); // Recursive.
					}
				}
			}
		}
		
		
		pa(this);
	}
	
	
	///
	protected void onCursorChanged(EventArgs ea)
	{
		/+
		debug(EVENT_PRINT)
		{
			cprintf("{ Event: onCursorChanged - Control %.*s }\n", name);
		}
		+/
		
		if(isHandleCreated)
		{
			if(visible && enabled)
			{
				Point curpt = Cursor.position;
				if(hwnd == WindowFromPoint(curpt.point))
				{
					SendMessageA(hwnd, WM_SETCURSOR, cast(WPARAM)hwnd,
						MAKELPARAM(
							SendMessageA(hwnd, WM_NCHITTEST, 0, MAKELPARAM(curpt.x, curpt.y)),
							WM_MOUSEMOVE)
							);
				}
			}
		}
		
		cursorChanged(this, ea);
	}
	
	
	///
	@property void cursor(Cursor cur) // setter
	{
		if(cur is wcurs)
			return;
		
		wcurs = cur;
		onCursorChanged(EventArgs.empty);
		
		_propagateCursorAmbience();
	}
	
	/// ditto
	@property Cursor cursor() // getter
	{
		if(!wcurs)
		{
			if(parent)
			{
				return parent.cursor;
			}
			return _defaultCursor;
		}
		return wcurs;
	}
	
	
	///
	static @property Color defaultBackColor() // getter
	{
		return Color.systemColor(COLOR_BTNFACE);
	}
	
	
	///
	static @property Color defaultForeColor() //getter
	{
		return Color.systemColor(COLOR_BTNTEXT);
	}
	
	
	private static Font _deffont = null;
	
	
	private static Font _createOldFont()
	{
		return new Font(cast(HFONT)GetStockObject(DEFAULT_GUI_FONT), false);
	}
	
	
	private static Font _createCompatibleFont()
	{
		Font result;
		result = _createOldFont();
		
		try
		{
			OSVERSIONINFOA osi;
			osi.dwOSVersionInfoSize = osi.sizeof;
			if(GetVersionExA(&osi) && osi.dwMajorVersion >= 5)
			{
				// "MS Shell Dlg" / "MS Shell Dlg 2" not always supported.
				result = new Font("MS Shell Dlg 2", result.getSize(GraphicsUnit.POINT), GraphicsUnit.POINT);
			}
		}
		catch
		{
		}
		
		//if(!result)
		//	result = _createOldFont();
		assert(result !is null);
		
		return result;
	}
	
	
	private static Font _createNativeFont()
	{
		Font result;
		
		NONCLIENTMETRICSA ncm;
		ncm.cbSize = ncm.sizeof;
		if(!SystemParametersInfoA(SPI_GETNONCLIENTMETRICS, ncm.sizeof, &ncm, 0))
		{
			result = _createCompatibleFont();
		}
		else
		{
			result = new Font(&ncm.lfMessageFont, true);
		}
		
		return result;
	}
	
	
	private static void _setDeffont(ControlFont cf)
	{
		synchronized
		{
			assert(_deffont is null);
			switch(cf)
			{
				case ControlFont.COMPATIBLE:
					_deffont = _createCompatibleFont();
					break;
				case ControlFont.NATIVE:
					_deffont = _createNativeFont();
					break;
				case ControlFont.OLD:
					_deffont = _createOldFont();
					break;
				default:
					assert(0);
			}
		}
	}
	
	
	deprecated alias defaultFont controlFont;
	
	///
	static @property void defaultFont(ControlFont cf) // setter
	{
		if(_deffont)
			throw new DflException("Control font already selected");
		_setDeffont(cf);
	}
	
	/// ditto
	static @property void defaultFont(Font f) // setter
	{
		if(_deffont)
			throw new DflException("Control font already selected");
		_deffont = f;
	}
	
	/// ditto
	static @property Font defaultFont() // getter
	{
		if(!_deffont)
		{
			_setDeffont(ControlFont.COMPATIBLE);
		}
		
		return _deffont;
	}
	
	
	package static class SafeCursor: Cursor
	{
		this(HCURSOR hcur)
		{
			super(hcur, false);
		}
		
		
		override void dispose()
		{
		}
		
		
		/+
		~this()
		{
			super.dispose();
		}
		+/
	}
	
	
	package static @property Cursor _defaultCursor() // getter
	{
		static Cursor def = null;
		
		if(!def)
		{
			synchronized
			{
				if(!def)
					def = new SafeCursor(LoadCursorA(HINSTANCE.init, IDC_ARROW));
			}
		}
		
		return def;
	}
	
	
	///
	@property Rect displayRectangle() // getter
	{
		return clientRectangle;
	}
	
	
	///
	//protected void onDockChanged(EventArgs ea)
	protected void onHasLayoutChanged(EventArgs ea)
	{
		if(parent)
			parent.alayout(this);
		
		//dockChanged(this, ea);
		hasLayoutChanged(this, ea);
	}
	
	alias onHasLayoutChanged onDockChanged;
	
	
	private final void _alreadyLayout()
	{
		throw new DflException("Control already has a layout");
	}
	
	
	///
	@property DockStyle dock() // getter
	{
		return sdock;
	}
	
	/// ditto
	@property void dock(DockStyle ds) // setter
	{
		if(ds == sdock)
			return;
		
		DockStyle _olddock = sdock;
		sdock = ds;
		/+
		anch = AnchorStyles.NONE; // Can't be set at the same time.
		+/
		
		if(DockStyle.NONE == ds)
		{
			if(DockStyle.NONE != _olddock) // If it was even docking before; don't unset hasLayout for something else.
				hasLayout = false;
		}
		else
		{
			// Ensure not replacing some other layout, but OK if replacing another dock.
			if(DockStyle.NONE == _olddock)
			{
				if(hasLayout)
					_alreadyLayout();
			}
			hasLayout = true;
		}
		
		/+ // Called by hasLayout.
		if(isHandleCreated)
		{
			onDockChanged(EventArgs.empty);
		}
		+/
	}
	
	
	/// Get or set whether or not this control currently has its bounds managed. Fires onHasLayoutChanged as needed.
	final @property bool hasLayout() // getter
	{
		if(cbits & CBits.HAS_LAYOUT)
			return true;
		return false;
	}
	
	/// ditto
	final @property void hasLayout(bool byes) // setter
	{
		//if(byes == hasLayout)
		//	return; // No! setting this property again must trigger onHasLayoutChanged again.
		
		if(byes)
			cbits |= CBits.HAS_LAYOUT;
		else
			cbits &= ~CBits.HAS_LAYOUT;
		
		if(byes) // No need if layout is removed.
		{
			if(isHandleCreated)
			{
				onHasLayoutChanged(EventArgs.empty);
			}
		}
	}
	
	
	package final void _venabled(bool byes)
	{
		if(isHandleCreated)
		{
			EnableWindow(hwnd, byes);
			// Window events will update -wstyle-.
		}
		else
		{
			if(byes)
				wstyle &= ~WS_DISABLED;
			else
				wstyle |= WS_DISABLED;
		}
	}
	
	
	///
	final @property void enabled(bool byes) // setter
	{
		if(byes)
			cbits |= CBits.ENABLED;
		else
			cbits &= ~CBits.ENABLED;
		
		/+
		if(!byes)
		{
			_venabled(false);
		}
		else
		{
			if(!parent || parent.enabled)
				_venabled(true);
		}
		
		_propagateEnabledAmbience();
		+/
		
		_venabled(byes);
	}
	
	///
	final @property bool enabled() // getter
	{
		/*
		return IsWindowEnabled(hwnd) ? true : false;
		*/
		
		return (wstyle & WS_DISABLED) == 0;
	}
	
	
	private void _propagateEnabledAmbience()
	{
		/+ // Isn't working...
		if(cbits & CBits.FORM)
			return;
		
		bool en = enabled;
		
		void pa(Control pc)
		{
			foreach(Control ctrl; pc.ccollection)
			{
				if(ctrl.cbits & CBits.ENABLED)
				{
					_venabled(en);
					
					pa(ctrl);
				}
			}
		}
		
		pa(this);
		+/
	}
	
	
	///
	final void enable()
	{
		enabled = true;
	}
	
	/// ditto
	final void disable()
	{
		enabled = false;
	}
	
	
	///
	@property bool focused() // getter
	{
		//return isHandleCreated && hwnd == GetFocus();
		return created && fromChildHandle(GetFocus()) is this;
	}
	
	
	///
	@property void font(Font f) // setter
	{
		if(wfont is f)
			return;
		
		wfont = f;
		if(isHandleCreated)
			SendMessageA(hwnd, WM_SETFONT, cast(WPARAM)wfont.handle, MAKELPARAM(true, 0));
		onFontChanged(EventArgs.empty);
		
		_propagateFontAmbience();
	}
	
	/// ditto
	@property Font font() // getter
	{
		if(!wfont)
		{
			if(parent)
			{
				return parent.font;
			}
			return defaultFont;
		}
		return wfont;
	}
	
	
	private void _propagateForeColorAmbience()
	{
		Color fc;
		fc = foreColor;
		
		
		void pa(Control pc)
		{
			foreach(Control ctrl; pc.ccollection)
			{
				if(Color.empty == ctrl.forec) // If default.
				{
					if(fc == ctrl.foreColor) // If same default.
					{
						ctrl.onForeColorChanged(EventArgs.empty);
						
						pa(ctrl); // Recursive.
					}
				}
			}
		}
		
		
		pa(this);
	}
	
	
	///
	protected void onForeColorChanged(EventArgs ea)
	{
		debug(EVENT_PRINT)
		{
			cprintf("{ Event: onForeColorChanged - Control %.*s }\n", name);
		}
		
		foreColorChanged(this, ea);
	}
	
	
	///
	@property void foreColor(Color c) // setter
	{
		if(c == forec)
			return;
		
		forec = c;
		onForeColorChanged(EventArgs.empty);
		
		_propagateForeColorAmbience();
		if(isHandleCreated)
			invalidate(true); // Redraw!
	}
	
	/// ditto
	@property Color foreColor() // getter
	{
		if(Color.empty == forec)
		{
			if(parent)
			{
				return parent.foreColor;
			}
			return defaultForeColor;
		}
		return forec;
	}
	
	
	///
	// Doesn't cause a ControlCollection to be constructed so
	// it could improve performance when walking through children.
	final @property bool hasChildren() // getter
	{
		//return isHandleCreated && GetWindow(hwnd, GW_CHILD) != HWND.init;
		
		if(isHandleCreated)
		{
			return GetWindow(hwnd, GW_CHILD) != HWND.init;
		}
		else
		{
			return ccollection.children.length != 0;
		}
	}
	
	
	///
	final @property void height(int h) // setter
	{
		/*
		RECT rect;
		GetWindowRect(hwnd, &rect);
		SetWindowPos(hwnd, HWND.init, 0, 0, rect.right - rect.left, h, SWP_NOACTIVATE | SWP_NOZORDER | SWP_NOMOVE);
		*/
		
		setBoundsCore(0, 0, 0, h, BoundsSpecified.HEIGHT);
	}
	
	/// ditto
	final @property int height() // getter
	{
		return wrect.height;
	}
	
	
	///
	final @property bool isHandleCreated() // getter
	{
		return hwnd != HWND.init;
	}
	
	
	///
	final @property void left(int l) // setter
	{
		/*
		RECT rect;
		GetWindowRect(hwnd, &rect);
		SetWindowPos(hwnd, HWND.init, l, rect.top, 0, 0, SWP_NOACTIVATE | SWP_NOZORDER | SWP_NOSIZE);
		*/
		
		setBoundsCore(l, 0, 0, 0, BoundsSpecified.X);
	}
	
	/// ditto
	final @property int left() // getter
	{
		return wrect.x;
	}
	
	
	/// Property: get or set the X and Y location of the control.
	final @property void location(Point pt) // setter
	{
		/*
		SetWindowPos(hwnd, HWND.init, pt.x, pt.y, 0, 0, SWP_NOACTIVATE | SWP_NOZORDER | SWP_NOSIZE);
		*/
		
		setBoundsCore(pt.x, pt.y, 0, 0, BoundsSpecified.LOCATION);
	}
	
	/// ditto
	final @property Point location() // getter
	{
		return wrect.location;
	}
	
	
	/// Currently depressed modifier keys.
	static @property Keys modifierKeys() // getter
	{
		// Is there a better way to do this?
		Keys ks = Keys.NONE;
		if(GetAsyncKeyState(VK_SHIFT) & 0x8000)
			ks |= Keys.SHIFT;
		if(GetAsyncKeyState(VK_MENU) & 0x8000)
			ks |= Keys.ALT;
		if(GetAsyncKeyState(VK_CONTROL) & 0x8000)
			ks|= Keys.CONTROL;
		return ks;
	}
	
	
	/// Currently depressed mouse buttons.
	static @property MouseButtons mouseButtons() // getter
	{
		MouseButtons result;
		
		result = MouseButtons.NONE;
		if(GetSystemMetrics(SM_SWAPBUTTON))
		{
			if(GetAsyncKeyState(VK_LBUTTON) & 0x8000)
				result |= MouseButtons.RIGHT; // Swapped.
			if(GetAsyncKeyState(VK_RBUTTON) & 0x8000)
				result |= MouseButtons.LEFT; // Swapped.
		}
		else
		{
			if(GetAsyncKeyState(VK_LBUTTON) & 0x8000)
				result |= MouseButtons.LEFT;
			if(GetAsyncKeyState(VK_RBUTTON) & 0x8000)
				result |= MouseButtons.RIGHT;
		}
		if(GetAsyncKeyState(VK_MBUTTON) & 0x8000)
			result |= MouseButtons.MIDDLE;
		
		return result;
	}
	
	
	///
	static @property Point mousePosition() // getter
	{
		Point pt;
		GetCursorPos(&pt.point);
		return pt;
	}
	
	
	/// Property: get or set the name of this control used in code.
	final @property void name(Dstring txt) // setter
	{
		_ctrlname = txt;
	}
	
	/// ditto
	final @property Dstring name() // getter
	{
		return _ctrlname;
	}
	
	
	///
	protected void onParentChanged(EventArgs ea)
	{
		debug(EVENT_PRINT)
		{
			cprintf("{ Event: onParentChanged - Control %.*s }\n", name);
		}
		
		parentChanged(this, ea);
	}
	
	
	/+
	///
	// ea is the new parent.
	protected void onParentChanging(ControlEventArgs ea)
	{
	}
	+/
	
	
	///
	final Form findForm()
	{
		Form f;
		Control c;
		
		c = this;
		for(;;)
		{
			f = cast(Form)c;
			if(f)
				break;
			c = c.parent;
			if(!c)
				return null;
		}
		return f;
	}
	
	
	///
	final @property void parent(Control c) // setter
	{
		if(c is wparent)
			return;
		
		if(!(_style() & WS_CHILD) || (_exStyle() & WS_EX_MDICHILD))
			throw new DflException("Cannot add a top level control to a control");
		
		//scope ControlEventArgs pcea = new ControlEventArgs(c);
		//onParentChanging(pcea);
		
		Control oldparent;
		_FixAmbientOld oldinfo;
		
		oldparent = wparent;
		
		if(oldparent)
		{
			oldinfo.set(oldparent);
			
			if(!oldparent.isHandleCreated)
			{
				int oi = oldparent.controls.indexOf(this);
				//assert(-1 != oi); // Fails if the parent (and thus this) handles destroyed.
				if(-1 != oi)
					oldparent.controls._removeNotCreated(oi);
			}
		}
		else
		{
			oldinfo.set(this);
		}
		
		scope ControlEventArgs cea = new ControlEventArgs(this);
		
		if(c)
		{
			wparent = c;
			
			// I want the destroy notification. Don't need it anymore.
			//c._exStyle(c._exStyle() & ~WS_EX_NOPARENTNOTIFY);
			
			if(c.isHandleCreated)
			{
				cbits &= ~CBits.NEED_INIT_LAYOUT;
				
				//if(created)
				if(isHandleCreated)
				{
					SetParent(hwnd, c.hwnd);
				}
				else
				{
					// If the parent is created, create me!
					createControl();
				}
				
				onParentChanged(EventArgs.empty);
				if(oldparent)
					oldparent._ctrlremoved(cea);
				c._ctrladded(cea);
				_fixAmbient(&oldinfo);
				
				initLayout();
			}
			else
			{
				// If the parent exists and isn't created, need to add
				// -this- to its children array.
				c.ccollection.children ~= this;
				
				onParentChanged(EventArgs.empty);
				if(oldparent)
					oldparent._ctrlremoved(cea);
				c._ctrladded(cea);
				_fixAmbient(&oldinfo);
				
				cbits |= CBits.NEED_INIT_LAYOUT;
			}
		}
		else
		{
			assert(c is null);
			//wparent = c;
			wparent = null;
			
			if(isHandleCreated)
				SetParent(hwnd, HWND.init);
			
			onParentChanged(EventArgs.empty);
			assert(oldparent !is null);
			oldparent._ctrlremoved(cea);
			_fixAmbient(&oldinfo);
		}
	}
	
	/// ditto
	final @property Control parent() // getter
	{
		return wparent;
	}
	
	
	private final Control _fetchParent()
	{
		HWND hwParent = GetParent(hwnd);
		return fromHandle(hwParent);
	}
	
	
	// TODO: check implementation.
	private static HRGN dupHrgn(HRGN hrgn)
	{
		HRGN rdup = CreateRectRgn(0, 0, 1, 1);
		CombineRgn(rdup, hrgn, HRGN.init, RGN_COPY);
		return rdup;
	}
	
	
	///
	final @property void region(Region rgn) // setter
	{
		if(isHandleCreated)
		{
			// Need to make a copy of the region.
			SetWindowRgn(hwnd, dupHrgn(rgn.handle), true);
		}
		
		wregion = rgn;
	}
	
	/// ditto
	final @property Region region() // getter
	{
		return wregion;
	}
	
	
	private final Region _fetchRegion()
	{
		HRGN hrgn = CreateRectRgn(0, 0, 1, 1);
		GetWindowRgn(hwnd, hrgn);
		return new Region(hrgn); // Owned because GetWindowRgn() gives a copy.
	}
	
	
	///
	final @property int right() // getter
	{
		return wrect.right;
	}
	
	
	/+
	@property void rightToLeft(bool byes) // setter
	{
		LONG wl = _exStyle();
		if(byes)
			wl |= WS_EX_RTLREADING;
		else
			wl &= ~WS_EX_RTLREADING;
		_exStyle(wl);
	}
	
	
	@property bool rightToLeft() // getter
	{
		return (_exStyle() & WS_EX_RTLREADING) != 0;
	}
	+/
	
	
	deprecated @property void rightToLeft(bool byes) // setter
	{
		rightToLeft = byes ? RightToLeft.YES : RightToLeft.NO;
	}
	
	
	package final void _fixRtol(RightToLeft val)
	{
		switch(val)
		{
			case RightToLeft.INHERIT:
				if(parent && parent.rightToLeft == RightToLeft.YES)
				{
					goto case RightToLeft.YES;
				}
				goto case RightToLeft.NO;
			
			case RightToLeft.YES:
				_exStyle(_exStyle() | WS_EX_RTLREADING);
				break;
			
			case RightToLeft.NO:
				_exStyle(_exStyle() & ~WS_EX_RTLREADING);
				break;
			
			default:
				assert(0);
		}
		
		//invalidate(true); // Children too in case they inherit.
		invalidate(false); // Since children are enumerated.
	}
	
	
	private void _propagateRtolAmbience()
	{
		RightToLeft rl;
		rl = rightToLeft;
		
		
		void pa(Control pc)
		{
			if(RightToLeft.INHERIT == pc.rtol)
			{
				//pc._fixRtol(rtol);
				pc._fixRtol(rl); // Set the specific parent value so it doesn't have to look up the chain.
				
				foreach(Control ctrl; pc.ccollection)
				{
					ctrl.onRightToLeftChanged(EventArgs.empty);
					
					pa(ctrl);
				}
			}
		}
		
		
		pa(this);
	}
	
	
	///
	@property void rightToLeft(RightToLeft val) // setter
	{
		if(rtol != val)
		{
			rtol = val;
			onRightToLeftChanged(EventArgs.empty);
			_propagateRtolAmbience(); // Also sets the class style and invalidates.
		}
	}
	
	/// ditto
	// Returns YES or NO; if inherited, returns parent's setting.
	@property RightToLeft rightToLeft() // getter
	{
		if(RightToLeft.INHERIT == rtol)
		{
			return parent ? parent.rightToLeft : RightToLeft.NO;
		}
		return rtol;
	}
	
	
	package struct _FixAmbientOld
	{
		Font font;
		Cursor cursor;
		Color backColor;
		Color foreColor;
		RightToLeft rightToLeft;
		//CBits cbits;
		bool enabled;
		
		
		void set(Control ctrl)
		{
			if(ctrl)
			{
				font = ctrl.font;
				cursor = ctrl.cursor;
				backColor = ctrl.backColor;
				foreColor = ctrl.foreColor;
				rightToLeft = ctrl.rightToLeft;
				//cbits = ctrl.cbits;
				enabled = ctrl.enabled;
			}
			/+else
			{
				font = null;
				cursor = null;
				backColor = Color.empty;
				foreColor = Color.empty;
				rightToLeft = RightToLeft.INHERIT;
				//cbits = CBits.init;
				enabled = true;
			}+/
		}
	}
	
	
	// This is called when the inherited ambience changes.
	package final void _fixAmbient(_FixAmbientOld* oldinfo)
	{
		// Note: exception will screw things up.
		
		_FixAmbientOld newinfo;
		if(parent)
			newinfo.set(parent);
		else
			newinfo.set(this);
		
		if(RightToLeft.INHERIT == rtol)
		{
			if(newinfo.rightToLeft !is oldinfo.rightToLeft)
			{
				onRightToLeftChanged(EventArgs.empty);
				_propagateRtolAmbience();
			}
		}
		
		if(Color.empty == backc)
		{
			if(newinfo.backColor !is oldinfo.backColor)
			{
				onBackColorChanged(EventArgs.empty);
				_propagateBackColorAmbience();
			}
		}
		
		if(Color.empty == forec)
		{
			if(newinfo.foreColor !is oldinfo.foreColor)
			{
				onForeColorChanged(EventArgs.empty);
				_propagateForeColorAmbience();
			}
		}
		
		if(!wfont)
		{
			if(newinfo.font !is oldinfo.font)
			{
				onFontChanged(EventArgs.empty);
				_propagateFontAmbience();
			}
		}
		
		if(!wcurs)
		{
			if(newinfo.cursor !is oldinfo.cursor)
			{
				onCursorChanged(EventArgs.empty);
				_propagateCursorAmbience();
			}
		}
		
		/+
		if(newinfo.enabled != oldinfo.enabled)
		{
			if(cbits & CBits.ENABLED)
			{
				_venabled(newinfo.enabled);
				_propagateEnabledAmbience();
			}
		}
		+/
	}
	
	
	/+
	package final void _fixAmbientChildren()
	{
		foreach(Control ctrl; ccollection.children)
		{
			ctrl._fixAmbient();
		}
	}
	+/
	
	
	///
	final @property void size(Size sz) // setter
	{
		/*
		SetWindowPos(hwnd, HWND.init, 0, 0, sz.width, sz.height, SWP_NOACTIVATE | SWP_NOZORDER | SWP_NOMOVE);
		*/
		
		setBoundsCore(0, 0, sz.width, sz.height, BoundsSpecified.SIZE);
	}
	
	/// ditto
	final @property Size size() // getter
	{
		return wrect.size; // struct Size, not sizeof.
	}
	
	
	/+
	final @property void tabIndex(int i) // setter
	{
		// TODO: ?
	}
	
	
	final @property int tabIndex() // getter
	{
		return tabidx;
	}
	+/
	
	
	// Use -zIndex- instead.
	// -tabIndex- may return different values in the future.
	deprecated int tabIndex() // getter
	{
		return zIndex;
	}
	
	
	///
	final @property int zIndex() // getter
	out(result)
	{
		assert(result >= 0);
	}
	body
	{
		if(!parent)
			return 0;
		
		if(isHandleCreated)
		{
			GetZIndex gzi;
			gzi.find = this;
			int index;
			int tmp;
			
			BOOL getZIndexCallback(HWND hWnd)
			{
				if(hWnd is hwnd)
				{
					index = tmp;
					return FALSE; // Stop, found it.
				}
				
				auto ctrl = Control.fromHandle(hWnd);
				if(ctrl && ctrl.parent is parent)
				{
					tmp++;
				}
				
				return TRUE; // Keep looking.
			}
			
			enumChildWindows(parent.hwnd, &getZIndexCallback);
			return index;
		}
		else
		{
			return parent.controls.indexOf(this);
		}
	}
	
	
	///
	// True if control can be tabbed to.
	final @property void tabStop(bool byes) // setter
	{
		LONG wl = _style();
		if(byes)
			wl |= WS_TABSTOP;
		else
			wl &= ~WS_TABSTOP;
		_style(wl);
	}
	
	/// ditto
	final @property bool tabStop() // getter
	{
		return (_style() & WS_TABSTOP) != 0;
	}
	
	
	/// Property: get or set additional data tagged onto the control.
	final @property void tag(Object o) // setter
	{
		otag = o;
	}
	
	/// ditto
	final @property Object tag() // getter
	{
		return otag;
	}
	
	
	private final Dstring _fetchText()
	{
		return dfl.internal.utf.getWindowText(hwnd);
	}
	
	
	///
	@property void text(Dstring txt) // setter
	{
		if(isHandleCreated)
		{
			if(ctrlStyle & ControlStyles.CACHE_TEXT)
			{
				//if(wtext == txt)
				//	return;
				wtext = txt;
			}
			
			dfl.internal.utf.setWindowText(hwnd, txt);
		}
		else
		{
			wtext = txt;
		}
	}
	
	/// ditto
	@property Dstring text() // getter
	{
		if(isHandleCreated)
		{
			if(ctrlStyle & ControlStyles.CACHE_TEXT)
				return wtext;
			
			return _fetchText();
		}
		else
		{
			return wtext;
		}
	}
	
	
	///
	final @property void top(int t) // setter
	{
		setBoundsCore(0, t, 0, 0, BoundsSpecified.Y);
	}
	
	/// ditto
	final @property int top() // getter
	{
		return wrect.y;
	}
	
	
	/// Returns the topmost Control related to this control.
	// Returns the owner control that has no parent.
	// Returns this Control if no owner ?
	final @property Control topLevelControl() // getter
	{
		if(isHandleCreated)
		{
			HWND hwCurrent = hwnd;
			HWND hwParent;
			
			for(;;)
			{
				hwParent = GetParent(hwCurrent); // This gets the top-level one, whereas the previous code jumped owners.
				if(!hwParent)
					break;
				
				hwCurrent = hwParent;
			}
			
			return fromHandle(hwCurrent);
		}
		else
		{
			Control ctrl;
			ctrl = this;
			while(ctrl.parent)
			{
				ctrl = ctrl.parent; // This shouldn't jump owners..
			}
			return ctrl;
		}
	}
	
	
	/+
	private DWORD _fetchVisible()
	{
		//return IsWindowVisible(hwnd) != FALSE;
		wstyle = GetWindowLongA(hwnd, GWL_STYLE);
		return wstyle & WS_VISIBLE;
	}
	+/
	
	
	///
	final @property void visible(bool byes) // setter
	{
		setVisibleCore(byes);
	}
	
	/// ditto
	final @property bool visible() // getter
	{
		//if(isHandleCreated)
		//	wstyle = GetWindowLongA(hwnd, GWL_STYLE); // ...
		//return (wstyle & WS_VISIBLE) != 0;
		return (cbits & CBits.VISIBLE) != 0;
	}
	
	
	///
	final @property void width(int w) // setter
	{
		setBoundsCore(0, 0, w, 0, BoundsSpecified.WIDTH);
	}
	
	/// ditto
	final @property int width() // getter
	{
		return wrect.width;
	}
	
	
	///
	final void sendToBack()
	{
		if(!isHandleCreated)
		{
			if(parent)
				parent.ccollection._simple_front(this);
			return;
		}
		
		SetWindowPos(hwnd, HWND_BOTTOM, 0, 0, 0, 0, SWP_NOMOVE | SWP_NOSIZE);
	}
	
	
	///
	final void bringToFront()
	{
		if(!isHandleCreated)
		{
			if(parent)
				parent.ccollection._simple_back(this);
			return;
		}
		
		SetWindowPos(hwnd, HWND_TOP, 0, 0, 0, 0, SWP_NOMOVE | SWP_NOSIZE);
		//BringWindowToTop(hwnd);
	}
	
	
	deprecated alias bringUpOne zIndexUp;
	
	///
	// Move up one.
	final void bringUpOne()
	{
		if(!isHandleCreated)
		{
			if(parent)
				parent.ccollection._simple_front_one(this);
			return;
		}
		
		HWND hw;
		
		// Need to move back twice because the previous one already precedes this one.
		hw = GetWindow(hwnd, GW_HWNDPREV);
		if(!hw)
		{
			hw = HWND_TOP;
		}
		else
		{
			hw = GetWindow(hw, GW_HWNDPREV);
			if(!hw)
				hw = HWND_TOP;
		}
		
		SetWindowPos(hwnd, hw, 0, 0, 0, 0, SWP_NOMOVE | SWP_NOSIZE);
	}
	
	
	deprecated alias sendBackOne zIndexDown;
	
	///
	// Move back one.
	final void sendBackOne()
	{
		if(!isHandleCreated)
		{
			if(parent)
				parent.ccollection._simple_back_one(this);
			return;
		}
		
		HWND hw;
		
		hw = GetWindow(hwnd, GW_HWNDNEXT);
		if(!hw)
			hw = HWND_BOTTOM;
		
		SetWindowPos(hwnd, hw, 0, 0, 0, 0, SWP_NOMOVE | SWP_NOSIZE);
	}
	
	
	// Note: true if no children, even if this not created.
	package final @property bool areChildrenCreated() // getter
	{
		return !ccollection.children.length;
	}
	
	
	package final void createChildren()
	{
		assert(isHandleCreated);
		
		Control[] ctrls;
		ctrls = ccollection.children;
		ccollection.children = null;
		
		foreach(Control ctrl; ctrls)
		{
			assert(ctrl.parent is this);
			assert(!(ctrl is null));
			assert(ctrl);
			ctrl.createControl();
		}
	}
	
	
	///
	// Force creation of the window and its child controls.
	final void createControl()
	{
		createHandle();
		
		// Called in WM_CREATE also.
		createChildren();
	}
	
	
	/// Returns a new Graphics object for this control, creating the control handle if necessary.
	final Graphics createGraphics()
	{
		HDC hdc = GetDC(handle); // Create handle as necessary.
		SetTextColor(hdc, foreColor.toRgb());
		return new CommonGraphics(hwnd, hdc);
	}
	
	
	version(DFL_NO_DRAG_DROP) {} else
	{
		private static class DropTarget: DflComObject, IDropTarget
		{
			this(Control ctrl)
			{
				this.ctrl = ctrl;
			}
			~this()
			{
				if (dataObj)
				{
					GC.removeRoot(cast(void*)dataObj);
					clear(dataObj);
				}
			}
			
			
			extern(Windows):
			override HRESULT QueryInterface(IID* riid, void** ppv)
			{
				if(*riid == _IID_IDropTarget)
				{
					*ppv = cast(void*)cast(IDropTarget)this;
					AddRef();
					return S_OK;
				}
				else if(*riid == _IID_IUnknown)
				{
					*ppv = cast(void*)cast(IUnknown)this;
					AddRef();
					return S_OK;
				}
				else
				{
					*ppv = null;
					return E_NOINTERFACE;
				}
			}
			
			
			HRESULT DragEnter(dfl.internal.wincom.IDataObject pDataObject, DWORD grfKeyState, POINTL pt, DWORD *pdwEffect)
			{
				HRESULT result;
				
				try
				{
					//dataObj = new ComToDdataObject(pDataObject);
					ensureDataObj(pDataObject);
					
					scope DragEventArgs ea = new DragEventArgs(dataObj, cast(int)grfKeyState, pt.x, pt.y, 
						cast(DragDropEffects)*pdwEffect, DragDropEffects.NONE); // ?
					ctrl.onDragEnter(ea);
					*pdwEffect = ea.effect;
					
					result = S_OK;
				}
				catch(DThrowable e)
				{
					Application.onThreadException(e);
					
					result = E_UNEXPECTED;
				}
				
				return result;
			}
			
			
			HRESULT DragOver(DWORD grfKeyState, POINTL pt, DWORD *pdwEffect)
			{
				HRESULT result;
				
				try
				{
					assert(dataObj !is null);
					
					scope DragEventArgs ea = new DragEventArgs(dataObj, cast(int)grfKeyState, pt.x, pt.y, 
						cast(DragDropEffects)*pdwEffect, DragDropEffects.NONE); // ?
					ctrl.onDragOver(ea);
					*pdwEffect = ea.effect;
					
					result = S_OK;
				}
				catch(DThrowable e)
				{
					Application.onThreadException(e);
					
					result = E_UNEXPECTED;
				}
				
				return result;
			}
			
			
			HRESULT DragLeave()
			{
				HRESULT result;
				
				try
				{
					ctrl.onDragLeave(EventArgs.empty);
					
					killDataObj();
					
					result = S_OK;
				}
				catch(DThrowable e)
				{
					Application.onThreadException(e);
					
					result = E_UNEXPECTED;
				}
				
				return result;
			}
			
			
			HRESULT Drop(dfl.internal.wincom.IDataObject pDataObject, DWORD grfKeyState, POINTL pt, DWORD *pdwEffect)
			{
				HRESULT result;
				
				try
				{
					//assert(dataObj !is null);
					ensureDataObj(pDataObject);
					
					scope DragEventArgs ea = new DragEventArgs(dataObj, cast(int)grfKeyState, pt.x, pt.y, 
						cast(DragDropEffects)*pdwEffect, DragDropEffects.NONE); // ?
					ctrl.onDragDrop(ea);
					*pdwEffect = ea.effect;
					
					result = S_OK;
				}
				catch(DThrowable e)
				{
					Application.onThreadException(e);
					
					result = E_UNEXPECTED;
				}
				
				return result;
			}
			
			
			private:
			
			Control ctrl;
			//dfl.data.IDataObject dataObj;
			ComToDdataObject dataObj;
			
			
			void ensureDataObj(dfl.internal.wincom.IDataObject pDataObject)
			{
				if(!dataObj)
				{
					dataObj = new ComToDdataObject(pDataObject);
					GC.addRoot(cast(void*)dataObj);
				}
				else if (!dataObj.isSameDataObject(pDataObject))
				{
					GC.removeRoot(cast(void*)dataObj);
					dataObj = new ComToDdataObject(pDataObject);
					GC.addRoot(cast(void*)dataObj);
				}
			}
			
			
			void killDataObj()
			{
				// Can't do this because the COM object might still need to be released elsewhere.
				//delete dataObj;
				//dataObj = null;
			}
		}
		
		
		///
		protected void onDragLeave(EventArgs ea)
		{
			dragLeave(this, ea);
		}
		
		
		///
		protected void onDragEnter(DragEventArgs ea)
		{
			dragEnter(this, ea);
		}
		
		
		///
		protected void onDragOver(DragEventArgs ea)
		{
			dragOver(this, ea);
		}
		
		
		///
		protected void onDragDrop(DragEventArgs ea)
		{
			dragDrop(this, ea);
		}
		
		
		private static class DropSource: DflComObject, IDropSource
		{
			this(Control ctrl)
			{
				this.ctrl = ctrl;
				mbtns = Control.mouseButtons;
			}
			
			
			extern(Windows):
			override HRESULT QueryInterface(IID* riid, void** ppv)
			{
				if(*riid == _IID_IDropSource)
				{
					*ppv = cast(void*)cast(IDropSource)this;
					AddRef();
					return S_OK;
				}
				else if(*riid == _IID_IUnknown)
				{
					*ppv = cast(void*)cast(IUnknown)this;
					AddRef();
					return S_OK;
				}
				else
				{
					*ppv = null;
					return E_NOINTERFACE;
				}
			}
			
			
			HRESULT QueryContinueDrag(BOOL fEscapePressed, DWORD grfKeyState)
			{
				HRESULT result;
				
				try
				{
					DragAction act;
					
					if(fEscapePressed)
					{
						act = cast(DragAction)DragAction.CANCEL;
					}
					else
					{
						if(mbtns & MouseButtons.LEFT)
						{
							if(!(grfKeyState & MK_LBUTTON))
							{
								act = cast(DragAction)DragAction.DROP;
								goto qdoit;
							}
						}
						else
						{
							if(grfKeyState & MK_LBUTTON)
							{
								act = cast(DragAction)DragAction.CANCEL;
								goto qdoit;
							}
						}
						if(mbtns & MouseButtons.RIGHT)
						{
							if(!(grfKeyState & MK_RBUTTON))
							{
								act = cast(DragAction)DragAction.DROP;
								goto qdoit;
							}
						}
						else
						{
							if(grfKeyState & MK_RBUTTON)
							{
								act = cast(DragAction)DragAction.CANCEL;
								goto qdoit;
							}
						}
						if(mbtns & MouseButtons.MIDDLE)
						{
							if(!(grfKeyState & MK_MBUTTON))
							{
								act = cast(DragAction)DragAction.DROP;
								goto qdoit;
							}
						}
						else
						{
							if(grfKeyState & MK_MBUTTON)
							{
								act = cast(DragAction)DragAction.CANCEL;
								goto qdoit;
							}
						}
						
						act = cast(DragAction)DragAction.CONTINUE;
					}
					
					qdoit:
					scope QueryContinueDragEventArgs ea = new QueryContinueDragEventArgs(cast(int)grfKeyState,
						fEscapePressed != FALSE, act); // ?
					ctrl.onQueryContinueDrag(ea);
					
					result = cast(HRESULT)ea.action;
				}
				catch(DThrowable e)
				{
					Application.onThreadException(e);
					
					result = E_UNEXPECTED;
				}
				
				return result;
			}
			
			
			HRESULT GiveFeedback(DWORD dwEffect)
			{
				HRESULT result;
				
				try
				{
					scope GiveFeedbackEventArgs ea = new GiveFeedbackEventArgs(cast(DragDropEffects)dwEffect, true);
					ctrl.onGiveFeedback(ea);
					
					result = ea.useDefaultCursors ? DRAGDROP_S_USEDEFAULTCURSORS : S_OK;
				}
				catch(DThrowable e)
				{
					Application.onThreadException(e);
					
					result = E_UNEXPECTED;
				}
				
				return result;
			}
			
			
			private:
			Control ctrl;
			MouseButtons mbtns;
		}
		
		
		///
		protected void onQueryContinueDrag(QueryContinueDragEventArgs ea)
		{
			queryContinueDrag(this, ea);
		}
		
		
		///
		protected void onGiveFeedback(GiveFeedbackEventArgs ea)
		{
			giveFeedback(this, ea);
		}
		
		
		/// Perform a drag/drop operation.
		final DragDropEffects doDragDrop(dfl.data.IDataObject dataObj, DragDropEffects allowedEffects)
		{
			Object foo = cast(Object)dataObj; // Hold a reference to the Object...
			
			DWORD effect;
			DropSource dropsrc;
			dfl.internal.wincom.IDataObject dropdata;
			
			dropsrc = new DropSource(this);
			dropdata = new DtoComDataObject(dataObj);
			
			// dataObj seems to be killed too early.
			switch(DoDragDrop(dropdata, dropsrc, cast(DWORD)allowedEffects, &effect))
			{
				case DRAGDROP_S_DROP: // All good.
					break;
				
				case DRAGDROP_S_CANCEL:
					return DragDropEffects.NONE; // ?
				
				default:
					throw new DflException("Unable to complete drag-drop operation");
			}
			
			return cast(DragDropEffects)effect;
		}
		
		/// ditto
		final DragDropEffects doDragDrop(Data obj, DragDropEffects allowedEffects)
		{
			dfl.data.IDataObject dd;
			dd = new DataObject;
			dd.setData(obj);
			return doDragDrop(dd, allowedEffects);
		}
	}
	
	
	override Dequ opEquals(Object o)
	{
		Control ctrl = cast(Control)o;
		if(!ctrl)
			return 0; // Not equal.
		return opEquals(ctrl);
	}
	
	
	Dequ opEquals(Control ctrl)
	{
		if(!isHandleCreated)
			return super.opEquals(ctrl);
		return hwnd == ctrl.hwnd;
	}
	
	
	override int opCmp(Object o)
	{
		Control ctrl = cast(Control)o;
		if(!ctrl)
			return -1;
		return opCmp(ctrl);
	}
	
	
	int opCmp(Control ctrl)
	{
		if(!isHandleCreated || hwnd != ctrl.hwnd)
			return super.opCmp(ctrl);
		return 0;
	}
	
	
	///
	final bool focus()
	{
		return SetFocus(hwnd) != HWND.init;
	}
	
	
	/// Returns the Control instance from one of its window handles, or null if none.
	// Finds controls that own more than one handle.
	// A combo box has several HWNDs, this would return the
	// correct combo box control if any of those handles are
	// provided.
	static Control fromChildHandle(HWND hwChild)
	{
		Control result;
		for(;;)
		{
			if(!hwChild)
				return null;
			
			result = fromHandle(hwChild);
			if(result)
				return result;
			
			hwChild = GetParent(hwChild);
		}
	}
	
	
	/// Returns the Control instance from its window handle, or null if none.
	static Control fromHandle(HWND hw)
	{
		return Application.lookupHwnd(hw);
	}
	
	
	///
	final Control getChildAtPoint(Point pt)
	{
		HWND hwChild;
		hwChild = ChildWindowFromPoint(hwnd, pt.point);
		if(!hwChild)
			return null;
		return fromChildHandle(hwChild);
	}
	
	
	///
	final void hide()
	{
		setVisibleCore(false);
	}
	
	/// ditto
	final void show()
	{
		/*
		ShowWindow(hwnd, SW_SHOW);
		doShow();
		*/
		
		setVisibleCore(true);
	}
	
	
	package final void redrawEntire()
	{
		if(hwnd)
		{
			SetWindowPos(hwnd, HWND.init, 0, 0, 0, 0, SWP_FRAMECHANGED | SWP_DRAWFRAME | SWP_NOMOVE
				| SWP_NOSIZE | SWP_NOZORDER | SWP_NOACTIVATE);
		}
	}
	
	
	package final void recalcEntire()
	{
		if(hwnd)
		{
			SetWindowPos(hwnd, HWND.init, 0, 0, 0, 0, SWP_FRAMECHANGED | SWP_NOMOVE
				| SWP_NOSIZE | SWP_NOZORDER | SWP_NOACTIVATE);
		}
	}
	
	
	///
	final void invalidate()
	{
		if(!hwnd)
			return;
		
		RedrawWindow(hwnd, null, HRGN.init, RDW_ERASE | RDW_INVALIDATE | RDW_NOCHILDREN);
	}
	
	/// ditto
	final void invalidate(bool andChildren)
	{
		if(!hwnd)
			return;
		
		RedrawWindow(hwnd, null, HRGN.init, RDW_ERASE | RDW_INVALIDATE | (andChildren ? RDW_ALLCHILDREN : RDW_NOCHILDREN));
	}
	
	/// ditto
	final void invalidate(Rect r)
	{
		if(!hwnd)
			return;
		
		RECT rect;
		r.getRect(&rect);
		
		RedrawWindow(hwnd, &rect, HRGN.init, RDW_ERASE | RDW_INVALIDATE | RDW_NOCHILDREN);
	}
	
	/// ditto
	final void invalidate(Rect r, bool andChildren)
	{
		if(!hwnd)
			return;
		
		RECT rect;
		r.getRect(&rect);
		
		RedrawWindow(hwnd, &rect, HRGN.init, RDW_ERASE | RDW_INVALIDATE | (andChildren ? RDW_ALLCHILDREN : RDW_NOCHILDREN));
	}
	
	/// ditto
	final void invalidate(Region rgn)
	{
		if(!hwnd)
			return;
		
		RedrawWindow(hwnd, null, rgn.handle, RDW_ERASE | RDW_INVALIDATE | RDW_NOCHILDREN);
	}
	
	/// ditto
	final void invalidate(Region rgn, bool andChildren)
	{
		if(!hwnd)
			return;
		
		RedrawWindow(hwnd, null, rgn.handle, RDW_ERASE | RDW_INVALIDATE | (andChildren ? RDW_ALLCHILDREN : RDW_NOCHILDREN));
	}
	
	
	///
	// Redraws the entire control, including nonclient area.
	final void redraw()
	{
		if(!hwnd)
			return;
		
		RedrawWindow(hwnd, null, HRGN.init, RDW_ERASE | RDW_INVALIDATE | RDW_FRAME);
	}
	
	
	/// Returns true if the window does not belong to the current thread.
	@property bool invokeRequired() // getter
	{
		DWORD tid = GetWindowThreadProcessId(hwnd, null);
		return tid != GetCurrentThreadId();
	}
	
	
	private static void badInvokeHandle()
	{
		//throw new DflException("Must invoke after creating handle");
		throw new DflException("Must invoke with created handle");
	}
	
	
	/// Synchronously calls a delegate in this Control's thread. This function is thread safe and exceptions are propagated to the caller.
	// Exceptions are propagated back to the caller of invoke().
	final Object invoke(Object delegate(Object[]) dg, Object[] args ...)
	{
		if(!hwnd)
			badInvokeHandle();
		
		InvokeData inv;
		inv.dg = dg;
		inv.args = args;
		
		if(LRESULT_DFL_INVOKE != SendMessageA(hwnd, wmDfl, WPARAM_DFL_INVOKE, cast(LRESULT)&inv))
			throw new DflException("Invoke failure");
		if(inv.exception)
			throw inv.exception;
		
		return inv.result;
	}
	
	/// ditto
	final void invoke(void delegate() dg)
	{
		if(!hwnd)
			badInvokeHandle();
		
		InvokeSimpleData inv;
		inv.dg = dg;
		
		if(LRESULT_DFL_INVOKE != SendMessageA(hwnd, wmDfl, WPARAM_DFL_INVOKE_SIMPLE, cast(LRESULT)&inv))
			throw new DflException("Invoke failure");
		if(inv.exception)
			throw inv.exception;
	}
	
	
	/** Asynchronously calls a function after the window message queue processes its current messages.
	    It is generally not safe to pass references to the delayed function.
	    Exceptions are not propagated to the caller.
	**/
	// Extra.
	// Exceptions will be passed to Application.onThreadException() and
	// trigger the threadException event or the default exception dialog.
	final void delayInvoke(void function() fn)
	{
		if(!hwnd)
			badInvokeHandle();
		
		assert(!invokeRequired);
		
		static assert(fn.sizeof <= LPARAM.sizeof);
		PostMessageA(hwnd, wmDfl, WPARAM_DFL_DELAY_INVOKE, cast(LPARAM)fn);
	}
	
	/// ditto
	// Extra.
	// Exceptions will be passed to Application.onThreadException() and
	// trigger the threadException event or the default exception dialog.
	// Copy of params are passed to fn, they do not exist after it returns.
	// It is unsafe to pass references to a delayed function.
	final void delayInvoke(void function(Control, size_t[]) fn, size_t[] params ...)
	{
		if(!hwnd)
			badInvokeHandle();
		
		assert(!invokeRequired);
		
		static assert((DflInvokeParam*).sizeof <= LPARAM.sizeof);
		
		DflInvokeParam* p;
		p = cast(DflInvokeParam*)dfl.internal.clib.malloc(
			(DflInvokeParam.sizeof - size_t.sizeof)
				+ params.length * size_t.sizeof);
		if(!p)
			throw new OomException();
		
		p.fp = fn;
		p.nparams = params.length;
		p.params.ptr[0 .. params.length] = params[];
		
		PostMessageA(hwnd, wmDfl, WPARAM_DFL_DELAY_INVOKE_PARAMS, cast(LPARAM)p);
	}
	
	deprecated alias delayInvoke beginInvoke;
	
	
	///
	static bool isMnemonic(dchar charCode, Dstring text)
	{
		uint ui;
		for(ui = 0; ui != text.length; ui++)
		{
			if('&' == text[ui])
			{
				if(++ui == text.length)
					break;
				if('&' == text[ui]) // && means literal & so skip it.
					continue;
				dchar dch;
				dch = utf8stringGetUtf32char(text, ui);
				return utf32charToLower(charCode) == utf32charToLower(dch);
			}
		}
		return false;
	}
	
	
	/// Converts a screen Point to a client Point.
	final Point pointToClient(Point pt)
	{
		ScreenToClient(hwnd, &pt.point);
		return pt;
	}
	
	
	/// Converts a client Point to a screen Point.
	final Point pointToScreen(Point pt)
	{
		ClientToScreen(hwnd, &pt.point);
		return pt;
	}
	
	
	/// Converts a screen Rectangle to a client Rectangle.
	final Rect rectangleToClient(Rect r)
	{
		RECT rect;
		r.getRect(&rect);
		
		MapWindowPoints(HWND.init, hwnd, cast(POINT*)&rect, 2);
		return Rect(&rect);
	}
	
	
	/// Converts a client Rectangle to a screen Rectangle.
	final Rect rectangleToScreen(Rect r)
	{
		RECT rect;
		r.getRect(&rect);
		
		MapWindowPoints(hwnd, HWND.init, cast(POINT*)&rect, 2);
		return Rect(&rect);
	}
	
	
	///
	// Return true if processed.
	bool preProcessMessage(ref Message msg)
	{
		return false;
	}
	
	
	///
	final Size getAutoScaleSize(Font f)
	{
		Size result;
		Graphics g;
		g = createGraphics();
		result = g.getScaleSize(f);
		g.dispose();
		return result;
	}
	
	/// ditto
	final Size getAutoScaleSize()
	{
		return getAutoScaleSize(font);
	}
	
	
	///
	void refresh()
	{
		invalidate(true);
	}
	
	
	///
	void resetBackColor()
	{
		//backColor = defaultBackColor;
		backColor = Color.empty;
	}
	
	
	///
	void resetCursor()
	{
		//cursor = new Cursor(LoadCursorA(HINSTANCE.init, IDC_ARROW), false);
		cursor = null;
	}
	
	
	///
	void resetFont()
	{
		//font = defaultFont;
		font = null;
	}
	
	
	///
	void resetForeColor()
	{
		//foreColor = defaultForeColor;
		foreColor = Color.empty;
	}
	
	
	///
	void resetRightToLeft()
	{
		//rightToLeft = false;
		rightToLeft = RightToLeft.INHERIT;
	}
	
	
	///
	void resetText()
	{
		//text = "";
		text = null;
	}
	
	
	///
	// Just allow layout recalc, but don't do it right now.
	final void resumeLayout()
	{
		//_allowLayout = true;
		if(_disallowLayout)
			_disallowLayout--;
	}
	
	/// ditto
	// Allow layout recalc, only do it now if -byes- is true.
	final void resumeLayout(bool byes)
	{
		if(_disallowLayout)
			_disallowLayout--;
		
		// This is correct.
		if(byes)
		{
			if(!_disallowLayout)
				alayout(null);
		}
	}
	
	
	///
	final void suspendLayout()
	{
		//_allowLayout = false;
		_disallowLayout++;
	}
	
	
	final void performLayout(Control affectedControl)
	{
		alayout(affectedControl, false);
	}
	
	
	final void performLayout()
	{
		return performLayout(this);
	}
	
	
	/+
	// TODO: implement.
	
	// Scale both height and width to -ratio-.
	final void scale(float ratio)
	{
		scaleCore(ratio, ratio);
	}
	
	
	// Scale -width- and -height- ratios.
	final void scale(float width, float height)
	{
		scaleCore(width, height);
	}
	
	
	// Also scales child controls recursively.
	protected void scaleCore(float width, float height)
	{
		suspendLayout();
		
		// ...
		
		resumeLayout();
	}
	+/
	
	
	private static bool _eachild(HWND hw, bool delegate(HWND hw) callback, ref size_t xiter, bool nested)
	{
		for(; hw; hw = GetWindow(hw, GW_HWNDNEXT))
		{
			if(!xiter)
				return false;
			xiter--;
			
			LONG st = GetWindowLongA(hw, GWL_STYLE);
			if(!(st & WS_VISIBLE))
				continue;
			if(st & WS_DISABLED)
				continue;
			
			if(!callback(hw))
				return false;
			
			if(nested)
			{
				//LONG exst = GetWindowLongA(hw, GWL_EXSTYLE);
				//if(exst & WS_EX_CONTROLPARENT) // It's no longer added.
				{
					HWND hwc = GetWindow(hw, GW_CHILD);
					if(hwc)
					{
						//if(!_eachild(hwc, callback, xiter, nested))
						if(!_eachild(hwc, callback, xiter, true))
							return false;
					}
				}
			}
		}
		return true;
	}
	
	package static void eachGoodChildHandle(HWND hwparent, bool delegate(HWND hw) callback, bool nested = true)
	{
		HWND hw = GetWindow(hwparent, GW_CHILD);
		size_t xiter = 2000;
		_eachild(hw, callback, xiter, nested);
	}
	
	
	private static bool _isHwndControlSel(HWND hw)
	{
		Control c = Control.fromHandle(hw);
		return c && c.getStyle(ControlStyles.SELECTABLE);
	}
	
	
	package static void _dlgselnext(Form dlg, HWND hwcursel, bool forward,
		bool tabStopOnly = true, bool selectableOnly = false,
		bool nested = true, bool wrap = true,
		HWND hwchildrenof = null)
	{
		//assert(cast(Form)Control.fromHandle(hwdlg) !is null);
		
		if(!hwchildrenof)
			hwchildrenof = dlg.handle;
		if(forward)
		{
			bool foundthis = false, tdone = false;
			HWND hwfirst;
			eachGoodChildHandle(hwchildrenof,
				(HWND hw)
				{
					assert(!tdone);
					if(hw == hwcursel)
					{
						foundthis = true;
					}
					else
					{
						if(!tabStopOnly || (GetWindowLongA(hw, GWL_STYLE) & WS_TABSTOP))
						{
							if(!selectableOnly || _isHwndControlSel(hw))
							{
								if(foundthis)
								{
									//DefDlgProcA(dlg.handle, WM_NEXTDLGCTL, cast(WPARAM)hw, MAKELPARAM(true, 0));
									dlg._selectChild(hw);
									tdone = true;
									return false; // Break.
								}
								else
								{
									if(HWND.init == hwfirst)
										hwfirst = hw;
								}
							}
						}
					}
					return true; // Continue.
				}, nested);
			if(!tdone && HWND.init != hwfirst)
			{
				// If it falls through without finding hwcursel, let it select the first one, even if not wrapping.
				if(wrap || !foundthis)
				{
					//DefDlgProcA(dlg.handle, WM_NEXTDLGCTL, cast(WPARAM)hwfirst, MAKELPARAM(true, 0));
					dlg._selectChild(hwfirst);
				}
			}
		}
		else
		{
			HWND hwprev;
			eachGoodChildHandle(hwchildrenof,
				(HWND hw)
				{
					if(hw == hwcursel)
					{
						if(HWND.init != hwprev) // Otherwise, keep looping and get last one.
							return false; // Break.
						if(!wrap) // No wrapping, so don't get last one.
						{
							assert(HWND.init == hwprev);
							return false; // Break.
						}
					}
					if(!tabStopOnly || (GetWindowLongA(hw, GWL_STYLE) & WS_TABSTOP))
					{
						if(!selectableOnly || _isHwndControlSel(hw))
						{
							hwprev = hw;
						}
					}
					return true; // Continue.
				}, nested);
			// If it falls through without finding hwcursel, let it select the last one, even if not wrapping.
			if(HWND.init != hwprev)
				//DefDlgProcA(dlg.handle, WM_NEXTDLGCTL, cast(WPARAM)hwprev, MAKELPARAM(true, 0));
				dlg._selectChild(hwprev);
		}
	}
	
	
	package final void _selectNextControl(Form ctrltoplevel,
		Control ctrl, bool forward, bool tabStopOnly, bool nested, bool wrap)
	{
		if(!created)
			return;
		
		assert(ctrltoplevel !is null);
		assert(ctrltoplevel.isHandleCreated);
		
		_dlgselnext(ctrltoplevel,
			(ctrl && ctrl.isHandleCreated) ? ctrl.handle : null,
			forward, tabStopOnly, !tabStopOnly, nested, wrap,
			this.handle);
	}
	
	
	package final void _selectThisControl()
	{
		
	}
	
	
	// Only considers child controls of this control.
	final void selectNextControl(Control ctrl, bool forward, bool tabStopOnly, bool nested, bool wrap)
	{
		if(!created)
			return;
		
		auto ctrltoplevel = findForm();
		if(ctrltoplevel)
			return _selectNextControl(ctrltoplevel, ctrl, forward, tabStopOnly, nested, wrap);
	}
	
	
	///
	final void select()
	{
		select(false, false);
	}
	
	/// ditto
	// If -directed- is true, -forward- is used; otherwise, selects this control.
	// If -forward- is true, the next control in the tab order is selected,
	// otherwise the previous control in the tab order is selected.
	// Controls without style ControlStyles.SELECTABLE are skipped.
	void select(bool directed, bool forward)
	{
		if(!created)
			return;
		
		auto ctrltoplevel = findForm();
		if(ctrltoplevel && ctrltoplevel !is this)
		{
			/+ // Old...
			// Even if directed, ensure THIS one is selected first.
			if(!directed || hwnd != GetFocus())
			{
				DefDlgProcA(ctrltoplevel.handle, WM_NEXTDLGCTL, cast(WPARAM)hwnd, MAKELPARAM(true, 0));
			}
			
			if(directed)
			{
				DefDlgProcA(ctrltoplevel.handle, WM_NEXTDLGCTL, !forward, MAKELPARAM(false, 0));
			}
			+/
			
			if(directed)
			{
				_dlgselnext(ctrltoplevel, this.handle, forward);
			}
			else
			{
				ctrltoplevel._selectChild(this);
			}
		}
		else
		{
			focus(); // This must be a form so just focus it ?
		}
	}
	
	
	///
	final void setBounds(int x, int y, int width, int height)
	{
		setBoundsCore(x, y, width, height, BoundsSpecified.ALL);
	}
	
	/// ditto
	final void setBounds(int x, int y, int width, int height, BoundsSpecified specified)
	{
		setBoundsCore(x, y, width, height, specified);
	}
	
	
	override Dstring toString()
	{
		return text;
	}
	
	
	///
	final void update()
	{
		if(!created)
			return;
		
		UpdateWindow(hwnd);
	}
	
	
	///
	// If mouseEnter, mouseHover and mouseLeave events are supported.
	// Returns true on Windows 95 with IE 5.5, Windows 98+ or Windows NT 4.0+.
	static @property bool supportsMouseTracking() // getter
	{
		return trackMouseEvent != null;
	}
	
	
	package final Rect _fetchBounds()
	{
		RECT r;
		GetWindowRect(hwnd, &r);
		HWND hwParent = GetParent(hwnd);
		if(hwParent && (_style() & WS_CHILD))
			MapWindowPoints(HWND.init, hwParent, cast(POINT*)&r, 2);
		return Rect(&r);
	}
	
	
	package final Size _fetchClientSize()
	{
		RECT r;
		GetClientRect(hwnd, &r);
		return Size(r.right, r.bottom);
	}
	
	
	deprecated protected void onInvalidated(InvalidateEventArgs iea)
	{
		//invalidated(this, iea);
	}
	
	
	///
	protected void onPaint(PaintEventArgs pea)
	{
		paint(this, pea);
	}
	
	
	///
	protected void onMove(EventArgs ea)
	{
		move(this, ea);
	}
	
	
	/+
	protected void onLocationChanged(EventArgs ea)
	{
		locationChanged(this, ea);
	}
	+/
	alias onMove onLocationChanged;
	
	
	///
	protected void onResize(EventArgs ea)
	{
		resize(this, ea);
	}
	
	
	/+
	protected void onSizeChanged(EventArgs ea)
	{
		sizeChanged(this, ea);
	}
	+/
	alias onResize onSizeChanged;
	
	
	/+
	// ///
	// Allows comparing before and after dimensions, and also allows modifying the new dimensions.
	deprecated protected void onBeforeResize(BeforeResizeEventArgs ea)
	{
	}
	+/
	
	
	///
	protected void onMouseEnter(MouseEventArgs mea)
	{
		mouseEnter(this, mea);
	}
	
	
	///
	protected void onMouseMove(MouseEventArgs mea)
	{
		mouseMove(this, mea);
	}
	
	
	///
	protected void onKeyDown(KeyEventArgs kea)
	{
		keyDown(this, kea);
	}
	
	
	///
	protected void onKeyPress(KeyPressEventArgs kea)
	{
		keyPress(this, kea);
	}
	
	
	///
	protected void onKeyUp(KeyEventArgs kea)
	{
		keyUp(this, kea);
	}
	
	
	///
	protected void onMouseWheel(MouseEventArgs mea)
	{
		mouseWheel(this, mea);
	}
	
	
	///
	protected void onMouseHover(MouseEventArgs mea)
	{
		mouseHover(this, mea);
	}
	
	
	///
	protected void onMouseLeave(MouseEventArgs mea)
	{
		mouseLeave(this, mea);
	}
	
	
	///
	protected void onMouseDown(MouseEventArgs mea)
	{
		mouseDown(this, mea);
	}
	
	
	///
	protected void onMouseUp(MouseEventArgs mea)
	{
		mouseUp(this, mea);
	}
	
	
	///
	protected void onClick(EventArgs ea)
	{
		click(this, ea);
	}
	
	
	///
	protected void onDoubleClick(EventArgs ea)
	{
		doubleClick(this, ea);
	}
	
	
	///
	protected void onGotFocus(EventArgs ea)
	{
		gotFocus(this, ea);
	}
	
	
	/+
	deprecated protected void onEnter(EventArgs ea)
	{
		//enter(this, ea);
	}
	
	
	deprecated protected void onLeave(EventArgs ea)
	{
		//leave(this, ea);
	}
	
	
	deprecated protected void onValidated(EventArgs ea)
	{
		//validated(this, ea);
	}
	
	
	deprecated protected void onValidating(CancelEventArgs cea)
	{
		/+
		foreach(CancelEventHandler.Handler handler; validating.handlers())
		{
			handler(this, cea);
			
			if(cea.cancel)
				return; // Not validated.
		}
		
		onValidated(EventArgs.empty);
		+/
	}
	+/
	
	
	///
	protected void onLostFocus(EventArgs ea)
	{
		lostFocus(this, ea);
	}
	
	
	///
	protected void onEnabledChanged(EventArgs ea)
	{
		enabledChanged(this, ea);
	}
	
	
	///
	protected void onTextChanged(EventArgs ea)
	{
		textChanged(this, ea);
	}
	
	
	private void _propagateFontAmbience()
	{
		Font fon;
		fon = font;
		
		
		void pa(Control pc)
		{
			foreach(Control ctrl; pc.ccollection)
			{
				if(!ctrl.wfont) // If default.
				{
					if(fon is ctrl.font) // If same default.
					{
						if(ctrl.isHandleCreated)
							SendMessageA(ctrl.hwnd, WM_SETFONT, cast(WPARAM)fon.handle, MAKELPARAM(true, 0));
						ctrl.onFontChanged(EventArgs.empty);
						
						pa(ctrl); // Recursive.
					}
				}
			}
		}
		
		
		pa(this);
	}
	
	
	///
	protected void onFontChanged(EventArgs ea)
	{
		debug(EVENT_PRINT)
		{
			cprintf("{ Event: onFontChanged - Control %.*s }\n", name);
		}
		
		fontChanged(this, ea);
	}
	
	
	///
	protected void onRightToLeftChanged(EventArgs ea)
	{
		debug(EVENT_PRINT)
		{
			cprintf("{ Event: onRightToLeftChanged - Control %.*s }\n", name);
		}
		
		rightToLeftChanged(this, ea);
	}
	
	
	///
	protected void onVisibleChanged(EventArgs ea)
	{
		if(wparent)
		{
			wparent.vchanged();
			suspendLayout(); // Note: exception could cause failure to restore.
			wparent.alayout(this);
			resumeLayout(false);
		}
		if(visible)
			alayout(this);
		
		visibleChanged(this, ea);
		
		if(visible)
		{
			// If no focus or the focused control is hidden, try to select something...
			HWND hwfocus = GetFocus();
			if(!hwfocus
				|| (hwfocus == hwnd && !getStyle(ControlStyles.SELECTABLE))
				|| !IsWindowVisible(hwfocus))
			{
				selectNextControl(null, true, true, true, false);
			}
		}
	}
	
	
	///
	protected void onHelpRequested(HelpEventArgs hea)
	{
		debug(EVENT_PRINT)
		{
			cprintf("{ Event: onHelpRequested - Control %.*s }\n", name);
		}
		
		helpRequested(this, hea);
	}
	
	
	///
	protected void onSystemColorsChanged(EventArgs ea)
	{
		debug(EVENT_PRINT)
		{
			cprintf("{ Event: onSystemColorsChanged - Control %.*s }\n", name);
		}
		
		systemColorsChanged(this, ea);
	}
	
	
	///
	protected void onHandleCreated(EventArgs ea)
	{
		if(!(cbits & CBits.VSTYLE))
			_disableVisualStyle();
		
		Font fon;
		fon = font;
		if(fon)
			SendMessageA(hwnd, WM_SETFONT, cast(WPARAM)fon.handle, 0);
		
		if(wregion)
		{
			// Need to make a copy of the region.
			SetWindowRgn(hwnd, dupHrgn(wregion.handle), true);
		}
		
		version(DFL_NO_DRAG_DROP) {} else
		{
			if(droptarget)
			{
				if(S_OK != RegisterDragDrop(hwnd, droptarget))
				{
					droptarget = null;
					throw new DflException("Unable to register drag-drop");
				}
			}
		}
		
		debug
		{
			_handlecreated = true;
		}
	}
	
	
	///
	protected void onHandleDestroyed(EventArgs ea)
	{
		handleDestroyed(this, ea);
	}
	
	
	///
	protected void onPaintBackground(PaintEventArgs pea)
	{
		RECT rect;
		pea.clipRectangle.getRect(&rect);
		FillRect(pea.graphics.handle, &rect, hbrBg);
	}
	
	
	private static MouseButtons wparamMouseButtons(WPARAM wparam)
	{
		MouseButtons result;
		if(wparam & MK_LBUTTON)
			result |= MouseButtons.LEFT;
		if(wparam & MK_RBUTTON)
			result |= MouseButtons.RIGHT;
		if(wparam & MK_MBUTTON)
			result |= MouseButtons.MIDDLE;
		return result;
	}
	
	
	package final void prepareDc(HDC hdc)
	{
		//SetBkMode(hdc, TRANSPARENT); // ?
		//SetBkMode(hdc, OPAQUE); // ?
		SetBkColor(hdc, backColor.toRgb());
		SetTextColor(hdc, foreColor.toRgb());
	}
	
	
	// Message copy so it cannot be modified.
	deprecated protected void onNotifyMessage(Message msg)
	{
	}
	
	
	/+
	/+package+/ LRESULT customMsg(ref CustomMsg msg) // package
	{
		return 0;
	}
	+/
	
	
	///
	protected void onReflectedMessage(ref Message m)
	{
		switch(m.msg)
		{
			case WM_CTLCOLORSTATIC:
			case WM_CTLCOLORLISTBOX:
			case WM_CTLCOLOREDIT:
			case WM_CTLCOLORSCROLLBAR:
			case WM_CTLCOLORBTN:
			//case WM_CTLCOLORDLG: // ?
			//case 0x0019: //WM_CTLCOLOR; obsolete.
				prepareDc(cast(HDC)m.wParam);
				//assert(GetObjectA(hbrBg, 0, null));
				m.result = cast(LRESULT)hbrBg;
				break;
			
			default:
		}
	}
	
	
	// ChildWindowFromPoint includes both hidden and disabled.
	// This includes disabled windows, but not hidden.
	// Here is a point in this control, see if it's over a visible child.
	// Returns null if not even in this control's client.
	final HWND pointOverVisibleChild(Point pt) // package
	{
		if(pt.x < 0 || pt.y < 0)
			return HWND.init;
		if(pt.x > wclientsz.width || pt.y > wclientsz.height)
			return HWND.init;
		
		// Note: doesn't include non-DFL windows... TO-DO: fix.
		foreach(Control ctrl; ccollection)
		{
			if(!ctrl.visible)
				continue;
			if(!ctrl.isHandleCreated) // Shouldn't..
				continue;
			if(ctrl.bounds.contains(pt))
				return ctrl.hwnd;
		}
		
		return hwnd; // Just over this control.
	}
	
	
	version(_DFL_WINDOWS_HUNG_WORKAROUND)
	{
		DWORD ldlgcode = 0;
	}
	
	
	///
	protected void wndProc(ref Message msg)
	{
		//if(ctrlStyle & ControlStyles.ENABLE_NOTIFY_MESSAGE)
		//	onNotifyMessage(msg);
		
		switch(msg.msg)
		{
			case WM_PAINT:
				{
					// This can't be done in BeginPaint() becuase part might get
					// validated during this event ?
					//RECT uprect;
					//GetUpdateRect(hwnd, &uprect, true);
					//onInvalidated(new InvalidateEventArgs(Rect(&uprect)));
					
					PAINTSTRUCT ps;
					BeginPaint(msg.hWnd, &ps);
					try
					{
						//onInvalidated(new InvalidateEventArgs(Rect(&uprect)));
						
						scope PaintEventArgs pea = new PaintEventArgs(new Graphics(ps.hdc, false), Rect(&ps.rcPaint));
						
						// Probably because ControlStyles.ALL_PAINTING_IN_WM_PAINT.
						if(ps.fErase)
						{
							prepareDc(ps.hdc);
							onPaintBackground(pea);
						}
						
						prepareDc(ps.hdc);
						onPaint(pea);
					}
					finally
					{
						EndPaint(hwnd, &ps);
					}
				}
				return;
			
			case WM_ERASEBKGND:
				if(ctrlStyle & ControlStyles.OPAQUE)
				{
					msg.result = 1; // Erased.
				}
				else if(!(ctrlStyle & ControlStyles.ALL_PAINTING_IN_WM_PAINT))
				{
					RECT uprect;
					/+
					GetUpdateRect(hwnd, &uprect, false);
					+/
					uprect.left = 0;
					uprect.top = 0;
					uprect.right = clientSize.width;
					uprect.bottom = clientSize.height;
					
					prepareDc(cast(HDC)msg.wParam);
					scope PaintEventArgs pea = new PaintEventArgs(new Graphics(cast(HDC)msg.wParam, false), Rect(&uprect));
					onPaintBackground(pea);
					msg.result = 1; // Erased.
				}
				return;
			
			case WM_PRINTCLIENT:
				prepareDc(cast(HDC)msg.wParam);
				scope PaintEventArgs pea = new PaintEventArgs(new Graphics(cast(HDC)msg.wParam, false), Rect(Point(0, 0), wclientsz));
				onPaint(pea);
				return;
			
			case WM_CTLCOLORSTATIC:
			case WM_CTLCOLORLISTBOX:
			case WM_CTLCOLOREDIT:
			case WM_CTLCOLORSCROLLBAR:
			case WM_CTLCOLORBTN:
			//case WM_CTLCOLORDLG: // ?
			//case 0x0019: //WM_CTLCOLOR; obsolete.
				{
					Control ctrl = fromChildHandle(cast(HWND)msg.lParam);
					if(ctrl)
					{
						//ctrl.prepareDc(cast(HDC)msg.wParam);
						//msg.result = cast(LRESULT)ctrl.hbrBg;
						ctrl.onReflectedMessage(msg);
						return;
					}
				}
				break;
			
			case WM_WINDOWPOSCHANGED:
				{
					WINDOWPOS* wp = cast(WINDOWPOS*)msg.lParam;
					bool needLayout = false;
					
					//if(!wp.hwndInsertAfter)
					//	wp.flags |= SWP_NOZORDER; // ?
					
					bool didvis = false;
					if(wp.flags & (SWP_HIDEWINDOW | SWP_SHOWWINDOW))
					{
						needLayout = true; // Only if not didvis / if not recreating.
						if(!recreatingHandle) // Note: suppresses onVisibleChanged
						{
							if(wp.flags & SWP_HIDEWINDOW) // Hiding.
								_clicking = false;
							onVisibleChanged(EventArgs.empty);
							didvis = true;
							//break; // Showing min/max includes other flags.
						}
					}
					
					if(!(wp.flags & SWP_NOZORDER) /+ || (wp.flags & SWP_SHOWWINDOW) +/)
					{
						if(wparent)
							wparent.vchanged();
					}
					
					if(!(wp.flags & SWP_NOMOVE))
					{
						onMove(EventArgs.empty);
					}
					
					if(!(wp.flags & SWP_NOSIZE))
					{
						if(szdraw)
							invalidate(true);
						
						onResize(EventArgs.empty);
						
						needLayout = true;
					}
					
					// Frame change results in a new client size.
					if(wp.flags & SWP_FRAMECHANGED)
					{
						if(szdraw)
							invalidate(true);
						
						needLayout = true;
					}
					
					if(!didvis) // onVisibleChanged already triggers layout.
					{
						if(/+ (wp.flags & SWP_SHOWWINDOW) || +/ !(wp.flags & SWP_NOSIZE) ||
							!(wp.flags & SWP_NOZORDER)) // z-order determines what is positioned first.
						{
							suspendLayout(); // Note: exception could cause failure to restore.
							if(wparent)
								wparent.alayout(this);
							resumeLayout(false);
							needLayout = true;
						}
						
						if(needLayout)
						{
							alayout(this);
						}
					}
				}
				break;
			
			/+
			case WM_WINDOWPOSCHANGING:
				{
					WINDOWPOS* wp = cast(WINDOWPOS*)msg.lParam;
					
					/+
					//if(!(wp.flags & SWP_NOSIZE))
					if(width != wp.cx || height != wp.cy)
					{
						scope BeforeResizeEventArgs ea = new BeforeResizeEventArgs(wp.cx, wp.cy);
						onBeforeResize(ea);
						/+if(wp.cx == ea.width && wp.cy == ea.height)
						{
							wp.flags |= SWP_NOSIZE;
						}
						else+/
						{
							wp.cx = ea.width;
							wp.cy = ea.height;
						}
					}
					+/
				}
				break;
			+/
			
			case WM_MOUSEMOVE:
				if(_clicking)
				{
					if(!(msg.wParam & MK_LBUTTON))
						_clicking = false;
				}
				
				if(trackMouseEvent) // Requires Windows 95 with IE 5.5, 98 or NT4.
				{
					if(!menter)
					{
						menter = true;
						
						POINT pt;
						GetCursorPos(&pt);
						MapWindowPoints(HWND.init, hwnd, &pt, 1);
						scope MouseEventArgs mea = new MouseEventArgs(wparamMouseButtons(msg.wParam), 0, pt.x, pt.y, 0);
						onMouseEnter(mea);
						
						TRACKMOUSEEVENT tme;
						tme.cbSize = TRACKMOUSEEVENT.sizeof;
						tme.dwFlags = TME_HOVER | TME_LEAVE;
						tme.hwndTrack = msg.hWnd;
						tme.dwHoverTime = HOVER_DEFAULT;
						trackMouseEvent(&tme);
					}
				}
				
				onMouseMove(new MouseEventArgs(wparamMouseButtons(msg.wParam), 0, cast(short)LOWORD(msg.lParam), cast(short)HIWORD(msg.lParam), 0));
				break;
			
			case WM_SETCURSOR:
				// Just update it so that Control.defWndProc() can set it correctly.
				if(cast(HWND)msg.wParam == hwnd)
				{
					Cursor cur;
					cur = cursor;
					if(cur)
					{
						if(cast(HCURSOR)GetClassLongA(hwnd, GCL_HCURSOR) != cur.handle)
							SetClassLongA(hwnd, GCL_HCURSOR, cast(LONG)cur.handle);
					}
					else
					{
						if(cast(HCURSOR)GetClassLongA(hwnd, GCL_HCURSOR) != HCURSOR.init)
							SetClassLongA(hwnd, GCL_HCURSOR, cast(LONG)cast(HCURSOR)null);
					}
					Control.defWndProc(msg);
					return;
				}
				break;
			
			/+
			case WM_NEXTDLGCTL:
				if(!LOWORD(msg.lParam))
				{
					select(true, msg.wParam != 0);
					return;
				}
				break;
			+/
			
			case WM_KEYDOWN:
			case WM_KEYUP:
			case WM_CHAR:
			case WM_SYSKEYDOWN:
			case WM_SYSKEYUP:
			case WM_SYSCHAR:
			//case WM_IMECHAR:
				/+
				if(processKeyEventArgs(msg))
				{
					// The key was processed.
					msg.result = 0;
					return;
				}
				msg.result = 1; // The key was not processed.
				break;
				+/
				msg.result = !processKeyEventArgs(msg);
				return;
			
			case WM_MOUSEWHEEL: // Requires Windows 98 or NT4.
				{
					scope MouseEventArgs mea = new MouseEventArgs(wparamMouseButtons(LOWORD(msg.wParam)), 0, cast(short)LOWORD(msg.lParam), cast(short)HIWORD(msg.lParam), cast(short)HIWORD(msg.wParam));
					onMouseWheel(mea);
				}
				break;
			
			case WM_MOUSEHOVER: // Requires Windows 95 with IE 5.5, 98 or NT4.
				{
					scope MouseEventArgs mea = new MouseEventArgs(wparamMouseButtons(msg.wParam), 0, cast(short)LOWORD(msg.lParam), cast(short)HIWORD(msg.lParam), 0);
					onMouseHover(mea);
				}
				break;
			
			case WM_MOUSELEAVE: // Requires Windows 95 with IE 5.5, 98 or NT4.
				{
					menter = false;
					
					POINT pt;
					GetCursorPos(&pt);
					MapWindowPoints(HWND.init, hwnd, &pt, 1);
					scope MouseEventArgs mea = new MouseEventArgs(wparamMouseButtons(msg.wParam), 0, pt.x, pt.y, 0);
					onMouseLeave(mea);
				}
				break;
			
			case WM_LBUTTONDOWN:
				{
					_clicking = true;
					
					scope MouseEventArgs mea = new MouseEventArgs(MouseButtons.LEFT, 1, cast(short)LOWORD(msg.lParam), cast(short)HIWORD(msg.lParam), 0);
					onMouseDown(mea);
					
					//if(ctrlStyle & ControlStyles.SELECTABLE)
					//	SetFocus(hwnd); // No, this goofs up stuff, including the ComboBox dropdown.
				}
				break;
			
			case WM_RBUTTONDOWN:
				{
					scope MouseEventArgs mea = new MouseEventArgs(MouseButtons.RIGHT, 1, cast(short)LOWORD(msg.lParam), cast(short)HIWORD(msg.lParam), 0);
					onMouseDown(mea);
				}
				break;
			
			case WM_MBUTTONDOWN:
				{
					scope MouseEventArgs mea = new MouseEventArgs(MouseButtons.MIDDLE, 1, cast(short)LOWORD(msg.lParam), cast(short)HIWORD(msg.lParam), 0);
					onMouseDown(mea);
				}
				break;
			
			case WM_LBUTTONUP:
				{
					if(msg.lParam == -1)
						break;
					
					// Use temp in case of exception.
					bool wasClicking = _clicking;
					_clicking = false;
					
					scope MouseEventArgs mea = new MouseEventArgs(MouseButtons.LEFT, 1, cast(short)LOWORD(msg.lParam), cast(short)HIWORD(msg.lParam), 0);
					onMouseUp(mea);
					
					if(wasClicking && (ctrlStyle & ControlStyles.STANDARD_CLICK))
					{
						// See if the mouse up was over the control.
						if(Rect(0, 0, wclientsz.width, wclientsz.height).contains(mea.x, mea.y))
						{
							// Now make sure there's no child in the way.
							//if(ChildWindowFromPoint(hwnd, Point(mea.x, mea.y).point) == hwnd) // Includes hidden windows.
							if(pointOverVisibleChild(Point(mea.x, mea.y)) == hwnd)
								onClick(EventArgs.empty);
						}
					}
				}
				break;
			
			version(CUSTOM_MSG_HOOK)
			{}
			else
			{
				case WM_DRAWITEM:
					{
						Control ctrl;
						
						DRAWITEMSTRUCT* dis = cast(DRAWITEMSTRUCT*)msg.lParam;
						if(dis.CtlType == ODT_MENU)
						{
							// dis.hwndItem is the HMENU.
						}
						else
						{
							ctrl = Control.fromChildHandle(dis.hwndItem);
							if(ctrl)
							{
								//msg.result = ctrl.customMsg(*(cast(CustomMsg*)&msg));
								ctrl.onReflectedMessage(msg);
								return;
							}
						}
					}
					break;
				
				case WM_MEASUREITEM:
					{
						Control ctrl;
						
						MEASUREITEMSTRUCT* mis = cast(MEASUREITEMSTRUCT*)msg.lParam;
						if(!(mis.CtlType == ODT_MENU))
						{
							ctrl = Control.fromChildHandle(cast(HWND)mis.CtlID);
							if(ctrl)
							{
								//msg.result = ctrl.customMsg(*(cast(CustomMsg*)&msg));
								ctrl.onReflectedMessage(msg);
								return;
							}
						}
					}
					break;
				
				case WM_COMMAND:
					{
						/+
						switch(LOWORD(msg.wParam))
						{
							case IDOK:
							case IDCANCEL:
								if(parent)
								{
									parent.wndProc(msg);
								}
								//break;
								return; // ?
							
							default:
						}
						+/
						
						Control ctrl;
						
						ctrl = Control.fromChildHandle(cast(HWND)msg.lParam);
						if(ctrl)
						{
							//msg.result = ctrl.customMsg(*(cast(CustomMsg*)&msg));
							ctrl.onReflectedMessage(msg);
							return;
						}
						else
						{
							version(DFL_NO_MENUS)
							{
							}
							else
							{
								MenuItem m;
								
								m = cast(MenuItem)Application.lookupMenuID(LOWORD(msg.wParam));
								if(m)
								{
									//msg.result = m.customMsg(*(cast(CustomMsg*)&msg));
									m._reflectMenu(msg);
									//return; // ?
								}
							}
						}
					}
					break;
				
				case WM_NOTIFY:
					{
						Control ctrl;
						NMHDR* nmh;
						nmh = cast(NMHDR*)msg.lParam;
						
						ctrl = Control.fromChildHandle(nmh.hwndFrom);
						if(ctrl)
						{
							//msg.result = ctrl.customMsg(*(cast(CustomMsg*)&msg));
							ctrl.onReflectedMessage(msg);
							return;
						}
					}
					break;
				
				version(DFL_NO_MENUS)
				{
				}
				else
				{
					case WM_MENUSELECT:
						{
							UINT mflags;
							UINT uitem;
							int mid;
							MenuItem m;
							
							mflags = HIWORD(msg.wParam);
							uitem = LOWORD(msg.wParam); // Depends on the flags.
							
							if(mflags & MF_SYSMENU)
								break;
							
							if(mflags & MF_POPUP)
							{
								// -uitem- is an index.
								mid = GetMenuItemID(cast(HMENU)msg.lParam, uitem);
							}
							else
							{
								// -uitem- is the item identifier.
								mid = uitem;
							}
							
							m = cast(MenuItem)Application.lookupMenuID(mid);
							if(m)
							{
								//msg.result = m.customMsg(*(cast(CustomMsg*)&msg));
								m._reflectMenu(msg);
								//return;
							}
						}
						break;
					
					case WM_INITMENUPOPUP:
						if(HIWORD(msg.lParam))
						{
							// System menu.
						}
						else
						{
							MenuItem m;
							
							//m = cast(MenuItem)Application.lookupMenuID(GetMenuItemID(cast(HMENU)msg.wParam, LOWORD(msg.lParam)));
							m = cast(MenuItem)Application.lookupMenu(cast(HMENU)msg.wParam);
							if(m)
							{
								//msg.result = m.customMsg(*(cast(CustomMsg*)&msg));
								m._reflectMenu(msg);
								//return;
							}
						}
						break;
					
					case WM_INITMENU:
						{
							ContextMenu m;
							
							m = cast(ContextMenu)Application.lookupMenu(cast(HMENU)msg.wParam);
							if(m)
							{
								//msg.result = m.customMsg(*(cast(CustomMsg*)&msg));
								m._reflectMenu(msg);
								//return;
							}
						}
						break;
				}
			}
			
			case WM_RBUTTONUP:
				{
					scope MouseEventArgs mea = new MouseEventArgs(MouseButtons.RIGHT, 1, cast(short)LOWORD(msg.lParam), cast(short)HIWORD(msg.lParam), 0);
					onMouseUp(mea);
				}
				break;
			
			case WM_MBUTTONUP:
				{
					scope MouseEventArgs mea = new MouseEventArgs(MouseButtons.MIDDLE, 1, cast(short)LOWORD(msg.lParam), cast(short)HIWORD(msg.lParam), 0);
					onMouseUp(mea);
				}
				break;
			
			case WM_LBUTTONDBLCLK:
				{
					scope MouseEventArgs mea = new MouseEventArgs(MouseButtons.LEFT, 2, cast(short)LOWORD(msg.lParam), cast(short)HIWORD(msg.lParam), 0);
					onMouseDown(mea);
					
					if((ctrlStyle & (ControlStyles.STANDARD_CLICK | ControlStyles.STANDARD_DOUBLE_CLICK))
						== (ControlStyles.STANDARD_CLICK | ControlStyles.STANDARD_DOUBLE_CLICK))
					{
						onDoubleClick(EventArgs.empty);
					}
				}
				break;
			
			case WM_RBUTTONDBLCLK:
				{
					scope MouseEventArgs mea = new MouseEventArgs(MouseButtons.RIGHT, 2, cast(short)LOWORD(msg.lParam), cast(short)HIWORD(msg.lParam), 0);
					onMouseDown(mea);
				}
				break;
			
			case WM_MBUTTONDBLCLK:
				{
					scope MouseEventArgs mea = new MouseEventArgs(MouseButtons.MIDDLE, 2, cast(short)LOWORD(msg.lParam), cast(short)HIWORD(msg.lParam), 0);
					onMouseDown(mea);
				}
				break;
			
			case WM_SETFOCUS:
				_wmSetFocus();
				// defWndProc* Form focuses a child.
				break;
			
			case WM_KILLFOCUS:
				_wmKillFocus();
				break;
			
			case WM_ENABLE:
				onEnabledChanged(EventArgs.empty);
				
				// defWndProc*
				break;
			
			/+
			case WM_NEXTDLGCTL:
				if(msg.wParam && !LOWORD(msg.lParam))
				{
					HWND hwf;
					hwf = GetFocus();
					if(hwf)
					{
						Control hwc;
						hwc = Control.fromHandle(hwf);
						if(hwc)
						{
							if(hwc._rtype() & 0x20) // TabControl
							{
								hwf = GetWindow(hwf, GW_CHILD);
								if(hwf)
								{
									// Can't do this because it could be modifying someone else's memory.
									//msg.wParam = cast(WPARAM)hwf;
									//msg.lParam = MAKELPARAM(1, 0);
									msg.result = DefWindowProcA(msg.hWnd, WM_NEXTDLGCTL, cast(WPARAM)hwf, MAKELPARAM(TRUE, 0));
									return;
								}
							}
						}
					}
				}
				break;
			+/
			
			case WM_SETTEXT:
				defWndProc(msg);
				
				// Need to fetch it because cast(char*)lparam isn't always accessible ?
				// Should this go in _wndProc()? Need to defWndProc() first ?
				if(ctrlStyle & ControlStyles.CACHE_TEXT)
					wtext = _fetchText();
				
				onTextChanged(EventArgs.empty);
				return;
			
			case WM_SETFONT:
				// Don't replace -wfont- if it's the same one, beacuse the old Font
				// object will get garbage collected and probably delete the HFONT.
				
				//onFontChanged(EventArgs.empty);
				
				// defWndProc*
				return;
			
			/+
			case WM_STYLECHANGED:
				{
					//defWndProc(msg);
					
					STYLESTRUCT* ss = cast(STYLESTRUCT*)msg.lParam;
					DWORD changed = ss.styleOld ^ ss.styleNew;
					
					if(msg.wParam == GWL_EXSTYLE)
					{
						//if(changed & WS_EX_RTLREADING)
						//	onRightToLeftChanged(EventArgs.empty);
					}
				}
				break;
			+/
			
			case WM_ACTIVATE:
				switch(LOWORD(msg.wParam))
				{
					case WA_INACTIVE:
						_clicking = false;
						break;
					
					default:
				}
				break;
			
			version(DFL_NO_MENUS)
			{
			}
			else
			{
				case WM_CONTEXTMENU:
					if(hwnd == cast(HWND)msg.wParam)
					{
						if(cmenu)
						{
							// Shift+F10 causes xPos and yPos to be -1.
							
							Point point;
							
							if(msg.lParam == -1)
								point = pointToScreen(Point(0, 0));
							else
								point = Point(cast(short)LOWORD(msg.lParam), cast(short)HIWORD(msg.lParam));
							
							SetFocus(handle); // ?
							cmenu.show(this, point);
							
							return;
						}
					}
					break;
			}
			
			case WM_HELP:
				{
					HELPINFO* hi = cast(HELPINFO*)msg.lParam;
					
					scope HelpEventArgs hea = new HelpEventArgs(Point(hi.MousePos.x, hi.MousePos.y));
					onHelpRequested(hea);
					if(hea.handled)
					{
						msg.result = TRUE;
						return;
					}
				}
				break;
			
			case WM_SYSCOLORCHANGE:
				onSystemColorsChanged(EventArgs.empty);
				
				// Need to send the message to children for some common controls to update properly.
				foreach(Control ctrl; ccollection)
				{
					SendMessageA(ctrl.handle, WM_SYSCOLORCHANGE, msg.wParam, msg.lParam);
				}
				break;
			
			case WM_SETTINGCHANGE:
				// Send the message to children.
				foreach(Control ctrl; ccollection)
				{
					SendMessageA(ctrl.handle, WM_SETTINGCHANGE, msg.wParam, msg.lParam);
				}
				break;
			
			case WM_PALETTECHANGED:
				/+
				if(cast(HWND)msg.wParam != hwnd)
				{
					// Realize palette.
				}
				+/
				
				// Send the message to children.
				foreach(Control ctrl; ccollection)
				{
					SendMessageA(ctrl.handle, WM_PALETTECHANGED, msg.wParam, msg.lParam);
				}
				break;
			
			//case WM_QUERYNEWPALETTE: // Send this message to children ?
			
			/+
			// Moved this stuff to -parent-.
			case WM_PARENTNOTIFY:
				switch(LOWORD(msg.wParam))
				{
					case WM_DESTROY:
						Control ctrl = fromChildHandle(cast(HWND)msg.lParam);
						if(ctrl)
						{
							_ctrlremoved(new ControlEventArgs(ctrl));
							
							// ?
							vchanged();
							//alayout(ctrl); // This is already being called from somewhere else..
						}
						break;
					
					/+
					case WM_CREATE:
						initLayout();
						break;
					+/
					
					default:
				}
				break;
			+/
			
			case WM_CREATE:
				/+
				if(wparent)
					initLayout(); // ?
				+/
				if(cbits & CBits.NEED_INIT_LAYOUT)
				{
					if(visible)
					{
						if(wparent)
						{
							wparent.vchanged();
							suspendLayout(); // Note: exception could cause failure to restore.
							wparent.alayout(this);
							resumeLayout(false);
						}
						alayout(this);
					}
				}
				break;
			
			case WM_DESTROY:
				onHandleDestroyed(EventArgs.empty);
				break;
			
			case WM_GETDLGCODE:
				{
					version(_DFL_WINDOWS_HUNG_WORKAROUND)
					{
						/+
						if(ctrlStyle & ControlStyles.CONTAINER_CONTROL)
						{
							if(!(_exStyle & WS_EX_CONTROLPARENT))
								assert(0);
						}
						+/
						
						DWORD dw;
						dw = GetTickCount();
						if(ldlgcode < dw - 1020)
						{
							ldlgcode = dw - 1000;
						}
						else
						{
							ldlgcode += 50;
							if(ldlgcode > dw)
							{
								// Probably a problem with WS_EX_CONTROLPARENT and WS_TABSTOP.
								if(ldlgcode >= ldlgcode.max - 10_000)
								{
									ldlgcode = 0;
									throw new WindowsHungDflException("Windows hung");
								}
								//msg.result |= 0x0004 | 0x0002 | 0x0001; //DLGC_WANTALLKEYS | DLGC_WANTTAB | DLGC_WANTARROWS;
								ldlgcode = ldlgcode.max - 10_000;
								return;
							}
						}
					}
					
					/+
					if(msg.lParam)
					{
						Message m;
						m._winMsg = *cast(MSG*)msg.lParam;
						if(processKeyEventArgs(m))
							return;
					}
					+/
					
					defWndProc(msg);
					
					if(ctrlStyle & ControlStyles.WANT_ALL_KEYS)
						msg.result |= DLGC_WANTALLKEYS;
					
					// Only want chars if ALT isn't down, because it would break mnemonics.
					if(!(GetKeyState(VK_MENU) & 0x8000))
						msg.result |= DLGC_WANTCHARS;
					
				}
				return;
			
			case WM_CLOSE:
				/+{
					if(parent)
					{
						Message mp;
						mp = msg;
						mp.hWnd = parent.handle;
						parent.wndProc(mp); // Pass to parent so it can decide what to do.
					}
				}+/
				return; // Prevent defWndProc from destroying the window!
			
			case 0: // WM_NULL
				// Don't confuse with failed RegisterWindowMessage().
				break;
			
			default:
				//defWndProc(msg);
				version(DFL_NO_WM_GETCONTROLNAME)
				{
				}
				else
				{
					if(msg.msg == wmGetControlName)
					{
						//cprintf("WM_GETCONTROLNAME: %.*s; wparam: %d\n", cast(uint)name.length, name.ptr, msg.wParam);
						if(msg.wParam && this.name.length)
						{
							OSVERSIONINFOA osver;
							osver.dwOSVersionInfoSize = OSVERSIONINFOA.sizeof;
							if(GetVersionExA(&osver))
							{
								try
								{
									if(osver.dwPlatformId <= VER_PLATFORM_WIN32_WINDOWS)
									{
										version(DFL_UNICODE)
										{
										}
										else
										{
											// ANSI.
											Dstring ansi;
											ansi = dfl.internal.utf.toAnsi(this.name);
											if(msg.wParam <= ansi.length)
												ansi = ansi[0 .. msg.wParam - 1];
											(cast(char*)msg.lParam)[0 .. ansi.length] = ansi[];
											(cast(char*)msg.lParam)[ansi.length] = 0;
											msg.result = ansi.length + 1;
										}
									}
									else
									{
										// Unicode.
										Dwstring uni;
										uni = dfl.internal.utf.toUnicode(this.name);
										if(msg.wParam <= uni.length)
											uni = uni[0 .. msg.wParam - 1];
										(cast(wchar*)msg.lParam)[0 .. uni.length] = uni[];
										(cast(wchar*)msg.lParam)[uni.length] = 0;
										msg.result = uni.length + 1;
									}
								}
								catch
								{
								}
								return;
							}
						}
					}
				}
		}
		
		defWndProc(msg);
		
		if(msg.msg == WM_CREATE)
		{
			EventArgs ea;
			ea = EventArgs.empty;
			onHandleCreated(ea);
			
			debug
			{
				assert(_handlecreated, "If overriding onHandleCreated(), be sure to call super.onHandleCreated()!");
			}
			handleCreated(this, ea);
			debug
			{
				_handlecreated = false; // Reset.
			}
		}
	}
	
	
	package final void _wmSetFocus()
	{
		//onEnter(EventArgs.empty);
		
		onGotFocus(EventArgs.empty);
		
		// defWndProc* Form focuses a child.
	}
	
	
	package final void _wmKillFocus()
	{
		_clicking = false;
		
		//onLeave(EventArgs.empty);
		
		//if(cvalidation)
		//	onValidating(new CancelEventArgs);
		
		onLostFocus(EventArgs.empty);
	}
	
	
	///
	protected void defWndProc(ref Message msg)
	{
		//msg.result = DefWindowProcA(msg.hWnd, msg.msg, msg.wParam, msg.lParam);
		msg.result = dfl.internal.utf.defWindowProc(msg.hWnd, msg.msg, msg.wParam, msg.lParam);
	}
	
	
	// Always called right when destroyed, before doing anything else.
	// hwnd is cleared after this step.
	void _destroying() // package
	{
		//wparent = null; // ?
	}
	
	
	// This function must be called FIRST for EVERY message to this
	// window in order to keep the correct window state.
	// This function must not throw exceptions.
	package final void mustWndProc(ref Message msg)
	{
		if(needCalcSize)
		{
			needCalcSize = false;
			RECT crect;
			GetClientRect(msg.hWnd, &crect);
			wclientsz.width = crect.right;
			wclientsz.height = crect.bottom;
		}
		
		switch(msg.msg)
		{
			case WM_NCCALCSIZE:
				needCalcSize = true;
				break;
			
			case WM_WINDOWPOSCHANGED:
				{
					WINDOWPOS* wp = cast(WINDOWPOS*)msg.lParam;
					
					if(!recreatingHandle)
					{
						//wstyle = GetWindowLongA(hwnd, GWL_STYLE); // ..WM_SHOWWINDOW.
						if(wp.flags & (SWP_HIDEWINDOW | SWP_SHOWWINDOW))
						{
							//wstyle = GetWindowLongA(hwnd, GWL_STYLE);
							cbits |= CBits.VISIBLE;
							wstyle |= WS_VISIBLE;
							if(wp.flags & SWP_HIDEWINDOW) // Hiding.
							{
								cbits &= ~CBits.VISIBLE;
								wstyle &= ~WS_VISIBLE;
							}
							//break; // Showing min/max includes other flags.
						}
					}
					
					//if(!(wp.flags & SWP_NOMOVE))
					//	wrect.location = Point(wp.x, wp.y);
					if(!(wp.flags & SWP_NOSIZE) || !(wp.flags & SWP_NOMOVE) || (wp.flags & SWP_FRAMECHANGED))
					{
						//wrect = _fetchBounds();
						wrect = Rect(wp.x, wp.y, wp.cx, wp.cy);
						wclientsz = _fetchClientSize();
					}
					
					if((wp.flags & (SWP_SHOWWINDOW | SWP_HIDEWINDOW)) || !(wp.flags & SWP_NOSIZE))
					{
						DWORD rstyle;
						rstyle = GetWindowLongA(msg.hWnd, GWL_STYLE);
						rstyle &= WS_MAXIMIZE | WS_MINIMIZE;
						wstyle &= ~(WS_MAXIMIZE | WS_MINIMIZE);
						wstyle |= rstyle;
					}
				}
				break;
			
			/+
			case WM_WINDOWPOSCHANGING:
				//oldwrect = wrect;
				break;
			+/
			
			/+
			case WM_SETFONT:
				//wfont = _fetchFont();
				break;
			+/
			
			case WM_STYLECHANGED:
				{
					STYLESTRUCT* ss = cast(STYLESTRUCT*)msg.lParam;
					
					if(msg.wParam == GWL_STYLE)
						wstyle = ss.styleNew;
					else if(msg.wParam == GWL_EXSTYLE)
						wexstyle = ss.styleNew;
					
					/+
					wrect = _fetchBounds();
					wclientsz = _fetchClientSize();
					+/
				}
				break;
			
			/+
			// NOTE: this is sent even if the parent is shown.
			case WM_SHOWWINDOW:
				if(!msg.lParam)
				{
					/+
					{
						cbits &= ~(CBits.SW_SHOWN | CBits.SW_HIDDEN);
						DWORD rstyle;
						rstyle = GetWindowLongA(msg.hWnd, GWL_STYLE);
						if(cast(BOOL)msg.wParam)
						{
							//wstyle |= WS_VISIBLE;
							if(!(WS_VISIBLE & wstyle) && (WS_VISIBLE & rstyle))
							{
								wstyle = rstyle;
								cbits |= CBits.SW_SHOWN;
								
								try
								{
									createChildren(); // Might throw.
								}
								catch(DThrowable e)
								{
									Application.onThreadException(e);
								}
							}
							wstyle = rstyle;
						}
						else
						{
							//wstyle &= ~WS_VISIBLE;
							if((WS_VISIBLE & wstyle) && !(WS_VISIBLE & rstyle))
							{
								wstyle = rstyle;
								cbits |= CBits.SW_HIDDEN;
							}
							wstyle = rstyle;
						}
					}
					+/
					wstyle = GetWindowLongA(msg.hWnd, GWL_STYLE);
					//if(cbits & CBits.FVISIBLE)
					//	wstyle |= WS_VISIBLE;
				}
				break;
			+/
			
			case WM_ENABLE:
				/+
				//if(IsWindowEnabled(hwnd))
				if(cast(BOOL)msg.wParam)
					wstyle &= ~WS_DISABLED;
				else
					wstyle |= WS_DISABLED;
				+/
				wstyle = GetWindowLongA(hwnd, GWL_STYLE);
				break;
			
			/+
			case WM_PARENTNOTIFY:
				switch(LOWORD(msg.wParam))
				{
					case WM_DESTROY:
						// ...
						break;
					
					default:
				}
				break;
			+/
			
			case WM_NCCREATE:
				{
					//hwnd = msg.hWnd;
					
					/+
					// Not using CREATESTRUCT for window bounds because it can contain
					// CW_USEDEFAULT and other magic values.
					
					CREATESTRUCTA* cs;
					cs = cast(CREATESTRUCTA*)msg.lParam;
					
					//wrect = Rect(cs.x, cs.y, cs.cx, cs.cy);
					+/
					
					wrect = _fetchBounds();
					//oldwrect = wrect;
					wclientsz = _fetchClientSize();
				}
				break;
			
			case WM_CREATE:
				try
				{
					cbits |= CBits.CREATED;
					
					//hwnd = msg.hWnd;
					
					CREATESTRUCTA* cs;
					cs = cast(CREATESTRUCTA*)msg.lParam;
					/+
					// Done in WM_NCCREATE now.
					//wrect = _fetchBounds();
					wrect = Rect(cs.x, cs.y, cs.cx, cs.cy);
					wclientsz = _fetchClientSize();
					+/
					
					// If class style was changed, update.
					if(_fetchClassLong() != wclassStyle)
						SetClassLongA(hwnd, GCL_STYLE, wclassStyle);
					
					// Need to update clientSize in case of styles in createParams().
					wclientsz = _fetchClientSize();
					
					//finishCreating(msg.hWnd);
					
					if(!(ctrlStyle & ControlStyles.CACHE_TEXT))
						wtext = null;
					
					/+
					// Gets created on demand instead.
					if(Color.empty != backc)
					{
						hbrBg = backc.createBrush();
					}
					+/
					
					/+
					// ?
					wstyle = cs.style;
					wexstyle = cs.dwExStyle;
					+/
					
					createChildren(); // Might throw. Used to be commented-out.
					
					if(recreatingHandle)
					{
						// After existing messages and functions are done.
						delayInvoke(function(Control cthis, size_t[] params){ cthis.cbits &= ~CBits.RECREATING; });
					}
				}
				catch(DThrowable e)
				{
					Application.onThreadException(e);
				}
				break;
			
			case WM_DESTROY:
				cbits &= ~CBits.CREATED;
				if(!recreatingHandle)
					cbits &= ~CBits.FORMLOADED;
				_destroying();
				//if(!killing)
				if(recreatingHandle)
					fillRecreationData();
				break;
			
			case WM_NCDESTROY:
				Application.removeHwnd(hwnd);
				hwnd = HWND.init;
				break;
			
			default:
				/+
				if(msg.msg == wmDfl)
				{
					switch(msg.wParam)
					{
						case WPARAM_DFL_:
						
						default:
					}
				}
				+/
		}
	}
	
	
	package final void _wndProc(ref Message msg)
	{
		//mustWndProc(msg); // Done in dflWndProc() now.
		wndProc(msg);
	}
	
	
	package final void _defWndProc(ref Message msg)
	{
		defWndProc(msg);
	}
	
	
	package final void doShow()
	{
		if(wparent) // Exclude owner.
		{
			SetWindowPos(hwnd, HWND.init, 0, 0, 0, 0, SWP_NOSIZE | SWP_NOMOVE | SWP_SHOWWINDOW | SWP_NOACTIVATE | SWP_NOZORDER);
		}
		else
		{
			SetWindowPos(hwnd, HWND_TOP, 0, 0, 0, 0, SWP_NOSIZE | SWP_NOMOVE | SWP_SHOWWINDOW);
		}
	}
	
	
	package final void doHide()
	{
		SetWindowPos(hwnd, HWND.init, 0, 0, 0, 0, SWP_NOSIZE | SWP_NOMOVE | SWP_NOACTIVATE | SWP_HIDEWINDOW | SWP_NOZORDER);
	}
	
	
	//EventHandler backColorChanged;
	Event!(Control, EventArgs) backColorChanged; ///
	// EventHandler backgroundImageChanged;
	/+
	deprecated EventHandler causesValidationChanged;
	deprecated InvalidateEventHandler invalidated;
	deprecated EventHandler validated;
	deprecated CancelEventHandler validating; // Once cancel is true, remaining events are suppressed (including validated).
	deprecated EventHandler enter; // Cascades up. TODO: fix implementation.
	deprecated EventHandler leave; // Cascades down. TODO: fix implementation.
	deprecated UICuesEventHandler changeUICues; // TODO: properly fire.
	+/
	//EventHandler click;
	Event!(Control, EventArgs) click; ///
	version(DFL_NO_MENUS)
	{
	}
	else
	{
		//EventHandler contextMenuChanged;
		Event!(Control, EventArgs) contextMenuChanged; ///
	}
	//ControlEventHandler controlAdded;
	Event!(Control, ControlEventArgs) controlAdded; ///
	//ControlEventHandler controlRemoved;
	Event!(Control, ControlEventArgs) controlRemoved; ///
	//EventHandler cursorChanged;
	Event!(Control, EventArgs) cursorChanged; ///
	//EventHandler disposed;
	Event!(Control, EventArgs) disposed; ///
	//EventHandler dockChanged;
	//Event!(Control, EventArgs) dockChanged; ///
	Event!(Control, EventArgs) hasLayoutChanged; ///
	alias hasLayoutChanged dockChanged;
	//EventHandler doubleClick;
	Event!(Control, EventArgs) doubleClick; ///
	//EventHandler enabledChanged;
	Event!(Control, EventArgs) enabledChanged; ///
	//EventHandler fontChanged;
	Event!(Control, EventArgs) fontChanged; ///
	//EventHandler foreColorChanged;
	Event!(Control, EventArgs) foreColorChanged; ///
	//EventHandler gotFocus; // After enter.
	Event!(Control, EventArgs) gotFocus; ///
	//EventHandler handleCreated;
	Event!(Control, EventArgs) handleCreated; ///
	//EventHandler handleDestroyed;
	Event!(Control, EventArgs) handleDestroyed; ///
	//HelpEventHandler helpRequested;
	Event!(Control, HelpEventArgs) helpRequested; ///
	//KeyEventHandler keyDown;
	Event!(Control, KeyEventArgs) keyDown; ///
	//KeyEventHandler keyPress;
	Event!(Control, KeyPressEventArgs) keyPress; ///
	//KeyEventHandler keyUp;
	Event!(Control, KeyEventArgs) keyUp; ///
	//LayoutEventHandler layout;
	Event!(Control, LayoutEventArgs) layout; ///
	//EventHandler lostFocus;
	Event!(Control, EventArgs) lostFocus; ///
	//MouseEventHandler mouseDown;
	Event!(Control, MouseEventArgs) mouseDown; ///
	//MouseEventHandler mouseEnter;
	Event!(Control, MouseEventArgs) mouseEnter; ///
	//MouseEventHandler mouseHover;
	Event!(Control, MouseEventArgs) mouseHover; ///
	//MouseEventHandler mouseLeave;
	Event!(Control, MouseEventArgs) mouseLeave; ///
	//MouseEventHandler mouseMove;
	Event!(Control, MouseEventArgs) mouseMove; ///
	//MouseEventHandler mouseUp;
	Event!(Control, MouseEventArgs) mouseUp; ///
	//MouseEventHandler mouseWheel;
	Event!(Control, MouseEventArgs) mouseWheel; ///
	//EventHandler move;
	Event!(Control, EventArgs) move; ///
	//EventHandler locationChanged;
	alias move locationChanged;
	//PaintEventHandler paint;
	Event!(Control, PaintEventArgs) paint; ///
	//EventHandler parentChanged;
	Event!(Control, EventArgs) parentChanged; ///
	//EventHandler resize;
	Event!(Control, EventArgs) resize; ///
	//EventHandler sizeChanged;
	alias resize sizeChanged;
	//EventHandler rightToLeftChanged;
	Event!(Control, EventArgs) rightToLeftChanged; ///
	// EventHandler styleChanged;
	//EventHandler systemColorsChanged;
	Event!(Control, EventArgs) systemColorsChanged; ///
	// EventHandler tabIndexChanged;
	// EventHandler tabStopChanged;
	//EventHandler textChanged;
	Event!(Control, EventArgs) textChanged; ///
	//EventHandler visibleChanged;
	Event!(Control, EventArgs) visibleChanged; ///
	
	version(DFL_NO_DRAG_DROP) {} else
	{
		//DragEventHandler dragDrop;
		Event!(Control, DragEventArgs) dragDrop; ///
		//DragEventHandler dragEnter;
		Event!(Control, DragEventArgs) dragEnter; ///
		//EventHandler dragLeave;
		Event!(Control, EventArgs) dragLeave; ///
		//DragEventHandler dragOver;
		Event!(Control, DragEventArgs) dragOver; ///
		//GiveFeedbackEventHandler giveFeedback;
		Event!(Control, GiveFeedbackEventArgs) giveFeedback; ///
		//QueryContinueDragEventHandler queryContinueDrag;
		Event!(Control, QueryContinueDragEventArgs) queryContinueDrag; ///
	}
	
	
	/// Construct a new Control instance.
	this()
	{
		//name = DObject.toString(); // ?
		
		wrect.size = defaultSize;
		//oldwrect = wrect;
		
		/+
		backc = defaultBackColor;
		forec = defaultForeColor;
		wfont = defaultFont;
		wcurs = new Cursor(LoadCursorA(HINSTANCE.init, IDC_ARROW), false);
		+/
		backc = Color.empty;
		forec = Color.empty;
		wfont = null;
		wcurs = null;
		
		ccollection = createControlsInstance();
	}
	
	/// ditto
	this(Dstring text)
	{
		this();
		wtext = text;
		
		ccollection = createControlsInstance();
	}
	
	/// ditto
	this(Control cparent, Dstring text)
	{
		this();
		wtext = text;
		parent = cparent;
		
		ccollection = createControlsInstance();
	}
	
	/// ditto
	this(Dstring text, int left, int top, int width, int height)
	{
		this();
		wtext = text;
		wrect = Rect(left, top, width, height);
		
		ccollection = createControlsInstance();
	}
	
	/// ditto
	this(Control cparent, Dstring text, int left, int top, int width, int height)
	{
		this();
		wtext = text;
		wrect = Rect(left, top, width, height);
		parent = cparent;
		
		ccollection = createControlsInstance();
	}
	
	
	/+
	// Used internally.
	this(HWND hwnd)
	in
	{
		assert(hwnd);
	}
	body
	{
		this.hwnd = hwnd;
		owned = false;
		
		ccollection = new ControlCollection(this);
	}
	+/
	
	
	~this()
	{
		debug(APP_PRINT)
			cprintf("~Control %p\n", cast(void*)this);
		
		version(DFL_NO_ZOMBIE_FORM)
		{
		}
		else
		{
			Application.zombieKill(this); // Does nothing if not zombie.
		}
		
		//dispose(false);
		destroyHandle();
		deleteThisBackgroundBrush();
	}
	
	
	/+ package +/ /+ protected +/ int _rtype() // package
	{
		return 0;
	}
	
	
	///
	void dispose()
	{
		dispose(true);
	}
	
	/// ditto
	protected void dispose(bool disposing)
	{
		if(disposing)
		{
			killing = true;
			
			version(DFL_NO_MENUS)
			{
			}
			else
			{
				cmenu = cmenu.init;
			}
			_ctrlname = _ctrlname.init;
			otag = otag.init;
			wcurs = wcurs.init;
			wfont = wfont.init;
			wparent = wparent.init;
			wregion = wregion.init;
			wtext = wtext.init;
			deleteThisBackgroundBrush();
			//ccollection.children = null; // Not GC-safe in dtor.
			//ccollection = null; // ? Causes bad things. Leaving it will do just fine.
		}
		
		if(!isHandleCreated)
			return;
		
		destroyHandle();
		/+
		//assert(hwnd == HWND.init); // Zombie trips this. (Not anymore with the hwnd-prop)
		if(hwnd)
		{
			assert(!IsWindow(hwnd));
			hwnd = HWND.init;
		}
		+/
		assert(hwnd == HWND.init);
		
		onDisposed(EventArgs.empty);
	}
	
	
	protected:
	
	///
	@property Size defaultSize() // getter
	{
		return Size(0, 0);
	}
	
	
	/+
	// TODO: implement.
	@property EventHandlerList events() // getter
	{
	}
	+/
	
	
	/+
	// TODO: implement. Is this worth implementing?
	
	// Set to -1 to reset cache.
	final @property void fontHeight(int fh) // setter
	{
		
	}
	
	
	final @property int fontHeight() // getter
	{
		return fonth;
	}
	+/
	
	
	///
	//final void resizeRedraw(bool byes) // setter
	public final @property void resizeRedraw(bool byes) // setter
	{
		/+
		// These class styles get lost sometimes so don't rely on them.
		LONG cl = _classStyle();
		if(byes)
			cl |= CS_HREDRAW | CS_VREDRAW;
		else
			cl &= ~(CS_HREDRAW | CS_VREDRAW);
		
		_classStyle(cl);
		+/
		szdraw = byes;
	}
	
	/// ditto
	final @property bool resizeRedraw() // getter
	{
		//return (_classStyle() & (CS_HREDRAW | CS_VREDRAW)) != 0;
		return szdraw;
	}
	
	
	/+
	// ///
	// I don't think this is reliable.
	final bool hasVisualStyle() // getter
	{
		bool result = false;
		HWND hw = handle; // Always reference handle.
		HMODULE huxtheme = GetModuleHandleA("uxtheme.dll");
		//HMODULE huxtheme = LoadLibraryA("uxtheme.dll");
		if(huxtheme)
		{
			auto getwintheme = cast(typeof(&GetWindowTheme))GetProcAddress(huxtheme, "GetWindowTheme");
			if(getwintheme)
			{
				result = getwintheme(hw) != null;
			}
			//FreeLibrary(huxtheme);
		}
		return result;
	}
	+/
	
	
	package final void _disableVisualStyle()
	{
		assert(isHandleCreated);
		
		HMODULE hmuxt;
		hmuxt = GetModuleHandleA("uxtheme.dll");
		if(hmuxt)
		{
			auto setWinTheme = cast(typeof(&SetWindowTheme))GetProcAddress(hmuxt, "SetWindowTheme");
			if(setWinTheme)
			{
				setWinTheme(hwnd, " "w.ptr, " "w.ptr); // Clear the theme.
			}
		}
	}
	
	
	///
	public final void disableVisualStyle(bool byes = true)
	{
		if(!byes)
		{
			if(cbits & CBits.VSTYLE)
				return;
			cbits |= CBits.VSTYLE;
			
			if(isHandleCreated)
			{
				_crecreate();
			}
		}
		else
		{
			if(!(cbits & CBits.VSTYLE))
				return;
			cbits &= ~CBits.VSTYLE;
			
			if(isHandleCreated)
				_disableVisualStyle();
		}
	}
	
	deprecated public final void enableVisualStyle(bool byes = true)
	{
		return disableVisualStyle(!byes);
	}
	
	
	///
	ControlCollection createControlsInstance()
	{
		return new ControlCollection(this);
	}
	
	
	deprecated package final void createClassHandle(Dstring className)
	{
		if(!wparent || !wparent.handle || killing)
		{
			create_err:
			throw new DflException("Control creation failure");
		}
		
		// This is here because referencing wparent.handle might create me.
		//if(created)
		if(isHandleCreated)
			return;
		
		Application.creatingControl(this);
		hwnd = dfl.internal.utf.createWindowEx(wexstyle, className, wtext, wstyle, wrect.x, wrect.y,
			wrect.width, wrect.height, wparent.handle, HMENU.init, Application.getInstance(), null);
		if(!hwnd)
			goto create_err;
	}
	
	
	///
	// Override to change the creation parameters.
	// Be sure to call super.createParams() or all the create params will need to be filled.
	protected void createParams(ref CreateParams cp)
	{
		with(cp)
		{
			className = CONTROL_CLASSNAME;
			caption = wtext;
			param = null;
			//parent = wparent.handle;
			parent = wparent ? wparent.handle : HWND.init;
			menu = HMENU.init;
			inst = Application.getInstance();
			x = wrect.x;
			y = wrect.y;
			width = wrect.width;
			height = wrect.height;
			classStyle = wclassStyle;
			exStyle = wexstyle;
			wstyle |= WS_VISIBLE;
			if(!(cbits & CBits.VISIBLE))
				wstyle &= ~WS_VISIBLE;
			style = wstyle;
		}
	}
	
	
	///
	protected void createHandle()
	{
		// Note: if modified, Form.createHandle() should be modified as well.
		
		if(isHandleCreated)
			return;
		
		//createClassHandle(CONTROL_CLASSNAME);
		
		/+
		if(!wparent || !wparent.handle || killing)
		{
			create_err:
			//throw new DflException("Control creation failure");
			throw new DflException(Object.toString() ~ " creation failure"); // ?
		}
		+/
		
		debug
		{
			Dstring er;
		}
		if(killing)
		{
			debug
			{
				er = "the control is being disposed";
			}
			
			debug(APP_PRINT)
			{
				cprintf("Creating Control handle while disposing.\n");
			}
			
			create_err:
			Dstring kmsg = "Control creation failure";
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
		
		// Need the parent's handle to exist.
		if(wparent)
			wparent.createHandle();
		
		// This is here because wparent.createHandle() might create me.
		//if(created)
		if(isHandleCreated)
			return;
		
		CreateParams cp;
		/+
		DWORD prevClassStyle;
		prevClassStyle = wclassStyle;
		+/
		
		createParams(cp);
		assert(!isHandleCreated); // Make sure the handle wasn't created in createParams().
		
		with(cp)
		{
			wtext = caption;
			//wrect = Rect(x, y, width, height); // This gets updated in WM_CREATE.
			wclassStyle = classStyle;
			wexstyle = exStyle;
			wstyle = style;
			
			//if(style & WS_CHILD) // Breaks context-help.
			if((ctrlStyle & ControlStyles.CONTAINER_CONTROL) && (style & WS_CHILD))
			{
				exStyle |= WS_EX_CONTROLPARENT;
			}
			
			bool vis = (style & WS_VISIBLE) != 0;
			
			Application.creatingControl(this);
			hwnd = dfl.internal.utf.createWindowEx(exStyle, className, caption, (style & ~WS_VISIBLE), x, y,
				width, height, parent, menu, inst, param);
			if(!hwnd)
			{
				debug(APP_PRINT)
				{
					cprintf("CreateWindowEx failed."
						" (exStyle=0x%X, className=`%.*s`, caption=`%.*s`, style=0x%X, x=%d, y=%d, width=%d, height=%d,"
						" parent=0x%X, menu=0x%X, inst=0x%X, param=0x%X)\n",
						exStyle, className, caption, style, x, y, width, height,
						parent, menu, inst, param);
				}
				
				debug
				{
					er = std.string.format("CreateWindowEx failed {className=%s;exStyle=0x%X;style=0x%X;parent=0x%X;menu=0x%X;inst=0x%X;}",
						className, exStyle, style, cast(void*)parent, cast(void*)menu, cast(void*)inst);
				}
				
				goto create_err;
			}
			
			if(vis)
				doShow(); // Properly fires onVisibleChanged.
		}
		
		//onHandleCreated(EventArgs.empty); // Called in WM_CREATE now.
	}
	
	
	package final void _createHandle()
	{
		createHandle();
	}
	
	
	///
	public final @property bool recreatingHandle() // getter
	{
		if(cbits & CBits.RECREATING)
			return true;
		return false;
	}
	
	
	private void _setAllRecreating()
	{
		cbits |= CBits.RECREATING;
		foreach(Control cc; controls)
		{
			cc._setAllRecreating();
		}
	}
	
	
	///
	protected void recreateHandle()
	in
	{
		assert(!recreatingHandle);
	}
	body
	{
		if(!isHandleCreated)
			return;
		
		if(recreatingHandle)
			return;
		
		bool hfocus = focused;
		HWND prevHwnd = GetWindow(hwnd, GW_HWNDPREV);
		
		_setAllRecreating();
		//scope(exit)
		//	cbits &= ~CBits.RECREATING; // Now done from WM_CREATE.
		
		destroyHandle();
		createHandle();
		
		if(prevHwnd)
			SetWindowPos(hwnd, prevHwnd, 0, 0, 0, 0, SWP_NOSIZE | SWP_NOMOVE | SWP_NOACTIVATE);
		else
			SetWindowPos(hwnd, HWND_TOPMOST, 0, 0, 0, 0, SWP_NOSIZE | SWP_NOMOVE | SWP_NOACTIVATE);
		if(hfocus)
			select();
	}
	
	
	///
	void destroyHandle()
	{
		if(!isHandleCreated)
			return;
		
		DestroyWindow(hwnd);
		
		// This stuff is done in WM_DESTROY because DestroyWindow() could be called elsewhere..
		//hwnd = HWND.init; // Done in WM_DESTROY.
		//onHandleDestroyed(EventArgs.empty); // Done in WM_DESTROY.
	}
	
	
	private final void fillRecreationData()
	{
		//cprintf(" { fillRecreationData %.*s }\n", name);
		
		if(!(ctrlStyle & ControlStyles.CACHE_TEXT))
			wtext = _fetchText();
		
		//wclassStyle = _fetchClassLong(); // ?
		
		// Fetch children.
		Control[] ccs;
		foreach(Control cc; controls)
		{
			ccs ~= cc;
		}
		ccollection.children = ccs;
	}
	
	
	///
	protected void onDisposed(EventArgs ea)
	{
		disposed(this, ea);
	}
	
	
	///
	protected final bool getStyle(ControlStyles flag)
	{
		return (ctrlStyle & flag) != 0;
	}
	
	/// ditto
	protected final void setStyle(ControlStyles flag, bool value)
	{
		if(flag & ControlStyles.CACHE_TEXT)
		{
			if(value)
				wtext = _fetchText();
			else
				wtext = null;
		}
		
		if(value)
			ctrlStyle |= flag;
		else
			ctrlStyle &= ~flag;
	}
	
	
	///
	// Only for setStyle() styles that are part of hwnd and wndclass styles.
	protected final void updateStyles()
	{
		LONG newClassStyles = _classStyle();
		LONG newWndStyles = _style();
		
		if(ctrlStyle & ControlStyles.STANDARD_DOUBLE_CLICK)
			newClassStyles |= CS_DBLCLKS;
		else
			newClassStyles &= ~CS_DBLCLKS;
		
		/+
		if(ctrlStyle & ControlStyles.RESIZE_REDRAW)
			newClassStyles |= CS_HREDRAW | CS_VREDRAW;
		else
			newClassStyles &= ~(CS_HREDRAW | CS_VREDRAW);
		+/
		
		/+
		if(ctrlStyle & ControlStyles.SELECTABLE)
			newWndStyles |= WS_TABSTOP;
		else
			newWndStyles &= ~WS_TABSTOP;
		+/
		
		_classStyle(newClassStyles);
		_style(newWndStyles);
	}
	
	
	///
	final bool getTopLevel()
	{
		// return GetParent(hwnd) == HWND.init;
		return wparent is null;
	}
	
	
	package final void alayout(Control ctrl, bool vcheck = true)
	{
		if(vcheck && !visible)
			return;
		
		if(cbits & CBits.IN_LAYOUT)
			return;
		
		//if(_allowLayout)
		if(!_disallowLayout)
		{
			//cprintf("alayout\n");
			scope LayoutEventArgs lea = new LayoutEventArgs(ctrl);
			onLayout(lea);
		}
	}
	
	
	// Z-order of controls has changed.
	package final void vchanged()
	{
		// Z-order can't change if it's not created or invisible.
		//if(!isHandleCreated || !visible)
		//	return;
		
		version(RADIO_GROUP_LAYOUT)
		{
			//cprintf("vchanged\n");
			
			bool foundRadio = false;
			
			foreach(Control ctrl; ccollection)
			{
				if(!ctrl.visible)
					continue;
				
				if(ctrl._rtype() & 1) // Radio type.
				{
					LONG wlg;
					wlg = ctrl._style();
					if(foundRadio)
					{
						if(wlg & WS_GROUP)
							//ctrl._style(wlg & ~WS_GROUP);
							ctrl._style(wlg & ~(WS_GROUP | WS_TABSTOP));
					}
					else
					{
						foundRadio = true;
						
						if(!(wlg & WS_GROUP))
							//ctrl._style(wlg | WS_GROUP);
							ctrl._style(wlg | WS_GROUP | WS_TABSTOP);
					}
				}
				else
				{
					// Found non-radio so reset group.
					// Update: only reset group if found ctrl with WS_EX_CONTROLPARENT.
					// TODO: check if correct implementation.
					if(ctrl._exStyle() & WS_EX_CONTROLPARENT)
						foundRadio = false;
				}
			}
		}
	}
	
	
	///
	// Called after adding the control to a container.
	protected void initLayout()
	{
		assert(wparent !is null);
		if(visible && created) // ?
		{
			wparent.vchanged();
			wparent.alayout(this);
		}
	}
	
	
	///
	protected void onLayout(LayoutEventArgs lea)
	{
		// Note: exception could cause failure to restore.
		//suspendLayout();
		cbits |= CBits.IN_LAYOUT;
		
		debug(EVENT_PRINT)
		{
			cprintf("{ Event: onLayout - Control %.*s }\n", name);
		}
		
		Rect area;
		area = displayRectangle;
		
		foreach(Control ctrl; ccollection)
		{
			if(!ctrl.visible || !ctrl.created)
				continue;
			if(ctrl._rtype() & (2 | 4)) // Mdichild | Tabpage
				continue;
			
			//Rect prevctrlbounds;
			//prevctrlbounds = ctrl.bounds;
			//ctrl.suspendLayout(); // Note: exception could cause failure to restore.
			switch(ctrl.sdock)
			{
				case DockStyle.NONE:
					/+
					if(ctrl.anch & (AnchorStyles.RIGHT | AnchorStyles.BOTTOM)) // If none of these are set, no point in doing any anchor code.
					{
						Rect newb;
						newb = ctrl.bounds;
						if(ctrl.anch & AnchorStyles.RIGHT)
						{
							if(ctrl.anch & AnchorStyles.LEFT)
								newb.width += bounds.width - originalBounds.width;
							else
								newb.x += bounds.width - originalBounds.width;
						}
						if(ctrl.anch & AnchorStyles.BOTTOM)
						{
							if(ctrl.anch & AnchorStyles.LEFT)
								newb.height += bounds.height - originalBounds.height;
							else
								newb.y += bounds.height - originalBounds.height;
						}
						if(newb != ctrl.bounds)
							ctrl.bounds = newb;
					}
					+/
					break;
				
				case DockStyle.LEFT:
					ctrl.setBoundsCore(area.x, area.y, 0, area.height, cast(BoundsSpecified)(BoundsSpecified.LOCATION | BoundsSpecified.HEIGHT));
					area.x = area.x + ctrl.width;
					area.width = area.width - ctrl.width;
					break;
				
				case DockStyle.TOP:
					ctrl.setBoundsCore(area.x, area.y, area.width, 0, cast(BoundsSpecified)(BoundsSpecified.LOCATION | BoundsSpecified.WIDTH));
					area.y = area.y + ctrl.height;
					area.height = area.height - ctrl.height;
					break;
				
				case DockStyle.FILL:
					//ctrl.bounds(Rect(area.x, area.y, area.width, area.height));
					ctrl.bounds = area;
					// area = ?
					break;
				
				case DockStyle.BOTTOM:
					ctrl.setBoundsCore(area.x, area.bottom - ctrl.height, area.width, 0, cast(BoundsSpecified)(BoundsSpecified.LOCATION | BoundsSpecified.WIDTH));
					area.height = area.height - ctrl.height;
					break;
				
				case DockStyle.RIGHT:
					ctrl.setBoundsCore(area.right - ctrl.width, area.y, 0, area.height, cast(BoundsSpecified)(BoundsSpecified.LOCATION | BoundsSpecified.HEIGHT));
					area.width = area.width - ctrl.width;
					break;
				
				default:
					assert(0);
			}
			//ctrl.resumeLayout(true);
			//ctrl.resumeLayout(prevctrlbounds != ctrl.bounds);
		}
		
		layout(this, lea);
		
		//resumeLayout(false);
		cbits &= ~CBits.IN_LAYOUT;
	}
	
	
	/+
	// Not sure what to do here.
	deprecated bool isInputChar(char charCode)
	{
		return false;
	}
	+/
	
	
	///
	void setVisibleCore(bool byes)
	{
		if(isHandleCreated)
		{
			//wstyle = GetWindowLongA(hwnd, GWL_STYLE);
			if(visible == byes)
				return;
			
			//ShowWindow(hwnd, byes ? SW_SHOW : SW_HIDE);
			if(byes)
				doShow();
			else
				doHide();
		}
		else
		{
			if(byes)
			{
				cbits |= CBits.VISIBLE;
				wstyle |= WS_VISIBLE;
				createControl();
			}
			else
			{
				cbits &= ~CBits.VISIBLE;
				wstyle &= ~WS_VISIBLE;
				return; // Not created and being hidden..
			}
		}
	}
	
	
	package final bool _wantTabKey()
	{
		if(ctrlStyle & ControlStyles.WANT_TAB_KEY)
			return true;
		return false;
	}
	
	
	///
	// Return true if processed.
	protected bool processKeyEventArgs(ref Message msg)
	{
		switch(msg.msg)
		{
			case WM_KEYDOWN:
				{
					scope KeyEventArgs kea = new KeyEventArgs(cast(Keys)(msg.wParam | modifierKeys));
					
					ushort repeat = msg.lParam & 0xFFFF; // First 16 bits.
					for(; repeat; repeat--)
					{
						//kea.handled = false;
						onKeyDown(kea);
					}
					
					if(kea.handled)
						return true;
				}
				break;
			
			case WM_KEYUP:
				{
					// Repeat count is always 1 for key up.
					scope KeyEventArgs kea = new KeyEventArgs(cast(Keys)(msg.wParam | modifierKeys));
					onKeyUp(kea);
					if(kea.handled)
						return true;
				}
				break;
			
			case WM_CHAR:
				{
					scope KeyPressEventArgs kpea = new KeyPressEventArgs(cast(dchar)msg.wParam, modifierKeys);
					onKeyPress(kpea);
					if(kpea.handled)
						return true;
				}
				break;
			
			default:
		}
		
		defWndProc(msg);
		return !msg.result;
	}
	
	
	package final bool _processKeyEventArgs(ref Message msg)
	{
		return processKeyEventArgs(msg);
	}
	
	
	/+
	bool processKeyPreview(ref Message m)
	{
		if(wparent)
			return wparent.processKeyPreview(m);
		return false;
	}
	
	
	protected bool processDialogChar(dchar charCode)
	{
		if(wparent)
			return wparent.processDialogChar(charCode);
		return false;
	}
	+/
	
	
	///
	protected bool processMnemonic(dchar charCode)
	{
		return false;
	}
	
	
	package bool _processMnemonic(dchar charCode)
	{
		return processMnemonic(charCode);
	}
	
	
	// Retain DFL 0.9.5 compatibility.
	public deprecated void setDFL095()
	{
		version(SET_DFL_095)
		{
			pragma(msg, "DFL: DFL 0.9.5 compatibility set at compile time");
		}
		else
		{
			//_compat = CCompat.DFL095;
			Application.setCompat(DflCompat.CONTROL_RECREATE_095);
		}
	}
	
	private enum CCompat: ubyte
	{
		NONE = 0,
		DFL095 = 1,
	}
	
	version(SET_DFL_095)
		package enum _compat = CCompat.DFL095;
	else version(DFL_NO_COMPAT)
		package enum _compat = CCompat.NONE;
	else
		package @property CCompat _compat() // getter
			{ if(Application._compat & DflCompat.CONTROL_RECREATE_095) return CCompat.DFL095; return CCompat.NONE; }
	
	
	package final void _crecreate()
	{
		if(CCompat.DFL095 != _compat)
		{
			if(!recreatingHandle)
				recreateHandle();
		}
	}
	
	
	package:
	HWND hwnd;
	//AnchorStyles anch = cast(AnchorStyles)(AnchorStyles.TOP | AnchorStyles.LEFT);
	//bool cvalidation = true;
	version(DFL_NO_MENUS)
	{
	}
	else
	{
		ContextMenu cmenu;
	}
	DockStyle sdock = DockStyle.NONE;
	Dstring _ctrlname;
	Object otag;
	Color backc, forec;
	Rect wrect;
	//Rect oldwrect;
	Size wclientsz;
	Cursor wcurs;
	Font wfont;
	Control wparent;
	Region wregion;
	ControlCollection ccollection;
	Dstring wtext; // After creation, this isn't used unless ControlStyles.CACHE_TEXT.
	ControlStyles ctrlStyle = ControlStyles.STANDARD_CLICK | ControlStyles.STANDARD_DOUBLE_CLICK /+ | ControlStyles.RESIZE_REDRAW +/ ;
	HBRUSH _hbrBg;
	RightToLeft rtol = RightToLeft.INHERIT;
	uint _disallowLayout = 0;
	
	version(DFL_NO_DRAG_DROP) {} else
	{
		DropTarget droptarget = null;
	}
	
	// Note: WS_VISIBLE is not reliable.
	LONG wstyle = WS_CHILD | WS_VISIBLE | WS_CLIPCHILDREN | WS_CLIPSIBLINGS; // Child, visible and enabled by default.
	LONG wexstyle;
	LONG wclassStyle = WNDCLASS_STYLE;
	
	
	enum CBits: uint
	{
		NONE = 0x0,
		MENTER = 0x1, // Is mouse entered? Only valid if -trackMouseEvent- is non-null.
		KILLING = 0x2,
		OWNED = 0x4,
		//ALLOW_LAYOUT = 0x8,
		CLICKING = 0x10,
		NEED_CALC_SIZE = 0x20,
		SZDRAW = 0x40,
		OWNEDBG = 0x80,
		HANDLE_CREATED = 0x100, // debug only
		SW_SHOWN = 0x200,
		SW_HIDDEN = 0x400,
		CREATED = 0x800,
		NEED_INIT_LAYOUT = 0x1000,
		IN_LAYOUT = 0x2000,
		FVISIBLE = 0x4000,
		VISIBLE = 0x8000,
		NOCLOSING = 0x10000,
		ASCROLL = 0x20000,
		ASCALE = 0x40000,
		FORM = 0x80000,
		RECREATING = 0x100000,
		HAS_LAYOUT = 0x200000,
		VSTYLE = 0x400000, // If not forced off.
		FORMLOADED = 0x800000, // If not forced off.
		ENABLED = 0x1000000, // Enabled state, not considering the parent.
	}
	
	//CBits cbits = CBits.ALLOW_LAYOUT;
	//CBits cbits = CBits.NONE;
	CBits cbits = CBits.VISIBLE | CBits.VSTYLE | CBits.ENABLED;
	
	
	final:
	
	@property void menter(bool byes) // setter
		{ if(byes) cbits |= CBits.MENTER; else cbits &= ~CBits.MENTER; }
	@property bool menter() // getter
		{ return (cbits & CBits.MENTER) != 0; }
	
	@property void killing(bool byes) // setter
		//{ if(byes) cbits |= CBits.KILLING; else cbits &= ~CBits.KILLING; }
		{ assert(byes); if(byes) cbits |= CBits.KILLING; }
	@property bool killing() // getter
		{ return (cbits & CBits.KILLING) != 0; }
	
	@property void owned(bool byes) // setter
		{ if(byes) cbits |= CBits.OWNED; else cbits &= ~CBits.OWNED; }
	@property bool owned() // getter
		{ return (cbits & CBits.OWNED) != 0; }
	
	/+
	void _allowLayout(bool byes) // setter
		{ if(byes) cbits |= CBits.ALLOW_LAYOUT; else cbits &= ~CBits.ALLOW_LAYOUT; }
	bool _allowLayout() // getter
		{ return (cbits & CBits.ALLOW_LAYOUT) != 0; }
	+/
	
	@property void _clicking(bool byes) // setter
		{ if(byes) cbits |= CBits.CLICKING; else cbits &= ~CBits.CLICKING; }
	@property bool _clicking() // getter
		{ return (cbits & CBits.CLICKING) != 0; }
	
	@property void needCalcSize(bool byes) // setter
		{ if(byes) cbits |= CBits.NEED_CALC_SIZE; else cbits &= ~CBits.NEED_CALC_SIZE; }
	@property bool needCalcSize() // getter
		{ return (cbits & CBits.NEED_CALC_SIZE) != 0; }
	
	@property void szdraw(bool byes) // setter
		{ if(byes) cbits |= CBits.SZDRAW; else cbits &= ~CBits.SZDRAW; }
	@property bool szdraw() // getter
		{ return (cbits & CBits.SZDRAW) != 0; }
	
	@property void ownedbg(bool byes) // setter
		{ if(byes) cbits |= CBits.OWNEDBG; else cbits &= ~CBits.OWNEDBG; }
	@property bool ownedbg() // getter
		{ return (cbits & CBits.OWNEDBG) != 0; }
	
	debug
	{
		@property void _handlecreated(bool byes) // setter
			{ if(byes) cbits |= CBits.HANDLE_CREATED; else cbits &= ~CBits.HANDLE_CREATED; }
		@property bool _handlecreated() // getter
			{ return (cbits & CBits.HANDLE_CREATED) != 0; }
	}
	
	
	@property LONG _exStyle()
	{
		// return GetWindowLongA(hwnd, GWL_EXSTYLE);
		return wexstyle;
	}
	
	
	@property void _exStyle(LONG wl)
	{
		if(isHandleCreated)
		{
			SetWindowLongA(hwnd, GWL_EXSTYLE, wl);
		}
		
		wexstyle = wl;
	}
	
	
	@property LONG _style()
	{
		// return GetWindowLongA(hwnd, GWL_STYLE);
		return wstyle;
	}
	
	
	@property void _style(LONG wl)
	{
		if(isHandleCreated)
		{
			SetWindowLongA(hwnd, GWL_STYLE, wl);
		}
		
		wstyle = wl;
	}
	
	
	@property HBRUSH hbrBg() // getter
	{
		if(_hbrBg)
			return _hbrBg;
		if(backc == Color.empty && parent && backColor == parent.backColor)
		{
			ownedbg = false;
			_hbrBg = parent.hbrBg;
			return _hbrBg;
		}
		hbrBg = backColor.createBrush(); // Call hbrBg's setter and set ownedbg.
		return _hbrBg;
	}
	
	
	@property void hbrBg(HBRUSH hbr) // setter
	in
	{
		if(hbr)
		{
			assert(!_hbrBg);
		}
	}
	body
	{
		_hbrBg = hbr;
		ownedbg = true;
	}
	
	
	void deleteThisBackgroundBrush()
	{
		if(_hbrBg)
		{
			if(ownedbg)
				DeleteObject(_hbrBg);
			_hbrBg = HBRUSH.init;
		}
	}
	
	
	LRESULT defwproc(UINT msg, WPARAM wparam, LPARAM lparam)
	{
		//return DefWindowProcA(hwnd, msg, wparam, lparam);
		return dfl.internal.utf.defWindowProc(hwnd, msg, wparam, lparam);
	}
	
	
	LONG _fetchClassLong()
	{
		return GetClassLongA(hwnd, GCL_STYLE);
	}
	
	
	LONG _classStyle()
	{
		// return GetClassLongA(hwnd, GCL_STYLE);
		// return wclassStyle;
		
		if(isHandleCreated)
		{
			// Always fetch because it's not guaranteed to be accurate.
			wclassStyle = _fetchClassLong();
		}
		
		return wclassStyle;
	}
	
	
	package void _classStyle(LONG cl)
	{
		if(isHandleCreated)
		{
			SetClassLongA(hwnd, GCL_STYLE, cl);
		}
		
		wclassStyle = cl;
	}
}


package abstract class ControlSuperClass: Control // dapi.d
{
	// Call previous wndProc().
	abstract protected void prevWndProc(ref Message msg);
	
	
	protected override void wndProc(ref Message msg)
	{
		switch(msg.msg)
		{
			case WM_PAINT:
				{
					RECT uprect;
					//GetUpdateRect(hwnd, &uprect, true);
					//onInvalidated(new InvalidateEventArgs(Rect(&uprect)));
					
					//if(!msg.wParam)
						GetUpdateRect(hwnd, &uprect, false); // Preserve.
					
					prevWndProc(msg);
					
					// Now fake a normal paint event...
					
					scope Graphics gpx = new CommonGraphics(hwnd, GetDC(hwnd));
					//scope Graphics gpx = new CommonGraphics(hwnd, msg.wParam ? cast(HDC)msg.wParam : GetDC(hwnd), msg.wParam ? false : true);
					HRGN hrgn;
					
					hrgn = CreateRectRgnIndirect(&uprect);
					SelectClipRgn(gpx.handle, hrgn);
					DeleteObject(hrgn);
					
					scope PaintEventArgs pea = new PaintEventArgs(gpx, Rect(&uprect));
					
					// Can't erase the background now, Windows just painted..
					//if(ps.fErase)
					//{
					//	prepareDc(gpx.handle);
					//	onPaintBackground(pea);
					//}
					
					prepareDc(gpx.handle);
					onPaint(pea);
				}
				break;
			
			case WM_PRINTCLIENT:
				{
					prevWndProc(msg);
					
					scope Graphics gpx = new CommonGraphics(hwnd, GetDC(hwnd));
					scope PaintEventArgs pea = new PaintEventArgs(gpx,
						Rect(Point(0, 0), wclientsz));
					
					prepareDc(pea.graphics.handle);
					onPaint(pea);
				}
				break;
			
			case WM_PRINT:
				Control.defWndProc(msg);
				break;
			
			case WM_ERASEBKGND:
				Control.wndProc(msg);
				break;
			
			case WM_NCACTIVATE:
			case WM_NCCALCSIZE:
			case WM_NCCREATE:
			case WM_NCPAINT:
				prevWndProc(msg);
				break;
			
			case WM_KEYDOWN:
			case WM_KEYUP:
			case WM_CHAR:
			case WM_SYSKEYDOWN:
			case WM_SYSKEYUP:
			case WM_SYSCHAR:
			//case WM_IMECHAR:
				super.wndProc(msg);
				return;
			
			default:
				prevWndProc(msg);
				super.wndProc(msg);
		}
	}
	
	
	override void defWndProc(ref Message m)
	{
		switch(m.msg)
		{
			case WM_KEYDOWN:
			case WM_KEYUP:
			case WM_CHAR:
			case WM_SYSKEYDOWN:
			case WM_SYSKEYUP:
			case WM_SYSCHAR:
			//case WM_IMECHAR: // ?
				prevWndProc(m);
				break;
			
			default:
		}
	}
	
	
	protected override void onPaintBackground(PaintEventArgs pea)
	{
		Message msg;
		
		msg.hWnd = handle;
		msg.msg = WM_ERASEBKGND;
		msg.wParam = cast(WPARAM)pea.graphics.handle;
		
		prevWndProc(msg);
		
		// Don't paint the background twice.
		//super.onPaintBackground(pea);
		
		// Event ?
		//paintBackground(this, pea);
	}
}


///
class ScrollableControl: Control // docmain
{
	// ///
	deprecated void autoScroll(bool byes) // setter
	{
		if(byes)
			cbits |= CBits.ASCROLL;
		else
			cbits &= ~CBits.ASCROLL;
	}
	
	// /// ditto
	deprecated bool autoScroll() // getter
	{
		return (cbits & CBits.ASCROLL) == CBits.ASCROLL;
	}
	
	
	// ///
	deprecated final void autoScrollMargin(Size sz) // setter
	{
		//scrollmargin = sz;
	}
	
	// /// ditto
	deprecated final Size autoScrollMargin() // getter
	{
		//return scrollmargin;
		return Size(0, 0);
	}
	
	
	// ///
	deprecated final void autoScrollMinSize(Size sz) // setter
	{
		//scrollmin = sz;
	}
	
	// /// ditto
	deprecated final Size autoScrollMinSize() // getter
	{
		//return scrollmin;
		return Size(0, 0);
	}
	
	
	// ///
	deprecated final void autoScrollPosition(Point pt) // setter
	{
		//autoscrollpos = pt;
	}
	
	// /// ditto
	deprecated final Point autoScrollPosition() // getter
	{
		//return autoscrollpos;
		return Point(0, 0);
	}
	
	
	///
	final @property Size autoScaleBaseSize() // getter
	{
		return autossz;
	}
	
	/// ditto
	final @property void autoScaleBaseSize(Size newSize) // setter
	in
	{
		assert(newSize.width > 0);
		assert(newSize.height > 0);
	}
	body
	{
		autossz = newSize;
	}
	
	
	///
	final @property void autoScale(bool byes) // setter
	{
		if(byes)
			cbits |= CBits.ASCALE;
		else
			cbits &= ~CBits.ASCALE;
	}
	
	/// ditto
	final @property bool autoScale() // getter
	{
		return (cbits & CBits.ASCALE) == CBits.ASCALE;
	}
	
	
	final @property Point scrollPosition() // getter
	{
		return Point(xspos, yspos);
	}
	
	
	static Size calcScale(Size area, Size toScale, Size fromScale) // package
	in
	{
		assert(fromScale.width);
		assert(fromScale.height);
	}
	body
	{
		area.width = cast(int)(cast(float)area.width / cast(float)fromScale.width * cast(float)toScale.width);
		area.height = cast(int)(cast(float)area.height / cast(float)fromScale.height * cast(float)toScale.height);
		return area;
	}
	
	
	Size calcScale(Size area, Size toScale) // package
	{
		return calcScale(area, toScale, DEFAULT_SCALE);
	}
	
	
	final void _scale(Size toScale) // package
	{
		bool first = true;
		
		// Note: doesn't get to-scale for nested scrollable-controls.
		void xscale(Control c, Size fromScale)
		{
			c.suspendLayout();
			
			if(first)
			{
				first = false;
				c.size = calcScale(c.size, toScale, fromScale);
			}
			else
			{
				Point pt;
				Size sz;
				sz = calcScale(Size(c.left, c.top), toScale, fromScale);
				pt = Point(sz.width, sz.height);
				sz = calcScale(c.size, toScale, fromScale);
				c.bounds = Rect(pt, sz);
			}
			
			if(c.hasChildren)
			{
				ScrollableControl scc;
				foreach(Control cc; c.controls)
				{
					scc = cast(ScrollableControl)cc;
					if(scc)
					{
						if(scc.autoScale) // ?
						{
							xscale(scc, scc.autoScaleBaseSize);
							scc.autoScaleBaseSize = toScale;
						}
					}
					else
					{
						xscale(cc, fromScale);
					}
				}
			}
			
			//c.resumeLayout(true);
			c.resumeLayout(false); // Should still be perfectly proportionate if it was properly laid out before scaling.
		}
		
		
		xscale(this, autoScaleBaseSize);
		autoScaleBaseSize = toScale;
	}
	
	
	final void _scale() // package
	{
		return _scale(getAutoScaleSize());
	}
	
	
	protected override void onControlAdded(ControlEventArgs ea)
	{
		super.onControlAdded(ea);
		
		if(created) // ?
		if(isHandleCreated)
		{
			auto sc = cast(ScrollableControl)ea.control;
			if(sc)
			{
				if(sc.autoScale)
					sc._scale();
			}
			else
			{
				if(autoScale)
					_scale();
			}
		}
	}
	
	
	//override final Rect displayRectangle() // getter
	override @property Rect displayRectangle() // getter
	{
		Rect result = clientRectangle;
		
		// Subtract dock padding.
		result.x = result.x + dpad.left;
		result.width = result.width - dpad.right - dpad.left;
		result.y = result.y + dpad.top;
		result.height = result.height - dpad.bottom - dpad.top;
		
		// Add scroll width.
		if(scrollSize.width > clientSize.width)
			result.width = result.width + (scrollSize.width - clientSize.width);
		if(scrollSize.height > clientSize.height)
			result.height = result.height + (scrollSize.height - clientSize.height);
		
		// Adjust scroll position.
		result.location = Point(result.location.x - scrollPosition.x, result.location.y - scrollPosition.y);
		
		return result;
	}
	
	
	///
	final @property void scrollSize(Size sz) // setter
	{
		scrollsz = sz;
		
		_fixScrollBounds(); // Implies _adjustScrollSize().
	}
	
	/// ditto
	final @property Size scrollSize() // getter
	{
		return scrollsz;
	}
	
	
	///
	class DockPaddingEdges
	{
		private:
		
		int _left, _top, _right, _bottom;
		int _all;
		//package void delegate() changed;
		
		
		final:
		
		void changed()
		{
			dpadChanged();
		}
		
		
		public:
		
		///
		@property void all(int x) // setter
		{
			_bottom = _right = _top = _left = _all = x;
			
			changed();
		}
		
		/// ditto
		final @property int all() // getter
		{
			return _all;
		}
		
		/// ditto
		@property void left(int x) // setter
		{
			_left = x;
			
			changed();
		}
		
		/// ditto
		@property int left() // getter
		{
			return _left;
		}
		
		/// ditto
		@property void top(int x) // setter
		{
			_top = x;
			
			changed();
		}
		
		/// ditto
		@property int top() // getter
		{
			return _top;
		}
		
		/// ditto
		@property void right(int x) // setter
		{
			_right = x;
			
			changed();
		}
		
		/// ditto
		@property int right() // getter
		{
			return _right;
		}
		
		/// ditto
		@property void bottom(int x) // setter
		{
			_bottom = x;
			
			changed();
		}
		
		/// ditto
		@property int bottom() // getter
		{
			return _bottom;
		}
	}
	
	
	///
	final @property DockPaddingEdges dockPadding() // getter
	{
		return dpad;
	}
	
	
	deprecated final void setAutoScrollMargin(int x, int y)
	{
		//
	}
	
	
	this()
	{
		super();
		_init();
	}
	
	
	enum DEFAULT_SCALE = Size(5, 13);
	
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
	
	/// ditto
	final @property bool vScroll() // getter
	{
		return (_style() & WS_VSCROLL) != 0;
	}
	
	
	protected:
	
	
	/+
	override void onLayout(LayoutEventArgs lea)
	{
		// ...
		super.onLayout(lea);
	}
	+/
	
	
	/+
	override void scaleCore(float width, float height)
	{
		// Might not want to call super.scaleCore().
	}
	+/
	
	
	override void wndProc(ref Message m)
	{
		switch(m.msg)
		{
			case WM_VSCROLL:
				{
					SCROLLINFO si = void;
					si.cbSize = SCROLLINFO.sizeof;
					si.fMask = SIF_ALL;
					if(GetScrollInfo(m.hWnd, SB_VERT, &si))
					{
						int delta, maxp;
						maxp = scrollSize.height - clientSize.height;
						switch(LOWORD(m.wParam))
						{
							case SB_LINEDOWN:
								if(yspos >= maxp)
									return;
								delta = maxp - yspos;
								if(autossz.height < delta)
									delta = autossz.height;
								break;
							case SB_LINEUP:
								if(yspos <= 0)
									return;
								delta = yspos;
								if(autossz.height < delta)
									delta = autossz.height;
								delta = -delta;
								break;
							case SB_PAGEDOWN:
								if(yspos >= maxp)
									return;
								if(yspos >= maxp)
									return;
								delta = maxp - yspos;
								if(clientSize.height < delta)
									delta = clientSize.height;
								break;
							case SB_PAGEUP:
								if(yspos <= 0)
									return;
								delta = yspos;
								if(clientSize.height < delta)
									delta = clientSize.height;
								delta = -delta;
								break;
							case SB_THUMBTRACK:
							case SB_THUMBPOSITION:
								//delta = cast(int)HIWORD(m.wParam) - yspos; // Limited to 16-bits.
								delta = si.nTrackPos - yspos;
								break;
							case SB_BOTTOM:
								delta = maxp - yspos;
								break;
							case SB_TOP:
								delta = -yspos;
								break;
							default:
						}
						yspos += delta;
						SetScrollPos(m.hWnd, SB_VERT, yspos, TRUE);
						ScrollWindow(m.hWnd, 0, -delta, null, null);
					}
				}
				break;
			
			case WM_HSCROLL:
				{
					SCROLLINFO si = void;
					si.cbSize = SCROLLINFO.sizeof;
					si.fMask = SIF_ALL;
					if(GetScrollInfo(m.hWnd, SB_HORZ, &si))
					{
						int delta, maxp;
						maxp = scrollSize.width - clientSize.width;
						switch(LOWORD(m.wParam))
						{
							case SB_LINERIGHT:
								if(xspos >= maxp)
									return;
								delta = maxp - xspos;
								if(autossz.width < delta)
									delta = autossz.width;
								break;
							case SB_LINELEFT:
								if(xspos <= 0)
									return;
								delta = xspos;
								if(autossz.width < delta)
									delta = autossz.width;
								delta = -delta;
								break;
							case SB_PAGERIGHT:
								if(xspos >= maxp)
									return;
								if(xspos >= maxp)
									return;
								delta = maxp - xspos;
								if(clientSize.width < delta)
									delta = clientSize.width;
								break;
							case SB_PAGELEFT:
								if(xspos <= 0)
									return;
								delta = xspos;
								if(clientSize.width < delta)
									delta = clientSize.width;
								delta = -delta;
								break;
							case SB_THUMBTRACK:
							case SB_THUMBPOSITION:
								//delta = cast(int)HIWORD(m.wParam) - xspos; // Limited to 16-bits.
								delta = si.nTrackPos - xspos;
								break;
							case SB_RIGHT:
								delta = maxp - xspos;
								break;
							case SB_LEFT:
								delta = -xspos;
								break;
							default:
						}
						xspos += delta;
						SetScrollPos(m.hWnd, SB_HORZ, xspos, TRUE);
						ScrollWindow(m.hWnd, -delta, 0, null, null);
					}
				}
				break;
			
			default:
		}
		
		super.wndProc(m);
	}
	
	
	override void onMouseWheel(MouseEventArgs ea)
	{
		int maxp = scrollSize.height - clientSize.height;
		int delta;
		
		UINT wlines;
		if(!SystemParametersInfoA(SPI_GETWHEELSCROLLLINES, 0, &wlines, 0))
			wlines = 3;
		
		if(ea.delta < 0)
		{
			if(yspos < maxp)
			{
				delta = maxp - yspos;
				if(autossz.height * wlines < delta)
					delta = autossz.height * wlines;
				
				yspos += delta;
				SetScrollPos(hwnd, SB_VERT, yspos, TRUE);
				ScrollWindow(hwnd, 0, -delta, null, null);
			}
		}
		else
		{
			if(yspos > 0)
			{
				delta = yspos;
				if(autossz.height * wlines < delta)
					delta = autossz.height * wlines;
				delta = -delta;
				
				yspos += delta;
				SetScrollPos(hwnd, SB_VERT, yspos, TRUE);
				ScrollWindow(hwnd, 0, -delta, null, null);
			}
		}
		
		super.onMouseWheel(ea);
	}
	
	
	override void onHandleCreated(EventArgs ea)
	{
		xspos = 0;
		yspos = 0;
		
		super.onHandleCreated(ea);
		
		//_adjustScrollSize(FALSE);
		if(hScroll || vScroll)
		{
			_adjustScrollSize(FALSE);
			recalcEntire(); // Need to recalc frame.
		}
	}
	
	
	override void onVisibleChanged(EventArgs ea)
	{
		if(visible)
			_adjustScrollSize(FALSE);
		
		super.onVisibleChanged(ea);
	}
	
	
	private void _fixScrollBounds()
	{
		if(hScroll || vScroll)
		{
			int ydiff = 0, xdiff = 0;
			
			if(yspos > scrollSize.height - clientSize.height)
			{
				ydiff = (clientSize.height + yspos) - scrollSize.height;
				yspos -= ydiff;
				if(yspos < 0)
				{
					ydiff += yspos;
					yspos = 0;
				}
			}
			
			if(xspos > scrollSize.width - clientSize.width)
			{
				xdiff = (clientSize.width + xspos) - scrollSize.width;
				xspos -= xdiff;
				if(xspos < 0)
				{
					xdiff += xspos;
					xspos = 0;
				}
			}
			
			if(isHandleCreated)
			{
				if(xdiff || ydiff)
					ScrollWindow(hwnd, xdiff, ydiff, null, null);
				
				_adjustScrollSize();
			}
		}
	}
	
	
	override void onResize(EventArgs ea)
	{
		super.onResize(ea);
		
		_fixScrollBounds();
	}
	
	
	private:
	//Size scrollmargin, scrollmin;
	//Point autoscrollpos;
	DockPaddingEdges dpad;
	Size autossz = DEFAULT_SCALE;
	Size scrollsz = Size(0, 0);
	int xspos = 0, yspos = 0;
	
	
	void _init()
	{
		dpad = new DockPaddingEdges;
		//dpad.changed = &dpadChanged;
	}
	
	
	void dpadChanged()
	{
		alayout(this);
	}
	
	
	void _adjustScrollSize(BOOL fRedraw = TRUE)
	{
		assert(isHandleCreated);
		
		if(!hScroll && !vScroll)
			return;
		
		SCROLLINFO si;
		//if(vScroll)
		{
			si.cbSize = SCROLLINFO.sizeof;
			si.fMask = SIF_RANGE | SIF_PAGE | SIF_POS;
			si.nPos = yspos;
			si.nMin = 0;
			si.nMax = clientSize.height;
			si.nPage = clientSize.height;
			if(scrollSize.height > clientSize.height)
				si.nMax = scrollSize.height;
			if(si.nMax)
				si.nMax--;
			SetScrollInfo(hwnd, SB_VERT, &si, fRedraw);
		}
		//if(hScroll)
		{
			si.cbSize = SCROLLINFO.sizeof;
			si.fMask = SIF_RANGE | SIF_PAGE | SIF_POS;
			si.nPos = xspos;
			si.nMin = 0;
			si.nMax = clientSize.width;
			si.nPage = clientSize.width;
			if(scrollSize.width > clientSize.width)
				si.nMax = scrollSize.width;
			if(si.nMax)
				si.nMax--;
			SetScrollInfo(hwnd, SB_HORZ, &si, fRedraw);
		}
	}
}


///
interface IContainerControl // docmain
{
	///
	@property Control activeControl(); // getter
	
	deprecated void activeControl(Control); // setter
	
	deprecated bool activateControl(Control);
}


///
class ContainerControl: ScrollableControl, IContainerControl // docmain
{
	///
	@property Control activeControl() // getter
	{
		/+
		HWND hwfocus, hw;
		hw = hwfocus = GetFocus();
		while(hw)
		{
			if(hw == this.hwnd)
				return Control.fromChildHandle(hwfocus);
			hw = GetParent(hw);
		}
		return null;
		+/
		Control ctrlfocus, ctrl;
		ctrl = ctrlfocus = Control.fromChildHandle(GetFocus());
		while(ctrl)
		{
			if(ctrl is this)
				return ctrlfocus;
			ctrl = ctrl.parent;
		}
		return null;
	}
	
	/// ditto
	@property void activeControl(Control ctrl) // setter
	{
		if(!activateControl(ctrl))
			throw new DflException("Unable to activate control");
	}
	
	
	///
	// Returns true if successfully activated.
	final bool activateControl(Control ctrl)
	{
		// Not sure if this is correct.
		
		if(!ctrl.canSelect)
			return false;
		//if(!SetActiveWindow(ctrl.handle))
		//	return false;
		ctrl.select();
		return true;
	}
	
	
	///
	final @property Form parentForm() // getter
	{
		Control par;
		Form f;
		
		for(par = parent; par; par = par.parent)
		{
			f = cast(Form)par;
			if(f)
				return f;
		}
		
		return null;
	}
	
	
	/+
	final bool validate()
	{
		// ...
	}
	+/
	
	
	this()
	{
		super();
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
	
	
	private void _init()
	{
		//wexstyle |= WS_EX_CONTROLPARENT;
		ctrlStyle |= ControlStyles.CONTAINER_CONTROL;
	}
	
	
	protected:
	/+
	override bool processDialogChar(char charCode)
	{
		// Not sure if this is correct.
		return false;
	}
	+/
	
	
	/+
	deprecated protected override bool processMnemonic(dchar charCode)
	{
		return false;
	}
	
	
	bool processTabKey(bool forward)
	{
		if(isHandleCreated)
		{
			//SendMessageA(hwnd, WM_NEXTDLGCTL, !forward, 0);
			//return true;
			select(true, forward);
		}
		return false;
	}
	+/
}


import std.traits, std.typecons;
private template hasLocalAliasing(T...)
{
	static if( !T.length )
		enum hasLocalAliasing = false;
	else
		enum hasLocalAliasing = std.traits.hasLocalAliasing!(T[0]) ||
			dfl.control.hasLocalAliasing!(T[1 .. $]);
}

///
shared class SharedControl
{
private:
	Control _ctrl;
	
	LPARAM makeParam(ARGS...)(void function(Control, ARGS) fn, Tuple!(ARGS)* args)
		if (ARGS.length)
	{
		static assert((DflInvokeParam*).sizeof <= LPARAM.sizeof);
		static struct InvokeParam
		{
			void function(Control, ARGS) fn;
			ARGS args;
		}
		alias dfl.internal.clib.malloc malloc;
		alias dfl.internal.clib.free free;
	
		auto param = cast(InvokeParam*)malloc(InvokeParam.sizeof);
		param.fn = fn;
		param.args = args.field;
		
		if (!param)
			throw new OomException();
		
		auto p = cast(DflInvokeParam*)malloc(DflInvokeParam.sizeof);
		
		if (!p)
			throw new OomException();
		
		
		static void fnentry(Control c, size_t[] p)
		{
			auto param = cast(InvokeParam*)p[0];
			param.fn(c, param.args);
			free(param);
		}
		
		p.fp = &fnentry;
		p.nparams = 1;
		p.params[0] = cast(size_t)param;
		
		return cast(LPARAM)p;
	}
	
	
	LPARAM makeParamNoneArgs(void function(Control) fn)
	{
		static assert((DflInvokeParam*).sizeof <= LPARAM.sizeof);
		alias dfl.internal.clib.malloc malloc;
		alias dfl.internal.clib.free free;
		
		auto p = cast(DflInvokeParam*)malloc(DflInvokeParam.sizeof);
		
		if (!p)
			throw new OomException();
		
		static void fnentry(Control c, size_t[] p)
		{
			auto fn = cast(void function(Control))p[0];
			fn(c);
		}
		
		p.fp = &fnentry;
		p.nparams = 1;
		p.params[0] = cast(size_t)fn;
		
		return cast(LPARAM)p;
	}
	
	
	
public:
	///
	this(Control ctrl)
	{
		assert(ctrl);
		_ctrl = cast(shared)ctrl;
	}
	
	///
	void invoke(ARGS...)(void function(Control, ARGS) fn, ARGS args)
		if (ARGS.length && !hasLocalAliasing!(ARGS))
	{
		auto ctrl = cast(Control)_ctrl;
		auto hwnd = ctrl.handle;
		
		if(!hwnd)
			Control.badInvokeHandle();
		
		auto t = tuple(args);
		auto p = makeParam(fn, &t);
		SendMessageA(hwnd, wmDfl, WPARAM_DFL_DELAY_INVOKE_PARAMS, p);
	}
	
	///
	void invoke(ARGS...)(void function(Control, ARGS) fn, ARGS args)
		if (!ARGS.length)
	{
		auto ctrl = cast(Control)_ctrl;
		auto hwnd = ctrl.handle;
		
		if(!hwnd)
			Control.badInvokeHandle();
		
		auto p = makeParamNoneArgs(fn);
		SendMessageA(hwnd, wmDfl, WPARAM_DFL_DELAY_INVOKE_PARAMS, p);
	}
	
	///
	void delayInvoke(ARGS...)(void function(Control, ARGS) fn, ARGS args)
		if (ARGS.length && !hasLocalAliasing!(ARGS))
	{
		auto ctrl = cast(Control)_ctrl;
		auto hwnd = ctrl.handle;
		
		if(!hwnd)
			Control.badInvokeHandle();
		
		auto t = tuple(args);
		auto p = makeParam(fn, &t);
		PostMessageA(hwnd, wmDfl, WPARAM_DFL_DELAY_INVOKE_PARAMS, p);
	}
	
	///
	void delayInvoke(ARGS...)(void function(Control, ARGS) fn, ARGS args)
		if (!ARGS.length)
	{
		auto ctrl = cast(Control)_ctrl;
		auto hwnd = ctrl.handle;
		
		if(!hwnd)
			Control.badInvokeHandle();
		
		auto p = makeParamNoneArgs(fn);
		PostMessageA(hwnd, wmDfl, WPARAM_DFL_DELAY_INVOKE_PARAMS, p);
	}
}
