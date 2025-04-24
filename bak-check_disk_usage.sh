#!/usr/bin/env bash

source ./dependencies/*

# Functions
# Find full directories to investigate
checkFullDirs() {
  sudo du -h --threshold=1G $path/* 2>/dev/null | sort -h
}

# Actual script
echo -e "Checking disk usage...\n\n"

df -h | awk '
  BEGIN { print "Partitions with >= 90% usage:" }
  NR>1 && $5+0 >= 90 { print $0 }
' | grep -v snap

#FULL_DISK_PATHS=$(df -h | awk '
#  NR>1 && $5+0 >= 90 { print $6 }
#  ' | grep -v snap)

readarray -t FULL_DISK_PATHS < <(df -h | awk 'NR>1 && $5+0 >= 90 { print $6 }' | grep -v snap)
  
echo
echo
echo $FULL_DISK_PATHS  

echo -e "\n\nPath to full partitions are $FULL_DISK_PATHS\n\n"

#for path in "${FULL_DISK_PATHS[@]}"; do
#  echo -e "Checking for large files and directories in $path\n\n"
#  checkFullDirs
#  echo ""
#  echo ""
#done

for path in "${FULL_DISK_PATHS[@]}"; do
  echo -e "Checking for large files and directories in $path\n\n"
  checkFullDirs
  OUTPUT=$(checkFullDirs | awk '{print $2}')
  FULL_DIRS+="$OUTPUT"
  echo ""
  echo ""
done

echo $FULL_DIRS

OPTIONS_VALUES=("OpenVDSBlobStorage" "EIA" "Geofiles" "Mongo" "Witsml" "PPDM" "OpenVDSS3" "AWSBatch" "AzureBatch" "Dataimport" )


for i in "${!OPTIONS_VALUES[@]}"; do
	OPTIONS_STRING+="${OPTIONS_VALUES[$i]};"
done

prompt_for_multiselect SELECTED "$OPTIONS_STRING"

for i in "${!SELECTED[@]}"; do
	if [ "${SELECTED[$i]}" == "true" ]; then
		CHECKED+=("${OPTIONS_VALUES[$i]}")
	fi
done
echo "${CHECKED[@]}"

#for i in "${!FULL_DIRS[@]}"; do
#	OPTIONS_STRING+="${OPTIONS_VALUES[$i]};"
#done
#
#prompt_for_multiselect SELECTED "$OPTIONS_STRING"
#
#for i in "${!SELECTED[@]}"; do
#	if [ "${SELECTED[$i]}" == "true" ]; then
#		CHECKED+=("${OPTIONS_VALUES[$i]}")
#	fi
#done
#echo "${CHECKED[@]}"


#source ./dependencies/*
#
#which prompt_for_multiselect

# For later
# sudo find /media/dillon/_/ -type f -name "*.log" -exec du -h {} \; | sort -h
