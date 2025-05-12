#!/usr/bin/env bash
################################################################################
# superpoint‑transformer install script
#
# – works in the *base* conda env that already exists in $CONDA_DIR
# – installs general libraries first (no strict pinning / default PyPI index)
# – then installs CUDA / Torch–specific wheels with the few pins they need
# – every custom C++/CUDA extension (FRNN, grid‑graph, parallel‑cut‑pursuit…) is
#   built and installed, with a status check after each step
################################################################################

############################### configuration ##################################
CONDA_DIR=${1:-/opt/conda}      # first CLI argument or /opt/conda
PYTHON_VER=3.8                  # Python version required by the project
TORCH_VER=2.2.0                 # keep in sync with CUDA wheels
CUDA_OK=("11.8" "12.1")         # CUDA versions we tested
################################################################################

# Pretty helper for step tracking ------------------------------------------------
step() { printf "\n\033[1;34m⭐  %s\033[0m\n" "$*"; }
ok()   { printf "\033[1;32m✅  %s\033[0m\n" "$*"; }
fail() { printf "\033[1;31m❌  %s\033[0m\n" "$*"; exit 1; }

run() { "$@"; local s=$?; ((s==0)) && ok "$1" || fail "$1"; }

# ------------------------------------------------------------------------------
# sanity checks
# ------------------------------------------------------------------------------
[[ -d "$CONDA_DIR" ]] || fail "Conda dir not found at $CONDA_DIR"

CUDA_VER=$(nvcc --version | awk -F'release ' '/release/{print $2}' | cut -d',' -f1)
[[ " ${CUDA_OK[*]} " == *" $CUDA_VER "* ]] || \
  fail "CUDA $CUDA_VER not supported (expected ${CUDA_OK[*]})"

# ------------------------------------------------------------------------------
# activate conda base
# ------------------------------------------------------------------------------
step "Activating conda base env"
source "$CONDA_DIR/etc/profile.d/conda.sh"
conda activate base || fail "Could not activate base environment"

run "conda install -y python=$PYTHON_VER pip nb_conda_kernels"

# ------------------------------------------------------------------------------
# 1️⃣  general Python packages – no pinning, default PyPI
# ------------------------------------------------------------------------------
step "Installing general Python packages (no version pins)"
run pip install \
        matplotlib plotly jupyterlab ipywidgets jupyter-dash notebook ipykernel \
        plyfile h5py colorhash seaborn numba pytorch-lightning pyrootutils \
        hydra-core hydra-colorlog hydra-submitit-launcher rich torch_tb_profiler \
        wandb open3d gdown ipyfilechooser

# ------------------------------------------------------------------------------
# 2️⃣  Torch & friends – minimal pinning + CUDA wheels
# ------------------------------------------------------------------------------
step "Installing Torch ${TORCH_VER} (+ CUDA ${CUDA_VER})"
run pip install torch==${TORCH_VER} torchvision \
       --index-url https://download.pytorch.org/whl/cu${CUDA_VER/./}

step "Installing PyG wheels that match Torch/CUDA"
PYG_URL="https://data.pyg.org/whl/torch-${TORCH_VER}+cu${CUDA_VER/./}.html"
run pip install torch_scatter torch_cluster pyg_lib -f "$PYG_URL"
run pip install torch_geometric -f "$PYG_URL"

# ------------------------------------------------------------------------------
# helper to clone only if the folder is absent
# ------------------------------------------------------------------------------
clone_if_missing () {
  local repo=$1 dir=$2
  [[ -d "$dir/.git" ]] || git clone --recursive "$repo" "$dir"
}

ROOT=$(pwd)

# ------------------------------------------------------------------------------
# 3️⃣  FRNN
# ------------------------------------------------------------------------------
step "Building & installing FRNN"
clone_if_missing https://github.com/lxxue/FRNN.git src/dependencies/FRNN

run bash -c "
  cd src/dependencies/FRNN/external/prefix_sum &&
  python setup.py install                >/dev/null
"

run bash -c "
  cd src/dependencies/FRNN &&
  python setup.py install                >/dev/null
"

# ------------------------------------------------------------------------------
# 4️⃣  grid‑graph
# ------------------------------------------------------------------------------
step "Building & installing grid‑graph"
clone_if_missing https://gitlab.com/1a7r0ch3/grid-graph.git src/dependencies/grid_graph

run bash -c "
  cd src/dependencies/grid_graph/python &&
  python setup.py install                >/dev/null
"

# ------------------------------------------------------------------------------
# 5️⃣  parallel‑cut‑pursuit
# ------------------------------------------------------------------------------
step "Building & installing parallel‑cut‑pursuit"
clone_if_missing https://gitlab.com/1a7r0ch3/parallel-cut-pursuit.git \
                 src/dependencies/parallel_cut_pursuit

run bash -c "
  cd src/dependencies/parallel_cut_pursuit/python &&
  python setup.py install                >/dev/null
"

# ------------------------------------------------------------------------------
# 6️⃣  point_geometric_features (pgeof)
# ------------------------------------------------------------------------------
step "Installing point_geometric_features"
run conda install -y -c conda-forge libstdcxx-ng
run pip install git+https://github.com/drprojects/point_geometric_features.git

# ------------------------------------------------------------------------------
# done 🎉
# ------------------------------------------------------------------------------
ok "SuperPoint‑Transformer stack installed in the *base* environment"
