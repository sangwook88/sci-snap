import base64
import mimetypes
import os
from openai import OpenAI

client = OpenAI(
    api_key=os.environ["GEMINI_API_KEY"],
    base_url=os.environ["GEMINI_BASE_URL"],
)


def _to_url(image_url: str) -> str:
    """로컬 파일이면 base64 data URL로 변환."""
    if image_url.startswith(("http://", "https://", "gs://", "data:")):
        return image_url
    if os.path.isfile(image_url):
        mime, _ = mimetypes.guess_type(image_url)
        mime = mime or "image/jpeg"
        with open(image_url, "rb") as f:
            encoded = base64.b64encode(f.read()).decode()
        return f"data:{mime};base64,{encoded}"
    return image_url


def build_content(question: str, image_urls: list):
    """텍스트+이미지를 OpenAI content 형식으로 변환."""
    if image_urls:
        content = [{"type": "image_url", "image_url": {"url": _to_url(url)}} for url in image_urls]
        if question:
            content.append({"type": "text", "text": question})
        return content
    return question
