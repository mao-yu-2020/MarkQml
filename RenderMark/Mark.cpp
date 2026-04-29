#include "Mark.h"
#include "MarkTree.h"
#include "MarkNode.h"

#include <QFile>
#include <QTextStream>

#include <cmark-gfm.h>
#include <cmark-gfm-core-extensions.h>

/**
 * @brief 为 cmark 解析器附加指定名称的语法扩展
 */
static void attachSyntaxExtension(cmark_parser *parser, const char *name)
{
    cmark_syntax_extension *ext = cmark_find_syntax_extension(name);
    if (ext) {
        cmark_parser_attach_syntax_extension(parser, ext);
    }
}

/**
 * @brief 为 cmark 解析器附加所有 GFM 核心扩展
 */
static void setupParser(cmark_parser *parser)
{
    attachSyntaxExtension(parser, "table");
    attachSyntaxExtension(parser, "strikethrough");
    attachSyntaxExtension(parser, "autolinks");
    attachSyntaxExtension(parser, "tagfilter");
    attachSyntaxExtension(parser, "tasklist");
}

/**
 * @brief 将 cmark AST 节点递归转换为 MarkNode
 */
static MarkNode *nodeToMarkNode(cmark_node *node, QObject *parent)
{
    MarkNode *markNode = new MarkNode(parent);

    markNode->setType(QString::fromUtf8(cmark_node_get_type_string(node)));

    const char *literal = cmark_node_get_literal(node);
    if (literal) {
        markNode->setContent(QString::fromUtf8(literal));
    }

    if (cmark_node_get_type(node) == CMARK_NODE_HEADING) {
        markNode->setLevel(cmark_node_get_heading_level(node));
    }

    if (cmark_node_get_type(node) == CMARK_NODE_CODE_BLOCK) {
        const char *info = cmark_node_get_fence_info(node);
        if (info && info[0] != '\0') {
            markNode->setLanguage(QString::fromUtf8(info));
        }
    }

    if (cmark_node_get_type(node) == CMARK_NODE_LINK
        || cmark_node_get_type(node) == CMARK_NODE_IMAGE) {
        const char *url = cmark_node_get_url(node);
        const char *title = cmark_node_get_title(node);
        if (url)
            markNode->setUrl(QString::fromUtf8(url));
        if (title && title[0] != '\0')
            markNode->setTitle(QString::fromUtf8(title));
    }

    if (cmark_node_get_type(node) == CMARK_NODE_LIST) {
        markNode->setOrdered(cmark_node_get_list_type(node) == CMARK_ORDERED_LIST);
        markNode->setStart(cmark_node_get_list_start(node));
    }

    if (cmark_node_get_type(node) == CMARK_NODE_ITEM) {
        markNode->setTasklistChecked(cmark_gfm_extensions_get_tasklist_item_checked(node));
    }

    QString typeStr = markNode->type();
    if (typeStr == "table") {
        uint16_t cols = cmark_gfm_extensions_get_table_columns(node);
        markNode->setColumns(cols);
        uint8_t *aligns = cmark_gfm_extensions_get_table_alignments(node);
        if (aligns && cols > 0) {
            QVariantList alignments;
            for (uint16_t i = 0; i < cols; ++i) {
                alignments.append(static_cast<int>(aligns[i]));
            }
            markNode->setAlignments(alignments);
        }
    } else if (typeStr == "table_header" || typeStr == "table_row") {
        markNode->setIsHeader(cmark_gfm_extensions_get_table_row_is_header(node) == 1);
    }

    for (cmark_node *child = cmark_node_first_child(node); child;
         child = cmark_node_next(child)) {
        markNode->appendChild(nodeToMarkNode(child, markNode));
    }

    return markNode;
}

/**
 * @brief 将 cmark AST 渲染为 HTML 字符串
 */
static QString renderFromNode(cmark_node *doc, int options, cmark_parser *parser)
{
    QString result;
    if (doc) {
        cmark_mem *mem = cmark_get_default_mem_allocator();
        cmark_llist *extensions = cmark_parser_get_syntax_extensions(parser);
        char *html = cmark_render_html(doc, options, extensions);
        if (html) {
            result = QString::fromUtf8(html);
            mem->free(html);
        }
        cmark_node_free(doc);
    }
    return result;
}

// ---------------------------------------------------------------------------
// Mark 类实现
// ---------------------------------------------------------------------------

Mark::Mark(QObject *parent)
    : QObject(parent)
    , _options(CMARK_OPT_DEFAULT)
{
    cmark_gfm_core_extensions_ensure_registered();
}

Mark::~Mark() = default;

QString Mark::toHtml(const QString &markdown) const
{
    if (markdown.isEmpty()) {
        return QString();
    }

    cmark_parser *parser = cmark_parser_new(_options);
    if (!parser) {
        return QString();
    }

    setupParser(parser);

    const QByteArray utf8 = markdown.toUtf8();
    cmark_parser_feed(parser, utf8.constData(), utf8.size());
    cmark_node *doc = cmark_parser_finish(parser);

    QString result = renderFromNode(doc, _options, parser);
    cmark_parser_free(parser);
    return result;
}

MarkTree *Mark::parse(const QString &markdown) const
{
    MarkTree *tree = new MarkTree();

    if (markdown.isEmpty()) {
        return tree;
    }

    cmark_parser *parser = cmark_parser_new(_options);
    if (!parser) {
        return tree;
    }

    setupParser(parser);

    const QByteArray utf8 = markdown.toUtf8();
    cmark_parser_feed(parser, utf8.constData(), utf8.size());
    cmark_node *doc = cmark_parser_finish(parser);

    if (doc) {
        tree->setRoot(nodeToMarkNode(doc, tree));
        cmark_node_free(doc);
    }

    cmark_parser_free(parser);
    return tree;
}

MarkTree *Mark::parseFile(const QString &filePath) const
{
    QFile file(filePath);
    if (!file.open(QIODevice::ReadOnly | QIODevice::Text)) {
        qWarning() << "Failed to open file:" << filePath;
        return new MarkTree();
    }

    QTextStream in(&file);
    in.setEncoding(QStringConverter::Utf8);
    const QString content = in.readAll();
    file.close();

    return parse(content);
}

void Mark::setOptions(int options)
{
    _options = options;
}

int Mark::options() const
{
    return _options;
}
