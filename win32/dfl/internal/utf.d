/*
	Copyright (C) 2004-2007 Christopher E. Miller
	
	This software is provided 'as-is', without any express or implied
	warranty.  In no event will the authors be held liable for any damages
	arising from the use of this software.
	
	Permission is granted to anyone to use this software for any purpose,
	including commercial applications, and to alter it and redistribute it
	freely, subject to the following restrictions:
	
	1. The origin of this software must not be misrepresented; you must not
	   claim that you wrote the original software. If you use this software
	   in a product, an acknowledgment in the product documentation would be
	   appreciated but is not required.
	2. Altered source versions must be plainly marked as such, and must not be
	   misrepresented as being the original software.
	3. This notice may not be removed or altered from any source distribution.
*/


module dfl.internal.utf;

private import dfl.internal.dlib, dfl.internal.clib;

private import dfl.internal.winapi;


version(Tango)
{
	version(DFL_BOTH_STRINGS)
	{
		pragma(msg, "DFL: warning: this Tango version might not support DFL_BOTH_STRINGS");
	}
	else
	{
		version(Win32SansUnicode)
		{
			version = DFL_ANSI;
		}
		else
		{
			version = DFL_UNICODE;
		}
	}
}
else
{
	private import std.windows.charset;
}


// Determine if using the "W" functions on Windows NT.
version(DFL_UNICODE)
{
	const bool useUnicode = true;
}
else version(DFL_ANSI)
{
	const bool useUnicode = false;
}
else
{
	version = DFL_BOTH_STRINGS;
	
	//bool useUnicode = false;
	alias std.windows.charset.useWfuncs useUnicode;
}

package HMODULE user32, kernel32, _advapi32, gdi32;

package HMODULE advapi32() // getter
{
	if(!_advapi32)
		_advapi32 = LoadLibraryA("advapi32.dll");
	return _advapi32;
}


private:

version(DFL_UNICODE)
	version = STATIC_UNICODE;


public void _utfinit() // package
{
	version(DFL_UNICODE)
	{
	}
	else version(DFL_ANSI)
	{
	}
	else
	{
		/+
		OSVERSIONINFOA osv;
		osv.dwOSVersionInfoSize = OSVERSIONINFOA.sizeof;
		if(GetVersionExA(&osv))
			useUnicode = osv.dwPlatformId == VER_PLATFORM_WIN32_NT;
		+/
		
		user32 = GetModuleHandleA("user32.dll");
		kernel32 = GetModuleHandleA("kernel32.dll");
		_advapi32 = GetModuleHandleA("advapi32.dll"); // Not guaranteed to be loaded.
		gdi32 = GetModuleHandleA("gdi32.dll");
	}
}


template _getlen(T)
{
	size_t _getlen(T* tz)
	in
	{
		assert(tz);
	}
	body
	{
		T* p;
		for(p = tz; *p; p++)
		{
		}
		return p - tz;
	}
}


public:

char* unsafeStringz(char[] s)
{
	if(!s.length)
		return "";
	
	// Check if already null terminated.
	if(!s.ptr[s.length]) // Disables bounds checking.
		return s.ptr;
	
	// Need to duplicate with null terminator.
	char[] result;
	result = new char[s.length + 1];
	result[0 .. s.length] = s;
	result[s.length] = 0;
	return result.ptr;
}


char[] unicodeToAnsi(wchar* unicode, size_t ulen)
{
	if(!ulen)
		return null;
	
	wchar* wsz;
	char[] result;
	int len;
	
	len = WideCharToMultiByte(0, 0, unicode, ulen, null, 0, null, null);
	assert(len > 0);
	
	result = new char[len];
	len = WideCharToMultiByte(0, 0, unicode, ulen, result.ptr, len, null, null);
	assert(len == result.length);
	return result[0 .. len - 1];
}


wchar[] ansiToUnicode(char* ansi, size_t len)
{
	wchar[] ws;
	
	len++;
	ws = new wchar[len];
	
	len = MultiByteToWideChar(0, 0, ansi, len, ws.ptr, len);
	//assert(len == ws.length);
	ws = ws[0 .. len - 1]; // Exclude null char at end.
	
	return ws;
}


char[] fromAnsi(char* ansi, size_t len)
{
	return utf16stringtoUtf8string(ansiToUnicode(ansi, len));
}


char[] fromAnsiz(char* ansiz)
{
	if(!ansiz)
		return null;
	
	return fromAnsi(ansiz, _getlen!(char)(ansiz));
}


private char[] _toAnsiz(char[] utf8, bool safe = true)
{
	foreach(char ch; utf8)
	{
		if(ch >= 0x80)
		{
			wchar* wsz;
			char[] result;
			int len;
			
			wsz = utf8stringToUtf16stringz(utf8);
			len = WideCharToMultiByte(0, 0, wsz, -1, null, 0, null, null);
			assert(len > 0);
			
			result = new char[len];
			len = WideCharToMultiByte(0, 0, wsz, -1, result.ptr, len, null, null);
			assert(len == result.length);
			return result[0 .. len - 1];
		}
	}
	
	// Don't need conversion.
	if(safe)
		return stringToStringz(utf8)[0 .. utf8.length];
	return unsafeStringz(utf8)[0 .. utf8.length];
}


private size_t toAnsiLength(char[] utf8)
{
	foreach(char ch; utf8)
	{
		if(ch >= 0x80)
		{
			wchar* wsz;
			char[] result;
			int len;
			
			wsz = utf8stringToUtf16stringz(utf8);
			len = WideCharToMultiByte(0, 0, wsz, -1, null, 0, null, null);
			assert(len > 0);
			return len - 1; // Minus null.
		}
	}
	return utf8.length; // Just ASCII; same length.
}


private char[] _unsafeAnsiz(char[] utf8)
{
	return _toAnsiz(utf8, false);
}


char* toAnsiz(char[] utf8, bool safe = true)
{
	return _toAnsiz(utf8, safe).ptr;
}


char* unsafeAnsiz(char[] utf8)
{
	return _toAnsiz(utf8, false).ptr;
}


char[] toAnsi(char[] utf8, bool safe = true)
{
	return _toAnsiz(utf8, safe);
}


char[] unsafeAnsi(char[] utf8)
{
	return _toAnsiz(utf8, false);
}


char[] fromUnicode(wchar* unicode, size_t len)
{
	return utf16stringtoUtf8string(unicode[0 .. len]);
}


char[] fromUnicodez(wchar* unicodez)
{
	if(!unicodez)
		return null;
	
	return fromUnicode(unicodez, _getlen!(wchar)(unicodez));
}


wchar* toUnicodez(char[] utf8)
{
	return utf8stringToUtf16stringz(utf8);
}


wchar[] toUnicode(char[] utf8)
{
	return utf8stringtoUtf16string(utf8);
}


size_t toUnicodeLength(char[] utf8)
{
	size_t result = 0;
	foreach(wchar wch; utf8)
	{
		result++;
	}
	return result;
}


private extern(Windows)
{
	alias HWND function(DWORD dwExStyle, LPCWSTR lpClassName, LPCWSTR lpWindowName, DWORD dwStyle,
		int x, int y, int nWidth, int nHeight, HWND hWndParent, HMENU hMenu, HINSTANCE hInstance,
		LPVOID lpParam) CreateWindowExWProc;
	alias int function(HWND hWnd) GetWindowTextLengthWProc;
	alias int function(HWND hWnd, LPCWSTR lpString, int nMaxCount) GetWindowTextWProc;
	alias BOOL function(HWND hWnd, LPCWSTR lpString) SetWindowTextWProc;
	alias LRESULT function(HWND hWnd, UINT Msg, WPARAM wParam, LPARAM lParam) SendMessageWProc;
	alias LRESULT function(WNDPROC lpPrevWndFunc, HWND hWnd, UINT Msg, WPARAM wParam, LPARAM lParam)
		CallWindowProcWProc;
	alias UINT function(LPCWSTR lpszFormat) RegisterClipboardFormatWProc;
	alias int function (UINT format, LPWSTR lpszFormatName, int cchMaxCount)
		GetClipboardFormatNameWProc;
	alias int function(HDC hdc, LPWSTR lpchText, int cchText, LPRECT lprc, UINT dwDTFormat,
		LPDRAWTEXTPARAMS lpDTParams) DrawTextExWProc;
	alias BOOL function(LPCWSTR lpPathName) SetCurrentDirectoryWProc;
	alias DWORD function(DWORD nBufferLength, LPWSTR lpBuffer) GetCurrentDirectoryWProc;
	alias BOOL function(LPWSTR lpBuffer, LPDWORD nSize) GetComputerNameWProc;
	alias UINT function(LPWSTR lpBuffer, UINT uSize) GetSystemDirectoryWProc;
	alias BOOL function(LPWSTR lpBuffer, LPDWORD nSize) GetUserNameWProc;
	alias DWORD function(LPCWSTR lpSrc, LPWSTR lpDst, DWORD nSize) ExpandEnvironmentStringsWProc;
	alias DWORD function(LPCWSTR lpName, LPWSTR lpBuffer, DWORD nSize) GetEnvironmentVariableWProc;
	alias LONG function(HKEY hKey, LPCWSTR lpValueName, DWORD Reserved, DWORD dwType, BYTE* lpData,
		DWORD cbData) RegSetValueExWProc;
	alias LONG function(HKEY hKey, LPCWSTR lpSubKey, DWORD Reserved, LPWSTR lpClass, DWORD dwOptions,
		REGSAM samDesired, LPSECURITY_ATTRIBUTES lpSecurityAttributes, PHKEY phkResult,
		LPDWORD lpdwDisposition) RegCreateKeyExWProc;
	alias LONG function(HKEY hKey, LPCWSTR lpSubKey, DWORD ulOptions, REGSAM samDesired,
		PHKEY phkResult) RegOpenKeyExWProc;
	alias LONG function(HKEY hKey, LPCWSTR lpSubKey) RegDeleteKeyWProc;
	alias LONG function(HKEY hKey, DWORD dwIndex, LPWSTR lpName, LPDWORD lpcbName, LPDWORD lpReserved,
		LPWSTR lpClass, LPDWORD lpcbClass, PFILETIME lpftLastWriteTime) RegEnumKeyExWProc;
	alias LONG function(HKEY hKey, LPWSTR lpValueName, LPDWORD lpReserved, LPDWORD lpType, LPBYTE lpData,
		LPDWORD lpcbData) RegQueryValueExWProc;
	alias LONG function(HKEY hKey, DWORD dwIndex, LPTSTR lpValueName, LPDWORD lpcbValueName,
		LPDWORD lpReserved, LPDWORD lpType, LPBYTE lpData, LPDWORD lpcbData) RegEnumValueWProc;
	alias ATOM function(WNDCLASSW* lpWndClass) RegisterClassWProc;
	alias BOOL function(HDC hdc, LPCWSTR lpString, int cbString, LPSIZE lpSize) GetTextExtentPoint32WProc;
	alias HANDLE function(HINSTANCE hinst, LPCWSTR lpszName, UINT uType, int cxDesired, int cyDesired, UINT fuLoad)
		LoadImageWProc;
	alias UINT function(HDROP hDrop, UINT iFile, LPWSTR lpszFile, UINT cch) DragQueryFileWProc;
	alias DWORD function(HMODULE hModule, LPWSTR lpFilename, DWORD nSize) GetModuleFileNameWProc;
	alias LONG function(MSG* lpmsg) DispatchMessageWProc;
	alias BOOL function(LPMSG lpMsg, HWND hWnd, UINT wMsgFilterMin, UINT wMsgFilterMax, UINT wRemoveMsg)
		PeekMessageWProc;
	alias BOOL function(HWND hDlg, LPMSG lpMsg) IsDialogMessageWProc;
	alias LRESULT function(HWND hWnd, UINT Msg, WPARAM wParam, LPARAM lParam) DefWindowProcWProc;
	alias LRESULT function(HWND hDlg, UINT Msg, WPARAM wParam, LPARAM lParam) DefDlgProcWProc;
	alias LRESULT function(HWND hWnd, HWND hWndMDIClient, UINT uMsg, WPARAM wParam, LPARAM lParam) DefFrameProcWProc;
	alias LRESULT function(HWND hWnd, UINT uMsg, WPARAM wParam, LPARAM lParam) DefMDIChildProcWProc;
	alias BOOL function(HINSTANCE hInstance, LPCWSTR lpClassName, LPWNDCLASSW lpWndClass) GetClassInfoWProc;
	alias HANDLE function(LPCWSTR lpPathName, BOOL bWatchSubtree, DWORD dwNotifyFilter) FindFirstChangeNotificationWProc;
	alias DWORD function(LPCWSTR lpFileName, DWORD nBufferLength, LPWSTR lpBuffer, LPWSTR *lpFilePart) GetFullPathNameWProc;
	alias typeof(&LoadLibraryExW) LoadLibraryExWProc;
	alias typeof(&SetMenuItemInfoW) SetMenuItemInfoWProc;
	alias typeof(&InsertMenuItemW) InsertMenuItemWProc;
}


private void getProcErr(char[] procName)
{
	throw new Exception("Unable to load procedure " ~ procName ~ ".");
}


// If loading from a resource just use LoadImageA().
HANDLE loadImage(HINSTANCE hinst, char[] name, UINT uType, int cxDesired, int cyDesired, UINT fuLoa)
{
	if(useUnicode)
	{
		version(STATIC_UNICODE)
		{
			alias LoadImageW proc;
		}
		else
		{
			const char[] NAME = "LoadImageW";
			static LoadImageWProc proc = null;
			
			if(!proc)
			{
				proc = cast(LoadImageWProc)GetProcAddress(user32, NAME.ptr);
				if(!proc)
					getProcErr(NAME);
			}
		}
		
		return proc(hinst, toUnicodez(name), uType, cxDesired, cyDesired, fuLoa);
	}
	else
	{
		return LoadImageA(hinst, unsafeAnsiz(name), uType, cxDesired, cyDesired, fuLoa);
	}
}


HWND createWindowEx(DWORD dwExStyle, char[] className, char[] windowName, DWORD dwStyle,
	int x, int y, int nWidth, int nHeight, HWND hWndParent, HMENU hMenu, HINSTANCE hInstance,
	LPVOID lpParam)
{
	if(useUnicode)
	{
		version(STATIC_UNICODE)
		{
			alias CreateWindowExW proc;
		}
		else
		{
			const char[] NAME = "CreateWindowExW";
			static CreateWindowExWProc proc = null;
			
			if(!proc)
			{
				proc = cast(CreateWindowExWProc)GetProcAddress(user32, NAME.ptr);
				if(!proc)
					getProcErr(NAME);
			}
		}
		
		//if(windowName.length)
		//	MessageBoxW(null, toUnicodez(windowName), toUnicodez(className ~ " caption"), 0);
		return proc(dwExStyle, toUnicodez(className), toUnicodez(windowName), dwStyle,
			x, y, nWidth, nHeight, hWndParent, hMenu, hInstance, lpParam);
	}
	else
	{
		return CreateWindowExA(dwExStyle, unsafeAnsiz(className), unsafeAnsiz(windowName), dwStyle,
			x, y, nWidth, nHeight, hWndParent, hMenu, hInstance, lpParam);
	}
}


HWND createWindow(char[] className, char[] windowName, DWORD dwStyle, int x, int y,
	int nWidth, int nHeight, HWND hWndParent, HMENU hMenu, HANDLE hInstance, LPVOID lpParam)
{
	return createWindowEx(0, className, windowName, dwStyle, x, y,
		nWidth, nHeight, hWndParent, hMenu, hInstance, lpParam);
}


char[] getWindowText(HWND hwnd)
{
	if(useUnicode)
	{
		version(STATIC_UNICODE)
		{
			alias GetWindowTextW proc;
			alias GetWindowTextLengthW proclen;
		}
		else
		{
			const char[] NAME = "GetWindowTextW";
			static GetWindowTextWProc proc = null;
			
			const char[] NAMELEN = "GetWindowTextLengthW";
			static GetWindowTextLengthWProc proclen = null;
			
			if(!proc)
			{
				proc = cast(GetWindowTextWProc)GetProcAddress(user32, NAME.ptr);
				if(!proc)
					getProcErr(NAME);
				
				//if(!proclen)
				{
					proclen = cast(GetWindowTextLengthWProc)GetProcAddress(user32, NAMELEN.ptr);
					//if(!proclen)
					//	getProcErr(NAMELEN);
				}
			}
		}
		
		wchar* buf;
		size_t len;
		
		len = proclen(hwnd);
		if(!len)
			return null;
		len++;
		buf = (new wchar[len]).ptr;
		
		len = proc(hwnd, buf, len);
		return fromUnicode(buf, len);
	}
	else
	{
		char* buf;
		size_t len;
		
		len = GetWindowTextLengthA(hwnd);
		if(!len)
			return null;
		len++;
		buf = (new char[len]).ptr;
		
		len = GetWindowTextA(hwnd, buf, len);
		return fromAnsi(buf, len);
	}
}


BOOL setWindowText(HWND hwnd, char[] str)
{
	if(useUnicode)
	{
		version(STATIC_UNICODE)
		{
			alias SetWindowTextW proc;
		}
		else
		{
			const char[] NAME = "SetWindowTextW";
			static SetWindowTextWProc proc = null;
			
			if(!proc)
			{
				proc = cast(SetWindowTextWProc)GetProcAddress(user32, NAME.ptr);
				if(!proc)
					getProcErr(NAME);
			}
		}
		
		return proc(hwnd, toUnicodez(str));
	}
	else
	{
		return SetWindowTextA(hwnd, unsafeAnsiz(str));
	}
}


char[] getModuleFileName(HMODULE hmod)
{
	if(useUnicode)
	{
		version(STATIC_UNICODE)
		{
			alias GetModuleFileNameW proc;
		}
		else
		{
			const char[] NAME = "GetModuleFileNameW";
			static GetModuleFileNameWProc proc = null;
			
			if(!proc)
			{
				proc = cast(GetModuleFileNameWProc)GetProcAddress(kernel32, NAME.ptr);
				if(!proc)
					getProcErr(NAME);
			}
		}
		
		wchar[] s;
		DWORD len;
		s = new wchar[MAX_PATH];
		len = proc(hmod, s.ptr, s.length);
		return fromUnicode(s.ptr, len);
	}
	else
	{
		char[] s;
		DWORD len;
		s = new char[MAX_PATH];
		len = GetModuleFileNameA(hmod, s.ptr, s.length);
		return fromAnsi(s.ptr, len);
	}
}


version = STATIC_UNICODE_SEND_MESSAGE;


version(STATIC_UNICODE_SEND_MESSAGE)
{
}
else
{
	version(DFL_UNICODE)
	{
		version = STATIC_UNICODE_SEND_MESSAGE;
	}
	else version(DFL_ANSI)
	{
	}
	else
	{
		private SendMessageWProc _loadSendMessageW()
		{
			const char[] NAME = "SendMessageW";
			static SendMessageWProc proc = null;
			
			if(!proc)
			{
				proc = cast(SendMessageWProc)GetProcAddress(user32, NAME.ptr);
				if(!proc)
					getProcErr(NAME);
			}
			
			return proc;
		}
	}
}


// Sends EM_GETSELTEXT to a rich text box and returns the text.
char[] emGetSelText(HWND hwnd, size_t selTextLength)
{
	if(useUnicode)
	{
		version(STATIC_UNICODE_SEND_MESSAGE)
		{
			alias SendMessageW proc;
		}
		else
		{
			SendMessageWProc proc;
			proc = _loadSendMessageW();
		}
		
		wchar[] buf;
		size_t len;
		buf = new wchar[selTextLength + 1];
		len = proc(hwnd, EM_GETSELTEXT, 0, cast(LPARAM)buf.ptr);
		return fromUnicode(buf.ptr, len);
	}
	else
	{
		char[] buf;
		size_t len;
		buf = new char[selTextLength + 1];
		len = SendMessageA(hwnd, EM_GETSELTEXT, 0, cast(LPARAM)buf.ptr);
		return fromAnsi(buf.ptr, len);
	}
}


// Gets the selected text of an edit box.
// This needs to retrieve the entire text and strip out the extra.
char[] getSelectedText(HWND hwnd)
{
	uint v1, v2;
	uint len;
	
	if(useUnicode)
	{
		version(STATIC_UNICODE_SEND_MESSAGE)
		{
			alias SendMessageW proc;
		}
		else
		{
			SendMessageWProc proc;
			proc = _loadSendMessageW();
		}
		
		proc(hwnd, EM_GETSEL, cast(WPARAM)&v1, cast(LPARAM)&v2);
		if(v1 == v2)
			return null;
		assert(v2 > v1);
		
		len = proc(hwnd, WM_GETTEXTLENGTH, 0, 0);
		if(len)
		{
			len++;
			wchar* buf;
			buf = (new wchar[len]).ptr;
			
			len = proc(hwnd, WM_GETTEXT, len, cast(LPARAM)buf);
			if(len)
			{
				wchar[] s;
				s = buf[v1 .. v2].dup;
				return fromUnicode(s.ptr, s.length);
			}
		}
	}
	else
	{
		SendMessageA(hwnd, EM_GETSEL, cast(WPARAM)&v1, cast(LPARAM)&v2);
		if(v1 == v2)
			return null;
		assert(v2 > v1);
		
		len = SendMessageA(hwnd, WM_GETTEXTLENGTH, 0, 0);
		if(len)
		{
			len++;
			char* buf;
			buf = (new char[len]).ptr;
			
			len = SendMessageA(hwnd, WM_GETTEXT, len, cast(LPARAM)buf);
			if(len)
			{
				char[] s;
				s = buf[v1 .. v2].dup;
				return fromAnsi(s.ptr, s.length);
			}
		}
	}
	
	return null;
}


// Sends EM_SETPASSWORDCHAR to an edit box.
// TODO: check if correct implementation.
void emSetPasswordChar(HWND hwnd, dchar pwc)
{
	if(useUnicode)
	{
		version(STATIC_UNICODE_SEND_MESSAGE)
		{
			alias SendMessageW proc;
		}
		else
		{
			SendMessageWProc proc;
			proc = _loadSendMessageW();
		}
		
		proc(hwnd, EM_SETPASSWORDCHAR, pwc, 0); // ?
	}
	else
	{
		char[] chs;
		char[] ansichs;
		chs = utf32stringtoUtf8string((&pwc)[0 .. 1]);
		ansichs = unsafeAnsi(chs);
		
		if(ansichs)
			SendMessageA(hwnd, EM_SETPASSWORDCHAR, ansichs[0], 0); // ?
	}
}


// Sends EM_GETPASSWORDCHAR to an edit box.
// TODO: check if correct implementation.
dchar emGetPasswordChar(HWND hwnd)
{
	if(useUnicode)
	{
		version(STATIC_UNICODE_SEND_MESSAGE)
		{
			alias SendMessageW proc;
		}
		else
		{
			SendMessageWProc proc;
			proc = _loadSendMessageW();
		}
		
		return cast(dchar)proc(hwnd, EM_GETPASSWORDCHAR, 0, 0); // ?
	}
	else
	{
		char ansich;
		char[] chs;
		dchar[] dchs;
		ansich = cast(char)SendMessageA(hwnd, EM_GETPASSWORDCHAR, 0, 0);
		//chs = fromAnsi((&ansich)[0 .. 1], 1);
		chs = fromAnsi(&ansich, 1);
		dchs = utf8stringtoUtf32string(chs);
		if(dchs.length == 1)
			return dchs[0]; // ?
		return 0;
	}
}


LRESULT sendMessage(HWND hwnd, UINT msg, WPARAM wparam, LPARAM lparam)
{
	if(useUnicode)
	{
		version(STATIC_UNICODE_SEND_MESSAGE)
		{
			alias SendMessageW proc;
		}
		else
		{
			SendMessageWProc proc;
			proc = _loadSendMessageW();
		}
		
		return proc(hwnd, msg, wparam, lparam);
	}
	else
	{
		return SendMessageA(hwnd, msg, wparam, lparam);
	}
}


LRESULT sendMessage(HWND hwnd, UINT msg, WPARAM wparam, char[] lparam, bool safe = true)
{
	if(useUnicode)
	{
		version(STATIC_UNICODE_SEND_MESSAGE)
		{
			alias SendMessageW proc;
		}
		else
		{
			SendMessageWProc proc;
			proc = _loadSendMessageW();
		}
		
		return proc(hwnd, msg, wparam, cast(LPARAM)toUnicodez(lparam));
	}
	else
	{
		return SendMessageA(hwnd, msg, wparam, cast(LPARAM)toAnsiz(lparam, safe)); // Can't assume unsafeAnsiz() is OK here.
	}
}


LRESULT sendMessageUnsafe(HWND hwnd, UINT msg, WPARAM wparam, char[] lparam)
{
	return sendMessage(hwnd, msg, wparam, lparam, false);
}


version = STATIC_UNICODE_CALL_WINDOW_PROC;


LRESULT callWindowProc(WNDPROC lpPrevWndFunc, HWND hwnd, UINT msg, WPARAM wparam, LPARAM lparam)
{
	if(useUnicode)
	{
		version(STATIC_UNICODE_CALL_WINDOW_PROC)
		{
			alias CallWindowProcW proc;
		}
		else
		{
			const char[] NAME = "CallWindowProcW";
			static CallWindowProcWProc proc = null;
			
			if(!proc)
			{
				proc = cast(CallWindowProcWProc)GetProcAddress(user32, NAME.ptr);
				if(!proc)
					getProcErr(NAME);
			}
		}
		
		return proc(lpPrevWndFunc, hwnd, msg, wparam, lparam);
	}
	else
	{
		return CallWindowProcA(lpPrevWndFunc, hwnd, msg, wparam, lparam);
	}
}


UINT registerClipboardFormat(char[] formatName)
{
	if(useUnicode)
	{
		version(STATIC_UNICODE)
		{
			alias RegisterClipboardFormatW proc;
		}
		else
		{
			const char[] NAME = "RegisterClipboardFormatW";
			static RegisterClipboardFormatWProc proc = null;
			
			if(!proc)
			{
				proc = cast(RegisterClipboardFormatWProc)GetProcAddress(user32, NAME.ptr);
				if(!proc)
					getProcErr(NAME);
			}
		}
		
		return proc(toUnicodez(formatName));
	}
	else
	{
		return RegisterClipboardFormatA(unsafeAnsiz(formatName));
	}
}


char[] getClipboardFormatName(UINT format)
{
	if(useUnicode)
	{
		version(STATIC_UNICODE)
		{
			alias GetClipboardFormatNameW proc;
		}
		else
		{
			const char[] NAME = "GetClipboardFormatNameW";
			static GetClipboardFormatNameWProc proc = null;
			
			if(!proc)
			{
				proc = cast(GetClipboardFormatNameWProc)GetProcAddress(user32, NAME.ptr);
				if(!proc)
					getProcErr(NAME);
			}
		}
		
		wchar[] buf;
		int len;
		buf = new wchar[64];
		len = proc(format, buf.ptr, buf.length);
		if(!len)
			return null;
		return fromUnicode(buf.ptr, len);
	}
	else
	{
		char[] buf;
		int len;
		buf = new char[64];
		len = GetClipboardFormatNameA(format, buf.ptr, buf.length);
		if(!len)
			return null;
		return fromAnsi(buf.ptr, len);
	}
}


// On Windows 9x, the number of characters cannot exceed 8192.
int drawTextEx(HDC hdc, char[] text, LPRECT lprc, UINT dwDTFormat, LPDRAWTEXTPARAMS lpDTParams)
{
	// Note: an older version of MSDN says cchText should be -1 for a null terminated string,
	// whereas the newer MSDN says 1. Lets just play it safe and use a local null terminated
	// string when the length is 1 so that it won't continue reading past the 1 character,
	// reguardless of which MSDN version is correct.
	
	if(useUnicode)
	{
		version(STATIC_UNICODE)
		{
			alias DrawTextExW proc;
		}
		else
		{
			const char[] NAME = "DrawTextExW";
			static DrawTextExWProc proc = null;
			
			if(!proc)
			{
				proc = cast(DrawTextExWProc)GetProcAddress(user32, NAME.ptr);
				if(!proc)
					getProcErr(NAME);
			}
		}
		
		/+
		wchar* strz;
		strz = toUnicodez(text);
		return proc(hdc, strz, -1, lprc, dwDTFormat, lpDTParams);
		+/
		wchar[] str;
		wchar[2] tempStr;
		str = toUnicode(text);
		if(str.length == 1)
		{
			tempStr[0] = str[0];
			tempStr[1] = 0;
			str = tempStr[0 .. 1];
		}
		return proc(hdc, str.ptr, str.length, lprc, dwDTFormat, lpDTParams);
	}
	else
	{
		/+
		char* strz;
		strz = unsafeAnsiz(text);
		return DrawTextExA(hdc, strz, -1, lprc, dwDTFormat, lpDTParams);
		+/
		char[] str;
		char[2] tempStr;
		str = unsafeAnsi(text);
		if(str.length == 1)
		{
			tempStr[0] = str[0];
			tempStr[1] = 0;
			str = tempStr[0 .. 1];
		}
		return DrawTextExA(hdc, str.ptr, str.length, lprc, dwDTFormat, lpDTParams);
	}
}


char[] getCommandLine()
{
	// Windows 9x supports GetCommandLineW().
	return dfl.internal.utf.fromUnicodez(GetCommandLineW());
}


BOOL setCurrentDirectory(char[] pathName)
{
	if(useUnicode)
	{
		version(STATIC_UNICODE)
		{
			alias SetCurrentDirectoryW proc;
		}
		else
		{
			const char[] NAME = "SetCurrentDirectoryW";
			static SetCurrentDirectoryWProc proc = null;
			
			if(!proc)
			{
				proc = cast(SetCurrentDirectoryWProc)GetProcAddress(kernel32, NAME.ptr);
				if(!proc)
					getProcErr(NAME);
			}
		}
		
		return proc(toUnicodez(pathName));
	}
	else
	{
		return SetCurrentDirectoryA(unsafeAnsiz(pathName));
	}
}


char[] getCurrentDirectory()
{
	if(useUnicode)
	{
		version(STATIC_UNICODE)
		{
			alias GetCurrentDirectoryW proc;
		}
		else
		{
			const char[] NAME = "GetCurrentDirectoryW";
			static GetCurrentDirectoryWProc proc = null;
			
			if(!proc)
			{
				proc = cast(GetCurrentDirectoryWProc)GetProcAddress(kernel32, NAME.ptr);
				if(!proc)
					getProcErr(NAME);
			}
		}
		
		wchar* buf;
		int len;
		len = proc(0, null);
		buf = (new wchar[len]).ptr;
		len = proc(len, buf);
		if(!len)
			return null;
		return fromUnicode(buf, len);
	}
	else
	{
		char* buf;
		int len;
		len = GetCurrentDirectoryA(0, null);
		buf = (new char[len]).ptr;
		len = GetCurrentDirectoryA(len, buf);
		if(!len)
			return null;
		return fromAnsi(buf, len);
	}
}


char[] getComputerName()
{
	if(useUnicode)
	{
		version(STATIC_UNICODE)
		{
			alias GetComputerNameW proc;
		}
		else
		{
			const char[] NAME = "GetComputerNameW";
			static GetComputerNameWProc proc = null;
			
			if(!proc)
			{
				proc = cast(GetComputerNameWProc)GetProcAddress(kernel32, NAME.ptr);
				if(!proc)
					getProcErr(NAME);
			}
		}
		
		wchar[] buf;
		DWORD len = MAX_COMPUTERNAME_LENGTH + 1;
		buf = new wchar[len];
		if(!proc(buf.ptr, &len))
			return null;
		return fromUnicode(buf.ptr, len);
	}
	else
	{
		char[] buf;
		DWORD len = MAX_COMPUTERNAME_LENGTH + 1;
		buf = new char[len];
		if(!GetComputerNameA(buf.ptr, &len))
			return null;
		return fromAnsi(buf.ptr, len);
	}
}


char[] getSystemDirectory()
{
	if(useUnicode)
	{
		version(STATIC_UNICODE)
		{
			alias GetSystemDirectoryW proc;
		}
		else
		{
			const char[] NAME = "GetSystemDirectoryW";
			static GetSystemDirectoryWProc proc = null;
			
			if(!proc)
			{
				proc = cast(GetSystemDirectoryWProc)GetProcAddress(kernel32, NAME.ptr);
				if(!proc)
					getProcErr(NAME);
			}
		}
		
		wchar[] buf;
		UINT len;
		buf = new wchar[MAX_PATH];
		len = proc(buf.ptr, buf.length);
		if(!len)
			return null;
		return fromUnicode(buf.ptr, len);
	}
	else
	{
		char[] buf;
		UINT len;
		buf = new char[MAX_PATH];
		len = GetSystemDirectoryA(buf.ptr, buf.length);
		if(!len)
			return null;
		return fromAnsi(buf.ptr, len);
	}
}


char[] getUserName()
{
	if(useUnicode)
	{
		version(STATIC_UNICODE)
		{
			alias GetUserNameW proc;
		}
		else
		{
			const char[] NAME = "GetUserNameW";
			static GetUserNameWProc proc = null;
			
			if(!proc)
			{
				proc = cast(GetUserNameWProc)GetProcAddress(advapi32, NAME.ptr);
				if(!proc)
					getProcErr(NAME);
			}
		}
		
		wchar[256 + 1] buf;
		DWORD len = buf.length;
		if(!proc(buf.ptr, &len) || !len || !--len) // Also remove null-terminator.
			return null;
		return fromUnicode(buf.ptr, len);
	}
	else
	{
		char[256 + 1] buf;
		DWORD len = buf.length;
		if(!GetUserNameA(buf.ptr, &len) || !len || !--len) // Also remove null-terminator.
			return null;
		return fromAnsi(buf.ptr, len);
	}
}


// Returns 0 on failure.
DWORD expandEnvironmentStrings(char[] src, out char[] result)
{
	if(useUnicode)
	{
		version(STATIC_UNICODE)
		{
			alias ExpandEnvironmentStringsW proc;
		}
		else
		{
			const char[] NAME = "ExpandEnvironmentStringsW";
			static ExpandEnvironmentStringsWProc proc = null;
			
			if(!proc)
			{
				proc = cast(ExpandEnvironmentStringsWProc)GetProcAddress(kernel32, NAME.ptr);
				if(!proc)
					getProcErr(NAME);
			}
		}
		
		wchar* strz, dest;
		DWORD len;
		
		strz = toUnicodez(src);
		len = proc(strz, null, 0);
		if(!len)
			return 0;
		dest = (new wchar[len]).ptr;
		len = proc(strz, dest, len);
		if(!len)
			return 0;
		result = fromUnicode(dest, len - 1);
		return len;
	}
	else
	{
		char* strz, dest;
		DWORD len;
		
		strz = unsafeAnsiz(src);
		len = ExpandEnvironmentStringsA(strz, null, 0);
		if(!len)
			return 0;
		dest = (new char[len]).ptr;
		len = ExpandEnvironmentStringsA(strz, dest, len);
		if(!len)
			return 0;
		result = fromAnsi(dest, len - 1);
		return len;
	}
}


char[] getEnvironmentVariable(char[] name)
{
	if(useUnicode)
	{
		version(STATIC_UNICODE)
		{
			alias GetEnvironmentVariableW proc;
		}
		else
		{
			const char[] NAME = "GetEnvironmentVariableW";
			static GetEnvironmentVariableWProc proc = null;
			
			if(!proc)
			{
				proc = cast(GetEnvironmentVariableWProc)GetProcAddress(kernel32, NAME.ptr);
				if(!proc)
					getProcErr(NAME);
			}
		}
		
		wchar* strz, buf;
		DWORD len;
		strz = toUnicodez(name);
		len = proc(strz, null, 0);
		if(!len)
			return null;
		buf = (new wchar[len]).ptr;
		len = proc(strz, buf, len);
		return fromUnicode(buf, len);
	}
	else
	{
		char* strz, buf;
		DWORD len;
		strz = unsafeAnsiz(name);
		len = GetEnvironmentVariableA(strz, null, 0);
		if(!len)
			return null;
		buf = (new char[len]).ptr;
		len = GetEnvironmentVariableA(strz, buf, len);
		return fromAnsi(buf, len);
	}
}


int messageBox(HWND hWnd, char[] text, char[] caption, UINT uType)
{
	// Windows 9x supports MessageBoxW().
	return MessageBoxW(hWnd, toUnicodez(text), toUnicodez(caption), uType);
}


struct WndClass
{
	union
	{
		WNDCLASSW wcw;
		WNDCLASSA wca;
	}
	alias wcw wc;
	
	char[] className;
}


ATOM registerClass(inout WndClass wc)
{
	if(useUnicode)
	{
		version(STATIC_UNICODE)
		{
			alias RegisterClassW proc;
		}
		else
		{
			const char[] NAME = "RegisterClassW";
			static RegisterClassWProc proc = null;
			
			if(!proc)
			{
				proc = cast(RegisterClassWProc)GetProcAddress(user32, NAME.ptr);
				if(!proc)
					getProcErr(NAME);
			}
		}
		
		wc.wcw.lpszClassName = toUnicodez(wc.className);
		return proc(&wc.wcw);
	}
	else
	{
		wc.wca.lpszClassName = unsafeAnsiz(wc.className);
		return RegisterClassA(&wc.wca);
	}
}


BOOL getClassInfo(HINSTANCE hinst, char[] className, inout WndClass wc)
{
	wc.className = className; // ?
	
	if(useUnicode)
	{
		version(STATIC_UNICODE)
		{
			alias GetClassInfoW proc;
		}
		else
		{
			const char[] NAME = "GetClassInfoW";
			static GetClassInfoWProc proc = null;
			
			if(!proc)
			{
				proc = cast(GetClassInfoWProc)GetProcAddress(user32, NAME.ptr);
				if(!proc)
					getProcErr(NAME);
			}
		}
		
		return proc(hinst, toUnicodez(className), &wc.wcw);
	}
	else
	{
		return GetClassInfoA(hinst, unsafeAnsiz(className), &wc.wca);
	}
}


// Shouldn't have been implemented this way.
deprecated BOOL getTextExtentPoint32(HDC hdc, char[] text, LPSIZE lpSize)
{
	if(useUnicode)
	{
		version(STATIC_UNICODE)
		{
			alias GetTextExtentPoint32W proc;
		}
		else
		{
			const char[] NAME = "GetTextExtentPoint32W";
			static GetTextExtentPoint32WProc proc = null;
			
			if(!proc)
			{
				proc = cast(GetTextExtentPoint32WProc)GetProcAddress(gdi32, NAME.ptr);
				if(!proc)
					getProcErr(NAME);
			}
		}
		
		wchar[] str;
		str = toUnicode(text);
		return proc(hdc, str.ptr, str.length, lpSize);
	}
	else
	{
		// Using GetTextExtentPoint32A here even though W is supported in order
		// to keep the measurements accurate with DrawTextA.
		char[] str;
		str = unsafeAnsi(text);
		return GetTextExtentPoint32A(hdc, str.ptr, str.length, lpSize);
	}
}


char[] dragQueryFile(HDROP hDrop, UINT iFile)
{
	if(iFile >= 0xFFFFFFFF)
		return null;
	
	if(useUnicode)
	{
		version(STATIC_UNICODE)
		{
			alias DragQueryFileW proc;
		}
		else
		{
			const char[] NAME = "DragQueryFileW";
			static DragQueryFileWProc proc = null;
			
			if(!proc)
			{
				proc = cast(DragQueryFileWProc)GetProcAddress(GetModuleHandleA("shell32.dll"), NAME.ptr);
				if(!proc)
					getProcErr(NAME);
			}
		}
		
		wchar[] str;
		UINT len;
		len = proc(hDrop, iFile, null, 0);
		if(!len)
			return null;
		str = new wchar[len + 1];
		proc(hDrop, iFile, str.ptr, str.length);
		return fromUnicode(str.ptr, len);
	}
	else
	{
		char[] str;
		UINT len;
		len = DragQueryFileA(hDrop, iFile, null, 0);
		if(!len)
			return null;
		str = new char[len + 1];
		DragQueryFileA(hDrop, iFile, str.ptr, str.length);
		return fromAnsi(str.ptr, len);
	}
}


// Just gets the number of files.
UINT dragQueryFile(HDROP hDrop)
{
	return DragQueryFileA(hDrop, 0xFFFFFFFF, null, 0);
}


HANDLE createFile(char[] fileName, DWORD dwDesiredAccess, DWORD dwShareMode, LPSECURITY_ATTRIBUTES lpSecurityAttributes,
	DWORD dwCreationDistribution, DWORD dwFlagsAndAttributes, HANDLE hTemplateFile)
{
	if(useUnicode)
	{
		return CreateFileW(toUnicodez(fileName), dwDesiredAccess, dwShareMode, lpSecurityAttributes,
			dwCreationDistribution, dwFlagsAndAttributes, hTemplateFile);
	}
	else
	{
		return CreateFileA(unsafeAnsiz(fileName), dwDesiredAccess, dwShareMode, lpSecurityAttributes,
			dwCreationDistribution, dwFlagsAndAttributes, hTemplateFile);
	}
}


version = STATIC_UNICODE_DEF_WINDOW_PROC;


LRESULT defWindowProc(HWND hwnd, UINT msg, WPARAM wparam, LPARAM lparam)
{
	if(useUnicode)
	{
		version(STATIC_UNICODE_DEF_WINDOW_PROC)
		{
			alias DefWindowProcW proc;
		}
		else
		{
			const char[] NAME = "DefWindowProcW";
			static DefWindowProcWProc proc = null;
			
			if(!proc)
			{
				proc = cast(DefWindowProcWProc)GetProcAddress(user32, NAME.ptr);
				if(!proc)
					getProcErr(NAME);
			}
		}
		
		return proc(hwnd, msg, wparam, lparam);
	}
	else
	{
		return DefWindowProcA(hwnd, msg, wparam, lparam);
	}
}


LRESULT defDlgProc(HWND hwnd, UINT msg, WPARAM wparam, LPARAM lparam)
{
	if(useUnicode)
	{
		version(STATIC_UNICODE_DEF_WINDOW_PROC)
		{
			alias DefDlgProcW proc;
		}
		else
		{
			const char[] NAME = "DefDlgProcW";
			static DefDlgProcWProc proc = null;
			
			if(!proc)
			{
				proc = cast(DefDlgProcWProc)GetProcAddress(user32, NAME.ptr);
				if(!proc)
					getProcErr(NAME);
			}
		}
		
		return proc(hwnd, msg, wparam, lparam);
	}
	else
	{
		return DefDlgProcA(hwnd, msg, wparam, lparam);
	}
}


LRESULT defFrameProc(HWND hwnd, HWND hwndMdiClient, UINT msg, WPARAM wparam, LPARAM lparam)
{
	if(useUnicode)
	{
		version(STATIC_UNICODE_DEF_WINDOW_PROC)
		{
			alias DefFrameProcW proc;
		}
		else
		{
			const char[] NAME = "DefFrameProcW";
			static DefFrameProcWProc proc = null;
			
			if(!proc)
			{
				proc = cast(DefFrameProcWProc)GetProcAddress(user32, NAME.ptr);
				if(!proc)
					getProcErr(NAME);
			}
		}
		
		return proc(hwnd, hwndMdiClient, msg, wparam, lparam);
	}
	else
	{
		return DefFrameProcA(hwnd, hwndMdiClient, msg, wparam, lparam);
	}
}


LRESULT defMDIChildProc(HWND hwnd, UINT msg, WPARAM wparam, LPARAM lparam)
{
	if(useUnicode)
	{
		version(STATIC_UNICODE_DEF_WINDOW_PROC)
		{
			alias DefMDIChildProcW proc;
		}
		else
		{
			const char[] NAME = "DefMDIChildProcW";
			static DefMDIChildProcWProc proc = null;
			
			if(!proc)
			{
				proc = cast(DefMDIChildProcWProc)GetProcAddress(user32, NAME.ptr);
				if(!proc)
					getProcErr(NAME);
			}
		}
		
		return proc(hwnd, msg, wparam, lparam);
	}
	else
	{
		return DefMDIChildProcA(hwnd, msg, wparam, lparam);
	}
}


version = STATIC_UNICODE_PEEK_MESSAGE;
version = STATIC_UNICODE_DISPATCH_MESSAGE;


LONG dispatchMessage(MSG* pmsg)
{
	if(useUnicode)
	{
		version(STATIC_UNICODE_DISPATCH_MESSAGE)
		{
			alias DispatchMessageW dispatchproc;
		}
		else
		{
			const char[] DISPATCHNAME = "DispatchMessageW";
			static DispatchMessageWProc dispatchproc = null;
			
			if(!dispatchproc)
			{
				dispatchproc = cast(DispatchMessageWProc)GetProcAddress(user32, DISPATCHNAME);
				if(!dispatchproc)
					getProcErr(DISPATCHNAME);
			}
		}
		
		return dispatchproc(pmsg);
	}
	else
	{
		return DispatchMessageA(pmsg);
	}
}


BOOL peekMessage(MSG* pmsg, HWND hwnd = HWND.init, UINT wmFilterMin = 0, UINT wmFilterMax = 0, UINT removeMsg = PM_NOREMOVE)
{
	if(useUnicode)
	{
		version(STATIC_UNICODE_PEEK_MESSAGE)
		{
			alias PeekMessageW peekproc;
		}
		else
		{
			const char[] PEEKNAME = "PeekMessageW";
			static PeekMessageWProc peekproc = null;
			
			if(!peekproc)
			{
				peekproc = cast(PeekMessageWProc)GetProcAddress(user32, PEEKNAME);
				if(!peekproc)
					getProcErr(PEEKNAME);
			}
		}
		
		/+
		// Using PeekMessageA to test if the window is unicod.
		if(!PeekMessageA(pmsg, hwnd, wmFilterMin, wmFilterMax, PM_NOREMOVE)) // Don't remove to test if unicode.
			return 0;
		if(!IsWindowUnicode(pmsg.hwnd)) // Window is not unicode.
		{
			if(removeMsg == PM_NOREMOVE)
				return 1; // No need to do extra work here.
			return PeekMessageA(pmsg, hwnd, wmFilterMin, wmFilterMax, removeMsg);
		}
		else // Window is unicode.
		{
			return peekproc(pmsg, hwnd, wmFilterMin, wmFilterMax, removeMsg);
		}
		+/
		// Since I already know useUnicode, use PeekMessageW to test if the window is unicode.
		if(!peekproc(pmsg, hwnd, wmFilterMin, wmFilterMax, PM_NOREMOVE)) // Don't remove to test if unicode.
			return 0;
		if(!IsWindowUnicode(pmsg.hwnd)) // Window is not unicode.
		{
			return PeekMessageA(pmsg, hwnd, wmFilterMin, wmFilterMax, removeMsg);
		}
		else // Window is unicode.
		{
			if(removeMsg == PM_NOREMOVE)
				return 1; // No need to do extra work here.
			return peekproc(pmsg, hwnd, wmFilterMin, wmFilterMax, removeMsg);
		}
	}
	else
	{
		return PeekMessageA(pmsg, hwnd, wmFilterMin, wmFilterMax, removeMsg);
	}
}


BOOL getMessage(MSG* pmsg, HWND hwnd = HWND.init, UINT wmFilterMin = 0, UINT wmFilterMax = 0)
{
	if(!WaitMessage())
		return -1;
	if(!peekMessage(pmsg, hwnd, wmFilterMin, wmFilterMax, PM_REMOVE))
		return -1;
	if(WM_QUIT == pmsg.message)
		return 0;
	return 1;
}


BOOL isDialogMessage(HWND hwnd, MSG* pmsg)
{
	if(useUnicode)
	{
		version(STATIC_UNICODE)
		{
			alias IsDialogMessageW proc;
		}
		else
		{
			const char[] NAME = "IsDialogMessageW";
			static IsDialogMessageWProc proc = null;
			
			if(!proc)
			{
				proc = cast(IsDialogMessageWProc)GetProcAddress(user32, NAME.ptr);
				if(!proc)
					getProcErr(NAME);
			}
		}
		
		return proc(hwnd, pmsg);
	}
	else
	{
		return IsDialogMessageA(hwnd, pmsg);
	}
}


HANDLE findFirstChangeNotification(char[] pathName, BOOL watchSubtree, DWORD notifyFilter)
{
	if(useUnicode)
	{
		version(STATIC_UNICODE)
		{
			alias FindFirstChangeNotificationW proc;
		}
		else
		{
			const char[] NAME = "FindFirstChangeNotificationW";
			static FindFirstChangeNotificationWProc proc = null;
			
			if(!proc)
			{
				proc = cast(FindFirstChangeNotificationWProc)GetProcAddress(kernel32, NAME.ptr);
				if(!proc)
					getProcErr(NAME);
			}
		}
		
		return proc(toUnicodez(pathName), watchSubtree, notifyFilter);
	}
	else
	{
		return FindFirstChangeNotificationA(unsafeAnsiz(pathName), watchSubtree, notifyFilter);
	}
}


char[] getFullPathName(char[] fileName)
{
	DWORD len;
	
	if(useUnicode)
	{
		version(STATIC_UNICODE)
		{
			alias GetFullPathNameW proc;
		}
		else
		{
			const char[] NAME = "GetFullPathNameW";
			static GetFullPathNameWProc proc = null;
			
			if(!proc)
			{
				proc = cast(GetFullPathNameWProc)GetProcAddress(kernel32, NAME.ptr);
				if(!proc)
					getProcErr(NAME);
			}
		}
		
		wchar* fnw;
		fnw = toUnicodez(fileName);
		len = proc(fnw, 0, null, null);
		if(!len)
			return null;
		wchar[260] _wbuf;
		wchar[] wbuf = _wbuf;
		if(len > _wbuf.sizeof)
			wbuf = new wchar[len];
		len = proc(fnw, wbuf.length, wbuf.ptr, null);
		assert(len < wbuf.length);
		return fromUnicode(wbuf.ptr, len);
	}
	else
	{
		char* fna;
		fna = unsafeAnsiz(fileName);
		len = GetFullPathNameA(fna, 0, null, null);
		if(!len)
			return null;
		char[260] _abuf;
		char[] abuf = _abuf;
		if(len > _abuf.sizeof)
			abuf = new char[len];
		len = GetFullPathNameA(fna, abuf.length, abuf.ptr, null);
		assert(len < abuf.length);
		return fromAnsi(abuf.ptr, len);
	}
}


HINSTANCE loadLibraryEx(char[] libFileName, DWORD flags)
{
	if(useUnicode)
	{
		version(STATIC_UNICODE)
		{
			alias LoadLibraryExW proc;
		}
		else
		{
			const char[] NAME = "LoadLibraryExW";
			static LoadLibraryExWProc proc = null;
			
			if(!proc)
			{
				proc = cast(LoadLibraryExWProc)GetProcAddress(kernel32, NAME.ptr);
				if(!proc)
					getProcErr(NAME);
			}
		}
		
		return proc(toUnicodez(libFileName), HANDLE.init, flags);
	}
	else
	{
		return LoadLibraryExA(unsafeAnsiz(libFileName), HANDLE.init, flags);
	}
}


BOOL _setMenuItemInfoW(HMENU hMenu, UINT uItem, BOOL fByPosition, LPMENUITEMINFOW lpmii) // package
{
	if(useUnicode)
	{
		version(STATIC_UNICODE)
		{
			alias SetMenuItemInfoW proc;
		}
		else
		{
			const char[] NAME = "SetMenuItemInfoW";
			static SetMenuItemInfoWProc proc = null;
			
			if(!proc)
			{
				proc = cast(SetMenuItemInfoWProc)GetProcAddress(user32, NAME.ptr);
				if(!proc)
					getProcErr(NAME);
			}
		}
		
		return proc(hMenu, uItem, fByPosition, lpmii);
	}
	else
	{
		assert(0);
		return FALSE;
	}
}


BOOL _insertMenuItemW(HMENU hMenu, UINT uItem, BOOL fByPosition, LPMENUITEMINFOW lpmii) // package
{
	if(useUnicode)
	{
		version(STATIC_UNICODE)
		{
			alias InsertMenuItemW proc;
		}
		else
		{
			const char[] NAME = "InsertMenuItemW";
			static InsertMenuItemWProc proc = null;
			
			if(!proc)
			{
				proc = cast(InsertMenuItemWProc)GetProcAddress(user32, NAME.ptr);
				if(!proc)
					getProcErr(NAME);
			}
		}
		
		return proc(hMenu, uItem, fByPosition, lpmii);
	}
	else
	{
		assert(0);
		return FALSE;
	}
}


char[] regQueryValueString(HKEY hkey, char[] valueName, LPDWORD lpType = null)
{
	DWORD _type;
	if(!lpType)
		lpType = &_type;
	
	DWORD sz;
	
	if(useUnicode)
	{
		version(STATIC_UNICODE)
		{
			alias RegQueryValueExW proc;
		}
		else
		{
			const char[] NAME = "RegQueryValueExW";
			static RegQueryValueExWProc proc = null;
			
			if(!proc)
			{
				proc = cast(RegQueryValueExWProc)GetProcAddress(advapi32, NAME.ptr);
				if(!proc)
					getProcErr(NAME);
			}
		}
		
		//sz = 0;
		LPWSTR lpValueName = toUnicodez(valueName);
		proc(hkey, lpValueName, null, lpType, null, &sz);
		if(!sz || (REG_SZ != *lpType && REG_EXPAND_SZ != *lpType))
			return null;
		wchar[] ws = new wchar[sz];
		if(ERROR_SUCCESS != proc(hkey, lpValueName, null, null, cast(LPBYTE)ws.ptr, &sz))
			return null;
		//return fromUnicode(ws.ptr, ws.length - 1); // Somehow ends up throwing invalid UTF-16.
		return fromUnicodez(ws.ptr);
	}
	else
	{
		//sz = 0;
		LPSTR lpValueName = toAnsiz(valueName);
		RegQueryValueExA(hkey, lpValueName, null, lpType, null, &sz);
		if(!sz || (REG_SZ != *lpType && REG_EXPAND_SZ != *lpType))
			return null;
		char[] s = new char[sz];
		if(ERROR_SUCCESS != RegQueryValueExA(hkey, lpValueName, null, null, cast(LPBYTE)s.ptr, &sz))
			return null;
		//return fromAnsi(s.ptr, s.length - 1);
		return fromAnsiz(s.ptr);
	}
}

