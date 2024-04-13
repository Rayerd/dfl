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
	alias CustomTimeChartRenderer = TimeChartRenderer!(int,int,int,int,int,int,int,int,int);
	CustomTimeChartRenderer _graph;

	alias CustomTableRenderer = TableRenderer!(int,int,int,int,int,int,int,int,int);
	CustomTableRenderer _table;

	public this()
	{
		this.text = "TimeChartRenderer example";
		this.size = Size(600, 650);

		string csv =
			"Time (ms),D1,D2,D3,D4,A1,A2,A3,A4\n" ~
			"0,0,0,0,0,0,0,0,0\n" ~
			"100,1,0,0,0,5,2,10,2\n" ~
			"200,0,1,0,0,6,3,10,-3\n" ~
			"300,1,1,1,0,7,4,9,4\n" ~
			"400,0,0,1,1,8,5,9,-5\n" ~
			"500,1,0,1,1,9,2,8,6\n" ~
			"600,0,0,0,1,8,3,8,-7\n" ~
			"700,1,1,0,1,7,4,7,8\n" ~
			"800,0,1,0,0,6,5,7,-9\n" ~
			"900,1,0,1,0,5,2,6,10\n" ~
			"1000,0,0,1,0,4,3,6,-10\n" ~
			"1100,1,1,1,0,3,4,5,9\n" ~
			"1200,0,1,0,1,2,5,5,-9\n" ~
			"1300,1,0,0,1,1,2,4,8\n" ~
			"1400,0,0,0,1,0,3,4,-8\n";
		_graph = new CustomTimeChartRenderer(csv, 15);
		_graph.location = Point(50, 50);
		_graph.chartMargins = ChartMargins(50, 50, 50, 50);
		_graph.seriesStyleList[0..4] = TimeChartSeriesStyle(true, Color.blue, 20); // Digital
		_graph.seriesStyleList[4..7] = TimeChartSeriesStyle(false, Color.red, 50, 0, 10); // Analog
		_graph.seriesStyleList[7] = TimeChartSeriesStyle(false, Color.red, 100, -10, 20,); // Analog
		_graph.plotAreaTopPadding = 20;
		_graph.plotAreaBottomPadding = 20;
		_graph.plotAreaLeftPadding = 20;
		_graph.plotAreaRightPadding = 20;
		_graph.plotAreaBoundsColor = Color.black;
		_graph.plotAreaAndHorizontalScaleSpanY = 10;
		_graph.hasHorizontalScale = true;
		_graph.horizontalScaleSpan = 20;
		_graph.horizontalScaleStep = 2;
		_graph.horizontalScaleLineInnerSide = 5;
		_graph.horizontalScaleLineOuterSide = 5;
		_graph.horizontalScaleHeight = 20;
		_graph.hasVerticalScale = true;
		_graph.verticalScaleWidth = 40;
		_graph.hasZeroLine = true;
		_graph.backColor = Color.white;

		_table = new CustomTableRenderer(csv, 15);
		_table.location = Point(600, 50);
		_table.hasHeader = true;
		_table.showHeader = true;
		_table.headerLine = true;
		_table.width[] = 50;
	}

	protected override void onPaint(PaintEventArgs e)
	{
		if (_graph)
			_graph.draw(e.graphics);
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
