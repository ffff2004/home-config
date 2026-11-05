# umuctl

以运行时本地配置管理 UMU 应用、Proton 预设和桌面入口。Nix 只安装工具，不读取、生成或覆盖个人应用配置。

## 使用

```bash
umuctl list
umuctl doctor
umuctl run my-game
umuctl run my-game -- --some-game-argument
umuctl exec --proton my-proton --wayland --gpu my-gpu --game-id my-game -- installer.exe
umuctl sync
```

默认使用系统 `/usr/bin/umu-run`，保持 Arch/genericLinux 的宿主运行环境；不会自动安装 UMU、Proton 或游戏。可用全局 `--umu-run /absolute/path` 或环境变量 `UMUCTL_UMU_RUN` 指定其他启动器。

配置默认位于 `$XDG_CONFIG_HOME/umuctl/config.toml`（通常为 `~/.config/umuctl/config.toml`）。全局 `--config /path/to/config.toml` 必须放在子命令之前。修改配置后，启动立即读取新值；桌面名称、图标、增删应用后重新运行 `sync`。

## 配置格式

以下只是格式示例，不是需要维护的个人应用清单：

```toml
[proton.my-proton]
path = "~/path/to/proton"
unset = ["EXAMPLE_UNWANTED_VARIABLE"]

[proton.my-proton.env]
EXAMPLE_PROTON_OPTION = "1"

[gpu.my-gpu]
icd_files = ["~/path/to/driver_icd.json"]

[apps.my-game]
name = "My Game"
comment = "Local Windows application"
exe = "C:/Games/My Game/game.exe"
proton = "my-proton"
game_id = "my-game"
prefix = "~/Games/umu/my-game"
wayland = true
gpu = "my-gpu" # 本地 GPU 预设名；default 清除显式 ICD 选择，省略则继承
args = []
icon = "~/Pictures/my-game.png" # 本地文件或 HTTP(S) URL；下载只发生在 sync
before = [["/absolute/path/to/prepare-hook"]]
after = [["/absolute/path/to/restore-hook"]]

[apps.my-game.env]
EXAMPLE_APP_OPTION = "value"
```

- 应用、Proton 和 GPU 标识只允许字母、数字、`_`、`-`，首位必须为字母或数字；GPU 名称 `default` 为保留值。
- 环境变量值使用字符串或整数；`unset` 用于删除继承变量。
- 路径支持 `~` 和 `$HOME`。Windows EXE 路径通过 prefix 的 `dosdevices` 检查，不重写盘符、不移动数据。
- `prefix` 建议显式设置，避免继承的 `STORE` 或 `WINEPREFIX` 改变默认 prefix。`GAMEID` 与 prefix 是不同概念，多个应用可以共享 prefix。
- 环境优先级为继承环境 → Proton 预设 → 应用 → 显式启动选项。例外：继承的非空 `PROTONPATH` 可以覆盖应用预设；`exec --proton` 则明确选择预设。
- `before` / `after` 是参数数组组成的列表，不是 shell 字符串，不执行 `eval`。机器相关流程放在仓库外本地脚本中。
- `after` 在退出/启动失败以及正常处理 SIGINT、SIGTERM 时尝试执行。SIGKILL、掉电无法保证清理；hooks 应可重复执行，并自行处理共享资源锁。
- MAA 一类专用流程可以使用本地 `before` hook 准备 Waydroid/ADB；工具不提供内建定时调度。

## GPU 与 Vulkan ICD

GPU 预设只记录本机 ICD manifest 文件路径，不探测厂商、不自动猜测驱动。修改本地 `gpu.<名称>.icd_files` 后，引用该预设的应用立即使用新路径，无需重建 Nix 或重新生成桌面入口。

- `icd_files` 是非空路径数组，支持多文件；相对路径以配置目录为基准，支持 `~`、`$HOME`。文件名不能包含冒号，因为最终使用 Linux 的冒号分隔列表。
- `run --gpu <名称> <应用>` 或 `exec --gpu <名称> -- <程序>` 覆盖应用的 GPU 选择。选项需放在应用 ID 前。
- 命名预设在普通 `env` 合并后设置 `VK_ICD_FILENAMES`，并清除 `VK_DRIVER_FILES`，避免继承的另一项显式选择覆盖预设。
- 未指定 GPU 时保留合并后的环境；`--gpu default`（或应用的 `gpu = "default"`）清除 `VK_ICD_FILENAMES` 和 `VK_DRIVER_FILES`。
- 启动前检查选定预设：预设不存在、路径缺失或不可读、JSON 无效、缺少非空 `ICD.library_path` 时明确报错，不执行启动 hooks，也不静默换用其他驱动。
- `doctor` 检查所有 GPU 预设，并显示各应用最终生效的 ICD 列表；继承环境同时存在两项变量时，以 `VK_DRIVER_FILES` 为有效选择。检查不加载驱动库，不能替代真实 Vulkan/游戏兼容性测试。

## 桌面入口和所有权

`sync` 生成 `$XDG_DATA_HOME/applications/umuctl-<id>.desktop` 和私有图标缓存；状态清单位于 `$XDG_STATE_HOME/umuctl/manifest.json`。只更新或删除清单登记且内容未被手动修改的文件，拒绝覆盖无关文件。游戏目录、prefix 和配置不在清理范围内。

桌面入口记录实际启动器的绝对路径及配置路径。升级 Nix 包后再运行一次 `umuctl sync`，让入口引用当前版本；不要依赖已被垃圾回收的旧 store 路径。桌面环境可能需要刷新菜单。与旧 Home Manager 包入口并存时会暂时出现重复项，切换到新 generation 后旧入口才会消失。

## 开发与验证

```bash
uv run python -m unittest discover -s pkgs/umuctl -p 'test_*.py' -v
uv run pkgs/umuctl/umuctl.py --help
nix build .#umuctl
./result/bin/umuctl --help
```

Nix 构建中运行相同测试和安装后 smoke check，不访问真实个人配置，不启动游戏。
