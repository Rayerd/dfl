module dfl.monthcalendar;

import dfl.application;
import dfl.base;
import dfl.control;
import dfl.drawing;
import dfl.event;

import dfl.internal.utf;
import dfl.internal.dpiaware;

import core.sys.windows.commctrl;
import core.sys.windows.winbase;
import core.sys.windows.windef;
import core.sys.windows.winuser;

import std.algorithm;
import std.array;
import std.datetime;


///
class MonthCalendar : ControlSuperClass
{
	///
	this()
	{
		_initMonthCalendar();
		
		// setStyle(ControlStyles.USER_PAINT, false);
		// setStyle(ControlStyles.USE_TEXT_FOR_ACCESSIBILITY, false);

		_windowStyle |= WS_BORDER | WS_CHILD | WS_VISIBLE | WS_TABSTOP
			| MCS_DAYSTATE
			| MCS_MULTISELECT
			// | MCS_WEEKNUMBERS
			// | MCS_NOTODAYCIRCLE
			// | MCS_NOTODAY
			| MCS_NOTRAILINGDATES
			| MCS_SHORTDAYSOFWEEK
			| MCS_NOSELCHANGEONNAV
		;

		_controlStyle |= ControlStyles.SELECTABLE;
		_windowClassStyle = monthcalendarClassStyle;
	}


	///
	void annuallyBoldedDates(const DateTime[] datetimes) // setter
	{
		_annuallyBoldedDates = datetimes.dup;
	}

	/// ditto
	const(DateTime[]) annuallyBoldedDates() const // getter
	{
		return _annuallyBoldedDates;
	}


	///
	void addAnnualluyBoldedDate(DateTime datetime)
	{
		_annuallyBoldedDates ~= datetime;
	}


	///
	void boldedDates(const DateTime[] datetimes) // setter
	{
		_boldedDates = datetimes.dup;
	}

	/// ditto
	const(DateTime[]) boldedDates() const // getter
	{
		return _boldedDates;
	}


	///
	void addBoldedDate(DateTime datetime)
	{
		_boldedDates ~= datetime;
	}


	///
	void calendarDimensions(Size dimensions) // setter
	{
		RECT oneCalSize;
		SendMessage(cast(HWND)_hwnd, MCM_SIZERECTTOMIN, 0, cast(LPARAM)&oneCalSize);
		// oneCalSize.right == cx
		// oneCalSize.bottom == cy
		assert(oneCalSize.left == 0);
		assert(oneCalSize.top == 0);

		RECT rect;
		rect.right = oneCalSize.right * dimensions.width;
		rect.bottom = oneCalSize.bottom * dimensions.height;
		SendMessage(cast(HWND)_hwnd, MCM_SIZERECTTOMIN, 0, cast(LPARAM)&rect);
		assert(rect.left == 0);
		assert(rect.top == 0);
		this.size = Size(
			MulDiv(rect.right - rect.left, USER_DEFAULT_SCREEN_DPI, dpi),
			MulDiv(rect.bottom - rect.top, USER_DEFAULT_SCREEN_DPI, dpi)
		);
	}

	/// ditto
	Size calendarDimensions() const // getter
	{
		Size sz = this.singleMonthSize();
		int col = MulDiv(width, dpi, USER_DEFAULT_SCREEN_DPI) / sz.width;
		int row = MulDiv(height, dpi, USER_DEFAULT_SCREEN_DPI) / sz.height;
		return Size(col, row);
	}

	/// ditto
	void setCalendarDimensions(int rows, int columns)
	{
		this.calendarDimensions = Size(rows, columns);
	}


	///
	protected override @property Size defaultSize() const // getter
	{
		return Size(200, 200);
	}


	///
	void firstDayOfWeek(DayOfWeek day) // setter
	{
		MonthCal_SetFirstDayOfWeek(cast(HWND)_hwnd, (day - 1) % 7);
	}

	/// ditto
	DayOfWeek firstDayOfWeek() const // getter
	{
		const int firstDay = LOWORD(MonthCal_GetFirstDayOfWeek(cast(HWND)_hwnd));
		final switch (firstDay)
		{
			case 0: return DayOfWeek.mon;
			case 1: return DayOfWeek.tue;
			case 2: return DayOfWeek.wed;
			case 3: return DayOfWeek.thu;
			case 4: return DayOfWeek.fri;
			case 5: return DayOfWeek.sat;
			case 6: return DayOfWeek.sun;
		}
	}


	///
	void maxDate(DateTime datetime) // setter
	{
		SYSTEMTIME[2] minMaxPair;
		DWORD flags = MonthCal_GetRange(cast(HWND)_hwnd, minMaxPair.ptr);
		flags |= GDTR_MAX;
		minMaxPair[1] = toSYSTEMTIME(datetime);
		MonthCal_SetRange(cast(HWND)_hwnd, flags, minMaxPair.ptr);
	}

	/// ditto
	DateTime maxDate() const // getter
	{
		SYSTEMTIME[2] minMaxPair;
		DWORD flags = MonthCal_GetRange(cast(HWND)_hwnd, minMaxPair.ptr);
		if (flags & GDTR_MAX)
			return toDateTime(minMaxPair[1]);
		else
			return DateTime.max;
	}


	///
	void minDate(DateTime datetime) // setter
	{
		SYSTEMTIME[2] minMaxPair;
		DWORD flags = MonthCal_GetRange(cast(HWND)_hwnd, minMaxPair.ptr);
		flags |= GDTR_MIN;
		minMaxPair[0] = toSYSTEMTIME(datetime);
		MonthCal_SetRange(cast(HWND)_hwnd, flags, minMaxPair.ptr);
	}

	/// ditto
	DateTime minDate() const // getter
	{
		SYSTEMTIME[2] minMaxPair;
		DWORD flags = MonthCal_GetRange(cast(HWND)_hwnd, minMaxPair.ptr);
		if (flags & GDTR_MIN)
			return toDateTime(minMaxPair[0]);
		else
			return DateTime.min;
	}


	///
	void maxSelectionCount(uint count) // setter
	{
		MonthCal_SetMaxSelCount(cast(HWND)_hwnd, count);
	}

	/// ditto
	int maxSelectionCount() const // getter
	{
		return MonthCal_GetMaxSelCount(cast(HWND)_hwnd);
	}
	

	///
	void monthlyBoldedDates(DateTime[] datetimes) // setter
	{
		_monthlyBoldedDates = datetimes.dup;
	}

	/// ditto
	const(DateTime[]) monthlyBoldedDates() const // getter
	{
		return _monthlyBoldedDates;
	}


	///
	void addMonthlyBoldedDate(DateTime datetime)
	{
		_monthlyBoldedDates ~= datetime;
	}


	///
	void scrollChange(int scroll) // setter
	{
		MonthCal_SetMonthDelta(cast(HWND)_hwnd, scroll);
	}

	/// ditto
	int scrollChange() const // getter
	{
		return MonthCal_GetMonthDelta(cast(HWND)_hwnd);
	}


	///
	void selectionEnd(DateTime datetime) // setter
	{
		DateTime start = this.selectionRange.start;
		this.selectionRange = new SelectionRange(start, datetime);
	}

	/// ditto
	DateTime selectionEnd() const // getter
	{
		return this.selectionRange.end;
	}


	///
	void selectionRange(const SelectionRange range) // setter
	{
		SYSTEMTIME[2] systimes;
		systimes[0] = toSYSTEMTIME(range.start);
		systimes[1] = toSYSTEMTIME(range.end);
		if (MonthCal_SetSelRange(cast(HWND)_hwnd, systimes.ptr) == 0)
			throw new DflException("DFL: selectionRange failure.");
	}

	/// ditto
	const(SelectionRange) selectionRange() const // getter
	{
		SYSTEMTIME[2] systimes;
		if (MonthCal_GetSelRange(cast(HWND)_hwnd, systimes.ptr) == 0)
			throw new DflException("DFL: selectionRange failure.");
		return new SelectionRange(toDateTime(systimes[0]), toDateTime(systimes[1]));
	}
	
	/// ditto
	void setSelectionRange(DateTime start, DateTime end)
	{
		this.selectionRange = new SelectionRange(start, end);
	}


	///
	void selectionStart(DateTime datetime) // setter
	{
		DateTime end = this.selectionRange.end;
		this.selectionRange = new SelectionRange(datetime, end);
	}

	/// ditto
	DateTime selectionStart() const // getter
	{
		return this.selectionRange.start;
	}


	///
	void showToday(bool show) // setter
	{
		if (show)
			_style = _style & ~MCS_NOTODAY;
		else
			_style = _style | MCS_NOTODAY;
	}

	/// ditto
	bool showToday() const // getter
	{
		return (_style & MCS_NOTODAY) == 0;
	}


	///
	void showTodayCircle(bool show) // setter
	{
		if (show)
			_style = _style & ~MCS_NOTODAYCIRCLE;
		else
			_style = _style | MCS_NOTODAYCIRCLE;
	}

	/// ditto
	bool showTodayCircle() const // getter
	{
		return (_style & MCS_NOTODAYCIRCLE) == 0;
	}


	///
	void showWeekNumbers(bool show) // setter
	{
		if (show)
			_style = _style | MCS_WEEKNUMBERS;
		else
			_style = _style & ~MCS_WEEKNUMBERS;
	}

	/// ditto
	bool showWeekNumbers() const // getter
	{
		return (_style & MCS_WEEKNUMBERS) != 0;
	}


	///
	Size singleMonthSize() const // getter
	{
		RECT singleCal;
		MonthCal_GetMinReqRect(cast(HWND)_hwnd, &singleCal);
		int singleW = singleCal.right - singleCal.left;
		int singleH = singleCal.bottom - singleCal.top;
		int w = MulDiv(singleW, USER_DEFAULT_SCREEN_DPI, dpi);
		int h = MulDiv(singleH, USER_DEFAULT_SCREEN_DPI, dpi);
		return Size(w, h);
	}


	///
	void titleBackColor(Color color) // setter
	{
		MonthCal_SetColor(cast(HWND)_hwnd, MCSC_TITLEBK, color.toRgb);
	}

	/// ditto
	Color titleBackColor() const // getter
	{
		return Color.fromRgb(MonthCal_GetColor(cast(HWND)_hwnd, MCSC_TITLEBK));
	}


	///
	void titleForeColor(Color color) // setter
	{
		MonthCal_SetColor(cast(HWND)_hwnd, MCSC_TITLETEXT, color.toRgb);
	}

	/// ditto
	Color titleForeColor() const // getter
	{
		return Color.fromRgb(MonthCal_GetColor(cast(HWND)_hwnd, MCSC_TITLETEXT));
	}


	///
	void backgroundColor(Color color) // setter
	{
		MonthCal_SetColor(cast(HWND)_hwnd, MCSC_BACKGROUND, color.toRgb);
	}

	/// ditto
	Color backgroundColor() const // getter
	{
		return Color.fromRgb(MonthCal_GetColor(cast(HWND)_hwnd, MCSC_BACKGROUND));
	}


	///
	void monthColor(Color color) // setter
	{
		MonthCal_SetColor(cast(HWND)_hwnd, MCSC_MONTHBK, color.toRgb);
	}

	/// ditto
	Color monthColor() const // getter
	{
		return Color.fromRgb(MonthCal_GetColor(cast(HWND)_hwnd, MCSC_MONTHBK));
	}


	///
	void todayDate(DateTime datetime) // setter
	{
		SYSTEMTIME systime = toSYSTEMTIME(datetime);
		MonthCal_SetToday(cast(HWND)_hwnd, &systime);
		_isTodayDateSet = true;
	}

	/// ditto
	DateTime todayDate() const // getter
	{
		SYSTEMTIME systime;
		MonthCal_GetToday(cast(HWND)_hwnd, &systime);
		return toDateTime(systime);
	}


	///
	void todayDateSet(bool set) // setter
	{
		_isTodayDateSet = set;
		if (!set)
			todayDate = cast(DateTime)Clock.currTime();
	}

	/// ditto
	bool todayDateSet() const // getter
	{
		return _isTodayDateSet;
	}


	///
	// visible == true   => GMR_VISIBLE
	// visible == false  => GMR_DAYSTATE
	const(SelectionRange) getDisplayRange(bool visible) const
	{
		SYSTEMTIME[2] range;
		MonthCal_GetMonthRange(cast(HWND)_hwnd, visible ? GMR_VISIBLE : GMR_DAYSTATE, range.ptr);
		return new SelectionRange(toDateTime(range[0]), toDateTime(range[1]));
	}


	///
	const(HitTestInfo) hitTest(int x, int y) const
	{
		MCHITTESTINFO hi;
		hi.cbSize = hi.sizeof;
		hi.pt = POINT(x, y);
		MonthCal_HitTest(cast(HWND) _hwnd, &hi);

		HitArea ha = HitArea.NOWHERE;
		if ((hi.uHit & MCHT_TODAYLINK) == MCHT_TODAYLINK)
		{
			ha = HitArea.TODAY_LINK;
		}
		else if (hi.uHit & MCHT_TITLE)
		{
			if ((hi.uHit & MCHT_TITLEBTNNEXT) == MCHT_TITLEBTNNEXT)
				ha = HitArea.NEXT_MONTH_BUTTON;
			else if ((hi.uHit & MCHT_TITLEBTNPREV) == MCHT_TITLEBTNPREV)
				ha = HitArea.PREV_MONTH_BUTTON;
			else if ((hi.uHit & MCHT_TITLEMONTH) == MCHT_TITLEMONTH)
				ha = HitArea.TITLE_MONTH;
			else if ((hi.uHit & MCHT_TITLEYEAR) == MCHT_TITLEYEAR)
				ha = HitArea.TITLE_YEAR;
			else
				ha = HitArea.TITLE_BACKGROUND;
		}
		else if (hi.uHit & MCHT_CALENDAR)
		{
			if ((hi.uHit & MCHT_CALENDARDATENEXT) == MCHT_CALENDARDATENEXT)
				ha = HitArea.NEXT_MONTH_DATE;
			else if ((hi.uHit & MCHT_CALENDARDATEPREV) == MCHT_CALENDARDATEPREV)
				ha = HitArea.PREV_MONTH_DATE;
			else if ((hi.uHit & MCHT_CALENDARDATE) == MCHT_CALENDARDATE)
				ha = HitArea.DATE;
			else if ((hi.uHit & MCHT_CALENDARDAY) == MCHT_CALENDARDAY)
				ha = HitArea.DAY_OF_WEEK;
			else if ((hi.uHit & MCHT_CALENDARWEEKNUM) == MCHT_CALENDARWEEKNUM)
				ha = HitArea.WEEK_NUMBERS;
			else
				ha = HitArea.CALENDAR_BACKGROUND;
		}
		return new HitTestInfo(ha, Point(hi.pt.x, hi.pt.y), toDateTime(hi.st));
	}

	/// ditto
	const(HitTestInfo) hitTest(Point point) const
	{
		return hitTest(point.x, point.y);
	}


	///
	void removeBoldedDate(DateTime datetime)
	{
		_boldedDates = _boldedDates.filter!(d => d != datetime).array;
	}

	///
	void removeAllBoldedDates()
	{
		_boldedDates = null;
	}


	///
	void removeAnnuallyBoldedDate(DateTime datetime)
	{
		_annuallyBoldedDates = _annuallyBoldedDates.filter!(d => (d.month != datetime.month || d.day != datetime.day)).array;
	}


	///
	void removeAllAnnuallyBoldedDates()
	{
		_annuallyBoldedDates = null;
	}


	///
	void removeMonthlyBoldedDate(DateTime datetime)
	{
		_monthlyBoldedDates = _monthlyBoldedDates.filter!(d => d.day != datetime.day).array;
	}


	///
	void removeAllMonthlyBoldedDates()
	{
		_monthlyBoldedDates = null;
	}


	///
	void setDate(DateTime date)
	{
		SYSTEMTIME systime = toSYSTEMTIME(date);
		MonthCal_SetCurSel(cast(HWND)_hwnd, &systime);
	}


	///
	// void updateBoldedDates()
	// {
	// 	// Do nothing.
	// }


	///
	void onDateChanged(DateRangeEventArgs args)
	{
		dateChanged(this, args);
	}


	///
	void onDateSelected(DateRangeEventArgs args)
	{
		dateSelected(this, args);
	}


	///
	void onDateBold(DateBoldEventArgs args)
	{
		dateBold(this, args);
	}


	///
	void onMonthlyDateBold(MonthlyDateBoldEventArgs args)
	{
		monthlyDateBold(this, args);
	}


	///
	void onAnnuallyDateBold(AnnuallyDateBoldEventArgs args)
	{
		annuallyDateBold(this, args);
	}


	///
	Event!(MonthCalendar, DateRangeEventArgs) dateSelected;
	Event!(MonthCalendar, DateRangeEventArgs) dateChanged;
	Event!(MonthCalendar, DateBoldEventArgs) dateBold;
	Event!(MonthCalendar, MonthlyDateBoldEventArgs) monthlyDateBold;
	Event!(MonthCalendar, AnnuallyDateBoldEventArgs) annuallyDateBold;


private:

	DateTime[] _boldedDates;
	DateTime[] _monthlyBoldedDates;
	DateTime[] _annuallyBoldedDates;

	bool _isTodayDateSet;


protected:

	///
	override void createParams(ref CreateParams cp)
	{
		super.createParams(cp);
		
		cp.className = MONTHCALENDAR_CLASSNAME;
	}


	///
	override void onHandleCreated(EventArgs ea)
	{
		super.onHandleCreated(ea);

		if (!isHandleCreated)
		{
			return;
		}
	}
	

	///
	override void onReflectedMessage(ref Message msg)
	{
		DateTime toDateTimeSafe(SYSTEMTIME time, SYSTEMTIME defaultTime = SYSTEMTIME.init) pure
		{
			if (time == SYSTEMTIME.init)
				return toDateTime(defaultTime);
			else
				return toDateTime(time);
		}

		switch (msg.msg)
		{
			case WM_NOTIFY:
			{
				NMHDR* hdr = cast(NMHDR*)msg.lParam;
				switch (hdr.code)
				{
					case MCN_SELCHANGE:
					{
						NMSELCHANGE* selChange = cast(NMSELCHANGE*)msg.lParam;
						DateTime start = toDateTimeSafe(selChange.stSelStart);
						DateTime end = toDateTimeSafe(selChange.stSelEnd, selChange.stSelStart);
						DateRangeEventArgs args = new DateRangeEventArgs(start, end);
						onDateChanged(args);
						return;
					}
					case MCN_SELECT:
					{
						NMSELCHANGE* selChange = cast(NMSELCHANGE*)msg.lParam;
						DateTime start = toDateTimeSafe(selChange.stSelStart);
						DateTime end = toDateTimeSafe(selChange.stSelEnd, selChange.stSelStart);
						DateRangeEventArgs args = new DateRangeEventArgs(start, end);
						onDateSelected(args);
						return;
					}
					case MCN_GETDAYSTATE:
					{
						static int getDaysInMonth(int year, int month) pure
						{
							assert(month >= 1 && month <= 12);

							immutable int[] days = [
								31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31
							];

							if (month == 2)
							{
								bool leap =
									((year % 4 == 0) && (year % 100 != 0)) ||
									(year % 400 == 0);

								return leap ? 29 : 28;
							}

							return days[month - 1];
						}

						// 2025/1/31 -> addMonth(+1) -> 2025/2/28
						// 2024/1/31 -> addMonth(+1) -> 2024/2/29
						static void addMonth(ref SYSTEMTIME st, int add) pure
						{
							int year = st.wYear;
							int month = st.wMonth;

							int m = month - 1 + add;

							year += m / 12;
							m %= 12;
							if (m < 0)
							{
								m += 12;
								year -= 1;
							}

							int newMonth = m + 1;

							int maxDay = getDaysInMonth(year, newMonth);
							int newDay = st.wDay;
							if (newDay > maxDay)
								newDay = maxDay;

							st.wYear = cast(ushort)year;
							st.wMonth = cast(ushort)newMonth;
							st.wDay = cast(ushort)newDay;
						}

						LPNMDAYSTATE dayState = cast(LPNMDAYSTATE)msg.lParam;

						foreach (i; 0 .. dayState.cDayState)
						{
							SYSTEMTIME firstDate = dayState.stStart;
							addMonth(firstDate, i);
							
							int days = getDaysInMonth(firstDate.wYear, firstDate.wMonth);
							
							MONTHDAYSTATE ds;

							foreach (d; 1 .. days +1)
							{
								SYSTEMTIME date = firstDate;
								date.wDay = cast(ushort)d;

								foreach (DateTime elem; _boldedDates)
								{
									auto ea = new DateBoldEventArgs(date.wYear, date.wMonth, date.wDay);
									onDateBold(ea);

									if (ea.isBold || (date.wYear == elem.year && date.wMonth == elem.month && date.wDay == elem.day))
									{
										ds |= (1 << (d -1));
									}
								}

								foreach (DateTime elem; _monthlyBoldedDates)
								{
									auto ea = new MonthlyDateBoldEventArgs(date.wDay);
									onMonthlyDateBold(ea);

									if (ea.isBold || date.wDay == elem.day)
									{
										ds |= (1 << (d -1));
									}
								}

								foreach (DateTime elem; _annuallyBoldedDates)
								{
									auto ea = new AnnuallyDateBoldEventArgs(date.wMonth, date.wDay);
									onAnnuallyDateBold(ea);

									if (ea.isBold || (date.wMonth == elem.month && date.wDay == elem.day))
									{
										ds |= (1 << (d -1));
									}
								}
							}

							dayState.prgDayState[i] = ds;
						}
						return;
					}
					case NM_RELEASEDCAPTURE:
					{
						return;
					}
					case MCN_VIEWCHANGE:
					{
						LPNMVIEWCHANGE* viewChange = cast(LPNMVIEWCHANGE*)msg.lParam;
						return;
					}
					default:
					{
						super.onReflectedMessage(msg);
						return;
					}
				}
			}
			default:
				super.onReflectedMessage(msg);
		}
	}


	///
	override void wndProc(ref Message msg)
	{
		super.wndProc(msg);
	}


	///
	override void prevWndProc(ref Message msg)
	{
		msg.result = dfl.internal.utf.callWindowProc(monthcalendarPrevWndProc, msg.hWnd, msg.msg, msg.wParam, msg.lParam);
	}
	
	
	///
	final LRESULT prevwproc(UINT msg, WPARAM wparam, LPARAM lparam)
	{
		return dfl.internal.utf.callWindowProc(monthcalendarPrevWndProc, _hwnd, msg, wparam, lparam);
	}
}


///
struct NMVIEWCHANGE
{
	NMHDR nmhdr;
	DWORD dwOldView;
	DWORD dwNewView;
}
alias LPNMVIEWCHANGE = NMVIEWCHANGE*;


///
enum MCN_VIEWCHANGE = MCN_FIRST - 4;


///
enum : int
{
	MCMV_MONTH = 0,
	MCMV_YEAR = 1,
	MCMV_DECADE = 2,
	MCMV_CENTURY = 3,
}


///
enum : int
{
	MCS_NOTRAILINGDATES = 0x0040,
	MCS_SHORTDAYSOFWEEK = 0x0080,
	MCS_NOSELCHANGEONNAV = 0x0100,
}


///
class DateRangeEventArgs : EventArgs
{
	///
	this(DateTime start, DateTime end)
	{
		this.start = start;
		this.end = end;
	}

	DateTime start; ///
	DateTime end; ///
}


///
class DateBoldEventArgs : EventArgs
{
	///
	this(uint year, uint month, uint day)
	{
		this.year = year;
		this.month = month;
		this.day = day;
	}

	uint year; ///
	uint month; ///
	uint day; ///

	bool isBold; ///
}


///
class MonthlyDateBoldEventArgs : EventArgs
{
	///
	this(uint day)
	{
		this.day = day;
	}

	uint day; ///

	bool isBold; ///
}


///
class AnnuallyDateBoldEventArgs : EventArgs
{
	///
	this(uint month, uint day)
	{
		this.month = month;
		this.day = day;
	}

	uint month; ///
	uint day; ///

	bool isBold; ///
}


///
final class SelectionRange
{
	///
	this(DateTime start, DateTime end)
	{
		this.start = start;
		this.end = end;
	}

	const DateTime start; ///
	const DateTime end; ///
}


///
final class HitTestInfo
{
	///
	this(HitArea hitArea, Point point, DateTime time)
	{
		this.hitArea = hitArea;
		this.point = point;
		this.time = time;
	}

	///
	override string toString() const
	{
		final switch (hitArea)
		{
		case HitArea.NOWHERE:
			return "NOWHERE";
		case HitArea.TITLE_BACKGROUND:
			return "TITLE_BACKGROUND";
		case HitArea.TITLE_YEAR:
			return "TITLE_YEAR";
		case HitArea.TITLE_MONTH:
			return "TITLE_MONTH";
		case HitArea.NEXT_MONTH_BUTTON:
			return "NEXT_MONTH_BUTTON";
		case HitArea.PREV_MONTH_BUTTON:
			return "PREV_MONTH_BUTTON";
		case HitArea.CALENDAR_BACKGROUND:
			return "CALENDAR_BACKGROUND";
		case HitArea.DATE:
			return "DATE";
		case HitArea.NEXT_MONTH_DATE:
			return "NEXT_MONTH_DATE";
		case HitArea.PREV_MONTH_DATE:
			return "PREV_MONTH_DATE";
		case HitArea.DAY_OF_WEEK:
			return "DAY_OF_WEEK";
		case HitArea.WEEK_NUMBERS:
			return "WEEK_NUMBERS";
		case HitArea.TODAY_LINK:
			return "TODAY_LINK";
		}
	}

	const HitArea hitArea; /// 
	const Point point; /// 
	const DateTime time; /// 
}


///
SYSTEMTIME toSYSTEMTIME(DateTime datetime) pure
{
	SYSTEMTIME systime;
	systime.wYear = datetime.year;
	systime.wMonth = datetime.month;
	systime.wDay = datetime.day;
	systime.wHour = datetime.hour;
	systime.wMinute = datetime.minute;
	systime.wSecond = datetime.second;
	return systime;
}


///
DateTime toDateTime(SYSTEMTIME systime) pure
{
	DateTime datetime;
	datetime.year = systime.wYear;
	datetime.month = cast(Month)systime.wMonth;
	datetime.day = systime.wDay;
	datetime.hour = systime.wHour;
	datetime.minute = systime.wMinute;
	datetime.second = systime.wSecond;
	return datetime;
}


///
enum HitArea : int
{
	NOWHERE = 0,
	TITLE_BACKGROUND = 1,
	TITLE_MONTH = 2,
	TITLE_YEAR = 3,
	NEXT_MONTH_BUTTON = 4,
	PREV_MONTH_BUTTON = 5,
	CALENDAR_BACKGROUND = 6,
	DATE = 7,
	NEXT_MONTH_DATE = 8,
	PREV_MONTH_DATE = 9,
	DAY_OF_WEEK = 10,
	WEEK_NUMBERS = 11,
	TODAY_LINK = 12,
}
