from __future__ import annotations

import os
from pathlib import Path

APP_NAME = "hax-bot"
VERSION = "7.8.0"

# app/config.py -> app -> project root
APP_ROOT = Path(os.getenv("HAX_APP_DIR", Path(__file__).resolve().parents[1])).resolve()
DATA_DIR = APP_ROOT / "data"
LOG_DIR = APP_ROOT / "logs"

TOKEN_FILE = APP_ROOT / "token.txt"
INTERVAL_FILE = APP_ROOT / "interval.txt"
USER_DATA_FILE = DATA_DIR / "user_data.json"
SNAPSHOT_JSON_FILE = DATA_DIR / "data_center.json"
SNAPSHOT_TEXT_FILE = DATA_DIR / "data_center.txt"
LEGACY_TEST_FILE = APP_ROOT / "test.txt"

HAX_DATA_CENTER_URL = os.getenv("HAX_DATA_CENTER_URL", "https://hax.co.id/data-center/")
DEFAULT_INTERVAL_SECONDS = 30
REQUEST_TIMEOUT_SECONDS = 20

HOST_TYPES = {
    "hax": {"name": "Hax主机", "days": 5},
    "woiden": {"name": "Woiden主机", "days": 3},
}


def ensure_runtime_dirs() -> None:
    DATA_DIR.mkdir(parents=True, exist_ok=True)
    LOG_DIR.mkdir(parents=True, exist_ok=True)


def read_text_file(path: Path, default: str = "") -> str:
    try:
        return path.read_text(encoding="utf-8").strip()
    except FileNotFoundError:
        return default


def get_token() -> str:
    token = os.getenv("HAX_TOKEN", "").strip()
    if token:
        return token
    return read_text_file(TOKEN_FILE)


def get_interval_seconds(default: int = DEFAULT_INTERVAL_SECONDS) -> int:
    raw = os.getenv("HAX_INTERVAL", "").strip() or read_text_file(INTERVAL_FILE)
    try:
        value = int(raw)
        return value if value > 0 else default
    except (TypeError, ValueError):
        return default
