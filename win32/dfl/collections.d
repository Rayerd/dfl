// Written by Christopher E. Miller
// See the included license.txt for copyright and license details.


// Not actually part of forms, but is handy.

///
module dfl.collections;

private import dfl.internal.dlib;

private import dfl.base;


void _blankListCallback(TValue)(size_t idx, TValue val) // package
{
}


// Mixin.
// Item*Callback called before modifications.
// For clear(), index is size_t.max and value is null. If CLEAR_EACH, also called back for each value.
template ListWrapArray(TValue, alias Array,
	/+ // DMD 1.005: basic type expected, not function
	alias ItemAddingCallback = function(size_t idx, TValue val){},
	alias ItemAddedCallback = function(size_t idx, TValue val){},
	alias ItemRemovingCallback = function(size_t idx, TValue val){},
	alias ItemRemovedCallback = function(size_t idx, TValue val){},
	+/
	alias ItemAddingCallback,
	alias ItemAddedCallback,
	alias ItemRemovingCallback,
	alias ItemRemovedCallback,
	bool OVERLOAD_STRING = false,
	bool OVERLOAD_OBJECT = false,
	bool COW = true,
	bool CLEAR_EACH = false) // package
{
	mixin OpApplyWrapArray!(TValue, Array); // Note: this overrides COW.
	
	
	static if(OVERLOAD_OBJECT)
	{
		static assert(!is(TValue == Object));
	}
	
	static if(OVERLOAD_STRING)
	{
		static assert(!is(TValue == Dstring));
		
		static if(is(TValue == Object))
			alias StringObject TValueString;
		else
			alias TValue TValueString;
	}
	
	
	///
	void opIndexAssign(TValue value, int index)
	{
		TValue oldval = Array[index];
		ItemRemovingCallback(index, oldval); // Removing.
		static if(COW)
		{
			Array = Array.dup;
		}
		else
		{
			//Array[index] = TValue.init;
		}
		ItemRemovedCallback(index, oldval); // Removed.
		
		ItemAddingCallback(index, value); // Adding.
		Array[index] = value;
		ItemAddedCallback(index, value); // Added.
	}
	
	static if(OVERLOAD_OBJECT)
	{
		/// ditto
		void opIndexAssign(Object value, int index)
		{
			TValue tval;
			tval = cast(TValue)value;
			if(tval)
				return opIndexAssign(tval, index);
			else
				return opIndexAssign(new TValue(value), index); // ?
		}
	}
	
	static if(OVERLOAD_STRING)
	{
		/// ditto
		void opIndexAssign(Dstring value, int index)
		{
			return opIndexAssign(new TValueString(value), index);
		}
	}
	
	
	///
	@property TValue opIndex(int index) // getter
	{
		return Array[index];
	}
	
	
	///
	void add(TValue value)
	{
		_insert(cast(int)Array.length, value);
	}
	
	static if(OVERLOAD_OBJECT)
	{
		/// ditto
		void add(Object value)
		{
			_insert(cast(int)Array.length, value);
		}
	}
	
	static if(OVERLOAD_STRING)
	{
		/// ditto
		void add(Dstring value)
		{
			_insert(cast(int)Array.length, new TValueString(value));
		}
	}
	
	
	///
	void clear()
	{
		ItemRemovingCallback(size_t.max, null); // Removing ALL.
		
		size_t iw;
		iw = Array.length;
		if(iw)
		{
			static if(CLEAR_EACH)
			{
				try
				{
					// Remove in reverse order so the indices don't keep shifting.
					TValue oldval;
					for(--iw;; iw--)
					{
						oldval = Array[iw];
						static if(CLEAR_EACH)
						{
							ItemRemovingCallback(iw, oldval); // Removing.
						}
						/+static if(COW)
						{
						}
						else
						{
							//Array[iw] = TValue.init;
						}+/
						debug
						{
							Array = Array[0 .. iw]; // 'Temporarily' removes it for ItemRemovedCallback.
						}
						static if(CLEAR_EACH)
						{
							ItemRemovedCallback(iw, oldval); // Removed.
						}
						if(!iw)
							break;
					}
				}
				finally
				{
					Array = Array[0 .. iw];
					static if(COW)
					{
						if(!iw)
							Array = null;
					}
				}
			}
			else
			{
				Array = Array[0 .. 0];
				static if(COW)
				{
					Array = null;
				}
			}
		}
		
		ItemRemovedCallback(size_t.max, null); // Removed ALL.
	}
	
	
	///
	bool contains(TValue value)
	{
		return -1 != findIsIndex!(TValue)(Array, value);
	}
	
	static if(OVERLOAD_OBJECT)
	{
		/// ditto
		bool contains(Object value)
		{
			return -1 != indexOf(value);
		}
	}
	
	static if(OVERLOAD_STRING)
	{
		/// ditto
		bool contains(Dstring value)
		{
			return -1 != indexOf(value);
		}
	}
	
	
	///
	int indexOf(TValue value)
	{
		return findIsIndex!(TValue)(Array, value);
	}
	
	static if(OVERLOAD_OBJECT)
	{
		/// ditto
		int indexOf(Object value)
		{
			TValue tval;
			tval = cast(TValue)value;
			if(tval)
			{
				return indexOf(tval);
			}
			else
			{
				foreach(size_t idx, TValue onval; Array)
				{
					if(onval == value) // TValue must have opEquals.
						return idx;
				}
				return -1;
			}
		}
	}
	
	static if(OVERLOAD_STRING)
	{
		/// ditto
		int indexOf(Dstring value)
		{
			foreach(size_t idx, TValue onval; Array)
			{
				static if(is(TValue == TValueString))
				{
					if(onval == value) // TValue must have opEquals.
						return idx;
				}
				else
				{
					if(getObjectString(onval) == value)
						return idx;
				}
			}
			return -1;
		}
	}
	
	
	private final void _insert(int index, TValue value)
	{
		if(index > Array.length)
			index = Array.length;
		ItemAddingCallback(index, value); // Adding.
		static if(COW)
		{
			if(index >= Array.length)
			{
				if(Array.length) // Workaround old bug ?
				{
					Array = Array[0 .. index] ~ (&value)[0 .. 1];
				}
				else
				{
					Array = (&value)[0 .. 1].dup;
				}
				goto insert_done;
			}
		}
		else
		{
			if(index >= Array.length)
			{
				Array ~= value;
				goto insert_done;
			}
		}
		Array = Array[0 .. index] ~ (&value)[0 .. 1] ~ Array[index .. Array.length];
		insert_done:
		ItemAddedCallback(index, value); // Added.
	}
	
	static if(OVERLOAD_OBJECT)
	{
		private final void _insert(int index, Object value)
		{
			TValue tval;
			tval = cast(TValue)value;
			if(tval)
				return _insert(index, tval);
			else
				return _insert(index, new TValue(value)); // ?
		}
	}
	
	static if(OVERLOAD_STRING)
	{
		/// ditto
		private final void _insert(int index, Dstring value)
		{
			return _insert(index, new TValueString(value));
		}
	}
	
	
	///
	void insert(int index, TValue value)
	{
		_insert(index, value);
	}
	
	static if(OVERLOAD_OBJECT)
	{
		/// ditto
		void insert(int index, Object value)
		{
			_insert(index, value);
		}
	}
	
	static if(OVERLOAD_STRING)
	{
		/// ditto
		void insert(int index, Dstring value)
		{
			return _insert(index, value);
		}
	}
	
	
	///
	void remove(TValue value)
	{
		int index;
		index = findIsIndex!(TValue)(Array, value);
		if(-1 != index)
			removeAt(index);
	}
	
	static if(OVERLOAD_OBJECT)
	{
		/// ditto
		void remove(Object value)
		{
			TValue tval;
			tval = cast(TValue)value;
			if(tval)
			{
				return remove(tval);
			}
			else
			{
				int i;
				i = indexOf(value);
				if(-1 != i)
					removeAt(i);
			}
		}
	}
	
	static if(OVERLOAD_STRING)
	{
		/// ditto
		void remove(Dstring value)
		{
			int i;
			i = indexOf(value);
			if(-1 != i)
				removeAt(i);
		}
	}
	
	
	///
	void removeAt(int index)
	{
		TValue oldval = Array[index];
		ItemRemovingCallback(index, oldval); // Removing.
		if(!index)
			Array = Array[1 .. Array.length];
		else if(index == Array.length - 1)
			Array = Array[0 .. index];
		else if(index > 0 && index < cast(int)Array.length)
			Array = Array[0 .. index] ~ Array[index + 1 .. Array.length];
		ItemRemovedCallback(index, oldval); // Removed.
	}
	
	
	deprecated alias length count;
	
	///
	@property size_t length() // getter
	{
		return Array.length;
	}
	
	
	deprecated alias dup clone;
	
	///
	TValue[] dup()
	{
		return Array.dup;
	}
	
	
	///
	void copyTo(TValue[] dest, int destIndex)
	{
		dest[destIndex .. destIndex + Array.length] = Array[];
	}
	
	
	///
	void addRange(TValue[] values)
	{
		foreach(TValue value; values)
		{
			add(value);
		}
	}
	
	static if(OVERLOAD_OBJECT)
	{
		/// ditto
		void addRange(Object[] values)
		{
			foreach(Object value; values)
			{
				add(value);
			}
		}
	}
	
	static if(OVERLOAD_STRING)
	{
		/// ditto
		void addRange(Dstring[] values)
		{
			foreach(Dstring value; values)
			{
				add(value);
			}
		}
	}
}


// Mixin.
template OpApplyAddIndex(alias ApplyFunc, TValue, bool ADD_APPLY_FUNC = false) // package
{
	///
	int opApply(int delegate(ref size_t, ref TValue val) dg)
	{
		size_t idx = 0;
		return ApplyFunc(
			(ref TValue val)
			{
				int result;
				result = dg(idx, val);
				idx++;
				return result;
			});
	}
	
	
	static if(ADD_APPLY_FUNC)
	{
		/// ditto
		int opApply(int delegate(ref TValue val) dg)
		{
			return ApplyFunc(dg);
		}
	}
}


// Mixin.
template OpApplyWrapArray(TValue, alias Array) // package
{
	///
	int opApply(int delegate(ref TValue val) dg)
	{
		int result = 0;
		foreach(ref TValue val; Array)
		{
			result = dg(val);
			if(result)
				break;
		}
		return result;
	}
	
	/// ditto
	int opApply(int delegate(ref size_t, ref TValue val) dg)
	{
		int result = 0;
		foreach(size_t idx, ref TValue val; Array)
		{
			result = dg(idx, val);
			if(result)
				break;
		}
		return result;
	}
}


template removeIndex(T) // package
{
	T[] removeIndex(T[] array, size_t index)
	{
		if(!index)
			array = array[1 .. array.length];
		else if(index == array.length - 1)
			array = array[0 .. index];
		else
			array = array[0 .. index] ~ array[index + 1 .. array.length];
		return array;
	}
}


// Returns -1 if not found.
template findIsIndex(T) // package
{
	int findIsIndex(T[] array, T obj)
	{
		int idx;
		for(idx = 0; idx != array.length; idx++)
		{
			if(obj is array[idx])
				return idx;
		}
		return -1;
	}
}

