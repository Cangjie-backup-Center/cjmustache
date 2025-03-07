package cjmustache.test

import cjmustache.*

import std.unittest.*
import std.unittest.testmacro.*
import std.io.*
import std.collection.*
import std.convert.*
import std.reflect.*


@Test 
public class StringSegmentTest {

    @TestCase
    public func SegmentEqaulTest() {
        let Segment1 = TestSegment1()
        let Segment2 = TestSegment1()
        let Segment3 = TestSegment1()
        let Segment4 = TestSegment1()
        let Segment5 = TestSegment1()
        let arrSegs1 = [Segment1, Segment2, 
        Segment3, Segment4, Segment5]
        let arrSegs2 = [Segment1, Segment2, 
        Segment3, Segment4, Segment5]
        let arrSegs3 = arrSegs2
        @Expect(arrSegs1.equal(arrSegs2))
        @Expect(arrSegs1.equal(arrSegs3))
        @Expect(arrSegs2.equal(arrSegs3))
    }

    @TestCase
    public func SectionSegmentTest() {
        let arrInt = [0, 1, 2, 3, 4 ,5]
        let iter = arrInt.iterator()
        var index: Int64 = 0
        let arr = ArrayList<Int64>()
        while (let Some(elem) <- iter.next()) {
            arr.add(elem)
        }
        var count = arr.size
        for (elem in arr) {
            count--
            let onFirst: Bool = (index == 0)
            let onLast: Bool = !(count != 0)
            if (index == 0) {
                @Expect(elem, 0)
                @Expect(onFirst)
            } else { @Expect(!onFirst) }
            index++
            if (count == 0) {
                @Expect(elem, 5)
                @Expect(onLast)
            } else { @Expect(!onLast) }
            if (elem == 0) { @Expect(index, 1) }
            else if (elem == 1) { @Expect(index, 2) }
            else if (elem == 2) { @Expect(index, 3) }
            else if (elem == 3) { @Expect(index, 4) }
            else if (elem == 4) { @Expect(index, 5) }
            else if (elem == 5) { @Expect(index, 6) }
        }
    }
}

protected class TestSegment1 <: Segment {
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

extend<T> Array<T> where T <: Segment {
    public func equal(segs: Array<T>): Bool {
        let size1 = this.size
        let size2 = segs.size
        if (size1 != size2) { return false }
        for (i in 0..size1) {
            if (!refEq(this[i], segs[i])) {
                return false
            }
        }
        return true
    }

    public func _toString(): String {
        let stringBuilder = StringBuilder()
        stringBuilder.append("[")
        for (i in 0..this.size) {
            stringBuilder.append(this[i].toString())
            if (i != this.size - 1) {
                stringBuilder.append(", ")
            }
        }
        stringBuilder.append("]")
        return stringBuilder.toString()
    }
}