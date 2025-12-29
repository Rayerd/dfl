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
	private Label _label;

	public this()
	{
		this.text = "Scrollbar example";
		this.size = Size(400, 200);
		this.hScroll = true;
		this.vScroll = true;
		Rect bounds = Screen.primaryScreen.bounds;
		this.scrollSize = Size(bounds.width, bounds.height);
		
		_label = new Label;
		_label.text =
			"Long long long long long long long long long\n" ~
			"long long long long long long long long long\n" ~
			"long long long long long long long long long\n" ~
			"long long long long long long long long long text";
		_label.autoSize = true;
		_label.location = Point(50, 50);
		_label.parent = this;
	}
}

void main()
{
	Application.enableVisualStyles();
	Application.setHighDpiMode(HighDpiMode.PER_MONITOR_V2);
	Application.run(new MainForm());
}
