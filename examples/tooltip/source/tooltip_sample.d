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
	private ToolTip _tip1;
	private ToolTip _tip2;
	private ToolTip _tip3;
	private Button _button1;
	private Button _button2;
	private Button _button3;

	public this()
	{
		this.text = "ToolTip example";
		this.size = Size(350, 300);

		_button1 = new Button();
		_button1.parent = this;
		_button1.location = Point(10,10);
		_button1.text = "Button 1";

		_button2 = new Button();
		_button2.parent = this;
		_button2.location = Point(10,50);
		_button2.text = "Button 2";

		_button3 = new Button();
		_button3.parent = this;
		_button3.location = Point(10,90);
		_button3.text = "Button 3";

		_tip1 = new ToolTip();
		_tip1.initialDelay = 500;
		_tip1.reshowDelay = 100;
		_tip1.autoPopDelay = 2000;
		_tip1.showAlways = true;
		_tip1.isBalloon = true;
		_tip1.maxWidth = 300;
		_tip1.setToolTip(_button1,
			"This unofficial project is a migration of D Forms Library (DFL) that is managed on SVN. \n" ~
			"DFL is a Win32 windowing library for the D language.");

		_tip2 = new ToolTip();
		_tip2.showAlways = true;
		_tip2.automaticDelay = 100; // initialDelay = 100, autoPopDelay = 1000, reshowDelay = 20
		_tip2.stripAmpersands = true; // bye (&X) => bye (X)
		_tip2.useAnimation = true;
		_tip2.useFading = false;
		_tip2.setToolTip(_button2, "bye (&X)");

		_tip3 = new ToolTip();
		_tip3.showAlways = true;
		_tip3.isBalloon = true;
		_tip3.useFading = true;
		_tip3.toolTipIcon = ToolTipIcon.INFO_LARGE;
		_tip3.toolTipTitle = "Link";
		_tip3.setToolTip(_button3, "https://github.com/Rayerd/dfl");
	}
}

void main()
{
	Application.enableVisualStyles();
	Application.setHighDpiMode(HighDpiMode.PER_MONITOR_V2);
	Application.run(new MainForm());
}
