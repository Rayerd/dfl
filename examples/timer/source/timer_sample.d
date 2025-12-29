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
	private Label _label;
	private Timer _timer;
	private Button _start;
	private Button _stop;
	private uint _count;

	public this()
	{
		this.text = "Timer example";
		this.size = Size(300, 200);

		_label = new Label;
		_label.location = Point(100, 0);
		_label.font = new Font("Verdana", 50f);
		_label.autoSize = true;
		_label.text = to!string(_count);
		_label.parent = this;

		_timer = new Timer;
		_timer.interval = 1000;
		_timer.tick ~= (Timer t, EventArgs e) {
			_label.text = to!string(_count);
			_count++;
		};

		_start = new Button;
		_start.text = "Start";
		_start.location = Point(10, 10);
		_start.click ~= (Control c, EventArgs e) {
			_timer.start();
		};
		_start.parent = this;

		_stop = new Button;
		_stop.text = "Stop";
		_stop.location = Point(10, 50);
		_stop.click ~= (Control c, EventArgs e) {
			_timer.stop();
		};
		_stop.parent = this;
	}
}

void main()
{
	Application.enableVisualStyles();
	Application.setHighDpiMode(HighDpiMode.PER_MONITOR_V2);
	Application.run(new MainForm());
}
