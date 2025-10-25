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
import dfl.internal.winapi;
static import dfl.internal.utf;


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
		// Note: this probably causes toStringz() to be called twice,
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
		// DMD 0.124: if I don't put this here, super.setBoundsCore ends up calling setBoundsCore instead of super.setBoundsCore.
		void delegate(int, int, int, int, BoundsSpecified) _foo = &setBoundsCore;
		
		super.setBoundsCore(r.x, r.y, r.width, r.height, BoundsSpecified.ALL);
	}
	
	
	protected override void setVisibleCore(bool byes)
	{
		assert(0); // Cannot set visibility of TabPage; it is done automatically.
	}
	
	
	package final @property void realVisible(bool byes) // setter
	{
		// DMD 0.124: if I don't put this here, super.setVisibleCore ends up calling setVisibleCore instead of super.setVisibleCore.
		void delegate(bool byes) _foo = &setVisibleCore;
		
		super.setVisibleCore(byes);
	}
}


package union TcItem
{
	TC_ITEMW tciw;
	TC_ITEMA tcia;
	struct
	{
		UINT mask;
		UINT lpReserved1;
		UINT lpReserved2;
		private void* pszText;
		int cchTextMax;
		int iImage;
		LPARAM lParam;
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
		tc = owner;
	}
	
	
private:
	
	TabControl tc;
	TabPage[] _pages = null;
	
	
	void doPages()
	in
	{
		assert(created);
	}
	do
	{
		Message m;
		m.hWnd = tc.handle;
		
		// Note: duplicate code.
		//TC_ITEMA tci;
		TcItem tci;
		if(dfl.internal.utf.useUnicode)
		{
			m.msg = TCM_INSERTITEMW; // <--
			foreach(i, TabPage page; _pages)
			{
				// TODO: TCIF_RTLREADING flag based on rightToLeft property.
				tci.mask = TCIF_TEXT | TCIF_PARAM;
				tci.tciw.pszText = cast(typeof(tci.tciw.pszText))dfl.internal.utf.toUnicodez(page.text); // <--
				static assert(tci.lParam.sizeof >= (void*).sizeof);
				tci.lParam = cast(LPARAM)cast(void*)page;
				
				m.wParam = i;
				m.lParam = cast(LPARAM)&tci.tciw;
				tc.prevWndProc(m);
				assert(cast(int)m.result != -1);
			}
		}
		else
		{
			m.msg = TCM_INSERTITEMA; // <--
			foreach(i, TabPage page; _pages)
			{
				// TODO: TCIF_RTLREADING flag based on rightToLeft property.
				tci.mask = TCIF_TEXT | TCIF_PARAM;
				tci.tcia.pszText = cast(typeof(tci.tcia.pszText))dfl.internal.utf.toAnsiz(page.text); // <--
				static assert(tci.lParam.sizeof >= (void*).sizeof);
				tci.lParam = cast(LPARAM)cast(void*)page;
				
				m.wParam = i;
				m.lParam = cast(LPARAM)&tci.tcia;
				tc.prevWndProc(m);
				assert(cast(int)m.result != -1);
			}
		}
	}
	
	
	package final @property bool created() const // getter
	{
		return tc && tc.created();
	}
	
	
	void _added(size_t idx, TabPage val)
	{
		if(val.parent)
		{
			TabControl parentTC = cast(TabControl)val.parent;
			if(parentTC && parentTC.tabPages.indexOf(val) != -1)
				throw new DflException("TabPage already has a parent");
		}
		
		//val.realVisible = false;
		assert(val.visible == false);
		assert(!(tc is null));
		val.parent = tc;
		
		if(created)
		{
			Message m;
			//TC_ITEMA tci;
			TcItem tci;
			// TODO: TCIF_RTLREADING flag based on rightToLeft property.
			tci.mask = TCIF_TEXT | TCIF_PARAM;
			static assert(tci.lParam.sizeof >= (void*).sizeof);
			tci.lParam = cast(LPARAM)cast(void*)val;
			if(dfl.internal.utf.useUnicode)
			{
				tci.tciw.pszText = cast(typeof(tci.tciw.pszText))dfl.internal.utf.toUnicodez(val.text);
				m = Message(tc.handle, TCM_INSERTITEMW, idx, cast(LPARAM)&tci.tciw);
			}
			else
			{
				tci.tcia.pszText = cast(typeof(tci.tcia.pszText))dfl.internal.utf.toAnsiz(val.text);
				m = Message(tc.handle, TCM_INSERTITEMA, idx, cast(LPARAM)&tci.tcia);
			}
			tc.prevWndProc(m);
			assert(cast(int)m.result != -1);
			
			if(tc.selectedTab is val)
			{
				//val.realVisible = true;
				tc.tabToFront(val);
			}
		}
	}
	
	
	void _removed(size_t idx, TabPage val)
	{
		if(size_t.max == idx) // Clear all.
		{
			if(created)
			{
				Message m = Message(tc.handle, TCM_DELETEALLITEMS, 0, 0);
				tc.prevWndProc(m);
			}
		}
		else
		{
			//val.parent = null; // Can't do that.
			
			if(created)
			{
				Message m = Message(tc.handle, TCM_DELETEITEM, idx, 0);
				tc.prevWndProc(m);
				
				// Hide this one.
				val.realVisible = false;
				
				// Show next visible.
				val = tc.selectedTab;
				if(val)
					tc.tabToFront(val);
			}
		}
	}
	
	
public:
	
	mixin ListWrapArray!(TabPage, _pages,
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
		switch(dm)
		{
		case TabDrawMode.OWNER_DRAW_FIXED:
			_style(_windowStyle | TCS_OWNERDRAWFIXED);
			break;
		
		case TabDrawMode.NORMAL:
			_style(_windowStyle & ~TCS_OWNERDRAWFIXED);
			break;
		
		default:
			assert(0);
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
			RECT drr;
			drr.left = 0;
			drr.top = 0;
			drr.right = clientSize.width;
			drr.bottom = clientSize.height;
			Message m = Message(_hwnd, TCM_ADJUSTRECT, FALSE, cast(LPARAM)&drr);
			prevWndProc(m);
			return Rect(&drr);
		}
	}
	
	
	protected override @property Size defaultSize() const // getter
	{
		return Size(200, 200); // TODO: ?
	}
	
	
	///
	final Rect getTabRect(int i)
	{
		Rect result;
		
		if(created)
		{
			RECT rt;
			Message m = Message(_hwnd, TCM_GETITEMRECT, cast(WPARAM)i, cast(LPARAM)&rt);
			prevWndProc(m);
			if(!m.result)
				goto rtfail;
			result = Rect(&rt);
		}
		else
		{
		rtfail:
			with(result)
			{
				x = 0;
				y = 0;
				width = 0;
				height = 0;
			}
		}
		
		return result;
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
	
	
	protected override void onReflectedMessage(ref Message m)
	{
		super.onReflectedMessage(m);
		
		NMHDR* nmh = cast(NMHDR*)m.lParam;
		
		switch(nmh.code)
		{
		case TCN_SELCHANGE:
			onSelectedIndexChanged(EventArgs.empty);
			break;
		
		case TCN_SELCHANGING:
			{
				scope CancelEventArgs ea = new CancelEventArgs;
				onSelectedIndexChanging(ea);
				if(ea.cancel)
				{
					m.result = TRUE; // Prevent change.
					return;
				}
			}
			m.result = FALSE; // Allow change.
			return;
		
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
		_pad = Point(6, 3);
	}
	
	
	///
	final @property void alignment(TabAlignment talign) // setter
	{
		switch(talign)
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
			break;
		
		default:
			assert(0);
		}
		
		// Display rectangle changed.
		
		if(created && visible)
		{
			invalidate(true); // Update children too ?
			
			TabPage page = selectedTab;
			if(page)
				page.realBounds = displayRectangle;
		}
	}
	
	/// ditto
	final @property TabAlignment alignment() const // getter
	{
		// NOTE: TCS_RIGHT and TCS_BOTTOM are the same flag.
		
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
		switch(tappear)
		{
		case TabAppearance.NORMAL:
			_style(_windowStyle & ~(TCS_BUTTONS | TCS_FLATBUTTONS));
			break;
		
		case TabAppearance.BUTTONS:
			_style((_windowStyle & ~TCS_FLATBUTTONS) | TCS_BUTTONS);
			break;
		
		case TabAppearance.FLAT_BUTTONS:
			_style(_windowStyle | TCS_BUTTONS | TCS_FLATBUTTONS);
			break;
		
		default:
			assert(0);
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
	final @property void padding(Point pad) // setter
	{
		if(created)
		{
			SendMessageA(_hwnd, TCM_SETPADDING, 0, MAKELPARAM(pad.x, pad.y));
			
			TabPage page = selectedTab;
			if(page)
				page.realBounds = displayRectangle;
		}
		
		_pad = pad;
	}
	
	/// ditto
	final @property Point padding() const // getter
	{
		return _pad;
	}
	
	
	///
	final @property TabPageCollection tabPages() // getter
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
		Message m = Message(_hwnd, TCM_GETROWCOUNT, 0, 0);
		prevWndProc(m);
		return cast(int)m.result;
	}
	
	
	///
	final @property int tabCount() const // getter
	{
		return _tabPageCollection._pages.length.toI32;
	}
	
	
	///
	final @property void selectedIndex(int i) // setter
	{
		if(!created || !_tabPageCollection._pages.length)
			return;
		
		TabPage curpage = selectedTab;
		if(curpage is _tabPageCollection._pages[i])
			return; // Already selected.
		curpage.realVisible = false;
		
		SendMessageA(_hwnd, TCM_SETCURSEL, cast(WPARAM)i, 0);
		tabToFront(_tabPageCollection._pages[i]);
	}
	
	/// ditto
	// Returns -1 if there are no tabs selected.
	final @property int selectedIndex() // getter
	{
		if(!created || !_tabPageCollection._pages.length)
			return -1;
		Message m = Message(_hwnd, TCM_GETCURSEL, 0, 0);
		prevWndProc(m);
		return cast(int)m.result;
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
		return _tabPageCollection._pages[i];
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
		
		SendMessageA(_hwnd, TCM_SETPADDING, 0, MAKELPARAM(_pad.x, _pad.y));
		
		_tabPageCollection.doPages();
		
		// Bring selected tab to front.
		if(_tabPageCollection._pages.length)
		{
			int i = selectedIndex;
			if(-1 != i)
				tabToFront(_tabPageCollection._pages[i]);
		}
	}
	
	
	protected override void onLayout(LayoutEventArgs ea)
	{
		if(_tabPageCollection._pages.length)
		{
			int i = selectedIndex;
			if(-1 != i)
			{
				_tabPageCollection._pages[i].realBounds = displayRectangle;
				//assert(tchildren._pages[i].bounds == displayRectangle);
			}
		}
		
		//super.onLayout(ea); // Tab control shouldn't even have other controls on it.
		super.onLayout(ea); // Should call it for consistency. Ideally it just checks handlers.length == 0 and does nothing.
	}
	
	
	/+
	protected override void wndProc(ref Message m)
	{
		// TODO: support the tab control messages.
		
		switch(m.msg)
		{
			/+ // Now handled in onLayout().
			case WM_WINDOWPOSCHANGED:
				{
					WINDOWPOS* wp;
					wp = cast(WINDOWPOS*)m.lParam;
					
					if(!(wp.flags & SWP_NOSIZE) || (wp.flags & SWP_FRAMECHANGED))
					{
						if(tchildren._pages.length)
						{
							int i;
							i = selectedIndex;
							if(-1 != i)
							{
								tchildren._pages[i].realBounds = displayRectangle;
								//assert(tchildren._pages[i].bounds == displayRectangle);
							}
						}
					}
				}
				break;
			+/
			
			default:
		}
		
		super.wndProc(m);
	}
	+/
	
	
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
			break;
		
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
	Point _pad;
	TabPageCollection _tabPageCollection;
	
	
	void tabToFront(TabPage page)
	{
		page.realBounds = displayRectangle;
		//page.realVisible = true;
		SetWindowPos(page.handle, HWND_TOP, 0, 0, 0, 0, /+ SWP_NOACTIVATE | +/ SWP_NOMOVE | SWP_NOSIZE | SWP_SHOWWINDOW);
		assert(page.visible == true);
		
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
		
		//TC_ITEMA tci;
		TcItem tci;
		tci.mask = TCIF_TEXT;
		Message m;
		if(dfl.internal.utf.useUnicode)
		{
			tci.tciw.pszText = cast(typeof(tci.tciw.pszText))dfl.internal.utf.toUnicodez(newText);
			m = Message(_hwnd, TCM_SETITEMW, cast(WPARAM)i, cast(LPARAM)&tci.tciw);
		}
		else
		{
			tci.tcia.pszText = cast(typeof(tci.tcia.pszText))dfl.internal.utf.toAnsiz(newText);
			m = Message(_hwnd, TCM_SETITEMA, cast(WPARAM)i, cast(LPARAM)&tci.tcia);
		}
		prevWndProc(m);
		
		// Updating a tab's text could cause tab rows to be adjusted,
		// so update the selected tab's area.
		page = selectedTab;
		if(page)
			page.realBounds = displayRectangle;
	}
}

