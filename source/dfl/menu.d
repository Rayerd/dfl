// Written by Christopher E. Miller
// See the included license.txt for copyright and license details.


///
module dfl.menu;

import dfl.application;
import dfl.base;
import dfl.collections;
import dfl.control;
import dfl.drawing;
import dfl.event;

import dfl.internal.dlib;
import dfl.internal.utf;

import core.sys.windows.windef;
import core.sys.windows.winuser;

debug(APP_PRINT)
{
	import dfl.internal.clib;
}

///
class ContextMenu: Menu // docmain
{
	///
	final void show(Control control, Point pos)
	{
		SetForegroundWindow(control.handle);
		TrackPopupMenu(_hmenu, TPM_LEFTALIGN | TPM_LEFTBUTTON | TPM_RIGHTBUTTON,
			pos.x, pos.y, 0, control.handle, null);
	}
	
	
	Event!(ContextMenu, EventArgs) popup; ///
	
	
	// Used internally.
	this(HMENU hmenu, bool owned = true)
	{
		super(hmenu, owned);
		
		_init();
	}
	
	
	this()
	{
		super(CreatePopupMenu());
		
		_init();
	}
	
	
	~this()
	{
		Application.removeMenu(this);
		
		debug(APP_PRINT)
			cprintf("~ContextMenu\n");
	}
	
	
	protected override void onReflectedMessage(ref Message m)
	{
		super.onReflectedMessage(m);
		
		switch (m.msg)
		{
			case WM_INITMENU:
				assert(cast(HMENU)m.wParam == handle);
				
				//onPopup(EventArgs.empty);
				popup(this, EventArgs.empty);
				break;
			
			default:
		}
	}
	
	
private:
	void _init()
	{
		Application.addContextMenu(this);
	}
}


///
class MenuItem: Menu // docmain
{
	///
	final @property void text(Dstring txt) // setter
	{
		if (!menuItems.length && txt == SEPARATOR_TEXT)
		{
			_type(_type() | MFT_SEPARATOR);
		}
		else
		{
			if (_manuParent)
			{
				MENUITEMINFOA mii;
				
				if (_menuItemType & MFT_SEPARATOR)
					_menuItemType = ~MFT_SEPARATOR;
				mii.cbSize = mii.sizeof;
				mii.fMask = MIIM_TYPE | MIIM_STATE; // Not setting the state can cause implicit disabled/gray if the text was empty.
				mii.fType = _menuItemType;
				mii.fState = _menuItemState;
				//mii.dwTypeData = stringToStringz(txt);
				
				_manuParent._setInfo(_menuId, false, &mii, txt);
			}
		}
		
		_menuText = txt;
	}
	
	/// ditto
	final @property Dstring text() const // getter
	{
		// if (mparent) fetch text ?
		return _menuText;
	}
	
	
	///
	final @property void parent(Menu m) // setter
	{
		m.menuItems.add(this);
	}
	
	/// ditto
	final @property Menu parent() // getter
	{
		return _manuParent;
	}
	
	
	package final void _setParent(Menu newParent)
	{
		assert(!_manuParent);
		_manuParent = newParent;
		
		if (cast(size_t)_menuItemIndex > _manuParent.menuItems.length)
			_menuItemIndex = _manuParent.menuItems.length.toI32;
		
		_setParent();
	}
	
	
	private void _setParent()
	{
		MENUITEMINFOA mii;
		mii.cbSize = mii.sizeof;
		mii.fMask = MIIM_TYPE | MIIM_STATE | MIIM_ID | MIIM_SUBMENU;
		mii.fType = _menuItemType;
		mii.fState = _menuItemState;
		mii.wID = _menuId;
		mii.hSubMenu = handle;
		//if (!(fType & MFT_SEPARATOR))
		//	mii.dwTypeData = stringToStringz(mtext);

		MenuItem miparent = cast(MenuItem)_manuParent;

		if (miparent && !miparent._hmenu)
		{
			miparent._hmenu = CreatePopupMenu();
			
			if (miparent.parent() && miparent.parent._hmenu)
			{
				MENUITEMINFOA miiPopup;
				
				miiPopup.cbSize = miiPopup.sizeof;
				miiPopup.fMask = MIIM_SUBMENU;
				miiPopup.hSubMenu = miparent._hmenu;
				miparent.parent._setInfo(miparent._menuID, false, &miiPopup);
			}
		}
		_manuParent._insert(_menuItemIndex, true, &mii, (_menuItemType & MFT_SEPARATOR) ? null : _menuText);
	}
	
	
	package final void _unsetParent()
	{
		assert(_manuParent);
		assert(_manuParent.menuItems.length > 0);
		assert(_manuParent._hmenu);
		
		// Last child menu item, make the parent non-popup now.
		if (_manuParent.menuItems.length == 1)
		{
			MenuItem miparent = cast(MenuItem)_manuParent;

			if (miparent && miparent._hmenu)
			{
				MENUITEMINFOA miiPopup;
				miiPopup.cbSize = miiPopup.sizeof;
				miiPopup.fMask = MIIM_SUBMENU;
				miiPopup.hSubMenu = null;
				miparent.parent._setInfo(miparent._menuID, false, &miiPopup);
				
				miparent._hmenu = null;
			}
		}
		
		_manuParent = null;
		
		if (!Menu._compat092)
		{
			_menuItemIndex = -1;
		}
	}
	
	
	///
	final @property void barBreak(bool byes) // setter
	{
		if (byes)
			_type(_type() | MFT_MENUBARBREAK);
		else
			_type(_type() & ~MFT_MENUBARBREAK);
	}
	
	/// ditto
	final @property bool barBreak() // getter
	{
		return (_type() & MFT_MENUBARBREAK) != 0;
	}
	
	
	// Can't be break().
	
	///
	final @property void breakItem(bool byes) // setter
	{
		if (byes)
			_type(_type() | MFT_MENUBREAK);
		else
			_type(_type() & ~MFT_MENUBREAK);
	}
	
	/// ditto
	final @property bool breakItem() // getter
	{
		return (_type() & MFT_MENUBREAK) != 0;
	}
	
	
	///
	final @property void checked(bool byes) // setter
	{
		if (byes)
			_state(_state() | MFS_CHECKED);
		else
			_state(_state() & ~MFS_CHECKED);
	}
	
	/// ditto
	final @property bool checked() // getter
	{
		return (_state() & MFS_CHECKED) != 0;
	}
	
	
	///
	final @property void defaultItem(bool byes) // setter
	{
		if (byes)
			_state(_state() | MFS_DEFAULT);
		else
			_state(_state() & ~MFS_DEFAULT);
	}
	
	/// ditto
	final @property bool defaultItem() // getter
	{
		return (_state() & MFS_DEFAULT) != 0;
	}
	
	
	///
	final @property void enabled(bool byes) // setter
	{
		if (byes)
			_state(_state() & ~MFS_GRAYED);
		else
			_state(_state() | MFS_GRAYED);
	}
	
	/// ditto
	final @property bool enabled() // getter
	{
		return (_state() & MFS_GRAYED) == 0;
	}
	
	
	///
	final @property void index(int idx) // setter
	{// Note: probably fails when the parent exists because mparent is still set and menuItems.insert asserts it's null.
		if (_manuParent)
		{
			if (cast(uint)idx > _manuParent.menuItems.length)
				throw new DflException("Invalid menu index");
			
			//RemoveMenu(mparent.handle, mid, MF_BYCOMMAND);
			_manuParent._remove(_menuId, MF_BYCOMMAND);
			_manuParent.menuItems._delitem(_menuItemIndex);
			
			/+
			mindex = idx;
			_setParent();
			mparent.menuItems._additem(this);
			+/
			_manuParent.menuItems.insert(idx, this);
		}
		
		if (Menu._compat092)
		{
			_menuItemIndex = idx;
		}
	}
	
	/// ditto
	final @property int index() // getter
	{
		return _menuItemIndex;
	}
	
	
	override @property bool isParent() // getter
	{
		return handle != null; // ?
	}
	
	
	deprecated final @property void mergeOrder(int ord) // setter
	{
		//_menuMergeOrder = ord;
	}
	
	deprecated final @property int mergeOrder() // getter
	{
		//return _menuMergeOrder;
		return 0;
	}
	
	
	// TODO: mergeType().
	
	
	///
	// Returns a NUL char if none.
	final @property char mnemonic() // getter
	{
		bool singleAmp = false;
		
		foreach (char ch; _menuText)
		{
			if (singleAmp)
			{
				if (ch == '&')
					singleAmp = false;
				else
					return ch;
			}
			else
			{
				if (ch == '&')
					singleAmp = true;
			}
		}
		
		return 0;
	}
	
	
	/+
	// TODO: implement owner drawn menus.
	
	final @property void ownerDraw(bool byes) // setter
	{
		
	}
	
	final @property bool ownerDraw() // getter
	{
		
	}
	+/
	
	
	///
	final @property void radioCheck(bool byes) // setter
	{
		auto par = parent;
		auto pidx = index;
		if (par)
			par.menuItems._removing(pidx, this);
		
		if (byes)
			//_type(_type() | MFT_RADIOCHECK);
			_menuItemType |= MFT_RADIOCHECK;
		else
			//_type(_type() & ~MFT_RADIOCHECK);
			_menuItemType &= ~MFT_RADIOCHECK;
		
		if (par)
			par.menuItems._added(pidx, this);
	}
	
	/// ditto
	final @property bool radioCheck() // getter
	{
		return (_type() & MFT_RADIOCHECK) != 0;
	}
	
	
	// TODO: shortcut(), showShortcut().
	
	
	/+
	// TODO: need to fake this ?
	
	final @property void visible(bool byes) // setter
	{
		// ?
		mvisible = byes;
	}
	
	final @property bool visible() // getter
	{
		return mvisible;
	}
	+/
	
	
	///
	final void performClick()
	{
		onClick(EventArgs.empty);
	}
	
	
	///
	final void performSelect()
	{
		onSelect(EventArgs.empty);
	}
	
	
	// Used internally.
	this(HMENU hmenu, bool owned = true) // package
	{
		super(hmenu, owned);
		_init();
	}
	
	
	///
	this(MenuItem[] items)
	{
		if (items.length)
		{
			HMENU hm = CreatePopupMenu();
			super(hm);
		}
		else
		{
			super();
		}
		_init();
		
		menuItems.addRange(items);
	}
	
	/// ditto
	this(Dstring text)
	{
		_init();
		
		this.text = text;
	}
	
	/// ditto
	this(Dstring text, MenuItem[] items)
	{
		if (items.length)
		{
			HMENU hm = CreatePopupMenu();
			super(hm);
		}
		else
		{
			super();
		}
		_init();
		
		this.text = text;
		
		menuItems.addRange(items);
	}
	
	/// ditto
	this()
	{
		_init();
	}
	
	
	~this()
	{
		Application.removeMenu(this);
		
		debug(APP_PRINT)
			cprintf("~MenuItem\n");
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
	

	protected override void onReflectedMessage(ref Message m)
	{
		super.onReflectedMessage(m);
		
		switch (m.msg)
		{
			case WM_COMMAND:
			{
				int menuID = LOWORD(m.wParam);
				int senderID = HIWORD(m.wParam);
				if (senderID == 0) // 0: Menu
				{
					assert(menuID == _menuId);
					onClick(EventArgs.empty);
				}
				break;
			}
			
			case WM_MENUSELECT:
				onSelect(EventArgs.empty);
				break;
			
			case WM_INITMENUPOPUP:
				assert(!HIWORD(m.lParam));
				//assert(cast(HMENU)msg.wParam == mparent.handle);
				assert(cast(HMENU)m.wParam == handle);
				//assert(GetMenuItemID(mparent.handle, LOWORD(msg.lParam)) == mid);
				
				onPopup(EventArgs.empty);
				break;
			
			default:
		}
	}
	
	
	Event!(MenuItem, EventArgs) click; ///
	Event!(MenuItem, EventArgs) popup; ///
	Event!(MenuItem, EventArgs) select; ///
	
	
protected:
	
	///
	final @property int menuID() // getter
	{
		return _menuId;
	}
	
	
	package final @property int _menuID()
	{
		return _menuId;
	}
	
	
	///
	void onClick(EventArgs ea)
	{
		click(this, ea);
	}
	
	
	///
	void onPopup(EventArgs ea)
	{
		popup(this, ea);
	}
	
	
	///
	void onSelect(EventArgs ea)
	{
		select(this, ea);
	}
	
	
private:
	
	int _menuId; // Menu ID.
	Dstring _menuText;
	Menu _manuParent;
	UINT _menuItemType = 0; // MFT_*
	UINT _menuItemState = 0;
	int _menuItemIndex = -1; //0;
	//int _menuMergeOrder = 0;
	
	enum SEPARATOR_TEXT = "-";
	
	static assert(!MFS_UNCHECKED);
	static assert(!MFT_STRING);
	
	
	void _init()
	{
		if (Menu._compat092)
		{
			_menuItemIndex = 0;
		}
		
		_menuId = Application.addMenuItem(this);
	}
	
	
	@property void _type(UINT newType) // setter
	{
		if (_manuParent)
		{
			MENUITEMINFOA mii;
			mii.cbSize = mii.sizeof;
			mii.fMask = MIIM_TYPE;
			mii.fType = newType;
			
			_manuParent._setInfo(_menuId, false, &mii);
		}
		
		_menuItemType = newType;
	}
	
	
	@property UINT _type() // getter
	{
		// if (mparent) fetch value ?
		return _menuItemType;
	}
	
	
	@property void _state(UINT newState) // setter
	{
		if (_manuParent)
		{
			MENUITEMINFOA mii;
			mii.cbSize = mii.sizeof;
			mii.fMask = MIIM_STATE;
			mii.fState = newState;
			
			_manuParent._setInfo(_menuId, false, &mii);
		}
		
		_menuItemState = newState;
	}
	
	
	@property UINT _state() // getter
	{
		// if (mparent) fetch value ? No: Windows seems to add disabled/gray when the text is empty.
		return _menuItemState;
	}
}


///
abstract class Menu: DObject // docmain
{
	// Retain DFL 0.9.2 compatibility.
	deprecated static void setDFL092()
	{
		version(SET_DFL_092)
		{
			pragma(msg, "DFL: DFL 0.9.2 compatibility set at compile time");
		}
		else
		{
			//_compat092 = true;
			Application.setCompat(DflCompat.MENU_092);
		}
	}
	
	version(SET_DFL_092)
		private enum _compat092 = true;
	else version(DFL_NO_COMPAT)
		private enum _compat092 = false;
	else
		private static @property bool _compat092() // getter
			{ return 0 != (Application._compat & DflCompat.MENU_092); }
	
	
	///
	static class MenuItemCollection
	{
		protected this(Menu owner)
		{
			_owner = owner;
		}
		
		
		package void _additem(MenuItem mi)
		{
			// Fix indices after this point.
			int idx = mi.index + 1; // Note, not orig idx.
			if (idx < _items.length)
			{
				foreach (MenuItem onmi; _items[idx .. _items.length])
				{
					onmi._menuItemIndex++;
				}
			}
		}
		
		
		// Note: clear() doesn't call this. Update: does now.
		package void _delitem(int idx)
		{
			// Fix indices after this point.
			if (idx < _items.length)
			{
				foreach (MenuItem onmi; _items[idx .. _items.length])
				{
					onmi._menuItemIndex--;
				}
			}
		}
		
		
		/+
		void insert(int index, MenuItem mi)
		{
			mi.mindex = index;
			mi._setParent(_owner);
			_additem(mi);
		}
		+/
		
		
		void add(MenuItem mi)
		{
			if (!Menu._compat092)
			{
				mi._menuItemIndex = length.toI32;
			}
			
			/+
			mi._setParent(_owner);
			_additem(mi);
			+/
			insert(mi._menuItemIndex, mi);
		}
		
		void add(Dstring value)
		{
			return add(new MenuItem(value));
		}
		
		
		void addRange(MenuItem[] items)
		{
			if (!Menu._compat092)
				return _wraparray.addRange(items);
			
			foreach (MenuItem it; items)
			{
				insert(length.toI32, it);
			}
		}
		
		void addRange(Dstring[] items)
		{
			if (!Menu._compat092)
				return _wraparray.addRange(items);
			
			foreach (Dstring it; items)
			{
				insert(length.toI32, it);
			}
		}
		
		
		// TODO: finish.
		
		
	package:
		
		Menu _owner;
		MenuItem[] _items; // Kept populated so the menu can be moved around.
		
		
		void _added(size_t idx, MenuItem val)
		{
			val._menuItemIndex = idx.toI32;
			val._setParent(_owner);
			_additem(val);
		}
		
		
		void _removing(size_t idx, MenuItem val)
		{
			if (size_t.max == idx) // Clear all.
			{
			}
			else
			{
				val._unsetParent();
				//RemoveMenu(_owner.handle, val._menuID, MF_BYCOMMAND);
				//_owner._remove(val._menuID, MF_BYCOMMAND);
				_owner._remove(idx.toI32, MF_BYPOSITION);
				_delitem(idx.toI32);
			}
		}
		
		
	public:
		
		mixin ListWrapArray!(MenuItem, _items,
			_blankListCallback!(MenuItem), _added,
			_removing, _blankListCallback!(MenuItem),
			true, false, false,
			true) _wraparray; // CLEAR_EACH
	}
	
	
	// Extra.
	deprecated void opOpAssign(string op)(MenuItem mi) if (op == "~")
	{
		menuItems.insert(menuItems.length.toI32, mi);
	}
	
	
	private void _init()
	{
		_menuItems = new MenuItemCollection(this);
	}
	
	
	// Menu item that isn't popup (yet).
	protected this()
	{
		_init();
	}
	
	
	// Used internally.
	this(HMENU hmenu, bool owned = true) // package
	{
		this._hmenu = hmenu;
		this._owned = owned;
		
		_init();
	}
	
	
	// Used internally.
	this(HMENU hmenu, MenuItem[] items) // package
	{
		this._owned = true;
		this._hmenu = hmenu;
		
		_init();
		
		menuItems.addRange(items);
	}
	
	
	// Don't call directly.
	@disable this(MenuItem[] items);
	/+{
		/+
		this.owned = true;
		
		_init();
		
		menuItems.addRange(items);
		+/
		
		assert(0);
	}+/
	
	
	~this()
	{
		if (_owned)
			DestroyMenu(_hmenu);
	}
	
	
	///
	final @property void tag(Object o) // setter
	{
		_ttag = o;
	}
	
	/// ditto
	final @property Object tag() // getter
	{
		return _ttag;
	}
	
	
	///
	final @property HMENU handle() // getter
	{
		return _hmenu;
	}
	
	
	///
	final @property MenuItemCollection menuItems() // getter
	{
		return _menuItems;
	}
	
	
	///
	@property bool isParent() // getter
	{
		return false;
	}
	
	
	///
	protected void onReflectedMessage(ref Message m)
	{
	}
	
	
	package final void _reflectMenu(ref Message m)
	{
		onReflectedMessage(m);
	}
	
	
	/+ package +/ protected void _setInfo(UINT uItem, BOOL fByPosition, LPMENUITEMINFOA lpmii, Dstring typeData = null) // package
	{
		if (typeData.length)
		{
			if (dfl.internal.utf.useUnicode)
			{
				static assert(MENUITEMINFOW.sizeof == MENUITEMINFOA.sizeof);
				lpmii.dwTypeData = cast(typeof(lpmii.dwTypeData))dfl.internal.utf.toUnicodez(typeData);
				_setMenuItemInfoW(_hmenu, uItem, fByPosition, cast(MENUITEMINFOW*)lpmii);
			}
			else
			{
				lpmii.dwTypeData = cast(typeof(lpmii.dwTypeData))dfl.internal.utf.unsafeAnsiz(typeData);
				SetMenuItemInfoA(_hmenu, uItem, fByPosition, lpmii);
			}
		}
		else
		{
			SetMenuItemInfoA(_hmenu, uItem, fByPosition, lpmii);
		}
	}
	
	
	/+ package +/ protected void _insert(UINT uItem, BOOL fByPosition, LPMENUITEMINFOA lpmii, Dstring typeData = null) // package
	{
		if (typeData.length)
		{
			if (dfl.internal.utf.useUnicode)
			{
				static assert(MENUITEMINFOW.sizeof == MENUITEMINFOA.sizeof);
				lpmii.dwTypeData = cast(typeof(lpmii.dwTypeData))dfl.internal.utf.toUnicodez(typeData);
				_insertMenuItemW(_hmenu, uItem, fByPosition, cast(MENUITEMINFOW*)lpmii);
			}
			else
			{
				lpmii.dwTypeData = cast(typeof(lpmii.dwTypeData))dfl.internal.utf.unsafeAnsiz(typeData);
				InsertMenuItemA(_hmenu, uItem, fByPosition, lpmii);
			}
		}
		else
		{
			InsertMenuItemA(_hmenu, uItem, fByPosition, lpmii);
		}
	}
	
	
	/+ package +/ protected void _remove(UINT uPosition, UINT uFlags) // package
	{
		RemoveMenu(_hmenu, uPosition, uFlags);
	}
	
	
	package HMENU _hmenu;
	
private:
	bool _owned = true;
	MenuItemCollection _menuItems;
	Object _ttag;
}


///
class MainMenu: Menu // docmain
{
	// Used internally.
	this(HMENU hmenu, bool owned = true)
	{
		super(hmenu, owned);
	}
	
	
	///
	this()
	{
		super(CreateMenu());
	}
	
	/// ditto
	this(MenuItem[] items)
	{
		super(CreateMenu(), items);
	}
	
	
	/+ package +/ protected override void _setInfo(UINT uItem, BOOL fByPosition, LPMENUITEMINFOA lpmii, Dstring typeData = null) // package
	{
		Menu._setInfo(uItem, fByPosition, lpmii, typeData);
		
		if (_hwnd)
			DrawMenuBar(_hwnd);
	}
	
	
	/+ package +/ protected override void _insert(UINT uItem, BOOL fByPosition, LPMENUITEMINFOA lpmii, Dstring typeData = null) // package
	{
		Menu._insert(uItem, fByPosition, lpmii, typeData);
		
		if (_hwnd)
			DrawMenuBar(_hwnd);
	}
	
	
	/+ package +/ protected override void _remove(UINT uPosition, UINT uFlags) // package
	{
		Menu._remove(uPosition, uFlags);
		
		if (_hwnd)
			DrawMenuBar(_hwnd);
	}
	
	
private:
	
	HWND _hwnd = HWND.init;
	
	
	package final void _setHwnd(HWND hwnd)
	{
		this._hwnd = hwnd;
	}
}
