# Claude Utilities

Claude Code 系统实用工具集，包含内存监控和性能优化工具。

## 安装

### 快速安装（推荐）

```bash
git clone https://github.com/yibohub/claude-utilities ~/.claude/plugins/claude-utilities
~/.claude/plugins/claude-utilities/install.sh
```

**一键安装将自动配置：**
- ✅ systemd 系统服务（开机自启）
- ✅ 内存监控守护进程（每 5 分钟自动检查）

### 手动安装

```bash
git clone https://github.com/yibohub/claude-utilities ~/.claude/plugins/claude-utilities
```

## 升级

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
- 停止旧版服务
- 更新配置文件
- 启动新版服务

## 功能

### 内存监控 (Memory Monitor)

通过 systemd 系统服务自动监控内存使用，并清理僵尸 Claude 进程。

**系统服务特性：**
- **开机自启**：系统启动后自动运行
- **自动重启**：异常退出 10 秒后自动恢复
- **持续监控**：每 5 分钟检查一次
- **日志集成**：支持 journalctl 和文件日志

**触发清理条件（满足任一即执行）：**
- 内存使用率 ≥ 75%
- Claude 进程数 ≥ 15 个

**使用方法：**

```bash
# 查看服务状态
systemctl status claude-memory-monitor

# 停止服务
sudo systemctl stop claude-memory-monitor

# 启动服务
sudo systemctl start claude-memory-monitor

# 重启服务
sudo systemctl restart claude-memory-monitor

# 查看实时日志
sudo journalctl -u claude-memory-monitor -f

# 手动执行一次检查
~/.claude/plugins/claude-utilities/skills/memory-monitor/scripts/memory-monitor.sh
```

**配置：**

### 永久修改

编辑系统服务文件：

```bash
sudo vim /etc/systemd/system/claude-memory-monitor.service
```

修改环境变量：
```ini
Environment="CHECK_INTERVAL=300"
Environment="MEMORY_THRESHOLD=75"
Environment="MAX_CLAUDE_PROCESSES=15"
```

修改后重新加载并重启：
```bash
sudo systemctl daemon-reload
sudo systemctl restart claude-memory-monitor
```

### 临时修改（手动检查时）

```bash
MEMORY_THRESHOLD=70 MAX_CLAUDE_PROCESSES=20 \
~/.claude/plugins/claude-utilities/skills/memory-monitor/scripts/memory-monitor.sh
```

**配置参数：**

| 变量 | 默认值 | 说明 |
|------|--------|------|
| `CHECK_INTERVAL` | 300 | 检查间隔（秒） |
| `MEMORY_THRESHOLD` | 75 | 内存告警阈值 (%) |
| `MAX_CLAUDE_PROCESSES` | 15 | 最大进程数 |
| `AUTO_CLEAN` | false | 跳过确认直接清理 |

## 插件结构

```
claude-utilities/
├── .claude-plugin/
│   └── plugin.json           # 插件元数据
├── skills/
│   └── memory-monitor/
│       ├── SKILL.md          # 技能入口
│       ├── REFERENCE.md      # 技术参考
│       └── scripts/          # 可执行脚本
└── README.md                 # 本文件
```

## 开发

### 添加新技能

1. 在 `skills/` 下创建新目录
2. 添加 `SKILL.md` 文件（含正确的 frontmatter）
3. 添加可选的 `REFERENCE.md` 详细文档
4. 在 `scripts/` 子目录添加脚本

示例结构：
```
skills/your-skill/
├── SKILL.md          # 必需
├── REFERENCE.md      # 可选
└── scripts/          # 可选
    └── your-script.sh
```

### 技能 Frontmatter 模板

```yaml
---
name: your-skill-name
description: 功能说明以及使用时机
---

# 技能名称

## 快速开始
直接可执行的指导...
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

# 删除插件目录
rm -rf ~/.claude/plugins/claude-utilities
```

## 贡献

欢迎贡献！请随时提交 Pull Request。

## 许可证

MIT License - 详见 LICENSE 文件

## 作者

**yibohub** - [GitHub](https://github.com/yibohub)

## 致谢

- 遵循 [Claude Code Plugin Specification](https://github.com/anthropics/skills) 构建
- 源于对长时间 Claude 会话更好内存管理的需求
