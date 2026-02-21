// Written by Christopher E. Miller
// See the included license.txt for copyright and license details.


///
module dfl.folderdialog;

import dfl.application;
import dfl.base;
import dfl.commondialog;
import dfl.environment;

import dfl.internal.clib;
import dfl.internal.dlib;
import dfl.internal.utf;
import dfl.internal.winapi : LPITEMIDLIST, LPBROWSEINFOW, BROWSEINFOW, BROWSEINFOA, BIF_RETURNONLYFSDIRS, BIF_NEWDIALOGSTYLE,
	BIF_NONEWFOLDERBUTTON, BIF_EDITBOX, SHGetSpecialFolderLocation, CoTaskMemFree, SHGetMalloc, BFFM_INITIALIZED, BFFM_SETSELECTIONW;

import core.sys.windows.objidl;
import core.sys.windows.winbase;
import core.sys.windows.windef;
import core.sys.windows.winuser;

private extern(Windows) nothrow
{
	alias SHBrowseForFolderWProc = LPITEMIDLIST function(LPBROWSEINFOW lpbi);
}


///
class FolderBrowserDialog: CommonDialog // docmain
{
	this()
	{
		// Flag BIF_NEWDIALOGSTYLE requires OleInitialize().
		//OleInitialize(null);
		
		Application.ppin(cast(void*)this);
		
		_bi.ulFlags = INIT_FLAGS;
		_bi.lParam = cast(typeof(_bi.lParam))cast(void*)this;
		_bi.lpfn = &_fbdHookProc;
	}
	
	
	~this()
	{
		//OleUninitialize();
	}
	
	
	override DialogResult showDialog()
	{
		if (!runDialog(GetActiveWindow()))
			return DialogResult.CANCEL;
		return DialogResult.OK;
	}
	
	
	/// 
	override DialogResult showDialog(IWindow owner)
	{
		if (!runDialog(owner ? owner.handle : GetActiveWindow()))
			return DialogResult.CANCEL;
		return DialogResult.OK;
	}
	
	
	///
	override void reset()
	{
		_bi.ulFlags = INIT_FLAGS;
		_description = null;
		_selectedPath = null;
		_root = Environment.SpecialFolder.DESKTOP;
	}
	
	
	///
	final @property void description(Dstring desc) // setter
	{
		// lpszTitle
		
		_description = desc;
	}
	
	/// ditto
	final @property Dstring description() const // getter
	{
		return _description;
	}
	
	
	///
	final @property void selectedPath(Dstring selpath) // setter
	{
		// pszDisplayName
		
		_selectedPath = selpath;
	}
	
	/// ditto
	final @property Dstring selectedPath() const // getter
	{
		return _selectedPath;
	}
	
	
	///
	// Currently only works for shell32.dll version 6.0+.
	final @property void showNewFolderButton(bool byes) // setter
	{
		// BIF_NONEWFOLDERBUTTON exists with shell 6.0+.
		// Might need to enum child windows looking for window title
		// "&New Folder" and hide it, then shift "OK" and "Cancel" over.
		
		if (byes)
			_bi.ulFlags &= ~BIF_NONEWFOLDERBUTTON;
		else
			_bi.ulFlags |= BIF_NONEWFOLDERBUTTON;
	}
	
	/// ditto
	final @property bool showNewFolderButton() const // getter
	{
		return (_bi.ulFlags & BIF_NONEWFOLDERBUTTON) == 0;
	}
	
	
	///
	// Currently only works for shell32.dll version 6.0+.
	final @property void showNewStyleDialog(bool byes) // setter
	{
		// BIF_NONEWFOLDERBUTTON exists with shell 6.0+.
		// Might need to enum child windows looking for window title
		// "&New Folder" and hide it, then shift "OK" and "Cancel" over.
		
		if (byes)
			_bi.ulFlags |= BIF_NEWDIALOGSTYLE;
		else
			_bi.ulFlags &= ~BIF_NEWDIALOGSTYLE;
	}
	
	/// ditto
	final @property bool showNewStyleDialog() const // getter
	{
		return (_bi.ulFlags & BIF_NEWDIALOGSTYLE) != 0;
	}
	
	
	///
	// Currently only works for shell32.dll version 6.0+.
	final @property void showTextBox(bool byes) // setter
	{
		// BIF_NONEWFOLDERBUTTON exists with shell 6.0+.
		// Might need to enum child windows looking for window title
		// "&New Folder" and hide it, then shift "OK" and "Cancel" over.
		
		if (byes)
			_bi.ulFlags |= BIF_EDITBOX;
		else
			_bi.ulFlags &= ~BIF_EDITBOX;
	}
	
	/// ditto
	final @property bool showTextBox() const // getter
	{
		return (_bi.ulFlags & BIF_EDITBOX) != 0;
	}
	
	
	///
	final @property void rootFolder(Environment.SpecialFolder root) // setter
	{
		_root = root;
	}

	/// ditto
	final @property Environment.SpecialFolder rootFolder() const // getter
	{
		return _root;
	}
	
	
	private void _errPathTooLong()
	{
		throw new DflException("Path name is too long");
	}
	
	
	private void _errNoGetPath()
	{
		throw new DflException("Unable to obtain path");
	}
	
	
	private void _errNoShMalloc()
	{
		throw new DflException("Unable to get shell memory allocator");
	}
	
	
	protected override bool runDialog(HWND owner)
	{
		IMalloc shmalloc;
		
		_bi.hwndOwner = owner;
		
		// Using size of wchar so that the buffer works for ansi and unicode.
		//void* pdescz = dfl.internal.clib.alloca(wchar.sizeof * MAX_PATH);
		//if (!pdescz)
		//	throw new DflException("Out of memory"); // Stack overflow ?
		//wchar[MAX_PATH] pdescz = void;
		wchar[MAX_PATH] pdescz; // Initialize because SHBrowseForFolder() is modal.
		
		static if (dfl.internal.utf.useUnicode)
		{
			enum BROWSE_NAME = "SHBrowseForFolderW";
			static SHBrowseForFolderWProc browseproc = null;
			
			if (!browseproc)
			{
				HMODULE hmod = GetModuleHandleA("shell32.dll");
				
				browseproc = cast(SHBrowseForFolderWProc)GetProcAddress(hmod, BROWSE_NAME.ptr);
				if (!browseproc)
					throw new Exception("Unable to load procedure " ~ BROWSE_NAME);
			}
			
			_bi.lpszTitle = dfl.internal.utf.toUnicodez(_description);
			
			{
				LPITEMIDLIST idlist;
				if (SHGetSpecialFolderLocation(owner, cast(int)_root, &idlist) == S_OK)
					_bi.pidlRoot = idlist;
				else
					_bi.pidlRoot = null;
			}
			scope(exit)
			{
				if (_bi.pidlRoot)
					CoTaskMemFree(_bi.pidlRoot);
			}
			
			_bi.pszDisplayName = cast(wchar*)pdescz;
			if (_description.length)
			{
				Dwstring tmp = dfl.internal.utf.toUnicode(_description);
				if (tmp.length >= MAX_PATH)
					_errPathTooLong();
				_bi.pszDisplayName[0 .. tmp.length] = tmp[];
				_bi.pszDisplayName[tmp.length] = 0;
			}
			else
			{
				_bi.pszDisplayName[0] = 0;
			}
			
			// Show the dialog!
			LPITEMIDLIST result = browseproc(&_bi);
			
			if (!result)
			{
				_bi.lpszTitle = null;
				return false;
			}
			
			if (NOERROR != SHGetMalloc(&shmalloc))
				_errNoShMalloc();
			
			Dstring wbuf = shGetPathFromIDList(result);
			if (!wbuf)
			{
				shmalloc.Free(result);
				shmalloc.Release();
				_errNoGetPath();
				assert(0);
			}
			
			_selectedPath = wbuf;
			
			shmalloc.Free(result);
			shmalloc.Release();
			
			_bi.lpszTitle = null;
		}
		else
		{
			_bi.lpszTitle = dfl.internal.utf.toAnsiz(_description);
			
			{
				LPITEMIDLIST idlist;
				if (SHGetSpecialFolderLocation(owner, cast(int)_root, &idlist) == S_OK)
					_bi.pidlRoot = idlist;
				else
					_bi.pidlRoot = null;
			}
			scope(exit)
			{
				if (_bi.pidlRoot)
					CoTaskMemFree(_bi.pidlRoot);
			}

			_bi.pszDisplayName = cast(char*)pdescz;
			if (_description.length)
			{
				Dstring tmp = dfl.internal.utf.toAnsi(_description); // ansi.
				if (tmp.length >= MAX_PATH)
					_errPathTooLong();
				_bi.pszDisplayName[0 .. tmp.length] = tmp[];
				_bi.pszDisplayName[tmp.length] = 0;
			}
			else
			{
				_bi.pszDisplayName[0] = 0;
			}
			
			// Show the dialog!
			LPITEMIDLIST result = SHBrowseForFolderA(&_bi);
			
			if (!result)
			{
				_bi.lpszTitle = null;
				return false;
			}
			
			if (NOERROR != SHGetMalloc(&shmalloc))
				_errNoShMalloc();
			
			Dstring abuf = shGetPathFromIDList(result);
			if (!abuf)
			{
				shmalloc.Free(result);
				shmalloc.Release();
				_errNoGetPath();
				assert(0);
			}
			
			_selectedPath = abuf;
			
			shmalloc.Free(result);
			shmalloc.Release();
			
			_bi.lpszTitle = null;
		}
		
		return true;
	}
	
	
protected:
	
	override UINT_PTR hookProc(HWND hwnd, UINT msg, WPARAM wparam, LPARAM lparam)
	{
		return super.hookProc(hwnd, msg, wparam, lparam);
	}
	
	
private:
	
	static if (dfl.internal.utf.useUnicode)
	{
		BROWSEINFOW _bi;
	}
	else
	{
		BROWSEINFOA _bi;
	}
	static assert(BROWSEINFOW.sizeof == BROWSEINFOA.sizeof);
	static assert(BROWSEINFOW.ulFlags.offsetof == BROWSEINFOA.ulFlags.offsetof);
	
	Dstring _description;
	Dstring _selectedPath;
	Environment.SpecialFolder _root = Environment.SpecialFolder.DESKTOP;
	
	
	enum UINT INIT_FLAGS = BIF_RETURNONLYFSDIRS | BIF_NEWDIALOGSTYLE;
}


// Return type is int.
// See https://learn.microsoft.com/en-us/previous-versions/windows/desktop/legacy/bb762598(v=vs.85)
private extern(Windows) int _fbdHookProc(HWND hwnd, UINT msg, LPARAM lparam, LPARAM lpData) nothrow
{
	
	int result = 0;
	try
	{
		FolderBrowserDialog fd = cast(FolderBrowserDialog)cast(void*)lpData;
		if (fd)
		{
			switch (msg)
			{
				case BFFM_INITIALIZED:
				{
					Dstring s = fd.selectedPath;
					if (s.length)
					{
						static if (dfl.internal.utf.useUnicode)
							SendMessageW(hwnd, BFFM_SETSELECTIONW, TRUE, cast(LPARAM)dfl.internal.utf.toUnicodez(s));
						else
							SendMessageA(hwnd, BFFM_SETSELECTIONA, TRUE, cast(LPARAM)dfl.internal.utf.toAnsiz(s));
					}
					break;
				}
				
				default:
			}
		}
	}
	catch (DThrowable e)
	{
		Application.onThreadException(e);
	}
	
	return result;
}
