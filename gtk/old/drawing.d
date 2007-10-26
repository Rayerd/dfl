// See the included license.txt for copyright and license details.


///
module dfl.drawing;

import dfl.internal.dlib, dfl.internal.gtk;
import dfl.base;


/// X and Y coordinate.
struct Point // docmain
{
	union
	{
		struct
		{
			gint x;
			gint y;
		}
		GdkPoint point; // package
	}
	
	
	/// Construct a new Point.
	static Point opCall(int x, int y)
	{
		Point pt;
		pt.x = x;
		pt.y = y;
		return pt;
	}
	
	/// ditto
	static Point opCall()
	{
		Point pt;
		return pt;
	}
	
	
	///
	int opEquals(Point pt)
	{
		return x == pt.x && y == pt.y;
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
	union
	{
		struct
		{
			gint width;
			gint height;
		}
		//GdkSize size; // package
	}
	
	
	/// Construct a new Size.
	static Size opCall(int width, int height)
	{
		Size sz;
		sz.width = width;
		sz.height = height;
		return sz;
	}
	
	/// ditto
	static Size opCall()
	{
		Size sz;
		return sz;
	}
	
	
	///
	int opEquals(Size sz)
	{
		return width == sz.width && height == sz.height;
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
	union
	{
		struct
		{
			gint x, y, width, height;
		}
		GdkRectangle rect; // package
	}
	
	// Used internally.
	void getRect(GdkRectangle* r) // package
	{
		*r = rect;
	}
	
	
	///
	Point location() // getter
	{
		return Point(x, y);
	}
	
	/// ditto
	void location(Point pt) // setter
	{
		x = pt.x;
		y = pt.y;
	}
	
	
	///
	Size size() //getter
	{
		return Size(width, height);
	}
	
	/// ditto
	void size(Size sz) // setter
	{
		width = sz.width;
		height = sz.height;
	}
	
	
	///
	int right() // getter
	{
		return x + width;
	}
	
	
	///
	int bottom() // getter
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
	static Rect opCall(GdkRectangle* rect) // package
	{
		Rect r;
		r.rect = *rect;
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
	
	
	///
	int opEquals(Rect r)
	{
		return x == r.x && y == r.y &&
			width == r.width && height == r.height;
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
	ubyte r() // getter
	{ validateColor(); return color.red; }
	
	/// ditto
	ubyte g() // getter
	{ validateColor(); return color.green; }
	
	/// ditto
	ubyte b() // getter
	{ validateColor(); return color.blue; }
	
	/// ditto
	ubyte a() // getter
	{ /+ validateColor(); +/ return color.alpha; }
	
	
	/// Return the numeric color value.
	guint32 toArgb()
	{
		validateColor();
		return color.cref;
	}
	
	
	/// Return the numeric red, green and blue color value.
	guint32 toRgb()
	{
		validateColor();
		return color.cref & 0x00FFFFFF;
	}
	
	
	/// Construct a new color.
	static Color opCall(ubyte alpha, Color c)
	{
		Color nc;
		nc.color.blue = c.color.blue;
		nc.color.green = c.color.green;
		nc.color.red = c.color.red;
		nc.color.alpha = alpha;
		return nc;
	}
	
	/// ditto
	static Color opCall(ubyte red, ubyte green, ubyte blue)
	{
		Color nc;
		nc.color.blue = blue;
		nc.color.green = green;
		nc.color.red = red;
		nc.color.alpha = 0xFF;
		return nc;
	}
	
	/// ditto
	static Color opCall(ubyte alpha, ubyte red, ubyte green, ubyte blue)
	{
		return fromArgb(alpha, red, green, blue);
	}
	
	/// ditto
	//alias opCall fromArgb;
	static Color fromArgb(ubyte alpha, ubyte red, ubyte green, ubyte blue)
	{
		Color nc;
		nc.color.blue = blue;
		nc.color.green = green;
		nc.color.red = red;
		nc.color.alpha = alpha;
		return nc;
	}
	
	/// ditto
	static Color fromRgb(guint32 rgb)
	{
		if(0xFFFFFFFF == rgb)
			return empty;
		Color nc;
		nc.color.cref = rgb;
		nc.color.alpha = 0xFF;
		return nc;
	}
	
	/// ditto
	static Color fromRgb(ubyte alpha, guint32 rgb)
	{
		Color nc;
		nc.color.cref = rgb | ((cast(guint32)alpha) << 24);
		return nc;
	}
	
	/// ditto
	static Color empty() // getter
	{
		return Color(0, 0, 0, 0);
	}
	
	
	/// Return a completely transparent color value.
	static Color transparent() // getter
	{
		return Color.fromArgb(0, 0xFF, 0xFF, 0xFF);
	}
	
	
	deprecated alias blendColor blend;
	
	
	/// Blend colors; alpha channels are ignored.
	// Blends the color channels half way.
	// Does not consider alpha channels and discards them.
	// The new blended color is returned; -this- Color is not modified.
	Color blendColor(Color wc)
	{
		if(*this == Color.empty)
			return wc;
		if(wc == Color.empty)
			return *this;
		
		validateColor();
		wc.validateColor();
		
		return Color((cast(uint)color.red + cast(uint)wc.color.red) >> 1,
			(cast(uint)color.green + cast(uint)wc.color.green) >> 1,
			(cast(uint)color.blue + cast(uint)wc.color.blue) >> 1);
	}
	
	
	/// Alpha blend this color with a background color to return a solid color (100% opaque).
	// Blends with backColor if this color has opacity to produce a solid color.
	// Returns the new solid color, or the original color if no opacity.
	// If backColor has opacity, it is ignored.
	// The new blended color is returned; -this- Color is not modified.
	Color solidColor(Color backColor)
	{
		//if(0x7F == this.color.alpha)
		//	return blendColor(backColor);
		//if(*this == Color.empty) // Checked if(0 == this.color.alpha)
		//	return backColor;
		if(0 == this.color.alpha)
			return backColor;
		if(backColor == Color.empty)
			return *this;
		if(0xFF == this.color.alpha)
			return *this;
		
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
	
	
	/+
	package static Color systemColor(int colorIndex)
	{
		Color c;
		c.sysIndex = colorIndex;
		c.color.alpha = 0xFF;
		return c;
	}
	
	
	// Gets color index or INVAILD_SYSTEM_COLOR_INDEX.
	package int _systemColorIndex() // getter
	{
		return sysIndex;
	}
	
	
	package const ubyte INVAILD_SYSTEM_COLOR_INDEX = ubyte.max;
	+/
	
	
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
		guint32 cref;
	}
	static assert(_color.sizeof == guint32.sizeof);
	_color color;
	
	
	void validateColor()
	{
		/+
		if(sysIndex != INVAILD_SYSTEM_COLOR_INDEX)
		{
			color.cref = GetSysColor(sysIndex);
			//color.alpha = 0xFF; // Should already be set.
		}
		+/
	}
}


/+ // To-do: ...
///
class SystemColors // docmain
{
	private this()
	{
	}
	
	
	static:
	
	///
	Color activeBorder() // getter
	{
		return Color.systemColor(COLOR_ACTIVEBORDER);
	}
	
	/// ditto
	Color activeCaption() // getter
	{
		return Color.systemColor(COLOR_ACTIVECAPTION);
	}
	
	/// ditto
	Color activeCaptionText() // getter
	{
		return Color.systemColor(COLOR_CAPTIONTEXT);
	}
	
	/// ditto
	Color appWorkspace() // getter
	{
		return Color.systemColor(COLOR_APPWORKSPACE);
	}
	
	/// ditto
	Color control() // getter
	{
		return Color.systemColor(COLOR_BTNFACE);
	}
	
	/// ditto
	Color controlDark() // getter
	{
		return Color.systemColor(COLOR_BTNSHADOW);
	}
	
	/// ditto
	Color controlDarkDark() // getter
	{
		return Color.systemColor(COLOR_3DDKSHADOW); // ?
	}
	
	/// ditto
	Color controlLight() // getter
	{
		return Color.systemColor(COLOR_3DLIGHT);
	}
	
	/// ditto
	Color controlLightLight() // getter
	{
		return Color.systemColor(COLOR_BTNHIGHLIGHT); // ?
	}
	
	/// ditto
	Color controlText() // getter
	{
		return Color.systemColor(COLOR_BTNTEXT);
	}
	
	/// ditto
	Color desktop() // getter
	{
		return Color.systemColor(COLOR_DESKTOP);
	}
	
	/// ditto
	Color grayText() // getter
	{
		return Color.systemColor(COLOR_GRAYTEXT);
	}
	
	/// ditto
	Color highlight() // getter
	{
		return Color.systemColor(COLOR_HIGHLIGHT);
	}
	
	/// ditto
	Color highlightText() // getter
	{
		return Color.systemColor(COLOR_HIGHLIGHTTEXT);
	}
	
	/// ditto
	Color hotTrack() // getter
	{
		return Color(0, 0, 0xFF); // ?
	}
	
	/// ditto
	Color inactiveBorder() // getter
	{
		return Color.systemColor(COLOR_INACTIVEBORDER);
	}
	
	/// ditto
	Color inactiveCaption() // getter
	{
		return Color.systemColor(COLOR_INACTIVECAPTION);
	}
	
	/// ditto
	Color inactiveCaptionText() // getter
	{
		return Color.systemColor(COLOR_INACTIVECAPTIONTEXT);
	}
	
	/// ditto
	Color info() // getter
	{
		return Color.systemColor(COLOR_INFOBK);
	}
	
	/// ditto
	Color infoText() // getter
	{
		return Color.systemColor(COLOR_INFOTEXT);
	}
	
	/// ditto
	Color menu() // getter
	{
		return Color.systemColor(COLOR_MENU);
	}
	
	/// ditto
	Color menuText() // getter
	{
		return Color.systemColor(COLOR_MENUTEXT);
	}
	
	/// ditto
	Color scrollBar() // getter
	{
		return Color.systemColor(CTLCOLOR_SCROLLBAR);
	}
	
	/// ditto
	Color window() // getter
	{
		return Color.systemColor(COLOR_WINDOW);
	}
	
	/// ditto
	Color windowFrame() // getter
	{
		return Color.systemColor(COLOR_WINDOWFRAME);
	}
	
	/// ditto
	Color windowText() // getter
	{
		return Color.systemColor(COLOR_WINDOWTEXT);
	}
}
+/


/+ // To-do: ...
///
class SystemIcons // docmain
{
	private this()
	{
	}
	
	
	static:
	
	///
	Icon application() // getter
	{
		return new Icon(LoadImageA(null, IDI_APPLICATION,
			 IMAGE_ICON, 0, 0, LR_DEFAULTSIZE | LR_SHARED), false);
	}
	
	/// ditto
	Icon error() // getter
	{
		return new Icon(LoadImageA(null, IDI_HAND,
			 IMAGE_ICON, 0, 0, LR_DEFAULTSIZE | LR_SHARED), false);
	}
	
	/// ditto
	Icon question() // getter
	{
		return new Icon(LoadImageA(null, IDI_QUESTION,
			 IMAGE_ICON, 0, 0, LR_DEFAULTSIZE | LR_SHARED), false);
	}
	
	/// ditto
	Icon warning() // getter
	{
		return new Icon(LoadImageA(null, IDI_EXCLAMATION,
			 IMAGE_ICON, 0, 0, LR_DEFAULTSIZE | LR_SHARED), false);
	}
}
+/


///
abstract class Image // docmain
{
	//flags(); // getter ???
	
	
	/+
	final ImageFormat rawFormat(); // getter
	+/
	
	
	static Bitmap fromHBitmap(GdkBitmap* hbm) // package
	{
		return new Bitmap(hbm, false); // Not owned. Up to caller to manage or call dispose().
	}
	
	
	/+
	static Image fromFile(char[] file)
	{
		return new Image(LoadImageA());
	}
	+/
	
	
	///
	void draw(Graphics g, Point pt);
	/// ditto
	void drawStretched(Graphics g, Rect r);
	
	
	///
	Size size(); // getter
	
	
	///
	int width() // getter
	{
		return size.width;
	}
	
	
	///
	int height() // getter
	{
		return size.height;
	}
}


// To-do: derive from Image when supported!
///
class Bitmap//: Image // docmain
{
	///
	// Load from a bmp file.
	this(char[] fileName)
	{
		//this.hbm = 
		// To-do: ...
		if(!this.hbm)
			throw new DflException("Unable to load bitmap from file '" ~ fileName ~ "'");
	}
	
	// Used internally.
	this(GdkBitmap* hbm, bool owned = true)
	{
		this.hbm = hbm;
		this.owned = owned;
	}
	
	
	///
	final GdkBitmap* handle() // getter
	{
		return hbm;
	}
	
	
	/+
	private void _getInfo(BITMAP* bm)
	{
		if(GetObjectA(hbm, BITMAP.sizeof, bm) != BITMAP.sizeof)
			throw new DflException("Unable to get image information");
	}
	+/
	
	
	/+
	///
	final override Size size() // getter
	{
		/+
		BITMAP bm;
		_getInfo(&bm);
		return Size(bm.bmWidth, bm.bmHeight);
		+/
		// To-do: ...
	}
	+/
	
	
	/+
	///
	final override int width() // getter
	{
		return size.width;
	}
	
	
	///
	final override int height() // getter
	{
		return size.height;
	}
	+/
	
	
	/+ // To-do: ... ...
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
	+/
	
	
	///
	void dispose()
	{
		if(hbm)
		{
			g_object_unref(hbm);
			hbm = null;
		}
	}
	
	
	~this()
	{
		if(owned)
			dispose();
	}
	
	
	private:
	GdkBitmap* hbm;
	bool owned = true;
}


// To-do: ...

///
enum TextTrimming: uint
{
	_none,
}


///
enum TextFormatFlags: uint
{
	_none,
}


///
enum TextAlignment: uint
{
	_none,
}


/+ // To-do: ...
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
	static TextFormat genericDefault() // getter
	{
		TextFormat result;
		result = new TextFormat;
		result._trim = TextTrimming.NONE;
		result._flags = TextFormatFlags.NO_PREFIX | TextFormatFlags.WORD_BREAK |
			TextFormatFlags.NO_CLIP | TextFormatFlags.LINE_LIMIT;
		return result;
	}
	
	/// ditto
	static TextFormat genericTypographic() // getter
	{
		return new TextFormat;
	}
	
	
	///
	final void alignment(TextAlignment ta) // setter
	{
		_align = ta;
	}
	
	/// ditto
	final TextAlignment alignment() // getter
	{
		return _align;
	}
	
	
	///
	final void formatFlags(TextFormatFlags tff) // setter
	{
		_flags = tff;
	}
	
	/// ditto
	final TextFormatFlags formatFlags() // getter
	{
		return _flags;
	}
	
	
	///
	final void trimming(TextTrimming tt) // getter
	{
		_trim = tt;
	}
	
	/// ditto
	final TextTrimming trimming() // getter
	{
		return _trim;
	}
	
	
	// Units of the average character width.
	
	///
	final void tabLength(int tablen) // setter
	{
		_params.iTabLength = tablen;
	}
	
	/// ditto
	final int tabLength() // getter
	{
		return _params.iTabLength;
	}
	
	
	// Units of the average character width.
	
	///
	final void leftMargin(int sz) // setter
	{
		_params.iLeftMargin = sz;
	}
	
	/// ditto
	final int leftMargin() // getter
	{
		return _params.iLeftMargin;
	}
	
	
	// Units of the average character width.
	
	///
	final void rightMargin(int sz) // setter
	{
		_params.iRightMargin = sz;
	}
	
	/// ditto
	final int rightMargin() // getter
	{
		return _params.iRightMargin;
	}
	
	
	private:
	TextTrimming _trim = TextTrimming.NONE; // TextTrimming.CHARACTER.
	TextFormatFlags _flags = TextFormatFlags.NO_PREFIX | TextFormatFlags.WORD_BREAK;
	TextAlignment _align = TextAlignment.LEFT;
	package DRAWTEXTPARAMS _params = { DRAWTEXTPARAMS.sizeof, 8, 0, 0 };
}
+/


// To-do: ...

///
class Graphics // docmain
{
	// Used internally.
	this(GdkGC* hdc, bool owned = true)
	{
		this.hdc = hdc;
		this.owned = owned;
	}
	
	
	~this()
	{
		if(owned)
			dispose();
	}
	
	
	void fillRectangle(Color c, Rect r)
	{
		// STUB
	}
	
	
	///
	final GdkGC* handle() // getter
	{
		return hdc;
	}
	
	
	///
	void dispose()
	{
		if(hdc)
		{
			gdk_gc_unref(hdc);
			hdc = null;
		}
	}
	
	
	private:
	GdkGC* hdc;
	bool owned = true;
}


// To-do: ...


///
class Font // docmain
{
}


// To-do: ...

