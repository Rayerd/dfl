// Written by Christopher E. Miller
// See the included license.txt for copyright and license details.


///
module dfl.tabcontrol;

import dfl.application;
import dfl.base;
import dfl.collections;
import dfl.control;
import dfl.drawing;
import dfl.event;
import dfl.panel;

import dfl.internal.dlib;
import dfl.internal.dpiaware;
static import dfl.internal.utf;

import core.sys.windows.winbase;
import core.sys.windows.windef;
import core.sys.windows.winuser;
import core.sys.windows.commctrl;

private extern(Windows) void _initTabcontrol();


///
class TabPage: Panel
{
	///
	this(Dstring tabText)
	{
		this();
		
		this.text = tabText;
	}
	
	/+
	/// ditto
	this(Object v) // package
	{
		this(getObjectString(v));
	}
	+/
	
	/// ditto
	this()
	{
		Application.ppin(cast(void*)this);
		
		_controlStyle |= ControlStyles.CONTAINER_CONTROL;
		
		_windowStyle &= ~WS_VISIBLE;
		_cbits &= ~CBits.VISIBLE;
	}
	
	
	override Dstring toString() const
	{
		return text;
	}
	

	alias opEquals = Control.opEquals;

	
	override Dequ opEquals(Object o) const
	{
		return text == getObjectString(o);
	}

	
	Dequ opEquals(Dstring val) const
	{
		return text == val;
	}
	
	
	alias opCmp = Control.opCmp;


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
	
	
	// imageIndex
	
	
	override @property void text(Dstring newText) // setter
	{
		// NOTE: this probably causes toStringz() to be called twice,
		// allocating 2 of the same string.
		
		super.text = newText;
		
		if(created)
		{
			TabControl tc = cast(TabControl)parent;
			if(tc)
				tc.updateTabText(this, newText);
		}
	}
	
	alias text = Panel.text; // Overload with Panel.text.
	
	
	/+
	final @property void toolTipText(Dstring ttt) // setter
	{
		// TODO: ...
	}
	
	
	final @property Dstring toolTipText() // getter
	{
		// TODO: ...
		return null;
	}
	+/
	
	
	/+ package +/ /+ protected +/ override int _rtype() // package
	{
		return 4;
	}
	
	
	protected override void setBoundsCore(int x, int y, int width, int height, BoundsSpecified specified)
	{
		assert(0); // Cannot set bounds of TabPage; it is done automatically.
	}
	
	
	package final @property void realBounds(Rect r) // setter
	{
		super.setBoundsCore(r.x, r.y, r.width, r.height, BoundsSpecified.ALL);
	}
	
	
	protected override void setVisibleCore(bool byes)
	{
		assert(0); // Cannot set visibility of TabPage; it is done automatically.
	}
	
	
	package final @property void realVisible(bool byes) // setter
	{
		super.setVisibleCore(byes);
	}
}


///
class TabPageCollection
{
	protected this(TabControl owner)
	in
	{
		assert(owner._tabPageCollection is null);
	}
	do
	{
		_ownerTabControl = owner;
	}
	
	
private:
	
	TabControl _ownerTabControl;
	TabPage[] _tabPages = null;
	
	
	void doPages()
	in
	{
		assert(created);
	}
	do
	{
		foreach (i, TabPage page; _tabPages)
		{
			TCITEM tci;
			tci.mask = TCIF_TEXT | TCIF_PARAM; // TODO: TCIF_RTLREADING flag based on rightToLeft property.
			tci.dwState = 0;
			tci.dwStateMask = 0;
			tci.iImage = -1;
			tci.cchTextMax = 0;

			if (dfl.internal.utf.useUnicode)
				tci.pszText = cast(typeof(tci.pszText))dfl.internal.utf.toUnicodez(page.text);
			else
				tci.pszText = cast(typeof(tci.pszText))dfl.internal.utf.toAnsiz(page.text);
			
			static assert(tci.lParam.sizeof >= (void*).sizeof);
			tci.lParam = cast(LPARAM)cast(void*)page;
			
			TabCtrl_InsertItem(_ownerTabControl.handle, cast(int)i, &tci);
		}
	}
	
	
	package final @property bool created() const // getter
	{
		return _ownerTabControl && _ownerTabControl.created();
	}
	
	
	void _added(size_t idx, TabPage val)
	{
		if(val.parent)
		{
			TabControl ownerTabControl = cast(TabControl)val.parent;
			if(ownerTabControl && ownerTabControl.tabPages.indexOf(val) != -1)
				throw new DflException("TabPage already has a parent");
		}
		
		//val.realVisible = false;
		assert(!val.visible);
		assert(_ownerTabControl);
		val.parent = _ownerTabControl;
		
		if (created)
		{
			TCITEM tci;
			tci.mask = TCIF_TEXT | TCIF_PARAM; // TODO: TCIF_RTLREADING flag based on rightToLeft property.
			tci.dwState = 0;
			tci.dwStateMask = 0;
			tci.iImage = -1;
			tci.cchTextMax = 0;

			if (dfl.internal.utf.useUnicode)
				tci.pszText = cast(typeof(tci.pszText))dfl.internal.utf.toUnicodez(val.text);
			else
				tci.pszText = cast(typeof(tci.pszText))dfl.internal.utf.toAnsiz(val.text);

			static assert(tci.lParam.sizeof >= (void*).sizeof);
			tci.lParam = cast(LPARAM)cast(void*)val;
			
			TabCtrl_InsertItem(_ownerTabControl.handle, cast(int)idx, &tci);

			if(_ownerTabControl.selectedTab is val)
			{
				//val.realVisible = true;
				_ownerTabControl.tabToFront(val);
			}
		}
	}
	
	
	void _removed(size_t idx, TabPage val)
	{
		if (size_t.max == idx) // Clear all.
		{
			if (created)
			{
				TabCtrl_DeleteAllItems(_ownerTabControl.handle);
			}
		}
		else
		{
			//val.parent = null; // Can't do that.
			
			if (created)
			{
				TabCtrl_DeleteItem(_ownerTabControl.handle, cast(int)idx);
				
				// Hide this one.
				val.realVisible = false;
				
				// Show next visible.
				val = _ownerTabControl.selectedTab;
				if(val)
					_ownerTabControl.tabToFront(val);
			}
		}
	}
	
	
public:
	
	mixin ListWrapArray!(TabPage, _tabPages,
		_blankListCallback!(TabPage), _added,
		_blankListCallback!(TabPage), _removed,
		true, false, false,
		true); // CLEAR_EACH
}


///
enum TabAlignment: ubyte
{
	TOP, ///
	BOTTOM, /// ditto
	LEFT, /// ditto
	RIGHT, /// ditto
}


///
enum TabAppearance: ubyte
{
	NORMAL, ///
	BUTTONS, /// ditto
	FLAT_BUTTONS, /// ditto
}


///
enum TabDrawMode: ubyte
{
	NORMAL, ///
	OWNER_DRAW_FIXED, /// ditto
}


///
class TabControlBase: ControlSuperClass
{
	this()
	{
		_initTabcontrol();
		
		_windowStyle |= WS_TABSTOP;
		_controlStyle |= ControlStyles.SELECTABLE | ControlStyles.CONTAINER_CONTROL;
		_windowClassStyle = tabcontrolClassStyle;
	}
	
	
	///
	final @property void drawMode(TabDrawMode dm) // setter
	{
		final switch (dm)
		{
			case TabDrawMode.OWNER_DRAW_FIXED:
				_style(_windowStyle | TCS_OWNERDRAWFIXED);
				break;
			
			case TabDrawMode.NORMAL:
				_style(_windowStyle & ~TCS_OWNERDRAWFIXED);
		}
		
		_crecreate();
	}
	
	/// ditto
	final @property TabDrawMode drawMode() const // getter
	{
		if(_windowStyle & TCS_OWNERDRAWFIXED)
			return TabDrawMode.OWNER_DRAW_FIXED;
		return TabDrawMode.NORMAL;
	}
	
	
	override @property Rect displayRectangle() // getter
	{
		if(!created)
		{
			return super.displayRectangle();
		}
		else
		{
			RECT rc;
			GetClientRect(handle, &rc);
			TabCtrl_AdjustRect(handle, FALSE, &rc);
			rc.top = MulDiv(rc.top, USER_DEFAULT_SCREEN_DPI, dpi);
			rc.left = MulDiv(rc.left, USER_DEFAULT_SCREEN_DPI, dpi);
			rc.right = MulDiv(rc.right, USER_DEFAULT_SCREEN_DPI, dpi);
			rc.bottom = MulDiv(rc.bottom, USER_DEFAULT_SCREEN_DPI, dpi);
			return Rect(&rc);
		}
	}
	
	
	protected override @property Size defaultSize() const // getter
	{
		return Size(200, 200); // TODO: ?
	}
	
	
	///
	final Rect getTabRect(int i)
	{
		Rect tabRect;
		RECT rt;
		
		if (created && TabCtrl_GetItemRect(_hwnd, i, &rt))
			tabRect = Rect(&rt);
		
		return tabRect;
	}
	
	
	// drawItem event.
	Event!(TabControlBase, EventArgs) selectedIndexChanged; ///
	Event!(TabControlBase, CancelEventArgs) selectedIndexChanging; ///
	
	
	protected override void createParams(ref CreateParams cp)
	{
		super.createParams(cp);
		
		cp.className = TABCONTROL_CLASSNAME;
	}
	
	
	///
	protected void onSelectedIndexChanged(EventArgs ea)
	{
		selectedIndexChanged(this, ea);
	}
	
	
	///
	protected void onSelectedIndexChanging(CancelEventArgs ea)
	{
		selectedIndexChanging(this, ea);
	}
	
	
	protected override void prevWndProc(ref Message msg)
	{
		//msg.result = CallWindowProcA(tabcontrolPrevWndProc, msg.hWnd, msg.msg, msg.wParam, msg.lParam);
		msg.result = dfl.internal.utf.callWindowProc(tabcontrolPrevWndProc, msg.hWnd, msg.msg, msg.wParam, msg.lParam);
	}
	
	
	/+
	protected override void wndProc(ref Message m)
	{
		// TODO: support the tab control messages.

		switch(m.msg)
		{
			/+
			case WM_SETFOCUS:
				_exStyle(_exStyle() | WS_EX_CONTROLPARENT);
				break;
			
			case WM_KILLFOCUS:
				_exStyle(_exStyle() & ~WS_EX_CONTROLPARENT);
				break;
			+/
			
			case TCM_DELETEALLITEMS:
				m.result = FALSE;
				return;
			
			case TCM_DELETEITEM:
				m.result = FALSE;
				return;
			
			case TCM_INSERTITEMA:
			case TCM_INSERTITEMW:
				m.result = -1;
				return;
			
			//case TCM_REMOVEIMAGE:
			//	return;
			
			//case TCM_SETIMAGELIST:
			//	m.result = cast(LRESULT)null;
			//	return;
			
			case TCM_SETITEMA:
			case TCM_SETITEMW:
				m.result = FALSE;
				return;
			
			case TCM_SETITEMEXTRA:
				m.result = FALSE;
				return;
			
			case TCM_SETITEMSIZE:
				m.result = 0;
				return;
			
			case TCM_SETPADDING:
				return;
			
			case TCM_SETTOOLTIPS:
				return;
			
			default:
		}
		
		super.wndProc(m);
	}
	+/
	
	
	protected override void onReflectedMessage(ref Message m)
	{
		super.onReflectedMessage(m);
		
		NMHDR* nmh = cast(NMHDR*)m.lParam;
		
		switch(nmh.code)
		{
			case TCN_SELCHANGE:
				onSelectedIndexChanged(EventArgs.empty);
				return;
			
			case TCN_SELCHANGING:
			{
				scope CancelEventArgs ea = new CancelEventArgs;
				onSelectedIndexChanging(ea);
				if(ea.cancel)
				{
					m.result = TRUE; // Prevent change.
					return;
				}
				m.result = FALSE; // Allow change.
				return;
			}
			
			default:
		}
	}
}


///
class TabControl: TabControlBase // docmain
{
	this()
	{
		_tabPageCollection = new TabPageCollection(this);
		_padding = Point(6, 3);
	}
	
	
	///
	final @property void alignment(TabAlignment talign) // setter
	{
		final switch(talign)
		{
			case TabAlignment.TOP:
				_style(_windowStyle & ~(TCS_VERTICAL | TCS_RIGHT | TCS_BOTTOM));
				break;
			
			case TabAlignment.BOTTOM:
				_style((_windowStyle & ~(TCS_VERTICAL | TCS_RIGHT)) | TCS_BOTTOM);
				break;
			
			case TabAlignment.LEFT:
				_style((_windowStyle & ~(TCS_BOTTOM | TCS_RIGHT)) | TCS_VERTICAL);
				break;
			
			case TabAlignment.RIGHT:
				_style((_windowStyle & ~TCS_BOTTOM) | TCS_VERTICAL | TCS_RIGHT);
		}
		
		// Display rectangle changed.
		if(created && visible)
		{
			invalidate(true); // TODO: Update children too ?
			
			TabPage page = selectedTab;
			if(page)
				page.realBounds = displayRectangle;
		}
	}
	
	/// ditto
	final @property TabAlignment alignment() const // getter
	{
		// TCS_RIGHT and TCS_BOTTOM are the same flag.
		if(_windowStyle & TCS_VERTICAL)
		{
			if(_windowStyle & TCS_RIGHT)
				return TabAlignment.RIGHT;
			return TabAlignment.LEFT;
		}
		else
		{
			if(_windowStyle & TCS_BOTTOM)
				return TabAlignment.BOTTOM;
			return TabAlignment.TOP;
		}
	}
	
	
	///
	final @property void appearance(TabAppearance tappear) // setter
	{
		final switch(tappear)
		{
			case TabAppearance.NORMAL:
				_style(_windowStyle & ~(TCS_BUTTONS | TCS_FLATBUTTONS));
				break;
			
			case TabAppearance.BUTTONS:
				_style((_windowStyle & ~TCS_FLATBUTTONS) | TCS_BUTTONS);
				break;
			
			case TabAppearance.FLAT_BUTTONS:
				_style(_windowStyle | TCS_BUTTONS | TCS_FLATBUTTONS);
		}
		
		if(created && visible)
		{
			invalidate(false);
			
			TabPage page = selectedTab;
			if(page)
				page.realBounds = displayRectangle;
		}
	}
	
	/// ditto
	final @property TabAppearance appearance() const // getter
	{
		if(_windowStyle & TCS_FLATBUTTONS)
			return TabAppearance.FLAT_BUTTONS;
		if(_windowStyle & TCS_BUTTONS)
			return TabAppearance.BUTTONS;
		return TabAppearance.NORMAL;
	}
	
	
	///
	final @property void padding(Point newPadding) // setter
	{
		if (created)
		{
			TabCtrl_SetPadding(_hwnd, newPadding.x, newPadding.y);
			
			TabPage page = selectedTab;
			if(page)
				page.realBounds = displayRectangle;
		}
		
		_padding = newPadding;
	}
	
	/// ditto
	final @property Point padding() const // getter
	{
		return _padding;
	}
	
	
	///
	final @property inout(TabPageCollection) tabPages() inout nothrow // getter
	{
		return _tabPageCollection;
	}
	
	
	///
	final @property void multiline(bool byes) // setter
	{
		if(byes)
			_style(_style() | TCS_MULTILINE);
		else
			_style(_style() & ~TCS_MULTILINE);
		
		TabPage page = selectedTab;
		if(page)
			page.realBounds = displayRectangle;
	}
	
	/// ditto
	final @property bool multiline() const // getter
	{
		return (_style() & TCS_MULTILINE) != 0;
	}
	
	
	///
	final @property int rowCount() // getter
	{
		if(!created || !multiline)
			return 0;
		return TabCtrl_GetRowCount(_hwnd);
	}
	
	
	///
	final @property int tabCount() const // getter
	{
		return _tabPageCollection._tabPages.length.toI32;
	}
	
	
	///
	final @property void selectedIndex(int i) // setter
	{
		if(!created || !_tabPageCollection._tabPages.length)
			return;
		
		TabPage currentPage = selectedTab;
		if(currentPage is _tabPageCollection._tabPages[i])
			return; // Already selected.
		currentPage.realVisible = false;
		
		TabCtrl_SetCurSel(_hwnd, i);
		tabToFront(_tabPageCollection._tabPages[i]);
	}
	
	/// ditto
	// Returns -1 if there are no tabs selected.
	final @property int selectedIndex() // getter
	{
		if(!created || !_tabPageCollection._tabPages.length)
			return -1;
		return TabCtrl_GetCurSel(_hwnd);
	}
	
	
	///
	final @property void selectedTab(TabPage page) // setter
	{
		int i = tabPages.indexOf(page);
		if(-1 != i)
			selectedIndex = i;
	}
	
	/// ditto
	final @property TabPage selectedTab() // getter
	{
		int i = selectedIndex;
		if(-1 == i)
			return null;
		return _tabPageCollection._tabPages[i];
	}
	
	
	/+
	///
	final @property void showToolTips(bool byes) // setter
	{
		if(byes)
			_style(_style() | TCS_TOOLTIPS);
		else
			_style(_style() & ~TCS_TOOLTIPS);
	}
	
	/// ditto
	final @property bool showToolTips() // getter
	{
		return (_style() & TCS_TOOLTIPS) != 0;
	}
	+/
	
	
	protected override void onHandleCreated(EventArgs ea)
	{
		super.onHandleCreated(ea);

		TabCtrl_SetPadding(_hwnd, _padding.x, _padding.y);
		
		_tabPageCollection.doPages();
		
		// Bring selected tab to front.
		if(_tabPageCollection._tabPages.length)
		{
			int i = selectedIndex;
			if(-1 != i)
				tabToFront(_tabPageCollection._tabPages[i]);
		}
	}
	
	
	protected override void onLayout(LayoutEventArgs ea)
	{
		foreach (ref TabPage page; _tabPageCollection)
		{
			page.realBounds = displayRectangle;
		}
		
		//super.onLayout(ea); // Tab control shouldn't even have other controls on it.
		super.onLayout(ea); // Should call it for consistency. Ideally it just checks handlers.length == 0 and does nothing.
	}
	
	
	protected override void onDpiChanged(uint newDpi)
	{
		foreach (ref TabPage page; _tabPageCollection)
		{
			page.realBounds = displayRectangle;
		}
	}
	
	protected override void wndProc(ref Message m)
	{
		// TODO: support the tab control messages.
		super.wndProc(m);
	}
	
	
	protected override void onReflectedMessage(ref Message m)
	{
		NMHDR* nmh = cast(NMHDR*)m.lParam;
		
		switch(nmh.code)
		{
			case TCN_SELCHANGE:
				TabPage page = selectedTab;
				if(page)
					tabToFront(page);
				super.onReflectedMessage(m);
				return;
			
			case TCN_SELCHANGING:
				super.onReflectedMessage(m);
				if(!m.result) // Allowed.
				{
					TabPage page = selectedTab;
					if(page)
						page.realVisible = false;
				}
				return;
			
			default:
				super.onReflectedMessage(m);
		}
	}
	
	
	/+
	/+ package +/ /+ protected +/ override int _rtype() // package
	{
		return 0x20;
	}
	+/
	
	
private:
	Point _padding;
	TabPageCollection _tabPageCollection;
	
	
	void tabToFront(TabPage page)
	{
		page.realBounds = displayRectangle;
		//page.realVisible = true;
		SetWindowPos(page.handle, HWND_TOP, 0, 0, 0, 0, /+ SWP_NOACTIVATE | +/ SWP_NOMOVE | SWP_NOSIZE | SWP_SHOWWINDOW);
		assert(page.visible);
		
		/+
		// Make sure the previous tab isn't still focused.
		// Will "steal" focus if done programatically.
		SetFocus(handle);
		//SetFocus(page.handle);
		+/
	}
	
	
	void updateTabText(TabPage page, Dstring newText)
	in
	{
		assert(created);
	}
	do
	{
		int i = tabPages.indexOf(page);
		assert(-1 != i);
		
		TCITEM tci;
		tci.mask = TCIF_TEXT;
		tci.dwState = 0;
		tci.dwStateMask = 0;
		tci.iImage = -1;
		tci.cchTextMax = 0;

		if(dfl.internal.utf.useUnicode)
			tci.pszText = cast(typeof(tci.pszText))dfl.internal.utf.toUnicodez(newText);
		else
			tci.pszText = cast(typeof(tci.pszText))dfl.internal.utf.toAnsiz(newText);
		
		TabCtrl_SetItem(_hwnd, i, &tci);
		
		// Updating a tab's text could cause tab rows to be adjusted,
		// so update the selected tab's area.
		page = selectedTab;
		if(page)
			page.realBounds = displayRectangle;
	}
}

