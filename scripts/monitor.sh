#!/bin/zsh

while do;
  echo -ne '\033c'
  ps --pid "$(echo `=pgrep -f thin` `=pgrep -f rackup` `=pgrep -f yeb` `=pgrep -f master`)" -o cmd,pid,ppid,pgid
  sleep 1
done
