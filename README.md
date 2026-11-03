# Duskrail / 暮轨

Duskrail 是一款基于 Godot 制作的中国铁路 3D 运输模拟游戏。线路约 89 km，包含
18 个车站、山区展线、隧道、桥梁、侧线与青川车场，并支持 25T 客运列车、
HXD1 电力机车和多种货运车辆。

## 下载

最新安装包和每个版本的版本说明见 GitHub Releases：

<https://github.com/zhangyuhexht/Duskrail/releases>

从 `alpha1.7` 开始，每个版本同时发布源码和 Windows 安装包。

## 已实现的内容

- HXD1 单端司机室、引擎室通道、车尾小驾驶室和贯通端门；
- 25T 客车内饰、2+2 座椅、可透视车窗、风琴式贯通道和行李车贯通走廊；
- 第一视角步行、准星、驾驶座/副驾驶座切换、任意站台车门上下车；
- 自动驾驶：选择站点、500 m 前限速 30 km/h、自动停车并施加停放制动；
- 整列车门同步、超站台车厢自动关门、侧线/车场轨道车门锁定；
- 牵引/制动不再造成车体前后点头；
- FSR 2.2 与 DLSS Super Resolution / DLAA（需要 NVIDIA RTX 20 系列及以上）。

## 操作

| 按键 | 功能 |
| --- | --- |
| `C` | 默认视角 / 第一视角 |
| `E` | 第一视角离开座椅；靠近打开的车门时登车 |
| `F` | 在驾驶座 / 副驾驶座旁坐下 |
| `P` | 自动驾驶面板 |
| `W/S` | 档位 / 步行前后 |
| `A/D` | 车门、车灯 / 步行左右 |
| `Space` | 紧急制动 / 跳跃 |
| `B` | 停放制动 |
| `K` | 车门（站台侧，整列同步） |
| `G` | 切换前方进路 |
| `M` | 全屏地图 |
| `Esc` | 暂停菜单 |

## 从源码运行

需要 Godot 4.7+；DLSS 版本需要 NVIDIA RTX Godot fork 和 Streamline SDK。

1. 用 Godot 打开 `train-sim/project.godot`。
2. 或使用命令行：

```powershell
godot --path train-sim
```

## 构建 Windows 安装包

目录约定：

```text
Duskrail/
  train-sim/          游戏工程
  tools/              构建和安装器脚本
  godot-rtx/          NVIDIA RTX Godot fork（不随仓库提交）
  streamline-sdk/     NVIDIA Streamline SDK（不随仓库提交）
```

构建：

```powershell
powershell -ExecutionPolicy Bypass -File tools/build.ps1 -Dlss -Installer -Version alpha1.7
```

依赖：

- Godot Windows editor/release template（NVIDIA RTX fork，分支 `nvidia-pt-dlss`）
- NVIDIA Streamline SDK 2.14.16
- Inno Setup 6
- `rcedit-x64.exe`（仅本地品牌化用，不随仓库提交）

如果使用官方 Godot 构建，可不加 `-Dlss`，但 DLSS 选项不可用，FSR 2.2 仍可用。

## 存档

存档默认位于 Godot 的 `user://saves`。安装器不会删除存档和设置。

Alpha 阶段保留了旧版本存档兼容：旧版本存档会显示、可加载，并在首次启动
时复制到 `user://saves_backup`。后续 Beta 可通过 `SaveManager.LEGACY_COMPAT`
收紧兼容，备份文件不会被删除。

## 许可证

本仓库原创代码和原创游戏素材采用 **GNU GPL v3.0**，见 [LICENSE](LICENSE)。

第三方组件、NVIDIA Streamline/DLSS 运行库、Godot 引擎、Inno Setup 语言文件等
不适用 GPL，具体见 [NOTICE.md](NOTICE.md)。Release 安装包中包含的 NVIDIA
运行库按其自身许可证分发，不包含在本源码仓库中。

Duskrail 与 NVIDIA、Godot Engine 的版权所有者和贡献者没有隶属关系。
