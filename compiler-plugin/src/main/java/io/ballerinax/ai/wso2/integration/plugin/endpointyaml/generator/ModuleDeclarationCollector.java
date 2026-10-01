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

package io.ballerinax.ai.wso2.integration.plugin.endpointyaml.generator;

import io.ballerina.compiler.syntax.tree.CaptureBindingPatternNode;
import io.ballerina.compiler.syntax.tree.ListenerDeclarationNode;
import io.ballerina.compiler.syntax.tree.ModuleMemberDeclarationNode;
import io.ballerina.compiler.syntax.tree.ModulePartNode;
import io.ballerina.compiler.syntax.tree.ModuleVariableDeclarationNode;
import io.ballerina.compiler.syntax.tree.NodeVisitor;
import io.ballerina.projects.DocumentId;
import io.ballerina.projects.Module;

import java.util.HashMap;
import java.util.Map;
import java.util.Optional;

/**
 * Collects a module's top-level {@code listener} and module-variable declarations by name in a
 * single pass over its documents, so a listener/port variable reference can be resolved with a map
 * lookup rather than re-walking every document per lookup.
 */
final class ModuleDeclarationCollector extends NodeVisitor {

    private final Map<String, ListenerDeclarationNode> listeners = new HashMap<>();
    private final Map<String, ModuleVariableDeclarationNode> moduleVariables = new HashMap<>();

    private ModuleDeclarationCollector() {
    }

    static ModuleDeclarationCollector collect(Module module) {
        ModuleDeclarationCollector collector = new ModuleDeclarationCollector();
        for (DocumentId documentId : module.documentIds()) {
            module.document(documentId).syntaxTree().rootNode().accept(collector);
        }
        return collector;
    }

    Optional<ListenerDeclarationNode> listener(String name) {
        return Optional.ofNullable(listeners.get(name));
    }

    Optional<ModuleVariableDeclarationNode> moduleVariable(String name) {
        return Optional.ofNullable(moduleVariables.get(name));
    }

    @Override
    public void visit(ModulePartNode modulePartNode) {
        // Both declaration kinds only occur at module level, so don't descend into function bodies etc.
        for (ModuleMemberDeclarationNode member : modulePartNode.members()) {
            member.accept(this);
        }
    }

    /**
     * A listener declaration is a distinct node from a module variable declaration: it always
     * carries an initializer and names its variable directly via a {@code Token}, not a binding pattern.
     */
    @Override
    public void visit(ListenerDeclarationNode listenerDeclarationNode) {
        listeners.putIfAbsent(listenerDeclarationNode.variableName().text().trim(), listenerDeclarationNode);
    }

    @Override
    public void visit(ModuleVariableDeclarationNode moduleVariableDeclarationNode) {
        if (moduleVariableDeclarationNode.typedBindingPattern().bindingPattern()
                instanceof CaptureBindingPatternNode captureBindingPatternNode) {
            moduleVariables.putIfAbsent(captureBindingPatternNode.variableName().text().trim(),
                    moduleVariableDeclarationNode);
        }
    }
}
