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


version(Tango)
{
	alias int Dequ;
	
	
	public import tango.core.Thread;
	
	public import tango.core.Traits;
		
	
	template PhobosTraits()
	{
		static if(!is(ParameterTypeTuple!(function() { })))
		{
			// Grabbed from std.traits since Tango's meta.Traits lacks these:
			
			template ParameterTypeTuple(alias dg)
			{
				alias ParameterTypeTuple!(typeof(dg)) ParameterTypeTuple;
			}
			
			/** ditto */
			template ParameterTypeTuple(dg)
			{
				static if (is(dg P == function))
					alias P ParameterTypeTuple;
				else static if (is(dg P == delegate))
					alias ParameterTypeTuple!(P) ParameterTypeTuple;
				else static if (is(dg P == P*))
					alias ParameterTypeTuple!(P) ParameterTypeTuple;
				else
					static assert(0, "argument has no parameters");
			}
		}
	}
	
	mixin PhobosTraits;
	
	
	Dstring getObjectString(Object o)
	{
		return o.toString();
	}
	
	
	version(DFL_USE_CORE_MEMORY)
	{
		private import core.memory;
		
		void gcPin(void* p) { }
		void gcUnpin(void* p) { }
		
		deprecated void gcGenCollect()
		{
			core.memory.GC.collect();
		}
		
		void gcFullCollect()
		{
			core.memory.GC.collect();
		}
	}
	else
	{
		private import tango.core.Memory;
		
		void gcPin(void* p) { }
		void gcUnpin(void* p) { }
		
		deprecated void gcGenCollect()
		{
			GC.collect();
		}
		
		void gcFullCollect()
		{
			GC.collect();
		}
	}
	
	
	private import tango.text.Ascii;
	
	alias tango.text.Ascii.icompare stringICmp;
	
	dchar utf32charToLower(dchar dch)
	{
		// TO-DO: fix; not just ASCII.
		if(dch >= 0x80)
			return dch;
		char[1] input, result;
		input[0] = dch;
		return tango.text.Ascii.toLower(input, result)[0];
	}
	
	
	private import tango.stdc.stringz;
	
	alias tango.stdc.stringz.fromStringz stringFromStringz;
	
	alias tango.stdc.stringz.toStringz stringToStringz;
	
	
	private import tango.io.FilePath;
	
	Dstring pathGetDirName(Dstring s)
	{
		// Need to dup because standard and native mutate.
		scope mypath = new FilePath(tango.io.Path.standard(s.dup));
		return tango.io.Path.native(mypath.path().dup);
	}
	
	Dstring pathJoin(Dstring p1, Dstring p2)
	{
			// Need to dup because standard and native mutate.
			return tango.io.Path.native(
				FilePath.join(
					tango.io.Path.standard(p1.dup),
					tango.io.Path.standard(p2.dup)).dup);
	}
	
	
	version(_DFL_NO_USE_CORE_EXCEPTION_OUTOFMEMORY_EXCEPTION)
	{
		private import tango.core.Exception;
		
		class OomException: tango.core.Exception.OutOfMemoryException
		{
			this()
			{
				super(null, 0);
			}
		}
	}
	else
	{
		private import core.exception;
		
		class OomException: core.exception.OutOfMemoryException
		{
			this()
			{
				super(null, 0);
			}
		}
	}
	
	
	private import tango.text.convert.Utf;
	
	dchar utf8stringGetUtf32char(Dstring input, ref uint idx)
	{
		// Since the 'ate' (x) param is specified, the output (result) doesn't grow and returns when full.
		dchar[1] result;
		uint x;
		tango.text.convert.Utf.toString32(input[idx .. input.length], result, &x);
		idx += x;
		return result[0];
	}
	
	alias tango.text.convert.Utf.toString utf16stringtoUtf8string;
	
	alias tango.text.convert.Utf.toString16 utf8stringtoUtf16string;
	
	Dwstringz utf8stringToUtf16stringz(Dstring s)
	{
		Dwstring ws;
		ws = tango.text.convert.Utf.toString16(s);
		ws ~= '\0';
		return ws.ptr;
	}
	
	alias tango.text.convert.Utf.toString utf32stringtoUtf8string;
	
	alias tango.text.convert.Utf.toString32 utf8stringtoUtf32string;
	
	
	private import tango.io.model.IFile;
	
	alias tango.io.model.IFile.FileConst.NewlineString nativeLineSeparatorString;
	
	alias tango.io.model.IFile.FileConst.PathSeparatorString nativePathSeparatorString;
	
	
	private import tango.text.Util;
	
	alias tango.text.Util.delimit!(char) stringSplit;
	
	int charFindInString(Dstring str, dchar dch)
	{
		//uint locate(T, U=uint) (T[] source, T match, U start=0)
		uint loc;
		loc = tango.text.Util.locate!(char)(str, dch);
		if(loc == str.length)
			return -1;
		return cast(int)loc;
	}
	
	alias tango.text.Util.splitLines!(char) stringSplitLines;
	
	
	private import tango.text.convert.Integer;
	
	alias tango.text.convert.Integer.toInt!(char) stringToInt;
	
	alias tango.text.convert.Integer.toString stringToInt;
	
	Dstring uintToHexString(uint num)
	{
		char[16] buf;
		return tango.text.convert.Integer.format(buf, num, "X").dup;
	}
	
	Dstring intToString(int num)
	{
		char[16] buf;
		return tango.text.convert.Integer.format(buf, num, "d").dup;
	}
	
	
	private import tango.stdc.ctype;
	
	int charIsHexDigit(dchar dch)
	{
		return dch < 0x80 && tango.stdc.ctype.isxdigit(cast(char)dch);
	}
	
	
	private import tango.io.model.IConduit;
	
	version(DFL_DSTREAM_ICONDUIT) // Disabled by default.
	{
		alias tango.io.model.IConduit.IConduit DStream; // Requires writability.
	}
	else
	{
		alias tango.io.model.IConduit.InputStream DStream;
	}
	
	alias tango.io.model.IConduit.OutputStream DOutputStream;
	
	//alias tango.io.model.IConduit.IConduit.Seek DSeekStream;
	alias tango.io.model.IConduit.IConduit DSeekStream;
	
	alias tango.core.Exception.IOException DStreamException; // Note: from tango.core.Exception.
	
	
	alias Object DObject;
}
else // Phobos
{
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
		
		void gcFullCollect()
		{
			core.memory.GC.collect();
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
	
	alias std.string.find charFindInString;
	
	alias std.string.toStringz stringToStringz;
	
	Dstring uintToHexString(uint num)
	{
		return std.string.format("%X", num);
	}
	
	alias std.string.splitlines stringSplitLines;
	
	
	private import std.path;
	
	alias std.path.getDirName pathGetDirName;
	
	alias std.path.linesep nativeLineSeparatorString;
	
	alias std.path.join pathJoin;
	
	alias std.path.pathsep nativePathSeparatorString;
	
	
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
	
	alias std.utf.toUTF16z utf8stringToUtf16stringz;
	
	alias std.utf.toUTF8 utf32stringtoUtf8string;
	
	alias std.utf.toUTF32 utf8stringtoUtf32string;
	
	
	private import std.uni;
	
	alias std.uni.toUniLower utf32charToLower;
	
	
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
	
	
	private import std.ctype;
	
	alias std.ctype.isxdigit charIsHexDigit;
	
	
	private import std.stream;
	
	alias std.stream.Stream DStream;
	
	alias std.stream.OutputStream DOutputStream;
	
	alias std.stream.StreamException DStreamException;
	
	
	alias Object DObject;
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

