import os
import time
import yaml
from tqdm import tqdm
from pathlib import Path
import openai

# 1. Set your API key (or export OPENAI_API_KEY in your environment)
# Pull from environment, or raise an error if it isn't set
openai.api_key = os.getenv("OPENAI_API_KEY")
if not openai.api_key:
    raise RuntimeError("Missing OPENAI_API_KEY environment variable")

QUESTIONS_FILE = Path(__file__).parent.parent / "LLM_Comparative_Study_Questions_ENG_RUS_HEB.yaml"

def load_questions():
    with open(QUESTIONS_FILE, "r", encoding="utf-8") as f:
        return yaml.safe_load(f)

QUESTIONS = load_questions()

def run_chats_per_language(language: str, questions: list, n_chats: int = 1):
    """Run n_chats independent ChatCompletion sessions for one language."""
    logs = []
    for _ in tqdm(range(n_chats), desc=f"[{language}] chats"):
        chat_log = []
        for q in questions:
            try:
                resp = openai.chat.completions.create(
                    model="gpt-4o",
                    messages=[
                        {"role": "system", "content": "You are a helpful assistant."},
                        {"role": "user",   "content": q}
                    ],
                    temperature=1,
                    max_tokens=8192
                )
                answer = resp.choices[0].message.content.strip()
            except Exception as e:
                answer = f"ERROR: {e}"
            chat_log.append({"question": q, "answer": answer})
            time.sleep(1.0)  # simple rate-limit throttle
        logs.append(chat_log)
    return logs

def main():
    all_results = {}
    for lang, qs in QUESTIONS.items():
        all_results[lang] = run_chats_per_language(lang, qs, n_chats=58)

    # 3. Dump to YAML (keeping Unicode for Hebrew)
    with open("chat_results_4o.yaml", "w", encoding="utf-8") as f:
        yaml.dump(all_results, f, allow_unicode=True, sort_keys=False)

    print("✅ Done — results written to chat_results_4o.yaml")

if __name__ == "__main__":
    main()
