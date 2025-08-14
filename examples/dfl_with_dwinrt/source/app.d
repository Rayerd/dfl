import dwinrt;

import dfl;
import dfl.internal.dpiaware :
	SetProcessDpiAwarenessContext,
	DPI_AWARENESS_CONTEXT_PER_MONITOR_AWARE_V2;

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

			// showHstring(toastXml.GetXml());

			// Create text node.
			XmlNodeList stringElements = toastXml.GetElementsByTagName(hstring("text").handle);
			XmlText textNode = stringElements.Item(0).as!XmlText;
			XmlText newTextNode = toastXml.CreateTextNode(hstring("This is the message from dlang!").handle);
			textNode.AppendChild(newTextNode);

			// showHstring(toastXml.GetXml());

			// Create notifier object.
			hstring str_appid = "dfl.toast_example";
			ToastNotifier notifier = ToastNotificationManager.CreateToastNotifier/+WithId+/(str_appid.handle); // Supported overload.

			// Create ToastNotification object.
			ToastNotification toast = ToastNotification.New(toastXml);
			notifier.Show(toast);

			// Show message dialog.
			auto msgDlg = MessageDialog.New(hstring("show").handle, hstring("Hello DFL with D/WinRT").handle);
			msgDlg.as!IInitializeWithWindow.Initialize(handle);
			auto okEvent = event!(UICommandInvokedHandler, Windows.UI.Popups.IUICommand)(
				(Windows.UI.Popups.IUICommand command) {
					msgBox("It's OK.");
				}
			);
			auto cancelEvent = handler!UICommandInvokedHandler(
				(Windows.UI.Popups.IUICommand command) {
					msgBox("It's cancel.");
				}
			);
			auto command1 = UICommand.New(hstring("OK").handle, okEvent);
			auto command2 = UICommand.New(hstring("Cancel").handle, cancelEvent);
			msgDlg.Commands.abi_Append(command1);
			msgDlg.Commands.abi_Append(command2);
			msgDlg.DefaultCommandIndex = 0;
			msgDlg.CancelCommandIndex = 1;

			// Another method for button-clicked event.
			msgDlg.ShowAsync.then(
				(Windows.UI.Popups.IUICommand thisCommand) {
					if (thisCommand is command1)
						msgBox("Completed.");
					else if (thisCommand is command2)
						msgBox("Cancled.");
				}
			);
		};

		DecimalFormatter f = DecimalFormatter.New();
		HSTRING str = f.Format/+Double+/(999.99); // Supported overload.
		showHstring(str);
	}
}

void showHstring(HSTRING s)
 {
	import std.conv : to;
	hstring str = s;
	msgBox(str.d_str.to!string);
}
