<div align="center">
<h1>cjmustache</h1>
</div>

<p align="center">
<img alt="" src="https://img.shields.io/badge/release-v0.1.0-brightgreen" style="display: inline-block;" />
<img alt="" src="https://img.shields.io/badge/cjc-v0.53.13-brightgreen" style="display: inline-block;" />
<!-- <img alt="" src="https://img.shields.io/badge/cjcov-0.0%25-brightgreen" style="display: inline-block;" /> -->
<!-- <img alt="" src="https://img.shields.io/badge/state-孵化/毕业-brightgreen" style="display: inline-block;" /> -->
<!-- <img alt="" src="https://img.shields.io/badge/domain-HOS/Cloud-brightgreen" style="display: inline-block;" /> -->
</p>

## <img alt="" src="./doc/readme-image/readme-icon-introduction.png" style="display: inline-block;" width=3%/> 1 介绍


### 1.1 项目特性

这是Mustache模板语言的cangjie实现 [Mustache template language](http://mustache.github.io/).
本项目迁移自 [jmustache](https://github.com/samskivert/jmustache) 

### 1.2 已知问题
  * `InputStream`和`OutputStram`暂未做文件流适配
  * cangjie暂时不支持`匿名类`写法，如需使用类来渲染，请在程序里显示地声明类.
  * cangjie的`反射机制`尚未健全，若使用类渲染，请确保你希望渲染的内容是被`public`修饰的且不为 `Nothing` 类型、`函数`类型、`元组`类型、`enum` 类型和带有`泛型`的 `struct` 类型，如果违背可能会出现无法渲染，异常，卡死等情况出现.
  * cangjie并不是所有对象都可以自动作为`key`值使用，所以请确保您给所用于渲染的内容的`key`为`String`类型.
  * 不知道为什么，通过cangjie`反射`获得的`非基本数据类型`的大部分cangjie对象似乎是`不健全`的，所以如果可以，当使用类来渲染时，请尽量让渲染内容是基本数据类型.目前类能适配的数据结构只有`ArrayList<T>`
  * 由于cangjie语言的机制，本项目的类型推断是基于逐一枚举判断的，所以为了避免出现类型无法匹配，在使用数据结构时，请尽量将渲染对象转为`Any`类型再进行渲染。目前枚举匹配的类型如下：`ArrayList<T>`, `Array<T>`, `HashMap<String, T>`, `Tuple(String, String)`.具体用法可看- [功能示例](#32-功能示例)


### 1.3 项目计划

逐渐适配[jmustache](https://github.com/samskivert/jmustache) 的类型推断。

## <img alt="" src="./doc/readme-image/readme-icon-framework.png" style="display: inline-block;" width=3%/> 2 架构

### 2.1 项目结构

```shell
.
├── README.md
├── cjpm.lock
├── cjpm.toml
├── CHANGELOG.md
├── LICENSE
├── doc
│   └── readme-image
│       ├── readme-icon-compile.png
│       ├── readme-icon-contribute.png
│       ├── readme-icon-framework.png
│       └── readme-icon-introduction.png
└── src
    ├── basic_collector.cj
    ├── default_collector.cj
    ├── escapers.cj
    ├── helpers.cj
    ├── mustache.cj
    ├── my_exception.cj
    ├── template.cj
    └── test
        ├── basic_collector_test.cj
        ├── compiler_test.cj
        ├── default_collector_test.cj
        ├── escapers_test.cj
        ├── helpers_test.cj
        ├── mustache_part_test.cj
        ├── mustache_test.cj
        ├── segment_test.cj
        ├── shared_test.cj
        ├── template_test.cj
        └── thread_safety_test.cj
```

### 2.2 接口说明
  * `compile(tmpl: String)`: 将输入的字符串编译成`Template`模版.
  * `execute(ctx: ?Any)`: 使用`ctx`来渲染编译成的`Template`模版.


## <img alt="" src="./doc/readme-image/readme-icon-compile.png" style="display: inline-block;" width=3%/> 3 使用说明

### 3.1 编译构建（Win/Linux/Mac）

```
cjpm update
cjpm build
cjpm test
```

### 3.2 功能示例

**Usage**


使用cjmustache非常简单。以`String`或`InputStream`的形式提供`Template`，并获取可以在任何上下文上执行的模板：

```
let text = "One, two, {{three}}. Three sir!"
let tmpl: Template = Mustache.compiler().compile(text)
let data = HashMap<String, String>()
data.put("three", "five")
println(tmpl.execute(data))
// result: "One, two, five. Three sir!"
```

使用 `InputStream` 和 `OutputStream` 如果你正在做一些更严肃的事情:

```
func executeTemplate (template: InputStream, out: OutputStream, data: HashMap<String, String>): Unit {
   Mustache.compiler().compile(template).execute(data, out)
}
```

执行上下文可以是大部分的cangjie对象。变量将通过以下机制解决：

  * 如果上下文是 `MustacheCustomContext`, 则将使用`MustacheCustomContext.get`.
  * 如果上下文是 `HashMap`, 则将使用`HashMap.get` .
  * 如果存在与变量同名的非空方法，则将调用该方法.
  * 如果存在一个名为 (对于变量 `foo`) `getFoo` 的非空方法,它将被调用.
  * 如果存在与变量同名的字段，则将使用其内容.

例子:

```
class Person {
    public final String name;
    public Person (String name, int age) {
        this.name = name;
        _age = age;
    }
    public int getAge () {
        return _age;
    }
    protected int _age;
}

class ObjectPerson {
    public let persons = ArrayList<Any>(Person("Elvis", 75), Person("Madonna", 52))
}

let tmpl = "{{#persons}}{{name}}: {{age}}\n{{/persons}}"
Mustache.compiler().compile(tmpl).execute(ObjectPerson())

// result:
// Elvis: 75
// Madonna: 52
```
如您所见，这里用来渲染的类使用了`ArrayList`对象，在实际处理中是通过了特殊处理途径的.
但是请注意，并不是所有的类型都得到了特殊处理.

节(Sections)的行为与您预期的一样:

 * `Boolean` 值启用或禁用节.
 * `Array`, `Iterator`, or `Iterable` 值重复执行节，每个元素用作每次迭代的上下文。空集合会导致模板中包含该部分的零个实例.
 * 无法解析或空值将被视为假,可以使用`strictSections()`来更改此行为. 有关详细信息，请参见默认值 _Default Values_.
 * 任何其他对象都将导致以该对象作为上下文对节执行一次.

具体示例请参见
[mustache_test.cangjie](https://gitcode.com/naxida/cjmustache/blob/main/src/test/mustache_test.cj)
中的代码,另请参阅
[Mustache documentation](http://mustache.github.io/mustache.5.html) 了解有关模板语法的详细信息

**Partials**


如果你想使用partials（例如`{{>subtmpl}}`），你必须在创建它时向编译器提供一个`Mustache.TemplateLoader`.例如:

```
public class TemplateLoader2 <: TemplateLoader {
    public TemplateLoader2(let str: String) {}

    public func getTemplate(_: String): InputStream {
        let byteArrayStream = ByteArrayStream()
        byteArrayStream.write(str.toArray())
        return BufferedInputStream(byteArrayStream)
    }
} 

Mustache.compiler().withLoader(TemplateLoader2("|\na\n\nb\n|\n")).
compile("\\\n\t{{>partial}}\n/\n").execute(HashMap<String, Any>())
```

**Lambdas**


cjmustache通过传递给你一个`Template.Fragment`实例来实现Lambda，你可以使用这个实例来执行传递给lambda的模板片段。

```
public class bold <: Lambda {
    public func execute(frag: Fragment, out: OutputStream): Unit {
        out.write("<b>".toArray())
        frag.execute(out)
        out.write("</b>".toArray())
    }
}

let tmpl = "{{#bold}}{{name}} is awesome.{{/bold}}"
let mp = HashMap<String, Any>()
mp.put("name", "Willy")
mp.put("bold", bold())
Mustache.compiler().compile(tmpl).execute(mp)
// result:
<b>Willy is awesome.</b>
```

对反编译（取消执行）模板和获取节中包含的原始Mustache模板文本的支持也很有限。有关限制的详细信息，请参阅 [Template.Fragment]

**Default Values**


默认情况下，当变量无法解析或解析为None时，将抛出异常（节除外，见下文）。您可以通过两种方式更改此行为。如果你想提供一个在所有这些情况下使用的值，请使用 `defaultValue()`:

```
let mp = HashMap<String, Any>()
mp.put("things", ArrayList<?Any>("bar", None, "bif"))
println(Mustache.compiler().defaultValue("!").
compile("{{#things}}{{.}}{{/things}}").
execute(mp))
// result:
bar!bif
```

如果你只希望为解析为null的变量提供一个默认值，并希望在变量无法解析的情况下保留异常，请使用`nullValue()`:

```
let mp = HashMap<String, ?Any>()
mp.put("nonnullvar", "bar")
mp.put("nullvar", None)
println(Mustache.compiler().nullValue("foo").
compile("{{nullvar}}{{nonnullvar}}").execute(mp))

// result:
foobar
```

当使用`HashMap`作为上下文时，`nullValue()`仅在`HashMap`包含到`None`的映射时使用。如果映射缺少给定变量的映射，那么它被认为是不可解析的，并引发异常。

```
let mp = HashMap<String, ?Any>()
mp.put("exists", "Say")
mp.put("nullValued", None)
// no mapping exists for "doesNotExist"
let tmpl = "{{exists}} {{nullValued}} {{doesNotExist}}?"
Mustache.compiler().nullValue("what").compile(tmpl).execute(mp)
// throws MustacheException when executing the template because doesNotExist cannot be resolved
```

**不要**在编译器配置中同时使用`defaultValue`和`nullValue`。每一个都覆盖另一个，所以你最后调用的那个就是你将得到的行为。但是即使你不小心做了正确的事情，你也有令人困惑的代码，所以不要同时调用两个，使用一个或另一个

**Sections**

节(Sections)不受`nullValue()`或`defaultValue()`设置的影响。它们的行为由一个单独的配置控制：`strictSections()`.


默认情况下，不可解析或解析为`None`的部分将被忽略（相反，不可解析或解析为`None`的反向部分将被包括在内）。如果使用`strictSections(true)`，则引用不可解析值的节将始终引发异常。引用可解析但为`None`的节永远不会抛出异常，无论`strictSections()`如何设置

**Extensions**

cjmustache扩展了基本的Mustache模板语言，增加了一些额外的功能。这些附加功能列举如下:

**默认情况下不转义HTML**


您可以在获取编译器时更改默认的HTML转义行为:

```
Mustache.compiler().escapeHTML(false).
compile("{{foo}}").execute(ObjectHTML())

// result: <bar>
// not: &lt;bar&gt;
```

**用户定义的对象格式**


默认情况下，cjmustache在呈现模板时将对象转换为字符串。您可以通过实现`Mustache.Formatter`来自定义此格式：

```
public class CustomFormatter <: Formatter {
    public func format(value: ?Any): String {
        if (let Some(extractedValue) <- value) {
            if (extractedValue is String) {
                return (extractedValue as String).getOrThrow() + "Customer"
            } else {
                return "unknown"
            }
        }
        return "unknown"
    }
}

let mp = HashMap<String, Any>()
mp.put("msg", Object())
mp.put("today", "My")
println(Mustache.compiler().withFormatter(CustomFormatter()).
compile("{{msg}}: {{today}}").execute(mp))

// result: 
unknown: MyCustomer
```

**用户定义的转义规则**


您可以在获取编译器时更改转义行为，以支持HTML和纯文本以外的文件格式.

如果你只需要替换文本中的固定字符串，你可以使用 `Escapers.simple`:

```
public class ObjectEscape {
    public let foo = "[bar]"
}
let escapes = [[ "[", "[[" ], [ "]", "]]" ]]
println(Mustache.compiler().withEscaper(Escapers.simple(escapes)).
compile("{{foo}}").execute(ObjectEscape()))

// result: [[bar]]
```
也可以直接实现`Mustache.Escaper`接口，以便对转义过程进行更多控制

**Special variables**


**this**

可以使用特殊变量`this`来引用上下文对象本身，而不是其成员之一。这在遍历列表时特别有用

```
Mustache.compiler().compile("{{this}}").execute("hello") // returns: hello
Mustache.compiler().compile("{{#names}}{{this}}{{/names}}").execute(ObjectList())
// result: TomDickHarry
```
请注意，您也可以使用特殊变量 `.` 意思是一样的

```
Mustache.compiler().compile("{{.}}").execute("hello")// returns: hello
Mustache.compiler().compile("{{#names}}{{.}}{{/names}}").execute(ObjectList())
// result: TomDickHarry
```

`.` 显然，其他Mustache实现也支持它，尽管它没有出现在官方文档中

**-first and -last**

可以使用特殊变量 `-first` 和 `-last` 对列表元素执行特殊处理。 `-first` 在处理元素列表的第一个元素的节中解析为 `true` .它在所有其他时间都解析为 `false` . `-last` 在处理元素列表中最后一个元素的节中解析为 `true` .它在所有其他时间都解析为 `false` 

人们经常会在倒排部分中使用这些特殊变量，如下所示:

```
let tmpl = "{{#things}}{{^-first}}, {{/-first}}{{this}}{{/things}}"
Mustache.compiler().compile(tmpl).execute(ObjectList1())
// result: one, two, three
```

请注意， `-first` 和 `-last` 的值仅引用最内部的封闭部分。如果您正在处理一个节中的一个节，则无法确定您是处于外部节的第一个迭代还是最后一个迭代中。

**-index**

`-index` 特殊变量包含1表示第一次迭代通过一个部分，2表示第二次，3表示第三次，依此类推。它在所有其他时间都包含0。请注意，对于由单例值而不是列表填充的部分，它也包含0。

```
let tmpl = "My favorite things:\n{{#things}}{{-index}}. {{this}}\n{{/things}}"
Mustache.compiler().compile(tmpl).execute(ObjectIndex())
// result:
// My favorite things:
// 1. Peanut butter
// 2. Pen spinning
// 3. Handstands
```

**Compound variables**

除了使用上下文解析简单变量外，还可以使用复合变量从当前上下文的子对象中提取数据。举例来说:

```
public class ObjectCompound1 {
    public func who(): String { 
        return "world" 
    }
}

public class ObjectCompound2 {
    public let field = ObjectCompound1()
}

Mustache.compiler().compile("Hello {{field.who}}!").execute(ObjectCompound2())
// result: Hello world!
```

请注意，复合变量本质上是使用单例节的简写。上述示例也可以表示为:

    Hello {{#field}}{{who}}{{/field}}!
    Hello {{#class}}{{name}}{{/class}}!

还请注意，嵌套的单例节和复合变量之间存在一个语义差异：在为复合变量的第一个组件解析对象之后，在解析子组件时将不会搜索父上下文

**Newline trimming**

如果开始或结束部分标记是一行中唯一的内容，则会修剪标记后面的所有空白和行结束符。这允许文明的模板，如:

```html
Favorite foods:
<ul>
  {{#people}}
  <li>{{first_name}} {{last_name}} likes {{favorite_food}}.</li>
  {{/people}}
</ul>
```

它产生的输出如下:

```html
Favorite foods:
<ul>
  <li>Elvis Presley likes peanut butter.</li>
  <li>Mahatma Gandhi likes aloo dum.</li>
</ul>
```

而不是:

```html
Favorite foods:
<ul>

  <li>Elvis Presley likes peanut butter.</li>

  <li>Mahatma Gandhi likes aloo dum.</li>

</ul>
```

其将在没有换行修剪的情况下产生.

**Nested Contexts**

如果在嵌套上下文中找不到变量，则在下一个外部上下文中解析该变量。这允许如下使用:

```java
let template = "{{outer}}:\n{{#inner}}{{outer}}.{{this}}\n{{/inner}}"
Mustache.compiler().compile(template).execute(ObjectContext())
// results:
// foo:
// foo.bar
// foo.baz
// foo.bif
```

请注意，如果一个变量是在内部上下文中定义的，它会隐藏外部上下文中的相同名称。目前还没有办法从外部上下文访问变量.

**Invertible Lambdas**

对于某些应用程序来说，对于反向部分执行DVDAs而不是完全省略该部分可能是有用的。这允许在静态地将模板转换为其他语言或上下文时进行适当的条件替换:

```
public class ObjectInvertibleLambda <: InvertibleLambda {
    public func execute (frag: Fragment, out: OutputStream): Unit {
        //当在普通节中引用lambda时，执行此方法
        out.write("if (condition) {console.log(\"".toArray())
        out.write(toJavaScriptLiteral(frag.execute()).toArray())
        out.write("\")}".toArray())
    }
    public func executeInverse (frag: Fragment, out: OutputStream) {
        //当在反段中引用lambda时，执行此方法
        out.write("if (!condition) {console.log(\"".toArray())
        out.write(toJavaScriptLiteral(frag.execute()).toArray())
        out.write("\")}".toArray())
    }
        private func toJavaScriptLiteral (execute: String): String {
        //注意：这不是JavaScript字符串文字转义的完整实现
        return execute.replace("\\\\", "\\\\\\\\").replace("\"", "\\\\\"")
    }
}

let template = "{{#condition}}result if true{{/condition}}\n" +
    "{{^condition}}result if false{{/condition}}"
let mp = HashMap<String, Any>()
mp.put("condition", ObjectInvertibleLambda())
println(Mustache.compiler().compile(template).execute(mp))

// results:
// if (condition) {console.log("result if true")}
// if (!condition) {console.log("result if false")}
```


**Standards Mode**

这些扩展中更具侵入性的扩展，特别是父上下文的搜索和复合变量的使用，可以在创建编译器时禁用，如下所示:

```
let ctx = HashMap<String, String>()
ctx.put("foo.bar", "baz")
Mustache.compiler().standardsMode(true).compile("{{foo.bar}}").execute(ctx)
// result: baz
```

**Thread Safety**

cjmustache是内部线程安全的，但有以下警告:

  * 编译：编译模板调用了各种帮助类：`Mustache.Formatter`, `Mustache.Escaper`, `Mustache.TemplateLoader`, `Mustache.Collector`.这些类的默认实现是线程安全的，但是如果您提供自定义实例，则必须确保自定义实例是线程安全的。

  * 执行：执行模板可以调用一些帮助类：`Mustache.Lambda`,`Mustache.VariableFetcher`。这些类的默认实现是线程安全的，但是如果您提供自定义实例，则必须确保自定义实例是线程安全的

  * 上下文数据：如果在执行模板时更改传递给模板执行的上下文数据，那么您就会受到竞争条件的影响。从理论上讲，可以为上下文数据使用线程安全的映射（`ConcurrentHashMap`），这将允许您在基于该数据呈现模板时改变数据，但这样做是在玩火。如果你的数据是以POJO的形式提供的，其中通过反射调用字段或方法来填充你的模板，

  *  `VariableFetcher`缓存：模板执行使用一个内部缓存来存储解析的 `VariableFetcher`实例（因为解析变量获取器的开销很大）。由于使用了 `ConcurrentHashMap`，该缓存是线程安全的。如果两个线程同时解析同一个变量，可能会做一些额外的工作，但它们不会相互冲突，它们只是都解析变量，而不是一个解析变量，另一个使用缓存的解析

因此，执行摘要是：只要您提供的所有帮助器类都是线程安全的（或者您使用默认值），那么在线程之间共享`Mustache.Compiler`实例来编译模板是安全的。如果在执行时将不可变数据传递给模板，那么让多个线程同时执行单个`Template`实例是安全的.

**Limitations**

为了简单起见，Mustache的一些功能被省略或简化了:

  * `{{= =}}` 只支持一个或两个字符分隔符。这只是因为我很懒，它简化了解析器.

[Template.Fragment]: http://samskivert.github.io/jmustache/apidocs/com/samskivert/mustache/Template.Fragment.html#decompile--


## <img alt="" src="./doc/readme-image/readme-icon-contribute.png" style="display: inline-block;" width=3%/> 4 参与贡献

本项目由 [SIGCANGJIE / 仓颉兴趣组](https://gitcode.com/SIGCANGJIE) 实现并维护。技术支持和意见反馈请提Issue。

本项目采用Apache Licnese 2.0，同时本项目迁移的原始项目 [jmustache](https://github.com/samskivert/jmustache)采用Eclipse Distribution License (EDL) v1.0协议。欢迎给我们提交PR，欢迎参与任何形式的贡献。

本项目committer：[@naxida-gitcode](https://gitcode.com/naxida/cjmustache.git)
