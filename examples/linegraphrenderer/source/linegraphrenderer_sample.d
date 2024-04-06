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
	alias CustomLineGraphRenderer = LineGraphRenderer!(string,int,int,int,int,int,int,int,int,int,int,int,int,int,int,int,int);
	CustomLineGraphRenderer _graph;

	alias CustomLineGraphRenderer2 = LineGraphRenderer!(int,int,int);
	CustomLineGraphRenderer2 _graph2;

	// alias CustomTableRenderer = TableRenderer!(string,int,int,int,int,int,int,int,int,int,int,int,int,int,int,int);
	// CustomTableRenderer _table;

	// alias CustomTableRenderer2 = TableRenderer!(int,int,int);
	// CustomTableRenderer2 _table2;

	public this()
	{
		this.text = "LineGraphRenderer example";
		this.size = Size(1000, 800);
		string csv =
			"教科,山田,佐藤,井上,田中,木下,藤原,山本,大森,伊藤,高橋,鈴木,中村,小林,松井,木村,近藤\n" ~ 
			"国語,70,80,80,75,68,65,55,48,45,38,35,25,20,10,5,1\n" ~ 
			"算数,60,90,80,75,68,65,55,48,45,38,35,25,20,10,5,1\n" ~ 
			"理科,80,70,80,75,68,65,55,48,45,38,35,25,20,10,5,1\n" ~ 
			"社会,90,60,80,75,68,65,55,48,45,38,35,25,20,10,5,1\n";
		_graph = new CustomLineGraphRenderer(csv, 4);
		_graph.showLegend = true;
		_graph.legendLineHeight = 18;
		_graph.chartMargins = ChartMargins(50, 50, 50, 50);
		_graph.plotPointSize = 10;
		_graph.verticalZeroPosition = VerticalZeroPosition.BOTTOM;
		_graph.plotAreaAndLegendSpanX = 50;
		_graph.plotAreaAndHorizontalScaleSpanY = 10;
		_graph.plotAreaLeftPadding = 20;
		_graph.plotAreaRightPadding = 20;
		_graph.plotAreaHeightOnDisplay = 300;
		_graph.hasHorizontalScale = true;
		_graph.horizontalScaleSpan = 100;
		_graph.horizonScaleLineInnerSide = 0;
		_graph.horizonScaleLineOuterSide = 5;
		_graph.horizontalScaleHeight = 12;
		_graph.hasVerticalScale = true;
		_graph.verticalMaxScale = 110;
		_graph.verticalScaleLineOuterSide = 5;
		_graph.verticalScaleLineInnerSide = 0;
		_graph.verticalScaleSpan = 20;
		_graph.verticalScaleWidth = 40;
		_graph.backColor = Color.white;
		_graph.plotAreaBoundsColor = Color.black;
		_graph.plotLineColorPalette[0] = Color.black;
		_graph.plotPointFormList[4..8] = PlotPointForm.CROSS;
		_graph.plotPointFormList[8..12] = PlotPointForm.RECTANGLE;
		_graph.plotPointFormList[12..16] = PlotPointForm.TRIANGLE;
		_graph.relocate = Point(50, 50); // Relocate origin point based on top-left margins.

		string csv2 =
			"A,B,C\n" ~ 
			"70,80,80\n" ~ 
			"60,90,80\n" ~ 
			"80,70,80\n" ~ 
			"90,60,80\n";
		_graph2 = new CustomLineGraphRenderer2(csv2, 4);
		_graph2.chartMargins = ChartMargins(10, 10, 10, 10);
		_graph2.relocate = Point(600, 50);

		// _table = new CustomTableRenderer(csv, 4);
		// _table.location = Point(50, 500);
		// _table.hasHeader = true;
		// _table.showHeader = true;
		// _table.headerLine = true;
		// _table.width[] = 40;

		// _table2 = new CustomTableRenderer2(csv2, 4);
		// _table2.hasHeader = true;
		// _table2.showHeader = true;
		// _table2.headerLine = true;
		// _table2.width[] = 40;
		// _table2.location = Point(680, 200);
	}

	protected override void onPaint(PaintEventArgs e)
	{
		if (_graph)
			_graph.draw(e.graphics);
		if (_graph2)
			_graph2.draw(e.graphics);
		// if (_table)
		// 	_table.draw(e.graphics);
		// if (_table2)
		// 	_table2.draw(e.graphics);
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
