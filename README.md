# PLM-ICD on `mimiciii_demo` (MIMIC-III Demo, Synthetic Notes)

This repository is a fork/customisation of **medical-coding-reproducibility** that
adds a **toy ICD coding experiment** based on the **MIMIC-III Demo** dataset.

Because MIMIC-III Demo does **not** contain free-text clinical notes, we build a
synthetic dataset called **`mimiciii_demo`**:

- input text is generated from ICD long titles,
- labels are true ICD-9 codes from the demo tables,
- we then train / evaluate **PLM-ICD** on this toy dataset.

> ⚠️ **Important:** This is for debugging, teaching and pipeline testing only.  
> The dataset is synthetic and **not suitable for real clinical conclusions or training.**
> The .feather files are already included, so you do not need MIMIC-III full
to run this experiment.

## 1. How the `mimiciii_demo` dataset is constructed

High-level idea:

1. Read MIMIC-III Demo tables:
   - `DIAGNOSES_ICD.csv`
   - `D_ICD_DIAGNOSES.csv`
2. Group ICD-9 codes per `HADM_ID`.
3. For each `HADM_ID`, create a synthetic “note”:
   - concatenate `LONG_TITLE` of each ICD-9 code into a short paragraph  
     (e.g. `"Diagnoses: CONGESTIVE HEART FAILURE. TYPE II DIABETES..."`).
4. Use the ICD-9 codes as multi-label targets:
   - labels are stored as a list of codes (and also as a string `"4019;25000;..."` in CSV).
5. Randomly split admissions into train/validation/test, e.g. 60/20/20.
6. Save:
   - `train_demo.csv`, `dev_demo.csv`, `test_demo.csv`
   - merged and preprocessed dataset in `mimiciii_demo.feather`
   - split information in `mimiciii_demo_splits.feather`.

These last two Feather files are what the training code actually loads.

## 2. Installation (local machine)

### 2.1. Clone the repo
[git clone <YOUR_FORK_URL> PLM-ICD](https://github.com/bTehe/PLM-ICD.git)
```bash
cd PLM-ICD
```

### 2.2. Create environment

Using conda (recommended):

```bash
conda create -n plmicd-demo python=3.10 -y
conda activate plmicd-demo
pip install -r requirements.txt
```

If you use plain `venv`, the steps are analogous.

---

## 3. Running the `mimiciii_demo` experiment locally

### 3.1. Quick sanity check

Make sure Hydra sees the configs:

```bash
ls configs/data/mimiciii_demo.yaml
ls configs/experiment/mimiciii_demo/plm_icd.yaml
```

Make sure the dataset files are where they should be:

```bash
ls files/data/mimiciii_demo
# should contain mimiciii_demo.feather and mimiciii_demo_splits.feather
```
### Before running experiments
1. Create a weights and biases account. It is possible to run the experiments without wandb.
2. You need to download [RoBERTa-base-PM-M3-Voc](https://dl.fbaipublicfiles.com/biolm/RoBERTa-base-PM-M3-Voc-hf.tar.gz), unzip it and change the model_path parameter in **`configs/model/plm_icd.yaml`** and **`configs/text_transform /huggingface.yaml`** to the path of the download.

### 3.2. Training PLM-ICD from scratch on `mimiciii_demo`

This will train a PLM-ICD model on the synthetic dataset:

```bash
python -u main.py experiment=mimiciii_demo/plm_icd gpu=0 trainer.epochs=5 trainer.print_metrics=true
```

Main arguments:

- `experiment=mimiciii_demo/plm_icd` – choose the right Hydra experiment.
- `gpu=0` – use GPU 0 (set to `-1` to use CPU only, or another index).
- `trainer.epochs=5` – number of training epochs (tune as you wish).
- `trainer.print_metrics=true` – print evaluation metrics after training.

The model checkpoint will be written under the path configured in the
experiment (typically inside `files/` or a Hydra `outputs/` directory,
depending on your settings).

### 3.3. Evaluating an existing checkpoint on `mimiciii_demo`

If you already have a trained model, point `load_model` to its folder and set
`trainer.epochs=0` to run pure evaluation:

```bash
python -u main.py \
  experiment=mimiciii_demo/plm_icd \
  gpu=0 \
  trainer.epochs=0 \
  load_model=files/is72ujzk \
  trainer.print_metrics=true
```

Replace `files/is72ujzk` with the actual path to your saved checkpoint.

---

## 4. What gets logged and where to find results

Depending on your configuration:

- **Checkpoints** – saved in `load_model` / `output_dir` folder (see the
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

Log in to the cluster and run *med_train.sh* for training an actual MIMICIII-full dataset.

### 5.2. Evaluating on HPC

To evaluate an existing checkpoint on the HPC cluster, just change the last
line in the *med_test.sh* SLURM script:

```bash
python -u main.py \
  experiment=mimiciii_demo/plm_icd \
  gpu=0 \
  trainer.epochs=0 \
  load_model=files/is72ujzk \
  trainer.print_metrics=true
```

Again, adjust `load_model` to the actual checkpoint path (which might be on
a shared scratch or project directory, depending on your cluster rules).

---
