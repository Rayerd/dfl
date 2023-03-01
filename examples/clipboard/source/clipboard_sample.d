import dfl;
import dfl.internal.utf;
import dfl.internal.dlib;
import std.utf;

version(Have_dfl) // For DUB.
{
}
else
{
	pragma(lib, "dfl.lib");
}

class MainForm : Form
{
	private Panel _leftSide;
	private Panel _rightSide;
	private TextBox _textbox;
	private PictureBox _picturebox;
	private Button _copyText;
	private Button _copyBitmap;
	private Button _copyFileDrop;
	private Button _paste;
	private Button _clear;
	private Button _formats;
	private Button _flush;

	public this()
	{
		this.text = "Clipboard example";
		this.size = Size(500, 400);

		_leftSide = new Panel();
		_leftSide.dock = DockStyle.LEFT;
		_leftSide.width = 200;
		_leftSide.parent = this;

		_rightSide = new Panel();
		_rightSide.dock = DockStyle.FILL;
		_rightSide.parent = this;

		_picturebox = new PictureBox();
		_picturebox.parent = _rightSide;
		_picturebox.dock = DockStyle.TOP;
		_picturebox.height = 100;
		_picturebox.backColor = Color(255,255,255);

		_textbox = new TextBox();
		_textbox.parent = _rightSide;
		_textbox.multiline = true;
		_textbox.dock = DockStyle.FILL;
		_textbox.wordWrap = false;
		_textbox.scrollBars = ScrollBars.BOTH;

		_copyText = new Button();
		_copyText.parent = _leftSide;
		_copyText.text = "copy from textbox";
		_copyText.dock = DockStyle.TOP;
		_copyText.click ~= (Control c, EventArgs e)
		{
			_picturebox.image = null;
			static if (1)
				Clipboard.setString(_textbox.text);
			else // same as
				Clipboard.setData(DataFormats.stringFormat, new Data(_textbox.text));
		};

		_copyBitmap = new Button();
		_copyBitmap.parent = _leftSide;
		_copyBitmap.text = "copy from sample bitmap";
		_copyBitmap.dock = DockStyle.TOP;
		_copyBitmap.click ~= (Control c, EventArgs e)
		{
			_textbox.clear();
			Bitmap bitmap = new Bitmap(r".\image\sample.bmp");

			// *** Traditional method ***
			// import core.sys.windows.winuser;
			// OpenClipboard(null);
			// EmptyClipboard();
			// SetClipboardData(CF_BITMAP, bitmap.handle);
			// CloseClipboard();
			Clipboard.setImage(bitmap);

			_picturebox.image = bitmap;
		};

		static if (0) // BUG: Don't work. Explorer makes hungup.
		{
			_copyFileDrop = new Button();
			_copyFileDrop.parent = _leftSide;
			_copyFileDrop.text = "copy as FileDrop";
			_copyFileDrop.dock = DockStyle.TOP;
			_copyFileDrop.click ~= (Control c, EventArgs e)
			{
				_picturebox.image = null;
				_textbox.clear();
				string[] fileNames = [getFullPathName(r".\image\sample.bmp")];
				Clipboard.setFileDropList(fileNames);
			};
		}

		_paste = new Button();
		_paste.parent = _leftSide;
		_paste.text = "paste to textbox/picturebox";
		_paste.dock = DockStyle.TOP;
		_paste.click ~= (Control c, EventArgs e)
		{
			IDataObject dataObj = Clipboard.getDataObject();
			
			// bitmap
			if (Clipboard.containsImage())
			{
				Data data = dataObj.getData(DataFormats.bitmap, false);
				Image image = data.getImage();
				if (image !is null)
				{
					_textbox.clear();
					_textbox.appendText = "Read as bitmap\r\n";
					_textbox.appendText = "---\r\n";
					_picturebox.image = image;
					return;
				}
			}

			// file drop (When select files and input ctrl+C on Explorer)
			if (Clipboard.containsFileDropList())
			{
				Data data = dataObj.getData(DataFormats.fileDrop, false);
				string[] fileDropList = data.getFileDropList();
				if (fileDropList !is null)
				{
					_textbox.clear();
					_textbox.appendText = "Read as FileDrop\r\n";
					_textbox.appendText = "---\r\n";
					_picturebox.image = null;
					string result;
					foreach (string item; fileDropList)
					{
						result ~= item;
						result ~= "\r\n";
					}
					_textbox.appendText = result;
					return;
				}
			}

			// utf8 text
			if (Clipboard.containsString())
			{
				string utf8Str = Clipboard.getString();
				if (utf8Str !is null)
				{
					_textbox.clear();
					_textbox.appendText = "Read as UTF-8 string\r\n";
					_textbox.appendText = "---\r\n";
					_textbox.appendText = utf8Str;
					return;
				}
			}

			// unicode text (utf16)
			if (Clipboard.containsData(DataFormats.unicodeText))
			{
				Data data = Clipboard.getData(DataFormats.unicodeText);
				wstring str = data.getUnicodeText();
				if (str !is null)
				{
					_textbox.clear();
					_textbox.appendText = "Read as UnicodeText\r\n";
					_textbox.appendText = "---\r\n";
					_textbox.appendText = toUTF8(str);
					return;
				}
			}

			// ansi text
			if (Clipboard.containsText())
			{
				enum ubyte[] UBYTE_ZERO = [0];
				ubyte[] ansiStrz = Clipboard.getText() ~ UBYTE_ZERO; // Add \0 terminal
				if (ansiStrz !is null)
				{
					_textbox.clear();
					_textbox.appendText = "Read as AnsiText\r\n";
					_textbox.appendText = "---\r\n";
					_textbox.appendText = dfl.internal.utf.fromAnsiz(cast(char*)ansiStrz.ptr);
					return;
				}
			}
		};

		_clear = new Button();
		_clear.parent = _leftSide;
		_clear.text = "clear previews and clipboard";
		_clear.dock = DockStyle.TOP;
		_clear.click ~= (Control c, EventArgs e)
		{
			_textbox.clear();
			_picturebox.image = null;
			Clipboard.clear();
		};

		_formats = new Button();
		_formats.parent = _leftSide;
		_formats.text = "show formats on clipboard";
		_formats.dock = DockStyle.TOP;
		_formats.click ~= (Control c, EventArgs e)
		{
			_textbox.clear();
			IDataObject dataObj = Clipboard.getDataObject();
			foreach (string f; dataObj.getFormats())
			{
				_textbox.appendText = "[";
				_textbox.appendText = f;
				_textbox.appendText = "]";
				_textbox.appendText = "\r\n";
			}
		};

		_flush = new Button();
		_flush.parent = _leftSide;
		_flush.text = "flush clipboard";
		_flush.dock = DockStyle.TOP;
		_flush.click ~= (Control c, EventArgs e)
		{
			// NOTE: Call after Clipboard.setDataObject().
			Clipboard.flush();
		};
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
