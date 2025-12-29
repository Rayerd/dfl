// Written by Christopher E. Miller
// See the included license.txt for copyright and license details.


///
module dfl.label;

import dfl.application;
import dfl.base;
import dfl.control;
import dfl.drawing;
import dfl.event;

import dfl.internal.dlib;
import dfl.internal.dpiaware;

import core.sys.windows.winbase;
import core.sys.windows.winuser;


///
class Label: Control // docmain
{
	///
	this()
	{
		resizeRedraw = true; // Word wrap and center correctly.
		
		_tfmt = new TextFormat(TextFormatFlags.WORD_BREAK | TextFormatFlags.LINE_LIMIT);
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
		
		if (isHandleCreated)
		{
			redrawEntire();
		}
	}
	
	/// ditto
	@property BorderStyle borderStyle() const // getter
	{
		if (_exStyle() & WS_EX_CLIENTEDGE)
			return BorderStyle.FIXED_3D;
		else if (_style() & WS_BORDER)
			return BorderStyle.FIXED_SINGLE;
		return BorderStyle.NONE;
	}
	
	
	///
	final @property void useMnemonic(bool byes) // setter
	{
		if (byes)
		{
			_tfmt.formatFlags = _tfmt.formatFlags & ~TextFormatFlags.NO_PREFIX;
			_style(_style() & ~SS_NOPREFIX);
		}
		else
		{
			_tfmt.formatFlags = _tfmt.formatFlags | TextFormatFlags.NO_PREFIX;
			_style(_style() | SS_NOPREFIX);
		}
		
		if(isHandleCreated)
			invalidate();
	}
	
	/// ditto
	final @property bool useMnemonic() const // getter
	{
		return (_tfmt.formatFlags & TextFormatFlags.NO_PREFIX) == 0;
	}
	
	
	///
	@property Size preferredSize() // getter
	{
		Graphics g;
		if (isHandleCreated)
			g = createGraphics();
		else
			g = Graphics.getScreen();
		Size result = g.measureText(text, _windowScaledFont, _tfmt); // DPI-scaled.
		g.dispose();
		return result;
	}
	
	
	///
	private void _doAutoSize()
	{
		if (!_autoSize) return;
		
		const uint border = {
			final switch (borderStyle)
			{
				case BorderStyle.FIXED_3D:
					return 2;
				case BorderStyle.FIXED_SINGLE:
					return 1;
				case BorderStyle.NONE:
					return 0;
			}
		}();
		const Size withinBoundsBorder = preferredSize + Size(border * 2, border * 2); // DPI-scaled.
		size = withinBoundsBorder * USER_DEFAULT_SCREEN_DPI / dpi; // Not DPI-scaled.
	}
	
	
	///
	override @property void text(Dstring newText) // setter
	{
		super.text = newText;
		_doAutoSize();
		invalidate(false);
	}
	
	alias text = Control.text; // Overload.
	
	
	///
	@property void autoSize(bool byes) // setter
	{
		if (byes != _autoSize)
			_autoSize = byes;
		_doAutoSize();
	}
	
	/// ditto
	@property bool autoSize() const // getter
	{
		return _autoSize;
	}
	
	
	///
	@property void textAlign(ContentAlignment calign) // setter
	{
		final switch (calign)
		{
			case ContentAlignment.TOP_LEFT:
				_tfmt.alignment = TextAlignment.TOP | TextAlignment.LEFT;
				break;
			
			case ContentAlignment.BOTTOM_CENTER:
				_tfmt.alignment = TextAlignment.BOTTOM | TextAlignment.CENTER;
				break;
			
			case ContentAlignment.BOTTOM_LEFT:
				_tfmt.alignment = TextAlignment.BOTTOM | TextAlignment.LEFT;
				break;
			
			case ContentAlignment.BOTTOM_RIGHT:
				_tfmt.alignment = TextAlignment.BOTTOM | TextAlignment.RIGHT;
				break;
			
			case ContentAlignment.MIDDLE_CENTER:
				_tfmt.alignment = TextAlignment.MIDDLE | TextAlignment.CENTER;
				break;
			
			case ContentAlignment.MIDDLE_LEFT:
				_tfmt.alignment = TextAlignment.MIDDLE | TextAlignment.LEFT;
				break;
			
			case ContentAlignment.MIDDLE_RIGHT:
				_tfmt.alignment = TextAlignment.MIDDLE | TextAlignment.RIGHT;
				break;
			
			case ContentAlignment.TOP_CENTER:
				_tfmt.alignment = TextAlignment.TOP | TextAlignment.CENTER;
				break;
			
			case ContentAlignment.TOP_RIGHT:
				_tfmt.alignment = TextAlignment.TOP | TextAlignment.RIGHT;
				break;
		}
		
		invalidate(); // TODO: ?
	}
	
	/// ditto
	@property ContentAlignment textAlign() const // getter
	{
		TextAlignment ta = _tfmt.alignment;
		
		if (ta & TextAlignment.BOTTOM)
		{
			if (ta & TextAlignment.RIGHT)
			{
				return ContentAlignment.BOTTOM_RIGHT;
			}
			else if (ta & TextAlignment.CENTER)
			{
				return ContentAlignment.BOTTOM_CENTER;
			}
			else // Left.
			{
				return ContentAlignment.BOTTOM_LEFT;
			}
		}
		else if (ta & TextAlignment.MIDDLE)
		{
			if (ta & TextAlignment.RIGHT)
			{
				return ContentAlignment.MIDDLE_RIGHT;
			}
			else if (ta & TextAlignment.CENTER)
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
			if (ta & TextAlignment.RIGHT)
			{
				return ContentAlignment.TOP_RIGHT;
			}
			else if (ta & TextAlignment.CENTER)
			{
				return ContentAlignment.TOP_CENTER;
			}
			else // Left.
			{
				return ContentAlignment.TOP_LEFT;
			}
		}
	}
	
	
	///
	protected override @property Size defaultSize() const // getter
	{
		return Size(100, 23);
	}
	
	
	///
	protected override void onPaint(PaintEventArgs ea)
	{
		super.onPaint(ea);

		const Rect rect = {
			Rect rc;
			if (_tfmt.alignment & TextAlignment.MIDDLE)
			{
				// Graphics.drawText() does not support middle alignment
				// if the text is multiline, so need to do extra work.
				Size dpiScaledSize = ea.graphics.measureText(text, _windowScaledFont, _tfmt);
				rc.x = 0;
				rc.y = (MulDiv(size.height, dpi, USER_DEFAULT_SCREEN_DPI) - dpiScaledSize.height) / 2;
				rc.width = MulDiv(size.width, dpi, USER_DEFAULT_SCREEN_DPI);
				rc.height = dpiScaledSize.height;
			}
			else if (_tfmt.alignment & TextAlignment.BOTTOM)
			{
				// Graphics.drawText() does not support bottom alignment
				// if the text is multiline, so need to do extra work.
				Size dpiScaledSize = ea.graphics.measureText(text, _windowScaledFont, _tfmt);
				rc.x = 0;
				rc.y = MulDiv(size.height, dpi, USER_DEFAULT_SCREEN_DPI) - dpiScaledSize.height;
				rc.width = MulDiv(size.width, dpi, USER_DEFAULT_SCREEN_DPI);
				rc.height = dpiScaledSize.height;
			}
			else
			{
				rc.x = 0;
				rc.y = 0;
				rc.width = MulDiv(size.width, dpi, USER_DEFAULT_SCREEN_DPI);
				rc.height = MulDiv(size.height, dpi, USER_DEFAULT_SCREEN_DPI);
			}
			return rc;
		}();
		
		const Color color = foreColor.solidColor(backColor);

		if (enabled)
		{
			const Rect r = rect * dpi / USER_DEFAULT_SCREEN_DPI;
			ea.graphics.drawText(text, _windowScaledFont, color, r, _tfmt);
		}
		else
		{
			version (LABEL_GRAYSTRING)
			{
				// GrayString() is pretty ugly.
				GrayStringA(ea.graphics.handle, null, &_disabledOutputProc, cast(LPARAM)cast(void*)this, -1, rect.x, rect.y, rect.width, rect.height);
			}
			else
			{
				ea.graphics.drawTextDisabled(text, _windowScaledFont, color, backColor, rect, _tfmt);
			}
		}
	}
	
	
	///
	protected override void onHandleCreated(EventArgs ea)
	{
		super.onHandleCreated(ea);
		
		_doAutoSize();
	}
	
	
	///
	protected override void onEnabledChanged(EventArgs ea)
	{
		invalidate(false);
		
		super.onEnabledChanged(ea);
	}
	
	
	///
	protected override void onFontChanged(EventArgs ea)
	{
		_doAutoSize();
		
		invalidate(false);
		
		super.onFontChanged(ea);
	}
	
	///
	protected override void onDpiChanged(uint newDpi)
	{
		_doAutoSize();
	}
	

	///
	protected override void wndProc(ref Message m)
	{
		switch (m.msg)
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
	
	
	///
	protected override bool processMnemonic(dchar charCode)
	{
		if (visible && enabled)
		{
			if (isMnemonic(charCode, text))
			{
				select(true, true);
				return true;
			}
		}
		return false;
	}
	
	
private:
	TextFormat _textFormat; ///
	bool _autoSize = false; ///
	
	
	///
	@property void _tfmt(TextFormat tf) // setter
	{
		_textFormat = tf;
	}
	
	
	///
	@property inout(TextFormat) _tfmt() inout // getter
	{
		/+
		// This causes it to invert.
		if(rightToLeft)
			_tfmt.formatFlags = _tfmt.formatFlags | TextFormatFlags.DIRECTION_RIGHT_TO_LEFT;
		else
			_tfmt.formatFlags = _tfmt.formatFlags & ~TextFormatFlags.DIRECTION_RIGHT_TO_LEFT;
		+/
		
		return _textFormat;
	}
}


version(LABEL_GRAYSTRING)
{
	///
	private extern(Windows) BOOL _disabledOutputProc(HDC hdc, LPARAM lpData, int cchData)
	{
		BOOL result = TRUE;
		try
		{
			scope Graphics g = new Graphics(hdc, false);
			Label l;
			with (l = cast(Label)cast(void*)lpData)
			{
				g.drawText(text, font, foreColor,
					Rect(0, 0, clientSize.width, clientSize.height), tfmt);
			}
		}
		catch (DThrowable e)
		{
			Application.onThreadException(e);
			result = FALSE;
		}
		return result;
	}
}

