module dfl.clippingform;

private import dfl.all, dfl.internal.winapi;
private import core.memory;

private extern (Windows)
{
	struct RGNDATAHEADER
	{
		DWORD dwSize;
		DWORD iType;
		DWORD nCount;
		DWORD nRgnSize;
		RECT rcBound;
	}
	
	struct RGNDATA
	{
		RGNDATAHEADER rdh;
		ubyte[1] Buffer;
	}
	
	struct XFORM
	{
		FLOAT eM11;
		FLOAT eM12;
		FLOAT eM21;
		FLOAT eM22;
		FLOAT eDx;
		FLOAT eDy;
	}
	
	enum {RDH_RECTANGLES = 1}
	enum {BI_RGB = 0}
	enum {DIB_RGB_COLORS = 0}
	
	HRGN ExtCreateRegion(void*, DWORD, RGNDATA*);
	int GetDIBits(HDC, HBITMAP, UINT, UINT, PVOID, LPBITMAPINFO, UINT);
}


///
struct RegionRects
{
private:
	RGNDATA* _rgn = null;
	size_t _capacity = 0;
	size_t _width = 0;
	size_t _height = 0;
public:
	
	
	const @property
	size_t width()
	{
		return _width;
	}
	
	
	///
	const @property
	size_t height()
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
	void opCatAssign(RECT rc)
	{
		add(rc);
	}
	
	
	///
	@property
	Region region()
	{
		if (_rgn is null) return null;
		with (_rgn.rdh)
		{
			dwSize = RGNDATAHEADER.sizeof;
			iType  = RDH_RECTANGLES;
			nRgnSize = RGNDATAHEADER.sizeof + RECT.sizeof*nCount;
			rcBound = RECT(0,0,_width,_height);
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
			biWidth       = w;
			biHeight      = h;
			biPlanes      = 1;
			biBitCount    = 32;
			biCompression = BI_RGB;
		}
		auto pxs = new COLORREF[w];
		COLORREF tr;
		for (int y = 1; y < h; ++y)
		{
			GetDIBits(hDC, hBitmap, h-y, 1, pxs.ptr, cast(BITMAPINFO*)&bi, DIB_RGB_COLORS);
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
		return region;
	}
	
	
	///
	Region create(MemoryGraphics g)
	{
		clear();
		_width = g.width;
		_height = g.height;
		return createClippingRegionFromHDC(cast(HBITMAP)g.hbitmap);
	}
	
	
	/// ditto
	Region create(Image img)
	{
		clear();
		_width = img.width;
		_height = img.height;
		if (auto bmp = cast(Bitmap)img)
		{
			return createClippingRegionFromHDC(cast(HBITMAP)bmp.handle);
		}
		auto g = new MemoryGraphics(img.width, img.height);
		img.draw(g, Point(0,0));
		return create(g);
	}
}


///
class ClippingForm: Form
{
private:
	Image m_Image;
	RegionRects m_RegionRects;
protected:
	override void createParams(ref CreateParams cp)
	{
		super.createParams(cp);
		cp.style = WS_EX_TOPMOST | WS_EX_TOOLWINDOW;
	}
public:
	
	
	///
	@property Image clipping()
	{
		return m_Image;
	}
	
	
	/// ditto
	@property void clipping(Image img)
	{
		m_Image = img;
	}
	
	
	///
	override void onHandleCreated(EventArgs ea)
	{
		if (m_Image)
		{
			region = m_RegionRects.create(m_Image);
		}
		super.onHandleCreated(ea);
	}
	
	
	///
	override void onPaint(PaintEventArgs pea)
	{
		if (m_Image)
		{
			m_Image.draw(pea.graphics, Point(0,0));
		}
		else
		{
			super.onPaint(pea);
		}
	}
}
