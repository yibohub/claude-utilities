#!/bin/bash
# Memory Monitor Daemon
# 后台自动监控内存，超阈值时自动清理

# 配置（支持环境变量覆盖）
CHECK_INTERVAL=${CHECK_INTERVAL:-300}  # 检查间隔（秒），默认 5 分钟
MEMORY_THRESHOLD=${MEMORY_THRESHOLD:-75}  # 内存阈值
MAX_CLAUDE_PROCESSES=${MAX_CLAUDE_PROCESSES:-15}  # 最大进程数
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="$SCRIPT_DIR/../memory-monitor.log"

# 确保日志目录存在
mkdir -p "$(dirname "$LOG_FILE")"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

log "=== 内存监控守护进程启动 ==="
log "配置: 阈值=${MEMORY_THRESHOLD}%, 最大进程=${MAX_CLAUDE_PROCESSES}, 间隔=${CHECK_INTERVAL}s"

while true; do
    # 检查内存
    MEMORY_PERCENT=$(free | awk '/Mem/{printf "%.0f", $3/$2 * 100}')
    CLAUDE_COUNT=$(ps aux | grep "claude$" | grep -v grep | wc -l)

    log "检查: 内存=${MEMORY_PERCENT}%, Claude进程=${CLAUDE_COUNT}个"

    # 判断是否需要清理
    NEED_CLEAN=false
    if [ "$MEMORY_PERCENT" -ge "$MEMORY_THRESHOLD" ]; then
        log "⚠️ 内存超过阈值 (${MEMORY_PERCENT}% >= ${MEMORY_THRESHOLD}%)"
        NEED_CLEAN=true
    fi

    if [ "$CLAUDE_COUNT" -ge "$MAX_CLAUDE_PROCESSES" ]; then
        log "⚠️ Claude进程超过阈值 (${CLAUDE_COUNT} >= ${MAX_CLAUDE_PROCESSES})"
        NEED_CLEAN=true
    fi

    # 执行清理
    if [ "$NEED_CLEAN" = true ]; then
        log "开始自动清理..."

        # 查找僵尸进程
        ZOMBIES=$(ps aux | grep "claude$" | grep -v grep | awk '($7 ~ /^[\?]/) {print $2}')

        if [ -n "$ZOMBIES" ]; then
            ZOMBIE_COUNT=$(echo "$ZOMBIES" | wc -l)
            log "发现 ${ZOMBIE_COUNT} 个僵尸进程"

            # 清理
            KILLED=0
            echo "$ZOMBIES" | while read pid; do
                if kill "$pid" 2>/dev/null; then
                    ((KILLED++))
                    log "  ✓ 已清理 PID ${pid}"
                fi
            done

            # 重新检查
            sleep 2
            NEW_MEMORY=$(free | awk '/Mem/{printf "%.0f", $3/$2 * 100}')
            NEW_COUNT=$(ps aux | grep "claude$" | grep -v grep | wc -l)

            log "✅ 清理完成: 内存 ${MEMORY_PERCENT}% -> ${NEW_MEMORY}%, 进程 ${CLAUDE_COUNT} -> ${NEW_COUNT}"
        else
            log "没有发现僵尸进程，跳过清理"
        fi
    fi

    # 等待下次检查
    sleep "$CHECK_INTERVAL"
done
