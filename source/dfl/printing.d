// printing.d
//
// Written by haru-s/Rayerd in 2024.

/// 
module dfl.printing;

pragma(lib, "WinSpool");

private import dfl.base;
private import dfl.commondialog;
private import dfl.drawing;
private import dfl.event;
private import dfl.messagebox;
private import dfl.control;
private import dfl.form;
private import dfl.toolbar;
private import dfl.imagelist;
private import dfl.panel;
private import dfl.label;
private import dfl.button;
private import dfl.textbox;

private import dfl.internal.utf;

private import core.sys.windows.commdlg;
private import core.sys.windows.windows;

private import std.conv;
private import std.range;
private import std.algorithm;

///
enum PrinterUnit
{
	DISPLAY = 0, // The default unit (0.01 inch).
	HUNDREDTHS_OF_AN_INCH = 0, // ditto.
	THOUSANDTHS_OF_AN_INCH = 1, // One-thousandth of an inch (0.001 inch).
	HUNDREDTHS_OF_A_MILLIMETER = 2, // One-hundredth of a millimeter (0.01 mm).
	TENTHS_OF_A_MILLIMETER = 3, // One-tenth of a millimeter (0.1 mm).
	THOUSANDTHS_OF_A_MILLIMETER = 4, // One-thousandth of an millimeter (0.001 mm).
}

///
final static class PrinterUnitConvert
{
	///
	static double convert(double value, PrinterUnit fromUnit, PrinterUnit toUnit)
	{
		double from = unitsPerDisplay(fromUnit);
		double to = unitsPerDisplay(toUnit);
		return value * to / from;
	}

	/// ditto
	static int convert(int value, PrinterUnit fromUnit, PrinterUnit toUnit)
	{
		double from = unitsPerDisplay(fromUnit);
		double to = unitsPerDisplay(toUnit);
		return cast(int)(value * to / from);
	}

	/// ditto
	static Margins convert(Margins value, PrinterUnit fromUnit, PrinterUnit toUnit)
	{
		return new Margins(
			convert(value.left, fromUnit, toUnit),
			convert(value.top, fromUnit, toUnit),
			convert(value.right, fromUnit, toUnit),
			convert(value.bottom, fromUnit, toUnit)
		);
	}

	/// ditto
	static Point convert(Point value, PrinterUnit fromUnit, PrinterUnit toUnit)
	{
		return Point(
			convert(value.x, fromUnit, toUnit),
			convert(value.y, fromUnit, toUnit)
		);
	}

	/// ditto
	static POINT convert(POINT value, PrinterUnit fromUnit, PrinterUnit toUnit)
	{
		return POINT(
			convert(value.x, fromUnit, toUnit),
			convert(value.y, fromUnit, toUnit)
		);
	}

	/// ditto
	static Rect convert(Rect value, PrinterUnit fromUnit, PrinterUnit toUnit)
	{
		return Rect(
			convert(value.x, fromUnit, toUnit),
			convert(value.y, fromUnit, toUnit),
			convert(value.width, fromUnit, toUnit),
			convert(value.height, fromUnit, toUnit)
		);
	}

	/// ditto
	static RECT convert(RECT value, PrinterUnit fromUnit, PrinterUnit toUnit)
	{
		return RECT(
			convert(value.left, fromUnit, toUnit),
			convert(value.top, fromUnit, toUnit),
			convert(value.right, fromUnit, toUnit),
			convert(value.bottom, fromUnit, toUnit)
		);
	}

	/// ditto
	static Size convert(Size value, PrinterUnit fromUnit, PrinterUnit toUnit)
	{
		return Size(
			convert(value.width, fromUnit, toUnit),
			convert(value.height, fromUnit, toUnit)
		);
	}

	/// ditto
	static SIZE convert(SIZE value, PrinterUnit fromUnit, PrinterUnit toUnit)
	{
		return SIZE(
			convert(value.cx, fromUnit, toUnit),
			convert(value.cy, fromUnit, toUnit)
		);
	}

	///
	private static double unitsPerDisplay(PrinterUnit unit)
	{
		final switch(unit)
		{
			case PrinterUnit.DISPLAY: // same as PrinterUnit.HUNDREDTHS_OF_AN_INCH.
				return 1.0;
			case PrinterUnit.THOUSANDTHS_OF_AN_INCH:
				return 10.0;
			case PrinterUnit.TENTHS_OF_A_MILLIMETER:
				return 2.54;
			case PrinterUnit.HUNDREDTHS_OF_A_MILLIMETER:
				return 25.4;
			case PrinterUnit.THOUSANDTHS_OF_A_MILLIMETER:
				return 254.0;
		}
	}
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
	CUSTOM = 256,
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
	private int _rawKind;
	private string _sourceName;

	///
	this()
	{
		rawKind = PaperSourceKind.CUSTOM;
		sourceName = "";
	}
	/// ditto
	this(int rawKind, string name)
	{
		this.rawKind = rawKind;
		this.sourceName = name;
	}

	///
	PaperSourceKind kind() const // getter
	{
		return _kind;
	}

	///
	void rawKind(int rawKind) // setter
	{
		_rawKind = rawKind;
		if (rawKind >= PaperSourceKind.CUSTOM)
			_kind = PaperSourceKind.CUSTOM;
		else
			_kind = cast(PaperSourceKind)rawKind;
	}
	/// ditto
	int rawKind() const // getter
	{
		return _rawKind;
	}

	///
	void sourceName(string name) // setter
	{
		_sourceName = name;
	}
	/// ditto
	string sourceName() const // getter
	{
		return _sourceName;
	}

	///
	override string toString() const
	{
		string str = "[";
		str ~= "kind: " ~ to!string(_kind) ~ ", ";
		str ~= "rawKind: " ~ to!string(_rawKind) ~ ", ";
		str ~= "sourceName: " ~ _sourceName ~ "]";
		return str;
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
class PrintRangeEventArgs : EventArgs
{
	PrintRangeSettings printRange;

	///
	this(PrintRangeSettings printRange)
	{
		this.printRange = printRange;
	}
}

///
class PrintEventArgs : EventArgs
{
	bool cancel = false;
	HDC hDC; // TODO: Remove.

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
	Rect marginBounds;
	Rect pageBounds;
	PageSettings pageSettings;
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
class LastPageChangedEventArgs : EventArgs
{
	int lastPage;

	///
	this(int page)
	{
		lastPage = page;
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
interface PrintController
{
	///
	void onStartPrint(PrintDocument document, PrintEventArgs e);

	///
	void onEndPrint(PrintDocument document, PrintEventArgs e);

	///
	Graphics onStartPage(PrintDocument document, PrintPageEventArgs e);

	///
	void onEndPage(PrintDocument document, PrintPageEventArgs e);
}

///
class StandardPrintController : PrintController
{
	///
	override void onStartPrint(PrintDocument document, PrintEventArgs e)
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
		StartDoc(e.hDC, &info);
	}

	///
	override void onEndPrint(PrintDocument document, PrintEventArgs e)
	{
		EndDoc(e.hDC);
	}
	
	///
	override Graphics onStartPage(PrintDocument document, PrintPageEventArgs e)
	{
		StartPage(e.graphics.handle);
		return e.graphics;
	}

	///
	override void onEndPage(PrintDocument document, PrintPageEventArgs e)
	{
		EndPage(e.graphics.handle);
	}
}

class PrintDocument
{
	PrinterSettings printerSettings;
	PrintController printController;
	wstring documentName;
	// bool originAtMargins = false; // TODO: Implement.

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
		// Do not change printRange.kind here!
		PrintRangeEventArgs printPageRangeEventArgs = new PrintRangeEventArgs(this.printerSettings.printRange);
		onPrintRange(printPageRangeEventArgs);

		if (this.printerSettings.printRange.empty)
			throw new DflException("DFL: Print range error.");

		PrintEventArgs printArgs = new PrintEventArgs(hDC);
		onBeginPrint(printArgs);
		if (printArgs.cancel)
			return;

		printController.onStartPrint(this, printArgs); // Call StartDoc() API
		if (printArgs.cancel)
			return;

		Graphics deviceScreen = new Graphics(hDC, false);
		
		PrintPageEventArgs printPageArgs;
		auto walker = new PrintRangeWalker(this.printerSettings.printRange.ranges);
		foreach (int pageCounter; walker)
		{
			PageSettings newPageSettings = this.printerSettings.defaultPageSettings.clone();
			QueryPageSettingsEventArgs queryPageSettingsArgs = new QueryPageSettingsEventArgs(hDC, newPageSettings, pageCounter);
			onQueryPageSettings(queryPageSettingsArgs); // Be modified pageSettings of current page by user.

			PageSettings ps = queryPageSettingsArgs.pageSettings; // Short name.

			// Change page orientation.
			DEVMODE devMode;
			devMode.dmSize = DEVMODE.sizeof;
			devMode.dmFields |= DM_ORIENTATION;
			devMode.dmOrientation |= ps.landscape ? DMORIENT_LANDSCAPE : DMORIENT_PORTRAIT;
			ResetDC(hDC, &devMode);

			Rect marginBounds = ps.bounds; // 1/100 inch unit.
			Rect pageBounds = Rect(0, 0, ps.paperSize.width, ps.paperSize.height); // 1/100 inch unit.
			printPageArgs = new PrintPageEventArgs(deviceScreen, marginBounds, pageBounds, ps, pageCounter);
			printPageArgs.graphics = printController.onStartPage(this, printPageArgs); // Call StartPage() API
			
			if(!printPageArgs.cancel)
				this.onPrintPage(printPageArgs);
			
			printPageArgs.graphics = deviceScreen;

			printController.onEndPage(this, printPageArgs); // Call EndPage() API
			if (printPageArgs.cancel)
				break;
		}

		onEndPrint(printArgs);
		printController.onEndPrint(this, printArgs); // Call EndPrint() API
	}

	///
	void onPrintRange(PrintRangeEventArgs e)
	{
		printRange(this, e);
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
	Event!(PrintDocument, PrintRangeEventArgs) printRange;
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

	///
	string toString() const
	{
		return "(" ~ to!string(fromPage) ~ ", " ~ to!string(toPage) ~ ")";
	}
}

///
class PrintRangeWalker // Forward Range
{
	private int[] _pages;
	private int _index;

	///
	this(const PrintRange[] ranges)
	{
		for (int i = 0; i < ranges.length; i++)
		{
			for (int p = ranges[i].fromPage; p <= ranges[i].toPage; p++)
			{
				_pages ~= p;
			}
		}
	}

	///
	bool empty() const
	{
		return _pages.length <= _index;
	}

	///
	int front() const
	{
		return _pages[_index];
	}

	///
	void popFront()
	{
		_index++;
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
		kind = PrintRangeKind.ALL_PAGES;
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
// Reference: https://learn.microsoft.com/en-us/windows/win32/api/wingdi/nf-wingdi-devicecapabilitiesw
// Value:   DC_BINNAMES
// Meaning: Retrieves the names of the printer's paper bins.
//          The pOutput buffer receives an array of string buffers.
//          Each string buffer is 24 characters long and contains the name of a paper bin.
//          The return value indicates the number of entries in the array.
//          The name strings are null-terminated unless the name is 24 characters long.
//          If pOutput is NULL, the return value is the number of bin entries required.
// Value:   DC_PAPERNAMES
// Meaning: The pOutput parameter points to a buffer that the function should fill with an array of string buffers,
//          each 64 characters in length. Each string buffer in the array should contain a wide-character,
//          NULL-terminated string specifying the name of a paper form.
//          The function's return value should be the number of elements in the returned array.
//          If pOutput is NULL, the function should just return the number of array elements required.
private wstring[] _splitNamesBuffer(wchar[] namesBuffer, int nameNum, int nameMaxLength)
{
	wstring[] nameArray;
	for (int i = 0; i < nameNum; i++)
	{
		wchar* w = cast(wchar*)(cast(ubyte*)namesBuffer + i * nameMaxLength * wchar.sizeof);
		int end = -1;
		for (int j = 0; j < nameMaxLength; j++)
		{
			if (w[j] == '\0')
			{
				end = j;
				break;
			}
		}
		if (end == -1) // Null terminal is not found.
			nameArray ~= w[0..nameMaxLength].dup; // TODO: Is it correct?
		else
			nameArray ~= w[0..end].dup; // Contains null terminal.
	}
	return nameArray;
}

///
private PaperSource[] _createPaperSourceArray(HGLOBAL hDevMode)
{
	DEVMODE* pDevMode = cast(DEVMODE*)GlobalLock(hDevMode);
	scope(exit)
		GlobalUnlock(pDevMode);
	
	// Get printer name.
	string deviceName = fromUnicodez(pDevMode.dmDeviceName.ptr);

	// Get number of paper sources.
	int sourceNum = DeviceCapabilities(toUnicodez(deviceName), "", DC_BINS, null, pDevMode);
	WORD[] sourceKindBuffer = new WORD[sourceNum];
	DeviceCapabilities(toUnicodez(deviceName), "", DC_BINS, cast(wchar*)sourceKindBuffer.ptr, pDevMode);

	// Get name of paper sources.
	enum BINNAME_MAX_LENGTH = 24;
	wchar[] sourceNamesBuffer = new wchar[BINNAME_MAX_LENGTH * sourceNum];
	DeviceCapabilities(toUnicodez(deviceName), "", DC_BINNAMES, sourceNamesBuffer.ptr, pDevMode);
	wstring[] sourceNameArray = _splitNamesBuffer(sourceNamesBuffer, sourceNum, BINNAME_MAX_LENGTH);

	// Return paper sources.
	PaperSource[] ret;
	for (int i; i < sourceNum; i++)
		ret ~= new PaperSource(sourceKindBuffer[i], to!string(sourceNameArray[i]));
	return ret;
}

///
private PaperSize[] _createPaperSizeArray(HGLOBAL hDevMode)
{
	DEVMODE* pDevMode = cast(DEVMODE*)GlobalLock(hDevMode);
	scope(exit)
		GlobalUnlock(pDevMode);
	
	// Get printer name.
	string deviceName = fromUnicodez(pDevMode.dmDeviceName.ptr);

	// Get number of printer sizes.
	int paperSizeNum = DeviceCapabilities(toUnicodez(deviceName), "", DC_PAPERSIZE, null, pDevMode);
	POINT[] paperSizeBuffer = new POINT[paperSizeNum]; // 1/10 mm unit.
	DeviceCapabilities(toUnicodez(deviceName), "", DC_PAPERSIZE, cast(wchar*)paperSizeBuffer.ptr, pDevMode);

	// Get paper kinds.
	WORD[] paperKindBuffer = new WORD[paperSizeNum];
	DeviceCapabilities(toUnicodez(deviceName), "", DC_PAPERS, cast(wchar*)paperKindBuffer.ptr, pDevMode);
	
	// Get name of paper sizes.
	enum PAPERNAME_MAX_LENGTH = 64;
	wchar[] paperNamesBuffer = new wchar[PAPERNAME_MAX_LENGTH * paperSizeNum];
	DeviceCapabilities(toUnicodez(deviceName), "", DC_PAPERNAMES, paperNamesBuffer.ptr, pDevMode);
	wstring[] paperNameArray = _splitNamesBuffer(paperNamesBuffer, paperSizeNum, PAPERNAME_MAX_LENGTH);

	// Return paper sizes.
	PaperSize[] ret;
	for (int i; i < paperSizeNum; i++)
	{
		Size tmpSize = Size(paperSizeBuffer[i].x, paperSizeBuffer[i].y); // 1/10 mm unit
		int paperRawKind = paperKindBuffer[i];
		string paperName = to!string(paperNameArray[i]);
		Size paperSize = PrinterUnitConvert.convert(tmpSize, PrinterUnit.TENTHS_OF_A_MILLIMETER, PrinterUnit.HUNDREDTHS_OF_AN_INCH);
		ret ~= new PaperSize(paperRawKind, paperName, paperSize.width, paperSize.height);
	}
	return ret;
}

///
// Reference: https://learn.microsoft.com/en-us/windows-hardware/drivers/ddi/mxdc/nf-mxdc-mxdcgetpdevadjustment
private int _tentativeDpi(int dmPrintQuality)
{
	if (dmPrintQuality == PrinterResolutionKind.DRAFT)
		return 400;
	else if (dmPrintQuality == PrinterResolutionKind.LOW)
		return 600;
	else if (dmPrintQuality == PrinterResolutionKind.MEDIUM)
		return 1200;
	else if (dmPrintQuality == PrinterResolutionKind.HIGH)
		return 2400;
	else if (dmPrintQuality > 0)
		return dmPrintQuality; // dpi unit.
	else
		assert(0);
}

///
private PrinterResolution[] _createPrinterResolutionArray(HGLOBAL hDevMode)
{
	DEVMODE* pDevMode = cast(DEVMODE*)GlobalLock(hDevMode);
	scope(exit)
		GlobalUnlock(pDevMode);
	
	// Get printer name.
	string deviceName = fromUnicodez(pDevMode.dmDeviceName.ptr);

	// Get printer resolutions.
	int resolutionNum = DeviceCapabilities(toUnicodez(deviceName), "", DC_ENUMRESOLUTIONS, null, pDevMode);
	if (resolutionNum < 0)
	{
		// Device is not support to get printer resolutions.
		return [new PrinterResolution(cast(PrinterResolutionKind)pDevMode.dmPrintQuality, 0, 0)];
	}
	else
	{
		SIZE[] resolutionBuffer = new SIZE[resolutionNum];
		DeviceCapabilities(toUnicodez(deviceName), "", DC_ENUMRESOLUTIONS, cast(wchar*)resolutionBuffer.ptr, pDevMode);

		// Return printer resolutions.
		PrinterResolution[] ret;
		for (int i; i < resolutionNum; i++)
		{
			int dpiX = _tentativeDpi(resolutionBuffer[i].cx);
			int dpiY = resolutionBuffer[i].cy; // dpi unit.
			PrinterResolutionKind kind = {
				if (resolutionBuffer[i].cx < 0)
					return cast(PrinterResolutionKind)resolutionBuffer[i].cx;
				else
					return PrinterResolutionKind.CUSTOM;
			}();
			ret ~= new PrinterResolution(kind, dpiX, dpiY);
		}
		return ret;
	}
}

private
{
	enum DEFAULT_PRINTER_RESOLUTION_X = 200;
	enum DEFAULT_PRINTER_RESOLUTION_Y = 200;
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
	PrinterResolution[] printerResolutions;
	PaperSize[] paperSizes;
	PaperSource[] paperSources;
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
				new PrinterResolution(PrinterResolutionKind.CUSTOM, DEFAULT_PRINTER_RESOLUTION_X, DEFAULT_PRINTER_RESOLUTION_Y)); // dpi unit.
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
		this.printerResolutions = _createPrinterResolutionArray(hDevMode)[0..$>=5?5:$]; // First 5 items.
		this.paperSizes = _createPaperSizeArray(hDevMode)[0..$>=5?5:$]; // First 5 items.
		this.paperSources = _createPaperSourceArray(hDevMode)[0..$>=5?5:$]; // First 5 items.
		// this.isPlotter =
		// this.duplex =

		pDevMode.dmFields |= DM_PAPERSIZE;
		pDevMode.dmPaperSize = cast(short)this.defaultPageSettings.paperSize.rawKind;
		
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
	private int _rawKind;
	private string _paperName;
	private int _width; /// Paper width with 1/100 inch unit.
	private int _height; /// Paper height with 1/100 inch unit.

	///
	this()
	{
		rawKind = PaperKind.CUSTOM;
		paperName = "";
	}
	/// ditto
	this(int rawKind, string name, int width, int height)
	{
		this.rawKind = rawKind;
		this.paperName = name;
		this.width = width;
		this.height = height;
	}

	///
	PaperKind kind() const // getter
	{
		return _kind;
	}

	///
	void rawKind(int rawKind) // setter
	{
		_rawKind = rawKind;
		if (rawKind == DMPAPER_RESERVED_48 || rawKind == DMPAPER_RESERVED_49 || rawKind > DMPAPER_LAST)
			_kind = PaperKind.CUSTOM;
		else
			_kind = cast(PaperKind)rawKind;
	}
	/// ditto
	int rawKind() const // getter
	{
		return _rawKind;
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
	override string toString() const
	{
		string str = "[";
		str ~= "kind: " ~ to!string(_kind) ~ ", ";
		str ~= "rawKind: " ~ to!string(_rawKind) ~ ", ";
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
		p._color = this._color;
		p._landscape = this._landscape;
		if (this._paperSize)
			p._paperSize = new PaperSize(this._paperSize.rawKind, this._paperSize.paperName, this._paperSize.width, this._paperSize.height);
		if (this._paperSource)
			p._paperSource = new PaperSource(this._paperSource.rawKind, this._paperSource.sourceName);
		p._printerResolution = new PrinterResolution(this._printerResolution.kind, this._printerResolution.x, this._printerResolution.y);
		p._margins = new Margins(this._margins.left, this._margins.top, this._margins.right, this._margins.bottom);
		p._hardMarginX = this._hardMarginX;
		p._hardMarginY = this._hardMarginY;
		p._printableArea = this._printableArea;
		p._printerSettings = this._printerSettings;
		return p;
	}

	/// 1/100 inch unit.
	Rect bounds() // getter
	in
	{
		assert(this.paperSize);
		assert(this.margins);
	}
	do
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

	/// Create PaperSource object.
	private PaperSource _createPaperSource(HGLOBAL hDevMode)
	{
		DEVMODE* pDevMode = cast(DEVMODE*)GlobalLock(hDevMode);
		scope(exit)
			GlobalUnlock(pDevMode);

		PaperSource[] sourceArray = _createPaperSourceArray(hDevMode);
		foreach (PaperSource iter; sourceArray)
		{
			if (iter.rawKind == pDevMode.dmDefaultSource)
				return iter;
		}
		return null;
	}

	/// Create PaperSize object.
	private PaperSize _createPaperSize(HGLOBAL hDevMode)
	{
		DEVMODE* pDevMode = cast(DEVMODE*)GlobalLock(hDevMode);
		scope(exit)
			GlobalUnlock(pDevMode);
		
		PaperSize[] sizeArray = _createPaperSizeArray(hDevMode);
		foreach (PaperSize iter; sizeArray)
		{
			if (iter.rawKind == pDevMode.dmPaperSize)
				return iter;
		}
		return null;
	}

	/// Create PrinterResolution object.
	private PrinterResolution _createPrinterResolution(HGLOBAL hDevMode)
	{
		DEVMODE* pDevMode = cast(DEVMODE*)GlobalLock(hDevMode);
		scope(exit)
			GlobalUnlock(pDevMode);
		
		string deviceName = fromUnicodez(pDevMode.dmDeviceName.ptr);

		int dpiX;
		int dpiY;
		PrinterResolutionKind kind;
		if (pDevMode.dmFields & DM_YRESOLUTION)
		{
			assert(pDevMode.dmPrintQuality > 0);
			dpiX = pDevMode.dmPrintQuality; // dpi unit.
			dpiY = pDevMode.dmYResolution; // dpi unit.
			kind = PrinterResolutionKind.CUSTOM;
		}
		else
		{
			int resolutionNum = DeviceCapabilities(toUnicodez(deviceName), "", DC_ENUMRESOLUTIONS, null, pDevMode);
			if (resolutionNum < 0)
			{
				// Device is not support to get printer resolutions.
				dpiX = _tentativeDpi(pDevMode.dmPrintQuality);
				dpiY = dpiX;
				kind = cast(PrinterResolutionKind)pDevMode.dmPrintQuality;
			}
			else
			{
				SIZE[] resolutionBuffer = new SIZE[resolutionNum];
				DeviceCapabilities(toUnicodez(deviceName), "", DC_ENUMRESOLUTIONS, cast(wchar*)resolutionBuffer.ptr, pDevMode);
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
				kind = PrinterResolutionKind.CUSTOM;
			}
		}

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
	/// ditto
	this(in RECT* rect)
	{
		this.left = rect.left;
		this.top = rect.top;
		this.right = rect.right;
		this.bottom = rect.bottom;
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
private RECT _toRECT(Margins margins)
{
	return RECT(margins.left, margins.top, margins.right, margins.bottom);
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
			printer.printRange.reset();
			printer.printRange.kind = PrintRangeKind.SOME_PAGES;
			for (int i = 0; i < _printDialog.nPageRanges; i++)
			{
				int from = _printPageRange[i].nFromPage;
				int to = _printPageRange[i].nToPage;
				printer.printRange.addPrintRange(PrintRange(from, to));
			}
		}
		else if (_printDialog.Flags & PD_SELECTION)
		{
			printer.printRange.reset();
			printer.printRange.kind = PrintRangeKind.SELECTION;
			// Concrete print range is modified by user side.
		}
		else if (_printDialog.Flags & PD_CURRENTPAGE)
		{
			printer.printRange.reset();
			printer.printRange.kind = PrintRangeKind.CURRENT_PAGE;
			// Concrete print range is modified by user side.
		}
		else // PD_ALLPAGES == 0x00000000
		{
			printer.printRange.reset();
			// Concrete print range is modified by user side.
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
			// _minMargins is 1/100 inch unit, but rtMinMargin is 1/100 mm unit.
			enum fromUnit = PrinterUnit.HUNDREDTHS_OF_AN_INCH;
			enum toUnit = PrinterUnit.HUNDREDTHS_OF_A_MILLIMETER;
			_pageSetupDlg.rtMinMargin = PrinterUnitConvert.convert(_toRECT(_minMargins), fromUnit, toUnit);
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
		// Get inital page settings.
		PAGESETUPDLG pd;
		bool isOK = _createPagesetupdlgFromPrinterSettings(pd, document.printerSettings);
		if (!isOK)
		{
			throw new DflException("DFL: runDialog failure.");
		}

		_pageSetupDlg.lStructSize = _pageSetupDlg.sizeof;
		_pageSetupDlg.hwndOwner = owner;
		_pageSetupDlg.hDevMode = pd.hDevMode;
		_pageSetupDlg.hDevNames = pd.hDevNames;
		_pageSetupDlg.lpfnPagePaintHook = null;

		// Set initial margins.
		if (document.printerSettings.defaultPageSettings && document.printerSettings.defaultPageSettings.margins)
		{
			// margins is 1/100 inch unit, but rtMargin is 1/100 mm unit.
			enum fromUnit = PrinterUnit.HUNDREDTHS_OF_AN_INCH;
			enum toUnit = PrinterUnit.HUNDREDTHS_OF_A_MILLIMETER;
			Margins margins = document.printerSettings.defaultPageSettings.margins;
			_pageSetupDlg.rtMargin = PrinterUnitConvert.convert(_toRECT(margins), fromUnit, toUnit);
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

			// rtMargin is 1/100 mm unit, but margins is 1/100 inch unit.
			// rtMinMargin is 1/100 mm unit, but _minMargins is 1/100 inch unit.
			enum fromUnit = PrinterUnit.HUNDREDTHS_OF_A_MILLIMETER;
			enum toUnit = PrinterUnit.HUNDREDTHS_OF_AN_INCH;
			document.printerSettings.defaultPageSettings.margins =
				PrinterUnitConvert.convert(new Margins(&_pageSetupDlg.rtMargin), fromUnit, toUnit);
			_minMargins = PrinterUnitConvert.convert(new Margins(&_pageSetupDlg.rtMinMargin), fromUnit, toUnit);
			return true;
		}
		else
		{
			return false;
		}
	}
}

///
private bool _createPagesetupdlgFromPrinterSettings(ref PAGESETUPDLG pd, PrinterSettings printerSettings)
{
	pd.lStructSize = pd.sizeof;
	pd.hwndOwner = null;
	pd.hDevMode = null;
	pd.hDevNames = null;
	pd.lpfnPagePaintHook = null;
	pd.Flags = PSD_RETURNDEFAULT;

	BOOL resultOK = PageSetupDlg(&pd);
	if (resultOK)
	{
		DEVMODE* pDevMode = cast(DEVMODE*)GlobalLock(pd.hDevMode);
		scope(exit)
			GlobalUnlock(pDevMode);
		pDevMode.dmPrintQuality = DEFAULT_PRINTER_RESOLUTION_X; // dpi
		pDevMode.dmYResolution = DEFAULT_PRINTER_RESOLUTION_Y; // dpi
		pDevMode.dmOrientation = {
			if (printerSettings.defaultPageSettings.landscape)
				return DMORIENT_LANDSCAPE;
			else
				return DMORIENT_PORTRAIT;
		}();
		pDevMode.dmPaperSize = cast(short)printerSettings.defaultPageSettings.paperSize.rawKind;
		pDevMode.dmFields |= DM_PRINTQUALITY | DM_YRESOLUTION | DM_ORIENTATION | DM_PAPERSIZE; // TODO: Need?
		return true;
	}
	else
		return false;
}

///
class PrintPreviewControl : Control
{
	enum LEFT_MARIGIN = 20; // pixels
	enum RIGHT_MARGIN = 20; // pixels
	enum TOP_MARGIN = 20; // pixels
	enum BOTTOM_MARGIN = 20; // pixels
	enum HORIZONTAL_SPAN = 20; // pixels
	enum VERTICAL_SPAN = 20; // pixels

	private PrintDocument _document; ///
	private int _columns; ///
	private int _rows; ///
	private int _startPage; ///
	private bool _autoZoom; ///
	private MemoryGraphics _offscreen; ///
	private Size _justDrawnSize; ///

	///
	this(PrintDocument doc)
	in
	{
		assert(doc);
	}
	do
	{
		_document = doc;
		_columns = 1;
		_rows = 1;
		_startPage = 0;
		_autoZoom = true;
	}

	///
	void document(PrintDocument doc) // setter
	in
	{
		assert(doc);
	}
	do
	{
		_document = doc;
	}
	/// ditto
	PrintDocument document() // getter
	{
		return _document;
	}

	///
	void autoZoom(bool b) // setter
	{
		_autoZoom = b;
	}
	/// ditto
	bool autoZoom() const // getter
	{
		return _autoZoom;
	}

	///
	void columns(int col) // setter
	{
		_columns = col;
	}
	/// ditto
	int columns() const // getter
	{
		return _columns;
	}

	///
	void rows(int row) // setter
	{
		_rows = row;
	}
	/// ditto
	int rows() const // getter
	{
		return _rows;
	}

	///
	void startPage(int page) // setter
	{
		_startPage = page;
	}
	/// ditto
	int startPage() const // getter
	{
		return _startPage;
	}

	///
	private void justDrawnSize(Size sz) // setter
	{
		_justDrawnSize = sz;
	}

	///
	final void invalidatePreview()
	in
	{
		assert(document);
	}
	do
	{
		PAGESETUPDLG pd;
		bool isOK = _createPagesetupdlgFromPrinterSettings(pd, document.printerSettings);
		if (!isOK)
		{
			throw new DflException("DFL: invalidatePreview failure.");
		}
		document.printerSettings.setHdevnames(pd.hDevNames);
		document.printerSettings.defaultPageSettings.setHdevmode(pd.hDevMode);

		Rect screenRect = Rect(0, 0, GetSystemMetrics(SM_CXSCREEN), GetSystemMetrics(SM_CYSCREEN));
		_offscreen = new MemoryGraphics(screenRect.width, screenRect.height);
		_offscreen.fillRectangle(new SolidBrush(Color.gray), screenRect);

		// Reset here, because print range is always all pages on preview print.
		document.printerSettings.printRange.reset();

		PrintController oldPrintController = document.printController;
		document.printController = new PreviewPrintController(this); // TODO: Cross reference.
		document.print(_offscreen.handle);
		this.onLastPageChanged(new LastPageChangedEventArgs(_getLastPage(document)));
		document.printController = oldPrintController;
	}

	///
	protected override void onPaint(PaintEventArgs e)
	{
		super.onPaint(e);
		if (_offscreen)
		{
			if (this.autoZoom)
			{
				const Rect offscreenRect = Rect(0, 0, _justDrawnSize.width, _justDrawnSize.height);
				uint onscreenHeight = this.height;
				uint onscreenWidth = offscreenRect.width * this.height / offscreenRect.height;
				if (onscreenWidth >= this.width)
				{
					onscreenWidth = this.width;
					onscreenHeight = offscreenRect.height * this.width / offscreenRect.width;
				}

				SetStretchBltMode(_offscreen.handle, STRETCH_DELETESCANS); // SRC
				StretchBlt(
					e.graphics.handle, // DST
					0,
					0,
					onscreenWidth,
					onscreenHeight,
					_offscreen.handle, // SRC
					0,
					0,
					offscreenRect.width,
					offscreenRect.height,
					SRCCOPY
				);
			}
			else
			{
				_offscreen.copyTo(e.graphics, 0, 0, _offscreen.width, _offscreen.height);
			}
		}
	}

	///
	protected void onLastPageChanged(LastPageChangedEventArgs e)
	{
		lastPageChangeed(this, e);
	}

	///
	Event!(Control, LastPageChangedEventArgs) lastPageChangeed;
}

///
class PrintPreviewDialog : Form
{
	private PrintPreviewControl _previewControl;
	private ToolBar _toolBar;
	private ToolBarButton _button1;
	private ToolBarButton _button2;
	private ToolBarButton _button3;
	private ToolBarButton _button4;
	private ToolBarButton _button5;
	private ImageList _imageList;
	private Panel _pageSelectPanel;
	private Panel _previewPanel;
	private Label _fromPageLabel;
	private TextBox _fromPage;
	private Label _slashLabel;
	private TextBox _toPage;
	private Button _forwardButton;
	private Button _backButton;

	///
	this(PrintDocument doc)
	in
	{
		assert(doc);
	}
	do
	{
		this.text = "Print Preview";

		_toolBar = new ToolBar();
		_toolBar.parent = this;
		_toolBar.dock = DockStyle.TOP;
		_toolBar.style = ToolBarStyle.NORMAL;

		_imageList = new ImageList;
		_imageList.imageSize = Size(32,32);
		_imageList.transparentColor = Color.red;
		import std.path;
		string bmpPath = dirName(__FILE__) ~ r"\image\previewprintdialog_toolbar.bmp";
		_imageList.images.addStrip(new Bitmap(bmpPath));
		_toolBar.imageList = _imageList;

		_button1 = new ToolBarButton("Print...");
		_button1.style = ToolBarButtonStyle.PUSH_BUTTON;
		_button1.imageIndex = 0;
		_toolBar.buttons.add(_button1);

		_button2 = new ToolBarButton("1x1");
		_button2.style = ToolBarButtonStyle.PUSH_BUTTON;
		_button2.imageIndex = 1;
		_toolBar.buttons.add(_button2);

		_button3 = new ToolBarButton("2x1");
		_button3.style = ToolBarButtonStyle.PUSH_BUTTON;
		_button3.imageIndex = 2;
		_toolBar.buttons.add(_button3);

		_button4 = new ToolBarButton("2x2");
		_button4.style = ToolBarButtonStyle.PUSH_BUTTON;
		_button4.imageIndex = 3;
		_toolBar.buttons.add(_button4);

		_button5 = new ToolBarButton("Fit");
		_button5.style = ToolBarButtonStyle.TOGGLE_BUTTON;
		_button5.pushed = true; // Initial mode is "Fit".
		_button5.imageIndex = 4;
		_toolBar.buttons.add(_button5);

		_toolBar.buttonClick ~= (ToolBar tb, ToolBarButtonClickEventArgs e) {
			if (e.button is _button1)
			{
				PrintDialog printDialog = new PrintDialog(doc);
				DialogResult r = printDialog.showDialog();
				if (r == dialogResult.OK)
				{
					// Do nothing.
				}
			}
			else if (e.button is _button2) // 1x1
			{
				_previewControl.columns = 1;
				_previewControl.rows = 1;
				_previewControl.invalidatePreview();
				_previewControl.invalidate();
			}
			else if (e.button is _button3) // 2x1
			{
				_previewControl.columns = 2;
				_previewControl.rows = 1;
				_previewControl.invalidatePreview();
				_previewControl.invalidate();
			}
			else if (e.button is _button4) // 2x2
			{
				_previewControl.columns = 2;
				_previewControl.rows = 2;
				_previewControl.invalidatePreview();
				_previewControl.invalidate();
			}
			else if (e.button is _button5)
			{
				_previewControl.autoZoom = !_previewControl.autoZoom;
				_previewControl.invalidatePreview();
				_previewControl.invalidate();
				_enableScroll = !_previewControl.autoZoom;
			}
			else
				assert(0);
		};

		_pageSelectPanel = new Panel();
		_pageSelectPanel.parent = this;
		_pageSelectPanel.height = 24;
		_pageSelectPanel.dock = DockStyle.TOP;

		_fromPageLabel = new Label();
		_fromPageLabel.parent = _pageSelectPanel;
		_fromPageLabel.text = "Page ";
		_fromPageLabel.width = 50;
		_fromPageLabel.textAlign = ContentAlignment.MIDDLE_RIGHT;
		_fromPageLabel.dock = DockStyle.LEFT;

 		_fromPage = new TextBox();
		_fromPage.parent = _pageSelectPanel;
		_fromPage.width = 50;
		_fromPage.dock = DockStyle.LEFT;
		_fromPage.gotFocus ~= (Control c, EventArgs e)
		{
			_fromPage.selectAll();
		};
		_fromPage.keyPress ~= (Control c, KeyEventArgs e)
		{
			if (e.keyCode == Keys.ENTER)
			{
				int oldPage = _previewControl.startPage;
				int newPage;
				e.handled = true; // Disallow beep.
				try
				{
					newPage = to!int(_fromPage.text) - 1;
				}
				catch (Exception e)
				{
					newPage = oldPage; // Undo.
				}

				if (newPage < 0 || newPage > _getLastPage(this.document))
					newPage = oldPage; // Undo.

				_previewControl.startPage = newPage;
				_fromPage.text = to!string(newPage + 1);

				if (oldPage != newPage)
				{
					_previewControl.invalidatePreview();
					_previewControl.invalidate();
				}
				
				_fromPage.selectAll();
			}
		};

		_slashLabel = new Label();
		_slashLabel.parent = _pageSelectPanel;
		_slashLabel.text = " / ";
		_slashLabel.autoSize = true;
		_slashLabel.dock = DockStyle.LEFT;

 		_toPage = new TextBox();
		_toPage.parent = _pageSelectPanel;
		_toPage.width = 50;
		_toPage.dock = DockStyle.LEFT;
		_toPage.enabled = false;

		_backButton = new Button;
		_backButton.parent = _pageSelectPanel;
		_backButton.text = "<";
		_backButton.width = 32;
		_backButton.dock = DockStyle.LEFT;
		_backButton.click ~= (Control c, EventArgs e)
		{
			int oldPage = _previewControl.startPage;
			int newPage = _previewControl.startPage - _previewControl.rows * _previewControl.columns;
			if (newPage < 0)
				newPage = 0;
			_previewControl.startPage = newPage;
			_fromPage.text = to!string(_previewControl.startPage + 1);
			if (oldPage != newPage)
			{
				_previewControl.invalidatePreview();
				_previewControl.invalidate();
			}
		};

		_forwardButton = new Button;
		_forwardButton.parent = _pageSelectPanel;
		_forwardButton.text = ">";
		_forwardButton.width = 32;
		_forwardButton.dock = DockStyle.LEFT;
		_forwardButton.click ~= (Control c, EventArgs e)
		{
			int oldPage = _previewControl.startPage;
			int newPage = _previewControl.startPage + _previewControl.rows * _previewControl.columns;
			int lastPage = _getLastPage(doc);
			if (newPage > lastPage)
				newPage = lastPage;
			if (newPage < 0)
				newPage = 0;
			_previewControl.startPage = newPage;
			_fromPage.text = to!string(_previewControl.startPage + 1);
			if (oldPage != newPage)
			{
				_previewControl.invalidatePreview();
				_previewControl.invalidate();
			}
		};

		_previewPanel = new Panel();
		_previewPanel.parent = this;
		_previewPanel.dock = DockStyle.FILL;

		_previewControl = new PrintPreviewControl(doc);
		_previewControl.parent = _previewPanel;
		_previewControl.resizeRedraw = true;
		_previewControl.backColor = Color.gray;
		_previewControl.dock = DockStyle.FILL;
		_previewControl.lastPageChangeed ~= (Control c, LastPageChangedEventArgs e) {
			_toPage.text = to!string(e.lastPage + 1);
		};

		_reset(doc);
	}

	///
	private void _reset(PrintDocument doc)
	{
		this.width = 1024;
		this.height = 960;
		this.windowState = FormWindowState.NORMAL;

		_previewControl.rows = 1;    // Single page view
		_previewControl.columns = 1; // ditto
		_previewControl.autoZoom = true; // Initial mode is "Fit".
		_previewControl.startPage = 0;

		_enableScroll = !_previewControl.autoZoom;

		_fromPage.text = to!string(_previewControl.startPage + 1);
	}

	///
	void document(PrintDocument doc) // setter
	in
	{
		assert(doc);
		assert(_previewControl);
	}
	do
	{
		_previewControl.document = doc;
	}
	/// ditto
	PrintDocument document() // getter
	in
	{
		assert(_previewControl);
	}
	do
	{
		return _previewControl.document;
	}

	///
	protected override void wndProc(ref Message msg)
	{
		super.wndProc(msg);
	}

	///
	protected override void onShown(EventArgs ea)
	{
		super.onShown(ea);
		_previewControl.invalidatePreview();
		// No need to call _previewControl.invalidate();
	}

	///
	protected override void onClosed(EventArgs ea)
	{
		super.onClosed(ea);
		_reset(document);
	}

	///
	private void _enableScroll(bool byes) @property // setter
	{
		if (byes)
		{
			_previewPanel.hScroll = true;
			_previewPanel.vScroll = true;
			_previewPanel.scrollSize = Size(GetSystemMetrics(SM_CXSCREEN), GetSystemMetrics(SM_CYSCREEN));
			_previewPanel.performLayout();
		}
		else
		{
			_previewPanel.hScroll = false;
			_previewPanel.vScroll = false;
			_previewPanel.scrollSize = Size(0, 0);
			_previewPanel.performLayout();
		}
	}
}

///
private int _getLastPage(PrintDocument doc)
{
	return cast(int)((new PrintRangeWalker(doc.printerSettings.printRange.ranges)).count) - 1;
}

///
class PreviewPrintController : PrintController
{
	///
	private class Page
	{
		this(MemoryGraphics g, PageSettings s)
		{
			graphics = g;
			settings = s;
		}
		MemoryGraphics graphics;
		PageSettings settings;
	}

	private PrintPreviewControl _previewControl; ///
	private Page[] _pages; ///

	///
	this(PrintPreviewControl previewControl)
	in
	{
		assert(previewControl);
	}
	do
	{
		_previewControl = previewControl;
	}

	///
	override void onStartPrint(PrintDocument document, PrintEventArgs e)
	{
		_pages.length = 0;
	}

	/// Create screen for single page and draw the paper looks form.
	override Graphics onStartPage(PrintDocument document, PrintPageEventArgs e)
	{
		Rect paperRect = _paperRectFrom(e.pageSettings);
		auto pageGraphcis = new MemoryGraphics(paperRect.width, paperRect.height, e.graphics);
		pageGraphcis.fillRectangle(Color.white, paperRect); // Draw the form of paper.
		pageGraphcis.drawRectangle(new Pen(Color.black), paperRect); // Draw the border of paper.
		_pages ~= new Page(pageGraphcis, e.pageSettings);
		return pageGraphcis;
	}

	///
	override void onEndPage(PrintDocument document, PrintPageEventArgs e)
	{
		Graphics pageGraphics = _pages[e.currentPage - 1].graphics;
		pageGraphics.pageUnit = GraphicsUnit.DISPLAY; // Initialize graphics unit that is changed in user side.
		Font font = new Font("MS Gothic", 100/+pt+/ * e.pageSettings.printerResolution.y / 72); // 1 point == 1/72 inches
		_drawPageNumber(pageGraphics, e.currentPage, font); // Draw the current page number.
	}

	///
	override void onEndPrint(PrintDocument document, PrintEventArgs e)
	{
		const Rect screenRect = {
			const int deviceWidth = GetSystemMetrics(SM_CXSCREEN); // pixel unit.
			const int deviceHeight = GetSystemMetrics(SM_CYSCREEN); // pixel unit.
			return Rect(0, 0, deviceWidth, deviceHeight); // TODO: Gets MemoryGraphics size as the background DC.
		}();

		enum LEFT_AND_RIGHT_MARGIN = PrintPreviewControl.LEFT_MARIGIN + PrintPreviewControl.RIGHT_MARGIN;
		enum TOP_AND_BOTTOM_MARGIN = PrintPreviewControl.TOP_MARGIN + PrintPreviewControl.BOTTOM_MARGIN;
		enum HORIZONTAL_SPAN = PrintPreviewControl.HORIZONTAL_SPAN;
		enum VERTICAL_SPAN = PrintPreviewControl.VERTICAL_SPAN;
		
		Page[] targetPageList = _pages;
		if (_previewControl.startPage > 0)
			targetPageList = targetPageList.drop(_previewControl.startPage);
		targetPageList = targetPageList.take(_previewControl.rows * _previewControl.columns);
		assert(targetPageList.length > 0, "targetPageList is empty.");
		
		int totalPageWidth = targetPageList
			.map!(p => _paperRectFrom(p.settings).width) // [w1,w2,w3,w4]
			.chunks(_previewControl.columns) // [w1,w2],[w3,w4]
			.map!(elem => elem.sum) // [w1+w2],[w3+w4]
			.maxElement; // w1+w2 if w1+w2 > w3+w4

		int totalPageHeight = targetPageList
			.map!(p => _paperRectFrom(p.settings).height) // [h1,h2,h3,h4]
			.chunks(_previewControl.columns) // [h1,h2],[h3,h4]
			.map!(elem => elem.maxElement) // [h1,h4] if h1 > h2 and h3 < h4
			.sum; // h1+h4

		// TOP_AND_BOTTOM_MARGIN and the others are scales on video screen world.
		double ratio = cast(double)(screenRect.height - TOP_AND_BOTTOM_MARGIN - VERTICAL_SPAN * (_previewControl.rows - 1)) / totalPageHeight;
		if (screenRect.width < totalPageWidth * ratio)
		{
			ratio = cast(double)(screenRect.width - LEFT_AND_RIGHT_MARGIN - HORIZONTAL_SPAN * (_previewControl.columns - 1)) / totalPageWidth;
		}

		_previewControl.justDrawnSize = Size(
			cast(int)(totalPageWidth * ratio) + LEFT_AND_RIGHT_MARGIN + HORIZONTAL_SPAN * (_previewControl.columns - 1),
			cast(int)(totalPageHeight * ratio) + TOP_AND_BOTTOM_MARGIN + VERTICAL_SPAN * (_previewControl.rows - 1)
		);

		auto layoutHelper = new PageLayoutHelper(_previewControl.columns, _previewControl.rows);
		foreach (Page page; targetPageList)
		{
			const Point pos = layoutHelper.position();
			const Rect paperRect = _paperRectFrom(page.settings);
			const uint pageRenderWidth = cast(uint)(paperRect.width * ratio);
			const uint pageRenderHeight = cast(uint)(paperRect.height * ratio);
			Graphics pageGraphics = page.graphics;
			SetStretchBltMode(pageGraphics.handle, STRETCH_DELETESCANS); // SRC
			StretchBlt(
				e.hDC, // DST
				pos.x,
				pos.y,
				pageRenderWidth,
				pageRenderHeight,
				pageGraphics.handle, // SRC
				0,
				0,
				paperRect.width * 100 / DEFAULT_PRINTER_RESOLUTION_X,
				paperRect.height * 100 / DEFAULT_PRINTER_RESOLUTION_Y,
				SRCCOPY
			);
			pageGraphics.dispose(); // Created in onStartPage().
			layoutHelper.appendPageSize(pageRenderWidth, pageRenderHeight);
		}
	}
	
	///
	private static void _drawPageNumber(Graphics graphics, int currentPage, Font font)
	{
		const string currentPageString = to!string(currentPage);
		graphics.drawText(currentPageString, font, Color.white, Rect(20, 20, 1000, 1000));
		graphics.drawText(currentPageString, font, Color.black, Rect(0, 0, 1000, 1000));
	}
}

///
private final class PageLayoutHelper
{
	private Point _nextPosition; ///
	private const uint _columns; ///
	private const uint _rows; ///
	private uint _col; ///
	private uint _row; ///
	private uint _maxHeightInCurrentLine; ///

	///
	this(uint columns, uint rows)
	{
		reset();
		_rows = rows;
		_columns = columns;
	}

	///
	void reset()
	{
		_nextPosition = Point(PrintPreviewControl.LEFT_MARIGIN, PrintPreviewControl.TOP_MARGIN);
		_row = 0;
		_col = 0;
		_maxHeightInCurrentLine = 0;
	}

	///
	Point position() const
	{
		return _nextPosition;
	}

	///
	void appendPageSize(int width, int height)
	{
		if (_maxHeightInCurrentLine < height)
		{
			_maxHeightInCurrentLine = height;
		}

		if (_col + 1 >= _columns)
		{
			_col = 0;
			_row++;
			_nextPosition.x = PrintPreviewControl.LEFT_MARIGIN;
			_nextPosition.y += _maxHeightInCurrentLine + PrintPreviewControl.VERTICAL_SPAN;
			_maxHeightInCurrentLine = 0;
		}
		else
		{
			_col++;
			_nextPosition.x += width + PrintPreviewControl.HORIZONTAL_SPAN;
		}
	}
}

///
private Rect _paperRectFrom(PageSettings page)
{
	const int paperLeft = (page.bounds.x - page.margins.left) * page.printerResolution.x / 100;
	const int paperTop = (page.bounds.y - page.margins.top) * page.printerResolution.y / 100;
	const int paperWidth = (page.bounds.x + page.bounds.width + page.margins.right) * page.printerResolution.x / 100;
	const int paperHeight = (page.bounds.y + page.bounds.height + page.margins.bottom) * page.printerResolution.y / 100;
	return Rect(paperLeft, paperTop, paperWidth, paperHeight);
}
