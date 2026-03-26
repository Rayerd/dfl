module dfl.expander;

import dfl.base;
import dfl.control;
import dfl.drawing;
import dfl.event;
import dfl.panel;

import dfl.internal.dpiaware;

import std.algorithm : min;

import core.sys.windows.winuser;


///
class Expander : ContainerControl
{
	Color defaultBackColor = SystemColors.controlLightLight; ///


	///
	this()
	{
		_windowStyle |= WS_CHILD | WS_VISIBLE;

		_header = new Panel;
		_header.resizeRedraw = true;
		_header.dock = DockStyle.TOP;
		_header.backColor = defaultBackColor;
		_header.mouseDown ~= (Control c, MouseEventArgs e) {
			_header.capture = true;
			_isMouseDown = true;
			_header.invalidate();
		};
		_header.mouseUp ~= (Control c, MouseEventArgs e) {
			if (!_isMouseDown) return;
			Point pt = Point(e.x, e.y) / dpi * USER_DEFAULT_SCREEN_DPI;
			if (_header.displayRectangle.contains(pt.x, pt.y) && _isMouseHover)
				_toggle();
			_isMouseDown = false;
			_header.capture = false;
			_header.invalidate();
		};
		_header.mouseMove ~= (Control c, MouseEventArgs e) {
			Rect rect = _header.clientRectangle * dpi / USER_DEFAULT_SCREEN_DPI;
			if (rect.contains(e.x, e.y))
			{
				if (!_isMouseHover)
				{
					_isMouseHover = true;
					_changeBackColorRecursive(_header, SystemColors.controlLight);
					_header.invalidate();
				}
			}
			else
			{
				if (_isMouseHover)
				{
					_isMouseHover = false;
					_changeBackColorRecursive(_header, defaultBackColor);
					_header.invalidate();
				}
			}
		};
		_header.mouseEnter ~= (Control c, MouseEventArgs e) {
			_isMouseHover = true;
			_changeBackColorRecursive(_header, SystemColors.controlLight);
			_header.invalidate();
		};
		_header.mouseLeave ~= (Control c, MouseEventArgs e) {
			_isMouseHover = false;
			_changeBackColorRecursive(_header, defaultBackColor);
			_header.invalidate();
		};
		_header.handleCreated ~= (Control c, EventArgs e) {
			_header.dockMargin.all = 2;
			Size marginAndPadding = Size(
				_header.dockMargin.left + _header.dockMargin.right + this.dockPadding.left + this.dockPadding.right,
				_header.dockMargin.top + _header.dockMargin.bottom + this.dockPadding.top + this.dockPadding.bottom
			);
			_header.size = this.size - marginAndPadding;
		};
		_header.paint ~= (Control c, PaintEventArgs e) {
			Graphics g = e.graphics;
			{
				Font f = _createScaledFont(_header.font, dpi);
				string str = _header.text;
				Size sz = g.measureText(str, f);
				Rect rc = Rect(0, 0, min(sz.width, _header.width - 50), sz.height);
				// g.drawRectangle(new Pen(Color.red, 1), rc);
				g.drawText(str, f, Color.black, rc);
			}
			{
				Font f = _createScaledFont(new Font("Segoe UI", 14.0f), dpi);
				string str = _isExpanded ? "∧" : "∨";
				Size sz = g.measureText(str, f);
				Rect rc = Rect((_header.width * dpi / USER_DEFAULT_SCREEN_DPI) - sz.width, 0, sz.width, sz.height);
				// g.drawRectangle(new Pen(Color.red, 1), rc);
				g.drawText(str, f, Color.gray, rc);
			}
			{
				if (_isMouseHover)
				{
					Pen pen = {
						if (_isMouseDown)
							return new Pen(Color.gray, 2);
						else
							return new Pen(Color.fromArgb(0, 0x00, 0x8a, 0xd8), 2);
					}();
					g.drawLine(pen,
						Point(_header.left, _header.height - 1) * dpi / USER_DEFAULT_SCREEN_DPI,
						Point(_header.width - 1, _header.height - 1) * dpi / USER_DEFAULT_SCREEN_DPI);
				}
			}
		};
		_header.parent = this;

		_content = new Panel;
		_content.backColor = defaultBackColor;
		_content.dockMargin.right = 2;
		_content.dockMargin.left = 2;
		_content.dockMargin.bottom = 2;
		_content.dockPadding.all = 4;
		_content.dock = DockStyle.TOP;
		_content.controlAdded ~= (Control c, ControlEventArgs e) {
			_content.height =
				+ _content.height
				+ _content.dockMargin.top + _content.dockMargin.bottom
				+ _content.dockPadding.top + _content.dockPadding.bottom
				+ e.control.height
				+ e.control.dockMargin.top + e.control.dockMargin.bottom
				+ e.control.dockPadding.top + e.control.dockPadding.bottom;
		};
		_content.parent = this;

		this._expandDirection = ExpandDirection.DOWN; // TODO: Impliment for UP.

		this.backColor = SystemColors.controlLight;
	}


	///
	@property inout(Panel) header() inout // getter
	{
		return _header;
	}
	

	///
	@property inout(Panel) content() inout // getter
	{
		return _content;
	}


	///
	@property void isExpanded(bool byes) // setter
	{
		if (_isExpanded == byes) return;
		_isExpanded = byes;
		_doExpand(byes);
	}

	/// ditto
	@property bool isExpanded() const // getter
	{
		return _isExpanded;
	}


	///
	@property void expandDirection() // setter
	{
		// TODO: Implement
		assert(false);
	}
	
	/// ditto
	@property ExpandDirection expandDirection() const // getter
	{
		return _expandDirection;
	}



	///
	Event!(Expander, ExpanderExpandedEventArgs) expanded;


protected:


	///
	@property override Size defaultSize() const // getter
	{
		return Size(200, 32);
	}


	///
	void onExpanded(ExpanderExpandedEventArgs e)
	{
		expanded(this, e);
	}


private:


	Panel _header; ///
	Panel _content; ///

	bool _isExpanded; ///
	ExpandDirection _expandDirection; ///

	bool _isMouseHover; ///
	bool _isMouseDown; ///
	

	///
	void _toggle()
	{
		_isExpanded = !_isExpanded;
		_doExpand(_isExpanded);
	}

	
	///
	void _doExpand(bool byes)
	{
		if (byes)
		{
			_content.visible = true;

			Size headerMargin = Size(
				_header.dockMargin.left + _header.dockMargin.right + _header.dockPadding.left + _header.dockPadding.right,
				_header.dockMargin.top + _header.dockMargin.bottom + _header.dockPadding.top + _header.dockPadding.bottom
			);

			Size contentMargin = Size(
				_content.dockMargin.left + _content.dockMargin.right + _content.dockPadding.left + _content.dockPadding.right,
				_content.dockMargin.top + _content.dockMargin.bottom);

			height = _header.height + headerMargin.height + _content.height + contentMargin.height;
		}
		else
		{
			_content.visible = false;

			size = Size(width, _header.height + _header.dockMargin.top + _header.dockMargin.bottom);
		}

		onExpanded(new ExpanderExpandedEventArgs(byes));
	}
	

	// uint _getHightRecursive(Control c)
	// {
	// 	uint ret = c.height + c.dockMargin.top + c.dockMargin.bottom + c.dockPadding.top + c.dockPadding.bottom;
	// 	foreach (Control child; c.controls)
	// 		ret += _getHightRecursive(child);
	// 	return ret;
	// }


	///
	void _changeBackColorRecursive(Control c, Color color)
	{
		c.backColor = color;
		foreach (ctrl; c.controls)
			ctrl.backColor = color;
	}
}


///
enum ExpandDirection
{
	DOWN = 0,
	UP = 1,
}


///
class ExpanderExpandedEventArgs : EventArgs
{
	///
	this(bool byes)
	{
		this.isExpanded = byes;
	}


	///
	bool isExpanded;
}
