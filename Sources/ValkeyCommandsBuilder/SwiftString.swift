//===----------------------------------------------------------------------===//
//
// This source file is part of the swift-valkey open source project
//
// Copyright (c) 2025 the swift-valkey project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of swift-valkey project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

extension StringProtocol {
    var swiftFunction: String {
        self
            .lowercased()
            .replacingOccurrences(of: "-", with: "_")
            .replacingOccurrences(of: " ", with: "_")
            .camelCased(capitalize: false)
    }

    var swiftArgument: String {
        self
            .lowercased()
            .replacingOccurrences(of: "-", with: "_")
            .replacingOccurrences(of: " ", with: "_")
            .camelCased(capitalize: false)
    }

    var swiftVariable: String {
        self
            .lowercased()
            .replacingOccurrences(of: "-", with: "_")
            .replacingOccurrences(of: " ", with: "_")
            .camelCased(capitalize: false)
            .reservedwordEscaped()
    }
    var swiftTypename: String {
        self
            .lowercased()
            .replacingOccurrences(of: "-", with: "_")
            .replacingOccurrences(of: " ", with: "_")
            .camelCased(capitalize: false)
            .upperFirst()
    }
    var commandTypeName: String {
        self
            .replacingOccurrences(of: "-", with: "_")
            .replacingOccurrences(of: " ", with: ".")
            .camelCased(capitalize: false)
            .uppercased()
    }

    var escaped: String {
        self.replacingOccurrences(of: "\"", with: "\\\"")
    }

    func camelCased(capitalize: Bool) -> String {
        let items = self.split(separator: "_")
        let firstWord = items.first!
        let firstWordProcessed: String
        if capitalize {
            firstWordProcessed = firstWord.upperFirst()
        } else {
            firstWordProcessed = firstWord.lowerFirstWord()
        }
        let remainingItems = items.dropFirst().map { word -> String in
            if word.allLetterIsSnakeUppercased() {
                return String(word)
            }
            return word.capitalized
        }
        return firstWordProcessed + remainingItems.joined()
    }

    func lowerFirst() -> String {
        String(self[startIndex]).lowercased() + self[index(after: startIndex)...]
    }

    func upperFirst() -> String {
        String(self[self.startIndex]).uppercased() + self[index(after: startIndex)...]
    }

    /// Lowercase first letter, or if first word is an uppercase acronym then lowercase the whole of the acronym
    func lowerFirstWord() -> String {
        var firstLowercase = self.startIndex
        var lastUppercaseOptional: Self.Index?
        // get last uppercase character, first lowercase character
        while firstLowercase != self.endIndex, self[firstLowercase].isSnakeUppercase() {
            lastUppercaseOptional = firstLowercase
            firstLowercase = self.index(after: firstLowercase)
        }
        // if first character was never set first character must be lowercase
        guard let lastUppercase = lastUppercaseOptional else {
            return String(self)
        }
        if firstLowercase == self.endIndex {
            // if first lowercase letter is the end index then whole word is uppercase and
            // should be wholly lowercased
            return self.lowercased()
        } else if lastUppercase == self.startIndex {
            // if last uppercase letter is the first letter then only lower that character
            return self.lowerFirst()
        } else {
            // We have an acronym at the start, lowercase the whole of it
            return self[startIndex..<lastUppercase].lowercased() + self[lastUppercase...]
        }
    }

    fileprivate func allLetterIsSnakeUppercased() -> Bool {
        for c in self {
            if !c.isSnakeUppercase() {
                return false
            }
        }
        return true
    }

    func dropPrefix<S: StringProtocol>(_ prefix: S) -> Self.SubSequence {
        if hasPrefix(prefix) {
            return self.dropFirst(prefix.count)
        } else {
            return self[...]
        }
    }
}

extension String {
    func reservedwordEscaped() -> String {
        if self == "self" {
            return "_self"
        }
        if swiftReservedWords.contains(self) {
            return "`\(self)`"
        }
        return self
    }
}

extension Character {
    fileprivate func isSnakeUppercase() -> Bool {
        self.isNumber || ("A"..."Z").contains(self) || self == "_"
    }
}

// List of keywords we've had clashes with
private let swiftReservedWords: Set<String> = [
    "where",
    "operator",
]
