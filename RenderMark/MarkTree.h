#pragma once

#include <QObject>
#include <QQmlEngine>

#include "MarkNode.h"

/**
 * @brief AST 树容器类
 *
 * 作为 Mark::parse() / Mark::end() 的返回结果，
 * 内部持有一个根 MarkNode（type 通常为 "document"），
 * QML 通过 root 属性访问整棵 AST 树。
 */
class MarkTree : public QObject
{
    Q_OBJECT
    QML_ELEMENT

    /** @brief AST 根节点，type 通常为 "document"，其 children 为顶层块元素 */
    Q_PROPERTY(MarkNode *root READ root CONSTANT)

public:
    explicit MarkTree(QObject *parent = nullptr);
    ~MarkTree() override;

    /** @return 当前 AST 根节点指针 */
    MarkNode *root() const;

    /**
     * @brief 设置 AST 根节点
     * @param root 根节点指针
     *
     * 调用后会将旧根节点销毁（若其 parent 为当前 MarkTree），
     * 并将新根节点的 parent 设为当前 MarkTree。
     */
    void setRoot(MarkNode *root);

    // -----------------------------------------------------------------------
    // 树形结构查询
    // -----------------------------------------------------------------------

    /**
     * @brief 整棵树的最大深度
     * @return 深度值，根节点深度为 1；空树返回 0
     */
    Q_INVOKABLE int depth() const;

    /**
     * @brief 查询指定节点在树中的深度
     * @param node 目标节点
     * @return 深度值（根节点为 1）；若节点不在树中返回 -1
     */
    Q_INVOKABLE int depthOf(MarkNode *node) const;

    // -----------------------------------------------------------------------
    // 遍历与搜索
    // -----------------------------------------------------------------------

    /**
     * @brief 前序遍历展平整棵树
     * @return 包含所有节点的列表（父节点在前，子节点在后）
     *
     * QML 中可用 Repeater 直接遍历返回的列表。
     */
    Q_INVOKABLE QList<MarkNode *> flatten() const;

    /**
     * @brief 按类型查找所有节点
     * @param type 节点类型字符串，如 "heading"、"link" 等
     * @return 匹配类型的节点列表
     */
    Q_INVOKABLE QList<MarkNode *> findAll(const QString &type) const;

    /**
     * @brief 查找第一个匹配类型的节点（前序遍历）
     * @param type 节点类型字符串
     * @return 第一个匹配的节点；找不到返回 nullptr
     */
    Q_INVOKABLE MarkNode *findFirst(const QString &type) const;

    /**
     * @brief 判断指定节点是否在这棵树中
     * @param node 目标节点
     * @return true 表示在树中
     */
    Q_INVOKABLE bool contains(MarkNode *node) const;

    // -----------------------------------------------------------------------
    // 节点增删改（C++ 后处理使用，QML 属性仍为 CONSTANT）
    // -----------------------------------------------------------------------

    /**
     * @brief 从树中移除指定节点并释放内存
     * @param node 要移除的节点
     *
     * 会自动从该节点的父节点的 children 中移除。
     * 若 node 是根节点，则将根置为空。
     */
    void removeNode(MarkNode *node);

    /**
     * @brief 替换树中的某个节点
     * @param oldNode 被替换的旧节点
     * @param newNode 新节点
     *
     * 新节点会继承 oldNode 在父节点 children 中的位置。
     * 若 oldNode 是根节点，则直接替换根。
     */
    void replaceNode(MarkNode *oldNode, MarkNode *newNode);

    // -----------------------------------------------------------------------
    // 调试输出
    // -----------------------------------------------------------------------

    /**
     * @brief 打印整棵树的结构到字符串
     * @return 带缩进的文本表示，方便在控制台或日志中查看
     *
     * 输出格式示例：
     *   document
     *     heading (level=1)
     *       text: "Hello"
     *     paragraph
     *       strong
     *         text: "World"
     */
    Q_INVOKABLE QString printTree() const;

private:
    MarkNode *_root = nullptr; /**< AST 根节点 */

    // 递归辅助函数
    static int nodeDepth(MarkNode *node);
    static bool findNodeDepth(MarkNode *current, MarkNode *target, int currentDepth, int &foundDepth);
    static void collectFlatten(MarkNode *node, QList<MarkNode *> &out);
    static void collectByType(MarkNode *node, const QString &type, QList<MarkNode *> &out);
    static void appendNodeString(MarkNode *node, QString &out, int indent);
};
