# Use podman-compose by default if available.
ifeq (, $(shell which podman-compose))
    COMPOSE := docker-compose --project-name plm
    PODMAN := docker
else
    COMPOSE := podman-compose --project-name plm
    PODMAN := podman
endif

BROWSER := xdg-open
SERVICE := dev
TEST_REQUIREMENTS := dev-requirements.txt

PYTHON := python3
PIP := $(PYTHON) -m pip
PYTEST := $(PYTHON) -m pytest --color=yes
FLAKE8 := $(PYTHON) -m flake8
PYLINT := $(PYTHON) -m pylint

.PHONY: all help up down build recreate exec sudo test test_requirements pytest flake8 pylint coverage

all: help

help:
	@echo 'Usage:'
	@echo
	@echo '  make up - starts containers in docker-compose environment'
	@echo
	@echo '  make down - stops containers in docker-compose environment'
	@echo
	@echo '  make build - builds container images for docker-compose environment'
	@echo
	@echo '  make recreate - recreates containers for docker-compose environment'
	@echo
	@echo '  make exec [CMD=".."] - executes command in dev container'
	@echo
	@echo '  make sudo [CMD=".."] - executes command in dev container under root user'
	@echo
	@echo '  make pytest [ARGS=".."] - executes pytest with given arguments in dev container'
	@echo
	@echo '  make flake8 - executes flake8 in dev container'
	@echo
	@echo '  make pylint - executes pylint in dev container'
	@echo
	@echo '  make test - alias for "make pytest flake8 pylint"'
	@echo
	@echo '  make coverage [ARGS=".."] - generates and shows test code coverage'
	@echo
	@echo 'Variables:'
	@echo
	@echo '  COMPOSE=docker-compose|podman-compose'
	@echo '    - docker-compose or podman-compose command'
	@echo '      (default is "podman-compose" if available)'
	@echo
	@echo '  PODMAN=docker|podman'
	@echo '    - docker or podman command'
	@echo '      (default is "podman" if "podman-compose" is available)'
	@echo
	@echo '  SERVICE={dev|composedb}'
	@echo '    - service for which to run `make exec` and similar (default is "dev")'
	@echo '      Example: make exec SERVICE=dev CMD=flake8'

up:
	$(COMPOSE) up -d

down:
	$(COMPOSE) down

build:
	$(COMPOSE) build

recreate:
	$(COMPOSE) up -d --force-recreate

exec:
	$(PODMAN) exec plm_$(SERVICE)_1 bash -c '$(CMD)'

sudo:
	$(PODMAN) exec -u root plm_$(SERVICE)_1 bash -c '$(CMD)'

test: test_requirements pytest flake8 pylint

test_requirements:
	$(MAKE) exec CMD="$(PIP) install --user -r $(TEST_REQUIREMENTS)"

pytest:
	$(MAKE) exec \
	    CMD="COVERAGE_FILE=/home/dev/.coverage-$(SERVICE) $(PYTEST) $(ARGS)"

flake8:
	$(FLAKE8)

pylint:
	$(PYLINT) product_listings_manager/

coverage:
	$(MAKE) pytest ARGS="--cov-config .coveragerc --cov=product_listings_manager --cov-report html:/home/dev/htmlcov-$(SERVICE) $(ARGS)"
	$(BROWSER) docker/home/htmlcov-$(SERVICE)/index.html
