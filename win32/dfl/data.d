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
		final @property int id() // getter
		{
			return _id;
		}
		
		
		/// Data format name.
		final @property Dstring name() // getter
		{
			return _name;
		}
		
		
		package:
		int _id;
		Dstring _name;
		
		
		this()
		{
		}
	}
	
	
	static:
	
	/// Predefined data formats.
	@property Dstring bitmap() // getter
	{
		return getFormat(CF_BITMAP).name;
	}
	
	/+
	/// ditto
	@property Dstring commaSeparatedValue() // getter
	{
		return getFormat(?).name;
	}
	+/
	
	/// ditto
	@property Dstring dib() // getter
	{
		return getFormat(CF_DIB).name;
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
	@property Dstring html() // getter
	{
		return getFormat("HTML Format").name;
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
	@property Dstring rtf() // getter
	{
		return getFormat("Rich Text Format").name;
	}
	
	
	/+
	/// ditto
	@property Dstring serializable() // getter
	{
		return getFormat(?).name;
	}
	+/
	
	/// ditto
	@property Dstring stringFormat() // getter
	{
		return utf8; // ?
	}
	
	/// ditto
	@property Dstring utf8() // getter
	{
		return getFormat("UTF-8").name;
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
	Format getFormat(Dstring name)
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
		
		
		void initfmt(int id, Dstring name)
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
	Dstring getName(int id)
	{
		Dstring result;
		result = dfl.internal.utf.getClipboardFormatName(id);
		if(!result.length)
			throw new DflException("Unable to get format");
		return result;
	}
	
	
	package Format getFormatFromType(TypeInfo type)
	{
		if(type == typeid(ubyte[]))
			return getFormat(text);
		if(type == typeid(Dstring))
			return getFormat(stringFormat);
		if(type == typeid(Dwstring))
			return getFormat(unicodeText);
		//if(type == typeid(Bitmap))
		//	return getFormat(bitmap);
		
		if(cast(TypeInfo_Class)type)
			throw new DflException("Unknown data format");
		
		return getFormat(getObjectString(type)); // ?
	}
	
	
	private Dstring[] getHDropStrings(void[] value)
	{
		/+
		if(value.length != HDROP.sizeof)
			return null;
		
		HDROP hd;
		UINT num;
		Dstring[] result;
		size_t iw;
		
		hd = *cast(HDROP*)value.ptr;
		num = dragQueryFile(hd);
		if(!num)
			return null;
		result = new Dstring[num];
		for(iw = 0; iw != num; iw++)
		{
			result[iw] = dragQueryFile(hd, iw);
		}
		return result;
		+/
		
		if(value.length <= DROPFILES.sizeof)
			return null;
		
		Dstring[] result;
		DROPFILES* df;
		size_t iw, startiw;
		
		df = cast(DROPFILES*)value.ptr;
		if(df.pFiles < DROPFILES.sizeof || df.pFiles >= value.length)
			return null;
		
		if(df.fWide) // Unicode.
		{
			Dwstring uni = cast(Dwstring)((value.ptr + df.pFiles)[0 .. value.length]);
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
			Dstring ansi = cast(Dstring)((value.ptr + df.pFiles)[0 .. value.length]);
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
				return Data(stopAtNull!(Dwchar)(cast(Dwstring)value));
			
			case CF_HDROP:
				return Data(getHDropStrings(value));
			
			default:
				if(id == getFormat(stringFormat).id)
					return Data(stopAtNull!(Dchar)(cast(Dstring)value));
		}
		
		//throw new DflException("Unknown data format");
		return Data(value); // ?
	}
	
	
	void[] getCbFileDrop(Dstring[] fileNames)
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
			enum ubyte[] UBYTE_ZERO = [0];
			return data.getText() ~ UBYTE_ZERO;
		}
		//else if(data.info == typeid(Dstring))
		//else if(getFormat(stringFormat).id == id)
		else if((getFormat(stringFormat).id == id) || (data.info == typeid(Dstring)))
		{
			// UTF-8 string.
			Dstring str;
			str = data.getString();
			//return toStringz(str)[0 .. str.length + 1];
			//return unsafeStringz(str)[0 .. str.length + 1]; // ?
			return cast(void[])unsafeStringz(str)[0 .. str.length + 1]; // ? Needed in D2.
		}
		//else if(data.info == typeid(Dwstring))
		//else if(CF_UNICODETEXT == id)
		else if((CF_UNICODETEXT == id) || (data.info == typeid(Dwstring)))
		{
			// Unicode string.
			//return data.getUnicodeText() ~ cast(Dwstring)"\0";
			//return cast(void[])(data.getUnicodeText() ~ cast(Dwstring)"\0"); // Needed in D2. Not guaranteed safe.
			return (data.getUnicodeText() ~ cast(Dwstring)"\0").dup; // Needed in D2.
		}
		else if(data.info == typeid(Ddstring))
		{
			//return (*cast(Ddstring*)data.value) ~ "\0";
			//return cast(void[])((*cast(Ddstring*)data.value) ~ "\0"); // Needed in D2. Not guaranteed safe.
			return ((*cast(Ddstring*)data.value) ~ "\0").dup; // Needed in D2.
		}
		else if(CF_HDROP == id)
		{
			return getCbFileDrop(data.getStrings());
		}
		else if(data.info == typeid(void[]) || data.info == typeid(Dstring)
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
	@property TypeInfo info() // getter
	{
		return _info;
	}
	
	
	/// The data's raw value.
	@property void[] value() // getter
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
	Dstring getString()
	{
		assert(_info == typeid(Dstring) || _info == typeid(void[]));
		return *cast(Dstring*)_value;
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
	Dwstring getUnicodeText()
	{
		assert(_info == typeid(Dwstring) || _info == typeid(void[]));
		return *cast(Dwstring*)_value;
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
	Dstring[] getStrings()
	{
		assert(_info == typeid(Dstring[]));
		return *cast(Dstring[]*)_value;
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
	Data getData(Dstring fmt);
	/// ditto
	Data getData(TypeInfo type);
	/// ditto
	Data getData(Dstring fmt, bool doConvert);
	
	///
	bool getDataPresent(Dstring fmt); // Check.
	/// ditto
	bool getDataPresent(TypeInfo type); // Check.
	/// ditto
	bool getDataPresent(Dstring fmt, bool canConvert); // Check.
	
	///
	Dstring[] getFormats();
	//Dstring[] getFormats(bool onlyNative);
	
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
class DataObject: dfl.data.IDataObject // docmain
{
	///
	Data getData(Dstring fmt)
	{
		return getData(fmt, true);
	}
	
	/// ditto
	Data getData(TypeInfo type)
	{
		return getData(DataFormats.getFormat(type).name);
	}
	
	/// ditto
	Data getData(Dstring fmt, bool doConvert)
	{
		// doConvert ...
		
		//cprintf("Looking for format '%.*s'.\n", fmt);
		int i;
		i = find(fmt);
		if(i == -1)
			throw new DflException("Data format not present");
		return all[i].obj;
	}
	
	
	///
	bool getDataPresent(Dstring fmt)
	{
		return getDataPresent(fmt, true);
	}
	
	/// ditto
	bool getDataPresent(TypeInfo type)
	{
		return getDataPresent(DataFormats.getFormat(type).name);
	}
	
	/// ditto
	bool getDataPresent(Dstring fmt, bool canConvert)
	{
		// canConvert ...
		return find(fmt) != -1;
	}
	
	
	///
	Dstring[] getFormats()
	{
		Dstring[] result;
		result = new Dstring[all.length];
		foreach(int i, ref Dstring fmt; result)
		{
			fmt = all[i].fmt;
		}
		return result;
	}
	
	
	// TO-DO: remove...
	deprecated final Dstring[] getFormats(bool onlyNative)
	{
		return getFormats();
	}
	
	
	package final void _setData(Dstring fmt, Data obj, bool replace = true)
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
	void setData(Dstring fmt, Data obj)
	{
		setData(fmt, true, obj);
	}
	
	
	/// ditto
	void setData(TypeInfo type, Data obj)
	{
		setData(DataFormats.getFormatFromType(type).name, true, obj);
	}
	
	
	/// ditto
	void setData(Dstring fmt, bool canConvert, Data obj)
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
				(Dstring cfmt)
				{
					_setData(cfmt, cdat, false);
				});
		}
	}
	
	
	private:
	struct Pair
	{
		Dstring fmt;
		Data obj;
	}
	
	
	Pair[] all;
	
	
	void fixPairEntry(ref Pair pr)
	{
		assert(pr.obj.info == typeid(_DataConvert));
		Data obj;
		void[] objv;
		objv = pr.obj.value;
		assert(objv.length == Data.sizeof);
		obj = *(cast(Data*)objv.ptr);
		pr.obj = _doConvertFormat(obj, pr.fmt);
	}
	
	
	int find(Dstring fmt, bool fix = true)
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


package void _canConvertFormats(Dstring fmt, void delegate(Dstring cfmt) callback)
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


package Data _doConvertFormat(Data dat, Dstring toFmt)
{
	Data result;
	//if(!stringICmp(toFmt, DataFormats.utf8))
	if(!stringICmp(toFmt, "UTF-8"))
	{
		if(typeid(Dwstring) == dat.info)
		{
			result = Data(utf16stringtoUtf8string(dat.getUnicodeText()));
		}
		else if(typeid(ubyte[]) == dat.info)
		{
			ubyte[] ubs;
			ubs = dat.getText();
			result = Data(dfl.internal.utf.fromAnsi(cast(Dstringz)ubs.ptr, ubs.length));
		}
	}
	else if(!stringICmp(toFmt, DataFormats.unicodeText))
	{
		if(typeid(Dstring) == dat.info)
		{
			result = Data(utf8stringtoUtf16string(dat.getString()));
		}
		else if(typeid(ubyte[]) == dat.info)
		{
			ubyte[] ubs;
			ubs = dat.getText();
			result = Data(dfl.internal.utf.ansiToUnicode(cast(Dstringz)ubs.ptr, ubs.length));
		}
	}
	else if(!stringICmp(toFmt, DataFormats.text))
	{
		if(typeid(Dstring) == dat.info)
		{
			result = Data(cast(ubyte[])dfl.internal.utf.toAnsi(dat.getString()));
		}
		else if(typeid(Dwstring) == dat.info)
		{
			Dwstring wcs;
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
		
		fmte.cfFormat = cast(CLIPFORMAT)id;
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
	
	
	Data getData(Dstring fmt)
	{
		return _getData(DataFormats.getFormat(fmt).id);
	}
	
	
	Data getData(TypeInfo type)
	{
		return _getData(DataFormats.getFormatFromType(type).id);
	}
	
	
	Data getData(Dstring fmt, bool doConvert)
	{
		return getData(fmt); // ?
	}
	
	
	private bool _getDataPresent(int id)
	{
		FORMATETC fmte;
		
		fmte.cfFormat = cast(CLIPFORMAT)id;
		fmte.ptd = null;
		fmte.dwAspect = DVASPECT_CONTENT; // ?
		fmte.lindex = -1;
		fmte.tymed = TYMED_HGLOBAL; // ?
		
		return S_OK == dataObj.QueryGetData(&fmte);
	}
	
	
	bool getDataPresent(Dstring fmt)
	{
		return _getDataPresent(DataFormats.getFormat(fmt).id);
	}
	
	
	bool getDataPresent(TypeInfo type)
	{
		return _getDataPresent(DataFormats.getFormatFromType(type).id);
	}
	
	
	bool getDataPresent(Dstring fmt, bool canConvert)
	{
		return getDataPresent(fmt); // ?
	}
	
	
	Dstring[] getFormats()
	{
		IEnumFORMATETC fenum;
		FORMATETC fmte;
		Dstring[] result;
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
			//cprintf("\t\t{getFormats:%d}\n", fmte.cfFormat);
			result ~= DataFormats.getFormat(fmte.cfFormat).name;
		}
		fenum.Release(); // ?
		
		return result;
	}
	
	
	// TO-DO: remove...
	deprecated final Dstring[] getFormats(bool onlyNative)
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
	}
	
	
	void setData(Data obj)
	{
		_setData(DataFormats.getFormatFromType(obj.info).id, obj);
	}
	
	
	void setData(Dstring fmt, Data obj)
	{
		_setData(DataFormats.getFormat(fmt).id, obj);
	}
	
	
	void setData(TypeInfo type, Data obj)
	{
		_setData(DataFormats.getFormatFromType(type).id, obj);
	}
	
	
	void setData(Dstring fmt, bool canConvert, Data obj)
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
	this(dfl.data.IDataObject dataObj, Dstring[] fmts, ULONG start)
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
					rgelt.cfFormat = cast(CLIPFORMAT)DataFormats.getFormat(fmts[idx]).id;
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
		catch(DThrowable e)
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
		catch(DThrowable e)
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
		catch(DThrowable e)
		{
			Application.onThreadException(e);
			
			result = E_UNEXPECTED;
		}
		
		return result;
	}
	
	
	extern(D):
	
	private:
	dfl.data.IDataObject dataObj;
	Dstring[] fmts;
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
		Dstring fmt;
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
						pmem[0 .. src.length] = src[];
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
		catch(DThrowable e)
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
		Dstring fmt;
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
		catch(DThrowable e)
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
		catch(DThrowable e)
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

