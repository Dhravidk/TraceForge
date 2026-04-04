import from pathlib { Path }
import from py.parser { parse_run }

glob SAMPLE_ROOT: str = "demo_runs";

def sample_batch_path(name: str = "starter") -> str {
    return f"{SAMPLE_ROOT}/{name}_batch";
}

def sample_batch_files(name: str = "starter") -> list[str] {
    batch_dir = Path(sample_batch_path(name));
    if not batch_dir.exists() {
        return [];
    }
    return [str(path) for path in sorted(batch_dir.glob("*.traj.json"))];
}

def sample_file_run_id(path: str) -> str {
    return Path(path).name.removesuffix(".traj.json");
}

def sample_batch_summary(name: str = "starter") -> dict[str, any] {
    files = sample_batch_files(name);
    run_ids = [sample_file_run_id(path) for path in files];
    return {
        "batch_id": "sample-" + name,
        "name": name,
        "source_format": "mini-swe-agent",
        "run_count": len(files),
        "run_ids": run_ids,
        "sample_path": sample_batch_path(name),
        "status": ("ready") if files else ("missing"),
        "next_step": "Use ParseBatch or GetRunView on one of the starter runs.",
    };
}

def upload_batch_summary(filename: str = "") -> dict[str, any] {
    return {
        "batch_id": "upload-pending",
        "filename": filename,
        "status": "not_implemented",
        "message": "Upload flow is scaffolded but not implemented yet.",
    };
}

def parse_batch_summary(batch_id: str) -> dict[str, any] {
    sample_name = batch_id.removeprefix("sample-");
    files = sample_batch_files(sample_name);
    if files {
        parsed_runs = [];
        for path in files {
            run = parse_run(path);
            parsed_runs.append(
                {
                    "run_id": run.run_id,
                    "step_count": len(run.steps),
                    "turn_count": len(run.turns),
                    "source_path": run.source_path,
                    "metadata": run.metadata,
                }
            );
        }
        return {
            "batch_id": batch_id,
            "status": "parsed",
            "run_count": len(parsed_runs),
            "runs": parsed_runs,
        };
    }
    return {
        "batch_id": batch_id,
        "status": "not_implemented",
        "message": "Parser contract is reserved for the ingest workstream.",
    };
}
