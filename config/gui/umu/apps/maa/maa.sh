[ -n "$WAYLAND_DISPLAY" ] || { echo "WAYLAND_DISPLAY not set" >&2; exit 1; }

# 检查 waydroid 状态
status_output=$(waydroid status 2>/dev/null)

# 提取 Container 状态行
session_status=$(printf '%s\n' "$status_output" | grep '^Session:' | awk '{print $2}')

# 启动应用（无论状态如何）
waydroid app launch com.hypergryph.arknights &

# 如果容器是 STOPPED，则需等待启动完成
if [ "$session_status" = "STOPPED" ]; then
    echo "Container is STOPPED, waiting for startup..."
    sleep 5
fi

# 尝试 ADB 连接并检查结果
if ! adb connect 192.168.240.112:5555; then
    echo "Error: Failed to connect to WayDroid via ADB." >&2
    exit 1
fi

# 创建adb符号链接
adb_target="$maa_path/adb"
adb_source="$(which adb)"

if [ ! -e "$adb_target" ] || [ "$(realpath "$adb_target")" != "$(realpath "$adb_source")" ]; then
    if ! ln -sf "$adb_source" "$adb_target" -v; then
        echo "创建adb符号链接失败" >&2
        exit 1
    fi
fi

# # 从配置文件中提取当前地址
# current_address=""
# if [ -f "$config_file" ]; then
#     # 使用grep和sed提取地址值
#     current_address=$(grep '"Connect.Address":' "$config_file" | sed -n 's/.*"Connect.Address": "\([^"]*\)".*/\1/p')
# fi

# # 使用zenity获取用户输入的地址，默认值为配置文件中的当前地址
# new_address=$(zenity --entry --title="MAA" --text="请输入ADB地址 (host:port格式，可选):" --entry-text="$current_address")

# # 检查用户是否点击了OK（zenity返回0）且输入不为空
# if [ $? -eq 0 ] && [ -n "$new_address" ]; then
#     # 执行adb连接
#     if adb connect "$new_address"; then
#         # 更新配置文件中的地址
#         if [ -f "$config_file" ]; then
#             sed -i "s/\"Connect.Address\": \".*\"/\"Connect.Address\": \"$new_address\"/" "$config_file"
#         else
#             zenity --warning --title="MAA" --text="配置文件未找到: $config_file"
#         fi
#     else
#         zenity --error --title="MAA" --text="ADB连接失败: $new_address"
#     fi
# fi

# 无论是否输入地址，都执行以下命令

# 设置安卓设备分辨率
# if ! adb -s "$new_address" shell wm size 1080x1920; then
#     if ! zenity --question --title="MAA" --text="设置分辨率失败，是否继续运行MAA？"; then
#         exit 1
#     fi
# fi

# 启动MAA
if ! $maa_cmd; then
    zenity --error --title="MAA" --text="MAA出现错误"
fi

# 重置分辨率
# if zenity --question --title="MAA" --text="是否重置分辨率？"; then
#     if ! adb -s "$new_address" shell wm size reset; then
#         zenity --warning --title="MAA" --text="重置分辨率失败"
#     fi
# fi

# 断开连接
# adb disconnect "$new_address"
