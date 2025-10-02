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


///
wstring fromHSTRING(HSTRING text)
{
	if (text is null)
		return ""w;
	UINT32 len = 0;
	auto ptr = WindowsGetStringRawBuffer(text, &len);
	return ptr[0 .. len].idup;
}


/// Simple HSTRING wrapper
struct hstring
{
	@disable this();

	/// Constructor
	this(hstring str)
	{
		WindowsDuplicateString(str._str, &_str);
	}

	/// ditto
	this(ref hstring str)
	{
		WindowsDuplicateString(str._str, &_str);
	}

	/// ditto
	this(wstring str)
	{
		_str = toHSTRING(str);
	}

	/// ditto
	this(this)
	{
		WindowsDuplicateString(this._str, &_str);
	}

	/// ditto
	this(HSTRING str)
	{
		WindowsDuplicateString(str, &_str);
	}

	/// ditto
	ref hstring opAssign(ref hstring str)
	{
		freeHSTRING(_str);
		WindowsDuplicateString(str._str, &_str);
		return this;
	}


	/// Destructor
	~this()
	{
		freeHSTRING(_str);
		_str = null;
	}


	/// Raw HSTRING
	HSTRING handle()
	{
		return _str;
	}


	/// Pointer to raw HSTRING
	HSTRING* ptr()
	{
		return &_str;
	}


private:
	HSTRING _str;
}


extern(Windows) nothrow @nogc
{
	///
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
		HRESULT get_Content(XmlDocument return_value);
		HRESULT _Dummy1();//HRESULT set_ExpirationTimeirationTime(Windows.Foundation.IReference!(Windows.Foundation.DateTime) value);
		HRESULT _Dummy2();//HRESULT get_ExpirationTime(Windows.Foundation.IReference!(Windows.Foundation.DateTime)* return_value);
		HRESULT _Dummy3();//HRESULT add_Dismissed(Windows.Foundation.TypedEventHandler!(Windows.UI.Notifications.ToastNotification, Windows.UI.Notifications.ToastDismissedEventArgs) handler, EventRegistrationToken* return_cookie);
		HRESULT _Dummy4();//HRESULT remove_Dismissed(EventRegistrationToken cookie);
		HRESULT _Dummy5();//HRESULT add_Activated(Windows.Foundation.TypedEventHandler!(Windows.UI.Notifications.ToastNotification, IInspectable) handler, EventRegistrationToken* return_cookie);
		HRESULT _Dummy6();//HRESULT RemoveActivated(EventRegistrationToken cookie);//HRESULT remove_Activated(EventRegistrationToken cookie);
		HRESULT _Dummy7();//HRESULT add_Failed(Windows.Foundation.TypedEventHandler!(Windows.UI.Notifications.ToastNotification, Windows.UI.Notifications.ToastFailedEventArgs) handler, EventRegistrationToken* return_token);
		HRESULT _Dummy8();//HRESULT remove_Failed(EventRegistrationToken token);
	}


	///
	interface IToastNotification2 : IInspectable
	{
	extern(Windows):
		HRESULT set_Tag(HSTRING value);
		HRESULT get_Tag(HSTRING* return_value);
		HRESULT set_Group(HSTRING value);
		HRESULT get_Group(HSTRING* return_value);
		HRESULT _Dummy5();// HRESULT set_SuppressPopup(bool value);
		HRESULT _Dummy6();// HRESULT get_SuppressPopup(bool* return_value);
	}


	///
	interface IToastNotification3 : IInspectable
	{
	extern(Windows):
		HRESULT _Dummy1();// HRESULT get_NotificationMirroring(Windows.UI.Notifications.NotificationMirroring* return_value);
		HRESULT _Dummy2();// HRESULT set_NotificationMirroring(Windows.UI.Notifications.NotificationMirroring value);
		HRESULT _Dummy3();// HRESULT get_RemoteId(HSTRING* return_value);
		HRESULT _Dummy4();// HRESULT set_RemoteId(HSTRING value);
	}


	///
	interface IToastNotification4 : IInspectable
	{
	extern(Windows):
		HRESULT get_Data(INotificationData* return_value);
		HRESULT set_Data(INotificationData value);
		HRESULT _Dummy3();// HRESULT get_Priority(Windows.UI.Notifications.ToastNotificationPriority* return_value);
		HRESULT _Dummy4();// HRESULT set_Priority(Windows.UI.Notifications.ToastNotificationPriority value);
	}


	///
	interface IToastNotificationFactory : IInspectable
	{
		HRESULT abi_CreateToastNotification(XmlDocument doc, IToastNotification* return_toast);
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
	enum NotificationUpdateResult
	{
		Succeeded = 0,
		Failed = 1,
		NotificationNotFound = 2
	}


	///
	interface IToastNotifier : IInspectable
	{
		HRESULT abi_Show(IToastNotification toast);
		HRESULT abi_Hide(IToastNotification toast);
		HRESULT get_Setting(NotificationSetting* return_setting);
		HRESULT _Dummy4();//HRESULT abi_AddToSchedule(Windows.UI.Notifications.ScheduledToastNotification scheduledToast);
		HRESULT _Dummy5();//HRESULT abi_RemoveFromSchedule(Windows.UI.Notifications.ScheduledToastNotification scheduledToast);
		HRESULT _Dummy6();//HRESULT abi_GetScheduledToastNotifications(Windows.Foundation.Collections.IVectorView!(Windows.UI.Notifications.ScheduledToastNotification)* return_scheduledToasts);
	}


	///
	interface IToastNotifier2 : IInspectable
	{
	extern(Windows):
		HRESULT abi_UpdateWithTagAndGroup(INotificationData data, HSTRING tag, HSTRING group, NotificationUpdateResult* return_result);
		HRESULT abi_UpdateWithTag(INotificationData data, HSTRING tag, NotificationUpdateResult* return_result);
	}


	///
	interface INotificationData : IInspectable
	{
	extern(Windows):
		HRESULT get_Values(IMap!(HSTRING, HSTRING)* return_value);
		HRESULT get_SequenceNumber(UINT32* return_value);
		HRESULT set_SequenceNumber(UINT32 value);
	}


	///
	interface INotificationDataFactory : IInspectable
	{
	extern(Windows):
		HRESULT abi_CreateNotificationDataWithValuesAndSequenceNumber(IIterable!(IKeyValuePair!(HSTRING, HSTRING)) initialValues, UINT32 sequenceNumber, INotificationData* return_result);
		HRESULT abi_CreateNotificationDataWithValues(IIterable!(IKeyValuePair!(HSTRING, HSTRING)) initialValues, INotificationData* return_result);
	}


	///
	interface IToastNotificationManagerStatics : IInspectable
	{
		HRESULT abi_CreateToastNotifier(IToastNotifier* return_notifier);
		HRESULT abi_CreateToastNotifierWithId(HSTRING applicationId, IToastNotifier* return_notifier);
		HRESULT abi_GetTemplateContent(ToastTemplateType type, XmlDocument* return_content);
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
		ToastText04 = 7
	}	


	///
	interface IIterator(Type) : IInspectable
	{
	extern(Windows):
		HRESULT abi_Current(Type* return_current);
		HRESULT abi_HasCurrent(bool* return_hasCurrent);
		HRESULT abi_MoveNext(bool* out_hasCurrent);
		HRESULT abi_GetMany(uint capacity, Type* value, uint* actual);
	}
	
	
	///
	interface IIterable(Type) : IInspectable
	{
	extern(Windows):
		HRESULT abi_First(IIterator!(Type)* out_first);
	}


	///
	interface IKeyValuePair(TKey, TValue) : IInspectable
	{
	extern(Windows):
		HRESULT get_Key(TKey* return_key);
		HRESULT get_Value(TValue* return_value);
	}


	///
	interface IMapView(TKey, TValue) : IInspectable
	{
	extern(Windows):
		HRESULT abi_Lookup(TKey key, TValue* return_value);
		HRESULT get_Size(uint* return_size);
		HRESULT abi_HasKey(TKey key, bool* return_found);
		HRESULT abi_Split(IMapView!(TKey, TValue) out_firstPartition, IMapView!(TKey, TValue) out_secondPartition);
	}


	///
	interface IMap(TKey, TValue) : IInspectable
	{
	extern(Windows):
		HRESULT abi_Lookup(TKey key, TValue* return_value);
		HRESULT get_Size(uint* return_size);
		HRESULT abi_HasKey(TKey key, bool* return_found);
		HRESULT abi_GetView(IMapView!(TKey, TValue)* return_view);
		HRESULT abi_Insert(TKey key, TValue value, bool* return_replaced);
		HRESULT abi_Remove(TKey key);
		HRESULT abi_Clear();
	}


	///
	interface IObservableMap(TKey, TValue) : IInspectable
	{
	extern(Windows):
		HRESULT _Dummy1();// HRESULT add_MapChanged(MapChangedEventHandler!(TKey, TValue) handler, EventRegistrationToken* return_token);
		HRESULT _Dummy2();// HRESULT remove_MapChanged(EventRegistrationToken token);
	}
	

	///
	interface IStringMap : IMap!(HSTRING, HSTRING), IIterable!(IKeyValuePair!(HSTRING, HSTRING)), IObservableMap!(HSTRING, HSTRING) {}
}


extern(Windows) __gshared
{
	IID IID_IToastNotifier2 = guidFromUUID("354389c6-7c01-4bd5-9c20-604340cd2b74");
	IID IID_IToastNotification = guidFromUUID("997e2675-059e-4e60-8b06-1760917c8b80");
	IID IID_IToastNotification2 = guidFromUUID("9dfb9fd1-143a-490e-90bf-b9fba7132de7");
	IID IID_IToastNotification4 = guidFromUUID("15154935-28ea-4727-88e9-c58680e2d118");
	IID IID_IToastNotificationManagerStatics = guidFromUUID("50ac103f-d235-4598-bbef-98fe4d1a3ad4");
	IID IID_IToastNotificationFactory = guidFromUUID("04124b20-82c6-4229-b109-fd9ed4662b53");
	IID IID_INotificationDataFactory = guidFromUUID("23c1e33a-1c10-46fb-8040-dec384621cf8");
	IID IID_IXmlDocumentIO = guidFromUUID("6cd0e74e-ee65-4489-9ebf-ca43e87ba637");
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
string uuidFromGUID(in GUID* guid)
{
	import std.format : format;
	import std.array : array;
	ubyte[16] data;
	data[0] = cast(ubyte)((guid.Data1 >> 24) & 0xFF);
	data[1] = cast(ubyte)((guid.Data1 >> 16) & 0xFF);
	data[2] = cast(ubyte)((guid.Data1 >> 8) & 0xFF);
	data[3] = cast(ubyte)(guid.Data1 & 0xFF);
	data[4] = cast(ubyte)((guid.Data2 >> 8) & 0xFF);
	data[5] = cast(ubyte)(guid.Data2 & 0xFF);
	data[6] = cast(ubyte)((guid.Data3 >> 8) & 0xFF);
	data[7] = cast(ubyte)(guid.Data3 & 0xFF);
	foreach (i; 0 .. 8)
		data[8 + i] = guid.Data4[i];
	return format(
		"{%02X%02X%02X%02X-%02X%02X-%02X%02X-%02X%02X-%02X%02X%02X%02X%02X%02X}",
		data[0], data[1], data[2], data[3],
		data[4], data[5],
		data[6], data[7],
		data[8], data[9],
		data[10], data[11], data[12], data[13], data[14], data[15]);
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
