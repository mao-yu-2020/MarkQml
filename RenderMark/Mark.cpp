#include "Mark.h"
#include "MarkTree.h"
#include "MarkNode.h"

#include <QFile>
#include <QHash>
#include <QRegularExpression>
#include <QTextStream>
#include <QVector>

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
    attachSyntaxExtension(parser, "autolink");
    attachSyntaxExtension(parser, "tagfilter");
    attachSyntaxExtension(parser, "tasklist");
}

namespace {

struct MathPlaceholder
{
    QString token;
    QString formula;
};

bool insideRanges(const QVector<QPair<int, int>> &ranges, int position)
{
    for (const auto &range : ranges) {
        if (position >= range.first && position < range.second)
            return true;
    }
    return false;
}

QVector<QPair<int, int>> fencedCodeRanges(const QString &markdown)
{
    QVector<QPair<int, int>> ranges;
    const QStringList lines = markdown.split(QLatin1Char('\n'), Qt::KeepEmptyParts);
    const QRegularExpression fenceRe(QStringLiteral("^\\s{0,3}(`{3,}|~{3,})"));

    QString openMarker;
    int openStart = 0;
    int offset = 0;

    for (const QString &line : lines) {
        const QRegularExpressionMatch match = fenceRe.match(line);
        if (openMarker.isEmpty()) {
            if (match.hasMatch()) {
                openMarker = match.captured(1);
                openStart = offset;
            }
        } else if (match.hasMatch()) {
            const QString marker = match.captured(1);
            if (!marker.isEmpty() && marker.at(0) == openMarker.at(0)
                && marker.size() >= openMarker.size()
                && line.mid(match.capturedEnd(1)).trimmed().isEmpty()) {
                ranges.append(qMakePair(openStart, offset + line.size()));
                openMarker.clear();
            }
        }
        offset += line.size() + 1;
    }

    if (!openMarker.isEmpty())
        ranges.append(qMakePair(openStart, markdown.size()));
    return ranges;
}

QString protectMath(const QString &markdown, QHash<QString, QString> &replacements)
{
    const QRegularExpression mathRe(QStringLiteral(R"(\$\$([\s\S]*?)\$\$|\\\[([\s\S]*?)\\\])"));
    const QVector<QPair<int, int>> codeRanges = fencedCodeRanges(markdown);

    QString result;
    result.reserve(markdown.size());
    int last = 0;
    int index = 0;

    auto it = mathRe.globalMatch(markdown);
    while (it.hasNext()) {
        const QRegularExpressionMatch match = it.next();
        if (insideRanges(codeRanges, match.capturedStart()))
            continue;

        QString formula = match.captured(1);
        if (formula.isNull())
            formula = match.captured(2);
        if (formula.isNull())
            continue;

        const QString token = QString(QChar(0xE000)) + QStringLiteral("M%1").arg(index++)
            + QString(QChar(0xE001));
        replacements.insert(token, QStringLiteral("$$%1$$").arg(formula));
        result += markdown.mid(last, match.capturedStart() - last);
        result += token;
        last = match.capturedEnd();
    }

    result += markdown.mid(last);
    return result;
}

QString restorePlaceholders(const QString &text, const QHash<QString, QString> &replacements)
{
    int marker = text.indexOf(QChar(0xE000));
    if (marker < 0)
        return text;

    QString restored;
    restored.reserve(text.size());
    int last = 0;

    while (marker >= 0) {
        const int end = text.indexOf(QChar(0xE001), marker + 1);
        if (end < 0)
            break;

        const auto it = replacements.constFind(text.mid(marker, end - marker + 1));
        if (it != replacements.cend()) {
            restored += text.mid(last, marker - last);
            restored += it.value();
            last = end + 1;
        }
        marker = text.indexOf(QChar(0xE000), end + 1);
    }

    if (last == 0)
        return text;

    restored += text.mid(last);
    return restored;
}

void restoreMath(MarkNode *node, const QHash<QString, QString> &replacements)
{
    if (!node)
        return;

    // Placeholders can end up in text, code spans/blocks, HTML literals, link
    // destinations, and titles depending on how cmark parsed the protected
    // source. Restore every text-bearing field so protected math never leaks
    // into the rendered document.
    const QString content = node->content();
    if (!content.isEmpty()) {
        const QString restored = restorePlaceholders(content, replacements);
        if (restored != content)
            node->setContent(restored);
    }

    const QString url = node->url();
    if (!url.isEmpty()) {
        const QString restored = restorePlaceholders(url, replacements);
        if (restored != url)
            node->setUrl(restored);
    }

    const QString title = node->title();
    if (!title.isEmpty()) {
        const QString restored = restorePlaceholders(title, replacements);
        if (restored != title)
            node->setTitle(restored);
    }

    const QVariantList children = node->children();
    for (const QVariant &child : children) {
        if (auto *childNode = child.value<MarkNode *>())
            restoreMath(childNode, replacements);
    }
}

} // namespace

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
                // cmark-gfm stores alignments as 'l'/'c'/'r' (or 0 for the
                // default). Normalize to 0=left, 1=center, 2=right so QML
                // consumers do not depend on the C implementation character
                // encoding.
                int alignment = 0;
                switch (aligns[i]) {
                case 'c':
                    alignment = 1;
                    break;
                case 'r':
                    alignment = 2;
                    break;
                case 'l':
                default:
                    alignment = 0;
                    break;
                }
                alignments.append(alignment);
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

    QHash<QString, QString> mathReplacements;
    const QString protectedMarkdown = protectMath(markdown, mathReplacements);

    cmark_parser *parser = cmark_parser_new(_options);
    if (!parser) {
        return tree;
    }

    setupParser(parser);

    const QByteArray utf8 = protectedMarkdown.toUtf8();
    cmark_parser_feed(parser, utf8.constData(), utf8.size());
    cmark_node *doc = cmark_parser_finish(parser);

    if (doc) {
        MarkNode *root = nodeToMarkNode(doc, tree);
        if (!mathReplacements.isEmpty())
            restoreMath(root, mathReplacements);
        tree->setRoot(root);
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
