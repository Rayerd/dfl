// Written by Christopher E. Miller
// See the included license.txt for copyright and license details.


///
module dfl.control;


version(NO_DRAG_DROP)
	version = DFL_NO_DRAG_DROP;

version(DFL_NO_DRAG_DROP)
{
}
else
{
	import dfl.data;
}


import dfl.application;
import dfl.base;
import dfl.collections;
import dfl.drawing;
import dfl.event;
import dfl.form;
import dfl.label;
import dfl.menu;

import dfl.internal.clib;
import dfl.internal.com;
import dfl.internal.dlib;
import dfl.internal.dpiaware;
import dfl.internal.utf;
import dfl.internal.winapi;
import dfl.internal.wincom;

import std.algorithm : max;

import core.memory;


//version = RADIO_GROUP_LAYOUT;
version = DFL_NO_ZOMBIE_FORM;


int GET_X_LPARAM(LPARAM lparam) pure
{
	return cast(int)cast(short)LOWORD(lparam);
}

int GET_Y_LPARAM(in LPARAM lparam) pure
{
	return cast(int)cast(short)HIWORD(lparam);
}


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
		if (hwnd == gzi.find._hwnd)
		{
			gzi.index = gzi._tmp;
			return FALSE; // Stop, found it.
		}
		
		Control ctrl = Control.fromHandle(hwnd);
		if (ctrl && ctrl.parent is gzi.find.parent)
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


/// Effect flags for drag/drop operations with key states.
enum DragDropKeyStates
{
	NONE = 0,
	LEFT_MOUSE_BUTTON = 1,
	RIGHT_MOUSE_BUTTON = 2,
	SHIFT_KEY = 4,
	CONTROL_KEY = 8,
	MIDDLE_MOUSE_BUTTON = 16,
	ALT_KEY = 32
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
	FIXED_WIDTH =                      0x20, /// ditto (Implemented for TrackBar)
	FIXED_HEIGHT =                     0x40, /// ditto (Implemented for TrackBar)
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
	//OPTIMIZED_DOUBLE_BUFFER =          0x20000, // TODO: implement.
	USE_TEXT_FOR_ACCESSIBILITY =       0x40000, /// ditto
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
		_uiCues = uic;
	}
	
	
	final @property UICues changed() const // getter
	{
		return _uiCues;
	}
	
	
	final @property bool changeFocus() const
	{
		return (_uiCues & UICues.CHANGE_FOCUS) != 0;
	}
	
	
	final @property bool changeKeyboard() const
	{
		return (_uiCues & UICues.CHANGE_KEYBOARD) != 0;
	}
	
	
	final @property bool showFocus() const
	{
		return (_uiCues & UICues.SHOW_FOCUS) != 0;
	}
	
	
	final @property bool showKeyboard() const
	{
		return (_uiCues & UICues.SHOW_KEYBOARD) != 0;
	}
	
	
private:
	UICues _uiCues;
}


///
class ControlEventArgs: EventArgs
{
	///
	this(Control ctrl)
	{
		this._ctrl = ctrl;
	}
	
	
	///
	final @property inout(Control) control() inout // getter
	{
		return _ctrl;
	}
	
	
private:
	Control _ctrl;
}


///
class HelpEventArgs: EventArgs
{
	///
	this(Point mousePos)
	{
		_mousePos = mousePos;
	}
	
	
	///
	final @property void handled(bool byes) // setter
	{
		_handled = byes;
	}
	
	/// ditto
	final @property bool handled() const // getter
	{
		return _handled;
	}
	
	
	///
	final @property Point mousePos() const // getter
	{
		return _mousePos;
	}
	
	
private:
	Point _mousePos;
	bool _handled = false;
}


///
class InvalidateEventArgs: EventArgs
{
	///
	this(Rect invalidRect)
	{
		_invalidRect = invalidRect;
	}
	
	
	///
	final @property Rect invalidRect() const // getter
	{
		return _invalidRect;
	}
	
	
private:
	Rect _invalidRect;
}


// ///
// New dimensions before resizing.
deprecated class BeforeResizeEventArgs: EventArgs
{
deprecated:
	
	///
	this(int width, int height)
	{
		this._width = width;
		this._height = height;
	}
	
	
	///
	@property void width(int cx) // setter
	{
		_width = cx;
	}
	
	/// ditto
	@property int width() const // getter
	{
		return _width;
	}
	
	
	///
	@property void height(int cy) // setter
	{
		_height = cy;
	}
	
	/// ditto
	@property int height() const // getter
	{
		return _height;
	}
	
	
private:
	int _width, _height;
}


///
class LayoutEventArgs: EventArgs
{
	///
	this(Control affectedControl)
	{
		_affectedControl = affectedControl;
	}
	
	
	///
	final @property inout(Control) affectedControl() inout // getter
	{
		return _affectedControl;
	}
	
	
private:
	Control _affectedControl;
}


version(DFL_NO_DRAG_DROP) {} else
{
	///
	class DragEventArgs: EventArgs
	{
		///
		this(dfl.data.IDataObject dataObj, int keyState, int x, int y, DragDropEffects allowedEffect, DragDropEffects effect)
		{
			_dobj = dataObj;
			_keyState = keyState;
			_x = x;
			_y = y;
			_allowedEffect = allowedEffect;
			_effect = effect;
		}
		
		
		///
		final @property DragDropEffects allowedEffect() const // getter
		{
			return _allowedEffect;
		}
		
		
		///
		final @property void effect(DragDropEffects newEffect) // setter
		{
			_effect = newEffect;
		}
		
		
		/// ditto
		final @property DragDropEffects effect() const // getter
		{
			return _effect;
		}
		
		
		///
		final @property inout(dfl.data.IDataObject) data() inout // getter
		{
			return _dobj;
		}
		
		
		///
		// State of ctrl, alt, shift, and mouse buttons.
		final @property int keyState() const // getter
		{
			return _keyState;
		}
		
		
		///
		final @property int x() const // getter
		{
			return _x;
		}
		
		
		///
		final @property int y() const // getter
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
			_useDefaultCursors = useDefaultCursors;
		}
		
		
		///
		final @property DragDropEffects effect() const // getter
		{
			return _effect;
		}
		
		
		///
		final @property void useDefaultCursors(bool byes) // setter
		{
			_useDefaultCursors = byes;
		}
		
		/// ditto
		final @property bool useDefaultCursors() const // getter
		{
			return _useDefaultCursors;
		}
		
		
	private:
		DragDropEffects _effect;
		bool _useDefaultCursors;
	}
	
	
	///
	class QueryContinueDragEventArgs: EventArgs
	{
		///
		this(int keyState, bool escapePressed, DragAction action)
		{
			_keyState = keyState;
			_escapePressed = escapePressed;
			_action = action;
		}
		
		
		///
		final @property void action(DragAction newAction) // setter
		{
			_action = newAction;
		}
		
		/// ditto
		final @property DragAction action() const // getter
		{
			return _action;
		}
		
		
		///
		final @property bool escapePressed() const // getter
		{
			return _escapePressed;
		}
		
		
		///
		// State of ctrl, alt and shift.
		final @property int keyState() const // getter
		{
			return _keyState;
		}
		
		
	private:
		int _keyState;
		bool _escapePressed;
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

alias EnumWindowsCallback = BOOL delegate(HWND);
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
	if (efi.hwParent == GetParent(hwnd))
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
	CLASSIC, /// ditto
	NATIVE, /// ditto
	OLD = CLASSIC /// deprecated
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
		
		
		///
		@property int length() // getter
		{
			if (_owner.isHandleCreated)
			{
				// Inefficient :(
				uint len = 0;
				foreach (Control ctrl; this)
				{
					len++;
				}
				return len;
			}
			else
			{
				return _children.length.toI32;
			}
		}
		
		
		///
		@property Control opIndex(int i) // getter
		{
			if (_owner.isHandleCreated)
			{
				int oni = 0;
				foreach (Control ctrl; this)
				{
					if (oni == i)
						return ctrl;
					oni++;
				}
				// Index out of bounds, bad things happen.
				assert(0);
			}
			else
			{
				return _children[i];
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
			if (_owner.isHandleCreated)
			{
				int i = 0;
				int foundi = -1;
				
				
				BOOL enuming(HWND hwnd)
				{
					if (hwnd == ctrl.handle)
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
				foreach (i, Control onCtrl; _children)
				{
					if (i > int.max)
						throw new DflException("indexof() failure");
					if (onCtrl == ctrl)
						return cast(int)i;
				}
				return -1;
			}
		}
		
		
		///
		void remove(Control ctrl)
		{
			if (_owner.isHandleCreated)
			{
				_removeCreated(ctrl.handle);
			}
			else
			{
				int i = indexOf(ctrl);
				if (i != -1)
					_removeNotCreated(i);
			}
		}
		
		
		private void _removeCreated(HWND hwnd)
		{
			DestroyWindow(hwnd); // TODO: ?
		}
		
		
		package void _removeNotCreated(int i)
		{
			if (!i)
				_children = _children[1 .. $];
			else if (i + 1 == _children.length)
				_children = _children[0 .. i];
			else
				_children = _children[0 .. i] ~ _children[i + 1 .. $];
		}
		
		
		///
		void removeAt(int i)
		{
			if (_owner.isHandleCreated)
			{
				int ith = 0;
				HWND hwndith;
				
				
				BOOL enuming(HWND hwnd)
				{
					if (ith == i)
					{
						hwndith = hwnd;
						return false; // Stop.
					}
					
					ith++;
					return true; // Continue.
				}
				
				
				enumFirstChildWindows(_owner.handle, &enuming);
				if (hwndith)
					_removeCreated(hwndith);
			}
			else
			{
				_removeNotCreated(i);
			}
		}
		
		
		protected @property inout(Control) owner() inout // getter
		{
			return _owner;
		}
		
		
		///
		int opApply(int delegate(ref Control) dg)
		{
			int result = 0;
			
			if (_owner.isHandleCreated)
			{
				BOOL enuming(HWND hwnd)
				{
					Control ctrl = fromHandle(hwnd);
					if (ctrl)
					{
						result = dg(ctrl);
						if (result)
							return false; // Stop.
					}
					
					return true; // Continue.
				}
				
				
				enumFirstChildWindows(_owner.handle, &enuming);
			}
			else
			{
				foreach (Control ctrl; _children)
				{
					result = dg(ctrl);
					if (result)
						break;
				}
			}
			
			return result;
		}
		
		mixin OpApplyAddIndex!(opApply, Control);
		
		
	package:
		Control _owner;
		Control[] _children; // Only valid if -owner- isn't created yet (or is recreating).
		
		
		/+
		final void _array_swap(int ifrom, int ito)
		{
			if (ifrom == ito ||
				ifrom < 0 || ito < 0 ||
				ifrom >= length || ito >= length)
				return;
			
			Control cto;
			cto = children[ito];
			children[ito] = children[ifrom];
			children[ifrom] = cto;
		}
		+/
		
		
		void _simple_front_one(int i)
		{
			if (i < 0 || i >= length - 1)
				return;
			
			_children = _children[0 .. i] ~ _children[i + 1 .. i + 2] ~ _children[i .. i + 1] ~ _children[i + 2 .. $];
		}
		
		
		void _simple_front_one(Control c)
		{
			return _simple_front_one(indexOf(c));
		}
		
		
		void _simple_back_one(int i)
		{
			if (i <= 0 || i >= length)
				return;
			
			_children = _children[0 .. i - 1] ~ _children[i + 1 .. i + 2] ~ _children[i .. i + 1] ~ _children[i + 2 .. $];
		}
		
		
		void _simple_back_one(Control c)
		{
			return _simple_back_one(indexOf(c));
		}
		
		
		void _simple_back(int i)
		{
			if (i <= 0 || i >= length)
				return;
			
			_children = _children[i .. i + 1] ~ _children[0 .. i] ~ _children[i + 1 .. $];
		}
		
		
		void _simple_back(Control c)
		{
			return _simple_back(indexOf(c));
		}
		
		
		void _simple_front(int i)
		{
			if (i < 0 || i >= length - 1)
				return;
			
			_children = _children[0 .. i] ~ _children[i + 1 .. $] ~ _children[i .. i + 1];
		}
		
		
		void _simple_front(Control c)
		{
			return _simple_front(indexOf(c));
		}
	} // static class ControlCollection
	
	
	private void _ctrladded(ControlEventArgs cea)
	{
		if (Application._compat & DflCompat.CONTROL_PARENT_096)
		{
			if (!(_exStyle() & WS_EX_CONTROLPARENT))
			{
				if (!(_cbits & CBits.FORM))
				{
					//if ((cea.control._style() & WS_TABSTOP) || (cea.control._exStyle() & WS_EX_CONTROLPARENT))
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
		if (!isHandleCreated)
		{
			debug(APP_PRINT)
				cprintf("Control created due to handle request.\n");
			
			createHandle();
		}
		
		return _hwnd;
	}
	
	
	version(DFL_NO_DRAG_DROP) {} else
	{
		///
		private void allowDropImplement(bool byes)
		{
			/+
			if (dyes)
				_exStyle(_exStyle() | WS_EX_ACCEPTFILES);
			else
				_exStyle(_exStyle() & ~WS_EX_ACCEPTFILES);
			+/
			
			if (byes)
			{
				if (!_dropTarget)
				{
					if (isHandleCreated)
					{
						_dropTarget = new DropTarget(this);
						switch (RegisterDragDrop(_hwnd, _dropTarget))
						{
							case S_OK:
							case DRAGDROP_E_ALREADYREGISTERED: // Hmm.
								break;
							case DRAGDROP_E_INVALIDHWND:
							case E_OUTOFMEMORY:
								_dropTarget = null;
								throw new DflException("Unable to register drag-drop");
							default:
								assert(0);
						}
					}
				}
			}
			else
			{
				if (_dropTarget)
				{
					destroy(_dropTarget); // delete is deprecated.
					_dropTarget = null;
					switch (RevokeDragDrop(_hwnd))
					{
						case S_OK:
							break;
						case DRAGDROP_E_NOTREGISTERED:
						case DRAGDROP_E_INVALIDHWND:
						case E_OUTOFMEMORY:
							throw new DflException("Unable to revoke drag-drop");
						default:
							assert(0);
					}
				}
			}
		}
		
		///
		@property void allowDrop(bool byes) // setter
		{
			_allowDrop = byes;
			allowDropImplement(_allowDrop);
		}
		
		/// ditto
		@property bool allowDrop() const // getter
		{
			/+
			return (_exStyle() & WS_EX_ACCEPTFILES) != 0;
			+/
			
			return _allowDrop;
		}
	}
	
	
	/+
	deprecated void anchor(AnchorStyles a) // setter
	{
		/+
		anch = a;
		if (!(anch & (AnchorStyles.LEFT | AnchorStyles.RIGHT)))
			anch |= AnchorStyles.LEFT;
		if (!(anch & (AnchorStyles.TOP | AnchorStyles.BOTTOM)))
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
		Color bc = backColor;
		
		
		void pa(Control pc)
		{
			foreach (Control ctrl; pc.controls)
			{
				if (Color.empty == ctrl.backColor) // If default.
				{
					if (bc == ctrl.backColor) // If same default.
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
		if (_backColor == c)
			return;
		
		deleteThisBackgroundBrush(); // Needs to be recreated with new color.
		_backColor = c;
		onBackColorChanged(EventArgs.empty);
		
		_propagateBackColorAmbience();
		if (isHandleCreated)
			invalidate(true); // Redraw!
	}
	
	/// ditto
	@property Color backColor() const // getter
	{
		if (Color.empty == _backColor)
		{
			if (parent)
			{
				return parent.backColor;
			}
			return defaultBackColor;
		}
		return _backColor;
	}
	
	
	///
	final @property int bottom() const // getter
	{
		return _windowRect.bottom;
	}
	
	
	///
	final @property void bounds(Rect r) // setter
	{
		setBoundsCore(r.x, r.y, r.width, r.height, BoundsSpecified.ALL);
	}
	
	/// ditto
	final @property Rect bounds() const // getter
	{
		return _windowRect;
	}
	
	
	/+
	final @property Rect originalBounds() // getter package
	{
		return oldwrect;
	}
	+/
	
	
	///
	protected void setBoundsCore(int x_, int y_, int width_, int height_, BoundsSpecified specified)
	{
		// Make sure at least one flag is set.
		if (!specified)
			return;
		
		if (isHandleCreated)
		{
			UINT swpf = SWP_NOZORDER | SWP_NOACTIVATE | SWP_NOOWNERZORDER | SWP_NOMOVE | SWP_NOSIZE;
			
			if (specified & BoundsSpecified.X)
			{
				_windowRect.x = x_;
				swpf &= ~SWP_NOMOVE;
			}
			if (specified & BoundsSpecified.Y)
			{
				_windowRect.y = y_;
				swpf &= ~SWP_NOMOVE;
			}
			if (specified & BoundsSpecified.WIDTH)
			{
				_windowRect.width = width_;
				swpf &= ~SWP_NOSIZE;
			}
			if (specified & BoundsSpecified.HEIGHT)
			{
				_windowRect.height = height_;
				swpf &= ~SWP_NOSIZE;
			}
			
			int newX = MulDiv(_windowRect.x, dpi, USER_DEFAULT_SCREEN_DPI);
			int newY = MulDiv(_windowRect.y, dpi, USER_DEFAULT_SCREEN_DPI);
			int newWidth = MulDiv(_windowRect.width, dpi, USER_DEFAULT_SCREEN_DPI);
			int newHeight = MulDiv(_windowRect.height, dpi, USER_DEFAULT_SCREEN_DPI);

			SetWindowPos(_hwnd, HWND.init, newX, newY, newWidth, newHeight, swpf);
			// Window events will update -_windowRect-.
		}
		else
		{
			if (specified & BoundsSpecified.X)
				_windowRect.x = x_;
			if (specified & BoundsSpecified.Y)
				_windowRect.y = y_;
			if (specified & BoundsSpecified.WIDTH)
			{
				if (width_ < 0)
					width_ = 0;
				
				_windowRect.width = width_;
				_clientSize.width = width_;
			}
			if (specified & BoundsSpecified.HEIGHT)
			{
				if (height_ < 0)
					height_ = 0;
				
				_windowRect.height = height_;
				_clientSize.height = height_;
			}
		}
	}
	
	
	///
	final @property bool canFocus() const // getter
	{
		/+
		LONG wl = _style();
		return /+ hwnd && +/ (wl & WS_VISIBLE) && !(wl & WS_DISABLED);
		+/
		//return visible && enabled;
		// Don't need to check -isHandleCreated- because IsWindowVisible() will fail from a null HWND.
		return /+ isHandleCreated && +/ IsWindowVisible(cast(HWND)_hwnd) && IsWindowEnabled(cast(HWND)_hwnd);
	}
	
	
	///
	final @property bool canSelect() const // getter
	out(result)
	{
		if (result)
		{
			assert(isHandleCreated);
		}
	}
	do
	{
		// All parent controls need to be visible and enabled, too.
		// Don't need to check -isHandleCreated- because IsWindowVisible() will fail from a null HWND.
		return /+ isHandleCreated && +/ (_controlStyle & ControlStyles.SELECTABLE) &&
			IsWindowVisible(cast(HWND)_hwnd) && IsWindowEnabled(cast(HWND)_hwnd);
	}
	
	
	package final bool _hasSelStyle() const
	{
		return getStyle(ControlStyles.SELECTABLE);
	}
	
	
	///
	// Returns true if this control has the mouse capture.
	final @property bool capture() const // getter
	{
		return isHandleCreated && _hwnd == GetCapture();
	}
	
	/// ditto
	final @property void capture(bool cyes) // setter
	{
		if (cyes)
			SetCapture(_hwnd);
		else
			ReleaseCapture();
	}
	
	
	// When true, validating and validated events are fired when the control
	// receives focus. Typically set to false for controls such as a Help button.
	// Default is true.
	deprecated final bool causesValidation() const // getter
	{
		//return cvalidation;
		return false;
	}
	
	
	deprecated final void causesValidation(bool vyes) // setter
	{
		/+
		if (cvalidation == vyes)
			return;
		
		cvalidation = vyes;
		
		onCausesValidationChanged(EventArgs.empty);
		+/
	}
	
	
	deprecated protected void onCausesValidationChanged(EventArgs ea)
	{
		//causesValidationChanged(this, ea);
	}
	
	
	///
	final @property Rect clientRectangle() const // getter
	{
		return Rect(Point(0, 0), _clientSize);
	}
	
	
	///
	final bool contains(Control ctrl) const
	{
		//return controls.contains(ctrl);
		return ctrl && ctrl.parent is this;
	}
	
	
	///
	final @property Size clientSize() const // getter
	{
		return _clientSize;
	}
	
	/// ditto
	final @property void clientSize(Size sz) // setter
	{
		setClientSizeCore(sz.width, sz.height);
	}
	
	
	///
	protected void setClientSizeCore(int width_, int height_)
	{
		RECT r;
		r.left = 0;
		r.top = 0;
		// r.right = MulDiv(width_, dpi, USER_DEFAULT_SCREEN_DPI);
		// r.bottom = MulDiv(height_, dpi, USER_DEFAULT_SCREEN_DPI);
		r.right = width_;
		r.bottom = height_;
		
		// AdjustWindowRectEx(&r, _style(), FALSE, _exStyle());
		AdjustWindowRectExForDpi(&r, _style(), FALSE, _exStyle(), _windowDpi);
		
		setBoundsCore(0, 0, r.right - r.left, r.bottom - r.top, BoundsSpecified.SIZE);
	}
	
	
	///
	// This window or one of its children has focus.
	final @property bool containsFocus() const // getter
	{
		if (!isHandleCreated)
			return false;
		
		HWND hwfocus = GetFocus();
		return hwfocus == _hwnd || IsChild(cast(HWND)_hwnd, hwfocus);
	}
	
	
	///
	protected void onContextMenuChanged(EventArgs ea)
	{
		contextMenuChanged(this, ea);
	}
	
	
	///
	@property void contextMenu(ContextMenu menu) // setter
	{
		if (_contextMenu is menu)
			return;
		
		_contextMenu = menu;
		
		if (isHandleCreated)
		{
			onContextMenuChanged(EventArgs.empty);
		}
	}
	
	/// ditto
	@property inout(ContextMenu) contextMenu() inout // getter
	{
		return _contextMenu;
	}
	
	
	///
	final @property ControlCollection controls() // getter
	{
		if (!_controlCollection)
			_controlCollection = new ControlCollection(this);
		return _controlCollection;
	}
	
	
	///
	final @property bool created() const // getter
	{
		// TODO: only return true when createHandle finishes.
		// Will also need to update uses of created/isHandleCreated.
		// Return false again when disposing/killing.
		//return isHandleCreated;
		return isHandleCreated || recreatingHandle;
	}
	
	
	private void _propagateCursorAmbience()
	{
		Cursor cur = cursor;
		
		
		void pa(Control pc)
		{
			foreach (Control ctrl; pc.controls)
			{
				if (ctrl._windowCursor is null) // If default.
				{
					if (cur is ctrl.cursor) // If same default.
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
		
		if (isHandleCreated)
		{
			if (visible && enabled)
			{
				Point curpt = Cursor.position;
				if (_hwnd == WindowFromPoint(curpt.point))
				{
					SendMessageA(_hwnd, WM_SETCURSOR, cast(WPARAM)_hwnd,
						MAKELPARAM(
							SendMessageA(_hwnd, WM_NCHITTEST, 0, MAKELPARAM(curpt.x, curpt.y)).toI32,
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
		if (cur is _windowCursor)
			return;
		
		_windowCursor = cur;
		onCursorChanged(EventArgs.empty);
		
		_propagateCursorAmbience();
	}
	
	/// ditto
	@property inout(Cursor) cursor() inout // getter
	{
		if (!_windowCursor)
		{
			if (parent)
			{
				return parent.cursor;
			}
			return cast(inout(Cursor))_defaultCursor;
		}
		return _windowCursor;
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
	
	
	private static Font _defaultFont = null;


	private static Font _createClassicFont()
	{
		return new Font(cast(HFONT)GetStockObject(DEFAULT_GUI_FONT), false);
	}
	
	
	private static Font _createCompatibleFont()
	{
		Font result;

		OSVERSIONINFOA osi;
		osi.dwOSVersionInfoSize = osi.sizeof;
		if (GetVersionExA(&osi) && osi.dwMajorVersion >= 5) // Windows 2000 or greater
		{
			// "MS Shell Dlg" / "MS Shell Dlg 2" not always supported.
			float emSize = 9.0f;
			result = new Font("MS Shell Dlg 2", emSize, GraphicsUnit.POINT);
		}
		else
		{
			result = _createClassicFont();
		}
		
		return result;
	}
	
	
	private static Font _createNativeFont()
	{
		Font result;
		
		NONCLIENTMETRICSA ncm;
		ncm.cbSize = ncm.sizeof;
		if (!SystemParametersInfoA(SPI_GETNONCLIENTMETRICS, ncm.sizeof, &ncm, 0))
			result = _createCompatibleFont();
		else
			result = new Font(&ncm.lfMessageFont, true);
		
		return result;
	}
	
	
	private static void _setDefaultFont(ControlFont cf)
	{
		synchronized
		{
			assert(_defaultFont is null);
			final switch (cf)
			{
				case ControlFont.COMPATIBLE:
					_defaultFont = _createCompatibleFont();
					break;
				case ControlFont.NATIVE:
					_defaultFont = _createNativeFont();
					break;
				case ControlFont.CLASSIC:
					_defaultFont = _createClassicFont();
					break;
			}
		}
	}
	
	
	deprecated alias controlFont = defaultFont;
	
	///
	static @property void defaultFont(ControlFont cf) // setter
	{
		if (_defaultFont)
			throw new DflException("Control font already selected");
		_setDefaultFont(cf);
	}
	
	/// ditto
	static @property void defaultFont(Font f) // setter
	{
		if (_defaultFont)
			throw new DflException("Control font already selected");
		_defaultFont = f;
	}
	
	/// ditto
	static @property Font defaultFont() // getter
	{
		if (!_defaultFont)
			_setDefaultFont(ControlFont.COMPATIBLE);
		
		return _defaultFont;
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
		
		if (!def)
		{
			synchronized
			{
				if (!def)
					def = new SafeCursor(LoadCursor(HINSTANCE.init, IDC_ARROW));
			}
		}
		
		return def;
	}
	
	
	///
	@property Rect displayRectangle() // getter
	{
		Rect result = clientRectangle;
		
		// Subtract dock padding.
		result.x = result.x + _dockPadding.left;
		result.width = result.width - _dockPadding.right - _dockPadding.left;
		result.y = result.y + _dockPadding.top;
		result.height = result.height - _dockPadding.bottom - _dockPadding.top;

		return result;
	}
	
	
	///
	//protected void onDockChanged(EventArgs ea)
	protected void onHasLayoutChanged(EventArgs ea)
	{
		if (parent)
			parent.alayout(this);
		
		//dockChanged(this, ea);
		hasLayoutChanged(this, ea);
	}
	
	alias onDockChanged = onHasLayoutChanged;
	
	
	private void _alreadyLayout()
	{
		throw new DflException("Control already has a layout");
	}
	
	
	///
	@property DockStyle dock() const // getter
	{
		return _dockStyle;
	}
	
	/// ditto
	@property void dock(DockStyle ds) // setter
	{
		if (ds == _dockStyle)
			return;
		
		DockStyle _olddock = _dockStyle;
		_dockStyle = ds;
		/+
		anch = AnchorStyles.NONE; // Can't be set at the same time.
		+/
		_locationAlignment = LocationAlignment.NONE; // Can't be set at the same time.
		
		if (DockStyle.NONE == ds)
		{
			if (DockStyle.NONE != _olddock) // If it was even docking before; don't unset hasLayout for something else.
				hasLayout = false;
		}
		else
		{
			// Ensure not replacing some other layout, but OK if replacing another dock.
			if (DockStyle.NONE == _olddock)
			{
				if (hasLayout)
					_alreadyLayout();
			}
			hasLayout = true;
		}
		
		/+ // Called by hasLayout.
		if (isHandleCreated)
		{
			onDockChanged(EventArgs.empty);
		}
		+/
	}
	
	
	/// Get or set whether or not this control currently has its bounds managed. Fires onHasLayoutChanged as needed.
	final @property bool hasLayout() const // getter
	{
		if (_cbits & CBits.HAS_LAYOUT)
			return true;
		return false;
	}
	
	/// ditto
	final @property void hasLayout(bool byes) // setter
	{
		//if (byes == hasLayout)
		//	return; // No! setting this property again must trigger onHasLayoutChanged again.
		
		if (byes)
			_cbits |= CBits.HAS_LAYOUT;
		else
			_cbits &= ~CBits.HAS_LAYOUT;
		
		if (byes) // No need if layout is removed.
		{
			if (isHandleCreated)
			{
				onHasLayoutChanged(EventArgs.empty);
			}
		}
	}
	
	
	///
	class DockPaddingEdges
	{
	private:
		int _left, _top, _right, _bottom;
		int _all;
		
		
	final:
		void changed()
		{
			dockPaddingChanged();
		}
		
		
	public:
		///
		@property void all(int x) // setter
		{
			_bottom = _right = _top = _left = _all = x;
			
			changed();
		}
		
		/// ditto
		final @property int all() const // getter
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
		@property int left() const // getter
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
		@property int top() const // getter
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
		@property int right() const // getter
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
		@property int bottom() const // getter
		{
			return _bottom;
		}
	}
	
	
	///
	final @property DockPaddingEdges dockPadding() // getter
	{
		return _dockPadding;
	}
	
	
	///
	void dockPaddingChanged()
	{
		alayout(this);
	}
	

	///
	class DockMarginEdges
	{
	private:
		int _left, _top, _right, _bottom;
		int _all;
		
		
		void changed()
		{
			dockMarginChanged();
		}
		
		
	public:
		///
		@property void all(int x) // setter
		{
			_bottom = _right = _top = _left = _all = x;
			
			changed();
		}
		
		/// ditto
		final @property int all() const // getter
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
		@property int left() const // getter
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
		@property int top() const // getter
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
		@property int right() const // getter
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
		@property int bottom() const // getter
		{
			return _bottom;
		}
	}
	
	
	///
	final @property DockMarginEdges dockMargin() // getter
	{
		return _dockMargin;
	}

	
	///
	void dockMarginChanged()
	{
		alayout(this);
	}
	
	
	package final void _venabled(bool byes)
	{
		if (isHandleCreated)
		{
			EnableWindow(_hwnd, byes);
			// Window events will update -wstyle-.
		}
		else
		{
			if (byes)
				_windowStyle &= ~WS_DISABLED;
			else
				_windowStyle |= WS_DISABLED;
		}
	}
	
	
	///
	final @property void enabled(bool byes) // setter
	{
		if (byes)
			_cbits |= CBits.ENABLED;
		else
			_cbits &= ~CBits.ENABLED;
		
		/+
		if (!byes)
		{
			_venabled(false);
		}
		else
		{
			if (!parent || parent.enabled)
				_venabled(true);
		}
		
		_propagateEnabledAmbience();
		+/
		
		_venabled(byes);
	}
	
	///
	final @property bool enabled() const // getter
	{
		/*
		return IsWindowEnabled(hwnd) ? true : false;
		*/
		
		return (_windowStyle & WS_DISABLED) == 0;
	}
	
	
	private void _propagateEnabledAmbience()
	{
		/+ // Isn't working...
		if (cbits & CBits.FORM)
			return;
		
		bool en = enabled;
		
		void pa(Control pc)
		{
			foreach (Control ctrl; pc.controls)
			{
				if (ctrl.cbits & CBits.ENABLED)
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
	
	
	/// Has focus.
	@property bool focused() const // getter
	{
		//return isHandleCreated && hwnd == GetFocus();
		return created && fromChildHandle(GetFocus()) is this;
	}
	
	
	///
	@property void font(Font f) // setter
	{
		if (_windowFont is f)
			return;
		
		_windowFont = f;
		if (isHandleCreated)
		{
			_windowScaledFont = _createScaledFont(this.font, this._windowDpi);
			SendMessage(_hwnd, WM_SETFONT, cast(WPARAM)_windowScaledFont.handle, MAKELPARAM(true, 0));
		}
		onFontChanged(EventArgs.empty);
		
		_propagateFontAmbience();
	}
	
	/// ditto
	@property Font font() // getter
	{
		if (!_windowFont)
		{
			if (parent)
			{
				return parent.font;
			}
			return defaultFont;
		}
		return _windowFont;
	}


	///
	protected Font _createScaledFont(Font originalFont, uint dpi)
	{
		LogicalFont logFont;
		getLogFont(originalFont.handle, logFont);

		const LONG lfHeight = {
			HDC hdc = GetDC(_hwnd);
			scope (exit) ReleaseDC(_hwnd, hdc);

			const float emSize = originalFont.size;
			const GraphicsUnit unit = originalFont.unit;

			return Font.getLfHeight(hdc, emSize, unit, dpi);
		}();

		logFont.lf.lfHeight = lfHeight;

		HFONT hFont = CreateFontIndirect(&logFont.lf);
		return new Font(hFont, true);
	}


	///
	uint dpi() const pure nothrow @property
	{
		return _windowDpi;
	}
	
	
	private void _propagateForeColorAmbience()
	{
		Color fc = foreColor;
		
		
		void pa(Control pc)
		{
			foreach (Control ctrl; pc.controls)
			{
				if (Color.empty == ctrl._foreColor) // If default.
				{
					if (fc == ctrl.foreColor) // If same default.
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
		if (c == _foreColor)
			return;
		
		_foreColor = c;
		onForeColorChanged(EventArgs.empty);
		
		_propagateForeColorAmbience();
		if (isHandleCreated)
			invalidate(true); // Redraw!
	}
	
	/// ditto
	@property Color foreColor() const // getter
	{
		if (Color.empty == _foreColor)
		{
			if (parent)
			{
				return parent.foreColor;
			}
			return defaultForeColor;
		}
		return _foreColor;
	}
	
	
	///
	// Doesn't cause a ControlCollection to be constructed so
	// it could improve performance when walking through children.
	final @property bool hasChildren() // getter
	{
		//return isHandleCreated && GetWindow(hwnd, GW_CHILD) != HWND.init;
		
		if (isHandleCreated)
		{
			return GetWindow(_hwnd, GW_CHILD) != HWND.init;
		}
		else
		{
			return controls._children.length != 0;
		}
	}
	
	
	///
	final @property void height(int h) // setter
	{
		setBoundsCore(0, 0, 0, h, BoundsSpecified.HEIGHT);
	}
	
	/// ditto
	final @property int height() const // getter
	{
		return _windowRect.height;
	}
	
	
	///
	final @property bool isHandleCreated() const nothrow @safe // getter
	{
		return _hwnd != HWND.init;
	}
	
	
	///
	final @property void left(int l) // setter
	{
		setBoundsCore(l, 0, 0, 0, BoundsSpecified.X);
	}
	
	/// ditto
	final @property int left() const // getter
	{
		return _windowRect.x;
	}
	
	
	/// Property: get or set the X and Y location of the control.
	final @property void location(Point pt) // setter
	{
		setBoundsCore(pt.x, pt.y, 0, 0, BoundsSpecified.LOCATION);
	}
	
	/// ditto
	final @property Point location() const // getter
	{
		return _windowRect.location;
	}
	
	
	/// Currently depressed modifier keys.
	static @property Keys modifierKeys() // getter
	{
		// Is there a better way to do this?
		Keys ks = Keys.NONE;
		if (GetAsyncKeyState(VK_SHIFT) & 0x8000)
			ks |= Keys.SHIFT;
		if (GetAsyncKeyState(VK_MENU) & 0x8000)
			ks |= Keys.ALT;
		if (GetAsyncKeyState(VK_CONTROL) & 0x8000)
			ks|= Keys.CONTROL;
		return ks;
	}
	
	
	/// Currently depressed mouse buttons.
	static @property MouseButtons mouseButtons() // getter
	{
		MouseButtons result = MouseButtons.NONE;
		
		if (GetSystemMetrics(SM_SWAPBUTTON))
		{
			if (GetAsyncKeyState(VK_LBUTTON) & 0x8000)
				result |= MouseButtons.RIGHT; // Swapped.
			if (GetAsyncKeyState(VK_RBUTTON) & 0x8000)
				result |= MouseButtons.LEFT; // Swapped.
		}
		else
		{
			if (GetAsyncKeyState(VK_LBUTTON) & 0x8000)
				result |= MouseButtons.LEFT;
			if (GetAsyncKeyState(VK_RBUTTON) & 0x8000)
				result |= MouseButtons.RIGHT;
		}
		if (GetAsyncKeyState(VK_MBUTTON) & 0x8000)
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
		_controlName = txt;
	}
	
	/// ditto
	final @property Dstring name() const // getter
	{
		return _controlName;
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
		Control c = this;

		for (;;)
		{
			f = cast(Form)c;
			if (f)
				break;
			c = c.parent;
			if (!c)
				return null;
		}
		return f;
	}
	
	
	///
	final @property void parent(Control c) // setter
	{
		if (c is _parentWindow)
			return;
		
		if (!(_style() & WS_CHILD) || (_exStyle() & WS_EX_MDICHILD))
			throw new DflException("Cannot add a top level control to a control");
		
		//scope ControlEventArgs pcea = new ControlEventArgs(c);
		//onParentChanging(pcea);
		
		Control oldParent = _parentWindow;
		_FixAmbientOld oldInfo;
		
		if (oldParent)
		{
			oldInfo.set(oldParent);
			
			if (!oldParent.isHandleCreated)
			{
				int oi = oldParent.controls.indexOf(this);
				//assert(-1 != oi); // Fails if the parent (and thus this) handles destroyed.
				if (-1 != oi)
					oldParent.controls._removeNotCreated(oi);
			}
		}
		else
		{
			oldInfo.set(this);
		}
		
		scope ControlEventArgs cea = new ControlEventArgs(this);
		
		if (c)
		{
			_parentWindow = c;
			
			// I want the destroy notification. Don't need it anymore.
			//c._exStyle(c._exStyle() & ~WS_EX_NOPARENTNOTIFY);
			
			if (c.isHandleCreated)
			{
				_cbits &= ~CBits.NEED_INIT_LAYOUT;
				
				//if (created)
				if (isHandleCreated)
				{
					SetParent(_hwnd, c._hwnd);
				}
				else
				{
					// If the parent is created, create me!
					createControl();
				}
				
				onParentChanged(EventArgs.empty);
				if (oldParent)
					oldParent._ctrlremoved(cea);
				c._ctrladded(cea);
				_fixAmbient(&oldInfo);
				
				initLayout();
			}
			else
			{
				// If the parent exists and isn't created, need to add
				// -this- to its children array.
				c.controls._children ~= this;
				
				onParentChanged(EventArgs.empty);
				if (oldParent)
					oldParent._ctrlremoved(cea);
				c._ctrladded(cea);
				_fixAmbient(&oldInfo);
				
				_cbits |= CBits.NEED_INIT_LAYOUT;
			}
		}
		else
		{
			assert(c is null);
			//wparent = c;
			_parentWindow = null;
			
			if (isHandleCreated)
				SetParent(_hwnd, HWND.init);
			
			onParentChanged(EventArgs.empty);
			assert(oldParent !is null);
			oldParent._ctrlremoved(cea);
			_fixAmbient(&oldInfo);
		}
	}
	
	/// ditto
	final @property inout(Control) parent() inout // getter
	{
		return _parentWindow;
	}

	
	private Control _fetchParent()
	{
		HWND hwParent = GetParent(_hwnd);
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
		if (isHandleCreated)
		{
			// Need to make a copy of the region.
			SetWindowRgn(_hwnd, dupHrgn(rgn.handle), true);
		}
		
		_windowRegion = rgn;
	}
	
	/// ditto
	final @property Region region() // getter
	{
		return _windowRegion;
	}
	
	
	private Region _fetchRegion()
	{
		HRGN hrgn = CreateRectRgn(0, 0, 1, 1);
		GetWindowRgn(_hwnd, hrgn);
		return new Region(hrgn); // Owned because GetWindowRgn() gives a copy.
	}
	
	
	///
	final @property int right() const // getter
	{
		return _windowRect.right;
	}
	
	
	/+
	@property void rightToLeft(bool byes) // setter
	{
		LONG wl = _exStyle();
		if (byes)
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
		switch (val)
		{
			case RightToLeft.INHERIT:
				if (parent && parent.rightToLeft == RightToLeft.YES)
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
		RightToLeft rl = rightToLeft;
		
		
		void pa(Control pc)
		{
			if (RightToLeft.INHERIT == pc._rightToLeft)
			{
				//pc._fixRtol(rtol);
				pc._fixRtol(rl); // Set the specific parent value so it doesn't have to look up the chain.
				
				foreach (Control ctrl; pc.controls)
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
		if (_rightToLeft != val)
		{
			_rightToLeft = val;
			onRightToLeftChanged(EventArgs.empty);
			_propagateRtolAmbience(); // Also sets the class style and invalidates.
		}
	}
	
	/// ditto
	// Returns YES or NO; if inherited, returns parent's setting.
	@property RightToLeft rightToLeft() const // getter
	{
		if (RightToLeft.INHERIT == _rightToLeft)
		{
			return parent ? parent.rightToLeft : RightToLeft.NO;
		}
		return _rightToLeft;
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
			if (ctrl)
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
		// NOTE: exception will screw things up.
		
		_FixAmbientOld newinfo;
		if (parent)
			newinfo.set(parent);
		else
			newinfo.set(this);
		
		if (RightToLeft.INHERIT == _rightToLeft)
		{
			if (newinfo.rightToLeft !is oldinfo.rightToLeft)
			{
				onRightToLeftChanged(EventArgs.empty);
				_propagateRtolAmbience();
			}
		}
		
		if (Color.empty == _backColor)
		{
			if (newinfo.backColor !is oldinfo.backColor)
			{
				onBackColorChanged(EventArgs.empty);
				_propagateBackColorAmbience();
			}
		}
		
		if (Color.empty == _foreColor)
		{
			if (newinfo.foreColor !is oldinfo.foreColor)
			{
				onForeColorChanged(EventArgs.empty);
				_propagateForeColorAmbience();
			}
		}
		
		if (!_windowFont)
		{
			if (newinfo.font !is oldinfo.font)
			{
				onFontChanged(EventArgs.empty);
				_propagateFontAmbience();
			}
		}
		
		if (!_windowCursor)
		{
			if (newinfo.cursor !is oldinfo.cursor)
			{
				onCursorChanged(EventArgs.empty);
				_propagateCursorAmbience();
			}
		}
		
		/+
		if (newinfo.enabled != oldinfo.enabled)
		{
			if (cbits & CBits.ENABLED)
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
		foreach (Control ctrl; controls.children)
		{
			ctrl._fixAmbient();
		}
	}
	+/
	
	
	///
	final @property void size(Size sz) // setter
	{
		setBoundsCore(0, 0, sz.width, sz.height, BoundsSpecified.SIZE);
	}
	
	/// ditto
	final @property Size size() const // getter
	{
		return _windowRect.size; // struct Size, not sizeof.
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
	do
	{
		if (!parent)
			return 0;
		
		if (isHandleCreated)
		{
			GetZIndex gzi;
			gzi.find = this;
			int index;
			int tmp;
			
			BOOL getZIndexCallback(HWND hWnd)
			{
				if (hWnd is _hwnd)
				{
					index = tmp;
					return FALSE; // Stop, found it.
				}
				
				auto ctrl = Control.fromHandle(hWnd);
				if (ctrl && ctrl.parent is parent)
				{
					tmp++;
				}
				
				return TRUE; // Keep looking.
			}
			
			enumChildWindows(parent._hwnd, &getZIndexCallback);
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
		if (byes)
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
		_objectTag = o;
	}
	
	/// ditto
	final @property Object tag() // getter
	{
		return _objectTag;
	}
	
	
	private Dstring _fetchText() const
	{
		return dfl.internal.utf.getWindowText(cast(void*)_hwnd);
	}
	
	
	///
	@property void text(Dstring txt) // setter
	{
		if (isHandleCreated)
		{
			if (_controlStyle & ControlStyles.CACHE_TEXT)
			{
				//if (wtext == txt)
				//	return;
				_windowText = txt;
			}
			
			dfl.internal.utf.setWindowText(_hwnd, txt);
		}
		else
		{
			_windowText = txt;
		}
	}
	
	/// ditto
	@property Dstring text() const // getter
	{
		if (isHandleCreated)
		{
			if (_controlStyle & ControlStyles.CACHE_TEXT)
				return _windowText;
			
			return _fetchText();
		}
		else
		{
			return _windowText;
		}
	}
	
	
	///
	final @property void top(int t) // setter
	{
		setBoundsCore(0, t, 0, 0, BoundsSpecified.Y);
	}
	
	/// ditto
	final @property int top() const // getter
	{
		return _windowRect.y;
	}
	
	
	/// Returns the topmost Control related to this control.
	// Returns the owner control that has no parent.
	// Returns this Control if no owner ?
	final @property Control topLevelControl() // getter
	{
		if (isHandleCreated)
		{
			HWND hwCurrent = _hwnd;
			HWND hwParent;
			
			for (;;)
			{
				hwParent = GetParent(hwCurrent); // This gets the top-level one, whereas the previous code jumped owners.
				if (!hwParent)
					break;
				
				hwCurrent = hwParent;
			}
			
			return fromHandle(hwCurrent);
		}
		else
		{
			Control ctrl = this;
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
		wstyle = GetWindowLongPtrA(hwnd, GWL_STYLE);
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
		//if (isHandleCreated)
		//	wstyle = GetWindowLongPtrA(hwnd, GWL_STYLE); // ...
		//return (wstyle & WS_VISIBLE) != 0;
		return (_cbits & CBits.VISIBLE) != 0;
	}
	
	
	///
	final @property void width(int w) // setter
	{
		setBoundsCore(0, 0, w, 0, BoundsSpecified.WIDTH);
	}
	
	/// ditto
	final @property int width() const // getter
	{
		return _windowRect.width;
	}
	
	
	///
	final void sendToBack()
	{
		if (!isHandleCreated)
		{
			if (parent)
				parent.controls._simple_front(this);
			return;
		}
		
		SetWindowPos(_hwnd, HWND_BOTTOM, 0, 0, 0, 0, SWP_NOMOVE | SWP_NOSIZE);
	}
	
	
	///
	final void bringToFront()
	{
		if (!isHandleCreated)
		{
			if (parent)
				parent.controls._simple_back(this);
			return;
		}
		
		SetWindowPos(_hwnd, HWND_TOP, 0, 0, 0, 0, SWP_NOMOVE | SWP_NOSIZE);
		//BringWindowToTop(hwnd);
	}
	
	
	deprecated alias zIndexUp = bringUpOne;
	
	///
	// Move up one.
	final void bringUpOne()
	{
		if (!isHandleCreated)
		{
			if (parent)
				parent.controls._simple_front_one(this);
			return;
		}
		
		// Need to move back twice because the previous one already precedes this one.
		HWND hw = GetWindow(_hwnd, GW_HWNDPREV);
		if (!hw)
		{
			hw = HWND_TOP;
		}
		else
		{
			hw = GetWindow(hw, GW_HWNDPREV);
			if (!hw)
				hw = HWND_TOP;
		}
		
		SetWindowPos(_hwnd, hw, 0, 0, 0, 0, SWP_NOMOVE | SWP_NOSIZE);
	}
	
	
	deprecated alias zIndexDown = sendBackOne;
	
	///
	// Move back one.
	final void sendBackOne()
	{
		if (!isHandleCreated)
		{
			if (parent)
				parent.controls._simple_back_one(this);
			return;
		}
		
		HWND hw = GetWindow(_hwnd, GW_HWNDNEXT);
		if (!hw)
			hw = HWND_BOTTOM;
		
		SetWindowPos(_hwnd, hw, 0, 0, 0, 0, SWP_NOMOVE | SWP_NOSIZE);
	}
	
	
	// NOTE: true if no children, even if this not created.
	package final @property bool areChildrenCreated() // getter
	{
		return !controls._children.length;
	}
	
	
	package final void createChildren()
	{
		assert(isHandleCreated);
		
		Control[] ctrls = controls._children;
		controls._children = null;
		
		foreach (Control ctrl; ctrls)
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
		return new CommonGraphics(_hwnd, hdc);
	}
	
	
	version(DFL_NO_DRAG_DROP) {} else
	{
		private static class DropTarget: DflComObject, IDropTarget
		{
			this(Control ctrl)
			{
				this._ctrl = ctrl;
			}
			~this()
			{
				if (_dataObj)
				{
					GC.removeRoot(cast(void*)_dataObj);
					destroy(_dataObj);
				}
			}
			
			
		extern(Windows):
			override HRESULT QueryInterface(IID* riid, void** ppv)
			{
				if (*riid == _IID_IDropTarget)
				{
					*ppv = cast(void*)cast(IDropTarget)this;
					AddRef();
					return S_OK;
				}
				else if (*riid == _IID_IUnknown)
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
					
					scope DragEventArgs ea = new DragEventArgs(_dataObj, cast(int)grfKeyState, pt.x, pt.y, 
						cast(DragDropEffects)*pdwEffect, DragDropEffects.NONE); // TODO: ?
					_ctrl.onDragEnter(ea);
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
					assert(_dataObj !is null);
					
					scope DragEventArgs ea = new DragEventArgs(_dataObj, cast(int)grfKeyState, pt.x, pt.y, 
						cast(DragDropEffects)*pdwEffect, DragDropEffects.NONE); // TODO: ?
					_ctrl.onDragOver(ea);
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
					_ctrl.onDragLeave(EventArgs.empty);
					
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
					
					scope DragEventArgs ea = new DragEventArgs(_dataObj, cast(int)grfKeyState, pt.x, pt.y, 
						cast(DragDropEffects)*pdwEffect, DragDropEffects.NONE); // TODO: ?
					_ctrl.onDragDrop(ea);
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
			
			Control _ctrl;
			ComToDdataObject _dataObj; //dfl.data.IDataObject dataObj;
			
			
			void ensureDataObj(dfl.internal.wincom.IDataObject pDataObject)
			{
				if (!_dataObj)
				{
					_dataObj = new ComToDdataObject(pDataObject);
					GC.addRoot(cast(void*)_dataObj);
				}
				else if (!_dataObj.isSameDataObject(pDataObject))
				{
					GC.removeRoot(cast(void*)_dataObj);
					_dataObj = new ComToDdataObject(pDataObject);
					GC.addRoot(cast(void*)_dataObj);
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
				this._ctrl = ctrl;
				_mbtns = Control.mouseButtons;
			}
			
			
		extern(Windows):
			override HRESULT QueryInterface(IID* riid, void** ppv)
			{
				if (*riid == _IID_IDropSource)
				{
					*ppv = cast(void*)cast(IDropSource)this;
					AddRef();
					return S_OK;
				}
				else if (*riid == _IID_IUnknown)
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
					
					if (fEscapePressed)
					{
						act = cast(DragAction)DragAction.CANCEL;
					}
					else
					{
						if (_mbtns & MouseButtons.LEFT)
						{
							if (!(grfKeyState & MK_LBUTTON))
							{
								act = cast(DragAction)DragAction.DROP;
								goto qdoit;
							}
						}
						else
						{
							if (grfKeyState & MK_LBUTTON)
							{
								act = cast(DragAction)DragAction.CANCEL;
								goto qdoit;
							}
						}
						if (_mbtns & MouseButtons.RIGHT)
						{
							if (!(grfKeyState & MK_RBUTTON))
							{
								act = cast(DragAction)DragAction.DROP;
								goto qdoit;
							}
						}
						else
						{
							if (grfKeyState & MK_RBUTTON)
							{
								act = cast(DragAction)DragAction.CANCEL;
								goto qdoit;
							}
						}
						if (_mbtns & MouseButtons.MIDDLE)
						{
							if (!(grfKeyState & MK_MBUTTON))
							{
								act = cast(DragAction)DragAction.DROP;
								goto qdoit;
							}
						}
						else
						{
							if (grfKeyState & MK_MBUTTON)
							{
								act = cast(DragAction)DragAction.CANCEL;
								goto qdoit;
							}
						}
						
						act = cast(DragAction)DragAction.CONTINUE;
					}
					
				qdoit:
					scope QueryContinueDragEventArgs ea = new QueryContinueDragEventArgs(cast(int)grfKeyState,
						fEscapePressed != FALSE, act); // TODO: ?
					_ctrl.onQueryContinueDrag(ea);
					
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
					_ctrl.onGiveFeedback(ea);
					
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
			Control _ctrl;
			MouseButtons _mbtns;
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
			Object foo = cast(Object)dataObj; // NOTE: Hold a reference to the Object...
			
			DWORD effect;
			DropSource dropsrc = new DropSource(this);
			dfl.internal.wincom.IDataObject dropdata = new DtoComDataObject(dataObj);
			
			// dataObj seems to be killed too early.
			switch (DoDragDrop(dropdata, dropsrc, cast(DWORD)allowedEffects, &effect))
			{
				case DRAGDROP_S_DROP: // All good.
					break;
				
				case DRAGDROP_S_CANCEL:
					return DragDropEffects.NONE; // TODO: ?
				
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
		if (!ctrl)
			return 0; // Not equal.
		return opEquals(ctrl);
	}
	
	
	Dequ opEquals(Control ctrl)
	{
		if (!isHandleCreated)
			return super.opEquals(ctrl);
		return _hwnd == ctrl._hwnd;
	}
	
	
	override size_t toHash() const nothrow @trusted
	{
		return hashOf(_hwnd);
	}
	

	override int opCmp(Object o)
	{
		Control ctrl = cast(Control)o;
		if (!ctrl)
			return -1;
		return opCmp(ctrl);
	}
	
	
	int opCmp(Control ctrl)
	{
		if (!isHandleCreated || _hwnd != ctrl._hwnd)
			return super.opCmp(ctrl);
		return 0;
	}
	
	
	/// Set focus.
	final bool focus()
	{
		return SetFocus(_hwnd) != HWND.init;
	}
	
	
	/// Returns the Control instance from one of its window handles, or null if none.
	// Finds controls that own more than one handle.
	// A combo box has several HWNDs, this would return the
	// correct combo box control if any of those handles are
	// provided.
	static Control fromChildHandle(HWND hwChild)
	{
		Control result;
		for (;;)
		{
			if (!hwChild)
				return null;
			
			result = fromHandle(hwChild);
			if (result)
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
		HWND hwChild = ChildWindowFromPoint(_hwnd, pt.point);
		if (!hwChild)
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
		if (_hwnd)
		{
			SetWindowPos(_hwnd, HWND.init, 0, 0, 0, 0, SWP_FRAMECHANGED | SWP_DRAWFRAME | SWP_NOMOVE
				| SWP_NOSIZE | SWP_NOZORDER | SWP_NOACTIVATE);
		}
	}
	
	
	package final void recalcEntire()
	{
		if (_hwnd)
		{
			SetWindowPos(_hwnd, HWND.init, 0, 0, 0, 0, SWP_FRAMECHANGED | SWP_NOMOVE
				| SWP_NOSIZE | SWP_NOZORDER | SWP_NOACTIVATE);
		}
	}
	
	
	///
	final void invalidate()
	{
		if (!_hwnd)
			return;
		
		RedrawWindow(_hwnd, null, HRGN.init, RDW_ERASE | RDW_INVALIDATE | RDW_NOCHILDREN);
	}
	
	/// ditto
	final void invalidate(bool andChildren)
	{
		if (!_hwnd)
			return;
		
		RedrawWindow(_hwnd, null, HRGN.init, RDW_ERASE | RDW_INVALIDATE | (andChildren ? RDW_ALLCHILDREN : RDW_NOCHILDREN));
	}
	
	/// ditto
	final void invalidate(Rect r)
	{
		if (!_hwnd)
			return;
		
		RECT rect;
		r.getRect(&rect);
		
		RedrawWindow(_hwnd, &rect, HRGN.init, RDW_ERASE | RDW_INVALIDATE | RDW_NOCHILDREN);
	}
	
	/// ditto
	final void invalidate(Rect r, bool andChildren)
	{
		if (!_hwnd)
			return;
		
		RECT rect;
		r.getRect(&rect);
		
		RedrawWindow(_hwnd, &rect, HRGN.init, RDW_ERASE | RDW_INVALIDATE | (andChildren ? RDW_ALLCHILDREN : RDW_NOCHILDREN));
	}
	
	/// ditto
	final void invalidate(Region rgn)
	{
		if (!_hwnd)
			return;
		
		RedrawWindow(_hwnd, null, rgn.handle, RDW_ERASE | RDW_INVALIDATE | RDW_NOCHILDREN);
	}
	
	/// ditto
	final void invalidate(Region rgn, bool andChildren)
	{
		if (!_hwnd)
			return;
		
		RedrawWindow(_hwnd, null, rgn.handle, RDW_ERASE | RDW_INVALIDATE | (andChildren ? RDW_ALLCHILDREN : RDW_NOCHILDREN));
	}
	
	
	///
	// Redraws the entire control, including nonclient area.
	final void redraw()
	{
		if (!_hwnd)
			return;
		
		RedrawWindow(_hwnd, null, HRGN.init, RDW_ERASE | RDW_INVALIDATE | RDW_FRAME);
	}
	
	
	/// Returns true if the window does not belong to the current thread.
	@property bool invokeRequired() // getter
	{
		DWORD tid = GetWindowThreadProcessId(_hwnd, null);
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
		if (!_hwnd)
			badInvokeHandle();
		
		static assert((DflInvokeParam*).sizeof <= LPARAM.sizeof);
		
		static struct DelegateInvokeParam
		{
			Object delegate(Object[]) dg;
			Object result;
			Object[] args;
		}

		static void funcEntry(Control c, size_t[] p)
		{
			auto dip = cast(DelegateInvokeParam*)p[0];
			dip.result = dip.dg(dip.args);
		}

		DelegateInvokeParam dip;
		dip.dg = dg;
		dip.args = args;

		DflInvokeParam dflInvokeParam;
		dflInvokeParam.fp = &funcEntry;
		dflInvokeParam.exception = null;
		dflInvokeParam.nparams = args.length;
		dflInvokeParam.params[0] = cast(size_t)&dip;
		
		if (LRESULT_DFL_INVOKE != SendMessageA(_hwnd, wmDfl, WPARAM_DFL_INVOKE_PARAMS, cast(LPARAM)&dflInvokeParam))
			throw new DflException("Invoke failure");
		if (dflInvokeParam.exception)
			throw dflInvokeParam.exception;
		
		return dip.result;
	}
	
	/// ditto
	final void invoke(void delegate() dg)
	{
		if (!_hwnd)
			badInvokeHandle();
		
		static assert((DflInvokeParam*).sizeof <= LPARAM.sizeof);

		static struct DelegateInvokeParam
		{
			void delegate() dg;
		}

		static void funcEntry(Control c, size_t[] p)
		{
			auto dip = cast(DelegateInvokeParam*)p[0];
			dip.dg();
		}

		DelegateInvokeParam dip;
		dip.dg = dg;

		DflInvokeParam dflInvokeParam;
		dflInvokeParam.fp = &funcEntry;
		dflInvokeParam.exception = null;
		dflInvokeParam.nparams = 0;
		dflInvokeParam.params[0] = cast(size_t)&dip;
		
		if (LRESULT_DFL_INVOKE != SendMessageA(_hwnd, wmDfl, WPARAM_DFL_INVOKE_NOPARAMS, cast(LPARAM)&dflInvokeParam))
			throw new DflException("Invoke failure");
		if (dflInvokeParam.exception)
			throw dflInvokeParam.exception;
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
		if (!_hwnd)
			badInvokeHandle();
		
		static assert((DflInvokeParam*).sizeof <= LPARAM.sizeof);

		static void funcEntry(Control c, size_t[] p)
		{
			auto func = cast(void function())p[0];
			func();
		}

		DflInvokeParam* dflInvokeParam = cast(DflInvokeParam*)malloc(DflInvokeParam.sizeof);
		if (!dflInvokeParam)
			throw new OomException();

		dflInvokeParam.fp = &funcEntry;
		dflInvokeParam.exception = null;
		dflInvokeParam.nparams = 0;
		dflInvokeParam.params[0] = cast(size_t)fn;

		PostMessageA(_hwnd, wmDfl, WPARAM_DFL_DELAY_INVOKE_NOPARAMS, cast(LPARAM)dflInvokeParam);
	}
	
	/// ditto
	// Extra.
	// Exceptions will be passed to Application.onThreadException() and
	// trigger the threadException event or the default exception dialog.
	// Copy of params are passed to fn, they do not exist after it returns.
	// It is unsafe to pass references to a delayed function.
	final void delayInvoke(void function(Control, size_t[]) fn, size_t[] params ...)
	{
		if (!_hwnd)
			badInvokeHandle();
		
		static assert((DflInvokeParam*).sizeof <= LPARAM.sizeof);
		
		DflInvokeParam* dflInvokeParams = cast(DflInvokeParam*)malloc(
			DflInvokeParam.sizeof - size_t.sizeof + params.length * size_t.sizeof);
		if (!dflInvokeParams)
			throw new OomException();
		
		dflInvokeParams.fp = fn;
		dflInvokeParams.exception = null;
		dflInvokeParams.nparams = params.length;
		dflInvokeParams.params.ptr[0 .. params.length] = params[];
		
		PostMessageA(_hwnd, wmDfl, WPARAM_DFL_DELAY_INVOKE_PARAMS, cast(LPARAM)dflInvokeParams);
	}
	
	deprecated alias beginInvoke = delayInvoke;
	
	
	///
	static bool isMnemonic(dchar charCode, Dstring text)
	{
		for (size_t ui = 0; ui != text.length; ui++)
		{
			if ('&' == text[ui])
			{
				if (++ui == text.length)
					break;
				if ('&' == text[ui]) // && means literal & so skip it.
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
		ScreenToClient(_hwnd, &pt.point);
		return pt;
	}
	
	
	/// Converts a client Point to a screen Point.
	final Point pointToScreen(Point pt)
	{
		ClientToScreen(_hwnd, &pt.point);
		return pt;
	}
	
	
	/// Converts a screen Rectangle to a client Rectangle.
	final Rect rectangleToClient(Rect r)
	{
		RECT rect;
		r.getRect(&rect);
		
		MapWindowPoints(HWND.init, _hwnd, cast(POINT*)&rect, 2);
		return Rect(&rect);
	}
	
	
	/// Converts a client Rectangle to a screen Rectangle.
	final Rect rectangleToScreen(Rect r)
	{
		RECT rect;
		r.getRect(&rect);
		
		MapWindowPoints(_hwnd, HWND.init, cast(POINT*)&rect, 2);
		return Rect(&rect);
	}
	
	
	/// Process shortcut key (ctrl+A etc).
	// Returns false when parent is none, otherwise call parent form's one.
	protected bool processCmdKey(ref Message msg, Keys keyData)
	{
		if (parent)
			return parent.processCmdKey(msg, keyData);
		else
			return false;
	}

	/// Process dialog key (TAB, RETURN, ESC, UP, DOWN, LEFT, RIGHT and so on).
	// Returns false when parent is none, otherwise call parent form's one.
	protected bool processDialogKey(Keys keyData)
	{
		if (parent)
			return parent.processDialogKey(keyData);
		else
			return false;
	}

	/// Process mnemonic (access key) such as Alt+T.
	// Returns false when parent is none, otherwise call parent form's one.
	protected bool processDialogChar(char charCode)
	{
		if (parent)
			return parent.processDialogChar(charCode);
		else
			return false;
	}

	/// Pre-process keybord message
	// This function called from Application.DflWndProc().
	// If return true, processed message,
	// then wndProc() be not called after preProcessMessage().
	// If return false, wndProc() be called after preProcessMessage().
	bool preProcessMessage(ref Message msg)
	{
		bool result/+ = false+/;

		if (msg.msg == WM_KEYDOWN || msg.msg == WM_SYSKEYDOWN)
		{
			// TODO: Implement
			// if (!getExtendedState(ExtendedStates.UiCues))
			// {
			// 	processUICues(msg);
			// }
			
			Keys keyData = cast(Keys)msg.wParam | modifierKeys;

			// processCmdKey returns true when keyData is a shortcut key (ctrl+C etc).
			if (processCmdKey(msg, keyData))
			{
				result = true;
			}
			// isInputKey returns true when keyData is a regular input key.
			else if (isInputKey(keyData))
			{
				// TODO: Implement
				// SetExtendedState(ExtendedStates.InputKey, true);
				result = false; // End preprocessing and call wndProc().
			}
			else
			{
				// Process dialog keys such as TAB, RETURN, ESC, UP, DOWN, RIGHT, LEFT.
				result = processDialogKey(keyData);
			}
		}
		else if (msg.msg == WM_CHAR || msg.msg == WM_SYSCHAR)
		{
			if (msg.msg == WM_CHAR && isInputChar(cast(char)msg.wParam))
			{
				// TODO: Implement
				// setExtendedState(ExtendedStates.InputChar, true);
				result = false;
			}
			else
			{
				result = processDialogChar(cast(char)msg.wParam);
			}
		}
		else
		{
			result = false;
		}

		return result;
	}
	
	
	///
	final Size getAutoScaleSize(Font f)
	{
		Graphics g = createGraphics();
		scope (exit) g.dispose();
		return g.getScaleSize(f);
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
		if (_disallowLayout)
			_disallowLayout--;
	}
	
	/// ditto
	// Allow layout recalc, only do it now if -byes- is true.
	final void resumeLayout(bool byes)
	{
		if (_disallowLayout)
			_disallowLayout--;
		
		// This is correct.
		if (byes)
		{
			if (!_disallowLayout)
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
		for (; hw; hw = GetWindow(hw, GW_HWNDNEXT))
		{
			if (!xiter)
				return false;
			xiter--;
			
			LONG st = GetWindowLongPtrA(hw, GWL_STYLE).toI32;
			if (!(st & WS_VISIBLE))
				continue;
			if (st & WS_DISABLED)
				continue;
			
			if (!callback(hw))
				return false;
			
			if (nested)
			{
				//LONG exst = GetWindowLongPtrA(hw, GWL_EXSTYLE);
				//if (exst & WS_EX_CONTROLPARENT) // It's no longer added.
				{
					HWND hwc = GetWindow(hw, GW_CHILD);
					if (hwc)
					{
						//if (!_eachild(hwc, callback, xiter, nested))
						if (!_eachild(hwc, callback, xiter, true))
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
	
	
	package static bool _dlgselnext(Form dlg, HWND hwcursel, bool forward,
		bool tabStopOnly = true, bool selectableOnly = false,
		bool nested = true, bool wrap = true,
		HWND hwchildrenof = null)
	{
		//assert(cast(Form)Control.fromHandle(hwdlg) !is null);
		
		if (!hwchildrenof)
			hwchildrenof = dlg.handle;
		if (forward)
		{
			bool foundthis = false, tdone = false;
			HWND hwfirst;
			eachGoodChildHandle(hwchildrenof,
				(HWND hw)
				{
					assert(!tdone);
					if (hw == hwcursel)
					{
						foundthis = true;
					}
					else
					{
						if (!tabStopOnly || (GetWindowLongPtrA(hw, GWL_STYLE) & WS_TABSTOP))
						{
							if (!selectableOnly || _isHwndControlSel(hw))
							{
								if (foundthis)
								{
									//DefDlgProcA(dlg.handle, WM_NEXTDLGCTL, cast(WPARAM)hw, MAKELPARAM(true, 0));
									dlg._selectChild(hw);
									tdone = true;
									return false; // Break.
								}
								else
								{
									if (HWND.init == hwfirst)
										hwfirst = hw;
								}
							}
						}
					}
					return true; // Continue.
				}, nested);
			if (!tdone && HWND.init != hwfirst)
			{
				// If it falls through without finding hwcursel, let it select the first one, even if not wrapping.
				if (wrap || !foundthis)
				{
					//DefDlgProcA(dlg.handle, WM_NEXTDLGCTL, cast(WPARAM)hwfirst, MAKELPARAM(true, 0));
					dlg._selectChild(hwfirst);
					return true;
				}
			}
		}
		else
		{
			HWND hwprev;
			eachGoodChildHandle(hwchildrenof,
				(HWND hw)
				{
					if (hw == hwcursel)
					{
						if (HWND.init != hwprev) // Otherwise, keep looping and get last one.
							return false; // Break.
						if (!wrap) // No wrapping, so don't get last one.
						{
							assert(HWND.init == hwprev);
							return false; // Break.
						}
					}
					if (!tabStopOnly || (GetWindowLongPtrA(hw, GWL_STYLE) & WS_TABSTOP))
					{
						if (!selectableOnly || _isHwndControlSel(hw))
						{
							hwprev = hw;
						}
					}
					return true; // Continue.
				}, nested);
			// If it falls through without finding hwcursel, let it select the last one, even if not wrapping.
			if (HWND.init != hwprev)
			{
				//DefDlgProcA(dlg.handle, WM_NEXTDLGCTL, cast(WPARAM)hwprev, MAKELPARAM(true, 0));
				dlg._selectChild(hwprev);
				return true;
			}
		}
		return false;
	}
	
	
	package final bool _selectNextControl(Form ctrltoplevel, Control ctrl, bool forward, bool tabStopOnly, bool nested, bool wrap)
	{
		if (!created)
			return false;
		
		assert(ctrltoplevel !is null);
		assert(ctrltoplevel.isHandleCreated);
		
		return _dlgselnext(ctrltoplevel,
			(ctrl && ctrl.isHandleCreated) ? ctrl.handle : null,
			forward, tabStopOnly, !tabStopOnly, nested, wrap,
			this.handle);
	}
	
	
	package final void _selectThisControl()
	{
		
	}
	
	
	// Only considers child controls of this control.
	final bool selectNextControl(Control ctrl, bool forward, bool tabStopOnly, bool nested, bool wrap)
	{
		if (!created)
			return false;
		
		auto ctrltoplevel = findForm();
		if (ctrltoplevel)
			return _selectNextControl(ctrltoplevel, ctrl, forward, tabStopOnly, nested, wrap);

		return false;
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
		if (!created)
			return;
		
		auto ctrltoplevel = findForm();
		if (ctrltoplevel && ctrltoplevel !is this)
		{
			/+ // Old...
			// Even if directed, ensure THIS one is selected first.
			if (!directed || hwnd != GetFocus())
			{
				DefDlgProcA(ctrltoplevel.handle, WM_NEXTDLGCTL, cast(WPARAM)hwnd, MAKELPARAM(true, 0));
			}
			
			if (directed)
			{
				DefDlgProcA(ctrltoplevel.handle, WM_NEXTDLGCTL, !forward, MAKELPARAM(false, 0));
			}
			+/
			
			if (directed)
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
	final void setBounds(int x_, int y_, int width_, int height_)
	{
		setBoundsCore(x_, y_, width_, height_, BoundsSpecified.ALL);
	}
	
	/// ditto
	final void setBounds(int x_, int y_, int width_, int height_, BoundsSpecified specified)
	{
		setBoundsCore(x_, y_, width_, height_, specified);
	}
	
	
	///
	override Dstring toString() const
	{
		return text;
	}
	
	
	///
	final void update()
	{
		if (!created)
			return;
		
		UpdateWindow(_hwnd);
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
		GetWindowRect(_hwnd, &r);
		HWND hwParent = GetParent(_hwnd);
		if (hwParent && (_style() & WS_CHILD))
			MapWindowPoints(HWND_DESKTOP, hwParent, cast(POINT*)&r, 2);
		return Rect(
			MulDiv(r.left, USER_DEFAULT_SCREEN_DPI, dpi),
			MulDiv(r.top, USER_DEFAULT_SCREEN_DPI, dpi),
			MulDiv(r.right - r.left, USER_DEFAULT_SCREEN_DPI, dpi),
			MulDiv(r.bottom - r.top, USER_DEFAULT_SCREEN_DPI, dpi));
	}
	
	
	package final Size _fetchClientSize()
	{
		RECT r;
		GetClientRect(_hwnd, &r);
		return Size(
			MulDiv(r.right, USER_DEFAULT_SCREEN_DPI, dpi),
			MulDiv(r.bottom, USER_DEFAULT_SCREEN_DPI, dpi));
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
	protected void onMoving(MovingEventArgs cea)
	{
		moving(this, cea);
	}
	

	///
	protected void onMove(EventArgs ea)
	{
		move(this, ea);
	}
	
	alias onLocationChanged = onMove;
	
	
	///
	protected void onSizing(SizingEventArgs cea)
	{
		sizing(this, cea);
	}
	

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
	alias onSizeChanged = onResize;
	
	
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
		foreach (CancelEventHandler.Handler handler; validating.handlers())
		{
			handler(this, cea);
			
			if (cea.cancel)
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
		Font f = font;
		
		
		void pa(Control pc)
		{
			foreach (Control ctrl; pc.controls)
			{
				if (!ctrl._windowFont) // If default.
				{
					if (f is ctrl.font) // If same default.
					{
						if (ctrl.isHandleCreated)
						{
							ctrl._windowScaledFont = _createScaledFont(f, this._windowDpi);
							SendMessage(ctrl._hwnd, WM_SETFONT, cast(WPARAM)ctrl._windowScaledFont.handle, MAKELPARAM(true, 0));
						}
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
		if (_parentWindow)
		{
			_parentWindow.vchanged();
			suspendLayout(); // NOTE: exception could cause failure to restore.
			_parentWindow.alayout(this);
			resumeLayout(false);
		}
		if (visible)
			alayout(this);
		
		visibleChanged(this, ea);
		
		if (visible)
		{
			// If no focus or the focused control is hidden, try to select something...
			HWND hwfocus = GetFocus();
			if (!hwfocus
				|| (hwfocus == _hwnd && !getStyle(ControlStyles.SELECTABLE))
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
		if (!(_cbits & CBits.VSTYLE))
			_disableVisualStyle();
		
		Font f = font;
		if (f)
		{
			_windowScaledFont = _createScaledFont(f, this._windowDpi);
			SendMessage(_hwnd, WM_SETFONT, cast(WPARAM)_windowScaledFont.handle, 0);
		}
		
		if (_windowRegion)
		{
			// Need to make a copy of the region.
			SetWindowRgn(_hwnd, dupHrgn(_windowRegion.handle), true);
		}
		
		version (DFL_NO_DRAG_DROP) {} else
		{
			// Need to do "allowDrop = true/false" after created handle.
			// When do "allowDrop = true" in MyForm.this(),
			// Now is _allowDrop == true and droptarget is null.
			// Therefore call here allowDropImplement() without change _allowDrop value.
			allowDropImplement(_allowDrop);
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
		rect.left = MulDiv(rect.left, dpi, USER_DEFAULT_SCREEN_DPI);
		rect.top = MulDiv(rect.top, dpi, USER_DEFAULT_SCREEN_DPI);
		rect.right = MulDiv(rect.right, dpi, USER_DEFAULT_SCREEN_DPI);
		rect.bottom = MulDiv(rect.bottom, dpi, USER_DEFAULT_SCREEN_DPI);
		FillRect(pea.graphics.handle, &rect, backgroundHbrush);
	}
	
	
	private static MouseButtons wparamMouseButtons(WPARAM wparam)
	{
		MouseButtons result;
		if (wparam & MK_LBUTTON)
			result |= MouseButtons.LEFT;
		if (wparam & MK_RBUTTON)
			result |= MouseButtons.RIGHT;
		if (wparam & MK_MBUTTON)
			result |= MouseButtons.MIDDLE;
		return result;
	}
	
	
	package final void prepareDc(HDC hdc)
	{
		//SetBkMode(hdc, TRANSPARENT); // TODO: ?
		//SetBkMode(hdc, OPAQUE); // TODO: ?
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
		switch (m.msg)
		{
			case WM_CTLCOLORSTATIC:
			case WM_CTLCOLORLISTBOX:
			case WM_CTLCOLOREDIT:
			case WM_CTLCOLORSCROLLBAR:
			case WM_CTLCOLORBTN:
			//case WM_CTLCOLORDLG: // TODO: ?
			//case 0x0019: //WM_CTLCOLOR; obsolete.
				prepareDc(cast(HDC)m.wParam);
				//assert(GetObjectA(hbrBg, 0, null));
				m.result = cast(LRESULT)backgroundHbrush;
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
		if (pt.x < 0 || pt.y < 0)
			return HWND.init;
		if (pt.x > _clientSize.width || pt.y > _clientSize.height)
			return HWND.init;
		
		// NOTE: doesn't include non-DFL windows...
		// TODO: fix.
		foreach (Control ctrl; controls)
		{
			if (!ctrl.visible)
				continue;
			if (!ctrl.isHandleCreated) // Shouldn't..
				continue;
			if (ctrl.bounds.contains(pt))
				return ctrl._hwnd;
		}
		
		return _hwnd; // Just over this control.
	}
	
	
	version(_DFL_WINDOWS_HUNG_WORKAROUND)
	{
		DWORD ldlgcode = 0;
	}
	

	///
	protected bool processKeyPreview(ref Message m)
	{
		return parent && parent.processKeyPreview(m);
	}


	///
	// Returns true in order to break in wndProc(), because processed.
	protected final bool processKeyMessage(ref Message m)
	{
		if (parent && parent.processKeyPreview(m))
		{
			return true;
		}
		return processKeyEventArgs(m);
	}


	///
	protected void onDpiChanged(uint newDpi)
	{
		// Do nothing in Control class.
	}


	///
	protected void wndProc(ref Message msg)
	{
		//if (ctrlStyle & ControlStyles.ENABLE_NOTIFY_MESSAGE)
		//	onNotifyMessage(msg);
		
		switch (msg.msg)
		{
			case WM_DPICHANGED: // Called only on top-level windows such as Form.
			{
				this._windowDpi = cast(uint)LOWORD(msg.wParam);
				const Rect rect = Rect(cast(RECT*)msg.lParam);

				_windowScaledFont = this._createScaledFont(this.font, this._windowDpi);
				SendMessage(handle, WM_SETFONT, cast(WPARAM)_windowScaledFont.handle, MAKELPARAM(true, 0));
				
				MoveWindow(msg.hWnd, rect.x, rect.y, rect.width, rect.height, FALSE);

				onDpiChanged(this._windowDpi);

				void recursiveDpiChange(ControlCollection children, uint newDpi)
				{
					foreach (child; children)
					{
						child._windowDpi = newDpi;

						child._windowScaledFont = child._createScaledFont(child.font, newDpi);
						SendMessage(child.handle, WM_SETFONT, cast(WPARAM)child._windowScaledFont.handle, MAKELPARAM(true, 0));

						RECT rc;
						rc.left = MulDiv(child.location.x, newDpi, USER_DEFAULT_SCREEN_DPI);
						rc.top = MulDiv(child.location.y, newDpi, USER_DEFAULT_SCREEN_DPI);
						rc.right = MulDiv(child.right, newDpi, USER_DEFAULT_SCREEN_DPI);
						rc.bottom = MulDiv(child.bottom, newDpi, USER_DEFAULT_SCREEN_DPI);

						MoveWindow(child.handle, rc.left, rc.top, rc.right - rc.left, rc.bottom - rc.top , FALSE);

						child.onDpiChanged(newDpi);

						if (child.controls.length != 0)
							recursiveDpiChange(child.controls, newDpi);
					}
				}

				if (this.controls.length != 0)
					recursiveDpiChange(this.controls, this._windowDpi);

				InvalidateRect(msg.hWnd, null, TRUE);
				msg.result = 0;
				return;
			}

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
					
					RECT rect = ps.rcPaint;
					rect.left = MulDiv(rect.left, USER_DEFAULT_SCREEN_DPI, dpi);
					rect.top = MulDiv(rect.top, USER_DEFAULT_SCREEN_DPI, dpi);
					rect.right = MulDiv(rect.right, USER_DEFAULT_SCREEN_DPI, dpi);
					rect.bottom = MulDiv(rect.bottom, USER_DEFAULT_SCREEN_DPI, dpi);
					scope PaintEventArgs pea = new PaintEventArgs(new Graphics(ps.hdc, false), Rect(&rect));
					
					// Probably because ControlStyles.ALL_PAINTING_IN_WM_PAINT.
					if (ps.fErase)
					{
						prepareDc(ps.hdc);
						onPaintBackground(pea);
					}
					
					prepareDc(ps.hdc);
					onPaint(pea);
				}
				finally
				{
					EndPaint(msg.hWnd, &ps);
				}
				return;
			}
		
			case WM_ERASEBKGND:
				if (_controlStyle & ControlStyles.OPAQUE)
				{
					msg.result = 1; // Erased.
				}
				else if (!(_controlStyle & ControlStyles.ALL_PAINTING_IN_WM_PAINT))
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
				scope PaintEventArgs pea = new PaintEventArgs(new Graphics(cast(HDC)msg.wParam, false), Rect(Point(0, 0), _clientSize));
				onPaint(pea);
				return;
		
			case WM_CTLCOLORSTATIC:
			case WM_CTLCOLORLISTBOX:
			case WM_CTLCOLOREDIT:
			case WM_CTLCOLORSCROLLBAR:
			case WM_CTLCOLORBTN:
			//case WM_CTLCOLORDLG: // TODO: ?
			//case 0x0019: //WM_CTLCOLOR; obsolete.
			{
				Control ctrl = fromChildHandle(cast(HWND)msg.lParam);
				if (ctrl)
				{
					//ctrl.prepareDc(cast(HDC)msg.wParam);
					//msg.result = cast(LRESULT)ctrl.hbrBg;
					ctrl.onReflectedMessage(msg);
					return;
				}
				break;
			}
		
			case WM_WINDOWPOSCHANGED:
			{
				WINDOWPOS* wp = cast(WINDOWPOS*)msg.lParam;
				bool needLayout = false;
				
				//if (!wp.hwndInsertAfter)
				//	wp.flags |= SWP_NOZORDER; // TODO: ?
				
				bool didvis = false;
				if (wp.flags & (SWP_HIDEWINDOW | SWP_SHOWWINDOW))
				{
					needLayout = true; // Only if not didvis / if not recreating.
					if (!recreatingHandle) // NOTE: suppresses onVisibleChanged
					{
						if (wp.flags & SWP_HIDEWINDOW) // Hiding.
							_clicking = false;
						onVisibleChanged(EventArgs.empty);
						didvis = true;
						//break; // Showing min/max includes other flags.
					}
				}
				
				if (!(wp.flags & SWP_NOZORDER) /+ || (wp.flags & SWP_SHOWWINDOW) +/)
				{
					if (_parentWindow)
						_parentWindow.vchanged();
				}
				
				if (!(wp.flags & SWP_NOMOVE))
				{
					onMove(EventArgs.empty);
				}
				
				if (!(wp.flags & SWP_NOSIZE))
				{
					if (szdraw)
						invalidate(true);
					
					onResize(EventArgs.empty);
					
					needLayout = true;
				}
				
				// Frame change results in a new client size.
				if (wp.flags & SWP_FRAMECHANGED)
				{
					if (szdraw)
						invalidate(true);
					
					needLayout = true;
				}
				
				if (!didvis) // onVisibleChanged already triggers layout.
				{
					if (/+ (wp.flags & SWP_SHOWWINDOW) || +/ !(wp.flags & SWP_NOSIZE) ||
						!(wp.flags & SWP_NOZORDER)) // z-order determines what is positioned first.
					{
						suspendLayout(); // NOTE: exception could cause failure to restore.
						if (_parentWindow)
							_parentWindow.alayout(this);
						resumeLayout(false);
						needLayout = true;
					}
					
					if (needLayout)
					{
						alayout(this);
					}
				}
				break;
			}
		
			case WM_WINDOWPOSCHANGING:
			{
				WINDOWPOS* wp = cast(WINDOWPOS*)msg.lParam;
				
				if (!(wp.flags & SWP_NOMOVE)
					&& (location.x != wp.x || location.y != wp.y))
				{
					scope e = new MovingEventArgs(Point(wp.x, wp.y));
					onMoving(e);
					wp.x = e.x;
					wp.y = e.y;
				}
				if (!(wp.flags & SWP_NOSIZE)
					&& (width != wp.cx || height != wp.cy))
				{
					scope e = new SizingEventArgs(Size(wp.cx, wp.cy));
					onSizing(e);
					wp.cx = e.width;
					wp.cy = e.height;
				}
				break;
			}
		
			case WM_MOUSEMOVE:
				if (_clicking)
				{
					if (!(msg.wParam & MK_LBUTTON))
						_clicking = false;
				}
				
				if (trackMouseEvent) // Requires Windows 95 with IE 5.5, 98 or NT4.
				{
					if (!menter)
					{
						menter = true;
						
						POINT pt;
						GetCursorPos(&pt);
						MapWindowPoints(HWND.init, _hwnd, &pt, 1);
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
				
				onMouseMove(new MouseEventArgs(wparamMouseButtons(msg.wParam), 0, GET_X_LPARAM(msg.lParam), GET_Y_LPARAM(msg.lParam), 0));
				break;
		
			case WM_SETCURSOR:
				// Just update it so that Control.defWndProc() can set it correctly.
				if (cast(HWND)msg.wParam == _hwnd)
				{
					Cursor cur = cursor;
					if (cur)
					{
						if (cast(HCURSOR)GetClassLongPtrA(_hwnd, GCL_HCURSOR) != cur.handle)
							SetClassLongPtrA(_hwnd, GCL_HCURSOR, cast(LONG_PTR)cur.handle);
					}
					else
					{
						if (cast(HCURSOR)GetClassLongPtrA(_hwnd, GCL_HCURSOR) != HCURSOR.init)
							SetClassLongPtrA(_hwnd, GCL_HCURSOR, cast(LONG_PTR)cast(HCURSOR)null);
					}
					Control.defWndProc(msg);
					return;
				}
				break;
		
			/+
			case WM_NEXTDLGCTL:
				if (!LOWORD(msg.lParam))
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
			case WM_SYSKEYUP: // TODO: Is it correct?
			case WM_SYSCHAR:
			//case WM_IMECHAR:
				/+
				if (processKeyEventArgs(msg))
				{
					// The key was processed.
					msg.result = 0;
					return;
				}
				msg.result = 1; // The key was not processed.
				break;
				+/
				if (processKeyMessage(msg))
				{
					//msg.result = 0;
					return;
				}
				defWndProc(msg);

				//msg.result = !processKeyEventArgs(msg);
				return;
		
			case WM_MOUSEWHEEL: // Requires Windows 98 or NT4.
			{
				scope MouseEventArgs mea = new MouseEventArgs(wparamMouseButtons(LOWORD(msg.wParam)), 0, GET_X_LPARAM(msg.lParam), GET_Y_LPARAM(msg.wParam), 0);
				onMouseWheel(mea);
				break;
			}
		
			case WM_MOUSEHOVER: // Requires Windows 95 with IE 5.5, 98 or NT4.
			{
				scope MouseEventArgs mea = new MouseEventArgs(wparamMouseButtons(msg.wParam), 0, GET_X_LPARAM(msg.lParam), GET_Y_LPARAM(msg.lParam), 0);
				onMouseHover(mea);
				break;
			}
		
			case WM_MOUSELEAVE: // Requires Windows 95 with IE 5.5, 98 or NT4.
			{
				menter = false;
				
				POINT pt;
				GetCursorPos(&pt);
				MapWindowPoints(HWND.init, _hwnd, &pt, 1);
				scope MouseEventArgs mea = new MouseEventArgs(wparamMouseButtons(msg.wParam), 0, pt.x, pt.y, 0);
				onMouseLeave(mea);
				break;
			}
		
			case WM_LBUTTONDOWN:
			{
				_clicking = true;
				
				scope MouseEventArgs mea = new MouseEventArgs(MouseButtons.LEFT, 1, GET_X_LPARAM(msg.lParam), GET_Y_LPARAM(msg.lParam), 0);
				onMouseDown(mea);
				
				//if (ctrlStyle & ControlStyles.SELECTABLE)
				//	SetFocus(hwnd); // No, this goofs up stuff, including the ComboBox dropdown.
				break;
			}
		
			case WM_RBUTTONDOWN:
			{
				scope MouseEventArgs mea = new MouseEventArgs(MouseButtons.RIGHT, 1, GET_X_LPARAM(msg.lParam), GET_Y_LPARAM(msg.lParam), 0);
				onMouseDown(mea);
				break;
			}
		
			case WM_MBUTTONDOWN:
			{
				scope MouseEventArgs mea = new MouseEventArgs(MouseButtons.MIDDLE, 1, GET_X_LPARAM(msg.lParam), GET_Y_LPARAM(msg.lParam), 0);
				onMouseDown(mea);
				break;
			}
		
			case WM_LBUTTONUP:
			{
				if (msg.lParam == -1)
					break;
				
				// Use temp in case of exception.
				bool wasClicking = _clicking;
				_clicking = false;
				
				scope MouseEventArgs mea = new MouseEventArgs(MouseButtons.LEFT, 1, GET_X_LPARAM(msg.lParam), GET_Y_LPARAM(msg.lParam), 0);
				onMouseUp(mea);
				
				if (wasClicking && (_controlStyle & ControlStyles.STANDARD_CLICK))
				{
					// See if the mouse up was over the control.
					if (Rect(0, 0, _clientSize.width, _clientSize.height).contains(mea.x, mea.y))
					{
						// Now make sure there's no child in the way.
						//if (ChildWindowFromPoint(hwnd, Point(mea.x, mea.y).point) == hwnd) // Includes hidden windows.
						if (pointOverVisibleChild(Point(mea.x, mea.y)) == _hwnd)
							onClick(EventArgs.empty);
					}
				}
				break;
			}
		
			version(CUSTOM_MSG_HOOK) {} else {
				case WM_DRAWITEM:
				{
					DRAWITEMSTRUCT* dis = cast(DRAWITEMSTRUCT*)msg.lParam;
					if (dis.CtlType == ODT_MENU)
					{
						// dis.hwndItem is the HMENU.
					}
					else
					{
						Control ctrl = Control.fromChildHandle(dis.hwndItem);
						if (ctrl)
						{
							//msg.result = ctrl.customMsg(*(cast(CustomMsg*)&msg));
							ctrl.onReflectedMessage(msg);
							return;
						}
					}
					break;
				}
				
				case WM_MEASUREITEM:
				{
					MEASUREITEMSTRUCT* mis = cast(MEASUREITEMSTRUCT*)msg.lParam;
					if (!(mis.CtlType == ODT_MENU))
					{
						Control ctrl = Control.fromChildHandle(cast(HWND)mis.CtlID);
						if (ctrl)
						{
							//msg.result = ctrl.customMsg(*(cast(CustomMsg*)&msg));
							ctrl.onReflectedMessage(msg);
							return;
						}
					}
					break;
				}
				
				case WM_COMMAND:
				{
					HWND hwnd = cast(HWND)msg.lParam;
					Control ctrl = Control.fromChildHandle(hwnd);
					if (ctrl)
					{
						//msg.result = ctrl.customMsg(*(cast(CustomMsg*)&msg));
						ctrl.onReflectedMessage(msg);
						return;
					}
					else
					{
						int menuID = LOWORD(msg.wParam);
						MenuItem m = cast(MenuItem)Application.lookupMenuID(menuID);
						if (m)
						{
							//msg.result = m.customMsg(*(cast(CustomMsg*)&msg));
							m._reflectMenu(msg);
							//return; // TODO: ?
						}
						return;
					}
				}
				
				case WM_NOTIFY:
				{
					NMHDR* nmh = cast(NMHDR*)msg.lParam;
					Control ctrl = Control.fromChildHandle(nmh.hwndFrom);
					if (ctrl)
					{
						//msg.result = ctrl.customMsg(*(cast(CustomMsg*)&msg));
						ctrl.onReflectedMessage(msg);
						return;
					}
					break;
				}
				
				case WM_HSCROLL:
				case WM_VSCROLL:
				{
					HWND hWnd = cast(HWND)msg.lParam;
					Control ctrl = Control.fromChildHandle(hWnd);
					if (ctrl)
					{
						ctrl.onReflectedMessage(msg);
						return;
					}
					break;
				}

				case WM_MENUSELECT:
				{
					UINT mflags = HIWORD(msg.wParam);
					
					if (mflags & MF_SYSMENU)
						break;
					
					int mid;
					UINT uitem = LOWORD(msg.wParam); // Depends on the flags.

					if (mflags & MF_POPUP)
					{
						// -uitem- is an index.
						mid = GetMenuItemID(cast(HMENU)msg.lParam, uitem);
					}
					else
					{
						// -uitem- is the item identifier.
						mid = uitem;
					}
					
					MenuItem m = cast(MenuItem)Application.lookupMenuID(mid);
					if (m)
					{
						//msg.result = m.customMsg(*(cast(CustomMsg*)&msg));
						m._reflectMenu(msg);
						//return;
					}
					break;
				}
				
				case WM_INITMENUPOPUP:
					if (HIWORD(msg.lParam))
					{
						// System menu.
					}
					else
					{
						//MenuItem m = cast(MenuItem)Application.lookupMenuID(GetMenuItemID(cast(HMENU)msg.wParam, LOWORD(msg.lParam)));
						MenuItem m = cast(MenuItem)Application.lookupMenu(cast(HMENU)msg.wParam);
						if (m)
						{
							//msg.result = m.customMsg(*(cast(CustomMsg*)&msg));
							m._reflectMenu(msg);
							//return;
						}
					}
					break;
				
				case WM_INITMENU:
				{
					ContextMenu m = cast(ContextMenu)Application.lookupMenu(cast(HMENU)msg.wParam);
					if (m)
					{
						//msg.result = m.customMsg(*(cast(CustomMsg*)&msg));
						m._reflectMenu(msg);
						//return;
					}
					break;
				}
			}
		
			case WM_RBUTTONUP:
			{
				scope MouseEventArgs mea = new MouseEventArgs(MouseButtons.RIGHT, 1, GET_X_LPARAM(msg.lParam), GET_Y_LPARAM(msg.lParam), 0);
				onMouseUp(mea);
				break;
			}
		
			case WM_MBUTTONUP:
			{
				scope MouseEventArgs mea = new MouseEventArgs(MouseButtons.MIDDLE, 1, GET_X_LPARAM(msg.lParam), GET_Y_LPARAM(msg.lParam), 0);
				onMouseUp(mea);
				break;
			}
		
			case WM_LBUTTONDBLCLK:
			{
				scope MouseEventArgs mea = new MouseEventArgs(MouseButtons.LEFT, 2, GET_X_LPARAM(msg.lParam), GET_Y_LPARAM(msg.lParam), 0);
				onMouseDown(mea);
				
				if ((_controlStyle & (ControlStyles.STANDARD_CLICK | ControlStyles.STANDARD_DOUBLE_CLICK))
					== (ControlStyles.STANDARD_CLICK | ControlStyles.STANDARD_DOUBLE_CLICK))
				{
					onDoubleClick(EventArgs.empty);
				}
				break;
			}
		
			case WM_RBUTTONDBLCLK:
			{
				scope MouseEventArgs mea = new MouseEventArgs(MouseButtons.RIGHT, 2, GET_X_LPARAM(msg.lParam), GET_Y_LPARAM(msg.lParam), 0);
				onMouseDown(mea);
				break;
			}
			
			case WM_MBUTTONDBLCLK:
			{
				scope MouseEventArgs mea = new MouseEventArgs(MouseButtons.MIDDLE, 2, GET_X_LPARAM(msg.lParam), GET_Y_LPARAM(msg.lParam), 0);
				onMouseDown(mea);
				break;
			}
		
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
				if (msg.wParam && !LOWORD(msg.lParam))
				{
					HWND hwf;
					hwf = GetFocus();
					if (hwf)
					{
						Control hwc;
						hwc = Control.fromHandle(hwf);
						if (hwc)
						{
							if (hwc._rtype() & 0x20) // TabControl
							{
								hwf = GetWindow(hwf, GW_CHILD);
								if (hwf)
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
				if (_controlStyle & ControlStyles.CACHE_TEXT)
					_windowText = _fetchText();
				
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
					
					if (msg.wParam == GWL_EXSTYLE)
					{
						//if (changed & WS_EX_RTLREADING)
						//	onRightToLeftChanged(EventArgs.empty);
					}
				}
				break;
			+/
		
			case WM_ACTIVATE:
				switch (LOWORD(msg.wParam))
				{
					case WA_INACTIVE:
						_clicking = false;
						break;
					
					default:
				}
				break;
		
			case WM_CONTEXTMENU:
				if (_hwnd == cast(HWND)msg.wParam)
				{
					if (_contextMenu)
					{
						// Shift+F10 causes xPos and yPos to be -1.
						
						Point point;
						
						if (msg.lParam == -1)
							point = pointToScreen(Point(0, 0));
						else
							point = Point(GET_X_LPARAM(msg.lParam), GET_Y_LPARAM(msg.lParam));
						
						SetFocus(handle); // TODO: ?
						_contextMenu.show(this, point);
						
						return;
					}
				}
				break;
		
			case WM_HELP:
			{
				HELPINFO* hi = cast(HELPINFO*)msg.lParam;
				
				scope HelpEventArgs hea = new HelpEventArgs(Point(hi.MousePos.x, hi.MousePos.y));
				onHelpRequested(hea);
				if (hea.handled)
				{
					msg.result = TRUE;
					return;
				}
				break;
			}
		
			case WM_SYSCOLORCHANGE:
				onSystemColorsChanged(EventArgs.empty);
				
				// Need to send the message to children for some common controls to update properly.
				foreach (Control ctrl; controls)
				{
					SendMessageA(ctrl.handle, WM_SYSCOLORCHANGE, msg.wParam, msg.lParam);
				}
				break;
			
			case WM_SETTINGCHANGE:
				// Send the message to children.
				foreach (Control ctrl; controls)
				{
					SendMessageA(ctrl.handle, WM_SETTINGCHANGE, msg.wParam, msg.lParam);
				}
				break;
			
			case WM_PALETTECHANGED:
				/+
				if (cast(HWND)msg.wParam != hwnd)
				{
					// Realize palette.
				}
				+/
				
				// Send the message to children.
				foreach (Control ctrl; controls)
				{
					SendMessageA(ctrl.handle, WM_PALETTECHANGED, msg.wParam, msg.lParam);
				}
				break;
		
			//case WM_QUERYNEWPALETTE: // Send this message to children ?
		
			/+
			// Moved this stuff to -parent-.
			case WM_PARENTNOTIFY:
				switch (LOWORD(msg.wParam))
				{
					case WM_DESTROY:
						Control ctrl = fromChildHandle(cast(HWND)msg.lParam);
						if (ctrl)
						{
							_ctrlremoved(new ControlEventArgs(ctrl));
							
							// TODO: ?
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
				if (wparent)
					initLayout(); // TODO: ?
				+/
				if (_cbits & CBits.NEED_INIT_LAYOUT)
				{
					if (visible)
					{
						if (_parentWindow)
						{
							_parentWindow.vchanged();
							suspendLayout(); // NOTE: exception could cause failure to restore.
							_parentWindow.alayout(this);
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
					if (ctrlStyle & ControlStyles.CONTAINER_CONTROL)
					{
						if (!(_exStyle & WS_EX_CONTROLPARENT))
							assert(0);
					}
					+/
					
					DWORD dw = GetTickCount();
					if (ldlgcode < dw - 1020)
					{
						ldlgcode = dw - 1000;
					}
					else
					{
						ldlgcode += 50;
						if (ldlgcode > dw)
						{
							// Probably a problem with WS_EX_CONTROLPARENT and WS_TABSTOP.
							if (ldlgcode >= ldlgcode.max - 10_000)
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
				if (msg.lParam)
				{
					Message m;
					m._winMsg = *cast(MSG*)msg.lParam;
					if (processKeyEventArgs(m))
						return;
				}
				+/
				
				defWndProc(msg);
				
				// Only want chars if ALT isn't down, because it would break mnemonics.
				if (!(GetKeyState(VK_MENU) & 0x8000))
					msg.result |= DLGC_WANTCHARS;
				
				return;
			}
		
			case WM_CLOSE:
				/+{
					if (parent)
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
			{
				//defWndProc(msg);
				version(DFL_NO_WM_GETCONTROLNAME) {} else
				{
					if (msg.msg == wmGetControlName)
					{
						//cprintf("WM_GETCONTROLNAME: %.*s; wparam: %d\n", cast(uint)name.length, name.ptr, msg.wParam);
						if (msg.wParam && this.name.length)
						{
							OSVERSIONINFOA osver;
							osver.dwOSVersionInfoSize = OSVERSIONINFOA.sizeof;
							if (GetVersionExA(&osver))
							{
								try
								{
									if (osver.dwPlatformId <= VER_PLATFORM_WIN32_WINDOWS)
									{
										if (dfl.internal.utf.useUnicode)
										{
										}
										else
										{
											// ANSI.
											Dstring ansi = dfl.internal.utf.toAnsi(this.name);
											if (msg.wParam <= ansi.length)
												ansi = ansi[0 .. msg.wParam - 1];
											(cast(char*)msg.lParam)[0 .. ansi.length] = ansi[];
											(cast(char*)msg.lParam)[ansi.length] = 0;
											msg.result = ansi.length + 1;
										}
									}
									else
									{
										// Unicode.
										Dwstring uni = dfl.internal.utf.toUnicode(this.name);
										if (msg.wParam <= uni.length)
											uni = uni[0 .. msg.wParam - 1];
										(cast(wchar*)msg.lParam)[0 .. uni.length] = uni[];
										(cast(wchar*)msg.lParam)[uni.length] = 0;
										msg.result = uni.length + 1;
									}
								}
								catch(Exception)
								{
								}
								return;
							}
						}
					}
				}
			}
		}
		
		defWndProc(msg);
		
		if (msg.msg == WM_CREATE)
		{
			EventArgs ea = EventArgs.empty;
			onHandleCreated(ea);
			
			debug
			{
				assert(_handlecreated, "If overriding onHandleCreated(), be sure to call super.onHandleCreated() first!");
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
		
		//if (cvalidation)
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
		//wparent = null; // TODO: ?
	}
	
	
	// This function must be called FIRST for EVERY message to this
	// window in order to keep the correct window state.
	// This function must not throw exceptions.
	package final void mustWndProc(ref Message msg)
	{
		if (needCalcSize)
		{
			needCalcSize = false;
			_windowRect = _fetchBounds();
			_clientSize = _fetchClientSize();
		}
		
		switch (msg.msg)
		{
			case WM_NCCALCSIZE:
				needCalcSize = true;
				break;
		
			case WM_WINDOWPOSCHANGED:
			{
				WINDOWPOS* wp = cast(WINDOWPOS*)msg.lParam;
				
				if (!recreatingHandle)
				{
					//wstyle = GetWindowLongPtrA(hwnd, GWL_STYLE); // ..WM_SHOWWINDOW.
					if (wp.flags & (SWP_HIDEWINDOW | SWP_SHOWWINDOW))
					{
						//wstyle = GetWindowLongPtrA(hwnd, GWL_STYLE);
						_cbits |= CBits.VISIBLE;
						_windowStyle |= WS_VISIBLE;
						if (wp.flags & SWP_HIDEWINDOW) // Hiding.
						{
							_cbits &= ~CBits.VISIBLE;
							_windowStyle &= ~WS_VISIBLE;
						}
						//break; // Showing min/max includes other flags.
					}
				}
				
				if (!(wp.flags & SWP_NOSIZE) || !(wp.flags & SWP_NOMOVE) || (wp.flags & SWP_FRAMECHANGED))
				{
					_windowRect = Rect(
						MulDiv(wp.x, USER_DEFAULT_SCREEN_DPI, _windowDpi),
						MulDiv(wp.y, USER_DEFAULT_SCREEN_DPI, _windowDpi),
						MulDiv(wp.cx, USER_DEFAULT_SCREEN_DPI, _windowDpi),
						MulDiv(wp.cy, USER_DEFAULT_SCREEN_DPI, _windowDpi));

					_clientSize = _fetchClientSize();
				}
				
				if ((wp.flags & (SWP_SHOWWINDOW | SWP_HIDEWINDOW)) || !(wp.flags & SWP_NOSIZE))
				{
					DWORD rstyle = GetWindowLongPtrA(msg.hWnd, GWL_STYLE).toI32;
					rstyle &= WS_MAXIMIZE | WS_MINIMIZE;
					_windowStyle &= ~(WS_MAXIMIZE | WS_MINIMIZE);
					_windowStyle |= rstyle;
				}
				break;
			}
		
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
				
				if (msg.wParam == GWL_STYLE)
					_windowStyle = ss.styleNew;
				else if (msg.wParam == GWL_EXSTYLE)
					_windowStyleEx = ss.styleNew;
				
				/+
				wrect = _fetchBounds();
				wclientsz = _fetchClientSize();
				+/
				break;
			}
		
			/+
			// NOTE: this is sent even if the parent is shown.
			case WM_SHOWWINDOW:
				if (!msg.lParam)
				{
					/+
					{
						cbits &= ~(CBits.SW_SHOWN | CBits.SW_HIDDEN);
						DWORD rstyle;
						rstyle = GetWindowLongPtrA(msg.hWnd, GWL_STYLE);
						if (cast(BOOL)msg.wParam)
						{
							//wstyle |= WS_VISIBLE;
							if (!(WS_VISIBLE & wstyle) && (WS_VISIBLE & rstyle))
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
							if ((WS_VISIBLE & wstyle) && !(WS_VISIBLE & rstyle))
							{
								wstyle = rstyle;
								cbits |= CBits.SW_HIDDEN;
							}
							wstyle = rstyle;
						}
					}
					+/
					wstyle = GetWindowLongPtrA(msg.hWnd, GWL_STYLE);
					//if (cbits & CBits.FVISIBLE)
					//	wstyle |= WS_VISIBLE;
				}
				break;
			+/
		
			case WM_ENABLE:
				/+
				//if (IsWindowEnabled(hwnd))
				if (cast(BOOL)msg.wParam)
					wstyle &= ~WS_DISABLED;
				else
					wstyle |= WS_DISABLED;
				+/
				_windowStyle = GetWindowLongPtrA(_hwnd, GWL_STYLE).toI32;
				break;
		
			/+
			case WM_PARENTNOTIFY:
				switch (LOWORD(msg.wParam))
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
				// hwnd = msg.hWnd;
				// CREATESTRUCTA* cs = cast(CREATESTRUCTA*)msg.lParam;
				
				// Not using CREATESTRUCT for window bounds because it can contain
				// CW_USEDEFAULT and other magic values.
				
				// _windowRect = Rect(cs.x, cs.y, cs.cx, cs.cy);
				_windowRect = _fetchBounds();
				
				//oldwrect = wrect;
				_clientSize = _fetchClientSize();
				break;
			}
		
			case WM_CREATE:
				try
				{
					_cbits |= CBits.CREATED;
					
					//hwnd = msg.hWnd;
					
					CREATESTRUCTA* cs = cast(CREATESTRUCTA*)msg.lParam;
					/+
					// Done in WM_NCCREATE now.
					//wrect = _fetchBounds();
					wrect = Rect(cs.x, cs.y, cs.cx, cs.cy);
					wclientsz = _fetchClientSize();
					+/
					
					// If class style was changed, update.
					if (_fetchClassLongPtr() != _windowClassStyle)
						SetClassLongPtrA(_hwnd, GCL_STYLE, _windowClassStyle);
					
					// Need to update clientSize in case of styles in createParams().
					_clientSize = _fetchClientSize();
					
					//finishCreating(msg.hWnd);
					
					if (!(_controlStyle & ControlStyles.CACHE_TEXT))
						_windowText = null;
					
					/+
					// Gets created on demand instead.
					if (Color.empty != backc)
					{
						hbrBg = backc.createBrush();
					}
					+/
					
					/+
					// TODO: ?
					wstyle = cs.style;
					wexstyle = cs.dwExStyle;
					+/
					
					createChildren(); // Might throw. Used to be commented-out.
					
					if (recreatingHandle)
					{
						// After existing messages and functions are done.
						delayInvoke(function(Control cthis, size_t[] params){ cthis._cbits &= ~CBits.RECREATING; });
					}
				}
				catch(DThrowable e)
				{
					Application.onThreadException(e);
				}
				break;
		
			case WM_DESTROY:
				_cbits &= ~CBits.CREATED;
				if (!recreatingHandle)
					_cbits &= ~CBits.FORMLOADED;
				_destroying();
				//if (!killing)
				if (recreatingHandle)
					fillRecreationData();
				break;
		
			case WM_NCDESTROY:
				Application.removeHwnd(_hwnd);
				_hwnd = HWND.init;
				break;
		
			default:
				/+
				if (msg.msg == wmDfl)
				{
					switch (msg.wParam)
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
		if (_parentWindow) // Exclude owner.
		{
			SetWindowPos(_hwnd, HWND.init, 0, 0, 0, 0, SWP_NOSIZE | SWP_NOMOVE | SWP_SHOWWINDOW | SWP_NOACTIVATE | SWP_NOZORDER);
		}
		else
		{
			SetWindowPos(_hwnd, HWND_TOP, 0, 0, 0, 0, SWP_NOSIZE | SWP_NOMOVE | SWP_SHOWWINDOW);
		}
	}
	
	
	package final void doHide()
	{
		SetWindowPos(_hwnd, HWND.init, 0, 0, 0, 0, SWP_NOSIZE | SWP_NOMOVE | SWP_NOACTIVATE | SWP_HIDEWINDOW | SWP_NOZORDER);
	}
	
	
	Event!(Control, EventArgs) backColorChanged; ///
	// Event!(Control, EventArgs) backgroundImageChanged;
	/+
	deprecated Event!(Control, EventArgs) causesValidationChanged;
	deprecated Event!(Control, InvalidateEventArgs) invalidated;
	deprecated Event!(Control, EventArgs) validated;
	deprecated Event!(Control, CancelEventArgs) validating; // Once cancel is true, remaining events are suppressed (including validated).
	deprecated Event!(Control, EventArgs) enter; // Cascades up. TODO: fix implementation.
	deprecated Event!(Control, EventArgs) leave; // Cascades down. TODO: fix implementation.
	deprecated Event!(Control, UICuesEventArgs) changeUICues; // TODO: properly fire.
	+/
	Event!(Control, EventArgs) click; ///
	Event!(Control, EventArgs) contextMenuChanged; ///
	Event!(Control, ControlEventArgs) controlAdded; ///
	Event!(Control, ControlEventArgs) controlRemoved; ///
	Event!(Control, EventArgs) cursorChanged; ///
	Event!(Control, EventArgs) disposed; ///
	Event!(Control, EventArgs) hasLayoutChanged; ///
	alias dockChanged = hasLayoutChanged;
	Event!(Control, EventArgs) doubleClick; ///
	Event!(Control, EventArgs) enabledChanged; ///
	Event!(Control, EventArgs) fontChanged; ///
	Event!(Control, EventArgs) foreColorChanged; ///
	Event!(Control, EventArgs) gotFocus; ///
	Event!(Control, EventArgs) handleCreated; ///
	Event!(Control, EventArgs) handleDestroyed; ///
	Event!(Control, HelpEventArgs) helpRequested; ///
	Event!(Control, KeyEventArgs) keyDown; ///
	Event!(Control, KeyPressEventArgs) keyPress; ///
	Event!(Control, KeyEventArgs) keyUp; ///
	Event!(Control, LayoutEventArgs) layout; ///
	Event!(Control, EventArgs) lostFocus; ///
	Event!(Control, MouseEventArgs) mouseDown; ///
	Event!(Control, MouseEventArgs) mouseEnter; ///
	Event!(Control, MouseEventArgs) mouseHover; ///
	Event!(Control, MouseEventArgs) mouseLeave; ///
	Event!(Control, MouseEventArgs) mouseMove; ///
	Event!(Control, MouseEventArgs) mouseUp; ///
	Event!(Control, MouseEventArgs) mouseWheel; ///
	Event!(Control, MovingEventArgs) moving; ///
	Event!(Control, EventArgs) move; ///
	alias locationChanged = move;
	Event!(Control, PaintEventArgs) paint; ///
	Event!(Control, EventArgs) parentChanged; ///
	Event!(Control, SizingEventArgs) sizing; ///
	Event!(Control, EventArgs) resize; ///
	alias sizeChanged = resize;
	Event!(Control, EventArgs) rightToLeftChanged; ///
	// Event!(Control, EventArgs) styleChanged;
	Event!(Control, EventArgs) systemColorsChanged; ///
	// Event!(Control, EventArgs) tabIndexChanged;
	// Event!(Control, EventArgs) tabStopChanged;
	Event!(Control, EventArgs) textChanged; ///
	Event!(Control, EventArgs) visibleChanged; ///
	
	version(DFL_NO_DRAG_DROP) {} else
	{
		Event!(Control, DragEventArgs) dragDrop; ///
		Event!(Control, DragEventArgs) dragEnter; ///
		Event!(Control, EventArgs) dragLeave; ///
		Event!(Control, DragEventArgs) dragOver; ///
		Event!(Control, GiveFeedbackEventArgs) giveFeedback; ///
		Event!(Control, QueryContinueDragEventArgs) queryContinueDrag; ///
	}
	
	
	/// Construct a new Control instance.
	this()
	{
		_windowRect.size = defaultSize;
		_backColor = Color.empty;
		_foreColor = Color.empty;
		_windowFont = null;
		_windowCursor = null;
		_dockPadding = new DockPaddingEdges;
		_dockMargin = new DockMarginEdges;
	}
	
	/// ditto
	this(Dstring text)
	{
		this();
		_windowText = text;
	}
	
	/// ditto
	this(Control cparent, Dstring text)
	{
		this();
		_windowText = text;
		parent = cparent;
	}
	
	/// ditto
	this(Dstring text, int left, int top, int width, int height)
	{
		this();
		_windowText = text;
		_windowRect = Rect(left, top, width, height);
	}
	
	/// ditto
	this(Control cparent, Dstring text, int left, int top, int width, int height)
	{
		this();
		_windowText = text;
		_windowRect = Rect(left, top, width, height);
		parent = cparent;
	}
	
	
	/+
	// Used internally.
	this(HWND hwnd)
	in
	{
		assert(hwnd);
	}
	do
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
		if (disposing)
		{
			killing = true;
			
			_contextMenu = _contextMenu.init;
			_controlName = _controlName.init;
			_objectTag = _objectTag.init;
			_windowCursor = _windowCursor.init;
			_windowFont = _windowFont.init;
			_parentWindow = _parentWindow.init;
			_windowRegion = _windowRegion.init;
			_windowText = _windowText.init;
			deleteThisBackgroundBrush();
			//controls.children = null; // Not GC-safe in dtor.
			//controls = null; // Causes bad things. Leaving it will do just fine.
		}
		
		if (!isHandleCreated)
			return;
		
		destroyHandle();
		/+
		//assert(hwnd == HWND.init); // Zombie trips this. (Not anymore with the hwnd-prop)
		if (hwnd)
		{
			assert(!IsWindow(hwnd));
			hwnd = HWND.init;
		}
		+/
		assert(_hwnd == HWND.init);
		
		onDisposed(EventArgs.empty);
	}
	
	
protected:
	
	///
	@property Size defaultSize() const // getter
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
	public final @property void resizeRedraw(bool byes) // setter
	{
		/+
		// These class styles get lost sometimes so don't rely on them.
		LONG cl = _classStyle();
		if (byes)
			cl |= CS_HREDRAW | CS_VREDRAW;
		else
			cl &= ~(CS_HREDRAW | CS_VREDRAW);
		
		_classStyle(cl);
		+/
		szdraw = byes;
	}
	
	/// ditto
	public final @property bool resizeRedraw() const // getter
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
		if (huxtheme)
		{
			auto getwintheme = cast(typeof(&GetWindowTheme))GetProcAddress(huxtheme, "GetWindowTheme");
			if (getwintheme)
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
		
		HMODULE hmuxt = GetModuleHandleA("uxtheme.dll");
		if (hmuxt)
		{
			auto setWinTheme = cast(typeof(&SetWindowTheme))GetProcAddress(hmuxt, "SetWindowTheme");
			if (setWinTheme)
			{
				setWinTheme(_hwnd, " "w.ptr, " "w.ptr); // Clear the theme.
			}
		}
	}
	
	
	///
	public final void disableVisualStyle(bool byes = true)
	{
		if (!byes)
		{
			if (_cbits & CBits.VSTYLE)
				return;
			_cbits |= CBits.VSTYLE;
			
			if (isHandleCreated)
			{
				_crecreate();
			}
		}
		else
		{
			if (!(_cbits & CBits.VSTYLE))
				return;
			_cbits &= ~CBits.VSTYLE;
			
			if (isHandleCreated)
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
	
	
	///
	// Override to change the creation parameters.
	// Be sure to call super.createParams() or all the create params will need to be filled.
	void createParams(ref CreateParams cp)
	{
		cp.className = CONTROL_CLASSNAME;
		cp.caption = _windowText;
		cp.param = null;
		cp.parent = _parentWindow ? _parentWindow.handle : HWND.init;
		cp.menu = HMENU.init;
		cp.inst = Application.getInstance();
		
		_windowDpi = {
			if (parent && parent.isHandleCreated)
			{
				return GetDpiForWindow(parent.handle);
			}
			else
			{
				HWND hwndForeGound = GetForegroundWindow();
				HMONITOR hMon = MonitorFromWindow(hwndForeGound, MONITOR_DEFAULTTONEAREST);
				UINT dpix_, dpiy_;
				GetDpiForMonitor(hMon, MONITOR_DPI_TYPE.MDT_EFFECTIVE_DPI, &dpix_, &dpiy_);
				return dpix_;
			}
		}();

		cp.x = MulDiv(_windowRect.x, _windowDpi, USER_DEFAULT_SCREEN_DPI);
		cp.y = MulDiv(_windowRect.y, _windowDpi, USER_DEFAULT_SCREEN_DPI);
		cp.width = MulDiv(_windowRect.width, _windowDpi, USER_DEFAULT_SCREEN_DPI);
		cp.height = MulDiv(_windowRect.height, _windowDpi, USER_DEFAULT_SCREEN_DPI);

		cp.classStyle = _windowClassStyle;
		cp.exStyle = _windowStyleEx;

		_windowStyle |= WS_VISIBLE;
		if (!(_cbits & CBits.VISIBLE))
			_windowStyle &= ~WS_VISIBLE;

		cp.style = _windowStyle;
	}
	
	
	///
	void createHandle()
	{
		// NOTE: if modified, Form.createHandle() should be modified as well.
		
		if (isHandleCreated)
			return;
		
		debug
		{
			Dstring er;
		}
		if (killing)
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
			if (name.length)
				kmsg ~= " (" ~ name ~ ")";
			debug
			{
				if (er.length)
					kmsg ~= " - " ~ er;
			}
			throw new DflException(kmsg);
		}
		
		// Need the parent's handle to exist.
		if (_parentWindow)
			_parentWindow.createHandle();
		
		// This is here because wparent.createHandle() might create me.
		if (isHandleCreated)
			return;
		
		CreateParams cp;
		
		// NOTE: After calling createParams(),
		//       cp.x, cp.y, cp.width, and cp.height may no longer represent coordinates.
		//       See document of createWindowEx().
		createParams(cp);
		assert(!isHandleCreated); // Make sure the handle wasn't created in createParams().

		_windowText = cp.caption;
		//_windowRect = Rect(cp.x, cp.y, cp.width, cp.height); // This gets updated in WM_CREATE.
		_windowClassStyle = cp.classStyle;
		_windowStyleEx = cp.exStyle;
		_windowStyle = cp.style;
		
		//if (cp.style & WS_CHILD) // Breaks context-help.
		if ((_controlStyle & ControlStyles.CONTAINER_CONTROL) && (cp.style & WS_CHILD))
		{
			cp.exStyle |= WS_EX_CONTROLPARENT;
		}
		
		bool vis = (cp.style & WS_VISIBLE) != 0;

		Application.creatingControl(this);
		_hwnd = dfl.internal.utf.createWindowEx(cp.exStyle, cp.className, cp.caption, (cp.style & ~WS_VISIBLE), cp.x, cp.y,
			cp.width, cp.height, cp.parent, cp.menu, cp.inst, cp.param);
		if (!_hwnd)
		{
			debug(APP_PRINT)
			{
				cprintf("CreateWindowEx failed." ~
						" (exStyle=0x%X, className=`%.*s`, caption=`%.*s`, style=0x%X, x=%d, y=%d, width=%d, height=%d," ~
						" parent=0x%X, menu=0x%X, inst=0x%X, param=0x%X)\n",
						cp.exStyle, cp.className.length.toI32, cp.className.ptr, cp.caption.length.toI32, cp.caption.ptr, cp.style, cp.x, cp.y, cp.width, cp.height,
						cast(uint)cp.parent, cast(uint)cp.menu, cast(uint)cp.inst, cast(uint)cp.param);
			}
			
			debug
			{
				er = std.string.format("CreateWindowEx failed {className=%s;exStyle=0x%X;style=0x%X;parent=0x%X;menu=0x%X;inst=0x%X;}",
					cp.className, cp.exStyle, cp.style, cast(void*)cp.parent, cast(void*)cp.menu, cast(void*)cp.inst);
			}
			
			goto create_err;
		}
		
		if (vis)
			doShow(); // Properly fires onVisibleChanged.
		
		//onHandleCreated(EventArgs.empty); // Called in WM_CREATE now.
	}
	
	
	package final void _createHandle()
	{
		createHandle();
	}
	
	
	///
	public final @property bool recreatingHandle() const // getter
	{
		if (_cbits & CBits.RECREATING)
			return true;
		return false;
	}
	
	
	private void _setAllRecreating()
	{
		_cbits |= CBits.RECREATING;
		foreach (Control cc; controls)
		{
			cc._setAllRecreating();
		}
	}
	
	
	///
	void recreateHandle()
	in
	{
		assert(!recreatingHandle);
	}
	do
	{
		if (!isHandleCreated)
			return;
		
		if (recreatingHandle)
			return;
		
		bool hfocus = focused;
		HWND prevHwnd = GetWindow(_hwnd, GW_HWNDPREV);
		
		_setAllRecreating();
		//scope (exit)
		//	cbits &= ~CBits.RECREATING; // Now done from WM_CREATE.
		
		destroyHandle();
		createHandle();
		
		if (prevHwnd)
			SetWindowPos(_hwnd, prevHwnd, 0, 0, 0, 0, SWP_NOSIZE | SWP_NOMOVE | SWP_NOACTIVATE);
		else
			SetWindowPos(_hwnd, HWND_TOPMOST, 0, 0, 0, 0, SWP_NOSIZE | SWP_NOMOVE | SWP_NOACTIVATE);
		if (hfocus)
			select();
	}
	
	
	///
	void destroyHandle()
	{
		if (!isHandleCreated)
			return;
		
		DestroyWindow(_hwnd);
		
		// This stuff is done in WM_DESTROY because DestroyWindow() could be called elsewhere..
		//hwnd = HWND.init; // Done in WM_DESTROY.
		//onHandleDestroyed(EventArgs.empty); // Done in WM_DESTROY.
	}
	
	
	private void fillRecreationData()
	{
		//cprintf(" { fillRecreationData %.*s }\n", name);
		
		if (!(_controlStyle & ControlStyles.CACHE_TEXT))
			_windowText = _fetchText();
		
		//wclassStyle = _fetchClassLongPtr(); // TODO: ?
		
		// Fetch children.
		Control[] ccs;
		foreach (Control cc; controls)
		{
			ccs ~= cc;
		}
		controls._children = ccs;
	}
	
	
	///
	void onDisposed(EventArgs ea)
	{
		disposed(this, ea);
	}
	
	
	///
	final bool getStyle(ControlStyles flag) const
	{
		return (_controlStyle & flag) != 0;
	}
	
	/// ditto
	final void setStyle(ControlStyles flag, bool value)
	{
		if (flag & ControlStyles.CACHE_TEXT)
		{
			if (value)
				_windowText = _fetchText();
			else
				_windowText = null;
		}
		
		if (value)
			_controlStyle |= flag;
		else
			_controlStyle &= ~flag;
	}
	
	
	///
	// Only for setStyle() styles that are part of hwnd and wndclass styles.
	final void updateStyles()
	{
		LONG newClassStyles = _classStyle();
		LONG newWndStyles = _style();
		
		if (_controlStyle & ControlStyles.STANDARD_DOUBLE_CLICK)
			newClassStyles |= CS_DBLCLKS;
		else
			newClassStyles &= ~CS_DBLCLKS;
		
		/+
		if (ctrlStyle & ControlStyles.RESIZE_REDRAW)
			newClassStyles |= CS_HREDRAW | CS_VREDRAW;
		else
			newClassStyles &= ~(CS_HREDRAW | CS_VREDRAW);
		+/
		
		/+
		if (ctrlStyle & ControlStyles.SELECTABLE)
			newWndStyles |= WS_TABSTOP;
		else
			newWndStyles &= ~WS_TABSTOP;
		+/
		
		_classStyle(newClassStyles);
		_style(newWndStyles);
	}
	
	
	///
	final bool getTopLevel() const
	{
		// return GetParent(hwnd) == HWND.init;
		return _parentWindow is null;
	}
	
	
	package final void alayout(Control ctrl, bool vcheck = true)
	{
		if (vcheck && !visible)
			return;
		
		if (_cbits & CBits.IN_LAYOUT)
			return;
		
		//if (_allowLayout)
		if (!_disallowLayout)
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
		//if (!isHandleCreated || !visible)
		//	return;
		
		version(RADIO_GROUP_LAYOUT)
		{
			//cprintf("vchanged\n");
			
			bool foundRadio = false;
			
			foreach (Control ctrl; controls)
			{
				if (!ctrl.visible)
					continue;
				
				if (ctrl._rtype() & 1) // Radio type.
				{
					LONG wlg = ctrl._style();
					if (foundRadio)
					{
						if (wlg & WS_GROUP)
							//ctrl._style(wlg & ~WS_GROUP);
							ctrl._style(wlg & ~(WS_GROUP | WS_TABSTOP));
					}
					else
					{
						foundRadio = true;
						
						if (!(wlg & WS_GROUP))
							//ctrl._style(wlg | WS_GROUP);
							ctrl._style(wlg | WS_GROUP | WS_TABSTOP);
					}
				}
				else
				{
					// Found non-radio so reset group.
					// Update: only reset group if found ctrl with WS_EX_CONTROLPARENT.
					// TODO: check if correct implementation.
					if (ctrl._exStyle() & WS_EX_CONTROLPARENT)
						foundRadio = false;
				}
			}
		}
	}
	

	///
	void locationAlignment(LocationAlignment alignment) // setter
	{
		_locationAlignment = alignment;
		_dockStyle = DockStyle.NONE; // Can't be set at the same time.
	}

	/// ditto
	LocationAlignment locationAlignment() const // getter
	{
		return _locationAlignment;
	}


	///
	// Called after adding the control to a container.
	void initLayout()
	{
		assert(_parentWindow !is null);
		if (visible && created) // TODO: ?
		{
			_parentWindow.vchanged();
			_parentWindow.alayout(this);
		}
	}
	
	
	///
	void onLayout(LayoutEventArgs lea)
	{
		// NOTE: exception could cause failure to restore.
		//suspendLayout();
		_cbits |= CBits.IN_LAYOUT;
		
		debug(EVENT_PRINT)
		{
			cprintf("{ Event: onLayout - Control %.*s }\n", name);
		}
		
		Rect area = displayRectangle; // area is padding-adjusted already.
		
		foreach (Control ctrl; controls)
		{
			if (!ctrl.visible || !ctrl.created)
				continue;
			if (ctrl._rtype() & (2 | 4)) // Mdichild | Tabpage
				continue;
			
			if (ctrl.locationAlignment != LocationAlignment.NONE)
			{
				Rect ctrlbounds = ctrl.bounds;

				if (ctrl.locationAlignment == LocationAlignment.TOP_LEFT
					|| ctrl.locationAlignment == LocationAlignment.TOP_CENTER
					|| ctrl.locationAlignment == LocationAlignment.TOP_RIGHT)
				{
					ctrlbounds.y = area.y + ctrl.dockMargin.top;
				}

				if (ctrl.locationAlignment == LocationAlignment.MIDDLE_LEFT
					|| ctrl.locationAlignment == LocationAlignment.MIDDLE_CENTER
					|| ctrl.locationAlignment == LocationAlignment.MIDDLE_RIGHT)
				{
					ctrlbounds.y = area.y + (area.height - ctrl.height) / 2;
				}

				if (ctrl.locationAlignment == LocationAlignment.BOTTOM_LEFT
					|| ctrl.locationAlignment == LocationAlignment.BOTTOM_CENTER
					|| ctrl.locationAlignment == LocationAlignment.BOTTOM_RIGHT)
				{
					ctrlbounds.y = area.bottom - ctrl.height - ctrl.dockMargin.bottom;
				}

				if (ctrl.locationAlignment == LocationAlignment.TOP_LEFT
					|| ctrl.locationAlignment == LocationAlignment.MIDDLE_LEFT
					|| ctrl.locationAlignment == LocationAlignment.BOTTOM_LEFT)
				{
					ctrlbounds.x = area.x + ctrl.dockMargin.left;
				}

				if (ctrl.locationAlignment == LocationAlignment.TOP_RIGHT
					|| ctrl.locationAlignment == LocationAlignment.MIDDLE_RIGHT
					|| ctrl.locationAlignment == LocationAlignment.BOTTOM_RIGHT)
				{
					ctrlbounds.x = area.right - ctrl.width - ctrl.dockMargin.right;
				}

				if (ctrl.locationAlignment == LocationAlignment.TOP_CENTER
					|| ctrl.locationAlignment == LocationAlignment.MIDDLE_CENTER
					|| ctrl.locationAlignment == LocationAlignment.BOTTOM_CENTER)
				{
					ctrlbounds.x = area.x + (area.width - ctrl.width) / 2;
				}

				ctrl.setBoundsCore(ctrlbounds.x, ctrlbounds.y, ctrlbounds.width, ctrlbounds.height, cast(BoundsSpecified)BoundsSpecified.LOCATION);
				continue;
			}

			//Rect prevctrlbounds;
			//prevctrlbounds = ctrl.bounds;
			//ctrl.suspendLayout(); // NOTE: exception could cause failure to restore.
			final switch (ctrl._dockStyle)
			{
				case DockStyle.NONE:
					/+
					if (ctrl.anch & (AnchorStyles.RIGHT | AnchorStyles.BOTTOM)) // If none of these are set, no point in doing any anchor code.
					{
						Rect newb;
						newb = ctrl.bounds;
						if (ctrl.anch & AnchorStyles.RIGHT)
						{
							if (ctrl.anch & AnchorStyles.LEFT)
								newb.width += bounds.width - originalBounds.width;
							else
								newb.x += bounds.width - originalBounds.width;
						}
						if (ctrl.anch & AnchorStyles.BOTTOM)
						{
							if (ctrl.anch & AnchorStyles.LEFT)
								newb.height += bounds.height - originalBounds.height;
							else
								newb.y += bounds.height - originalBounds.height;
						}
						if (newb != ctrl.bounds)
							ctrl.bounds = newb;
					}
					+/
					break;
				
				case DockStyle.LEFT:
					Rect ctrlbounds;
					ctrlbounds.x = area.x + ctrl.dockMargin.left;
					ctrlbounds.y = area.y + ctrl.dockMargin.top;
					// ctrlbounds.width = 0;
					ctrlbounds.height = area.height - ctrl.dockMargin.top - ctrl.dockMargin.bottom;
					ctrl.setBoundsCore(ctrlbounds.x, ctrlbounds.y, ctrlbounds.width, ctrlbounds.height, cast(BoundsSpecified)(BoundsSpecified.LOCATION | BoundsSpecified.HEIGHT));
					
					area.x = area.x + ctrl.width + ctrl.dockMargin.left + ctrl.dockMargin.right;
					area.width = area.width - ctrl.width - ctrl.dockMargin.left - ctrl.dockMargin.right;
					break;
				
				case DockStyle.RIGHT:
					Rect ctrlbounds;
					ctrlbounds.x = area.width - ctrl.width - ctrl.dockMargin.right;
					ctrlbounds.y = area.y + ctrl.dockMargin.top;
					// ctrlbounds.width = 0;
					ctrlbounds.height = area.height - ctrl.dockMargin.top - ctrl.dockMargin.bottom;
					ctrl.setBoundsCore(ctrlbounds.x, ctrlbounds.y, ctrlbounds.width, ctrlbounds.height, cast(BoundsSpecified)(BoundsSpecified.LOCATION | BoundsSpecified.HEIGHT));

					area.width = area.width - ctrl.width - ctrl.dockMargin.left - ctrl.dockMargin.right;
					break;
				
				case DockStyle.TOP:
					Rect ctrlbounds;
					ctrlbounds.x = area.x + ctrl.dockMargin.left;
					ctrlbounds.y = area.y + ctrl.dockMargin.top;
					ctrlbounds.width = area.width - ctrl.dockMargin.left - ctrl.dockMargin.right;
					// ctrlbounds.height = 0;
					ctrl.setBoundsCore(ctrlbounds.x, ctrlbounds.y, ctrlbounds.width, ctrlbounds.height, cast(BoundsSpecified)(BoundsSpecified.LOCATION | BoundsSpecified.WIDTH));
					
					area.y = area.y + ctrl.height + ctrl.dockMargin.top + ctrl.dockMargin.bottom;
					area.height = area.height - ctrl.height - ctrl.dockMargin.top - ctrl.dockMargin.bottom;
					break;
				
				case DockStyle.BOTTOM:
					Rect ctrlbounds;
					ctrlbounds.x = area.x + ctrl.dockMargin.left;
					ctrlbounds.y = area.bottom - ctrl.height - ctrl.dockMargin.bottom;
					ctrlbounds.width = area.width - ctrl.dockMargin.left - ctrl.dockMargin.right;
					// ctrlbounds.height = 0;
					ctrl.setBoundsCore(ctrlbounds.x, ctrlbounds.y, ctrlbounds.width, ctrlbounds.height, cast(BoundsSpecified)(BoundsSpecified.LOCATION | BoundsSpecified.WIDTH));

					area.height = area.height - ctrl.height - ctrl.dockMargin.top - ctrl.dockMargin.bottom;
					break;
				
				case DockStyle.FILL:
					area.width = area.width - ctrl.dockMargin.left - ctrl.dockMargin.right;
					area.height = area.height - ctrl.dockMargin.top - ctrl.dockMargin.bottom;
					area.x = area.x + ctrl.dockMargin.left;
					area.y = area.y + ctrl.dockMargin.top;
					ctrl.bounds = area;
			}
			//ctrl.resumeLayout(true);
			//ctrl.resumeLayout(prevctrlbounds != ctrl.bounds);
		}
		
		layout(this, lea);
		
		//resumeLayout(false);
		_cbits &= ~CBits.IN_LAYOUT;
	}
	
	/+
	// Not sure what to do here.
	deprecated bool isInputChar(char charCode)
	{
		return false;
	}
	+/
	bool isInputChar(char charCode)
	{
		int mask = 0;
		if (charCode == Keys.TAB)
		{
			mask = (DLGC_WANTCHARS | DLGC_WANTALLKEYS | DLGC_WANTTAB);
		}
		else
		{
			mask = (DLGC_WANTCHARS | DLGC_WANTALLKEYS);
		}

		return (SendMessage(_hwnd, WM_GETDLGCODE, 0, 0) & mask) != 0;
	}


	/// isInputKey returns true when keyData is a regular input key.
	// If keyData is input key, then window message is sended to wndProc()
	// such as WM_KEYDOWN, WM_KEYUP, WM_CHAR and so on.
	bool isInputKey(Keys keyData)
	{
		if ((keyData & Keys.ALT) == Keys.ALT)
		{
			return false;
		}

		auto mask = DLGC_WANTALLKEYS;
		switch (keyData & Keys.KEY_CODE)
		{
			case Keys.TAB:
				mask = DLGC_WANTALLKEYS | DLGC_WANTTAB;
				break;
			case Keys.LEFT:
			case Keys.RIGHT:
			case Keys.UP:
			case Keys.DOWN:
				mask = DLGC_WANTALLKEYS | DLGC_WANTARROWS;
				break;
			default:
				// Nothing
		}

		// return isHandleCreated
		// 	&& (SendMessage(hwnd, WM_GETDLGCODE, 0, 0) & mask) != 0;
		if (isHandleCreated)
		{
			LRESULT r = SendMessage(_hwnd, WM_GETDLGCODE, 0, 0);
			return (r & mask) != 0;
		}
		return false;
	}	

	///
	void setVisibleCore(bool byes)
	{
		if (isHandleCreated)
		{
			//wstyle = GetWindowLongPtrA(hwnd, GWL_STYLE);
			if (visible == byes)
				return;
			
			//ShowWindow(hwnd, byes ? SW_SHOW : SW_HIDE);
			if (byes)
				doShow();
			else
				doHide();
		}
		else
		{
			if (byes)
			{
				_cbits |= CBits.VISIBLE;
				_windowStyle |= WS_VISIBLE;
				createControl();
			}
			else
			{
				_cbits &= ~CBits.VISIBLE;
				_windowStyle &= ~WS_VISIBLE;
				return; // Not created and being hidden..
			}
		}
	}
	
	
	package final bool _wantTabKey()
	{
		// if (ctrlStyle & ControlStyles.WANT_TAB_KEY)
		if ((DLGC_WANTTAB & sendMessage(_hwnd, WM_GETDLGCODE, 0, 0)) != 0)
			return true;
		else
			return false;
	}
	
	
	///
	// Return true if processed.
	bool processKeyEventArgs(ref Message msg)
	{
		// TODO: implement more (IME etc...)

		switch (msg.msg)
		{
			case WM_CHAR:
			case WM_SYSCHAR:
			{
				scope KeyPressEventArgs kpea = new KeyPressEventArgs(cast(dchar)msg.wParam, modifierKeys);
				onKeyPress(kpea);
				return kpea.handled;
			}

			case WM_KEYDOWN:
			case WM_SYSKEYDOWN:
			{
				scope KeyEventArgs kea = new KeyEventArgs(cast(Keys)(msg.wParam | modifierKeys));
				ushort repeat = msg.lParam & 0xFFFF; // First 16 bits.
				for (; repeat; repeat--)
				{
					//kea.handled = false;
					onKeyDown(kea);
				}
				
				return kea.handled;
			}
		
			case WM_KEYUP:
			case WM_SYSKEYUP: // TODO: Is it correct?
			{
				// Repeat count is always 1 for key up.
				scope KeyEventArgs kea = new KeyEventArgs(cast(Keys)(msg.wParam | modifierKeys));
				onKeyUp(kea);
				return kea.handled;
			}
		
			default:
				assert(0); // Does not reached here, if WM is traped in Control.wndProc() correctly.
		}
	}
	
	
	package final bool _processKeyEventArgs(ref Message msg)
	{
		return processKeyEventArgs(msg);
	}
	

	///
	bool processMnemonic(dchar charCode)
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
	
	package enum CCompat: ubyte
	{
		NONE = 0,
		DFL095 = 1,
	}
	
	version(SET_DFL_095)
		package enum _compat = CCompat.DFL095;
	else version(DFL_NO_COMPAT)
		package enum _compat = CCompat.NONE;
	else
		package @property CCompat _compat() const // getter
			{ if (Application._compat & DflCompat.CONTROL_RECREATE_095) return CCompat.DFL095; return CCompat.NONE; }
	
	
	package final void _crecreate()
	{
		if (CCompat.DFL095 != _compat)
		{
			if (!recreatingHandle)
				recreateHandle();
		}
	}
	
	
package:
	HWND _hwnd;
	//AnchorStyles anch = cast(AnchorStyles)(AnchorStyles.TOP | AnchorStyles.LEFT);
	//bool cvalidation = true;
	ContextMenu _contextMenu;
	LocationAlignment _locationAlignment = LocationAlignment.NONE;
	DockStyle _dockStyle = DockStyle.NONE;
	DockPaddingEdges _dockPadding;
	DockMarginEdges _dockMargin;
	Dstring _controlName;
	Object _objectTag;
	Color _backColor, _foreColor;
	Rect _windowRect;
	//Rect oldwrect;
	Size _clientSize;
	Cursor _windowCursor;
	Font _windowFont;
	Font _windowScaledFont;
	Control _parentWindow;
	Region _windowRegion;
	ControlCollection _controlCollection;
	Dstring _windowText; // After creation, this isn't used unless ControlStyles.CACHE_TEXT.
	ControlStyles _controlStyle = ControlStyles.STANDARD_CLICK | ControlStyles.STANDARD_DOUBLE_CLICK /+ | ControlStyles.RESIZE_REDRAW +/ ;
	HBRUSH _backgroundHbrush;
	RightToLeft _rightToLeft = RightToLeft.INHERIT;
	uint _disallowLayout = 0;
	uint _windowDpi = USER_DEFAULT_SCREEN_DPI;
	
	version(DFL_NO_DRAG_DROP) {} else
	{
		DropTarget _dropTarget = null;
		bool _allowDrop = false;
	}
	
	// NOTE: WS_VISIBLE is not reliable.
	LONG _windowStyle = WS_CHILD | WS_VISIBLE | WS_CLIPCHILDREN | WS_CLIPSIBLINGS; // Child, visible and enabled by default.
	LONG _windowStyleEx;
	LONG _windowClassStyle = WNDCLASS_STYLE;
	
	
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
	CBits _cbits = CBits.VISIBLE | CBits.VSTYLE | CBits.ENABLED;
	
	
final:
	
	@property void menter(bool byes) // setter
	{
		if (byes)
			_cbits |= CBits.MENTER;
		else
			_cbits &= ~CBits.MENTER;
	}
	@property bool menter() const // getter
	{
		return (_cbits & CBits.MENTER) != 0;
	}
	
	@property void killing(bool byes) // setter
	//{ if (byes) cbits |= CBits.KILLING; else cbits &= ~CBits.KILLING; }
	{
		assert(byes);
		if (byes)
			_cbits |= CBits.KILLING;
	}
	@property bool killing() const // getter
	{
		return (_cbits & CBits.KILLING) != 0;
	}
	
	@property void owned(bool byes) // setter
	{
		if (byes)
			_cbits |= CBits.OWNED;
		else
			_cbits &= ~CBits.OWNED;
	}
	@property bool owned() const // getter
	{
		return (_cbits & CBits.OWNED) != 0;
	}
	
	/+
	void _allowLayout(bool byes) // setter
	{
		if (byes)
			cbits |= CBits.ALLOW_LAYOUT;
		else
			cbits &= ~CBits.ALLOW_LAYOUT;
	}
	
	bool _allowLayout() // getter
	{
		return (cbits & CBits.ALLOW_LAYOUT) != 0;
	}
	+/

	@property void _clicking(bool byes) // setter
	{
		if (byes)
			_cbits |= CBits.CLICKING;
		else
			_cbits &= ~CBits.CLICKING;
	}
	@property bool _clicking() const // getter
	{
		return (_cbits & CBits.CLICKING) != 0;
	}
	
	@property void needCalcSize(bool byes) // setter
	{
		if (byes)
			_cbits |= CBits.NEED_CALC_SIZE;
		else
			_cbits &= ~CBits.NEED_CALC_SIZE;
	}
	@property bool needCalcSize() const // getter
	{
		return (_cbits & CBits.NEED_CALC_SIZE) != 0;
	}
	
	@property void szdraw(bool byes) // setter
	{
		if (byes)
			_cbits |= CBits.SZDRAW;
		else
			_cbits &= ~CBits.SZDRAW;
	}
	@property bool szdraw() const // getter
	{
		return (_cbits & CBits.SZDRAW) != 0;
	}
	
	@property void ownedbg(bool byes) // setter
	{
		if (byes)
			_cbits |= CBits.OWNEDBG;
		else
		_cbits &= ~CBits.OWNEDBG;
	}
	@property bool ownedbg() const // getter
	{
		return (_cbits & CBits.OWNEDBG) != 0;
	}
	
	debug
	{
		@property void _handlecreated(bool byes) // setter
		{
			if (byes)
				_cbits |= CBits.HANDLE_CREATED;
			else
				_cbits &= ~CBits.HANDLE_CREATED;
		}
		@property bool _handlecreated() const // getter
		{
			return (_cbits & CBits.HANDLE_CREATED) != 0;
		}
	}
	
	
	@property LONG _exStyle() const // getter
	{
		// return GetWindowLongPtrA(hwnd, GWL_EXSTYLE);
		return _windowStyleEx;
	}
	
	@property void _exStyle(LONG wl) // setter
	{
		if (isHandleCreated)
		{
			SetWindowLongPtrA(_hwnd, GWL_EXSTYLE, wl);
		}
		
		_windowStyleEx = wl;
	}
	
	
	@property LONG _style() const // getter
	{
		// return GetWindowLongPtrA(hwnd, GWL_STYLE);
		return _windowStyle;
	}
	
	@property void _style(LONG wl) // setter
	{
		if (isHandleCreated)
		{
			SetWindowLongPtrA(_hwnd, GWL_STYLE, wl);
		}
		
		_windowStyle = wl;
	}
	
	
	deprecated alias hbrBg = backgroundHbrush;

	@property HBRUSH backgroundHbrush() // getter
	{
		if (_backgroundHbrush)
			return _backgroundHbrush;
		if (_backColor == Color.empty && parent && backColor == parent.backColor)
		{
			ownedbg = false;
			_backgroundHbrush = parent.backgroundHbrush;
			return _backgroundHbrush;
		}
		backgroundHbrush = backColor.createBrush(); // Call hbrBg's setter and set ownedbg.
		return _backgroundHbrush;
	}
	
	@property void backgroundHbrush(HBRUSH hbr) // setter
	in
	{
		if (hbr)
		{
			assert(!_backgroundHbrush);
		}
	}
	do
	{
		_backgroundHbrush = hbr;
		ownedbg = true;
	}
	
	
	void deleteThisBackgroundBrush()
	{
		if (_backgroundHbrush)
		{
			if (ownedbg)
				DeleteObject(_backgroundHbrush);
			_backgroundHbrush = HBRUSH.init;
		}
	}
	
	
	LRESULT defwproc(UINT msg, WPARAM wparam, LPARAM lparam)
	{
		//return DefWindowProcA(hwnd, msg, wparam, lparam);
		return dfl.internal.utf.defWindowProc(_hwnd, msg, wparam, lparam);
	}
	
	
	LONG_PTR _fetchClassLongPtr()
	{
		return GetClassLongPtrA(_hwnd, GCL_STYLE);
	}
	
	
	LONG _classStyle() // getter
	{
		// return GetClassLongPtrA(hwnd, GCL_STYLE);
		// return wclassStyle;
		
		if (isHandleCreated)
		{
			// Always fetch because it's not guaranteed to be accurate.
			_windowClassStyle = _fetchClassLongPtr().toI32;
		}
		
		return _windowClassStyle;
	}
	
	void _classStyle(LONG cl) // setter
	{
		if (isHandleCreated)
		{
			SetClassLongPtrA(_hwnd, GCL_STYLE, cl);
		}
		
		_windowClassStyle = cl;
	}
}


package abstract class ControlSuperClass: Control // dapi.d
{
	// Call previous wndProc().
	abstract protected void prevWndProc(ref Message msg);
	
	
	protected override void wndProc(ref Message msg)
	{
		switch (msg.msg)
		{
			case WM_PAINT:
			{
				RECT uprect;
				//GetUpdateRect(hwnd, &uprect, true);
				//onInvalidated(new InvalidateEventArgs(Rect(&uprect)));
				
				//if (!msg.wParam)
					GetUpdateRect(_hwnd, &uprect, false); // Preserve.

				prevWndProc(msg);
				
				// Now fake a normal paint event...
				
				scope Graphics gpx = new CommonGraphics(_hwnd, GetDC(_hwnd));
				//scope Graphics gpx = new CommonGraphics(hwnd, msg.wParam ? cast(HDC)msg.wParam : GetDC(hwnd), msg.wParam ? false : true);
				HRGN hrgn = CreateRectRgnIndirect(&uprect);
				SelectClipRgn(gpx.handle, hrgn);
				DeleteObject(hrgn);
				
				uprect.left = MulDiv(uprect.left, USER_DEFAULT_SCREEN_DPI, _windowDpi);
				uprect.top = MulDiv(uprect.top, USER_DEFAULT_SCREEN_DPI, _windowDpi);
				uprect.right = MulDiv(uprect.right, USER_DEFAULT_SCREEN_DPI, _windowDpi);
				uprect.bottom = MulDiv(uprect.bottom, USER_DEFAULT_SCREEN_DPI, _windowDpi);
				
				scope PaintEventArgs pea = new PaintEventArgs(gpx, Rect(&uprect));
				
				// Can't erase the background now, Windows just painted..
				//if (ps.fErase)
				//{
				//	prepareDc(gpx.handle);
				//	onPaintBackground(pea);
				//}
				
				prepareDc(gpx.handle);
				onPaint(pea);
				break;
			}
			
			case WM_PRINTCLIENT:
			{
				prevWndProc(msg);
				
				scope Graphics gpx = new CommonGraphics(_hwnd, GetDC(_hwnd));
				scope PaintEventArgs pea = new PaintEventArgs(gpx, Rect(Point(0, 0), _clientSize));
				
				prepareDc(pea.graphics.handle);
				onPaint(pea);
				break;
			}
			
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
		switch (m.msg)
		{
			case WM_KEYDOWN:
			case WM_KEYUP:
			case WM_CHAR:
			case WM_SYSKEYDOWN:
			case WM_SYSKEYUP:
			case WM_SYSCHAR:
			//case WM_IMECHAR: // TODO: ?
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
	///
	deprecated void autoScroll(bool byes) // setter
	{
		if (byes)
			_cbits |= CBits.ASCROLL;
		else
			_cbits &= ~CBits.ASCROLL;
	}
	
	/// ditto
	deprecated bool autoScroll() const // getter
	{
		return (_cbits & CBits.ASCROLL) == CBits.ASCROLL;
	}
	
	
	///
	deprecated final void autoScrollMargin(Size sz) // setter
	{
		//scrollmargin = sz;
	}
	
	/// ditto
	deprecated final Size autoScrollMargin() const // getter
	{
		//return scrollmargin;
		return Size(0, 0);
	}
	
	
	///
	deprecated final void autoScrollMinSize(Size sz) // setter
	{
		//scrollmin = sz;
	}
	
	/// ditto
	deprecated final Size autoScrollMinSize() const // getter
	{
		//return scrollmin;
		return Size(0, 0);
	}
	
	
	///
	deprecated final void autoScrollPosition(Point pt) // setter
	{
		//autoscrollpos = pt;
	}
	
	/// ditto
	deprecated final Point autoScrollPosition() const // getter
	{
		//return autoscrollpos;
		return Point(0, 0);
	}
	
	
	///
	final @property Size autoScaleBaseSize() const // getter
	{
		return _autoScrollSize;
	}
	
	/// ditto
	final @property void autoScaleBaseSize(Size newSize) // setter
	in
	{
		assert(newSize.width > 0);
		assert(newSize.height > 0);
	}
	do
	{
		_autoScrollSize = newSize;
	}
	
	
	///
	final @property void autoScale(bool byes) // setter
	{
		if (byes)
			_cbits |= CBits.ASCALE;
		else
			_cbits &= ~CBits.ASCALE;
	}
	
	/// ditto
	final @property bool autoScale() const // getter
	{
		return (_cbits & CBits.ASCALE) == CBits.ASCALE;
	}
	
	
	///
	final @property Point scrollPosition() const // getter
	{
		return Point(_xScrollPostision, _yScrollPosition);
	}
	
	
	///
	static Size _calcScaleStatics(Size area, Size toScale, Size fromScale) // package
	in
	{
		assert(fromScale.width);
		assert(fromScale.height);
	}
	do
	{
		area.width = cast(int)(cast(float)area.width / cast(float)fromScale.width * cast(float)toScale.width);
		area.height = cast(int)(cast(float)area.height / cast(float)fromScale.height * cast(float)toScale.height);
		return area;
	}
	
	
	///
	Size _calcScale(Size area, Size toScale) // package
	{
		return _calcScaleStatics(area, toScale, DEFAULT_SCALE);
	}
	
	
	///
	final void _scale(Size toScale) // package
	{
		bool first = true;
		
		// Note: doesn't get to-scale for nested scrollable-controls.
		void xscale(Control c, Size fromScale)
		{
			c.suspendLayout();
			
			if (first)
			{
				first = false;
				c.size = _calcScaleStatics(c.size, toScale, fromScale);
			}
			else
			{
				Size sz = _calcScaleStatics(Size(c.left, c.top), toScale, fromScale);
				Point pt = Point(sz.width, sz.height);
				sz = _calcScaleStatics(c.size, toScale, fromScale);
				c.bounds = Rect(pt, sz);
			}
			
			if (c.hasChildren)
			{
				ScrollableControl scc;
				foreach (Control cc; c.controls)
				{
					scc = cast(ScrollableControl)cc;
					if (scc)
					{
						if (scc.autoScale) // TODO: ?
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
		
		if (created) // TODO: ?
		if (isHandleCreated)
		{
			auto sc = cast(ScrollableControl)ea.control;
			if (sc)
			{
				if (sc.autoScale)
					sc._scale();
			}
			else
			{
				if (autoScale)
					_scale();
			}
		}
	}
	
	
	///
	override @property Rect displayRectangle() // getter
	{
		Rect result = super.displayRectangle();
		
		// Add scroll width.
		if (scrollSize.width > clientSize.width)
			result.width = result.width + (scrollSize.width - clientSize.width);
		if (scrollSize.height > clientSize.height)
			result.height = result.height + (scrollSize.height - clientSize.height);
		
		// Adjust scroll position.
		result.location = Point(result.location.x - scrollPosition.x, result.location.y - scrollPosition.y);
		
		return result;
	}
	
	
	///
	final @property void scrollSize(Size sz) // setter
	{
		_scrollSize = sz;
		
		_fixScrollBounds(); // Implies _adjustScrollSize().
	}
	
	/// ditto
	final @property Size scrollSize() const // getter
	{
		return _scrollSize;
	}
	
	
	///
	deprecated final void setAutoScrollMargin(int x, int y)
	{
		//
	}
	
	
	enum DEFAULT_SCALE = Size(5, 13);
	
	///
	final @property void hScroll(bool byes) // setter
	{
		LONG wl = _style();
		if (byes)
			wl |= WS_HSCROLL;
		else
			wl &= ~WS_HSCROLL;
		_style(wl);
		
		if (isHandleCreated)
			redrawEntire();
	}
	
	
	/// ditto
	final @property bool hScroll() const // getter
	{
		return (_style() & WS_HSCROLL) != 0;
	}
	
	
	///
	final @property void vScroll(bool byes) // setter
	{
		LONG wl = _style();
		if (byes)
			wl |= WS_VSCROLL;
		else
			wl &= ~WS_VSCROLL;
		_style(wl);
		
		if (isHandleCreated)
			redrawEntire();
	}
	
	/// ditto
	final @property bool vScroll() const // getter
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
		switch (m.msg)
		{
			case WM_VSCROLL:
			{
				SCROLLINFO si = void;
				si.cbSize = SCROLLINFO.sizeof;
				si.fMask = SIF_ALL;
				if (GetScrollInfo(m.hWnd, SB_VERT, &si))
				{
					int delta;
					int maxp = scrollSize.height - clientSize.height;
					switch (LOWORD(m.wParam))
					{
						case SB_LINEDOWN:
							if (_yScrollPosition >= maxp)
								return;
							delta = maxp - _yScrollPosition;
							if (_autoScrollSize.height < delta)
								delta = _autoScrollSize.height;
							break;
						case SB_LINEUP:
							if (_yScrollPosition <= 0)
								return;
							delta = _yScrollPosition;
							if (_autoScrollSize.height < delta)
								delta = _autoScrollSize.height;
							delta = -delta;
							break;
						case SB_PAGEDOWN:
							if (_yScrollPosition >= maxp)
								return;
							if (_yScrollPosition >= maxp)
								return;
							delta = maxp - _yScrollPosition;
							if (clientSize.height < delta)
								delta = clientSize.height;
							break;
						case SB_PAGEUP:
							if (_yScrollPosition <= 0)
								return;
							delta = _yScrollPosition;
							if (clientSize.height < delta)
								delta = clientSize.height;
							delta = -delta;
							break;
						case SB_THUMBTRACK:
						case SB_THUMBPOSITION:
							//delta = cast(int)HIWORD(m.wParam) - yspos; // Limited to 16-bits.
							delta = si.nTrackPos - _yScrollPosition;
							break;
						case SB_BOTTOM:
							delta = maxp - _yScrollPosition;
							break;
						case SB_TOP:
							delta = -_yScrollPosition;
							break;
						default:
					}
					_yScrollPosition += delta;
					SetScrollPos(m.hWnd, SB_VERT, _yScrollPosition, TRUE);
					ScrollWindow(m.hWnd, 0, -delta, null, null);
				}
				break;
			}
			
			case WM_HSCROLL:
			{
				SCROLLINFO si = void;
				si.cbSize = SCROLLINFO.sizeof;
				si.fMask = SIF_ALL;
				if (GetScrollInfo(m.hWnd, SB_HORZ, &si))
				{
					int delta;
					int maxp = scrollSize.width - clientSize.width;
					switch (LOWORD(m.wParam))
					{
						case SB_LINERIGHT:
							if (_xScrollPostision >= maxp)
								return;
							delta = maxp - _xScrollPostision;
							if (_autoScrollSize.width < delta)
								delta = _autoScrollSize.width;
							break;
						case SB_LINELEFT:
							if (_xScrollPostision <= 0)
								return;
							delta = _xScrollPostision;
							if (_autoScrollSize.width < delta)
								delta = _autoScrollSize.width;
							delta = -delta;
							break;
						case SB_PAGERIGHT:
							if (_xScrollPostision >= maxp)
								return;
							if (_xScrollPostision >= maxp)
								return;
							delta = maxp - _xScrollPostision;
							if (clientSize.width < delta)
								delta = clientSize.width;
							break;
						case SB_PAGELEFT:
							if (_xScrollPostision <= 0)
								return;
							delta = _xScrollPostision;
							if (clientSize.width < delta)
								delta = clientSize.width;
							delta = -delta;
							break;
						case SB_THUMBTRACK:
						case SB_THUMBPOSITION:
							//delta = cast(int)HIWORD(m.wParam) - xspos; // Limited to 16-bits.
							delta = si.nTrackPos - _xScrollPostision;
							break;
						case SB_RIGHT:
							delta = maxp - _xScrollPostision;
							break;
						case SB_LEFT:
							delta = -_xScrollPostision;
							break;
						default:
					}
					_xScrollPostision += delta;
					SetScrollPos(m.hWnd, SB_HORZ, _xScrollPostision, TRUE);
					ScrollWindow(m.hWnd, -delta, 0, null, null);
				}
				break;
			}
			
			default:
		}
		
		super.wndProc(m);
	}
	
	
	override void onMouseWheel(MouseEventArgs ea)
	{
		int maxp = scrollSize.height - clientSize.height;
		int delta;
		
		UINT wlines;
		if (!SystemParametersInfoA(SPI_GETWHEELSCROLLLINES, 0, &wlines, 0))
			wlines = 3;
		
		if (ea.delta < 0)
		{
			if (_yScrollPosition < maxp)
			{
				delta = maxp - _yScrollPosition;
				if (_autoScrollSize.height * wlines < delta)
					delta = _autoScrollSize.height * wlines;
				
				_yScrollPosition += delta;
				SetScrollPos(_hwnd, SB_VERT, _yScrollPosition, TRUE);
				ScrollWindow(_hwnd, 0, -delta, null, null);
			}
		}
		else
		{
			if (_yScrollPosition > 0)
			{
				delta = _yScrollPosition;
				if (_autoScrollSize.height * wlines < delta)
					delta = _autoScrollSize.height * wlines;
				delta = -delta;
				
				_yScrollPosition += delta;
				SetScrollPos(_hwnd, SB_VERT, _yScrollPosition, TRUE);
				ScrollWindow(_hwnd, 0, -delta, null, null);
			}
		}
		
		super.onMouseWheel(ea);
	}
	
	
	override void onHandleCreated(EventArgs ea)
	{
		_xScrollPostision = 0;
		_yScrollPosition = 0;
		
		super.onHandleCreated(ea);
		
		//_adjustScrollSize(FALSE);
		if (hScroll || vScroll)
		{
			_adjustScrollSize(FALSE);
			recalcEntire(); // Need to recalc frame.
		}
	}
	
	
	override void onVisibleChanged(EventArgs ea)
	{
		if (visible)
			_adjustScrollSize(FALSE);
		
		super.onVisibleChanged(ea);
	}
	
	
	private void _fixScrollBounds()
	{
		if (hScroll || vScroll)
		{
			int ydiff = 0, xdiff = 0;
			
			if (_yScrollPosition > scrollSize.height - clientSize.height)
			{
				ydiff = (clientSize.height + _yScrollPosition) - scrollSize.height;
				_yScrollPosition -= ydiff;
				if (_yScrollPosition < 0)
				{
					ydiff += _yScrollPosition;
					_yScrollPosition = 0;
				}
			}
			
			if (_xScrollPostision > scrollSize.width - clientSize.width)
			{
				xdiff = (clientSize.width + _xScrollPostision) - scrollSize.width;
				_xScrollPostision -= xdiff;
				if (_xScrollPostision < 0)
				{
					xdiff += _xScrollPostision;
					_xScrollPostision = 0;
				}
			}
			
			if (isHandleCreated)
			{
				if (xdiff || ydiff)
					ScrollWindow(_hwnd, xdiff, ydiff, null, null);
				
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
	Size _autoScrollSize = DEFAULT_SCALE;
	Size _scrollSize = Size(0, 0);
	int _xScrollPostision = 0, _yScrollPosition = 0;
	
	
	void _adjustScrollSize(BOOL fRedraw = TRUE)
	{
		assert(isHandleCreated);
		
		if (!hScroll && !vScroll)
			return;
		
		SCROLLINFO si;
		//if (vScroll)
		{
			si.cbSize = SCROLLINFO.sizeof;
			si.fMask = SIF_RANGE | SIF_PAGE | SIF_POS;
			si.nPos = _yScrollPosition;
			si.nMin = 0;
			si.nMax = clientSize.height;
			si.nPage = clientSize.height;
			if (scrollSize.height > clientSize.height)
				si.nMax = scrollSize.height;
			if (si.nMax)
				si.nMax--;
			SetScrollInfo(_hwnd, SB_VERT, &si, fRedraw);
		}
		//if (hScroll)
		{
			si.cbSize = SCROLLINFO.sizeof;
			si.fMask = SIF_RANGE | SIF_PAGE | SIF_POS;
			si.nPos = _xScrollPostision;
			si.nMin = 0;
			si.nMax = clientSize.width;
			si.nPage = clientSize.width;
			if (scrollSize.width > clientSize.width)
				si.nMax = scrollSize.width;
			if (si.nMax)
				si.nMax--;
			SetScrollInfo(_hwnd, SB_HORZ, &si, fRedraw);
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
			if (hw == this.hwnd)
				return Control.fromChildHandle(hwfocus);
			hw = GetParent(hw);
		}
		return null;
		+/
		Control ctrlfocus = Control.fromChildHandle(GetFocus());
		Control ctrl = ctrlfocus;
		while(ctrl)
		{
			if (ctrl is this)
				return ctrlfocus;
			ctrl = ctrl.parent;
		}
		return null;
	}
	
	/// ditto
	@property void activeControl(Control ctrl) // setter
	{
		if (!activateControl(ctrl))
			throw new DflException("Unable to activate control");
	}
	
	
	///
	// Returns true if successfully activated.
	final bool activateControl(Control ctrl)
	{
		// Not sure if this is correct.
		
		if (!ctrl.canSelect)
			return false;
		//if (!SetActiveWindow(ctrl.handle))
		//	return false;
		ctrl.select();
		return true;
	}
	
	
	///
	final @property Form parentForm() // getter
	{
		Form f;
		
		for (Control par = parent; par; par = par.parent)
		{
			f = cast(Form)par;
			if (f)
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
		_controlStyle |= ControlStyles.CONTAINER_CONTROL;
	}
	
	
	protected bool processTabKey(bool forward)
	{
		if (isHandleCreated)
		{
			return selectNextControl(activeControl, forward, tabStop, true, false);
		}
		return false;
	}
}
