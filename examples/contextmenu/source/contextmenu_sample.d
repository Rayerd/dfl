import dfl;
import core.sys.windows.windows;

version(Have_dfl) // For DUB.
{
}
else
{
	pragma(lib, "dfl.lib");
}

class MainForm : Form
{
	private ContextMenu _contextMenu;
	
	this()
	{
		this.text = "ContextMenu example";
		this.size = Size(350, 200);
		
		_contextMenu = new ContextMenu();
		MenuItem contextMenuItem1 = new MenuItem("Kyoto");
		contextMenuItem1.click ~= (MenuItem mi, EventArgs e) {
			msgBox("Kyoto");
		};
		MenuItem contextMenuItem2 = new MenuItem("Tokyo");
		contextMenuItem2.click ~= (MenuItem mi, EventArgs e) {
			msgBox("Tokyo");
		};
		MenuItem contextMenuItem3 = new MenuItem("Osaka");
		contextMenuItem3.click ~= (MenuItem mi, EventArgs e) {
			msgBox("Osaka");
		};
		_contextMenu.menuItems.add(contextMenuItem1);
		_contextMenu.menuItems.addRange([contextMenuItem2, contextMenuItem3]);
	}

	override void wndProc(ref Message msg)
	{
		switch (msg.msg)
		{
			case WM_RBUTTONDOWN:
			{
				if (_contextMenu)
				{
					POINT pt;
					GetCursorPos(&pt);
					_contextMenu.show(this, Point(&pt));
				}
				return;
			}
			default:
			{
				super.wndProc(msg);
				return;
			}
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
