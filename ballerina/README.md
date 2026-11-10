## Overview

The `ai.wso2.integration` module provides a Ballerina `ai:KnowledgeBase` implementation for ingesting content into, and retrieving relevant content from, a WSO2 Integration knowledge base.

### Quickstart

```ballerina
import ballerina/ai;
import ballerinax/ai.wso2.integration;

integration:CloudKnowledgeBase knowledgeBase = check new (
    serviceUrl,
    {auth: {token: accessToken}}
);

check knowledgeBase.ingest(documents);
ai:QueryMatch[] matches = check knowledgeBase.retrieve("How do I configure the integration?");
```

#### Authentication

`KnowledgeBaseAuthConfig.auth` accepts one of the following:

- `http:BearerTokenConfig` - a bearer token, e.g. `{auth: {token: accessToken}}`
- `http:OAuth2ClientCredentialsGrantConfig` - OAuth2 client credentials, e.g. `{auth: {tokenUrl, clientId, clientSecret}}`
- `integration:ApiKeyConfig` - a WSO2 Cloud gateway API key. The key is sent in the `X-API-Key` request header by default; set `headerName` if the gateway API is configured to read it from a different header.

```ballerina
configurable string serviceUrl = ?;
configurable string apiKey = ?;

integration:CloudKnowledgeBase knowledgeBase = check new (
    serviceUrl,
    {auth: {apiKey}}
);

// Or, with a custom gateway header:
// {auth: {apiKey, headerName: "X-Custom-Api-Key"}}
```

The implementation supports ingestion and retrieval. Each ingested document must have a `source` or `fileName` metadata value. Deletion is not currently supported.
