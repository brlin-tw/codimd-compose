# Compose container deployment of CodiMD

Launch a [CodiMD](https://github.com/hackmdio/codimd) service instance that satisfies your requirements in seconds!

<https://gitlab.com/brlin/codimd-compose>  
[![The GitLab CI pipeline status badge of the project's `main` branch](https://gitlab.com/brlin/codimd-compose/badges/main/pipeline.svg?ignore_skipped=true "Click here to check out the comprehensive status of the GitLab CI pipelines")](https://gitlab.com/brlin/codimd-compose/-/pipelines) [![GitHub Actions workflow status badge](https://github.com/brlin-tw/codimd-compose/actions/workflows/check-potential-problems.yml/badge.svg "GitHub Actions workflow status")](https://github.com/brlin-tw/codimd-compose/actions/workflows/check-potential-problems.yml) [![pre-commit enabled badge](https://img.shields.io/badge/pre--commit-enabled-brightgreen?logo=pre-commit&logoColor=white "This project uses pre-commit to check potential problems")](https://pre-commit.com/) [![REUSE Specification compliance badge](https://api.reuse.software/badge/gitlab.com/brlin/codimd-compose "This project complies to the REUSE specification to decrease software licensing costs")](https://api.reuse.software/info/gitlab.com/brlin/codimd-compose)

## Prerequisites

The following prerequisites must be met in order to use this product:

* The service host:
    + Must have Docker installed.
    + Must have access to the Docker Hub container registry service.
    + Must have Internet connectivity during the deployment of the service.
* You must have:
    + Access to the service host's text terminal.
    + Permission to run Docker commands on the service host.

## Reference

* [Docker Deployment - HackMD](https://hackmd.io/s/codimd-docker-deployment)  
  The upstream project's relevant documentation.
* [CodiMD Configuration - HackMD](https://hackmd.io/s/codimd-configuration)  
  The configuration documentation of the CodiMD software.
* [environment variables - Docker-compose env file not working - Stack Overflow](https://stackoverflow.com/questions/48495663/docker-compose-env-file-not-working)  
  Explains why the .env file's environment variable definition does not apply to individual containers automatically.

## Licensing

Unless otherwise noted(individual file's header/[REUSE DEP5](.reuse/dep5)), this product is licensed under [the 4.0 International version of the Creative Commons Attribution-ShareAlike license](https://creativecommons.org/licenses/by-sa/4.0/), or any of its more recent versions of your preference.

This work complies to the [REUSE Specification](https://reuse.software/spec/), refer the [REUSE - Make licensing easy for everyone](https://reuse.software/) website for info regarding the licensing of this product.
