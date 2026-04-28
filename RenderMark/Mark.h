#pragma once

#include <QObject>
#include <QQmlEngine>
#include <QString>

#include "MarkTree.h"

// cmark-gfm 解析器的前向声明（避免在头文件中暴露 cmark 头文件）
struct cmark_parser;

/**
 * @brief Markdown 解析器主类
 *
 * 封装 cmark-gfm 库，提供两种输出方式：
 *  1. toHtml() —— 直接输出 HTML 字符串（快捷方式）
 *  2. parse() / begin()+feed()+end() —— 输出 AST 树（MarkTree），供 QML 遍历渲染
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
     * @brief 将 Markdown 文本一次性转换为 HTML（快捷方式）
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
     * @param filePath 文件路径（支持绝对路径和相对路径）
     * @return AST 树；若文件打开失败则返回空树
     */
    Q_INVOKABLE MarkTree *parseFile(const QString &filePath) const;

    /**
     * @brief 开始一次增量式解析会话
     *
     * 调用后会创建一个新的 cmark 解析器，后续可通过 feed() 分批追加文本。
     */
    Q_INVOKABLE void begin();

    /**
     * @brief 向当前解析会话追加 Markdown 文本
     * @param markdown 要追加的 Markdown 片段
     *
     * 必须在 begin() 之后、end() 之前调用。
     */
    Q_INVOKABLE void feed(const QString &markdown);

    /**
     * @brief 结束解析会话，返回 AST 树
     * @return AST 树（根节点 type 为 "document"）
     *
     * 调用后会释放当前解析器，解析器不可再用。
     */
    Q_INVOKABLE MarkTree *end();

    /**
     * @brief 设置 cmark 渲染选项（如 CMARK_OPT_UNSAFE 等）
     * @param options 选项位掩码，参考 cmark-gfm 的 CMARK_OPT_* 常量
     */
    void setOptions(int options);

    /**
     * @brief 获取当前渲染选项
     * @return 当前选项位掩码
     */
    int options() const;

private:
    // cmark 渲染选项（默认 CMARK_OPT_DEFAULT == 0）
    int _options = 0;

    // 增量式解析时持有的 cmark 解析器实例（begin() 创建，end() 释放）
    cmark_parser *_parser = nullptr;
};
