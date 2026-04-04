"""TraceForge trajectory parsing helpers.

These helpers are intentionally lightweight. They keep raw payloads around,
derive only a small amount of structure, and leave deeper interpretation for
Jac walkers and later analysis passes.
"""

from __future__ import annotations

from dataclasses import dataclass, field
from pathlib import Path
import hashlib
import json
from typing import Any, Iterable, Sequence


@dataclass(slots=True)
class RawTurn:
    """A single message-like item from a trajectory."""

    index: int
    role: str
    content: str
    raw: dict[str, Any] = field(default_factory=dict)


@dataclass(slots=True)
class ParsedStep:
    """A coarse decision step built from one assistant turn and follow-up output."""

    index: int
    assistant_turn: RawTurn | None
    trailing_turns: list[RawTurn] = field(default_factory=list)
    kind: str = "OTHER"
    phase: str = "other"
    excerpt: str = ""
    content_hash: str = ""
    touched_files: list[str] = field(default_factory=list)
    patch_text: str = ""
    test_text: str = ""
    error_text: str = ""


@dataclass(slots=True)
class ParsedRun:
    """Minimal trajectory representation for later Jac-side graph compilation."""

    run_id: str
    source_path: str
    raw: dict[str, Any]
    turns: list[RawTurn] = field(default_factory=list)
    steps: list[ParsedStep] = field(default_factory=list)
    metadata: dict[str, Any] = field(default_factory=dict)


def load_trajectory_file(path: str | Path) -> dict[str, Any]:
    """Load a trajectory JSON file and return the raw dict.

    Unknown structures are preserved as-is so later passes can adapt without
    rewriting ingestion.
    """

    data = json.loads(Path(path).read_text(encoding="utf-8"))
    if not isinstance(data, dict):
        raise ValueError("trajectory file must decode to a JSON object")
    return data


def _turn_role(item: dict[str, Any]) -> str:
    role = item.get("role") or item.get("speaker") or item.get("type") or "other"
    return str(role).lower()


def _turn_content(item: dict[str, Any]) -> str:
    content = item.get("content")
    if content is None:
        content = item.get("text")
    if content is None:
        content = item.get("message")
    return "" if content is None else str(content)


def extract_turns(raw: dict[str, Any]) -> list[RawTurn]:
    """Extract a stable list of turns from common trajectory field names."""

    candidates: Sequence[Any] = (
        raw.get("trajectory"),
        raw.get("messages"),
        raw.get("history"),
        raw.get("turns"),
    )
    items: Iterable[Any] = next((c for c in candidates if isinstance(c, list)), [])

    turns: list[RawTurn] = []
    for index, item in enumerate(items):
        if not isinstance(item, dict):
            continue
        turns.append(
            RawTurn(
                index=index,
                role=_turn_role(item),
                content=_turn_content(item),
                raw=item,
            )
        )
    return turns


def _hash_text(text: str) -> str:
    return hashlib.sha256(text.encode("utf-8")).hexdigest()


def _infer_kind(role: str, text: str) -> str:
    lower = text.lower()
    if role in {"assistant", "agent"}:
        return "ASSISTANT"
    if "traceback" in lower or "error" in lower or "exception" in lower:
        return "ERROR"
    if "pytest" in lower or "test" in lower:
        return "TEST"
    if "patch" in lower or "diff" in lower or "apply_patch" in lower:
        return "EDIT"
    if "submit" in lower or "final" in lower:
        return "SUBMIT"
    if role in {"tool", "command", "system"}:
        return role.upper()
    return "OTHER"


def _infer_phase(text: str) -> str:
    lower = text.lower()
    if any(token in lower for token in ("grep", "ls", "find", "read", "inspect")):
        return "inspect"
    if any(token in lower for token in ("patch", "diff", "apply_patch", "write")):
        return "edit"
    if any(token in lower for token in ("pytest", "unittest", "test")):
        return "test"
    if any(token in lower for token in ("submit", "final", "done")):
        return "submit"
    if any(token in lower for token in ("traceback", "error", "exception", "failed")):
        return "error"
    return "other"


def segment_steps(turns: Sequence[RawTurn]) -> list[ParsedStep]:
    """Group turns into coarse decision steps.

    This is a simple default that treats each assistant turn as a pivot and
    attaches following non-assistant turns until the next assistant turn.
    """

    steps: list[ParsedStep] = []
    current: ParsedStep | None = None

    for turn in turns:
        is_assistant = turn.role in {"assistant", "agent"}
        if is_assistant:
            if current is not None:
                steps.append(current)
            current = ParsedStep(index=len(steps), assistant_turn=turn)
            current.kind = _infer_kind(turn.role, turn.content)
            current.phase = _infer_phase(turn.content)
            current.excerpt = turn.content.strip()[:280]
            current.content_hash = _hash_text(turn.content)
            continue

        if current is None:
            current = ParsedStep(index=len(steps), assistant_turn=None)

        current.trailing_turns.append(turn)
        current.excerpt = (current.excerpt + "\n" + turn.content.strip()).strip()[:280]
        current.kind = current.kind if current.kind != "OTHER" else _infer_kind(turn.role, turn.content)
        current.phase = current.phase if current.phase != "other" else _infer_phase(turn.content)
        if turn.content:
            current.content_hash = _hash_text(current.content_hash + turn.content) if current.content_hash else _hash_text(turn.content)

    if current is not None:
        steps.append(current)

    for step in steps:
        if not step.content_hash:
            joined = "\n".join([step.assistant_turn.content if step.assistant_turn else ""] + [t.content for t in step.trailing_turns])
            step.content_hash = _hash_text(joined)
        if not step.excerpt:
            step.excerpt = (step.assistant_turn.content if step.assistant_turn else "").strip()[:280]

    return steps


def parse_run(source_path: str | Path, run_id: str | None = None) -> ParsedRun:
    """Parse one trajectory file into a compact run object."""

    raw = load_trajectory_file(source_path)
    turns = extract_turns(raw)
    steps = segment_steps(turns)
    metadata = raw.get("metadata") if isinstance(raw.get("metadata"), dict) else {}
    if run_id is None:
        run_id = str(raw.get("run_id") or raw.get("instance_id") or Path(source_path).stem)
    return ParsedRun(
        run_id=run_id,
        source_path=str(source_path),
        raw=raw,
        turns=turns,
        steps=steps,
        metadata=dict(metadata),
    )

