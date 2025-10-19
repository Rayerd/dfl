module dfl.toggleswitch;

import dfl.base;
import dfl.control;
import dfl.drawing;
import dfl.event;


///
class ToggleSwitch : Control
{
	/// Constructor.
	this()
	{
		size = Size(70, 40); // default size.
	}


	///
	protected override void onPaint(PaintEventArgs pea)
	{
		enum uint PEN_WIDTH = 2;

		Color baseColor = {
			if (isOn && enabled)
				return baseColorOn;
			else if (!isOn && enabled)
				return baseColorOff;
			else if (!enabled)
				return Color.darkGray;
			else
				assert(false);
		}();

		Color edgeColor = {
			if (isOn && enabled)
				return edgeColorOn;
			else if (!isOn && enabled)
				return edgeColorOff;
			else if (!enabled)
				return Color.darkGray;
			else
				assert(false);
		}();

		Color thumbColor = {
			if (isOn && enabled)
				return thumbColorOn;
			else if (!isOn && enabled)
				return thumbColorOff;
			else if (!enabled)
				return Color.gray;
			else
				assert(false);
		}();

		Brush innerBrush = new SolidBrush(baseColor);
		Brush thumbBrush = new SolidBrush(thumbColor);

		int x0 = PEN_WIDTH;
		int y0 = PEN_WIDTH;
		int w0 = width - 2 * PEN_WIDTH;
		int h0 = height - 2 * PEN_WIDTH;
		
		Rect bodyRect = Rect(x0 + h0 * 0.5, y0, w0 - h0 - 1, h0 - 1); // ==
		Rect leftCircle = Rect(x0, y0, h0, h0); // (
		Rect rightCircle = Rect(x0 + w0 - h0, y0, h0, h0); // )
		const double thumbCircleRatio = { // o
			if (_isMouseHover)
				return 0.6;
			else
				return 0.7;
		}();
		Rect thumbRect = {
			if(isOn)
			{
				Rect ret = rightCircle;
				if (_isClicking && _isMouseHover)
					ret.x -= cast(int)(ret.width * 0.25);
				ret.scaleFromCenter(thumbCircleRatio, thumbCircleRatio);
				return ret;
			}
			else
			{
				Rect ret = leftCircle;
				if (_isClicking && _isMouseHover)
					ret.x += cast(int)(ret.width * 0.25);
				ret.scaleFromCenter(thumbCircleRatio, thumbCircleRatio);
				return ret;
			}
		}();

		if (isOn)
		{
			pea.graphics.fillRectangle(baseColor, bodyRect);
			pea.graphics.fillEllipse(innerBrush, leftCircle);
			pea.graphics.fillEllipse(innerBrush, rightCircle);
			pea.graphics.fillEllipse(thumbBrush, thumbRect);
		}
		else
		{
			pea.graphics.fillRectangle(baseColor, bodyRect);
			pea.graphics.fillEllipse(innerBrush, leftCircle);
			pea.graphics.fillEllipse(innerBrush, rightCircle);

			Pen edgePen = new Pen(edgeColor, PEN_WIDTH);
			// upper line
			pea.graphics.drawLine(
				edgePen,
				bodyRect.x, bodyRect.y, bodyRect.x + bodyRect.width, bodyRect.y);
			// lower line
			pea.graphics.drawLine(
				edgePen,
				bodyRect.x, bodyRect.y + bodyRect.height, bodyRect.x + bodyRect.width, bodyRect.y + bodyRect.height);
			// (
			pea.graphics.drawArc(
				edgePen,
				leftCircle.x, leftCircle.y, leftCircle.height, leftCircle.height,
				leftCircle.x, int.min, leftCircle.x, int.max);
			// )
			pea.graphics.drawArc(
				edgePen,
				rightCircle.x, rightCircle.y, rightCircle.height, rightCircle.height,
				rightCircle.x, int.max, rightCircle.x, int.min);
			// o
			pea.graphics.fillEllipse(thumbBrush, thumbRect);
		}
	}

	
	///
	protected override void onMouseDown(MouseEventArgs mea)
	{
		capture = true;
		_isClicking = true;
		redraw();
	}


	///
	protected override void onMouseMove(MouseEventArgs mea)
	{
		if (clientRectangle().contains(mea.x, mea.y))
		{
			if (!_isMouseHover)
			{
				_isMouseHover = true;
				redraw();
			}
		}
		else
		{
			if (_isMouseHover)
			{
				_isMouseHover = false;
				redraw();
			}
		}
	}


	///
	protected override void onMouseUp(MouseEventArgs mea)
	{
		if (clientRectangle().contains(mea.x, mea.y) && _isClicking)
			isOn = !isOn; // Called redraw() in isOn() already.
		_isClicking = false;
		capture = false;
	}


	///
	protected override void onMouseEnter(MouseEventArgs mea)
	{
		_isMouseHover = true;
		redraw();
	}


	///
	protected override void onMouseLeave(MouseEventArgs mea)
	{
		_isMouseHover = false;
		redraw();
	}


	///
	@property void isOn(bool byes) // setter
	{
		if (_isOn == byes)
			return;
		_isOn = byes;
		redraw();
		onToggled(new ToggledEventArgs(_isOn));
	}

	/// ditto
	@property bool isOn() const // getter
	{
		return _isOn;
	}


	///
	protected void onToggled(ToggledEventArgs ea)
	{
		toggle(this, ea);
	}

	
	Event!(ToggleSwitch, ToggledEventArgs) toggle; ///

	Color thumbColorOn = Color.white;
	Color thumbColorOff = Color.black;
	Color baseColorOn = Color(0x00, 0x00, 0x7f, 0xff); // azure;
	Color baseColorOff = Color.white;
	Color edgeColorOn = Color(0x00, 0x00, 0x7f, 0xff); // azure;
	Color edgeColorOff = Color.black;


private:
	bool _isOn = true; ///
	bool _isMouseHover; ///
	bool _isClicking; ///
}


///
class ToggledEventArgs : EventArgs
{
	this(bool isOn)
	{
		value = isOn;
	}

	bool value; ///
}
