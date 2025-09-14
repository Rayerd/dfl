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

// NOTE: Please update the file path in the sample source code to match your environment.
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

		wstring appId = "Dlang.Dfl.ToastNotifierExample";

		version (ToastNotifier)
		{
			wstring appName = "toastnotifier_sample";
			wstring exePath = r"C:\d\gitproj\dfl\examples\toastnotifier\bin\" ~ appName ~ r".exe";
			wstring shortcutPath = Application.userAppDataBasePath.to!wstring ~ r"\Microsoft\Windows\Start Menu\Programs\" ~ appName ~ r".lnk";

			_notifier = new ToastNotifier(appName, exePath, shortcutPath, appId);
			_notifier.heroImage = HeroImagePath;
			_notifier.hintCrop = true;

			this.closed ~= (Control c, EventArgs e) {
				_notifier.dispose(); // NOTE: Must be called to delete shortcut files.
			};
		}
		else
		{
			_notifier = new ToastNotifierLegacy(appId);
			_notifier.toastTemplate = ToastTemplateType.ToastImageAndText04;
		}
		_notifier.headline = "Hello ToastNotifier with DFL!";
		_notifier.text = "ToastNotifierのサンプルコードです。";
		_notifier.subtext = "2025-09-15";
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

void main()
{
	Application.enableVisualStyles();

	import dfl.internal.dpiaware;
	SetProcessDpiAwarenessContext(DPI_AWARENESS_CONTEXT_PER_MONITOR_AWARE_V2);

	Application.run(new MainForm());
}
