// Copyright (c) 2026, WSO2 LLC. (http://www.wso2.com).
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

import ballerina/ai;
import ballerina/http;

# Configuration for connecting to a WSO2 Cloud knowledge base.
#
# + auth - Authentication configuration: either bearer token or OAuth2 client credentials
# + timeout - The HTTP client timeout in seconds (optional)
public type ConnectKnowledgeBase record {|
    http:BearerTokenConfig|http:OAuth2ClientCredentialsGrantConfig auth;
    decimal timeout?;
|};

# Represents a WSO2 Cloud knowledge base for retrieval.
@display {label: "WSO2 Cloud Knowledge Base"}
public isolated class CloudKnowledgeBase {
    *ai:KnowledgeBase;

    private final http:Client serviceClient;
    private final decimal minSimilarityThreshold;
    private final string? cohereRerankerApiKey;
    private final string? cohereRerankerModel;
    private final int rerankerTopN;

    # Initializes a new `KnowledgeBase` instance.
    #
    # + knowledgeBaseConfig - Either `CreateKnowledgeBase` to provision a new knowledge base,
    # or `ConnectKnowledgeBase` to connect to an existing one
    # + connectionConfig - Additional HTTP connection configurations
    # + minSimilarityThreshold - The minimum similarity score threshold for retrieved chunks (default: 0.0)
    # + cohereRerankerApiKey - The API key for the Cohere reranker service; omit to disable reranking
    # + cohereRerankerModel - The Cohere reranker model name to use
    # + rerankerTopN - The number of top results to return from the reranker (default: 5)
    # + return - `nil` on success, or an `ai:Error` if the initialization fails
    public isolated function init(
            @display {label: "Service URL"} string serviceUrl,
            @display {label: "Knowledge Base Configuration"} ConnectKnowledgeBase knowledgeBaseAuthConfig,
            @display {label: "Minimum Similarity Threshold"} decimal minSimilarityThreshold = 0.7,
            @display {label: "Cohere Reranker API Key"} string? cohereRerankerApiKey = (),
            @display {label: "Cohere Reranker Model"} string? cohereRerankerModel = (),
            @display {label: "Reranker Top N"} int rerankerTopN = 5,
            @display {label: "Connection Configuration"} *ai:ConnectionConfig connectionConfig) returns ai:Error? {

        http:ClientConfiguration httpConfig = {
            httpVersion: http:HTTP_1_1,
            http1Settings: connectionConfig.http1Settings,
            timeout: connectionConfig.timeout,
            forwarded: connectionConfig.forwarded,
            poolConfig: connectionConfig.poolConfig,
            cache: connectionConfig.cache,
            compression: connectionConfig.compression,
            circuitBreaker: connectionConfig.circuitBreaker,
            retryConfig: connectionConfig.retryConfig,
            responseLimits: connectionConfig.responseLimits,
            secureSocket: connectionConfig.secureSocket,
            proxy: connectionConfig.proxy,
            validation: connectionConfig.validation,
            auth: knowledgeBaseAuthConfig.auth
        };

        if knowledgeBaseAuthConfig.timeout is decimal {
            httpConfig.timeout = <decimal>knowledgeBaseAuthConfig.timeout;
        }

        string normalizedUrl = serviceUrl.endsWith("/") ? serviceUrl.substring(0, serviceUrl.length() - 1) : serviceUrl;
        http:Client|error serviceClient = new (normalizedUrl, httpConfig);
        if serviceClient is error {
            return error(string `failed to initialize the client: ${serviceClient.message()}`, serviceClient);
        }
        self.serviceClient = serviceClient;
        self.minSimilarityThreshold = minSimilarityThreshold;
        self.cohereRerankerApiKey = cohereRerankerApiKey;
        self.cohereRerankerModel = cohereRerankerModel;
        self.rerankerTopN = rerankerTopN;
    }

    # Ingests documents or chunks into the WSO2 Cloud knowledge base.
    #
    # + documents - The documents or chunks to ingest
    # + return - `nil` on success, or an `ai:Error` if ingestion fails
    public isolated function ingest(ai:Chunk[]|ai:Document[]|ai:Document documents) returns ai:Error? {
        do {
            KnowledgeBaseIngestRequest ingestRequest = check createIngestRequest(documents);
            http:Response response = check self.serviceClient->/ingest.post(
                ingestRequest, {}, APPLICATION_JSON
            );
            check validateResponse(response);
        } on fail error e {
            return error(string `failed to ingest documents: ${e.message()}`, e);
        }
    }

    # Retrieves relevant chunks for the given query.
    #
    # + query - The text query to search for
    # + maxLimit - The maximum number of items to return
    # + filters - Optional metadata filters to apply during retrieval
    # + return - An array of matching chunks with similarity scores, or an `ai:Error` if retrieval fails
    public isolated function retrieve(string query, int maxLimit = 10,
            ai:MetadataFilters? filters = ()) returns ai:QueryMatch[]|ai:Error {
        if maxLimit != -1 && maxLimit <= 0 {
            return error("maxLimit must be a positive integer");
        }

        KnowledgeBaseRetrieveRequest retrieveRequest = {
            user_query: query,
            max_retrieve_chunks: maxLimit == -1 ? () : maxLimit,
            min_similarity_threshold: self.minSimilarityThreshold,
            cohere_reranker_apikey: self.cohereRerankerApiKey,
            cohere_reranker_model: self.cohereRerankerModel,
            reranker_top_n: self.rerankerTopN,
            filters: filters is ai:MetadataFilters ? filters.toJson() : ()
        };

        do {
            json retrievePayload = retrieveRequest;
            http:Response response = check self.serviceClient->/retrieve.post(
                retrievePayload, {}, APPLICATION_JSON
            );
            json payload = check readJsonResponse(response);
            return check parseQueryMatches(payload);
        } on fail error e {
            return error(string `failed to retrieve chunks: ${e.message()}`, e);
        }
    }

    # Deletion is not supported.
    #
    # + filters - The metadata filters used to identify which chunks to delete
    # + return - An `ai:Error` since deletion is not supported by the retrieve API
    public isolated function deleteByFilter(ai:MetadataFilters filters) returns ai:Error? {
        return error("delete by filter is not supported by the WSO2 Integration knowledge base API");
    }
}
