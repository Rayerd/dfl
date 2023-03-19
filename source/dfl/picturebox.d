// Written by Christopher E. Miller
// See the included license.txt for copyright and license details.


///
module dfl.picturebox;

private import dfl.control;
private import dfl.base;
private import dfl.drawing;
private import dfl.event;

private import core.sys.windows.windows;


///
enum PictureBoxSizeMode: ubyte
{
	///
	NORMAL, // Image at upper left of control.
	/// ditto
	AUTO_SIZE, // Control sizes to fit image size.
	/// ditto
	CENTER_IMAGE, // Image at center of control.
	/// ditto
	STRETCH_IMAGE, // Image stretched to fit control.
	/// ditto
	ZOOM, // Image sizes to fit control at center of control.
}


///
class PictureBox: Control // docmain
{
public:
	this()
	{
		//resizeRedraw = true; // Redrawn manually in onResize() when necessary.
	}
	
	
	///
	final @property void image(Image img) // setter
	{
		if (this._img is img)
			return;
		
		if (_mode == PictureBoxSizeMode.AUTO_SIZE)
		{
			if (img)
				clientSize = img.size;
			else
				clientSize = Size(0, 0);
		}
		
		this._img = img;
		
		if (created)
			invalidate();
		
		onImageChanged(EventArgs.empty);
	}
	
	/// ditto
	final @property Image image() // getter
	{
		return _img;
	}
	
	
	///
	final @property void sizeMode(PictureBoxSizeMode sm) // setter
	{
		if (_mode == sm)
			return;
		
		final switch(sm)
		{
			case PictureBoxSizeMode.AUTO_SIZE:
				if (_img)
					clientSize = _img.size;
				else
					clientSize = Size(0, 0);
				break;
			
			case PictureBoxSizeMode.NORMAL:
				break;
			
			case PictureBoxSizeMode.CENTER_IMAGE:
				break;
			
			case PictureBoxSizeMode.STRETCH_IMAGE:
				break;

			case PictureBoxSizeMode.ZOOM:
				break;
		}
		
		_mode = sm;
		
		if (created)
			invalidate();
		
		onSizeModeChanged(EventArgs.empty);
	}
	
	/// ditto
	final @property PictureBoxSizeMode sizeMode() // getter
	{
		return _mode;
	}
	
	
	///
	@property void borderStyle(BorderStyle bs) // setter
	{
		final switch (bs)
		{
			case BorderStyle.FIXED_3D:
				_style(_style() & ~WS_BORDER);
				_exStyle(_exStyle() | WS_EX_CLIENTEDGE);
				break;
				
			case BorderStyle.FIXED_SINGLE:
				_exStyle(_exStyle() & ~WS_EX_CLIENTEDGE);
				_style(_style() | WS_BORDER);
				break;
				
			case BorderStyle.NONE:
				_style(_style() & ~WS_BORDER);
				_exStyle(_exStyle() & ~WS_EX_CLIENTEDGE);
				break;
		}
		
		if (created)
		{
			redrawEntire();
		}
	}
	
	/// ditto
	@property BorderStyle borderStyle() // getter
	{
		if(_exStyle() & WS_EX_CLIENTEDGE)
			return BorderStyle.FIXED_3D;
		else if(_style() & WS_BORDER)
			return BorderStyle.FIXED_SINGLE;
		return BorderStyle.NONE;
	}
	
	
	//EventHandler sizeModeChanged;
	Event!(PictureBox, EventArgs) sizeModeChanged; ///
	//EventHandler imageChanged;
	Event!(PictureBox, EventArgs) imageChanged; ///
	
	
protected:
	///
	void onSizeModeChanged(EventArgs ea)
	{
		sizeModeChanged(this, ea);
	}
	
	
	///
	void onImageChanged(EventArgs ea)
	{
		imageChanged(this, ea);
	}
	
	
	///
	override void onPaint(PaintEventArgs ea)
	{
		if (_img)
		{
			final switch (_mode)
			{
			case PictureBoxSizeMode.NORMAL:
			case PictureBoxSizeMode.AUTO_SIZE: // Drawn the same as normal.
				_img.draw(ea.graphics, Point(0, 0));
				break;
			
			case PictureBoxSizeMode.CENTER_IMAGE:
				Size imageSize = _img.size;
				_img.draw(ea.graphics, Point((clientSize.width  - imageSize.width) / 2,
					(clientSize.height - imageSize.height) / 2));
				break;
			
			case PictureBoxSizeMode.STRETCH_IMAGE:
				_img.drawStretched(ea.graphics, Rect(0, 0, clientSize.width, clientSize.height));
				break;
			
			case PictureBoxSizeMode.ZOOM:
				Size imageSize = _img.size;
				Point center = Point(clientSize.width / 2, clientSize.height / 2);
				double ratio = {
					if (clientSize.width > clientSize.height)
						return cast(double)clientSize.height / imageSize.height;
					else
						return cast(double)clientSize.width / imageSize.width;
				}();
				Rect rect;
				rect.width = cast(int)(imageSize.width * ratio);
				rect.height = cast(int)(imageSize.height * ratio);
				rect.x = center.x - rect.width / 2;
				rect.y = center.y - rect.height / 2;
				_img.drawStretched(ea.graphics, rect);
				break;
			}
		}
		
		super.onPaint(ea);
	}
	
	
	///
	override void onResize(EventArgs ea)
	{
		if (PictureBoxSizeMode.CENTER_IMAGE == _mode || PictureBoxSizeMode.STRETCH_IMAGE == _mode)
			invalidate();
		
		super.onResize(ea);
	}
	
	
private:
	PictureBoxSizeMode _mode = PictureBoxSizeMode.NORMAL;
	Image _img = null;
}

