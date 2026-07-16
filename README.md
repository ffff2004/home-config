# Home Manager 配置说明

本仓库用于管理用户 fym 的 Home Manager 配置，采用 flake + 模块化目录组织。

## 1. 架构与加载关系

核心入口与模块加载链路：

1. [flake.nix](flake.nix)
2. [config/common/default.nix](config/common/default.nix)
3. [config/gui/default.nix](config/gui/default.nix)
4. [modules/default.nix](modules/default.nix)
5. [lib/default.nix](lib/default.nix)

`flake.nix` 构建 `homeConfigurations.fym` 与 `homeConfigurations.fym-tty`，并通过 `extraSpecialArgs` 注入 `localLib` 与 `pkgsFrom`。现在也包含 Home Manager 元配置、Nix 配置，以及仓库内工具包输出（如 `codex-config-sync`）。
`flake.nix` 显式组合配置：共享配置导入 `config/common` 与 `modules`，默认 GUI 配置 `fym` 额外导入 `config/gui`，TTY/WSL 配置 `fym-tty` 不导入 `config/gui`。`common`、`gui` 与 `modules` 目录的 `default.nix` 统一使用 `localLib.lsSubmodule ./.` 自动导入子模块。

### 1.1 modules：可复用 Home Manager 模块

| 模块 | 职责 |
| --- | --- |
| [modules/default.nix](modules/default.nix) | modules 目录入口，自动导入子模块 |
| [modules/agents.nix](modules/agents.nix) | 通过 `local.agents.skills` 将共享 agent skills 部署到 `~/.agents/skills` |

## 2. config 目录模块职责

### 2.1 common：通用环境与开发工具

| 模块 | 职责 |
| --- | --- |
| [config/common/default.nix](config/common/default.nix) | common 目录入口，递归导入 |
| [config/common/agents.nix](config/common/agents.nix) | 共享 agent 配置，例如 skills |
| [config/common/env.nix](config/common/env.nix) | 维护 `PATH` 等搜索路径变量 |
| [config/common/shell.nix](config/common/shell.nix) | Bash/Fish 配置与普通 shell 别名 |
| [config/common/home-manager-wrapper.nix](config/common/home-manager-wrapper.nix) | 自动按当前会话选择 `fym` 或 `fym-tty` 的 `hmb`/`hmbo`/`hms`/`hmso` 命令 |
| [config/common/git.nix](config/common/git.nix) | Git 与 GitHub CLI 配置（签名、fsck、安全设置） |
| [config/common/gpg.nix](config/common/gpg.nix) | GPG 与 gpg-agent 启用 |
| [config/common/ssh.nix](config/common/ssh.nix) | OpenSSH 客户端与默认 TTY ssh-agent 配置 |
| [config/common/generic-linux.nix](config/common/generic-linux.nix) | 非 NixOS 通用兼容工具（`wrapIfEnabled`/`nullIfEnable`/`getCmd`） |
| [config/common/tmux/default.nix](config/common/tmux/default.nix) | tmux 安装与配置文件（oh-my-tmux 主配置 + 本地覆盖） |
| [config/common/neovim.nix](config/common/neovim.nix) | Neovim 默认编辑器配置：Lua 设置、常用插件、nvim-cmp 补全与 nil/ruff/bash/fish LSP |
| [config/common/nodejs/default.nix](config/common/nodejs/default.nix) | Node.js、pnpm、`.npmrc` 链接与 pnpm 全局 bin PATH |
| [config/common/python/default.nix](config/common/python/default.nix) | Python 工具链（uv、nix-py 脚本） |
| [config/common/codex/default.nix](config/common/codex/default.nix) | Codex 配置 |
| [config/common/misc/default.nix](config/common/misc/default.nix) | 杂项工具（direnv、nix-direnv、yazi） |
| [config/common/misc/packages.nix](config/common/misc/packages.nix) | 常用包清单（含 nil、nixfmt、jq 等） |
| [config/common/fastfetch/default.nix](config/common/fastfetch/default.nix) | fastfetch 配置与配置文件链接 |

### 2.2 gui：桌面环境、输入法与图形应用

| 模块 | 职责 |
| --- | --- |
| [config/gui/default.nix](config/gui/default.nix) | gui 目录入口，递归导入 |
| [config/gui/credentials/default.nix](config/gui/credentials/default.nix) | GNOME Keyring、libsecret 与 GCR SSH agent 集成 |
| [config/gui/fontconfig.nix](config/gui/fontconfig.nix) | 字体渲染与默认字体族设置 |
| [config/gui/terminal/default.nix](config/gui/terminal/default.nix) | 终端方案（Alacritty Graphics + matugen 主题）和 xdg-terminal-exec |
| [config/gui/gtk/default.nix](config/gui/gtk/default.nix) | GTK3/GTK4 配置与 matugen CSS 引入 |
| [config/gui/qt6ct/default.nix](config/gui/qt6ct/default.nix) | Qt5/Qt6 ct 主题变量、配置与 matugen 色彩方案 |
| [config/gui/polkit-agent.nix](config/gui/polkit-agent.nix) | Polkit 认证代理 systemd user service |
| [config/gui/swayidle.nix](config/gui/swayidle.nix) | 空闲策略（熄屏、锁屏、休眠） |
| [config/gui/wallpaper-fetcher.nix](config/gui/wallpaper-fetcher.nix) | 壁纸抓取服务与定时器 |
| [config/gui/cliphist.nix](config/gui/cliphist.nix) | Cliphist 剪贴板历史服务与 Fuzzel picker |
| [config/gui/media.nix](config/gui/media.nix) | MPRIS 播放器跟踪与媒体键绑定 |
| [config/gui/lock-session/default.nix](config/gui/lock-session/default.nix) | 运行预锁命令并调用屏幕锁定命令 |
| [config/gui/pywalfox/default.nix](config/gui/pywalfox/default.nix) | Pywalfox native host 与 matugen 颜色桥接 |
| [config/gui/app-overrides/default.nix](config/gui/app-overrides/default.nix) | 为本地 GUI 应用集中管理 wrapper、desktop override 与 MIME/URL scheme 关联 |
| [config/gui/theme/default.nix](config/gui/theme/default.nix) | matugen 主题 registry、运行命令与 light/dark 模式状态 |
| [config/gui/fuzzel/default.nix](config/gui/fuzzel/default.nix) | Fuzzel 启动器配置与 matugen 主题引入 |
| [config/gui/waybar/default.nix](config/gui/waybar/default.nix) | Waybar 底栏、托盘、任务栏、系统指标与 matugen 样式 |
| [config/gui/swaync/default.nix](config/gui/swaync/default.nix) | SwayNC 通知守护进程、通知中心配置与 matugen 样式 |
| [config/gui/wpaperd.nix](config/gui/wpaperd.nix) | wpaperd 壁纸运行时与主题生成 hook |
| [config/gui/fcitx5/default.nix](config/gui/fcitx5/default.nix) | Fcitx5 输入法与配置树递归链接 |
| [config/gui/niri/default.nix](config/gui/niri/default.nix) | Niri 主入口，导入 niri-flake 与 settings 子模块 |
| [config/gui/umu/default.nix](config/gui/umu/default.nix) | UMU Launcher 包装器定义与 Proton 变体 |

## 3. lib 目录模块职责

| 模块 | 职责 |
| --- | --- |
| [lib/default.nix](lib/default.nix) | lib 聚合入口：遍历并导入本目录子模块，最终合并为 `localLib` |
| [lib/ls.nix](lib/ls.nix) | 文件与模块发现工具：`lsFile`、`lsDir`、`lsFileRecursively`、`lsSubmodule` |
| [lib/symlink-to-source.nix](lib/symlink-to-source.nix) | 源路径映射与软链接：`toSourcePath`、`mkSymlinkToSource`、`mkSymlinkToSourceRecursively` |

`lib/ls.nix` 和 `lib/symlink-to-source.nix` 是本仓库最核心的两类基础能力：

1. 自动导入模块（避免在 `default.nix` 手工枚举）。
2. 将配置文件以 out-of-store symlink 方式链接到源码路径，便于维护与热更新。

## 4. pkgs 目录工具包

| 模块 | 职责 |
| --- | --- |
| [pkgs/coding-setup/default.nix](pkgs/coding-setup/default.nix) | tmux 编程工作区初始化脚本 `coding-setup` |
| [pkgs/nix-py/default.nix](pkgs/nix-py/default.nix) | 使用 Nix 提供依赖启动 Python 的包装脚本 `nix-py` |
| [pkgs/pinentry-auto/default.nix](pkgs/pinentry-auto/default.nix) | 按 pinentry 请求上下文选择图形或终端后端的代理 |
| [pkgs/waybar-niri-taskbar-focused/default.nix](pkgs/waybar-niri-taskbar-focused/default.nix) | 当前 workspace 过滤的 Waybar Niri CFFI 任务栏模块 |

## 5. 其他有用信息

提交信息使用 `<type>(<scope>): <summary>` 格式，详细约定见 [AGENTS.md](AGENTS.md)。

### 5.1 构建和求值

```bash
# 仅改本地配置、未新增包或依赖时，推荐：跳过 Nix binary cache 查询以节省时间
home-manager build --flake ".#fym" --option substitute false

# 常规构建
home-manager build --flake ".#fym"

# TTY/WSL 配置
home-manager build --flake ".#fym-tty"

# 应用配置并备份
home-manager switch --flake ".#fym" -b hmbak

# 应用 TTY/WSL 配置
home-manager switch --flake ".#fym-tty" -b hmbak

# 同时跳过 substitute 查询
home-manager switch --flake ".#fym" -b hmbak --option substitute false
```

如果当前 shell 已加载配置，可使用自动选择 GUI 或 TTY/WSL 配置的包装命令：

```bash
hmb   # home-manager build --flake ".#fym" 或 ".#fym-tty"
hmbo  # hmb + --option substitute false
hms   # home-manager switch --flake ".#fym" 或 ".#fym-tty" -b hmbak
hmso  # hms + --option substitute false
```
