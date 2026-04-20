import json
import logging
from db.db import upsert_conversation, fetch_history, insert_message
from llm.gemini import build_content
from RAG.query import query as rag_query, _get_openai, generate_curiosity_hooks
from object_detection.detector import detect
from object_detection.analyzer import analyze as detect_analyze


logger = logging.getLogger()
logger.setLevel(logging.INFO)




def get_answer(qeury, conversation_id, user_id, image_urls):
    try:
        completion = _get_openai().chat.completions.create(
            model="gpt-4o",
            messages=qeury
        )
        answer = completion.choices[0].message.content
        insert_message(conversation_id, user_id, qeury, image_urls, answer)

        hooks = generate_curiosity_hooks(qeury, image_urls)
        
        return _response(200, {
            "answer": answer,
            "image_urls": [],
            "conversation_id": conversation_id,
            "curiosity_hooks": hooks,
        })
    except Exception as e:
        return _response(500, {"error": str(e)})

def lambda_handler(event, context):
    request_id = getattr(context, "aws_request_id", None)
    logger.info("request_received request_id=%s event=%s", request_id, json.dumps(event, ensure_ascii=False, default=str))

    body = event.get("body", event)
    if isinstance(body, str):
        body = json.loads(body)

    def _clean(v):
        if isinstance(v, str) and v.strip().lower() in ("null", "none", "undefined", ""):
            return None
        return v

    question        = _clean(body.get("question")) or ""
    image_urls      = body.get("image_urls") or []
    if isinstance(image_urls, str):
        image_urls = [image_urls] if image_urls else []
    conversation_id = _clean(body.get("conversation_id"))
    user_id         = _clean(body.get("user_id"))
    mode            = _clean(body.get("mode")) or "default"
    word            = _clean(body.get("word")) or ""

    logger.info(
        "request_parsed request_id=%s mode=%s user_id=%s conversation_id=%s question=%r word=%r image_count=%d",
        request_id, mode, user_id, conversation_id, question, word, len(image_urls),
    )

    # detect / child_detect: 사물 탐지 + 과학 현상 분석
    if mode in ("detect", "child_detect"):
        if not image_urls:
            return _response(400, {"error": "image_urls is required for detect mode"})
        try:
            image_url = image_urls[0]
            objects = detect(image_url)
            result = detect_analyze(image_url, objects, mode=mode)
            if mode == "child_detect":
                print(f"curriculum_refs: {result.get('curriculum_refs', [])}")
            response_body = {"detect": result["detect"]}
            return _response(200, response_body)
        except Exception as e:
            return _response(500, {"error": str(e)})

    # child: 교과서 RAG 파이프라인
    if mode == "child":
        if not question and not image_urls and not word:
            return _response(400, {"error": "question, image_urls, word 중 하나는 필요합니다"})

        conversation_id = upsert_conversation(conversation_id, user_id)
        history = fetch_history(conversation_id)

        try:
            result = rag_query(
                question=question,
                image_urls=image_urls,
                history=history,
                word=word,
            )
            answer = result["answer"]
            insert_message(conversation_id, user_id, question, image_urls, answer)

            print(f"curriculum_refs: {result.get('curriculum_refs', [])}")

            return _response(200, {
                "answer": answer,
                "conversation_id": conversation_id,
                "curiosity_hooks": result.get("curiosity_hooks", []),
            })
        except Exception as e:
            return _response(500, {"error": str(e)})

    # question이 없을 때: 이미지/word 조합으로 자동 질문 구성
    # word 단독: 사용자가 이전 설명에서 선택한 단어 → 심화 탐구 의도
    if not question:
        if image_urls and word:
            words = [w.strip() for w in word.split(",") if w.strip()]
            word_list = ", ".join(f"'{w}'" for w in words)
            question = (
                f"이 사진에서 분석된 단어/개념들({word_list})이 있습니다. "
                f"각 단어마다 이 사진의 상황을 살짝 연결하여 개념을 설명해주세요. "
                f"즉, 사진에 보이는 것과 어떻게 관련되는지 자연스럽게 언급하면서 각 단어의 과학 개념을 설명해주세요."
            )
        elif image_urls:
            question = "이 사진에서 관찰할 수 있는 과학 개념이나 현상을 설명해주세요."
        elif word:
            question = f"사용자가 과학 설명을 읽다가 '{word}'라는 단어를 선택했습니다. 이미 기본 개념을 접한 상태이므로, 이 개념의 더 흥미롭고 신기한 면을 탐구하듯 설명해주세요."
    # question과 word가 함께 있을 때: 질문에 답하면서 선택된 단어들도 연결하여 설명
    elif word:
        words = [w.strip() for w in word.split(",") if w.strip()]
        word_list = ", ".join(f"'{w}'" for w in words)
        question = (
            f"사용자 질문: {question}\n\n"
            f"함께 선택된 단어/개념들: {word_list}\n\n"
            f"위 질문에 먼저 답하되, 선택된 각 단어/개념을 질문의 맥락(사진이 있다면 사진 상황)과 자연스럽게 연결하여 과학적으로 설명해주세요. "
            f"질문에 대한 답과 단어 설명이 하나의 흐름으로 이어지도록 작성해주세요."
        )

    if not question and not image_urls:
        return _response(400, {"error": "Question and image_urls are both empty"})

    conversation_id = upsert_conversation(conversation_id, user_id)
    history = fetch_history(conversation_id)

    # default: 대화 이력 포함해 GPT-4o 직접 호출
    messages = [
        {
            "role": "system",
            "content": (
                "당신은 과학을 알려주는 'SCI-Snap'입니다. 전문 지식이 없는 일반인도 쉽게 이해할 수 있도록 답변하세요.\n"
                "규칙:\n"
                "1. 과학·기술·자연현상·일상 속 원리 등 과학으로 설명 가능한 주제는 자유롭게 답변하세요.\n"
                "2. 자기소개를 묻는 질문(예: '너 누구야', '뭐 하는 앱이야')에는 '저는 과학을 알려주는 SCI-Snap이에요'라고 친근하게 답하세요.\n"
                "3. 과학과 너무 동떨어진 주제(개인 상담, 점성술, 연애 고민 등)는 '저는 과학 이야기에 특화되어 있어요'라고 안내하며 관련된 과학 주제로 부드럽게 유도하세요.\n"
                "4. 전문 용어는 반드시 쉬운 말로 풀어서 설명하고, 일상생활의 친숙한 사례나 비유를 들어 설명하세요.\n"
                "5. 지나치게 학술적이거나 딱딱한 표현은 피하고, 대화하듯 자연스럽게 써주세요.\n"
                "6. 핵심 내용은 빠짐없이 전달하되 불필요한 세부사항은 생략하세요.\n"
                "7. 항상 한국어로 답변하세요.\n"
                "8. 답변은 Markdown 형식으로 작성하고, 제목·목록·강조 등 Markdown 문법을 적극 활용하세요.\n"
                "9. '물론이죠!', '네!', '좋아요!', '알겠습니다' 같은 인사·동의·서두 멘트 없이 곧바로 본문 설명부터 시작하세요."
            ),
        }
    ]
    for turn in history:
        messages.append({"role": "user",      "content": build_content(turn["question"], turn.get("image_urls") or [])})
        messages.append({"role": "assistant", "content": turn["answer"]})
    messages.append({"role": "user", "content": build_content(question, image_urls)})



    return get_answer(messages, conversation_id, user_id, image_urls)
    # try:
    #     completion = _get_openai().chat.completions.create(
    #         model="gpt-4o",
    #         messages=messages
    #     )
    #     answer = completion.choices[0].message.content
    #     insert_message(conversation_id, user_id, question, image_urls, answer)

    #     hooks = generate_curiosity_hooks(question, image_urls)

    #     return _response(200, {
    #         "answer": answer,
    #         "image_urls": [],
    #         "conversation_id": conversation_id,
    #         "curiosity_hooks": hooks,
    #     })
    # except Exception as e:
    #     return _response(500, {"error": str(e)})


def _response(status_code: int, body: dict) -> dict:
    return {
        "statusCode": status_code,
        "headers": {"Content-Type": "application/json"},
        "body": body
    }
