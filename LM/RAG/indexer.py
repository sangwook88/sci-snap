"""교과서 PDF 인덱싱: PDF → 텍스트/이미지 추출 → Gemini 캡셔닝 → 청킹 → 임베딩 → Supabase 저장"""

import base64
import json
import os
import sys
from pathlib import Path

import fitz  # PyMuPDF
from openai import OpenAI

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from db.db import _get_supabase

_openai_client = None
_gemini_client = None


def _get_openai():
    global _openai_client
    if _openai_client is None:
        _openai_client = OpenAI(api_key=os.environ["OPENAI_API_KEY"])
    return _openai_client


def _get_gemini():
    global _gemini_client
    if _gemini_client is None:
        _gemini_client = OpenAI(
            api_key=os.environ["GEMINI_API_KEY"],
            base_url=os.environ["GEMINI_BASE_URL"],
        )
    return _gemini_client


# PDF 파싱

def _extract_page_blocks(page: fitz.Page) -> dict:
    """페이지에서 텍스트 블록과 이미지를 좌표와 함께 추출."""
    text_blocks = []
    for b in page.get_text("dict", flags=fitz.TEXT_PRESERVE_WHITESPACE)["blocks"]:
        if b["type"] == 0:
            lines_text = ""
            for line in b["lines"]:
                for span in line["spans"]:
                    lines_text += span["text"]
                lines_text += "\n"
            lines_text = lines_text.strip()
            if lines_text:
                text_blocks.append({"text": lines_text, "bbox": b["bbox"]})

    images = []
    for img_index, img in enumerate(page.get_images(full=True)):
        xref = img[0]
        try:
            img_rect = page.get_image_rects(xref)
            if not img_rect:
                continue
            rect = img_rect[0]
            pix = fitz.Pixmap(page.parent, xref)
            if pix.n > 4:
                pix = fitz.Pixmap(fitz.csRGB, pix)
            img_bytes = pix.tobytes("png")
            if len(img_bytes) < 5000:  # 아이콘 등 소형 이미지 제외
                continue
            images.append({
                "bytes": img_bytes,
                "bbox": (rect.x0, rect.y0, rect.x1, rect.y1),
                "index": img_index,
            })
        except Exception:
            continue

    return {"text_blocks": text_blocks, "images": images}


def _find_nearby_text(text_blocks: list, img_bbox: tuple, threshold: float = 80) -> str:
    """이미지 주변 텍스트 블록 결합 (y좌표 기준 threshold 이내)."""
    img_y0, img_y1 = img_bbox[1], img_bbox[3]
    nearby = []
    for tb in text_blocks:
        tb_y0, tb_y1 = tb["bbox"][1], tb["bbox"][3]
        if tb_y0 <= img_y1 + threshold and tb_y1 >= img_y0 - threshold:
            nearby.append(tb["text"])
    return "\n".join(nearby)


def _fallback_page_as_image(page: fitz.Page) -> bytes:
    """텍스트 파싱 불가 시 페이지 전체를 이미지로 변환."""
    pix = page.get_pixmap(dpi=200)
    return pix.tobytes("png")


# 이미지 캡셔닝

def caption_image(image_bytes: bytes, nearby_text: str = "") -> str:
    """교과서 이미지를 Gemini Vision으로 캡셔닝."""
    b64 = base64.b64encode(image_bytes).decode()
    prompt = f"""이 교과서 이미지를 분석해주세요.
주변 텍스트 맥락: {nearby_text[:500] if nearby_text else '없음'}

다음을 포함해서 설명해주세요:
1. 이미지가 보여주는 과학적 개념
2. 핵심 키워드 5개
3. 관련된 과학 분야 (물리, 화학, 생물, 지구과학)
한국어로 답변해주세요."""

    resp = _get_gemini().chat.completions.create(
        model="gemini-3-flash-preview",
        messages=[{
            "role": "user",
            "content": [
                {"type": "text", "text": prompt},
                {"type": "image_url", "image_url": {"url": f"data:image/png;base64,{b64}"}},
            ],
        }],
        max_tokens=500,
    )
    return resp.choices[0].message.content


def caption_full_page(image_bytes: bytes) -> str:
    """페이지 전체 이미지에서 텍스트·다이어그램·과학 개념 추출."""
    b64 = base64.b64encode(image_bytes).decode()
    prompt = """이 교과서 페이지를 분석해주세요.
1. 페이지의 모든 텍스트 내용을 추출해주세요
2. 다이어그램이나 그림이 있다면 설명해주세요
3. 핵심 과학 개념과 키워드를 나열해주세요
한국어로 답변해주세요."""

    resp = _get_gemini().chat.completions.create(
        model="gemini-3-flash-preview",
        messages=[{
            "role": "user",
            "content": [
                {"type": "text", "text": prompt},
                {"type": "image_url", "image_url": {"url": f"data:image/png;base64,{b64}"}},
            ],
        }],
        max_tokens=1000,
    )
    return resp.choices[0].message.content


# 청킹

def _chunk_text(text: str, max_tokens: int = 500, overlap: int = 100) -> list[str]:
    """텍스트를 오버랩 포함해 청킹 (한국어 기준 1토큰 ≈ 1.5자)."""
    max_chars = int(max_tokens * 1.5)
    overlap_chars = int(overlap * 1.5)

    if len(text) <= max_chars:
        return [text] if text.strip() else []

    chunks = []
    start = 0
    while start < len(text):
        end = start + max_chars
        chunk = text[start:end]
        if chunk.strip():
            chunks.append(chunk.strip())
        start = end - overlap_chars

    return chunks


def _extract_metadata_from_filename(filename: str) -> dict:
    """파일명에서 학년·학기 메타데이터 추출."""
    meta = {"curriculum": "KR", "language": "ko", "source_file": filename}
    name_lower = filename.lower()

    for grade in ("3", "4", "5", "6"):
        if f"{grade}-1" in name_lower or f"{grade}-2" in name_lower:
            meta["grade_level"] = grade
            break

    if "-1" in name_lower:
        meta["semester"] = "1"
    elif "-2" in name_lower:
        meta["semester"] = "2"

    return meta


# 임베딩

def _embed_text(text: str) -> list[float]:
    resp = _get_openai().embeddings.create(
        model="text-embedding-3-large",
        input=text[:8000],
        dimensions=512,
    )
    return resp.data[0].embedding


def _embed_batch(texts: list[str], batch_size: int = 20) -> list[list[float]]:
    all_embeddings = []
    for i in range(0, len(texts), batch_size):
        batch = [t[:8000] for t in texts[i:i + batch_size]]
        resp = _get_openai().embeddings.create(
            model="text-embedding-3-large",
            input=batch,
            dimensions=512,
        )
        all_embeddings.extend([d.embedding for d in resp.data])
    return all_embeddings


# 저장

def _store_chunks(chunks: list[dict]):
    """청크를 임베딩 후 Supabase에 50개씩 배치 저장."""
    sb = _get_supabase()
    if sb is None:
        raise RuntimeError("Supabase client not initialized")

    texts = [c["combined_text"] for c in chunks]
    embeddings = _embed_batch(texts)

    rows = []
    for chunk, emb in zip(chunks, embeddings):
        rows.append({
            "content": chunk["content"],
            "image_caption": chunk.get("image_caption"),
            "embedding": emb,
            "metadata": chunk["metadata"],
        })

    for i in range(0, len(rows), 50):
        batch = rows[i:i + 50]
        sb.table("curriculum_chunks").insert(batch).execute()

    print(f"  → {len(rows)}개 청크 저장 완료")


# 메인 인덱싱 파이프라인

def index_pdf(pdf_path: str):
    """단일 PDF 파일을 인덱싱."""
    pdf_path = Path(pdf_path)
    print(f"\n{'='*60}")
    print(f"인덱싱 시작: {pdf_path.name}")
    print(f"{'='*60}")

    doc = fitz.open(str(pdf_path))
    base_meta = _extract_metadata_from_filename(pdf_path.name)
    all_chunks = []

    for page_num in range(len(doc)):
        page = doc[page_num]
        print(f"  페이지 {page_num + 1}/{len(doc)} 처리 중...")

        blocks = _extract_page_blocks(page)
        page_text_blocks = blocks["text_blocks"]
        page_images = blocks["images"]

        total_text = " ".join(tb["text"] for tb in page_text_blocks)
        if len(total_text.strip()) < 30:
            # 스캔 PDF: 페이지 전체를 이미지로 캡셔닝
            try:
                img_bytes = _fallback_page_as_image(page)
                full_caption = caption_full_page(img_bytes)
                for chunk_text in _chunk_text(full_caption):
                    meta = {**base_meta, "source_page": page_num + 1, "has_image": True}
                    all_chunks.append({
                        "content": chunk_text,
                        "image_caption": full_caption[:500],
                        "combined_text": chunk_text,
                        "metadata": meta,
                    })
            except Exception as e:
                print(f"    ⚠ 페이지 {page_num + 1} 폴백 실패: {e}")
            continue

        for img in page_images:
            nearby = _find_nearby_text(page_text_blocks, img["bbox"])
            try:
                caption = caption_image(img["bytes"], nearby)
                meta = {**base_meta, "source_page": page_num + 1, "has_image": True}
                combined = f"{nearby}\n\n[이미지 설명]: {caption}" if nearby else caption
                all_chunks.append({
                    "content": nearby or caption,
                    "image_caption": caption,
                    "combined_text": combined,
                    "metadata": meta,
                })
            except Exception as e:
                print(f"    ⚠ 이미지 캡셔닝 실패: {e}")

        for chunk_text in _chunk_text(total_text):
            meta = {**base_meta, "source_page": page_num + 1, "has_image": False}
            all_chunks.append({
                "content": chunk_text,
                "combined_text": chunk_text,
                "metadata": meta,
            })

    doc.close()

    if all_chunks:
        print(f"\n총 {len(all_chunks)}개 청크 생성 → 임베딩 및 저장 시작...")
        _store_chunks(all_chunks)
    else:
        print("생성된 청크가 없습니다.")

    print(f"✓ {pdf_path.name} 인덱싱 완료\n")


def index_all_pdfs(directory: str = None):
    """디렉토리 내 모든 PDF를 인덱싱."""
    if directory is None:
        directory = Path(__file__).parent
    else:
        directory = Path(directory)

    pdf_files = sorted(directory.glob("*.pdf"))
    if not pdf_files:
        print(f"PDF 파일을 찾을 수 없습니다: {directory}")
        return

    print(f"{len(pdf_files)}개 PDF 발견:")
    for f in pdf_files:
        print(f"  - {f.name}")

    for pdf_file in pdf_files:
        index_pdf(str(pdf_file))

    print("\n모든 PDF 인덱싱 완료!")


if __name__ == "__main__":
    from dotenv import load_dotenv
    load_dotenv()

    if len(sys.argv) > 1:
        index_pdf(sys.argv[1])
    else:
        index_all_pdfs()
