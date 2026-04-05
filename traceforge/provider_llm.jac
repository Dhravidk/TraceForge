import json;
import from pathlib { Path }
import from shutil { rmtree }
import from subprocess { run }
import from tempfile { mkdtemp }
import from time { perf_counter }
import from urllib.error { HTTPError, URLError }
import from urllib.request { Request, urlopen }
import from traceforge.provider_config {
    configured_codex_cli_path,
    configured_provider_key,
    configured_provider_model,
    provider_resolution_summary,
}
import from traceforge.parser { truncate_text }

def _trim_json_fence(text: str) -> str {
    cleaned = str(text or "").strip();
    if cleaned.startswith("```json") {
        cleaned = cleaned.removeprefix("```json").strip();
    } elif cleaned.startswith("```") {
        cleaned = cleaned.removeprefix("```").strip();
    }
    if cleaned.endswith("```") {
        cleaned = cleaned.removesuffix("```").strip();
    }
    return cleaned;
}

def extract_json_object(text: str) -> dict[str, any] {
    cleaned = _trim_json_fence(text);
    try {
        parsed = json.loads(cleaned);
        if isinstance(parsed, dict) {
            return parsed;
        }
    } except Exception {
    }

    start = cleaned.find("{");
    stop = cleaned.rfind("}");
    if start >= 0 and stop > start {
        snippet = cleaned[start: stop + 1];
        parsed = json.loads(snippet);
        if isinstance(parsed, dict) {
            return parsed;
        }
    }
    raise ValueError("model response did not contain a JSON object");
}

def _pack_token_estimate(text: str) -> int {
    if not text {
        return 0;
    }
    return max(len(text) // 4, 1);
}

def _codex_exec_prompt(system_prompt: str, user_prompt: str) -> str {
    lines: list[str] = [];
    lines.append("You are being used as an offline evaluator, not as a coding agent.");
    lines.append("Do not run commands, inspect files, or use tools.");
    lines.append("Answer only from the evidence in this prompt.");
    lines.append("");
    lines.append("Evaluator instructions:");
    lines.append(system_prompt);
    lines.append("");
    lines.append("Evidence:");
    lines.append(user_prompt);
    return "\n".join(lines);
}

def _codex_completion(system_prompt: str, user_prompt: str, model: str, schema: dict[str, any]) -> dict[str, any] {
    codex_path = configured_codex_cli_path();
    if not codex_path {
        raise RuntimeError("Codex CLI is not available on PATH.");
    }

    temp_root = Path(mkdtemp(prefix="traceforge_provider_llm_"));
    schema_path = temp_root.joinpath("schema.json");
    output_path = temp_root.joinpath("last_message.json");
    schema_path.write_text(json.dumps(schema, indent=2) + "\n", encoding="utf-8");
    prompt_text = _codex_exec_prompt(system_prompt, user_prompt);
    command = [
        codex_path,
        "exec",
        "--skip-git-repo-check",
        "--ephemeral",
        "--dangerously-bypass-approvals-and-sandbox",
        "--color",
        "never",
        "--output-schema",
        str(schema_path),
        "--output-last-message",
        str(output_path),
        "-C",
        str(temp_root),
    ];
    if model {
        command.extend(["-m", model]);
    }
    command.append("-");

    start = perf_counter();
    try {
        result = run(
            command,
            input=prompt_text,
            capture_output=True,
            text=True,
            check=False,
            timeout=300,
        );
        latency_ms = round((perf_counter() - start) * 1000.0, 2);
        if result.returncode != 0 {
            raise RuntimeError(
                "Codex CLI failed: "
                + truncate_text((result.stderr or result.stdout or "").strip(), 1200)
            );
        }
        if not output_path.exists() {
            raise RuntimeError("Codex CLI did not write an output message.");
        }
        text = output_path.read_text(encoding="utf-8").strip();
        completion_tokens = _pack_token_estimate(text);
        prompt_tokens = _pack_token_estimate(prompt_text);
        return {
            "text": text,
            "usage": {
                "prompt_tokens": prompt_tokens,
                "completion_tokens": completion_tokens,
                "total_tokens": prompt_tokens + completion_tokens,
            },
            "latency_ms": latency_ms,
            "provider": "codex",
            "model": model,
        };
    } finally {
        rmtree(temp_root, ignore_errors=True);
    }
}

def _http_post_json(url: str, headers: dict[str, str], payload: dict[str, any]) -> dict[str, any] {
    request = Request(
        url=url,
        data=json.dumps(payload).encode("utf-8"),
        headers=headers,
        method="POST",
    );
    start = perf_counter();
    try {
        response = urlopen(request);
        body_text = response.read().decode("utf-8");
        latency_ms = round((perf_counter() - start) * 1000.0, 2);
        return {
            "status": int(response.status),
            "body": json.loads(body_text),
            "latency_ms": latency_ms,
        };
    } except HTTPError as err {
        body_text = err.read().decode("utf-8");
        raise RuntimeError("HTTP " + str(err.code) + ": " + body_text);
    } except URLError as err {
        raise RuntimeError("Network error: " + str(err.reason));
    }
}

def _openai_completion(system_prompt: str, user_prompt: str, model: str) -> dict[str, any] {
    headers = {
        "Authorization": "Bearer " + configured_provider_key("openai"),
        "Content-Type": "application/json",
    };
    payload = {
        "model": model,
        "temperature": 0.0,
        "max_completion_tokens": 900,
        "messages": [
            {"role": "system", "content": system_prompt},
            {"role": "user", "content": user_prompt},
        ],
    };
    response = _http_post_json("https://api.openai.com/v1/chat/completions", headers, payload);
    body = response["body"];
    choice = body.get("choices", [])[0];
    message = choice.get("message", {});
    content = str(message.get("content") or "");
    usage = body.get("usage", {});
    return {
        "text": content,
        "usage": {
            "prompt_tokens": int(usage.get("prompt_tokens") or 0),
            "completion_tokens": int(usage.get("completion_tokens") or 0),
            "total_tokens": int(usage.get("total_tokens") or 0),
        },
        "latency_ms": response["latency_ms"],
        "provider": "openai",
        "model": model,
    };
}

def _anthropic_completion(system_prompt: str, user_prompt: str, model: str) -> dict[str, any] {
    headers = {
        "x-api-key": configured_provider_key("anthropic"),
        "anthropic-version": "2023-06-01",
        "content-type": "application/json",
    };
    payload = {
        "model": model,
        "system": system_prompt,
        "temperature": 0.0,
        "max_tokens": 900,
        "messages": [
            {
                "role": "user",
                "content": [
                    {
                        "type": "text",
                        "text": user_prompt,
                    }
                ],
            }
        ],
    };
    response = _http_post_json("https://api.anthropic.com/v1/messages", headers, payload);
    body = response["body"];
    content_text = "";
    for block in body.get("content", []) {
        if str(block.get("type") or "") == "text" {
            content_text += str(block.get("text") or "");
        }
    }
    usage = body.get("usage", {});
    input_tokens = int(usage.get("input_tokens") or 0);
    output_tokens = int(usage.get("output_tokens") or 0);
    return {
        "text": content_text,
        "usage": {
            "prompt_tokens": input_tokens,
            "completion_tokens": output_tokens,
            "total_tokens": input_tokens + output_tokens,
        },
        "latency_ms": response["latency_ms"],
        "provider": "anthropic",
        "model": model,
    };
}

def provider_llm_status(provider: str = "auto", model: str = "") -> dict[str, any] {
    resolved = provider_resolution_summary(provider, model);
    return {
        "llm_ready": bool(resolved.get("available")),
        "resolved_provider": str(resolved.get("provider") or ""),
        "resolved_model": str(resolved.get("model") or ""),
        "provider_available": bool(resolved.get("available")),
        "status": "provider_ready" if bool(resolved.get("available")) else "unavailable",
        "message": (
            "Provider-backed synthesis is available."
            if bool(resolved.get("available"))
            else "No configured provider is available for live synthesis."
        ),
    };
}

def run_provider_json(
    system_prompt: str,
    user_prompt: str,
    schema: dict[str, any],
    provider: str = "auto",
    model: str = "",
) -> dict[str, any] {
    resolved = provider_resolution_summary(provider, model);
    if not bool(resolved.get("available")) {
        raise RuntimeError("No configured model provider is available for live synthesis.");
    }
    chosen_provider = str(resolved.get("provider") or "");
    chosen_model = configured_provider_model(chosen_provider, str(resolved.get("model") or model));
    response = {};
    if chosen_provider == "codex" {
        response = _codex_completion(system_prompt, user_prompt, chosen_model, schema);
    } elif chosen_provider == "openai" {
        response = _openai_completion(system_prompt, user_prompt, chosen_model);
    } elif chosen_provider == "anthropic" {
        response = _anthropic_completion(system_prompt, user_prompt, chosen_model);
    } else {
        raise RuntimeError("Unsupported provider: " + chosen_provider);
    }
    parsed = extract_json_object(str(response["text"]));
    return {
        "parsed": parsed,
        "provider": str(response["provider"]),
        "model": str(response["model"]),
        "latency_ms": float(response["latency_ms"]),
        "usage": response["usage"],
        "raw_model_text": str(response["text"]),
    };
}
