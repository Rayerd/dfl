import dfl;

import core.sys.windows.winuser;
import core.sys.windows.windef;

version(Have_dfl) // For DUB.
{
}
else
{
	pragma(lib, "dfl.lib");
}


int GET_X_LPARAM(LPARAM lparam) pure
{
	return cast(int)cast(short)LOWORD(lparam);
}

int GET_Y_LPARAM(in LPARAM lparam) pure
{
	return cast(int)cast(short)HIWORD(lparam);
}

///
class ItemDragEventArgs : EventArgs
{
	this(MouseButtons button, Object item = null)
	{
		this._button = button;
		this._item = item;
	}
	
	final @property MouseButtons button() // getter
	{
		return this._button;
	}
	
	final @property Object item() // getter
	{
		return this._item;
	}

	private:
	MouseButtons _button;
	Object _item;
}

///
class DragDropListBox : ListBox
{
	///
	this()
	{
		allowDrop = true; // Allow Drag and Drop.
	}

	///
	Event!(DragDropListBox, ItemDragEventArgs) itemDrag;

	protected:
	
	///
	void onItemDrag(ItemDragEventArgs e)
	{
		itemDrag(this, e);
	}
	
	///
	override void wndProc(ref Message msg)
	{
		switch (msg.msg)
		{
			case WM_LBUTTONDOWN:
			{
				int x = GET_X_LPARAM(msg.lParam);
				int y = GET_Y_LPARAM(msg.lParam);
				int idx = this.indexFromPoint(x, y);
				if (idx == ListBox.NO_MATCHES)
				{
					// When pressed mouse position is in space,
					// Selected items are cleared.
					// This action different default ListBox.
					this.clearSelected();
					return;
				}
				else
				{
					// Mouse position is on any items.
					assert(idx >= 0);
					Object obj = this.items[idx];
					assert(obj);
					if (this.selectedItems.contains(obj))
					{
						// On selected item.
						if ((modifierKeys & Keys.CONTROL) == Keys.CONTROL)
						{
							if (this.selectionMode == SelectionMode.ONE)
							{
								// Unselected within CONTROL key.
								this.setSelected(idx, false);
							}
							else if (this.selectionMode == SelectionMode.MULTI_SIMPLE || this.selectionMode == SelectionMode.MULTI_EXTENDED)
							{
								// Unselected within CONTROL key.
								this.setSelected(idx, false);
							}
						}
						else
						{
							_mouseDownPoint = new Point(x, y);
						}
						return;
					}
					else
					{
						// On unselected item.
						if (this.selectionMode == SelectionMode.ONE)
						{
							this.setSelected(idx, true);
							_mouseDownPoint = new Point(x, y);
							break;
						}
						else if (this.selectionMode == SelectionMode.MULTI_SIMPLE || this.selectionMode == SelectionMode.MULTI_EXTENDED)
						{
							if ((modifierKeys & Keys.CONTROL) == Keys.CONTROL)
							{
								// Selected within CONTROL key.
								this.setSelected(idx, true);
								_mouseDownPoint = new Point(x, y);
								return;
							}
							else
							{
								// Selected without CONTROL key.
								this.clearSelected();
								break;
							}
						}
					}
				}
				break;
			}
			case WM_RBUTTONDOWN:
			case WM_MBUTTONDOWN:
			{
				_mouseDownPoint = null;
				break;
			}
			case WM_MOUSEMOVE:
			{
				if (_mouseDownPoint)
				{
					Rect moveRect = Rect(
						_mouseDownPoint.x - GetSystemMetrics(SM_CXDRAG) / 2,
						_mouseDownPoint.y - GetSystemMetrics(SM_CYDRAG) / 2,
						GetSystemMetrics(SM_CXDRAG),
						GetSystemMetrics(SM_CYDRAG)
					);

					int x = GET_X_LPARAM(msg.lParam);
					int y = GET_Y_LPARAM(msg.lParam);

					if (moveRect.contains(x, y))
						return; // Not started to drag yet, because mouse move distance is short.

					int idx = this.indexFromPoint(_mouseDownPoint.x, _mouseDownPoint.y);
					if (idx == ListBox.NO_MATCHES) return;
					assert(idx >= 0);
					Object obj = this.items[idx];
					assert(obj);
					assert(selectedItems.length != 1 || (selectedItems.length == 1 && (obj is selectedItem())));
					scope ItemDragEventArgs idea = new ItemDragEventArgs(
							wparamMouseButtons(msg.wParam),
							obj);
					onItemDrag(idea);
					
					_mouseDownPoint = null;
				}
				break;
			}
			case WM_LBUTTONUP:
			{
				if (_mouseDownPoint)
				{
					int idxDown = this.indexFromPoint(_mouseDownPoint.x, _mouseDownPoint.y);
					if (idxDown == ListBox.NO_MATCHES) return;
					assert(idxDown >= 0);
					Object objDown = this.items[idxDown];
					assert(objDown);

					int x = GET_X_LPARAM(msg.lParam);
					int y = GET_Y_LPARAM(msg.lParam);
					int idxUp = this.indexFromPoint(x, y);
					if (idxUp == ListBox.NO_MATCHES) return;
					assert(idxUp >= 0);
					Object objUp = this.items[idxUp];
					assert(objUp);

					// Mouse down and up position is same over the item.
					if (objDown is objUp)
					{
						if (this.selectionMode == SelectionMode.MULTI_SIMPLE || this.selectionMode == SelectionMode.MULTI_EXTENDED)
						{
							// Mouse position is on selected item.
							if ((modifierKeys & Keys.CONTROL) == Keys.CONTROL)
							{
								// Unselected within CONTROL key.
							}
							else
							{
								// Selected without CONTROL key.
								this.clearSelected();
								this.setSelected(idxUp, true);
							}
						}
					}
				}

				_mouseDownPoint = null;
				break;
			}
			default:
		}
		super.wndProc(msg);
	}

	private:

	/// Currently depressed modifier keys.
	static @property Keys modifierKeys() // getter
	{
		// Is there a better way to do this?
		Keys ks = Keys.NONE;
		if(GetAsyncKeyState(VK_SHIFT) & 0x8000)
			ks |= Keys.SHIFT;
		if(GetAsyncKeyState(VK_MENU) & 0x8000)
			ks |= Keys.ALT;
		if(GetAsyncKeyState(VK_CONTROL) & 0x8000)
			ks|= Keys.CONTROL;
		return ks;
	}

	/// Currently depressed mouse buttons.
	static MouseButtons wparamMouseButtons(WPARAM wparam)
	{
		MouseButtons result;
		if(wparam & MK_LBUTTON)
			result |= MouseButtons.LEFT;
		if(wparam & MK_RBUTTON)
			result |= MouseButtons.RIGHT;
		if(wparam & MK_MBUTTON)
			result |= MouseButtons.MIDDLE;
		return result;
	}

	///
	Point* _mouseDownPoint;
}

class MainForm : Form
{
	private DragDropListBox _list;

	public this()
	{
		this.text = "DragDropListBox example";
		this.size = Size(600, 300);

		_list = new DragDropListBox();
		_list.parent = this;
		_list.location = Point(0,0);
		_list.dock = DockStyle.FILL;
		_list.font = new Font("Meiryo UI", 14f);

		// _list.selectionMode = SelectionMode.ONE;
		// _list.selectionMode = SelectionMode.MULTI_SIMPLE;
		_list.selectionMode = SelectionMode.MULTI_EXTENDED;

		_list.items.add("DragDropListBox is Drag-and-Drop suported ListBox.");
		_list.items.add("It is working on single and multi select mode.");
		_list.items.add("It has a comfortable itemDrag event handler.");
		_list.items.add("Drop files to this ListBox.");
		_list.items.add("Drag items of the ListBox to WORDPAD.");

		//
		// OLE-Drop
		//
		_list.dragEnter ~= (Control sender, DragEventArgs e) {
			// Do nothing.
		};
		_list.dragOver ~= (Control sender, DragEventArgs e) {
			// Accepts file drop.
			if (e.data.getDataPresent(DataFormats.fileDrop))
			{
				// Mouse cursor view setting on dragging.
				if ((e.keyState & DragDropKeyStates.CONTROL_KEY) == DragDropKeyStates.CONTROL_KEY)
				{
					e.effect = DragDropEffects.COPY;
				}
				else if ((e.keyState & DragDropKeyStates.SHIFT_KEY) == DragDropKeyStates.SHIFT_KEY)
				{
					e.effect = DragDropEffects.MOVE;
				}
				else if ((e.keyState & DragDropKeyStates.ALT_KEY) == DragDropKeyStates.ALT_KEY)
				{
					e.effect = DragDropEffects.LINK;
				}
				else
				{
					e.effect = DragDropEffects.COPY;
				}
				assert((e.allowedEffect & e.effect) != 0);
			}
			else
			{
				e.effect = DragDropEffects.NONE;
			}
		};
		_list.dragDrop ~= (Control sender, DragEventArgs e) {
			// Get droped file names.
			string[] files = e.data.getData(DataFormats.fileDrop, false).getStrings();
			_list.beginUpdate();
			_list.items.clear();
			foreach (string fileName; files)
			{
				_list.items.add(fileName);
			}
			_list.endUpdate();
		};
		_list.dragLeave ~= (Control sender, EventArgs e) {
			// Do nothing.
		};

		//
		// OLE-Drag
		//
		_list.itemDrag ~= (Control sender, ItemDragEventArgs e) {
			string[] selectedAllItemText;
			foreach (string txt; _list.selectedItems)
			{
				selectedAllItemText ~= txt;
			}
			// Send string[] to target window.
			// The string[] is converted to '\n' separated string automatically.
			DataObject dataObj = new DataObject();
			dataObj.setData(DataFormats.stringFormat, new Data(selectedAllItemText));
			DragDropEffects effect = _list.doDragDrop(dataObj, DragDropEffects.COPY);
		};
		_list.giveFeedback ~= (Control sender, GiveFeedbackEventArgs e) {
			e.useDefaultCursors = true; // Default.

			// When use another cursor.
			//
			// e.useDefaultCursors = false;
			// if ((e.effect & DragDropEffects.COPY) == DragDropEffects.COPY)
			//	Cursor.current = ...;
			// else ...
		};
		_list.queryContinueDrag ~= (Control sender, QueryContinueDragEventArgs e) {
			if(e.escapePressed)
			{
				e.action = DragAction.CANCEL; // Cancel by ESC key.
			}
			else if ((e.keyState & DragDropKeyStates.RIGHT_MOUSE_BUTTON) == DragDropKeyStates.RIGHT_MOUSE_BUTTON)
			{
				e.action = DragAction.CANCEL; // Cancel by right mouse button.
			}
		};
	}
}

static this()
{
	Application.enableVisualStyles();
}

void main()
{
	Application.run(new MainForm());
}
