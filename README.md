# 念力守城：脑波游戏

用 TGAM 脑波头环的「专注度」「放松度」来玩的网页小游戏，在浏览器里通过串口直接读头环数据。

- **念力守城**：越专注法杖充能越快、闪电越密；放松下来修城墙；四个 Boss 各有要靠专注、停手或放松才能过的考验。
- **脑波动作识别测试**：按提示做动作并记录脑波，可导出 CSV。

没有设备也能玩：点游戏里的「模拟模式」，用方向键代替脑波。

## 安装和启动（Windows 10 / 11）

### 一行命令安装

打开 **PowerShell**（开始菜单搜索 PowerShell），粘贴回车：

```powershell
irm https://raw.githubusercontent.com/1molchuan/mind-castle/main/install.ps1 | iex
```

或者在 **cmd（命令提示符）** 里：

```bat
curl -fsSLo %TEMP%\mc.ps1 https://raw.githubusercontent.com/1molchuan/mind-castle/main/install.ps1 && powershell -ExecutionPolicy Bypass -File %TEMP%\mc.ps1
```

它会：

1. 下载最新版到 `%LOCALAPPDATA%\MindCastle`（约 6 MB）；
2. 在桌面创建「念力守城」快捷方式；
3. 在本机 `http://127.0.0.1:8765/` 开一个小网页服务器，并用 Edge / Chrome 打开游戏。

以后双击桌面快捷方式就能玩；关掉那个黑色的服务器窗口就退出。**想更新到新版，再运行一次同一条命令即可。**

不需要安装 Python、Node 或任何软件，用的是 Windows 自带的 PowerShell 和 .NET。服务器只监听本机回环地址（127.0.0.1），局域网里的其他电脑访问不到。

### 不用命令，手动下载

在 GitHub 页面点 **Code → Download ZIP**，解压后双击 `start.bat`。

也可以直接用 Edge / Chrome 打开 `index.html`（`file://` 方式），同样能连设备。

### 国内网络下载慢？

安装脚本支持换下载地址：先设置环境变量 `MC_ZIP` 为任意镜像的 zip 地址（或本地 zip 路径）再运行，例如在 PowerShell 里：

```powershell
$env:MC_ZIP = 'D:\mind-castle-main.zip'; irm https://raw.githubusercontent.com/1molchuan/mind-castle/main/install.ps1 | iex
```

机房批量部署时，可以把 zip 和 `install.ps1` 放到共享盘，每台电脑运行：
`powershell -ExecutionPolicy Bypass -File \\共享盘\install.ps1`（同时设置 `MC_ZIP` 指向共享盘里的 zip；再设置 `MC_NOSTART=1` 就只安装、不打开游戏）。

## 连接脑波设备

- 设备：TGAM 脑波模块 + 蓝牙接收器（`USB-SERIAL CH340`）。插上接收器后，Windows 一般会自动装好 CH340 驱动；设备管理器的「端口 (COM 和 LPT)」里能看到它占用的 COM 口。
- 浏览器：必须用 **Edge 或 Chrome**，Firefox 没有串口功能。
- 波特率：选 **9600**（选错会收到全是 0 的数据）。
- 连接前关掉串口助手、调试软件和其他游戏页面，否则会提示串口被占用。
- 串口能打开但一直没有数据：多半是头环和接收器的蓝牙断了。把头环关掉再打开，等接收器的灯常亮。
- 头环刚开机的二十几秒数据不准（专注会一路掉到 0），等一会儿再开始。
- 信号质量 200 表示电极没贴好：额头电极贴紧、耳夹夹住耳垂，必要时用湿纸巾擦一下皮肤。

## 文件说明

| 文件 | 作用 |
|---|---|
| `index.html` | 游戏选择页 |
| `mind-castle.html` / `calib.html` | 念力守城 / 脑波动作识别测试，各自是一个独立网页 |
| `assets/` | 图片、动画、音效；来源见 `assets/CREDITS.txt` |
| `serve.ps1` | 本地网页服务器 + 打开浏览器（`-Port 9000` 换端口，`-NoBrowser` 不开浏览器） |
| `start.bat` | 双击启动，等同于运行 `serve.ps1` |
| `install.ps1` | 一行命令安装 / 更新用的脚本 |
