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
import ballerina/http;

# Mock SAP Business One Service Layer for the banking connector tests. Session
# protected and served over TLS with the shared self-signed certificate.

const string SESSION = "mock-session";

isolated function hasSession(http:Request req) returns boolean {
    string|error cookies = req.getHeader("Cookie");
    return cookies is string && cookies.includes("B1SESSION=" + SESSION);
}

listener http:Listener mockListener = new (9094,
    secureSocket = {
        key: {
            certFile: "../resources/public.crt",
            keyFile: "../resources/private.key"
        }
    }
);

service / on mockListener {

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

        if method == "GET" && path == "/b1s/v1/IncomingPayments" {
            res.setJsonPayload({"odata.metadata": "https://mock/b1s/v1/$metadata", value: [{DocEntry: 1, CardCode: "C20000"}]});
            return res;
        }

        if method == "GET" && path == "/b1s/v1/IncomingPayments(1)" {
            res.setJsonPayload({DocEntry: 1, CardCode: "C20000"});
            return res;
        }

        if method == "POST" && path == "/b1s/v1/IncomingPayments" {
            json body = check req.getJsonPayload();
            map<json> created = <map<json>>body;
            created["DocEntry"] = 88;
            res.statusCode = 201;
            res.setJsonPayload(created);
            return res;
        }

        if method == "PATCH" && path == "/b1s/v1/IncomingPayments(1)" {
            res.statusCode = 204;
            return res;
        }

        res.statusCode = 404;
        res.setJsonPayload({"error": {"code": -2028, "message": {"value": "No matching records found"}}});
        return res;
    }
}
