import dfl;

version (Have_dfl) // For DUB.
{
}
else
{
	pragma(lib, "dfl.lib");
}

class MainForm : Form
{
	private ToolBar _toolBar;
	private ToolBarButton _button1; // Normal button
	private ToolBarButton _button2; // Toggle button
	private ToolBarButton _button3; // Separator
	private ToolBarButton _button4; // Drop down button
	private ToolBarButton _button5; // Partial drop down button
	private ToolBarButton _button6; // Separator
	private ToolBarButton _button7; // Radio button group 1
	private ToolBarButton _button8; // Radio button group 1
	private ToolBarButton _button9; // Radio button group 1
	private ToolBarButton _button10; // Separtor
	private ToolBarButton _button11; // Radio button group 2
	private ImageList _imageList;

	public this()
	{
		this.text = "ToolBar example";
		this.size = Size(640, 100);

		_toolBar = new ToolBar;
		_toolBar.parent = this;
		
		_imageList = new ImageList;
		_imageList.images.addStrip(new Bitmap(r".\image\toolbaricon.bmp"));
		_toolBar.imageList = _imageList;

		_button1 = new ToolBarButton("Border");
		_button1.style = ToolBarButtonStyle.PUSH_BUTTON;
		_button1.imageIndex = 0;
		_toolBar.buttons.add(_button1);

		_button2 = new ToolBarButton("3D/Flat");
		_button2.style = ToolBarButtonStyle.TOGGLE_BUTTON;
		_button2.imageIndex = 1;
		_toolBar.buttons.add(_button2);

		_button3 = new ToolBarButton;
		_button3.style = ToolBarButtonStyle.SEPARATOR;
		// _button3.imageIndex = ... // Separators cannot have image.
		_toolBar.buttons.add(_button3);

		_button4 = new ToolBarButton("Drop down");
		_button4.style = ToolBarButtonStyle.DROP_DOWN_BUTTON;
		_button4.imageIndex = 2;
		ContextMenu button4_menu = new ContextMenu;
		MenuItem item1 = new MenuItem("Hop");
		MenuItem item2 = new MenuItem("Step");
		MenuItem item3 = new MenuItem("Jump");
		item1.click ~= (MenuItem mi, EventArgs e) {
			msgBox("Hop clicked.");
		};
		button4_menu.menuItems.add(item1);
		button4_menu.menuItems.add(item2);
		button4_menu.menuItems.add(item3);
		_button4.dropDownMenu = button4_menu;
		_toolBar.buttons.add(_button4);

		_button5 = new ToolBarButton("Partial DD");
		_button5.style = ToolBarButtonStyle.PARTIAL_DROP_DOWN_BUTTON; // Exteded Style
		_button5.imageIndex = 3;
		ContextMenu button5_menu = new ContextMenu;
		button5_menu.menuItems.add(new MenuItem("1"));
		button5_menu.menuItems.add(new MenuItem("2"));
		button5_menu.menuItems.add(new MenuItem("3"));
		_button5.dropDownMenu = button5_menu;
		_toolBar.buttons.add(_button5);

		_button6 = new ToolBarButton;
		_button6.style = ToolBarButtonStyle.SEPARATOR;
		// _button6.imageIndex = ... // Separators cannot have image.
		_toolBar.buttons.add(_button6);

		_button7 = new ToolBarButton("Large");
		_button7.style = ToolBarButtonStyle.RADIO_BUTTON; // Exteded Button Style
		_button7.imageIndex = 4;
		_toolBar.buttons.add(_button7);

		_button8 = new ToolBarButton("Middle");
		_button8.style = ToolBarButtonStyle.RADIO_BUTTON; // Exteded Button Style
		_button8.imageIndex = 5;
		_toolBar.buttons.add(_button8);

		_button9 = new ToolBarButton("Small");
		_button9.style = ToolBarButtonStyle.RADIO_BUTTON; // Exteded Button Style
		_button9.imageIndex = 6;
		_toolBar.buttons.add(_button9);

		// NOTE: Radio button group is separated by separator button.

		_button10 = new ToolBarButton;
		_button10.style = ToolBarButtonStyle.SEPARATOR;
		// _button10.imageIndex = ... // Separators cannot have image.
		_toolBar.buttons.add(_button10);

		_button11 = new ToolBarButton("Dummy");
		_button11.style = ToolBarButtonStyle.RADIO_BUTTON; // Exteded Button Style
		_button11.imageIndex = 7;
		_toolBar.buttons.add(_button11);

		_toolBar.buttonClick ~= (ToolBar tb, ToolBarButtonClickEventArgs e) {
			if (e.button is _button1)
			{
				final switch (tb.borderStyle)
				{
				case BorderStyle.NONE:
					tb.borderStyle = BorderStyle.FIXED_SINGLE;
					_button5.enabled = false;
					break;
				case BorderStyle.FIXED_SINGLE:
					tb.borderStyle = BorderStyle.FIXED_3D;
					_button5.enabled = true;
					break;
				case BorderStyle.FIXED_3D:
					tb.borderStyle = BorderStyle.NONE;
					break;
				}
			}
			else if (e.button is _button2)
			{
				if (e.button.pushed)
				{
					tb.appearance = ToolBarAppearance.FLAT;
					_button6.visible = false;
					_button7.visible = false; // NOTE: The pushed state of radio style button is cleared.
					_button8.visible = false; // diito
					_button9.visible = false; // diito
					tb.style = ToolBarStyle.LIST; // Extended ToolBar style
				}
				else
				{
					tb.appearance = ToolBarAppearance.NORMAL; // 3D
					_button6.visible = true;
					_button7.visible = true;
					_button8.visible = true;
					_button9.visible = true;
					tb.style = ToolBarStyle.NORMAL; // Extended ToolBar style
				}
			}
			else if (e.button is _button5)
			{
				msgBox("Clicked Partial DD");
			}
			else if (e.button is _button7)
			{
				msgBox("Clicked Large");
			}
			else if (e.button is _button9)
			{
				msgBox("Clicked Small");
			}
		};
	}
}

static this()
{
	// The ToolBar is always flat if the application is in visual styles.
	// Separators are visible only if the ToolBar is ToolBarAppearance.FLAT.

	// Application.enableVisualStyles();
}

void main()
{
	Application.run(new MainForm());
}
