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

import ballerina/log;
import ballerina/websocket;

service class VoiceConnection {
    *websocket:Service;

    private final VoiceService handler;
    private final string sessionId;

    isolated function init(VoiceService handler, string sessionId) {
        self.handler = handler;
        self.sessionId = sessionId;
    }

    isolated remote function onTextMessage(websocket:Caller caller, string text)
            returns websocket:InternalServerError? {
        ChatMessage message = {sessionId: self.sessionId, message: text};
        string|error reply = self.handler->onChatMessage(message);
        if reply is error {
            log:printError("chat handler failed", reply, sessionId = self.sessionId);
            websocket:InternalServerError closeFrame = {reason: "internal server error"};
            return closeFrame;
        }

        websocket:Error? writeResult = caller->writeTextMessage(reply);
        if writeResult is websocket:Error {
            log:printError("failed to write reply", writeResult, sessionId = self.sessionId);
            websocket:InternalServerError closeFrame = {reason: writeResult.message()};
            return closeFrame;
        }
        return;
    }

    isolated remote function onError(websocket:Caller caller, error err) {
        log:printError("connection error", err, sessionId = self.sessionId);
    }
}
