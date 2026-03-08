import dfl;

import std.datetime;

class MainForm : Form
{
	DateTimePicker _dt;
	Button _checkBoxButton;
	Button _upDownButton;
	Button _longFormatButton;
	Button _shortFormatButton;
	Button _customFormatButton;
	Button _timeFormatButton;
	StackPanel _datetimePanel;
	StackPanel _commandPanel;

	this()
	{
		this.text = "DateTimePicker example";
		this.size = Size(500, 300);

		_datetimePanel = new StackPanel;
		_datetimePanel.parent = this;
		_datetimePanel.borderStyle = BorderStyle.FIXED_SINGLE;
		_datetimePanel.size = Size(300, 100);
		_datetimePanel.dock = DockStyle.TOP;

		_commandPanel = new StackPanel;
		_commandPanel.parent = this;
		_commandPanel.borderStyle = BorderStyle.FIXED_SINGLE;
		_commandPanel.size = Size(300, 50);
		_commandPanel.dock = DockStyle.TOP;
		_commandPanel.orientation = Orientation.HORIZONTAL;

		_checkBoxButton = new Button;
		_checkBoxButton.text = "CheckBox";
		_checkBoxButton.click ~= (Control c, EventArgs e) {
			_dt.showCheckBox = !_dt.showCheckBox;
		};
		_commandPanel.add(_checkBoxButton);

		_upDownButton = new Button;
		_upDownButton.text = "UpDown";
		_upDownButton.click ~= (Control c, EventArgs e) {
			_dt.showUpDown = !_dt.showUpDown;
		};
		_commandPanel.add(_upDownButton);

		_longFormatButton = new Button;
		_longFormatButton.text = "Long";
		_longFormatButton.click ~= (Control c, EventArgs e) {
			_dt.format = DateTimePickerFormat.LONG;
		};
		_commandPanel.add(_longFormatButton);

		_shortFormatButton = new Button;
		_shortFormatButton.text = "Short";
		_shortFormatButton.click ~= (Control c, EventArgs e) {
			_dt.format = DateTimePickerFormat.SHORT;
		};
		_commandPanel.add(_shortFormatButton);

		_customFormatButton = new Button;
		_customFormatButton.text = "Custom";
		_customFormatButton.click ~= (Control c, EventArgs e) {
			_dt.format = DateTimePickerFormat.CUSTOM;
			_dt.customFormat = "yyyy'/'MM'/'dd HH':'mm':'ss";
		};
		_commandPanel.add(_customFormatButton);

		_timeFormatButton = new Button;
		_timeFormatButton.text = "Time";
		_timeFormatButton.click ~= (Control c, EventArgs e) {
			_dt.format = DateTimePickerFormat.TIME;
		};
		_commandPanel.add(_timeFormatButton);

		_dt = new DateTimePicker();
		_dt.parent = _datetimePanel;
		_dt.size = Size(300, 21);
		_dt.valueChanged ~= (Control c, EventArgs e) {
			if (_dt.value.month != 4)
				_dt.value = DateTime(2027, 4, 1);
			this.text = _dt.value.toISOString;
		};

		this.mouseDown ~= (Control c, EventArgs e) {
			// Test to fix Win32 bug.
			_dt.font = new Font("MS UI Gothic", 12.0f);
		};
		
		this.load ~= (Control c, EventArgs e) {
			_dt.dateMin = DateTime(2026, 4, 1);
			_dt.dateMax = DateTime(2027, 5, 10);
		};
	}
}

void main()
{
	Application.enableVisualStyles();
	Application.setHighDpiMode(HighDpiMode.PER_MONITOR_V2);
	Application.run(new MainForm());
}
