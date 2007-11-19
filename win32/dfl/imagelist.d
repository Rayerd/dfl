// Written by Christopher E. Miller
// See the included license.txt for copyright and license details.


///
module dfl.imagelist;

import dfl.base, dfl.drawing, dfl.internal.winapi;


///
class ImageList // docmain
{
	class ImageCollection
	{
		protected this()
		{
		}
		
		
		package Image[] _images;
	}
	
	
	this()
	{
		_cimages = new ImageCollection();
		_transcolor = Color.transparent;
	}
	
	
	///
	final void colorDepth(ColorDepth depth) // setter
	{
		assert(!isHandleCreated);
		
		this._depth = depth;
	}
	
	/// ditto
	final ColorDepth colorDepth() // getter
	{
		return _depth;
	}
	
	
	///
	final void transparentColor(Color tc) // setter
	{
		assert(!isHandleCreated);
		
		_transcolor = tc;
	}
	
	/// ditto
	final Color transparentColor() // getter
	{
		return _transcolor;
	}
	
	
	///
	final void imageSize(Size sz) // setter
	{
		assert(!isHandleCreated);
		
		_w = sz.width;
		_h = sz.height;
	}
	
	/// ditto
	final Size imageSize() // getter
	{
		return Size(_w, _h);
	}
	
	
	///
	final ImageCollection images() // getter
	{
		return _cimages;
	}
	
	
	///
	final void tag(Object t) // setter
	{
		this._tag = t;
	}
	
	/// ditto
	final Object tag() // getter
	{
		return this._tag;
	}
	
	
	///
	final void draw(Graphics g, Point pt, int index)
	{
		return draw(g, pt.x, pt.y, index);
	}
	
	/// ditto
	final void draw(Graphics g, int x, int y, int index)
	{
		ImageList_Draw(handle, index, g.handle, x, y, ILD_NORMAL);
	}
	
	/+
	/// ditto
	// stretch
	final void draw(Graphics g, int x, int y, int width, int height, int index)
	{
	}
	+/
	
	
	///
	final bool isHandleCreated() // getter
	{
		return HIMAGELIST.init != _hil;
	}
	
	deprecated alias isHandleCreated handleCreated;
	
	
	final HIMAGELIST handle() // getter
	{
		if(!isHandleCreated)
			_createimagelist();
		return _hil;
	}
	
	
	~this()
	{
		if(isHandleCreated)
			ImageList_Destroy(_hil);
	}
	
	
	private:
	
	ColorDepth _depth = ColorDepth.DEPTH_8BIT;
	Color _transcolor;
	ImageCollection _cimages;
	HIMAGELIST _hil;
	int _w = 16, _h = 16;
	Object _tag;
	
	
	void _createimagelist()
	{
		if(isHandleCreated)
		{
			ImageList_Destroy(_hil);
			_hil = HIMAGELIST.init;
		}
		
		UINT flags = 0;
		/+
		switch(_depth)
		{
			case ColorDepth.DEPTH_4BIT: flags = ILC_COLOR4; break;
			default: case DEPTH_8BIT: flags = ILC_COLOR8; break;
			case ColorDepth.DEPTH_16BIT: flags = ILC_COLOR16; break;
			case ColorDepth.DEPTH_24BIT: flags = ILC_COLOR24; break;
			case ColorDepth.DEPTH_32BIT: flags = ILC_COLOR32; break;
		}
		+/
		flags |= _depth;
		flags |= ILC_MASK; // ?
		
		_hil = ImageList_Create(_w, _h, flags, _cimages._images.length, 65535); // ?
	}
}

