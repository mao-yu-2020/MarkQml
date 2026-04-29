#include "MarkNode.h"

// ---------------------------------------------------------------------------
// 构造
// ---------------------------------------------------------------------------

MarkNode::MarkNode(QObject *parent)
    : QObject(parent)
{
}

// ---------------------------------------------------------------------------
// Getter 实现
// ---------------------------------------------------------------------------

QString MarkNode::type() const
{
    return _type;
}

QString MarkNode::content() const
{
    return _content;
}

/**
 * @brief 将 QList<MarkNode*> 转换为 QVariantList
 *
 * QVariantList 可被 QML Repeater 直接作为 model 使用，
 * QML delegate 中通过 modelData 可访问到 MarkNode 的各个 Q_PROPERTY。
 */
QVariantList MarkNode::children() const
{
    QVariantList result;
    for (MarkNode *child : _children) {
        result.append(QVariant::fromValue(child));
    }
    return result;
}

int MarkNode::level() const
{
    return _level;
}

QString MarkNode::language() const
{
    return _language;
}

QString MarkNode::url() const
{
    return _url;
}

QString MarkNode::title() const
{
    return _title;
}

bool MarkNode::ordered() const
{
    return _ordered;
}

int MarkNode::start() const
{
    return _start;
}

bool MarkNode::tasklistChecked() const
{
    return _tasklistChecked;
}

int MarkNode::columns() const
{
    return _columns;
}

QVariantList MarkNode::alignments() const
{
    return _alignments;
}

bool MarkNode::isHeader() const
{
    return _isHeader;
}

// ---------------------------------------------------------------------------
// 便捷类型判断方法实现
// ---------------------------------------------------------------------------

bool MarkNode::isDocument() const { return _type == "document"; }
bool MarkNode::isBlockQuote() const { return _type == "block_quote"; }
bool MarkNode::isList() const { return _type == "list"; }
bool MarkNode::isItem() const { return _type == "item"; }
bool MarkNode::isCodeBlock() const { return _type == "code_block"; }
bool MarkNode::isHtmlBlock() const { return _type == "html_block"; }
bool MarkNode::isParagraph() const { return _type == "paragraph"; }
bool MarkNode::isHeading() const { return _type == "heading"; }
bool MarkNode::isThematicBreak() const { return _type == "thematic_break"; }
bool MarkNode::isFootnoteDefinition() const { return _type == "footnote_definition"; }
bool MarkNode::isText() const { return _type == "text"; }
bool MarkNode::isSoftbreak() const { return _type == "softbreak"; }
bool MarkNode::isLinebreak() const { return _type == "linebreak"; }
bool MarkNode::isCode() const { return _type == "code"; }
bool MarkNode::isHtmlInline() const { return _type == "html_inline"; }
bool MarkNode::isEmphasis() const { return _type == "emph"; }
bool MarkNode::isStrong() const { return _type == "strong"; }
bool MarkNode::isLink() const { return _type == "link"; }
bool MarkNode::isImage() const { return _type == "image"; }
bool MarkNode::isFootnoteReference() const { return _type == "footnote_reference"; }
bool MarkNode::isTable() const { return _type == "table"; }
bool MarkNode::isTableHeader() const { return _type == "table_header"; }
bool MarkNode::isTableRow() const { return _type == "table_row"; }
bool MarkNode::isTableCell() const { return _type == "table_cell"; }
bool MarkNode::isStrikethrough() const { return _type == "strikethrough"; }
bool MarkNode::isUnknown() const { return _type == "unknown"; }

MarkNode *MarkNode::parentNode() const
{
    // QObject::parent() 在 appendChild 时被设为当前节点的父 MarkNode，
    // 因此直接向上转型即可得到 AST 中的逻辑父节点。
    return qobject_cast<MarkNode *>(QObject::parent());
}

// ---------------------------------------------------------------------------
// Setter 实现（仅 C++ 构建 AST 时使用）
// ---------------------------------------------------------------------------

void MarkNode::setType(const QString &type)
{
    _type = type;
}

void MarkNode::setContent(const QString &content)
{
    _content = content;
}

void MarkNode::appendChild(MarkNode *child)
{
    if (child) {
        // 将子节点的 QObject parent 设为当前节点，
        // 这样当当前节点被销毁时，子节点会自动释放
        child->setParent(this);
        _children.append(child);
    }
}

void MarkNode::insertChild(int index, MarkNode *child)
{
    if (!child)
        return;

    child->setParent(this);

    if (index < 0 || index > _children.size()) {
        _children.append(child);
    } else {
        _children.insert(index, child);
    }
}

void MarkNode::removeChild(int index)
{
    if (index < 0 || index >= _children.size())
        return;

    MarkNode *child = _children.takeAt(index);
    if (child) {
        delete child;
    }
}

void MarkNode::removeChild(MarkNode *child)
{
    if (!child)
        return;

    int idx = _children.indexOf(child);
    if (idx >= 0) {
        _children.removeAt(idx);
        delete child;
    }
}

void MarkNode::clearChildren()
{
    // takeFirst + delete 确保逐个释放，避免迭代器失效
    while (!_children.isEmpty()) {
        MarkNode *child = _children.takeFirst();
        delete child;
    }
}

int MarkNode::childCount() const
{
    return _children.size();
}

MarkNode *MarkNode::childAt(int index) const
{
    if (index < 0 || index >= _children.size())
        return nullptr;
    return _children.at(index);
}

int MarkNode::indexOf(MarkNode *child) const
{
    return _children.indexOf(child);
}

void MarkNode::setLevel(int level)
{
    _level = level;
}

void MarkNode::setLanguage(const QString &language)
{
    _language = language;
}

void MarkNode::setUrl(const QString &url)
{
    _url = url;
}

void MarkNode::setTitle(const QString &title)
{
    _title = title;
}

void MarkNode::setOrdered(bool ordered)
{
    _ordered = ordered;
}

void MarkNode::setStart(int start)
{
    _start = start;
}

void MarkNode::setTasklistChecked(bool checked)
{
    _tasklistChecked = checked;
}

void MarkNode::setColumns(int columns)
{
    _columns = columns;
}

void MarkNode::setAlignments(const QVariantList &alignments)
{
    _alignments = alignments;
}

void MarkNode::setIsHeader(bool isHeader)
{
    _isHeader = isHeader;
}
