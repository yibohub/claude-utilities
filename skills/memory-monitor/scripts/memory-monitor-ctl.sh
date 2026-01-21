#!/bin/bash
# Memory Monitor Control
# 快速启动/停止/查看内存监控守护进程

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DAEMON="$SCRIPT_DIR/memory-monitor-daemon.sh"
PIDFILE="$SCRIPT_DIR/../memory-monitor.pid"
LOGFILE="$SCRIPT_DIR/../memory-monitor.log"
SERVICE_NAME="claude-memory-monitor"

# 检测是否使用 systemd 服务
USE_SYSTEMD=false
if [ -f "/etc/systemd/system/${SERVICE_NAME}.service" ]; then
    USE_SYSTEMD=true
fi

# systemctl 包装函数
systemctl_cmd() {
    if [ "$USE_SYSTEMD" = true ]; then
        systemctl "$@"
    else
        return 1  # 不使用 systemd
    fi
}

case "${1:-status}" in
    start)
        if systemctl_cmd is-active --quiet "$SERVICE_NAME" 2>/dev/null; then
            echo "❌ 系统服务已在运行"
            systemctl status "$SERVICE_NAME" --no-pager
            exit 1
        fi

        if systemctl_cmd start "$SERVICE_NAME" 2>/dev/null; then
            echo "✅ 系统服务已启动"
            systemctl status "$SERVICE_NAME" --no-pager
        else
            # 降级到 nohup 方式
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
        fi
        ;;

    stop)
        if systemctl_cmd stop "$SERVICE_NAME" 2>/dev/null; then
            echo "✅ 系统服务已停止"
        else
            # 降级到 nohup 方式
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
        fi
        ;;

    restart)
        if systemctl_cmd restart "$SERVICE_NAME" 2>/dev/null; then
            echo "✅ 系统服务已重启"
            systemctl status "$SERVICE_NAME" --no-pager
        else
            # 降级到 nohup 方式
            $0 stop
            sleep 1
            $0 start
        fi
        ;;

    status)
        if systemctl_cmd status "$SERVICE_NAME" --no-pager 2>/dev/null; then
            # systemctl status 已输出信息
            :
        elif [ -f "$PIDFILE" ]; then
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
        if systemctl_cmd status "$SERVICE_NAME" --no-pager &>/dev/null; then
            echo "📋 查看 systemd 日志 (Ctrl+C 退出):"
            sudo journalctl -u "$SERVICE_NAME" -f
        elif [ -f "$LOGFILE" ]; then
            tail -f "$LOGFILE"
        else
            echo "❌ 日志文件不存在: $LOGFILE"
            exit 1
        fi
        ;;

    enable)
        if systemctl_cmd enable "$SERVICE_NAME" 2>/dev/null; then
            echo "✅ 系统服务已设置为开机自启"
        else
            echo "❌ 不支持此命令（仅 systemd 模式）"
            exit 1
        fi
        ;;

    disable)
        if systemctl_cmd disable "$SERVICE_NAME" 2>/dev/null; then
            echo "✅ 系统服务已取消开机自启"
        else
            echo "❌ 不支持此命令（仅 systemd 模式）"
            exit 1
        fi
        ;;

    *)
        echo "用法: $0 {start|stop|restart|status|check|log|enable|disable}"
        echo ""
        echo "命令:"
        echo "  start   - 启动守护进程"
        echo "  stop    - 停止守护进程"
        echo "  restart - 重启守护进程"
        echo "  status  - 查看运行状态"
        echo "  check   - 立即执行一次检查"
        echo "  log     - 查看实时日志"
        echo "  enable  - 设置开机自启 (systemd)"
        echo "  disable - 取消开机自启 (systemd)"
        echo ""
        echo "当前模式: $([ "$USE_SYSTEMD" = true ] && echo "systemd 服务" || echo "standalone 守护进程")"
        exit 1
        ;;
esac
