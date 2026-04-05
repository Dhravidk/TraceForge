"""Thin packaging shim for the Jac-native TraceForge CLI."""

from __future__ import annotations

import shutil
import subprocess
import sys
from pathlib import Path


def _repo_root() -> Path:
    return Path(__file__).resolve().parents[1]


def _jac_binary() -> str:
    local = _repo_root() / ".venv" / "bin" / "jac"
    if local.exists():
        return str(local)
    discovered = shutil.which("jac")
    if discovered:
        return discovered
    raise SystemExit("TraceForge CLI could not find `jac`. Create `.venv` first or add `jac` to PATH.")


def main(argv: list[str] | None = None) -> int:
    args = list(sys.argv[1:] if argv is None else argv)
    command = [_jac_binary(), "run", str(_repo_root() / "traceforge" / "cli.jac"), *args]
    result = subprocess.run(command, cwd=_repo_root(), check=False)
    return int(result.returncode)


if __name__ == "__main__":
    raise SystemExit(main())
