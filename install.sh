#!/bin/bash
# claude-utilities 自动安装脚本

set -e

PLUGIN_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOOKS_DIR="$HOME/.claude/hooks/SessionStart"
SKILL_DIR="$PLUGIN_DIR/skills/memory-monitor"

echo "🔧 正在安装 claude-utilities..."

# 1. 创建 hooks 目录
echo "📁 创建 hooks 目录..."
mkdir -p "$HOOKS_DIR"

# 2. 创建 SessionStart hook
echo "📝 配置 SessionStart hook..."
cat > "$HOOKS_DIR/memory-check.sh" << 'EOF'
#!/bin/bash
# Memory Monitor SessionStart Hook
MEMORY_THRESHOLD=85
ZOMBIE_THRESHOLD=10

MEMORY_PERCENT=$(free | grep Mem | awk '{printf("%.0f", ($3/$2) * 100)}')
ZOMBIE_COUNT=$(ps aux | grep "claude$" | grep -v grep | awk '$7 == "?"' | wc -l)

if [ "$MEMORY_PERCENT" -gt $MEMORY_THRESHOLD ] || [ "$ZOMBIE_COUNT" -gt $ZOMBIE_THRESHOLD ]; then
    echo ""
    echo "⚠️  内存监控警告"
    echo "================================"
    echo "系统内存: ${MEMORY_PERCENT}%"
    echo "僵尸进程: ${ZOMBIE_COUNT} 个"
    echo ""
    echo "建议运行: $HOME/.claude/plugins/claude-utilities/skills/memory-monitor/scripts/memory-monitor.sh"
    echo "================================"
    echo ""
fi
EOF

chmod +x "$HOOKS_DIR/memory-check.sh"

# 3. 启动内存监控守护进程
echo "🚀 启动内存监控守护进程..."
bash "$SKILL_DIR/scripts/memory-monitor-ctl.sh" start 2>/dev/null || true

echo ""
echo "✅ 安装完成！"
echo ""
echo "已配置："
echo "  ✓ SessionStart hook (会话开始时检查内存)"
echo "  ✓ 内存监控守护进程 (每5分钟自动检查)"
echo ""
echo "管理命令："
echo "  查看状态: $SKILL_DIR/scripts/memory-monitor-ctl.sh status"
echo "  停止监控: $SKILL_DIR/scripts/memory-monitor-ctl.sh stop"
echo "  查看日志: $SKILL_DIR/scripts/memory-monitor-ctl.sh log"
echo ""
