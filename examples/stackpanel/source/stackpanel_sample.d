import dfl;
class MainForm : Form
{
	private StackPanel _sidePanel;
	private StackPanel _headerPanel;
	private StackPanel _contentPanel;

	this()
	{
		this.text = "StackPanel example";
		this.size = Size(500, 500);

		//
		// Create side panel.
		//
		_sidePanel = new StackPanel;

		_sidePanel.orientation = Orientation.VERTICAL;
		// _sidePanel.orientation = Orientation.VERTICAL_INVERSE; // Extra.
		// _sidePanel.orientation = Orientation.HORIZONTAL;
		// _sidePanel.orientation = Orientation.HORIZONTAL_INVERSE; // Extra.

		_sidePanel.width = 150;
		// _sidePanel.height = 150;
		_sidePanel.dock = DockStyle.LEFT;
		_sidePanel.backColor = SystemColors.controlLight;
		_sidePanel.parent = this;
		_sidePanel.dockPadding.all = 10;

		for (size_t i; i < 5; ++i)
		{
			Button b = new Button;
			b.text = ["Settings", "Name", "Address", "Tel", "Email"][i];
			b.height = 50;
			b.dockMargin.bottom = 10;
			// b.dockMargin.right = 10;
			_sidePanel.add(b);

			if (i == 0)
			{
				Separator s = new Separator;
				s.dockMargin.bottom = 10;
				// s.dockMargin.right = 10;
				_sidePanel.add(s);
			}
		}

		//
		// Create header and content panels.
		//
		_headerPanel = new StackPanel;
		_headerPanel.dock = DockStyle.TOP;
		_headerPanel.dockMargin.all = 10;
		_headerPanel.paint ~= (Control c, PaintEventArgs e) {
			Graphics g = e.graphics;
			Rect rect = c.displayRectangle;
			g.drawRectangle(new Pen(SystemColors.controlDarkDark), rect);
			rect.inflate(-10, -10);
			g.drawText("TOP docking area", new Font("MS Gothic", 20f), Color.black, rect);
		};
		_headerPanel.resizeRedraw = true; // For owner-draw on resize.
		// _headerPanel.width = 200;
		_headerPanel.height = 100;
		_headerPanel.parent = this;

		_contentPanel = new StackPanel;
		_contentPanel.dock = DockStyle.FILL;
		_contentPanel.dockMargin.all = 10;
		_contentPanel.paint ~= (Control c, PaintEventArgs e) {
			Graphics g = e.graphics;
			Rect rect = c.displayRectangle;
			g.drawRectangle(new Pen(SystemColors.controlDarkDark), rect);
			rect.inflate(-10, -10);
			g.drawText("FILL docking area", new Font("MS Gothic", 20f), Color.black, rect);
		};
		_contentPanel.resizeRedraw = true; // For owner-draw on resize.
		_contentPanel.parent = this;
	}
}

void main(string[] args)
{
		Application.enableVisualStyles();

		import dfl.internal.dpiaware;
		SetProcessDpiAwarenessContext(DPI_AWARENESS_CONTEXT_PER_MONITOR_AWARE_V2);

		Application.run(new MainForm());
}
