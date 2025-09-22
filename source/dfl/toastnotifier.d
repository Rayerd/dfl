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

import core.sys.windows.basetyps : REFIID, REFCLSID;
import core.sys.windows.com;
import core.sys.windows.objbase : CoRevokeClassObject, CoRegisterClassObject, REGCLS;
import core.sys.windows.objidl : PROPVARIANT, IPersistFile;
import core.sys.windows.shlobj : IShellLinkW;
import core.sys.windows.shlwapi : SHStrDupW;
import core.sys.windows.winbase : Sleep, DeleteFile;
import core.sys.windows.windef;
import core.sys.windows.wtypes : VARENUM;

import std.conv : to;


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
		import std.format;
		Dwstring xml = format(r"
			<toast launch='%s' useButtonStyle='%s'>
				<visual>
					<binding template='ToastGeneric'>
						<text>%s</text>
						<text>%s</text>
						<text>%s</text>
						<image %s %s/>
						<image %s/>
					</binding>
				</visual>" ~
				// <actions>
				// 	<input id='message' type='text' placeHolderContent='Input message here' title='Message'/>
				// 	<input id='mode' type='selection' title='Mode' defaultInput='fast'>
				// 		<selection id='fast' content='Fast'/>
				// 		<selection id='slow' content='Slow'/>
				// 	</input>
				// 	<action activationType='foreground' content='Ok' arguments='action=OkButton&amp;userId=49183' type='one' hint-buttonStyle='Success'/>
				// 	<action activationType='background' content='Cancel' arguments='action=CancelButton&amp;userId=49183' type='two' hint-buttonStyle='Success'/>
				// 	<action activationType='protocol' content='Open Google' arguments='https://www.google.com/' type='three' hint-buttonStyle='Critical'/>
				// </actions>
			"</toast>",
			_launch,
			_useButtonStyle ? "true" : "false",
			_headline,
			_text,
			_subtext,
			_appLogoImage.length ? format("placement='appLogoOverride' src='%s'", _appLogoImage) : "",
			_hintCrop ? "hint-crop='circle'" : "",
			_heroImage.length ? format("placement='hero' src='%s'", _heroImage) : ""
		).to!Dwstring;
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
		HSTRING hAppId = toHSTRING(_aumid.to!Dwstring);
		hr = toastStatics.CreateToastNotifierWithId(hAppId, &notifier);
		assert(notifier);
		assert(hr == S_OK, "Failed to create ToastNotifier");
		freeHSTRING(hAppId);
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


	///
	@property void launch(Dwstring txt) // setter
	{
		_launch = txt;
	}

	/// ditto
	@property Dwstring launch() // gettitle
	{
		return _launch;
	}
	
	///
	@property void useButtonStyle(bool byes) // setter
	{
		_useButtonStyle = byes;
	}

	/// ditto
	@property bool useButtonStyle() // gettitle
	{
		return _useButtonStyle;
	}


	///
	@property void headline(Dwstring txt) // setter
	{
		_headline = txt;
	}

	/// ditto
	@property Dwstring headline() // gettitle
	{
		return _headline;
	}


	///
	@property void text(Dwstring txt) // setter
	{
		_text = txt;
	}
	
	/// ditto
	@property Dwstring text() // getter
	{
		return _text;
	}
	

	///
	@property void subtext(Dwstring txt) // setter
	{
		_subtext = txt;
	}
	
	/// ditto
	@property Dwstring subtext() // getter
	{
		return _subtext;
	}
	

	///
	@property void appLogoImage(Dwstring path) // setter
	{
		_appLogoImage = path;
	}

	/// ditto
	@property Dwstring appLogoImage() // getter
	{
		return _appLogoImage;
	}

	
	///
	@property void heroImage(Dwstring path) // setter
	{
		_heroImage = path;
	}

	/// ditto
	@property Dwstring heroImage() // getter
	{
		return _heroImage;
	}

	
	///
	@property void hintCrop(bool byes) // setter
	{
		_hintCrop = byes;
	}

	/// ditto
	@property bool hintCrop() // getter
	{
		return _hintCrop;
	}


private:
	Dwstring _aumid; ///
	Dwstring _launch; ///
	bool _useButtonStyle; ///
	Dwstring _headline; ///
	Dwstring _text; ///
	Dwstring _subtext; ///
	Dwstring _appLogoImage; ///
	Dwstring _heroImage; ///
	bool _hintCrop; ///
}


///
class ToastNotifierLegacy // docmain
{
	///
	static this()
	{
		templates[ToastTemplateType.ToastImageAndText01] = "ToastImageAndText01";
		templates[ToastTemplateType.ToastImageAndText02] = "ToastImageAndText02";
		templates[ToastTemplateType.ToastImageAndText03] = "ToastImageAndText03";
		templates[ToastTemplateType.ToastImageAndText04] = "ToastImageAndText04";
		templates[ToastTemplateType.ToastText01] = "ToastText01";
		templates[ToastTemplateType.ToastText02] = "ToastText02";
		templates[ToastTemplateType.ToastText03] = "ToastText03";
		templates[ToastTemplateType.ToastText04] = "ToastText04";
	}


	///
	this(Dwstring aumid)
	{
		_notifier = new ToastNotifier(aumid);
	}


	///
	void show()
	{
		import std.format;
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
			</toast>",
			templates[_toastTemplateType],
			_headline,
			_text,
			_subtext,
			_appLogoImage
		).to!Dwstring;
		showCore(xml);
	}


	///
	@property void toastTemplate(ToastTemplateType type) // setter
	{
		_toastTemplateType = type;
	}

	/// ditto
	@property ToastTemplateType toastTemplate() // getter
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
	ToastImageAndText01 = 0,
	ToastImageAndText02 = 1,
	ToastImageAndText03 = 2,
	ToastImageAndText04 = 3,
	ToastText01 = 4,
	ToastText02 = 5,
	ToastText03 = 6,
	ToastText04 = 7,
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
	///
	const IID IID_IPropertyStore = { 0x886d8eeb, 0x8cf2, 0x4446, [0x8d, 0x02, 0xcd, 0xba, 0x1d, 0xbd, 0xcf, 0x99] };
	///
	const IID IID_INotificationActivationCallback = { 0x53E31837, 0x6600, 0x4A81, [0x93, 0x95, 0x75, 0xCF, 0xFE, 0x74, 0x6F, 0x94] };
	///
	const PROPERTYKEY PKEY_AppUserModel_ID = {
		{0x9F4C2855, 0x9F79, 0x4B39, [0xA8, 0xD0, 0xE1, 0xD4, 0x2D, 0xE1, 0xD5, 0xF3]}, 5
	};
	///
	const PROPERTYKEY PKEY_AppUserModel_ToastActivatorCLSID = {
		{0x9F4C2855, 0x9F79, 0x4B39, [0xA8, 0xD0, 0xE1, 0xD4, 0x2D, 0xE1, 0xD5, 0xF3]}, 26
	};
	///
	enum UUID_NOTIFICATION_ACTIVATOR = "{64539c9a-c2da-4349-b9af-c5126944f6fc}";
	CLSID CLSID_NOTIFICATION_ACTIVATOR = guidFromUUID(UUID_NOTIFICATION_ACTIVATOR[1..$-1]);
}


interface INotificationActivationCallBack : IUnknown
{
extern (Windows):
	HRESULT Activate(LPCWSTR appUserModelId, LPCWSTR invokedArgs, const NOTIFICATION_USER_INPUT_DATA* data, ULONG count);
}


///
// uuid("64539c9a-c2da-4349-b9af-c5126944f6fc")
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
		_appId = appUserModelId;
		_args = invokedArgs;
		_data = data;
		_count = count;
	}


	///
	@property Dwstring arguments() const
	{
		import dfl.internal.utf : fromUnicodez;
		return fromUnicodez(cast(wchar*)_args).to!Dwstring;
	}


	///
	@property Dwstring[Dwstring] userInputs() const
	{
		import core.stdc.wchar_ : wcslen;
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
	LPCWSTR _appId; ///
	LPCWSTR _args; ///
	const NOTIFICATION_USER_INPUT_DATA* _data; ///
	ULONG _count; ///

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
void PropVariantInit(PROPVARIANT* pvar)
{
	import core.stdc.string : memset;
	memset(pvar, 0, PROPVARIANT.sizeof);
}


///
class ShellLinkWithAppIdAndClsId
{
	///
	this(in Dwstring exePath, in Dwstring shortcutPath, in Dwstring aumid, in CLSID clsId)
	{
		_exePath = exePath;
		_shortcutPath = shortcutPath;
		_aumid = aumid;
		_clsId = clsId;
	}


	///
	void install()
	in
	{
		assert(_exePath.length > 0);
		assert(_shortcutPath.length > 0);
		assert(_aumid.length > 0);
		assert(_clsId != GUID.init);
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
		
		PROPVARIANT propAppId;
		PropVariantInit(&propAppId);
		hr = InitPropVariantFromString(_aumid.ptr, &propAppId);
		assert(hr == S_OK, "InitPropropAppIdariantFromString() failed");
		hr = propertyStore.SetValue(&PKEY_AppUserModel_ID, &propAppId);
		assert(hr == S_OK, "IPropertyStore.SetValue() failed");
		// 
		PROPVARIANT propClsId;
		PropVariantInit(&propClsId);
		hr = InitPropVariantFromCLSID(&_clsId, &propClsId);
		assert(hr == S_OK, "InitPropVariantFromCLSID() failed");
		hr = propertyStore.SetValue(&PKEY_AppUserModel_ToastActivatorCLSID, &propClsId);
		assert(hr == S_OK, "IPropertyStore.SetValue() failed");
		
		hr = propertyStore.Commit();
		assert(hr == S_OK, "IPropertyStore.Commit() failed");

		hr = PropVariantClear(&propAppId);
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
	Dwstring _exePath; ///
	Dwstring _shortcutPath; ///
	Dwstring _aumid; ///
	CLSID _clsId; ///
}


///
scope class DesktopNotificationManager
{
	/// Constructor.
	this(Dstring[] launchArgs, Dwstring aumid)
	{
		_aumid = aumid;

		import std.path;
		_exePath = Application.executablePath.to!Dwstring;
		_exeName = _exePath.baseName;
		_appName = _exeName.stripExtension;
		_programPath = Environment.getFolderPath(Environment.SpecialFolder.PROGRAMS).to!Dwstring;
		_shortcutPath = buildNormalizedPath(_programPath, _appName.setExtension("lnk"w));
		
		_shell = new ShellLinkWithAppIdAndClsId(_exePath, _shortcutPath, aumid, CLSID_NOTIFICATION_ACTIVATOR);

		import std.algorithm : canFind;
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
		import core.sys.windows.winbase : Sleep;
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

		HRESULT hr = CoRegisterClassObject(&CLSID_NOTIFICATION_ACTIVATOR, _activatorFactory, CLSCTX_LOCAL_SERVER, REGCLS.REGCLS_MULTIPLEUSE, &_registerClassToken);
		assert(hr == S_OK);

		assert(!_activator);
		_activator = customActivator;
	}


	/// Unregister Toast Activator.
	void unregisterActivator()
	{
		if (!_activatorFactory)
			throw new DflException("DFL: unregisterActivator failue.");

		_activatorFactory.Release();
		_activatorFactory = null;

		HRESULT hr = CoRevokeClassObject(_registerClassToken);
		assert(hr == S_OK);
	}
	

	/// Register AUMID and Toast Activator CLSID.
	void registerAumidAndComServer()
	{
		// Install Toast Activator CLSID.
		//   \HKEY_CURRENT_USER\SOFTWARE\Classes\CLSID\{Toast Activator CLSID}\LocalServer32
		//
		scope RegistryKey clsid = Registry.currentUser().openSubKey("SOFTWARE").openSubKey("Classes").openSubKey("CLSID");
		// Create CLSID for COM Activator.
		clsid.createSubKey(UUID_NOTIFICATION_ACTIVATOR).createSubKey("LocalServer32")
			.setValue("", "\"" ~ _exePath.to!Dstring ~ "\""); // Need "double quotation"
		clsid.flush();

		// Install AUMID.
		//   \HKEY_CURRENT_USER\SOFTWARE\Classes\AppUserModelId\{Your AUMID}
		//
		// Create AUMID for GenericToast in Toast XML.
		scope RegistryKey aumid = Registry.currentUser().openSubKey("SOFTWARE").openSubKey("Classes").openSubKey("AppUserModelId");
		// Create AUMID for COM Activator.
		aumid.createSubKey(_aumid.to!Dstring).setValue("ToastActivatorCLSID", UUID_NOTIFICATION_ACTIVATOR);
		aumid.flush();
	}


	/// Unregister AUMID and Toast Activator CLSID.
	void unregisterAumidAndComServer()
	{
		// Uninstall Toast Activator CLSID.
		scope RegistryKey clsidKey = Registry.currentUser().openSubKey("SOFTWARE").openSubKey("Classes").openSubKey("CLSID");
		clsidKey.openSubKey(UUID_NOTIFICATION_ACTIVATOR).deleteSubKey("LocalServer32");
		clsidKey.deleteSubKey(UUID_NOTIFICATION_ACTIVATOR);
		clsidKey.flush();

		// Uninstall AUMID.
		scope RegistryKey aumidKey = Registry.currentUser().openSubKey("SOFTWARE").openSubKey("Classes").openSubKey("AppUserModelId");
		aumidKey.deleteSubKey(_aumid.to!Dstring);
		aumidKey.flush();
	}


	///
	@property DesktopNotificationMode mode() // getter
	{
		return _mode;
	}

private:
	ShellLinkWithAppIdAndClsId _shell; ///
	const DesktopNotificationMode _mode; ///

	const Dwstring _aumid; ///
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
