#!/bin/bash
# Memory Monitor Skill
# 监控内存并自动清理僵尸 Claude 进程

set -euo pipefail

# 配置
MEMORY_THRESHOLD=${MEMORY_THRESHOLD:-80}
MAX_CLAUDE_PROCESSES=${MAX_CLAUDE_PROCESSES:-10}
AUTO_CLEAN=${AUTO_CLEAN:-false}

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "🔍 内存监控报告"
echo "===================="
echo ""

# 1. 检查系统内存
MEMORY_PERCENT=$(free | awk '/Mem/{printf "%.0f", $3/$2 * 100}')
MEMORY_USED=$(free -h | awk '/Mem/{print $3}')
MEMORY_TOTAL=$(free -h | awk '/Mem/{print $2}')

echo "系统内存: ${MEMORY_PERCENT}% (${MEMORY_USED} / ${MEMORY_TOTAL})"

if [ "$MEMORY_PERCENT" -ge "$MEMORY_THRESHOLD" ]; then
    echo -e "  ${RED}⚠️ 超过阈值 (${MEMORY_THRESHOLD}%)${NC}"
    MEMORY_HIGH=true
else
    echo -e "  ${GREEN}✅ 正常${NC}"
    MEMORY_HIGH=false
fi

# 2. 检查 Claude 进程
CLAUDE_COUNT=$(ps aux | grep "claude$" | grep -v grep | wc -l)
echo "Claude 进程: ${CLAUDE_COUNT} 个"

if [ "$CLAUDE_COUNT" -ge "$MAX_CLAUDE_PROCESSES" ]; then
    echo -e "  ${YELLOW}⚠️ 超过阈值 (${MAX_CLAUDE_PROCESSES})${NC}"
    CLAUDE_HIGH=true
else
    echo -e "  ${GREEN}✅ 正常${NC}"
    CLAUDE_HIGH=false
fi

# 3. 检查 MCP 服务器
MCP_COUNT=$(ps aux | grep -E "(mcp-server|chroma-mcp|playwright)" | grep -v grep | wc -l)
echo "MCP 服务器: ${MCP_COUNT} 个"

echo ""
echo "===================="

# 4. 查找僵尸进程
ZOMBIES=$(ps aux | grep "claude$" | grep -v grep | awk '($7 ~ /^[\?]/) {print $2}')

# 5. 判断是否需要清理
NEED_CLEAN=false
if [ "$MEMORY_HIGH" = true ] || [ "$CLAUDE_HIGH" = true ] || [ -n "$ZOMBIES" ]; then
    NEED_CLEAN=true
fi

if [ "$NEED_CLEAN" = false ]; then
    echo -e "${GREEN}✅ 系统状态良好，无需清理${NC}"
    exit 0
fi

# 6. 显示僵尸进程详情
if [ -n "$ZOMBIES" ]; then
    ZOMBIE_COUNT=$(echo "$ZOMBIES" | wc -l)
    echo ""
    echo -e "${YELLOW}发现 ${ZOMBIE_COUNT} 个僵尸会话：${NC}"
    echo "$ZOMBIES" | while read pid; do
        if ps -p "$pid" > /dev/null 2>&1; then
            ELAPSED=$(ps -p "$pid" -o etime= | tr -d ' ')
            MEM=$(ps -p "$pid" -o rss= | awk '{printf "%.0f", $1/1024}')
            echo "  - PID ${pid} (运行 ${ELAPSED}, 内存 ${MEM}MB, 无终端)"
        fi
    done
fi

# 7. 估算可释放内存
if [ -n "$ZOMBIES" ]; then
    RECLAIMABLE=$(echo "$ZOMBIES" | while read pid; do
        ps -p "$pid" -o rss= 2>/dev/null || echo 0
    done | awk '{sum+=$1} END {printf "%.0f", sum/1024}')
    echo ""
    echo -e "${YELLOW}预计可释放: ~${RECLAIMABLE}MB${NC}"
fi

echo ""

# 8. 确认清理（除非自动模式）
if [ "$AUTO_CLEAN" != "true" ]; then
    read -p "是否清理这些僵尸进程？(y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${RED}❌ 取消清理${NC}"
        exit 0
    fi
fi

# 9. 执行清理
echo "正在清理..."
KILLED=0
echo "$ZOMBIES" | while read pid; do
    if kill "$pid" 2>/dev/null; then
        ((KILLED++))
        echo "  ✓ 已清理 PID ${pid}"
    fi
done

echo ""
echo -e "${GREEN}✅ 清理完成${NC}"

# 10. 显示清理后状态
sleep 1
NEW_MEMORY_PERCENT=$(free | awk '/Mem/{printf "%.0f", $3/$2 * 100}')
NEW_CLAUDE_COUNT=$(ps aux | grep "claude$" | grep -v grep | wc -l)

echo "清理后状态:"
echo "  系统内存: ${NEW_MEMORY_PERCENT}%"
echo "  Claude 进程: ${NEW_CLAUDE_COUNT} 个"
echo "  已清理: ${KILLED} 个僵尸会话"
