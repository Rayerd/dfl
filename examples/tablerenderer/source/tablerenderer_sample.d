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
	alias CustomTableRenderer = TableRenderer!(string, int, int);
	CustomTableRenderer _table;

	public this()
	{
		this.text = "TableRenderer example";
		this.size = Size(450, 450);
		string csv =
			"教科,大森,山田\n" ~ 
			"国語,95,98\n" ~ 
			"理科,75,80\n" ~ 
			"算数,90,78\n" ~ 
			"社会,80,76\n";
		_table = new CustomTableRenderer(csv, 5);
		_table.height = 40;
		_table.width[] = 80;
		_table.paddingX = 10;
		_table.paddingY = 12;
		_table.location = Point(20, 20);
		_table.hasHeader = true; // true : 1st line is header.
		_table.showHeader = true;
		_table.firstRecord = 0;
		_table.lastRecord = 3;
		_table.textColor = Color.black;
		_table.backColor = Color.white;
		_table.lineColor = Color.lightGray;
		_table.headerLine = true;
		_table.topSideLine = true;
		_table.leftSideLine = true;
		_table.bottomSideLine = true;
		_table.rightSideLine = true;
		_table.verticalLine = true;
		_table.horizontalLine = true;
		_table.headerFont = new Font("MS Gothic", 16f, FontStyle.BOLD);
		_table.recordFont = new Font("MS Gothic", 12f, FontStyle.REGULAR);
	}

	protected override void onPaint(PaintEventArgs e)
	{
		if (_table)
			_table.draw(e.graphics);
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
