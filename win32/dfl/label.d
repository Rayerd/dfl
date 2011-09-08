// Written by Christopher E. Miller
// See the included license.txt for copyright and license details.


///
module dfl.label;

private import dfl.base, dfl.control, dfl.internal.winapi, dfl.application,
	dfl.event, dfl.drawing, dfl.internal.dlib;


///
class Label: Control // docmain
{
	this()
	{
		resizeRedraw = true; // Word wrap and center correctly.
		
		tfmt = new TextFormat(TextFormatFlags.WORD_BREAK | TextFormatFlags.LINE_LIMIT);
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
		
		if(isHandleCreated)
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
	
	
	///
	final @property void useMnemonic(bool byes) // setter
	{
		if(byes)
		{
			tfmt.formatFlags = tfmt.formatFlags & ~TextFormatFlags.NO_PREFIX;
			_style(_style() & ~SS_NOPREFIX);
		}
		else
		{
			tfmt.formatFlags = tfmt.formatFlags | TextFormatFlags.NO_PREFIX;
			_style(_style() | SS_NOPREFIX);
		}
		
		if(isHandleCreated)
			invalidate();
	}
	
	/// ditto
	final @property bool useMnemonic() // getter
	{
		return (tfmt.formatFlags & TextFormatFlags.NO_PREFIX) == 0;
	}
	
	
	///
	@property Size preferredSize() // getter
	{
		Size result;
		Graphics g;
		g = isHandleCreated ? createGraphics() : Graphics.getScreen();
		result = g.measureText(text, font, tfmt);
		g.dispose();
		return result;
	}
	
	
	private void doAutoSize(Dstring text)
	{
		//if(isHandleCreated)
		{
			clientSize = preferredSize;
		}
	}
	
	
	override @property void text(Dstring newText) // setter
	{
		super.text = newText;
		
		if(autosz)
			doAutoSize(newText);
		
		invalidate(false);
	}
	
	alias Control.text text; // Overload.
	
	
	///
	@property void autoSize(bool byes) // setter
	{
		if(byes != autosz)
		{
			autosz = byes;
			
			if(byes)
			{
				doAutoSize(text);
			}
		}
	}
	
	/// ditto
	@property bool autoSize() // getter
	{
		return autosz;
	}
	
	
	///
	@property void textAlign(ContentAlignment calign) // setter
	{
		final switch(calign)
		{
			case ContentAlignment.TOP_LEFT:
				tfmt.alignment = TextAlignment.TOP | TextAlignment.LEFT;
				break;
			
			case ContentAlignment.BOTTOM_CENTER:
				tfmt.alignment = TextAlignment.BOTTOM | TextAlignment.CENTER;
				break;
			
			case ContentAlignment.BOTTOM_LEFT:
				tfmt.alignment = TextAlignment.BOTTOM | TextAlignment.LEFT;
				break;
			
			case ContentAlignment.BOTTOM_RIGHT:
				tfmt.alignment = TextAlignment.BOTTOM | TextAlignment.RIGHT;
				break;
			
			case ContentAlignment.MIDDLE_CENTER:
				tfmt.alignment = TextAlignment.MIDDLE | TextAlignment.CENTER;
				break;
			
			case ContentAlignment.MIDDLE_LEFT:
				tfmt.alignment = TextAlignment.MIDDLE | TextAlignment.LEFT;
				break;
			
			case ContentAlignment.MIDDLE_RIGHT:
				tfmt.alignment = TextAlignment.MIDDLE | TextAlignment.RIGHT;
				break;
			
			case ContentAlignment.TOP_CENTER:
				tfmt.alignment = TextAlignment.TOP | TextAlignment.CENTER;
				break;
			
			case ContentAlignment.TOP_RIGHT:
				tfmt.alignment = TextAlignment.TOP | TextAlignment.RIGHT;
				break;
		}
		
		invalidate(); // ?
	}
	
	/// ditto
	@property ContentAlignment textAlign() // getter
	{
		TextAlignment ta;
		ta = tfmt.alignment;
		
		if(ta & TextAlignment.BOTTOM)
		{
			if(ta & TextAlignment.RIGHT)
			{
				return ContentAlignment.BOTTOM_RIGHT;
			}
			else if(ta & TextAlignment.CENTER)
			{
				return ContentAlignment.BOTTOM_CENTER;
			}
			else // Left.
			{
				return ContentAlignment.BOTTOM_LEFT;
			}
		}
		else if(ta & TextAlignment.MIDDLE)
		{
			if(ta & TextAlignment.RIGHT)
			{
				return ContentAlignment.MIDDLE_RIGHT;
			}
			else if(ta & TextAlignment.CENTER)
			{
				return ContentAlignment.MIDDLE_CENTER;
			}
			else // Left.
			{
				return ContentAlignment.MIDDLE_LEFT;
			}
		}
		else // Top.
		{
			if(ta & TextAlignment.RIGHT)
			{
				return ContentAlignment.TOP_RIGHT;
			}
			else if(ta & TextAlignment.CENTER)
			{
				return ContentAlignment.TOP_CENTER;
			}
			else // Left.
			{
				return ContentAlignment.TOP_LEFT;
			}
		}
	}
	
	
	protected override @property Size defaultSize() // getter
	{
		return Size(100, 23);
	}
	
	
	protected override void onPaint(PaintEventArgs ea)
	{
		int x, y, w, h;
		Dstring text;
		
		text = this.text;
		
		if(tfmt.alignment & TextAlignment.MIDDLE)
		{
			// Graphics.drawText() does not support middle alignment
			// if the text is multiline, so need to do extra work.
			Size sz;
			sz = ea.graphics.measureText(text, font, tfmt);
			x = 0;
			//if(sz.height >= this.clientSize.height)
			//	y = 0;
			//else
				y = (this.clientSize.height - sz.height) / 2;
			w = clientSize.width;
			h = sz.height;
		}
		else if(tfmt.alignment & TextAlignment.BOTTOM)
		{
			// Graphics.drawText() does not support bottom alignment
			// if the text is multiline, so need to do extra work.
			Size sz;
			sz = ea.graphics.measureText(text, font, tfmt);
			x = 0;
			//if(sz.height >= this.clientSize.height)
			//	y = 0;
			//else
				y = this.clientSize.height - sz.height;
			w = clientSize.width;
			h = sz.height;
		}
		else
		{
			x = 0;
			y = 0;
			w = clientSize.width;
			h = clientSize.height;
		}
		
		Color c;
		//c = foreColor;
		c = foreColor.solidColor(backColor);
		
		if(enabled)
		{
			ea.graphics.drawText(text, font, c, Rect(x, y, w, h), tfmt);
		}
		else
		{
			version(LABEL_GRAYSTRING)
			{
				// GrayString() is pretty ugly.
				GrayStringA(ea.graphics.handle, null, &_disabledOutputProc,
					cast(LPARAM)cast(void*)this, -1, x, y, w, h);
			}
			else
			{
				ea.graphics.drawTextDisabled(text, font, c, backColor, Rect(x, y, w, h), tfmt);
			}
		}
		
		super.onPaint(ea);
	}
	
	
	/+
	protected override void onHandleCreated(EventArgs ea)
	{
		super.onHandleCreated(ea);
		
		/+
		if(autosz)
			doAutoSize(text);
		+/
	}
	+/
	
	
	protected override void onEnabledChanged(EventArgs ea)
	{
		invalidate(false);
		
		super.onEnabledChanged(ea);
	}
	
	
	protected override void onFontChanged(EventArgs ea)
	{
		if(autosz)
			doAutoSize(text);
		
		invalidate(false);
		
		super.onFontChanged(ea);
	}
	
	
	protected override void wndProc(ref Message m)
	{
		switch(m.msg)
		{
			case WM_GETDLGCODE:
				super.wndProc(m);
				//if(useMnemonic)
					m.result |= DLGC_STATIC;
				break;
			
			default:
				super.wndProc(m);
		}
	}
	
	
	protected override bool processMnemonic(dchar charCode)
	{
		if(visible && enabled)
		{
			if(isMnemonic(charCode, text))
			{
				select(true, true);
				return true;
			}
		}
		return false;
	}
	
	
	private:
	TextFormat _tfmt;
	bool autosz = false;
	
	
	final @property void tfmt(TextFormat tf) // setter
	{
		_tfmt = tf;
	}
	
	
	final @property TextFormat tfmt() // getter
	{
		/+
		// This causes it to invert.
		if(rightToLeft)
			_tfmt.formatFlags = _tfmt.formatFlags | TextFormatFlags.DIRECTION_RIGHT_TO_LEFT;
		else
			_tfmt.formatFlags = _tfmt.formatFlags & ~TextFormatFlags.DIRECTION_RIGHT_TO_LEFT;
		+/
		
		return _tfmt;
	}
}


version(LABEL_GRAYSTRING)
{
	private extern(Windows) BOOL _disabledOutputProc(HDC hdc, LPARAM lpData, int cchData)
	{
		BOOL result = TRUE;
		try
		{
			scope Graphics g = new Graphics(hdc, false);
			Label l;
			with(l = cast(Label)cast(void*)lpData)
			{
				g.drawText(text, font, foreColor,
					Rect(0, 0, clientSize.width, clientSize.height), tfmt);
			}
		}
		catch(DThrowable e)
		{
			Application.onThreadException(e);
			result = FALSE;
		}
		return result;
	}
}

