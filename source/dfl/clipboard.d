// Written by Christopher E. Miller
// See the included license.txt for copyright and license details.


/// Interfacing with the system clipboard for copy and paste operations.
module dfl.clipboard;

private import dfl.base;
private import dfl.data;
private import dfl.drawing;

private import dfl.internal.dlib;
private import dfl.internal.winapi;
private import dfl.internal.wincom;


///
class Clipboard // docmain
{
	private this() {}
	
	
static:

	/// Returns a data object that represents the entire contents of the Clipboard.
	dfl.data.IDataObject getDataObject()
	{
		dfl.internal.wincom.IDataObject comdobj;
		if(S_OK != OleGetClipboard(&comdobj))
			throw new DflException("Unable to obtain clipboard data object");
		if(comdobj is _comd)
			return _dd;
		_comd = comdobj;
		return _dd = new ComToDdataObject(comdobj);
	}
	
	/// Places a specified data object on the system Clipboard and accepts a Boolean parameter
	/// that indicates whether the data object should be left on the Clipboard
	/// when the application exits.
	void setDataObject(Data obj, bool persist = false)
	{
		// First, clears data on clipboard.
		if(S_OK != OleSetClipboard(null))
			goto err_set;
		
		_comd = null;
		_dd = null;
		_objref = null;
		
		if(obj.info)
		{
			if(cast(TypeInfo_Class)obj.info)
			{
				Object foo;
				foo = obj.getObject();
				
				if(obj.info == typeid(Bitmap))
				{
					DataObject bar = new DataObject;
					_dd = bar;
					_objref = bar;
					_dd.setData(DataFormats.bitmap, obj);
				}
				else if(cast(dfl.data.IDataObject)foo)
				{
					_dd = cast(dfl.data.IDataObject)foo;
					_objref = foo;
				}
				else
				{
					// Can't set any old class object.
					throw new DflException("Unknown data object");
				}
			}
			else if(obj.info == typeid(dfl.data.IDataObject))
			{
				_dd = obj.getIDataObject();
				_objref = cast(Object)_dd;
			}
			else if(cast(TypeInfo_Interface)obj.info)
			{
				// Can't set any old interface.
				throw new DflException("Unknown data object");
			}
			else
			{
				DataObject foo = new DataObject;
				_dd = foo;
				_objref = foo;
				_dd.setData(obj); // Same as _dd.setData(DataFormats.getFormat(obj.info).name, obj);
			}
			
			assert(_dd !is null);
			_comd = new DtoComDataObject(_dd);
			if(S_OK != OleSetClipboard(_comd))
			{
				_comd = null;
				//delete dd;
				_dd = null;
				goto err_set;
			}
			
			if(persist)
				OleFlushClipboard();
		}
		else
		{
			_dd = null;
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
		setDataObject(new Data(obj), persist);
	}
	

	/// Retrieves data in a specified format from the Clipboard.
	Data getData(Dstring fmt)
	{
		dfl.data.IDataObject ido = getDataObject();
		Dstring normalizedFormatName = DataFormats.getFormat(fmt).name;
		if (ido.getDataPresent(normalizedFormatName))
			return ido.getData(normalizedFormatName);
		return null;
	}

	/// Stores the specified data on the Clipboard in the specified format.
	void setData(Dstring fmt, Data obj)
	{
		dfl.data.IDataObject dataObj = new DataObject;
		Dstring normalizedFormatName = DataFormats.getFormat(fmt).name;
		dataObj.setData(normalizedFormatName, obj);

		// TODO: Why do not work to call setDataObject()?
		if(S_OK != OleSetClipboard(new DtoComDataObject(dataObj)))
			throw new DflException("OleSetClipboard failure");
	}

	/// Queries the Clipboard for the presence of data in a specified data format.
	bool containsData(Dstring fmt)
	{
		dfl.data.IDataObject ido = getDataObject();
		Dstring normalizedFormatName = DataFormats.getFormat(fmt).name;
		return ido.getDataPresent(normalizedFormatName);
	}

	
	/// Stores UTF-8 text data on the Clipboard.
	void setString(Dstring str, bool persist = false)
	{
		setDataObject(new Data(str), persist);
	}
	
	/// Returns a string containing the UTF-8 text data on the Clipboard.
	Dstring getString()
	{
		dfl.data.IDataObject ido = getDataObject();
		if(ido.getDataPresent(DataFormats.utf8))
			return ido.getData(DataFormats.utf8).getString();
		return null;
	}
	
	/// Queries the Clipboard for the presence of data in the UTF-8 text format.
	bool containsString()
	{
		dfl.data.IDataObject ido = getDataObject();
		return ido.getDataPresent(DataFormats.stringFormat);
	}

	
	/// Stores UnicodeText data on the Clipboard.
	// Unicode text.
	void setUnicodeText(Dwstring unicodeText, bool persist = false)
	{
		setDataObject(new Data(unicodeText), persist);
	}
	
	/// Returns a string containing the UnicodeText data on the Clipboard.
	Dwstring getUnicodeText()
	{
		dfl.data.IDataObject ido = getDataObject();
		if(ido.getDataPresent(DataFormats.unicodeText))
			return ido.getData(DataFormats.unicodeText).getUnicodeText();
		return null;
	}

	///  Queries the Clipboard for the presence of data in the UnicodeText format.
	bool containsUnicodeText()
	{
		dfl.data.IDataObject ido = getDataObject();
		return ido.getDataPresent(DataFormats.unicodeText);
	}


	/// Stores (Ansi)Text data on the Clipboard.
	// ANSI text.
	void setText(ubyte[] ansiText, bool persist = false)
	{
		setDataObject(new Data(ansiText), persist);
	}
	
	/// Returns a string containing the (Ansi)Text data on the Clipboard.
	ubyte[] getText()
	{
		dfl.data.IDataObject ido = getDataObject();
		if(ido.getDataPresent(DataFormats.text))
			return ido.getData(DataFormats.text).getText();
		return null;
	}
	
	/// Queries the Clipboard for the presence of data in the (Ansi)Text format.
	bool containsText()
	{
		dfl.data.IDataObject ido = getDataObject();
		return ido.getDataPresent(DataFormats.text);
	}

	
	/// Stores FileDrop data on the Clipboard. The dropped file list is specified as a string collection.
	void setFileDropList(string[] fileDropList, bool persist = false)
	{
		setDataObject(new Data(fileDropList), persist);
	}
	
	/// Returns a string collection that contains a list of dropped files available on the Clipboard.
	string[] getFileDropList()
	{
		dfl.data.IDataObject ido = getDataObject();
		if(ido.getDataPresent(DataFormats.fileDrop))
			return ido.getData(DataFormats.fileDrop).getStrings();
		return null;
	}
	
	/// Queries the Clipboard for the presence of data in the FileDrop data format.
	bool containsFileDropList()
	{
		dfl.data.IDataObject ido = getDataObject();
		return ido.getDataPresent(DataFormats.fileDrop);
	}
	
	
	/// Stores Bitmap data on the Clipboard.
	void setImage(Image image, bool persist = false)
	{
		setDataObject(new Data(image), persist);
	}
	
	/// Returns a Image object from the Clipboard that contains data in the Bitmap format.
	Image getImage()
	{
		dfl.data.IDataObject ido = getDataObject();
		if(ido.getDataPresent(DataFormats.bitmap))
			return ido.getData(DataFormats.bitmap).getImage();
		return null;
	}
	
	/// Queries the Clipboard for the presence of data in the Bitmap data format.
	bool containsImage()
	{
		dfl.data.IDataObject ido = getDataObject();
		return ido.getDataPresent(DataFormats.bitmap);
	}


	/// Clears any data from the system Clipboard.
	void clear()
	{
		if (S_OK != OleSetClipboard(null))
			throw new DflException("Unable to clear clipboard data");
		
		_comd = null;
		_dd = null;
		_objref = null;
	}
	
	
	/// Permanently adds the data that is on the Clipboard
	/// so that it is available after the data's original application closes.
	void flush()
	{
		if (S_OK != OleFlushClipboard())
			throw new DflException("Unable to flush clipboard data");
	}
	
	
private:
	dfl.internal.wincom.IDataObject _comd;
	dfl.data.IDataObject _dd;
	Object _objref; // Prevent dd from being garbage collected!
}
