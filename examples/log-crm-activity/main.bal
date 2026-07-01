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
import ballerina/time;
import ballerinax/sap.businessone.crm;

// Supplied through Config.toml — never hardcode credentials.
configurable string serviceUrl = ?;
configurable string companyDb = ?;
configurable string username = ?;
configurable string password = ?;

// Creates a harmless CRM note activity and reads it back (create + read only).
public function main() returns error? {
    crm:Client b1 = check new (
        {companyDb, username, password},
        // TLS verification is disabled for development servers with
        // self-signed certificates. Remove `secureSocket` for production.
        {secureSocket: {enable: false}},
        serviceUrl
    );

    string today = time:utcToCivil(time:utcNow()).year.toString() + "-" +
            time:utcToCivil(time:utcNow()).month.toString().padStart(2, "0") + "-" +
            time:utcToCivil(time:utcNow()).day.toString().padStart(2, "0");

    crm:Activity created = check b1->createActivities({
        Activity: "cn_Note",
        ActivityDate: today,
        Details: "Logged from the Ballerina sap.businessone.crm connector",
        Notes: "Connectivity test note — safe to delete."
    });
    io:println(string `Created activity #${created.ActivityCode ?: 0}`);

    crm:Activity fetched = check b1->getActivities(created.ActivityCode ?: 0, queries = {
        dollarSelect: "ActivityCode,Activity,ActivityDate,Details,Notes"
    });
    io:println(string `Read back: [${fetched.ActivityDate ?: ""}] ${fetched.Details ?: ""} — ${fetched.Notes ?: ""}`);
    // The Service Layer session expires on its own (default 30 minutes), so an
    // explicit `b1->logout()` is optional for a short-lived script like this.
}
