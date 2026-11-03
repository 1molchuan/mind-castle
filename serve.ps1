# 念力守城本地启动器：在 127.0.0.1 上开一个只给本机用的小网页服务器，再用 Edge / Chrome 打开游戏。
# 用法：双击 start.bat，或 powershell -ExecutionPolicy Bypass -File serve.ps1 [-Port 8765] [-NoBrowser] [-Shortcut]
#   -Shortcut  只在桌面上创建「念力守城」快捷方式，不启动（安装脚本会调用）
# 不用安装 Python / Node，用的是 Windows 自带的 .NET。服务器只监听本机回环地址，局域网里的其他电脑访问不到。
param([int]$Port = 8765, [switch]$NoBrowser, [switch]$Shortcut)
$ErrorActionPreference = 'Stop'
$root = $PSScriptRoot

if ($Shortcut) {
  $lnk = Join-Path ([Environment]::GetFolderPath('Desktop')) '念力守城.lnk'
  $s = (New-Object -ComObject WScript.Shell).CreateShortcut($lnk)
  $s.TargetPath = Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe'
  $s.Arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$root\serve.ps1`""
  $s.WorkingDirectory = $env:USERPROFILE
  $s.IconLocation = "$root\icon.ico"
  $s.Description = '念力守城 · 脑波游戏'
  $s.Save()
  Write-Host "已在桌面创建快捷方式：$lnk"
  exit
}

$host.UI.RawUI.WindowTitle = '念力守城 · 本地服务器（关掉这个窗口就退出游戏）'

# 找一个能打开游戏的浏览器：串口功能只有 Edge / Chrome 有，Firefox 没有
function Find-Browser {
  $candidates = @(
    "${env:ProgramFiles(x86)}\Microsoft\Edge\Application\msedge.exe",
    "$env:ProgramFiles\Microsoft\Edge\Application\msedge.exe",
    "$env:ProgramFiles\Google\Chrome\Application\chrome.exe",
    "${env:ProgramFiles(x86)}\Google\Chrome\Application\chrome.exe",
    "$env:LOCALAPPDATA\Google\Chrome\Application\chrome.exe"
  )
  $candidates | Where-Object { $_ -and (Test-Path $_) } | Select-Object -First 1
}

function Open-Game($url) {
  if ($NoBrowser) { return }
  $browser = Find-Browser
  if ($browser) { Start-Process $browser -ArgumentList '--new-window', $url }
  else {
    Write-Host '没找到 Edge 或 Chrome，用默认浏览器打开；如果是 Firefox，连不上脑波设备（可以先用模拟模式）。' -ForegroundColor Yellow
    Start-Process $url
  }
}

# 端口上已经有一个念力守城在跑（比如双击了两次）：直接打开它，不再开第二个
try {
  $page = Invoke-WebRequest "http://127.0.0.1:$Port/index.html" -UseBasicParsing -TimeoutSec 2
  if ($page.Content -match 'mind-castle-launcher') {
    Write-Host '念力守城已经在运行，直接打开游戏。'
    Open-Game "http://127.0.0.1:$Port/"
    Start-Sleep -Seconds 2
    exit
  }
} catch {}

Add-Type -TypeDefinition @'
using System;
using System.Collections.Generic;
using System.IO;
using System.Net;
using System.Net.Sockets;
using System.Text;
using System.Threading;

// 只读的静态文件服务器：GET / HEAD，支持 Range（音效要靠它跳到指定位置播放），每个连接一个线程
public static class MindCastleServer {
    static string root;
    static readonly Dictionary<string, string> Types = new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase) {
        { ".html", "text/html; charset=utf-8" }, { ".js", "text/javascript; charset=utf-8" }, { ".css", "text/css; charset=utf-8" },
        { ".json", "application/json; charset=utf-8" }, { ".txt", "text/plain; charset=utf-8" }, { ".md", "text/plain; charset=utf-8" },
        { ".ps1", "text/plain; charset=utf-8" }, { ".bat", "text/plain; charset=utf-8" },
        { ".webp", "image/webp" }, { ".png", "image/png" }, { ".jpg", "image/jpeg" }, { ".gif", "image/gif" }, { ".ico", "image/x-icon" },
        { ".svg", "image/svg+xml" }, { ".mp3", "audio/mpeg" }, { ".ogg", "audio/ogg" }, { ".wav", "audio/wav" },
        { ".webm", "video/webm" }, { ".mp4", "video/mp4" },
    };

    // 从 port 开始找一个空闲端口，返回实际端口；都被占用返回 -1
    public static int Start(string dir, int port) {
        root = Path.GetFullPath(dir).TrimEnd('\\');
        for (int p = port; p < port + 20; p++) {
            var listener = new TcpListener(IPAddress.Loopback, p);
            try { listener.Start(); } catch (SocketException) { continue; }
            var t = new Thread(() => Accept(listener));
            t.IsBackground = true;
            t.Start();
            return p;
        }
        return -1;
    }

    static void Accept(TcpListener listener) {
        for (;;) {
            var client = listener.AcceptTcpClient();
            ThreadPool.QueueUserWorkItem(_ => Serve(client));
        }
    }

    static void Serve(TcpClient client) {
        try {
            using (client) {
                client.ReceiveTimeout = 10000;
                client.SendTimeout = 30000;
                var stream = client.GetStream();
                string head = ReadHead(stream);
                if (head == null) return;
                var lines = head.Split(new[] { "\r\n" }, StringSplitOptions.None);
                var first = lines[0].Split(' ');
                if (first.Length < 2) return;
                string method = first[0];
                if (method != "GET" && method != "HEAD") { Send(stream, 405, "Method Not Allowed", "text/plain", null, 0, 0, 0, false); return; }
                string range = null;
                foreach (var line in lines) {
                    if (line.StartsWith("Range:", StringComparison.OrdinalIgnoreCase)) range = line.Substring(6).Trim();
                }
                string file = Resolve(first[1]);
                if (file == null) { Send(stream, 404, "Not Found", "text/plain", null, 0, 0, 0, false); return; }
                string type;
                if (!Types.TryGetValue(Path.GetExtension(file), out type)) type = "application/octet-stream";
                long size = new FileInfo(file).Length, start = 0, end = size - 1;
                int status = 200;
                if (range != null && range.StartsWith("bytes=") && size > 0) {
                    var r = range.Substring(6).Split(',')[0].Split('-');
                    long a, b;
                    if (r[0].Length == 0 && long.TryParse(r[1], out b)) { start = Math.Max(0, size - b); }
                    else if (long.TryParse(r[0], out a)) {
                        start = a;
                        if (r.Length > 1 && long.TryParse(r[1], out b)) end = Math.Min(b, size - 1);
                    }
                    if (start > end || start >= size) { Send(stream, 416, "Range Not Satisfiable", "text/plain", null, 0, 0, size, false); return; }
                    status = 206;
                }
                Send(stream, status, status == 206 ? "Partial Content" : "OK", type, file, start, end, size, method == "GET");
            }
        } catch (Exception) {
            // 浏览器中途取消请求（比如快速切换页面）时连接会断，忽略即可
        }
    }

    // 读到请求头结束（空行）为止；超过 16 KB 或连接断开返回 null
    static string ReadHead(NetworkStream stream) {
        var buf = new byte[16384];
        int n = 0;
        while (n < buf.Length) {
            int k = stream.Read(buf, n, buf.Length - n);
            if (k <= 0) return null;
            n += k;
            for (int i = 3; i < n; i++) {
                if (buf[i - 3] == 13 && buf[i - 2] == 10 && buf[i - 1] == 13 && buf[i] == 10) return Encoding.ASCII.GetString(buf, 0, i - 3);
            }
        }
        return null;
    }

    // 把 URL 路径换成游戏目录下的文件；目录取 index.html；跑出游戏目录的路径一律不给
    static string Resolve(string target) {
        string p = target.Split('?', '#')[0];
        try { p = Uri.UnescapeDataString(p); } catch (Exception) { return null; }
        p = p.Replace('/', '\\').TrimStart('\\');
        string full;
        try { full = Path.GetFullPath(Path.Combine(root, p)); } catch (Exception) { return null; }
        if (full != root && !full.StartsWith(root + "\\", StringComparison.OrdinalIgnoreCase)) return null;
        if (Directory.Exists(full)) full = Path.Combine(full, "index.html");
        return File.Exists(full) ? full : null;
    }

    static void Send(NetworkStream stream, int status, string reason, string type, string file, long start, long end, long size, bool body) {
        long length = file == null ? 0 : end - start + 1;
        var h = new StringBuilder();
        h.Append("HTTP/1.1 ").Append(status).Append(' ').Append(reason).Append("\r\n");
        h.Append("Content-Type: ").Append(type).Append("\r\n");
        h.Append("Content-Length: ").Append(length).Append("\r\n");
        h.Append("Accept-Ranges: bytes\r\n");
        if (status == 206) h.Append("Content-Range: bytes ").Append(start).Append('-').Append(end).Append('/').Append(size).Append("\r\n");
        if (status == 416) h.Append("Content-Range: bytes */").Append(size).Append("\r\n");
        h.Append("Cache-Control: no-cache\r\nConnection: close\r\n\r\n");
        var bytes = Encoding.ASCII.GetBytes(h.ToString());
        stream.Write(bytes, 0, bytes.Length);
        if (!body || file == null) return;
        using (var fs = new FileStream(file, FileMode.Open, FileAccess.Read, FileShare.ReadWrite | FileShare.Delete)) {
            fs.Seek(start, SeekOrigin.Begin);
            var buf = new byte[65536];
            long left = length;
            while (left > 0) {
                int k = fs.Read(buf, 0, (int)Math.Min(buf.Length, left));
                if (k <= 0) break;
                stream.Write(buf, 0, k);
                left -= k;
            }
        }
    }
}
'@

$actual = [MindCastleServer]::Start($root, $Port)
if ($actual -lt 0) {
  Write-Host "端口 $Port ~ $($Port + 19) 都被占用了，换一个端口试试：powershell -File serve.ps1 -Port 9000" -ForegroundColor Red
  Read-Host '按回车退出'
  exit 1
}
$url = "http://127.0.0.1:$actual/"
Write-Host ''
Write-Host "  念力守城已启动：$url" -ForegroundColor Green
Write-Host '  请用 Edge 或 Chrome 打开（Firefox 不支持串口）。'
Write-Host '  玩完直接关掉这个窗口即可。'
Write-Host ''
Open-Game $url
while ($true) { Start-Sleep -Seconds 3600 }
