import os
import json
import time
from enum import Enum

from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import StreamingResponse, JSONResponse
from pydantic import BaseModel
from typing import List, Optional, Dict, Any, Union, Literal
import boto3
import httpx
from anthropic import AnthropicBedrock

AWS_ACCESS_KEY_ID = os.getenv("BEDROCK_ACCESS_KEY_ID")
AWS_SECRET_ACCESS_KEY = os.getenv("BEDROCK_SECRET_ACCESS_KEY")

if not AWS_ACCESS_KEY_ID or not AWS_SECRET_ACCESS_KEY:
    raise RuntimeError("Provide env variables BEDROCK_ACCESS_KEY_ID and BEDROCK_SECRET_ACCESS_KEY")

MODEL_ID = "anthropic.claude-3-5-sonnet-20241022-v2:0"
REGION = "us-west-2"

app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


class MessageRole(str, Enum):
    system = "system"
    user = "user"
    assistant = "assistant"


class ChatMessage(BaseModel):
    role: MessageRole
    content: str


class ChatCompletionRequest(BaseModel):
    model: str
    messages: List[ChatMessage]
    temperature: Optional[float] = 1.0
    max_tokens: Optional[int] = None
    stream: Optional[bool] = False



# Create httpx client with proxy
# http://54.150.176.53:809
bedrock_proxy = os.getenv('BEDROCK_PROXY', None)
http_client = httpx.Client(proxy=bedrock_proxy)

client = AnthropicBedrock(
    # Authenticate by either providing the keys below or use the default AWS credential providers, such as
    # using ~/.aws/credentials or the "AWS_SECRET_ACCESS_KEY" and "AWS_ACCESS_KEY_ID" environment variables.
    aws_access_key=AWS_ACCESS_KEY_ID,
    aws_secret_key=AWS_SECRET_ACCESS_KEY,
    # Temporary credentials can be used with aws_session_token.
    # Read more at https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp.html.
    # and if that's not present, we default to us-east-1. Note that we do not read ~/.aws/config for the region.
    aws_region=REGION,
    http_client=http_client,
    )


def extract_messages_and_system(
    messages: List[ChatMessage],
) -> tuple[List[Dict[str, str]], Optional[str]]:
    """Separate system message from other messages"""
    system_message = None
    chat_messages = []

    for msg in messages:
        if msg.role == MessageRole.system:
            system_message = msg.content
        else:
            chat_messages.append({"role": msg.role, "content": msg.content})

    return chat_messages, system_message


async def stream_response(
    messages: List[Dict[str, str]],
    system: Optional[str],
    model: str,
    temperature: Optional[float],
    max_tokens: Optional[int],
):
    """Stream chat completion response in SSE format"""
    yield (
        "data: "
        + json.dumps(
            {
                "id": "chatcmpl-bedrock",
                "object": "chat.completion.chunk",
                "created": int(time.time()),
                "model": model,
                "choices": [
                    {"index": 0, "delta": {"role": "assistant"}, "finish_reason": None}
                ],
            }
        )
        + "\n\n"
    )

    try:
        stream = client.messages.stream(
            messages=messages,
            system=system,
            max_tokens=max_tokens or 1000,
            temperature=temperature,
            model=model,
        )

        async for chunk in stream:
            if chunk.type == "content_block_delta" and chunk.delta.text:
                yield (
                    "data: "
                    + json.dumps(
                        {
                            "id": "chatcmpl-bedrock",
                            "object": "chat.completion.chunk",
                            "created": int(time.time()),
                            "model": model,
                            "choices": [
                                {
                                    "index": 0,
                                    "delta": {"content": chunk.delta.text},
                                    "finish_reason": None,
                                }
                            ],
                        }
                    )
                    + "\n\n"
                )

        yield (
            "data: "
            + json.dumps(
                {
                    "id": "chatcmpl-bedrock",
                    "object": "chat.completion.chunk",
                    "created": int(time.time()),
                    "model": model,
                    "choices": [{"index": 0, "delta": {}, "finish_reason": "stop"}],
                }
            )
            + "\n\n"
        )

        yield "data: [DONE]\n\n"

    except Exception as e:
        yield (
            "data: "
            + json.dumps({"error": {"message": str(e), "type": "internal_error"}})
            + "\n\n"
        )


@app.post("/v1/chat/completions")
async def create_chat_completion(request: ChatCompletionRequest):
    try:
        messages, system = extract_messages_and_system(request.messages)

        if request.stream:
            return StreamingResponse(
                stream_response(
                    messages=messages,
                    system=system,
                    model=MODEL_ID,
                    temperature=request.temperature,
                    max_tokens=request.max_tokens,
                ),
                media_type="text/event-stream",
            )

        response = client.messages.create(
            messages=messages,
            system=system,
            max_tokens=request.max_tokens or 1000,
            temperature=request.temperature,
            model=MODEL_ID,
        )

        # Extract text content only from the first text block
        content = next(
            (block.text for block in response.content if block.type == "text"), ""
        )

        completion_response = {
            "id": "chatcmpl-bedrock",
            "object": "chat.completion",
            "created": int(time.time()),
            "model": request.model,
            "choices": [
                {
                    "index": 0,
                    "message": {"role": "assistant", "content": content},
                    "finish_reason": "stop",
                }
            ],
            "usage": {"prompt_tokens": -1, "completion_tokens": -1, "total_tokens": -1},
        }

        return JSONResponse(content=completion_response, media_type="application/json")

    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


if __name__ == "__main__":
    import uvicorn

    uvicorn.run(app, host="0.0.0.0", port=8000)
