pragma ComponentBehavior: Bound

/**
 * @brief Heading renderer.
 *
 * Heading text is an inline flow just like a paragraph; reuse the rich-text
 * renderer so links, emphasis, code, and wrapping behave consistently.
 */
MarkInlineText {
    id: root

    headingLevel: root.astNode && root.astNode.level > 0 ? root.astNode.level : 1
}
