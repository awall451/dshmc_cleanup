#!/usr/bin/env bash

source ./dependencies/*

# Function to find large dirs/files under a full mount point
checkFullDirs() {
  sudo du -h --threshold=1G "$path"/* 2>/dev/null | sort -h
}

# Function to find large and/or interesting files
searchLargeFilesInDir() {
  local target_dir="$1"

  echo -e "\n🔍 Searching in $target_dir\n"

  # Core dumps
  echo "🧠 Core dumps:"
  while IFS= read -r line; do
    echo "$line"
    CORE_FILES+=("$(awk '{print $2}' <<< "$line")")
  done < <(sudo find "$target_dir" -type f -name "core*.dmp" -exec du -h {} + 2>/dev/null | sort -h)

  # Log files
  echo -e "\n📜 Log files:"
  while IFS= read -r line; do
    echo "$line"
    LOG_FILES+=("$(awk '{print $2}' <<< "$line")")
  done < <(sudo find "$target_dir" -type f \( -iname "*.log" -o -iname "*.out" \) -exec du -h {} + 2>/dev/null | sort -h)

  # Other large files
  echo -e "\n📦 Other large files (>100MB):"
  while IFS= read -r line; do
    echo "$line"
    LARGE_FILES+=("$(awk '{print $2}' <<< "$line")")
  done < <(sudo find "$target_dir" -type f -size +100M -exec du -h {} + 2>/dev/null | sort -h)
}

# Function to find large and/or interesting files
#searchLargeFilesInDir() {
#  local target_dir="$1"
#
#  echo -e "\n🔍 Searching in $target_dir\n"
#
#  echo "🧠 Core dumps:"
#  sudo find "$target_dir" -type f -name "core*.dmp" -exec du -h {} + 2>/dev/null | sort -h
#
#  echo -e "\n📜 Log files:"
#  sudo find "$target_dir" -type f \( -iname "*.log" -o -iname "*.out" -o \) -exec du -h {} + 2>/dev/null | sort -h
#
#  echo -e "\n📦 Other large files (>100MB):"
#  sudo find "$target_dir" -type f -size +100M -exec du -h {} + 2>/dev/null | sort -h
#}

echo -e "Checking disk usage...\n\n"

df -h | awk '
  BEGIN { print "Partitions with >= 90% usage:" }
  NR>1 && $5+0 >= 90 { print $0 }
' | grep -v snap

# Read full disk mount paths into an array
readarray -t FULL_DISK_PATHS < <(df -h | awk 'NR>1 && $5+0 >= 90 { print $6 }' | grep -v snap)

# Prepare a Bash array for full directories/files
FULL_DIRS=()

for path in "${FULL_DISK_PATHS[@]}"; do
  
  # Call the function and extract the second column (directory path)
  while IFS= read -r line; do
    dir_path=$(awk '{print $2}' <<< "$line")
    FULL_DIRS+=("$dir_path")
  done < <(checkFullDirs)
done

echo

# Display the options
echo "Directories to investigate:"
for dir in "${FULL_DIRS[@]}"; do
  echo "$dir"
done

echo

# Build OPTIONS_STRING for prompt
OPTIONS_STRING=""
for dir in "${FULL_DIRS[@]}"; do
  OPTIONS_STRING+="$dir;"
done

# Prompt for selection
prompt_for_multiselect SELECTED "$OPTIONS_STRING"

# Gather checked values
CHECKED=()
for i in "${!SELECTED[@]}"; do
  if [ "${SELECTED[$i]}" == "true" ]; then
    CHECKED+=("${FULL_DIRS[$i]}")
  fi
done

echo "Selected directories for investigation:"
echo "${CHECKED[@]}"

for DIR in "${!CHECKED[@]}"; do
  sudo find $DIR -type f -name "core*.dmp" -exec du -h {} \; | sort -h
done

echo -e "\n\n📁 Investigating selected directories...\n"

CORE_FILES=()
LOG_FILES=()
LARGE_FILES=()

for dir in "${CHECKED[@]}"; do
  searchLargeFilesInDir "$dir"
done

echo -e "\n\nSelect core dump files to delete:"

# Select core dump files to delete
#ALL_FILES=("${CORE_FILES[@]}" "${LOG_FILES[@]}" "${LARGE_FILES[@]}")

# Convert into options string for prompt
OPTIONS_STRING=""
for file in "${CORE_FILES[@]}"; do
  OPTIONS_STRING+="$file;"
done

prompt_for_multiselect SELECTED "$OPTIONS_STRING"

for i in "${!SELECTED[@]}"; do
  if [ "${SELECTED[$i]}" == "true" ]; then
    FILES_TO_DELETE+=("${CORE_FILES[$i]}")
  fi
done

echo "${FILES_TO_DELETE[@]}"
