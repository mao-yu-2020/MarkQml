# MarkQml 复杂测试文档

> 这是外层引用块，包含**粗体**和*斜体*。
> 
> 第二段引用，带有`行内代码`和[Qt 官网](https://www.qt.io)。
>
> > 嵌套引用块，内部有 ~~删除线~~ 文本。
>
> - 引用块内的无序列表项
> - 另一个列表项，`code inside list`

---

## 1. 六级标题全展示

# H1: 项目总览
## H2: 核心模块
### H3: 解析器
#### H4: AST 节点
##### H5: 渲染管线
###### H6: 工具函数

## 2. 行内样式组合

这是**纯粗体**，这是*纯斜体*，这是~~纯删除线~~。

**粗体里有*斜体*和`代码`以及[链接](https://www.qt.io)**。

*斜体里有**粗体**和~~删除线~~*。

`代码里有**粗体**吗？没有，代码就是纯文本`。

## 3. 多语言代码块

### Python

```python
def fibonacci(n):
    if n <= 1:
        return n
    a, b = 0, 1
    for _ in range(2, n + 1):
        a, b = b, a + b
    return b

print(fibonacci(10))  # 55
```

### JavaScript

```javascript
const fetchData = async () => {
    try {
        const res = await fetch('https://api.example.com/data');
        const json = await res.json();
        console.log(json);
    } catch (err) {
        console.error('Failed:', err);
    }
};

fetchData();
```

### Rust

```rust
fn main() {
    let mut vec = Vec::new();
    vec.push(42);
    vec.push(7);
    
    for item in &vec {
        println!("Value: {}", item);
    }
}
```

### Bash

```bash
#!/bin/bash
set -euo pipefail

echo "Installing dependencies..."
sudo apt-get update
sudo apt-get install -y build-essential cmake

echo "Done!"
```

## 4. 深度嵌套列表

- 第一层 A
  - 第二层 A1
    - 第三层 A1a
      - 第四层 A1a1
        - 第五层 A1a1i
  - 第二层 A2
- 第一层 B
  - 第二层 B1
    - 第三层 B1a
  - 第二层 B2
- 第一层 C

## 5. 有序列表与无序列表混排

1. 安装步骤
   - 下载安装包
   - 运行安装程序
   - 完成配置
2. 验证安装
   1. 打开终端
   2. 输入 `markqml --version`
   3. 检查输出版本号
3. 常见问题
   - Windows: 以管理员身份运行
   - macOS: 需要授予磁盘权限
   - Linux: 检查依赖库

## 6. 任务列表

- [x] 项目初始化
- [x] 核心解析器开发
- [x] AST 树构建
- [x] QML 渲染组件
- [ ] 插件系统
  - [ ] 自定义扩展加载
  - [ ] 热更新支持
- [ ] 性能优化
  - [ ] 增量渲染
  - [ ] 虚拟滚动
- [ ] 文档完善

## 7. 链接测试

[普通链接](https://www.qt.io)

[带标题的链接](https://www.qt.io "Qt 官方网站")

**[粗体链接](https://github.com)**

*[斜体链接](https://stackoverflow.com)*

自动链接：https://www.kernel.org

## 8. 图片测试

### 本地图片

![唯美侧颜](C:\\Users\\jie\\Pictures\\zhuomian.jpeg)

### 在线占位图

![随机图片 400x300](https://micvs-dev.oss-cn-guangzhou.aliyuncs.com/hongjie/user/res/5137669067836465152/4.jpg)

![随机图片 600x400](https://micvs-dev.oss-cn-guangzhou.aliyuncs.com/hongjie/user/res/5137669067836465152/4.jpg)

![随机图片 800x200](https://micvs-dev.oss-cn-guangzhou.aliyuncs.com/hongjie/user/res/5137669067836465152/4.jpg)

### 图片与链接组合

[![Qt Logo](https://www.qt.io/hubfs/Qt-logo-neon.png)](https://www.qt.io)

## 9. 复杂表格

| 语言 | 类型 | 内存安全 | 性能 | 代表项目 |
|------|------|----------|------|----------|
| C++ | 编译型 | 手动管理 | ⭐⭐⭐⭐⭐ | Qt、Chrome |
| Rust | 编译型 | 编译期保证 | ⭐⭐⭐⭐⭐ | Firefox、Tokio |
| Python | 解释型 | GC | ⭐⭐⭐ | Django、PyTorch |
| JavaScript | 解释型 | GC | ⭐⭐⭐⭐ | Node.js、VS Code |
| Go | 编译型 | GC | ⭐⭐⭐⭐ | Docker、Kubernetes |

## 10. 表格内嵌样式

| 功能 | 语法 | 示例 | 状态 |
|------|------|------|------|
| 粗体 | `**text**` | **粗体** | ✅ |
| 斜体 | `*text*` | *斜体* | ✅ |
| 代码 | `` `code` `` | `code` | ✅ |
| 删除线 | `~~text~~` | ~~删除~~ | ✅ |
| 链接 | `[text](url)` | [链接](https://qt.io) | ✅ |
| 图片 | `![alt](url)` | 见上方 | ✅ |

## 11. 多重分割线

第一段内容。

---

第二段内容。

***

第三段内容。

___

## 12. HTML 混合

<div style="color: #e74c3c;">红色 HTML 行内文本</div>

行内 HTML：<span>span 标签内容</span> 和 <b>粗体 HTML</b>。

## 13. 长段落与换行

这是一个非常长的段落，用来测试文本换行和 softbreak 的表现。当文本长度超过容器宽度时，应该自动换行到下一行继续显示。我们需要确保各种内联元素如**粗体**、*斜体*、`代码`和[链接](https://www.qt.io)在换行时也能正确渲染。

这是另一个段落。行尾有两个空格，应该产生硬换行。  
这是换行后的新行。

## 14. 边界情况

空行下面的段落。

包含特殊字符：`< > & " '` 和 `&amp;`。

包含emoji：🎉 🚀 💻 ✨ 🌟

## 15. 结语

> **Markdown** 是一种轻量级标记语言，它允许人们使用易读易写的纯文本格式编写文档，然后转换成有效的 **HTML**。
>
> > 本项目使用 `cmark-gfm` 作为解析引擎，结合 **Qt Quick / QML** 实现原生渲染。
>
> 感谢测试！
