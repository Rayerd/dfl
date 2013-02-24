// Written by Christopher E. Miller
// See the included license.txt for copyright and license details.


// Not actually part of forms, but is handy.

///
module dfl.environment;

private import dfl.internal.dlib, dfl.internal.clib;

private import dfl.internal.winapi, dfl.base, dfl.internal.utf, dfl.event;


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
	EventHandler displaySettingsChanged;
	EventHandler installedFontsChanged;
	EventHandler lowMemory; // GC automatically collects before this event.
	EventHandler paletteChanged;
	//PowerModeChangedEventHandler powerModeChanged; // WM_POWERBROADCAST
	SystemEndedEventHandler systemEnded;
	SessionEndingEventHandler systemEnding;
	SessionEndingEventHandler sessionEnding;
	EventHandler timeChanged;
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
				result[result.length - 1] = args[startIndex .. i];
				findStart = true;
			}
			else //starting quote
			{
				if(startIndex != i) //must be a quote stuck to another word, separate them
				{
					result.length = result.length + 1;
					result[result.length - 1] = args[startIndex .. i];
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
				result[result.length - 1] = args[startIndex .. i];
				findStart = true;
			}
		}
	}
	
	if(startIndex != i)
	{
		result.length = result.length + 1;
		result[result.length - 1] = args[startIndex .. i];
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
	override Dstring toString()
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
		override Dstring toString()
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

