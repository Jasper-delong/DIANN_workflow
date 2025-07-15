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
    - 使用以下代码可以完成DIA-NN 2.1.0的安装
      ```bash
      # 假设下载的文件为 DIA-NN-2.1.0-Academia-Linux.zip
      #在家目录里建立一个downloads文件
        mkdir -p ~/Downloads
      # 进入 Downloads 文件夹
        cd ~/Downloads
      #下载文件
        wget https://github.com/vdemichev/DiaNN/releases/download/2.0/DIA-NN-2.1.0-Academia-Linux.zip
      #安装解压工具
        sudo apt update
        sudo apt install unzip
      #解压文件
        unzip DIA-NN-2.1.0-Academia-Linux.zip
      #会获得一个文件，名称为 diann-2.1.0
      #在家目录里创建一个新的目录“apps”，专门用于存放下载在linux中的应用
        mkdir -p ~/apps
      #将整个 “diann-2.1.0”移动到“apps”目录里
        mv ~/downloads/diann-2.1.0 ~/apps/
      # 进入 DIANN 的新家
        cd ~/apps/diann-2.1.0
      # 赋予权限
        chmod +x diann-linux
      #创建符号连接（这是最关键的一步）我们要在 /usr/local/bin 里创建一个名为 diann 的“快捷方式”，让它指向我们存放在 ~/apps/diann-2.1.0/ 里的真实程序 diann-linux。
      #语法: sudo ln -s [源文件完整路径] [快捷方式的完整路径]
        sudo ln -s ~/apps/diann-2.1.0/diann-linux /usr/local/bin/diann
      #进行验证
        diann --version
      #会出现如下结果
        DIA-NN 2.1.0 Academia  (Data-Independent Acquisition by Neural Networks)
        Compiled on Mar 23 2025 15:49:03
        Current date and time: Tue Jul 15 08:45:41 2025
        Logical CPU cores: 8..........（后面还有一大串）
      #表示安装成功
       
      ```

---

## 2. 项目设置 (Setup)
本流程遵循将**代码与数据分离**的最佳实践。项目仓库只包含运行流程的代码和脚本，而大型数据文件（如原始数据和FASTA数据库）则存放在本地，不上传至 GitHub。
1.  **克隆本项目到本地**:
    ```bash
    git clone https://github.com/Jasper-delong/diann-dia-workflow.git
    cd diann-dia-workflow
    ```

2.  **下载蛋白质数据库**:
    ```
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
3. **定位你的原始数据**
    将原始文件存（.raw或.d文件）放在你电脑的任何位置
    - **Windows本地存储**:C:\Users\YourUser\Documents\Proteomics_Data (在WSL中对应的路径是 /mnt/c/Users/YourUser/Documents/Proteomics_Data)
    - **集群存储**：/path/to/your/project/on/cluster/raw_files
**重要**：请勿将大型原始数据文件放入本项目文件中


---

## 3. 分析流程 (Workflow)

核心分析流程通过一个 shell 脚本来执行，以确保参数的一致性和可重复性。

### 步骤 1: 配置运行脚本
一切准备就绪后，**请打开 scripts/run_diann.sh 文件，将文件顶部的 RAW_FILE_DIR 和 FASTA_DB 变量修改为指向你刚刚准备好的文件路径。**

**重要！！这里需要自己进行修改，每一次使用前，因为路径都会改变**
  ```
    # scripts/run_diann.sh 中的示例配置

    # --- 用户配置区 (请根据你的实际情况修改这里) ---

    # 1. DIANN 可执行文件 (如果已配置好，保持 'diann' 即可)
    DIANN_EXECUTABLE="diann"

    # 2. 存放原始数据文件 (.raw, .d, 等) 的文件夹路径
    #    重要: 使用绝对路径！
    #    例如，在 Windows 的 D 盘: "/mnt/d/my_dia_data"
    #    或在集群上: "/home/yourname/data/project_x/raw"
    RAW_FILE_DIR="/path/to/your/raw_files"

    # 3. 蛋白质数据库 (FASTA 格式) 的完整路径
    #    它应该位于本项目内的 data/fasta/ 目录下
    FASTA_DB="./data/fasta/uniprot-human-swissprot-2024-05-21.fasta"
    THREADS=8
  ```
  **修改完.sh文件后，可以执行文件内容了**


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

