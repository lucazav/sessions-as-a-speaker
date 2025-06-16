FROM mcr.microsoft.com/azureml/inference-base-2204:20250414.v1

WORKDIR /
ENV AZUREML_CONDA_ENVIRONMENT_PATH=/azureml-envs/minimal
ENV AZUREML_CONDA_DEFAULT_ENVIRONMENT=$AZUREML_CONDA_ENVIRONMENT_PATH

ENV PATH $AZUREML_CONDA_ENVIRONMENT_PATH/bin:$PATH
ENV LD_LIBRARY_PATH $AZUREML_CONDA_ENVIRONMENT_PATH/lib:$LD_LIBRARY_PATH

USER root

# (Optional) patch out conflicting lines in gunicorn run script
RUN sed -i '66,148d' /var/runit/gunicorn/run

# Install Java + utilities
# Create the manpage dir so openjdk’s post‑install can write there,
# and suppress any interactive prompts
ENV DEBIAN_FRONTEND=noninteractive
RUN mkdir -p /usr/share/man/man1 \
 && apt-get update \
 && apt-get install -y --no-install-recommends \
      unzip \
      wget \
      openjdk-11-jre-headless \
 && rm -rf /var/lib/apt/lists/*

# Fetch and unzip H2O
RUN wget -q https://h2o-release.s3.amazonaws.com/h2o/rel-3.44.0/3/h2o-3.44.0.3.zip && \
    unzip h2o-3.44.0.3.zip && \
    rm h2o-3.44.0.3.zip

# Build the conda environment
COPY conda_dependencies.yaml .
RUN conda env create -p $AZUREML_CONDA_ENVIRONMENT_PATH \
        -f conda_dependencies.yaml -q && \
    rm conda_dependencies.yaml && \
    conda run -p $AZUREML_CONDA_ENVIRONMENT_PATH pip cache purge && \
    conda clean -a -y

# Add H2O as a runit service (with logging)
RUN mkdir -p /var/runit/h2o/log && \
    printf '%s\n' '#!/bin/bash' \
      'exec java -jar /h2o-3.44.0.3/h2o.jar' \
      > /var/runit/h2o/run && \
    chmod +x /var/runit/h2o/run && \
    printf '%s\n' '#!/bin/bash' \
      'exec svlogd -tt /var/log/h2o' \
      > /var/runit/h2o/log/run && \
    chmod +x /var/runit/h2o/log/run

USER dockeruser

EXPOSE 54321

# Start all services: gunicorn + your H2O service + AzureML hooks
CMD ["runsvdir", "/var/runit"]
