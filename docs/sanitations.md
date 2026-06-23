# SAP Business One OpenAPI Specification Sanitization

_Document version: 1.0.0_

The SAP Business One connectors are generated from per-module OpenAPI 3.0 specifications that are derived from
the SAP Business One Service Layer OData V3 `$metadata`. A single Service Layer exposes more than 1,400 paths and
1,800 schemas across every business area, so the specification is split into one OpenAPI document per business
module (`docs/spec/<module>.json`) before generation, and the generated client code is post-processed so that it
authenticates through the session-handling wrapper (`ballerinax/sap.businessone`) instead of a plain HTTP client.

The specification split and pruning are performed by [`split_oas.py`](../split_oas.py). The generated-code
sanitizations are performed by [`tools/sanitize_connector.py`](../tools/sanitize_connector.py). Both are
idempotent and can be re-run after regenerating from an updated `$metadata`.

## Sanitization Steps (OpenAPI specification)

1. **Split the Service Layer specification by business module.** The full Service Layer specification is
   partitioned into 14 self-contained OpenAPI documents, one per SAP Business One module (`administration`,
   `financials`, `fixedassets`, `businesspartners`, `crm`, `sales`, `purchasing`, `banking`, `inventory`,
   `production`, `projects`, `service`, `humanresources`, `localization`). Every path is assigned to exactly one
   module; `<Entity>Service_<Action>` function-import paths inherit the module of their base entity set. The split
   is a complete, non-overlapping partition — no path or operation is dropped or duplicated.

2. **Carry the transitive schema closure into each module.** Each module specification includes only the schemas
   its own paths reference, plus the transitive closure of schemas those reference, so every `$ref` resolves
   within the document and no module carries unused types.

3. **Prune cross-module navigation properties.** The Service Layer entity graph is a single strongly connected
   component through OData navigation properties (for example, `Warehouse` → `BusinessPartner` → … reaches almost
   every entity), which would otherwise pull the entire ~1,800-schema graph into every module. Navigation
   properties whose target entity type is owned by another module are dropped from each module's schemas, so a
   module carries only its own entities and their data fields. Data properties and same-module navigations are
   left untouched.

4. **Preserve OData key and quoting conventions.** Entity-set item paths keep their OData key syntax — single
   string-like keys are quoted (`/UserDefaultGroups('{Code}')`) and numeric keys are not (`/Orders({DocEntry})`) —
   so the generated resource paths address entities exactly as the Service Layer expects.

## Sanitization for the SAP Business One OpenAPI Generated Client

These steps are applied to the `bal openapi` generated client by `tools/sanitize_connector.py`:

1. **Replace the transport client with the session-auth wrapper.** The generated `http:Client clientEp` field and
   its `ApiKeysConfig` (a cookie-as-API-key placeholder the generator emits for the session cookie) are replaced
   with `final businessone:Client clientEp`. The `init` parameter `ApiKeysConfig apiKeyConfig` becomes
   `businessone:SessionConfig session`, and the client is constructed as
   `new (serviceUrl, session, httpClientConfig)`. The unusable `ApiKeysConfig` record is removed from the
   generated types. This routes every request through `ballerinax/sap.businessone`, which logs in, attaches the
   `B1SESSION`/`ROUTEID` session cookies, and transparently re-logs in once on session expiry.

2. **Expose `logout()` on the connector.** A `remote isolated function logout()` that delegates to
   `self.clientEp->logout()` is appended to the generated client, so callers can end the Service Layer session
   explicitly.

3. **Document `payload` parameters.** The generator omits the documentation line for request `payload`
   parameters, which produces `undocumented parameter` warnings on every build. A `# + payload - Request payload`
   line is inserted into each affected function's doc comment so the packages build without documentation
   warnings.

The package `Ballerina.toml`, `README.md` (from `docs.json` via the `updateDocumentationFiles` Gradle task), and
the shared `icon.png` reference are also written during sanitization.

## Process to Create or Regenerate a Connector

1. Obtain the Service Layer `$metadata` and the OpenAPI specification derived from it (`openapi.json`).
2. Run `python3 split_oas.py --prune` to regenerate the per-module specifications under `subspecs-pruned/`.
3. Copy the relevant module specification to `docs/spec/<module>.json`.
4. Generate the client:
   `bal openapi -i docs/spec/<module>.json --mode client --client-methods remote` in `ballerina/<module>`.
5. Run `python3 tools/sanitize_connector.py ballerina/<module> <module>` to apply the generated-client
   sanitizations and write the package files.
6. If adding a brand-new module, register it in `tools/write_gradle_files.py` (`GROUPS`) and re-run it, and add a
   `docs.json` for the README generation.
7. Build and test the package: `./gradlew :businessone-ballerina:<module>:build`.
