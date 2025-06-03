# workbench-mlflow-ambiente

Este repositório oferece um **ambiente de trabalho integrado** para desenvolvimento e experimentação com **MLflow**, **Jupyter** e **PostgreSQL**, tudo orquestrado via **Docker**. A ideia central é fornecer:

* Um **servidor MLflow** para registro e rastreamento de experimentos.
* Um ambiente **Jupyter Notebook/Lab** com imagens pré-configuradas (SciPy, TensorFlow, PySpark).
* Um banco de dados **PostgreSQL** para armazenar os metadados do MLflow.
* Imagens Docker independentes de **Python Dev** e **Sphinx** para testes e documentação.

O “workbench” foi construído com base em um “cookiecutter” existente, mas foi adaptado para as necessidades específicas do projeto, contemplando suporte a múltiplos kernels no Jupyter e integração transparente com o MLflow.

---

## Índice

- [workbench-mlflow-ambiente](#workbench-mlflow-ambiente)
  - [Índice](#índice)
  - [Pré-requisitos](#pré-requisitos)
  - [Visão Geral da Estrutura](#visão-geral-da-estrutura)
  - [Configuração do Ambiente](#configuração-do-ambiente)
    - [Variáveis de Ambiente – `.env`](#variáveis-de-ambiente--env)
    - [Criação de Diretórios Locais](#criação-de-diretórios-locais)
  - [Como Construir e Subir o Ambiente Docker](#como-construir-e-subir-o-ambiente-docker)
    - [1. Build das Imagens](#1-build-das-imagens)
    - [2. Inicializar o Docker Compose](#2-inicializar-o-docker-compose)
    - [3. Acessar o Jupyter](#3-acessar-o-jupyter)
    - [4. Acessar o MLflow](#4-acessar-o-mlflow)
    - [5. Parar e Remover Containers](#5-parar-e-remover-containers)
  - [Imagens Docker Independentes](#imagens-docker-independentes)
    - [Python Dev (Desenvolvimento)](#python-dev-desenvolvimento)
    - [Sphinx (Documentação)](#sphinx-documentação)
  - [Execução de Testes](#execução-de-testes)
  - [Estrutura de Diretórios](#estrutura-de-diretórios)
  - [Como Contribuir](#como-contribuir)
  - [Licença](#licença)
  - [Autor e Agradecimentos](#autor-e-agradecimentos)

---

## Pré-requisitos

Antes de executar qualquer comando, verifique se o seu ambiente local atende aos seguintes itens:

1. **Sistema operacional**

   * Linux (Ubuntu/Debian) ou macOS (testado em ambas); para Windows recomenda-se usar WSL2 ou Docker Desktop.

2. **Docker Engine + Docker Compose**

   * Docker Engine >= 20.10
   * Docker Compose v2 (se for Compose como plugin) ou v1.29 (se for binário).

3. **Make (GNU Make)**

   * Para executar comandos automatizados definidos no `Makefile`.

   ```bash
   $ make --version
   GNU Make 4.3
   ```

4. **Git**

   * Para clonar o repositório.

   ```bash
   $ git --version
   git version 2.x.x
   ```

5. **Python 3.10+** (opcional para rodar testes localmente sem Docker)

   * Caso queira executar os testes de forma nativa (pytest, tox), é recomendável ter Python 3.10 ou superior instalado.

   ```bash
   $ python3 --version
   Python 3.10.x
   ```

> **Observação**:
>
> * Se você estiver usando Windows, consulte a [documentação do Docker Desktop](https://docs.docker.com/desktop/windows/install/) para habilitar WSL2 e o backend Linux.
> * Este projeto foi testado em ambientes Unix-like (Linux/macOS).

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

## Configuração do Ambiente

### Variáveis de Ambiente – `.env`

Todas as variáveis estão centralizadas em um arquivo chamado `.env`. Ele já está incluído neste repositório como modelo, mas **recomenda-se revisar e ajustar** conforme o seu contexto local:

```dotenv
# Versão das imagens criadas
VERSION=0.2.0

# Diretórios locais que serão montados nos containers
JUPYTER_DATA_PROCESSED=data/processed
DATA_DIR=data/
IMAGE_OWNER=gradflow            # Docker Hub Namespace ou usuário
REPO_SLUG=workbench             # Nome do repositório/imagem base
WAIT_FOR_IT_TIMEOUT=60

# Configurações do Jupyter (vários targets possíveis: scipy, tensorflow, pyspark)
JUPYTER_USERNAME=jovyan
JUPYTER_SCIPY_IMAGE=scipy-notebook
JUPYTER_SCIPY_VERSION=python-3.10
JUPYTER_TENSORFLOW_IMAGE=tensorflow-notebook
JUPYTER_TENSORFLOW_VERSION=python-3.10
JUPYTER_PYSPARK_IMAGE=pyspark-notebook
JUPYTER_PYSPARK_VERSION=python-3.10
JUPYTER_ENABLE_LAB=yes
JUPYTER_PORT=8888
JUPYTER_TARGET=scipy           # Opções: scipy, tensorflow, pyspark (altera o FROM no Dockerfile)

# MLflow
MLFLOW_IMAGE_NAME=mlflow
MLFLOW_VERSION=2.9.1
MLFLOW_ARTIFACT_STORE=artifacts/    # Diretório montado para salvar modelos e artefatos
MLFLOW_TRACKING_SERVER_HOST=0.0.0.0
MLFLOW_TRACKING_SERVER_PORT=5000
MLFLOW_TRACKING_URI=http://mlflow:5000

# PostgreSQL (será usado pelo MLflow para armazenar metadados)
POSTGRES_IMAGE_NAME=postgres
POSTGRES_STORE=data/db              # Diretório local dos dados do PostgreSQL
POSTGRES_USER=admin
POSTGRES_PASSWORD=secret
POSTGRES_PORT=5432
POSTGRES_DATABASE=mlflow

# Imagens auxiliares
PYTHON_DEV_IMAGE_NAME=workbench/python-dev
SPHINX_IMAGE_NAME=workbench/sphinx
SPHINX_VERSION=3.0.3
```

> **Importante**:
>
> * Ajuste `IMAGE_OWNER` para o seu usuário no Docker Hub (ou deixei “gradflow” apenas como referência).
> * Reveja as portas caso tenha conflitos locais (ex.: 5000 para MLflow, 5432 para PostgreSQL, 8888 para Jupyter).
> * Altere `MLFLOW_VERSION` e demais versões conforme desejar.
>

### Criação de Diretórios Locais

Alguns diretórios precisam existir localmente para **mount** nos volumes dos containers. Para criá-los automaticamente:

```bash
$ make dirs
```

Isso irá gerar, na raiz do projeto:

```
data/
├── processed/      # usado pelo Jupyter para dados processados
├── db/             # usado pelo PostgreSQL para armazenar arquivos físicos
└── artifacts/      # usado pelo MLflow para salvar modelos / logs
```

Se preferir criar manualmente:

```bash
$ mkdir -p data/processed data/db artifacts
```

---

## Como Construir e Subir o Ambiente Docker

### 1. Build das Imagens

Para gerar todas as imagens Docker definidas em `docker/jupyter`, `docker/mlflow` e `docker/postgres`, basta executar:

```bash
$ make build
```

Isso fará:

1. Construir a imagem **Jupyter**, usando `docker/jupyter/Dockerfile`.
2. Construir a imagem **MLflow**, usando `docker/mlflow/Dockerfile`.
3. Construir a imagem **PostgreSQL**, usando `docker/postgres/Dockerfile`.

As tags geradas (nomeadas como `${IMAGE_OWNER}/${REPO_SLUG}/...:${VERSION}`) serão:

* `gradflow/workbench/jupyter-scipy:0.2.0` (ou equivalente, conforme a variável `JUPYTER_TARGET`).
* `gradflow/workbench/mlflow:0.2.0`.
* `gradflow/workbench/postgres:0.2.0`.

> **Dica**: se você modificar apenas o código Python em `src/workbench`, não é necessário rebuildar Jupyter ou MLflow, a menos que altere dependências no Dockerfile.

### 2. Inicializar o Docker Compose

Depois do build, rode o `docker-compose` para subir todos os serviços:

```bash
$ docker-compose up -d
```

Ou, se preferir ver os logs no terminal (modo não detached):

```bash
$ docker-compose up
```

Isso criará três containers:

* `workbench-mlflow-ambiente_jupyter_1`
* `workbench-mlflow-ambiente_mlflow_1`
* `workbench-mlflow-ambiente_postgres_1`

Você pode conferir:

```bash
$ docker ps
CONTAINER ID   IMAGE                                   COMMAND                  ...   PORTS
abcd1234       gradflow/workbench/jupyter-scipy:0.2.0  "tini -g -- start-no…"   ...   0.0.0.0:8888->8888/tcp
efgh5678       gradflow/workbench/mlflow:0.2.0         "mlflow server --boo…"   ...   0.0.0.0:5000->5000/tcp
ijkl9012       gradflow/workbench/postgres:0.2.0       "docker-entrypoint.s…"   ...   0.0.0.0:5432->5432/tcp
```

### 3. Acessar o Jupyter

Abra seu navegador e visite:

```
http://localhost:8888
```

* O token ou senha padrão é definido pelo Dockerfile base (`jovyan`).
* Caso queira trocar usuário/senha, consulte as variáveis `JUPYTER_USERNAME` no `.env` e modifique `Dockerfile` conforme instruções da imagem base do Jupyter.

Dentro do Jupyter, você encontrará um diretório montado para `./data`, contendo subpastas:

* `data/processed/` – para outputs de notebooks.
* `data/` – raiz para seus datasets.
* `artifacts/` – local de salvamento de modelos via MLflow.

Você pode abrir notebooks de exemplo no diretório `src/workbench` ou criar novos.

### 4. Acessar o MLflow

No seu navegador, acesse:

```
http://localhost:5000
```

Este é o **MLflow Tracking Server**.

* As informações de experimento são persistidas no PostgreSQL (connection string montada a partir de `POSTGRES_*` no `.env`).
* Os artefatos (modelos, métricas, gráficos) ficam em `./artifacts/`, amarrados pela variável `MLFLOW_ARTIFACT_STORE`.

### 5. Parar e Remover Containers

Quando terminar de trabalhar, você pode parar tudo de duas formas:

* **Somente parar, mas manter volumes e imagens**:

  ```bash
  $ docker-compose down
  ```
* **Remover containers, volumes e imagens criadas** (pra um “reset” completo):

  ```bash
  $ make destroy
  ```

  ou

  ```bash
  $ make down-all
  ```

> **Observação**:
>
> * `make reset` limpa tudo (“destroy”) e recria os diretórios necessários.
> * `make prune` remove containers e imagens etiquetadas com o label do projeto.

---

## Imagens Docker Independentes

Além do stack orquestrado pelo `docker-compose.yml`, existem duas imagens isoladas para usos específicos:

### Python Dev (Desenvolvimento)

Localizado em `docker/python-dev/Dockerfile` (se existir; caso contrário, usa-se o diretório de exemplo).
Esta imagem serve para:

* Instalar suas dependências Python que não estão embutidas na imagem Jupyter/MLflow.
* Roda linters (pylint), formatação e testes unitários (pytest).

Para criar essa imagem:

```bash
$ docker build \
    -f docker/python-dev/Dockerfile \
    -t ${IMAGE_OWNER}/${REPO_SLUG}/python-dev:${VERSION} \
    .
```

E para entrar no container:

```bash
$ docker run --rm -it \
    -v $(pwd)/src:/workbench/src \
    -v $(pwd)/tests:/workbench/tests \
    ${IMAGE_OWNER}/${REPO_SLUG}/python-dev:${VERSION} \
    bash
```

Dentro do container, você pode rodar:

```bash
# Roda linter
$ pylint src/workbench

# Roda pytest
$ pytest tests/python
```

### Sphinx (Documentação)

Localizado em `docker/sphinx/Dockerfile`.
Esta imagem gera documentos HTML a partir de arquivos `.rst` ou `.md`.

Para criar:

```bash
$ docker build \
    -f docker/sphinx/Dockerfile \
    -t ${IMAGE_OWNER}/${REPO_SLUG}/sphinx:${SPHINX_VERSION} \
    .
```

E para renderizar:

```bash
$ docker run --rm -it \
    -v $(pwd)/docs:/workbench/docs \
    ${IMAGE_OWNER}/${REPO_SLUG}/sphinx:${SPHINX_VERSION} \
    make html
```

Após isso, em `docs/_build/html/` estarão os arquivos estáticos prontos para publicação (GitHub Pages, kit de documentação, etc.).

---

## Execução de Testes

Este projeto inclui dois tipos principais de testes:

1. **Testes Python unitários** (`tests/python/`)

   * Verificam lógica interna, versões e utilidades do pacote Python.
   * Para rodar localmente (fora do container):

     ```bash
     $ python3 -m venv .venv
     $ source .venv/bin/activate
     $ pip install -r requirements-dev.txt   # se existir requirements-dev.txt ou equivalente
     $ pytest tests/python
     ```
   * Ou, dentro do container Python Dev:

     ```bash
     $ make test
     ```

     Esse comando executa `pytest tests/python`, conforme configurado no `Makefile`.

2. **Testes de Integração Docker** (`tests/docker/`)

   * Validam se a imagem MLflow subiu corretamente e expôs a porta de tracking.
   * Executam um script `tests/run_docker_tests.sh` que cria um container temporário, checa endpoints do MLflow, e remove tudo.
   * Para rodar (após ter feito o build das imagens):

     ```bash
     $ make test  # já engloba testes Python e Docker
     ```
   * Ou diretamente:

     ```bash
     $ bash tests/run_docker_tests.sh
     ```

Além disso, há suporte ao **tox**, que automatiza ambientes de teste e checagem de lint:

```bash
$ tox
```

Isso irá:

* Criar ambientes virtuais com Python 3.x (conforme configurado em `tox.ini`).
* Executar `pytest` e `pylint`.

---

## Estrutura de Diretórios

Uma visão em árvore do repositório com breves descrições:

```
.
├── .dockerignore              # Arquivos/dirs a ignorar no build Docker
├── .env                       # Variáveis de ambiente (ex: versões, senhas, portas)
├── .gitignore                 # Padrão de arquivos a ignorar no Git
├── .pylintrc                  # Configurações do pylint (quality)
├── .travis.yml                # Pipeline de CI no Travis CI
├── Makefile                   # Comandos automatizados (build, test, lint, etc.)
├── docker-compose.yml         # Serviços: jupyter, mlflow, postgres
├── docker/
│   ├── jupyter/               # → Dockerfile e scripts para imagem Jupyter
│   │   ├── Dockerfile
│   │   └── requirements.test.txt
│   ├── mlflow/                # → Dockerfile e scripts para imagem MLflow
│   │   ├── Dockerfile
│   │   └── scripts/
│   │       └── wait-for-it.sh  # script para aguardar o PostgreSQL iniciar
│   └── postgres/              # → Dockerfile para imagem PostgreSQL customizada
│       └── Dockerfile
├── src/
│   └── workbench/             # Pacote Python (vazio ou com módulos utilitários)
│       └── __init__.py        # Exemplo de validação de versão, etc.
├── tests/
│   ├── docker/                # Testes de integração Docker
│   │   ├── test_mlflow.py
│   │   └── __init__.py
│   ├── python/                # Testes unitários Python
│   │   ├── test_version.py
│   │   └── __init__.py
│   └── run_docker_tests.sh    # Script de teste para MLflow container
├── tox.ini                    # Configuração do tox (pytest + lint)
└── README.md                  # (este arquivo!)
```

---

## Como Contribuir

1. **Fork** deste repositório.
2. Crie uma **branch** para sua feature ou bugfix:

   ```bash
   $ git checkout -b feat/nova-funcionalidade
   ```
3. Faça os commits de suas alterações de forma atômica, escrevendo mensagens claras:

   ```bash
   $ git commit -m "feat: adiciona suporte a nova versão do MLflow"
   ```
4. Garanta que **todos os testes** passem localmente:

   ```bash
   $ make test
   ```

   ou

   ```bash
   $ pytest tests/python && bash tests/run_docker_tests.sh
   ```
5. Envie sua **Pull Request** para a branch `main` (ou `master`) deste repositório.
6. Aguarde revisão de código (code review).
7. Após aprovação, sua contribuição será mesclada (merge) e disponibilizada.

> **Dicas de estilo**
>
> * Siga as regras do **PEP8** para Python.
> * Utilize o **pylint** integrado (já configurado em `.pylintrc`).
> * Crie testes unitários para novas funcionalidades.
> * Mantenha a estrutura do projeto organizada.

---

## Licença

Este projeto está licenciado sob a **MIT License**.
Veja o arquivo [LICENSE](LICENSE) para detalhes completos.

---

## Autor e Agradecimentos

* **Autor:** Carlos Eduardo Correa
* **Base/Inspiração:**
  * [Natu Lauchande](https://github.com/PacktPublishing/Machine-Learning-Engineering-with-Mlflow.git.)
  * [cookiecutter-ds-docker](https://github.com/sertansenturk/cookiecutter-ds-docker)
  * Projetos-padrão de MLflow + Docker

Obrigado a todos que contribuíram com ideias, testes e relatórios de bugs!

---

> **Resumo Rápido (FAQs)**
>
> * **Como subir tudo de uma vez?**
>
>   ```bash
>   $ make dirs
>   $ make build
>   $ docker-compose up -d
>   ```
> * **Como visualizar a interface do MLflow?**
>   Acesse [http://localhost:5000](http://localhost:5000).
> * **Como executar testes?**
>
>   ```bash
>   $ make test
>   ```
> * **Como parar e limpar containers/volumes?**
>
>   ```bash
>   $ make destroy
>   ```

---