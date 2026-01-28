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

/// Checks if a separator string matches at an exact position in the base string.
///
/// Performs character-by-character comparison.
/// The match must start exactly at the specified position (anchored match).
///
/// - Parameters:
///   - base: The string to search within
///   - separator: The substring to match (can be multi-character like "\r\n")
///   - position: The exact index where the match must start
/// - Returns: Range of the matched separator, or `nil` if no match or insufficient characters
/// - Complexity: O(m) where m is the length of the separator
@inlinable
func matchSeparatorAt<T: StringProtocol>(
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

/// Searches for the next occurrence of a separator string within the base string.
///
/// Performs either anchored (separator must be at exact position) or unanchored
/// (finds next occurrence anywhere after start) search.
///
/// - Parameters:
///   - base: The string to search within
///   - separator: The substring to find (can be multi-character like "\r\n")
///   - startIndex: The index to begin searching from
///   - anchored: If `true`, matches only at `startIndex`; if `false`, searches forward
/// - Returns: Range of the matched separator, or `nil` if no match found
/// - Complexity: Anchored O(m), Unanchored O(n*m) where n = string length, m = separator length
@inlinable
func findSeparator<T: StringProtocol>(
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

    @usableFromInline
    struct Iterator: IteratorProtocol {
        @usableFromInline let base: S
        @usableFromInline let endIndex: S.Index
        @usableFromInline var currentIndex: S.Index
        @usableFromInline let separator: String

        /// Creates a new iterator that will split the base string by the given separator.
        ///
        /// Skips any leading separator occurrences during initialization to ensure
        /// the first component returned is non-empty.
        ///
        /// - Parameters:
        ///   - base: The string to split
        ///   - separator: The separator string to split by
        @inlinable
        init(base: S, separator: String) {
            self.base = base
            self.separator = separator
            self.endIndex = base.endIndex
            // Skip leading separators
            var index = base.startIndex
            while index < base.endIndex {
                if let range = findSeparator(in: base, separator: separator, from: index, anchored: true) {
                    index = range.upperBound
                } else {
                    break
                }
            }
            self.currentIndex = index
        }

        /// Returns the next component in the split sequence.
        ///
        /// Finds the next separator and returns the substring before it. After finding
        /// a separator, skips any consecutive separators to avoid returning empty components.
        ///
        /// - Returns: The next non-empty substring component, or `nil` when iteration is complete
        @inlinable
        mutating func next() -> S.SubSequence? {
            guard currentIndex < endIndex else { return nil }

            let start = currentIndex

            // Find next separator or end
            if let range = findSeparator(in: base, separator: separator, from: currentIndex, anchored: false) {
                let component = base[start..<range.lowerBound]
                currentIndex = range.upperBound

                // Skip any additional separators
                while currentIndex < endIndex {
                    if let nextRange = findSeparator(in: base, separator: separator, from: currentIndex, anchored: true) {
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

        /// Creates a new iterator that will split the base string with a maximum number of splits.
        ///
        /// Skips leading separators during initialization. The `maxSplits` parameter controls
        /// how many times the string will be split - after reaching the limit, the remainder
        /// is returned as one component.
        ///
        /// - Parameters:
        ///   - base: The string to split
        ///   - separator: The separator string to split by
        ///   - maxSplits: Maximum number of splits (final component count = maxSplits + 1)
        @inlinable
        init(base: S, separator: String, maxSplits: Int) {
            self.base = base
            self.separator = separator
            self.endIndex = base.endIndex
            // Skip leading separators
            var index = base.startIndex
            while index < base.endIndex {
                if let range = findSeparator(in: base, separator: separator, from: index, anchored: true) {
                    index = range.upperBound
                } else {
                    break
                }
            }
            self.currentIndex = index
            self.availableSplits = maxSplits + 1
        }

        /// Returns the next component in the split sequence, respecting the maximum split limit.
        ///
        /// Behaves like the unlimited version but stops splitting after reaching `maxSplits`.
        /// Once the limit is reached, returns the entire remainder of the string as the final component.
        ///
        /// - Returns: The next substring component, or `nil` when iteration is complete
        @inlinable
        public mutating func next() -> S.SubSequence? {
            guard self.currentIndex < self.endIndex, self.availableSplits > 0 else { return nil }

            self.availableSplits -= 1
            if self.availableSplits == 0 {
                let component = base[self.currentIndex...]
                self.currentIndex = self.endIndex
                return component
            }

            let start = currentIndex

            // Find next separator or end
            if let range = findSeparator(in: base, separator: separator, from: currentIndex, anchored: false) {
                let component = base[start..<range.lowerBound]
                currentIndex = range.upperBound

                // Skip any additional separators
                while currentIndex < endIndex {
                    if let nextRange = findSeparator(in: base, separator: separator, from: currentIndex, anchored: true) {
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
    /// Returns a sequence that splits this string by the given separator, omitting empty components.
    ///
    /// Creates a lazy sequence that splits the string each time a separator is found.
    /// Consecutive separators are treated as a single separator. Leading separators are skipped.
    ///
    /// - Parameter separator: The separator string to split by (can be multi-character)
    /// - Returns: A sequence of non-empty substring components
    @inlinable
    func splitSequence(separator: String) -> SplitStringSequence<Self> {
        SplitStringSequence(self, separator: separator)
    }

    /// Returns a sequence that splits this string by the given separator up to a maximum number of times.
    ///
    /// Creates a lazy sequence that splits the string up to `maxSplits` times.
    /// After reaching the limit, the remainder of the string is returned as a single component.
    /// Consecutive and leading separators are skipped.
    ///
    /// - Parameters:
    ///   - separator: The separator string to split by (can be multi-character)
    ///   - maxSplits: Maximum number of splits to perform
    /// - Returns: A sequence with at most `maxSplits + 1` components
    @inlinable
    func splitMaxSplitsSequence(separator: String, maxSplits: Int) -> SplitStringMaxSplitsSequence<Self> {
        SplitStringMaxSplitsSequence(self, separator: separator, maxSplits: maxSplits)
    }
}
