#!/bin/bash
# ==============================================================================
# 智能 DIANN 分析脚本 - 阶段一: 谱图库生成
# ==============================================================================
# 工作流程:
# 1. 检查理论谱图库 (PREDICTED_LIBRARY) 是否存在。
# 2. 如果不存在，则根据指定的 FASTA 和酶切参数，生成一个理论预测谱图库。
# 3. 如果已存在，则跳过生成步骤。
# ==============================================================================

# --- 自动确定绝对路径 (让脚本与运行位置无关) ---
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)
PROJECT_ROOT=$(dirname "$SCRIPT_DIR")

echo "--- 项目根目录已确定为: $PROJECT_ROOT ---"
echo "--- 开始 DIANN 谱图库生成流程 ---"

# --- 用户配置区 (请根据你的实际情况修改这里) ---

# 1. DIANN 可执行文件
DIANN_EXECUTABLE="diann"

# 2. 蛋白质数据库 (FASTA 格式) 的文件名
FASTA_FILENAME="uniprot-human-swissprot-2025-07-15.fasta"

# 3. CPU 线程数
THREADS=6

# --- 自动构建内部文件的绝对路径 ---
FASTA_DB_ABSPATH="$PROJECT_ROOT/data/fasta/$FASTA_FILENAME"
PREDICTED_LIBRARY_ABSPATH="$PROJECT_ROOT/results/predicted_library.tsv"

# --- 智能建库逻辑 ---
# 确保 results 目录存在
mkdir -p "$PROJECT_ROOT/results"

# 检查理论谱图库是否存在
if [ ! -f "$PREDICTED_LIBRARY_ABSPATH" ]; then
    echo "--- 未找到理论谱图库 ($PREDICTED_LIBRARY_ABSPATH) ---"
    echo "--- 正在从 FASTA 文件生成新的理论谱图库... ---"

    # 【核心命令】使用我们验证成功的参数来生成理论库
    $DIANN_EXECUTABLE \
    --fasta "$FASTA_DB_ABSPATH" \
    --fasta-search \
    --cut K*,R*,!*P \
    --missed-cleavages 1 \
    --predictor \
    --out-lib "$PREDICTED_LIBRARY_ABSPATH" \
    --threads $THREADS

    # 检查谱图库文件是否被成功创建且内容不为空
    if [ -s "$PREDICTED_LIBRARY_ABSPATH" ]; then
        echo "--- 理论谱图库生成成功！存放于: $PREDICTED_LIBRARY_ABSPATH ---"
    else
        echo "--- 错误: 理论谱图库生成失败！文件为空或不存在。请检查上面的日志。 ---"
        exit 1 # 如果建库失败，则立即退出脚本
    fi
else
    echo "--- 已找到现有的理论谱图库: $PREDICTED_LIBRARY_ABSPATH ---"
    echo "--- 无需重新生成。 ---"
fi

echo ""
echo "--- DIANN 谱图库生成流程完成 ---"