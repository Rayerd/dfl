import dfl;

class MainForm : Form
{
	private StackPanel _contentPanel;
	private Panel[] _configPanels;
	private Button _changeOrientaionButton;

	private enum DEFAULT_PANEL_SIZE = Size(240, 80);

	this()
	{
		this.text = "LocationAlignment example";
		this.size = Size(1200, 500);
		this.minimumSize = Size(400, 400);

		_contentPanel = new StackPanel;
		_contentPanel.orientation = Orientation.VERTICAL;
		_contentPanel.dock = DockStyle.FILL;
		_contentPanel.dockPadding.all = 10;
		_contentPanel.parent = this;

		_configPanels ~= createSwitchConfigPanel("Top Left Label");
		_configPanels ~= createSwitchConfigPanel("Top Left Label");
		_configPanels ~= createComboBoxConfigPanel("Middle Center Label", ["Option 1", "Option 2", "Option 3", "Option 4", "Option 5"]);
		_configPanels ~= createButtonConfigPanel("Bottom Center Label", "Rotate", &rotateOrientaion);

		foreach (panel; _configPanels)
			_contentPanel.add(panel);
	}

	static Panel createSwitchConfigPanel(string name)
	{
		Panel p = new Panel;
		p.backColor = SystemColors.controlLightLight;
		p.borderStyle = BorderStyle.FIXED_SINGLE;
		p.dockPadding.all = 10;
		p.dockMargin.right = 10;
		p.dockMargin.bottom = 10;
		p.size = DEFAULT_PANEL_SIZE;

		Label label = new Label;
		label.text = name;
		label.autoSize = true;
		label.locationAlignment = LocationAlignment.TOP_LEFT;
		label.parent = p;

		ToggleSwitch sw = new ToggleSwitch;
		sw.width = 100;
		sw.height = 50;
		sw.locationAlignment = LocationAlignment.MIDDLE_RIGHT;
		sw.parent = p;

		return p;
	}

	static Panel createComboBoxConfigPanel(string name, string[] items)
	{
		Panel p = new Panel;
		p.backColor = SystemColors.controlLightLight;
		p.borderStyle = BorderStyle.FIXED_SINGLE;
		p.dockPadding.all = 10;
		p.dockMargin.right = 10;
		p.dockMargin.bottom = 10;
		p.size = DEFAULT_PANEL_SIZE;

		Label label = new Label;
		label.text = name;
		label.autoSize = true;
		label.locationAlignment = LocationAlignment.TOP_CENTER;
		label.parent = p;

		ComboBox cb = new ComboBox;
		cb.dropDownStyle = ComboBoxStyle.DROP_DOWN_LIST;
		cb.width = 120;
		cb.locationAlignment = LocationAlignment.MIDDLE_RIGHT;
		cb.items.addRange(items);
		cb.text = items[0]; // initial selected item text
		cb.selectedIndex = 0; // initial selected item
		cb.parent = p;

		return p;
	}

	static Panel createButtonConfigPanel(string name, string text, void delegate(Control, EventArgs) clickEvent)
	{
		Panel p = new Panel;
		p.backColor = SystemColors.controlLightLight;
		p.borderStyle = BorderStyle.FIXED_SINGLE;
		p.dockPadding.all = 10;
		p.dockMargin.right = 10;
		p.dockMargin.bottom = 10;
		p.size = DEFAULT_PANEL_SIZE;

		Label label = new Label;
		label.text = name;
		label.autoSize = true;
		label.locationAlignment = LocationAlignment.BOTTOM_CENTER;
		label.parent = p;

		Button b = new Button;
		b.text = text;
		b.width = 120;
		b.height = 60;
		b.locationAlignment = LocationAlignment.MIDDLE_RIGHT;
		b.click ~= clickEvent;
		b.parent = p;

		return p;
	}

	void rotateOrientaion(Control c, EventArgs e)
	{
		if (_contentPanel.orientation != Orientation.HORIZONTAL)
			_contentPanel.orientation = Orientation.HORIZONTAL;
		else
			_contentPanel.orientation = Orientation.VERTICAL;
		
		// NOTE: Reset panel size to default after orientation changed.
		foreach (panel; _configPanels)
			panel.size = DEFAULT_PANEL_SIZE;
	}
}

void main(string[] args)
{
		Application.enableVisualStyles();

		import dfl.internal.dpiaware;
		SetProcessDpiAwarenessContext(DPI_AWARENESS_CONTEXT_PER_MONITOR_AWARE_V2);

		Application.run(new MainForm());
}
