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

import ballerina/http;
import ballerina/uuid;
import ballerina/websocket;

const int MAX_FRAME_SIZE = 104857600; // 100 MB

# A CloudVoiceListener for handling voice agent connections over WebSocket.
public class CloudVoiceListener {
    private final websocket:Listener wsListener;
    private Attachment[] attachments = [];

    # Initializes the listener.
    #
    # + listenOn - Port to listen on, or an existing `websocket:Listener` to
    # share, for example with another WebSocket service
    # + config - Configurations for the cloud voice service listener. Ignored
    # if `listenOn` is an existing `websocket:Listener`
    # + return - An `error` if the underlying listener could not be created
    public isolated function init(int|websocket:Listener listenOn, *ListenerConfiguration config) returns Error? {
        if listenOn is websocket:Listener {
            self.wsListener = listenOn;
            return;
        }
        websocket:Listener|error wsListener = new (listenOn, config);
        if wsListener is error {
            return error("error initializing Cloud Voice Listener", wsListener);
        }
        self.wsListener = wsListener;
    }

    # Attaches a service to the listener.
    #
    # + svc - The service that answers chat requests
    # + name - Base path of the service
    # + return - An `error` if the service is already attached, or if the
    # underlying listener rejected the attach
    public isolated function attach(VoiceService svc, string[]|string? name = ()) returns error? {
        foreach Attachment attachment in self.attachments {
            if attachment.svc === svc {
                return error("service is already attached to this listener");
            }
        }
        websocket:UpgradeService upgradeService = createUpgradeService(svc);
        check self.wsListener.attach(upgradeService, name);
        self.attachments.push({svc, upgradeService});
    }

    # Detaches a service from the listener.
    # + svc - The service to detach
    # + return - An `error` if the service was never attached, or if the
    # underlying listener rejected the detach
    public isolated function detach(VoiceService svc) returns error? {
        foreach int i in 0 ..< self.attachments.length() {
            if self.attachments[i].svc === svc {
                check self.wsListener.detach(self.attachments[i].upgradeService);
                _ = self.attachments.remove(i);
                return;
            }
        }
        return error("service is not attached to this listener");
    }

    # Starts the listener.
    #
    # + return - An `error` if the listener could not be started
    public isolated function 'start() returns error? => self.wsListener.'start();

    # Stops the listener, serving already-accepted requests first.
    #
    # + return - An `error` if the listener could not be stopped
    public isolated function gracefulStop() returns error? => self.wsListener.gracefulStop();

    # Stops the listener immediately.
    #
    # + return - An `error` if the listener could not be stopped
    public isolated function immediateStop() returns error? => self.wsListener.immediateStop();
}

isolated function createUpgradeService(VoiceService svc) returns websocket:UpgradeService {
    websocket:UpgradeService upgradeService = @websocket:ServiceConfig {
        maxFrameSize: MAX_FRAME_SIZE
    } isolated service object {
        isolated resource function get .(http:Request req) returns websocket:Service|websocket:UpgradeError {
            string sessionId = req.getQueryParamValue("sessionId") ?: uuid:createRandomUuid();
            return new VoiceConnection(svc, sessionId);
        }
    };
    return upgradeService;
}
