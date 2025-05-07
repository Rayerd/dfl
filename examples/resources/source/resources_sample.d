import dfl;

import dfl.internal.dlib;

import core.sys.windows.winnt;
import core.sys.windows.winuser;

import std.conv;

version(Have_dfl) // For DUB.
{
}
else
{
	pragma(lib, "dfl.lib");
}

struct RCData
{
	string ansiString;
	wstring unicodeString;
	WORD wordInt;
	DWORD dwordInt;
	WORD wordHexInt;
	WORD wordOctInt;
}

RCData parseRCData(const(ubyte)* ptr, size_t size)
{
	RCData data;
	size_t offset;

	// string ansiString: ANSI null-terminated string
	auto start = offset;
	while (offset < size && ptr[offset] != 0)
		offset += char.sizeof;
	data.ansiString = cast(string)ptr[start .. offset];
	offset += char.sizeof; // skip null terminator

	// wstring unicodeString: Unicode null-terminated string
	start = offset;
	while (offset + 1 < size && (ptr[offset] != 0 || ptr[offset + 1] != 0))
		offset += wchar.sizeof;
	data.unicodeString = cast(wstring)ptr[start .. offset];
	offset += wchar.sizeof; // skip null terminator

	// WORD wordInt
	data.wordInt = *cast(WORD*)&ptr[offset];
	offset += WORD.sizeof;

	// DWORD dwordInt
	data.dwordInt = *cast(DWORD*)&ptr[offset];
	offset += DWORD.sizeof;

	// WORD wordHexIn
	data.wordHexInt = *cast(WORD*)&ptr[offset];
	offset += WORD.sizeof;

	// WORD wordOctInt
	data.wordOctInt = *cast(WORD*)&ptr[offset];
	offset += WORD.sizeof;

	return data;
}

class MainForm : Form
{
	Bitmap _bmp;
	Cursor _cur;
	Icon _ico;
	string[] _str;
	RCData _rcdata;

	public this()
	{
		this.text = "Resources example";
		this.size = Size(600, 600);

		Resources r = new Resources(Application.getInstance());

		_bmp = r.getBitmap(257);
		
		_cur = r.getCursor(259);

		_ico = r.getIcon(256, 32, 32);
		this.icon = _ico;

		_str = [r.getString(260), r.getString(261)];

		void[] dat = r.getData(RT_RCDATA, 258);
		_rcdata = parseRCData(cast(ubyte*)dat, dat.length);
	}

	override void onPaint(PaintEventArgs e)
	{
		Font fon = new Font("msgothic", 12);
		e.graphics.drawText(_str[0] ~ " " ~ _str[1], fon, Color.black, Rect(0, 0, width, height));

		e.graphics.drawText(_rcdata.ansiString, fon, Color.black, Rect(0, 50, width, height));
		e.graphics.drawText(_rcdata.unicodeString.to!string(), fon, Color.black, Rect(0, 70, width, height));
		e.graphics.drawText(_rcdata.wordInt.to!string(), fon, Color.black, Rect(0, 90, width, height));
		e.graphics.drawText(_rcdata.dwordInt.to!string(), fon, Color.black, Rect(0, 110, width, height));
		e.graphics.drawText(_rcdata.wordHexInt.to!string(), fon, Color.black, Rect(0, 130, width, height));
		e.graphics.drawText(_rcdata.wordOctInt.to!string(), fon, Color.black, Rect(0, 150, width, height));

		_bmp.draw(e.graphics, Point(100, 200));
	}

	override void wndProc(ref Message msg)
	{
		if (msg.msg == WM_SETCURSOR)
		{
			Cursor.current = _cur;
			return; // Returns so that the class cursor is not displayed.
		}
		super.wndProc(msg);
	}
}

static this()
{
	Application.enableVisualStyles();

	import dfl.internal.dpiaware;
	// SetProcessDpiAwarenessContext(DPI_AWARENESS_CONTEXT_UNAWARE); // OK
	// SetProcessDpiAwarenessContext(DPI_AWARENESS_CONTEXT_UNAWARE_GDISCALED); // OK
	// SetProcessDpiAwarenessContext(DPI_AWARENESS_CONTEXT_SYSTEM_AWARE); // Windows suppresses the display of balloon tips.
	SetProcessDpiAwarenessContext(DPI_AWARENESS_CONTEXT_PER_MONITOR_AWARE_V2); // ditto.
}

void main()
{
	Application.run(new MainForm());
}
