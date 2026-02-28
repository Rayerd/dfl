import dfl;

import std.traits : EnumMembers;

version(Have_dfl) // For DUB.
{
}
else
{
	pragma(lib, "dfl.lib");
}

class MainForm : Form
{
	private ListView _listView;
	private ComboBox _combobox;
	private ImageList _smallImagelist;
	private ImageList _largeImagelist;
	private Bitmap _icons24;
	private Bitmap _icons64;

	// Helper
	private static string stringFromView(View v)
	{
		static string[] arr = ["LARGE_ICON", "SMALL_ICON", "LIST", "DETAILS"];
		return arr[cast(int)v];
	}

	public this()
	{
		this.text = "ImageList example";
		this.size = Size(300, 300);
		this.formBorderStyle = FormBorderStyle.FIXED_SINGLE;

		// Create Bitmap
		ubyte[] bmpData24 = cast(ubyte[])import(r".\image\rgb24.bmp");
		auto pic24 = new Picture(bmpData24);
		_icons24 = pic24.toBitmap();

		ubyte[] bmpData64 = cast(ubyte[])import(r".\image\rgb64.bmp");
		auto pic64 = new Picture(bmpData64);
		_icons64 = pic64.toBitmap();

		// Create ImageList
		_smallImagelist = new ImageList();
		_smallImagelist.imageSize = Size(24, 24); // Each bitmap size in image list (W24[dots] x H24[dots] x 3[icons]).
		_smallImagelist.transparentColor = Color.white;
		_smallImagelist.images.addStrip(_icons24);

		_largeImagelist = new ImageList();
		_largeImagelist.imageSize = Size(64, 64); // Each bitmap size in image list (W64[dots] x H64[dots] x 3[icons]).
		_largeImagelist.transparentColor = Color.white;
		_largeImagelist.images.addStrip(_icons64);

		// Create ComboBox
		_combobox = new ComboBox();
		_combobox.parent = this;
		_combobox.location = Point(0, 160);
		_combobox.size = Size(250, 100);

		// _combobox.dropDownStyle = ComboBoxStyle.DROP_DOWN_LIST;
		_combobox.dropDownStyle = ComboBoxStyle.DROP_DOWN;
		// _combobox.dropDownStyle = ComboBoxStyle.SIMPLE;

		foreach (v; EnumMembers!View)
		{
			_combobox.items.add(stringFromView(v));
		}

		immutable View initialViewMove = View.LARGE_ICON;
		_combobox.text = stringFromView(initialViewMove);
		_combobox.selectedIndex = cast(int)initialViewMove;

		_combobox.textChanged ~= (Control sender, EventArgs e)
		{
			// msgBox("textChanged");
		};

		_combobox.selectedValueChanged ~= (Control sender, EventArgs e)
		{
			// msgBox("selectedValueChanged");

			int sel = _combobox.selectedIndex();
			if (sel >= 0)
			{
				_listView.view = cast(View)sel;
			}
			else
			{
				msgBox("Unknown ListView style.");
			}
		};

		// Create ListView
		_listView = new ListView();
		_listView.parent = this;
		_listView.location = Point(0, 0);
		_listView.size = Size(250, 150);

		_listView.largeImageList = _largeImagelist; // Attach image list to ListView.
		_listView.smallImageList = _smallImagelist; // ditto

		// Style
		_listView.view = initialViewMove;
		_listView.gridLines = true;
		_listView.multiSelect = false;
		_listView.hideSelection = false;
		_listView.fullRowSelect = true;
		_listView.checkBoxes = false;
		_listView.scrollable = true; // scrollable=false is not compatible with the list or details(report) styles(views).

		// Header
		ColumnHeader col1 = new ColumnHeader();
		col1.text = "Color";
		col1.width = 70;

		ColumnHeader col2 = new ColumnHeader();
		col2.text = "R-G-B";
		col2.width = 70;

		_listView.columns.addRange([col1, col2]);

		// Contents
		_listView.beginUpdate(); // Stop redraw.

		ListViewItem item1 = new ListViewItem("Red");
		item1.subItems.add("255-0-0");
		item1.imageIndex = 0; // 0 is Red icon.
		_listView.items.add(item1);

		ListViewItem item2 = new ListViewItem("Green");
		item2.subItems.add("0-255-0");
		item2.imageIndex = 1; // 1 is Green icon.
		_listView.items.add(item2);

		ListViewItem item3 = new ListViewItem("Blue");
		item3.subItems.add("0-0-255");
		item3.imageIndex = 2; // 2 is Blue icon.
		_listView.items.add(item3);

		_listView.endUpdate(); // Restart redraw.
	}
}

void main()
{
	Application.enableVisualStyles();
	Application.setHighDpiMode(HighDpiMode.PER_MONITOR_V2);
	Application.run(new MainForm());
}
