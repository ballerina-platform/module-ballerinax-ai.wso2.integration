/*
 * Copyright (c) 2026, WSO2 LLC. (http://www.wso2.com).
 *
 * WSO2 LLC. licenses this file to you under the Apache License,
 * Version 2.0 (the "License"); you may not use this file except
 * in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing,
 * software distributed under the License is distributed on an
 * "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 * KIND, either express or implied. See the License for the
 * specific language governing permissions and limitations
 * under the License.
 */

package io.ballerinax.ai.wso2.integration.plugin;

import io.ballerina.tools.diagnostics.DiagnosticSeverity;

/**
 * Shared constants for the ai.wso2.integration compiler plugin.
 */
public final class PluginConstants {

    public static final String PACKAGE_ORG = "ballerinax";
    public static final String PACKAGE_NAME = "ai.wso2.integration";
    public static final String LISTENER_NAME = "CloudVoiceListener";
    public static final String CHAT_MESSAGE_TYPE = "ChatMessage";
    public static final String ON_CHAT_MESSAGE = "onChatMessage";

    public static final String CTX_DATA_ENDPOINTS = "AiWso2IntegrationExportedEndpoints";
    public static final String CTX_DATA_OLD_DISTRO_REPORTED = "AiWso2IntegrationOldDistroReported";

    private PluginConstants() {
    }

    /**
     * Diagnostic codes reported by this plugin. All are warnings: each one means a {@code service on
     * <CloudVoiceListener>} is left out of the {@code endpoints.yaml} that {@code bal build
     * --export-endpoints} generates, never a reason to fail the build.
     */
    public enum DiagnosticCodes {
        PORT_RESOLUTION_FAILED("AIWSO2INT_101",
                "Unable to statically resolve the port of this CloudVoiceListener; the service is excluded from "
                        + "the generated endpoints.yaml. Pass the port as an int literal or a configurable int "
                        + "variable with a literal default value.",
                DiagnosticSeverity.WARNING),
        OLD_DISTRO_NOT_SUPPORTED("AIWSO2INT_102",
                "endpoints.yaml generation for CloudVoiceListener services is not supported by the Ballerina "
                        + "distribution in use. Try using Ballerina 2201.13.6 or above.",
                DiagnosticSeverity.WARNING),
        SCHEMA_WRITE_FAILED("AIWSO2INT_103",
                "Failed to write the AsyncAPI schema file for this service; the service is excluded from the "
                        + "generated endpoints.yaml.",
                DiagnosticSeverity.WARNING);

        private final String code;
        private final String message;
        private final DiagnosticSeverity severity;

        DiagnosticCodes(String code, String message, DiagnosticSeverity severity) {
            this.code = code;
            this.message = message;
            this.severity = severity;
        }

        public String code() {
            return code;
        }

        public String message() {
            return message;
        }

        public DiagnosticSeverity severity() {
            return severity;
        }
    }
}
