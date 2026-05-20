import os
import time
import yaml
from tqdm import tqdm
from pathlib import Path
import anthropic

QUESTIONS_FILE = Path(__file__).parent.parent / "LLM_Comparative_Study_Questions_ENG_RUS_HEB.yaml"


def load_questions():
    with open(QUESTIONS_FILE, "r", encoding="utf-8") as f:
        return yaml.safe_load(f)


def run_chats_per_language(client: anthropic.Anthropic, language: str, questions: list, n_chats: int = 58):
    """Run n_chats independent chat sessions for one language."""
    logs = []
    for _ in tqdm(range(n_chats), desc=f"[{language}] chats"):
        chat_log = []
        for q in questions:
            try:
                resp = client.messages.create(
                    model="claude-sonnet-4-20250514",
                    max_tokens=8192,
                    temperature=1,
                    messages=[{"role": "user", "content": q}]
                )
                answer = resp.content[0].text.strip()
            except Exception as e:
                answer = f"ERROR: {e}"
            chat_log.append({"question": q, "answer": answer})
            time.sleep(1.0)
        logs.append(chat_log)
    return logs


def main():
    api_key = os.getenv("ANTHROPIC_API_KEY")
    if not api_key:
        raise RuntimeError("Missing ANTHROPIC_API_KEY environment variable")

    client = anthropic.Anthropic(api_key=api_key)
    questions = load_questions()

    output_file = Path(__file__).parent / "claude_responses_4.yaml"
    all_results = {}
    for lang, qs in questions.items():
        all_results[lang] = run_chats_per_language(client, lang, qs, n_chats=58)
        with open(output_file, "w", encoding="utf-8") as f:
            yaml.dump(all_results, f, allow_unicode=True, sort_keys=False)
        print(f"Saved progress after [{lang}] → {output_file}")

    print(f"Done — results written to {output_file}")


if __name__ == "__main__":
    main()
