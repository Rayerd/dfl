// Public domain.


module dfl.internal.clib;


version(Tango)
{
	public import tango.stdc.stdlib,
		tango.stdc.string,
		tango.stdc.stdint,
		tango.stdc.stdio;
	
	alias tango.stdc.stdio.printf cprintf;
}
else // Phobos
{
	public import std.c.stdlib,
		std.c.string,
		std.stdint, // Mostly the same as the C interface.
		std.c.stdio;
	
	alias std.c.stdio.printf cprintf;
}

