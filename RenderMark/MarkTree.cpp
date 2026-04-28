#include "MarkTree.h"

#include <QVariantList>

// ---------------------------------------------------------------------------
// 构造 / 析构
// ---------------------------------------------------------------------------

MarkTree::MarkTree(QObject *parent)
    : QObject(parent)
{
}

MarkTree::~MarkTree()
{
    // 若根节点的 parent 是当前 MarkTree，则主动释放，
    // 连带释放整棵子树（因为每个 MarkNode 的子节点 parent 都指向父节点）
    if (_root && _root->parent() == this) {
        delete _root;
    }
}

// ---------------------------------------------------------------------------
// 根节点访问
// ---------------------------------------------------------------------------

MarkNode *MarkTree::root() const
{
    return _root;
}

void MarkTree::setRoot(MarkNode *root)
{
    // 释放旧根节点（避免内存泄漏）
    if (_root && _root->parent() == this) {
        delete _root;
    }

    _root = root;

    // 将新根节点的 parent 设为当前 MarkTree，
    // 这样 MarkTree 析构时会自动释放整棵树
    if (_root) {
        _root->setParent(this);
    }
}

// ---------------------------------------------------------------------------
// 树形结构查询
// ---------------------------------------------------------------------------

/**
 * @brief 递归计算以 node 为根的子树最大深度
 * @param node 当前子树根节点
 * @return 子树深度（叶子节点返回 1）
 */
int MarkTree::nodeDepth(MarkNode *node)
{
    if (!node)
        return 0;

    const QVariantList children = node->children();
    if (children.isEmpty())
        return 1;

    int maxChildDepth = 0;
    for (const QVariant &v : children) {
        MarkNode *child = v.value<MarkNode *>();
        if (child) {
            maxChildDepth = qMax(maxChildDepth, nodeDepth(child));
        }
    }
    return 1 + maxChildDepth;
}

int MarkTree::depth() const
{
    return nodeDepth(_root);
}

/**
 * @brief 深度优先搜索，查找 target 节点的深度
 * @param current 当前遍历到的节点
 * @param target 要查找的目标节点
 * @param currentDepth 当前节点的深度（根节点传入 1）
 * @param foundDepth 输出参数，找到后写入目标深度
 * @return 是否找到目标节点
 */
bool MarkTree::findNodeDepth(MarkNode *current, MarkNode *target, int currentDepth, int &foundDepth)
{
    if (!current || !target)
        return false;

    if (current == target) {
        foundDepth = currentDepth;
        return true;
    }

    const QVariantList children = current->children();
    for (const QVariant &v : children) {
        MarkNode *child = v.value<MarkNode *>();
        if (child && findNodeDepth(child, target, currentDepth + 1, foundDepth)) {
            return true;
        }
    }
    return false;
}

int MarkTree::depthOf(MarkNode *node) const
{
    if (!_root || !node)
        return -1;

    int foundDepth = -1;
    if (findNodeDepth(_root, node, 1, foundDepth)) {
        return foundDepth;
    }
    return -1;
}

// ---------------------------------------------------------------------------
// 遍历与搜索
// ---------------------------------------------------------------------------

/**
 * @brief 递归前序遍历，将所有节点追加到 out 列表
 * @param node 当前节点
 * @param out 输出列表
 */
void MarkTree::collectFlatten(MarkNode *node, QList<MarkNode *> &out)
{
    if (!node)
        return;

    out.append(node);

    const QVariantList children = node->children();
    for (const QVariant &v : children) {
        MarkNode *child = v.value<MarkNode *>();
        if (child) {
            collectFlatten(child, out);
        }
    }
}

QList<MarkNode *> MarkTree::flatten() const
{
    QList<MarkNode *> result;
    if (_root) {
        collectFlatten(_root, result);
    }
    return result;
}

/**
 * @brief 递归收集所有类型匹配的节点
 * @param node 当前节点
 * @param type 目标类型字符串
 * @param out 输出列表
 */
void MarkTree::collectByType(MarkNode *node, const QString &type, QList<MarkNode *> &out)
{
    if (!node)
        return;

    if (node->type() == type) {
        out.append(node);
    }

    const QVariantList children = node->children();
    for (const QVariant &v : children) {
        MarkNode *child = v.value<MarkNode *>();
        if (child) {
            collectByType(child, type, out);
        }
    }
}

QList<MarkNode *> MarkTree::findAll(const QString &type) const
{
    QList<MarkNode *> result;
    if (_root) {
        collectByType(_root, type, result);
    }
    return result;
}

/**
 * @brief 递归查找第一个匹配类型的节点
 * @param node 当前节点
 * @param type 目标类型
 * @return 第一个匹配的节点指针；找不到返回 nullptr
 */
static MarkNode *findFirstByType(MarkNode *node, const QString &type)
{
    if (!node)
        return nullptr;

    if (node->type() == type)
        return node;

    const QVariantList children = node->children();
    for (const QVariant &v : children) {
        MarkNode *child = v.value<MarkNode *>();
        MarkNode *found = findFirstByType(child, type);
        if (found)
            return found;
    }
    return nullptr;
}

MarkNode *MarkTree::findFirst(const QString &type) const
{
    return findFirstByType(_root, type);
}

/**
 * @brief 递归判断树中是否包含指定节点
 * @param current 当前遍历节点
 * @param target 目标节点
 * @return true 表示找到
 */
static bool treeContains(MarkNode *current, MarkNode *target)
{
    if (!current || !target)
        return false;

    if (current == target)
        return true;

    const QVariantList children = current->children();
    for (const QVariant &v : children) {
        MarkNode *child = v.value<MarkNode *>();
        if (treeContains(child, target))
            return true;
    }
    return false;
}

bool MarkTree::contains(MarkNode *node) const
{
    return treeContains(_root, node);
}

// ---------------------------------------------------------------------------
// 节点增删改（C++ 后处理使用）
// ---------------------------------------------------------------------------

void MarkTree::removeNode(MarkNode *node)
{
    if (!node)
        return;

    // 若移除的是根节点，直接清空根
    if (node == _root) {
        setRoot(nullptr);
        return;
    }

    // 通过 parentNode() 定位到父节点，从父节点的 children 中移除
    MarkNode *parent = node->parentNode();
    if (parent) {
        parent->removeChild(node);
    }
}

void MarkTree::replaceNode(MarkNode *oldNode, MarkNode *newNode)
{
    if (!oldNode || !newNode || oldNode == newNode)
        return;

    // 替换根节点
    if (oldNode == _root) {
        setRoot(newNode);
        return;
    }

    // 通过父节点定位并替换
    MarkNode *parent = oldNode->parentNode();
    if (!parent)
        return;

    int idx = parent->indexOf(oldNode);
    if (idx < 0)
        return;

    // 移除旧节点（不释放，因为 newNode 要复用位置）
    // 但这里需要先把 oldNode 从列表中拿出来
    parent->removeChild(idx);  // 这会释放 oldNode

    // 在同样位置插入新节点
    parent->insertChild(idx, newNode);
}

// ---------------------------------------------------------------------------
// 调试输出
// ---------------------------------------------------------------------------

/**
 * @brief 递归追加节点的字符串表示到输出文本
 * @param node 当前节点
 * @param out 输出字符串
 * @param indent 当前缩进层级（每层 2 个空格）
 */
void MarkTree::appendNodeString(MarkNode *node, QString &out, int indent)
{
    if (!node)
        return;

    QString prefix(indent * 2, ' ');
    out += prefix + node->type();

    // 附加关键属性信息，方便一眼识别
    if (node->isHeading()) {
        out += QString(" (level=%1)").arg(node->level());
    } else if (node->isCodeBlock() && !node->language().isEmpty()) {
        out += QString(" [lang=%1]").arg(node->language());
    } else if (node->isLink() || node->isImage()) {
        out += QString(" (url=%1)").arg(node->url());
    } else if (node->isList()) {
        out += QString(" (ordered=%1, start=%2)").arg(node->ordered()).arg(node->start());
    } else if (node->isTable()) {
        out += QString(" (cols=%1)").arg(node->columns());
    } else if (!node->content().isEmpty()) {
        out += QString(": \"%1\"").arg(node->content());
    }
    out += "\n";

    // 递归处理子节点
    const QVariantList children = node->children();
    for (const QVariant &v : children) {
        MarkNode *child = v.value<MarkNode *>();
        if (child) {
            appendNodeString(child, out, indent + 1);
        }
    }
}

QString MarkTree::printTree() const
{
    if (!_root)
        return "(empty tree)\n";

    QString result;
    appendNodeString(_root, result, 0);
    return result;
}
