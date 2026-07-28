## Overview

The `ai.wso2.integration` module provides a Ballerina `ai:KnowledgeBase` implementation for retrieving relevant content from a WSO2 Integration knowledge base.

### Quickstart

```ballerina
import ballerina/ai;
import ballerinax/ai.wso2.integration;

integration:CloudKnowledgeBase knowledgeBase = check new (
    serviceUrl,
    {auth: {token: accessToken}}
);

ai:QueryMatch[] matches = check knowledgeBase.retrieve("How do I configure the integration?");
```

The implementation supports retrieval. Ingestion and deletion are not currently supported.
