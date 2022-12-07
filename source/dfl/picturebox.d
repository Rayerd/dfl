// Written by Christopher E. Miller
// See the included license.txt for copyright and license details.


///
module dfl.picturebox;

private import dfl.control, dfl.base, dfl.drawing, dfl.event;
private import dfl.internal.winapi;


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
}


///
class PictureBox: Control // docmain
{
	this()
	{
		//resizeRedraw = true; // Redrawn manually in onResize() when necessary.
	}
	
	
	///
	final @property void image(Image img) // setter
	{
		if(this.img is img)
			return;
		
		if(_mode == PictureBoxSizeMode.AUTO_SIZE)
		{
			if(img)
				clientSize = img.size;
			else
				clientSize = Size(0, 0);
		}
		
		this.img = img;
		
		if(created)
			invalidate();
		
		onImageChanged(EventArgs.empty);
	}
	
	/// ditto
	final @property Image image() // getter
	{
		return img;
	}
	
	
	///
	final @property void sizeMode(PictureBoxSizeMode sm) // setter
	{
		if(_mode == sm)
			return;
		
		final switch(sm)
		{
			case PictureBoxSizeMode.AUTO_SIZE:
				if(img)
					clientSize = img.size;
				else
					clientSize = Size(0, 0);
				break;
			
			case PictureBoxSizeMode.NORMAL:
				break;
			
			case PictureBoxSizeMode.CENTER_IMAGE:
				break;
			
			case PictureBoxSizeMode.STRETCH_IMAGE:
				break;
		}
		
		_mode = sm;
		
		if(created)
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
		final switch(bs)
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
		
		if(created)
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
	
	
	override void onPaint(PaintEventArgs ea)
	{
		if(img)
		{
			final switch(_mode)
			{
				case PictureBoxSizeMode.NORMAL:
				case PictureBoxSizeMode.AUTO_SIZE: // Drawn the same as normal.
					img.draw(ea.graphics, Point(0, 0));
					break;
				
				case PictureBoxSizeMode.CENTER_IMAGE:
					{
						Size isz;
						isz = img.size;
						img.draw(ea.graphics, Point((clientSize.width  - isz.width) / 2,
							(clientSize.height - isz.height) / 2));
					}
					break;
				
				case PictureBoxSizeMode.STRETCH_IMAGE:
					img.drawStretched(ea.graphics, Rect(0, 0, clientSize.width, clientSize.height));
					break;
			}
		}
		
		super.onPaint(ea);
	}
	
	
	override void onResize(EventArgs ea)
	{
		if(PictureBoxSizeMode.CENTER_IMAGE == _mode || PictureBoxSizeMode.STRETCH_IMAGE == _mode)
			invalidate();
		
		super.onResize(ea);
	}
	
	
	private:
	PictureBoxSizeMode _mode = PictureBoxSizeMode.NORMAL;
	Image img = null;
}

