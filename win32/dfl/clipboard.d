// Written by Christopher E. Miller
// See the included license.txt for copyright and license details.


/// Interfacing with the system clipboard for copy and paste operations.
module dfl.clipboard;

private import dfl.base, dfl.internal.winapi, dfl.data, dfl.internal.wincom,
	dfl.internal.dlib;


///
class Clipboard // docmain
{
	private this() {}
	
	
	static:
	
	///
	dfl.data.IDataObject getDataObject()
	{
		dfl.internal.wincom.IDataObject comdobj;
		if(S_OK != OleGetClipboard(&comdobj))
			throw new DflException("Unable to obtain clipboard data object");
		if(comdobj is comd)
			return dd;
		//delete dd;
		comd = comdobj;
		return dd = new ComToDdataObject(comdobj);
	}
	
	/// ditto
	void setDataObject(Data obj, bool persist = false)
	{
		comd = null;
		/+
		Object ddd;
		ddd = cast(Object)dd;
		delete ddd;
		+/
		dd = null;
		objref = null;
		
		if(obj.info)
		{
			if(cast(TypeInfo_Class)obj.info)
			{
				Object foo;
				foo = obj.getObject();
				
				/+
				if(cast(Bitmap)foo)
				{
					// ...
				}
				else +/ if(cast(dfl.data.IDataObject)foo)
				{
					dd = cast(dfl.data.IDataObject)foo;
					objref = foo;
				}
				else
				{
					// Can't set any old class object.
					throw new DflException("Unknown data object");
				}
			}
			else if(obj.info == typeid(dfl.data.IDataObject))
			{
				dd = obj.getValue!(dfl.data.IDataObject)();
				objref = cast(Object)dd;
			}
			else if(cast(TypeInfo_Interface)obj.info)
			{
				// Can't set any old interface.
				throw new DflException("Unknown data object");
			}
			else
			{
				DataObject foo = new DataObject;
				dd = foo;
				objref = foo;
				dd.setData(obj);
			}
			
			assert(!(dd is null));
			comd = new DtoComDataObject(dd);
			if(S_OK != OleSetClipboard(comd))
			{
				comd = null;
				//delete dd;
				dd = null;
				goto err_set;
			}
			
			if(persist)
				OleFlushClipboard();
		}
		else
		{
			dd = null;
			if(S_OK != OleSetClipboard(null))
				goto err_set;
		}
		
		return;
		err_set:
		throw new DflException("Unable to set clipboard data");
	}
	
	/// ditto
	void setDataObject(dfl.data.IDataObject obj, bool persist = false)
	{
		setDataObject(Data(obj), persist);
	}
	
	
	///
	void setString(Dstring str, bool persist = false)
	{
		setDataObject(Data(str), persist);
	}
	
	/// ditto
	Dstring getString()
	{
		dfl.data.IDataObject ido;
		ido = getDataObject();
		if(ido.getDataPresent(DataFormats.utf8))
			return ido.getData(DataFormats.utf8).getString();
		return null; // ?
	}
	
	
	///
	// ANSI text.
	void setText(ubyte[] ansiText, bool persist = false)
	{
		setDataObject(Data(ansiText), persist);
	}
	
	/// ditto
	ubyte[] getText()
	{
		dfl.data.IDataObject ido;
		ido = getDataObject();
		if(ido.getDataPresent(DataFormats.text))
			return ido.getData(DataFormats.text).getText();
		return null; // ?
	}
	
	
	private:
	dfl.internal.wincom.IDataObject comd;
	dfl.data.IDataObject dd;
	Object objref; // Prevent dd from being garbage collected!
	
	
	/+
	static ~this()
	{
		Object ddd;
		ddd = cast(Object)dd;
		delete ddd;
	}
	+/
}

