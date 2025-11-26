import base64
import logging
from io import BytesIO

import requests
from PIL import Image


class ImageAccessor:
    @staticmethod
    def download_image_as_base64(url: str) -> str:
        valid_mime_types = [
            "image/jpeg",
            "image/png",
            "image/gif",
            "image/bmp",
            "image/webp",
        ]
        try:
            response = requests.get(url, allow_redirects=False)
            response.raise_for_status()
            if response.status_code != 200:
                raise ValueError("Failed to download image from URL.")
            content_type = response.headers["Content-Type"]
            if content_type not in valid_mime_types:
                raise ValueError(f"Invalid MIME type: {content_type}")
            image = Image.open(BytesIO(response.content))
            buffered = BytesIO()
            image.save(buffered, format=image.format)
            return (
                f"data:image/{content_type.split('/')[1]};base64,"
                f"{base64.b64encode(buffered.getvalue()).decode('utf-8')}"
            )
        except Exception:
            logging.error("Error downloading image from URL: %s", url)
            return ""

    @staticmethod
    def download_images_with_redirection(url: str, redirect_count: int = 0) -> str:
        if redirect_count > 5:
            raise ValueError("Too many redirects")
        try:
            response = requests.get(url, allow_redirects=False)
            if response.status_code == 302:
                new_url = response.headers["Location"]
                return ImageAccessor.download_images_with_redirection(new_url, redirect_count + 1)
            if response.status_code == 200:
                return ImageAccessor.download_image_as_base64(url)
            raise ValueError("Failed to download image from URL.")
        except Exception:
            logging.error("Error downloading image from URL: %s", url)
            return ""
