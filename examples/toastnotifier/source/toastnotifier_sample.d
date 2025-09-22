import dfl;

import std.conv : to;

version(Have_dfl) // For DUB.
{
}
else
{
	pragma(lib, "dfl.lib");
}

version = ToastNotifier;// NOTE: If commented out, ToastNotifierLegacy will be used.

// NOTE: Change to your AUMID (App User Model Id).
enum AUMID = "Dlang.Dfl.ToastNotifierExample"w;

// NOTE: Change to the file path in the sample source code to match your environment.
enum AppLogoImagePath = r"file:///C:/d/gitproj/dfl/examples/toastnotifier/image/d.bmp";
enum HeroImagePath = r"file:///C:/d/gitproj/dfl/examples/picturebox/image/dman-error.bmp";

class MainForm : Form
{
	private Button _button;

	version (ToastNotifier)
		private ToastNotifier _notifier;
	else
		private ToastNotifierLegacy _notifier;

	this()
	{
		this.text = "ToastNotifier example";
		this.size = Size(300, 250);

		version (ToastNotifier)
		{
			_notifier = new ToastNotifier(AUMID);
			_notifier.launch = "action=Test&amp;userId=49183";
			_notifier.useButtonStyle = true;
			_notifier.heroImage = HeroImagePath;
			_notifier.hintCrop = true;
		}
		else
		{
			_notifier = new ToastNotifierLegacy(AUMID);
			// _notifier.toastTemplate = ToastTemplateType.ToastImageAndText01;
			// _notifier.toastTemplate = ToastTemplateType.ToastImageAndText02;
			// _notifier.toastTemplate = ToastTemplateType.ToastImageAndText03;
			_notifier.toastTemplate = ToastTemplateType.ToastImageAndText04;
			// _notifier.toastTemplate = ToastTemplateType.ToastText01;
			// _notifier.toastTemplate = ToastTemplateType.ToastText02;
			// _notifier.toastTemplate = ToastTemplateType.ToastText03;
			// _notifier.toastTemplate = ToastTemplateType.ToastText04;
		}
		_notifier.headline = "Hello ToastNotifier with DFL!";
		_notifier.text = "ToastNotifierのサンプルコードです。";
		_notifier.subtext = "2025-09-22";
		_notifier.appLogoImage = AppLogoImagePath;

		_button = new Button;
		_button.text = "Show toast";
		_button.location = Point(50, 50);
		_button.size = Size(150,60);
		_button.parent = this;
		_button.click ~= (Control c, EventArgs e) {
			_notifier.show();
		};
	}
}

class CustomNotificationActivator : NotificationActivator
{
	override void onActivated(NotificationActivator activator, ToastActivatedEventArgs args)
	{
		// Write user-side code.
		import std.conv : to;

		wstring argList = args.arguments;

		wstring inputsList;
		foreach (key, value; args.userInputs)
			inputsList ~= "[" ~ key ~ ":" ~ value ~ "]\n";
		
		msgBox(
			"<activated>\n" ~
			"- args  : " ~ argList.to!string ~ "\n" ~
			"- inputs: " ~ inputsList.to!string);
	}
}

void main(string[] args)
{
	scope manager = new DesktopNotificationManager(args, AUMID);
	final switch (manager.mode)
	{
	case DesktopNotificationMode.NORMAL:
		manager.installShellLink(); // Create SHellLink to StartMenu.
		manager.registerAumidAndComServer(); // Add registry keys and values.

		static if (1)
		{
			// Mehotd 1.
			auto activator = new CustomNotificationActivator;
		}
		else
		{
			// Mehotd 2.
			auto activator = new NotificationActivator;
			activator.activated ~= (NotificationActivator na, ToastActivatedEventArgs ea) {
				// Do something.
			};
		}
		manager.registerActivator(activator);
		scope(exit)
			manager.unregisterActivator();

		Application.enableVisualStyles();

		import dfl.internal.dpiaware;
		SetProcessDpiAwarenessContext(DPI_AWARENESS_CONTEXT_PER_MONITOR_AWARE_V2);

		Application.run(new MainForm()); // Show your main form.
		break;

	case DesktopNotificationMode.LAUNCH:
		// Called from Activator COM server.
		manager.registerActivator(new CustomNotificationActivator);
		scope(exit)
			manager.unregisterActivator();

		// NOTE: This is where we need a message loop.

		import std.string : join;
		msgBox("<Embedding>\n" ~ args.join("\n")); // Calling msgBox() establishes a message loop.

		Application.run(new Form()); // Show simple form experimentally. Of course, a message loop is configured.

		// NOTE: Call this methos if you want to uninstall this app.
		static if (0)
		{
			manager.unregisterAumidAndComServer();
			manager.uninstallShellLink();
		}
		break;
	}
}	
