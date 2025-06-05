# Workbench Mlflow

Este repositório oferece um **ambiente de trabalho integrado** para desenvolvimento e experimentação com **MLflow**, **Jupyter**, **PostgreSQL** e **MinIO**, tudo orquestrado via **Docker Compose**. A ideia central é fornecer:

* Um **servidor MLflow** com suporte a artefatos em bucket S3 (via MinIO).
* Um ambiente **Jupyter Notebook/Lab** com imagens pré-configuradas (SciPy, TensorFlow, PySpark).
* Um banco de dados **PostgreSQL** para metadados do MLflow.
* Armazenamento de artefatos com **MinIO** acessado via boto3.

---

## Requisitos

* Docker Engine >= 20.10
* Docker Compose v2
* GNU Make

---

## Uso rápido

```bash
make dirs          # cria diretórios: data/, logs/, notebooks/
make build         # builda as imagens
make run           # sobe o ambiente
```

Acesse:

* Jupyter: [http://localhost:8888](http://localhost:8888)
* MLflow UI: [http://localhost:5000](http://localhost:5000)
* MinIO Console: [http://localhost:9001](http://localhost:9001)

---

## Visão Geral da Estrutura

O repositório segue um layout padrão de projetos Python + Docker:

```
workbench-mlflow-ambiente/
├── .dockerignore
├── .env                 # Definição das variáveis de ambiente
├── .gitignore
├── .pylintrc
├── .travis.yml          # Configuração CI (Travis CI)
├── Makefile             # Comandos automatizados (build, test, lint etc.)
├── docker-compose.yml   # Orquestração dos serviços: jupyter, mlflow, postgres
├── docker/              
│   ├── jupyter/         # Dockerfile e scripts para imagem Jupyter
│   │   ├── Dockerfile
│   │   └── requirements.test.txt
│   ├── mlflow/          # Dockerfile e scripts para imagem MLflow
│   │   ├── Dockerfile
│   │   └── scripts/
│   └── postgres/        # Dockerfile para PostgreSQL customizado (opcional)
│       └── Dockerfile
├── src/                 
│   └── workbench/       # Código Python (pacote “workbench”)
│       └── __init__.py
├── tests/               
│   ├── docker/          # Testes que verificam containers Docker
│   │   └── test_mlflow.py
│   └── python/          # Testes Python unitários
│       └── test_version.py
├── tox.ini              # Configuração de ambientes de teste/linters
└── README.md            # (este arquivo)
```

* **`.env`**: concentra todas as variáveis de configuração (versão das imagens, credenciais mínimas do PostgreSQL, portas etc.).

* **`Makefile`**: reúne tarefas padronizadas (build, test, lint, remove containers, etc.).

* **`docker-compose.yml`**: define três serviços principais:

  1. **jupyter** – ambiente de notebooks (SciPy, TensorFlow, PySpark)
  2. **mlflow** – servidor de rastreamento (tracking server) para experimentos
  3. **postgres** – banco de dados para armazenar metadados do MLflow

* **`docker/jupyter/`**: todos os arquivos necessários para construir a imagem do Jupyter (base `jovyan/scipy-notebook`, `tensorflow-notebook` ou `pyspark-notebook`).

* **`docker/mlflow/`**: recursos para gerar uma imagem MLflow customizada (versionada).

* **`docker/postgres/`**: (opcional) Dockerfile para criar a imagem do PostgreSQL com ajustes no `entrypoint`, se necessário.

* **`src/workbench/`**: eventualmente conterá módulos Python que você queira desenvolver e versionar.

* **`tests/`**:

  * `tests/docker/` valida se o MLflow sobe corretamente no container (integração básica).
  * `tests/python/` abrange testes unitários de funções ou versão do pacote.

---

## Variáveis principais do `.env`

```dotenv
MLFLOW_ARTIFACT_STORE=s3://mlflow
MLFLOW_S3_ENDPOINT_URL=http://minio:9000
AWS_ACCESS_KEY_ID=minio
AWS_SECRET_ACCESS_KEY=minio123
```

Essas variáveis são usadas para fazer o MLflow gravar artefatos no bucket `mlflow` do MinIO.

O container do `jupyter` também recebe essas variáveis para que códigos Python com `mlflow.log_artifact()` funcionem direto do notebook.

---

> **Importante**:
>
> * Ajuste `IMAGE_OWNER` para o seu usuário no Docker Hub (ou deixei “gradflow” apenas como referência).
> * Reveja as portas caso tenha conflitos locais (ex.: 5000 para MLflow, 5432 para PostgreSQL, 8888 para Jupyter).
> * Altere `MLFLOW_VERSION` e demais versões conforme desejar.
>

---

## Redes Docker

O ambiente utiliza três redes:

* `frontend`: conecta Jupyter, MLflow e NGINX
* `backend`: conecta PostgreSQL e MLflow
* `storage`: conecta MLflow, MinIO e Jupyter

Crie manualmente se quiser:

```bash
docker network create frontend
docker network create backend
docker network create storage
```

Ou automaticamente via:

```bash
make create-networks
```

---

## Principais comandos do Makefile

```bash
make run            # builda e sobe o ambiente
make build          # builda todas as imagens
make destroy        # remove containers, volumes e data/
make down-all       # igual ao destroy mas remove imagens
make test           # executa os testes (pytest)
make lint           # roda linter
make tox            # executa tox
make dirs           # cria diretórios locais esperados
make prune          # limpa containers/imagens com label
```

---

## Observação sobre erro "Loading artifact failed" no MLflow UI

Esse erro aparece se a interface web do MLflow não consegue acessar diretamente o bucket do MinIO.

### Alternativas:

1. **Política de bucket público (uso local/teste)**

```bash
docker exec -it minio /bin/sh
mc alias set local http://localhost:9000 minio minio123
mc policy set download local/mlflow
```

2. **Configurar nginx como proxy de downloads**

No `sites-enabled/minio.conf`, inclua:

```nginx
location /artifacts/ {
    proxy_pass http://minio:9000/mlflow/;
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
}
```

Reinicie:

```bash
docker-compose restart nginx
```

---

## Persistência

Volumes locais estão definidos no `docker-compose.yml`:

```yaml
volumes:
  ./data/minio_data:/data
  ./data/db:/var/lib/postgresql/data
  ./data/:/home/jovyan/work/data
```

Os dados persistem fora dos containers, o que facilita a inspeção e backup.

---

## Testes e Lint

```bash
make test     # pytest nos notebooks
make lint     # pylint no pacote
make tox      # roda tox
```

---

## Finalização

Para parar o ambiente:

```bash
make destroy     # remove containers e volumes
make down-all    # remove tudo incluindo imagens
```

---

## Autor

* **Autor:** Carlos Eduardo Correa
* **Base/Inspiração:**
  * [Yong Liu](https://github.com/PacktPublishing/Practical-Deep-Learning-at-Scale-with-MLFlow.git)
  * [Natu Lauchande](https://github.com/PacktPublishing/Machine-Learning-Engineering-with-Mlflow.git)
  * [cookiecutter-ds-docker](https://github.com/sertansenturk/cookiecutter-ds-docker)
  * Projetos-padrão de MLflow + Docker

---

> Projeto mantido para fins de estudo e demonstração de ambientes MLOps containerizados com MLflow.
