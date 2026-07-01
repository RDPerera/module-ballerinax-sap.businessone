# Inventory stock report

This example uses the `ballerinax/sap.businessone.inventory` connector to list a company's warehouses and the
items with the highest stock on hand, producing a quick inventory snapshot.

## Overview

The [SAP Business One Service Layer](https://help.sap.com/docs/SAP_BUSINESS_ONE_ONE_BRANCH) exposes inventory
master data through an OData web service. This example logs in to the Service Layer with a session and runs two
read-only queries: it lists the `Warehouses` entity set, and it queries the `Items` entity set selecting the item
code, name, on-hand quantity, and quantity on order, sorted so the highest-stock items appear first. Each result is
printed to the console. Nothing is created or modified in the company database.

## Prerequisites

### 1. Set up the SAP Business One Service Layer

You need access to an SAP Business One installation with the Service Layer component enabled. The Service Layer
endpoint is typically `https://<host>:50000/b1s/v1`. You also need a Business One user with a valid license and
read authorization for inventory data, and the name of the company database (schema) to connect to.

### 2. Build the connectors

The connectors are resolved from the local Ballerina repository until they are published to Ballerina Central.
From the repository root, build and publish them once:

```bash
./gradlew build
```

### 3. Configuration

Copy the template and fill in your Service Layer details. `Config.toml` is gitignored — never commit credentials
to source control.

```bash
cp Config.toml.template Config.toml
```

```toml
serviceUrl = "https://<host>:50000/b1s/v1"
companyDb = "<COMPANY_DB>"
username = "<USER>"
password = "<PASSWORD>"
```

> The example disables TLS certificate verification (`secureSocket: {enable: false}`) because development Service
> Layer instances usually present a self-signed certificate. For production, remove that option (or supply the
> server certificate with `secureSocket: {cert: "<path>"}`) so certificates are verified.

## Run the example

```bash
bal run
```

## Sample output

```
Warehouses:
  01 — General Warehouse
  02 — West Cost Warehouse
  03 — Dropship Warehouse

Top items by quantity on stock:
  R00002 | Printer Paper A4 Recycled | on stock: 36168.0 | on order: 0.0
  R00001 | Printer Paper A4 White | on stock: 22950.0 | on order: 0.0
  A00002 | J.B. Officeprint 1111 | on stock: 1121.0 | on order: 0.0
```
