import os
import time
import yaml
from tqdm import tqdm
from pathlib import Path
from google import genai

QUESTIONS_FILE = Path(__file__).parent.parent / "LLM_Comparative_Study_Questions_ENG_RUS_HEB.yaml"
MODEL_ID = "gemini-2.5-flash"
OUTPUT_FILE = Path(__file__).parent / "gemini_results_2.5flash.yaml"


def load_questions():
    with open(QUESTIONS_FILE, "r", encoding="utf-8") as f:
        return yaml.safe_load(f)


def call_model_with_retry(client, prompt, max_retries=5):
    for attempt in range(max_retries):
        try:
            response = client.models.generate_content(
                model=MODEL_ID,
                contents=prompt,
                config={"temperature": 1, "max_output_tokens": 8192},
            )
            return response.text.strip()
        except Exception as e:
            if "503" in str(e) or "429" in str(e):
                time.sleep((2 ** attempt) + 2)
                continue
            return f"ERROR: {e}"
    return "ERROR: Max retries exceeded (Model Overloaded)"


def run_chats_per_language(client, language, questions, n_chats=58):
    logs = []
    for _ in tqdm(range(n_chats), desc=f"[{language}] chats"):
        chat_log = []
        for q in questions:
            answer = call_model_with_retry(client, q)
            chat_log.append({"question": q, "answer": answer})
            time.sleep(1.0)
        logs.append(chat_log)
    return logs


def main():
    api_key = os.getenv("GOOGLE_API_KEY")
    if not api_key:
        raise RuntimeError("Missing GOOGLE_API_KEY environment variable")

    client = genai.Client(api_key=api_key)
    questions = load_questions()

    all_results = {}
    for lang, qs in questions.items():
        all_results[lang] = run_chats_per_language(client, lang, qs, n_chats=58)
        with open(OUTPUT_FILE, "w", encoding="utf-8") as f:
            yaml.dump(all_results, f, allow_unicode=True, sort_keys=False)
        print(f"Saved progress after [{lang}] → {OUTPUT_FILE}")

    print(f"Done — results written to {OUTPUT_FILE}")


if __name__ == "__main__":
    main()
