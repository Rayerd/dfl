// Written by Christopher E. Miller
// See the included license.txt for copyright and license details.


///
module dfl.folderdialog;

private import dfl.internal.dlib, dfl.internal.clib;

private import dfl.commondialog, dfl.base, dfl.internal.winapi, dfl.internal.wincom;
private import dfl.internal.utf, dfl.application;


private extern(Windows) nothrow
{
	alias LPITEMIDLIST function(LPBROWSEINFOW lpbi) SHBrowseForFolderWProc;
	alias BOOL function(LPCITEMIDLIST pidl, LPWSTR pszPath) SHGetPathFromIDListWProc;
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
	
	
	override DialogResult showDialog(IWindow owner)
	{
		if(!runDialog(owner ? owner.handle : GetActiveWindow()))
			return DialogResult.CANCEL;
		return DialogResult.OK;
	}
	
	
	override void reset()
	{
		bi.ulFlags = INIT_FLAGS;
		_desc = null;
		_selpath = null;
	}
	
	
	///
	final @property void description(Dstring desc) // setter
	{
		// lpszTitle
		
		_desc = desc;
	}
	
	/// ditto
	final @property Dstring description() // getter
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
	final @property Dstring selectedPath() // getter
	{
		return _selpath;
	}
	
	
	// ///
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
	
	// /// ditto
	final @property bool showNewFolderButton() // getter
	{
		return (bi.ulFlags & BIF_NONEWFOLDERBUTTON) == 0;
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
		
		if(dfl.internal.utf.useUnicode)
		{
			enum BROWSE_NAME = "SHBrowseForFolderW";
			enum PATH_NAME = "SHGetPathFromIDListW";
			static SHBrowseForFolderWProc browseproc = null;
			static SHGetPathFromIDListWProc pathproc = null;
			
			if(!browseproc)
			{
				HMODULE hmod;
				hmod = GetModuleHandleA("shell32.dll");
				
				browseproc = cast(SHBrowseForFolderWProc)GetProcAddress(hmod, BROWSE_NAME.ptr);
				if(!browseproc)
					throw new Exception("Unable to load procedure " ~ BROWSE_NAME);
				
				pathproc = cast(SHGetPathFromIDListWProc)GetProcAddress(hmod, PATH_NAME.ptr);
				if(!pathproc)
					throw new Exception("Unable to load procedure " ~ PATH_NAME);
			}
			
			biw.lpszTitle = dfl.internal.utf.toUnicodez(_desc);
			
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
			
			//wchar* wbuf = cast(wchar*)dfl.internal.clib.alloca(wchar.sizeof * MAX_PATH);
			wchar[MAX_PATH] wbuf = void;
			if(!pathproc(result, wbuf.ptr))
			{
				shmalloc.Free(result);
				shmalloc.Release();
				_errNoGetPath();
				assert(0);
			}
			
			_selpath = dfl.internal.utf.fromUnicodez(wbuf.ptr); // Assumes fromUnicodez() copies.
			
			shmalloc.Free(result);
			shmalloc.Release();
			
			biw.lpszTitle = null;
		}
		else
		{
			bia.lpszTitle = dfl.internal.utf.toAnsiz(_desc);
			
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
			
			//char* abuf = cast(char*)dfl.internal.clib.alloca(char.sizeof * MAX_PATH);
			char[MAX_PATH] abuf = void;
			if(!SHGetPathFromIDListA(result, abuf.ptr))
			{
				shmalloc.Free(result);
				shmalloc.Release();
				_errNoGetPath();
				assert(0);
			}
			
			_selpath = dfl.internal.utf.fromAnsiz(abuf.ptr); // Assumes fromAnsiz() copies.
			
			shmalloc.Free(result);
			shmalloc.Release();
			
			bia.lpszTitle = null;
		}
		
		return true;
	}
	
	
	protected:
	
	/+
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
						/+
						case CDN_FILEOK:
							break;
						+/
						
						default:
					}
				}
				break;
			
			default:
		}
		
		return super.hookProc(hwnd, msg, wparam, lparam);
	}
	+/
	
	
	private:
	
	union
	{
		BROWSEINFOW biw;
		BROWSEINFOA bia;
		alias biw bi;
		
		static assert(BROWSEINFOW.sizeof == BROWSEINFOA.sizeof);
		static assert(BROWSEINFOW.ulFlags.offsetof == BROWSEINFOA.ulFlags.offsetof);
	}
	
	Dstring _desc;
	Dstring _selpath;
	
	
	enum UINT INIT_FLAGS = BIF_RETURNONLYFSDIRS | BIF_NEWDIALOGSTYLE;
}


private:

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
						if(dfl.internal.utf.useUnicode)
							SendMessageA(hwnd, BFFM_SETSELECTIONW, TRUE, cast(LPARAM)dfl.internal.utf.toUnicodez(s));
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

