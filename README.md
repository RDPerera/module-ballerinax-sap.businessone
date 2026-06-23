# Ballerina SAP Business One Connectors

[![Build](https://github.com/RDPerera/module-ballerinax-sap.businessone/actions/workflows/ci.yml/badge.svg)](https://github.com/RDPerera/module-ballerinax-sap.businessone/actions/workflows/ci.yml)
[![GitHub Last Commit](https://img.shields.io/github/last-commit/RDPerera/module-ballerinax-sap.businessone.svg)](https://github.com/RDPerera/module-ballerinax-sap.businessone/commits/main)
[![GitHub Issues](https://img.shields.io/github/issues/ballerina-platform/ballerina-library/module/sap.businessone.svg?label=Open%20Issues)](https://github.com/ballerina-platform/ballerina-library/labels/module%2Fsap.businessone)
[![License](https://img.shields.io/badge/License-Apache_2.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)

This repository hosts the [Ballerina](https://ballerina.io/) connector family for the
[SAP Business One Service Layer](https://help.sap.com/docs/SAP_BUSINESS_ONE_ONE_BRANCH) (OData V3). The Service
Layer exposes the SAP Business One business objects through an OData web service, and these connectors provide
typed Ballerina clients for them, grouped by business module.

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

Each connector's `README.md` contains an overview, a setup guide, and a quickstart. The module connectors are
generated from per-module OpenAPI specifications (under [`docs/spec`](docs/spec)) that are derived from the
Service Layer `$metadata` and post-processed so the generated clients use the session-auth wrapper.

## Build options

Execute the commands below to build from the source.

1. To build all packages:

   ```bash
   ./gradlew clean build
   ```

2. To run the tests in all packages:

   ```bash
   ./gradlew clean test
   ```

3. To build without the tests:

   ```bash
   ./gradlew clean build -x test
   ```

4. To build only one specific package:

   ```bash
   ./gradlew clean :businessone-ballerina:<package>:build
   ```

   | Package          | Connector                                   |
   |------------------|---------------------------------------------|
   | businessone      | ballerinax/sap.businessone                  |
   | administration   | ballerinax/sap.businessone.administration   |
   | financials       | ballerinax/sap.businessone.financials       |
   | fixedassets      | ballerinax/sap.businessone.fixedassets      |
   | businesspartners | ballerinax/sap.businessone.businesspartners |
   | crm              | ballerinax/sap.businessone.crm              |
   | sales            | ballerinax/sap.businessone.sales            |
   | purchasing       | ballerinax/sap.businessone.purchasing       |
   | banking          | ballerinax/sap.businessone.banking          |
   | inventory        | ballerinax/sap.businessone.inventory        |
   | production       | ballerinax/sap.businessone.production       |
   | projects         | ballerinax/sap.businessone.projects         |
   | service          | ballerinax/sap.businessone.service          |
   | humanresources   | ballerinax/sap.businessone.humanresources   |
   | localization     | ballerinax/sap.businessone.localization     |

5. To run tests against a live Service Layer instead of the mock:

   ```bash
   B1_SERVICE_URL="https://<host>:50000/b1s/v1" B1_COMPANY_DB="<db>" \
     B1_USERNAME="<user>" B1_PASSWORD="<password>" ./gradlew clean test
   ```

   **Note**: When `B1_SERVICE_URL` is unset, tests run against the bundled mock Service Layer.

6. To debug packages with a remote debugger:

   ```bash
   ./gradlew clean build -Pdebug=<port>
   ```

7. To debug with the Ballerina language:

   ```bash
   ./gradlew clean build -PbalJavaDebug=<port>
   ```

8. Publish the generated artifacts to the local Ballerina Central repository:

   ```bash
   ./gradlew clean build -PpublishToLocalCentral=true
   ```

9. Publish the generated artifacts to the Ballerina Central repository:

   ```bash
   ./gradlew clean build -PpublishToCentral=true
   ```

## Contribute to Ballerina

As an open-source project, Ballerina welcomes contributions from the community.

For more information, go to the [contribution guidelines](https://github.com/ballerina-platform/ballerina-lang/blob/master/CONTRIBUTING.md).

## Code of conduct

All the contributors are encouraged to read the [Ballerina Code of Conduct](https://ballerina.io/code-of-conduct).

## Useful links

* For more information go to the [`sap.businessone` package](https://central.ballerina.io/ballerinax/sap.businessone/latest).
* For example demonstrations of the usage, go to [Ballerina By Examples](https://ballerina.io/learn/by-example/).
* Chat live with us via our [Discord server](https://discord.gg/ballerinalang).
* Post all technical questions on Stack Overflow with the [#ballerina](https://stackoverflow.com/questions/tagged/ballerina) tag.

## Issues and projects

The **Issues** and **Projects** tabs are disabled for this repository as this is part of the Ballerina library. To
report bugs, request new features, start new discussions, view project boards, etc., visit the Ballerina
library [parent repository](https://github.com/ballerina-platform/ballerina-library).

This repository only contains the source code for the package.
