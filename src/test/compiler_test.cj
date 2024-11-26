package cjmustache.test

import cjmustache.*

import std.unittest.*
import std.unittest.testmacro.*
import std.io.*
import std.collection.*
import std.convert.*
import std.reflect.*

/*
 * Not Test : loadTemplate
*/

@Test
public class CompilerTest {
    let compiler: Compiler

    public init() {
        compiler = Mustache.compiler()
    }
    @TestCase
    public func returnCompilerTest() {
        @Expect(compiler.
            standardsMode(true)._standardsMode)
        @Expect(compiler.
            strictSections(true)._strictSections)
        @Expect(compiler.
            defaultValue("foo")._nullValue.getOrThrow(), "foo")
        @Expect(compiler.
            nullValue("foo")._nullValue.getOrThrow(), "foo")
        @Expect(compiler.
            emptyStringIsFalse(true)._emptyStringIsFalse)
        @Expect(compiler.
            zeroIsFalse(true)._zeroIsFalse)

        let formatter = DefaultFormatter()
        @Expect(refEq((compiler.
        withFormatter(formatter)._formatter as DefaultFormatter).
        getOrThrow(), formatter))
        let escaper = NoneEscaper()
        @Expect(refEq((compiler.
        withEscaper(escaper)._escaper as NoneEscaper).
        getOrThrow(), escaper))
        let loader = DefenseTemplateLoader()
        @Expect(refEq((compiler.
        withLoader(loader)._loader as DefenseTemplateLoader).
        getOrThrow(), loader))
        let collector = DefaultCollector()
        @Expect(refEq((compiler.
        withCollector(collector)._collector as DefaultCollector).
        getOrThrow(), collector))
        let ctemp = compiler.withDelims("[[ ]]")
    }

    @TestCase
    public func computerNullValueTest() {
        @ExpectThrows[NoneValueException](
            compiler.computerNullValue("foo").
            getOrThrow()
        )
        let compiler1 = compiler.nullValue("{{name}}")
        @Expect(compiler1.computerNullValue("foo").
        getOrThrow(), "foo")
    }

    @TestCase
    public func isEmptyCharSequenceTest() {
        @Expect(compiler.isEmptyCharSequence(None) == false)
        @Expect(compiler.isEmptyCharSequence(""))
        @Expect(compiler.isEmptyCharSequence("foo") == false)
    }

    @TestCase
    public func isFalseyTest() {
        let compiler1 = compiler.emptyStringIsFalse(true)
        @Expect(compiler.isFalsey("") == false)
        @Expect(compiler.isFalsey("foo") == false)
        @Expect(compiler1.isFalsey(""))
        @Expect(compiler1.isFalsey("foo") == false)
        
        let compiler2 = compiler1.zeroIsFalse(true)
        @Expect(compiler2.isFalsey(1) == false)
        @Expect(compiler2.isFalsey(0))
    }
}