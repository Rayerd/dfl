///
module dfl.toolbar;

private import dfl.base, dfl.control, dfl.drawing, dfl.application,
	dfl.event, dfl.collections;
private import dfl.internal.winapi, dfl.internal.dlib;

version(DFL_NO_IMAGELIST)
{
}
else
{
	private import dfl.imagelist;
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
	}
	
	
	version(DFL_NO_IMAGELIST)
	{
	}
	else
	{
		///
		final void imageIndex(int index) // setter
		{
			this._imgidx = index;
			
			//if(tbar && tbar.created)
			//	tbar.updateItem(this);
		}
		
		/// ditto
		final int imageIndex() // getter
		{
			return _imgidx;
		}
	}
	
	
	///
	void text(Dstring newText) // setter
	{
		_text = newText;
		
		//if(tbar && tbar.created)
		//	
	}
	
	/// ditto
	Dstring text() // getter
	{
		return _text;
	}
	
	
	override Dstring toString()
	{
		return text;
	}
	
	
	override int opEquals(Object o)
	{
		return text == getObjectString(o);
	}
	
	
	int opEquals(Dstring val)
	{
		return text == val;
	}
	
	
	override int opCmp(Object o)
	{
		return stringICmp(text, getObjectString(o));
	}
	
	
	int opCmp(Dstring val)
	{
		return stringICmp(text, val);
	}
	
	
	private:
	ToolBar tbar;
	Dstring _text;
	version(DFL_NO_IMAGELIST)
	{
	}
	else
	{
		int _imgidx = -1;
	}
}


///
class ToolBarButtonClickEventArgs: EventArgs
{
	this(ToolBarButton tbbtn)
	{
		_btn = tbbtn;
	}
	
	
	///
	final ToolBarButton button() // getter
	{
		return _btn;
	}
	
	
	private:
	
	ToolBarButton _btn;
}


///
class ToolBar: ControlSuperClass // docmain
{
	class ToolBarButtonCollection
	{
		protected this()
		{
		}
		
		
		private:
		
		ToolBarButton[] _buttons;
		
		
		void _adding(size_t idx, ToolBarButton val)
		{
			if(val.tbar)
				throw new DflException("ToolBarButton already belongs to a ToolBar");
		}
		
		
		void _added(size_t idx, ToolBarButton val)
		{
			val.tbar = tbar;
			
			if(created)
			{
				_ins(idx, val);
			}
		}
		
		
		void _removed(size_t idx, ToolBarButton val)
		{
			if(size_t.max == idx) // Clear all.
			{
			}
			else
			{
				if(created)
				{
					prevwproc(TB_DELETEBUTTON, idx, 0);
				}
			}
		}
		
		
		public:
		
		mixin ListWrapArray!(ToolBarButton, _buttons,
			_adding, _added,
			_blankListCallback!(ToolBarButton), _removed,
			true, false, false,
			true); // CLEAR_EACH
	}
	
	
	private ToolBar tbar()
	{
		return this;
	}
	
	
	this()
	{
		_initToolbar();
		
		_tbuttons = new ToolBarButtonCollection();
		
		dock = DockStyle.TOP;
		
		//wexstyle |= WS_EX_CLIENTEDGE;
		wclassStyle = toolbarClassStyle;
	}
	
	
	///
	final ToolBarButtonCollection buttons() // getter
	{
		return _tbuttons;
	}
	
	
	// buttonSize...
	
	
	///
	final Size imageSize() // getter
	{
		version(DFL_NO_IMAGELIST)
		{
		}
		else
		{
			if(_imglist)
				return _imglist.imageSize;
		}
		return Size(16, 16); // ?
	}
	
	
	version(DFL_NO_IMAGELIST)
	{
	}
	else
	{
		///
		final void imageList(ImageList imglist) // setter
		{
			if(isHandleCreated)
			{
				prevwproc(TB_SETIMAGELIST, 0, cast(WPARAM)imglist.handle);
			}
			
			_imglist = imglist;
		}
		
		/// ditto
		final ImageList imageList() // getter
		{
			return _imglist;
		}
	}
	
	
	///
	Event!(ToolBar, ToolBarButtonClickEventArgs) buttonClick;
	
	
	///
	protected void onButtonClick(ToolBarButtonClickEventArgs ea)
	{
		buttonClick(this, ea);
	}
	
	
	protected override void onReflectedMessage(inout Message m)
	{
		switch(m.msg)
		{
			case WM_NOTIFY:
				{
					auto nmh = cast(LPNMHDR)m.lParam;
					switch(nmh.code)
					{
						case NM_CLICK:
							{
								auto nmm = cast(LPNMMOUSE)nmh;
								if(nmm.dwItemData)
								{
									auto tbb = cast(ToolBarButton)cast(void*)nmm.dwItemData;
									scope ToolBarButtonClickEventArgs bcea = new ToolBarButtonClickEventArgs(tbb);
									onButtonClick(bcea);
								}
							}
							break;
						
						default: ;
					}
				}
				break;
			
			default: ;
				super.onReflectedMessage(m);
		}
	}
	
	
	protected override Size defaultSize() // getter
	{
		return Size(100, 16);
	}
	
	
	protected override void createParams(inout CreateParams cp)
	{
		super.createParams(cp);
		
		cp.className = TOOLBAR_CLASSNAME;
	}
	
	
	protected override void onHandleCreated(EventArgs ea)
	{
		super.onHandleCreated(ea);
		
		static assert(TBBUTTON.sizeof == 20);
		prevwproc(TB_BUTTONSTRUCTSIZE, TBBUTTON.sizeof, 0);
		
		if(_imglist)
			prevwproc(TB_SETIMAGELIST, 0, cast(WPARAM)_imglist.handle);
		
		foreach(idx, tbb; _tbuttons._buttons)
		{
			_ins(idx, tbb);
		}
	}
	
	
	protected override void prevWndProc(inout Message msg)
	{
		//msg.result = CallWindowProcA(toolbarPrevWndProc, msg.hWnd, msg.msg, msg.wParam, msg.lParam);
		msg.result = dfl.internal.utf.callWindowProc(toolbarPrevWndProc, msg.hWnd, msg.msg, msg.wParam, msg.lParam);
	}
	
	
	private:
	
	ToolBarButtonCollection _tbuttons;
	
	version(DFL_NO_IMAGELIST)
	{
	}
	else
	{
		ImageList _imglist;
	}
	
	
	void _ins(size_t idx, ToolBarButton tbb)
	{
		// To change: TB_SETBUTTONINFO
		
		TBBUTTON xtb;
		version(DFL_NO_IMAGELIST)
		{
			xtb.iBitmap = -1;
		}
		else
		{
			xtb.iBitmap = tbb._imgidx;
		}
		//xtb.idCommand = 42;
		xtb.dwData = cast(DWORD)cast(void*)tbb;
		xtb.fsState = TBSTATE_ENABLED;
		xtb.fsStyle = BTNS_AUTOSIZE;
		LRESULT lresult;
		// MSDN says iString can be either an int offset or pointer to a string buffer.
		if(dfl.internal.utf.useUnicode)
		{
			xtb.iString = cast(typeof(xtb.iString))dfl.internal.utf.toUnicodez(tbb._text);
			//prevwproc(TB_ADDBUTTONSW, 1, cast(LPARAM)&xtb);
			lresult = prevwproc(TB_INSERTBUTTONW, idx, cast(LPARAM)&xtb);
		}
		else
		{
			xtb.iString = cast(typeof(xtb.iString))dfl.internal.utf.toAnsiz(tbb._text);
			//prevwproc(TB_ADDBUTTONSA, 1, cast(LPARAM)&xtb);
			lresult = prevwproc(TB_INSERTBUTTONA, idx, cast(LPARAM)&xtb);
		}
		//if(!lresult)
		//	throw new DflException("Unable to add ToolBarButton");
	}
	
	
	package:
	final:
	LRESULT prevwproc(UINT msg, WPARAM wparam, LPARAM lparam)
	{
		//return CallWindowProcA(toolbarPrevWndProc, hwnd, msg, wparam, lparam);
		return dfl.internal.utf.callWindowProc(toolbarPrevWndProc, hwnd, msg, wparam, lparam);
	}
}


private
{
	const Dstring TOOLBAR_CLASSNAME = "DFL_ToolBar";
	
	WNDPROC toolbarPrevWndProc;
	
	LONG toolbarClassStyle;
	
	void _initToolbar()
	{
		if(!toolbarPrevWndProc)
		{
			_initCommonControls(ICC_BAR_CLASSES);
			
			dfl.internal.utf.WndClass info;
			toolbarPrevWndProc = superClass(HINSTANCE.init, "ToolbarWindow32", TOOLBAR_CLASSNAME, info);
			if(!toolbarPrevWndProc)
				_unableToInit(TOOLBAR_CLASSNAME);
			toolbarClassStyle = info.wc.style;
		}
	}
}

