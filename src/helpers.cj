package cjmustache

import std.reflect.*
import std.io.*

public func appendOrWrite(
    sb: ?StringBuilder, 
    out: ?OutputStream, raw: String): Unit {
    if (let Some(extractedStringBuilder) <- sb) {
        extractedStringBuilder.append(raw)
    }
    if (let Some(extractedOutputStream) <- out) {
        extractedOutputStream.
        write(raw.toArray())
    }
}

public func appendOrWrite(
    sb: ?StringBuilder, 
    out: ?OutputStream, raw: String,
        start: Int64, end: Int64): Unit {
    if (let Some(extractedStringBuilder) <- sb) {
        extractedStringBuilder.
        append(raw[start..end])
    }
    if (let Some(extractedOutputStream) <- out) {
        extractedOutputStream.
        write(raw[start..end].toArray())
    }
}


// 简化调用
public func getDataType(any: Any): String { 
    return TypeInfo.of(any).name.
    split("<")[1].split(">")[0]
}

public func getCollctionType(any: Any): String {
    return TypeInfo.of(any).name.
    split("<")[0]
}

public func isSubType(type1: Any, type2: Any): Bool {
    return TypeInfo.of(type1).
    isSubtypeOf(TypeInfo.of(type2))
}

public func isSubType(type1: String, type2: Any): Bool {
    return TypeInfo.get(type1).
    isSubtypeOf(TypeInfo.of(type2))
}

public func isSubType(type1: Any, type2: String): Bool {
    return TypeInfo.of(type1).
    isSubtypeOf(TypeInfo.get(type2))
}

public func isSubType(type1: String, type2: String): Bool {
    return TypeInfo.get(type1).
    isSubtypeOf(TypeInfo.get(type2))
}


public func isNO_FETCHER_FOUND(data: Any): Bool {
    return  (data is String && 
            ((data as String).getOrThrow())
            .equalsIgnoreAsciiCase(
            (Template.NO_FETCHER_FOUND as String).
            getOrThrow()))
}