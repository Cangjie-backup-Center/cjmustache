package cjmustache.test

import cjmustache.*

import std.unittest.*
import std.unittest.testmacro.*
import std.io.*
import std.collection.*
import std.convert.*
import std.reflect.*

@Test
public class mustachePartTest {
    @TestCase
    public func templateLoaderTest() {
        let loader = Mustache.FAILING_LOADER
        @ExpectThrows[UnsupportedException](
            loader.getTemplate("")
        )
    }

    @TestCase
    public func formatterTest() {
        let formatter = Mustache.DEFAULT_FORMATTER
        @Expect(formatter.format((64i64 as Any).
        getOrThrow()).equalsIgnoreAsciiCase("64"))
        @Expect(formatter.format(("foo" as Any).
        getOrThrow()).equalsIgnoreAsciiCase("foo"))
    }

    @TestCase
    public func delimsTest() {
        let delims = Delims()
        @Expect(delims.isStaches())

        let sb = StringBuilder()
        delims.addTag(r'#', "foo", sb)
        @Expect(sb.toString().
        equalsIgnoreAsciiCase("{{#foo}}"))

        delims.updateDelims("[ ]")
        @Expect(delims.start1, r'[')
        @Expect(delims.start2, Mustache.NO_CHAR)
        @Expect(delims.end1, r']')
        @Expect(delims.end2, Mustache.NO_CHAR)

        delims.updateDelims("[[ ]]")
        @Expect(delims.start1, r'[')
        @Expect(delims.start2,  r'[')
        @Expect(delims.end1, r']')
        @Expect(delims.end2, r']')

        let delimsCopy = delims.copy()
        @Expect(delimsCopy.start1, delims.start1)
        @Expect(delimsCopy.start2, delims.start2)
        @Expect(delimsCopy.end1, delims.end1)
        @Expect(delimsCopy.end2, delims.end2)
    } 

    @TestCase
    public func restoreStartTagTest() {
        let sb = StringBuilder()
        sb.append("test")
        let delims = Delims()
        Mustache.restoreStartTag(sb, delims)
        @Expect(sb.toString(), "{{test")
        delims.start2 = Mustache.NO_CHAR
        sb.reset(capacity: Some(1))
        sb.append("test")
        Mustache.restoreStartTag(sb, delims)
        @Expect(sb.toString(), "{test")
    }
}

@Test
public class ParserTest {
    var source: ?InputStream = None

    @TestCase
    public func nextCharTest() {
        let bf = ByteBuffer()
        bf.write("abcdef".toArray())
        source = BufferedInputStream(bf)
        @Expect(nextChar(), 97)
        @Expect(nextChar(), 98)
        @Expect(nextChar(), 99)
        @Expect(nextChar(), 100)
        @Expect(nextChar(), 101)
        @Expect(nextChar(), 102)
        @Expect(nextChar(), 0)
    }
    
    @TestCase
    public func StringBuilderExtendTest() {
        let sb = StringBuilder()
        sb.append("test")
        sb.insert(0, r'{')
        sb.insert(1, r'{')
        @Expect(sb.toString(), "{{test")
        sb.replace(0, 2, "A")
        @Expect(sb.toString(), "Atest")
    }

    @TestCase
    public func StringBuilderResetTest() {
        let sb = StringBuilder()
        sb.append("test")
        sb.reset(capacity: Some(1))
        @Expect(sb.toString(), "")
    }


    private func nextChar(): Int64 { 
        try {
            let arr = Array<Byte>(1, repeat: 0)
            let s = source.getOrThrow()
            s.read(arr)
            return Int64(arr[0]) 
        } catch (ioe: IOException) {
            throw MustacheException(ioe)
        }
    }

}

extend StringBuilder {
    public func insert(index: Int64, r: Rune) {
        let str = this.toString()
        this.reset(capacity: Some(1))
        this.append(str[0..index] + r.toString() + str[index..])
    }

    public func replace(l: Int64, r: Int64, s: String) {
        let str = this.toString()
        this.reset(capacity: Some(1))
        this.append(str[0..l] + s + str[r..])
    } 
}