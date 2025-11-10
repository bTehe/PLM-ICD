#!/bin/bash
#SBATCH --job-name=plm_icd_cn9
#SBATCH --output=test_plm_icd_cn9.%j.out
#SBATCH --partition=scavenge
#SBATCH --nodelist=cn9
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=16
#SBATCH --mem=120G
#SBATCH --gres=gpu:a30:1
#SBATCH --time=23:59:59

set -eo pipefail
cd "$SLURM_SUBMIT_DIR"

# --- предотвратить "QT_XCB_GL_INTEGRATION: unbound variable" ---
export QT_XCB_GL_INTEGRATION="${QT_XCB_GL_INTEGRATION-}"

# --- локальные tmp/кеши ---
mkdir -p "$HOME/tmp"
export TMPDIR="$HOME/tmp"
export CONDA_PKGS_DIRS="$TMPDIR/conda_pkgs"

# --- загрузка Anaconda и инициализация conda (без activate) ---
module purge
module load Anaconda3
eval "$(conda shell.bash hook)"

# --- только conda-forge ---
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

# --- инструменты сборки (совместимые версии) ---
conda run -n "$ENV_NAME" python -m pip install --upgrade "pip<25.3" "setuptools<70" wheel
conda run -n "$ENV_NAME" python -m pip -V

# --- установка проекта (editable) ---
cd "$HOME/med_coding"
conda run -n "$ENV_NAME" python -m pip install -e .

# --- фиксируем 1-й GPU и отключаем W&B ---
export CUDA_VISIBLE_DEVICES=0
export WANDB_DISABLED=true

# --- запуск эксперимента (твой набор оверрайдов) ---
srun conda run -n "$ENV_NAME" python -u main.py \
  experiment=mimiciii_full/plm_icd \
  gpu=0 \
  trainer.epochs=0 \
  load_model=files/is72ujzk \
  trainer.print_metrics=true
