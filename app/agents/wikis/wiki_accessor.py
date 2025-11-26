import asyncio
import logging
from urllib.parse import urljoin

import httpx
from bs4 import BeautifulSoup

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


class WikiContent:
    def __init__(self, content: str, url: str):
        self.content = content
        self.url = url


class WikiContents:
    def __init__(self, docs: list[WikiContent]):
        self.docs = docs


class WebAccessor:
    @staticmethod
    async def fetch_page(client: httpx.AsyncClient, page_url: str) -> str | None:
        try:
            response = await client.get(page_url)
            response.raise_for_status()
            return response.text
        except httpx.HTTPStatusError as e:
            logger.error(f"Request failed with status code {e.response.status_code}")
        except Exception as e:
            logger.error(f"Error fetching page {page_url}: {e}")
        return None

    @staticmethod
    async def load_document(client: httpx.AsyncClient, image_base_url: str, page_url: str) -> WikiContent | None:
        html = await WebAccessor.fetch_page(client, page_url)
        if not html:
            return None

        soup = BeautifulSoup(html, "html.parser")

        if image_base_url:
            for img in soup.find_all("img"):
                src = img.get("src")
                if src and not src.startswith("http"):
                    img["src"] = urljoin(image_base_url, src)

        text = str(soup.body) if soup.body else ""

        return WikiContent(content=text, url=page_url)

    @staticmethod
    async def fetch_all_documents(image_base_url: str, urls: list[str]) -> list:
        async with httpx.AsyncClient() as client:
            tasks = [WebAccessor.load_document(client, image_base_url, url) for url in urls]
            return await asyncio.gather(*tasks)
