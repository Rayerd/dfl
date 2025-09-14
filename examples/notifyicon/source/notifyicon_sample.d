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
	private Button _button;
	private NotifyIcon _notifyIcon;

	public this()
	{
		this.text = "NotifyIcon example";
		this.size = Size(300, 250);

		_button = new Button;
		_button.text = "Show toast";
		_button.location = Point(50, 50);
		_button.size = Size(150, 60);
		_button.parent = this;
		_button.click ~= (Control c, EventArgs e) {
			_notifyIcon.showBalloonTip();
		};

		MenuItem menuItem1 = new MenuItem("Show");
		menuItem1.click ~= (MenuItem mi, EventArgs e) {
			msgBox("Hi!");
		};

		MenuItem menuItem2 = new MenuItem("Close");
		menuItem2.click ~= (MenuItem mi, EventArgs e) {
			this.close();
		};

		_notifyIcon = new NotifyIcon;
		_notifyIcon.contextMenu = new ContextMenu;
		_notifyIcon.contextMenu.menuItems.add(menuItem1);
		_notifyIcon.contextMenu.menuItems.add(menuItem2);
		
		_notifyIcon.icon = new Icon(r".\image\icon.ico");
		_notifyIcon.text = "This is tooltip text";
		_notifyIcon.balloonTipTitle = "Balloon tip example";
		_notifyIcon.balloonTipText = "Welcome to the D world!";
		_notifyIcon.balloonTipSound = true;
		static if (false)
		{
			_notifyIcon.balloonTipIconStyle = BalloonTipIconStyle.INFO;
			// _notifyIcon.balloonTipIconStyle = BalloonTipIconStyle.ERROR;
			// _notifyIcon.balloonTipIconStyle = BalloonTipIconStyle.WARNING;
			// _notifyIcon.balloonTipIconStyle = BalloonTipIconStyle.NONE;
		}
		else
		{
			_notifyIcon.balloonTipIconStyle = BalloonTipIconStyle.USER;
			_notifyIcon.balloonTipIcon = new Icon(r".\image\icon2.ico");
		}
		_notifyIcon.click ~= (NotifyIcon ni, EventArgs e) {
			// NOTE: Using .select() event handler is recommended.
			// text = "click";
		};
		_notifyIcon.doubleClick ~= (NotifyIcon ni, EventArgs e) {
			// text = "doubleClick";
		};
		_notifyIcon.mouseDown ~= (NotifyIcon ni, MouseEventArgs e) {
			// text = "mouseDown";
		};
		_notifyIcon.mouseUp ~= (NotifyIcon ni, MouseEventArgs e) {
			// text = "mouseUp";
		};
		_notifyIcon.mouseMove ~= (NotifyIcon ni, MouseEventArgs e) {
			// text = "mouseMove";
		};
		_notifyIcon.balloonTipShown ~= (NotifyIcon ni, EventArgs e) {
			text = "balloonTipShown";
		};
		_notifyIcon.balloonTipClosed ~= (NotifyIcon ni, EventArgs e) {
			text = "balloonTipClosed";
		};
		_notifyIcon.balloonTipClicked ~= (NotifyIcon ni, EventArgs e) {
			text = "balloonTipClicked";
		};
		_notifyIcon.balloonTipTimeout ~= (NotifyIcon ni, EventArgs e) {
			text = "balloonTipTimeout";
		};
		_notifyIcon.select ~= (NotifyIcon ni, MouseEventArgs e) {
			text = "select";
		};
		_notifyIcon.keySelect ~= (NotifyIcon ni, MouseEventArgs e) {
			text = "keySelect";
		};
		_notifyIcon.popupShown ~= (NotifyIcon ni, MouseEventArgs e) {
			text = "popupShown";
		};
		_notifyIcon.popupClosed ~= (NotifyIcon ni, EventArgs e) {
			text = "popupClosed";
		};
		_notifyIcon.show();
	}
}

void main()
{
	Application.enableVisualStyles();

	// NOTE: DPI Awareness
	import dfl.internal.dpiaware;
	SetProcessDpiAwarenessContext(DPI_AWARENESS_CONTEXT_UNAWARE); // OK
	// SetProcessDpiAwarenessContext(DPI_AWARENESS_CONTEXT_UNAWARE_GDISCALED); // ditto
	// SetProcessDpiAwarenessContext(DPI_AWARENESS_CONTEXT_SYSTEM_AWARE); // NG, Windows suppresses the display of balloon tips if DPI awareness mode.
	// SetProcessDpiAwarenessContext(DPI_AWARENESS_CONTEXT_PER_MONITOR_AWARE_V2); // ditto.

	Application.run(new MainForm());
}
