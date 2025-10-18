import dwinrt;

import dfl;

import Windows.Ui.Notifications;
import Windows.UI.Popups;
import Windows.Data.Xml.Dom;
import Windows.Globalization.NumberFormatting;
import Windows.Foundation.Collections;

void main()
{
	// Initialize WinRT.
	init_apartment(ApartmentType.singleThreaded);
	scope(exit) uninit_apartment();

	// Visual Styles.
	Application.enableVisualStyles();

	// DPI Aware.
	import dfl.internal.dpiaware;
	SetProcessDpiAwarenessContext(DPI_AWARENESS_CONTEXT_PER_MONITOR_AWARE_V2);

	Application.run(new MainForm);
}

class MainForm : Form
{
	Button button;

	this()
	{
		button = new Button;
		button.text = "Show toast";
		button.size = Size(150,60);
		button.parent = this;
		button.click ~= (Control c, EventArgs e)
		{
			// Get notify XML template.
			XmlDocument toastXml = ToastNotificationManager.GetTemplateContent(ToastTemplateType.ToastText01);

			// Create text node.
			XmlNodeList stringElements = toastXml.GetElementsByTagName("text");
			XmlText textNode = stringElements.Item(0).as!(XmlText);
			XmlText newTextNode = toastXml.CreateTextNode("This is the message from dlang!");
			textNode.AppendChild(newTextNode);

			// Create notifier object.
			wstring appId = "Dlang.Library.DflToastExample";
			Windows.UI.Notifications.ToastNotifier notifier = ToastNotificationManager.CreateToastNotifier/+WithId+/(appId); // Supported overload.

			// Create ToastNotification object.
			ToastNotification toast = ToastNotification.New(toastXml);
			notifier.Show(toast);

			// Show message dialog.
			auto msgDlg = MessageDialog.New("show", "Hello DFL with D/WinRT");
			msgDlg.as!IInitializeWithWindow.Initialize(handle);
			auto okEvent = delegate (IUICommand command) {
				msgBox("It's OK.");
			};
			auto cancelEvent = delegate (IUICommand command) {
				msgBox("It's cancel.");
			};
			auto command1 = UICommand.New("OK", okEvent);
			auto command2 = UICommand.New("Cancel", cancelEvent);
			msgDlg.Commands.abi_Append(command1);
			msgDlg.Commands.abi_Append(command2);
			msgDlg.DefaultCommandIndex = 0;
			msgDlg.CancelCommandIndex = 1;

			// Another method for button-clicked event.
			msgDlg.ShowAsync.then(
				(IUICommand thisCommand) {
					if (thisCommand is command1)
						msgBox("Completed.");
					else if (thisCommand is command2)
						msgBox("Cancled.");
				}
			);
		};

		DecimalFormatter f = DecimalFormatter.New();
		wstring str = f.Format/+Double+/(999.99); // Supported overload.
		import std.conv : to;
		msgBox(str.to!string);
	}
}
