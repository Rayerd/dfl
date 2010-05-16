/*
	Copyright (C) 2005-2007, 2009 Christopher E. Miller
	
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


private import std.stdio, std.string, std.path, std.file,
	std.random, std.cstream, std.stream;
private import std.process;
private import std.c.stdlib;

private import dfl.all, dfl.internal.winapi, dfl.internal.utf;


private extern(Windows)
{
	DWORD GetLogicalDriveStringsA(DWORD nBufferLength,LPSTR lpBuffer);
	UINT GetDriveTypeA(LPCTSTR lpRootPathName);
	DWORD GetShortPathNameA(LPCSTR lpszLongPath, LPSTR lpszShortPath, DWORD cchBuffer);
	
	
	enum: UINT
	{
		DRIVE_FIXED = 3,
	}
	
	
	alias DWORD function(LPCWSTR lpszLongPath, LPWSTR lpszShortPath, DWORD cchBuffer) GetShortPathNameWProc;
}


enum Flags: DWORD
{
	NONE = 0,
	
	INSTALLED = 1, // Everything is setup.
}


RegistryKey rkey;
Flags flags = Flags.NONE;
char[] startpath, basepath;
char[] dmdpath, dmdpath_windows = "\0";
char[] libfile = "dfl_debug.lib";
bool isPrepared = false;
bool isDebug = true;
bool debugSpecified = false;
char[] dlibname; // Read from sc.ini

char[] optExet = "nt"; // Exe type.
char[] optSu = "console:4.0"; // Subsystem.
bool optForceInstall = false;
bool optBuild = false; // Build dfl.lib.
bool optShowVer = false;
bool optNoVer = false;
bool alreadyBuilt = false;
bool optTangobos = false;
bool optTango = false;
bool optPhobos = false;
bool optNoDflc = false; // Don't compile dflc_ bat files.


bool isValidDmdDir(char[] dir)
{
	if(std.path.isabs(dir)
		&& (std.file.exists(std.path.join(dir, "bin\\dmd.exe"))
			|| std.file.exists(std.path.join(dir, "windows\\bin\\dmd.exe")))
		)
		return true;
	return false;
}


void install()
{
	char[] s;
	
	bool mboxdmdpath(char[] xpath)
	{
		switch(msgBox("Found DMD at '" ~ xpath ~ "'.\r\n"
			"Would you like to use this path?\r\n\r\n"
			"Press No to keep looking.\r\n"
			"Press Cancel to abort and try again later.",
			"DFL", MsgBoxButtons.YES_NO_CANCEL, MsgBoxIcon.QUESTION))
		{
			case DialogResult.YES: return true;
			case DialogResult.NO: return false;
			default: exit(0);
		}
		return false;
	}
	
	/+
	switch(msgBox("Would you like to install DFL now?",
		"DFL", MsgBoxButtons.YES_NO, MsgBoxIcon.QUESTION))
	{
		case DialogResult.YES:
			break;
		
		default:
			exit(0);
	}
	+/
	
	if(dmdpath.length)
	{
		if(!isValidDmdDir(dmdpath))
			goto locate_dmd;
		
		if(optForceInstall)
		{
			if(!mboxdmdpath(dmdpath))
				goto locate_dmd;
		}
		
		//rkey.setValue("dmdpath", dmdpath);
		rkey.deleteValue("dmdpath", false); // Since it's the base dir, it is inferred.
	}
	else
	{
		locate_dmd:
		
		writefln("Locating DMD...");
		
		char[128] drives;
		if(GetLogicalDriveStringsA(drives.length, drives.ptr))
		{
			char* p;
			for(p = drives.ptr; *p; p++)
			{
				if(GetDriveTypeA(p) == DRIVE_FIXED) // Only check fixed disks.
				{
					s = std.path.join(.toString(p), "dmd");
					if(std.file.exists(s))
					{
						if(isValidDmdDir(s))
						{
							if(mboxdmdpath(s))
							{
								rkey.setValue("dmdpath", s);
								goto found_dmd;
							}
						}
						else
						{
							writefln("Found '%s' but no bin and lib directories...", s);
						}
					}
				}
				
				for(; *p; p++)
				{
				}
			}
		}
		
		// Didn't find DMD yet, so ask where it is.
		FolderBrowserDialog fbd;
		fbd = new typeof(fbd);
		fbd.description = "Please locate DMD.";
		browse_dmd_again:
		if(fbd.showDialog() != DialogResult.OK)
			exit(0); // Aborted.
		if(!isValidDmdDir(fbd.selectedPath))
		{
			fbd.description = "DMD was not found at that location. Please try again.";
			goto browse_dmd_again;
		}
		rkey.setValue("dmdpath", fbd.selectedPath);
	}
	
	found_dmd:
	
	flags |= Flags.INSTALLED;
	rkey.setValue("flags", cast(DWORD)flags);
	
	writef("Installation complete.\r\n\r\n");
}


void prepare()
{
	if(isPrepared)
		return;
	isPrepared = true;
	
	RegistryValueDword regDword;
	RegistryValueSz regSz;
	
	if(isValidDmdDir(basepath))
		dmdpath = basepath;
	
	regDword = cast(RegistryValueDword)rkey.getValue("flags");
	if(regDword)
		flags = cast(Flags)regDword.value;
	
	if(optForceInstall || !(flags & Flags.INSTALLED))
		install();
	
	
	void badInstall()
	{
		writefln("Bad install. To reinstall, use   dfl -dfl-i");
		exit(5);
	}
	
	
	//if(!dmdpath.length)
	if(!optForceInstall)
	{
		regSz = cast(RegistryValueSz)rkey.getValue("dmdpath");
		if(regSz && isValidDmdDir(regSz.value))
		{
			if(!dmdpath.length || isValidDmdDir(regSz.value))
				dmdpath = regSz.value;
		}
		else
		{
			if(!dmdpath.length)
				badInstall();
		}
	}
	
	dmdpath_windows = dmdpath;
	{
		char[] dpw = std.path.join(dmdpath, "windows");
		if(std.file.exists(dpw) && std.file.isdir(dpw))
		{
			dmdpath_windows = dpw;
		}
	}
}


// Returns true if it's actually a DFL switch.
// The "-dfl-" part must be stripped.
bool doDflSwitch(char[] arg)
{
	int i;
	char[] equ = null;
	
	i = std.string.find(arg, '=');
	if(i != -1)
	{
		equ = arg[i + 1 .. arg.length];
		arg = arg[0 .. i];
	}
	
	
	void oops(char[] equName = "value")
	{
		writefln("Expected %s=<%s>", arg, equName);
		exit(2);
	}
	
	
	switch(arg)
	{
		case "dmd":
			prepare();
			std.process.system(quotearg(std.path.join(dmdpath_windows, "bin\\dmd.exe\"")));
			exit(0);
		
		case "gui", "winexe", "windowed":
			i = std.string.find(optSu, ':');
			optSu = "windows:" ~ optSu[i + 1 .. optSu.length];
			break;
		
		case "con", "console", "exe":
			i = std.string.find(optSu, ':');
			optSu = "console:" ~ optSu[i + 1 .. optSu.length];
			break;
		
		case "i":
			optForceInstall = true;
			break;
		
		case "nodflc", "no-dflc":
			optNoDflc = true;
			break;
		
		case "dflc":
			if(optNoDflc)
				throw new Exception("Both switches nodflc and dflc specified");
			optNoDflc = false;
			break;
		
		/+
		case "h", "help", "?":
			showUsage();
			exit(0);
			break;
		+/
		
		case "exet", "exetype":
			if(equ.length)
			{
				optExet = equ;
			}
			else
			{
				oops();
			}
			break;
		
		case "su", "subsystem":
			if(equ.length > 3 && std.string.find(equ, ':') != -1)
			{
				optSu = equ;
			}
			else
			{
				oops("name:version");
			}
			break;
		
		case "doc":
			arg = std.path.join(basepath, "packages\\dfl\\doc\\index.html");
			if(!std.file.exists(arg))
				throw new Exception("'" ~ arg ~ "' not found");
			ShellExecuteA(null, null, std.string.toStringz(quotearg(arg)), null, null, 0);
			exit(0);
		
		case "readme":
			arg = std.path.join(basepath, "packages\\dfl\\readme.txt");
			if(!std.file.exists(arg))
				throw new Exception("'" ~ arg ~ "' not found");
			ShellExecuteA(null, null, std.string.toStringz(quotearg(arg)), null, null, SW_SHOWNORMAL);
			exit(0);
		
		case "tips":
			arg = std.path.join(basepath, "packages\\dfl\\tips.txt");
			if(!std.file.exists(arg))
				throw new Exception("'" ~ arg ~ "' not found");
			ShellExecuteA(null, null, std.string.toStringz(quotearg(arg)), null, null, SW_SHOWNORMAL);
			exit(0);
		
		case "examples", "samples", "eg", "ex":
			arg = std.path.join(basepath, "packages\\dfl\\examples");
			if(!std.file.exists(arg))
				throw new Exception("'" ~ arg ~ "' not found");
			ShellExecuteA(null, "explore", std.string.toStringz(quotearg(arg)), null, null, SW_SHOWNORMAL);
			exit(0);
		
		case "release":
			if(debugSpecified)
				throw new Exception("-release specified with -debug");
			libfile = "dfl.lib";
			isDebug = false;
			return false;
		
		case "debug":
			if(!isDebug)
				throw new Exception("-debug specified with -release");
			debugSpecified = true;
			return false;
		
		case "ver":
			optShowVer = true;
			return true;
		
		case "nover":
			optNoVer = true;
			return true;
		
		case "tangobos", "Tangobos":
			if(optPhobos)
				throw new Exception("-phobos specified with -tangobos");
			optTangobos = true;
			return true;
		
		case "phobos", "Phobos":
			if(optTango)
				throw new Exception("-tango specified with -phobos");
			if(optTangobos)
				throw new Exception("-tangobos specified with -phobos");
			optPhobos = true;
			return true;
		
		case "tango", "Tango":
			if(optPhobos)
				throw new Exception("-phobos specified with -tango");
			optTango = true;
			return true;
		
		default:
			return false;
	}
	
	return true;
}


void showUsage()
{
	writefln("DFL written by Christopher E. Miller");
	writef("Usage:\n"
		"   dfl [<switches...>] <files...>\n\n");
	writef("Switches:\n"
		"   -dmd             Show DMD's usage.\n"
		"   -dfl-ver         Show DFL version installed.\n"
		"   -dfl-nover       Do not perform version check.\n"
		"   -dfl-build       Build DFL lib files.\n"
		"   -dfl-nodflc      Do not run dflc batch files.\n"
		//"   -dfl-dflc        Run dflc batch files if building DFL lib files.\n"
		"   -dfl-readme      Open the DFL readme.txt file.\n"
		"   -dfl-doc         Open the DFL documentation.\n"
		"   -dfl-tips        Open the DFL tips.txt file.\n"
		"   -dfl-eg          Explore the DFL examples directory.\n"
		"   -dfl-gui         Make a Windows GUI exe without a console.\n"
		"   -dfl-con         Make a console exe (default).\n"
		"   -dfl-exet=<x>    Override executable type.\n"
		"   -dfl-su=<x1:x2>  Override subsystem name and version.\n"
		"   -dfl-i           Force install.\n"
		"   <other>          Any other non-dfl switches are passed to DMD.\n");
	writef("Files:\n"
		"   Files passed to DMD. File name wildcard expansion supported.\n");
}


char[] quotearg(char[] s)
{
	if(std.string.find(s, ' ') != -1)
		return `"` ~ s ~ `"`;
	return s;
}


char[][] quoteexpandwcfile(char[] s)
{
	char[][] result;
	if(s.length)
	{
		char[] wc, ppath;
		bool foundwc = false;
		size_t iw;
		for(iw = s.length - 1;; iw--)
		{
			if('\\' == s[iw] || '/' == s[iw] || ':' == s[iw])
			{
				if(foundwc)
				{
					wc = s[iw + 1 .. s.length];
					ppath = s[0 .. iw + 1];
					// Sanity check; make sure the rest of the path doesn't contain wildcards.
					for(--iw;; iw--)
					{
						if('*' == s[iw] || '?' == s[iw])
							throw new Exception("Unable to expand wildcard path '" ~ s ~ "'; directories cannot be wildcard expanded");
						if(!iw)
							break;
					}
					break;
				}
				result ~= quotearg(s);
				return result;
			}
			if('*' == s[iw] || '?' == s[iw])
				foundwc = true;
			if(!iw)
			{
				if(foundwc)
				{
					wc = s;
					//ppath = null;
					break;
				}
				result ~= quotearg(s);
				return result;
			}
		}
		
		assert(wc.length);
		
		if(ppath.length)
		{
			if(!std.file.exists(ppath))
			{
				result ~= quotearg(s); // ?
				return result;
			}
			
			if(!std.file.isdir(ppath))
			{
				throw new Exception("Unable to expand wildcard path '" ~ s ~ "'");
			}
		}
		
		// This version of listdir is not recursive.
		listdir(ppath,
			(DirEntry* de)
			{
				if(de.isfile)
				{
					char[] sf;
					size_t iwsf;
					sf = de.name;
					if(std.path.fnmatch(sf, wc)) // Note: also does [] stuff.
					{
						result ~= quotearg(sf);
					}
				}
				return true; // Continue listing.
			});
	}
	return result;
}


char[] getshortpath(char[] fn)
{
	if(dfl.internal.utf.useUnicode)
	{
		version(STATIC_UNICODE)
		{
			alias GetShortPathNameW proc;
		}
		else
		{
			const char[] NAME = "GetShortPathNameW";
			static GetShortPathNameWProc proc = null;
			
			if(!proc)
			{
				proc = cast(GetShortPathNameWProc)GetProcAddress(GetModuleHandleA("kernel32.dll"), NAME.ptr);
				if(!proc)
					throw new Exception("GetShortPathNameW not found");
			}
		}
		
		DWORD len;
		wchar[] s;
		s = new wchar[MAX_PATH];
		len = proc(dfl.internal.utf.toUnicodez(fn), s.ptr, s.length);
		return fromUnicode(s.ptr, len);
	}
	else
	{
		DWORD len;
		char[] s;
		s = new char[MAX_PATH];
		len = GetShortPathNameA(dfl.internal.utf.toAnsiz(fn), s.ptr, s.length);
		return fromAnsi(s.ptr, len);
	}
}


char[] getParentDir(char[] dir)
{
	int i;
	
	for(;;)
	{
		if(!dir.length)
			return null;
		if(dir[dir.length - 1] == '/' || dir[dir.length - 1] == '\\')
			dir = dir[0 .. dir.length - 1];
		else
			break;
	}
	char[] result = null;
	for(i = dir.length - 1;;)
	{
		if(dir[i] == '/' || dir[i] == '\\')
		{
			result = dir[0 .. i];
			break;
		}
		if(!--i)
			break;
	}
	return result;
}


int main(/+ char[][] args +/)
{
	startpath = getshortpath(Application.startupPath);
	basepath = getParentDir(startpath);
	{
		while(basepath.length > 0
			&& ('\\' == basepath[basepath.length - 1]
				|| '/' == basepath[basepath.length - 1])
			)
		{
			basepath = basepath[0 .. basepath.length - 1];
		}
		char[] platformdirname = "windows";
		if(basepath.length > platformdirname.length
			&& ('\\' == basepath[basepath.length - 1 - platformdirname.length]
				|| '/' == basepath[basepath.length - 1 - platformdirname.length])
			&& (0 == std.string.icmp(platformdirname,
				basepath[basepath.length - platformdirname.length .. basepath.length]))
			)
		{
			basepath = getParentDir(basepath);
		}
	}
	rkey = Registry.currentUser.createSubKey("Software\\DFL");
	
	bool gotargfn = false;
	char[][] dmdargs = null;
	int i;
	
	char[][] args;
	args = Environment.getCommandLineArgs();
	
	if(args.length > 1
		&& args[1] == "-dfl-bp")
	{
		writefln("basepath = %s", basepath);
		return 0;
	}
	
	if(args.length > 1)
	{
		foreach(char[] _origarg; args[1 .. args.length])
		{
			if(_origarg.length && (_origarg[0] == '-' || _origarg[0] == '/'))
			{
				char[] arg;
				arg = _origarg[1 .. _origarg.length];
				i = std.string.find(arg, '-');
				
				if(i == -1)
					goto regular_switch;
				
				switch(arg[0 .. i])
				{
					case "dfl":
						if(!doDflSwitch(arg[i + 1 .. arg.length]))
						{
							if("build" == arg[i + 1 .. arg.length])
							{
								optBuild = true;
							}
							else
							{
								writefln("Unrecognized DFL switch '-%s'", arg);
								return 1;
							}
						}
						break;
					
					case "dmd":
						dmdargs ~= "-" ~ quotearg(arg[i + 1 .. arg.length]);
						break;
					
					default: regular_switch:
						if(!doDflSwitch(arg))
							dmdargs ~= quotearg(_origarg);
				}
			}
			else
			{
				gotargfn = true;
				dmdargs ~= quoteexpandwcfile(_origarg);
			}
		}
		
		prepare();
		
		
		char[] dfllib;
		char[] importdir;
		
		
		void findimportdir()
		{
			if(!importdir.length)
			{
				importdir = std.path.join(basepath, "import");
				if(!std.file.exists(importdir) || !std.file.exists(std.path.join(importdir, "dfl")))
				{
					importdir = std.path.join(dmdpath, "import");
					if(!std.file.exists(importdir) || !std.file.exists(std.path.join(importdir, "dfl")))
					{
						importdir = std.path.join(dmdpath_windows, "import");
						if(!std.file.exists(importdir) || !std.file.exists(std.path.join(importdir, "dfl")))
						{
							importdir = std.path.join(dmdpath, "src");
							if(!std.file.exists(importdir) || !std.file.exists(std.path.join(importdir, "dfl")))
							{
								importdir = std.path.join(dmdpath, "src\\phobos");
								if(!std.file.exists(importdir) || !std.file.exists(std.path.join(importdir, "dfl")))
								{
									importdir = null;
									throw new Exception("DFL import directory not found");
								}
							}
						}
					}
				}
				
				/+
				if(!optTangobos)
				{
					if(std.file.exists(std.path.join(importdir, "tangobos")))
					{
						writefln("Tangobos detected; use switch -tangobos to use Tangobos.");
					}
				}
				+/
			}
		}
		
		
		void finddlibname()
		{
			if(dlibname.length)
				return;
			
			if(optPhobos)
			{
				dlibname = "Phobos";
				return;
			}
			
			if(optTangobos)
			{
				dlibname = "Tango+Tangobos";
				return;
			}
			
			if(optTango)
			{
				dlibname = "Tango";
				return;
			}
			
			// Autodetect...
			
			dlibname = "Phobos";
			try
			{
				char[] scx = cast(char[])std.file.read(std.path.join(basepath, "bin\\sc.ini"));
				if(-1 != std.string.find(scx, "-version=Tango"))
					dlibname = "Tango";
			}
			catch
			{
			}
		}
		
		
		void buildDflLibs()
		{
			if(alreadyBuilt)
				return;
			alreadyBuilt = true;
			
			findimportdir();
			
			char[] dflsrcdir = std.path.join(importdir, "dfl");
			char[] batfilepath = std.path.join(dflsrcdir, "_dflexe.bat");
			
			char[] dmcpathbefore, dmcpathafter;
			char[] dmcpath;
			if(std.file.exists(std.path.join(dmdpath_windows, "bin\\link.exe"))
				&& std.file.exists(std.path.join(dmdpath_windows, "bin\\lib.exe")))
			{
				dmcpath = dmdpath;
			}
			else
			{
				dmcpath = std.path.join(dmdpath, "..\\dm");
			}
			if(std.file.exists(dmcpath))
			{
				dmcpathbefore =
					"\r\n   @set _old_dmc_path=%dmc_path%"
					"\r\n   @set dmc_path=" ~ dmcpath
					;
				dmcpathafter =
					"\r\n   @set dmc_path=%_old_dmc_path%"
					;
			}
			
			char[] oldcwd = getcwd();
			char[] olddrive = std.path.getDrive(oldcwd);
			
			char[][] dflcs;
			if(!optNoDflc)
				//dflcs = listdir(dflsrcdir, "dflc_*.bat"); // Not working.
				listdir(dflsrcdir, (char[] filename) { if(fnmatch(filename, "dflc_*.bat")) dflcs ~= filename; return true; });
			
			//@
			scope batf = new BufferedFile(batfilepath, FileMode.OutNew);
			
			batf.writeString(
				"\r\n   @" ~ std.path.getDrive(dflsrcdir)
				~ "\r\n   @cd \"" ~ dflsrcdir ~ "\"");
			
			batf.writeString(
				"\r\n   @set _old_dmd_path=%dmd_path%"
				"\r\n   @set dmd_path=" ~ dmdpath
				~"\r\n   @set _old_dmd_path_windows=%dmd_path_windows%"
				"\r\n   @set dmd_path_windows=" ~ dmdpath_windows
				
				);
			
			batf.writeString(dmcpathbefore);
			
			batf.writeString(
				"\r\n   @set _old_dlib=%dlib%"
				"\r\n   @set dlib=" ~ dlibname);
			
			batf.writeString(
				"\r\n   @set _old_dfl_go_move=%dfl_go_move%"
				"\r\n   @set dfl_go_move=1");
			
			batf.writeString("\r\n   @set dfl_failed=-1"); // Let makelib.bat unset this.
			
			//batf.writeString("\r\n   @call \"" ~ std.path.join(dflsrcdir, "go.bat") ~ "\"\r\n");
			batf.writeString("\r\n   @call \"" ~ std.path.join(dflsrcdir, "makelib.bat") ~ "\"\r\n");
			
			batf.writeString("\r\n" `@if not "%dfl_failed%" == "" goto fail`); // No longer using go.bat for this.
			
			if(dflcs.length)
			{
				batf.writeString("\r\n   @set _old_path=%path%");
				batf.writeString("\r\n   @set path=%dmd_path_windows%;%dmc_path%;%path%");
				batf.writeString("\r\n   @set dflc=true");
				
				foreach(dflc; dflcs)
				{
					auto ssd = dflc;
					if(ssd.length > 5 && 0 == std.string.icmp("dflc_", ssd[0 .. 5]))
						ssd = ssd[5 .. $];
					if(ssd.length > 4 && 0 == std.string.icmp(".bat", ssd[$ - 4 .. $]))
						ssd = ssd[0 .. $ - 4];
					if(0 == ssd.length)
						continue;
					ssd = std.string.toupper(ssd[0 .. 1]) ~ ssd[1 .. $];
					batf.writeString("\r\n   @echo.\r\n   @echo Setting up DFL " ~ ssd ~ "...");
					batf.writeString("\r\n   @call \"" ~ std.path.join(dflsrcdir, dflc) ~ "\"\r\n");
				}
				
				batf.writeString("\r\n   @set dflc=");
				batf.writeString("\r\n   @set path=%_old_path%");
			}
			
			batf.writeString("\r\n   @move /Y dfl*.lib %dmd_path_windows%\\lib > NUL"); // Important! no longer using go.bat for this.
			
			batf.writeString("\r\n:fail\r\n");
			
			batf.writeString(dmcpathafter);
			
			batf.writeString("\r\n   @set dlib=%_old_dlib%");
			
			batf.writeString("\r\n   @set dfl_go_move=%_old_dfl_go_move%");
			
			batf.writeString("\r\n   @set dmd_path=%_old_dmd_path%"
				"\r\n   @set dmd_path_windows=%_old_dmd_path_windows%");
			
			batf.writeString(
				"\r\n   @" ~ olddrive
				~ "\r\n   @cd \"" ~ oldcwd ~ "\"");
			
			batf.writeString("\r\n");
			
			batf.close();
			
			std.process.system(batfilepath);
			
			std.file.remove(batfilepath);
		}
		
		
		bool askBuildDflNow()
		{
			if(alreadyBuilt)
				return false;
			
			writef("Would you like to build the DFL lib files now? [Y/n] ");
			char userc = 'y';
			for(;;)
			{
				char[] s = std.string.tolower(din.readLine());
				if((!s.length && 'y' == userc)
					|| "y" == s || "yes" == s)
				{
					userc = 'y';
					break;
				}
				if("no" == s || "n" == s)
				{
					userc = 'n';
					break;
				}
				userc = ' ';
				writef("[y/n] ");
			}
			if('y' == userc)
			{
				buildDflLibs();
				return true;
			}
			alreadyBuilt = true; // ? stop asking...
			return false;
		}
		
		
		void findlibdir()
		{
			try_lib_again:
			if(!dfllib.length)
			{
				//dfllib = std.path.join(basepath, "lib\\" ~ libfile);
				//if(!std.file.exists(dfllib))
				{
					dfllib = std.path.join(dmdpath_windows, "lib\\" ~ libfile);
					if(!std.file.exists(dfllib))
					{
						dfllib = null;
						writefln("DFL lib files not found.");
						if(askBuildDflNow())
							goto try_lib_again;
						throw new Exception(libfile ~ " not found");
					}
				}
			}
		}
		
		
		void findpaths()
		{
			findlibdir();
			findimportdir();
		}
		
		
		// Version number returned; fullver filled with entire version string.
		char[] scanDmdOut(char[] data, out char[] fullver)
		{
			char[] xver, x2, result;
			int ix;
			const char[] FINDDMDVER = "Digital Mars D Compiler v";
			ix = std.string.find(data, FINDDMDVER);
			if(-1 != ix && (!ix || '\n' == data[ix - 1]))
			{
				x2 = data[ix + FINDDMDVER.length .. data.length];
				xver = data[ix .. data.length];
				for(ix = 0;; ix++)
				{
					if(ix == xver.length || '\r' == xver[ix] || '\n' == xver[ix])
					{
						xver = xver[0 .. ix];
						break;
					}
				}
				fullver = std.string.strip(xver);
				
				xver = x2;
				for(ix = 0;; ix++)
				{
					if(ix == xver.length || ' ' == xver[ix] || '\r' == xver[ix] || '\n' == xver[ix])
						break;
				}
				result = std.string.strip(xver[0 .. ix]);
			}
			return result;
		}
		
		
		void doVerCheck(bool vcVerbose = false, bool vcPrintIssues = true)
		{
			findpaths();
			finddlibname();
			
			if(vcVerbose)
				writefln("Using %s library", dlibname);
			
			char[] x, x2, xver;
			int ix;
			
			//x = cast(char[])std.file.read(std.path.join(importdir, r"dfl\readme.txt"));
			x = cast(char[])std.file.read(std.path.join(basepath, "packages\\dfl\\readme.txt"));
			
			const char[] FINDDFLVER = "\nVersion ";
			ix = std.string.find(x, FINDDFLVER);
			if(-1 == ix)
			{
				bad_readme_ver:
				throw new Exception("Unable to find version information from readme.txt");
			}
			xver = x[ix + FINDDFLVER.length .. x.length];
			for(ix = 0;; ix++)
			{
				if(ix == xver.length || '\r' == xver[ix] || '\n' == xver[ix])
				{
					xver = xver[0 .. ix];
					break;
				}
			}
			ix = std.string.find(xver, " by Christopher E. Miller");
			if(-1 == ix)
				goto bad_readme_ver;
			xver = std.string.strip(xver[0 .. ix]); // DFL version.
			if(vcVerbose)
				writefln("DFL version %s", xver);
			
			char[] dmdverdfl;
			const char[] FINDTESTEDDMDVER = "\nTested with DMD v";
			ix = std.string.find(x, FINDTESTEDDMDVER);
			if(-1 == ix)
			{
				//goto bad_readme_ver;
			}
			else
			{
				x2 = x[ix + FINDTESTEDDMDVER.length .. x.length];
				xver = x[ix + 1 .. x.length];
				for(ix = 0;; ix++)
				{
					if(ix == xver.length || '\r' == xver[ix] || '\n' == xver[ix])
					{
						xver = xver[0 .. ix];
						break;
					}
				}
				xver = std.string.strip(xver);
				if(vcVerbose)
					writefln("%s", xver);
				
				xver = x2;
				for(ix = 0;; ix++)
				{
					if(ix == xver.length || ' ' == xver[ix] || '\r' == xver[ix] || '\n' == xver[ix])
						break;
				}
				dmdverdfl = std.string.strip(xver[0 .. ix]);
				if(ix && '.' == xver[ix - 1])
					dmdverdfl = xver[0 .. ix - 1];
			}
			
			char[] dfllibdmdver;
			char[] dfllibdlibname = "Phobos";
			try
			{
				x = cast(char[])std.file.read(std.path.join(importdir, r"dfl\dflcompile.info"));
				
				dfllibdmdver = scanDmdOut(x, xver);
				if(dfllibdmdver.length)
				{
					if(vcVerbose)
						writefln("DFL lib files compiled with %s", xver);
				}
				
				int fli = std.string.find(x, '\n');
				if(-1 != fli)
				{
					char[] flx = std.string.strip(x[0 .. fli]);
					if(flx.length > 5 && flx[0 .. 5] == "dlib=")
					{
						dfllibdlibname = flx[5 .. $];
					}
				}
			}
			catch
			{
			}
			
			char[] dmdver;
			x2 = "dmd" ~ std.string.toString(std.random.rand() % 20000 + 10000) ~ ".info";
			std.process.system(getshortpath(std.path.join(dmdpath_windows, "bin\\dmd.exe"))
				~ " > " ~ x2);
			x = cast(char[])std.file.read(x2);
			std.file.remove(x2);
			dmdver = scanDmdOut(x, xver);
			if(dmdver.length)
			{
				if(vcVerbose)
					writefln("Installed compiler is %s", xver);
			}
			
			if(vcPrintIssues)
			{
				if(!dmdver.length || !dfllibdmdver.length)
				{
					writefln("*** Warning: Unable to verify if current DFL and DMD versions are compatible.");
					askBuildDflNow();
				}
				else
				{
					if(dfllibdmdver != dmdver
						|| std.string.icmp(dfllibdlibname, dlibname))
					{
						/+
						writefln("*** Warning: DFL lib files were not compiled with the current DMD compiler."
							"\nIt is recommended to go to www.dprogramming.com and look for a DFL update"
							"\nor rebuild the DFL lib files to ensure binary compatibility when linking."
							/+ "\n (-nover skips this check) " +/);
						std.process.system("pause");
						+/
						writefln("*** Warning: DFL lib files were not compiled with the current DMD compiler."
							"\nIt is recommended you rebuild the DFL lib files to ensure binary compatibility,"
							"\nor go to www.dprogramming.com and look for a possible DFL update."
							/+ "\n (-nover skips this check) " +/);
						askBuildDflNow();
					}
				}
			}
		}
		
		
		if(optShowVer)
		{
			if(optNoVer)
			{
				throw new Exception("Conflicting switches: -ver -nover");
			}
			else
			{
				doVerCheck(true);
			}
		}
		
		finddlibname();
		
		if(optBuild)
			buildDflLibs();
		
		if(!dmdargs.length)
		{
			if(gotargfn)
				throw new Exception("No files found");
			
			if(!optShowVer && !optForceInstall && !optBuild)
			{
				showUsage();
			}
		}
		else
		{
			findpaths();
			
			if(optNoVer)
			{
				writefln("Bypassing version check");
			}
			else if(!optShowVer)
			{
				try
				{
					doVerCheck();
				}
				catch
				{
					writefln("Error checking versions; use switch -ver for details");
				}
			}
			
			dmdargs ~= "-version=DFL_EXE";
			
			if(optTangobos)
				dmdargs ~= "-version=Tangobos";
			
			if(optTango)
				dmdargs ~= "-version=Tango";
			
			if(isDebug && !debugSpecified)
			{
				//writefln("Compiling in debug mode; use -release to compile in release mode");
				writefln("Compiling in debug mode for testing; use -release to compile in release mode");
				dmdargs ~= "-debug";
			}
			else if(!isDebug)
			{
				writefln("Compiling in release mode; safety checks removed");
			}
			if(!optTangobos && "Tango" != dlibname) // Tango's std and Tangobos' std conflict; Tango automatically has this -I anyway.
				dmdargs ~= "-I" ~ getshortpath(importdir);
			dmdargs ~= "-L/exet:" ~ optExet ~ "/su:" ~ optSu;
			dmdargs ~= getshortpath(dfllib);
			
			// Call DMD.
			assert(dmdpath_windows.length);
			char[] cmdline;
			int sc;
			cmdline = getshortpath(std.path.join(dmdpath_windows, "bin\\dmd.exe")) ~ " " ~ std.string.join(dmdargs, " ");
			writefln("%s", cmdline);
			sc = std.process.system(cmdline);
			if(sc)
				writef("\nReturned status code %d\n", sc);
		}
	}
	else
	{
		prepare();
		showUsage();
	}
	
	return 0;
}

