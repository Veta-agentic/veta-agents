
from semantic_kernel.functions import kernel_function

from app.agents.wikis.wiki_accessor import WebAccessor, WikiContents


class WikiPlugin:
    PLUGIN_NAME = "WikiSearch"
    DESCRIPTION = "A plugin that allows you to search for content in a wiki."

    def __init__(self, wiki_urls: list[str] | None = None, base_url_images: str | None = None):
        self.urls = wiki_urls or []
        self.base_url_images = base_url_images

    @kernel_function(
        name="get_wiki_content",
        description="Gets the documentation from a github wiki pages",
    )
    async def get_content(self) -> WikiContents:
        docs = await WebAccessor.fetch_all_documents(self.base_url_images, self.urls)
        return WikiContents(docs)
