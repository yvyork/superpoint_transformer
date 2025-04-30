#!/bin/bash

# Argument: Conda directory (default to /opt/conda)
CONDA_DIR=${1:-/opt/conda}
PYTHON=3.10
TORCH=2.2.0
PROJECT_NAME=base
CUDA_SUPPORTED=("11.8" "12.1")

set -e  # Stop script on first error

# === Step 1: Preparation ===
HERE=$(realpath "$(dirname "$0")")
cd "$HERE"

echo "⭐ Checking CUDA version"
CUDA_VERSION=$(nvcc --version | grep release | sed 's/.* release //' | sed 's/,.*//')
if [[ ! " ${CUDA_SUPPORTED[*]} " =~ " ${CUDA_VERSION} " ]]; then
  echo "❌ Unsupported CUDA version: ${CUDA_VERSION} (Supported: ${CUDA_SUPPORTED[*]})"
  exit 1
fi
CUDA_INDEX_VERSION=${CUDA_VERSION/./}  # e.g., 12.1 → 121

# === Step 2: Activate Conda ===
echo "⭐ Activating conda from $CONDA_DIR"
source "${CONDA_DIR}/etc/profile.d/conda.sh"
conda activate $PROJECT_NAME

# === Step 3: Set Python version ===
echo "⭐ Installing Python $PYTHON in base environment"
conda install python=$PYTHON -y

# === Step 4: Install PyTorch with correct index ===
echo "⭐ Installing torch $TORCH with CUDA $CUDA_VERSION"
pip install torch==$TORCH torchvision --index-url https://download.pytorch.org/whl/cu$CUDA_INDEX_VERSION

# === Step 5: Install PyG packages from separate index ===
PIP_PYG_INDEX="https://data.pyg.org/whl/torch-${TORCH}+cu${CUDA_INDEX_VERSION}.html"

echo "⭐ Installing pyg_lib, torch_scatter, torch_cluster"
pip install pyg_lib -f $PIP_PYG_INDEX
pip install torch_scatter -f $PIP_PYG_INDEX
pip install torch_cluster -f $PIP_PYG_INDEX

# === Step 6: Install general Python packages from default PyPI ===
echo "⭐ Installing general Python packages"
pip install --index-url https://pypi.org/simple \
  torch_geometric==2.3.0 \
  matplotlib \
  plotly==5.9.0 \
  "jupyterlab>=3" \
  "ipywidgets>=7.6" \
  "notebook>=5.3" \
  jupyter-dash \
  ipykernel \
  torchmetrics==0.11.4 \
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

# === Step 7: Fix for point_geometric_features ===
echo "⭐ Installing point_geometric_features"
conda install -c conda-forge libstdcxx-ng -y
pip install git+https://github.com/drprojects/point_geometric_features.git

# === Step 8: Install FRNN ===
echo "⭐ Installing FRNN"
git clone --recursive https://github.com/lxxue/FRNN.git src/dependencies/FRNN
cd src/dependencies/FRNN/external/prefix_sum
python setup.py install
cd ..
python setup.py install
cd "$HERE"

# === Step 9: Install Parallel Cut-Pursuit ===
echo "⭐ Installing Parallel Cut-Pursuit"
git clone https://gitlab.com/1a7r0ch3/parallel-cut-pursuit.git src/dependencies/parallel_cut_pursuit
git clone https://gitlab.com/1a7r0ch3/grid-graph.git src/dependencies/grid_graph
python scripts/setup_dependencies.py build_ext

echo
echo "🚀 Superpoint Transformer installed successfully in Conda base environment"
