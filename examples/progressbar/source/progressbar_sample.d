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
	private ProgressBar _progress;
	private Button _incre;
	private Button _reset;
	private ComboBox _mode;

	public this()
	{
		this.text = "ProgressBar example";
		this.size = Size(300, 300);

		_progress = new ProgressBar();
		_progress.parent = this;
		_progress.location = Point(20, 100);
		_progress.size = Size(200, 30);
		_progress.minimum = 0;
		_progress.maximum = 100;
		_progress.step = 5;
		_progress.value = 50;
		_progress.marqueeAnimationSpeed = 0; // Default; 30 ms.

		_mode = new ComboBox();
		_mode.parent =  this;
		_mode.location = Point(20, 150);
		_mode.dropDownStyle = ComboBoxStyle.DROP_DOWN_LIST;
		_mode.items.add("BLOCKS");
		_mode.items.add("CONTINUOUS");
		_mode.items.add("MARQUEE");
		_mode.selectedIndex = 0;
		_mode.selectedValueChanged ~= (Control c, EventArgs e)
		{
			if (_mode.selectedItem.toString() == "BLOCKS")
			{
				_progress.style = ProgressBarStyle.BLOCKS; // On visual styles, same as CONTINUOUS.
			}
			else if (_mode.selectedItem.toString() == "CONTINUOUS")
			{
				_progress.style = ProgressBarStyle.CONTINUOUS; // Classic Styles only.
			}
			else if (_mode.selectedItem.toString() == "MARQUEE")
			{
				_progress.style = ProgressBarStyle.MARQUEE; // Visual styles only.
			}
		};

		_incre = new Button();
		_incre.parent = this;
		_incre.location = Point(20, 20);
		_incre.text = "Increment";
		_incre.click ~= (Control c, EventArgs e)
		{
			if (_progress.style == ProgressBarStyle.MARQUEE)
				msgBox("Can't increment.");
			else
			{
				// Advances the current position of the progress bar by the amount of the Step property.
				_progress.performStep();
				// Advances the current position of the progress bar by the specified amount.
				_progress.increment(5);
			}
		};

		_reset = new Button();
		_reset.parent = this;
		_reset.location = Point(120, 20);
		_reset.text = "Reset";
		_reset.click ~= (Control c, EventArgs e)
		{
			if (_progress.style == ProgressBarStyle.MARQUEE)
				msgBox("Can't reset.");
			else
				_progress.value = 50;
		};
	}
}

static this()
{
	Application.enableVisualStyles(); // Apply visual styles.
}

void main()
{
	Application.run(new MainForm());
}
