import requests
import io
from PyPDF2 import PdfReader

import asyncio

async def extract_cv_text_locally(cv_url: str) -> str:
    """
    Downloads the PDF from the given URL (including Google Drive links) 
    and extracts all text from it.
    """
    try:
        # 1. Convert Google Drive share link to a Direct Download link
        if "drive.google.com" in cv_url and "/d/" in cv_url:
            file_id = cv_url.split("/d/")[1].split("/")[0]
            download_url = f"https://drive.google.com/uc?export=download&id={file_id}"
        else:
            download_url = cv_url

        # 2. Download the PDF file asynchronously (non-blocking)
        print(f"Downloading CV from: {download_url}")
        response = await asyncio.to_thread(requests.get, download_url, timeout=15)
        
        if response.status_code != 200:
            return f"Error: Unable to download CV. Status code {response.status_code}"

        # 3. Read the PDF content from memory
        pdf_file = io.BytesIO(response.content)
        reader = PdfReader(pdf_file)
        
        # 4. Extract text and embedded links from all pages
        extracted_text = ""
        urls = []
        for page in reader.pages:
            text = page.extract_text()
            if text:
                extracted_text += text + "\n"
                
            # Extract hyperlinks from PDF annotations
            if "/Annots" in page:
                for annot in page["/Annots"]:
                    obj = annot.get_object()
                    if "/A" in obj and "/URI" in obj["/A"]:
                        urls.append(obj["/A"]["/URI"])
                        
        if urls:
            extracted_text += "\n\n--- Embedded Links ---\n"
            extracted_text += "\n".join(urls)
                
        if not extracted_text.strip():
            return "Warning: Downloaded PDF was empty or contained only images."
            
        return extracted_text

    except Exception as e:
        return f"Error extracting CV: {str(e)}"