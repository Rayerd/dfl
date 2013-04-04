/*
	Copyright (C) 2007-2010 Christopher E. Miller
	
	This software is provided 'as-is', without any express or implied
	warranty.  In no event will the authors be held liable for any damages
	arising from the use of this software.
	
	Permission is granted to anyone to use this software for any purpose,
	including commercial applications, and to alter it and redistribute it
	freely, subject to the following restrictions:
	
	1. The origin of this software must not be misrepresented; you must not
	   claim that you wrote the original software. If you use this software
	   in a product, an acknowledgment in the product documentation would be
	   appreciated but is not required.
	2. Altered source versions must be plainly marked as such, and must not be
	   misrepresented as being the original software.
	3. This notice may not be removed or altered from any source distribution.
*/


module dfl.internal.dlib;


alias typeof(""c[]) Dstring;
alias typeof(""c.ptr) Dstringz;
alias typeof(" "c[0]) Dchar;
alias typeof(""w[]) Dwstring;
alias typeof(""w.ptr) Dwstringz;
alias typeof(" "w[0]) Dwchar;
alias typeof(""d[]) Ddstring;
alias typeof(""d.ptr) Ddstringz;
alias typeof(" "d[0]) Ddchar;


version(D_Version2)
{
	version = DFL_D2;
	version = DFL_D2_AND_ABOVE;
}
else version(D_Version3)
{
	version = DFL_D3;
	version = DFL_D3_AND_ABOVE;
	version = DFL_D2_AND_ABOVE;
}
else version(D_Version4)
{
	version = DFL_D4;
	version = DFL_D4_AND_ABOVE;
	version = DFL_D3_AND_ABOVE;
	version = DFL_D2_AND_ABOVE;
}
else
{
	version = DFL_D1;
}
//version = DFL_D1_AND_ABOVE;


version(DFL_D1)
{
	public import dfl.internal.d1;
}
else
{
	public import dfl.internal.d2;
}


version(DFL_D1)
{
	version(DFL_USE_CORE_MEMORY)
	{
	}
	else
	{
		version = DFL_NO_USE_CORE_MEMORY;
		version = _DFL_NO_USE_CORE_EXCEPTION_OUTOFMEMORY_EXCEPTION;
	}
	
	version(DFL_CONV_TO_TEMPLATE)
	{
	}
	else
	{
		version = DFL_NO_CONV_TO_TEMPLATE;
	}
}


version(DFL_D2_AND_ABOVE)
{
	version(DFL_beforeDMD2020)
	{
		version = DFL_NO_USE_CORE_MEMORY;
		version = _DFL_NO_USE_CORE_EXCEPTION_OUTOFMEMORY_EXCEPTION;
		version = _DFL_NO_USE_CORE_EXCEPTION_OUTOFMEMORY_ERROR;
		
		version = DFL_beforeDMD2021;
		version = DFL_beforeDMD2029;
	}
	
	version(DFL_beforeDMD2021)
	{
		version = _DFL_NO_USE_CORE_EXCEPTION_OUTOFMEMORY_ERROR;
		
		version = DFL_beforeDMD2029;
	}
	
	version(DFL_beforeDMD2029)
	{
		version(DFL_CONV_TO_TEMPLATE)
		{
		}
		else
		{
			version = DFL_NO_CONV_TO_TEMPLATE;
		}
	}
}


version(DFL_NO_USE_CORE_MEMORY)
{
	version = _DFL_NO_USE_CORE_EXCEPTION_OUTOFMEMORY_EXCEPTION;
}


public import std.traits;


alias ReturnType!(Object.opEquals) Dequ; // Since D2 changes mid-stream.


Dstring getObjectString(Object o)
{
	return o.toString();
}


version(DFL_NO_USE_CORE_MEMORY)
{
	private import std.gc; // If you get "module gc cannot read file 'core\memory.d'" then use -version=DFL_NO_USE_CORE_MEMORY <http://wiki.dprogramming.com/Dfl/CompileVersions>
	
	void gcPin(void* p) { }
	void gcUnpin(void* p) { }
	
	deprecated alias std.gc.genCollect gcGenCollect;
	
	alias std.gc.fullCollect gcFullCollect;
}
else
{
	private import core.memory; // If you get "module gc cannot read file 'std\gc.d'" then use -version=DFL_USE_CORE_MEMORY <http://wiki.dprogramming.com/Dfl/CompileVersions>
	
	void gcPin(void* p) { }
	void gcUnpin(void* p) { }
	
	deprecated void gcGenCollect()
	{
		core.memory.GC.collect();
	}
	
		void gcFullCollect() nothrow
	{
			try
			{
				core.memory.GC.collect();
			}
			catch (Throwable e)
			{
			}
		}
	}


private import std.string;

alias std.string.icmp stringICmp;

version(DFL_NO_CONV_TO_TEMPLATE)
{
	alias std.string.toString stringFromStringz;
}
else
{
	version(DFL_DMD2029)
	{
		Dstring stringFromStringz(Dstringz sz)
		{
			return std.conv.to!(Dstring, Dstringz)(sz); // D 2.029
		}
	}
	else
	{
		Dstring stringFromStringz(Dstringz sz)
		{
			return std.conv.to!(Dstring)(sz);
		}
	}
	
	version(DFL_D2_AND_ABOVE)
	{
		Dstring stringFromStringz(char* sz)
		{
			return stringFromStringz(cast(Dstringz)sz);
		}
	}
}

alias std.string.split stringSplit;

version(DFL_NO_CONV_TO_TEMPLATE)
{
	alias std.string.toString intToString;
}
else
{
	Dstring intToString(int i) 
	{ 
		return to!(Dstring)(i); // D 2.029
	}
}

alias std.algorithm.find charFindInString;

alias std.string.toStringz stringToStringz;

Dstring uintToHexString(uint num)
{
	return std.string.format("%X", num);
}

alias std.string.splitLines stringSplitLines;


private import std.path;

alias std.path.dirName pathGetDirName;

version(D_Version2)
	alias std.ascii.newline nativeLineSeparatorString;
else
	alias std.path.linesep nativeLineSeparatorString;

alias std.path.buildPath pathJoin;

alias std.path.pathSeparator nativePathSeparatorString;


version(_DFL_NO_USE_CORE_EXCEPTION_OUTOFMEMORY_EXCEPTION)
{
	private import std.outofmemory;
	
	alias std.outofmemory.OutOfMemoryException OomException;
}
else
{
	private import core.exception;
	
	version(_DFL_NO_USE_CORE_EXCEPTION_OUTOFMEMORY_ERROR)
	{
		class OomException: core.exception.OutOfMemoryException
		{
			this()
			{
				super(null, 0);
			}
		}
	}
	else
	{
		class OomException: core.exception.OutOfMemoryError
		{
			this()
			{
				super(null, 0);
			}
		}
	}
}


private import std.utf;

alias std.utf.decode utf8stringGetUtf32char;

alias std.utf.toUTF8 utf16stringtoUtf8string;

alias std.utf.toUTF16 utf8stringtoUtf16string;

alias std.utf.toUTFz!(typeof(Dwstring.init.ptr), Dstring) utf8stringToUtf16stringz;

alias std.utf.toUTF8 utf32stringtoUtf8string;

alias std.utf.toUTF32 utf8stringtoUtf32string;


private import std.uni;

alias std.uni.toLower utf32charToLower;


private import std.conv;

version(DFL_NO_CONV_TO_TEMPLATE)
{
	alias std.conv.toInt stringToInt;
}
else
{
	version(DFL_DMD2029)
	{
		alias std.conv.to!(int, Dstring) stringToInt; // D 2.029
	}
	else
	{
		int stringToInt(Dstring s)
		{
			return std.conv.to!(int)(s);
		}
	}
}


private import std.ascii;

alias std.ascii.isHexDigit charIsHexDigit;


private import std.stream;

alias std.stream.Stream DStream;

alias std.stream.OutputStream DOutputStream;

alias std.stream.StreamException DStreamException;


alias Object DObject;
version(DFL_D2_AND_ABOVE)
{
	version(DFL_CanThrowObject)
	{
		alias Object DThrowable;
	}
	else
	{
		alias Throwable DThrowable;
	}
}
else
{
	alias Object DThrowable;
}


char* unsafeToStringz(Dstring s)
{
	// This is intentionally unsafe, hence the name.
	if(!s.ptr[s.length])
		//return s.ptr;
		return cast(char*)s.ptr; // Needed in D2.
	//return stringToStringz(s);
	return cast(char*)stringToStringz(s); // Needed in D2.
}

