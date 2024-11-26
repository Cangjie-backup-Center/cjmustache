package cjmustache

import std.collection.*
import std.reflect.*

/**
  *  cjnustache使用的默认收集器。
  */
open public class DefaultCollector <: BasicCollector {
    public DefaultCollector(
        let _allowAccessCoercion!: Bool = true) { } 

    public override func createFetcher(
        ctx: Any, name: String): ?VariableFetcher {
        let fetcher: ?VariableFetcher = 
            super.createFetcher(ctx, name)
        if (fetcher.isSome()) { return fetcher }

        try {
            let cclass = 
                (TypeInfo.of(ctx) as ClassTypeInfo).
                    getOrThrow()

            if (let Some(methodInfo) <- 
                getMethod(cclass, name)) {
                return MethodVariableFetcher(methodInfo)
            }

            if (let Some(fieldInfo) <- 
                getField(cclass, name)) {
                return FieldVariableFetcher(fieldInfo)
            }

        } catch (ie: InfoNotFoundException) {
            if (name.equalsIgnoreAsciiCase("mapkey") ||
                name.equalsIgnoreAsciiCase("mapvalue")) {
                return TupleVariableFetcher()
            }
        } catch (e: NoneValueException) { // 无法转为ClassTypeInfo
            // fall
        }

        return None
    }

    public override func createFetcherCache(): 
        HashMap<String, VariableFetcher> {
        return HashMap<String, VariableFetcher>()
    }

    protected func getMethod(
        cclass: ClassTypeInfo, name: String): 
            ?InstanceFunctionInfo {
        if (_allowAccessCoercion) {
            var optionCclass: ?ClassTypeInfo = cclass
            while (optionCclass.isSome()) {
                let m = getMethodOn(
                    optionCclass.getOrThrow(), name)
                if (m.isSome()) { 
                    return m 
                }
                optionCclass = optionCclass.
                getOrThrow().superClass
            }
        } else {
            try {
                return cclass.getInstanceFunction(name)
            } catch (e: Exception) {
                // fall through
            }
        }

        return None
    }

    protected func getMethodOn(
        cclass: ClassTypeInfo, name: String): 
            ?InstanceFunctionInfo {
        var methodInfo: InstanceFunctionInfo
        try {
            methodInfo = cclass.getInstanceFunction(name)
            if (!methodInfo.returnType.
                isSubtypeOf(TypeInfo.get("Unit"))) {
                return methodInfo 
            }
        } catch (e: Exception) {
            // fall through
        }

        let upperName = (name.toRuneArray()[0].toString()).
                        toAsciiUpper() + name[1..]
        try {
            methodInfo = cclass.
                getInstanceFunction("get" + upperName)
            if (!methodInfo.returnType.
                isSubtypeOf(TypeInfo.get("Unit"))) { 
                return methodInfo 
            }
        } catch (e: Exception) {
            // fall through
        }

        try {
            methodInfo = cclass.
                getInstanceFunction("is" + upperName)
            if (methodInfo.returnType.
                isSubtypeOf(TypeInfo.get("Bool"))) { 
                return methodInfo 
            }
        } catch (e: Exception) {
            // fall through
        }
        
        return None
    }

    public func getField(
        cclass: ClassTypeInfo, name: String): 
            ?InstanceVariableInfo { 
        if (!_allowAccessCoercion) {
            try {
                return cclass.getInstanceVariable(name)
            } catch (e: Exception) {
                // fall through
            }
        }

        var fieldInfo: InstanceVariableInfo
        try {
            fieldInfo = cclass.getInstanceVariable(name)
            return fieldInfo
        } catch (e: Exception) {
            // fall through
        }

        let superclass = cclass.superClass
        if (superclass.isSome() && !superclass.getOrThrow().
            name.equalsIgnoreAsciiCase("Object")) {
                return getField(superclass.getOrThrow(), name)
        }

        return None
    }
}

public class MethodVariableFetcher <: VariableFetcher {
    public MethodVariableFetcher(
        let methodInfo: InstanceFunctionInfo) {}
    
    public func get(ctx: Any, _: String): ?Any {
        return methodInfo.apply(ctx)
    }
}

public class FieldVariableFetcher <: VariableFetcher {
    public FieldVariableFetcher(
        let fieldInfo: InstanceVariableInfo) {}

    public func get(ctx: Any, _: String): ?Any {
        var instance = ctx
        var classinfo = 
            (TypeInfo.of(ctx) as ClassTypeInfo).
            getOrThrow()
        var value: ?Any = None
        
        while (true) {
            try {
                value = fieldInfo.getValue(instance) // 成功在当前类拿到字段
                break
            } catch (ite: IllegalTypeException) { // 没能在当前类找到字段，向父类查找
                if (let Some(superClassInfo) <-  
                    classinfo.superClass) {
                    classinfo = superClassInfo
                    let constructorInfo = 
                        superClassInfo.constructors.toArray()[0]
                    let paramInfos = constructorInfo.parameters
                    instance = constructorInfo.apply(
                        Array<Any>(paramInfos.size, repeat: Object()))
                    continue
                } else {
                    break
                }
            } catch (e: Exception) {
                break
            }
        }
        
        if (let Some(extractedValue) <- value) {
            if (extractedValue is Option<Any>) {
                return (extractedValue as Option<Any>).getOrThrow()
            }
            return extractedValue
        }
        
        return None
    }
}

public class TupleVariableFetcher <: VariableFetcher {
    public TupleVariableFetcher() {}

    public func get(ctx: Any, name: String): ?Any {
        if (let Some(tuple) <- (ctx as (String, String))) {
            if (name.equalsIgnoreAsciiCase("mapkey")) {
                return tuple[0]
            }
            if (name.equalsIgnoreAsciiCase("mapvalue")) {
                return tuple[1]
            }
        } 
        return None
        
    }
}


