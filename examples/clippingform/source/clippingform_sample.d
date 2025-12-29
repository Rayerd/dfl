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
		this.clipping = new Bitmap(r".\image\clipping.bmp"); // Point(0, 0)'s color (white) is used as transparent.
		this.keyDown ~= (Control c, KeyEventArgs e) {
			// Press ESC to terminate.
			if (!(e.keyData & ~Keys.ESCAPE))
				this.close();
		};
	}

	override void wndProc(ref Message msg)
	{
		import core.sys.windows.winuser;
		switch(msg.msg)
		{
			case WM_NCHITTEST:
			{
				msg.result = HTCAPTION; // Makes all area to title bar.
				return;
			}
			default:
		}
		super.wndProc(msg);
	}
}

void main()
{
	Application.enableVisualStyles();
	Application.setHighDpiMode(HighDpiMode.PER_MONITOR_V2);
	Application.run(new MainForm());
}
