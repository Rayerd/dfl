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
	private NotifyIcon _notifyIcon;

	public this()
	{
		this.text = "NotifyIcon example";
		this.size = Size(300, 200);
		
		MenuItem menuItem1 = new MenuItem("Show");
		menuItem1.click ~= (MenuItem mi, EventArgs e) { msgBox("Hi!"); };

		MenuItem menuItem2 = new MenuItem("Close");
		menuItem2.click ~= (MenuItem mi, EventArgs e) { this.close(); };
		
		_notifyIcon = new NotifyIcon;
		_notifyIcon.icon = new Icon(r".\image\icon.ico");
		_notifyIcon.text = "This is tooltip text";
		_notifyIcon.contextMenu = new ContextMenu;
		_notifyIcon.contextMenu.menuItems.add(menuItem1);
		_notifyIcon.contextMenu.menuItems.add(menuItem2);
		_notifyIcon.show();

		_notifyIcon.balloonTipTitle = "Balloon tip example";
		_notifyIcon.balloonTipText = "Welcome to the D world!";
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
		_notifyIcon.balloonTipSound = true;
		_notifyIcon.showBalloonTip();
	}
}

static this()
{
	Application.enableVisualStyles();
}

void main()
{
	Application.run(new MainForm());
}
