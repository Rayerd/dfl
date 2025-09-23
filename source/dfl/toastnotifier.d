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

import dfl.internal.com : DflComObject;
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
class ToastNotifier // docmain
{
	///
	this(Dwstring aumid)
	{
		_aumid = aumid;
	}
	

	///
	void show()
	{
		static Dwstring createAppLogoXmlElement(ToastNotifier n)
		{
			if (n._appLogoImagePath.length == 0)
				return ""w;
			
			if (n._hintCrop)
				return format("<image placement='appLogoOverride' src='%s' hint-crop='circle' />"w, n._appLogoImagePath);
			else
				return format("<image placement='appLogoOverride' src='%s' />"w, n._appLogoImagePath);
		}

		static Dwstring createImageXmlElement(ToastNotifier n)
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

		static Dwstring createInputXmlElement(ToastNotifier n)
		{
			Dwstring ret;
			foreach (input; n.inputs)
				ret ~= input.toXmlElement ~ "\n"w;
			return ret;
		}

		static Dwstring createButtonXmlElement(ToastNotifier n)
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
						<text>%s</text>
						<text>%s</text>
						<text>%s</text>
						%s
						%s
					</binding>
				</visual>
				<actions>
					%s
					%s
				</actions>
			</toast>"w,
			_launch,
			_useButtonStyle ? "true" : "false",
			_headline,
			_text,
			_subtext,
			createAppLogoXmlElement(this),
			createImageXmlElement(this),
			createInputXmlElement(this),
			createButtonXmlElement(this)
		);
		showCore(xml);
	}


	///
	private void showCore(Dwstring xml)
	{
		HRESULT hr;

		// 1. Get ActivationFactory of ToastNotificationManager class.
		IToastNotificationManagerStatics toastStatics;
		HSTRING hClass = toHSTRING("Windows.UI.Notifications.ToastNotificationManager"w);
		hr = RoGetActivationFactory(hClass, &IID_IToastNotificationManagerStatics, cast(void**)&toastStatics);
		assert(toastStatics);
		assert(hr == S_OK, "Failed to get ToastNotificationManager statics");
		freeHSTRING(hClass);
		scope(exit)
		{
			toastStatics.Release();
			toastStatics = null;
		}

		// 2. Create Notifier.
		IToastNotifier notifier;
		HSTRING hAumid = toHSTRING(_aumid);
		hr = toastStatics.CreateToastNotifierWithId(hAumid, &notifier);
		assert(notifier);
		assert(hr == S_OK, "Failed to create ToastNotifier");
		freeHSTRING(hAumid);
		scope(exit)
		{
			notifier.Release();
			notifier = null;
		}

		// 3. Create XmlDocument.
		XmlDocument xmlDoc;
		HSTRING hXmlDocClass = toHSTRING("Windows.Data.Xml.Dom.XmlDocument"w);
		hr = RoActivateInstance(hXmlDocClass, cast(IInspectable*)&xmlDoc);
		assert(xmlDoc);
		assert(hr == S_OK, "Failed to activate XmlDocument");
		scope(exit)
		{
			xmlDoc.Release();
			xmlDoc = null;
		}
		
		IXmlDocumentIO xmlDocIO;
		hr = xmlDoc.QueryInterface(&IID_IXmlDocumentIO, cast(void**)&xmlDocIO);
		assert(xmlDocIO);
		assert(hr == S_OK, "Failed to activate XmlDocumentIO");
		freeHSTRING(hXmlDocClass);
		scope(exit)
		{
			xmlDocIO.Release();
			xmlDocIO = null;
		}

		// 4. Load XML.
		HSTRING hXml = toHSTRING(xml);
		hr = xmlDocIO.LoadXml(hXml);
		assert(hr == S_OK, "Failed to load XML");
		freeHSTRING(hXml);

		// 5. Create ToastNotification.
		IToastNotificationFactory toastFactory;
		HSTRING hToastClass = toHSTRING("Windows.UI.Notifications.ToastNotification"w);
		hr = RoGetActivationFactory(hToastClass, &IID_IToastNotificationFactory, cast(void**)&toastFactory);
		assert(toastFactory);
		assert(hr == S_OK, "Failed to get ToastNotificationFactory");
		freeHSTRING(hToastClass);
		scope(exit)
		{
			toastFactory.Release();
			toastFactory = null;
		}

		IToastNotification toast;
		hr = toastFactory.CreateToastNotification(xmlDoc, &toast);
		assert(toast);
		assert(hr == S_OK, "Failed to create ToastNotification");
		scope(exit)
		{
			toast.Release();
			toast = null;
		}

		// 6. Show toast.
		hr = notifier.Show(toast);
		assert(hr == S_OK, "Failed to show toast");
	}


	/// Set launch arguments within XML escape.
	void setLaunch(Dwstring txt, bool enableEscape = true)
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
	@property void launch(Dwstring txt) // setter
	{
		_launch = txt;
	}

	/// Get launch arguments.
	@property Dwstring launch() const // getter
	{
		return _launch;
	}
	
	///
	@property void useButtonStyle(bool byes) // setter
	{
		_useButtonStyle = byes;
	}

	/// ditto
	@property bool useButtonStyle() const // getter
	{
		return _useButtonStyle;
	}


	///
	@property void headline(Dwstring txt) // setter
	{
		_headline = txt;
	}

	/// ditto
	@property Dwstring headline() const // getter
	{
		return _headline;
	}


	///
	@property void text(Dwstring txt) // setter
	{
		_text = txt;
	}
	
	/// ditto
	@property Dwstring text() const // getter
	{
		return _text;
	}
	

	///
	@property void subtext(Dwstring txt) // setter
	{
		_subtext = txt;
	}
	
	/// ditto
	@property Dwstring subtext() const // getter
	{
		return _subtext;
	}
	

	///
	@property void appLogoImagePath(Dwstring path) // setter
	{
		_appLogoImagePath = path;
	}

	/// ditto
	@property Dwstring appLogoImagePath() const // getter
	{
		return _appLogoImagePath;
	}

	
	///
	@property void imagePath(Dwstring path) // setter
	{
		_imagePath = path;
	}

	/// ditto
	@property Dwstring imagePath() const // getter
	{
		return _imagePath;
	}

	
	///
	@property void imageStyle(ToastNotifierImageStyle style) // setter
	{
		_imageStyle = style;
	}

	/// ditto
	@property ToastNotifierImageStyle imageStyle() const // getter
	{
		return _imageStyle;
	}


	///
	@property void hintCrop(bool byes) // setter
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


	///
	@property ToastTextBoxCollection inputs() // getter
	{
		return _inputs;
	}


private:
	Dwstring _aumid; ///
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
	int opApply(scope int delegate(ItemType) dg)
	{
		int result = 0;
		foreach (item; _items)
		{
			result = dg(item);
			if (result)
				break;
		}
		return result;
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
	this(Dwstring id, Dwstring title, Dwstring placeHolderContent)
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
	@property void title(Dwstring title) // setter
	{
		_title = title;
	}

	/// ditto
	@property Dwstring title() const // getter
	{
		return _title;
	}


	///
	@property void placeHolderContent(Dwstring placeHolderContent) // setter
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
	this(Dwstring id, Dwstring title, Dwstring placeHolderContent, Dwstring defaultInput)
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
	@property void title(Dwstring title) // setter
	{
		_title = title;
	}

	/// ditto
	@property Dwstring title() const // getter
	{
		return _title;
	}


	///
	@property void placeHolderContent(Dwstring placeHolderContent) // setter
	{
		_placeHolderContent = placeHolderContent;
	}

	/// ditto
	@property Dwstring placeHolderContent() const // getter
	{
		return _placeHolderContent;	
	}

	
	///
	@property void defaultInput(Dwstring defaultInput) // setter
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
	this(Dwstring id, Dwstring content)
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
	this(Dwstring content, Dwstring arguments)
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
	@property void buttonStyle(ToastButtonStyle buttonStyle) // setter
	{
		_buttonStyle = buttonStyle;
	}

	/// ditto
	@property ToastButtonStyle buttonStyle() const // getter
	{
		return _buttonStyle;
	}


	///
	@property void activationType(ToastActivationType type) // setter
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
	Dwstring toString(ToastButtonStyle buttonStyle) const
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
	this(Dwstring aumid)
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
		showCore(xml);
	}


	///
	@property void toastTemplate(ToastTemplateType type) // setter
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
	TOAST_IMAGE_AND_TEXT_01 = 0, ///
	TOAST_IMAGE_AND_TEXT_02 = 1, ///
	TOAST_IMAGE_AND_TEXT_03 = 2, ///
	TOAST_IMAGE_AND_TEXT_04 = 3, ///
	TOAST_TEXT_01 = 4, ///
	TOAST_TEXT_02 = 5, ///
	TOAST_TEXT_03 = 6, ///
	TOAST_TEXT_04 = 7 ///
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
	// propsys.h
	// https://learn.microsoft.com/en-us/windows/win32/api/propsys/nn-propsys-ipropertystore
	const IID IID_IPropertyStore = { 0x886d8eeb, 0x8cf2, 0x4446, [0x8d, 0x02, 0xcd, 0xba, 0x1d, 0xbd, 0xcf, 0x99] };
	
	// notificationactivationcallback.h
	// https://learn.microsoft.com/en-us/windows/win32/api/notificationactivationcallback/nn-notificationactivationcallback-inotificationactivationcallback
	const IID IID_INotificationActivationCallback = { 0x53E31837, 0x6600, 0x4A81, [0x93, 0x95, 0x75, 0xCF, 0xFE, 0x74, 0x6F, 0x94] };
	
	// Propkey.h
	// https://learn.microsoft.com/en-us/windows/win32/properties/props-system-appusermodel-id?source=recommendations
	const PROPERTYKEY PKEY_AppUserModel_ID = {
		{0x9F4C2855, 0x9F79, 0x4B39, [0xA8, 0xD0, 0xE1, 0xD4, 0x2D, 0xE1, 0xD5, 0xF3]}, 5
	};
	
	// Propkey.h
	// https://learn.microsoft.com/en-us/windows/win32/properties/props-system-appusermodel-toastactivatorclsid
	const PROPERTYKEY PKEY_AppUserModel_ToastActivatorCLSID = {
		{0x9F4C2855, 0x9F79, 0x4B39, [0xA8, 0xD0, 0xE1, 0xD4, 0x2D, 0xE1, 0xD5, 0xF3]}, 26
	};
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
string uuidFromClsid(REFCLSID clsid)
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
	this(LPCWSTR appUserModelId, LPCWSTR invokedArgs, const NOTIFICATION_USER_INPUT_DATA* data, ULONG count)
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
HRESULT InitPropVariantFromString(PCWSTR psz, PROPVARIANT* ppropvar)
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
	this(Dstring[] launchArgs, Dwstring aumid, REFCLSID clsid)
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
		if (!_activatorFactory)
			throw new DflException("DFL: unregisterActivator failure.");

		_activatorFactory.Release();
		_activatorFactory = null;

		HRESULT hr = CoRevokeClassObject(_registerClassToken);
		assert(hr == S_OK);
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
