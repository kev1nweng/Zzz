# Zzz

Zzz 是一款 macOS 极简菜单栏就寝倒计时工具，旨在通过原生优雅的界面，提醒你准时休息。

[English Version](./README.en.md)

## 核心功能

- 原生体验：基于 SwiftUI 与 AppKit 打造，完美融入系统毛玻璃视觉。
- 智能算法：支持跨凌晨作息（以早晨 8 点为分割点），自动区分工作日与周末。
- 临时覆盖：支持设置今晚特殊的就寝时间，不影响常规周期配置。
- 状态栏显示：支持隐藏图标的紧凑模式，并能在临近就寝时自动切换显示单位。
- 桌面组件：基于 WidgetKit 实现，支持与主应用配置实时同步。
- 视觉警报：倒计时在临近就寝或超时状态下会自动变红。
- 快捷操作：支持右键菜单一键退出。

## 安装方法

1. 从 Release 页面下载 Zzz.dmg 或自行从源码构建。
2. 打开 DMG 文件，将 Zzz 拖入 Applications 应用程序文件夹。
3. 启动应用，即可在菜单栏看到倒计时。

## 开发与构建

### 环境要求

- macOS 14.0 或更高版本
- Xcode 15.0 或更高版本
- XcodeGen

### 从源码构建

1. 克隆本仓库。
2. 安装 XcodeGen（如果尚未安装）：`brew install xcodegen`。
3. 在项目根目录执行：`xcodegen generate` 以生成 Xcode 工程。
4. 打开 `Zzz.xcodeproj`，选择 Zzz 方案并进行构建。

## 许可证

MIT License
