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

import io.ballerina.compiler.api.symbols.ServiceDeclarationSymbol;
import io.ballerina.compiler.api.symbols.Symbol;
import io.ballerina.compiler.syntax.tree.ServiceDeclarationNode;
import io.ballerina.projects.BuildOptions;
import io.ballerina.projects.Project;
import io.ballerina.projects.plugins.AnalysisTask;
import io.ballerina.projects.plugins.SyntaxNodeAnalysisContext;
import io.ballerina.tools.diagnostics.Diagnostic;
import io.ballerina.tools.diagnostics.DiagnosticSeverity;
import io.ballerinax.ai.wso2.integration.plugin.endpointyaml.generator.Endpoint;
import io.ballerinax.ai.wso2.integration.plugin.endpointyaml.generator.EndpointYamlGenerator;

import java.util.List;
import java.util.Map;
import java.util.Optional;

/**
 * Analysis task that, when {@code --export-endpoints} is set, collects every {@code service on
 * <CloudVoiceListener>} declaration's endpoint details for {@link
 * io.ballerinax.ai.wso2.integration.plugin.endpointyaml.generator.EndpointMetadataTask} to add to
 * the generated {@code endpoints.yaml} once code generation completes.
 */
public class VoiceServiceAnalysisTask implements AnalysisTask<SyntaxNodeAnalysisContext> {

    /** Added in ballerina-lang 2201.13.6; {@code --export-endpoints} itself predates it (2201.13.2). */
    private static final String ENDPOINT_META_INFO_CLASS = "io.ballerina.projects.plugins.EndpointMetaInfo";
    private static final boolean ENDPOINT_METADATA_SUPPORTED = isClassPresent(ENDPOINT_META_INFO_CLASS);

    private final Map<String, Object> ctxData;

    VoiceServiceAnalysisTask(Map<String, Object> ctxData) {
        this.ctxData = ctxData;
    }

    @Override
    @SuppressWarnings("unchecked")
    public void perform(SyntaxNodeAnalysisContext context) {
        Project project = context.currentPackage().project();
        if (!isExportEndpoints(project.buildOptions())) {
            return;
        }
        for (Diagnostic diagnostic : context.semanticModel().diagnostics()) {
            if (diagnostic.diagnosticInfo().severity() == DiagnosticSeverity.ERROR) {
                // Don't collect endpoint data over a service declaration with pre-existing errors.
                return;
            }
        }

        ServiceDeclarationNode serviceNode = (ServiceDeclarationNode) context.node();
        Optional<Symbol> symbol = context.semanticModel().symbol(serviceNode);
        if (symbol.isEmpty() || !(symbol.get() instanceof ServiceDeclarationSymbol serviceDeclarationSymbol)) {
            return;
        }

        EndpointYamlGenerator generator = new EndpointYamlGenerator(context, serviceNode);
        if (!generator.isVoiceListenerService(serviceDeclarationSymbol)) {
            return;
        }
        if (!ENDPOINT_METADATA_SUPPORTED) {
            // Report once per compilation, not once per service.
            if (ctxData.putIfAbsent(PluginConstants.CTX_DATA_OLD_DISTRO_REPORTED, Boolean.TRUE) == null) {
                context.reportDiagnostic(PluginUtils.getDiagnostic(
                        PluginConstants.DiagnosticCodes.OLD_DISTRO_NOT_SUPPORTED, serviceNode.location()));
            }
            return;
        }

        Optional<Endpoint> endpoint = generator.getEndpoint(serviceDeclarationSymbol);
        if (endpoint.isEmpty()) {
            return;
        }
        List<Endpoint> collected = (List<Endpoint>) ctxData.get(PluginConstants.CTX_DATA_ENDPOINTS);
        collected.add(endpoint.get());
    }

    private boolean isExportEndpoints(BuildOptions buildOptions) {
        try {
            return buildOptions.exportEndpoints();
        } catch (NoSuchMethodError e) {
            // Distributions older than 2201.13.2 can't pass --export-endpoints at all, so there's
            // nothing to warn about.
            return false;
        }
    }

    private static boolean isClassPresent(String className) {
        try {
            Class.forName(className, false, VoiceServiceAnalysisTask.class.getClassLoader());
            return true;
        } catch (ClassNotFoundException | LinkageError e) {
            return false;
        }
    }
}
