# Tempelate for a Python Poetry Project

This is a template for a Python Poetry project. It is configured to use cuda 12.2.2, python 3.10, and ubuntu 22.04. Coding with devcontainers is supported.

## Features

- Python 3.10
- Poetry 2.1.1
- CUDA 12.2.2
- Ubuntu 22.04
- Git, vim, wget, curl
- Timezone in Asia/Taipei

## Changes before using

Before using this template, you may want to change the project path in these files:
- [docker-compose.yml line 4](./docker-compose.yml#L4)
- [docker-compose.yml line 16](./docker-compose.yml#L16)
- [.devcontainer/docker-compose-dev.yml line 4](./.devcontainer/docker-compose-dev.yml#L4)
- [.devcontainer/docker-compose-dev.yml line 16](./.devcontainer/docker-compose-dev.yml#L16)

...and you may want to change the project name:
- [pyproject.toml line 2](./pyproject.toml#L2)

...and you may want to change the Python version:
- [.github/workflows/requirements.txt.yml line 28](./.github/workflows/requirements.txt.yml#L28)
- [Dockerfile line 41](./Dockerfile#L41)

...and you may want to change Poetry's version:
- [.github/workflows/requirements.txt.yml line 15](./.github/workflows/requirements.txt.yml#L15)
- [Dockerfile line 18](./Dockerfile#L18)

## Usage

### Using VSCode for development

1. Install [Dev Containers](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers) extension.
2. Open this project in VSCode.
3. Click the `Reopen in Container` button.

### Build and run for production

Just run:

```sh
docker compose up --build
```
