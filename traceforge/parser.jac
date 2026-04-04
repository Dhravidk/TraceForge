import json;
import hashlib;
import from pathlib { Path }

obj RawTurn {
    has index: int;
    has role: str;
    has content: str;
    has raw: dict[str, any] = {};
}

obj ParsedStep {
    has index: int;
    has role: str = "other";
    has kind: str = "OTHER";
    has phase: str = "other";
    has excerpt: str = "";
    has content_hash: str = "";
    has assistant_content: str = "";
    has trailing_turns: list[RawTurn] = [];
    has touched_files: list[str] = [];
    has patch_text: str = "";
    has test_text: str = "";
    has error_text: str = "";
}

obj ParsedRun {
    has run_id: str;
    has source_path: str;
    has raw: dict[str, any] = {};
    has turns: list[RawTurn] = [];
    has steps: list[ParsedStep] = [];
    has metadata: dict[str, any] = {};
    has instance_id: str = "";
    has task_title: str = "";
}

def truncate_text(text: str, limit: int = 280) -> str {
    clean = text.strip();
    if len(clean) <= limit {
        return clean;
    }
    return clean[: max(limit - 3, 0)].rstrip() + "...";
}

def unique_strings(items: list[str]) -> list[str] {
    seen: set[str] = set();
    output: list[str] = [];
    for item in items {
        if item in seen {
            continue;
        }
        seen.add(item);
        output.append(item);
    }
    return output;
}

def path_run_stem(path: str) -> str {
    name = Path(path).name;
    if name.endswith(".traj.json") {
        return name.removesuffix(".traj.json");
    }
    return Path(path).stem;
}

def load_trajectory_file(path: str) -> dict[str, any] {
    text = Path(path).read_text(encoding="utf-8");
    data = json.loads(text);
    if not isinstance(data, dict) {
        raise ValueError("trajectory file must decode to a JSON object");
    }
    return data;
}

def _turn_role(item: dict[str, any]) -> str {
    role = item.get("role");
    if role is None {
        role = item.get("speaker");
    }
    if role is None {
        role = item.get("type");
    }
    if role is None {
        role = "other";
    }
    return str(role).lower();
}

def _turn_content(item: dict[str, any]) -> str {
    content = item.get("content");
    if content is None {
        content = item.get("text");
    }
    if content is None {
        content = item.get("message");
    }
    if content is None {
        return "";
    }
    return str(content);
}

def extract_turns(raw: dict[str, any]) -> list[RawTurn] {
    items: list[any] = [];
    candidates = [
        raw.get("trajectory"),
        raw.get("messages"),
        raw.get("history"),
        raw.get("turns"),
    ];
    for candidate in candidates {
        if isinstance(candidate, list) {
            items = candidate;
            break;
        }
    }

    turns: list[RawTurn] = [];
    for (index, item) in enumerate(items) {
        if not isinstance(item, dict) {
            continue;
        }
        turns.append(
            RawTurn(
                index=index,
                role=_turn_role(item),
                content=_turn_content(item),
                raw=item,
            )
        );
    }
    return turns;
}

def hash_text(text: str) -> str {
    return hashlib.sha256(text.encode("utf-8")).hexdigest();
}

def infer_kind(role: str, text: str) -> str {
    lower = text.lower();
    if role in {"assistant", "agent"} {
        return "ASSISTANT";
    }
    if "traceback" in lower or "error" in lower or "exception" in lower or "failed" in lower {
        return "ERROR";
    }
    if "pytest" in lower or "test" in lower {
        return "TEST";
    }
    if "patch" in lower or "diff" in lower or "apply_patch" in lower {
        return "EDIT";
    }
    if "submit" in lower or "final" in lower {
        return "SUBMIT";
    }
    if role in {"tool", "command", "system"} {
        return role.upper();
    }
    return "OTHER";
}

def infer_phase(text: str) -> str {
    lower = text.lower();
    if any(token in lower for token in ["grep", "ls", "find", "read", "inspect"]) {
        return "inspect";
    }
    if any(token in lower for token in ["patch", "diff", "apply_patch", "write"]) {
        return "edit";
    }
    if any(token in lower for token in ["pytest", "unittest", "test"]) {
        return "test";
    }
    if any(token in lower for token in ["submit", "final", "done"]) {
        return "submit";
    }
    if any(token in lower for token in ["traceback", "error", "exception", "failed"]) {
        return "error";
    }
    return "other";
}

def extract_file_tokens(text: str) -> list[str] {
    tokens: list[str] = [];
    for chunk in text.replace("`", " ").split() {
        cleaned = chunk.strip(" ,:;()[]{}<>");
        if not cleaned {
            continue;
        }
        if "/" in cleaned or "::" in cleaned {
            tokens.append(cleaned);
            continue;
        }
        if (
            cleaned.endswith(".py")
            or cleaned.endswith(".md")
            or cleaned.endswith(".json")
            or cleaned.endswith(".toml")
            or cleaned.endswith(".yaml")
            or cleaned.endswith(".yml")
        ) {
            tokens.append(cleaned);
        }
    }
    return unique_strings(tokens);
}

def step_text(step: ParsedStep) -> str {
    parts: list[str] = [];
    if step.assistant_content {
        parts.append(step.assistant_content);
    }
    for turn in step.trailing_turns {
        if turn.content {
            parts.append(turn.content);
        }
    }
    return "\n".join(parts);
}

def finalize_step(step: ParsedStep) -> ParsedStep {
    text = step_text(step);
    lower = text.lower();
    if not step.content_hash {
        step.content_hash = hash_text(text);
    }
    if not step.excerpt {
        step.excerpt = truncate_text(text);
    }
    step.touched_files = extract_file_tokens(text);
    if "patch" in lower or "diff" in lower or "apply_patch" in lower {
        step.patch_text = truncate_text(text, 600);
    }
    if "pytest" in lower or "test" in lower {
        step.test_text = truncate_text(text, 600);
    }
    if "traceback" in lower or "error" in lower or "exception" in lower or "failed" in lower {
        step.error_text = truncate_text(text, 600);
    }
    return step;
}

def segment_steps(turns: list[RawTurn]) -> list[ParsedStep] {
    steps: list[ParsedStep] = [];
    current: ParsedStep | None = None;

    for turn in turns {
        is_assistant = turn.role in {"assistant", "agent"};
        if is_assistant {
            if current is not None {
                steps.append(finalize_step(current));
            }
            current = ParsedStep(index=len(steps));
            current.role = turn.role;
            current.kind = infer_kind(turn.role, turn.content);
            current.phase = infer_phase(turn.content);
            current.assistant_content = turn.content;
            current.excerpt = truncate_text(turn.content);
            current.content_hash = hash_text(turn.content);
            continue;
        }

        if current is None {
            current = ParsedStep(index=len(steps));
            current.role = turn.role;
        }

        current.trailing_turns.append(turn);
        current.excerpt = truncate_text((current.excerpt + "\n" + turn.content).strip());
        if current.kind == "OTHER" {
            current.kind = infer_kind(turn.role, turn.content);
        }
        if current.phase == "other" {
            current.phase = infer_phase(turn.content);
        }
        if turn.content {
            if current.content_hash {
                current.content_hash = hash_text(current.content_hash + turn.content);
            } else {
                current.content_hash = hash_text(turn.content);
            }
        }
    }

    if current is not None {
        steps.append(finalize_step(current));
    }

    return steps;
}

def parse_run(source_path: str, run_id: str = "") -> ParsedRun {
    raw = load_trajectory_file(source_path);
    turns = extract_turns(raw);
    steps = segment_steps(turns);
    metadata = raw.get("metadata");
    if not isinstance(metadata, dict) {
        metadata = {};
    }
    chosen_run_id = run_id;
    if not chosen_run_id {
        raw_run_id = raw.get("run_id");
        raw_instance_id = raw.get("instance_id");
        if raw_run_id is not None and str(raw_run_id) {
            chosen_run_id = str(raw_run_id);
        } elif raw_instance_id is not None and str(raw_instance_id) {
            chosen_run_id = str(raw_instance_id);
        } else {
            chosen_run_id = path_run_stem(source_path);
        }
    }
    return ParsedRun(
        run_id=chosen_run_id,
        source_path=source_path,
        raw=raw,
        turns=turns,
        steps=steps,
        metadata=metadata,
        instance_id=str(raw.get("instance_id") or ""),
        task_title=str(raw.get("task_title") or ""),
    );
}
