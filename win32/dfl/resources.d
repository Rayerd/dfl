// Written by Christopher E. Miller
// See the included license.txt for copyright and license details.


///
module dfl.resources;

private import dfl.internal.dlib;

private import dfl.internal.utf, dfl.internal.winapi, dfl.base, dfl.drawing;


///
class Resources // docmain
{
	///
	this(HINSTANCE inst, WORD language = 0, bool owned = false)
	{
		this.hinst = inst;
		this.lang = language;
		this._owned = owned;
	}
	
	/// ditto
	// Note: libName gets unloaded and may take down all its resources with it.
	this(char[] libName, WORD language = 0)
	{
		HINSTANCE inst;
		inst = loadLibraryEx(libName, LOAD_LIBRARY_AS_DATAFILE);
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
		//if(hinst != Application.getInstance()) // ?
			FreeLibrary(hinst);
		hinst = null;
	}
	
	
	///
	final WORD language() // getter
	{
		return lang;
	}
	
	
	///
	final Icon getIcon(int id, bool defaultSize = true)
	in
	{
		assert(id >= WORD.min && id <= WORD.max);
	}
	body
	{
		/+
		HICON hi;
		hi = LoadIconA(hinst, cast(LPCSTR)cast(WORD)id);
		if(!hi)
			return null;
		return Icon.fromHandle(hi);
		+/
		HICON hi;
		hi = cast(HICON)LoadImageA(hinst, cast(LPCSTR)cast(WORD)id, IMAGE_ICON,
			0, 0, defaultSize ? (LR_DEFAULTSIZE | LR_SHARED) : 0);
		if(!hi)
			return null;
		return new Icon(hi, true); // Owned.
	}
	
	/// ditto
	final Icon getIcon(char[] name, bool defaultSize = true)
	{
		/+
		HICON hi;
		hi = LoadIconA(hinst, unsafeStringz(name));
		if(!hi)
			return null;
		return Icon.fromHandle(hi);
		+/
		HICON hi;
		hi = cast(HICON)dfl.internal.utf.loadImage(hinst, name, IMAGE_ICON,
			0, 0, defaultSize ? (LR_DEFAULTSIZE | LR_SHARED) : 0);
		if(!hi)
			return null;
		return new Icon(hi, true); // Owned.
	}
	
	/+
	/// ditto
	final Icon getIcon(int id, int width, int height)
	in
	{
		assert(id >= WORD.min && id <= WORD.max);
	}
	body
	{
		// Can't have size 0 (plus causes Windows to use the actual size).
		//if(width <= 0 || height <= 0)
		//	_noload("icon");
		HICON hi;
		hi = cast(HICON)LoadImageA(hinst, cast(LPCSTR)cast(WORD)id, IMAGE_ICON,
			width, height, 0);
		if(!hi)
			return null;
		return new Icon(hi, true); // Owned.
	}
	
	/// ditto
	final Icon getIcon(char[] name, int width, int height)
	{
		// Can't have size 0 (plus causes Windows to use the actual size).
		//if(width <= 0 || height <= 0)
		//	_noload("icon");
		HICON hi;
		hi = cast(HICON)dfl.internal.utf.loadImage(hinst, name, IMAGE_ICON,
			width, height, 0);
		if(!hi)
			return null;
		return new Icon(hi, true); // Owned.
	}
	+/
	
	deprecated alias getIcon loadIcon;
	
	
	///
	final Bitmap getBitmap(int id)
	in
	{
		assert(id >= WORD.min && id <= WORD.max);
	}
	body
	{
		HBITMAP h;
		h = cast(HBITMAP)LoadImageA(hinst, cast(LPCSTR)cast(WORD)id, IMAGE_BITMAP,
			0, 0, 0);
		if(!h)
			return null;
		return new Bitmap(h, true); // Owned.
	}
	
	/// ditto
	final Bitmap getBitmap(char[] name)
	{
		HBITMAP h;
		h = cast(HBITMAP)loadImage(hinst, name, IMAGE_BITMAP,
			0, 0, 0);
		if(!h)
			return null;
		return new Bitmap(h, true); // Owned.
	}
	
	deprecated alias getBitmap loadBitmap;
	
	
	///
	final Cursor getCursor(int id)
	in
	{
		assert(id >= WORD.min && id <= WORD.max);
	}
	body
	{
		HCURSOR h;
		h = cast(HCURSOR)LoadImageA(hinst, cast(LPCSTR)cast(WORD)id, IMAGE_CURSOR,
			0, 0, 0);
		if(!h)
			return null;
		return new Cursor(h, true); // Owned.
	}
	
	/// ditto
	final Cursor getCursor(char[] name)
	{
		HCURSOR h;
		h = cast(HCURSOR)loadImage(hinst, name, IMAGE_CURSOR,
			0, 0, 0);
		if(!h)
			return null;
		return new Cursor(h, true); // Owned.
	}
	
	deprecated alias getCursor loadCursor;
	
	
	///
	final char[] getString(int id)
	in
	{
		assert(id >= WORD.min && id <= WORD.max);
	}
	body
	{
		HRSRC hrc;
		hrc = FindResourceExA(hinst, RT_STRING, cast(LPCSTR)cast(WORD)(id / 16 + 1), lang);
		if(!hrc)
			return null;
		HGLOBAL hg;
		LPCWSTR ws;
		char[] result = null;
		hg = LoadResource(hinst, hrc);
		if(!hg)
			return null;
		ws = cast(LPCWSTR)LockResource(hg);
		if(ws)
		{
			int i;
			for(i = 0; i < (id & 15); i++)
			{
				ws += 1 + cast(size_t)*ws;
			}
			result = utf16stringtoUtf8string((ws + 1)[0 .. cast(size_t)*ws]);
			//UnlockResource(ws); // Obsolete / stub.
		}
		FreeResource(hg); // Obsolete / stub.
		return result;
	}
	
	deprecated alias getString loadString;
	
	
	~this()
	{
		if(_owned)
			dispose();
	}
	
	
	private:
	
	HINSTANCE hinst;
	WORD lang = 0;
	bool _owned = false;
	
	
	/+
	void _noload(char[] type)
	{
		throw new DflException("Unable to load " ~ type ~ " resource");
	}
	+/
}

