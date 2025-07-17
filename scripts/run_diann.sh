#!/bin/bash
# ==============================================================================
# 智能 DIANN 分析脚本 (自动化两步法工作流)
# ==============================================================================
# 工作流程:
# 1. 检查最终的实验谱图库 (PROJECT_LIBRARY) 是否存在。
# 2. 如果不存在，则从 FASTA 和原始数据生成它。
# 3. 如果已存在，则直接使用它进行分析。
# ==============================================================================

echo "--- 开始 DIANN 智能分析流程 ---"

# --- 用户配置区 (请根据你的实际情况修改这里) ---

# 1. DIANN 可执行文件
DIANN_EXECUTABLE="diann"

# 2. 原始数据文件夹路径 (绝对路径)
RAW_FILE_DIR="/mnt/d/20250626_analysis"

# 3. 蛋白质数据库 (FASTA 格式) 的完整路径
#    (仅在生成谱图库时需要)
FASTA_DB="home/judelong/bioinfo/GitHub_projects/DIANN_workflow/data/fasta/uniprot-human-swissprot-2025-07-15.fasta"

# 4. 【核心】最终项目谱图库的路径和文件名
#    这是我们流程的核心检查点。
PROJECT_LIBRARY="./results/project_library.tsv"

# 5. 最终分析报告的输出路径
FINAL_REPORT_OUT="./results/report.tsv"

# 6. CPU 线程数
THREADS=8

# --- 智能工作流逻辑 ---

# 检查输出目录是否存在
mkdir -p ./results

# 步骤一: 检查并生成项目谱图库
if [ ! -f "$PROJECT_LIBRARY" ]; then
    echo "--- 未找到项目谱图库 ($PROJECT_LIBRARY) ---"
    echo "--- 正在从 FASTA 和原始数据生成新的谱图库... ---"

    # 使用 DIANN 从 FASTA 生成谱图库
    $DIANN_EXECUTABLE \
    --f "$RAW_FILE_DIR"/*.raw \
    --fasta "$FASTA_DB" \
    --gen-spec-lib \
    --out-lib "$PROJECT_LIBRARY" \
    --threads $THREADS \
    --verbose 1

    if [ $? -eq 0 ]; then
        echo "--- 谱图库生成成功！---"
    else
        echo "--- 错误: 谱图库生成失败！请检查日志。 ---"
        exit 1 # 如果建库失败，则退出脚本
    fi
else
    echo "--- 已找到现有的项目谱图库: $PROJECT_LIBRARY ---"
    echo "--- 将跳过建库步骤，直接使用此库进行分析。 ---"
fi


# 步骤二: 使用项目谱图库进行最终分析
echo "" # 打印一个空行，让输出更清晰
echo "--- 开始最终分析，使用谱图库: $PROJECT_LIBRARY ---"

$DIANN_EXECUTABLE \
--f "$RAW_FILE_DIR"/*.raw \
--lib "$PROJECT_LIBRARY" \
--out "$FINAL_REPORT_OUT" \
--threads $THREADS \
--verbose 1 \
--matrices \
--reanalyse # <-- 仍然推荐保留，它会用库对数据进行更精细的二次优化

# --- 结束 ---
echo ""
echo "--- DIANN 智能分析流程完成 ---"
echo "最终分析报告位于: $FINAL_REPORT_OUT"