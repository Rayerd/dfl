// Written by Christopher E. Miller
// See the included license.txt for copyright and license details.


///
module dfl.folderdialog;

import dfl.application;
import dfl.base;
import dfl.commondialog;
import dfl.environment;

import dfl.internal.clib;
import dfl.internal.com;
import dfl.internal.dlib;
import dfl.internal.utf;
import dfl.internal.winapi : LPITEMIDLIST, LPBROWSEINFOW, BROWSEINFOW, BROWSEINFOA, BIF_RETURNONLYFSDIRS, BIF_NEWDIALOGSTYLE,
	BIF_NONEWFOLDERBUTTON, BIF_EDITBOX, SHGetSpecialFolderLocation, CoTaskMemFree, SHGetMalloc, BFFM_INITIALIZED, BFFM_SETSELECTIONW;

import core.sys.windows.basetyps : REFIID;
import core.sys.windows.objidl;
import core.sys.windows.winbase;
import core.sys.windows.windef;
import core.sys.windows.winuser;
import core.sys.windows.com;
import core.sys.windows.objbase;

import std.conv;


///
class FolderBrowserDialog: CommonDialog // docmain
{
	/// Creates a new instance of the FolderBrowserDialog class.
	/// If autoUpgradeEnabled is true, the dialog will use the modern folder browser dialog if available,
	/// otherwise it will use the legacy folder browser dialog.
	this(bool autoUpgradeEnabled = true)
	{
		_autoUpgradeEnabled = autoUpgradeEnabled;

		if (autoUpgradeEnabled)
			_strategy = new ModernFolderBrowserStrategy();
		else
			_strategy = new LegacyFolderBrowserStrategy();
	}
	
	
	///
	override DialogResult showDialog()
	{
		return _strategy.showDialog();
	}
	
	/// ditto
	override DialogResult showDialog(IWindow owner)
	{
		return _strategy.showDialog(owner);
	}
	
	
	///
	override void reset()
	{
		_strategy.reset();
	}
	
	
	///
	final @property void description(Dstring desc) // setter
	{
		_strategy.description = desc;
	}
	
	/// ditto
	final @property Dstring description() const // getter
	{
		return _strategy.description;
	}
	
	
	///
	final @property void selectedPath(Dstring selpath) // setter
	{
		_strategy.selectedPath = selpath;
	}
	
	/// ditto
	final @property Dstring selectedPath() const // getter
	{
		return _strategy.selectedPath;
	}
	
	
	///
	// Currently only works for shell32.dll version 6.0+.
	final @property void showNewFolderButton(bool byes) // setter
	{
		_strategy.showNewFolderButton = byes;
	}
	
	/// ditto
	final @property bool showNewFolderButton() const // getter
	{
		return _strategy.showNewFolderButton();
	}
	
	
	///
	// Currently only works for shell32.dll version 6.0+.
	final @property void showNewStyleDialog(bool byes) // setter
	{
		_strategy.showNewStyleDialog = byes;
	}
	
	/// ditto
	final @property bool showNewStyleDialog() const // getter
	{
		return _strategy.showNewStyleDialog();
	}
	
	
	///
	// Currently only works for shell32.dll version 6.0+.
	final @property void showTextBox(bool byes) // setter
	{
		_strategy.showTextBox = byes;
	}
	
	/// ditto
	final @property bool showTextBox() const // getter
	{
		return _strategy.showTextBox();
	}
	
	
	///
	final @property void rootFolder(Environment.SpecialFolder root) // setter
	{
		_strategy.rootFolder = root;
	}

	/// ditto
	final @property Environment.SpecialFolder rootFolder() const // getter
	{
		return _strategy.rootFolder;
	}


	protected override bool runDialog(HWND owner)
	{
		return _strategy.runDialog(owner);
	}
	
	
	///
	final @property bool autoUpgradeEnabled() const // getter
	{
		return _autoUpgradeEnabled;
	}

	
private:

	IFolderBrowserStrategy _strategy;
	bool _autoUpgradeEnabled;
}


// Return type is int.
// See https://learn.microsoft.com/en-us/previous-versions/windows/desktop/legacy/bb762598(v=vs.85)
private extern(Windows) int _fbdHookProc(HWND hwnd, UINT msg, LPARAM lparam, LPARAM lpData) nothrow
{
	
	int result = 0;
	try
	{
		LegacyFolderBrowserStrategy fd = cast(LegacyFolderBrowserStrategy)cast(void*)lpData;
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


private:


///
interface IFolderBrowserStrategy
{
	DialogResult showDialog();
	DialogResult showDialog(IWindow owner);
	void reset();
	@property void description(Dstring desc); // setter
	@property Dstring description() const; // getter
	@property void selectedPath(Dstring selpath); // setter
	@property Dstring selectedPath() const; // getter
	@property void showNewFolderButton(bool byes); // setter
	@property bool showNewFolderButton() const; // getter
	@property void showNewStyleDialog(bool byes); // setter
	@property bool showNewStyleDialog() const; // getter
	@property void showTextBox(bool byes); // setter
	@property bool showTextBox() const; // getter
	@property void rootFolder(Environment.SpecialFolder root); // setter
	@property Environment.SpecialFolder rootFolder() const; // getter
	bool runDialog(HWND owner);
}


extern(Windows) nothrow
{
	alias SHBrowseForFolderWProc = LPITEMIDLIST function(LPBROWSEINFOW lpbi);
}


///
class LegacyFolderBrowserStrategy : CommonDialog, IFolderBrowserStrategy
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
		return showDialog(cast(IWindow)null);
	}
	
	
	/// ditto
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


extern(C) extern const IID IID_IModalWindow;


// uuid("b4db1657-70d7-485e-8e3e-6fcb5a5c1802")
interface IModalWindow : IUnknown
{
extern (Windows):
	HRESULT Show(HWND hwndOwner);
}


extern(C) extern const IID IID_IFileDialog;


// uuid("42f85136-db7e-439c-85f1-e4075d135fc8")
interface IFileDialog : IModalWindow
{
extern (Windows):
	HRESULT SetFileTypes(); //(UINT cFileTypes, const COMDLG_FILTERSPEC* rgFilterSpec);
	HRESULT SetFileTypeIndex(); //(UINT iFileType);
	HRESULT GetFileTypeIndex(); //(UINT* piFileType);
	HRESULT Advise(); //(IFileDialogEvents pfde, DWORD* pdwCookie);
	HRESULT Unadvise(); //(DWORD dwCookie);
	HRESULT SetOptions(FILEOPENDIALOGOPTIONS fos);
	HRESULT GetOptions(FILEOPENDIALOGOPTIONS* pfos);
	HRESULT SetDefaultFolder(IShellItem psi);
	HRESULT SetFolder(IShellItem psi);
	HRESULT GetFolder(); //(IShellItem* ppsi);
	HRESULT GetCurrentSelection(); //(IShellItem* ppsi);
	HRESULT SetFileName(); //(LPCWSTR pszName);
	HRESULT GetFileName(); //(LPWSTR pszName);
	HRESULT SetTitle(LPCWSTR pszTitle);
	HRESULT SetOkButtonLabel(); //(LPCWSTR pszText);
	HRESULT SetFileNameLabel(); //(LPCWSTR pszLabel);
	HRESULT GetResult(IShellItem* ppsi);
	HRESULT AddPlace(); //(IShellItem psi, FDAP fdap);
	HRESULT SetDefaultExtension(); //(LPCWSTR pszDefaultExtension);
	HRESULT Close(); //(HRESULT hr);
	HRESULT SetClientGuid(); //(REFGUID guid);
	HRESULT ClearClientData();
	HRESULT SetFilter(); //(IShellItemFilter pFilter);
}


///
enum FILEOPENDIALOGOPTIONS : DWORD
{
	FOS_OVERWRITEPROMPT = 0x2,
	FOS_STRICTFILETYPES = 0x4,
	FOS_NOCHANGEDIR = 0x8,
	FOS_PICKFOLDERS = 0x20,
	FOS_FORCEFILESYSTEM = 0x40,
	FOS_ALLNONSTORAGEITEMS = 0x80,
	FOS_NOVALIDATE = 0x100,
	FOS_ALLOWMULTISELECT = 0x200,
	FOS_PATHMUSTEXIST = 0x800,
	FOS_FILEMUSTEXIST = 0x1000,
	FOS_CREATEPROMPT = 0x2000,
	FOS_SHAREAWARE = 0x4000,
	FOS_NOREADONLYRETURN = 0x8000,
	FOS_NOTESTFILECREATE = 0x10000,
	FOS_HIDEMRUPLACES = 0x20000,
	FOS_HIDEPINNEDPLACES = 0x40000,
	FOS_NODEREFERENCELINKS = 0x100000,
	FOS_OKBUTTONNEEDSINTERACTION = 0x200000,
	FOS_DONTADDTORECENT = 0x2000000,
	FOS_FORCESHOWHIDDEN = 0x10000000,
	FOS_DEFAULTNOMINIMODE = 0x20000000,
	FOS_FORCEPREVIEWPANEON = 0x40000000,
	FOS_SUPPORTSTREAMABLEITEMS = 0x80000000
}


extern(C) extern const IID IID_IFileOpenDialog;


// uuid("d57c7288-d4ad-4768-be02-9d969532d960")
interface IFileOpenDialog : IFileDialog
{
extern (Windows):
	HRESULT GetResults(); //(IShellItemArray* ppenum);
	HRESULT GetSelectedItems(); //(IShellItemArray* ppsai);
}


extern(C) extern const IID IID_IShellItem;


// uuid("43826d1e-e718-42ee-bc55-a1e261c37bfe")
interface IShellItem : IUnknown
{
extern(Windows):
	HRESULT BindToHandler(); //(IBindCtx pbc, REFGUID bhid, REFIID riid, void** ppv);
	HRESULT GetParent(); //(IShellItem* ppsi);
	HRESULT GetDisplayName(SIGDN sigdnName, LPWSTR* ppszName);
	HRESULT GetAttributes(); //(SFGAOF sfgaoMask, SFGAOF* psfgaoAttribs);
	HRESULT Compare(); //(IShellItem psi, SICHINTF hint, int* piOrder);
}


///
enum SIGDN : int
{
	SIGDN_NORMALDISPLAY = 0,
	SIGDN_PARENTRELATIVEPARSING = 0x80018001,
	SIGDN_DESKTOPABSOLUTEPARSING = 0x80028000,
	SIGDN_PARENTRELATIVEEDITING = 0x80031001,
	SIGDN_DESKTOPABSOLUTEEDITING = 0x8004c000,
	SIGDN_FILESYSPATH = 0x80058000,
	SIGDN_URL = 0x80068000,
	SIGDN_PARENTRELATIVEFORADDRESSBAR = 0x8007c001,
	SIGDN_PARENTRELATIVE = 0x80080001,
	SIGDN_PARENTRELATIVEFORUI = 0x80094001
}


extern(C) extern const CLSID CLSID_FileOpenDialog;

extern(C) extern const IID IID_IShellItem2;


///
struct PROPERTYKEY
{
	GUID fmtid;
	DWORD pid;
}

alias REFPROPERTYKEY = PROPERTYKEY*;


// uuid("7e9fb0d3-919f-4307-ab2e-9b1860310c93")
interface IShellItem2 : IShellItem
{
extern (Windows):
	HRESULT GetPropertyStore(); //(GETPROPERTYSTOREFLAGS flags, REFIID riid, void **ppv);
	HRESULT GetPropertyStoreWithCreateObject(); //(GETPROPERTYSTOREFLAGS flags, IUnknown *punkCreateObject, REFIID riid, void **ppv);
	HRESULT GetPropertyStoreForKeys(); //(const PROPERTYKEY *rgKeys, UINT cKeys, GETPROPERTYSTOREFLAGS flags, REFIID riid, void **ppv);
	HRESULT GetPropertyDescriptionList(); //(REFPROPERTYKEY keyType, REFIID riid, void **ppv);
	HRESULT Update(); //(IBindCtx *pbc);
	HRESULT GetProperty(); //(REFPROPERTYKEY key, PROPVARIANT *ppropvar);
	HRESULT GetCLSID(); //(REFPROPERTYKEY key, CLSID *pclsid);
	HRESULT GetFileTime(REFPROPERTYKEY key, FILETIME* pft);
	HRESULT GetInt32(); //(REFPROPERTYKEY key, int *pi);
	HRESULT GetString(); //(REFPROPERTYKEY key, LPWSTR *ppsz);
	HRESULT GetUInt32(); //(REFPROPERTYKEY key, ULONG *pui);
	HRESULT GetUInt64(); //(REFPROPERTYKEY key, ULONGLONG *pull);
	HRESULT GetBool(); //(REFPROPERTYKEY key, BOOL *pf);
}


const PROPERTYKEY PKEY_DateCreated = {
	{0xB725F130, 0x47EF, 0x101A, [0xA5, 0xF1, 0x02, 0x60, 0x8C, 0x9E, 0xEB, 0xAC]}, 15
};


alias KNOWNFOLDERID = GUID;
alias REFKNOWNFOLDERID = const(KNOWNFOLDERID)*;


///
enum KNOWN_FOLDER_FLAG
{
	KF_FLAG_DEFAULT = 0x00000000,
	KF_FLAG_FORCE_APP_DATA_REDIRECTION = 0x00080000,
	KF_FLAG_RETURN_FILTER_REDIRECTION_TARGET = 0x00040000,
	KF_FLAG_FORCE_PACKAGE_REDIRECTION = 0x00020000,
	KF_FLAG_NO_PACKAGE_REDIRECTION = 0x00010000,
	KF_FLAG_FORCE_APPCONTAINER_REDIRECTION = 0x00020000,
	KF_FLAG_NO_APPCONTAINER_REDIRECTION = 0x00010000,
	KF_FLAG_CREATE = 0x00008000,
	KF_FLAG_DONT_VERIFY = 0x00004000,
	KF_FLAG_DONT_UNEXPAND = 0x00002000,
	KF_FLAG_NO_ALIAS = 0x00001000,
	KF_FLAG_INIT = 0x00000800,
	KF_FLAG_DEFAULT_PATH = 0x00000400,
	KF_FLAG_NOT_PARENT_RELATIVE = 0x00000200,
	KF_FLAG_SIMPLE_IDLIST = 0x00000100,
	KF_FLAG_ALIAS_ONLY = 0x80000000
}


extern(Windows)
{
extern:
	///
	HRESULT SHGetKnownFolderPath(REFKNOWNFOLDERID rfid, DWORD dwFlags, HANDLE hToken, PWSTR* ppszPath);
	///
	HRESULT SHGetKnownFolderItem(REFKNOWNFOLDERID rfid, KNOWN_FOLDER_FLAG flags, HANDLE hToken, REFIID riid, void** ppv);
	///
	HRESULT SHCreateItemFromParsingName(PCWSTR pszPath, IBindCtx* pbc, REFIID riid, void** ppv);
}


///
class ModernFolderBrowserStrategy : IFolderBrowserStrategy
{
	///
	override DialogResult showDialog()
	{
		return showDialog(cast(IWindow)null);
	}
	
	/// ditto
	override DialogResult showDialog(IWindow owner)
	{
		if (!runDialog(owner ? owner.handle : GetActiveWindow()))
			return DialogResult.CANCEL;
		return DialogResult.OK;
	}
	
	
	///
	override void reset()
	{
		_selectedPath = "";
		_description = "";
 	}
	
	
	///
	final @property void description(Dstring desc) // setter
	{
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
		_selectedPath = selpath;
	}
	
	/// ditto
	final @property Dstring selectedPath() const // getter
	{
		return _selectedPath;
	}
	
	
	///
	final @property void showNewFolderButton(bool byes) // setter
	{
		// Do nothig. The modern folder browser dialog always shows the new folder button.
	}
	
	/// ditto
	final @property bool showNewFolderButton() const // getter
	{
		// Do nothig. The modern folder browser dialog always shows the new folder button.
		throw new DflException("The modern folder browser dialog does not support.");
	}
	
	
	///
	final @property void showNewStyleDialog(bool byes) // setter
	{
		// Do nothig. The modern folder browser dialog always shows the new style dialog.
	}
	
	/// ditto
	final @property bool showNewStyleDialog() const // getter
	{
		// Do nothig. The modern folder browser dialog always shows the new style dialog.
		throw new DflException("The modern folder browser dialog does not support.");
	}
	
	
	///
	final @property void showTextBox(bool byes) // setter
	{
		// Do nothig. The modern folder browser dialog always shows the text box.
	}
	
	/// ditto
	final @property bool showTextBox() const // getter
	{
		// Do nothig. The modern folder browser dialog always shows the text box.
		throw new DflException("The modern folder browser dialog does not support.");
	}
	
	
	///
	final @property void rootFolder(Environment.SpecialFolder root) // setter
	{
		// Do nothing. The modern folder browser dialog does not support changing the root folder.
	}

	/// ditto
	final @property Environment.SpecialFolder rootFolder() const // getter
	{
		// Do nothing. The modern folder browser dialog does not support changing the root folder.
		throw new DflException("The modern folder browser dialog does not support.");
	}
	
	
	protected override bool runDialog(HWND owner)
	{
		HRESULT hr;

		ComPtr!IFileOpenDialog fileOpenDialog;
		hr = CoCreateInstance(&CLSID_FileOpenDialog, null, CLSCTX_INPROC_SERVER, &IID_IFileOpenDialog, cast(void**)fileOpenDialog.ptr);
		if (FAILED(hr)) return false;

		FILEOPENDIALOGOPTIONS opt;
		fileOpenDialog.GetOptions(&opt);
		with (FILEOPENDIALOGOPTIONS)
			fileOpenDialog.SetOptions(opt | FOS_PICKFOLDERS);
		
		ComPtr!IFileDialog fileDialog = fileOpenDialog.as!IFileDialog(&IID_IFileDialog);
		LPCWSTR title = dfl.internal.utf.toUnicodez(_description);
		hr = fileDialog.SetTitle(title);
		if (FAILED(hr)) return false;

		if (_selectedPath.length)
		{
			ComPtr!IShellItem shItem;
			PCWSTR path = dfl.internal.utf.toUnicodez(_selectedPath);
			hr = SHCreateItemFromParsingName(path, null, &IID_IShellItem, cast(void**)shItem.ptr);
			if (FAILED(hr)) return false;
			fileDialog.SetFolder(shItem.handle);
		}
		else
		{
			ComPtr!IShellItem shItem;
			REFKNOWNFOLDERID kfid = _specialFolderToKnownFolder(Environment.SpecialFolder.MY_COMPUTER);
			if (kfid)
			{
				hr = SHGetKnownFolderItem(kfid, KNOWN_FOLDER_FLAG.KF_FLAG_DEFAULT, null, &IID_IShellItem, cast(void**)shItem.ptr);
				if (FAILED(hr)) return false;
				fileDialog.SetDefaultFolder(shItem.handle);
			}
		}

		hr = fileOpenDialog.Show(null);
		if (FAILED(hr)) return false;

		ComPtr!IShellItem shItem;
		hr = fileOpenDialog.GetResult(shItem.ptr);
		if (FAILED(hr)) return false;

		LPWSTR outPath;
		hr = shItem.GetDisplayName(SIGDN.SIGDN_FILESYSPATH, &outPath);
		if (FAILED(hr)) return false;
		scope(exit) CoTaskMemFree(outPath);

		_selectedPath = to!Dstring(outPath);

		return true;
	}


private:

	Dstring _selectedPath;
	Dstring _description;
}


// https://learn.microsoft.com/ja-jp/windows/win32/shell/knownfolderid
extern(Windows)
{
__gshared:
extern:
	const KNOWNFOLDERID FOLDERID_Desktop;
	const KNOWNFOLDERID FOLDERID_Programs;
	const KNOWNFOLDERID FOLDERID_Documents;
	const KNOWNFOLDERID FOLDERID_Pictures;
	const KNOWNFOLDERID FOLDERID_Music;
	const KNOWNFOLDERID FOLDERID_Videos;
	const KNOWNFOLDERID FOLDERID_Favorites;
	const KNOWNFOLDERID FOLDERID_Startup;
	const KNOWNFOLDERID FOLDERID_Recent;
	const KNOWNFOLDERID FOLDERID_SendTo;
	const KNOWNFOLDERID FOLDERID_StartMenu;
	const KNOWNFOLDERID FOLDERID_ComputerFolder;
	const KNOWNFOLDERID FOLDERID_NetHood;
	const KNOWNFOLDERID FOLDERID_Fonts;
	const KNOWNFOLDERID FOLDERID_Templates;
	const KNOWNFOLDERID FOLDERID_CommonStartMenu;
	const KNOWNFOLDERID FOLDERID_CommonPrograms;
	const KNOWNFOLDERID FOLDERID_CommonStartup;
	const KNOWNFOLDERID FOLDERID_CommonDesktopDirectory;
	const KNOWNFOLDERID FOLDERID_RoamingAppData;
	const KNOWNFOLDERID FOLDERID_LocalAppData;
	const KNOWNFOLDERID FOLDERID_ProgramData;
	const KNOWNFOLDERID FOLDERID_InternetCache;
	const KNOWNFOLDERID FOLDERID_Cookies;
	const KNOWNFOLDERID FOLDERID_History;
	const KNOWNFOLDERID FOLDERID_System;
	const KNOWNFOLDERID FOLDERID_SystemX86;
	const KNOWNFOLDERID FOLDERID_ProgramFiles;
	const KNOWNFOLDERID FOLDERID_ProgramFilesX86;
	const KNOWNFOLDERID FOLDERID_ProgramFilesCommon;
	const KNOWNFOLDERID FOLDERID_ProgramFilesCommonX86;
	const KNOWNFOLDERID FOLDERID_AdminTools;
	const KNOWNFOLDERID FOLDERID_CommonAdminTools;
	const KNOWNFOLDERID FOLDERID_PrintHood;
	const KNOWNFOLDERID FOLDERID_Profile;
	const KNOWNFOLDERID FOLDERID_CommonTemplates;
	const KNOWNFOLDERID FOLDERID_PublicDesktop;
	const KNOWNFOLDERID FOLDERID_PublicDocuments;
	const KNOWNFOLDERID FOLDERID_PublicPictures;
	const KNOWNFOLDERID FOLDERID_PublicMusic;
	const KNOWNFOLDERID FOLDERID_PublicVideos;
	const KNOWNFOLDERID FOLDERID_ResourceDir;
	const KNOWNFOLDERID FOLDERID_LocalizedResourcesDir;
	const KNOWNFOLDERID FOLDERID_CommonOEMLinks;
	const KNOWNFOLDERID FOLDERID_CDBurning;
}


///
REFKNOWNFOLDERID _specialFolderToKnownFolder(Environment.SpecialFolder folder)
{
	with (Environment)
	{
		final switch (folder)
		{
		case SpecialFolder.DESKTOP:
			return &FOLDERID_Desktop;

		case SpecialFolder.PROGRAMS:
			return &FOLDERID_ProgramFiles;

		case SpecialFolder.MY_DOCUMENTS:
		// case SpecialFolder.PERSONAL: // Same as MY_DOCUMENTS.
			return &FOLDERID_Documents;
		
		case SpecialFolder.FAVORITES:
			return &FOLDERID_Favorites;

		case SpecialFolder.STARTUP:
			return &FOLDERID_Startup;

		case SpecialFolder.RECENT:
			return &FOLDERID_Recent;

		case SpecialFolder.SEND_TO:
			return &FOLDERID_SendTo;

		case SpecialFolder.START_MENU:
			return &FOLDERID_StartMenu;

		case SpecialFolder.MY_MUSIC:
			 return &FOLDERID_Music;

		case SpecialFolder.MY_VIDEOS:
			 return &FOLDERID_Videos;

		case SpecialFolder.DESKTOP_DIRECTORY:
			return &FOLDERID_Desktop;

		case SpecialFolder.MY_COMPUTER:
			return &FOLDERID_ComputerFolder;

		case SpecialFolder.NETWORK_SHORTCUTS:
			return &FOLDERID_NetHood;

		case SpecialFolder.FONTS:
			return &FOLDERID_Fonts;

		case SpecialFolder.TEMPLATES:
			return &FOLDERID_Templates;

		case SpecialFolder.COMMON_START_MENU:
			return &FOLDERID_CommonStartMenu;

		case SpecialFolder.COMMON_PROGRAMS:
			return &FOLDERID_CommonPrograms;

		case SpecialFolder.COMMON_STARTUP:
			return &FOLDERID_CommonStartup;

		case SpecialFolder.COMMON_DESKTOP_DIRECTORY:
			return &FOLDERID_PublicDesktop;

		case SpecialFolder.APPLICATION_DATA:
			return &FOLDERID_RoamingAppData;

		case SpecialFolder.PRINTER_SHORTCUTS:
			return &FOLDERID_PrintHood;

		case SpecialFolder.LOCAL_APPLICATION_DATA:
			return &FOLDERID_LocalAppData;

		case SpecialFolder.INTERNET_CACHE:
			return &FOLDERID_InternetCache;

		case SpecialFolder.COOKIES:
			return &FOLDERID_Cookies;

		case SpecialFolder.HISTORY:
			return &FOLDERID_History;

		case SpecialFolder.COMMON_APPLICATION_DATA:
			return &FOLDERID_ProgramData;

		case SpecialFolder.WINDOWS:
			return &FOLDERID_System;

		case SpecialFolder.SYSTEM:
			return &FOLDERID_System;

		case SpecialFolder.PROGRAM_FILES:
			return &FOLDERID_ProgramFiles;

		case SpecialFolder.MY_PICTURES:
			return &FOLDERID_Pictures;

		case SpecialFolder.USERT_PROFILE:
			return &FOLDERID_Profile;

		case SpecialFolder.SYSTEM_X86:
			return &FOLDERID_SystemX86;

		case SpecialFolder.PROGRAM_FILES_X86:
			return &FOLDERID_ProgramFilesX86;

		case SpecialFolder.COMMON_PROGRAM_FILES:
			return &FOLDERID_ProgramFilesCommon;

		case SpecialFolder.COMMON_PROGRAM_FILES_X86:
			return &FOLDERID_ProgramFilesCommonX86;

		case SpecialFolder.COMMON_TEMPLATES:
			return &FOLDERID_CommonTemplates;

		case SpecialFolder.COMMON_DOCUMENTS:
			return &FOLDERID_PublicDocuments;

		case SpecialFolder.COMMON_ADMIN_TOOLS:
			return &FOLDERID_CommonAdminTools;

		case SpecialFolder.ADMIN_TOOLS:
			return &FOLDERID_AdminTools;

		case SpecialFolder.COMMON_MUSIC:
			return &FOLDERID_PublicMusic;

		case SpecialFolder.COMMON_PICTURES:
			return &FOLDERID_PublicPictures;

		case SpecialFolder.COMMON_VIDEOS:
			return &FOLDERID_PublicVideos;

		case SpecialFolder.RESOURCES:
			return &FOLDERID_ResourceDir;

		case SpecialFolder.LOCALIZED_RESOURCES:
			return &FOLDERID_LocalizedResourcesDir;

		case SpecialFolder.COMMON_OEM_LINKS:
			return &FOLDERID_CommonOEMLinks;

		case SpecialFolder.CD_BURNING:
			return &FOLDERID_CDBurning;
		
		// default:
		// 	return null; // Unknown special folder.
		}
	}
}
