// Public domain.


module dfl.internal.clib;


public import core.stdc.stdlib,
	core.stdc.string,
	core.stdc.stdint, // Mostly the same as the C interface.
	core.stdc.stdio;
	
alias core.stdc.stdio.printf cprintf;
