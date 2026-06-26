# Examples

Each example is a standalone Ballerina project that talks to the SAP Business One Service Layer
through the `ballerinax/sap.businessone.*` connectors.

| Example | Connector | What it does |
|---|---|---|
| [open-sales-orders](open-sales-orders) | `sap.businessone.sales` | Lists the latest open sales orders (read-only) |
| [inventory-stock-report](inventory-stock-report) | `sap.businessone.inventory` | Prints warehouses and top items by stock (read-only) |
| [log-crm-activity](log-crm-activity) | `sap.businessone.crm` | Creates a CRM note activity and reads it back |

## Running an example

1. Make sure the connectors are in your local Ballerina repository (one-time, from the repo root):

   ```sh
   ./gradlew build
   ```

2. Copy the credentials template and fill in your Service Layer details:

   ```sh
   cd examples/open-sales-orders
   cp Config.toml.template Config.toml
   # edit Config.toml
   ```

   `Config.toml` is gitignored. **Never commit credentials** — they live only in `Config.toml`,
   never in source code.

3. Run it:

   ```sh
   bal run
   ```

> The Service Layer endpoint (`https://<host>:50000/b1s/v1`) is usually reachable only from
> inside the network/VPN that hosts SAP Business One.
