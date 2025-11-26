from unittest.mock import AsyncMock, patch

import httpx
import pytest

from app.agents.wikis.wiki_accessor import WebAccessor, WikiContent


@pytest.mark.asyncio
async def test_fetch_page_success() -> None:
    url = "http://example.com"
    mock_response = AsyncMock()
    mock_response.text = "<html><body>Test</body></html>"
    mock_response.raise_for_status = AsyncMock()

    with patch("httpx.AsyncClient.get", return_value=mock_response):
        async with httpx.AsyncClient() as client:
            result = await WebAccessor.fetch_page(client, url)
            assert result == "<html><body>Test</body></html>"


@pytest.mark.asyncio
async def test_fetch_page_http_error() -> None:
    url = "http://example.com"
    mock_response = AsyncMock()
    mock_response.raise_for_status = AsyncMock(
        side_effect=httpx.HTTPStatusError("Error", request=None, response=mock_response)
    )
    mock_response.status_code = 404

    with patch("httpx.AsyncClient.get", return_value=mock_response):
        async with httpx.AsyncClient() as client:
            result = await WebAccessor.fetch_page(client, url)
            assert result is not None


@pytest.mark.asyncio
async def test_load_document_success() -> None:
    url = "http://example.com"
    image_base_url = "http://example.com/images/"
    html_content = '<html><body><img src="/image.png"></body></html>'

    mock_response = AsyncMock()
    mock_response.text = html_content
    mock_response.raise_for_status = AsyncMock()

    with patch("httpx.AsyncClient.get", return_value=mock_response):
        async with httpx.AsyncClient() as client:
            result = await WebAccessor.load_document(client, image_base_url, url)
            assert isinstance(result, WikiContent)
            assert result.url == url


@pytest.mark.asyncio
async def test_load_document_no_body() -> None:
    url = "http://example.com"
    image_base_url = "http://example.com/images/"
    html_content = "<html></html>"

    mock_response = AsyncMock()
    mock_response.text = html_content
    mock_response.raise_for_status = AsyncMock()

    with patch("httpx.AsyncClient.get", return_value=mock_response):
        async with httpx.AsyncClient() as client:
            result = await WebAccessor.load_document(client, image_base_url, url)
            assert result is not None
            assert result.content == ""
            assert result.url == url


@pytest.mark.asyncio
async def test_fetch_all_documents() -> None:
    urls = ["http://example.com/page1", "http://example.com/page2"]
    image_base_url = "http://example.com/images/"
    html_content = "<html><body>Test</body></html>"

    mock_response = AsyncMock()
    mock_response.text = html_content
    mock_response.raise_for_status = AsyncMock()

    with patch("httpx.AsyncClient.get", return_value=mock_response):
        async with httpx.AsyncClient():
            results = await WebAccessor.fetch_all_documents(image_base_url, urls)
            assert len(results) == 2
            for result, url in zip(results, urls):
                assert isinstance(result, WikiContent)
                assert result.content == "<body>Test</body>"
                assert result.url == url
