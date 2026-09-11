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
import ballerina/time;

service on new http:Listener(9090) {
    resource function post ingest(http:Request req) returns http:Response|error {
        if !req.getContentType().startsWith(APPLICATION_JSON) {
            return error("Expected an application/json request");
        }
        json payload = check req.getJsonPayload();
        if payload !is map<json> {
            return error("Expected an object payload");
        }
        json? documents = payload["documents"];
        if documents !is json[] || documents.length() != 2 {
            return error("Unexpected ingest request payload");
        }
        json firstDocument = documents[0];
        if firstDocument !is map<json> || firstDocument["text"] !=
                "Permanent employees receive 21 days of annual leave per calendar year."
                || firstDocument["source"] != "employee-handbook.pdf"
                || firstDocument["timestamp"] != "2026-07-31T10:00:00Z" {
            return error("Unexpected normalized ingest chunk");
        }
        json? metadata = firstDocument["metadata"];
        if metadata !is map<json> || metadata["createdAt"] != "2026-07-01T08:30:00Z"
                || metadata["modifiedAt"] != "2026-07-30T14:15:00Z" {
            return error("Unexpected normalized ingest metadata");
        }
        http:Response response = new;
        response.statusCode = http:STATUS_NO_CONTENT;
        return response;
    }

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
isolated function testKnowledgeBaseIngestJsonRequest() returns error? {
    CloudKnowledgeBase knowledgeBase = check new ("http://localhost:9090",
        {auth: {token: "test-token"}}
    );
    time:Utc createdAt = check time:utcFromString("2026-07-01T08:30:00Z");
    time:Utc modifiedAt = check time:utcFromString("2026-07-30T14:15:00Z");
    ai:Chunk[] chunks = [
        {
            'type: "text-chunk",
            content: "Permanent employees receive 21 days of annual leave per calendar year.",
            metadata: {
                fileName: "employee-handbook.pdf",
                createdAt,
                modifiedAt,
                index: 0,
                "source": "employee-handbook.pdf",
                "timestamp": "2026-07-31T10:00:00Z"
            }
        },
        {
            'type: "text-chunk",
            content: "Leave requests must be submitted through the HR portal.",
            metadata: {
                fileName: "employee-handbook.pdf",
                index: 1,
                "source": "employee-handbook.pdf",
                "timestamp": "2026-07-31T10:00:00Z"
            }
        }
    ];
    check knowledgeBase.ingest(chunks);
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
