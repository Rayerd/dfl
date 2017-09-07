// Written in the D programming language

/**
 * $(RED Deprecated: This module is considered out-dated and not up to Phobos'
 *       current standards. It will be remove in October 2016.)
 *
 * Source:    $(PHOBOSSRC std/_stream.d)
 * Macros:
 *      WIKI = Phobos/StdStream
 */

/*
 * Copyright (c) 2001-2005
 * Pavel "EvilOne" Minayev
 *  with buffering and endian support added by Ben Hinkle
 *  with buffered readLine performance improvements by Dave Fladebo
 *  with opApply inspired by (and mostly copied from) Regan Heath
 *  with bug fixes and MemoryStream/SliceStream enhancements by Derick Eddington
 *
 * Permission to use, copy, modify, distribute and sell this software
 * and its documentation for any purpose is hereby granted without fee,
 * provided that the above copyright notice appear in all copies and
 * that both that copyright notice and this permission notice appear
 * in supporting documentation.  Author makes no representations about
 * the suitability of this software for any purpose. It is provided
 * "as is" without express or implied warranty.
 */
module dfl.internal.stream;
// @@@DEPRECATED_2016-10@@@


import std.internal.cstring;

/* Class structure:
 *  InputStream       interface for reading
 *  OutputStream      interface for writing
 *  Stream            abstract base of stream implementations
 *    File            an OS file stream
 *    FilterStream    a base-class for wrappers around another stream
 *      BufferedStream  a buffered stream wrapping another stream
 *        BufferedFile  a buffered File
 *      EndianStream    a wrapper stream for swapping byte order and BOMs
 *      SliceStream     a portion of another stream
 *    MemoryStream    a stream entirely stored in main memory
 *    TArrayStream    a stream wrapping an array-like buffer
 */

/// A base class for stream exceptions.
class StreamException: Exception {
  /// Construct a StreamException with given error message.
  this(string msg) { super(msg); }
}

/// Thrown when unable to read data from Stream.
class ReadException: StreamException {
  /// Construct a ReadException with given error message.
  this(string msg) { super(msg); }
}

/// Thrown when unable to write data to Stream.
class WriteException: StreamException {
  /// Construct a WriteException with given error message.
  this(string msg) { super(msg); }
}

/// Thrown when unable to move Stream pointer.
class SeekException: StreamException {
  /// Construct a SeekException with given error message.
  this(string msg) { super(msg); }
}

// seek whence...
enum SeekPos {
  Set,
  Current,
  End
}

private {
  import std.conv;
  import std.algorithm;
  import std.ascii;
  import std.format;
  import std.system;    // for Endian enumeration
  import std.utf;
  import core.bitop; // for bswap
  import core.vararg;
  import std.file;
}

/// InputStream is the interface for readable streams.

interface InputStream {

  /***
   * Read exactly size bytes into the buffer.
   *
   * Throws a ReadException if it is not correct.
   */
  void readExact(void* buffer, size_t size);

  /***
   * Read a block of data big enough to fill the given array buffer.
   *
   * Returns: the actual number of bytes read. Unfilled bytes are not modified.
   */
  size_t read(ubyte[] buffer);

  /***
   * Read a basic type or counted string.
   *
   * Throw a ReadException if it could not be read.
   * Outside of byte, ubyte, and char, the format is
   * implementation-specific and should not be used except as opposite actions
   * to write.
   */
  void read(out byte x);
  void read(out ubyte x);       /// ditto
  void read(out short x);       /// ditto
  void read(out ushort x);      /// ditto
  void read(out int x);         /// ditto
  void read(out uint x);        /// ditto
  void read(out long x);        /// ditto
  void read(out ulong x);       /// ditto
  void read(out float x);       /// ditto
  void read(out double x);      /// ditto
  void read(out real x);        /// ditto
  void read(out ifloat x);      /// ditto
  void read(out idouble x);     /// ditto
  void read(out ireal x);       /// ditto
  void read(out cfloat x);      /// ditto
  void read(out cdouble x);     /// ditto
  void read(out creal x);       /// ditto
  void read(out char x);        /// ditto
  void read(out wchar x);       /// ditto
  void read(out dchar x);       /// ditto

  // reads a string, written earlier by write()
  void read(out char[] s);      /// ditto

  // reads a Unicode string, written earlier by write()
  void read(out wchar[] s);     /// ditto

  /***
   * Read a line that is terminated with some combination of carriage return and
   * line feed or end-of-file.
   *
   * The terminators are not included. The wchar version
   * is identical. The optional buffer parameter is filled (reallocating
   * it if necessary) and a slice of the result is returned.
   */
  char[] readLine();
  char[] readLine(char[] result);       /// ditto
  wchar[] readLineW();                  /// ditto
  wchar[] readLineW(wchar[] result);    /// ditto

  /***
   * Overload foreach statements to read the stream line by line and call the
   * supplied delegate with each line or with each line with line number.
   *
   * The string passed in line may be reused between calls to the delegate.
   * Line numbering starts at 1.
   * Breaking out of the foreach will leave the stream
   * position at the beginning of the next line to be read.
   * For example, to echo a file line-by-line with line numbers run:
   * ------------------------------------
   * Stream file = new BufferedFile("sample.txt");
   * foreach(ulong n, char[] line; file)
   * {
   *     writefln("line %d: %s", n, line);
   * }
   * file.close();
   * ------------------------------------
   */

  // iterate through the stream line-by-line
  int opApply(scope int delegate(ref char[] line) dg);
  int opApply(scope int delegate(ref ulong n, ref char[] line) dg);  /// ditto
  int opApply(scope int delegate(ref wchar[] line) dg);            /// ditto
  int opApply(scope int delegate(ref ulong n, ref wchar[] line) dg); /// ditto

  /// Read a string of the given length,
  /// throwing ReadException if there was a problem.
  char[] readString(size_t length);

  /***
   * Read a string of the given length, throwing ReadException if there was a
   * problem.
   *
   * The file format is implementation-specific and should not be used
   * except as opposite actions to <b>write</b>.
   */

  wchar[] readStringW(size_t length);


  /***
   * Read and return the next character in the stream.
   *
   * This is the only method that will handle ungetc properly.
   * getcw's format is implementation-specific.
   * If EOF is reached then getc returns char.init and getcw returns wchar.init.
   */

  char getc();
  wchar getcw(); /// ditto

  /***
   * Push a character back onto the stream.
   *
   * They will be returned in first-in last-out order from getc/getcw.
   * Only has effect on further calls to getc() and getcw().
   */
  char ungetc(char c);
  wchar ungetcw(wchar c); /// ditto

  /***
   * Scan a string from the input using a similar form to C's scanf
   * and <a href="std_format.html">std.format</a>.
   *
   * An argument of type string is interpreted as a format string.
   * All other arguments must be pointer types.
   * If a format string is not present a default will be supplied computed from
   * the base type of the pointer type. An argument of type string* is filled
   * (possibly with appending characters) and a slice of the result is assigned
   * back into the argument. For example the following readf statements
   * are equivalent:
   * --------------------------
   * int x;
   * double y;
   * string s;
   * file.readf(&x, " hello ", &y, &s);
   * file.readf("%d hello %f %s", &x, &y, &s);
   * file.readf("%d hello %f", &x, &y, "%s", &s);
   * --------------------------
   */
  int vreadf(TypeInfo[] arguments, va_list args);
  int readf(...); /// ditto

  /// Retrieve the number of bytes available for immediate reading.
  @property size_t available();

  /***
   * Return whether the current file position is the same as the end of the
   * file.
   *
   * This does not require actually reading past the end, as with stdio. For
   * non-seekable streams this might only return true after attempting to read
   * past the end.
   */

  @property bool eof();

  @property bool isOpen();        /// Return true if the stream is currently open.
}

/// Interface for writable streams.
interface OutputStream {

  /***
   * Write exactly size bytes from buffer, or throw a WriteException if that
   * could not be done.
   */
  void writeExact(const void* buffer, size_t size);

  /***
   * Write as much of the buffer as possible,
   * returning the number of bytes written.
   */
  size_t write(const(ubyte)[] buffer);

  /***
   * Write a basic type.
   *
   * Outside of byte, ubyte, and char, the format is implementation-specific
   * and should only be used in conjunction with read.
   * Throw WriteException on error.
   */
  void write(byte x);
  void write(ubyte x);          /// ditto
  void write(short x);          /// ditto
  void write(ushort x);         /// ditto
  void write(int x);            /// ditto
  void write(uint x);           /// ditto
  void write(long x);           /// ditto
  void write(ulong x);          /// ditto
  void write(float x);          /// ditto
  void write(double x);         /// ditto
  void write(real x);           /// ditto
  void write(ifloat x);         /// ditto
  void write(idouble x);        /// ditto
  void write(ireal x);          /// ditto
  void write(cfloat x);         /// ditto
  void write(cdouble x);        /// ditto
  void write(creal x);          /// ditto
  void write(char x);           /// ditto
  void write(wchar x);          /// ditto
  void write(dchar x);          /// ditto

  /***
   * Writes a string, together with its length.
   *
   * The format is implementation-specific
   * and should only be used in conjunction with read.
   * Throw WriteException on error.
   */
    void write(const(char)[] s);
    void write(const(wchar)[] s); /// ditto

  /***
   * Write a line of text,
   * appending the line with an operating-system-specific line ending.
   *
   * Throws WriteException on error.
   */
  void writeLine(const(char)[] s);

  /***
   * Write a line of text,
   * appending the line with an operating-system-specific line ending.
   *
   * The format is implementation-specific.
   * Throws WriteException on error.
   */
    void writeLineW(const(wchar)[] s);

  /***
   * Write a string of text.
   *
   * Throws WriteException if it could not be fully written.
   */
    void writeString(const(char)[] s);

  /***
   * Write a string of text.
   *
   * The format is implementation-specific.
   * Throws WriteException if it could not be fully written.
   */
  void writeStringW(const(wchar)[] s);

  /***
   * Print a formatted string into the stream using printf-style syntax,
   * returning the number of bytes written.
   */
  size_t vprintf(const(char)[] format, va_list args);
  size_t printf(const(char)[] format, ...);    /// ditto

  /***
   * Print a formatted string into the stream using writef-style syntax.
   * References: <a href="std_format.html">std.format</a>.
   * Returns: self to chain with other stream commands like flush.
   */
  OutputStream writef(...);
  OutputStream writefln(...); /// ditto
  OutputStream writefx(TypeInfo[] arguments, va_list argptr, int newline = false);  /// ditto

  void flush(); /// Flush pending output if appropriate.
  void close(); /// Close the stream, flushing output if appropriate.
  @property bool isOpen(); /// Return true if the stream is currently open.
}


/***
 * Stream is the base abstract class from which the other stream classes derive.
 *
 * Stream's byte order is the format native to the computer.
 *
 * Reading:
 * These methods require that the readable flag be set.
 * Problems with reading result in a ReadException being thrown.
 * Stream implements the InputStream interface in addition to the
 * readBlock method.
 *
 * Writing:
 * These methods require that the writeable flag be set. Problems with writing
 * result in a WriteException being thrown. Stream implements the OutputStream
 * interface in addition to the following methods:
 * writeBlock
 * copyFrom
 * copyFrom
 *
 * Seeking:
 * These methods require that the seekable flag be set.
 * Problems with seeking result in a SeekException being thrown.
 * seek, seekSet, seekCur, seekEnd, position, size, toString, toHash
 */

// not really abstract, but its instances will do nothing useful
class Stream : InputStream, OutputStream {
  private import std.string, std.digest.crc, core.stdc.stdlib, core.stdc.stdio;

  // stream abilities
  bool readable = false;        /// Indicates whether this stream can be read from.
  bool writeable = false;       /// Indicates whether this stream can be written to.
  bool seekable = false;        /// Indicates whether this stream can be seeked within.
  protected bool isopen = true; /// Indicates whether this stream is open.

  protected bool readEOF = false; /** Indicates whether this stream is at eof
                                   * after the last read attempt.
                                   */

  protected bool prevCr = false; /** For a non-seekable stream indicates that
                                  * the last readLine or readLineW ended on a
                                  * '\r' character.
                                  */

  this() {}

  /***
   * Read up to size bytes into the buffer and return the number of bytes
   * actually read. A return value of 0 indicates end-of-file.
   */
  abstract size_t readBlock(void* buffer, size_t size);

  // reads block of data of specified size,
  // throws ReadException on error
  void readExact(void* buffer, size_t size) {
    for(;;) {
      if (!size) return;
      size_t readsize = readBlock(buffer, size); // return 0 on eof
      if (readsize == 0) break;
      buffer += readsize;
      size -= readsize;
    }
    if (size != 0)
      throw new ReadException("not enough data in stream");
  }

  // reads block of data big enough to fill the given
  // array, returns actual number of bytes read
  size_t read(ubyte[] buffer) {
    return readBlock(buffer.ptr, buffer.length);
  }

  // read a single value of desired type,
  // throw ReadException on error
  void read(out byte x) { readExact(&x, x.sizeof); }
  void read(out ubyte x) { readExact(&x, x.sizeof); }
  void read(out short x) { readExact(&x, x.sizeof); }
  void read(out ushort x) { readExact(&x, x.sizeof); }
  void read(out int x) { readExact(&x, x.sizeof); }
  void read(out uint x) { readExact(&x, x.sizeof); }
  void read(out long x) { readExact(&x, x.sizeof); }
  void read(out ulong x) { readExact(&x, x.sizeof); }
  void read(out float x) { readExact(&x, x.sizeof); }
  void read(out double x) { readExact(&x, x.sizeof); }
  void read(out real x) { readExact(&x, x.sizeof); }
  void read(out ifloat x) { readExact(&x, x.sizeof); }
  void read(out idouble x) { readExact(&x, x.sizeof); }
  void read(out ireal x) { readExact(&x, x.sizeof); }
  void read(out cfloat x) { readExact(&x, x.sizeof); }
  void read(out cdouble x) { readExact(&x, x.sizeof); }
  void read(out creal x) { readExact(&x, x.sizeof); }
  void read(out char x) { readExact(&x, x.sizeof); }
  void read(out wchar x) { readExact(&x, x.sizeof); }
  void read(out dchar x) { readExact(&x, x.sizeof); }

  // reads a string, written earlier by write()
  void read(out char[] s) {
    size_t len;
    read(len);
    s = readString(len);
  }

  // reads a Unicode string, written earlier by write()
  void read(out wchar[] s) {
    size_t len;
    read(len);
    s = readStringW(len);
  }

  // reads a line, terminated by either CR, LF, CR/LF, or EOF
  char[] readLine() {
    return readLine(null);
  }

  // reads a line, terminated by either CR, LF, CR/LF, or EOF
  // reusing the memory in buffer if result will fit and otherwise
  // allocates a new string
  char[] readLine(char[] result) {
    size_t strlen = 0;
    char ch = getc();
    while (readable) {
      switch (ch) {
      case '\r':
        if (seekable) {
          ch = getc();
          if (ch != '\n')
            ungetc(ch);
        } else {
          prevCr = true;
        }
        goto case;
      case '\n':
      case char.init:
        result.length = strlen;
        return result;

      default:
        if (strlen < result.length) {
          result[strlen] = ch;
        } else {
          result ~= ch;
        }
        strlen++;
      }
      ch = getc();
    }
    result.length = strlen;
    return result;
  }

  // reads a Unicode line, terminated by either CR, LF, CR/LF,
  // or EOF; pretty much the same as the above, working with
  // wchars rather than chars
  wchar[] readLineW() {
    return readLineW(null);
  }

  // reads a Unicode line, terminated by either CR, LF, CR/LF,
  // or EOF;
  // fills supplied buffer if line fits and otherwise allocates a new string.
  wchar[] readLineW(wchar[] result) {
    size_t strlen = 0;
    wchar c = getcw();
    while (readable) {
      switch (c) {
      case '\r':
        if (seekable) {
          c = getcw();
          if (c != '\n')
            ungetcw(c);
        } else {
          prevCr = true;
        }
        goto case;
      case '\n':
      case wchar.init:
        result.length = strlen;
        return result;

      default:
        if (strlen < result.length) {
          result[strlen] = c;
        } else {
          result ~= c;
        }
        strlen++;
      }
      c = getcw();
    }
    result.length = strlen;
    return result;
  }

  // iterate through the stream line-by-line - due to Regan Heath
  int opApply(scope int delegate(ref char[] line) dg) {
    int res = 0;
    char[128] buf;
    while (!eof) {
      char[] line = readLine(buf);
      res = dg(line);
      if (res) break;
    }
    return res;
  }

  // iterate through the stream line-by-line with line count and string
  int opApply(scope int delegate(ref ulong n, ref char[] line) dg) {
    int res = 0;
    ulong n = 1;
    char[128] buf;
    while (!eof) {
      auto line = readLine(buf);
      res = dg(n,line);
      if (res) break;
      n++;
    }
    return res;
  }

  // iterate through the stream line-by-line with wchar[]
  int opApply(scope int delegate(ref wchar[] line) dg) {
    int res = 0;
    wchar[128] buf;
    while (!eof) {
      auto line = readLineW(buf);
      res = dg(line);
      if (res) break;
    }
    return res;
  }

  // iterate through the stream line-by-line with line count and wchar[]
  int opApply(scope int delegate(ref ulong n, ref wchar[] line) dg) {
    int res = 0;
    ulong n = 1;
    wchar[128] buf;
    while (!eof) {
      auto line = readLineW(buf);
      res = dg(n,line);
      if (res) break;
      n++;
    }
    return res;
  }

  // reads a string of given length, throws
  // ReadException on error
  char[] readString(size_t length) {
    char[] result = new char[length];
    readExact(result.ptr, length);
    return result;
  }

  // reads a Unicode string of given length, throws
  // ReadException on error
  wchar[] readStringW(size_t length) {
    auto result = new wchar[length];
    readExact(result.ptr, result.length * wchar.sizeof);
    return result;
  }

  // unget buffer
  private wchar[] unget;
  final bool ungetAvailable() { return unget.length > 1; }

  // reads and returns next character from the stream,
  // handles characters pushed back by ungetc()
  // returns char.init on eof.
  char getc() {
    char c;
    if (prevCr) {
      prevCr = false;
      c = getc();
      if (c != '\n')
        return c;
    }
    if (unget.length > 1) {
      c = cast(char)unget[unget.length - 1];
      unget.length = unget.length - 1;
    } else {
      readBlock(&c,1);
    }
    return c;
  }

  // reads and returns next Unicode character from the
  // stream, handles characters pushed back by ungetc()
  // returns wchar.init on eof.
  wchar getcw() {
    wchar c;
    if (prevCr) {
      prevCr = false;
      c = getcw();
      if (c != '\n')
        return c;
    }
    if (unget.length > 1) {
      c = unget[unget.length - 1];
      unget.length = unget.length - 1;
    } else {
      void* buf = &c;
      size_t n = readBlock(buf,2);
      if (n == 1 && readBlock(buf+1,1) == 0)
          throw new ReadException("not enough data in stream");
    }
    return c;
  }

  // pushes back character c into the stream; only has
  // effect on further calls to getc() and getcw()
  char ungetc(char c) {
    if (c == c.init) return c;
    // first byte is a dummy so that we never set length to 0
    if (unget.length == 0)
      unget.length = 1;
    unget ~= c;
    return c;
  }

  // pushes back Unicode character c into the stream; only
  // has effect on further calls to getc() and getcw()
  wchar ungetcw(wchar c) {
    if (c == c.init) return c;
    // first byte is a dummy so that we never set length to 0
    if (unget.length == 0)
      unget.length = 1;
    unget ~= c;
    return c;
  }

  int vreadf(TypeInfo[] arguments, va_list args) {
    string fmt;
    int j = 0;
    int count = 0, i = 0;
    char c;
    bool firstCharacter = true;
    while ((j < arguments.length || i < fmt.length) && !eof) {
      if(firstCharacter) {
        c = getc();
        firstCharacter = false;
      }
      if (fmt.length == 0 || i == fmt.length) {
        i = 0;
        if (arguments[j] is typeid(string) || arguments[j] is typeid(char[])
            || arguments[j] is typeid(const(char)[])) {
          fmt = va_arg!(string)(args);
          j++;
          continue;
        } else if (arguments[j] is typeid(int*) ||
                   arguments[j] is typeid(byte*) ||
                   arguments[j] is typeid(short*) ||
                   arguments[j] is typeid(long*)) {
          fmt = "%d";
        } else if (arguments[j] is typeid(uint*) ||
                   arguments[j] is typeid(ubyte*) ||
                   arguments[j] is typeid(ushort*) ||
                   arguments[j] is typeid(ulong*)) {
          fmt = "%d";
        } else if (arguments[j] is typeid(float*) ||
                   arguments[j] is typeid(double*) ||
                   arguments[j] is typeid(real*)) {
          fmt = "%f";
        } else if (arguments[j] is typeid(char[]*) ||
                   arguments[j] is typeid(wchar[]*) ||
                   arguments[j] is typeid(dchar[]*)) {
          fmt = "%s";
        } else if (arguments[j] is typeid(char*)) {
          fmt = "%c";
        }
      }
      if (fmt[i] == '%') {      // a field
        i++;
        bool suppress = false;
        if (fmt[i] == '*') {    // suppress assignment
          suppress = true;
          i++;
        }
        // read field width
        int width = 0;
        while (isDigit(fmt[i])) {
          width = width * 10 + (fmt[i] - '0');
          i++;
        }
        if (width == 0)
          width = -1;
        // skip any modifier if present
        if (fmt[i] == 'h' || fmt[i] == 'l' || fmt[i] == 'L')
          i++;
        // check the typechar and act accordingly
        switch (fmt[i]) {
        case 'd':       // decimal/hexadecimal/octal integer
        case 'D':
        case 'u':
        case 'U':
        case 'o':
        case 'O':
        case 'x':
        case 'X':
        case 'i':
        case 'I':
          {
            while (isWhite(c)) {
              c = getc();
              count++;
            }
            bool neg = false;
            if (c == '-') {
              neg = true;
              c = getc();
              count++;
            } else if (c == '+') {
              c = getc();
              count++;
            }
            char ifmt = cast(char)(fmt[i] | 0x20);
            if (ifmt == 'i')    { // undetermined base
              if (c == '0')     { // octal or hex
                c = getc();
                count++;
                if (c == 'x' || c == 'X')       { // hex
                  ifmt = 'x';
                  c = getc();
                  count++;
                } else {        // octal
                  ifmt = 'o';
                }
              }
              else      // decimal
                ifmt = 'd';
            }
            long n = 0;
            switch (ifmt)
            {
                case 'd':       // decimal
                case 'u': {
                  while (isDigit(c) && width) {
                    n = n * 10 + (c - '0');
                    width--;
                    c = getc();
                    count++;
                  }
                } break;

                case 'o': {     // octal
                  while (isOctalDigit(c) && width) {
                    n = n * 8 + (c - '0');
                    width--;
                    c = getc();
                    count++;
                  }
                } break;

                case 'x': {     // hexadecimal
                  while (isHexDigit(c) && width) {
                    n *= 0x10;
                    if (isDigit(c))
                      n += c - '0';
                    else
                      n += 0xA + (c | 0x20) - 'a';
                    width--;
                    c = getc();
                    count++;
                  }
                } break;

                default:
                    assert(0);
            }
            if (neg)
              n = -n;
            if (arguments[j] is typeid(int*)) {
              int* p = va_arg!(int*)(args);
              *p = cast(int)n;
            } else if (arguments[j] is typeid(short*)) {
              short* p = va_arg!(short*)(args);
              *p = cast(short)n;
            } else if (arguments[j] is typeid(byte*)) {
              byte* p = va_arg!(byte*)(args);
              *p = cast(byte)n;
            } else if (arguments[j] is typeid(long*)) {
              long* p = va_arg!(long*)(args);
              *p = n;
            } else if (arguments[j] is typeid(uint*)) {
              uint* p = va_arg!(uint*)(args);
              *p = cast(uint)n;
            } else if (arguments[j] is typeid(ushort*)) {
              ushort* p = va_arg!(ushort*)(args);
              *p = cast(ushort)n;
            } else if (arguments[j] is typeid(ubyte*)) {
              ubyte* p = va_arg!(ubyte*)(args);
              *p = cast(ubyte)n;
            } else if (arguments[j] is typeid(ulong*)) {
              ulong* p = va_arg!(ulong*)(args);
              *p = cast(ulong)n;
            }
            j++;
            i++;
          } break;

        case 'f':       // float
        case 'F':
        case 'e':
        case 'E':
        case 'g':
        case 'G':
          {
            while (isWhite(c)) {
              c = getc();
              count++;
            }
            bool neg = false;
            if (c == '-') {
              neg = true;
              c = getc();
              count++;
            } else if (c == '+') {
              c = getc();
              count++;
            }
            real r = 0;
            while (isDigit(c) && width) {
              r = r * 10 + (c - '0');
              width--;
              c = getc();
              count++;
            }
            if (width && c == '.') {
              width--;
              c = getc();
              count++;
              double frac = 1;
              while (isDigit(c) && width) {
                r = r * 10 + (c - '0');
                frac *= 10;
                width--;
                c = getc();
                count++;
              }
              r /= frac;
            }
            if (width && (c == 'e' || c == 'E')) {
              width--;
              c = getc();
              count++;
              if (width) {
                bool expneg = false;
                if (c == '-') {
                  expneg = true;
                  width--;
                  c = getc();
                  count++;
                } else if (c == '+') {
                  width--;
                  c = getc();
                  count++;
                }
                real exp = 0;
                while (isDigit(c) && width) {
                  exp = exp * 10 + (c - '0');
                  width--;
                  c = getc();
                  count++;
                }
                if (expneg) {
                  while (exp--)
                    r /= 10;
                } else {
                  while (exp--)
                    r *= 10;
                }
              }
            }
            if(width && (c == 'n' || c == 'N')) {
              width--;
              c = getc();
              count++;
              if(width && (c == 'a' || c == 'A')) {
                width--;
                c = getc();
                count++;
                if(width && (c == 'n' || c == 'N')) {
                  width--;
                  c = getc();
                  count++;
                  r = real.nan;
                }
              }
            }
            if(width && (c == 'i' || c == 'I')) {
              width--;
              c = getc();
              count++;
              if(width && (c == 'n' || c == 'N')) {
                width--;
                c = getc();
                count++;
                if(width && (c == 'f' || c == 'F')) {
                  width--;
                  c = getc();
                  count++;
                  r = real.infinity;
                }
              }
            }
            if (neg)
              r = -r;
            if (arguments[j] is typeid(float*)) {
              float* p = va_arg!(float*)(args);
              *p = r;
            } else if (arguments[j] is typeid(double*)) {
              double* p = va_arg!(double*)(args);
              *p = r;
            } else if (arguments[j] is typeid(real*)) {
              real* p = va_arg!(real*)(args);
              *p = r;
            }
            j++;
            i++;
          } break;

        case 's': {     // string
          while (isWhite(c)) {
            c = getc();
            count++;
          }
          char[] s;
          char[]* p;
          size_t strlen;
          if (arguments[j] is typeid(char[]*)) {
            p = va_arg!(char[]*)(args);
            s = *p;
          }
          while (!isWhite(c) && c != char.init) {
            if (strlen < s.length) {
              s[strlen] = c;
            } else {
              s ~= c;
            }
            strlen++;
            c = getc();
            count++;
          }
          s = s[0 .. strlen];
          if (arguments[j] is typeid(char[]*)) {
            *p = s;
          } else if (arguments[j] is typeid(char*)) {
            s ~= 0;
            auto q = va_arg!(char*)(args);
            q[0 .. s.length] = s[];
          } else if (arguments[j] is typeid(wchar[]*)) {
            auto q = va_arg!(const(wchar)[]*)(args);
            *q = toUTF16(s);
          } else if (arguments[j] is typeid(dchar[]*)) {
            auto q = va_arg!(const(dchar)[]*)(args);
            *q = toUTF32(s);
          }
          j++;
          i++;
        } break;

        case 'c': {     // character(s)
          char* s = va_arg!(char*)(args);
          if (width < 0)
            width = 1;
          else
            while (isWhite(c)) {
            c = getc();
            count++;
          }
          while (width-- && !eof) {
            *(s++) = c;
            c = getc();
            count++;
          }
          j++;
          i++;
        } break;

        case 'n': {     // number of chars read so far
          int* p = va_arg!(int*)(args);
          *p = count;
          j++;
          i++;
        } break;

        default:        // read character as is
          goto nws;
        }
      } else if (isWhite(fmt[i])) {     // skip whitespace
        while (isWhite(c))
          c = getc();
        i++;
      } else {  // read character as is
      nws:
        if (fmt[i] != c)
          break;
        c = getc();
        i++;
      }
    }
    ungetc(c);
    return count;
  }

  int readf(...) {
    return vreadf(_arguments, _argptr);
  }

  // returns estimated number of bytes available for immediate reading
  @property size_t available() { return 0; }

  /***
   * Write up to size bytes from buffer in the stream, returning the actual
   * number of bytes that were written.
   */
  abstract size_t writeBlock(const void* buffer, size_t size);

  // writes block of data of specified size,
  // throws WriteException on error
  void writeExact(const void* buffer, size_t size) {
    const(void)* p = buffer;
    for(;;) {
      if (!size) return;
      size_t writesize = writeBlock(p, size);
      if (writesize == 0) break;
      p += writesize;
      size -= writesize;
    }
    if (size != 0)
      throw new WriteException("unable to write to stream");
  }

  // writes the given array of bytes, returns
  // actual number of bytes written
  size_t write(const(ubyte)[] buffer) {
    return writeBlock(buffer.ptr, buffer.length);
  }

  // write a single value of desired type,
  // throw WriteException on error
  void write(byte x) { writeExact(&x, x.sizeof); }
  void write(ubyte x) { writeExact(&x, x.sizeof); }
  void write(short x) { writeExact(&x, x.sizeof); }
  void write(ushort x) { writeExact(&x, x.sizeof); }
  void write(int x) { writeExact(&x, x.sizeof); }
  void write(uint x) { writeExact(&x, x.sizeof); }
  void write(long x) { writeExact(&x, x.sizeof); }
  void write(ulong x) { writeExact(&x, x.sizeof); }
  void write(float x) { writeExact(&x, x.sizeof); }
  void write(double x) { writeExact(&x, x.sizeof); }
  void write(real x) { writeExact(&x, x.sizeof); }
  void write(ifloat x) { writeExact(&x, x.sizeof); }
  void write(idouble x) { writeExact(&x, x.sizeof); }
  void write(ireal x) { writeExact(&x, x.sizeof); }
  void write(cfloat x) { writeExact(&x, x.sizeof); }
  void write(cdouble x) { writeExact(&x, x.sizeof); }
  void write(creal x) { writeExact(&x, x.sizeof); }
  void write(char x) { writeExact(&x, x.sizeof); }
  void write(wchar x) { writeExact(&x, x.sizeof); }
  void write(dchar x) { writeExact(&x, x.sizeof); }

  // writes a string, together with its length
  void write(const(char)[] s) {
    write(s.length);
    writeString(s);
  }

  // writes a Unicode string, together with its length
  void write(const(wchar)[] s) {
    write(s.length);
    writeStringW(s);
  }

  // writes a line, throws WriteException on error
  void writeLine(const(char)[] s) {
    writeString(s);
    version (Windows)
      writeString("\r\n");
    else version (Mac)
      writeString("\r");
    else
      writeString("\n");
  }

  // writes a Unicode line, throws WriteException on error
  void writeLineW(const(wchar)[] s) {
    writeStringW(s);
    version (Windows)
      writeStringW("\r\n");
    else version (Mac)
      writeStringW("\r");
    else
      writeStringW("\n");
  }

  // writes a string, throws WriteException on error
  void writeString(const(char)[] s) {
    writeExact(s.ptr, s.length);
  }

  // writes a Unicode string, throws WriteException on error
  void writeStringW(const(wchar)[] s) {
    writeExact(s.ptr, s.length * wchar.sizeof);
  }

  // writes data to stream using vprintf() syntax,
  // returns number of bytes written
  size_t vprintf(const(char)[] format, va_list args) {
    // shamelessly stolen from OutBuffer,
    // by Walter's permission
    char[1024] buffer;
    char* p = buffer.ptr;
    // Can't use `tempCString()` here as it will result in compilation error:
    // "cannot mix core.std.stdlib.alloca() and exception handling".
    auto f = toStringz(format);
    size_t psize = buffer.length;
    size_t count;
    while (true) {
      version (Windows) {
        count = vsnprintf(p, psize, f, args);
        if (count != -1)
          break;
        psize *= 2;
        p = cast(char*) alloca(psize);
      } else version (Posix) {
        count = vsnprintf(p, psize, f, args);
        if (count == -1)
          psize *= 2;
        else if (count >= psize)
          psize = count + 1;
        else
          break;
        p = cast(char*) alloca(psize);
      } else
          throw new Exception("unsupported platform");
    }
    writeString(p[0 .. count]);
    return count;
  }

  // writes data to stream using printf() syntax,
  // returns number of bytes written
  size_t printf(const(char)[] format, ...) {
    va_list ap;
    va_start(ap, format);
    auto result = vprintf(format, ap);
    va_end(ap);
    return result;
  }

  private void doFormatCallback(dchar c) {
    char[4] buf;
    auto b = std.utf.encode(buf, c);
    writeString(buf);
  }

  // writes data to stream using writef() syntax,
  OutputStream writef(...) {
    return writefx(_arguments,_argptr,0);
  }

  // writes data with trailing newline
  OutputStream writefln(...) {
    return writefx(_arguments,_argptr,1);
  }

  // writes data with optional trailing newline
  OutputStream writefx(TypeInfo[] arguments, va_list argptr, int newline=false) {
    doFormat(&doFormatCallback,arguments,argptr);
    if (newline)
      writeLine("");
    return this;
  }

  /***
   * Copies all data from s into this stream.
   * This may throw ReadException or WriteException on failure.
   * This restores the file position of s so that it is unchanged.
   */
  void copyFrom(Stream s) {
    if (seekable) {
      ulong pos = s.position;
      s.position = 0;
      copyFrom(s, s.size);
      s.position = pos;
    } else {
      ubyte[128] buf;
      while (!s.eof) {
        size_t m = s.readBlock(buf.ptr, buf.length);
        writeExact(buf.ptr, m);
      }
    }
  }

  /***
   * Copy a specified number of bytes from the given stream into this one.
   * This may throw ReadException or WriteException on failure.
   * Unlike the previous form, this doesn't restore the file position of s.
   */
  void copyFrom(Stream s, ulong count) {
    ubyte[128] buf;
    while (count > 0) {
      size_t n = cast(size_t)(count<buf.length ? count : buf.length);
      s.readExact(buf.ptr, n);
      writeExact(buf.ptr, n);
      count -= n;
    }
  }

  /***
   * Change the current position of the stream. whence is either SeekPos.Set, in
   which case the offset is an absolute index from the beginning of the stream,
   SeekPos.Current, in which case the offset is a delta from the current
   position, or SeekPos.End, in which case the offset is a delta from the end of
   the stream (negative or zero offsets only make sense in that case). This
   returns the new file position.
   */
  abstract ulong seek(long offset, SeekPos whence);

  /***
   * Aliases for their normal seek counterparts.
   */
  ulong seekSet(long offset) { return seek (offset, SeekPos.Set); }
  ulong seekCur(long offset) { return seek (offset, SeekPos.Current); } /// ditto
  ulong seekEnd(long offset) { return seek (offset, SeekPos.End); }     /// ditto

  /***
   * Sets file position. Equivalent to calling seek(pos, SeekPos.Set).
   */
  @property void position(ulong pos) { seek(cast(long)pos, SeekPos.Set); }

  /***
   * Returns current file position. Equivalent to seek(0, SeekPos.Current).
   */
  @property ulong position() { return seek(0, SeekPos.Current); }

  /***
   * Retrieve the size of the stream in bytes.
   * The stream must be seekable or a SeekException is thrown.
   */
  @property ulong size() {
    assertSeekable();
    ulong pos = position, result = seek(0, SeekPos.End);
    position = pos;
    return result;
  }

  // returns true if end of stream is reached, false otherwise
  @property bool eof() {
    // for unseekable streams we only know the end when we read it
    if (readEOF && !ungetAvailable())
      return true;
    else if (seekable)
      return position == size;
    else
      return false;
  }

  // returns true if the stream is open
  @property bool isOpen() { return isopen; }

  // flush the buffer if writeable
  void flush() {
    if (unget.length > 1)
      unget.length = 1; // keep at least 1 so that data ptr stays
  }

  // close the stream somehow; the default just flushes the buffer
  void close() {
    if (isopen)
      flush();
    readEOF = prevCr = isopen = readable = writeable = seekable = false;
  }

  /***
   * Read the entire stream and return it as a string.
   * If the stream is not seekable the contents from the current position to eof
   * is read and returned.
   */
  override string toString() {
    if (!readable)
      return super.toString();
    try
    {
        size_t pos;
        size_t rdlen;
        size_t blockSize;
        char[] result;
        if (seekable) {
          ulong orig_pos = position;
          scope(exit) position = orig_pos;
          position = 0;
          blockSize = cast(size_t)size;
          result = new char[blockSize];
          while (blockSize > 0) {
            rdlen = readBlock(&result[pos], blockSize);
            pos += rdlen;
            blockSize -= rdlen;
          }
        } else {
          blockSize = 4096;
          result = new char[blockSize];
          while ((rdlen = readBlock(&result[pos], blockSize)) > 0) {
            pos += rdlen;
            blockSize += rdlen;
            result.length = result.length + blockSize;
          }
        }
        return cast(string) result[0 .. pos];
    }
    catch (Throwable)
    {
        return super.toString();
    }
  }

  /***
   * Get a hash of the stream by reading each byte and using it in a CRC-32
   * checksum.
   */
  override size_t toHash() @trusted {
    if (!readable || !seekable)
      return super.toHash();
    try
    {
        ulong pos = position;
        scope(exit) position = pos;
        CRC32 crc;
        crc.start();
        position = 0;
        ulong len = size;
        for (ulong i = 0; i < len; i++)
        {
          ubyte c;
          read(c);
          crc.put(c);
        }

        union resUnion
        {
            size_t hash;
            ubyte[4] crcVal;
        }
        resUnion res;
        res.crcVal = crc.finish();
        return res.hash;
    }
    catch (Throwable)
    {
        return super.toHash();
    }
  }

  // helper for checking that the stream is readable
  final protected void assertReadable() {
    if (!readable)
      throw new ReadException("Stream is not readable");
  }
  // helper for checking that the stream is writeable
  final protected void assertWriteable() {
    if (!writeable)
      throw new WriteException("Stream is not writeable");
  }
  // helper for checking that the stream is seekable
  final protected void assertSeekable() {
    if (!seekable)
      throw new SeekException("Stream is not seekable");
  }

  unittest { // unit test for Issue 3363
    import std.stdio;
    immutable fileName = std.file.deleteme ~ "-issue3363.txt";
    auto w = std.stdio.File(fileName, "w");
    scope (exit) remove(fileName.ptr);
    w.write("one two three");
    w.close();
    auto r = std.stdio.File(fileName, "r");
    const(char)[] constChar;
    string str;
    char[] chars;
    r.readf("%s %s %s", &constChar, &str, &chars);
    assert (constChar == "one", constChar);
    assert (str == "two", str);
    assert (chars == "three", chars);
  }

  unittest { //unit tests for Issue 1668
    void tryFloatRoundtrip(float x, string fmt = "", string pad = "") {
      auto s = new MemoryStream();
      s.writef(fmt, x, pad);
      s.position = 0;

      float f;
      assert(s.readf(&f));
      assert(x == f || (x != x && f != f)); //either equal or both NaN
    }

    tryFloatRoundtrip(1.0);
    tryFloatRoundtrip(1.0, "%f");
    tryFloatRoundtrip(1.0, "", " ");
    tryFloatRoundtrip(1.0, "%f", " ");

    tryFloatRoundtrip(3.14);
    tryFloatRoundtrip(3.14, "%f");
    tryFloatRoundtrip(3.14, "", " ");
    tryFloatRoundtrip(3.14, "%f", " ");

    float nan = float.nan;
    tryFloatRoundtrip(nan);
    tryFloatRoundtrip(nan, "%f");
    tryFloatRoundtrip(nan, "", " ");
    tryFloatRoundtrip(nan, "%f", " ");

    float inf = 1.0/0.0;
    tryFloatRoundtrip(inf);
    tryFloatRoundtrip(inf, "%f");
    tryFloatRoundtrip(inf, "", " ");
    tryFloatRoundtrip(inf, "%f", " ");

    tryFloatRoundtrip(-inf);
    tryFloatRoundtrip(-inf,"%f");
    tryFloatRoundtrip(-inf, "", " ");
    tryFloatRoundtrip(-inf, "%f", " ");
  }
}

/***
 * A base class for streams that wrap a source stream with additional
 * functionality.
 *
 * The method implementations forward read/write/seek calls to the
 * source stream. A FilterStream can change the position of the source stream
 * arbitrarily and may not keep the source stream state in sync with the
 * FilterStream, even upon flushing and closing the FilterStream. It is
 * recommended to not make any assumptions about the state of the source position
 * and read/write state after a FilterStream has acted upon it. Specifc subclasses
 * of FilterStream should document how they modify the source stream and if any
 * invariants hold true between the source and filter.
 */
class FilterStream : Stream {
  private Stream s;              // source stream

  /// Property indicating when this stream closes to close the source stream as
  /// well.
  /// Defaults to true.
  bool nestClose = true;

  /// Construct a FilterStream for the given source.
  this(Stream source) {
    s = source;
    resetSource();
  }

  // source getter/setter

  /***
   * Get the current source stream.
   */
  final Stream source(){return s;}

  /***
   * Set the current source stream.
   *
   * Setting the source stream closes this stream before attaching the new
   * source. Attaching an open stream reopens this stream and resets the stream
   * state.
   */
  void source(Stream s) {
    close();
    this.s = s;
    resetSource();
  }

  /***
   * Indicates the source stream changed state and that this stream should reset
   * any readable, writeable, seekable, isopen and buffering flags.
   */
  void resetSource() {
    if (s !is null) {
      readable = s.readable;
      writeable = s.writeable;
      seekable = s.seekable;
      isopen = s.isOpen;
    } else {
      readable = writeable = seekable = false;
      isopen = false;
    }
    readEOF = prevCr = false;
  }

  // read from source
  override size_t readBlock(void* buffer, size_t size) {
    size_t res = s.readBlock(buffer,size);
    readEOF = res == 0;
    return res;
  }

  // write to source
  override size_t writeBlock(const void* buffer, size_t size) {
    return s.writeBlock(buffer,size);
  }

  // close stream
  override void close() {
    if (isopen) {
      super.close();
      if (nestClose)
        s.close();
    }
  }

  // seek on source
  override ulong seek(long offset, SeekPos whence) {
    readEOF = false;
    return s.seek(offset,whence);
  }

  override @property size_t available() { return s.available; }
  override void flush() { super.flush(); s.flush(); }
}

/***
 * This subclass is for buffering a source stream.
 *
 * A buffered stream must be
 * closed explicitly to ensure the final buffer content is written to the source
 * stream. The source stream position is changed according to the block size so
 * reading or writing to the BufferedStream may not change the source stream
 * position by the same amount.
 */
class BufferedStream : FilterStream {
  ubyte[] buffer;       // buffer, if any
  size_t bufferCurPos;    // current position in buffer
  size_t bufferLen;       // amount of data in buffer
  bool bufferDirty = false;
  size_t bufferSourcePos; // position in buffer of source stream position
  ulong streamPos;      // absolute position in source stream

  /* Example of relationship between fields:
   *
   *  s             ...01234567890123456789012EOF
   *  buffer                |--                     --|
   *  bufferCurPos                       |
   *  bufferLen             |--            --|
   *  bufferSourcePos                        |
   *
   */

  invariant() {
    assert(bufferSourcePos <= bufferLen);
    assert(bufferCurPos <= bufferLen);
    assert(bufferLen <= buffer.length);
  }

  enum size_t DefaultBufferSize = 8192;

  /***
   * Create a buffered stream for the stream source with the buffer size
   * bufferSize.
   */
  this(Stream source, size_t bufferSize = DefaultBufferSize) {
    super(source);
    if (bufferSize)
      buffer = new ubyte[bufferSize];
  }

  override protected void resetSource() {
    super.resetSource();
    streamPos = 0;
    bufferLen = bufferSourcePos = bufferCurPos = 0;
    bufferDirty = false;
  }

  // reads block of data of specified size using any buffered data
  // returns actual number of bytes read
  override size_t readBlock(void* result, size_t len) {
    if (len == 0) return 0;

    assertReadable();

    ubyte* outbuf = cast(ubyte*)result;
    size_t readsize = 0;

    if (bufferCurPos + len < bufferLen) {
      // buffer has all the data so copy it
      outbuf[0 .. len] = buffer[bufferCurPos .. bufferCurPos+len];
      bufferCurPos += len;
      readsize = len;
      goto ExitRead;
    }

    readsize = bufferLen - bufferCurPos;
    if (readsize > 0) {
      // buffer has some data so copy what is left
      outbuf[0 .. readsize] = buffer[bufferCurPos .. bufferLen];
      outbuf += readsize;
      bufferCurPos += readsize;
      len -= readsize;
    }

    flush();

    if (len >= buffer.length) {
      // buffer can't hold the data so fill output buffer directly
      size_t siz = super.readBlock(outbuf, len);
      readsize += siz;
      streamPos += siz;
    } else {
      // read a new block into buffer
        bufferLen = super.readBlock(buffer.ptr, buffer.length);
        if (bufferLen < len) len = bufferLen;
        outbuf[0 .. len] = buffer[0 .. len];
        bufferSourcePos = bufferLen;
        streamPos += bufferLen;
        bufferCurPos = len;
        readsize += len;
    }

  ExitRead:
    return readsize;
  }

  // write block of data of specified size
  // returns actual number of bytes written
  override size_t writeBlock(const void* result, size_t len) {
    assertWriteable();

    ubyte* buf = cast(ubyte*)result;
    size_t writesize = 0;

    if (bufferLen == 0) {
      // buffer is empty so fill it if possible
      if ((len < buffer.length) && (readable)) {
        // read in data if the buffer is currently empty
        bufferLen = s.readBlock(buffer.ptr, buffer.length);
        bufferSourcePos = bufferLen;
        streamPos += bufferLen;

      } else if (len >= buffer.length) {
        // buffer can't hold the data so write it directly and exit
        writesize = s.writeBlock(buf,len);
        streamPos += writesize;
        goto ExitWrite;
      }
    }

    if (bufferCurPos + len <= buffer.length) {
      // buffer has space for all the data so copy it and exit
      buffer[bufferCurPos .. bufferCurPos+len] = buf[0 .. len];
      bufferCurPos += len;
      bufferLen = bufferCurPos > bufferLen ? bufferCurPos : bufferLen;
      writesize = len;
      bufferDirty = true;
      goto ExitWrite;
    }

    writesize = buffer.length - bufferCurPos;
    if (writesize > 0) {
      // buffer can take some data
      buffer[bufferCurPos .. buffer.length] = buf[0 .. writesize];
      bufferCurPos = bufferLen = buffer.length;
      buf += writesize;
      len -= writesize;
      bufferDirty = true;
    }

    assert(bufferCurPos == buffer.length);
    assert(bufferLen == buffer.length);

    flush();

    writesize += writeBlock(buf,len);

  ExitWrite:
    return writesize;
  }

  override ulong seek(long offset, SeekPos whence) {
    assertSeekable();

    if ((whence != SeekPos.Current) ||
        (offset + bufferCurPos < 0) ||
        (offset + bufferCurPos >= bufferLen)) {
      flush();
      streamPos = s.seek(offset,whence);
    } else {
      bufferCurPos += offset;
    }
    readEOF = false;
    return streamPos-bufferSourcePos+bufferCurPos;
  }

  // Buffered readLine - Dave Fladebo
  // reads a line, terminated by either CR, LF, CR/LF, or EOF
  // reusing the memory in buffer if result will fit, otherwise
  // will reallocate (using concatenation)
  template TreadLine(T) {
      T[] readLine(T[] inBuffer)
      {
          size_t    lineSize = 0;
          bool    haveCR = false;
          T       c = '\0';
          size_t    idx = 0;
          ubyte*  pc = cast(ubyte*)&c;

        L0:
          for(;;) {
              size_t start = bufferCurPos;
            L1:
              foreach(ubyte b; buffer[start .. bufferLen]) {
                  bufferCurPos++;
                  pc[idx] = b;
                  if(idx < T.sizeof - 1) {
                      idx++;
                      continue L1;
                  } else {
                      idx = 0;
                  }
                  if(c == '\n' || haveCR) {
                      if(haveCR && c != '\n') bufferCurPos--;
                      break L0;
                  } else {
                      if(c == '\r') {
                          haveCR = true;
                      } else {
                          if(lineSize < inBuffer.length) {
                              inBuffer[lineSize] = c;
                          } else {
                              inBuffer ~= c;
                          }
                          lineSize++;
                      }
                  }
              }
              flush();
              size_t res = super.readBlock(buffer.ptr, buffer.length);
              if(!res) break L0; // EOF
              bufferSourcePos = bufferLen = res;
              streamPos += res;
          }
          return inBuffer[0 .. lineSize];
      }
  } // template TreadLine(T)

  override char[] readLine(char[] inBuffer) {
    if (ungetAvailable())
      return super.readLine(inBuffer);
    else
      return TreadLine!(char).readLine(inBuffer);
  }
  alias readLine = Stream.readLine;

  override wchar[] readLineW(wchar[] inBuffer) {
    if (ungetAvailable())
      return super.readLineW(inBuffer);
    else
      return TreadLine!(wchar).readLine(inBuffer);
  }
  alias readLineW = Stream.readLineW;

  override void flush()
  out {
    assert(bufferCurPos == 0);
    assert(bufferSourcePos == 0);
    assert(bufferLen == 0);
  }
  body {
    if (writeable && bufferDirty) {
      if (bufferSourcePos != 0 && seekable) {
        // move actual file pointer to front of buffer
        streamPos = s.seek(-bufferSourcePos, SeekPos.Current);
      }
      // write buffer out
      bufferSourcePos = s.writeBlock(buffer.ptr, bufferLen);
      if (bufferSourcePos != bufferLen) {
        throw new WriteException("Unable to write to stream");
      }
    }
    super.flush();
    long diff = cast(long)bufferCurPos-bufferSourcePos;
    if (diff != 0 && seekable) {
      // move actual file pointer to current position
      streamPos = s.seek(diff, SeekPos.Current);
    }
    // reset buffer data to be empty
    bufferSourcePos = bufferCurPos = bufferLen = 0;
    bufferDirty = false;
  }

  // returns true if end of stream is reached, false otherwise
  override @property bool eof() {
    if ((buffer.length == 0) || !readable) {
      return super.eof;
    }
    // some simple tests to avoid flushing
    if (ungetAvailable() || bufferCurPos != bufferLen)
      return false;
    if (bufferLen == buffer.length)
      flush();
    size_t res = super.readBlock(&buffer[bufferLen],buffer.length-bufferLen);
    bufferSourcePos +=  res;
    bufferLen += res;
    streamPos += res;
    return readEOF;
  }

  // returns size of stream
  override @property ulong size() {
    if (bufferDirty) flush();
    return s.size;
  }

  // returns estimated number of bytes available for immediate reading
  override @property size_t available() {
    return bufferLen - bufferCurPos;
  }
}

/// An exception for File errors.
class StreamFileException: StreamException {
  /// Construct a StreamFileException with given error message.
  this(string msg) { super(msg); }
}

/// An exception for errors during File.open.
class OpenException: StreamFileException {
  /// Construct an OpenFileException with given error message.
  this(string msg) { super(msg); }
}

/// Specifies the $(LREF File) access mode used when opening the file.
enum FileMode {
  In = 1,     /// Opens the file for reading.
  Out = 2,    /// Opens the file for writing.
  OutNew = 6, /// Opens the file for writing, creates a new file if it doesn't exist.
  Append = 10 /// Opens the file for writing, appending new data to the end of the file.
}

version (Windows) {
  private import core.sys.windows.windows;
  extern (Windows) {
    void FlushFileBuffers(HANDLE hFile);
    DWORD  GetFileType(HANDLE hFile);
  }
}
version (Posix) {
  private import core.sys.posix.fcntl;
  private import core.sys.posix.unistd;
  alias HANDLE = int;
}

/// This subclass is for unbuffered file system streams.
class File: Stream {

  version (Windows) {
    private HANDLE hFile;
  }
  version (Posix) {
    private HANDLE hFile = -1;
  }

  this() {
    super();
    version (Windows) {
      hFile = null;
    }
    version (Posix) {
      hFile = -1;
    }
    isopen = false;
  }

  // opens existing handle; use with care!
  this(HANDLE hFile, FileMode mode) {
    super();
    this.hFile = hFile;
    readable = cast(bool)(mode & FileMode.In);
    writeable = cast(bool)(mode & FileMode.Out);
    version(Windows) {
      seekable = GetFileType(hFile) == 1; // FILE_TYPE_DISK
    } else {
      auto result = lseek(hFile, 0, 0);
      seekable = (result != ~0);
    }
  }

  /***
   * Create the stream with no open file, an open file in read mode, or an open
   * file with explicit file mode.
   * mode, if given, is a combination of FileMode.In
   * (indicating a file that can be read) and FileMode.Out (indicating a file
   * that can be written).
   * Opening a file for reading that doesn't exist will error.
   * Opening a file for writing that doesn't exist will create the file.
   * The FileMode.OutNew mode will open the file for writing and reset the
   * length to zero.
   * The FileMode.Append mode will open the file for writing and move the
   * file position to the end of the file.
   */
  this(string filename, FileMode mode = FileMode.In)
  {
      this();
      open(filename, mode);
  }


  /***
   * Open a file for the stream, in an identical manner to the constructors.
   * If an error occurs an OpenException is thrown.
   */
  void open(string filename, FileMode mode = FileMode.In) {
    close();
    int access, share, createMode;
    parseMode(mode, access, share, createMode);
    seekable = true;
    readable = cast(bool)(mode & FileMode.In);
    writeable = cast(bool)(mode & FileMode.Out);
    version (Windows) {
      hFile = CreateFileW(filename.tempCStringW(), access, share,
                          null, createMode, 0, null);
      isopen = hFile != INVALID_HANDLE_VALUE;
    }
    version (Posix) {
      hFile = core.sys.posix.fcntl.open(filename.tempCString(), access | createMode, share);
      isopen = hFile != -1;
    }
    if (!isopen)
      throw new OpenException(cast(string) ("Cannot open or create file '"
                                            ~ filename ~ "'"));
    else if ((mode & FileMode.Append) == FileMode.Append)
      seekEnd(0);
  }

  private void parseMode(int mode,
                         out int access,
                         out int share,
                         out int createMode) {
    version (Windows) {
      share |= FILE_SHARE_READ | FILE_SHARE_WRITE;
      if (mode & FileMode.In) {
        access |= GENERIC_READ;
        createMode = OPEN_EXISTING;
      }
      if (mode & FileMode.Out) {
        access |= GENERIC_WRITE;
        createMode = OPEN_ALWAYS; // will create if not present
      }
      if ((mode & FileMode.OutNew) == FileMode.OutNew) {
        createMode = CREATE_ALWAYS; // resets file
      }
    }
    version (Posix) {
      share = octal!666;
      if (mode & FileMode.In) {
        access = O_RDONLY;
      }
      if (mode & FileMode.Out) {
        createMode = O_CREAT; // will create if not present
        access = O_WRONLY;
      }
      if (access == (O_WRONLY | O_RDONLY)) {
        access = O_RDWR;
      }
      if ((mode & FileMode.OutNew) == FileMode.OutNew) {
        access |= O_TRUNC; // resets file
      }
    }
  }

  /// Create a file for writing.
  void create(string filename) {
    create(filename, FileMode.OutNew);
  }

  /// ditto
  void create(string filename, FileMode mode) {
    close();
    open(filename, mode | FileMode.OutNew);
  }

  /// Close the current file if it is open; otherwise it does nothing.
  override void close() {
    if (isopen) {
      super.close();
      if (hFile) {
        version (Windows) {
          CloseHandle(hFile);
          hFile = null;
        } else version (Posix) {
          core.sys.posix.unistd.close(hFile);
          hFile = -1;
        }
      }
    }
  }

  // destructor, closes file if still opened
  ~this() { close(); }

  version (Windows) {
    // returns size of stream
    override @property ulong size() {
      assertSeekable();
      uint sizehi;
      uint sizelow = GetFileSize(hFile,&sizehi);
      return (cast(ulong)sizehi << 32) + sizelow;
    }
  }

  override size_t readBlock(void* buffer, size_t size) {
    assertReadable();
    version (Windows) {
      auto dwSize = to!DWORD(size);
      ReadFile(hFile, buffer, dwSize, &dwSize, null);
      size = dwSize;
    } else version (Posix) {
      size = core.sys.posix.unistd.read(hFile, buffer, size);
      if (size == -1)
        size = 0;
    }
    readEOF = (size == 0);
    return size;
  }

  override size_t writeBlock(const void* buffer, size_t size) {
    assertWriteable();
    version (Windows) {
      auto dwSize = to!DWORD(size);
      WriteFile(hFile, buffer, dwSize, &dwSize, null);
      size = dwSize;
    } else version (Posix) {
      size = core.sys.posix.unistd.write(hFile, buffer, size);
      if (size == -1)
        size = 0;
    }
    return size;
  }

  override ulong seek(long offset, SeekPos rel) {
    assertSeekable();
    version (Windows) {
      int hi = cast(int)(offset>>32);
      uint low = SetFilePointer(hFile, cast(int)offset, &hi, rel);
      if ((low == INVALID_SET_FILE_POINTER) && (GetLastError() != 0))
        throw new SeekException("unable to move file pointer");
      ulong result = (cast(ulong)hi << 32) + low;
    } else version (Posix) {
      auto result = lseek(hFile, cast(off_t)offset, rel);
      if (result == cast(typeof(result))-1)
        throw new SeekException("unable to move file pointer");
    }
    readEOF = false;
    return cast(ulong)result;
  }

  /***
   * For a seekable file returns the difference of the size and position and
   * otherwise returns 0.
   */

  override @property size_t available() {
    if (seekable) {
      ulong lavail = size - position;
      if (lavail > size_t.max) lavail = size_t.max;
      return cast(size_t)lavail;
    }
    return 0;
  }

  // OS-specific property, just in case somebody wants
  // to mess with underlying API
  HANDLE handle() { return hFile; }

  // run a few tests
  unittest {
    import std.internal.cstring : tempCString;
    import core.stdc.stdio : remove;

    File file = new File;
    int i = 666;
    auto stream_file = std.file.deleteme ~ "-stream.$$$";
    file.create(stream_file);
    // should be ok to write
    assert(file.writeable);
    file.writeLine("Testing stream.d:");
    file.writeString("Hello, world!");
    file.write(i);
    // string#1 + string#2 + int should give exacly that
    version (Windows)
      assert(file.position == 19 + 13 + 4);
    version (Posix)
      assert(file.position == 18 + 13 + 4);
    // we must be at the end of file
    assert(file.eof);
    file.close();
    // no operations are allowed when file is closed
    assert(!file.readable && !file.writeable && !file.seekable);
    file.open(stream_file);
    // should be ok to read
    assert(file.readable);
    assert(file.available == file.size);
    char[] line = file.readLine();
    char[] exp = "Testing stream.d:".dup;
    assert(line[0] == 'T');
    assert(line.length == exp.length);
    assert(!std.algorithm.cmp(line, "Testing stream.d:"));
    // jump over "Hello, "
    file.seek(7, SeekPos.Current);
    version (Windows)
      assert(file.position == 19 + 7);
    version (Posix)
      assert(file.position == 18 + 7);
    assert(!std.algorithm.cmp(file.readString(6), "world!"));
    i = 0; file.read(i);
    assert(i == 666);
    // string#1 + string#2 + int should give exacly that
    version (Windows)
      assert(file.position == 19 + 13 + 4);
    version (Posix)
      assert(file.position == 18 + 13 + 4);
    // we must be at the end of file
    assert(file.eof);
    file.close();
    file.open(stream_file,FileMode.OutNew | FileMode.In);
    file.writeLine("Testing stream.d:");
    file.writeLine("Another line");
    file.writeLine("");
    file.writeLine("That was blank");
    file.position = 0;
    char[][] lines;
    foreach(char[] line; file) {
      lines ~= line.dup;
    }
    assert( lines.length == 4 );
    assert( lines[0] == "Testing stream.d:");
    assert( lines[1] == "Another line");
    assert( lines[2] == "");
    assert( lines[3] == "That was blank");
    file.position = 0;
    lines = new char[][4];
    foreach(ulong n, char[] line; file) {
      lines[cast(size_t)(n-1)] = line.dup;
    }
    assert( lines[0] == "Testing stream.d:");
    assert( lines[1] == "Another line");
    assert( lines[2] == "");
    assert( lines[3] == "That was blank");
    file.close();
    remove(stream_file.tempCString());
  }
}

/***
 * This subclass is for buffered file system streams.
 *
 * It is a convenience class for wrapping a File in a BufferedStream.
 * A buffered stream must be closed explicitly to ensure the final buffer
 * content is written to the file.
 */
class BufferedFile: BufferedStream {

  /// opens file for reading
  this() { super(new File()); }

  /// opens file in requested mode and buffer size
  this(string filename, FileMode mode = FileMode.In,
       size_t bufferSize = DefaultBufferSize) {
    super(new File(filename,mode),bufferSize);
  }

  /// opens file for reading with requested buffer size
  this(File file, size_t bufferSize = DefaultBufferSize) {
    super(file,bufferSize);
  }

  /// opens existing handle; use with care!
  this(HANDLE hFile, FileMode mode, size_t buffersize = DefaultBufferSize) {
    super(new File(hFile,mode),buffersize);
  }

  /// opens file in requested mode
  void open(string filename, FileMode mode = FileMode.In) {
    File sf = cast(File)s;
    sf.open(filename,mode);
    resetSource();
  }

  /// creates file in requested mode
  void create(string filename, FileMode mode = FileMode.OutNew) {
    File sf = cast(File)s;
    sf.create(filename,mode);
    resetSource();
  }

  // run a few tests same as File
  unittest {
    import std.internal.cstring : tempCString;
    import core.stdc.stdio : remove;

    BufferedFile file = new BufferedFile;
    int i = 666;
    auto stream_file = std.file.deleteme ~ "-stream.$$$";
    file.create(stream_file);
    // should be ok to write
    assert(file.writeable);
    file.writeLine("Testing stream.d:");
    file.writeString("Hello, world!");
    file.write(i);
    // string#1 + string#2 + int should give exacly that
    version (Windows)
      assert(file.position == 19 + 13 + 4);
    version (Posix)
      assert(file.position == 18 + 13 + 4);
    // we must be at the end of file
    assert(file.eof);
    long oldsize = cast(long)file.size;
    file.close();
    // no operations are allowed when file is closed
    assert(!file.readable && !file.writeable && !file.seekable);
    file.open(stream_file);
    // should be ok to read
    assert(file.readable);
    // test getc/ungetc and size
    char c1 = file.getc();
    file.ungetc(c1);
    assert( file.size == oldsize );
    assert(!std.algorithm.cmp(file.readLine(), "Testing stream.d:"));
    // jump over "Hello, "
    file.seek(7, SeekPos.Current);
    version (Windows)
      assert(file.position == 19 + 7);
    version (Posix)
      assert(file.position == 18 + 7);
    assert(!std.algorithm.cmp(file.readString(6), "world!"));
    i = 0; file.read(i);
    assert(i == 666);
    // string#1 + string#2 + int should give exacly that
    version (Windows)
      assert(file.position == 19 + 13 + 4);
    version (Posix)
      assert(file.position == 18 + 13 + 4);
    // we must be at the end of file
    assert(file.eof);
    file.close();
    remove(stream_file.tempCString());
  }

}

/// UTF byte-order-mark signatures
enum BOM {
        UTF8,           /// UTF-8
        UTF16LE,        /// UTF-16 Little Endian
        UTF16BE,        /// UTF-16 Big Endian
        UTF32LE,        /// UTF-32 Little Endian
        UTF32BE,        /// UTF-32 Big Endian
}

private enum int NBOMS = 5;
immutable Endian[NBOMS] BOMEndian =
[ std.system.endian,
  Endian.littleEndian, Endian.bigEndian,
  Endian.littleEndian, Endian.bigEndian
  ];

immutable ubyte[][NBOMS] ByteOrderMarks =
[ [0xEF, 0xBB, 0xBF],
  [0xFF, 0xFE],
  [0xFE, 0xFF],
  [0xFF, 0xFE, 0x00, 0x00],
  [0x00, 0x00, 0xFE, 0xFF]
  ];


/***
 * This subclass wraps a stream with big-endian or little-endian byte order
 * swapping.
 *
 * UTF Byte-Order-Mark (BOM) signatures can be read and deduced or
 * written.
 * Note that an EndianStream should not be used as the source of another
 * FilterStream since a FilterStream call the source with byte-oriented
 * read/write requests and the EndianStream will not perform any byte swapping.
 * The EndianStream reads and writes binary data (non-getc functions) in a
 * one-to-one
 * manner with the source stream so the source stream's position and state will be
 * kept in sync with the EndianStream if only non-getc functions are called.
 */
class EndianStream : FilterStream {

  Endian endian;        /// Endianness property of the source stream.

  /***
   * Create the endian stream for the source stream source with endianness end.
   * The default endianness is the native byte order.
   * The Endian type is defined
   * in the std.system module.
   */
  this(Stream source, Endian end = std.system.endian) {
    super(source);
    endian = end;
  }

  /***
   * Return -1 if no BOM and otherwise read the BOM and return it.
   *
   * If there is no BOM or if bytes beyond the BOM are read then the bytes read
   * are pushed back onto the ungetc buffer or ungetcw buffer.
   * Pass ungetCharSize == 2 to use
   * ungetcw instead of ungetc when no BOM is present.
   */
  int readBOM(int ungetCharSize = 1) {
    ubyte[4] BOM_buffer;
    int n = 0;       // the number of read bytes
    int result = -1; // the last match or -1
    for (int i=0; i < NBOMS; ++i) {
      int j;
      immutable ubyte[] bom = ByteOrderMarks[i];
      for (j=0; j < bom.length; ++j) {
        if (n <= j) { // have to read more
          if (eof)
            break;
          readExact(&BOM_buffer[n++],1);
        }
        if (BOM_buffer[j] != bom[j])
          break;
      }
      if (j == bom.length) // found a match
        result = i;
    }
    ptrdiff_t m = 0;
    if (result != -1) {
      endian = BOMEndian[result]; // set stream endianness
      m = ByteOrderMarks[result].length;
    }
    if ((ungetCharSize == 1 && result == -1) || (result == BOM.UTF8)) {
      while (n-- > m)
        ungetc(BOM_buffer[n]);
    } else { // should eventually support unget for dchar as well
      if (n & 1) // make sure we have an even number of bytes
        readExact(&BOM_buffer[n++],1);
      while (n > m) {
        n -= 2;
        wchar cw = *(cast(wchar*)&BOM_buffer[n]);
        fixBO(&cw,2);
        ungetcw(cw);
      }
    }
    return result;
  }

  /***
   * Correct the byte order of buffer to match native endianness.
   * size must be even.
   */
  final void fixBO(const(void)* buffer, size_t size) {
    if (endian != std.system.endian) {
      ubyte* startb = cast(ubyte*)buffer;
      uint* start = cast(uint*)buffer;
      switch (size) {
      case 0: break;
      case 2: {
        ubyte x = *startb;
        *startb = *(startb+1);
        *(startb+1) = x;
        break;
      }
      case 4: {
        *start = bswap(*start);
        break;
      }
      default: {
        uint* end = cast(uint*)(buffer + size - uint.sizeof);
        while (start < end) {
          uint x = bswap(*start);
          *start = bswap(*end);
          *end = x;
          ++start;
          --end;
        }
        startb = cast(ubyte*)start;
        ubyte* endb = cast(ubyte*)end;
        auto len = uint.sizeof - (startb - endb);
        if (len > 0)
          fixBO(startb,len);
      }
      }
    }
  }

  /***
   * Correct the byte order of the given buffer in blocks of the given size and
   * repeated the given number of times.
   * size must be even.
   */
  final void fixBlockBO(void* buffer, uint size, size_t repeat) {
    while (repeat--) {
      fixBO(buffer,size);
      buffer += size;
    }
  }

  override void read(out byte x) { readExact(&x, x.sizeof); }
  override void read(out ubyte x) { readExact(&x, x.sizeof); }
  override void read(out short x) { readExact(&x, x.sizeof); fixBO(&x,x.sizeof); }
  override void read(out ushort x) { readExact(&x, x.sizeof); fixBO(&x,x.sizeof); }
  override void read(out int x) { readExact(&x, x.sizeof); fixBO(&x,x.sizeof); }
  override void read(out uint x) { readExact(&x, x.sizeof); fixBO(&x,x.sizeof); }
  override void read(out long x) { readExact(&x, x.sizeof); fixBO(&x,x.sizeof); }
  override void read(out ulong x) { readExact(&x, x.sizeof); fixBO(&x,x.sizeof); }
  override void read(out float x) { readExact(&x, x.sizeof); fixBO(&x,x.sizeof); }
  override void read(out double x) { readExact(&x, x.sizeof); fixBO(&x,x.sizeof); }
  override void read(out real x) { readExact(&x, x.sizeof); fixBO(&x,x.sizeof); }
  override void read(out ifloat x) { readExact(&x, x.sizeof); fixBO(&x,x.sizeof); }
  override void read(out idouble x) { readExact(&x, x.sizeof); fixBO(&x,x.sizeof); }
  override void read(out ireal x) { readExact(&x, x.sizeof); fixBO(&x,x.sizeof); }
  override void read(out cfloat x) { readExact(&x, x.sizeof); fixBlockBO(&x,float.sizeof,2); }
  override void read(out cdouble x) { readExact(&x, x.sizeof); fixBlockBO(&x,double.sizeof,2); }
  override void read(out creal x) { readExact(&x, x.sizeof); fixBlockBO(&x,real.sizeof,2); }
  override void read(out char x) { readExact(&x, x.sizeof); }
  override void read(out wchar x) { readExact(&x, x.sizeof); fixBO(&x,x.sizeof); }
  override void read(out dchar x) { readExact(&x, x.sizeof); fixBO(&x,x.sizeof); }

  override wchar getcw() {
    wchar c;
    if (prevCr) {
      prevCr = false;
      c = getcw();
      if (c != '\n')
        return c;
    }
    if (unget.length > 1) {
      c = unget[unget.length - 1];
      unget.length = unget.length - 1;
    } else {
      void* buf = &c;
      size_t n = readBlock(buf,2);
      if (n == 1 && readBlock(buf+1,1) == 0)
          throw new ReadException("not enough data in stream");
      fixBO(&c,c.sizeof);
    }
    return c;
  }

  override wchar[] readStringW(size_t length) {
    wchar[] result = new wchar[length];
    readExact(result.ptr, length * wchar.sizeof);
    fixBlockBO(result.ptr, wchar.sizeof, length);
    return result;
  }

  /// Write the specified BOM b to the source stream.
  void writeBOM(BOM b) {
    immutable ubyte[] bom = ByteOrderMarks[b];
    writeBlock(bom.ptr, bom.length);
  }

  override void write(byte x) { writeExact(&x, x.sizeof); }
  override void write(ubyte x) { writeExact(&x, x.sizeof); }
  override void write(short x) { fixBO(&x,x.sizeof); writeExact(&x, x.sizeof); }
  override void write(ushort x) { fixBO(&x,x.sizeof); writeExact(&x, x.sizeof); }
  override void write(int x) { fixBO(&x,x.sizeof); writeExact(&x, x.sizeof); }
  override void write(uint x) { fixBO(&x,x.sizeof); writeExact(&x, x.sizeof); }
  override void write(long x) { fixBO(&x,x.sizeof); writeExact(&x, x.sizeof); }
  override void write(ulong x) { fixBO(&x,x.sizeof); writeExact(&x, x.sizeof); }
  override void write(float x) { fixBO(&x,x.sizeof); writeExact(&x, x.sizeof); }
  override void write(double x) { fixBO(&x,x.sizeof); writeExact(&x, x.sizeof); }
  override void write(real x) { fixBO(&x,x.sizeof); writeExact(&x, x.sizeof); }
  override void write(ifloat x) { fixBO(&x,x.sizeof); writeExact(&x, x.sizeof); }
  override void write(idouble x) { fixBO(&x,x.sizeof); writeExact(&x, x.sizeof); }
  override void write(ireal x) { fixBO(&x,x.sizeof); writeExact(&x, x.sizeof); }
  override void write(cfloat x) { fixBlockBO(&x,float.sizeof,2); writeExact(&x, x.sizeof); }
  override void write(cdouble x) { fixBlockBO(&x,double.sizeof,2); writeExact(&x, x.sizeof); }
  override void write(creal x) { fixBlockBO(&x,real.sizeof,2); writeExact(&x, x.sizeof);  }
  override void write(char x) { writeExact(&x, x.sizeof); }
  override void write(wchar x) { fixBO(&x,x.sizeof); writeExact(&x, x.sizeof); }
  override void write(dchar x) { fixBO(&x,x.sizeof); writeExact(&x, x.sizeof); }

  override void writeStringW(const(wchar)[] str) {
    foreach(wchar cw;str) {
      fixBO(&cw,2);
      s.writeExact(&cw, 2);
    }
  }

  override @property bool eof() { return s.eof && !ungetAvailable();  }
  override @property ulong size() { return s.size;  }

  unittest {
    MemoryStream m;
    m = new MemoryStream ();
    EndianStream em = new EndianStream(m,Endian.bigEndian);
    uint x = 0x11223344;
    em.write(x);
    assert( m.data[0] == 0x11 );
    assert( m.data[1] == 0x22 );
    assert( m.data[2] == 0x33 );
    assert( m.data[3] == 0x44 );
    em.position = 0;
    ushort x2 = 0x5566;
    em.write(x2);
    assert( m.data[0] == 0x55 );
    assert( m.data[1] == 0x66 );
    em.position = 0;
    static ubyte[12] x3 = [1,2,3,4,5,6,7,8,9,10,11,12];
    em.fixBO(x3.ptr,12);
    if (std.system.endian == Endian.littleEndian) {
      assert( x3[0] == 12 );
      assert( x3[1] == 11 );
      assert( x3[2] == 10 );
      assert( x3[4] == 8 );
      assert( x3[5] == 7 );
      assert( x3[6] == 6 );
      assert( x3[8] == 4 );
      assert( x3[9] == 3 );
      assert( x3[10] == 2 );
      assert( x3[11] == 1 );
    }
    em.endian = Endian.littleEndian;
    em.write(x);
    assert( m.data[0] == 0x44 );
    assert( m.data[1] == 0x33 );
    assert( m.data[2] == 0x22 );
    assert( m.data[3] == 0x11 );
    em.position = 0;
    em.write(x2);
    assert( m.data[0] == 0x66 );
    assert( m.data[1] == 0x55 );
    em.position = 0;
    em.fixBO(x3.ptr,12);
    if (std.system.endian == Endian.bigEndian) {
      assert( x3[0] == 12 );
      assert( x3[1] == 11 );
      assert( x3[2] == 10 );
      assert( x3[4] == 8 );
      assert( x3[5] == 7 );
      assert( x3[6] == 6 );
      assert( x3[8] == 4 );
      assert( x3[9] == 3 );
      assert( x3[10] == 2 );
      assert( x3[11] == 1 );
    }
    em.writeBOM(BOM.UTF8);
    assert( m.position == 3 );
    assert( m.data[0] == 0xEF );
    assert( m.data[1] == 0xBB );
    assert( m.data[2] == 0xBF );
    em.writeString ("Hello, world");
    em.position = 0;
    assert( m.position == 0 );
    assert( em.readBOM() == BOM.UTF8 );
    assert( m.position == 3 );
    assert( em.getc() == 'H' );
    em.position = 0;
    em.writeBOM(BOM.UTF16BE);
    assert( m.data[0] == 0xFE );
    assert( m.data[1] == 0xFF );
    em.position = 0;
    em.writeBOM(BOM.UTF16LE);
    assert( m.data[0] == 0xFF );
    assert( m.data[1] == 0xFE );
    em.position = 0;
    em.writeString ("Hello, world");
    em.position = 0;
    assert( em.readBOM() == -1 );
    assert( em.getc() == 'H' );
    assert( em.getc() == 'e' );
    assert( em.getc() == 'l' );
    assert( em.getc() == 'l' );
    em.position = 0;
  }
}

/***
 * Parameterized subclass that wraps an array-like buffer with a stream
 * interface.
 *
 * The type Buffer must support the length property, opIndex and opSlice.
 * Compile in release mode when directly instantiating a TArrayStream to avoid
 * link errors.
 */
class TArrayStream(Buffer): Stream {
  Buffer buf; // current data
  ulong len;  // current data length
  ulong cur;  // current file position

  /// Create the stream for the the buffer buf. Non-copying.
  this(Buffer buf) {
    super ();
    this.buf = buf;
    this.len = buf.length;
    readable = writeable = seekable = true;
  }

  // ensure subclasses don't violate this
  invariant() {
    assert(len <= buf.length);
    assert(cur <= len);
  }

  override size_t readBlock(void* buffer, size_t size) {
    assertReadable();
    ubyte* cbuf = cast(ubyte*) buffer;
    if (len - cur < size)
      size = cast(size_t)(len - cur);
    ubyte[] ubuf = cast(ubyte[])buf[cast(size_t)cur .. cast(size_t)(cur + size)];
    cbuf[0 .. size] = ubuf[];
    cur += size;
    return size;
  }

  override size_t writeBlock(const void* buffer, size_t size) {
    assertWriteable();
    ubyte* cbuf = cast(ubyte*) buffer;
    ulong blen = buf.length;
    if (cur + size > blen)
      size = cast(size_t)(blen - cur);
    ubyte[] ubuf = cast(ubyte[])buf[cast(size_t)cur .. cast(size_t)(cur + size)];
    ubuf[] = cbuf[0 .. size];
    cur += size;
    if (cur > len)
      len = cur;
    return size;
  }

  override ulong seek(long offset, SeekPos rel) {
    assertSeekable();
    long scur; // signed to saturate to 0 properly

    switch (rel) {
    case SeekPos.Set: scur = offset; break;
    case SeekPos.Current: scur = cast(long)(cur + offset); break;
    case SeekPos.End: scur = cast(long)(len + offset); break;
    default:
        assert(0);
    }

    if (scur < 0)
      cur = 0;
    else if (scur > len)
      cur = len;
    else
      cur = cast(ulong)scur;

    return cur;
  }

  override @property size_t available () { return cast(size_t)(len - cur); }

  /// Get the current memory data in total.
  @property ubyte[] data() {
    if (len > size_t.max)
      throw new StreamException("Stream too big");
    const(void)[] res = buf[0 .. cast(size_t)len];
    return cast(ubyte[])res;
  }

  override string toString() {
      // assume data is UTF8
      return to!(string)(cast(char[])data);
  }
}

/* Test the TArrayStream */
unittest {
  char[100] buf;
  TArrayStream!(char[]) m;

  m = new TArrayStream!(char[]) (buf);
  assert (m.isOpen);
  m.writeString ("Hello, world");
  assert (m.position == 12);
  assert (m.available == 88);
  assert (m.seekSet (0) == 0);
  assert (m.available == 100);
  assert (m.seekCur (4) == 4);
  assert (m.available == 96);
  assert (m.seekEnd (-8) == 92);
  assert (m.available == 8);
  assert (m.size == 100);
  assert (m.seekSet (4) == 4);
  assert (m.readString (4) == "o, w");
  m.writeString ("ie");
  assert (buf[0..12] == "Hello, wield");
  assert (m.position == 10);
  assert (m.available == 90);
  assert (m.size == 100);
  m.seekSet (0);
  assert (m.printf ("Answer is %d", 42) == 12);
  assert (buf[0..12] == "Answer is 42");
}

/// This subclass reads and constructs an array of bytes in memory.
class MemoryStream: TArrayStream!(ubyte[]) {

  /// Create the output buffer and setup for reading, writing, and seeking.
  // clear to an empty buffer.
  this() { this(cast(ubyte[]) null); }

  /***
   * Create the output buffer and setup for reading, writing, and seeking.
   * Load it with specific input data.
   */
  this(ubyte[] buf) { super (buf); }
  this(byte[] buf) { this(cast(ubyte[]) buf); } /// ditto
  this(char[] buf) { this(cast(ubyte[]) buf); } /// ditto

  /// Ensure the stream can write count extra bytes from cursor position without an allocation.
  void reserve(size_t count) {
    if (cur + count > buf.length)
      buf.length = cast(uint)((cur + count) * 2);
  }

  override size_t writeBlock(const void* buffer, size_t size) {
    reserve(size);
    return super.writeBlock(buffer,size);
  }

  unittest {
    MemoryStream m;

    m = new MemoryStream ();
    assert (m.isOpen);
    m.writeString ("Hello, world");
    assert (m.position == 12);
    assert (m.seekSet (0) == 0);
    assert (m.available == 12);
    assert (m.seekCur (4) == 4);
    assert (m.available == 8);
    assert (m.seekEnd (-8) == 4);
    assert (m.available == 8);
    assert (m.size == 12);
    assert (m.readString (4) == "o, w");
    m.writeString ("ie");
    assert (cast(char[]) m.data == "Hello, wield");
    m.seekEnd (0);
    m.writeString ("Foo");
    assert (m.position == 15);
    assert (m.available == 0);
    m.writeString ("Foo foo foo foo foo foo foo");
    assert (m.position == 42);
    m.position = 0;
    assert (m.available == 42);
    m.writef("%d %d %s",100,345,"hello");
    auto str = m.toString();
    assert (str[0..13] == "100 345 hello", str[0 .. 13]);
    assert (m.available == 29);
    assert (m.position == 13);

    MemoryStream m2;
    m.position = 3;
    m2 = new MemoryStream ();
    m2.writeString("before");
    m2.copyFrom(m,10);
    str = m2.toString();
    assert (str[0..16] == "before 345 hello");
    m2.position = 3;
    m2.copyFrom(m);
    auto str2 = m.toString();
    str = m2.toString();
    assert (str == ("bef" ~ str2));
  }
}

import std.mmfile;

/***
 * This subclass wraps a memory-mapped file with the stream API.
 * See std.mmfile module.
 */
class MmFileStream : TArrayStream!(MmFile) {

  /// Create stream wrapper for file.
  this(MmFile file) {
    super (file);
    MmFile.Mode mode = file.mode();
    writeable = mode > MmFile.Mode.read;
  }

  override void flush() {
    if (isopen) {
      super.flush();
      buf.flush();
    }
  }

  override void close() {
    if (isopen) {
      super.close();
      delete buf;
      buf = null;
    }
  }
}

unittest {
  auto test_file = std.file.deleteme ~ "-testing.txt";
  MmFile mf = new MmFile(test_file,MmFile.Mode.readWriteNew,100,null);
  MmFileStream m;
  m = new MmFileStream (mf);
  m.writeString ("Hello, world");
  assert (m.position == 12);
  assert (m.seekSet (0) == 0);
  assert (m.seekCur (4) == 4);
  assert (m.seekEnd (-8) == 92);
  assert (m.size == 100);
  assert (m.seekSet (4));
  assert (m.readString (4) == "o, w");
  m.writeString ("ie");
  ubyte[] dd = m.data;
  assert ((cast(char[]) dd)[0 .. 12] == "Hello, wield");
  m.position = 12;
  m.writeString ("Foo");
  assert (m.position == 15);
  m.writeString ("Foo foo foo foo foo foo foo");
  assert (m.position == 42);
  m.close();
  mf = new MmFile(test_file);
  m = new MmFileStream (mf);
  assert (!m.writeable);
  char[] str = m.readString(12);
  assert (str == "Hello, wield");
  m.close();
  std.file.remove(test_file);
}


/***
 * This subclass slices off a portion of another stream, making seeking relative
 * to the boundaries of the slice.
 *
 * It could be used to section a large file into a
 * set of smaller files, such as with tar archives. Reading and writing a
 * SliceStream does not modify the position of the source stream if it is
 * seekable.
 */
class SliceStream : FilterStream {
  private {
    ulong pos;  // our position relative to low
    ulong low; // low stream offset.
    ulong high; // high stream offset.
    bool bounded; // upper-bounded by high.
  }

  /***
   * Indicate both the source stream to use for reading from and the low part of
   * the slice.
   *
   * The high part of the slice is dependent upon the end of the source
   * stream, so that if you write beyond the end it resizes the stream normally.
   */
  this (Stream s, ulong low)
  in {
    assert (low <= s.size);
  }
  body {
    super(s);
    this.low = low;
    this.high = 0;
    this.bounded = false;
  }

  /***
   * Indicate the high index as well.
   *
   * Attempting to read or write past the high
   * index results in the end being clipped off.
   */
  this (Stream s, ulong low, ulong high)
  in {
    assert (low <= high);
    assert (high <= s.size);
  }
  body {
    super(s);
    this.low = low;
    this.high = high;
    this.bounded = true;
  }

  invariant() {
    if (bounded)
      assert (pos <= high - low);
    else
      // size() does not appear to be const, though it should be
      assert (pos <= (cast()s).size - low);
  }

  override size_t readBlock (void *buffer, size_t size) {
    assertReadable();
    if (bounded && size > high - low - pos)
        size = cast(size_t)(high - low - pos);
    ulong bp = s.position;
    if (seekable)
      s.position = low + pos;
    size_t ret = super.readBlock(buffer, size);
    if (seekable) {
      pos = s.position - low;
      s.position = bp;
    }
    return ret;
  }

  override size_t writeBlock (const void *buffer, size_t size) {
    assertWriteable();
    if (bounded && size > high - low - pos)
        size = cast(size_t)(high - low - pos);
    ulong bp = s.position;
    if (seekable)
      s.position = low + pos;
    size_t ret = s.writeBlock(buffer, size);
    if (seekable) {
      pos = s.position - low;
      s.position = bp;
    }
    return ret;
  }

  override ulong seek(long offset, SeekPos rel) {
    assertSeekable();
    long spos;

    switch (rel) {
      case SeekPos.Set:
        spos = offset;
        break;
      case SeekPos.Current:
        spos = cast(long)(pos + offset);
        break;
      case SeekPos.End:
        if (bounded)
          spos = cast(long)(high - low + offset);
        else
          spos = cast(long)(s.size - low + offset);
        break;
      default:
        assert(0);
    }

    if (spos < 0)
      pos = 0;
    else if (bounded && spos > high - low)
      pos = high - low;
    else if (!bounded && spos > s.size - low)
      pos = s.size - low;
    else
      pos = cast(ulong)spos;

    readEOF = false;
    return pos;
  }

  override @property size_t available() {
    size_t res = s.available;
    ulong bp = s.position;
    if (bp <= pos+low && pos+low <= bp+res) {
      if (!bounded || bp+res <= high)
        return cast(size_t)(bp + res - pos - low);
      else if (high <= bp+res)
        return cast(size_t)(high - pos - low);
    }
    return 0;
  }

  unittest {
    MemoryStream m;
    SliceStream s;

    m = new MemoryStream ((cast(char[])"Hello, world").dup);
    s = new SliceStream (m, 4, 8);
    assert (s.size == 4);
    assert (m.position == 0);
    assert (s.position == 0);
    assert (m.available == 12);
    assert (s.available == 4);

    assert (s.writeBlock (cast(char *) "Vroom", 5) == 4);
    assert (m.position == 0);
    assert (s.position == 4);
    assert (m.available == 12);
    assert (s.available == 0);
    assert (s.seekEnd (-2) == 2);
    assert (s.available == 2);
    assert (s.seekEnd (2) == 4);
    assert (s.available == 0);
    assert (m.position == 0);
    assert (m.available == 12);

    m.seekEnd(0);
    m.writeString("\nBlaho");
    assert (m.position == 18);
    assert (m.available == 0);
    assert (s.position == 4);
    assert (s.available == 0);

    s = new SliceStream (m, 4);
    assert (s.size == 14);
    assert (s.toString () == "Vrooorld\nBlaho");
    s.seekEnd (0);
    assert (s.available == 0);

    s.writeString (", etcetera.");
    assert (s.position == 25);
    assert (s.seekSet (0) == 0);
    assert (s.size == 25);
    assert (m.position == 18);
    assert (m.size == 29);
    assert (m.toString() == "HellVrooorld\nBlaho, etcetera.");
  }
}


// This stuff has been removed from the docs and is planned for deprecation.
/*
 * Interprets variadic argument list pointed to by argptr whose types
 * are given by arguments[], formats them according to embedded format
 * strings in the variadic argument list, and sends the resulting
 * characters to putc.
 *
 * The variadic arguments are consumed in order.  Each is formatted
 * into a sequence of chars, using the default format specification
 * for its type, and the characters are sequentially passed to putc.
 * If a $(D char[]), $(D wchar[]), or $(D dchar[]) argument is
 * encountered, it is interpreted as a format string. As many
 * arguments as specified in the format string are consumed and
 * formatted according to the format specifications in that string and
 * passed to putc. If there are too few remaining arguments, a
 * $(D FormatException) is thrown. If there are more remaining arguments than
 * needed by the format specification, the default processing of
 * arguments resumes until they are all consumed.
 *
 * Params:
 *        putc =        Output is sent do this delegate, character by character.
 *        arguments = Array of $(D TypeInfo)s, one for each argument to be formatted.
 *        argptr = Points to variadic argument list.
 *
 * Throws:
 *        Mismatched arguments and formats result in a $(D FormatException) being thrown.
 *
 * Format_String:
 *        <a name="format-string">$(I Format strings)</a>
 *        consist of characters interspersed with
 *        $(I format specifications). Characters are simply copied
 *        to the output (such as putc) after any necessary conversion
 *        to the corresponding UTF-8 sequence.
 *
 *        A $(I format specification) starts with a '%' character,
 *        and has the following grammar:

$(CONSOLE
$(I FormatSpecification):
    $(B '%%')
    $(B '%') $(I Flags) $(I Width) $(I Precision) $(I FormatChar)

$(I Flags):
    $(I empty)
    $(B '-') $(I Flags)
    $(B '+') $(I Flags)
    $(B '#') $(I Flags)
    $(B '0') $(I Flags)
    $(B ' ') $(I Flags)

$(I Width):
    $(I empty)
    $(I Integer)
    $(B '*')

$(I Precision):
    $(I empty)
    $(B '.')
    $(B '.') $(I Integer)
    $(B '.*')

$(I Integer):
    $(I Digit)
    $(I Digit) $(I Integer)

$(I Digit):
    $(B '0')
    $(B '1')
    $(B '2')
    $(B '3')
    $(B '4')
    $(B '5')
    $(B '6')
    $(B '7')
    $(B '8')
    $(B '9')

$(I FormatChar):
    $(B 's')
    $(B 'b')
    $(B 'd')
    $(B 'o')
    $(B 'x')
    $(B 'X')
    $(B 'e')
    $(B 'E')
    $(B 'f')
    $(B 'F')
    $(B 'g')
    $(B 'G')
    $(B 'a')
    $(B 'A')
)
    $(DL
    $(DT $(I Flags))
    $(DL
        $(DT $(B '-'))
        $(DD
        Left justify the result in the field.
        It overrides any $(B 0) flag.)

        $(DT $(B '+'))
        $(DD Prefix positive numbers in a signed conversion with a $(B +).
        It overrides any $(I space) flag.)

        $(DT $(B '#'))
        $(DD Use alternative formatting:
        $(DL
            $(DT For $(B 'o'):)
            $(DD Add to precision as necessary so that the first digit
            of the octal formatting is a '0', even if both the argument
            and the $(I Precision) are zero.)
            $(DT For $(B 'x') ($(B 'X')):)
            $(DD If non-zero, prefix result with $(B 0x) ($(B 0X)).)
            $(DT For floating point formatting:)
            $(DD Always insert the decimal point.)
            $(DT For $(B 'g') ($(B 'G')):)
            $(DD Do not elide trailing zeros.)
        ))

        $(DT $(B '0'))
        $(DD For integer and floating point formatting when not nan or
        infinity, use leading zeros
        to pad rather than spaces.
        Ignore if there's a $(I Precision).)

        $(DT $(B ' '))
        $(DD Prefix positive numbers in a signed conversion with a space.)
    )

    $(DT $(I Width))
    $(DD
    Specifies the minimum field width.
    If the width is a $(B *), the next argument, which must be
    of type $(B int), is taken as the width.
    If the width is negative, it is as if the $(B -) was given
    as a $(I Flags) character.)

    $(DT $(I Precision))
    $(DD Gives the precision for numeric conversions.
    If the precision is a $(B *), the next argument, which must be
    of type $(B int), is taken as the precision. If it is negative,
    it is as if there was no $(I Precision).)

    $(DT $(I FormatChar))
    $(DD
    $(DL
        $(DT $(B 's'))
        $(DD The corresponding argument is formatted in a manner consistent
        with its type:
        $(DL
            $(DT $(B bool))
            $(DD The result is <tt>'true'</tt> or <tt>'false'</tt>.)
            $(DT integral types)
            $(DD The $(B %d) format is used.)
            $(DT floating point types)
            $(DD The $(B %g) format is used.)
            $(DT string types)
            $(DD The result is the string converted to UTF-8.)
            A $(I Precision) specifies the maximum number of characters
            to use in the result.
            $(DT classes derived from $(B Object))
            $(DD The result is the string returned from the class instance's
            $(B .toString()) method.
            A $(I Precision) specifies the maximum number of characters
            to use in the result.)
            $(DT non-string static and dynamic arrays)
            $(DD The result is [s<sub>0</sub>, s<sub>1</sub>, ...]
            where s<sub>k</sub> is the kth element
            formatted with the default format.)
        ))

        $(DT $(B 'b','d','o','x','X'))
        $(DD The corresponding argument must be an integral type
        and is formatted as an integer. If the argument is a signed type
        and the $(I FormatChar) is $(B d) it is converted to
        a signed string of characters, otherwise it is treated as
        unsigned. An argument of type $(B bool) is formatted as '1'
        or '0'. The base used is binary for $(B b), octal for $(B o),
        decimal
        for $(B d), and hexadecimal for $(B x) or $(B X).
        $(B x) formats using lower case letters, $(B X) uppercase.
        If there are fewer resulting digits than the $(I Precision),
        leading zeros are used as necessary.
        If the $(I Precision) is 0 and the number is 0, no digits
        result.)

        $(DT $(B 'e','E'))
        $(DD A floating point number is formatted as one digit before
        the decimal point, $(I Precision) digits after, the $(I FormatChar),
        &plusmn;, followed by at least a two digit exponent: $(I d.dddddd)e$(I &plusmn;dd).
        If there is no $(I Precision), six
        digits are generated after the decimal point.
        If the $(I Precision) is 0, no decimal point is generated.)

        $(DT $(B 'f','F'))
        $(DD A floating point number is formatted in decimal notation.
        The $(I Precision) specifies the number of digits generated
        after the decimal point. It defaults to six. At least one digit
        is generated before the decimal point. If the $(I Precision)
        is zero, no decimal point is generated.)

        $(DT $(B 'g','G'))
        $(DD A floating point number is formatted in either $(B e) or
        $(B f) format for $(B g); $(B E) or $(B F) format for
        $(B G).
        The $(B f) format is used if the exponent for an $(B e) format
        is greater than -5 and less than the $(I Precision).
        The $(I Precision) specifies the number of significant
        digits, and defaults to six.
        Trailing zeros are elided after the decimal point, if the fractional
        part is zero then no decimal point is generated.)

        $(DT $(B 'a','A'))
        $(DD A floating point number is formatted in hexadecimal
        exponential notation 0x$(I h.hhhhhh)p$(I &plusmn;d).
        There is one hexadecimal digit before the decimal point, and as
        many after as specified by the $(I Precision).
        If the $(I Precision) is zero, no decimal point is generated.
        If there is no $(I Precision), as many hexadecimal digits as
        necessary to exactly represent the mantissa are generated.
        The exponent is written in as few digits as possible,
        but at least one, is in decimal, and represents a power of 2 as in
        $(I h.hhhhhh)*2<sup>$(I &plusmn;d)</sup>.
        The exponent for zero is zero.
        The hexadecimal digits, x and p are in upper case if the
        $(I FormatChar) is upper case.)
    )

    Floating point NaN's are formatted as $(B nan) if the
    $(I FormatChar) is lower case, or $(B NAN) if upper.
    Floating point infinities are formatted as $(B inf) or
    $(B infinity) if the
    $(I FormatChar) is lower case, or $(B INF) or $(B INFINITY) if upper.
    ))

Example:

-------------------------
import core.stdc.stdio;
import std.format;

void myPrint(...)
{
    void putc(dchar c)
    {
        fputc(c, stdout);
    }

    std.format.doFormat(&putc, _arguments, _argptr);
}

void main()
{
    int x = 27;

    // prints 'The answer is 27:6'
    myPrint("The answer is %s:", x, 6);
}
------------------------
 */
void doFormat()(scope void delegate(dchar) putc, TypeInfo[] arguments, va_list ap)
{
    import std.utf : toUCSindex, isValidDchar, UTFException, encode;
    import core.stdc.string : strlen;
    import core.stdc.stdlib : alloca, malloc, realloc, free;
    import core.stdc.stdio : snprintf;

    size_t bufLength = 1024;
    void* argBuffer = malloc(bufLength);
    scope(exit) free(argBuffer);

    size_t bufUsed = 0;
    foreach(ti; arguments)
    {
        // Ensure the required alignment
        bufUsed += ti.talign - 1;
        bufUsed -= (cast(size_t)argBuffer + bufUsed) & (ti.talign - 1);
        auto pos = bufUsed;
        // Align to next word boundary
        bufUsed += ti.tsize + size_t.sizeof - 1;
        bufUsed -= (cast(size_t)argBuffer + bufUsed) & (size_t.sizeof - 1);
        // Resize buffer if necessary
        while (bufUsed > bufLength)
        {
            bufLength *= 2;
            argBuffer = realloc(argBuffer, bufLength);
        }
        // Copy argument into buffer
        va_arg(ap, ti, argBuffer + pos);
    }

    auto argptr = argBuffer;
    void* skipArg(TypeInfo ti)
    {
        // Ensure the required alignment
        argptr += ti.talign - 1;
        argptr -= cast(size_t)argptr & (ti.talign - 1);
        auto p = argptr;
        // Align to next word boundary
        argptr += ti.tsize + size_t.sizeof - 1;
        argptr -= cast(size_t)argptr & (size_t.sizeof - 1);
        return p;
    }
    auto getArg(T)()
    {
        return *cast(T*)skipArg(typeid(T));
    }

    TypeInfo ti;
    Mangle m;
    uint flags;
    int field_width;
    int precision;

    enum : uint
    {
        FLdash = 1,
        FLplus = 2,
        FLspace = 4,
        FLhash = 8,
        FLlngdbl = 0x20,
        FL0pad = 0x40,
        FLprecision = 0x80,
    }

    static TypeInfo skipCI(TypeInfo valti)
    {
        for (;;)
        {
            if (typeid(valti).name.length == 18 &&
                    typeid(valti).name[9..18] == "Invariant")
                valti = (cast(TypeInfo_Invariant)valti).base;
            else if (typeid(valti).name.length == 14 &&
                    typeid(valti).name[9..14] == "Const")
                valti = (cast(TypeInfo_Const)valti).base;
            else
                break;
        }

        return valti;
    }

    void formatArg(char fc)
    {
        bool vbit;
        ulong vnumber;
        char vchar;
        dchar vdchar;
        Object vobject;
        real vreal;
        creal vcreal;
        Mangle m2;
        int signed = 0;
        uint base = 10;
        int uc;
        char[ulong.sizeof * 8] tmpbuf; // long enough to print long in binary
        const(char)* prefix = "";
        string s;

        void putstr(const char[] s)
        {
            //printf("putstr: s = %.*s, flags = x%x\n", s.length, s.ptr, flags);
            ptrdiff_t padding = field_width -
                (strlen(prefix) + toUCSindex(s, s.length));
            ptrdiff_t prepad = 0;
            ptrdiff_t postpad = 0;
            if (padding > 0)
            {
                if (flags & FLdash)
                    postpad = padding;
                else
                    prepad = padding;
            }

            if (flags & FL0pad)
            {
                while (*prefix)
                    putc(*prefix++);
                while (prepad--)
                    putc('0');
            }
            else
            {
                while (prepad--)
                    putc(' ');
                while (*prefix)
                    putc(*prefix++);
            }

            foreach (dchar c; s)
                putc(c);

            while (postpad--)
                putc(' ');
        }

        void putreal(real v)
        {
            //printf("putreal %Lg\n", vreal);

            switch (fc)
            {
                case 's':
                    fc = 'g';
                    break;

                case 'f', 'F', 'e', 'E', 'g', 'G', 'a', 'A':
                    break;

                default:
                    //printf("fc = '%c'\n", fc);
                Lerror:
                    throw new FormatException("incompatible format character for floating point type");
            }
            version (DigitalMarsC)
            {
                uint sl;
                char[] fbuf = tmpbuf;
                if (!(flags & FLprecision))
                    precision = 6;
                while (1)
                {
                    sl = fbuf.length;
                    prefix = (*__pfloatfmt)(fc, flags | FLlngdbl,
                            precision, &v, cast(char*)fbuf, &sl, field_width);
                    if (sl != -1)
                        break;
                    sl = fbuf.length * 2;
                    fbuf = (cast(char*)alloca(sl * char.sizeof))[0 .. sl];
                }
                putstr(fbuf[0 .. sl]);
            }
            else
            {
                ptrdiff_t sl;
                char[] fbuf = tmpbuf;
                char[12] format;
                format[0] = '%';
                int i = 1;
                if (flags & FLdash)
                    format[i++] = '-';
                if (flags & FLplus)
                    format[i++] = '+';
                if (flags & FLspace)
                    format[i++] = ' ';
                if (flags & FLhash)
                    format[i++] = '#';
                if (flags & FL0pad)
                    format[i++] = '0';
                format[i + 0] = '*';
                format[i + 1] = '.';
                format[i + 2] = '*';
                format[i + 3] = 'L';
                format[i + 4] = fc;
                format[i + 5] = 0;
                if (!(flags & FLprecision))
                    precision = -1;
                while (1)
                {
                    sl = fbuf.length;
                    int n;
                    version (CRuntime_Microsoft)
                    {
                        import std.math : isNaN, isInfinity;
                        if (isNaN(v)) // snprintf writes 1.#QNAN
                            n = snprintf(fbuf.ptr, sl, "nan");
                        else if(isInfinity(v)) // snprintf writes 1.#INF
                            n = snprintf(fbuf.ptr, sl, v < 0 ? "-inf" : "inf");
                        else
                            n = snprintf(fbuf.ptr, sl, format.ptr, field_width,
                                         precision, cast(double)v);
                    }
                    else
                        n = snprintf(fbuf.ptr, sl, format.ptr, field_width,
                                precision, v);
                    //printf("format = '%s', n = %d\n", cast(char*)format, n);
                    if (n >= 0 && n < sl)
                    {        sl = n;
                        break;
                    }
                    if (n < 0)
                        sl = sl * 2;
                    else
                        sl = n + 1;
                    fbuf = (cast(char*)alloca(sl * char.sizeof))[0 .. sl];
                }
                putstr(fbuf[0 .. sl]);
            }
            return;
        }

        static Mangle getMan(TypeInfo ti)
        {
          auto m = cast(Mangle)typeid(ti).name[9];
          if (typeid(ti).name.length == 20 &&
              typeid(ti).name[9..20] == "StaticArray")
                m = cast(Mangle)'G';
          return m;
        }

        /* p = pointer to the first element in the array
         * len = number of elements in the array
         * valti = type of the elements
         */
        void putArray(void* p, size_t len, TypeInfo valti)
        {
          //printf("\nputArray(len = %u), tsize = %u\n", len, valti.tsize);
          putc('[');
          valti = skipCI(valti);
          size_t tsize = valti.tsize;
          auto argptrSave = argptr;
          auto tiSave = ti;
          auto mSave = m;
          ti = valti;
          //printf("\n%.*s\n", typeid(valti).name.length, typeid(valti).name.ptr);
          m = getMan(valti);
          while (len--)
          {
            //doFormat(putc, (&valti)[0 .. 1], p);
            argptr = p;
            formatArg('s');
            p += tsize;
            if (len > 0) putc(',');
          }
          m = mSave;
          ti = tiSave;
          argptr = argptrSave;
          putc(']');
        }

        void putAArray(ubyte[long] vaa, TypeInfo valti, TypeInfo keyti)
        {
            putc('[');
            bool comma=false;
            auto argptrSave = argptr;
            auto tiSave = ti;
            auto mSave = m;
            valti = skipCI(valti);
            keyti = skipCI(keyti);
            foreach(ref fakevalue; vaa)
            {
                if (comma) putc(',');
                comma = true;
                void *pkey = &fakevalue;
                version (D_LP64)
                    pkey -= (long.sizeof + 15) & ~(15);
                else
                    pkey -= (long.sizeof + size_t.sizeof - 1) & ~(size_t.sizeof - 1);

                // the key comes before the value
                auto keysize = keyti.tsize;
                version (D_LP64)
                    auto keysizet = (keysize + 15) & ~(15);
                else
                    auto keysizet = (keysize + size_t.sizeof - 1) & ~(size_t.sizeof - 1);

                void* pvalue = pkey + keysizet;

                //doFormat(putc, (&keyti)[0..1], pkey);
                m = getMan(keyti);
                argptr = pkey;

                ti = keyti;
                formatArg('s');

                putc(':');
                //doFormat(putc, (&valti)[0..1], pvalue);
                m = getMan(valti);
                argptr = pvalue;

                ti = valti;
                formatArg('s');
            }
            m = mSave;
            ti = tiSave;
            argptr = argptrSave;
            putc(']');
        }

        //printf("formatArg(fc = '%c', m = '%c')\n", fc, m);
        int mi;
        switch (m)
        {
            case Mangle.Tbool:
                vbit = getArg!(bool)();
                if (fc != 's')
                {   vnumber = vbit;
                    goto Lnumber;
                }
                putstr(vbit ? "true" : "false");
                return;

            case Mangle.Tchar:
                vchar = getArg!(char)();
                if (fc != 's')
                {   vnumber = vchar;
                    goto Lnumber;
                }
            L2:
                putstr((&vchar)[0 .. 1]);
                return;

            case Mangle.Twchar:
                vdchar = getArg!(wchar)();
                goto L1;

            case Mangle.Tdchar:
                vdchar = getArg!(dchar)();
            L1:
                if (fc != 's')
                {   vnumber = vdchar;
                    goto Lnumber;
                }
                if (vdchar <= 0x7F)
                {   vchar = cast(char)vdchar;
                    goto L2;
                }
                else
                {   if (!isValidDchar(vdchar))
                        throw new UTFException("invalid dchar in format");
                    char[4] vbuf;
					encode(vbuf, vdchar);
                    putstr(vbuf);
                }
                return;

            case Mangle.Tbyte:
                signed = 1;
                vnumber = getArg!(byte)();
                goto Lnumber;

            case Mangle.Tubyte:
                vnumber = getArg!(ubyte)();
                goto Lnumber;

            case Mangle.Tshort:
                signed = 1;
                vnumber = getArg!(short)();
                goto Lnumber;

            case Mangle.Tushort:
                vnumber = getArg!(ushort)();
                goto Lnumber;

            case Mangle.Tint:
                signed = 1;
                vnumber = getArg!(int)();
                goto Lnumber;

            case Mangle.Tuint:
            Luint:
                vnumber = getArg!(uint)();
                goto Lnumber;

            case Mangle.Tlong:
                signed = 1;
                vnumber = cast(ulong)getArg!(long)();
                goto Lnumber;

            case Mangle.Tulong:
            Lulong:
                vnumber = getArg!(ulong)();
                goto Lnumber;

            case Mangle.Tclass:
                vobject = getArg!(Object)();
                if (vobject is null)
                    s = "null";
                else
                    s = vobject.toString();
                goto Lputstr;

            case Mangle.Tpointer:
                vnumber = cast(ulong)getArg!(void*)();
                if (fc != 'x')  uc = 1;
                flags |= FL0pad;
                if (!(flags & FLprecision))
                {   flags |= FLprecision;
                    precision = (void*).sizeof;
                }
                base = 16;
                goto Lnumber;

            case Mangle.Tfloat:
            case Mangle.Tifloat:
                if (fc == 'x' || fc == 'X')
                    goto Luint;
                vreal = getArg!(float)();
                goto Lreal;

            case Mangle.Tdouble:
            case Mangle.Tidouble:
                if (fc == 'x' || fc == 'X')
                    goto Lulong;
                vreal = getArg!(double)();
                goto Lreal;

            case Mangle.Treal:
            case Mangle.Tireal:
                vreal = getArg!(real)();
                goto Lreal;

            case Mangle.Tcfloat:
                vcreal = getArg!(cfloat)();
                goto Lcomplex;

            case Mangle.Tcdouble:
                vcreal = getArg!(cdouble)();
                goto Lcomplex;

            case Mangle.Tcreal:
                vcreal = getArg!(creal)();
                goto Lcomplex;

            case Mangle.Tsarray:
                putArray(argptr, (cast(TypeInfo_StaticArray)ti).len, (cast(TypeInfo_StaticArray)ti).next);
                return;

            case Mangle.Tarray:
                mi = 10;
                if (typeid(ti).name.length == 14 &&
                    typeid(ti).name[9..14] == "Array")
                { // array of non-primitive types
                  TypeInfo tn = (cast(TypeInfo_Array)ti).next;
                  tn = skipCI(tn);
                  switch (cast(Mangle)typeid(tn).name[9])
                  {
                    case Mangle.Tchar:  goto LarrayChar;
                    case Mangle.Twchar: goto LarrayWchar;
                    case Mangle.Tdchar: goto LarrayDchar;
                    default:
                        break;
                  }
                  void[] va = getArg!(void[])();
                  putArray(va.ptr, va.length, tn);
                  return;
                }
                if (typeid(ti).name.length == 25 &&
                    typeid(ti).name[9..25] == "AssociativeArray")
                { // associative array
                  ubyte[long] vaa = getArg!(ubyte[long])();
                  putAArray(vaa,
                        (cast(TypeInfo_AssociativeArray)ti).next,
                        (cast(TypeInfo_AssociativeArray)ti).key);
                  return;
                }

                while (1)
                {
                    m2 = cast(Mangle)typeid(ti).name[mi];
                    switch (m2)
                    {
                        case Mangle.Tchar:
                        LarrayChar:
                            s = getArg!(string)();
                            goto Lputstr;

                        case Mangle.Twchar:
                        LarrayWchar:
                            wchar[] sw = getArg!(wchar[])();
                            s = toUTF8(sw);
                            goto Lputstr;

                        case Mangle.Tdchar:
                        LarrayDchar:
                            s = toUTF8(getArg!(dstring)());
                        Lputstr:
                            if (fc != 's')
                                throw new FormatException("string");
                            if (flags & FLprecision && precision < s.length)
                                s = s[0 .. precision];
                            putstr(s);
                            break;

                        case Mangle.Tconst:
                        case Mangle.Timmutable:
                            mi++;
                            continue;

                        default:
                            TypeInfo ti2 = primitiveTypeInfo(m2);
                            if (!ti2)
                              goto Lerror;
                            void[] va = getArg!(void[])();
                            putArray(va.ptr, va.length, ti2);
                    }
                    return;
                }
                assert(0);

            case Mangle.Tenum:
                ti = (cast(TypeInfo_Enum)ti).base;
                m = cast(Mangle)typeid(ti).name[9];
                formatArg(fc);
                return;

            case Mangle.Tstruct:
            {        TypeInfo_Struct tis = cast(TypeInfo_Struct)ti;
                if (tis.xtoString is null)
                    throw new FormatException("Can't convert " ~ tis.toString()
                            ~ " to string: \"string toString()\" not defined");
                s = tis.xtoString(skipArg(tis));
                goto Lputstr;
            }

            default:
                goto Lerror;
        }

    Lnumber:
        switch (fc)
        {
            case 's':
            case 'd':
                if (signed)
                {   if (cast(long)vnumber < 0)
                    {        prefix = "-";
                        vnumber = -vnumber;
                    }
                    else if (flags & FLplus)
                        prefix = "+";
                    else if (flags & FLspace)
                        prefix = " ";
                }
                break;

            case 'b':
                signed = 0;
                base = 2;
                break;

            case 'o':
                signed = 0;
                base = 8;
                break;

            case 'X':
                uc = 1;
                if (flags & FLhash && vnumber)
                    prefix = "0X";
                signed = 0;
                base = 16;
                break;

            case 'x':
                if (flags & FLhash && vnumber)
                    prefix = "0x";
                signed = 0;
                base = 16;
                break;

            default:
                goto Lerror;
        }

        if (!signed)
        {
            switch (m)
            {
                case Mangle.Tbyte:
                    vnumber &= 0xFF;
                    break;

                case Mangle.Tshort:
                    vnumber &= 0xFFFF;
                    break;

                case Mangle.Tint:
                    vnumber &= 0xFFFFFFFF;
                    break;

                default:
                    break;
            }
        }

        if (flags & FLprecision && fc != 'p')
            flags &= ~FL0pad;

        if (vnumber < base)
        {
            if (vnumber == 0 && precision == 0 && flags & FLprecision &&
                !(fc == 'o' && flags & FLhash))
            {
                putstr(null);
                return;
            }
            if (precision == 0 || !(flags & FLprecision))
            {        vchar = cast(char)('0' + vnumber);
                if (vnumber < 10)
                    vchar = cast(char)('0' + vnumber);
                else
                    vchar = cast(char)((uc ? 'A' - 10 : 'a' - 10) + vnumber);
                goto L2;
            }
        }

        {
            ptrdiff_t n = tmpbuf.length;
            char c;
            int hexoffset = uc ? ('A' - ('9' + 1)) : ('a' - ('9' + 1));

            while (vnumber)
            {
                c = cast(char)((vnumber % base) + '0');
                if (c > '9')
                    c += hexoffset;
                vnumber /= base;
                tmpbuf[--n] = c;
            }
            if (tmpbuf.length - n < precision && precision < tmpbuf.length)
            {
                ptrdiff_t m = tmpbuf.length - precision;
                tmpbuf[m .. n] = '0';
                n = m;
            }
            else if (flags & FLhash && fc == 'o')
                prefix = "0";
            putstr(tmpbuf[n .. tmpbuf.length]);
            return;
        }

    Lreal:
        putreal(vreal);
        return;

    Lcomplex:
        putreal(vcreal.re);
        if (vcreal.im >= 0)
        {
            putc('+');
        }
        putreal(vcreal.im);
        putc('i');
        return;

    Lerror:
        throw new FormatException("formatArg");
    }

    for (int j = 0; j < arguments.length; )
    {
        ti = arguments[j++];
        //printf("arg[%d]: '%.*s' %d\n", j, typeid(ti).name.length, typeid(ti).name.ptr, typeid(ti).name.length);
        //ti.print();

        flags = 0;
        precision = 0;
        field_width = 0;

        ti = skipCI(ti);
        int mi = 9;
        do
        {
            if (typeid(ti).name.length <= mi)
                goto Lerror;
            m = cast(Mangle)typeid(ti).name[mi++];
        } while (m == Mangle.Tconst || m == Mangle.Timmutable);

        if (m == Mangle.Tarray)
        {
            if (typeid(ti).name.length == 14 &&
                    typeid(ti).name[9..14] == "Array")
            {
                TypeInfo tn = (cast(TypeInfo_Array)ti).next;
                tn = skipCI(tn);
                switch (cast(Mangle)typeid(tn).name[9])
                {
                case Mangle.Tchar:
                case Mangle.Twchar:
                case Mangle.Tdchar:
                    ti = tn;
                    mi = 9;
                    break;
                default:
                    break;
                }
            }
          L1:
            Mangle m2 = cast(Mangle)typeid(ti).name[mi];
            string  fmt;                        // format string
            wstring wfmt;
            dstring dfmt;

            /* For performance reasons, this code takes advantage of the
             * fact that most format strings will be ASCII, and that the
             * format specifiers are always ASCII. This means we only need
             * to deal with UTF in a couple of isolated spots.
             */

            switch (m2)
            {
            case Mangle.Tchar:
                fmt = getArg!(string)();
                break;

            case Mangle.Twchar:
                wfmt = getArg!(wstring)();
                fmt = toUTF8(wfmt);
                break;

            case Mangle.Tdchar:
                dfmt = getArg!(dstring)();
                fmt = toUTF8(dfmt);
                break;

            case Mangle.Tconst:
            case Mangle.Timmutable:
                mi++;
                goto L1;

            default:
                formatArg('s');
                continue;
            }

            for (size_t i = 0; i < fmt.length; )
            {        dchar c = fmt[i++];

                dchar getFmtChar()
                {   // Valid format specifier characters will never be UTF
                    if (i == fmt.length)
                        throw new FormatException("invalid specifier");
                    return fmt[i++];
                }

                int getFmtInt()
                {   int n;

                    while (1)
                    {
                        n = n * 10 + (c - '0');
                        if (n < 0)        // overflow
                            throw new FormatException("int overflow");
                        c = getFmtChar();
                        if (c < '0' || c > '9')
                            break;
                    }
                    return n;
                }

                int getFmtStar()
                {   Mangle m;
                    TypeInfo ti;

                    if (j == arguments.length)
                        throw new FormatException("too few arguments");
                    ti = arguments[j++];
                    m = cast(Mangle)typeid(ti).name[9];
                    if (m != Mangle.Tint)
                        throw new FormatException("int argument expected");
                    return getArg!(int)();
                }

                if (c != '%')
                {
                    if (c > 0x7F)        // if UTF sequence
                    {
                        i--;                // back up and decode UTF sequence
                        import std.utf : decode;
                        c = decode(fmt, i);
                    }
                  Lputc:
                    putc(c);
                    continue;
                }

                // Get flags {-+ #}
                flags = 0;
                while (1)
                {
                    c = getFmtChar();
                    switch (c)
                    {
                    case '-':        flags |= FLdash;        continue;
                    case '+':        flags |= FLplus;        continue;
                    case ' ':        flags |= FLspace;        continue;
                    case '#':        flags |= FLhash;        continue;
                    case '0':        flags |= FL0pad;        continue;

                    case '%':        if (flags == 0)
                                          goto Lputc;
                                     break;

                    default:         break;
                    }
                    break;
                }

                // Get field width
                field_width = 0;
                if (c == '*')
                {
                    field_width = getFmtStar();
                    if (field_width < 0)
                    {   flags |= FLdash;
                        field_width = -field_width;
                    }

                    c = getFmtChar();
                }
                else if (c >= '0' && c <= '9')
                    field_width = getFmtInt();

                if (flags & FLplus)
                    flags &= ~FLspace;
                if (flags & FLdash)
                    flags &= ~FL0pad;

                // Get precision
                precision = 0;
                if (c == '.')
                {   flags |= FLprecision;
                    //flags &= ~FL0pad;

                    c = getFmtChar();
                    if (c == '*')
                    {
                        precision = getFmtStar();
                        if (precision < 0)
                        {   precision = 0;
                            flags &= ~FLprecision;
                        }

                        c = getFmtChar();
                    }
                    else if (c >= '0' && c <= '9')
                        precision = getFmtInt();
                }

                if (j == arguments.length)
                    goto Lerror;
                ti = arguments[j++];
                ti = skipCI(ti);
                mi = 9;
                do
                {
                    m = cast(Mangle)typeid(ti).name[mi++];
                } while (m == Mangle.Tconst || m == Mangle.Timmutable);

                if (c > 0x7F)                // if UTF sequence
                    goto Lerror;        // format specifiers can't be UTF
                formatArg(cast(char)c);
            }
        }
        else
        {
            formatArg('s');
        }
    }
    return;

  Lerror:
    throw new FormatException();
}

// return the TypeInfo for a primitive type and null otherwise.  This
// is required since for arrays of ints we only have the mangled char
// to work from. If arrays always subclassed TypeInfo_Array this
// routine could go away.
private TypeInfo primitiveTypeInfo(Mangle m)
{
    // BUG: should fix this in static this() to avoid double checked locking bug
    __gshared TypeInfo[Mangle] dic;
    if (!dic.length) {
        dic = [
            Mangle.Tvoid : typeid(void),
            Mangle.Tbool : typeid(bool),
            Mangle.Tbyte : typeid(byte),
            Mangle.Tubyte : typeid(ubyte),
            Mangle.Tshort : typeid(short),
            Mangle.Tushort : typeid(ushort),
            Mangle.Tint : typeid(int),
            Mangle.Tuint : typeid(uint),
            Mangle.Tlong : typeid(long),
            Mangle.Tulong : typeid(ulong),
            Mangle.Tfloat : typeid(float),
            Mangle.Tdouble : typeid(double),
            Mangle.Treal : typeid(real),
            Mangle.Tifloat : typeid(ifloat),
            Mangle.Tidouble : typeid(idouble),
            Mangle.Tireal : typeid(ireal),
            Mangle.Tcfloat : typeid(cfloat),
            Mangle.Tcdouble : typeid(cdouble),
            Mangle.Tcreal : typeid(creal),
            Mangle.Tchar : typeid(char),
            Mangle.Twchar : typeid(wchar),
            Mangle.Tdchar : typeid(dchar)
            ];
    }
    auto p = m in dic;
    return p ? *p : null;
}

