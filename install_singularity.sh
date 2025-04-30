#!/bin/bash

# Optional argument: conda directory (default to /opt/conda)
CONDA_DIR=${1:-/opt/conda}
PYTHON=3.8
TORCH=2.2.0
PROJECT_NAME=base
CUDA_SUPPORTED=("11.8" "12.1")

# === Step 1: Prepare environment ===
set -e
HERE=$(realpath $(dirname "$0"))
cd "$HERE"

# Check CUDA version
echo "⭐ Checking for supported CUDA"
CUDA_VERSION=$(nvcc --version | grep release | sed 's/.* release //' | sed 's/,.*//')
if [[ ! " ${CUDA_SUPPORTED[*]} " =~ " ${CUDA_VERSION} " ]]; then
  echo "❌ Found unsupported CUDA version: ${CUDA_VERSION}"
  echo "   Supported: ${CUDA_SUPPORTED[*]}"
  exit 1
fi

# Activate conda
echo "⭐ Activating conda from $CONDA_DIR"
source "${CONDA_DIR}/etc/profile.d/conda.sh"
conda activate base

# Optionally set Python version
echo "⭐ Setting Python version to $PYTHON"
conda install python=$PYTHON -y

# === Step 2: Install PyTorch from custom index ===
echo "⭐ Installing PyTorch $TORCH with CUDA ${CUDA_VERSION}"
pip install torch==${TORCH} torchvision --index-url https://download.pytorch.org/whl/cu${CUDA_VERSION/./}

# === Step 3: Install other Python packages from default PyPI ===
echo "⭐ Installing general Python packages"
pip install --index-url https://pypi.org/simple \
  matplotlib \
  plotly==5.9.0 \
  "jupyterlab>=3" \
  "ipywidgets>=7.6" \
  "notebook>=5.3" \
  jupyter-dash \
  ipykernel \
  torchmetrics==0.11.4 \
  pyg_lib \
  torch_scatter \
  torch_cluster \
  torch_geometric==2.3.0 \
  plyfile \
  h5py \
  colorhash \
  seaborn \
  numba \
  pytorch-lightning \
  pyrootutils \
  hydra-core \
  hydra-colorlog \
  hydra-submitit-launcher \
  rich \
  torch_tb_profiler \
  wandb \
  open3d \
  gdown \
  ipyfilechooser

# === Step 4: Fix for point_geometric_features ===
echo "⭐ Installing conda-forge libstdcxx-ng"
conda install -c conda-forge libstdcxx-ng -y
pip install git+https://github.com/drprojects/point_geometric_features.git

# === Step 5: Install FRNN ===
echo "⭐ Installing FRNN"
git clone --recursive https://github.com/lxxue/FRNN.git src/dependencies/FRNN
cd src/dependencies/FRNN/external/prefix_sum
python setup.py install
cd ..
python setup.py install
cd "$HERE"

# === Step 6: Install Parallel Cut-Pursuit ===
echo "⭐ Installing Parallel Cut-Pursuit"
git clone https://gitlab.com/1a7r0ch3/parallel-cut-pursuit.git src/dependencies/parallel_cut_pursuit
git clone https://gitlab.com/1a7r0ch3/grid-graph.git src/dependencies/grid_graph
python scripts/setup_dependencies.py build_ext

echo
echo "🚀 Successfully installed Superpoint Transformer into Conda base environment"
