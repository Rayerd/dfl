// chart.d
//
// Written by haru-s/Rayerd in 2024.

/// 
module dfl.chart;

private import dfl.base;
private import dfl.drawing;

private import std.csv;
private import std.typecons;
private import std.conv;
private import std.algorithm;
private import std.range;

///
class TableRenderer(T...)
{
	enum DEFAULT_HEIGHT = 25; ///
	enum DEFAULT_WIDTH = 100; ///
	enum DEFAULT_PADDING_X = 5; ///
	enum DEFAULT_PADDING_Y = 5; ///

	///
	this(string csv, int numRecords)
	{
		this(csv);
		_firstRecord = 0;
		_lastRecord = numRecords - 1;
	}
	/// ditto
	this(string csv, int first, int last)
	{
		this(csv);
		_firstRecord = first;
		_lastRecord = last;
	}
	/// ditto
	this(string csv) // deprecated
	{
		_csv = csv;
		_columns = T.length;
		height = DEFAULT_HEIGHT;
		for (int i; i < columns; i++)
			_width ~= DEFAULT_WIDTH;
		_headerFont = new Font("MS Gothic", 12f, FontStyle.BOLD);
		_recordFont = new Font("MS Gothic", 12f, FontStyle.REGULAR);
		_paddingX = DEFAULT_PADDING_X;
		_paddingY = DEFAULT_PADDING_Y;
		_textColor = Color.black;
		_backColor = Color.white;
		_lineColor = Color.black;
		_headerTextFormat = new TextFormat(TextFormatFlags.SINGLE_LINE);
		_recordTextFormat = new TextFormat(TextFormatFlags.SINGLE_LINE);
	}

	/// Draw records from first record to last record.
	void draw(Graphics g)
	{
		// Draw background.
		g.fillRectangle(new SolidBrush(_backColor), bounds);
		// Draw top side line.
		if (_topSideLine)
			g.drawLine(new Pen(_lineColor), Point(location.x, location.y), Point(bounds.right, location.y));
		// Draw header line.
		if (_showHeader && _hasHeader && _headerLine)
			g.drawLine(new Pen(_lineColor), Point(location.x, location.y + height), Point(bounds.right, location.y + height));
		// Draw header.
		int row; // -row- is line number in CSV.
		int viewLine; // -viewLine- is line number on display.
		if (_hasHeader)
		{
			if (_showHeader)
			{
				int y = location.y + viewLine * height + _paddingY;
				foreach (col, value; csvReader!(Tuple!T)(_csv, null).header)
				{
					int x = location.x + sum(_width[0..col]) + _paddingX;
					g.drawText(to!string(value), _headerFont, _textColor, Rect(x, y, _width[col] - _paddingX, _height - _paddingY), _headerTextFormat);
				}
				row++;
				viewLine++;
			}
			else
			{
				row++;
				// Do not increment -viewLine- here.
			}
		}
		// Draw records.
		foreach (record; (_hasHeader ? csvReader!(Tuple!T)(_csv, null) : csvReader!(Tuple!T)(_csv)))
		{
			int rows = (_hasHeader?1:0) + lastRecord - firstRecord + 1;
			if (firstRecord + (_hasHeader?1:0) <= row && row <= rows)
			{
				int y = location.y + viewLine * height + _paddingY;
				foreach (int col, value; record)
				{
					int x = location.x + sum(_width[0..col]) + _paddingX;
					g.drawText(to!string(value), _recordFont, _textColor, Rect(x, y, _width[col] - _paddingX, _height - _paddingY), _recordTextFormat);
				}
				// Draw horizontal line.
				if (_horizontalLine && viewLine < lastRecord - firstRecord + (_showHeader?1:0))
				{
					int y2 = location.y + height * (viewLine + 1);
					g.drawLine(new Pen(_lineColor), Point(location.x, y2), Point(bounds.right, y2));
				}
				row++;
				viewLine++;
			}
			else
			{
				row++;
				// Do not increment -viewLine- here.
			}
		}
		// Draw left side line.
		if (_leftSideLine)
			g.drawLine(new Pen(_lineColor), Point(location.x, location.y), Point(location.x, location.y + height * viewLine));
		// Draw right side line.
		if (_rightSideLine)
			g.drawLine(new Pen(_lineColor), Point(bounds.right, location.y), Point(bounds.right, location.y + height * viewLine));
		// Draw vertical line.
		if (_verticalLine)
		{
			for (int i; i < _columns - 1; i++)
			{
				int w = sum(_width[0..i+1]);
				g.drawLine(new Pen(_lineColor), Point(location.x + w, location.y), Point(location.x + w, location.y + height * viewLine));
			}
		}
		// Draw bottom side line.
		if (_bottomSideLine)
			g.drawLine(new Pen(_lineColor), Point(location.x, location.y + height * viewLine), Point(bounds.right, location.y + height * viewLine));
	}

	///
	void hasHeader(bool byes)
	{
		_hasHeader = byes;
	}

	///
	void showHeader(bool byes)
	{
		if (!_hasHeader)
			throw new DflException("DFL: showHeader is failure because do not have header.");
		_showHeader = byes;
	}

	///
	void headerLine(bool byes)
	{
		_headerLine = byes;
	}

	///
	void topSideLine(bool byes)
	{
		_topSideLine = byes;
	}

	///
	void leftSideLine(bool byes)
	{
		_leftSideLine = byes;
	}

	///
	void bottomSideLine(bool byes)
	{
		_bottomSideLine = byes;
	}
	
	///
	void rightSideLine(bool byes)
	{
		_rightSideLine = byes;
	}
	
	///
	void verticalLine(bool byes)
	{
		_verticalLine = byes;
	}
	
	///
	void horizontalLine(bool byes)
	{
		_horizontalLine = byes;
	}

	///
	Rect bounds() const
	{
		int rows = (_showHeader?1:0) + lastRecord - firstRecord + 1;
		return Rect(_location.x, _location.y, sum(_width), height * rows);
	}

	/// Left and Top point.
	void location(Point pt)
	{
		_location = pt;
	}
	/// ditto
	Point location() const
	{
		return _location;
	}
	/// ditto
	deprecated void margin(Point pt)
	{
		location = pt;
	}
	/// ditto
	deprecated Point margin()
	{
		return location;
	}

	///
	void paddingX(int px)
	{
		_paddingX = px;
	}

	///
	void paddingY(int py)
	{
		_paddingY = py;
	}

	///
	void firstRecord(int r)
	{
		_firstRecord = r;
	}
	///
	int firstRecord() const
	{
		return _firstRecord;
	}

	///
	void lastRecord(int r)
	{
		_lastRecord = r;
	}
	///
	int lastRecord() const
	{
		return _lastRecord;
	}

	///
	int columns() const
	{
		return _columns;
	}

	///
	void height(int h)
	{
		_height = h;
	}
	/// ditto
	int height() const
	{
		return _height;
	}

	///
	struct WidthObject // Internal struct.
	{
		///
		this(int[] w)
		{
			_arr = w;
		}

		/// Assign operator forwarding.
		void opIndexAssign(int value)
		{
			_arr[] = value;
		}
		/// ditto
		void opIndexAssign(int value, size_t i)
		{
			_arr[i] = value;
		}
		/// ditto
		void opSliceAssign(int value, size_t i, size_t j)
		{
			_arr[i..j] = value;
		}

		///
		int opIndex(size_t i)
		{
			return _arr[i];
		}
	
	private:
		int[] _arr;
	}
	
	///
	WidthObject width()
	{
		return WidthObject(_width);
	}

	///
	void textColor(Color c)
	{
		_textColor = c;
	}

	///
	void backColor(Color c)
	{
		_backColor = c;
	}

	///
	void lineColor(Color c)
	{
		_lineColor = c;
	}

	///
	void headerFont(Font f)
	{
		_headerFont = f;
	}

	///
	void recordFont(Font f)
	{
		_recordFont = f;
	}

	///
	void headerTextFormat(TextFormat tf)
	{
		_headerTextFormat = tf;
	}

	///
	void recordTextFormat(TextFormat tf)
	{
		_recordTextFormat = tf;
	}

private:
	string _csv;
	Point _location;
	int _paddingX;
	int _paddingY;
	int _columns;
	int _height;
	int[] _width;
	int _firstRecord;
	int _lastRecord;
	Color _textColor;
	Color _backColor;
	Color _lineColor;
	bool _hasHeader;
	bool _showHeader;
	bool _headerLine;
	bool _topSideLine;
	bool _leftSideLine;
	bool _bottomSideLine;
	bool _rightSideLine;
	bool _verticalLine;
	bool _horizontalLine;
	Font _headerFont;
	Font _recordFont;
	TextFormat _headerTextFormat;
	TextFormat _recordTextFormat;
}

///
class LineGraphRenderer(T...)
	if (is(T[0] == string) && T.length <= 17 || !is(T[0] == string) && T.length <= 16) // Supported number of colors is 16.
{
	///
	this(string csv, int numRecords)
	{
		this(csv);
		_firstRecord = 0;
		_lastRecord = numRecords - 1;
	}
	/// ditto
	this(string csv, int first, int last)
	{
		this(csv);
		_firstRecord = first;
		_lastRecord = last;
	}
	/// ditto
	this(string csv) // deprecated
	{
		_csv = csv;
		_vZeroPos = VerticalZeroPosition.BOTTOM;
		_chartMargins = ChartMargins(50, 50, 50, 50);
		_backColor = Color.white;
		_plotAreaBoundsColor = Color.black;
		_plotAreaHeightOnDisplay = 100;
		_plotAreaLeftPadding = 20;
		_plotAreaRightPadding = 20;
		_plotAreaAndLegendSpanX = 50;
		_plotAreaAndHorizontalScaleSpanY = 10;
		_plotPointSize = 10;
		_plotLineColorPalette = [
			Color.black,           // 0
			Color.blue,            // 1
			Color.red,             // 2
			Color.purple,          // 3
			Color.yellowGreen,     // 4
			Color.lightBlue,       // 5
			Color(0xFF,0xC2,0x0E), // 6: Use Himawari color as yellow.
			Color.lightGray,       // 7
			Color.black,           // 8
			Color.darkBlue,        // 9
			Color.darkRed,         // 10
			Color.mediumPurple,    // 11
			Color.darkGreen,       // 12
			Color.darkSeaGreen,    // 13
			Color.darkOrange,      // 14
			Color.darkGray         // 15
		];
		for (int i; i < T.length; i++)
		{
			_plotPointFormList ~= PlotPointForm.CIRCLE;
		}
		_legendWidth = 100;
		_legendLineHeight = 18;
		_hasVerticalScale = false;
		_verticalScaleWidth = 40;
		_verticalMaxScale = 100;
		_verticalScaleLineOuterSide = 5;
		_verticalScaleLineInnerSide = 5;
		_hasHorizontalScale = false;
		_horizontalScaleSpan = 50;
		_horizontalScaleLineInnerSide = 5;
		_horizontalScaleLineOuterSide = 5;
		_horizontalScaleHeight = 25;
	}

	/// Draw records.
	void draw(Graphics g)
	{
		// Draw background.
		Rect backgroundRect = Rect(
			plotAreaBounds.x - _chartMargins.left,
			plotAreaBounds.y - _chartMargins.top,
			plotAreaBounds.width + _chartMargins.left + _chartMargins.right,
			plotAreaBounds.height + _chartMargins.top + _chartMargins.bottom
		);
		if (_showLegend)
		{
			backgroundRect.width = plotAreaBounds.width + _chartMargins.left + _legendWidth + _chartMargins.right;
			int legendBottom = _chartMargins.top + _legendLineHeight * (1 + cast(int)T.length) + _chartMargins.bottom;
			if (legendBottom > backgroundRect.bottom)
				backgroundRect.height = legendBottom;
		}
		if (_hasVerticalScale)
		{
			backgroundRect.x = plotAreaBounds.x - _chartMargins.left - _verticalScaleWidth,
			backgroundRect.width = plotAreaBounds.width + _chartMargins.left + _legendWidth + _chartMargins.right + _verticalScaleWidth;
		}
		if (_hasHorizontalScale)
		{
			backgroundRect.height += _horizontalScaleHeight + _plotAreaAndHorizontalScaleSpanY;
		}
		g.fillRectangle(new SolidBrush(_backColor), backgroundRect);
		// Draw bounds of plot area.
		g.drawRectangle(new Pen(_plotAreaBoundsColor), plotAreaBounds);
		// Draw vertical scale.
		int baseY = (_vZeroPos == VerticalZeroPosition.BOTTOM ? 0: _plotAreaHeightOnDisplay);
		double vRatio = cast(double)_plotAreaHeightOnDisplay / _verticalMaxScale;
		if (_hasVerticalScale)
		{
			enum LINE_HEIGHT = 12f;
			auto scaleList = iota(0, _verticalMaxScale, _verticalScaleSpan);
			Font f = new Font("MS Gothic", LINE_HEIGHT);
			int x = _originPoint.x - _verticalScaleWidth;
			int index;
			foreach (s; scaleList)
			{
				int y = cast(int)(baseY + _originPoint.y - LINE_HEIGHT / 2 + index * vRatio * _verticalScaleSpan * (_vZeroPos == VerticalZeroPosition.BOTTOM ? -1: 1));
				// Draw vertical scalse label.
				g.drawText(to!string(index * _verticalScaleSpan), f, Color.black, Rect(x, y, 100, 100));
				// Draw vertical scalse line.
				g.drawLine(
					new Pen(_plotAreaBoundsColor),
					_originPoint.x - _verticalScaleLineOuterSide,
					cast(int)(y + LINE_HEIGHT / 2 + (_vZeroPos == VerticalZeroPosition.BOTTOM ? -1: 0)),
					_originPoint.x + _verticalScaleLineInnerSide,
					cast(int)(y + LINE_HEIGHT / 2 + (_vZeroPos == VerticalZeroPosition.BOTTOM ? -1: 0))
				);
				index++;
			}
		}
		// Draw horizontal scale.
		if (_hasHorizontalScale)
		{
			// Draw horizontal scale label.
			static if (is(T[0] == string))
			{{
				int i;
				foreach (label; csvReader!(Tuple!T)(_csv, null))
				{
					int x = _originPoint.x + _plotAreaLeftPadding + i * _horizontalScaleSpan - cast(int)_horizontalScaleHeight;
					int y = baseY + _originPoint.y + (_vZeroPos == VerticalZeroPosition.BOTTOM ? _plotAreaAndHorizontalScaleSpanY: -_plotAreaAndHorizontalScaleSpanY - _horizontalScaleHeight);
					g.drawText(
						label[0],
						new Font("MS Gothic", 12f),
						_plotAreaBoundsColor,
						Rect(x, y, _horizontalScaleSpan, _horizontalScaleHeight)
					);
					i++;
				}
			}}
			//
			for (int i; i < _lastRecord - _firstRecord + 1; i++)
			{
				int x = _originPoint.x + _plotAreaLeftPadding + i * _horizontalScaleSpan;
				int y = baseY + _originPoint.y;
				// Draw horizontal scale line.
				g.drawLine(
					new Pen(_plotAreaBoundsColor),
					x,
					y - _horizontalScaleLineInnerSide * (_vZeroPos == VerticalZeroPosition.BOTTOM ? 1 : -1),
					x,
					y + _horizontalScaleLineOuterSide * (_vZeroPos == VerticalZeroPosition.BOTTOM ? 1 : -1)
				);
			}
		}
		// Draw legend.
		if (_showLegend)
		{
			int legendLine;
			foreach (i, value; csvReader!(Tuple!T)(_csv, null).header)
			{
				static if (is(T[0] == string))
				{
					if (i == 0) continue;
				}
				int x = plotAreaBounds.right + _plotAreaAndLegendSpanX + _plotPointSize;
				int y = plotAreaBounds.y + _legendLineHeight * cast(int)legendLine;
				g.drawText(to!string(value), new Font("MS Gothic", 12f), Color.black, Rect(x, y, 100, 100));
				_drawPlotPoint(
					g,
					new Pen(_plotLineColorPalette[legendLine]),
					_plotPointFormList[legendLine],
					_plotPointSize, x - _plotPointSize * 2, // Center X.
					y + _legendLineHeight / 2 // Center Y.
				);
				legendLine++;
			}
		}
		// Draw records.
		Tuple!T prevRecord;
		int x1 = _originPoint.x + _plotAreaLeftPadding;
		int x2;
		bool isFirstRecord = true;
		auto csvRange = csvReader!(Tuple!T)(_csv, null).drop(_firstRecord);
		foreach (currRecord; csvRange)
		{
			x2 = x1 + _horizontalScaleSpan;
			bool isFirstColumn = true;
			foreach (col, value; currRecord)
			{
				static if (!(is(T[0] == string) && col == 0))
				{
					int y1 = cast(int)(baseY + _originPoint.y + vRatio * prevRecord[col] * (_vZeroPos == VerticalZeroPosition.BOTTOM ? -1: 1));
					int y2 = cast(int)(baseY + _originPoint.y + vRatio * value * (_vZeroPos == VerticalZeroPosition.BOTTOM ? -1: 1));
					int seriesIndex = col - (is(T[0] == string)?1:0);
					if (!isFirstRecord)
					{
						g.drawLine(
							new Pen(_plotLineColorPalette[seriesIndex]),
							x1 - _horizontalScaleSpan,
							y1,
							x2 - _horizontalScaleSpan,
							y2
						);
					}
					_drawPlotPoint(
						g,
						new Pen(_plotLineColorPalette[seriesIndex]),
						_plotPointFormList[seriesIndex],
						_plotPointSize,
						x2 - _horizontalScaleSpan, // Center X.
						y2 // Center Y.
					);
				}
				isFirstColumn = false;
			}
			x1 = x1 + _horizontalScaleSpan;
			prevRecord = currRecord;
			isFirstRecord = false;
		}
	}

	///
	Rect plotAreaBounds() const
	{
		return Rect(
			_originPoint.x,
			_originPoint.y + _plotAreaHeightOnDisplay * (_vZeroPos == VerticalZeroPosition.BOTTOM ? -1 : 1),
			cast(int)((_lastRecord - _firstRecord) * _horizontalScaleSpan) + _plotAreaLeftPadding + _plotAreaRightPadding,
			_plotAreaHeightOnDisplay
		);
	}

	///
	void originPoint(Point pt)
	{
		_originPoint = pt;
	}

	///
	void relocate(Point pt)
	{
		final switch (_vZeroPos)
		{
		case VerticalZeroPosition.BOTTOM:
			int x = _chartMargins.left + _verticalScaleWidth + pt.x;
			int y = _chartMargins.top + _plotAreaHeightOnDisplay + pt.y;
			originPoint = Point(x, y);
			break;
		case VerticalZeroPosition.TOP:
			int x = _chartMargins.left + _verticalScaleWidth + pt.x;
			int y = _chartMargins.top + pt.y - _plotAreaHeightOnDisplay;
			originPoint = Point(x, y);
		}
	}

	///
	void verticalZeroPosition(VerticalZeroPosition vZeroPos) // setter
	{
		_vZeroPos = vZeroPos;
	}

	///
	void chartMargins(ChartMargins m)
	{
		_chartMargins = m;
	}

	///
	void plotPointSize(int size)
	{
		_plotPointSize = size;
	}

	///
	void showLegend(bool byes)
	{
		_showLegend = byes;
	}

	///
	void plotLineColorPalette(Color[] colors)
	{
		_plotLineColorPalette = colors;
	}
	/// ditto
	Color[] plotLineColorPalette()
	{
		return _plotLineColorPalette;
	}

	///
	void plotAreaAndLegendSpanX(int x)
	{
		_plotAreaAndLegendSpanX = x;
	}

	///
	void plotAreaAndHorizontalScaleSpanY(int y)
	{
		_plotAreaAndHorizontalScaleSpanY = y;
	}

	///
	void legendLineHeight(int h)
	{
		_legendLineHeight = h;
	}

	///
	void legendWidth(int w)
	{
		_legendWidth = w;
	}

	///
	void plotAreaRightPadding(int x)
	{
		_plotAreaRightPadding = x;
	}

	///
	void plotAreaLeftPadding(int x)
	{
		_plotAreaLeftPadding = x;
	}

	///
	void firstRecord(int i)
	{
		_firstRecord = i;
	}

	///
	void lastRecord(int i)
	{
		_lastRecord = i;
	}
	
	///
	void backColor(Color c)
	{
		_backColor = c;
	}

	///
	void plotAreaBoundsColor(Color c)
	{
		_plotAreaBoundsColor = c;
	}

	///
	void horizontalScaleSpan(int x)
	{
		_horizontalScaleSpan = x;
	}

	///
	void verticalMaxScale(int m)
	{
		_verticalMaxScale = m;
	}

	///
	void plotAreaHeightOnDisplay(int h)
	{
		_plotAreaHeightOnDisplay = h;
	}

	///
	void hasVerticalScale(bool byes)
	{
		_hasVerticalScale = byes;
	}

	///
	void hasHorizontalScale(bool byes)
	{
		_hasHorizontalScale = byes;
	}

	///
	void verticalScaleSpan(int scale)
	{
		_verticalScaleSpan = scale;
	}

	///
	void verticalScaleWidth(int w)
	{
		_verticalScaleWidth = w;
	}

	///
	void verticalScaleLineOuterSide(int w)
	{
		_verticalScaleLineOuterSide = w;
	}

	///
	void verticalScaleLineInnerSide(int w)
	{
		_verticalScaleLineInnerSide = w;
	}

	///
	void horizontalScaleLineInnerSide(int h)
	{
		_horizontalScaleLineInnerSide = h;
	}

	///
	void horizontalScaleLineOuterSide(int h)
	{
		_horizontalScaleLineOuterSide = h;
	}

	///
	void horizontalScaleHeight(int h)
	{
		_horizontalScaleHeight = h;
	}

	///
	void plotPointFormList(PlotPointForm[] forms)
	{
		_plotPointFormList = forms;
	}
	/// ditto
	PlotPointForm[] plotPointFormList()
	{
		return _plotPointFormList;
	}

private:
	string _csv;
	int _firstRecord;
	int _lastRecord;
	VerticalZeroPosition _vZeroPos;
	Point _originPoint;
	ChartMargins _chartMargins;
	bool _showLegend;
	int _legendLineHeight;
	int _legendWidth;
	Color _backColor;
	Color _plotAreaBoundsColor;
	int _plotAreaLeftPadding;
	int _plotAreaRightPadding;
	int _plotAreaHeightOnDisplay;
	int _plotAreaAndLegendSpanX;
	int _plotAreaAndHorizontalScaleSpanY;
	int _plotPointSize;
	Color[] _plotLineColorPalette;
	PlotPointForm[] _plotPointFormList;
	bool _hasHorizontalScale;
	int _horizontalScaleSpan;
	int _horizontalScaleHeight;
	int _horizontalScaleLineInnerSide;
	int _horizontalScaleLineOuterSide;
	bool _hasVerticalScale;
	int _verticalMaxScale;
	int _verticalScaleSpan;
	int _verticalScaleWidth;
	int _verticalScaleLineOuterSide;
	int _verticalScaleLineInnerSide;

	///
	void _drawPlotPoint(Graphics g, Pen pen, PlotPointForm form, int plotPointSize, int centerX, int centerY)
	{
		final switch (form)
		{
		case PlotPointForm.CIRCLE:
			g.drawEllipse(
				pen,
				centerX - _plotPointSize / 2,
				centerY - _plotPointSize / 2,
				plotPointSize, // width
				plotPointSize // height
			);
			break;
		case PlotPointForm.RECTANGLE:
			g.drawRectangle(
				pen,
				centerX - _plotPointSize / 2,
				centerY - _plotPointSize / 2,
				plotPointSize, // width
				plotPointSize // height
			);
			break;
		case PlotPointForm.CROSS:
			g.drawLine(
				pen,
				centerX - _plotPointSize / 2,
				centerY - _plotPointSize / 2,
				centerX + _plotPointSize / 2 + 1,
				centerY + _plotPointSize / 2 + 1
			);
			g.drawLine(
				pen,
				centerX + _plotPointSize / 2,
				centerY - _plotPointSize / 2,
				centerX - _plotPointSize / 2 - 1,
				centerY + _plotPointSize / 2 + 1
			);
			break;
		case PlotPointForm.TRIANGLE:
			g.drawLine(
				pen,
				centerX,
				centerY - _plotPointSize * 2 / 3,
				centerX + _plotPointSize / 2,
				centerY + _plotPointSize / 3
			);
			g.drawLine(
				pen,
				centerX,
				centerY - _plotPointSize * 2 / 3,
				centerX - _plotPointSize / 2,
				centerY + _plotPointSize / 3
			);
			g.drawLine(
				pen,
				centerX - _plotPointSize / 2,
				centerY + _plotPointSize / 3,
				centerX + _plotPointSize / 2,
				centerY + _plotPointSize / 3
			);
			break;
		}
	}
}

///
struct ChartMargins
{
	int left; /// Left margin.
	int top; /// Top margin.
	int right; /// Right margin.
	int bottom; /// Bottom margin.

	///
	this(int left, int top, int right, int bottom)
	{
		this.left = left;
		this.top = top;
		this.right = right;
		this.bottom = bottom;
	}

	///
	string toString() const
	{
		
		string str = "[";
		str ~= to!string(left) ~ " ,";
		str ~= to!string(top) ~ " ,";
		str ~= to!string(right) ~ " ,";
		str ~= to!string(bottom) ~ "]";
		return str;
	}
}

///
enum VerticalZeroPosition
{
	TOP,
	BOTTOM,
}

///
enum PlotPointForm
{
	CIRCLE,
	RECTANGLE,
	CROSS,
	TRIANGLE,
}