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
import ballerinax/sap.businessone.sales;

// Supplied through Config.toml — never hardcode credentials.
configurable string serviceUrl = ?;
configurable string companyDb = ?;
configurable string username = ?;
configurable string password = ?;

// Lists the most recent open sales orders with their totals (read-only).
public function main() returns error? {
    sales:Client b1 = check new (
        {companyDb, username, password},
        // TLS verification is disabled for development servers with
        // self-signed certificates. Remove `secureSocket` for production.
        {secureSocket: {enable: false}},
        serviceUrl
    );

    sales:Orders_CollectionResponse orders = check b1->ordersList(queries = {
        \$filter: "DocumentStatus eq 'bost_Open'",
        \$select: "DocEntry,DocNum,CardCode,CardName,DocDate,DocDueDate,DocTotal,DocCurrency",
        \$orderby: "DocDate desc",
        \$top: 20
    });

    io:println("Open sales orders:");
    foreach sales:Document doc in orders.value ?: [] {
        io:println(string `  #${doc.DocNum ?: 0} | ${doc.DocDate ?: ""} | due ${doc.DocDueDate ?: ""} | ` +
                string `${doc.CardCode ?: ""} ${doc.CardName ?: ""} | ${doc.DocTotal ?: 0d} ${doc.DocCurrency ?: ""}`);
    }
    // The Service Layer session expires on its own (default 30 minutes), so an
    // explicit `b1->logout()` is optional for a short-lived script like this.
}
