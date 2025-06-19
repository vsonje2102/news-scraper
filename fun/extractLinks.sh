extract_links() {
    OUTPUT_FILE=$1
    BASE_URL=$2
    DB_FILE=$3
    base_folder=$4
    site_name=$(basename "$base_folder")
    echo "Processing file: $OUTPUT_FILE in folder: $base_folder"

    links_inserted=0
    
    while IFS= read -r raw_link; do
	
        original_link="$raw_link"
        #echo "$original_link"
	# Normalize the link
        
	if [[ "$raw_link" != http* ]]; then
            raw_link="$BASE_URL/${raw_link#/}"
            #echo "Updated Raw Link ${raw_link}"
    fi

    #site_name="pudhari"
    # Only process internal: links belonging to the current site
    # if [[ ! "$raw_link" =~ ^https?://(www\.)?${site_name}\.?(com)? ]]; then
    #     continue
    # fi
    if [[ ! "$raw_link" =~ ^https?://(www\.)?${site_name}\.(com|news)(/.*)?$ ]]; then
        continue
    fi
    
	raw_link=$(escape_single_quotes "$raw_link")

        if [[ "$raw_link" =~ javascript:|\.(css|js|png|jpg|jpeg|gif|svg|woff|woff2|ttf|eot|ico|bmp|webp|json|net)(\?.*)?$ ]]; then
            # Skip links that are assets JavaScript or have certain file extensions
            #echo "Skipping link: $raw_link"
            continue
        fi

        
        if insert_link "$raw_link" "$original_link" 0 "$DB_FILE" "$site_name"; then
            ((links_inserted++))
            #echo "Link Inserted"
            page_counter=$((page_counter + 1))
        fi
        
    done < <(grep -oP '(?<= href=")[^"]*|(?<= src=")[^"]*' "$OUTPUT_FILE")

    # Display counts for this file
    #echo "Finished processing file: $OUTPUT_FILE"
    echo "Links Inserted: $links_inserted"

    echo "---------------------------------------------"
}
