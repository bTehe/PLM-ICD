#!/bin/bash
#SBATCH --job-name=plm_icd_cn3
#SBATCH --output=plm_icd_cn3.%j.out
#SBATCH --partition=acltr
#SBATCH --nodelist=cn3
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=30
#SBATCH --mem=100G
#SBATCH --gres=gpu:v100:1
#SBATCH --time=1-23:59:59

set -eo pipefail
cd "$SLURM_SUBMIT_DIR"

# --- предотвратить "QT_XCB_GL_INTEGRATION: unbound variable" ---
export QT_XCB_GL_INTEGRATION="${QT_XCB_GL_INTEGRATION-}"

# --- локальные tmp/кеши (ускоряет и предотвращает битый кеш на NFS) ---
mkdir -p "$HOME/tmp"
export TMPDIR="$HOME/tmp"
export CONDA_PKGS_DIRS="$TMPDIR/conda_pkgs"

# --- загрузка Anaconda и инициализация conda (без activate) ---
module purge
module load Anaconda3
eval "$(conda shell.bash hook)"

# --- только conda-forge (чтобы обойти ToS Anaconda и конфликтующие сборки) ---
conda config --remove-key channels || true
conda config --add channels conda-forge
conda config --set channel_priority strict

# --- окружение с Python 3.10 ---
ENV_NAME=coding
if ! conda env list | awk '{print $1}' | grep -qx "$ENV_NAME"; then
  conda create -y -n "$ENV_NAME" -c conda-forge python=3.10
fi

echo ">>> Python в env:"
conda run -n "$ENV_NAME" python -V
conda run -n "$ENV_NAME" python - <<'PY'
import sys, platform; print(sys.executable); print(platform.python_version())
PY

# --- почистить возможный битый кеш astropy и переустановить ---
rm -rf "$HOME/.conda/pkgs/astropy-"* || true
conda clean -a -y

# Ставим бинарный astropy (патч 5.2.2)
conda install -y -n "$ENV_NAME" -c conda-forge "astropy==5.2.2"

# --- инструменты сборки в совместимых версиях ---
conda run -n "$ENV_NAME" python -m pip install --upgrade "pip<25.3" "setuptools<70" wheel
conda run -n "$ENV_NAME" python -m pip -V

# --- установка вашего проекта (editable) ---
cd "$HOME/med_coding"
# Если есть requirements.txt, раскомментируйте:
# conda run -n "$ENV_NAME" python -m pip install -r requirements.txt
conda run -n "$ENV_NAME" python -m pip install -e .

# --- фиксируем первый GPU, если нужно (иначе удалите строку) ---
export CUDA_VISIBLE_DEVICES=0

# --- запуск эксперимента ---
export WANDB_DISABLED=true
srun conda run -n "$ENV_NAME" python -u main.py experiment=mimiciii_full/plm_icd

