import dfl; import std.concurrency;

version(Have_dfl) // For DUB.
{
}
else
{
	pragma(lib, "dfl.lib");
}

class MainForm : Form
{
	private Label _headerLabel;
	private Label _alarmLabel1;
	private Label _alarmLabel2;

	private ToggleSwitch _headerSwitch;
	private ToggleSwitch _alarmSwitch1;
	private ToggleSwitch _alarmSwitch2;

	this()
	{
		this.text = "ToggleSwitch example";
		this.size = Size(500, 500);

		Font labelFont = new Font("Yu Gothic UI", 24.0);

		_headerLabel = new Label;
		_headerLabel.font = labelFont;
		_headerLabel.location = Point(10, 5);
		_headerLabel.text = "Alarm";
		_headerLabel.autoSize = true;
		_headerLabel.parent = this;

		_alarmLabel1 = new Label;
		_alarmLabel1.font = labelFont;
		_alarmLabel1.location = Point(50, 105);
		_alarmLabel1.text = "AM 07:00";
		_alarmLabel1.autoSize = true;
		_alarmLabel1.parent = this;

		_alarmLabel2 = new Label;
		_alarmLabel2.font = labelFont;
		_alarmLabel2.location = Point(50, 205);
		_alarmLabel2.text = "AM 07:30";
		_alarmLabel2.autoSize = true;
		_alarmLabel2.parent = this;

		Size switchSize = Size(100, 60);

		_headerSwitch = new ToggleSwitch;
		_headerSwitch.location = _headerLabel.location + Point(360, 5);
		_headerSwitch.size = switchSize;
		_headerSwitch.isOn = true;
		_headerSwitch.toggle ~= (ToggleSwitch ts, ToggledEventArgs ea) {
			_alarmSwitch1.enabled = !_alarmSwitch1.enabled;
			_alarmSwitch1.redraw();
			_alarmSwitch2.enabled = !_alarmSwitch2.enabled;
			_alarmSwitch2.redraw();
		};
		_headerSwitch.thumbColorOff = Color.red;
		_headerSwitch.baseColorOn = Color.red;
		_headerSwitch.parent = this;

		_alarmSwitch1 = new ToggleSwitch;
		_alarmSwitch1.location = _alarmLabel1.location + Point(320, 5);
		_alarmSwitch1.size = switchSize;
		_alarmSwitch1.isOn = true;
		_alarmSwitch1.parent = this;

		_alarmSwitch2 = new ToggleSwitch;
		_alarmSwitch2.location = _alarmLabel2.location + Point(320, 5);
		_alarmSwitch2.size = switchSize;
		_alarmSwitch2.isOn = false;
		_alarmSwitch2.parent = this;
	}
}

void main(string[] args)
{
		Application.enableVisualStyles();

		import dfl.internal.dpiaware;
		SetProcessDpiAwarenessContext(DPI_AWARENESS_CONTEXT_PER_MONITOR_AWARE_V2);

		Application.run(new MainForm()); // Show your main form.
}	
