//
// This source file is part of the valkey-swift project
// Copyright (c) 2025 the valkey-swift project authors
//
// See LICENSE.txt for license information
// SPDX-License-Identifier: Apache-2.0
//
@usableFromInline
struct IndexedSubCollection<Base: Collection>: Collection {
    @usableFromInline
    typealias Element = Base.Element
    @usableFromInline
    typealias Index = [Base.Index].Index

    @usableFromInline
    let base: Base
    @usableFromInline
    let baseIndices: [Base.Index]

    @inlinable
    var startIndex: Index { self.baseIndices.startIndex }
    @inlinable
    var endIndex: Index { self.baseIndices.endIndex }

    @inlinable
    init(_ base: Base, indices: [Base.Index]) {
        self.base = base
        self.baseIndices = indices
    }

    @inlinable
    func index(after i: Array<Base.Index>.Index) -> Array<Base.Index>.Index {
        self.baseIndices.index(after: i)
    }

    @inlinable
    subscript(position: Index) -> Element {
        get {
            let index = self.baseIndices[position]
            return self.base[index]
        }
    }

    @inlinable
    subscript(index: Index) -> Base.Index {
        get {
            self.baseIndices[index]
        }
    }

    @usableFromInline
    struct Iterator: IteratorProtocol {
        @usableFromInline
        let base: Base
        @usableFromInline
        var iterator: [Base.Index].Iterator

        @inlinable
        init(base: Base, iterator: [Base.Index].Iterator) {
            self.base = base
            self.iterator = iterator
        }

        @inlinable
        mutating func next() -> Base.Element? {
            if let index = self.iterator.next() {
                return base[index]
            }
            return nil
        }
    }

    @inlinable
    func makeIterator() -> Iterator {
        .init(base: self.base, iterator: self.baseIndices.makeIterator())
    }
}

extension IndexedSubCollection: Sendable where Base: Sendable, Base.Index: Sendable {}
