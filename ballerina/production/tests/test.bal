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
import ballerinax/sap.businessone.production.mock as _;

import ballerina/log;
import ballerina/os;
import ballerina/test;

// Tests run against the bundled mock Service Layer by default. Set B1_SERVICE_URL
// (and B1_COMPANY_DB / B1_USERNAME / B1_PASSWORD) to run them against a live
// Service Layer instead.
final boolean isLiveServer = os:getEnv("B1_SERVICE_URL") != "";

final string serviceUrl = isLiveServer ? os:getEnv("B1_SERVICE_URL") : "https://localhost:9102/b1s/v1";
final string companyDb = isLiveServer ? os:getEnv("B1_COMPANY_DB") : "TEST_DB";
final string username = isLiveServer ? os:getEnv("B1_USERNAME") : "tester";
final string password = isLiveServer ? os:getEnv("B1_PASSWORD") : "secret";

Client b1 = test:mock(Client);

@test:BeforeSuite
function initializeClient() returns error? {
    if isLiveServer {
        log:printInfo("Running production connector tests against a live Service Layer");
        b1 = check new ({companyDb, username, password}, {secureSocket: {enable: false}}, serviceUrl);
    } else {
        log:printInfo("Running production connector tests against the mock Service Layer");
        // Trust the mock's shared self-signed certificate.
        b1 = check new ({companyDb, username, password}, {secureSocket: {cert: "../resources/public.crt"}}, serviceUrl);
    }
}

@test:Config {}
function testList() returns error? {
    ProductTrees_CollectionResponse response = check b1->productTreesList();
    test:assertTrue(response.value !is (), "expected a collection response");
    if !isLiveServer {
        test:assertEquals((response.value ?: []).length(), 1);
    }
}

@test:AfterSuite
function tearDown() returns error? {
    check b1->logout();
}
