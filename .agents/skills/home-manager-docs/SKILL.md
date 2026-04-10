---
name: home-manager-docs
description: 查询当前仓库锁定的 Home Manager 文档，并在每次查询前将所需文档构建到独立缓存目录，而不是依赖容易被覆盖的 result、result-1、result-2。优先使用构建出的 options.json 精确查找 option 的描述、类型、默认值、示例和声明位置，并在需要叙述性说明时构建和检索 HTML 手册。用于回答 Home Manager 配置项怎么写、某个模块有哪些选项、某个选项定义在哪、当前仓库锁定的 Home Manager 版本包含哪些文档内容，以及需要基于 ~/.config/home-manager 当前 flake 输入进行检索的场景。
---

# Home Manager Docs

使用本 skill 查询当前仓库锁定的 Home Manager 文档。不要依赖仓库里的 `result*` 符号链接，因为它们可能被其他构建覆盖。每次查询前，把所需文档构建到 `/tmp/home-manager-docs`，然后从该目录读取。

## 文档源

- `/tmp/home-manager-docs/json/share/doc/home-manager/options.json`
  主数据源。由脚本按需构建。适合精确查询 option 名称、类型、默认值、示例、声明位置。
- `/tmp/home-manager-docs/html/share/doc/home-manager/index.xhtml`
  手册首页。由脚本按需构建。适合定位章节和整体说明。
- `/tmp/home-manager-docs/html/share/doc/home-manager/options.xhtml`
  HTML 版 options 文档。由脚本按需构建。适合在结构化查询不足时补充人工可读上下文。
- `/tmp/home-manager-docs/manpages/share/man/man5/home-configuration.nix.5`
  manpage。由脚本按需构建。只在终端快速浏览时使用。

## 工作流

1. 先确认仓库根目录可用，并从当前 flake 解析出锁定的 `home-manager` input。
2. 对 option 查询，优先运行 `scripts/query_hm_options.py`。脚本会先构建 `docs-json` 到 `/tmp/home-manager-docs/json`。
3. 如果用户问的是概念、章节、迁移说明或教程，先构建 HTML 手册到 `/tmp/home-manager-docs/html`，再用 `rg` 检索对应 `*.xhtml`。
4. 如果需要进一步解释行为，实现细节以模块源码为准，结合 option 的 `declarations` 继续打开 Home Manager 源文件。

## 快速命令

列出文档路径：

```bash
python .agents/skills/home-manager-docs/scripts/query_hm_options.py paths
```

精确查询一个 option：

```bash
python .agents/skills/home-manager-docs/scripts/query_hm_options.py show programs.zoxide.enable
```

按关键字搜索 option：

```bash
python .agents/skills/home-manager-docs/scripts/query_hm_options.py search zoxide
```

在 HTML 手册里搜叙述性内容：

```bash
rg -n "activation|flakes|stateVersion" /tmp/home-manager-docs/html/share/doc/home-manager
```

## 输出要求

- 回答 option 问题时，优先给出：
  option 名、类型、默认值、是否只读、声明位置、简短说明。
- 如果脚本返回多个候选，不要猜；列出最相关的几个候选项并说明你在按名称匹配。
- 如果问题涉及“怎么配置”，除文档摘要外，尽量给出最小可用 Nix 片段。
- 如果文档和源码可能不一致，以当前本地构建产物和当前锁定源码为准，并明确说明依据。

## 限制

- 这个 skill 会在每次查询前触发 `nix build`，因此可能需要额外的 Nix 权限或花费少量时间。
- `options.json` 只覆盖 option 元数据，不覆盖完整教程式说明。
- 对模块实现行为的最终确认，仍应回到 `declarations` 指向的源码。
