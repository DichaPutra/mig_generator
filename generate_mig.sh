#!/bin/bash

#----------------   READ ME !!!  ------------------#
# Save this file into your main project path / folder
# Run 'chmod +x generate_mig.sh' in terminal to ensure the script has executable permissions
# Checkout into your feature branch
# Ensure that your feature branch is up to date with your main branch
# Run './generate_mig.sh {your_branch_feature}'
# Example: ./generate_mig.sh feature/BL-1234
# Your mig file will be generated in your main project folder as a CSV file
# Finish

# Permission chmod +x generate_mig.sh
#--------------- END READ ME !!! -----------------#

# Default base branch (change this branch name based on your main branch)
base_branch="release/production"

# Function to display script usage
usage() {
    echo "Usage: ./generate_mig.sh [compare_branch]"
    echo "Example: ./generate_mig.sh feature/BL-1234"
}

# Check if a compare branch name is provided as a command-line argument
if [ $# -eq 1 ]; then
    compare_branch="$1"
else
    usage
    exit 1
fi

# Pull latest changes from origin for the base branch
echo "Pulling latest changes from origin for $base_branch..."
git pull origin "$base_branch"

# Pull latest changes from origin for the compare branch
echo "Pulling latest changes from origin for $compare_branch..."
git pull origin "$compare_branch"

# Specify the output CSV file path
output_csv="mig_${compare_branch//\//-}.csv"  # Replace '/' with '-' in branch name for filename

# Prepare CSV file header
echo "No,release/development,Type,File Size Feature,Compile,No,release/production,Type,File Size Base,Compile" > "$output_csv"

# Initialize auto-increment counter
number=1

# Loop through each changed file in the compare branch
while IFS= read -r file; do
    # Get file name, extension, and path
    file_name=$(basename -- "$file")
    file_extension="${file_name##*.}"
    file_name="${file_name%.*}"
    file_path=$(dirname -- "$file")

    # Get current date
    current_date=$(date +"%Y-%m-%d")

    # Get file size in kilobytes (KB) for the compare branch (feature branch) with 3 decimal values
    if git show "$compare_branch":"$file" >/dev/null 2>&1; then
        file_size_bytes_compare=$(git show "$compare_branch":"$file" | wc -c)
        file_size_kb_compare=$(echo "scale=3; $file_size_bytes_compare / 1024" | bc)
        formatted_file_size_compare="${file_size_kb_compare} KB"
    else
        formatted_file_size_compare="N/A"
    fi

    # Get file size in kilobytes (KB) for the base branch (release/production) with 3 decimal values
    if git show "$base_branch":"$file" >/dev/null 2>&1; then
        file_size_bytes_base=$(git show "$base_branch":"$file" | wc -c)
        file_size_kb_base=$(echo "scale=3; $file_size_bytes_base / 1024" | bc)
        formatted_file_size_base="${file_size_kb_base} KB"
    else
        formatted_file_size_base="N/A"
    fi

    # Concatenate file path with filename for CSV output
    full_file_name="${file_path}/${file_name}.${file_extension}"

    # Append formatted row to CSV file
    echo "$number,\"$full_file_name\",\"$file_extension\",\"$formatted_file_size_compare\",\"$current_date\",$number,\"$full_file_name\",\"$file_extension\",\"$formatted_file_size_base\",\"$current_date\"" >> "$output_csv"

    # Increment the counter
    ((number++))
done < <(git diff --name-only "$(git merge-base "$base_branch" "$compare_branch")".."$compare_branch")

echo "Formatted file list generated: $output_csv"
