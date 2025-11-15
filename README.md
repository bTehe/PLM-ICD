# PLM-ICD on `mimiciii_full` (Reproducibility challenge)

This repository is a fork/customisation of **medical-coding-reproducibility**.

It focuses on reproducing the PLM-ICD results on **MIMIC-III full** using the data pipelines from the *Explainable Prediction of Medical Codes from Clinical Text* line of work.

---

## 1. Installation (local machine)

### 1.1. Clone the repo

```bash
git clone https://github.com/bTehe/PLM-ICD.git PLM-ICD
cd PLM-ICD
```

### 1.2. Create environment

Using conda (recommended):

```bash
conda create -n plmicd-demo python=3.10 -y
conda activate plmicd-demo
pip install -r requirements.txt
```

If you use plain `venv`, the steps are analogous.

---

## 2. Data preparation

This project follows the **Mullenbach-style** MIMIC-III preprocessing from  
*Explainable Prediction of Medical Codes from Clinical Text* via  
[`medical-coding-reproducibility`](https://github.com/JoakimEdin/medical-coding-reproducibility).

### 2.1. Point to your raw MIMIC-III data

1. Download **MIMIC-III v1.4** from PhysioNet into some folder, for example:

   ```bash
   /path/to/mimiciii/
     ADMISSIONS.csv.gz
     DIAGNOSES_ICD.csv.gz
     D_ICD_DIAGNOSES.csv.gz
     NOTEEVENTS.csv.gz
     ...
   ```

2. Open:

   ```text
   src/settings.py
   ```

   and change:

   ```python
   DOWNLOAD_DIRECTORY_MIMICIII = "/absolute/path/to/mimiciii"
   ```

   to the actual path where your **raw** MIMIC-III `.csv.gz` files are stored.

3. (Optional but recommended) Also set where the *processed* MIMIC-III data will be written.  
   For example, to keep everything inside this repo, you can set in `src/settings.py`:

   ```python
   DATA_DIRECTORY_MIMICIII_FULL = "files/data/mimiciii_full"
   DATA_DIRECTORY_MIMICIII_50   = "files/data/mimiciii_50"
   ```

   This way the generated `.feather` and split files will end up under `files/data/...` and match the paths expected by your Hydra configs.

### 2.2. Run the Mullenbach-style preprocessing

If you want to use the **MIMIC-III full** and **MIMIC-III 50** datasets from the
*Explainable Prediction of Medical Codes from Clinical Text*, you need to run:

```bash
python prepare_data/prepare_mimiciii_mullenbach.py
```

This script will:

- read the raw MIMIC-III v1.4 CSV files from `DOWNLOAD_DIRECTORY_MIMICIII`,
- build discharge summaries and label sets,
- generate:

  - `mimiciii_full.feather` + `mimiciii_full_splits.feather`,
  - `mimiciii_50.feather` + `mimiciii_50_splits.feather`,

- and write them into the directories you set via `DATA_DIRECTORY_MIMICIII_FULL` and `DATA_DIRECTORY_MIMICIII_50`
  (for example `files/data/mimiciii_full` and `files/data/mimiciii_50`).

After this, you should have:

```bash
ls files/data/mimiciii_full
# mimiciii_full.feather
# mimiciii_full_splits.feather
# (optionally) ALL_CODES.txt

ls files/data/mimiciii_50
# mimiciii_50.feather
# mimiciii_50_splits.feather
# (optionally) ALL_CODES_50.txt
```

If your Hydra data configs use a different base path (e.g. `dataset/mimiciii_full`), either:

- change `DATA_DIRECTORY_MIMICIII_FULL` / `DATA_DIRECTORY_MIMICIII_50` in `src/settings.py` to match those paths, **or**
- update the paths in `configs/data/mimiciii_full.yaml` / `configs/data/mimiciii_50.yaml` so they point to the actual location of the generated files.

---

## 3. Running the `mimiciii_full` experiment locally

### 3.1. Quick sanity check

Make sure Hydra sees the configs:

```bash
ls configs/data/mimiciii_full.yaml
ls configs/experiment/mimiciii_full/plm_icd.yaml
```

Make sure the dataset files are where they should be (for example):

```bash
ls files/data/mimiciii_full
# should contain mimiciii_full.feather and mimiciii_full_splits.feather (and possibly ALL_CODES.txt)
```

If not, double-check:

- `src/settings.py` paths for `DOWNLOAD_DIRECTORY_MIMICIII` and `DATA_DIRECTORY_MIMICIII_FULL`,
- the paths configured in `configs/data/mimiciii_full.yaml`.

---

### 3.2. Before running experiments

1. **Weights & Biases (optional)**  
   Create a Weights & Biases account and log in if you want experiment tracking. It is also possible to run the experiments without W&B; in that case, disable or ignore the W&B integration in the configs.

2. **Download RoBERTa-base-PM-M3-Voc**  
   Download [RoBERTa-base-PM-M3-Voc](https://dl.fbaipublicfiles.com/biolm/RoBERTa-base-PM-M3-Voc-hf.tar.gz), unzip it, and change the `model_path` parameter in  
   **`configs/model/plm_icd.yaml`** and **`configs/text_transform/huggingface.yaml`** to point to the extracted model folder.

3. **Prepare MIMIC-III full / 50**  
   If you want to use **MIMIC-III full** and **MIMIC-III 50** from *Explainable Prediction of Medical Codes from Clinical Text*, run:

   ```bash
   python prepare_data/prepare_mimiciii_mullenbach.py
   ```

   and verify that the generated `.feather` and split files are in the directories defined by `DATA_DIRECTORY_MIMICIII_FULL` and `DATA_DIRECTORY_MIMICIII_50`, and that these paths match your data configs.

4. **Download model checkpoints (optional)**  
   Download the model checkpoints and unzip them if you want to evaluate existing models instead of training from scratch.  
   **Please note that these model weights can't be used commercially due to the MIMIC License.**

---

### 3.3. Training PLM-ICD from scratch on `mimiciii_full`

This will train a PLM-ICD model on the **MIMIC-III full** dataset:

```bash
python -u main.py \
  experiment=mimiciii_full/plm_icd \
  gpu=0 \
  trainer.epochs=5 \
  trainer.print_metrics=true
```

Main arguments:

- `experiment=mimiciii_full/plm_icd` – choose the right Hydra experiment for MIMIC-III full.
- `gpu=0` – use GPU 0 (set to `-1` to use CPU only, or another index).
- `trainer.epochs=5` – number of training epochs (tune as you wish, e.g. 20 for full training).
- `trainer.print_metrics=true` – print evaluation metrics after each validation phase.

The model checkpoint will be written under the path configured in the
experiment (typically inside `files/` or a Hydra `outputs/` directory,
depending on your settings).

---

### 3.4. Evaluating an existing checkpoint on `mimiciii_full`

If you already have a trained model, point `load_model` to its folder and set
`trainer.epochs=0` to run pure evaluation:

```bash
python -u main.py \
  experiment=mimiciii_full/plm_icd \
  gpu=0 \
  trainer.epochs=0 \
  load_model=files/is72ujzk \
  trainer.print_metrics=true
```

Replace `files/is72ujzk` with the actual path to your saved checkpoint
(for example `files/mimiciii_full/plm_icd/best.ckpt` or a similar directory).

---

## 4. What gets logged and where to find results

Depending on your configuration:

- **Checkpoints** – saved in the `load_model` / `output_dir` folder (see the
  experiment config).
- **Metrics** – printed to stdout (`trainer.print_metrics=true`) and often
  logged to:
  - Weights & Biases (if W&B is enabled),
  - local log files under `logs/` or `outputs/…` (Hydra default).

Look for metrics such as micro/macro F1, AUC, precision, recall, etc.

---

## 5. Running on an HPC cluster (SLURM example)

Below is a generic HPC setup assuming:

- a SLURM-based cluster,
- modules for Python and CUDA,
- you can allocate a GPU (e.g. A100/V100 etc.).

### 5.1. Prepare environment on HPC

Log in to the cluster and use your existing scripts:

- `med_train.sh` – for training on the actual **MIMIC-III full** dataset.
- `med_test.sh` – for evaluating a trained model on the test split.

A typical `med_train.sh` script will:

- load modules (Python, CUDA),
- activate the `plmicd-demo` (or similar) environment,
- `cd` into `PLM-ICD`,
- call something like:

  ```bash
  python -u main.py \
    experiment=mimiciii_full/plm_icd \
    gpu=0 \
    trainer.epochs=20 \
    trainer.print_metrics=true
  ```

### 5.2. Evaluating on HPC

To evaluate an existing checkpoint on the HPC cluster, adjust the last
line in the `med_test.sh` SLURM script to something like:

```bash
python -u main.py \
  experiment=mimiciii_full/plm_icd \
  gpu=0 \
  trainer.epochs=0 \
  load_model=files/is72ujzk \
  trainer.print_metrics=true
```

Again, adjust `load_model` to the actual checkpoint path (which might be on
a shared scratch or project directory, depending on your cluster rules).

---
