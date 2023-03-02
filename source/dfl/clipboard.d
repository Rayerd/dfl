// Written by Christopher E. Miller
// See the included license.txt for copyright and license details.


/// Interfacing with the system clipboard for copy and paste operations.
module dfl.clipboard;

private import dfl.base;
private import dfl.data;
private import dfl.drawing;

private import dfl.internal.dlib;
private import dfl.internal.wincom;


///
class Clipboard
{
	private this() {}
	
	
static:

	/// Returns a data object that represents the entire contents of the Clipboard.
	dfl.data.IDataObject getDataObject()
	{
		dfl.internal.wincom.IDataObject comDataObject;
		if(S_OK != OleGetClipboard(&comDataObject))
			throw new DflException("Unable to obtain clipboard data object");
		if(comDataObject is _comDataObject)
			return _dflDataObject;
		_comDataObject = comDataObject;
		return _dflDataObject = new ComToDdataObject(comDataObject);
	}
	
	/// Places a specified data object on the system Clipboard and accepts a Boolean parameter
	/// that indicates whether the data object should be left on the Clipboard
	/// when the application exits.
	void setDataObject(dfl.data.IDataObject dataObj, bool persist = false)
	{
		// First, clears data on clipboard.
		if(S_OK != OleSetClipboard(null))
			goto err_set;
		
		_dflDataObject = dataObj;
		_comDataObject = new DtoComDataObject(_dflDataObject);

		if(S_OK != OleSetClipboard(_comDataObject))
			goto err_set;
		
		if(persist)
			OleFlushClipboard();
		
		return;
	err_set:
		throw new DflException("Unable to set clipboard data");
	}


	/// Retrieves data in a specified format from the Clipboard.
	Data getData(Dstring fmt)
	{
		dfl.data.IDataObject dataObj = getDataObject();
		Dstring regsteredFormat = DataFormats.getFormat(fmt).name;
		if (dataObj.getDataPresent(regsteredFormat))
			return dataObj.getData(regsteredFormat);
		return null;
	}

	/// Stores the specified data on the Clipboard in the specified format.
	void setData(Dstring fmt, Data obj)
	{
		dfl.data.IDataObject dataObj = new DataObject;
		Dstring regsteredFormat = DataFormats.getFormat(fmt).name;
		dataObj.setData(regsteredFormat, obj);
		setDataObject(dataObj, true);
	}

	/// Queries the Clipboard for the presence of data in a specified data format.
	bool containsData(Dstring fmt)
	{
		dfl.data.IDataObject dataObj = getDataObject();
		Dstring regsteredFormat = DataFormats.getFormat(fmt).name;
		return dataObj.getDataPresent(regsteredFormat);
	}

	
	/// Stores UTF-8 text data on the Clipboard.
	void setString(Dstring str)
	{
		setData(DataFormats.stringFormat, new Data(str));
	}
	
	/// Returns a string containing the UTF-8 text data on the Clipboard.
	Dstring getString()
	{
		dfl.data.IDataObject dataObj = getDataObject();
		if(dataObj.getDataPresent(DataFormats.stringFormat))
			return dataObj.getData(DataFormats.stringFormat).getStringFormat();
		return null;
	}
	
	/// Queries the Clipboard for the presence of data in the UTF-8 text format.
	bool containsString()
	{
		dfl.data.IDataObject dataObj = getDataObject();
		return dataObj.getDataPresent(DataFormats.stringFormat);
	}

	
	/// Stores UnicodeText data on the Clipboard.
	// Unicode text.
	void setUnicodeText(Dwstring unicodeText)
	{
		setData(DataFormats.unicodeText, new Data(unicodeText));
	}
	
	/// Returns a string containing the UnicodeText data on the Clipboard.
	Dwstring getUnicodeText()
	{
		dfl.data.IDataObject dataObj = getDataObject();
		if(dataObj.getDataPresent(DataFormats.unicodeText))
			return dataObj.getData(DataFormats.unicodeText).getUnicodeText();
		return null;
	}

	///  Queries the Clipboard for the presence of data in the UnicodeText format.
	bool containsUnicodeText()
	{
		dfl.data.IDataObject dataObj = getDataObject();
		return dataObj.getDataPresent(DataFormats.unicodeText);
	}


	/// Stores (Ansi)Text data on the Clipboard.
	// ANSI text.
	void setText(ubyte[] ansiText)
	{
		setData(DataFormats.text, new Data(ansiText));
	}
	
	/// Returns a string containing the (Ansi)Text data on the Clipboard.
	ubyte[] getText()
	{
		dfl.data.IDataObject dataObj = getDataObject();
		if(dataObj.getDataPresent(DataFormats.text))
			return dataObj.getData(DataFormats.text).getText();
		return null;
	}
	
	/// Queries the Clipboard for the presence of data in the (Ansi)Text format.
	bool containsText()
	{
		dfl.data.IDataObject dataObj = getDataObject();
		return dataObj.getDataPresent(DataFormats.text);
	}

	
	/// Stores FileDrop data on the Clipboard. The dropped file list is specified as a string collection.
	void setFileDropList(string[] fileDropList)
	{
		setData(DataFormats.fileDrop, new Data(fileDropList));
	}
	
	/// Returns a string collection that contains a list of dropped files available on the Clipboard.
	string[] getFileDropList()
	{
		dfl.data.IDataObject dataObj = getDataObject();
		if(dataObj.getDataPresent(DataFormats.fileDrop))
			return dataObj.getData(DataFormats.fileDrop).getFileDropList();
		return null;
	}
	
	/// Queries the Clipboard for the presence of data in the FileDrop data format.
	bool containsFileDropList()
	{
		dfl.data.IDataObject dataObj = getDataObject();
		return dataObj.getDataPresent(DataFormats.fileDrop);
	}
	
	
	/// Stores Bitmap data on the Clipboard.
	void setImage(Image image)
	{
		setData(DataFormats.bitmap, new Data(image));
	}
	
	/// Returns a Image object from the Clipboard that contains data in the Bitmap format.
	Image getImage()
	{
		dfl.data.IDataObject dataObj = getDataObject();
		if(dataObj.getDataPresent(DataFormats.bitmap))
			return dataObj.getData(DataFormats.bitmap).getImage();
		return null;
	}
	
	/// Queries the Clipboard for the presence of data in the Bitmap data format.
	bool containsImage()
	{
		dfl.data.IDataObject dataObj = getDataObject();
		return dataObj.getDataPresent(DataFormats.bitmap);
	}


	/// Clears any data from the system Clipboard.
	void clear()
	{
		if (S_OK != OleSetClipboard(null))
			throw new DflException("Unable to clear clipboard data");
		
		_comDataObject = null;
		_dflDataObject = null;
	}
	
	
	/// Permanently adds the data that is on the Clipboard
	/// so that it is available after the data's original application closes.
	void flush()
	{
		if (S_OK != OleFlushClipboard())
			throw new DflException("Unable to flush clipboard data");
	}
	
	
private:
	dfl.internal.wincom.IDataObject _comDataObject;
	dfl.data.IDataObject _dflDataObject;
}
