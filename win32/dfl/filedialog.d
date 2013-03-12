// Written by Christopher E. Miller
// See the included license.txt for copyright and license details.


///
module dfl.filedialog;

private import dfl.internal.dlib;

private import dfl.control, dfl.internal.winapi, dfl.base, dfl.drawing;
private import dfl.application, dfl.commondialog, dfl.event, dfl.internal.utf;


///
abstract class FileDialog: CommonDialog // docmain
{
	private this()
	{
		Application.ppin(cast(void*)this);
		
		ofn.lStructSize = ofn.sizeof;
		ofn.lCustData = cast(typeof(ofn.lCustData))cast(void*)this;
		ofn.Flags = INIT_FLAGS;
		ofn.nFilterIndex = INIT_FILTER_INDEX;
		initInstance();
		ofn.lpfnHook = cast(typeof(ofn.lpfnHook))&ofnHookProc;
	}
	
	
	override DialogResult showDialog()
	{
		return runDialog(GetActiveWindow()) ?
			DialogResult.OK : DialogResult.CANCEL;
	}
	
	override DialogResult showDialog(IWindow owner)
	{
		return runDialog(owner ? owner.handle : GetActiveWindow()) ?
			DialogResult.OK : DialogResult.CANCEL;
	}
	
	
	override void reset()
	{
		ofn.Flags = INIT_FLAGS;
		ofn.lpstrFilter = null;
		ofn.nFilterIndex = INIT_FILTER_INDEX;
		ofn.lpstrDefExt = null;
		_defext = null;
		_fileNames = null;
		needRebuildFiles = false;
		_filter = null;
		ofn.lpstrInitialDir = null;
		_initDir = null;
		ofn.lpstrTitle = null;
		_title = null;
		initInstance();
	}
	
	
	private void initInstance()
	{
		//ofn.hInstance = ?; // Should this be initialized?
	}
	
	
	/+
	final @property void addExtension(bool byes) // setter
	{
		addext = byes;
	}
	
	
	final @property bool addExtension() // getter
	{
		return addext;
	}
	+/
	
	
	///
	@property void checkFileExists(bool byes) // setter
	{
		if(byes)
			ofn.Flags |= OFN_FILEMUSTEXIST;
		else
			ofn.Flags &= ~OFN_FILEMUSTEXIST;
	}
	
	/// ditto
	@property bool checkFileExists() // getter
	{
		return (ofn.Flags & OFN_FILEMUSTEXIST) != 0;
	}
	
	
	///
	final @property void checkPathExists(bool byes) // setter
	{
		if(byes)
			ofn.Flags |= OFN_PATHMUSTEXIST;
		else
			ofn.Flags &= ~OFN_PATHMUSTEXIST;
	}
	
	/// ditto
	final @property bool checkPathExists() // getter
	{
		return (ofn.Flags & OFN_PATHMUSTEXIST) != 0;
	}
	
	
	///
	final @property void defaultExt(Dstring ext) // setter
	{
		if(!ext.length)
		{
			ofn.lpstrDefExt = null;
			_defext = null;
		}
		else
		{
			if(ext.length && ext[0] == '.')
				ext = ext[1 .. ext.length];
			
			if(dfl.internal.utf.useUnicode)
			{
				ofnw.lpstrDefExt = dfl.internal.utf.toUnicodez(ext);
			}
			else
			{
				ofna.lpstrDefExt = dfl.internal.utf.toAnsiz(ext);
			}
			_defext = ext;
		}
	}
	
	/// ditto
	final @property Dstring defaultExt() // getter
	{
		return _defext;
	}
	
	
	///
	final @property void dereferenceLinks(bool byes) // setter
	{
		if(byes)
			ofn.Flags &= ~OFN_NODEREFERENCELINKS;
		else
			ofn.Flags |= OFN_NODEREFERENCELINKS;
	}
	
	/// ditto
	final @property bool dereferenceLinks() // getter
	{
		return (ofn.Flags & OFN_NODEREFERENCELINKS) == 0;
	}
	
	
	///
	final @property void fileName(Dstring fn) // setter
	{
		// TODO: check if correct implementation.
		
		if(fn.length > MAX_PATH)
			throw new DflException("Invalid file name");
		
		if(fileNames.length)
		{
			_fileNames = (&fn)[0 .. 1] ~ _fileNames[1 .. _fileNames.length];
		}
		else
		{
			_fileNames = new Dstring[1];
			_fileNames[0] = fn;
		}
	}
	
	/// ditto
	final @property Dstring fileName() // getter
	{
		if(fileNames.length)
			return fileNames[0];
		return null;
	}
	
	
	///
	final @property Dstring[] fileNames() // getter
	{
		if(needRebuildFiles)
			populateFiles();
		
		return _fileNames;
	}
	
	
	///
	// The format string is like "Text files (*.txt)|*.txt|All files (*.*)|*.*".
	final @property void filter(Dstring filterString) // setter
	{
		if(!filterString.length)
		{
			ofn.lpstrFilter = null;
			_filter = null;
		}
		else
		{
			struct _Str
			{
				union
				{
					wchar[] sw;
					char[] sa;
				}
			}
			_Str str;
			
			size_t i, starti;
			size_t nitems = 0;
			
			if(dfl.internal.utf.useUnicode)
			{
				str.sw = new wchar[filterString.length + 2];
				str.sw = str.sw[0 .. 0];
			}
			else
			{
				str.sa = new char[filterString.length + 2];
				str.sa = str.sa[0 .. 0];
			}
			
			
			for(i = starti = 0; i != filterString.length; i++)
			{
				switch(filterString[i])
				{
					case '|':
						if(starti == i)
							goto bad_filter;
						
						if(dfl.internal.utf.useUnicode)
						{
							str.sw ~= dfl.internal.utf.toUnicode(filterString[starti .. i]);
							str.sw ~= "\0";
						}
						else
						{
							str.sa ~= dfl.internal.utf.unsafeAnsi(filterString[starti .. i]);
							str.sa ~= "\0";
						}
						
						starti = i + 1;
						nitems++;
						break;
					
					case 0:
					case '\r', '\n':
						goto bad_filter;
					
					default:
				}
			}
			if(starti == i || !(nitems % 2))
				goto bad_filter;
			if(dfl.internal.utf.useUnicode)
			{
				str.sw ~= dfl.internal.utf.toUnicode(filterString[starti .. i]);
				str.sw ~= "\0\0";
				
				ofnw.lpstrFilter = str.sw.ptr;
			}
			else
			{
				str.sa ~= dfl.internal.utf.unsafeAnsi(filterString[starti .. i]);
				str.sa ~= "\0\0";
				
				ofna.lpstrFilter = str.sa.ptr;
			}
			
			_filter = filterString;
			return;
			
			bad_filter:
			throw new DflException("Invalid file filter string");
		}
	}
	
	/// ditto
	final @property Dstring filter() // getter
	{
		return _filter;
	}
	
	
	///
	// Note: index is 1-based.
	final @property void filterIndex(int index) // setter
	{
		ofn.nFilterIndex = (index > 0) ? index : 1;
	}
	
	/// ditto
	final @property int filterIndex() // getter
	{
		return ofn.nFilterIndex;
	}
	
	
	///
	final @property void initialDirectory(Dstring dir) // setter
	{
		if(!dir.length)
		{
			ofn.lpstrInitialDir = null;
			_initDir = null;
		}
		else
		{
			if(dfl.internal.utf.useUnicode)
			{
				ofnw.lpstrInitialDir = dfl.internal.utf.toUnicodez(dir);
			}
			else
			{
				ofna.lpstrInitialDir = dfl.internal.utf.toAnsiz(dir);
			}
			_initDir = dir;
		}
	}
	
	/// ditto
	final @property Dstring initialDirectory() // getter
	{
		return _initDir;
	}
	
	
	// Should be instance(), but conflicts with D's old keyword.
	
	///
	protected @property void inst(HINSTANCE hinst) // setter
	{
		ofn.hInstance = hinst;
	}
	
	/// ditto
	protected @property HINSTANCE inst() // getter
	{
		return ofn.hInstance;
	}
	
	
	///
	protected @property DWORD options() // getter
	{
		return ofn.Flags;
	}
	
	
	///
	final @property void restoreDirectory(bool byes) // setter
	{
		if(byes)
			ofn.Flags |= OFN_NOCHANGEDIR;
		else
			ofn.Flags &= ~OFN_NOCHANGEDIR;
	}
	
	/// ditto
	final @property bool restoreDirectory() // getter
	{
		return (ofn.Flags & OFN_NOCHANGEDIR) != 0;
	}
	
	
	///
	final @property void showHelp(bool byes) // setter
	{
		if(byes)
			ofn.Flags |= OFN_SHOWHELP;
		else
			ofn.Flags &= ~OFN_SHOWHELP;
	}
	
	/// ditto
	final @property bool showHelp() // getter
	{
		return (ofn.Flags & OFN_SHOWHELP) != 0;
	}
	
	
	///
	final @property void title(Dstring newTitle) // setter
	{
		if(!newTitle.length)
		{
			ofn.lpstrTitle = null;
			_title = null;
		}
		else
		{
			if(dfl.internal.utf.useUnicode)
			{
				ofnw.lpstrTitle = dfl.internal.utf.toUnicodez(newTitle);
			}
			else
			{
				ofna.lpstrTitle = dfl.internal.utf.toAnsiz(newTitle);
			}
			_title = newTitle;
		}
	}
	
	/// ditto
	final @property Dstring title() // getter
	{
		return _title;
	}
	
	
	///
	final @property void validateNames(bool byes) // setter
	{
		if(byes)
			ofn.Flags &= ~OFN_NOVALIDATE;
		else
			ofn.Flags |= OFN_NOVALIDATE;
	}
	
	/// ditto
	final @property bool validateNames() // getter
	{
		return(ofn.Flags & OFN_NOVALIDATE) == 0;
	}
	
	
	///
	Event!(FileDialog, CancelEventArgs) fileOk;
	
	
	protected:
	
	override bool runDialog(HWND owner)
	{
		assert(0);
	}
	
	
	///
	void onFileOk(CancelEventArgs ea)
	{
		fileOk(this, ea);
	}
	
	
	override LRESULT hookProc(HWND hwnd, UINT msg, WPARAM wparam, LPARAM lparam)
	{
		switch(msg)
		{
			case WM_NOTIFY:
				{
					NMHDR* nmhdr;
					nmhdr = cast(NMHDR*)lparam;
					switch(nmhdr.code)
					{
						case CDN_FILEOK:
							{
								CancelEventArgs cea;
								cea = new CancelEventArgs;
								onFileOk(cea);
								if(cea.cancel)
								{
									SetWindowLongA(hwnd, DWL_MSGRESULT, 1);
									return 1;
								}
							}
							break;
						
						default:
							//cprintf("   nmhdr.code = %d/0x%X\n", nmhdr.code, nmhdr.code);
					}
				}
				break;
			
			default:
		}
		
		return super.hookProc(hwnd, msg, wparam, lparam);
	}
	
	
	private:
	union
	{
		OPENFILENAMEW ofnw;
		OPENFILENAMEA ofna;
		alias ofnw ofn;
		
		static assert(OPENFILENAMEW.sizeof == OPENFILENAMEA.sizeof);
		static assert(OPENFILENAMEW.Flags.offsetof == OPENFILENAMEA.Flags.offsetof);
	}
	Dstring[] _fileNames;
	Dstring _filter;
	Dstring _initDir;
	Dstring _defext;
	Dstring _title;
	//bool addext = true;
	bool needRebuildFiles = false;
	
	enum DWORD INIT_FLAGS = OFN_EXPLORER | OFN_PATHMUSTEXIST | OFN_HIDEREADONLY |
		OFN_ENABLEHOOK | OFN_ENABLESIZING;
	enum INIT_FILTER_INDEX = 0;
	enum FILE_BUF_LEN = 4096; // ? 12288 ? 12800 ?
	
	
	void beginOfn(HWND owner)
	{
		if(dfl.internal.utf.useUnicode)
		{
			auto buf = new wchar[(ofn.Flags & OFN_ALLOWMULTISELECT) ? FILE_BUF_LEN : MAX_PATH];
			buf[0] = 0;
			
			if(fileNames.length)
			{
				Dwstring ts;
				ts = dfl.internal.utf.toUnicode(_fileNames[0]);
				buf[0 .. ts.length] = ts[];
				buf[ts.length] = 0;
			}
			
			ofnw.nMaxFile = buf.length;
			ofnw.lpstrFile = buf.ptr;
		}
		else
		{
			auto buf = new char[(ofn.Flags & OFN_ALLOWMULTISELECT) ? FILE_BUF_LEN : MAX_PATH];
			buf[0] = 0;
			
			if(fileNames.length)
			{
				Dstring ts;
				ts = dfl.internal.utf.unsafeAnsi(_fileNames[0]);
				buf[0 .. ts.length] = ts[];
				buf[ts.length] = 0;
			}
			
			ofna.nMaxFile = buf.length;
			ofna.lpstrFile = buf.ptr;
		}
		
		ofn.hwndOwner = owner;
	}
	
	
	// Populate -_fileNames- from -ofn.lpstrFile-.
	void populateFiles()
	in
	{
		assert(ofn.lpstrFile !is null);
	}
	body
	{
		if(ofn.Flags & OFN_ALLOWMULTISELECT)
		{
			// Nonstandard reserve.
			_fileNames = new Dstring[4];
			_fileNames = _fileNames[0 .. 0];
			
			if(dfl.internal.utf.useUnicode)
			{
				wchar* startp, p;
				p = startp = ofnw.lpstrFile;
				for(;;)
				{
					if(!*p)
					{
						_fileNames ~= dfl.internal.utf.fromUnicode(startp, p - startp); // dup later.
						
						p++;
						if(!*p)
							break;
						
						startp = p;
						continue;
					}
					
					p++;
				}
			}
			else
			{
				char* startp, p;
				p = startp = ofna.lpstrFile;
				for(;;)
				{
					if(!*p)
					{
						_fileNames ~= dfl.internal.utf.fromAnsi(startp, p - startp); // dup later.
						
						p++;
						if(!*p)
							break;
						
						startp = p;
						continue;
					}
					
					p++;
				}
			}
			
			assert(_fileNames.length);
			if(_fileNames.length == 1)
			{
				//_fileNames[0] = _fileNames[0].dup;
				//_fileNames[0] = _fileNames[0].idup; // Needed in D2. Doesn't work in D1.
				_fileNames[0] = cast(Dstring)_fileNames[0].dup; // Needed in D2.
			}
			else
			{
				Dstring s;
				size_t i;
				s = _fileNames[0];
				
				// Not sure which of these 2 is better...
				/+
				for(i = 1; i != _fileNames.length; i++)
				{
					_fileNames[i - 1] = pathJoin(s, _fileNames[i]);
				}
				_fileNames = _fileNames[0 .. _fileNames.length - 1];
				+/
				for(i = 1; i != _fileNames.length; i++)
				{
					_fileNames[i] = pathJoin(s, _fileNames[i]);
				}
				_fileNames = _fileNames[1 .. _fileNames.length];
			}
		}
		else
		{
			_fileNames = new Dstring[1];
			if(dfl.internal.utf.useUnicode)
			{
				_fileNames[0] = dfl.internal.utf.fromUnicodez(ofnw.lpstrFile);
			}
			else
			{
				_fileNames[0] = dfl.internal.utf.fromAnsiz(ofna.lpstrFile);
			}
			
			/+
			if(addext && checkFileExists() && ofn.nFilterIndex)
			{
				if(!ofn.nFileExtension || ofn.nFileExtension == _fileNames[0].length)
				{
					Dstring s;
					typeof(ofn.nFilterIndex) onidx;
					int i;
					Dstring[] exts;
					
					s = _filter;
					onidx = ofn.nFilterIndex << 1;
					do
					{
						i = charFindInString(s, '|');
						if(i == -1)
							goto no_such_filter;
						
						s = s[i + 1 .. s.length];
						
						onidx--;
					}
					while(onidx != 1);
					
					i = charFindInString(s, '|');
					if(i != -1)
						s = s[0 .. i];
					
					exts = stringSplit(s, ";");
					foreach(Dstring ext; exts)
					{
						cprintf("sel ext:  %.*s\n", ext);
					}
					
					// ...
					
					no_such_filter: ;
				}
			}
			+/
		}
		
		needRebuildFiles = false;
	}
	
	
	// Call only if the dialog succeeded.
	void finishOfn()
	{
		if(needRebuildFiles)
			populateFiles();
		
		ofn.lpstrFile = null;
	}
	
	
	// Call only if dialog fail or cancel.
	void cancelOfn()
	{
		needRebuildFiles = false;
		
		ofn.lpstrFile = null;
		_fileNames = null;
	}
}


private extern(Windows) nothrow
{
	alias BOOL function(LPOPENFILENAMEW lpofn) GetOpenFileNameWProc;
	alias BOOL function(LPOPENFILENAMEW lpofn) GetSaveFileNameWProc;
}


///
class OpenFileDialog: FileDialog // docmain
{
	this()
	{
		super();
		ofn.Flags |= OFN_FILEMUSTEXIST;
	}
	
	
	override void reset()
	{
		super.reset();
		ofn.Flags |= OFN_FILEMUSTEXIST;
	}
	
	
	///
	final @property void multiselect(bool byes) // setter
	{
		if(byes)
			ofn.Flags |= OFN_ALLOWMULTISELECT;
		else
			ofn.Flags &= ~OFN_ALLOWMULTISELECT;
	}
	
	/// ditto
	final @property bool multiselect() // getter
	{
		return (ofn.Flags & OFN_ALLOWMULTISELECT) != 0;
	}
	
	
	///
	final @property void readOnlyChecked(bool byes) // setter
	{
		if(byes)
			ofn.Flags |= OFN_READONLY;
		else
			ofn.Flags &= ~OFN_READONLY;
	}
	
	/// ditto
	final @property bool readOnlyChecked() // getter
	{
		return (ofn.Flags & OFN_READONLY) != 0;
	}
	
	
	///
	final @property void showReadOnly(bool byes) // setter
	{
		if(byes)
			ofn.Flags &= ~OFN_HIDEREADONLY;
		else
			ofn.Flags |= OFN_HIDEREADONLY;
	}
	
	/// ditto
	final @property bool showReadOnly() // getter
	{
		return (ofn.Flags & OFN_HIDEREADONLY) == 0;
	}
	
	
	private import std.stream; // TO-DO: remove this import; use dfl.internal.dlib.
	
	///
	final Stream openFile()
	{
		return new File(fileName(), FileMode.In);
	}
	
	
	protected:
	
	override bool runDialog(HWND owner)
	{
		if(!_runDialog(owner))
		{
			if(!CommDlgExtendedError())
				return false;
			_cantrun();
		}
		return true;
	}
	
	
	private BOOL _runDialog(HWND owner)
	{
		BOOL result = 0;
		
		beginOfn(owner);
		
		//synchronized(typeid(dfl.internal.utf.CurDirLockType))
		{
			if(dfl.internal.utf.useUnicode)
			{
				enum NAME = "GetOpenFileNameW";
				static GetOpenFileNameWProc proc = null;
				
				if(!proc)
				{
					proc = cast(GetOpenFileNameWProc)GetProcAddress(GetModuleHandleA("comdlg32.dll"), NAME.ptr);
					if(!proc)
						throw new Exception("Unable to load procedure " ~ NAME ~ "");
				}
				
				result = proc(&ofnw);
			}
			else
			{
				result = GetOpenFileNameA(&ofna);
			}
		}
		
		if(result)
		{
			finishOfn();
			return result;
		}
		
		cancelOfn();
		return result;
	}
}


///
class SaveFileDialog: FileDialog // docmain
{
	this()
	{
		super();
		ofn.Flags |= OFN_OVERWRITEPROMPT;
	}
	
	
	override void reset()
	{
		super.reset();
		ofn.Flags |= OFN_OVERWRITEPROMPT;
	}
	
	
	///
	final @property void createPrompt(bool byes) // setter
	{
		if(byes)
			ofn.Flags |= OFN_CREATEPROMPT;
		else
			ofn.Flags &= ~OFN_CREATEPROMPT;
	}
	
	/// ditto
	final @property bool createPrompt() // getter
	{
		return (ofn.Flags & OFN_CREATEPROMPT) != 0;
	}
	
	
	///
	final @property void overwritePrompt(bool byes) // setter
	{
		if(byes)
			ofn.Flags |= OFN_OVERWRITEPROMPT;
		else
			ofn.Flags &= ~OFN_OVERWRITEPROMPT;
	}
	
	/// ditto
	final @property bool overwritePrompt() // getter
	{
		return (ofn.Flags & OFN_OVERWRITEPROMPT) != 0;
	}
	
	
	private import std.stream; // TO-DO: remove this import; use dfl.internal.dlib.
		
	///
	// Opens and creates with read and write access.
	// Warning: if file exists, it's truncated.
	final Stream openFile()
	{
		return new File(fileName(), FileMode.OutNew | FileMode.Out | FileMode.In);
	}
	
	
	protected:
	
	override bool runDialog(HWND owner)
	{
		beginOfn(owner);
		
		//synchronized(typeid(dfl.internal.utf.CurDirLockType))
		{
			if(dfl.internal.utf.useUnicode)
			{
				enum NAME = "GetSaveFileNameW";
				static GetSaveFileNameWProc proc = null;
				
				if(!proc)
				{
					proc = cast(GetSaveFileNameWProc)GetProcAddress(GetModuleHandleA("comdlg32.dll"), NAME.ptr);
					if(!proc)
						throw new Exception("Unable to load procedure " ~ NAME ~ "");
				}
				
				if(proc(&ofnw))
				{
					finishOfn();
					return true;
				}
			}
			else
			{
				if(GetSaveFileNameA(&ofna))
				{
					finishOfn();
					return true;
				}
			}
		}
		
		cancelOfn();
		return false;
	}
}


private extern(Windows) LRESULT ofnHookProc(HWND hwnd, UINT msg, WPARAM wparam, LPARAM lparam) nothrow
{
	alias dfl.internal.winapi.HANDLE HANDLE; // Otherwise, odd conflict with wine.
	
	enum PROP_STR = "DFL_FileDialog";
	FileDialog fd;
	LRESULT result = 0;
	
	try
	{
		if(msg == WM_INITDIALOG)
		{
			OPENFILENAMEA* ofn;
			ofn = cast(OPENFILENAMEA*)lparam;
			SetPropA(hwnd, PROP_STR.ptr, cast(HANDLE)ofn.lCustData);
			fd = cast(FileDialog)cast(void*)ofn.lCustData;
		}
		else
		{
			fd = cast(FileDialog)cast(void*)GetPropA(hwnd, PROP_STR.ptr);
		}
		
		//cprintf("hook msg(%d/0x%X) to obj %p\n", msg, msg, fd);
		if(fd)
		{
			fd.needRebuildFiles = true;
			result = fd.hookProc(hwnd, msg, wparam, lparam);
		}
	}
	catch(DThrowable e)
	{
		Application.onThreadException(e);
	}
	
	return result;
}

