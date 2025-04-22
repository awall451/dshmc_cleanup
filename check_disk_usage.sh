#!/bin/bash

echo -e "Checking disk usage...\n\n"

df -h | awk '
  BEGIN { print "Partitions with >= 90% usage:" }
  NR>1 && $5+0 >= 90 { print $0 }
' | grep -v snap

FULL_DISK_PATHS=$(df -h | awk '
  NR>1 && $5+0 >= 90 { print $6 }
  ' | grep -v snap)

echo -e "\n\nPath to full partitions are $FULL_DISK_PATHS\n\n"

for path in $FULL_DISK_PATHS; do
  echo -e "Checking for large files in $path\n\n"
  sudo du -h --threshold=1G $path/* 2>/dev/null | sort -h
  echo ""
  echo ""
done
