{
  lib,
  stdenvNoCC,
  fetchurl,
  umu-launcher-wrapper,
  maaPath,
  android-tools,
  zenity,
  writeShellScript,
  imagemagick,
  makeDesktopItem,
  copyDesktopItems,
  writeTextFile,
  niriConfig ? null,
}:
stdenvNoCC.mkDerivation (finalAttrs: {
  name = "maa";

  dontUnpack = true;

  icon512 = fetchurl {
    url = "https://docs.maa.plus/images/maa-logo_512x512.png";
    hash = "sha256-29AUkVyjpN+5Hh9izH5rqTdYSmgEoJyx5DsEieg13SY=";
  };

  desktopItems = [
    (makeDesktopItem {
      name = "MAA";
      exec = finalAttrs.script;
      icon = "maa";
      comment = finalAttrs.meta.description;
      desktopName = "MAA";
      categories = [ "Game" ];
    })
  ];

  nativeBuildInputs = [
    copyDesktopItems
  ];

  script = writeShellScript "maa" ''
    set -euo pipefail
    export PATH="${
      builtins.concatStringsSep ":" (
        map (p: "${p}/bin") [
          android-tools
          zenity
        ]
      )
    }:$PATH"
    maa_path="${maaPath}"
    # 如果 maa_path 未设置，则使用默认值
    if [ -z "$maa_path" ]; then
        maa_path="$HOME/Games/maa"
    fi
    maa_bin="$maa_path/MAA.exe"
    config_file="$maa_path/config/gui.json"

    echo "maa_path=$maa_path"
    echo "maa_bin=$maa_bin"
    echo "config_file=$config_file"

    maa_cmd="env GAMEID=maa ${lib.getExe umu-launcher-wrapper} $maa_bin"
    echo "maa_cmd=$maa_cmd"


    [ -n "$WAYLAND_DISPLAY" ] || { echo "WAYLAND_DISPLAY not set" >&2; exit 1; }

    # 检查 waydroid 状态
    status_output=$(waydroid status 2>/dev/null)

    # 提取 Container 状态行
    session_status=$(printf '%s\n' "$status_output" | grep '^Session:' | awk '{print $2}')

    # 启动应用（无论状态如何）
    ${
      if niriConfig != null then
        "niri -c ${
          writeTextFile {
            name = "niri-config-arknights";
            text = ''
              ${niriConfig}
              window-rule {
                  match app-id="^waydroid.com.hypergryph.arknights$"
                  open-fullscreen true
              }
              spawn-at-startup "waydroid" "app" "launch" "com.hypergryph.arknights"
            '';
          }
        } &"
      else
        "waydroid app launch com.hypergryph.arknights &"
    }

    # 如果容器状态是 STOPPED，则需等待启动完成
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
    adb_source="${android-tools}/bin/adb"

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
    $maa_cmd
    exit_code=$?

    if [ $exit_code -ne 0 ]; then
        zenity --error --title="MAA" --text="MAA 出现错误\n错误码: $exit_code"
        exit $exit_code
    fi

    # 重置分辨率
    # if zenity --question --title="MAA" --text="是否重置分辨率？"; then
    #     if ! adb -s "$new_address" shell wm size reset; then
    #         zenity --warning --title="MAA" --text="重置分辨率失败"
    #     fi
    # fi

    # 断开连接
    # adb disconnect "$new_address"
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin
    ln -s ${finalAttrs.script} $out/bin/maa

    mkdir -p $out/share/icons/hicolor/512x512/apps/
    ln -s ${finalAttrs.icon512} $out/share/icons/hicolor/512x512/apps/maa.png
    for size in 16 32 48 64 128 256; do
      res="$size"x"$size"
      mkdir -p $out/share/icons/hicolor/"$res"/apps/
      ${lib.getExe imagemagick} \
          $out/share/icons/hicolor/512x512/apps/maa.png \
          -resize "$res" \
          $out/share/icons/hicolor/"$res"/apps/maa.png
    done

    runHook postInstall
  '';

  meta = {
    mainProgram = "maa";
    description = "MAA Assistant Arknights 一款明日方舟游戏小助手";
  };
})
