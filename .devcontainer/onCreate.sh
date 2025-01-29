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
