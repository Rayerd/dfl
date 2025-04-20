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

import dfl.internal.clib;
import dfl.internal.dlib;
import dfl.internal.winapi : LPCITEMIDLIST, SHGetPathFromIDListA, SHGetPathFromIDListW;

import core.sys.windows.richedit;
import core.sys.windows.shellapi;
import core.sys.windows.winbase;
import core.sys.windows.windef;
import core.sys.windows.wingdi;
import core.sys.windows.winnls;
import core.sys.windows.winreg;
import core.sys.windows.winuser;

import std.windows.charset;


version(DFL_NO_D2_AND_ABOVE)
{
}
else
{
	version(D_Version2)
	{
		version = DFL_D2_AND_ABOVE;
	}
	else version(D_Version3)
	{
		version = DFL_D3_AND_ABOVE;
		version = DFL_D2_AND_ABOVE;
	}
}

// Do not support Win9x.
version = DFL_UNICODE;
enum useUnicode = true;

package:

version(DFL_LOAD_INTERNAL_LIBS)
{
	alias initInternalLib = LoadLibraryA;
}
else
{
	version = DFL_GET_INTERNAL_LIBS;
	
	alias initInternalLib = GetModuleHandleA;
}


HMODULE _user32, _kernel32, _advapi32, _gdi32;

@property HMODULE advapi32() nothrow // getter
{
	// advapi32 generally always delay loads.
	if(!_advapi32)
		_advapi32 = LoadLibraryA("advapi32.dll");
	return _advapi32;
}

@property HMODULE gdi32() nothrow // getter
{
	// gdi32 sometimes delay loads.
	version(DFL_GET_INTERNAL_LIBS)
	{
		if(!_gdi32)
			_gdi32 = LoadLibraryA("gdi32.dll");
	}
	return _gdi32;
}

@property HMODULE user32() nothrow // getter
{
	version(DFL_GET_INTERNAL_LIBS)
	{
		if(!_user32)
			_user32 = LoadLibraryA("user32.dll");
	}
	return _user32;
}

@property HMODULE kernel32() nothrow // getter
{
	version(DFL_GET_INTERNAL_LIBS)
	{
		if(!_kernel32)
			_kernel32 = LoadLibraryA("kernel32.dll");
	}
	return _kernel32;
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
		
		_user32 = initInternalLib("user32.dll");
		_kernel32 = initInternalLib("kernel32.dll");
		_advapi32 = GetModuleHandleA("advapi32.dll"); // Not guaranteed to be loaded.
		_gdi32 = initInternalLib("gdi32.dll");
	}
}


template _getlen(T)
{
	size_t _getlen(T* tz) pure
	in
	{
		assert(tz);
	}
	do
	{
		T* p;
		for(p = tz; *p; p++)
		{
		}
		return p - tz;
	}
}


public:

Dstringz unsafeStringz(Dstring s) nothrow pure
{
	if(!s.length)
		return "";
	
	// Check if already null terminated.
	if(!s.ptr[s.length]) // Disables bounds checking.
		return s.ptr;
	
	// Need to duplicate with null terminator.
	char[] result = new char[s.length + 1];
	result[0 .. s.length] = s[];
	result[s.length] = 0;
	//return result.ptr;
	return cast(Dstringz)result.ptr; // Needed in D2.
}


Dstring unicodeToAnsi(Dwstringz unicode, size_t ulen)
{
	if(!ulen)
		return null;
	
	int len = WideCharToMultiByte(0, 0, unicode, ulen.toI32, null, 0, null, null);
	assert(len > 0);
	
	char[] result = new char[len];
	len = WideCharToMultiByte(0, 0, unicode, ulen.toI32, result.ptr, len, null, null);
	assert(len == result.length);
	//return result[0 .. len - 1];
	return cast(Dstring)result[0 .. len - 1]; // Needed in D2.
}


Dwstring ansiToUnicode(Dstringz ansi, size_t len)
{
	len++;
	wchar[] ws = new wchar[len];
	
	len = MultiByteToWideChar(0, 0, ansi, len.toI32, ws.ptr, len.toI32);
	//assert(len == ws.length);
	ws = ws[0 .. len - 1]; // Exclude null char at end.
	
	//return ws;
	return cast(Dwstring)ws; // Needed in D2.
}


Dstring fromAnsi(Dstringz ansi, size_t len)
{
	return utf16stringtoUtf8string(ansiToUnicode(ansi, len));
}

version(DFL_D2_AND_ABOVE)
{
	Dstring fromAnsi(char* ansi, size_t len)
	{
		return fromAnsi(cast(Dstringz)ansi, len);
	}
}


Dstring fromAnsiz(Dstringz ansiz)
{
	if(!ansiz)
		return null;
	
	//return fromAnsi(ansiz, _getlen!(char)(ansiz));
	return fromAnsi(ansiz, _getlen(ansiz));
}

version(DFL_D2_AND_ABOVE)
{
	Dstring fromAnsiz(char* ansi)
	{
		return fromAnsiz(cast(Dstringz)ansi);
	}
}


private Dstring _toAnsiz(Dstring utf8, bool safe = true)
{
	// This function is intentionally unsafe; depends on "safe" param.
	foreach(char ch; utf8)
	{
		if(ch >= 0x80)
		{
			auto wsz = utf8stringToUtf16stringz(utf8);
			auto len = WideCharToMultiByte(0, 0, wsz, -1, null, 0, null, null);
			assert(len > 0);
			
			char[] result = new char[len];
			len = WideCharToMultiByte(0, 0, wsz, -1, result.ptr, len, null, null);
			assert(len == result.length);
			//return result[0 .. len - 1];
			return cast(Dstring)result[0 .. len - 1]; // Needed in D2.
		}
	}
	
	// Don't need conversion.
	if(safe)
		//return stringToStringz(utf8)[0 .. utf8.length];
		return cast(Dstring)stringToStringz(utf8)[0 .. utf8.length]; // Needed in D2.
	return unsafeStringz(utf8)[0 .. utf8.length];
}


private size_t toAnsiLength(Dstring utf8)
{
	foreach(char ch; utf8)
	{
		if(ch >= 0x80)
		{
			auto wsz = utf8stringToUtf16stringz(utf8);
			auto len = WideCharToMultiByte(0, 0, wsz, -1, null, 0, null, null);
			assert(len > 0);
			return len - 1; // Minus null.
		}
	}
	return utf8.length; // Just ASCII; same length.
}


private Dstring _unsafeAnsiz(Dstring utf8)
{
	return _toAnsiz(utf8, false);
}


Dstringz toAnsiz(Dstring utf8, bool safe = true)
{
	return _toAnsiz(utf8, safe).ptr;
}


Dstringz unsafeAnsiz(Dstring utf8)
{
	return _toAnsiz(utf8, false).ptr;
}


Dstring toAnsi(Dstring utf8, bool safe = true)
{
	return _toAnsiz(utf8, safe);
}


Dstring unsafeAnsi(Dstring utf8)
{
	return _toAnsiz(utf8, false);
}


Dstring fromUnicode(Dwstringz unicode, size_t len)
{
	return utf16stringtoUtf8string(unicode[0 .. len]);
}

version(DFL_D2_AND_ABOVE)
{
	Dstring fromUnicode(wchar* unicode, size_t len)
	{
		return fromUnicode(cast(Dwstringz)unicode, len);
	}
}


Dstring fromUnicodez(Dwstringz unicodez)
{
	if(!unicodez)
		return null;
	
	//return fromUnicode(unicodez, _getlen!(wchar)(unicodez));
	return fromUnicode(unicodez, _getlen(unicodez));
}

version(DFL_D2_AND_ABOVE)
{
	Dstring fromUnicodez(wchar* unicodez)
	{
		return fromUnicodez(cast(Dwstringz)unicodez);
	}
}


Dwstringz toUnicodez(Dstring utf8) pure
{
	//return utf8stringToUtf16stringz(utf8);
	return cast(Dwstringz)utf8stringToUtf16stringz(utf8); // Needed in D2.
}


Dwstring toUnicode(Dstring utf8) pure
{
	return utf8stringtoUtf16string(utf8);
}


size_t toUnicodeLength(Dstring utf8) pure
{
	size_t result = 0;
	foreach(wchar wch; utf8)
	{
		result++;
	}
	return result;
}


extern(Windows)
{
	alias CreateWindowExWProc = HWND function(DWORD dwExStyle, LPCWSTR lpClassName, LPCWSTR lpWindowName, DWORD dwStyle,
		int x, int y, int nWidth, int nHeight, HWND hWndParent, HMENU hMenu, HINSTANCE hInstance,
		LPVOID lpParam);
	alias GetWindowTextLengthWProc = int function(HWND hWnd);
	alias GetWindowTextWProc = int function(HWND hWnd, LPCWSTR lpString, int nMaxCount);
	alias SetWindowTextWProc = BOOL function(HWND hWnd, LPCWSTR lpString);
	alias SendMessageWProc = LRESULT function(HWND hWnd, UINT Msg, WPARAM wParam, LPARAM lParam);
	alias CallWindowProcWProc = LRESULT function(WNDPROC lpPrevWndFunc, HWND hWnd, UINT Msg, WPARAM wParam, LPARAM lParam);
	alias RegisterClipboardFormatWProc = UINT function(LPCWSTR lpszFormat);
	alias GetClipboardFormatNameWProc = int function (UINT format, LPWSTR lpszFormatName, int cchMaxCount);
	alias DrawTextExWProc = int function(HDC hdc, LPWSTR lpchText, int cchText, LPRECT lprc, UINT dwDTFormat,
		LPDRAWTEXTPARAMS lpDTParams);
	alias SetCurrentDirectoryWProc = BOOL function(LPCWSTR lpPathName);
	alias GetCurrentDirectoryWProc = DWORD function(DWORD nBufferLength, LPWSTR lpBuffer);
	alias GetComputerNameWProc = BOOL function(LPWSTR lpBuffer, LPDWORD nSize);
	alias GetSystemDirectoryWProc = UINT function(LPWSTR lpBuffer, UINT uSize);
	alias GetUserNameWProc = BOOL function(LPWSTR lpBuffer, LPDWORD nSize);
	alias ExpandEnvironmentStringsWProc = DWORD function(LPCWSTR lpSrc, LPWSTR lpDst, DWORD nSize);
	alias GetEnvironmentVariableWProc = DWORD function(LPCWSTR lpName, LPWSTR lpBuffer, DWORD nSize);
	alias RegSetValueExWProc = LONG function(HKEY hKey, LPCWSTR lpValueName, DWORD Reserved,
		DWORD dwType, BYTE* lpData, DWORD cbData);
	alias RegCreateKeyExWProc = LONG function(HKEY hKey, LPCWSTR lpSubKey, DWORD Reserved,
		LPWSTR lpClass, DWORD dwOptions, REGSAM samDesired, LPSECURITY_ATTRIBUTES lpSecurityAttributes,
		PHKEY phkResult, LPDWORD lpdwDisposition);
	alias RegOpenKeyExWProc = LONG function(HKEY hKey, LPCWSTR lpSubKey, DWORD ulOptions, REGSAM samDesired,
		PHKEY phkResult);
	alias RegDeleteKeyWProc = LONG function(HKEY hKey, LPCWSTR lpSubKey);
	alias RegEnumKeyExWProc = LONG function(HKEY hKey, DWORD dwIndex, LPWSTR lpName, LPDWORD lpcbName,
		LPDWORD lpReserved, LPWSTR lpClass, LPDWORD lpcbClass, PFILETIME lpftLastWriteTime);
	alias RegQueryValueExWProc = LONG function(HKEY hKey, LPCWSTR lpValueName, LPDWORD lpReserved,
		LPDWORD lpType, LPBYTE lpData, LPDWORD lpcbData);
	alias RegEnumValueWProc = LONG function(HKEY hKey, DWORD dwIndex, LPTSTR lpValueName,
		LPDWORD lpcbValueName, LPDWORD lpReserved, LPDWORD lpType, LPBYTE lpData, LPDWORD lpcbData);
	alias RegisterClassWProc = ATOM function(WNDCLASSW* lpWndClass);
	alias GetTextExtentPoint32WProc = BOOL function(HDC hdc, LPCWSTR lpString, int cbString, LPSIZE lpSize);
	alias LoadImageWProc = HANDLE function(HINSTANCE hinst, LPCWSTR lpszName, UINT uType,
		int cxDesired, int cyDesired, UINT fuLoad);
	alias DragQueryFileWProc = UINT function(HDROP hDrop, UINT iFile, LPWSTR lpszFile, UINT cch);
	alias GetModuleFileNameWProc = DWORD function(HMODULE hModule, LPWSTR lpFilename, DWORD nSize);
	alias DispatchMessageWProc = LONG function(MSG* lpmsg);
	alias PeekMessageWProc = BOOL function(LPMSG lpMsg, HWND hWnd, UINT wMsgFilterMin, UINT wMsgFilterMax,
		UINT wRemoveMsg);
	alias IsDialogMessageWProc = BOOL function(HWND hDlg, LPMSG lpMsg);
	alias DefWindowProcWProc = LRESULT function(HWND hWnd, UINT Msg, WPARAM wParam, LPARAM lParam);
	alias DefDlgProcWProc = LRESULT function(HWND hDlg, UINT Msg, WPARAM wParam, LPARAM lParam);
	alias DefFrameProcWProc = LRESULT function(HWND hWnd, HWND hWndMDIClient, UINT uMsg, WPARAM wParam, LPARAM lParam);
	alias DefMDIChildProcWProc = LRESULT function(HWND hWnd, UINT uMsg, WPARAM wParam, LPARAM lParam);
	alias GetClassInfoWProc = BOOL function(HINSTANCE hInstance, LPCWSTR lpClassName, LPWNDCLASSW lpWndClass);
	alias FindFirstChangeNotificationWProc = HANDLE function(LPCWSTR lpPathName, BOOL bWatchSubtree, DWORD dwNotifyFilter);
	alias GetFullPathNameWProc = DWORD function(LPCWSTR lpFileName, DWORD nBufferLength, LPWSTR lpBuffer,
		LPWSTR *lpFilePart);
	alias LoadLibraryExWProc = typeof(&LoadLibraryExW);
	alias SetMenuItemInfoWProc = typeof(&SetMenuItemInfoW);
	alias InsertMenuItemWProc = typeof(&InsertMenuItemW);
	alias CreateFontIndirectWProc = typeof(&CreateFontIndirectW);
	alias GetObjectWProc = typeof(&GetObjectW);
}


private void getProcErr(Dstring procName)
{
	Dstring errdesc;
	version(DFL_NO_PROC_ERROR_INFO)
	{
	}
	else
	{
		auto le = cast(int)GetLastError();
		if(le)
			errdesc = " (error " ~ intToString(le) ~ ")";
	}
	throw new Exception("Unable to load procedure " ~ procName ~ errdesc);
}


// If loading from a resource just use LoadImageA().
HANDLE loadImage(HINSTANCE hinst, Dstring name, UINT uType, int cxDesired, int cyDesired, UINT fuLoa)
{
	if(useUnicode)
	{
		version(STATIC_UNICODE)
		{
			alias proc = LoadImageW;
		}
		else
		{
			enum NAME = "LoadImageW";
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


HWND createWindowEx(DWORD dwExStyle, Dstring className, Dstring windowName, DWORD dwStyle,
	int x, int y, int nWidth, int nHeight, HWND hWndParent, HMENU hMenu, HINSTANCE hInstance,
	LPVOID lpParam)
{
	if(useUnicode)
	{
		version(STATIC_UNICODE)
		{
			alias proc = CreateWindowExW;
		}
		else
		{
			enum NAME = "CreateWindowExW";
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


HWND createWindow(Dstring className, Dstring windowName, DWORD dwStyle, int x, int y,
	int nWidth, int nHeight, HWND hWndParent, HMENU hMenu, HANDLE hInstance, LPVOID lpParam)
{
	return createWindowEx(0, className, windowName, dwStyle, x, y,
		nWidth, nHeight, hWndParent, hMenu, hInstance, lpParam);
}


Dstring getWindowText(HWND hwnd)
{
	if(useUnicode)
	{
		version(STATIC_UNICODE)
		{
			alias proc = GetWindowTextW;
			alias proclen = GetWindowTextLengthW;
		}
		else
		{
			enum NAME = "GetWindowTextW";
			static GetWindowTextWProc proc = null;
			
			enum NAMELEN = "GetWindowTextLengthW";
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
		
		size_t len = proclen(hwnd);
		if(!len)
			return null;
		len++;
		wchar* buf = (new wchar[len]).ptr;
		
		len = proc(hwnd, buf, len.toI32);
		return fromUnicode(buf, len);
	}
	else
	{
		size_t len = GetWindowTextLengthA(hwnd);
		if(!len)
			return null;
		len++;
		char* buf = (new char[len]).ptr;
		
		len = GetWindowTextA(hwnd, buf, len.toI32);
		return fromAnsi(buf, len);
	}
}


BOOL setWindowText(HWND hwnd, Dstring str)
{
	if(useUnicode)
	{
		version(STATIC_UNICODE)
		{
			alias proc = SetWindowTextW;
		}
		else
		{
			enum NAME = "SetWindowTextW";
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


Dstring getModuleFileName(HMODULE hmod)
{
	if(useUnicode)
	{
		version(STATIC_UNICODE)
		{
			alias proc = GetModuleFileNameW;
		}
		else
		{
			enum NAME = "GetModuleFileNameW";
			static GetModuleFileNameWProc proc = null;
			
			if(!proc)
			{
				proc = cast(GetModuleFileNameWProc)GetProcAddress(kernel32, NAME.ptr);
				if(!proc)
					getProcErr(NAME);
			}
		}
		
		wchar[] s = new wchar[MAX_PATH];
		DWORD len = proc(hmod, s.ptr, s.length.toI32);
		return fromUnicode(s.ptr, len);
	}
	else
	{
		char[] s = new char[MAX_PATH];
		DWORD len = GetModuleFileNameA(hmod, s.ptr, s.length.toI32);
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
			enum NAME = "SendMessageW";
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
Dstring emGetSelText(HWND hwnd, size_t selTextLength)
{
	if(useUnicode)
	{
		version(STATIC_UNICODE_SEND_MESSAGE)
		{
			alias proc = SendMessageW;
		}
		else
		{
			SendMessageWProc proc;
			proc = _loadSendMessageW();
		}
		
		wchar[] buf = new wchar[selTextLength + 1];
		size_t len = proc(hwnd, EM_GETSELTEXT, 0, cast(LPARAM)buf.ptr);
		return fromUnicode(buf.ptr, len);
	}
	else
	{
		char[] buf = new char[selTextLength + 1];
		size_t len = SendMessageA(hwnd, EM_GETSELTEXT, 0, cast(LPARAM)buf.ptr);
		return fromAnsi(buf.ptr, len);
	}
}


// Gets the selected text of an edit box.
// This needs to retrieve the entire text and strip out the extra.
Dstring getSelectedText(HWND hwnd)
{
	uint v1, v2;
	uint len;
	
	if(useUnicode)
	{
		version(STATIC_UNICODE_SEND_MESSAGE)
		{
			alias proc = SendMessageW;
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
		
		len = proc(hwnd, WM_GETTEXTLENGTH, 0, 0).toI32;
		if(len)
		{
			len++;
			wchar* buf = (new wchar[len]).ptr;
			
			len = proc(hwnd, WM_GETTEXT, len, cast(LPARAM)buf).toI32;
			if(len)
			{
				wchar[] s = buf[v1 .. v2].dup;
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
		
		len = SendMessageA(hwnd, WM_GETTEXTLENGTH, 0, 0).toI32;
		if(len)
		{
			len++;
			char* buf = (new char[len]).ptr;
			
			len = SendMessageA(hwnd, WM_GETTEXT, len, cast(LPARAM)buf).toI32;
			if(len)
			{
				char[] s = buf[v1 .. v2].dup;
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
			alias proc = SendMessageW;
		}
		else
		{
			SendMessageWProc proc;
			proc = _loadSendMessageW();
		}
		
		proc(hwnd, EM_SETPASSWORDCHAR, pwc, 0); // TODO: ?
	}
	else
	{
		Dstring chs = utf32stringtoUtf8string((&pwc)[0 .. 1]);
		Dstring ansichs = unsafeAnsi(chs);
		
		if(ansichs)
			SendMessageA(hwnd, EM_SETPASSWORDCHAR, ansichs[0], 0); // TODO: ?
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
			alias proc = SendMessageW;
		}
		else
		{
			SendMessageWProc proc;
			proc = _loadSendMessageW();
		}
		
		return cast(dchar)proc(hwnd, EM_GETPASSWORDCHAR, 0, 0); // TODO: ?
	}
	else
	{
		char ansich = cast(char)SendMessageA(hwnd, EM_GETPASSWORDCHAR, 0, 0);
		//Dstring chs = fromAnsi((&ansich)[0 .. 1], 1);
		Dstring chs = fromAnsi(&ansich, 1);
		Ddstring dchs = utf8stringtoUtf32string(chs);
		if(dchs.length == 1)
			return dchs[0]; // TODO: ?
		return 0;
	}
}


LRESULT sendMessage(HWND hwnd, UINT msg, WPARAM wparam, LPARAM lparam)
{
	if(useUnicode)
	{
		version(STATIC_UNICODE_SEND_MESSAGE)
		{
			alias proc = SendMessageW;
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


LRESULT sendMessage(HWND hwnd, UINT msg, WPARAM wparam, Dstring lparam, bool safe = true)
{
	if(useUnicode)
	{
		version(STATIC_UNICODE_SEND_MESSAGE)
		{
			alias proc = SendMessageW;
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


LRESULT sendMessageUnsafe(HWND hwnd, UINT msg, WPARAM wparam, Dstring lparam)
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
			alias proc = CallWindowProcW;
		}
		else
		{
			enum NAME = "CallWindowProcW";
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


UINT registerClipboardFormat(Dstring formatName)
{
	if(useUnicode)
	{
		version(STATIC_UNICODE)
		{
			alias proc = RegisterClipboardFormatW;
		}
		else
		{
			enum NAME = "RegisterClipboardFormatW";
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


Dstring getClipboardFormatName(UINT format)
{
	if(useUnicode)
	{
		version(STATIC_UNICODE)
		{
			alias proc = GetClipboardFormatNameW;
		}
		else
		{
			enum NAME = "GetClipboardFormatNameW";
			static GetClipboardFormatNameWProc proc = null;
			
			if(!proc)
			{
				proc = cast(GetClipboardFormatNameWProc)GetProcAddress(user32, NAME.ptr);
				if(!proc)
					getProcErr(NAME);
			}
		}
		
		wchar[] buf = new wchar[256];
		int len = proc(format, buf.ptr, buf.length.toI32);
		if(!len)
			return null;
		return fromUnicode(buf.ptr, len);
	}
	else
	{
		char[] buf = new char[256];
		int len = GetClipboardFormatNameA(format, buf.ptr, buf.length.toI32);
		if(!len)
			return null;
		return fromAnsi(buf.ptr, len);
	}
}


// On Windows 9x, the number of characters cannot exceed 8192.
int drawTextEx(HDC hdc, Dstring text, LPRECT lprc, UINT dwDTFormat, LPDRAWTEXTPARAMS lpDTParams)
{
	// Note: an older version of MSDN says cchText should be -1 for a null terminated string,
	// whereas the newer MSDN says 1. Lets just play it safe and use a local null terminated
	// string when the length is 1 so that it won't continue reading past the 1 character,
	// reguardless of which MSDN version is correct.
	
	if(useUnicode)
	{
		version(STATIC_UNICODE)
		{
			alias proc = DrawTextExW;
		}
		else
		{
			enum NAME = "DrawTextExW";
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
		wchar[2] tempStr;
		Dwstring str = toUnicode(text);
		if(str.length == 1)
		{
			tempStr[0] = str[0];
			tempStr[1] = 0;
			//str = tempStr[0 .. 1];
			str = cast(Dwstring)tempStr[0 .. 1]; // Needed in D2.
		}
		//return proc(hdc, str.ptr, str.length, lprc, dwDTFormat, lpDTParams);
		return proc(hdc, cast(wchar*)str.ptr, str.length.toI32, lprc, dwDTFormat, lpDTParams); // Needed in D2.
	}
	else
	{
		/+
		char* strz;
		strz = unsafeAnsiz(text);
		return DrawTextExA(hdc, strz, -1, lprc, dwDTFormat, lpDTParams);
		+/
		char[2] tempStr;
		Dstring str = unsafeAnsi(text);
		if(str.length == 1)
		{
			tempStr[0] = str[0];
			tempStr[1] = 0;
			//str = tempStr[0 .. 1];
			str = cast(Dstring)tempStr[0 .. 1]; // Needed in D2.
		}
		//return DrawTextExA(hdc, str.ptr, str.length, lprc, dwDTFormat, lpDTParams);
		return DrawTextExA(hdc, cast(char*)str.ptr, str.length.toI32, lprc, dwDTFormat, lpDTParams); // Needed in D2.
	}
}


Dstring getCommandLine()
{
	// Windows 9x supports GetCommandLineW().
	return dfl.internal.utf.fromUnicodez(GetCommandLineW());
}


/* MSDN:
	The current directory state written by the SetCurrentDirectory function
	is stored as a global variable in each process, therefore multithreaded
	applications cannot reliably use this value without possible data
	corruption from other threads that may also be reading or setting this
	value. This limitation also applies to the GetCurrentDirectory and
	GetFullPathName functions.
*/
// This doesn't prevent the problem, but it can minimize it.
// e.g. file dialogs set it.
//class CurDirLockType { }


BOOL setCurrentDirectory(Dstring pathName)
{
	//synchronized(typeid(CurDirLockType))
	{
		if(useUnicode)
		{
			version(STATIC_UNICODE)
			{
				alias proc = SetCurrentDirectoryW;
			}
			else
			{
				enum NAME = "SetCurrentDirectoryW";
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
}


Dstring getCurrentDirectory()
{
	//synchronized(typeid(CurDirLockType))
	{
		if(useUnicode)
		{
			version(STATIC_UNICODE)
			{
				alias proc = GetCurrentDirectoryW;
			}
			else
			{
				enum NAME = "GetCurrentDirectoryW";
				static GetCurrentDirectoryWProc proc = null;
				
				if(!proc)
				{
					proc = cast(GetCurrentDirectoryWProc)GetProcAddress(kernel32, NAME.ptr);
					if(!proc)
						getProcErr(NAME);
				}
			}
			
			int len = proc(0, null);
			wchar* buf = (new wchar[len]).ptr;
			len = proc(len, buf);
			if(!len)
				return null;
			return fromUnicode(buf, len);
		}
		else
		{
			int len = GetCurrentDirectoryA(0, null);
			char* buf = (new char[len]).ptr;
			len = GetCurrentDirectoryA(len, buf);
			if(!len)
				return null;
			return fromAnsi(buf, len);
		}
	}
}


Dstring getFullPathName(Dstring fileName)
{
	//synchronized(typeid(CurDirLockType))
	{
		DWORD len;
		
		if(useUnicode)
		{
			version(STATIC_UNICODE)
			{
				alias proc = GetFullPathNameW;
			}
			else
			{
				enum NAME = "GetFullPathNameW";
				static GetFullPathNameWProc proc = null;
				
				if(!proc)
				{
					proc = cast(GetFullPathNameWProc)GetProcAddress(kernel32, NAME.ptr);
					if(!proc)
						getProcErr(NAME);
				}
			}
			
			auto fnw = toUnicodez(fileName);
			len = proc(fnw, 0, null, null);
			if(!len)
				return null;
			wchar[260] _wbuf;
			wchar[] wbuf = _wbuf;
			if(len > _wbuf.sizeof)
				wbuf = new wchar[len];
			len = proc(fnw, wbuf.length.toI32, wbuf.ptr, null);
			assert(len < wbuf.length);
			return fromUnicode(wbuf.ptr, len);
		}
		else
		{
			auto fna = unsafeAnsiz(fileName);
			len = GetFullPathNameA(fna, 0, null, null);
			if(!len)
				return null;
			char[260] _abuf;
			char[] abuf = _abuf;
			if(len > _abuf.sizeof)
				abuf = new char[len];
			len = GetFullPathNameA(fna, abuf.length.toI32, abuf.ptr, null);
			assert(len < abuf.length);
			return fromAnsi(abuf.ptr, len);
		}
	}
}


Dstring getComputerName()
{
	if(useUnicode)
	{
		version(STATIC_UNICODE)
		{
			alias proc = GetComputerNameW;
		}
		else
		{
			enum NAME = "GetComputerNameW";
			static GetComputerNameWProc proc = null;
			
			if(!proc)
			{
				proc = cast(GetComputerNameWProc)GetProcAddress(kernel32, NAME.ptr);
				if(!proc)
					getProcErr(NAME);
			}
		}
		
		DWORD len = MAX_COMPUTERNAME_LENGTH + 1;
		wchar[] buf = new wchar[len];
		if(!proc(buf.ptr, &len))
			return null;
		return fromUnicode(buf.ptr, len);
	}
	else
	{
		DWORD len = MAX_COMPUTERNAME_LENGTH + 1;
		char[] buf = new char[len];
		if(!GetComputerNameA(buf.ptr, &len))
			return null;
		return fromAnsi(buf.ptr, len);
	}
}


Dstring getSystemDirectory()
{
	if(useUnicode)
	{
		version(STATIC_UNICODE)
		{
			alias proc = GetSystemDirectoryW;
		}
		else
		{
			enum NAME = "GetSystemDirectoryW";
			static GetSystemDirectoryWProc proc = null;
			
			if(!proc)
			{
				proc = cast(GetSystemDirectoryWProc)GetProcAddress(kernel32, NAME.ptr);
				if(!proc)
					getProcErr(NAME);
			}
		}
		
		wchar[] buf = new wchar[MAX_PATH];
		UINT len = proc(buf.ptr, buf.length.toI32);
		if(!len)
			return null;
		return fromUnicode(buf.ptr, len);
	}
	else
	{
		char[] buf = new char[MAX_PATH];
		UINT len = GetSystemDirectoryA(buf.ptr, buf.length.toI32);
		if(!len)
			return null;
		return fromAnsi(buf.ptr, len);
	}
}


Dstring getUserName()
{
	if(useUnicode)
	{
		version(STATIC_UNICODE)
		{
			alias proc = GetUserNameW;
		}
		else
		{
			enum NAME = "GetUserNameW";
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
DWORD expandEnvironmentStrings(Dstring src, out Dstring result)
{
	if(useUnicode)
	{
		version(STATIC_UNICODE)
		{
			alias proc = ExpandEnvironmentStringsW;
		}
		else
		{
			enum NAME = "ExpandEnvironmentStringsW";
			static ExpandEnvironmentStringsWProc proc = null;
			
			if(!proc)
			{
				proc = cast(ExpandEnvironmentStringsWProc)GetProcAddress(kernel32, NAME.ptr);
				if(!proc)
					getProcErr(NAME);
			}
		}
		
		auto strz = toUnicodez(src);
		DWORD len = proc(strz, null, 0);
		if(!len)
			return 0;
		wchar* dest = (new wchar[len]).ptr;
		len = proc(strz, dest, len);
		if(!len)
			return 0;
		result = fromUnicode(dest, len - 1);
		return len;
	}
	else
	{
		auto strz = unsafeAnsiz(src);
		DWORD len = ExpandEnvironmentStringsA(strz, null, 0);
		if(!len)
			return 0;
		char* dest = (new char[len]).ptr;
		len = ExpandEnvironmentStringsA(strz, dest, len);
		if(!len)
			return 0;
		result = fromAnsi(dest, len - 1);
		return len;
	}
}


Dstring getEnvironmentVariable(Dstring name)
{
	if(useUnicode)
	{
		version(STATIC_UNICODE)
		{
			alias proc = GetEnvironmentVariableW;
		}
		else
		{
			enum NAME = "GetEnvironmentVariableW";
			static GetEnvironmentVariableWProc proc = null;
			
			if(!proc)
			{
				proc = cast(GetEnvironmentVariableWProc)GetProcAddress(kernel32, NAME.ptr);
				if(!proc)
					getProcErr(NAME);
			}
		}
		
		auto strz = toUnicodez(name);
		DWORD len = proc(strz, null, 0);
		if(!len)
			return null;
		wchar* buf = (new wchar[len]).ptr;
		len = proc(strz, buf, len);
		return fromUnicode(buf, len);
	}
	else
	{
		auto strz = unsafeAnsiz(name);
		DWORD len = GetEnvironmentVariableA(strz, null, 0);
		if(!len)
			return null;
		char* buf = (new char[len]).ptr;
		len = GetEnvironmentVariableA(strz, buf, len);
		return fromAnsi(buf, len);
	}
}


int messageBox(HWND hWnd, Dstring text, Dstring caption, UINT uType)
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
	alias wc = wcw;
	
	Dstring className;
}


ATOM registerClass(ref WndClass wc)
{
	if(useUnicode)
	{
		version(STATIC_UNICODE)
		{
			alias proc = RegisterClassW;
		}
		else
		{
			enum NAME = "RegisterClassW";
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


BOOL getClassInfo(HINSTANCE hinst, Dstring className, ref WndClass wc)
{
	wc.className = className; // TODO: ?
	
	if(useUnicode)
	{
		version(STATIC_UNICODE)
		{
			alias proc = GetClassInfoW;
		}
		else
		{
			enum NAME = "GetClassInfoW";
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
deprecated BOOL getTextExtentPoint32(HDC hdc, Dstring text, LPSIZE lpSize)
{
	if(useUnicode)
	{
		version(STATIC_UNICODE)
		{
			alias proc = GetTextExtentPoint32W;
		}
		else
		{
			enum NAME = "GetTextExtentPoint32W";
			static GetTextExtentPoint32WProc proc = null;
			
			if(!proc)
			{
				proc = cast(GetTextExtentPoint32WProc)GetProcAddress(gdi32, NAME.ptr);
				if(!proc)
					getProcErr(NAME);
			}
		}
		
		Dwstring str = toUnicode(text);
		return proc(hdc, str.ptr, str.length.toI32, lpSize);
	}
	else
	{
		// Using GetTextExtentPoint32A here even though W is supported in order
		// to keep the measurements accurate with DrawTextA.
		Dstring str = unsafeAnsi(text);
		return GetTextExtentPoint32A(hdc, str.ptr, str.length.toI32, lpSize);
	}
}


Dstring dragQueryFile(HDROP hDrop, UINT idxFile)
{
	if(idxFile >= 0xFFFFFFFF)
		return null;
	
	if(useUnicode)
	{
		version(STATIC_UNICODE)
		{
			alias proc = DragQueryFileW;
		}
		else
		{
			enum NAME = "DragQueryFileW";
			static DragQueryFileWProc proc = null;
			
			if(!proc)
			{
				proc = cast(DragQueryFileWProc)GetProcAddress(GetModuleHandleA("shell32.dll"), NAME.ptr);
				if(!proc)
					getProcErr(NAME);
			}
		}
		
		UINT len = proc(hDrop, idxFile, null, 0);
		if(!len)
			return null;
		wchar[] str = new wchar[len + 1];
		proc(hDrop, idxFile, str.ptr, str.length.toI32);
		return fromUnicode(str.ptr, len);
	}
	else
	{
		UINT len = DragQueryFileA(hDrop, idxFile, null, 0);
		if(!len)
			return null;
		char[] str = new char[len + 1];
		DragQueryFileA(hDrop, idxFile, str.ptr, str.length.toI32);
		return fromAnsi(str.ptr, len);
	}
}


// Just gets the number of files.
UINT dragQueryFile(HDROP hDrop)
{
	return DragQueryFileA(hDrop, 0xFFFFFFFF, null, 0);
}


HANDLE createFile(Dstring fileName, DWORD dwDesiredAccess, DWORD dwShareMode, LPSECURITY_ATTRIBUTES lpSecurityAttributes,
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
			alias proc = DefWindowProcW;
		}
		else
		{
			enum NAME = "DefWindowProcW";
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
			alias proc = DefDlgProcW;
		}
		else
		{
			enum NAME = "DefDlgProcW";
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
			alias proc = DefFrameProcW;
		}
		else
		{
			enum NAME = "DefFrameProcW";
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
			alias proc = DefMDIChildProcW;
		}
		else
		{
			enum NAME = "DefMDIChildProcW";
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
			alias dispatchproc = DispatchMessageW;
		}
		else
		{
			enum DISPATCHNAME = "DispatchMessageW";
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
			alias peekproc = PeekMessageW;
		}
		else
		{
			enum PEEKNAME = "PeekMessageW";
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
			alias proc = IsDialogMessageW;
		}
		else
		{
			enum NAME = "IsDialogMessageW";
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


HANDLE findFirstChangeNotification(Dstring pathName, BOOL watchSubtree, DWORD notifyFilter)
{
	if(useUnicode)
	{
		version(STATIC_UNICODE)
		{
			alias proc = FindFirstChangeNotificationW;
		}
		else
		{
			enum NAME = "FindFirstChangeNotificationW";
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


HINSTANCE loadLibraryEx(Dstring libFileName, DWORD flags)
{
	if(useUnicode)
	{
		version(STATIC_UNICODE)
		{
			alias proc = LoadLibraryExW;
		}
		else
		{
			enum NAME = "LoadLibraryExW";
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
			alias proc = SetMenuItemInfoW;
		}
		else
		{
			enum NAME = "SetMenuItemInfoW";
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
	}
}


BOOL _insertMenuItemW(HMENU hMenu, UINT uItem, BOOL fByPosition, LPMENUITEMINFOW lpmii) // package
{
	if(useUnicode)
	{
		version(STATIC_UNICODE)
		{
			alias proc = InsertMenuItemW;
		}
		else
		{
			enum NAME = "InsertMenuItemW";
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
	}
}


Dstring regQueryValueString(HKEY hkey, Dstring valueName, LPDWORD lpType = null)
{
	DWORD _type;
	if(!lpType)
		lpType = &_type;
	
	DWORD sz;
	
	if(useUnicode)
	{
		version(STATIC_UNICODE)
		{
			alias proc = RegQueryValueExW;
		}
		else
		{
			enum NAME = "RegQueryValueExW";
			static RegQueryValueExWProc proc = null;
			
			if(!proc)
			{
				proc = cast(RegQueryValueExWProc)GetProcAddress(advapi32, NAME.ptr);
				if(!proc)
					getProcErr(NAME);
			}
		}
		
		//sz = 0;
		auto lpValueName = toUnicodez(valueName);
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
		auto lpValueName = toAnsiz(valueName);
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


struct LogFont
{
	union
	{
		LOGFONTW lfw;
		LOGFONTA lfa;
	}
	alias lf = lfw;
	
	Dstring faceName;
}


HFONT createFontIndirect(ref LogFont lf)
{
	if(useUnicode)
	{
		version(STATIC_UNICODE)
		{
			alias proc = CreateFontIndirectW;
		}
		else
		{
			enum NAME = "CreateFontIndirectW";
			static CreateFontIndirectWProc proc = null;
			
			if(!proc)
			{
				proc = cast(CreateFontIndirectWProc)GetProcAddress(gdi32, NAME.ptr);
				if(!proc)
					getProcErr(NAME);
			}
		}
		
		Dwstring ws = toUnicode(lf.faceName);
		if(ws.length >= LF_FACESIZE)
			ws = ws[0 .. LF_FACESIZE - 1]; // TODO: ?
		foreach(idx, wch; ws)
		{
			lf.lfw.lfFaceName[idx] = wch;
		}
		lf.lfw.lfFaceName[ws.length] = 0;
		
		return proc(&lf.lfw);
	}
	else
	{
		Dstring as = toAnsi(lf.faceName);
		if(as.length >= LF_FACESIZE)
			as = as[0 .. LF_FACESIZE - 1]; // TODO: ?
		foreach(idx, ach; as)
		{
			lf.lfa.lfFaceName[idx] = ach;
		}
		lf.lfa.lfFaceName[as.length] = 0;
		
		return CreateFontIndirectA(&lf.lfa);
	}
}


// GetObject for a LogFont.
int getLogFont(HFONT hf, ref LogFont lf)
{
	static if(useUnicode)
	{
		version(STATIC_UNICODE)
		{
			alias proc = GetObjectW;
		}
		else
		{
			enum NAME = "GetObjectW";
			static GetObjectWProc proc = null;
			
			if(!proc)
			{
				proc = cast(GetObjectWProc)GetProcAddress(gdi32, NAME.ptr);
				if(!proc)
					getProcErr(NAME);
			}
		}
		
		if(LOGFONTW.sizeof != proc(hf, LOGFONTW.sizeof, &lf.lfw))
			return 0;
		lf.faceName = fromUnicodez(lf.lfw.lfFaceName.ptr);
		return LOGFONTW.sizeof;
	}
	else
	{
		if(LOGFONTA.sizeof != GetObjectA(hf, LOGFONTA.sizeof, &lf.lfa))
			return 0;
		lf.faceName = fromAnsiz(lf.lfa.lfFaceName.ptr);
		return LOGFONTA.sizeof;
	}
}


Dstring shGetPathFromIDList(LPCITEMIDLIST pidl)
{
	static if(useUnicode)
	{
		version(STATIC_UNICODE)
		{
			alias proc = SHGetPathFromIDListW;
		}
		else
		{
			enum PATH_NAME = "SHGetPathFromIDListW";
			static SHGetPathFromIDListWProc pathproc = null;
			
			if(!pathproc)
			{
				HMODULE hmod;
				hmod = GetModuleHandleA("shell32.dll");
				
				pathproc = cast(SHGetPathFromIDListWProc)GetProcAddress(hmod, PATH_NAME.ptr);
				if(!pathproc)
					throw new Exception("Unable to load procedure " ~ PATH_NAME);
			}
		}
		wchar[] wbuf = new wchar[MAX_PATH];
		if (proc(pidl, wbuf.ptr) == FALSE)
			return null;
		return fromUnicodez(wbuf.ptr);
	}
	else
	{
		char[] abuf = new char[MAX_PATH];
		if (SHGetPathFromIDListA(pidl, abuf.ptr) == FALSE)
			return null;
		return fromAnsiz(abuf.ptr);
	}
}

