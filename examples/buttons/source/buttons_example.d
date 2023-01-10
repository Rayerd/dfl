import dfl;

version(Have_dfl) // For DUB.
{
}
else
{
	pragma(lib, "dfl.lib");
}

class MainForm : Form
{
	private Button _okButton;
	private Button _cancelButton;

	private RadioButton _radioButton1;
	private RadioButton _radioButton2;
	private RadioButton _radioButton3;
	private GroupBox _groupbox1;

	private RadioButton _radioButton4;
	private RadioButton _radioButton5;
	private RadioButton _radioButton6;
	private GroupBox _groupbox2;
	
	private CheckBox _checkbox1;
	private CheckBox _checkbox2;
	private CheckBox _checkbox3;

	private RadioButton getSelectedRadioButton(RadioButton[] arr)
	{
		foreach (elem; arr)
		{
			if (elem.checked)
			{
				return elem;
			}
		}
		return null;
	}

	public this()
	{
		// Form setting
		this.text = "Buttons example";
		this.size = Size(400,300);
		this.formBorderStyle = FormBorderStyle.FIXED_DIALOG;
		this.maximizeBox = false;
		
		// Default button
		_okButton = new Button();
		_okButton.location = Point(10,10);
		_okButton.text = "Done";
		_okButton.click ~= (Control c, EventArgs e)
		{
			string s;

			RadioButton r1 = getSelectedRadioButton([_radioButton1, _radioButton2, _radioButton3]);
			if (r1)
				s ~= _groupbox1.text ~ " = " ~ r1.text ~ "\n";

			RadioButton r2 = getSelectedRadioButton([_radioButton4, _radioButton5, _radioButton6]);
			if (r2)
				s ~= _groupbox2.text ~ " = " ~ r2.text ~ "\n";

			s ~= _checkbox1.text ~ " = " ~ (_checkbox1.checked ? "CHECKED" : "") ~ "\n";
			s ~= _checkbox2.text ~ " = " ~ (_checkbox2.checked ? "CHECKED" : "") ~ "\n";
			s ~= _checkbox3.text ~ " = " ~ (_checkbox3.checked ? "CHECKED" : "") ~ "\n";

			msgBox(s);
		};
		_okButton.parent = this;

		// Cancel button
		_cancelButton = new Button();
		_cancelButton.location = Point(100,10);
		_cancelButton.text = "Cancel";
		_cancelButton.click ~= (Control c, EventArgs e)
		{
			msgBox("Close this application.");
			Application.exit();
		};
		_cancelButton.parent = this;
		
		this.acceptButton = _okButton; // pushed by ENTER
		this.cancelButton = _cancelButton; // pushed by ESC

		// First group
		_groupbox1 = new GroupBox();
		_groupbox1.location = Point(10, 60);
		_groupbox1.size = Size(90, 150);
		_groupbox1.text = "Color";
		_groupbox1.parent = this;

		// Default radio button in first group
		_radioButton1 = new RadioButton();
		_radioButton1.location = Point(10, 40+30*0);
		_radioButton1.text = "Red";
		_radioButton1.checked = true; // Default
		_radioButton1.parent = _groupbox1;

		_radioButton2 = new RadioButton();
		_radioButton2.location = Point(10, 40+30*1);
		_radioButton2.text = "Yellow";
		_radioButton2.parent = _groupbox1;

		_radioButton3 = new RadioButton();
		_radioButton3.location = Point(10, 40+30*2);
		_radioButton3.text = "Green";
		_radioButton3.enabled = false;
		_radioButton3.parent = _groupbox1;

		// Second group
		_groupbox2 = new GroupBox();
		_groupbox2.location = Point(110, 60);
		_groupbox2.size = Size(90, 150);
		_groupbox2.text = "Fruits";
		_groupbox2.parent = this;

		// Default radio button in second group
		_radioButton4 = new RadioButton();
		_radioButton4.location = Point(10, 40+30*0);
		_radioButton4.text = "Apple";
		_radioButton4.checked = true; // Default
		_radioButton4.parent = _groupbox2;

		_radioButton5 = new RadioButton();
		_radioButton5.location = Point(10, 40+30*1);
		_radioButton5.text = "Banana";
		_radioButton5.parent = _groupbox2;

		_radioButton6 = new RadioButton();
		_radioButton6.location = Point(10, 40+30*2);
		_radioButton6.text = "Melon";
		_radioButton6.parent = _groupbox2;

		// CheckBox
		_checkbox1 = new CheckBox();
		_checkbox1.location = Point(250, 100);
		_checkbox1.text = "Kyoto";
		_checkbox1.parent = this;

		_checkbox2 = new CheckBox();
		_checkbox2.location = Point(250, 100+30*1);
		_checkbox2.text = "Tokyo";
		_checkbox2.parent = this;

		_checkbox3 = new CheckBox();
		_checkbox3.location = Point(250, 100+30*2);
		_checkbox3.text = "Osaka";
		_checkbox3.parent = this;
	}
}

void main()
{
	Application.enableVisualStyles();
	Application.run(new MainForm());
}
