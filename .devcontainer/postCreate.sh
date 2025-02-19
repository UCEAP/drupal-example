#!/bin/bash

# set ports to be publicly accessible
if [[ -n "$CODESPACE_NAME" ]]; then
  gh codespace ports visibility 8080:public -c $CODESPACE_NAME
fi