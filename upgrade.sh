#!/bin/bash
# CleanClaude 一键升级脚本

INSTALL_DIR="$HOME/cleanclaude"
# 如果从其他位置运行，检测当前目录
CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "$CURRENT_DIR/install.sh" ]; then
    INSTALL_DIR="$CURRENT_DIR"
fi

echo "🔄 正在升级 CleanClaude..."
echo ""

# 检查目录是否存在
if [ ! -d "$INSTALL_DIR" ]; then
    echo "❌ 安装目录不存在，请先安装："
    echo ""
    echo "  git clone https://github.com/yibohub/claude-utilities ~/cleanclaude"
    echo "  ~/cleanclaude/install.sh"
    exit 1
fi

# 1. 更新代码
echo "📥 拉取最新代码..."
cd "$INSTALL_DIR"
git pull

# 2. 执行升级脚本
echo ""
echo "📝 执行升级..."
bash "$INSTALL_DIR/update.sh"
