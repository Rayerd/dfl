import dfl.registry;
import std.stdio : writeln;
import std.range : take;
import core.sys.windows.windef : DWORD;

version(Have_dfl) // For DUB.
{
}
else
{
	pragma(lib, "dfl.lib");
}

// helper
string fromValueType(DWORD valueType)
{
	return [
		"REG_NONE",
		"REG_SZ",
		"REG_EXPAND_SZ",
		"REG_BINARY",
		"REG_DWORD_LITTLE_ENDIAN",
		"REG_DWORD = REG_DWORD_LITTLE_ENDIAN",
		"REG_DWORD_BIG_ENDIAN",
		"REG_LINK",
		"REG_MULTI_SZ",
		"REG_RESOURCE_LIST",
		"REG_FULL_RESOURCE_DESCRIPTOR",
		"REG_RESOURCE_REQUIREMENTS_LIST",
		"REG_QWORD_LITTLE_ENDIAN",
		"REG_QWORD = REG_QWORD_LITTLE_ENDIAN"
	][valueType];
}

void main()
{
	RegistryKey key1 = Registry.currentUser();

	RegistryKey key2 = key1.openSubKey("Console");

	writeln("valueCount: ", key1.valueCount);
	writeln("getValueNames: ", key1.getValueNames.take(10));
	writeln("subKeyCount: ", key1.subKeyCount);
	writeln("getSubKeyNames: ", key1.getSubKeyNames.take(10));

	RegistryValue value1 = key2.getValue("WindowSize");
	writeln("- WindowSize");
	writeln("valueType: ", fromValueType(value1.valueType()));
	writeln("value: ", value1.toString());

	RegistryValue value2 = key2.getValue("FaceName");
	writeln("- FaceName");
	writeln("valueType: ", fromValueType(value2.valueType()));
	writeln("value: ", value2.toString());

	RegistryKey key3 = key2.createSubKey("_DFL_TEST_KEY_");
	key3.setValue("_DFL_TEST_VALUE_", 255);
	RegistryValue value3 = key3.getValue("_DFL_TEST_VALUE_");
	writeln("value: ", value3.toString());

	key2.deleteSubKey("_DFL_TEST_KEY_", true);

	key1.flush();
}
