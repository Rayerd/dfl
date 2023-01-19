import dfl;
import std.conv : to;

version(Have_dfl) // For DUB.
{
}
else
{
	pragma(lib, "dfl.lib");
}

// Method 1 (DragAcceptFiles) when defined.
// Method 2 (OLE-Drop) when not defined.
//
version = SELECT_DROP_METHOD1;

version (SELECT_DROP_METHOD1)
{
	import core.sys.windows.shellapi;
	import core.sys.windows.winuser;
}

class MainForm : Form
{
	private Label _label;

	public this()
	{
		this.text = "Drag-and-Drop example";
		this.size = Size(600, 300);

		version (SELECT_DROP_METHOD1)
		{
			// Let's trap WM_DROPFILES in wndProc().
			DragAcceptFiles(handle, true);
		}
		else
		{
			this.allowDrop = true;
			this.dragEnter ~= (Control sender, DragEventArgs e) {
				// Do nothing
			};
			this.dragOver ~= (Control sender, DragEventArgs e) {
				if (e.data.getDataPresent(DataFormats.fileDrop))
				{
					if ((e.keyState & DragDropKeyStates.SHIFT_KEY) == DragDropKeyStates.SHIFT_KEY)
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
			this.dragDrop ~= (Control sender, DragEventArgs e) {
				string[] files = e.data.getData(DataFormats.fileDrop, false).getStrings;
				_label.text = "";
				foreach (string fileName; files)
				{
					_label.text = _label.text ~ fileName ~ "\n";
				}
				this.allowDrop = false; // Example: Accept only once.
			};
			this.dragLeave ~= (Control sender, EventArgs e) {
				// Do nothing
			};
		}

		_label = new Label();
		_label.location = Point(0,0);
		_label.autoSize = true;
		_label.dock = DockStyle.FILL;
		_label.font = new Font("Meiryo UI", 14f);
		_label.text = "Drop files to this form.";
		_label.parent = this;
	}

	version (SELECT_DROP_METHOD1)
	{
		protected override void wndProc(ref Message msg)
		{
			switch (msg.msg)
			{
				case WM_DROPFILES:
					HDROP hDrop = cast(HDROP)msg.wParam;

					uint numFiles = DragQueryFile(cast(HDROP)msg.wParam, -1, null, 0);
					if (numFiles == 0)
					{
						_label.text = "Error";
					}
					else
					{
						_label.text = "";
						for (int i; i < numFiles; i++)
						{
							enum BUFFER_LENGTH = 260;
							wchar[BUFFER_LENGTH] fileName;
							DragQueryFile(hDrop, i, fileName.ptr, BUFFER_LENGTH);
							_label.text = _label.text ~ to!string(fileName);
							_label.text = _label.text ~ "\n";
						}
					}
					DragFinish(hDrop);
					break;
				default:
			}
			super.wndProc(msg);
		}
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
