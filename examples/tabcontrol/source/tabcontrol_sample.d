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
	private TabControl _tab;
	private Label _label1;
	private Label _label2;
	private Button _button1;
	private Button _button2;

	this()
	{
		this.text = "TabControl example";
		this.size = Size(300, 300);
		this.formBorderStyle = FormBorderStyle.SIZABLE;
		this.maximizeBox = false;

		_tab = new TabControl();
		_tab.dock = DockStyle.FILL;
		// _tab.size = Size(200, 200);
		_tab.multiline = true;
		_tab.parent = this;

		// First tab
		TabPage _page1 = new TabPage("First tab name");
		_tab.tabPages.add(_page1);

		_label1 = new Label();
		_label1.text = "First tab";
		_label1.parent = _page1;

		_button1 = new Button;
		_button1.text = "Insert tab";
		_button1.size = Size(200, 60);
		_button1.location = Point(20, 50);
		_button1.click ~= (Control c, EventArgs e) {
			_tab.tabPages.add(new TabPage("Inserted tab"));
			_page1.text = "Changed tab name";
		};
		_button1.parent = _page1;

		// Second tab
		TabPage _page2 = new TabPage("Second tab name");
		_tab.tabPages.add(_page2);

		_label2 = new Label();
		_label2.text = "Second tab";
		_label2.parent = _page2;

		_button2 = new Button;
		_button2.text = "Close application";
		_button2.size = Size(200, 60);
		_button2.location = Point(20, 50);
		_button2.click ~= (Control c, EventArgs e) {
			Application.exit();
		};
		_button2.parent = _page2;
	}
}

void main()
{
	Application.enableVisualStyles();
	Application.setHighDpiMode(HighDpiMode.PER_MONITOR_V2);
	Application.run(new MainForm());
}
