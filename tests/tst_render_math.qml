import QtQuick
import QtTest
import RenderMark 1.0

// Run this suite against a build configured with JKQTMATH_TEXT_ROOT.
TestCase {
    name: "MathBlock"
    width: 500
    height: 600

    Component {
        id: renderComponent
        RenderMark {
            width: 420
            fitContent: true
            animate: false
        }
    }

    function findMath(item, out) {
        if (!item || !item.children)
            return
        for (var i = 0; i < item.children.length; ++i) {
            var child = item.children[i]
            if (child.latex !== undefined && child.error !== undefined)
                out.push(child)
            findMath(child, out)
        }
    }

    function collectText(item, out) {
        if (!item || !item.children)
            return
        for (var i = 0; i < item.children.length; ++i) {
            var child = item.children[i]
            if (child.text !== undefined && child.textFormat !== undefined)
                out.push(child.text)
            collectText(child, out)
        }
    }

    function findNodeType(node, type, out) {
        if (!node)
            return
        if (node.type === type)
            out.push(node)
        var children = node.children || []
        for (var i = 0; i < children.length; ++i)
            findNodeType(children[i], type, out)
    }

    function render(markdown) {
        var item = renderComponent.createObject(this)
        item.markdown = markdown
        wait(120)
        return item
    }

    function test_display_math_dollar() {
        var item = render("$$\nx=\\frac{-b\\pm\\sqrt{b^2-4ac}}{2a}\n$$")
        var found = []
        findMath(item, found)
        verify(found.length > 0)
        verify(found[0].implicitWidth > 0)
        verify(found[0].implicitHeight > 0)
        verify(found[0].error === "")
        compare(found[0].latex.indexOf("\\frac") >= 0, true)
        item.destroy()
    }

    function test_display_math_bracket() {
        var item = render("\\[\na^2+b^2=c^2\n\\]")
        var found = []
        findMath(item, found)
        verify(found.length > 0)
        verify(found[0].implicitWidth > 0)
        verify(found[0].error === "")
        item.destroy()
    }

    function test_math_preserves_latex_escapes() {
        var item = render("$$\n\\int_0^1 x^2\\,dx\\n$$")
        var found = []
        findMath(item, found)
        verify(found.length > 0)
        verify(found[0].latex.indexOf("\\,") >= 0)
        item.destroy()
    }

    function test_blockquote_math_has_no_container_markers() {
        var item = render("> $$\nx+y\n$$")
        var found = []
        findMath(item, found)
        verify(found.length > 0)
        compare(found[0].latex.indexOf(">"), -1)
        verify(found[0].implicitWidth > 0)
        item.destroy()
    }

    function test_fenced_code_is_not_math() {
        var item = render("```\n$$a**b**$$\n```")
        var found = []
        findMath(item, found)
        compare(found.length, 0)
        item.destroy()
    }

    function test_inline_code_is_not_math() {
        var item = render("`$$a**b**$$`")
        var found = []
        findMath(item, found)
        compare(found.length, 0)
        var texts = []
        collectText(item, texts)
        verify(texts.join("").indexOf("$$a**b**$$") >= 0)
        item.destroy()
    }

    function test_indented_code_is_not_math() {
        var item = render("    $$a**b**$$\n")
        var found = []
        findMath(item, found)
        compare(found.length, 0)
        var texts = []
        collectText(item, texts)
        verify(texts.join("").indexOf("$$a**b**$$") >= 0)
        item.destroy()
    }

    function test_link_destination_is_restored() {
        var item = render("[x](https://example.com/$$a$$)")
        var links = []
        findNodeType(item.tree.root, "link", links)
        compare(links.length, 1)
        compare(links[0].url, "https://example.com/$$a$$")
        item.destroy()
    }

    function test_oversized_formula_is_bounded() {
        var item = render("$$\n" + "x+".repeat(5000) + "x\n$$")
        var found = []
        findMath(item, found)
        verify(found.length > 0)
        verify(found[0].implicitWidth > 0)
        verify(found[0].implicitWidth <= 4096)
        verify(found[0].implicitHeight > 0)
        verify(found[0].implicitHeight <= 4096)
        item.destroy()
    }

    function test_very_wide_formula_is_bounded() {
        var item = render("$$\n\\mathrm{" + "x".repeat(2000) + "}\n$$")
        var found = []
        findMath(item, found)
        verify(found.length > 0)
        verify(found[0].implicitWidth > 0)
        verify(found[0].implicitWidth <= 4096)
        verify(found[0].implicitHeight > 0)
        verify(found[0].implicitHeight <= 4096)
        item.destroy()
    }

    function test_deeply_nested_formula_is_bounded() {
        var latex = "\\sqrt{".repeat(200) + "x" + "}".repeat(200)
        var item = render("$$\n" + latex + "\n$$")
        var found = []
        findMath(item, found)
        verify(found.length > 0)
        verify(found[0].implicitWidth > 0)
        verify(found[0].implicitWidth <= 4096)
        verify(found[0].implicitHeight > 0)
        verify(found[0].implicitHeight <= 4096)
        item.destroy()
    }

    function test_many_formulas_are_restored() {
        var markdown = ""
        for (var i = 0; i < 20; ++i)
            markdown += "$$\nx_" + i + "\n$$\n\n"
        var item = render(markdown)
        var found = []
        findMath(item, found)
        compare(found.length, 20)
        for (var j = 0; j < found.length; ++j) {
            verify(found[j].latex.indexOf("x_" + j) >= 0)
            verify(found[j].latex.indexOf("$$") < 0)
            verify(found[j].implicitWidth > 0)
        }
        item.destroy()
    }

    function test_math_does_not_display_delimiters() {
        var item = render("$$\na+b\n$$")
        var found = []
        findMath(item, found)
        verify(found.length > 0)
        verify(found[0].latex.indexOf("$$") < 0)
        item.destroy()
    }
}
