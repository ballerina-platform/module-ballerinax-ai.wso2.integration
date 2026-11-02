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

The implementation supports ingestion and retrieval. Each ingested document must have a `source` or `fileName` metadata value. Deletion is not currently supported.
