import os
import logging
import json
import numpy
import h2o
import pandas as pd


def init():
    """
    This function is called when the container is initialized/started, typically after create/update of the deployment.
    You can write the logic here to perform init operations like caching the model in memory
    """
    global model, q
    # AZUREML_MODEL_DIR is an environment variable created during deployment.
    # It is the path to the model folder (./azureml-models/$MODEL_NAME/$VERSION)
    # Please provide your model's folder name if there is one
    model_path = os.path.join(os.getenv("AZUREML_MODEL_DIR"), "MOJO_model10032025.zip")

    # This value of q (170.4836) is the (1 - alpha) empirical quantile of the absolute residuals
    # between the predicted and actual values from an H2O model prediction of a validation dataset.
    # It was computed in the calculate-prediction-error.ipynb notebook using a 90% prediction interval
    # (alpha = 0.1), based on the closest observation method via numpy's quantile function.
    q = 170.4836

    h2o.init()

    model = h2o.import_mojo(model_path) 
    logging.info("Init complete")   



def run(raw_data):
    """
    This function is called for every invocation of the endpoint to perform the actual scoring/prediction.
    """

    # Parsing dell'input
    data = json.loads(raw_data)
    data = data["data"]

    # Conversione in DataFrame pandas
    input_data = pd.DataFrame(data)

    # Conversione in H2OFrame
    input_frame = h2o.H2OFrame(input_data)
    logging.info("Making predictions...")

    # Effettua la prediction, escludendo la colonna target
    prediction = model.predict(input_frame)
    prediction_df = prediction.as_data_frame()

    # Estrae la predizione puntuale (si assume che sia nella prima colonna)
    prediction_list = prediction_df.iloc[:, 0].tolist()

    # Costruisce il JSON di output con intervallo di predizione
    results = {"predictions": []}
    for p in prediction_list:
        results["predictions"].append({
            "bct_pred": p,
            "bct_lower_90": p - q,
            "bct_upper_90": p + q
        })

    logging.info("Request processed")
    return results