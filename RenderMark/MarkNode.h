#pragma once

#include <QObject>
#include <QQmlEngine>
#include <QString>
#include <QVariantList>

/**
 * @brief AST 单个节点类
 *
 * 代表 Markdown 抽象语法树中的一个节点（如 heading、paragraph、text、link 等）。
 * 继承 QObject 并注册为 QML 元素，QML 可直接访问其属性来渲染对应 UI 元素。
 */
class MarkNode : public QObject
{
    Q_OBJECT
    QML_ELEMENT

    // -----------------------------------------------------------------------
    // QML 可读属性（均为 CONSTANT，树构建完成后不再变化）
    // -----------------------------------------------------------------------

    /** @brief 节点类型字符串，如 "document"、"heading"、"paragraph"、"text"、"table" 等 */
    Q_PROPERTY(QString type READ type CONSTANT)

    /** @brief 纯文本内容，仅 text/code/code_block 等节点有效 */
    Q_PROPERTY(QString content READ content CONSTANT)

    /**
     * @brief 子节点列表
     * @return QVariantList，每个元素为 MarkNode*（QML 中可用 modelData 访问）
     */
    Q_PROPERTY(QVariantList children READ children CONSTANT)

    /** @brief 标题级别（h1~h6），仅 heading 节点有效 */
    Q_PROPERTY(int level READ level CONSTANT)

    /** @brief 代码块语言标识（如 "cpp"、"js"），仅 code_block 节点有效 */
    Q_PROPERTY(QString language READ language CONSTANT)

    /** @brief 链接/图片 URL，仅 link/image 节点有效 */
    Q_PROPERTY(QString url READ url CONSTANT)

    /** @brief 链接/图片标题文本，仅 link/image 节点有效 */
    Q_PROPERTY(QString title READ title CONSTANT)

    /** @brief 列表是否为有序列表（true=有序，false=无序），仅 list 节点有效 */
    Q_PROPERTY(bool ordered READ ordered CONSTANT)

    /** @brief 有序列表起始序号，仅 list 节点有效 */
    Q_PROPERTY(int start READ start CONSTANT)

    /** @brief 任务列表项是否勾选，仅 item 节点且为任务列表时有效 */
    Q_PROPERTY(bool tasklistChecked READ tasklistChecked CONSTANT)

    /** @brief 表格列数，仅 table 节点有效 */
    Q_PROPERTY(int columns READ columns CONSTANT)

    /**
     * @brief 表格每列对齐方式列表
     * @return QVariantList<int>，值为 0=左对齐, 1=居中, 2=右对齐，仅 table 节点有效
     */
    Q_PROPERTY(QVariantList alignments READ alignments CONSTANT)

    /** @brief 表格行是否为表头行，仅 table_header/table_row 节点有效 */
    Q_PROPERTY(bool isHeader READ isHeader CONSTANT)

    /**
     * @brief 逻辑父节点（AST 树中的父 MarkNode）
     * @return 父节点指针；若当前节点为根节点或其 QObject parent 不是 MarkNode，则返回 nullptr
     */
    Q_PROPERTY(MarkNode *parentNode READ parentNode CONSTANT)

public:
    explicit MarkNode(QObject *parent = nullptr);

    // -----------------------------------------------------------------------
    // Getter（供 Q_PROPERTY 和 C++ 使用）
    // -----------------------------------------------------------------------
    QString type() const;
    QString content() const;
    QVariantList children() const;
    int level() const;
    QString language() const;
    QString url() const;
    QString title() const;
    bool ordered() const;
    int start() const;
    bool tasklistChecked() const;
    int columns() const;
    QVariantList alignments() const;
    bool isHeader() const;

    // -----------------------------------------------------------------------
    // 便捷类型判断方法（对 type() == "xxx" 的包装，方便 QML/C++ 使用）
    // -----------------------------------------------------------------------
    Q_INVOKABLE bool isDocument() const;
    Q_INVOKABLE bool isBlockQuote() const;
    Q_INVOKABLE bool isList() const;
    Q_INVOKABLE bool isItem() const;
    Q_INVOKABLE bool isCodeBlock() const;
    Q_INVOKABLE bool isHtmlBlock() const;
    Q_INVOKABLE bool isParagraph() const;
    Q_INVOKABLE bool isHeading() const;
    Q_INVOKABLE bool isThematicBreak() const;
    Q_INVOKABLE bool isFootnoteDefinition() const;
    Q_INVOKABLE bool isText() const;
    Q_INVOKABLE bool isSoftbreak() const;
    Q_INVOKABLE bool isLinebreak() const;
    Q_INVOKABLE bool isCode() const;
    Q_INVOKABLE bool isHtmlInline() const;
    Q_INVOKABLE bool isEmphasis() const;
    Q_INVOKABLE bool isStrong() const;
    Q_INVOKABLE bool isLink() const;
    Q_INVOKABLE bool isImage() const;
    Q_INVOKABLE bool isFootnoteReference() const;
    Q_INVOKABLE bool isTable() const;
    Q_INVOKABLE bool isTableHeader() const;
    Q_INVOKABLE bool isTableRow() const;
    Q_INVOKABLE bool isTableCell() const;
    Q_INVOKABLE bool isStrikethrough() const;
    Q_INVOKABLE bool isUnknown() const;

    /** @return 当前节点的逻辑父节点（AST 父节点），若无则返回 nullptr */
    MarkNode *parentNode() const;

    // -----------------------------------------------------------------------
    // Setter（仅在 C++ 构建 AST 时内部使用，不暴露给 QML）
    // -----------------------------------------------------------------------
    void setType(const QString &type);
    void setContent(const QString &content);

    /**
     * @brief 追加子节点到末尾
     * @param child 子节点指针
     *
     * 会自动将 child 的 QObject parent 设为当前节点，确保随父节点自动销毁。
     */
    void appendChild(MarkNode *child);

    /**
     * @brief 在指定位置插入子节点
     * @param index 插入位置索引（0 表示头部）
     * @param child 子节点指针
     *
     * 若 index 越界，则等效于 appendChild。
     */
    void insertChild(int index, MarkNode *child);

    /**
     * @brief 移除指定索引的子节点并释放内存
     * @param index 子节点索引
     *
     * 若 index 越界，无任何操作。
     */
    void removeChild(int index);

    /**
     * @brief 移除指定的子节点并释放内存
     * @param child 子节点指针
     *
     * 若 child 不在列表中，无任何操作。
     */
    void removeChild(MarkNode *child);

    /** @brief 移除并释放所有子节点 */
    void clearChildren();

    /** @return 当前子节点数量 */
    int childCount() const;

    /**
     * @brief 获取指定索引的子节点
     * @param index 索引
     * @return 子节点指针；越界时返回 nullptr
     */
    MarkNode *childAt(int index) const;

    /**
     * @brief 查找子节点在当前列表中的索引
     * @param child 子节点指针
     * @return 索引值，找不到返回 -1
     */
    int indexOf(MarkNode *child) const;

    void setLevel(int level);
    void setLanguage(const QString &language);
    void setUrl(const QString &url);
    void setTitle(const QString &title);
    void setOrdered(bool ordered);
    void setStart(int start);
    void setTasklistChecked(bool checked);
    void setColumns(int columns);
    void setAlignments(const QVariantList &alignments);
    void setIsHeader(bool isHeader);

private:
    QString _type;                /**< 节点类型 */
    QString _content;             /**< 纯文本内容 */
    QList<MarkNode *> _children;  /**< 子节点列表（树形结构） */
    int _level = 0;               /**< 标题级别 */
    QString _language;            /**< 代码块语言 */
    QString _url;                 /**< 链接/图片 URL */
    QString _title;               /**< 链接/图片标题 */
    bool _ordered = false;        /**< 列表是否有序 */
    int _start = 0;               /**< 有序列表起始序号 */
    bool _tasklistChecked = false;/**< 任务列表勾选状态 */
    int _columns = 0;             /**< 表格列数 */
    QVariantList _alignments;     /**< 表格列对齐方式 */
    bool _isHeader = false;       /**< 表格行是否为表头 */
};
