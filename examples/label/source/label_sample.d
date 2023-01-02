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
   Form myForm;
   Label myLabel;
   
   myForm = new Form;
   myForm.text = "DFL Example";
   
   myLabel = new Label;
   myLabel.font = new Font("Verdana", 14f);
   myLabel.text = "Hello, DFL World!";
   myLabel.location = Point(15, 15);
   myLabel.autoSize = true;
   myLabel.parent = myForm;
   
   Application.run(myForm);
   
   return 0;
}
