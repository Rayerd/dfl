// Written by Christopher E. Miller
// See the included license.txt for copyright and license details.


module dfl.internal.com;

private import dfl.internal.winapi, dfl.internal.wincom;

version(Tango)
{
}
else
{
	private import std.stream;
}


// Importing dfl.application here causes the compiler to crash.
//import dfl.application;
private extern(C)
{
	size_t C_refCountInc(void* p);
	size_t C_refCountDec(void* p);
}


// Won't be killed by GC if not referenced in D and the refcount is > 0.
package class DflComObject: ComObject
{
	extern (Windows):
	
	override ULONG AddRef()
	{
		//printf("AddRef `%.*s`\n", cast(int)toString().length, toString().ptr);
		return C_refCountInc(cast(void*)this);
	}
	
	override ULONG Release()
	{
		//printf("Release `%.*s`\n", cast(int)toString().length, toString().ptr);
		return C_refCountDec(cast(void*)this);
	}
}


version(Tango)
{
}
else
{
	class StdStreamToIStream: DflComObject, dfl.internal.wincom.IStream
	{
		this(Stream sourceStdStream)
		{
			this.stm = sourceStdStream;
		}
		
		
		// TODO: catch general exceptions and react.
		
		extern(Windows):
		override HRESULT QueryInterface(IID* riid, void** ppv)
		{
			if(*riid == _IID_IStream)
			{
				*ppv = cast(void*)cast(dfl.internal.wincom.IStream)this;
				AddRef();
				return S_OK;
			}
			else if(*riid == _IID_ISequentialStream)
			{
				*ppv = cast(void*)cast(dfl.internal.wincom.ISequentialStream)this;
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
		
		
		HRESULT Read(void* pv, ULONG cb, ULONG* pcbRead)
		{
			ULONG read;
			read = stm.readBlock(pv, cb);
			if(pcbRead)
				*pcbRead = read;
			if(!read)
				return S_FALSE;
			return S_OK;
		}
		
		
		HRESULT Write(void* pv, ULONG cb, ULONG* pcbWritten)
		{
			ULONG written;
			written = stm.writeBlock(pv, cb);
			if(pcbWritten)
				*pcbWritten = written;
			if(!written)
				return S_FALSE;
			return S_OK;
		}
		
		
		HRESULT Seek(LARGE_INTEGER dlibMove, DWORD dwOrigin, ULARGE_INTEGER* plibNewPosition)
		{
			if(!stm.seekable)
				return S_FALSE; // ?
			
			HRESULT result = S_OK;
			ulong pos;
			try
			{
				switch(dwOrigin)
				{
					case STREAM_SEEK_SET:
						pos = stm.seekSet(dlibMove.QuadPart);
						if(plibNewPosition)
							plibNewPosition.QuadPart = pos;
						break;
					
					case STREAM_SEEK_CUR:
						pos = stm.seekCur(dlibMove.QuadPart);
						if(plibNewPosition)
							plibNewPosition.QuadPart = pos;
						break;
					
					case STREAM_SEEK_END:
						pos = stm.seekEnd(dlibMove.QuadPart);
						if(plibNewPosition)
							plibNewPosition.QuadPart = pos;
						break;
					
					default:
						result = STG_E_INVALIDFUNCTION;
				}
			}
			catch(SeekException se)
			{
				result = S_FALSE; // ?
			}
			
			return result;
		}
		
		
		HRESULT SetSize(ULARGE_INTEGER libNewSize)
		{
			return E_NOTIMPL;
		}
		
		
		HRESULT CopyTo(IStream pstm, ULARGE_INTEGER cb, ULARGE_INTEGER* pcbRead, ULARGE_INTEGER* pcbWritten)
		{
			// TODO: implement.
			return E_NOTIMPL;
		}
		
		
		HRESULT Commit(DWORD grfCommitFlags)
		{
			// Ignore -grfCommitFlags- and just flush the stream..
			stm.flush();
			return S_OK; // ?
		}
		
		
		HRESULT Revert()
		{
			return E_NOTIMPL; // ? S_FALSE ?
		}
		
		
		HRESULT LockRegion(ULARGE_INTEGER libOffset, ULARGE_INTEGER cb, DWORD dwLockType)
		{
			return E_NOTIMPL;
		}
		
		
		HRESULT UnlockRegion(ULARGE_INTEGER libOffset, ULARGE_INTEGER cb, DWORD dwLockType)
		{
			return E_NOTIMPL;
		}
		
		
		HRESULT Stat(STATSTG* pstatstg, DWORD grfStatFlag)
		{
			return E_NOTIMPL; // ?
		}
		
		
		HRESULT Clone(IStream* ppstm)
		{
			// Cloned stream needs its own seek position.
			return E_NOTIMPL; // ?
		}
		
		
		extern(D):
		
		private:
		Stream stm;
	}
}

