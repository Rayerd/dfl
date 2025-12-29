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
	private StatusBar _statusBar;

	this()
	{
		this.text = "StatusBar example";
		this.size = Size(300, 300);

		_statusBar = new StatusBar();

		StatusBarPanel panel1 = new StatusBarPanel("Click count:");
		StatusBarPanel panel2 = new StatusBarPanel("Second panel");
		StatusBarPanel panel3 = new StatusBarPanel("Third panel");

		panel1.borderStyle = StatusBarPanelBorderStyle.SUNKEN;
		panel2.borderStyle = StatusBarPanelBorderStyle.RAISED;
		panel3.borderStyle = StatusBarPanelBorderStyle.NONE;

		panel1.width = 100;

		_statusBar.panels.add(panel1);
		_statusBar.panels.add(panel2);
		_statusBar.panels.add(panel3);

		_statusBar.showPanels = true;
		_statusBar.parent = this;

		this.click ~= (Control c, EventArgs e) {
			static int counter;
			panel1.text = "Click count: " ~ to!string(++counter);
		};
	}
}

void main()
{
	Application.enableVisualStyles();
	Application.setHighDpiMode(HighDpiMode.PER_MONITOR_V2);
	Application.run(new MainForm());
}
