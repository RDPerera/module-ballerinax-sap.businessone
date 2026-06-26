## Overview

[SAP Business One](https://www.sap.com/products/erp/business-one.html) is an enterprise resource planning (ERP)
solution designed for small and midsize businesses by SAP SE. Its
[Service Layer](https://help.sap.com/docs/SAP_BUSINESS_ONE_ONE_BRANCH) exposes the Business One business objects
through an OData web service interface.

The SAP Business One Sales (A/R) connector provides APIs for the sales (A/R) documents of SAP Business One: quotations, orders, deliveries, returns, invoices, credit memos, and dunning, exposed through the [SAP Business One Service Layer](https://help.sap.com/docs/SAP_BUSINESS_ONE_ONE_BRANCH) (OData).

### Key Features

- Create, read, update, close, and cancel sales documents
- Work with document lines, expenses, and serial/batch allocations
- Manage blanket agreements and sales tax invoices
- Drive document flows such as order-to-invoice

## Setup guide

The connector requires an SAP Business One installation with the Service Layer component enabled (available for
SAP Business One, version for SAP HANA, and SAP Business One on Microsoft SQL Server 9.3 PL10+). The Service Layer
endpoint is `https://<host>:50000/b1s/v1` by default. A Business One user with a license and the relevant object
authorizations is needed; sessions are opened against a specific company database (schema).

## Quickstart

To use the `sap.businessone.sales` connector in your Ballerina application, modify the `.bal` file as follows:

### Step 1: Import the module

```ballerina
import ballerinax/sap.businessone.sales;
```

### Step 2: Instantiate a new connector

The connector authenticates with the Service Layer session protocol: it logs in with the configured company
database, user name, and password, tracks the `B1SESSION`/`ROUTEID` cookies, and transparently re-logs in once
when the session expires. Place the credentials in a `Config.toml` (never commit credentials to source control):

```toml
serviceUrl = "https://<host>:50000/b1s/v1"
companyDb = "<COMPANY_DB>"
username = "<USER>"
password = "<PASSWORD>"
```

```ballerina
configurable string serviceUrl = ?;
configurable string companyDb = ?;
configurable string username = ?;
configurable string password = ?;

sales:Client b1Client = check new (
    {companyDb, username, password},
    serviceUrl = serviceUrl
);
```

### Step 3: Invoke the connector operation

```ballerina
sales:Orders_CollectionResponse response = check b1Client->ordersList();
```

### Step 4: Run the Ballerina application

```bash
bal run
```

## Examples

The SAP Business One connectors provide practical examples illustrating usage in various scenarios. Explore these
[examples](https://github.com/ballerina-platform/module-ballerinax-sap.businessone/tree/main/examples), covering
use cases like listing open sales orders, reporting inventory stock, and logging CRM activities.
