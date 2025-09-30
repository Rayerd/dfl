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
	private Button _showButton;
	private Button _updateButton;

	version (ToastNotifier)
		private ToastNotifier _notifier;
	else
		private ToastNotifierLegacy _notifier;

	this()
	{
		this.text = "ToastNotifier example";
		this.size = Size(300, 350);

		version (ToastNotifier)
		{
			_notifier = new ToastNotifier(AUMID);

			// _notifier.launch = "action=Test&amp;userId=49183";
			_notifier.setLaunch("action=Test&userId=49183"); // setLaunch() converts text to escaped XML.

			_notifier.imagePath = IMAGE_PATH;
			
			_notifier.hintCrop = true;

			_notifier.imageStyle = ToastNotifierImageStyle.HERO;
			// _notifier.imageStyle = ToastNotifierImageStyle.INLINE;
			
			auto progressBar = new ToastProgressBar("Processing..."w, 0.6);
			progressBar.title = "Download"w;
			progressBar.valueStringOverride = "60/100 files"w;
			_notifier.progressBar = progressBar;

			// Input1 (TextBox)
			_notifier.inputs.add(new ToastTextBox("input1"w, "Message"w, "Place holder content"w));
			// Input2 (SelectionBox)
			ToastSelectionBox input2 = new ToastSelectionBox("input2"w, "Fruits"w, "Place holder content"w, "select3"w);
			input2.items.add(new ToastSelectionBoxItem("select1"w, "Apple"w));
			input2.items.add(new ToastSelectionBoxItem("select2"w, "Orange"w));
			input2.items.add(new ToastSelectionBoxItem("select3"w, "Pine"w));
			_notifier.inputs.add(input2);
			// Input3 (TextBox)
			_notifier.inputs.add(new ToastTextBox("input3"w, "to"w, "Place holder content"w));
			// Input4 (TextBox)
			_notifier.inputs.add(new ToastTextBox("input4"w, "cc"w, "Place holder content"w));
			// Input5 (TextBox)
			_notifier.inputs.add(new ToastTextBox("input5"w, "bcc"w, "Place holder content"w));
			//
			assert(_notifier.inputs.length <= 5, "Toast textboxes length must be 0 to 5.");

			_notifier.useButtonStyle = true;
			// Button1
			ToastButton button1 = new ToastButton("Ok"w, "action=OkButton&amp;userId=49183"w);
			button1.buttonStyle = ToastButtonStyle.SUCCESS; // buttonStyle property is enabled if useButtonStyle is true.
			_notifier.buttons.add(button1);
			// Button2
			_notifier.buttons.add(new ToastButton("Cancel"w, "action=CancelButton&amp;userId=49183"w));
			// Button3
			ToastButton button3 = new ToastButton("Open Google"w, "https://www.google.com/"w);
			button3.activationType = ToastActivationType.PROTOCOL;
			button3.buttonStyle = ToastButtonStyle.CRITICAL;
			_notifier.buttons.add(button3);
			// Button4
			_notifier.buttons.add(new ToastButton("Option"w, "action=Option"w));
			// Button5
			_notifier.buttons.add(new ToastButton("Close"w, "action=Close"w));
			//
			assert(_notifier.buttons.length <= 5, "Toast buttons length must be 0 to 5.");
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

		_showButton = new Button;
		_showButton.text = "Show toast";
		_showButton.location = Point(50, 50);
		_showButton.size = Size(150,60);
		_showButton.parent = this;
		_showButton.click ~= (Control c, EventArgs e) {
			version (ToastNotifier)
			{
				_notifier.sequenceNumber = 1; // Initial value is 1 defaultly.
				_notifier.show("tag", "group");
			}
			else
			{
				_notifier.show();
			}
		};

		version (ToastNotifier)
		{
			_updateButton = new Button;
			_updateButton.text = "Update toast";
			_updateButton.location = Point(50, 150);
			_updateButton.size = Size(150,60);
			_updateButton.parent = this;
			_updateButton.click ~= (Control c, EventArgs e) {
				_notifier.headline = "Updated headline!";
				_notifier.text = "Updated text!";
				_notifier.subtext = "2025-09-23";
				//
				_notifier.progressBar.value = 1.0;
				_notifier.progressBar.status = "Completed!"w;
				_notifier.progressBar.title = "Downloaded"w;
				_notifier.progressBar.valueStringOverride = "100/100 files"w;
				//
				_notifier.sequenceNumber = 2;
				//
				auto result = _notifier.update("tag", "group");
			};
		}
	}
}

class CustomNotificationActivator : NotificationActivator
{
	override void onActivated(NotificationActivator activator, ToastActivatedEventArgs args)
	{
		// Write user-side code.
		wstring[wstring] argList = parseArguments(args.arguments);

		wstring inputList;
		foreach (key, value; args.userInputs)
			inputList ~= "[" ~ key ~ ":" ~ value ~ "]\n";
		
		msgBox(
			"<activated>\n" ~
			"- args  : " ~ argList.to!string ~ "\n" ~
			"- inputs: " ~ inputList.to!string);
	}
}

wstring[wstring] parseArguments(wstring args)
{
	import std.string;
	import std.array;
	wstring[wstring] ret;
	foreach (wstring e; args.split("&"w))
	{
		wstring[] set = e.split("=");
		wstring key = set[0];
		wstring value = set[1];
		ret[key] = value;
	}
	return ret;
}
unittest
{
	wstring[wstring] result = parseArguments("param1=hello&param2=dfl&param3=world"w);
	assert(result["param1"w] == "hello"w);
	assert(result["param2"w] == "dfl"w);
	assert(result["param3"w] == "world"w);
}

version(unittest) {} else
void main(string[] args)
{
	// NOTE: Do not set an existing CLSID, except for one predefined by the DFL,
	//       as this will corrupt the registry.
	//
	// NOTE: Change to your CLSID if you want to use your own COM server.
	//
	// NOTE: If you use a CLSID predefined by DFL,
	//       the toast notification generated by DFL will share the COM server with all applications.
	//
	// NOTE: Since you can only set one path to the application's executable,
	//       the shared COM server will launch only one application.
	CLSID activatorClsid = DFL_CLSID_NOTIFICATION_ACTIVATOR;

	scope manager = new DesktopNotificationManager(args, AUMID, &activatorClsid);
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
