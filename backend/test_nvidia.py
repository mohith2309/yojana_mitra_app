import os
import sys

from dotenv import load_dotenv
from openai import OpenAI

load_dotenv()

api_key = os.getenv("NVIDIA_API_KEY", "").strip()
if not api_key:
    raise SystemExit("NVIDIA_API_KEY is not set. Copy .env.example to .env and add your rotated key.")

use_color = sys.stdout.isatty() and os.getenv("NO_COLOR") is None
reasoning_color = "\033[90m" if use_color else ""
reset_color = "\033[0m" if use_color else ""

client = OpenAI(
    base_url=os.getenv("NVIDIA_BASE_URL", "https://integrate.api.nvidia.com/v1"),
    api_key=api_key,
)

prompt = " ".join(sys.argv[1:]).strip() or "Answer in one sentence: what is BharatMitra?"
mode = os.getenv("NVIDIA_TEST_MODE", "consumer")
model = os.getenv("NVIDIA_CONSUMER_MODEL", "google/gemma-3n-e4b-it") if mode == "consumer" else os.getenv("NVIDIA_AUTOTASK_MODEL", "mistralai/mistral-medium-3.5-128b")

completion = client.chat.completions.create(
    model=model,
    messages=[{"role": "user", "content": prompt}],
    temperature=float(os.getenv("NVIDIA_CONSUMER_TEMPERATURE", "0.2") if mode == "consumer" else os.getenv("NVIDIA_TEMPERATURE", "0.7")),
    top_p=float(os.getenv("NVIDIA_CONSUMER_TOP_P", "0.7") if mode == "consumer" else os.getenv("NVIDIA_TOP_P", "1")),
    max_tokens=int(os.getenv("NVIDIA_CONSUMER_MAX_TOKENS", "512") if mode == "consumer" else os.getenv("NVIDIA_MAX_TOKENS", "16384")),
    reasoning_effort=None if mode == "consumer" else os.getenv("NVIDIA_REASONING_EFFORT", "high"),
    extra_body={
        "chat_template_kwargs": {
            "enable_thinking": os.getenv("NVIDIA_ENABLE_THINKING", "true").lower() == "true",
            "clear_thinking": os.getenv("NVIDIA_CLEAR_THINKING", "false").lower() == "true",
        }
    },
    stream=True,
)

for chunk in completion:
    if not getattr(chunk, "choices", None):
        continue
    if len(chunk.choices) == 0 or getattr(chunk.choices[0], "delta", None) is None:
        continue
    delta = chunk.choices[0].delta
    reasoning = getattr(delta, "reasoning_content", None)
    if reasoning:
        print(f"{reasoning_color}{reasoning}{reset_color}", end="")
    if getattr(delta, "content", None) is not None:
        print(delta.content, end="")

print()
