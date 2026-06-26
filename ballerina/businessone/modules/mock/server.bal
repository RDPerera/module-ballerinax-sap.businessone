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

# Mock SAP Business One Service Layer used by the tests.
#
# Faithful to the real Service Layer where it matters to the client:
# session login issues `B1SESSION`/`ROUTEID` cookies scoped to `path=/b1s/v1`,
# every other endpoint rejects requests without the current session cookie
# (HTTP 401), and sessions can be invalidated through a test-only control
# endpoint to exercise the re-login flow.

isolated record {|string session; int logins;|} state = {session: "", logins: 0};

isolated function newSession() returns string {
    lock {
        state.logins += 1;
        state.session = string `sess-${state.logins}`;
        return state.session;
    }
}

isolated function hasValidSession(http:Request req) returns boolean {
    string|error cookieHeader = req.getHeader("Cookie");
    if cookieHeader is error {
        return false;
    }
    string header = cookieHeader;
    lock {
        return state.session != "" && header.includes(string `B1SESSION=${state.session}`);
    }
}

isolated function invalidSessionResponse() returns http:Response {
    http:Response res = new;
    res.statusCode = 401;
    res.setJsonPayload({"error": {"code": 301, "message": {"value": "Invalid session."}}});
    return res;
}

// Served over TLS with the shared self-signed certificate (ballerina/resources),
// so the mock mirrors the real Service Layer's HTTPS endpoint. Paths are relative
// to the package directory, which is the working directory during `bal test`.
listener http:Listener mockListener = new (9091,
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

        if method == "POST" && path == "/b1s/v1/Login" {
            json payload = check req.getJsonPayload();
            json companyDb = check payload.CompanyDB;
            json userName = check payload.UserName;
            json password = check payload.Password;
            http:Response res = new;
            if companyDb != "TEST_DB" || userName != "tester" || password != "secret" {
                res.statusCode = 401;
                res.setJsonPayload({"error": {"code": -304, "message": {"value": "Login failed."}}});
                return res;
            }
            string session = newSession();
            res.setJsonPayload({SessionId: session, Version: "1000000", SessionTimeout: 30});
            res.addHeader("Set-Cookie", string `B1SESSION=${session}; path=/b1s/v1; HttpOnly;`);
            res.addHeader("Set-Cookie", "ROUTEID=.node1; path=/b1s/v1");
            return res;
        }

        // Test-only control endpoints.
        if method == "POST" && path == "/control/expire" {
            lock {
                state.session = "";
            }
            http:Response res = new;
            res.statusCode = 204;
            return res;
        }
        if method == "GET" && path == "/control/loginCount" {
            http:Response res = new;
            int count;
            lock {
                count = state.logins;
            }
            res.setJsonPayload({count: count});
            return res;
        }

        if !hasValidSession(req) {
            return invalidSessionResponse();
        }

        if method == "POST" && path == "/b1s/v1/Logout" {
            lock {
                state.session = "";
            }
            http:Response res = new;
            res.statusCode = 204;
            return res;
        }

        if method == "GET" && path == "/b1s/v1/Items" {
            http:Response res = new;
            res.setJsonPayload({
                "odata.metadata": "https://mock/b1s/v1/$metadata#Items",
                value: [
                    {ItemCode: "A00001", ItemName: "Mock Printer", QuantityOnStock: 7.0},
                    {ItemCode: "A00002", ItemName: "Mock Scanner", QuantityOnStock: 3.0}
                ]
            });
            return res;
        }

        if method == "GET" && path == "/b1s/v1/Items('A00001')" {
            http:Response res = new;
            res.setJsonPayload({ItemCode: "A00001", ItemName: "Mock Printer", QuantityOnStock: 7.0});
            return res;
        }

        if method == "POST" && path == "/b1s/v1/Items" {
            json body = check req.getJsonPayload();
            http:Response res = new;
            res.statusCode = 201;
            res.setJsonPayload(body);
            return res;
        }

        if method == "HEAD" && path == "/b1s/v1/Items" {
            http:Response res = new;
            res.statusCode = 200;
            return res;
        }

        http:Response res = new;
        res.statusCode = 404;
        res.setJsonPayload({"error": {"code": -2028, "message": {"value": "No matching records found"}}});
        return res;
    }
}
