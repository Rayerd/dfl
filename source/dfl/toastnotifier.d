// Refference:
//
// Send a local app notification from other types of unpackaged apps
// https://learn.microsoft.com/en-us/windows/apps/develop/notifications/app-notifications/send-local-toast-other-apps
//
// Send a local app notification from a C# app
// https://learn.microsoft.com/en-us/windows/apps/develop/notifications/app-notifications/send-local-toast?tabs=desktop#step-6-handling-activation
//
// Toast schema
// https://learn.microsoft.com/en-us/uwp/schemas/tiles/toastschema/schema-root

///
module dfl.toastnotifier;

import dfl.application;
import dfl.base;
import dfl.drawing;
import dfl.environment;
import dfl.event;
import dfl.registry;

import dfl.internal.com : DflComObject, ComPtr;
import dfl.internal.dlib;
import dfl.internal.winrt;
import dfl.internal.utf : fromUnicodez;

import core.stdc.string : memset;
import core.stdc.wchar_ : wcslen;

import core.sys.windows.basetyps : REFIID;
public import core.sys.windows.basetyps : CLSID, REFCLSID;
import core.sys.windows.com;
import core.sys.windows.objbase : CoRevokeClassObject, CoRegisterClassObject, REGCLS;
import core.sys.windows.objidl : PROPVARIANT, IPersistFile;
import core.sys.windows.shlobj : IShellLinkW;
import core.sys.windows.shlwapi : SHStrDupW;
import core.sys.windows.winbase : Sleep, DeleteFile;
import core.sys.windows.windef;
import core.sys.windows.wtypes : VARENUM;

import std.algorithm : canFind;
import std.conv : to;
import std.format : format;
import std.path : baseName, stripExtension, buildNormalizedPath, setExtension;
import std.string : replace;


pragma(lib, "Shlwapi"); // SHStrDupW
pragma(lib, "Propsys"); // InitPropVariantFromCLSID, PropVariantClear


///
class ToastNotification // docmain
{
	///
	this(in Dwstring xml)
	{
		_xml = xml;
	}


	///
	@property Dwstring content() const
	{
		return _xml;
	}


	///
	@property void data(INotificationData data) // setter
	{
		_data = data;
	}


	///
	@property INotificationData data() // getter
	{
		return _data;
	}

	///
	@property void tag(in Dwstring tag) // setter
	{
		_tag = tag;
	}

	/// ditto
	@property Dwstring tag() const // getter
	{
		return _tag;
	}

	///
	@property void group(in Dwstring group) // setter
	{
		_group = group;
	}

	/// ditto
	@property Dwstring group() const // getter
	{
		return _group;
	}


private:
	const Dwstring _xml; ///
	INotificationData _data; ///
	Dwstring _tag; ///
	Dwstring _group; ///
}


///
class ToastNotifier // docmain
{
	///
	this(in Dwstring aumid)
	{
		_aumid = aumid;
	}
	

	///
	private static Dwstring _buildXml(in ToastNotifier notifier)
	{
		static Dwstring createAppLogoXmlElement(in ToastNotifier n)
		{
			if (n._appLogoImagePath.length == 0)
				return ""w;
			
			if (n._hintCrop)
				return format("<image placement='appLogoOverride' src='%s' hint-crop='circle' />"w, n._appLogoImagePath);
			else
				return format("<image placement='appLogoOverride' src='%s' />"w, n._appLogoImagePath);
		}

		static Dwstring createImageXmlElement(in ToastNotifier n)
		{
			if (n._imagePath.length == 0)
				return ""w;
			
			final switch (n._imageStyle)
			{
			case ToastNotifierImageStyle.INLINE:
				return format("<image src='%s' />"w, n._imagePath);
			case ToastNotifierImageStyle.HERO:
				return format("<image placement='hero' src='%s' />"w, n._imagePath);
			}
		}

		static Dwstring createInputXmlElement(in ToastNotifier n)
		{
			Dwstring ret;
			foreach (input; n.inputs)
				ret ~= input.toXmlElement ~ "\n"w;
			return ret;
		}

		static Dwstring createButtonXmlElement(in ToastNotifier n)
		{
			Dwstring ret;
			foreach (button; n.buttons)
				ret ~= button.toXmlElement ~ "\n"w;
			return ret;
		}

		Dwstring xml = format(r"
			<toast launch='%s' useButtonStyle='%s'>
				<visual>
					<binding template='ToastGeneric'>
						%s
						<text>{headline}</text>
						<text>{text}</text>
						<text>{subtext}</text>
						%s
						%s
					</binding>
				</visual>
				<actions>
					%s
					%s
				</actions>
			</toast>"w,
			notifier._launch,
			notifier._useButtonStyle ? "true" : "false",
			notifier._progressBar ? notifier._progressBar.toXmlElement() : ""w,
			createAppLogoXmlElement(notifier),
			createImageXmlElement(notifier),
			createInputXmlElement(notifier),
			createButtonXmlElement(notifier)
		);
		return xml;
	}

	///
	void show(in Dwstring tag, in Dwstring group)
	{
		Dwstring xml = _buildXml(this);
		_showCore(xml, tag, group);
	}

	/// ditto
	void show(in Dwstring tag)
	{
		show(tag, ""w);
	}
	
	/// ditto
	void show()
	{
		show(""w, ""w);
	}


	///
	private void _showCore(in Dwstring xml, in Dwstring tag, in Dwstring group)
	{
		HRESULT hr;
		
		ComPtr!IToastNotification toast = _createToastNotification(xml, tag, group);
		ComPtr!IToastNotifier notifier = _createToastNotifier(_aumid);
		hr = notifier.abi_Show(toast);
		assert(hr == S_OK, "Failed to show toast");
	}


	///
	private static ComPtr!IToastNotifier _createToastNotifier(in Dwstring aumid)
	{
		HRESULT hr;

		// Get ActivationFactory of ToastNotificationManager class.
		ComPtr!IToastNotificationManagerStatics toastStatics;
		hstring hClass = hstring("Windows.UI.Notifications.ToastNotificationManager"w);
		hr = RoGetActivationFactory(hClass.handle, &IID_IToastNotificationManagerStatics, cast(void**)toastStatics.ptr);
		assert(toastStatics.ptr);
		assert(hr == S_OK, "Failed to get ToastNotificationManager statics");

		// Create Notifier.
		ComPtr!IToastNotifier notifier;
		hr = toastStatics.abi_CreateToastNotifierWithId(hstring(aumid).handle, notifier.ptr);
		assert(notifier.ptr);
		assert(hr == S_OK, "Failed to create ToastNotifier");
		
		return notifier;
	}


	///
	private ComPtr!IToastNotification _createToastNotification(in Dwstring xml, in Dwstring tag, in Dwstring group)
	{
		HRESULT hr;

		// Create XmlDocument.
		ComPtr!XmlDocument xmlDoc;
		hstring hXmlDocClass = hstring("Windows.Data.Xml.Dom.XmlDocument"w);
		hr = RoActivateInstance(hXmlDocClass.handle, cast(IInspectable*)xmlDoc.ptr);
		assert(xmlDoc.ptr);
		assert(hr == S_OK, "Failed to activate XmlDocument");
		
		// Load XML.
		ComPtr!IXmlDocumentIO xmlDocIO = xmlDoc.as!IXmlDocumentIO(&IID_IXmlDocumentIO);
		assert(xmlDocIO.ptr);
		assert(hr == S_OK, "Failed to activate XmlDocumentIO");

		hr = xmlDocIO.LoadXml(hstring(xml).handle);
		assert(hr == S_OK, "Failed to load XML");

		// Create ToastNotification.
		ComPtr!IToastNotificationFactory toastFactory;
		hstring hToastClass = hstring("Windows.UI.Notifications.ToastNotification"w);
		hr = RoGetActivationFactory(hToastClass.handle, &IID_IToastNotificationFactory, cast(void**)toastFactory.ptr);
		assert(toastFactory.ptr);
		assert(hr == S_OK, "Failed to get ToastNotificationFactory");

		ComPtr!IToastNotification toast;
		hr = toastFactory.abi_CreateToastNotification(xmlDoc.handle, toast.ptr);
		assert(toast.ptr);
		assert(hr == S_OK, "Failed to create ToastNotification");

		ComPtr!IToastNotification2 toast2 = toast.as!IToastNotification2(&IID_IToastNotification2);
		hr = toast2.set_Tag(hstring(tag).handle);
		assert(hr == S_OK, "set_Tag is failed");
		hr = toast2.set_Group(hstring(group).handle);
		assert(hr == S_OK, "set_Group is failed");

		ComPtr!INotificationDataFactory dataFacotry;
		hstring hDataClass = hstring("Windows.UI.Notifications.NotificationData"w);
		hr = RoGetActivationFactory(hDataClass.handle, &IID_INotificationDataFactory, cast(void**)dataFacotry.ptr);
		assert(dataFacotry.ptr);
		assert(hr == S_OK, "Failed to get ToastNotificationDataFactory");

		ComPtr!IStringMap values;
		hstring hStringMapClass = hstring("Windows.Foundation.Collections.StringMap"w);
		hr = RoActivateInstance(hStringMapClass.handle, cast(IInspectable*)values.ptr);
		assert(values.ptr);
		assert(hr == S_OK, "Failed to activate StringMap");

		hr = _bindTextAndProgressBar(values);

		ComPtr!INotificationData data;
		hr = dataFacotry.abi_CreateNotificationDataWithValuesAndSequenceNumber(values, _sequenceNumber, data.ptr);
		assert(data.ptr);
		assert(hr == S_OK, "Failed to create NotificationData");

		ComPtr!IToastNotification4 toast4 = toast.as!IToastNotification4(&IID_IToastNotification4);
		assert(toast4.ptr);
		hr = toast4.set_Data(data);
		assert(hr == S_OK, "Failed to set data");

		return toast;
	}


	///
	private HRESULT _bindTextAndProgressBar(IStringMap values) const
	{
		HRESULT hr;

		hr = _insert(values, "headline"w, _headline);
		if (hr != S_OK) return hr;
		hr = _insert(values, "text"w, _text);
		if (hr != S_OK) return hr;
		hr = _insert(values, "subtext"w, _subtext);
		if (hr != S_OK) return hr;

		if (!_progressBar) return S_OK;

		hr = _insert(values, "progressTitle"w, _progressBar._title);
		if (hr != S_OK) return hr;
		hr = _insert(values, "progressStatus"w, _progressBar._status);
		if (hr != S_OK) return hr;
		hr = _insert(values, "progressValue"w, format("%.2f"w, _progressBar._value));
		if (hr != S_OK) return hr;
		hr = _insert(values, "progressValueStringOverride"w, _progressBar._valueStringOverride);
		if (hr != S_OK) return hr;

		return S_OK;
	}

	
	///
	private static HRESULT _insert(IStringMap stringMap, in Dwstring key, in Dwstring value)
	{
		bool outReplaced1;
		return stringMap.abi_Insert(hstring(key).handle, hstring(value).handle, &outReplaced1);
	}


	///
	NotificationUpdateResult update(in Dwstring tag, in Dwstring group)
	{
		HRESULT hr;

		Dwstring xml = _buildXml(this);

		ComPtr!IToastNotifier notifier = _createToastNotifier(_aumid);
		ComPtr!IToastNotifier2 notifier2 = notifier.as!IToastNotifier2(&IID_IToastNotifier2);

		ComPtr!INotificationDataFactory dataFacotry;
		hstring hDataClass = hstring("Windows.UI.Notifications.NotificationData"w);
		hr = RoGetActivationFactory(hDataClass.handle, &IID_INotificationDataFactory, cast(void**)dataFacotry.ptr);
		assert(dataFacotry.ptr);
		assert(hr == S_OK, "Failed to get ToastNotificationDataFactory");

		ComPtr!IStringMap values;
		hstring hStringMapClass = hstring("Windows.Foundation.Collections.StringMap"w);
		hr = RoActivateInstance(hStringMapClass.handle, cast(IInspectable*)values.ptr);
		assert(values.ptr);
		assert(hr == S_OK, "Failed to activate StringMap");

		hr = _bindTextAndProgressBar(values);

		ComPtr!INotificationData data;
		hr = dataFacotry.abi_CreateNotificationDataWithValuesAndSequenceNumber(values, _sequenceNumber, data.ptr);
		assert(data.ptr);
		assert(hr == S_OK, "Failed to create NotificationData");

		dfl.internal.winrt.NotificationUpdateResult result;
		if (group.length == 0)
			hr = notifier2.abi_UpdateWithTag(data, hstring(tag).handle, &result);
		else
			hr = notifier2.abi_UpdateWithTagAndGroup(data, hstring(tag).handle, hstring(group).handle, &result);
		assert(hr == S_OK, "Failed to update toast");

		return cast(NotificationUpdateResult)result;
	}

	/// ditto
	NotificationUpdateResult update(in Dwstring tag)
	{
		return update(tag, "");
	}


	/// Experimentally: Set launch arguments within XML escape.
	void setLaunch(in Dwstring txt, in bool enableEscape = true)
	{
		if (enableEscape)
		{
			wstring escaped = txt;
			escaped = escaped.replace("&", "&amp;");
			escaped = escaped.replace("<", "&lt;");
			escaped = escaped.replace(">", "&gt;");
			escaped = escaped.replace("\"", "&quot;");
			escaped = escaped.replace("'", "&apos;");
			launch = escaped;
		}
		else
			launch = txt;
	}

	/// Set launch arguments without XML escape.
	@property void launch(in Dwstring txt) // setter
	{
		_launch = txt;
	}

	/// Get launch arguments.
	@property Dwstring launch() const // getter
	{
		return _launch;
	}
	
	///
	@property void useButtonStyle(in bool byes) // setter
	{
		_useButtonStyle = byes;
	}

	/// ditto
	@property bool useButtonStyle() const // getter
	{
		return _useButtonStyle;
	}


	///
	@property void headline(in Dwstring txt) // setter
	{
		_headline = txt;
	}

	/// ditto
	@property Dwstring headline() const // getter
	{
		return _headline;
	}


	///
	@property void text(in Dwstring txt) // setter
	{
		_text = txt;
	}
	
	/// ditto
	@property Dwstring text() const // getter
	{
		return _text;
	}
	

	///
	@property void subtext(in Dwstring txt) // setter
	{
		_subtext = txt;
	}
	
	/// ditto
	@property Dwstring subtext() const // getter
	{
		return _subtext;
	}
	

	///
	@property void appLogoImagePath(in Dwstring path) // setter
	{
		_appLogoImagePath = path;
	}

	/// ditto
	@property Dwstring appLogoImagePath() const // getter
	{
		return _appLogoImagePath;
	}

	
	///
	@property void imagePath(in Dwstring path) // setter
	{
		_imagePath = path;
	}

	/// ditto
	@property Dwstring imagePath() const // getter
	{
		return _imagePath;
	}

	
	///
	@property void imageStyle(in ToastNotifierImageStyle style) // setter
	{
		_imageStyle = style;
	}

	/// ditto
	@property ToastNotifierImageStyle imageStyle() const // getter
	{
		return _imageStyle;
	}


	///
	@property void hintCrop(in bool byes) // setter
	{
		_hintCrop = byes;
	}

	/// ditto
	@property bool hintCrop() const // getter
	{
		return _hintCrop;
	}


	///
	@property ToastButtonCollection buttons() // getter
	{
		return _buttons;
	}

	/// ditto
	@property const(ToastButtonCollection) buttons() const // getter
	{
		return _buttons;
	}


	///
	@property ToastTextBoxCollection inputs() // getter
	{
		return _inputs;
	}

	/// ditto
	@property const(ToastTextBoxCollection) inputs() const // getter
	{
		return _inputs;
	}


	///
	@property void progressBar(ToastProgressBar bar) // setter
	{
		_progressBar = bar;
	}

	/// ditto
	@property ToastProgressBar progressBar() // getter
	{
		return _progressBar;
	}


	///
	@property void sequenceNumber(in uint sequenceNumber) // setter
	{
		_sequenceNumber = sequenceNumber;
	}

	///
	@property uint sequenceNumber() // getter
	{
		return _sequenceNumber;
	}


private:
	const Dwstring _aumid; ///
	Dwstring _launch; ///
	bool _useButtonStyle; ///
	Dwstring _headline; ///
	Dwstring _text; ///
	Dwstring _subtext; ///
	Dwstring _appLogoImagePath; ///
	Dwstring _imagePath; ///
	ToastNotifierImageStyle _imageStyle; ///
	bool _hintCrop; ///
	ToastButtonCollection _buttons = new ToastButtonCollection; ///
	ToastTextBoxCollection _inputs = new ToastTextBoxCollection; ///
	ToastProgressBar _progressBar; ///
	uint _sequenceNumber = 1;
}


///
enum NotificationUpdateResult
{
	SUCCEEDED = dfl.internal.winrt.NotificationUpdateResult.Succeeded,
	FAILED = dfl.internal.winrt.NotificationUpdateResult.Failed,
	NOTIFICATION_NOT_FOUND = dfl.internal.winrt.NotificationUpdateResult.NotificationNotFound
}


///
class ToastCollectionBase(ItemType)
{
	///
	void add(ItemType item)
	{
		_items ~= item;
		assert(_items.length <= 5, "Toast buttons/TextBox length must be 0 to 5.");
	}

	
	///
	@property size_t length() const
	{
		return _items.length;
	}

	
	///
	@property ItemType opIndex(size_t index)
	{
		return _items[index];
	}

	
	///
	int opApply(int delegate(ref ItemType) dg)
	{
		foreach (ref ItemType item; _items)
		{
			auto result = dg(item);
			if (result)
				return result;
		}
		return 0;
	}

	/// ditto
	int opApply(int delegate(ref const(ItemType)) dg) const
	{
		foreach (ref const(ItemType) item; _items)
		{
			auto result = dg(item);
			if (result)
				return result;
		}
		return 0;
	}

private:
	ItemType[] _items; ///
}


///
alias ToastTextBoxCollection = ToastCollectionBase!IToastTextBox;

///
alias ToastSelectionBoxItemCollection = ToastCollectionBase!ToastSelectionBoxItem;

///
alias ToastButtonCollection = ToastCollectionBase!ToastButton;


/// 
interface IToastTextBox
{
	///
	@property Dwstring id() const; // getter
	///
	@property Dwstring toXmlElement() const; // getter
}


///
class ToastTextBox : IToastTextBox
{
	///
	this(Dwstring id)
	{
		_id = id;
	}

	/// ditto (extra.)
	this(in Dwstring id, in Dwstring title, in Dwstring placeHolderContent)
	{
		_id = id;
		_title = title;
		_placeHolderContent = placeHolderContent;
	}


	///
	@property Dwstring id() const // getter
	{
		return _id;
	}


	///
	@property void title(in Dwstring title) // setter
	{
		_title = title;
	}

	/// ditto
	@property Dwstring title() const // getter
	{
		return _title;
	}


	///
	@property void placeHolderContent(in Dwstring placeHolderContent) // setter
	{
		_placeHolderContent = placeHolderContent;
	}

	/// ditto
	@property Dwstring placeHolderContent() const // getter
	{
		return _placeHolderContent;	
	}


	///
	@property Dwstring toXmlElement() const // getter
	{
		return format(
			"<input id='%s' type='text' title='%s' placeHolderContent='%s'/>"w,
			_id,
			_title,
			_placeHolderContent
		);
	}

private:
	const Dwstring _id; ///
	Dwstring _title; ///
	Dwstring _placeHolderContent; ///
}


///
class ToastSelectionBox : IToastTextBox
{
	///
	this(Dwstring id)
	{
		_id = id;
	}

	/// ditto (extra.)
	this(in Dwstring id, in Dwstring title, in Dwstring placeHolderContent, in Dwstring defaultInput)
	{
		_id = id;
		_title = title;
		_placeHolderContent = placeHolderContent;
		_defaultInput = defaultInput;
	}


	///
	@property Dwstring id() const // getter
	{
		return _id;
	}


	///
	@property void title(in Dwstring title) // setter
	{
		_title = title;
	}

	/// ditto
	@property Dwstring title() const // getter
	{
		return _title;
	}


	///
	@property void placeHolderContent(in Dwstring placeHolderContent) // setter
	{
		_placeHolderContent = placeHolderContent;
	}

	/// ditto
	@property Dwstring placeHolderContent() const // getter
	{
		return _placeHolderContent;	
	}

	
	///
	@property void defaultInput(in Dwstring defaultInput) // setter
	{
		_defaultInput = defaultInput;
	}

	/// ditto
	@property Dwstring defaultInput() const // getter
	{
		return _defaultInput;	
	}


	///
	@property Dwstring toXmlElement() const // getter
	{
		static Dwstring createSelectionBoxXmlElement(ToastSelectionBox box)
		{
			Dwstring ret;
			foreach (item; box.items)
				ret ~= item.toXmlElement ~ "\n"w;
			return ret;
		}
				
		return format(
			"<input id='%s' type='selection' title='%s' placeHolderContent='%s' defaultInput='%s'>"w ~
			"%s"w ~
			"</input>"w,
			_id,
			_title,
			_placeHolderContent,
			_defaultInput,
			createSelectionBoxXmlElement(cast(ToastSelectionBox)this)
		);
	}


	///
	@property ToastSelectionBoxItemCollection items() // getter
	{
		return _items;
	}


private:
	const Dwstring _id; ///
	Dwstring _title; ///
	Dwstring _placeHolderContent; ///
	Dwstring _defaultInput; ///

	ToastSelectionBoxItemCollection _items = new ToastSelectionBoxItemCollection; ///
}


///
class ToastSelectionBoxItem
{
	///
	this(in Dwstring id, in Dwstring content)
	{
		_id = id;
		_content = content;
	}


	///
	@property Dwstring id() const // getter
	{
		return _id;
	}


	///
	@property Dwstring content() const // getter
	{
		return _content;
	}


	///
	@property Dwstring toXmlElement() const
	{
		return format(
			"<selection id='%s' content='%s'/>"w,
			_id,
			_content
		);
	}


private:
	const Dwstring _id; ///
	const Dwstring _content; ///
}


///
class ToastButton
{
	///
	this(in Dwstring content, in Dwstring arguments)
	{
		_content = content;
		_arguments = arguments;
	}


	///
	@property Dwstring toXmlElement() const
	{
		return format(
			"<action "w ~
			"activationType='%s' "w ~ 
			"content='%s' "w ~
			"arguments='%s' "w ~
			"hint-buttonStyle='%s' "w ~
			"/>"w,
			_activationType == ToastActivationType.PROTOCOL ? "protocol"w : "foreground"w,
			_content,
			_arguments,
			toString(_buttonStyle)
		);
	}


	///
	@property Dwstring content() const // getter
	{
		return _content;
	}


	///
	@property Dwstring arguments() const // getter
	{
		return _arguments;
	}


	///
	@property void buttonStyle(in ToastButtonStyle buttonStyle) // setter
	{
		_buttonStyle = buttonStyle;
	}

	/// ditto
	@property ToastButtonStyle buttonStyle() const // getter
	{
		return _buttonStyle;
	}


	///
	@property void activationType(in ToastActivationType type) // setter
	{
		_activationType = type;
	}

	/// ditto
	@property ToastActivationType activationType() const // getter
	{
		return _activationType;
	}


private:
	const Dwstring _content; ///
	const Dwstring _arguments; ///
	ToastButtonStyle _buttonStyle; ///
	ToastActivationType _activationType; ///


	///
	Dwstring toString(in ToastButtonStyle buttonStyle) const
	{
		final switch (buttonStyle)
		{
		case ToastButtonStyle.DEFAULT:
			return ""w; // Empty.
		case ToastButtonStyle.SUCCESS:
			return "Success"w;
		case ToastButtonStyle.CRITICAL:
			return "Critical"w;
		}
	}
}


///
enum ToastButtonStyle
{
	DEFAULT, ///
	SUCCESS, ///
	CRITICAL ///
}


///
enum ToastActivationType
{
	FOREGROUND, ///
	BACKGROUND, /// Same as FOREGROUND. Desktop apps do not support Background activation.
	PROTOCOL ///
}

///
class ToastProgressBar
{
	///
	this(in Dwstring status, in double value)
	{
		_status = status;
		_value = value;
		assert(_value >= 0.0 && _value <= 1.0, "Progress value must be between 0.0 and 1.0.");
	}


	///
	@property void status(in Dwstring status) // setter
	{
		_status = status;
	}

	///
	@property Dwstring status() const // getter
	{
		return _status;
	}


	///
	@property void value(in double v) // setter
	{
		_value = v;
	}

	///
	@property double value() const // getter
	{
		return _value;
	}


	///
	@property void title(in Dwstring text) // setter
	{
		_title = text;
	}

	/// ditto
	@property Dwstring title() const // getter
	{
		return _title;
	}


	///
	@property void valueStringOverride(in Dwstring text) // setter
	{
		_valueStringOverride = text;
	}

	/// ditto
	@property Dwstring valueStringOverride() const // getter
	{
		return _valueStringOverride;
	}


	///
	@property Dwstring toXmlElement() const // getter
	{
		return
			"<progress title='{progressTitle}' " ~
			"status='{progressStatus}' " ~
			"value='{progressValue}' " ~
			"valueStringOverride='{progressValueStringOverride}' />"w;
	}


private:
	Dwstring _status; ///
	double _value; ///
	Dwstring _title; ///
	Dwstring _valueStringOverride; ///
}


///
class ToastNotifierLegacy // docmain
{
	///
	static this()
	{
		templates[ToastTemplateType.TOAST_IMAGE_AND_TEXT_01] = "ToastImageAndText01";
		templates[ToastTemplateType.TOAST_IMAGE_AND_TEXT_02] = "ToastImageAndText02";
		templates[ToastTemplateType.TOAST_IMAGE_AND_TEXT_03] = "ToastImageAndText03";
		templates[ToastTemplateType.TOAST_IMAGE_AND_TEXT_04] = "ToastImageAndText04";
		templates[ToastTemplateType.TOAST_TEXT_01] = "ToastText01";
		templates[ToastTemplateType.TOAST_TEXT_02] = "ToastText02";
		templates[ToastTemplateType.TOAST_TEXT_03] = "ToastText03";
		templates[ToastTemplateType.TOAST_TEXT_04] = "ToastText04";
	}


	///
	this(in Dwstring aumid)
	{
		_notifier = new ToastNotifier(aumid);
	}


	///
	void show()
	{
		Dwstring xml = format(r"
			<toast>
				<visual>
					<binding template='%s'>
						<text id='1'>%s</text>
						<text id='2'>%s</text>
						<text id='3'>%s</text>
						<image id='1' src='%s'/>
					</binding>
				</visual>
			</toast>"w,
			templates[_toastTemplateType],
			_headline,
			_text,
			_subtext,
			_appLogoImagePath
		);
		_showCore(xml, ""w, ""w);
	}


	///
	@property void toastTemplate(in ToastTemplateType type) // setter
	{
		_toastTemplateType = type;
	}

	/// ditto
	@property ToastTemplateType toastTemplate() const // getter
	{
		return _toastTemplateType;
	}


	ToastNotifier _notifier; ///
	alias _notifier this;

private:

	static Dstring[ToastTemplateType] templates; ///
	ToastTemplateType _toastTemplateType; ///
}


///
enum ToastTemplateType
{
	TOAST_IMAGE_AND_TEXT_01 = dfl.internal.winrt.ToastTemplateType.ToastImageAndText01, ///
	TOAST_IMAGE_AND_TEXT_02 = dfl.internal.winrt.ToastTemplateType.ToastImageAndText02, ///
	TOAST_IMAGE_AND_TEXT_03 = dfl.internal.winrt.ToastTemplateType.ToastImageAndText03, ///
	TOAST_IMAGE_AND_TEXT_04 = dfl.internal.winrt.ToastTemplateType.ToastImageAndText04, ///
	TOAST_TEXT_01 = dfl.internal.winrt.ToastTemplateType.ToastText01, ///
	TOAST_TEXT_02 = dfl.internal.winrt.ToastTemplateType.ToastText02, ///
	TOAST_TEXT_03 = dfl.internal.winrt.ToastTemplateType.ToastText03, ///
	TOAST_TEXT_04 = dfl.internal.winrt.ToastTemplateType.ToastText04 ///
}


///
enum ToastNotifierImageStyle
{
	INLINE, ///
	HERO ///
}


///
struct PROPERTYKEY
{
	GUID fmtid;
	DWORD pid;
}


extern (Windows)
{
__gshared:
extern:
	// propsys.h
	// https://learn.microsoft.com/en-us/windows/win32/api/propsys/nn-propsys-ipropertystore
	const IID IID_IPropertyStore; // { 0x886d8eeb, 0x8cf2, 0x4446, [0x8d, 0x02, 0xcd, 0xba, 0x1d, 0xbd, 0xcf, 0x99] }
	
	// notificationactivationcallback.h
	// https://learn.microsoft.com/en-us/windows/win32/api/notificationactivationcallback/nn-notificationactivationcallback-inotificationactivationcallback
	const IID IID_INotificationActivationCallback; // { 0x53E31837, 0x6600, 0x4A81, [0x93, 0x95, 0x75, 0xCF, 0xFE, 0x74, 0x6F, 0x94] }
	
	// Propkey.h
	// https://learn.microsoft.com/en-us/windows/win32/properties/props-system-appusermodel-id?source=recommendations
	const PROPERTYKEY PKEY_AppUserModel_ID; // {{0x9F4C2855, 0x9F79, 0x4B39, [0xA8, 0xD0, 0xE1, 0xD4, 0x2D, 0xE1, 0xD5, 0xF3]}, 5 }
	
	// Propkey.h
	// https://learn.microsoft.com/en-us/windows/win32/properties/props-system-appusermodel-toastactivatorclsid
	const PROPERTYKEY PKEY_AppUserModel_ToastActivatorCLSID;// = { {0x9F4C2855, 0x9F79, 0x4B39, [0xA8, 0xD0, 0xE1, 0xD4, 0x2D, 0xE1, 0xD5, 0xF3]}, 26 }
}

extern (Windows)
{
__gshared:
	/// Predefined Notification Activator CLSID by DFL.
	CLSID DFL_CLSID_NOTIFICATION_ACTIVATOR = clsidFromUUID("{64539c9a-c2da-4349-b9af-c5126944f6fc}");
}


///
CLSID clsidFromUUID(string uuidString)
{
	return guidFromUUID(uuidString[1..$-1]);
}


///
string uuidFromClsid(in REFCLSID clsid)
{
	return uuidFromGUID(clsid);
}


///
interface INotificationActivationCallBack : IUnknown
{
extern (Windows):
	HRESULT Activate(LPCWSTR appUserModelId, LPCWSTR invokedArgs, const NOTIFICATION_USER_INPUT_DATA* data, ULONG count);
}


///
private class NotificationActivatorBase : DflComObject, INotificationActivationCallBack
{
extern (Windows):
	///
	override HRESULT QueryInterface(IID* riid, void** ppv)
	{
		if (*riid == IID_INotificationActivationCallback)
		{
			*ppv = cast(void*)cast(INotificationActivationCallBack)this;
			AddRef();
			return S_OK;
		}
		return super.QueryInterface(riid, ppv);
	}


	///
	HRESULT Activate(LPCWSTR appUserModelId, LPCWSTR invokedArgs, const NOTIFICATION_USER_INPUT_DATA* data, ULONG count)
	{
		auto args = new ToastActivatedEventArgs(appUserModelId, invokedArgs, data, count);
		_cumtomActivator.onActivated(_cumtomActivator, args);
		return S_OK;
	}

extern(D):
	///
	void Attach(NotificationActivator activator)
	in
	{
		assert(activator);
	}
	do
	{
		_cumtomActivator = activator;
	}

private:
	NotificationActivator _cumtomActivator; ///
}


///
class NotificationActivator
{
	///
	void onActivated(NotificationActivator activator, ToastActivatedEventArgs args)
	{
		activated(activator, args);
	}

	///
	Event!(NotificationActivator, ToastActivatedEventArgs) activated;
}


///
class ToastActivatedEventArgs : EventArgs
{
	///
	this(in LPCWSTR appUserModelId, in LPCWSTR invokedArgs, const NOTIFICATION_USER_INPUT_DATA* data, in ULONG count)
	{
		_aumid = appUserModelId;
		_args = invokedArgs;
		_data = data;
		_count = count;
	}


	///
	@property Dwstring arguments() const // getter
	{
		return fromUnicodez(cast(wchar*)_args).to!Dwstring;
	}


	///
	@property Dwstring[Dwstring] userInputs() const // getter
	{
		Dwstring[Dwstring] result;
		foreach (i; 0 .. _count)
		{
			Dwstring key = _data[i].Key[0 .. wcslen(_data[i].Key)].to!Dwstring;
			Dwstring value = _data[i].Value[0 .. wcslen(_data[i].Value)].to!Dwstring;
			result[key] = value;
		}
		return result;
	}


private:
	const LPCWSTR _aumid; ///
	const LPCWSTR _args; ///
	const NOTIFICATION_USER_INPUT_DATA* _data; ///
	const ULONG _count; ///

}


///
class NotificationActivatorFactory : DflComObject, IClassFactory
{
extern (Windows):
	///
	override HRESULT QueryInterface(IID* riid, void** ppv)
	{
		if (*riid == IID_IClassFactory)
		{
			*ppv = cast(void*)cast(IClassFactory)this;
			AddRef();
			return S_OK;
		}
		return super.QueryInterface(riid, ppv);
	}


	///
	HRESULT CreateInstance(IUnknown pUnkOuter, REFIID riid, void** ppvObject)
	{
		if (pUnkOuter)
			return CLASS_E_NOAGGREGATION;
		
		auto activator = new NotificationActivatorBase(); // Create COM Activator.
		scope(exit)
		{
			activator.Release();
			activator = null;
		}
		activator.Attach(_cumtomActivator);

		return activator.QueryInterface(riid, ppvObject);
	}


	///
	HRESULT LockServer(BOOL fLock)
	{
		return S_OK;
	}

extern(D):
	///
	this(NotificationActivator activator)
	{
		_cumtomActivator = activator;
	}

private:
	NotificationActivator _cumtomActivator; ///
}


///
struct NOTIFICATION_USER_INPUT_DATA
{
	LPCWSTR Key;
	LPCWSTR Value;
}


///
interface IPropertyStore : IUnknown
{
extern (Windows):
	HRESULT GetCount(DWORD* cProps);
	HRESULT GetAt(DWORD iProp, PROPERTYKEY* pkey);
	HRESULT GetValue(PROPERTYKEY* key, PROPVARIANT* pv);
	HRESULT SetValue(const(PROPERTYKEY*) key, PROPVARIANT* propvar);
	HRESULT Commit();
}


extern(Windows)
{
	// Propsys.lib
	HRESULT InitPropVariantFromCLSID(REFCLSID clsid, PROPVARIANT* ppropvar);
	HRESULT PropVariantClear(PROPVARIANT* pvar);
}


///
// propvarutil.h
HRESULT InitPropVariantFromString(in PCWSTR psz, PROPVARIANT* ppropvar)
{
	HRESULT hr = SHStrDupW(psz, &ppropvar.pwszVal);
	if (hr == S_OK)
		ppropvar.vt = VARENUM.VT_LPWSTR;
	else
		PropVariantInit(ppropvar);
	return hr;
}


///
// propvarutil.h
void PropVariantInit(PROPVARIANT* pvar)
{
	memset(pvar, 0, PROPVARIANT.sizeof);
}


///
class ShellLinkWithAumidAndClsid
{
	///
	this(in Dwstring exePath, in Dwstring shortcutPath, in Dwstring aumid, in REFCLSID clsid)
	{
		_exePath = exePath;
		_shortcutPath = shortcutPath;
		_aumid = aumid;
		_clsid = clsid;
	}


	///
	void install()
	in
	{
		assert(_exePath.length > 0);
		assert(_shortcutPath.length > 0);
		assert(_aumid.length > 0);
		assert(_clsid && (*_clsid != GUID_NULL));
	}
	do
	{
		HRESULT hr;

		IShellLinkW shellLink;
		hr = CoCreateInstance(&CLSID_ShellLink, null, CLSCTX_INPROC_SERVER, &IID_IShellLinkW, cast(LPVOID*)&shellLink);
		assert(shellLink);
		assert(hr == S_OK, "CoCreateInstance(CLSID_ShellLink) failed");
		scope (exit)
		{
			shellLink.Release();
			shellLink = null;
		}

		hr = shellLink.SetPath(_exePath.ptr);
		assert(hr == S_OK, "IShellLinkW.SetPath() failed");

		IPropertyStore propertyStore;
		hr = shellLink.QueryInterface(&IID_IPropertyStore, cast(LPVOID*)&propertyStore);
		assert(propertyStore);
		assert(hr == S_OK, "IPropertyStore.QueryInterface(IID_IPropertyStore) failed");
		scope (exit)
		{
			propertyStore.Release();
			propertyStore = null;
		}
		
		PROPVARIANT propAumid;
		PropVariantInit(&propAumid);
		hr = InitPropVariantFromString(_aumid.ptr, &propAumid);
		assert(hr == S_OK, "InitPropVariantFromString() failed");
		hr = propertyStore.SetValue(&PKEY_AppUserModel_ID, &propAumid);
		assert(hr == S_OK, "IPropertyStore.SetValue() failed");
		// 
		PROPVARIANT propClsId;
		PropVariantInit(&propClsId);
		hr = InitPropVariantFromCLSID(_clsid, &propClsId);
		assert(hr == S_OK, "InitPropVariantFromCLSID() failed");
		hr = propertyStore.SetValue(&PKEY_AppUserModel_ToastActivatorCLSID, &propClsId);
		assert(hr == S_OK, "IPropertyStore.SetValue() failed");
		
		hr = propertyStore.Commit();
		assert(hr == S_OK, "IPropertyStore.Commit() failed");

		hr = PropVariantClear(&propAumid);
		assert(hr == S_OK, "PropVariantClear() failed");
		hr = PropVariantClear(&propClsId);
		assert(hr == S_OK, "PropVariantClear() failed");

		IPersistFile persistFile;
		hr = shellLink.QueryInterface(&IID_IPersistFile, cast(LPVOID*)&persistFile);
		assert(persistFile);
		assert(hr == S_OK, "QueryInterface(IID_IPersistFile) failed");
		scope (exit)
		{
			persistFile.Release();
			persistFile = null;
		}
		
		hr = persistFile.Save(_shortcutPath.ptr, TRUE);
		assert(hr == S_OK, "IPersistFile.Save() failed");

		_isInstalled = true;
	}


	///
	void uninstall()
	in
	{
		assert(_shortcutPath.length > 0);
	}
	do
	{
		if (_isInstalled)
		{
			DeleteFile(_shortcutPath.ptr);
			_isInstalled = false;
		}
	}

private:

	bool _isInstalled; ///
	const Dwstring _exePath; ///
	const Dwstring _shortcutPath; ///
	const Dwstring _aumid; ///
	const REFCLSID _clsid; ///
}


///
scope class DesktopNotificationManager
{
	/// Constructor.
	this(in Dstring[] launchArgs, in Dwstring aumid, in REFCLSID clsid)
	{
		_aumid = aumid;
		_clsid = clsid;

		_exePath = Application.executablePath.to!Dwstring;
		_exeName = _exePath.baseName;
		_appName = _exeName.stripExtension;
		_programPath = Environment.getFolderPath(Environment.SpecialFolder.PROGRAMS).to!Dwstring;
		_shortcutPath = buildNormalizedPath(_programPath, _appName.setExtension("lnk"w));
		
		_shell = new ShellLinkWithAumidAndClsid(_exePath, _shortcutPath, _aumid, _clsid);

		if (launchArgs.canFind("-Embedding"))
		{
			// COM server launched this App.
			// You can do something for launched App.
			_mode = DesktopNotificationMode.LAUNCH;
		}
		else
		{
			_mode = DesktopNotificationMode.NORMAL;
		}
	}


	/// Destructor.
	~this()
	{
		unregisterActivator();
	}


	/// Install ShellLink with AUMID and CLSID to StartMenu.
	void installShellLink()
	{
		_shell.install();
		Sleep(3000); // NOTE: Wait for the shell to recognize the AUMID.
	}


	/// Uninstall ShellLink from StartMenu.
	void uninstallShellLink()
	{
		if (!_shell)
			throw new DflException("DFL: DesktopNotificationManager.uninstallShellLink failure.");
		_shell.uninstall();
	}


	/// Register Toast Activator.
	void registerActivator(NotificationActivator customActivator = new NotificationActivator)
	{
		if (_activatorFactory)
		{
			_activatorFactory.Release();
			_activatorFactory = null;

			HRESULT hr = CoRevokeClassObject(_registerClassToken);
			assert(hr == S_OK);
		}
		
		assert(!_activatorFactory);
		_activatorFactory = new NotificationActivatorFactory(customActivator);

		HRESULT hr = CoRegisterClassObject(_clsid, _activatorFactory, CLSCTX_LOCAL_SERVER, REGCLS.REGCLS_MULTIPLEUSE, &_registerClassToken);
		assert(hr == S_OK);

		assert(!_activator);
		_activator = customActivator;
	}


	/// Unregister Toast Activator.
	void unregisterActivator()
	{
		if (_activatorFactory)
		{
			_activatorFactory.Release();
			_activatorFactory = null;

			HRESULT hr = CoRevokeClassObject(_registerClassToken);
			assert(hr == S_OK);
		}
	}
	

	/// Register AUMID and Toast Activator CLSID.
	void registerAumidAndComServer()
	{
		string uuid = uuidFromGUID(_clsid);

		// Install Toast Activator CLSID.
		//   \HKEY_CURRENT_USER\SOFTWARE\Classes\CLSID\{Toast Activator CLSID}\LocalServer32
		//
		scope RegistryKey clsid = Registry.currentUser().openSubKey("SOFTWARE").openSubKey("Classes").openSubKey("CLSID");
		// Create CLSID for COM Activator.
		clsid.createSubKey(uuid).createSubKey("LocalServer32")
			.setValue("", "\"" ~ _exePath.to!Dstring ~ "\""); // Need "double quotation"
		clsid.flush();

		// Install AUMID.
		//   \HKEY_CURRENT_USER\SOFTWARE\Classes\AppUserModelId\{Your AUMID}
		//
		// Create AUMID for GenericToast in Toast XML.
		scope RegistryKey aumid = Registry.currentUser().openSubKey("SOFTWARE").openSubKey("Classes").openSubKey("AppUserModelId");
		// Create AUMID for COM Activator.
		aumid.createSubKey(_aumid.to!Dstring).setValue("ToastActivatorCLSID", uuid);
		aumid.flush();
	}


	/// Unregister AUMID and Toast Activator CLSID.
	void unregisterAumidAndComServer()
	{
		string uuid = uuidFromGUID(_clsid);

		// Uninstall Toast Activator CLSID.
		scope RegistryKey clsidKey = Registry.currentUser().openSubKey("SOFTWARE").openSubKey("Classes").openSubKey("CLSID");
		clsidKey.openSubKey(uuid).deleteSubKey("LocalServer32");
		clsidKey.deleteSubKey(uuid);
		clsidKey.flush();

		// Uninstall AUMID.
		scope RegistryKey aumidKey = Registry.currentUser().openSubKey("SOFTWARE").openSubKey("Classes").openSubKey("AppUserModelId");
		aumidKey.deleteSubKey(_aumid.to!Dstring);
		aumidKey.flush();
	}


	///
	@property DesktopNotificationMode mode() const // getter
	{
		return _mode;
	}

private:
	ShellLinkWithAumidAndClsid _shell; ///
	const DesktopNotificationMode _mode; ///

	const Dwstring _aumid; ///
	const REFCLSID _clsid; ///
	const Dwstring _exePath; ///
	const Dwstring _exeName; ///
	const Dwstring _appName; ///
	const Dwstring _programPath; ///
	const Dwstring _shortcutPath; ///

	NotificationActivator _activator; ///
	NotificationActivatorFactory _activatorFactory; ///
	DWORD _registerClassToken; ///
}


///
enum DesktopNotificationMode
{
	NORMAL, ///
	LAUNCH ///
}
