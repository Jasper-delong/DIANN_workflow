
# 使用 DIANN 在 Linux 上进行 DIA 质谱数据分析流程
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

本项目提供了一个标准化的、可复现的工作流程，用于在 Linux 系统 (包括 WSL) 上使用 [DIANN](https://github.com/vdemichev/DiaNN) 软件分析数据非依赖采集 (DIA) 的质谱数据。

该流程的核心优势在于：
- **环境隔离**: 所有软件依赖（DIANN, .NET）均通过 Conda 环境管理，与主系统完全隔离，保证了极高的可复现性。
- **智能自动化**: 核心脚本能自动检查并生成谱图库，避免重复工作，确保分析一致性。
- **健壮性**: 脚本包含路径和文件检查，能提前发现并报告常见错误。

---

## 目录
1. [环境要求与设置](#1-环境要求与设置-environment-setup)
2. [数据准备与项目克隆](#2-数据准备与项目克隆-data-preparation--project-clone)
3. [执行分析](#3-执行分析-running-the-analysis)
4. [结果文件说明](#4-结果文件说明-outputs)
5. [常见问题](#5-常见问题-faq)

---

## 1. 环境要求与设置 (Environment Setup)

本流程的所有依赖项都通过 [Conda](https://docs.conda.io/en/latest/miniconda.html) 进行管理。以下步骤将指导您如何在**您已有或新建的 Conda 环境**中安装所有必需的软件。

### 步骤 1: 准备并激活 Conda 环境

首先，请确保您已有一个 Conda 环境，并将其激活。如果您没有，可以按以下方式创建一个：

```bash
# (可选) 如果您没有环境，可以创建一个新的
# conda create --name bioinfo python=3.10 -y

# 激活您的目标环境 (将 bioinfo 替换为您的环境名)
conda activate bioinfo
```

### 步骤 2: 在激活的环境中安装 DIANN 及其依赖

在已激活的 Conda 环境中，按顺序执行以下命令。

#### A. 安装 .NET 8.0 SDK (DIANN 必需依赖)

DIANN 需要 .NET 8.0 或更高版本来读取 Thermo .raw 文件。

```bash
# 下载并运行微软官方安装脚本，将其安装到当前 Conda 环境中
wget https://dot.net/v1/dotnet-install.sh -O dotnet-install.sh
chmod +x ./dotnet-install.sh
# --channel 8.0 会自动安装 8.0 系列的最新稳定版
./dotnet-install.sh --channel 8.0 --install-dir $CONDA_PREFIX
rm dotnet-install.sh
```
注意：以上命令安装的是完整的SDK，它包含了Runtime，并能确保所有 dotnet 验证命令正常工作。

#### B. 安装 DIANN

由于 DIANN 没有官方 Conda 包，我们将其程序文件直接安装到当前环境中。

```bash
# 1. 在临时目录下载并解压 DIANN (请从官网确认最新版本链接)
mkdir -p ~/diann_temp_download
cd ~/diann_temp_download
wget https://github.com/vdemichev/DiaNN/releases/download/2.0/DIA-NN-2.1.0-Academia-Linux.zip
unzip DIA-NN-2.1.0-Academia-Linux.zip

# 2. 将 DIANN 程序文件夹移动到当前 Conda 环境的 opt/ 目录下
mkdir -p $CONDA_PREFIX/opt
mv diann-2.1.0 $CONDA_PREFIX/opt/

# 3. 赋予执行权限并创建符号链接
chmod +x $CONDA_PREFIX/opt/diann-2.1.0/diann-linux
ln -s $CONDA_PREFIX/opt/diann-2.1.0/diann-linux $CONDA_PREFIX/bin/diann

# 4. 清理临时下载目录
cd ~
rm -rf ~/diann_temp_download
```

### 步骤 3: 验证安装

在已激活的 Conda 环境中，运行以下命令进行验证：

```bash
dotnet --version
# 期望输出: 8.0.x

diann --version
# 期望输出: DIANN 2.1.0 ...
```

如果两条命令都成功返回版本信息，您的分析环境就已经完美配置！

## 2. 数据准备与项目克隆 (Data Preparation & Project Clone)
### 步骤 1: 克隆本项目
```bash
git clone https://github.com/Jasper-delong/DIANN_workflow.git
cd DIANN_workflow
```

### 步骤 2: 下载蛋白质数据库 (FASTA)

本项目要求将 FASTA 数据库下载到项目内的 data/fasta/ 目录中。.gitignore 文件已配置好，会忽略此目录下的所有文件。

```bash
# 定义将要保存FASTA文件的目录和文件名
FASTA_DIR="./data/fasta"
FASTA_FILENAME="uniprot-human-swissprot-$(date +%Y-%m-%d).fasta"

# 下载并解压
echo "--- 正在从 UniProt 下载人类参考蛋白质组到 ${FASTA_DIR} ---"
wget -O "${FASTA_DIR}/${FASTA_FILENAME}.gz" "https://rest.uniprot.org/uniprotkb/stream?compressed=true&download=true&format=fasta&query=%28reviewed%3Atrue%29+AND+%28model_organism%3A9606%29"

echo "--- 下载完成，正在解压... ---"
gunzip "${FASTA_DIR}/${FASTA_FILENAME}.gz"

echo "--- 数据库准备就绪，存放于: ${FASTA_DIR}/${FASTA_FILENAME} ---"
```

### 步骤 3: 定位你的原始数据

将你的质谱原始文件 (如 .raw 或 .d 文件) 存放在你电脑的任何位置 (例如 /mnt/d/my_dia_data)。重要: 请勿将大型原始数据文件放入本项目文件夹内。

## 3. 执行分析 (Running the Analysis)
### 步骤 1: 配置运行脚本

>[重要！！！]

每次分析前，请务必打开 scripts/run_diann.sh 文件，并根据你的实际情况修改顶部的 用户配置区。

您需要修改的核心变量包括 RAW_FILE_DIR 和 FASTA_DB 的文件名，并确认原始数据的文件后缀 (如 *.raw 或 *.d) 是否正确。脚本内的注释有详细说明。

### 步骤 2: 执行分析

赋予脚本执行权限 (首次运行时必需):

```bash
chmod +x scripts/run_diann.sh
```

运行分析脚本:

```bash
bash scripts/run_diann.sh
```

脚本将自动开始执行。它会首先检查并生成谱图库（如果需要），然后进行最终的定量分析。所有日志都会实时打印在终端上。

4. 结果文件说明 (Outputs)

分析成功后，results/ 文件夹中会包含多个文件。最重要的文件是：

- project_library.tsv: 第一次运行时，根据你的数据和FASTA文件生成的项目专属实验谱图库。后续分析会重复使用此库以保证一致性。

- report.tsv: 主要结果文件。这是一个表格文件，包含了每个前体、肽段和蛋白质在所有样本中的定量信息。这是所有下游统计分析的起点。

- report.stats.tsv: 包含运行统计信息。

5. 常见问题 (FAQ)

Q: 分析速度很慢怎么办?

A: 在 scripts/run_diann.sh 脚本的 用户配置区，增加 THREADS 的值，使其接近你电脑的 CPU 核心数。

Q: 如何重新生成谱图库?

A: 只需手动删除 results/project_library.tsv 这个文件，然后重新运行 bash scripts/run_diann.sh 即可。脚本会自动检测到库文件不存在并重新生成。

Q: 脚本报错说找不到原始文件怎么办?

A: 请检查 run_diann.sh 中的 RAW_FILE_DIR 路径是否为正确的绝对路径，并确认脚本中用于查找文件的后缀（默认为 *.raw）与你的实际文件类型是否匹配。

## 如何贡献

欢迎通过 Pull Requests 或 Issues 对本流程提出改进建议。

## 许可证

本项目采用 MIT License。

