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
