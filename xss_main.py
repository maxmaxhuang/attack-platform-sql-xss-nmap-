#!/usr/bin/env python
"""XSS 工具入口：py xss_main.py [选项]"""

from sqlscan.bootstrap import ensure_runtime

ensure_runtime()

from xsscan.cli import main  # noqa: E402

if __name__ == "__main__":
    raise SystemExit(main())
