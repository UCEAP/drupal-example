#!/bin/bash
set -eo pipefail

# Download and extract files
if [ -z "$TERMINUS_TOKEN" ]; then
  # Fallback to DEVOPS_TERMINUS_TOKEN if personal token is not set (intended for Codespaces).
  if [ -z "$DEVOPS_TERMINUS_TOKEN" ]; then
    echo "Please set the TERMINUS_TOKEN environment variable."
    exit 1
  fi
  export TERMINUS_TOKEN=$DEVOPS_TERMINUS_TOKEN
fi
terminus auth:login --machine-token=$TERMINUS_TOKEN
export TERMINUS_ENV="dev"
terminus backup:get --element=files --to=files.tar.gz
tar zx --no-same-permissions --strip-components 1 -C web/sites/default/files -f files.tar.gz
rm files.tar.gz

# no-same-permissions doesn't seem to work so we fix it here
sudo find web/sites/default/files -type d -exec chmod g+ws {} +
sudo find web/sites/default/files -type f -exec chmod g+w {} +

# Install Terraform
# TODO move this into base image

sudo apt-get install -y gnupg software-properties-common
wget -O- https://apt.releases.hashicorp.com/gpg | \
  gpg --dearmor | \
  sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg > /dev/null
gpg --no-default-keyring \
  --keyring /usr/share/keyrings/hashicorp-archive-keyring.gpg \
  --fingerprint
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | \
  sudo tee /etc/apt/sources.list.d/hashicorp.list > /dev/null
sudo apt update
sudo apt-get install -y terraform

# Install Azure CLI
# TODO move this into base image

sudo apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release
sudo mkdir -p /etc/apt/keyrings
curl -sLS https://packages.microsoft.com/keys/microsoft.asc | \
  gpg --dearmor | sudo tee /etc/apt/keyrings/microsoft.gpg > /dev/null
sudo chmod go+r /etc/apt/keyrings/microsoft.gpg
AZ_DIST=$(lsb_release -cs)
echo "Types: deb
URIs: https://packages.microsoft.com/repos/azure-cli/
Suites: ${AZ_DIST}
Components: main
Architectures: $(dpkg --print-architecture)
Signed-by: /etc/apt/keyrings/microsoft.gpg" | sudo tee /etc/apt/sources.list.d/azure-cli.sources > /dev/null
sudo apt-get update
sudo apt-get install -y azure-cli
