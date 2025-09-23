import dfl;

import std.conv : to;
import std.string : join;

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
enum APP_LOGO_IMAGE_PATH = r"file:///C:/d/gitproj/dfl/examples/toastnotifier/image/d.bmp";
enum IMAGE_PATH = r"file:///C:/d/gitproj/dfl/examples/picturebox/image/dman-error.bmp";

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
			_notifier.imagePath = IMAGE_PATH;
			_notifier.imageStyle = ToastNotifierImageStyle.HERO;
			// _notifier.imageStyle = ToastNotifierImageStyle.INLINE;
			_notifier.hintCrop = true;
		}
		else
		{
			_notifier = new ToastNotifierLegacy(AUMID);
			// _notifier.toastTemplate = ToastTemplateType.TOAST_IMAGE_AND_TEXT_01;
			// _notifier.toastTemplate = ToastTemplateType.TOAST_IMAGE_AND_TEXT_02;
			// _notifier.toastTemplate = ToastTemplateType.TOAST_IMAGE_AND_TEXT_03;
			_notifier.toastTemplate = ToastTemplateType.TOAST_IMAGE_AND_TEXT_04;
			// _notifier.toastTemplate = ToastTemplateType.TOAST_TEXT_01;
			// _notifier.toastTemplate = ToastTemplateType.TOAST_TEXT_02;
			// _notifier.toastTemplate = ToastTemplateType.TOAST_TEXT_03;
			// _notifier.toastTemplate = ToastTemplateType.TOAST_TEXT_04;
		}
		_notifier.headline = "Hello ToastNotifier with DFL!";
		_notifier.text = "ToastNotifierのサンプルコードです。";
		_notifier.subtext = "2025-09-22";
		_notifier.appLogoImagePath = APP_LOGO_IMAGE_PATH;

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
		wstring argList = args.arguments;

		wstring inputList;
		foreach (key, value; args.userInputs)
			inputList ~= "[" ~ key ~ ":" ~ value ~ "]\n";
		
		msgBox(
			"<activated>\n" ~
			"- args  : " ~ argList.to!string ~ "\n" ~
			"- inputs: " ~ inputList.to!string);
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
			// Method 1.
			auto activator = new CustomNotificationActivator;
		}
		else
		{
			// Method 2.
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

		msgBox("<Embedding>\n" ~ args.join("\n")); // Calling msgBox() establishes a message loop.

		Application.run(new Form()); // Show simple form experimentally. Of course, a message loop is configured.

		// NOTE: Call this methos if you want to uninstall this app.
		static if (0)
		{
			manager.unregisterAumidAndComServer();
			manager.uninstallShellLink();
		}
	}
}	
