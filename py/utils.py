"""Shared helper utilities for TraceForge.

These helpers intentionally stay generic so both Python and Jac code can rely
on the same low-risk primitives later.
"""

from __future__ import annotations

from collections import Counter
from pathlib import Path
from typing import Iterable, TypeVar

T = TypeVar("T")


def safe_stem(path: str | Path) -> str:
    return Path(path).stem


def bounded_ratio(numerator: int, denominator: int) -> float:
    if denominator <= 0:
        return 0.0
    return round(min(max(numerator / denominator, 0.0), 1.0), 4)


def unique_preserve_order(items: Iterable[T]) -> list[T]:
    seen: set[T] = set()
    output: list[T] = []
    for item in items:
        if item in seen:
            continue
        seen.add(item)
        output.append(item)
    return output


def top_k_indices(values: list[float], k: int = 5) -> list[int]:
    return [index for index, _ in sorted(enumerate(values), key=lambda pair: pair[1], reverse=True)[: max(k, 0)]]


def cosine_like_overlap(left: Iterable[str], right: Iterable[str]) -> float:
    """A cheap token-overlap score that behaves like a loose cosine proxy."""

    left_counts = Counter(str(item) for item in left if str(item))
    right_counts = Counter(str(item) for item in right if str(item))
    if not left_counts and not right_counts:
        return 1.0
    if not left_counts or not right_counts:
        return 0.0

    intersection = 0
    for token in left_counts.keys() & right_counts.keys():
        intersection += min(left_counts[token], right_counts[token])
    left_total = sum(left_counts.values())
    right_total = sum(right_counts.values())
    return round((2.0 * intersection) / (left_total + right_total), 4)


def summarize_counts(items: Iterable[str], limit: int = 5) -> list[tuple[str, int]]:
    counts = Counter(str(item) for item in items if str(item))
    return counts.most_common(limit)


def truncate(text: str, limit: int = 280) -> str:
    clean = text.strip()
    if len(clean) <= limit:
        return clean
    return clean[: max(limit - 3, 0)].rstrip() + "..."

