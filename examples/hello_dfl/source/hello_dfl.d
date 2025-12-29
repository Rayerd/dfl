import dfl;
import std.conv : to;

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
		import dfl.internal.dpiaware;

		Point pt1 = Point(50, 200) * dpi / USER_DEFAULT_SCREEN_DPI;
		Point pt2 = Point(150, 170) * dpi / USER_DEFAULT_SCREEN_DPI;
		pea.graphics.drawLine(new Pen(Color.blue, 5, PenStyle.SOLID), pt1, pt2);

		Rect rt1 = Rect(20, 170, 100, 50) * dpi / USER_DEFAULT_SCREEN_DPI;
		pea.graphics.drawRectangle(new Pen(Color.black), rt1);

		Rect rt2 = Rect(200, 10, 50, 50) * dpi / USER_DEFAULT_SCREEN_DPI;
		pea.graphics.fillRectangle(Color.green, rt2);
		
		Rect rt3 = Rect(100, 10, 50, 50) * dpi / USER_DEFAULT_SCREEN_DPI;
		pea.graphics.drawEllipse(new Pen(Color.red), rt3);
		
		Rect rt4 = Rect(200, 100, 50, 50) * dpi / USER_DEFAULT_SCREEN_DPI;
		pea.graphics.fillEllipse(new SolidBrush(Color.purple), rt4);
	}
}

import core.sys.windows.windows;
import std.format;

shared wstring names;
enum int MAX_TITLE = 1000;

extern(Windows)
BOOL enumCallBack(HWND hwnd, LPARAM lParam) nothrow
{
	wchar* str = cast(wchar*)new wchar[MAX_TITLE];
	int len = GetWindowText(hwnd, str, MAX_TITLE);
	names ~= "-" ~ str[0..len].dup ~ "\n";
	return TRUE;
}
class TestButton : Button
{
	override void onClick(EventArgs ea)
	{
		wstring _ = names;
		names.length = 0;
		EnumChildWindows(parent.handle, &enumCallBack, 0);
		msgBox(names.to!string);
		// msgBox("hi");
	}
}

void main()
{
	Application.enableVisualStyles();
	Application.setHighDpiMode(HighDpiMode.PER_MONITOR_V2);
	Application.run(new MainForm());
}
