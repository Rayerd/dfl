// Written by Christopher E. Miller
// See the included license.txt for copyright and license details.


///
module dfl.combobox;

private import dfl.internal.dlib;

private import dfl.listbox, dfl.application, dfl.base, dfl.internal.winapi;
private import dfl.event, dfl.drawing, dfl.collections, dfl.control,
	dfl.internal.utf;


private extern(Windows) void _initCombobox();


///
enum ComboBoxStyle: ubyte
{
	DROP_DOWN, ///
	DROP_DOWN_LIST, /// ditto
	SIMPLE, /// ditto
}


///
class ComboBox: ListControl // docmain
{
	this()
	{
		_initCombobox();
		
		wstyle |= WS_TABSTOP | WS_VSCROLL | CBS_DROPDOWN | CBS_AUTOHSCROLL | CBS_HASSTRINGS;
		wexstyle |= WS_EX_CLIENTEDGE;
		ctrlStyle |= ControlStyles.SELECTABLE;
		wclassStyle = comboboxClassStyle;
		
		icollection = createItemCollection();
	}
	
	
	///
	final @property void dropDownStyle(ComboBoxStyle ddstyle) // setter
	{
		LONG st;
		st = _style() & ~(CBS_DROPDOWN | CBS_DROPDOWNLIST | CBS_SIMPLE);
		
		final switch(ddstyle)
		{
			case ComboBoxStyle.DROP_DOWN:
				_style(st | CBS_DROPDOWN);
				break;
			
			case ComboBoxStyle.DROP_DOWN_LIST:
				_style(st | CBS_DROPDOWNLIST);
				break;
			
			case ComboBoxStyle.SIMPLE:
				_style(st | CBS_SIMPLE);
				break;
		}
		
		_crecreate();
	}
	
	/// ditto
	final @property ComboBoxStyle dropDownStyle() // getter
	{
		LONG st;
		st = _style() & (CBS_DROPDOWN | CBS_DROPDOWNLIST | CBS_SIMPLE);
		
		switch(st)
		{
			case CBS_DROPDOWN:
				return ComboBoxStyle.DROP_DOWN;
			
			case CBS_DROPDOWNLIST:
				return ComboBoxStyle.DROP_DOWN_LIST;
			
			case CBS_SIMPLE:
				return ComboBoxStyle.SIMPLE;
			default:
				assert(0);
		}
	}
	
	
	///
	final @property void integralHeight(bool byes) //setter
	{
		if(byes)
			_style(_style() & ~CBS_NOINTEGRALHEIGHT);
		else
			_style(_style() | CBS_NOINTEGRALHEIGHT);
		
		_crecreate();
	}
	
	/// ditto
	final @property bool integralHeight() // getter
	{
		return (_style() & CBS_NOINTEGRALHEIGHT) == 0;
	}
	
	
	///
	// This function has no effect if the drawMode is OWNER_DRAW_VARIABLE.
	@property void itemHeight(int h) // setter
	{
		if(drawMode == DrawMode.OWNER_DRAW_VARIABLE)
			return;
		
		iheight = h;
		
		if(isHandleCreated)
			prevwproc(CB_SETITEMHEIGHT, 0, h);
	}
	
	/// ditto
	// Return value is meaningless when drawMode is OWNER_DRAW_VARIABLE.
	@property int itemHeight() // getter
	{
		/+
		if(drawMode == DrawMode.OWNER_DRAW_VARIABLE || !isHandleCreated)
			return iheight;
		
		int result = prevwproc(CB_GETITEMHEIGHT, 0, 0);
		if(result == CB_ERR)
			result = iheight; // ?
		else
			iheight = result;
		
		return result;
		+/
		return iheight;
	}
	
	
	///
	override @property void selectedIndex(int idx) // setter
	{
		if(isHandleCreated)
		{
			prevwproc(CB_SETCURSEL, cast(WPARAM)idx, 0);
		}
	}
	
	/// ditto
	override @property int selectedIndex() //getter
	{
		if(isHandleCreated)
		{
			LRESULT result;
			result = prevwproc(CB_GETCURSEL, 0, 0);
			if(CB_ERR != result) // Redundant.
				return cast(int)result;
		}
		return -1;
	}
	
	
	///
	final @property void selectedItem(Object o) // setter
	{
		int i;
		i = items.indexOf(o);
		if(i != -1)
			selectedIndex = i;
	}
	
	/// ditto
	final @property void selectedItem(Dstring str) // setter
	{
		int i;
		i = items.indexOf(str);
		if(i != -1)
			selectedIndex = i;
	}
	
	/// ditto
	final @property Object selectedItem() // getter
	{
		int idx;
		idx = selectedIndex;
		if(idx == -1)
			return null;
		return items[idx];
	}
	
	
	///
	override @property void selectedValue(Object val) // setter
	{
		selectedItem = val;
	}
	
	/// ditto
	override @property void selectedValue(Dstring str) // setter
	{
		selectedItem = str;
	}
	
	/// ditto
	override @property Object selectedValue() // getter
	{
		return selectedItem;
	}
	
	
	///
	final @property void sorted(bool byes) // setter
	{
		/+
		if(byes)
			_style(_style() | CBS_SORT);
		else
			_style(_style() & ~CBS_SORT);
		+/
		_sorting = byes;
	}
	
	/// ditto
	final @property bool sorted() // getter
	{
		//return (_style() & CBS_SORT) != 0;
		return _sorting;
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
	
	
	///
	final int findString(Dstring str, int startIndex)
	{
		// TODO: find string if control not created ?
		
		int result = NO_MATCHES;
		
		if(isHandleCreated)
		{
			if(dfl.internal.utf.useUnicode)
				result = prevwproc(CB_FINDSTRING, startIndex, cast(LPARAM)dfl.internal.utf.toUnicodez(str));
			else
				result = prevwproc(CB_FINDSTRING, startIndex, cast(LPARAM)dfl.internal.utf.unsafeAnsiz(str));
			if(result == CB_ERR) // Redundant.
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
		
		if(isHandleCreated)
		{
			if(dfl.internal.utf.useUnicode)
				result = prevwproc(CB_FINDSTRINGEXACT, startIndex, cast(LPARAM)dfl.internal.utf.toUnicodez(str));
			else
				result = prevwproc(CB_FINDSTRINGEXACT, startIndex, cast(LPARAM)dfl.internal.utf.unsafeAnsiz(str));
			if(result == CB_ERR) // Redundant.
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
		int result = prevwproc(CB_GETITEMHEIGHT, idx, 0);
		if(CB_ERR == result)
			throw new DflException("Unable to obtain item height");
		return result;
	}
	
	
	///
	final @property void drawMode(DrawMode dm) // setter
	{
		LONG wl = _style() & ~(CBS_OWNERDRAWVARIABLE | CBS_OWNERDRAWFIXED);
		
		final switch(dm)
		{
			case DrawMode.OWNER_DRAW_VARIABLE:
				wl |= CBS_OWNERDRAWVARIABLE;
				break;
			
			case DrawMode.OWNER_DRAW_FIXED:
				wl |= CBS_OWNERDRAWFIXED;
				break;
			
			case DrawMode.NORMAL:
				break;
		}
		
		_style(wl);
		
		_crecreate();
	}
	
	/// ditto
	final @property DrawMode drawMode() // getter
	{
		LONG wl = _style();
		
		if(wl & CBS_OWNERDRAWVARIABLE)
			return DrawMode.OWNER_DRAW_VARIABLE;
		if(wl & CBS_OWNERDRAWFIXED)
			return DrawMode.OWNER_DRAW_FIXED;
		return DrawMode.NORMAL;
	}
	
	
	///
	final void selectAll()
	{
		if(isHandleCreated)
			prevwproc(CB_SETEDITSEL, 0, MAKELPARAM(0, cast(ushort)-1));
	}
	
	
	///
	final @property void maxLength(uint len) // setter
	{
		if(!len)
			lim = 0x7FFFFFFE;
		else
			lim = len;
		
		if(isHandleCreated)
		{
			Message m;
			m = Message(handle, CB_LIMITTEXT, cast(WPARAM)lim, 0);
			prevWndProc(m);
		}
	}
	
	/// ditto
	final @property uint maxLength() // getter
	{
		return lim;
	}
	
	
	///
	final @property void selectionLength(uint len) // setter
	{
		if(isHandleCreated)
		{
			uint v1, v2;
			prevwproc(CB_GETEDITSEL, cast(WPARAM)&v1, cast(LPARAM)&v2);
			v2 = v1 + len;
			prevwproc(CB_SETEDITSEL, 0, MAKELPARAM(v1, v2));
		}
	}
	
	/// ditto
	final @property uint selectionLength() // getter
	{
		if(isHandleCreated)
		{
			uint v1, v2;
			prevwproc(CB_GETEDITSEL, cast(WPARAM)&v1, cast(LPARAM)&v2);
			assert(v2 >= v1);
			return v2 - v1;
		}
		return 0;
	}
	
	
	///
	final @property void selectionStart(uint pos) // setter
	{
		if(isHandleCreated)
		{
			uint v1, v2;
			prevwproc(CB_GETEDITSEL, cast(WPARAM)&v1, cast(LPARAM)&v2);
			assert(v2 >= v1);
			v2 = pos + (v2 - v1);
			prevwproc(CB_SETEDITSEL, 0, MAKELPARAM(pos, v2));
		}
	}
	
	/// ditto
	final @property uint selectionStart() // getter
	{
		if(isHandleCreated)
		{
			uint v1, v2;
			prevwproc(CB_GETEDITSEL, cast(WPARAM)&v1, cast(LPARAM)&v2);
			return v1;
		}
		return 0;
	}
	
	
	///
	// Number of characters in the textbox.
	// This does not necessarily correspond to the number of chars; some characters use multiple chars.
	// Return may be larger than the amount of characters.
	// This is a lot faster than retrieving the text, but retrieving the text is completely accurate.
	@property uint textLength() // getter
	{
		if(!(ctrlStyle & ControlStyles.CACHE_TEXT) && isHandleCreated)
			//return cast(uint)SendMessageA(handle, WM_GETTEXTLENGTH, 0, 0);
			return cast(uint)dfl.internal.utf.sendMessage(handle, WM_GETTEXTLENGTH, 0, 0);
		return wtext.length;
	}
	
	
	///
	final @property void droppedDown(bool byes) // setter
	{
		if(isHandleCreated)
			prevwproc(CB_SHOWDROPDOWN, cast(WPARAM)byes, 0);
	}
	
	/// ditto
	final @property bool droppedDown() // getter
	{
		if(isHandleCreated)
			return prevwproc(CB_GETDROPPEDSTATE, 0, 0) != FALSE;
		return false;
	}
	
	
	///
	final @property void dropDownWidth(int w) // setter
	{
		if(dropw == w)
			return;
		
		if(w < 0)
			w = 0;
		dropw = w;
		
		if(isHandleCreated)
		{
			if(dropw < width)
				prevwproc(CB_SETDROPPEDWIDTH, width, 0);
			else
				prevwproc(CB_SETDROPPEDWIDTH, dropw, 0);
		}
	}
	
	/// ditto
	final @property int dropDownWidth() // getter
	{
		if(isHandleCreated)
		{
			int w;
			w = cast(int)prevwproc(CB_GETDROPPEDWIDTH, 0, 0);
			if(dropw != -1)
				dropw = w;
			return w;
		}
		else
		{
			if(dropw < width)
				return width;
			return dropw;
		}
	}
	
	
	///
	final @property ObjectCollection items() // getter
	{
		return icollection;
	}
	
	
	enum DEFAULT_ITEM_HEIGHT = 13;
	enum NO_MATCHES = CB_ERR;
	
	
	///
	static class ObjectCollection
	{
		protected this(ComboBox lbox)
		{
			this.lbox = lbox;
		}
		
		
		protected this(ComboBox lbox, Object[] range)
		{
			this.lbox = lbox;
			addRange(range);
		}
		
		
		protected this(ComboBox lbox, Dstring[] range)
		{
			this.lbox = lbox;
			addRange(range);
		}
		
		
		/+
		protected this(ComboBox lbox, ObjectCollection range)
		{
			this.lbox = lbox;
			addRange(range);
		}
		+/
		
		
		void add(Object value)
		{
			add2(value);
		}
		
		void add(Dstring value)
		{
			add(new ListString(value));
		}
		
		
		void addRange(Object[] range)
		{
			if(lbox.sorted)
			{
				foreach(Object value; range)
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
			foreach(Dstring s; range)
			{
				add(s);
			}
		}
		
		
		private:
		
		ComboBox lbox;
		Object[] _items;
		
		
		this()
		{
		}
		
		
		LRESULT insert2(WPARAM idx, Dstring val)
		{
			insert(idx, val);
			return idx;
		}
		
		
		LRESULT add2(Object val)
		{
			int i;
			if(lbox.sorted)
			{
				for(i = 0; i != _items.length; i++)
				{
					if(val < _items[i])
						break;
				}
			}
			else
			{
				i = _items.length;
			}
			
			insert(i, val);
			
			return i;
		}
		
		
		LRESULT add2(Dstring val)
		{
			return add2(new ListString(val));
		}
		
		
		void _added(size_t idx, Object val)
		{
			if(lbox.isHandleCreated)
			{
				if(dfl.internal.utf.useUnicode)
					lbox.prevwproc(CB_INSERTSTRING, idx, cast(LPARAM)dfl.internal.utf.toUnicodez(getObjectString(val)));
				else
					lbox.prevwproc(CB_INSERTSTRING, idx, cast(LPARAM)dfl.internal.utf.toAnsiz(getObjectString(val))); // Can this be unsafeAnsiz()?
			}
		}
		
		
		void _removed(size_t idx, Object val)
		{
			if(size_t.max == idx) // Clear all.
			{
				if(lbox.isHandleCreated)
				{
					lbox.prevwproc(CB_RESETCONTENT, 0, 0);
				}
			}
			else
			{
				if(lbox.isHandleCreated)
				{
					lbox.prevwproc(CB_DELETESTRING, cast(WPARAM)idx, 0);
				}
			}
		}
		
		
		public:
		
		mixin ListWrapArray!(Object, _items,
			_blankListCallback!(Object), _added,
			_blankListCallback!(Object), _removed,
			true, false, false) _wraparray;
	}
	
	
	///
	protected ObjectCollection createItemCollection()
	{
		return new ObjectCollection(this);
	}
	
	
	protected override void onHandleCreated(EventArgs ea)
	{
		super.onHandleCreated(ea);
		
		// Set the Ctrl ID to the HWND so that it is unique
		// and WM_MEASUREITEM will work properly.
		SetWindowLongA(hwnd, GWL_ID, cast(LONG)hwnd);
		
		//prevwproc(EM_SETLIMITTEXT, cast(WPARAM)lim, 0);
		maxLength = lim; // Call virtual function.
		
		if(dropw < width)
			prevwproc(CB_SETDROPPEDWIDTH, width, 0);
		else
			prevwproc(CB_SETDROPPEDWIDTH, dropw, 0);
		
		if(iheight != DEFAULT_ITEM_HEIGHT)
			prevwproc(CB_SETITEMHEIGHT, 0, iheight);
		
		Message m;
		m.hWnd = hwnd;
		m.msg = CB_INSERTSTRING;
		// Note: duplicate code.
		if(dfl.internal.utf.useUnicode)
		{
			foreach(int i, Object obj; icollection._items)
			{
				m.wParam = i;
				m.lParam = cast(LPARAM)dfl.internal.utf.toUnicodez(getObjectString(obj)); // <--
				
				prevWndProc(m);
				//if(CB_ERR == m.result || CB_ERRSPACE == m.result)
				if(m.result < 0)
					throw new DflException("Unable to add combo box item");
				
				//prevwproc(CB_SETITEMDATA, m.result, cast(LPARAM)cast(void*)obj);
			}
		}
		else
		{
			foreach(int i, Object obj; icollection._items)
			{
				m.wParam = i;
				m.lParam = cast(LPARAM)dfl.internal.utf.toAnsiz(getObjectString(obj)); // Can this be unsafeAnsiz()? // <--
				
				prevWndProc(m);
				//if(CB_ERR == m.result || CB_ERRSPACE == m.result)
				if(m.result < 0)
					throw new DflException("Unable to add combo box item");
				
				//prevwproc(CB_SETITEMDATA, m.result, cast(LPARAM)cast(void*)obj);
			}
		}
		
		//redrawEntire();
	}
	
	
	package final @property bool hasDropList() // getter
	{
		return dropDownStyle != ComboBoxStyle.SIMPLE;
	}
	
	
	// This is needed for the SIMPLE style.
	protected override void onPaintBackground(PaintEventArgs pea)
	{
		RECT rect;
		pea.clipRectangle.getRect(&rect);
		FillRect(pea.graphics.handle, &rect, parent.hbrBg); // Hack.
	}
	
	
	override void createHandle()
	{
		if(isHandleCreated)
			return;
		
		// TODO: check if correct implementation.
		if(hasDropList)
			wrect.height = DEFAULT_ITEM_HEIGHT * 8;
		
		Dstring ft;
		ft = wtext;
		
		super.createHandle();
		
		// Fix the cached window rect.
		// This is getting screen coords, not parent coords. Why was it here, anyway?
		//RECT rect;
		//GetWindowRect(hwnd, &rect);
		//wrect = Rect(&rect);
		
		// Fix the combo box's text since the initial window
		// text isn't put in the edit box for some reason.
		Message m;
		if(dfl.internal.utf.useUnicode)
			m = Message(hwnd, WM_SETTEXT, 0, cast(LPARAM)dfl.internal.utf.toUnicodez(ft));
		else
			m = Message(hwnd, WM_SETTEXT, 0, cast(LPARAM)dfl.internal.utf.toAnsiz(ft)); // Can this be unsafeAnsiz()?
		prevWndProc(m);
	}
	
	
	protected override void createParams(ref CreateParams cp)
	{
		super.createParams(cp);
		
		cp.className = COMBOBOX_CLASSNAME;
	}
	
	
	//DrawItemEventHandler drawItem;
	Event!(ComboBox, DrawItemEventArgs) drawItem;
	//MeasureItemEventHandler measureItem;
	Event!(ComboBox, MeasureItemEventArgs) measureItem;
	
	
	protected:
	override @property Size defaultSize() // getter
	{
		return Size(120, 23); // ?
	}
	
	
	void onDrawItem(DrawItemEventArgs dieh)
	{
		drawItem(this, dieh);
	}
	
	
	void onMeasureItem(MeasureItemEventArgs miea)
	{
		measureItem(this, miea);
	}
	
	
	package final void _WmDrawItem(DRAWITEMSTRUCT* dis)
	in
	{
		assert(dis.hwndItem == handle);
		assert(dis.CtlType == ODT_COMBOBOX);
	}
	body
	{
		DrawItemState state;
		state = cast(DrawItemState)dis.itemState;
		
		if(dis.itemID == -1)
		{
			if(state & DrawItemState.FOCUS)
				DrawFocusRect(dis.hDC, &dis.rcItem);
		}
		else
		{
			DrawItemEventArgs diea;
			Color bc, fc;
			
			if(state & DrawItemState.SELECTED)
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
			diea = new DrawItemEventArgs(new Graphics(dis.hDC, false), wfont,
				Rect(&dis.rcItem), dis.itemID, state, fc, bc);
			
			onDrawItem(diea);
		}
	}
	
	
	package final void _WmMeasureItem(MEASUREITEMSTRUCT* mis)
	in
	{
		assert(mis.CtlType == ODT_COMBOBOX);
	}
	body
	{
		MeasureItemEventArgs miea;
		scope Graphics gpx = new CommonGraphics(handle(), GetDC(handle));
		miea = new MeasureItemEventArgs(gpx, mis.itemID, /+ mis.itemHeight +/ iheight);
		miea.itemWidth = mis.itemWidth;
		
		onMeasureItem(miea);
		
		mis.itemHeight = miea.itemHeight;
		mis.itemWidth = miea.itemWidth;
	}
	
	
	override void prevWndProc(ref Message msg)
	{
		//msg.result = CallWindowProcA(comboboxPrevWndProc, msg.hWnd, msg.msg, msg.wParam, msg.lParam);
		msg.result = dfl.internal.utf.callWindowProc(comboboxPrevWndProc, msg.hWnd, msg.msg, msg.wParam, msg.lParam);
	}
	
	
	protected override void onReflectedMessage(ref Message m)
	{
		super.onReflectedMessage(m);
		
		switch(m.msg)
		{
			case WM_DRAWITEM:
				_WmDrawItem(cast(DRAWITEMSTRUCT*)m.lParam);
				m.result = 1;
				break;
			
			case WM_MEASUREITEM:
				_WmMeasureItem(cast(MEASUREITEMSTRUCT*)m.lParam);
				m.result = 1;
				break;
			
			/+
			case WM_CTLCOLORSTATIC:
			case WM_CTLCOLOREDIT:
				/+
				//SetBkColor(cast(HDC)m.wParam, backColor.toRgb()); // ?
				SetBkMode(cast(HDC)m.wParam, OPAQUE); // ?
				+/
				break;
			+/
			
			case WM_COMMAND:
				//assert(cast(HWND)msg.lParam == handle); // Might be one of its children.
				switch(HIWORD(m.wParam))
				{
					case CBN_SELCHANGE:
						/+
						if(drawMode != DrawMode.NORMAL)
						{
							// Hack.
							Object item = selectedItem;
							text = item ? getObjectString(item) : cast(Dstring)null;
						}
						+/
						onSelectedIndexChanged(EventArgs.empty);
						onTextChanged(EventArgs.empty); // ?
						break;
					
					case CBN_SETFOCUS:
						_wmSetFocus();
						break;
					
					case CBN_KILLFOCUS:
						_wmKillFocus();
						break;
					
					case CBN_EDITCHANGE:
						onTextChanged(EventArgs.empty); // ?
						break;
					
					default:
				}
				break;
			
			default:
		}
	}
	
	
	override void wndProc(ref Message msg)
	{
		switch(msg.msg)
		{
			case CB_ADDSTRING:
				//msg.result = icollection.add2(stringFromStringz(cast(char*)msg.lParam).dup); // TODO: fix.
				//msg.result = icollection.add2(stringFromStringz(cast(char*)msg.lParam).idup); // TODO: fix. // Needed in D2. Doesn't work in D1.
				msg.result = icollection.add2(cast(Dstring)stringFromStringz(cast(char*)msg.lParam).dup); // TODO: fix. // Needed in D2.
				return;
			
			case CB_INSERTSTRING:
				//msg.result = icollection.insert2(msg.wParam, stringFromStringz(cast(char*)msg.lParam).dup); // TODO: fix.
				//msg.result = icollection.insert2(msg.wParam, stringFromStringz(cast(char*)msg.lParam).idup); // TODO: fix. // Needed in D2. Doesn't work in D1.
				msg.result = icollection.insert2(msg.wParam, cast(Dstring)stringFromStringz(cast(char*)msg.lParam).dup); // TODO: fix. // Needed in D2.
				return;
			
			case CB_DELETESTRING:
				icollection.removeAt(msg.wParam);
				msg.result = icollection.length;
				return;
			
			case CB_RESETCONTENT:
				icollection.clear();
				return;
			
			case CB_SETITEMDATA:
				// Cannot set item data from outside DFL.
				msg.result = CB_ERR;
				return;
			
			case CB_DIR:
				msg.result = CB_ERR;
				return;
			
			case CB_LIMITTEXT:
				maxLength = msg.wParam;
				return;
			
			case WM_SETFOCUS:
			case WM_KILLFOCUS:
				prevWndProc(msg);
				return; // Handled by reflected message.
			
			default:
		}
		super.wndProc(msg);
	}
	
	
	private:
	int iheight = DEFAULT_ITEM_HEIGHT;
	int dropw = -1;
	ObjectCollection icollection;
	package uint lim = 30_000; // Documented as default.
	bool _sorting = false;
	
	
	package:
	final:
	LRESULT prevwproc(UINT msg, WPARAM wparam, LPARAM lparam)
	{
		//return CallWindowProcA(listviewPrevWndProc, hwnd, msg, wparam, lparam);
		return dfl.internal.utf.callWindowProc(comboboxPrevWndProc, hwnd, msg, wparam, lparam);
	}
}

