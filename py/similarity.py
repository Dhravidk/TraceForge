"""Similarity helpers for TraceForge runs."""

from __future__ import annotations

from dataclasses import dataclass
from typing import Iterable

from py.features import RunFingerprint
from py.utils import cosine_like_overlap, top_k_indices


@dataclass(slots=True)
class NeighborScore:
    """One neighbor relationship in the run similarity graph."""

    index: int
    score: float


def _sequence_similarity(left: list[str], right: list[str]) -> float:
    if not left and not right:
        return 1.0
    return cosine_like_overlap(left, right)


def similarity_score(left: RunFingerprint, right: RunFingerprint) -> float:
    """Heuristic similarity over compact run fingerprints."""

    failure_overlap = cosine_like_overlap(
        [f"{k}:{round(v, 2)}" for k, v in left.failure_class_scores.items()],
        [f"{k}:{round(v, 2)}" for k, v in right.failure_class_scores.items()],
    )
    sequence_similarity = _sequence_similarity(left.step_kind_sequence, right.step_kind_sequence)
    lexical_overlap = cosine_like_overlap(
        left.top_files + left.top_test_names + left.top_error_keywords,
        right.top_files + right.top_test_names + right.top_error_keywords,
    )
    numeric_similarity = 1.0 - min(
        1.0,
        (
            abs(left.num_steps - right.num_steps)
            + abs(left.num_tests - right.num_tests)
            + abs(left.num_patches - right.num_patches)
            + abs(left.repeated_step_ratio - right.repeated_step_ratio)
            + abs(left.repeated_file_ratio - right.repeated_file_ratio)
            + abs(left.loop_score - right.loop_score)
        )
        / 6.0,
    )
    return round(
        0.35 * failure_overlap
        + 0.20 * sequence_similarity
        + 0.20 * lexical_overlap
        + 0.15 * numeric_similarity
        + 0.10 * lexical_overlap,
        4,
    )


def top_k_neighbors(target_index: int, fingerprints: list[RunFingerprint], k: int = 5) -> list[NeighborScore]:
    """Return the strongest neighbors for one run.

    The function is deterministic and intentionally simple so Jac-side graph
    walkers can reason about the same scores.
    """

    scores = []
    target = fingerprints[target_index]
    for index, other in enumerate(fingerprints):
        if index == target_index:
            continue
        scores.append(NeighborScore(index=index, score=similarity_score(target, other)))
    top = top_k_indices([item.score for item in scores], k=k)
    return [scores[i] for i in top]


def threshold_edges(neighbor_sets: Iterable[list[NeighborScore]], threshold: float) -> list[tuple[int, int, float]]:
    """Convert neighbor lists into graph edges."""

    edges: list[tuple[int, int, float]] = []
    for source_index, neighbors in enumerate(neighbor_sets):
        for neighbor in neighbors:
            if neighbor.score >= threshold:
                edges.append((source_index, neighbor.index, neighbor.score))
    return edges
