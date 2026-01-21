#!/bin/bash
# CleanClaude 自动安装脚本

set -e

INSTALL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SERVICE_NAME="claude-memory-monitor"
SERVICE_FILE="/etc/systemd/system/${SERVICE_NAME}.service"
SERVICE_TEMPLATE="$INSTALL_DIR/systemd/${SERVICE_NAME}.service"

# 检测是否已安装（优先检查系统服务）
if systemctl is-active --quiet "$SERVICE_NAME" 2>/dev/null; then
    echo "✅ 系统服务已运行"
    systemctl status "$SERVICE_NAME" --no-pager
    exit 0
elif [ -f "$SERVICE_FILE" ]; then
    echo "⚠️  检测到已安装，如需重启请运行: sudo systemctl restart $SERVICE_NAME"
    echo ""
    systemctl status "$SERVICE_NAME" --no-pager 2>/dev/null || true
    exit 0
fi

echo "🔧 正在安装 CleanClaude..."

# 1. 确保日志目录存在
VAR_DIR="$INSTALL_DIR/var"
mkdir -p "$VAR_DIR"

# 2. 安装系统服务
echo "📦 安装 systemd 系统服务..."
CURRENT_USER="$(whoami)"
CURRENT_GROUP="$(id -gn)"
DAEMON_SCRIPT="$INSTALL_DIR/lib/memory-monitor-daemon.sh"
LOG_FILE="$VAR_DIR/memory-monitor.log"
LOG_DIR="$VAR_DIR"

# 生成实际服务文件（替换占位符）
sed -e "s|USER_PLACEHOLDER|$CURRENT_USER|g" \
    -e "s|GROUP_PLACEHOLDER|$CURRENT_GROUP|g" \
    -e "s|WORKING_DIR_PLACEHOLDER|$INSTALL_DIR|g" \
    -e "s|DAEMON_SCRIPT_PLACEHOLDER|$DAEMON_SCRIPT|g" \
    -e "s|LOG_FILE_PLACEHOLDER|$LOG_FILE|g" \
    -e "s|LOG_DIR_PLACEHOLDER|$LOG_DIR|g" \
    "$SERVICE_TEMPLATE" > /tmp/"$SERVICE_NAME.service"

# 移动到系统目录
sudo mv /tmp/"$SERVICE_NAME.service" "$SERVICE_FILE"
sudo chmod 644 "$SERVICE_FILE"

# 3. 重新加载 systemd 并启动服务
echo "🚀 启动系统服务..."
sudo systemctl daemon-reload
sudo systemctl enable "$SERVICE_NAME"
sudo systemctl start "$SERVICE_NAME"

# 等待服务启动
sleep 2

# 4. 检查服务状态
if systemctl is-active --quiet "$SERVICE_NAME"; then
    echo "✅ 服务启动成功"
else
    echo "❌ 服务启动失败，查看状态："
    sudo systemctl status "$SERVICE_NAME" --no-pager
    exit 1
fi

echo ""
echo "✅ 安装完成！"
echo ""
echo "已配置："
echo "  ✓ systemd 系统服务 (开机自启动)"
echo "  ✓ 僵尸进程清理守护进程 (每5分钟自动检查)"
echo ""
echo "管理命令："
echo "  查看状态: systemctl status $SERVICE_NAME"
echo "  停止服务: sudo systemctl stop $SERVICE_NAME"
echo "  启动服务: sudo systemctl start $SERVICE_NAME"
echo "  重启服务: sudo systemctl restart $SERVICE_NAME"
echo "  查看日志: sudo journalctl -u $SERVICE_NAME -f"
echo "  或查看文件: tail -f $LOG_FILE"
echo ""
echo "快捷控制："
echo "  $INSTALL_DIR/bin/memory-monitor-ctl.sh {start|stop|restart|status|log}"
echo ""
