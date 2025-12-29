import dfl;

version(Have_dfl) // For DUB.
{
}
else
{
	pragma(lib, "dfl.lib");
}

int main()
{
	Application.enableVisualStyles();
	Application.setHighDpiMode(HighDpiMode.PER_MONITOR_V2);

	Form myForm;
	Label myLabel;

	myForm = new Form;
	myForm.text = "DFL Example";

	myLabel = new Label;
	myLabel.font = new Font("Verdana", 20f);
	myLabel.text = "Hello, DFL World!";
	myLabel.location = Point(15, 15);
	myLabel.autoSize = true;
	myLabel.parent = myForm;

	Application.run(myForm);

	return 0;
}
