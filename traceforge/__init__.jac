glob APP_NAME: str = "TraceForge";
glob APP_TAGLINE: str = "Batch failure compiler for coding-agent trajectories";
glob APP_VERSION: str = "0.1.0-hackathon";

def project_identity() -> dict[str, any] {
    return {
        "name": APP_NAME,
        "tagline": APP_TAGLINE,
        "version": APP_VERSION,
        "status": "scaffold",
    };
}

