#pragma once

#include <QObject>
#include <QQmlEngine>
#include <QString>

#include "MarkTree.h"

/**
 * @brief Markdown 解析器主类
 *
 * 封装 cmark-gfm 库，提供：
 *  1. toHtml() —— 直接输出 HTML 字符串
 *  2. parse() / parseFile() —— 输出 AST 树（MarkTree），供 QML 遍历渲染
 *
 * 继承 QObject 并注册为 QML 元素，可直接在 QML 中实例化使用。
 */
class Mark : public QObject
{
    Q_OBJECT
    QML_ELEMENT
public:
    explicit Mark(QObject *parent = nullptr);
    ~Mark() override;

    /**
     * @brief 将 Markdown 文本一次性转换为 HTML
     * @param markdown 输入的 Markdown 文本
     * @return 渲染后的 HTML 字符串
     */
    Q_INVOKABLE QString toHtml(const QString &markdown) const;

    /**
     * @brief 将 Markdown 文本一次性解析为 AST
     * @param markdown 输入的 Markdown 文本
     * @return AST 树（根节点 type 为 "document"）
     */
    Q_INVOKABLE MarkTree *parse(const QString &markdown) const;

    /**
     * @brief 从本地文件路径读取 Markdown 并解析为 AST
     * @param filePath 文件路径
     * @return AST 树；若文件打开失败则返回空树
     */
    Q_INVOKABLE MarkTree *parseFile(const QString &filePath) const;

    /**
     * @brief 设置 cmark 渲染选项
     * @param options 选项位掩码
     */
    void setOptions(int options);

    /**
     * @brief 获取当前渲染选项
     * @return 当前选项位掩码
     */
    int options() const;

private:
    int _options = 0;
};
