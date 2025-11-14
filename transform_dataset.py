import pandas as pd
from pathlib import Path

ROOT = Path(__file__).resolve().parent
DATA_DIR = ROOT / "dataset"
DATA_DIR.mkdir(parents=True, exist_ok=True)

def load_split(split_name):
    df = pd.read_csv(DATA_DIR / f"{split_name}_demo.csv")
    df["split"] = split_name.replace("dev", "val")  # train/dev/test -> train/val/test
    return df

train = load_split("train")
dev   = load_split("dev")
test  = load_split("test")

full = pd.concat([train, dev, test], ignore_index=True)

# припускаємо, що у CSV є колонки: HADM_ID, text, label
full["_id"] = full["HADM_ID"].astype(int)
full["subject_id"] = full["_id"]

# рядок "4019;25000" -> список ["4019", "25000"]
def split_codes(s):
    if pd.isna(s):
        return []
    return [c.strip() for c in str(s).split(";") if c.strip()]

full["codes"] = full["label"].apply(split_codes)

# у цьому репо очікуються такі колонки
full["icd9_diag"] = full["codes"]
full["icd9_proc"] = [[] for _ in range(len(full))]
full["target"]    = full["codes"]

full["num_targets"] = full["target"].apply(len)
full["num_words"]   = full["text"].fillna("").str.split().apply(len)

cols = ["subject_id", "_id", "text",
        "icd9_diag", "icd9_proc", "target",
        "num_words", "num_targets", "split"]

full[cols].to_feather(DATA_DIR / "mimiciii_demo.feather")

# окремий файл зі сплітами (_id + split), як у mimiciii_full_splits.feather
splits = full[["_id", "split"]].copy()
splits.to_feather(DATA_DIR / "mimiciii_demo_splits.feather")

print("Saved:")
print(DATA_DIR / "mimiciii_demo.feather")
print(DATA_DIR / "mimiciii_demo_splits.feather")