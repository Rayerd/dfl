// Written by Christopher E. Miller
// See the included license.txt for copyright and license details.


///
module dfl.panel;

import dfl.base;
import dfl.control;
import dfl.drawing;
import dfl.label;

import dfl.internal.winapi;


/// Panel control container
class Panel: ContainerControl // docmain
{
	/// Constructor
	this()
	{
		//ctrlStyle |= ControlStyles.SELECTABLE | ControlStyles.CONTAINER_CONTROL;
		_controlStyle |= ControlStyles.CONTAINER_CONTROL;
		/+ wstyle |= WS_TABSTOP; +/ // Should WS_TABSTOP be set?
		//wexstyle |= WS_EX_CONTROLPARENT; // Allow tabbing through children. ?
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
	@property BorderStyle borderStyle() const // getter
	{
		if(_exStyle() & WS_EX_CLIENTEDGE)
			return BorderStyle.FIXED_3D;
		else if(_style() & WS_BORDER)
			return BorderStyle.FIXED_SINGLE;
		return BorderStyle.NONE;
	}
}


/// StackPanel control for automatic stacking of child controls
class StackPanel : Panel
{
	///
	void orientation(Orientation orientaion) @property // setter
	{
		_orientation = orientaion;
		foreach (ctrl; controls)
			_setOrientation(ctrl, orientaion);
	}

	///
	Orientation orientation() const @property // getter
	{
		return _orientation;
	}


	///
	void add(Control c)
	{
		if (typeid(c) == typeid(Separator))
		{
			c.width = 1;
			c.height = 1;
		}

		_setOrientation(c, _orientation);
		controls.add(c);
		c.parent = this;
	}


private:

	Orientation _orientation; ///


	///
	void _setOrientation(Control c, Orientation orientation)
	{
		final switch (orientation)
		{
		case Orientation.HORIZONTAL:
			c.dock = DockStyle.LEFT;
			break;
		case Orientation.VERTICAL:
			c.dock = DockStyle.TOP;
			break;
		case Orientation.HORIZONTAL_INVERSE:
			c.dock = DockStyle.RIGHT;
			break;
		case Orientation.VERTICAL_INVERSE:
			c.dock = DockStyle.BOTTOM;
		}
	}
}


/// Simplle separator control for use in StackPanel
class Separator : Label
{
	/// Constructor
	this()
	{
		_exStyle(_exStyle() & ~WS_EX_CLIENTEDGE);
		_style(_style() | WS_BORDER);

		backColor = SystemColors.controlDarkDark;
	}
}
