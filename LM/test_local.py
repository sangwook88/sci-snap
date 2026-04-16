# lambda_handler 로컬 통합 테스트
import json
import os
import sys
from dotenv import load_dotenv

load_dotenv()

from main import lambda_handler


def _print_result(label: str, result: dict):
    print(f"\n{'='*60}")
    print(f"  {label}")
    print(f"{'='*60}")
    print(json.dumps(result, ensure_ascii=False, indent=2))


# ── 인덱서 테스트 ──────────────────────────────────────────────

def test_indexer():
    """RAG/indexer.py: RAG 폴더의 PDF 전체 인덱싱"""
    print("\n" + "="*60)
    print("  [INDEXER] PDF 인덱싱 시작 (시간이 오래 걸릴 수 있습니다)")
    print("="*60)
    from RAG.indexer import index_all_pdfs
    index_all_pdfs()
    print("\n[INDEXER] 완료")


# ── child 모드 (RAG) 테스트 ────────────────────────────────────

def test_child_text_only():
    """텍스트 질문만으로 RAG 검색"""
    result = lambda_handler(
        {
            "body": json.dumps({
                "question": "식물은 어떻게 햇빛으로 음식을 만들어요?",
                "mode": "child",
            })
        },
        {},
    )
    _print_result("[CHILD] 텍스트 질문", result)
    return result


def test_child_with_image():
    """이미지 + 텍스트로 RAG 검색"""
    result = lambda_handler(
        {
            "body": json.dumps({
                "question": "이 사진에서 어떤 과학을 배울 수 있어요?",
                "image_urls": [
                    "https://jakllghtnmkwydeskjee.supabase.co/storage/v1/object/public/images/6._.jpg"
                ],
                "mode": "child",
            })
        },
        {},
    )
    _print_result("[CHILD] 이미지 + 질문", result)
    return result


def test_child_followup():
    """child 모드 꼬리 질문 (conversation_id 연결)"""
    # 첫 번째 대화
    result1 = lambda_handler(
        {
            "body": json.dumps({
                "question": "물은 왜 100도에서 끓어요?",
                "mode": "child",
            })
        },
        {},
    )
    _print_result("[CHILD] 첫 질문", result1)

    conversation_id = result1.get("body", {}).get("conversation_id")
    if not conversation_id:
        print("  ⚠ conversation_id 없음 - 꼬리 질문 건너뜀")
        return

    # 꼬리 질문
    result2 = lambda_handler(
        {
            "body": json.dumps({
                "question": "그럼 높은 산에서는 온도가 다른가요?",
                "conversation_id": conversation_id,
                "mode": "child",
            })
        },
        {},
    )
    _print_result("[CHILD] 꼬리 질문", result2)


# ── 기본 모드 테스트 ───────────────────────────────────────────

def test_default_text():
    """기본 대화 모드 텍스트 질문"""
    result = lambda_handler(
        {
            "body": json.dumps({
                "question": "파이썬과 자바스크립트의 차이점은 뭔가요?",
            })
        },
        {},
    )
    _print_result("[DEFAULT] 텍스트 질문", result)


def test_default_followup():
    """기본 모드 꼬리 질문"""
    result1 = lambda_handler(
        {
            "body": json.dumps({
                "question": "리스트와 튜플의 차이를 알려줘",
            })
        },
        {},
    )
    _print_result("[DEFAULT] 첫 질문", result1)

    conversation_id = result1.get("body", {}).get("conversation_id")
    if not conversation_id:
        print("  ⚠ conversation_id 없음 - 꼬리 질문 건너뜀")
        return

    result2 = lambda_handler(
        {
            "body": json.dumps({
                "question": "어떤 걸 쓰는 게 더 좋아요?",
                "conversation_id": conversation_id,
            })
        },
        {},
    )
    _print_result("[DEFAULT] 꼬리 질문", result2)


def test_error_case():
    """에러 케이스: question, image_urls 모두 없음"""
    result = lambda_handler(
        {
            "body": json.dumps({
                "conversation_id": "00000000-0000-0000-0000-000000000000",
            })
        },
        {},
    )
    _print_result("[ERROR] 질문·이미지 없음 (400 기대)", result)


# ── 실행 ───────────────────────────────────────────────────────

if __name__ == "__main__":
    mode = sys.argv[1] if len(sys.argv) > 1 else "all"

    if mode == "indexer":
        test_indexer()

    elif mode == "child":
        test_child_text_only()
        test_child_with_image()
        test_child_followup()

    elif mode == "default":
        test_default_text()
        test_default_followup()
        test_error_case()

    else:  # all
        test_child_text_only()
        test_child_with_image()
        test_default_text()
        test_error_case()
