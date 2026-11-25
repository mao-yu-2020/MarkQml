# Markdown rendering parity notes

This document records the external reference used while hardening `RenderMark`.
It is intentionally written against a specific upstream revision so future QML
changes can be compared without guessing.

## Reference implementation

- Project: [markdown-it](https://github.com/markdown-it/markdown-it)
- Version: `15.0.3`
- Revision: `a8c00d4` (`15.0.3 released`, 2026-10-16)
- License: MIT
- Why this project:
  - it is a mature, widely deployed CommonMark parser and renderer;
  - its block/inline rule split is close to the `cmark-gfm` AST used by
    `RenderMark`, so token/edge-case comparisons are meaningful;
  - its link validator and HTML escaping rules are explicit and testable;
  - it is independent of Qt, so it gives us a non-QML reference for layout
    semantics, escaping, and dangerous-link handling.

`markdown-it` is not shipped or linked into `RenderMark`; it is only a reference
oracle for tests and review.

## Behaviours compared

The following fixtures were rendered with `markdown-it` 15.0.3 using
`html: false`, `linkify: true`, `typographer: false`, plus
`markdown-it-task-lists` 2.1.1 for GFM task items.

| Area | markdown-it behaviour | RenderMark target |
| --- | --- | --- |
| Raw HTML | `html: false` escapes `<em>` as text | escape HTML unless a future whitelist is added |
| Links | rejects `javascript:`, `vbscript:`, `file:`, and most `data:` URLs | additionally only open `http`, `https`, and `mailto` from chat UI |
| Tables | emits per-column `text-align:left/center/right` | map `alignments` to the native cell alignment |
| Task lists | emits disabled checkbox plus label | render a native checkbox plus label |
| Fenced code | keeps fence language in `language-*` class | keep the language label and code as plain text |
| Softbreak | emits a source newline inside the paragraph | preserve a visible line break in the native rich-text block |
| Inline code | escapes content and wraps it in `<code>` | escape content and use a monospace inline run |
| Images | validates the source URL before rendering | constrain to container width and reject unsafe schemes |

## Deliberate differences

- `RenderMark` is a QML renderer, not an HTML renderer. It does not emit HTML
  for the final document; the reference is used only to verify parsing and
  security semantics.
- The chat surface is read-only. Task-list checkboxes are display-only for now;
  toggling would require writing back to the Markdown source.
- Relative links are not opened from chat. `http`, `https`, and `mailto` are the
  supported schemes until a product decision adds local-file navigation.

## Verification fixtures

The comparison fixtures cover:

1. paragraphs with long CJK text and inline emphasis;
2. nested emphasis/strong/strikethrough;
3. inline code and fenced code with a language;
4. GFM tables with left/center/right alignment;
5. task lists (`[x]` and `[ ]`) mixed with normal list items;
6. raw HTML blocks/inlines;
7. `javascript:`, `data:`, relative, and `mailto:` links;
8. images with local and remote sources;
9. hard/soft line breaks;
10. autolinks.

These are the cases that the QML components must keep aligned when the
renderer is extended.
