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

   and verify that the generated `.feather` and split files match what your data configs expect.

4. **Download model checkpoints (optional)**  
   Download the model checkpoints and unzip them if you want to evaluate existing models instead of training from scratch.  
   **Please note that these model weights can't be used commercially due to the MIMIC License.**

---

### 3.3. Training PLM-ICD from scratch on `mimiciii_full`

This will train a PLM-ICD model on the **MIMIC-III full** dataset:

```bash
python -u main.py experiment=mimiciii_full/plm_icd gpu=0 trainer.print_metrics=true
```

Main arguments:

- `experiment=mimiciii_full/plm_icd` – choose the right Hydra experiment for MIMIC-III full.
- `gpu=0` – use GPU 0 (set to `-1` to use CPU only, or another index).
- `trainer.print_metrics=true` – print evaluation metrics after each validation phase.

The model checkpoint will be written under the path configured in the
experiment (typically inside `files/` or a Hydra `outputs/` directory,
depending on your settings.

---

### 3.4. Evaluating an existing checkpoint on `mimiciii_full`

If you already have a trained model, point `load_model` to its folder and set
`trainer.epochs=0` to run pure evaluation:

```bash
python -u main.py experiment=mimiciii_full/plm_icd gpu=0 trainer.epochs=0 load_model=files/is72ujzk trainer.print_metrics=true
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
