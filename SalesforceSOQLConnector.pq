// This file contains your Data Connector logic
[Version = "1.0.0"]
section SalesforceSOQLConnector;

[DataSource.Kind="SalesforceSOQLConnector", Publish="SalesforceSOQLConnector.Publish"]
shared SalesforceSOQLConnector.ExecuteQuery = (domain as text, soqlQuery as text) as table =>
    let
        // Retrieve stored credentials
        credential = Extension.CurrentCredential(),
        clientId = credential[Username],
        clientSecret = credential[Password],
        // Fetch token and data
        token = GetOAuthToken(domain, clientId, clientSecret),
        data = FetchData(domain, soqlQuery, token)
    in
        data;

// Get OAuth token from Salesforce
GetOAuthToken = (domain as text, clientId as text, clientSecret as text) as text =>
    let
        TokenEndpoint = "https://" & domain & ".my.salesforce.com/services/oauth2/token",
        Body = "grant_type=client_credentials&client_id=" & clientId & "&client_secret=" & clientSecret,
        Response = Web.Contents(TokenEndpoint, [
            Content = Text.ToBinary(Body),
            Headers = [#"Content-Type" = "application/x-www-form-urlencoded"]
        ]),
        AccessToken = Json.Document(Response)[access_token]
    in
        AccessToken;

// Execute SOQL Query using Salesforce API
FetchData = (domain as text, soqlQuery as text, token as text) as table =>
    let
        BaseUrl = "https://" & domain & ".my.salesforce.com/services/data/v60.0/query/",
        EncodedQuery = Uri.EscapeDataString(soqlQuery),
        FullUrl = BaseUrl & "?q=" & EncodedQuery,
        JsonContent = Web.Contents(FullUrl, [
            Headers = [Authorization="Bearer " & token],
            ManualStatusHandling = {400, 401, 403, 404, 500}
        ]),
        Response = Json.Document(JsonContent),
        DataTable = if Response[records]? <> null then
                        Table.RemoveColumns(
                            Table.FromRecords(Response[records]),
                            "attributes"
                        )
                    else
                        error "Failed to fetch data or invalid query. Error: " & Response[message]
    in
        DataTable;

// Data Source Kind description
SalesforceSOQLConnector = [
    Authentication = [
        UsernamePassword = [
            UsernameLabel = "Client ID",
            PasswordLabel = "Client Secret"
        ]
    ],
    Label = "Salesforce SOQL Connector"
];


// Data Source UI publishing description
SalesforceSOQLConnector.Publish = [
    Beta = true,
    Category = "Other",
    ButtonText = { Extension.LoadString("ButtonTitle"), Extension.LoadString("ButtonHelp") },
    LearnMoreUrl = "https://powerbi.microsoft.com/",
    SourceImage = SalesforceSOQLConnector.Icons,
    SourceTypeImage = SalesforceSOQLConnector.Icons
];

SalesforceSOQLConnector.Icons = [
    Icon16 = { Extension.Contents("SalesforceSOQLConnector16.png"), Extension.Contents("SalesforceSOQLConnector20.png"), Extension.Contents("SalesforceSOQLConnector24.png"), Extension.Contents("SalesforceSOQLConnector32.png") },
    Icon32 = { Extension.Contents("SalesforceSOQLConnector32.png"), Extension.Contents("SalesforceSOQLConnector40.png"), Extension.Contents("SalesforceSOQLConnector48.png"), Extension.Contents("SalesforceSOQLConnector64.png") }
];
