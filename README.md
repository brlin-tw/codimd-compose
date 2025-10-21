# Compose container deployment of CodiMD

Launch a [CodiMD](https://github.com/hackmdio/codimd) service instance that satisfies your requirements in seconds!

<https://gitlab.com/brlin/codimd-compose>  
[![The GitLab CI pipeline status badge of the project's `main` branch](https://gitlab.com/brlin/codimd-compose/badges/main/pipeline.svg?ignore_skipped=true "Click here to check out the comprehensive status of the GitLab CI pipelines")](https://gitlab.com/brlin/codimd-compose/-/pipelines) [![GitHub Actions workflow status badge](https://github.com/brlin-tw/codimd-compose/actions/workflows/check-potential-problems.yml/badge.svg "GitHub Actions workflow status")](https://github.com/brlin-tw/codimd-compose/actions/workflows/check-potential-problems.yml) [![pre-commit enabled badge](https://img.shields.io/badge/pre--commit-enabled-brightgreen?logo=pre-commit&logoColor=white "This project uses pre-commit to check potential problems")](https://pre-commit.com/) [![REUSE Specification compliance badge](https://api.reuse.software/badge/gitlab.com/brlin/codimd-compose "This project complies to the REUSE specification to decrease software licensing costs")](https://api.reuse.software/info/gitlab.com/brlin/codimd-compose)

\#codimd \#container \#deployment

## Prerequisites

The following prerequisites must be met in order to make use of this product:

* The service host:
    + Must have Docker installed.
    + Must have access to the Docker Hub container registry service.
    + Must have Internet connectivity during the deployment of the service.
* You must have:
    + Access to the service host's text terminal.
    + Permission to run Docker commands on the service host.

## Usage

Follow the instructions below to deploy this product:

1. Download a copy of the product release archive from [the Releases page](https://gitlab.com/brlin/codimd-compose).
1. Extract the product release archive using your preferred archive manipulation application/utility.
1. In a text terminal, change the working directory to the extracted release archive by running the following command(with the version string placeholder replaced to the correct values):

    ```bash
    cd /path/to/codimd-compose-X.Y.Z
    ```

1. Run the following command to create and start the CodiMD service containers:

    ```bash
    docker compose up -d
    ```

## Reference

* [Docker Deployment - HackMD](https://hackmd.io/s/codimd-docker-deployment)  
  The upstream project's relevant documentation.
* [CodiMD Configuration - HackMD](https://hackmd.io/s/codimd-configuration)  
  The configuration documentation of the CodiMD software.
* [environment variables - Docker-compose env file not working - Stack Overflow](https://stackoverflow.com/questions/48495663/docker-compose-env-file-not-working)  
  Explains why the .env file's environment variable definition does not apply to individual containers automatically.
* [nginx - Official Image | Docker Hub](https://hub.docker.com/_/nginx/)  
  Explains how to use the official nginx container image.
* [Appendix:Basic English word list - Wiktionary, the free dictionary](https://en.wiktionary.org/wiki/Appendix:Basic_English_word_list)  
  Used to select common words for generating random passphrases.

## Licensing

Unless otherwise noted(individual file's header/[REUSE DEP5](.reuse/dep5)), this product is licensed under [the 4.0 International version of the Creative Commons Attribution-ShareAlike license](https://creativecommons.org/licenses/by-sa/4.0/), or any of its more recent versions of your preference.

This work complies to the [REUSE Specification](https://reuse.software/spec/), refer the [REUSE - Make licensing easy for everyone](https://reuse.software/) website for info regarding the licensing of this product.
