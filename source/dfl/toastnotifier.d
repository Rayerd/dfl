///
module dfl.toastnotifier;

import dfl.base;
import dfl.drawing;

import dfl.internal.dlib;
import dfl.internal.winrt;

import core.sys.windows.com;
import core.sys.windows.oaidl;
import core.sys.windows.objidl;
import core.sys.windows.shlobj;
import core.sys.windows.shlwapi;
pragma(lib, "Shlwapi");
import core.sys.windows.winbase;
import core.sys.windows.windef;
import core.sys.windows.wtypes;

import std.conv;


///
class ToastNotifier // docmain
{
	///
	this(Dwstring appName, Dwstring exePath, Dwstring shortcutPath, Dwstring appId)
	{
		if (appName.length > 0 && exePath.length > 0 && shortcutPath.length > 0 && appId.length > 0)
		{
			_shell = new ShellLinkWithAppId(exePath, shortcutPath, appId);
			_shell.install();
			Sleep(3000); // Wait for the shell to recognize the AUMID.
		}
		_appName = appName;
		_exePath = exePath;
		_shortbutPath = shortcutPath;
		_appId = appId;
	}

	
	///
	void dispose()
	{
		_shell.uninstall();
	}
	
	
	///
	void show()
	{
		import std.format;
		Dwstring xml = format(r"
			<toast>
				<visual>
					<binding template='ToastGeneric'>
						<text>%s</text>
						<text>%s</text>
						<text>%s</text>
						<image placement='appLogoOverride' src='%s' %s/>
						<image placement='hero' src='%s'/>
					</binding>
				</visual>"
				// <actions>
				// 	<action activetionType='foreground' content='Ok' arguments='Ok'/>
				// 	<action activetionType='background' content='Cancel' arguments='Cancel'/>
				// </actions>
			~ "</toast>",
			_headline,
			_text,
			_subtext,
			_appLogoImage,
			_hintCrop ? "hint-crop='circle'" : "",
			_heroImage
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
		scope(exit) toastStatics.Release();

		// 2. Create Notifier.
		IToastNotifier notifier;
		HSTRING hAppId = toHSTRING(_appId.to!Dwstring);
		hr = toastStatics.CreateToastNotifierWithId(hAppId, &notifier);
		assert(notifier);
		assert(hr == S_OK, "Failed to create ToastNotifier");
		freeHSTRING(hAppId);
		scope(exit) notifier.Release();

		// 3. Create XmlDocument.
		XmlDocument xmlDoc;
		HSTRING hXmlDocClass = toHSTRING("Windows.Data.Xml.Dom.XmlDocument"w);
		hr = RoActivateInstance(hXmlDocClass, cast(IInspectable*)&xmlDoc);
		assert(xmlDoc);
		assert(hr == S_OK, "Failed to activate XmlDocument");
		scope(exit) xmlDoc.Release;
		
		IXmlDocumentIO xmlDocIO;
		hr = xmlDoc.QueryInterface(&IID_IXmlDocumentIO, cast(void**)&xmlDocIO);
		assert(xmlDocIO);
		assert(hr == S_OK, "Failed to activate XmlDocumentIO");
		freeHSTRING(hXmlDocClass);
		scope(exit) xmlDocIO.Release();

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
		scope(exit) toastFactory.Release();

		IToastNotification toast;
		hr = toastFactory.CreateToastNotification(xmlDoc, &toast);
		assert(toast);
		assert(hr == S_OK, "Failed to create ToastNotification");
		scope(exit) toast.Release();

		// 6. Show toast.
		hr = notifier.Show(toast);
		assert(hr == S_OK, "Failed to show toast");
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
	
	ShellLinkWithAppId _shell; ///
	Dwstring _appName; ///
	Dwstring _exePath; ///
	Dwstring _shortbutPath; ///
	Dwstring _appId; ///
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
	this(Dwstring appId)
	{
		_notifier = new ToastNotifier("", "", "", appId);
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


extern (Windows)
{
__gshared:
	const IID IID_IPropertyStore = { 0x886d8eeb, 0x8cf2, 0x4446, [0x8d, 0x02, 0xcd, 0xba, 0x1d, 0xbd, 0xcf, 0x99] };
	const IID IID_IPersistFile = { 0x0000010b, 0x0000, 0x0000, [0xc0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x46] };
}


struct PROPERTYKEY
{
	GUID fmtid;
	DWORD pid;
}


extern (Windows) __gshared const PROPERTYKEY PKEY_AppUserModel_ID = {
	{0x9F4C2855, 0x9F79, 0x4B39, [0xA8, 0xD0, 0xE1, 0xD4, 0x2D, 0xE1, 0xD5, 0xF3]}, 5
};


struct VERSIONEDSTREAM
{
	GUID guidVersion;
	IStream pStream;
}


struct CAC
{
	uint cElems;
	byte* pElems;
}


struct PROPVARIANT
{
	union
	{
		struct
		{
			VARTYPE vt;
			ushort /+PROPVAR_PAD1+/ wReserved1;
			ushort /+PROPVAR_PAD2+/ wReserved2;
			ushort /+PROPVAR_PAD3+/ wReserved3;
			union
			{
				CHAR cVal;
				UCHAR bVal;
				SHORT iVal;
				USHORT uiVal;
				LONG lVal;
				ULONG ulVal;
				INT intVal;
				UINT uintVal;
				LARGE_INTEGER hVal;
				ULARGE_INTEGER uhVal;
				FLOAT fltVal;
				DOUBLE dblVal;
				VARIANT_BOOL boolVal;
				VARIANT_BOOL __OBSOLETE__VARIANT_BOOL;
				SCODE scode;
				CY cyVal;
				DATE date;
				FILETIME filetime;
				CLSID* puuid;
				CLIPDATA* pclipdata;
				BSTR bstrVal;
				BSTRBLOB bstrblobVal;
				BLOB blob;
				LPSTR pszVal;
				LPWSTR pwszVal;
				IUnknown* punkVal;
				IDispatch* pdispVal;
				IStream* pStream;
				IStorage* pStorage;
				VERSIONEDSTREAM* pVersionedStream;
				LPSAFEARRAY parray;
				CAC cac;
				CAUB caub;
				CAI cai;
				CAUI caui;
				CAL cal;
				CAUL caul;
				CAH cah;
				CAUH cauh;
				CAFLT caflt;
				CADBL cadbl;
				CABOOL cabool;
				CASCODE cascode;
				CACY cacy;
				CADATE cadate;
				CAFILETIME cafiletime;
				CACLSID cauuid;
				CACLIPDATA caclipdata;
				CABSTR cabstr;
				CABSTRBLOB cabstrblob;
				CALPSTR calpstr;
				CALPWSTR calpwstr;
				CAPROPVARIANT capropvar;
				CHAR* pcVal;
				UCHAR* pbVal;
				SHORT* piVal;
				USHORT* puiVal;
				LONG* plVal;
				ULONG* pulVal;
				INT* pintVal;
				UINT* puintVal;
				FLOAT* pfltVal;
				DOUBLE* pdblVal;
				VARIANT_BOOL* pboolVal;
				DECIMAL* pdecVal;
				SCODE* pscode;
				CY* pcyVal;
				DATE* pdate;
				BSTR* pbstrVal;
				IUnknown** ppunkVal;
				IDispatch** ppdispVal;
				LPSAFEARRAY* pparray;
				PROPVARIANT* pvarVal;
			}
		}
		DECIMAL decVal;
	}
}
alias LPPROPVARIANT = PROPVARIANT*;


interface IPropertyStore : IUnknown
{
extern (Windows):
	HRESULT GetCount(DWORD* cProps);
	HRESULT GetAt(DWORD iProp, PROPERTYKEY* pkey);
	HRESULT GetValue(PROPERTYKEY* key, PROPVARIANT* pv);
	HRESULT SetValue(const(PROPERTYKEY*) key, PROPVARIANT* propvar);
	HRESULT Commit();
}


interface IPersistFile : IPersist
{
extern (Windows):
	HRESULT IsDirty();
	HRESULT Load(LPCOLESTR pszFileName, DWORD dwMode);
	HRESULT Save(LPCOLESTR pszFileName, BOOL fRemember);
	HRESULT SaveCompleted(LPCOLESTR pszFileName);
	HRESULT GetCurFile(out LPOLESTR* ppszFileName);
}


extern (Windows)
{
	HRESULT PropVariantClear(PROPVARIANT* pvar);
}


void PropVariantInit(PROPVARIANT* pvar)
{
	import core.stdc.string : memset;
	memset(pvar, 0, PROPVARIANT.sizeof);
}


HRESULT InitPropVariantFromString(PCWSTR psz, PROPVARIANT* ppropvar)
{
	HRESULT hr = SHStrDupW(psz, &ppropvar.pwszVal);
	if (hr == S_OK)
		ppropvar.vt = VARENUM.VT_LPWSTR;
	else
		PropVariantInit(ppropvar);
	return hr;
}


class ShellLinkWithAppId
{
	///
	this(in Dwstring exePath, in Dwstring shortcutPath, in Dwstring appId)
	{
		_exePath = exePath;
		_shortcutPath = shortcutPath;
		_appId = appId;
	}


	///
	void install()
	in
	{
		assert(_exePath.length > 0);
		assert(_shortcutPath.length > 0);
		assert(_appId.length > 0);
	}
	do
	{
		HRESULT hr;

		IShellLinkW shellLink;
		hr = CoCreateInstance(&CLSID_ShellLink, null, CLSCTX_INPROC_SERVER, &IID_IShellLinkW, cast(LPVOID*)&shellLink);
		assert(shellLink);
		assert(hr == S_OK, "CoCreateInstance(CLSID_ShellLink) failed");
		scope (exit)
			shellLink.Release();
		hr = shellLink.SetPath(_exePath.ptr);
		assert(hr == S_OK, "IShellLinkW.SetPath() failed");

		IPropertyStore propertyStore;
		hr = shellLink.QueryInterface(&IID_IPropertyStore, cast(LPVOID*)&propertyStore);
		assert(propertyStore);
		assert(hr == S_OK, "IPropertyStore.QueryInterface(IID_IPropertyStore) failed");
		scope (exit)
			propertyStore.Release();
		PROPVARIANT pv;
		hr = InitPropVariantFromString(_appId.ptr, &pv);
		assert(hr == S_OK, "InitPropVariantFromString() failed");
		hr = propertyStore.SetValue(&PKEY_AppUserModel_ID, &pv);
		assert(hr == S_OK, "IPropertyStore.SetValue() failed");
		hr = propertyStore.Commit();
		assert(hr == S_OK, "IPropertyStore.Commit() failed");
		hr = PropVariantClear(&pv);
		assert(hr == S_OK, "PropVariantClear() failed");

		IPersistFile persistFile;
		hr = shellLink.QueryInterface(&IID_IPersistFile, cast(LPVOID*)&persistFile);
		assert(persistFile);
		assert(hr == S_OK, "QueryInterface(IID_IPersistFile) failed");
		scope (exit)
			persistFile.Release();
		hr = persistFile.Save(_shortcutPath.ptr, TRUE);
		assert(hr == S_OK, "IPersistFile.Save() failed");

		isInstalled = true;
	}


	///
	void uninstall()
	in
	{
		assert(_shortcutPath.length > 0);
	}
	do
	{
		if (isInstalled)
		{
			DeleteFile(_shortcutPath.ptr);
			isInstalled = false;
		}
	}

private:

	static bool isInstalled; ///
	Dwstring _exePath; ///
	Dwstring _shortcutPath; ///
	Dwstring _appId; ///
}
