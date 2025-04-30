module dfl.internal.dpiaware;


import core.sys.windows.basetyps : GUID;
import core.sys.windows.shellapi;
import core.sys.windows.winbase;
import core.sys.windows.windef;
import core.sys.windows.winuser;


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


enum ulong DPI_AWARENESS_CONTEXT_UNAWARE              =  -1; /// 
enum ulong DPI_AWARENESS_CONTEXT_SYSTEM_AWARE         =  -2; /// 
enum ulong DPI_AWARENESS_CONTEXT_PER_MONITOR_AWARE    =  -3; /// 
enum ulong DPI_AWARENESS_CONTEXT_PER_MONITOR_AWARE_V2 =  -4; /// 
enum ulong DPI_AWARENESS_CONTEXT_UNAWARE_GDISCALED    =  -5; /// 


extern(Windows) nothrow @nogc
{
	///
	BOOL SetProcessDpiAwarenessContext(ulong);
	///
	UINT GetDpiForWindow(HWND);
	///
	HRESULT GetScaleFactorForMonitor(HMONITOR hMon, DEVICE_SCALE_FACTOR *pScale);
	///
	HRESULT GetDpiForMonitor(HMONITOR hmonitor, MONITOR_DPI_TYPE dpiType, UINT *dpiX, UINT *dpiY);
	///
	BOOL PhysicalToLogicalPointForPerMonitorDPI(HWND hWnd, const POINT* lpPoint);
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
