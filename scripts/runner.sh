#!/bin/bash

set -e

cd $DIR >/dev/null 2>&1

if [[ -f ~/.yebrc ]]; then
  source ~/.yebrc
fi

if [[ -f .yebrc ]]; then
  source .yebrc
fi

exec "$@"
