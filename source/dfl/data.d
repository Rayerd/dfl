// Written by Christopher E. Miller
// See the included license.txt for copyright and license details.


///
module dfl.data;

import dfl.base;
import dfl.application;
import dfl.drawing;

import dfl.internal.dlib;
import dfl.internal.utf;
import dfl.internal.com;
import dfl.internal.winapi;
import dfl.internal.wincom;

import core.sys.windows.ole2 : DATA_E_FORMATETC;
public import core.sys.windows.wingdi : BITMAPINFO;


pragma(lib, "urlmon"); // CreateFormatEnumerator()


///
final static class DataFormats
{
	/// Pair of id and Clipboard Format Name.
	static class Format
	{
		/// Data format ID number.
		@property int id() pure // getter
		{
			return _id;
		}
		
		
		/// Data format name.
		@property Dstring name() pure // getter
		{
			return _name;
		}
		
		
		this(int id, Dstring name)
		{
			assert(_id == 0);
			assert(_name == "");
			assert(id != 0);
			assert(name != "");
			_id = id;
			_name = name;
		}

	private:
		int _id;
		Dstring _name;
	}
	
	
static:
	/// Predefined Standard Clipboard Formats.
	/// - https://learn.microsoft.com/en-us/windows/win32/dataxchg/standard-clipboard-formats
	@property Dstring bitmap() // getter
	{
		return getFormat(CF_BITMAP).name;
	}
	
	/// ditto
	@property Dstring dib() // getter
	{
		return getFormat(CF_DIB).name;
	}
	
	/// ditto
	@property Dstring dibv5() // getter
	{
		return getFormat(CF_DIBV5).name;
	}

	/// ditto
	@property Dstring dif() // getter
	{
		return getFormat(CF_DIF).name;
	}
	
	/// ditto
	@property Dstring enhandedMetaFile() // getter
	{
		return getFormat(CF_ENHMETAFILE).name;
	}
	
	/// ditto
	@property Dstring fileDrop() // getter
	{
		return getFormat(CF_HDROP).name;
	}
	
	/// ditto
	@property Dstring locale() // getter
	{
		return getFormat(CF_LOCALE).name;
	}
	
	/// ditto
	@property Dstring metafilePict() // getter
	{
		return getFormat(CF_METAFILEPICT).name;
	}
	
	/// ditto
	@property Dstring oemText() // getter
	{
		return getFormat(CF_OEMTEXT).name;
	}
	
	/// ditto
	@property Dstring palette() // getter
	{
		return getFormat(CF_PALETTE).name;
	}
	
	/// ditto
	@property Dstring penData() // getter
	{
		return getFormat(CF_PENDATA).name;
	}
	
	/// ditto
	@property Dstring riff() // getter
	{
		return getFormat(CF_RIFF).name;
	}
	
	/// ditto
	@property Dstring symbolicLink() // getter
	{
		return getFormat(CF_SYLK).name;
	}
	
	/// ditto
	@property Dstring text() // getter
	{
		return getFormat(CF_TEXT).name;
	}
	
	/// ditto
	@property Dstring tiff() // getter
	{
		return getFormat(CF_TIFF).name;
	}
	
	/// ditto
	@property Dstring unicodeText() // getter
	{
		return getFormat(CF_UNICODETEXT).name;
	}
	
	/// ditto
	@property Dstring waveAudio() // getter
	{
		return getFormat(CF_WAVE).name;
	}
	
	/// User Defined Clipboard Formats.
	/// - https://learn.microsoft.com/en-us/dotnet/api/system.windows.dataformats?view=netframework-4.8
	@property Dstring rtf() // getter
	{
		return getFormat("Rich Text Format").name;
	}
	
	/// ditto
	@property Dstring html() // getter
	{
		return getFormat("HTML Format").name;
	}
	
	/// ditto
	@property Dstring stringFormat() // getter
	{
		return getFormat("UTF-8").name;
	}
	
	/// ditto
	@property Dstring commaSeparatedValue() // getter
	{
		return getFormat("CSV").name;
	}

	/// ditto
	@property Dstring serializable() // getter
	{
		return getFormat("PersistentObject").name;
	}


	///
	Format getFormat(int id)
	{
		_initForStandardClipboardFormat();
		// Lookups Standard and User-defined Clipboard Format.
		if (id in _fmts)
			return _fmts[id];
		// Didn't find it. So defines new User-defined clipboard format.
		return _appendUserDefinedClipboardFormat(id);
	}
	
	/// ditto
	// Creates the format name if it doesn't exist.
	Format getFormat(Dstring name)
	{
		_initForStandardClipboardFormat();
		// Lookups Standard and User-defined Clipboard Format.
		assert(_fmts.length != 0);
		foreach(Format onfmt; _fmts.byValue())
		{
			if(!stringICmp(name, onfmt.name))
				return onfmt;
		}
		// Didn't find it. So defines new User-defined clipboard format.
		int newID = dfl.internal.utf.registerClipboardFormat(name);
		assert(newID != 0);
		return _appendUserDefinedClipboardFormat(newID);
	}
	
	/// ditto
	// Extra.
	Format getFormat(TypeInfo type)
	{
		_initForStandardClipboardFormat();

		if(type == typeid(ubyte[]))
			return getFormat(text);
		
		if(type == typeid(Dstring)) // If type is Ansi string in Dstring, but also assume UTF-8 string.
			return getFormat(stringFormat);
		
		if(type == typeid(Dwstring))
			return getFormat(unicodeText);
		
		if(type == typeid(Image) || type == typeid(Bitmap)) // workaround for Bitmap
			return getFormat(bitmap);
		
		if(cast(TypeInfo_Class)type) // Example: Data, Object, IDataObject, ...
			throw new DflException("Converts TypeInfo to Format failure");

		// Creates format name of User-defined Clipboard Format from TypeInfo.
		Dstring fmt = getObjectString(type); // Example: int -> "int", byte[] -> "byte[]"
		return getFormat(fmt);
	}
	
	
private:
	// _fmts is appended the Standard Clipboard Formats first.
	// After that, _fmts is appended more User-defined Clipboard Formats.
	Format[int] _fmts; // Indexed by identifier. Must _initForStandardClipboardFormat() before accessing!
	
	
	///
	void _initForStandardClipboardFormat()
	{
		if (_fmts.length != 0)
			return;
		
		void appendFormat(int id, Dstring name)
		in
		{
			assert(!(id in _fmts)); // Dupulicated ID is invalid.
		}
		do
		{
			_fmts[id] = new DataFormats.Format(id, name);
		}
		
		// https://learn.microsoft.com/en-us/windows/win32/dataxchg/standard-clipboard-formats
		appendFormat(CF_BITMAP, "CF_BITMAP");
		appendFormat(CF_DIB, "CF_DIB");
		appendFormat(CF_DIF, "CF_DIF");
		appendFormat(CF_ENHMETAFILE, "CF_ENHMETAFILE");
		appendFormat(CF_HDROP, "CF_HDROP");
		appendFormat(CF_LOCALE, "CF_LOCALE");
		appendFormat(CF_METAFILEPICT, "CF_METAFILEPICT");
		appendFormat(CF_OEMTEXT, "CF_OEMTEXT");
		appendFormat(CF_PALETTE, "CF_PALETTE");
		appendFormat(CF_PENDATA, "CF_PENDATA");
		appendFormat(CF_RIFF, "CF_RIFF");
		appendFormat(CF_SYLK, "CF_SYLK");
		appendFormat(CF_TEXT, "CF_TEXT");
		appendFormat(CF_TIFF, "CF_TIFF");
		appendFormat(CF_UNICODETEXT, "CF_UNICODETEXT");
		appendFormat(CF_WAVE, "CF_WAVE");
		appendFormat(CF_DIBV5, "CF_DIBV5");

		assert(_fmts[CF_BITMAP].name == "CF_BITMAP");
		assert(_fmts[CF_DIB].name == "CF_DIB");
		assert(_fmts[CF_DIF].name == "CF_DIF");

		_fmts.rehash;
	}
	
	
	// Assumes _initForStandardClipboardFormat() was already called and
	// -id- is not in -fmts-.
	Format _appendUserDefinedClipboardFormat(int id)
	{
		// Gets user defined clipboard format.
		Dstring name = _getRegisteredClipboardFormatName(id);
		Format fmt = new Format(id, name);
		//synchronized // _initForStandardClipboardFormat() would need to be synchronized with it.
		{
			_fmts[id] = fmt;
		}
		return fmt;
	}
	
	
	/// Returns the name of defined format by RegisterClipboardFormat().
	/// Does not get the name of one of the predefined constant ones.
	Dstring _getRegisteredClipboardFormatName(int id)
	{
		// TODO: Work around.
		// buf is "UTF-8*", but length is 5.
		// Fix "UTF-8*" to "UTF-8\0"
		Dstring buf = dfl.internal.utf.getClipboardFormatName(id); // This is not zero terminal.
		ulong len = buf.length;
		Dstring fmt = buf ~ "_ALOC_MEM_";
		char* p = cast(char*)fmt.ptr;
		*(p + len) = 0;
		if (!fmt)
		{
			throw new DflException("Unable to get registered clipboard format name");
		}
		if (len > uint.max)
			throw new DflException("_getRegisteredClipboardFormatName() failure");
		return fmt[0..cast(uint)len];
	}
	
	
	/// Converts file name list to HDROP as clipboard value.
	ubyte[] _getHDropStringFromFileDropList(Dstring[] fileNames)
	{
		size_t sz;
		foreach(fn; fileNames)
		{
			sz += fn.length + 1;
		}
		sz++;

		wchar* buf = (new wchar[sz]).ptr;
		wchar* w = buf;
		foreach (fn; fileNames)
		{
			Dwstring wName = toUnicode(fn);
			w[0 .. wName.length] = wName[];
			w[wName.length] = 0;
			w += wName.length + 1;
		}
		*w++ = 0;

		return cast(ubyte[])(buf[0 .. sz]);
	}
	unittest
	{
		Dstring[] strs;
		strs ~= "aa";
		strs ~= "bb";
		strs ~= "cc";
		wchar* hDropString = cast(wchar*)_getHDropStringFromFileDropList(strs);
		assert(hDropString[0] == 'a');
		assert(hDropString[1] == 'a');
		assert(hDropString[2] == '\0');
		assert(hDropString[3] == 'b');
		assert(hDropString[4] == 'b');
		assert(hDropString[5] == '\0');
		assert(hDropString[6] == 'c');
		assert(hDropString[7] == 'c');
		assert(hDropString[8] == '\0');
		assert(hDropString[9] == '\0');
	}
}


/// Converts the Data object to clipboard value assuming it is of the specified format id.
private void[] _getClipboardValueFromData(int id, Data data)
{
	if (CF_TEXT == id)
	{
		// ANSI text.
		enum ubyte[] UBYTE_ZERO = [0];
		return data.getText() ~ UBYTE_ZERO;
	}
	else if (DataFormats.getFormat(DataFormats.stringFormat).id == id)
	{
		// UTF-8 string.
		Dstring str = data.getStringFormat() ~ '\0';
		return cast(void[])(unsafeStringz(str)[0 .. str.length]);
	}
	else if (CF_UNICODETEXT == id)
	{
		// Unicode string.
		return (data.getUnicodeText() ~ '\0').dup;
	}
	else if (CF_DIB == id)
	{
		// https://learn.microsoft.com/ja-jp/windows/win32/gdi/storing-an-image
		// https://learn.microsoft.com/ja-jp/windows/win32/api/wingdi/ns-wingdi-bitmap
		// https://ja.wikipedia.org/wiki/Windows_bitmap
		// https://note.affi-sapo-sv.com/bitmap-file-format.php
		// http://dencha.ojaru.jp/programs_07/pg_graphic_04.html
		// http://www5d.biglobe.ne.jp/~noocyte/Programming/Windows/BmpFileFormat.html
		// https://imagingsolution.net/imaging/imaging-programing/bitmap-file-format/
		// http://hp.vector.co.jp/authors/VA023539/tips/bitmap/001.htm
		// http://www.sm.rim.or.jp/~shishido/windows.html
		const BITMAPINFO* pbi = data.getDIB();
		assert(pbi);
		const uint bitsPerPixel = pbi.bmiHeader.biPlanes * pbi.bmiHeader.biBitCount;
		const uint colorMaskBytes = {
			if (pbi.bmiHeader.biCompression == BI_BITFIELDS)
				return 4 * 3; // 4 bytes * 3 masks(R,G,B)
			else
				return 0;
		}();
		const uint numPallet = {
			if (bitsPerPixel <= 8) // 1, 4, 8 bits color
			{
				if (pbi.bmiHeader.biClrUsed == 0)
					return 2 ^^ bitsPerPixel; // Assume max.
				else
					return pbi.bmiHeader.biClrUsed;
			}
			else if (bitsPerPixel <= 32) // 16, 24, 32 bits color
				return pbi.bmiHeader.biClrUsed;
			else
				throw new DflException("Illegal color bits bitmap");
		}();
		const uint widthBytes = (pbi.bmiHeader.biWidth * bitsPerPixel + 31) / 32 * 4;
		const uint pixelBufSize = widthBytes * pbi.bmiHeader.biHeight;
		ubyte[] buf = (cast(ubyte*)pbi)[0 .. BITMAPINFOHEADER.sizeof + colorMaskBytes + RGBQUAD.sizeof * numPallet + pixelBufSize];
		return buf;
	}
	else
	{
		throw new DflException("DFL: getClipboardValueFromData failure.");
	}
}


///
private template _stopAtNull(T)
{
	T[] _stopAtNull(T[] array)
	{
		for(size_t i = 0; i != array.length; i++)
		{
			if(!array[i])
				return array[0 .. i];
		}
		throw new DflException("Invalid data");
	}
}


/// Data class for holding data in a raw format with type information.
class Data
{
	/// Construct a new Data class.
	this(T)(T arg)
	{
		this._info = typeid(arg);
		static if (is(T == Dstring))
		{
			this._innerValues.stringFormatValue = arg.dup;
		}
		else static if (is(T == Dstring[]))
		{
			this._innerValues.fileDropListValue = arg.dup;
		}
		else static if (is(T == Dwstring))
		{
			this._innerValues.unicodeTextValue = arg.dup;
		}
		else static if (is(T == ubyte[]))
		{
			this._innerValues.textValue = arg.dup;
		}
		else static if (is(T == Image))
		{
			this._innerValues.imageValue = arg;
		}
		else static if (is(T == Bitmap))
		{
			static assert(false); // Data class constructor can not get type of Bitmap.
		}
		else static if (is(T == BITMAPINFO*))
		{
			assert(arg !is null);
			this._innerValues.dibValue = arg;
		}
		else static if (is(T == Object))
		{
			this._innerValues.objectValue = arg;
		}
		else static if (is(T == Data))
		{
			Data data = arg;
			this._info = data._info;
			this._innerValues = data._innerValues;
		}
		else static if (is(T == _DataConvert))
		{
			throw new DflException("DFL: class Data construct error with _DataConvert.");
		}
		else
		{
			throw new DflException("DFL: class Data construct error with unkown type.");
		}
	}
	
	
	/// Information about the data type.
	@property TypeInfo info() pure // getter
	{
		return _info;
	}

	
	/// Get an inner value that is Data class holded with selected type.
	// Data.
	Data getData()
	{
		return _innerValues.dataValue;
	}
	
	/// ditto
	// UTF-8.
	Dstring getStringFormat()
	{
		assert(_info == typeid(Dstring));
		return _innerValues.stringFormatValue;
	}
	
	/// ditto
	// ANSI text.
	ubyte[] getText()
	{
		assert(_info == typeid(ubyte[]));
		return _innerValues.textValue;
	}
	
	/// ditto
	Dwstring getUnicodeText()
	{
		assert(_info == typeid(Dwstring));
		return _innerValues.unicodeTextValue;
	}

	/// ditto
	Dstring[] getFileDropList()
	{
		assert(_info == typeid(Dstring[]));
		return _innerValues.fileDropListValue;
	}
	
	/// ditto
	Image getImage()
	{
		assert(_info == typeid(Image) || _info == typeid(Bitmap));
		return _innerValues.imageValue;
	}
	
	/// ditto
	BITMAPINFO* getDIB()
	{
		assert(_info == typeid(BITMAPINFO*));
		return _innerValues.dibValue;
	}
	
private:
	TypeInfo _info;
	InnerValues _innerValues;

	/// Data object entity
	struct InnerValues
	{
		Data dataValue;              // For automatic convert between Clipboard Formats.
		Dstring stringFormatValue;   // UTF-8
		Dwstring unicodeTextValue;   // Unicode
		ubyte[] textValue;           // Ansi
		Dstring[] fileDropListValue; // HDROP
		Image imageValue;            // Bitmap (DDB)
		BITMAPINFO* dibValue;        // DIB
	}
}


/// Interface to a data object. The data can have different formats by setting different formats.
interface IDataObject
{
	///
	Data getData(Dstring fmt);
	/// ditto
	Data getData(TypeInfo type);
	/// ditto
	Data getData(Dstring fmt, bool doConvert);
	
	///
	bool getDataPresent(Dstring fmt);
	/// ditto
	bool getDataPresent(TypeInfo type);
	/// ditto
	bool getDataPresent(Dstring fmt, bool canConvert);
	
	///
	Dstring[] getFormats();
	
	///
	void setData(Data obj);
	/// ditto
	void setData(Dstring fmt, Data obj);
	/// ditto
	void setData(TypeInfo type, Data obj);
	/// ditto
	void setData(Dstring fmt, bool canConvert, Data obj);
}


///
class DataObject: dfl.data.IDataObject
{
	///
	Data getData(Dstring fmt)
	{
		return getData(fmt, true);
	}
	
	/// ditto
	Data getData(TypeInfo type)
	{
		Dstring fmt = DataFormats.getFormat(type).name;
		return getData(fmt, true);
	}
	
	/// ditto
	Data getData(Dstring fmt, bool doConvert)
	{
		// TODO: doConvert ...
		
		//cprintf("Looking for format '%.*s'.\n", fmt);

		int i = _find(fmt);
		if (i == -1)
			throw new DflException("Data format not present");
		return _all[i].obj;
	}
	
	
	///
	bool getDataPresent(Dstring fmt)
	{
		return getDataPresent(fmt, true);
	}
	
	/// ditto
	bool getDataPresent(TypeInfo type)
	{
		Dstring fmt = DataFormats.getFormat(type).name;
		return getDataPresent(fmt, true);
	}
	
	/// ditto
	bool getDataPresent(Dstring fmt, bool canConvert)
	{
		// TODO: canConvert ...

		return _find(fmt) != -1;
	}
	
	
	///
	Dstring[] getFormats()
	{
		static if (1) // Enumerates all format types on Clipboard.
		{
			Dstring[] clipNames;
			if (0 != OpenClipboard(null))
			{
				scope(exit) CloseClipboard();
				for (uint i = EnumClipboardFormats(0); i != 0;)
				{
					if (i != 0)
						clipNames ~= DataFormats.getFormat(i).name;
					i = EnumClipboardFormats(i);
				}
			}
			return clipNames;
		}
		else // Enumerates from the format types that the DataObject has.
		{
			Dstring[] result;
			foreach(Pair p; _all)
			{
				result ~= p.fmt;
			}
			return result;
		}
	}
	
	
	///
	void setData(Data obj)
	{
		Dstring fmt = DataFormats.getFormat(obj.info).name; // Example: int -> Format { "int", id }
		setData(fmt, /+ canConvert: +/true, obj);
	}
	
	/// ditto
	void setData(Dstring fmt, Data obj)
	{
		setData(fmt, /+ canConvert: +/true, obj);
	}
	
	/// ditto
	void setData(TypeInfo type, Data obj)
	{
		Dstring fmt = DataFormats.getFormat(type).name; // Example: int -> Format { "int", id }
		setData(fmt, /+ canConvert: +/true, obj);
	}
	
	/// ditto
	void setData(Dstring fmt, bool canConvert, Data obj)
	{
		// When -fmt- exists already, -obj- is replaced as pair of -fmt-.
		_setData(fmt, obj, true);
		
		static if (0)
		{
			import std.conv;
			string str;
			foreach(ref p; _all)
			{
				str ~= p.fmt ~ " : ";
				assert(p.obj);
				str ~= to!string(p.obj.info) ~ " : ";
				if (p.obj.info == typeid(Dstring))
					str ~= p.obj.getStringFormat();
				else
					str ~= "[SOME ONE]";
				str ~= "\n";
			}
			_msgBox(str);

		}

		// When fmt is UTF-8 and you call before _canConvertFormats(), _all[] has;
		// - fmt : UTF-8 : stringFormat

		if(canConvert)
		{
			_canConvertFormats(
				fmt, // fromFmt
				(Dstring toFmt) {
					Data markedData = new _DataConvert(obj);
					_setData(toFmt, markedData, false);
				}
			);
		}

		// When fmt is UTF-8 and you call after _canConvertFormats(), _all[] has;
		// - fmt : UTF-8 : stringFormat
		// - fmt : CF_UNICODETEXT : _DataConvert
		// - fmt : CF_TEXT : _DataConvert

		_fixPairEntry(fmt);
	}
	
	
private:
	/// Pair has two fileds, Data that should be converted and correctly data format.
	/// Do fix obj when obj.info is _DataConvert.
	/// The obj's inner value should be fixed by fmt.
	struct Pair
	{
		Dstring fmt;
		Data obj;
	}
	
	
	Pair[] _all; /// Pair list of Clipboard Format (Dstring) and Data object.
	
	
	/// Stores pair of format and data.
	/// When -replace- is true, stores new data with as a pair of preexist format.
	// Concrete implementation.
	void _setData(Dstring fmt, Data obj, bool replace)
	{
		// # Example 1
		//
		// Search "CF_UNICODETEXT" in _all.
		// _all[0].fmt == "CF_TEXT"
		// _all[1].fmt == "CF_UNICODETEXT"  <-- FOUND HERE
		//
		// _all[1].obj = new obj

		// # Example 2
		//
		// Search "CF_BITMAP" in _all.
		// _all[0].fmt == "CF_TEXT"
		// _all[1].fmt == "CF_UNICODETEXT"
		//                                  <-- NOT FOUND
		// _all ~= Pair(fmt, obj);

		int i = _find(fmt);
		if (i != -1)
		{
			if (replace)
				_all[i].obj = obj; // If found fmt in _all, replace obj.
		}
		else
		{
			// If not found fmt in _all, append new pair of fmt and obj.
			Pair pair;
			pair.fmt = fmt;
			pair.obj = obj;
			_all ~= pair;
		}

		static if (1)
		{
			int j = _find(fmt);
			assert(j != -1);
			assert(_all[j].fmt == fmt);
			assert(_all[j].obj is obj);
		}
	}


	///
	int _find(Dstring fmt) const
	{
		for (size_t i; i < _all.length; i++)
		{
			if(!stringICmp(_all[i].fmt, fmt))
			{
				return i.toI32;
			}
		}
		return -1;
	}
	
	
	/// 
	void _fixPairEntry(Dstring fmt)
	{
		for (size_t i; i < _all.length; i++)
		{
			if(_all[i].obj.info == typeid(_DataConvert))
			{
				Data fromData = _all[i].obj.getData(); // Gets original Data object.
				assert(fromData);
				Dstring toFmt = _all[i].fmt;
				_all[i].obj = _doConvertFormat(fromData, toFmt);
			}
		}
	}
}


/// Defined for marking _DataConvert tag to Data object.
/// When this object is created by coping Data object,
/// change Data.info value to typeid(_DataConvert),
/// but not change Data's inner value.
/// finally, Hold original Data into this._innerValues._dataValue.
private final class _DataConvert : Data
{
	this(Data data)
	{
		super(data);
		this._info = typeid(_DataConvert);
		this._innerValues = data._innerValues;
		this._innerValues.dataValue = data;
	}
}


/// 
private void _canConvertFormats(Dstring fromFmt, void delegate(Dstring toFmt) callback)
{
	// StringFormat(utf8)/UnicodeText/(Ansi)Text
	if(!stringICmp(fromFmt, DataFormats.stringFormat))
	{
		callback(DataFormats.unicodeText);
		callback(DataFormats.text);
	}
	else if(!stringICmp(fromFmt, DataFormats.unicodeText))
	{
		callback(DataFormats.stringFormat);
		callback(DataFormats.text);
	}
	else if(!stringICmp(fromFmt, DataFormats.text))
	{
		callback(DataFormats.stringFormat);
		callback(DataFormats.unicodeText);
	}
	// bitmap <-> dib <-> dibv5 are converted automatically by system.
}

/// Get new Data instance that is converted format.
private Data _doConvertFormat(Data fromData, Dstring toFmt)
{
	assert(fromData !is null);
	assert(toFmt != "");
	assert(fromData._info != typeid(_DataConvert));
	assert(fromData.getData() is null);

	Data result;

	// StringFormat(utf8)/UnicodeText/(Ansi)Text
	if(!stringICmp(toFmt, DataFormats.stringFormat))
	{
		if(typeid(Dwstring) == fromData.info)
		{
			result = new Data(utf16stringtoUtf8string(fromData.getUnicodeText()));
		}
		else if(typeid(ubyte[]) == fromData.info)
		{
			ubyte[] ubs = fromData.getText();
			result = new Data(dfl.internal.utf.fromAnsi(cast(Dstringz)ubs.ptr, ubs.length));
		}
		else
			assert(0);
	}
	else if(!stringICmp(toFmt, DataFormats.unicodeText))
	{
		if(typeid(Dstring) == fromData.info)
		{
			result = new Data(utf8stringtoUtf16string(fromData.getStringFormat()));
		}
		else if(typeid(ubyte[]) == fromData.info)
		{
			ubyte[] ubs = fromData.getText();
			result = new Data(dfl.internal.utf.ansiToUnicode(cast(Dstringz)ubs.ptr, ubs.length));
		}
		else
			assert(0);
	}
	else if(!stringICmp(toFmt, DataFormats.text))
	{
		if(typeid(Dstring) == fromData.info)
		{
			result = new Data(cast(ubyte[])dfl.internal.utf.toAnsi(fromData.getStringFormat()));
		}
		else if(typeid(Dwstring) == fromData.info)
		{
			Dwstring wcs = fromData.getUnicodeText();
			result = new Data(cast(ubyte[])unicodeToAnsi(wcs.ptr, wcs.length));
		}
		else
			assert(0);
	}
	// bitmap <-> dib <-> dibv5 are converted automatically by system.
	assert(result);
	return result;
}


///
final class ComToDdataObject: dfl.data.IDataObject
{
	///
	this(dfl.internal.wincom.IDataObject dataObj)
	{
		_comDataObj = dataObj;
		_comDataObj.AddRef();
	}
	
	
	///
	~this()
	{
		_comDataObj.Release(); // Must get called...
	}
	
	
	///
	private Data _getData(int id)
	{
		FORMATETC fmte;
		STGMEDIUM stgm;

		// TODO: Lookup all Stadard and User-defined Clipboard Formats

		if (id == CF_BITMAP)
		{
			fmte.cfFormat = cast(CLIPFORMAT)id;
			fmte.ptd = null;
			fmte.dwAspect = DVASPECT_CONTENT;
			fmte.lindex = -1;
			fmte.tymed = TYMED_GDI;

			if (S_OK != _comDataObj.QueryGetData(&fmte/+ in +/))
				return null;
			
			if (S_OK != _comDataObj.GetData(&fmte/+ in +/, &stgm/+ out +/))
				return null;

			Image image = Image.fromHBitmap(cast(HBITMAP)stgm.hBitmap, true);
			ReleaseStgMedium(&stgm);
			return new Data(image);
		}
		else if (id == CF_TEXT
			||   id == CF_UNICODETEXT
			||   id == DataFormats.getFormat(DataFormats.stringFormat).id
			||   id == CF_HDROP
			||   id == CF_DIB)
		{
			fmte.cfFormat = cast(CLIPFORMAT)id;
			fmte.ptd = null;
			fmte.dwAspect = DVASPECT_CONTENT;
			fmte.lindex = -1;
			fmte.tymed = TYMED_HGLOBAL;

			if (S_OK != _comDataObj.QueryGetData(&fmte/+ in +/))
				return null;
			
			if (S_OK != _comDataObj.GetData(&fmte/+ in +/, &stgm/+ out +/))
				return null;
			
			void* plock = GlobalLock(stgm.hGlobal);
			if(!plock)
			{
				ReleaseStgMedium(&stgm);
				throw new DflException("Error obtaining data");
			}
			
			void[] mem = new ubyte[GlobalSize(stgm.hGlobal)];
			mem[] = plock[0 .. mem.length];
			GlobalUnlock(stgm.hGlobal);
			ReleaseStgMedium(&stgm);

			if (id == CF_TEXT)
				return new Data(_stopAtNull!(ubyte)(cast(ubyte[])mem));

			if (id == CF_UNICODETEXT)
				return new Data(_stopAtNull!(Dwchar)(cast(Dwstring)mem));

			if (id == DataFormats.getFormat(DataFormats.stringFormat).id)
				return new Data(_stopAtNull!(Dchar)(cast(Dstring)mem));
			
			if (id == CF_HDROP)
			{
				Dstring[] fileDropList;
				int numFiles = dragQueryFile(cast(HDROP)mem);
				for (int i = 0 ; i < numFiles; i++)
				{
					fileDropList ~= dragQueryFile(cast(HDROP)mem, i);
				}
				return new Data(fileDropList);
			}

			if (id == CF_DIB)
			{
				BITMAPINFO* pbi = cast(BITMAPINFO*)mem;

				static if (0) // Call on paste
				{
					HDC hdc = GetDC(null);
					HDC hdcMem = CreateCompatibleDC(hdc);
					Bitmap bitmap = createBitmap(pbi);
					HGDIOBJ oldBitmap = SelectObject(hdcMem, bitmap.handle);
					core.sys.windows.wingdi.BitBlt(hdc, 0, 500, pbi.bmiHeader.biWidth, pbi.bmiHeader.biHeight, hdcMem, 0, 0, SRCCOPY);
					core.sys.windows.wingdi.TextOutW(hdc, 0, 500, "_getData()"w.ptr, 10);
					SelectObject(hdcMem, oldBitmap);
					DeleteDC(hdcMem);
					ReleaseDC(null, hdc);
				}

				return new Data(pbi);
			}
			
			assert(0);
		}
		else
		{
			throw new DflException("Not supported format in _getData()");
		}
	}
	
	/// ditto
	Data getData(Dstring fmt)
	{
		return _getData(DataFormats.getFormat(fmt).id);
	}
	
	/// ditto
	Data getData(TypeInfo type)
	{
		return _getData(DataFormats.getFormat(type).id);
	}
	
	/// ditto
	Data getData(Dstring fmt, bool doConvert)
	{
		// TODO: doConvert ...

		return _getData(DataFormats.getFormat(fmt).id);
	}
	
	
	///
	private bool _getDataPresent(int id)
	{
		static if (0) // Enumerates all format types on Clipboard.
		{
			static if (0)
				_msgBox([id.intToString, DataFormats.getFormat(id).name] ~ getFormats());
			
			if (0 != OpenClipboard(null))
			{
				scope(exit) CloseClipboard();
				for (uint i = EnumClipboardFormats(0); i != 0;)
				{
					if (i == id)
						return true;
					i = EnumClipboardFormats(i);
				}
			}
			return false;
		}
		else static if (0) // Enumerates from the format types that the DataObject has.
		{
			IEnumFORMATETC fenum;
			
			if (S_OK != _comDataObj.EnumFormatEtc(DATADIR_GET, &fenum))
				throw new DflException("Unable to get formats");

			// https://learn.microsoft.com/en-us/windows/win32/api/objidl/nf-objidl-idataobject-enumformatetc
			scope(exit) fenum.Release();
			
			for(;;)
			{
				FORMATETC fmte;
				ULONG numFetched;
				if (S_OK != fenum.Next(1, &fmte, &numFetched))
					break;
				if (!numFetched)
					break;
				if (fmte.cfFormat == id)
					return true;
			}
			
			return false;
		}
		else
		{
			FORMATETC fmte;

			// TODO: Lookup all Stadard and User-defined Clipboard Formats
			
			if (id == CF_BITMAP)
			{
				fmte.cfFormat = cast(CLIPFORMAT)id;
				fmte.ptd = null;
				fmte.dwAspect = DVASPECT_CONTENT;
				fmte.lindex = -1;
				fmte.tymed = TYMED_GDI;
			}
			else if (id == CF_TEXT
				||   id == CF_UNICODETEXT
				||   id == DataFormats.getFormat(DataFormats.stringFormat).id
				||   id == CF_HDROP
				||   id == CF_DIB)
			{
				fmte.cfFormat = cast(CLIPFORMAT)id;
				fmte.ptd = null;
				fmte.dwAspect = DVASPECT_CONTENT;
				fmte.lindex = -1;
				fmte.tymed = TYMED_HGLOBAL;
			}
			else
				return false;
			
			static if (0)
			{
				_msgBox(DataFormats.getFormat(id).name);
				_msgBox(fmte);
			}

			return S_OK == _comDataObj.QueryGetData(&fmte);
		}
	}
	
	/// ditto
	bool getDataPresent(Dstring fmt)
	{
		return _getDataPresent(DataFormats.getFormat(fmt).id);
	}
	
	/// ditto
	bool getDataPresent(TypeInfo type)
	{
		DataFormats.Format fmt = DataFormats.getFormat(type); // Example: int -> Format { "int", id }
		return _getDataPresent(fmt.id);
	}
	
	/// ditto
	bool getDataPresent(Dstring fmt, bool canConvert)
	{
		// TODO: canConvert ...

		return _getDataPresent(DataFormats.getFormat(fmt).id);
	}
	
	
	///
	Dstring[] getFormats()
	{
		static if (1) // Enumerates all format types on Clipboard.
		{
			// In the case of the official DataObject, which is probably set when you screenshot it,
			// both implementations below list all format types, including automatic conversions.
			// In the case of DFL's own DataObject and when EnumFormatEtc() is called,
			// only the formats held by the original DataObject itself are enumerated,
			// but when GetData() is called, data is read even in automatically converted format formats.
			// Therefore, in the first place, the original DataObject should also list all format types
			// including automatic conversion.
			string[] clipNames;
			if (0 != OpenClipboard(null))
			{
				scope(exit) CloseClipboard();
				for (uint i = EnumClipboardFormats(0); i != 0;)
				{
					if (i != 0)
						clipNames ~= DataFormats.getFormat(i).name;
					i = EnumClipboardFormats(i);
				}
			}
			return clipNames;
		}
		else // Enumerates from the format types that the DataObject has.
		{
			IEnumFORMATETC fenum;
			FORMATETC fmte;
			Dstring[] clipNames;
			ULONG numFetched;
			
			if(S_OK != _comDataObj.EnumFormatEtc(DATADIR_GET, &fenum))
				throw new DflException("Unable to get formats");
			
			for(;;)
			{
				if(S_OK != fenum.Next(1, &fmte, &numFetched))
					break;
				if(!numFetched)
					break;
				//cprintf("\t\t{getFormats:%d}\n", fmte.cfFormat);
				clipNames ~= DataFormats.getFormat(fmte.cfFormat).name;
			}
			// https://learn.microsoft.com/en-us/windows/win32/api/objidl/nf-objidl-idataobject-enumformatetc
			fenum.Release();
			
			return clipNames;
		}
	}
	
	
	///
	private void _setData(int id, Data obj)
	{
		/+
		FORMATETC fmte;
		STGMEDIUM stgm;
		HANDLE hmem;
		void[] mem;
		void* pmem;
		
		mem = DataFormats.getClipboardValueFromData(id, obj);
		
		hmem = GlobalAlloc(GMEM_SHARE, mem.length);
		if(!hmem)
		{
			//cprintf("Unable to GlobalAlloc().\n");
			err_set:
			throw new DflException("Unable to set data");
		}
		pmem = GlobalLock(hmem);
		if(!pmem)
		{
			//cprintf("Unable to GlobalLock().\n");
			GlobalFree(hmem);
			goto err_set;
		}
		pmem[0 .. mem.length] = mem;
		GlobalUnlock(hmem);
		
		fmte.cfFormat = cast(CLIPFORMAT)id;
		fmte.ptd = null;
		fmte.dwAspect = DVASPECT_CONTENT; // ?
		fmte.lindex = -1;
		fmte.tymed = TYMED_HGLOBAL;
		
		stgm.tymed = TYMED_HGLOBAL;
		stgm.hGlobal = hmem;
		stgm.pUnkForRelease = null;
		
		// -dataObj- now owns the handle.
		HRESULT hr = dataObj.SetData(&fmte, &stgm, true);
		if(S_OK != hr)
		{
			//cprintf("Unable to IDataObject::SetData() = %d (0x%X).\n", hr, hr);
			// Failed, need to free it..
			GlobalFree(hmem);
			goto err_set;
		}
		+/
		// Don't set stuff in someone else's data object.
		throw new DflException("DFL: ComToDdataObject._setData() is not implemented.");
	}
	
	/// ditto
	void setData(Data obj)
	{
		DataFormats.Format fmt = DataFormats.getFormat(obj.info); // Example: int -> Format { "int", id }
		_setData(fmt.id, obj);
	}
	
	/// ditto
	void setData(Dstring fmt, Data obj)
	{
		_setData(DataFormats.getFormat(fmt).id, obj);
	}
	
	/// ditto
	void setData(TypeInfo type, Data obj)
	{
		DataFormats.Format fmt = DataFormats.getFormat(type); // Example: int -> Format { "int", id }
		_setData(fmt.id, obj);
	}
	
	/// ditto
	void setData(Dstring fmt, bool canConvert, Data obj)
	{
		// TODO: canConvert ...

		_setData(DataFormats.getFormat(fmt).id, obj);
	}
	
	
	///
	bool isSameDataObject(dfl.internal.wincom.IDataObject comDataObj) const pure
	{
		return comDataObj is _comDataObj;
	}
	
	
private:
	dfl.internal.wincom.IDataObject _comDataObj;
}


///
final class DtoComDataObject: DflComObject, dfl.internal.wincom.IDataObject
{
	///
	this(dfl.data.IDataObject dataObj)
	{
		assert(dataObj);
		_dataObj = dataObj;

		CLIPFORMAT getId(Dstring fmt)
		{
			return cast(CLIPFORMAT)DataFormats.getFormat(fmt).id;
		}
		
		// TODO: Lookup all Stadard and User-defined Clipboard Formats

		// FormatEtc list that can send to paste target.
		_formatetcList ~= FORMATETC(CF_BITMAP, null, DVASPECT_CONTENT, -1, TYMED_GDI);
		_formatetcList ~= FORMATETC(CF_DIB, null, DVASPECT_CONTENT, -1, TYMED_HGLOBAL);
		_formatetcList ~= FORMATETC(CF_TEXT, null, DVASPECT_CONTENT, -1, TYMED_HGLOBAL);
		_formatetcList ~= FORMATETC(CF_UNICODETEXT, null, DVASPECT_CONTENT, -1, TYMED_HGLOBAL);
		_formatetcList ~= FORMATETC(getId(DataFormats.stringFormat), null, DVASPECT_CONTENT, -1, TYMED_HGLOBAL);
		_formatetcList ~= FORMATETC(CF_HDROP, null, DVASPECT_CONTENT, -1, TYMED_HGLOBAL);
	}

	
extern(Windows):
	
	///
	// [in]  IID* riid
	// [out] void** ppv
	override HRESULT QueryInterface(IID* riid, void** ppv)
	{
		if(*riid == _IID_IDataObject)
		{
			*ppv = cast(void*)cast(dfl.internal.wincom.IDataObject)this;
			AddRef();
			return S_OK;
		}
		else if(*riid == _IID_IUnknown)
		{
			*ppv = cast(void*)cast(IUnknown)this;
			AddRef();
			return S_OK;
		}
		else
		{
			*ppv = null;
			return E_NOINTERFACE;
		}
	}
	
	
	///
	// [in]  FORMATETC* pFormatetc
	// [out] STGMEDIUM* pmedium
	HRESULT GetData(FORMATETC* pFormatetc, STGMEDIUM* pmedium)
	{
		try
		{
			// TODO: Lookup all Stadard and User-defined Clipboard Formats

			if (pFormatetc.cfFormat == CF_BITMAP)
			{
				if (pFormatetc.tymed & TYMED_GDI)
				{
					DataFormats.Format fmt = DataFormats.getFormat(pFormatetc.cfFormat);
					Data data = _dataObj.getData(fmt.name, true); // Should this be convertable?

					Bitmap bitmap = cast(Bitmap)data.getImage();
					assert(typeid(bitmap) == typeid(Bitmap));

					pmedium.tymed = TYMED_GDI;
					pmedium.hBitmap = bitmap.handle;
					pmedium.pUnkForRelease = null;
				}
				else
				{
					return DV_E_TYMED;
				}
			}
			else if (pFormatetc.cfFormat == CF_TEXT
				||   pFormatetc.cfFormat == CF_UNICODETEXT
				||   pFormatetc.cfFormat == DataFormats.getFormat(DataFormats.stringFormat).id
				||   pFormatetc.cfFormat == CF_DIB)
			{
				if (pFormatetc.tymed & TYMED_HGLOBAL)
				{
					DataFormats.Format fmt = DataFormats.getFormat(pFormatetc.cfFormat);
					Data data = _dataObj.getData(fmt.name, true); // Should this be convertable?
					
					// ; void[] src = cast(void[])"hoge\0"; // UTF-8 text example
					void[] src = _getClipboardValueFromData(fmt.id, data);
					HGLOBAL hg = GlobalAlloc(GHND, src.length.toI32);
					if (!hg)
					{
						return STG_E_MEDIUMFULL;
					}

					const uint memSize = GlobalSize(hg);
					if (!memSize)
					{
						return STG_E_MEDIUMFULL;
					}

					void* pmem = GlobalLock(hg);
					if (!pmem)
					{
						GlobalFree(hg);
						return E_UNEXPECTED;
					}

					pmem[0 .. memSize] = src[];
					GlobalUnlock(hg);
					
					pmedium.tymed = TYMED_HGLOBAL;
					pmedium.hGlobal = hg;
					pmedium.pUnkForRelease = null;
				}
				else
				{
					return DV_E_TYMED;
				}
			}
			else if (pFormatetc.cfFormat == CF_HDROP)
			{
				if (pFormatetc.tymed & TYMED_HGLOBAL)
				{
					DataFormats.Format fmt = DataFormats.getFormat(pFormatetc.cfFormat);
					Data data = _dataObj.getData(fmt.name, true); // Should this be convertable?
					assert(data);
					string[] files = data.getFileDropList();
					assert(files);
					ubyte[] ubfileList = DataFormats._getHDropStringFromFileDropList(files);
					// ; ubyte[] ubfileList = cast(ubyte[])"abc\0\0xyz\0"w;

					HDROP hDrop = cast(HDROP)GlobalAlloc(GHND, cast(uint)(DROPFILES.sizeof + ubfileList.length));
					if(!hDrop)
					{
						return STG_E_MEDIUMFULL;
					}

					DROPFILES* dp = cast(DROPFILES*)GlobalLock(hDrop);
					if(!dp)
					{
						GlobalFree(hDrop);
						return E_UNEXPECTED;
					}

					dp.pFiles = DROPFILES.sizeof;
					dp.pt.x = 0;
					dp.pt.y = 0;
					dp.fNC = false;
					dp.fWide = true;

					ubyte* p = cast(ubyte*)dp + DROPFILES.sizeof;
					p[0 .. ubfileList.length] = ubfileList[];
					GlobalUnlock(hDrop);
					
					pmedium.tymed = TYMED_HGLOBAL;
					pmedium.hGlobal = hDrop;
					pmedium.pUnkForRelease = null;
				}
				else
				{
					return DV_E_TYMED;
				}
			}
			else
			{
				return DV_E_FORMATETC;
			}
		}
		catch(DflException e)
		{
			//Application.onThreadException(e);
			
			return DV_E_FORMATETC;
		}
		catch(OomException e)
		{
			Application.onThreadException(e);
			
			return E_OUTOFMEMORY;
		}
		catch(DThrowable e)
		{
			Application.onThreadException(e);
			
			return E_UNEXPECTED;
		}
		
		return S_OK;
	}
	
	
	///
	// [in]  FORMATETC* pFormatetc
	// [out] STGMEDIUM* pmedium
	HRESULT GetDataHere(FORMATETC* pFormatetc, STGMEDIUM* pmedium)
	{
		return DATA_E_FORMATETC;
	}
	
	
	///
	// [in] FORMATETC* pFormatetc
	HRESULT QueryGetData(FORMATETC* pFormatetc)
	{
		try
		{
			static if (1) // Enumerates all format types on Clipboard.
			{
				if (0 != OpenClipboard(null))
				{
					scope(exit) CloseClipboard();
					for (uint i = EnumClipboardFormats(0); i != 0;)
					{
						if (i == pFormatetc.cfFormat)
							return S_OK;
						i = EnumClipboardFormats(i);
					}
				}
			}
			else // Enumerates from the format types that the DataObject has.
			{
				if (!_isSupportedFormatetc(pFormatetc))
				{
					return S_FALSE;
				}

				// Call DataObject.find(fmt, fix: true) to find out
				// if the required fmt exists in DataObject._all.
				Dstring fmt = DataFormats.getFormat(pFormatetc.cfFormat).name;
				if(!_dataObj.getDataPresent(fmt))
				{
					return S_FALSE;
				}
			}
		}
		catch(DflException e)
		{
			//Application.onThreadException(e);
			
			return DV_E_FORMATETC;
		}
		catch(OomException e)
		{
			Application.onThreadException(e);
			
			return E_OUTOFMEMORY;
		}
		catch(DThrowable e)
		{
			Application.onThreadException(e);
			
			return E_UNEXPECTED;
		}
		
		// return S_OK;
		return S_FALSE;
	}
	
	///
	// [in]  FORMATETC* pFormatetcIn
	// [out] FORMATETC* pFormatetcOut
	HRESULT GetCanonicalFormatEtc(FORMATETC* pFormatetcIn, FORMATETC* pFormatetcOut)
	{
		pFormatetcOut.ptd = null;
		return E_NOTIMPL;
	}
	
	
	///
	// [in]  FORMATETC* pFormatetc
	// [out] STGMEDIUM* pmedium
	// [in]  BOOL fRelease
	HRESULT SetData(FORMATETC* pFormatetc, STGMEDIUM* pmedium, BOOL fRelease)
	{
		return E_NOTIMPL;
	}
	
	
	///
	// [in]  DWORD dwDirection
	// [out] IEnumFORMATETC* ppenumFormatetc
	HRESULT EnumFormatEtc(DWORD dwDirection, IEnumFORMATETC* ppenumFormatetc)
	{
		try
		{
			if(dwDirection == DATADIR_GET)
			{
				FORMATETC[] feList;
				foreach (ref formatetc; _formatetcList)
				{
					int id = formatetc.cfFormat;
					DataFormats.Format format = DataFormats.getFormat(id);
					if (_dataObj.getDataPresent(format.name))
					{
						// dataObj has required type of FORMATETC.
						feList ~= formatetc;
					}
				}

				if (feList.length == 0)
				{
					// That is illegal that number of FORMATETC[] is zero.
					feList ~= FORMATETC(0, null, DVASPECT_CONTENT, -1, TYMED_NULL);
					return CreateFormatEnumerator(1, &(feList[0]), ppenumFormatetc);
				}
				else
				{
					return CreateFormatEnumerator(cast(UINT)feList.length, &(feList[0]), ppenumFormatetc);
				}
			}
			else if(dwDirection == DATADIR_SET)
			{
				return E_NOTIMPL;
			}
			else
			{
				return E_INVALIDARG;
			}
		}
		catch(DThrowable e)
		{
			Application.onThreadException(e);
			
			return E_UNEXPECTED;
		}
	}
	
	
	///
	// [in]  FORMATETC* pFormatetc
	// [in]  DWORD advf
	// [in]  IAdviseSink pAdvSink
	// [out] DWORD* pdwConnection
	HRESULT DAdvise(FORMATETC* pFormatetc, DWORD advf, IAdviseSink pAdvSink, DWORD* pdwConnection)
	{
		return OLE_E_ADVISENOTSUPPORTED;
	}
	
	
	///
	// [in]  DWORD dwConnection
	HRESULT DUnadvise(DWORD dwConnection)
	{
		return OLE_E_ADVISENOTSUPPORTED;
	}
	
	
	///
	// [out] IEnumSTATDATA* ppenumAdvise
	HRESULT EnumDAdvise(IEnumSTATDATA* ppenumAdvise)
	{
		return OLE_E_ADVISENOTSUPPORTED;
	}
	
	
extern(D):
	
private:
	///
	bool _isSupportedFormatetc(const FORMATETC* pFormatetc) const
	{
		foreach (ref const FORMATETC f; _formatetcList)
		{
			if ((f.tymed & pFormatetc.tymed)
				&& f.cfFormat == pFormatetc.cfFormat
				&& f.dwAspect == pFormatetc.dwAspect
				&& f.lindex == pFormatetc.lindex)
			{
				return true;
			}
		}
		return false;
	}
	
	dfl.data.IDataObject _dataObj;
	FORMATETC[] _formatetcList;
}


///
BITMAPINFO* createBitmapInfo(Bitmap objBitmap)
{
	HBITMAP hBitmap = objBitmap.handle;
	BITMAP bitmap;
	GetObject(hBitmap, BITMAP.sizeof, &bitmap); // Gets bitmap info but color bits is not used.
	HDC hdc = GetDC(null);

	// Allocates memory of BITMAPINFO
	const uint bitsPerPixel = bitmap.bmPlanes * 32; // 32 bits color
	const uint colorMaskBytes = {
		// Contains color mask when biCompression is BI_BITFIELDS.
		return 4 * 3; // 4 bytes * 3 masks(R,G,B)
	}();
	const uint numPallet = 0; // Wants that no color palette.
	const uint widthBytes = (bitmap.bmWidth * bitsPerPixel + 31) / 32 * 4;
	const uint bitmapBodySize = widthBytes * bitmap.bmHeight;

	BITMAPINFO* pbi = cast(BITMAPINFO*)new ubyte[
		BITMAPINFOHEADER.sizeof + colorMaskBytes + RGBQUAD.sizeof * numPallet + bitmapBodySize];

	// https://learn.microsoft.com/ja-jp/windows/win32/api/wingdi/nf-wingdi-getdibits
	pbi.bmiHeader.biSize = BITMAPINFOHEADER.sizeof; // First 6 members
	pbi.bmiHeader.biWidth = bitmap.bmWidth;
	pbi.bmiHeader.biHeight = bitmap.bmHeight;
	pbi.bmiHeader.biPlanes = bitmap.bmPlanes;
	pbi.bmiHeader.biBitCount = 32; // 32 bits color
	pbi.bmiHeader.biCompression = BI_BITFIELDS; // Contains color mask
	// pbi.bmiHeader.biSizeImage =     // No other members need to be initialized.
	// pbi.bmiHeader.biXPelsPerMeter = // ditto
	// pbi.bmiHeader.biYPelsPerMeter = // ditto
	// pbi.bmiHeader.biClrUsed =       // ditto
	// pbi.bmiHeader.biClrImportant =  // ditto
	if (0 == core.sys.windows.wingdi.GetDIBits(
		hdc, hBitmap, 0, bitmap.bmHeight,
		cast(ubyte*)pbi + BITMAPINFOHEADER.sizeof + colorMaskBytes + RGBQUAD.sizeof * numPallet, pbi, DIB_RGB_COLORS))
	{
		throw new DflException("createBitmapInfo failure");
	}

	static if (0)
	{
		HDC hdcMem = CreateCompatibleDC(hdc);
		HGDIOBJ oldGdiObj = SelectObject(hdcMem, hBitmap);

		for (uint y = 10; y < 30; y++)
		{
			for (uint x = 10; x < 30; x++)
			{
				// uint.sizeof == 32 bytes
				uint* p = cast(uint*)(cast(ubyte*)pbi + BITMAPINFOHEADER.sizeof + colorMaskBytes + RGBQUAD.sizeof * numPallet);
				p[y * bitmap.bmWidth + x] = 0x000000FF;
			}
		}
		core.sys.windows.wingdi.SetDIBitsToDevice(
			hdcMem, 0, 0, pbi.bmiHeader.biWidth, pbi.bmiHeader.biHeight,
			0, 0, 0, pbi.bmiHeader.biHeight,
			cast(ubyte*)pbi + BITMAPINFOHEADER.sizeof + colorMaskBytes + RGBQUAD.sizeof * numPallet, pbi, DIB_RGB_COLORS);
		core.sys.windows.wingdi.Rectangle(hdcMem, 0, 0, 50, 50);
		TextOutW(hdcMem, 0, 0, "createBitmapInfo()"w.ptr, 18);
		core.sys.windows.wingdi.BitBlt(hdc, 200, 200, pbi.bmiHeader.biWidth, pbi.bmiHeader.biHeight, hdcMem, 0, 0, SRCCOPY);

		SelectObject(hdcMem, oldGdiObj);
		DeleteDC(hdcMem);
	}

	ReleaseDC(null, hdc);
	return pbi;
}


///
Bitmap createBitmap(BITMAPINFO* pbi)
{
	const uint bitsPerPixel = pbi.bmiHeader.biPlanes * pbi.bmiHeader.biBitCount;
	const uint colorMaskBytes = {
		if (pbi.bmiHeader.biCompression == BI_BITFIELDS)
			return 4 * 3; // 4 bytes * 3 masks(R,G,B)
		else
			return 0;
	}();
	const uint numPallet = {
		if (bitsPerPixel <= 8) // 1, 4, 8 bits color
		{
			if (pbi.bmiHeader.biClrUsed == 0)
				return 2 ^^ bitsPerPixel; // Assume max.
			else
				return pbi.bmiHeader.biClrUsed;
		}
		else if (bitsPerPixel <= 32) // 16, 24, 32 bits color
			return pbi.bmiHeader.biClrUsed;
		else
			throw new DflException("Illegal color bits bitmap");
	}();
	HDC hdc = GetDC(null);
	HBITMAP hBitmap = CreateDIBitmap(
		hdc, &pbi.bmiHeader, CBM_INIT,
		cast(ubyte*)pbi + BITMAPINFOHEADER.sizeof + colorMaskBytes + RGBQUAD.sizeof * numPallet, pbi, DIB_RGB_COLORS);
	// If you called "HBITMAP hOldBitmap = SelectObject(hdc, hBitmap)",
	// you must call "SelectObject(hdc, hOldBitmap)" before "Image.fromHBitmap()".
	// The otherwise you will get all black.
	Bitmap bitmap = Image.fromHBitmap(hBitmap, true);
	ReleaseDC(null, hdc);
	return bitmap;
}


///
void _msgBox(T)(T arg)
{
	import dfl.messagebox, std.conv;
	msgBox(to!string(arg));
}
