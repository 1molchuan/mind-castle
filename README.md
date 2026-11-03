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
| `LICENSE` | 代码和自制素材的 MIT 许可 |

## 许可与用途

本项目是课堂实验里做的脑波交互小游戏，公开出来供**个人学习、课堂教学、科普展示**等非商业用途使用。

- **代码**（`*.html` 里的程序、`serve.ps1`、`install.ps1`、`start.bat`）和**自制素材**（背景、城堡、法师及其动画、小蓝鲸等，
  清单见 `assets/CREDITS.txt` 第一部分）：按 [MIT 许可](LICENSE) 发布，可以自由使用、修改和再发布，包括商用。
- **带开放许可的第三方素材**（奶蛙动画和笑声、背手负鼠、木鱼音效为 MIT，Kenney 音效为 CC0）：按各自原许可使用。
- **未获授权的第三方素材**（奶龙、肥嘟嘟袋鼠、高雅人士企鹅、各家 AI 娘化形象、梁武谷梗图等，清单见
  `assets/CREDITS.txt` 第三部分）：版权归原作者或权利人，**不在 MIT 许可范围内**，只是为了非商业的教学演示而收录。
  不能用于商业用途；如果要商用或作为正式作品发行，必须先把这些素材全部换成有授权的或原创的。
- **权利人删除请求**：如果你是上述素材的作者或权利人、不同意在这里使用，请提 [issue](https://github.com/1molchuan/mind-castle/issues)，我们会尽快删除。

其他声明：

- 游戏里的梗（DeepSeek 娘「服务器繁忙」、Claude 封号通知、梁武谷、各家 AI 娘化形象等）都是网络梗的娱乐性二创，
  与 DeepSeek、OpenAI、Anthropic、Google、美团、第七印象等公司及相关个人无关，不代表其立场，也没有任何贬损意图。
- 「专注度」「放松度」是 TGAM 模块用厂商算法给出的估计值。本项目不是医疗器械，不能用于任何诊断或治疗。
