#!/usr/bin/env python3
"""Post-process a `bal openapi` generated client so it uses the
ballerinax/sap.businessone session-auth wrapper instead of a plain
http:Client with the (unsupported) cookie ApiKeysConfig.

Usage: sanitize_connector.py <connector-dir> <group-name>
Also writes the package Ballerina.toml. Idempotent: re-run after regeneration.
"""
import re
import sys
from pathlib import Path

WRAPPER_VERSION = "1.0.0"

GROUP_TITLES = {
    "administration": "Administration & Setup",
    "financials": "Financials",
    "fixedassets": "Fixed Assets",
    "businesspartners": "Business Partners",
    "crm": "CRM (Activities, Campaigns & Opportunities)",
    "sales": "Sales (A/R)",
    "purchasing": "Purchasing (A/P)",
    "banking": "Banking & Payments",
    "inventory": "Inventory",
    "production": "Production & MRP",
    "projects": "Project Management",
    "service": "Service",
    "humanresources": "Human Resources",
    "localization": "Localization & Electronic Documents",
}

def sanitize_client(path):
    src = path.read_text()
    if "ballerinax/sap.businessone" in src:
        return  # already sanitized
    src = src.replace(
        "import ballerina/http;",
        "import ballerina/http;\nimport ballerinax/sap.businessone;", 1)
    src = src.replace(
        "    final http:Client clientEp;\n    final readonly & ApiKeysConfig apiKeyConfig;",
        "    final businessone:Client clientEp;")
    src = src.replace(
        "    # + apiKeyConfig - API keys for authorization \n",
        "    # + session - SAP Business One Service Layer session credentials \n")
    src = re.sub(
        r"public isolated function init\(ApiKeysConfig apiKeyConfig, ",
        "public isolated function init(businessone:SessionConfig session, ", src)
    src = src.replace(
        "        self.clientEp = check new (serviceUrl, httpClientConfig);\n"
        "        self.apiKeyConfig = apiKeyConfig.cloneReadOnly();\n",
        "        self.clientEp = check new (serviceUrl, session, httpClientConfig);\n")
    path.write_text(src)

def add_logout(path):
    """Expose the wrapper's logout() on the generated client (appended as the
    last method of the client class)."""
    src = path.read_text()
    if "remote isolated function logout" in src:
        return
    src = src.rstrip()
    assert src.endswith("}"), "unexpected client.bal ending"
    src = src[:-1].rstrip() + """

    # Ends the active SAP Business One Service Layer session.
    #
    # + return - An error if the logout failed
    remote isolated function logout() returns error? {
        return self.clientEp->logout();
    }
}
"""
    path.write_text(src)

def document_payload_params(path):
    """The generator omits the doc line for `payload` parameters, producing
    'undocumented parameter' warnings on every build. Insert one into each
    affected function's doc block."""
    lines = path.read_text().splitlines(keepends=True)
    out = []
    import re as _re
    func_re = _re.compile(r"^    remote isolated function \w+\([^)]*\bpayload\b")
    for i, line in enumerate(lines):
        if func_re.match(line):
            # locate this function's doc block in `out`
            block_start = len(out)
            while block_start > 0 and out[block_start - 1].lstrip().startswith("#"):
                block_start -= 1
            block = out[block_start:]
            if not any("+ payload -" in b for b in block):
                insert_at = None
                for j in range(block_start, len(out)):
                    if out[j].startswith("    # + headers") or out[j].startswith("    # + return"):
                        insert_at = j
                        break
                if insert_at is None:
                    insert_at = len(out)
                out.insert(insert_at, "    # + payload - Request payload \n")
        out.append(line)
    path.write_text("".join(out))

def sanitize_types(path):
    src = path.read_text()
    src = re.sub(
        r"\n# Provides API key configurations needed when communicating with a remote HTTP endpoint\.\n"
        r"public type ApiKeysConfig record \{\|\n"
        r"(?:.*\n)*?\|\};\n",
        "\n", src, count=1)
    path.write_text(src)

def write_toml(cdir, group):
    toml = cdir / "Ballerina.toml"
    toml.write_text(f'''[package]
org = "ballerinax"
name = "sap.businessone.{group}"
version = "1.0.0"
distribution = "2201.13.0"
authors = ["Ballerina"]
keywords = ["Business Management/ERP", "Cost/Paid", "Vendor/SAP", "Area/ERP & Business Operations", "Type/Connector"]
repository = "https://github.com/ballerina-platform/module-ballerinax-sap.businessone"
icon = "../icon.png"
license = ["Apache-2.0"]

[build-options]
observabilityIncluded = true

# Dev-time only: resolve the wrapper from the local repository until it is
# published to Ballerina Central. Remove `repository` for release builds.
[[dependency]]
org = "ballerinax"
name = "sap.businessone"
version = "{WRAPPER_VERSION}"
repository = "local"
''')

def write_readme(cdir, group):
    readme = cdir / "README.md"
    if readme.exists():
        return
    title = GROUP_TITLES[group]
    readme.write_text(
        f"# Ballerina SAP Business One {title} Connector\n\n"
        f"[ballerinax/sap.businessone.{group}](https://central.ballerina.io/ballerinax/"
        f"sap.businessone.{group}/latest) provides typed access to the {title} entity sets "
        f"and service operations of the SAP Business One Service Layer (OData V3).\n\n"
        f"Authentication is session based and handled transparently by the underlying "
        f"[ballerinax/sap.businessone](https://central.ballerina.io/ballerinax/sap.businessone/latest) "
        f"client: configure the company database, user name, and password; the connector "
        f"logs in, tracks the `B1SESSION`/`ROUTEID` cookies, and re-logs in once on session expiry.\n")

def main():
    cdir = Path(sys.argv[1])
    group = sys.argv[2]
    sanitize_client(cdir / "client.bal")
    add_logout(cdir / "client.bal")
    document_payload_params(cdir / "client.bal")
    sanitize_types(cdir / "types.bal")
    write_toml(cdir, group)
    write_readme(cdir, group)
    print(f"sanitized {cdir.name} -> ballerinax/sap.businessone.{group}")

if __name__ == "__main__":
    main()
