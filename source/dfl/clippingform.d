module dfl.clippingform;

import dfl.base;
import dfl.form;
import dfl.control;
import dfl.event;
import dfl.drawing;

import dfl.internal.dlib : toI32;

import core.memory;
import core.sys.windows.windows;

///
struct RegionRects
{
private:
	RGNDATA* _rgn = null;
	size_t _capacity = 0;
	size_t _width = 0;
	size_t _height = 0;

public:
	@property size_t width() const
	{
		return _width;
	}
	
	
	///
	@property size_t height() const
	{
		return _height;
	}
	
	
	///
	void clear()
	{
		if (_rgn)
		{
			GC.free(_rgn);
		}
		_rgn = null;
		_capacity = 0;
		_width = 0;
		_height = 0;
	}
	
	
	///
	void add(RECT rc)
	{
		if (_capacity == 0)
		{
			_capacity = 1024;
			_rgn = cast(RGNDATA*) GC.malloc(
				RGNDATAHEADER.sizeof + RECT.sizeof * _capacity);
			_rgn.rdh.nCount = 0;
		}
		else if (_rgn.rdh.nCount == _capacity)
		{
			_capacity *= 2;
			_rgn = cast(RGNDATA*) GC.realloc(cast(void*)_rgn,
				RGNDATAHEADER.sizeof + RECT.sizeof * _capacity);
		}
		(cast(RECT*)_rgn.Buffer.ptr)[_rgn.rdh.nCount++] = rc;
	}
	
	
	/// ditto
	void add(int l, int t, int r, int b)
	{
		add(RECT(l, t, r, b));
	}
	
	
	/// ditto
	void opOpAssign(string op)(RECT rc) if (op == "~")
	{
		add(rc);
	}
	
	
	///
	@property Region region()
	{
		if (_rgn is null) return null;
		with (_rgn.rdh)
		{
			dwSize = RGNDATAHEADER.sizeof;
			iType  = RDH_RECTANGLES;
			nRgnSize = RGNDATAHEADER.sizeof.toI32 + RECT.sizeof.toI32*nCount.toI32;
			rcBound = RECT(0,0,_width.toI32,_height.toI32);
		}
		if (auto hRgn = ExtCreateRegion(null, _rgn.rdh.nRgnSize, _rgn))
		{
			return new Region(hRgn);
		}
		throw new Exception("Failed to make a region data.");
	}
	
	
	private Region createClippingRegionFromHDC(HBITMAP hBitmap)
	{
		HDC hDC = CreateCompatibleDC(null);
		auto h = _height;
		auto w = _width;
		if (!hDC) throw new Exception("Failed to get device context data.");
		BITMAPINFOHEADER bi;
		with(bi)
		{
			biSize        = BITMAPINFOHEADER.sizeof;
			biWidth       = w.toI32;
			biHeight      = h.toI32;
			biPlanes      = 1;
			biBitCount    = 32;
			biCompression = BI_RGB;
		}
		auto pxs = new COLORREF[w];
		COLORREF tr;
		for (int y = 1; y < h; ++y)
		{
			GetDIBits(hDC, hBitmap, h.toI32-y, 1, pxs.ptr, cast(BITMAPINFO*)&bi, DIB_RGB_COLORS);
			if (y == 1) tr = pxs[0];
			for (int x = 0; x < w; x++)
			{
				if (pxs[x] == tr) continue;
				int sx = x;
				while (x < w)
				{
					if (pxs[x++] == tr) break;
				}
				add(sx, y-1, x-1, y);
			}
		}
		DeleteDC(hDC);
		return region;
	}
	
	
	///
	Region create(MemoryGraphics g)
	{
		clear();
		_width = g.width;
		_height = g.height;
		return createClippingRegionFromHDC(g.hbitmap);
	}
	
	
	/// ditto
	Region create(Image img)
	{
		clear();
		_width = img.width;
		_height = img.height;
		if (auto bmp = cast(Bitmap)img)
		{
			return createClippingRegionFromHDC(bmp.handle);
		}
		auto g = new MemoryGraphics(img.width, img.height);
		img.draw(g, Point(0,0));
		return create(g);
	}
}


///
class ClippingForm : Form
{
private:
	Image _image;
	RegionRects _regionRects;

protected:
	override void createParams(ref CreateParams cp)
	{
		super.createParams(cp);
		cp.style = WS_POPUP;
		cp.exStyle |= WS_EX_TOPMOST;
	}

public:
	///
	@property Image clipping()
	{
		return _image;
	}
	
	
	/// ditto
	@property void clipping(Image img)
	{
		_image = img;
	}
	
	
	///
	override void onHandleCreated(EventArgs ea)
	{
		if (_image)
		{
			region = _regionRects.create(_image);
		}
		super.onHandleCreated(ea);
	}
	
	
	///
	override void onPaint(PaintEventArgs pea)
	{
		if (_image)
		{
			_image.draw(pea.graphics, Point(0,0));
		}
		else
		{
			super.onPaint(pea);
		}
	}
}
