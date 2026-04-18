# lambda_handler 로컬 통합 테스트
import json
import os
import sys
from dotenv import load_dotenv

load_dotenv()

from main import lambda_handler

TEST_IMAGE_URL = "https://jakllghtnmkwydeskjee.supabase.co/storage/v1/object/public/images/5._.jpg"


def _point_valid(pt) -> bool:
    return (
        isinstance(pt, list)
        and len(pt) == 2
        and all(isinstance(v, (int, float)) and v >= 0 for v in pt)
    )


# ──────────────────────────── detect / child_detect ────────────────────────────

def test_child_detect_returns_detect():
    """child_detect 모드로 이미지를 넣으면 detect 배열이 반환되는지 확인."""
    event = {"body": {"mode": "child_detect", "image_urls": [TEST_IMAGE_URL]}}
    response = lambda_handler(event, None)
    assert response["statusCode"] == 200, f"status != 200: {response}"
    body = response["body"]
    print("\n[child_detect 응답]")
    print(json.dumps(body, ensure_ascii=False, indent=2))
    detect = body.get("detect", [])
    assert isinstance(detect, list), "detect가 리스트가 아님"
    for item in detect:
        assert isinstance(item, list) and len(item) == 2, f"detect 항목 형식 오류: {item}"
        name, pt = item
        assert isinstance(name, str), f"이름이 문자열이 아님: {name}"
        assert _point_valid(pt), f"유효하지 않은 좌표: {pt}"
    print(f"\n[PASS] child_detect 반환 검증 완료 — detect 항목: {len(detect)}개")


def test_detect_returns_detect():
    """detect 모드(일반)로도 detect 배열이 반환되는지 확인."""
    event = {"body": {"mode": "detect", "image_urls": [TEST_IMAGE_URL]}}
    response = lambda_handler(event, None)
    assert response["statusCode"] == 200, f"status != 200: {response}"
    body = response["body"]
    print("\n[detect 응답]")
    print(json.dumps(body, ensure_ascii=False, indent=2))
    detect = body.get("detect", [])
    assert isinstance(detect, list), "detect가 리스트가 아님"
    for item in detect:
        assert isinstance(item, list) and len(item) == 2, f"detect 항목 형식 오류: {item}"
        name, pt = item
        assert isinstance(name, str), f"이름이 문자열이 아님: {name}"
        assert _point_valid(pt), f"유효하지 않은 좌표: {pt}"
    print(f"\n[PASS] detect 반환 검증 완료 — detect 항목: {len(detect)}개")


def test_detect_missing_image_returns_400():
    """image_urls 없이 detect 모드 호출 시 400 반환 확인."""
    event = {"body": {"mode": "child_detect", "image_urls": []}}
    response = lambda_handler(event, None)
    assert response["statusCode"] == 400, f"400이어야 하는데: {response}"
    print("\n[PASS] detect 모드에서 image_urls 없을 때 400 반환 확인")


# ──────────────────────────── default 모드 ────────────────────────────

def test_default_mode_with_question():
    """default 모드 — 텍스트 질문만 보내면 answer가 반환되는지 확인."""
    event = {
        "body": {
            "mode": "default",
            "question": "빛이 왜 직진하나요?",
        }
    }
    response = lambda_handler(event, None)
    assert response["statusCode"] == 200, f"status != 200: {response}"
    body = response["body"]
    print("\n[default 텍스트 응답]")
    print(json.dumps(body, ensure_ascii=False, indent=2))
    assert "answer" in body, "answer 키가 없음"
    assert isinstance(body["answer"], str) and body["answer"], "answer가 비어있음"
    assert "conversation_id" in body, "conversation_id 키가 없음"
    print("\n[PASS] default 모드 텍스트 응답 확인")


def test_default_mode_with_image_and_question():
    """default 모드 — 이미지 + 질문 조합으로 answer가 반환되는지 확인."""
    event = {
        "body": {
            "mode": "default",
            "question": "이 사진에서 무엇이 보이나요?",
            "image_urls": [TEST_IMAGE_URL],
        }
    }
    response = lambda_handler(event, None)
    assert response["statusCode"] == 200, f"status != 200: {response}"
    body = response["body"]
    print("\n[default 이미지+질문 응답]")
    print(json.dumps(body, ensure_ascii=False, indent=2))
    assert "answer" in body and body["answer"], "answer가 비어있음"
    print("\n[PASS] default 모드 이미지+질문 응답 확인")


def test_default_mode_missing_inputs_returns_400():
    """default 모드에서 question·image_urls 모두 없으면 400 반환 확인."""
    event = {"body": {"mode": "default"}}
    response = lambda_handler(event, None)
    assert response["statusCode"] == 400, f"400이어야 하는데: {response}"
    print("\n[PASS] default 모드 입력 없을 때 400 반환 확인")


# ──────────────────────────── child 모드 (RAG) ────────────────────────────

def test_child_mode_with_question():
    """child 모드 — 텍스트 질문으로 RAG 파이프라인이 동작하는지 확인."""
    event = {
        "body": {
            "mode": "child",
            "question": "왜 하늘은 파란색인가요?",
        }
    }
    response = lambda_handler(event, None)
    assert response["statusCode"] == 200, f"status != 200: {response}"
    body = response["body"]
    print("\n[child 질문 응답]")
    print(json.dumps(body, ensure_ascii=False, indent=2))
    assert "answer" in body and body["answer"], "answer가 비어있음"
    assert "conversation_id" in body, "conversation_id 키가 없음"
    assert "curiosity_hooks" in body, "curiosity_hooks 키가 없음"
    assert isinstance(body["curiosity_hooks"], list), "curiosity_hooks가 리스트가 아님"
    print("\n[PASS] child 모드 질문 응답 확인")


def test_child_mode_with_word():
    """child 모드 — word 파라미터로 특정 개념을 설명하는지 확인."""
    event = {
        "body": {
            "mode": "child",
            "word": "광합성",
        }
    }
    response = lambda_handler(event, None)
    assert response["statusCode"] == 200, f"status != 200: {response}"
    body = response["body"]
    print("\n[child word 응답]")
    print(json.dumps(body, ensure_ascii=False, indent=2))
    assert "answer" in body and body["answer"], "answer가 비어있음"
    print("\n[PASS] child 모드 word 응답 확인")


def test_child_mode_with_image():
    """child 모드 — 이미지로 RAG 파이프라인이 동작하는지 확인."""
    event = {
        "body": {
            "mode": "child",
            "image_urls": [TEST_IMAGE_URL],
        }
    }
    response = lambda_handler(event, None)
    assert response["statusCode"] == 200, f"status != 200: {response}"
    body = response["body"]
    print("\n[child 이미지 응답]")
    print(json.dumps(body, ensure_ascii=False, indent=2))
    assert "answer" in body and body["answer"], "answer가 비어있음"
    print("\n[PASS] child 모드 이미지 응답 확인")


def test_child_mode_missing_inputs_returns_400():
    """child 모드에서 question·image_urls·word 모두 없으면 400 반환 확인."""
    event = {"body": {"mode": "child"}}
    response = lambda_handler(event, None)
    assert response["statusCode"] == 400, f"400이어야 하는데: {response}"
    print("\n[PASS] child 모드 입력 없을 때 400 반환 확인")


# ──────────────────────────── 진입점 ────────────────────────────

if __name__ == "__main__":
    event = {"body": {"mode": "child_detect", "image_urls": [TEST_IMAGE_URL], "question":"안녕"}}
    print(lambda_handler(event, None)["body"]["answer"])