module dfl.toggleswitch;

import dfl.base;
import dfl.control;
import dfl.drawing;
import dfl.event;

import dfl.internal.dpiaware;


// Experimental Direct2D support.
static if (0)
{
	import dfl.internal.com;
	import dfl.internal.winrt;

	import core.sys.windows.windows;

	pragma(lib, "d2d1.lib");

	enum D2D1_FACTORY_TYPE
	{
		D2D1_FACTORY_TYPE_SINGLE_THREADED = 0,
		D2D1_FACTORY_TYPE_MULTI_THREADED = 1,
		D2D1_FACTORY_TYPE_FORCE_DWORD = 0xffffffff
	}

	struct D2D1_FACTORY_OPTIONS
	{
		D2D1_DEBUG_LEVEL debugLevel;
	}

	enum D2D1_DEBUG_LEVEL
	{
		D2D1_DEBUG_LEVEL_NONE = 0,
		D2D1_DEBUG_LEVEL_ERROR = 1,
		D2D1_DEBUG_LEVEL_WARNING = 2,
		D2D1_DEBUG_LEVEL_INFORMATION = 3,
		D2D1_DEBUG_LEVEL_FORCE_DWORD = 0xffffffff
	}

	HRESULT D2D1CreateFactory(
		D2D1_FACTORY_TYPE factoryType,
		REFIID riid,
		const D2D1_FACTORY_OPTIONS* pFactoryOptions,
		void** ppIFactory
	);

	struct D2D_RECT_F
	{
		FLOAT left;
		FLOAT top;
		FLOAT right;
		FLOAT bottom;
	}

	alias D2D1_RECT_F = D2D_RECT_F;

	const IID IID_ID2D1Factory = guidFromUUID("2cd90691-12e2-11dc-9fed-001143a055f9");

	static if (0)
	{
		// "2cd90691-12e2-11dc-9fed-001143a055f9"
		interface ID2D1Factory : IUnknown
		{
		extern (Windows):
			/// <summary>
			/// Cause the factory to refresh any system metrics that it might have been snapped
			/// on factory creation.
			/// </summary>
			HRESULT ReloadSystemMetrics();

			/// <summary>
			/// Retrieves the current desktop DPI. To refresh this, call ReloadSystemMetrics.
			/// </summary>
			void GetDesktopDpi(
				FLOAT* dpiX,
				FLOAT* dpiY
			);

			HRESULT CreateRectangleGeometry(
				const D2D1_RECT_F* rectangle,
				ID2D1RectangleGeometry** rectangleGeometry
			);

			HRESULT CreateRoundedRectangleGeometry(
				const D2D1_ROUNDED_RECT* roundedRectangle,
				ID2D1RoundedRectangleGeometry** roundedRectangleGeometry
			);

			HRESULT CreateEllipseGeometry(
				const D2D1_ELLIPSE* ellipse,
				ID2D1EllipseGeometry** ellipseGeometry
			);

			/// <summary>
			/// Create a geometry which holds other geometries.
			/// </summary>
			HRESULT CreateGeometryGroup(
				D2D1_FILL_MODE fillMode,
				ID2D1Geometry** geometries,
				UINT32 geometriesCount,
				ID2D1GeometryGroup** geometryGroup
			);

			HRESULT CreateTransformedGeometry(
				ID2D1Geometry* sourceGeometry,
				const D2D1_MATRIX_3X2_F* transform,
				ID2D1TransformedGeometry** transformedGeometry
			);

			/// <summary>
			/// Returns an initially empty path geometry interface. A geometry sink is created
			/// off the interface to populate it.
			/// </summary>
			HRESULT CreatePathGeometry(
				ID2D1PathGeometry** pathGeometry
			);

			/// <summary>
			/// Allows a non-default stroke style to be specified for a given geometry at draw
			/// time.
			/// </summary>
			HRESULT CreateStrokeStyle(
				const D2D1_STROKE_STYLE_PROPERTIES* strokeStyleProperties,
				const FLOAT* dashes,
				UINT32 dashesCount,
				ID2D1StrokeStyle** strokeStyle
			);

			/// <summary>
			/// Creates a new drawing state block, this can be used in subsequent
			/// SaveDrawingState and RestoreDrawingState operations on the render target.
			/// </summary>
			HRESULT CreateDrawingStateBlock(
				const D2D1_DRAWING_STATE_DESCRIPTION* drawingStateDescription,
				IDWriteRenderingParams* textRenderingParams,
				ID2D1DrawingStateBlock** drawingStateBlock
			);

			/// <summary>
			/// Creates a render target which is a source of bitmaps.
			/// </summary>
			HRESULT CreateWicBitmapRenderTarget(
				IWICBitmap* target,
				const D2D1_RENDER_TARGET_PROPERTIES* renderTargetProperties,
				ID2D1RenderTarget** renderTarget
			);

			/// <summary>
			/// Creates a render target that appears on the display.
			/// </summary>
			HRESULT CreateHwndRenderTarget(
				const D2D1_RENDER_TARGET_PROPERTIES* renderTargetProperties,
				const D2D1_HWND_RENDER_TARGET_PROPERTIES* hwndRenderTargetProperties,
				ID2D1HwndRenderTarget** hwndRenderTarget
			);

			/// <summary>
			/// Creates a render target that draws to a DXGI Surface. The device that owns the
			/// surface is used for rendering.
			/// </summary>
			HRESULT CreateDxgiSurfaceRenderTarget(
				IDXGISurface* dxgiSurface,
				const D2D1_RENDER_TARGET_PROPERTIES* renderTargetProperties,
				ID2D1RenderTarget** renderTarget
			);

			/// <summary>
			/// Creates a render target that draws to a GDI device context.
			/// </summary>
			HRESULT CreateDCRenderTarget(
				const D2D1_RENDER_TARGET_PROPERTIES* renderTargetProperties,
				ID2D1DCRenderTarget** dcRenderTarget
			);

			HRESULT CreateRectangleGeometry(
				const ref D2D1_RECT_F rectangle,
				ID2D1RectangleGeometry** rectangleGeometry
			)
			{
				return CreateRectangleGeometry(&rectangle, rectangleGeometry);
			}

			HRESULT CreateRoundedRectangleGeometry(
				const ref D2D1_ROUNDED_RECT roundedRectangle,
				ID2D1RoundedRectangleGeometry** roundedRectangleGeometry
			)
			{
				return CreateRoundedRectangleGeometry(&roundedRectangle, roundedRectangleGeometry);
			}

			HRESULT CreateEllipseGeometry(
				const ref D2D1_ELLIPSE ellipse,
				ID2D1EllipseGeometry** ellipseGeometry
			)
			{
				return CreateEllipseGeometry(&ellipse, ellipseGeometry);
			}

			HRESULT CreateTransformedGeometry(
				ID2D1Geometry* sourceGeometry,
				const ref D2D1_MATRIX_3X2_F transform,
				ID2D1TransformedGeometry** transformedGeometry
			)
			{
				return CreateTransformedGeometry(sourceGeometry, &transform, transformedGeometry);
			}

			HRESULT CreateStrokeStyle(
				const ref D2D1_STROKE_STYLE_PROPERTIES strokeStyleProperties,
				const FLOAT* dashes,
				UINT32 dashesCount,
				ID2D1StrokeStyle** strokeStyle
			)
			{
				return CreateStrokeStyle(&strokeStyleProperties, dashes, dashesCount, strokeStyle);
			}

			HRESULT CreateDrawingStateBlock(
				const ref D2D1_DRAWING_STATE_DESCRIPTION drawingStateDescription,
				ID2D1DrawingStateBlock** drawingStateBlock
			)
			{
				return CreateDrawingStateBlock(&drawingStateDescription, NULL, drawingStateBlock);
			}

			HRESULT CreateDrawingStateBlock(
				ID2D1DrawingStateBlock** drawingStateBlock
			)
			{
				return CreateDrawingStateBlock(NULL, NULL, drawingStateBlock);
			}

			HRESULT CreateWicBitmapRenderTarget(
				IWICBitmap* target,
				const ref D2D1_RENDER_TARGET_PROPERTIES renderTargetProperties,
				ID2D1RenderTarget** renderTarget
			)
			{
				return CreateWicBitmapRenderTarget(target, &renderTargetProperties, renderTarget);
			}

			HRESULT CreateHwndRenderTarget(
				const ref D2D1_RENDER_TARGET_PROPERTIES renderTargetProperties,
				const ref D2D1_HWND_RENDER_TARGET_PROPERTIES hwndRenderTargetProperties,
				ID2D1HwndRenderTarget** hwndRenderTarget
			)
			{
				return CreateHwndRenderTarget(&renderTargetProperties, &hwndRenderTargetProperties, hwndRenderTarget);
			}

			HRESULT CreateDxgiSurfaceRenderTarget(
				IDXGISurface* dxgiSurface,
				const ref D2D1_RENDER_TARGET_PROPERTIES renderTargetProperties,
				ID2D1RenderTarget** renderTarget
			)
			{
				return CreateDxgiSurfaceRenderTarget(dxgiSurface, &renderTargetProperties, renderTarget);
			}
		}
	}
}

///
class ToggleSwitch : Control
{
	// ComPtr!ID2D1Factory _d2dFactory;

	/// Constructor.
	this()
	{
		super();
		// D2D1CreateFactory(D2D1_FACTORY_TYPE.D2D1_FACTORY_TYPE_SINGLE_THREADED, &IID_ID2D1Factory, null, _d2dFactory.handle);
		_windowRect.size = Size(70, 41);
	}


	///
	protected override void onPaint(PaintEventArgs pea)
	{
		super.onPaint(pea);

		enum uint PEN_WIDTH = 2;

		const Color baseColor = {
			if (isOn && enabled)
				return baseColorOn;
			else if (!isOn && enabled)
				return baseColorOff;
			else if (!enabled)
				return Color.darkGray;
			else
				assert(false);
		}();

		const Color edgeColor = {
			if (isOn && enabled)
				return edgeColorOn;
			else if (!isOn && enabled)
				return edgeColorOff;
			else if (!enabled)
				return Color.darkGray;
			else
				assert(false);
		}();

		const Color thumbColor = {
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

		const int x0 = PEN_WIDTH;
		const int y0 = PEN_WIDTH;
		const int w0 = width - 2 * PEN_WIDTH;
		const int h0 = height - 2 * PEN_WIDTH;
		
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

		bodyRect = bodyRect * dpi / USER_DEFAULT_SCREEN_DPI;
		leftCircle = leftCircle * dpi / USER_DEFAULT_SCREEN_DPI;
		rightCircle = rightCircle * dpi / USER_DEFAULT_SCREEN_DPI;
		thumbRect = thumbRect * dpi / USER_DEFAULT_SCREEN_DPI;

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
		Rect rect = clientRectangle * dpi / USER_DEFAULT_SCREEN_DPI;
		if (rect.contains(mea.x, mea.y))
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
		Rect rect = clientRectangle * dpi / USER_DEFAULT_SCREEN_DPI;
		if (rect.contains(mea.x, mea.y) && _isClicking)
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
