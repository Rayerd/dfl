// Written by Christopher E. Miller
// See the included license.txt for copyright and license details.


///
module dfl.listview;

import dfl.application;
import dfl.base;
import dfl.collections;
import dfl.control;
import dfl.drawing;
import dfl.event;
import dfl.imagelist;

import dfl.internal.clib;
import dfl.internal.dlib;
import dfl.internal.dpiaware;
import dfl.internal.utf;

import core.sys.windows.commctrl;
import core.sys.windows.winbase;
import core.sys.windows.windef;
import core.sys.windows.wingdi;
import core.sys.windows.winuser;


private extern(Windows) void _initListview();


///
enum ListViewAlignment: ubyte
{
	TOP, ///
	DEFAULT, /// ditto
	LEFT, /// ditto
	SNAP_TO_GRID, /// ditto
}


private union CallText
{
	Dstringz ansi;
	Dwstringz unicode;
}


private CallText _getCallText(Dstring text)
{
	CallText result;
	if (text is null)
	{
		static if (useUnicode)
			result.unicode = null;
		else
			result.ansi = null;
	}
	else
	{
		static if (useUnicode)
			result.unicode = toUnicodez(text);
		else
			result.ansi = toAnsiz(text);
	}
	return result;
}


// TODO: Work around for commctrl.d.
package
{
	struct LVCOLUMN
	{
		UINT mask;
		int fmt;
		int cx;
		static if (useUnicode)
			LPWSTR pszText;
		else
			LPSTR pszText;
		int cchTextMax;
		int iSubItem;
		int iImage;
		int iOrder;
		int cxMin;
		int cxDefault;
		int cxIdeal;
	}

	enum LVCFMT_FIXED_WIDTH = 0x00100;
	enum LVCFMT_NO_DPI_SCALE = 0x40000;
	enum LVCFMT_FIXED_RATIO = 0x80000;
	enum LVCFMT_SPLITBUTTON = 0x1000000;
}


///
class ListViewSubItem: DObject
{
	///
	this()
	{
		Application.ppin(cast(void*)this);
	}
	
	/// ditto
	this(Dstring thisSubItemText)
	{
		this();
		
		settextin(thisSubItemText);
	}
	
	/// ditto
	this(ListViewItem owner, Dstring thisSubItemText)
	{
		this();
		
		settextin(thisSubItemText);
		if (owner)
		{
			this._item = owner;
			owner.subItems.add(this);
		}
	}
	
	/+
	this(Object obj) // package
	{
		this(getObjectString(obj));
	}
	+/
	
	
	package final void settextin(Dstring newText)
	{
		_calltxt = _getCallText(newText);
		_txt = newText;
	}
	
	
	override Dstring toString() const
	{
		return text;
	}
	
	
	override Dequ opEquals(Object o) const
	{
		return text == getObjectString(o);
	}
	
	
	Dequ opEquals(Dstring val) const
	{
		return text == val;
	}
	
	
	override int opCmp(Object o) const
	{
		return stringICmp(text, getObjectString(o));
	}
	
	
	int opCmp(Dstring val) const
	{
		return stringICmp(text, val);
	}
	

	override size_t toHash() const nothrow @trusted
	{
		try
		{
			return hashOf(text);
		}
		catch (Exception e)
		{
			assert(0);
		}
	}

	
	///
	final @property void text(Dstring newText) // setter
	{
		settextin(newText);
		
		if (_item && _item._parentListView && _item._parentListView.created)
		{
			int ii = _item._parentListView.items.indexOf(_item);
			assert(-1 != ii);
			int subi = _item.subItems.indexOf(this);
			assert(-1 != subi);
			_item._parentListView.updateItemText(ii, newText, subi + 1); // Sub items really start at 1 in the list view.
		}
	}
	
	/// ditto
	final @property Dstring text() const // getter
	{
		return _txt;
	}
	
	
private:
	package ListViewItem _item;
	Dstring _txt;
	package CallText _calltxt;
}


///
class ListViewItem: DObject
{
	///
	static class ListViewSubItemCollection
	{
		protected this(ListViewItem owner)
		in
		{
			assert(!owner._subItems);
		}
		do
		{
			_item = owner;
		}
		
		
	private:
		
		ListViewItem _item;
		package ListViewSubItem[] _subs;
		
		
		void _adding(size_t idx, ListViewSubItem val)
		{
			if (val._item)
				throw new DflException("ListViewSubItem already belongs to a ListViewItem");
		}
		
		
	public:
		
		mixin ListWrapArray!(ListViewSubItem, _subs,
			_adding, _blankListCallback!(ListViewSubItem),
			_blankListCallback!(ListViewSubItem), _blankListCallback!(ListViewSubItem),
			true, false, false);
	}
	
	
	///
	this()
	{
		Application.ppin(cast(void*)this);
		
		_subItems = new ListViewSubItemCollection(this);
	}
	
	/// ditto
	this(Dstring text)
	{
		this();
		
		settextin(text);
	}
	
	
	private void _setcheckstate(int thisindex, bool bchecked)
	{
		if (_parentListView && _parentListView.created)
		{
			LV_ITEMA li;
			li.stateMask = LVIS_STATEIMAGEMASK; // Bits 12 through 15 of the member state
			li.state = cast(UINT)(bchecked ? 2 : 1) << 12;
			_parentListView.prevwproc(LVM_SETITEMSTATE, cast(WPARAM)thisindex, cast(LPARAM)&li);
		}
	}
	
	
	private bool _getcheckstate(int thisindex)
	{
		if (_parentListView && _parentListView.created)
		{
			if ((_parentListView.prevwproc(LVM_GETITEMSTATE, cast(WPARAM)thisindex, LVIS_STATEIMAGEMASK) >> 12) - 1)
				return true;
		}
		return false;
	}
	
	
	///
	final @property void checked(bool byes) // setter
	{
		return _setcheckstate(index, byes);
	}
	
	/// ditto
	final @property bool checked() // getter
	{
		return _getcheckstate(index);
	}
	
	
	package final void settextin(Dstring newText)
	{
		_calltxt = _getCallText(newText);
		_txt = newText;
	}
	
	
	override Dstring toString() const
	{
		return text;
	}
	
	
	override Dequ opEquals(Object o) const
	{
		return text == getObjectString(o);
	}
	
	
	Dequ opEquals(Dstring val) const
	{
		return text == val;
	}
	
	
	override int opCmp(Object o) const
	{
		return stringICmp(text, getObjectString(o));
	}
	
	
	int opCmp(Dstring val) const
	{
		return stringICmp(text, val);
	}
	

	override size_t toHash() const nothrow @trusted
	{
		try
		{
			return hashOf(text);
		}
		catch (Exception e)
		{
			assert(0);
		}
	}

	
	///
	final @property Rect bounds() // getter
	{
		if (_parentListView)
		{
			int i = index;
			assert(-1 != i);
			return _parentListView.getItemRect(i);
		}
		return Rect(0, 0, 0, 0);
	}
	
	
	///
	final @property int index() // getter
	{
		if (_parentListView)
			return _parentListView._litems.indexOf(this);
		return -1;
	}
	
	
	///
	final @property void text(Dstring newText) // setter
	{
		settextin(newText);
		
		if (_parentListView && _parentListView.created)
			_parentListView.updateItemText(this, newText);
	}
	
	/// ditto
	final @property Dstring text() const // getter
	{
		return _txt;
	}
	
	
	///
	final @property void selected(bool byes) // setter
	{
		if (_parentListView && _parentListView.created)
		{
			LV_ITEMA li;
			li.stateMask = LVIS_SELECTED;
			if (byes)
				li.state = LVIS_SELECTED;
			_parentListView.prevwproc(LVM_SETITEMSTATE, cast(WPARAM)index, cast(LPARAM)&li);
		}
	}
	
	/// ditto
	final @property bool selected() // getter
	{
		if (_parentListView && _parentListView.created)
		{
			if (_parentListView.prevwproc(LVM_GETITEMSTATE, cast(WPARAM)index, LVIS_SELECTED))
				return true;
		}
		return false;
	}
	
	
	///
	final @property ListView listView() // getter
	{
		return _parentListView;
	}
	
	
	///
	final @property void tag(Object obj) // setter
	{
		_tag = obj;
	}
	
	/// ditto
	final @property Object tag() // getter
	{
		return _tag;
	}
	
	
	final void beginEdit()
	{
		if (_parentListView && _parentListView.created)
		{
			static if (dfl.internal.utf.useUnicode)
			{
				_parentListView.prevwproc(LVM_EDITLABELW, index, 0);
			}
			else
			{
				_parentListView.prevwproc(LVM_EDITLABELA, index, 0);
			}
		}
	}
	
	
	///
	final @property ListViewSubItemCollection subItems() // getter
	{
		return _subItems;
	}
	
	
	///
	final @property void imageIndex(int index) // setter
	{
		this._imgidx = index;
		
		if (_parentListView && _parentListView.created)
			_parentListView.updateItem(this);
	}
	
	/// ditto
	final @property int imageIndex() // getter
	{
		return _imgidx;
	}
	
	
private:
	package ListView _parentListView = null;
	Object _tag = null;
	package ListViewSubItemCollection _subItems = null;
	int _imgidx = -1;
	Dstring _txt;
	package CallText _calltxt;
}


///
class ColumnHeader: DObject
{
	///
	this(Dstring text)
	{
		this();
		
		this._txt = text;
	}
	
	/// ditto
	this()
	{
		Application.ppin(cast(void*)this);
	}
	
	
	///
	final @property ListView listView() // getter
	{
		return _parentListView;
	}
	
	
	///
	final @property void text(Dstring newText) // setter
	{
		_txt = newText;
		
		if (_parentListView && _parentListView.created)
		{
			_parentListView.updateColumnText(this, newText);
		}
	}
	
	/// ditto
	final @property Dstring text() const // getter
	{
		return _txt;
	}
	
	
	override Dstring toString() const
	{
		return text;
	}
	
	
	override Dequ opEquals(Object o) const
	{
		return text == getObjectString(o);
	}
	
	
	Dequ opEquals(Dstring val) const
	{
		return text == val;
	}
	
	
	override int opCmp(Object o) const
	{
		return stringICmp(text, getObjectString(o));
	}
	
	
	int opCmp(Dstring val) const
	{
		return stringICmp(text, val);
	}
	
	
	override size_t toHash() const nothrow @trusted
	{
		try
		{
			return hashOf(text);
		}
		catch (Exception e)
		{
			assert(0);
		}
	}


	///
	final @property int index() // getter
	{
		if (_parentListView)
			_parentListView._cols.indexOf(this);
		return -1;
	}
	
	
	///
	final @property void textAlign(HorizontalAlignment halign) // setter
	{
		_align = halign;
		
		if (_parentListView && _parentListView.created)
		{
			_parentListView.updateColumnAlign(this, halign);
		}
	}
	
	/// ditto
	final @property HorizontalAlignment textAlign() // getter
	{
		return _align;
	}
	
	
	///
	final @property void width(int w) // setter
	{
		_width = w;

		if (_parentListView && _parentListView.created)
		{
			_parentListView.updateColumnWidth(this, w);
		}
	}
	
	/// ditto
	final @property int width() // getter
	{
		return _width;
	}
	
	
private:
	package ListView _parentListView;
	Dstring _txt;
	int _width;
	HorizontalAlignment _align;
}


///
class LabelEditEventArgs: EventArgs
{
	///
	this(ListViewItem item, Dstring label)
	{
		_item = item;
		_label = label;
	}
	
	/// ditto
	this(ListViewItem node)
	{
		_item = item;
	}
	
	
	///
	final @property ListViewItem item() // getter
	{
		return _item;
	}
	
	
	///
	final @property Dstring label() // getter
	{
		return _label;
	}
	
	
	///
	final @property void cancelEdit(bool byes) // setter
	{
		_cancel = byes;
	}
	
	/// ditto
	final @property bool cancelEdit() // getter
	{
		return _cancel;
	}
	
	
private:
	ListViewItem _item;
	Dstring _label;
	bool _cancel = false;
}


/+
class ItemCheckEventArgs: EventArgs
{
	this(int index, CheckState newCheckState, CheckState oldCheckState)
	{
		this._idx = index;
		this._ncs = newCheckState;
		this._ocs = oldCheckState;
	}
	
	
	final @property CheckState currentValue() // getter
	{
		return _ocs;
	}
	
	
	/+
	final @property void newValue(CheckState cs) // setter
	{
		_ncs = cs;
	}
	+/
	
	
	final @property CheckState newValue() // getter
	{
		return _ncs;
	}
	
	
	private:
	int _idx;
	CheckState _ncs, _ocs;
}
+/


class ItemCheckedEventArgs: EventArgs
{
	this(ListViewItem item)
	{
		this._item = item;
	}
	
	
	final @property ListViewItem item() // getter
	{
		return this._item;
	}
	
	
private:
	ListViewItem _item;
}


///
class ListView: ControlSuperClass // docmain
{
	///
	static class ListViewItemCollection
	{
		protected this(ListView lv)
		in
		{
			assert(lv._litems is null);
		}
		do
		{
			this._parentListView = lv;
		}
		
		
		void add(ListViewItem item)
		{
			int ii = -1; // Insert index.
			
			switch (_parentListView.sorting)
			{
				case SortOrder.NONE: // Add to end.
					ii = _items.length.toI32;
					break;
				
				case SortOrder.ASCENDING: // Insertion sort.
					for (ii = 0; ii != _items.length.toI32; ii++)
					{
						assert(_parentListView._sortproc);
						//if (item < _items[ii])
						if (_parentListView._sortproc(item, _items[ii]) < 0)
							break;
					}
					break;
				
				case SortOrder.DESCENDING: // Insertion sort.
					for (ii = 0; ii != _items.length.toI32; ii++)
					{
						assert(_parentListView._sortproc);
						//if (item >= _items[ii])
						if (_parentListView._sortproc(item, _items[ii]) >= 0)
							break;
					}
					break;
				
				default:
					assert(0);
			}
			
			assert(-1 != ii);
			insert(ii, item);
		}
		
		void add(Dstring text)
		{
			return add(new ListViewItem(text));
		}
		
		
		// addRange must have special case in case of sorting.
		
		void addRange(ListViewItem[] range)
		{
			foreach (ListViewItem item; range)
			{
				add(item);
			}
		}
		
		/+
		void addRange(Object[] range)
		{
			foreach (Object o; range)
			{
				add(o);
			}
		}
		+/
		
		void addRange(Dstring[] range)
		{
			foreach (Dstring s; range)
			{
				add(s);
			}
		}
		
		
	private:
		
		ListView _parentListView;
		package ListViewItem[] _items;
		
		
		package @property bool created() // getter
		{
			return _parentListView && _parentListView.created();
		}
		
		
		package void doListItems() // DMD 0.125: this member is not accessible when private.
		in
		{
			assert(created);
		}
		do
		{
			int ii;
			foreach (i, ListViewItem item; _items)
			{
				if (i > int.max)
					throw new DflException("doListItems() failure");
				ii = _parentListView._ins(cast(int)i, item);
				//assert(-1 != ii);
				assert(i == ii);
				
				/+
				// Add sub items.
				foreach (int subi, ListViewSubItem subItem; item.isubs._subs)
				{
					_listview._ins(i, subItem, subi + 1); // Sub items really start at 1 in the list view.
				}
				+/
			}
		}
		
		
		void verifyNoParent(ListViewItem item)
		{
			if (item._parentListView)
				throw new DflException("ListViewItem already belongs to a ListView");
		}
		
		
		void _adding(size_t idx, ListViewItem val)
		{
			verifyNoParent(val);
		}
		
		
		void _added(size_t idx, ListViewItem val)
		{
			val._parentListView = _parentListView;
			
			int i;
			if (created)
			{
				i = _parentListView._ins(idx.toI32, val);
				assert(-1 != i);
			}
		}
		
		
		void _removed(size_t idx, ListViewItem val)
		{
			if (size_t.max == idx) // Clear all.
			{
				if (created)
				{
					_parentListView.prevwproc(LVM_DELETEALLITEMS, 0, 0);
				}
			}
			else
			{
				if (created)
				{
					_parentListView.prevwproc(LVM_DELETEITEM, cast(WPARAM)idx, 0);
				}
			}
		}
		
		
	public:
		
		mixin ListWrapArray!(ListViewItem, _items,
			_adding, _added,
			_blankListCallback!(ListViewItem), _removed,
			true, false, false);
	}
	
	
	///
	static class ColumnHeaderCollection
	{
		protected this(ListView owner)
		in
		{
			assert(!owner._cols);
		}
		do
		{
			_parentListView = owner;
		}
		
		
	private:
		ListView _parentListView;
		ColumnHeader[] _headers;
		
		
		package @property bool created() // getter
		{
			return _parentListView && _parentListView.created();
		}
		
		
		void verifyNoParent(ColumnHeader header)
		{
			if (header._parentListView)
				throw new DflException("ColumnHeader already belongs to a ListView");
		}
		
		
		package void doListHeaders() // DMD 0.125: this member is not accessible when private.
		in
		{
			assert(created);
		}
		do
		{
			int ii;
			foreach (i, ColumnHeader header; _headers)
			{
				if (i > int.max)
					throw new DflException("doListHeaders() failure");
				ii = _parentListView._ins(cast(int)i, header);
				assert(-1 != ii);
				//assert(i == ii);
			}
		}
		
		
		void _adding(size_t idx, ColumnHeader val)
		{
			verifyNoParent(val);
		}
		
		
		void _added(size_t idx, ColumnHeader val)
		{
			val._parentListView = _parentListView;
			
			int i;
			if (created)
			{
				i = _parentListView._ins(idx.toI32, val);
				assert(-1 != i);
			}
		}
		
		
		void _removed(size_t idx, ColumnHeader val)
		{
			if (size_t.max == idx) // Clear all.
			{
			}
			else
			{
				if (created)
				{
					_parentListView.prevwproc(LVM_DELETECOLUMN, cast(WPARAM)idx, 0);
				}
			}
		}
		
		
	public:
		
		mixin ListWrapArray!(ColumnHeader, _headers,
			_adding, _added,
			_blankListCallback!(ColumnHeader), _removed,
			true, false, false,
			true); // CLEAR_EACH
	}
	
	
	///
	static class SelectedIndexCollection
	{
		@property int length() // getter
		{
			if (!_parentListView.created)
				return 0;
			
			int result = 0;
			foreach (int onidx; this)
			{
				result++;
			}
			return result;
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
			if (!_parentListView.created)
				return 0;
			
			int result = 0;
			int idx = -1;
			for (;;)
			{
				idx = cast(int)_parentListView.prevwproc(LVM_GETNEXTITEM, cast(WPARAM)idx, MAKELPARAM(cast(UINT)LVNI_SELECTED, 0));
				if (-1 == idx) // Done.
					break;
				int dgidx = idx; // Prevent ref.
				result = dg(dgidx);
				if (result)
					break;
			}
			return result;
		}
		
		mixin OpApplyAddIndex!(opApply, int);
		
		
		protected this(ListView lv)
		{
			_parentListView = lv;
		}
		
		
	package:
		ListView _parentListView;
	}
	
	
	///
	static class SelectedItemCollection
	{
		@property int length() // getter
		{
			if (!_parentListView.created)
				return 0;
			
			int result = 0;
			foreach (ListViewItem onitem; this)
			{
				result++;
			}
			return result;
		}
		
		
		ListViewItem opIndex(int idx)
		{
			foreach (ListViewItem onitem; this)
			{
				if (!idx)
					return onitem;
				idx--;
			}
			
			// If it's not found it's out of bounds and bad things happen.
			assert(0);
		}
		
		
		bool contains(ListViewItem item)
		{
			return indexOf(item) != -1;
		}
		
		
		int indexOf(ListViewItem item)
		{
			int i = 0;
			foreach (ListViewItem onitem; this)
			{
				if (onitem == item) // Not using is.
					return i;
				i++;
			}
			return -1;
		}
		
		
		int opApply(int delegate(ref ListViewItem) dg)
		{
			if (!_parentListView.created)
				return 0;
			
			int result = 0;
			int idx = -1;
			for (;;)
			{
				idx = cast(int)_parentListView.prevwproc(LVM_GETNEXTITEM, cast(WPARAM)idx, MAKELPARAM(cast(UINT)LVNI_SELECTED, 0));
				if (-1 == idx) // Done.
					break;
				ListViewItem litem = _parentListView._litems._items[idx]; // Prevent ref.
				result = dg(litem);
				if (result)
					break;
			}
			return result;
		}
		
		mixin OpApplyAddIndex!(opApply, ListViewItem);
		
		
		protected this(ListView lv)
		{
			_parentListView = lv;
		}
		
		
	package:
		ListView _parentListView;
	}
	
	
	///
	static class CheckedIndexCollection
	{
		@property int length() // getter
		{
			if (!_parentListView.created)
				return 0;
			
			int result = 0;
			foreach (int onidx; this)
			{
				result++;
			}
			return result;
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
			if (!_parentListView.created)
				return 0;
			
			int result = 0;
			foreach (ref size_t i, ref ListViewItem lvitem; _parentListView.items)
			{
				if (lvitem._getcheckstate(i.toI32))
				{
					int dgidx = i.toI32; // Prevent ref.
					result = dg(dgidx);
					if (result)
						break;
				}
			}
			return result;
		}
		
		mixin OpApplyAddIndex!(opApply, int);
		
		
		protected this(ListView lv)
		{
			_parentListView = lv;
		}
		
		
	package:
		ListView _parentListView;
	}
	
	
	this()
	{
		_initListview();
		
		_litems = new ListViewItemCollection(this);
		_cols = new ColumnHeaderCollection(this);
		_selidxcollection = new SelectedIndexCollection(this);
		_selobjcollection = new SelectedItemCollection(this);
		_checkedis = new CheckedIndexCollection(this);

		_windowStyle |= WS_TABSTOP | LVS_ALIGNTOP | LVS_AUTOARRANGE | LVS_SHAREIMAGELISTS;
		_windowStyleEx |= WS_EX_CLIENTEDGE;
		_controlStyle |= ControlStyles.SELECTABLE;
		_windowClassStyle = listviewClassStyle;
	}
	
	
	///
	final @property void activation(ItemActivation ia) // setter
	{
		final switch (ia)
		{
			case ItemActivation.STANDARD:
				_lvexstyle(LVS_EX_ONECLICKACTIVATE | LVS_EX_TWOCLICKACTIVATE, 0);
				break;
			
			case ItemActivation.ONE_CLICK:
				_lvexstyle(LVS_EX_ONECLICKACTIVATE | LVS_EX_TWOCLICKACTIVATE, LVS_EX_ONECLICKACTIVATE);
				break;
			
			case ItemActivation.TWO_CLICK:
				_lvexstyle(LVS_EX_ONECLICKACTIVATE | LVS_EX_TWOCLICKACTIVATE, LVS_EX_TWOCLICKACTIVATE);
				break;
		}
	}
	
	/// ditto
	final @property ItemActivation activation() const // getter
	{
		DWORD lvex = _lvexstyle();
		if (lvex & LVS_EX_ONECLICKACTIVATE)
			return ItemActivation.ONE_CLICK;
		if (lvex & LVS_EX_TWOCLICKACTIVATE)
			return ItemActivation.TWO_CLICK;
		return ItemActivation.STANDARD;
	}
	
	
	/+
	///
	final void alignment(ListViewAlignment lva)
	{
		// TODO
		
		switch (lva)
		{
			case ListViewAlignment.TOP:
				_style((_style() & ~(LVS_ALIGNLEFT | foo)) | LVS_ALIGNTOP);
				break;
			
			default:
				assert(0);
		}
	}
	
	/// ditto
	final @property ListViewAlignment alignment() // getter
	{
		// TODO
	}
	+/
	
	
	///
	final @property void allowColumnReorder(bool byes) // setter
	{
		_lvexstyle(LVS_EX_HEADERDRAGDROP, byes ? LVS_EX_HEADERDRAGDROP : 0);
	}
	
	/// ditto
	final @property bool allowColumnReorder() const // getter
	{
		return (_lvexstyle() & LVS_EX_HEADERDRAGDROP) == LVS_EX_HEADERDRAGDROP;
	}
	
	
	///
	final @property void autoArrange(bool byes) // setter
	{
		if (byes)
			_style(_style() | LVS_AUTOARRANGE);
		else
			_style(_style() & ~LVS_AUTOARRANGE);
		
		//_crecreate(); // ?
	}
	
	/// ditto
	final @property bool autoArrange() const // getter
	{
		return (_style() & LVS_AUTOARRANGE) == LVS_AUTOARRANGE;
	}
	
	
	override @property void backColor(Color c) // setter
	{
		if (created)
		{
			COLORREF cref = {
				if (Color.empty == c)
					return CLR_NONE;
				else
					return c.toRgb();
			}();
			prevwproc(LVM_SETBKCOLOR, 0, cast(LPARAM)cref);
			prevwproc(LVM_SETTEXTBKCOLOR, 0, cast(LPARAM)cref);
		}
		
		super.backColor = c;
	}
	
	
	override @property Color backColor() const // getter
	{
		if (Color.empty == _backColor)
			return defaultBackColor;
		return _backColor;
	}
	
	
	///
	final @property void borderStyle(BorderStyle bs) // setter
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
		
		if (created)
		{
			redrawEntire();
		}
	}
	
	/// ditto
	final @property BorderStyle borderStyle() const // getter
	{
		if (_exStyle() & WS_EX_CLIENTEDGE)
			return BorderStyle.FIXED_3D;
		else if (_style() & WS_BORDER)
			return BorderStyle.FIXED_SINGLE;
		return BorderStyle.NONE;
	}
	
	
	///
	final @property void checkBoxes(bool byes) // setter
	{
		_lvexstyle(LVS_EX_CHECKBOXES, byes ? LVS_EX_CHECKBOXES : 0);
	}
	
	/// ditto
	final @property bool checkBoxes() const // getter
	{
		return (_lvexstyle() & LVS_EX_CHECKBOXES) == LVS_EX_CHECKBOXES;
	}
	
	
	///
	// ListView.CheckedIndexCollection
	final @property inout(CheckedIndexCollection) checkedIndices() inout // getter
	{
		return _checkedis;
	}
	
	
	/+
	///
	// ListView.CheckedListViewItemCollection
	final @property CheckedListViewItemCollection checkedItems() // getter
	{
		// TODO
	}
	+/
	
	
	///
	final @property inout(ColumnHeaderCollection) columns() inout // getter
	{
		return _cols;
	}
	
	
	///
	// Extra.
	final @property int focusedIndex() // getter
	{
		if (!created)
			return -1;
		return cast(int)prevwproc(LVM_GETNEXTITEM, cast(WPARAM)-1, MAKELPARAM(cast(UINT)LVNI_FOCUSED, 0));
	}
	
	
	///
	final @property ListViewItem focusedItem() // getter
	{
		int i = focusedIndex;
		if (-1 == i)
			return null;
		return _litems._items[i];
	}
	
	
	override @property void foreColor(Color c) // setter
	{
		if (created)
			prevwproc(LVM_SETTEXTCOLOR, 0, cast(LPARAM)c.toRgb());
		
		super.foreColor = c;
	}
	
	
	override @property Color foreColor() const // getter
	{
		if (Color.empty == _foreColor)
			return defaultForeColor;
		return _foreColor;
	}
	
	
	///
	final @property void fullRowSelect(bool byes) // setter
	{
		_lvexstyle(LVS_EX_FULLROWSELECT, byes ? LVS_EX_FULLROWSELECT : 0);
	}
	
	/// ditto
	final @property bool fullRowSelect() const // getter
	{
		return (_lvexstyle() & LVS_EX_FULLROWSELECT) == LVS_EX_FULLROWSELECT;
	}
	
	
	///
	final @property void gridLines(bool byes) // setter
	{
		_lvexstyle(LVS_EX_GRIDLINES, byes ? LVS_EX_GRIDLINES : 0);
	}
	
	/// ditto
	final @property bool gridLines() const // getter
	{
		return (_lvexstyle() & LVS_EX_GRIDLINES) == LVS_EX_GRIDLINES;
	}
	
	
	/+
	///
	final @property void headerStyle(ColumnHeaderStyle chs) // setter
	{
		// TODO: LVS_NOCOLUMNHEADER ... default is clickable.
	}
	
	/// ditto
	final @property ColumnHeaderStyle headerStyle() // getter
	{
		// TODO
	}
	+/
	
	
	///
	final @property void hideSelection(bool byes) // setter
	{
		if (byes)
			_style(_style() & ~LVS_SHOWSELALWAYS);
		else
			_style(_style() | LVS_SHOWSELALWAYS);
	}
	
	/// ditto
	final @property bool hideSelection() const // getter
	{
		return (_style() & LVS_SHOWSELALWAYS) != LVS_SHOWSELALWAYS;
	}
	
	
	///
	final @property void hoverSelection(bool byes) // setter
	{
		_lvexstyle(LVS_EX_TRACKSELECT, byes ? LVS_EX_TRACKSELECT : 0);
	}
	
	/// ditto
	final @property bool hoverSelection() const // getter
	{
		return (_lvexstyle() & LVS_EX_TRACKSELECT) == LVS_EX_TRACKSELECT;
	}
	
	
	///
	final @property inout(ListViewItemCollection) items() inout // getter
	{
		return _litems;
	}
	
	
	///
	// Simple as addRow("item", "sub item1", "sub item2", "etc");
	// rowstrings[0] is the item and rowstrings[1 .. rowstrings.length] are its sub items.
	//final void addRow(Dstring[] rowstrings ...)
	final ListViewItem addRow(Dstring[] rowstrings ...)
	{
		if (rowstrings.length)
		{
			ListViewItem item = new ListViewItem(rowstrings[0]);
			if (rowstrings.length > 1)
				item.subItems.addRange(rowstrings[1 .. rowstrings.length]);
			items.add(item);
			return item;
		}
		assert(0);
	}
	
	
	///
	final @property void labelEdit(bool byes) // setter
	{
		if (byes)
			_style(_style() | LVS_EDITLABELS);
		else
			_style(_style() & ~LVS_EDITLABELS);
	}
	
	/// ditto
	final @property bool labelEdit() const // getter
	{
		return (_style() & LVS_EDITLABELS) == LVS_EDITLABELS;
	}
	
	
	///
	final @property void labelWrap(bool byes) // setter
	{
		if (byes)
			_style(_style() & ~LVS_NOLABELWRAP);
		else
			_style(_style() | LVS_NOLABELWRAP);
	}
	
	/// ditto
	final @property bool labelWrap() const // getter
	{
		return (_style() & LVS_NOLABELWRAP) != LVS_NOLABELWRAP;
	}
	
	
	///
	final @property void multiSelect(bool byes) // setter
	{
		if (byes)
		{
			_style(_style() & ~LVS_SINGLESEL);
		}
		else
		{
			_style(_style() | LVS_SINGLESEL);
			
			if (selectedItems.length > 1)
				selectedItems[0].selected = true; // Clear all but first selected.
		}
	}
	
	/// ditto
	final @property bool multiSelect() const // getter
	{
		return (_style() & LVS_SINGLESEL) != LVS_SINGLESEL;
	}
	
	
	///
	// NOTE: scrollable=false is not compatible with the list or details(report) styles(views).
	// See Knowledge Base Article Q137520.
	final @property void scrollable(bool byes) // setter
	{
		if (byes)
			_style(_style() & ~LVS_NOSCROLL);
		else
			_style(_style() | LVS_NOSCROLL);
		
		_crecreate();
	}
	
	/// ditto
	final @property bool scrollable() const // getter
	{
		return (_style() & LVS_NOSCROLL) != LVS_NOSCROLL;
	}
	
	
	///
	final @property inout(SelectedIndexCollection) selectedIndices() inout // getter
	{
		return _selidxcollection;
	}
	
	
	///
	final @property inout(SelectedItemCollection) selectedItems() inout // getter
	{
		return _selobjcollection;
	}
	
	
	///
	final @property void view(View v) // setter
	{
		final switch (v)
		{
			case View.LARGE_ICON:
				_style((_style() & ~LVS_TYPEMASK) | LVS_ICON);
				break;
			
			case View.SMALL_ICON:
				_style((_style() & ~LVS_TYPEMASK) | LVS_SMALLICON);
				break;
			
			case View.LIST:
				_style((_style() & ~LVS_TYPEMASK) | LVS_LIST);
				break;
			
			case View.DETAILS:
				_style((_style() & ~LVS_TYPEMASK) | LVS_REPORT);
		}
		
		if (created)
		{
			arrangeIcons();
			redrawEntire();
		}
	}
	
	/// ditto
	final @property View view() const // getter
	{
		LONG st = _style();
		if (st & LVS_SMALLICON)
			return View.SMALL_ICON;
		if (st & LVS_LIST)
			return View.LIST;
		if (st & LVS_REPORT)
			return View.DETAILS;
		return View.LARGE_ICON;
	}
	
	
	///
	final @property void sorting(SortOrder so) // setter
	{
		if (so == _sortorder)
			return;
		
		final switch (so)
		{
			case SortOrder.NONE:
				_sortproc = null;
				break;
			
			case SortOrder.ASCENDING:
			case SortOrder.DESCENDING:
				if (!_sortproc)
					_sortproc = &_defsortproc;
				break;
		}
		
		_sortorder = so;
		
		sort();
	}
	
	/// ditto
	final @property SortOrder sorting() const // getter
	{
		return _sortorder;
	}
	
	
	///
	final void sort()
	{
		if (SortOrder.NONE != _sortorder)
		{
			assert(_sortproc);
			ListViewItem[] sitems = items._items;
			if (sitems.length > 1)
			{
				sitems = sitems.dup; // So exception won't damage anything.
				// Stupid bubble sort. At least it's a "stable sort".
				bool swp;
				auto sortmax = sitems.length + (-1);
				do
				{
					swp = false;
					for (size_t iw = 0; iw != sortmax; iw++)
					{
						//if (sitems[iw] > sitems[iw + 1])
						if (_sortproc(sitems[iw], sitems[iw + 1]) > 0)
						{
							swp = true;
							ListViewItem lvis = sitems[iw];
							sitems[iw] = sitems[iw + 1];
							sitems[iw + 1] = lvis;
						}
					}
				}
				while (swp);
				
				if (created)
				{
					beginUpdate();
					SendMessageA(handle, LVM_DELETEALLITEMS, 0, 0); // NOTE: this sends LVN_DELETEALLITEMS.
					foreach (idx, lvi; sitems)
					{
						_ins(idx.toI32, lvi);
					}
					endUpdate();
				}
				
				items._items = sitems;
			}
		}
	}
	
	
	///
	final @property void sorter(int delegate(ListViewItem, ListViewItem) sortproc) // setter
	{
		if (sortproc == this._sortproc)
			return;
		
		if (!sortproc)
		{
			this._sortproc = null;
			sorting = SortOrder.NONE;
			return;
		}
		
		this._sortproc = sortproc;
		
		if (SortOrder.NONE == sorting)
			sorting = SortOrder.ASCENDING;
		sort();
	}
	
	/// ditto
	final int delegate(ListViewItem, ListViewItem) sorter() const @property // getter
	{
		return _sortproc;
	}
	
	
	/+
	///
	// Gets the first visible item.
	final @property ListViewItem topItem() // getter
	{
		if (!created)
			return null;
		// TODO: LVM_GETTOPINDEX
	}
	+/
	
	
	///
	final @property void arrangeIcons()
	{
		if (created)
		//	SendMessageA(hwnd, LVM_ARRANGE, LVA_DEFAULT, 0);
			prevwproc(LVM_ARRANGE, LVA_DEFAULT, 0);
	}
	
	/// ditto
	final @property void arrangeIcons(ListViewAlignment a)
	{
		if (created)
		{
			final switch (a)
			{
				case ListViewAlignment.TOP:
					//SendMessageA(hwnd, LVM_ARRANGE, LVA_ALIGNTOP, 0);
					prevwproc(LVM_ARRANGE, LVA_ALIGNTOP, 0);
					break;
				
				case ListViewAlignment.DEFAULT:
					//SendMessageA(hwnd, LVM_ARRANGE, LVA_DEFAULT, 0);
					prevwproc(LVM_ARRANGE, LVA_DEFAULT, 0);
					break;
				
				case ListViewAlignment.LEFT:
					//SendMessageA(hwnd, LVM_ARRANGE, LVA_ALIGNLEFT, 0);
					prevwproc(LVM_ARRANGE, LVA_ALIGNLEFT, 0);
					break;
				
				case ListViewAlignment.SNAP_TO_GRID:
					//SendMessageA(hwnd, LVM_ARRANGE, LVA_SNAPTOGRID, 0);
					prevwproc(LVM_ARRANGE, LVA_SNAPTOGRID, 0);
					break;
			}
		}
	}
	
	
	///
	final void beginUpdate()
	{
		SendMessageA(handle, WM_SETREDRAW, false, 0);
	}
	
	/// ditto
	final void endUpdate()
	{
		SendMessageA(handle, WM_SETREDRAW, true, 0);
		invalidate(true); // Show updates.
	}
	
	
	///
	final void clear()
	{
		_litems.clear();
	}
	
	
	///
	final void ensureVisible(int index)
	{
		// Can only be visible if it's created. Check if correct implementation.
		createControl();
		
		//if (created)
		//	SendMessageA(hwnd, LVM_ENSUREVISIBLE, cast(WPARAM)index, FALSE);
			prevwproc(LVM_ENSUREVISIBLE, cast(WPARAM)index, FALSE);
	}
	
	
	/+
	///
	// Returns null if no item is at this location.
	final ListViewItem getItemAt(int x, int y)
	{
		// LVM_FINDITEM LVFI_NEARESTXY ? since it's nearest, need to see if it's really at that location.
		// TODO
	}
	+/
	
	
	///
	final Rect getItemRect(int index)
	{
		if (created)
		{
			RECT rect;
			rect.left = LVIR_BOUNDS;
			if (prevwproc(LVM_GETITEMRECT, cast(WPARAM)index, cast(LPARAM)&rect))
				return Rect(&rect);
		}
		return Rect(0, 0, 0, 0);
	}
	
	/// ditto
	final Rect getItemRect(int index, ItemBoundsPortion ibp)
	{
		if (created)
		{
			RECT rect;
			final switch (ibp)
			{
				case ItemBoundsPortion.ENTIRE:
					rect.left = LVIR_BOUNDS;
					break;
				
				case ItemBoundsPortion.ICON:
					rect.left = LVIR_ICON;
					break;
				
				case ItemBoundsPortion.ITEM_ONLY:
					rect.left = LVIR_SELECTBOUNDS;
					break;
				
				case ItemBoundsPortion.LABEL:
					rect.left = LVIR_LABEL;
			}
			if (prevwproc(LVM_GETITEMRECT, cast(WPARAM)index, cast(LPARAM)&rect))
				return Rect(&rect);
		}
		return Rect(0, 0, 0, 0);
	}
	
	
	///
	final @property void largeImageList(ImageList imglist) // setter
	{
		if (isHandleCreated)
		{
			prevwproc(LVM_SETIMAGELIST, LVSIL_NORMAL,
				cast(LPARAM)(imglist ? imglist.handle : cast(HIMAGELIST)null));
		}
		
		_lgimglist = imglist;
	}
	
	/// ditto
	final @property inout(ImageList) largeImageList() inout // getter
	{
		return _lgimglist;
	}
	
	
	///
	final @property void smallImageList(ImageList imglist) // setter
	{
		if (isHandleCreated)
		{
			prevwproc(LVM_SETIMAGELIST, LVSIL_SMALL,
				cast(LPARAM)(imglist ? imglist.handle : cast(HIMAGELIST)null));
		}
		
		_smimglist = imglist;
	}
	
	/// ditto
	final @property inout(ImageList) smallImageList() inout // getter
	{
		return _smimglist;
	}
	
	
	/+
	///
	final @property void stateImageList(ImageList imglist) // setter
	{
		if (isHandleCreated)
		{
			prevwproc(LVM_SETIMAGELIST, LVSIL_STATE,
				cast(LPARAM)(imglist ? imglist.handle : cast(HIMAGELIST)null));
		}
		
		_stimglist = imglist;
	}
	
	/// ditto
	final @property ImageList stateImageList() // getter
	{
		return _stimglist;
	}
	+/
	
	
	///
	deprecated
	public @property void headerFont(Font newFont) // setter
	{
		if (newFont && isHandleCreated)
		{
			HWND hHeader = ListView_GetHeader(handle);
			if (hHeader)
				SendMessage(hHeader, WM_SETFONT, cast(WPARAM)newFont.handle, TRUE);
		}

		_headerFont = newFont;
	}

	/// ditto
	deprecated
	public @property Font headerFont() // getter
	{
		return _headerFont;
	}
	

	// TODO: itemActivate, itemDrag
	//Event!(ListView, CancelEventArgs) selectedIndexChanging; // TODO: ?
	Event!(ListView, ColumnClickEventArgs) columnClick; ///
	Event!(ListView, LabelEditEventArgs) afterLabelEdit; ///
	Event!(ListView, LabelEditEventArgs) beforeLabelEdit; ///
	//Event!(ListView, ItemCheckEventArgs) itemCheck; ///
	Event!(ListView, ItemCheckedEventArgs) itemChecked; ///
	Event!(ListView, EventArgs) selectedIndexChanged; ///
	
	
	///
	protected void onColumnClick(ColumnClickEventArgs ea)
	{
		columnClick(this, ea);
	}
	
	
	///
	protected void onAfterLabelEdit(LabelEditEventArgs ea)
	{
		afterLabelEdit(this, ea);
	}
	
	
	///
	protected void onBeforeLabelEdit(LabelEditEventArgs ea)
	{
		beforeLabelEdit(this, ea);
	}
	
	
	/+
	protected void onItemCheck(ItemCheckEventArgs ea)
	{
		itemCheck(this, ea);
	}
	+/
	
	
	///
	protected void onItemChecked(ItemCheckedEventArgs ea)
	{
		itemChecked(this, ea);
	}
	
	
	///
	protected void onSelectedIndexChanged(EventArgs ea)
	{
		selectedIndexChanged(this, ea);
	}
	
	
	protected override @property Size defaultSize() const // getter
	{
		return Size(120, 95);
	}
	
	
	static @property Color defaultBackColor() // getter
	{
		return SystemColors.window;
	}
	
	
	static @property Color defaultForeColor() // getter
	{
		return SystemColors.windowText;
	}
	
	
	protected override void createParams(ref CreateParams cp)
	{
		super.createParams(cp);
		
		cp.className = LISTVIEW_CLASSNAME;
	}
	
	
	protected override void onHandleCreated(EventArgs ea)
	{
		super.onHandleCreated(ea);

		_buildTreeView();
	}
	

	protected override void onDpiChanged(uint newDpi)
	{
		// BUG: ListView control size will be broken by scrollbars appearing.

		if (_lgimglist)
		{
			int spacingX = MulDiv(_lgimglist.imageSize.width + MARGIN_X, newDpi, USER_DEFAULT_SCREEN_DPI);
			int spacingY = MulDiv(_lgimglist.imageSize.height + MARGIN_Y, newDpi, USER_DEFAULT_SCREEN_DPI);
			ListView_SetIconSpacing(handle, spacingX, spacingY);
		}

		foreach (size_t colIndex, ref ColumnHeader item; this.columns)
		{
			updateColumnWidth(cast(int)colIndex, item.width);
		}
	}


	private void _buildTreeView()
	{
		//SendMessageA(hwnd, LVM_SETEXTENDEDLISTVIEWSTYLE, wlvexstyle, wlvexstyle);
		prevwproc(LVM_SETEXTENDEDLISTVIEWSTYLE, 0, _wlvexstyle); // wparam=0 sets all.
		
		{
			Color color = backColor;
			COLORREF cref = {
				if (Color.empty == color)
					return CLR_NONE;
				else
					return color.toRgb();
			}();
			prevwproc(LVM_SETBKCOLOR, 0, cast(LPARAM)cref);
			prevwproc(LVM_SETTEXTBKCOLOR, 0, cast(LPARAM)cref);
		}
		
		{
			//prevwproc(LVM_SETTEXTCOLOR, 0, foreColor.toRgb()); // DMD 0.125: cast(Control )(this).foreColor() is not an lvalue
			Color color = foreColor;
			prevwproc(LVM_SETTEXTCOLOR, 0, cast(LPARAM)color.toRgb());
		}
		
		if (_lgimglist)
			prevwproc(LVM_SETIMAGELIST, LVSIL_NORMAL, cast(LPARAM)_lgimglist.handle);
		if (_smimglist)
			prevwproc(LVM_SETIMAGELIST, LVSIL_SMALL, cast(LPARAM)_smimglist.handle);
		//if (_stimglist)
		//	prevwproc(LVM_SETIMAGELIST, LVSIL_STATE, cast(LPARAM)_stimglist.handle);
		
		_cols.doListHeaders();
		_litems.doListItems();

		static if (0)
		{
			headerFont = {
				LOGFONT lf;
				SystemParametersInfo(SPI_GETICONTITLELOGFONT, cast(UINT)lf.sizeof, &lf, 0);
				HFONT hFont = CreateFontIndirect(&lf);
				Font sysFont = new Font(hFont, true);
				// float emSize = sysFont.size;
				float emSize = sysFont.size * dpi / USER_DEFAULT_SCREEN_DPI;
				return new Font(sysFont, emSize, sysFont.style);
			}();
		}

		if (_lgimglist)
		{
			int spacingX = MulDiv(_lgimglist.imageSize.width + MARGIN_X, dpi, USER_DEFAULT_SCREEN_DPI);
			int spacingY = MulDiv(_lgimglist.imageSize.height + MARGIN_Y, dpi, USER_DEFAULT_SCREEN_DPI);
			ListView_SetIconSpacing(handle, spacingX, spacingY);
		}

		foreach (size_t colIndex, ref ColumnHeader item; this.columns)
		{
			updateColumnWidth(cast(int)colIndex, item.width);
		}

		arrangeIcons();
		recalcEntire(); // Fix frame.
	}


	protected override void wndProc(ref Message m)
	{
		// TODO: support the listview messages.
		
		switch (m.msg)
		{
			case WM_NOTIFY:
			{
				NMHDR* nmh = cast(NMHDR*)m.lParam;
				HWND hHeader = ListView_GetHeader(this.handle);
				if (nmh.hwndFrom == hHeader)
				{
					switch (nmh.code)
					{
						case HDN_ENDTRACK:
						{
							HD_NOTIFY* hdn = cast(HD_NOTIFY*)nmh;
							if (hdn.pitem && (hdn.pitem.mask & HDI_WIDTH))
							{
								int colIndex = hdn.iItem;
								int physicalWidth = ListView_GetColumnWidth(this.handle, colIndex);
								int logical96 = MulDiv(physicalWidth, USER_DEFAULT_SCREEN_DPI, dpi);
								columns[colIndex]._width = logical96;
							}
							break;
						}

						default:
							break;
					}
				}
				m.result = FALSE;
				break;
			}

			/+
			case WM_PAINT:
				// This seems to be the only way to display columns correctly.
				prevWndProc(m);
				return;
			+/
			
			case LVM_ARRANGE:
				m.result = FALSE;
				return;
			
			case LVM_DELETEALLITEMS:
				_litems.clear();
				m.result = TRUE;
				return;
			
			case LVM_DELETECOLUMN:
				_cols.removeAt(cast(int)m.wParam);
				m.result = TRUE;
				return;
			
			case LVM_DELETEITEM:
				_litems.removeAt(cast(int)m.wParam);
				m.result = TRUE;
				return;
			
			case LVM_INSERTCOLUMNA:
			case LVM_INSERTCOLUMNW:
				m.result = -1;
				return;
			
			case LVM_INSERTITEMA:
			case LVM_INSERTITEMW:
				m.result = -1;
				return;
			
			case LVM_SETBKCOLOR:
				backColor = Color.fromRgb(cast(COLORREF)m.lParam);
				m.result = TRUE;
				return;
			
			case LVM_SETCALLBACKMASK:
				m.result = FALSE;
				return;
			
			case LVM_SETCOLUMNA:
			case LVM_SETCOLUMNW:
				m.result = FALSE;
				return;
			
			case LVM_SETCOLUMNWIDTH:
				return;
			
			case LVM_SETIMAGELIST:
				m.result = cast(LRESULT)0;
				return;
			
			case LVM_SETITEMA:
				m.result = FALSE;
				return;
			
			case LVM_SETITEMSTATE:
				m.result = FALSE;
				return;
			
			case LVM_SETITEMTEXTA:
			case LVM_SETITEMTEXTW:
				m.result = FALSE;
				return;
			
			//case LVM_SETTEXTBKCOLOR:
			
			case LVM_SETTEXTCOLOR:
				foreColor = Color.fromRgb(cast(COLORREF)m.lParam);
				m.result = TRUE;
				return;
			
			case LVM_SORTITEMS:
				m.result = FALSE;
				return;
			
			default:
		}
		super.wndProc(m);
	}
	
	
	protected override void onReflectedMessage(ref Message m)
	{
		super.onReflectedMessage(m);
		
		switch (m.msg)
		{
			case WM_NOTIFY:
			{
				NMHDR* nmh = cast(NMHDR*)m.lParam;
				switch (nmh.code)
				{
					case LVN_GETDISPINFOA:
					{
						static if (dfl.internal.utf.useUnicode)
						{
							break;
						}
						else
						{
							LV_DISPINFOA* lvdi = cast(LV_DISPINFOA*)nmh;
							
							// NOTE: might want to verify it's a valid ListViewItem.
							
							ListViewItem item = cast(ListViewItem)cast(void*)lvdi.item.lParam;
							
							if (!lvdi.item.iSubItem) // Item.
							{
								if (lvdi.item.mask & LVIF_IMAGE)
									lvdi.item.iImage = item._imgidx;
								
								if (lvdi.item.mask & LVIF_TEXT)
									lvdi.item.pszText = cast(typeof(lvdi.item.pszText))item._calltxt.ansi;
							}
							else // Sub item.
							{
								if (lvdi.item.mask & LVIF_TEXT)
								{
									if (lvdi.item.iSubItem <= item.subItems.length.toI32)
										lvdi.item.pszText = cast(typeof(lvdi.item.pszText))item.subItems[lvdi.item.iSubItem - 1]._calltxt.ansi;
								}
							}
							break;
						}
					}
					
					case LVN_GETDISPINFOW:
					{
						LV_DISPINFOW* lvdi = cast(LV_DISPINFOW*)nmh;
						
						// NOTE: might want to verify it's a valid ListViewItem.
						
						ListViewItem item = cast(ListViewItem)cast(void*)lvdi.item.lParam;
						
						if (!lvdi.item.iSubItem) // Item.
						{
							if (lvdi.item.mask & LVIF_IMAGE)
								lvdi.item.iImage = item._imgidx;
							
							if (lvdi.item.mask & LVIF_TEXT)
								lvdi.item.pszText = cast(typeof(lvdi.item.pszText))item._calltxt.unicode;
						}
						else // Sub item.
						{
							if (lvdi.item.mask & LVIF_TEXT)
							{
								if (lvdi.item.iSubItem <= item.subItems.length.toI32)
									lvdi.item.pszText = cast(typeof(lvdi.item.pszText))item.subItems[lvdi.item.iSubItem - 1]._calltxt.unicode;
							}
						}
						break;
					}
					
					/+
					case LVN_ITEMCHANGING:
						{
							auto nmlv = cast(NM_LISTVIEW*)nmh;
							if (-1 != nmlv.iItem)
							{
								UINT stchg = nmlv.uNewState ^ nmlv.uOldState;
								if (stchg & (3 << 12))
								{
									// NOTE: not tested.
									scope ItemCheckEventArgs ea = new ItemCheckEventArgs(nmlv.iItem,
										(((nmlv.uNewState >> 12) & 3) - 1) ? CheckState.CHECKED : CheckState.UNCHECKED,
										(((nmlv.uOldState >> 12) & 3) - 1) ? CheckState.CHECKED : CheckState.UNCHECKED);
									onItemCheck(ea);
								}
							}
						}
						break;
					+/
					
					case LVN_ITEMCHANGED:
					{
						auto nmlv = cast(NMLISTVIEW*)nmh;
						if (-1 != nmlv.iItem)
						{
							if (nmlv.uChanged & LVIF_STATE)
							{
								UINT stchg = nmlv.uNewState ^ nmlv.uOldState;
								
								//if (stchg & LVIS_SELECTED)
								{
									// Only fire for the selected one; don't fire twice for old/new.
									if (nmlv.uNewState & LVIS_SELECTED)
									{
										onSelectedIndexChanged(EventArgs.empty);
									}
								}
								
								if (stchg & (3 << 12))
								{
									scope ItemCheckedEventArgs ea = new ItemCheckedEventArgs(items[nmlv.iItem]);
									onItemChecked(ea);
								}
							}
						}
						break;
					}
					
					case LVN_COLUMNCLICK:
					{
						auto nmlv = cast(NMLISTVIEW*)nmh;
						scope ccea = new ColumnClickEventArgs(nmlv.iSubItem);
						onColumnClick(ccea);
						break;
					}
					
					case LVN_BEGINLABELEDITW:
						goto begin_label_edit;
					
					case LVN_BEGINLABELEDITA:
					{
						static if (dfl.internal.utf.useUnicode)
							break;
					begin_label_edit:
						
						LV_DISPINFOA* nmdi = cast(LV_DISPINFOA*)nmh;
						if (nmdi.item.iSubItem)
						{
							m.result = TRUE;
							break;
						}
						ListViewItem lvitem = cast(ListViewItem)cast(void*)nmdi.item.lParam;
						scope LabelEditEventArgs leea = new LabelEditEventArgs(lvitem);
						onBeforeLabelEdit(leea);
						m.result = leea.cancelEdit;
						break;
					}
					
					case LVN_ENDLABELEDITW:
					{
						LV_DISPINFOW* nmdi = cast(LV_DISPINFOW*)nmh;
						if (nmdi.item.pszText)
						{
							ListViewItem lvitem = cast(ListViewItem)cast(void*)nmdi.item.lParam;
							if (nmdi.item.iSubItem)
							{
								m.result = FALSE;
								break;
							}
							Dstring label = fromUnicodez(nmdi.item.pszText);
							scope LabelEditEventArgs nleea = new LabelEditEventArgs(lvitem, label);
							onAfterLabelEdit(nleea);
							if (nleea.cancelEdit)
							{
								m.result = FALSE;
							}
							else
							{
								// TODO: check if correct implementation.
								// Update the lvitem's cached text..
								lvitem.settextin(label);
								
								m.result = TRUE;
							}
						}
						break;
					}
					
					case LVN_ENDLABELEDITA:
					{
						static if (dfl.internal.utf.useUnicode)
						{
							break;
						}
						else
						{
							LV_DISPINFOA* nmdi = cast(LV_DISPINFOA*)nmh;
							if (nmdi.item.pszText)
							{
								ListViewItem lvitem = cast(ListViewItem)cast(void*)nmdi.item.lParam;
								if (nmdi.item.iSubItem)
								{
									m.result = FALSE;
									break;
								}
								Dstring label = fromAnsiz(nmdi.item.pszText);
								scope LabelEditEventArgs nleea = new LabelEditEventArgs(lvitem, label);
								onAfterLabelEdit(nleea);
								if (nleea.cancelEdit)
								{
									m.result = FALSE;
								}
								else
								{
									// TODO: check if correct implementation.
									// Update the lvitem's cached text..
									lvitem.settextin(label);
									
									m.result = TRUE;
								}
							}
							break;
						}
					}
					
					default:
				}
				break;
			}
			
			default:
		}
	}
	
	
	protected override void prevWndProc(ref Message msg)
	{
		switch (msg.msg)
		{
			case WM_MOUSEHOVER:
				if (!hoverSelection)
					return;
				break;
			
			default:
		}
		
		//msg.result = CallWindowProcA(listviewPrevWndProc, msg.hWnd, msg.msg, msg.wParam, msg.lParam);
		msg.result = dfl.internal.utf.callWindowProc(listviewPrevWndProc, msg.hWnd, msg.msg, msg.wParam, msg.lParam);
	}


private:
	enum MARGIN_X = 4;
	enum MARGIN_Y = 4;

	DWORD _wlvexstyle = 0;
	ListViewItemCollection _litems;
	ColumnHeaderCollection _cols;
	SelectedIndexCollection _selidxcollection;
	SelectedItemCollection _selobjcollection;
	SortOrder _sortorder = SortOrder.NONE;
	CheckedIndexCollection _checkedis;
	int delegate(ListViewItem, ListViewItem) _sortproc;
	ImageList _lgimglist, _smimglist;
	//ImageList _stimglist;
	Font _headerFont;
	
	
	int _defsortproc(ListViewItem a, ListViewItem b) const
	{
		return a.opCmp(b);
	}
	
	
	DWORD _lvexstyle() const
	{
		//if (created)
		//	wlvexstyle = cast(DWORD)SendMessageA(hwnd, LVM_GETEXTENDEDLISTVIEWSTYLE, 0, 0);
		//	wlvexstyle = cast(DWORD)prevwproc(LVM_GETEXTENDEDLISTVIEWSTYLE, 0, 0);
		return _wlvexstyle;
	}
	
	
	void _lvexstyle(DWORD flags)
	{
		DWORD _b4 = _wlvexstyle;
		
		_wlvexstyle = flags;
		if (created)
		{
			// hwnd, msg, mask, flags
			//SendMessageA(hwnd, LVM_SETEXTENDEDLISTVIEWSTYLE, flags ^ _b4, wlvexstyle);
			prevwproc(LVM_SETEXTENDEDLISTVIEWSTYLE, flags ^ _b4, _wlvexstyle);
			//redrawEntire(); // Need to recalc the frame ?
		}
	}
	
	
	void _lvexstyle(DWORD mask, DWORD flags)
	in
	{
		assert(mask);
	}
	do
	{
		_wlvexstyle = (_wlvexstyle & ~mask) | (flags & mask);
		if (created)
		{
			// hwnd, msg, mask, flags
			//SendMessageA(hwnd, LVM_SETEXTENDEDLISTVIEWSTYLE, mask, flags);
			prevwproc(LVM_SETEXTENDEDLISTVIEWSTYLE, mask, flags);
			//redrawEntire(); // Need to recalc the frame ?
		}
	}
	
	
	// If -subItemIndex- is 0 it's an item not a sub item.
	// Returns the insertion index or -1 on failure.
	package final int _ins(int index, LPARAM lparam, Dstring itemText, int subItemIndex, int imageIndex = -1)
	in
	{
		assert(created);
	}
	do
	{
		/+
		cprintf("^ Insert item:  index=%d, lparam=0x%X, text='%.*s', subItemIndex=%d\n",
			index, lparam, itemText.length > 20 ? 20 : itemText.length, cast(char*)itemText, subItemIndex);
		+/
		
		LV_ITEMA lvi;
		lvi.mask = LVIF_TEXT | LVIF_PARAM;
		//if (-1 != imageIndex)
		if (!subItemIndex)
			lvi.mask |= LVIF_IMAGE;
		//lvi.iImage = imageIndex;
		lvi.iImage = I_IMAGECALLBACK;
		lvi.iItem = index;
		lvi.iSubItem = subItemIndex;
		//lvi.pszText = toStringz(itemText);
		lvi.pszText = LPSTR_TEXTCALLBACKA;
		lvi.lParam = lparam;
		return prevwproc(LVM_INSERTITEMA, 0, cast(LPARAM)&lvi).toI32;
	}
	
	
	package final int _ins(int index, ListViewItem item)
	{
		return _ins(index, cast(LPARAM)cast(void*)item, item.text, 0, item._imgidx).toI32;
	}
	
	
	package final int _ins(int index, ListViewSubItem subItem, int subItemIndex)
	in
	{
		assert(subItemIndex > 0);
	}
	do
	{
		return _ins(index, cast(LPARAM)cast(void*)subItem, subItem.text, subItemIndex).toI32;
	}
	
	
	package final int _ins(int index, ColumnHeader header)
	{
		// TODO: column inserted at index 0 can only be left aligned, so will need to
		// insert a dummy column to change the alignment, then delete the dummy column.
		
		LVCOLUMN lvc;
		lvc.mask = LVCF_FMT | LVCF_SUBITEM | LVCF_TEXT | LVCF_WIDTH;
		final switch (header.textAlign)
		{
			case HorizontalAlignment.RIGHT:
				lvc.fmt = LVCFMT_RIGHT | LVCFMT_FIXED_RATIO;
				break;
			
			case HorizontalAlignment.CENTER:
				lvc.fmt = LVCFMT_CENTER | LVCFMT_FIXED_RATIO;
				break;
			
			case HorizontalAlignment.LEFT:
				lvc.fmt = LVCFMT_LEFT | LVCFMT_FIXED_RATIO;
		}
		lvc.cx = MulDiv(header.width, dpi, USER_DEFAULT_SCREEN_DPI);
		lvc.iSubItem = index; // iSubItem is probably only used when retrieving column info.
		static if (dfl.internal.utf.useUnicode)
		{
			lvc.pszText = cast(typeof(lvc.pszText))dfl.internal.utf.toUnicodez(header.text);
			return prevwproc(LVM_INSERTCOLUMNW, cast(WPARAM)index, cast(LPARAM)&lvc).toI32;
		}
		else
		{
			lvc.pszText = cast(typeof(lvc.pszText))dfl.internal.utf.toAnsiz(header.text);
			return prevwproc(LVM_INSERTCOLUMNA, cast(WPARAM)index, cast(LPARAM)&lvc).toI32;
		}
	}
	
	
	// If -subItemIndex- is 0 it's an item not a sub item.
	// Returns FALSE on failure.
	LRESULT updateItem(int index)
	in
	{
		assert(created);
	}
	do
	{
		return prevwproc(LVM_REDRAWITEMS, cast(WPARAM)index, cast(LPARAM)index);
	}
	
	LRESULT updateItem(ListViewItem item)
	{
		int index = item.index;
		assert(-1 != index);
		return updateItem(index);
	}
	
	
	LRESULT updateItemText(int index, Dstring newText, int subItemIndex = 0)
	{
		return updateItem(index);
	}
	
	LRESULT updateItemText(ListViewItem item, Dstring newText, int subItemIndex = 0)
	{
		return updateItem(item);
	}
	
	
	LRESULT updateColumnText(int colIndex, Dstring newText)
	{
		LVCOLUMN lvc;
		
		lvc.mask = LVCF_TEXT;
		static if (dfl.internal.utf.useUnicode)
		{
			lvc.pszText = cast(typeof(lvc.pszText))dfl.internal.utf.toUnicodez(newText);
			return prevwproc(LVM_SETCOLUMNW, cast(WPARAM)colIndex, cast(LPARAM)&lvc);
		}
		else
		{
			lvc.pszText = cast(typeof(lvc.pszText))dfl.internal.utf.toAnsiz(newText);
			return prevwproc(LVM_SETCOLUMNA, cast(WPARAM)colIndex, cast(LPARAM)&lvc);
		}
	}
	
	
	LRESULT updateColumnText(ColumnHeader col, Dstring newText)
	{
		int colIndex = columns.indexOf(col);
		assert(-1 != colIndex);
		return updateColumnText(colIndex, newText);
	}
	
	
	LRESULT updateColumnAlign(int colIndex, HorizontalAlignment halign)
	{
		LVCOLUMN lvc;
		lvc.mask = LVCF_FMT;
		final switch (halign)
		{
			case HorizontalAlignment.RIGHT:
				lvc.fmt = LVCFMT_RIGHT | LVCFMT_FIXED_RATIO;
				break;
			
			case HorizontalAlignment.CENTER:
				lvc.fmt = LVCFMT_CENTER | LVCFMT_FIXED_RATIO;
				break;
			
			case HorizontalAlignment.LEFT:
				lvc.fmt = LVCFMT_LEFT | LVCFMT_FIXED_RATIO;
		}
		return prevwproc(LVM_SETCOLUMNA, cast(WPARAM)colIndex, cast(LPARAM)&lvc);
	}
	
	
	LRESULT updateColumnAlign(ColumnHeader col, HorizontalAlignment halign)
	{
		int colIndex = columns.indexOf(col);
		assert(-1 != colIndex);
		return updateColumnAlign(colIndex, halign);
	}
	
	
	LRESULT updateColumnWidth(int colIndex, int w)
	{
		LVCOLUMN lvc;
		lvc.mask = LVCF_WIDTH;
		lvc.cx = MulDiv(w, dpi, USER_DEFAULT_SCREEN_DPI);
		return prevwproc(LVM_SETCOLUMN, cast(WPARAM)colIndex, cast(LPARAM)&lvc);
	}
	
	
	LRESULT updateColumnWidth(ColumnHeader col, int w)
	{
		int colIndex = columns.indexOf(col);
		assert(-1 != colIndex);
		return updateColumnWidth(colIndex, w);
	}
	
	
	int getColumnWidth(int colIndex)
	{
		LVCOLUMN lvc;
		lvc.mask = LVCF_WIDTH;
		lvc.cx = -1;
		prevwproc(LVM_GETCOLUMN, cast(WPARAM)colIndex, cast(LPARAM)&lvc);
		return MulDiv(lvc.cx, USER_DEFAULT_SCREEN_DPI, dpi);
	}
	
	
	int getColumnWidth(ColumnHeader col)
	{
		int colIndex = columns.indexOf(col);
		assert(-1 != colIndex);
		return getColumnWidth(colIndex);
	}
	
	
package:
final:
	LRESULT prevwproc(UINT msg, WPARAM wparam, LPARAM lparam)
	{
		//return CallWindowProcA(listviewPrevWndProc, hwnd, msg, wparam, lparam);
		return dfl.internal.utf.callWindowProc(listviewPrevWndProc, _hwnd, msg, wparam, lparam);
	}
}
