#!/bin/bash
# claude-utilities 一键升级脚本

PLUGIN_DIR="$HOME/.claude/plugins/claude-utilities"

echo "🔄 正在升级 claude-utilities..."
echo ""

# 检查目录是否存在
if [ ! -d "$PLUGIN_DIR" ]; then
    echo "❌ 插件目录不存在，请先安装："
    echo ""
    echo "  git clone https://github.com/yibohub/claude-utilities ~/.claude/plugins/claude-utilities"
    echo "  ~/.claude/plugins/claude-utilities/install.sh"
    exit 1
fi

# 1. 更新代码
echo "📥 拉取最新代码..."
cd "$PLUGIN_DIR"
git pull

# 2. 执行升级脚本
echo ""
echo "📝 执行升级..."
bash "$PLUGIN_DIR/update.sh"
