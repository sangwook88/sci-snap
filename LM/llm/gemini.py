import os
from openai import OpenAI

client = OpenAI(
    api_key=os.environ["GEMINI_API_KEY"],
    base_url=os.environ["GEMINI_BASE_URL"],
)


def build_content(question: str, image_urls: list):
    """Gemini content 형식으로 변환."""
    if image_urls:
        content = [{"type": "image_url", "image_url": {"url": url}} for url in image_urls]
        if question:
            content.append({"type": "text", "text": question})
        return content
    return question
