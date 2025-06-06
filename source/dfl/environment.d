// Written by Christopher E. Miller
// See the included license.txt for copyright and license details.


// Not actually part of forms, but is handy.

///
module dfl.environment;

import dfl.base;
import dfl.event;

import dfl.internal.dlib;
import dfl.internal.clib;
import dfl.internal.utf;
import dfl.internal.winapi;


private extern(Windows) nothrow
{
	alias SHGetPathFromIDListWProc = BOOL function(LPCITEMIDLIST pidl, LPWSTR pszPath);
}


///
final class Environment // docmain
{
	private this() {}
	
	
	static:
	
	///
	@property Dstring commandLine() // getter
	{
		return dfl.internal.utf.getCommandLine();
	}
	
	
	///
	@property void currentDirectory(Dstring cd) // setter
	{
		if(!dfl.internal.utf.setCurrentDirectory(cd))
			throw new DflException("Unable to set current directory");
	}
	
	/// ditto
	@property Dstring currentDirectory() // getter
	{
		return dfl.internal.utf.getCurrentDirectory();
	}
	
	
	///
	@property Dstring machineName() // getter
	{
		Dstring result;
		result = dfl.internal.utf.getComputerName();
		if(!result.length)
			throw new DflException("Unable to obtain machine name");
		return result;
	}
	
	
	///
	@property Dstring newLine() // getter
	{
		return nativeLineSeparatorString;
	}
	
	
	///
	@property OperatingSystem osVersion() // getter
	{
		OSVERSIONINFOA osi;
		Version ver;
		
		osi.dwOSVersionInfoSize = osi.sizeof;
		if(!GetVersionExA(&osi))
			throw new DflException("Unable to obtain operating system version information");
		
		int build;
		
		switch(osi.dwPlatformId)
		{
			case VER_PLATFORM_WIN32_NT:
				ver = new Version(osi.dwMajorVersion, osi.dwMinorVersion, osi.dwBuildNumber);
				break;
			
			case VER_PLATFORM_WIN32_WINDOWS:
				ver = new Version(osi.dwMajorVersion, osi.dwMinorVersion, LOWORD(osi.dwBuildNumber));
				break;
			
			default:
				ver = new Version(osi.dwMajorVersion, osi.dwMinorVersion);
		}
		
		return new OperatingSystem(cast(PlatformId)osi.dwPlatformId, ver);
	}
	
	
	///
	@property Dstring systemDirectory() // getter
	{
		Dstring result;
		result = dfl.internal.utf.getSystemDirectory();
		if(!result.length)
			throw new DflException("Unable to obtain system directory");
		return result;
	}
	
	
	// Should return int ?
	@property DWORD tickCount() // getter
	{
		return GetTickCount();
	}
	
	
	///
	@property Dstring userName() // getter
	{
		Dstring result;
		result = dfl.internal.utf.getUserName();
		if(!result.length)
			throw new DflException("Unable to obtain user name");
		return result;
	}
	
	
	///
	void exit(int code)
	{
		// This is probably better than ExitProcess(code).
		dfl.internal.clib.exit(code);
	}
	
	
	///
	Dstring expandEnvironmentVariables(Dstring str)
	{
		if(!str.length)
		{
			return str;
		}
		Dstring result;
		if(!dfl.internal.utf.expandEnvironmentStrings(str, result))
			throw new DflException("Unable to expand environment variables");
		return result;
	}
	
	
	///
	Dstring[] getCommandLineArgs()
	{
		return parseArgs(commandLine);
	}
	
	
	///
	Dstring getEnvironmentVariable(Dstring name, bool throwIfMissing)
	{
		Dstring result;
		result = dfl.internal.utf.getEnvironmentVariable(name);
		if(!result.length)
		{
			if(!throwIfMissing)
			{
				if(GetLastError() == 203) // ERROR_ENVVAR_NOT_FOUND
					return null;
			}
			throw new DflException("Unable to obtain environment variable");
		}
		return result;
	}
	
	/// ditto
	Dstring getEnvironmentVariable(Dstring name)
	{
		return getEnvironmentVariable(name, true);
	}
	
	
	//Dstring[Dstring] getEnvironmentVariables()
	//Dstring[] getEnvironmentVariables()
	
	
	///
	Dstring[] getLogicalDrives()
	{
		DWORD dr = GetLogicalDrives();
		Dstring[] result;
		int i;
		char[4] tmp = " :\\\0";
		
		for(i = 0; dr; i++)
		{
			if(dr & 1)
			{
				char[] s = tmp.dup[0 .. 3];
				s[0] = cast(char)('A' + i);
				//result ~= s;
				result ~= cast(Dstring)s; // Needed in D2.
			}
			dr >>= 1;
		}
		
		return result;
	}
	
	
	///
	Dstring getFolderPath(SpecialFolder folder)
	{
		LPITEMIDLIST idlist;
		if (SHGetSpecialFolderLocation(null, cast(int)folder, &idlist) != S_OK)
			idlist = null;
		scope(exit)
		{
			if (idlist)
				CoTaskMemFree(idlist);
		}

		Dstring path;
		path = shGetPathFromIDList(idlist);
		if (!path)
		{
			throw new DflException("Unable to obtain path");
			assert(0);
		}
		return path;
	}
	
	
	///
	enum SpecialFolder
	{
		DESKTOP = 0,
		PROGRAMS = 2,
		MY_DOCUMENTS = 5, // == Personal
		PERSONAL = 5, // == MyDocuments
		FAVORITES = 6,
		STARTUP = 7,
		RECENT = 8,
		SEND_TO = 9,
		START_MENU = 11,
		MY_MUSIC = 13,
		MY_VIDEOS = 14,
		DESKTOP_DIRECTORY = 16,
		MY_COMPUTER = 17, // Environment.getFolderPath() returns "" always.
		NETWORK_SHORTCUTS = 19,
		FONTS = 20,
		TEMPLATES = 21,
		COMMON_START_MENU = 22,
		COMMON_PROGRAMS = 23,
		COMMON_STARTUP = 24,
		COMMON_DESKTOP_DIRECTORY = 25,
		APPLICATION_DATA = 26,
		PRINTER_SHORTCUTS = 27,
		LOCAL_APPLICATION_DATA = 28,
		INTERNET_CACHE = 32,
		COOKIES = 33,
		HISTORY = 34,
		COMMON_APPLICATION_DATA = 35,
		WINDOWS = 36, // == %windir% or $SYSTEMROOT%
		SYSTEM = 37,
		PROGRAM_FILES = 38,
		MY_PICTURES = 39,
		USERT_PROFILE = 40,
		SYSTEM_X86 = 41,
		PROGRAM_FILES_X86 = 42,
		COMMON_PROGRAM_FILES = 43,
		COMMON_PROGRAM_FILES_X86 = 44,
		COMMON_TEMPLATES = 45,
		COMMON_DOCUMENTS = 46,
		COMMON_ADMIN_TOOLS = 47,
		ADMIN_TOOLS = 48,
		COMMON_MUSIC = 53,
		COMMON_PICTURES = 54,
		COMMON_VIDEOS = 55,
		RESOURCES = 56,
		LOCALIZED_RESOURCES = 57,
		COMMON_OEM_LINKS = 58,
		CD_BURNING = 59,
	}
}


/+
enum PowerModes: ubyte
{
	STATUS_CHANGE,
	RESUME,
	SUSPEND,
}


class PowerModeChangedEventArgs: EventArgs
{
	this(PowerModes pm)
	{
		this._pm = pm;
	}
	
	
	@property final PowerModes mode() // getter
	{
		return _pm;
	}
	
	
	private:
	PowerModes _pm;
}
+/


/+
///
enum SessionEndReasons: ubyte
{
	SYSTEM_SHUTDOWN, ///
	LOGOFF, /// ditto
}


///
class SystemEndedEventArgs: EventArgs
{
	///
	this(SessionEndReasons reason)
	{
		this._reason = reason;
	}
	
	
	///
	final @property SessionEndReasons reason() // getter
	{
		return this._reason;
	}
	
	
	private:
	SessionEndReasons _reason;
}


///
class SessionEndingEventArgs: EventArgs
{
	///
	this(SessionEndReasons reason)
	{
		this._reason = reason;
	}
	
	
	///
	final @property SessionEndReasons reason() // getter
	{
		return this._reason;
	}
	
	
	///
	final @property void cancel(bool byes) // setter
	{
		this._cancel = byes;
	}
	
	/// ditto
	final @property bool cancel() // getter
	{
		return this._cancel;
	}
	
	
	private:
	SessionEndReasons _reason;
	bool _cancel = false;
}
+/


/+
final class SystemEvents // docmain
{
	private this() {}
	
	
	static:
	Event!(Object, EventArgs) displaySettingsChanged;
	Event!(Object, EventArgs) installedFontsChanged;
	Event!(Object, EventArgs) lowMemory; // GC automatically collects before this event.
	Event!(Object, EventArgs) paletteChanged;
	//Event!(Object, PowerModeChangedEventArgs) powerModeChanged; // WM_POWERBROADCAST
	Event!(Object, SystemEndedEventArgs) systemEnded;
	Event!(Object, SessionEndingEventArgs) systemEnding;
	Event!(Object, SessionEndingEventArgs) sessionEnding;
	Event!(Object, EventArgs) timeChanged;
	// user preference changing/changed. WM_SETTINGCHANGE ?
	
	
	/+
	@property void useOwnThread(bool byes) // setter
	{
		if(byes != useOwnThread)
		{
			if(byes)
			{
				_ownthread = new Thread;
				// idle priority..
			}
			else
			{
				// Kill thread.
			}
		}
	}
	
	
	@property bool useOwnThread() // getter
	{
		return _ownthread !is null;
	}
	+/
	
	
	private:
	//package Thread _ownthread = null;
	
	
	SessionEndReasons sessionEndReasonFromLparam(LPARAM lparam)
	{
		if(ENDSESSION_LOGOFF == lparam)
			return SessionEndReasons.LOGOFF;
		return SessionEndReasons.SYSTEM_SHUTDOWN;
	}
	
	
	void _realCheckMessage(ref Message m)
	{
		switch(m.msg)
		{
			case WM_DISPLAYCHANGE:
				displaySettingsChanged(typeid(SystemEvents), EventArgs.empty);
				break;
			
			case WM_FONTCHANGE:
				installedFontsChanged(typeid(SystemEvents), EventArgs.empty);
				break;
			
			case WM_COMPACTING:
				//gcFullCollect();
				lowMemory(typeid(SystemEvents), EventArgs.empty);
				break;
			
			case WM_PALETTECHANGED:
				paletteChanged(typeid(SystemEvents), EventArgs.empty);
				break;
			
			case WM_ENDSESSION:
				if(m.wParam)
				{
					scope SystemEndedEventArgs ea = new SystemEndedEventArgs(sessionEndReasonFromLparam(m.lParam));
					systemEnded(typeid(SystemEvents), ea);
				}
				break;
			
			case WM_QUERYENDSESSION:
				{
					scope SessionEndingEventArgs ea = new SessionEndingEventArgs(sessionEndReasonFromLparam(m.lParam));
					systemEnding(typeid(SystemEvents), ea);
					if(ea.cancel)
						m.result = FALSE; // Stop shutdown.
					m.result = TRUE; // Continue shutdown.
				}
				break;
			
			case WM_TIMECHANGE:
				timeChanged(typeid(SystemEvents), EventArgs.empty);
				break;
			
			default:
		}
	}
	
	
	package void _checkMessage(ref Message m)
	{
		//if(_ownthread)
			_realCheckMessage(m);
	}
}
+/


package Dstring[] parseArgs(Dstring args)
{
	Dstring[] result;
	uint i;
	bool inQuote = false;
	bool findStart = true;
	uint startIndex = 0;
	
	for(i = 0;; i++)
	{
		if(i == args.length)
		{
			if(findStart)
				startIndex = i;
			break;
		}
		
		if(findStart)
		{
			if(args[i] == ' ' || args[i] == '\t')
				continue;
			findStart = false;
			startIndex = i;
		}
		
		if(args[i] == '"')
		{
			inQuote = !inQuote;
			if(!inQuote) //matched quotes
			{
				result.length = result.length + 1;
				result[$ - 1] = args[startIndex .. i];
				findStart = true;
			}
			else //starting quote
			{
				if(startIndex != i) //must be a quote stuck to another word, separate them
				{
					result.length = result.length + 1;
					result[$ - 1] = args[startIndex .. i];
					startIndex = i + 1;
				}
				else
				{
					startIndex++; //exclude the quote
				}
			}
		}
		else if(!inQuote)
		{
			if(args[i] == ' ' || args[i] == '\t')
			{
				result.length = result.length + 1;
				result[$ - 1] = args[startIndex .. i];
				findStart = true;
			}
		}
	}
	
	if(startIndex != i)
	{
		result.length = result.length + 1;
		result[$ - 1] = args[startIndex .. i];
	}
	
	return result;
}


unittest
{
	Dstring[] args;
	
	args = parseArgs(`"foo" bar`);
	assert(args.length == 2);
	assert(args[0] == "foo");
	assert(args[1] == "bar");
	
	args = parseArgs(`"environment"`);
	assert(args.length == 1);
	assert(args[0] == "environment");
	
	/+
	writefln("commandLine = '%s'", Environment.commandLine);
	foreach(Dstring arg; Environment.getCommandLineArgs())
	{
		writefln("\t'%s'", arg);
	}
	+/
}


///
// Any version, not just the operating system.
class Version // docmain ?
{
	private:
	int _major = 0, _minor = 0;
	int _build = -1, _revision = -1;
	
	
	public:
	
	///
	this()
	{
	}
	
	
	final:
	
	/// ditto
	// A string containing "major.minor.build.revision".
	// 2 to 4 parts expected.
	this(Dstring str)
	{
		Dstring[] stuff = stringSplit(str, ".");
		
		switch(stuff.length)
		{
			case 4:
				_revision = stringToInt(stuff[3]);
				goto case 3;
			case 3:
				_build = stringToInt(stuff[2]);
				goto case 2;
			case 2:
				_minor = stringToInt(stuff[1]);
				_major = stringToInt(stuff[0]);
				break;
			default:
				throw new DflException("Invalid version parameter");
		}
	}
	
	/// ditto
	this(int major, int minor)
	{
		_major = major;
		_minor = minor;
	}
	
	/// ditto
	this(int major, int minor, int build)
	{
		_major = major;
		_minor = minor;
		_build = build;
	}
	
	/// ditto
	this(int major, int minor, int build, int revision)
	{
		_major = major;
		_minor = minor;
		_build = build;
		_revision = revision;
	}
	
	
	/+ // D2 doesn't like this without () but this invariant doesn't really even matter.
	invariant
	{
		assert(_major >= 0);
		assert(_minor >= 0);
		assert(_build >= -1);
		assert(_revision >= -1);
	}
	+/
	
	
	///
	override Dstring toString() const
	{
		Dstring result;
		
		result = intToString(_major) ~ "." ~ intToString(_minor);
		if(_build != -1)
			result ~= "." ~ intToString(_build);
		if(_revision != -1)
			result ~= "." ~ intToString(_revision);
		
		return result;
	}
	
	
	///
	@property int major() // getter
	{
		return _major;
	}
	
	/// ditto
	@property int minor() // getter
	{
		return _minor;
	}
	
	/// ditto
	// -1 if no build.
	@property int build() // getter
	{
		return _build;
	}
	
	/// ditto
	// -1 if no revision.
	@property int revision() // getter
	{
		return _revision;
	}
}


///
enum PlatformId: DWORD
{
	WIN_CE = cast(DWORD)-1,
	WIN32s = VER_PLATFORM_WIN32s,
	WIN32_WINDOWS = VER_PLATFORM_WIN32_WINDOWS,
	WIN32_NT = VER_PLATFORM_WIN32_NT,
}


///
final class OperatingSystem // docmain
{
	final
	{
		///
		this(PlatformId platId, Version ver)
		{
			this.platId = platId;
			this.vers = ver;
		}
		
		
		///
		override Dstring toString() const
		{
			Dstring result;
			
			// DMD 0.92 says error: cannot implicitly convert uint to PlatformId
			switch(cast(DWORD)platId)
			{
				case PlatformId.WIN32_NT:
					result = "Microsoft Windows NT ";
					break;
				
				case PlatformId.WIN32_WINDOWS:
					result = "Microsoft Windows 95 ";
					break;
				
				case PlatformId.WIN32s:
					result = "Microsoft Win32s ";
					break;
				
				case PlatformId.WIN_CE:
					result = "Microsoft Windows CE ";
					break;
				
				default:
					throw new DflException("Unknown platform ID");
			}
			
			result ~= vers.toString();
			return result;
		}
		
		
		///
		@property PlatformId platform() // getter
		{
			return platId;
		}
		
		
		///
		// Should be version() :p
		@property Version ver() // getter
		{
			return vers;
		}
	}
	
	
	private:
	PlatformId platId;
	Version vers;
}

