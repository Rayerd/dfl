import dfl;

version(Have_dfl) // For DUB.
{
}
else
{
	pragma(lib, "dfl.lib");
}

class MainForm : ClippingForm
{
	public this()
	{
		this.text = "Clipping Form example";
		this.size = Size(300, 200);
		this.clipping = new Bitmap(r".\image\clipping.bmp"); // White is transparent.
		this.click ~= (Control c, EventArgs e) {
			this.close();
		};
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
