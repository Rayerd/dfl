// Written by Christopher E. Miller
// See the included license.txt for copyright and license details.


///
module dfl.imagelist;

import dfl.base;
import dfl.collections;
import dfl.drawing;

import dfl.internal.dlib;

import core.sys.windows.winbase;
import core.sys.windows.windef;
import core.sys.windows.commctrl;
import core.sys.windows.wingdi;


///
class ImageList // docmain
{
	///
	class ImageCollection
	{
		protected this()
		{
		}
		
		
		void insert(int index, Image img)
		{
			if (index >= _images.length.toI32)
			{
				add(img);
			}
			else
			{
				assert(0, "Must add images to the end of the image list");
			}
		}
		
		
		final void addStrip(Image img)
		{
			HGDIOBJ hgo;
			if (1 != img._imgtype(&hgo))
			{
				debug
				{
					assert(0, "Image list: addStrip needs bitmap");
				}
				else
				{
					_unableimg();
				}
			}
			
			auto sz = imageSize;
			if (img.height != sz.height
				|| img.width % sz.width)
			{
				debug
				{
					assert(0, "Image list: invalid image size");
				}
				else
				{
					_unableimg();
				}
			}
			int num = img.width / sz.width;
			
			/+
			if (1 == num)
			{
				add(img);
				return;
			}
			+/
			
			auto _hdl = handle; // _addhbitmap needs the handle! Could avoid this in the future.
			_addhbitmap(hgo);
			
			int x = 0;
			for (; num; num--)
			{
				auto sp = new StripPart();
				sp.origImg = img;
				sp.hbm = hgo;
				sp.partBounds = Rect(x, 0, sz.width, sz.height);
				
				_images ~= sp;
				
				x += sz.width;
			}
		}
		
		
	package:
		
		Image[] _images;
		
		
		static class StripPart: Image
		{
			override @property Size size() // getter
			{
				return partBounds.size;
			}
			
			
			override void draw(Graphics g, Point pt)
			{
				HDC memdc = CreateCompatibleDC(g.handle);
				try
				{
					HGDIOBJ hgo = SelectObject(memdc, hbm);
					BitBlt(g.handle, pt.x, pt.y, partBounds.width, partBounds.height, memdc, partBounds.x, partBounds.y, SRCCOPY);
					SelectObject(memdc, hgo); // Old bitmap.
				}
				finally
				{
					DeleteDC(memdc);
				}
			}
			
			
			override void drawStretched(Graphics g, Rect r)
			{
				HDC memdc = CreateCompatibleDC(g.handle);
				try
				{
					HGDIOBJ hgo = SelectObject(memdc, hbm);
					int lstretch = SetStretchBltMode(g.handle, COLORONCOLOR);
					StretchBlt(g.handle, r.x, r.y, r.width, r.height,
						memdc, partBounds.x, partBounds.y, partBounds.width, partBounds.height, SRCCOPY);
					SetStretchBltMode(g.handle, lstretch);
					SelectObject(memdc, hgo); // Old bitmap.
				}
				finally
				{
					DeleteDC(memdc);
				}
			}
			
			
			Image origImg; // Hold this so the HBITMAP doesn't get collected.
			HBITMAP hbm;
			Rect partBounds;
		}
		
		
		void _adding(size_t idx, Image val)
		{
			assert(val !is null);
			
			switch (val._imgtype(null))
			{
				case 1:
				case 2:
					break;
				default:
					debug
					{
						assert(0, "Image list: invalid image type");
					}
					else
					{
						_unableimg();
					}
			}
			
			if (val.size != imageSize)
			{
				debug
				{
					assert(0, "Image list: invalid image size");
				}
				else
				{
					_unableimg();
				}
			}
		}
		
		
		void _added(size_t idx, Image val)
		{
			if (isHandleCreated)
			{
				//if (idx >= _images.length) // Can't test for this here because -val- is already added to the array.
				_addimg(val);
			}
		}
		
		
		void _removed(size_t idx, Image val)
		{
			if (isHandleCreated)
			{
				if (size_t.max == idx) // Clear all.
				{
					imageListRemove(handle, -1);
				}
				else
				{
					imageListRemove(handle, idx.toI32);
				}
			}
		}
		
		
	public:
		
		mixin ListWrapArray!(Image, _images,
			_adding, _added,
			_blankListCallback!(Image), _removed,
			false, false, false);
	}
	
	
	this()
	{
		InitCommonControls();
		
		_imageCollections = new ImageCollection();
		_transparentColor = Color.transparent;
	}
	
	
	///
	final @property void colorDepth(ColorDepth depth) // setter
	{
		assert(!isHandleCreated);
		
		this._colorDepth = depth;
	}
	
	/// ditto
	final @property ColorDepth colorDepth() const // getter
	{
		return _colorDepth;
	}
	
	
	///
	final @property void transparentColor(Color tc) // setter
	{
		assert(!isHandleCreated);
		
		_transparentColor = tc;
	}
	
	/// ditto
	final @property Color transparentColor() const // getter
	{
		return _transparentColor;
	}
	
	
	///
	final @property void imageSize(Size sz) // setter
	{
		assert(!isHandleCreated);
		
		assert(sz.width && sz.height);
		
		_width = sz.width;
		_height = sz.height;
	}
	
	/// ditto
	final @property Size imageSize() const // getter
	{
		return Size(_width, _height);
	}
	
	
	///
	final @property inout(ImageCollection) images() inout // getter
	{
		return _imageCollections;
	}
	
	
	///
	final @property void tag(Object t) // setter
	{
		this._tag = t;
	}
	
	/// ditto
	final @property inout(Object) tag() inout // getter
	{
		return this._tag;
	}
	
	
	/+ // Actually, forget about these; just draw with the actual images.
	///
	final void draw(Graphics g, Point pt, int index)
	{
		return draw(g, pt.x, pt.y, index);
	}
	
	/// ditto
	final void draw(Graphics g, int x, int y, int index)
	{
		imageListDraw(handle, index, g.handle, x, y, ILD_NORMAL);
	}
	
	/// ditto
	// stretch
	final void draw(Graphics g, int x, int y, int width, int height, int index)
	{
		// ImageList_DrawEx operates differently if the width or height is zero
		// so bail out if zero and pretend the zero size image was drawn.
		if (!width)
			return;
		if (!height)
			return;
		
		imageListDrawEx(handle, index, g.handle, x, y, width, height,
			CLR_NONE, CLR_NONE, ILD_NORMAL); // ?
	}
	+/
	
	
	///
	final @property bool isHandleCreated() // getter
	{
		return HIMAGELIST.init != _hImageList;
	}
	
	
	///
	final @property HIMAGELIST handle() // getter
	{
		if (!isHandleCreated)
			_createImageList();
		return _hImageList;
	}
	
	
	///
	void dispose()
	{
		return dispose(true);
	}
	
	/// ditto
	void dispose(bool disposing)
	{
		if (isHandleCreated)
			imageListDestroy(_hImageList);
		_hImageList = HIMAGELIST.init;
		
		if (disposing)
		{
			//_cimages._images = null; // Not GC-safe in dtor.
			//_cimages = null; // Could cause bad things.
		}
	}
	
	
	~this()
	{
		dispose();
	}
	
	
private:
	
	ColorDepth _colorDepth = ColorDepth.DEPTH_8BIT;
	Color _transparentColor;
	ImageCollection _imageCollections;
	HIMAGELIST _hImageList;
	int _width = 16;
	int _height = 16;
	Object _tag;
	
	
	void _createImageList()
	{
		if (isHandleCreated)
		{
			imageListDestroy(_hImageList);
			_hImageList = HIMAGELIST.init;
		}
		
		UINT flags = ILC_MASK;
		switch (_colorDepth)
		{
			case ColorDepth.DEPTH_4BIT:          flags |= ILC_COLOR4;  break;
			default: case ColorDepth.DEPTH_8BIT: flags |= ILC_COLOR8;  break;
			case ColorDepth.DEPTH_16BIT:         flags |= ILC_COLOR16; break;
			case ColorDepth.DEPTH_24BIT:         flags |= ILC_COLOR24; break;
			case ColorDepth.DEPTH_32BIT:         flags |= ILC_COLOR32; break;
		}
		
		// NOTE: cGrow is not a limit, but how many images to preallocate each grow.
		_hImageList = imageListCreate(_width, _height, flags, _imageCollections._images.length.toI32, 4 + _imageCollections._images.length.toI32 / 4);
		if (!_hImageList)
			throw new DflException("Unable to create image list");
		
		foreach (img; _imageCollections._images)
		{
			_addimg(img);
		}
	}
	
	
	void _unableimg()
	{
		throw new DflException("Unable to add image to image list");
	}
	
	
	int _addimg(Image img)
	{
		assert(isHandleCreated);
		
		HGDIOBJ hgo;
		int result;
		switch (img._imgtype(&hgo))
		{
			case 1:
				result = _addhbitmap(hgo);
				break;
			
			case 2:
				result = imageListAddIcon(_hImageList, cast(HICON)hgo);
				break;
			
			default:
				result = -1;
		}
		
		//if (-1 == result)
		//	_unableimg();
		return result;
	}
	
	int _addhbitmap(HBITMAP hbm)
	{
		assert(isHandleCreated);
		
		COLORREF cr;
		if (_transparentColor == Color.empty
			|| _transparentColor == Color.transparent)
		{
			cr = CLR_DEFAULT;
		}
		else
		{
			cr = _transparentColor.toRgb();
		}
		return imageListAddMasked(_hImageList, cast(HBITMAP)hbm, cr);
	}
}


private extern(Windows)
{
	// This was the only way I could figure out how to use the current actctx (Windows issue).
	
	HIMAGELIST imageListCreate(int cx, int cy, UINT flags, int cInitial, int cGrow)
	{
		alias TProc = typeof(&ImageList_Create);
		static TProc proc = null;
		if (!proc)
			proc = cast(typeof(proc))GetProcAddress(GetModuleHandleA("comctl32.dll"), "ImageList_Create");
		return proc(cx, cy, flags, cInitial, cGrow);
	}
	
	int imageListAddIcon(HIMAGELIST himl, HICON hicon)
	{
		alias TProc = typeof(&ImageList_AddIcon);
		static TProc proc = null;
		if (!proc)
			proc = cast(typeof(proc))GetProcAddress(GetModuleHandleA("comctl32.dll"), "ImageList_AddIcon");
		return proc(himl, hicon);
	}
	
	int imageListAddMasked(HIMAGELIST himl, HBITMAP hbmImage, COLORREF crMask)
	{
		alias TProc = typeof(&ImageList_AddMasked);
		static TProc proc = null;
		if (!proc)
			proc = cast(typeof(proc))GetProcAddress(GetModuleHandleA("comctl32.dll"), "ImageList_AddMasked");
		return proc(himl, hbmImage, crMask);
	}
	
	BOOL imageListRemove(HIMAGELIST himl, int i)
	{
		alias TProc = typeof(&ImageList_Remove);
		static TProc proc = null;
		if (!proc)
			proc = cast(typeof(proc))GetProcAddress(GetModuleHandleA("comctl32.dll"), "ImageList_Remove");
		return proc(himl, i);
	}
	
	BOOL imageListDestroy(HIMAGELIST himl)
	{
		alias TProc = typeof(&ImageList_Destroy);
		static TProc proc = null;
		if (!proc)
			proc = cast(typeof(proc))GetProcAddress(GetModuleHandleA("comctl32.dll"), "ImageList_Destroy");
		return proc(himl);
	}
}
