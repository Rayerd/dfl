// Written by Christopher E. Miller
// See the included license.txt for copyright and license details.


// Not actually part of forms, but is handy.

///
module dfl.registry;

private import dfl.internal.dlib;

private import dfl.internal.winapi, dfl.base, dfl.internal.utf;


///
class Registry // docmain
{
	private this() {}
	
	
	static:
	
	///
	RegistryKey classesRoot() // getter
	{
		if(!_classesRoot)
			_classesRoot = new RegistryKey(HKEY_CLASSES_ROOT, false);
		return _classesRoot;
	}
	
	/// ditto
	RegistryKey currentConfig() // getter
	{
		if(!_currentConfig)
			_currentConfig = new RegistryKey(HKEY_CURRENT_CONFIG, false);
		return _currentConfig;
	}
	
	/// ditto
	RegistryKey currentUser() // getter
	{
		if(!_currentUser)
			_currentUser = new RegistryKey(HKEY_CURRENT_USER, false);
		return _currentUser;
	}
	
	/// ditto
	RegistryKey dynData() // getter
	{
		if(!_dynData)
			_dynData = new RegistryKey(HKEY_DYN_DATA, false);
		return _dynData;
	}
	
	/// ditto
	RegistryKey localMachine() // getter
	{
		if(!_localMachine)
			_localMachine = new RegistryKey(HKEY_LOCAL_MACHINE, false);
		return _localMachine;
	}
	
	/// ditto
	RegistryKey performanceData() // getter
	{
		if(!_performanceData)
			_performanceData = new RegistryKey(HKEY_PERFORMANCE_DATA, false);
		return _performanceData;
	}
	
	/// ditto
	RegistryKey users() // getter
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
	
	
	/+
	static this()
	{
		_classesRoot = new RegistryKey(HKEY_CLASSES_ROOT, false);
		_currentConfig = new RegistryKey(HKEY_CURRENT_CONFIG, false);
		_currentUser = new RegistryKey(HKEY_CURRENT_USER, false);
		_dynData = new RegistryKey(HKEY_DYN_DATA, false);
		_localMachine = new RegistryKey(HKEY_LOCAL_MACHINE, false);
		_performanceData = new RegistryKey(HKEY_PERFORMANCE_DATA, false);
		_users = new RegistryKey(HKEY_USERS, false);
	}
	+/
}


private const uint MAX_REG_BUFFER = 256;


///
abstract class RegistryValue
{
	DWORD valueType(); // getter
	char[] toString();
	/+ package +/ protected LONG save(HKEY hkey, char[] name); // package
	package final RegistryValue _reg() { return this; }
}


///
class RegistryValueSz: RegistryValue
{
	///
	char[] value;
	
	
	///
	this(char[] str)
	{
		this.value = str;
	}
	
	/// ditto
	this()
	{
	}
	
	
	override DWORD valueType() // getter
	{
		return REG_SZ;
	}
	
	
	override char[] toString()
	{
		return value;
	}
	
	
	/+ package +/ protected override LONG save(HKEY hkey, char[] name) // package
	{
		char* valuez = unsafeStringz(value);
		return RegSetValueExA(hkey, unsafeStringz(name), 0, REG_SZ, cast(BYTE*)valuez, value.length + 1);
	}
}


/+
// Extra.
///
class RegistryValueSzW: RegistryValue
{
	///
	wchar[] value;
	
	
	///
	this(wchar[] str)
	{
		this.value = str;
	}
	
	/// ditto
	this()
	{
	}
	
	
	override DWORD valueType() // getter
	{
		return REG_SZ;
	}
	
	
	override char[] toString()
	{
		return utf16stringtoUtf8string(value);
	}
	
	
	/+ package +/ protected override LONG save(HKEY hkey, char[] name) // package
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
	char[][] value;
	
	
	///
	this(char[][] strs)
	{
		this.value = strs;
	}
	
	/// ditto
	this()
	{
	}
	
	
	override DWORD valueType() // getter
	{
		return REG_MULTI_SZ;
	}
	
	
	override char[] toString()
	{
		char[] result;
		foreach(char[] str; value)
		{
			result ~= str ~ \r\n;
		}
		if(result.length)
			result = result[0 .. result.length - 2]; // Exclude last \r\n.
		return result;
	}
	
	
	/+ package +/ protected override LONG save(HKEY hkey, char[] name) // package
	{
		char[] multi;
		uint i;
		
		i = value.length + 1; // Each NUL and the extra terminating NUL.
		foreach(char[] s; value)
		{
			i += s.length;
		}
		
		multi = new char[i];
		foreach(char[] s; value)
		{
			if(!s.length)
				throw new DflException("Empty strings are not allowed in multi_sz registry values");
			
			multi[i .. i + s.length] = s;
			i += s.length;
			multi[i++] = 0;
		}
		multi[i++] = 0;
		assert(i == multi.length);
		
		return RegSetValueExA(hkey, unsafeStringz(name), 0, REG_MULTI_SZ, cast(BYTE*)multi, multi.length);
	}
}


///
class RegistryValueExpandSz: RegistryValue
{
	///
	char[] value;
	
	
	///
	this(char[] str)
	{
		this.value = str;
	}
	
	/// ditto
	this()
	{
	}
	
	
	override DWORD valueType() // getter
	{
		return REG_EXPAND_SZ;
	}
	
	
	override char[] toString()
	{
		return value;
	}
	
	
	/+ package +/ protected override LONG save(HKEY hkey, char[] name) // package
	{
		char* valuez = unsafeStringz(value);
		return RegSetValueExA(hkey, unsafeStringz(name), 0, REG_EXPAND_SZ, cast(BYTE*)valuez, value.length + 1);
	}
}


private char[] dwordToString(DWORD dw)
out(result)
{
	assert(result.length == 10);
	assert(result[0 .. 2] == "0x");
	foreach(char ch; result[2 .. result.length])
	{
		assert(charIsHexDigit(ch));
	}
}
body
{
	char[] result;
	char[] stmp;
	uint ntmp;
	
	stmp = uintToHexString(dw);
	assert(stmp.length <= 8);
	ntmp = 8 - stmp.length + 2; // Plus 0x.
	result = new char[ntmp + stmp.length];
	result[0 .. 2] = "0x";
	result[2 .. ntmp] = '0';
	result[ntmp .. result.length] = stmp;
	
	return result;
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
	
	
	override DWORD valueType() // getter
	{
		return REG_DWORD;
	}
	
	
	override char[] toString()
	{
		return dwordToString(value);
	}
	
	
	/+ package +/ protected override LONG save(HKEY hkey, char[] name) // package
	{
		return RegSetValueExA(hkey, unsafeStringz(name), 0, REG_DWORD, cast(BYTE*)&value, DWORD.sizeof);
	}
}

/// ditto
alias RegistryValueDword RegistryValueDwordLittleEndian;

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
	
	
	override DWORD valueType() // getter
	{
		return REG_DWORD_BIG_ENDIAN;
	}
	
	
	override char[] toString()
	{
		return dwordToString(value);
	}
	
	
	/+ package +/ protected override LONG save(HKEY hkey, char[] name) // package
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
	
	
	override DWORD valueType() // getter
	{
		return REG_BINARY;
	}
	
	
	override char[] toString()
	{
		return "Binary";
	}
	
	
	/+ package +/ protected override LONG save(HKEY hkey, char[] name) // package
	{
		return RegSetValueExA(hkey, unsafeStringz(name), 0, REG_BINARY, cast(BYTE*)value, value.length);
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
	
	
	override DWORD valueType() // getter
	{
		return REG_LINK;
	}
	
	
	override char[] toString()
	{
		return "Symbolic Link";
	}
	
	
	/+ package +/ protected override LONG save(HKEY hkey, char[] name) // package
	{
		return RegSetValueExA(hkey, unsafeStringz(name), 0, REG_LINK, cast(BYTE*)value, value.length);
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
	
	
	override DWORD valueType() // getter
	{
		return REG_RESOURCE_LIST;
	}
	
	
	override char[] toString()
	{
		return "Resource List";
	}
	
	
	/+ package +/ protected override LONG save(HKEY hkey, char[] name) // package
	{
		return RegSetValueExA(hkey, unsafeStringz(name), 0, REG_RESOURCE_LIST, cast(BYTE*)value, value.length);
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
	
	
	override DWORD valueType() // getter
	{
		return REG_NONE;
	}
	
	
	override char[] toString()
	{
		return "None";
	}
	
	
	/+ package +/ protected override LONG save(HKEY hkey, char[] name) // package
	{
		return RegSetValueExA(hkey, unsafeStringz(name), 0, REG_NONE, cast(BYTE*)value, value.length);
	}
}


///
enum RegistryHive: size_t
{
	/+
	// DMD 0.98:
	// C:\dmd\bin\..\src\phobos\std\c\windows\windows.d(493): cast(HKEY)(2147483648) is not an expression
	// ...
	CLASSES_ROOT = cast(size_t)HKEY_CLASSES_ROOT,
	CURRENT_CONFIG = cast(size_t)HKEY_CURRENT_CONFIG,
	CURRENT_USER = cast(size_t)HKEY_CURRENT_USER,
	DYN_DATA = cast(size_t)HKEY_DYN_DATA,
	LOCAL_MACHINE = cast(size_t)HKEY_LOCAL_MACHINE,
	PERFORMANCE_DATA = cast(size_t)HKEY_PERFORMANCE_DATA,
	USERS = cast(size_t)HKEY_USERS,
	+/
	
	CLASSES_ROOT = 0x80000000, ///
	CURRENT_CONFIG = 0x80000005, /// ditto
	CURRENT_USER = 0x80000001, /// ditto
	DYN_DATA = 0x80000006, /// ditto
	LOCAL_MACHINE = 0x80000002, /// ditto
	PERFORMANCE_DATA = 0x80000004, /// ditto
	USERS = 0x80000003, /// ditto
}


///
class RegistryKey // docmain
{
	private:
	HKEY hkey;
	bool owned = true;
	
	
	public:
	final:
	/+
	// An absolute key path.
	// This doesn't work.
	final char[] name() // getter
	{
		char[] buf;
		DWORD buflen;
		
		buf = new char[MAX_REG_BUFFER];
		buflen = buf.length;
		if(ERROR_SUCCESS != RegQueryInfoKeyA(hkey, buf, &buflen, null, null,
			null, null, null, null, null, null, null))
			infoErr();
		
		return buf[0 .. buflen];
	}
	+/
	
	
	///
	final int subKeyCount() // getter
	{
		DWORD count;
		
		if(ERROR_SUCCESS != RegQueryInfoKeyA(hkey, null, null, null, &count,
			null, null, null, null, null, null, null))
			infoErr();
		
		return count;
	}
	
	
	///
	final int valueCount() // getter
	{
		DWORD count;
		
		if(ERROR_SUCCESS != RegQueryInfoKeyA(hkey, null, null, null, null,
			null, null, &count, null, null, null, null))
			infoErr();
		
		return count;
	}
	
	
	///
	final void close()
	{
		//if(!owned)
			RegCloseKey(hkey);
	}
	
	
	///
	final RegistryKey createSubKey(char[] name)
	{
		HKEY newHkey;
		DWORD cdisp;
		
		if(ERROR_SUCCESS != RegCreateKeyExA(hkey, unsafeStringz(name), 0, null, 0, KEY_ALL_ACCESS, null, &newHkey, &cdisp))
			throw new DflException("Unable to create registry key");
		
		return new RegistryKey(newHkey);
	}
	
	
	///
	final void deleteSubKey(char[] name, bool throwIfMissing)
	{
		LONG opencode;
		HKEY openHkey;
		char* namez;
		
		if(!name.length || !name[0])
		{
			unable:
			throw new DflException("Unable to delete subkey");
		}
		
		namez = unsafeStringz(name);
		
		opencode = RegOpenKeyExA(hkey, namez, 0, KEY_ALL_ACCESS, &openHkey);
		if(ERROR_SUCCESS == opencode)
		{
			DWORD count;
			
			if(ERROR_SUCCESS == RegQueryInfoKeyA(openHkey, null, null, null, &count,
				null, null, null, null, null, null, null))
			{
				RegCloseKey(openHkey);
				
				if(!count)
				{
					if(ERROR_SUCCESS == RegDeleteKeyA(hkey, namez))
						return; // OK.
					
					goto unable;
				}
				
				throw new DflException("Cannot delete registry key with subkeys");
			}
			
			RegCloseKey(openHkey);
		}
		else
		{
			if(!throwIfMissing)
			{
				switch(opencode)
				{
					case ERROR_FILE_NOT_FOUND:
						return;
					
					default: ;
				}
			}
		}
		
		throw new DflException("Unable to delete registry key");
	}
	
	/// ditto
	final void deleteSubKey(char[] name)
	{
		deleteSubKey(name, true);
	}
	
	
	///
	final void deleteSubKeyTree(char[] name)
	{
		_deleteSubKeyTree(hkey, name);
	}
	
	
	private static void _deleteSubKeyTree(HKEY shkey, char[] name)
	{
		HKEY openHkey;
		char* namez;
		
		namez = unsafeStringz(name);
		
		if(ERROR_SUCCESS == RegOpenKeyExA(shkey, namez, 0, KEY_ALL_ACCESS, &openHkey))
		{
			void ouch()
			{
				throw new DflException("Unable to delete entire subkey tree");
			}
			
			
			DWORD count;
			
			if(ERROR_SUCCESS == RegQueryInfoKeyA(openHkey, null, null, null, &count,
				null, null, null, null, null, null, null))
			{
				if(!count)
				{
					del_me:
					RegCloseKey(openHkey);
					if(ERROR_SUCCESS == RegDeleteKeyA(shkey, namez))
						return; // OK.
					
					//throw new DflException("Unable to delete subkey");
					ouch();
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
						switch(RegEnumKeyExA(openHkey, 0, skn.ptr, &len, null, null, null, null))
						{
							case ERROR_SUCCESS:
								_deleteSubKeyTree(openHkey, skn[0 .. len]);
								goto next_subkey;
							
							case ERROR_NO_MORE_ITEMS:
								// Done!
								break;
							
							default:
								ouch();
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
				ouch();
			}
		}
	}
	
	
	///
	final void deleteValue(char[] name, bool throwIfMissing)
	{
		switch(RegDeleteValueA(hkey, unsafeStringz(name)))
		{
			case ERROR_SUCCESS:
				break;
			
			case ERROR_FILE_NOT_FOUND:
				if(!throwIfMissing)
					break;
			default:
				throw new DflException("Unable to delete registry value");
		}
	}
	
	/// ditto
	final void deleteValue(char[] name)
	{
		deleteValue(name, true);
	}
	
	
	override int opEquals(Object o)
	{
		RegistryKey rk;
		
		rk = cast(RegistryKey)o;
		if(!rk)
			return false;
		return opEquals(rk);
	}
	
	
	int opEquals(RegistryKey rk)
	{
		return hkey == rk.hkey;
	}
	
	
	///
	final void flush()
	{
		RegFlushKey(hkey);
	}
	
	
	///
	final char[][] getSubKeyNames()
	{
		char[MAX_REG_BUFFER] buf;
		DWORD len;
		DWORD idx;
		char[][] result;
		
		key_names:
		for(idx = 0;; idx++)
		{
			len = buf.length;
			switch(RegEnumKeyExA(hkey, idx, buf.ptr, &len, null, null, null, null))
			{
				case ERROR_SUCCESS:
					result ~= buf[0 .. len].dup;
					break;
				
				case ERROR_NO_MORE_ITEMS:
					// Done!
					break key_names;
				
				default:
					throw new DflException("Unable to obtain subkey names");
			}
		}
		
		return result;
	}
	
	
	///
	final RegistryValue getValue(char[] name, RegistryValue defaultValue)
	{
		DWORD type;
		DWORD len;
		ubyte[] data;
		
		len = 0;
		switch(RegQueryValueExA(hkey, unsafeStringz(name), null, &type, null, &len))
		{
			case ERROR_SUCCESS:
				// Good.
				break;
			
			case ERROR_FILE_NOT_FOUND:
				// Value doesn't exist.
				return defaultValue;
			
			default: err:
				throw new DflException("Unable to get registry value");
		}
		
		data = new ubyte[len];
		if(ERROR_SUCCESS != RegQueryValueExA(hkey, unsafeStringz(name), null, &type, data.ptr, &len))
			goto err;
		
		switch(type)
		{
			case REG_SZ:
				with(new RegistryValueSz)
				{
					assert(!data[data.length - 1]);
					value = cast(char[])data[0 .. data.length - 1];
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
					assert(!data[data.length - 1]);
					value = cast(char[])data[0 .. data.length - 1];
					defaultValue = _reg;
				}
				break;
			
			case REG_MULTI_SZ:
				with(new RegistryValueMultiSz)
				{
					char[] s;
					
					next_sz:
					s = stringFromStringz(cast(char*)data);
					if(s.length)
					{
						value ~= s;
						data = data[s.length + 1 .. data.length];
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
				throw new DflException("Unknown type for registry value");
		}
		
		return defaultValue;
	}
	
	/// ditto
	final RegistryValue getValue(char[] name)
	{
		return getValue(name, null);
	}
	
	
	///
	final char[][] getValueNames()
	{
		char[MAX_REG_BUFFER] buf;
		DWORD len;
		DWORD idx;
		char[][] result;
		
		value_names:
		for(idx = 0;; idx++)
		{
			len = buf.length;
			switch(RegEnumValueA(hkey, idx, buf.ptr, &len, null, null, null, null))
			{
				case ERROR_SUCCESS:
					result ~= buf[0 .. len].dup;
					break;
				
				case ERROR_NO_MORE_ITEMS:
					// Done!
					break value_names;
				
				default:
					throw new DflException("Unable to obtain value names");
			}
		}
		
		return result;
	}
	
	
	///
	static RegistryKey openRemoteBaseKey(RegistryHive hhive, char[] machineName)
	{
		HKEY openHkey;
		
		if(ERROR_SUCCESS != RegConnectRegistryA(unsafeStringz(machineName), cast(HKEY)hhive, &openHkey))
			throw new DflException("Unable to open remote base key");
		
		return new RegistryKey(openHkey);
	}
	
	
	///
	// Returns null on error.
	final RegistryKey openSubKey(char[] name, bool writeAccess)
	{
		HKEY openHkey;
		
		if(ERROR_SUCCESS != RegOpenKeyExA(hkey, unsafeStringz(name), 0,
			writeAccess ? KEY_READ | KEY_WRITE : KEY_READ, &openHkey))
			return null;
		
		return new RegistryKey(openHkey);
	}
	
	/// ditto
	final RegistryKey openSubKey(char[] name)
	{
		return openSubKey(name, false);
	}
	
	
	///
	final void setValue(char[] name, RegistryValue value)
	{
		if(ERROR_SUCCESS != value.save(hkey, name))
			throw new DflException("Unable to set registry value");
	}
	
	/// ditto
	// Shortcut.
	final void setValue(char[] name, char[] value)
	{
		scope rv = new RegistryValueSz(value);
		setValue(name, rv);
	}
	
	/// ditto
	// Shortcut.
	final void setValue(char[] name, char[][] value)
	{
		scope rv = new RegistryValueMultiSz(value);
		setValue(name, rv);
	}
	
	/// ditto
	// Shortcut.
	final void setValue(char[] name, DWORD value)
	{
		scope rv = new RegistryValueDword(value);
		setValue(name, rv);
	}
	
	
	///
	// Used internally.
	final HKEY handle() // getter
	{
		return hkey;
	}
	
	
	// Used internally.
	this(HKEY hkey, bool owned = true)
	{
		this.hkey = hkey;
		this.owned = owned;
	}
	
	
	~this()
	{
		if(owned)
			RegCloseKey(hkey);
	}
	
	
	void infoErr()
	{
		throw new DflException("Unable to obtain registry information");
	}
}

