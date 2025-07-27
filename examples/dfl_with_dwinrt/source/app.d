import dwinrt;

import dfl;
import dfl.internal.dpiaware;

import Windows.Ui.Notifications;
import Windows.Data.Xml.Dom;
import Windows.Globalization.NumberFormatting;

void main()
{
	// WinRT 初期化
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
			// 通知XMLのテンプレートを取得
			XmlDocument toastXml = ToastNotificationManager.GetTemplateContent(ToastTemplateType.ToastText01);

			// showHstring(toastXml.GetXml());

			// テキストノードを設定
			XmlNodeList stringElements = toastXml.GetElementsByTagName(hstring("text").handle);
			XmlText textNode = cast(XmlText)stringElements.Item(0);
			XmlText newTextNode = toastXml.CreateTextNode(hstring("This is the message from dlang!").handle);
			textNode.AppendChild(newTextNode);

			// showHstring(toastXml.GetXml());

			// 通知送信オブジェクトを作成
			hstring str_appid = "dfl.toast_example";
			ToastNotifier notifier = ToastNotificationManager.CreateToastNotifier/+WithId+/(str_appid.handle); // オーバーロードにも対応

			// ToastNotification オブジェクト作成
			ToastNotification toast = ToastNotification.New(toastXml);
			notifier.Show(toast);
		};

		DecimalFormatter f = DecimalFormatter.New();
		HSTRING str = f.Format/+Double+/(999.99); // オーバーロードにも対応
		showHstring(str);
	}
}

void showHstring(HSTRING s)
 {
	import std.conv : to;
	hstring str = s;
	msgBox(str.d_str.to!string);
}
