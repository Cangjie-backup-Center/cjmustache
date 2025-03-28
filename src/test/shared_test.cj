package cjmustache.test

import cjmustache.*

import serialization.serialization.*
import std.unittest.*
import std.unittest.testmacro.*
import std.io.*
import std.collection.*
import std.convert.*
import std.fs.*

type L_I = ArrayList<Int64>
type L_S = ArrayList<String>
type A_I = Array<Int64>

type M_SS = HashMap<String, String>
type M_SOS = HashMap<String, ?String>
type M_SL_I = HashMap<String, ArrayList<Int>>
type M_SL_S = HashMap<String, ArrayList<String>>
type M_SA_I = HashMap<String, Array<Int>>
type M_SM_SS = HashMap<String, HashMap<String, String>>

type L_M_SS = ArrayList<HashMap<String, String>>
type A_M_SS = Array<HashMap<String, String>>

type M_SL_M_SS = HashMap<String, ArrayList<HashMap<String, String>>>
type M_SA_M_SS = HashMap<String, Array<HashMap<String, String>>>
type M_SM_SA_M_SS  = HashMap<String, HashMap<String, Array<HashMap<String, String>>>>

type M_SB = HashMap<String, Bool>

@Test
public class SharedTest {
    protected var name: String = ""
    protected var partials = M_SS()
    private let EMPTY = M_SS().serialize()

    @TestCase
    public func simpleVariableTest() {
        @Expect(test("bar", "{{foo}}", 
            M_SS([("foo", "bar")]).serialize()))
    }

    @TestCase
    public func testPrimitiveArrayVariable () {  // NoneValueException
        @Expect(test("1234", "{{#foo}}{{this}}{{/foo}}",
            M_SL_I([("foo", L_I([1, 2, 3, 4]))]).serialize()))
    }

    @TestCase
    public func testPrimitiveArrayIndexVariable() {
        @Expect(test("1", "{{foo.0}}",
            M_SL_I([("foo", L_I([1, 2, 3, 4]))]).serialize()))
    }

    @TestCase
    public func testPrimitiveArrayIndexOutOfBoundsVariable() {
        let comp = Mustache.compiler().defaultValue("?");
        @Expect(test(comp, "?", "{{foo.4}}",
            M_SL_I([("foo", L_I([1, 2, 3, 4]))]).serialize()))
    }

    @TestCase 
    public func testOneShotSection() { 
        @Expect(test("baz", "{{#foo}}{{bar}}{{/foo}}",
            M_SM_SS([("foo", M_SS([("bar", "baz")]))]).serialize()))
    }

    @TestCase 
    public func testListSection () {
        @Expect(test("bazbif", "{{#foo}}{{bar}}{{/foo}}", 
        M_SL_M_SS([("foo", L_M_SS(
            [M_SS([("bar", "baz")]), M_SS([("bar", "bif")])]))]).serialize()))
    }

    @TestCase 
    public func testListIndexSection() { 
        @Expect(test("baz", "{{#foo.0}}{{bar}}{{/foo.0}}",
        M_SL_M_SS([("foo", L_M_SS(
            [M_SS([("bar", "baz")]), M_SS([("bar", "bif")])]))]).serialize()))
    }

    @TestCase 
    public func testListIndexOutOfBoundsSection (){
        @Expect(test("", "{{#foo.2}}{{bar}}{{/foo.2}}",
        M_SL_M_SS([("foo", L_M_SS(
            [M_SS([("bar", "baz")]), M_SS([("bar", "bif")])]))]).serialize()))
    }

    @TestCase 
    public func testListItemSection () {
        @Expect(test("baz", "{{foo.0.bar}}", 
        M_SL_M_SS([("foo", L_M_SS(
            [M_SS([("bar", "baz")]), M_SS([("bar", "bif")])]))]).serialize()))
    }

    @TestCase 
    public func testArraySection() {
        @Expect(test("bazbif", "{{#foo}}{{bar}}{{/foo}}",
            M_SA_M_SS([("foo", 
                [M_SS([("bar", "baz")]), M_SS([("bar", "bif")])])]).serialize()))
    }

    @TestCase 
    public func testArrayIndexSection() {
        @Expect(test("baz", "{{#foo.0}}{{bar}}{{/foo.0}}",
            M_SA_M_SS([("foo", 
                [M_SS([("bar", "baz")]), M_SS([("bar", "bif")])])]).serialize()))
    }

    @TestCase
    public func testArrayIndexOutOfBoundsSection() {
        @Expect(test("", "{{#foo.2}}{{bar}}{{/foo.2}}",
            M_SA_M_SS([("foo", 
                [M_SS([("bar", "baz")]), M_SS([("bar", "bif")])])]).serialize()))
    }
    
    @TestCase 
    public func testEmptyListSection() {
        @Expect(test("", "{{#foo}}{{bar}}{{/foo}}", 
            M_SL_I([("foo", L_I())]).serialize()))
    }

    @TestCase
    public func testEmptyArraySection() {
        @Expect(test("", "{{#foo}}{{bar}}{{/foo}}", 
                    M_SA_I([("foo", A_I())]).serialize()))
    }

    @TestCase
    public func testFalseSection() {
        @Expect(test("", "{{#foo}}{{bar}}{{/foo}}", 
            M_SB([("foo", false)]).serialize()))
    }

    @TestCase 
    public func testNestedListSection() {
        HashMap<String, HashMap<String, Array<HashMap<String, String>>>>()
        @Expect(test("1234", "{{#a}}{{#b}}{{c}}{{/b}}{{#d}}{{e}}{{/d}}{{/a}}",
            M_SM_SA_M_SS([("a", M_SA_M_SS([
                ("b", [M_SS([("c", "1")]), M_SS([("c", "2")])]), 
                ("d", [M_SS([("e", "3")]), M_SS([("e", "4")])])]))]).serialize()))
    }

    @TestCase 
    public func testNullSection() {
        var ctx = M_SOS([("foo", None)]).serialize()
        @Expect(test("", "{{#foo}}{{bar}}{{/foo}}", ctx))
        @Expect(test(Mustache.compiler().defaultValue(""), 
                        "", "{{#foo}}{{bar}}{{/foo}}", ctx))
        @Expect(test(Mustache.compiler().nullValue(""), 
                        "", "{{#foo}}{{bar}}{{/foo}}", ctx))
    }

    @TestCase
    public func testMissingNonStrictSection() {
        // no foo; section omitted due to non-strict-sections
        @Expect(test("", "{{#foo}}{{bar}}{{/foo}}", EMPTY))
        // no foo; no exception because nullValue does change section strictness
        @Expect(test(Mustache.compiler().nullValue(""), 
                        "", "{{#foo}}{{bar}}{{/foo}}", EMPTY))
        // no foo; no exception because defaultValue does change section strictness
        @Expect(test(Mustache.compiler().defaultValue(""),
                        "", "{{#foo}}{{bar}}{{/foo}}", EMPTY))
    }

    @TestCase 
    public func testMissingStrictSection() {  // 不能准确抛出需要的错误
        try {
            @Expect(test(Mustache.compiler().strictSections(true), 
                        "", "{{#foo}}{{bar}}{{/foo}}", EMPTY))
                         // no foo; should throw exception due to strict-sections
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
        var ctx = M_SS([("foo", ""), ("bar", "nonempty")]).serialize()
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
            test(None, "{{>foo}}", DataModelNull())
            @Assert(false)
        } catch (me: Exception) {} // expected
    }

    @TestCase 
    public func testPartial() {
        @Expect(test(Mustache.compiler().withLoader(
                fpartials(("foo", "inside:{{bar}}"), ("baz", "nonfoo")))
                    , "foo inside:foo nonfoo foo", "{{bar}} {{>foo}} {{>baz}} {{bar}}", 
                        M_SS([("bar", "foo")]).serialize()))
    }

    @TestCase
    public func testPartialIndent() {
        @Expect(test(Mustache.compiler().withLoader(
            StringTemplateLoader("|\n{{{content}}}\n|\n"))
                , "\\\n |\n <\n->\n |\n/\n", "\\\n {{>partial}}\n/\n",
                    M_SS([("content", "<\n->")]).serialize()))
    }

    @TestCase
    public func testPartialBlankLines() {
        @Expect(test(Mustache.compiler().withLoader(
            StringTemplateLoader("|\na\n\nb\n|\n"))
                , "\\\n\t|\n\ta\n\t\n\tb\n\t|\n/\n", 
                    "\\\n\t{{>partial}}\n/\n", EMPTY))
    }

    @TestCase
    public func testNestedPartialBlankLines() {
        @Expect(test(Mustache.compiler().withLoader(
            DualStrPartialTemplateLoader("1\n\t{{>nest}}\n1\n", "2\na\n\nb\n2\n" ))
                , "\\\n\t1\n\t\t2\n\t\ta\n\t\t\n\t\tb\n\t\t2\n\t1\n/\n",
                    "\\\n\t{{>partial}}\n/\n", EMPTY))
    }

    @TestCase 
    public func testNestedPartialBlankLinesCRLF() {
        @Expect(test(Mustache.compiler().withLoader(
            DualStrPartialTemplateLoader("1\r\n\t{{>nest}}\r\n1\r\n", "2\r\na\r\n\r\nb\r\n2\r\n"))
                , "\\\r\n\t1\r\n\t\t2\r\n\t\ta\r\n\t\t\r\n\t\tb\r\n\t\t2\r\n\t1\r\n/\r\n",
                    "\\\r\n\t{{>partial}}\r\n/\r\n", EMPTY))
    }

    @TestCase
    public func testNestedPartialIndent() {
        let loader = fpartials(("partial", "1\n {{>nest}}\n1\n"), ("nest", "2\n{{{content}}}\n2\n"))
        @Expect(test(Mustache.compiler().withLoader(loader), "|\n 1\n  2\n  <\n->\n  2\n 1\n|\n",
            "|\n {{>partial}}\n|\n", M_SS([("content", "<\n->")]).serialize()))
    }

    @TestCase
    public func testPartialIndentWithVariableAtTheStart() {
        @Expect(test(Mustache.compiler().withLoader(
                StringTemplateLoader("{{{content}}}\n|\n"))
                , "\\\n <\n->\n |\n/\n", "\\\n {{>partial}}\n/\n", 
                    M_SS([("content", "<\n->")]).serialize()))
    }

    @TestCase
    public func testPartialIndentWithBlock() {
        @Expect(test(Mustache.compiler().withLoader(
            StringTemplateLoader("|\n{{#show}}\n{{{content}}}{{/show}}\n|\n"))
                , "\\\n |\n <\n->\n |\n/\n", "\\\n {{>partial}}\n/\n", 
                    DiffTypeRenderClass_B_S().serialize()))
    }

    @TestCase public func testPartialIndentInBlock() {
        @Expect(test(Mustache.compiler().withLoader(StringTemplateLoader("content"))
            , " content", "{{#show}}\n {{>partial}}\n{{/show}}\n", 
                M_SB([("show", true)]).serialize()))
    }

    @TestCase
    public func testPartialIndentWithBlockAtStart() {
        @Expect(test(Mustache.compiler().withLoader(
            StringTemplateLoader("{{#show}}\n{{{content}}}{{/show}}\n|\n"))
                , "\\\n <\n->\n |\n/\n", "\\\n {{>partial}}\n/\n", 
                    DiffTypeRenderClass_B_S().serialize()))
    }

    @TestCase 
    public func testPartialIndentWithInlineBlock() {
        @Expect(test(Mustache.compiler().withLoader(
            StringTemplateLoader("line {{#show}}content{{/show}}\n"))
                , "\\\n line content\n/\n", "\\\n {{>partial}}\n/\n",
                    M_SB([("show", true)]).serialize()))
    }

    @TestCase 
    public func testPartialPlusNestedContext() {
        @Expect(test(Mustache.compiler().withLoader(
            DualStrNestedTemplateLoader("{{name}}{{thing_name}}", "nonfoo"))
                , "foo((foobar)(foobaz))", "{{name}}({{#things}}({{>nested}}){{/things}})",
                    DiffTypeRenderClass_S_L_M_SS().serialize()))
    }

    @TestCase 
    public func testDelimiterChange() {
        @Expect(test("foo bar baz", "{{one}} {{=<% %>=}}<%two%><%={{ }}=%> {{three}}",
            M_SS([("one", "foo"), ("two", "bar"), ("three", "baz")]).serialize()))
        @Expect(test("baz bar foo", "{{three}} {{=% %=}}%two%%={{ }}=% {{one}}",
            M_SS([("one", "foo"), ("two", "bar"), ("three", "baz")]).serialize()))
    }

    @TestCase
    public func testUnescapeHTML() {
        @Expect(check("<b>", Mustache.compiler().escapeHTML(true).compile("{{&a}}").
            execute(M_SS([("a", "<b>")]).serialize())))
        @Expect(check("<b>", Mustache.compiler().escapeHTML(true).compile("{{{a}}}").
            execute(M_SS([("a", "<b>")]).serialize())))
        // make sure these also work when escape HTML is off
        @Expect(check("<b>", Mustache.compiler().escapeHTML(false).compile("{{&a}}").
            execute(M_SS([("a", "<b>")]).serialize())))
        @Expect(check("<b>", Mustache.compiler().escapeHTML(false).compile("{{{a}}}").
            execute(M_SS([("a", "<b>")]).serialize())))
    }

    @TestCase 
    public func testStrayTagCharacters() {
        @Expect(test("funny [b] business {{", "funny {{a}} business {{", M_SS([("a", "[b]")]).serialize()))
        @Expect(test("funny <b> business {{", "funny {{{a}}} business {{", M_SS([("a", "<b>")]).serialize()))
        @Expect(test("{{ funny [b] business", "{{ funny {{a}} business", M_SS([("a", "[b]")]).serialize()))
        @Expect(test("{{ funny <b> business", "{{ funny {{{a}}} business", M_SS([("a", "<b>")]).serialize()))
        @Expect(test("funny [b] business }}", "funny {{a}} business }}", M_SS([("a", "[b]")]).serialize()))
        @Expect(test("funny <b> business }}", "funny {{{a}}} business }}", M_SS([("a", "<b>")]).serialize()))
        @Expect(test("}} funny [b] business", "}} funny {{a}} business", M_SS([("a", "[b]")]).serialize()))
        @Expect(test("}} funny <b> business", "}} funny {{{a}}} business", M_SS([("a", "<b>")]).serialize()))
    }

    @TestCase 
    public func testInvalidUnescapeHTML() {
        try {
            Mustache.compiler().escapeHTML(true).compile("{{{a}}").execute(
                M_SS([("a", "<b>")]).serialize())
            @Assert(false)
        } catch (me: Exception) {} // expected
    }

    @TestCase 
    public func testEscapeHTML () {
        @Expect(check("&lt;b&gt;", Mustache.compiler().compile("{{a}}").execute(
            M_SS([("a", "<b>")]).serialize())))
        @Expect(check("<b>", Mustache.compiler().escapeHTML(false).compile("{{a}}").
            execute(M_SS([("a", "<b>")]).serialize())))
        // ensure that some potential XSS enablers are escaped
        @Expect(check("&#x60;&#x3D;", Mustache.compiler().compile("{{a}}").execute(
            M_SS([("a", "`=")]).serialize())))
    }

    @TestCase 
    public func testUserDefinedEscaping(){
        let escaper = Escapers.simple([
            [ "[", ":BEGIN:" ],
            [ "]", ":END:" ]
        ])
        @Expect(check(":BEGIN:b:END:", Mustache.compiler().withEscaper(escaper).
            compile("{{a}}").execute(M_SS([("a", "[b]")]).serialize())))
    }

    @TestCase 
    public func testPartialDelimiterMatch() {
        @Expect(check("{bob}", Mustache.compiler().compile("{bob}").execute(EMPTY)))
        @Expect(check("bar", Mustache.compiler().compile("{{bob}bob}}").execute(
            M_SS([("bob}bob", "bar")]).serialize())))
    }

    @TestCase
    public func testDanglingTag() {
        @Expect(test("foo{", "foo{", M_SS([("a", "<b>")]).serialize()))
        @Expect(test("foo{{", "foo{{", M_SS([("a", "<b>")]).serialize()))
        @Expect(test("foo{{a", "foo{{a", M_SS([("a", "<b>")]).serialize()))
        @Expect(test("foo{{a}", "foo{{a}", M_SS([("a", "<b>")]).serialize()))
    }

    @TestCase 
    public func testTopLevelThis() {
        @Expect(check("bar", Mustache.compiler().compile("{{this}}").execute("bar".serialize())))
        @Expect(check("bar", Mustache.compiler().compile("{{.}}").execute("bar".serialize())))
    }

    @TestCase 
    public func testNestedThis() {
        @Expect(check("barbazbif", Mustache.compiler().compile("{{#things}}{{this}}{{/things}}").
            execute(M_SL_S([("things", L_S(["bar", "baz", "bif"]))]).serialize())))
        @Expect(check("barbazbif", Mustache.compiler().compile("{{#things}}{{.}}{{/things}}").
            execute(M_SL_S([("things", L_S(["bar", "baz", "bif"]))]).serialize())))
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
            M_SB([("boolean", false)]).serialize()))
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
            "endlist", tmpl, M_SL_S([("items", L_S(["one", "two", "three"]))]).serialize()))
        @Expect(test("list:" + sep +
            "no items" + sep +
            "endlist", tmpl, M_SL_S([("items", L_S())]).serialize()))

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
            "</ul>", htmlTmpl, M_SL_S([("items", L_S(["one", "two", "three"]))]).serialize()))
        @Expect(test("<ul>" + sep +
            "  <li>no items</li>" + sep +
            "</ul>", htmlTmpl, M_SL_S([("items", L_S())]).serialize()))
    }

    @TestCase
    public func testNewlineNonSkipping () {
        // only when a section tag is by itself on a line should we absorb the newline following it
        let tmpl = "thing?: {{#thing}}yes{{/thing}}{{^thing}}no{{/thing}}\n" +
            "that's nice";
        @Expect(test("thing?: yes\n" +
            "that's nice", tmpl, M_SB([("thing", true)]).serialize()))
        @Expect(test("thing?: no\n" +
            "that's nice", tmpl, M_SB([("thing", false)]).serialize()))
    }

    @TestCase
    public func testNestedContexts () {
        @Expect(test("foo((foobar)(foobaz))", "{{name}}({{#things}}({{name}}{{thing_name}}){{/things}})",
            DiffTypeRenderClass_S_L_M_SS().serialize()))
    }

    @TestCase 
    public func testShadowedContext() {
        @Expect(test("foo((bar)(baz))", "{{name}}({{#things}}({{name}}){{/things}})",
            DiffTypeRenderClass_S_L_M_SS("foo", L_M_SS([M_SS([("name", "bar")]), M_SS([("name", "baz")])])).serialize()))
    }

    @TestCase 
    public func testFirst() {
        @Expect(test("foo|bar|baz", "{{#things}}{{^-first}}|{{/-first}}{{this}}{{/things}}",
            M_SL_S([("things", L_S(["foo", "bar", "baz"]))]).serialize()))
    }

    @TestCase 
    public func testLast() {
        @Expect(test("foo|bar|baz", "{{#things}}{{this}}{{^-last}}|{{/-last}}{{/things}}",
            M_SL_S([("things", L_S(["foo", "bar", "baz"]))]).serialize()))
    }

    @TestCase 
    public func testFirstLast() { 
        @Expect(test("[foo]", "{{#things}}{{#-first}}[{{/-first}}{{this}}{{#-last}}]{{/-last}}{{/things}}",
            M_SL_S([("things", L_S(["foo"]))]).serialize()))
        @Expect(test("foo", "{{#things}}{{this}}{{^-last}}|{{/-last}}{{/things}}",
            M_SL_S([("things", L_S(["foo"]))]).serialize()))
    }

    @TestCase 
    public func testFirstLastCombo() {
        @Expect(test("FIRST_and_LAST", "{{#things}}{{#-first}}FIRST{{/-first}}{{this}}{{#-last}}LAST{{/-last}}{{/things}}",
            M_SL_S([("things", L_S(["_and_"]))]).serialize()))
    }

    @TestCase 
    public func testInverseFirstLastCombo() {  
        @Expect(test("_and_", "{{#things}}{{^-first}}NOT-FIRST{{/-first}}{{this}}{{^-last}}NOT-LAST{{/-last}}{{/things}}",
            M_SL_S([("things", L_S(["_and_"]))]).serialize()))
    }

    @TestCase 
    public func testNotFirst() { 
        @Expect(test("1,2,3", "{{#things}}{{^-first}},{{/-first}}{{this}}{{/things}}",
            M_SL_S([("things", L_S(["1", "2", "3"]))]).serialize()))
    }

    @TestCase 
    public func testNotLast() {
        @Expect(test("1,2,3", "{{#things}}{{this}}{{^-last}},{{/-last}}{{/things}}",
            M_SL_S([("things", L_S(["1", "2", "3"]))]).serialize()))
    }

    @TestCase 
    public func testIndex() {
        @Expect(test("123", "{{#things}}{{-index}}{{/things}}",
            M_SL_S([("things", L_S(["foo", "bar", "baz"]))]).serialize()))
    }

    @TestCase 
    public func testNestedIndex() {
        let tmpl =
            "{{#fooList}}\n" +
            "{{#quantity}}|q{{-index}}={{quantity}}{{/quantity}}|{{name}}\n" +
            "{{/fooList}}"
        @Expect(test("|q1=1|a\n|b\n", tmpl,
            M_SL_M_SS([("fooList", L_M_SS([M_SS([("name", "a"), ("quantity", "1")]), M_SS([("name", "b")])]))]).serialize()))
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
    public func testStandardsModeWithDotValue() {
        let tmpl = "{{#foo}}:{{.}}:{{/foo}}"
        let result = Mustache.compiler().standardsMode(true).compile(tmpl).
            execute(M_SS([("foo", "bar")]).serialize())
        @Expect(check(":bar:", result))
    }

    @TestCase 
    public func testStandardsModeWithNoParentContextSearching() {
        try {
            let tmpl = "{{#parent}}foo{{parentProperty}}bar{{/parent}}"
            let result = Mustache.compiler().standardsMode(true).compile(tmpl).
                execute(DiffTypeRenderClass_M_SS_S(M_SS(), "bar").serialize())
            @Expect(false)
        } catch (me: Exception) {} // expected
    }

    @TestCase 
    public func testMissingValue() {
        try {
            test("n/a", "{{missing}} {{notmissing}}", M_SS([("notmissing", "bar")]).serialize())
            @Expect(false)
        } catch (me: Exception) {} // expected
    }

    @TestCase 
    public func testMissingValueWithDefault() {
        @Expect(test(Mustache.compiler().defaultValue(""),
            "bar", "{{missing}}{{notmissing}}", 
                M_SS([("notmissing", "bar")]).serialize()))
    }

    @TestCase 
    public func testMissingValueWithDefaultNonEmptyString() {
        @Expect(test(Mustache.compiler().defaultValue("foo"),
            "foobar", "{{missing}}{{notmissing}}", 
                M_SS([("notmissing", "bar")]).serialize()))
    }

    @TestCase 
    public func testMissingValueWithDefaultSubstitution() {
        @Expect(test(Mustache.compiler().defaultValue("?{{name}}?"),
            "?missing?bar", "{{missing}}{{notmissing}}",
                M_SS([("notmissing", "bar")]).serialize()))
    }

    @TestCase
    public func testMissingValueWithDefaultSubstitution2() {
        @Expect(test(Mustache.compiler().defaultValue("{{{{name}}}}"),
            "{{missing}}bar", "{{missing}}{{notmissing}}",
                M_SS([("notmissing", "bar")]).serialize()))
    }

    @TestCase
    public func testMissingValueWithDefaultSubstitution3() {
        @Expect(test(Mustache.compiler().defaultValue("{{?{{name}}?}}"),
            "{{?missing?}}bar", "{{missing}}{{notmissing}}", 
                M_SS([("notmissing", "bar")]).serialize()))
    }

    @TestCase
    public func testMissingValueWithNullDefault () {
        try {
            // no field or method for 'missing'
            test(Mustache.compiler().nullValue(""), 
                "bar", "{{missing}}{{notmissing}}", 
                    M_SS([("notmissing", "bar")]).serialize())
            @Expect(false)
        } catch (me: Exception) {} // expected
    }

    @TestCase 
    public func testInvalidTripleMustache() {
        try {
            Mustache.compiler().compile("{{{foo}}")
            fail("Expected MustacheParseException")
        } catch (me: MustacheException) {
            @Expect(check(
                "Invalid triple-mustache tag: {{{foo}} @ line 1", me.message))
        }
        try {
            Mustache.compiler().compile("{{{foo}}]")
            fail("Expected MustacheParseException")
        } catch (me: MustacheException) {
            @Expect(check(
                "Invalid triple-mustache tag: {{{foo}}] @ line 1", me.message))
        }
    }

    @TestCase 
    public func testNonStandardDefaultDelims() {
        @Expect(test(Mustache.compiler().withDelims("<% %>"), "bar", "<%foo%>", 
            M_SS([("foo", "bar")]).serialize()))
    }

    @TestCase 
    public func testCompilingDoesntChangeCompilersDelimiters() {
        let compiler = Mustache.compiler();
        let ctx = M_SS([("variable", "value")]).serialize()
        @Expect(test(compiler, "value", "{{=<% %>=}}<% variable %>", ctx))
        @Expect(test(compiler, "value", "{{=<% %>=}}<% variable %>", ctx))
    }

    @TestCase
    public func testChinese() {
        @Expect(test("你好, 世界!", "你好, {{foo}}!", 
            M_SS([("foo", "世界")]).serialize()))

        @Expect(test("你好, 世界!", "你好, {{中}}!", 
            M_SS([("中", "世界")]).serialize()))

        @Expect(test("你好, 世界!", "你好, {{中foo中}}!", 
            M_SS([("中foo中", "世界")]).serialize()))

        @Expect(test("你好, 世界!", "你好, {{中中foo……下%#上中}}!", 
            M_SS([("中中foo……下%#上中", "世界")]).serialize()))
    }

    protected func test(compiler: Compiler, expected: ?String, template: String, ctx: DataModel): Bool {
        let actual: String = compiler.compile(template).execute(ctx)
        if (!(expected.getOrThrow() == actual)) {
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
        return showWhitespace(expected.getOrThrow()) == showWhitespace(output)
    }

    protected func test(expected: ?String, template: String, ctx: DataModel): Bool {
        return test(Mustache.compiler(), expected, template, ctx)
    }

    protected func showWhitespace(s: String): String {
        s.replace("\r\n", (r"\u{240D}").toString())
        s.replace('\t', (r"\u{21E5}").toString())
        s.replace("\n", "\u{21B5}\n")
        s.replace("\u{240D}", "\u{240D}\n")
        return s
    }

    protected func fpartials(entries: Array<(String, String)>): TemplateLoader {
        let templates = HashMap<String, String>()
        for (e in entries) {
            templates.put(e[0], e[1])
        }
        partials = templates
        return MapTemplateLoader(templates)
    }
} 


public class MapTemplateLoader <: TemplateLoader {
    public MapTemplateLoader(let mp: HashMap<String, String>) {}

    public func getTemplate(name: String): InputStream {
        let byteArrayStream = ByteArrayStream()
        if (let Some(value) <- mp.get(name)) {
            byteArrayStream.write(value.toArray())
            return BufferedInputStream(byteArrayStream)
        }
        return BufferedInputStream(byteArrayStream)
    }
}

public class StringTemplateLoader <: TemplateLoader {
    public StringTemplateLoader(let str: String) {}

    public func getTemplate(_: String): InputStream {
        let byteArrayStream = ByteArrayStream()
        byteArrayStream.write(str.toArray())
        return BufferedInputStream(byteArrayStream)
    }
} 

public class DualStrPartialTemplateLoader <: TemplateLoader {
    public DualStrPartialTemplateLoader(let str1: String, let str2: String) {}

    public func getTemplate(name: String): InputStream {
        let byteArrayStream = ByteArrayStream()
        if (name == "partial") {
            byteArrayStream.write(str1.toArray())
            return BufferedInputStream(byteArrayStream)
        }
        byteArrayStream.write(str2.toArray())
        return BufferedInputStream(byteArrayStream)
    }
} 


public class DualStrNestedTemplateLoader <: TemplateLoader {
    public DualStrNestedTemplateLoader(let str1: String, let str2: String) {}

    public func getTemplate(name: String): InputStream {
        let byteArrayStream = ByteArrayStream()
        if (name == "nested") {
            byteArrayStream.write(str1.toArray())
            return BufferedInputStream(byteArrayStream)
        }
        byteArrayStream.write(str2.toArray())
        return BufferedInputStream(byteArrayStream)
    }
}

public class DiffTypeRenderClass_B_S <: Serializable<DiffTypeRenderClass_B_S> {
    var show = true
    var content = "<\n->"

    public func serialize(): DataModel {
        return DataModelStruct()
            .add(field<Bool>("show", show))
            .add(field<String>("content", content))
    }

    public static func deserialize(dm: DataModel): DiffTypeRenderClass_B_S {
        let dms = match (dm) {
            case data: DataModelStruct => data
            case _ => throw Exception("this data is not DataModelStruct")
        }
        let result = DiffTypeRenderClass_B_S()
        result.show = Bool.deserialize(dms.get("show"))
        result.content = String.deserialize(dms.get("content"))
        return result
    }
}

public class DiffTypeRenderClass_S_L_M_SS <: Serializable<DiffTypeRenderClass_S_L_M_SS> {
    var name = "foo"
    var things = L_M_SS([M_SS([("thing_name", "bar")]), M_SS([("thing_name", "baz")])])

    public DiffTypeRenderClass_S_L_M_SS() {}

    public init(_name: String, _things: L_M_SS) {
        name = _name
        things = _things
    }

    public func serialize(): DataModel {
        return DataModelStruct()
            .add(field<String>("name", name))
            .add(field<L_M_SS>("things", things))
    }

    public static func deserialize(dm: DataModel): DiffTypeRenderClass_S_L_M_SS {
        let dms = match (dm) {
            case data: DataModelStruct => data
            case _ => throw Exception("this data is not DataModelStruct")
        }
        let result = DiffTypeRenderClass_S_L_M_SS()
        result.name = String.deserialize(dms.get("name"))
        result.things = L_M_SS.deserialize(dms.get("things"))
        return result
    }
}

public abstract class AbsDiffTypeRenderClass <: Serializable<AbsDiffTypeRenderClass> {
    public func serialize(): DataModel 
    public static func deserialize(_: DataModel): AbsDiffTypeRenderClass {
        throw UnInplementException()
    }
}

public class DiffTypeRenderClass_S_L <: Serializable<DiffTypeRenderClass_S_L> {
    var name = "level2a"
    var properties = L_I()

    public func serialize(): DataModel {
        return DataModelStruct()
            .add(field<String>("name", name))
            .add(field<L_I>("properties", properties))
    }

    public static func deserialize(dm: DataModel): DiffTypeRenderClass_S_L {
        let dms = match (dm) {
            case data: DataModelStruct => data
            case _ => throw Exception("this data is not DataModelStruct")
        }
        let result = DiffTypeRenderClass_S_L()
        result.name = String.deserialize(dms.get("name"))
        result.properties = L_I.deserialize(dms.get("properties"))
        return result
    }
}

public class DiffTypeRenderClass_S_C <: AbsDiffTypeRenderClass & Serializable<DiffTypeRenderClass_S_C>{
    var name = "level1a"
    var properties = DiffTypeRenderClass_S_L()

    public func serialize(): DataModel {
        return DataModelStruct()
            .add(field<String>("name", name))
            .add(field<DiffTypeRenderClass_S_L>("properties", properties))
    }

    public static func deserialize(dm: DataModel): DiffTypeRenderClass_S_C {
        let dms = match (dm) {
            case data: DataModelStruct => data
            case _ => throw Exception("this data is not DataModelStruct")
        }
        let result = DiffTypeRenderClass_S_C()
        result.name = String.deserialize(dms.get("name"))
        result.properties = DiffTypeRenderClass_S_L.deserialize(dms.get("properties"))
        return result
    }
}

public class DiffTypeRenderClass_S_M_SS <: AbsDiffTypeRenderClass & Serializable<DiffTypeRenderClass_S_M_SS> {
    var name = "level1b"
    var properties = M_SS([("name", "level2b"), ("properties", "")])

    public func serialize(): DataModel {
        return DataModelStruct()
            .add(field<String>("name", name))
            .add(field<M_SS>("properties", properties))
    }

    public static func deserialize(dm: DataModel): DiffTypeRenderClass_S_M_SS {
        let dms = match (dm) {
            case data: DataModelStruct => data
            case _ => throw Exception("this data is not DataModelStruct")
        }
        let result = DiffTypeRenderClass_S_M_SS()
        result.name = String.deserialize(dms.get("name"))
        result.properties = M_SS.deserialize(dms.get("properties"))
        return result
    }
}

public class DiffTypeRenderClass_S_L_G <: Serializable<DiffTypeRenderClass_S_L_G> {
    var name = "level0"
    var properties = ArrayList<AbsDiffTypeRenderClass>([DiffTypeRenderClass_S_C(), DiffTypeRenderClass_S_M_SS()])

    public func serialize(): DataModel {
        return DataModelStruct()
            .add(field<String>("name", name))
            .add(field<ArrayList<AbsDiffTypeRenderClass>>("properties", properties))
    }

    public static func deserialize(dm: DataModel): DiffTypeRenderClass_S_L_G {
        let dms = match (dm) {
            case data: DataModelStruct => data
            case _ => throw Exception("this data is not DataModelStruct")
        }
        let result = DiffTypeRenderClass_S_L_G()
        result.name = String.deserialize(dms.get("name"))
        result.properties = ArrayList<AbsDiffTypeRenderClass>.deserialize(dms.get("properties"))
        return result
    }
}

public class DiffTypeRenderClass_M_SS_S <: Serializable<DiffTypeRenderClass_M_SS_S> {
    var parent: M_SS
    var parentProperty: String

    public init(_parent: M_SS, _parentProperty: String) {
        parent = _parent
        parentProperty = _parentProperty
    }

    public func serialize(): DataModel {
        return DataModelStruct()
            .add(field<M_SS>("parent", parent))
            .add(field<String>("parentProperty", parentProperty))
    }

    public static func deserialize(dm: DataModel): DiffTypeRenderClass_M_SS_S {
        let dms = match (dm) {
            case data: DataModelStruct => data
            case _ => throw Exception("this data is not DataModelStruct")
        }

        let result = DiffTypeRenderClass_M_SS_S(
            M_SS.deserialize(dms.get("parent")),
            String.deserialize(dms.get("parentProperty"))
        )
        return result
    }
}


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
