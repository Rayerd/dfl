// Written by Christopher E. Miller
// See the included license.txt for copyright and license details.


///
module dfl.tooltip;

import dfl.application;
import dfl.base;
import dfl.control;
import dfl.drawing;

import dfl.internal.clib;
import dfl.internal.dlib;
import dfl.internal.dpiaware;
import dfl.internal.utf;

import core.sys.windows.commctrl;
import core.sys.windows.windows;


///
enum ToolTipIcon
{
	NONE = 0,
	INFO = 1,
	WARNING = 2,
	ERROR = 3,
	INFO_LARGE = 4,
	WARNING_LARGE = 5,
	ERROR_LARGE = 6,
}


///
class ToolTip // docmain
{
private:
	static if (dfl.internal.utf.useUnicode)
		enum TOOLTIPS_CLASS = "tooltips_class32"w;
	else
		enum TOOLTIPS_CLASS = "tooltips_class32";
	enum size_t MAX_TIP_TEXT_LENGTH = 2045;
	enum int DEFAULT_TIP_WIDTH = -1;
	
	HWND _hwtt; // Tooltip control handle.
	bool _active = true;
	ToolTipIcon _icon = ToolTipIcon.NONE;
	Dstring _title;
	Font _font;
	uint _dpi;


package:
	this(DWORD style)
	{
		_initCommonControls(ICC_TREEVIEW_CLASSES); // Includes tooltip.
		
		_hwtt = CreateWindowEx(WS_EX_TOPMOST | WS_EX_TOOLWINDOW, TOOLTIPS_CLASS.ptr,
			"", style, CW_USEDEFAULT, CW_USEDEFAULT, CW_USEDEFAULT, CW_USEDEFAULT, null, null, null, null);
		if(!_hwtt)
			throw new DflException("Unable to create tooltip");

		_dpi = GetDpiForWindow(_hwtt);
		const int fontSizePt = 9; // default size
		const int fontHeight = -MulDiv(fontSizePt, _dpi, USER_DEFAULT_SCREEN_DPI);
		_font = new Font("Segoe UI", fontHeight);
		SendMessage(_hwtt, WM_SETFONT, cast(WPARAM)_font.handle, TRUE);
	}
	
	
public:
	this()
	{
		// enum TTS_USEVISUALSTYLE = 0x100;
		this(cast(DWORD)(WS_POPUP | TTS_NOPREFIX));
	}
	
	
	~this()
	{
		removeAll(); // Fixes ref count.
		DestroyWindow(_hwtt);
	}
	
	
	///
	final @property HWND handle() const // getter
	{
		return cast(HWND)_hwtt;
	}
	
	
	///
	final @property void active(bool byes) // setter
	{
		SendMessage(_hwtt, TTM_ACTIVATE, byes, 0);
		_active = byes;
	}
	
	/// ditto
	final @property bool active() const // getter
	{
		return _active;
	}
	
	
	///
	// Sets autoPopDelay, initialDelay and reshowDelay.
	final @property void automaticDelay(DWORD ms) // setter
	{
		SendMessage(_hwtt, TTM_SETDELAYTIME, TTDT_AUTOMATIC, ms);
	}
	
	/+
	/// ditto
	final @property DWORD automaticDelay() // getter
	{
	}
	+/
	
	
	///
	final @property void autoPopDelay(DWORD ms) // setter
	{
		SendMessage(_hwtt, TTM_SETDELAYTIME, TTDT_AUTOPOP, ms);
	}
	
	/+
	/// ditto
	final @property DWORD autoPopDelay() // getter
	{
	}
	+/
	
	
	///
	final @property void initialDelay(DWORD ms) // setter
	{
		SendMessage(_hwtt, TTM_SETDELAYTIME, TTDT_INITIAL, ms);
	}
	
	/+
	/// ditto
	final @property DWORD initialDelay() // getter
	{
	}
	+/
	
	
	///
	final @property void reshowDelay(DWORD ms) // setter
	{
		SendMessage(_hwtt, TTS_BALLOON, 0, 0);
	}
	
	/+
	/// ditto
	final @property DWORD reshowDelay() // getter
	{
	}
	+/
	
	
	///
	final @property void isBalloon(bool byes) // setter
	{
		LONG wl = GetWindowLongPtr(_hwtt, GWL_STYLE).toI32;
		if(byes)
		{
			if(wl & TTS_BALLOON)
				return;
			wl |= TTS_BALLOON;
		}
		else
		{
			if(!(wl & TTS_BALLOON))
				return;
			wl &= ~TTS_BALLOON;
		}
		SetWindowLongPtr(_hwtt, GWL_STYLE, wl);
	}
	
	/// ditto
	final @property bool isBalloon() const // getter
	{
		return (GetWindowLongPtr(cast(HWND)_hwtt, GWL_STYLE) & TTS_BALLOON) != 0;
	}
	

	///
	final @property void stripAmpersands(bool byes) // setter
	{
		LONG wl = GetWindowLongPtr(_hwtt, GWL_STYLE).toI32;
		if(!byes)
		{
			if(wl & TTS_NOPREFIX)
				return;
			wl |= TTS_NOPREFIX;
		}
		else
		{
			if(!(wl & TTS_NOPREFIX))
				return;
			wl &= ~TTS_NOPREFIX;
		}
		SetWindowLongPtr(_hwtt, GWL_STYLE, wl);
	}
	
	/// ditto
	final @property bool stripAmpersands() const // getter
	{
		return (GetWindowLongPtr(cast(HWND)_hwtt, GWL_STYLE) & TTS_NOPREFIX) == 0;
	}
	

	///
	final @property void toolTipIcon(ToolTipIcon icon) // setter
	{
		_icon = icon;
		static if (dfl.internal.utf.useUnicode)
			SendMessage(_hwtt, TTM_SETTITLE, cast(WPARAM)_icon, cast(LPARAM)toUnicodez(_title));
		else
			SendMessage(_hwtt, TTM_SETTITLE, cast(WPARAM)_icon, cast(LPARAM)toAnsiz(_title));
	}
	
	/// ditto
	final @property inout(ToolTipIcon) toolTipIcon() inout // getter
	{
		return _icon;
	}
	
	
	///
	// The maximum length of a title is 99 characters.
	// If this property contains a string longer then 99 characters, no title will be displayed.
	final @property void toolTipTitle(Dstring title) // setter
	{
		_title = title;
		static if (dfl.internal.utf.useUnicode)
			SendMessage(_hwtt, TTM_SETTITLE, cast(WPARAM)_icon, cast(LPARAM)toUnicodez(_title));
		else
			SendMessage(_hwtt, TTM_SETTITLE, cast(WPARAM)_icon, cast(LPARAM)toAnsiz(_title));
	}
	
	/// ditto
	final @property Dstring toolTipTitle() const // getter
	{
		return _title;
	}
	
	
	///
	final @property void useAnimation(bool byes) // setter
	{
		LONG wl = GetWindowLongPtr(_hwtt, GWL_STYLE).toI32;
		if(!byes)
		{
			if(wl & TTS_NOANIMATE)
				return;
			wl |= TTS_NOANIMATE;
		}
		else
		{
			if(!(wl & TTS_NOANIMATE))
				return;
			wl &= ~TTS_NOANIMATE;
		}
		SetWindowLongPtr(_hwtt, GWL_STYLE, wl);
	}
	
	/// ditto
	final @property bool useAnimation() const // getter
	{
		return (GetWindowLongPtr(cast(HWND)_hwtt, GWL_STYLE) & TTS_NOANIMATE) == 0;
	}
	

	///
	final @property void useFading(bool byes) // setter
	{
		LONG wl = GetWindowLongPtr(_hwtt, GWL_STYLE).toI32;
		if(!byes)
		{
			if(wl & TTS_NOFADE)
				return;
			wl |= TTS_NOFADE;
		}
		else
		{
			if(!(wl & TTS_NOFADE))
				return;
			wl &= ~TTS_NOFADE;
		}
		SetWindowLongPtr(_hwtt, GWL_STYLE, wl);
	}
	
	/// ditto
	final @property bool useFading() const // getter
	{
		return (GetWindowLongPtr(cast(HWND)_hwtt, GWL_STYLE) & TTS_NOFADE) == 0;
	}


	///
	final @property void showAlways(bool byes) // setter
	{
		LONG wl = GetWindowLongPtr(_hwtt, GWL_STYLE).toI32;
		if(byes)
		{
			if(wl & TTS_ALWAYSTIP)
				return;
			wl |= TTS_ALWAYSTIP;
		}
		else
		{
			if(!(wl & TTS_ALWAYSTIP))
				return;
			wl &= ~TTS_ALWAYSTIP;
		}
		SetWindowLongPtr(_hwtt, GWL_STYLE, wl);
	}
	
	/// ditto
	final @property bool showAlways() const // getter
	{
		return (GetWindowLongPtr(cast(HWND)_hwtt, GWL_STYLE) & TTS_ALWAYSTIP) != 0;
	}
	
	
	///
	// Remove all tooltip text associated with this instance.
	final void removeAll()
	{
		TOOLINFO tool;
		tool.cbSize = TOOLINFO.sizeof;
		while(SendMessage(_hwtt, TTM_ENUMTOOLS, 0, cast(LPARAM)&tool))
		{
			SendMessage(_hwtt, TTM_DELTOOL, 0, cast(LPARAM)&tool);
			Application.refCountDec(cast(void*)this);
		}
	}
	
	
	///
	// WARNING: possible buffer overflow.
	final Dstring getToolTip(Control ctrl) const
	{
		Dstring result;
		TOOLINFO tool;
		tool.cbSize = TOOLINFO.sizeof;
		tool.uFlags = TTF_IDISHWND;
		tool.hwnd = ctrl.handle;
		tool.uId = cast(UINT)ctrl.handle;
		
		static if(dfl.internal.utf.useUnicode)
		{
			tool.lpszText = cast(typeof(tool.lpszText))dfl.internal.clib.malloc((MAX_TIP_TEXT_LENGTH + 1) * wchar.sizeof);
			if(!tool.lpszText)
				throw new OomException;
			scope(exit)
				dfl.internal.clib.free(tool.lpszText);
			tool.lpszText[0 .. 2] = 0;
			SendMessage(cast(HWND)_hwtt, TTM_GETTEXT, 0, cast(LPARAM)&tool);
			if(!(cast(wchar*)tool.lpszText)[0])
				result = null;
			else
				result = fromUnicodez(cast(wchar*)tool.lpszText);
		}
		else
		{
			tool.lpszText = cast(typeof(tool.lpszText))dfl.internal.clib.malloc(MAX_TIP_TEXT_LENGTH + 1);
			if(!tool.lpszText)
				throw new OomException;
			scope(exit)
				dfl.internal.clib.free(tool.lpszText);
			tool.lpszText[0] = 0;
			SendMessage(_hwtt, TTM_GETTEXT, 0, cast(LPARAM)&tool);
			if(!tool.lpszText[0])
				result = null;
			else
				result = fromAnsiz(tool.lpszText); // Assumes fromAnsiz() copies.
		}
		return result;
	}
	
	
	///
	final void setToolTip(Control ctrl, Dstring text)
	in
	{
		try
		{
			ctrl.createControl();
		}
		catch(DThrowable o)
		{
			assert(0); // If -ctrl- is a child, make sure the parent is set before setting tool tip text.
			//throw o;
		}
	}
	do
	{
		TOOLINFO tool;
		tool.cbSize = TOOLINFO.sizeof;
		tool.uFlags = TTF_IDISHWND | TTF_PARSELINKS;
		tool.hwnd = ctrl.handle;
		tool.uId = cast(UINT)ctrl.handle;
		
		if(!text.length)
		{
			if(SendMessage(_hwtt, TTM_GETTOOLINFO, 0, cast(LPARAM)&tool))
			{
				// Remove.
				
				SendMessage(_hwtt, TTM_DELTOOL, 0, cast(LPARAM)&tool);
				
				Application.refCountDec(cast(void*)this);
			}
			return;
		}
		
		// Hack to help prevent getToolTip() overflow.
		if(text.length > MAX_TIP_TEXT_LENGTH)
			text = text[0 .. MAX_TIP_TEXT_LENGTH];
		
		if(SendMessage(_hwtt, TTM_GETTOOLINFO, 0, cast(LPARAM)&tool))
		{
			// Update.

			static if(dfl.internal.utf.useUnicode)
			{
				tool.lpszText = cast(typeof(tool.lpszText))toUnicodez(text);
				SendMessage(_hwtt, TTM_UPDATETIPTEXT, 0, cast(LPARAM)&tool);
			}
			else
			{
				tool.lpszText = cast(typeof(tool.lpszText))unsafeAnsiz(text);
				SendMessage(_hwtt, TTM_UPDATETIPTEXT, 0, cast(LPARAM)&tool);
			}
		}
		else
		{
			// Add.
			
			/+
			// TOOLINFOA.rect is ignored if TTF_IDISHWND.
			tool.rect.left = 0;
			tool.rect.top = 0;
			tool.rect.right = ctrl.clientSize.width;
			tool.rect.bottom = ctrl.clientSize.height;
			+/
			tool.uFlags |= TTF_SUBCLASS; // Not a good idea ?
			LRESULT lr;
			static if(dfl.internal.utf.useUnicode)
			{
				tool.lpszText = cast(typeof(tool.lpszText))toUnicodez(text);
				lr = SendMessage(_hwtt, TTM_ADDTOOL, 0, cast(LPARAM)&tool);
			}
			else
			{
				tool.lpszText = cast(typeof(tool.lpszText))unsafeAnsiz(text);
				lr = SendMessage(_hwtt, TTM_ADDTOOL, 0, cast(LPARAM)&tool);
			}
			
			if(lr)
				Application.refCountInc(cast(void*)this);
		}
	}


	///
	// Extra.
	void disableAutoWrap()
	{
		SendMessage(_hwtt, TTM_SETMAXTIPWIDTH, 0, DEFAULT_TIP_WIDTH);
	}


	///
	// Extra.
	void maxWidth(int width) @property // setter
	{
		SendMessage(_hwtt, TTM_SETMAXTIPWIDTH, 0, width);
	}
	
	/// ditto
	int maxWidth() const @property // getter
	{
		return cast(int)SendMessage(cast(HWND)_hwtt, TTM_GETMAXTIPWIDTH, 0, 0);
	}
}
