// Written by Christopher E. Miller
// See the included license.txt for copyright and license details.


// Not actually part of forms, but is handy.

///
module dfl.registry;

import dfl.base;

import dfl.internal.dlib;
import dfl.internal.utf;

import core.sys.windows.windef;
import core.sys.windows.winreg;


///
class DflRegistryException: DflException // package
{
	///
	this(Dstring msg, int errorCode = 0)
	{
		this.errorCode = errorCode;
		debug
		{
			if(errorCode)
				msg = msg ~ " (error " ~ intToString(errorCode) ~ ")"; // Dup.
		}
		super(msg);
	}
	
	
	///
	int errorCode;
}


///
class Registry // docmain
{
	///
	private this() {}
	
	
static:
	
	///
	@property RegistryKey classesRoot() // getter
	{
		if(!_classesRoot)
			_classesRoot = new RegistryKey(HKEY_CLASSES_ROOT, false);
		return _classesRoot;
	}
	
	/// ditto
	@property RegistryKey currentConfig() // getter
	{
		if(!_currentConfig)
			_currentConfig = new RegistryKey(HKEY_CURRENT_CONFIG, false);
		return _currentConfig;
	}
	
	/// ditto
	@property RegistryKey currentUser() // getter
	{
		if(!_currentUser)
			_currentUser = new RegistryKey(HKEY_CURRENT_USER, false);
		return _currentUser;
	}
	
	/// ditto
	@property RegistryKey dynData() // getter
	{
		if(!_dynData)
			_dynData = new RegistryKey(HKEY_DYN_DATA, false);
		return _dynData;
	}
	
	/// ditto
	@property RegistryKey localMachine() // getter
	{
		if(!_localMachine)
			_localMachine = new RegistryKey(HKEY_LOCAL_MACHINE, false);
		return _localMachine;
	}
	
	/// ditto
	@property RegistryKey performanceData() // getter
	{
		if(!_performanceData)
			_performanceData = new RegistryKey(HKEY_PERFORMANCE_DATA, false);
		return _performanceData;
	}
	
	/// ditto
	@property RegistryKey users() // getter
	{
		if(!_users)
			_users = new RegistryKey(HKEY_USERS, false);
		return _users;
	}
	
	
private:
	RegistryKey _classesRoot;
	RegistryKey _currentConfig;
	RegistryKey _currentUser;
	RegistryKey _dynData;
	RegistryKey _localMachine;
	RegistryKey _performanceData;
	RegistryKey _users;
}


///
private enum uint MAX_REG_BUFFER = 256;


///
abstract class RegistryValue
{
	///
	@property DWORD valueType() const; // getter


	///
	override Dstring toString() const;

	
	///
	/+ package +/ protected LONG save(HKEY hkey, Dstring name); // package

	
	///
	package final @property RegistryValue _reg() { return this; }
}


///
class RegistryValueSz: RegistryValue
{
	///
	Dstring value;
	
	
	///
	this(Dstring str)
	{
		this.value = str;
	}
	
	/// ditto
	this()
	{
	}
	
	
	///
	override @property DWORD valueType() const // getter
	{
		return REG_SZ;
	}
	
	
	///
	override Dstring toString() const
	{
		return value;
	}
	
	
	///
	/+ package +/ protected override LONG save(HKEY hkey, Dstring name) // package
	{
		auto valuez = unsafeStringz(value);
		return RegSetValueExA(hkey, unsafeStringz(name), 0, REG_SZ, cast(BYTE*)valuez, cast(uint)(value.length + 1));
	}
}


/+
// Extra.
///
class RegistryValueSzW: RegistryValue
{
	///
	wDstring value;
	
	
	///
	this(wDstring str)
	{
		this.value = str;
	}
	
	/// ditto
	this()
	{
	}
	
	
	///
	override @property DWORD valueType() const // getter
	{
		return REG_SZ;
	}
	
	
	///
	override Dstring toString()
	{
		return utf16stringtoUtf8string(value);
	}
	
	
	///
	/+ package +/ protected override LONG save(HKEY hkey, Dstring name) // package
	{
		if(dfl.internal.utf.useUnicode)
		{
			
		}
		else
		{
			
		}
	}
}
+/


///
class RegistryValueMultiSz: RegistryValue
{
	///
	Dstring[] value;
	
	
	///
	this(Dstring[] strs)
	{
		this.value = strs;
	}
	
	/// ditto
	this()
	{
	}
	
	
	///
	override @property DWORD valueType() const // getter
	{
		return REG_MULTI_SZ;
	}
	
	
	///
	override Dstring toString() const
	{
		Dstring result;
		foreach(Dstring str; value)
		{
			result ~= str ~ "\r\n";
		}
		if(result.length)
			result = result[0 .. $ - 2]; // Exclude last \r\n.
		return result;
	}
	
	
	///
	/+ package +/ protected override LONG save(HKEY hkey, Dstring name) // package
	{
		size_t i = value.length + 1; // Each NUL and the extra terminating NUL.
		foreach(Dstring s; value)
		{
			i += s.length;
		}
		
		char[] multi = new char[i];
		foreach(Dstring s; value)
		{
			if(!s.length)
				throw new DflRegistryException("Empty strings are not allowed in multi_sz registry values");
			
			multi[i .. i + s.length] = s[];
			i += s.length;
			multi[i++] = 0;
		}
		multi[i++] = 0;
		assert(i == multi.length);
		
		return RegSetValueExA(hkey, unsafeStringz(name), 0, REG_MULTI_SZ, cast(BYTE*)multi, cast(uint)(multi.length));
	}
}


///
class RegistryValueExpandSz: RegistryValue
{
	///
	Dstring value;
	
	
	///
	this(Dstring str)
	{
		this.value = str;
	}
	
	/// ditto
	this()
	{
	}
	
	
	///
	override @property DWORD valueType() const // getter
	{
		return REG_EXPAND_SZ;
	}
	
	
	///
	override Dstring toString() const
	{
		return value;
	}
	
	
	///
	/+ package +/ protected override LONG save(HKEY hkey, Dstring name) // package
	{
		auto valuez = unsafeStringz(value);
		return RegSetValueExA(hkey, unsafeStringz(name), 0, REG_EXPAND_SZ, cast(BYTE*)valuez, cast(uint)(value.length + 1));
	}
}


///
private Dstring dwordToString(DWORD dw)
out(result)
{
	assert(result.length == 10);
	assert(result[0 .. 2] == "0x");
	foreach(char ch; result[2 .. result.length])
	{
		assert(charIsHexDigit(ch));
	}
}
do
{
	Dstring stmp = uintToHexString(dw);
	assert(stmp.length <= 8);
	uint ntmp = cast(uint)(8 - stmp.length + 2); // Plus 0x.
	char[] result = new char[ntmp + stmp.length];
	result[0 .. 2] = "0x";
	result[2 .. ntmp] = '0';
	result[ntmp .. result.length] = stmp[];
	
	return cast(Dstring)result;
}


unittest
{
	assert(dwordToString(0x8934) == "0x00008934");
	assert(dwordToString(0xF00BA2) == "0x00F00BA2");
	assert(dwordToString(0xBADBEEF0) == "0xBADBEEF0");
	assert(dwordToString(0xCAFEBEEF) == "0xCAFEBEEF");
	assert(dwordToString(0x09090BB) == "0x009090BB");
	assert(dwordToString(0) == "0x00000000");
}


///
class RegistryValueDword: RegistryValue
{
	///
	DWORD value;
	
	
	///
	this(DWORD dw)
	{
		this.value = dw;
	}
	
	/// ditto
	this()
	{
	}
	
	
	///
	override @property DWORD valueType() const // getter
	{
		return REG_DWORD;
	}
	
	
	///
	override Dstring toString() const
	{
		return dwordToString(value);
	}
	
	
	///
	/+ package +/ protected override LONG save(HKEY hkey, Dstring name) // package
	{
		return RegSetValueExA(hkey, unsafeStringz(name), 0, REG_DWORD, cast(BYTE*)&value, DWORD.sizeof);
	}
}

/// ditto
alias RegistryValueDwordLittleEndian = RegistryValueDword;

/// ditto
class RegistryValueDwordBigEndian: RegistryValue
{
	///
	DWORD value;
	
	
	///
	this(DWORD dw)
	{
		this.value = dw;
	}
	
	/// ditto
	this()
	{
	}
	
	
	///
	override @property DWORD valueType() const // getter
	{
		return REG_DWORD_BIG_ENDIAN;
	}
	
	
	///
	override Dstring toString() const
	{
		return dwordToString(value);
	}
	
	
	///
	/+ package +/ protected override LONG save(HKEY hkey, Dstring name) // package
	{
		return RegSetValueExA(hkey, unsafeStringz(name), 0, REG_DWORD_BIG_ENDIAN, cast(BYTE*)&value, DWORD.sizeof);
	}
}


///
class RegistryValueBinary: RegistryValue
{
	///
	void[] value;
	
	
	///
	this(void[] val)
	{
		this.value = val;
	}
	
	/// ditto
	this()
	{
	}
	
	
	///
	override @property DWORD valueType() const // getter
	{
		return REG_BINARY;
	}
	
	
	///
	override Dstring toString() const
	{
		return "Binary";
	}
	
	
	///
	/+ package +/ protected override LONG save(HKEY hkey, Dstring name) // package
	{
		return RegSetValueExA(hkey, unsafeStringz(name), 0, REG_BINARY, cast(BYTE*)value, cast(uint)value.length);
	}
}


///
class RegistryValueLink: RegistryValue
{
	///
	void[] value;
	
	
	///
	this(void[] val)
	{
		this.value = val;
	}
	
	/// ditto
	this()
	{
	}
	
	
	///
	override @property DWORD valueType() const // getter
	{
		return REG_LINK;
	}
	
	
	///
	override Dstring toString() const
	{
		return "Symbolic Link";
	}
	
	
	///
	/+ package +/ protected override LONG save(HKEY hkey, Dstring name) // package
	{
		return RegSetValueExA(hkey, unsafeStringz(name), 0, REG_LINK, cast(BYTE*)value, cast(uint)value.length);
	}
}


///
class RegistryValueResourceList: RegistryValue
{
	///
	void[] value;
	
	
	///
	this(void[] val)
	{
		this.value = val;
	}
	
	/// ditto
	this()
	{
	}
	
	
	///
	override @property DWORD valueType() const // getter
	{
		return REG_RESOURCE_LIST;
	}
	
	
	///
	override Dstring toString() const
	{
		return "Resource List";
	}
	
	
	///
	/+ package +/ protected override LONG save(HKEY hkey, Dstring name) // package
	{
		return RegSetValueExA(hkey, unsafeStringz(name), 0, REG_RESOURCE_LIST, cast(BYTE*)value, cast(uint)value.length);
	}
}


///
class RegistryValueNone: RegistryValue
{
	///
	void[] value;
	
	
	///
	this(void[] val)
	{
		this.value = val;
	}
	
	/// ditto
	this()
	{
	}
	
	
	///
	override @property DWORD valueType() const // getter
	{
		return REG_NONE;
	}
	
	
	///
	override Dstring toString() const
	{
		return "None";
	}
	
	
	///
	/+ package +/ protected override LONG save(HKEY hkey, Dstring name) // package
	{
		return RegSetValueExA(hkey, unsafeStringz(name), 0, REG_NONE, cast(BYTE*)value, cast(uint)value.length);
	}
}


///
enum RegistryHive: uint
{
	CLASSES_ROOT = 0x80000000, ///
	CURRENT_CONFIG = 0x80000005, /// ditto
	CURRENT_USER = 0x80000001, /// ditto
	DYN_DATA = 0x80000006, /// ditto (win9x only)
	LOCAL_MACHINE = 0x80000002, /// ditto
	PERFORMANCE_DATA = 0x80000004, /// ditto
	USERS = 0x80000003, /// ditto
}


///
class RegistryKey // docmain
{
private:
	HKEY _hkey;
	bool _owned = true;
	
	
public:
final:
	///
	final @property Dstring className() // getter
	{
		char[MAX_REG_BUFFER] buf;
		DWORD buflen = char.sizeof * MAX_REG_BUFFER;
		
		LONG rr = RegQueryInfoKeyA(_hkey, &buf[0], &buflen, null, null, null, null, null, null, null, null, null);
		if(ERROR_SUCCESS != rr)
			infoErr(rr);
		
		return buf[0 .. buflen].dup;
	}
	
	
	///
	final @property int subKeyCount() // getter
	{
		DWORD count;
		
		LONG rr = RegQueryInfoKeyA(_hkey, null, null, null, &count, null, null, null, null, null, null, null);
		if(ERROR_SUCCESS != rr)
			infoErr(rr);
		
		return count;
	}
	
	
	///
	final @property int valueCount() // getter
	{
		DWORD count;
		
		LONG rr = RegQueryInfoKeyA(_hkey, null, null, null, null, null, null, &count, null, null, null, null);
		if(ERROR_SUCCESS != rr)
			infoErr(rr);
		
		return count;
	}
	
	
	///
	final void close()
	{
		LONG rr = RegCloseKey(_hkey);
		if(ERROR_SUCCESS != rr)
			infoErr(rr);
	}
	
	
	///
	final RegistryKey createSubKey(Dstring name)
	{
		HKEY newHkey;
		DWORD cdisp;
		
		LONG rr = RegCreateKeyExA(_hkey, unsafeStringz(name), 0, null, 0, KEY_ALL_ACCESS, null, &newHkey, &cdisp);
		if(ERROR_SUCCESS != rr)
			throw new DflRegistryException("Unable to create registry key", rr);
		
		return new RegistryKey(newHkey);
	}
	
	
	///
	final void deleteSubKey(Dstring name, bool throwIfMissing)
	{
		HKEY openHkey;
		
		if(!name.length || !name[0])
			throw new DflRegistryException("Unable to delete subkey");
		
		auto namez = unsafeStringz(name);
		
		LONG opencode = RegOpenKeyExA(_hkey, namez, 0, KEY_ALL_ACCESS, &openHkey);
		if(ERROR_SUCCESS == opencode)
		{
			DWORD count;
			
			LONG querycode = RegQueryInfoKeyA(openHkey, null, null, null, &count, null, null, null, null, null, null, null);
			if(ERROR_SUCCESS == querycode)
			{
				RegCloseKey(openHkey);
				
				LONG delcode;
				if(!count)
				{
					delcode = RegDeleteKeyA(_hkey, namez);
					if(ERROR_SUCCESS == delcode)
						return; // OK.
					
					throw new DflRegistryException("Unable to delete subkey", delcode);
				}
				
				throw new DflRegistryException("Cannot delete registry key with subkeys");
			}
			
			RegCloseKey(openHkey);
			
			throw new DflRegistryException("Unable to delete registry key", querycode);
		}
		else
		{
			if(!throwIfMissing)
			{
				switch(opencode)
				{
					case ERROR_FILE_NOT_FOUND:
						return;
					
					default:
				}
			}
			
			throw new DflRegistryException("Unable to delete registry key", opencode);
		}
	}
	
	/// ditto
	final void deleteSubKey(Dstring name)
	{
		deleteSubKey(name, true);
	}
	
	
	///
	final void deleteSubKeyTree(Dstring name)
	{
		_deleteSubKeyTree(_hkey, name);
	}
	
	
	// NOTE: name is not written to! it's just not "invariant".
	private static void _deleteSubKeyTree(HKEY shkey, Dstring name)
	{
		HKEY openHkey;
		
		auto namez = unsafeStringz(name);
		
		if(ERROR_SUCCESS == RegOpenKeyExA(shkey, namez, 0, KEY_ALL_ACCESS, &openHkey))
		{
			void ouch(LONG why = 0)
			{
				throw new DflRegistryException("Unable to delete entire subkey tree", why);
			}
			
			
			DWORD count;
			
			LONG querycode = RegQueryInfoKeyA(openHkey, null, null, null, &count, null, null, null, null, null, null, null);
			if(ERROR_SUCCESS == querycode)
			{
				if(!count)
				{
					del_me:
					RegCloseKey(openHkey);
					LONG delcode = RegDeleteKeyA(shkey, namez);
					if(ERROR_SUCCESS == delcode)
						return; // OK.
					
					ouch(delcode);
				}
				else
				{
					try
					{
						// deleteSubKeyTree on all subkeys.
						
						char[MAX_REG_BUFFER] skn;
						DWORD len;
						
						next_subkey:
						len = skn.length;
						LONG enumcode = RegEnumKeyExA(openHkey, 0, skn.ptr, &len, null, null, null, null);
						switch(enumcode)
						{
							case ERROR_SUCCESS:
								//_deleteSubKeyTree(openHkey, skn[0 .. len]);
								_deleteSubKeyTree(openHkey, cast(Dstring)skn[0 .. len]); // Needed in D2. WARNING: NOT REALLY INVARIANT.
								goto next_subkey;
							
							case ERROR_NO_MORE_ITEMS:
								// Done!
								break;
							
							default:
								ouch(enumcode);
						}
						
						// Now go back to delete the origional key.
						goto del_me;
					}
					finally
					{
						RegCloseKey(openHkey);
					}
				}
			}
			else
			{
				ouch(querycode);
			}
		}
	}
	
	
	///
	final void deleteValue(Dstring name, bool throwIfMissing)
	{
		LONG rr = RegDeleteValueA(_hkey, unsafeStringz(name));
		switch(rr)
		{
			case ERROR_SUCCESS:
				break;
			
			case ERROR_FILE_NOT_FOUND:
				if(!throwIfMissing)
					break;
				goto default;
			default:
				throw new DflRegistryException("Unable to delete registry value", rr);
		}
	}
	
	/// ditto
	final void deleteValue(Dstring name)
	{
		deleteValue(name, true);
	}
	
	
	///
	override Dequ opEquals(Object o) const
	{
		RegistryKey rk = cast(RegistryKey)o;
		if(!rk)
			return false;
		return opEquals(rk);
	}
		
	/// ditto
	Dequ opEquals(RegistryKey rk) const
	{
		return _hkey == rk._hkey;
	}


	///
	override size_t toHash() const nothrow @safe
	{
		return hashOf(_hkey);
	}
	
	
	///
	final void flush()
	{
		RegFlushKey(_hkey);
	}
	
	
	///
	final Dstring[] getSubKeyNames()
	{
		char[MAX_REG_BUFFER] buf;
		DWORD len;
		DWORD idx;
		Dstring[] result;
		
		key_names:
		for(idx = 0;; idx++)
		{
			len = buf.length;
			LONG rr = RegEnumKeyExA(_hkey, idx, buf.ptr, &len, null, null, null, null);
			switch(rr)
			{
				case ERROR_SUCCESS:
					//result ~= buf[0 .. len].dup;
					//result ~= buf[0 .. len].idup; // Needed in D2. Doesn't work in D1.
					result ~= cast(Dstring)buf[0 .. len].dup; // Needed in D2.
					break;
				
				case ERROR_NO_MORE_ITEMS:
					// Done!
					break key_names;
				
				default:
					throw new DflRegistryException("Unable to obtain subkey names", rr);
			}
		}
		
		return result;
	}
	
	
	///
	final RegistryValue getValue(Dstring name, RegistryValue defaultValue)
	{
		DWORD type;
		DWORD len;
		
		LONG querycode = RegQueryValueExA(_hkey, unsafeStringz(name), null, &type, null, &len);
		switch(querycode)
		{
			case ERROR_SUCCESS:
				// Good.
				break;
			
			case ERROR_FILE_NOT_FOUND:
				// Value doesn't exist.
				return defaultValue;
			
			default: errquerycode:
				throw new DflRegistryException("Unable to get registry value", querycode);
		}
		
		ubyte[] data = new ubyte[len];
		// NOTE: reusing querycode here and above.
		querycode = RegQueryValueExA(_hkey, unsafeStringz(name), null, &type, data.ptr, &len);
		if(ERROR_SUCCESS != querycode)
			goto errquerycode;
		
		switch(type)
		{
			case REG_SZ:
				with(new RegistryValueSz)
				{
					assert(!data[$ - 1]);
					value = cast(Dstring)data[0 .. $ - 1];
					defaultValue = _reg;
				}
				break;
			
			case REG_DWORD: // REG_DWORD_LITTLE_ENDIAN
				with(new RegistryValueDword)
				{
					assert(data.length == DWORD.sizeof);
					value = *(cast(DWORD*)cast(void*)data);
					defaultValue = _reg;
				}
				break;
				
			case REG_EXPAND_SZ:
				with(new RegistryValueExpandSz)
				{
					assert(!data[$ - 1]);
					value = cast(Dstring)data[0 .. $ - 1];
					defaultValue = _reg;
				}
				break;
			
			case REG_MULTI_SZ:
				with(new RegistryValueMultiSz)
				{
					Dstring s;
					
					next_sz:
					s = stringFromStringz(cast(char*)data);
					if(s.length)
					{
						value ~= s;
						data = data[s.length + 1 .. $];
						goto next_sz;
					}
					
					defaultValue = _reg;
				}
				break;
			
			case REG_BINARY:
				with(new RegistryValueBinary)
				{
					value = data;
					defaultValue = _reg;
				}
				break;
			
			case REG_DWORD_BIG_ENDIAN:
				with(new RegistryValueDwordBigEndian)
				{
					assert(data.length == DWORD.sizeof);
					value = *(cast(DWORD*)cast(void*)data);
					defaultValue = _reg;
				}
				break;
			
			case REG_LINK:
				with(new RegistryValueLink)
				{
					value = data;
					defaultValue = _reg;
				}
				break;
			
			case REG_RESOURCE_LIST:
				with(new RegistryValueResourceList)
				{
					value = data;
					defaultValue = _reg;
				}
				break;
			
			case REG_NONE:
				with(new RegistryValueNone)
				{
					value = data;
					defaultValue = _reg;
				}
				break;
			
			default:
				throw new DflRegistryException("Unknown type for registry value");
		}
		
		return defaultValue;
	}
	
	/// ditto
	final RegistryValue getValue(Dstring name)
	{
		return getValue(name, null);
	}
	
	
	///
	final Dstring[] getValueNames()
	{
		char[MAX_REG_BUFFER] buf;
		DWORD len;
		DWORD idx;
		Dstring[] result;
		
		value_names:
		for(idx = 0;; idx++)
		{
			len = buf.length;
			LONG rr = RegEnumValueA(_hkey, idx, buf.ptr, &len, null, null, null, null);
			switch(rr)
			{
				case ERROR_SUCCESS:
					//result ~= buf[0 .. len].dup;
					//result ~= buf[0 .. len].idup; // Needed in D2. Doesn't work in D1.
					result ~= cast(Dstring)buf[0 .. len].dup; // Needed in D2.
					break;
				
				case ERROR_NO_MORE_ITEMS:
					// Done!
					break value_names;
				
				default:
					throw new DflRegistryException("Unable to obtain value names", rr);
			}
		}
		
		return result;
	}
	
	
	///
	static RegistryKey openRemoteBaseKey(RegistryHive hhive, Dstring machineName)
	{
		HKEY openHkey;
		
		LONG rr = RegConnectRegistryA(unsafeStringz(machineName), cast(HKEY)hhive, &openHkey);
		if(ERROR_SUCCESS != rr)
			throw new DflRegistryException("Unable to open remote base key", rr);
		
		return new RegistryKey(openHkey);
	}
	
	
	///
	// Returns null on error.
	final RegistryKey openSubKey(Dstring name, bool writeAccess)
	{
		HKEY openHkey;
		
		if(ERROR_SUCCESS != RegOpenKeyExA(_hkey, unsafeStringz(name), 0, writeAccess ? KEY_READ | KEY_WRITE : KEY_READ, &openHkey))
			return null;
		
		return new RegistryKey(openHkey);
	}
	
	/// ditto
	final RegistryKey openSubKey(Dstring name)
	{
		return openSubKey(name, false);
	}
	
	
	///
	final void setValue(Dstring name, RegistryValue value)
	{
		LONG rr = value.save(_hkey, name);
		if(ERROR_SUCCESS != rr)
			throw new DflRegistryException("Unable to set registry value", rr);
	}
	
	/// ditto
	// Shortcut.
	final void setValue(Dstring name, Dstring value)
	{
		scope rv = new RegistryValueSz(value);
		setValue(name, rv);
	}
	
	/// ditto
	// Shortcut.
	final void setValue(Dstring name, Dstring[] value)
	{
		scope rv = new RegistryValueMultiSz(value);
		setValue(name, rv);
	}
	
	/// ditto
	// Shortcut.
	final void setValue(Dstring name, DWORD value)
	{
		scope rv = new RegistryValueDword(value);
		setValue(name, rv);
	}
	
	
	///
	// Used internally.
	final @property HKEY handle() // getter
	{
		return _hkey;
	}
	
	
	// Used internally.
	this(HKEY hkey, bool owned = true)
	{
		this._hkey = hkey;
		this._owned = owned;
	}
	
	
	///
	~this()
	{
		if(_owned)
			RegCloseKey(_hkey);
	}
	
	
	///
	private void infoErr(LONG why)
	{
		throw new DflRegistryException("Unable to obtain registry information", why);
	}
}

