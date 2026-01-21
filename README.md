# CleanClaude

Claude 僵尸进程清理工具，自动监控并清理内存泄漏。

## 功能特性

- **自动监控**：基于 systemd 的系统服务，开机自启
- **智能清理**：内存或进程数超阈值时自动清理僵尸进程
- **可配置**：支持灵活的阈值和间隔配置
- **日志完整**：支持 systemd journalctl 和文件日志

## 安装

### 快速安装（推荐）

```bash
git clone https://github.com/yibohub/claude-utilities ~/cleanclaude
~/cleanclaude/install.sh
```

**一键安装将自动配置：**
- ✅ systemd 系统服务（开机自启）
- ✅ 僵尸进程清理守护进程（每 5 分钟自动检查）

## 升级

**⚠️ 注意：升级时不要使用 `git clone`，目录已存在会导致报错**

### 一键升级（推荐）

```bash
~/cleanclaude/upgrade.sh
```

### 手动升级

```bash
cd ~/cleanclaude
git pull
./update.sh
```

## 使用方法

### systemd 服务管理

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
```

### 快捷控制脚本

```bash
# 使用控制脚本
~/cleanclaude/bin/memory-monitor-ctl.sh {start|stop|restart|status|log}

# 立即执行一次检查
~/cleanclaude/bin/memory-monitor-ctl.sh check
```

## 配置

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
~/cleanclaude/bin/memory-monitor.sh
```

## 配置参数

| 变量 | 默认值 | 说明 |
|------|--------|------|
| `CHECK_INTERVAL` | 300 | 检查间隔（秒） |
| `MEMORY_THRESHOLD` | 75 | 内存告警阈值 (%) |
| `MAX_CLAUDE_PROCESSES` | 15 | 最大进程数 |
| `AUTO_CLEAN` | false | 跳过确认直接清理 |

## 触发清理条件

满足以下任一条件即执行清理：
- 内存使用率 ≥ 75%
- Claude 进程数 ≥ 15 个

## 项目结构

```
cleanclaude/
├── bin/                        # 可执行脚本
│   ├── memory-monitor.sh       # 手动检查脚本
│   └── memory-monitor-ctl.sh   # 控制脚本
├── lib/                        # 库文件
│   └── memory-monitor-daemon.sh # 守护进程
├── systemd/                    # 系统服务配置
│   └── claude-memory-monitor.service
├── var/                        # 运行时数据（日志、PID）
├── install.sh                  # 安装脚本
├── upgrade.sh                  # 一键升级
├── update.sh                   # 升级逻辑
└── README.md
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

# 删除项目目录
rm -rf ~/cleanclaude
```

## 贡献

欢迎贡献！请随时提交 Pull Request。

## 许可证

MIT License - 详见 LICENSE 文件

## 作者

**yibohub** - [GitHub](https://github.com/yibohub)
