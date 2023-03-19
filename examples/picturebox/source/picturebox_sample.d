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
	private PictureBox _pic1;
	private PictureBox _pic2;
	private PictureBox _pic3;
	private PictureBox _pic4;
	private PictureBox _pic5;

	public this()
	{
		this.text = "PictureBox example";
		this.size = Size(450, 450);

		_pic1 = new PictureBox;
		_pic2 = new PictureBox;
		_pic3 = new PictureBox;
		_pic4 = new PictureBox;
		_pic5 = new PictureBox;

		// Layout
		// 1 2 3
		// 4 5
		_pic1.location = Point(0, 0);
		_pic2.location = Point(110, 0);
		_pic3.location = Point(220, 0);
		_pic4.location = Point(0, 110);
		_pic5.location = Point(110, 110);

		_pic1.size = Size(100, 100);
		_pic2.size = Size(100, 100);
		_pic3.size = Size(200, 100); // wider than height
		_pic4.size = Size(100, 100);
		_pic5.size = Size(100, 100);

		_pic1.parent = this;
		_pic2.parent = this;
		_pic3.parent = this;
		_pic4.parent = this;
		_pic5.parent = this;

		_pic1.sizeMode = PictureBoxSizeMode.NORMAL;
		_pic2.sizeMode = PictureBoxSizeMode.STRETCH_IMAGE;
		_pic3.sizeMode = PictureBoxSizeMode.ZOOM;
		_pic4.sizeMode = PictureBoxSizeMode.CENTER_IMAGE;
		_pic5.sizeMode = PictureBoxSizeMode.AUTO_SIZE;

		_pic1.borderStyle = BorderStyle.FIXED_SINGLE;
		_pic2.borderStyle = BorderStyle.NONE;
		_pic3.borderStyle = BorderStyle.FIXED_SINGLE;
		_pic4.borderStyle = BorderStyle.FIXED_3D;
		_pic5.borderStyle = BorderStyle.FIXED_3D;

		// https://raw.githubusercontent.com/dlang/dlang.org/master/images/dman-error.jpg
		Image image = new Bitmap(r".\image\dman-error.bmp");

		_pic1.image = image;
		_pic2.image = image;
		_pic3.image = image;
		_pic4.image = image;
		_pic5.image = image;
	}
}

static this()
{
	Application.enableVisualStyles();
}

void main()
{
	Application.run(new MainForm());
}
