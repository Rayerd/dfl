// Copyright (C) 2007 Christopher E. Miller
// See the included license.txt for license details.


///
module dfl.drawing;


import dfl.internal.gtk;


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
	int width;
	int height;
	
	
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
	gint x, y, width, height;
	
	// Used internally.
	void getRect(GdkRectangle* r) // package
	{
		*r = *cast(GdkRectangle*)this;
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
		r = *cast(Rect*)rect;
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
}

