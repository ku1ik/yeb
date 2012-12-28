#!/bin/bash

set -e

if [[ -f ~/.yebrc ]]; then
  source ~/.yebrc
fi

cd $1

if [[ -f .yebrc ]]; then
  source .yebrc
fi

if [[ -z $WEB ]]; then
  if [ $(which thin 2>/dev/null) ]; then
    WEB="thin start -p $PORT"
  else
    WEB="rackup -p $PORT"
  fi
fi

exec $WEB
