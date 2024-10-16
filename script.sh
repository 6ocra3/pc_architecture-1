#!/usr/bin/env bash

# Checking the number of arguments
if [ "$#" -lt 2 ]; then
    echo "ERROR: Not enough arguments. Usage: $0 <directory> <size_limit_mb> [files_count]"
    exit 1
fi

files_to_backup="${3:-5}"
output_directory="$HOME/safe_storage/backup"
source_folder="$1"
limit_size=$(($2 * 1024 * 1024))

# Checking if the source directory exists
if [ ! -d "$source_folder" ]; then
    echo "ERROR: directory $source_folder not found."
    exit 1
fi

# Creating the output directory if it doesn't exist
[ ! -d "$output_directory" ] && mkdir -p "$output_directory"

# Calculating the size of the source directory
dir_size_bytes=$(find "$source_folder" -type f -exec stat --format="%s" {} \; | awk '{s+=$1} END {print s}')

# If directory is empty, set size to 0
if [ -z "$dir_size_bytes" ]; then
    dir_size_bytes=0
fi

echo "Current size of $source_folder: $(( dir_size_bytes / (1024 * 1024) )) MB"

# Check if the directory size exceeds the limit
if (( dir_size_bytes > limit_size )); then
    echo "Folder size exceeds limit. Archiving $files_to_backup old files..."

    # Finding and archiving old files
    files_to_archive=$(find "$source_folder" -type f -printf "%T@ %p\n" | sort -n | head -n "$files_to_backup" | cut -d' ' -f2)

    if [ -n "$files_to_archive" ]; then
        archive_name="$output_directory/backup_$(date +%Y%m%d_%H%M%S).tar.gz"
        tar -czf "$archive_name" $files_to_archive

        if [ $? -eq 0 ]; then
            echo "Backup created: $archive_name"
            echo "Deleting old files..."
            for file in $files_to_archive; do
                rm "$file" && echo "Deleted: $file"
            done
        else
            echo "ERROR: Failed to create backup."
            exit 1
        fi
    else
        echo "No files to archive."
    fi
else
    echo "Folder size is within the limit. No need to archive."
fi
