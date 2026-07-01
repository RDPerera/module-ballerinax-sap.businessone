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
import ballerina/http;

# Mock SAP Business One Service Layer exposing the Orders endpoints used by
# the sales connector tests. Session-protected like the real Service Layer.

const string SESSION = "mock-session";

isolated function hasSession(http:Request req) returns boolean {
    string|error cookies = req.getHeader("Cookie");
    return cookies is string && cookies.includes("B1SESSION=" + SESSION);
}

// Served over TLS with the shared self-signed certificate (ballerina/resources),
// so the mock mirrors the real Service Layer's HTTPS endpoint. Paths are relative
// to the package directory, which is the working directory during `bal test`.
listener http:Listener salesMockListener = new (9092,
    secureSocket = {
        key: {
            certFile: "../resources/public.crt",
            keyFile: "../resources/private.key"
        }
    }
);

service / on salesMockListener {

    isolated resource function 'default [string... paths](http:Request req) returns http:Response|error {
        string path = "/" + string:'join("/", ...paths);
        string method = req.method;
        http:Response res = new;

        if method == "POST" && path == "/b1s/v1/Login" {
            res.setJsonPayload({SessionId: SESSION, Version: "1000000", SessionTimeout: 30});
            res.addHeader("Set-Cookie", string `B1SESSION=${SESSION}; path=/b1s/v1; HttpOnly;`);
            res.addHeader("Set-Cookie", "ROUTEID=.node1; path=/b1s/v1");
            return res;
        }

        if !hasSession(req) {
            res.statusCode = 401;
            res.setJsonPayload({"error": {"code": 301, "message": {"value": "Invalid session."}}});
            return res;
        }

        if method == "POST" && path == "/b1s/v1/Logout" {
            res.statusCode = 204;
            return res;
        }

        if method == "GET" && path == "/b1s/v1/Orders" {
            res.setJsonPayload({
                "odata.metadata": "https://mock/b1s/v1/$metadata#Orders",
                value: [
                    {DocEntry: 1, DocNum: 1001, CardCode: "C20000", CardName: "Maxi-Teq", DocumentStatus: "bost_Open", DocTotal: 1250.5, DocCurrency: "$"},
                    {DocEntry: 2, DocNum: 1002, CardCode: "C30000", CardName: "Microchips", DocumentStatus: "bost_Open", DocTotal: 980.0, DocCurrency: "$"}
                ]
            });
            return res;
        }

        if method == "GET" && path == "/b1s/v1/Orders(1)" {
            res.setJsonPayload({
                DocEntry: 1, DocNum: 1001, CardCode: "C20000", CardName: "Maxi-Teq",
                DocumentStatus: "bost_Open", DocTotal: 1250.5, DocCurrency: "$",
                DocumentLines: [
                    {LineNum: 0, ItemCode: "A00001", Quantity: 5.0, UnitPrice: 250.1}
                ]
            });
            return res;
        }

        if method == "POST" && path == "/b1s/v1/Orders" {
            json body = check req.getJsonPayload();
            map<json> created = <map<json>>body;
            created["DocEntry"] = 99;
            created["DocNum"] = 2001;
            created["DocumentStatus"] = "bost_Open";
            res.statusCode = 201;
            res.setJsonPayload(created);
            return res;
        }

        if method == "POST" && path == "/b1s/v1/Orders(1)/Close" {
            res.statusCode = 204;
            return res;
        }

        if method == "PATCH" && path == "/b1s/v1/Orders(1)" {
            res.statusCode = 204;
            return res;
        }

        res.statusCode = 404;
        res.setJsonPayload({"error": {"code": -2028, "message": {"value": "No matching records found"}}});
        return res;
    }
}
