import dfl;
import std.conv;

version(Have_dfl) // For DUB.
{
}
else
{
	pragma(lib, "dfl.lib");
}

class MainForm : Form
{
	private RichTextBox _textbox1;
	private ToolBar _toolBar;

	this()
	{
		// Form setting
		this.text = "RichTextBox sample";
		this.size = Size(800,400);
		
		// ToolBar setting
		_toolBar = new ToolBar;
		_toolBar.parent = this;
		_toolBar.buttonSize = Size(30, 30);
		_toolBar.dock = DockStyle.TOP;

		ToolBarButton button1 = new ToolBarButton("Bold");
		_toolBar.buttonClick ~= (ToolBar tb, ToolBarButtonClickEventArgs e) {
			if (e.button is button1)
				_textbox1.selectionBold = !_textbox1.selectionBold;
		};
		_toolBar.buttons.add(button1);

		ToolBarButton button2 = new ToolBarButton("UnderLine");
		_toolBar.buttonClick ~= (ToolBar tb, ToolBarButtonClickEventArgs e) {
			if (e.button is button2)
				_textbox1.selectionUnderline = !_textbox1.selectionUnderline;
		};
		_toolBar.buttons.add(button2);

		ToolBarButton button3 = new ToolBarButton("Font");
		_toolBar.buttonClick ~= (ToolBar tb, ToolBarButtonClickEventArgs e) {
			if (e.button is button3)
			{
				auto fontDialog = new FontDialog;
				DialogResult dr = fontDialog.showDialog();
				if (dr == DialogResult.OK)
					_textbox1.selectionFont = fontDialog.font;
			}
		};
		_toolBar.buttons.add(button3);

		ToolBarButton button4 = new ToolBarButton("BaseUp");
		_toolBar.buttonClick ~= (ToolBar tb, ToolBarButtonClickEventArgs e) {
			if (e.button is button4)
			{
				if (_textbox1.selectionCharOffset <= 0)
					_textbox1.selectionCharOffset = 72;
				else
					_textbox1.selectionCharOffset = 0;
			}
		};
		_toolBar.buttons.add(button4);

		ToolBarButton button5 = new ToolBarButton("BaseDown");
		_toolBar.buttonClick ~= (ToolBar tb, ToolBarButtonClickEventArgs e) {
			if (e.button is button5)
			{
				if (_textbox1.selectionCharOffset >= 0)
					_textbox1.selectionCharOffset = -72;
				else
					_textbox1.selectionCharOffset = 0;
			}
		};
		_toolBar.buttons.add(button5);

		ToolBarButton buton6 = new ToolBarButton("F.Color");
		_toolBar.buttonClick ~= (ToolBar tb, ToolBarButtonClickEventArgs e) {
			if (e.button is buton6)
			{
				auto colorDialog = new ColorDialog;
				DialogResult dr = colorDialog.showDialog();
				if (dr == DialogResult.OK)
					_textbox1.selectionColor = colorDialog.color;
			}
		};
		_toolBar.buttons.add(buton6);

		ToolBarButton button7 = new ToolBarButton("B.Color");
		_toolBar.buttonClick ~= (ToolBar tb, ToolBarButtonClickEventArgs e) {
			if (e.button is button7)
			{
				auto colorDialog = new ColorDialog;
				DialogResult dr = colorDialog.showDialog();
				if (dr == DialogResult.OK)
					_textbox1.selectionBackColor = colorDialog.color;
			}
		};
		_toolBar.buttons.add(button7);

		ToolBarButton button8 = new ToolBarButton("^X");
		_toolBar.buttonClick ~= (ToolBar tb, ToolBarButtonClickEventArgs e) {
			if (e.button is button8)
			{
				_textbox1.selectionSuperscript = !_textbox1.selectionSuperscript;
			}
		};
		_toolBar.buttons.add(button8);

		ToolBarButton button9 = new ToolBarButton("_X");
		_toolBar.buttonClick ~= (ToolBar tb, ToolBarButtonClickEventArgs e) {
			if (e.button is button9)
			{
				_textbox1.selectionSubscript = !_textbox1.selectionSubscript;
			}
		};
		_toolBar.buttons.add(button9);

		ToolBarButton button10 = new ToolBarButton("GetText");
		_toolBar.buttonClick ~= (ToolBar tb, ToolBarButtonClickEventArgs e) {
			if (e.button is button10)
			{
				msgBox(_textbox1.selectedText);
			}
		};
		_toolBar.buttons.add(button10);

		ToolBarButton button11 = new ToolBarButton("InsText");
		_toolBar.buttonClick ~= (ToolBar tb, ToolBarButtonClickEventArgs e) {
			if (e.button is button11)
			{
				_textbox1.selectedText = "[Insert Text]";
			}
		};
		_toolBar.buttons.add(button11);

		ToolBarButton buton12 = new ToolBarButton("GetRtf");
		_toolBar.buttonClick ~= (ToolBar tb, ToolBarButtonClickEventArgs e) {
			if (e.button is buton12)
			{
				static if (1)
				{
					string rtf = _textbox1.selectedRtf;
				}
				else
				{
					string rtf = _textbox1.rtf;
				}
				msgBox(rtf);

				static if (0)
				{
					_textbox1.rtf = rtf;
				}
			}
		};
		_toolBar.buttons.add(buton12);

		ToolBarButton button13 = new ToolBarButton("GetSelNum");
		_toolBar.buttonClick ~= (ToolBar tb, ToolBarButtonClickEventArgs e) {
			if (e.button is button13)
			{
				msgBox(to!string(_textbox1.selectionLength));
			}
		};
		_toolBar.buttons.add(button13);

		ToolBarButton button14 = new ToolBarButton("SetSel(5)");
		_toolBar.buttonClick ~= (ToolBar tb, ToolBarButtonClickEventArgs e) {
			if (e.button is button14)
			{
				_textbox1.selectionLength = 5;
			}
		};
		_toolBar.buttons.add(button14);

		// RichTextBox setting
		_textbox1 = new RichTextBox();
		_textbox1.dock = DockStyle.FILL;
		_textbox1.font = new Font(_textbox1.font.name, 14f);
		_textbox1.multiline = true;
		_textbox1.scrollBars = RichTextBoxScrollBars.FORCED_VERTICAL;
		// _textbox1.acceptsReturn = true; // true: Enables RETURN key.
		_textbox1.acceptsTab = true; // false: Disables TAB key.
									 // true: Enables TAB key. But be changed focus only
									 //       because one line textbox is not able to input TAB char.
		_textbox1.wordWrap = false; // false: Do not send words that span the right edge to the next line.
		_textbox1.text = "Hello.\nhttp://g/ <- click\nこんにちは。";
		_textbox1.linkClicked ~= (RichTextBox sender, LinkClickedEventArgs e) {
			msgBox(e.linkText);
		};
		_textbox1.parent = this;
	}
}

void main()
{
	Application.enableVisualStyles();
	Application.setHighDpiMode(HighDpiMode.PER_MONITOR_V2);
	Application.run(new MainForm());
}
