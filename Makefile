SHELL := /bin/bash
.DEFAULT_GOAL := help

HELP_PADDING = 28
bold := $(shell tput bold)
sgr0 := $(shell tput sgr0)
padded_str := %-$(HELP_PADDING)s
pretty_command := $(bold)$(padded_str)$(sgr0)

include .env

export

MAKEFILE_DIR = $(dir $(realpath $(firstword $(MAKEFILE_LIST))))
BUILDKIT = 1
BUILD_OPTS =
RUN_OPTS =
UP_OPTS =
DOWN_OPTS = --remove-orphans
DOWN_ALL_OPTS = ${DOWN_OPTS} --rmi all -v

HOST_USERNAME := $(shell id -u -n)
JUPYTER_UID := $(shell id -u)
JUPYTER_USERNAME := $(shell id -u -n)
POSTGRES_UID := $(shell id -u)
POSTGRES_GID := $(shell id -g)

JUPYTER_BASE_IMAGE := ${JUPYTER_SCIPY_IMAGE}
JUPYTER_BASE_VERSION := ${JUPYTER_SCIPY_VERSION}
JUPYTER_CHOWN_EXTRA := "/data"

## ======= AÇÕES PRINCIPAIS =======

run: dirs
	docker-compose up --build -d

build: dirs ## Constrói imagem Docker
	DOCKER_BUILDKIT=$(BUILDKIT) COMPOSE_DOCKER_CLI_BUILD=$(BUILDKIT) \
	docker-compose build $(BUILD_OPTS)

reset:  ## Remove tudo e reinicia o ambiente do zero
	down-all destroy run

destroy: clean ## Remove diretórios e containers
	rm -rf notebooks logs data

test: ## Executa os testes
	docker-compose run --rm jupyter pytest

lint: ## Roda o linter
	docker-compose run --rm jupyter pylint mlops-pytemplate

tox: ## Roda o tox
	docker-compose run --rm jupyter tox

## ======= SETUPS E CRIAÇÃO DE PASTAS =======

dirs: ## Cria diretórios necessários
	mkdir -p notebooks
	mkdir -p logs
	mkdir -p data
	mkdir -p data/processed

## ======= GESTÃO DO DOCKER =======

clean: ## Remove containers e volumes relacionados ao projeto
	docker-compose down $(DOWN_OPTS)

down-all: ## Remove tudo relacionado ao projeto (containers, volumes, imagens)
	docker-compose down $(DOWN_ALL_OPTS)

prune: ## Remove imagens e containers com label do projeto
	docker container prune -f --filter "label=mlops-pytemplate"
	docker image prune -f --filter "label=mlops-pytemplate"

## ======= BASES DE CONTAINER =======

scipy: JUPYTER_BASE_IMAGE=${JUPYTER_SCIPY_IMAGE}
scipy: JUPYTER_BASE_VERSION=${JUPYTER_SCIPY_VERSION}
scipy: build run

tensorflow: JUPYTER_BASE_IMAGE=${JUPYTER_TENSORFLOW_IMAGE}
tensorflow: JUPYTER_BASE_VERSION=${JUPYTER_TENSORFLOW_VERSION}
tensorflow: build run

pyspark: JUPYTER_BASE_IMAGE=${JUPYTER_PYSPARK_IMAGE}
pyspark: JUPYTER_BASE_VERSION=${JUPYTER_PYSPARK_VERSION}
pyspark: build run

## ======= UTILITÁRIOS E OUTROS =======

test-store-permissions:
	@if [ $$(find data ! -user ${HOST_USERNAME} | wc -l) -gt 0 ]; then \
		echo "Found files and/or folders with wrong permission:" ; \
		find data ! -user ${HOST_USERNAME} -printf '%p (%u)\n' ; \
		exit 1 ; \
	else \
		exit 0 ; \
	fi

clean-python: ## Limpa arquivos temporários Python
	find . -name '*.pyc' -exec rm -f {} +
	find . -name '*.pyo' -exec rm -f {} +
	find . -name '*~' -exec rm -f {} +
	find . -name '__pycache__' -exec rm -fr {} +
	find . -name '.ipynb_checkpoints' -exec rm -fr {} +
	rm -rf build/ dist/ .eggs/ .pytest_cache .tox/ htmlcov/
	find . -name '*.egg-info' -exec rm -rf {} +
	rm -f .coverage

fix-line-endings: ## Converte arquivos .sh para o formato Unix (evita erro de '\r')
	find . -type f -name "*.sh" -exec dos2unix {} \;

## ======= AJUDA =======

help: ## Lista todos os comandos disponíveis
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' Makefile | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-15s\033[0m %s\n", $$1, $$2}'
