#!/bin/sh
SESSION="coding"
TARGET_DIR="."

# 手动解析参数以支持选项后置
while [ $# -gt 0 ]; do
    case "$1" in
        -s)
            if [ -n "$2" ] && [ "${2#-}" = "$2" ]; then
                SESSION="$2"
                shift 2
            else
                echo "Error: -s requires a session name argument" >&2
                exit 1
            fi
            ;;
        -*)
            echo "Error: Unknown option $1" >&2
            echo "Usage: coding-setup [-s session_name] [target_dir]" >&2
            exit 1
            ;;
        *)
            # 第一个非选项参数视为目标目录
            if [ "$TARGET_DIR" = "." ]; then
                TARGET_DIR="$1"
            else
                echo "Error: Multiple target directories specified" >&2
                exit 1
            fi
            shift
            ;;
    esac
done

# 切换到目标目录
if ! cd "$TARGET_DIR" 2>/dev/null; then
    echo "Error: 无法切换到目录 '$TARGET_DIR'" >&2
    exit 1
fi

if ! tmux has-session -t "$SESSION" 2>/dev/null; then
    # 在目标目录创建主窗格（窗口ID=1）
    tmux new-session -s "$SESSION" -d

    # 水平分割主窗口（创建左右布局：1.1 和 1.2）
    tmux split-window -h -t "$SESSION":1
    tmux send-keys -t "$SESSION":1.1 'nvim .'
    tmux send-keys -t "$SESSION":1.2 'codex'

    tmux new-window -t "$SESSION"
    tmux send-keys -t "$SESSION":2 'yazi'

    tmux new-window -t "$SESSION"
    tmux send-keys -t "$SESSION":3 'lazygit'

    tmux select-window -t "$SESSION":1
    tmux select-pane -t "$SESSION":1.1
fi

tmux attach -t "$SESSION"
