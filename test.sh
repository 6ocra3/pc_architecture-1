#!/usr/bin/env bash

# Parameters
source_folder="./logs"
output_directory="./archives"
file_size_mb=1024

# Function to clear directories before tests
clear_directories() {
    echo
    echo "Clearing old data in $source_folder and $output_directory..."
    rm -rf "$source_folder" "$output_directory"
    mkdir -p "$source_folder" "$output_directory"
}

# Function to generate test files in /logs
generate_test_files() {
    local total_size_mb="$1"
    local num_files=$((total_size_mb / file_size_mb))
    echo "Creating $num_files files of $file_size_mb MB in folder $source_folder..."

    for i in $(seq 1 "$num_files"); do
        # Create a file with the specified size
        fallocate -l "${file_size_mb}M" "$source_folder/testfile_$i.log"
        # Short delay to alter the timestamp
        sleep 0.1
    done
}

# Function to run test cases and verify the results
run_test_case() {
    local limit_size="$1"
    local files_to_backup="${2:-3}"
    echo "Test: limit_size = $limit_size MB, archive $files_to_backup files"

    # Execute the main script for archiving
    ./script.sh "$source_folder" "$limit_size" "$files_to_backup"
    
    # Verify the number of archived files and remaining files
    local files_archived=$(tar -tzf "$output_directory"/*.tar.gz 2> /dev/null | wc -l)
    local remaining_files=$(ls "$source_folder" | wc -l)

    echo "Files in archive: $files_archived"
    echo "Remain in folder: $remaining_files"
}

# Clear directories to ensure proper test execution
clear_directories

# Test 1
echo "Test 1.0: Folder size > limit_size"
generate_test_files $((6 * 1024))
run_test_case $((5 * 1024)) 4
clear_directories
echo
echo

# Test 2
echo "Test 2.0: Folder size < limit_size"
generate_test_files $((6 * 1024))
run_test_case $((7 * 1024)) 2
clear_directories
echo
echo

# Test 3
echo "Test 3.0: Folder size = limit_size"
generate_test_files $((6 * 1024))
run_test_case $((6 * 1024 + 1))
clear_directories
echo
echo

# Test 4
echo "Test 4.0: No arguments"
generate_test_files $((6 * 1024))
run_test_case $((3 * 1024))
clear_directories
echo
echo

# Test 5
echo "Test 5.0: Files to archive > files in folder (quantity)"
generate_test_files $((6 * 1024))
run_test_case $((5 * 1024)) 10
clear_directories
echo
echo

# Test 6
echo "Test 6.0: Empty folder"
run_test_case $((6 * 1024)) 2
clear_directories
echo
echo
