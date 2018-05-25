#!/bin/bash
set -e

# Pull test deps
docker pull "hashicorp/terraform:$TERRAFORM_VERSION"
docker pull "koalaman/shellcheck:$SHELLCHECK_VERSION"
docker pull "jamesmstone/shfmt:$SHFMT_VERSION"
docker pull "boiyaa/yamllint:$YAMLLINT_VERSION"
