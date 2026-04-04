"""Deterministic feature extraction for TraceForge runs."""

from __future__ import annotations

from dataclasses import dataclass, field
from typing import Any

from py.parser import ParsedRun, ParsedStep
from py.utils import bounded_ratio, unique_preserve_order


@dataclass(slots=True)
class RunFingerprint:
    """Compact run-level summary used by later clustering and diagnosis."""

    num_steps: int = 0
    num_turns: int = 0
    num_commands: int = 0
    num_tests: int = 0
    num_patches: int = 0
    num_unique_files: int = 0
    repeated_step_ratio: float = 0.0
    repeated_file_ratio: float = 0.0
    first_patch_step: int = -1
    first_test_step: int = -1
    first_error_step: int = -1
    first_submit_step: int = -1
    submit_before_recovery: bool = False
    nonzero_return_ratio: float = 0.0
    loop_score: float = 0.0
    top_files: list[str] = field(default_factory=list)
    top_test_names: list[str] = field(default_factory=list)
    top_error_keywords: list[str] = field(default_factory=list)
    step_kind_sequence: list[str] = field(default_factory=list)
    failure_class_scores: dict[str, float] = field(default_factory=dict)


def _step_text(step: ParsedStep) -> str:
    parts = [step.excerpt]
    if step.assistant_turn:
        parts.append(step.assistant_turn.content)
    parts.extend(turn.content for turn in step.trailing_turns)
    return "\n".join(part for part in parts if part)


def _looks_like_command(text: str) -> bool:
    lower = text.lower()
    return any(
        token in lower
        for token in ("$", "python ", "pytest", "bash", "git ", "ls ", "grep ", "find ", "apply_patch")
    )


def _extract_file_tokens(text: str) -> list[str]:
    tokens: list[str] = []
    for chunk in text.replace("`", " ").split():
        cleaned = chunk.strip(" ,:;()[]{}<>")
        if not cleaned:
            continue
        if "/" in cleaned or "::" in cleaned or cleaned.endswith((".py", ".md", ".json", ".toml", ".yaml", ".yml")):
            tokens.append(cleaned)
    return unique_preserve_order(tokens)


def compute_run_fingerprint(run: ParsedRun) -> RunFingerprint:
    """Compute a compact deterministic summary for a parsed run."""

    fingerprint = RunFingerprint()
    fingerprint.num_steps = len(run.steps)
    fingerprint.num_turns = len(run.turns)

    files: list[str] = []
    repeated_hits = 0
    step_signatures: list[str] = []
    seen_hashes: set[str] = set()
    nonzero_returns = 0
    saw_error = False
    passed_after_error = False
    search_command_hits = 0
    syntax_error_after_patch = False

    for idx, step in enumerate(run.steps):
        text = _step_text(step)
        lower = text.lower()
        step_signatures.append(step.kind or "OTHER")

        if _looks_like_command(text):
            fingerprint.num_commands += 1
        if any(token in lower for token in ("grep ", "ls ", "find ")):
            search_command_hits += 1
        if "pytest" in lower or "test" in lower:
            fingerprint.num_tests += 1
            if fingerprint.first_test_step < 0:
                fingerprint.first_test_step = idx
            fingerprint.top_test_names.extend(_extract_file_tokens(text))
        if "patch" in lower or "diff" in lower or "apply_patch" in lower:
            fingerprint.num_patches += 1
            if fingerprint.first_patch_step < 0:
                fingerprint.first_patch_step = idx
        if "traceback" in lower or "error" in lower or "exception" in lower or "failed" in lower:
            saw_error = True
            if fingerprint.first_error_step < 0:
                fingerprint.first_error_step = idx
            fingerprint.top_error_keywords.extend(
                token for token in ("traceback", "error", "exception", "failed") if token in lower
            )
            if fingerprint.first_patch_step >= 0 and idx >= fingerprint.first_patch_step:
                if "syntaxerror" in lower or "invalid syntax" in lower or "traceback" in lower:
                    syntax_error_after_patch = True
        if saw_error and (" passed" in lower or lower.startswith("passed") or "resolved" in lower or "1 passed" in lower):
            passed_after_error = True
        if "submit" in lower or "final" in lower:
            if fingerprint.first_submit_step < 0:
                fingerprint.first_submit_step = idx

        extracted = _extract_file_tokens(text)
        if extracted:
            files.extend(extracted)
        if step.content_hash in seen_hashes:
            repeated_hits += 1
        else:
            seen_hashes.add(step.content_hash)
        if "returncode" in lower or "exit code" in lower or "non-zero" in lower:
            nonzero_returns += 1

    unique_files = unique_preserve_order(files)
    fingerprint.num_unique_files = len(unique_files)
    fingerprint.top_files = unique_files[:8]
    fingerprint.top_error_keywords = unique_preserve_order(fingerprint.top_error_keywords)[:8]
    fingerprint.top_test_names = unique_preserve_order(fingerprint.top_test_names)[:8]
    fingerprint.step_kind_sequence = step_signatures
    fingerprint.repeated_step_ratio = bounded_ratio(repeated_hits, max(len(run.steps), 1))
    fingerprint.repeated_file_ratio = bounded_ratio(len(files) - len(unique_files), max(len(files), 1))
    fingerprint.nonzero_return_ratio = bounded_ratio(nonzero_returns, max(len(run.steps), 1))
    fingerprint.loop_score = round(fingerprint.repeated_step_ratio * 0.6 + fingerprint.repeated_file_ratio * 0.4, 4)
    fingerprint.submit_before_recovery = (
        fingerprint.first_submit_step >= 0
        and fingerprint.first_error_step >= 0
        and not passed_after_error
    )
    fingerprint.failure_class_scores = {
        "PREMATURE_COMPLETION": 0.0,
        "INVALID_PATCH": 0.0,
        "WRONG_FILE_FOCUS": 0.0,
        "OSCILLATION_LOOP": 0.0,
        "TOOL_MISUSE": fingerprint.nonzero_return_ratio,
        "STALE_CONTEXT_OR_BAD_PLAN": 0.0,
        "REQUIREMENT_DRIFT": 0.0,
    }
    if fingerprint.submit_before_recovery:
        fingerprint.failure_class_scores["PREMATURE_COMPLETION"] = 0.8
    if (
        fingerprint.first_patch_step >= 0
        and fingerprint.first_error_step >= 0
        and fingerprint.first_patch_step <= fingerprint.first_error_step
        and not passed_after_error
    ):
        fingerprint.failure_class_scores["INVALID_PATCH"] = 0.95 if syntax_error_after_patch else 0.5
    if fingerprint.num_unique_files > 0 and fingerprint.repeated_file_ratio > 0.5:
        fingerprint.failure_class_scores["WRONG_FILE_FOCUS"] = 0.5
    if (
        not passed_after_error
        and (
            fingerprint.loop_score >= 0.35
            or search_command_hits >= 3
            or (fingerprint.repeated_file_ratio >= 0.25 and fingerprint.num_tests == 0)
        )
    ):
        fingerprint.failure_class_scores["OSCILLATION_LOOP"] = max(fingerprint.loop_score, 0.7)
    return fingerprint


def fingerprint_to_dict(fingerprint: RunFingerprint) -> dict[str, Any]:
    """Convert a fingerprint to a JSON-friendly dict."""

    return {
        "num_steps": fingerprint.num_steps,
        "num_turns": fingerprint.num_turns,
        "num_commands": fingerprint.num_commands,
        "num_tests": fingerprint.num_tests,
        "num_patches": fingerprint.num_patches,
        "num_unique_files": fingerprint.num_unique_files,
        "repeated_step_ratio": fingerprint.repeated_step_ratio,
        "repeated_file_ratio": fingerprint.repeated_file_ratio,
        "first_patch_step": fingerprint.first_patch_step,
        "first_test_step": fingerprint.first_test_step,
        "first_error_step": fingerprint.first_error_step,
        "first_submit_step": fingerprint.first_submit_step,
        "submit_before_recovery": fingerprint.submit_before_recovery,
        "nonzero_return_ratio": fingerprint.nonzero_return_ratio,
        "loop_score": fingerprint.loop_score,
        "top_files": fingerprint.top_files,
        "top_test_names": fingerprint.top_test_names,
        "top_error_keywords": fingerprint.top_error_keywords,
        "step_kind_sequence": fingerprint.step_kind_sequence,
        "failure_class_scores": fingerprint.failure_class_scores,
    }
