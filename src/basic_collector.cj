package cjmustache

import std.reflect.*
import std.collection.*
import std.convert.*

/* 负责在不使用 cangjie 反射的情况下收集和解析数据。
 * 该类主要用于将模板中的变量（例如迭代器、数组等）转换为可迭代的对象或用于模板渲染的数据片段 */
public abstract class BasicCollector <: Collector {
        /* 该方法用于将不同的数据类型（如 Iterable、Iterator、数组等）转换为 Iterator */
    public static func toIterator<T>(
            value: Any): ?Iterator<T> {
        let valueType = TypeInfo.of(value)
        var dataType: String = ""

        try {
            dataType = getDataType(value)
            if (dataType.
                equalsIgnoreAsciiCase("Option")) {
                dataType = "Option<Any>"
            } else if (dataType.
                equalsIgnoreAsciiCase("Tuple")) {
                dataType = "Tuple<String, String>"
            }
        } catch (e: Exception) {
            return Option<Iterator<T>>.None
        }

        try {
            let IterableType = TypeInfo.
                get("Iterable<${dataType}>")
            if (valueType.isSubtypeOf(IterableType)) {
                try {
                    return (value as ArrayList<T>).getOrThrow().iterator()
                } catch (e: Exception) {
                    // fall
                }
                return (value as Iterable<T>).getOrThrow().iterator()
            }
        } catch (e: Exception) {
            // fall
        }

        try {
            let IteratorType = TypeInfo.
                get("Iterator<${dataType}>")
            if (valueType.isSubtypeOf(IteratorType)) {
                return (value as Iterator<T>).getOrThrow()
            }
        } catch (e: Exception) {
            // fall
        }

        try {
            let ArrayType = TypeInfo.
                get("Array<${dataType}>")
            if (valueType.isSubtypeOf(ArrayType)) {
                return ArrayHelperIterator<T>(
                    getArrayHelper(value)
                        .getOrThrow() , value)
            }
        } catch (e: Exception) {
            // fall
        }

        return Option<Iterator<T>>.None
    }

    public open func createFetcher(
        ctx: Any, name: String): ?VariableFetcher {
        if (ctx is CustomContext) {
            return CUSTOM_FETCHER
        }
        
        let ctxType: TypeInfo
        let ctxTypeStr: String
        let ctxDataType: String

        try {
            ctxType = TypeInfo.of(ctx)
            ctxTypeStr = getCollctionType(ctx)
            ctxDataType = getDataType(ctx)
        }  catch (ie: InfoNotFoundException) {
            if (name.equalsIgnoreAsciiCase("mapkey") ||
                name.equalsIgnoreAsciiCase("mapvalue")) {
                return TupleVariableFetcher()
            }
            return None
        } catch (ie: IndexOutOfBoundsException) {
            return None
        }

        if (ctxTypeStr == "HashMap" || 
            ctxTypeStr == "Map") { 
            return MAP_FETCHER
        }

        let IteratorTypeInfo = TypeInfo.
            get("Iterator<${ctxDataType}>")
        let ArrayTypeInfo = TypeInfo.
            get("Array<${ctxDataType}>")

        /* 如果名称看起来像一个数字，可以使用我们的“索引”获取器之一 */
        let c = name.toRuneArray()[0]
        if (c >= r'0' && c <= r'9') {
            if (ctxTypeStr.
                equalsIgnoreAsciiCase("ArrayList")) { 
                return LIST_FETCHER
            }
            if (ctxType.isSubtypeOf(IteratorTypeInfo)) { 
                return ITER_FETCHER 
            }
            if (ctxType.isSubtypeOf(ArrayTypeInfo)) {
                if (let Some(arrayHelper) <-
                    getArrayHelper(ctx)) {
                    return (arrayHelper as VariableFetcher).
                    getOrThrow()
                }
            }
        }
        return None
    }

    /** 这应该返回一个线程安全的映射，要么在标准的{@link map}实现上调用
      * {@link Collections#synchronizedMap}，要么类似于{@code ConcurrentHashMap}
      */
    public func createFetcherCache(): HashMap<String, VariableFetcher>
    
    protected static func getArrayHelper(ctx: Any): ?ArrayHelper {
        var ctxType = TypeInfo.of(ctx)
        if (ctxType.isSubtypeOf(TypeInfo.get("Array<Any>"))) 
        { return OBJECT_ARRAY_HELPER }
        if (ctxType.isSubtypeOf(TypeInfo.of(Array<Bool>()))) 
        { return BOOL_ARRAY_HELPER }
        if (ctxType.isSubtypeOf(TypeInfo.of(Array<UInt8>()))) 
        { return BYTE_ARRAY_HELPER }
        if (ctxType.isSubtypeOf(TypeInfo.get("Array<Rune>"))) 
        { return RUNE_ARRAY_HELPER }
        if (ctxType.isSubtypeOf(TypeInfo.of(Array<Int16>()))) 
        { return INT16_ARRAY_HELPER }
        if (ctxType.isSubtypeOf(TypeInfo.of(Array<Int32>()))) 
        { return INT32_ARRAY_HELPER }
        if (ctxType.isSubtypeOf(TypeInfo.get("Array<Int64>"))) 
        { return INT64_ARRAY_HELPER }
        if (ctxType.isSubtypeOf(TypeInfo.get("Array<Float32>"))) 
        { return FLOAT32_ARRAY_HELPER }
        if (ctxType.isSubtypeOf(TypeInfo.get("Array<Float64>"))) 
        { return FLOAT64_ARRAY_HELPER }
        if (ctxType.isSubtypeOf(TypeInfo.of(Array<(String, String)>()))) 
        { return TUPLE_ARRAY_HELPER }
        return Option<ArrayHelper>.None
    }

     /* 用于自定义上下文（Mustache.CustomContext），调用其 get() 方法获取变量值。 */
    protected static let CUSTOM_FETCHER = CustomVariableFetcher()

    /* 于 Map 类型的上下文，调用 Map.get() 获取变量值，或者允许迭代 entrySet。 */
    protected static let MAP_FETCHER = MapVariableFetcher()

    /* 用于 List 类型的上下文，根据索引获取列表中的元素 */
    protected static let LIST_FETCHER = ListVariableFetcher()

    /* 用于 Iterator，通过索引获取迭代器中的下一个元素 */
    protected static let ITER_FETCHER = IterVariableFetcher()

    /* 于 Map 类型的上下文，调用 Map.get() 获取变量值，或者允许迭代 entrySet。 */

    protected static let OBJECT_ARRAY_HELPER = GenericArrayHelpe<Any>()
    protected static let BOOL_ARRAY_HELPER = GenericArrayHelpe<Bool>()
    protected static let BYTE_ARRAY_HELPER = GenericArrayHelpe<UInt8>()
    protected static let RUNE_ARRAY_HELPER = GenericArrayHelpe<Rune>()
    protected static let INT16_ARRAY_HELPER = GenericArrayHelpe<Int16>()
    protected static let INT32_ARRAY_HELPER = GenericArrayHelpe<Int64>()
    protected static let INT64_ARRAY_HELPER = GenericArrayHelpe<Int64>()
    protected static let FLOAT32_ARRAY_HELPER = GenericArrayHelpe<Float32>()
    protected static let FLOAT64_ARRAY_HELPER = GenericArrayHelpe<Float64>()
    protected static let TUPLE_ARRAY_HELPER = GenericArrayHelpe<(String, String)>()
}

protected class ArrayHelperIterator<T> <: Iterator<T> {
    private let helper: ArrayHelper
    private let value: Any
    private let _count: Int64
    private var _idx: Int64

    public init(helper: ArrayHelper, value: Any) {
        this.helper = helper
        this.value = value
        _count = this.helper.length(this.value)
        _idx = 0
    }

    public func hasNext(): Bool { 
        return _idx < _count
    }

    public override func next(): ?T {
        if (let Some(fetchedValue) <- 
            helper.get(value, _idx)) {
            if (isNO_FETCHER_FOUND(fetchedValue)) {
                return None
            }
            _idx = _idx + 1
            return (fetchedValue as T).getOrThrow()
        } else {
            return None
        }
    }

    public func remove(): Unit {
        throw UnsupportedException()
    }
}

protected abstract class ArrayHelper <: VariableFetcher {
    public func get(ctx: Any, name: String): ?Any {
        try {
            if (let Some(value) <-
                get(ctx, Int64.parse(name))) {
                return value
            } 
            return Template.NO_FETCHER_FOUND
        } catch (nfe: IllegalFormatException) {
            return Template.NO_FETCHER_FOUND
        } catch (e: IndexOutOfBoundsException) {
            return Template.NO_FETCHER_FOUND
        }
    }

    public func length(ctx: Any): Int64
    protected func get(ctx: Any, index: Int64): ?Any
}

protected class GenericArrayHelpe<T> <: ArrayHelper {
    protected override func get(
            ctx: Any, index: Int64): ?Any {
        if  (let Some(value) <- 
            (ctx as Array<T>).getOrThrow().get(index)) {
                return value as Any
        } else {
            return Template.NO_FETCHER_FOUND
        }
    }

    public override func length(ctx: Any): Int64 {
        return (ctx as Array<T>).getOrThrow().size
    }
}


protected class CustomVariableFetcher <: VariableFetcher {
    public func get(ctx: Any, name: String): ?Any {
        if (let Some(value) <- 
            (ctx as CustomContext).
                getOrThrow().get(name)) {
                return value
        }
        return Template.NO_FETCHER_FOUND
    }

    public func toString(): String {
        return "CUSTOM_FETCHER"
    }
}

protected class MapVariableFetcher <: VariableFetcher {
    public func get(ctx: Any, name: String): ?Any {
        try {
            let ctxType = getDataType(ctx)
            if (ctxType == "String, String") {
                let mp = (ctx as HashMap<String, String>).
                    getOrThrow()
                if (let Some(value) <- mp.get(name)) {
                    return value
                }
                if ("entrySet".equalsIgnoreAsciiCase(name)) {
                    return mp.toArray()
                }
            } else if (ctxType == "String, Any") {
                let mp = (ctx as HashMap<String, Any>).
                    getOrThrow()
                if (let Some(value) <- mp.get(name)) {
                    return value
                }
                if ("entrySet".equalsIgnoreAsciiCase(name)) {
                    return mp.toArray()
                }
            } else if (ctxType == "String, Option") {
                let mp = (ctx as HashMap<String, ?Any>).
                    getOrThrow()
                if (let Some(value) <- mp.get(name)) {
                    if (value.isNone()) {
                        return None
                    }
                    return value
                }
                if ("entrySet".equalsIgnoreAsciiCase(name)) {
                    return mp.toArray()
                }
            }
        } catch (e: Exception) {
            return Template.NO_FETCHER_FOUND
        }
        return Template.NO_FETCHER_FOUND
    }

    public func toString(): String {
        return "MAP_FETCHER"
    }
}

protected class ListVariableFetcher <: VariableFetcher {
    public func get(ctx: Any, name: String): ?Any {
        try {
            let datatype = getDataType(ctx)
            let index = Int64.parse(name)
            if (datatype.equalsIgnoreAsciiCase("String")) {
                if (let Some(value) <- 
                    (ctx as ArrayList<String>).
                        getOrThrow().get(index)) {
                    return (value as Any).getOrThrow()
                }
            } else if (datatype.equalsIgnoreAsciiCase(
                        "cjmustache.Context")) {
                if (let Some(value) <- 
                    (ctx as ArrayList<Context>).
                        getOrThrow().get(index)) {
                    return (value as Any).getOrThrow()
                }
            } else if (datatype.equalsIgnoreAsciiCase("Int64")) {
                if (let Some(value) <- 
                    (ctx as ArrayList<Int64>).
                        getOrThrow().get(index)) {
                    return (value as Any).getOrThrow()
                }
            } else if (datatype.equalsIgnoreAsciiCase("Option")) {
                if (let Some(value) <-
                    (ctx as ArrayList<?Any>).
                        getOrThrow().get(index)) {
                    return (value as Any).getOrThrow()
                }
            } else {
                if (let Some(value) <- 
                    (ctx as ArrayList<Any>).
                        getOrThrow().get(index)) {
                    return value
                }
            }
        } catch(e: Exception) {
            // fall
        }

        return Template.NO_FETCHER_FOUND
    }

    public func toString(): String {
        return "LIST_FETCHER"
    }
}

protected class IterVariableFetcher <: VariableFetcher {
    public func get(ctx: Any, name: String): ?Any {
        try {
            let datatype = getDataType(ctx)
            if (datatype.equalsIgnoreAsciiCase("String")) {
                if (let Some(value) <- 
                    retHelper((ctx as Iterator<String>).
                        getOrThrow(), name)) {
                            return (value as Any).getOrThrow()
                }
            } else if (datatype.equalsIgnoreAsciiCase(
                    "cjmustache.Context")) {
                if (let Some(value) <- 
                    retHelper((ctx as Iterator<Context>).
                        getOrThrow(), name)) {
                            return (value as Any).getOrThrow()
                }
            } else if (datatype.equalsIgnoreAsciiCase(
                    "cjmustache.Context")) {
                if (let Some(value) <- 
                    retHelper((ctx as Iterator<?Any>).
                        getOrThrow(), name)) {
                            return value
                }
            } else {
                if (let Some(value) <- 
                    retHelper((ctx as Iterator<Any>).
                        getOrThrow(), name)) {
                            return value
                }
            }
        } catch(e: Exception) {
            // fall
        }

        return Template.NO_FETCHER_FOUND
    }

    private func retHelper<T>(
            iter: Iterator<T>, name: String): ?Any {
        for (_ in 0..Int64.parse(name)) { 
            iter.next() 
        }
        
        if (let Some(value) <- iter.next()) {
            return value
        }
        
        return Template.NO_FETCHER_FOUND
    }

    public func toString(): String {
        return "ITER_FETCHER"
    }
}

