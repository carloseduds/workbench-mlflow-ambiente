############## custom jupyter image ###############
ARG JUPYTER_BASE_IMAGE
ARG JUPYTER_BASE_VERSION
FROM jupyter/${JUPYTER_BASE_IMAGE}:${JUPYTER_BASE_VERSION} AS jupyter

ARG MLFLOW_ARTIFACT_STORE
ARG MLFLOW_VERSION
ARG JUPYTER_USERNAME
ENV HOME_DIR=/home/$JUPYTER_USERNAME
ENV WORK_DIR=$HOME_DIR/work

USER root

# Atualiza pip
RUN pip install --upgrade pip

# Copia e instala dependências do projeto
WORKDIR $WORK_DIR
COPY ./requirements.txt ./setup.py ./
COPY ./src/ ./src/
RUN chown -R $NB_UID:$NB_GID $HOME_DIR && \
    pip install -r requirements.txt && \
    pip install -e . && \
    fix-permissions $HOME_DIR

# Instala dependências adicionais
RUN pip install \
    mlflow==${MLFLOW_VERSION} \
    psycopg2-binary \
    boto3 \
    "protobuf<4.0.0" \
    "jupyterlab>=4.0.0" \
    "numpy<1.24" \
    "notebook>=7.0.0" \
    "jupyter_server>=2.0.0" \
    jupyter_contrib_nbextensions \
    jupyter_nbextensions_configurator \
    tqdm && \
    pip install \
    torch==2.6.0 \
    torchvision==0.21.0 \
    torchaudio==2.6.0 \
    pytorch-lightning \
    'lightning-flash[text]' \
    --extra-index-url https://download.pytorch.org/whl/cu126 && \
    fix-permissions $CONDA_DIR

# Prepara diretório do MLflow com permissões adequadas
RUN ldconfig && \
    if [[ "$MLFLOW_ARTIFACT_STORE" != s3* ]]; then \
      mkdir -p $MLFLOW_ARTIFACT_STORE && \
      chown -R ${NB_UID}:${NB_GID} $MLFLOW_ARTIFACT_STORE && \
      fix-permissions $MLFLOW_ARTIFACT_STORE; \
    fi

# Troca para usuário Jupyter
USER $NB_UID

################## test image ###################
FROM jupyter AS test

ARG TEST_DIR=/tests

COPY ./docker/jupyter/requirements.test.txt ${TEST_DIR}/
RUN pip install -r ${TEST_DIR}/requirements.test.txt

COPY ./tests/docker ${TEST_DIR}/docker
COPY ./tests/run_docker_tests.sh ${TEST_DIR}/
COPY ./docker/jupyter/scripts/wait-for-it.sh ${TEST_DIR}/

USER root
RUN chmod +x ${TEST_DIR}/wait-for-it.sh
USER $NB_UID

WORKDIR ${TEST_DIR}
