#!/bin/bash
set -e

# Inits module and runs checks
checkModule() {
  module_path=$1
  echo -e "\nTERRAFORM INIT: $module_path ...\n"
  docker run -v "$1:/hostdir" -w /hostdir "hashicorp/terraform:$TERRAFORM_VERSION" init
  echo -e "\nTERRAFORM VALIDATE: $module_path ...\n"
  docker run -v "$1:/hostdir" -w /hostdir "hashicorp/terraform:$TERRAFORM_VERSION" validate -check-variables=false
  echo -e "\nTERRAFORM FORMAT: $module_path ...\n"
  docker run -v "$1:/hostdir" -w /hostdir "hashicorp/terraform:$TERRAFORM_VERSION" fmt -check=true -diff
}

# Check root module
checkModule "$PWD"

# Check each submodule
for module_dir in $(find modules -type d | tail -n +2); do
  checkModule "$PWD/$module_dir"
done

# Check scripts
echo -e "\nSHELLCHECK ...\n"
#shellcheck disable=SC2046
docker run -v "$PWD:/mnt" "koalaman/shellcheck:$SHELLCHECK_VERSION" $(find . -name '*.sh')
echo -e "\nSHFMT ...\n"
#shellcheck disable=SC2046
docker run -v "$PWD:/hostdir" -w /hostdir "jamesmstone/shfmt:$SHFMT_VERSION" -i 2 -w $(find . -name '*.sh')
git diff --exit-code

# Check YAMLs
echo -e "\nYAMLLINT ...\n"
#shellcheck disable=SC2046
docker run -v "$PWD:/workdir" "boiyaa/yamllint:$YAMLLINT_VERSION" -c .yamllint.yml -s $(find . -type f -name '*.yml')
