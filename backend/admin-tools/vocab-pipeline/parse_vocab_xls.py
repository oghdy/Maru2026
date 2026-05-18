"""
parse_vocab_xls.py
Task 22-2: 국립국어원 '한국어 학습용 어휘 목록.xls' 파서

역할:
- XLS 파일을 pandas로 읽어 각 행을 VocabEntry DTO로 변환
- 이형어 번호 제거, 품사 코드 변환, 등급 변환 처리
- 후속 파이프라인(Gemini 번역, DB 적재)의 입력 데이터 공급
"""
import re
import math
from dataclasses import dataclass, field
from typing import Optional
import pandas as pd


# ─────────────────────────────────────────────
# DTO: 파서 출력 데이터 모델
# ─────────────────────────────────────────────
@dataclass
class VocabEntry:
    korean_word: str       # 정규화된 한국어 단어
    part_of_speech: str    # "Noun" / "Verb" / "Adjective" / "Adverb" / "Other"
    hanja_hint: str        # 한자 풀이 (없으면 "")
    level: str             # "Beginner" / "Intermediate" / "Advanced" / "Unknown"


# ─────────────────────────────────────────────
# 순수 변환 함수 (Unit Test 가능한 단위)
# ─────────────────────────────────────────────
_POS_MAP = {
    "명": "Noun",
    "동": "Verb",
    "형": "Adjective",
    "부": "Adverb",
}

_LEVEL_MAP = {
    "A": "Beginner",
    "B": "Intermediate",
    "C": "Advanced",
}


def normalize_word(raw: str) -> str:
    """
    이형어 번호 제거 및 공백 정리.
    예: '가구03' → '가구', '  가게  ' → '가게'
    """
    if not isinstance(raw, str):
        return ""
    # 단어 끝의 숫자(두 자리까지) 제거
    normalized = re.sub(r"\d+$", "", raw.strip())
    return normalized.strip()


def convert_pos(pos: Optional[str]) -> str:
    """품사 코드를 영어로 변환. 알 수 없는 값은 'Other'."""
    if not isinstance(pos, str):
        return "Other"
    return _POS_MAP.get(pos.strip(), "Other")


def parse_level(level: Optional[str]) -> str:
    """등급 코드를 영어로 변환. 알 수 없는 값은 'Unknown'."""
    if not isinstance(level, str):
        return "Unknown"
    return _LEVEL_MAP.get(level.strip(), "Unknown")


def _safe_hanja(value) -> str:
    """NaN, None, 비문자열을 빈 문자열로 안전 변환."""
    if value is None:
        return ""
    if isinstance(value, float) and math.isnan(value):
        return ""
    return str(value).strip()


def parse_row(row: pd.Series) -> VocabEntry:
    """
    pandas DataFrame의 한 행(Series)을 VocabEntry DTO로 변환.
    이 함수가 파서의 핵심 단위이며, 전체 파이프라인의 입력 공급원입니다.
    """
    return VocabEntry(
        korean_word=normalize_word(row.get("단어", "")),
        part_of_speech=convert_pos(row.get("품사")),
        hanja_hint=_safe_hanja(row.get("풀이")),
        level=parse_level(row.get("등급")),
    )


# ─────────────────────────────────────────────
# 전체 XLS 파일 파싱 함수
# ─────────────────────────────────────────────
def parse_xls(file_path: str) -> list[VocabEntry]:
    """
    XLS 파일 전체를 읽어 VocabEntry 리스트로 반환.
    빈 단어 또는 파싱 실패 행은 자동 스킵.
    """
    df = pd.read_excel(file_path, sheet_name=0)

    entries = []
    skipped = 0

    for _, row in df.iterrows():
        try:
            entry = parse_row(row)
            if not entry.korean_word:
                skipped += 1
                continue
            entries.append(entry)
        except Exception as e:
            skipped += 1
            print(f"[WARN] 행 파싱 실패 (스킵): {row.get('단어', '?')} — {e}")

    print(f"[parse_xls] 완료: {len(entries)}개 파싱, {skipped}개 스킵")
    return entries


# ─────────────────────────────────────────────
# 단독 실행 시 샘플 미리보기
# ─────────────────────────────────────────────
if __name__ == "__main__":
    import sys
    import os

    xls_path = os.path.join(os.path.dirname(__file__), "한국어 학습용 어휘 목록.xls")
    entries = parse_xls(xls_path)

    print(f"\n총 {len(entries)}개 단어 파싱 완료. 샘플 10개:")
    for e in entries[:10]:
        print(f"  [{e.level}] {e.korean_word} ({e.part_of_speech}) | 한자: {e.hanja_hint or '-'}")
