//
// This source file is part of the valkey-swift project
// Copyright (c) 2025-2026 the valkey-swift project authors
//
// See LICENSE.txt for license information
// SPDX-License-Identifier: Apache-2.0
//

import Valkey

// MARK: Backwards compatibility

extension FT.AGGREGATE.Load {
    @inlinable
    public static func fields(_ fields: [String]) -> Self {
        .fields(fields.map { FT.AGGREGATE.LoadFields(field: $0) })
    }
}

extension FT.AGGREGATE {
    @_disfavoredOverload
    @available(*, deprecated, message: "Use FT.AGGREGATE.init with sortbys array parameter")
    @inlinable public init(
        index: ValkeyKey,
        query: Query,
        addscores: Bool = false,
        dialect: Int? = nil,
        inorder: Bool = false,
        load: Load? = nil,
        params: [Params] = [],
        scorer: String? = nil,
        slop: Int? = nil,
        timeout: Int? = nil,
        verbatim: Bool = false,
        applys: [Apply] = [],
        filters: [String] = [],
        groupbys: [Groupby] = [],
        limits: [Limit] = [],
        sortby: Sortby? = nil,
        withcursor: Withcursor? = nil
    ) {
        self.index = index
        self.query = query
        self.addscores = addscores
        self.dialect = dialect
        self.inorder = inorder
        self.load = load
        self.params = params
        self.scorer = scorer
        self.slop = slop
        self.timeout = timeout
        self.verbatim = verbatim
        self.applys = applys
        self.filters = filters
        self.groupbys = groupbys
        self.limits = limits
        self.sortbys = sortby.map { [$0] } ?? []
        self.withcursor = withcursor
    }
}

extension FT.CREATE {
    @_disfavoredOverload
    @available(*, deprecated, message: "Use FT.CREATE.init with language enum parameter")
    @inlinable public init(
        indexName: IndexName,
        on: On? = nil,
        prefixes: [String] = [],
        filter: String? = nil,
        score: String? = nil,
        scoreField: String? = nil,
        language: String? = nil,
        skipinitialscan: Bool = false,
        minstemsize: Int? = nil,
        nohl: Bool = false,
        offsets: Offsets? = nil,
        stopwords: Stopwords? = nil,
        punctuation: String? = nil,
        schemas: [Schema]
    ) {
        self.indexName = indexName
        self.on = on
        self.prefixes = prefixes
        self.filter = filter
        self.score = score
        self.scoreField = scoreField
        self.language = language.flatMap { .init(string: $0) }
        self.skipinitialscan = skipinitialscan
        self.minstemsize = minstemsize
        self.nohl = nohl
        self.offsets = offsets
        self.stopwords = stopwords
        self.punctuation = punctuation
        self.schemas = schemas
        self.nostem = false
    }
}

extension FT.CREATE.Language {
    @usableFromInline
    init(string value: String) {
        switch value {
        case "ARABIC": self = .arabic
        case "DUTCH": self = .dutch
        case "ENGLISH": self = .english
        case "FRENCH": self = .french
        case "GERMAN": self = .german
        case "INDONESIAN": self = .indonesian
        case "ITALIAN": self = .italian
        case "PORTUGUESE": self = .portuguese
        case "RUSSIAN": self = .russian
        case "SPANISH": self = .spanish
        case "SWEDISH": self = .swedish
        case "TURKISH": self = .turkish
        default: fatalError("\(value) is not a supported language")
        }
    }
}

extension FT.CREATE.Schema {
    @inlinable
    @_disfavoredOverload
    @available(*, deprecated, message: "Use FT.CREATE.Schema.init with sortable SchemaSortable parameter")
    public init(
        fieldIdentifier: FieldIdentifier,
        alias: String? = nil,
        fieldType: FT.CREATE<IndexName, FieldIdentifier>.SchemaFieldType,
        sortable: Bool = false
    ) {
        self.fieldIdentifier = fieldIdentifier
        self.alias = alias
        self.fieldType = fieldType
        self.sortable = sortable ? .init(unf: false) : nil
    }
}

@available(valkeySwift 1.0, *)
extension ValkeyClientProtocol {
    /// Performs a search of the specified index. The keys which match the query expression are subjected to further processing as specified
    ///
    /// - Documentation: [FT.AGGREGATE](https://valkey.io/commands/ft.aggregate)
    /// - History:
    ///     * 1.2.0: Added Text Indexing and Search support
    ///     * 1.3.0: Added WITHCURSOR, ADDSCORES and SCORER options; TOLIST, FIRST_VALUE, RANDOM_SAMPLE, COUNT_DISTINCTISH and QUANTILE reducers; the case() expression function; GROUPBY 0; VECTOR_RANGE queries and HYBRID_POLICY; VERBATIM, INORDER and SLOP are honored. With `search.emulate-release 1.3.0`: LOAD ... AS, Redisearch-compatible default reducer names, SORTBY bounded by an adjacent LIMIT, Redisearch-compatible operator precedence, type-sensitive comparisons and missing-field handling in expressions
    /// - Complexity: O(log N)
    @inlinable
    @_disfavoredOverload
    @available(*, deprecated, message: "Use ftAggregate with sortbys array parameter")
    @discardableResult
    public func ftAggregate<Query: RESPStringRenderable>(
        index: ValkeyKey,
        query: Query,
        addscores: Bool = false,
        dialect: Int? = nil,
        inorder: Bool = false,
        load: FT.AGGREGATE<Query>.Load? = nil,
        params: [FT.AGGREGATE<Query>.Params] = [],
        scorer: String? = nil,
        slop: Int? = nil,
        timeout: Int? = nil,
        verbatim: Bool = false,
        applys: [FT.AGGREGATE<Query>.Apply] = [],
        filters: [String] = [],
        groupbys: [FT.AGGREGATE<Query>.Groupby] = [],
        limits: [FT.AGGREGATE<Query>.Limit] = [],
        sortby: FT.AGGREGATE<Query>.Sortby? = nil,
        withcursor: FT.AGGREGATE<Query>.Withcursor? = nil
    ) async throws(ValkeyClientError) -> RESPToken {
        try await execute(
            FT.AGGREGATE(
                index: index,
                query: query,
                addscores: addscores,
                dialect: dialect,
                inorder: inorder,
                load: load,
                params: params,
                scorer: scorer,
                slop: slop,
                timeout: timeout,
                verbatim: verbatim,
                applys: applys,
                filters: filters,
                groupbys: groupbys,
                limits: limits,
                sortby: sortby,
                withcursor: withcursor
            )
        )
    }

    /// Creates an empty search index and initiates the backfill process
    ///
    /// - Documentation: [FT.CREATE](https://valkey.io/commands/ft.create)
    /// - History:
    ///     * 1.2.0: Added Text Indexing and Search support
    ///     * 1.3.0: Added FILTER, SCORE_FIELD, NOHL and SORTABLE UNF options; SCORE accepts values in [0, 1]; FLOAT16 and BFLOAT16 vector types; LANGUAGE values beyond ENGLISH, with per-language punctuation, stop words, and stemming; the same field may be indexed under multiple aliases; PREFIX (like FILTER) may appear anywhere among the options between ON and SCHEMA. With `search.emulate-release` 1.3.0 or later, invalid field data drops the whole key and TAG rejects non-UTF-8 values
    /// - Complexity: Construction time O(N log N), where N is the number of indexed items
    @inlinable
    @_disfavoredOverload
    @available(*, deprecated, message: "Use ftCreate with language enum parameter")
    @discardableResult
    public func ftCreate<IndexName: RESPStringRenderable, FieldIdentifier: RESPStringRenderable>(
        indexName: IndexName,
        on: FT.CREATE<IndexName, FieldIdentifier>.On? = nil,
        prefixes: [String] = [],
        filter: String? = nil,
        score: String? = nil,
        scoreField: String? = nil,
        language: String? = nil,
        skipinitialscan: Bool = false,
        minstemsize: Int? = nil,
        nohl: Bool = false,
        offsets: FT.CREATE<IndexName, FieldIdentifier>.Offsets? = nil,
        stopwords: FT.CREATE<IndexName, FieldIdentifier>.Stopwords? = nil,
        punctuation: String? = nil,
        schemas: [FT.CREATE<IndexName, FieldIdentifier>.Schema]
    ) async throws(ValkeyClientError) -> RESPToken {
        try await execute(
            FT.CREATE(
                indexName: indexName,
                on: on,
                prefixes: prefixes,
                filter: filter,
                score: score,
                scoreField: scoreField,
                language: language,
                skipinitialscan: skipinitialscan,
                minstemsize: minstemsize,
                nohl: nohl,
                offsets: offsets,
                stopwords: stopwords,
                punctuation: punctuation,
                schemas: schemas
            )
        )
    }
}
