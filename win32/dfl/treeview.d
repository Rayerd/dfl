// Written by Christopher E. Miller
// See the included license.txt for copyright and license details.


///
module dfl.treeview;

private import dfl.internal.dlib;

private import dfl.control, dfl.application, dfl.base, dfl.internal.winapi;
private import dfl.event, dfl.drawing, dfl.collections, dfl.internal.utf;

version(DFL_NO_IMAGELIST)
{
}
else
{
	private import dfl.imagelist;
}


private extern(Windows) void _initTreeview();


///
enum TreeViewAction: ubyte
{
	UNKNOWN, ///
	COLLAPSE, /// ditto
	EXPAND, /// ditto
	BY_KEYBOARD, /// ditto
	BY_MOUSE, /// ditto
}


///
class TreeViewCancelEventArgs: CancelEventArgs
{
	///
	this(TreeNode node, bool cancel, TreeViewAction action)
	{
		super(cancel);
		
		_node = node;
		_action = action;
	}
	
	
	///
	final @property TreeViewAction action() // getter
	{
		return _action;
	}
	
	
	///
	final @property TreeNode node() // getter
	{
		return _node;
	}
	
	
	private:
	TreeNode _node;
	TreeViewAction _action;
}


///
class TreeViewEventArgs: EventArgs
{
	///
	this(TreeNode node, TreeViewAction action)
	{
		_node = node;
		_action = action;
	}
	
	/// ditto
	this(TreeNode node)
	{
		_node = node;
		//_action = TreeViewAction.UNKNOWN;
	}
	
	
	///
	final @property TreeViewAction action() // getter
	{
		return _action;
	}
	
	
	///
	final @property TreeNode node() // getter
	{
		return _node;
	}
	
	
	private:
	TreeNode _node;
	TreeViewAction _action = TreeViewAction.UNKNOWN;
}


///
class NodeLabelEditEventArgs: EventArgs
{
	///
	this(TreeNode node, Dstring label)
	{
		_node = node;
		_label = label;
	}
	
	/// ditto
	this(TreeNode node)
	{
		_node = node;
	}
	
	
	///
	final @property TreeNode node() // getter
	{
		return _node;
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
	TreeNode _node;
	Dstring _label;
	bool _cancel = false;
}


///
class TreeNode: DObject
{
	///
	this(Dstring labelText)
	{
		this();
		
		ttext = labelText;
	}
	
	/// ditto
	this(Dstring labelText, TreeNode[] children)
	{
		this();
		
		ttext = labelText;
		tchildren.addRange(children);
	}
	
	/// ditto
	this()
	{
		Application.ppin(cast(void*)this);
		
		/+
		bcolor = Color.empty;
		fcolor = Color.empty;
		+/
		
		tchildren = new TreeNodeCollection(tview, this);
	}
	
	this(Object val) // package
	{
		this(getObjectString(val));
	}
	
	
	/+
	///
	final @property void backColor(Color c) // setter
	{
		bcolor = c;
	}
	
	/// ditto
	final @property Color backColor() // getter
	{
		return bcolor;
	}
	+/
	
	
	///
	final @property Rect bounds() // getter
	{
		Rect result;
		
		if(created)
		{
			RECT rect;
			*(cast(HTREEITEM*)&rect) = hnode;
			if(SendMessageA(tview.handle, TVM_GETITEMRECT, FALSE, cast(LPARAM)&rect))
			{
				result = Rect(&rect);
			}
		}
		
		return result;
	}
	
	
	///
	final @property TreeNode firstNode() // getter
	{
		if(tchildren.length)
			return tchildren._nodes[0];
		return null;
	}
	
	
	/+
	///
	final @property void foreColor(Color c) // setter
	{
		fcolor = c;
	}
	
	/// ditto
	final @property Color foreColor() // getter
	{
		return fcolor;
	}
	+/
	
	
	///
	// Path from the root to this node.
	final @property Dstring fullPath() // getter
	{
		if(!tparent)
			return ttext;
		
		// Might want to manually loop through parents and preallocate the whole buffer.
		assert(tview !is null);
		dchar sep;
		sep = tview.pathSeparator;
		//return std.string.format("%s%s%s", tparent.fullPath, sep, ttext);
		char[4] ssep;
		int sseplen = 0;
		foreach(char ch; (&sep)[0 .. 1])
		{
			ssep[sseplen++] = ch;
		}
		//return tparent.fullPath ~ ssep[0 .. sseplen] ~ ttext;
		return tparent.fullPath ~ cast(Dstring)ssep[0 .. sseplen] ~ ttext; // Needed in D2.
	}
	
	
	///
	final @property HTREEITEM handle() // getter
	{
		return hnode;
	}
	
	
	///
	// Index of this node in the parent node.
	final @property int index() // getter
	{
		int result = -1;
		if(tparent)
		{
			result = tparent.tchildren.indexOf(this);
			assert(result != -1);
		}
		return result;
	}
	
	
	/+
	///
	final @property bool isEditing() // getter
	{
	}
	+/
	
	
	///
	final @property bool isExpanded() // getter
	{
		return isState(TVIS_EXPANDED);
	}
	
	
	///
	final @property bool isSelected() // getter
	{
		return isState(TVIS_SELECTED);
	}
	
	
	/+
	///
	final @property bool isVisible() // getter
	{
	}
	+/
	
	
	///
	final @property TreeNode lastNode() // getter
	{
		if(tchildren.length)
			return tchildren._nodes[tchildren.length - 1];
		return null;
	}
	
	
	///
	// Next sibling node.
	final @property TreeNode nextNode() // getter
	{
		if(tparent)
		{
			int i;
			i = tparent.tchildren.indexOf(this);
			assert(i != -1);
			
			i++;
			if(i != tparent.tchildren.length)
				return tparent.tchildren._nodes[i];
		}
		return null;
	}
	
	
	/+
	///
	final @property void nodeFont(Font f) // setter
	{
		tfont = f;
	}
	
	/// ditto
	final @property Font nodeFont() // getter
	{
		return tfont;
	}
	+/
	
	
	///
	final @property TreeNodeCollection nodes() // getter
	{
		return tchildren;
	}
	
	
	///
	final @property TreeNode parent() // getter
	{
		return tparent;
	}
	
	
	///
	// Previous sibling node.
	final @property TreeNode prevNode() // getter
	{
		if(tparent)
		{
			int i;
			i = tparent.tchildren.indexOf(this);
			assert(i != -1);
			
			if(i)
			{
				i--;
				return tparent.tchildren._nodes[i];
			}
		}
		return null;
	}
	
	
	///
	final @property void tag(Object o) // setter
	{
		ttag = o;
	}
	
	/// ditto
	final @property Object tag() // getter
	{
		return ttag;
	}
	
	
	///
	final @property void text(Dstring newText) // setter
	{
		ttext = newText;
		
		if(created)
		{
			TV_ITEMA item;
			Message m;
			
			item.mask = TVIF_HANDLE | TVIF_TEXT;
			item.hItem = hnode;
			/+
			item.pszText = stringToStringz(ttext);
			//item.cchTextMax = ttext.length; // ?
			m = Message(tview.handle, TVM_SETITEMA, 0, cast(LPARAM)&item);
			+/
			if(dfl.internal.utf.useUnicode)
			{
				item.pszText = cast(typeof(item.pszText))dfl.internal.utf.toUnicodez(ttext);
				m = Message(tview.handle, TVM_SETITEMW, 0, cast(LPARAM)&item);
			}
			else
			{
				item.pszText = cast(typeof(item.pszText))dfl.internal.utf.unsafeAnsiz(ttext);
				m = Message(tview.handle, TVM_SETITEMA, 0, cast(LPARAM)&item);
			}
			tview.prevWndProc(m);
		}
	}
	
	/// ditto
	final @property Dstring text() // getter
	{
		return ttext;
	}
	
	
	///
	// Get the TreeView control this node belongs to.
	final @property TreeView treeView() // getter
	{
		return tview;
	}
	
	
	///
	final void beginEdit()
	{
		if(created)
		{
			SetFocus(tview.hwnd); // Needs to have focus.
			HWND hwEdit;
			hwEdit = cast(HWND)SendMessageA(tview.hwnd, TVM_EDITLABELA, 0, cast(LPARAM)hnode);
			if(!hwEdit)
				goto err_edit;
		}
		else
		{
			err_edit:
			throw new DflException("Unable to edit TreeNode");
		}
	}
	
	
	/+
	///
	final void endEdit(bool cancel)
	{
		// ?
	}
	+/
	
	
	///
	final void ensureVisible()
	{
		if(created)
		{
			SendMessageA(tview.hwnd, TVM_ENSUREVISIBLE, 0, cast(LPARAM)hnode);
		}
	}
	
	
	///
	final void collapse()
	{
		if(created)
		{
			SendMessageA(tview.hwnd, TVM_EXPAND, TVE_COLLAPSE, cast(LPARAM)hnode);
		}
	}
	
	
	///
	final void expand()
	{
		if(created)
		{
			SendMessageA(tview.hwnd, TVM_EXPAND, TVE_EXPAND, cast(LPARAM)hnode);
		}
	}
	
	
	///
	final void expandAll()
	{
		if(created)
		{
			SendMessageA(tview.hwnd, TVM_EXPAND, TVE_EXPAND, cast(LPARAM)hnode);
			
			foreach(TreeNode node; tchildren._nodes)
			{
				node.expandAll();
			}
		}
	}
	
	
	///
	static TreeNode fromHandle(TreeView tree, HTREEITEM handle)
	{
		return tree.treeNodeFromHandle(handle);
	}
	
	
	///
	final void remove()
	{
		if(tparent)
			tparent.tchildren.remove(this);
		else if(tview) // It's a top level node.
			tview.tchildren.remove(this);
	}
	
	
	///
	final void toggle()
	{
		if(created)
		{
			SendMessageA(tview.hwnd, TVM_EXPAND, TVE_TOGGLE, cast(LPARAM)hnode);
		}
	}
	
	
	version(DFL_NO_IMAGELIST)
	{
	}
	else
	{
		///
		final @property void imageIndex(int index) // setter
		{
			this._imgidx = index;
			
			if(created)
			{
				TV_ITEMA item;
				Message m;
				m = Message(tview.handle, TVM_SETITEMA, 0, cast(LPARAM)&item);
				
				item.mask = TVIF_HANDLE | TVIF_IMAGE;
				item.hItem = hnode;
				item.iImage = _imgidx;
				if(tview._selimgidx < 0)
				{
					item.mask |= TVIF_SELECTEDIMAGE;
					item.iSelectedImage = _imgidx;
				}
				tview.prevWndProc(m);
			}
		}
		
		/// ditto
		final @property int imageIndex() // getter
		{
			return _imgidx;
		}
	}
	
	
	override Dstring toString()
	{
		return ttext;
	}
	
	
	override Dequ opEquals(Object o)
	{
		return 0 == stringICmp(ttext, getObjectString(o)); // ?
	}
	
	Dequ opEquals(TreeNode node)
	{
		return 0 == stringICmp(ttext, node.ttext);
	}
	
	Dequ opEquals(Dstring val)
	{
		return 0 == stringICmp(ttext, val);
	}
	
	
	override int opCmp(Object o)
	{
		return stringICmp(ttext, getObjectString(o)); // ?
	}
	
	int opCmp(TreeNode node)
	{
		return stringICmp(ttext, node.ttext);
	}
	
	int opCmp(Dstring val)
	{
		return stringICmp(text, val);
	}
	
	
	private:
	Dstring ttext;
	TreeNode tparent;
	TreeNodeCollection tchildren;
	Object ttag;
	HTREEITEM hnode;
	TreeView tview;
	version(DFL_NO_IMAGELIST)
	{
	}
	else
	{
		int _imgidx = -1;
	}
	/+
	Color bcolor, fcolor;
	Font tfont;
	+/
	
	
	package final @property bool created() // getter
	{
		if(tview && tview.created())
		{
			assert(hnode);
			return true;
		}
		return false;
	}
	
	
	bool isState(UINT state)
	{
		if(created)
		{
			TV_ITEMA ti;
			ti.mask = TVIF_HANDLE | TVIF_STATE;
			ti.hItem = hnode;
			ti.stateMask = state;
			if(SendMessageA(tview.handle, TVM_GETITEMA, 0, cast(LPARAM)&ti))
			{
				if(ti.state & state)
					return true;
			}
		}
		return false;
	}
	
	
	void _reset()
	{
		hnode = null;
		tview = null;
		tparent = null;
	}
}


///
class TreeNodeCollection
{
	void add(TreeNode node)
	{
		//cprintf("Adding node %p '%.*s'\n", cast(void*)node, getObjectString(node));
		
		int i;
		
		if(tview && tview.sorted())
		{
			// Insertion sort.
			
			for(i = 0; i != _nodes.length; i++)
			{
				if(node < _nodes[i])
					break;
			}
		}
		else
		{
			i = _nodes.length;
		}
		
		insert(i, node);
	}
	
	void add(Dstring text)
	{
		return add(new TreeNode(text));
	}
	
	void add(Object val)
	{
		return add(new TreeNode(getObjectString(val))); // ?
	}
	
	
	void addRange(Object[] range)
	{
		foreach(Object o; range)
		{
			add(o);
		}
	}
	
	void addRange(TreeNode[] range)
	{
		foreach(TreeNode node; range)
		{
			add(node);
		}
	}
	
	void addRange(Dstring[] range)
	{
		foreach(Dstring s; range)
		{
			add(s);
		}
	}
	
	
	// Like clear but doesn't bother removing stuff from the lists.
	// Used when a parent is being removed and the children only
	// need to be reset.
	private void _reset()
	{
		foreach(TreeNode node; _nodes)
		{
			node._reset();
		}
	}
	
	
	// Clear node handles when the TreeView window is destroyed so
	// that it can be reconstructed.
	private void _resetHandles()
	{
		foreach(TreeNode node; _nodes)
		{
			node.tchildren._resetHandles();
			node.hnode = null;
		}
	}
	
	
	private:
	
	TreeView tview; // null if not assigned to a TreeView yet.
	TreeNode tparent; // null if root. The parent of -_nodes-.
	TreeNode[] _nodes;
	
	
	void verifyNoParent(TreeNode node)
	{
		if(node.tparent)
			throw new DflException("TreeNode already belongs to a TreeView");
	}
	
	
	package this(TreeView treeView, TreeNode parentNode)
	{
		tview = treeView;
		tparent = parentNode;
	}
	
	
	package final void setTreeView(TreeView treeView)
	{
		tview = treeView;
		foreach(TreeNode node; _nodes)
		{
			node.tchildren.setTreeView(treeView);
		}
	}
	
	
	package final @property bool created() // getter
	{
		return tview && tview.created();
	}
	
	
	package void populateInsertChildNode(ref Message m, ref TV_ITEMA dest, TreeNode node)
	{
		with(dest)
		{
			mask = /+ TVIF_CHILDREN | +/ TVIF_PARAM | TVIF_TEXT;
			version(DFL_NO_IMAGELIST)
			{
			}
			else
			{
				mask |= TVIF_IMAGE | TVIF_SELECTEDIMAGE;
				iImage = node._imgidx;
				if(tview._selimgidx < 0)
					iSelectedImage = node._imgidx;
				else
					iSelectedImage = tview._selimgidx;
			}
			/+ cChildren = I_CHILDRENCALLBACK; +/
			lParam = cast(LPARAM)cast(void*)node;
			/+
			pszText = stringToStringz(node.text);
			//cchTextMax = node.text.length; // ?
			+/
			if(dfl.internal.utf.useUnicode)
			{
				pszText = cast(typeof(pszText))dfl.internal.utf.toUnicodez(node.text);
				m.hWnd = tview.handle;
				m.msg = TVM_INSERTITEMW;
			}
			else
			{
				pszText = cast(typeof(pszText))dfl.internal.utf.unsafeAnsiz(node.text);
				m.hWnd = tview.handle;
				m.msg = TVM_INSERTITEMA;
			}
		}
	}
	
	
	void doNodes()
	in
	{
		assert(created);
	}
	body
	{
		TV_INSERTSTRUCTA tis;
		Message m;
		
		tis.hInsertAfter = TVI_LAST;
		
		m.hWnd = tview.handle;
		m.wParam = 0;
		
		foreach(TreeNode node; _nodes)
		{
			assert(!node.handle);
			
			tis.hParent = tparent ? tparent.handle : TVI_ROOT;
			populateInsertChildNode(m, tis.item, node);
			
			m.lParam = cast(LPARAM)&tis;
			tview.prevWndProc(m);
			assert(m.result);
			node.hnode = cast(HTREEITEM)m.result;
			
			node.tchildren.doNodes();
		}
	}
	
	
	void _added(size_t idx, TreeNode val)
	{
		verifyNoParent(val);
		
		val.tparent = tparent;
		val.tview = tview;
		val.tchildren.setTreeView(tview);
		
		if(created)
		{
			TV_INSERTSTRUCTA tis;
			
			if(idx <= 0)
			{
				tis.hInsertAfter = TVI_FIRST;
			}
			else if(idx >= cast(int)_nodes.length)
			{
				tis.hInsertAfter = TVI_LAST;
			}
			else
			{
				tis.hInsertAfter = _nodes[idx - 1].handle;
			}
			
			tis.hParent = tparent ? tparent.handle : TVI_ROOT;
			assert(tis.hInsertAfter);
			
			Message m;
			m.wParam = 0;
			
			populateInsertChildNode(m, tis.item, val);
			
			m.lParam = cast(LPARAM)&tis;
			tview.prevWndProc(m);
			assert(m.result);
			val.hnode = cast(HTREEITEM)m.result;
			
			val.tchildren.doNodes();
			
			if(tparent)
				tview.invalidate(tparent.bounds);
		}
	}
	
	
	void _removing(size_t idx, TreeNode val)
	{
		if(size_t.max == idx) // Clearing all...
		{
			TreeNode[] nodes = _nodes;
			_nodes = _nodes[0 .. 0]; // Not nice to dfl.collections, but OK.
			if(created)
			{
				Message m;
				m.hWnd = tview.handle;
				m.msg = TVM_DELETEITEM;
				m.wParam = 0;
				if(tparent)
				{
					foreach(TreeNode node; nodes)
					{
						assert(node.handle !is null);
						m.lParam = cast(LPARAM)node.handle;
						tview.prevWndProc(m);
						
						node._reset();
					}
				}
				else
				{
					m.lParam = TVI_ROOT;
					tview.prevWndProc(m);
					foreach(TreeNode node; nodes)
					{
						node._reset();
					}
				}
			}
		}
		else
		{
		}
	}
	
	
	void _removed(size_t idx, TreeNode val)
	{
		if(size_t.max == idx) // Clear all.
		{
		}
		else
		{
			if(created)
			{
				assert(val.hnode);
				Message m;
				m = Message(tview.handle, TVM_DELETEITEM, 0, cast(LPARAM)val.hnode);
				tview.prevWndProc(m);
			}
			
			// Clear children.
			val._reset();
		}
	}
	
	
	public:
	
	mixin ListWrapArray!(TreeNode, _nodes,
		_blankListCallback!(TreeNode), _added,
		_removing, _removed,
		true, /+true+/ false, false) _wraparray;
}


///
class TreeView: ControlSuperClass // docmain
{
	this()
	{
		_initTreeview();
		
		wstyle |= WS_TABSTOP | TVS_HASBUTTONS | TVS_LINESATROOT | TVS_HASLINES;
		wexstyle |= WS_EX_CLIENTEDGE;
		ctrlStyle |= ControlStyles.SELECTABLE;
		wclassStyle = treeviewClassStyle;
		
		tchildren = new TreeNodeCollection(this, null);
	}
	
	
	/+
	~this()
	{
		/+
		if(tchildren)
			tchildren._dtorReset();
		+/
	}
	+/
	
	
	static @property Color defaultBackColor() // getter
	{
		return SystemColors.window;
	}
	
	
	override @property Color backColor() // getter
	{
		if(Color.empty == backc)
			return defaultBackColor;
		return backc;
	}
	
	
	override @property void backColor(Color b) // setter
	{
		super.backColor = b;
		
		if(created)
		{
			// For some reason the left edge isn't showing the new color.
			// This causes the entire control to be redrawn with the new color.
			// Sets the same font.
			prevwproc(WM_SETFONT, this.font ? cast(WPARAM)this.font.handle : 0, MAKELPARAM(TRUE, 0));
		}
	}
	
	
	static @property Color defaultForeColor() //getter
	{
		return SystemColors.windowText;
	}
	
	
	override @property Color foreColor() // getter
	{
		if(Color.empty == forec)
			return defaultForeColor;
		return forec;
	}
	
	alias Control.foreColor foreColor; // Overload.
	
	
	final @property void borderStyle(BorderStyle bs) // setter
	{
		final switch(bs)
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
		
		if(created)
		{
			redrawEntire();
		}
	}
	
	
	final @property BorderStyle borderStyle() // getter
	{
		if(_exStyle() & WS_EX_CLIENTEDGE)
			return BorderStyle.FIXED_3D;
		else if(_style() & WS_BORDER)
			return BorderStyle.FIXED_SINGLE;
		return BorderStyle.NONE;
	}
	
	
	/+
	///
	final @property void checkBoxes(bool byes) // setter
	{
		if(byes)
			_style(_style() | TVS_CHECKBOXES);
		else
			_style(_style() & ~TVS_CHECKBOXES);
		
		_crecreate();
	}
	
	/// ditto
	final @property bool checkBoxes() // getter
	{
		return (_style() & TVS_CHECKBOXES) != 0;
	}
	+/
	
	
	///
	final @property void fullRowSelect(bool byes) // setter
	{
		if(byes)
			_style(_style() | TVS_FULLROWSELECT);
		else
			_style(_style() & ~TVS_FULLROWSELECT);
		
		_crecreate(); // ?
	}
	
	/// ditto
	final @property bool fullRowSelect() // getter
	{
		return (_style() & TVS_FULLROWSELECT) != 0;
	}
	
	
	///
	final @property void hideSelection(bool byes) // setter
	{
		if(byes)
			_style(_style() & ~TVS_SHOWSELALWAYS);
		else
			_style(_style() | TVS_SHOWSELALWAYS);
	}
	
	/// ditto
	final @property bool hideSelection() // getter
	{
		return (_style() & TVS_SHOWSELALWAYS) == 0;
	}
	
	
	deprecated alias hoverSelection hotTracking;
	
	///
	final @property void hoverSelection(bool byes) // setter
	{
		if(byes)
			_style(_style() | TVS_TRACKSELECT);
		else
			_style(_style() & ~TVS_TRACKSELECT);
	}
	
	/// ditto
	final @property bool hoverSelection() // getter
	{
		return (_style() & TVS_TRACKSELECT) != 0;
	}
	
	
	///
	final @property void indent(int newIndent) // setter
	{
		if(newIndent < 0)
			newIndent = 0;
		else if(newIndent > 32_000)
			newIndent = 32_000;
		
		ind = newIndent;
		
		if(created)
			SendMessageA(hwnd, TVM_SETINDENT, ind, 0);
	}
	
	/// ditto
	final @property int indent() // getter
	{
		if(created)
			ind = cast(int)SendMessageA(hwnd, TVM_GETINDENT, 0, 0);
		return ind;
	}
	
	
	///
	final @property void itemHeight(int h) // setter
	{
		if(h < 0)
			h = 0;
		
		iheight = h;
		
		if(created)
			SendMessageA(hwnd, TVM_SETITEMHEIGHT, iheight, 0);
	}
	
	/// ditto
	final @property int itemHeight() // getter
	{
		if(created)
			iheight = cast(int)SendMessageA(hwnd, TVM_GETITEMHEIGHT, 0, 0);
		return iheight;
	}
	
	
	///
	final @property void labelEdit(bool byes) // setter
	{
		if(byes)
			_style(_style() | TVS_EDITLABELS);
		else
			_style(_style() & ~TVS_EDITLABELS);
	}
	
	/// ditto
	final @property bool labelEdit() // getter
	{
		return (_style() & TVS_EDITLABELS) != 0;
	}
	
	
	///
	final @property TreeNodeCollection nodes() // getter
	{
		return tchildren;
	}
	
	
	///
	final @property void pathSeparator(dchar sep) // setter
	{
		pathsep = sep;
	}
	
	/// ditto
	final @property dchar pathSeparator() // getter
	{
		return pathsep;
	}
	
	
	///
	final @property void scrollable(bool byes) // setter
	{
		if(byes)
			_style(_style() & ~TVS_NOSCROLL);
		else
			_style(_style() | TVS_NOSCROLL);
		
		if(created)
			redrawEntire();
	}
	
	/// ditto
	final @property bool scrollable() // getter
	{
		return (_style & TVS_NOSCROLL) == 0;
	}
	
	
	///
	final @property void selectedNode(TreeNode node) // setter
	{
		if(created)
		{
			if(node)
			{
				SendMessageA(hwnd, TVM_SELECTITEM, TVGN_CARET, cast(LPARAM)node.handle);
			}
			else
			{
				// Should the selection be cleared if -node- is null?
				//SendMessageA(hwnd, TVM_SELECTITEM, TVGN_CARET, cast(LPARAM)null);
			}
		}
	}
	
	/// ditto
	final @property TreeNode selectedNode() // getter
	{
		if(created)
		{
			HTREEITEM hnode;
			hnode = cast(HTREEITEM)SendMessageA(hwnd, TVM_GETNEXTITEM, TVGN_CARET, cast(LPARAM)null);
			if(hnode)
				return treeNodeFromHandle(hnode);
		}
		return null;
	}
	
	
	///
	final @property void showLines(bool byes) // setter
	{
		if(byes)
			_style(_style() | TVS_HASLINES);
		else
			_style(_style() & ~TVS_HASLINES);
		
		_crecreate(); // ?
	}
	
	/// ditto
	final @property bool showLines() // getter
	{
		return (_style() & TVS_HASLINES) != 0;
	}
	
	
	///
	final @property void showPlusMinus(bool byes) // setter
	{
		if(byes)
			_style(_style() | TVS_HASBUTTONS);
		else
			_style(_style() & ~TVS_HASBUTTONS);
		
		_crecreate(); // ?
	}
	
	/// ditto
	final @property bool showPlusMinus() // getter
	{
		return (_style() & TVS_HASBUTTONS) != 0;
	}
	
	
	///
	// -showPlusMinus- should be false.
	final @property void singleExpand(bool byes) // setter
	{
		if(byes)
			_style(_style() | TVS_SINGLEEXPAND);
		else
			_style(_style() & ~TVS_SINGLEEXPAND);
		
		_crecreate(); // ?
	}
	
	/// ditto
	final @property bool singleExpand() // getter
	{
		return (_style & TVS_SINGLEEXPAND) != 0;
	}
	
	
	///
	final @property void showRootLines(bool byes) // setter
	{
		if(byes)
			_style(_style() | TVS_LINESATROOT);
		else
			_style(_style() & ~TVS_LINESATROOT);
		
		_crecreate(); // ?
	}
	
	/// ditto
	final @property bool showRootLines() // getter
	{
		return (_style() & TVS_LINESATROOT) != 0;
	}
	
	
	///
	final @property void sorted(bool byes) // setter
	{
		_sort = byes;
	}
	
	/// ditto
	final @property bool sorted() // getter
	{
		return _sort;
	}
	
	
	///
	// First visible node, based on the scrolled position.
	final @property TreeNode topNode() // getter
	{
		if(created)
		{
			HTREEITEM hnode;
			hnode = cast(HTREEITEM)SendMessageA(hwnd, TVM_GETNEXTITEM,
				TVGN_FIRSTVISIBLE, cast(LPARAM)null);
			if(hnode)
				return treeNodeFromHandle(hnode);
		}
		return null;
	}
	
	
	///
	// Number of visible nodes, including partially visible.
	final @property int visibleCount() // getter
	{
		if(!created)
			return 0;
		return cast(int)SendMessageA(hwnd, TVM_GETVISIBLECOUNT, 0, 0);
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
	final void collapseAll()
	{
		if(created)
		{
			void collapsing(TreeNodeCollection tchildren)
			{
				foreach(TreeNode node; tchildren._nodes)
				{
					SendMessageA(hwnd, TVM_EXPAND, TVE_COLLAPSE, cast(LPARAM)node.hnode);
					collapsing(node.tchildren);
				}
			}
			
			
			collapsing(tchildren);
		}
	}
	
	
	///
	final void expandAll()
	{
		if(created)
		{
			void expanding(TreeNodeCollection tchildren)
			{
				foreach(TreeNode node; tchildren._nodes)
				{
					SendMessageA(hwnd, TVM_EXPAND, TVE_EXPAND, cast(LPARAM)node.hnode);
					expanding(node.tchildren);
				}
			}
			
			
			expanding(tchildren);
		}
	}
	
	
	///
	final TreeNode getNodeAt(int x, int y)
	{
		if(created)
		{
			TVHITTESTINFO thi;
			HTREEITEM hti;
			thi.pt.x = x;
			thi.pt.y = y;
			hti = cast(HTREEITEM)SendMessageA(hwnd, TVM_HITTEST, 0, cast(LPARAM)&thi);
			if(hti)
			{
				TreeNode result;
				result = treeNodeFromHandle(hti);
				if(result)
				{
					assert(result.tview is this);
					return result;
				}
			}
		}
		return null;
	}
	
	/// ditto
	final TreeNode getNodeAt(Point pt)
	{
		return getNodeAt(pt.x, pt.y);
	}
	
	
	/+
	///
	// TODO: finish.
	final int getNodeCount(bool includeSubNodes)
	{
		int result;
		result = tchildren.length();
		
		if(includeSubNodes)
		{
			// ...
		}
		
		return result;
	}
	+/
	
	
	version(DFL_NO_IMAGELIST)
	{
	}
	else
	{
		///
		final @property void imageList(ImageList imglist) // setter
		{
			if(isHandleCreated)
			{
				prevwproc(TVM_SETIMAGELIST, TVSIL_NORMAL,
					cast(LPARAM)(imglist ? imglist.handle : cast(HIMAGELIST)null));
			}
			
			_imglist = imglist;
		}
		
		/// ditto
		final @property ImageList imageList() // getter
		{
			return _imglist;
		}
		
		
		/+
		///
		// Default image index (if -1 use this).
		final @property void imageIndex(int index) // setter
		{
			_defimgidx = index;
		}
		
		/// ditto
		final @property int imageIndex() // getter
		{
			return _defimgidx;
		}
		+/
		
		
		///
		final @property void selectedImageIndex(int index) // setter
		{
			//assert(index >= 0);
			assert(index >= -1);
			_selimgidx = index;
			
			if(isHandleCreated)
			{
				TreeNode curnode = selectedNode;
				_crecreate();
				if(curnode)
					curnode.ensureVisible();
			}
		}
		
		/// ditto
		final @property int selectedImageIndex() // getter
		{
			return _selimgidx;
		}
	}
	
	
	protected override @property Size defaultSize() // getter
	{
		return Size(120, 100);
	}
	
	
	/+
	override void createHandle()
	{
		if(isHandleCreated)
			return;
		
		createClassHandle(TREEVIEW_CLASSNAME);
		
		onHandleCreated(EventArgs.empty);
	}
	+/
	
	
	protected override void createParams(ref CreateParams cp)
	{
		super.createParams(cp);
		
		cp.className = TREEVIEW_CLASSNAME;
	}
	
	
	protected override void onHandleCreated(EventArgs ea)
	{
		super.onHandleCreated(ea);
		
		prevwproc(CCM_SETVERSION, 5, 0); // Fixes font size issue.
		
		prevwproc(TVM_SETINDENT, ind, 0);
		
		prevwproc(TVM_SETITEMHEIGHT, iheight, 0);
		
		version(DFL_NO_IMAGELIST)
		{
		}
		else
		{
			if(_imglist)
				prevwproc(TVM_SETIMAGELIST, TVSIL_NORMAL, cast(LPARAM)_imglist.handle);
		}
		
		tchildren.doNodes();
	}
	
	
	protected override void onHandleDestroyed(EventArgs ea)
	{
		tchildren._resetHandles();
		
		super.onHandleDestroyed(ea);
	}
	
	
	protected override void wndProc(ref Message m)
	{
		// TODO: support these messages.
		switch(m.msg)
		{
			case TVM_INSERTITEMA:
			case TVM_INSERTITEMW:
				m.result = cast(LRESULT)null;
				return;
			
			case TVM_SETITEMA:
			case TVM_SETITEMW:
				m.result = cast(LRESULT)-1;
				return;
			
			case TVM_DELETEITEM:
				m.result = FALSE;
				return;
			
			case TVM_SETIMAGELIST:
				m.result = cast(LRESULT)null;
				return;
			
			default:
		}
		
		super.wndProc(m);
	}
	
	
	protected override void prevWndProc(ref Message msg)
	{
		//msg.result = CallWindowProcA(treeviewPrevWndProc, msg.hWnd, msg.msg, msg.wParam, msg.lParam);
		msg.result = dfl.internal.utf.callWindowProc(treeviewPrevWndProc, msg.hWnd, msg.msg, msg.wParam, msg.lParam);
	}
	
	
	//TreeViewEventHandler afterCollapse;
	Event!(TreeView, TreeViewEventArgs) afterCollapse; ///
	//TreeViewEventHandler afterExpand;
	Event!(TreeView, TreeViewEventArgs) afterExpand; ///
	//TreeViewEventHandler afterSelect;
	Event!(TreeView, TreeViewEventArgs) afterSelect; ///
	//NodeLabelEditEventHandler afterLabelEdit;
	Event!(TreeView, NodeLabelEditEventArgs) afterLabelEdit; ///
	//TreeViewCancelEventHandler beforeCollapse;
	Event!(TreeView, TreeViewCancelEventArgs) beforeCollapse; ///
	//TreeViewCancelEventHandler beforeExpand;
	Event!(TreeView, TreeViewCancelEventArgs) beforeExpand; ///
	//TreeViewCancelEventHandler beforeSelect;
	Event!(TreeView, TreeViewCancelEventArgs) beforeSelect; ///
	//NodeLabelEditEventHandler beforeLabelEdit;
	Event!(TreeView, NodeLabelEditEventArgs) beforeLabelEdit; ///
	
	
	///
	protected void onAfterCollapse(TreeViewEventArgs ea)
	{
		afterCollapse(this, ea);
	}
	
	
	///
	protected void onAfterExpand(TreeViewEventArgs ea)
	{
		afterExpand(this, ea);
	}
	
	
	///
	protected void onAfterSelect(TreeViewEventArgs ea)
	{
		afterSelect(this, ea);
	}
	
	
	///
	protected void onAfterLabelEdit(NodeLabelEditEventArgs ea)
	{
		afterLabelEdit(this, ea);
	}
	
	
	///
	protected void onBeforeCollapse(TreeViewCancelEventArgs ea)
	{
		beforeCollapse(this, ea);
	}
	
	
	///
	protected void onBeforeExpand(TreeViewCancelEventArgs ea)
	{
		beforeExpand(this, ea);
	}
	
	
	///
	protected void onBeforeSelect(TreeViewCancelEventArgs ea)
	{
		beforeSelect(this, ea);
	}
	
	
	///
	protected void onBeforeLabelEdit(NodeLabelEditEventArgs ea)
	{
		beforeLabelEdit(this, ea);
	}
	
	
	protected override void onReflectedMessage(ref Message m) // package
	{
		super.onReflectedMessage(m);
		
		switch(m.msg)
		{
			case WM_NOTIFY:
				{
					NMHDR* nmh;
					NM_TREEVIEW* nmtv;
					TreeViewCancelEventArgs cea;
					
					nmh = cast(NMHDR*)m.lParam;
					assert(nmh.hwndFrom == hwnd);
					
					switch(nmh.code)
					{
						case NM_CUSTOMDRAW:
							{
								NMTVCUSTOMDRAW* tvcd;
								tvcd = cast(NMTVCUSTOMDRAW*)nmh;
								//if(tvcd.nmcd.dwDrawStage & CDDS_ITEM)
								{
									//if(tvcd.nmcd.uItemState & CDIS_SELECTED)
									if((tvcd.nmcd.dwDrawStage & CDDS_ITEM)
										&& (tvcd.nmcd.uItemState & CDIS_SELECTED))
									{
										// Note: might not look good with custom colors.
										tvcd.clrText = SystemColors.highlightText.toRgb();
										tvcd.clrTextBk = SystemColors.highlight.toRgb();
									}
									else
									{
										//tvcd.clrText = foreColor.toRgb();
										tvcd.clrText = foreColor.solidColor(backColor).toRgb();
										tvcd.clrTextBk = backColor.toRgb();
									}
								}
								m.result |= CDRF_NOTIFYITEMDRAW; // | CDRF_NOTIFYITEMERASE;
								
								// This doesn't seem to be doing anything.
								Font fon;
								fon = this.font;
								if(fon)
								{
									SelectObject(tvcd.nmcd.hdc, fon.handle);
									m.result |= CDRF_NEWFONT;
								}
							}
							break;
						
						/+
						case TVN_GETDISPINFOA:
							
							break;
						+/
						
						case TVN_SELCHANGINGW:
							goto sel_changing;
						
						case TVN_SELCHANGINGA:
							if(dfl.internal.utf.useUnicode)
								break;
							sel_changing:
							
							nmtv = cast(NM_TREEVIEW*)nmh;
							switch(nmtv.action)
							{
								case TVC_BYMOUSE:
									cea = new TreeViewCancelEventArgs(cast(TreeNode)cast(void*)nmtv.itemNew.lParam,
										false, TreeViewAction.BY_MOUSE);
									onBeforeSelect(cea);
									m.result = cea.cancel;
									break;
								
								case TVC_BYKEYBOARD:
									cea = new TreeViewCancelEventArgs(cast(TreeNode)cast(void*)nmtv.itemNew.lParam,
										false, TreeViewAction.BY_KEYBOARD);
									onBeforeSelect(cea);
									m.result = cea.cancel;
									break;
								
								//case TVC_UNKNOWN:
								default:
									cea = new TreeViewCancelEventArgs(cast(TreeNode)cast(void*)nmtv.itemNew.lParam,
										false, TreeViewAction.UNKNOWN);
									onBeforeSelect(cea);
									m.result = cea.cancel;
							}
							break;
						
						case TVN_SELCHANGEDW:
							goto sel_changed;
						
						case TVN_SELCHANGEDA:
							if(dfl.internal.utf.useUnicode)
								break;
							sel_changed:
							
							nmtv = cast(NM_TREEVIEW*)nmh;
							switch(nmtv.action)
							{
								case TVC_BYMOUSE:
									onAfterSelect(new TreeViewEventArgs(cast(TreeNode)cast(void*)nmtv.itemNew.lParam,
										TreeViewAction.BY_MOUSE));
									break;
								
								case TVC_BYKEYBOARD:
									onAfterSelect(new TreeViewEventArgs(cast(TreeNode)cast(void*)nmtv.itemNew.lParam,
										TreeViewAction.BY_KEYBOARD));
									break;
								
								//case TVC_UNKNOWN:
								default:
									onAfterSelect(new TreeViewEventArgs(cast(TreeNode)cast(void*)nmtv.itemNew.lParam,
										TreeViewAction.UNKNOWN));
							}
							break;
						
						case TVN_ITEMEXPANDINGW:
							goto item_expanding;
						
						case TVN_ITEMEXPANDINGA:
							if(dfl.internal.utf.useUnicode)
								break;
							item_expanding:
							
							nmtv = cast(NM_TREEVIEW*)nmh;
							switch(nmtv.action)
							{
								case TVE_COLLAPSE:
									cea = new TreeViewCancelEventArgs(cast(TreeNode)cast(void*)nmtv.itemNew.lParam,
										false, TreeViewAction.COLLAPSE);
									onBeforeCollapse(cea);
									m.result = cea.cancel;
									break;
								
								case TVE_EXPAND:
									cea = new TreeViewCancelEventArgs(cast(TreeNode)cast(void*)nmtv.itemNew.lParam,
										false, TreeViewAction.EXPAND);
									onBeforeExpand(cea);
									m.result = cea.cancel;
									break;
								
								default:
							}
							break;
						
						case TVN_ITEMEXPANDEDW:
							goto item_expanded;
						
						case TVN_ITEMEXPANDEDA:
							if(dfl.internal.utf.useUnicode)
								break;
							item_expanded:
							
							nmtv = cast(NM_TREEVIEW*)nmh;
							switch(nmtv.action)
							{
								case TVE_COLLAPSE:
									{
										scope TreeViewEventArgs tvea = new TreeViewEventArgs(
											cast(TreeNode)cast(void*)nmtv.itemNew.lParam,
											TreeViewAction.COLLAPSE);
										onAfterCollapse(tvea);
									}
									break;
								
								case TVE_EXPAND:
									{
										scope TreeViewEventArgs tvea = new TreeViewEventArgs(
											cast(TreeNode)cast(void*)nmtv.itemNew.lParam,
											TreeViewAction.EXPAND);
										onAfterExpand(tvea);
									}
									break;
								
								default:
							}
							break;
						
						case TVN_BEGINLABELEDITW:
							goto begin_label_edit;
						
						case TVN_BEGINLABELEDITA:
							if(dfl.internal.utf.useUnicode)
								break;
							begin_label_edit:
							
							{
								TV_DISPINFOA* nmdi;
								nmdi = cast(TV_DISPINFOA*)nmh;
								TreeNode node;
								node = cast(TreeNode)cast(void*)nmdi.item.lParam;
								scope NodeLabelEditEventArgs nleea = new NodeLabelEditEventArgs(node);
								onBeforeLabelEdit(nleea);
								m.result = nleea.cancelEdit;
							}
							break;
						
						case TVN_ENDLABELEDITW:
							{
								Dstring label;
								TV_DISPINFOW* nmdi;
								nmdi = cast(TV_DISPINFOW*)nmh;
								if(nmdi.item.pszText)
								{
									TreeNode node;
									node = cast(TreeNode)cast(void*)nmdi.item.lParam;
									label = fromUnicodez(nmdi.item.pszText);
									scope NodeLabelEditEventArgs nleea = new NodeLabelEditEventArgs(node, label);
									onAfterLabelEdit(nleea);
									if(nleea.cancelEdit)
									{
										m.result = FALSE;
									}
									else
									{
										// TODO: check if correct implementation.
										// Update the node's cached text..
										node.ttext = label;
										
										m.result = TRUE;
									}
								}
							}
							break;
						
						case TVN_ENDLABELEDITA:
							if(dfl.internal.utf.useUnicode)
							{
								break;
							}
							else
							{
								Dstring label;
								TV_DISPINFOA* nmdi;
								nmdi = cast(TV_DISPINFOA*)nmh;
								if(nmdi.item.pszText)
								{
									TreeNode node;
									node = cast(TreeNode)cast(void*)nmdi.item.lParam;
									label = fromAnsiz(nmdi.item.pszText);
									scope NodeLabelEditEventArgs nleea = new NodeLabelEditEventArgs(node, label);
									onAfterLabelEdit(nleea);
									if(nleea.cancelEdit)
									{
										m.result = FALSE;
									}
									else
									{
										// TODO: check if correct implementation.
										// Update the node's cached text..
										node.ttext = label;
										
										m.result = TRUE;
									}
								}
								break;
							}
						
						default:
					}
				}
				break;
			
			default:
		}
	}
	
	
	private:
	TreeNodeCollection tchildren;
	int ind = 19; // Indent.
	dchar pathsep = '\\';
	bool _sort = false;
	int iheight = 16;
	version(DFL_NO_IMAGELIST)
	{
	}
	else
	{
		ImageList _imglist;
		int _selimgidx = -1; //0;
	}
	
	
	TreeNode treeNodeFromHandle(HTREEITEM hnode)
	{
		TV_ITEMA ti;
		ti.mask = TVIF_HANDLE | TVIF_PARAM;
		ti.hItem = hnode;
		if(SendMessageA(hwnd, TVM_GETITEMA, 0, cast(LPARAM)&ti))
		{
			return cast(TreeNode)cast(void*)ti.lParam;
		}
		return null;
	}
	
	package:
	final:
	LRESULT prevwproc(UINT msg, WPARAM wparam, LPARAM lparam)
	{
		//return CallWindowProcA(treeviewPrevWndProc, hwnd, msg, wparam, lparam);
		return dfl.internal.utf.callWindowProc(treeviewPrevWndProc, hwnd, msg, wparam, lparam);
	}
}

