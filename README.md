# Claude Utilities

System utilities for Claude Code including memory monitoring and performance optimization tools.

## Installation

### Quick Install (Recommended)

```bash
git clone https://github.com/yibohub/claude-utilities ~/.claude/plugins/claude-utilities
~/.claude/plugins/claude-utilities/install.sh
```

**一键安装将自动配置：**
- ✅ SessionStart hook（会话开始时检查内存）
- ✅ 内存监控守护进程（每5分钟自动检查）

### Manual Installation

```bash
git clone https://github.com/yibohub/claude-utilities ~/.claude/plugins/claude-utilities
```

## Upgrade

**⚠️ 注意：升级时不要使用 `git clone`，目录已存在会导致报错**

### 一键升级（推荐）

```bash
~/.claude/plugins/claude-utilities/upgrade.sh
```

### 手动升级

```bash
cd ~/.claude/plugins/claude-utilities
git pull
./update.sh
```

升级脚本会自动：
- 停止旧版守护进程
- 更新配置文件
- 启动新版守护进程

## Features

### Memory Monitor

Automatically monitors system memory usage and cleans up zombie Claude processes to maintain performance.

**Proactive Monitoring (NEW):**
- **Session start**: Automatically checks if memory > 85% or zombie processes > 10
- **During tasks**: Rechecks every 10 minutes during long-running tasks
- **Silent operation**: No alerts when memory < 80% AND zombie processes < 5

**When to use:**
- Automatic: At session start if memory > 85% or zombie processes > 10
- Automatic: During complex tasks if memory degrades
- Manual: System feels slow or sluggish
- Manual: Memory usage is abnormally high
- Manual: Multiple Claude sessions are running

**Usage:**
```bash
# Manual check
~/.claude/plugins/claude-utilities/skills/memory-monitor/scripts/memory-monitor.sh

# Start daemon (automatic monitoring)
~/.claude/plugins/claude-utilities/skills/memory-monitor/scripts/memory-monitor-ctl.sh start

# Check daemon status
~/.claude/plugins/claude-utilities/skills/memory-monitor/scripts/memory-monitor-ctl.sh status

# Stop daemon
~/.claude/plugins/claude-utilities/skills/memory-monitor/scripts/memory-monitor-ctl.sh stop
```

**Configuration:**

Environment variables:
- `MEMORY_THRESHOLD`: Memory % that triggers warning (default: 80)
- `MAX_CLAUDE_PROCESSES`: Max Claude processes before warning (default: 10)
- `AUTO_CLEAN`: Skip confirmation prompt (default: false)

Example:
```bash
MEMORY_THRESHOLD=70 AUTO_CLEAN=true ~/.claude/plugins/claude-utilities/skills/memory-monitor/scripts/memory-monitor.sh
```

## Plugin Structure

```
claude-utilities/
├── .claude-plugin/
│   └── plugin.json           # Plugin metadata
├── skills/
│   └── memory-monitor/
│       ├── SKILL.md          # Skill entry point
│       ├── REFERENCE.md      # Technical reference
│       └── scripts/          # Executable scripts
└── README.md                 # This file
```

## Development

### Adding New Skills

1. Create a new directory under `skills/`
2. Add a `SKILL.md` file with proper frontmatter
3. Add optional `REFERENCE.md` for detailed docs
4. Add any scripts in a `scripts/` subdirectory

Example structure:
```
skills/your-skill/
├── SKILL.md          # Required
├── REFERENCE.md      # Optional
└── scripts/          # Optional
    └── your-script.sh
```

### Skill Frontmatter Template

```yaml
---
name: your-skill-name
description: What it does AND when to use it
---

# Your Skill Name

## Quick Start
Immediate actionable guidance...
```

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

MIT License - see LICENSE file for details

## Author

**yibohub** - [GitHub](https://github.com/yibohub)

## Acknowledgments

- Built following [Claude Code Plugin Specification](https://github.com/anthropics/skills)
- Inspired by the need for better memory management in long-running Claude sessions
