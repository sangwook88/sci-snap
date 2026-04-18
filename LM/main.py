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

    # question(이 질문이 과학에 관한 질문이야? O / X로 대답해줘) -> llm -> if "O" in 대답 : 원래대로 else: 해당 질문을 과학에 대한 질문으로 유도해줘
    is_question = get_answer([{"role": "user", "content": f"이 질문이 과학에 관한 질문이야? O / X로 대답해줘\n {question}"}], conversation_id, user_id, image_urls)["body"]["answer"]

    if "O" in is_question:
        pass
    else:
        return get_answer([{"role": "user", "content": f"이 질문을 과학에 대한 질문으로 유도해줘: {question}"}], conversation_id, user_id, image_urls)


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

    # word만 있고 question이 없으면 word를 질문으로 사용
    if not question and word:
        question = word

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
