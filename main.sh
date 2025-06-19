#!/bin/bash

source fun/databaseInit.sh
source fun/extractLinks.sh
source fun/helperFunctions.sh
source fun/download_pages.sh
main() {
	url=$1
	reg_1_1=$2
	reg_1_2=$3
	reg_2_1=$4
	reg_2_2=$5

	echo "URL: $url"


	site_name="$(extract_site_name "$url")"
	echo "$site_name"
	# Ensure the directory exists
	mkdir -p "$site_name"

	# Set database file path
	DB_FILE="${site_name}.db"

	# Create the database
	create_database "$DB_FILE"
	echo "Database Created"

	# Set DOM file path and base URL
	dom_file="${site_name}/index.html"
	BASE_URL="https://$url"
	echo "$DB_FILE"

	file_name=$(echo "$dom_file" | sed 's/\//_/g' |sed 's/\.html//g').txt
	SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
	python3 "$SCRIPT_DIR/fun/dom_scrapper.py" "$url" "$dom_file" "$reg_1_1" "$reg_1_2" "$reg_2_1" "$reg_2_2" "$file_name"
	status=$?
	# Check the exit status of the Python script
	# Download the DOM of the page

    if [ $status -eq 2 ] || [ $status -eq 0 ]; then   # Indicating successful download or no article found ; then
		echo "DOM Page downloaded"
	else
		echo "Failed to download DOM page. Exiting."
		exit 1
	fi
	
	
	# Insert base URL into the database as a downloaded link
	insert_link "$BASE_URL/" "$BASE_URL/" 1 "$DB_FILE" "$site_name"
	insert_link "$BASE_URL" "$BASE_URL"  1  "$DB_FILE" "$site_name"


	# Extract and process the links
	extract_links "$dom_file" "$BASE_URL" "$DB_FILE" "$site_name" "0" 
	echo "Links Extracted"

    download_pages "$DB_FILE" "$site_name" "$reg_1_1" "$reg_1_2" "$reg_2_1" "$reg_2_2"
	#download_assets "$DB_FILE"
	#update_links_in_file "$DB_FILE" "${site_name}/pages"
	#update_links_Index "$DB_FILE" "${site_name}/index.html" 
}

if [ $# -lt 3 ]; then
	echo "Usage: $0 <url> <reg_1_1> <reg_1_2> <reg_2_1> <reg_2_2>"
	exit 1
fi

if ! main "$1" "$2" "$3" "$4" "$5"; then
	echo "An error occurred during execution."
	exit 1
fi

