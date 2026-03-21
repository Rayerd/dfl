import dfl;
import dfl.internal.dpiaware;

class MainForm : Form
{
	Expander[] _expanders;

	this()
	{
		this.text = "Expander example";
		this.size = Size(300, 500);
		this.dockPadding.all = 10;

		final Expander makeExpander()
		{
			Expander e = new Expander();
			e.dock = DockStyle.TOP;
			e.parent = this;
			
			e.header.text = "Open Calendar";
			e.header.font = new Font("Segoe UI", 18.0f * dpi / USER_DEFAULT_SCREEN_DPI);

			Label caption = new Label;
			caption.autoSize = true;
			caption.text = "Input Task Subject";
			caption.font = new Font("Segoe UI", 14.0f * dpi / USER_DEFAULT_SCREEN_DPI);
			caption.dockMargin.top = 16;
			caption.dockMargin.bottom = 4;
			caption.dock = DockStyle.TOP;
			caption.parent = e.content;

			TextBox textbox = new TextBox;
			textbox.text = "Place holder text";
			textbox.font = new Font("Segoe UI", 12.0f * dpi / USER_DEFAULT_SCREEN_DPI);
			textbox.size = Size(300, 30);
			textbox.dockMargin.bottom = 16;
			textbox.dock = DockStyle.TOP;
			textbox.borderStyle = BorderStyle.FIXED_SINGLE;
			textbox.parent = e.content;

			MonthCalendar cal = new MonthCalendar;
			cal.dock = DockStyle.TOP;
			cal.parent = e.content;

			e.expanded ~= (Expander c, ExpanderExpandedEventArgs e) {
				this.text = e.isExpanded ? "open" : "close";
			};

			return e;
		}

		_expanders ~= makeExpander();
		_expanders ~= makeExpander();
	}
}

void main()
{
	Application.enableVisualStyles();
	Application.setHighDpiMode(HighDpiMode.PER_MONITOR_V2);
	Application.run(new MainForm());
}
