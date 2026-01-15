# Claude Utilities

System utilities for Claude Code including memory monitoring and performance optimization tools.

## Installation

### Via Plugin Marketplace (Recommended)

```bash
/plugin marketplace add https://github.com/yibohub/claude-utilities
/plugin install claude-utilities
```

### Manual Installation

```bash
git clone https://github.com/yibohub/claude-utilities ~/.claude/plugins/claude-utilities
```

## Features

### Memory Monitor

Automatically monitors system memory usage and cleans up zombie Claude processes to maintain performance.

**When to use:**
- System feels slow or sluggish
- Memory usage is abnormally high
- Multiple Claude sessions are running

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
