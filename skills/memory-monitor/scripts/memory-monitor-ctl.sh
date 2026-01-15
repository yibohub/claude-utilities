#!/bin/bash
# Memory Monitor Control
# 快速启动/停止/查看内存监控守护进程

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DAEMON="$SCRIPT_DIR/memory-monitor-daemon.sh"
PIDFILE="$SCRIPT_DIR/../memory-monitor.pid"
LOGFILE="$SCRIPT_DIR/../memory-monitor.log"

case "${1:-status}" in
    start)
        if [ -f "$PIDFILE" ]; then
            PID=$(cat "$PIDFILE")
            if ps -p "$PID" > /dev/null 2>&1; then
                echo "❌ 守护进程已在运行 (PID: $PID)"
                exit 1
            else
                rm -f "$PIDFILE"
            fi
        fi

        echo "🚀 启动内存监控守护进程..."
        nohup "$DAEMON" > /dev/null 2>&1 &
        echo $! > "$PIDFILE"
        echo "✅ 已启动 (PID: $!)"
        echo "📋 查看日志: tail -f $LOGFILE"
        ;;

    stop)
        if [ ! -f "$PIDFILE" ]; then
            echo "❌ 守护进程未运行"
            exit 1
        fi

        PID=$(cat "$PIDFILE")
        if ps -p "$PID" > /dev/null 2>&1; then
            echo "🛑 停止内存监控守护进程..."
            kill "$PID"
            rm -f "$PIDFILE"
            echo "✅ 已停止"
        else
            echo "❌ 守护进程已停止（清理残留 PID 文件）"
            rm -f "$PIDFILE"
        fi
        ;;

    restart)
        $0 stop
        sleep 1
        $0 start
        ;;

    status)
        if [ -f "$PIDFILE" ]; then
            PID=$(cat "$PIDFILE")
            if ps -p "$PID" > /dev/null 2>&1; then
                echo "✅ 守护进程运行中 (PID: $PID)"
                echo "📋 日志: tail -f $LOGFILE"

                # 显示最近几条日志
                if [ -f "$LOGFILE" ]; then
                    echo ""
                    echo "最近日志:"
                    tail -5 "$LOGFILE"
                fi
            else
                echo "❌ 守护进程未运行（残留 PID 文件）"
                exit 1
            fi
        else
            echo "❌ 守护进程未运行"
            exit 1
        fi
        ;;

    check)
        "$SCRIPT_DIR/memory-monitor.sh"
        ;;

    log)
        if [ -f "$LOGFILE" ]; then
            tail -f "$LOGFILE"
        else
            echo "❌ 日志文件不存在: $LOGFILE"
            exit 1
        fi
        ;;

    *)
        echo "用法: $0 {start|stop|restart|status|check|log}"
        echo ""
        echo "命令:"
        echo "  start   - 启动守护进程"
        echo "  stop    - 停止守护进程"
        echo "  restart - 重启守护进程"
        echo "  status  - 查看运行状态"
        echo "  check   - 立即执行一次检查"
        echo "  log     - 查看实时日志"
        exit 1
        ;;
esac
