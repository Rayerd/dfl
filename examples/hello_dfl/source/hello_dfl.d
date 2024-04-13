import std.conv : to;
import dfl;

version(Have_dfl) // For DUB.
{
}
else
{
	pragma(lib, "dfl.lib");
}

class MainForm : Form
{
	private Button _button;
	private ListBox _listbox;
	private MainMenu _menu;
	
	this()
	{
		this.text = "Hello DFL";
		this.resizeRedraw = true;
		
		_button = new TestButton();
		_button.text = "ok";
		_button.parent = this;
		_button.location = Point(100, 100);
		
		_listbox = new ListBox();
		_listbox.parent = this;
		_listbox.size = Size(60, 150);
		_listbox.items.add("foo");
		_listbox.items.addRange(["hoge", "piyo"]);
		_listbox.click ~= (Control c, EventArgs ea) {
			int index = _listbox.selectedIndex;
			msgBox(to!string(index));
			if (index >= 0)
			{
				string msg = _listbox.selectedItem.toString();
				msgBox(msg);
			}
		};
		
		_menu = new MainMenu();
		MenuItem item = new MenuItem();
		item.text = "File";
		MenuItem subItem = new MenuItem();
		subItem.text = "Open";
		auto menuClickHandler = (MenuItem mi, EventArgs ea){ msgBox("open the door"); };
		subItem.click.addHandler(menuClickHandler); // same =~
		item.menuItems.add(subItem);
		_menu.menuItems.add(item);
		this.menu = _menu;
	}

	override void onPaint(PaintEventArgs pea)
	{
		pea.graphics.drawLine(new Pen(Color.blue, 5, PenStyle.SOLID), Point(50, 200), Point(150, 170));
		pea.graphics.drawRectangle(new Pen(Color.black), 20, 170, 100, 50);
		pea.graphics.fillRectangle(Color.green, 200, 10, 50, 50);
		pea.graphics.drawEllipse(new Pen(Color.red), 100, 10, 50, 50);
		pea.graphics.fillEllipse(new SolidBrush(Color.purple), 200, 100, 50, 50);
	}
}

class TestButton : Button
{
	override void onClick(EventArgs ea)
	{
		msgBox("hi");
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
