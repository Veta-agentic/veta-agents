import pytest

from app.agents.images.image_accessor import ImageAccessor


def test_download_image_as_base64_fails_with_redirections() -> None:
    result = ImageAccessor.download_image_as_base64(
        "https://github.com/Azure/CCOInsights/assets/1135473/75838f91-4d8f-44a6-8895-db065559fc5d"
    )
    assert result == ""


def test_download_image_with_redirects_happy_path() -> None:
    ImageAccessor.download_images_with_redirection(
        "https://github.com/Azure/CCOInsights/assets/1135473/75838f91-4d8f-44a6-8895-db065559fc5d"
    )


def test_download_image_as_base64_invalid_url() -> None:
    result = ImageAccessor.download_image_as_base64("https://invalid-url.com/image.jpg")
    assert result == ""


def test_download_image_with_redirects_invalid_url() -> None:
    result = ImageAccessor.download_images_with_redirection("https://invalid-url.com/image.jpg")
    assert result == ""


def test_download_image_as_base64_invalid_mime_type() -> None:
    result = ImageAccessor.download_image_as_base64("https://example.com/file.txt")
    assert result == ""


def test_download_image_with_redirects_too_many_redirects() -> None:
    with pytest.raises(ValueError, match="Too many redirects"):
        ImageAccessor.download_images_with_redirection("https://example.com/redirect", redirect_count=6)
