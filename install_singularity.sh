#!/usr/bin/env bash
###############################################################################
# SuperPoint‑Transformer stack installer (runs INSIDE the Singularity build)
###############################################################################

# -------- configuration ------------------------------------------------------
CONDA_DIR=${1:-/opt/conda}     # first CLI arg or /opt/conda
CONDA_BIN="${CONDA_DIR}/bin/conda"
PYTHON_VER=3.8
TORCH_VER=2.2.0
CUDA_OK=("11.8" "12.1")
###############################################################################

# -------- pretty helpers -----------------------------------------------------
step () { printf "\n\033[1;34m⭐ %s\033[0m\n" "$*"; }
ok   () { printf "\033[1;32m✅ %s\033[0m\n" "$*"; }
die  () { printf "\033[1;31m❌ %s\033[0m\n" "$*"; exit 1; }
run  () { "$@"; local s=$?; ((s==0)) && ok "$1" || die "$1"; }

# -------- sanity -------------------------------------------------------------
[[ -x "$CONDA_BIN" ]] || die "conda executable not found at $CONDA_BIN"

CUDA_VER=$(nvcc --version | awk -F'release ' '/release/{print $2}' | cut -d',' -f1)
[[ " ${CUDA_OK[*]} " == *" $CUDA_VER "* ]] || \
   die "CUDA $CUDA_VER not supported (want ${CUDA_OK[*]})"

# -------- activate base ------------------------------------------------------
step "Activating conda base"
source "${CONDA_DIR}/etc/profile.d/conda.sh"
"$CONDA_BIN" activate base || die "conda activate base failed"

# -------- 1. ensure python / pip --------------------------------------------
run "$CONDA_BIN" install -y python=$PYTHON_VER pip nb_conda_kernels

# -------- 2. general PyPI packages ------------------------------------------
step "Installing general Python packages"
run pip install \
     matplotlib plotly jupyterlab ipywidgets jupyter-dash notebook ipykernel \
     plyfile h5py colorhash seaborn numba pytorch-lightning pyrootutils \
     hydra-core hydra-colorlog hydra-submitit-launcher rich torch_tb_profiler \
     wandb open3d gdown ipyfilechooser

# -------- 3. Torch / CUDA wheels --------------------------------------------
step "Installing PyTorch ${TORCH_VER} (CUDA ${CUDA_VER})"
run pip install torch==${TORCH_VER} torchvision \
     --index-url https://download.pytorch.org/whl/cu${CUDA_VER/./}

step "Installing PyG wheels"
PYG_URL=https://data.pyg.org/whl/torch-${TORCH_VER}+cu${CUDA_VER/./}.html
run pip install torch_scatter torch_cluster pyg_lib -f "$PYG_URL"
run pip install torch_geometric -f "$PYG_URL"

# -------- helper for git clones ---------------------------------------------
clone_if_missing () {
  local repo=$1 dir=$2
  [[ -d "$dir/.git" ]] || git clone --recursive "$repo" "$dir"
}

# -------- 4. FRNN ------------------------------------------------------------
step "Building FRNN"
clone_if_missing https://github.com/lxxue/FRNN.git src/dependencies/FRNN
run bash -c "cd src/dependencies/FRNN/external/prefix_sum && python setup.py install >/dev/null"
run bash -c "cd src/dependencies/FRNN && python setup.py install >/dev/null"

# -------- 5. grid‑graph ------------------------------------------------------
step "Building grid_graph"
clone_if_missing https://gitlab.com/1a7r0ch3/grid-graph.git src/dependencies/grid_graph
run bash -c "cd src/dependencies/grid_graph/python && python setup.py install >/dev/null"

# -------- 6. parallel‑cut‑pursuit -------------------------------------------
step "Building parallel_cut_pursuit"
clone_if_missing https://gitlab.com/1a7r0ch3/parallel-cut-pursuit.git \
                 src/dependencies/parallel_cut_pursuit
run bash -c "cd src/dependencies/parallel_cut_pursuit/python && python setup.py install >/dev/null"

# -------- 7. point_geometric_features ---------------------------------------
step "Installing point_geometric_features"
run "$CONDA_BIN" install -y -c conda-forge libstdcxx-ng
run pip install git+https://github.com/drprojects/point_geometric_features.git

# -------- done --------------------------------------------------------------
ok "SuperPoint‑Transformer installed in conda *base*"
