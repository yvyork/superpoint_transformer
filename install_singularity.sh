#!/bin/bash

# Arguments
CONDA_DIR=${1:-/opt/conda}

# Config
PROJECT_NAME=base
PYTHON=3.8
TORCH=2.2.0
CUDA_SUPPORTED=("11.8" "12.1")

# Sanity check for Conda
if [ ! -d "$CONDA_DIR" ]; then
  echo "Conda directory not found at $CONDA_DIR"
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
  echo "Found CUDA ${CUDA_VERSION}, but expected one of: ${CUDA_SUPPORTED[*]}"
  exit 1
fi

# Activate Conda base environment
echo "⭐ Activating Conda at $CONDA_DIR"
source "$CONDA_DIR/etc/profile.d/conda.sh"
conda activate base

# Optional: Set Python version
conda install python=$PYTHON -y

# Install dependencies
echo "⭐ Installing pip and Conda packages"
conda install pip nb_conda_kernels -y
pip install matplotlib
pip install plotly==5.9.0
pip install "jupyterlab>=3" "ipywidgets>=7.6" jupyter-dash
pip install "notebook>=5.3" "ipywidgets>=7.5"
pip install ipykernel
pip3 install torch==${TORCH} torchvision --index-url https://download.pytorch.org/whl/cu${CUDA_MAJOR}${CUDA_MINOR}
pip install torchmetrics==0.11.4
pip install pyg_lib torch_scatter torch_cluster -f https://data.pyg.org/whl/torch-${TORCH}+cu${CUDA_MAJOR}${CUDA_MINOR}.html
pip install torch_geometric==2.3.0
pip install plyfile
pip install h5py
pip install colorhash
pip install seaborn
pip install numba
pip install pytorch-lightning
pip install pyrootutils
pip install hydra-core --upgrade
pip install hydra-colorlog
pip install hydra-submitit-launcher
pip install rich
pip install torch_tb_profiler
pip install wandb
pip install open3d
pip install gdown
pip install ipyfilechooser

# Install FRNN
echo "⭐ Installing FRNN"
git clone --recursive https://github.com/lxxue/FRNN.git src/dependencies/FRNN
cd src/dependencies/FRNN/external/prefix_sum && python setup.py install
cd .. && python setup.py install
cd "$HERE"

# Fix for pgeof
conda install -c conda-forge libstdcxx-ng -y
pip install git+https://github.com/drprojects/point_geometric_features.git

# Install Parallel Cut-Pursuit
echo "⭐ Installing Parallel Cut-Pursuit"
git clone https://gitlab.com/1a7r0ch3/parallel-cut-pursuit.git src/dependencies/parallel_cut_pursuit
git clone https://gitlab.com/1a7r0ch3/grid-graph.git src/dependencies/grid_graph
python scripts/setup_dependencies.py build_ext

echo "🚀 SPT successfully installed in Conda base env"
