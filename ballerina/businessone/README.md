# Ballerina SAP Business One Connector

[ballerinax/sap.businessone](https://central.ballerina.io/ballerinax/sap.businessone/latest) is a generic HTTP client for the [SAP Business One Service Layer](https://help.sap.com/docs/SAP_BUSINESS_ONE_ONE_BRANCH/6e2367407c0b4d048272fdfb47b4207f) (OData V3).

It wraps `ballerina/http:Client` and transparently manages the Service Layer's session-based authentication:

- Logs in with the configured company database, user name, and password (`POST /Login`).
- Tracks the `B1SESSION` and `ROUTEID` cookies through the HTTP client's cookie store, so load-balanced Service Layer deployments work without extra configuration.
- When a request fails with HTTP 401 (session expired — the Service Layer default timeout is 30 minutes), the client re-logs in and replays the request once.
- `->logout()` ends the session explicitly.

This package is the transport used by the `ballerinax/sap.businessone.*` module connectors (e.g. `sap.businessone.sales`, `sap.businessone.inventory`). Use it directly when you need an endpoint or query shape the module connectors don't expose.

## Quickstart

```ballerina
import ballerinax/sap.businessone;

public function main() returns error? {
    businessone:Client b1 = check new ("https://localhost:50000/b1s/v1", {
        companyDb: "SBODEMOUS",
        username: "manager",
        password: "manager-password"
    });

    json orders = check b1->/Orders(headers = (), targetType = json, \$top = 5);
    check b1->logout();
}
```

## Setup

Any SAP Business One on-premise installation (or B1 Cloud) with the Service Layer component installed exposes the endpoint at `https://<host>:50000/b1s/v1`. A valid B1 user with appropriate license and authorizations is required.
