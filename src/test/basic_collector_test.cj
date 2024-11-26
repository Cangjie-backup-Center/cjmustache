package cjmustache.test

import cjmustache.*

import std.unittest.*
import std.unittest.testmacro.*
import std.io.*
import std.collection.*
import std.convert.*
import std.reflect.*

@Test
public class BasicCollectorTest {
    @TestCase
    public func ArrayHelper1Test() {
        let anyArr = (ArrayList<Any>(1, "Hello", [1, 2, 3]).
        toArray() as Any).getOrThrow()
        let arrHelper = GenericArrayHelpe<Any>()
        @Expect(arrHelper.length(anyArr), 3)
        @Expect((arrHelper.get(anyArr, 0).
        getOrThrow() as Int64).
        getOrThrow(), 1)
        @Expect((arrHelper.get(anyArr, 1).
        getOrThrow() as String).
        getOrThrow(), "Hello")
        @Expect((arrHelper.get(anyArr, 2).
        getOrThrow() as Array<Int64>).
        getOrThrow(), [1, 2, 3])
        @Expect((arrHelper.get(anyArr, 3).
        getOrThrow() as String).
        getOrThrow(), "<no fetcher found>")
    }
    @TestCase
    public func ArrayHelper2Test() {
        let anyArr = ([true, false] as Any)
        .getOrThrow()
        let arrHelper = GenericArrayHelpe<Bool>()
        @Expect(arrHelper.length(anyArr), 2)
        @Expect((arrHelper.get(anyArr, 0).
        getOrThrow() as Bool)
        .getOrThrow(), true)
        @Expect((arrHelper.get(anyArr, 1).
        getOrThrow() as Bool).
        getOrThrow(), false)
        @Expect((arrHelper.get(anyArr, 2).
        getOrThrow() as String).
        getOrThrow(), "<no fetcher found>")
    }

    @TestCase
    public func ArrayHelper3Test() {
        let anyArr = ([b'a', b'#'] as Any).
        getOrThrow()
        let arrHelper = GenericArrayHelpe<UInt8>()
        @Expect(arrHelper.length(anyArr), 2)
        @Expect((arrHelper.get(anyArr, 0).
        getOrThrow() as UInt8).
        getOrThrow(), b'a')
        @Expect((arrHelper.get(anyArr, 1).
        getOrThrow() as UInt8).
        getOrThrow(), b'#')
        @Expect((arrHelper.get(anyArr, 2).
        getOrThrow() as String).
        getOrThrow(), "<no fetcher found>")
    }

    @TestCase
    public func ArrayHelper4Test() {
        let anyArr = ([r'a', r'#'] as Any).
        getOrThrow()
        let arrHelper = GenericArrayHelpe<Rune>()
        @Expect(arrHelper.length(anyArr), 2)
        @Expect((arrHelper.get(anyArr, 0).
        getOrThrow() as Rune).
        getOrThrow(), r'a')
        @Expect((arrHelper.get(anyArr, 1).
        getOrThrow() as Rune).
        getOrThrow(), r'#')
        @Expect((arrHelper.get(anyArr, 2).
        getOrThrow() as String).
        getOrThrow(), "<no fetcher found>")
    }

    @TestCase
    public func ArrayHelper5Test() {
        let anyArr = ([1i16, 100i16] as Any).
        getOrThrow()
        let arrHelper = GenericArrayHelpe<Int16>()
        @Expect(arrHelper.length(anyArr), 2)
        @Expect((arrHelper.get(anyArr, 0).
        getOrThrow() as Int16).
        getOrThrow(), 1)
        @Expect((arrHelper.get(anyArr, 1).
        getOrThrow() as Int16).
        getOrThrow(), 100)
        @Expect((arrHelper.get(anyArr, 2).
        getOrThrow() as String).
        getOrThrow(), "<no fetcher found>")
    }

    @TestCase
    public func ArrayHelper6Test() {
        let anyArr = ([1, 100] as Any).
        getOrThrow()
        let arrHelper = GenericArrayHelpe<Int64>()
        @Expect(arrHelper.length(anyArr), 2)
        @Expect((arrHelper.get(anyArr, 0).
        getOrThrow() as Int64).
        getOrThrow(), 1)
        @Expect((arrHelper.get(anyArr, 1).
        getOrThrow() as Int64).
        getOrThrow(), 100)
        @Expect((arrHelper.get(anyArr, 2).
        getOrThrow() as String).
        getOrThrow(), "<no fetcher found>")
    }

    @TestCase
    public func ArrayHelper7Test() {
        let anyArr = ([1, 100] as Any).
        getOrThrow()
        let arrHelper = GenericArrayHelpe<Int64>()
        @Expect(arrHelper.length(anyArr), 2)
        @Expect((arrHelper.get(anyArr, 0).
        getOrThrow() as Int64).
        getOrThrow(), 1)
        @Expect((arrHelper.get(anyArr, 1).
        getOrThrow() as Int64).
        getOrThrow(), 100)
        @Expect((arrHelper.get(anyArr, 2).
        getOrThrow() as String).
        getOrThrow(), "<no fetcher found>")
    }

    @TestCase
    public func ArrayHelper8Test() {
        let anyArr = ([3.14f32, 100.0f32] as Any).
        getOrThrow()
        let arrHelper = GenericArrayHelpe<Float32>()
        @Expect(arrHelper.length(anyArr), 2)
        @Expect((arrHelper.get(anyArr, 0).
        getOrThrow() as Float32).
        getOrThrow(), 3.14f32)
        @Expect((arrHelper.get(anyArr, 1).
        getOrThrow() as Float32).
        getOrThrow(), 100.0f32)
        @Expect((arrHelper.get(anyArr, 2).
        getOrThrow() as String).
        getOrThrow(), "<no fetcher found>")
    }

    @TestCase
    public func ArrayHelper9Test() {
        let anyArr = ([3.14f64, 100.0f64] as Any).
        getOrThrow()
        let arrHelper = GenericArrayHelpe<Float64>()
        @Expect(arrHelper.length(anyArr), 2)
        @Expect((arrHelper.get(anyArr, 0).
        getOrThrow() as Float64).
        getOrThrow(), 3.14f64)
        @Expect((arrHelper.get(anyArr, 1).
        getOrThrow() as Float64).
        getOrThrow(), 100.0f64)
        @Expect((arrHelper.get(anyArr, 2).
        getOrThrow() as String).
        getOrThrow(), "<no fetcher found>")
    }

    @TestCase
    public func VariableFetcher3Test() {
        let mp = HashMap<String, Any>()
        mp.put("foo", ("bar" as Any).getOrThrow())
        mp.put("arr", ([1, 2, 3] as Any).getOrThrow())
        let anyMp = (mp as Any).getOrThrow()
        let fetcher = MapVariableFetcher()
        @Expect((fetcher.get(anyMp, "foo").
        getOrThrow() as String).
        getOrThrow(), "bar")
        @Expect((fetcher.get(anyMp, "arr").
        getOrThrow() as Array<Int64>).
        getOrThrow(), [1, 2, 3])
        @Expect(((fetcher.get(anyMp, "None").
        getOrThrow() as String).
        getOrThrow()).
        equalsIgnoreAsciiCase("<no fetcher found>"))
        @Expect(fetcher.toString().
        equalsIgnoreAsciiCase("MAP_FETCHER"))
    }

    @TestCase
    public func VariableFetcher4Test() {
        let arr1 = ArrayList<String>("foo", "bar")
        let anyArr1 = (arr1 as Any).getOrThrow()
        let fetcher = ListVariableFetcher()
        @Expect((fetcher.get(anyArr1, "0").
        getOrThrow() as String).
        getOrThrow(), "foo")
        @Expect((fetcher.get(anyArr1, "1").
        getOrThrow() as String).
        getOrThrow(), "bar")
        @Expect(((fetcher.get(anyArr1, "2").
        getOrThrow() as String).
        getOrThrow()).equalsIgnoreAsciiCase("<no fetcher found>"))


        let ctx1 = Context(
            None, None, 0, false, false)
        let ctx2 = Context(
            ctx1 as Any, None, 0, false ,false)
        let arr2 = ArrayList<Context>(
            Context(None, None, 0, false, false), 
        Context(ctx1 as Any, None, 0, false ,false))
        let anyArr2 = (arr2 as Any).getOrThrow()
        @Expect(refEq((fetcher.get(anyArr2, "0").
        getOrThrow() as Context).
        getOrThrow(), arr2[0]))
        @Expect(refEq((fetcher.get(anyArr2, "1").
        getOrThrow() as Context).
        getOrThrow(), arr2[1]))
        @Expect(fetcher.toString().
        equalsIgnoreAsciiCase("LIST_FETCHER"))
    }

    @TestCase
    public func VariableFetcher5Test() {
        let arr1 = ["foo", "bar", "tony", "tom", "aili"]
        let anyIter1 = (arr1.iterator() as Any).
        getOrThrow()
        let fetcher = IterVariableFetcher()
        @Expect((fetcher.get(anyIter1, "0").
        getOrThrow() as String).
        getOrThrow(), "foo")
        @Expect((fetcher.get(anyIter1, "2").
        getOrThrow() as String).
        getOrThrow(), "tom")
        @Expect(((fetcher.get(anyIter1, "6").
        getOrThrow() as String).
        getOrThrow()).
        equalsIgnoreAsciiCase("<no fetcher found>"))

        let ctx1 = Context(
            None, None, 0, false, false)
        let ctx2 = Context(
            ctx1 as Any, None, 0, false ,false)
        let arr2 = ArrayList<Context>(Context(
            None, None, 0, false, false), 
        Context(
            ctx1 as Any, None, 0, false ,false))
        let anyIter2 = (arr2.iterator() as Any).
        getOrThrow()
        @Expect(refEq((fetcher.get(anyIter2, "0").
        getOrThrow() as Context).
        getOrThrow(), arr2[0]))
        @Expect(refEq((fetcher.get(anyIter2, "0").
        getOrThrow() as Context).
        getOrThrow(), arr2[1]))
        @Expect(fetcher.toString().
        equalsIgnoreAsciiCase("ITER_FETCHER"))

    }

    @TestCase
    public func getArrayHelperTest() {
        @Expect(refEq(BasicCollector.getArrayHelper((Array<Any>() as Any).
        getOrThrow()).getOrThrow(), BasicCollector.OBJECT_ARRAY_HELPER))
        @Expect(refEq(BasicCollector.getArrayHelper((Array<Bool>() as Any).
        getOrThrow()).getOrThrow(), BasicCollector.BOOL_ARRAY_HELPER))
        @Expect(refEq(BasicCollector.getArrayHelper((Array<UInt8>() as Any).
        getOrThrow()).getOrThrow(), BasicCollector.BYTE_ARRAY_HELPER))
        @Expect(refEq(BasicCollector.getArrayHelper((Array<Rune>() as Any).
        getOrThrow()).getOrThrow(), BasicCollector.RUNE_ARRAY_HELPER))
        @Expect(refEq(BasicCollector.getArrayHelper((Array<Int16>() as Any).
        getOrThrow()).getOrThrow(), BasicCollector.INT16_ARRAY_HELPER))
        @Expect(refEq(BasicCollector.getArrayHelper((Array<Int32>() as Any).
        getOrThrow()).getOrThrow(), BasicCollector.INT32_ARRAY_HELPER))
        @Expect(refEq(BasicCollector.getArrayHelper((Array<Int64>() as Any).
        getOrThrow()).getOrThrow(), BasicCollector.INT64_ARRAY_HELPER))
        @Expect(refEq(BasicCollector.getArrayHelper((Array<Float32>() as Any).
        getOrThrow()).getOrThrow(), BasicCollector.FLOAT32_ARRAY_HELPER))
        @Expect(refEq(BasicCollector.getArrayHelper((Array<Float64>() as Any).
        getOrThrow()).getOrThrow(), BasicCollector.FLOAT64_ARRAY_HELPER))
        @ExpectThrows[NoneValueException](
            BasicCollector.getArrayHelper((Array<Context>() as Any).
            getOrThrow()).getOrThrow()
        )
    }

    @TestCase
    public func createFetcherTest() {
        let mp = HashMap<String, Any>()
        let list = ArrayList<String>()
        let arr = Array<Any>()
        let iter = Array<String>().iterator()
        let testBasicCollector = testBasicCollector()
        @Expect(refEq((testBasicCollector.createFetcher((mp as Any).
        getOrThrow(), "").getOrThrow() as MapVariableFetcher).
        getOrThrow(), BasicCollector.MAP_FETCHER))
        @Expect(refEq((testBasicCollector.createFetcher((list as Any).
        getOrThrow(), "0").getOrThrow() as ListVariableFetcher).
        getOrThrow(), BasicCollector.LIST_FETCHER))
        @Expect(refEq((testBasicCollector.createFetcher((iter as Any).
        getOrThrow(), "0").getOrThrow() as IterVariableFetcher).
        getOrThrow(), BasicCollector.ITER_FETCHER))
        @Expect(refEq((testBasicCollector.createFetcher((arr as Any).
        getOrThrow(), "0").getOrThrow() as GenericArrayHelpe<Any>).
        getOrThrow(), BasicCollector.OBJECT_ARRAY_HELPER))
    }

    @TestCase
    public func toIteratorTest() {
        let list = ArrayList<String>("foo", "bar")
        let listIter = BasicCollector.
        toIterator<String>((list as Any).
        getOrThrow()).getOrThrow()
        @Expect(listIter.next().getOrThrow(), "foo")

        let arr: Array<Int64> = [1, 100]
        let arrIter = BasicCollector.
        toIterator<Int64>((arr as Any).
        getOrThrow()).getOrThrow()
        @Expect(arrIter.next().getOrThrow(), 1)
    }
}

public class testBasicCollector <: BasicCollector {
    public override func createFetcherCache(): 
    HashMap<String, VariableFetcher> {
        return HashMap<String, VariableFetcher>()
    }
}

extend String {
    public func equalsIgnoreAsciiCase(str: String): Bool {
        return this == str
    }
}
