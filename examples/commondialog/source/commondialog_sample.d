import dfl;
import std.conv;

// version = DFL_USE_STREAM; // Stream is deprecated.

version(Have_dfl) // For DUB.
{
}
else
{
	pragma(lib, "dfl.lib");
}

class MainForm : Form
{
	private Button _openButton;
	private Button _saveButton;
	private Button _folderButton;
	private Button _fontButton;
	private Button _colorButton;
	private Button _printButton;
	private Button _pageSetupButton;

	private OpenFileDialog _openFileDialog;
	private SaveFileDialog _saveFileDialog;
	private FolderBrowserDialog _folderDialog;
	private FontDialog _fontDialog;
	private ColorDialog _colorDialog;

	private PrintDocument _document;
	private PrintDialog _printDialog;
	private PageSetupDialog _pageSetupDialog;

	private void doOpenFileDialog(Control sender, EventArgs e)
	{
		// Settings
		_openFileDialog.title = "Select to open file";
		_openFileDialog.initialDirectory = ".";
		_openFileDialog.fileName = "*.json"; // Initial file name
		_openFileDialog.filter = "All files(*.*)|*.*|json file(*.json)|*.json";
		_openFileDialog.filterIndex = 1; // 1 is *.json
		
		_openFileDialog.restoreDirectory = true;
		_openFileDialog.checkFileExists = true;
		_openFileDialog.checkPathExists = true;
		_openFileDialog.dereferenceLinks = true;
		_openFileDialog.multiselect = true; // single select
		_openFileDialog.showHelp = true; // NOTE: The help button does not respond if showPlaceBar is true.

		_openFileDialog.defaultExt = "json";
		// _openFileDialog.addExtension = true; // TODO: Implement

		_openFileDialog.showPlaceBar = true; // When false, Enable fileOk event and helpRequest event but hide place bar.

		DialogResult r = _openFileDialog.showDialog();
		if (r == DialogResult.OK)
		{
			version(DFL_USE_STREAM) // Stream is deprecated.
			{
				string filelist;
				foreach (f; _openFileDialog.fileNames)
				{
					filelist ~= f ~ "\n";
				}
				msgBox(filelist, "Selected file list");

				import undead.stream;
				Stream st = _openFileDialog.openFileStream;
				foreach(char[] line; st)
				{
					msgBox(cast(string)line, _openFileDialog.fileName); break; // Read first line only.
				}
			}
			else
			{
				string filelist;
				foreach (f; _openFileDialog.fileNames)
				{
					filelist ~= f ~ "\n";
				}
				msgBox(filelist, "Selected file list");

				import std.stdio;
				File file = _openFileDialog.openFile();
				foreach(line; file.byLine())
				{
					msgBox(cast(string)line, _openFileDialog.fileName); break; // Read first line only.
				}
			}
		}
	}

	private void doSaveFileDialog(Control sender, EventArgs e)
	{
		_saveFileDialog.title = "Select to write file";
		_saveFileDialog.fileName = "newfile.json";
		_saveFileDialog.initialDirectory = r".";
		_saveFileDialog.filter = "json file|*.json|All files(*.*)|*.*";
		_saveFileDialog.filterIndex = 0;
		
		_saveFileDialog.restoreDirectory = true;
		_saveFileDialog.checkFileExists = true;
		_saveFileDialog.checkPathExists = true;
		_saveFileDialog.overwritePrompt = true;
		_saveFileDialog.showHelp = true;

		_saveFileDialog.showPlaceBar = false; // When false, Enable fileOk event and helpRequest event but hide place bar.
		
		DialogResult r = _saveFileDialog.showDialog();
		if (r == DialogResult.OK)
		{
			// import std.stdio;
			// File file = _saveFileDialog.openFile();
			// file.write("Hello DFL.");
			msgBox(_saveFileDialog.fileName, "Created new file (Not actually)");
		}
	}

	private void doFolderDialog(Control sender, EventArgs e)
	{
		_folderDialog.description = "Select folder";
		_folderDialog.showNewStyleDialog = true;
		_folderDialog.showNewFolderButton = true;
		_folderDialog.showTextBox = true;
		_folderDialog.rootFolder = Environment.SpecialFolder.MY_COMPUTER;
		_folderDialog.selectedPath = Environment.getFolderPath(Environment.SpecialFolder.MY_DOCUMENTS);

		DialogResult r = _folderDialog.showDialog();
		if (r == DialogResult.OK)
		{
			msgBox(_folderDialog.selectedPath, "Selected folder");
		}
	}

	private void doFontDialog(Control sender, EventArgs e)
	{
		_fontDialog.font = new Font("Meiryo UI", 14f);
		_fontDialog.color = Color(255, 0, 0);
		_fontDialog.minSize = 8;
		_fontDialog.maxSize = 20;

		_fontDialog.allowVerticalFonts = false;
		_fontDialog.showEffects = true;
		_fontDialog.fontMustExist = true;
		_fontDialog.fixedPitchOnly = false;
		_fontDialog.allowVectorFonts = true;
		_fontDialog.allowSimulations = true;
		_fontDialog.scriptsOnly = false;

		DialogResult r = _fontDialog.showDialog();
		if (r == DialogResult.OK)
		{
			msgBox(_fontDialog.font.name, "Selected font");
		}
	}

	private void doColorDialog(Control sender, EventArgs e)
	{
		_colorDialog.color = Color(255, 0, 0);
		_colorDialog.allowFullOpen = true;
		_colorDialog.solidColorOnly = false;
		_colorDialog.fullOpen = false;
		_colorDialog.anyColor = true;
		_colorDialog.customColors = [1000, 2000, 3000, 4000];

		DialogResult r = _colorDialog.showDialog();
		if (r == DialogResult.OK)
		{
			auto red = _colorDialog.color.r;
			auto green = _colorDialog.color.g;
			auto blue = _colorDialog.color.b;
			import std.format;
			string mes = format("(R,G,B) = (%d,%d,%d)", red, green, blue);
			msgBox(mes, "Selected color");
		}
	}

	private void doFileOk(FileDialog sender, CancelEventArgs e)
	{
		// if (REJECT_CONDITON)
		// 	e.cancel = true;
		msgBox("Fired fileOk event");
	}

	private void doHelpRequest(CommonDialog sender, HelpEventArgs e)
	{
		msgBox("Fired helpRequest event");
	}

	private void doPrintDialog(Control sender, EventArgs e)
	{
		_printDialog.document.printRange ~= (PrintDocument doc, PrintRangeEventArgs e) {
			final switch (e.printRange.kind)
			{
			case PrintRangeKind.ALL_PAGES:
				e.printRange.addPrintRange(PrintRange(1, 2));
				break;
			case PrintRangeKind.SELECTION:
				e.printRange.addPrintRange(PrintRange(1, 1));
				break;
			case PrintRangeKind.CURRENT_PAGE:
				e.printRange.addPrintRange(PrintRange(2, 2));
				break;
			case PrintRangeKind.SOME_PAGES:
				// The page range is determined by the printer dialog, so we don't do anything here.
			}
		};

		_printDialog.document.beginPrint ~= (PrintDocument doc, PrintEventArgs e) {
			// Do something.
		};

		_printDialog.document.queryPageSettings ~= (PrintDocument doc, QueryPageSettingsEventArgs e) {
			// User modify page settings here.
			// TODO: Paper orientation cannot be changed.
		};

		_printDialog.document.printPage ~= (PrintDocument doc, PrintPageEventArgs e) {
			Graphics g = e.graphics;
			int dpiX = e.pageSettings.printerResolution.x; // dpi unit.
			int dpiY = e.pageSettings.printerResolution.y; // dpi unit.

			// Draw margin border to all pages.
			Rect marginRect = Rect(
				e.marginBounds.x * dpiX / 100, // e.marginBounds is 1/100 dpi unit.
				e.marginBounds.y * dpiY / 100,
				e.marginBounds.width * dpiX / 100,
				e.marginBounds.height * dpiY / 100);
			g.drawRectangle(new Pen(Color.green, 10), marginRect);

			if (e.currentPage == 1) // Draw page 1.
			{
				string str =
					"PrintDcoument.DocumentName: " ~ to!string(doc.documentName) ~ "\n\n" ~
					"PrintDcoument.defaultPageSettings: " ~ to!string(doc.printerSettings.defaultPageSettings) ~ "\n\n" ~
					"PrintDcoument.printerSettings: " ~ to!string(doc.printerSettings) ~ "\n\n" ~
					"PrintPageEventArgs.pageSettings: " ~ to!string(e.pageSettings) ~ "\n\n" ~ 
					"PrintPageEventArgs.pageBounds: " ~ to!string(e.pageBounds) ~ "\n\n" ~
					"PrintPageEventArgs.marginBounds: " ~ to!string(e.marginBounds);
				Rect paramPrintRect = Rect(
					e.marginBounds.x * dpiX / 100, // e.marginBounds is 1/100 dpi unit.
					e.marginBounds.y * dpiY / 100,
					e.marginBounds.width * dpiX / 100,
					e.marginBounds.height * dpiY / 100
				);
				g.drawText(
					str,
					new Font("MS Gothic", 8/+pt+/ * dpiX / 72),
					Color.black,
					paramPrintRect
				);

				e.hasMorePage = true;
			}
			else if (e.currentPage == 2) // Draw page 2.
			{
				Rect redRect = Rect(1 * dpiX, 1 * dpiY, 1 * dpiX, 1 * dpiY); // 1 x 1 inch.
				redRect.offset(marginRect.x, marginRect.y);
				g.fillRectangle(new SolidBrush(Color.red), redRect);

				Rect blueRect = Rect(dpiX, dpiY, 3 * dpiX, 3 * dpiY); // 3 x 3 inch.
				blueRect.offset(marginRect.x, marginRect.y);
				g.drawRectangle(new Pen(Color.blue, 10), blueRect);

				Rect textRect = Rect(1 * dpiX, 1 * dpiY, 1 * dpiX, 1 * dpiY); // 1 x 1 inch.
				textRect.offset(marginRect.x, marginRect.y);
				g.drawText(
					"ABCDEあいうえお",
					new Font("MS Gothic", 12/+pt+/ * dpiX / 72),
					Color.black,
					textRect
				);

				Rect purpleRect = Rect(3 * dpiX, 3 * dpiY, 1 * dpiX, 1 * dpiY); // 1 x 1 inch.
				purpleRect.offset(marginRect.x, marginRect.y);
				g.drawEllipse(new Pen(Color.purple, 10), purpleRect);

				Pen pen = new Pen(Color.black, 10);
				enum lineNum = 20;
				for (int x; x < lineNum; x++)
				{
					g.drawLine(
						pen,
						marginRect.x + cast(int)(x / 4.0 * dpiX),
						e.marginBounds.y * dpiY / 100,
						marginRect.x + cast(int)((lineNum - x - 1)/4.0 * dpiX),
						e.marginBounds.bottom * dpiY / 100);
				}

				e.hasMorePage = false;
			}
		};

		_printDialog.document.endPrint ~= (PrintDocument doc, PrintEventArgs e) {
			// Do nothing.
		};

		_printDialog.allowSomePages = true;
		_printDialog.showHelp = true;
		
		DialogResult r = _printDialog.showDialog();
		if (r == DialogResult.OK)
		{
			// Do nothing.
		}
	}

	private void doPageSetupDialog(Control sender, EventArgs e)
	{
		_pageSetupDialog.minMargins = new Margins(100, 100, 100, 100); // 1/100 inch unit. (1 inch)
		_pageSetupDialog.showNetwork = true;
		_pageSetupDialog.showHelp = true;
		_pageSetupDialog.allowMargins = true;
		_pageSetupDialog.allowOrientation = true;
		_pageSetupDialog.allowPaper = true;
		_pageSetupDialog.allowPrinter = true;

		DialogResult r = _pageSetupDialog.showDialog();
		if (r == DialogResult.OK)
		{
			string msg = "[";
			msg ~= "minMargins: " ~ to!string(_pageSetupDialog.minMargins) ~ ", ";
			msg ~= "defaultPageSettings: " ~ to!string(_pageSetupDialog.document.printerSettings.defaultPageSettings) ~ "]";
			msgBox(msg, "doPageSetupDialog");
		}
	}

	public this()
	{
		this.text = "Common dialogs example";
		this.size = Size(350, 300);

		_openFileDialog = new OpenFileDialog();
		_openFileDialog.fileOk ~= &doFileOk;
		_openFileDialog.helpRequest ~= &doHelpRequest;

		_saveFileDialog = new SaveFileDialog();
		_saveFileDialog.fileOk ~= &doFileOk;
		_saveFileDialog.helpRequest ~= &doHelpRequest;
		
		_folderDialog = new FolderBrowserDialog();
		_fontDialog = new FontDialog();
		_colorDialog = new ColorDialog();

		_document = new PrintDocument();
		_printDialog = new PrintDialog(_document);
		_pageSetupDialog = new PageSetupDialog(_document);

		with(_openButton = new Button())
		{
			parent = this;
			text = "Open file";
			location = Point(10, 10);
			size = Size(100, 23);
			click ~= &doOpenFileDialog;
		}
		with(_saveButton = new Button())
		{
			parent = this;
			text = "Save file";
			location = Point(10, 40);
			size = Size(100, 23);
			click ~= &doSaveFileDialog;
		}
		with(_folderButton = new Button())
		{
			parent = this;
			text = "Folder";
			location = Point(10, 70);
			size = Size(100, 23);
			click ~= &doFolderDialog;
		}
		with(_fontButton = new Button())
		{
			parent = this;
			text = "Font";
			location = Point(10, 100);
			size = Size(100, 23);
			click ~= &doFontDialog;
		}
		with(_colorButton = new Button())
		{
			parent = this;
			text = "Color";
			location = Point(10, 130);
			size = Size(100, 23);
			click ~= &doColorDialog;
		}
		with(_printButton = new Button())
		{
			parent = this;
			text = "Print";
			location = Point(10, 160);
			size = Size(100, 23);
			click ~= &doPrintDialog;
		}
		with(_pageSetupButton = new Button())
		{
			parent = this;
			text = "Page Setup";
			location = Point(10, 190);
			size = Size(100, 23);
			click ~= &doPageSetupDialog;
		}
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
