# Ballerina SAP Business One Connectors

[![Build](https://github.com/ballerina-platform/module-ballerinax-sap.businessone/actions/workflows/ci.yml/badge.svg)](https://github.com/ballerina-platform/module-ballerinax-sap.businessone/actions/workflows/ci.yml)
[![License](https://img.shields.io/badge/License-Apache_2.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)

This repository hosts the [Ballerina](https://ballerina.io/) connector family for the
[SAP Business One Service Layer](https://help.sap.com/docs/SAP_BUSINESS_ONE_ONE_BRANCH) (OData V3).

## Packages

| Package | Directory | Description |
|---|---|---|
| `ballerinax/sap.businessone` | [`ballerina/businessone`](ballerina/businessone) | Session-authenticating HTTP client used by all module connectors |
| `ballerinax/sap.businessone.administration` | [`ballerina/administration`](ballerina/administration) | Administration & setup (users, approvals, queries, web client) |
| `ballerinax/sap.businessone.financials` | [`ballerina/financials`](ballerina/financials) | Chart of accounts, journal entries, budgets, tax setup |
| `ballerinax/sap.businessone.fixedassets` | [`ballerina/fixedassets`](ballerina/fixedassets) | Asset master data, depreciation, capitalization, retirement |
| `ballerinax/sap.businessone.businesspartners` | [`ballerina/businesspartners`](ballerina/businesspartners) | Business partners, contacts, payment terms |
| `ballerinax/sap.businessone.crm` | [`ballerina/crm`](ballerina/crm) | Activities, campaigns, sales opportunities |
| `ballerinax/sap.businessone.sales` | [`ballerina/sales`](ballerina/sales) | Sales (A/R) documents: orders, deliveries, invoices, returns |
| `ballerinax/sap.businessone.purchasing` | [`ballerina/purchasing`](ballerina/purchasing) | Purchasing (A/P) documents and landed costs |
| `ballerinax/sap.businessone.banking` | [`ballerina/banking`](ballerina/banking) | Payments, deposits, checks, bank statements, reconciliations |
| `ballerinax/sap.businessone.inventory` | [`ballerina/inventory`](ballerina/inventory) | Items, warehouses, stock transactions, price lists, batches/serials |
| `ballerinax/sap.businessone.production` | [`ballerina/production`](ballerina/production) | Bills of materials, production orders, resources, MRP forecasts |
| `ballerinax/sap.businessone.projects` | [`ballerina/projects`](ballerina/projects) | Project management, time sheets |
| `ballerinax/sap.businessone.service` | [`ballerina/service`](ballerina/service) | Service calls, contracts, equipment cards, knowledge base |
| `ballerinax/sap.businessone.humanresources` | [`ballerina/humanresources`](ballerina/humanresources) | Employees, teams, HR setup |
| `ballerinax/sap.businessone.localization` | [`ballerina/localization`](ballerina/localization) | Country-specific objects and electronic documents |

The module connectors are generated from per-module OpenAPI specifications (under [`docs/spec`](docs/spec))
that are derived from the Service Layer `$metadata` and post-processed so the generated clients use the
session-auth wrapper. The transformations applied to the specifications and the generated code are documented
in [`docs/sanitations.md`](docs/sanitations.md).

## Authentication

The Service Layer uses session-based authentication. All connectors take the session credentials at
initialization and delegate session handling (login, `B1SESSION`/`ROUTEID` cookies, re-login on expiry)
to `ballerinax/sap.businessone`:

```ballerina
import ballerinax/sap.businessone.sales;

public function main() returns error? {
    sales:Client b1 = check new (
        session = {companyDb: "SBODEMOUS", username: "manager", password: "..."},
        serviceUrl = "https://b1host:50000/b1s/v1"
    );
    sales:Documents_CollectionResponse openOrders = check b1->ordersList(filter = "DocumentStatus eq 'bost_Open'");
}
```

## Building from source

1. Install Java 21 and Ballerina 2201.13.0+.
2. Build the native session-client jar and all packages: `./gradlew build`.
3. To build a single connector locally before the wrapper is on Ballerina Central:
   push the wrapper to the local repository first
   (`cd ballerina/businessone && bal pack && bal push --repository=local`),
   then `bal pack` the connector (its `Ballerina.toml` resolves the wrapper from the local repository
   during development).

## Regenerating a connector

```sh
cd ballerina/<module>
bal openapi -i ../../docs/spec/<module>.json --mode client --client-methods remote
# then apply the sanitizations described in docs/sanitations.md
bal pack
```
