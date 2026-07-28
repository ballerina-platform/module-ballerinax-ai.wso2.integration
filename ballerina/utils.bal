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
import ballerina/io;

isolated function readResponsePayloadAsString(http:Response response) returns string|Error {
    do {
        byte[] allBytes = [];
        stream<byte[], io:Error?> byteStream = check response.getByteStream();
        check from byte[] bytes in byteStream
            do {
                allBytes.push(...bytes);
            };
        return check string:fromBytes(allBytes); // Returns a newline-delimited JSON (NDJSON) string
    } on fail error e {
        return error("unable to read response", e);
    }
}

isolated function readJsonResponse(http:Response response) returns json|Error {
    if response.statusCode == http:STATUS_UNAUTHORIZED {
        return error(string `invalid access token or unauthorized access to the service.`);
    }
    if response.statusCode < 200 || response.statusCode >= 300 {
        string|Error responseBody = readResponsePayloadAsString(response);
        if responseBody is string && responseBody.trim() != "" {
            return error(string `request failed with status code ${response.statusCode}: ${responseBody}`);
        }
        return error(string `request failed with status code ${response.statusCode}`);
    }
    string contentType = re `;`.split(response.getContentType())[0].trim();
    if contentType != APPLICATION_JSON {
        return error(string `unexpected content type '${response.getContentType()}', expected 'application/json'.`);
    }

    do {
        return check response.getJsonPayload();
    } on fail error e {
        return error("unable to read JSON response", e);
    }
}

isolated function parseQueryMatches(json payload) returns ai:QueryMatch[]|ai:Error {
    json matchesPayload = payload;
    if payload is map<json> {
        if payload.hasKey(MATCHES) {
            matchesPayload = payload[MATCHES];
        } else if payload.hasKey(RESULTS) {
            matchesPayload = payload[RESULTS];
        } else if payload.hasKey(VALUE) {
            matchesPayload = payload[VALUE];
        } else if payload.hasKey(RETRIEVED_CHUNKS) {
            matchesPayload = payload[RETRIEVED_CHUNKS];
        }
    }

    if matchesPayload !is json[] {
        return error("retrieve response must contain an array of matches");
    }

    ai:QueryMatch[] queryMatches = [];
    foreach json matchPayload in matchesPayload {
        if matchPayload !is map<json> {
            return error("retrieve response match must be a JSON object");
        }
        queryMatches.push(check parseQueryMatch(matchPayload));
    }
    return queryMatches;
}

isolated function parseQueryMatch(map<json> matchPayload) returns ai:QueryMatch|ai:Error {
    string|ai:Error content = extractContent(matchPayload);
    if content is ai:Error {
        return content;
    }

    ai:Metadata metadata = {};
    json? metadataPayload = matchPayload[METADATA];
    if metadataPayload is map<json> {
        metadata = {...metadataPayload};
    }
    foreach string key in [SOURCE, TIMESTAMP] {
        json? val = matchPayload[key];
        if val is string {
            metadata[key] = val;
        }
    }

    ai:Chunk chunk = {
        'type: "text-chunk",
        content,
        metadata
    };

    return {
        chunk,
        similarityScore: extractSimilarityScore(matchPayload)
    };
}

isolated function extractContent(map<json> matchPayload) returns string|ai:Error {
    json? content = matchPayload[CONTENT];
    if content is string {
        return content;
    }

    json? text = matchPayload[TEXT];
    if text is string {
        return text;
    }

    json? chunk = matchPayload["chunk"];
    if chunk is map<json> {
        json? chunkContent = chunk[CONTENT];
        if chunkContent is string {
            return chunkContent;
        }
    }

    return error("retrieve response match does not contain string content");
}

isolated function extractSimilarityScore(map<json> matchPayload) returns float {
    json? score = matchPayload[SIMILARITY_SCORE];
    if score is float {
        return score;
    }
    if score is int {
        return <float>score;
    }
    if score is decimal {
        return <float>score;
    }

    score = matchPayload[SCORE];
    if score is float {
        return score;
    }
    if score is int {
        return <float>score;
    }
    if score is decimal {
        return <float>score;
    }

    score = matchPayload[SEARCH_SCORE];
    if score is float {
        return score;
    }
    if score is int {
        return <float>score;
    }
    if score is decimal {
        return <float>score;
    }

    return 0.0;
}
