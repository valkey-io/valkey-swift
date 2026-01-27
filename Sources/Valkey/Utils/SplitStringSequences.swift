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

    /// Check if separator matches at exact position
    @inlinable
    static func matchSeparatorAt<T: StringProtocol>(
        _ base: T,
        _ separator: String,
        position: T.Index
    ) -> Range<T.Index>? {
        var baseIndex = position
        var sepIndex = separator.startIndex

        while sepIndex < separator.endIndex {
            guard baseIndex < base.endIndex else { return nil }
            if base[baseIndex] != separator[sepIndex] { return nil }

            baseIndex = base.index(after: baseIndex)
            sepIndex = separator.index(after: sepIndex)
        }

        return position..<baseIndex
    }

    /// Search for separator substring within a string range
    @inlinable
    static func findSeparator<T: StringProtocol>(
        in base: T,
        separator: String,
        from startIndex: T.Index,
        anchored: Bool
    ) -> Range<T.Index>? {
        guard startIndex < base.endIndex else { return nil }

        if anchored {
            return matchSeparatorAt(base, separator, position: startIndex)
        } else {
            var currentIndex = startIndex
            while currentIndex < base.endIndex {
                if let matchRange = matchSeparatorAt(base, separator, position: currentIndex) {
                    return matchRange
                }
                currentIndex = base.index(after: currentIndex)
            }
            return nil
        }
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
                if let range = SplitStringSequence.findSeparator(in: base, separator: separator, from: index, anchored: true) {
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
            if let range = SplitStringSequence.findSeparator(in: base, separator: separator, from: currentIndex, anchored: false) {
                let component = base[start..<range.lowerBound]
                currentIndex = range.upperBound

                // Skip any additional separators
                while currentIndex < endIndex {
                    if let nextRange = SplitStringSequence.findSeparator(in: base, separator: separator, from: currentIndex, anchored: true) {
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

    /// Check if separator matches at exact position
    @inlinable
    static func matchSeparatorAt<T: StringProtocol>(
        _ base: T,
        _ separator: String,
        position: T.Index
    ) -> Range<T.Index>? {
        var baseIndex = position
        var sepIndex = separator.startIndex

        while sepIndex < separator.endIndex {
            guard baseIndex < base.endIndex else { return nil }
            if base[baseIndex] != separator[sepIndex] { return nil }

            baseIndex = base.index(after: baseIndex)
            sepIndex = separator.index(after: sepIndex)
        }

        return position..<baseIndex
    }

    /// Search for separator substring within a string range
    @inlinable
    static func findSeparator<T: StringProtocol>(
        in base: T,
        separator: String,
        from startIndex: T.Index,
        anchored: Bool
    ) -> Range<T.Index>? {
        guard startIndex < base.endIndex else { return nil }

        if anchored {
            return matchSeparatorAt(base, separator, position: startIndex)
        } else {
            var currentIndex = startIndex
            while currentIndex < base.endIndex {
                if let matchRange = matchSeparatorAt(base, separator, position: currentIndex) {
                    return matchRange
                }
                currentIndex = base.index(after: currentIndex)
            }
            return nil
        }
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
                if let range = SplitStringMaxSplitsSequence.findSeparator(in: base, separator: separator, from: index, anchored: true) {
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
            if let range = SplitStringMaxSplitsSequence.findSeparator(in: base, separator: separator, from: currentIndex, anchored: false) {
                let component = base[start..<range.lowerBound]
                currentIndex = range.upperBound

                // Skip any additional separators
                while currentIndex < endIndex {
                    if let nextRange = SplitStringMaxSplitsSequence.findSeparator(in: base, separator: separator, from: currentIndex, anchored: true)
                    {
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
