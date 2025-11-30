from PIL import Image
from PIL.ExifTags import TAGS
from datetime import datetime
import json
import os

class MediaService:
    @staticmethod
    def extract_metadata(file_path: str) -> dict:
        """
        Extracts EXIF metadata from an image file.
        Returns a dictionary of metadata.
        """
        metadata = {}
        try:
            image = Image.open(file_path)
            exif_data = image._getexif()
            
            if exif_data:
                for tag_id, value in exif_data.items():
                    tag_name = TAGS.get(tag_id, tag_id)
                    # Filter out binary data or very long strings
                    if isinstance(value, (bytes, bytearray)) or len(str(value)) > 500:
                        continue
                    metadata[tag_name] = str(value)
                    
            # Add basic file info
            metadata['format'] = image.format
            metadata['size'] = image.size
            metadata['mode'] = image.mode
            
        except Exception as e:
            metadata['error'] = str(e)
            
        return metadata

    @staticmethod
    def verify_evidence(metadata: dict, campaign_start_date: datetime = None) -> bool:
        """
        Verifies evidence based on metadata.
        Simple rules:
        1. Must have some EXIF data (not stripped)
        2. If Date Taken exists, it should be after campaign start (if provided)
        3. Software shouldn't indicate editing tools (basic check)
        """
        if not metadata:
            return False
            
        # Rule 1: Check for software manipulation (Basic)
        software = metadata.get('Software', '').lower()
        suspicious_tools = ['photoshop', 'gimp', 'canva', 'stable diffusion', 'midjourney']
        if any(tool in software for tool in suspicious_tools):
            return False
            
        # Rule 2: Date Check (if DateTimeOriginal is present)
        # format usually: 'YYYY:MM:DD HH:MM:SS'
        date_taken_str = metadata.get('DateTimeOriginal')
        if date_taken_str and campaign_start_date:
            try:
                date_taken = datetime.strptime(date_taken_str, '%Y:%m:%d %H:%M:%S')
                if date_taken < campaign_start_date:
                    return False # Photo taken before campaign started
            except ValueError:
                pass # Ignore parse errors
                
        return True
