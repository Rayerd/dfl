module dfl.internal.winrt;

import dfl.base;

import core.sys.windows.windows;
import core.sys.windows.com;


pragma(lib, "windowsapp");


extern(Windows) nothrow @nogc
{
	// uuid("af86e2e0-b12d-4c6a-9c5a-d7aa65101e90")
	interface IInspectable : IUnknown
	{
		HRESULT GetIids(uint* iidCount, GUID** iids);
		HRESULT GetRuntimeClassName(HSTRING* className);
		HRESULT GetTrustLevel(int* trustLevel);
	}

	HRESULT RoInitialize(RO_INIT_TYPE type);
	void RoUninitialize();
	HRESULT RoActivateInstance(HSTRING activatableClassId, IInspectable* thisInstance);
	HRESULT RoGetActivationFactory(HSTRING activatableClassId, REFIID iid, void** factory);
	HRESULT SetCurrentProcessExplicitAppUserModelID(PCWSTR aumid);
	HRESULT GetCurrentProcessExplicitAppUserModelID(PWSTR* aumid);


	///
	enum RO_INIT_TYPE : int
	{
		RO_INIT_SINGLETHREADED = 0,
		RO_INIT_MULTITHREADED = 1
	}


	alias HSTRING = HANDLE; ///
	alias HSTRING_BUFFER = HANDLE; ///


	///
	struct HSTRING_HEADER
	{
		PVOID Reserved1;
		union ReservedType
		{
			version(Win64)
				char[24] Reserved2;
			else
				char[20] Reserved2;
		}
		ReservedType Reserved2;
	}

	HRESULT WindowsCompareStringOrdinal(HSTRING str1, HSTRING str2, INT32* order);
	HRESULT WindowsConcatString(HSTRING str1, HSTRING str2, HSTRING* out_);
	HRESULT WindowsCreateString(LPCWSTR ptr, UINT32 len, HSTRING* out_);
	HRESULT WindowsCreateStringReference(LPCWSTR ptr, UINT32 len, HSTRING_HEADER* header, HSTRING* out_);
	HRESULT WindowsDeleteString(HSTRING str);
	HRESULT WindowsDeleteStringBuffer(HSTRING_BUFFER buf);
	HRESULT WindowsDuplicateString(HSTRING str, HSTRING* out_);
	UINT32 WindowsGetStringLen(HSTRING str);
	LPCWSTR WindowsGetStringRawBuffer(HSTRING str, UINT32* len);
	BOOL WindowsIsStringEmpty(HSTRING str);
	HRESULT WindowsPreallocateStringBuffer(UINT32 len, WCHAR** outptr, HSTRING_BUFFER* out_);
	HRESULT WindowsPromoteStringBuffer(HSTRING_BUFFER buf, HSTRING* out_);
	HRESULT WindowsReplaceString(HSTRING haystack, HSTRING needle, HSTRING replacement, HSTRING* out_);
	HRESULT WindowsStringHasEmbeddedNull(HSTRING str, BOOL* out_);
	HRESULT WindowsSubstring(HSTRING str, UINT32 pos, HSTRING* out_);
	HRESULT WindowsSubstringWithSpecifiedLength(HSTRING str, UINT32 pos, UINT32 len, HSTRING* out_);
	HRESULT WindowsTrimStringEnd(HSTRING str, HSTRING charstr, HSTRING* out_);
	HRESULT WindowsTrimStringStart(HSTRING str, HSTRING charstr, HSTRING* out_);
}


///
HSTRING toHSTRING(wstring text)
{
	HSTRING h;
	WindowsCreateString(text.ptr, cast(uint)text.length, &h);
	return h;
}


///
void freeHSTRING(HSTRING h)
{
	if (h !is null)
		WindowsDeleteString(h);
}


extern(Windows) nothrow @nogc
{
	struct EventRegistrationToken
	{
		long value;
	}


	///
	interface IXmlDocumentIO : IInspectable
	{
		HRESULT LoadXml(HSTRING xml);
	}


	///
	interface IXmlDocument : IInspectable {}


	///
	interface XmlDocument : IXmlDocument, IXmlDocumentIO {}


	///
	interface IToastNotification : IInspectable
	{
		HRESULT Content(XmlDocument return_value);//HRESULT get_Content(Windows.Data.Xml.Dom.XmlDocument* return_value);
		HRESULT _Dummy1();//HRESULT Expset_ExpirationTimeirationTime(Windows.Foundation.IReference!(Windows.Foundation.DateTime) value);
		HRESULT _Dummy2();//HRESULT get_ExpirationTime(Windows.Foundation.IReference!(Windows.Foundation.DateTime)* return_value);
		HRESULT _Dummy3();//HRESULT add_Dismissed(Windows.Foundation.TypedEventHandler!(Windows.UI.Notifications.ToastNotification, Windows.UI.Notifications.ToastDismissedEventArgs) handler, EventRegistrationToken* return_cookie);
		HRESULT _Dummy4();//HRESULT remove_Dismissed(EventRegistrationToken cookie);
		HRESULT _Dummy5();//HRESULT Activated(ITypedEventHandler!(IToastNotification, IInspectable) handler, EventRegistrationToken* return_cookie);//HRESULT add_Activated(Windows.Foundation.TypedEventHandler!(Windows.UI.Notifications.ToastNotification, IInspectable) handler, EventRegistrationToken* return_cookie);
		HRESULT _Dummy6();//HRESULT RemoveActivated(EventRegistrationToken cookie);//HRESULT remove_Activated(EventRegistrationToken cookie);
		HRESULT _Dummy7();//HRESULT add_Failed(Windows.Foundation.TypedEventHandler!(Windows.UI.Notifications.ToastNotification, Windows.UI.Notifications.ToastFailedEventArgs) handler, EventRegistrationToken* return_token);
		HRESULT _Dummy8();//HRESULT remove_Failed(EventRegistrationToken token);
	}


	///
	interface IToastNotificationFactory : IInspectable
	{
		HRESULT CreateToastNotification(XmlDocument doc, IToastNotification* return_toast);
	}


	///
	enum NotificationSetting
	{
		Enabled = 0, ///
		DisabledForApplication = 1, ///
		DisabledForUser = 2, ///
		DisabledByGroupPolicy = 3, ///
		DisabledByManifest = 4, ///
	}


	///
	interface IToastNotifier : IInspectable
	{
		HRESULT Show(IToastNotification toast);
		HRESULT Hide(IToastNotification toast);
		HRESULT Setting(NotificationSetting* return_setting);
	}

	///
	interface IToastNotificationManagerStatics : IInspectable
	{
		HRESULT CreateToastNotifier(IToastNotifier* return_notifier);
		HRESULT CreateToastNotifierWithId(HSTRING applicationId, IToastNotifier* return_notifier);
	}
}


__gshared
{
	GUID IID_IToastNotification = guidFromUUID("997e2675-059e-4e60-8b06-1760917c8b80");
	GUID IID_IToastNotificationManagerStatics = guidFromUUID("50ac103f-d235-4598-bbef-98fe4d1a3ad4");
	GUID IID_IToastNotificationFactory = guidFromUUID("04124b20-82c6-4229-b109-fd9ed4662b53");
	GUID IID_IXmlDocumentIO = guidFromUUID("6cd0e74e-ee65-4489-9ebf-ca43e87ba637");
}


///
GUID guidFromUUID(string uuidString)
{
	static import std.uuid;
	std.uuid.UUID uuid = std.uuid.UUID(uuidString);
	ubyte[8] data = uuid.data[8 .. $];
	return GUID(uuid.data[0] << 24 | uuid.data[1] << 16 | uuid.data[2] << 8 | uuid.data[3], uuid.data[4] << 8 | uuid.data[5], uuid.data[6] << 8 | uuid.data[7], data);
}


///
final class WinRuntime
{
	///
	static void initApartment(RO_INIT_TYPE type)
	{
		if (_isInitialized)
			return;
		HRESULT hr = RoInitialize(type);
		if (hr < 0)
			throw new DflException("initApartment failure");
		_isInitialized = true;
	}

	///
	static void uninitApartment()
	{
		if (_isInitialized)
		{
			RoUninitialize();
			_isInitialized = false;
		}
	}

private:
	static bool _isInitialized; ///
}
