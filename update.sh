#!/bin/bash
# CleanClaude 升级脚本

set -e

INSTALL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SERVICE_NAME="claude-memory-monitor"
SERVICE_FILE="/etc/systemd/system/${SERVICE_NAME}.service"

echo "🔄 正在升级 CleanClaude..."

# 检查系统服务是否已安装
if [ ! -f "$SERVICE_FILE" ]; then
    echo "⚠️  未检测到系统服务安装，请先运行 ./install.sh"
    exit 1
fi

# 1. 停止服务
echo "🛑 停止旧版服务..."
sudo systemctl stop "$SERVICE_NAME" 2>/dev/null || true

# 2. 确保日志目录存在
VAR_DIR="$INSTALL_DIR/var"
mkdir -p "$VAR_DIR"

# 3. 重新生成服务文件
echo "📝 更新系统服务配置..."
CURRENT_USER="$(whoami)"
CURRENT_GROUP="$(id -gn)"
DAEMON_SCRIPT="$INSTALL_DIR/lib/memory-monitor-daemon.sh"
LOG_FILE="$VAR_DIR/memory-monitor.log"
LOG_DIR="$VAR_DIR"
SERVICE_TEMPLATE="$INSTALL_DIR/systemd/${SERVICE_NAME}.service"

sed -e "s|USER_PLACEHOLDER|$CURRENT_USER|g" \
    -e "s|GROUP_PLACEHOLDER|$CURRENT_GROUP|g" \
    -e "s|WORKING_DIR_PLACEHOLDER|$INSTALL_DIR|g" \
    -e "s|DAEMON_SCRIPT_PLACEHOLDER|$DAEMON_SCRIPT|g" \
    -e "s|LOG_FILE_PLACEHOLDER|$LOG_FILE|g" \
    -e "s|LOG_DIR_PLACEHOLDER|$LOG_DIR|g" \
    "$SERVICE_TEMPLATE" > /tmp/"$SERVICE_NAME.service"

sudo mv /tmp/"$SERVICE_NAME.service" "$SERVICE_FILE"
sudo chmod 644 "$SERVICE_FILE"

# 4. 重新加载并启动服务
echo "🚀 启动新版服务..."
sudo systemctl daemon-reload
sudo systemctl enable "$SERVICE_NAME"
sudo systemctl start "$SERVICE_NAME"

# 等待服务启动
sleep 2

# 5. 检查服务状态
if systemctl is-active --quiet "$SERVICE_NAME"; then
    echo "✅ 升级成功！"
else
    echo "❌ 服务启动失败，查看状态："
    sudo systemctl status "$SERVICE_NAME" --no-pager
    exit 1
fi

echo ""
echo "管理命令："
echo "  查看状态: systemctl status $SERVICE_NAME"
echo "  查看日志: sudo journalctl -u $SERVICE_NAME -f"
echo "  快捷控制: $INSTALL_DIR/bin/memory-monitor-ctl.sh {start|stop|restart|status|log}"
echo ""
