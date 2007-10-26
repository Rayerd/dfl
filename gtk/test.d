import dfl.application, dfl.form, dfl.label;


int main()
{
	Form myForm;
	Label myLabel;
	
	myForm = new Form;
	myForm.text = "DFL GTK";
	
	myLabel = new Label;
	//myLabel.font = new Font("Verdana", 14f);
	myLabel.text = "Hello, DFL World!";
	//myLabel.location = Point(15, 15);
	//myLabel.autoSize = true;
	myLabel.parent = myForm;
	
	//fornow:
	//myForm.show();
	myLabel.show();
	
	Application.run(myForm);
	
	return 0;
}

