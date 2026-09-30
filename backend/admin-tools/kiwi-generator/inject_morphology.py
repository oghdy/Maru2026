"""소개(intro) 단계 문장마다 탭 분석용 `chunks` 를 다시 만든다.
사용: python inject_morphology.py <lesson.json>   (파일을 제자리에서 갱신)
batch_merger.py --chunks 에서도 inject_chunks() 를 그대로 쓴다."""
import json
import sys

from generate_morphology import MorphologyGenerator


def _body(step: dict) -> dict:
    return step.get("content") or step.get("contentObj") or {}


def inject_chunks(content: dict, gen: MorphologyGenerator = None) -> int:
    """content = {"steps": [...]}. 바꾼 문장 수를 돌려준다."""
    gen = gen or MorphologyGenerator()
    count = 0
    for step in content.get("steps", []):
        if (step.get("step_type") or step.get("stepType")) != "intro":
            continue
        for s in _body(step).get("sentences", []):
            korean = s.get("korean", "")
            if korean:
                s["chunks"] = [c.model_dump() for c in gen.analyze(korean)]
                count += 1
    return count


if __name__ == "__main__":
    if len(sys.argv) != 2:
        sys.exit("usage: python inject_morphology.py <lesson.json>")
    path = sys.argv[1]
    with open(path, encoding="utf-8") as f:
        data = json.load(f)
    n = inject_chunks(data)
    with open(path, "w", encoding="utf-8") as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
        f.write("\n")
    print(f"Injected chunks into {n} sentences in {path}")
