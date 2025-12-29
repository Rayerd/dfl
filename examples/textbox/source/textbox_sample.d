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
	private TextBox _textbox1;
	private TextBox _textbox2;
	private TextBox _textbox3;
	private TextBox _textbox4;
	private TextBox _textbox5;
	private Button _button1;
	private Button _button2;

	this()
	{
		// Form setting
		text = "TextBox sample";
		size = Size(500,400);
		resizeRedraw = true;
		
		// Button setting (Default button)
		_button1 = new Button();
		_button1.location = Point(10,10);
		_button1.text = "OK";
		_button1.click ~= (Control c, EventArgs e)
		{
			this.text = this.text ~ "+";
		};
		_button1.parent = this;

		// Button setting (Default button's enable/disable is switched).
		_button2 = new Button();
		_button2.location = Point(100,10);
		_button2.text = "On/Off";
		_button2.click ~= (Control c, EventArgs e)
		{
			if(acceptButton)
			{
				acceptButton = null; // Default button is now none.
				_button1.notifyDefault(false);
				_textbox1.text = "Now Off";
			}
			else
			{
				acceptButton = _button1; // Set default button.
				_button1.notifyDefault(true);
				_textbox1.text = "Now On";
			}
		};
		_button2.parent = this;
		
		// TextBox setting (Single line)
		_textbox1 = new TextBox();
		_textbox1.location = Point(200,10);
		_textbox1.size = Size(100,30);
		_textbox1.multiline = false; // false: One line textbox.
		_textbox1.scrollBars = ScrollBars.NONE; // NONE: Without scroll bar.
		_textbox1.acceptsReturn = false; // false: Disables RETURN key.
		_textbox1.acceptsTab = false; // false: Disables TAB key.
									  // true: Enables TAB key. But be changed focus only
									  //       because one line textbox is not able to input TAB char.
		_textbox1.wordWrap = false; // false: Do not send words that span the right edge to the next line.
		_button1.notifyDefault(false); // false: Do not set as default button
		_textbox1.text = "Default Off";
		_textbox1.parent = this;
		
		// TextBox setting (return:yes, tab:yes)
		_textbox2 = new TextBox();
		_textbox2.location = Point(10,60);
		_textbox2.size = Size(450,50);
		_textbox2.multiline = true; // true: Multi line textbox.
		_textbox2.scrollBars = ScrollBars.VERTICAL; // VERTICAL: within vertical scroll bar.
		_textbox2.acceptsReturn = true; // true: Enables RETURN key.
		_textbox2.acceptsTab = true; // true: Enables TAB key.
		_textbox2.wordWrap = true; // true: Send words that span the right edge to the next line.
		_textbox2.text = "return:yes, tab:yes";
		_textbox2.parent = this;

		// TextBox setting (return:yes, tab:no)
		_textbox3 = new TextBox();
		_textbox3.location = Point(10,130);
		_textbox3.size = Size(450,50);
		_textbox3.multiline = true; // false: One line textbox.
		_textbox3.scrollBars = ScrollBars.VERTICAL; // VERTICAL: within vertical scroll bar.
		_textbox3.acceptsReturn = true; // true: Enables RETURN key.
		_textbox3.acceptsTab = false; // false: Disables TAB key.
		_textbox3.wordWrap = true; // true: Send words that span the right edge to the next line.
		_textbox3.text = "return:yes, tab:no";
		_textbox3.parent = this;

		// TextBox setting (return:no, tab:yes)
		_textbox4 = new TextBox();
		_textbox4.location = Point(10,190);
		_textbox4.size = Size(450,50);
		_textbox4.multiline = true; // true: Multi line textbox.
		_textbox4.scrollBars = ScrollBars.VERTICAL; // VERTICAL: within vertical scroll bar.
		_textbox4.acceptsReturn = false; // false: Disables RETURN key.
		_textbox4.acceptsTab = true; // true: Enables TAB key.
		_textbox4.wordWrap = true; // true: Send words that span the right edge to the next line.
		_textbox4.text = "return:no, tab:yes";
		_textbox4.parent = this;

		// TextBox setting (return:no, tab:no)
		_textbox5 = new TextBox();
		_textbox5.location = Point(10,250);
		_textbox5.size = Size(450,50);
		_textbox5.multiline = true; // true: Multi line textbox.
		_textbox5.scrollBars = ScrollBars.VERTICAL; // VERTICAL: within vertical scroll bar.
		_textbox5.acceptsReturn = false; // false: Disables RETURN key.
		_textbox5.acceptsTab = false; // false: Disables TAB key.
		_textbox5.wordWrap = true; // true: Send words that span the right edge to the next line.
		_textbox5.text = "return:no, tab:no";
		_textbox5.parent = this;
	}
}

void main()
{
	Application.enableVisualStyles();
	Application.setHighDpiMode(HighDpiMode.PER_MONITOR_V2);
	Application.run(new MainForm());
}
