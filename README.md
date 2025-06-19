# News Article Scraper

This project is a Bash/Python-based framework for scraping news articles from various Indian news websites. It automates the process of downloading HTML pages, extracting article content, and storing links in a SQLite database for further processing.

---

## Project Structure

```
launch.sh
main.sh
setup_env.sh
fun/
    databaseInit.sh
    dom_scrapper.py
    download_pages.sh
    extractLinks.sh
    helperFunctions.sh
ip/
    ip_bhaskar.txt
    ip_lokmat.txt
    ip_loksatta.txt
    ip_marathi_inditimes.txt
    ip_mayboli.txt
    ip_navbharat_times.txt
    ip_pudhari.txt
    ip_pudharPune.txt
    ip_tarunbharat.txt
```

---

## File-by-File Analysis

### 1. [setup_env.sh](setup_env.sh)
- **Purpose:** Sets up the Python environment.
- **Actions:**
  - Checks for Python3 and installs it if missing.
  - Creates a Python virtual environment (`env`).
  - Activates the environment and upgrades `pip`.
  - Installs required Python packages: `beautifulsoup4`, `playwright`, `requests`, `lxml`.
  - Installs Playwright browsers.
- **Usage:**  
  ```sh
  bash setup_env.sh
  ```

---

### 2. [launch.sh](launch.sh)
- **Purpose:** Entry point for running the scraper for a specific news site.
- **Actions:**
  - Takes a single argument: a config file from the `ip/` directory.
  - Reads the first five lines: URL, headline tag, headline class, content tag, content class.
  - Passes these as arguments to `main.sh`.
- **Usage:**  
  ```sh
  bash launch.sh ip/ip_pudhari.txt
  ```

---

### 3. [main.sh](main.sh)
- **Purpose:** Orchestrates the scraping workflow for a single site.
- **Actions:**
  - Sources helper scripts from `fun/`.
  - Extracts the site name from the URL.
  - Creates a directory and SQLite database for the site.
  - Downloads the homepage DOM and extracts the main article.
  - Inserts the base URL into the database.
  - Extracts links from the homepage and inserts them into the database.
  - Calls `download_pages` to recursively download and process linked pages.
- **Key Functions Used:**
  - [`extract_site_name`](fun/helperFunctions.sh)
  - [`create_database`](fun/databaseInit.sh)
  - [`insert_link`](fun/helperFunctions.sh)
  - [`extract_links`](fun/extractLinks.sh)
  - [`download_pages`](fun/download_pages.sh)

---

### 4. [fun/databaseInit.sh](fun/databaseInit.sh)
- **Purpose:** Initializes the SQLite database schema.
- **Tables:**
  - `status_help`: Maps status codes to human-readable status.
  - `links`: Stores all discovered links, their status, and output file mapping.
- **Function:**
  - `create_database <db_file>`

---

### 5. [fun/helperFunctions.sh](fun/helperFunctions.sh)
- **Purpose:** Provides utility functions for string manipulation, database operations, and file handling. (Some functions are not used in the current scripts but may be useful for future extensions.)
- **Key Functions:**
  - `extract_site_name`: Extracts the site name from a URL.
  - `escape_single_quotes`: Escapes single quotes for SQL.
---

### 6. [fun/extractLinks.sh](fun/extractLinks.sh)
- **Purpose:** Extracts all internal links from a downloaded HTML file and inserts them into the database.
- **Logic:**
  - Uses `grep` to find all `href` and `src` attributes.
  - Normalizes relative links to absolute URLs.
  - Filters out external links and asset files (images, CSS, JS, etc.).
  - Calls `insert_link` for each valid link.

---

### 7. [fun/download_pages.sh](fun/download_pages.sh)
- **Purpose:** Downloads all pages whose links are in the database with status `0` (not yet downloaded).
- **Logic:**
  - Loops through all pending links.
  - For each, calls the Python scraper to download and extract content.
  - On success, marks the link as downloaded and extracts further links from the page.
  - Implements retry logic for failed downloads, updating status accordingly.

---

### 8. [fun/dom_scrapper.py](fun/dom_scrapper.py)
- **Purpose:** Downloads a web page and extracts article headlines and content using BeautifulSoup.
- **Arguments:**
  1. URL
  2. Local HTML file path
  3. Headline tag (e.g., `h1`)
  4. Headline class (or `none`)
  5. Content tag (e.g., `div`)
  6. Content class (or `none`)
  7. Output file for extracted content
- **Logic:**
  - Downloads the page and saves it.
  - Parses the HTML and finds headlines and content blocks.
  - Writes extracted articles to the output file.
  - Returns exit codes to indicate success, no article found, or error.

---

### 9. [ip/*.txt](ip/)
- **Purpose:** Configuration files for each news site.
- **Format:**  
  1. Base URL  
  2. Headline tag  
  3. Headline class  
  4. Content tag  
  5. Content class  
- **Example:**  
  ```
  https://www.pudhari.news
  h1
  arr--story--headline-h1 story-headline-m_headline__x10-O story-headline-m_dark__1_kPz
  div
  text-story-m_gap-16__5BPKQ
  ```

---

## How the Workflow Proceeds

1. **Setup:**  
   Run `setup_env.sh` to prepare the Python environment.

2. **Launch:**  
   Use `launch.sh` with a config file from `ip/` to start scraping a site.

3. **Main Orchestration:**  
   `main.sh` coordinates database creation, homepage download, link extraction, and recursive page downloads.

4. **Database:**  
   All discovered links and their statuses are tracked in a SQLite database per site.

5. **Extraction:**  
   The Python script downloads and parses each page, extracting articles and saving them to text files.

6. **Recursion:**  
   Newly discovered internal links are added to the database and processed until all are downloaded or failed.

---

## Extending to New Sites

- Add a new config file in `ip/` with the required selectors for the new site.
- Run `launch.sh` with the new config file.

---

## Requirements

- Bash
- Python 3
- SQLite3
- Python packages: `beautifulsoup4`, `playwright`, `requests`, `lxml`

---

## Notes

- The system is designed for news sites with predictable HTML structures.
- The scraping logic can be extended or refined by editing the config files or the Python extraction script.

---

## Troubleshooting

- If you encounter missing dependencies, rerun `setup_env.sh`.
- Ensure all shell scripts are executable by running:
    ```sh
    chmod +x *.sh fun/*.sh
    ```
- Check the log output for errors related to network, parsing, or database operations.

---

## Authors

- Scripted and maintained by Vrundavan.
