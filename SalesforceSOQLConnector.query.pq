// Use this file to write queries to test your data connector
let
    result = SalesforceSOQLConnector.ExecuteQuery("salesforce_domain", "SELECT Name, (SELECT ActivityDate, ActivityType FROM ActivityHistories) FROM Account")
in
    result
