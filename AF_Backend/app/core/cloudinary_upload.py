import cloudinary
import cloudinary.uploader
from app.core.config import settings


def configure_cloudinary():
    cloudinary.config(
        cloud_name=settings.CLOUDINARY_CLOUD_NAME,
        api_key=settings.CLOUDINARY_API_KEY,
        api_secret=settings.CLOUDINARY_API_SECRET,
        secure=True
    )


def upload_image(file_bytes: bytes, folder: str, public_id: str = None) -> str:
    """
    Upload an image to Cloudinary and return the secure URL.
    
    Args:
        file_bytes: Raw bytes of the file to upload.
        folder: Cloudinary folder to upload into (e.g. 'campaigns', 'evidence').
        public_id: Optional custom public ID. Auto-generated if not provided.

    Returns:
        The secure HTTPS URL of the uploaded file.
    """
    configure_cloudinary()
    
    upload_options = {
        "folder": f"ascent_fin/{folder}",
        "resource_type": "auto",
    }
    if public_id:
        upload_options["public_id"] = public_id

    result = cloudinary.uploader.upload(file_bytes, **upload_options)
    return result["secure_url"]
