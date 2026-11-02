# Ballerina WSO2 Integration AI Library

[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)

## Overview

The `ai.wso2.integration` module integrates the Ballerina AI APIs with a WSO2 Integration knowledge base. It implements `ai:KnowledgeBase` and supports ingesting content through the service's `/ingest/content` endpoint and retrieving relevant content through its `/retrieve` endpoint.

## Quickstart

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

Each ingested document must have a `source` or `fileName` metadata value. Deletion is not currently supported by this knowledge base implementation.

## Build from source

Install JDK 21, then run:

```bash
./gradlew clean build
```

## Contributing

This repository is part of the Ballerina Library. Report bugs and request features through the [Ballerina standard library repository](https://github.com/ballerina-platform/ballerina-standard-library).
