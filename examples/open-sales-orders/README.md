# Open sales orders report

This example uses the `ballerinax/sap.businessone.sales` connector to query the open sales orders (A/R orders)
from an SAP Business One company and print a short report of each order's customer, dates, and total.

## Overview

The [SAP Business One Service Layer](https://help.sap.com/docs/SAP_BUSINESS_ONE_ONE_BRANCH) exposes sales
documents through an OData web service. This example logs in to the Service Layer with a session, runs a single
filtered query against the `Orders` entity set — selecting only the fields it needs, restricting to documents whose
`DocumentStatus` is `bost_Open`, sorting by document date, and capping the result at 20 rows — and prints each
returned order. It is a read-only example: it creates and changes nothing in the company database.

## Prerequisites

### 1. Set up the SAP Business One Service Layer

You need access to an SAP Business One installation with the Service Layer component enabled. The Service Layer
endpoint is typically `https://<host>:50000/b1s/v1`. You also need a Business One user with a valid license and
read authorization for marketing documents, and the name of the company database (schema) to connect to.

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
Open sales orders:
  #1173 | 2026-08-13T00:00:00Z | due 2026-08-20T00:00:00Z | C42000 Mashina Corporation | 10696.73 $
  #1174 | 2026-08-13T00:00:00Z | due 2026-08-20T00:00:00Z | C99998 Web Customer | 43561.0 $
  #1170 | 2026-08-10T00:00:00Z | due 2026-08-17T00:00:00Z | C42000 Mashina Corporation | 7579.0 $
```
