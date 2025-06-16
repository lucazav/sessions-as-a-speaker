import os
import logging
import h2o
import pandas as pd
from typing import List, Union

def init():
    global model, q, output_path
    mojo_path = os.path.join(os.getenv("AZUREML_MODEL_DIR"), "MOJO_model10032025.zip")
    q = 170.4836
    h2o.init()
    model = h2o.import_mojo(mojo_path)
    # the batch job’s output folder
    output_path = os.environ["AZUREML_BI_OUTPUT_PATH"]
    logging.info("Init complete.")

def run(raw_data: Union[str, List[str]]) -> List[str]:
    """
    raw_data: either a single local path or a list of paths.
    Detects .csv vs .xls/.xlsx and reads appropriately.
    Logs a warning and skips any other extensions.
    Returns the list of CSV filenames written under `output_path`.
    """
    # Normalize to a list
    mini_batch = raw_data if isinstance(raw_data, list) else [raw_data]
    written_files: List[str] = []

    for inp in mini_batch:
        _, ext = os.path.splitext(inp.lower())

        # Read input with the right pandas function, or skip unsupported
        if ext == ".csv":
            df = pd.read_csv(inp)
        elif ext in (".xls", ".xlsx"):
            df = pd.read_excel(inp, engine="openpyxl")
        else:
            logging.warning(f"Skipping unsupported file extension '{ext}' for input '{inp}'.")
            continue

        # Score with H2O MOJO
        hf = h2o.H2OFrame(df)
        preds = model.predict(hf).as_data_frame()

        # Append prediction columns
        df["bct_pred"]     = preds.iloc[:, 0]
        df["bct_lower_90"] = df["bct_pred"] - q
        df["bct_upper_90"] = df["bct_pred"] + q

        # Write out CSV with headers to the batch output folder
        base = os.path.splitext(os.path.basename(inp))[0]
        out_name = f"{base}_scored.csv"
        out_path = os.path.join(output_path, out_name)
        df.to_csv(out_path, index=False)
        written_files.append(out_name)

    return written_files
