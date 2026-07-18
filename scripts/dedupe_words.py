# -*- coding: utf-8 -*-
import json
import unicodedata
from pathlib import Path

p = Path("assets/data/words.json")
data = json.loads(p.read_text(encoding="utf-8"))


def key(s: str) -> str:
    return unicodedata.normalize("NFC", s).casefold().strip()


seen: set[str] = set()
deduped: list[dict] = []
removed: list[dict] = []

for item in data:
    k = key(item["correct"])
    if k in seen:
        removed.append(item)
        continue
    seen.add(k)
    deduped.append(
        {
            "correct": unicodedata.normalize("NFC", item["correct"].strip()),
            "wrong": unicodedata.normalize("NFC", item["wrong"].strip()),
        }
    )

clean: list[dict] = []
for item in deduped:
    if key(item["correct"]) == key(item["wrong"]):
        removed.append(item)
        continue
    clean.append(item)

out = [
    {"id": i, "correct": row["correct"], "wrong": row["wrong"]}
    for i, row in enumerate(clean, start=1)
]

p.write_text(json.dumps(out, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")

ids = [x["id"] for x in out]
assert ids == list(range(1, len(out) + 1))
assert len({key(x["correct"]) for x in out}) == len(out)

print(f"before={len(data)} after={len(out)} removed={len(removed)}")
print("removed:")
for r in removed:
    print(f"  id={r.get('id')} correct={r['correct']!r} wrong={r['wrong']!r}")
print(f"id_range={out[0]['id']}..{out[-1]['id']}")
