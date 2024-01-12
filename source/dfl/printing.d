// printing.d
//
// Copyright (C) 2024 haru-s/Rayerd

/// 
module dfl.printing;

pragma(msg, "DFL: dfl.printing module is an experimental version."); // NOTE

pragma(lib, "WinSpool");

private import dfl.base;
private import dfl.commondialog;
private import dfl.drawing;
private import dfl.event;
private import dfl.messagebox;

private import dfl.internal.utf;

private import core.sys.windows.commdlg;
private import core.sys.windows.windows;

private import std.conv;

/// Convert to 1/1000 mm unit from 1/100 inch unit.
private int _mmFromInch(int inch)// NOTE: Bad name.
{
	return cast(int)(inch * 2.54 * 10.0);
}

/// Convert to 1/100 inch unit from 1/1000 mm unit.
private int _inchFromMm(int mm)// NOTE: Bad name.
{
	return cast(int)(mm / 2.54 / 10.0);
}

///
enum PaperKind
{
	A2 = 66,
	A3 = 8,
	A3_EXTRA = 63,
	A3_EXTRA_TRANSVERSE = 68,
	A3_ROTATED = 76,
	A3_TRANSVERSE = 67,
	A4 = 9,
	A4_EXTRA = 53,
	A4_PLUS = 60,
	A4_ROTATED = 77,
	A4_SMALL = 10,
	A4_TRANSVERSE = 55,
	A5 = 11,
	A5_EXTRA = 64,
	A5_ROTATED = 78,
	A5_TRANSVERSE = 61,
	A6 = 70,
	A6_ROTATED = 83,
	A_PLUS = 57,
	B4 = 12,
	B4_ENVELOPE = 33,
	B4_JIS_ROTATED = 79,
	B5 = 13,
	B5_ENVELOPE = 34,
	B5_EXTRA = 65,
	B5_JIS_ROTATED = 80,
	B5_TRANSVERSE = 62,
	B6_ENVELOPE = 35,
	B6_JIS = 88,
	B6_JIS_ROTATED = 89,
	B_PLUS = 58,
	C3_ENVELOPE = 29,
	C4_ENVELOPE = 30,
	C5_ENVELOPE = 28,
	C65_ENVELOPE = 32,
	C6_ENVELOPE = 31,
	C_SHEET = 24,
	CUSTOM = 0,
	DL_ENVELOPE = 27,
	D_SHEET = 25,
	E_SHEET = 26,
	EXECUTIVE = 7,
	FOLIO = 14,
	GERMAN_LEGAL_FANFOLD = 41,
	GERMAN_STANDARD_FANFOLD = 40,
	INVITE_ENVELOPE = 47,
	ISO_B4 = 42,
	ITALY_ENVELOPE = 36,
	JAPANESE_DOUBLE_POSTCARD = 69,
	JAPANESE_DOUBLE_POSTCARD_ROTATED = 82,
	JAPANESE_ENVELOPE_CHOU_NUMBER3 = 73,
	JAPANESE_ENVELOPE_CHOU_NUMBER3_ROTATED = 86,
	JAPANESE_ENVELOPE_CHOU_NUMBER4 = 74,
	JAPANESE_ENVELOPE_CHOU_NUMBER4_ROTATED = 87,
	JAPANESE_ENVELOPE_KAKU_NUMBER2 = 71,
	JAPANESE_ENVELOPE_KAKU_NUMBER2_ROTATED = 84,
	JAPANESE_ENVELOPE_KAKU_NUMBER3 = 72,
	JAPANESE_ENVELOPE_KAKU_NUMBER3_ROTATED = 85,
	JAPANESE_ENVELOPE_YOU_NUMBER4 = 91,
	JAPANESE_ENVELOPE_YOU_NUMBER4_ROTATED = 92,
	JAPANESE_POSTCARD = 43,
	JAPANESE_POSTCARD_ROTATED = 81,
	LEDGER = 4,
	LEGAL = 5,
	LEGAL_EXTRA = 51,
	LETTER = 1,
	LETTER_EXTRA = 50,
	LETTER_EXTRA_TRANSVERSE = 56,
	LETTER_PLUS = 59,
	LETTER_ROTATED = 75,
	LETTER_SMALL = 2,
	LETTER_TRANSVERSE = 54,
	MONARCH_ENVELOPE = 37,
	NOTE = 18,
	NUMBER10_ENVELOPE = 20,
	NUMBER11_ENVELOPE = 21,
	NUMBER12_ENVELOPE = 22,
	NUMBER14_ENVELOPE = 23,
	NUMBER9_ENVELOPE = 19,
	PERSONAL_ENVELOPE = 38,
	PRC_16K = 93,
	PRC_16K_ROTATED = 106,
	PRC_32K = 94,
	PRC_32K_BIG = 95,
	PRC_32K_BIG_ROTATED = 108,
	PRC_32K_ROTATED = 107,
	PRC_ENVELOPE_NUMBER1 = 96,
	PRC_ENVELOPE_NUMBER10 = 105,
	PRC_ENVELOPE_NUMBER10_ROTATED = 118,
	PRC_ENVELOPE_NUMBER1_ROTATED = 109,
	PRC_ENVELOPE_NUMBER2 = 97,
	PRC_ENVELOPE_NUMBER2_ROTATED = 110,
	PRC_ENVELOPE_NUMBER3 = 98,
	PRC_ENVELOPE_NUMBER3_ROTATED = 111,
	PRC_ENVELOPE_NUMBER4 = 99,
	PRC_ENVELOPE_NUMBER4_ROTATED = 112,
	PRC_ENVELOPE_NUMBER5 = 100,
	PRC_ENVELOPE_NUMBER5_ROTATED = 113,
	PRC_ENVELOPE_NUMBER6 = 101,
	PRC_ENVELOPE_NUMBER6_ROTATED = 114,
	PRC_ENVELOPE_NUMBER7 = 102,
	PRC_ENVELOPE_NUMBER7_ROTATED = 115,
	PRC_ENVELOPE_NUMBER8 = 103,
	PRC_ENVELOPE_NUMBER8_ROTATED = 116,
	PRC_ENVELOPE_NUMBER9 = 104,
	PRC_ENVELOPE_NUMBER9_ROTATED = 117,
	QUARTO = 15,
	STANDARD10X11 = 45,
	STANDARD10X14 = 16,
	STANDARD11X17 = 17,
	STANDARD12X11 = 90,
	STANDARD15X11 = 46,
	STANDARD9X11 = 44,
	STATEMENT = 6,
	TABLOID = 3,
	TABLOID_EXTRA = 52,
	US_STANDARD_FANFOLD = 39,
}

///
enum PaperSourceKind
{
	AUTOMATIC_FEED = 7,
	CASSETTE = 14,
	CUSTOM = 257,
	ENVELOPE = 5,
	FORM_SOURCE = 15,
	LARGE_CAPACITY = 11,
	LARGE_FORMAT = 10,
	LOWER = 2,
	MANUAL = 4,
	MANUAL_FEED = 6,
	MIDDLE = 3,
	SMALL_FORMAT = 9,
	TRACTOR_FEED = 8,
	UPPER = 1,
}

///
class PaperSource
{
	private PaperSourceKind _kind;
	private string _sourceName;

	///
	this()
	{
		_kind = PaperSourceKind.CUSTOM;
		_sourceName = "";
	}
	/// ditto
	this(PaperSourceKind kind, string sourceName)
	{
		_kind = kind;
		_sourceName = sourceName;
	}

	///
	PaperSourceKind kind() const // getter
	{
		return _kind;
	}

	// void rawKind(int k); // TODO: Not implemented.
	// int rawKind() const; // TODO: Not implemented.

	///
	void sourceName(string name) // setter
	{
		_sourceName = name;
	}
	string sourceName() const // getter
	{
		return _sourceName;
	}

	///
	override string toString() const
	{
		
		return "[" ~ to!string(_kind) ~ ", " ~ _sourceName ~ "]";
	}
}

///
enum PrintAction
{
	PRINT_TO_FILE = 0,
	PRINT_TO_PREVIEW = 1,
	PRINT_TO_PRINTER = 2,
}

///
class PrintEventArgs : EventArgs
{
	bool cancel = false;
	HDC hDC;

	///
	this(HDC hDC)
	{
		this.hDC = hDC;
	}

	///
	PrintAction printAction() const // getter
	{
		return PrintAction.PRINT_TO_FILE;
	}
}

///
class PrintPageEventArgs : EventArgs
{
	bool cancel = false;
	Graphics graphics;
	bool hasMorePage;
	Rect marginBounds;
	Rect pageBounds;
	PageSettings pageSettings;
	HDC hDC;
	int currentPage;

	///
	this(Graphics graphics, Rect marginBounds, Rect pageBounds, PageSettings pageSettings, int currentPage)
	{
		this.graphics = graphics;
		this.marginBounds = marginBounds;
		this.pageBounds = pageBounds;
		this.pageSettings = pageSettings;
		this.currentPage = currentPage;
	}
}

///
class QueryPageSettingsEventArgs : PrintEventArgs
{
	bool cancel = false;
	PageSettings pageSettings;
	int currentPage;

	///
	this(HDC hDC, PageSettings pageSettings, int currentPage)
	{
		super(hDC);
		this.pageSettings = pageSettings;
		this.currentPage = currentPage;
	}
}

///
abstract class PrintController
{
	///
	bool isPreview() const
	{
		return false;
	}

	///
	int onStartPrint(PrintDocument document, PrintEventArgs e)
	{
		return 0;
	}

	///
	void onEndPrint(PrintDocument document, PrintEventArgs e)
	{
	}

	///
	void onStartPage(PrintDocument document, PrintPageEventArgs e)
	{
	}

	///
	void onEndPage(PrintDocument document, PrintPageEventArgs e)
	{
	}
}

///
class StandardPrintController : PrintController
{
	///
	this()
	{
	}

	///
	override int onStartPrint(PrintDocument document, PrintEventArgs e)
	{
		DOCINFO info;
		info.cbSize = info.sizeof;
		// info.lpszOutput:
		//  If this pointer is NULL, the output will be sent to the device identified
		//  by the device context handle that was passed to the StartDoc function.
		info.lpszOutput = null;
		info.lpszDocName = document.documentName.ptr;
		info.lpszDatatype = null;
		info.fwType = 0;
		int printJobID = StartDoc(e.hDC, &info);
		assert(printJobID > 0);
		return printJobID;
	}

	///
	override void onEndPrint(PrintDocument document, PrintEventArgs e)
	{
		EndDoc(e.hDC);
	}
	
	///
	override void onStartPage(PrintDocument document, PrintPageEventArgs e)
	{
		StartPage(e.hDC);
	}

	///
	override void onEndPage(PrintDocument document, PrintPageEventArgs e)
	{
		EndPage(e.hDC);
	}
}

class PrintDocument
{
	PrinterSettings printerSettings;
	PrintController printController;
	wstring documentName;
	bool originAtMargins = false; // TODO: Implement.

	///
	this()
	{
		documentName = "document";
		printerSettings = new PrinterSettings();
		printController = new StandardPrintController();
	}

	///
	void print(HDC hDC)
	{
		PrintEventArgs printArgs = new PrintEventArgs(hDC);
		onBeginPrint(printArgs);
		if (printArgs.cancel)
			return;

		int printJobID = printController.onStartPrint(this, printArgs); // Call StartDoc() API
		if (printArgs.cancel)
			return;

		int pageCounter;
		PrintPageEventArgs printPageArgs;
		do
		{
		SKIP:
			pageCounter++;
			Graphics g = new Graphics(printArgs.hDC, false);

			PageSettings newPageSettings = this.printerSettings.defaultPageSettings.clone();
			QueryPageSettingsEventArgs queryPageSettingsArgs = new QueryPageSettingsEventArgs(hDC, newPageSettings, pageCounter);
			onQueryPageSettings(queryPageSettingsArgs); // Be modified pageSettings of current page by user.

			if (this.printerSettings.printRange.kind != PrintRangeKind.ALL_PAGES)
			{
				bool contains = false;
				assert(!printerSettings.printRange.empty());
				foreach (ref const(PrintRange) iter; printerSettings.printRange.ranges)
				{
					if (iter.fromPage <= pageCounter && pageCounter <= iter.toPage)
						contains = true;
				}
				if (!contains) goto SKIP;
			}

			PageSettings ps = queryPageSettingsArgs.pageSettings;
			Rect marginBounds = ps.bounds; // 1/100 inch unit.
			Rect pageBounds = Rect(0, 0, ps.paperSize.width, ps.paperSize.height); // 1/100 inch unit.
			printPageArgs = new PrintPageEventArgs(g, marginBounds, pageBounds, ps, pageCounter);
			printController.onStartPage(this, printPageArgs); // Call StartPage() API

			printPageArgs.hDC = hDC;
			if(!printPageArgs.cancel)
				this.onPrintPage(printPageArgs);
			
			printController.onEndPage(this, printPageArgs); // Call EndPage() API
			if (printPageArgs.cancel)
				break;
			
			if (this.printerSettings.printRange.empty() != 0 && this.printerSettings.printRange.ranges[$-1].toPage == pageCounter)
				break;
		} while (printPageArgs.hasMorePage);

		onEndPrint(printArgs);
		printController.onEndPrint(this, printArgs); // Call EndPrint() API
	}

	///
	void onBeginPrint(PrintEventArgs e)
	{
		beginPrint(this, e);
	}

	///
	void onEndPrint(PrintEventArgs e)
	{
		endPrint(this, e);
	}

	///
	void onPrintPage(PrintPageEventArgs e)
	{
		printPage(this, e);
	}

	///
	void onQueryPageSettings(QueryPageSettingsEventArgs e)
	{
		queryPageSettings(this, e);
	}

	///
	Event!(PrintDocument, PrintEventArgs) beginPrint;
	///
	Event!(PrintDocument, PrintEventArgs) endPrint;
	///
	Event!(PrintDocument, PrintPageEventArgs) printPage;
	///
	Event!(PrintDocument, QueryPageSettingsEventArgs) queryPageSettings;
}

///
enum Duplex
{
	DEFAULT = -1,
	HORIZONTAL = 3,
	SIMPLEX = 1,
	VERTICAL = 2,
}

///
enum PrintRangeKind
{
	ALL_PAGES = 0,
	CURRENT_PAGE = 4194304,
	SELECTION = 1,
	SOME_PAGES = 2,
}

///
struct PrintRange
{
	int fromPage;
	int toPage;
	string toString() const
	{
		return "(" ~ to!string(fromPage) ~ ", " ~ to!string(toPage) ~ ")";
	}
}

///
class PrintRangeSettings
{
	PrintRangeKind kind;
	private PrintRange[] _ranges;

	///
	const(PrintRange[]) ranges() const
	{
		return _ranges;
	}

	///
	void addPrintRange(PrintRange range)
	{
		_ranges ~= range;
	}

	///
	void reset()
	{
		_ranges.length = 0;
	}

	///
	bool empty() const
	{
		return _ranges.length == 0;
	}

	///
	override string toString() const
	{
		string str = "[";
		str ~= "kind: " ~ to!string(kind) ~ ", ";
		str ~= "ranges: " ~ to!string(ranges) ~ "]";
		return str;
	}
}

///
class PrinterSettings
{
	string printerName;
	string printFileName;
	int copies;
	int maximumPage;
	int minimumPage;
	PrintRangeSettings printRange;
	bool collate;
	int maximumCopies;
	bool canDuplex;
	bool supportColor;
	int landscapeAngle;
	bool printToFile;
	PrinterResolution[] printerResolutions; // TODO: Implement.
	PaperSize[] paperSizes; // TODO: Implement.
	PaperSource[] paperSources; // TODO: Implement.
	bool isPlotter;
	Duplex duplex;

	private PageSettings _defaultPageSettings;

	///
	this()
	{
		reset();
	}

	///
	private void reset()
	{
		_defaultPageSettings = null;
		printRange = new PrintRangeSettings();
		maximumPage = 9999;
		copies = 1;
		collate = true;
		printerResolutions = null;
		paperSizes = null;
		paperSources = null;
	}

	///
	PageSettings defaultPageSettings()
	{
		if (!_defaultPageSettings)
		{
			_defaultPageSettings = new PageSettings(
				this,
				this.supportColor,
				false, // true is landscape (w > h).
				new PaperSize(PaperKind.A4, "A4", 827, 1169), // 1/100 inch unit. (210 x 297 mm)
				new PaperSource(PaperSourceKind.FORM_SOURCE, "Tray"),
				new PrinterResolution(PrinterResolutionKind.CUSTOM, 200, 200)); // dpi unit.
		}
		return _defaultPageSettings;
	}

	///
	void setHdevmode(HGLOBAL hDevMode)
	{
		DEVMODE* pDevMode = cast(DEVMODE*)GlobalLock(hDevMode);
		scope(exit)
			GlobalUnlock(pDevMode);

		string deviceName = fromUnicodez(pDevMode.dmDeviceName.ptr);
		this.printerName = deviceName;

		// TODO
		// this.printFileName =
		this.copies = pDevMode.dmCopies;
		// this.maximumPage = _printDialog.nMaxPage;
		// this.minimumPage =
		// this.fromPage =
		// this.toPage = _printDialog.toPage;
		// this.printRange =
		this.collate = DeviceCapabilities(toUnicodez(deviceName), "", DC_COLLATE, null, pDevMode) == 1 ? true : false;
		this.maximumCopies = DeviceCapabilities(toUnicodez(deviceName), "", DC_COPIES, null, pDevMode);
		this.canDuplex = DeviceCapabilities(toUnicodez(deviceName), "", DC_DUPLEX, null, pDevMode) == 1 ? true : false;
		this.supportColor = DeviceCapabilities(toUnicodez(deviceName), "", DC_COLORDEVICE, null, pDevMode) == 1 ? true : false;
		this.landscapeAngle = DeviceCapabilities(toUnicodez(deviceName), "", DC_ORIENTATION, null, pDevMode);
		// this.printToFile =
		// this.printerResolutions =
		// this.paperSizes =
		// this.paperSources =
		// this.isPlotter =
		// this.duplex =

		pDevMode.dmFields |= DM_ORIENTATION;
		pDevMode.dmOrientation = this.defaultPageSettings.landscape ? DMORIENT_LANDSCAPE : DMORIENT_PORTRAIT;

		pDevMode.dmFields |= DM_DUPLEX;
		if (pDevMode.dmDuplex == DMDUP_SIMPLEX)
			this.duplex = Duplex.SIMPLEX;
		else if (pDevMode.dmDuplex == DMDUP_HORIZONTAL)
			this.duplex = Duplex.HORIZONTAL;
		else if (pDevMode.dmDuplex == DMDUP_VERTICAL)
			this.duplex = Duplex.VERTICAL;
		else
			this.duplex = Duplex.DEFAULT;
	}

	///
	void setHdevnames(HGLOBAL hDevNames)
	{
		DEVNAMES* pDevNames = cast(DEVNAMES*)GlobalLock(hDevNames);
		scope(exit)
			GlobalUnlock(pDevNames);

		string deviceName = fromUnicodez(cast(wchar*)(cast(ubyte*)pDevNames + pDevNames.wDeviceOffset * wchar.sizeof));
		this.printerName = deviceName;

		/// Example codes.
		// string driverName = fromUnicodez(cast(wchar*)(cast(ubyte*)pDevNames + pDevNames.wDriverOffset * wchar.sizeof));
		// string outputPort = fromUnicodez(cast(wchar*)(cast(ubyte*)pDevNames + pDevNames.wOutputOffset * wchar.sizeof));
		// bool isDefaultPrinter = pDevNames.wDefault == DN_DEFAULTPRN ? true : false;
	}

	///
	override string toString() const
	{
		string str = "[";
		str ~= "printerName: " ~ printerName ~ ", ";
		str ~= "printFileName: " ~ printFileName ~ ", ";
		str ~= "copies: " ~ to!string(copies) ~ ", ";
		str ~= "maximumPage: " ~ to!string(maximumPage) ~ ", ";
		str ~= "minimumPage: " ~ to!string(minimumPage) ~ ", ";
		str ~= "printRange: " ~ to!string(printRange) ~ ", ";
		str ~= "collate: " ~ to!string(collate) ~ ", ";
		str ~= "maximumCopies: " ~ to!string(maximumCopies) ~ ", ";
		str ~= "canDuplex: " ~ to!string(canDuplex) ~ ", ";
		str ~= "supportColor: " ~ to!string(supportColor) ~ ", ";
		str ~= "landscapeAngle: " ~ to!string(landscapeAngle) ~ ", ";
		str ~= "printToFile: " ~ to!string(printToFile) ~ ", ";
		str ~= "printerResolutions: " ~ to!string(printerResolutions) ~ ", ";
		str ~= "paperSizes: " ~ to!string(paperSizes) ~ ", ";
		str ~= "paperSources: " ~ to!string(paperSources) ~ ", ";
		str ~= "duplex: " ~ to!string(duplex) ~ ", ";
		str ~= "isPlotter: " ~ to!string(isPlotter) ~ ", ";
		str ~= "defaultPageSettings: " ~ to!string(_defaultPageSettings) ~ "]";
		return str;
	}
}

///
enum PrinterResolutionKind
{
	CUSTOM = 0,
	DRAFT = -1,
	HIGH = -4,
	LOW = -2,
	MEDIUM = -3,
}

///
class PrinterResolution
{
	PrinterResolutionKind kind;
	int x; /// Horizontal resolution with dpi unit
	int y; /// Vertical resolution with dpi unit

	///
	this(PrinterResolutionKind kind, int x, int y)
	{
		this.kind = kind;
		this.x = x;
		this.y = y;
	}

	///
	override string toString() const
	{
		string str = "[";
		str ~= "kind: " ~ to!string(kind) ~ ", ";
		str ~= "x: " ~ to!string(x) ~ ", ";
		str ~= "y: " ~ to!string(y) ~ "]";
		return str;
	}
}

///
class PaperSize
{
	private PaperKind _kind;
	private string _paperName;
	private int _width; /// Paper width with 1/100 inch unit.
	private int _height; /// Paper height with 1/100 inch unit.
	// private int _rawKind;

	///
	this(PaperKind kind, string name, int w, int h)
	{
		_kind = kind;
		_paperName = name;
		_width = w;
		_height = h;
	}

	///
	PaperKind kind() const // getter
	{
		return _kind;
	}

	///
	void paperName(string name) // setter
	{
		_paperName = name;
	}
	/// ditto
	string paperName() const // getter
	{
		return _paperName;
	}

	/// Paper height with 1/100 inch unit.
	void height(int h) // setter
	{
		_height = h;
	}
	/// ditto
	int height() const // getter
	{
		return _height;
	}

	/// Paper width with 1/100 inch unit.
	void width(int w) // setter
	{
		_width = w;
	}
	/// ditto
	int width() const // getter
	{
		return _width;
	}

	///
	// void rawKind(int kind) // setter
	// {
	// }
	// int rawKind() const // getter
	// {
	// }

	override string toString() const
	{
		string str = "[";
		str ~= "kind: " ~ to!string(_kind) ~ ", ";
		str ~= "paperName: " ~ to!string(_paperName) ~ ", ";
		str ~= "width: " ~ to!string(_width) ~ ", ";
		str ~= "height: " ~ to!string(_height) ~ "]";
		return str;
	}
}

///
class PageSettings
{
	private bool _color;
	private bool _landscape;
	private PaperSize _paperSize;
	private PaperSource _paperSource;
	private PrinterResolution _printerResolution;
	private Margins _margins = new Margins();
	private float _hardMarginX;
	private float _hardMarginY;
	private RectF _printableArea;
	private PrinterSettings _printerSettings;

	///
	this()
	{
		this(new PrinterSettings());
	}
	/// ditto
	this(PrinterSettings printerSettings)
	{
		_printerSettings = printerSettings;

		_color = _printerSettings.defaultPageSettings.color;
		_landscape = _printerSettings.defaultPageSettings.landscape;
		_paperSize = _printerSettings.defaultPageSettings.paperSize;
		_paperSource = _printerSettings.defaultPageSettings.paperSource;
		_printerResolution = _printerSettings.defaultPageSettings.printerResolution;
	}
	/// ditto
	private this(PrinterSettings printerSettings, bool color, bool landscape,
		PaperSize paperSize, PaperSource paperSource, PrinterResolution printerResolution)
	{
		_printerSettings = printerSettings;

		_color = color;
		_landscape = landscape;
		_paperSize = paperSize;
		_paperSource = paperSource;
		_printerResolution = printerResolution;
	}

	///
	PageSettings clone()
	{
		PageSettings p = new PageSettings();
		p._color = this.color;
		p._landscape = this.landscape;
		p._paperSize = new PaperSize(this.paperSize.kind, this.paperSize.paperName, this.paperSize.width, this.paperSize.height);
		p._paperSource = new PaperSource(this.paperSource.kind, this.paperSource.sourceName);
		p._printerResolution = new PrinterResolution(this.printerResolution.kind, this.printerResolution.x, this.printerResolution.y);
		p._margins = new Margins(this.margins.left, this.margins.top, this.margins.right, this.margins.bottom);
		p._hardMarginX = this.hardMarginX;
		p._hardMarginY = this.hardMarginY;
		p._printableArea = this.printableArea;
		p._printerSettings = this.printerSettings;
		return p;
	}

	/// 1/100 inch unit.
	Rect bounds() // getter
	in
	{
		assert(this.paperSize);
		assert(this.margins);
	}
	body
	{
		int width = this.paperSize.width - this.margins.left - this.margins.right;
		int height = this.paperSize.height - this.margins.top - this.margins.bottom;
		assert(width >= 0);
		assert(height >= 0);
		if (this.landscape)
		{
			// swap
			int tmp = width;
			width = height;
			height = tmp;
		}
		return Rect(this.margins.left, this.margins.top, width, height);
	}

	///
	void color(bool c) // setter
	{
		_color = c;
	}
	/// ditto
	bool color() const // getter
	{
		return _color;
	}

	///
	float hardMarginX() const // getter
	{
		return _hardMarginX;
	}
	/// ditto
	float hardMarginY() const // getter
	{
		return _hardMarginY;
	}

	///
	void landscape(bool l) // setter
	{
		_landscape = l;
	}
	/// ditto
	bool landscape() // getter
	{
		return _landscape;
	}

	///
	void margins(Margins m) // setter
	{
		_margins = m;
	}
	/// ditto
	Margins margins() // getter
	{
		return _margins;
	}

	///
	void paperSize(PaperSize p) // setter
	{
		_paperSize = p;
	}
	/// ditto
	PaperSize paperSize() // getter
	{
		return _paperSize;
	}

	///
	void paperSource(PaperSource p) // setter
	{
		_paperSource = p;
	}
	/// ditto
	PaperSource paperSource() // getter
	{
		return _paperSource;
	}

	///
	RectF printableArea() const // getter
	{
		return _printableArea;
	}

	///
	void printerResolution(PrinterResolution p) // setter
	{
		_printerResolution = p;
	}
	/// ditto
	PrinterResolution printerResolution() // getter
	{
		return _printerResolution;
	}

	///
	void printerSettings(PrinterSettings p) // setter
	{
		_printerSettings = p;
	}
	/// ditto
	PrinterSettings printerSettings() // getter
	{
		return _printerSettings;
	}

	///
	// void copyToHdevmode(HGLOBAL hDevMode)
	// {
	// 	throw new DflException("DFL: copyToHdevmode is not implemented yet."); // TODO: Implememt?
	// }

	///
	void setHdevmode(HGLOBAL hDevMode)
	{
		DEVMODE* pDevMode = cast(DEVMODE*)GlobalLock(hDevMode);
		scope(exit)
			GlobalUnlock(pDevMode);

		switch (pDevMode.dmColor)
		{
			case DMCOLOR_COLOR:
				_color = true;
				break;
			case DMCOLOR_MONOCHROME:
				_color = false;
				break;
			default:
				assert(0);
		}

		switch (pDevMode.dmOrientation)
		{
			case DMORIENT_PORTRAIT:
				_landscape = false;
				break;
			case DMORIENT_LANDSCAPE:
				_landscape = true;
				break;
			default:
				assert(0);
		}

		_paperSource = _createPaperSource(hDevMode);
		_paperSize = _createPaperSize(hDevMode);
		_printerResolution = _createPrinterResolution(hDevMode);

		// TODO
		// _margins =
		// _hardMarginX =
		// _hardMarginY =
		// _printableArea =
	}

	///
	private PaperSource _createPaperSource(HGLOBAL hDevMode)
	{
		DEVMODE* pDevMode = cast(DEVMODE*)GlobalLock(hDevMode);
		scope(exit)
			GlobalUnlock(pDevMode);
		
		// Get printer name.
		string deviceName = fromUnicodez(pDevMode.dmDeviceName.ptr);

		// Get default paper source kind.
		PaperSourceKind sourceKind = {
			if (pDevMode.dmDefaultSource <= DMBIN_LAST) // System defined paper source.
				return cast(PaperSourceKind)pDevMode.dmDefaultSource;
			else if (pDevMode.dmDefaultSource >= DMBIN_USER) // User defined paper source.
				return PaperSourceKind.CUSTOM;
			else
				assert(0);
		}();

		// Get number of paper sources.
		int sourceNum = DeviceCapabilities(toUnicodez(deviceName), "", DC_BINS, null, pDevMode);
		WORD[] sourceBuffer = new WORD[sourceNum];
		DeviceCapabilities(toUnicodez(deviceName), "", DC_BINS, cast(wchar*)sourceBuffer.ptr, pDevMode);
		WORD[] sourceList;
		for (int i = 0; i < sourceNum; i++)
			sourceList ~= sourceBuffer[i];

		// Get name of paper sources.
		enum BINNAME_MAX_LENGTH = 24;
		wchar[] sourceNamesBuffer = new wchar[BINNAME_MAX_LENGTH * sourceNum];
		// for(int i = 0; i < BINNAME_MAX_LENGTH * sourceNum; i++) // TODO: Remove?
		// 	sourceNamesBuffer[i] = 0;
		DeviceCapabilities(toUnicodez(deviceName), "", DC_BINNAMES, sourceNamesBuffer.ptr, pDevMode);
		// Reference: https://learn.microsoft.com/en-us/windows/win32/api/wingdi/nf-wingdi-devicecapabilitiesw
		// Value: DC_BINNAMES
		// Meaning: Retrieves the names of the printer's paper bins.
		//          The pOutput buffer receives an array of string buffers.
		//          Each string buffer is 24 characters long and contains the name of a paper bin.
		//          The return value indicates the number of entries in the array.
		//          The name strings are null-terminated unless the name is 24 characters long.
		//          If pOutput is NULL, the return value is the number of bin entries required.
		wstring[] sourceNameList;
		for (int i = 0; i < sourceNum; i++)
		{
			wchar* w = cast(wchar*)(cast(ubyte*)sourceNamesBuffer + i * BINNAME_MAX_LENGTH * wchar.sizeof);
			int end = -1;
			for (int j = 0; j < BINNAME_MAX_LENGTH; j++)
			{
				if (w[j] == '\0')
				{
					end = j;
					break;
				}
			}
			if (end == -1) // Null terminal is not found.
				sourceNameList ~= w[0..BINNAME_MAX_LENGTH].dup; // TODO: Is it correct?
			else
				sourceNameList ~= w[0..end].dup; // Contains null terminal.
		}

		// Get paper source name.
		// Search index of paper source.
		wstring sourceName = {
			int index = -1;
			for (int i = 0; i < sourceNum; i++)
			{
				if (sourceList[i] == pDevMode.dmDefaultSource)
				{
					index = i;
					break;
				}
			}
			if (index != -1)
				return sourceNameList[index];
			else
				return "no name"w;
		}();
		
		return new PaperSource(sourceKind, to!string(sourceName));
	}

	/// Create PaperSize object.
	private PaperSize _createPaperSize(HGLOBAL hDevMode)
	{
		DEVMODE* pDevMode = cast(DEVMODE*)GlobalLock(hDevMode);
		scope(exit)
			GlobalUnlock(pDevMode);
		
		string deviceName = fromUnicodez(pDevMode.dmDeviceName.ptr);
		short selectedPaperSize = pDevMode.dmPaperSize; // ex) A4 size is DMPAPER_A4 (9).

		int sizeNum = DeviceCapabilities(toUnicodez(deviceName), "", DC_PAPERSIZE, null, pDevMode);
		POINT[] sizeBuffer = new POINT[sizeNum]; // 1/10 mm unit.
		DeviceCapabilities(toUnicodez(deviceName), "", DC_PAPERSIZE, cast(wchar*)sizeBuffer.ptr, pDevMode);

		int paperNum = DeviceCapabilities(toUnicodez(deviceName), "", DC_PAPERS, null, pDevMode);
		WORD[] paperBuffer = new WORD[paperNum];
		DeviceCapabilities(toUnicodez(deviceName), "", DC_PAPERS, cast(wchar*)paperBuffer.ptr, pDevMode);
		int index = -1;
		for (int i = 0; i < paperNum; i++)
		{
			if (paperBuffer[i] == selectedPaperSize)
			{
				index = i;
				break;
			}
		}
		if (index == -1)
			assert(0);
		
		Size size = {
			if (selectedPaperSize == 0 || selectedPaperSize >= DMPAPER_USER)
			{
				// User defined paper size.
				return Size(pDevMode.dmPaperWidth, pDevMode.dmPaperLength); // 1/100 mm unit
			}
			else
			{
				// System defined paper size.
				return Size(sizeBuffer[index].x, sizeBuffer[index].y); // 1/100 mm unit
			}
		}();

		PaperKind paperKind = cast(PaperKind)selectedPaperSize;
		string paperName = fromUnicodez(pDevMode.dmFormName.ptr);
		int width = cast(int)(size.width / 2.54); // Convert to 1/100 inch unit.
		int height = cast(int)(size.height / 2.54); // Convert to 1/100 inch unit.
		return new PaperSize(paperKind, paperName, width, height);
	}

	///
	private PrinterResolution _createPrinterResolution(HGLOBAL hDevMode)
	{
		DEVMODE* pDevMode = cast(DEVMODE*)GlobalLock(hDevMode);
		scope(exit)
			GlobalUnlock(pDevMode);
		
		string deviceName = fromUnicodez(pDevMode.dmDeviceName.ptr);
		int printQuality = pDevMode.dmPrintQuality;

		int dpiX;
		int dpiY;
		if (pDevMode.dmFields & DM_YRESOLUTION)
		{
			assert(pDevMode.dmPrintQuality > 0);
			dpiX = pDevMode.dmPrintQuality; // dpi unit.
			dpiY = pDevMode.dmYResolution; // dpi unit.
		}
		else
		{
			int resolutionNum = DeviceCapabilities(toUnicodez(deviceName), "", DC_ENUMRESOLUTIONS, null, pDevMode);
			if (resolutionNum < 0)
			{
				// Device is not support to get printer resolutions.
				dpiX = 0;
				dpiY = 0;
			}
			else
			{
				SIZE[] resolutionBuffer = new SIZE[resolutionNum];
				DeviceCapabilities(toUnicodez(deviceName), "", DC_ENUMRESOLUTIONS, cast(wchar*)resolutionBuffer.ptr, pDevMode);
				// debug msgBox(to!string(resolutionBuffer));
				int index = -1;
				for (int i = 0; i < resolutionNum; i++)
				{
					if (resolutionBuffer[i].cx == pDevMode.dmPrintQuality && resolutionBuffer[i].cy == pDevMode.dmYResolution)
					{
						index = i;
						break;
					}
				}
				if (index == -1)
					assert(0);
				dpiX = resolutionBuffer[index].cx; // dpi unit.
				dpiY = resolutionBuffer[index].cy; // dpi unit.
			}
		}
		
		PrinterResolutionKind kind = {
			if (pDevMode.dmPrintQuality < 0)
				return cast(PrinterResolutionKind)pDevMode.dmPrintQuality;
			else
				return PrinterResolutionKind.CUSTOM;
		}();

		return new PrinterResolution(kind, dpiX, dpiY);
	}
	
	///
	override string toString() const
	{
		string str = "[";
		str ~= "color: " ~ to!string(_color) ~ ", ";
		str ~= "landscape: " ~ to!string(_landscape) ~ ", ";
		str ~= "paperSize: " ~ to!string(_paperSize) ~ ", ";
		str ~= "paperSource: " ~ to!string(_paperSource) ~ ", ";
		str ~= "printerResolution: " ~ to!string(_printerResolution) ~ ", ";
		str ~= "margins: " ~ to!string(_margins) ~ ", ";
		str ~= "hardMarginX: " ~ to!string(_hardMarginX) ~ ", ";
		str ~= "hardMarginY: " ~ to!string(_hardMarginY) ~ ", ";
		str ~= "printableArea: " ~ to!string(_printableArea) ~ ", ";
		str ~= "printerSettings: " ~ /+to!string(_printerSettings)+/"***" ~ "]";
		return str;
	}
}

/// Paper margins (1/100 inch unit.)
class Margins
{
	int left; /// Left margin With 1/100 inch unit.
	int top; /// Top margin With 1/100 inch unit.
	int right; /// Right margin With 1/100 inch unit.
	int bottom; /// Bottom margin With 1/100 inch unit.

	///
	this()
	{
		left = top = right = bottom = 100; // 1 inch. 1/100 inch unit. 
	}
	/// ditto
	this(int left, int top, int right, int bottom)
	{
		this.left = left;
		this.top = top;
		this.right = right;
		this.bottom = bottom;
	}

	///
	override string toString() const
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
struct PointF
{
	float x, y;
}

///
struct SizeF
{
	float width, height;
}

///
struct RectF
{
	float x, y, width, height;

	///
	this(PointF p, SizeF s)
	{
		x = p.x;
		y = p.y;
		width = s.width;
		height = s.height;
	}
	/// ditto
	this(float x, float y, float width, float height)
	{
		this.x = x;
		this.y = y;
		this.width = width;
		this.height = height;
	}
}

///
final class PrintDialog : CommonDialog
{
	private PRINTDLGEX _printDialog;
	private PRINTPAGERANGE[10] _printPageRange; // The number of elements is 10 if page range is "1,2-3,4,5-6,7,8,9,10,11,12".
	private PrintDocument _document;

	bool allowCurrentPage;
	bool allowPrintToFile;
	bool allowSelection;
	bool allowSomePages;
	bool canRaiseEvents;
	bool printToFile;
	bool showHelp;
	bool showNetwork;

	///
	this(PrintDocument document)
	{
		reset();
		this.document = document;
	}

	///
	override void reset()
	{
		document = null;

		allowCurrentPage = false;
		allowPrintToFile = true;
		allowSelection = false;
		allowSomePages = false;
		canRaiseEvents = true;
		printToFile = false;
		showHelp = false;
		showNetwork = true;
	}

	///
	void document(PrintDocument doc)
	{
		_document = doc;
	}
	/// ditto
	PrintDocument document()
	{
		return _document;
	}

	///
	override DialogResult showDialog()
	{
		bool resultOK = runDialog(GetActiveWindow());
		if (resultOK)
			return DialogResult.OK;
		else
			return DialogResult.CANCEL;
	}

	///
	override DialogResult showDialog(IWindow owner)
	{
		bool resultOK = runDialog(owner ? owner.handle : GetActiveWindow());
		if (resultOK)
			return DialogResult.OK;
		else
			return DialogResult.CANCEL;
	}

	///
	override bool runDialog(HWND owner)
	{
		if (!this.document)
			throw new DflException("DFL: Called PrintDialog.showDialog() without PrintDocument.");

		_printDialog.lStructSize = _printDialog.sizeof;
		_printDialog.hwndOwner = owner;
		_printDialog.hDevMode = null;
		_printDialog.hDevNames = null;
		_printDialog.hDC = null;
		_printDialog.Flags = PD_USEDEVMODECOPIESANDCOLLATE | PD_RETURNDC;
		_printDialog.nCopies = 1;
		_printDialog.nMaxPageRanges = _printPageRange.length;
		_printDialog.lpPageRanges = _printPageRange.ptr;
		_printDialog.nMinPage = 1;
		_printDialog.nMaxPage = 0xffff;
		_printDialog.nStartPage = START_PAGE_GENERAL;

		scope(exit)
		{
			_printDialog = PRINTDLGEX.init;
			if (_printDialog.hDevMode)
				GlobalFree(_printDialog.hDevMode);
			if (_printDialog.hDevNames)
				GlobalFree(_printDialog.hDevNames);
			if (_printDialog.hDC)
				DeleteDC(_printDialog.hDC);
		}

		// You must free hDevMode, hDevNames and hDC if dialog succeded.
		HRESULT hr = PrintDlgEx(&_printDialog);
		if (hr == E_OUTOFMEMORY)
		{
			debug msgBox("PrintDlgEx is failure: E_OUTOFMEMORY");
			return false;
		}
		else if (hr == E_INVALIDARG)
		{
			debug msgBox("PrintDlgEx is failure: E_INVALIDARG");
			return false;
		}
		else if (hr == E_POINTER)
		{
			debug msgBox("PrintDlgEx is failure: E_POINTER");
			return false;
		}
		else if (hr == E_HANDLE)
		{
			debug msgBox("PrintDlgEx is failure: E_HANDLE");
			return false;
		}
		else if (hr == E_FAIL)
		{
			debug msgBox("PrintDlgEx is failure: E_FAIL");
			return false;
		}
		else if (hr != S_OK)
			assert(0);

		if (_printDialog.dwResultAction == PD_RESULT_CANCEL)
			return false;
		
		// Short name.
		PrinterSettings printer = document.printerSettings;
		PageSettings page = printer.defaultPageSettings;

		// Load printer settings from dialog parameters.
		printer.setHdevnames(_printDialog.hDevNames);
		printer.setHdevmode(_printDialog.hDevMode);
		HDC hdc = {
			DEVMODE* pDevMode = cast(DEVMODE*)GlobalLock(_printDialog.hDevMode);
			scope(exit)
				GlobalUnlock(pDevMode);
			return ResetDC(_printDialog.hDC, pDevMode);
		}();

		// Get print page range.
		if (_printDialog.Flags & PD_PAGENUMS)
		{
			printer.printRange.kind = PrintRangeKind.SOME_PAGES;
			printer.printRange.reset();
			for (int i = 0; i < _printDialog.nPageRanges; i++)
			{
				int from = _printPageRange[i].nFromPage;
				int to = _printPageRange[i].nToPage;
				printer.printRange.addPrintRange(PrintRange(from, to));
			}
		}
		else if (_printDialog.Flags & PD_SELECTION)
		{
			printer.printRange.kind = PrintRangeKind.SELECTION;
			// Don't override Print Range here.
		}
		else if (_printDialog.Flags & PD_CURRENTPAGE)
		{
			printer.printRange.kind = PrintRangeKind.CURRENT_PAGE;
			// Don't override Print Range here.
		}
		else // PD_ALLPAGES == 0x00000000
		{
			printer.printRange.kind = PrintRangeKind.ALL_PAGES;
			// Don't override Print Range here.
		}

		// Get printer resolution.
		int dpiX = GetDeviceCaps(hdc, LOGPIXELSX);
		int dpiY = GetDeviceCaps(hdc, LOGPIXELSY);
		page.printerResolution.x = dpiX;
		page.printerResolution.y = dpiY;

		// TODO: Move to far.
		int hardMarginLeft = GetDeviceCaps(hdc, PHYSICALOFFSETX);
		int hardMarginTop = GetDeviceCaps(hdc, PHYSICALOFFSETX);
		page._hardMarginX = hardMarginLeft;
		page._hardMarginY = hardMarginTop;

		//
		printer.isPlotter = GetDeviceCaps(hdc, TECHNOLOGY) == DT_PLOTTER ? true : false;

		// TODO: Move to far.
		int physWidth = GetDeviceCaps(hdc, PHYSICALWIDTH); // inch x dpi
		int physHeight = GetDeviceCaps(hdc, PHYSICALHEIGHT); // inch x dpi
		float printableWidth = physWidth * 100.0 / dpiX; // 1/100 inch unit.
		float printableHeight = physHeight * 100.0 / dpiY; // 1/100 inch unit.
		page._printableArea = RectF(hardMarginLeft, hardMarginTop, printableWidth, printableHeight);

		if (_printDialog.dwResultAction == PD_RESULT_APPLY)
		{
			return false;
		}
		else if (_printDialog.dwResultAction == PD_RESULT_PRINT)
		{
			this.document.print(hdc);
			return true;
		}
		else
		{
			assert(0);
		}
	}
}

///
final class PageSetupDialog : CommonDialog
{
	private PAGESETUPDLG _pageSetupDlg;

	private PrintDocument _document;
	
	private bool _allowMargins;
	private bool _allowOrientation;
	private bool _allowPaper;
	private bool _allowPrinter;
	// private bool _enableMetric; // TODO: Implement
	private Margins _minMargins;
	private bool _showHelp;
	private bool _showNetwork;

	///
	this(PrintDocument document)
	{
		reset();
		this._document = document;
	}

	///
	override void reset()
	{
		_pageSetupDlg.Flags = PSD_INHUNDREDTHSOFMILLIMETERS;

		_document = null;

		allowMargins = true;
		allowOrientation = true;
		allowPaper = true;
		allowPrinter = true;
		minMargins = null;
		showHelp = false;
		showNetwork = true;
	}

	///
	void showNetwork(bool byes) // setter
	{
		enum PSD_NONETOWRKBUTTON = 0x00200000;
		_showNetwork = byes;
		if (_showNetwork)
			_pageSetupDlg.Flags |= PSD_NONETOWRKBUTTON;
		else
			_pageSetupDlg.Flags &= ~PSD_NONETOWRKBUTTON;
	}
	/// ditto
	bool showNetwork() // getter
	{
		return _showNetwork;
	}

	///
	void showHelp(bool byes) // setter
	{
		_showHelp = byes;
		if (_showHelp)
			_pageSetupDlg.Flags |= PSD_SHOWHELP;
		else
			_pageSetupDlg.Flags &= ~PSD_SHOWHELP;
	}
	/// ditto
	bool showHelp() // getter
	{
		return _showHelp;
	}

	///
	void minMargins(Margins m) // setter
	{
		_minMargins = m;
		if (_minMargins)
		{
			_pageSetupDlg.Flags |= PSD_MINMARGINS; // Use user defined min-margins.
			// _minMargins is 1/100 inch unit, but rtMinMargin is 1/1000 mm unit.
			_pageSetupDlg.rtMinMargin.left = _mmFromInch(_minMargins.left);
			_pageSetupDlg.rtMinMargin.top = _mmFromInch(_minMargins.top);
			_pageSetupDlg.rtMinMargin.right = _mmFromInch(_minMargins.right);
			_pageSetupDlg.rtMinMargin.bottom = _mmFromInch(_minMargins.bottom);
		}
		else
		{
			_pageSetupDlg.Flags &= ~PSD_MINMARGINS; // Use system defined min-margins.
		}
	}
	/// ditto
	Margins minMargins() // getter
	{
		return _minMargins;
	}

	// TODO: Implement
	// void enableMetric(bool byes) // setter
	// {
	// 	// ...
	// }
	// bool enableMetric() // getter
	// {
	// 	return _enableMetric;
	// }

	///
	void allowPrinter(bool byes) // setter
	{
		_allowPrinter = byes;
		if (_allowPrinter)
			_pageSetupDlg.Flags &= ~PSD_DISABLEPRINTER;
		else
			_pageSetupDlg.Flags |= PSD_DISABLEPRINTER;
	}
	/// ditto
	bool allowPrinter() // getter
	{
		return _allowPrinter;
	}

	///
	void allowPaper(bool byes) // setter
	{
		_allowPaper = byes;
		if (_allowPaper)
			_pageSetupDlg.Flags &= ~PSD_DISABLEPAPER;
		else
			_pageSetupDlg.Flags |= PSD_DISABLEPAPER;
	}
	/// ditto
	bool allowPaper() // getter
	{
		return _allowPaper;
	}

	///
	void allowOrientation(bool byes) // setter
	{
		_allowOrientation = byes;
		if (_allowOrientation)
			_pageSetupDlg.Flags &= ~PSD_DISABLEORIENTATION;
		else
			_pageSetupDlg.Flags |= PSD_DISABLEORIENTATION;
	}
	/// ditto
	bool allowOrientation() // getter
	{
		return _allowOrientation;
	}

	///
	void allowMargins(bool byes) // setter
	{
		_allowMargins = byes;
		if (_allowMargins)
			_pageSetupDlg.Flags &= ~PSD_DISABLEMARGINS;
		else
			_pageSetupDlg.Flags |= PSD_DISABLEMARGINS;
	}
	/// ditto
	bool allowMargins() // getter
	{
		return _allowMargins;
	}

	///
	void document(PrintDocument document) // setter
	{
		_document = document;
	}
	/// ditto
	PrintDocument document() // getter
	{
		return _document;
	}

	///
	override DialogResult showDialog()
	{
		bool resultOK = runDialog(GetActiveWindow());
		if (resultOK)
			return DialogResult.OK;
		else
			return DialogResult.CANCEL;
	}

	///
	override DialogResult showDialog(IWindow owner)
	{
		bool resultOK = runDialog(owner ? owner.handle : GetActiveWindow());
		if (resultOK)
			return DialogResult.OK;
		else
			return DialogResult.CANCEL;
	}

	///
	override bool runDialog(HWND owner)
	{
		_pageSetupDlg.lStructSize = _pageSetupDlg.sizeof;
		_pageSetupDlg.hwndOwner = owner;
		_pageSetupDlg.hDevMode = null;
		_pageSetupDlg.hDevNames = null;
		_pageSetupDlg.lpfnPagePaintHook = null;

		// Set initial margins.
		if (document.printerSettings.defaultPageSettings && document.printerSettings.defaultPageSettings.margins)
		{
			// margins is 1/100 dpi unit, but rtMargin is 1/1000 mm unit.
			_pageSetupDlg.rtMargin.left = _mmFromInch(document.printerSettings.defaultPageSettings.margins.left);
			_pageSetupDlg.rtMargin.top = _mmFromInch(document.printerSettings.defaultPageSettings.margins.top);
			_pageSetupDlg.rtMargin.right = _mmFromInch(document.printerSettings.defaultPageSettings.margins.right);
			_pageSetupDlg.rtMargin.bottom = _mmFromInch(document.printerSettings.defaultPageSettings.margins.bottom);
			_pageSetupDlg.Flags |= PSD_MARGINS;
		}
		else
			_pageSetupDlg.Flags &= ~PSD_MARGINS;

		scope(exit)
		{
			_pageSetupDlg = PAGESETUPDLG.init;

			if (_pageSetupDlg.hDevMode)
				GlobalFree(_pageSetupDlg.hDevMode);
			if (_pageSetupDlg.hDevNames)
				GlobalFree(_pageSetupDlg.hDevNames);
		}
		
		// You must free hDevMode and hDevNames if dialog succeded.
		BOOL resultOK = PageSetupDlg(&_pageSetupDlg);
		if (resultOK)
		{
			document.printerSettings.setHdevnames(_pageSetupDlg.hDevNames);
			document.printerSettings.defaultPageSettings.setHdevmode(_pageSetupDlg.hDevMode);

			// rtMargin is 1/1000 mm unit, but margins is 1/100 inch unit.
			document.printerSettings.defaultPageSettings.margins = new Margins(
				_inchFromMm(_pageSetupDlg.rtMargin.left),
				_inchFromMm(_pageSetupDlg.rtMargin.top),
				_inchFromMm(_pageSetupDlg.rtMargin.right),
				_inchFromMm(_pageSetupDlg.rtMargin.bottom));
			
			// rtMinMargin is 1/1000 mm unit, but _minMargins is 1/100 inch unit.
			_minMargins = new Margins(
				_inchFromMm(_pageSetupDlg.rtMinMargin.left),
				_inchFromMm(_pageSetupDlg.rtMinMargin.top),
				_inchFromMm(_pageSetupDlg.rtMinMargin.right),
				_inchFromMm(_pageSetupDlg.rtMinMargin.bottom));
			
			return true;
		}
		else
		{
			return false;
		}
	}
}
