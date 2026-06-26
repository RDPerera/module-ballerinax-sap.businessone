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
import ballerina/jballerina.java;
import ballerina/mime;

# The `sap.businessone` client return type for the HTTP client actions.
public type TargetType http:Response|anydata;

# SAP Business One Service Layer session credentials.
#
# + companyDb - The company database (schema) to connect to
# + username - SAP Business One user code
# + password - SAP Business One user password
public type SessionConfig record {|
    string companyDb;
    string username;
    string password;
|};

# The `sap.businessone` client provides the capability for initiating contact with the SAP Business One
# Service Layer. The API it provides includes the functions for the standard HTTP methods.
#
# Authentication is session based: the client logs in to the Service Layer with the configured
# company database, user name, and password, and transparently re-logs in and replays the request
# once when the session expires (HTTP 401).
public client isolated class Client {

    final http:Client httpClient;
    private final string companyDb;
    private final string username;
    private final string password;
    private string sessionCookies = "";

    # Gets invoked to initialize the `client`. During initialization, the configurations provided through the `config`
    # record is used to determine which type of additional behaviours are added to the endpoint (e.g.
    # security, circuit breaking). The Service Layer session (`B1SESSION` and `ROUTEID` cookies) is captured
    # from the login response and attached to every request by the client itself.
    #
    # + url - URL of the target Service Layer endpoint (e.g. `https://host:50000/b1s/v1`)
    # + session - The Service Layer session credentials
    # + config - The configurations to be used when initializing the `client`
    # + return - The `client` or a `sap.businessone:ClientError` if the initialization failed
    public isolated function init(string url, SessionConfig session, http:ClientConfiguration config = {}) returns ClientError? {
        self.companyDb = session.companyDb;
        self.username = session.username;
        self.password = session.password;
        self.httpClient = check new (url, config);
        return;
    }

    # The client resource function to send HTTP POST requests to the SAP Business One Service Layer.
    #
    # + path - Request path
    # + message - An HTTP outbound request or any allowed payload
    # + headers - The entity headers
    # + mediaType - The MIME type header of the request entity
    # + targetType - HTTP response or `anydata`, which is expected to be returned after data binding
    # + params - The query parameters
    # + return - The response or the payload (if the `targetType` is configured) or a `sap.businessone:ClientError` if failed to
    # establish the communication with the upstream server or a data binding failure
    isolated resource function post [http:PathParamType... path](http:RequestMessage message, map<string|string[]>? headers = (), string?
            mediaType = (), typedesc<TargetType> targetType = <>, *http:QueryParams params) returns targetType|ClientError = @java:Method {
        'class: "io.ballerina.lib.sap.businessone.ClientAction",
        name: "postResource"
    } external;

    # The `Client.post()` function can be used to send HTTP POST requests to the SAP Business One Service Layer.
    #
    # + path - Resource path
    # + message - An HTTP outbound request or any allowed payload
    # + headers - The entity headers
    # + mediaType - The MIME type header of the request entity
    # + targetType - HTTP response or `anydata`, which is expected to be returned after data binding
    # + return - The response or the payload (if the `targetType` is configured) or a `sap.businessone:ClientError` if failed to
    # establish the communication with the upstream server or a data binding failure
    remote isolated function post(string path, http:RequestMessage message, map<string|string[]>? headers = (),
            string? mediaType = (), typedesc<TargetType> targetType = <>)
            returns targetType|ClientError = @java:Method {
        'class: "io.ballerina.lib.sap.businessone.ClientAction"
    } external;

    private isolated function processPost(string path, http:RequestMessage message, typedesc<TargetType> targetType,
            string? mediaType, map<string|string[]>? headers) returns TargetType|ClientError {
        map<string|string[]> headersModified = headers ?: {};
        headersModified[ACCEPT_HEADER] = mime:APPLICATION_JSON;
        check self.ensureSession();
        headersModified[COOKIE_HEADER] = self.sessionCookieHeader();
        TargetType|ClientError response = self.httpClient->post(path, message, headersModified, mediaType, targetType);
        if isSessionExpired(response) {
            check self.ensureSession(true);
            headersModified[COOKIE_HEADER] = self.sessionCookieHeader();
            return self.httpClient->post(path, message, headersModified, mediaType, targetType);
        }
        return response;
    }

    # The client resource function to send HTTP PUT requests to the SAP Business One Service Layer.
    #
    # + path - Request path
    # + message - An HTTP outbound request or any allowed payload
    # + headers - The entity headers
    # + mediaType - The MIME type header of the request entity
    # + targetType - HTTP response or `anydata`, which is expected to be returned after data binding
    # + params - The query parameters
    # + return - The response or the payload (if the `targetType` is configured) or a `sap.businessone:ClientError` if failed to
    # establish the communication with the upstream server or a data binding failure
    isolated resource function put [http:PathParamType... path](http:RequestMessage message, map<string|string[]>? headers = (), string?
            mediaType = (), typedesc<TargetType> targetType = <>, *http:QueryParams params) returns targetType|ClientError = @java:Method {
        'class: "io.ballerina.lib.sap.businessone.ClientAction",
        name: "putResource"
    } external;

    # The `Client.put()` function can be used to send HTTP PUT requests to the SAP Business One Service Layer.
    #
    # + path - Resource path
    # + message - An HTTP outbound request or any allowed payload
    # + mediaType - The MIME type header of the request entity
    # + headers - The entity headers
    # + targetType - HTTP response or `anydata`, which is expected to be returned after data binding
    # + return - The response or the payload (if the `targetType` is configured) or a `sap.businessone:ClientError` if failed to
    # establish the communication with the upstream server or a data binding failure
    remote isolated function put(string path, http:RequestMessage message, map<string|string[]>? headers = (),
            string? mediaType = (), typedesc<TargetType> targetType = <>)
            returns targetType|ClientError = @java:Method {
        'class: "io.ballerina.lib.sap.businessone.ClientAction"
    } external;

    private isolated function processPut(string path, http:RequestMessage message, typedesc<TargetType> targetType,
            string? mediaType, map<string|string[]>? headers) returns TargetType|ClientError {
        map<string|string[]> headersModified = headers ?: {};
        headersModified[ACCEPT_HEADER] = mime:APPLICATION_JSON;
        check self.ensureSession();
        headersModified[COOKIE_HEADER] = self.sessionCookieHeader();
        TargetType|ClientError response = self.httpClient->put(path, message, headersModified, mediaType, targetType);
        if isSessionExpired(response) {
            check self.ensureSession(true);
            headersModified[COOKIE_HEADER] = self.sessionCookieHeader();
            return self.httpClient->put(path, message, headersModified, mediaType, targetType);
        }
        return response;
    }

    # The client resource function to send HTTP PATCH requests to the SAP Business One Service Layer.
    #
    # + path - Request path
    # + message - An HTTP outbound request or any allowed payload
    # + headers - The entity headers
    # + mediaType - The MIME type header of the request entity
    # + targetType - HTTP response or `anydata`, which is expected to be returned after data binding
    # + params - The query parameters
    # + return - The response or the payload (if the `targetType` is configured) or a `sap.businessone:ClientError` if failed to
    # establish the communication with the upstream server or a data binding failure
    isolated resource function patch [http:PathParamType... path](http:RequestMessage message, map<string|string[]>? headers = (),
            string? mediaType = (), typedesc<TargetType> targetType = <>, *http:QueryParams params) returns targetType|ClientError = @java:Method {
        'class: "io.ballerina.lib.sap.businessone.ClientAction",
        name: "patchResource"
    } external;

    # The `Client.patch()` function can be used to send HTTP PATCH requests to the SAP Business One Service Layer.
    #
    # + path - Resource path
    # + message - An HTTP outbound request or any allowed payload
    # + mediaType - The MIME type header of the request entity
    # + headers - The entity headers
    # + targetType - HTTP response or `anydata`, which is expected to be returned after data binding
    # + return - The response or the payload (if the `targetType` is configured) or a `sap.businessone:ClientError` if failed to
    # establish the communication with the upstream server or a data binding failure
    remote isolated function patch(string path, http:RequestMessage message, map<string|string[]>? headers = (),
            string? mediaType = (), typedesc<TargetType> targetType = <>)
            returns targetType|ClientError = @java:Method {
        'class: "io.ballerina.lib.sap.businessone.ClientAction"
    } external;

    private isolated function processPatch(string path, http:RequestMessage message, typedesc<TargetType> targetType,
            string? mediaType, map<string|string[]>? headers) returns TargetType|ClientError {
        map<string|string[]> headersModified = headers ?: {};
        headersModified[ACCEPT_HEADER] = mime:APPLICATION_JSON;
        check self.ensureSession();
        headersModified[COOKIE_HEADER] = self.sessionCookieHeader();
        TargetType|ClientError response = self.httpClient->patch(path, message, headersModified, mediaType, targetType);
        if isSessionExpired(response) {
            check self.ensureSession(true);
            headersModified[COOKIE_HEADER] = self.sessionCookieHeader();
            return self.httpClient->patch(path, message, headersModified, mediaType, targetType);
        }
        return response;
    }

    # The client resource function to send HTTP DELETE requests to the SAP Business One Service Layer.
    #
    # + path - Request path
    # + message - An optional HTTP outbound request or any allowed payload
    # + headers - The entity headers
    # + mediaType - The MIME type header of the request entity
    # + targetType - HTTP response or `anydata`, which is expected to be returned after data binding
    # + params - The query parameters
    # + return - The response or the payload (if the `targetType` is configured) or a `sap.businessone:ClientError` if failed to
    # establish the communication with the upstream server or a data binding failure
    isolated resource function delete [http:PathParamType... path](http:RequestMessage message = (), map<string|string[]>? headers = (),
            string? mediaType = (), typedesc<TargetType> targetType = <>, *http:QueryParams params) returns targetType|ClientError = @java:Method {
        'class: "io.ballerina.lib.sap.businessone.ClientAction",
        name: "deleteResource"
    } external;

    # The `Client.delete()` function can be used to send HTTP DELETE requests to the SAP Business One Service Layer.
    #
    # + path - Resource path
    # + message - An optional HTTP outbound request message or any allowed payload
    # + mediaType - The MIME type header of the request entity
    # + headers - The entity headers
    # + targetType - HTTP response or `anydata`, which is expected to be returned after data binding
    # + return - The response or the payload (if the `targetType` is configured) or a `sap.businessone:ClientError` if failed to
    # establish the communication with the upstream server or a data binding failure
    remote isolated function delete(string path, http:RequestMessage message = (),
            map<string|string[]>? headers = (), string? mediaType = (), typedesc<TargetType> targetType = <>)
            returns targetType|ClientError = @java:Method {
        'class: "io.ballerina.lib.sap.businessone.ClientAction"
    } external;

    private isolated function processDelete(string path, http:RequestMessage message, typedesc<TargetType> targetType,
            string? mediaType, map<string|string[]>? headers) returns TargetType|ClientError {
        map<string|string[]> headersModified = headers ?: {};
        headersModified[ACCEPT_HEADER] = mime:APPLICATION_JSON;
        check self.ensureSession();
        headersModified[COOKIE_HEADER] = self.sessionCookieHeader();
        TargetType|ClientError response = self.httpClient->delete(path, message, headersModified, mediaType, targetType);
        if isSessionExpired(response) {
            check self.ensureSession(true);
            headersModified[COOKIE_HEADER] = self.sessionCookieHeader();
            return self.httpClient->delete(path, message, headersModified, mediaType, targetType);
        }
        return response;
    }

    # The client resource function to send HTTP HEAD requests to the SAP Business One Service Layer.
    #
    # + path - Request path
    # + headers - The entity headers
    # + params - The query parameters
    # + return - The response or a `sap.businessone:ClientError` if failed to establish the communication with the upstream server
    isolated resource function head [http:PathParamType... path](map<string|string[]>? headers = (), *http:QueryParams params)
            returns http:Response|ClientError = @java:Method {
        'class: "io.ballerina.lib.sap.businessone.ClientAction",
        name: "headResource"
    } external;

    # The `Client.head()` function can be used to send HTTP HEAD requests to the SAP Business One Service Layer.
    #
    # + path - Resource path
    # + headers - The entity headers
    # + return - The response or a `sap.businessone:ClientError` if failed to establish the communication with the upstream server
    remote isolated function head(string path, map<string|string[]>? headers = ()) returns http:Response|ClientError {
        map<string|string[]> headersModified = headers ?: {};
        check self.ensureSession();
        headersModified[COOKIE_HEADER] = self.sessionCookieHeader();
        http:Response|ClientError response = self.httpClient->head(path, headersModified);
        if isSessionExpired(response) {
            check self.ensureSession(true);
            headersModified[COOKIE_HEADER] = self.sessionCookieHeader();
            return self.httpClient->head(path, headersModified);
        }
        return response;
    }

    # The client resource function to send HTTP GET requests to the SAP Business One Service Layer.
    #
    # + path - Request path
    # + headers - The entity headers
    # + targetType - HTTP response or `anydata`, which is expected to be returned after data binding
    # + params - The query parameters
    # + return - The response or the payload (if the `targetType` is configured) or a `sap.businessone:ClientError` if failed to
    # establish the communication with the upstream server or a data binding failure
    isolated resource function get [http:PathParamType... path](map<string|string[]>? headers = (), typedesc<TargetType> targetType = <>,
            *http:QueryParams params) returns targetType|ClientError = @java:Method {
        'class: "io.ballerina.lib.sap.businessone.ClientAction",
        name: "getResource"
    } external;

    # The `Client.get()` function can be used to send HTTP GET requests to the SAP Business One Service Layer.
    #
    # + path - Request path
    # + headers - The entity headers
    # + targetType - HTTP response or `anydata`, which is expected to be returned after data binding
    # + return - The response or the payload (if the `targetType` is configured) or a `sap.businessone:ClientError` if failed to
    # establish the communication with the upstream server or a data binding failure
    remote isolated function get(string path, map<string|string[]>? headers = (), typedesc<TargetType> targetType = <>)
            returns targetType|ClientError = @java:Method {
        'class: "io.ballerina.lib.sap.businessone.ClientAction"
    } external;

    private isolated function processGet(string path, map<string|string[]>? headers, typedesc<TargetType> targetType)
            returns TargetType|ClientError {
        map<string|string[]> headersModified = headers ?: {};
        headersModified[ACCEPT_HEADER] = mime:APPLICATION_JSON;
        check self.ensureSession();
        headersModified[COOKIE_HEADER] = self.sessionCookieHeader();
        TargetType|ClientError response = self.httpClient->get(path, headersModified, targetType);
        if isSessionExpired(response) {
            check self.ensureSession(true);
            headersModified[COOKIE_HEADER] = self.sessionCookieHeader();
            return self.httpClient->get(path, headersModified, targetType);
        }
        return response;
    }

    # The client resource function to send HTTP OPTIONS requests to the SAP Business One Service Layer.
    #
    # + path - Request path
    # + headers - The entity headers
    # + targetType - HTTP response or `anydata`, which is expected to be returned after data binding
    # + params - The query parameters
    # + return - The response or the payload (if the `targetType` is configured) or a `sap.businessone:ClientError` if failed to
    # establish the communication with the upstream server or a data binding failure
    isolated resource function options [http:PathParamType... path](map<string|string[]>? headers = (), typedesc<TargetType> targetType = <>,
            *http:QueryParams params) returns targetType|ClientError = @java:Method {
        'class: "io.ballerina.lib.sap.businessone.ClientAction",
        name: "optionsResource"
    } external;

    # The `Client.options()` function can be used to send HTTP OPTIONS requests to the SAP Business One Service Layer.
    #
    # + path - Request path
    # + headers - The entity headers
    # + targetType - HTTP response or `anydata`, which is expected to be returned after data binding
    # + return - The response or the payload (if the `targetType` is configured) or a `sap.businessone:ClientError` if failed to
    # establish the communication with the upstream server or a data binding failure
    remote isolated function options(string path, map<string|string[]>? headers = (), typedesc<TargetType> targetType = <>)
            returns targetType|ClientError = @java:Method {
        'class: "io.ballerina.lib.sap.businessone.ClientAction"
    } external;

    private isolated function processOptions(string path, map<string|string[]>? headers, typedesc<TargetType> targetType)
            returns TargetType|ClientError {
        map<string|string[]> headersModified = headers ?: {};
        headersModified[ACCEPT_HEADER] = mime:APPLICATION_JSON;
        check self.ensureSession();
        headersModified[COOKIE_HEADER] = self.sessionCookieHeader();
        TargetType|ClientError response = self.httpClient->options(path, headersModified, targetType);
        if isSessionExpired(response) {
            check self.ensureSession(true);
            headersModified[COOKIE_HEADER] = self.sessionCookieHeader();
            return self.httpClient->options(path, headersModified, targetType);
        }
        return response;
    }

    # Ends the current Service Layer session.
    #
    # + return - A `sap.businessone:ClientError` if the logout failed
    remote isolated function logout() returns ClientError? {
        string sessionCookies = self.sessionCookieHeader();
        if sessionCookies == "" {
            return;
        }
        http:Response _ = check self.httpClient->post(LOGOUT_PATH, (), {[COOKIE_HEADER]: sessionCookies});
        lock {
            self.sessionCookies = "";
        }
        return;
    }

    # Logs in to the Service Layer if there is no active session, or unconditionally when `refresh` is set.
    #
    # + refresh - Forces a new login even when a session is believed to be active
    # + return - A `sap.businessone:LoginFailure` if the Service Layer rejects the login
    isolated function ensureSession(boolean refresh = false) returns ClientError? {
        lock {
            if self.sessionCookies != "" && !refresh {
                return;
            }
        }
        json loginPayload = {
            CompanyDB: self.companyDb,
            UserName: self.username,
            Password: self.password
        };
        http:Response response = check self.httpClient->post(LOGIN_PATH, loginPayload);
        if response.statusCode != http:STATUS_OK {
            string body = "";
            string|http:ClientError textPayload = response.getTextPayload();
            if textPayload is string {
                body = textPayload;
            }
            return error LoginFailure(
                    string `Service Layer login failed with status ${response.statusCode}: ${body}`);
        }
        string[] setCookieHeaders = [];
        string[]|http:HeaderNotFoundError cookieHeaders = response.getHeaders(SET_COOKIE_HEADER);
        if cookieHeaders is string[] {
            setCookieHeaders = cookieHeaders;
        }
        string[] cookiePairs = [];
        foreach string headerValue in setCookieHeaders {
            int? separator = headerValue.indexOf(";");
            cookiePairs.push(separator is int ? headerValue.substring(0, separator) : headerValue);
        }
        if cookiePairs.length() == 0 {
            return error LoginFailure("Service Layer login response did not include session cookies");
        }
        string joined = string:'join("; ", ...cookiePairs);
        lock {
            self.sessionCookies = joined;
        }
        return;
    }

    # Returns the `Cookie` header value carrying the active Service Layer session.
    #
    # + return - The session cookies, or an empty string when no session is active
    isolated function sessionCookieHeader() returns string {
        lock {
            return self.sessionCookies;
        }
    }
}

isolated function isSessionExpired(TargetType|ClientError response) returns boolean {
    if response is http:Response {
        return response.statusCode == http:STATUS_UNAUTHORIZED;
    }
    if response is http:ClientRequestError {
        return response.detail().statusCode == http:STATUS_UNAUTHORIZED;
    }
    return false;
}
