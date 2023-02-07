import std.conv : to;
import dfl;

version(Have_dfl) // For DUB.
{
}
else
{
	pragma(lib, "dfl.lib");
}

class MainForm : Form {
	private Button _button;
	private ListBox _listbox;
	private MainMenu _menu;
	
	this() {
		text = "Hello DFL";
		resizeRedraw = true;
		
		_button = new TestButton();
		_button.text = "ok";
		_button.parent = this;
		_button.location = Point(100, 100);
		
		_listbox = new ListBox();
		_listbox.parent = this;
		_listbox.size = Size(60, 150);
		_listbox.items.add("foo");
		_listbox.items.addRange(["hoge", "piyo"]);
		_listbox.click ~=
			(Control c, EventArgs ea) {
				int index = _listbox.selectedIndex;
				msgBox(to!string(index));
				if(index >= 0) {
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
}

class TestButton : Button {
	override void onClick(EventArgs ea) {
		msgBox("hi");
	}
}

static this() {
	Application.enableVisualStyles();
}

void main() {
	Application.run(new MainForm());
}
