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
