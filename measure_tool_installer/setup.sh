#!/usr/bin/env bash

GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}[INFO] GPU-BOPs 环境自检与配置程序启动...${NC}"

if ! command -v wget &> /dev/null; then
    echo -e "${RED}[WARN] 未检测到 wget，正在安装...${NC}"
    sudo apt-get update && sudo apt-get install -y wget
fi

echo -e "${GREEN}[INFO] 正在检查 Python 运行时...${NC}"

if ! command -v python3 &> /dev/null; then
    echo -e "${RED}[WARN] 未检测到 Python3，正在通过 apt 在线安装...${NC}"
    sudo apt-get update
    sudo apt-get install -y python3 python3-pip
else
    echo -e "${GREEN}[OK] Python3 已安装: $(python3 --version)${NC}"
fi

if ! command -v pip3 &> /dev/null; then
    echo -e "${RED}[WARN] 未检测到 pip3，正在安装...${NC}"
    sudo apt-get install -y python3-pip
fi

echo -e "${GREEN}[INFO] 正在检查依赖库 (torch)...${NC}"
if ! python3 -c "import torch" &> /dev/null; then
     echo -e "${RED}[WARN] 未检测到 torch 库，正在从 PyTorch 源在线安装 (这可能需要几分钟)...${NC}"
     pip3 install torch --extra-index-url https://download.pytorch.org/whl/cu118
else
     echo -e "${GREEN}[OK] torch 库已安装${NC}"
fi


echo -e "${GREEN}[INFO] 正在检查底层分析工具 (Nsight Compute)...${NC}"

if ! command -v ncu &> /dev/null; then
    echo -e "${RED}[WARN] 未检测到 ncu 指令。${NC}"
    echo -e "${GREEN}[INFO] 准备下载 NVIDIA CUDA Toolkit (仅安装工具包，不覆盖显卡驱动)...${NC}"
    
    CUDA_URL="https://developer.download.nvidia.com/compute/cuda/12.2.0/local_installers/cuda_12.2.0_535.54.03_linux.run"
    INSTALLER_NAME="cuda_toolkit_installer.run"

    wget -O "$INSTALLER_NAME" "$CUDA_URL"

    if [ -f "$INSTALLER_NAME" ]; then
        echo -e "${GREEN}[INFO] 下载完成，开始静默安装...${NC}"
        
        sudo sh "$INSTALLER_NAME" --silent --toolkit --override
        
        rm "$INSTALLER_NAME"
        
        if ! grep -q "cuda-12.2/bin" ~/.bashrc; then
            echo 'export PATH=/usr/local/cuda-12.2/bin:$PATH' >> ~/.bashrc
            echo 'export LD_LIBRARY_PATH=/usr/local/cuda-12.2/lib64:$LD_LIBRARY_PATH' >> ~/.bashrc
        fi
        
        export PATH=/usr/local/cuda-12.2/bin:$PATH
        
        if command -v ncu &> /dev/null; then
            echo -e "${GREEN}[SUCCESS] Nsight Compute 安装成功！${NC}"
        else
            echo -e "${RED}[ERROR] 安装看似完成但 ncu 命令仍不可用。请尝试运行 'source ~/.bashrc' 或手动检查 /usr/local/