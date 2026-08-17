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

import ballerina/websocket;

# Represents a message of a user.
#
# + sessionId - Identifies the user's session. Stable across the turns of one
# connection, so it can be used directly as an agent memory key
# + message - The latest user utterance.
public type ChatMessage record {|
    string sessionId;
    string message;
|};


# Represents a service that handles chat messages from a voice connection.
public type VoiceService distinct isolated service object {

    # Handles a single chat message and returns the reply to send back to the caller.
    #
    # If this returns an `error`, the error is logged and the connection is closed with a
    # `websocket:InternalServerError` close frame carrying a generic reason. The error's message
    # and details are not sent to the client, so it is safe to return errors containing internal
    # information here.
    #
    # + message - The chat message to handle
    # + return - The reply to send to the caller, or an `error` if the message could not be handled
    isolated remote function onChatMessage(ChatMessage message) returns string|error;
};


# Provides a set of configurations for voice service of voice listener
public type ListenerConfiguration record {|
    *websocket:ListenerConfiguration;
|};


type Attachment record {|
    VoiceService svc;
    websocket:UpgradeService upgradeService;
|};
