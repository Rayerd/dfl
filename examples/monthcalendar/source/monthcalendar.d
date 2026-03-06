import dfl;

import core.sys.windows.commctrl;
import core.sys.windows.winbase;
import core.sys.windows.windef;
import core.sys.windows.winuser;

import std.conv;
import std.datetime;

class MainForm : Form
{
	MonthCalendar _cal;
	
	this()
	{
		this.text = "MonthCalendar";
		this.size = Size(400, 400);

		_cal = new MonthCalendar();
		_cal.parent = this;
		// _cal.dock = DockStyle.FILL;
		_cal.dateChanged ~= (MonthCalendar c, DateRangeEventArgs args) {
			text = "Date changed: " ~ args.start.toISOExtString ~ " - " ~ args.end.toISOExtString;
		};
		_cal.dateSelected ~= (MonthCalendar c, DateRangeEventArgs args) {
			text = "Date selected: " ~ args.start.toISOExtString ~ " - " ~ args.end.toISOExtString;
		};
		_cal.mouseDown ~= (Control c, MouseEventArgs e) {

			enum mode = 2;

			switch (mode)
			{
			case 0:
				text = _cal.calendarDimensions.to!string;
				break;
			case 1:
				DayOfWeek dow = _cal.firstDayOfWeek;
				text = dow.to!string;
				break;
			case 2:
				DateTime minRange = _cal.minDate;
				DateTime maxRange = _cal.maxDate;
				text = minRange.toISOExtString ~ " - " ~ maxRange.toISOExtString;
				break;
			case 3:
				uint count = _cal.maxSelectionCount();
				text = count.to!string;
				break;
			case 4:
				POINT pt;
				GetCursorPos(&pt);
				ScreenToClient(handle, &pt);
				const HitTestInfo hi = _cal.hitTest(Point(&pt));
				text = hi.to!string;
				break;
			case 5:
				auto range = _cal.selectionRange();
				text = range.start.to!string ~ ", " ~ range.end.to!string;
				break;
			case 6:
				text = _cal.todayDate.to!string;
				break;
			case 7:
				_cal.calendarDimensions = Size(2, 2);
				text = _cal.calendarDimensions.to!string;
				break;
			default:
				const(SelectionRange) range = _cal.getDisplayRange(true);
				text = range.start.toISOExtString ~ ", " ~ range.end.toISOExtString;
			}

			_cal.showToday = true;
			_cal.showTodayCircle = true;
			_cal.showWeekNumbers = true;
			_cal.todayDateSet = false;
		};

		load ~= (Form f, EventArgs e) {
			_cal.firstDayOfWeek = DayOfWeek.mon;
			assert(_cal.firstDayOfWeek == DayOfWeek.mon);

			_cal.minDate(DateTime(2026, 4, 1));
			_cal.maxDate(DateTime(2026, 9, 1));

			_cal.setDate(DateTime(2026, 4, 1));

			_cal.selectionRange(new SelectionRange(DateTime(2026, 4, 10), DateTime(2026, 4, 12)));

			_cal.todayDate = DateTime(2026, 4, 3);

			_cal.maxSelectionCount = 3;
			_cal.scrollChange = 2;

			_cal.boldedDates = [
				DateTime(2026, 5, 1),
				DateTime(2026, 5, 2),
			];

			// _cal.removeAllBoldedDates();

			_cal.removeBoldedDate(DateTime(2026, 5, 1)); // Remove 2026-05-01.

			_cal.monthlyBoldedDates = [
				DateTime(2026, 4, 27),
				DateTime(2026, 4, 28),
			];

			// _cal.removeAllMonthlyBoldedDates();

			//It will remove 2026-04-28, but not the non-registered 2025-03-28.
			_cal.removeMonthlyBoldedDate(DateTime(2025, 3, 28));

			_cal.annuallyBoldedDates = [
				DateTime(2026, 6, 10),
				DateTime(2026, 6, 11),
			];

			// _cal.removeAllAnnuallyBoldedDates();

			// It will remove 2026-06-10, but not the non-registered 2025-06-10.
			_cal.removeAnnuallyBoldedDate(DateTime(2025, 6, 10));

			_cal.dateBold ~= (MonthCalendar m, DateBoldEventArgs e) {
				if (e.year == 2026 && e.month == 6 && e.day == 1)
				{
					e.isBold = true;
				}
			};
			_cal.annuallyDateBold ~= (MonthCalendar m, AnnuallyDateBoldEventArgs e) {
				if (e.month == 7 && e.day == 1)
				{
					e.isBold = true;
				}
			};

			_cal.backgroundColor(Color.white);

			// NOTE: Disabled in enableVisualStyles mode.
			// _cal.titleForeColor(Color.green);
			// _cal.titleBackColor(Color.yellow);
			// _cal.trailingForeColor(Color.blue);
			// _cal.monthColor(Color.purple);
		};
	}
}

void main()
{
	Application.enableVisualStyles();
	Application.setHighDpiMode(HighDpiMode.PER_MONITOR_V2);
	Application.run(new MainForm());
}
