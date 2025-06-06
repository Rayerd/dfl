// Written by Christopher E. Miller
// See the included license.txt for copyright and license details.


///
module dfl.resources;

import dfl.base;
import dfl.drawing;

import dfl.internal.dlib;
import dfl.internal.utf;
import dfl.internal.winapi;

///
class Resources // docmain
{
	///
	this(HINSTANCE inst, WORD language = 0, bool owned = false)
	{
		this._hinst = inst;
		this._lang = language;
		this._owned = owned;
	}
	
	/// ditto
	// NOTE: libName gets unloaded and may take down all its resources with it.
	this(Dstring libName, WORD language = 0)
	{
		HINSTANCE inst = loadLibraryEx(libName, LOAD_LIBRARY_AS_DATAFILE);
		if(!inst)
			throw new DflException("Unable to load resources from '" ~ libName ~ "'");
		this(inst, language, true); // Owned.
	}
	
	/+ // Let's not depend on Application; the user can do so if they wish.
	/// ditto
	this(WORD language = 0)
	{
		this(Application.getInstance(), language);
	}
	+/
	
	
	///
	void dispose()
	{
		assert(_owned);
		//if(hinst != Application.getInstance()) // ?
			FreeLibrary(_hinst);
		_hinst = null;
	}
	
	
	///
	final @property WORD language() // getter
	{
		return _lang;
	}
	
	
	///
	final Icon getIcon(int id, bool defaultSize = true)
	in
	{
		assert(id >= WORD.min && id <= WORD.max);
	}
	do
	{
		/+
		HICON hi;
		hi = LoadIconA(hinst, cast(LPCSTR)cast(WORD)id);
		if(!hi)
			return null;
		return Icon.fromHandle(hi);
		+/
		HICON hi = cast(HICON)LoadImageA(_hinst, cast(LPCSTR)cast(WORD)id, IMAGE_ICON, 0, 0, defaultSize ? (LR_DEFAULTSIZE | LR_SHARED) : 0);
		if(!hi)
			return null;
		return new Icon(hi, true); // Owned.
	}
	
	/// ditto
	final Icon getIcon(Dstring name, bool defaultSize = true)
	{
		/+
		HICON hi;
		hi = LoadIconA(hinst, unsafeStringz(name));
		if(!hi)
			return null;
		return Icon.fromHandle(hi);
		+/
		HICON hi = cast(HICON)dfl.internal.utf.loadImage(_hinst, name, IMAGE_ICON, 0, 0, defaultSize ? (LR_DEFAULTSIZE | LR_SHARED) : 0);
		if(!hi)
			return null;
		return new Icon(hi, true); // Owned.
	}
	
	/// ditto
	final Icon getIcon(int id, int width, int height)
	in
	{
		assert(id >= WORD.min && id <= WORD.max);
	}
	do
	{
		// Can't have size 0 (plus causes Windows to use the actual size).
		//if(width <= 0 || height <= 0)
		//	_noload("icon");
		HICON hi = cast(HICON)LoadImageA(_hinst, cast(LPCSTR)cast(WORD)id, IMAGE_ICON, width, height, 0);
		if(!hi)
			return null;
		return new Icon(hi, true); // Owned.
	}
	
	/// ditto
	final Icon getIcon(Dstring name, int width, int height)
	{
		// Can't have size 0 (plus causes Windows to use the actual size).
		//if(width <= 0 || height <= 0)
		//	_noload("icon");
		HICON hi = cast(HICON)dfl.internal.utf.loadImage(_hinst, name, IMAGE_ICON, width, height, 0);
		if(!hi)
			return null;
		return new Icon(hi, true); // Owned.
	}
	
	deprecated alias loadIcon = getIcon;
	
	
	///
	final Bitmap getBitmap(int id)
	in
	{
		assert(id >= WORD.min && id <= WORD.max);
	}
	do
	{
		HBITMAP h = cast(HBITMAP)LoadImageA(_hinst, cast(LPCSTR)cast(WORD)id, IMAGE_BITMAP, 0, 0, 0);
		if(!h)
			return null;
		return new Bitmap(h, true); // Owned.
	}
	
	/// ditto
	final Bitmap getBitmap(Dstring name)
	{
		HBITMAP h = cast(HBITMAP)loadImage(_hinst, name, IMAGE_BITMAP, 0, 0, 0);
		if(!h)
			return null;
		return new Bitmap(h, true); // Owned.
	}
	
	deprecated alias loadBitmap = getBitmap;
	
	
	///
	final Cursor getCursor(int id)
	in
	{
		assert(id >= WORD.min && id <= WORD.max);
	}
	do
	{
		HCURSOR h = cast(HCURSOR)LoadImageA(_hinst, cast(LPCSTR)cast(WORD)id, IMAGE_CURSOR, 0, 0, 0);
		if(!h)
			return null;
		return new Cursor(h, true); // Owned.
	}
	
	/// ditto
	final Cursor getCursor(Dstring name)
	{
		HCURSOR h = cast(HCURSOR)loadImage(_hinst, name, IMAGE_CURSOR, 0, 0, 0);
		if(!h)
			return null;
		return new Cursor(h, true); // Owned.
	}
	
	deprecated alias loadCursor = getCursor;
	

	///
	final Dstring getString(int id)
	in
	{
		assert(id >= WORD.min && id <= WORD.max);
	}
	do
	{
		// Not casting to wDstring because a resource isn't guaranteed to be the same size.
		wchar* ws = cast(wchar*)_getData(cast(LPCWSTR)RT_STRING, cast(LPCWSTR)cast(WORD)(id / 16 + 1)).ptr;
		Dstring result;
		if(ws)
		{
			int i;
			for(i = 0; i < (id & 15); i++)
			{
				ws += 1 + cast(size_t)*ws;
			}
			result = utf16stringtoUtf8string((ws + 1)[0 .. cast(size_t)*ws]);
		}
		return result;
	}
	
	deprecated alias loadString = getString;
	
	
	// Used internally
	// NOTE: win9x doesn't like these strings to be on the heap!
	final void[] _getData(LPCWSTR type, LPCWSTR name) // internal
	{
		HRSRC hrc = FindResourceExW(_hinst, type, name, _lang);
		if(!hrc)
			return null;
		HGLOBAL hg = LoadResource(_hinst, hrc);
		if(!hg)
			return null;
		LPVOID pv = LockResource(hg);
		if(!pv)
			return null;
		return pv[0 .. SizeofResource(_hinst, hrc)];
	}
	
	///
	final void[] getData(int type, int id)
	in
	{
		assert(type >= WORD.min && type <= WORD.max);
		assert(id >= WORD.min && id <= WORD.max);
	}
	do
	{
		return _getData(cast(LPCWSTR)type, cast(LPCWSTR)id);
	}
	
	/// ditto
	final void[] getData(Dstring type, int id)
	in
	{
		assert(id >= WORD.min && id <= WORD.max);
	}
	do
	{
		return _getData(utf8stringToUtf16stringz(type), cast(LPCWSTR)id);
	}
	
	/// ditto
	final void[] getData(int type, Dstring name)
	in
	{
		assert(type >= WORD.min && type <= WORD.max);
	}
	do
	{
		return _getData(cast(LPCWSTR)type, utf8stringToUtf16stringz(name));
	}
	
	/// ditto
	final void[] getData(Dstring type, Dstring name)
	{
		return _getData(utf8stringToUtf16stringz(type), utf8stringToUtf16stringz(name));
	}
	
	
	~this()
	{
		if(_owned)
			dispose();
	}
	
	
private:
	
	HINSTANCE _hinst;
	WORD _lang = 0;
	bool _owned = false;
	
	
	void _noload(Dstring type)
	{
		throw new DflException("Unable to load " ~ type ~ " resource");
	}
}

