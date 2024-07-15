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


alias Dstring = typeof(""c[]);
alias Dstringz = typeof(""c.ptr);
alias Dchar = typeof(" "c[0]);
alias Dwstring = typeof(""w[]);
alias Dwstringz = typeof(""w.ptr);
alias Dwchar = typeof(" "w[0]);
alias Ddstring = typeof(""d[]);
alias Ddstringz = typeof(""d.ptr);
alias Ddchar = typeof(" "d[0]);

uint toI32(size_t val) @property @safe pure nothrow
{
	return cast(uint)val;
}

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


alias Dequ = ReturnType!(Object.opEquals); // Since D2 changes mid-stream.


Dstring getObjectString(Object o)
{
	return o.toString();
}


version(DFL_NO_USE_CORE_MEMORY)
{
	private import std.gc; // If you get "module gc cannot read file 'core\memory.d'" then use -version=DFL_NO_USE_CORE_MEMORY <http://wiki.dprogramming.com/Dfl/CompileVersions>
	
	void gcPin(void* p) { }
	void gcUnpin(void* p) { }
	
	deprecated alias gcGenCollect = std.gc.genCollect;
	
	alias gcFullCollect = std.gc.fullCollect;
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

alias stringICmp = std.string.icmp;

version(DFL_NO_CONV_TO_TEMPLATE)
{
	alias stringFromStringz = std.string.toString;
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

alias stringSplit = std.string.split;

version(DFL_NO_CONV_TO_TEMPLATE)
{
	alias intToString = std.string.toString;
}
else
{
	Dstring intToString(int i) 
	{ 
		return to!(Dstring)(i); // D 2.029
	}
}

private import std.algorithm.searching;

alias charFindInString = std.algorithm.searching.find;

alias stringToStringz = std.string.toStringz;

Dstring uintToHexString(uint num)
{
	return std.string.format("%X", num);
}

alias stringSplitLines = std.string.splitLines;


private import std.path;

alias pathGetDirName = std.path.dirName;

version(D_Version2)
	alias nativeLineSeparatorString = std.ascii.newline;
else
	alias nativeLineSeparatorString = std.path.linesep;

alias pathJoin = std.path.buildPath;

alias nativePathSeparatorString = std.path.pathSeparator;


version(_DFL_NO_USE_CORE_EXCEPTION_OUTOFMEMORY_EXCEPTION)
{
	private import std.outofmemory;
	
	alias OomException = std.outofmemory.OutOfMemoryException;
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

alias utf8stringGetUtf32char = std.utf.decode;

alias utf16stringtoUtf8string = std.utf.toUTF8;

alias utf8stringtoUtf16string = std.utf.toUTF16;

alias utf8stringToUtf16stringz = std.utf.toUTFz!(typeof(Dwstring.init.ptr));

alias utf32stringtoUtf8string = std.utf.toUTF8;

alias utf8stringtoUtf32string = std.utf.toUTF32;


private import std.uni;

alias utf32charToLower = std.uni.toLower;


private import std.conv;

version(DFL_NO_CONV_TO_TEMPLATE)
{
	alias stringToInt = std.conv.toInt;
}
else
{
	version(DFL_DMD2029)
	{
		alias stringToInt = std.conv.to!(int, Dstring); // D 2.029
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

alias charIsHexDigit = std.ascii.isHexDigit;


private import undead.stream;// dfl.internal.stream is deprecated.

deprecated alias DStream = undead.stream.Stream;// dfl.internal.stream.Stream is deprecated.

deprecated alias DOutputStream = undead.stream.OutputStream;//dfl.internal.stream.OutputStream is deprecated.

deprecated alias DStreamException = undead.stream.StreamException;//dfl.internal.stream.StreamException is deprecated.


alias DObject = Object;
version(DFL_D2_AND_ABOVE)
{
	version(DFL_CanThrowObject)
	{
		alias DThrowable = Object;
	}
	else
	{
		alias DThrowable = Throwable;
	}
}
else
{
	alias DThrowable = Object;
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

