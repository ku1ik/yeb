#!/bin/bash

set -e

cd $DIR

if [[ -f ~/.yebrc ]]; then
  source ~/.yebrc
fi

exec ./.yebrc
