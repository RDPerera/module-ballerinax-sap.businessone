#!/usr/bin/env python3
"""Regenerate all SAP Business One connectors: align each spec, rewrite CRUD
operationIds to verb-first, regenerate the client, and sanitize.

Run from the repo root:  python3 tools/regenerate.py
Requires `bal` on PATH.
"""
import json
import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
CONNS = ["administration", "financials", "fixedassets", "businesspartners", "crm",
         "sales", "purchasing", "banking", "inventory", "production", "projects",
         "service", "humanresources", "localization"]

CRUD = {"List", "Get", "Create", "Update", "Delete"}


def rewrite_operation_ids(spec_path):
    """Flip `<Base>_<Verb>` CRUD operationIds to verb-first `<Verb>_<Base>` so
    bal openapi generates listOrders / createOrders / getOrders / etc. Bound
    actions and *Service_* operations are left as-is."""
    spec = json.loads(spec_path.read_text())
    n = 0
    for item in spec.get("paths", {}).values():
        for op in item.values():
            if not isinstance(op, dict):
                continue
            oid = op.get("operationId")
            if not oid:
                continue
            m = re.match(r"^(?P<base>.+)_(?P<verb>List|Get|Create|Update|Delete)$", oid)
            if m:
                op["operationId"] = f"{m.group('verb')}_{m.group('base')}"
                n += 1
    spec_path.write_text(json.dumps(spec, indent=2) + "\n")
    return n


def run(cmd, cwd=None):
    r = subprocess.run(cmd, cwd=cwd, capture_output=True, text=True)
    if r.returncode != 0:
        print(r.stdout[-2000:]); print(r.stderr[-2000:])
        raise SystemExit(f"FAILED: {' '.join(cmd)}")
    return r


def main():
    only = sys.argv[1:] or CONNS
    aligned_dir = Path("/tmp/b1-aligned")
    aligned_dir.mkdir(exist_ok=True)
    for c in only:
        spec = ROOT / "docs" / "spec" / f"{c}.json"
        # 1. align into a temp dir
        run(["bal", "openapi", "align", "-i", str(spec), "-o", str(aligned_dir),
             "-n", c, "-f", "json"])
        aligned = aligned_dir / f"{c}.json"
        # 2. verb-first CRUD operationIds
        flipped = rewrite_operation_ids(aligned)
        # 3. overwrite committed spec so it matches the connector
        spec.write_text(aligned.read_text())
        # 4. regenerate client
        cdir = ROOT / "ballerina" / c
        run(["bal", "openapi", "-i", str(spec), "--mode", "client",
             "--client-methods", "remote"], cwd=str(cdir))
        # 5. sanitize
        run(["python3", str(ROOT / "tools" / "sanitize_connector.py"), str(cdir)])
        print(f"{c}: aligned, {flipped} CRUD ops flipped, regenerated, sanitized")


if __name__ == "__main__":
    main()
