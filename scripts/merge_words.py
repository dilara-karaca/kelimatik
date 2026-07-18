# -*- coding: utf-8 -*-
"""Merge user word list into assets/data/words.json with filters."""
from __future__ import annotations

import json
import unicodedata
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
EXISTING_PATH = ROOT / "assets" / "data" / "words.json"
USER_PATH = ROOT / "assets" / "data" / "_user_words.json"
OUT_PATH = EXISTING_PATH

TR_ASCII = str.maketrans(
    {
        "ç": "c",
        "Ç": "C",
        "ğ": "g",
        "Ğ": "G",
        "ı": "i",
        "İ": "I",
        "ö": "o",
        "Ö": "O",
        "ş": "s",
        "Ş": "S",
        "ü": "u",
        "Ü": "U",
        "â": "a",
        "Â": "A",
        "î": "i",
        "Î": "I",
        "û": "u",
        "Û": "U",
    }
)

CIRC = str.maketrans(
    {
        "â": "a",
        "Â": "A",
        "î": "i",
        "Î": "I",
        "û": "u",
        "Û": "U",
    }
)

# Ünlü düşmesi / daralma / ünsüz / bitişik-ayrı ekleri
EXTRAS = [
    ("burnu", "burunu"),
    ("ağzı", "ağızı"),
    ("omzu", "omuzu"),
    ("oğlu", "oğulu"),
    ("şehri", "şehiri"),
    ("fikri", "fikiri"),
    ("gelmiyor", "gelmeyor"),
    ("sevmiyor", "sevmeyor"),
    ("etmiyor", "etmeyor"),
    ("gitmiyor", "gitmeyor"),
    ("diyor", "deyor"),
    ("yiyor", "yeyor"),
    ("söylüyor", "söyleyor"),
    ("hallolmak", "halolmak"),
    ("ağaçtan", "ağaçdan"),
    ("kitaptan", "kitabdan"),
    ("çokça", "çokca"),
    ("yavaşça", "yavaşca"),
    ("açıkça", "açıkca"),
    ("usulca", "usulça"),
    ("renkler", "rengler"),
    ("dolaplar", "dolablar"),
    ("sebep", "sebeb"),
    ("meşgul", "meşğul"),
    ("hâlbuki", "halbuki"),
    ("lâkin", "lakin"),
    ("imkân", "imkan"),
    ("küçücük", "küçüçük"),
    ("birbiri", "bir biri"),
    ("dışbükey", "dış bükey"),
    ("içbükey", "iç bükey"),
]


def nfc(s: str) -> str:
    return unicodedata.normalize("NFC", s).strip()


def low(s: str) -> str:
    return nfc(s).casefold()


def asciiize(s: str) -> str:
    return low(s).translate(TR_ASCII)


def is_ascii_only(s: str) -> bool:
    return all(ord(ch) < 128 for ch in s)


def is_circumflex_pair(correct: str, wrong: str) -> bool:
    c, w = low(correct), low(wrong)
    return c.translate(CIRC) == w or w.translate(CIRC) == c


def is_spacing_or_compound_pair(correct: str, wrong: str) -> bool:
    c = asciiize(correct).replace(" ", "")
    w = asciiize(wrong).replace(" ", "")
    return c == w and (" " in correct or " " in wrong)


def is_vowel_ascii_strip(correct: str, wrong: str) -> bool:
    """yüzük/yuzuk: yanlış biçim salt ASCII = doğrunun asciiize hali."""
    c, w = nfc(correct), nfc(wrong)
    if is_circumflex_pair(c, w):
        return False
    if is_spacing_or_compound_pair(c, w):
        return False
    wn = low(w)
    return is_ascii_only(wn) and asciiize(c) == wn


def should_exclude(correct: str, wrong: str) -> str | None:
    c, w = nfc(correct), nfc(wrong)
    if low(c) == low(w):
        return "identical"
    if is_circumflex_pair(c, w):
        return None
    if is_spacing_or_compound_pair(c, w):
        return None
    if is_vowel_ascii_strip(c, w):
        return "ascii_vowel_strip"
    return None


def pair_key(correct: str, wrong: str) -> tuple[str, str]:
    return (low(correct), low(wrong))


def main() -> None:
    existing = json.loads(EXISTING_PATH.read_text(encoding="utf-8"))
    user = json.loads(USER_PATH.read_text(encoding="utf-8"))

    merged: list[dict] = []
    seen: set[tuple[str, str]] = set()
    excluded_user: list[tuple[str, str, str]] = []
    added_from_user = 0
    added_extras = 0

    def try_add(correct: str, wrong: str, source: str) -> bool:
        nonlocal added_from_user, added_extras
        reason = should_exclude(correct, wrong)
        if reason:
            if source == "user":
                excluded_user.append((correct, wrong, reason))
            return False
        key = pair_key(correct, wrong)
        rev = pair_key(wrong, correct)
        if key in seen or rev in seen:
            return False
        seen.add(key)
        merged.append({"correct": nfc(correct), "wrong": nfc(wrong)})
        if source == "user":
            added_from_user += 1
        elif source == "extra":
            added_extras += 1
        return True

    for item in existing:
        try_add(item["correct"], item["wrong"], "existing")

    for item in user:
        try_add(item["correct"], item["wrong"], "user")

    for c, w in EXTRAS:
        try_add(c, w, "extra")

    out = [
        {"id": i, "correct": row["correct"], "wrong": row["wrong"]}
        for i, row in enumerate(merged, start=1)
    ]

    OUT_PATH.write_text(
        json.dumps(out, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )

    ids = [x["id"] for x in out]
    assert ids == list(range(1, len(out) + 1)), "ID sequence broken"
    assert all(x["correct"] != x["wrong"] for x in out)
    assert not any(should_exclude(x["correct"], x["wrong"]) for x in out)

    print(f"existing_in={len(existing)}")
    print(f"user_in={len(user)}")
    print(f"added_from_user={added_from_user}")
    print(f"excluded_user={len(excluded_user)}")
    print(f"added_extras={added_extras}")
    print(f"final={len(out)}")
    print("excluded_samples:")
    for row in excluded_user[:40]:
        print(f"  {row}")
    print("id_check_ok", ids[0], "...", ids[-1], "count", len(ids))


if __name__ == "__main__":
    main()
