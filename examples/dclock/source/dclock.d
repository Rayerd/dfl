import dfl;

import dfl.internal.dpiaware;

import std.format;
import std.datetime;

class MainForm : Form
{
	private Label _label;
	private Timer _timer;

	public this()
	{
		this.text = "Dclock";
		this.size = Size(220, 120);
		this.formBorderStyle = FormBorderStyle.FIXED_SINGLE;
		this.maximizeBox = false;
		this.topMost = true;

		_label = new Label;
		_label.location = Point(0, 0);
		_label.font = new Font("MS Gothic", 30f);
		_label.autoSize = true;
		_label.parent = this;
		_drawClock();

		_timer = new Timer;
		_timer.interval = 1000;
		_timer.start();
		_timer.tick ~= (Timer t, EventArgs e) {
			_drawClock();
		};
	}

	private void _drawClock()
	{
		DateTime now = cast(DateTime)Clock.currTime();
		_label.text = format(
			"%.4d/%.2d/%.2d\n(%s)%.2d:%.2d",
			now.year, now.month, now.day,
			["日","月","火","水","木","金","土"][now.dayOfWeek],
			now.hour, now.minute);
	}

}

void main()
{
	Application.enableVisualStyles();
	Application.setHighDpiMode(HighDpiMode.PER_MONITOR_V2);
	Application.run(new MainForm());
}
