// Written by Christopher E. Miller
// See the included license.txt for copyright and license details.


///
module dfl.filedialog;

import dfl.application;
import dfl.base;
import dfl.commondialog;
import dfl.control;
import dfl.drawing;
import dfl.event;

import dfl.internal.dlib;
import dfl.internal.utf;

import core.sys.windows.commdlg;
import core.sys.windows.winbase;
import core.sys.windows.windef;
import core.sys.windows.winuser;


///
abstract class FileDialog: CommonDialog // docmain
{
	///
	private this()
	{
		Application.ppin(cast(void*)this);
		
		_ofn.lStructSize = _ofn.sizeof;
		_ofn.lCustData = cast(typeof(_ofn.lCustData))cast(void*)this;
		_ofn.Flags = INIT_FLAGS;
		_ofn.nFilterIndex = INIT_FILTER_INDEX;
		_initInstance();
		_ofn.lpfnHook = &_ofnHookProc;
	}
	
	
	///
	override DialogResult showDialog()
	{
		bool resultOK = runDialog(GetActiveWindow());
		if (resultOK)
		{
			_populateFiles();
			return DialogResult.OK;
		}
		else
		{
			return DialogResult.CANCEL;
		}
	}
	
	/// ditto
	override DialogResult showDialog(IWindow owner)
	{
		bool resultOK = runDialog(owner ? owner.handle : GetActiveWindow());
		if (resultOK)
		{
			_populateFiles();
			return DialogResult.OK;
		}
		else
		{
			return DialogResult.CANCEL;
		}
	}
	
	
	///
	override void reset()
	{
		_ofn.Flags = INIT_FLAGS;
		_ofn.lpstrFilter = null;
		_ofn.nFilterIndex = INIT_FILTER_INDEX;
		_ofn.lpstrDefExt = null;
		_ofn.lpstrInitialDir = null;
		_ofn.lpstrTitle = null;
		_defext = null;
		_fileNames = null;
		_needRebuildFileNames = false;
		_filter = null;
		_showPlaceBar = false;
		_initDir = null;
		_title = null;
		_initInstance();
	}
	
	
	///
	private void _initInstance()
	{
		//_ofn.hInstance = ?; // Should this be initialized?
	}
	
	
	/+
	final @property void addExtension(bool byes) // setter
	{
		_addext = byes;
	}
	
	
	final @property bool addExtension() const // getter
	{
		return _addext;
	}
	+/
	
	
	///
	@property void checkFileExists(bool byes) // setter
	{
		if (byes)
			_ofn.Flags |= OFN_FILEMUSTEXIST;
		else
			_ofn.Flags &= ~OFN_FILEMUSTEXIST;
	}
	
	/// ditto
	@property bool checkFileExists() const // getter
	{
		return (_ofn.Flags & OFN_FILEMUSTEXIST) != 0;
	}
	
	
	///
	final @property void checkPathExists(bool byes) // setter
	{
		if (byes)
			_ofn.Flags |= OFN_PATHMUSTEXIST;
		else
			_ofn.Flags &= ~OFN_PATHMUSTEXIST;
	}
	
	/// ditto
	final @property bool checkPathExists() const // getter
	{
		return (_ofn.Flags & OFN_PATHMUSTEXIST) != 0;
	}
	
	
	///
	final @property void defaultExt(Dstring ext) // setter
	{
		if (!ext.length)
		{
			_ofn.lpstrDefExt = null;
			_defext = null;
		}
		else
		{
			if (ext.length && ext[0] == '.')
				ext = ext[1 .. ext.length];
			
			static if (dfl.internal.utf.useUnicode)
			{
				_ofn.lpstrDefExt = dfl.internal.utf.toUnicodez(ext);
			}
			else
			{
				_ofn.lpstrDefExt = dfl.internal.utf.toAnsiz(ext);
			}
			_defext = ext;
		}
	}
	
	/// ditto
	final @property Dstring defaultExt() const // getter
	{
		return _defext;
	}
	
	
	///
	final @property void dereferenceLinks(bool byes) // setter
	{
		if (byes)
			_ofn.Flags &= ~OFN_NODEREFERENCELINKS;
		else
			_ofn.Flags |= OFN_NODEREFERENCELINKS;
	}
	
	/// ditto
	final @property bool dereferenceLinks() const // getter
	{
		return (_ofn.Flags & OFN_NODEREFERENCELINKS) == 0;
	}
	
	
	/// When false, Enable events and hide place bar (mutually exclusive).
	final @property void showPlaceBar(bool byes) // setter
	{
		_showPlaceBar = byes;
		if (byes)
			_ofn.Flags &= ~OFN_ENABLEHOOK;
		else
			_ofn.Flags |= OFN_ENABLEHOOK;
	}
	
	/// ditto
	final @property bool showPlaceBar() const // getter
	{
		return _showPlaceBar;
	}
	
	
	///
	final @property void fileName(Dstring fn) // setter
	{
		// TODO: check if correct implementation.
		
		if (fn.length > MAX_PATH)
			throw new DflException("Invalid file name");
		
		if (fileNames.length)
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
		if (fileNames.length)
			return fileNames[0];
		return null;
	}
	
	
	///
	final @property Dstring[] fileNames() // getter
	{
		if (_needRebuildFileNames)
			_populateFiles();
		
		return _fileNames;
	}
	
	
	///
	// The format string is like "Text files (*.txt)|*.txt|All files (*.*)|*.*".
	final @property void filter(Dstring filterString) // setter
	{
		if (!filterString.length)
		{
			_ofn.lpstrFilter = null;
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
			
			static if (dfl.internal.utf.useUnicode)
			{
				str.sw = new wchar[filterString.length + 2];
				str.sw = str.sw[0 .. 0];
			}
			else
			{
				str.sa = new char[filterString.length + 2];
				str.sa = str.sa[0 .. 0];
			}
			
			
			for (i = starti = 0; i != filterString.length; i++)
			{
				switch (filterString[i])
				{
					case '|':
						if (starti == i)
							goto bad_filter;
						
						static if (dfl.internal.utf.useUnicode)
						{
							str.sw ~= dfl.internal.utf.toUnicode(filterString[starti .. i]);
							str.sw ~= "\0"w;
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
			if (starti == i || !(nitems % 2))
				goto bad_filter;
			static if (dfl.internal.utf.useUnicode)
			{
				str.sw ~= dfl.internal.utf.toUnicode(filterString[starti .. i]);
				str.sw ~= "\0\0"w;
				
				_ofn.lpstrFilter = str.sw.ptr;
			}
			else
			{
				str.sa ~= dfl.internal.utf.unsafeAnsi(filterString[starti .. i]);
				str.sa ~= "\0\0";
				
				_ofn.lpstrFilter = str.sa.ptr;
			}
			
			_filter = filterString;
			return;
			
		bad_filter:
			throw new DflException("Invalid file filter string");
		}
	}
	
	/// ditto
	final @property Dstring filter() const // getter
	{
		return _filter;
	}
	
	
	///
	// Note: index is 1-based.
	final @property void filterIndex(int index) // setter
	{
		_ofn.nFilterIndex = (index > 0) ? index : 1;
	}
	
	/// ditto
	final @property int filterIndex() const // getter
	{
		return _ofn.nFilterIndex;
	}
	
	
	///
	final @property void initialDirectory(Dstring dir) // setter
	{
		if (!dir.length)
		{
			_ofn.lpstrInitialDir = null;
			_initDir = null;
		}
		else
		{
			static if (dfl.internal.utf.useUnicode)
			{
				_ofn.lpstrInitialDir = dfl.internal.utf.toUnicodez(dir);
			}
			else
			{
				_ofn.lpstrInitialDir = dfl.internal.utf.toAnsiz(dir);
			}
			_initDir = dir;
		}
	}
	
	/// ditto
	final @property Dstring initialDirectory() const // getter
	{
		return _initDir;
	}
	
	
	// Should be instance(), but conflicts with D's old keyword.
	
	///
	protected @property void inst(HINSTANCE hinst) // setter
	{
		_ofn.hInstance = hinst;
	}
	
	/// ditto
	protected @property HINSTANCE inst() // getter
	{
		return _ofn.hInstance;
	}
	
	
	///
	protected @property DWORD options() const // getter
	{
		return _ofn.Flags;
	}
	
	
	///
	final @property void restoreDirectory(bool byes) // setter
	{
		if (byes)
			_ofn.Flags |= OFN_NOCHANGEDIR;
		else
			_ofn.Flags &= ~OFN_NOCHANGEDIR;
	}
	
	/// ditto
	final @property bool restoreDirectory() const // getter
	{
		return (_ofn.Flags & OFN_NOCHANGEDIR) != 0;
	}
	
	
	///
	final @property void showHelp(bool byes) // setter
	{
		if (byes)
			_ofn.Flags |= OFN_SHOWHELP;
		else
			_ofn.Flags &= ~OFN_SHOWHELP;
	}
	
	/// ditto
	final @property bool showHelp() const // getter
	{
		return (_ofn.Flags & OFN_SHOWHELP) != 0;
	}
	
	
	///
	final @property void title(Dstring newTitle) // setter
	{
		if (!newTitle.length)
		{
			_ofn.lpstrTitle = null;
			_title = null;
		}
		else
		{
			static if (dfl.internal.utf.useUnicode)
			{
				_ofn.lpstrTitle = dfl.internal.utf.toUnicodez(newTitle);
			}
			else
			{
				_ofn.lpstrTitle = dfl.internal.utf.toAnsiz(newTitle);
			}
			_title = newTitle;
		}
	}
	
	/// ditto
	final @property Dstring title() const // getter
	{
		return _title;
	}
	
	
	///
	final @property void validateNames(bool byes) // setter
	{
		if (byes)
			_ofn.Flags &= ~OFN_NOVALIDATE;
		else
			_ofn.Flags |= OFN_NOVALIDATE;
	}
	
	/// ditto
	final @property bool validateNames() const // getter
	{
		return(_ofn.Flags & OFN_NOVALIDATE) == 0;
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
	

	override UINT_PTR hookProc(HWND hwnd, UINT msg, WPARAM wparam, LPARAM lparam)
	{
		switch (msg)
		{
			case WM_NOTIFY:
			{
				OFNOTIFY* notify = cast(OFNOTIFY*)lparam;

				switch (notify.hdr.code)
				{
					case CDN_FILEOK:
					{
						CancelEventArgs cea = new CancelEventArgs;
						onFileOk(cea);
						if (cea.cancel)
						{
							static if (dfl.internal.utf.useUnicode)
								SetWindowLongPtrW(hwnd, DWL_MSGRESULT, 1);
							else
								SetWindowLongPtrA(hwnd, DWL_MSGRESULT, 1);
							return 1;
						}
						else
						{
							static if (dfl.internal.utf.useUnicode)
								fileName = fromUnicodez(notify.lpOFN.lpstrFile);
							else
								fileName = fromAnsiz(notify.lpOFN.lpstrFile);
							_populateFiles();
							return 0;
						}
					}
					
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
	static if (dfl.internal.utf.useUnicode)
	{
		OPENFILENAMEW _ofn;
	}
	else
	{
		OPENFILENAMEA _ofn;
	}
	static assert(OPENFILENAMEW.Flags.offsetof == OPENFILENAMEA.Flags.offsetof);

	Dstring[] _fileNames;
	Dstring _filter;
	Dstring _initDir;
	Dstring _defext;
	Dstring _title;
	//bool _addext = true;
	bool _needRebuildFileNames = false;
	bool _showPlaceBar = false;
	
	enum DWORD INIT_FLAGS = OFN_EXPLORER | OFN_PATHMUSTEXIST | OFN_HIDEREADONLY | OFN_ENABLEHOOK | OFN_ENABLESIZING;
	enum INIT_FILTER_INDEX = 0;
	enum FILE_BUF_LEN = 4096; // ? 12288 ? 12800 ?
	
	
	void _beginOfn(HWND owner)
	{
		static if (dfl.internal.utf.useUnicode)
		{
			auto buf = new wchar[(_ofn.Flags & OFN_ALLOWMULTISELECT) ? FILE_BUF_LEN : MAX_PATH];
			buf[0] = 0;
			
			if (fileNames.length)
			{
				Dwstring ts = dfl.internal.utf.toUnicode(_fileNames[0]);
				buf[0 .. ts.length] = ts[];
				buf[ts.length] = 0;
			}
			
			_ofn.nMaxFile = buf.length.toI32;
			_ofn.lpstrFile = buf.ptr;
		}
		else
		{
			auto buf = new char[(_ofn.Flags & OFN_ALLOWMULTISELECT) ? FILE_BUF_LEN : MAX_PATH];
			buf[0] = 0;
			
			if (fileNames.length)
			{
				Dstring ts = dfl.internal.utf.unsafeAnsi(_fileNames[0]);
				buf[0 .. ts.length] = ts[];
				buf[ts.length] = 0;
			}
			
			_ofn.nMaxFile = buf.length.toI32;
			_ofn.lpstrFile = buf.ptr;
		}
		
		_ofn.hwndOwner = owner;
	}
	
	
	// Populate -_fileNames- from -ofn.lpstrFile-.
	void _populateFiles()
	in
	{
		assert(_ofn.lpstrFile !is null);
	}
	do
	{
		if (_ofn.Flags & OFN_ALLOWMULTISELECT)
		{
			// Nonstandard reserve.
			_fileNames = new Dstring[4];
			_fileNames = _fileNames[0 .. 0];
			
			static if (dfl.internal.utf.useUnicode)
			{
				wchar* startp = _ofn.lpstrFile;
				wchar* p = startp;

				for (;;)
				{
					if (!*p)
					{
						_fileNames ~= dfl.internal.utf.fromUnicode(startp, p - startp); // dup later.
						
						p++;
						if (!*p)
							break;
						
						startp = p;
						continue;
					}
					
					p++;
				}
			}
			else
			{
				char* startp = _ofn.lpstrFile;
				char* p = startp;
				for (;;)
				{
					if (!*p)
					{
						_fileNames ~= dfl.internal.utf.fromAnsi(startp, p - startp); // dup later.
						
						p++;
						if (!*p)
							break;
						
						startp = p;
						continue;
					}
					
					p++;
				}
			}
			
			assert(_fileNames.length);
			if (_fileNames.length == 1)
			{
				//_fileNames[0] = _fileNames[0].dup;
				//_fileNames[0] = _fileNames[0].idup; // Needed in D2. Doesn't work in D1.
				_fileNames[0] = cast(Dstring)_fileNames[0].dup; // Needed in D2.
			}
			else
			{
				Dstring s = _fileNames[0];
				
				// Not sure which of these 2 is better...
				/+
				for (size_t i = 1; i != _fileNames.length; i++)
				{
					_fileNames[i - 1] = pathJoin(s, _fileNames[i]);
				}
				_fileNames = _fileNames[0 .. _fileNames.length - 1];
				+/
				for (size_t i = 1; i != _fileNames.length; i++)
				{
					_fileNames[i] = pathJoin(s, _fileNames[i]);
				}
				_fileNames = _fileNames[1 .. _fileNames.length];
			}
		}
		else
		{
			_fileNames = new Dstring[1];
			static if (dfl.internal.utf.useUnicode)
			{
				_fileNames[0] = dfl.internal.utf.fromUnicodez(_ofn.lpstrFile);
			}
			else
			{
				_fileNames[0] = dfl.internal.utf.fromAnsiz(_ofn.lpstrFile);
			}
			
			/+
			if (_addext && checkFileExists() && _ofn.nFilterIndex)
			{
				if (!_ofn.nFileExtension || _ofn.nFileExtension == _fileNames[0].length)
				{
					Dstring s = _filter;
					typeof(_ofn.nFilterIndex) onidx = _ofn.nFilterIndex << 1;

					int i;
					
					do
					{
						i = charFindInString(s, '|');
						if (i == -1)
							goto no_such_filter;
						
						s = s[i + 1 .. s.length];
						
						onidx--;
					}
					while(onidx != 1);
					
					i = charFindInString(s, '|');
					if (i != -1)
						s = s[0 .. i];
					
					Dstring[] exts = stringSplit(s, ";");
					foreach ((Dstring ext; exts)
					{
						cprintf("sel ext:  %.*s\n", ext);
					}
					
					// ...
					
				no_such_filter: ;
				}
			}
			+/
		}
		
		_needRebuildFileNames = false;
	}
	
	
	// Call only if the dialog succeeded.
	void _finishOfn()
	{
		if (_needRebuildFileNames)
			_populateFiles();
		
		// NOTE: When don't use hook proc, Need to get file names from _ofn.lpstrFile.
		// Don't let _ofn.lpstrFile be null.
		//
		// _ofn.lpstrFile = null;
	}
	
	
	// Call only if dialog fail or cancel.
	void _cancelOfn()
	{
		_needRebuildFileNames = false;
		
		_ofn.lpstrFile = null;
		_fileNames = null;
	}
}


private extern(Windows) nothrow
{
	alias GetOpenFileNameWProc = BOOL function(LPOPENFILENAMEW lpofn);
	alias GetSaveFileNameWProc = BOOL function(LPOPENFILENAMEW lpofn);
}


///
class OpenFileDialog: FileDialog // docmain
{
	this()
	{
		super();
		_ofn.Flags |= OFN_FILEMUSTEXIST;
	}
	
	
	override void reset()
	{
		super.reset();
		_ofn.Flags |= OFN_FILEMUSTEXIST;
	}
	
	
	///
	final @property void multiselect(bool byes) // setter
	{
		if (byes)
			_ofn.Flags |= OFN_ALLOWMULTISELECT;
		else
			_ofn.Flags &= ~OFN_ALLOWMULTISELECT;
	}
	
	/// ditto
	final @property bool multiselect() const // getter
	{
		return (_ofn.Flags & OFN_ALLOWMULTISELECT) != 0;
	}
	
	
	///
	final @property void readOnlyChecked(bool byes) // setter
	{
		if (byes)
			_ofn.Flags |= OFN_READONLY;
		else
			_ofn.Flags &= ~OFN_READONLY;
	}
	
	/// ditto
	final @property bool readOnlyChecked() const // getter
	{
		return (_ofn.Flags & OFN_READONLY) != 0;
	}
	
	
	///
	final @property void showReadOnly(bool byes) // setter
	{
		if (byes)
			_ofn.Flags &= ~OFN_HIDEREADONLY;
		else
			_ofn.Flags |= OFN_HIDEREADONLY;
	}
	
	/// ditto
	final @property bool showReadOnly() const // getter
	{
		return (_ofn.Flags & OFN_HIDEREADONLY) == 0;
	}
	
	
	import std.stdio : File;
	
	///
	final File openFile()
	{
		return File(fileName(), "r");
	}

	
protected:
	
	override bool runDialog(HWND owner)
	{
		if (!_runDialog(owner))
		{
			if (!CommDlgExtendedError())
				return false;
			_cantRun();
		}
		return true;
	}
	
	
	private BOOL _runDialog(HWND owner)
	{
		BOOL result = 0;
		
		_beginOfn(owner);
		
		//synchronized(typeid(dfl.internal.utf.CurDirLockType))
		{
			static if (dfl.internal.utf.useUnicode)
			{
				enum NAME = "GetOpenFileNameW";
				static GetOpenFileNameWProc proc = null;
				
				if (!proc)
				{
					proc = cast(GetOpenFileNameWProc)GetProcAddress(GetModuleHandleA("comdlg32.dll"), NAME.ptr);
					if (!proc)
						throw new Exception("Unable to load procedure " ~ NAME ~ "");
				}
				
				result = proc(&_ofn);
			}
			else
			{
				result = GetOpenFileNameA(&_ofn);
			}
		}
		
		if (result)
		{
			_finishOfn();
			return result;
		}
		
		_cancelOfn();
		return result;
	}
}


///
class SaveFileDialog: FileDialog // docmain
{
	this()
	{
		super();
		_ofn.Flags |= OFN_OVERWRITEPROMPT;
	}
	
	
	override void reset()
	{
		super.reset();
		_ofn.Flags |= OFN_OVERWRITEPROMPT;
	}
	
	
	///
	final @property void createPrompt(bool byes) // setter
	{
		if (byes)
			_ofn.Flags |= OFN_CREATEPROMPT;
		else
			_ofn.Flags &= ~OFN_CREATEPROMPT;
	}
	
	/// ditto
	final @property bool createPrompt() // getter
	{
		return (_ofn.Flags & OFN_CREATEPROMPT) != 0;
	}
	
	
	///
	final @property void overwritePrompt(bool byes) // setter
	{
		if (byes)
			_ofn.Flags |= OFN_OVERWRITEPROMPT;
		else
			_ofn.Flags &= ~OFN_OVERWRITEPROMPT;
	}
	
	/// ditto
	final @property bool overwritePrompt() // getter
	{
		return (_ofn.Flags & OFN_OVERWRITEPROMPT) != 0;
	}
	
	
	import std.stdio : File;
	

	///
	final File openFile()
	{
		return File(fileName(), "w+");
	}
	
	
protected:
	
	override bool runDialog(HWND owner)
	{
		_beginOfn(owner);
		
		//synchronized(typeid(dfl.internal.utf.CurDirLockType))
		{
			static if (dfl.internal.utf.useUnicode)
			{
				enum NAME = "GetSaveFileNameW";
				static GetSaveFileNameWProc proc = null;
				
				if (!proc)
				{
					proc = cast(GetSaveFileNameWProc)GetProcAddress(GetModuleHandleA("comdlg32.dll"), NAME.ptr);
					if (!proc)
						throw new Exception("Unable to load procedure " ~ NAME ~ "");
				}
				
				if (proc(&_ofn))
				{
					_finishOfn();
					return true;
				}
			}
			else
			{
				if (GetSaveFileNameA(&_ofn))
				{
					_finishOfn();
					return true;
				}
			}
		}
		
		_cancelOfn();
		return false;
	}
}


private extern(Windows) UINT_PTR _ofnHookProc(HWND hwnd, UINT msg, WPARAM wparam, LPARAM lparam) nothrow
{
	enum PROP_STR = "DFL_FileDialog";
	FileDialog fd;
	UINT_PTR result = 0;
	
	try
	{
		if (msg == WM_INITDIALOG)
		{
			OPENFILENAME* ofn = cast(OPENFILENAME*)lparam;
			static if (dfl.internal.utf.useUnicode)
			{
				SetPropW(hwnd, toUnicodez(PROP_STR), cast(HANDLE)ofn.lCustData);
			}
			else
			{
				SetPropA(hwnd, toAnsiz(PROP_STR), cast(HANDLE)ofn.lCustData);
			}
			fd = cast(FileDialog)cast(void*)ofn.lCustData;
		}
		else
		{
			static if (dfl.internal.utf.useUnicode)
			{
				fd = cast(FileDialog)cast(void*)GetPropW(hwnd, toUnicodez(PROP_STR));
			}
			else
			{
				fd = cast(FileDialog)cast(void*)GetPropA(hwnd, toAnsiz(PROP_STR));
			}
		}
		
		//cprintf("hook msg(%d/0x%X) to obj %p\n", msg, msg, fd);
		if (fd)
		{
			fd._needRebuildFileNames = true;
			result = fd.hookProc(hwnd, msg, wparam, lparam);
		}
	}
	catch (DThrowable e)
	{
		Application.onThreadException(e);
	}
	
	return result;
}
