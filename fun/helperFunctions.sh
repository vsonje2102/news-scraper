#!/bin/bash

# Function to extract the site name from the URL
#extract_site_name() {
#	echo "$1" | grep -oP '^(?:https?//)?(www\.)?\K[^.]+'
#}
extract_site_name() {
    echo "$1" | sed -E 's~https?://~~; s~www\.~~; s~\.(com|news).*~~'
}



# Function to download the DOM of the page using Headless Chromium
download_dom_page() {
    URL=$1
    OUTPUT_FILE=$2

    # Check if the chromiumlog.txt file exceeds 1MB (1024*1024 bytes)
    LOG_FILE="chromiumlog.txt"
    # Create the log file if it does not exist
    if [ ! -f "$LOG_FILE" ]; then
        touch "$LOG_FILE"
    fi
    MAX_LOG_SIZE=$((1024 * 1024))  # 1MB in bytes

    # Check the file size using stat or du (returns size in bytes)
    log_size=$(stat --format=%s "$LOG_FILE")
    #echo $log_size
    
    # If the file size is greater than or equal to 1MB, delete it
    if [[ "$log_size" -ge "$MAX_LOG_SIZE" ]]; then
        echo "Log file size exceeds 1MB, deleting it."
        rm -f "$LOG_FILE"
    fi

    # Run Chromium in headless mode to fetch the page content with a timeout
    #timeout 30s chromium-browser --headless --disable-gpu --no-sandbox --disable-dev-shm-usage --dump-dom "$URL" > "$OUTPUT_FILE" 2>> "$LOG_FILE"
    python3 fetch_dom.py "$URL" "$OUTPUT_FILE" 2>> "$LOG_FILE"

    # Check if the downloaded DOM page is empty
    if [ ! -s "$OUTPUT_FILE" ]; then
        echo "Downloaded DOM page is empty for URL: $URL"
        return 1
    fi
    # Check if the Chromium command succeeded
    if [ $? -ne 0 ]; then
        echo "Download failed or timed out for URL: $URL"
        return 1
    fi

    return 0
}



# Function to escape single quotes in URLs to prevent SQL issues
escape_single_quotes() {
	echo "$1" | sed "s/'/\\\'/g"
}

# Function to extract the file extension from a URL
get_extension() {
    extension=$(echo "$1" | awk -F'[?]' '{print $1}' | awk -F'.' '{print $NF}')
    echo "$extension"
}

# Function to insert link information into the database
insert_link() {
    RAW_LINK=$1
    ORIGINAL_LINK=$2
    STATUS=$3
    DB_FILE=$4
    site_name=$5

    # Check if the link already exists in the database to avoid duplicates
    existing_link=$(sqlite3 "$DB_FILE" "SELECT 1 FROM links WHERE raw_link='$RAW_LINK' LIMIT 1;")
    if [[ -n "$existing_link" ]]; then
        #echo "Duplicate Link Detected: $RAW_LINK"
        return 1  # Skip inserting the duplicate link
    fi

    # Attempt to insert the link into the database
    sqlite3 "$DB_FILE" <<EOF
        INSERT OR IGNORE INTO links (raw_link, original_link,  status) 
        VALUES ('$RAW_LINK', '$ORIGINAL_LINK', $STATUS);
EOF

    updated_link=$(sqlite3 "$DB_FILE" "SELECT printf('%s/%08d.html', '$site_name', id) FROM links WHERE id = (SELECT MAX(id) FROM links);")
	#echo $updated_link
    sqlite3 "$DB_FILE" <<EOF
        UPDATE links
        SET updated_link = "$updated_link"		
	WHERE id = (select max(id) from links);
EOF

    # Check if the last command was successful
    if [ $? -eq 0 ]; then
        #echo "Inserted Successfully:"
        #echo "RAW_LINK: $RAW_LINK"
        #echo "ORIGINAL_LINK: $ORIGINAL_LINK"
        #echo "NEW_LINK: $NEW_LINK"
        #echo "-----------------------------------------"
		return 0
	else
		return 1
    fi
}
extract_html_block() {
	local file="$1"
	local start_pattern="$2"   # Example: '<h1 class="article-head">'
	local end_pattern="$3"     # Example: '</h1>'

	awk -v start="$start_pattern" -v end="$end_pattern" '
	BEGIN { flag=0 }
	index($0, start) { flag=1 }
	index($0, end) && flag {
		print
		flag=0
		next
	}
	flag { print }
	' "$file" | sed 's/<[^>]*>//g' | xargs
}

# Function to map file extensions to type values
get_type_value() {
	case "$1" in
		png) echo 1 ;;
		jpg) echo 2 ;;
		css) echo 3 ;;
		js) echo 4 ;;
		svg) echo 5 ;;
		jpeg) echo 6 ;;
		woff2) echo 7 ;;
		ttf) echo 8 ;;
		eot) echo 9 ;;
		ico) echo 10 ;;
		bmp) echo 11 ;;
		webp) echo 12 ;;
		json) echo 13 ;;
		net) echo 14 ;;
		woff) echo 15 ;;
		*) echo 16 ;; # others
	esac
}
