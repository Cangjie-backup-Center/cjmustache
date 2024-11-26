package cjmustache.test

import cjmustache.*

import std.unittest.*
import std.unittest.testmacro.*
import std.io.*
import std.collection.*
import std.convert.*
import std.reflect.*


@Test
public class DefaultCollectorTest {
    let collector: DefaultCollector
    let testclass1: TestClass1
    let testclass2: TestClass2
    let info1: ClassTypeInfo
    let info2: ClassTypeInfo

    public init() {
        collector = DefaultCollector()
        testclass1 = TestClass1()
        testclass2 = TestClass2()
        info1 = (TypeInfo.of(testclass1) as ClassTypeInfo).
        getOrThrow()
        info2 = (TypeInfo.of(testclass2) as ClassTypeInfo).
        getOrThrow()
    }

    @TestCase
    public func getMethodOnTest() {
        @Expect((collector.getMethodOn(info1, "foo").
        getOrThrow()).name, "foo")
        @Expect((collector.getMethodOn(info1, "hello").
        getOrThrow()).name, "getHello")
        @Expect((collector.getMethodOn(info1, "world").
        getOrThrow()).name, "isWorld")
        @ExpectThrows[NoneValueException](
            collector.getMethodOn(info1, "bar").
            getOrThrow()
        )
    }

    @TestCase
    public func getFieldTest() {
        @Expect(((collector.getField(info1, "str1").getOrThrow()).
        getValue(testclass1) as String).getOrThrow(), "foo")
        @Expect(((collector.getField(info1, "str2").getOrThrow()).
        getValue(testclass1) as String).getOrThrow(), "bar")
        @Expect(((collector.getField(info2, "str3").getOrThrow()).
        getValue(testclass2) as String).getOrThrow(), "woo")
    }

    @TestCase
    public func getMethodTest() {
        @Expect((collector.getMethod(info1, "foo").
        getOrThrow()).name, "foo")
        @Expect((collector.getMethod(info1, "hello").
        getOrThrow()).name, "getHello")
        @Expect((collector.getMethod(info1, "world").
        getOrThrow()).name, "isWorld")

        @Expect((collector.getMethod(info2, "foo").
        getOrThrow()).name, "foo")
        @Expect((collector.getMethod(info2, "hello").
        getOrThrow()).name, "getHello")
        @Expect((collector.getMethod(info2, "world").
        getOrThrow()).name, "isWorld")
        @ExpectThrows[NoneValueException](
            collector.getMethod(info1, "bar").
            getOrThrow()
        )
    }

    @TestCase
    public func VariableFetcher6Test() {
        let vaf1 = MethodVariableFetcher(collector.getMethod(info1, "foo").
        getOrThrow())
        @Expect((vaf1.get(testclass1, "foo").getOrThrow() as String).
        getOrThrow(), "foo")
        let vaf2 = MethodVariableFetcher(collector.getMethod(info1, "hello").
        getOrThrow())
        @Expect((vaf2.get(testclass1, "Hello").getOrThrow() as String).
        getOrThrow(), "Hello")

    }

    @TestCase
    public func VariableFetcher7Test() {
        let vaf1 = FieldVariableFetcher(collector.getField(info1, "str1").
        getOrThrow())
        let vaf2 = FieldVariableFetcher(collector.getField(info2, "str1").
        getOrThrow())
        @Expect((vaf1.get(testclass1, "str1").getOrThrow() as String).
        getOrThrow(), "foo")
        @Expect((vaf2.get(testclass2, "str1").getOrThrow() as String).
        getOrThrow(), "foo")
    }

    @TestCase
    public func createFetcherTest() {
        let mp = HashMap<String, Any>()
        let list = ArrayList<String>()
        let arr = Array<Any>()
        let iter = Array<String>().iterator()
        @Expect(refEq((collector.createFetcher((mp as Any).
        getOrThrow(), "").getOrThrow() as MapVariableFetcher).
        getOrThrow(), BasicCollector.MAP_FETCHER))
        @Expect(refEq((collector.createFetcher((list as Any).
        getOrThrow(), "0").getOrThrow() as ListVariableFetcher).
        getOrThrow(), BasicCollector.LIST_FETCHER))
        @Expect(refEq((collector.createFetcher((iter as Any).
        getOrThrow(), "0").getOrThrow() as IterVariableFetcher).
        getOrThrow(), BasicCollector.ITER_FETCHER))
        @Expect(refEq((collector.createFetcher((arr as Any).
        getOrThrow(), "0").getOrThrow() as GenericArrayHelpe<Any>).
        getOrThrow(), BasicCollector.OBJECT_ARRAY_HELPER))

        let vaf61 = collector.createFetcher(testclass1, "foo").
        getOrThrow()
        @Expect((vaf61.get(testclass1, "foo").getOrThrow() as String).
        getOrThrow(), "foo")
        let vaf62 = collector.createFetcher(testclass1, "hello").
        getOrThrow()
        @Expect((vaf62.get(testclass1, "Hello").getOrThrow() as String).
        getOrThrow(), "Hello")

        let vaf71 = collector.createFetcher(testclass1, "str1").
        getOrThrow()
        @Expect((vaf71.get(testclass1, "str1").getOrThrow() as String).
        getOrThrow(), "foo")
        let vaf72 = collector.createFetcher(testclass2, "str1").
        getOrThrow()
        @Expect((vaf72.get(testclass2, "str1").getOrThrow() as String).
        getOrThrow(), "foo")
    }

    @TestCase 
    public func createFetcherCache() {
        let mp = collector.createFetcherCache()
        @Expect(mp is HashMap<String, VariableFetcher>)
    }
}

open public class TestClass1 {
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

public class TestClass2 <: TestClass1 {
    public let str3 = "woo"
}