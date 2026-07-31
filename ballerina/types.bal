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

// Constants used for knowledge base retrieval.
const APPLICATION_JSON = "application/json";
const MATCHES = "matches";
const RESULTS = "results";
const VALUE = "value";
const CONTENT = "content";
const METADATA = "metadata";
const SIMILARITY_SCORE = "similarityScore";
const SCORE = "score";
const SEARCH_SCORE = "@search.score";
const RETRIEVED_CHUNKS = "retrieved_chunks";
const TEXT = "text";
const SOURCE = "source";
const TIMESTAMP = "timestamp";

type KnowledgeBaseIngestRequest record {|
    IngestChunkRequest[] documents;
|};

type IngestChunkRequest record {|
    string text;
    string 'source;
    string timestamp?;
    map<json> metadata;
|};

type KnowledgeBaseRetrieveRequest record {|
    string user_query;
    int max_retrieve_chunks?;
    decimal min_similarity_threshold?;
    string cohere_reranker_apikey?;
    string cohere_reranker_model?;
    int reranker_top_n?;
    json filters?;
|};
