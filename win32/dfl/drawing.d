// Written by Christopher E. Miller
// See the included license.txt for copyright and license details.


///
module dfl.drawing;

private import dfl.internal.dlib;

private import dfl.internal.winapi, dfl.base, dfl.internal.utf, dfl.internal.com,
	dfl.internal.wincom;


version(D_Version2)
{
	version = DFL_D2;
	version = DFL_D2_AND_ABOVE;
}
else version(D_Version3)
{
	version = DFL_D3;
	version = DFL_D3_AND_ABOVE;
	version = DFL_D2_AND_ABOVE;
}
else version(D_Version4)
{
	version = DFL_D4;
	version = DFL_D4_AND_ABOVE;
	version = DFL_D3_AND_ABOVE;
	version = DFL_D2_AND_ABOVE;
}
else
{
	version = DFL_D1;
}
//version = DFL_D1_AND_ABOVE;


/// X and Y coordinate.
struct Point // docmain
{
	union
	{
		struct
		{
			LONG x;
			LONG y;
		}
		POINT point; // package
	}
	
	
	/// Construct a new Point.
	this(int x, int y)
	{
		this.x = x;
		this.y = y;
	}
	
	
	version(DFL_D2_AND_ABOVE)
	{
		///
		const Dequ opEquals(ref ConstType!(Point) pt)
		{
			return x == pt.x && y == pt.y;
		}
		
		/// ditto
		const Dequ opEquals(Point pt)
		{
			return x == pt.x && y == pt.y;
		}
	}
	else
	{
		///
		Dequ opEquals(Point pt)
		{
			return x == pt.x && y == pt.y;
		}
	}
	
	
	///
	Point opAdd(Size sz)
	{
		Point result;
		result.x = x + sz.width;
		result.y = y + sz.height;
		return result;
	}
	
	
	///
	Point opSub(Size sz)
	{
		Point result;
		result.x = x - sz.width;
		result.y = y - sz.height;
		return result;
	}
	
	
	///
	void opAddAssign(Size sz)
	{
		x += sz.width;
		y += sz.height;
	}
	
	
	///
	void opSubAssign(Size sz)
	{
		x -= sz.width;
		y -= sz.height;
	}
	
	
	///
	Point opNeg()
	{
		return Point(-x, -y);
	}
}


/// Width and height.
struct Size // docmain
{
	int width;
	int height;
	
	
	SIZE size() const
	{
		SIZE sz;
		sz.cx = width;
		sz.cy = height;
		return sz;
	}
	
	
	void size(SIZE sz)
	{
		width = sz.cx;
		height = sz.cy;
	}
	
	
	/// Construct a new Size.
	this(int width, int height)
	{
		this.width = width;
		this.height = height;
	}
	
	
	version(DFL_D2_AND_ABOVE)
	{
		///
		const Dequ opEquals(ref ConstType!(Size) sz)
		{
			return width == sz.width && height == sz.height;
		}
		
		/// ditto
		const Dequ opEquals(Size sz)
		{
			return width == sz.width && height == sz.height;
		}
	}
	else
	{
		///
		Dequ opEquals(Size sz)
		{
			return width == sz.width && height == sz.height;
		}
	}
	
	
	///
	Size opAdd(Size sz)
	{
		Size result;
		result.width = width + sz.width;
		result.height = height + sz.height;
		return result;
	}
	
	
	///
	Size opSub(Size sz)
	{
		Size result;
		result.width = width - sz.width;
		result.height = height - sz.height;
		return result;
	}
	
	
	///
	void opAddAssign(Size sz)
	{
		width += sz.width;
		height += sz.height;
	}
	
	
	///
	void opSubAssign(Size sz)
	{
		width -= sz.width;
		height -= sz.height;
	}
}


/// X, Y, width and height rectangle dimensions.
struct Rect // docmain
{
	int x, y, width, height;
	
	// Used internally.
	pure nothrow void getRect(RECT* r) // package
	{
		r.left = x;
		r.right = x + width;
		r.top = y;
		r.bottom = y + height;
	}
	
	
	///
	@property Point location() // getter
	{
		return Point(x, y);
	}
	
	/// ditto
	@property void location(Point pt) // setter
	{
		x = pt.x;
		y = pt.y;
	}
	
	
	///
	@property Size size() //getter
	{
		return Size(width, height);
	}
	
	/// ditto
	@property void size(Size sz) // setter
	{
		width = sz.width;
		height = sz.height;
	}
	
	
	///
	@property int right() // getter
	{
		return x + width;
	}
	
	
	///
	@property int bottom() // getter
	{
		return y + height;
	}
	
	
	/// Construct a new Rect.
	static Rect opCall(int x, int y, int width, int height)
	{
		Rect r;
		r.x = x;
		r.y = y;
		r.width = width;
		r.height = height;
		return r;
	}
	
	/// ditto
	static Rect opCall(Point location, Size size)
	{
		Rect r;
		r.x = location.x;
		r.y = location.y;
		r.width = size.width;
		r.height = size.height;
		return r;
	}
	
	/// ditto
	static Rect opCall()
	{
		Rect r;
		return r;
	}
	
	
	// Used internally.
	static Rect opCall(RECT* rect) // package
	{
		Rect r;
		r.x = rect.left;
		r.y = rect.top;
		r.width = rect.right - rect.left;
		r.height = rect.bottom - rect.top;
		return r;
	}
	
	
	/// Construct a new Rect from left, top, right and bottom values.
	static Rect fromLTRB(int left, int top, int right, int bottom)
	{
		Rect r;
		r.x = left;
		r.y = top;
		r.width = right - left;
		r.height = bottom - top;
		return r;
	}
	
	
	version(DFL_D2_AND_ABOVE)
	{
		///
		const Dequ opEquals(ref ConstType!(Rect) r)
		{
			return x == r.x && y == r.y &&
				width == r.width && height == r.height;
		}
		
		/// ditto
		const Dequ opEquals(Rect r)
		{
			return x == r.x && y == r.y &&
				width == r.width && height == r.height;
		}
	}
	else
	{
		///
		Dequ opEquals(Rect r)
		{
			return x == r.x && y == r.y &&
				width == r.width && height == r.height;
		}
	}
	
	
	///
	bool contains(int c_x, int c_y)
	{
		if(c_x >= x && c_y >= y)
		{
			if(c_x <= right && c_y <= bottom)
				return true;
		}
		return false;
	}
	
	/// ditto
	bool contains(Point pos)
	{
		return contains(pos.x, pos.y);
	}
	
	/// ditto
	// Contained entirely within -this-.
	bool contains(Rect r)
	{
		if(r.x >= x && r.y >= y)
		{
			if(r.right <= right && r.bottom <= bottom)
				return true;
		}
		return false;
	}
	
	
	///
	void inflate(int i_width, int i_height)
	{
		x -= i_width;
		width += i_width * 2;
		y -= i_height;
		height += i_height * 2;
	}
	
	/// ditto
	void inflate(Size insz)
	{
		inflate(insz.width, insz.height);
	}
	
	
	///
	// Just tests if there's an intersection.
	bool intersectsWith(Rect r)
	{
		if(r.right >= x && r.bottom >= y)
		{
			if(r.y <= bottom && r.x <= right)
				return true;
		}
		return false;
	}
	
	
	///
	void offset(int x, int y)
	{
		this.x += x;
		this.y += y;
	}
	
	/// ditto
	void offset(Point pt)
	{
		//return offset(pt.x, pt.y);
		this.x += pt.x;
		this.y += pt.y;
	}
	
	
	/+
	// Modify -this- to include only the intersection
	// of -this- and -r-.
	void intersect(Rect r)
	{
	}
	+/
	
	
	// void offset(Point), void offset(int, int)
	// static Rect union(Rect, Rect)
}


unittest
{
	Rect r = Rect(3, 3, 3, 3);
	
	assert(r.contains(3, 3));
	assert(!r.contains(3, 2));
	assert(r.contains(6, 6));
	assert(!r.contains(6, 7));
	assert(r.contains(r));
	assert(r.contains(Rect(4, 4, 2, 2)));
	assert(!r.contains(Rect(2, 4, 4, 2)));
	assert(!r.contains(Rect(4, 3, 2, 4)));
	
	r.inflate(2, 1);
	assert(r.x == 1);
	assert(r.right == 8);
	assert(r.y == 2);
	assert(r.bottom == 7);
	r.inflate(-2, -1);
	assert(r == Rect(3, 3, 3, 3));
	
	assert(r.intersectsWith(Rect(4, 4, 2, 9)));
	assert(r.intersectsWith(Rect(3, 3, 1, 1)));
	assert(r.intersectsWith(Rect(0, 3, 3, 0)));
	assert(r.intersectsWith(Rect(3, 2, 0, 1)));
	assert(!r.intersectsWith(Rect(3, 1, 0, 1)));
	assert(r.intersectsWith(Rect(5, 6, 1, 1)));
	assert(!r.intersectsWith(Rect(7, 6, 1, 1)));
	assert(!r.intersectsWith(Rect(6, 7, 1, 1)));
}


/// Color value representation
struct Color // docmain
{
	/// Red, green, blue and alpha channel color values.
	@property ubyte r() nothrow // getter
	{ validateColor(); return color.red; }
	
	/// ditto
	@property ubyte g() nothrow // getter
	{ validateColor(); return color.green; }
	
	/// ditto
	@property ubyte b() nothrow // getter
	{ validateColor(); return color.blue; }
	
	/// ditto
	@property ubyte a() nothrow // getter
	{ /+ validateColor(); +/ return color.alpha; }
	
	
	/// Return the numeric color value.
	COLORREF toArgb() nothrow
	{
		validateColor();
		return color.cref;
	}
	
	
	/// Return the numeric red, green and blue color value.
	COLORREF toRgb() nothrow
	{
		validateColor();
		return color.cref & 0x00FFFFFF;
	}
	
	
	// Used internally.
	HBRUSH createBrush() nothrow // package
	{
		HBRUSH hbr;
		if(_systemColorIndex == Color.INVAILD_SYSTEM_COLOR_INDEX)
			hbr = CreateSolidBrush(toRgb());
		else
			hbr = GetSysColorBrush(_systemColorIndex);
		return hbr;
	}
	
	
	Color* Dthisptr(Color* t) pure nothrow { return t; }
	Color* Dthisptr(ref Color t) pure nothrow { return &t; }
	Color Dthisval(Color* t) pure nothrow { return *t; }
	Color Dthisval(Color t) pure nothrow { return t; }
	
	
	deprecated static Color opCall(COLORREF argb)
	{
		Color nc;
		nc.color.cref = argb;
		return nc;
	}
	
	
	/// Construct a new color.
	this(ubyte alpha, Color c) pure nothrow
	{
		color.blue = c.color.blue;
		color.green = c.color.green;
		color.red = c.color.red;
		color.alpha = alpha;
	}
	
	/// ditto
	this(ubyte red, ubyte green, ubyte blue) pure nothrow
	{
		color.blue = blue;
		color.green = green;
		color.red = red;
		color.alpha = 0xFF;
	}
	
	/// ditto
	this(ubyte alpha, ubyte red, ubyte green, ubyte blue) pure nothrow
	{
		this = fromArgb(alpha, red, green, blue);
	}
	
	/// ditto
	//alias opCall fromArgb;
	static Color fromArgb(ubyte alpha, ubyte red, ubyte green, ubyte blue) pure nothrow
	{
		Color nc;
		nc.color.blue = blue;
		nc.color.green = green;
		nc.color.red = red;
		nc.color.alpha = alpha;
		return nc;
	}
	
	/// ditto
	static Color fromRgb(COLORREF rgb) pure nothrow
	{
		if(CLR_NONE == rgb)
			return empty;
		Color nc;
		nc.color.cref = rgb;
		nc.color.alpha = 0xFF;
		return nc;
	}
	
	/// ditto
	static Color fromRgb(ubyte alpha, COLORREF rgb) pure nothrow
	{
		Color nc;
		nc.color.cref = rgb | ((cast(COLORREF)alpha) << 24);
		return nc;
	}
	
	/// ditto
	static @property Color empty() pure nothrow // getter
	{
		return Color(0, 0, 0, 0);
	}
	
	
	/// Return a completely transparent color value.
	static @property Color transparent() nothrow // getter
	{
		return Color.fromArgb(0, 0xFF, 0xFF, 0xFF);
	}
	
	
	deprecated alias blendColor blend;
	
	
	/// Blend colors; alpha channels are ignored.
	// Blends the color channels half way.
	// Does not consider alpha channels and discards them.
	// The new blended color is returned; -this- Color is not modified.
	Color blendColor(Color wc) nothrow
	{
		if(Dthisval(this) == Color.empty)
			return wc;
		if(wc == Color.empty)
			return Dthisval(this);
		
		validateColor();
		wc.validateColor();
		
		return Color(cast(ubyte)((cast(uint)color.red + cast(uint)wc.color.red) >> 1),
			cast(ubyte)((cast(uint)color.green + cast(uint)wc.color.green) >> 1),
			cast(ubyte)((cast(uint)color.blue + cast(uint)wc.color.blue) >> 1));
	}
	
	
	/// Alpha blend this color with a background color to return a solid color (100% opaque).
	// Blends with backColor if this color has opacity to produce a solid color.
	// Returns the new solid color, or the original color if no opacity.
	// If backColor has opacity, it is ignored.
	// The new blended color is returned; -this- Color is not modified.
	Color solidColor(Color backColor) nothrow
	{
		//if(0x7F == this.color.alpha)
		//	return blendColor(backColor);
		//if(Dthisval(this) == Color.empty) // Checked if(0 == this.color.alpha)
		//	return backColor;
		if(0 == this.color.alpha)
			return backColor;
		if(backColor == Color.empty)
			return Dthisval(this);
		if(0xFF == this.color.alpha)
			return Dthisval(this);
		
		validateColor();
		backColor.validateColor();
		
		float fa, ba;
		fa = cast(float)color.alpha / 255.0;
		ba = 1.0 - fa;
		
		Color result;
		result.color.alpha = 0xFF;
		result.color.red = cast(ubyte)(this.color.red * fa + backColor.color.red * ba);
		result.color.green = cast(ubyte)(this.color.green * fa + backColor.color.green * ba);
		result.color.blue = cast(ubyte)(this.color.blue * fa + backColor.color.blue * ba);
		return result;
	}
	
	
	package static Color systemColor(int colorIndex) pure nothrow
	{
		Color c;
		c.sysIndex = cast(ubyte)colorIndex;
		c.color.alpha = 0xFF;
		return c;
	}
	
	
	// Gets color index or INVAILD_SYSTEM_COLOR_INDEX.
	package @property int _systemColorIndex() pure nothrow // getter
	{
		return sysIndex;
	}
	
	
	package enum ubyte INVAILD_SYSTEM_COLOR_INDEX = ubyte.max;
	
	
	private:
	union _color
	{
		struct
		{
			align(1):
			ubyte red;
			ubyte green;
			ubyte blue;
			ubyte alpha;
		}
		COLORREF cref;
	}
	static assert(_color.sizeof == uint.sizeof);
	_color color;
	
	ubyte sysIndex = INVAILD_SYSTEM_COLOR_INDEX;
	
	
	void validateColor() nothrow
	{
		if(sysIndex != INVAILD_SYSTEM_COLOR_INDEX)
		{
			color.cref = GetSysColor(sysIndex);
			//color.alpha = 0xFF; // Should already be set.
		}
	}
}


///
class SystemColors // docmain
{
	private this()
	{
	}
	
	
	static:
	
	///
	@property Color activeBorder() // getter
	{
		return Color.systemColor(COLOR_ACTIVEBORDER);
	}
	
	/// ditto
	@property Color activeCaption() // getter
	{
		return Color.systemColor(COLOR_ACTIVECAPTION);
	}
	
	/// ditto
	@property Color activeCaptionText() // getter
	{
		return Color.systemColor(COLOR_CAPTIONTEXT);
	}
	
	/// ditto
	@property Color appWorkspace() // getter
	{
		return Color.systemColor(COLOR_APPWORKSPACE);
	}
	
	/// ditto
	@property Color control() // getter
	{
		return Color.systemColor(COLOR_BTNFACE);
	}
	
	/// ditto
	@property Color controlDark() // getter
	{
		return Color.systemColor(COLOR_BTNSHADOW);
	}
	
	/// ditto
	@property Color controlDarkDark() // getter
	{
		return Color.systemColor(COLOR_3DDKSHADOW); // ?
	}
	
	/// ditto
	@property Color controlLight() // getter
	{
		return Color.systemColor(COLOR_3DLIGHT);
	}
	
	/// ditto
	@property Color controlLightLight() // getter
	{
		return Color.systemColor(COLOR_BTNHIGHLIGHT); // ?
	}
	
	/// ditto
	@property Color controlText() // getter
	{
		return Color.systemColor(COLOR_BTNTEXT);
	}
	
	/// ditto
	@property Color desktop() // getter
	{
		return Color.systemColor(COLOR_DESKTOP);
	}
	
	/// ditto
	@property Color grayText() // getter
	{
		return Color.systemColor(COLOR_GRAYTEXT);
	}
	
	/// ditto
	@property Color highlight() // getter
	{
		return Color.systemColor(COLOR_HIGHLIGHT);
	}
	
	/// ditto
	@property Color highlightText() // getter
	{
		return Color.systemColor(COLOR_HIGHLIGHTTEXT);
	}
	
	/// ditto
	@property Color hotTrack() // getter
	{
		return Color(0, 0, 0xFF); // ?
	}
	
	/// ditto
	@property Color inactiveBorder() // getter
	{
		return Color.systemColor(COLOR_INACTIVEBORDER);
	}
	
	/// ditto
	@property Color inactiveCaption() // getter
	{
		return Color.systemColor(COLOR_INACTIVECAPTION);
	}
	
	/// ditto
	@property Color inactiveCaptionText() // getter
	{
		return Color.systemColor(COLOR_INACTIVECAPTIONTEXT);
	}
	
	/// ditto
	@property Color info() // getter
	{
		return Color.systemColor(COLOR_INFOBK);
	}
	
	/// ditto
	@property Color infoText() // getter
	{
		return Color.systemColor(COLOR_INFOTEXT);
	}
	
	/// ditto
	@property Color menu() // getter
	{
		return Color.systemColor(COLOR_MENU);
	}
	
	/// ditto
	@property Color menuText() // getter
	{
		return Color.systemColor(COLOR_MENUTEXT);
	}
	
	/// ditto
	@property Color scrollBar() // getter
	{
		return Color.systemColor(CTLCOLOR_SCROLLBAR);
	}
	
	/// ditto
	@property Color window() // getter
	{
		return Color.systemColor(COLOR_WINDOW);
	}
	
	/// ditto
	@property Color windowFrame() // getter
	{
		return Color.systemColor(COLOR_WINDOWFRAME);
	}
	
	/// ditto
	@property Color windowText() // getter
	{
		return Color.systemColor(COLOR_WINDOWTEXT);
	}
}


///
class SystemIcons // docmain
{
	private this()
	{
	}
	
	
	static:
	
	///
	@property Icon application() // getter
	{
		return new Icon(LoadIconA(null, IDI_APPLICATION), false);
	}
	
	/// ditto
	@property Icon error() // getter
	{
		return new Icon(LoadIconA(null, IDI_HAND), false);
	}
	
	/// ditto
	@property Icon question() // getter
	{
		return new Icon(LoadIconA(null, IDI_QUESTION), false);
	}
	
	/// ditto
	@property Icon warning() // getter
	{
		return new Icon(LoadIconA(null, IDI_EXCLAMATION), false);
	}
	
	/// ditto
	@property Icon information() // getter
	{
		return new Icon(LoadIconA(null, IDI_INFORMATION), false);
	}
}


/+
class ImageFormat
{
	/+
	this(guid)
	{
		
	}
	
	
	final @property guid() // getter
	{
		return guid;
	}
	+/
	
	
	static:
	
	@property ImageFormat bmp() // getter
	{
		return null;
	}
	
	
	@property ImageFormat icon() // getter
	{
		return null;
	}
}
+/


///
abstract class Image // docmain
{
	//flags(); // getter ???
	
	
	/+
	final @property ImageFormat rawFormat(); // getter
	+/
	
	
	static Bitmap fromHBitmap(HBITMAP hbm) // package
	{
		return new Bitmap(hbm, false); // Not owned. Up to caller to manage or call dispose().
	}
	
	
	/+
	static Image fromFile(Dstring file)
	{
		return new Image(LoadImageA());
	}
	+/
	
	
	///
	void draw(Graphics g, Point pt);
	/// ditto
	void drawStretched(Graphics g, Rect r);
	
	
	///
	@property Size size(); // getter
	
	
	///
	@property int width() // getter
	{
		return size.width;
	}
	
	
	///
	@property int height() // getter
	{
		return size.height;
	}
	
	
	int _imgtype(HGDIOBJ* ph) // internal
	{
		if(ph)
			*ph = HGDIOBJ.init;
		return 0; // 1 = bitmap; 2 = icon.
	}
}


///
class Bitmap: Image // docmain
{
	///
	// Load from a bmp file.
	this(Dstring fileName)
	{
		this.hbm = cast(HBITMAP)dfl.internal.utf.loadImage(null, fileName, IMAGE_BITMAP, 0, 0, LR_LOADFROMFILE);
		if(!this.hbm)
			throw new DflException("Unable to load bitmap from file '" ~ fileName ~ "'");
	}
	
	// Used internally.
	this(HBITMAP hbm, bool owned = true)
	{
		this.hbm = hbm;
		this.owned = owned;
	}
	
	
	///
	final @property HBITMAP handle() // getter
	{
		return hbm;
	}
	
	
	private void _getInfo(BITMAP* bm)
	{
		if(GetObjectA(hbm, BITMAP.sizeof, bm) != BITMAP.sizeof)
			throw new DflException("Unable to get image information");
	}
	
	
	///
	final override @property Size size() // getter
	{
		BITMAP bm;
		_getInfo(&bm);
		return Size(bm.bmWidth, bm.bmHeight);
	}
	
	
	///
	final override @property int width() // getter
	{
		return size.width;
	}
	
	
	///
	final override @property int height() // getter
	{
		return size.height;
	}
	
	
	private void _draw(Graphics g, Point pt, HDC memdc)
	{
		HGDIOBJ hgo;
		Size sz;
		
		sz = size;
		hgo = SelectObject(memdc, hbm);
		BitBlt(g.handle, pt.x, pt.y, sz.width, sz.height, memdc, 0, 0, SRCCOPY);
		SelectObject(memdc, hgo); // Old bitmap.
	}
	
	
	///
	final override void draw(Graphics g, Point pt)
	{
		HDC memdc;
		memdc = CreateCompatibleDC(g.handle);
		try
		{
			_draw(g, pt, memdc);
		}
		finally
		{
			DeleteDC(memdc);
		}
	}
	
	/// ditto
	// -tempMemGraphics- is used as a temporary Graphics instead of
	// creating and destroying a temporary one for each call.
	final void draw(Graphics g, Point pt, Graphics tempMemGraphics)
	{
		_draw(g, pt, tempMemGraphics.handle);
	}
	
	
	private void _drawStretched(Graphics g, Rect r, HDC memdc)
	{
		HGDIOBJ hgo;
		Size sz;
		int lstretch;
		
		sz = size;
		hgo = SelectObject(memdc, hbm);
		lstretch = SetStretchBltMode(g.handle, COLORONCOLOR);
		StretchBlt(g.handle, r.x, r.y, r.width, r.height, memdc, 0, 0, sz.width, sz.height, SRCCOPY);
		SetStretchBltMode(g.handle, lstretch);
		SelectObject(memdc, hgo); // Old bitmap.
	}
	
	
	///
	final override void drawStretched(Graphics g, Rect r)
	{
		HDC memdc;
		memdc = CreateCompatibleDC(g.handle);
		try
		{
			_drawStretched(g, r, memdc);
		}
		finally
		{
			DeleteDC(memdc);
		}
	}
	
	/// ditto
	// -tempMemGraphics- is used as a temporary Graphics instead of
	// creating and destroying a temporary one for each call.
	final void drawStretched(Graphics g, Rect r, Graphics tempMemGraphics)
	{
		_drawStretched(g, r, tempMemGraphics.handle);
	}
	
	
	///
	void dispose()
	{
		assert(owned);
		DeleteObject(hbm);
		hbm = null;
	}
	
	
	~this()
	{
		if(owned)
			dispose();
	}
	
	
	override int _imgtype(HGDIOBJ* ph) // internal
	{
		if(ph)
			*ph = cast(HGDIOBJ)hbm;
		return 1;
	}
	
	
	private:
	HBITMAP hbm;
	bool owned = true;
}


///
class Picture: Image // docmain
{
	// Note: requires OleInitialize(null).
	
	
	///
	// Throws exception on failure.
	this(DStream stm)
	{
		this.ipic = _fromDStream(stm);
		if(!this.ipic)
			throw new DflException("Unable to load picture from stream");
	}
	
	/// ditto
	// Throws exception on failure.
	this(Dstring fileName)
	{
		this.ipic = _fromFileName(fileName);
		if(!this.ipic)
			throw new DflException("Unable to load picture from file '" ~ fileName ~ "'");
	}
	
	
	/// ditto
	this(void[] mem)
	{
		this.ipic = _fromMemory(mem);
		if(!this.ipic)
			throw new DflException("Unable to load picture from memory");
	}
	
	
	private this(dfl.internal.wincom.IPicture ipic)
	{
		this.ipic = ipic;
	}
	
	
	///
	// Returns null on failure instead of throwing exception.
	static Picture fromStream(DStream stm)
	{
		auto ipic = _fromDStream(stm);
		if(!ipic)
			return null;
		return new Picture(ipic);
	}
	
	
	///
	// Returns null on failure instead of throwing exception.
	static Picture fromFile(Dstring fileName)
	{
		auto ipic = _fromFileName(fileName);
		if(!ipic)
			return null;
		return new Picture(ipic);
	}
	
	
	///
	static Picture fromMemory(void[] mem)
	{
		auto ipic = _fromMemory(mem);
		if(!ipic)
			return null;
		return new Picture(ipic);
	}
	
	
	///
	final void draw(HDC hdc, Point pt) // package
	{
		int lhx, lhy;
		int width, height;
		lhx = loghimX;
		lhy = loghimY;
		width = MAP_LOGHIM_TO_PIX(lhx, GetDeviceCaps(hdc, LOGPIXELSX));
		height = MAP_LOGHIM_TO_PIX(lhy, GetDeviceCaps(hdc, LOGPIXELSY));
		ipic.Render(hdc, pt.x, pt.y + height, width, -height, 0, 0, lhx, lhy, null);
	}
	
	/// ditto
	final override void draw(Graphics g, Point pt)
	{
		return draw(g.handle, pt);
	}
	
	
	///
	final void drawStretched(HDC hdc, Rect r) // package
	{
		int lhx, lhy;
		lhx = loghimX;
		lhy = loghimY;
		ipic.Render(hdc, r.x, r.y + r.height, r.width, -r.height, 0, 0, lhx, lhy, null);
	}
	
	/// ditto
	final override void drawStretched(Graphics g, Rect r)
	{
		return drawStretched(g.handle, r);
	}
	
	
	///
	final @property OLE_XSIZE_HIMETRIC loghimX() // getter
	{
		OLE_XSIZE_HIMETRIC xsz;
		if(S_OK != ipic.get_Width(&xsz))
			return 0; // ?
		return xsz;
	}
	
	/// ditto
	final @property OLE_YSIZE_HIMETRIC loghimY() // getter
	{
		OLE_YSIZE_HIMETRIC ysz;
		if(S_OK != ipic.get_Height(&ysz))
			return 0; // ?
		return ysz;
	}
	
	
	///
	final override @property int width() // getter
	{
		Graphics g;
		int result;
		g = Graphics.getScreen();
		result = getWidth(g);
		g.dispose();
		return result;
	}
	
	
	///
	final override @property int height() // getter
	{
		Graphics g;
		int result;
		g = Graphics.getScreen();
		result = getHeight(g);
		g.dispose();
		return result;
	}
	
	
	///
	final override @property Size size() // getter
	{
		Graphics g;
		Size result;
		g = Graphics.getScreen();
		result = getSize(g);
		g.dispose();
		return result;
	}
	
	
	///
	final int getWidth(HDC hdc) // package
	{
		return MAP_LOGHIM_TO_PIX(loghimX, GetDeviceCaps(hdc, LOGPIXELSX));
	}
	
	/// ditto
	final int getWidth(Graphics g)
	{
		return getWidth(g.handle);
	}
	
	
	///
	final int getHeight(HDC hdc) // package
	{
		return MAP_LOGHIM_TO_PIX(loghimY, GetDeviceCaps(hdc, LOGPIXELSX));
	}
	
	/// ditto
	final int getHeight(Graphics g)
	{
		return getHeight(g.handle);
	}
	
	
	final Size getSize(HDC hdc) // package
	{
		return Size(getWidth(hdc), getHeight(hdc));
	}
	
	///
	final Size getSize(Graphics g)
	{
		return Size(getWidth(g), getHeight(g));
	}
	
	
	///
	void dispose()
	{
		if(HBITMAP.init != _hbmimgtype)
		{
			DeleteObject(_hbmimgtype);
			_hbmimgtype = HBITMAP.init;
		}
		
		if(ipic)
		{
			ipic.Release();
			ipic = null;
		}
	}
	
	
	~this()
	{
		dispose();
	}
	
	
	final HBITMAP toHBitmap(HDC hdc) // package
	{
		HDC memdc;
		HBITMAP result;
		HGDIOBJ oldbm;
		memdc = CreateCompatibleDC(hdc);
		if(!memdc)
			throw new DflException("Device error");
		try
		{
			Size sz;
			sz = getSize(hdc);
			result = CreateCompatibleBitmap(hdc, sz.width, sz.height);
			if(!result)
			{
				bad_bm:
				throw new DflException("Unable to allocate image");
			}
			oldbm = SelectObject(memdc, result);
			draw(memdc, Point(0, 0));
		}
		finally
		{
			if(oldbm)
				SelectObject(memdc, oldbm);
			DeleteDC(memdc);
		}
		return result;
	}
	
	
	final Bitmap toBitmap(HDC hdc) // package
	{
		HBITMAP hbm;
		hbm = toHBitmap(hdc);
		if(!hbm)
			throw new DflException("Unable to create bitmap");
		return new Bitmap(hbm, true); // Owned.
	}
	
	
	final Bitmap toBitmap()
	{
		Bitmap result;
		scope Graphics g = Graphics.getScreen();
		result = toBitmap(g);
		//g.dispose(); // scope'd
		return result;
	}
	
	/// ditto
	final Bitmap toBitmap(Graphics g)
	{
		return toBitmap(g.handle);
	}
	
	
	HBITMAP _hbmimgtype;
	
	override int _imgtype(HGDIOBJ* ph) // internal
	{
		if(ph)
		{
			if(HBITMAP.init == _hbmimgtype)
			{
				scope Graphics g = Graphics.getScreen();
				_hbmimgtype = toHBitmap(g.handle);
				//g.dispose(); // scope'd
			}
			
			*ph = _hbmimgtype;
		}
		return 1;
	}
	
	
	private:
	dfl.internal.wincom.IPicture ipic = null;
	
	
	static dfl.internal.wincom.IPicture _fromIStream(dfl.internal.wincom.IStream istm)
	{
		dfl.internal.wincom.IPicture ipic;
		switch(OleLoadPicture(istm, 0, FALSE, &_IID_IPicture, cast(void**)&ipic))
		{
			case S_OK:
				return ipic;
			
			debug(DFL_X)
			{
				case E_OUTOFMEMORY:
					debug assert(0, "Picture: Out of memory");
					break;
				case E_NOINTERFACE:
					debug assert(0, "Picture: The object does not support the interface");
					break;
				case E_UNEXPECTED:
					debug assert(0, "Picture: Unexpected error");
					break;
				case E_POINTER:
					debug assert(0, "Picture: Invalid pointer");
					break;
				case E_FAIL:
					debug assert(0, "Picture: Fail");
					break;
			}
			
			default:
		}
		return null;
	}
	
	
	static dfl.internal.wincom.IPicture _fromDStream(DStream stm)
	in
	{
		assert(stm !is null);
	}
	body
	{
		scope DStreamToIStream istm = new DStreamToIStream(stm);
		return _fromIStream(istm);
	}
	
	
	static dfl.internal.wincom.IPicture _fromFileName(Dstring fileName)
	{
		alias dfl.internal.winapi.HANDLE HANDLE; // Otherwise, odd conflict with wine.
		
		HANDLE hf;
		HANDLE hg;
		void* pg;
		DWORD dwsz, dw;
		
		hf = dfl.internal.utf.createFile(fileName, GENERIC_READ, FILE_SHARE_READ, null,
			OPEN_EXISTING, FILE_FLAG_SEQUENTIAL_SCAN, null);
		if(!hf)
			return null;
		
		dwsz = GetFileSize(hf, null);
		if(0xFFFFFFFF == dwsz)
		{
			failclose:
			CloseHandle(hf);
			return null;
		}
		
		hg = GlobalAlloc(GMEM_MOVEABLE, dwsz);
		if(!hg)
			goto failclose;
		
		pg = GlobalLock(hg);
		if(!pg)
		{
			CloseHandle(hf);
			CloseHandle(hg);
			return null;
		}
		
		if(!ReadFile(hf, pg, dwsz, &dw, null) || dwsz != dw)
		{
			CloseHandle(hf);
			GlobalUnlock(hg);
			CloseHandle(hg);
			return null;
		}
		
		CloseHandle(hf);
		GlobalUnlock(hg);
		
		IStream istm;
		dfl.internal.wincom.IPicture ipic;
		
		if(S_OK != CreateStreamOnHGlobal(hg, TRUE, &istm))
		{
			CloseHandle(hg);
			return null;
		}
		// Don't need to CloseHandle(hg) due to 2nd param being TRUE.
		
		ipic = _fromIStream(istm);
		istm.Release();
		return ipic;
	}
	
	
	static dfl.internal.wincom.IPicture _fromMemory(void[] mem)
	{
		return _fromIStream(new MemoryIStream(mem));
	}
	
}


///
enum TextTrimming: UINT
{
	NONE = 0,
	ELLIPSIS = DT_END_ELLIPSIS, /// ditto
	ELLIPSIS_PATH = DT_PATH_ELLIPSIS, /// ditto
}


///
enum TextFormatFlags: UINT
{
	NO_PREFIX = DT_NOPREFIX,
	DIRECTION_RIGHT_TO_LEFT = DT_RTLREADING, /// ditto
	WORD_BREAK = DT_WORDBREAK, /// ditto
	SINGLE_LINE = DT_SINGLELINE, /// ditto
	NO_CLIP = DT_NOCLIP, /// ditto
	LINE_LIMIT = DT_EDITCONTROL, /// ditto
}


///
enum TextAlignment: UINT
{
	LEFT = DT_LEFT, ///
	RIGHT = DT_RIGHT, /// ditto
	CENTER = DT_CENTER, /// ditto
	
	TOP = DT_TOP,  /// Single line only alignment.
	BOTTOM = DT_BOTTOM, /// ditto
	MIDDLE = DT_VCENTER, /// ditto
}


///
class TextFormat
{
	///
	this()
	{
	}
	
	/// ditto
	this(TextFormat tf)
	{
		_trim = tf._trim;
		_flags = tf._flags;
		_align = tf._align;
		_params = tf._params;
	}
	
	/// ditto
	this(TextFormatFlags flags)
	{
		_flags = flags;
	}
	
	
	///
	static @property TextFormat genericDefault() // getter
	{
		TextFormat result;
		result = new TextFormat;
		result._trim = TextTrimming.NONE;
		result._flags = TextFormatFlags.NO_PREFIX | TextFormatFlags.WORD_BREAK |
			TextFormatFlags.NO_CLIP | TextFormatFlags.LINE_LIMIT;
		return result;
	}
	
	/// ditto
	static @property TextFormat genericTypographic() // getter
	{
		return new TextFormat;
	}
	
	
	///
	final @property void alignment(TextAlignment ta) // setter
	{
		_align = ta;
	}
	
	/// ditto
	final @property TextAlignment alignment() // getter
	{
		return _align;
	}
	
	
	///
	final @property void formatFlags(TextFormatFlags tff) // setter
	{
		_flags = tff;
	}
	
	/// ditto
	final @property TextFormatFlags formatFlags() // getter
	{
		return _flags;
	}
	
	
	///
	final @property void trimming(TextTrimming tt) // getter
	{
		_trim = tt;
	}
	
	/// ditto
	final @property TextTrimming trimming() // getter
	{
		return _trim;
	}
	
	
	// Units of the average character width.
	
	///
	final @property void tabLength(int tablen) // setter
	{
		_params.iTabLength = tablen;
	}
	
	/// ditto
	final @property int tabLength() // getter
	{
		return _params.iTabLength;
	}
	
	
	// Units of the average character width.
	
	///
	final @property void leftMargin(int sz) // setter
	{
		_params.iLeftMargin = sz;
	}
	
	/// ditto
	final @property int leftMargin() // getter
	{
		return _params.iLeftMargin;
	}
	
	
	// Units of the average character width.
	
	///
	final @property void rightMargin(int sz) // setter
	{
		_params.iRightMargin = sz;
	}
	
	/// ditto
	final @property int rightMargin() // getter
	{
		return _params.iRightMargin;
	}
	
	
	private:
	TextTrimming _trim = TextTrimming.NONE; // TextTrimming.CHARACTER.
	TextFormatFlags _flags = TextFormatFlags.NO_PREFIX | TextFormatFlags.WORD_BREAK;
	TextAlignment _align = TextAlignment.LEFT;
	package DRAWTEXTPARAMS _params = { DRAWTEXTPARAMS.sizeof, 8, 0, 0 };
}


///
class Screen
{
	///
	static @property Screen primaryScreen() // getter
	{
		version(DFL_MULTIPLE_SCREENS)
		{
			_getScreens();
			if(_screens.length > 0)
			{
				if(_screens.length == 1)
				{
					return _screens[0];
				}
				MONITORINFO mi;
				for(int i = 0; i < _screens.length; i++)
				{
					_screens[i]._getInfo(mi);
					if(mi.dwFlags & MONITORINFOF_PRIMARY)
						return _screens[i];
				}
			}
		}
		if(!_ps)
		{
			_setPs();
		}
		return _ps;
	}
	
	
	///
	@property Rect bounds() // getter
	{
		version(DFL_MULTIPLE_SCREENS)
		{
			if(HMONITOR.init != hmonitor)
			{
				MONITORINFO mi;
				_getInfo(mi);
				return Rect(&mi.rcMonitor);
			}
		}
		RECT area;
		if(!GetWindowRect(GetDesktopWindow(), &area))
			assert(0);
		return Rect(&area);
	}
	
	
	///
	@property Rect workingArea() // getter
	{
		version(DFL_MULTIPLE_SCREENS)
		{
			if(HMONITOR.init != hmonitor)
			{
				MONITORINFO mi;
				_getInfo(mi);
				return Rect(&mi.rcWork);
			}
		}
		RECT area;
		if(!SystemParametersInfoA(SPI_GETWORKAREA, 0, &area, FALSE))
			return bounds;
		return Rect(&area);
	}
	
	
	version(DFL_MULTIPLE_SCREENS)
	{
		
		debug
		{
			static @property void fakeMultipleScreens(bool byes) // setter
			{
				if(byes)
				{
					allScreens(); // Force populating.
					if(_screens.length < 2)
					{
						_screens ~= new Screen(HMFAKE);
					}
				}
			}
			
			static @property bool fakeMultipleScreens() // getter
			{
				return _screens.length > 1
					&& HMFAKE == _screens[1].hmonitor;
			}
			
			private enum HMONITOR HMFAKE = cast(HMONITOR)1969253357;
		}
		
		
		///
		static @property Screen[] allScreens() // getter
		{
			version(DFL_MULTIPLE_SCREENS)
			{
				_getScreens();
				if(_screens.length > 0)
					return _screens;
			}
			if(_screens.length < 1)
			{
				synchronized
				{
					_screens = new Screen[1];
					if(!_ps)
					{
						_setPs();
					}
					_screens[0] = _ps;
				}
			}
			return _screens;
		}
		
		
		static Screen fromHandle(HWND hwnd)
		{
			version(DFL_MULTIPLE_SCREENS)
			{
				version(SUPPORTS_MULTIPLE_SCREENS)
				{
					alias MonitorFromWindow fromWindow;
				}
				else
				{
					auto fromWindow = cast(typeof(&MonitorFromWindow))GetProcAddress(
						GetModuleHandleA("user32.dll"), "MonitorFromWindow");
					if(!fromWindow)
					{
						//throw new DflException("Multiple screens not supported");
						goto _def;
					}
				}
				HMONITOR hm = fromWindow(hwnd, MONITOR_DEFAULTTOPRIMARY);
				debug
				{
					if(fakeMultipleScreens
						&& hm == _screens[0].hmonitor)
					{
						RECT rect;
						if(GetWindowRect(hwnd, &rect))
						{
							Rect r = Rect(&rect);
							if(_withinFakeScreen(r))
								return _screens[1];
						}
					}
				}
				return _findScreen(hm);
			}
			_def:
			return primaryScreen;
		}
		
		
		///
		static Screen fromControl(IWindow ctrl)
		{
			return fromHandle(ctrl.handle);
		}
		
		
		///
		static Screen fromPoint(Point pt)
		{
			version(DFL_MULTIPLE_SCREENS)
			{
				version(SUPPORTS_MULTIPLE_SCREENS)
				{
					alias MonitorFromPoint fromPoint;
				}
				else
				{
					auto fromPoint = cast(typeof(&MonitorFromPoint))GetProcAddress(
						GetModuleHandleA("user32.dll"), "MonitorFromPoint");
					if(!fromPoint)
					{
						//throw new DflException("Multiple screens not supported");
						goto _def;
					}
				}
				HMONITOR hm = fromPoint(pt.point, MONITOR_DEFAULTTOPRIMARY);
				debug
				{
					if(fakeMultipleScreens
						&& hm == _screens[0].hmonitor)
					{
						Rect r = Rect(pt, Size(0, 0));
						if(_withinFakeScreen(r))
							return _screens[1];
					}
				}
				return _findScreen(hm);
			}
			_def:
			return primaryScreen;
		}
		
		
		///
		static Screen fromRectangle(Rect r)
		{
			version(DFL_MULTIPLE_SCREENS)
			{
				version(SUPPORTS_MULTIPLE_SCREENS)
				{
					alias MonitorFromRect fromRect;
				}
				else
				{
					auto fromRect = cast(typeof(&MonitorFromRect))GetProcAddress(
						GetModuleHandleA("user32.dll"), "MonitorFromRect");
					if(!fromRect)
					{
						//throw new DflException("Multiple screens not supported");
						goto _def;
					}
				}
				RECT rect;
				r.getRect(&rect);
				HMONITOR hm = fromRect(&rect, MONITOR_DEFAULTTOPRIMARY);
				debug
				{
					if(fakeMultipleScreens
						&& hm == _screens[0].hmonitor)
					{
						if(_withinFakeScreen(r))
							return _screens[1];
					}
				}
				return _findScreen(hm);
			}
			_def:
			return primaryScreen;
		}
		
	}
	
	
	private:
	
	static void _setPs()
	{
		synchronized
		{
			if(!_ps)
				_ps = new Screen();
		}
	}
	
	this()
	{
	}
	
	this(HMONITOR hmonitor)
	{
		this.hmonitor = hmonitor;
	}
	
	HMONITOR hmonitor;
	
	static Screen _ps; // Primary screen; might not be used.
	static Screen[] _screens;
	
	version(DFL_MULTIPLE_SCREENS)
	{
		
		bool foundThis = true; // Used during _getScreens callback.
		
		
		static Screen _findScreen(HMONITOR hm)
		{
			foreach(Screen s; allScreens)
			{
				if(s.hmonitor == hm)
				{
					return s;
				}
			}
			return primaryScreen;
		}
		
		
		static void _getScreens()
		{
			// Note: monitors can change, so always enum,
			// but update the array by removing old ones and adding new ones.
			for(int i = 0; i < _screens.length; i++)
			{
				_screens[i].foundThis = false;
				debug
				{
					if(HMFAKE == _screens[i].hmonitor)
					{
						_screens[i].foundThis = true;
					}
				}
			}
			version(SUPPORTS_MULTIPLE_SCREENS)
			{
				pragma(msg, "DFL: multiple screens supported at compile time");
				
				alias EnumDisplayMonitors enumScreens;
			}
			else
			{
				auto enumScreens = cast(typeof(&EnumDisplayMonitors))GetProcAddress(
					GetModuleHandleA("user32.dll"), "EnumDisplayMonitors");
				if(!enumScreens)
				{
					//throw new DflException("Multiple screens not supported");
					return;
				}
			}
			if(!enumScreens(null, null, &_gettingScreens, 0))
			{
				//throw new DflException("Failed to enumerate screens");
				return;
			}
			{
				int numremoved = 0;
				for(int i = 0; i < _screens.length; i++)
				{
					if(!_screens[i].foundThis)
					{
						numremoved++;
					}
				}
				if(numremoved > 0)
				{
					Screen[] newscreens = new Screen[_screens.length - numremoved];
					for(int i = 0, nsi = 0; i < _screens.length; i++)
					{
						if(_screens[i].foundThis)
						{
							newscreens[nsi++] = _screens[i];
						}
					}
					_screens = newscreens;
				}
			}
		}
		
		
		debug
		{
			static bool _withinFakeScreen(Rect r)
			{
				Rect fr = _screens[1].bounds;
				//return r.right >= fr.x;
				if(r.x >= fr.x)
					return true;
				if(r.right < fr.x)
					return false;
				{
					// See which side it's in most.
					RECT rect;
					r.getRect(&rect);
					RECT w0 = rect;
					assert(w0.right >= fr.width);
					w0.right = fr.width;
					RECT w1 = rect;
					assert(w1.left <= fr.width);
					w1.left = fr.width;
					return Rect(&w1).width > Rect(&w0).width;
				}
			}
		}
		
		
		void _getInfo(ref MONITORINFO info)
		{
			version(SUPPORTS_MULTIPLE_SCREENS)
			{
				alias GetMonitorInfoA getMI;
			}
			else
			{
				auto getMI = cast(typeof(&GetMonitorInfoA))GetProcAddress(
					GetModuleHandleA("user32.dll"), "GetMonitorInfoA");
				if(!getMI)
					throw new DflException("Error getting screen information (unable to find GetMonitorInfoA)");
			}
			info.cbSize = MONITORINFO.sizeof;
			HMONITOR hm = hmonitor;
			int fake = -1;
			debug
			{
				if(fakeMultipleScreens)
				{
					if(HMFAKE == hm)
					{
						fake = 1;
						hm = _screens[0].hmonitor;
					}
					else if(hm == _screens[0].hmonitor)
					{
						fake = 0;
					}
				}
			}
			if(!getMI(hm, &info))
				throw new DflException("Unable to get screen information");
			debug
			{
				if(1 == fake)
				{
					info.dwFlags &= ~MONITORINFOF_PRIMARY;
					{
						Rect r = Rect(&info.rcMonitor);
						int w = r.width >> 1;
						r.x = r.x + w;
						r.width = r.width - w;
						r.getRect(&info.rcMonitor);
					}
					{
						Rect r = Rect(&info.rcWork);
						int w = r.width >> 1;
						r.x = r.x + w;
						r.width = r.width - w;
						r.getRect(&info.rcWork);
					}
				}
				else if(0 == fake)
				{
					{
						Rect r = Rect(&info.rcMonitor);
						int w = r.width >> 1;
						r.width = r.width - w;
						r.getRect(&info.rcMonitor);
					}
					{
						Rect r = Rect(&info.rcWork);
						int w = r.width >> 1;
						r.width = r.width - w;
						r.getRect(&info.rcWork);
					}
				}
			}
		}
		
		
	}
}


version(DFL_MULTIPLE_SCREENS)
{
	private extern(Windows) BOOL _gettingScreens(HMONITOR hmonitor,
		HDC hdcMonitor, LPRECT lprcMonitor, LPARAM dwData) nothrow
	{
		for(int i = 0; i < Screen._screens.length; i++)
		{
			if(hmonitor == Screen._screens[i].hmonitor)
			{
				Screen._screens[i].foundThis = true;
				return TRUE; // Continue.
			}
		}
		// Didn't find it from old list, so add it.
		Screen._screens ~= new Screen(hmonitor);
		return TRUE; // Continue.
	}
	
}


///
class Graphics // docmain
{
	// Used internally.
	this(HDC hdc, bool owned = true)
	{
		this.hdc = hdc;
		this.owned = owned;
	}
	
	
	~this()
	{
		if(owned)
			dispose();
	}
	
	
	// Used internally.
	final void drawSizeGrip(int right, int bottom) // package
	{
		Color light, dark;
		int x, y;
		
		light = SystemColors.controlLightLight;
		dark = SystemColors.controlDark;
		scope Pen lightPen = new Pen(light);
		scope Pen darkPen = new Pen(dark);
		x = right;
		y = bottom;
		
		x -= 3;
		y -= 3;
		drawLine(darkPen, x, bottom, right, y);
		x--;
		y--;
		drawLine(darkPen, x, bottom, right, y);
		drawLine(lightPen, x - 1, bottom, right, y - 1);
		
		x -= 3;
		y -= 3;
		drawLine(darkPen, x, bottom, right, y);
		x--;
		y--;
		drawLine(darkPen, x, bottom, right, y);
		drawLine(lightPen, x - 1, bottom, right, y - 1);
		
		x -= 3;
		y -= 3;
		drawLine(darkPen, x, bottom, right, y);
		x--;
		y--;
		drawLine(darkPen, x, bottom, right, y);
		drawLine(lightPen, x - 1, bottom, right, y - 1);
	}
	
	
	// Used internally.
	// vSplit=true means the move grip moves left to right; false means top to bottom.
	final void drawMoveGrip(Rect movableArea, bool vSplit = true, size_t count = 5) // package
	{
		enum MSPACE = 4;
		enum MWIDTH = 3;
		enum MHEIGHT = 3;
		
		if(!count || !movableArea.width || !movableArea.height)
			return;
		
		Color norm, light, dark, ddark;
		int x, y;
		size_t iw;
		
		norm = SystemColors.control;
		light = SystemColors.controlLightLight.blendColor(norm); // center
		//dark = SystemColors.controlDark.blendColor(norm); // top
		ubyte ubmin(int ub) { if(ub <= 0) return 0; return cast(ubyte)ub; }
		dark = Color(ubmin(cast(int)norm.r - 0x10), ubmin(cast(int)norm.g - 0x10), ubmin(cast(int)norm.b - 0x10));
		//ddark = SystemColors.controlDarkDark; // bottom
		ddark = SystemColors.controlDark.blendColor(Color(0x10, 0x10, 0x10)); // bottom
		//scope Pen lightPen = new Pen(light);
		scope Pen darkPen = new Pen(dark);
		scope Pen ddarkPen = new Pen(ddark);
		
		
		void drawSingleMoveGrip()
		{
			Point[3] pts;
			
			pts[0].x = x + MWIDTH - 2;
			pts[0].y = y;
			pts[1].x = x;
			pts[1].y = y;
			pts[2].x = x;
			pts[2].y = y + MHEIGHT - 1;
			drawLines(darkPen, pts);
			
			pts[0].x = x + MWIDTH - 1;
			pts[0].y = y + 1;
			pts[1].x = pts[0].x;
			pts[1].y = y + MHEIGHT - 1;
			pts[2].x = x;
			pts[2].y = pts[1].y;
			drawLines(ddarkPen, pts);
			
			fillRectangle(light, x + 1, y + 1, 1, 1);
		}
		
		
		if(vSplit)
		{
			x = movableArea.x + (movableArea.width / 2 - MWIDTH / 2);
			//y = movableArea.height / 2 - ((MWIDTH * count) + (MSPACE * (count - 1))) / 2;
			y = movableArea.y + (movableArea.height / 2 - ((MWIDTH * count) + (MSPACE * count)) / 2);
			
			for(iw = 0; iw != count; iw++)
			{
				drawSingleMoveGrip();
				y += MHEIGHT + MSPACE;
			}
		}
		else // hSplit
		{
			//x = movableArea.width / 2 - ((MHEIGHT * count) + (MSPACE * (count - 1))) / 2;
			x = movableArea.x + (movableArea.width / 2 - ((MHEIGHT * count) + (MSPACE * count)) / 2);
			y = movableArea.y + (movableArea.height / 2 - MHEIGHT / 2);
			
			for(iw = 0; iw != count; iw++)
			{
				drawSingleMoveGrip();
				x += MWIDTH + MSPACE;
			}
		}
	}
	
	
	package final TextFormat getCachedTextFormat()
	{
		static TextFormat fmt = null;
		if(!fmt)
			fmt = TextFormat.genericDefault;
		return fmt;
	}
	
	
	// Windows 95/98/Me limits -text- to 8192 characters.
	
	///
	final void drawText(Dstring text, Font font, Color color, Rect r, TextFormat fmt)
	{
		// Should SaveDC/RestoreDC be used instead?
		
		COLORREF prevColor;
		HFONT prevFont;
		int prevBkMode;
		
		prevColor = SetTextColor(hdc, color.toRgb());
		prevFont = cast(HFONT)SelectObject(hdc, font ? font.handle : null);
		prevBkMode = SetBkMode(hdc, TRANSPARENT);
		
		RECT rect;
		r.getRect(&rect);
		dfl.internal.utf.drawTextEx(hdc, text, &rect, DT_EXPANDTABS | DT_TABSTOP |
			fmt._trim | fmt._flags | fmt._align, &fmt._params);
		
		// Reset stuff.
		//if(CLR_INVALID != prevColor)
			SetTextColor(hdc, prevColor);
		//if(prevFont)
			SelectObject(hdc, prevFont);
		//if(prevBkMode)
			SetBkMode(hdc, prevBkMode);
	}
	
	/// ditto
	final void drawText(Dstring text, Font font, Color color, Rect r)
	{
		return drawText(text, font, color, r, getCachedTextFormat());
	}
	
	
	///
	final void drawTextDisabled(Dstring text, Font font, Color color, Color backColor, Rect r, TextFormat fmt)
	{
		r.offset(1, 1);
		//drawText(text, font, Color(24, color).solidColor(backColor), r, fmt); // Lighter, lower one.
		//drawText(text, font, Color.fromRgb(~color.toRgb() & 0xFFFFFF), r, fmt); // Lighter, lower one.
		drawText(text, font, Color(192, Color.fromRgb(~color.toRgb() & 0xFFFFFF)).solidColor(backColor), r, fmt); // Lighter, lower one.
		r.offset(-1, -1);
		drawText(text, font, Color(128, color).solidColor(backColor), r, fmt);
	}
	
	/// ditto
	final void drawTextDisabled(Dstring text, Font font, Color color, Color backColor, Rect r)
	{
		return drawTextDisabled(text, font, color, backColor, r, getCachedTextFormat());
	}
	
	
	/+
	final Size measureText(Dstring text, Font font)
	{
		SIZE sz;
		HFONT prevFont;
		
		prevFont = cast(HFONT)SelectObject(hdc, font ? font.handle : null);
		
		dfl.internal.utf.getTextExtentPoint32(hdc, text, &sz);
		
		//if(prevFont)
			SelectObject(hdc, prevFont);
		
		return Size(sz.cx, sz.cy);
	}
	+/
	
	
	private enum int DEFAULT_MEASURE_SIZE = short.max; // Has to be smaller because it's 16-bits on win9x.
	
	
	///
	final Size measureText(Dstring text, Font font, int maxWidth, TextFormat fmt)
	{
		RECT rect;
		HFONT prevFont;
		
		rect.left = 0;
		rect.top = 0;
		rect.right = maxWidth;
		rect.bottom = DEFAULT_MEASURE_SIZE;
		
		prevFont = cast(HFONT)SelectObject(hdc, font ? font.handle : null);
		
		if(!dfl.internal.utf.drawTextEx(hdc, text, &rect, DT_EXPANDTABS | DT_TABSTOP |
			fmt._trim | fmt._flags | fmt._align | DT_CALCRECT | DT_NOCLIP, &fmt._params))
		{
			//throw new DflException("Text measure error");
			rect.left = 0;
			rect.top = 0;
			rect.right = 0;
			rect.bottom = 0;
		}
		
		//if(prevFont)
			SelectObject(hdc, prevFont);
		
		return Size(rect.right - rect.left, rect.bottom - rect.top);
	}
	
	/// ditto
	final Size measureText(Dstring text, Font font, TextFormat fmt)
	{
		return measureText(text, font, DEFAULT_MEASURE_SIZE, fmt);
	}
	
	/// ditto
	final Size measureText(Dstring text, Font font, int maxWidth)
	{
		return measureText(text, font, maxWidth, getCachedTextFormat());
	}
	
	/// ditto
	final Size measureText(Dstring text, Font font)
	{
		return measureText(text, font, DEFAULT_MEASURE_SIZE, getCachedTextFormat());
	}
	
	
	/+
	// Doesn't work... dfl.internal.utf.drawTextEx uses a different buffer!
	// ///
	final Dstring getTrimmedText(Dstring text, Font font, Rect r, TextFormat fmt) // deprecated
	{
		switch(fmt.trimming)
		{
			case TextTrimming.ELLIPSIS:
			case TextTrimming.ELLIPSIS_PATH:
				{
					char[] newtext;
					RECT rect;
					HFONT prevFont;
					
					newtext = text.dup;
					r.getRect(&rect);
					prevFont = cast(HFONT)SelectObject(hdc, font ? font.handle : null);
					
					// DT_CALCRECT needs to prevent it from actually drawing.
					if(!dfl.internal.utf.drawTextEx(hdc, newtext, &rect, DT_EXPANDTABS | DT_TABSTOP |
						fmt._trim | fmt._flags | fmt._align | DT_CALCRECT | DT_MODIFYSTRING | DT_NOCLIP, &fmt._params))
					{
						//throw new DflException("Text trimming error");
					}
					
					//if(prevFont)
						SelectObject(hdc, prevFont);
					
					for(size_t iw = 0; iw != newtext.length; iw++)
					{
						if(!newtext[iw])
							return newtext[0 .. iw];
					}
					//return newtext;
					// There was no change, so no sense in keeping the duplicate.
					delete newtext;
					return text;
				}
				break;
			
			default:
				return text;
		}
	}
	
	// ///
	final Dstring getTrimmedText(Dstring text, Font font, Rect r, TextTrimming trim)
	{
		scope fmt = new TextFormat(TextFormatFlags.NO_PREFIX | TextFormatFlags.WORD_BREAK |
			TextFormatFlags.NO_CLIP | TextFormatFlags.LINE_LIMIT);
		fmt.trimming = trim;
		return getTrimmedText(text, font, r, fmt);
	}
	+/
	
	
	///
	final void drawIcon(Icon icon, Rect r)
	{
		// DrawIconEx operates differently if the width or height is zero
		// so bail out if zero and pretend the zero size icon was drawn.
		int width = r.width;
		if(!width)
			return;
		int height = r.height;
		if(!height)
			return;
		
		DrawIconEx(handle, r.x, r.y, icon.handle, width, height, 0, null, DI_NORMAL);
	}
	
	/// ditto
	final void drawIcon(Icon icon, int x, int y)
	{
		DrawIconEx(handle, x, y, icon.handle, 0, 0, 0, null, DI_NORMAL);
	}
	
	
	///
	final void fillRectangle(Brush brush, Rect r)
	{
		fillRectangle(brush, r.x, r.y, r.width, r.height);
	}
	
	/// ditto
	final void fillRectangle(Brush brush, int x, int y, int width, int height)
	{
		RECT rect;
		rect.left = x;
		rect.right = x + width;
		rect.top = y;
		rect.bottom = y + height;
		FillRect(handle, &rect, brush.handle);
	}
	
	
	// Extra function.
	final void fillRectangle(Color color, Rect r)
	{
		fillRectangle(color, r.x, r.y, r.width, r.height);
	}
	
	/// ditto
	// Extra function.
	final void fillRectangle(Color color, int x, int y, int width, int height)
	{
		RECT rect;
		int prevBkColor;
		
		prevBkColor = SetBkColor(hdc, color.toRgb());
		
		rect.left = x;
		rect.top = y;
		rect.right = x + width;
		rect.bottom = y + height;
		ExtTextOutA(hdc, x, y, ETO_OPAQUE, &rect, "", 0, null);
		
		// Reset stuff.
		//if(CLR_INVALID != prevBkColor)
			SetBkColor(hdc, prevBkColor);
	}
	
	
	///
	final void fillRegion(Brush brush, Region region)
	{
		FillRgn(handle, region.handle, brush.handle);
	}
	
	
	///
	static Graphics fromHwnd(HWND hwnd)
	{
		return new CommonGraphics(hwnd, GetDC(hwnd));
	}
	
	
	/// Get the entire screen's Graphics for the primary monitor.
	static Graphics getScreen()
	{
		return new CommonGraphics(null, GetWindowDC(null));
	}
	
	
	///
	final void drawLine(Pen pen, Point start, Point end)
	{
		drawLine(pen, start.x, start.y, end.x, end.y);
	}
	
	/// ditto
	final void drawLine(Pen pen, int startX, int startY, int endX, int endY)
	{
		HPEN prevPen;
		
		prevPen = SelectObject(hdc, pen.handle);
		
		MoveToEx(hdc, startX, startY, null);
		LineTo(hdc, endX, endY);
		
		// Reset stuff.
		SelectObject(hdc, prevPen);
	}
	
	
	///
	// First two points is the first line, the other points link a line
	// to the previous point.
	final void drawLines(Pen pen, Point[] points)
	{
		assert(points.length >= 2, "Not enough line points.");
		
		HPEN prevPen;
		int i;
		
		prevPen = SelectObject(hdc, pen.handle);
		
		MoveToEx(hdc, points[0].x, points[0].y, null);
		for(i = 1;;)
		{
			LineTo(hdc, points[i].x, points[i].y);
			
			if(++i == points.length)
				break;
		}
		
		// Reset stuff.
		SelectObject(hdc, prevPen);
	}
	
	
	///
	final void drawArc(Pen pen, int x, int y, int width, int height, int arcX1, int arcY1, int arcX2, int arcY2)
	{
		HPEN prevPen;
		
		prevPen = SelectObject(hdc, pen.handle);
		
		Arc(hdc, x, y, x + width, y + height, arcX1, arcY1, arcX2, arcY2);
		
		// Reset stuff.
		SelectObject(hdc, prevPen);
	}
	
	/// ditto
	final void drawArc(Pen pen, Rect r, Point arc1, Point arc2)
	{
		drawArc(pen, r.x, r.y, r.width, r.height, arc1.x, arc1.y, arc2.x, arc2.y);
	}
	
	
	///
	final void drawBezier(Pen pen, Point[4] points)
	{
		HPEN prevPen;
		POINT* cpts;
		
		prevPen = SelectObject(hdc, pen.handle);
		
		// This assumes a Point is laid out exactly like a POINT.
		static assert(Point.sizeof == POINT.sizeof);
		cpts = cast(POINT*)cast(Point*)points;
		
		PolyBezier(hdc, cpts, 4);
		
		// Reset stuff.
		SelectObject(hdc, prevPen);
	}
	
	/// ditto
	final void drawBezier(Pen pen, Point pt1, Point pt2, Point pt3, Point pt4)
	{
		Point[4] points;
		points[0] = pt1;
		points[1] = pt2;
		points[2] = pt3;
		points[3] = pt4;
		drawBezier(pen, points);
	}
	
	
	///
	// First 4 points are the first bezier, each next 3 are the next
	// beziers, using the previous last point as the starting point.
	final void drawBeziers(Pen pen, Point[] points)
	{
		if(points.length < 1 || (points.length - 1) % 3)
		{
			assert(0); // Bad number of points.
			//return; // Let PolyBezier() do what it wants with the bad number.
		}
		
		HPEN prevPen;
		POINT* cpts;
		
		prevPen = SelectObject(hdc, pen.handle);
		
		// This assumes a Point is laid out exactly like a POINT.
		static assert(Point.sizeof == POINT.sizeof);
		cpts = cast(POINT*)cast(Point*)points;
		
		PolyBezier(hdc, cpts, points.length);
		
		// Reset stuff.
		SelectObject(hdc, prevPen);
	}
	
	
	// TODO: drawCurve(), drawClosedCurve() ...
	
	
	///
	final void drawEllipse(Pen pen, Rect r)
	{
		drawEllipse(pen, r.x, r.y, r.width, r.height);
	}
	
	/// ditto
	final void drawEllipse(Pen pen, int x, int y, int width, int height)
	{
		HPEN prevPen;
		HBRUSH prevBrush;
		
		prevPen = SelectObject(hdc, pen.handle);
		prevBrush = SelectObject(hdc, cast(HBRUSH)GetStockObject(NULL_BRUSH)); // Don't fill it in.
		
		Ellipse(hdc, x, y, x + width, y + height);
		
		// Reset stuff.
		SelectObject(hdc, prevPen);
		SelectObject(hdc, prevBrush);
	}
	
	
	// TODO: drawPie()
	
	
	///
	final void drawPolygon(Pen pen, Point[] points)
	{
		if(points.length < 2)
		{
			assert(0); // Need at least 2 points.
			//return;
		}
		
		HPEN prevPen;
		HBRUSH prevBrush;
		POINT* cpts;
		
		prevPen = SelectObject(hdc, pen.handle);
		prevBrush = SelectObject(hdc, cast(HBRUSH)GetStockObject(NULL_BRUSH)); // Don't fill it in.
		
		// This assumes a Point is laid out exactly like a POINT.
		static assert(Point.sizeof == POINT.sizeof);
		cpts = cast(POINT*)cast(Point*)points;
		
		Polygon(hdc, cpts, points.length);
		
		// Reset stuff.
		SelectObject(hdc, prevPen);
		SelectObject(hdc, prevBrush);
	}
	
	
	///
	final void drawRectangle(Pen pen, Rect r)
	{
		drawRectangle(pen, r.x, r.y, r.width, r.height);
	}
	
	/// ditto
	final void drawRectangle(Pen pen, int x, int y, int width, int height)
	{
		HPEN prevPen;
		HBRUSH prevBrush;
		
		prevPen = SelectObject(hdc, pen.handle);
		prevBrush = SelectObject(hdc, cast(HBRUSH)GetStockObject(NULL_BRUSH)); // Don't fill it in.
		
		dfl.internal.winapi.Rectangle(hdc, x, y, x + width, y + height);
		
		// Reset stuff.
		SelectObject(hdc, prevPen);
		SelectObject(hdc, prevBrush);
	}
	
	
	/+
	final void drawRectangle(Color c, Rect r)
	{
		drawRectangle(c, r.x, r.y, r.width, r.height);
	}
	
	
	final void drawRectangle(Color c, int x, int y, int width, int height)
	{
		
	}
	+/
	
	
	///
	final void drawRectangles(Pen pen, Rect[] rs)
	{
		HPEN prevPen;
		HBRUSH prevBrush;
		
		prevPen = SelectObject(hdc, pen.handle);
		prevBrush = SelectObject(hdc, cast(HBRUSH)GetStockObject(NULL_BRUSH)); // Don't fill it in.
		
		foreach(ref Rect r; rs)
		{
			dfl.internal.winapi.Rectangle(hdc, r.x, r.y, r.x + r.width, r.y + r.height);
		}
		
		// Reset stuff.
		SelectObject(hdc, prevPen);
		SelectObject(hdc, prevBrush);
	}
	
	
	///
	// Force pending graphics operations.
	final void flush()
	{
		GdiFlush();
	}
	
	
	///
	final Color getNearestColor(Color c)
	{
		COLORREF cref;
		cref = GetNearestColor(handle, c.toRgb());
		if(CLR_INVALID == cref)
			return Color.empty;
		return Color.fromRgb(c.a, cref); // Preserve alpha.
	}
	
	
	///
	final Size getScaleSize(Font f)
	{
		// http://support.microsoft.com/kb/125681
		Size result;
		version(DIALOG_BOX_SCALE)
		{
			enum SAMPLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz";
			result = measureText(SAMPLE, f);
			result.width = (result.width / (SAMPLE.length / 2) + 1) / 2;
			TEXTMETRICA tma;
			if(GetTextMetricsA(handle, &tma))
				result.height = tma.tmHeight;
		}
		else
		{
			enum SAMPLE = "Abcdefghijklmnopqrstuvwxyz";
			result = measureText(SAMPLE, f);
			result.width /= SAMPLE.length;
		}
		return result;
	}
	
	
	final bool copyTo(HDC dest, int destX, int destY, int width, int height, int srcX = 0, int srcY = 0, DWORD rop = SRCCOPY) // package
	{
		return cast(bool)dfl.internal.winapi.BitBlt(dest, destX, destY, width, height, this.handle, srcX, srcY, rop);
	}
	
	
	///
	final bool copyTo(Graphics destGraphics, int destX, int destY, int width, int height, int srcX = 0, int srcY = 0, DWORD rop = SRCCOPY)
	{
		return copyTo(destGraphics.handle, destX, destY, width, height, srcX, srcY, rop);
	}
	
	/// ditto
	final bool copyTo(Graphics destGraphics, Rect bounds)
	{
		return copyTo(destGraphics.handle, bounds.x, bounds.y, bounds.width, bounds.height);
	}
	
	
	///
	final @property HDC handle() // getter
	{
		return hdc;
	}
	
	
	///
	void dispose()
	{
		assert(owned);
		DeleteDC(hdc);
		hdc = null;
	}
	
	
	private:
	HDC hdc;
	bool owned = true;
}


/// Graphics for a surface in memory.
class MemoryGraphics: Graphics // docmain
{
	///
	// Graphics compatible with the current screen.
	this(int width, int height)
	{
		HDC hdc;
		hdc = GetWindowDC(null);
		scope(exit)
			ReleaseDC(null, hdc);
		this(width, height, hdc);
	}
	
	
	/// ditto
	// graphicsCompatible cannot be another MemoryGraphics.
	this(int width, int height, Graphics graphicsCompatible)
	{
		if(cast(MemoryGraphics)graphicsCompatible)
		{
			//throw new DflException("Graphics cannot be compatible with memory");
			assert(0, "Graphics cannot be compatible with memory");
		}
		this(width, height, graphicsCompatible.handle);
	}
	
	
	// Used internally.
	this(int width, int height, HDC hdcCompatible) // package
	{
		_w = width;
		_h = height;
		
		hbm = CreateCompatibleBitmap(hdcCompatible, width, height);
		if(!hbm)
			throw new DflException("Unable to allocate Graphics memory");
		scope(failure)
		{
			DeleteObject(hbm);
			//hbm = HBITMAP.init;
		}
		
		HDC hdcc;
		hdcc = CreateCompatibleDC(hdcCompatible);
		if(!hdcc)
			throw new DflException("Unable to allocate Graphics");
		scope(failure)
			DeleteDC(hdcc);
		
		hbmOld = SelectObject(hdcc, hbm);
		scope(failure)
			SelectObject(hdcc, hbmOld);
		
		super(hdcc);
	}
	
	
	///
	final @property int width() // getter
	{
		return _w;
	}
	
	
	///
	final @property int height() // getter
	{
		return _h;
	}
	
	
	final Size size() // getter
	{
		return Size(_w, _h);
	}
	
	
	///
	final @property HBITMAP hbitmap() // getter // package
	{
		return hbm;
	}
	
	
	// Needs to copy so it can be selected into other DC`s.
	final HBITMAP toHBitmap(HDC hdc) // package
	{
		HDC memdc;
		HBITMAP result;
		HGDIOBJ oldbm;
		memdc = CreateCompatibleDC(hdc);
		if(!memdc)
			throw new DflException("Device error");
		try
		{
			result = CreateCompatibleBitmap(hdc, width, height);
			if(!result)
			{
				bad_bm:
				throw new DflException("Unable to allocate image");
			}
			oldbm = SelectObject(memdc, result);
			copyTo(memdc, 0, 0, width, height);
		}
		finally
		{
			if(oldbm)
				SelectObject(memdc, oldbm);
			DeleteDC(memdc);
		}
		return result;
	}
	
	
	final Bitmap toBitmap(HDC hdc) // package
	{
		HBITMAP hbm;
		hbm = toHBitmap(hdc);
		if(!hbm)
			throw new DflException("Unable to create bitmap");
		return new Bitmap(hbm, true); // Owned.
	}
	
	
	///
	final Bitmap toBitmap()
	{
		Graphics g;
		Bitmap result;
		g = Graphics.getScreen();
		result = toBitmap(g);
		g.dispose();
		return result;
	}
	
	/// ditto
	final Bitmap toBitmap(Graphics g)
	{
		return toBitmap(g.handle);
	}
	
	
	///
	override void dispose()
	{
		SelectObject(hdc, hbmOld);
		hbmOld = HGDIOBJ.init;
		DeleteObject(hbm);
		hbm = HBITMAP.init;
		super.dispose();
	}
	
	
	private:
	HGDIOBJ hbmOld;
	HBITMAP hbm;
	int _w, _h;
}


// Use with GetDC()/GetWindowDC()/GetDCEx() so that
// the HDC is properly released instead of deleted.
package class CommonGraphics: Graphics
{
	// Used internally.
	this(HWND hwnd, HDC hdc, bool owned = true)
	{
		super(hdc, owned);
		this.hwnd = hwnd;
	}
	
	
	override void dispose()
	{
		ReleaseDC(hwnd, hdc);
		hdc = null;
	}
	
	
	package:
	HWND hwnd;
}


///
class Icon: Image // docmain
{
	// Used internally.
	this(HICON hi, bool owned = true)
	{
		this.hi = hi;
		this.owned = owned;
	}
	
	///
	// Load from an ico file.
	this(Dstring fileName)
	{
		this.hi = cast(HICON)dfl.internal.utf.loadImage(null, fileName, IMAGE_ICON, 0, 0, LR_LOADFROMFILE);
		if(!this.hi)
			throw new DflException("Unable to load icon from file '" ~ fileName ~ "'");
	}
	
	
	///
	deprecated static Icon fromHandle(HICON hi)
	{
		return new Icon(hi, false); // Not owned. Up to caller to manage or call dispose().
	}
	
	
	// -bm- can be null.
	// NOTE: the bitmaps in -ii- need to be deleted! _deleteBitmaps() is a shortcut.
	private void _getInfo(ICONINFO* ii, BITMAP* bm = null)
	{
		if(GetIconInfo(hi, ii))
		{
			if(!bm)
				return;
			
			HBITMAP hbm;
			if(ii.hbmColor)
				hbm = ii.hbmColor;
			else // Monochrome.
				hbm = ii.hbmMask;
			if(GetObjectA(hbm, BITMAP.sizeof, bm) == BITMAP.sizeof)
				return;
		}
		
		// Fell through, failed.
		throw new DflException("Unable to get image information");
	}
	
	
	private void _deleteBitmaps(ICONINFO* ii)
	{
		DeleteObject(ii.hbmColor);
		ii.hbmColor = null;
		DeleteObject(ii.hbmMask);
		ii.hbmMask = null;
	}
	
	
	///
	final Bitmap toBitmap()
	{
		ICONINFO ii;
		BITMAP bm;
		_getInfo(&ii, &bm);
		// Not calling _deleteBitmaps() because I'm keeping one.
		
		HBITMAP hbm;
		if(ii.hbmColor)
		{
			hbm = ii.hbmColor;
			DeleteObject(ii.hbmMask);
		}
		else // Monochrome.
		{
			hbm = ii.hbmMask;
		}
		
		return new Bitmap(hbm, true); // Yes owned.
	}
	
	
	///
	final override void draw(Graphics g, Point pt)
	{
		g.drawIcon(this, pt.x, pt.y);
	}
	
	
	///
	final override void drawStretched(Graphics g, Rect r)
	{
		g.drawIcon(this, r);
	}
	
	
	///
	final override @property Size size() // getter
	{
		ICONINFO ii;
		BITMAP bm;
		_getInfo(&ii, &bm);
		_deleteBitmaps(&ii);
		return Size(bm.bmWidth, bm.bmHeight);
	}
	
	
	///
	final override @property int width() // getter
	{
		return size.width;
	}
	
	
	///
	final override @property int height() // getter
	{
		return size.height;
	}
	
	
	~this()
	{
		if(owned)
			dispose();
	}
	
	
	override int _imgtype(HGDIOBJ* ph) // internal
	{
		if(ph)
			*ph = cast(HGDIOBJ)hi;
		return 2;
	}
	
	
	///
	void dispose()
	{
		assert(owned);
		DestroyIcon(hi);
		hi = null;
	}
	
	
	///
	final @property HICON handle() // getter
	{
		return hi;
	}
	
	
	private:
	HICON hi;
	bool owned = true;
}


///
enum GraphicsUnit: ubyte // docmain ?
{
	///
	PIXEL,
	/// ditto
	DISPLAY, // 1/75 inch.
	/// ditto
	DOCUMENT, // 1/300 inch.
	/// ditto
	INCH, // 1 inch, der.
	/// ditto
	MILLIMETER, // 25.4 millimeters in 1 inch.
	/// ditto
	POINT, // 1/72 inch.
	//WORLD, // ?
	TWIP, // Extra. 1/1440 inch.
}


/+
// TODO: check if correct implementation.
enum GenericFontFamilies
{
	MONOSPACE = FF_MODERN,
	SANS_SERIF = FF_ROMAN,
	SERIF = FF_SWISS,
}
+/


/+
abstract class FontCollection
{
	abstract @property FontFamily[] families(); // getter
}


class FontFamily
{
	/+
	this(GenericFontFamilies genericFamily)
	{
		
	}
	+/
	
	
	this(Dstring name)
	{
		
	}
	
	
	this(Dstring name, FontCollection fontCollection)
	{
		
	}
	
	
	final @property Dstring name() // getter
	{
		
	}
	
	
	static @property FontFamily[] families() // getter
	{
		
	}
	
	
	/+
	// TODO: implement.
	
	static @property FontFamily genericMonospace() // getter
	{
		
	}
	
	
	static @property FontFamily genericSansSerif() // getter
	{
		
	}
	
	
	static @property FontFamily genericSerif() // getter
	{
		
	}
	+/
}
+/


///
// Flags.
enum FontStyle: ubyte
{
	REGULAR = 0, ///
	BOLD = 1, /// ditto
	ITALIC = 2, /// ditto
	UNDERLINE = 4, /// ditto
	STRIKEOUT = 8, /// ditto
}


///
enum FontSmoothing
{
	DEFAULT = DEFAULT_QUALITY,
	ON = ANTIALIASED_QUALITY,
	OFF = NONANTIALIASED_QUALITY,
}


///
class Font // docmain
{
	// Used internally.
	static void LOGFONTAtoLogFont(ref LogFont lf, LOGFONTA* plfa) // package // deprecated
	{
		lf.lfa = *plfa;
		lf.faceName = dfl.internal.utf.fromAnsiz(plfa.lfFaceName.ptr);
	}
	
	// Used internally.
	static void LOGFONTWtoLogFont(ref LogFont lf, LOGFONTW* plfw) // package // deprecated
	{
		lf.lfw = *plfw;
		lf.faceName = dfl.internal.utf.fromUnicodez(plfw.lfFaceName.ptr);
	}
	
	
	// Used internally.
	this(HFONT hf, LOGFONTA* plfa, bool owned = true) // package // deprecated
	{
		LogFont lf;
		LOGFONTAtoLogFont(lf, plfa);
		
		this.hf = hf;
		this.owned = owned;
		this._unit = GraphicsUnit.POINT;
		
		_fstyle = _style(lf);
		_initLf(lf);
	}
	
	
	// Used internally.
	this(HFONT hf, ref LogFont lf, bool owned = true) // package
	{
		this.hf = hf;
		this.owned = owned;
		this._unit = GraphicsUnit.POINT;
		
		_fstyle = _style(lf);
		_initLf(lf);
	}
	
	
	// Used internally.
	this(HFONT hf, bool owned = true) // package
	{
		this.hf = hf;
		this.owned = owned;
		this._unit = GraphicsUnit.POINT;
		
		LogFont lf;
		_info(lf);
		
		_fstyle = _style(lf);
		_initLf(lf);
	}
	
	
	// Used internally.
	this(LOGFONTA* plfa, bool owned = true) // package // deprecated
	{
		LogFont lf;
		LOGFONTAtoLogFont(lf, plfa);
		
		this(_create(lf), lf, owned);
	}
	
	
	// Used internally.
	this(ref LogFont lf, bool owned = true) // package
	{
		this(_create(lf), lf, owned);
	}
	
	
	package static HFONT _create(ref LogFont lf)
	{
		HFONT result;
		result = dfl.internal.utf.createFontIndirect(lf);
		if(!result)
			throw new DflException("Unable to create font");
		return result;
	}
	
	
	private static void _style(ref LogFont lf, FontStyle style)
	{
		lf.lf.lfWeight = (style & FontStyle.BOLD) ? FW_BOLD : FW_NORMAL;
		lf.lf.lfItalic = (style & FontStyle.ITALIC) ? TRUE : FALSE;
		lf.lf.lfUnderline = (style & FontStyle.UNDERLINE) ? TRUE : FALSE;
		lf.lf.lfStrikeOut = (style & FontStyle.STRIKEOUT) ? TRUE : FALSE;
	}
	
	
	private static FontStyle _style(ref LogFont lf)
	{
		FontStyle style = FontStyle.REGULAR;
		
		if(lf.lf.lfWeight >= FW_BOLD)
			style |= FontStyle.BOLD;
		if(lf.lf.lfItalic)
			style |= FontStyle.ITALIC;
		if(lf.lf.lfUnderline)
			style |= FontStyle.UNDERLINE;
		if(lf.lf.lfStrikeOut)
			style |= FontStyle.STRIKEOUT;
		
		return style;
	}
	
	
	package void _info(LOGFONTA* lf) // deprecated
	{
		if(GetObjectA(hf, LOGFONTA.sizeof, lf) != LOGFONTA.sizeof)
			throw new DflException("Unable to get font information");
	}
	
	package void _info(LOGFONTW* lf) // deprecated
	{
		auto proc = cast(GetObjectWProc)GetProcAddress(GetModuleHandleA("gdi32.dll"), "GetObjectW");
		
		if(!proc || proc(hf, LOGFONTW.sizeof, lf) != LOGFONTW.sizeof)
			throw new DflException("Unable to get font information");
	}
	
	
	package void _info(ref LogFont lf)
	{
		if(!dfl.internal.utf.getLogFont(hf, lf))
			throw new DflException("Unable to get font information");
	}
	
	
	package static LONG getLfHeight(float emSize, GraphicsUnit unit)
	{
		LONG result;
		HDC hdc;
		
		final switch(unit)
		{
			case GraphicsUnit.PIXEL:
				result = cast(LONG)emSize;
				break;
			
			case GraphicsUnit.POINT:
				hdc = GetWindowDC(null);
				result = MulDiv(cast(int)(emSize * 100), GetDeviceCaps(hdc, LOGPIXELSY), 72 * 100);
				ReleaseDC(null, hdc);
				break;
			
			case GraphicsUnit.DISPLAY:
				hdc = GetWindowDC(null);
				result = MulDiv(cast(int)(emSize * 100), GetDeviceCaps(hdc, LOGPIXELSY), 75 * 100);
				ReleaseDC(null, hdc);
				break;
			
			case GraphicsUnit.MILLIMETER:
				hdc = GetWindowDC(null);
				result = MulDiv(cast(int)(emSize * 100), GetDeviceCaps(hdc, LOGPIXELSY), 2540);
				ReleaseDC(null, hdc);
				break;
			
			case GraphicsUnit.INCH:
				hdc = GetWindowDC(null);
				result = cast(LONG)(emSize * cast(float)GetDeviceCaps(hdc, LOGPIXELSY));
				ReleaseDC(null, hdc);
				break;
			
			case GraphicsUnit.DOCUMENT:
				hdc = GetWindowDC(null);
				result = MulDiv(cast(int)(emSize * 100), GetDeviceCaps(hdc, LOGPIXELSY), 300 * 100);
				ReleaseDC(null, hdc);
				break;
			
			case GraphicsUnit.TWIP:
				hdc = GetWindowDC(null);
				result = MulDiv(cast(int)(emSize * 100), GetDeviceCaps(hdc, LOGPIXELSY), 1440 * 100);
				ReleaseDC(null, hdc);
				break;
		}
		
		return result;
	}
	
	
	package static float getEmSize(HDC hdc, LONG lfHeight, GraphicsUnit toUnit)
	{
		float result;
		
		if(lfHeight < 0)
			lfHeight = -lfHeight;
		
		final switch(toUnit)
		{
			case GraphicsUnit.PIXEL:
				result = cast(float)lfHeight;
				break;
			
			case GraphicsUnit.POINT:
				result = cast(float)MulDiv(lfHeight, 72, GetDeviceCaps(hdc, LOGPIXELSY));
				break;
			
			case GraphicsUnit.DISPLAY:
				result = cast(float)MulDiv(lfHeight, 75, GetDeviceCaps(hdc, LOGPIXELSY));
				break;
			
			case GraphicsUnit.MILLIMETER:
				result = cast(float)MulDiv(lfHeight, 254, GetDeviceCaps(hdc, LOGPIXELSY)) / 10.0;
				break;
			
			case GraphicsUnit.INCH:
				result = cast(float)lfHeight / cast(float)GetDeviceCaps(hdc, LOGPIXELSY);
				break;
			
			case GraphicsUnit.DOCUMENT:
				result = cast(float)MulDiv(lfHeight, 300, GetDeviceCaps(hdc, LOGPIXELSY));
				break;
			
			case GraphicsUnit.TWIP:
				result = cast(float)MulDiv(lfHeight, 1440, GetDeviceCaps(hdc, LOGPIXELSY));
				break;
		}
		
		return result;
	}
	
	
	package static float getEmSize(LONG lfHeight, GraphicsUnit toUnit)
	{
		if(GraphicsUnit.PIXEL == toUnit)
		{
			if(lfHeight < 0)
				return cast(float)-lfHeight;
			return cast(float)lfHeight;
		}
		HDC hdc;
		hdc = GetWindowDC(null);
		float result = getEmSize(hdc, lfHeight, toUnit);
		ReleaseDC(null, hdc);
		return result;
	}
	
	
	///
	this(Font font, FontStyle style)
	{
		LogFont lf;
		_unit = font._unit;
		font._info(lf);
		_style(lf, style);
		this(_create(lf));
		
		_fstyle = style;
		_initLf(font, lf);
	}
	
	/// ditto
	this(Dstring name, float emSize, GraphicsUnit unit)
	{
		this(name, emSize, FontStyle.REGULAR, unit);
	}
	
	
	/// ditto
	this(Dstring name, float emSize, FontStyle style = FontStyle.REGULAR,
		GraphicsUnit unit = GraphicsUnit.POINT)
	{
		this(name, emSize, style, unit, DEFAULT_CHARSET, FontSmoothing.DEFAULT);
	}
	
	
	/// ditto
	this(Dstring name, float emSize, FontStyle style,
		GraphicsUnit unit, FontSmoothing smoothing)
	{
		this(name, emSize, style, unit, DEFAULT_CHARSET, smoothing);
	}
	
	// /// ditto
	// This is a somewhat internal function.
	// -gdiCharSet- is one of *_CHARSET from wingdi.h
	this(Dstring name, float emSize, FontStyle style,
		GraphicsUnit unit, ubyte gdiCharSet,
		FontSmoothing smoothing = FontSmoothing.DEFAULT)
	{
		LogFont lf;
		
		lf.faceName = name;
		lf.lf.lfCharSet = gdiCharSet;
		lf.lf.lfQuality = cast(BYTE)smoothing;
		lf.lf.lfOutPrecision = OUT_DEFAULT_PRECIS;
		lf.lf.lfClipPrecision = CLIP_DEFAULT_PRECIS;
		lf.lf.lfPitchAndFamily = DEFAULT_PITCH | FF_DONTCARE;
		
		this(lf, emSize, style, unit);
	}
	
	// /// ditto
	// This is a somewhat internal function.
	this(ref LogFont lf, float emSize, FontStyle style, GraphicsUnit unit)
	{
		_unit = unit;
		
		lf.lf.lfHeight = -getLfHeight(emSize, unit);
		_style(lf, style);
		
		this(_create(lf));
		
		_fstyle = style;
		_initLf(lf);
	}
	
	
	~this()
	{
		if(owned)
			DeleteObject(hf);
	}
	
	
	///
	final @property HFONT handle() // getter
	{
		return hf;
	}
	
	
	///
	final @property GraphicsUnit unit() // getter
	{
		return _unit;
	}
	
	
	///
	final @property float size() // getter
	{
		/+
		LOGFONTA lf;
		_info(&lf);
		return getEmSize(lf.lf.lfHeight, _unit);
		+/
		return getEmSize(this.lfHeight, _unit);
	}
	
	
	///
	final float getSize(GraphicsUnit unit)
	{
		/+
		LOGFONTA lf;
		_info(&lf);
		return getEmSize(lf.lf.lfHeight, unit);
		+/
		return getEmSize(this.lfHeight, unit);
	}
	
	/// ditto
	final float getSize(GraphicsUnit unit, Graphics g)
	{
		return getEmSize(g.handle, this.lfHeight, unit);
	}
	
	
	///
	final @property FontStyle style() // getter
	{
		return _fstyle;
	}
	
	
	///
	final @property Dstring name() // getter
	{
		return lfName;
	}
	
	
	final @property ubyte gdiCharSet() // getter
	{
		return lfCharSet;
	}
	
	
	/+
	private void _initLf(LOGFONTA* lf)
	{
		this.lfHeight = lf.lfHeight;
		this.lfName = stringFromStringz(lf.lfFaceName.ptr).dup;
		this.lfCharSet = lf.lfCharSet;
	}
	+/
	
	private void _initLf(ref LogFont lf)
	{
		this.lfHeight = lf.lf.lfHeight;
		this.lfName = lf.faceName;
		this.lfCharSet = lf.lf.lfCharSet;
	}
	
	
	/+
	private void _initLf(Font otherfont, LOGFONTA* lf)
	{
		this.lfHeight = otherfont.lfHeight;
		this.lfName = otherfont.lfName;
		this.lfCharSet = otherfont.lfCharSet;
	}
	+/
	
	private void _initLf(Font otherfont, ref LogFont lf)
	{
		this.lfHeight = otherfont.lfHeight;
		this.lfName = otherfont.lfName;
		this.lfCharSet = otherfont.lfCharSet;
	}
	
	
	private:
	HFONT hf;
	GraphicsUnit _unit;
	bool owned = true;
	FontStyle _fstyle;
	
	LONG lfHeight;
	Dstring lfName;
	ubyte lfCharSet;
}


///
enum PenStyle: UINT
{
	SOLID = PS_SOLID, ///
	DASH = PS_DASH, /// ditto
	DOT = PS_DOT, /// ditto
	DASH_DOT = PS_DASHDOT, /// ditto
	DASH_DOT_DOT = PS_DASHDOTDOT, /// ditto
	NULL = PS_NULL, /// ditto
	INSIDE_FRAME = PS_INSIDEFRAME, /// ditto
}


///
// If the pen width is greater than 1 the style cannot have dashes or dots.
class Pen // docmain
{
	// Used internally.
	this(HPEN hp, bool owned = true)
	{
		this.hp = hp;
		this.owned = owned;
	}
	
	
	///
	this(Color color, int width = 1, PenStyle ps = PenStyle.SOLID)
	{
		hp = CreatePen(ps, width, color.toRgb());
	}
	
	
	~this()
	{
		if(owned)
			DeleteObject(hp);
	}
	
	
	///
	final @property HPEN handle() // getter
	{
		return hp;
	}
	
	
	private:
	HPEN hp;
	bool owned = true;
}


///
class Brush // docmain
{
	// Used internally.
	this(HBRUSH hb, bool owned = true)
	{
		this.hb = hb;
		this.owned = owned;
	}
	
	
	protected this()
	{
	}
	
	
	~this()
	{
		if(owned)
			DeleteObject(hb);
	}
	
	
	///
	final @property HBRUSH handle() // getter
	{
		return hb;
	}
	
	
	private:
	HBRUSH hb;
	bool owned = true;
}


///
class SolidBrush: Brush // docmain
{
	///
	this(Color c)
	{
		super(CreateSolidBrush(c.toRgb()));
	}
	
	
	/+
	final @property void color(Color c) // setter
	{
		// delete..
		super.hb = CreateSolidBrush(c.toRgb());
	}
	+/
	
	
	///
	final @property Color color() // getter
	{
		Color result;
		LOGBRUSH lb;
		
		if(GetObjectA(hb, lb.sizeof, &lb))
		{
			result = Color.fromRgb(lb.lbColor);
		}
		
		return result;
	}
}


// PatternBrush has the win9x/ME limitation of not supporting images larger than 8x8 pixels.
// TextureBrush supports any size images but requires GDI+.


/+
class PatternBrush: Brush
{
	//CreatePatternBrush() ...
}
+/


/+
class TextureBrush: Brush
{
	// GDI+ ...
}
+/


///
enum HatchStyle: LONG
{
	HORIZONTAL = HS_HORIZONTAL, ///
	VERTICAL = HS_VERTICAL, /// ditto
	FORWARD_DIAGONAL = HS_FDIAGONAL, /// ditto
	BACKWARD_DIAGONAL = HS_BDIAGONAL, /// ditto
	CROSS = HS_CROSS, /// ditto
	DIAGONAL_CROSS = HS_DIAGCROSS, /// ditto
}


///
class HatchBrush: Brush // docmain
{
	///
	this(HatchStyle hs, Color c)
	{
		super(CreateHatchBrush(hs, c.toRgb()));
	}
	
	
	///
	final @property Color foregroundColor() // getter
	{
		Color result;
		LOGBRUSH lb;
		
		if(GetObjectA(hb, lb.sizeof, &lb))
		{
			result = Color.fromRgb(lb.lbColor);
		}
		
		return result;
	}
	
	
	///
	final @property HatchStyle hatchStyle() // getter
	{
		HatchStyle result;
		LOGBRUSH lb;
		
		if(GetObjectA(hb, lb.sizeof, &lb))
		{
			result = cast(HatchStyle)lb.lbHatch;
		}
		
		return result;
	}
}


///
class Region // docmain
{
	// Used internally.
	this(HRGN hrgn, bool owned = true)
	{
		this.hrgn = hrgn;
		this.owned = owned;
	}
	
	
	~this()
	{
		if(owned)
			DeleteObject(hrgn);
	}
	
	
	///
	final @property HRGN handle() // getter
	{
		return hrgn;
	}
	
	
	override Dequ opEquals(Object o)
	{
		Region rgn = cast(Region)o;
		if(!rgn)
			return 0; // Not equal.
		return opEquals(rgn);
	}
	
	
	Dequ opEquals(Region rgn)
	{
		return hrgn == rgn.hrgn;
	}
	
	
	private:
	HRGN hrgn;
	bool owned = true;
}

