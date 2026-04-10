---
name: nix-eval
description: 对 Nix 表达式、flake 输出、模块配置值和属性集进行求值与探索。用于确认实际求值结果而不是只看源码，例如查询 `homeConfigurations`、包属性、模块合并后的 `config`、某个 option 的最终值，或当文件搜索无法可靠回答问题时使用。
---
# nix-eval

使用 `nix eval` 和 `nix repl` 获取 Nix 的真实求值结果。优先把它当作只读查询工具，而不是构建或切换工具。

## 何时使用

- 需要确认 flake 某个输出实际是什么。
- 需要查看 Home Manager 或 NixOS 配置合并后的值。
- 需要确认某个属性是否存在，或查看 attrset 的顶层结构。
- 文件搜索只能看到定义，不能可靠得出最终结果。

## 优先顺序

1. 精确取值时，先用 `nix eval`。
2. 结果是字符串或路径时，根据需要加 `--raw`。
3. 结果要继续交给其他工具处理时，优先加 `--json`。
4. 只想快速浏览 attrset 结构时，用 `nix repl` 逐层探索。

## 精确求值

直接求值某个 flake 输出：

```bash
nix eval <flake-url>#<nix-expression>
```

示例，查看当前目录里的 Home Manager session variables：

```bash
nix eval .#homeConfigurations.<user>.config.home.sessionVariables --json
```

如果结果本身是字符串或路径，优先使用 `--raw`：

```bash
nix eval .#homeConfigurations.<user>.config.home.username --raw
```

## 交互探索

当表达式很大，或者你只想先看顶层结构时，使用 REPL：

```bash
nix repl <flake-url>
```

示例，查看当前 flake 暴露了哪些 `homeConfigurations`：

```bash
printf '%s\n' homeConfigurations | nix repl .
```

REPL 更适合逐层探索 attrset；显示里的 `...` 只是输出省略，不是“部分求值”语义。

## 常见模式

查询属性是否存在：

```bash
nix eval .#homeConfigurations.<user>.config.programs.zoxide.enable
```

查看顶层键名：

```bash
printf '%s\n' homeConfigurations | nix repl .
```

用表达式读取 flake input 的路径：

```bash
nix eval --raw .#inputs.home-manager.outPath
```

任意表达式：

```bash
nix eval --expr '{foo = 1 + 1; bar = "hello";}' --json
```

## 注意事项

- 默认不要吞掉 stderr。报错信息通常就是下一步行动所需的上下文。
- `builtins.getFlake` 对未锁定或脏工作树可能需要 `--impure`。
- 对大型 attrset，不要一上来求整个根；先缩小到明确路径，再逐层深入。
- 这个 skill 只负责读取和探索结果，不负责 `nix build`、`home-manager switch` 或其他会改变系统状态的操作。
