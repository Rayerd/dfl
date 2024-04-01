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

///
class TableRenderer(T...)
{
	enum DEFAULT_HEIGHT = 25; ///
	enum DEFAULT_WIDTH = 100; ///
	enum DEFAULT_PADDING_X = 5; ///
	enum DEFAULT_PADDING_Y = 5; ///

	///
	this(string csv)
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
			g.drawLine(new Pen(_lineColor), Point(margin.x, margin.y), Point(bounds.right, margin.y));
		// Draw header line.
		if (_showHeader && _hasHeader && _headerLine)
			g.drawLine(new Pen(_lineColor), Point(margin.x, margin.y + height), Point(bounds.right, margin.y + height));
		// Draw header and records.
		int row; // -row- is line number in CSV.
		int viewLine; // -viewLine- is line number on display.
		foreach (record; csvReader!(Tuple!T)(_csv))
		{
			// Draw header.
			if (row == 0)
			{
				if (_hasHeader)
				{
					if (_showHeader)
					{
						int y = margin.y + viewLine * height + _paddingY;
						foreach (int col, value; record)
						{
							int x = margin.x + sum(_width[0..col]) + _paddingX;
							g.drawText(to!string(value), _headerFont, _textColor, Rect(x, y, _width[col] - _paddingX, _height - _paddingY), _headerTextFormat);
						}
						row++;
						viewLine++;
						continue;
					}
					else
					{
						row++;
						// Do not increment -viewLine- here.
						continue;
					}
				}
			}
			// Draw record.
			int rows = (_hasHeader?1:0) + lastRecord - firstRecord + 1;
			if (firstRecord + (_hasHeader?1:0) <= row && row <= rows)
			{
				int y = margin.y + viewLine * height + _paddingY;
				foreach (int col, value; record)
				{
					int x = margin.x + sum(_width[0..col]) + _paddingX;
					g.drawText(to!string(value), _recordFont, _textColor, Rect(x, y, _width[col] - _paddingX, _height - _paddingY), _recordTextFormat);
				}
				// Draw horizontal line.
				if (_horizontalLine && viewLine < lastRecord - firstRecord + (_showHeader?1:0))
				{
					int y2 = margin.y + height * (viewLine + 1);
					g.drawLine(new Pen(_lineColor), Point(margin.x, y2), Point(bounds.right, y2));
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
			g.drawLine(new Pen(_lineColor), Point(margin.x, margin.y), Point(margin.x, margin.y + height * viewLine));
		// Draw right side line.
		if (_rightSideLine)
			g.drawLine(new Pen(_lineColor), Point(bounds.right, margin.y), Point(bounds.right, margin.y + height * viewLine));
		// Draw vertical line.
		if (_verticalLine)
		{
			for (int i; i < _columns - 1; i++)
			{
				int w = sum(_width[0..i+1]);
				g.drawLine(new Pen(_lineColor), Point(margin.x + w, margin.y), Point(margin.x + w, margin.y + height * viewLine));
			}
		}
		// Draw bottom side line.
		if (_bottomSideLine)
			g.drawLine(new Pen(_lineColor), Point(margin.x, margin.y + height * viewLine), Point(bounds.right, margin.y + height * viewLine));
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
		return Rect(_margin.x, _margin.y, sum(_width), height * rows);
	}

	/// Left and Top margins.
	void margin(Point pt)
	{
		_margin.x = pt.x;
		_margin.y = pt.y;
	}
	/// ditto
	Point margin() const
	{
		return _margin;
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
		this(ref int[] w)
		{
			_arr = w;
		}

		///
		void opIndexAssign(int value, size_t i)
		{
			_arr[i] = value;
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
	Point _margin;
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
