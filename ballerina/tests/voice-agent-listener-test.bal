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

import ballerina/test;
import ballerina/websocket;

isolated service class EchoVoiceService {
    *VoiceService;

    isolated remote function onChatMessage(ChatMessage message) returns string|error {
        return "echo:" + message.message;
    }
}

isolated service class FailingVoiceService {
    *VoiceService;

    isolated remote function onChatMessage(ChatMessage message) returns string|error {
        return error("sensitive backend detail: db password is hunter2");
    }
}

@test:Config
isolated function testAttachStartCommunicateAndDetach() returns error? {
    CloudVoiceListener voiceListener = check new (21091);
    EchoVoiceService svc = new;
    check voiceListener.attach(svc);
    check voiceListener.'start();

    websocket:Client wsClient = check new ("ws://localhost:21091/");
    check wsClient->writeTextMessage("hello");
    string reply = check wsClient->readTextMessage();
    test:assertEquals(reply, "echo:hello");
    check wsClient->close();

    check voiceListener.detach(svc);
    check voiceListener.gracefulStop();
}

@test:Config
isolated function testAttachSameServiceTwiceFails() returns error? {
    CloudVoiceListener voiceListener = check new (21092);
    EchoVoiceService svc = new;
    check voiceListener.attach(svc);

    error? result = voiceListener.attach(svc);
    test:assertTrue(result is error);
    test:assertEquals((<error>result).message(), "service is already attached to this listener");

    check voiceListener.gracefulStop();
}

@test:Config
isolated function testDetachUnattachedServiceFails() returns error? {
    CloudVoiceListener voiceListener = check new (21093);
    EchoVoiceService svc = new;

    error? result = voiceListener.detach(svc);
    test:assertTrue(result is error);
    test:assertEquals((<error>result).message(), "service is not attached to this listener");

    check voiceListener.gracefulStop();
}

@test:Config
isolated function testDetachRemovesServiceSoSecondDetachFails() returns error? {
    CloudVoiceListener voiceListener = check new (21094);
    EchoVoiceService svc = new;
    check voiceListener.attach(svc);
    check voiceListener.detach(svc);

    error? result = voiceListener.detach(svc);
    test:assertTrue(result is error);
    test:assertEquals((<error>result).message(), "service is not attached to this listener");

    check voiceListener.gracefulStop();
}

@test:Config
isolated function testHandlerErrorDoesNotLeakInternalMessage() returns error? {
    CloudVoiceListener voiceListener = check new (21095);
    FailingVoiceService svc = new;
    check voiceListener.attach(svc);
    check voiceListener.'start();

    websocket:Client wsClient = check new ("ws://localhost:21095/");
    check wsClient->writeTextMessage("trigger failure");
    string|websocket:Error reply = wsClient->readTextMessage();
    test:assertTrue(reply is websocket:Error);
    string closeMessage = (<websocket:Error>reply).message();
    test:assertTrue(!closeMessage.includes("hunter2"));
    test:assertTrue(!closeMessage.includes("sensitive backend detail"));

    check voiceListener.detach(svc);
    check voiceListener.gracefulStop();
}

@test:Config
isolated function testInitWithExistingWebSocketListenerIsReused() returns error? {
    websocket:Listener sharedListener = check new (21096);
    CloudVoiceListener voiceListener = check new (sharedListener);
    EchoVoiceService svc = new;
    check voiceListener.attach(svc);
    check voiceListener.'start();

    websocket:Client wsClient = check new ("ws://localhost:21096/");
    check wsClient->writeTextMessage("hi");
    string reply = check wsClient->readTextMessage();
    test:assertEquals(reply, "echo:hi");
    check wsClient->close();

    check voiceListener.detach(svc);
    check voiceListener.gracefulStop();
}
