module dfl.datetimepicker;

import dfl.application;
import dfl.base;
import dfl.control;
import dfl.event;
import dfl.drawing;
import dfl.monthcalendar : toDateTime, toSYSTEMTIME;

import dfl.internal.utf;

import core.sys.windows.commctrl;
import core.sys.windows.winbase;
import core.sys.windows.windef;
import core.sys.windows.winuser;

import std.datetime;


///
enum DTS_FORMAT_MASK = DTS_LONGDATEFORMAT | DTS_TIMEFORMAT | DTS_SHORTDATECENTURYFORMAT | DTS_SHORTDATEFORMAT;


///
enum DateTimePickerFormat
{
	LONG = 1,
	SHORT = 2,
	TIME = 4,
	CUSTOM = 8,
}


///
class DateTimePicker : ControlSuperClass
{
	///
	this()
	{
		_initDateTimePicker();
		
		// setStyle(ControlStyles.USER_PAINT, false);
		// setStyle(ControlStyles.USE_TEXT_FOR_ACCESSIBILITY, false);

		_windowStyle |= WS_BORDER | WS_CHILD | WS_VISIBLE | WS_TABSTOP
			// | DTS_APPCANPARSE
			// | DTS_LONGDATEFORMAT
			// | DTS_RIGHTALIGN
			// | DTS_SHOWNONE
			// | DTS_SHORTDATEFORMAT
			// | DTS_SHORTDATECENTURYFORMAT
			// | DTS_TIMEFORMAT
			// | DTS_UPDOWN
		;

		_controlStyle |= ControlStyles.SELECTABLE;
		_windowClassStyle = datetimepickerClassStyle;
	}

	
	///
	void value(DateTime datetime) // setter
	{
		if (_value == datetime) return;

		_settingValue = true;

		_value = datetime;
		_checked = true;

		if (isHandleCreated)
		{
			SYSTEMTIME systime = toSYSTEMTIME(datetime);
			DateTime_SetSystemtime(cast(HWND)_hwnd, GDT_VALID, &systime);
		}

		onValueChanged(new EventArgs);
	}

	/// ditto
	DateTime value() const // getter
	{
		// if (isHandleCreated)
		// {
		// 	SYSTEMTIME systime;
		// 	DWORD ret = DateTime_GetSystemtime(cast(HWND)_hwnd, &systime);
		// 	if (ret == GDT_VALID)
		// 		return toDateTime(systime);
		// 	throw new DflException("value failure.");
		// }
		return _value; // Returns value if checked == false.
	}


	///
	void format(DateTimePickerFormat newFormat) // setter
	{
		checked = true; // Force the change.
		
		if (_format == newFormat) return;

		_format = newFormat;

		if (isHandleCreated && !recreatingHandle)
		{
			recreateHandle();

			// DTM_SETFORMATW in core.sys.windows.commctrl is broken.
			// The couse is MinGW's one is broken too.
			// DTM_SETFORMATW is 0x1032 (0x1000 + 50), but not 0x1050.
			if (_format == DateTimePickerFormat.CUSTOM && _customFormatString.length)
			{
				auto fmt = toUnicodez(_customFormatString);
				SendMessageW(handle, 0x1032, 0, cast(LPARAM)fmt);
			}
			else
			{
				SendMessageW(handle, 0x1032, 0, cast(LPARAM)null);
			}
		}
	}

	/// ditto
	DateTimePickerFormat format() const // getter
	{
		return _format;
	}


	///
	void customFormat(string formatString) // setter
	{
		_customFormatString = formatString;

		if (isHandleCreated && _format == DateTimePickerFormat.CUSTOM)
		{
			// DTM_SETFORMATW in core.sys.windows.commctrl is broken.
			// The couse is MinGW's one is broken too.
			// DTM_SETFORMATW is 0x1032 (0x1000 + 50), but not 0x1050.
			auto fmt = toUnicodez(_customFormatString);
			SendMessageW(handle, 0x1032, 0, cast(LPARAM)fmt);
		}
	}

	/// ditto
	string customFormat() const // getter
	{
		return _customFormatString;
	}


	///
	void dateMax(DateTime datetime) // setter
	{
		if (datetime < _dateMin)
			throw new DflException("dateMax failure.");
		
		_dateMax = datetime;

		if (isHandleCreated)
		{
			_settingValue = true;

			SYSTEMTIME[2] systime;
			DWORD flags = DateTime_GetRange(cast(HWND)_hwnd, systime.ptr);
			systime[1] = toSYSTEMTIME(datetime);
			if (!DateTime_SetRange(cast(HWND)_hwnd, flags | GDTR_MAX, systime.ptr))
				throw new DflException("dateMax failure.");
		}
	}

	/// ditto
	DateTime dateMax() const // getter
	{
		// SYSTEMTIME[2] systime;
		// DWORD flags = DateTime_GetRange(cast(HWND)_hwnd, systime.ptr);
		// if (flags & GDTR_MAX)
		// 	return toDateTime(systime[1]);
		// else
		// 	return DateTime.max;
		return _dateMax;
	}


	///
	void dateMin(DateTime datetime) // setter
	{
		if (datetime > _dateMax)
			throw new DflException("dateMin failure.");
		
		_dateMin = datetime;
	
		if (isHandleCreated)
		{
			_settingValue = true;
			
			SYSTEMTIME[2] systime;
			DWORD flags = DateTime_GetRange(cast(HWND)_hwnd, systime.ptr);
			systime[0] = toSYSTEMTIME(datetime);
			if (!DateTime_SetRange(cast(HWND)_hwnd, GDTR_MIN | flags, systime.ptr))
				throw new DflException("dateMin failure.");
		}
	}

	/// ditto
	DateTime dateMin() const // getter
	{
		// SYSTEMTIME[2] systime;
		// DWORD flags = DateTime_GetRange(cast(HWND)_hwnd, systime.ptr);
		// if (flags & GDTR_MIN)
		// 	return toDateTime(systime[0]);
		// else
		// 	return DateTime.min;
		return _dateMin;
	}


	///
	void showCheckBox(bool byes) // setter
	{
		_showCheckBox = byes;
		if (isHandleCreated && !recreatingHandle)
			recreateHandle();
	}

	/// ditto
	bool showCheckBox() const // getter
	{
		// return (_style & DTS_SHOWNONE) != 0;
		return _showCheckBox;
	}


	///
	void showUpDown(bool byes) // setter
	{
		_showUpDown = byes;
		if (isHandleCreated && !recreatingHandle)
			recreateHandle();
	}

	/// ditto
	bool showUpDown() const // getter
	{
		// return (_style & DTS_UPDOWN) != 0;
		return _showUpDown;
	}


	///
	void checked(bool byes)
	{
		if (!_showCheckBox)
			byes = true;
		
		_checked = byes;

		if (isHandleCreated)
		{
			if (byes)
			{
				SYSTEMTIME st = toSYSTEMTIME(_value);
				DateTime_SetSystemtime(_hwnd, GDT_VALID, &st);
			}
			else
			{
				DateTime_SetSystemtime(_hwnd, GDT_NONE, null);
			}
		}
	}

	/// ditto
	bool checked() const
	{
		if (_showCheckBox)
			return _checked;
		else
			return true;
	}


	///
	void onValueChanged(EventArgs ea)
	{
		valueChanged(this, ea);
	}


	///
	Event!(DateTimePicker, EventArgs) valueChanged;


private:


	DateTime _value;
	DateTimePickerFormat _format = DateTimePickerFormat.LONG;
	string _customFormatString;
	DateTime _dateMax = DateTime(9999, 12, 31);
	DateTime _dateMin = DateTime(1601, 1, 1);
	bool _showCheckBox;
	bool _showUpDown;
	bool _checked;

	bool _settingValue;


protected:


	/+
	///
	override void onHandleCreated(EventArgs ea)
	{
		super.onHandleCreated(ea);

		if (!isHandleCreated) return;
	}
	+/
	

	///
	override void createParams(ref CreateParams cp)
	{
		super.createParams(cp);
		
		cp.className = DATETIMEPICKER_CLASSNAME;

		final switch (_format)
		{
		case DateTimePickerFormat.LONG:
			cp.style = (cp.style & ~DTS_FORMAT_MASK) | DTS_LONGDATEFORMAT;
			break;
		case DateTimePickerFormat.SHORT:
			cp.style = (cp.style & ~DTS_FORMAT_MASK) | DTS_SHORTDATECENTURYFORMAT;
			break;
		case DateTimePickerFormat.TIME:
			cp.style = (cp.style & ~DTS_FORMAT_MASK) | DTS_TIMEFORMAT;
			break;
		case DateTimePickerFormat.CUSTOM:
			// Win32 requires one base format.
			cp.style = (cp.style & ~DTS_FORMAT_MASK) | DTS_SHORTDATECENTURYFORMAT;
		}

		if (_showUpDown)
			cp.style = cp.style | DTS_UPDOWN;
		else
			cp.style = cp.style & ~DTS_UPDOWN;

		if (_showCheckBox)
			cp.style = cp.style | DTS_SHOWNONE;
		else
			cp.style = cp.style & ~DTS_SHOWNONE;

	}


	override void recreateHandle()
	{
		Size tmpSize = size;

		super.recreateHandle();

		showCheckBox = _showCheckBox;
		showUpDown = _showUpDown;
		dateMin = _dateMin;
		dateMax = _dateMax;
		value = _value;
		checked = _checked;
		format = _format;
		customFormat = _customFormatString;

		size = tmpSize;
	}


	override @property Size defaultSize() const // getter
	{
		if (isHandleCreated)
		{
			SIZE size;
			SendMessage(cast(HWND)_hwnd, DTM_GETIDEALSIZE, 0, cast(LPARAM)&size);
			return Size(&size);
		}
		else
		{
			return Size(200, 21);
		}
	}


	override void onReflectedMessage(ref Message msg)
	{
		switch (msg.msg)
		{
			case WM_NOTIFY:
			{
				auto nm = cast(NMHDR*)msg.lParam;

				if (nm.code == DTN_DATETIMECHANGE)
				{
					auto info = cast(NMDATETIMECHANGE*)msg.lParam;

					if (info.dwFlags == GDT_VALID)
					{
						_value = toDateTime(info.st);
						_checked = true;

						if (!_settingValue)
							onValueChanged(new EventArgs);
					}
					else
					{
						_checked = false;
					}

					_settingValue = false;

					msg.result = 0;
				}
				return;
			}
			default:
				super.onReflectedMessage(msg);
		}
	}


	///
	override void wndProc(ref Message msg)
	{
		switch (msg.msg)
		{
			// Fix for Win32 bug.
			case WM_SETFONT:
			case WM_THEMECHANGED:
			case WM_SETTINGCHANGE:
			{
				super.wndProc(msg);
				if (_format == DateTimePickerFormat.CUSTOM)
				{
					if (!isHandleCreated) return;
					auto fmt = toUnicodez(_customFormatString);
					// DTM_SETFORMATW in core.sys.windows.commctrl is broken.
					// The couse is MinGW's one is broken too.
					// DTM_SETFORMATW is 0x1032 (0x1000 + 50), but not 0x1050.
					SendMessageW(handle, 0x1032, 0, cast(LPARAM)fmt);
				}
				return;
			}
			default:
				super.wndProc(msg);
		}
	}


	///
	override void prevWndProc(ref Message msg)
	{
		msg.result = dfl.internal.utf.callWindowProc(datetimepickerPrevWndProc, msg.hWnd, msg.msg, msg.wParam, msg.lParam);
	}
	
	
	///
	final LRESULT prevwproc(UINT msg, WPARAM wparam, LPARAM lparam)
	{
		return dfl.internal.utf.callWindowProc(datetimepickerPrevWndProc, _hwnd, msg, wparam, lparam);
	}
}
