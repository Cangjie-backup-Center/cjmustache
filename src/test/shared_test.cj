package cjmustache.test

import cjmustache.*

import std.unittest.*
import std.unittest.testmacro.*
import std.io.*
import std.collection.*
import std.convert.*
import std.reflect.*
import std.fs.*

@Test
public class SharedTest {
    protected var name: String = ""
    protected var partials = HashMap<String, String>()

    @TestCase
    public func simpleVariableTest() {
        @Expect(test("bar", "{{foo}}", context("foo", "bar")))
    }

    @TestCase
    public func testPrimitiveArrayVariable () {  // NoneValueException
        @Expect(test("1234", "{{#foo}}{{this}}{{/foo}}", context("foo", [1, 2, 3, 4])))
    }

    @TestCase
    public func testPrimitiveArrayIndexVariable() {
        @Expect(test("1", "{{foo.0}}", context("foo", [1, 2, 3, 4])))
    }

    @TestCase
    public func testPrimitiveArrayIndexOutOfBoundsVariable() {
        let comp = Mustache.compiler().defaultValue("?");
        @Expect(test(comp, "?", "{{foo.4}}", context("foo", [1, 2, 3, 4])))
    }

    @TestCase 
    public func testOneShotSection() { 
        @Expect(test("baz", "{{#foo}}{{bar}}{{/foo}}", context("foo", context("bar", "baz"))))
    }

    @TestCase 
    public func testListSection () {
        @Expect(test("bazbif", "{{#foo}}{{bar}}{{/foo}}", context(
                "foo", ArrayList<Any>(context("bar", "baz"), context("bar", "bif")))))
    }

    @TestCase 
    public func testListIndexSection() { 
        @Expect(test("baz", "{{#foo.0}}{{bar}}{{/foo.0}}", context(
            "foo", ArrayList<Any>(context("bar", "baz"), context("bar", "bif")))))
    }

    @TestCase 
    public func testListIndexOutOfBoundsSection (){
        @Expect(test("", "{{#foo.2}}{{bar}}{{/foo.2}}", context(
            "foo", ArrayList<Any>(context("bar", "baz"), context("bar", "bif")))))
    }

    @TestCase 
    public func testListItemSection () {
        @Expect(test("baz", "{{foo.0.bar}}", context(
            "foo", ArrayList<Any>(context("bar", "baz"), context("bar", "bif")))))
    }

    @TestCase
    public func testMapEntriesSection () {
        let data = HashMap<String, String>()
        data.put("k1", "v1");
        data.put("k2", "v2");
        @Expect(test(Mustache.compiler().escapeHTML(false),
            "k1=v1k2=v2", "{{#map.entrySet}}{{.}}{{/map.entrySet}}",
            context("map", data)))
    }

    @TestCase 
    public func testArraySection() {
        @Expect(test("bazbif", "{{#foo}}{{bar}}{{/foo}}",
            context("foo", ArrayList<Any>(context("bar", "baz"), context("bar", "bif")))))
    }

    @TestCase 
    public func testArrayIndexSection() {
        @Expect(test("baz", "{{#foo.0}}{{bar}}{{/foo.0}}",
            context("foo", ArrayList<Any>(
                context("bar", "baz"), context("bar", "bif")))))
    }

    @TestCase
    public func testArrayIndexOutOfBoundsSection() {
        @Expect(test("", "{{#foo.2}}{{bar}}{{/foo.2}}",
            context("foo", ArrayList<Any>(
                    context("bar", "baz"), context("bar", "bif")))))
    }

    @TestCase
    public func testIteratorIndexSection() {
        @Expect(test("baz", "{{#foo.0}}{{bar}}{{/foo.0}}",
            context("foo", ArrayList<Any>(context("bar", "baz"),
                context("bar", "bif")).iterator())))
    }

    @TestCase 
    public func testIteratorSection() {
        @Expect(test("bazbif", "{{#foo}}{{bar}}{{/foo}}",
            context("foo", ArrayList<Any>(
                context("bar", "baz"), context("bar", "bif")).iterator())))
    }

    @TestCase 
    public func testIteratorIndexOutOfBoundsSection() {
        @Expect(test("", "{{#foo.2}}{{bar}}{{/foo.2}}",
            context("foo", ArrayList<Any>(
                context("bar", "baz"), context("bar", "bif")).iterator())))
    }

    @TestCase 
    public func testEmptyListSection() {
        @Expect(test("", "{{#foo}}{{bar}}{{/foo}}", context("foo", ArrayList<Any>())))
    }

    @TestCase
    public func testEmptyArraySection() {
        @Expect(test("", "{{#foo}}{{bar}}{{/foo}}", context("foo", Array<Any>())))
    }

    @TestCase
    public func testEmptyIteratorSection() {
        @Expect(test("", "{{#foo}}{{bar}}{{/foo}}", context("foo", ArrayList<Any>().iterator())))
    }

    @TestCase
    public func testFalseSection() {
        @Expect(test("", "{{#foo}}{{bar}}{{/foo}}", context("foo", false)))
    }

    @TestCase 
    public func testNestedListSection() {
        @Expect(test("1234", "{{#a}}{{#b}}{{c}}{{/b}}{{#d}}{{e}}{{/d}}{{/a}}",
            context("a", context("b", [context("c", "1"), context("c", "2")]),
                                "d",[context("e", "3"), context("e", "4")])))
    }

    @TestCase 
    public func testNullSection() {
        var ctx = context("foo", None)
        @Expect(test("", "{{#foo}}{{bar}}{{/foo}}", ctx))
        @Expect(test(Mustache.compiler().defaultValue(""), "", "{{#foo}}{{bar}}{{/foo}}", ctx))
        @Expect(test(Mustache.compiler().nullValue(""), "", "{{#foo}}{{bar}}{{/foo}}", ctx))
    }

    @TestCase
    public func testMissingNonStrictSection() {
        // no foo; section omitted due to non-strict-sections
        @Expect(test("", "{{#foo}}{{bar}}{{/foo}}", EMPTY))
        // no foo; no exception because nullValue does change section strictness
        @Expect(test(Mustache.compiler().nullValue(""), "", "{{#foo}}{{bar}}{{/foo}}", EMPTY))
        // no foo; no exception because defaultValue does change section strictness
        @Expect(test(Mustache.compiler().defaultValue(""), "", "{{#foo}}{{bar}}{{/foo}}", EMPTY))
    }

    @TestCase 
    public func testMissingStrictSection() {  // 不能准确抛出需要的错误
        try {
            @Expect(test(Mustache.compiler().strictSections(true), "", "{{#foo}}{{bar}}{{/foo}}",
                 EMPTY)) // no foo; should throw exception due to strict-sections
            @Assert(false)
        } catch (me: Exception) {} // expected
    }

    @TestCase 
    public func testMissingStrictSectionDefaultValue() {
        try {
            // missing strict-sections always throw regardless of defaultValue()
            @Expect(test(Mustache.compiler().strictSections(true).defaultValue(""), "",
                "{{#foo}}{{bar}}{{/foo}}", EMPTY))
            @Assert(false)
        } catch (me: Exception) {} // expected
    }

    @TestCase
    public func testSectionWithFalseyEmptyString() {
        var ctx = context("foo", "", "bar", "nonempty")
        // test normal sections with falsey empty string
        var compiler = Mustache.compiler().emptyStringIsFalse(true)
        @Expect(test(compiler, "",     "{{#foo}}test{{/foo}}", ctx))
        @Expect(test(compiler, "test", "{{#bar}}test{{/bar}}", ctx))
        // test inverted sections with falsey empty string
        @Expect(test(compiler, "test", "{{^foo}}test{{/foo}}", ctx))
        @Expect(test(compiler, "",     "{{^bar}}test{{/bar}}", ctx))
    }

    @TestCase
    public func testComment() {
        @Expect(test("foobar", "foo{{! nothing to see here}}bar", EMPTY))
    }

    @TestCase 
    public func testCommentWithFunnyChars(){
        @Expect(test("foobar", "foo{{! {baz\n }}bar", EMPTY))
    }

    @TestCase
    public func testPartialUseWhenUnconfigured() { 
        try {
            test(None, "{{>foo}}", None)
            @Assert(false)
        } catch (me: Exception) {} // expected
    }

    protected func fpartials(entries: Array<(String, String)>): TemplateLoader {
        let templates = HashMap<String, String>()
        for (e in entries) {
            templates.put(e[0], e[1])
        }
        partials = templates
        return TemplateLoader1(templates)
    }

    @TestCase 
    public func testPartial() {
        @Expect(test(Mustache.compiler().withLoader(
                fpartials(("foo", "inside:{{bar}}"), ("baz", "nonfoo")))
                , "foo inside:foo nonfoo foo", "{{bar}} {{>foo}} {{>baz}} {{bar}}", context("bar", "foo")))
    }

    @TestCase
    public func testPartialIndent() {
        @Expect(test(Mustache.compiler().withLoader(TemplateLoader2("|\n{{{content}}}\n|\n"))
        , "\\\n |\n <\n->\n |\n/\n", "\\\n {{>partial}}\n/\n", context("content", "<\n->")))
    }

    @TestCase
    public func testPartialBlankLines() {
        @Expect(test(Mustache.compiler().withLoader(TemplateLoader2("|\na\n\nb\n|\n"))
        , "\\\n\t|\n\ta\n\t\n\tb\n\t|\n/\n", "\\\n\t{{>partial}}\n/\n", context()))
    }

    @TestCase
    public func testNestedPartialBlankLines() {
        @Expect(test(Mustache.compiler().withLoader(TemplateLoader3("1\n\t{{>nest}}\n1\n", "2\na\n\nb\n2\n" ))
        , "\\\n\t1\n\t\t2\n\t\ta\n\t\t\n\t\tb\n\t\t2\n\t1\n/\n", "\\\n\t{{>partial}}\n/\n", context()))
    }

    @TestCase 
    public func testNestedPartialBlankLinesCRLF() {
        @Expect(test(Mustache.compiler().withLoader(TemplateLoader3("1\r\n\t{{>nest}}\r\n1\r\n", "2\r\na\r\n\r\nb\r\n2\r\n"))
        , "\\\r\n\t1\r\n\t\t2\r\n\t\ta\r\n\t\t\r\n\t\tb\r\n\t\t2\r\n\t1\r\n/\r\n", "\\\r\n\t{{>partial}}\r\n/\r\n", context()))
    }

    @TestCase
    public func testNestedPartialIndent() {
        let loader = fpartials(("partial", "1\n {{>nest}}\n1\n"), ("nest", "2\n{{{content}}}\n2\n"))
        @Expect(test(Mustache.compiler().withLoader(loader),
                "|\n 1\n  2\n  <\n->\n  2\n 1\n|\n",
                "|\n {{>partial}}\n|\n", context("content", "<\n->")))
    }

    @TestCase
    public func testPartialIndentWithVariableAtTheStart() {
        @Expect(test(Mustache.compiler().withLoader(TemplateLoader2("{{{content}}}\n|\n"))
        , "\\\n <\n->\n |\n/\n", "\\\n {{>partial}}\n/\n", context("content", "<\n->")))
    }

    @TestCase
    public func testPartialIndentWithBlock() {
        @Expect(test(Mustache.compiler().withLoader(TemplateLoader2("|\n{{#show}}\n{{{content}}}{{/show}}\n|\n"))
        , "\\\n |\n <\n->\n |\n/\n", "\\\n {{>partial}}\n/\n", context("show", true, "content", "<\n->")))
    }

    @TestCase public func testPartialIndentInBlock() {
        @Expect(test(Mustache.compiler().withLoader(TemplateLoader2("content"))
        , " content", "{{#show}}\n {{>partial}}\n{{/show}}\n", context("show", true)))
    }

    @TestCase
    public func testPartialIndentWithBlockAtStart() {
        @Expect(test(Mustache.compiler().withLoader(TemplateLoader2("{{#show}}\n{{{content}}}{{/show}}\n|\n"))
        , "\\\n <\n->\n |\n/\n", "\\\n {{>partial}}\n/\n", context("show", true, "content", "<\n->")))
    }

    @TestCase 
    public func testPartialIndentWithInlineBlock() {
        @Expect(test(Mustache.compiler().withLoader(TemplateLoader2("line {{#show}}content{{/show}}\n"))
        , "\\\n line content\n/\n", "\\\n {{>partial}}\n/\n", context("show", true)))
    }

    @TestCase 
    public func testPartialPlusNestedContext() {
        @Expect(test(Mustache.compiler().withLoader(TemplateLoader4("{{name}}{{thing_name}}", "nonfoo"))
        , "foo((foobar)(foobaz))", "{{name}}({{#things}}({{>nested}}){{/things}})",
            context("name", "foo",
                    "things", ArrayList<Any>(context("thing_name", "bar"),
                                            context("thing_name", "baz")))))
    }

    @TestCase 
    public func testRecursivePartial() {
        let template = "[{{name}}{{#properties}}, {{> schema.mustache}}{{/properties}}]";
        @Expect(test(Mustache.compiler().withLoader(TemplateLoader2(template))
        , "[level0, [level1a, [level2a]], [level1b, [level2b]]]", template,
            context("name", "level0",
                    "properties", ArrayList<Any>(
            context("name", "level1a",
                    // test with empty list as recursive terminator
                    "properties", context("name", "level2a", "properties", ArrayList<Any>())),
            context("name", "level1b",
                    // test with null as recursive terminator
                    "properties", context("name", "level2b", "properties", None))
        ))))
    }

    @TestCase 
    public func testDelimiterChange() {
        @Expect(test("foo bar baz", "{{one}} {{=<% %>=}}<%two%><%={{ }}=%> {{three}}",
            context("one", "foo", "two", "bar", "three", "baz")))
        @Expect(test("baz bar foo", "{{three}} {{=% %=}}%two%%={{ }}=% {{one}}",
            context("one", "foo", "two", "bar", "three", "baz")))
    }


    @TestCase
    public func testUnescapeHTML() {
        @Expect(check("<b>", Mustache.compiler().escapeHTML(true).compile("{{&a}}").
            execute(context("a", "<b>"))))
        @Expect(check("<b>", Mustache.compiler().escapeHTML(true).compile("{{{a}}}").
            execute(context("a", "<b>"))))
        // make sure these also work when escape HTML is off
        @Expect(check("<b>", Mustache.compiler().escapeHTML(false).compile("{{&a}}").
            execute(context("a", "<b>"))))
        @Expect(check("<b>", Mustache.compiler().escapeHTML(false).compile("{{{a}}}").
            execute(context("a", "<b>"))))
    }

    @TestCase 
    public func testStrayTagCharacters() {
        @Expect(test("funny [b] business {{", "funny {{a}} business {{", context("a", "[b]")))
        @Expect(test("funny <b> business {{", "funny {{{a}}} business {{", context("a", "<b>")))
        @Expect(test("{{ funny [b] business", "{{ funny {{a}} business", context("a", "[b]")))
        @Expect(test("{{ funny <b> business", "{{ funny {{{a}}} business", context("a", "<b>")))
        @Expect(test("funny [b] business }}", "funny {{a}} business }}", context("a", "[b]")))
        @Expect(test("funny <b> business }}", "funny {{{a}}} business }}", context("a", "<b>")))
        @Expect(test("}} funny [b] business", "}} funny {{a}} business", context("a", "[b]")))
        @Expect(test("}} funny <b> business", "}} funny {{{a}}} business", context("a", "<b>")))
    }

    @TestCase 
    public func testInvalidUnescapeHTML() {
        try {
            Mustache.compiler().escapeHTML(true).compile("{{{a}}").execute(context("a", "<b>"))
            @Assert(false)
        } catch (me: Exception) {} // expected
    }

    @TestCase 
    public func testEscapeHTML () {
        @Expect(check("&lt;b&gt;", Mustache.compiler().compile("{{a}}").execute(context("a", "<b>"))))
        @Expect(check("<b>", Mustache.compiler().escapeHTML(false).compile("{{a}}").
            execute(context("a", "<b>"))))
        // ensure that some potential XSS enablers are escaped
        @Expect(check("&#x60;&#x3D;", Mustache.compiler().compile("{{a}}").execute(context("a", "`="))))
    }

    @TestCase 
    public func testUserDefinedEscaping(){
        let escaper = Escapers.simple([
            [ "[", ":BEGIN:" ],
            [ "]", ":END:" ]
        ])
        @Expect(check(":BEGIN:b:END:", Mustache.compiler().withEscaper(escaper).
            compile("{{a}}").execute(context("a", "[b]"))))
    }

    @TestCase 
    public func testPartialDelimiterMatch() {
        @Expect(check("{bob}", Mustache.compiler().compile("{bob}").execute(EMPTY)))
        @Expect(check("bar", Mustache.compiler().compile("{{bob}bob}}").execute(context("bob}bob", "bar"))))
    }

    @TestCase
    public func testDanglingTag() {
        @Expect(test("foo{", "foo{", context("a", "<b>")))
        @Expect(test("foo{{", "foo{{", context("a", "<b>")))
        @Expect(test("foo{{a", "foo{{a", context("a", "<b>")))
        @Expect(test("foo{{a}", "foo{{a}", context("a", "<b>")))
    }

    @TestCase 
    public func testTopLevelThis() {
        @Expect(check("bar", Mustache.compiler().compile("{{this}}").execute("bar")))
        @Expect(check("bar", Mustache.compiler().compile("{{.}}").execute("bar")))
    }

    @TestCase 
    public func testNestedThis() {
        @Expect(check("barbazbif", Mustache.compiler().compile("{{#things}}{{this}}{{/things}}").
            execute(context("things", ArrayList<Any>("bar", "baz", "bif")))))
        @Expect(check("barbazbif", Mustache.compiler().compile("{{#things}}{{.}}{{/things}}").
            execute(context("things", ArrayList<Any>("bar", "baz", "bif")))))
    }

    @TestCase 
    public func testNestedNullThis() {
        @Expect(check("bar!bif", Mustache.compiler().defaultValue("!").
            compile("{{#things}}{{.}}{{/things}}").
            execute(context("things", ArrayList<?Any>("bar", None, "bif")))))
    }

    @TestCase 
    public func testNewlineSkipping() {
        testNewlineSkipping("\n")
    }

    @TestCase 
    public func testNewlineSkippingCRLF() {
        testNewlineSkipping("\r\n")
    }

    @TestCase 
    public func testNewlineSkippingDelimsTag() {
        @Expect(test("Begin.\nEnd.\n", "Begin.\n{{=@ @=}}\nEnd.\n", EMPTY))
    }

    @TestCase 
    public func testNoTrimNewlineFromNestedTagAt0() {
        @Expect(test(" | \n  | \n", " | {{^boolean}}{{! comment }}\n {{/boolean}} | \n",
            context("boolean", false)))
    }

    @TestCase
    public func testTrimBlank() {
        let str = StringSegment("  \r\n  ", false)
        @Expect(check("Text(  )-1/0", str.trimLeadBlank().toString()))
        @Expect(check("Text(  \\r\\n)3/-1", str.trimTrailBlank().toString()))
    }

    @TestCase 
    public func testVisit(){
        let template = "{{#one}}1{{/one}} {{^two}}2{{three}}{{/two}}{{four}}"
        let viz = GetKeysVisitor()
        Mustache.compiler().compile(template).visit(viz)
        @Expect(viz.keys.size, 4)
        @Expect(viz.keys.contains("one"))
        @Expect(viz.keys.contains("two"))
        @Expect(viz.keys.contains("three"))
        @Expect(viz.keys.contains("four"))
    }

    @TestCase 
    public func testVisitNested() {
        let template = "{{#one}}1{{/one}} {{^two}}" +
            "2{{two_and_half}}{{#five}}{{three}}{{/five}}" +
            "{{/two}} {{#one}}{{three}}{{/one}} {{four}}{{! ignore me }}"
        let viz = GetKeysVisitor()
        Mustache.compiler().compile(template).visit(viz)
        @Expect(viz.keys.size, 6)
        @Expect(viz.keys.contains("one"))
        @Expect(viz.keys.contains("two"))
        @Expect(viz.keys.contains("three"))
        @Expect(viz.keys.contains("four"))
        @Expect(viz.keys.contains("two_and_half"))
        @Expect(viz.keys.contains("five"))
    }

    protected func testNewlineSkipping (sep: String) {
        let tmpl = "list:" + sep +
            "{{#items}}" + sep +
            "{{this}}" + sep +
            "{{/items}}" + sep +
            "{{^items}}" + sep +
            "no items" + sep +
            "{{/items}}" + sep +
            "endlist"
        @Expect(test("list:" + sep +
            "one" + sep +
            "two" + sep +
            "three" + sep +
            "endlist", tmpl, context("items",  ArrayList<Any>("one", "two", "three"))))
        @Expect(test("list:" + sep +
            "no items" + sep +
            "endlist", tmpl, context("items",  ArrayList<Any>())))

        // this tests newline trimming even if the group tags have leading/trailing whitespace
        let htmlTmpl =
            "<ul>" + sep +
            "  {{#items}}  " + sep +
            "  <li>{{this}}</li>" + sep +
            "  {{/items}}  " + sep +
            "  {{^items}}" + sep +
            "  <li>no items</li>" + sep +
            "  {{/items}}" + sep +
            "</ul>"
        @Expect(test("<ul>" + sep +
            "  <li>one</li>" + sep +
            "  <li>two</li>" + sep +
            "  <li>three</li>" + sep +
            "</ul>", htmlTmpl, context("items", ArrayList<Any>("one", "two", "three"))))
        @Expect(test("<ul>" + sep +
            "  <li>no items</li>" + sep +
            "</ul>", htmlTmpl, context("items",  ArrayList<Any>())))
    }

    @TestCase
    public func testNewlineNonSkipping () {
        // only when a section tag is by itself on a line should we absorb the newline following it
        let tmpl = "thing?: {{#thing}}yes{{/thing}}{{^thing}}no{{/thing}}\n" +
            "that's nice";
        @Expect(test("thing?: yes\n" +
            "that's nice", tmpl, context("thing", true)))
        @Expect(test("thing?: no\n" +
            "that's nice", tmpl, context("thing", false)))
    }

    @TestCase
    public func testNestedContexts () {
        @Expect(test("foo((foobar)(foobaz))", "{{name}}({{#things}}({{name}}{{thing_name}}){{/things}})",
            context("name", "foo",
                    "things", ArrayList<Any>(context("thing_name", "bar"),
                                        context("thing_name", "baz")))))
    }

    @TestCase 
    public func testShadowedContext() {
        @Expect(test("foo((bar)(baz))", "{{name}}({{#things}}({{name}}){{/things}})",
            context("name", "foo",
                    "things", ArrayList<Any>(context("name", "bar"), context("name", "baz")))))
    }

    @TestCase 
    public func testFirst() {
        @Expect(test("foo|bar|baz", "{{#things}}{{^-first}}|{{/-first}}{{this}}{{/things}}",
            context("things", ArrayList<Any>("foo", "bar", "baz"))))
    }

    @TestCase 
    public func testLast() {
        @Expect(test("foo|bar|baz", "{{#things}}{{this}}{{^-last}}|{{/-last}}{{/things}}",
            context("things", ArrayList<Any>("foo", "bar", "baz"))))
    }

    @TestCase 
    public func testFirstLast() { 
        @Expect(test("[foo]", "{{#things}}{{#-first}}[{{/-first}}{{this}}{{#-last}}]{{/-last}}{{/things}}",
            context("things", ArrayList<Any>("foo"))))
        @Expect(test("foo", "{{#things}}{{this}}{{^-last}}|{{/-last}}{{/things}}",
            context("things", ArrayList<Any>("foo"))))
    }

    @TestCase 
    public func testFirstLastCombo() {
        @Expect(test("FIRST_and_LAST", "{{#things}}{{#-first}}FIRST{{/-first}}{{this}}{{#-last}}LAST{{/-last}}{{/things}}",
            context("things", ArrayList<Any>("_and_"))))
    }

    @TestCase 
    public func testInverseFirstLastCombo() {  
        @Expect(test("_and_", "{{#things}}{{^-first}}NOT-FIRST{{/-first}}{{this}}{{^-last}}NOT-LAST{{/-last}}{{/things}}",
            context("things", ArrayList<Any>("_and_"))))
    }

    @TestCase 
    public func testNotFirst() { 
        @Expect(test("1,2,3", "{{#things}}{{^-first}},{{/-first}}{{this}}{{/things}}",
            context("things", ArrayList<Any>("1", "2", "3"))))
    }

    @TestCase 
    public func testNotLast() {
        @Expect(test("1,2,3", "{{#things}}{{this}}{{^-last}},{{/-last}}{{/things}}",
            context("things", ArrayList<Any>("1", "2", "3"))))
    }

    @TestCase 
    public func testIndex() {
        @Expect(test("123", "{{#things}}{{-index}}{{/things}}",
            context("things", ArrayList<Any>("foo", "bar", "baz"))))
    }

    @TestCase 
    public func testNestedIndex() {
        let tmpl =
            "{{#fooList}}\n" +
            "{{#quantity}}|q{{-index}}={{quantity}}{{/quantity}}|{{name}}\n" +
            "{{/fooList}}"
        @Expect(test("|q1=1|a\n|b\n", tmpl,
            context("fooList", ArrayList<Any>(context("name", "a", "quantity", 1),
                                            context("name", "b")))))
    }

    @TestCase 
    public func testLineReporting() {  
        let tmpl = "first line\n{{nonexistent}}\nsecond line"
        try {
            Mustache.compiler().compile(tmpl).execute(EMPTY)
            fail("Referencing a nonexistent variable should throw MustacheException")
        } catch (me: MustacheException) {
            @Expect(me.message.contains("line 2"))
        }
    }

    @TestCase 
    public func testStandardsModeWithNullValuesInLoop() {
        @Expect(test("first line\nsecond line",
            "first line\n{{#nullvalue}}foo\n{{/nullvalue}}\nsecond line",
            context("nullvalue", None)))
    }

    @TestCase 
    public func testStandardsModeWithNullValuesInInverseLoop () {
        @Expect(test("first line\nfoo \nsecond line",
            "first line\n{{^nullvalue}}foo{{/nullvalue}} \nsecond line",
            context("nullvalue", None)))
    }

    @TestCase 
    public func testStandardsModeWithDotValue() {
        let tmpl = "{{#foo}}:{{.}}:{{/foo}}"
        let mp = HashMap<String, String>()
        mp.put("foo", "bar")
        let result = Mustache.compiler().standardsMode(true).compile(tmpl).
            execute(mp as Any)
        @Expect(check(":bar:", result))
    }

    @TestCase 
    public func testStandardsModeWithNoParentContextSearching() {
        try {
            let tmpl = "{{#parent}}foo{{parentProperty}}bar{{/parent}}"
            let result = Mustache.compiler().standardsMode(true).compile(tmpl).
                execute(context("parent", EMPTY,
                                "parentProperty", "bar"))
            @Expect(false)
        } catch (me: Exception) {} // expected
    }

    @TestCase 
    public func testMissingValue() {
        try {
            test("n/a", "{{missing}} {{notmissing}}", context("notmissing", "bar"))
            @Expect(false)
        } catch (me: Exception) {} // expected
    }

    @TestCase 
    public func testMissingValueWithDefault() {
        @Expect(test(Mustache.compiler().defaultValue(""),
            "bar", "{{missing}}{{notmissing}}", context("notmissing", "bar")))
    }

    @TestCase 
    public func testMissingValueWithDefaultNonEmptyString() {
        @Expect(test(Mustache.compiler().defaultValue("foo"),
            "foobar", "{{missing}}{{notmissing}}", context("notmissing", "bar")))
    }

    @TestCase 
    public func testMissingValueWithDefaultSubstitution() {
        @Expect(test(Mustache.compiler().defaultValue("?{{name}}?"),
            "?missing?bar", "{{missing}}{{notmissing}}", context("notmissing", "bar")))
    }

    @TestCase
    public func testMissingValueWithDefaultSubstitution2() {
        @Expect(test(Mustache.compiler().defaultValue("{{{{name}}}}"),
            "{{missing}}bar", "{{missing}}{{notmissing}}", context("notmissing", "bar")))
    }

    @TestCase
    public func testMissingValueWithDefaultSubstitution3() {
        @Expect(test(Mustache.compiler().defaultValue("{{?{{name}}?}}"),
            "{{?missing?}}bar", "{{missing}}{{notmissing}}", context("notmissing", "bar")))
    }

    @TestCase
    public func testNullValueGetsDefault() {
        @Expect(test(Mustache.compiler().defaultValue("foo"),
            "foobar", "{{nullvar}}{{nonnullvar}}", context("nonnullvar", "bar", "nullvar", None)))
    }

    @TestCase
    public func testMissingValueWithNullDefault () {
        try {
            let ctx = context("notmissing", "bar");
            // no field or method for 'missing'
            test(Mustache.compiler().nullValue(""), "bar", "{{missing}}{{notmissing}}", ctx)
            @Expect(false)
        } catch (me: Exception) {} // expected
    }

    @TestCase 
    public func testInvalidTripleMustache() {
        try {
            Mustache.compiler().compile("{{{foo}}")
            fail("Expected MustacheParseException")
        } catch (me: MustacheException) {
            @Expect(check("Invalid triple-mustache tag: {{{foo}} @ line 1", me.message))
        }
        try {
            Mustache.compiler().compile("{{{foo}}]")
            fail("Expected MustacheParseException")
        } catch (me: MustacheException) {
            @Expect(check("Invalid triple-mustache tag: {{{foo}}] @ line 1", me.message))
        }
    }

    @TestCase 
    public func testNullValueGetsNullDefault() {
        @Expect(test(Mustache.compiler().nullValue("foo"),
            "foobar", "{{nullvar}}{{nonnullvar}}", context("nonnullvar", "bar", "nullvar", None)))
    }

    @TestCase 
    public func testCompilingDoesntChangeCompilersDelimiters() {
        let compiler = Mustache.compiler();
        let ctx = context("variable", "value")
        @Expect(test(compiler, "value", "{{=<% %>=}}<% variable %>", ctx))
        @Expect(test(compiler, "value", "{{=<% %>=}}<% variable %>", ctx))
    }

    @TestCase 
    public func testLambda1 () {
        @Expect(test("<b>Willy is awesome.</b>", "{{#bold}}{{name}} is awesome.{{/bold}}",
            context("name", "Willy", "bold", Lambda1("b"))))
    }

    @TestCase 
    public func testLambda2() {
        @Expect(test("Slug bug potato!", "{{#l}}1{{/l}} {{#l}}2{{/l}} {{#l}}{{three}}{{/l}}",
            context("three", "3", "l", Lambda2())))
    }

    @TestCase 
    public func testInvertibleLambda () {
        @Expect(test("positive = positive, negative = negative, simple lambdas do still work",
            "{{#invertible}}positive{{/invertible}}, {{^invertible}}negative{{/invertible}}, " +
            "simple lambdas do {{^simple}}NOT {{/simple}}still work",
            context("invertible", InvertibleLambda1(), "simple", Lambda3())))
    }

    @TestCase 
    public func testLambdaWithContext() {
        @Expect(test("a in l1, a in l2", "{{#l1}}{{a}}{{/l1}}, {{#l2}}{{a}}{{/l2}}", context(
                "l1", Lambda4([("a" as Any).getOrThrow(), ("a in l1" as Any).getOrThrow()]),
                "l2", Lambda4([("a" as Any).getOrThrow(), ("a in l2" as Any).getOrThrow()]))))
    }

    @TestCase
    public func testLambdaDecompile() {
        @Expect(test("Foo {{a}}, Bar {{a}}", "{{#lam}}Foo {{a}}{{/lam}}, {{#lam}}Bar {{a}}{{/lam}}",
            context("lam", Lambda5())))
        // whitespace inside tags is dropped!
        @Expect(test("Foo {{a}}, Bar {{a}}", "{{#lam}}Foo {{a}}{{/lam}}, {{#lam}}Bar {{ a }}{{/lam}}",
            context("lam", Lambda5())))
        // custom delimiters are ignored!
        @Expect(test("Foo {{a}}, Bar {{a}}",
            "{{#lam}}Foo {{a}}{{/lam}}, {{=(( ))=}}((#lam))Bar ((a))((/lam))",
            context("lam", Lambda5())))
        // coalesced whitespace around section tags is preserved
        @Expect(test("{{#section}}\n" +
            "{{a}}\n" +
            "{{/section}}",
            "{{#lam}}{{#section}}\n" +
            "{{a}}\n" +
            "{{/section}}{{/lam}}",
            context("lam", Lambda5())))
    }

    @TestCase 
    public func testLambdaFragExecTemplate() {
        let a = Mustache.compiler().compile("{{value}} should be A");
        let b = Mustache.compiler().compile("{{value}} should be B");
        let lambda = Lambda6(a, b)
        let tmpl = "[{{#lam}}{{value}}{{/lam}}]";
        @Expect(test("[A should be A]", tmpl, context("lam", lambda, "value", "A")))
        @Expect(test("[B should be B]", tmpl, context("lam", lambda, "value", "B")))
    }

    @TestCase 
    public func testNonStandardDefaultDelims() {
        @Expect(test(Mustache.compiler().withDelims("<% %>"), "bar", "<%foo%>", context("foo", "bar")))
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
        return showWhitespace(expected.getOrThrow()).equalsIgnoreAsciiCase(showWhitespace(output))
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
                ctx.put((data[ii].getOrThrow() as String).getOrThrow(), None)
            } else {
                ctx.put((data[ii].getOrThrow() as String).getOrThrow(), (data[ii + 1].getOrThrow() as Any).getOrThrow())
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

public class TemplateLoader1 <: TemplateLoader {
    public TemplateLoader1(let mp: HashMap<String, String>) {}

    public func getTemplate(name: String): InputStream {
        let byteArrayStream = ByteArrayStream()
        if (let Some(value) <- mp.get(name)) {
            byteArrayStream.write(value.toArray())
            return BufferedInputStream(byteArrayStream)
        }
        return BufferedInputStream(byteArrayStream)
    }
}

public class TemplateLoader2 <: TemplateLoader {
    public TemplateLoader2(let str: String) {}

    public func getTemplate(_: String): InputStream {
        let byteArrayStream = ByteArrayStream()
        byteArrayStream.write(str.toArray())
        return BufferedInputStream(byteArrayStream)
    }
} 

public class TemplateLoader3 <: TemplateLoader {
    public TemplateLoader3(let str1: String, let str2: String) {}

    public func getTemplate(name: String): InputStream {
        let byteArrayStream = ByteArrayStream()
        if (name.equalsIgnoreAsciiCase("partial")) {
            byteArrayStream.write(str1.toArray())
            return BufferedInputStream(byteArrayStream)
        }
        byteArrayStream.write(str2.toArray())
        return BufferedInputStream(byteArrayStream)
    }
} 

public class TemplateLoader4 <: TemplateLoader {
    public TemplateLoader4(let str1: String, let str2: String) {}

    public func getTemplate(name: String): InputStream {
        let byteArrayStream = ByteArrayStream()
        if (name.equalsIgnoreAsciiCase("nested")) {
            byteArrayStream.write(str1.toArray())
            return BufferedInputStream(byteArrayStream)
        }
        byteArrayStream.write(str2.toArray())
        return BufferedInputStream(byteArrayStream)
    }
}

// public class TemplateLoader5 <: TemplateLoader {
//     public TemplateLoader5(let str: String) {}

//     public func getTemplate(name: String): InputStream {
//         var file: File = File(Path(str), OpenOption.Create(false))
//         return file
//     }
// } 

public class GetKeysVisitor <: Visitor {
    public let keys = HashSet<String>()
    public func visitText (_: String): Unit {}
    public func visitVariable (name: String): Unit { keys.put(name) }
    public func visitInclude (name: String): Bool { 
        keys.put(name)
        return true
    }
    public func visitSection (name: String): Bool {
        keys.put(name)
        return true
    }
    public func visitInvertedSection (name: String): Bool { 
        keys.put(name) 
        return true 
    }
}


public class Lambda1 <: Lambda {
    public Lambda1(let str: String) { }

    public func execute(frag: Fragment, out: OutputStream): Unit {
        out.write(("<" + str + ">").toArray())
        frag.execute(out)
        out.write(("</" + str + ">").toArray())
    }
}

public class Lambda2 <: Lambda {
    public Lambda2() { }

    public func execute(frag: Fragment, out: OutputStream): Unit {
        out.write(lookup(frag.execute()).toArray())
    }

    protected func lookup(contents: String): String {
        if (contents.equalsIgnoreAsciiCase("1")) { return "Slug" }
        else if (contents.equalsIgnoreAsciiCase("2")) { return "bug" }
        else if (contents.equalsIgnoreAsciiCase("3")) { return "potato!" }
        return "Who was that man?"
    }
}

public class Lambda3 <: Lambda {
    public Lambda3() { }

    public func execute(frag: Fragment, out: OutputStream): Unit {
        frag.execute(out)
    }
}

public class Lambda4 <: Lambda {
    public Lambda4(let ctx: Array<?Any>) { }

    public func execute(frag: Fragment, out: OutputStream): Unit {
        frag.execute(SharedTest.context(ctx), out)
    }
}

public class Lambda5 <: Lambda {
    public Lambda5() { }

    public func execute(frag: Fragment, out: OutputStream): Unit {
        out.write(frag.decomplie().toArray())
    }
}

public class Lambda6 <: Lambda {
    public Lambda6(let a: Template, let b: Template) { }

    public func execute(frag: Fragment, out: OutputStream): Unit {
        let which = frag.execute()
        if (which.equalsIgnoreAsciiCase("A")) {
            frag.executeTemplate(a, out)
        } else if (which.equalsIgnoreAsciiCase("B")) {
            frag.executeTemplate(b, out)
        } else {
            throw AssertException()
        }
    }
}

public class InvertibleLambda1 <: InvertibleLambda {
    public func execute(frag: Fragment, out: OutputStream): Unit {
        out.write("positive = ".toArray())
        frag.execute(out)
    }

    public func executeInverse(frag: Fragment, out: OutputStream): Unit {
        out.write("negative = ".toArray())
        frag.execute(out)
    }
}
