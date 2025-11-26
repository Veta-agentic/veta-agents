from semantic_kernel.functions import kernel_function

from app.agents.images.image_accessor import ImageAccessor


class ImageDownloaded:
    def __init__(self, url: str, base64string: str):
        self.url = url
        self.base64string = base64string


class ImagesPlugin:
    PLUGIN_NAME = "ImagesPlugin"
    DESCRIPTION = "A plugin that downloads images and returns the base64 contents from the images."

    @kernel_function(
        name="download_images_in_base64",
        description="""Given a list of images,
           download the images and returns the an object with the url,
           and base64 content processed fields.""",
    )
    def download_images(self, urls: list[str]) -> list[ImageDownloaded]:
        """
        Given a list of images, download the images and returns the an object with the url, and base64 content fields.
        """
        results = []
        for url in urls:
            base64string = ImageAccessor.download_images_with_redirection(url)
            if base64string:
                results.append(ImageDownloaded(url, base64string))
        return results
