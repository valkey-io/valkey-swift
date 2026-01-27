//
// This source file is part of the valkey-swift project
// Copyright (c) 2026 the valkey-swift project authors
//
// See LICENSE.txt for license information
// SPDX-License-Identifier: Apache-2.0
//
// This implementation is adapted from Hummingbird:
// https://github.com/hummingbird-project/hummingbird/blob/main/Sources/Hummingbird/Utils/SplitStringSequences.swift
//

/// A sequence that iterates over string components separated by a given string separator,
/// omitting empty components.
import Foundation

@usableFromInline
struct SplitStringSequence<S: StringProtocol>: Sequence {
    @usableFromInline let base: S
    @usableFromInline let separator: String

    @inlinable
    init(_ base: S, separator: String = "/") {
        self.base = base
        self.separator = separator
    }

    @inlinable
    func makeIterator() -> Iterator {
        Iterator(base: base, separator: separator)
    }

    @usableFromInline
    struct Iterator: IteratorProtocol {
        @usableFromInline let base: S
        @usableFromInline let endIndex: S.Index
        @usableFromInline var currentIndex: S.Index
        @usableFromInline let separator: String

        @inlinable
        init(base: S, separator: String) {
            self.base = base
            self.separator = separator
            self.endIndex = base.endIndex
            // Skip leading separators
            var index = base.startIndex
            while index < base.endIndex {
                if let range = base[index...].range(of: separator, options: .anchored) {
                    index = range.upperBound
                } else {
                    break
                }
            }
            self.currentIndex = index
        }

        @inlinable
        mutating func next() -> S.SubSequence? {
            guard currentIndex < endIndex else { return nil }

            let start = currentIndex

            // Find next separator or end
            let searchRange = base[currentIndex...]
            if let range = searchRange.range(of: separator) {
                let component = base[start..<range.lowerBound]
                currentIndex = range.upperBound

                // Skip any additional separators
                while currentIndex < endIndex {
                    if let nextRange = base[currentIndex...].range(of: separator, options: .anchored) {
                        currentIndex = nextRange.upperBound
                    } else {
                        break
                    }
                }

                return component
            } else {
                // No more separators, return rest of string
                let component = base[start..<endIndex]
                currentIndex = endIndex
                return component
            }
        }
    }
}

/// A sequence that iterates over string components separated by a given string separator,
/// omitting empty components.
@usableFromInline
struct SplitStringMaxSplitsSequence<S: StringProtocol>: Sequence {
    @usableFromInline let base: S
    @usableFromInline let separator: String
    @usableFromInline let maxSplits: Int

    @inlinable
    init(_ base: S, separator: String, maxSplits: Int) {
        self.base = base
        self.separator = separator
        self.maxSplits = maxSplits
    }

    @inlinable
    func makeIterator() -> Iterator {
        Iterator(base: self.base, separator: self.separator, maxSplits: self.maxSplits)
    }

    @usableFromInline
    struct Iterator: IteratorProtocol {
        @usableFromInline let base: S
        @usableFromInline let endIndex: S.Index
        @usableFromInline var currentIndex: S.Index
        @usableFromInline var availableSplits: Int
        @usableFromInline let separator: String

        @inlinable
        init(base: S, separator: String, maxSplits: Int) {
            self.base = base
            self.separator = separator
            self.endIndex = base.endIndex
            // Skip leading separators
            var index = base.startIndex
            while index < base.endIndex {
                if let range = base[index...].range(of: separator, options: .anchored) {
                    index = range.upperBound
                } else {
                    break
                }
            }
            self.currentIndex = index
            self.availableSplits = maxSplits + 1
        }

        @inlinable
        mutating func next() -> S.SubSequence? {
            guard self.currentIndex < self.endIndex, self.availableSplits > 0 else { return nil }

            self.availableSplits -= 1
            if self.availableSplits == 0 {
                let component = base[self.currentIndex...]
                self.currentIndex = self.endIndex
                return component
            }

            let start = currentIndex

            // Find next separator or end
            let searchRange = base[currentIndex...]
            if let range = searchRange.range(of: separator) {
                let component = base[start..<range.lowerBound]
                currentIndex = range.upperBound

                // Skip any additional separators
                while currentIndex < endIndex {
                    if let nextRange = base[currentIndex...].range(of: separator, options: .anchored) {
                        currentIndex = nextRange.upperBound
                    } else {
                        break
                    }
                }

                return component
            } else {
                // No more separators, return rest of string
                let component = base[start..<endIndex]
                currentIndex = endIndex
                return component
            }
        }
    }
}

extension StringProtocol {
    @inlinable
    func splitSequence(separator: String) -> SplitStringSequence<Self> {
        SplitStringSequence(self, separator: separator)
    }

    @inlinable
    func splitMaxSplitsSequence(separator: String, maxSplits: Int) -> SplitStringMaxSplitsSequence<Self> {
        SplitStringMaxSplitsSequence(self, separator: separator, maxSplits: maxSplits)
    }
}
