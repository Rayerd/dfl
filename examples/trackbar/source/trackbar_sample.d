module trackbar_sample;

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
	private Button _button1;
	private Button _button2;
	private TrackBar _trackbar1;
	private TrackBar _trackbar2;

	private enum TRACKBAR_INITIAL_POSITION = 5;
	private enum TRACKBAR_LONG_SIDE = 200;
	private enum TRACKBAR_SHORT_SIDE = 50;
	
	this()
	{
		// Form setting
		text = "TrackBar sample";
		size = Size(500,400);
		resizeRedraw = true;
		
		// Button setting 1
		_button1 = new Button();
		_button1.location = Point(10,10);
		_button1.text = "Reset";
		_button1.click ~= (Control c, EventArgs ea)
		{
			// Initialize TrackBar position
			_trackbar1.value = TRACKBAR_INITIAL_POSITION;
			_trackbar2.value = TRACKBAR_INITIAL_POSITION;

			// If the out side of range is safe.
			// _trackbar1.setRange(10, 20);
			// _trackbar2.setRange(90, 100);
		};
		_button1.parent = this;
		
		// Button setting 2
		_button2 = new Button();
		_button2.location = Point(100,10);
		_button2.text = "Rotate";
		_button2.click ~= (Control c, EventArgs ea)
		{
			// Switch orientation of two TrackBars
			static bool sw = true;
			if (sw)
			{
				_trackbar1.orientation = Orientation.VERTICAL;
				_trackbar2.orientation = Orientation.HORIZONTAL;
				_trackbar1.size = Size(TRACKBAR_SHORT_SIDE, TRACKBAR_LONG_SIDE);
				_trackbar2.size = Size(TRACKBAR_LONG_SIDE, TRACKBAR_SHORT_SIDE);
			}
			else
			{
				_trackbar1.orientation = Orientation.HORIZONTAL;
				_trackbar2.orientation = Orientation.VERTICAL;
				_trackbar1.size = Size(TRACKBAR_LONG_SIDE, TRACKBAR_SHORT_SIDE);
				_trackbar2.size = Size(TRACKBAR_SHORT_SIDE, TRACKBAR_LONG_SIDE);
			}
			sw = !sw;
		};
		_button2.parent = this;

		// TrackBar setting 1
		_trackbar1 = new TrackBar();
		// _trackbar1.orientation = Orientation.HORIZONTAL; // same as default
		// _trackbar1.autoSize = true; // same as default
		_trackbar1.location = Point(10, 80);
		_trackbar1.size = Size(TRACKBAR_LONG_SIDE, TRACKBAR_SHORT_SIDE);
		// _trackbar1.setRange(0, 10); // same as default
		// _trackbar1.smallChange = 1; // same as default
		// _trackbar1.largeChange = 5; // same as default
		// _trackbar1.tickFrequency = 1; // same as default
		// _trackbar1.tickStyle = TickStyle.BottomRight; // same as default
		// _trackbar1.value = 0; // same as default
		// _trackbar1.scroll ~= (TrackBar tb, EventArgs ea) // same as default
		// {
		// 	// Do nothing
		// };
		_trackbar1.valueChanged ~= (TrackBar tb, EventArgs ea) {
			this.text = "TrackBar 1 ValueChanged = " ~ tb.value.to!string();
		};
		_trackbar1.parent = this;

		// TrackBar setting 2
		_trackbar2 = new TrackBar();
		_trackbar2.orientation = Orientation.VERTICAL;
		_trackbar2.autoSize = true; // same as default
		_trackbar2.location = Point(250, 80);
		_trackbar2.size = Size(TRACKBAR_SHORT_SIDE, TRACKBAR_LONG_SIDE);
		_trackbar2.setRange(0, 100);
		_trackbar2.smallChange = 5;
		_trackbar2.largeChange = 10;
		_trackbar2.tickFrequency = 10;
		_trackbar2.tickStyle = TickStyle.BOTH;
		_trackbar2.value = TRACKBAR_INITIAL_POSITION;
		_trackbar2.valueChanged ~= &_onTrackbarValueChanged;
		_trackbar2.parent = this;
	}

	private void _onTrackbarValueChanged(TrackBar tb, EventArgs ea)
	{
		this.text = "TrackBar 2 ValueChanged = " ~ tb.value.to!string();
	}
}

void main()
{
	Application.run(new MainForm());
}
