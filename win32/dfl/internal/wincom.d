// This module just contains things that are needed but aren't in std.c.windows.com.
// This code is public domain.

module dfl.internal.wincom;

private import dfl.internal.winapi;


version(WINE)
	version = _dfl_needcom;

version(_dfl_needcom)
{
	private import dfl.internal.dlib;
	
	// Grabbed from std.c.windows.com:
	
	alias WCHAR OLECHAR;
	alias OLECHAR *LPOLESTR;
	alias OLECHAR *LPCOLESTR;
	
	enum
	{
		rmm = 23,	// OLE 2 version number info
		rup = 639,
	}
	
	enum : int
	{
		S_OK = 0,
		S_FALSE = 0x00000001,
		NOERROR = 0,
		E_NOTIMPL     = cast(int)0x80004001,
		E_NOINTERFACE = cast(int)0x80004002,
		E_POINTER     = cast(int)0x80004003,
		E_ABORT       = cast(int)0x80004004,
		E_FAIL        = cast(int)0x80004005,
		E_HANDLE      = cast(int)0x80070006,
		CLASS_E_NOAGGREGATION = cast(int)0x80040110,
		E_OUTOFMEMORY = cast(int)0x8007000E,
		E_INVALIDARG  = cast(int)0x80070057,
		E_UNEXPECTED  = cast(int)0x8000FFFF,
	}
	
	struct GUID {          // size is 16
		 align(1):
		DWORD Data1;
		WORD  Data2;
		WORD  Data3;
		BYTE  Data4[8];
	}
	
	enum
	{
		CLSCTX_INPROC_SERVER	= 0x1,
		CLSCTX_INPROC_HANDLER	= 0x2,
		CLSCTX_LOCAL_SERVER	= 0x4,
		CLSCTX_INPROC_SERVER16	= 0x8,
		CLSCTX_REMOTE_SERVER	= 0x10,
		CLSCTX_INPROC_HANDLER16	= 0x20,
		CLSCTX_INPROC_SERVERX86	= 0x40,
		CLSCTX_INPROC_HANDLERX86 = 0x80,
	
		CLSCTX_INPROC = (CLSCTX_INPROC_SERVER|CLSCTX_INPROC_HANDLER),
		CLSCTX_ALL = (CLSCTX_INPROC_SERVER| CLSCTX_INPROC_HANDLER| CLSCTX_LOCAL_SERVER),
		CLSCTX_SERVER = (CLSCTX_INPROC_SERVER|CLSCTX_LOCAL_SERVER),
	}
	
	alias GUID IID;
	alias GUID CLSID;
	
	extern (C)
	{
		 extern IID IID_IUnknown;
		 extern IID IID_IClassFactory;
		 extern IID IID_IMarshal;
		 extern IID IID_IMallocSpy;
		 extern IID IID_IStdMarshalInfo;
		 extern IID IID_IExternalConnection;
		 extern IID IID_IMultiQI;
		 extern IID IID_IEnumUnknown;
		 extern IID IID_IBindCtx;
		 extern IID IID_IEnumMoniker;
		 extern IID IID_IRunnableObject;
		 extern IID IID_IRunningObjectTable;
		 extern IID IID_IPersist;
		 extern IID IID_IPersistStream;
		 extern IID IID_IMoniker;
		 extern IID IID_IROTData;
		 extern IID IID_IEnumString;
		 extern IID IID_ISequentialStream;
		 extern IID IID_IStream;
		 extern IID IID_IEnumSTATSTG;
		 extern IID IID_IStorage;
		 extern IID IID_IPersistFile;
		 extern IID IID_IPersistStorage;
		 extern IID IID_ILockBytes;
		 extern IID IID_IEnumFORMATETC;
		 extern IID IID_IEnumSTATDATA;
		 extern IID IID_IRootStorage;
		 extern IID IID_IAdviseSink;
		 extern IID IID_IAdviseSink2;
		 extern IID IID_IDataObject;
		 extern IID IID_IDataAdviseHolder;
		 extern IID IID_IMessageFilter;
		 extern IID IID_IRpcChannelBuffer;
		 extern IID IID_IRpcProxyBuffer;
		 extern IID IID_IRpcStubBuffer;
		 extern IID IID_IPSFactoryBuffer;
		 extern IID IID_IPropertyStorage;
		 extern IID IID_IPropertySetStorage;
		 extern IID IID_IEnumSTATPROPSTG;
		 extern IID IID_IEnumSTATPROPSETSTG;
		 extern IID IID_IFillLockBytes;
		 extern IID IID_IProgressNotify;
		 extern IID IID_ILayoutStorage;
		 extern IID GUID_NULL;
		 extern IID IID_IRpcChannel;
		 extern IID IID_IRpcStub;
		 extern IID IID_IStubManager;
		 extern IID IID_IRpcProxy;
		 extern IID IID_IProxyManager;
		 extern IID IID_IPSFactory;
		 extern IID IID_IInternalMoniker;
		 extern IID IID_IDfReserved1;
		 extern IID IID_IDfReserved2;
		 extern IID IID_IDfReserved3;
		 extern IID IID_IStub;
		 extern IID IID_IProxy;
		 extern IID IID_IEnumGeneric;
		 extern IID IID_IEnumHolder;
		 extern IID IID_IEnumCallback;
		 extern IID IID_IOleManager;
		 extern IID IID_IOlePresObj;
		 extern IID IID_IDebug;
		 extern IID IID_IDebugStream;
		 extern IID IID_StdOle;
		 extern IID IID_ICreateTypeInfo;
		 extern IID IID_ICreateTypeInfo2;
		 extern IID IID_ICreateTypeLib;
		 extern IID IID_ICreateTypeLib2;
		 extern IID IID_IDispatch;
		 extern IID IID_IEnumVARIANT;
		 extern IID IID_ITypeComp;
		 extern IID IID_ITypeInfo;
		 extern IID IID_ITypeInfo2;
		 extern IID IID_ITypeLib;
		 extern IID IID_ITypeLib2;
		 extern IID IID_ITypeChangeEvents;
		 extern IID IID_IErrorInfo;
		 extern IID IID_ICreateErrorInfo;
		 extern IID IID_ISupportErrorInfo;
		 extern IID IID_IOleAdviseHolder;
		 extern IID IID_IOleCache;
		 extern IID IID_IOleCache2;
		 extern IID IID_IOleCacheControl;
		 extern IID IID_IParseDisplayName;
		 extern IID IID_IOleContainer;
		 extern IID IID_IOleClientSite;
		 extern IID IID_IOleObject;
		 extern IID IID_IOleWindow;
		 extern IID IID_IOleLink;
		 extern IID IID_IOleItemContainer;
		 extern IID IID_IOleInPlaceUIWindow;
		 extern IID IID_IOleInPlaceActiveObject;
		 extern IID IID_IOleInPlaceFrame;
		 extern IID IID_IOleInPlaceObject;
		 extern IID IID_IOleInPlaceSite;
		 extern IID IID_IContinue;
		 extern IID IID_IViewObject;
		 extern IID IID_IViewObject2;
		 extern IID IID_IDropSource;
		 extern IID IID_IDropTarget;
		 extern IID IID_IEnumOLEVERB;
	}
	
	extern (Windows)
	{
	
	export
	{
	DWORD   CoBuildVersion();
	
	int StringFromGUID2(GUID *rguid, LPOLESTR lpsz, int cbMax);
	
	/* init/uninit */
	
	HRESULT CoInitialize(LPVOID pvReserved);
	void    CoUninitialize();
	DWORD   CoGetCurrentProcess();
	
	
	HRESULT CoCreateInstance(CLSID *rclsid, IUnknown UnkOuter,
							  DWORD dwClsContext, IID* riid, void* ppv);
	
	//HINSTANCE CoLoadLibrary(LPOLESTR lpszLibName, BOOL bAutoFree);
	void    CoFreeLibrary(HINSTANCE hInst);
	void    CoFreeAllLibraries();
	void    CoFreeUnusedLibraries();
	}
	
	interface IUnknown
	{
		 HRESULT QueryInterface(IID* riid, void** pvObject);
		 ULONG AddRef();
		 ULONG Release();
	}
	
	interface IClassFactory : IUnknown
	{
		 HRESULT CreateInstance(IUnknown UnkOuter, IID* riid, void** pvObject);
		 HRESULT LockServer(BOOL fLock);
	}
	
	class ComObject : IUnknown
	{
	extern (Windows):
		 HRESULT QueryInterface(IID* riid, void** ppv)
		 {
		if (*riid == IID_IUnknown)
		{
			 *ppv = cast(void*)cast(IUnknown)this;
			 AddRef();
			 return S_OK;
		}
		else
		{   *ppv = null;
			 return E_NOINTERFACE;
		}
		 }
	
		 ULONG AddRef()
		 {
		return InterlockedIncrement(&count);
		 }
	
		 ULONG Release()
		 {
		LONG lRef = InterlockedDecrement(&count);
		if (lRef == 0)
		{
			 // free object
	
			 // If we delete this object, then the postinvariant called upon
			 // return from Release() will fail.
			 // Just let the GC reap it.
			 //delete this;
	
			 return 0;
		}
		return cast(ULONG)lRef;
		 }
	
		 LONG count = 0;		// object reference count
	}
	
	}
}
else
{
	public import std.c.windows.com;
}


extern(C)
{
	extern IID IID_IPicture;
	
	version(REDEFINE_UUIDS)
	{
		// These are needed because uuid.lib is broken in DMC 8.46.
		IID _IID_IUnknown= { 0, 0, 0, [ 192, 0, 0, 0, 0, 0, 0, 70] };
		IID _IID_IDataObject = { 270, 0, 0, [192, 0, 0, 0, 0, 0, 0, 70 ] };
		IID _IID_IPicture = { 2079852928, 48946, 4122, [139, 187, 0, 170, 0, 48, 12, 171] };
		IID _IID_ISequentialStream = { 208878128, 10780, 4558, [ 173, 229, 0, 170, 0, 68, 119, 61 ] };
		IID _IID_IStream = { 12, 0, 0, [ 192, 0, 0, 0, 0, 0, 0, 70 ] };
		IID _IID_IDropTarget = { 290, 0, 0, [ 192, 0, 0, 0, 0, 0, 0, 70 ] };
		IID _IID_IDropSource = { 289, 0, 0, [ 192, 0, 0, 0, 0, 0, 0, 70 ] };
		IID _IID_IEnumFORMATETC = { 259, 0, 0, [ 192, 0, 0, 0, 0, 0, 0, 70 ] };
	}
	else
	{
		alias IID_IUnknown _IID_IUnknown;
		alias IID_IDataObject _IID_IDataObject;
		alias IID_IPicture _IID_IPicture;
		alias IID_ISequentialStream _IID_ISequentialStream;
		alias IID_IStream _IID_IStream;
		alias IID_IDropTarget _IID_IDropTarget;
		alias IID_IDropSource _IID_IDropSource;
		alias IID_IEnumFORMATETC _IID_IEnumFORMATETC;
	}
}


extern(Windows):

interface ISequentialStream: IUnknown
{
	extern(Windows):
	HRESULT Read(void* pv, ULONG cb, ULONG* pcbRead);
	HRESULT Write(void* pv, ULONG cb, ULONG* pcbWritten);
}


/// STREAM_SEEK
enum: DWORD
{
	STREAM_SEEK_SET = 0,
	STREAM_SEEK_CUR = 1,
	STREAM_SEEK_END = 2,
}
alias DWORD STREAM_SEEK;


// TODO: implement the enum`s used here.
struct STATSTG
{
	LPWSTR pwcsName;
	DWORD type;
	ULARGE_INTEGER cbSize;
	FILETIME mtime;
	FILETIME ctime;
	FILETIME atime;
	DWORD grfMode;
	DWORD grfLocksSupported;
	CLSID clsid;
	DWORD grfStateBits;
	DWORD reserved;
}


interface IStream: ISequentialStream
{
	extern(Windows):
	HRESULT Seek(LARGE_INTEGER dlibMove, DWORD dwOrigin, ULARGE_INTEGER* plibNewPosition);
	HRESULT SetSize(ULARGE_INTEGER libNewSize);
	HRESULT CopyTo(IStream pstm, ULARGE_INTEGER cb, ULARGE_INTEGER* pcbRead, ULARGE_INTEGER* pcbWritten);
	HRESULT Commit(DWORD grfCommitFlags);
	HRESULT Revert();
	HRESULT LockRegion(ULARGE_INTEGER libOffset, ULARGE_INTEGER cb, DWORD dwLockType);
	HRESULT UnlockRegion(ULARGE_INTEGER libOffset, ULARGE_INTEGER cb, DWORD dwLockType);
	HRESULT Stat(STATSTG* pstatstg, DWORD grfStatFlag);
	HRESULT Clone(IStream* ppstm);
}
alias IStream* LPSTREAM;


alias UINT OLE_HANDLE;

alias LONG OLE_XPOS_HIMETRIC;

alias LONG OLE_YPOS_HIMETRIC;

alias LONG OLE_XSIZE_HIMETRIC;

alias LONG OLE_YSIZE_HIMETRIC;


interface IPicture: IUnknown
{
	extern(Windows):
	HRESULT get_Handle(OLE_HANDLE* phandle);
	HRESULT get_hPal(OLE_HANDLE* phpal);
	HRESULT get_Type(short* ptype);
	HRESULT get_Width(OLE_XSIZE_HIMETRIC* pwidth);
	HRESULT get_Height(OLE_YSIZE_HIMETRIC* pheight);
	HRESULT Render(HDC hdc, int x, int y, int cx, int cy, OLE_XPOS_HIMETRIC xSrc, OLE_YPOS_HIMETRIC ySrc, OLE_XSIZE_HIMETRIC cxSrc, OLE_YSIZE_HIMETRIC cySrc, LPCRECT prcWBounds);
	HRESULT set_hPal(OLE_HANDLE hpal);
	HRESULT get_CurDC(HDC* phdcOut);
	HRESULT SelectPicture(HDC hdcIn, HDC* phdcOut, OLE_HANDLE* phbmpOut);
	HRESULT get_KeepOriginalFormat(BOOL* pfkeep);
	HRESULT put_KeepOriginalFormat(BOOL keep);
	HRESULT PictureChanged();
	HRESULT SaveAsFile(IStream pstream, BOOL fSaveMemCopy, LONG* pcbSize);
	HRESULT get_Attributes(DWORD* pdwAttr);
}

struct DVTARGETDEVICE
{
	DWORD tdSize;
	WORD tdDriverNameOffset;
	WORD tdDeviceNameOffset;
	WORD tdPortNameOffset;
	WORD tdExtDevmodeOffset;
	BYTE[1] tdData;
}


struct FORMATETC
{
	CLIPFORMAT cfFormat;
	DVTARGETDEVICE* ptd;
	DWORD dwAspect;
	LONG lindex;
	DWORD tymed;
}
alias FORMATETC* LPFORMATETC;


struct STATDATA 
{
	FORMATETC formatetc;
	DWORD grfAdvf;
	IAdviseSink pAdvSink;
	DWORD dwConnection;
}


struct STGMEDIUM
{
	DWORD tymed;
	union //u
	{
		HBITMAP hBitmap;
		//HMETAFILEPICT hMetaFilePict;
		HENHMETAFILE hEnhMetaFile;
		HGLOBAL hGlobal;
		LPOLESTR lpszFileName;
		IStream pstm;
		//IStorage pstg;
	}
	IUnknown pUnkForRelease;
}
alias STGMEDIUM* LPSTGMEDIUM;


interface IDataObject: IUnknown
{
	extern(Windows):
	HRESULT GetData(FORMATETC* pFormatetc, STGMEDIUM* pmedium);
	HRESULT GetDataHere(FORMATETC* pFormatetc, STGMEDIUM* pmedium);
	HRESULT QueryGetData(FORMATETC* pFormatetc);
	HRESULT GetCanonicalFormatEtc(FORMATETC* pFormatetcIn, FORMATETC* pFormatetcOut);
	HRESULT SetData(FORMATETC* pFormatetc, STGMEDIUM* pmedium, BOOL fRelease);
	HRESULT EnumFormatEtc(DWORD dwDirection, IEnumFORMATETC* ppenumFormatetc);
	HRESULT DAdvise(FORMATETC* pFormatetc, DWORD advf, IAdviseSink pAdvSink, DWORD* pdwConnection);
	HRESULT DUnadvise(DWORD dwConnection);
	HRESULT EnumDAdvise(IEnumSTATDATA* ppenumAdvise);
}


interface IDropSource: IUnknown
{
	extern(Windows):
	HRESULT QueryContinueDrag(BOOL fEscapePressed, DWORD grfKeyState);
	HRESULT GiveFeedback(DWORD dwEffect);
}


interface IDropTarget: IUnknown
{
	extern(Windows):
	HRESULT DragEnter(IDataObject pDataObject, DWORD grfKeyState, POINTL pt, DWORD* pdwEffect);
	HRESULT DragOver(DWORD grfKeyState, POINTL pt, DWORD* pdwEffect);
	HRESULT DragLeave();
	HRESULT Drop(IDataObject pDataObject, DWORD grfKeyState, POINTL pt, DWORD* pdwEffect);
}


interface IEnumFORMATETC: IUnknown
{
	extern(Windows):
	HRESULT Next(ULONG celt, FORMATETC* rgelt, ULONG* pceltFetched);
	HRESULT Skip(ULONG celt);
	HRESULT Reset();
	HRESULT Clone(IEnumFORMATETC* ppenum);
}


interface IEnumSTATDATA: IUnknown
{
	extern(Windows):
	HRESULT Next(ULONG celt, STATDATA* rgelt, ULONG* pceltFetched);
	HRESULT Skip(ULONG celt);
	HRESULT Reset();
	HRESULT Clone(IEnumSTATDATA* ppenum);
}


interface IAdviseSink: IUnknown
{
	// TODO: finish.
}


interface IMalloc: IUnknown
{
	extern(Windows):
	void* Alloc(ULONG cb);
	void* Realloc(void *pv, ULONG cb);
	void Free(void* pv);
	ULONG GetSize(void* pv);
	int DidAlloc(void* pv);
	void HeapMinimize();
}
// Since an interface is a pointer..
alias IMalloc PMALLOC;
alias IMalloc LPMALLOC;


LONG MAP_LOGHIM_TO_PIX(LONG x, LONG logpixels)
{
	return MulDiv(logpixels, x, 2540);
}


enum: DWORD
{
	DVASPECT_CONTENT = 1,
	DVASPECT_THUMBNAIL = 2,
	DVASPECT_ICON = 4,
	DVASPECT_DOCPRINT = 8,
}
alias DWORD DVASPECT;


enum: DWORD
{
	TYMED_HGLOBAL = 1,
	TYMED_FILE = 2,
	TYMED_ISTREAM = 4,
	TYMED_ISTORAGE = 8,
	TYMED_GDI = 16,
	TYMED_MFPICT = 32,
	TYMED_ENHMF = 64,
	TYMED_NULL = 0
}
alias DWORD TYMED;


enum
{
	DATADIR_GET = 1,
}


enum: HRESULT
{
	DRAGDROP_S_DROP = 0x00040100,
	DRAGDROP_S_CANCEL = 0x00040101,
	DRAGDROP_S_USEDEFAULTCURSORS = 0x00040102,
	V_E_LINDEX = cast(HRESULT)0x80040068,
	STG_E_MEDIUMFULL = cast(HRESULT)0x80030070,
	STG_E_INVALIDFUNCTION = cast(HRESULT)0x80030001,
	DV_E_TYMED = cast(HRESULT)0x80040069,
	DV_E_DVASPECT = cast(HRESULT)0x8004006B,
	DV_E_FORMATETC = cast(HRESULT)0x80040064,
	DV_E_LINDEX = cast(HRESULT)0x80040068,
	DRAGDROP_E_ALREADYREGISTERED = cast(HRESULT)0x80040101,
}


alias HRESULT WINOLEAPI;


WINOLEAPI OleInitialize(LPVOID pvReserved);
WINOLEAPI DoDragDrop(IDataObject pDataObject, IDropSource pDropSource, DWORD dwOKEffect, DWORD* pdwEffect);
WINOLEAPI RegisterDragDrop(HWND hwnd, IDropTarget pDropTarget);
WINOLEAPI RevokeDragDrop(HWND hwnd);
WINOLEAPI OleGetClipboard(IDataObject* ppDataObj);
WINOLEAPI OleSetClipboard(IDataObject pDataObj);
WINOLEAPI OleFlushClipboard();
WINOLEAPI CreateStreamOnHGlobal(HGLOBAL hGlobal, BOOL fDeleteOnRelease, LPSTREAM ppstm);
WINOLEAPI OleLoadPicture(IStream pStream, LONG lSize, BOOL fRunmode, IID* riid, void** ppv);

