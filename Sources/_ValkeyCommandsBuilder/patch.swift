//
// This source file is part of the valkey-swift project
// Copyright (c) 2025 the valkey-swift project authors
//
// See LICENSE.txt for license information
// SPDX-License-Identifier: Apache-2.0
//

struct ValkeyPatchError: Error {}

/// Patch to apply to argument
protocol ArgumentPatch {
    func apply(to: ValkeyCommand.Argument) -> ValkeyCommand.Argument
}

/// Patch that replaces argument
struct ReplaceArgumentPatch: ArgumentPatch {
    let replacement: ValkeyCommand.Argument

    func apply(to: ValkeyCommand.Argument) -> ValkeyCommand.Argument {
        replacement
    }
}

extension ArgumentPatch where Self == ReplaceArgumentPatch {
    static func replace(_ replacement: ValkeyCommand.Argument) -> ReplaceArgumentPatch {
        .init(replacement: replacement)
    }
}

/// Patch that sets a single field in the parameter
struct SetFieldPatch<Value>: ArgumentPatch {
    let keyPath: WritableKeyPath<ValkeyCommand.Argument, Value>
    let value: Value

    func apply(to original: ValkeyCommand.Argument) -> ValkeyCommand.Argument {
        var argument = original
        argument[keyPath: keyPath] = value
        return argument
    }
}

extension ArgumentPatch where Self == SetFieldPatch<String> {
    static func set(_ keyPath: WritableKeyPath<ValkeyCommand.Argument, String>, value: String) -> SetFieldPatch<String> {
        .init(keyPath: keyPath, value: value)
    }
}

extension ArgumentPatch where Self == SetFieldPatch<Bool> {
    static func set(_ keyPath: WritableKeyPath<ValkeyCommand.Argument, Self>, value: Self) -> SetFieldPatch<Self> {
        .init(keyPath: keyPath, value: value)
    }
}

extension ArgumentPatch where Self == SetFieldPatch<ValkeyCommand.Argument.ArrayCount> {
    static func set(
        _ keyPath: WritableKeyPath<ValkeyCommand.Argument, ValkeyCommand.Argument.ArrayCount>,
        value: ValkeyCommand.Argument.ArrayCount
    ) -> SetFieldPatch<ValkeyCommand.Argument.ArrayCount> {
        .init(keyPath: keyPath, value: value)
    }
}

/// Patch applied to command.
struct CommandPatch {
    /// command name
    let command: String
    /// argument path
    let path: [String]
    /// patch to apply
    let patch: any ArgumentPatch

    init(_ command: String, path: [String], patch: any ArgumentPatch) {
        self.command = command
        self.path = path
        self.patch = patch
    }
}

extension ValkeyCommand {
    /// Patch arguments of command
    mutating func patchArguments(_ path: [String], patch: some ArgumentPatch) throws {
        guard let arguments = self.arguments else { throw ValkeyPatchError() }
        guard let index = self.arguments?.firstIndex(where: { $0.name == path.first }) else { throw ValkeyPatchError() }
        if path.count == 1 {
            self.arguments?[index] = patch.apply(to: arguments[index])
        } else {
            try self.arguments?[index].patch(path.dropFirst(), patch: patch)
        }
    }
}

extension ValkeyCommand.Argument {
    /// Patch arguments of argument
    mutating func patch(_ path: ArraySlice<String>, patch: some ArgumentPatch) throws {
        guard let arguments = self.arguments else { throw ValkeyPatchError() }
        guard let index = self.arguments?.firstIndex(where: { $0.name == path.first }) else { throw ValkeyPatchError() }
        if path.count == 1 {
            self.arguments?[index] = patch.apply(to: arguments[index])
        } else {
            try self.arguments?[index].patch(path.dropFirst(), patch: patch)
        }
    }
}

extension ValkeyCommands {
    /// Patch commands
    func patch(_ patches: [CommandPatch]) throws {
        for patch in patches {
            try self.patch(patch.command, path: patch.path, patch: patch.patch)
        }
    }

    /// Patch a single command
    func patch(_ command: String, path: [String], patch: some ArgumentPatch) throws {
        guard self.commands[command] != nil else { throw ValkeyPatchError() }
        try self.commands[command]?.patchArguments(path, patch: patch)
    }
}

extension [CommandPatch] {
    /// Patches applied to ValkeySearch module
    static var searchPatches: [CommandPatch] {
        [
            // FT.AGGREGATE sort parameters are not grouped into expression and direction
            .init(
                "FT.AGGREGATE",
                path: ["SORTBY", "sort_params"],
                patch: .replace(
                    .init(
                        name: "expression",
                        type: .block,
                        multiple: true,
                        arguments: [
                            .init(name: "expression", type: .string),
                            .init(
                                name: "direction",
                                type: .oneOf,
                                optional: true,
                                arguments: [
                                    .init(name: "ASC", type: .pureToken, token: "ASC"),
                                    .init(name: "DESC", type: .pureToken, token: "DESC"),
                                ]
                            ),
                        ],
                        combinedWithCount: .parameterCount
                    )
                )
            ),
            // params field and value are counted separately
            .init("FT.AGGREGATE", path: ["PARAMS"], patch: .set(\.combinedWithCount, value: .parameterCount)),
            // params field and value are counted separately
            .init("FT.SEARCH", path: ["PARAMS"], patch: .set(\.combinedWithCount, value: .parameterCount)),
            // FT.CREATE vector type should be an enum of the different kinds even though there
            // is only one type at the moment
            .init(
                "FT.CREATE",
                path: ["schema", "field-type", "VECTOR", "vector-params", "type"],
                patch: .replace(
                    .init(
                        name: "type",
                        type: .oneOf,
                        token: "TYPE",
                        arguments: [
                            .init(name: "float32", type: .pureToken, token: "FLOAT32")
                        ]
                    )
                )
            ),
        ]
    }
}
