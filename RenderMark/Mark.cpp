#include "Mark.h"
#include "MarkTree.h"
#include "MarkNode.h"

#include <QFile>
#include <QTextStream>

#include <cmark-gfm.h>
#include <cmark-gfm-core-extensions.h>

/**
 * @brief 为 cmark 解析器附加指定名称的语法扩展
 * @param parser cmark 解析器实例
 * @param name 扩展名称，如 "table"、"strikethrough" 等
 *
 * 如果扩展不存在，静默跳过（不会报错）。
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
 * @param parser cmark 解析器实例
 *
 * 附加的扩展包括：table（表格）、strikethrough（删除线）、autolinks（自动链接）、
 * tagfilter（标签过滤）、tasklist（任务列表）。
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
 * @param node cmark 原始 AST 节点
 * @param parent 新创建的 MarkNode 的 QObject 父对象（用于内存管理）
 * @return 转换后的 MarkNode 实例
 *
 * 该函数会递归处理 node 的所有子节点，构建完整的树形结构。
 */
static MarkNode *nodeToMarkNode(cmark_node *node, QObject *parent)
{
    MarkNode *markNode = new MarkNode(parent);

    // 节点类型字符串，如 "heading"、"paragraph"、"text"、"table" 等
    markNode->setType(QString::fromUtf8(cmark_node_get_type_string(node)));

    // 纯文本内容（仅 text/code/code_block 等节点有）
    const char *literal = cmark_node_get_literal(node);
    if (literal) {
        markNode->setContent(QString::fromUtf8(literal));
    }

    // 标题节点：提取级别 h1~h6
    if (cmark_node_get_type(node) == CMARK_NODE_HEADING) {
        markNode->setLevel(cmark_node_get_heading_level(node));
    }

    // 代码块节点：提取围栏信息（如 ```cpp 中的 "cpp"）
    if (cmark_node_get_type(node) == CMARK_NODE_CODE_BLOCK) {
        const char *info = cmark_node_get_fence_info(node);
        if (info && info[0] != '\0') {
            markNode->setLanguage(QString::fromUtf8(info));
        }
    }

    // 链接 / 图片节点：提取 URL 和标题
    if (cmark_node_get_type(node) == CMARK_NODE_LINK
        || cmark_node_get_type(node) == CMARK_NODE_IMAGE) {
        const char *url = cmark_node_get_url(node);
        const char *title = cmark_node_get_title(node);
        if (url)
            markNode->setUrl(QString::fromUtf8(url));
        if (title && title[0] != '\0')
            markNode->setTitle(QString::fromUtf8(title));
    }

    // 列表节点：提取有序/无序、起始序号
    if (cmark_node_get_type(node) == CMARK_NODE_LIST) {
        markNode->setOrdered(cmark_node_get_list_type(node) == CMARK_ORDERED_LIST);
        markNode->setStart(cmark_node_get_list_start(node));
    }

    // 列表项节点：提取任务列表勾选状态（若非任务列表则返回 false）
    if (cmark_node_get_type(node) == CMARK_NODE_ITEM) {
        markNode->setTasklistChecked(cmark_gfm_extensions_get_tasklist_item_checked(node));
    }

    // 表格扩展节点：提取列数、对齐方式、表头标记
    QString typeStr = markNode->type();
    if (typeStr == "table") {
        // 表格总列数
        uint16_t cols = cmark_gfm_extensions_get_table_columns(node);
        markNode->setColumns(cols);
        // 每列对齐方式（0=左, 1=居中, 2=右）
        uint8_t *aligns = cmark_gfm_extensions_get_table_alignments(node);
        if (aligns && cols > 0) {
            QVariantList alignments;
            for (uint16_t i = 0; i < cols; ++i) {
                alignments.append(static_cast<int>(aligns[i]));
            }
            markNode->setAlignments(alignments);
        }
    } else if (typeStr == "table_header" || typeStr == "table_row") {
        // 标记该行是否为表头行
        markNode->setIsHeader(cmark_gfm_extensions_get_table_row_is_header(node) == 1);
    }

    // 递归转换所有子节点，子节点的 parent 设为当前 markNode
    for (cmark_node *child = cmark_node_first_child(node); child;
         child = cmark_node_next(child)) {
        markNode->appendChild(nodeToMarkNode(child, markNode));
    }

    return markNode;
}

/**
 * @brief 将 cmark AST 渲染为 HTML 字符串
 * @param doc cmark document 节点
 * @param options cmark 渲染选项
 * @param parser 当前使用的 cmark 解析器（用于获取已附加的扩展列表）
 * @return HTML 字符串
 *
 * 调用后 doc 节点会被释放，parser 由调用者释放。
 */
static QString renderFromNode(cmark_node *doc, int options, cmark_parser *parser)
{
    QString result;
    if (doc) {
        cmark_mem *mem = cmark_get_default_mem_allocator();
        // 获取解析器上附加的所有语法扩展列表
        cmark_llist *extensions = cmark_parser_get_syntax_extensions(parser);
        // 渲染为 HTML
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
    // 注册所有 GFM 核心扩展（全局初始化，线程安全由 cmark-gfm 保证）
    cmark_gfm_core_extensions_ensure_registered();
}

Mark::~Mark()
{
    // 析构时若增量解析器未释放，则主动释放
    if (_parser) {
        cmark_parser_free(_parser);
    }
}

QString Mark::toHtml(const QString &markdown) const
{
    if (markdown.isEmpty()) {
        return QString();
    }

    // 创建临时解析器
    cmark_parser *parser = cmark_parser_new(_options);
    if (!parser) {
        return QString();
    }

    setupParser(parser);

    // 喂入 Markdown 文本
    const QByteArray utf8 = markdown.toUtf8();
    cmark_parser_feed(parser, utf8.constData(), utf8.size());
    // 完成解析，得到 document 节点
    cmark_node *doc = cmark_parser_finish(parser);

    // 渲染为 HTML
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

    // 创建临时解析器
    cmark_parser *parser = cmark_parser_new(_options);
    if (!parser) {
        return tree;
    }

    setupParser(parser);

    // 喂入 Markdown 文本并完成解析
    const QByteArray utf8 = markdown.toUtf8();
    cmark_parser_feed(parser, utf8.constData(), utf8.size());
    cmark_node *doc = cmark_parser_finish(parser);

    // 将 cmark AST 递归转换为 MarkNode，并设为 MarkTree 的根节点
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

void Mark::begin()
{
    // 若已有增量解析器，先释放
    if (_parser) {
        cmark_parser_free(_parser);
    }

    // 创建新的增量解析器，并附加 GFM 扩展
    _parser = cmark_parser_new(_options);
    if (_parser) {
        setupParser(_parser);
    }
}

void Mark::feed(const QString &markdown)
{
    // 只有在 begin() 成功创建了解析器后才可 feed
    if (!_parser || markdown.isEmpty()) {
        return;
    }

    const QByteArray utf8 = markdown.toUtf8();
    cmark_parser_feed(_parser, utf8.constData(), utf8.size());
}

MarkTree *Mark::end()
{
    MarkTree *tree = new MarkTree();

    // 若未调用 begin()，返回空树
    if (!_parser) {
        return tree;
    }

    // 完成解析，得到 document 节点
    cmark_node *doc = cmark_parser_finish(_parser);
    if (doc) {
        tree->setRoot(nodeToMarkNode(doc, tree));
        cmark_node_free(doc);
    }

    // 释放解析器并置空
    cmark_parser_free(_parser);
    _parser = nullptr;

    return tree;
}

void Mark::setOptions(int options)
{
    _options = options;
}

int Mark::options() const
{
    return _options;
}
