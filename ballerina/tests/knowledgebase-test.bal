// Copyright (c) 2026 WSO2 LLC (http://www.wso2.com).
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
// KIND, either express or implied. See the License for the
// specific language governing permissions and limitations
// under the License.

import ballerina/ai;
import ballerina/http;
import ballerina/test;

service on new http:Listener(9090) {
    resource function post retrieve(http:Request req) returns http:Response|error {
        if !req.getContentType().startsWith(APPLICATION_JSON) {
            return error("Expected an application/json request");
        }
        json payload = check req.getJsonPayload();
        if payload !is map<json> || payload["user_query"] != "test query"
                || payload["reranker_top_n"] != 5 {
            return error("Unexpected retrieve request payload");
        }
        http:Response response = new;
        response.setJsonPayload({
            retrieved_chunks: [
                {
                    content: "matching content",
                    similarityScore: 0.9
                }
            ]
        });
        return response;
    }
}

@test:Config
isolated function testKnowledgeBaseRetrieveJsonRequest() returns error? {
    CloudKnowledgeBase knowledgeBase = check new ("http://localhost:9090",
        {auth: {token: "test-token"}}
    );
    ai:QueryMatch[] matches = check knowledgeBase.retrieve("test query");
    test:assertEquals(matches.length(), 1);
    test:assertEquals(matches[0].chunk.content, "matching content");
}

const AUTH_HEADER_PROBE_PORT = 9091;
const DEFAULT_API_KEY_HEADER = "X-API-Key";
const CUSTOM_API_KEY_HEADER = "X-Custom-Api-Key";

// Echoes the authentication-related request headers back as chunk metadata so that tests can
// assert exactly which headers the client sent.
service on new http:Listener(AUTH_HEADER_PROBE_PORT) {
    resource function post retrieve(http:Request req) returns http:Response {
        http:Response response = new;
        response.setJsonPayload({
            retrieved_chunks: [
                {
                    content: "matching content",
                    similarityScore: 0.9,
                    metadata: {
                        defaultApiKeyHeader: getHeaderValues(req, DEFAULT_API_KEY_HEADER),
                        customApiKeyHeader: getHeaderValues(req, CUSTOM_API_KEY_HEADER),
                        authorization: getHeaderValues(req, http:AUTH_HEADER)
                    }
                }
            ]
        });
        return response;
    }
}

isolated function getHeaderValues(http:Request req, string headerName) returns string[] {
    string[]|http:HeaderNotFoundError values = req.getHeaders(headerName);
    return values is string[] ? values : [];
}

isolated function retrieveAuthHeaders(KnowledgeBaseAuthConfig authConfig) returns ai:Metadata|error {
    CloudKnowledgeBase knowledgeBase = check new (string `http://localhost:${AUTH_HEADER_PROBE_PORT}`, authConfig);
    ai:QueryMatch[] matches = check knowledgeBase.retrieve("test query");
    test:assertEquals(matches.length(), 1);
    return matches[0].chunk.metadata ?: {};
}

@test:Config
isolated function testKnowledgeBaseRetrieveWithApiKeyUsesDefaultHeader() returns error? {
    ai:Metadata headers = check retrieveAuthHeaders({auth: {apiKey: "test-api-key"}});
    test:assertEquals(headers["defaultApiKeyHeader"], ["test-api-key"]);
    test:assertEquals(headers["customApiKeyHeader"], []);
    test:assertEquals(headers["authorization"], []);
}

@test:Config
isolated function testKnowledgeBaseRetrieveWithApiKeyUsesCustomHeader() returns error? {
    KnowledgeBaseAuthConfig authConfig = {auth: {apiKey: "test-api-key", headerName: CUSTOM_API_KEY_HEADER}};
    ai:Metadata headers = check retrieveAuthHeaders(authConfig);
    test:assertEquals(headers["customApiKeyHeader"], ["test-api-key"]);
    test:assertEquals(headers["defaultApiKeyHeader"], []);
    test:assertEquals(headers["authorization"], []);
}

@test:Config
isolated function testKnowledgeBaseRetrieveWithBearerTokenSendsAuthorizationHeader() returns error? {
    ai:Metadata headers = check retrieveAuthHeaders({auth: {token: "test-token"}});
    test:assertEquals(headers["authorization"], ["Bearer test-token"]);
    test:assertEquals(headers["defaultApiKeyHeader"], []);
}

@test:Config
isolated function testKnowledgeBaseInitWithEmptyApiKeyHeaderNameFails() {
    CloudKnowledgeBase|ai:Error knowledgeBase = new (string `http://localhost:${AUTH_HEADER_PROBE_PORT}`,
        {auth: {apiKey: "test-api-key", headerName: " "}}
    );
    if knowledgeBase !is ai:Error {
        test:assertFail("Expected an error for an empty API key header name");
    }
    test:assertEquals(knowledgeBase.message(), "the API key header name must not be empty");
}
