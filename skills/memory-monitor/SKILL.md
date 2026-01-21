---
name: memory-monitor
description: Automatically monitor system memory via systemd service. Clean up zombie Claude processes proactively. Use when system is slow, memory usage is high, or when user mentions memory issues, zombie processes, or performance problems. The service runs automatically in background after installation.
---

# Memory Monitor

通过 systemd 系统服务自动监控系统内存使用，并清理僵尸 Claude 进程以保持系统性能。

## 快速开始

运行安装脚本自动配置系统服务：

```bash
cd /path/to/claude-utilities
./install.sh
```

安装完成后，服务会自动启动并设置为开机自启。

## 工作原理

### 系统服务模式

内存监控作为 **systemd 系统服务**运行，具有以下特性：

- **开机自启**：系统启动后自动运行
- **自动重启**：服务异常退出时自动重启（10秒后）
- **安全加固**：使用 NoNewPrivileges、PrivateTmp 等 systemd 安全特性
- **日志集成**：日志同时输出到 journalctl 和文件

### 监控与清理逻辑

守护进程定期检查（默认每 5 分钟）：

| 检查项 | 默认阈值 |
|-------|---------|
| 系统内存使用率 | 75% |
| Claude 进程数 | 15 个 |

**触发清理条件**（满足任一即执行）：
- 内存使用率 ≥ 75%
- Claude 进程数 ≥ 15 个

**僵尸进程识别**：
1. TTY 状态为 `?`（无终端）
2. 进程名匹配 `claude$`
3. 安全规则：**从不**清理有活跃终端的进程

### 日志位置

- **journalctl**: `sudo journalctl -u claude-memory-monitor -f`
- **文件日志**: `~/.claude/plugins/claude-utilities/skills/memory-monitor/memory-monitor.log`

## 使用方法

### 查看服务状态

```bash
# 使用 systemctl
systemctl status claude-memory-monitor

# 或使用控制脚本
~/.claude/plugins/claude-utilities/skills/memory-monitor/scripts/memory-monitor-ctl.sh status
```

### 启动/停止服务

```bash
# 使用 systemctl
sudo systemctl start claude-memory-monitor
sudo systemctl stop claude-memory-monitor
sudo systemctl restart claude-memory-monitor

# 或使用控制脚本（兼容模式）
~/.claude/plugins/claude-utilities/skills/memory-monitor/scripts/memory-monitor-ctl.sh start
~/.claude/plugins/claude-utilities/skills/memory-monitor/scripts/memory-monitor-ctl.sh stop
~/.claude/plugins/claude-utilities/skills/memory-monitor/scripts/memory-monitor-ctl.sh restart
```

### 查看日志

```bash
# 实时查看 systemd 日志
sudo journalctl -u claude-memory-monitor -f

# 实时查看文件日志
tail -f ~/.claude/plugins/claude-utilities/skills/memory-monitor/memory-monitor.log
```

### 手动执行检查

```bash
~/.claude/plugins/claude-utilities/skills/memory-monitor/scripts/memory-monitor.sh
```

### 开机自启管理

```bash
# 启用开机自启
sudo systemctl enable claude-memory-monitor

# 禁用开机自启
sudo systemctl disable claude-memory-monitor
```

## 配置

修改服务文件中的环境变量来调整配置：

```bash
sudo vim /etc/systemd/system/claude-memory-monitor.service
```

| 环境变量 | 默认值 | 说明 |
|---------|-------|------|
| `CHECK_INTERVAL` | 300 | 检查间隔（秒） |
| `MEMORY_THRESHOLD` | 75 | 内存阈值（%） |
| `MAX_CLAUDE_PROCESSES` | 15 | 最大 Claude 进程数 |

修改后需要重新加载并重启服务：

```bash
sudo systemctl daemon-reload
sudo systemctl restart claude-memory-monitor
```

## 卸载

```bash
# 停止并禁用服务
sudo systemctl stop claude-memory-monitor
sudo systemctl disable claude-memory-monitor

# 删除服务文件
sudo rm /etc/systemd/system/claude-memory-monitor.service

# 重新加载 systemd
sudo systemctl daemon-reload
```

## 示例

### 服务状态输出

```
● claude-memory-monitor.service - Claude Memory Monitor Daemon
     Loaded: loaded (/etc/systemd/system/claude-memory-monitor.service; enabled; preset: disabled)
     Active: active (running) since Wed 2026-01-15 10:30:00 CST; 2h ago
   Main PID: 12345 (memory-monitor)
      Tasks: 1 (limit: 4679)
     Memory: 2.5M (peak: 3.2M)
        CPU: 150ms
     CGroup: /system.slice/claude-memory-monitor.service
             └─12345 /bin/bash /path/to/memory-monitor-daemon.sh

Jan 15 10:30:00 host memory-monitor-daemon.sh[12345]: === 内存监控守护进程启动 ===
Jan 15 10:30:00 host memory-monitor-daemon.sh[12345]: 配置: 阈值=75%, 最大进程=15, 间隔=300s
Jan 15 10:35:00 host memory-monitor-daemon.sh[12345]: 检查: 内存=65%, Claude进程=4个
Jan 15 10:40:00 host memory-monitor-daemon.sh[12345]: 检查: 内存=82%, Claude进程=18个
Jan 15 10:40:05 host memory-monitor-daemon.sh[12345]: ⚠️ Claude进程超过阈值 (18 >= 15)
Jan 15 10:40:05 host memory-monitor-daemon.sh[12345]: 发现 14 个僵尸进程
Jan 15 10:40:10 host memory-monitor-daemon.sh[12345]: ✅ 清理完成: 内存 82% -> 68%, 进程 18 -> 4
```

### 手动检查输出

```
🔍 内存监控报告
====================

系统内存: 66% (9.8Gi / 14Gi)
  ✅ 正常
Claude 进程: 4 个
  ✅ 正常
MCP 服务器: 17 个

====================
✅ 系统状态良好，无需清理
```

### 发现僵尸进程时的输出

```
🔍 内存监控报告
====================

系统内存: 85% (11.9GB / 14GB) ⚠️ 超过阈值
Claude 进程: 26 个 ⚠️ 超过阈值
MCP 服务器: 22 个

====================

发现 24 个僵尸会话：
  - PID 12345 (运行 03:26:36, 内存 259MB, 无终端)
  - PID 12346 (运行 03:25:10, 内存 238MB, 无终端)
  [...]

预计可释放: ~5920MB
是否清理这些僵尸进程？(y/N) y
正在清理...
  ✓ 已清理 PID 12345
  ✓ 已清理 PID 12346
  ...

✅ 清理完成
清理后状态:
  系统内存: 65%
  Claude 进程: 4 个
  已清理: 24 个僵尸会话
```

## 故障排查

### 服务无法启动

检查服务文件路径是否正确：

```bash
sudo systemctl status claude-memory-monitor
```

### 日志查看

```bash
# systemd 日志
sudo journalctl -u claude-memory-monitor -n 50

# 文件日志
tail -50 ~/.claude/plugins/claude-utilities/skills/memory-monitor/memory-monitor.log
```

### 清理后内存仍然高

检查其他占用内存的进程：

```bash
ps aux --sort=-%mem | head -20
```

问题可能来自非 Claude 进程。

## 高级

详细实现和修改指南请参考 [REFERENCE.md](REFERENCE.md)。
