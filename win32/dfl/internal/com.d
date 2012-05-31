// Written by Christopher E. Miller
// See the included license.txt for copyright and license details.


module dfl.internal.com;

private import dfl.internal.winapi, dfl.internal.wincom, dfl.internal.dlib;


version(DFL_TANGO_SEEK_COMPAT)
{
}
else
{
	version = DFL_TANGO_NO_SEEK_COMPAT;
}


// Importing dfl.application here causes the compiler to crash.
//import dfl.application;
private extern(C)
{
	size_t C_refCountInc(void* p);
	size_t C_refCountDec(void* p);
}


// Won't be killed by GC if not referenced in D and the refcount is > 0.
class DflComObject: ComObject // package
{
	extern(Windows):
	
	override ULONG AddRef()
	{
		//cprintf("AddRef `%.*s`\n", cast(int)toString().length, toString().ptr);
		return C_refCountInc(cast(void*)this);
	}
	
	override ULONG Release()
	{
		//cprintf("Release `%.*s`\n", cast(int)toString().length, toString().ptr);
		return C_refCountDec(cast(void*)this);
	}
}


class DStreamToIStream: DflComObject, dfl.internal.wincom.IStream
{
	this(DStream sourceDStream)
	{
		this.stm = sourceDStream;
	}
	
	
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
		HRESULT result = S_OK;
		
		try
		{
			read = stm.readBlock(pv, cb);
		}
		catch(DStreamException e)
		{
			result = S_FALSE; // ?
		}
		
		if(pcbRead)
			*pcbRead = read;
		//if(!read)
		//	result = S_FALSE;
		return result;
	}
	
	
	HRESULT Write(void* pv, ULONG cb, ULONG* pcbWritten)
	{
		ULONG written;
		HRESULT result = S_OK;
		
		try
		{
			if(!stm.writeable)
				return E_NOTIMPL;
			written = stm.writeBlock(pv, cb);
		}
		catch(DStreamException e)
		{
			result = S_FALSE; // ?
		}
		
		if(pcbWritten)
			*pcbWritten = written;
		//if(!written)
		//	result = S_FALSE;
		return result;
	}
	
	
	version(DFL_TANGO_NO_SEEK_COMPAT)
	{
	}
	else
	{
		long _fakepos = 0;
	}
	
	
	HRESULT Seek(LARGE_INTEGER dlibMove, DWORD dwOrigin, ULARGE_INTEGER* plibNewPosition)
	{
		HRESULT result = S_OK;
		
		//cprintf("seek move=%u, origin=0x%x\n", cast(uint)dlibMove.QuadPart, dwOrigin);
		
		try
		{
			if(!stm.seekable)
				//return S_FALSE; // ?
				return E_NOTIMPL; // ?
			
			ulong pos;
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
		catch(DStreamException e)
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
		//stm.flush();
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
	DStream stm;
}

class MemoryIStream: DflComObject, dfl.internal.wincom.IStream
{
	this(void[] memory)
	{
		this.mem = memory;
	}
	
	
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
		// Shouldn't happen unless the mem changes, which doesn't happen yet.
		if(seekpos > mem.length)
			return S_FALSE; // ?
		
		size_t count = mem.length - seekpos;
		if(count > cb)
			count = cb;
		
		pv[0 .. count] = mem[seekpos .. seekpos + count];
		seekpos += count;
		
		if(pcbRead)
			*pcbRead = count;
		return S_OK;
	}
	
	
	HRESULT Write(void* pv, ULONG cb, ULONG* pcbWritten)
	{
		//return STG_E_ACCESSDENIED;
		return E_NOTIMPL;
	}
	
	
	HRESULT Seek(LARGE_INTEGER dlibMove, DWORD dwOrigin, ULARGE_INTEGER* plibNewPosition)
	{
		//cprintf("seek move=%u, origin=0x%x\n", cast(uint)dlibMove.QuadPart, dwOrigin);
		
		auto toPos = cast(long)dlibMove.QuadPart;
		switch(dwOrigin)
		{
			case STREAM_SEEK_SET:
				break;
			
			case STREAM_SEEK_CUR:
				toPos = cast(long)seekpos + toPos;
				break;
			
			case STREAM_SEEK_END:
				toPos = cast(long)mem.length - toPos;
				break;
			
			default:
				return STG_E_INVALIDFUNCTION;
		}
		
		if(withinbounds(toPos))
		{
			seekpos = cast(size_t)toPos;
			if(plibNewPosition)
				plibNewPosition.QuadPart = seekpos;
			return S_OK;
		}
		else
		{
			return 0x80030005; //STG_E_ACCESSDENIED; // Seeking past end needs write access.
		}
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
	void[] mem;
	size_t seekpos = 0;
	
	
	bool withinbounds(long pos)
	{
		if(pos < seekpos.min || pos > seekpos.max)
			return false;
		// Note: it IS within bounds if it's AT the end, it just can't read there.
		return cast(size_t)pos <= mem.length;
	}
}

