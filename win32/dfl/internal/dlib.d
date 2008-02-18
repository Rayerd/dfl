/*
	Copyright (C) 2007 Christopher E. Miller
	
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


version(Tango)
{
	version(DFL_TANGO097rc1)
	{
		version = DFL_TANGObefore099rc3;
		version = DFL_TANGObefore0994;
	}
	else version(DFL_TANGO098rc2)
	{
		version = DFL_TANGObefore099rc3;
		version = DFL_TANGObefore0994;
	}
	else version(DFL_TANGObefore099rc3)
	{
		version = DFL_TANGObefore0994;
	}
	else version(DFL_TANGO0992)
	{
		version = DFL_TANGObefore0994;
	}
	else version(DFL_TANGO0993)
	{
		version = DFL_TANGObefore0994;
	}
	else version(DFL_TANGO_0994)
	{
	}
	
	
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
	
	
	char[] getObjectString(Object o)
	{
		version(DFL_TANGObefore0994)
		{
			return o.toUtf8();
		}
		else
		{
			return o.toString();
		}
	}
	
	
	private import tango.core.Memory;
	
	void gcPin(void* p) { }
	void gcUnpin(void* p) { }
	
	void gcGenCollect()
	{
		version(DFL_TANGObefore099rc3)
			gc.collect();
		else
			GC.collect();
	}
	
	void gcFullCollect()
	{
		version(DFL_TANGObefore099rc3)
			gc.collect();
		else
			GC.collect();
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
	
	alias tango.stdc.stringz.fromUtf8z stringFromStringz;
	
	version(DFL_TANGObefore0994)
	{
		alias tango.stdc.stringz.toUtf8z stringToStringz;
	}
	else
	{
		alias tango.stdc.stringz.toStringz stringToStringz;
	}
	
	
	private import tango.io.FilePath;
	
	char[] pathGetDirName(char[] s)
	{
		scope mypath = new FilePath(s);
		return mypath.path();
	}
	
	char[] pathJoin(char[] p1, char[] p2)
	{
		return FilePath.join(p1, p2);
	}
	
	
	private import tango.core.Exception;
	
	class OomException: tango.core.Exception.OutOfMemoryException
	{
		this()
		{
			super(null, 0);
		}
	}
	
	
	private import tango.text.convert.Utf;
	
	dchar utf8stringGetUtf32char(char[] input, inout uint idx)
	{
		// Since the 'ate' (x) param is specified, the output (result) doesn't grow and returns when full.
		dchar[1] result;
		uint x;
		version(DFL_TANGObefore0994)
		{
			tango.text.convert.Utf.toUtf32(input[idx .. input.length], result, &x);
		}
		else
		{
			tango.text.convert.Utf.toString32(input[idx .. input.length], result, &x);
		}
		idx += x;
		return result[0];
	}
	
	version(DFL_TANGObefore0994)
	{
		alias tango.text.convert.Utf.toUtf8 utf16stringtoUtf8string;
	}
	else
	{
		alias tango.text.convert.Utf.toString utf16stringtoUtf8string;
	}
	
	version(DFL_TANGObefore0994)
	{
		alias tango.text.convert.Utf.toUtf16 utf8stringtoUtf16string;
	}
	else
	{
		alias tango.text.convert.Utf.toString16 utf8stringtoUtf16string;
	}
	
	wchar* utf8stringToUtf16stringz(char[] s)
	{
		wchar[] ws;
		version(DFL_TANGObefore0994)
		{
			ws = tango.text.convert.Utf.toUtf16(s);
		}
		else
		{
			ws = tango.text.convert.Utf.toString16(s);
		}
		ws ~= '\0';
		return ws.ptr;
	}
	
	version(DFL_TANGObefore0994)
	{
		alias tango.text.convert.Utf.toUtf8 utf32stringtoUtf8string;
	}
	else
	{
		alias tango.text.convert.Utf.toString utf32stringtoUtf8string;
	}
	
	version(DFL_TANGObefore0994)
	{
		alias tango.text.convert.Utf.toUtf32 utf8stringtoUtf32string;
	}
	else
	{
		alias tango.text.convert.Utf.toString32 utf8stringtoUtf32string;
	}
	
	
	private import tango.io.FileConst;
	
	alias tango.io.FileConst.FileConst.NewlineString nativeLineSeparatorString;
	
	alias tango.io.FileConst.FileConst.PathSeparatorString nativePathSeparatorString;
	
	
	private import tango.text.Util;
	
	alias tango.text.Util.delimit!(char) stringSplit;
	
	int charFindInString(char[] str, dchar dch)
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
	
	version(DFL_TANGObefore0994)
	{
		alias tango.text.convert.Integer.toUtf8 stringToInt;
	}
	else
	{
		alias tango.text.convert.Integer.toString stringToInt;
	}
	
	char[] uintToHexString(uint num)
	{
		char[16] buf;
		return tango.text.convert.Integer.format!(char, uint)(buf, num,
			tango.text.convert.Integer.Style.HexUpper).dup;
	}
	
	char[] intToString(int num)
	{
		char[16] buf;
		return tango.text.convert.Integer.format!(char, uint)(buf, num).dup;
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
	
	alias tango.io.model.IConduit.IConduit.Seek DSeekStream;
	
	alias tango.core.Exception.IOException DStreamException; // Note: from tango.core.Exception.
	
	
	class DObject
	{
		version(DFL_TANGObefore0994)
		{
			//alias toUtf8 toString; // Doesn't let you override.
			char[] toString() { return super.toUtf8(); }
			override char[] toUtf8() { return toString(); }
		}
		else
		{
			// No need to override.
		}
	}
}
else // Phobos
{
	public import std.thread, std.traits;
	
	
	char[] getObjectString(Object o)
	{
		return o.toString();
	}
	
	
	private import std.gc;
	
	void gcPin(void* p) { }
	void gcUnpin(void* p) { }
	
	alias std.gc.genCollect gcGenCollect;
	
	alias std.gc.fullCollect gcFullCollect;
	
	
	private import std.string;
	
	alias std.string.icmp stringICmp;
	
	alias std.string.toString stringFromStringz;
	
	alias std.string.split stringSplit;
	
	alias std.string.toString intToString;
	
	alias std.string.find charFindInString;
	
	alias std.string.toStringz stringToStringz;
	
	char[] uintToHexString(uint num)
	{
		return std.string.format("%X", num);
	}
	
	alias std.string.splitlines stringSplitLines;
	
	
	private import std.path;
	
	alias std.path.getDirName pathGetDirName;
	
	alias std.path.linesep nativeLineSeparatorString;
	
	alias std.path.join pathJoin;
	
	alias std.path.pathsep nativePathSeparatorString;
	
	
	private import std.outofmemory;
	
	alias std.outofmemory.OutOfMemoryException OomException;
	
	
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
	
	alias std.conv.toInt stringToInt;
	
	
	private import std.ctype;
	
	alias std.ctype.isxdigit charIsHexDigit;
	
	
	private import std.stream;
	
	alias std.stream.Stream DStream;
	
	alias std.stream.OutputStream DOutputStream;
	
	alias std.stream.StreamException DStreamException;
	
	
	alias Object DObject;
}


char* unsafeToStringz(char[] s)
{
	if(!s.ptr[s.length])
		return s.ptr;
	return stringToStringz(s);
}

