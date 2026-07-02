#!/usr/bin/env python3
"""Add a type-level `description` to every schema in the connector specs that
lacks one, so `bal openapi` emits a documentation comment for each public type.

The SAP Business One Service Layer `$metadata` provides no descriptions for
entity/complex types, so we synthesise them from the EDMX type kind (EntityType
vs ComplexType) and the schema name.

Run from the repo root:  python3 tools/add_descriptions.py
"""
import json
import re
import xml.etree.ElementTree as ET
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
METADATA = Path("/Users/dilanperera/Desktop/SAP B1/metadata.xml")
EDM = "{http://schemas.microsoft.com/ado/2009/11/edm}"


def load_kinds():
    """name-without-underscores -> (original name, kind) from the EDMX."""
    sch = ET.parse(METADATA).getroot().find(f".//{EDM}Schema")
    kinds = {}
    for e in sch.findall(f"{EDM}EntityType"):
        n = e.get("Name")
        kinds[n.replace("_", "")] = (n, "entity")
    for c in sch.findall(f"{EDM}ComplexType"):
        n = c.get("Name")
        kinds.setdefault(n.replace("_", ""), (n, "complex"))
    return kinds


def describe(name, kinds):
    if name.endswith("CollectionResponse"):
        base = name[: -len("CollectionResponse")]
        return f"A paged collection of `{base}` entities returned by the SAP Business One Service Layer."
    hit = kinds.get(name.replace("_", ""))
    if hit:
        orig, kind = hit
        noun = "entity" if kind == "entity" else "complex type"
        return f"The `{orig}` {noun} of the SAP Business One Service Layer."
    if name.endswith("Params") or name.endswith("_body"):
        return f"Represents the `{name}` request payload of the SAP Business One Service Layer."
    return f"Represents the `{name}` type of the SAP Business One Service Layer."


def main():
    kinds = load_kinds()
    for spec_path in sorted((ROOT / "docs" / "spec").glob("*.json")):
        spec = json.loads(spec_path.read_text())
        added = 0
        for name, schema in spec.get("components", {}).get("schemas", {}).items():
            if not isinstance(schema, dict):
                continue
            # only object/record schemas without a description (enums already have one)
            if "enum" in schema or schema.get("description"):
                continue
            if schema.get("type") == "object" or "properties" in schema:
                schema["description"] = describe(name, kinds)
                added += 1
        # inline request-body object schemas (generate the `<op>_body` records)
        for path, item in spec.get("paths", {}).items():
            for method, op in item.items():
                if not isinstance(op, dict):
                    continue
                sc = (op.get("requestBody", {}) or {}).get("content", {}) \
                    .get("application/json", {}).get("schema", {})
                if isinstance(sc, dict) and not sc.get("description") \
                        and (sc.get("type") == "object" or "properties" in sc) \
                        and "$ref" not in sc:
                    opid = op.get("operationId", "operation")
                    sc["description"] = (
                        f"Represents the request payload for the `{opid}` "
                        f"operation of the SAP Business One Service Layer.")
                    added += 1
                # inline response object schemas (generate `inline_response_*`)
                for resp in (op.get("responses", {}) or {}).values():
                    if not isinstance(resp, dict):
                        continue
                    rsc = resp.get("content", {}).get("application/json", {}).get("schema", {})
                    if isinstance(rsc, dict) and not rsc.get("description") \
                            and (rsc.get("type") == "object" or "properties" in rsc) \
                            and "$ref" not in rsc:
                        opid = op.get("operationId", "operation")
                        rsc["description"] = (
                            f"Represents the response payload for the `{opid}` "
                            f"operation of the SAP Business One Service Layer.")
                        added += 1
        spec_path.write_text(json.dumps(spec, indent=2) + "\n")
        print(f"{spec_path.stem}: added {added} descriptions")


if __name__ == "__main__":
    main()
