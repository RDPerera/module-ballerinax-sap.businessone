// Copyright (c) 2026, WSO2 LLC. (http://www.wso2.org).
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
import sap.businessone.mock as _;

import ballerina/http;
import ballerina/test;

const string MOCK_URL = "http://localhost:9091/b1s/v1";

final http:Client controlClient = check new ("http://localhost:9091");

type Item record {
    string ItemCode?;
    string ItemName?;
    decimal QuantityOnStock?;
};

type ItemsEnvelope record {
    Item[] value?;
};

@test:Config {}
function testGetWithDataBinding() returns error? {
    Client b1 = check new (MOCK_URL, {companyDb: "TEST_DB", username: "tester", password: "secret"});
    ItemsEnvelope items = check b1->get("/Items");
    test:assertEquals((items.value ?: []).length(), 2, "expected two mock items");
    test:assertEquals((items.value ?: [])[0].ItemCode, "A00001");
}

@test:Config {}
function testGetWithQueryParamsKeepsSession() returns error? {
    // Regression guard: session cookies must be attached on requests that
    // carry query strings (the http module cookie store fails to do this for
    // path-scoped cookies, which is why the client manages cookies itself).
    Client b1 = check new (MOCK_URL, {companyDb: "TEST_DB", username: "tester", password: "secret"});
    ItemsEnvelope items = check b1->/Items(targetType = ItemsEnvelope, \$top = 2, \$select = "ItemCode");
    test:assertEquals((items.value ?: []).length(), 2);
}

@test:Config {}
function testGetSingleByODataKey() returns error? {
    Client b1 = check new (MOCK_URL, {companyDb: "TEST_DB", username: "tester", password: "secret"});
    Item item = check b1->get("/Items('A00001')");
    test:assertEquals(item.ItemName, "Mock Printer");
}

@test:Config {}
function testPostEcho() returns error? {
    Client b1 = check new (MOCK_URL, {companyDb: "TEST_DB", username: "tester", password: "secret"});
    Item created = check b1->post("/Items", {ItemCode: "N10001", ItemName: "New Item"});
    test:assertEquals(created.ItemCode, "N10001");
}

@test:Config {}
function testLoginFailure() returns error? {
    Client b1 = check new (MOCK_URL, {companyDb: "TEST_DB", username: "tester", password: "wrong"});
    ItemsEnvelope|ClientError items = b1->get("/Items");
    test:assertTrue(items is LoginFailure, "expected a LoginFailure error");
    if items is error {
        test:assertTrue(items.message().includes("401"), "expected the 401 status in the error message");
    }
}

@test:Config {}
function testSessionExpiryTriggersRelogin() returns error? {
    Client b1 = check new (MOCK_URL, {companyDb: "TEST_DB", username: "tester", password: "secret"});
    ItemsEnvelope _ = check b1->get("/Items");
    record {int count;} before = check controlClient->get("/control/loginCount");

    // Invalidate the session server-side; the next call must transparently
    // re-login and replay the request.
    http:Response _ = check controlClient->post("/control/expire", ());
    ItemsEnvelope items = check b1->get("/Items");
    test:assertEquals((items.value ?: []).length(), 2);

    record {int count;} after = check controlClient->get("/control/loginCount");
    test:assertEquals(after.count, before.count + 1, "expected exactly one re-login");
}

@test:Config {}
function testHead() returns error? {
    Client b1 = check new (MOCK_URL, {companyDb: "TEST_DB", username: "tester", password: "secret"});
    http:Response res = check b1->head("/Items");
    test:assertEquals(res.statusCode, 200);
}

@test:Config {}
function testLogout() returns error? {
    Client b1 = check new (MOCK_URL, {companyDb: "TEST_DB", username: "tester", password: "secret"});
    ItemsEnvelope _ = check b1->get("/Items");
    check b1->logout();
    // A further call simply starts a fresh session.
    ItemsEnvelope items = check b1->get("/Items");
    test:assertEquals((items.value ?: []).length(), 2);
}
