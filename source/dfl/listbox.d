// Written by Christopher E. Miller
// See the included license.txt for copyright and license details.


///
module dfl.listbox;

import dfl.application;
import dfl.base;
import dfl.collections;
import dfl.control;
import dfl.drawing;
import dfl.event;

import dfl.internal.dlib;
import dfl.internal.dpiaware;
import dfl.internal.utf;

import core.sys.windows.winbase;
import core.sys.windows.winuser;
import core.sys.windows.windef;
import core.sys.windows.wingdi;

static import std.algorithm;


private extern(C) void* memmove(void*, void*, size_t len);

private extern(Windows) void _initListbox();


alias ListString = StringObject;


///
abstract class ListControl: ControlSuperClass // docmain
{
	///
	final Dstring getItemText(Object item)
	{
		return getObjectString(item);
	}
	
	
	Event!(ListControl, EventArgs) selectedValueChanged; ///
	
	
	///
	abstract @property void selectedIndex(int idx); // setter
	/// ditto
	abstract @property int selectedIndex(); // getter
	
	///
	abstract @property void selectedValue(Object val); // setter
	/// ditto
	
	///
	abstract @property void selectedValue(Dstring str); // setter
	/// ditto
	abstract @property Object selectedValue(); // getter
	
	
	static @property Color defaultBackColor() // getter
	{
		return SystemColors.window;
	}
	
	
	override @property Color backColor() const // getter
	{
		if (Color.empty == _backColor)
			return defaultBackColor;
		return _backColor;
	}
	
	alias backColor = Control.backColor; // Overload.
	
	
	static @property Color defaultForeColor() // getter
	{
		return SystemColors.windowText;
	}
	
	
	override @property Color foreColor() const // getter
	{
		if (Color.empty == _foreColor)
			return defaultForeColor;
		return _foreColor;
	}
	
	alias foreColor = Control.foreColor; // Overload.
	
	
	this()
	{
	}
	
	
protected:
	
	///
	void onSelectedValueChanged(EventArgs ea)
	{
		selectedValueChanged(this, ea);
	}
	
	
	///
	// Index change causes the value to be changed.
	void onSelectedIndexChanged(EventArgs ea)
	{
		onSelectedValueChanged(ea); // This appears to be correct.
	}
}


///
enum SelectionMode: ubyte
{
	ONE, ///
	NONE, /// ditto
	MULTI_SIMPLE, /// ditto
	MULTI_EXTENDED, /// ditto
}


///
class ListBox: ListControl // docmain
{
	///
	static class SelectedIndexCollection
	{
		@property int length() // getter
		{
			if (!_listBox.isHandleCreated)
				return 0;
			
			if (_listBox.isMultSel())
			{
				return _listBox.prevwproc(LB_GETSELCOUNT, 0, 0).toI32;
			}
			else
			{
				return (_listBox.selectedIndex == -1) ? 0 : 1;
			}
		}
		
		
		int opIndex(int idx)
		{
			foreach (int onidx; this)
			{
				if (!idx)
					return onidx;
				idx--;
			}
			
			// If it's not found it's out of bounds and bad things happen.
			assert(0);
		}
		
		
		bool contains(int idx)
		{
			return indexOf(idx) != -1;
		}
		
		
		int indexOf(int idx)
		{
			int i = 0;
			foreach (int onidx; this)
			{
				if (onidx == idx)
					return i;
				i++;
			}
			return -1;
		}
		
		
		int opApply(int delegate(ref int) dg)
		{
			int result = 0;
			
			if (_listBox.isMultSel())
			{
				int[] items = new int[length];
				if (items.length != _listBox.prevwproc(LB_GETSELITEMS, items.length, cast(LPARAM)cast(int*)items))
					throw new DflException("Unable to enumerate selected list items");
				foreach (int _idx; items)
				{
					int idx = _idx; // Prevent ref.
					result = dg(idx);
					if (result)
						break;
				}
			}
			else
			{
				int idx = _listBox.selectedIndex;
				if (-1 != idx)
					result = dg(idx);
			}
			return result;
		}
		
		mixin OpApplyAddIndex!(opApply, int);
		
		
		protected this(ListBox lb)
		{
			_listBox = lb;
		}
		
		
	package:
		ListBox _listBox;
	}
	
	
	///
	static class SelectedObjectCollection
	{
		@property int length() // getter
		{
			if (!_listBox.isHandleCreated)
				return 0;
			
			if (_listBox.isMultSel())
			{
				return _listBox.prevwproc(LB_GETSELCOUNT, 0, 0).toI32;
			}
			else
			{
				return (_listBox.selectedIndex == -1) ? 0 : 1;
			}
		}
		
		
		Object opIndex(int idx)
		{
			foreach (Object obj; this)
			{
				if (!idx)
					return obj;
				idx--;
			}
			
			// If it's not found it's out of bounds and bad things happen.
			assert(0);
		}
		
		
		bool contains(Object obj)
		{
			return indexOf(obj) != -1;
		}
		
		
		bool contains(Dstring str)
		{
			return indexOf(str) != -1;
		}
		
		
		int indexOf(Object obj)
		{
			int idx = 0;
			foreach (Object onobj; this)
			{
				if (onobj == obj) // Not using is.
					return idx;
				idx++;
			}
			return -1;
		}
		
		
		int indexOf(Dstring str)
		{
			int idx = 0;
			foreach (Object onobj; this)
			{
				//if (getObjectString(onobj) is str && getObjectString(onobj).length == str.length)
				if (getObjectString(onobj) == str)
					return idx;
				idx++;
			}
			return -1;
		}
		
		
		// Used internally.
		int _opApply(int delegate(ref Object) dg) // package
		{
			int result = 0;
			
			if (_listBox.isMultSel())
			{
				int[] items = new int[length];
				if (items.length != _listBox.prevwproc(LB_GETSELITEMS, items.length, cast(LPARAM)cast(int*)items))
					throw new DflException("Unable to enumerate selected list items");
				foreach (int idx; items)
				{
					Object obj = _listBox.items[idx];
					result = dg(obj);
					if (result)
						break;
				}
			}
			else
			{
				Object obj = _listBox.selectedItem;
				if (obj)
					result = dg(obj);
			}
			return result;
		}
		
		
		// Used internally.
		int _opApply(int delegate(ref Dstring) dg) // package
		{
			int result = 0;
			
			if (_listBox.isMultSel())
			{
				int[] items = new int[length];
				if (items.length != _listBox.prevwproc(LB_GETSELITEMS, items.length, cast(LPARAM)cast(int*)items))
					throw new DflException("Unable to enumerate selected list items");
				foreach (int idx; items)
				{
					Dstring str = getObjectString(_listBox.items[idx]);
					result = dg(str);
					if (result)
						break;
				}
			}
			else
			{
				Object obj = _listBox.selectedItem;
				if (obj)
				{
					Dstring str = getObjectString(obj);
					result = dg(str);
				}
			}
			return result;
		}
		
		mixin OpApplyAddIndex!(_opApply, Dstring);
		
		mixin OpApplyAddIndex!(_opApply, Object);
		
		// Had to do it this way because: DMD 1.028: -H is broken for mixin identifiers
		// Note that this way probably prevents opApply from being overridden.
		alias opApply = _opApply;
		
		
		protected this(ListBox lb)
		{
			_listBox = lb;
		}
		
		
	package:
		ListBox _listBox;
	}
	
	
	///
	enum int DEFAULT_ITEM_HEIGHT = 13;
	///
	enum int NO_MATCHES = LB_ERR;
	
	
	protected override @property Size defaultSize() const // getter
	{
		return Size(120, 95);
	}
	
	
	///
	@property void borderStyle(BorderStyle bs) // setter
	{
		final switch (bs)
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
		
		if (isHandleCreated)
		{
			redrawEntire();
		}
	}
	
	/// ditto
	@property BorderStyle borderStyle() const // getter
	{
		if (_exStyle() & WS_EX_CLIENTEDGE)
			return BorderStyle.FIXED_3D;
		else if (_style() & WS_BORDER)
			return BorderStyle.FIXED_SINGLE;
		return BorderStyle.NONE;
	}
	
	
	///
	@property void drawMode(DrawMode dm) // setter
	{
		LONG wl = _style() & ~(LBS_OWNERDRAWVARIABLE | LBS_OWNERDRAWFIXED);
		
		final switch (dm)
		{
			case DrawMode.OWNER_DRAW_VARIABLE:
				wl |= LBS_OWNERDRAWVARIABLE;
				break;
			
			case DrawMode.OWNER_DRAW_FIXED:
				wl |= LBS_OWNERDRAWFIXED;
				break;
			
			case DrawMode.NORMAL:
				break;
		}
		
		_style(wl);
		
		_crecreate();
	}
	
	/// ditto
	@property DrawMode drawMode() const // getter
	{
		LONG wl = _style();
		
		if (wl & LBS_OWNERDRAWVARIABLE)
			return DrawMode.OWNER_DRAW_VARIABLE;
		if (wl & LBS_OWNERDRAWFIXED)
			return DrawMode.OWNER_DRAW_FIXED;
		return DrawMode.NORMAL;
	}
	
	
	///
	final @property void horizontalExtent(int he) // setter
	{
		if (isHandleCreated)
			prevwproc(LB_SETHORIZONTALEXTENT, he, 0);
		
		_horizontalExtent = he;
	}
	
	/// ditto
	final @property int horizontalExtent() // getter
	{
		if (isHandleCreated)
			_horizontalExtent = cast(int)prevwproc(LB_GETHORIZONTALEXTENT, 0, 0);
		return _horizontalExtent;
	}
	
	
	///
	final @property void horizontalScrollbar(bool byes) // setter
	{
		if (byes)
			_style(_style() | WS_HSCROLL);
		else
			_style(_style() & ~WS_HSCROLL);
		
		_crecreate();
	}
	
	/// ditto
	final @property bool horizontalScrollbar() const // getter
	{
		return (_style() & WS_HSCROLL) != 0;
	}
	
	
	///
	final @property void integralHeight(bool byes) // setter
	{
		if (byes)
			_style(_style() & ~LBS_NOINTEGRALHEIGHT);
		else
			_style(_style() | LBS_NOINTEGRALHEIGHT);
		
		_crecreate();
	}
	
	/// ditto
	final @property bool integralHeight() const // getter
	{
		return (_style() & LBS_NOINTEGRALHEIGHT) == 0;
	}
	
	
	///
	// This function has no effect if the drawMode is OWNER_DRAW_VARIABLE.
	final @property void itemHeight(int h) // setter
	{
		if (drawMode == DrawMode.OWNER_DRAW_VARIABLE)
			return;
		
		_itemHeight = h;
		
		if (isHandleCreated)
			prevwproc(LB_SETITEMHEIGHT, 0, MAKELPARAM(MulDiv(h, dpi, USER_DEFAULT_SCREEN_DPI), 0));
	}
	
	/// ditto
	// Return value is meaningless when drawMode is OWNER_DRAW_VARIABLE.
	final @property int itemHeight() const // getter
	{
		// Requesting it like this when owner draw variable doesn't work.
		/+
		if (!isHandleCreated)
			return iheight;
		
		int result = prevwproc(LB_GETITEMHEIGHT, 0, 0);
		if (result == LB_ERR)
			result = iheight; // ?
		else
			iheight = result;
		
		return result;
		+/
		
		return _itemHeight;
	}
	
	
	///
	final @property inout(ObjectCollection) items() inout // getter
	{
		return _itemCollection;
	}
	
	
	///
	final @property void multiColumn(bool byes) // setter
	{
		// TODO: is this the correct implementation?
		
		if (byes)
			_style(_style() | LBS_MULTICOLUMN | WS_HSCROLL);
		else
			_style(_style() & ~(LBS_MULTICOLUMN | WS_HSCROLL));
		
		_crecreate();
	}
	
	/// ditto
	final @property bool multiColumn() const // getter
	{
		return (_style() & LBS_MULTICOLUMN) != 0;
	}
	
	
	///
	final @property void scrollAlwaysVisible(bool byes) // setter
	{
		if (byes)
			_style(_style() | LBS_DISABLENOSCROLL);
		else
			_style(_style() & ~LBS_DISABLENOSCROLL);
		
		_crecreate();
	}
	
	/// ditto
	final @property bool scrollAlwaysVisible() const // getter
	{
		return (_style() & LBS_DISABLENOSCROLL) != 0;
	}
	
	
	override @property void selectedIndex(int idx) // setter
	{
		if (isHandleCreated)
		{
			if (isMultSel())
			{
				if (idx == -1)
				{
					// Remove all selection.
					
					// Not working right.
					//prevwproc(LB_SELITEMRANGE, false, MAKELPARAM(0, ushort.max));
					
					// Get the indices directly because deselecting them during
					// selidxcollection.foreach could screw it up.
					
					int[] items = new int[_selectedIndexCollection.length];
					if (items.length != prevwproc(LB_GETSELITEMS, items.length, cast(LPARAM)cast(int*)items))
						throw new DflException("Unable to clear selected list items");
					
					foreach (int _idx; items)
					{
						prevwproc(LB_SETSEL, false, _idx);
					}
				}
				else
				{
					prevwproc(LB_SETSEL, true, idx); // TODO: ?
				}
			}
			else
			{
				prevwproc(LB_SETCURSEL, idx, 0);
			}
		}
	}
	
	override @property int selectedIndex() // getter
	{
		if (isHandleCreated)
		{
			if (isMultSel())
			{
				if (_selectedIndexCollection.length)
					return _selectedIndexCollection[0];
			}
			else
			{
				LRESULT result;
				result = prevwproc(LB_GETCURSEL, 0, 0);
				if (LB_ERR != result) // Redundant.
					return cast(int)result;
			}
		}
		return -1;
	}
	
	
	///
	final @property void selectedItem(Object o) // setter
	{
		int i = items.indexOf(o);
		if (i != -1)
			selectedIndex = i;
	}
	
	/// ditto
	final @property void selectedItem(Dstring str) // setter
	{
		int i = items.indexOf(str);
		if (i != -1)
			selectedIndex = i;
	}
	
	
	final @property Object selectedItem() // getter
	{
		int idx = selectedIndex;
		if (idx == -1)
			return null;
		return items[idx];
	}
	
	
	override @property void selectedValue(Object val) // setter
	{
		selectedItem = val;
	}
	
	override @property void selectedValue(Dstring str) // setter
	{
		selectedItem = str;
	}
	
	override @property Object selectedValue() // getter
	{
		return selectedItem;
	}
	
	
	///
	final @property inout(SelectedIndexCollection) selectedIndices() inout // getter
	{
		return _selectedIndexCollection;
	}
	
	
	///
	final @property inout(SelectedObjectCollection) selectedItems() inout // getter
	{
		return _selectedObjectCollection;
	}
	
	
	///
	@property void selectionMode(SelectionMode selmode) // setter
	{
		LONG wl = _style() & ~(LBS_NOSEL | LBS_EXTENDEDSEL | LBS_MULTIPLESEL);
		
		final switch (selmode)
		{
			case SelectionMode.ONE:
				break;
			
			case SelectionMode.MULTI_SIMPLE:
				wl |= LBS_MULTIPLESEL;
				break;
			
			case SelectionMode.MULTI_EXTENDED:
				wl |= LBS_EXTENDEDSEL;
				break;
			
			case SelectionMode.NONE:
				wl |= LBS_NOSEL;
				break;
		}
		
		_style(wl);
		
		_crecreate();
	}
	
	/// ditto
	@property SelectionMode selectionMode() const // getter
	{
		LONG wl = _style();
		
		if (wl & LBS_NOSEL)
			return SelectionMode.NONE;
		if (wl & LBS_EXTENDEDSEL)
			return SelectionMode.MULTI_EXTENDED;
		if (wl & LBS_MULTIPLESEL)
			return SelectionMode.MULTI_SIMPLE;
		return SelectionMode.ONE;
	}
	
	
	///
	final @property void sorted(bool byes) // setter
	{
		/+
		if (byes)
			_style(_style() | LBS_SORT);
		else
			_style(_style() & ~LBS_SORT);
		+/
		_sorting = byes;
	}
	
	/// ditto
	final @property bool sorted() const // getter
	{
		//return (_style() & LBS_SORT) != 0;
		return _sorting;
	}
	
	
	///
	final @property void topIndex(int idx) // setter
	{
		if (isHandleCreated)
			prevwproc(LB_SETTOPINDEX, idx, 0);
	}
	
	/// ditto
	final @property int topIndex() // getter
	{
		if (isHandleCreated)
			return prevwproc(LB_GETTOPINDEX, 0, 0).toI32;
		return 0;
	}
	
	
	///
	final @property void useTabStops(bool byes) // setter
	{
		if (byes)
			_style(_style() | LBS_USETABSTOPS);
		else
			_style(_style() & ~LBS_USETABSTOPS);
		
		_crecreate();
	}
	
	/// ditto
	final @property bool useTabStops() const // getter
	{
		return (_style() & LBS_USETABSTOPS) != 0;
	}
	
	
	///
	final void beginUpdate()
	{
		prevwproc(WM_SETREDRAW, false, 0);
	}
	
	/// ditto
	final void endUpdate()
	{
		prevwproc(WM_SETREDRAW, true, 0);
		invalidate(true); // Show updates.
	}
	
	
	package final bool isMultSel()
	{
		return (_style() & (LBS_EXTENDEDSEL | LBS_MULTIPLESEL)) != 0;
	}
	
	
	///
	final void clearSelected()
	{
		if (created)
			selectedIndex = -1;
	}
	
	
	///
	final int findString(Dstring str, int startIndex)
	{
		// TODO: find string if control not created ?
		
		int result = NO_MATCHES;
		
		if (created)
		{
			if (useUnicode)
				result = prevwproc(LB_FINDSTRING, startIndex, cast(LPARAM)toUnicodez(str)).toI32;
			else
				result = prevwproc(LB_FINDSTRING, startIndex, cast(LPARAM)unsafeAnsiz(str)).toI32;
			
			if (result == LB_ERR) // Redundant.
				result = NO_MATCHES;
		}
		
		return result;
	}
	
	/// ditto
	final int findString(Dstring str)
	{
		return findString(str, -1); // Start at beginning.
	}
	
	
	///
	final int findStringExact(Dstring str, int startIndex)
	{
		// TODO: find string if control not created ?
		
		int result = NO_MATCHES;
		
		if (created)
		{
			if (useUnicode)
				result = prevwproc(LB_FINDSTRINGEXACT, startIndex, cast(LPARAM)toUnicodez(str)).toI32;
			else
				result = prevwproc(LB_FINDSTRINGEXACT, startIndex, cast(LPARAM)unsafeAnsiz(str)).toI32;
			
			if (result == LB_ERR) // Redundant.
				result = NO_MATCHES;
		}
		
		return result;
	}
	
	/// ditto
	final int findStringExact(Dstring str)
	{
		return findStringExact(str, -1); // Start at beginning.
	}
	
	
	///
	final int getItemHeight(int idx)
	{
		int result = prevwproc(LB_GETITEMHEIGHT, idx, 0).toI32;
		if (LB_ERR == result)
			throw new DflException("Unable to obtain item height");
		return MulDiv(result, USER_DEFAULT_SCREEN_DPI, dpi);
	}
	
	
	///
	final Rect getItemRectangle(int idx)
	{
		RECT rect;
		if (LB_ERR == prevwproc(LB_GETITEMRECT, idx, cast(LPARAM)&rect))
		{
			//if (idx >= 0 && idx < items.length)
				return Rect(0, 0, 0, 0); // ?
			//throw new DflException("Unable to obtain item rectangle");
		}
		return Rect(&rect);
	}
	
	
	///
	final bool getSelected(int idx)
	{
		return prevwproc(LB_GETSEL, idx, 0) > 0;
	}
	
	
	///
	final int indexFromPoint(int x, int y)
	{
		// LB_ITEMFROMPOINT is "nearest", so also check with the item rectangle to
		// see if the point is directly in the item.
		
		// Maybe use LBItemFromPt() from common controls.
		
		int result = NO_MATCHES;
		
		if (created)
		{
			result = prevwproc(LB_ITEMFROMPOINT, 0, MAKELPARAM(x, y)).toI32;
			if (!HIWORD(result)) // In client area
			{
				//result = LOWORD(result); // High word already 0.
				if (result < 0 || !getItemRectangle(result).contains(x, y))
					result = NO_MATCHES;
			}
			else // Outside client area.
			{
				result = NO_MATCHES;
			}
		}
		
		return result;
	}
	
	/// ditto
	final int indexFromPoint(Point pt)
	{
		return indexFromPoint(pt.x, pt.y);
	}
	
	
	///
	final void setSelected(int idx, bool byes)
	{
		if (created)
			prevwproc(LB_SETSEL, byes, idx);
	}
	
	
	///
	protected ObjectCollection createItemCollection()
	{
		return new ObjectCollection(this);
	}
	
	
	///
	void sort()
	{
		if (_itemCollection._items.length)
		{
			Object[] itemscopy = _itemCollection._items.dup;
			std.algorithm.sort(itemscopy);
			
			items.clear();
			
			beginUpdate();
			scope(exit)
				endUpdate();
			
			foreach (i, Object o; itemscopy)
			{
				if (i > int.max)
					throw new DflException("sort() failure");
				items.insert(cast(int)i, o);
			}
		}
	}
	
	
	///
	static class ObjectCollection
	{
		protected this(ListBox lbox)
		{
			this._listBox = lbox;
		}
		
		
		protected this(ListBox lbox, Object[] range)
		{
			this._listBox = lbox;
			addRange(range);
		}
		
		
		protected this(ListBox lbox, Dstring[] range)
		{
			this._listBox = lbox;
			addRange(range);
		}
		
		
		/+
		protected this(ListBox lbox, ObjectCollection range)
		{
			this.lbox = lbox;
			addRange(range);
		}
		+/
		
		
		void add(Object value)
		{
			_add2(value);
		}
		
		
		void add(Dstring value)
		{
			add(new ListString(value));
		}
		
		
		void addRange(Object[] range)
		{
			if (_listBox.sorted)
			{
				foreach (Object value; range)
				{
					add(value);
				}
			}
			else
			{
				_wraparray.addRange(range);
			}
		}
		
		
		void addRange(Dstring[] range)
		{
			foreach (Dstring value; range)
			{
				add(value);
			}
		}
		
		
	private:
		
		ListBox _listBox;
		Object[] _items;
		
		
		LRESULT _insert2(WPARAM idx, Dstring val)
		{
			insert(idx.toI32, val);
			return idx;
		}
		
		
		LRESULT _add2(Object val)
		{
			int i;
			if (_listBox.sorted)
			{
				for (i = 0; i != _items.length.toI32; i++)
				{
					if (val < _items[i])
						break;
				}
			}
			else
			{
				i = _items.length.toI32;
			}
			
			insert(i, val);
			
			return i;
		}
		
		
		LRESULT _add2(Dstring val)
		{
			return _add2(new ListString(val));
		}
		
		
		void _added(size_t idx, Object val)
		{
			if (_listBox.created)
			{
				if (useUnicode)
					_listBox.prevwproc(LB_INSERTSTRING, idx, cast(LPARAM)toUnicodez(getObjectString(val)));
				else
					_listBox.prevwproc(LB_INSERTSTRING, idx, cast(LPARAM)toAnsiz(getObjectString(val))); // Can this be unsafeAnsiz()?
			}
		}
		
		
		void _removed(size_t idx, Object val)
		{
			if (size_t.max == idx) // Clear all.
			{
				if (_listBox.created)
				{
					_listBox.prevwproc(LB_RESETCONTENT, 0, 0);
				}
			}
			else
			{
				if (_listBox.created)
				{
					_listBox.prevwproc(LB_DELETESTRING, cast(WPARAM)idx, 0);
				}
			}
		}
		
		
	public:
		
		mixin ListWrapArray!(Object, _items,
			_blankListCallback!(Object), _added,
			_blankListCallback!(Object), _removed,
			true, false, false) _wraparray;
	}
	
	
	this()
	{
		_initListbox();
		
		// Default useTabStops and vertical scrolling.
		_windowStyle |= WS_CHILD | WS_TABSTOP | LBS_USETABSTOPS | LBS_HASSTRINGS | WS_VSCROLL | LBS_NOTIFY;
		_windowStyleEx |= WS_EX_CLIENTEDGE;
		_controlStyle |= ControlStyles.SELECTABLE;
		_windowClassStyle = listboxClassStyle;
		
		_itemCollection = createItemCollection();
		_selectedIndexCollection = new SelectedIndexCollection(this);
		_selectedObjectCollection = new SelectedObjectCollection(this);
	}
	
	
	protected override void onHandleCreated(EventArgs ea)
	{
		super.onHandleCreated(ea);
		
		// Set the Ctrl ID to the HWND so that it is unique
		// and WM_MEASUREITEM will work properly.
		SetWindowLongPtrA(_hwnd, GWL_ID, cast(LONG_PTR)_hwnd);
		
		if (_horizontalExtent != 0)
			prevwproc(LB_SETHORIZONTALEXTENT, _horizontalExtent, 0);
		
		if (_itemHeight != DEFAULT_ITEM_HEIGHT)
			prevwproc(LB_SETITEMHEIGHT, 0, MAKELPARAM(MulDiv(_itemHeight, dpi, USER_DEFAULT_SCREEN_DPI), 0));
		
		Message m;
		m.hWnd = handle;
		m.msg = LB_INSERTSTRING;

		foreach (i, Object obj; _itemCollection._items)
		{
			m.wParam = i;

			static if (useUnicode)
				m.lParam = cast(LPARAM)toUnicodez(getObjectString(obj));
			else
				m.lParam = cast(LPARAM)toAnsiz(getObjectString(obj)); // Can this be unsafeAnsiz?
			
			prevWndProc(m);
			//if (LB_ERR == m.result || LB_ERRSPACE == m.result)
			if (m.result < 0)
				throw new DflException("Unable to add list item");
			
			//prevwproc(LB_SETITEMDATA, m.result, cast(LPARAM)cast(void*)obj);
		}
		
		//redrawEntire();
	}
	
	
	/+
	override void createHandle()
	{
		if (isHandleCreated)
			return;
		
		createClassHandle(LISTBOX_CLASSNAME);
		
		onHandleCreated(EventArgs.empty);
	}
	+/
	
	
	protected override void createParams(ref CreateParams cp)
	{
		super.createParams(cp);
		
		cp.className = LISTBOX_CLASSNAME;
		cp.style |= LBS_NOINTEGRALHEIGHT;
	}
	
	
	Event!(ListBox, DrawItemEventArgs) drawItem; ///
	Event!(ListBox, MeasureItemEventArgs) measureItem; ///
	
	
protected:
	
	///
	void onDrawItem(DrawItemEventArgs dieh)
	{
		drawItem(this, dieh);
	}
	
	
	///
	void onMeasureItem(MeasureItemEventArgs miea)
	{
		measureItem(this, miea);
	}
	
	
	package final void _WmDrawItem(DRAWITEMSTRUCT* dis)
	in
	{
		assert(dis.hwndItem == handle);
		assert(dis.CtlType == ODT_LISTBOX);
	}
	do
	{
		DrawItemState state = cast(DrawItemState)dis.itemState;
		
		if (dis.itemID == -1)
		{
			FillRect(dis.hDC, &dis.rcItem, backgroundHbrush);
			if (state & DrawItemState.FOCUS)
				DrawFocusRect(dis.hDC, &dis.rcItem);
		}
		else
		{
			Color bc, fc;
			
			if (state & DrawItemState.SELECTED)
			{
				bc = Color.systemColor(COLOR_HIGHLIGHT);
				fc = Color.systemColor(COLOR_HIGHLIGHTTEXT);
			}
			else
			{
				bc = backColor;
				fc = foreColor;
			}
			
			prepareDc(dis.hDC);
			DrawItemEventArgs diea = new DrawItemEventArgs(new Graphics(dis.hDC, false), _windowFont,
				Rect(&dis.rcItem), dis.itemID, state, fc, bc);
			
			onDrawItem(diea);
		}
	}
	
	
	package final void _WmMeasureItem(MEASUREITEMSTRUCT* mis)
	in
	{
		assert(mis.CtlType == ODT_LISTBOX);
	}
	do
	{
		scope Graphics gpx = new CommonGraphics(handle(), GetDC(handle));
		MeasureItemEventArgs miea = new MeasureItemEventArgs(gpx, mis.itemID, /+ mis.itemHeight +/ _itemHeight);
		miea.itemWidth = MulDiv(mis.itemWidth, USER_DEFAULT_SCREEN_DPI, dpi);
		
		onMeasureItem(miea);
		
		mis.itemHeight = MulDiv(miea.itemHeight, dpi , USER_DEFAULT_SCREEN_DPI);
		mis.itemWidth = MulDiv(miea.itemWidth, dpi, USER_DEFAULT_SCREEN_DPI);
	}
	
	
	override void prevWndProc(ref Message msg)
	{
		//msg.result = CallWindowProcA(listboxPrevWndProc, msg.hWnd, msg.msg, msg.wParam, msg.lParam);
		msg.result = callWindowProc(listboxPrevWndProc, msg.hWnd, msg.msg, msg.wParam, msg.lParam);
	}
	
	
	override void onReflectedMessage(ref Message m)
	{
		super.onReflectedMessage(m);
		
		switch (m.msg)
		{
			case WM_DRAWITEM:
				_WmDrawItem(cast(DRAWITEMSTRUCT*)m.lParam);
				m.result = 1;
				break;
			
			case WM_MEASUREITEM:
				_WmMeasureItem(cast(MEASUREITEMSTRUCT*)m.lParam);
				m.result = 1;
				break;
			
			case WM_COMMAND:
				assert(cast(HWND)m.lParam == handle);
				switch (HIWORD(m.wParam))
				{
					case LBN_SELCHANGE:
						onSelectedIndexChanged(EventArgs.empty);
						break;
					
					case LBN_SELCANCEL:
						onSelectedIndexChanged(EventArgs.empty);
						break;
					
					default:
				}
				break;
			
			default:
		}
	}
	

	override void onDpiChanged(uint newDpi)
	{
		// If you want to apply _itemHeight, you should call SendMessage with LB_SETITEMHEIGHT.
		//
		// LPARAM newHeight = MAKELPARAM(MulDiv(_itemHeight, this._windowDpi, USER_DEFAULT_SCREEN_DPI), 0);
		// SendMessage(handle, LB_SETITEMHEIGHT, 0, newHeight);

		// TODO: Performed once in Control.wndProc(), but perform twice as work around.
		_windowScaledFont = _createScaledFont(font, newDpi);
		SendMessage(handle, WM_SETFONT, cast(WPARAM)_windowScaledFont.handle, MAKELPARAM(true, 0));
	}

	
	override void wndProc(ref Message msg)
	{
		switch (msg.msg)
		{
			case LB_ADDSTRING:
				msg.result = _itemCollection._add2(cast(Dstring)stringFromStringz(cast(char*)msg.lParam).dup);
				return;
			
			case LB_INSERTSTRING:
				msg.result = _itemCollection._insert2(msg.wParam, cast(Dstring)stringFromStringz(cast(char*)msg.lParam).dup);
				return;
			
			case LB_DELETESTRING:
				_itemCollection.removeAt(msg.wParam.toI32);
				msg.result = _itemCollection.length;
				return;
			
			case LB_RESETCONTENT:
				_itemCollection.clear();
				return;
			
			case LB_SETITEMDATA:
				// Cannot set item data from outside DFL.
				msg.result = LB_ERR;
				return;
			
			case LB_ADDFILE:
				msg.result = LB_ERR;
				return;
			
			case LB_DIR:
				msg.result = LB_ERR;
				return;
			
			default:
				super.wndProc(msg);
		}
	}
	
	
private:
	int _horizontalExtent = 0;
	int _itemHeight = DEFAULT_ITEM_HEIGHT;
	ObjectCollection _itemCollection;
	SelectedIndexCollection _selectedIndexCollection;
	SelectedObjectCollection _selectedObjectCollection;
	bool _sorting = false;
	
	
package:
final:
	LRESULT prevwproc(UINT msg, WPARAM wparam, LPARAM lparam)
	{
		return callWindowProc(listboxPrevWndProc, _hwnd, msg, wparam, lparam);
	}
}

