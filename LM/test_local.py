# lambda_handler 로컬 통합 테스트
import json
import os
import sys
from dotenv import load_dotenv

load_dotenv()

from main import lambda_handler

# 테스트에 사용할 공개 이미지 URL (자동차와 사람이 있는 야외 사진)
TEST_IMAGE_URL = "https://jakllghtnmkwydeskjee.supabase.co/storage/v1/object/public/images/5._.jpg"


def _point_valid(pt) -> bool:
    """pt가 [x, y] 형태이고 좌표가 0 이상 정수인지 확인."""
    return (
        isinstance(pt, list)
        and len(pt) == 2
        and all(isinstance(v, (int, float)) and v >= 0 for v in pt)
    )


def test_child_detect_returns_detect():
    """child_detect 모드로 이미지를 넣으면 detect 배열이 반환되는지 확인."""
    event = {
        "body": {
            "mode": "child_detect",
            "image_urls": [TEST_IMAGE_URL],
        }
    }

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

    print("\n[PASS] child_detect 반환 검증 완료")
    print(f"  detect 항목: {len(detect)}개")


def test_detect_returns_detect():
    """detect 모드(일반)로도 동일하게 detect 배열이 반환되는지 확인."""
    event = {
        "body": {
            "mode": "detect",
            "image_urls": [TEST_IMAGE_URL],
        }
    }

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

    print("\n[PASS] detect 반환 검증 완료")
    print(f"  detect 항목: {len(detect)}개")


def test_missing_image_returns_400():
    """image_urls 없이 detect 모드 호출 시 400 반환 확인."""
    event = {"body": {"mode": "child_detect", "image_urls": []}}
    response = lambda_handler(event, None)
    assert response["statusCode"] == 400, f"400이어야 하는데: {response}"
    print("\n[PASS] image_urls 없을 때 400 반환 확인")


if __name__ == "__main__":
    print("=" * 60)
    print("detect / child_detect 좌표 반환 테스트")
    print("=" * 60)

    #test_missing_image_returns_400()
    test_detect_returns_detect()
    test_child_detect_returns_detect()

    print("\n모든 테스트 통과")
