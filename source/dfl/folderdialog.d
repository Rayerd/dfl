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
import dfl.internal.wincom;

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
		
		bi.ulFlags = INIT_FLAGS;
		bi.lParam = cast(typeof(bi.lParam))cast(void*)this;
		bi.lpfn = &fbdHookProc;
	}
	
	
	~this()
	{
		//OleUninitialize();
	}
	
	
	override DialogResult showDialog()
	{
		if(!runDialog(GetActiveWindow()))
			return DialogResult.CANCEL;
		return DialogResult.OK;
	}
	
	
	/// 
	override DialogResult showDialog(IWindow owner)
	{
		if(!runDialog(owner ? owner.handle : GetActiveWindow()))
			return DialogResult.CANCEL;
		return DialogResult.OK;
	}
	
	
	///
	override void reset()
	{
		bi.ulFlags = INIT_FLAGS;
		_desc = null;
		_selpath = null;
		_root = Environment.SpecialFolder.DESKTOP;
	}
	
	
	///
	final @property void description(Dstring desc) // setter
	{
		// lpszTitle
		
		_desc = desc;
	}
	
	/// ditto
	final @property Dstring description() const // getter
	{
		return _desc;
	}
	
	
	///
	final @property void selectedPath(Dstring selpath) // setter
	{
		// pszDisplayName
		
		_selpath = selpath;
	}
	
	/// ditto
	final @property Dstring selectedPath() const // getter
	{
		return _selpath;
	}
	
	
	///
	// Currently only works for shell32.dll version 6.0+.
	final @property void showNewFolderButton(bool byes) // setter
	{
		// BIF_NONEWFOLDERBUTTON exists with shell 6.0+.
		// Might need to enum child windows looking for window title
		// "&New Folder" and hide it, then shift "OK" and "Cancel" over.
		
		if(byes)
			bi.ulFlags &= ~BIF_NONEWFOLDERBUTTON;
		else
			bi.ulFlags |= BIF_NONEWFOLDERBUTTON;
	}
	
	/// ditto
	final @property bool showNewFolderButton() const // getter
	{
		return (bi.ulFlags & BIF_NONEWFOLDERBUTTON) == 0;
	}
	
	
	///
	// Currently only works for shell32.dll version 6.0+.
	final @property void showNewStyleDialog(bool byes) // setter
	{
		// BIF_NONEWFOLDERBUTTON exists with shell 6.0+.
		// Might need to enum child windows looking for window title
		// "&New Folder" and hide it, then shift "OK" and "Cancel" over.
		
		if(byes)
			bi.ulFlags |= BIF_NEWDIALOGSTYLE;
		else
			bi.ulFlags &= ~BIF_NEWDIALOGSTYLE;
	}
	
	/// ditto
	final @property bool showNewStyleDialog() const // getter
	{
		return (bi.ulFlags & BIF_NEWDIALOGSTYLE) != 0;
	}
	
	
	///
	// Currently only works for shell32.dll version 6.0+.
	final @property void showTextBox(bool byes) // setter
	{
		// BIF_NONEWFOLDERBUTTON exists with shell 6.0+.
		// Might need to enum child windows looking for window title
		// "&New Folder" and hide it, then shift "OK" and "Cancel" over.
		
		if(byes)
			bi.ulFlags |= BIF_EDITBOX;
		else
			bi.ulFlags &= ~BIF_EDITBOX;
	}
	
	/// ditto
	final @property bool showTextBox() const // getter
	{
		return (bi.ulFlags & BIF_EDITBOX) != 0;
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
		
		bi.hwndOwner = owner;
		
		// Using size of wchar so that the buffer works for ansi and unicode.
		//void* pdescz = dfl.internal.clib.alloca(wchar.sizeof * MAX_PATH);
		//if(!pdescz)
		//	throw new DflException("Out of memory"); // Stack overflow ?
		//wchar[MAX_PATH] pdescz = void;
		wchar[MAX_PATH] pdescz; // Initialize because SHBrowseForFolder() is modal.
		
		static if(dfl.internal.utf.useUnicode)
		{
			enum BROWSE_NAME = "SHBrowseForFolderW";
			static SHBrowseForFolderWProc browseproc = null;
			
			if(!browseproc)
			{
				HMODULE hmod;
				hmod = GetModuleHandleA("shell32.dll");
				
				browseproc = cast(SHBrowseForFolderWProc)GetProcAddress(hmod, BROWSE_NAME.ptr);
				if(!browseproc)
					throw new Exception("Unable to load procedure " ~ BROWSE_NAME);
			}
			
			biw.lpszTitle = dfl.internal.utf.toUnicodez(_desc);
			
			{
				LPITEMIDLIST idlist;
				if (SHGetSpecialFolderLocation(owner, cast(int)_root, &idlist) == S_OK)
					biw.pidlRoot = idlist;
				else
					biw.pidlRoot = null;
			}
			scope(exit)
			{
				if (biw.pidlRoot)
					CoTaskMemFree(biw.pidlRoot);
			}
			
			biw.pszDisplayName = cast(wchar*)pdescz;
			if(_desc.length)
			{
				Dwstring tmp;
				tmp = dfl.internal.utf.toUnicode(_desc);
				if(tmp.length >= MAX_PATH)
					_errPathTooLong();
				biw.pszDisplayName[0 .. tmp.length] = tmp[];
				biw.pszDisplayName[tmp.length] = 0;
			}
			else
			{
				biw.pszDisplayName[0] = 0;
			}
			
			// Show the dialog!
			LPITEMIDLIST result;
			result = browseproc(&biw);
			
			if(!result)
			{
				biw.lpszTitle = null;
				return false;
			}
			
			if(NOERROR != SHGetMalloc(&shmalloc))
				_errNoShMalloc();
			
			Dstring wbuf;
			wbuf = shGetPathFromIDList(result);
			if(!wbuf)
			{
				shmalloc.Free(result);
				shmalloc.Release();
				_errNoGetPath();
				assert(0);
			}
			
			_selpath = wbuf;
			
			shmalloc.Free(result);
			shmalloc.Release();
			
			biw.lpszTitle = null;
		}
		else
		{
			bia.lpszTitle = dfl.internal.utf.toAnsiz(_desc);
			
			{
				LPITEMIDLIST idlist;
				if (SHGetSpecialFolderLocation(owner, cast(int)_root, &idlist) == S_OK)
					bia.pidlRoot = idlist;
				else
					bia.pidlRoot = null;
			}
			scope(exit)
			{
				if (bia.pidlRoot)
					CoTaskMemFree(bia.pidlRoot);
			}

			bia.pszDisplayName = cast(char*)pdescz;
			if(_desc.length)
			{
				Dstring tmp; // ansi.
				tmp = dfl.internal.utf.toAnsi(_desc);
				if(tmp.length >= MAX_PATH)
					_errPathTooLong();
				bia.pszDisplayName[0 .. tmp.length] = tmp[];
				bia.pszDisplayName[tmp.length] = 0;
			}
			else
			{
				bia.pszDisplayName[0] = 0;
			}
			
			// Show the dialog!
			LPITEMIDLIST result;
			result = SHBrowseForFolderA(&bia);
			
			if(!result)
			{
				bia.lpszTitle = null;
				return false;
			}
			
			if(NOERROR != SHGetMalloc(&shmalloc))
				_errNoShMalloc();
			
			Dstring abuf;
			abuf = shGetPathFromIDList(result);
			if(!abuf)
			{
				shmalloc.Free(result);
				shmalloc.Release();
				_errNoGetPath();
				assert(0);
			}
			
			_selpath = abuf;
			
			shmalloc.Free(result);
			shmalloc.Release();
			
			bia.lpszTitle = null;
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
		BROWSEINFOW biw;
		alias bi = biw;
	}
	else
	{
		BROWSEINFOA bia;
		alias bi = bia;
	}
	static assert(BROWSEINFOW.sizeof == BROWSEINFOA.sizeof);
	static assert(BROWSEINFOW.ulFlags.offsetof == BROWSEINFOA.ulFlags.offsetof);
	
	Dstring _desc;
	Dstring _selpath;
	Environment.SpecialFolder _root = Environment.SpecialFolder.DESKTOP;
	
	
	enum UINT INIT_FLAGS = BIF_RETURNONLYFSDIRS | BIF_NEWDIALOGSTYLE;
}


// Return type is int.
// Se  https://learn.microsoft.com/en-us/previous-versions/windows/desktop/legacy/bb762598(v=vs.85)
private extern(Windows) int fbdHookProc(HWND hwnd, UINT msg, LPARAM lparam, LPARAM lpData) nothrow
{
	FolderBrowserDialog fd;
	int result = 0;
	
	try
	{
		fd = cast(FolderBrowserDialog)cast(void*)lpData;
		if(fd)
		{
			Dstring s;
			switch(msg)
			{
				case BFFM_INITIALIZED:
					s = fd.selectedPath;
					if(s.length)
					{
						static if(dfl.internal.utf.useUnicode)
							SendMessageW(hwnd, BFFM_SETSELECTIONW, TRUE, cast(LPARAM)dfl.internal.utf.toUnicodez(s));
						else
							SendMessageA(hwnd, BFFM_SETSELECTIONA, TRUE, cast(LPARAM)dfl.internal.utf.toAnsiz(s));
					}
					break;
				
				default:
			}
		}
	}
	catch(DThrowable e)
	{
		Application.onThreadException(e);
	}
	
	return result;
}

