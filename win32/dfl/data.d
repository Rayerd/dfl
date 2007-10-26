// Written by Christopher E. Miller
// See the included license.txt for copyright and license details.


///
module dfl.data;

private import dfl.internal.dlib;

private import dfl.base, dfl.internal.winapi, dfl.internal.wincom, dfl.application,
	dfl.internal.utf, dfl.internal.com;


///
class DataFormats // docmain
{
	///
	static class Format // docmain
	{
		/// Data format ID number.
		final int id() // getter
		{
			return _id;
		}
		
		
		/// Data format name.
		final char[] name() // getter
		{
			return _name;
		}
		
		
		package:
		int _id;
		char[] _name;
		
		
		this()
		{
		}
	}
	
	
	static:
	
	/// Predefined data formats.
	char[] bitmap() // getter
	{
		return getFormat(CF_BITMAP).name;
	}
	
	/+
	/// ditto
	char[] commaSeparatedValue() // getter
	{
		return getFormat(?).name;
	}
	+/
	
	/// ditto
	char[] dib() // getter
	{
		return getFormat(CF_DIB).name;
	}
	
	/// ditto
	char[] dif() // getter
	{
		return getFormat(CF_DIF).name;
	}
	
	/// ditto
	char[] enhandedMetaFile() // getter
	{
		return getFormat(CF_ENHMETAFILE).name;
	}
	
	/// ditto
	char[] fileDrop() // getter
	{
		return getFormat(CF_HDROP).name;
	}
	
	/// ditto
	char[] html() // getter
	{
		return getFormat("HTML Format").name;
	}
	
	/// ditto
	char[] locale() // getter
	{
		return getFormat(CF_LOCALE).name;
	}
	
	/// ditto
	char[] metafilePict() // getter
	{
		return getFormat(CF_METAFILEPICT).name;
	}
	
	/// ditto
	char[] oemText() // getter
	{
		return getFormat(CF_OEMTEXT).name;
	}
	
	/// ditto
	char[] palette() // getter
	{
		return getFormat(CF_PALETTE).name;
	}
	
	/// ditto
	char[] penData() // getter
	{
		return getFormat(CF_PENDATA).name;
	}
	
	/// ditto
	char[] riff() // getter
	{
		return getFormat(CF_RIFF).name;
	}
	
	/// ditto
	char[] rtf() // getter
	{
		return getFormat("Rich Text Format").name;
	}
	
	
	/+
	/// ditto
	char[] serializable() // getter
	{
		return getFormat(?).name;
	}
	+/
	
	/// ditto
	char[] stringFormat() // getter
	{
		return utf8; // ?
	}
	
	/// ditto
	char[] utf8() // getter
	{
		return getFormat("UTF-8").name;
	}
	
	/// ditto
	char[] symbolicLink() // getter
	{
		return getFormat(CF_SYLK).name;
	}
	
	/// ditto
	char[] text() // getter
	{
		return getFormat(CF_TEXT).name;
	}
	
	/// ditto
	char[] tiff() // getter
	{
		return getFormat(CF_TIFF).name;
	}
	
	/// ditto
	char[] unicodeText() // getter
	{
		return getFormat(CF_UNICODETEXT).name;
	}
	
	/// ditto
	char[] waveAudio() // getter
	{
		return getFormat(CF_WAVE).name;
	}
	
	
	// Assumes _init() was already called and
	// -id- is not in -fmts-.
	private Format _didntFindId(int id)
	{
		Format result;
		result = new Format;
		result._id = id;
		result._name = getName(id);
		//synchronized // _init() would need to be synchronized with it.
		{
			fmts[id] = result;
		}
		return result;
	}
	
	
	///
	Format getFormat(int id)
	{
		_init();
		
		if(id in fmts)
			return fmts[id];
		
		return _didntFindId(id);
	}
	
	/// ditto
	// Creates the format name if it doesn't exist.
	Format getFormat(char[] name)
	{
		_init();
		foreach(Format onfmt; fmts)
		{
			if(!stringICmp(name, onfmt.name))
				return onfmt;
		}
		// Didn't find it.
		return _didntFindId(dfl.internal.utf.registerClipboardFormat(name));
	}
	
	/// ditto
	// Extra.
	Format getFormat(TypeInfo type)
	{
		return getFormatFromType(type);
	}
	
	
	private:
	Format[int] fmts; // Indexed by identifier. Must _init() before accessing!
	
	
	void _init()
	{
		if(fmts.length)
			return;
		
		
		void initfmt(int id, char[] name)
		in
		{
			assert(!(id in fmts));
		}
		body
		{
			Format fmt;
			fmt = new Format;
			fmt._id = id;
			fmt._name = name;
			fmts[id] = fmt;
		}
		
		
		initfmt(CF_BITMAP, "Bitmap");
		initfmt(CF_DIB, "DeviceIndependentBitmap");
		initfmt(CF_DIF, "DataInterchangeFormat");
		initfmt(CF_ENHMETAFILE, "EnhancedMetafile");
		initfmt(CF_HDROP, "FileDrop");
		initfmt(CF_LOCALE, "Locale");
		initfmt(CF_METAFILEPICT, "MetaFilePict");
		initfmt(CF_OEMTEXT, "OEMText");
		initfmt(CF_PALETTE, "Palette");
		initfmt(CF_PENDATA, "PenData");
		initfmt(CF_RIFF, "RiffAudio");
		initfmt(CF_SYLK, "SymbolicLink");
		initfmt(CF_TEXT, "Text");
		initfmt(CF_TIFF, "TaggedImageFileFormat");
		initfmt(CF_UNICODETEXT, "UnicodeText");
		initfmt(CF_WAVE, "WaveAudio");
		
		fmts.rehash;
	}
	
	
	// Does not get the name of one of the predefined constant ones.
	char[] getName(int id)
	{
		char[] result;
		result = dfl.internal.utf.getClipboardFormatName(id);
		if(!result.length)
			throw new DflException("Unable to get format");
		return result;
	}
	
	
	package Format getFormatFromType(TypeInfo type)
	{
		if(type == typeid(ubyte[]))
			return getFormat(text);
		if(type == typeid(char[]))
			return getFormat(stringFormat);
		if(type == typeid(wchar[]))
			return getFormat(unicodeText);
		//if(type == typeid(Bitmap))
		//	return getFormat(bitmap);
		
		if(cast(TypeInfo_Class)type)
			throw new DflException("Unknown data format");
		
		return getFormat(getObjectString(type)); // ?
	}
	
	
	private char[][] getHDropStrings(void[] value)
	{
		/+
		if(value.length != HDROP.sizeof)
			return null;
		
		HDROP hd;
		UINT num;
		char[][] result;
		size_t iw;
		
		hd = *cast(HDROP*)value.ptr;
		num = dragQueryFile(hd);
		if(!num)
			return null;
		result = new char[][num];
		for(iw = 0; iw != num; iw++)
		{
			result[iw] = dragQueryFile(hd, iw);
		}
		return result;
		+/
		
		if(value.length <= DROPFILES.sizeof)
			return null;
		
		char[][] result;
		DROPFILES* df;
		size_t iw, startiw;
		
		df = cast(DROPFILES*)value.ptr;
		if(df.pFiles < DROPFILES.sizeof || df.pFiles >= value.length)
			return null;
		
		if(df.fWide) // Unicode.
		{
			wchar[] uni = cast(wchar[])((value.ptr + df.pFiles)[0 .. value.length]);
			for(iw = startiw = 0;; iw++)
			{
				if(!uni[iw])
				{
					if(startiw == iw)
						break;
					result ~= fromUnicode(uni.ptr + startiw, iw - startiw);
					assert(result[result.length - 1].length);
					startiw = iw + 1;
				}
			}
		}
		else // ANSI.
		{
			char[] ansi = cast(char[])((value.ptr + df.pFiles)[0 .. value.length]);
			for(iw = startiw = 0;; iw++)
			{
				if(!ansi[iw])
				{
					if(startiw == iw)
						break;
					result ~= fromAnsi(ansi.ptr + startiw, iw - startiw);
					assert(result[result.length - 1].length);
					startiw = iw + 1;
				}
			}
		}
		
		return result;
	}
	
	
	// Convert clipboard -value- to Data.
	Data getDataFromFormat(int id, void[] value)
	{
		switch(id)
		{
			case CF_TEXT:
				return Data(stopAtNull!(ubyte)(cast(ubyte[])value));
			
			case CF_UNICODETEXT:
				return Data(stopAtNull!(wchar)(cast(wchar[])value));
			
			case CF_HDROP:
				return Data(getHDropStrings(value));
			
			default:
				if(id == getFormat(stringFormat).id)
					return Data(stopAtNull!(char)(cast(char[])value));
		}
		
		//throw new DflException("Unknown data format");
		return Data(value); // ?
	}
	
	
	void[] getCbFileDrop(char[][] fileNames)
	{
		size_t sz = DROPFILES.sizeof;
		void* p;
		DROPFILES* df;
		
		foreach(fn; fileNames)
		{
			sz += (dfl.internal.utf.toUnicodeLength(fn) + 1) << 1;
		}
		sz += 2;
		
		p = (new byte[sz]).ptr;
		df = cast(DROPFILES*)p;
		
		df.pFiles = DROPFILES.sizeof;
		df.fWide = TRUE;
		
		wchar* ws = cast(wchar*)(p + DROPFILES.sizeof);
		foreach(fn; fileNames)
		{
			foreach(wchar wch; fn)
			{
				*ws++ = wch;
			}
			*ws++ = 0;
		}
		*ws++ = 0;
		
		return p[0 .. sz];
	}
	
	
	// Value the clipboard wants.
	void[] getClipboardValueFromData(int id, Data data)
	{
		//if(data.info == typeid(ubyte[]))
		if(CF_TEXT == id)
		{
			// ANSI text.
			const ubyte[] UBYTE_ZERO = [0];
			return data.getText() ~ UBYTE_ZERO;
		}
		//else if(data.info == typeid(char[]))
		//else if(getFormat(stringFormat).id == id)
		else if((getFormat(stringFormat).id == id) || (data.info == typeid(char[])))
		{
			// UTF-8 string.
			char[] str;
			str = data.getString();
			//return toStringz(str)[0 .. str.length + 1];
			return unsafeStringz(str)[0 .. str.length + 1]; // ?
		}
		//else if(data.info == typeid(wchar[]))
		//else if(CF_UNICODETEXT == id)
		else if((CF_UNICODETEXT == id) || (data.info == typeid(wchar[])))
		{
			// Unicode string.
			return data.getUnicodeText() ~ cast(wchar[])\0;
		}
		else if(data.info == typeid(dchar[]))
		{
			return (*cast(dchar[]*)data.value) ~ \0;
		}
		else if(CF_HDROP == id)
		{
			return getCbFileDrop(data.getStrings());
		}
		else if(data.info == typeid(void[]) || data.info == typeid(char[])
			|| data.info == typeid(ubyte[]) || data.info == typeid(byte[])) // Hack ?
		{
			return *cast(void[]*)data.value; // Save the array elements, not the reference.
		}
		else
		{
			return data.value; // ?
		}
	}
	
	
	this()
	{
	}
}


private template stopAtNull(T)
{
	T[] stopAtNull(T[] array)
	{
		int i;
		for(i = 0; i != array.length; i++)
		{
			if(!array[i])
				return array[0 .. i];
		}
		//return null;
		throw new DflException("Invalid data"); // ?
	}
}


/// Data structure for holding data in a raw format with type information.
struct Data // docmain
{
	/// Information about the data type.
	TypeInfo info() // getter
	{
		return _info;
	}
	
	
	/// The data's raw value.
	void[] value() // getter
	{
		return _value[0 .. _info.tsize()];
	}
	
	
	/// Construct a new Data structure.
	static Data opCall(...)
	in
	{
		assert(_arguments.length == 1);
	}
	body
	{
		Data result;
		result._info = _arguments[0];
		result._value = _argptr[0 .. result._info.tsize()].dup.ptr;
		return result;
	}
	
	
	///
	T getValue(T)()
	{
		assert(_info.tsize == T.sizeof);
		return *cast(T*)_value;
	}
	
	/// ditto
	// UTF-8.
	char[] getString()
	{
		assert(_info == typeid(char[]) || _info == typeid(void[]));
		return *cast(char[]*)_value;
	}
	
	/// ditto
	alias getString getUtf8;
	/// ditto
	deprecated alias getString getUTF8;
	
	/// ditto
	// ANSI text.
	ubyte[] getText()
	{
		assert(_info == typeid(ubyte[]) || _info == typeid(byte[]) || _info == typeid(void[]));
		return *cast(ubyte[]*)_value;
	}
	
	/// ditto
	wchar[] getUnicodeText()
	{
		assert(_info == typeid(wchar[]) || _info == typeid(void[]));
		return *cast(wchar[]*)_value;
	}
	
	/// ditto
	int getInt()
	{
		return getValue!(int)();
	}
	
	/// ditto
	int getUint()
	{
		return getValue!(uint)();
	}
	
	/// ditto
	char[][] getStrings()
	{
		assert(_info == typeid(char[][]));
		return *cast(char[][]*)_value;
	}
	
	/// ditto
	Object getObject()
	{
		assert(!(cast(TypeInfo_Class)_info is null));
		return cast(Object)*cast(Object**)_value;
	}
	
	
	private:
	TypeInfo _info;
	void* _value;
}


/+
interface IDataFormat
{
	
}
+/


/// Interface to a data object. The data can have different formats by setting different formats.
interface IDataObject // docmain
{
	///
	Data getData(char[] fmt);
	/// ditto
	Data getData(TypeInfo type);
	/// ditto
	Data getData(char[] fmt, bool doConvert);
	
	///
	bool getDataPresent(char[] fmt); // Check.
	/// ditto
	bool getDataPresent(TypeInfo type); // Check.
	/// ditto
	bool getDataPresent(char[] fmt, bool canConvert); // Check.
	
	///
	char[][] getFormats();
	//char[][] getFormats(bool onlyNative);
	
	///
	void setData(Data obj);
	/// ditto
	void setData(char[] fmt, Data obj);
	/// ditto
	void setData(TypeInfo type, Data obj);
	/// ditto
	void setData(char[] fmt, bool canConvert, Data obj);
}


///
class DataObject: dfl.data.IDataObject // docmain
{
	///
	Data getData(char[] fmt)
	{
		return getData(fmt, true);
	}
	
	/// ditto
	Data getData(TypeInfo type)
	{
		return getData(DataFormats.getFormat(type).name);
	}
	
	/// ditto
	Data getData(char[] fmt, bool doConvert)
	{
		// doConvert ...
		
		//printf("Looking for format '%.*s'.\n", fmt);
		int i;
		i = find(fmt);
		if(i == -1)
			throw new DflException("Data format not present");
		return all[i].obj;
	}
	
	
	///
	bool getDataPresent(char[] fmt)
	{
		return getDataPresent(fmt, true);
	}
	
	/// ditto
	bool getDataPresent(TypeInfo type)
	{
		return getDataPresent(DataFormats.getFormat(type).name);
	}
	
	/// ditto
	bool getDataPresent(char[] fmt, bool canConvert)
	{
		// canConvert ...
		return find(fmt) != -1;
	}
	
	
	///
	char[][] getFormats()
	{
		char[][] result;
		result = new char[][all.length];
		foreach(int i, inout char[] fmt; result)
		{
			fmt = all[i].fmt;
		}
		return result;
	}
	
	
	// TO-DO: remove...
	deprecated final char[][] getFormats(bool onlyNative)
	{
		return getFormats();
	}
	
	
	package final void _setData(char[] fmt, Data obj, bool replace = true)
	{
		int i;
		i = find(fmt, false);
		if(i != -1)
		{
			if(replace)
				all[i].obj = obj;
		}
		else
		{
			Pair pair;
			pair.fmt = fmt;
			pair.obj = obj;
			all ~= pair;
		}
	}
	
	
	///
	void setData(Data obj)
	{
		setData(DataFormats.getFormat(obj.info).name, obj);
	}
	
	
	/// ditto
	void setData(char[] fmt, Data obj)
	{
		setData(fmt, true, obj);
	}
	
	
	/// ditto
	void setData(TypeInfo type, Data obj)
	{
		setData(DataFormats.getFormatFromType(type).name, true, obj);
	}
	
	
	/// ditto
	void setData(char[] fmt, bool canConvert, Data obj)
	{
		/+
		if(obj.info == typeid(Data))
		{
			void[] objv;
			objv = obj.value;
			assert(objv.length == Data.sizeof);
			obj = *(cast(Data*)objv.ptr);
		}
		+/
		
		_setData(fmt, obj);
		if(canConvert)
		{
			Data cdat;
			cdat = Data(*(cast(_DataConvert*)&obj));
			_canConvertFormats(fmt,
				(char[] cfmt)
				{
					_setData(cfmt, cdat, false);
				});
		}
	}
	
	
	private:
	struct Pair
	{
		char[] fmt;
		Data obj;
	}
	
	
	Pair[] all;
	
	
	void fixPairEntry(inout Pair pr)
	{
		assert(pr.obj.info == typeid(_DataConvert));
		Data obj;
		void[] objv;
		objv = pr.obj.value;
		assert(objv.length == Data.sizeof);
		obj = *(cast(Data*)objv.ptr);
		pr.obj = _doConvertFormat(obj, pr.fmt);
	}
	
	
	int find(char[] fmt, bool fix = true)
	{
		int i;
		for(i = 0; i != all.length; i++)
		{
			if(!stringICmp(all[i].fmt, fmt))
			{
				if(fix && all[i].obj.info == typeid(_DataConvert))
					fixPairEntry(all[i]);
				return i;
			}
		}
		return -1;
	}
}


private struct _DataConvert
{
	Data data;
}


package void _canConvertFormats(char[] fmt, void delegate(char[] cfmt) callback)
{
	//if(!stringICmp(fmt, DataFormats.utf8))
	if(!stringICmp(fmt, "UTF-8"))
	{
		callback(DataFormats.unicodeText);
		callback(DataFormats.text);
	}
	else if(!stringICmp(fmt, DataFormats.unicodeText))
	{
		//callback(DataFormats.utf8);
		callback("UTF-8");
		callback(DataFormats.text);
	}
	else if(!stringICmp(fmt, DataFormats.text))
	{
		//callback(DataFormats.utf8);
		callback("UTF-8");
		callback(DataFormats.unicodeText);
	}
}


package Data _doConvertFormat(Data dat, char[] toFmt)
{
	Data result;
	//if(!stringICmp(toFmt, DataFormats.utf8))
	if(!stringICmp(toFmt, "UTF-8"))
	{
		if(typeid(wchar[]) == dat.info)
		{
			result = Data(utf16stringtoUtf8string(dat.getUnicodeText()));
		}
		else if(typeid(ubyte[]) == dat.info)
		{
			ubyte[] ubs;
			ubs = dat.getText();
			result = Data(dfl.internal.utf.fromAnsi(cast(char*)ubs.ptr, ubs.length));
		}
	}
	else if(!stringICmp(toFmt, DataFormats.unicodeText))
	{
		if(typeid(char[]) == dat.info)
		{
			result = Data(utf8stringtoUtf16string(dat.getString()));
		}
		else if(typeid(ubyte[]) == dat.info)
		{
			ubyte[] ubs;
			ubs = dat.getText();
			result = Data(dfl.internal.utf.ansiToUnicode(cast(char*)ubs.ptr, ubs.length));
		}
	}
	else if(!stringICmp(toFmt, DataFormats.text))
	{
		if(typeid(char[]) == dat.info)
		{
			result = Data(cast(ubyte[])dfl.internal.utf.toAnsi(dat.getString()));
		}
		else if(typeid(wchar[]) == dat.info)
		{
			wchar[] wcs;
			wcs = dat.getUnicodeText();
			result = Data(cast(ubyte[])unicodeToAnsi(wcs.ptr, wcs.length));
		}
	}
	return result;
}


class ComToDdataObject: dfl.data.IDataObject // package
{
	this(dfl.internal.wincom.IDataObject dataObj)
	{
		this.dataObj = dataObj;
		dataObj.AddRef();
	}
	
	
	~this()
	{
		dataObj.Release(); // Must get called...
	}
	
	
	private Data _getData(int id)
	{
		FORMATETC fmte;
		STGMEDIUM stgm;
		void[] mem;
		void* plock;
		
		fmte.cfFormat = id;
		fmte.ptd = null;
		fmte.dwAspect = DVASPECT_CONTENT; // ?
		fmte.lindex = -1;
		fmte.tymed = TYMED_HGLOBAL; // ?
		
		if(S_OK != dataObj.GetData(&fmte, &stgm))
			throw new DflException("Unable to get data");
		
		
		void release()
		{
			//ReleaseStgMedium(&stgm);
			if(stgm.pUnkForRelease)
				stgm.pUnkForRelease.Release();
			else
				GlobalFree(stgm.hGlobal);
		}
		
		
		plock = GlobalLock(stgm.hGlobal);
		if(!plock)
		{
			release();
			throw new DflException("Error obtaining data");
		}
		
		mem = new ubyte[GlobalSize(stgm.hGlobal)];
		mem[] = plock[0 .. mem.length];
		GlobalUnlock(stgm.hGlobal);
		release();
		
		return DataFormats.getDataFromFormat(id, mem);
	}
	
	
	Data getData(char[] fmt)
	{
		return _getData(DataFormats.getFormat(fmt).id);
	}
	
	
	Data getData(TypeInfo type)
	{
		return _getData(DataFormats.getFormatFromType(type).id);
	}
	
	
	Data getData(char[] fmt, bool doConvert)
	{
		return getData(fmt); // ?
	}
	
	
	private bool _getDataPresent(int id)
	{
		FORMATETC fmte;
		
		fmte.cfFormat = id;
		fmte.ptd = null;
		fmte.dwAspect = DVASPECT_CONTENT; // ?
		fmte.lindex = -1;
		fmte.tymed = TYMED_HGLOBAL; // ?
		
		return S_OK == dataObj.QueryGetData(&fmte);
	}
	
	
	bool getDataPresent(char[] fmt)
	{
		return _getDataPresent(DataFormats.getFormat(fmt).id);
	}
	
	
	bool getDataPresent(TypeInfo type)
	{
		return _getDataPresent(DataFormats.getFormatFromType(type).id);
	}
	
	
	bool getDataPresent(char[] fmt, bool canConvert)
	{
		return getDataPresent(fmt); // ?
	}
	
	
	char[][] getFormats()
	{
		IEnumFORMATETC fenum;
		FORMATETC fmte;
		char[][] result;
		ULONG nfetched = 1; // ?
		
		if(S_OK != dataObj.EnumFormatEtc(1, &fenum))
			throw new DflException("Unable to get formats");
		
		fenum.AddRef(); // ?
		for(;;)
		{
			if(S_OK != fenum.Next(1, &fmte, &nfetched))
				break;
			if(!nfetched)
				break;
			//printf("\t\t{getFormats:%d}\n", fmte.cfFormat);
			result ~= DataFormats.getFormat(fmte.cfFormat).name;
		}
		fenum.Release(); // ?
		
		return result;
	}
	
	
	// TO-DO: remove...
	deprecated final char[][] getFormats(bool onlyNative)
	{
		return getFormats();
	}
	
	
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
			//printf("Unable to GlobalAlloc().\n");
			err_set:
			throw new DflException("Unable to set data");
		}
		pmem = GlobalLock(hmem);
		if(!pmem)
		{
			//printf("Unable to GlobalLock().\n");
			GlobalFree(hmem);
			goto err_set;
		}
		pmem[0 .. mem.length] = mem;
		GlobalUnlock(hmem);
		
		fmte.cfFormat = id;
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
			//printf("Unable to IDataObject::SetData() = %d (0x%X).\n", hr, hr);
			// Failed, need to free it..
			GlobalFree(hmem);
			goto err_set;
		}
		+/
		// Don't set stuff in someone else's data object.
	}
	
	
	void setData(Data obj)
	{
		_setData(DataFormats.getFormatFromType(obj.info).id, obj);
	}
	
	
	void setData(char[] fmt, Data obj)
	{
		_setData(DataFormats.getFormat(fmt).id, obj);
	}
	
	
	void setData(TypeInfo type, Data obj)
	{
		_setData(DataFormats.getFormatFromType(type).id, obj);
	}
	
	
	void setData(char[] fmt, bool canConvert, Data obj)
	{
		setData(fmt, obj); // ?
	}
	
	
	final bool isSameDataObject(dfl.internal.wincom.IDataObject dataObj)
	{
		return dataObj is this.dataObj;
	}
	
	
	private:
	dfl.internal.wincom.IDataObject dataObj;
}


package class EnumDataObjectFORMATETC: DflComObject, IEnumFORMATETC
{
	this(dfl.data.IDataObject dataObj, char[][] fmts, ULONG start)
	{
		this.dataObj = dataObj;
		this.fmts = fmts;
		idx = start;
	}
	
	
	this(dfl.data.IDataObject dataObj)
	{
		this(dataObj, dataObj.getFormats(), 0);
	}
	
	
	extern(Windows):
	override HRESULT QueryInterface(IID* riid, void** ppv)
	{
		if(*riid == _IID_IEnumFORMATETC)
		{
			*ppv = cast(void*)cast(IEnumFORMATETC)this;
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
	
	
	HRESULT Next(ULONG celt, FORMATETC* rgelt, ULONG* pceltFetched)
	{
		HRESULT result;
		
		try
		{
			if(idx < fmts.length)
			{
				ULONG end;
				end = idx + celt;
				if(end > fmts.length)
				{
					result = S_FALSE; // ?
					end = fmts.length;
					
					if(pceltFetched)
						*pceltFetched = end - idx;
				}
				else
				{
					result = S_OK;
					
					if(pceltFetched)
						*pceltFetched = celt;
				}
				
				for(; idx != end; idx++)
				{
					rgelt.cfFormat = DataFormats.getFormat(fmts[idx]).id;
					rgelt.ptd = null;
					rgelt.dwAspect = DVASPECT_CONTENT; // ?
					rgelt.lindex = -1;
					//rgelt.tymed = TYMED_NULL;
					rgelt.tymed = TYMED_HGLOBAL;
					
					rgelt++;
				}
			}
			else
			{
				if(pceltFetched)
					*pceltFetched = 0;
				result = S_FALSE;
			}
		}
		catch(Object e)
		{
			Application.onThreadException(e);
			
			result = E_UNEXPECTED;
		}
		
		return result;
	}
	
	
	HRESULT Skip(ULONG celt)
	{
		idx += celt;
		return (idx > fmts.length) ? S_FALSE : S_OK;
	}
	
	
	HRESULT Reset()
	{
		HRESULT result;
		
		try
		{
			idx = 0;
			fmts = dataObj.getFormats();
			
			result = S_OK;
		}
		catch(Object e)
		{
			Application.onThreadException(e);
			
			result = E_UNEXPECTED;
		}
		
		return result;
	}
	
	
	HRESULT Clone(IEnumFORMATETC* ppenum)
	{
		HRESULT result;
		
		try
		{
			*ppenum = new EnumDataObjectFORMATETC(dataObj, fmts, idx);
			result = S_OK;
		}
		catch(Object e)
		{
			Application.onThreadException(e);
			
			result = E_UNEXPECTED;
		}
		
		return result;
	}
	
	
	extern(D):
	
	private:
	dfl.data.IDataObject dataObj;
	char[][] fmts;
	ULONG idx;
}


class DtoComDataObject: DflComObject, dfl.internal.wincom.IDataObject // package
{
	this(dfl.data.IDataObject dataObj)
	{
		this.dataObj = dataObj;
	}
	
	
	extern(Windows):
	
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
	
	
	HRESULT GetData(FORMATETC* pFormatetc, STGMEDIUM* pmedium)
	{
		char[] fmt;
		HRESULT result = S_OK;
		Data data;
		
		try
		{
			if(pFormatetc.lindex != -1)
			{
				result = DV_E_LINDEX;
			}
			else if(!(pFormatetc.tymed & TYMED_HGLOBAL))
			{
				// Unsupported medium type.
				result = DV_E_TYMED;
			}
			else if(!(pFormatetc.dwAspect & DVASPECT_CONTENT))
			{
				// What about the other aspects?
				result = DV_E_DVASPECT;
			}
			else
			{
				DataFormats.Format dfmt;
				dfmt = DataFormats.getFormat(pFormatetc.cfFormat);
				fmt = dfmt.name;
				data = dataObj.getData(fmt, true); // Should this be convertable?
				
				HGLOBAL hg;
				void* pmem;
				void[] src;
				
				//src = data.value;
				src = DataFormats.getClipboardValueFromData(dfmt.id, data);
				hg = GlobalAlloc(GMEM_SHARE, src.length);
				if(!hg)
				{
					result = STG_E_MEDIUMFULL;
				}
				else
				{
					pmem = GlobalLock(hg);
					if(!hg)
					{
						result = E_UNEXPECTED;
						GlobalFree(hg);
					}
					else
					{
						pmem[0 .. src.length] = src;
						GlobalUnlock(hg);
						
						pmedium.tymed = TYMED_HGLOBAL;
						pmedium.hGlobal = hg;
						pmedium.pUnkForRelease = null; // ?
					}
				}
			}
		}
		catch(DflException e)
		{
			//Application.onThreadException(e);
			
			result = DV_E_FORMATETC;
		}
		catch(OomException e)
		{
			Application.onThreadException(e);
			
			result = E_OUTOFMEMORY;
		}
		catch(Object e)
		{
			Application.onThreadException(e);
			
			result = E_UNEXPECTED;
		}
		
		return result;
	}
	
	
	HRESULT GetDataHere(FORMATETC* pFormatetc, STGMEDIUM* pmedium)
	{
		return E_UNEXPECTED; // TODO: finish.
	}
	
	
	HRESULT QueryGetData(FORMATETC* pFormatetc)
	{
		char[] fmt;
		HRESULT result = S_OK;
		
		try
		{
			if(pFormatetc.lindex != -1)
			{
				result = DV_E_LINDEX;
			}
			else if(!(pFormatetc.tymed & TYMED_HGLOBAL))
			{
				// Unsupported medium type.
				result = DV_E_TYMED;
			}
			else if(!(pFormatetc.dwAspect & DVASPECT_CONTENT))
			{
				// What about the other aspects?
				result = DV_E_DVASPECT;
			}
			else
			{
				fmt = DataFormats.getFormat(pFormatetc.cfFormat).name;
				
				if(!dataObj.getDataPresent(fmt))
					result = S_FALSE; // ?
			}
		}
		catch(DflException e)
		{
			//Application.onThreadException(e);
			
			result = DV_E_FORMATETC;
		}
		catch(OomException e)
		{
			Application.onThreadException(e);
			
			result = E_OUTOFMEMORY;
		}
		catch(Object e)
		{
			Application.onThreadException(e);
			
			result = E_UNEXPECTED;
		}
		
		return result;
	}
	
	
	HRESULT GetCanonicalFormatEtc(FORMATETC* pFormatetcIn, FORMATETC* pFormatetcOut)
	{
		// TODO: finish.
		
		pFormatetcOut.ptd = null;
		return E_NOTIMPL;
	}
	
	
	HRESULT SetData(FORMATETC* pFormatetc, STGMEDIUM* pmedium, BOOL fRelease)
	{
		return E_UNEXPECTED; // TODO: finish.
	}
	
	
	HRESULT EnumFormatEtc(DWORD dwDirection, IEnumFORMATETC* ppenumFormatetc)
	{
		// SHCreateStdEnumFmtEtc() requires Windows 2000 +
		
		HRESULT result;
		
		try
		{
			if(dwDirection == DATADIR_GET)
			{
				*ppenumFormatetc = new EnumDataObjectFORMATETC(dataObj);
				result = S_OK;
			}
			else
			{
				result = E_NOTIMPL;
			}
		}
		catch(Object e)
		{
			Application.onThreadException(e);
			
			result = E_UNEXPECTED;
		}
		
		return result;
	}
	
	
	HRESULT DAdvise(FORMATETC* pFormatetc, DWORD advf, IAdviseSink pAdvSink, DWORD* pdwConnection)
	{
		return E_UNEXPECTED; // TODO: finish.
	}
	
	
	HRESULT DUnadvise(DWORD dwConnection)
	{
		return E_UNEXPECTED; // TODO: finish.
	}
	
	
	HRESULT EnumDAdvise(IEnumSTATDATA* ppenumAdvise)
	{
		return E_UNEXPECTED; // TODO: finish.
	}
	
	
	extern(D):
	
	private:
	dfl.data.IDataObject dataObj;
}

