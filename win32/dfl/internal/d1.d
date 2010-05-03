// Written by Christopher E. Miller
// See the included license.txt for copyright and license details.


module dfl.internal.d1;


/// Gets the const type of a type, or the type itself if not supported.
template ConstType(T)
{
	alias T ConstType;
}

