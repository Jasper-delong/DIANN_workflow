#!/bin/bash

# ==============================================================================
# DIANN DIA 数据分析运行脚本
# ==============================================================================
# 使用说明:
# 1. 修改下面 "用户配置区" 的变量。
# 2. 在项目根目录的终端中运行: bash scripts/run_diann.sh
# ==============================================================================

echo "--- 开始 DIANN 分析流程 ---"

# --- 用户配置区 (请根据你的实际情况修改这里) ---

# 1. DIANN 可执行文件的路径 (如果已添加到系统路径，则只需写'diann')
DIANN_EXECUTABLE="diann"

# 2. 存放原始数据文件 (.raw, .d, 等) 的文件夹路径
#    重要: 使用绝对路径以避免错误。例如: /home/username/data/raw_files
RAW_FILE_DIR="/path/to/your/raw_files"

# 3. 蛋白质数据库 (FASTA 格式) 的完整路径
FASTA_DB="/path/to/your/protein_database.fasta"

# 4. 分析结果的输出目录 (推荐使用项目内的 results 文件夹)
OUTPUT_DIR="./results"

# 5. 使用的 CPU 线程数
THREADS=8

# --- DIANN 核心命令 (通常无需修改) ---

# 检查输出目录是否存在，如果不存在则创建
mkdir -p $OUTPUT_DIR

# 构建 DIANN 命令
$DIANN_EXECUTABLE \
--f "$RAW_FILE_DIR"/*.raw \
--lib "" \
--fasta "$FASTA_DB" \
--out "$OUTPUT_DIR/report.tsv" \
--out-spec-lib "$OUTPUT_DIR/speclib.tsv" \
--gen-spec-lib \
--threads $THREADS \
--verbose 1 \
--matrices \
--reanalyse

# --- 结束 ---
echo "--- DIANN 分析完成 ---"
echo "主要结果文件位于: $OUTPUT_DIR/report.tsv"