#!/bin/bash
source fun/helperFunctions.sh
source fun/extractLinks.sh
download_pages() {
	DB_FILE=$1
	BASE_FOLDER=$2
	reg_1_1=$3
	reg_1_2=$4
	reg_2_1=$5
	reg_2_2=$6

	# Create directory if it doesn't exist
	mkdir -p "${BASE_FOLDER}_Articles"

	while true; do
		sleep 2
		# Fetch URLs and their corresponding output file names from the database
		url_output_pairs=$(sqlite3 "$DB_FILE" "SELECT raw_link, updated_link FROM links WHERE status=0;")
	
	        if [[ -z "$url_output_pairs" ]]; then
	            echo "No more URLs to process. Exiting."
	            break
	        fi
	
		counters=1
		sleep_counter=0
		# Loop through each URL-output file pair and download the page
		while IFS='|' read -r url output_file; do
			echo "Downloading $url to $output_file"
			
			# Retry logic
			for i in {1..3}; do
				# Use download_dom_page to fetch the page content
			 #	echo "before Downloading"
			 #	echo $output_file
				# it is a file name where content is written
				local file_name=${BASE_FOLDER}_Articles/$(echo "$output_file" | sed 's/\//_/g' | sed 's/\.html//g').txt
				SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
				#-----------------------------------------------------------
			
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
			
				
				#-----------------------------------------------------------
				python3 "$SCRIPT_DIR/dom_scrapper.py" "$url" "$output_file" "$reg_1_1" "$reg_1_2" "$reg_2_1" "$reg_2_2" "$file_name" >> "$LOG_FILE"
				status=$?
				echo "Status: $status"
				# Check the exit status of the Python script
				if [ $status -eq 2 ] || [ $status -eq 0 ]; then   # Indicating successful download or no article found
					if [ $status -eq 0 ]; then # Indicating article found
						echo "Article Found"
					elif [ $status -eq 2 ]; then # Indicating no article found
						echo "No Article Found"
					fi
					extract_links "$output_file" "$BASE_URL" "$DB_FILE" "$BASE_FOLDER" 	
					echo "Links Extracted"					
					# Update status to 1 (downloaded) if successful
					sqlite3 "$DB_FILE" "UPDATE links SET status=1 WHERE raw_link='$url';"
					break  # Exit the retry loop on success
					
				elif [ $status -eq 1 ]; then  # Indicating download error
					echo "Retrying download: attempt $i"
					
					# Update status based on the current attempt number
					case $i in
						1) sqlite3 "$DB_FILE" "UPDATE links SET status=3 WHERE raw_link='$url';" ;;
						2) sqlite3 "$DB_FILE" "UPDATE links SET status=4 WHERE raw_link='$url';" ;;
						3) sqlite3 "$DB_FILE" "UPDATE links SET status=5 WHERE raw_link='$url';" ;;
					esac
					sleep 2
					# Update status to 6 (error: downloading attempt exceeded) if failed after 3 attempts
					if [ $i -eq 3 ]; then
						sqlite3 "$DB_FILE" "UPDATE links SET status=6 WHERE raw_link='$url';"
					fi
				fi
			done
			((sleep_counter++))
			echo "Sleep Counter is {$sleep_counter}"
			if [ $sleep_counter -ge 100 ]; then
	        		echo "Processed 100 links, sleeping for 3 seconds..."
	        		sleep 3
	        		sleep_counter=0  # Reset the counter after sleeping
	    		fi
		done <<< "$url_output_pairs"
	done

}
