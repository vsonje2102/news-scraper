import sys
import requests
from bs4 import BeautifulSoup

def download_and_extract(url, local_file, head_tag, head_class, content_tag, content_class, output_file):
    """Download HTML, save to local_file, extract content, and write to output_file."""
    headers = {"User-Agent": "Mozilla/5.0"}
    try:
        response = requests.get(url, headers=headers)
        response.raise_for_status()
        html = response.text
        with open(local_file, "w", encoding="utf-8") as f:
            f.write(html)
        print(f"HTML saved to '{local_file}'")

    except requests.exceptions.RequestException as e:
        print(f"[ERROR] Failed to download URL: {e}")
        sys.exit(1)  # Indicate download error
       
    # Determine if the page is HTML or XML
    content_type = response.headers.get("Content-Type", "").lower()
    if "xml" in content_type:
        soup = BeautifulSoup(html, "xml")
    else:
        soup = BeautifulSoup(html, "html.parser")
    print(head_class)
    if head_class.lower() == "none":
        #print("None Tag present").
        headlines = soup.find_all(head_tag)
        for i, headline in enumerate(headlines, 1):
            print(f"Headline {i}: {headline.get_text(strip=True)}")
    else:
        headlines = soup.find_all(head_tag, class_=head_class)


    if not headlines:
        print(f"No Article Found(Headline)")
        sys.exit(2)  # Indicate no articles found
        return
    else:
        print(f"Found {len(headlines)} headlines with tag '{head_tag}' and class '{head_class}'")
    #print(f"Headlines: {headlines}")
    
   #print(f"Content Tag: {content_tag_elem}")..
    with open(output_file, "w", encoding="utf-8") as out:
        
        for i, headline in enumerate(headlines, 1):
            headline_text = headline.get_text(strip=True)
            if content_class.lower() == "none":
                content_tag_elem = headline.find_all_next(content_tag)
            else:
                content_tag_elem = headline.find_all_next(content_tag, class_=content_class)
            #content_tag_elem = headline.find_next(content_tag, class_=content_class)
            # content_text = content_tag_elem.get_text(strip=True)
            #print(f"[HEAD] {headline_text}")
            #print(f"[CONTENT] {content_tag_elem}")

            if content_tag_elem:
               # content_text = content_tag_elem.get_text(strip=True)
               content_text = "\n".join(elem.get_text(strip=True) for elem in content_tag_elem)

            else:
                print(f"No Article Found")
                sys.exit(2)

            out.write(f"Article {i}\n")
            out.write(f"Headline: {headline_text}\n")
            out.write(f"Content: {content_text}\n\n")
            

    print(f"\n Extracted content saved to '{output_file}'")

    sys.exit(0)  # Successfully found and saved

if __name__ == "__main__":
    if len(sys.argv) != 8:
        print("Usage:")
        print("  python dom_scraper.py <URL> <LOCAL_FILE> <HEAD_TAG> <HEAD_CLASS> <CONTENT_TAG> <CONTENT_CLASS> <OUTPUT_FILE>")
        sys.exit(1)

    url = sys.argv[1]
    local_file = sys.argv[2]
    head_tag = sys.argv[3]
    head_class = sys.argv[4]
    content_tag = sys.argv[5]
    content_class = sys.argv[6]
    output_file = sys.argv[7]

    download_and_extract(url, local_file, head_tag, head_class, content_tag, content_class, output_file)
