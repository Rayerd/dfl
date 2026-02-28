///
module dfl.toolbar;

import dfl.application;
import dfl.base;
import dfl.collections;
import dfl.control;
import dfl.drawing;
import dfl.event;
import dfl.imagelist;
import dfl.menu;

import dfl.internal.dlib;
import dfl.internal.dpiaware;
static import dfl.internal.utf;

import core.sys.windows.windef;
import core.sys.windows.winbase;
import core.sys.windows.winuser;
import core.sys.windows.wingdi;
import core.sys.windows.commctrl;


///
enum // Work around for TBMF_ not defined in dmd's core.sys.windows.commctrl
{
	TBMF_PAD = 0x00000001,
	TBMF_BARPAD = 0x00000002,
	TBMF_BUTTONSPACING = 0x00000004,
}

///
enum ToolBarButtonStyle: ubyte
{
	PUSH_BUTTON = BTNS_BUTTON, ///
	TOGGLE_BUTTON = BTNS_CHECK, /// ditto
	SEPARATOR = BTNS_SEP, /// ditto
	DROP_DOWN_BUTTON = BTNS_DROPDOWN | BTNS_WHOLEDROPDOWN, /// ditto
	PARTIAL_DROP_DOWN_BUTTON = BTNS_DROPDOWN, /// ditto (Extend)
	RADIO_BUTTON = BTNS_CHECKGROUP, /// ditto (Extend)
}


///
enum ToolBarStyle: ubyte
{
	NORMAL, ///
	LIST, /// ditto
}


///
enum ToolBarAppearance: ubyte
{
	NORMAL, ///
	FLAT, /// ditto
}


///
class ToolBarButton
{
	///
	this()
	{
		Application.ppin(cast(void*)this);
	}
	
	///
	this(Dstring text)
	{
		this();
		
		this.text = text;
		this.enabled = true;
	}
	
	
	///
	final @property void imageIndex(int index) // setter
	{
		this._imageIndex = index;
		
		//if(tbar && tbar.created)
		//	tbar.updateItem(this);
	}
	
	/// ditto
	final @property int imageIndex() const nothrow // getter
	{
		return _imageIndex;
	}
	
	
	///
	@property void text(Dstring newText) // setter
	{
		_text = newText;
		
		//if(tbar && tbar.created)
		//	
	}
	
	/// ditto
	@property Dstring text() const // getter
	{
		return _text;
	}
	
	
	///
	final @property void style(ToolBarButtonStyle st) // setter
	{
		this._style = st;
		
		//if(tbar && tbar.created)
		//	
	}
	
	/// ditto
	final @property inout(ToolBarButtonStyle) style() inout // getter
	{
		return _style;
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
	
	
	override int opCmp(Object o) const
	{
		return stringICmp(text, getObjectString(o));
	}
	
	
	int opCmp(Dstring val) const
	{
		return stringICmp(text, val);
	}
	
	
	///
	final @property void tag(Object o) // setter
	{
		_tag = o;
	}
	
	/// ditto
	final @property inout(Object) tag() inout nothrow // getter
	{
		return _tag;
	}
	
	
	///
	final @property void dropDownMenu(ContextMenu cmenu) // setter
	{
		_contextMenu = cmenu;
	}
	
	/// ditto
	final @property inout(ContextMenu) dropDownMenu() inout // getter
	{
		return _contextMenu;
	}
	
	
	///
	final @property inout(ToolBar) parent() inout // getter
	{
		return _toolBar;
	}
	
	
	///
	final @property Rect rectangle() // getter
	{
		//if(!tbar || !tbar.created)
		if (!visible)
			return Rect(0, 0, 0, 0); // TODO: ?
		assert(_toolBar !is null);
		RECT rect;
		//assert(-1 != tbar.buttons.indexOf(this));
		_toolBar.prevwproc(TB_GETITEMRECT, _toolBar.buttons.indexOf(this), cast(LPARAM)&rect); // Fails if item is hidden.
		return Rect(&rect); // Should return all 0`s if TB_GETITEMRECT failed.
	}
	
	
	///
	// NOTE: When -byes- is false, the pushed state of radio style button is cleared.
	final @property void visible(bool byes) // setter
	{
		if (byes)
			_state &= ~TBSTATE_HIDDEN;
		else
			_state |= TBSTATE_HIDDEN;
		
		if (_toolBar && _toolBar.created)
			_toolBar.prevwproc(TB_SETSTATE, _id, MAKELPARAM(_state, 0));
	}
	
	/// ditto
	final @property bool visible() // getter
	{
		if (_toolBar && _toolBar.created)
		{
			LRESULT hr = _toolBar.prevwproc(TB_GETSTATE, _id, 0);
			if (hr & TBSTATE_HIDDEN)
				_state |= TBSTATE_HIDDEN;
			else
				_state &= ~TBSTATE_HIDDEN;
		}
		return (_state & TBSTATE_HIDDEN) == 0;
	}
	
	
	///
	final @property void enabled(bool byes) // setter
	{
		if (byes)
			_state |= TBSTATE_ENABLED;
		else
			_state &= ~TBSTATE_ENABLED;
		
		if (_toolBar && _toolBar.created)
			_toolBar.prevwproc(TB_SETSTATE, _id, MAKELPARAM(_state, 0));
	}
	
	/// ditto
	final @property bool enabled() // getter
	{
		if (_toolBar && _toolBar.created)
		{
			LRESULT hr = _toolBar.prevwproc(TB_GETSTATE, _id, 0);
			if (hr & TBSTATE_ENABLED)
				_state |= TBSTATE_ENABLED;
			else
				_state &= ~TBSTATE_ENABLED;
		}
		return (_state & TBSTATE_ENABLED) != 0;
	}
	
	
	///
	final @property void pushed(bool byes) // setter
	{
		if (byes)
			_state = (_state & ~TBSTATE_INDETERMINATE) | TBSTATE_CHECKED;
		else
			_state &= ~(TBSTATE_CHECKED | TBSTATE_INDETERMINATE);
		
		if (_toolBar && _toolBar.created)
			_toolBar.prevwproc(TB_SETSTATE, _id, MAKELPARAM(_state, 0));
	}
	
	/// ditto
	final @property bool pushed() // getter
	{
		if (_toolBar && _toolBar.created)
		{
			LRESULT hr = _toolBar.prevwproc(TB_GETSTATE, _id, 0);
			if (hr & TBSTATE_CHECKED)
				_state |= TBSTATE_CHECKED;
			else
				_state &= ~TBSTATE_CHECKED;
		}
		return (_state & TBSTATE_CHECKED) != 0;
	}
	
	
	///
	final @property void partialPush(bool byes) // setter
	{
		if (byes)
			_state = (_state & ~TBSTATE_CHECKED) | TBSTATE_INDETERMINATE;
		else
			_state &= ~(TBSTATE_INDETERMINATE | TBSTATE_CHECKED);
		
		if (_toolBar && _toolBar.created)
			_toolBar.prevwproc(TB_SETSTATE, _id, MAKELPARAM(_state, 0));
	}
	
	/// ditto
	final @property bool partialPush() // getter
	{
		if (_toolBar && _toolBar.created)
		{
			LRESULT hr = _toolBar.prevwproc(TB_GETSTATE, _id, 0);
			if (hr & TBSTATE_INDETERMINATE)
				_state |= TBSTATE_INDETERMINATE;
			else
				_state &= ~TBSTATE_INDETERMINATE;
		}
		return (_state & TBSTATE_INDETERMINATE) != 0;
	}
	
	
private:
	ToolBar _toolBar;
	int _id = 0;
	Dstring _text;
	Object _tag;
	ToolBarButtonStyle _style = ToolBarButtonStyle.PUSH_BUTTON;
	BYTE _state;
	ContextMenu _contextMenu;
	int _imageIndex = -1;
}


///
class ToolBarButtonClickEventArgs: EventArgs
{
	this(ToolBarButton tbbtn)
	{
		_button = tbbtn;
	}
	
	
	///
	final @property ToolBarButton button() // getter
	{
		return _button;
	}
	
	
private:
	
	ToolBarButton _button;
}


///
class ToolBar: ControlSuperClass // docmain
{
	///
	class ToolBarButtonCollection
	{
		protected this()
		{
		}
		
		
	private:
		
		ToolBarButton[] _buttons;
		
		
		///
		void _adding(size_t idx, ToolBarButton val)
		{
			if (val._toolBar)
				throw new DflException("ToolBarButton already belongs to a ToolBar");
		}
		
		
		///
		void _added(size_t idx, ToolBarButton val)
		{
			val._toolBar = _toolBar;
			val._id = _toolBar._allocTbbID();
			
			if (created)
			{
				_ins(idx, val);
			}
		}
		
		
		///
		void _removed(size_t idx, ToolBarButton val)
		{
			if (size_t.max == idx) // Clear all.
			{
			}
			else
			{
				if (created)
				{
					prevwproc(TB_DELETEBUTTON, idx, 0);
				}
				val._toolBar = null;
			}
		}
		
		
	public:
		
		mixin ListWrapArray!(ToolBarButton, _buttons,
			_adding, _added,
			_blankListCallback!(ToolBarButton), _removed,
			true, false, false,
			true); // CLEAR_EACH
	}
	
	
	///
	private @property ToolBar _toolBar()
	{
		return this;
	}
	
	
	///
	this()
	{
		_initToolbar();
		
		_toolBarButtons = new ToolBarButtonCollection();
		
		dock = DockStyle.TOP;
		
		_windowClassStyle = toolbarClassStyle;
	}
	
	
	///
	final @property inout(ToolBarButtonCollection) buttons() inout // getter
	{
		return _toolBarButtons;
	}
	
	
	///
	final @property void buttonSize(Size sz) // setter
	{
		if (sz == _buttonSize) return;
		_buttonSize = sz;
		_setButtonSize(sz);
	}

	/// ditto
	final @property Size buttonSize() const // getter
	{
		return _buttonSize;
	}
	
	private void _setButtonSize(Size sz)
	{
		if (!isHandleCreated) return;

		const int buttonW = MulDiv(sz.width, dpi, USER_DEFAULT_SCREEN_DPI);
		const int buttonH = MulDiv(sz.height, dpi, USER_DEFAULT_SCREEN_DPI);
		SendMessage(handle, TB_SETBUTTONSIZE, 0, MAKELPARAM(buttonW, buttonH));

		// SendMessage(handle, TB_AUTOSIZE, 0, 0);
		// SendMessage(parent.handle, WM_SIZE, 0, 0);
	}

	
	///
	final @property ToolBarAppearance appearance() const nothrow // getter
	{
		return _appearance;
	}

	/// ditto
	final @property void appearance(ToolBarAppearance appearance) // setter
	{
		if (_appearance == appearance)
			return;
		_appearance = appearance;

		if (isHandleCreated)
		{
			LONG_PTR baseStyle = GetWindowLongPtr(handle, GWL_STYLE);
			final switch (_appearance)
			{
				case ToolBarAppearance.NORMAL:
					baseStyle |= TBSTYLE_TRANSPARENT;
					baseStyle &= ~TBSTYLE_FLAT;
					break;
				case ToolBarAppearance.FLAT:
					baseStyle |= TBSTYLE_FLAT;
					baseStyle &= ~TBSTYLE_TRANSPARENT;
					break;
			}
			SetWindowLongPtr(handle, GWL_STYLE, baseStyle);
			invalidate();
		}
	}

	
	///
	final @property ToolBarStyle style() const nothrow // getter
	{
		return _toolBarStyle;
	}

	/// ditto
	final @property void style(ToolBarStyle st) // setter
	{
		if (_toolBarStyle == st)
			return;
		_toolBarStyle = st;

		if (isHandleCreated)
		{
			ulong baseStyle = SendMessage(handle, TB_GETSTYLE, 0, 0);
			final switch (_toolBarStyle)
			{
				case ToolBarStyle.NORMAL:
					baseStyle &= ~TBSTYLE_LIST;
					break;
				case ToolBarStyle.LIST:
					baseStyle |= TBSTYLE_LIST;
					break;
			}
			// TODO: On case of use SendMessage(), text of buttons is not visible.
			// http://blog.sssoftware.main.jp/?eid=1947
			static if (1)
			{
				recreateHandle(); // Work around
			}
			else
			{
				SendMessage(handle, TB_SETSTYLE, 0, baseStyle);
				SendMessage(handle, TB_SETBUTTONSIZE, 0, MAKELPARAM(0, 0));
				SendMessage(handle, TB_AUTOSIZE, 0, 0);
			}
		}
	}


	///
	final @property BorderStyle borderStyle() // getter
	{
		if (isHandleCreated)
		{
			const ulong baseStyle = GetWindowLongPtr(handle, GWL_STYLE);
			const ulong baseExStyle = GetWindowLongPtr(handle, GWL_EXSTYLE);
			if (baseStyle & WS_BORDER)
				return _borderStyle = BorderStyle.FIXED_SINGLE;
			else if (baseExStyle & WS_EX_CLIENTEDGE)
				return _borderStyle = BorderStyle.FIXED_3D;
			else
				return _borderStyle = BorderStyle.NONE;
		}
		return _borderStyle;
	}

	/// ditto
	final @property void borderStyle(BorderStyle border) // setter
	{
		if (_borderStyle == border)
			return;
		_borderStyle = border;

		if (isHandleCreated)
		{
			LONG_PTR baseStyle = GetWindowLongPtr(handle, GWL_STYLE);
			LONG_PTR baseExStyle = GetWindowLongPtr(handle, GWL_EXSTYLE);
			final switch (border)
			{
				case BorderStyle.FIXED_SINGLE:
					baseStyle |= WS_BORDER;
					baseExStyle &= ~WS_EX_CLIENTEDGE;
					break;
				case BorderStyle.FIXED_3D:
					baseStyle &= ~WS_BORDER;
					baseExStyle |= WS_EX_CLIENTEDGE;
					break;
				case BorderStyle.NONE:
					baseStyle &= ~WS_BORDER;
					baseExStyle &= ~WS_EX_CLIENTEDGE;
					break;
			}
			SetWindowLongPtr(handle, GWL_STYLE, baseStyle);
			SetWindowLongPtr(handle, GWL_EXSTYLE, baseExStyle);
			SetWindowPos(handle, null, 0, 0, 0, 0, SWP_NOMOVE|SWP_NOSIZE|SWP_NOZORDER|SWP_FRAMECHANGED);
			invalidate();
		}
	}
	

	///
	final @property Size imageSize() const // getter
	{
		if (_imageList)
			return _imageList.imageSize;
		else
		{
			int cxIcon = GetSystemMetricsForDpi(SM_CXSMICON, dpi); // small icon size x
			int cyIcon = GetSystemMetricsForDpi(SM_CYSMICON, dpi); // small icon size y
			return Size(cxIcon, cyIcon);
		}
	}
	
	
	///
	final @property void imageList(ImageList imageList) // setter
	{
		_imageList = imageList;
	}
	
	/// ditto
	final @property inout(ImageList) imageList() inout // getter
	{
		return _imageList;
	}
	
	
	///
	Event!(ToolBar, ToolBarButtonClickEventArgs) buttonClick;
	
	
	///
	protected void onButtonClick(ToolBarButtonClickEventArgs ea)
	{
		buttonClick(this, ea);
	}
	
	
	///
	protected override void onReflectedMessage(ref Message m)
	{
		switch (m.msg)
		{
			case WM_NOTIFY:
			{
				auto nmh = cast(LPNMHDR)m.lParam;
				switch (nmh.code)
				{
					// case NM_CLICK: // I don't use it because it behaves strangely.
					case TBN_DROPDOWN:
					{
						LPNMTOOLBARA nmtb = cast(LPNMTOOLBARA)nmh; // NMTOOLBARA/NMTOOLBARW doesn't matter here; string fields not used.
						ToolBarButton tbb = buttomFromID(nmtb.iItem);
						if (tbb)
						{
							if (tbb._contextMenu)
							{
								Rect brect = tbb.rectangle;

								// NOTE: When arrow symbol is pressed twice, disable to call click event.
								SendMessage(handle, WM_LBUTTONUP, 0, 0); // Work around

								tbb._contextMenu.show(this, pointToScreen(Point(brect.x, brect.bottom)));
							}
						}
						return;
					}
					default:
						return;
				}
			}
			default:
			{
				super.onReflectedMessage(m);
				return;
			}
		}
	}
	
	
	///
	protected override void wndProc(ref Message m)
	{
		static bool wasClicked;
		static HWND clickedHwnd;
		static ToolBarButton clickedButton;
		switch (m.msg)
		{
			case WM_COMMAND:
			{
				prevWndProc(m); // Important for context menu within msgBox().
				return;
			}
			case WM_LBUTTONDOWN:
			{
				SetCapture(handle);
				Point pt = Point(GET_X_LPARAM(m.lParam), GET_Y_LPARAM(m.lParam));
				scope MouseEventArgs mea = new MouseEventArgs(MouseButtons.LEFT, 1, pt.x, pt.y, 0);
				onMouseDown(mea);

				wasClicked = true;
				clickedHwnd = null;
				clickedButton = null;
				
				if (Rect(0, 0, _clientSize.width, _clientSize.height).contains(pt))
				{
					if (pointOverVisibleChild(pt) == _hwnd)
					{
						for (size_t i; i < this.buttons.length; i++)
						{
							ToolBarButton b = this.buttons[i];
							if (b && b.rectangle.contains(pt.x, pt.y) && b.enabled)
							{
								clickedHwnd = this.handle;
								clickedButton = b;
								break; // for
							}
						}
					}
				}
				prevWndProc(m);
				return;
			}
			case WM_LBUTTONUP:
			{
				Point pt = Point(GET_X_LPARAM(m.lParam), GET_Y_LPARAM(m.lParam));
				scope MouseEventArgs mea = new MouseEventArgs(MouseButtons.LEFT, 1, pt.x, pt.y, 0);
				onMouseUp(mea);
				if (wasClicked && clickedHwnd == this.handle)
				{
					for (size_t i; i < this.buttons.length; i++)
					{
						ToolBarButton b = this.buttons[i];
						if (b && b.rectangle.contains(pt.x, pt.y) && b is clickedButton)
						{
							scope ToolBarButtonClickEventArgs tbbcea = new ToolBarButtonClickEventArgs(b);
							final switch (b.style)
							{
								case ToolBarButtonStyle.PUSH_BUTTON:
									b.pushed = false; // Work around for trouble on show Modal Window such as msgBox().
									onButtonClick(tbbcea);
									break;
								case ToolBarButtonStyle.DROP_DOWN_BUTTON:
									onButtonClick(tbbcea);
									break;
								case ToolBarButtonStyle.PARTIAL_DROP_DOWN_BUTTON:
									prevWndProc(m);
									onButtonClick(tbbcea);
									break;
								case ToolBarButtonStyle.RADIO_BUTTON:
									if (!b.pushed)
									{ // Disable duplicated push.
										prevWndProc(m);
										onButtonClick(tbbcea);
									}
									break;
								case ToolBarButtonStyle.TOGGLE_BUTTON:
									b.pushed = !b.pushed;
									onButtonClick(tbbcea);
									// Do not call prevWndProc().
									break;
								case ToolBarButtonStyle.SEPARATOR:
									// Do not call this onButtonClick().
									// Do not call prevWndProc().
									break;
							}
							break; // for
						}
					}
				}
				wasClicked = false;
				clickedHwnd = null;
				clickedButton = null;
				ReleaseCapture();
				return;
			}
			case WM_RBUTTONDOWN:
			{ // Cancel
				wasClicked = false;
				clickedHwnd = null;
				clickedButton = null;
				ReleaseCapture();
				return;
			}
			default:
			{
				// Do not call prevWndProc().
				super.wndProc(m);
				return;
			}
		}
	}
	

	///
	protected override @property Size defaultSize() const // getter
	{
		return Size(100, 16);
	}
	
	
	///
	protected override void createParams(ref CreateParams cp)
	{
		super.createParams(cp);
		
		final switch (_appearance)
		{
			case ToolBarAppearance.NORMAL:
				cp.style |= TBSTYLE_TRANSPARENT;
				cp.style &= ~TBSTYLE_FLAT;
				break;
			case ToolBarAppearance.FLAT:
				cp.style &= ~TBSTYLE_TRANSPARENT;
				cp.style |= TBSTYLE_FLAT;
				break;
		}

		final switch (_borderStyle)
		{
			case BorderStyle.NONE:
				cp.style &= ~WS_BORDER;
				cp.exStyle &= ~WS_EX_CLIENTEDGE;
				break;
			case BorderStyle.FIXED_SINGLE:
				cp.style |= WS_BORDER;
				cp.exStyle &= ~WS_EX_CLIENTEDGE;
				break;
			case BorderStyle.FIXED_3D:
				cp.style &= ~WS_BORDER;
				cp.exStyle |= WS_EX_CLIENTEDGE;
				break;
		}

		final switch (_toolBarStyle)
		{
			case ToolBarStyle.NORMAL:
				cp.style &= ~TBSTYLE_LIST;
				break;
			case ToolBarStyle.LIST:
				cp.style |= TBSTYLE_LIST;
				break;
		}
		
		cp.className = TOOLBAR_CLASSNAME;
	}
	
	
	///
	protected override void onHandleCreated(EventArgs ea)
	{
		super.onHandleCreated(ea);

		_buildToolBarButtons();
	}


	///
	protected override void onDpiChanged(uint newDpi)
	{
		_buildToolBarButtons();
	}


	///
	private void _buildToolBarButtons()
	{
		SendMessage(handle, TB_BUTTONSTRUCTSIZE, TBBUTTON.sizeof, 0); // Initialize ToolBar.
		SendMessage(handle, TB_SETEXTENDEDSTYLE, 0, TBSTYLE_EX_DRAWDDARROWS); // Enable Drop-Down-Arrows-Button on ToolBar.

		if (_imageList)
		{
			ImageList oldImageList = _imageListForDpi;
			_imageListForDpi = createImageListForDpi(_imageList, dpi);
			if (oldImageList)
				oldImageList.dispose;

			// NOTE: This is required for the bitmap method, but not for the image list method.
			// const int cxIcon = GetSystemMetricsForDpi(SM_CXSMICON, dpi);
			// const int cyIcon = GetSystemMetricsForDpi(SM_CYSMICON, dpi);
			// SendMessage(handle, TB_SETBITMAPSIZE, 0, MAKELPARAM(cxIcon, cyIcon));

			if (_imageListForDpi)
				SendMessage(handle, TB_SETIMAGELIST, cast(WPARAM)0, cast(LPARAM)_imageListForDpi.handle);
		}

		while (1)
		{
			if (0 == SendMessage(handle, TB_BUTTONCOUNT, 0, 0))
				break;
			SendMessage(handle, TB_DELETEBUTTON, 0, 0);
		}

		foreach (idx, tbb; _toolBarButtons._buttons)
		{
			_ins(idx, tbb);
		}

		TBMETRICS tbm;
		tbm.cbSize = TBMETRICS.sizeof;
		tbm.dwMask = TBMF_PAD | TBMF_BUTTONSPACING;
		// SendMessage(handle, TB_GETMETRICS, 0, cast(LPARAM)&tbm);
		tbm.cxPad = MulDiv(7, dpi, USER_DEFAULT_SCREEN_DPI);
		tbm.cyPad = MulDiv(6, dpi, USER_DEFAULT_SCREEN_DPI);
		tbm.cxButtonSpacing = 0;
		tbm.cyButtonSpacing = 0;
		SendMessage(handle, TB_SETMETRICS, 0, cast(LPARAM)&tbm);

		_setButtonSize(_buttonSize); // TODO: ?

		SendMessage(handle, TB_AUTOSIZE, 0, 0);
		SendMessage(parent.handle, WM_SIZE, 0, 0);
	}


	// Used internally
	/+package+/ final inout(ToolBarButton) buttomFromID(int id) inout // package
	{
		foreach (tbb; _toolBarButtons._buttons)
		{
			if (id == tbb._id)
				return tbb;
		}
		return null;
	}
	
	
	package int _lastTbbID = 0;
	
	///
	package final int _allocTbbID()
	{
		for (int j = 0; j != 250; j++)
		{
			_lastTbbID++;
			if (_lastTbbID >= short.max)
				_lastTbbID = 1;
			
			if (!buttomFromID(_lastTbbID))
				return _lastTbbID;
		}
		return 0;
	}
	
	
	///
	protected override void prevWndProc(ref Message msg)
	{
		//msg.result = CallWindowProcA(toolbarPrevWndProc, msg.hWnd, msg.msg, msg.wParam, msg.lParam);
		msg.result = dfl.internal.utf.callWindowProc(toolbarPrevWndProc, msg.hWnd, msg.msg, msg.wParam, msg.lParam);
	}
	
	
private:
	
	ToolBarButtonCollection _toolBarButtons;
	ToolBarAppearance _appearance = ToolBarAppearance.NORMAL;
	ToolBarStyle _toolBarStyle = ToolBarStyle.NORMAL;
	BorderStyle _borderStyle = BorderStyle.NONE;
	ImageList _imageList;
	ImageList _imageListForDpi;
	Size _buttonSize;
	

	///
	void _ins(size_t idx, ToolBarButton tbb)
	{
		// TODO: To change: TB_SETBUTTONINFO
		
		TBBUTTON xtb;
		xtb.iBitmap = tbb._imageIndex;
		xtb.idCommand = tbb._id;
		xtb.dwData = cast(DWORD)cast(void*)tbb;
		xtb.fsState = tbb._state;
		xtb.fsStyle = TBSTYLE_AUTOSIZE | tbb.style; // TBSTYLE_AUTOSIZE factors in the text's width instead of default button size.

		// MSDN says iString can be either an int offset or pointer to a string buffer.
		if (tbb._text.length)
		{
			if (dfl.internal.utf.useUnicode)
				xtb.iString = cast(typeof(xtb.iString))dfl.internal.utf.toUnicodez(tbb._text);
			else
				xtb.iString = cast(typeof(xtb.iString))dfl.internal.utf.toAnsiz(tbb._text);
		}

		LRESULT lresult = prevwproc(TB_INSERTBUTTON, idx, cast(LPARAM)&xtb);

		if(!lresult)
			throw new DflException("Unable to add ToolBarButton");
	}
	
	
package:
final:
	///
	LRESULT prevwproc(UINT msg, WPARAM wparam, LPARAM lparam)
	{
		//return CallWindowProcA(toolbarPrevWndProc, hwnd, msg, wparam, lparam);
		return dfl.internal.utf.callWindowProc(toolbarPrevWndProc, _hwnd, msg, wparam, lparam);
	}
}


private
{
	enum TOOLBAR_CLASSNAME = "DFL_ToolBar";
	
	WNDPROC toolbarPrevWndProc;
	
	LONG toolbarClassStyle;
	
	void _initToolbar()
	{
		if (!toolbarPrevWndProc)
		{
			_initCommonControls(ICC_BAR_CLASSES);
			
			dfl.internal.utf.WndClass info;
			toolbarPrevWndProc = superClass(HINSTANCE.init, "ToolbarWindow32", TOOLBAR_CLASSNAME, info);
			if (!toolbarPrevWndProc)
				_unableToInit(TOOLBAR_CLASSNAME);
			toolbarClassStyle = info.wc.style;
		}
	}
}
