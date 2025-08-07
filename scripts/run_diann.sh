#!/bin/bash
# ==============================================================================
# 智能 DIANN 分析脚本 (最终完美版 - 完整两步法)
# ==============================================================================
# 工作流程:
# 1. 检查理论谱图库是否存在，如果不存在则从 FASTA 生成。
# 2. 使用生成的谱图库，分析指定目录下的所有原始数据文件。
# ==============================================================================

# --- 自动确定绝对路径 (让脚本与运行位置无关) ---
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)
PROJECT_ROOT=$(dirname "$SCRIPT_DIR")

echo "--- 项目根目录已确定为: $PROJECT_ROOT ---"
echo "--- 开始 DIANN 智能分析流程 ---"

# --- 用户配置区 (请根据你的实际情况修改这里) ---

# 从这里往下可以进行修改

# 1. DIANN 可执行文件
DIANN_EXECUTABLE="diann"

# 2. 原始数据文件夹路径 (必须是绝对路径!)
RAW_FILE_DIR="/mnt/d/20250626_analysis"

# 3. 蛋白质数据库 (FASTA 格式) 的文件名
FASTA_FILENAME="uniprot-human-swissprot-2025-07-15.fasta"

# 4. CPU 线程数
THREADS=6

# 5. 我们只定义库的基础名，脚本会自动处理 DIANN 生成的后缀
LIBRARY_BASENAME="predicted_library"

# 从这里往上可以进行修改

# --- 自动构建内部文件的绝对路径 ---
FASTA_DB_ABSPATH="$PROJECT_ROOT/data/fasta/$FASTA_FILENAME"
# 这是 DIANN 生成库时使用的“基础路径”
LIBRARY_OUT_PATH="$PROJECT_ROOT/results/$LIBRARY_BASENAME"
# 这是 DIANN 实际生成的谱图库的真实路径
LIBRARY_REAL_PATH="$PROJECT_ROOT/results/${LIBRARY_BASENAME}.predicted.speclib"
# 这是最终报告的输出路径
FINAL_REPORT_OUT_ABSPATH="$PROJECT_ROOT/results/final_report.tsv"

# --- 【核心】准备文件参数列表 ---
echo "--- 正在扫描原始数据文件夹: $RAW_FILE_DIR ---"
# 注意：如果你的文件后缀不是 .raw，请修改下面的 -name "*.raw"。
#比如，如果是.d文件，只要修改-name "*.raw"为-name "*.d"就可以了
mapfile -t RAW_FILES < <(find "$RAW_FILE_DIR" -maxdepth 1 -name "*.raw")

# 检查是否找到了任何文件
if [ ${#RAW_FILES[@]} -eq 0 ]; then
    echo "--- 错误: 在 $RAW_FILE_DIR 中没有找到任何 .raw 文件！---"
    echo "--- 请检查 RAW_FILE_DIR 路径是否正确，以及文件后缀是否匹配。 ---"
    exit 1
fi

# 构建 --f 参数数组，这是解决问题的关键
F_PARAMS=()
for file in "${RAW_FILES[@]}"; do
    F_PARAMS+=(--f "$file")
done
echo "--- 找到 ${#RAW_FILES[@]} 个文件进行分析。 ---"

# --- 智能工作流逻辑 ---
mkdir -p "$PROJECT_ROOT/results"

# 步骤一: 检查并生成理论谱图库
if [ ! -f "$LIBRARY_REAL_PATH" ]; then
    echo "--- 未找到理论谱图库，正在从 FASTA 生成... ---"
    
    $DIANN_EXECUTABLE \
    --fasta "$FASTA_DB_ABSPATH" \
    --fasta-search \
    --cut K*,R*,!*P \
    --missed-cleavages 1 \
    --predictor \
    --out-lib "$LIBRARY_OUT_PATH" \
    --threads $THREADS

    if [ -s "$LIBRARY_REAL_PATH" ]; then
        echo "--- 理论谱图库生成成功！存放于: $LIBRARY_REAL_PATH ---"
    else
        echo "--- 错误: 理论谱图库生成失败！请检查日志。 ---"
        exit 1
    fi
else
    echo "--- 已找到现有的理论谱图库: $LIBRARY_REAL_PATH ---"
fi

# 步骤二: 使用生成的谱图库进行最终分析
echo ""
echo "--- 开始最终分析... ---"

$DIANN_EXECUTABLE \
"${F_PARAMS[@]}" \
--lib "$LIBRARY_REAL_PATH" \
--out "$FINAL_REPORT_OUT_ABSPATH" \
--reanalyse \
--matrices \
--threads $THREADS

# --- 结束 ---
echo ""
echo "--- DIANN 智能分析流程完成 ---"
echo "最终分析报告位于: $FINAL_REPORT_OUT_ABSPATH"