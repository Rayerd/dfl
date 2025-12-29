// Written by Christopher E. Miller
// See the included license.txt for copyright and license details.


///
module dfl.picturebox;

import dfl.base;
import dfl.control;
import dfl.drawing;
import dfl.event;

import dfl.internal.dpiaware;

import core.sys.windows.winuser;


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
		if (this._image is img)
			return;
		
		if (_sizeMode == PictureBoxSizeMode.AUTO_SIZE)
		{
			if (img)
				clientSize = img.size;
			else
				clientSize = Size(0, 0);
		}
		
		this._image = img;
		
		if (created)
			invalidate();
		
		onImageChanged(EventArgs.empty);
	}
	
	/// ditto
	final @property Image image() // getter
	{
		return _image;
	}
	
	
	///
	final @property void sizeMode(PictureBoxSizeMode sm) // setter
	{
		if (_sizeMode == sm)
			return;
		
		final switch(sm)
		{
			case PictureBoxSizeMode.AUTO_SIZE:
				if (_image)
					clientSize = _image.size;
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
		
		_sizeMode = sm;
		
		if (created)
			invalidate();
		
		onSizeModeChanged(EventArgs.empty);
	}
	
	/// ditto
	final @property PictureBoxSizeMode sizeMode() // getter
	{
		return _sizeMode;
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
	
	
	Event!(PictureBox, EventArgs) sizeModeChanged; ///
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
		if (_image)
		{
			final switch (_sizeMode)
			{
			case PictureBoxSizeMode.NORMAL:
			case PictureBoxSizeMode.AUTO_SIZE: // Drawn the same as normal.
				_image.drawStretched(ea.graphics, Rect(0, 0, _image.width, _image.height) * dpi / USER_DEFAULT_SCREEN_DPI);
				break;
			
			case PictureBoxSizeMode.CENTER_IMAGE:
				Rect r = Rect(
					(clientSize.width - _image.size.width) / 2,
					(clientSize.height - _image.size.height) / 2,
					_image.size.width,
					_image.size.height
				);
				_image.drawStretched(ea.graphics, r * dpi / USER_DEFAULT_SCREEN_DPI);
				break;
			
			case PictureBoxSizeMode.STRETCH_IMAGE:
				_image.drawStretched(ea.graphics, Rect(0, 0, clientSize.width, clientSize.height) * dpi / USER_DEFAULT_SCREEN_DPI);
				break;
			
			case PictureBoxSizeMode.ZOOM:
				Size imageSize = _image.size;
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
				_image.drawStretched(ea.graphics, rect * dpi / USER_DEFAULT_SCREEN_DPI);
				break;
			}
		}
		
		super.onPaint(ea);
	}
	
	
	///
	override void onResize(EventArgs ea)
	{
		if (PictureBoxSizeMode.CENTER_IMAGE == _sizeMode || PictureBoxSizeMode.STRETCH_IMAGE == _sizeMode)
			invalidate();
		
		super.onResize(ea);
	}
	
	
private:
	PictureBoxSizeMode _sizeMode = PictureBoxSizeMode.NORMAL;
	Image _image = null;
}

