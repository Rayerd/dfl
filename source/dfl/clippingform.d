module dfl.clippingform;

import dfl.base;
import dfl.form;
import dfl.control;
import dfl.event;
import dfl.drawing;

import dfl.internal.dlib : toI32;
import dfl.internal.dpiaware;

import core.memory;
import core.sys.windows.winbase;
import core.sys.windows.wingdi;
import core.sys.windows.windef;
import core.sys.windows.winuser;

///
struct RegionRects
{
	///
	@property size_t width() const pure nothrow
	{
		return _width;
	}
	
	
	///
	@property size_t height() const pure nothrow
	{
		return _height;
	}
	
	
	///
	void clear()
	{
		if (_rgn)
			GC.free(_rgn);
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
			_rgn = cast(RGNDATA*)GC.malloc(RGNDATAHEADER.sizeof + RECT.sizeof * _capacity);
			_rgn.rdh.nCount = 0;
		}
		else if (_rgn.rdh.nCount == _capacity)
		{
			_capacity *= 2;
			_rgn = cast(RGNDATA*)GC.realloc(cast(void*)_rgn, RGNDATAHEADER.sizeof + RECT.sizeof * _capacity);
		}
		(cast(RECT*)_rgn.Buffer.ptr)[_rgn.rdh.nCount++] = rc;
	}
	
	/// ditto
	void add(int l, int t, int r, int b)
	{
		add(RECT(l, t, r, b));
	}
	
	/// ditto
	void opOpAssign(string op : "~")(RECT rc)
	{
		add(rc);
	}
	
	
	///
	@property Region region()
	{
		if (_rgn is null)
			return null;
		with (_rgn.rdh)
		{
			dwSize = RGNDATAHEADER.sizeof;
			iType = RDH_RECTANGLES;
			nRgnSize = RGNDATAHEADER.sizeof.toI32 + RECT.sizeof.toI32 * nCount.toI32;
			rcBound = RECT(0, 0, _width.toI32, _height.toI32);
		}
		if (auto hRgn = ExtCreateRegion(null, _rgn.rdh.nRgnSize, _rgn))
			return new Region(hRgn);
		throw new Exception("Failed to make a region data.");
	}


	///
	Region create(MemoryGraphics mg, int dpi = USER_DEFAULT_SCREEN_DPI)
	{
		clear();
		_width = MulDiv(mg.width, dpi, USER_DEFAULT_SCREEN_DPI);
		_height = MulDiv(mg.height, dpi, USER_DEFAULT_SCREEN_DPI);
		auto g = new MemoryGraphics(_width.toI32, _height.toI32, mg.handle);
		Bitmap bmp = new Bitmap(mg.toHBitmap(mg.handle));
		bmp.drawStretched(g, Rect(0, 0, _width, _height));
		return _createClippingRegionFromHDC(g.hbitmap);
	}
	
	/// ditto
	Region create(Image img, int dpi = USER_DEFAULT_SCREEN_DPI)
	{
		clear();
		_width = MulDiv(img.width, dpi, USER_DEFAULT_SCREEN_DPI);
		_height = MulDiv(img.height, dpi, USER_DEFAULT_SCREEN_DPI);
		auto g = new MemoryGraphics(_width.toI32, _height.toI32);
		img.drawStretched(g, Rect(0, 0, _width, _height));
		return _createClippingRegionFromHDC(g.hbitmap);
	}

private:
	RGNDATA* _rgn = null; ///
	size_t _capacity = 0; ///
	size_t _width = 0; ///
	size_t _height = 0; ///

	///
	Region _createClippingRegionFromHDC(HBITMAP hBitmap)
	{
		HDC hDC = CreateCompatibleDC(null);
		if (!hDC)
			throw new Exception("Failed to get device context data.");
		BITMAPINFOHEADER bi;
		with(bi)
		{
			biSize        = BITMAPINFOHEADER.sizeof;
			biWidth       = _width.toI32;
			biHeight      = _height.toI32;
			biPlanes      = 1;
			biBitCount    = 32;
			biCompression = BI_RGB;
		}
		auto pixels = new COLORREF[_width];
		COLORREF transparentColor;
		for (int y = 1; y < _height; ++y)
		{
			GetDIBits(hDC, hBitmap, _height.toI32 - y, 1, pixels.ptr, cast(BITMAPINFO*)&bi, DIB_RGB_COLORS);
			if (y == 1)
				transparentColor = pixels[0];
			for (int x = 0; x < _width; x++)
			{
				if (pixels[x] == transparentColor) continue;
				int sx = x;
				while (x < _width)
				{
					if (pixels[x++] == transparentColor) break;
				}
				int l = sx;
				int t = y-1;
				int r = x-1;
				int b = y;
				add(l, t, r, b); // L,T,R,B
			}
		}
		DeleteDC(hDC);
		return region;
	}
}


///
class ClippingForm : Form
{
	///
	@property inout(Image) clipping() inout // getter
	{
		return _image;
	}
	
	/// ditto
	@property void clipping(Image img) // setter
	{
		_image = img;
	}
	
	
protected:

	///
	override void onHandleCreated(EventArgs ea)
	{
		super.onHandleCreated(ea);

		_updateRegionWithDpi(dpi);
	}
	
	
	///
	override void onPaint(PaintEventArgs pea)
	{
		super.onPaint(pea);
		if (_image)
		{
			// TODO: If the dpi is not an integer ratio (100%, 200%, 300%...),
			//       the window size and image size will be misaligned.
			Rect rect;
			rect.x = 0;
			rect.y = 0;
			rect.width = MulDiv(width, dpi, USER_DEFAULT_SCREEN_DPI);
			rect.height = MulDiv(height, dpi, USER_DEFAULT_SCREEN_DPI);
			_image.drawStretched(pea.graphics, rect);
		}
	}


	///
	override void wndProc(ref Message msg)
	{
		switch(msg.msg)
		{
			case WM_DPICHANGED:
			{
				super.wndProc(msg); // Call it before, because window size must be changed.

				_updateRegionWithDpi(dpi);

				invalidate();
				return; // Exit function without call super.wndProc().
			}

			default:
		}
		super.wndProc(msg);
	}


	///
	override void createParams(ref CreateParams cp)
	{
		super.createParams(cp);
		cp.style = WS_POPUP;
	}


private:

	Image _image; ///
	RegionRects _regionRects; ///


	///
	void _updateRegionWithDpi(uint dpi_)
	{
		if (_image)
		{
			this.region = _regionRects.create(_image, dpi_);
		}
	}
}
