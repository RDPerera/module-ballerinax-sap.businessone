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
import sap.businessone.sales.mock as _;

import ballerina/log;
import ballerina/os;
import ballerina/test;

// Tests run against the bundled mock Service Layer by default. Set
// B1_SERVICE_URL (and B1_COMPANY_DB / B1_USERNAME / B1_PASSWORD) to run the
// read-only tests against a live Service Layer instead.
final boolean isLiveServer = os:getEnv("B1_SERVICE_URL") != "";

final string serviceUrl = isLiveServer ? os:getEnv("B1_SERVICE_URL") : "https://localhost:9092/b1s/v1";
final string companyDb = isLiveServer ? os:getEnv("B1_COMPANY_DB") : "TEST_DB";
final string username = isLiveServer ? os:getEnv("B1_USERNAME") : "tester";
final string password = isLiveServer ? os:getEnv("B1_PASSWORD") : "secret";

Client b1 = test:mock(Client);

@test:BeforeSuite
function initializeClient() returns error? {
    if isLiveServer {
        log:printInfo("Running sales connector tests against a live Service Layer");
        b1 = check new ({companyDb, username, password}, {secureSocket: {enable: false}}, serviceUrl);
    } else {
        log:printInfo("Running sales connector tests against the mock Service Layer");
        // Trust the mock's shared self-signed certificate.
        b1 = check new ({companyDb, username, password}, {secureSocket: {cert: "../resources/public.crt"}}, serviceUrl);
    }
}

@test:Config {}
function testOrdersList() returns error? {
    Orders_CollectionResponse orders = check b1->ordersList(queries = {
        \$filter: "DocumentStatus eq 'bost_Open'",
        \$select: "DocEntry,DocNum,CardCode,CardName,DocTotal",
        \$top: 5
    });
    test:assertTrue((orders.value ?: []).length() > 0, "expected at least one open order");
    if !isLiveServer {
        test:assertEquals((orders.value ?: [])[0].DocNum, 1001);
    }
}

@test:Config {}
function testOrdersGetByKey() returns error? {
    if isLiveServer {
        return; // key 1 is only guaranteed on the mock
    }
    Document doc = check b1->ordersGet(1);
    test:assertEquals(doc.CardCode, "C20000");
    test:assertEquals((doc.DocumentLines ?: []).length(), 1);
    test:assertEquals((doc.DocumentLines ?: [])[0].ItemCode, "A00001");
}

@test:Config {enable: !isLiveServer}
function testOrdersCreate() returns error? {
    Document created = check b1->ordersCreate({
        CardCode: "C20000",
        DocDueDate: "2026-07-01",
        DocumentLines: [
            {ItemCode: "A00001", Quantity: 2.0}
        ]
    });
    test:assertEquals(created.DocEntry, 99);
    test:assertEquals(created.DocumentStatus, "bost_Open");
}

@test:Config {enable: !isLiveServer}
function testOrdersCloseAction() returns error? {
    check b1->ordersClose(1);
}

@test:Config {enable: !isLiveServer}
function testOrdersUpdate() returns error? {
    check b1->ordersUpdate(1, {Comments: "updated from test"});
}

@test:AfterSuite
function tearDown() returns error? {
    check b1->logout();
}
