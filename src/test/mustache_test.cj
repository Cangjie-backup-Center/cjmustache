package cjmustache.test

import cjmustache.*

import std.unittest.*
import std.unittest.testmacro.*
import std.io.*
import std.collection.*
import std.convert.*
import std.reflect.*

@Test
public class MustacheTest {
    protected var name: String = ""
    protected var partials = HashMap<String, String>()

    @TestCase 
    public func testFieldVariable() {
        @Expect(test("bar", "{{foo}}", Object1()))
    }

    @TestCase 
    public func testMethodVariable() {
        @Expect(test("bar", "{{foo}}", Object2()))
    }

    @TestCase 
    public func testPropertyVariable() {
        @Expect(test("bar", "{{foo}}", Object3()))
    }

    @TestCase 
    public func testCustomContext(){
        @Expect(test("bar", "{{foo}}", CustomContext1()))
    }

    @TestCase 
    public func testCharSequenceVariable(){
        let ctx = HashMap<String, Any>()
        let stringBuffer = ByteBuffer()
        stringBuffer.write("bar".toArray())
        ctx.put("foo", (stringBuffer as Any).getOrThrow())
        @Expect(test("bar", "{{foo}}", ctx))
    }

    @TestCase 
    public func testDefaultMethodVariable() {
        @Expect(test("bar", "{{foo}}", HasDefault1()))
        @Expect(test("bang", "{{foo}}", Interloper1()))
        @Expect(test("bong", "{{foo}}", Interloper2()))
    }

    @TestCase 
    public func testBooleanPropertyVariable() {
        @Expect(test("true", "{{foo}}", Object4()))
    }

    @TestCase 
    public func testPrimitiveBooleanPropertyVariable() {
        @Expect(test("false", "{{foo}}", Object5()))
    }

    @TestCase 
    public func testSkipVoidReturn() {
        @Expect(test("bar", "{{foo}}", Object6()))
    }

    @TestCase 
    public func testCallSiteReuse() {
        let tmpl = Mustache.compiler().compile("{{foo}}");
        let ctx = Object3()
        for (ii in 0..50) {
            @Expect(check("bar", tmpl.execute(ctx)))
        }
    }

    @TestCase 
    public func testCallSiteChange() {
        let tmpl = Mustache.compiler().compile("{{foo}}");
        @Expect(check("bar", tmpl.execute(Object3())))
        @Expect(check("bar", tmpl.execute(Object1())))
    }

    @TestCase 
    public func testSectionWithNonFalseyZero() {
        @Expect(test(Mustache.compiler(), 
        "test", "{{#foo}}test{{/foo}}", Object7()))
    }

    @TestCase 
    public func testSectionWithFalseyZero() {
        @Expect(test(Mustache.compiler().zeroIsFalse(true), "",
            "{{#intv}}intv{{/intv}}" +
            "{{#longv}}longv{{/longv}}" +
            "{{#floatv}}floatv{{/floatv}}" +
            "{{#doublev}}doublev{{/doublev}}" +
            "{{#longm}}longm{{/longm}}" +
            "{{#intm}}intm{{/intm}}" +
            "{{#floatm}}floatm{{/floatm}}" +
            "{{#doublem}}doublem{{/doublem}}",
            Object8()))
    }

    // @Test public void testOptionalSupportingCollector () // TODO

    @TestCase 
    public func testCompoundVariable() {
        @Expect(test("hello", "{{foo.bar.baz}}", Object11()))
    }

    @Skip[true]
    @TestCase    // TODO
    public func testNullComponentInCompoundVariable() {  // 仓颉的反射尚未支持枚举，即Option类型 
        try {
            @Expect(test(Mustache.compiler(), 
            "unused", "{{foo.bar.baz}}", Object13()))
            @Assert(false)
        } catch (me: MustacheException) {} // expected
    }

    @TestCase 
    public func testMissingComponentInCompoundVariable() {
        try {
            @Expect(test(Mustache.compiler(), 
            "unused", "{{foo.bar.baz}}", Object15()))
            @Assert(false)
        } catch (me: MustacheException) {} // expected
    }

    @Skip[true]
    @TestCase 
    public func testNullComponentInCompoundVariableWithDefault () {  // TODO
        @Expect(test(Mustache.compiler().
        nullValue("null"), "null", "{{foo.bar.baz}}", Object16()))
        @Expect(test(Mustache.compiler().
        nullValue("null"), "null", "{{foo.bar.baz}}", Object13()))
    }

    @TestCase 
    public func testMissingComponentInCompoundVariableWithDefault() {
        @Expect(test(Mustache.compiler().
        defaultValue("?"), "?", "{{foo.bar.baz}}", Object14()))
        @Expect(test(Mustache.compiler().
        defaultValue("?"), "?", "{{foo.bar.baz}}", Object15()))
    }

    @TestCase 
    public func testCompoundVariableAsPlain() {
        // if a compound variable is found without decomposition, we use that first
        @Expect(test("wholekey", "{{foo.bar}}", context(
                "foo.bar", "wholekey",
                "foo", Object17())))
    }

    @Skip[true]
    @TestCase   // TODO
    public func testShadowedContextWithNull() {
        let comp = Mustache.compiler().nullValue("(null)");
        let tmpl = "{{foo}}{{#inner}}{{foo}}{{/inner}}"
        let expect = "outer(null)"
        @Expect(test(comp, expect, tmpl, Object18()))
        // same as above, but with maps instead of objects
        @Expect(test(comp, expect, tmpl, 
        context("foo", "outer", "inner", context("foo", None))))
    }
    
    @TestCase 
    public func testContextPokingLambda() {
        let c = Mustache.compiler()

        let lfoo = c.compile("{{foo}}")
        @Expect(check("1", lfoo.execute(Foo())))

        let lbar = c.compile("{{bar}}")
        @Expect(check("one", lbar.execute(Bar())))

        @Expect(test(c, "1oneone1one!", 
        "{{#events}}{{#renderEvent}}{{/renderEvent}}{{/events}}", context(
                "renderEvent", TestLambda(lfoo, lbar), "events",
                ArrayList<Any>(Foo(), Bar(), Bar(), Foo(), Bar(), "wtf?"))))
    }

    // @Test public void testCustomFormatter ()  // TODO


    @TestCase 
    public func testMapEntriesPlusReflectSection() {
        let data = HashMap<String,String>()
        data.put("k1", "v1")
        data.put("k2", "v2")
        // 'key' and 'value' here rely on reflection so we can't test this in GWT
        @Expect(test("k1v1k2v2", 
        "{{#map.entrySet}}{{mapkey}}{{mapvalue}}{{/map.entrySet}}",
            context("map", data)))
    }

    @TestCase 
    public func testNoAccesCoercion() {
        let ctx = Object21()
        let comp = Mustache.compiler().
            withCollector(
                DefaultCollector(_allowAccessCoercion: false)).
            defaultValue("missing");
        @Expect(test(comp, 
        "hello:missing", "{{foo.bar.baz}}:{{foo.bar.quux}}", ctx))
    }

    protected func test(compiler: Compiler, expected: ?String, template: String, ctx: ?Any): Bool {
        let actual: String = compiler.compile(template).execute(ctx)
        if (!expected.getOrThrow().equalsIgnoreAsciiCase(actual)) {
            println("")
            println("----------------------------------------")
            println("")
            println("Failed: ${name}")
            println("Tempalte : \"${showWhitespace(template)}\"")
            if (!partials.isEmpty()) {
                println("Partials : ")
                for ((k, v) in partials) {
                    println("\t${k}: \"${showWhitespace(v)}\"")
                }
            }
            println("Expected : \"${showWhitespace(expected.getOrThrow())}\"")
            println("Result   : \"${showWhitespace(actual)}\"")
            println("----------------------------------------")
            println("")
        }

        return check(expected, actual)
    }

    protected func check(expected: ?String, output: String): Bool {
        return showWhitespace(expected.getOrThrow()).
        equalsIgnoreAsciiCase(showWhitespace(output))
    }

    protected func test(expected: ?String, template: String, ctx: ?Any): Bool {
        return test(Mustache.compiler(), expected, template, ctx)
    }

    protected static func context(data: Array<?Any>): Any {
        let ctx = HashMap<String, ?Any>()
        var ii = 0
        while (ii < data.size) {
            if (ii + 1 >= data.size) { break }
            if (data[ii + 1].isNone()) {
                ctx.put((data[ii].getOrThrow() as String).
                getOrThrow(), None)
            } else {
                ctx.put((data[ii].getOrThrow() as String).
                getOrThrow(), (data[ii + 1].getOrThrow() as Any).
                getOrThrow())
            }
            ii += 2
        }
        return (ctx as Any).getOrThrow()
    }

    protected static let EMPTY: Any = context()

    protected func showWhitespace(s: String): String {
        s.replace("\r\n", (r"\u{240D}").toString())
        s.replace('\t', (r"\u{21E5}").toString())
        s.replace("\n", "\u{21B5}\n")
        s.replace("\u{240D}", "\u{240D}\n")
        return s
    }
}

public class Object1 {
    public let foo: String = "bar"
}

public class Object2 {
    public func foo(): String {
        return "bar"
    }
}

public class Object3 {
    public func getFoo(): String {
        return "bar"
    }
}

public class Object4 {
    public func getFoo(): Bool {
        return true
    }
}

public class Object5 {
    public func getFoo(): Bool {
        return false
    }
}

public class Object6 {
    public func foo(): Unit {}

    public func getFoo(): String {
        return "bar"
    }
}

public class Object7 {
    public let foo: Int64 = 0
}

public class Object8 {
    public let intv: Int32 = 0i32
    public let longv: Int64 = 0
    public let floatv: Float32 = 0.0f32
    public let doublev: Float64 = 0.0f64
    public func intm(): Int32 { return 0i32 }
    public func longm(): Int64 { return 0 }
    public func floatm(): Float32 { return 0.0f32 }
    public func doublem(): Float64 { return 0.0f64 }
}

public class Object9 {
    public let baz: String = "hello"
}

public class Object10 {
    public let bar: Object9 = Object9()
}

public class Object11 {
    public func foo(): Object10 {
        return Object10()
    }
}

public class Object12 {
    public let bar: ?Any = None
}

public class Object13 {
    public let foo: Object12 = Object12()
}

public class Object14 {}

public class Object15 {
    public let foo: Object14 = Object14()
}

public class Object16 {
    public let foo: ?Any = None
}

public class Object17 {
    public let bar: String = "hello"
}

public class Object18 {
    public let foo: String = "outer"
    public let inner = Object16()
}

public class Object19 {
    public let baz: String = "hello"
    private let quux: String = "hello"
}

public class Object20 {
    public let bar = Object19()
}

public class Object21 {
    public func foo(): Object20 {
        return Object20()
    }
}


public class CustomContext1 <: CustomContext {
    public func get(name: String): ?Any {
        if (name.equalsIgnoreAsciiCase("foo")) {
            return "bar"
        } 
        return None
    }
}

public interface HasDefault {
    func getFoo() { return "bar" }
}

public class HasDefault1 <: HasDefault {

}

public interface Interloper <: HasDefault {
    func getFoo() { return "bang" }
}

public class Interloper1 <: Interloper {
    
}

public class Interloper2 <: Interloper {
    public override func getFoo() { return "bong" }
}

public class Foo {
    public let foo: Int64 = 1
}

public class Bar {
    public let bar: String = "one"
}

public class TestLambda <: Lambda {
    public TestLambda(let lfoo: Template, let lbar: Template) { }

    public func execute(frag: Fragment, out: OutputStream): Unit {
        let ctx = frag.context().getOrThrow()
        if (ctx is Foo) { lfoo.execute(ctx, out) }
        else if (ctx is Bar) { lbar.execute(ctx, out) }
        else { out.write("!".toArray()) }
    }
}