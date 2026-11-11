#!/usr/bin/env python
"""Entry point: py main.py [options]"""

from sqlscan.bootstrap import ensure_runtime

ensure_runtime()

from sqlscan.cli import main  # noqa: E402

if __name__ == "__main__":
    raise SystemExit(main())
