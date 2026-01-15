---
name: memory-monitor
description: Monitor system memory usage and automatically clean up zombie Claude processes. Use when system is slow, memory usage is high, or when user mentions memory issues, zombie processes, or performance problems.
---

# Memory Monitor

Monitor system memory usage and automatically clean up zombie Claude processes to maintain system performance.

## Quick Start

Check current memory status and clean up zombie processes:

```bash
~/.claude/skills/memory-monitor/memory-monitor.sh
```

For automatic monitoring, start the daemon:

```bash
~/.claude/skills/memory-monitor/memory-monitor-ctl.sh start
```

## When to Use

- System feels slow or sluggish
- Memory usage is abnormally high
- Multiple Claude sessions are running
- User mentions "memory", "performance", "zombie processes"
- Periodic maintenance (recommend running weekly)

## How It Works

### Detection Strategy

The script identifies zombie Claude processes by checking:
1. **TTY status**: Zombies have `?` in the TTY column (no terminal)
2. **Process name**: Matches `claude$` (main Claude processes)
3. **Memory usage**: Calculates total memory that can be reclaimed

Zombie processes are created when:
- Terminal window closes without terminating Claude
- Network interruption leaves orphaned sessions
- System crashes leave residual processes

### Safety Rules

- **Never** kills processes with active terminals (preserves user sessions)
- **Never** kills non-Claude processes
- Requires confirmation before cleaning (unless AUTO_CLEAN is enabled)
- Logs all actions for audit trail

## Instructions

### Manual Check and Clean

Run the main script to check current status:

```bash
~/.claude/skills/memory-monitor/memory-monitor.sh
```

The script will:
1. Display current memory usage percentage
2. Count Claude and MCP server processes
3. Identify zombie processes (TTY = `?`)
4. Ask for confirmation before cleaning
5. Display memory freed after cleanup

### Automatic Monitoring

Start the daemon for continuous monitoring:

```bash
# Start daemon
~/.claude/skills/memory-monitor/memory-monitor-ctl.sh start

# Check status
~/.claude/skills/memory-monitor/memory-monitor-ctl.sh status

# View live logs
~/.claude/skills/memory-monitor/memory-monitor-ctl.sh log

# Stop daemon
~/.claude/skills/memory-monitor/memory-monitor-ctl.sh stop
```

The daemon runs every 5 minutes and automatically cleans when:
- Memory usage exceeds 75%
- Claude process count exceeds 8

### One-Time Check

Check without cleanup:

```bash
~/.claude/skills/memory-monitor/memory-monitor-ctl.sh check
```

### Auto-Clean Mode

Skip confirmation prompt:

```bash
AUTO_CLEAN=true ~/.claude/skills/memory-monitor/memory-monitor.sh
```

## Configuration

Environment variables:

| Variable | Default | Description |
|----------|---------|-------------|
| `MEMORY_THRESHOLD` | 80 | Memory % that triggers warning |
| `MAX_CLAUDE_PROCESSES` | 10 | Max Claude processes before warning |
| `AUTO_CLEAN` | false | Skip confirmation prompt |

Example:

```bash
MEMORY_THRESHOLD=70 MAX_CLAUDE_PROCESSES=5 ~/.claude/skills/memory-monitor/memory-monitor.sh
```

## Examples

**Example 1: Normal State**

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

**Example 2: Zombies Found**

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

**Example 3: Daemon Status**

```bash
$ ~/.claude/skills/memory-monitor/memory-monitor-ctl.sh status
✅ 守护进程运行中 (PID: 12345)
📋 日志: tail -f ~/.claude/skills/memory-monitor.log

最近日志:
[2026-01-15 12:30:00] 检查: 内存=65%, Claude进程=4个
[2026-01-15 12:35:00] 检查: 内存=68%, Claude进程=4个
[2026-01-15 12:40:00] 检查: 内存=72%, Claude进程=6个
```

## Scripts

| Script | Purpose |
|--------|---------|
| `memory-monitor.sh` | Main check and clean script |
| `memory-monitor-daemon.sh` | Background daemon (do not run directly) |
| `memory-monitor-ctl.sh` | Control script: start/stop/status/check/log |

## Output Template

The script produces standardized output:

```
🔍 内存监控报告
====================

系统内存: {X}% ({used} / {total})
  {status}
Claude 进程: {N} 个
  {status}
MCP 服务器: {N} 个

====================

{zombie details or success message}
```

## Guidelines

- Always show status before taking action
- Never kill processes with active terminals
- Log all actions for troubleshooting
- Use daemon for production environments
- Run manually for one-time cleanup
- Check logs if unexpected behavior occurs
- Adjust thresholds based on system capacity

## Troubleshooting

**Problem: Script shows "❌ 守护进程已在运行" but daemon isn't working**

Solution: The daemon may have crashed. Run:
```bash
~/.claude/skills/memory-monitor/memory-monitor-ctl.sh stop
~/.claude/skills/memory-monitor/memory-monitor-ctl.sh start
```

**Problem: Memory still high after cleanup**

Solution: Check what's using memory:
```bash
ps aux --sort=-%mem | head -20
```
The issue may be non-Claude processes.

**Problem: Script kills active session**

This should never happen. Report the bug with:
```bash
ps aux | grep "claude$" | grep -v grep
```

## Advanced

For detailed implementation and modification guide, see [REFERENCE.md](REFERENCE.md).
