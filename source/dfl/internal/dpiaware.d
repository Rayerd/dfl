module dfl.internal.dpiaware;


import core.sys.windows.windef;


pragma(lib, "Shcore");


///
enum USER_DEFAULT_SCREEN_DPI = 96;


///
enum DEVICE_SCALE_FACTOR
{
	DEVICE_SCALE_FACTOR_INVALID = 0,
	SCALE_100_PERCENT = 100,
	SCALE_120_PERCENT = 120,
	SCALE_125_PERCENT = 125,
	SCALE_140_PERCENT = 140,
	SCALE_150_PERCENT = 150,
	SCALE_160_PERCENT = 160,
	SCALE_175_PERCENT = 175,
	SCALE_180_PERCENT = 180,
	SCALE_200_PERCENT = 200,
	SCALE_225_PERCENT = 225,
	SCALE_250_PERCENT = 250,
	SCALE_300_PERCENT = 300,
	SCALE_350_PERCENT = 350,
	SCALE_400_PERCENT = 400,
	SCALE_450_PERCENT = 450,
	SCALE_500_PERCENT = 500,
}


///
enum MONITOR_DPI_TYPE
{
	MDT_EFFECTIVE_DPI = 0,
	MDT_ANGULAR_DPI = 1,
	MDT_RAW_DPI = 2,
	MDT_DEFAULT
}


///
enum DPI_AWARENESS
{
	DPI_AWARENESS_INVALID = -1,
	DPI_AWARENESS_UNAWARE = 0,
	DPI_AWARENESS_SYSTEM_AWARE = 1,
	DPI_AWARENESS_PER_MONITOR_AWARE = 2
}


///
enum DIALOG_CONTROL_DPI_CHANGE_BEHAVIORS
{
	DCDC_DEFAULT = 0x0000,
	DCDC_DISABLE_FONT_UPDATE = 0x0001,
	DCDC_DISABLE_RELAYOUT = 0x0002
}


///
enum DIALOG_DPI_CHANGE_BEHAVIORS
{
	DDC_DEFAULT = 0x0000,
	DDC_DISABLE_ALL = 0x0001,
	DDC_DISABLE_RESIZE = 0x0002,
	DDC_DISABLE_CONTROL_RELAYOUT = 0x0004
}


///
enum DPI_HOSTING_BEHAVIOR
{
	DPI_HOSTING_BEHAVIOR_INVALID = -1,
	DPI_HOSTING_BEHAVIOR_DEFAULT = 0,
	DPI_HOSTING_BEHAVIOR_MIXED = 1
}


///
enum PROCESS_DPI_AWARENESS
{
	PROCESS_DPI_UNAWARE = 0,
	PROCESS_SYSTEM_DPI_AWARE = 1,
	PROCESS_PER_MONITOR_DPI_AWARE = 2
}


alias DPI_AWARENESS_CONTEXT = HANDLE; ///
enum DPI_AWARENESS_CONTEXT DPI_AWARENESS_CONTEXT_UNAWARE = cast(void*)-1; ///
enum DPI_AWARENESS_CONTEXT DPI_AWARENESS_CONTEXT_SYSTEM_AWARE = cast(void*)-2; ///
enum DPI_AWARENESS_CONTEXT DPI_AWARENESS_CONTEXT_PER_MONITOR_AWARE = cast(void*)-3; ///
enum DPI_AWARENESS_CONTEXT DPI_AWARENESS_CONTEXT_PER_MONITOR_AWARE_V2 = cast(void*)-4; ///
enum DPI_AWARENESS_CONTEXT DPI_AWARENESS_CONTEXT_UNAWARE_GDISCALED = cast(void*)-5; ///


enum WM_DPICHANGED = 0x02E0; ///
enum WM_DPICHANGED_BEFOREPARENT = 0x02E2; ///
enum WM_DPICHANGED_AFTERPARENT = 0x02E3; ///
enum WM_GETDPISCALEDSIZE = 0x02E4; /// 


alias HTHEME = HANDLE; ///


///
// Refference: https://learn.microsoft.com/en-us/windows/win32/api/_hidpi/
extern(Windows) nothrow @nogc
{
	BOOL AdjustWindowRectExForDpi(LPRECT lpRect, DWORD dwStyle, BOOL bMenu, DWORD dwExStyle, UINT dpi);
	BOOL AreDpiAwarenessContextsEqual(DPI_AWARENESS_CONTEXT dpiContextA, DPI_AWARENESS_CONTEXT dpiContextB);
	BOOL EnableNonClientDpiScaling(HWND hwnd);
	DPI_AWARENESS GetAwarenessFromDpiAwarenessContext(DPI_AWARENESS_CONTEXT value);
	DPI_AWARENESS_CONTEXT GetDpiAwarenessContextForProcess(HANDLE hProcess);
	UINT GetDpiForSystem(); 
	UINT GetDpiForWindow(HWND);
	int GetSystemMetricsForDpi(int nIndex, UINT dpi);
	DPI_AWARENESS_CONTEXT GetThreadDpiAwarenessContext();
	DPI_AWARENESS_CONTEXT GetWindowDpiAwarenessContext(HWND hwnd);
	BOOL IsValidDpiAwarenessContext(DPI_AWARENESS_CONTEXT value);
	BOOL LogicalToPhysicalPointForPerMonitorDPI(HWND hWnd, LPPOINT lpPoint);
	BOOL PhysicalToLogicalPointForPerMonitorDPI(HWND hWnd, const POINT* lpPoint);
	DPI_AWARENESS_CONTEXT SetThreadDpiAwarenessContext(DPI_AWARENESS_CONTEXT dpiContext);
	BOOL SystemParametersInfoForDpi(UINT  uiAction, UINT  uiParam, PVOID pvParam, UINT  fWinIni, UINT  dpi);
	BOOL SetProcessDpiAwarenessContext(DPI_AWARENESS_CONTEXT);
	BOOL SetDialogDpiChangeBehavior(HWND hDlg, DIALOG_DPI_CHANGE_BEHAVIORS mask, DIALOG_DPI_CHANGE_BEHAVIORS values);
	DIALOG_DPI_CHANGE_BEHAVIORS GetDialogDpiChangeBehavior(HWND hDlg);
	BOOL SetDialogControlDpiChangeBehavior(HWND hWnd, DIALOG_CONTROL_DPI_CHANGE_BEHAVIORS mask, DIALOG_CONTROL_DPI_CHANGE_BEHAVIORS values);
	DIALOG_CONTROL_DPI_CHANGE_BEHAVIORS GetDialogControlDpiChangeBehavior(HWND hWnd);
	HTHEME OpenThemeDataForDpi(HWND hwnd, LPCWSTR pszClassList, UINT dpi);
	UINT GetSystemDpiForProcess(HANDLE hProcess);
	UINT GetDpiFromDpiAwarenessContext(DPI_AWARENESS_CONTEXT value);
	DPI_HOSTING_BEHAVIOR SetThreadDpiHostingBehavior(DPI_HOSTING_BEHAVIOR value);
	DPI_HOSTING_BEHAVIOR GetThreadDpiHostingBehavior();
	DPI_HOSTING_BEHAVIOR GetWindowDpiHostingBehavior(HWND hwnd);
	BOOL InheritWindowMonitor(HWND hwnd, HWND hwndInherit);
	UINT SetThreadCursorCreationScaling(UINT cursorDpi);
}


///
deprecated enum DISPLAY_DEVICE_TYPE
{
	DEVICE_PRIMARY = 0,
	DEVICE_IMMERSIVE = 1
}


///
enum SCALE_CHANGE_FLAGS
{
	SCF_VALUE_NONE = 0x00,
	SCF_SCALE = 0x01,
	SCF_PHYSICAL = 0x02
}


///
enum SHELL_UI_COMPONENT
{
	SHELL_UI_COMPONENT_TASKBARS = 0,
	SHELL_UI_COMPONENT_NOTIFICATIONAREA = 1,
	SHELL_UI_COMPONENT_DESKBAND = 2
}


///
// Refference: https://learn.microsoft.com/en-us/windows/win32/api/shellscalingapi/
extern(Windows) nothrow @nogc
{
	HRESULT GetDpiForMonitor(HMONITOR hmonitor, MONITOR_DPI_TYPE dpiType, UINT *dpiX, UINT *dpiY);
	UINT GetDpiForShellUIComponent(SHELL_UI_COMPONENT unnamedParam1);
	HRESULT GetProcessDpiAwareness(HANDLE hprocess, PROCESS_DPI_AWARENESS *value);
	deprecated DEVICE_SCALE_FACTOR GetScaleFactorForDevice(DISPLAY_DEVICE_TYPE deviceType);
	HRESULT GetScaleFactorForMonitor(HMONITOR hMon, DEVICE_SCALE_FACTOR *pScale);
	deprecated HRESULT RegisterScaleChangeNotifications(DISPLAY_DEVICE_TYPE displayDevice, HWND hwndNotify, UINT uMsgNotify, DWORD *pdwCookie);
	deprecated HRESULT RevokeScaleChangeNotifications(DISPLAY_DEVICE_TYPE displayDevice, DWORD dwCookie);
	HRESULT SetProcessDpiAwareness(PROCESS_DPI_AWARENESS value);
	HRESULT UnregisterScaleChangeEvent(DWORD_PTR dwCookie);
}


///
double getScaleFactorPerDefaultScreenDpi(HMONITOR hMon)
{
	DEVICE_SCALE_FACTOR bufScale;
	GetScaleFactorForMonitor(hMon, &bufScale);
	if (bufScale != DEVICE_SCALE_FACTOR.DEVICE_SCALE_FACTOR_INVALID)
		return cast(double)bufScale / USER_DEFAULT_SCREEN_DPI;
	else
		return 1.0;
}


///
class DpiConverter
{
	import dfl.drawing;
	import std.math.rounding : ceil;

	///
	this(Screen screen)
	{
		_screen = screen;
		_displayScale = getScaleFactorPerDefaultScreenDpi(_screen.handle);
	}


	///
	Point point(in Point p) const
	{
		return Point(
			ceil(cast(double)p.x * _displayScale),
			ceil(cast(double)p.y * _displayScale));
	}

	/// ditto
	Size size(in Size s) const
	{
		return Size(
			ceil(cast(double)s.width * _displayScale),
			ceil(cast(double)s.height * _displayScale));
	}

	/// ditto
	Rect rect(in Rect r) const
	{
		return Rect(
			ceil(cast(double)r.x * _displayScale),
			ceil(cast(double)r.y * _displayScale),
			ceil(cast(double)r.width * _displayScale),
			ceil(cast(double)r.height * _displayScale));
	}


	///
	void displayScale(double scale) @property // setter
	{
		_displayScale = scale;
	}

	/// ditto
	double displayScale() const @property // getter
	{
		return _displayScale;
	}

private:
	Screen _screen;
	double _displayScale;
}