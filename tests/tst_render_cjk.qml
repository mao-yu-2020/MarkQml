import QtQuick
import QtTest
import RenderMark 1.0

// Run this suite against a build configured with CMARK_GFM_CJK_ROOT, i.e. the
// cjk-friendly cmark-gfm fork. It intentionally exercises cases that plain
// CommonMark/cmark-gfm leaves as literal text.
TestCase {
    name: "CjkFriendly"
    width: 400
    height: 400

    Component {
        id: renderComponent
        RenderMark {
            width: 300
            fitContent: true
            animate: false
        }
    }

    function render(markdown) {
        var item = renderComponent.createObject(this)
        item.markdown = markdown
        wait(60)
        var out = []
        collectText(item, out)
        item.destroy()
        return out.join("")
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

    function test_cjk_strong_and_emphasis() {
        var cases = [
            "例子例子**\"加粗\"**例子例子",
            "日本語**(強調)**日本語",
            "한국어**[강조]**한국어",
            "**来源：**2013年",
            "中文**加粗**中文",
            "中文__加粗__中文"
        ]
        for (var i = 0; i < cases.length; ++i) {
            var html = render(cases[i])
            verify(html.indexOf("font-weight:700") >= 0)
        }

        var italic = render("中文*\"斜体\"*中文")
        verify(italic.indexOf("font-style:italic") >= 0)
    }

    function test_cjk_strikethrough() {
        var html = render("a~~a()~~あ")
        verify(html.indexOf("line-through") >= 0)
    }

    function test_cjk_non_regression() {
        var html = render("a * foo bar*\n\na_foo bar_")
        verify(html.indexOf("font-weight:700") < 0)
        verify(html.indexOf("font-style:italic") < 0)
    }
}
