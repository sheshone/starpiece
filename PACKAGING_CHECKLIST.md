# Windows 打包检查清单

当前项目已使用 Godot 4.7 Windows 导出模板生成兼容版，不需要额外下载运行库。

## 玩家需要安装什么

正常情况下不需要安装 Godot、Python或其他运行库。发布时只需要发送：

```text
expo/starpiece_demo_compat.exe
```

项目使用 `embed_pck=true`，资源包已经嵌入主 EXE。

不要单独发送或让玩家运行：

```text
starpiece_demo.v0.console.exe
```

它只是控制台包装器，本身不是完整游戏。当前导出配置已经关闭后续生成该文件。

## 已做的兼容性调整

- 默认渲染器改为 `gl_compatibility`，Windows 强制使用 OpenGL 3，规避旧包在部分机器上出现的 D3D12 `0x887a0005` 设备丢失和黑屏。
- Windows 架构仍为 `x86_64`，要求 64 位 Windows。
- 已关闭控制台包装器，只生成包含全部资源的主 EXE。
- 不启用代码签名，Windows SmartScreen 仍可能显示“未知发布者”，这是警告而不是游戏损坏。

## 当前兼容版

```text
expo/starpiece_demo_compat.exe
```

- 文件大小：133,113,400 字节。
- SHA-256：`C0FB4A491A925E158A2DADDFE8052A8F293D6671C500B90083130181173A5156`
- 已完成项目静态检查、项目运行冒烟测试，以及导出 EXE 的独立启动测试。

## 下一次正式发送前

1. 只发送 `starpiece_demo_compat.exe`，不要再发送旧版 `starpiece_demo.v0.exe` 或 `.console.exe`。
2. 最好在一台没有安装 Godot 的 64 位 Windows 机器测试主 EXE。
3. 如果启动失败，让测试者截图完整报错，并记录 Windows 版本、显卡型号和驱动版本。
4. 将 EXE 压缩为 ZIP 后发送，可减少聊天软件或浏览器修改、拦截文件的概率。

## 常见问题

- “无法在此电脑运行”：可能是 32 位系统、文件损坏或安全软件拦截。
- 黑屏/图形设备错误：通常与显卡驱动有关；Compatibility 渲染器已降低此风险。
- Windows 拦截：右键属性检查是否有“解除锁定”，或通过“更多信息 → 仍要运行”启动。
- 只有几百 KB 的程序无法运行：很可能误发了 `.console.exe`。
