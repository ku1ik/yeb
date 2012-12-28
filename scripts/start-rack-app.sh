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
  if [[ -f Gemfile ]]; then
    runner="bundle exec"
  fi

  if [ $($runner which thin 2>/dev/null) ]; then
    WEB="$runner thin start -p $PORT"
  else
    WEB="$runner rackup -p $PORT"
  fi
fi

exec $WEB
