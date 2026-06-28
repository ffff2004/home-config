# Home Manager 配置说明

本仓库用于管理用户 fym 的 Home Manager 配置，采用 flake + 模块化目录组织。

## 1. 架构与加载关系

核心入口与模块加载链路：

1. [flake.nix](flake.nix)
2. [config/default.nix](config/default.nix)
3. [modules/default.nix](modules/default.nix)
4. [lib/default.nix](lib/default.nix)

`flake.nix` 构建 `homeConfigurations.fym`，并通过 `extraSpecialArgs` 注入 `localLib` 与 `pkgsFrom`。现在也包含 Home Manager 元配置、Nix 配置，以及仓库内工具包输出（如 `codex-config-sync`）。
`config` 与 `modules` 目录的 `default.nix` 统一使用 `localLib.lsSubmodule ./.` 自动导入子模块。

## 2. config 目录模块职责

### 2.1 入口模块

| 模块 | 职责 |
| --- | --- |
| [config/default.nix](config/default.nix) | config 总入口，自动导入 `common`、`gui` 等子模块 |

### 2.2 common：通用环境与开发工具

| 模块 | 职责 |
| --- | --- |
| [config/common/default.nix](config/common/default.nix) | common 目录入口，递归导入 |
| [config/common/env.nix](config/common/env.nix) | 维护 `PATH` 等搜索路径变量 |
| [config/common/shell.nix](config/common/shell.nix) | Bash/Fish 配置与常用别名（`hmb`/`hmbo`/`hms`/`hmso`） |
| [config/common/git.nix](config/common/git.nix) | Git 与 GitHub CLI 配置（签名、fsck、安全设置） |
| [config/common/gpg.nix](config/common/gpg.nix) | GPG 与 gpg-agent 启用 |
| [config/common/gnome-keyring.nix](config/common/gnome-keyring.nix) | libsecret 与 git-credential helper 集成 |
| [config/common/generic-linux.nix](config/common/generic-linux.nix) | 非 NixOS 通用兼容工具（`wrapIfEnabled`/`nullIfEnable`/`getCmd`） |
| [config/common/tmux/default.nix](config/common/tmux/default.nix) | tmux 安装与配置文件（oh-my-tmux 主配置 + 本地覆盖） |
| [config/common/neovim.nix](config/common/neovim.nix) | Neovim 默认编辑器配置：Lua 设置、常用插件、nvim-cmp 补全与 nil/ruff/bash/fish LSP |
| [config/common/nodejs/default.nix](config/common/nodejs/default.nix) | Node.js、pnpm、`.npmrc` 链接与 pnpm 全局 bin PATH |
| [config/common/python/default.nix](config/common/python/default.nix) | Python 工具链（uv、nix-py 脚本） |
| [config/common/codex/default.nix](config/common/codex/default.nix) | Codex 受管配置部署入口：通过 `codex-config-sync` 将仓库中的 `AGENTS.md`、`skills/`、`agents/` 同步到 `~/.codex`，默认不覆盖本地差异 |
| [config/common/misc/default.nix](config/common/misc/default.nix) | 杂项工具（direnv、nix-direnv、yazi） |
| [config/common/misc/packages.nix](config/common/misc/packages.nix) | 常用包清单（含 nil、nixfmt、jq 等） |
| [config/common/fastfetch/default.nix](config/common/fastfetch/default.nix) | fastfetch 配置与配置文件链接 |


### 2.3 gui：桌面环境、输入法与图形应用

| 模块 | 职责 |
| --- | --- |
| [config/gui/default.nix](config/gui/default.nix) | gui 目录入口，递归导入 |
| [config/gui/fontconfig.nix](config/gui/fontconfig.nix) | 字体渲染与默认字体族设置 |
| [config/gui/terminal/default.nix](config/gui/terminal/default.nix) | 终端方案（Alacritty Graphics + matugen 主题）和 xdg-terminal-exec |
| [config/gui/qt6ct.nix](config/gui/qt6ct.nix) | Qt6 主题变量与包配置 |
| [config/gui/polkit-agent.nix](config/gui/polkit-agent.nix) | Polkit 认证代理 systemd user service |
| [config/gui/swayidle.nix](config/gui/swayidle.nix) | 空闲策略（熄屏、锁屏、休眠） |
| [config/gui/wallpaper-fetcher.nix](config/gui/wallpaper-fetcher.nix) | 壁纸抓取服务与定时器 |
| [config/gui/clipboard.nix](config/gui/clipboard.nix) | X11/Wayland 剪贴板桥接服务 |
| [config/gui/lock-session.nix](config/gui/lock-session.nix) | 运行预锁命令并调用屏幕锁定命令 |
| [config/gui/app-overrides/default.nix](config/gui/app-overrides/default.nix) | 为本地 GUI 应用集中管理 wrapper、desktop override 与 MIME/URL scheme 关联 |
| [config/gui/desktop-shell/default.nix](config/gui/desktop-shell/default.nix) | 轻量桌面 shell 入口（后续集成 Waybar、swaync、cliphist、wpaperd 与 matugen） |
| [config/gui/fcitx5/default.nix](config/gui/fcitx5/default.nix) | Fcitx5 输入法与配置树递归链接 |
| [config/gui/niri/default.nix](config/gui/niri/default.nix) | Niri 主入口，导入 niri-flake 与 settings 子模块 |
| [config/gui/noctalia-shell/default.nix](config/gui/noctalia-shell/default.nix) | Noctalia shell 集成、模板与设置文件链接 |
| [config/gui/umu/default.nix](config/gui/umu/default.nix) | UMU Launcher 包装器定义与 Proton 变体 |

## 3. lib 目录模块职责

| 模块 | 职责 |
| --- | --- |
| [lib/default.nix](lib/default.nix) | lib 聚合入口：遍历并导入本目录子模块，最终合并为 `localLib` |
| [lib/ls.nix](lib/ls.nix) | 文件与模块发现工具：`lsFile`、`lsDir`、`lsFileRecursively`、`lsSubmodule` |
| [lib/to-source-path.nix](lib/to-source-path.nix) | 源路径映射与软链接：`toSourcePath`、`mkSymlinkToSource` |

`lib/ls.nix` 和 `lib/to-source-path.nix` 是本仓库最核心的两类基础能力：

1. 自动导入模块（避免在 `default.nix` 手工枚举）。
2. 将配置文件以 out-of-store symlink 方式链接到源码路径，便于维护与热更新。

## 4. pkgs 目录工具包

| 模块 | 职责 |
| --- | --- |
| [pkgs/codex-config-sync/default.nix](pkgs/codex-config-sync/default.nix) | Codex 配置双向同步脚本 |
| [pkgs/coding-setup/default.nix](pkgs/coding-setup/default.nix) | tmux 编程工作区初始化脚本 `coding-setup` |
| [pkgs/nix-py/default.nix](pkgs/nix-py/default.nix) | 使用 Nix 提供依赖启动 Python 的包装脚本 `nix-py` |
| [pkgs/clipboard-bridge/default.nix](pkgs/clipboard-bridge/default.nix) | X11/Wayland 双向剪贴板桥接脚本：`clipboard-bridge` |
| [pkgs/pinentry-auto/default.nix](pkgs/pinentry-auto/default.nix) | 按 pinentry 请求上下文选择图形或终端后端的代理 |

## 5. 其他有用信息

提交信息使用 `<type>(<scope>): <summary>` 格式，详细约定见 [AGENTS.md](AGENTS.md)。

### 5.1 构建和求值

```bash
# 仅改本地配置、未新增包或依赖时，推荐：跳过 Nix binary cache 查询以节省时间
home-manager build --option substitute false

# 常规构建
home-manager build

# 应用配置并备份
home-manager switch -b hmbak

# 同时跳过 substitute 查询
home-manager switch -b hmbak --option substitute false
```

如果当前 shell 已加载别名，可使用：

```bash
hmb   # home-manager build
hmbo  # home-manager build --option substitute false
hms   # home-manager switch -b hmbak
hmso  # home-manager switch -b hmbak --option substitute false
```

涉及 Codex 配置同步时，可使用：

```bash
# 查看受管文件与本地 ~/.codex 的差异
nix run .#codex-config-sync -- status

# 将 ~/.codex 中的改动回收到仓库
nix run .#codex-config-sync -- pull-from-home --write

# 将仓库中的 Codex 配置部署到 ~/.codex
nix run .#codex-config-sync -- push-to-home --write
```

求值：维护时优先使用 `nix-eval` skill 做只读求值，必要时再用 `nix eval` 或 `nix repl` 直接查询 flake 输出。

### 5.2 维护约定

1. 新建模块目录时，建议提供 `default.nix` 并使用 `imports = localLib.lsSubmodule ./.`。
2. 尽量通过 [lib/to-source-path.nix](lib/to-source-path.nix) 的 `mkSymlinkToSource` 管理配置文件源链接。
3. 非必要不要修改 `home.stateVersion`。
4. Nix 文件遵循 [.editorconfig](.editorconfig) 的 2 空格缩进。
5. Codex 配置只纳入需要声明式管理的 `AGENTS.md`、`skills/` 和 `agents/`；不要复制 `~/.codex/skills/.system`、插件缓存、会话状态等运行时文件。同步工具默认不会覆盖本地有差异的 `~/.codex` 文件。
