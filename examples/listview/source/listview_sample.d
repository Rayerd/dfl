import dfl;
import std.conv;

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

	this()
	{
		this.text = "ListView example";
		this.size = Size(300, 300);

		// Create
		_listView = new ListView();
		_listView.parent = this;

		// Style
		_listView.dock = DockStyle.FILL;
		_listView.view = View.DETAILS;
		// _listView.view = View.LIST;
		// _listView.view = View.LARGE_ICON;
		// _listView.view = View.SMALL_ICON;
		_listView.gridLines = true;
		_listView.multiSelect = false;
		_listView.hideSelection = false;
		_listView.fullRowSelect = true;
		_listView.checkBoxes = true;

		// Header
		ColumnHeader colX = new ColumnHeader();
		colX.text = "X";
		colX.width = 70;

		ColumnHeader colY = new ColumnHeader();
		colY.text = "Y";
		colY.width = 70;

		ColumnHeader colXY = new ColumnHeader();
		colXY.text = "XY";
		colXY.width = 70;

		_listView.columns.addRange([colX, colY, colXY]);

		// Contents
		_listView.beginUpdate(); // Stop redraw.

		// Work around: The first column alignment setting is enabled after beginUpdate().
		colX.textAlign = HorizontalAlignment.CENTER;
		colY.textAlign = HorizontalAlignment.RIGHT;
		colXY.textAlign = HorizontalAlignment.LEFT;

		for (int x=1; x<=3; x++)
		{
			for (int y=1; y<=3; y++)
			{
				string xstr = to!string(x);
				string ystr = to!string(y);
				string xystr = to!string(x*y);
				ListViewItem item = new ListViewItem(xstr);
				_listView.items.add(item); // Add item to first column.
				item.subItems.add(ystr);   // Add sub item to second column.
				item.subItems.add(xystr);  // Add sub item to third column.
			}
		}

		_listView.endUpdate(); // Restart redraw.
	}
}

void main()
{
	Application.run(new MainForm());
}
