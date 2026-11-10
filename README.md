# Ballerina WSO2 Integration AI Library

[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)

## Overview

The `ai.wso2.integration` module integrates the Ballerina AI APIs with a WSO2 Integration knowledge base. It implements `ai:KnowledgeBase` and supports retrieving relevant content through the service's `/retrieve` endpoint.

## Quickstart

```ballerina
import ballerina/ai;
import ballerinax/ai.wso2.integration;

integration:CloudKnowledgeBase knowledgeBase = check new (
    serviceUrl,
    {auth: {token: accessToken}}
);

ai:QueryMatch[] matches = check knowledgeBase.retrieve("How do I configure the integration?");
```

### Authentication

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

Ingestion and deletion are not currently supported by this knowledge base implementation.

## Build from source

Install JDK 21, then run:

```bash
./gradlew clean build
```

## Contributing

This repository is part of the Ballerina Library. Report bugs and request features through the [Ballerina standard library repository](https://github.com/ballerina-platform/ballerina-standard-library).
