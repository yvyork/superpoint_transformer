#!/bin/bash

# Arguments
CONDA_DIR=${1:-/opt/conda}

# Config
PYTHON=3.8
TORCH=2.2.0
CUDA_SUPPORTED=("11.8" "12.1")

# Sanity check for Conda
if [ ! -d "$CONDA_DIR" ]; then
  echo "❌ Conda directory not found at $CONDA_DIR"
  exit 1
fi

# Enter script directory
HERE=$(dirname "$0")
HERE=$(realpath "$HERE")
cd "$HERE"

# Check CUDA
echo "⭐ Checking for supported CUDA"
CUDA_VERSION=$(nvcc --version | grep release | sed 's/.* release //' | sed 's/,.*//')
if [[ ! " ${CUDA_SUPPORTED[*]} " =~ " ${CUDA_VERSION} " ]]; then
  echo "❌ Found CUDA ${CUDA_VERSION}, but expected one of: ${CUDA_SUPPORTED[*]}"
  exit 1
fi

# Activate Conda base environment
echo "⭐ Activating Conda at $CONDA_DIR"
source "$CONDA_DIR/etc/profile.d/conda.sh"
conda activate base

# Ensure Python version
conda install python=$PYTHON -y

# Install pip and conda helper
conda install pip nb_conda_kernels -y

# ✅ Install general packages first (default PyPI)
echo "⭐ Installing general Python packages from default index"
pip install matplotlib plotly jupyterlab ipywidgets jupyter-dash notebook ipykernel \
    torchmetrics pyg_lib torch_geometric plyfile h5py colorhash seaborn numba \
    pytorch-lightning pyrootutils hydra-core hydra-colorlog hydra-submitit-launcher \
    rich torch_tb_profiler wandb open3d gdown ipyfilechooser

# ✅ Install PyTorch and CUDA-specific packages (with dedicated indexes)
echo "⭐ Installing PyTorch and CUDA-specific packages"
pip install torch==${TORCH} torchvision --index-url https://download.pytorch.org/whl/cu${CUDA_VERSION/./}
pip install torch_scatter torch_cluster -f https://data.pyg.org/whl/torch-${TORCH}+cu${CUDA_VERSION/./}.html

# Install FRNN
echo "⭐ Installing FRNN"
git clone --recursive https://github.com/lxxue/FRNN.git src/dependencies/FRNN
cd src/dependencies/FRNN/external/prefix_sum && python setup.py install
cd .. && python setup.py install
cd "$HERE"

# Fix for pgeof
echo "⭐ Installing point_geometric_features"
conda install -c conda-forge libstdcxx-ng -y
pip install git+https://github.com/drprojects/point_geometric_features.git

# Install Parallel Cut-Pursuit
echo "⭐ Installing Parallel Cut-Pursuit"
git clone https://gitlab.com/1a7r0ch3/parallel-cut-pursuit.git src/dependencies/parallel_cut_pursuit
git clone https://gitlab.com/1a7r0ch3/grid-graph.git src/dependencies/grid_graph
python scripts/setup_dependencies.py build_ext

echo "🚀 SPT successfully installed in Conda base env"
