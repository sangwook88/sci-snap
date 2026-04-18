import json
from db.db import upsert_conversation, fetch_history, insert_message
from llm.gemini import build_content
from RAG.query import query as rag_query, _get_openai, generate_curiosity_hooks
from object_detection.detector import detect
from object_detection.analyzer import analyze as detect_analyze




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
    body = event.get("body", event)
    if isinstance(body, str):
        body = json.loads(body)

    question        = body.get("question") or ""
    image_urls      = body.get("image_urls") or []
    if isinstance(image_urls, str):
        image_urls = [image_urls] if image_urls else []
    conversation_id = body.get("conversation_id") or None
    user_id         = body.get("user_id") or None
    mode            = body.get("mode") or "default"
    word            = body.get("word") or ""

    # detect/child 모드이거나 question이 없으면 과학 질문 여부 체크 생략
    if question and mode not in ("detect", "child_detect", "child"):
        is_question_resp = get_answer([{"role": "user", "content": f"이 질문이 과학에 관한 질문이야? O / X로 대답해줘\n {question}"}], conversation_id, user_id, image_urls)
        if is_question_resp["statusCode"] != 200:
            return is_question_resp
        is_question = is_question_resp["body"]["answer"]
        if "O" not in is_question:
            return get_answer([{"role": "user", "content": f"이 질문을 과학에 대한 질문으로 유도해줘: {question}\n 예를 들어: 저는 {question}에 대해 말씀드릴 순 없지만 []의 과학에 대해 알려드릴까요?"}], conversation_id, user_id, image_urls)


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
    if not question:
        if image_urls and word:
            question = f"이 사진과 '{word}'를 함께 보고 관련된 과학 개념이나 현상을 설명해주세요."
        elif image_urls:
            question = "이 사진에서 관찰할 수 있는 과학 개념이나 현상을 설명해주세요."
        elif word:
            question = f"'{word}'에 대해 과학적으로 설명해주세요."

    if not question and not image_urls:
        return _response(400, {"error": "Question and image_urls are both empty"})

    conversation_id = upsert_conversation(conversation_id, user_id)
    history = fetch_history(conversation_id)

    # default: 대화 이력 포함해 GPT-4o 직접 호출
    messages = [
        {
            "role": "system",
            "content": (
                "당신은 과학 커뮤니케이터입니다. 전문 지식이 없는 일반인도 쉽게 이해할 수 있도록 답변하세요.\n"
                "규칙:\n"
                "1. 전문 용어는 반드시 쉬운 말로 풀어서 설명하세요.\n"
                "2. 일상생활의 친숙한 사례나 비유를 들어 설명하세요.\n"
                "3. 지나치게 학술적이거나 딱딱한 표현은 피하고, 대화하듯 자연스럽게 써주세요.\n"
                "4. 핵심 내용은 빠짐없이 전달하되 불필요한 세부사항은 생략하세요.\n"
                "5. 항상 한국어로 답변하세요.\n"
                "6. 답변은 Markdown 형식으로 작성하고, 제목·목록·강조 등 Markdown 문법을 적극 활용하세요."
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
