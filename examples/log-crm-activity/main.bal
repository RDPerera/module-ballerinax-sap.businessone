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

    crm:Activity created = check b1->activitiesCreate({
        Activity: "cn_Note",
        ActivityDate: today,
        Details: "Logged from the Ballerina sap.businessone.crm connector",
        Notes: "Connectivity test note — safe to delete."
    });
    io:println(string `Created activity #${created.ActivityCode ?: 0}`);

    crm:Activity fetched = check b1->activitiesGet(created.ActivityCode ?: 0, queries = {
        \$select: "ActivityCode,Activity,ActivityDate,Details,Notes"
    });
    io:println(string `Read back: [${fetched.ActivityDate ?: ""}] ${fetched.Details ?: ""} — ${fetched.Notes ?: ""}`);
    // The Service Layer session expires on its own (default 30 minutes), so an
    // explicit `b1->logout()` is optional for a short-lived script like this.
}
