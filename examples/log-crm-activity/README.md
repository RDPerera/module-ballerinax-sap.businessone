# Log a CRM activity

This example uses the `ballerinax/sap.businessone.crm` connector to create a CRM activity (a note) in SAP Business
One and then read it back, demonstrating a round-trip create-and-fetch against the Service Layer.

## Overview

The [SAP Business One Service Layer](https://help.sap.com/docs/SAP_BUSINESS_ONE_ONE_BRANCH) exposes CRM objects
through an OData web service. This example logs in to the Service Layer with a session, creates a single
`Activity` of type `cn_Note` dated today, and then fetches the newly created activity back by its generated
`ActivityCode` to confirm it was persisted. The created note is harmless and safe to delete afterwards.

Unlike the read-only examples in this directory, this one **writes** a record to the company database (one CRM
activity). It does not delete anything.

## Prerequisites

### 1. Set up the SAP Business One Service Layer

You need access to an SAP Business One installation with the Service Layer component enabled. The Service Layer
endpoint is typically `https://<host>:50000/b1s/v1`. You also need a Business One user with a valid license and
authorization to create CRM activities, and the name of the company database (schema) to connect to.

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
Created activity #1842
Read back: [2026-06-12] Logged from the Ballerina sap.businessone.crm connector — Connectivity test note — safe to delete.
```
