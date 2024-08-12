# rime-cloud-input: RIME 云输入插件, 纯lua实现

## 说明
1. 这个是rime输入法的云输入插件，云输入请求使用纯lua实现，不再依赖so库，提高可移植性
## 安装
  1. 编译或获取压缩包
  2. 解压
     - Windows 平台（小狼毫 >= 0.14.0）
       - 将 `out-mingw` 下所有文件复制到小狼毫的程序文件夹下
       - 将 `scripts` 下所有文件复制到小狼毫的用户目录下
     - Linux 平台（librime 需编译 lua 支持）
       - 将 `out-linux` 下所有文件复制到 `/usr/local/lib/lua/$LUAV` 下
       - 将 `scripts` 下所有文件复制到用户目录下
     - macOS 平台（小企鹅）
       - 将 `out-macos` 下所有文件复制到 `/usr/local/lib/lua/$LUAV` 下
       - 将 `scripts` 下所有文件复制到 `~/.local/share/fcitx5/rime` 下
  3. 配置：见 `scripts/rime.lua` 中的注释

## 使用
  默认情况下，在输入状态下按 `Control+t` 触发一次云输入，云候选前五项自动加到候选菜单最前方。
