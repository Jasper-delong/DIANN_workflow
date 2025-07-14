# 使用 DIANN 在 Linux 上进行 DIA 质谱数据分析流程
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

本项目提供了一个标准化的、可复现的工作流程，用于在 Linux 系统 (包括 WSL) 上使用 [DIANN](https://github.com/vdemichev/DiaNN) 软件分析数据非依赖采集 (DIA) 的质谱数据。

---

## 目录
1. [环境要求](#1-环境要求-prerequisites)
2. [项目设置](#2-项目设置-setup)
3. [分析流程](#3-分析流程-workflow)
4. [结果文件说明](#4-结果文件说明-outputs)
5. [常见问题](#5-常见问题-faq)

---

## 1. 环境要求 (Prerequisites)

在运行本流程前，请确保你的系统已安装以下软件。所有命令均在 Ubuntu 终端中执行。

*   **操作系统**: Ubuntu 22.04 LTS (或类似发行版)
*   **Git**: 用于版本控制。
    ```bash
    sudo apt update && sudo apt install git
    ```
*   **DIANN**: 本流程测试版本为 `v2.1.0`。
    *   从 [DIANN GitHub Releases](https://github.com/vdemichev/DiaNN/releases) 下载最新的 Linux 可执行文件。
    *   **重要**: 将下载的可执行文件赋予执行权限，并建议将其移动到系统路径中，以便全局调用。
      ```bash
      # 假设下载的文件为 diann-2.1.0.linux.x64
      chmod +x diann-2.1.0.linux.x64
      sudo mv diann-2.1.0.linux.x64 /usr/local/bin/diann
      ```
*   **(可选) 蛋白数据库**: 一个 FASTA 格式的蛋白质序列数据库 (例如，从 UniProt 下载的人类蛋白质组)。

---

## 2. 项目设置 (Setup)

1.  **克隆本项目到本地**:
    ```bash
    git clone https://github.com/[你的用户名]/diann-dia-workflow.git
    cd diann-dia-workflow
    ```

2.  **准备数据和数据库**:
    *   将你的质谱原始文件 (如 `.raw` 或 `.d` 文件) 存放在你电脑的**任何位置**，例如 `~/proteomics_data/raw_files`。**请不要将它们放入本项目文件夹内**。
    *   将你的 FASTA 数据库文件也存放在一个方便访问的位置，例如 `~/proteomics_data/fasta/human.fasta`。

---

## 3. 分析流程 (Workflow)

核心分析流程通过一个 shell 脚本来执行，以确保参数的一致性和可重复性。

### 步骤 1: 配置运行脚本

打开 `scripts/run_diann.sh` 文件 (我们将在下一步创建它)，并修改顶部的变量，以匹配你的文件路径和期望参数。

### 步骤 2: 执行分析

在项目根目录的终端中，运行以下命令：
```bash
bash scripts/run_diann.sh
```
脚本将调用 DIANN 并开始分析。分析过程的日志会直接打印在终端上。分析完成后，所有结果文件将生成在 `results/` 目录下。

---

## 4. 结果文件说明 (Outputs)

分析成功后，`results/` 文件夹中会包含多个文件。最重要的文件是：

*   `report.tsv`: **主要结果文件**。这是一个表格文件，包含了每个前体、肽段和蛋白质在所有样本中的定量信息。这是所有下游统计分析的起点。
*   `report.stats.tsv`: 包含运行统计信息。
*   `speclib.tsv` (可选): 如果在脚本中开启了谱图库生成，这里会存放生成的谱图库。

---

## 5. 常见问题 (FAQ)

*   **Q: 分析速度很慢怎么办?**
    *   **A**: 在 `run_diann.sh` 脚本中，增加 `--threads` 参数的值，使其接近你电脑的 CPU 核心数。

*   **Q: 我应该使用谱图库模式还是直接模式 (FASTA-based)?**
    *   **A**: 本流程默认使用直接模式，它通过 `--fasta` 参数直接从数据库生成预测谱图库。这对于大多数项目来说足够好。如果你有高质量的实验谱图库，可以通过 `--lib` 参数指定。

---

## 如何贡献
欢迎通过 Pull Requests 或 Issues 对本流程提出改进建议。

## 许可证
本项目采用 [MIT License](LICENSE)。
