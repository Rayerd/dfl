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
	private Splitter _splitter1;
	private Splitter _splitter2;
	private Panel _panel1;
	private Panel _panel2;
	private Panel _panel3;

	this()
	{
		this.text = "Splitter example";
		this.size = Size(300, 300);

		_panel1 = new Panel();
		_panel1.dock = DockStyle.LEFT;
		_panel1.width = 100;
		_panel1.borderStyle = BorderStyle.FIXED_3D;
		_panel1.backColor = Color(255, 255, 255);
		_panel1.resize ~= (Control c, EventArgs e) {
			if (_panel1.width > 250)
			{
				_panel1.width = 250;
			}
		};
		_panel1.paint ~= (Control c, PaintEventArgs e) {
			Graphics g = e.graphics;
			string str = "min=25(default)\nmax=250";
			Font font = new Font("Meiryo UI", 10f);
			Color color = Color(0, 0, 0);
			Size size = g.measureText(str, font);
			g.drawText(str, font, color, Rect(0, 0, size.width, size.height));
		};
		_panel1.parent = this;

		_splitter1 = new Splitter();
		_splitter1.parent = this;

		_panel2 = new Panel();
		_panel2.dock = DockStyle.TOP;
		_panel2.height = 100;
		_panel2.borderStyle = BorderStyle.FIXED_3D;
		_panel2.backColor = Color(255, 255, 255);
		_panel2.resize ~= (Control c, EventArgs e) {
			if (_panel2.height > 120)
			{
				_panel2.height = 120;
			}
		};
		_panel2.paint ~= (Control c, PaintEventArgs e) {
			Graphics g = e.graphics;
			string str = "min=25(default)\nmax=120";
			Font font = new Font("Meiryo UI", 10f);
			Color color = Color(0, 0, 0);
			Size size = g.measureText(str, font);
			g.drawText(str, font, color, Rect(0, 0, size.width, size.height));
		};
		_panel2.parent = this;

		_splitter2 = new Splitter();
		_splitter2.dock = DockStyle.TOP;
		_splitter2.movingGrip = false;
		_splitter2.parent = this;

		_panel3 = new Panel();
		_panel3.dock = DockStyle.FILL;
		_panel3.borderStyle = BorderStyle.FIXED_3D;
		_panel3.backColor = Color(255, 255, 255);
		_panel3.parent = this;
	}
}

void main()
{
	Application.enableVisualStyles();
	Application.setHighDpiMode(HighDpiMode.PER_MONITOR_V2);
	Application.run(new MainForm());
}
