import dfl;
import std.conv : to;

version(Have_dfl) // For DUB.
{
}
else
{
	pragma(lib, "dfl.lib");
}

import core.sys.windows.shellapi; // For method 1
import core.sys.windows.winuser; // ditto

class MainForm : Form
{
	private Label _labelLeft;
	private Label _labelRight;

	public this()
	{
		this.text = "Drag-and-Drop example";
		this.size = Size(680, 370);

		// Method 1: DragAcceptFiles
		_labelLeft = new DragAcceptLabel();
		_labelLeft.location = Point(50,50);
		_labelLeft.size = Size(250,250);
		_labelLeft.borderStyle = BorderStyle.FIXED_SINGLE;
		_labelLeft.font = new Font("Meiryo UI", 14f);
		_labelLeft.text = "[Method 1: DragAcceptFiles]\nDrop files to this rectangle.";
		_labelLeft.parent = this;

		// Method 2: OLE-Drop
		_labelRight = new Label();
		_labelRight.location = Point(350,50);
		_labelRight.size = Size(250,250);
		_labelRight.borderStyle = BorderStyle.FIXED_SINGLE;
		_labelRight.font = new Font("Meiryo UI", 14f);
		_labelRight.text = "[Method 2: OLE-Drop]\nDrop files to this rectangle.";
		_labelRight.parent = this;
		//
		_labelRight.allowDrop = true;
		_labelRight.dragEnter ~= (Control sender, DragEventArgs e) {
			// Do nothing
		};
		_labelRight.dragOver ~= (Control sender, DragEventArgs e) {
			if (e.data.getDataPresent(DataFormats.fileDrop))
			{
				if ((e.keyState & DragDropKeyStates.SHIFT_KEY) != 0)
				{
					e.effect = DragDropEffects.MOVE;
				}
				else if ((e.keyState & DragDropKeyStates.ALT_KEY) != 0)
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
		_labelRight.dragDrop ~= (Control sender, DragEventArgs e) {
			Label label = cast(Label)sender;
			string[] files = e.data.getData(DataFormats.fileDrop, false).getFileDropList;
			label.text = "";
			foreach (string fileName; files)
			{
				label.text = label.text ~ fileName ~ "\n";
			}
		};
		_labelRight.dragLeave ~= (Control sender, EventArgs e) {
			// Do nothing
		};
	}
}

// For method 1
class DragAcceptLabel : Label
{
	protected override void onHandleCreated(EventArgs e)
	{
		super.onHandleCreated(e);
		DragAcceptFiles(handle, true); // Let's trap WM_DROPFILES in wndProc().
	}
	protected override void wndProc(ref Message msg) // For method 1
	{
		switch (msg.msg)
		{
			case WM_DROPFILES:
				HDROP hDrop = cast(HDROP)msg.wParam;

				uint numFiles = DragQueryFile(cast(HDROP)msg.wParam, -1, null, 0);
				if (numFiles == 0)
				{
					this.text = "Error";
				}
				else
				{
					this.text = "";
					for (int i; i < numFiles; i++)
					{
						enum BUFFER_LENGTH = 260;
						wchar[BUFFER_LENGTH] fileName;
						DragQueryFile(hDrop, i, fileName.ptr, BUFFER_LENGTH);
						this.text = this.text ~ to!string(fileName);
						this.text = this.text ~ "\n";
					}
				}
				DragFinish(hDrop);
				break;
			default:
		}
		super.wndProc(msg);
	}
}

void main()
{
	Application.enableVisualStyles();
	Application.setHighDpiMode(HighDpiMode.PER_MONITOR_V2);
	Application.run(new MainForm());
}
