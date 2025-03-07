package cjmustache.test

import cjmustache.*

import std.unittest.*
import std.unittest.testmacro.*
import std.io.*
import std.collection.*
import std.convert.*
import std.reflect.*

@Test
public class TemplateTest {
    let testclass3: TestClass3
    let testclass4: TestClass4
    let info3: TypeInfo
    let info4: TypeInfo
    let template: Template
    let mp: HashMap<String, Any>
    let arrInt: Array<Int64>
    let arrStr: Array<String>
    let arrStr2: Array<Array<String>>
    let anyIterStr: Any
    let listStr: ArrayList<String>
    let listInt: ArrayList<Int64>
    let arrMp1: HashMap<String, Any>
    let arrMp2: HashMap<String, Any>
    let arrMp3: HashMap<String, Any>
    let listMp: ArrayList<Any>
    let arrMp4: HashMap<String, Any>


    public init() {
        let compiler = Mustache.compiler()
        template = Template([TestSegment()], compiler)
        testclass3 = TestClass3()
        testclass4 = TestClass4()
        info3 = TypeInfo.of(testclass3)
        info4 = TypeInfo.of(testclass4)
        mp = HashMap<String, Any>()
        mp.add("foo", "bar")
        mp.add("arr", [1, 2, 3])
        arrInt = [1, 2, 3]
        arrStr = ["foo", "bar", "tony", "tom", "aili"]
        arrStr2 = [["foo"], ["bar"]]
        anyIterStr = (arrStr.iterator() as Any).getOrThrow()
        listStr = ArrayList<String>(["foo", "bar"])
        listInt = ArrayList<Int64>([1, 2])
        arrMp1 = HashMap<String, Any>()
        arrMp1.add("foo", (listStr as Any).getOrThrow())
        arrMp2 = HashMap<String, Any>()
        arrMp3 = HashMap<String, Any>()
        arrMp2.add("bar", ("woo" as Any).getOrThrow())
        arrMp3.add("woo", ("tom" as Any).getOrThrow())
        listMp = ArrayList<Any>([arrMp2, arrMp3])
        arrMp4 = HashMap<String, Any>()
        arrMp4.add("foo", listMp)
    }

    @TestCase
    public func keyTest() {
        let ctx = (["foo", "bar"] as Any).getOrThrow()
        let key1 = Key(ctx, "foobar")
        let key2 = Key(ctx, "barfoo")
        @Expect(key1.toString().
        equalsIgnoreAsciiCase("Array<String>:foobar"))
        @Expect(key2.toString().
        equalsIgnoreAsciiCase("Array<String>:barfoo"))
        @Expect(key1.equals(key2))
    }

    @TestCase
    public func contextTest() {
        let ctx1 = Context(("foo" as Any).
        getOrThrow(), None, 0, true ,false)
        let ctx2 = Context(("bar" as Any).
        getOrThrow(), ctx1, 1, false, false)
        let ctx3 = ctx2.next(("hello" as Any).
        getOrThrow())
        let ctx4 = ctx3.next(("world" as Any).
        getOrThrow(), 3, false, true)

        @Expect(((ctx4.data.getOrThrow() as String).
        getOrThrow()).equalsIgnoreAsciiCase("world"))

        @Expect(ctx4.index, 3)
        @Expect(ctx4.onFirst, false)
        @Expect(ctx4.onLast, true)

        @Expect(refEq((ctx4.parent.getOrThrow() as Context).
        getOrThrow(), ctx3))

        @Expect(((((ctx4.parent.getOrThrow() as Context).
        getOrThrow()).data.getOrThrow() as String).getOrThrow()).
        equalsIgnoreAsciiCase("hello"))

        @Expect(refEq((ctx3.parent.getOrThrow() as Context).
        getOrThrow(), ctx2))

        @Expect(((((ctx3.parent.getOrThrow() as Context).
        getOrThrow()).data.getOrThrow() as String).getOrThrow()).
        equalsIgnoreAsciiCase("bar"))

        @Expect(refEq((ctx2.parent.getOrThrow() as Context).
        getOrThrow(), ctx1))

        @Expect(((((ctx2.parent.getOrThrow() as Context).
        getOrThrow()).data.getOrThrow() as String).getOrThrow()).
        equalsIgnoreAsciiCase("foo"))

        @ExpectThrows[NoneValueException](
            ctx1.parent.getOrThrow()
        )
    }

    @TestCase
    public func checkForMissingTest() {
        let ctx1 = Context(None, None, 0, false, false)
        let str1 = "foo"
        let str2 = Template.NO_FETCHER_FOUND

        @Expect(refEq((template.
        checkForMissing("foo", 0, false, ctx1).
        getOrThrow() as Context).getOrThrow(), ctx1))

        @Expect(((template.
        checkForMissing("bar", 0, false, str1).
        getOrThrow() as String).getOrThrow()).
        equalsIgnoreAsciiCase("foo"))

        @ExpectThrows[NoneValueException](
            template.
            checkForMissing("foo", 0, true, str2).getOrThrow()
        )
    }

    @TestCase
    public func isThisNameTest() {
        @Expect(Template.isThisName("."))
        @Expect(Template.isThisName("this"))
        @Expect(Template.isThisName("foo") == false)
    }

    @TestCase
    public func getValueInTest() {
        @Expect((template.getValueIn("foo", "this", 0).
        getOrThrow() as String).getOrThrow(), "foo")
        @Expect((template.getValueIn(1, "this", 0).
        getOrThrow() as Int64).getOrThrow(), 1)

        @Expect((template.getValueIn(mp as Any, "foo", 0).
        getOrThrow() as String).getOrThrow(), "bar")
        @Expect((template.getValueIn(1, "this", 0).
        getOrThrow() as Int64).getOrThrow(), 1)

        @Expect((template.getValueIn(listStr, "0", 0).
        getOrThrow() as String).getOrThrow(), "foo")
        @Expect((template.getValueIn(listInt, "0", 0).
        getOrThrow() as Int64).getOrThrow(), 1)

        @Expect((template.getValueIn(arrInt, "0", 0).
        getOrThrow() as Int64).getOrThrow(), 1)

        @Expect((template.getValueIn(anyIterStr, "0", 0).
        getOrThrow() as String).getOrThrow(), "foo")
        @Expect((template.getValueIn(anyIterStr, "2", 0).
        getOrThrow() as String).getOrThrow(), "tom")
        @Expect(((template.getValueIn(anyIterStr, "6", 0).
        getOrThrow() as String).getOrThrow()).
        equalsIgnoreAsciiCase("<no fetcher found>"))

        let segment = TestSegment()
        @Expect((template.getValueIn(segment as Any, "foo", 0).
        getOrThrow() as String).getOrThrow(), "<no fetcher found>")

        @Expect((template.getValueIn(testclass3, "foo", 0).
        getOrThrow() as String).getOrThrow(), "foo")
        @Expect((template.getValueIn(testclass3, "Hello", 0).
        getOrThrow() as String).getOrThrow(), "Hello")
        @Expect((template.getValueIn(testclass3, "str1", 0).
        getOrThrow() as String).getOrThrow(), "foo")
        @Expect((template.getValueIn(testclass4, "str1", 0).
        getOrThrow() as String).getOrThrow(), "foo")
    }

    @TestCase
    public func getValueTest() {
        let ctx1 = Context(anyIterStr, None, 0, true ,false)
        let ctx2 = Context(arrInt, ctx1, 1, false, false)
        let ctx3 = ctx2.next(listStr)
        let ctx4 = ctx3.next(mp, 3, false, true)

        @Expect(((template.getValue(ctx1, "-first", 0, true)).
        getOrThrow() as Bool).getOrThrow(), true)
        @Expect(((template.getValue(ctx1, "-last", 0, true)).
        getOrThrow() as Bool).getOrThrow(), false)
        @Expect(((template.getValue(ctx1, "-index", 0, true)).
        getOrThrow() as Int64).getOrThrow(), 0)

        @Expect(((template.getValue(ctx4, "foo", 0, true).
        getOrThrow() as String).getOrThrow()), "bar")
        @Expect(((template.getValue(ctx4, "0", 0, true).
        getOrThrow() as String).getOrThrow()), "foo")
        @Expect(((template.getValue(ctx4, "2", 0, true).
        getOrThrow() as Int64).getOrThrow()), 3)

        let ctx5 = Context(arrMp1, None, 0, false, false)
        let ctx6 = Context(arrMp4, None, 0, false, false)
        @Expect((template.getCompoundValue(ctx5, "foo.0", 0, true).
        getOrThrow() as String).getOrThrow(), "foo")
        @Expect((template.getCompoundValue(ctx5, "foo.1", 0, true).
        getOrThrow() as String).getOrThrow(), "bar")
        @Expect((template.getCompoundValue(ctx6, "foo.0.bar", 0, true).
        getOrThrow() as String).getOrThrow(), "woo")
    }

    @TestCase
    public func getCompoundValueTest() {
        let ctx1 = Context(arrMp1, None, 0, false, false)
        let ctx2 = Context(arrMp4, None, 0, false, false)
        @Expect((template.getCompoundValue(ctx1, "foo.0", 0, true).
        getOrThrow() as String).getOrThrow(), "foo")
        @Expect((template.getCompoundValue(ctx1, "foo.1", 0, true).
        getOrThrow() as String).getOrThrow(), "bar")
        @Expect((template.getCompoundValue(ctx2, "foo.0.bar", 0, true).
        getOrThrow() as String).getOrThrow(), "woo")
    }

    @TestCase
    public func getSectionValueTest() {
        let ctx1 = Context(arrMp1, None, 0, false, false)
        let ctx2 = Context(arrMp4, None, 0, false, false)
        @Expect((template.getSectionValue(ctx1, "foo.0", 0).
        getOrThrow() as String).getOrThrow(), "foo")
        @Expect((template.getSectionValue(ctx1, "foo.1", 0).
        getOrThrow() as String).getOrThrow(), "bar")
        @Expect((template.getSectionValue(ctx2, "foo.0.bar", 0).
        getOrThrow() as String).getOrThrow(), "woo")

        let ret1 = template.getSectionValue(ctx1, "foo.9", 0).
        getOrThrow() as ArrayList<Any>
    }

    @Skip[true]
    @TestCase
    public func getValueOrDefaultTest() {
        let ctx1 = Context(arrMp1, None, 0, false, false)
        let ctx2 = Context(arrMp4, None, 0, false, false)
        @Expect((template.getValueOrDefault(ctx1, "foo.0", 0).
        getOrThrow() as String).getOrThrow(), "foo")
        @Expect((template.getValueOrDefault(ctx1, "foo.1", 0).
        getOrThrow() as String).getOrThrow(), "bar")
        @Expect((template.getValueOrDefault(ctx2, "foo.0.bar", 0).
        getOrThrow() as String).getOrThrow(), "woo")
        
        // test missingIsNull = true, nullValue = "{{name}}"
        // @Expect((template.getValueOrDefault(ctx1, "foo.9", 0).getOrThrow() as String).getOrThrow(), "foo.9")
        // test missingIsNull = true, nullValue = None
        // @ExpectThrows[NoneValueException](
        //     template.getValueOrDefault(ctx1, "foo.9", 0).getOrThrow()
        // )
    }
}

protected class TestSegment <: Segment {
    protected func execute(
        _: Template, _: Context, 
        _: OutputStream): Unit {
        throw UnInplementException()
    }
    protected func decompile(
        _: Delims, _: StringBuilder): Unit {
        throw UnInplementException()
    }
    protected func visit(_: Visitor): Unit {
        throw UnInplementException()
    }

    protected func indent(
        _: String, _: Bool,
        _: Bool): Segment {
        throw UnInplementException()
    }

    protected func isStandalone(): Bool {
        throw UnInplementException()
    }
}

open public class TestClass3 {
    public let str1 = "foo" 
    public let str2 = "bar"

    public func foo(): String {
        return "foo"
    }

    public func getHello(): String {
        return "Hello"
    }

    public func isWorld(): Bool {
        return true
    }
}

public class TestClass4 <: TestClass3 {
    public let str3 = "woo"
}
