# RenderMark regression tests

These are QML TestCase files for the native renderer. They cover the cases
that matter for a chat surface rather than the HTML output of a browser:

- `tst_render_mark.qml` — inline layout, tables, task lists, code blocks,
  source loading, raw HTML escaping, and dangerous JavaScript links;
- `tst_render_cjk.qml` — CJK strong/emphasis and non-regression cases for the
  CJK-friendly cmark-gfm fork;
- `tst_render_math.qml` — `$$...$$` and `\[...\]` block formulas, LaTeX
  escape preservation, and code/link protection. With JKQTMathText disabled
  the same suite verifies the text fallback.

## Run

Build the project first, then point the QML engine at the build tree and the
RenderMark plugin:

```bash
qmltestrunner \
  -input tests/tst_render_mark.qml \
  -import "$PWD/build" \
  -import "$PWD/build/RenderMark"
```

If `RenderMark` and `cmark-gfm` are installed in a non-standard prefix, add the
corresponding `QML2_IMPORT_PATH` / `LD_LIBRARY_PATH` entries, for example:

```bash
QML2_IMPORT_PATH="$PWD/build" \
LD_LIBRARY_PATH="$PWD/build/RenderMark:/path/to/cmark-gfm/lib" \
qmltestrunner -input tests/tst_render_mark.qml
```

The tests use only the public `RenderMark` QML module and do not require a
display (`QT_QPA_PLATFORM=offscreen` works).

For a build configured with `JKQTMATH_TEXT_ROOT`, add the JKQTMathText runtime
directory to `LD_LIBRARY_PATH` as well:

```bash
QML2_IMPORT_PATH="$PWD/build" \
LD_LIBRARY_PATH="$PWD/build/RenderMark:$PWD/build:/path/to/jkqtmathtext/lib" \
qmltestrunner -input tests/tst_render_math.qml
```
