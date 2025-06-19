#!/bin/bash

if [ $# -ne 1 ]; then
    echo "Usage: $0 <input_file>"
    exit 1
fi

input_file="$1"

site_name=$(sed -n '1p' "$input_file")
reg_1_1=$(sed -n '2p' "$input_file")
reg_1_2=$(sed -n '3p' "$input_file")
reg_2_1=$(sed -n '4p' "$input_file")
reg_2_2=$(sed -n '5p' "$input_file")

if [[ -z "$site_name" || -z "$reg_1_1" || -z "$reg_1_2" || -z "$reg_2_1" || -z "$reg_2_2" ]]; then
    echo "Error: Input file must contain at least 5 non-empty lines (site name and 4 regexes)."
    exit 1
fi

echo "Regular Expression 1: $reg_1_1 to $reg_1_2"
echo "Regular Expression 2: $reg_2_1 to $reg_2_2"
./main.sh "$site_name" "$reg_1_1" "$reg_1_2" "$reg_2_1" "$reg_2_2"
