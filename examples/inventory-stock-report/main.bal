// Copyright (c) 2026, WSO2 LLC. (http://www.wso2.com).
//
// WSO2 LLC. licenses this file to you under the Apache License,
// Version 2.0 (the "License"); you may not use this file except
// in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing,
// software distributed under the License is distributed on an
// "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
// KIND, either express or implied.  See the License for the
// specific language governing permissions and limitations
// under the License.

import ballerina/io;
import ballerinax/sap.businessone.inventory;

// Supplied through Config.toml — never hardcode credentials.
configurable string serviceUrl = ?;
configurable string companyDb = ?;
configurable string username = ?;
configurable string password = ?;

// Prints warehouses and the items with the highest stock (read-only).
public function main() returns error? {
    inventory:Client b1 = check new (
        {companyDb, username, password},
        // TLS verification is disabled for development servers with
        // self-signed certificates. Remove `secureSocket` for production.
        {secureSocket: {enable: false}},
        serviceUrl
    );

    inventory:Warehouses_CollectionResponse warehouses = check b1->warehousesList(queries = {
        \$select: "WarehouseCode,WarehouseName",
        \$top: 50
    });
    io:println("Warehouses:");
    foreach inventory:Warehouse wh in warehouses.value ?: [] {
        io:println(string `  ${wh.WarehouseCode ?: ""} — ${wh.WarehouseName ?: ""}`);
    }

    inventory:Items_CollectionResponse items = check b1->itemsList(queries = {
        \$select: "ItemCode,ItemName,QuantityOnStock,QuantityOrderedFromVendors",
        \$orderby: "QuantityOnStock desc",
        \$top: 20
    });
    io:println("\nTop items by quantity on stock:");
    foreach inventory:Item item in items.value ?: [] {
        io:println(string `  ${item.ItemCode ?: ""} | ${item.ItemName ?: ""} | on stock: ${item.QuantityOnStock ?: 0d} ` +
                string `| on order: ${item.QuantityOrderedFromVendors ?: 0d}`);
    }
    // The Service Layer session expires on its own (default 30 minutes), so an
    // explicit `b1->logout()` is optional for a short-lived script like this.
}
