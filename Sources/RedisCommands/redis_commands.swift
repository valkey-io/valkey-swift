import NIOCore
import Redis
import RESP

#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

extension RESPCommand {
    /// Lists the ACL categories, or the commands inside a category.
    ///
    /// - Documentation: [ACL CAT](https:/redis.io/docs/latest/commands/acl-cat)
    /// - Version: 6.0.0
    /// - Complexity: O(1) since the categories and commands are a fixed set.
    /// - Categories: @slow
    /// - Response: One of the following:
    ///     * [Array](https:/redis.io/docs/reference/protocol-spec#arrays): an array of [Bulk string](https:/redis.io/docs/reference/protocol-spec#bulk-strings) elements representing ACL categories or commands in a given category.
    ///     * [Simple error](https:/redis.io/docs/reference/protocol-spec#simple-errors): the command returns an error if an invalid category name is given.
    @inlinable
    public static func aclCat(category: String? = nil) -> RESPCommand {
        RESPCommand("ACL", "CAT", category)
    }

    /// Deletes ACL users, and terminates their connections.
    ///
    /// - Documentation: [ACL DELUSER](https:/redis.io/docs/latest/commands/acl-deluser)
    /// - Version: 6.0.0
    /// - Complexity: O(1) amortized time considering the typical user.
    /// - Categories: @admin, @slow, @dangerous
    /// - Response: [Integer](https:/redis.io/docs/reference/protocol-spec#integers): the number of users that were deleted. This number will not always match the number of arguments since certain users may not exist.
    @inlinable
    public static func aclDeluser(username: String) -> RESPCommand {
        RESPCommand("ACL", "DELUSER", username)
    }

    /// Deletes ACL users, and terminates their connections.
    ///
    /// - Documentation: [ACL DELUSER](https:/redis.io/docs/latest/commands/acl-deluser)
    /// - Version: 6.0.0
    /// - Complexity: O(1) amortized time considering the typical user.
    /// - Categories: @admin, @slow, @dangerous
    /// - Response: [Integer](https:/redis.io/docs/reference/protocol-spec#integers): the number of users that were deleted. This number will not always match the number of arguments since certain users may not exist.
    @inlinable
    public static func aclDeluser(usernames: [String]) -> RESPCommand {
        RESPCommand("ACL", "DELUSER", usernames)
    }

    /// Simulates the execution of a command by a user, without executing the command.
    ///
    /// - Documentation: [ACL DRYRUN](https:/redis.io/docs/latest/commands/acl-dryrun)
    /// - Version: 7.0.0
    /// - Complexity: O(1).
    /// - Categories: @admin, @slow, @dangerous
    /// - Response: Any of the following:
    ///     * [Simple string](https:/redis.io/docs/reference/protocol-spec#simple-strings): `OK` on success.
    ///     * [Bulk string](https:/redis.io/docs/reference/protocol-spec#bulk-strings): an error describing why the user can't execute the command.
    @inlinable
    public static func aclDryrun(username: String, command: String, arg: String? = nil) -> RESPCommand {
        RESPCommand("ACL", "DRYRUN", username, command, arg)
    }

    /// Simulates the execution of a command by a user, without executing the command.
    ///
    /// - Documentation: [ACL DRYRUN](https:/redis.io/docs/latest/commands/acl-dryrun)
    /// - Version: 7.0.0
    /// - Complexity: O(1).
    /// - Categories: @admin, @slow, @dangerous
    /// - Response: Any of the following:
    ///     * [Simple string](https:/redis.io/docs/reference/protocol-spec#simple-strings): `OK` on success.
    ///     * [Bulk string](https:/redis.io/docs/reference/protocol-spec#bulk-strings): an error describing why the user can't execute the command.
    @inlinable
    public static func aclDryrun(username: String, command: String, args: [String]) -> RESPCommand {
        RESPCommand("ACL", "DRYRUN", username, command, args)
    }

    /// Generates a pseudorandom, secure password that can be used to identify ACL users.
    ///
    /// - Documentation: [ACL GENPASS](https:/redis.io/docs/latest/commands/acl-genpass)
    /// - Version: 6.0.0
    /// - Complexity: O(1)
    /// - Categories: @slow
    /// - Response: [Bulk string](https:/redis.io/docs/reference/protocol-spec#bulk-strings): pseudorandom data. By default it contains 64 bytes, representing 256 bits of data. If `bits` was given, the output string length is the number of specified bits (rounded to the next multiple of 4) divided by 4.
    @inlinable
    public static func aclGenpass(bits: Int? = nil) -> RESPCommand {
        RESPCommand("ACL", "GENPASS", bits)
    }

    /// Lists the ACL rules of a user.
    ///
    /// - Documentation: [ACL GETUSER](https:/redis.io/docs/latest/commands/acl-getuser)
    /// - Version: 6.0.0
    /// - Complexity: O(N). Where N is the number of password, command and pattern rules that the user has.
    /// - Categories: @admin, @slow, @dangerous
    /// - Response: One of the following:
    ///     * [Map](https:/redis.io/docs/reference/protocol-spec#maps): a set of ACL rule definitions for the user
    ///     * [Null](https:/redis.io/docs/reference/protocol-spec#nulls): if user does not exist.
    @inlinable
    public static func aclGetuser(username: String) -> RESPCommand {
        RESPCommand("ACL", "GETUSER", username)
    }

    /// Returns helpful text about the different subcommands.
    ///
    /// - Documentation: [ACL HELP](https:/redis.io/docs/latest/commands/acl-help)
    /// - Version: 6.0.0
    /// - Complexity: O(1)
    /// - Categories: @slow
    /// - Response: [Array](https:/redis.io/docs/reference/protocol-spec#arrays): a list of subcommands and their descriptions.
    @inlinable
    public static func aclHelp() -> RESPCommand {
        RESPCommand("ACL", "HELP")
    }

    /// Dumps the effective rules in ACL file format.
    ///
    /// - Documentation: [ACL LIST](https:/redis.io/docs/latest/commands/acl-list)
    /// - Version: 6.0.0
    /// - Complexity: O(N). Where N is the number of configured users.
    /// - Categories: @admin, @slow, @dangerous
    /// - Response: [Array](https:/redis.io/docs/reference/protocol-spec#arrays): an array of [Bulk string](https:/redis.io/docs/reference/protocol-spec#bulk-strings) elements.
    @inlinable
    public static func aclList() -> RESPCommand {
        RESPCommand("ACL", "LIST")
    }

    /// Reloads the rules from the configured ACL file.
    ///
    /// - Documentation: [ACL LOAD](https:/redis.io/docs/latest/commands/acl-load)
    /// - Version: 6.0.0
    /// - Complexity: O(N). Where N is the number of configured users.
    /// - Categories: @admin, @slow, @dangerous
    /// - Response: [Simple string](https:/redis.io/docs/reference/protocol-spec#simple-strings): `OK` on success.
    ///     
    ///     The command may fail with an error for several reasons: if the file is not readable, if there is an error inside the file, and in such cases, the error will be reported to the user in the error.
    ///     Finally, the command will fail if the server is not configured to use an external ACL file.
    @inlinable
    public static func aclLoad() -> RESPCommand {
        RESPCommand("ACL", "LOAD")
    }

    public enum ACLLOGOperation: RESPRenderable {
        case count(Int)
        case reset

        @inlinable
        public func writeToRESPBuffer(_ buffer: inout ByteBuffer) -> Int {
            switch self {
            case .count(let count): count.writeToRESPBuffer(&buffer)
            case .reset: "RESET".writeToRESPBuffer(&buffer)
            }
        }
    }
    /// Lists recent security events generated due to ACL rules.
    ///
    /// - Documentation: [ACL LOG](https:/redis.io/docs/latest/commands/acl-log)
    /// - Version: 6.0.0
    /// - Complexity: O(N) with N being the number of entries shown.
    /// - Categories: @admin, @slow, @dangerous
    /// - Response: When called to show security events:
    ///     * [Array](https:/redis.io/docs/reference/protocol-spec#arrays): an array of [Bulk string](https:/redis.io/docs/reference/protocol-spec#bulk-strings) elements representing ACL security events.
    ///     When called with `RESET`:
    ///     * [Simple string](https:/redis.io/docs/reference/protocol-spec#simple-strings): `OK` if the security log was cleared.
    @inlinable
    public static func aclLog(operation: ACLLOGOperation? = nil) -> RESPCommand {
        RESPCommand("ACL", "LOG", operation)
    }

    /// Saves the effective ACL rules in the configured ACL file.
    ///
    /// - Documentation: [ACL SAVE](https:/redis.io/docs/latest/commands/acl-save)
    /// - Version: 6.0.0
    /// - Complexity: O(N). Where N is the number of configured users.
    /// - Categories: @admin, @slow, @dangerous
    /// - Response: [Simple string](https:/redis.io/docs/reference/protocol-spec#simple-strings): `OK`.
    ///     The command may fail with an error for several reasons: if the file cannot be written or if the server is not configured to use an external ACL file.
    @inlinable
    public static func aclSave() -> RESPCommand {
        RESPCommand("ACL", "SAVE")
    }

    /// Creates and modifies an ACL user and its rules.
    ///
    /// - Documentation: [ACL SETUSER](https:/redis.io/docs/latest/commands/acl-setuser)
    /// - Version: 6.0.0
    /// - Complexity: O(N). Where N is the number of rules provided.
    /// - Categories: @admin, @slow, @dangerous
    /// - Response: [Simple string](https:/redis.io/docs/reference/protocol-spec#simple-strings): `OK`.
    ///     If the rules contain errors, the error is returned.
    @inlinable
    public static func aclSetuser(username: String, rule: String? = nil) -> RESPCommand {
        RESPCommand("ACL", "SETUSER", username, rule)
    }

    /// Creates and modifies an ACL user and its rules.
    ///
    /// - Documentation: [ACL SETUSER](https:/redis.io/docs/latest/commands/acl-setuser)
    /// - Version: 6.0.0
    /// - Complexity: O(N). Where N is the number of rules provided.
    /// - Categories: @admin, @slow, @dangerous
    /// - Response: [Simple string](https:/redis.io/docs/reference/protocol-spec#simple-strings): `OK`.
    ///     If the rules contain errors, the error is returned.
    @inlinable
    public static func aclSetuser(username: String, rules: [String]) -> RESPCommand {
        RESPCommand("ACL", "SETUSER", username, rules)
    }

    /// Lists all ACL users.
    ///
    /// - Documentation: [ACL USERS](https:/redis.io/docs/latest/commands/acl-users)
    /// - Version: 6.0.0
    /// - Complexity: O(N). Where N is the number of configured users.
    /// - Categories: @admin, @slow, @dangerous
    /// - Response: [Array](https:/redis.io/docs/reference/protocol-spec#arrays): list of existing ACL users.
    @inlinable
    public static func aclUsers() -> RESPCommand {
        RESPCommand("ACL", "USERS")
    }

    /// Returns the authenticated username of the current connection.
    ///
    /// - Documentation: [ACL WHOAMI](https:/redis.io/docs/latest/commands/acl-whoami)
    /// - Version: 6.0.0
    /// - Complexity: O(1)
    /// - Categories: @slow
    /// - Response: [Bulk string](https:/redis.io/docs/reference/protocol-spec#bulk-strings): the username of the current connection.
    @inlinable
    public static func aclWhoami() -> RESPCommand {
        RESPCommand("ACL", "WHOAMI")
    }

    /// Appends a string to the value of a key. Creates the key if it doesn't exist.
    ///
    /// - Documentation: [APPEND](https:/redis.io/docs/latest/commands/append)
    /// - Version: 2.0.0
    /// - Complexity: O(1). The amortized time complexity is O(1) assuming the appended value is small and the already present value is of any size, since the dynamic string library used by Redis will double the free space available on every reallocation.
    /// - Categories: @write, @string, @fast
    /// - Response: [Integer](https:/redis.io/docs/reference/protocol-spec#integers): the length of the string after the append operation.
    @inlinable
    public static func append(key: RedisKey, value: String) -> RESPCommand {
        RESPCommand("APPEND", key, value)
    }

    /// Signals that a cluster client is following an -ASK redirect.
    ///
    /// - Documentation: [ASKING](https:/redis.io/docs/latest/commands/asking)
    /// - Version: 3.0.0
    /// - Complexity: O(1)
    /// - Categories: @fast, @connection
    /// - Response: [Simple string](https:/redis.io/docs/reference/protocol-spec#simple-strings): `OK`.
    @inlinable
    public static func asking() -> RESPCommand {
        RESPCommand("ASKING")
    }

    /// Authenticates the connection.
    ///
    /// - Documentation: [AUTH](https:/redis.io/docs/latest/commands/auth)
    /// - Version: 1.0.0
    /// - Complexity: O(N) where N is the number of passwords defined for the user
    /// - Categories: @fast, @connection
    /// - Response: [Simple string](https:/redis.io/docs/reference/protocol-spec#simple-strings): `OK`, or an error if the password, or username/password pair, is invalid.
    @inlinable
    public static func auth(username: String? = nil, password: String) -> RESPCommand {
        RESPCommand("AUTH", username, password)
    }

    /// Asynchronously rewrites the append-only file to disk.
    ///
    /// - Documentation: [BGREWRITEAOF](https:/redis.io/docs/latest/commands/bgrewriteaof)
    /// - Version: 1.0.0
    /// - Complexity: O(1)
    /// - Categories: @admin, @slow, @dangerous
    /// - Response: [Bulk string](https:/redis.io/docs/reference/protocol-spec#bulk-strings): a simple string reply indicating that the rewriting started or is about to start ASAP when the call is executed with success.
    ///     
    ///     The command may reply with an error in certain cases, as documented above.
    @inlinable
    public static func bgrewriteaof() -> RESPCommand {
        RESPCommand("BGREWRITEAOF")
    }

    /// Asynchronously saves the database(s) to disk.
    ///
    /// - Documentation: [BGSAVE](https:/redis.io/docs/latest/commands/bgsave)
    /// - Version: 1.0.0
    /// - Complexity: O(1)
    /// - Categories: @admin, @slow, @dangerous
    /// - Response: One of the following:
    ///     * [Simple string](https:/redis.io/docs/reference/protocol-spec#simple-strings): `Background saving started`.
    ///     * [Simple string](https:/redis.io/docs/reference/protocol-spec#simple-strings): `Background saving scheduled`.
    @inlinable
    public static func bgsave(schedule: Bool = false) -> RESPCommand {
        RESPCommand("BGSAVE", RedisPureToken("SCHEDULE", schedule))
    }

    public enum BITCOUNTRangeUnit: RESPRenderable {
        case byte
        case bit

        @inlinable
        public func writeToRESPBuffer(_ buffer: inout ByteBuffer) -> Int {
            switch self {
            case .byte: "BYTE".writeToRESPBuffer(&buffer)
            case .bit: "BIT".writeToRESPBuffer(&buffer)
            }
        }
    }
    public struct BITCOUNTRange: RESPRenderable {
        @usableFromInline let start: Int
        @usableFromInline let end: Int
        @usableFromInline let unit: BITCOUNTRangeUnit?

        @inlinable
        public func writeToRESPBuffer(_ buffer: inout ByteBuffer) -> Int {
            var count = 0
            count += self.start.writeToRESPBuffer(&buffer)
            count += self.end.writeToRESPBuffer(&buffer)
            count += self.unit.writeToRESPBuffer(&buffer)
            return count
        }
    }
    /// Counts the number of set bits (population counting) in a string.
    ///
    /// - Documentation: [BITCOUNT](https:/redis.io/docs/latest/commands/bitcount)
    /// - Version: 2.6.0
    /// - Complexity: O(N)
    /// - Categories: @read, @bitmap, @slow
    /// - Response: [Integer](https:/redis.io/docs/reference/protocol-spec#integers): the number of bits set to 1.
    @inlinable
    public static func bitcount(key: RedisKey, range: BITCOUNTRange? = nil) -> RESPCommand {
        RESPCommand("BITCOUNT", key, range)
    }

    public struct BITFIELDOperationGetBlock: RESPRenderable {
        @usableFromInline let encoding: String
        @usableFromInline let offset: Int

        @inlinable
        public func writeToRESPBuffer(_ buffer: inout ByteBuffer) -> Int {
            var count = 0
            count += self.encoding.writeToRESPBuffer(&buffer)
            count += self.offset.writeToRESPBuffer(&buffer)
            return count
        }
    }
    public enum BITFIELDOperationWriteOverflowBlock: RESPRenderable {
        case wrap
        case sat
        case fail

        @inlinable
        public func writeToRESPBuffer(_ buffer: inout ByteBuffer) -> Int {
            switch self {
            case .wrap: "WRAP".writeToRESPBuffer(&buffer)
            case .sat: "SAT".writeToRESPBuffer(&buffer)
            case .fail: "FAIL".writeToRESPBuffer(&buffer)
            }
        }
    }
    public struct BITFIELDOperationWriteWriteOperationSetBlock: RESPRenderable {
        @usableFromInline let encoding: String
        @usableFromInline let offset: Int
        @usableFromInline let value: Int

        @inlinable
        public func writeToRESPBuffer(_ buffer: inout ByteBuffer) -> Int {
            var count = 0
            count += self.encoding.writeToRESPBuffer(&buffer)
            count += self.offset.writeToRESPBuffer(&buffer)
            count += self.value.writeToRESPBuffer(&buffer)
            return count
        }
    }
    public struct BITFIELDOperationWriteWriteOperationIncrbyBlock: RESPRenderable {
        @usableFromInline let encoding: String
        @usableFromInline let offset: Int
        @usableFromInline let increment: Int

        @inlinable
        public func writeToRESPBuffer(_ buffer: inout ByteBuffer) -> Int {
            var count = 0
            count += self.encoding.writeToRESPBuffer(&buffer)
            count += self.offset.writeToRESPBuffer(&buffer)
            count += self.increment.writeToRESPBuffer(&buffer)
            return count
        }
    }
    public enum BITFIELDOperationWriteWriteOperation: RESPRenderable {
        case setBlock(BITFIELDOperationWriteWriteOperationSetBlock)
        case incrbyBlock(BITFIELDOperationWriteWriteOperationIncrbyBlock)

        @inlinable
        public func writeToRESPBuffer(_ buffer: inout ByteBuffer) -> Int {
            switch self {
            case .setBlock(let setBlock): RESPWithToken("SET", setBlock).writeToRESPBuffer(&buffer)
            case .incrbyBlock(let incrbyBlock): RESPWithToken("INCRBY", incrbyBlock).writeToRESPBuffer(&buffer)
            }
        }
    }
    public struct BITFIELDOperationWrite: RESPRenderable {
        @usableFromInline let overflowBlock: BITFIELDOperationWriteOverflowBlock?
        @usableFromInline let writeOperation: BITFIELDOperationWriteWriteOperation

        @inlinable
        public func writeToRESPBuffer(_ buffer: inout ByteBuffer) -> Int {
            var count = 0
            count += RESPWithToken("OVERFLOW", overflowBlock).writeToRESPBuffer(&buffer)
            count += self.writeOperation.writeToRESPBuffer(&buffer)
            return count
        }
    }
    public enum BITFIELDOperation: RESPRenderable {
        case getBlock(BITFIELDOperationGetBlock)
        case write(BITFIELDOperationWrite)

        @inlinable
        public func writeToRESPBuffer(_ buffer: inout ByteBuffer) -> Int {
            switch self {
            case .getBlock(let getBlock): RESPWithToken("GET", getBlock).writeToRESPBuffer(&buffer)
            case .write(let write): write.writeToRESPBuffer(&buffer)
            }
        }
    }
    /// Performs arbitrary bitfield integer operations on strings.
    ///
    /// - Documentation: [BITFIELD](https:/redis.io/docs/latest/commands/bitfield)
    /// - Version: 3.2.0
    /// - Complexity: O(1) for each subcommand specified
    /// - Categories: @write, @bitmap, @slow
    /// - Response: One of the following:
    ///     * [Array](https:/redis.io/docs/reference/protocol-spec#arrays): each entry being the corresponding result of the sub-command given at the same position.
    ///     * [Null](https:/redis.io/docs/reference/protocol-spec#nulls): if OVERFLOW FAIL was given and overflows or underflows are detected.
    @inlinable
    public static func bitfield(key: RedisKey, operation: BITFIELDOperation? = nil) -> RESPCommand {
        RESPCommand("BITFIELD", key, operation)
    }

    /// Performs arbitrary bitfield integer operations on strings.
    ///
    /// - Documentation: [BITFIELD](https:/redis.io/docs/latest/commands/bitfield)
    /// - Version: 3.2.0
    /// - Complexity: O(1) for each subcommand specified
    /// - Categories: @write, @bitmap, @slow
    /// - Response: One of the following:
    ///     * [Array](https:/redis.io/docs/reference/protocol-spec#arrays): each entry being the corresponding result of the sub-command given at the same position.
    ///     * [Null](https:/redis.io/docs/reference/protocol-spec#nulls): if OVERFLOW FAIL was given and overflows or underflows are detected.
    @inlinable
    public static func bitfield(key: RedisKey, operations: [BITFIELDOperation]) -> RESPCommand {
        RESPCommand("BITFIELD", key, operations)
    }

    public struct BITFIELDROGetBlock: RESPRenderable {
        @usableFromInline let encoding: String
        @usableFromInline let offset: Int

        @inlinable
        public func writeToRESPBuffer(_ buffer: inout ByteBuffer) -> Int {
            var count = 0
            count += self.encoding.writeToRESPBuffer(&buffer)
            count += self.offset.writeToRESPBuffer(&buffer)
            return count
        }
    }
    /// Performs arbitrary read-only bitfield integer operations on strings.
    ///
    /// - Documentation: [BITFIELD_RO](https:/redis.io/docs/latest/commands/bitfield_ro)
    /// - Version: 6.0.0
    /// - Complexity: O(1) for each subcommand specified
    /// - Categories: @read, @bitmap, @fast
    /// - Response: [Array](https:/redis.io/docs/reference/protocol-spec#arrays): each entry being the corresponding result of the sub-command given at the same position.
    @inlinable
    public static func bitfieldRo(key: RedisKey, getBlock: BITFIELDROGetBlock? = nil) -> RESPCommand {
        RESPCommand("BITFIELD_RO", key, RESPWithToken("GET", getBlock))
    }

    /// Performs arbitrary read-only bitfield integer operations on strings.
    ///
    /// - Documentation: [BITFIELD_RO](https:/redis.io/docs/latest/commands/bitfield_ro)
    /// - Version: 6.0.0
    /// - Complexity: O(1) for each subcommand specified
    /// - Categories: @read, @bitmap, @fast
    /// - Response: [Array](https:/redis.io/docs/reference/protocol-spec#arrays): each entry being the corresponding result of the sub-command given at the same position.
    @inlinable
    public static func bitfieldRo(key: RedisKey, getBlocks: [BITFIELDROGetBlock]) -> RESPCommand {
        RESPCommand("BITFIELD_RO", key, RESPWithToken("GET", getBlocks))
    }

    public enum BITOPOperation: RESPRenderable {
        case and
        case or
        case xor
        case not

        @inlinable
        public func writeToRESPBuffer(_ buffer: inout ByteBuffer) -> Int {
            switch self {
            case .and: "AND".writeToRESPBuffer(&buffer)
            case .or: "OR".writeToRESPBuffer(&buffer)
            case .xor: "XOR".writeToRESPBuffer(&buffer)
            case .not: "NOT".writeToRESPBuffer(&buffer)
            }
        }
    }
    /// Performs bitwise operations on multiple strings, and stores the result.
    ///
    /// - Documentation: [BITOP](https:/redis.io/docs/latest/commands/bitop)
    /// - Version: 2.6.0
    /// - Complexity: O(N)
    /// - Categories: @write, @bitmap, @slow
    /// - Response: [Integer](https:/redis.io/docs/reference/protocol-spec#integers): the size of the string stored in the destination key is equal to the size of the longest input string.
    @inlinable
    public static func bitop(operation: BITOPOperation, destkey: RedisKey, key: RedisKey) -> RESPCommand {
        RESPCommand("BITOP", operation, destkey, key)
    }

    /// Performs bitwise operations on multiple strings, and stores the result.
    ///
    /// - Documentation: [BITOP](https:/redis.io/docs/latest/commands/bitop)
    /// - Version: 2.6.0
    /// - Complexity: O(N)
    /// - Categories: @write, @bitmap, @slow
    /// - Response: [Integer](https:/redis.io/docs/reference/protocol-spec#integers): the size of the string stored in the destination key is equal to the size of the longest input string.
    @inlinable
    public static func bitop(operation: BITOPOperation, destkey: RedisKey, keys: [RedisKey]) -> RESPCommand {
        RESPCommand("BITOP", operation, destkey, keys)
    }

    public enum BITPOSRangeEndUnitBlockUnit: RESPRenderable {
        case byte
        case bit

        @inlinable
        public func writeToRESPBuffer(_ buffer: inout ByteBuffer) -> Int {
            switch self {
            case .byte: "BYTE".writeToRESPBuffer(&buffer)
            case .bit: "BIT".writeToRESPBuffer(&buffer)
            }
        }
    }
    public struct BITPOSRangeEndUnitBlock: RESPRenderable {
        @usableFromInline let end: Int
        @usableFromInline let unit: BITPOSRangeEndUnitBlockUnit?

        @inlinable
        public func writeToRESPBuffer(_ buffer: inout ByteBuffer) -> Int {
            var count = 0
            count += self.end.writeToRESPBuffer(&buffer)
            count += self.unit.writeToRESPBuffer(&buffer)
            return count
        }
    }
    public struct BITPOSRange: RESPRenderable {
        @usableFromInline let start: Int
        @usableFromInline let endUnitBlock: BITPOSRangeEndUnitBlock?

        @inlinable
        public func writeToRESPBuffer(_ buffer: inout ByteBuffer) -> Int {
            var count = 0
            count += self.start.writeToRESPBuffer(&buffer)
            count += self.endUnitBlock.writeToRESPBuffer(&buffer)
            return count
        }
    }
    /// Finds the first set (1) or clear (0) bit in a string.
    ///
    /// - Documentation: [BITPOS](https:/redis.io/docs/latest/commands/bitpos)
    /// - Version: 2.8.7
    /// - Complexity: O(N)
    /// - Categories: @read, @bitmap, @slow
    /// - Response: One of the following:
    ///     * [Integer](https:/redis.io/docs/reference/protocol-spec#integers): the position of the first bit set to 1 or 0 according to the request
    ///     * [Integer](https:/redis.io/docs/reference/protocol-spec#integers): `-1`. In case the `bit` argument is 1 and the string is empty or composed of just zero bytes
    ///     
    ///     If we look for set bits (the bit argument is 1) and the string is empty or composed of just zero bytes, -1 is returned.
    ///     
    ///     If we look for clear bits (the bit argument is 0) and the string only contains bits set to 1, the function returns the first bit not part of the string on the right. So if the string is three bytes set to the value `0xff` the command `BITPOS key 0` will return 24, since up to bit 23 all the bits are 1.
    ///     
    ///     The function considers the right of the string as padded with zeros if you look for clear bits and specify no range or the _start_ argument **only**.
    ///     
    ///     However, this behavior changes if you are looking for clear bits and specify a range with both _start_ and _end_.
    ///     If a clear bit isn't found in the specified range, the function returns -1 as the user specified a clear range and there are no 0 bits in that range.
    @inlinable
    public static func bitpos(key: RedisKey, bit: Int, range: BITPOSRange? = nil) -> RESPCommand {
        RESPCommand("BITPOS", key, bit, range)
    }

    public enum BLMOVEWherefrom: RESPRenderable {
        case left
        case right

        @inlinable
        public func writeToRESPBuffer(_ buffer: inout ByteBuffer) -> Int {
            switch self {
            case .left: "LEFT".writeToRESPBuffer(&buffer)
            case .right: "RIGHT".writeToRESPBuffer(&buffer)
            }
        }
    }
    public enum BLMOVEWhereto: RESPRenderable {
        case left
        case right

        @inlinable
        public func writeToRESPBuffer(_ buffer: inout ByteBuffer) -> Int {
            switch self {
            case .left: "LEFT".writeToRESPBuffer(&buffer)
            case .right: "RIGHT".writeToRESPBuffer(&buffer)
            }
        }
    }
    /// Pops an element from a list, pushes it to another list and returns it. Blocks until an element is available otherwise. Deletes the list if the last element was moved.
    ///
    /// - Documentation: [BLMOVE](https:/redis.io/docs/latest/commands/blmove)
    /// - Version: 6.2.0
    /// - Complexity: O(1)
    /// - Categories: @write, @list, @slow, @blocking
    /// - Response: One of the following:
    ///     * [Bulk string](https:/redis.io/docs/reference/protocol-spec#bulk-strings): the element being popped from the _source_ and pushed to the _destination_.
    ///     * [Null](https:/redis.io/docs/reference/protocol-spec#nulls): the operation timed-out
    @inlinable
    public static func blmove(source: RedisKey, destination: RedisKey, wherefrom: BLMOVEWherefrom, whereto: BLMOVEWhereto, timeout: Double) -> RESPCommand {
        RESPCommand("BLMOVE", source, destination, wherefrom, whereto, timeout)
    }

    public enum BLMPOPWhere: RESPRenderable {
        case left
        case right

        @inlinable
        public func writeToRESPBuffer(_ buffer: inout ByteBuffer) -> Int {
            switch self {
            case .left: "LEFT".writeToRESPBuffer(&buffer)
            case .right: "RIGHT".writeToRESPBuffer(&buffer)
            }
        }
    }
    /// Pops the first element from one of multiple lists. Blocks until an element is available otherwise. Deletes the list if the last element was popped.
    ///
    /// - Documentation: [BLMPOP](https:/redis.io/docs/latest/commands/blmpop)
    /// - Version: 7.0.0
    /// - Complexity: O(N+M) where N is the number of provided keys and M is the number of elements returned.
    /// - Categories: @write, @list, @slow, @blocking
    /// - Response: One of the following:
    ///     * [Null](https:/redis.io/docs/reference/protocol-spec#nulls): when no element could be popped and the _timeout_ is reached.
    ///     * [Array](https:/redis.io/docs/reference/protocol-spec#arrays): a two-element array with the first element being the name of the key from which elements were popped, and the second element being an array of the popped elements.
    @inlinable
    public static func blmpop(timeout: Double, key: RedisKey, `where`: BLMPOPWhere, count: Int? = nil) -> RESPCommand {
        RESPCommand("BLMPOP", timeout, 1, key, `where`, RESPWithToken("COUNT", count))
    }

    /// Pops the first element from one of multiple lists. Blocks until an element is available otherwise. Deletes the list if the last element was popped.
    ///
    /// - Documentation: [BLMPOP](https:/redis.io/docs/latest/commands/blmpop)
    /// - Version: 7.0.0
    /// - Complexity: O(N+M) where N is the number of provided keys and M is the number of elements returned.
    /// - Categories: @write, @list, @slow, @blocking
    /// - Response: One of the following:
    ///     * [Null](https:/redis.io/docs/reference/protocol-spec#nulls): when no element could be popped and the _timeout_ is reached.
    ///     * [Array](https:/redis.io/docs/reference/protocol-spec#arrays): a two-element array with the first element being the name of the key from which elements were popped, and the second element being an array of the popped elements.
    @inlinable
    public static func blmpop(timeout: Double, keys: [RedisKey], `where`: BLMPOPWhere, count: Int? = nil) -> RESPCommand {
        RESPCommand("BLMPOP", timeout, RESPArrayWithCount(keys), `where`, RESPWithToken("COUNT", count))
    }

    /// Removes and returns the first element in a list. Blocks until an element is available otherwise. Deletes the list if the last element was popped.
    ///
    /// - Documentation: [BLPOP](https:/redis.io/docs/latest/commands/blpop)
    /// - Version: 2.0.0
    /// - Complexity: O(N) where N is the number of provided keys.
    /// - Categories: @write, @list, @slow, @blocking
    /// - Response: One of the following:
    ///     * [Null](https:/redis.io/docs/reference/protocol-spec#nulls): no element could be popped and the timeout expired
    ///     * [Array](https:/redis.io/docs/reference/protocol-spec#arrays): the key from which the element was popped and the value of the popped element.
    @inlinable
    public static func blpop(key: RedisKey, timeout: Double) -> RESPCommand {
        RESPCommand("BLPOP", key, timeout)
    }

    /// Removes and returns the first element in a list. Blocks until an element is available otherwise. Deletes the list if the last element was popped.
    ///
    /// - Documentation: [BLPOP](https:/redis.io/docs/latest/commands/blpop)
    /// - Version: 2.0.0
    /// - Complexity: O(N) where N is the number of provided keys.
    /// - Categories: @write, @list, @slow, @blocking
    /// - Response: One of the following:
    ///     * [Null](https:/redis.io/docs/reference/protocol-spec#nulls): no element could be popped and the timeout expired
    ///     * [Array](https:/redis.io/docs/reference/protocol-spec#arrays): the key from which the element was popped and the value of the popped element.
    @inlinable
    public static func blpop(keys: [RedisKey], timeout: Double) -> RESPCommand {
        RESPCommand("BLPOP", keys, timeout)
    }

    /// Removes and returns the last element in a list. Blocks until an element is available otherwise. Deletes the list if the last element was popped.
    ///
    /// - Documentation: [BRPOP](https:/redis.io/docs/latest/commands/brpop)
    /// - Version: 2.0.0
    /// - Complexity: O(N) where N is the number of provided keys.
    /// - Categories: @write, @list, @slow, @blocking
    /// - Response: One of the following:
    ///     * [Null](https:/redis.io/docs/reference/protocol-spec#nulls): no element could be popped and the timeout expired.
    ///     * [Array](https:/redis.io/docs/reference/protocol-spec#arrays): the key from which the element was popped and the value of the popped element
    @inlinable
    public static func brpop(key: RedisKey, timeout: Double) -> RESPCommand {
        RESPCommand("BRPOP", key, timeout)
    }

    /// Removes and returns the last element in a list. Blocks until an element is available otherwise. Deletes the list if the last element was popped.
    ///
    /// - Documentation: [BRPOP](https:/redis.io/docs/latest/commands/brpop)
    /// - Version: 2.0.0
    /// - Complexity: O(N) where N is the number of provided keys.
    /// - Categories: @write, @list, @slow, @blocking
    /// - Response: One of the following:
    ///     * [Null](https:/redis.io/docs/reference/protocol-spec#nulls): no element could be popped and the timeout expired.
    ///     * [Array](https:/redis.io/docs/reference/protocol-spec#arrays): the key from which the element was popped and the value of the popped element
    @inlinable
    public static func brpop(keys: [RedisKey], timeout: Double) -> RESPCommand {
        RESPCommand("BRPOP", keys, timeout)
    }

    /// Pops an element from a list, pushes it to another list and returns it. Block until an element is available otherwise. Deletes the list if the last element was popped.
    ///
    /// - Documentation: [BRPOPLPUSH](https:/redis.io/docs/latest/commands/brpoplpush)
    /// - Version: 2.2.0
    /// - Complexity: O(1)
    /// - Categories: @write, @list, @slow, @blocking
    /// - Response: One of the following:
    ///     * [Bulk string](https:/redis.io/docs/reference/protocol-spec#bulk-strings): the element being popped from _source_ and pushed to _destination_.
    ///     * [Null](https:/redis.io/docs/reference/protocol-spec#nulls): the timeout is reached.
    @inlinable
    public static func brpoplpush(source: RedisKey, destination: RedisKey, timeout: Double) -> RESPCommand {
        RESPCommand("BRPOPLPUSH", source, destination, timeout)
    }

    public enum BZMPOPWhere: RESPRenderable {
        case min
        case max

        @inlinable
        public func writeToRESPBuffer(_ buffer: inout ByteBuffer) -> Int {
            switch self {
            case .min: "MIN".writeToRESPBuffer(&buffer)
            case .max: "MAX".writeToRESPBuffer(&buffer)
            }
        }
    }
    /// Removes and returns a member by score from one or more sorted sets. Blocks until a member is available otherwise. Deletes the sorted set if the last element was popped.
    ///
    /// - Documentation: [BZMPOP](https:/redis.io/docs/latest/commands/bzmpop)
    /// - Version: 7.0.0
    /// - Complexity: O(K) + O(M*log(N)) where K is the number of provided keys, N being the number of elements in the sorted set, and M being the number of elements popped.
    /// - Categories: @write, @sortedset, @slow, @blocking
    /// - Response: One of the following:
    ///     * [Null](https:/redis.io/docs/reference/protocol-spec#nulls): when no element could be popped.
    ///     * [Array](https:/redis.io/docs/reference/protocol-spec#arrays): a two-element array with the first element being the name of the key from which elements were popped, and the second element is an array of the popped elements. Every entry in the elements array is also an array that contains the member and its score.
    @inlinable
    public static func bzmpop(timeout: Double, key: RedisKey, `where`: BZMPOPWhere, count: Int? = nil) -> RESPCommand {
        RESPCommand("BZMPOP", timeout, 1, key, `where`, RESPWithToken("COUNT", count))
    }

    /// Removes and returns a member by score from one or more sorted sets. Blocks until a member is available otherwise. Deletes the sorted set if the last element was popped.
    ///
    /// - Documentation: [BZMPOP](https:/redis.io/docs/latest/commands/bzmpop)
    /// - Version: 7.0.0
    /// - Complexity: O(K) + O(M*log(N)) where K is the number of provided keys, N being the number of elements in the sorted set, and M being the number of elements popped.
    /// - Categories: @write, @sortedset, @slow, @blocking
    /// - Response: One of the following:
    ///     * [Null](https:/redis.io/docs/reference/protocol-spec#nulls): when no element could be popped.
    ///     * [Array](https:/redis.io/docs/reference/protocol-spec#arrays): a two-element array with the first element being the name of the key from which elements were popped, and the second element is an array of the popped elements. Every entry in the elements array is also an array that contains the member and its score.
    @inlinable
    public static func bzmpop(timeout: Double, keys: [RedisKey], `where`: BZMPOPWhere, count: Int? = nil) -> RESPCommand {
        RESPCommand("BZMPOP", timeout, RESPArrayWithCount(keys), `where`, RESPWithToken("COUNT", count))
    }

    /// Removes and returns the member with the highest score from one or more sorted sets. Blocks until a member available otherwise.  Deletes the sorted set if the last element was popped.
    ///
    /// - Documentation: [BZPOPMAX](https:/redis.io/docs/latest/commands/bzpopmax)
    /// - Version: 5.0.0
    /// - Complexity: O(log(N)) with N being the number of elements in the sorted set.
    /// - Categories: @write, @sortedset, @fast, @blocking
    /// - Response: One of the following:
    ///     * [Null](https:/redis.io/docs/reference/protocol-spec#nulls): when no element could be popped and the _timeout_ expired.
    ///     * [Array](https:/redis.io/docs/reference/protocol-spec#arrays): the keyname, popped member, and its score.
    @inlinable
    public static func bzpopmax(key: RedisKey, timeout: Double) -> RESPCommand {
        RESPCommand("BZPOPMAX", key, timeout)
    }

    /// Removes and returns the member with the highest score from one or more sorted sets. Blocks until a member available otherwise.  Deletes the sorted set if the last element was popped.
    ///
    /// - Documentation: [BZPOPMAX](https:/redis.io/docs/latest/commands/bzpopmax)
    /// - Version: 5.0.0
    /// - Complexity: O(log(N)) with N being the number of elements in the sorted set.
    /// - Categories: @write, @sortedset, @fast, @blocking
    /// - Response: One of the following:
    ///     * [Null](https:/redis.io/docs/reference/protocol-spec#nulls): when no element could be popped and the _timeout_ expired.
    ///     * [Array](https:/redis.io/docs/reference/protocol-spec#arrays): the keyname, popped member, and its score.
    @inlinable
    public static func bzpopmax(keys: [RedisKey], timeout: Double) -> RESPCommand {
        RESPCommand("BZPOPMAX", keys, timeout)
    }

    /// Removes and returns the member with the lowest score from one or more sorted sets. Blocks until a member is available otherwise. Deletes the sorted set if the last element was popped.
    ///
    /// - Documentation: [BZPOPMIN](https:/redis.io/docs/latest/commands/bzpopmin)
    /// - Version: 5.0.0
    /// - Complexity: O(log(N)) with N being the number of elements in the sorted set.
    /// - Categories: @write, @sortedset, @fast, @blocking
    /// - Response: One of the following:
    ///     * [Null](https:/redis.io/docs/reference/protocol-spec#nulls): when no element could be popped and the _timeout_ expired.
    ///     * [Array](https:/redis.io/docs/reference/protocol-spec#arrays): the keyname, popped member, and its score.
    @inlinable
    public static func bzpopmin(key: RedisKey, timeout: Double) -> RESPCommand {
        RESPCommand("BZPOPMIN", key, timeout)
    }

    /// Removes and returns the member with the lowest score from one or more sorted sets. Blocks until a member is available otherwise. Deletes the sorted set if the last element was popped.
    ///
    /// - Documentation: [BZPOPMIN](https:/redis.io/docs/latest/commands/bzpopmin)
    /// - Version: 5.0.0
    /// - Complexity: O(log(N)) with N being the number of elements in the sorted set.
    /// - Categories: @write, @sortedset, @fast, @blocking
    /// - Response: One of the following:
    ///     * [Null](https:/redis.io/docs/reference/protocol-spec#nulls): when no element could be popped and the _timeout_ expired.
    ///     * [Array](https:/redis.io/docs/reference/protocol-spec#arrays): the keyname, popped member, and its score.
    @inlinable
    public static func bzpopmin(keys: [RedisKey], timeout: Double) -> RESPCommand {
        RESPCommand("BZPOPMIN", keys, timeout)
    }

    public enum CLIENTCACHINGMode: RESPRenderable {
        case yes
        case no

        @inlinable
        public func writeToRESPBuffer(_ buffer: inout ByteBuffer) -> Int {
            switch self {
            case .yes: "YES".writeToRESPBuffer(&buffer)
            case .no: "NO".writeToRESPBuffer(&buffer)
            }
        }
    }
    /// Instructs the server whether to track the keys in the next request.
    ///
    /// - Documentation: [CLIENT CACHING](https:/redis.io/docs/latest/commands/client-caching)
    /// - Version: 6.0.0
    /// - Complexity: O(1)
    /// - Categories: @slow, @connection
    /// - Response: [Simple string](https:/redis.io/docs/reference/protocol-spec#simple-strings): `OK` or an error if the argument is not "yes" or "no".
    @inlinable
    public static func clientCaching(mode: CLIENTCACHINGMode) -> RESPCommand {
        RESPCommand("CLIENT", "CACHING", mode)
    }

    /// Returns the name of the connection.
    ///
    /// - Documentation: [CLIENT GETNAME](https:/redis.io/docs/latest/commands/client-getname)
    /// - Version: 2.6.9
    /// - Complexity: O(1)
    /// - Categories: @slow, @connection
    /// - Response: One of the following:
    ///     * [Bulk string](https:/redis.io/docs/reference/protocol-spec#bulk-strings): the connection name of the current connection.
    ///     * [Null](https:/redis.io/docs/reference/protocol-spec#nulls): the connection name was not set.
    @inlinable
    public static func clientGetname() -> RESPCommand {
        RESPCommand("CLIENT", "GETNAME")
    }

    /// Returns the client ID to which the connection's tracking notifications are redirected.
    ///
    /// - Documentation: [CLIENT GETREDIR](https:/redis.io/docs/latest/commands/client-getredir)
    /// - Version: 6.0.0
    /// - Complexity: O(1)
    /// - Categories: @slow, @connection
    /// - Response: One of the following:
    ///     * [Integer](https:/redis.io/docs/reference/protocol-spec#integers): `0` when not redirecting notifications to any client.
    ///     * [Integer](https:/redis.io/docs/reference/protocol-spec#integers): `-1` if client tracking is not enabled.
    ///     * [Integer](https:/redis.io/docs/reference/protocol-spec#integers): the ID of the client to which notification are being redirected.
    @inlinable
    public static func clientGetredir() -> RESPCommand {
        RESPCommand("CLIENT", "GETREDIR")
    }

    /// Returns helpful text about the different subcommands.
    ///
    /// - Documentation: [CLIENT HELP](https:/redis.io/docs/latest/commands/client-help)
    /// - Version: 5.0.0
    /// - Complexity: O(1)
    /// - Categories: @slow, @connection
    /// - Response: [Array](https:/redis.io/docs/reference/protocol-spec#arrays): a list of subcommands and their descriptions.
    @inlinable
    public static func clientHelp() -> RESPCommand {
        RESPCommand("CLIENT", "HELP")
    }

    /// Returns the unique client ID of the connection.
    ///
    /// - Documentation: [CLIENT ID](https:/redis.io/docs/latest/commands/client-id)
    /// - Version: 5.0.0
    /// - Complexity: O(1)
    /// - Categories: @slow, @connection
    /// - Response: [Integer](https:/redis.io/docs/reference/protocol-spec#integers): the ID of the client.
    @inlinable
    public static func clientId() -> RESPCommand {
        RESPCommand("CLIENT", "ID")
    }

    /// Returns information about the connection.
    ///
    /// - Documentation: [CLIENT INFO](https:/redis.io/docs/latest/commands/client-info)
    /// - Version: 6.2.0
    /// - Complexity: O(1)
    /// - Categories: @slow, @connection
    /// - Response: [Bulk string](https:/redis.io/docs/reference/protocol-spec#bulk-strings): a unique string for the current client, as described at the `CLIENT LIST` page.
    @inlinable
    public static func clientInfo() -> RESPCommand {
        RESPCommand("CLIENT", "INFO")
    }

    public enum CLIENTKILLFilterNewFormatClientType: RESPRenderable {
        case normal
        case master
        case slave
        case replica
        case pubsub

        @inlinable
        public func writeToRESPBuffer(_ buffer: inout ByteBuffer) -> Int {
            switch self {
            case .normal: "NORMAL".writeToRESPBuffer(&buffer)
            case .master: "MASTER".writeToRESPBuffer(&buffer)
            case .slave: "SLAVE".writeToRESPBuffer(&buffer)
            case .replica: "REPLICA".writeToRESPBuffer(&buffer)
            case .pubsub: "PUBSUB".writeToRESPBuffer(&buffer)
            }
        }
    }
    public enum CLIENTKILLFilterNewFormatSkipme: RESPRenderable {
        case yes
        case no

        @inlinable
        public func writeToRESPBuffer(_ buffer: inout ByteBuffer) -> Int {
            switch self {
            case .yes: "YES".writeToRESPBuffer(&buffer)
            case .no: "NO".writeToRESPBuffer(&buffer)
            }
        }
    }
    public enum CLIENTKILLFilterNewFormat: RESPRenderable {
        case clientId(Int?)
        case clientType(CLIENTKILLFilterNewFormatClientType?)
        case username(String?)
        case addr(String?)
        case laddr(String?)
        case skipme(CLIENTKILLFilterNewFormatSkipme?)

        @inlinable
        public func writeToRESPBuffer(_ buffer: inout ByteBuffer) -> Int {
            switch self {
            case .clientId(let clientId): RESPWithToken("ID", clientId).writeToRESPBuffer(&buffer)
            case .clientType(let clientType): RESPWithToken("TYPE", clientType).writeToRESPBuffer(&buffer)
            case .username(let username): RESPWithToken("USER", username).writeToRESPBuffer(&buffer)
            case .addr(let addr): RESPWithToken("ADDR", addr).writeToRESPBuffer(&buffer)
            case .laddr(let laddr): RESPWithToken("LADDR", laddr).writeToRESPBuffer(&buffer)
            case .skipme(let skipme): RESPWithToken("SKIPME", skipme).writeToRESPBuffer(&buffer)
            }
        }
    }
    public enum CLIENTKILLFilter: RESPRenderable {
        case oldFormat(String)
        case newFormat([CLIENTKILLFilterNewFormat])

        @inlinable
        public func writeToRESPBuffer(_ buffer: inout ByteBuffer) -> Int {
            switch self {
            case .oldFormat(let oldFormat): oldFormat.writeToRESPBuffer(&buffer)
            case .newFormat(let newFormat): newFormat.writeToRESPBuffer(&buffer)
            }
        }
    }
    /// Terminates open connections.
    ///
    /// - Documentation: [CLIENT KILL](https:/redis.io/docs/latest/commands/client-kill)
    /// - Version: 2.4.0
    /// - Complexity: O(N) where N is the number of client connections
    /// - Categories: @admin, @slow, @dangerous, @connection
    /// - Response: One of the following:
    ///     * [Simple string](https:/redis.io/docs/reference/protocol-spec#simple-strings): `OK` when called in 3 argument format and the connection has been closed.
    ///     * [Integer](https:/redis.io/docs/reference/protocol-spec#integers): when called in filter/value format, the number of clients killed.
    @inlinable
    public static func clientKill(filter: CLIENTKILLFilter) -> RESPCommand {
        RESPCommand("CLIENT", "KILL", filter)
    }

    public enum CLIENTLISTClientType: RESPRenderable {
        case normal
        case master
        case replica
        case pubsub

        @inlinable
        public func writeToRESPBuffer(_ buffer: inout ByteBuffer) -> Int {
            switch self {
            case .normal: "NORMAL".writeToRESPBuffer(&buffer)
            case .master: "MASTER".writeToRESPBuffer(&buffer)
            case .replica: "REPLICA".writeToRESPBuffer(&buffer)
            case .pubsub: "PUBSUB".writeToRESPBuffer(&buffer)
            }
        }
    }
    /// Lists open connections.
    ///
    /// - Documentation: [CLIENT LIST](https:/redis.io/docs/latest/commands/client-list)
    /// - Version: 2.4.0
    /// - Complexity: O(N) where N is the number of client connections
    /// - Categories: @admin, @slow, @dangerous, @connection
    /// - Response: [Bulk string](https:/redis.io/docs/reference/protocol-spec#bulk-strings): information and statistics about client connections.
    @inlinable
    public static func clientList(clientType: CLIENTLISTClientType? = nil, clientId: Int? = nil) -> RESPCommand {
        RESPCommand("CLIENT", "LIST", RESPWithToken("TYPE", clientType), RESPWithToken("ID", clientId))
    }

    /// Lists open connections.
    ///
    /// - Documentation: [CLIENT LIST](https:/redis.io/docs/latest/commands/client-list)
    /// - Version: 2.4.0
    /// - Complexity: O(N) where N is the number of client connections
    /// - Categories: @admin, @slow, @dangerous, @connection
    /// - Response: [Bulk string](https:/redis.io/docs/reference/protocol-spec#bulk-strings): information and statistics about client connections.
    @inlinable
    public static func clientList(clientType: CLIENTLISTClientType? = nil, clientIds: [Int]) -> RESPCommand {
        RESPCommand("CLIENT", "LIST", RESPWithToken("TYPE", clientType), RESPWithToken("ID", clientIds))
    }

    public enum CLIENTNOEVICTEnabled: RESPRenderable {
        case on
        case off

        @inlinable
        public func writeToRESPBuffer(_ buffer: inout ByteBuffer) -> Int {
            switch self {
            case .on: "ON".writeToRESPBuffer(&buffer)
            case .off: "OFF".writeToRESPBuffer(&buffer)
            }
        }
    }
    /// Sets the client eviction mode of the connection.
    ///
    /// - Documentation: [CLIENT NO-EVICT](https:/redis.io/docs/latest/commands/client-no-evict)
    /// - Version: 7.0.0
    /// - Complexity: O(1)
    /// - Categories: @admin, @slow, @dangerous, @connection
    /// - Response: [Simple string](https:/redis.io/docs/reference/protocol-spec#simple-strings): `OK`.
    @inlinable
    public static func clientNoEvict(enabled: CLIENTNOEVICTEnabled) -> RESPCommand {
        RESPCommand("CLIENT", "NO-EVICT", enabled)
    }

    public enum CLIENTNOTOUCHEnabled: RESPRenderable {
        case on
        case off

        @inlinable
        public func writeToRESPBuffer(_ buffer: inout ByteBuffer) -> Int {
            switch self {
            case .on: "ON".writeToRESPBuffer(&buffer)
            case .off: "OFF".writeToRESPBuffer(&buffer)
            }
        }
    }
    /// Controls whether commands sent by the client affect the LRU/LFU of accessed keys.
    ///
    /// - Documentation: [CLIENT NO-TOUCH](https:/redis.io/docs/latest/commands/client-no-touch)
    /// - Version: 7.2.0
    /// - Complexity: O(1)
    /// - Categories: @slow, @connection
    /// - Response: [Simple string](https:/redis.io/docs/reference/protocol-spec#simple-strings): `OK`.
    @inlinable
    public static func clientNoTouch(enabled: CLIENTNOTOUCHEnabled) -> RESPCommand {
        RESPCommand("CLIENT", "NO-TOUCH", enabled)
    }

    public enum CLIENTPAUSEMode: RESPRenderable {
        case write
        case all

        @inlinable
        public func writeToRESPBuffer(_ buffer: inout ByteBuffer) -> Int {
            switch self {
            case .write: "WRITE".writeToRESPBuffer(&buffer)
            case .all: "ALL".writeToRESPBuffer(&buffer)
            }
        }
    }
    /// Suspends commands processing.
    ///
    /// - Documentation: [CLIENT PAUSE](https:/redis.io/docs/latest/commands/client-pause)
    /// - Version: 3.0.0
    /// - Complexity: O(1)
    /// - Categories: @admin, @slow, @dangerous, @connection
    /// - Response: [Simple string](https:/redis.io/docs/reference/protocol-spec#simple-strings): `OK` or an error if the timeout is invalid.
    @inlinable
    public static func clientPause(timeout: Int, mode: CLIENTPAUSEMode? = nil) -> RESPCommand {
        RESPCommand("CLIENT", "PAUSE", timeout, mode)
    }

    public enum CLIENTREPLYAction: RESPRenderable {
        case on
        case off
        case skip

        @inlinable
        public func writeToRESPBuffer(_ buffer: inout ByteBuffer) -> Int {
            switch self {
            case .on: "ON".writeToRESPBuffer(&buffer)
            case .off: "OFF".writeToRESPBuffer(&buffer)
            case .skip: "SKIP".writeToRESPBuffer(&buffer)
            }
        }
    }
    /// Instructs the server whether to reply to commands.
    ///
    /// - Documentation: [CLIENT REPLY](https:/redis.io/docs/latest/commands/client-reply)
    /// - Version: 3.2.0
    /// - Complexity: O(1)
    /// - Categories: @slow, @connection
    /// - Response: [Simple string](https:/redis.io/docs/reference/protocol-spec#simple-strings): `OK` when called with `ON`. When called with either `OFF` or `SKIP` sub-commands, no reply is made.
    @inlinable
    public static func clientReply(action: CLIENTREPLYAction) -> RESPCommand {
        RESPCommand("CLIENT", "REPLY", action)
    }

    public enum CLIENTSETINFOAttr: RESPRenderable {
        case libname(String)
        case libver(String)

        @inlinable
        public func writeToRESPBuffer(_ buffer: inout ByteBuffer) -> Int {
            switch self {
            case .libname(let libname): RESPWithToken("LIB-NAME", libname).writeToRESPBuffer(&buffer)
            case .libver(let libver): RESPWithToken("LIB-VER", libver).writeToRESPBuffer(&buffer)
            }
        }
    }
    /// Sets information specific to the client or connection.
    ///
    /// - Documentation: [CLIENT SETINFO](https:/redis.io/docs/latest/commands/client-setinfo)
    /// - Version: 7.2.0
    /// - Complexity: O(1)
    /// - Categories: @slow, @connection
    /// - Response: [Simple string](https:/redis.io/docs/reference/protocol-spec#simple-strings): `OK` if the attribute name was successfully set.
    @inlinable
    public static func clientSetinfo(attr: CLIENTSETINFOAttr) -> RESPCommand {
        RESPCommand("CLIENT", "SETINFO", attr)
    }

    /// Sets the connection name.
    ///
    /// - Documentation: [CLIENT SETNAME](https:/redis.io/docs/latest/commands/client-setname)
    /// - Version: 2.6.9
    /// - Complexity: O(1)
    /// - Categories: @slow, @connection
    /// - Response: [Simple string](https:/redis.io/docs/reference/protocol-spec#simple-strings): `OK` if the connection name was successfully set.
    @inlinable
    public static func clientSetname(connectionName: String) -> RESPCommand {
        RESPCommand("CLIENT", "SETNAME", connectionName)
    }

    public enum CLIENTTRACKINGStatus: RESPRenderable {
        case on
        case off

        @inlinable
        public func writeToRESPBuffer(_ buffer: inout ByteBuffer) -> Int {
            switch self {
            case .on: "ON".writeToRESPBuffer(&buffer)
            case .off: "OFF".writeToRESPBuffer(&buffer)
            }
        }
    }
    /// Controls server-assisted client-side caching for the connection.
    ///
    /// - Documentation: [CLIENT TRACKING](https:/redis.io/docs/latest/commands/client-tracking)
    /// - Version: 6.0.0
    /// - Complexity: O(1). Some options may introduce additional complexity.
    /// - Categories: @slow, @connection
    /// - Response: [Simple string](https:/redis.io/docs/reference/protocol-spec#simple-strings): `OK` if the connection was successfully put in tracking mode or if the tracking mode was successfully disabled. Otherwise, an error is returned.
    @inlinable
    public static func clientTracking(status: CLIENTTRACKINGStatus, clientId: Int? = nil, prefix: String? = nil, bcast: Bool = false, optin: Bool = false, optout: Bool = false, noloop: Bool = false) -> RESPCommand {
        RESPCommand("CLIENT", "TRACKING", status, RESPWithToken("REDIRECT", clientId), RESPWithToken("PREFIX", prefix), RedisPureToken("BCAST", bcast), RedisPureToken("OPTIN", optin), RedisPureToken("OPTOUT", optout), RedisPureToken("NOLOOP", noloop))
    }

    /// Controls server-assisted client-side caching for the connection.
    ///
    /// - Documentation: [CLIENT TRACKING](https:/redis.io/docs/latest/commands/client-tracking)
    /// - Version: 6.0.0
    /// - Complexity: O(1). Some options may introduce additional complexity.
    /// - Categories: @slow, @connection
    /// - Response: [Simple string](https:/redis.io/docs/reference/protocol-spec#simple-strings): `OK` if the connection was successfully put in tracking mode or if the tracking mode was successfully disabled. Otherwise, an error is returned.
    @inlinable
    public static func clientTracking(status: CLIENTTRACKINGStatus, clientId: Int? = nil, prefixs: [String], bcast: Bool = false, optin: Bool = false, optout: Bool = false, noloop: Bool = false) -> RESPCommand {
        RESPCommand("CLIENT", "TRACKING", status, RESPWithToken("REDIRECT", clientId), RESPWithToken("PREFIX", prefixs), RedisPureToken("BCAST", bcast), RedisPureToken("OPTIN", optin), RedisPureToken("OPTOUT", optout), RedisPureToken("NOLOOP", noloop))
    }

    /// Returns information about server-assisted client-side caching for the connection.
    ///
    /// - Documentation: [CLIENT TRACKINGINFO](https:/redis.io/docs/latest/commands/client-trackinginfo)
    /// - Version: 6.2.0
    /// - Complexity: O(1)
    /// - Categories: @slow, @connection
    /// - Response: [Map](https:/redis.io/docs/reference/protocol-spec#maps): a list of tracking information sections and their respective values.
    @inlinable
    public static func clientTrackinginfo() -> RESPCommand {
        RESPCommand("CLIENT", "TRACKINGINFO")
    }

    public enum CLIENTUNBLOCKUnblockType: RESPRenderable {
        case timeout
        case error

        @inlinable
        public func writeToRESPBuffer(_ buffer: inout ByteBuffer) -> Int {
            switch self {
            case .timeout: "TIMEOUT".writeToRESPBuffer(&buffer)
            case .error: "ERROR".writeToRESPBuffer(&buffer)
            }
        }
    }
    /// Unblocks a client blocked by a blocking command from a different connection.
    ///
    /// - Documentation: [CLIENT UNBLOCK](https:/redis.io/docs/latest/commands/client-unblock)
    /// - Version: 5.0.0
    /// - Complexity: O(log N) where N is the number of client connections
    /// - Categories: @admin, @slow, @dangerous, @connection
    /// - Response: One of the following:
    ///     * [Integer](https:/redis.io/docs/reference/protocol-spec#integers): `0` if the client was unblocked successfully.
    ///     * [Integer](https:/redis.io/docs/reference/protocol-spec#integers): `1` if the client wasn't unblocked.
    @inlinable
    public static func clientUnblock(clientId: Int, unblockType: CLIENTUNBLOCKUnblockType? = nil) -> RESPCommand {
        RESPCommand("CLIENT", "UNBLOCK", clientId, unblockType)
    }

    /// Resumes processing commands from paused clients.
    ///
    /// - Documentation: [CLIENT UNPAUSE](https:/redis.io/docs/latest/commands/client-unpause)
    /// - Version: 6.2.0
    /// - Complexity: O(N) Where N is the number of paused clients
    /// - Categories: @admin, @slow, @dangerous, @connection
    /// - Response: [Simple string](https:/redis.io/docs/reference/protocol-spec#simple-strings): `OK`.
    @inlinable
    public static func clientUnpause() -> RESPCommand {
        RESPCommand("CLIENT", "UNPAUSE")
    }

    /// Assigns new hash slots to a node.
    ///
    /// - Documentation: [CLUSTER ADDSLOTS](https:/redis.io/docs/latest/commands/cluster-addslots)
    /// - Version: 3.0.0
    /// - Complexity: O(N) where N is the total number of hash slot arguments
    /// - Categories: @admin, @slow, @dangerous
    /// - Response: [Simple string](https:/redis.io/docs/reference/protocol-spec#simple-strings): `OK` if the command was successful. Otherwise an error is returned.
    @inlinable
    public static func clusterAddslots(slot: Int) -> RESPCommand {
        RESPCommand("CLUSTER", "ADDSLOTS", slot)
    }

    /// Assigns new hash slots to a node.
    ///
    /// - Documentation: [CLUSTER ADDSLOTS](https:/redis.io/docs/latest/commands/cluster-addslots)
    /// - Version: 3.0.0
    /// - Complexity: O(N) where N is the total number of hash slot arguments
    /// - Categories: @admin, @slow, @dangerous
    /// - Response: [Simple string](https:/redis.io/docs/reference/protocol-spec#simple-strings): `OK` if the command was successful. Otherwise an error is returned.
    @inlinable
    public static func clusterAddslots(slots: [Int]) -> RESPCommand {
        RESPCommand("CLUSTER", "ADDSLOTS", slots)
    }

    public struct CLUSTERADDSLOTSRANGERange: RESPRenderable {
        @usableFromInline let startSlot: Int
        @usableFromInline let endSlot: Int

        @inlinable
        public func writeToRESPBuffer(_ buffer: inout ByteBuffer) -> Int {
            var count = 0
            count += self.startSlot.writeToRESPBuffer(&buffer)
            count += self.endSlot.writeToRESPBuffer(&buffer)
            return count
        }
    }
    /// Assigns new hash slot ranges to a node.
    ///
    /// - Documentation: [CLUSTER ADDSLOTSRANGE](https:/redis.io/docs/latest/commands/cluster-addslotsrange)
    /// - Version: 7.0.0
    /// - Complexity: O(N) where N is the total number of the slots between the start slot and end slot arguments.
    /// - Categories: @admin, @slow, @dangerous
    /// - Response: [Simple string](https:/redis.io/docs/reference/protocol-spec#simple-strings): `OK` if the command was successful. Otherwise an error is returned.
    @inlinable
    public static func clusterAddslotsrange(range: CLUSTERADDSLOTSRANGERange) -> RESPCommand {
        RESPCommand("CLUSTER", "ADDSLOTSRANGE", range)
    }

    /// Assigns new hash slot ranges to a node.
    ///
    /// - Documentation: [CLUSTER ADDSLOTSRANGE](https:/redis.io/docs/latest/commands/cluster-addslotsrange)
    /// - Version: 7.0.0
    /// - Complexity: O(N) where N is the total number of the slots between the start slot and end slot arguments.
    /// - Categories: @admin, @slow, @dangerous
    /// - Response: [Simple string](https:/redis.io/docs/reference/protocol-spec#simple-strings): `OK` if the command was successful. Otherwise an error is returned.
    @inlinable
    public static func clusterAddslotsrange(ranges: [CLUSTERADDSLOTSRANGERange]) -> RESPCommand {
        RESPCommand("CLUSTER", "ADDSLOTSRANGE", ranges)
    }

    /// Advances the cluster config epoch.
    ///
    /// - Documentation: [CLUSTER BUMPEPOCH](https:/redis.io/docs/latest/commands/cluster-bumpepoch)
    /// - Version: 3.0.0
    /// - Complexity: O(1)
    /// - Categories: @admin, @slow, @dangerous
    /// - Response: One of the following:
    ///     * [Bulk string](https:/redis.io/docs/reference/protocol-spec#bulk-strings): `BUMPED` if the epoch was incremented.
    ///     * [Bulk string](https:/redis.io/docs/reference/protocol-spec#bulk-strings): `STILL` if the node already has the greatest configured epoch in the cluster.
    @inlinable
    public static func clusterBumpepoch() -> RESPCommand {
        RESPCommand("CLUSTER", "BUMPEPOCH")
    }

    /// Returns the number of active failure reports active for a node.
    ///
    /// - Documentation: [CLUSTER COUNT-FAILURE-REPORTS](https:/redis.io/docs/latest/commands/cluster-count-failure-reports)
    /// - Version: 3.0.0
    /// - Complexity: O(N) where N is the number of failure reports
    /// - Categories: @admin, @slow, @dangerous
    /// - Response: [Integer](https:/redis.io/docs/reference/protocol-spec#integers): the number of active failure reports for the node.
    @inlinable
    public static func clusterCountFailureReports(nodeId: String) -> RESPCommand {
        RESPCommand("CLUSTER", "COUNT-FAILURE-REPORTS", nodeId)
    }

    /// Returns the number of keys in a hash slot.
    ///
    /// - Documentation: [CLUSTER COUNTKEYSINSLOT](https:/redis.io/docs/latest/commands/cluster-countkeysinslot)
    /// - Version: 3.0.0
    /// - Complexity: O(1)
    /// - Categories: @slow
    /// - Response: [Integer](https:/redis.io/docs/reference/protocol-spec#integers): The number of keys in the specified hash slot, or an error if the hash slot is invalid.
    @inlinable
    public static func clusterCountkeysinslot(slot: Int) -> RESPCommand {
        RESPCommand("CLUSTER", "COUNTKEYSINSLOT", slot)
    }

    /// Sets hash slots as unbound for a node.
    ///
    /// - Documentation: [CLUSTER DELSLOTS](https:/redis.io/docs/latest/commands/cluster-delslots)
    /// - Version: 3.0.0
    /// - Complexity: O(N) where N is the total number of hash slot arguments
    /// - Categories: @admin, @slow, @dangerous
    /// - Response: [Simple string](https:/redis.io/docs/reference/protocol-spec#simple-strings): `OK` if the command was successful. Otherwise an error is returned.
    @inlinable
    public static func clusterDelslots(slot: Int) -> RESPCommand {
        RESPCommand("CLUSTER", "DELSLOTS", slot)
    }

    /// Sets hash slots as unbound for a node.
    ///
    /// - Documentation: [CLUSTER DELSLOTS](https:/redis.io/docs/latest/commands/cluster-delslots)
    /// - Version: 3.0.0
    /// - Complexity: O(N) where N is the total number of hash slot arguments
    /// - Categories: @admin, @slow, @dangerous
    /// - Response: [Simple string](https:/redis.io/docs/reference/protocol-spec#simple-strings): `OK` if the command was successful. Otherwise an error is returned.
    @inlinable
    public static func clusterDelslots(slots: [Int]) -> RESPCommand {
        RESPCommand("CLUSTER", "DELSLOTS", slots)
    }

    public struct CLUSTERDELSLOTSRANGERange: RESPRenderable {
        @usableFromInline let startSlot: Int
        @usableFromInline let endSlot: Int

        @inlinable
        public func writeToRESPBuffer(_ buffer: inout ByteBuffer) -> Int {
            var count = 0
            count += self.startSlot.writeToRESPBuffer(&buffer)
            count += self.endSlot.writeToRESPBuffer(&buffer)
            return count
        }
    }
    /// Sets hash slot ranges as unbound for a node.
    ///
    /// - Documentation: [CLUSTER DELSLOTSRANGE](https:/redis.io/docs/latest/commands/cluster-delslotsrange)
    /// - Version: 7.0.0
    /// - Complexity: O(N) where N is the total number of the slots between the start slot and end slot arguments.
    /// - Categories: @admin, @slow, @dangerous
    /// - Response: [Simple string](https:/redis.io/docs/reference/protocol-spec#simple-strings): `OK` if the command was successful. Otherwise an error is returned.
    @inlinable
    public static func clusterDelslotsrange(range: CLUSTERDELSLOTSRANGERange) -> RESPCommand {
        RESPCommand("CLUSTER", "DELSLOTSRANGE", range)
    }

    /// Sets hash slot ranges as unbound for a node.
    ///
    /// - Documentation: [CLUSTER DELSLOTSRANGE](https:/redis.io/docs/latest/commands/cluster-delslotsrange)
    /// - Version: 7.0.0
    /// - Complexity: O(N) where N is the total number of the slots between the start slot and end slot arguments.
    /// - Categories: @admin, @slow, @dangerous
    /// - Response: [Simple string](https:/redis.io/docs/reference/protocol-spec#simple-strings): `OK` if the command was successful. Otherwise an error is returned.
    @inlinable
    public static func clusterDelslotsrange(ranges: [CLUSTERDELSLOTSRANGERange]) -> RESPCommand {
        RESPCommand("CLUSTER", "DELSLOTSRANGE", ranges)
    }

    public enum CLUSTERFAILOVEROptions: RESPRenderable {
        case force
        case takeover

        @inlinable
        public func writeToRESPBuffer(_ buffer: inout ByteBuffer) -> Int {
            switch self {
            case .force: "FORCE".writeToRESPBuffer(&buffer)
            case .takeover: "TAKEOVER".writeToRESPBuffer(&buffer)
            }
        }
    }
    /// Forces a replica to perform a manual failover of its master.
    ///
    /// - Documentation: [CLUSTER FAILOVER](https:/redis.io/docs/latest/commands/cluster-failover)
    /// - Version: 3.0.0
    /// - Complexity: O(1)
    /// - Categories: @admin, @slow, @dangerous
    /// - Response: [Simple string](https:/redis.io/docs/reference/protocol-spec#simple-strings): `OK` if the command was accepted and a manual failover is going to be attempted. An error if the operation cannot be executed, for example if the client is connected to a node that is already a master.
    @inlinable
    public static func clusterFailover(options: CLUSTERFAILOVEROptions? = nil) -> RESPCommand {
        RESPCommand("CLUSTER", "FAILOVER", options)
    }

    /// Deletes all slots information from a node.
    ///
    /// - Documentation: [CLUSTER FLUSHSLOTS](https:/redis.io/docs/latest/commands/cluster-flushslots)
    /// - Version: 3.0.0
    /// - Complexity: O(1)
    /// - Categories: @admin, @slow, @dangerous
    /// - Response: [Simple string](https:/redis.io/docs/reference/protocol-spec#simple-strings): `OK`.
    @inlinable
    public static func clusterFlushslots() -> RESPCommand {
        RESPCommand("CLUSTER", "FLUSHSLOTS")
    }

    /// Removes a node from the nodes table.
    ///
    /// - Documentation: [CLUSTER FORGET](https:/redis.io/docs/latest/commands/cluster-forget)
    /// - Version: 3.0.0
    /// - Complexity: O(1)
    /// - Categories: @admin, @slow, @dangerous
    /// - Response: [Simple string](https:/redis.io/docs/reference/protocol-spec#simple-strings): `OK` if the command was executed successfully. Otherwise an error is returned.
    @inlinable
    public static func clusterForget(nodeId: String) -> RESPCommand {
        RESPCommand("CLUSTER", "FORGET", nodeId)
    }

    /// Returns the key names in a hash slot.
    ///
    /// - Documentation: [CLUSTER GETKEYSINSLOT](https:/redis.io/docs/latest/commands/cluster-getkeysinslot)
    /// - Version: 3.0.0
    /// - Complexity: O(N) where N is the number of requested keys
    /// - Categories: @slow
    /// - Response: [Array](https:/redis.io/docs/reference/protocol-spec#arrays): an array with up to count elements.
    @inlinable
    public static func clusterGetkeysinslot(slot: Int, count: Int) -> RESPCommand {
        RESPCommand("CLUSTER", "GETKEYSINSLOT", slot, count)
    }

    /// Returns helpful text about the different subcommands.
    ///
    /// - Documentation: [CLUSTER HELP](https:/redis.io/docs/latest/commands/cluster-help)
    /// - Version: 5.0.0
    /// - Complexity: O(1)
    /// - Categories: @slow
    /// - Response: [Array](https:/redis.io/docs/reference/protocol-spec#arrays): a list of subcommands and their descriptions.
    @inlinable
    public static func clusterHelp() -> RESPCommand {
        RESPCommand("CLUSTER", "HELP")
    }

    /// Returns information about the state of a node.
    ///
    /// - Documentation: [CLUSTER INFO](https:/redis.io/docs/latest/commands/cluster-info)
    /// - Version: 3.0.0
    /// - Complexity: O(1)
    /// - Categories: @slow
    /// - Response: [Bulk string](https:/redis.io/docs/reference/protocol-spec#bulk-strings): A map between named fields and values in the form of <field>:<value> lines separated by newlines composed by the two bytes CRLF
    @inlinable
    public static func clusterInfo() -> RESPCommand {
        RESPCommand("CLUSTER", "INFO")
    }

    /// Returns the hash slot for a key.
    ///
    /// - Documentation: [CLUSTER KEYSLOT](https:/redis.io/docs/latest/commands/cluster-keyslot)
    /// - Version: 3.0.0
    /// - Complexity: O(N) where N is the number of bytes in the key
    /// - Categories: @slow
    /// - Response: [Integer](https:/redis.io/docs/reference/protocol-spec#integers): The hash slot number for the specified key
    @inlinable
    public static func clusterKeyslot(key: String) -> RESPCommand {
        RESPCommand("CLUSTER", "KEYSLOT", key)
    }

    /// Returns a list of all TCP links to and from peer nodes.
    ///
    /// - Documentation: [CLUSTER LINKS](https:/redis.io/docs/latest/commands/cluster-links)
    /// - Version: 7.0.0
    /// - Complexity: O(N) where N is the total number of Cluster nodes
    /// - Categories: @slow
    /// - Response: [Array](https:/redis.io/docs/reference/protocol-spec#arrays): an array of [Map](https:/redis.io/docs/reference/protocol-spec#maps) where each map contains various attributes and their values of a cluster link.
    @inlinable
    public static func clusterLinks() -> RESPCommand {
        RESPCommand("CLUSTER", "LINKS")
    }

    /// Forces a node to handshake with another node.
    ///
    /// - Documentation: [CLUSTER MEET](https:/redis.io/docs/latest/commands/cluster-meet)
    /// - Version: 3.0.0
    /// - Complexity: O(1)
    /// - Categories: @admin, @slow, @dangerous
    /// - Response: [Simple string](https:/redis.io/docs/reference/protocol-spec#simple-strings): `OK` if the command was successful. If the address or port specified are invalid an error is returned.
    @inlinable
    public static func clusterMeet(ip: String, port: Int, clusterBusPort: Int? = nil) -> RESPCommand {
        RESPCommand("CLUSTER", "MEET", ip, port, clusterBusPort)
    }

    /// Returns the ID of a node.
    ///
    /// - Documentation: [CLUSTER MYID](https:/redis.io/docs/latest/commands/cluster-myid)
    /// - Version: 3.0.0
    /// - Complexity: O(1)
    /// - Categories: @slow
    /// - Response: [Bulk string](https:/redis.io/docs/reference/protocol-spec#bulk-strings): the node ID.
    @inlinable
    public static func clusterMyid() -> RESPCommand {
        RESPCommand("CLUSTER", "MYID")
    }

    /// Returns the shard ID of a node.
    ///
    /// - Documentation: [CLUSTER MYSHARDID](https:/redis.io/docs/latest/commands/cluster-myshardid)
    /// - Version: 7.2.0
    /// - Complexity: O(1)
    /// - Categories: @slow
    /// - Response: [Bulk string](https:/redis.io/docs/reference/protocol-spec#bulk-strings): the node's shard ID.
    @inlinable
    public static func clusterMyshardid() -> RESPCommand {
        RESPCommand("CLUSTER", "MYSHARDID")
    }

    /// Returns the cluster configuration for a node.
    ///
    /// - Documentation: [CLUSTER NODES](https:/redis.io/docs/latest/commands/cluster-nodes)
    /// - Version: 3.0.0
    /// - Complexity: O(N) where N is the total number of Cluster nodes
    /// - Categories: @slow
    /// - Response: [Bulk string](https:/redis.io/docs/reference/protocol-spec#bulk-strings): the serialized cluster configuration.
    @inlinable
    public static func clusterNodes() -> RESPCommand {
        RESPCommand("CLUSTER", "NODES")
    }

    /// Lists the replica nodes of a master node.
    ///
    /// - Documentation: [CLUSTER REPLICAS](https:/redis.io/docs/latest/commands/cluster-replicas)
    /// - Version: 5.0.0
    /// - Complexity: O(N) where N is the number of replicas.
    /// - Categories: @admin, @slow, @dangerous
    /// - Response: [Array](https:/redis.io/docs/reference/protocol-spec#arrays): a list of replica nodes replicating from the specified master node provided in the same format used by `CLUSTER NODES`.
    @inlinable
    public static func clusterReplicas(nodeId: String) -> RESPCommand {
        RESPCommand("CLUSTER", "REPLICAS", nodeId)
    }

    /// Configure a node as replica of a master node.
    ///
    /// - Documentation: [CLUSTER REPLICATE](https:/redis.io/docs/latest/commands/cluster-replicate)
    /// - Version: 3.0.0
    /// - Complexity: O(1)
    /// - Categories: @admin, @slow, @dangerous
    /// - Response: [Simple string](https:/redis.io/docs/reference/protocol-spec#simple-strings): `OK` if the command was successful. Otherwise an error is returned.
    @inlinable
    public static func clusterReplicate(nodeId: String) -> RESPCommand {
        RESPCommand("CLUSTER", "REPLICATE", nodeId)
    }

    public enum CLUSTERRESETResetType: RESPRenderable {
        case hard
        case soft

        @inlinable
        public func writeToRESPBuffer(_ buffer: inout ByteBuffer) -> Int {
            switch self {
            case .hard: "HARD".writeToRESPBuffer(&buffer)
            case .soft: "SOFT".writeToRESPBuffer(&buffer)
            }
        }
    }
    /// Resets a node.
    ///
    /// - Documentation: [CLUSTER RESET](https:/redis.io/docs/latest/commands/cluster-reset)
    /// - Version: 3.0.0
    /// - Complexity: O(N) where N is the number of known nodes. The command may execute a FLUSHALL as a side effect.
    /// - Categories: @admin, @slow, @dangerous
    /// - Response: [Simple string](https:/redis.io/docs/reference/protocol-spec#simple-strings): `OK` if the command was successful. Otherwise an error is returned.
    @inlinable
    public static func clusterReset(resetType: CLUSTERRESETResetType? = nil) -> RESPCommand {
        RESPCommand("CLUSTER", "RESET", resetType)
    }

    /// Forces a node to save the cluster configuration to disk.
    ///
    /// - Documentation: [CLUSTER SAVECONFIG](https:/redis.io/docs/latest/commands/cluster-saveconfig)
    /// - Version: 3.0.0
    /// - Complexity: O(1)
    /// - Categories: @admin, @slow, @dangerous
    /// - Response: [Simple string](https:/redis.io/docs/reference/protocol-spec#simple-strings): `OK` if the command was successful. Otherwise an error is returned.
    @inlinable
    public static func clusterSaveconfig() -> RESPCommand {
        RESPCommand("CLUSTER", "SAVECONFIG")
    }

    /// Sets the configuration epoch for a new node.
    ///
    /// - Documentation: [CLUSTER SET-CONFIG-EPOCH](https:/redis.io/docs/latest/commands/cluster-set-config-epoch)
    /// - Version: 3.0.0
    /// - Complexity: O(1)
    /// - Categories: @admin, @slow, @dangerous
    /// - Response: [Simple string](https:/redis.io/docs/reference/protocol-spec#simple-strings): `OK` if the command was successful. Otherwise an error is returned.
    @inlinable
    public static func clusterSetConfigEpoch(configEpoch: Int) -> RESPCommand {
        RESPCommand("CLUSTER", "SET-CONFIG-EPOCH", configEpoch)
    }

    public enum CLUSTERSETSLOTSubcommand: RESPRenderable {
        case importing(String)
        case migrating(String)
        case node(String)
        case stable

        @inlinable
        public func writeToRESPBuffer(_ buffer: inout ByteBuffer) -> Int {
            switch self {
            case .importing(let importing): RESPWithToken("IMPORTING", importing).writeToRESPBuffer(&buffer)
            case .migrating(let migrating): RESPWithToken("MIGRATING", migrating).writeToRESPBuffer(&buffer)
            case .node(let node): RESPWithToken("NODE", node).writeToRESPBuffer(&buffer)
            case .stable: "STABLE".writeToRESPBuffer(&buffer)
            }
        }
    }
    /// Binds a hash slot to a node.
    ///
    /// - Documentation: [CLUSTER SETSLOT](https:/redis.io/docs/latest/commands/cluster-setslot)
    /// - Version: 3.0.0
    /// - Complexity: O(1)
    /// - Categories: @admin, @slow, @dangerous
    /// - Response: [Simple string](https:/redis.io/docs/reference/protocol-spec#simple-strings): all the sub-commands return `OK` if the command was successful. Otherwise an error is returned.
    @inlinable
    public static func clusterSetslot(slot: Int, subcommand: CLUSTERSETSLOTSubcommand) -> RESPCommand {
        RESPCommand("CLUSTER", "SETSLOT", slot, subcommand)
    }

    /// Returns the mapping of cluster slots to shards.
    ///
    /// - Documentation: [CLUSTER SHARDS](https:/redis.io/docs/latest/commands/cluster-shards)
    /// - Version: 7.0.0
    /// - Complexity: O(N) where N is the total number of cluster nodes
    /// - Categories: @slow
    /// - Response: [Array](https:/redis.io/docs/reference/protocol-spec#arrays): a nested list of [Map](https:/redis.io/docs/reference/protocol-spec#maps) of hash ranges and shard nodes describing individual shards.
    @inlinable
    public static func clusterShards() -> RESPCommand {
        RESPCommand("CLUSTER", "SHARDS")
    }

    /// Lists the replica nodes of a master node.
    ///
    /// - Documentation: [CLUSTER SLAVES](https:/redis.io/docs/latest/commands/cluster-slaves)
    /// - Version: 3.0.0
    /// - Complexity: O(N) where N is the number of replicas.
    /// - Categories: @admin, @slow, @dangerous
    /// - Response: [Array](https:/redis.io/docs/reference/protocol-spec#arrays): a list of replica nodes replicating from the specified master node provided in the same format used by `CLUSTER NODES`.
    @inlinable
    public static func clusterSlaves(nodeId: String) -> RESPCommand {
        RESPCommand("CLUSTER", "SLAVES", nodeId)
    }

    /// Returns the mapping of cluster slots to nodes.
    ///
    /// - Documentation: [CLUSTER SLOTS](https:/redis.io/docs/latest/commands/cluster-slots)
    /// - Version: 3.0.0
    /// - Complexity: O(N) where N is the total number of Cluster nodes
    /// - Categories: @slow
    /// - Response: [Array](https:/redis.io/docs/reference/protocol-spec#arrays): nested list of slot ranges with networking information.
    @inlinable
    public static func clusterSlots() -> RESPCommand {
        RESPCommand("CLUSTER", "SLOTS")
    }

    /// Returns detailed information about all commands.
    ///
    /// - Documentation: [COMMAND](https:/redis.io/docs/latest/commands/command)
    /// - Version: 2.8.13
    /// - Complexity: O(N) where N is the total number of Redis commands
    /// - Categories: @slow, @connection
    /// - Response: [Array](https:/redis.io/docs/reference/protocol-spec#arrays): a nested list of command details. The order of the commands in the array is random.
    @inlinable
    public static func command() -> RESPCommand {
        RESPCommand("COMMAND")
    }

    /// Returns a count of commands.
    ///
    /// - Documentation: [COMMAND COUNT](https:/redis.io/docs/latest/commands/command-count)
    /// - Version: 2.8.13
    /// - Complexity: O(1)
    /// - Categories: @slow, @connection
    /// - Response: [Integer](https:/redis.io/docs/reference/protocol-spec#integers): the number of commands returned by `COMMAND`.
    @inlinable
    public static func commandCount() -> RESPCommand {
        RESPCommand("COMMAND", "COUNT")
    }

    /// Returns documentary information about one, multiple or all commands.
    ///
    /// - Documentation: [COMMAND DOCS](https:/redis.io/docs/latest/commands/command-docs)
    /// - Version: 7.0.0
    /// - Complexity: O(N) where N is the number of commands to look up
    /// - Categories: @slow, @connection
    /// - Response: [Map](https:/redis.io/docs/reference/protocol-spec#maps): a map where each key is a command name, and each value is the documentary information.
    @inlinable
    public static func commandDocs(commandName: String? = nil) -> RESPCommand {
        RESPCommand("COMMAND", "DOCS", commandName)
    }

    /// Returns documentary information about one, multiple or all commands.
    ///
    /// - Documentation: [COMMAND DOCS](https:/redis.io/docs/latest/commands/command-docs)
    /// - Version: 7.0.0
    /// - Complexity: O(N) where N is the number of commands to look up
    /// - Categories: @slow, @connection
    /// - Response: [Map](https:/redis.io/docs/reference/protocol-spec#maps): a map where each key is a command name, and each value is the documentary information.
    @inlinable
    public static func commandDocs(commandNames: [String]) -> RESPCommand {
        RESPCommand("COMMAND", "DOCS", commandNames)
    }

    /// Extracts the key names from an arbitrary command.
    ///
    /// - Documentation: [COMMAND GETKEYS](https:/redis.io/docs/latest/commands/command-getkeys)
    /// - Version: 2.8.13
    /// - Complexity: O(N) where N is the number of arguments to the command
    /// - Categories: @slow, @connection
    /// - Response: [Array](https:/redis.io/docs/reference/protocol-spec#arrays): a list of keys from the given command.
    @inlinable
    public static func commandGetkeys(command: String, arg: String? = nil) -> RESPCommand {
        RESPCommand("COMMAND", "GETKEYS", command, arg)
    }

    /// Extracts the key names from an arbitrary command.
    ///
    /// - Documentation: [COMMAND GETKEYS](https:/redis.io/docs/latest/commands/command-getkeys)
    /// - Version: 2.8.13
    /// - Complexity: O(N) where N is the number of arguments to the command
    /// - Categories: @slow, @connection
    /// - Response: [Array](https:/redis.io/docs/reference/protocol-spec#arrays): a list of keys from the given command.
    @inlinable
    public static func commandGetkeys(command: String, args: [String]) -> RESPCommand {
        RESPCommand("COMMAND", "GETKEYS", command, args)
    }

    /// Extracts the key names and access flags for an arbitrary command.
    ///
    /// - Documentation: [COMMAND GETKEYSANDFLAGS](https:/redis.io/docs/latest/commands/command-getkeysandflags)
    /// - Version: 7.0.0
    /// - Complexity: O(N) where N is the number of arguments to the command
    /// - Categories: @slow, @connection
    /// - Response: [Array](https:/redis.io/docs/reference/protocol-spec#arrays): a list of keys from the given command and their usage flags.
    @inlinable
    public static func commandGetkeysandflags(command: String, arg: String? = nil) -> RESPCommand {
        RESPCommand("COMMAND", "GETKEYSANDFLAGS", command, arg)
    }

    /// Extracts the key names and access flags for an arbitrary command.
    ///
    /// - Documentation: [COMMAND GETKEYSANDFLAGS](https:/redis.io/docs/latest/commands/command-getkeysandflags)
    /// - Version: 7.0.0
    /// - Complexity: O(N) where N is the number of arguments to the command
    /// - Categories: @slow, @connection
    /// - Response: [Array](https:/redis.io/docs/reference/protocol-spec#arrays): a list of keys from the given command and their usage flags.
    @inlinable
    public static func commandGetkeysandflags(command: String, args: [String]) -> RESPCommand {
        RESPCommand("COMMAND", "GETKEYSANDFLAGS", command, args)
    }

    /// Returns helpful text about the different subcommands.
    ///
    /// - Documentation: [COMMAND HELP](https:/redis.io/docs/latest/commands/command-help)
    /// - Version: 5.0.0
    /// - Complexity: O(1)
    /// - Categories: @slow, @connection
    /// - Response: [Array](https:/redis.io/docs/reference/protocol-spec#arrays): a list of sub-commands and their descriptions.
    @inlinable
    public static func commandHelp() -> RESPCommand {
        RESPCommand("COMMAND", "HELP")
    }

    /// Returns information about one, multiple or all commands.
    ///
    /// - Documentation: [COMMAND INFO](https:/redis.io/docs/latest/commands/command-info)
    /// - Version: 2.8.13
    /// - Complexity: O(N) where N is the number of commands to look up
    /// - Categories: @slow, @connection
    /// - Response: [Array](https:/redis.io/docs/reference/protocol-spec#arrays): a nested list of command details.
    @inlinable
    public static func commandInfo(commandName: String? = nil) -> RESPCommand {
        RESPCommand("COMMAND", "INFO", commandName)
    }

    /// Returns information about one, multiple or all commands.
    ///
    /// - Documentation: [COMMAND INFO](https:/redis.io/docs/latest/commands/command-info)
    /// - Version: 2.8.13
    /// - Complexity: O(N) where N is the number of commands to look up
    /// - Categories: @slow, @connection
    /// - Response: [Array](https:/redis.io/docs/reference/protocol-spec#arrays): a nested list of command details.
    @inlinable
    public static func commandInfo(commandNames: [String]) -> RESPCommand {
        RESPCommand("COMMAND", "INFO", commandNames)
    }

    public enum COMMANDLISTFilterby: RESPRenderable {
        case moduleName(String)
        case category(String)
        case pattern(String)

        @inlinable
        public func writeToRESPBuffer(_ buffer: inout ByteBuffer) -> Int {
            switch self {
            case .moduleName(let moduleName): RESPWithToken("MODULE", moduleName).writeToRESPBuffer(&buffer)
            case .category(let category): RESPWithToken("ACLCAT", category).writeToRESPBuffer(&buffer)
            case .pattern(let pattern): RESPWithToken("PATTERN", pattern).writeToRESPBuffer(&buffer)
            }
        }
    }
    /// Returns a list of command names.
    ///
    /// - Documentation: [COMMAND LIST](https:/redis.io/docs/latest/commands/command-list)
    /// - Version: 7.0.0
    /// - Complexity: O(N) where N is the total number of Redis commands
    /// - Categories: @slow, @connection
    /// - Response: [Array](https:/redis.io/docs/reference/protocol-spec#arrays): a list of command names.
    @inlinable
    public static func commandList(filterby: COMMANDLISTFilterby? = nil) -> RESPCommand {
        RESPCommand("COMMAND", "LIST", RESPWithToken("FILTERBY", filterby))
    }

    /// Returns the effective values of configuration parameters.
    ///
    /// - Documentation: [CONFIG GET](https:/redis.io/docs/latest/commands/config-get)
    /// - Version: 2.0.0
    /// - Complexity: O(N) when N is the number of configuration parameters provided
    /// - Categories: @admin, @slow, @dangerous
    /// - Response: [Map](https:/redis.io/docs/reference/protocol-spec#maps): a list of configuration parameters matching the provided arguments.
    @inlinable
    public static func configGet(parameter: String) -> RESPCommand {
        RESPCommand("CONFIG", "GET", parameter)
    }

    /// Returns the effective values of configuration parameters.
    ///
    /// - Documentation: [CONFIG GET](https:/redis.io/docs/latest/commands/config-get)
    /// - Version: 2.0.0
    /// - Complexity: O(N) when N is the number of configuration parameters provided
    /// - Categories: @admin, @slow, @dangerous
    /// - Response: [Map](https:/redis.io/docs/reference/protocol-spec#maps): a list of configuration parameters matching the provided arguments.
    @inlinable
    public static func configGet(parameters: [String]) -> RESPCommand {
        RESPCommand("CONFIG", "GET", parameters)
    }

    /// Returns helpful text about the different subcommands.
    ///
    /// - Documentation: [CONFIG HELP](https:/redis.io/docs/latest/commands/config-help)
    /// - Version: 5.0.0
    /// - Complexity: O(1)
    /// - Categories: @slow
    /// - Response: [Array](https:/redis.io/docs/reference/protocol-spec#arrays): a list of sub-commands and their descriptions.
    @inlinable
    public static func configHelp() -> RESPCommand {
        RESPCommand("CONFIG", "HELP")
    }

    /// Resets the server's statistics.
    ///
    /// - Documentation: [CONFIG RESETSTAT](https:/redis.io/docs/latest/commands/config-resetstat)
    /// - Version: 2.0.0
    /// - Complexity: O(1)
    /// - Categories: @admin, @slow, @dangerous
    /// - Response: [Simple string](https:/redis.io/docs/reference/protocol-spec#simple-strings): `OK`.
    @inlinable
    public static func configResetstat() -> RESPCommand {
        RESPCommand("CONFIG", "RESETSTAT")
    }

    /// Persists the effective configuration to file.
    ///
    /// - Documentation: [CONFIG REWRITE](https:/redis.io/docs/latest/commands/config-rewrite)
    /// - Version: 2.8.0
    /// - Complexity: O(1)
    /// - Categories: @admin, @slow, @dangerous
    /// - Response: [Simple string](https:/redis.io/docs/reference/protocol-spec#simple-strings): `OK` when the configuration was rewritten properly. Otherwise an error is returned.
    @inlinable
    public static func configRewrite() -> RESPCommand {
        RESPCommand("CONFIG", "REWRITE")
    }

    public struct CONFIGSETData: RESPRenderable {
        @usableFromInline let parameter: String
        @usableFromInline let value: String

        @inlinable
        public func writeToRESPBuffer(_ buffer: inout ByteBuffer) -> Int {
            var count = 0
            count += self.parameter.writeToRESPBuffer(&buffer)
            count += self.value.writeToRESPBuffer(&buffer)
            return count
        }
    }
    /// Sets configuration parameters in-flight.
    ///
    /// - Documentation: [CONFIG SET](https:/redis.io/docs/latest/commands/config-set)
    /// - Version: 2.0.0
    /// - Complexity: O(N) when N is the number of configuration parameters provided
    /// - Categories: @admin, @slow, @dangerous
    /// - Response: [Simple string](https:/redis.io/docs/reference/protocol-spec#simple-strings): `OK` when the configuration was set properly. Otherwise an error is returned.
    @inlinable
    public static func configSet(data: CONFIGSETData) -> RESPCommand {
        RESPCommand("CONFIG", "SET", data)
    }

    /// Sets configuration parameters in-flight.
    ///
    /// - Documentation: [CONFIG SET](https:/redis.io/docs/latest/commands/config-set)
    /// - Version: 2.0.0
    /// - Complexity: O(N) when N is the number of configuration parameters provided
    /// - Categories: @admin, @slow, @dangerous
    /// - Response: [Simple string](https:/redis.io/docs/reference/protocol-spec#simple-strings): `OK` when the configuration was set properly. Otherwise an error is returned.
    @inlinable
    public static func configSet(datas: [CONFIGSETData]) -> RESPCommand {
        RESPCommand("CONFIG", "SET", datas)
    }

    /// Copies the value of a key to a new key.
    ///
    /// - Documentation: [COPY](https:/redis.io/docs/latest/commands/copy)
    /// - Version: 6.2.0
    /// - Complexity: O(N) worst case for collections, where N is the number of nested items. O(1) for string values.
    /// - Categories: @keyspace, @write, @slow
    /// - Response: One of the following:
    ///     * [Integer](https:/redis.io/docs/reference/protocol-spec#integers): `1` if _source_ was copied.
    ///     * [Integer](https:/redis.io/docs/reference/protocol-spec#integers): `0` if _source_ was not copied.
    @inlinable
    public static func copy(source: RedisKey, destination: RedisKey, destinationDb: Int? = nil, replace: Bool = false) -> RESPCommand {
        RESPCommand("COPY", source, destination, RESPWithToken("DB", destinationDb), RedisPureToken("REPLACE", replace))
    }

    /// Returns the number of keys in the database.
    ///
    /// - Documentation: [DBSIZE](https:/redis.io/docs/latest/commands/dbsize)
    /// - Version: 1.0.0
    /// - Complexity: O(1)
    /// - Categories: @keyspace, @read, @fast
    /// - Response: [Integer](https:/redis.io/docs/reference/protocol-spec#integers): the number of keys in the currently-selected database.
    @inlinable
    public static func dbsize() -> RESPCommand {
        RESPCommand("DBSIZE")
    }

    /// Decrements the integer value of a key by one. Uses 0 as initial value if the key doesn't exist.
    ///
    /// - Documentation: [DECR](https:/redis.io/docs/latest/commands/decr)
    /// - Version: 1.0.0
    /// - Complexity: O(1)
    /// - Categories: @write, @string, @fast
    /// - Response: [Integer](https:/redis.io/docs/reference/protocol-spec#integers): the value of the key after decrementing it.
    @inlinable
    public static func decr(key: RedisKey) -> RESPCommand {
        RESPCommand("DECR", key)
    }

    /// Decrements a number from the integer value of a key. Uses 0 as initial value if the key doesn't exist.
    ///
    /// - Documentation: [DECRBY](https:/redis.io/docs/latest/commands/decrby)
    /// - Version: 1.0.0
    /// - Complexity: O(1)
    /// - Categories: @write, @string, @fast
    /// - Response: [Integer](https:/redis.io/docs/reference/protocol-spec#integers): the value of the key after decrementing it.
    @inlinable
    public static func decrby(key: RedisKey, decrement: Int) -> RESPCommand {
        RESPCommand("DECRBY", key, decrement)
    }

    /// Deletes one or more keys.
    ///
    /// - Documentation: [DEL](https:/redis.io/docs/latest/commands/del)
    /// - Version: 1.0.0
    /// - Complexity: O(N) where N is the number of keys that will be removed. When a key to remove holds a value other than a string, the individual complexity for this key is O(M) where M is the number of elements in the list, set, sorted set or hash. Removing a single key that holds a string value is O(1).
    /// - Categories: @keyspace, @write, @slow
    /// - Response: [Integer](https:/redis.io/docs/reference/protocol-spec#integers): the number of keys that were removed.
    @inlinable
    public static func del(key: RedisKey) -> RESPCommand {
        RESPCommand("DEL", key)
    }

    /// Deletes one or more keys.
    ///
    /// - Documentation: [DEL](https:/redis.io/docs/latest/commands/del)
    /// - Version: 1.0.0
    /// - Complexity: O(N) where N is the number of keys that will be removed. When a key to remove holds a value other than a string, the individual complexity for this key is O(M) where M is the number of elements in the list, set, sorted set or hash. Removing a single key that holds a string value is O(1).
    /// - Categories: @keyspace, @write, @slow
    /// - Response: [Integer](https:/redis.io/docs/reference/protocol-spec#integers): the number of keys that were removed.
    @inlinable
    public static func del(keys: [RedisKey]) -> RESPCommand {
        RESPCommand("DEL", keys)
    }

    /// Discards a transaction.
    ///
    /// - Documentation: [DISCARD](https:/redis.io/docs/latest/commands/discard)
    /// - Version: 2.0.0
    /// - Complexity: O(N), when N is the number of queued commands
    /// - Categories: @fast, @transaction
    /// - Response: [Simple string](https:/redis.io/docs/reference/protocol-spec#simple-strings): `OK`.
    @inlinable
    public static func discard() -> RESPCommand {
        RESPCommand("DISCARD")
    }

    /// Returns a serialized representation of the value stored at a key.
    ///
    /// - Documentation: [DUMP](https:/redis.io/docs/latest/commands/dump)
    /// - Version: 2.6.0
    /// - Complexity: O(1) to access the key and additional O(N*M) to serialize it, where N is the number of Redis objects composing the value and M their average size. For small string values the time complexity is thus O(1)+O(1*M) where M is small, so simply O(1).
    /// - Categories: @keyspace, @read, @slow
    /// - Response: One of the following:
    ///     * [Bulk string](https:/redis.io/docs/reference/protocol-spec#bulk-strings): the serialized value of the key.
    ///     * [Null](https:/redis.io/docs/reference/protocol-spec#nulls): the key does not exist.
    @inlinable
    public static func dump(key: RedisKey) -> RESPCommand {
        RESPCommand("DUMP", key)
    }

    /// Returns the given string.
    ///
    /// - Documentation: [ECHO](https:/redis.io/docs/latest/commands/echo)
    /// - Version: 1.0.0
    /// - Complexity: O(1)
    /// - Categories: @fast, @connection
    /// - Response: [Bulk string](https:/redis.io/docs/reference/protocol-spec#bulk-strings): the given string.
    @inlinable
    public static func echo(message: String) -> RESPCommand {
        RESPCommand("ECHO", message)
    }

    /// Executes a server-side Lua script.
    ///
    /// - Documentation: [EVAL](https:/redis.io/docs/latest/commands/eval)
    /// - Version: 2.6.0
    /// - Complexity: Depends on the script that is executed.
    /// - Categories: @slow, @scripting
    /// - Response: The return value depends on the script that was executed.
    @inlinable
    public static func eval(script: String, key: RedisKey? = nil, arg: String? = nil) -> RESPCommand {
        RESPCommand("EVAL", script, 1, key, arg)
    }

    /// Executes a server-side Lua script.
    ///
    /// - Documentation: [EVAL](https:/redis.io/docs/latest/commands/eval)
    /// - Version: 2.6.0
    /// - Complexity: Depends on the script that is executed.
    /// - Categories: @slow, @scripting
    /// - Response: The return value depends on the script that was executed.
    @inlinable
    public static func eval(script: String, keys: [RedisKey], args: [String]) -> RESPCommand {
        RESPCommand("EVAL", script, RESPArrayWithCount(keys), args)
    }

    /// Executes a server-side Lua script by SHA1 digest.
    ///
    /// - Documentation: [EVALSHA](https:/redis.io/docs/latest/commands/evalsha)
    /// - Version: 2.6.0
    /// - Complexity: Depends on the script that is executed.
    /// - Categories: @slow, @scripting
    /// - Response: The return value depends on the script that was executed.
    @inlinable
    public static func evalsha(sha1: String, key: RedisKey? = nil, arg: String? = nil) -> RESPCommand {
        RESPCommand("EVALSHA", sha1, 1, key, arg)
    }

    /// Executes a server-side Lua script by SHA1 digest.
    ///
    /// - Documentation: [EVALSHA](https:/redis.io/docs/latest/commands/evalsha)
    /// - Version: 2.6.0
    /// - Complexity: Depends on the script that is executed.
    /// - Categories: @slow, @scripting
    /// - Response: The return value depends on the script that was executed.
    @inlinable
    public static func evalsha(sha1: String, keys: [RedisKey], args: [String]) -> RESPCommand {
        RESPCommand("EVALSHA", sha1, RESPArrayWithCount(keys), args)
    }

    /// Executes a read-only server-side Lua script by SHA1 digest.
    ///
    /// - Documentation: [EVALSHA_RO](https:/redis.io/docs/latest/commands/evalsha_ro)
    /// - Version: 7.0.0
    /// - Complexity: Depends on the script that is executed.
    /// - Categories: @slow, @scripting
    /// - Response: The return value depends on the script that was executed.
    @inlinable
    public static func evalshaRo(sha1: String, key: RedisKey? = nil, arg: String? = nil) -> RESPCommand {
        RESPCommand("EVALSHA_RO", sha1, 1, key, arg)
    }

    /// Executes a read-only server-side Lua script by SHA1 digest.
    ///
    /// - Documentation: [EVALSHA_RO](https:/redis.io/docs/latest/commands/evalsha_ro)
    /// - Version: 7.0.0
    /// - Complexity: Depends on the script that is executed.
    /// - Categories: @slow, @scripting
    /// - Response: The return value depends on the script that was executed.
    @inlinable
    public static func evalshaRo(sha1: String, keys: [RedisKey], args: [String]) -> RESPCommand {
        RESPCommand("EVALSHA_RO", sha1, RESPArrayWithCount(keys), args)
    }

    /// Executes a read-only server-side Lua script.
    ///
    /// - Documentation: [EVAL_RO](https:/redis.io/docs/latest/commands/eval_ro)
    /// - Version: 7.0.0
    /// - Complexity: Depends on the script that is executed.
    /// - Categories: @slow, @scripting
    /// - Response: The return value depends on the script that was executed.
    @inlinable
    public static func evalRo(script: String, key: RedisKey? = nil, arg: String? = nil) -> RESPCommand {
        RESPCommand("EVAL_RO", script, 1, key, arg)
    }

    /// Executes a read-only server-side Lua script.
    ///
    /// - Documentation: [EVAL_RO](https:/redis.io/docs/latest/commands/eval_ro)
    /// - Version: 7.0.0
    /// - Complexity: Depends on the script that is executed.
    /// - Categories: @slow, @scripting
    /// - Response: The return value depends on the script that was executed.
    @inlinable
    public static func evalRo(script: String, keys: [RedisKey], args: [String]) -> RESPCommand {
        RESPCommand("EVAL_RO", script, RESPArrayWithCount(keys), args)
    }

    /// Executes all commands in a transaction.
    ///
    /// - Documentation: [EXEC](https:/redis.io/docs/latest/commands/exec)
    /// - Version: 1.2.0
    /// - Complexity: Depends on commands in the transaction
    /// - Categories: @slow, @transaction
    /// - Response: One of the following:
    ///     * [Array](https:/redis.io/docs/reference/protocol-spec#arrays): each element being the reply to each of the commands in the atomic transaction.
    ///     * [Null](https:/redis.io/docs/reference/protocol-spec#nulls): the transaction was aborted because a `WATCH`ed key was touched.
    @inlinable
    public static func exec() -> RESPCommand {
        RESPCommand("EXEC")
    }

    /// Determines whether one or more keys exist.
    ///
    /// - Documentation: [EXISTS](https:/redis.io/docs/latest/commands/exists)
    /// - Version: 1.0.0
    /// - Complexity: O(N) where N is the number of keys to check.
    /// - Categories: @keyspace, @read, @fast
    /// - Response: [Integer](https:/redis.io/docs/reference/protocol-spec#integers): the number of keys that exist from those specified as arguments.
    @inlinable
    public static func exists(key: RedisKey) -> RESPCommand {
        RESPCommand("EXISTS", key)
    }

    /// Determines whether one or more keys exist.
    ///
    /// - Documentation: [EXISTS](https:/redis.io/docs/latest/commands/exists)
    /// - Version: 1.0.0
    /// - Complexity: O(N) where N is the number of keys to check.
    /// - Categories: @keyspace, @read, @fast
    /// - Response: [Integer](https:/redis.io/docs/reference/protocol-spec#integers): the number of keys that exist from those specified as arguments.
    @inlinable
    public static func exists(keys: [RedisKey]) -> RESPCommand {
        RESPCommand("EXISTS", keys)
    }

    public enum EXPIRECondition: RESPRenderable {
        case nx
        case xx
        case gt
        case lt

        @inlinable
        public func writeToRESPBuffer(_ buffer: inout ByteBuffer) -> Int {
            switch self {
            case .nx: "NX".writeToRESPBuffer(&buffer)
            case .xx: "XX".writeToRESPBuffer(&buffer)
            case .gt: "GT".writeToRESPBuffer(&buffer)
            case .lt: "LT".writeToRESPBuffer(&buffer)
            }
        }
    }
    /// Sets the expiration time of a key in seconds.
    ///
    /// - Documentation: [EXPIRE](https:/redis.io/docs/latest/commands/expire)
    /// - Version: 1.0.0
    /// - Complexity: O(1)
    /// - Categories: @keyspace, @write, @fast
    /// - Response: One of the following:
    ///     * [Integer](https:/redis.io/docs/reference/protocol-spec#integers): `0` if the timeout was not set; for example, the key doesn't exist, or the operation was skipped because of the provided arguments.
    ///     * [Integer](https:/redis.io/docs/reference/protocol-spec#integers): `1` if the timeout was set.
    @inlinable
    public static func expire(key: RedisKey, seconds: Int, condition: EXPIRECondition? = nil) -> RESPCommand {
        RESPCommand("EXPIRE", key, seconds, condition)
    }

    public enum EXPIREATCondition: RESPRenderable {
        case nx
        case xx
        case gt
        case lt

        @inlinable
        public func writeToRESPBuffer(_ buffer: inout ByteBuffer) -> Int {
            switch self {
            case .nx: "NX".writeToRESPBuffer(&buffer)
            case .xx: "XX".writeToRESPBuffer(&buffer)
            case .gt: "GT".writeToRESPBuffer(&buffer)
            case .lt: "LT".writeToRESPBuffer(&buffer)
            }
        }
    }
    /// Sets the expiration time of a key to a Unix timestamp.
    ///
    /// - Documentation: [EXPIREAT](https:/redis.io/docs/latest/commands/expireat)
    /// - Version: 1.2.0
    /// - Complexity: O(1)
    /// - Categories: @keyspace, @write, @fast
    /// - Response: One of the following:
    ///     * [Integer](https:/redis.io/docs/reference/protocol-spec#integers): `0` if the timeout was not set; for example, the key doesn't exist, or the operation was skipped because of the provided arguments.
    ///     * [Integer](https:/redis.io/docs/reference/protocol-spec#integers): `1` if the timeout was set.
    @inlinable
    public static func expireat(key: RedisKey, unixTimeSeconds: Date, condition: EXPIREATCondition? = nil) -> RESPCommand {
        RESPCommand("EXPIREAT", key, unixTimeSeconds, condition)
    }

    /// Returns the expiration time of a key as a Unix timestamp.
    ///
    /// - Documentation: [EXPIRETIME](https:/redis.io/docs/latest/commands/expiretime)
    /// - Version: 7.0.0
    /// - Complexity: O(1)
    /// - Categories: @keyspace, @read, @fast
    /// - Response: One of the following:
    ///     * [Integer](https:/redis.io/docs/reference/protocol-spec#integers): the expiration Unix timestamp in seconds.
    ///     * [Integer](https:/redis.io/docs/reference/protocol-spec#integers): `-1` if the key exists but has no associated expiration time.
    ///     * [Integer](https:/redis.io/docs/reference/protocol-spec#integers): `-2` if the key does not exist.
    @inlinable
    public static func expiretime(key: RedisKey) -> RESPCommand {
        RESPCommand("EXPIRETIME", key)
    }

    public struct FAILOVERTarget: RESPRenderable {
        @usableFromInline let host: String
        @usableFromInline let port: Int
        @usableFromInline let force: Bool

        @inlinable
        public func writeToRESPBuffer(_ buffer: inout ByteBuffer) -> Int {
            var count = 0
            count += self.host.writeToRESPBuffer(&buffer)
            count += self.port.writeToRESPBuffer(&buffer)
            if self.force { count += "FORCE".writeToRESPBuffer(&buffer) }
            return count
        }
    }
    /// Starts a coordinated failover from a server to one of its replicas.
    ///
    /// - Documentation: [FAILOVER](https:/redis.io/docs/latest/commands/failover)
    /// - Version: 6.2.0
    /// - Complexity: O(1)
    /// - Categories: @admin, @slow, @dangerous
    /// - Response: [Simple string](https:/redis.io/docs/reference/protocol-spec#simple-strings): `OK` if the command was accepted and a coordinated failover is in progress. An error if the operation cannot be executed.
    @inlinable
    public static func failover(target: FAILOVERTarget? = nil, abort: Bool = false, milliseconds: Int? = nil) -> RESPCommand {
        RESPCommand("FAILOVER", RESPWithToken("TO", target), RedisPureToken("ABORT", abort), RESPWithToken("TIMEOUT", milliseconds))
    }

    /// Invokes a function.
    ///
    /// - Documentation: [FCALL](https:/redis.io/docs/latest/commands/fcall)
    /// - Version: 7.0.0
    /// - Complexity: Depends on the function that is executed.
    /// - Categories: @slow, @scripting
    /// - Response: The return value depends on the function that was executed.
    @inlinable
    public static func fcall(function: String, key: RedisKey? = nil, arg: String? = nil) -> RESPCommand {
        RESPCommand("FCALL", function, 1, key, arg)
    }

    /// Invokes a function.
    ///
    /// - Documentation: [FCALL](https:/redis.io/docs/latest/commands/fcall)
    /// - Version: 7.0.0
    /// - Complexity: Depends on the function that is executed.
    /// - Categories: @slow, @scripting
    /// - Response: The return value depends on the function that was executed.
    @inlinable
    public static func fcall(function: String, keys: [RedisKey], args: [String]) -> RESPCommand {
        RESPCommand("FCALL", function, RESPArrayWithCount(keys), args)
    }

    /// Invokes a read-only function.
    ///
    /// - Documentation: [FCALL_RO](https:/redis.io/docs/latest/commands/fcall_ro)
    /// - Version: 7.0.0
    /// - Complexity: Depends on the function that is executed.
    /// - Categories: @slow, @scripting
    /// - Response: The return value depends on the function that was executed.
    @inlinable
    public static func fcallRo(function: String, key: RedisKey? = nil, arg: String? = nil) -> RESPCommand {
        RESPCommand("FCALL_RO", function, 1, key, arg)
    }

    /// Invokes a read-only function.
    ///
    /// - Documentation: [FCALL_RO](https:/redis.io/docs/latest/commands/fcall_ro)
    /// - Version: 7.0.0
    /// - Complexity: Depends on the function that is executed.
    /// - Categories: @slow, @scripting
    /// - Response: The return value depends on the function that was executed.
    @inlinable
    public static func fcallRo(function: String, keys: [RedisKey], args: [String]) -> RESPCommand {
        RESPCommand("FCALL_RO", function, RESPArrayWithCount(keys), args)
    }

    public enum FLUSHALLFlushType: RESPRenderable {
        case async
        case sync

        @inlinable
        public func writeToRESPBuffer(_ buffer: inout ByteBuffer) -> Int {
            switch self {
            case .async: "ASYNC".writeToRESPBuffer(&buffer)
            case .sync: "SYNC".writeToRESPBuffer(&buffer)
            }
        }
    }
    /// Removes all keys from all databases.
    ///
    /// - Documentation: [FLUSHALL](https:/redis.io/docs/latest/commands/flushall)
    /// - Version: 1.0.0
    /// - Complexity: O(N) where N is the total number of keys in all databases
    /// - Categories: @keyspace, @write, @slow, @dangerous
    /// - Response: [Simple string](https:/redis.io/docs/reference/protocol-spec#simple-strings): `OK`.
    @inlinable
    public static func flushall(flushType: FLUSHALLFlushType? = nil) -> RESPCommand {
        RESPCommand("FLUSHALL", flushType)
    }

    public enum FLUSHDBFlushType: RESPRenderable {
        case async
        case sync

        @inlinable
        public func writeToRESPBuffer(_ buffer: inout ByteBuffer) -> Int {
            switch self {
            case .async: "ASYNC".writeToRESPBuffer(&buffer)
            case .sync: "SYNC".writeToRESPBuffer(&buffer)
            }
        }
    }
    /// Remove all keys from the current database.
    ///
    /// - Documentation: [FLUSHDB](https:/redis.io/docs/latest/commands/flushdb)
    /// - Version: 1.0.0
    /// - Complexity: O(N) where N is the number of keys in the selected database
    /// - Categories: @keyspace, @write, @slow, @dangerous
    /// - Response: [Simple string](https:/redis.io/docs/reference/protocol-spec#simple-strings): `OK`.
    @inlinable
    public static func flushdb(flushType: FLUSHDBFlushType? = nil) -> RESPCommand {
        RESPCommand("FLUSHDB", flushType)
    }

    /// Deletes a library and its functions.
    ///
    /// - Documentation: [FUNCTION DELETE](https:/redis.io/docs/latest/commands/function-delete)
    /// - Version: 7.0.0
    /// - Complexity: O(1)
    /// - Categories: @write, @slow, @scripting
    /// - Response: [Simple string](https:/redis.io/docs/reference/protocol-spec#simple-strings): `OK`.
    @inlinable
    public static func functionDelete(libraryName: String) -> RESPCommand {
        RESPCommand("FUNCTION", "DELETE", libraryName)
    }

    /// Dumps all libraries into a serialized binary payload.
    ///
    /// - Documentation: [FUNCTION DUMP](https:/redis.io/docs/latest/commands/function-dump)
    /// - Version: 7.0.0
    /// - Complexity: O(N) where N is the number of functions
    /// - Categories: @slow, @scripting
    /// - Response: [Bulk string](https:/redis.io/docs/reference/protocol-spec#bulk-strings): the serialized payload
    @inlinable
    public static func functionDump() -> RESPCommand {
        RESPCommand("FUNCTION", "DUMP")
    }

    public enum FUNCTIONFLUSHFlushType: RESPRenderable {
        case async
        case sync

        @inlinable
        public func writeToRESPBuffer(_ buffer: inout ByteBuffer) -> Int {
            switch self {
            case .async: "ASYNC".writeToRESPBuffer(&buffer)
            case .sync: "SYNC".writeToRESPBuffer(&buffer)
            }
        }
    }
    /// Deletes all libraries and functions.
    ///
    /// - Documentation: [FUNCTION FLUSH](https:/redis.io/docs/latest/commands/function-flush)
    /// - Version: 7.0.0
    /// - Complexity: O(N) where N is the number of functions deleted
    /// - Categories: @write, @slow, @scripting
    /// - Response: [Simple string](https:/redis.io/docs/reference/protocol-spec#simple-strings): `OK`.
    @inlinable
    public static func functionFlush(flushType: FUNCTIONFLUSHFlushType? = nil) -> RESPCommand {
        RESPCommand("FUNCTION", "FLUSH", flushType)
    }

    /// Returns helpful text about the different subcommands.
    ///
    /// - Documentation: [FUNCTION HELP](https:/redis.io/docs/latest/commands/function-help)
    /// - Version: 7.0.0
    /// - Complexity: O(1)
    /// - Categories: @slow, @scripting
    /// - Response: [Array](https:/redis.io/docs/reference/protocol-spec#arrays): a list of sub-commands and their descriptions.
    @inlinable
    public static func functionHelp() -> RESPCommand {
        RESPCommand("FUNCTION", "HELP")
    }

    /// Terminates a function during execution.
    ///
    /// - Documentation: [FUNCTION KILL](https:/redis.io/docs/latest/commands/function-kill)
    /// - Version: 7.0.0
    /// - Complexity: O(1)
    /// - Categories: @slow, @scripting
    /// - Response: [Simple string](https:/redis.io/docs/reference/protocol-spec#simple-strings): `OK`.
    @inlinable
    public static func functionKill() -> RESPCommand {
        RESPCommand("FUNCTION", "KILL")
    }

    /// Returns information about all libraries.
    ///
    /// - Documentation: [FUNCTION LIST](https:/redis.io/docs/latest/commands/function-list)
    /// - Version: 7.0.0
    /// - Complexity: O(N) where N is the number of functions
    /// - Categories: @slow, @scripting
    /// - Response: [Array](https:/redis.io/docs/reference/protocol-spec#arrays): information about functions and libraries.
    @inlinable
    public static func functionList(libraryNamePattern: String? = nil, withcode: Bool = false) -> RESPCommand {
        RESPCommand("FUNCTION", "LIST", RESPWithToken("LIBRARYNAME", libraryNamePattern), RedisPureToken("WITHCODE", withcode))
    }

    /// Creates a library.
    ///
    /// - Documentation: [FUNCTION LOAD](https:/redis.io/docs/latest/commands/function-load)
    /// - Version: 7.0.0
    /// - Complexity: O(1) (considering compilation time is redundant)
    /// - Categories: @write, @slow, @scripting
    /// - Response: [Bulk string](https:/redis.io/docs/reference/protocol-spec#bulk-strings): the library name that was loaded.
    @inlinable
    public static func functionLoad(replace: Bool = false, functionCode: String) -> RESPCommand {
        RESPCommand("FUNCTION", "LOAD", RedisPureToken("REPLACE", replace), functionCode)
    }

    public enum FUNCTIONRESTOREPolicy: RESPRenderable {
        case flush
        case append
        case replace

        @inlinable
        public func writeToRESPBuffer(_ buffer: inout ByteBuffer) -> Int {
            switch self {
            case .flush: "FLUSH".writeToRESPBuffer(&buffer)
            case .append: "APPEND".writeToRESPBuffer(&buffer)
            case .replace: "REPLACE".writeToRESPBuffer(&buffer)
            }
        }
    }
    /// Restores all libraries from a payload.
    ///
    /// - Documentation: [FUNCTION RESTORE](https:/redis.io/docs/latest/commands/function-restore)
    /// - Version: 7.0.0
    /// - Complexity: O(N) where N is the number of functions on the payload
    /// - Categories: @write, @slow, @scripting
    /// - Response: [Simple string](https:/redis.io/docs/reference/protocol-spec#simple-strings): `OK`.
    @inlinable
    public static func functionRestore(serializedValue: String, policy: FUNCTIONRESTOREPolicy? = nil) -> RESPCommand {
        RESPCommand("FUNCTION", "RESTORE", serializedValue, policy)
    }

    /// Returns information about a function during execution.
    ///
    /// - Documentation: [FUNCTION STATS](https:/redis.io/docs/latest/commands/function-stats)
    /// - Version: 7.0.0
    /// - Complexity: O(1)
    /// - Categories: @slow, @scripting
    /// - Response: [Map](https:/redis.io/docs/reference/protocol-spec#maps): information about the function that's currently running and information about the available execution engines.
    @inlinable
    public static func functionStats() -> RESPCommand {
        RESPCommand("FUNCTION", "STATS")
    }

    public enum GEOADDCondition: RESPRenderable {
        case nx
        case xx

        @inlinable
        public func writeToRESPBuffer(_ buffer: inout ByteBuffer) -> Int {
            switch self {
            case .nx: "NX".writeToRESPBuffer(&buffer)
            case .xx: "XX".writeToRESPBuffer(&buffer)
            }
        }
    }
    public struct GEOADDData: RESPRenderable {
        @usableFromInline let longitude: Double
        @usableFromInline let latitude: Double
        @usableFromInline let member: String

        @inlinable
        public func writeToRESPBuffer(_ buffer: inout ByteBuffer) -> Int {
            var count = 0
            count += self.longitude.writeToRESPBuffer(&buffer)
            count += self.latitude.writeToRESPBuffer(&buffer)
            count += self.member.writeToRESPBuffer(&buffer)
            return count
        }
    }
    /// Adds one or more members to a geospatial index. The key is created if it doesn't exist.
    ///
    /// - Documentation: [GEOADD](https:/redis.io/docs/latest/commands/geoadd)
    /// - Version: 3.2.0
    /// - Complexity: O(log(N)) for each item added, where N is the number of elements in the sorted set.
    /// - Categories: @write, @geo, @slow
    /// - Response: [Integer](https:/redis.io/docs/reference/protocol-spec#integers): When used without optional arguments, the number of elements added to the sorted set (excluding score updates).  If the CH option is specified, the number of elements that were changed (added or updated).
    @inlinable
    public static func geoadd(key: RedisKey, condition: GEOADDCondition? = nil, change: Bool = false, data: GEOADDData) -> RESPCommand {
        RESPCommand("GEOADD", key, condition, RedisPureToken("CH", change), data)
    }

    /// Adds one or more members to a geospatial index. The key is created if it doesn't exist.
    ///
    /// - Documentation: [GEOADD](https:/redis.io/docs/latest/commands/geoadd)
    /// - Version: 3.2.0
    /// - Complexity: O(log(N)) for each item added, where N is the number of elements in the sorted set.
    /// - Categories: @write, @geo, @slow
    /// - Response: [Integer](https:/redis.io/docs/reference/protocol-spec#integers): When used without optional arguments, the number of elements added to the sorted set (excluding score updates).  If the CH option is specified, the number of elements that were changed (added or updated).
    @inlinable
    public static func geoadd(key: RedisKey, condition: GEOADDCondition? = nil, change: Bool = false, datas: [GEOADDData]) -> RESPCommand {
        RESPCommand("GEOADD", key, condition, RedisPureToken("CH", change), datas)
    }

    public enum GEODISTUnit: RESPRenderable {
        case m
        case km
        case ft
        case mi

        @inlinable
        public func writeToRESPBuffer(_ buffer: inout ByteBuffer) -> Int {
            switch self {
            case .m: "M".writeToRESPBuffer(&buffer)
            case .km: "KM".writeToRESPBuffer(&buffer)
            case .ft: "FT".writeToRESPBuffer(&buffer)
            case .mi: "MI".writeToRESPBuffer(&buffer)
            }
        }
    }
    /// Returns the distance between two members of a geospatial index.
    ///
    /// - Documentation: [GEODIST](https:/redis.io/docs/latest/commands/geodist)
    /// - Version: 3.2.0
    /// - Complexity: O(1)
    /// - Categories: @read, @geo, @slow
    /// - Response: One of the following:
    ///     * [Null](https:/redis.io/docs/reference/protocol-spec#nulls): one or both of the elements are missing.
    ///     * [Bulk string](https:/redis.io/docs/reference/protocol-spec#bulk-strings): distance as a double (represented as a string) in the specified units.
    @inlinable
    public static func geodist(key: RedisKey, member1: String, member2: String, unit: GEODISTUnit? = nil) -> RESPCommand {
        RESPCommand("GEODIST", key, member1, member2, unit)
    }

    /// Returns members from a geospatial index as geohash strings.
    ///
    /// - Documentation: [GEOHASH](https:/redis.io/docs/latest/commands/geohash)
    /// - Version: 3.2.0
    /// - Complexity: O(1) for each member requested.
    /// - Categories: @read, @geo, @slow
    /// - Response: [Array](https:/redis.io/docs/reference/protocol-spec#arrays): An array where each element is the Geohash corresponding to each member name passed as an argument to the command.
    @inlinable
    public static func geohash(key: RedisKey, member: String? = nil) -> RESPCommand {
        RESPCommand("GEOHASH", key, member)
    }

    /// Returns members from a geospatial index as geohash strings.
    ///
    /// - Documentation: [GEOHASH](https:/redis.io/docs/latest/commands/geohash)
    /// - Version: 3.2.0
    /// - Complexity: O(1) for each member requested.
    /// - Categories: @read, @geo, @slow
    /// - Response: [Array](https:/redis.io/docs/reference/protocol-spec#arrays): An array where each element is the Geohash corresponding to each member name passed as an argument to the command.
    @inlinable
    public static func geohash(key: RedisKey, members: [String]) -> RESPCommand {
        RESPCommand("GEOHASH", key, members)
    }

    /// Returns the longitude and latitude of members from a geospatial index.
    ///
    /// - Documentation: [GEOPOS](https:/redis.io/docs/latest/commands/geopos)
    /// - Version: 3.2.0
    /// - Complexity: O(1) for each member requested.
    /// - Categories: @read, @geo, @slow
    /// - Response: [Array](https:/redis.io/docs/reference/protocol-spec#arrays): An array where each element is a two elements array representing longitude and latitude (x,y) of each member name passed as argument to the command. Non-existing elements are reported as [Null](https:/redis.io/docs/reference/protocol-spec#nulls) elements of the array.
    @inlinable
    public static func geopos(key: RedisKey, member: String? = nil) -> RESPCommand {
        RESPCommand("GEOPOS", key, member)
    }

    /// Returns the longitude and latitude of members from a geospatial index.
    ///
    /// - Documentation: [GEOPOS](https:/redis.io/docs/latest/commands/geopos)
    /// - Version: 3.2.0
    /// - Complexity: O(1) for each member requested.
    /// - Categories: @read, @geo, @slow
    /// - Response: [Array](https:/redis.io/docs/reference/protocol-spec#arrays): An array where each element is a two elements array representing longitude and latitude (x,y) of each member name passed as argument to the command. Non-existing elements are reported as [Null](https:/redis.io/docs/reference/protocol-spec#nulls) elements of the array.
    @inlinable
    public static func geopos(key: RedisKey, members: [String]) -> RESPCommand {
        RESPCommand("GEOPOS", key, members)
    }

    public enum GEORADIUSUnit: RESPRenderable {
        case m
        case km
        case ft
        case mi

        @inlinable
        public func writeToRESPBuffer(_ buffer: inout ByteBuffer) -> Int {
            switch self {
            case .m: "M".writeToRESPBuffer(&buffer)
            case .km: "KM".writeToRESPBuffer(&buffer)
            case .ft: "FT".writeToRESPBuffer(&buffer)
            case .mi: "MI".writeToRESPBuffer(&buffer)
            }
        }
    }
    public struct GEORADIUSCountBlock: RESPRenderable {
        @usableFromInline let count: Int
        @usableFromInline let any: Bool

        @inlinable
        public func writeToRESPBuffer(_ buffer: inout ByteBuffer) -> Int {
            var count = 0
            count += RESPWithToken("COUNT", count).writeToRESPBuffer(&buffer)
            if self.any { count += "ANY".writeToRESPBuffer(&buffer) }
            return count
        }
    }
    public enum GEORADIUSOrder: RESPRenderable {
        case asc
        case desc

        @inlinable
        public func writeToRESPBuffer(_ buffer: inout ByteBuffer) -> Int {
            switch self {
            case .asc: "ASC".writeToRESPBuffer(&buffer)
            case .desc: "DESC".writeToRESPBuffer(&buffer)
            }
        }
    }
    public enum GEORADIUSStore: RESPRenderable {
        case storekey(RedisKey)
        case storedistkey(RedisKey)

        @inlinable
        public func writeToRESPBuffer(_ buffer: inout ByteBuffer) -> Int {
            switch self {
            case .storekey(let storekey): RESPWithToken("STORE", storekey).writeToRESPBuffer(&buffer)
            case .storedistkey(let storedistkey): RESPWithToken("STOREDIST", storedistkey).writeToRESPBuffer(&buffer)
            }
        }
    }
    /// Queries a geospatial index for members within a distance from a coordinate, optionally stores the result.
    ///
    /// - Documentation: [GEORADIUS](https:/redis.io/docs/latest/commands/georadius)
    /// - Version: 3.2.0
    /// - Complexity: O(N+log(M)) where N is the number of elements inside the bounding box of the circular area delimited by center and radius and M is the number of items inside the index.
    /// - Categories: @write, @geo, @slow
    /// - Response: One of the following:
    ///     * If no `WITH*` option is specified, an [Array](https:/redis.io/docs/reference/protocol-spec#arrays) of matched member names
    ///     * If `WITHCOORD`, `WITHDIST`, or `WITHHASH` options are specified, the command returns an [Array](https:/redis.io/docs/reference/protocol-spec#arrays) of arrays, where each sub-array represents a single item:
    ///         1. The distance from the center as a floating point number, in the same unit specified in the radius.
    ///         1. The Geohash integer.
    ///         1. The coordinates as a two items x,y array (longitude,latitude).
    ///     
    ///     For example, the command `GEORADIUS Sicily 15 37 200 km WITHCOORD WITHDIST` will return each item in the following way:
    ///     
    ///     `["Palermo","190.4424",["13.361389338970184","38.115556395496299"]]`
    @inlinable
    public static func georadius(key: RedisKey, longitude: Double, latitude: Double, radius: Double, unit: GEORADIUSUnit, withcoord: Bool = false, withdist: Bool = false, withhash: Bool = false, countBlock: GEORADIUSCountBlock? = nil, order: GEORADIUSOrder? = nil, store: GEORADIUSStore? = nil) -> RESPCommand {
        RESPCommand("GEORADIUS", key, longitude, latitude, radius, unit, RedisPureToken("WITHCOORD", withcoord), RedisPureToken("WITHDIST", withdist), RedisPureToken("WITHHASH", withhash), countBlock, order, store)
    }

    public enum GEORADIUSBYMEMBERUnit: RESPRenderable {
        case m
        case km
        case ft
        case mi

        @inlinable
        public func writeToRESPBuffer(_ buffer: inout ByteBuffer) -> Int {
            switch self {
            case .m: "M".writeToRESPBuffer(&buffer)
            case .km: "KM".writeToRESPBuffer(&buffer)
            case .ft: "FT".writeToRESPBuffer(&buffer)
            case .mi: "MI".writeToRESPBuffer(&buffer)
            }
        }
    }
    public struct GEORADIUSBYMEMBERCountBlock: RESPRenderable {
        @usableFromInline let count: Int
        @usableFromInline let any: Bool

        @inlinable
        public func writeToRESPBuffer(_ buffer: inout ByteBuffer) -> Int {
            var count = 0
            count += RESPWithToken("COUNT", count).writeToRESPBuffer(&buffer)
            if self.any { count += "ANY".writeToRESPBuffer(&buffer) }
            return count
        }
    }
    public enum GEORADIUSBYMEMBEROrder: RESPRenderable {
        case asc
        case desc

        @inlinable
        public func writeToRESPBuffer(_ buffer: inout ByteBuffer) -> Int {
            switch self {
            case .asc: "ASC".writeToRESPBuffer(&buffer)
            case .desc: "DESC".writeToRESPBuffer(&buffer)
            }
        }
    }
    public enum GEORADIUSBYMEMBERStore: RESPRenderable {
        case storekey(RedisKey)
        case storedistkey(RedisKey)

        @inlinable
        public func writeToRESPBuffer(_ buffer: inout ByteBuffer) -> Int {
            switch self {
            case .storekey(let storekey): RESPWithToken("STORE", storekey).writeToRESPBuffer(&buffer)
            case .storedistkey(let storedistkey): RESPWithToken("STOREDIST", storedistkey).writeToRESPBuffer(&buffer)
            }
        }
    }
    /// Queries a geospatial index for members within a distance from a member, optionally stores the result.
    ///
    /// - Documentation: [GEORADIUSBYMEMBER](https:/redis.io/docs/latest/commands/georadiusbymember)
    /// - Version: 3.2.0
    /// - Complexity: O(N+log(M)) where N is the number of elements inside the bounding box of the circular area delimited by center and radius and M is the number of items inside the index.
    /// - Categories: @write, @geo, @slow
    /// - Response: One of the following:
    ///     * If no `WITH*` option is specified, an [Array](https:/redis.io/docs/reference/protocol-spec#arrays) of matched member names
    ///     * If `WITHCOORD`, `WITHDIST`, or `WITHHASH` options are specified, the command returns an [Array](https:/redis.io/docs/reference/protocol-spec#arrays) of arrays, where each sub-array represents a single item:
    ///         * The distance from the center as a floating point number, in the same unit specified in the radius.
    ///         * The Geohash integer.
    ///         * The coordinates as a two items x,y array (longitude,latitude).
    @inlinable
    public static func georadiusbymember(key: RedisKey, member: String, radius: Double, unit: GEORADIUSBYMEMBERUnit, withcoord: Bool = false, withdist: Bool = false, withhash: Bool = false, countBlock: GEORADIUSBYMEMBERCountBlock? = nil, order: GEORADIUSBYMEMBEROrder? = nil, store: GEORADIUSBYMEMBERStore? = nil) -> RESPCommand {
        RESPCommand("GEORADIUSBYMEMBER", key, member, radius, unit, RedisPureToken("WITHCOORD", withcoord), RedisPureToken("WITHDIST", withdist), RedisPureToken("WITHHASH", withhash), countBlock, order, store)
    }

    public enum GEORADIUSBYMEMBERROUnit: RESPRenderable {
        case m
        case km
        case ft
        case mi

        @inlinable
        public func writeToRESPBuffer(_ buffer: inout ByteBuffer) -> Int {
            switch self {
            case .m: "M".writeToRESPBuffer(&buffer)
            case .km: "KM".writeToRESPBuffer(&buffer)
            case .ft: "FT".writeToRESPBuffer(&buffer)
            case .mi: "MI".writeToRESPBuffer(&buffer)
            }
        }
    }
    public struct GEORADIUSBYMEMBERROCountBlock: RESPRenderable {
        @usableFromInline let count: Int
        @usableFromInline let any: Bool

        @inlinable
        public func writeToRESPBuffer(_ buffer: inout ByteBuffer) -> Int {
            var count = 0
            count += RESPWithToken("COUNT", count).writeToRESPBuffer(&buffer)
            if self.any { count += "ANY".writeToRESPBuffer(&buffer) }
            return count
        }
    }
    public enum GEORADIUSBYMEMBERROOrder: RESPRenderable {
        case asc
        case desc

        @inlinable
        public func writeToRESPBuffer(_ buffer: inout ByteBuffer) -> Int {
            switch self {
            case .asc: "ASC".writeToRESPBuffer(&buffer)
            case .desc: "DESC".writeToRESPBuffer(&buffer)
            }
        }
    }
    /// Returns members from a geospatial index that are within a distance from a member.
    ///
    /// - Documentation: [GEORADIUSBYMEMBER_RO](https:/redis.io/docs/latest/commands/georadiusbymember_ro)
    /// - Version: 3.2.10
    /// - Complexity: O(N+log(M)) where N is the number of elements inside the bounding box of the circular area delimited by center and radius and M is the number of items inside the index.
    /// - Categories: @read, @geo, @slow
    /// - Response: One of the following:
    ///     * If no `WITH*` option is specified, an [Array](https:/redis.io/docs/reference/protocol-spec#arrays) of matched member names
    ///     * If `WITHCOORD`, `WITHDIST`, or `WITHHASH` options are specified, the command returns an [Array](https:/redis.io/docs/reference/protocol-spec#arrays) of arrays, where each sub-array represents a single item:
    ///         * The distance from the center as a floating point number, in the same unit specified in the radius.
    ///         * The Geohash integer.
    ///         * The coordinates as a two items x,y array (longitude,latitude).
    @inlinable
    public static func georadiusbymemberRo(key: RedisKey, member: String, radius: Double, unit: GEORADIUSBYMEMBERROUnit, withcoord: Bool = false, withdist: Bool = false, withhash: Bool = false, countBlock: GEORADIUSBYMEMBERROCountBlock? = nil, order: GEORADIUSBYMEMBERROOrder? = nil) -> RESPCommand {
        RESPCommand("GEORADIUSBYMEMBER_RO", key, member, radius, unit, RedisPureToken("WITHCOORD", withcoord), RedisPureToken("WITHDIST", withdist), RedisPureToken("WITHHASH", withhash), countBlock, order)
    }

    public enum GEORADIUSROUnit: RESPRenderable {
        case m
        case km
        case ft
        case mi

        @inlinable
        public func writeToRESPBuffer(_ buffer: inout ByteBuffer) -> Int {
            switch self {
            case .m: "M".writeToRESPBuffer(&buffer)
            case .km: "KM".writeToRESPBuffer(&buffer)
            case .ft: "FT".writeToRESPBuffer(&buffer)
            case .mi: "MI".writeToRESPBuffer(&buffer)
            }
        }
    }
    public struct GEORADIUSROCountBlock: RESPRenderable {
        @usableFromInline let count: Int
        @usableFromInline let any: Bool

        @inlinable
        public func writeToRESPBuffer(_ buffer: inout ByteBuffer) -> Int {
            var count = 0
            count += RESPWithToken("COUNT", count).writeToRESPBuffer(&buffer)
            if self.any { count += "ANY".writeToRESPBuffer(&buffer) }
            return count
        }
    }
    public enum GEORADIUSROOrder: RESPRenderable {
        case asc
        case desc

        @inlinable
        public func writeToRESPBuffer(_ buffer: inout ByteBuffer) -> Int {
            switch self {
            case .asc: "ASC".writeToRESPBuffer(&buffer)
            case .desc: "DESC".writeToRESPBuffer(&buffer)
            }
        }
    }
    /// Returns members from a geospatial index that are within a distance from a coordinate.
    ///
    /// - Documentation: [GEORADIUS_RO](https:/redis.io/docs/latest/commands/georadius_ro)
    /// - Version: 3.2.10
    /// - Complexity: O(N+log(M)) where N is the number of elements inside the bounding box of the circular area delimited by center and radius and M is the number of items inside the index.
    /// - Categories: @read, @geo, @slow
    /// - Response: One of the following:
    ///     * If no `WITH*` option is specified, an [Array](https:/redis.io/docs/reference/protocol-spec#arrays) of matched member names
    ///     * If `WITHCOORD`, `WITHDIST`, or `WITHHASH` options are specified, the command returns an [Array](https:/redis.io/docs/reference/protocol-spec#arrays) of arrays, where each sub-array represents a single item:
    ///         * The distance from the center as a floating point number, in the same unit specified in the radius.
    ///         * The Geohash integer.
    ///         * The coordinates as a two items x,y array (longitude,latitude).
    @inlinable
    public static func georadiusRo(key: RedisKey, longitude: Double, latitude: Double, radius: Double, unit: GEORADIUSROUnit, withcoord: Bool = false, withdist: Bool = false, withhash: Bool = false, countBlock: GEORADIUSROCountBlock? = nil, order: GEORADIUSROOrder? = nil) -> RESPCommand {
        RESPCommand("GEORADIUS_RO", key, longitude, latitude, radius, unit, RedisPureToken("WITHCOORD", withcoord), RedisPureToken("WITHDIST", withdist), RedisPureToken("WITHHASH", withhash), countBlock, order)
    }

    public struct GEOSEARCHFromFromlonlat: RESPRenderable {
        @usableFromInline let longitude: Double
        @usableFromInline let latitude: Double

        @inlinable
        public func writeToRESPBuffer(_ buffer: inout ByteBuffer) -> Int {
            var count = 0
            count += self.longitude.writeToRESPBuffer(&buffer)
            count += self.latitude.writeToRESPBuffer(&buffer)
            return count
        }
    }
    public enum GEOSEARCHFrom: RESPRenderable {
        case member(String)
        case fromlonlat(GEOSEARCHFromFromlonlat)

        @inlinable
        public func writeToRESPBuffer(_ buffer: inout ByteBuffer) -> Int {
            switch self {
            case .member(let member): RESPWithToken("FROMMEMBER", member).writeToRESPBuffer(&buffer)
            case .fromlonlat(let fromlonlat): RESPWithToken("FROMLONLAT", fromlonlat).writeToRESPBuffer(&buffer)
            }
        }
    }
    public enum GEOSEARCHByCircleUnit: RESPRenderable {
        case m
        case km
        case ft
        case mi

        @inlinable
        public func writeToRESPBuffer(_ buffer: inout ByteBuffer) -> Int {
            switch self {
            case .m: "M".writeToRESPBuffer(&buffer)
            case .km: "KM".writeToRESPBuffer(&buffer)
            case .ft: "FT".writeToRESPBuffer(&buffer)
            case .mi: "MI".writeToRESPBuffer(&buffer)
            }
        }
    }
    public struct GEOSEARCHByCircle: RESPRenderable {
        @usableFromInline let radius: Double
        @usableFromInline let unit: GEOSEARCHByCircleUnit

        @inlinable
        public func writeToRESPBuffer(_ buffer: inout ByteBuffer) -> Int {
            var count = 0
            count += RESPWithToken("BYRADIUS", radius).writeToRESPBuffer(&buffer)
            count += self.unit.writeToRESPBuffer(&buffer)
            return count
        }
    }
    public enum GEOSEARCHByBoxUnit: RESPRenderable {
        case m
        case km
        case ft
        case mi

        @inlinable
        public func writeToRESPBuffer(_ buffer: inout ByteBuffer) -> Int {
            switch self {
            case .m: "M".writeToRESPBuffer(&buffer)
            case .km: "KM".writeToRESPBuffer(&buffer)
            case .ft: "FT".writeToRESPBuffer(&buffer)
            case .mi: "MI".writeToRESPBuffer(&buffer)
            }
        }
    }
    public struct GEOSEARCHByBox: RESPRenderable {
        @usableFromInline let width: Double
        @usableFromInline let height: Double
        @usableFromInline let unit: GEOSEARCHByBoxUnit

        @inlinable
        public func writeToRESPBuffer(_ buffer: inout ByteBuffer) -> Int {
            var count = 0
            count += RESPWithToken("BYBOX", width).writeToRESPBuffer(&buffer)
            count += self.height.writeToRESPBuffer(&buffer)
            count += self.unit.writeToRESPBuffer(&buffer)
            return count
        }
    }
    public enum GEOSEARCHBy: RESPRenderable {
        case circle(GEOSEARCHByCircle)
        case box(GEOSEARCHByBox)

        @inlinable
        public func writeToRESPBuffer(_ buffer: inout ByteBuffer) -> Int {
            switch self {
            case .circle(let circle): circle.writeToRESPBuffer(&buffer)
            case .box(let box): box.writeToRESPBuffer(&buffer)
            }
        }
    }
    public enum GEOSEARCHOrder: RESPRenderable {
        case asc
        case desc

        @inlinable
        public func writeToRESPBuffer(_ buffer: inout ByteBuffer) -> Int {
            switch self {
            case .asc: "ASC".writeToRESPBuffer(&buffer)
            case .desc: "DESC".writeToRESPBuffer(&buffer)
            }
        }
    }
    public struct GEOSEARCHCountBlock: RESPRenderable {
        @usableFromInline let count: Int
        @usableFromInline let any: Bool

        @inlinable
        public func writeToRESPBuffer(_ buffer: inout ByteBuffer) -> Int {
            var count = 0
            count += RESPWithToken("COUNT", count).writeToRESPBuffer(&buffer)
            if self.any { count += "ANY".writeToRESPBuffer(&buffer) }
            return count
        }
    }
    /// Queries a geospatial index for members inside an area of a box or a circle.
    ///
    /// - Documentation: [GEOSEARCH](https:/redis.io/docs/latest/commands/geosearch)
    /// - Version: 6.2.0
    /// - Complexity: O(N+log(M)) where N is the number of elements in the grid-aligned bounding box area around the shape provided as the filter and M is the number of items inside the shape
    /// - Categories: @read, @geo, @slow
    /// - Response: One of the following:
    ///     * If no `WITH*` option is specified, an [Array](https:/redis.io/docs/reference/protocol-spec#arrays) of matched member names
    ///     * If `WITHCOORD`, `WITHDIST`, or `WITHHASH` options are specified, the command returns an [Array](https:/redis.io/docs/reference/protocol-spec#arrays) of arrays, where each sub-array represents a single item:
    ///         * The distance from the center as a floating point number, in the same unit specified in the radius.
    ///         * The Geohash integer.
    ///         * The coordinates as a two items x,y array (longitude,latitude).
    @inlinable
    public static func geosearch(key: RedisKey, from: GEOSEARCHFrom, by: GEOSEARCHBy, order: GEOSEARCHOrder? = nil, countBlock: GEOSEARCHCountBlock? = nil, withcoord: Bool = false, withdist: Bool = false, withhash: Bool = false) -> RESPCommand {
        RESPCommand("GEOSEARCH", key, from, by, order, countBlock, RedisPureToken("WITHCOORD", withcoord), RedisPureToken("WITHDIST", withdist), RedisPureToken("WITHHASH", withhash))
    }

    public struct GEOSEARCHSTOREFromFromlonlat: RESPRenderable {
        @usableFromInline let longitude: Double
        @usableFromInline let latitude: Double

        @inlinable
        public func writeToRESPBuffer(_ buffer: inout ByteBuffer) -> Int {
            var count = 0
            count += self.longitude.writeToRESPBuffer(&buffer)
            count += self.latitude.writeToRESPBuffer(&buffer)
            return count
        }
    }
    public enum GEOSEARCHSTOREFrom: RESPRenderable {
        case member(String)
        case fromlonlat(GEOSEARCHSTOREFromFromlonlat)

        @inlinable
        public func writeToRESPBuffer(_ buffer: inout ByteBuffer) -> Int {
            switch self {
            case .member(let member): RESPWithToken("FROMMEMBER", member).writeToRESPBuffer(&buffer)
            case .fromlonlat(let fromlonlat): RESPWithToken("FROMLONLAT", fromlonlat).writeToRESPBuffer(&buffer)
            }
        }
    }
    public enum GEOSEARCHSTOREByCircleUnit: RESPRenderable {
        case m
        case km
        case ft
        case mi

        @inlinable
        public func writeToRESPBuffer(_ buffer: inout ByteBuffer) -> Int {
            switch self {
            case .m: "M".writeToRESPBuffer(&buffer)
            case .km: "KM".writeToRESPBuffer(&buffer)
            case .ft: "FT".writeToRESPBuffer(&buffer)
            case .mi: "MI".writeToRESPBuffer(&buffer)
            }
        }
    }
    public struct GEOSEARCHSTOREByCircle: RESPRenderable {
        @usableFromInline let radius: Double
        @usableFromInline let unit: GEOSEARCHSTOREByCircleUnit

        @inlinable
        public func writeToRESPBuffer(_ buffer: inout ByteBuffer) -> Int {
            var count = 0
            count += RESPWithToken("BYRADIUS", radius).writeToRESPBuffer(&buffer)
            count += self.unit.writeToRESPBuffer(&buffer)
            return count
        }
    }
    public enum GEOSEARCHSTOREByBoxUnit: RESPRenderable {
        case m
        case km
        case ft
        case mi

        @inlinable
        public func writeToRESPBuffer(_ buffer: inout ByteBuffer) -> Int {
            switch self {
            case .m: "M".writeToRESPBuffer(&buffer)
            case .km: "KM".writeToRESPBuffer(&buffer)
            case .ft: "FT".writeToRESPBuffer(&buffer)
            case .mi: "MI".writeToRESPBuffer(&buffer)
            }
        }
    }
    public struct GEOSEARCHSTOREByBox: RESPRenderable {
        @usableFromInline let width: Double
        @usableFromInline let height: Double
        @usableFromInline let unit: GEOSEARCHSTOREByBoxUnit

        @inlinable
        public func writeToRESPBuffer(_ buffer: inout ByteBuffer) -> Int {
            var count = 0
            count += RESPWithToken("BYBOX", width).writeToRESPBuffer(&buffer)
            count += self.height.writeToRESPBuffer(&buffer)
            count += self.unit.writeToRESPBuffer(&buffer)
            return count
        }
    }
    public enum GEOSEARCHSTOREBy: RESPRenderable {
        case circle(GEOSEARCHSTOREByCircle)
        case box(GEOSEARCHSTOREByBox)

        @inlinable
        public func writeToRESPBuffer(_ buffer: inout ByteBuffer) -> Int {
            switch self {
            case .circle(let circle): circle.writeToRESPBuffer(&buffer)
            case .box(let box): box.writeToRESPBuffer(&buffer)
            }
        }
    }
    public enum GEOSEARCHSTOREOrder: RESPRenderable {
        case asc
        case desc

        @inlinable
        public func writeToRESPBuffer(_ buffer: inout ByteBuffer) -> Int {
            switch self {
            case .asc: "ASC".writeToRESPBuffer(&buffer)
            case .desc: "DESC".writeToRESPBuffer(&buffer)
            }
        }
    }
    public struct GEOSEARCHSTORECountBlock: RESPRenderable {
        @usableFromInline let count: Int
        @usableFromInline let any: Bool

        @inlinable
        public func writeToRESPBuffer(_ buffer: inout ByteBuffer) -> Int {
            var count = 0
            count += RESPWithToken("COUNT", count).writeToRESPBuffer(&buffer)
            if self.any { count += "ANY".writeToRESPBuffer(&buffer) }
            return count
        }
    }
    /// Queries a geospatial index for members inside an area of a box or a circle, optionally stores the result.
    ///
    /// - Documentation: [GEOSEARCHSTORE](https:/redis.io/docs/latest/commands/geosearchstore)
    /// - Version: 6.2.0
    /// - Complexity: O(N+log(M)) where N is the number of elements in the grid-aligned bounding box area around the shape provided as the filter and M is the number of items inside the shape
    /// - Categories: @write, @geo, @slow
    /// - Response: [Integer](https:/redis.io/docs/reference/protocol-spec#integers): the number of elements in the resulting set
    @inlinable
    public static func geosearchstore(destination: RedisKey, source: RedisKey, from: GEOSEARCHSTOREFrom, by: GEOSEARCHSTOREBy, order: GEOSEARCHSTOREOrder? = nil, countBlock: GEOSEARCHSTORECountBlock? = nil, storedist: Bool = false) -> RESPCommand {
        RESPCommand("GEOSEARCHSTORE", destination, source, from, by, order, countBlock, RedisPureToken("STOREDIST", storedist))
    }

    /// Returns the string value of a key.
    ///
    /// - Documentation: [GET](https:/redis.io/docs/latest/commands/get)
    /// - Version: 1.0.0
    /// - Complexity: O(1)
    /// - Categories: @read, @string, @fast
    /// - Response: One of the following:
    ///     * [Bulk string](https:/redis.io/docs/reference/protocol-spec#bulk-strings): the value of the key.
    ///     * [Null](https:/redis.io/docs/reference/protocol-spec#nulls): key does not exist.
    @inlinable
    public static func get(key: RedisKey) -> RESPCommand {
        RESPCommand("GET", key)
    }

    /// Returns a bit value by offset.
    ///
    /// - Documentation: [GETBIT](https:/redis.io/docs/latest/commands/getbit)
    /// - Version: 2.2.0
    /// - Complexity: O(1)
    /// - Categories: @read, @bitmap, @fast
    /// - Response: The bit value stored at _offset_, one of the following:
    ///     * [Integer](https:/redis.io/docs/reference/protocol-spec#integers): `0`.
    ///     * [Integer](https:/redis.io/docs/reference/protocol-spec#integers): `1`.
    @inlinable
    public static func getbit(key: RedisKey, offset: Int) -> RESPCommand {
        RESPCommand("GETBIT", key, offset)
    }

    /// Returns the string value of a key after deleting the key.
    ///
    /// - Documentation: [GETDEL](https:/redis.io/docs/latest/commands/getdel)
    /// - Version: 6.2.0
    /// - Complexity: O(1)
    /// - Categories: @write, @string, @fast
    /// - Response: One of the following:
    ///     * [Bulk string](https:/redis.io/docs/reference/protocol-spec#bulk-strings): the value of the key.
    ///     * [Null](https:/redis.io/docs/reference/protocol-spec#nulls): if the key does not exist or if the key's value type is not a string.
    @inlinable
    public static func getdel(key: RedisKey) -> RESPCommand {
        RESPCommand("GETDEL", key)
    }

    public enum GETEXExpiration: RESPRenderable {
        case seconds(Int)
        case milliseconds(Int)
        case unixTimeSeconds(Date)
        case unixTimeMilliseconds(Date)
        case persist

        @inlinable
        public func writeToRESPBuffer(_ buffer: inout ByteBuffer) -> Int {
            switch self {
            case .seconds(let seconds): RESPWithToken("EX", seconds).writeToRESPBuffer(&buffer)
            case .milliseconds(let milliseconds): RESPWithToken("PX", milliseconds).writeToRESPBuffer(&buffer)
            case .unixTimeSeconds(let unixTimeSeconds): RESPWithToken("EXAT", unixTimeSeconds).writeToRESPBuffer(&buffer)
            case .unixTimeMilliseconds(let unixTimeMilliseconds): RESPWithToken("PXAT", unixTimeMilliseconds).writeToRESPBuffer(&buffer)
            case .persist: "PERSIST".writeToRESPBuffer(&buffer)
            }
        }
    }
    /// Returns the string value of a key after setting its expiration time.
    ///
    /// - Documentation: [GETEX](https:/redis.io/docs/latest/commands/getex)
    /// - Version: 6.2.0
    /// - Complexity: O(1)
    /// - Categories: @write, @string, @fast
    /// - Response: [Bulk string](https:/redis.io/docs/reference/protocol-spec#bulk-strings): the value of `key`
    ///     [Null](https:/redis.io/docs/reference/protocol-spec#nulls): if `key` does not exist.
    @inlinable
    public static func getex(key: RedisKey, expiration: GETEXExpiration? = nil) -> RESPCommand {
        RESPCommand("GETEX", key, expiration)
    }

    /// Returns a substring of the string stored at a key.
    ///
    /// - Documentation: [GETRANGE](https:/redis.io/docs/latest/commands/getrange)
    /// - Version: 2.4.0
    /// - Complexity: O(N) where N is the length of the returned string. The complexity is ultimately determined by the returned length, but because creating a substring from an existing string is very cheap, it can be considered O(1) for small strings.
    /// - Categories: @read, @string, @slow
    /// - Response: [Bulk string](https:/redis.io/docs/reference/protocol-spec#bulk-strings): The substring of the string value stored at key, determined by the offsets start and end (both are inclusive).
    @inlinable
    public static func getrange(key: RedisKey, start: Int, end: Int) -> RESPCommand {
        RESPCommand("GETRANGE", key, start, end)
    }

    /// Returns the previous string value of a key after setting it to a new value.
    ///
    /// - Documentation: [GETSET](https:/redis.io/docs/latest/commands/getset)
    /// - Version: 1.0.0
    /// - Complexity: O(1)
    /// - Categories: @write, @string, @fast
    /// - Response: One of the following:
    ///     * [Bulk string](https:/redis.io/docs/reference/protocol-spec#bulk-strings): the old value stored at the key.
    ///     * [Null](https:/redis.io/docs/reference/protocol-spec#nulls): if the key does not exist.
    @inlinable
    public static func getset(key: RedisKey, value: String) -> RESPCommand {
        RESPCommand("GETSET", key, value)
    }

    /// Deletes one or more fields and their values from a hash. Deletes the hash if no fields remain.
    ///
    /// - Documentation: [HDEL](https:/redis.io/docs/latest/commands/hdel)
    /// - Version: 2.0.0
    /// - Complexity: O(N) where N is the number of fields to be removed.
    /// - Categories: @write, @hash, @fast
    /// - Response: [Integer](https:/redis.io/docs/reference/protocol-spec#integers): The number of fields that were removed from the hash, excluding any specified but non-existing fields.
    @inlinable
    public static func hdel(key: RedisKey, field: String) -> RESPCommand {
        RESPCommand("HDEL", key, field)
    }

    /// Deletes one or more fields and their values from a hash. Deletes the hash if no fields remain.
    ///
    /// - Documentation: [HDEL](https:/redis.io/docs/latest/commands/hdel)
    /// - Version: 2.0.0
    /// - Complexity: O(N) where N is the number of fields to be removed.
    /// - Categories: @write, @hash, @fast
    /// - Response: [Integer](https:/redis.io/docs/reference/protocol-spec#integers): The number of fields that were removed from the hash, excluding any specified but non-existing fields.
    @inlinable
    public static func hdel(key: RedisKey, fields: [String]) -> RESPCommand {
        RESPCommand("HDEL", key, fields)
    }

    public struct HELLOArgumentsAuth: RESPRenderable {
        @usableFromInline let username: String
        @usableFromInline let password: String

        @inlinable
        public func writeToRESPBuffer(_ buffer: inout ByteBuffer) -> Int {
            var count = 0
            count += self.username.writeToRESPBuffer(&buffer)
            count += self.password.writeToRESPBuffer(&buffer)
            return count
        }
    }
    public struct HELLOArguments: RESPRenderable {
        @usableFromInline let protover: Int
        @usableFromInline let auth: HELLOArgumentsAuth?
        @usableFromInline let clientname: String?

        @inlinable
        public func writeToRESPBuffer(_ buffer: inout ByteBuffer) -> Int {
            var count = 0
            count += self.protover.writeToRESPBuffer(&buffer)
            count += RESPWithToken("AUTH", auth).writeToRESPBuffer(&buffer)
            count += RESPWithToken("SETNAME", clientname).writeToRESPBuffer(&buffer)
            return count
        }
    }
    /// Handshakes with the Redis server.
    ///
    /// - Documentation: [HELLO](https:/redis.io/docs/latest/commands/hello)
    /// - Version: 6.0.0
    /// - Complexity: O(1)
    /// - Categories: @fast, @connection
    /// - Response: [Map](https:/redis.io/docs/reference/protocol-spec#maps): a list of server properties.
    ///     [Simple error](https:/redis.io/docs/reference/protocol-spec#simple-errors): if the `protover` requested does not exist.
    @inlinable
    public static func hello(arguments: HELLOArguments? = nil) -> RESPCommand {
        RESPCommand("HELLO", arguments)
    }

    /// Determines whether a field exists in a hash.
    ///
    /// - Documentation: [HEXISTS](https:/redis.io/docs/latest/commands/hexists)
    /// - Version: 2.0.0
    /// - Complexity: O(1)
    /// - Categories: @read, @hash, @fast
    /// - Response: One of the following:
    ///     * [Integer](https:/redis.io/docs/reference/protocol-spec#integers): `0` if the hash does not contain the field, or the key does not exist.
    ///     * [Integer](https:/redis.io/docs/reference/protocol-spec#integers): `1` if the hash contains the field.
    @inlinable
    public static func hexists(key: RedisKey, field: String) -> RESPCommand {
        RESPCommand("HEXISTS", key, field)
    }

    /// Returns the value of a field in a hash.
    ///
    /// - Documentation: [HGET](https:/redis.io/docs/latest/commands/hget)
    /// - Version: 2.0.0
    /// - Complexity: O(1)
    /// - Categories: @read, @hash, @fast
    /// - Response: One of the following:
    ///     * [Bulk string](https:/redis.io/docs/reference/protocol-spec#bulk-strings): The value associated with the field.
    ///     * [Null](https:/redis.io/docs/reference/protocol-spec#nulls): If the field is not present in the hash or key does not exist.
    @inlinable
    public static func hget(key: RedisKey, field: String) -> RESPCommand {
        RESPCommand("HGET", key, field)
    }

    /// Returns all fields and values in a hash.
    ///
    /// - Documentation: [HGETALL](https:/redis.io/docs/latest/commands/hgetall)
    /// - Version: 2.0.0
    /// - Complexity: O(N) where N is the size of the hash.
    /// - Categories: @read, @hash, @slow
    /// - Response: [Map](https:/redis.io/docs/reference/protocol-spec#maps): a map of fields and their values stored in the hash, or an empty list when key does not exist.
    @inlinable
    public static func hgetall(key: RedisKey) -> RESPCommand {
        RESPCommand("HGETALL", key)
    }

    /// Increments the integer value of a field in a hash by a number. Uses 0 as initial value if the field doesn't exist.
    ///
    /// - Documentation: [HINCRBY](https:/redis.io/docs/latest/commands/hincrby)
    /// - Version: 2.0.0
    /// - Complexity: O(1)
    /// - Categories: @write, @hash, @fast
    /// - Response: [Integer](https:/redis.io/docs/reference/protocol-spec#integers): the value of the field after the increment operation.
    @inlinable
    public static func hincrby(key: RedisKey, field: String, increment: Int) -> RESPCommand {
        RESPCommand("HINCRBY", key, field, increment)
    }

    /// Increments the floating point value of a field by a number. Uses 0 as initial value if the field doesn't exist.
    ///
    /// - Documentation: [HINCRBYFLOAT](https:/redis.io/docs/latest/commands/hincrbyfloat)
    /// - Version: 2.6.0
    /// - Complexity: O(1)
    /// - Categories: @write, @hash, @fast
    /// - Response: [Bulk string](https:/redis.io/docs/reference/protocol-spec#bulk-strings): The value of the field after the increment operation.
    @inlinable
    public static func hincrbyfloat(key: RedisKey, field: String, increment: Double) -> RESPCommand {
        RESPCommand("HINCRBYFLOAT", key, field, increment)
    }

    /// Returns all fields in a hash.
    ///
    /// - Documentation: [HKEYS](https:/redis.io/docs/latest/commands/hkeys)
    /// - Version: 2.0.0
    /// - Complexity: O(N) where N is the size of the hash.
    /// - Categories: @read, @hash, @slow
    /// - Response: [Array](https:/redis.io/docs/reference/protocol-spec#arrays): a list of fields in the hash, or an empty list when the key does not exist.
    @inlinable
    public static func hkeys(key: RedisKey) -> RESPCommand {
        RESPCommand("HKEYS", key)
    }

    /// Returns the number of fields in a hash.
    ///
    /// - Documentation: [HLEN](https:/redis.io/docs/latest/commands/hlen)
    /// - Version: 2.0.0
    /// - Complexity: O(1)
    /// - Categories: @read, @hash, @fast
    /// - Response: [Integer](https:/redis.io/docs/reference/protocol-spec#integers): the number of the fields in the hash, or 0 when the key does not exist.
    @inlinable
    public static func hlen(key: RedisKey) -> RESPCommand {
        RESPCommand("HLEN", key)
    }

    /// Returns the values of all fields in a hash.
    ///
    /// - Documentation: [HMGET](https:/redis.io/docs/latest/commands/hmget)
    /// - Version: 2.0.0
    /// - Complexity: O(N) where N is the number of fields being requested.
    /// - Categories: @read, @hash, @fast
    /// - Response: [Array](https:/redis.io/docs/reference/protocol-spec#arrays): a list of values associated with the given fields, in the same order as they are requested.
    @inlinable
    public static func hmget(key: RedisKey, field: String) -> RESPCommand {
        RESPCommand("HMGET", key, field)
    }

    /// Returns the values of all fields in a hash.
    ///
    /// - Documentation: [HMGET](https:/redis.io/docs/latest/commands/hmget)
    /// - Version: 2.0.0
    /// - Complexity: O(N) where N is the number of fields being requested.
    /// - Categories: @read, @hash, @fast
    /// - Response: [Array](https:/redis.io/docs/reference/protocol-spec#arrays): a list of values associated with the given fields, in the same order as they are requested.
    @inlinable
    public static func hmget(key: RedisKey, fields: [String]) -> RESPCommand {
        RESPCommand("HMGET", key, fields)
    }

    public struct HMSETData: RESPRenderable {
        @usableFromInline let field: String
        @usableFromInline let value: String

        @inlinable
        public func writeToRESPBuffer(_ buffer: inout ByteBuffer) -> Int {
            var count = 0
            count += self.field.writeToRESPBuffer(&buffer)
            count += self.value.writeToRESPBuffer(&buffer)
            return count
        }
    }
    /// Sets the values of multiple fields.
    ///
    /// - Documentation: [HMSET](https:/redis.io/docs/latest/commands/hmset)
    /// - Version: 2.0.0
    /// - Complexity: O(N) where N is the number of fields being set.
    /// - Categories: @write, @hash, @fast
    /// - Response: [Simple string](https:/redis.io/docs/reference/protocol-spec#simple-strings): `OK`.
    @inlinable
    public static func hmset(key: RedisKey, data: HMSETData) -> RESPCommand {
        RESPCommand("HMSET", key, data)
    }

    /// Sets the values of multiple fields.
    ///
    /// - Documentation: [HMSET](https:/redis.io/docs/latest/commands/hmset)
    /// - Version: 2.0.0
    /// - Complexity: O(N) where N is the number of fields being set.
    /// - Categories: @write, @hash, @fast
    /// - Response: [Simple string](https:/redis.io/docs/reference/protocol-spec#simple-strings): `OK`.
    @inlinable
    public static func hmset(key: RedisKey, datas: [HMSETData]) -> RESPCommand {
        RESPCommand("HMSET", key, datas)
    }

    public struct HRANDFIELDOptions: RESPRenderable {
        @usableFromInline let count: Int
        @usableFromInline let withvalues: Bool

        @inlinable
        public func writeToRESPBuffer(_ buffer: inout ByteBuffer) -> Int {
            var count = 0
            count += self.count.writeToRESPBuffer(&buffer)
            if self.withvalues { count += "WITHVALUES".writeToRESPBuffer(&buffer) }
            return count
        }
    }
    /// Returns one or more random fields from a hash.
    ///
    /// - Documentation: [HRANDFIELD](https:/redis.io/docs/latest/commands/hrandfield)
    /// - Version: 6.2.0
    /// - Complexity: O(N) where N is the number of fields returned
    /// - Categories: @read, @hash, @slow
    /// - Response: Any of the following:
    ///     * [Null](https:/redis.io/docs/reference/protocol-spec#nulls): if the key doesn't exist
    ///     * [Bulk string](https:/redis.io/docs/reference/protocol-spec#bulk-strings): a single, randomly selected field when the `count` option is not used
    ///     * [Array](https:/redis.io/docs/reference/protocol-spec#arrays): a list containing `count` fields when the `count` option is used, or an empty array if the key does not exists.
    ///     * [Array](https:/redis.io/docs/reference/protocol-spec#arrays): a list of fields and their values when `count` and `WITHVALUES` were both used.
    @inlinable
    public static func hrandfield(key: RedisKey, options: HRANDFIELDOptions? = nil) -> RESPCommand {
        RESPCommand("HRANDFIELD", key, options)
    }

    /// Iterates over fields and values of a hash.
    ///
    /// - Documentation: [HSCAN](https:/redis.io/docs/latest/commands/hscan)
    /// - Version: 2.8.0
    /// - Complexity: O(1) for every call. O(N) for a complete iteration, including enough command calls for the cursor to return back to 0. N is the number of elements inside the collection.
    /// - Categories: @read, @hash, @slow
    /// - Response: [Array](https:/redis.io/docs/reference/protocol-spec#arrays): a two-element array.
    ///     * The first element is a [Bulk string](https:/redis.io/docs/reference/protocol-spec#bulk-strings) that represents an unsigned 64-bit number, the cursor.
    ///     * The second element is an [Array](https:/redis.io/docs/reference/protocol-spec#arrays) of field/value pairs that were scanned.
    @inlinable
    public static func hscan(key: RedisKey, cursor: Int, pattern: String? = nil, count: Int? = nil) -> RESPCommand {
        RESPCommand("HSCAN", key, cursor, RESPWithToken("MATCH", pattern), RESPWithToken("COUNT", count))
    }

    public struct HSETData: RESPRenderable {
        @usableFromInline let field: String
        @usableFromInline let value: String

        @inlinable
        public func writeToRESPBuffer(_ buffer: inout ByteBuffer) -> Int {
            var count = 0
            count += self.field.writeToRESPBuffer(&buffer)
            count += self.value.writeToRESPBuffer(&buffer)
            return count
        }
    }
    /// Creates or modifies the value of a field in a hash.
    ///
    /// - Documentation: [HSET](https:/redis.io/docs/latest/commands/hset)
    /// - Version: 2.0.0
    /// - Complexity: O(1) for each field/value pair added, so O(N) to add N field/value pairs when the command is called with multiple field/value pairs.
    /// - Categories: @write, @hash, @fast
    /// - Response: [Integer](https:/redis.io/docs/reference/protocol-spec#integers): the number of fields that were added.
    @inlinable
    public static func hset(key: RedisKey, data: HSETData) -> RESPCommand {
        RESPCommand("HSET", key, data)
    }

    /// Creates or modifies the value of a field in a hash.
    ///
    /// - Documentation: [HSET](https:/redis.io/docs/latest/commands/hset)
    /// - Version: 2.0.0
    /// - Complexity: O(1) for each field/value pair added, so O(N) to add N field/value pairs when the command is called with multiple field/value pairs.
    /// - Categories: @write, @hash, @fast
    /// - Response: [Integer](https:/redis.io/docs/reference/protocol-spec#integers): the number of fields that were added.
    @inlinable
    public static func hset(key: RedisKey, datas: [HSETData]) -> RESPCommand {
        RESPCommand("HSET", key, datas)
    }

    /// Sets the value of a field in a hash only when the field doesn't exist.
    ///
    /// - Documentation: [HSETNX](https:/redis.io/docs/latest/commands/hsetnx)
    /// - Version: 2.0.0
    /// - Complexity: O(1)
    /// - Categories: @write, @hash, @fast
    /// - Response: One of the following:
    ///     * [Integer](https:/redis.io/docs/reference/protocol-spec#integers): `0` if the field already exists in the hash and no operation was performed.
    ///     * [Integer](https:/redis.io/docs/reference/protocol-spec#integers): `1` if the field is a new field in the hash and the value was set.
    @inlinable
    public static func hsetnx(key: RedisKey, field: String, value: String) -> RESPCommand {
        RESPCommand("HSETNX", key, field, value)
    }

    /// Returns the length of the value of a field.
    ///
    /// - Documentation: [HSTRLEN](https:/redis.io/docs/latest/commands/hstrlen)
    /// - Version: 3.2.0
    /// - Complexity: O(1)
    /// - Categories: @read, @hash, @fast
    /// - Response: [Integer](https:/redis.io/docs/reference/protocol-spec#integers): the string length of the value associated with the _field_, or zero when the _field_ isn't present in the hash or the _key_ doesn't exist at all.
    @inlinable
    public static func hstrlen(key: RedisKey, field: String) -> RESPCommand {
        RESPCommand("HSTRLEN", key, field)
    }

    /// Returns all values in a hash.
    ///
    /// - Documentation: [HVALS](https:/redis.io/docs/latest/commands/hvals)
    /// - Version: 2.0.0
    /// - Complexity: O(N) where N is the size of the hash.
    /// - Categories: @read, @hash, @slow
    /// - Response: [Array](https:/redis.io/docs/reference/protocol-spec#arrays): a list of values in the hash, or an empty list when the key does not exist.
    @inlinable
    public static func hvals(key: RedisKey) -> RESPCommand {
        RESPCommand("HVALS", key)
    }

    /// Increments the integer value of a key by one. Uses 0 as initial value if the key doesn't exist.
    ///
    /// - Documentation: [INCR](https:/redis.io/docs/latest/commands/incr)
    /// - Version: 1.0.0
    /// - Complexity: O(1)
    /// - Categories: @write, @string, @fast
    /// - Response: [Integer](https:/redis.io/docs/reference/protocol-spec#integers): the value of the key after the increment.
    @inlinable
    public static func incr(key: RedisKey) -> RESPCommand {
        RESPCommand("INCR", key)
    }

    /// Increments the integer value of a key by a number. Uses 0 as initial value if the key doesn't exist.
    ///
    /// - Documentation: [INCRBY](https:/redis.io/docs/latest/commands/incrby)
    /// - Version: 1.0.0
    /// - Complexity: O(1)
    /// - Categories: @write, @string, @fast
    /// - Response: [Integer](https:/redis.io/docs/reference/protocol-spec#integers): the value of the key after the increment.
    @inlinable
    public static func incrby(key: RedisKey, increment: Int) -> RESPCommand {
        RESPCommand("INCRBY", key, increment)
    }

    /// Increment the floating point value of a key by a number. Uses 0 as initial value if the key doesn't exist.
    ///
    /// - Documentation: [INCRBYFLOAT](https:/redis.io/docs/latest/commands/incrbyfloat)
    /// - Version: 2.6.0
    /// - Complexity: O(1)
    /// - Categories: @write, @string, @fast
    /// - Response: [Bulk string](https:/redis.io/docs/reference/protocol-spec#bulk-strings): the value of the key after the increment.
    @inlinable
    public static func incrbyfloat(key: RedisKey, increment: Double) -> RESPCommand {
        RESPCommand("INCRBYFLOAT", key, increment)
    }

    /// Returns information and statistics about the server.
    ///
    /// - Documentation: [INFO](https:/redis.io/docs/latest/commands/info)
    /// - Version: 1.0.0
    /// - Complexity: O(1)
    /// - Categories: @slow, @dangerous
    /// - Response: [Bulk string](https:/redis.io/docs/reference/protocol-spec#bulk-strings): a map of info fields, one field per line in the form of `<field>:<value>` where the value can be a comma separated map like `<key>=<val>`. Also contains section header lines starting with `#` and blank lines.
    ///     
    ///     Lines can contain a section name (starting with a `#` character) or a property. All the properties are in the form of `field:value` terminated by `\r\n`.
    @inlinable
    public static func info(section: String? = nil) -> RESPCommand {
        RESPCommand("INFO", section)
    }

    /// Returns information and statistics about the server.
    ///
    /// - Documentation: [INFO](https:/redis.io/docs/latest/commands/info)
    /// - Version: 1.0.0
    /// - Complexity: O(1)
    /// - Categories: @slow, @dangerous
    /// - Response: [Bulk string](https:/redis.io/docs/reference/protocol-spec#bulk-strings): a map of info fields, one field per line in the form of `<field>:<value>` where the value can be a comma separated map like `<key>=<val>`. Also contains section header lines starting with `#` and blank lines.
    ///     
    ///     Lines can contain a section name (starting with a `#` character) or a property. All the properties are in the form of `field:value` terminated by `\r\n`.
    @inlinable
    public static func info(sections: [String]) -> RESPCommand {
        RESPCommand("INFO", sections)
    }

    /// Returns all key names that match a pattern.
    ///
    /// - Documentation: [KEYS](https:/redis.io/docs/latest/commands/keys)
    /// - Version: 1.0.0
    /// - Complexity: O(N) with N being the number of keys in the database, under the assumption that the key names in the database and the given pattern have limited length.
    /// - Categories: @keyspace, @read, @slow, @dangerous
    /// - Response: [Array](https:/redis.io/docs/reference/protocol-spec#arrays): a list of keys matching _pattern_.
    @inlinable
    public static func keys(pattern: String) -> RESPCommand {
        RESPCommand("KEYS", pattern)
    }

    /// Returns the Unix timestamp of the last successful save to disk.
    ///
    /// - Documentation: [LASTSAVE](https:/redis.io/docs/latest/commands/lastsave)
    /// - Version: 1.0.0
    /// - Complexity: O(1)
    /// - Categories: @admin, @fast, @dangerous
    /// - Response: [Integer](https:/redis.io/docs/reference/protocol-spec#integers): UNIX TIME of the last DB save executed with success.
    @inlinable
    public static func lastsave() -> RESPCommand {
        RESPCommand("LASTSAVE")
    }

    /// Returns a human-readable latency analysis report.
    ///
    /// - Documentation: [LATENCY DOCTOR](https:/redis.io/docs/latest/commands/latency-doctor)
    /// - Version: 2.8.13
    /// - Complexity: O(1)
    /// - Categories: @admin, @slow, @dangerous
    /// - Response: [Verbatim string](https:/redis.io/docs/reference/protocol-spec#verbatim-strings): a human readable latency analysis report.
    @inlinable
    public static func latencyDoctor() -> RESPCommand {
        RESPCommand("LATENCY", "DOCTOR")
    }

    /// Returns a latency graph for an event.
    ///
    /// - Documentation: [LATENCY GRAPH](https:/redis.io/docs/latest/commands/latency-graph)
    /// - Version: 2.8.13
    /// - Complexity: O(1)
    /// - Categories: @admin, @slow, @dangerous
    /// - Response: [Bulk string](https:/redis.io/docs/reference/protocol-spec#bulk-strings): Latency graph
    @inlinable
    public static func latencyGraph(event: String) -> RESPCommand {
        RESPCommand("LATENCY", "GRAPH", event)
    }

    /// Returns helpful text about the different subcommands.
    ///
    /// - Documentation: [LATENCY HELP](https:/redis.io/docs/latest/commands/latency-help)
    /// - Version: 2.8.13
    /// - Complexity: O(1)
    /// - Categories: @slow
    /// - Response: [Array](https:/redis.io/docs/reference/protocol-spec#arrays): a list of sub-commands and their descriptions.
    @inlinable
    public static func latencyHelp() -> RESPCommand {
        RESPCommand("LATENCY", "HELP")
    }

    /// Returns the cumulative distribution of latencies of a subset or all commands.
    ///
    /// - Documentation: [LATENCY HISTOGRAM](https:/redis.io/docs/latest/commands/latency-histogram)
    /// - Version: 7.0.0
    /// - Complexity: O(N) where N is the number of commands with latency information being retrieved.
    /// - Categories: @admin, @slow, @dangerous
    /// - Response: [Map](https:/redis.io/docs/reference/protocol-spec#maps): a map where each key is a command name, and each value is a map with the total calls, and an inner map of the histogram time buckets.
    @inlinable
    public static func latencyHistogram(command: String? = nil) -> RESPCommand {
        RESPCommand("LATENCY", "HISTOGRAM", command)
    }

    /// Returns the cumulative distribution of latencies of a subset or all commands.
    ///
    /// - Documentation: [LATENCY HISTOGRAM](https:/redis.io/docs/latest/commands/latency-histogram)
    /// - Version: 7.0.0
    /// - Complexity: O(N) where N is the number of commands with latency information being retrieved.
    /// - Categories: @admin, @slow, @dangerous
    /// - Response: [Map](https:/redis.io/docs/reference/protocol-spec#maps): a map where each key is a command name, and each value is a map with the total calls, and an inner map of the histogram time buckets.
    @inlinable
    public static func latencyHistogram(commands: [String]) -> RESPCommand {
        RESPCommand("LATENCY", "HISTOGRAM", commands)
    }

    /// Returns timestamp-latency samples for an event.
    ///
    /// - Documentation: [LATENCY HISTORY](https:/redis.io/docs/latest/commands/latency-history)
    /// - Version: 2.8.13
    /// - Complexity: O(1)
    /// - Categories: @admin, @slow, @dangerous
    /// - Response: [Array](https:/redis.io/docs/reference/protocol-spec#arrays): an array where each element is a two elements array representing the timestamp and the latency of the event.
    @inlinable
    public static func latencyHistory(event: String) -> RESPCommand {
        RESPCommand("LATENCY", "HISTORY", event)
    }

    /// Returns the latest latency samples for all events.
    ///
    /// - Documentation: [LATENCY LATEST](https:/redis.io/docs/latest/commands/latency-latest)
    /// - Version: 2.8.13
    /// - Complexity: O(1)
    /// - Categories: @admin, @slow, @dangerous
    /// - Response: [Array](https:/redis.io/docs/reference/protocol-spec#arrays): an array where each element is a four elements array representing the event's name, timestamp, latest and all-time latency measurements.
    @inlinable
    public static func latencyLatest() -> RESPCommand {
        RESPCommand("LATENCY", "LATEST")
    }

    /// Resets the latency data for one or more events.
    ///
    /// - Documentation: [LATENCY RESET](https:/redis.io/docs/latest/commands/latency-reset)
    /// - Version: 2.8.13
    /// - Complexity: O(1)
    /// - Categories: @admin, @slow, @dangerous
    /// - Response: [Integer](https:/redis.io/docs/reference/protocol-spec#integers): the number of event time series that were reset.
    @inlinable
    public static func latencyReset(event: String? = nil) -> RESPCommand {
        RESPCommand("LATENCY", "RESET", event)
    }

    /// Resets the latency data for one or more events.
    ///
    /// - Documentation: [LATENCY RESET](https:/redis.io/docs/latest/commands/latency-reset)
    /// - Version: 2.8.13
    /// - Complexity: O(1)
    /// - Categories: @admin, @slow, @dangerous
    /// - Response: [Integer](https:/redis.io/docs/reference/protocol-spec#integers): the number of event time series that were reset.
    @inlinable
    public static func latencyReset(events: [String]) -> RESPCommand {
        RESPCommand("LATENCY", "RESET", events)
    }

    /// Finds the longest common substring.
    ///
    /// - Documentation: [LCS](https:/redis.io/docs/latest/commands/lcs)
    /// - Version: 7.0.0
    /// - Complexity: O(N*M) where N and M are the lengths of s1 and s2, respectively
    /// - Categories: @read, @string, @slow
    /// - Response: One of the following:
    ///     * [Bulk string](https:/redis.io/docs/reference/protocol-spec#bulk-strings): the longest common subsequence.
    ///     * [Integer](https:/redis.io/docs/reference/protocol-spec#integers): the length of the longest common subsequence when _LEN_ is given.
    ///     * [Map](https:/redis.io/docs/reference/protocol-spec#maps): a map with the LCS length and all the ranges in both the strings when _IDX_ is given.
    @inlinable
    public static func lcs(key1: RedisKey, key2: RedisKey, len: Bool = false, idx: Bool = false, minMatchLen: Int? = nil, withmatchlen: Bool = false) -> RESPCommand {
        RESPCommand("LCS", key1, key2, RedisPureToken("LEN", len), RedisPureToken("IDX", idx), RESPWithToken("MINMATCHLEN", minMatchLen), RedisPureToken("WITHMATCHLEN", withmatchlen))
    }

    /// Returns an element from a list by its index.
    ///
    /// - Documentation: [LINDEX](https:/redis.io/docs/latest/commands/lindex)
    /// - Version: 1.0.0
    /// - Complexity: O(N) where N is the number of elements to traverse to get to the element at index. This makes asking for the first or the last element of the list O(1).
    /// - Categories: @read, @list, @slow
    /// - Response: One of the following:
    ///     * [Null](https:/redis.io/docs/reference/protocol-spec#nulls): when _index_ is out of range.
    ///     * [Bulk string](https:/redis.io/docs/reference/protocol-spec#bulk-strings): the requested element.
    @inlinable
    public static func lindex(key: RedisKey, index: Int) -> RESPCommand {
        RESPCommand("LINDEX", key, index)
    }

    public enum LINSERTWhere: RESPRenderable {
        case before
        case after

        @inlinable
        public func writeToRESPBuffer(_ buffer: inout ByteBuffer) -> Int {
            switch self {
            case .before: "BEFORE".writeToRESPBuffer(&buffer)
            case .after: "AFTER".writeToRESPBuffer(&buffer)
            }
        }
    }
    /// Inserts an element before or after another element in a list.
    ///
    /// - Documentation: [LINSERT](https:/redis.io/docs/latest/commands/linsert)
    /// - Version: 2.2.0
    /// - Complexity: O(N) where N is the number of elements to traverse before seeing the value pivot. This means that inserting somewhere on the left end on the list (head) can be considered O(1) and inserting somewhere on the right end (tail) is O(N).
    /// - Categories: @write, @list, @slow
    /// - Response: One of the following:
    ///     * [Integer](https:/redis.io/docs/reference/protocol-spec#integers): the list length after a successful insert operation.
    ///     * [Integer](https:/redis.io/docs/reference/protocol-spec#integers): `0` when the key doesn't exist.
    ///     * [Integer](https:/redis.io/docs/reference/protocol-spec#integers): `-1` when the pivot wasn't found.
    @inlinable
    public static func linsert(key: RedisKey, `where`: LINSERTWhere, pivot: String, element: String) -> RESPCommand {
        RESPCommand("LINSERT", key, `where`, pivot, element)
    }

    /// Returns the length of a list.
    ///
    /// - Documentation: [LLEN](https:/redis.io/docs/latest/commands/llen)
    /// - Version: 1.0.0
    /// - Complexity: O(1)
    /// - Categories: @read, @list, @fast
    /// - Response: [Integer](https:/redis.io/docs/reference/protocol-spec#integers): the length of the list.
    @inlinable
    public static func llen(key: RedisKey) -> RESPCommand {
        RESPCommand("LLEN", key)
    }

    public enum LMOVEWherefrom: RESPRenderable {
        case left
        case right

        @inlinable
        public func writeToRESPBuffer(_ buffer: inout ByteBuffer) -> Int {
            switch self {
            case .left: "LEFT".writeToRESPBuffer(&buffer)
            case .right: "RIGHT".writeToRESPBuffer(&buffer)
            }
        }
    }
    public enum LMOVEWhereto: RESPRenderable {
        case left
        case right

        @inlinable
        public func writeToRESPBuffer(_ buffer: inout ByteBuffer) -> Int {
            switch self {
            case .left: "LEFT".writeToRESPBuffer(&buffer)
            case .right: "RIGHT".writeToRESPBuffer(&buffer)
            }
        }
    }
    /// Returns an element after popping it from one list and pushing it to another. Deletes the list if the last element was moved.
    ///
    /// - Documentation: [LMOVE](https:/redis.io/docs/latest/commands/lmove)
    /// - Version: 6.2.0
    /// - Complexity: O(1)
    /// - Categories: @write, @list, @slow
    /// - Response: [Bulk string](https:/redis.io/docs/reference/protocol-spec#bulk-strings): the element being popped and pushed.
    @inlinable
    public static func lmove(source: RedisKey, destination: RedisKey, wherefrom: LMOVEWherefrom, whereto: LMOVEWhereto) -> RESPCommand {
        RESPCommand("LMOVE", source, destination, wherefrom, whereto)
    }

    public enum LMPOPWhere: RESPRenderable {
        case left
        case right

        @inlinable
        public func writeToRESPBuffer(_ buffer: inout ByteBuffer) -> Int {
            switch self {
            case .left: "LEFT".writeToRESPBuffer(&buffer)
            case .right: "RIGHT".writeToRESPBuffer(&buffer)
            }
        }
    }
    /// Returns multiple elements from a list after removing them. Deletes the list if the last element was popped.
    ///
    /// - Documentation: [LMPOP](https:/redis.io/docs/latest/commands/lmpop)
    /// - Version: 7.0.0
    /// - Complexity: O(N+M) where N is the number of provided keys and M is the number of elements returned.
    /// - Categories: @write, @list, @slow
    /// - Response: One of the following:
    ///     * [Null](https:/redis.io/docs/reference/protocol-spec#nulls): if no element could be popped.
    ///     * [Array](https:/redis.io/docs/reference/protocol-spec#arrays): a two-element array with the first element being the name of the key from which elements were popped and the second element being an array of elements.
    @inlinable
    public static func lmpop(key: RedisKey, `where`: LMPOPWhere, count: Int? = nil) -> RESPCommand {
        RESPCommand("LMPOP", 1, key, `where`, RESPWithToken("COUNT", count))
    }

    /// Returns multiple elements from a list after removing them. Deletes the list if the last element was popped.
    ///
    /// - Documentation: [LMPOP](https:/redis.io/docs/latest/commands/lmpop)
    /// - Version: 7.0.0
    /// - Complexity: O(N+M) where N is the number of provided keys and M is the number of elements returned.
    /// - Categories: @write, @list, @slow
    /// - Response: One of the following:
    ///     * [Null](https:/redis.io/docs/reference/protocol-spec#nulls): if no element could be popped.
    ///     * [Array](https:/redis.io/docs/reference/protocol-spec#arrays): a two-element array with the first element being the name of the key from which elements were popped and the second element being an array of elements.
    @inlinable
    public static func lmpop(keys: [RedisKey], `where`: LMPOPWhere, count: Int? = nil) -> RESPCommand {
        RESPCommand("LMPOP", RESPArrayWithCount(keys), `where`, RESPWithToken("COUNT", count))
    }

    /// Displays computer art and the Redis version
    ///
    /// - Documentation: [LOLWUT](https:/redis.io/docs/latest/commands/lolwut)
    /// - Version: 5.0.0
    /// - Categories: @read, @fast
    /// - Response: [Verbatim string](https:/redis.io/docs/reference/protocol-spec#verbatim-strings): a string containing generative computer art and the Redis version.
    @inlinable
    public static func lolwut(version: Int? = nil) -> RESPCommand {
        RESPCommand("LOLWUT", RESPWithToken("VERSION", version))
    }

    /// Returns the first elements in a list after removing it. Deletes the list if the last element was popped.
    ///
    /// - Documentation: [LPOP](https:/redis.io/docs/latest/commands/lpop)
    /// - Version: 1.0.0
    /// - Complexity: O(N) where N is the number of elements returned
    /// - Categories: @write, @list, @fast
    /// - Response: One of the following:
    ///     * [Null](https:/redis.io/docs/reference/protocol-spec#nulls): if the key does not exist.
    ///     * [Bulk string](https:/redis.io/docs/reference/protocol-spec#bulk-strings): when called without the _count_ argument, the value of the first element.
    ///     * [Array](https:/redis.io/docs/reference/protocol-spec#arrays): when called with the _count_ argument, a list of popped elements.
    @inlinable
    public static func lpop(key: RedisKey, count: Int? = nil) -> RESPCommand {
        RESPCommand("LPOP", key, count)
    }

    /// Returns the index of matching elements in a list.
    ///
    /// - Documentation: [LPOS](https:/redis.io/docs/latest/commands/lpos)
    /// - Version: 6.0.6
    /// - Complexity: O(N) where N is the number of elements in the list, for the average case. When searching for elements near the head or the tail of the list, or when the MAXLEN option is provided, the command may run in constant time.
    /// - Categories: @read, @list, @slow
    /// - Response: Any of the following:
    ///     * [Null](https:/redis.io/docs/reference/protocol-spec#nulls): if there is no matching element.
    ///     * [Integer](https:/redis.io/docs/reference/protocol-spec#integers): an integer representing the matching element.
    ///     * [Array](https:/redis.io/docs/reference/protocol-spec#arrays): If the COUNT option is given, an array of integers representing the matching elements (or an empty array if there are no matches).
    @inlinable
    public static func lpos(key: RedisKey, element: String, rank: Int? = nil, numMatches: Int? = nil, len: Int? = nil) -> RESPCommand {
        RESPCommand("LPOS", key, element, RESPWithToken("RANK", rank), RESPWithToken("COUNT", numMatches), RESPWithToken("MAXLEN", len))
    }

    /// Prepends one or more elements to a list. Creates the key if it doesn't exist.
    ///
    /// - Documentation: [LPUSH](https:/redis.io/docs/latest/commands/lpush)
    /// - Version: 1.0.0
    /// - Complexity: O(1) for each element added, so O(N) to add N elements when the command is called with multiple arguments.
    /// - Categories: @write, @list, @fast
    /// - Response: [Integer](https:/redis.io/docs/reference/protocol-spec#integers): the length of the list after the push operation.
    @inlinable
    public static func lpush(key: RedisKey, element: String) -> RESPCommand {
        RESPCommand("LPUSH", key, element)
    }

    /// Prepends one or more elements to a list. Creates the key if it doesn't exist.
    ///
    /// - Documentation: [LPUSH](https:/redis.io/docs/latest/commands/lpush)
    /// - Version: 1.0.0
    /// - Complexity: O(1) for each element added, so O(N) to add N elements when the command is called with multiple arguments.
    /// - Categories: @write, @list, @fast
    /// - Response: [Integer](https:/redis.io/docs/reference/protocol-spec#integers): the length of the list after the push operation.
    @inlinable
    public static func lpush(key: RedisKey, elements: [String]) -> RESPCommand {
        RESPCommand("LPUSH", key, elements)
    }

    /// Prepends one or more elements to a list only when the list exists.
    ///
    /// - Documentation: [LPUSHX](https:/redis.io/docs/latest/commands/lpushx)
    /// - Version: 2.2.0
    /// - Complexity: O(1) for each element added, so O(N) to add N elements when the command is called with multiple arguments.
    /// - Categories: @write, @list, @fast
    /// - Response: [Integer](https:/redis.io/docs/reference/protocol-spec#integers): the length of the list after the push operation.
    @inlinable
    public static func lpushx(key: RedisKey, element: String) -> RESPCommand {
        RESPCommand("LPUSHX", key, element)
    }

    /// Prepends one or more elements to a list only when the list exists.
    ///
    /// - Documentation: [LPUSHX](https:/redis.io/docs/latest/commands/lpushx)
    /// - Version: 2.2.0
    /// - Complexity: O(1) for each element added, so O(N) to add N elements when the command is called with multiple arguments.
    /// - Categories: @write, @list, @fast
    /// - Response: [Integer](https:/redis.io/docs/reference/protocol-spec#integers): the length of the list after the push operation.
    @inlinable
    public static func lpushx(key: RedisKey, elements: [String]) -> RESPCommand {
        RESPCommand("LPUSHX", key, elements)
    }

    /// Returns a range of elements from a list.
    ///
    /// - Documentation: [LRANGE](https:/redis.io/docs/latest/commands/lrange)
    /// - Version: 1.0.0
    /// - Complexity: O(S+N) where S is the distance of start offset from HEAD for small lists, from nearest end (HEAD or TAIL) for large lists; and N is the number of elements in the specified range.
    /// - Categories: @read, @list, @slow
    /// - Response: [Array](https:/redis.io/docs/reference/protocol-spec#arrays): a list of elements in the specified range, or an empty array if the key doesn't exist.
    @inlinable
    public static func lrange(key: RedisKey, start: Int, stop: Int) -> RESPCommand {
        RESPCommand("LRANGE", key, start, stop)
    }

    /// Removes elements from a list. Deletes the list if the last element was removed.
    ///
    /// - Documentation: [LREM](https:/redis.io/docs/latest/commands/lrem)
    /// - Version: 1.0.0
    /// - Complexity: O(N+M) where N is the length of the list and M is the number of elements removed.
    /// - Categories: @write, @list, @slow
    /// - Response: [Integer](https:/redis.io/docs/reference/protocol-spec#integers): the number of removed elements.
    @inlinable
    public static func lrem(key: RedisKey, count: Int, element: String) -> RESPCommand {
        RESPCommand("LREM", key, count, element)
    }

    /// Sets the value of an element in a list by its index.
    ///
    /// - Documentation: [LSET](https:/redis.io/docs/latest/commands/lset)
    /// - Version: 1.0.0
    /// - Complexity: O(N) where N is the length of the list. Setting either the first or the last element of the list is O(1).
    /// - Categories: @write, @list, @slow
    /// - Response: [Simple string](https:/redis.io/docs/reference/protocol-spec#simple-strings): `OK`.
    @inlinable
    public static func lset(key: RedisKey, index: Int, element: String) -> RESPCommand {
        RESPCommand("LSET", key, index, element)
    }

    /// Removes elements from both ends a list. Deletes the list if all elements were trimmed.
    ///
    /// - Documentation: [LTRIM](https:/redis.io/docs/latest/commands/ltrim)
    /// - Version: 1.0.0
    /// - Complexity: O(N) where N is the number of elements to be removed by the operation.
    /// - Categories: @write, @list, @slow
    /// - Response: [Simple string](https:/redis.io/docs/reference/protocol-spec#simple-strings): `OK`.
    @inlinable
    public static func ltrim(key: RedisKey, start: Int, stop: Int) -> RESPCommand {
        RESPCommand("LTRIM", key, start, stop)
    }

    /// Outputs a memory problems report.
    ///
    /// - Documentation: [MEMORY DOCTOR](https:/redis.io/docs/latest/commands/memory-doctor)
    /// - Version: 4.0.0
    /// - Complexity: O(1)
    /// - Categories: @slow
    /// - Response: [Verbatim string](https:/redis.io/docs/reference/protocol-spec#verbatim-strings): a memory problems report.
    @inlinable
    public static func memoryDoctor() -> RESPCommand {
        RESPCommand("MEMORY", "DOCTOR")
    }

    /// Returns helpful text about the different subcommands.
    ///
    /// - Documentation: [MEMORY HELP](https:/redis.io/docs/latest/commands/memory-help)
    /// - Version: 4.0.0
    /// - Complexity: O(1)
    /// - Categories: @slow
    /// - Response: [Array](https:/redis.io/docs/reference/protocol-spec#arrays): a list of sub-commands and their descriptions.
    @inlinable
    public static func memoryHelp() -> RESPCommand {
        RESPCommand("MEMORY", "HELP")
    }

    /// Returns the allocator statistics.
    ///
    /// - Documentation: [MEMORY MALLOC-STATS](https:/redis.io/docs/latest/commands/memory-malloc-stats)
    /// - Version: 4.0.0
    /// - Complexity: Depends on how much memory is allocated, could be slow
    /// - Categories: @slow
    /// - Response: [Bulk string](https:/redis.io/docs/reference/protocol-spec#bulk-strings): The memory allocator's internal statistics report.
    @inlinable
    public static func memoryMallocStats() -> RESPCommand {
        RESPCommand("MEMORY", "MALLOC-STATS")
    }

    /// Asks the allocator to release memory.
    ///
    /// - Documentation: [MEMORY PURGE](https:/redis.io/docs/latest/commands/memory-purge)
    /// - Version: 4.0.0
    /// - Complexity: Depends on how much memory is allocated, could be slow
    /// - Categories: @slow
    /// - Response: [Simple string](https:/redis.io/docs/reference/protocol-spec#simple-strings): `OK`.
    @inlinable
    public static func memoryPurge() -> RESPCommand {
        RESPCommand("MEMORY", "PURGE")
    }

    /// Returns details about memory usage.
    ///
    /// - Documentation: [MEMORY STATS](https:/redis.io/docs/latest/commands/memory-stats)
    /// - Version: 4.0.0
    /// - Complexity: O(1)
    /// - Categories: @slow
    /// - Response: [Map](https:/redis.io/docs/reference/protocol-spec#maps): memory usage metrics and their values.
    @inlinable
    public static func memoryStats() -> RESPCommand {
        RESPCommand("MEMORY", "STATS")
    }

    /// Estimates the memory usage of a key.
    ///
    /// - Documentation: [MEMORY USAGE](https:/redis.io/docs/latest/commands/memory-usage)
    /// - Version: 4.0.0
    /// - Complexity: O(N) where N is the number of samples.
    /// - Categories: @read, @slow
    /// - Response: One of the following:
    ///     * [Integer](https:/redis.io/docs/reference/protocol-spec#integers): the memory usage in bytes.
    ///     * [Null](https:/redis.io/docs/reference/protocol-spec#nulls): if the key does not exist.
    @inlinable
    public static func memoryUsage(key: RedisKey, count: Int? = nil) -> RESPCommand {
        RESPCommand("MEMORY", "USAGE", key, RESPWithToken("SAMPLES", count))
    }

    /// Atomically returns the string values of one or more keys.
    ///
    /// - Documentation: [MGET](https:/redis.io/docs/latest/commands/mget)
    /// - Version: 1.0.0
    /// - Complexity: O(N) where N is the number of keys to retrieve.
    /// - Categories: @read, @string, @fast
    /// - Response: [Array](https:/redis.io/docs/reference/protocol-spec#arrays): a list of values at the specified keys.
    @inlinable
    public static func mget(key: RedisKey) -> RESPCommand {
        RESPCommand("MGET", key)
    }

    /// Atomically returns the string values of one or more keys.
    ///
    /// - Documentation: [MGET](https:/redis.io/docs/latest/commands/mget)
    /// - Version: 1.0.0
    /// - Complexity: O(N) where N is the number of keys to retrieve.
    /// - Categories: @read, @string, @fast
    /// - Response: [Array](https:/redis.io/docs/reference/protocol-spec#arrays): a list of values at the specified keys.
    @inlinable
    public static func mget(keys: [RedisKey]) -> RESPCommand {
        RESPCommand("MGET", keys)
    }

    public enum MIGRATEKeySelector: RESPRenderable {
        case key(RedisKey)
        case emptyString

        @inlinable
        public func writeToRESPBuffer(_ buffer: inout ByteBuffer) -> Int {
            switch self {
            case .key(let key): key.writeToRESPBuffer(&buffer)
            case .emptyString: "".writeToRESPBuffer(&buffer)
            }
        }
    }
    public struct MIGRATEAuthenticationAuth2: RESPRenderable {
        @usableFromInline let username: String
        @usableFromInline let password: String

        @inlinable
        public func writeToRESPBuffer(_ buffer: inout ByteBuffer) -> Int {
            var count = 0
            count += self.username.writeToRESPBuffer(&buffer)
            count += self.password.writeToRESPBuffer(&buffer)
            return count
        }
    }
    public enum MIGRATEAuthentication: RESPRenderable {
        case auth(String)
        case auth2(MIGRATEAuthenticationAuth2)

        @inlinable
        public func writeToRESPBuffer(_ buffer: inout ByteBuffer) -> Int {
            switch self {
            case .auth(let auth): RESPWithToken("AUTH", auth).writeToRESPBuffer(&buffer)
            case .auth2(let auth2): RESPWithToken("AUTH2", auth2).writeToRESPBuffer(&buffer)
            }
        }
    }
    /// Atomically transfers a key from one Redis instance to another.
    ///
    /// - Documentation: [MIGRATE](https:/redis.io/docs/latest/commands/migrate)
    /// - Version: 2.6.0
    /// - Complexity: This command actually executes a DUMP+DEL in the source instance, and a RESTORE in the target instance. See the pages of these commands for time complexity. Also an O(N) data transfer between the two instances is performed.
    /// - Categories: @keyspace, @write, @slow, @dangerous
    /// - Response: One of the following:
    ///     * [Simple string](https:/redis.io/docs/reference/protocol-spec#simple-strings): `OK` on success.
    ///     * [Simple string](https:/redis.io/docs/reference/protocol-spec#simple-strings): `NOKEY` when no keys were found in the source instance.
    @inlinable
    public static func migrate(host: String, port: Int, keySelector: MIGRATEKeySelector, destinationDb: Int, timeout: Int, copy: Bool = false, replace: Bool = false, authentication: MIGRATEAuthentication? = nil, keys: RedisKey? = nil) -> RESPCommand {
        RESPCommand("MIGRATE", host, port, keySelector, destinationDb, timeout, RedisPureToken("COPY", copy), RedisPureToken("REPLACE", replace), authentication, RESPWithToken("KEYS", keys))
    }

    /// Atomically transfers a key from one Redis instance to another.
    ///
    /// - Documentation: [MIGRATE](https:/redis.io/docs/latest/commands/migrate)
    /// - Version: 2.6.0
    /// - Complexity: This command actually executes a DUMP+DEL in the source instance, and a RESTORE in the target instance. See the pages of these commands for time complexity. Also an O(N) data transfer between the two instances is performed.
    /// - Categories: @keyspace, @write, @slow, @dangerous
    /// - Response: One of the following:
    ///     * [Simple string](https:/redis.io/docs/reference/protocol-spec#simple-strings): `OK` on success.
    ///     * [Simple string](https:/redis.io/docs/reference/protocol-spec#simple-strings): `NOKEY` when no keys were found in the source instance.
    @inlinable
    public static func migrate(host: String, port: Int, keySelector: MIGRATEKeySelector, destinationDb: Int, timeout: Int, copy: Bool = false, replace: Bool = false, authentication: MIGRATEAuthentication? = nil, keyss: [RedisKey]) -> RESPCommand {
        RESPCommand("MIGRATE", host, port, keySelector, destinationDb, timeout, RedisPureToken("COPY", copy), RedisPureToken("REPLACE", replace), authentication, RESPWithToken("KEYS", keyss))
    }

    /// Returns helpful text about the different subcommands.
    ///
    /// - Documentation: [MODULE HELP](https:/redis.io/docs/latest/commands/module-help)
    /// - Version: 5.0.0
    /// - Complexity: O(1)
    /// - Categories: @slow
    /// - Response: [Array](https:/redis.io/docs/reference/protocol-spec#arrays): a list of sub-commands and their descriptions
    @inlinable
    public static func moduleHelp() -> RESPCommand {
        RESPCommand("MODULE", "HELP")
    }

    /// Returns all loaded modules.
    ///
    /// - Documentation: [MODULE LIST](https:/redis.io/docs/latest/commands/module-list)
    /// - Version: 4.0.0
    /// - Complexity: O(N) where N is the number of loaded modules.
    /// - Categories: @admin, @slow, @dangerous
    /// - Response: [Array](https:/redis.io/docs/reference/protocol-spec#arrays): list of loaded modules. Each element in the list represents a represents a module, and is a [Map](https:/redis.io/docs/reference/protocol-spec#maps) of property names and their values. The following properties is reported for each loaded module:
    ///     * name: the name of the module.
    ///     * ver: the version of the module.
    @inlinable
    public static func moduleList() -> RESPCommand {
        RESPCommand("MODULE", "LIST")
    }

    /// Loads a module.
    ///
    /// - Documentation: [MODULE LOAD](https:/redis.io/docs/latest/commands/module-load)
    /// - Version: 4.0.0
    /// - Complexity: O(1)
    /// - Categories: @admin, @slow, @dangerous
    /// - Response: [Simple string](https:/redis.io/docs/reference/protocol-spec#simple-strings): `OK` if the module was loaded.
    @inlinable
    public static func moduleLoad(path: String, arg: String? = nil) -> RESPCommand {
        RESPCommand("MODULE", "LOAD", path, arg)
    }

    /// Loads a module.
    ///
    /// - Documentation: [MODULE LOAD](https:/redis.io/docs/latest/commands/module-load)
    /// - Version: 4.0.0
    /// - Complexity: O(1)
    /// - Categories: @admin, @slow, @dangerous
    /// - Response: [Simple string](https:/redis.io/docs/reference/protocol-spec#simple-strings): `OK` if the module was loaded.
    @inlinable
    public static func moduleLoad(path: String, args: [String]) -> RESPCommand {
        RESPCommand("MODULE", "LOAD", path, args)
    }

    public struct MODULELOADEXConfigs: RESPRenderable {
        @usableFromInline let name: String
        @usableFromInline let value: String

        @inlinable
        public func writeToRESPBuffer(_ buffer: inout ByteBuffer) -> Int {
            var count = 0
            count += self.name.writeToRESPBuffer(&buffer)
            count += self.value.writeToRESPBuffer(&buffer)
            return count
        }
    }
    /// Loads a module using extended parameters.
    ///
    /// - Documentation: [MODULE LOADEX](https:/redis.io/docs/latest/commands/module-loadex)
    /// - Version: 7.0.0
    /// - Complexity: O(1)
    /// - Categories: @admin, @slow, @dangerous
    /// - Response: [Simple string](https:/redis.io/docs/reference/protocol-spec#simple-strings): `OK` if the module was loaded.
    @inlinable
    public static func moduleLoadex(path: String, configs: MODULELOADEXConfigs? = nil, args: String? = nil) -> RESPCommand {
        RESPCommand("MODULE", "LOADEX", path, RESPWithToken("CONFIG", configs), RESPWithToken("ARGS", args))
    }

    /// Loads a module using extended parameters.
    ///
    /// - Documentation: [MODULE LOADEX](https:/redis.io/docs/latest/commands/module-loadex)
    /// - Version: 7.0.0
    /// - Complexity: O(1)
    /// - Categories: @admin, @slow, @dangerous
    /// - Response: [Simple string](https:/redis.io/docs/reference/protocol-spec#simple-strings): `OK` if the module was loaded.
    @inlinable
    public static func moduleLoadex(path: String, configss: [MODULELOADEXConfigs], argss: [String]) -> RESPCommand {
        RESPCommand("MODULE", "LOADEX", path, RESPWithToken("CONFIG", configss), RESPWithToken("ARGS", argss))
    }

    /// Unloads a module.
    ///
    /// - Documentation: [MODULE UNLOAD](https:/redis.io/docs/latest/commands/module-unload)
    /// - Version: 4.0.0
    /// - Complexity: O(1)
    /// - Categories: @admin, @slow, @dangerous
    /// - Response: [Simple string](https:/redis.io/docs/reference/protocol-spec#simple-strings): `OK` if the module was unloaded.
    @inlinable
    public static func moduleUnload(name: String) -> RESPCommand {
        RESPCommand("MODULE", "UNLOAD", name)
    }

    /// Listens for all requests received by the server in real-time.
    ///
    /// - Documentation: [MONITOR](https:/redis.io/docs/latest/commands/monitor)
    /// - Version: 1.0.0
    /// - Categories: @admin, @slow, @dangerous
    /// - Response: **Non-standard return value**. Dumps the received commands in an infinite flow.
    @inlinable
    public static func monitor() -> RESPCommand {
        RESPCommand("MONITOR")
    }

    /// Moves a key to another database.
    ///
    /// - Documentation: [MOVE](https:/redis.io/docs/latest/commands/move)
    /// - Version: 1.0.0
    /// - Complexity: O(1)
    /// - Categories: @keyspace, @write, @fast
    /// - Response: One of the following:
    ///     * [Integer](https:/redis.io/docs/reference/protocol-spec#integers): `1` if _key_ was moved.
    ///     * [Integer](https:/redis.io/docs/reference/protocol-spec#integers): `0` if _key_ wasn't moved.
    @inlinable
    public static func move(key: RedisKey, db: Int) -> RESPCommand {
        RESPCommand("MOVE", key, db)
    }

    public struct MSETData: RESPRenderable {
        @usableFromInline let key: RedisKey
        @usableFromInline let value: String

        @inlinable
        public func writeToRESPBuffer(_ buffer: inout ByteBuffer) -> Int {
            var count = 0
            count += self.key.writeToRESPBuffer(&buffer)
            count += self.value.writeToRESPBuffer(&buffer)
            return count
        }
    }
    /// Atomically creates or modifies the string values of one or more keys.
    ///
    /// - Documentation: [MSET](https:/redis.io/docs/latest/commands/mset)
    /// - Version: 1.0.1
    /// - Complexity: O(N) where N is the number of keys to set.
    /// - Categories: @write, @string, @slow
    /// - Response: [Simple string](https:/redis.io/docs/reference/protocol-spec#simple-strings): always `OK` because `MSET` can't fail.
    @inlinable
    public static func mset(data: MSETData) -> RESPCommand {
        RESPCommand("MSET", data)
    }

    /// Atomically creates or modifies the string values of one or more keys.
    ///
    /// - Documentation: [MSET](https:/redis.io/docs/latest/commands/mset)
    /// - Version: 1.0.1
    /// - Complexity: O(N) where N is the number of keys to set.
    /// - Categories: @write, @string, @slow
    /// - Response: [Simple string](https:/redis.io/docs/reference/protocol-spec#simple-strings): always `OK` because `MSET` can't fail.
    @inlinable
    public static func mset(datas: [MSETData]) -> RESPCommand {
        RESPCommand("MSET", datas)
    }

    public struct MSETNXData: RESPRenderable {
        @usableFromInline let key: RedisKey
        @usableFromInline let value: String

        @inlinable
        public func writeToRESPBuffer(_ buffer: inout ByteBuffer) -> Int {
            var count = 0
            count += self.key.writeToRESPBuffer(&buffer)
            count += self.value.writeToRESPBuffer(&buffer)
            return count
        }
    }
    /// Atomically modifies the string values of one or more keys only when all keys don't exist.
    ///
    /// - Documentation: [MSETNX](https:/redis.io/docs/latest/commands/msetnx)
    /// - Version: 1.0.1
    /// - Complexity: O(N) where N is the number of keys to set.
    /// - Categories: @write, @string, @slow
    /// - Response: One of the following:
    ///     * [Integer](https:/redis.io/docs/reference/protocol-spec#integers): `0` if no key was set (at least one key already existed).
    ///     * [Integer](https:/redis.io/docs/reference/protocol-spec#integers): `1` if all the keys were set.
    @inlinable
    public static func msetnx(data: MSETNXData) -> RESPCommand {
        RESPCommand("MSETNX", data)
    }

    /// Atomically modifies the string values of one or more keys only when all keys don't exist.
    ///
    /// - Documentation: [MSETNX](https:/redis.io/docs/latest/commands/msetnx)
    /// - Version: 1.0.1
    /// - Complexity: O(N) where N is the number of keys to set.
    /// - Categories: @write, @string, @slow
    /// - Response: One of the following:
    ///     * [Integer](https:/redis.io/docs/reference/protocol-spec#integers): `0` if no key was set (at least one key already existed).
    ///     * [Integer](https:/redis.io/docs/reference/protocol-spec#integers): `1` if all the keys were set.
    @inlinable
    public static func msetnx(datas: [MSETNXData]) -> RESPCommand {
        RESPCommand("MSETNX", datas)
    }

    /// Starts a transaction.
    ///
    /// - Documentation: [MULTI](https:/redis.io/docs/latest/commands/multi)
    /// - Version: 1.2.0
    /// - Complexity: O(1)
    /// - Categories: @fast, @transaction
    /// - Response: [Simple string](https:/redis.io/docs/reference/protocol-spec#simple-strings): `OK`.
    @inlinable
    public static func multi() -> RESPCommand {
        RESPCommand("MULTI")
    }

    /// Returns the internal encoding of a Redis object.
    ///
    /// - Documentation: [OBJECT ENCODING](https:/redis.io/docs/latest/commands/object-encoding)
    /// - Version: 2.2.3
    /// - Complexity: O(1)
    /// - Categories: @keyspace, @read, @slow
    /// - Response: One of the following:
    ///     * [Null](https:/redis.io/docs/reference/protocol-spec#nulls): if the key doesn't exist.
    ///     * [Bulk string](https:/redis.io/docs/reference/protocol-spec#bulk-strings): the encoding of the object.
    @inlinable
    public static func objectEncoding(key: RedisKey) -> RESPCommand {
        RESPCommand("OBJECT", "ENCODING", key)
    }

    /// Returns the logarithmic access frequency counter of a Redis object.
    ///
    /// - Documentation: [OBJECT FREQ](https:/redis.io/docs/latest/commands/object-freq)
    /// - Version: 4.0.0
    /// - Complexity: O(1)
    /// - Categories: @keyspace, @read, @slow
    /// - Response: One of the following:
    ///     [Integer](https:/redis.io/docs/reference/protocol-spec#integers): the counter's value.
    ///     [Null](https:/redis.io/docs/reference/protocol-spec#nulls): if _key_ doesn't exist.
    @inlinable
    public static func objectFreq(key: RedisKey) -> RESPCommand {
        RESPCommand("OBJECT", "FREQ", key)
    }

    /// Returns helpful text about the different subcommands.
    ///
    /// - Documentation: [OBJECT HELP](https:/redis.io/docs/latest/commands/object-help)
    /// - Version: 6.2.0
    /// - Complexity: O(1)
    /// - Categories: @keyspace, @slow
    /// - Response: [Array](https:/redis.io/docs/reference/protocol-spec#arrays): a list of sub-commands and their descriptions.
    @inlinable
    public static func objectHelp() -> RESPCommand {
        RESPCommand("OBJECT", "HELP")
    }

    /// Returns the time since the last access to a Redis object.
    ///
    /// - Documentation: [OBJECT IDLETIME](https:/redis.io/docs/latest/commands/object-idletime)
    /// - Version: 2.2.3
    /// - Complexity: O(1)
    /// - Categories: @keyspace, @read, @slow
    /// - Response: One of the following:
    ///     [Integer](https:/redis.io/docs/reference/protocol-spec#integers): the idle time in seconds.
    ///     [Null](https:/redis.io/docs/reference/protocol-spec#nulls): if _key_ doesn't exist.
    @inlinable
    public static func objectIdletime(key: RedisKey) -> RESPCommand {
        RESPCommand("OBJECT", "IDLETIME", key)
    }

    /// Returns the reference count of a value of a key.
    ///
    /// - Documentation: [OBJECT REFCOUNT](https:/redis.io/docs/latest/commands/object-refcount)
    /// - Version: 2.2.3
    /// - Complexity: O(1)
    /// - Categories: @keyspace, @read, @slow
    /// - Response: One of the following:
    ///     [Integer](https:/redis.io/docs/reference/protocol-spec#integers): the number of references.
    ///     [Null](https:/redis.io/docs/reference/protocol-spec#nulls): if _key_ doesn't exist.
    @inlinable
    public static func objectRefcount(key: RedisKey) -> RESPCommand {
        RESPCommand("OBJECT", "REFCOUNT", key)
    }

    /// Removes the expiration time of a key.
    ///
    /// - Documentation: [PERSIST](https:/redis.io/docs/latest/commands/persist)
    /// - Version: 2.2.0
    /// - Complexity: O(1)
    /// - Categories: @keyspace, @write, @fast
    /// - Response: One of the following:
    ///     * [Integer](https:/redis.io/docs/reference/protocol-spec#integers): `0` if _key_ does not exist or does not have an associated timeout.
    ///     * [Integer](https:/redis.io/docs/reference/protocol-spec#integers): `1` if the timeout has been removed.
    @inlinable
    public static func persist(key: RedisKey) -> RESPCommand {
        RESPCommand("PERSIST", key)
    }

    public enum PEXPIRECondition: RESPRenderable {
        case nx
        case xx
        case gt
        case lt

        @inlinable
        public func writeToRESPBuffer(_ buffer: inout ByteBuffer) -> Int {
            switch self {
            case .nx: "NX".writeToRESPBuffer(&buffer)
            case .xx: "XX".writeToRESPBuffer(&buffer)
            case .gt: "GT".writeToRESPBuffer(&buffer)
            case .lt: "LT".writeToRESPBuffer(&buffer)
            }
        }
    }
    /// Sets the expiration time of a key in milliseconds.
    ///
    /// - Documentation: [PEXPIRE](https:/redis.io/docs/latest/commands/pexpire)
    /// - Version: 2.6.0
    /// - Complexity: O(1)
    /// - Categories: @keyspace, @write, @fast
    /// - Response: One of the following:
    ///     * [Integer](https:/redis.io/docs/reference/protocol-spec#integers): `0`if the timeout was not set. For example, if the key doesn't exist, or the operation skipped because of the provided arguments.
    ///     * [Integer](https:/redis.io/docs/reference/protocol-spec#integers): `1` if the timeout was set.
    @inlinable
    public static func pexpire(key: RedisKey, milliseconds: Int, condition: PEXPIRECondition? = nil) -> RESPCommand {
        RESPCommand("PEXPIRE", key, milliseconds, condition)
    }

    public enum PEXPIREATCondition: RESPRenderable {
        case nx
        case xx
        case gt
        case lt

        @inlinable
        public func writeToRESPBuffer(_ buffer: inout ByteBuffer) -> Int {
            switch self {
            case .nx: "NX".writeToRESPBuffer(&buffer)
            case .xx: "XX".writeToRESPBuffer(&buffer)
            case .gt: "GT".writeToRESPBuffer(&buffer)
            case .lt: "LT".writeToRESPBuffer(&buffer)
            }
        }
    }
    /// Sets the expiration time of a key to a Unix milliseconds timestamp.
    ///
    /// - Documentation: [PEXPIREAT](https:/redis.io/docs/latest/commands/pexpireat)
    /// - Version: 2.6.0
    /// - Complexity: O(1)
    /// - Categories: @keyspace, @write, @fast
    /// - Response: One of the following:
    ///     * [Integer](https:/redis.io/docs/reference/protocol-spec#integers): `1` if the timeout was set.
    ///     * [Integer](https:/redis.io/docs/reference/protocol-spec#integers): `0` if the timeout was not set. For example, if the key doesn't exist, or the operation was skipped due to the provided arguments.
    @inlinable
    public static func pexpireat(key: RedisKey, unixTimeMilliseconds: Date, condition: PEXPIREATCondition? = nil) -> RESPCommand {
        RESPCommand("PEXPIREAT", key, unixTimeMilliseconds, condition)
    }

    /// Returns the expiration time of a key as a Unix milliseconds timestamp.
    ///
    /// - Documentation: [PEXPIRETIME](https:/redis.io/docs/latest/commands/pexpiretime)
    /// - Version: 7.0.0
    /// - Complexity: O(1)
    /// - Categories: @keyspace, @read, @fast
    /// - Response: One of the following:
    ///     * [Integer](https:/redis.io/docs/reference/protocol-spec#integers): Expiration Unix timestamp in milliseconds.
    ///     * [Integer](https:/redis.io/docs/reference/protocol-spec#integers): `-1` if the key exists but has no associated expiration time.
    ///     * [Integer](https:/redis.io/docs/reference/protocol-spec#integers): `-2` if the key does not exist.
    @inlinable
    public static func pexpiretime(key: RedisKey) -> RESPCommand {
        RESPCommand("PEXPIRETIME", key)
    }

    /// Adds elements to a HyperLogLog key. Creates the key if it doesn't exist.
    ///
    /// - Documentation: [PFADD](https:/redis.io/docs/latest/commands/pfadd)
    /// - Version: 2.8.9
    /// - Complexity: O(1) to add every element.
    /// - Categories: @write, @hyperloglog, @fast
    /// - Response: One of the following:
    ///     * [Integer](https:/redis.io/docs/reference/protocol-spec#integers): `1` if at least one HyperLogLog internal register was altered.
    ///     * [Integer](https:/redis.io/docs/reference/protocol-spec#integers): `0` if no HyperLogLog internal registers were altered.
    @inlinable
    public static func pfadd(key: RedisKey, element: String? = nil) -> RESPCommand {
        RESPCommand("PFADD", key, element)
    }

    /// Adds elements to a HyperLogLog key. Creates the key if it doesn't exist.
    ///
    /// - Documentation: [PFADD](https:/redis.io/docs/latest/commands/pfadd)
    /// - Version: 2.8.9
    /// - Complexity: O(1) to add every element.
    /// - Categories: @write, @hyperloglog, @fast
    /// - Response: One of the following:
    ///     * [Integer](https:/redis.io/docs/reference/protocol-spec#integers): `1` if at least one HyperLogLog internal register was altered.
    ///     * [Integer](https:/redis.io/docs/reference/protocol-spec#integers): `0` if no HyperLogLog internal registers were altered.
    @inlinable
    public static func pfadd(key: RedisKey, elements: [String]) -> RESPCommand {
        RESPCommand("PFADD", key, elements)
    }

    /// Returns the approximated cardinality of the set(s) observed by the HyperLogLog key(s).
    ///
    /// - Documentation: [PFCOUNT](https:/redis.io/docs/latest/commands/pfcount)
    /// - Version: 2.8.9
    /// - Complexity: O(1) with a very small average constant time when called with a single key. O(N) with N being the number of keys, and much bigger constant times, when called with multiple keys.
    /// - Categories: @read, @hyperloglog, @slow
    /// - Response: [Integer](https:/redis.io/docs/reference/protocol-spec#integers): the approximated number of unique elements observed via `PFADD`
    @inlinable
    public static func pfcount(key: RedisKey) -> RESPCommand {
        RESPCommand("PFCOUNT", key)
    }

    /// Returns the approximated cardinality of the set(s) observed by the HyperLogLog key(s).
    ///
    /// - Documentation: [PFCOUNT](https:/redis.io/docs/latest/commands/pfcount)
    /// - Version: 2.8.9
    /// - Complexity: O(1) with a very small average constant time when called with a single key. O(N) with N being the number of keys, and much bigger constant times, when called with multiple keys.
    /// - Categories: @read, @hyperloglog, @slow
    /// - Response: [Integer](https:/redis.io/docs/reference/protocol-spec#integers): the approximated number of unique elements observed via `PFADD`
    @inlinable
    public static func pfcount(keys: [RedisKey]) -> RESPCommand {
        RESPCommand("PFCOUNT", keys)
    }

    /// Merges one or more HyperLogLog values into a single key.
    ///
    /// - Documentation: [PFMERGE](https:/redis.io/docs/latest/commands/pfmerge)
    /// - Version: 2.8.9
    /// - Complexity: O(N) to merge N HyperLogLogs, but with high constant times.
    /// - Categories: @write, @hyperloglog, @slow
    /// - Response: [Simple string](https:/redis.io/docs/reference/protocol-spec#simple-strings): `OK`.
    @inlinable
    public static func pfmerge(destkey: RedisKey, sourcekey: RedisKey? = nil) -> RESPCommand {
        RESPCommand("PFMERGE", destkey, sourcekey)
    }

    /// Merges one or more HyperLogLog values into a single key.
    ///
    /// - Documentation: [PFMERGE](https:/redis.io/docs/latest/commands/pfmerge)
    /// - Version: 2.8.9
    /// - Complexity: O(N) to merge N HyperLogLogs, but with high constant times.
    /// - Categories: @write, @hyperloglog, @slow
    /// - Response: [Simple string](https:/redis.io/docs/reference/protocol-spec#simple-strings): `OK`.
    @inlinable
    public static func pfmerge(destkey: RedisKey, sourcekeys: [RedisKey]) -> RESPCommand {
        RESPCommand("PFMERGE", destkey, sourcekeys)
    }

    /// An internal command for testing HyperLogLog values.
    ///
    /// - Documentation: [PFSELFTEST](https:/redis.io/docs/latest/commands/pfselftest)
    /// - Version: 2.8.9
    /// - Complexity: N/A
    /// - Categories: @hyperloglog, @admin, @slow, @dangerous
    /// - Response: [Simple string](https:/redis.io/docs/reference/protocol-spec#simple-strings): `OK`.
    @inlinable
    public static func pfselftest() -> RESPCommand {
        RESPCommand("PFSELFTEST")
    }

    /// Returns the server's liveliness response.
    ///
    /// - Documentation: [PING](https:/redis.io/docs/latest/commands/ping)
    /// - Version: 1.0.0
    /// - Complexity: O(1)
    /// - Categories: @fast, @connection
    /// - Response: Any of the following:
    ///     * [Simple string](https:/redis.io/docs/reference/protocol-spec#simple-strings): `PONG` when no argument is provided.
    ///     * [Bulk string](https:/redis.io/docs/reference/protocol-spec#bulk-strings): the provided argument.
    @inlinable
    public static func ping(message: String? = nil) -> RESPCommand {
        RESPCommand("PING", message)
    }

    /// Sets both string value and expiration time in milliseconds of a key. The key is created if it doesn't exist.
    ///
    /// - Documentation: [PSETEX](https:/redis.io/docs/latest/commands/psetex)
    /// - Version: 2.6.0
    /// - Complexity: O(1)
    /// - Categories: @write, @string, @slow
    /// - Response: [Simple string](https:/redis.io/docs/reference/protocol-spec#simple-strings): `OK`.
    @inlinable
    public static func psetex(key: RedisKey, milliseconds: Int, value: String) -> RESPCommand {
        RESPCommand("PSETEX", key, milliseconds, value)
    }

    /// Listens for messages published to channels that match one or more patterns.
    ///
    /// - Documentation: [PSUBSCRIBE](https:/redis.io/docs/latest/commands/psubscribe)
    /// - Version: 2.0.0
    /// - Complexity: O(N) where N is the number of patterns to subscribe to.
    /// - Categories: @pubsub, @slow
    /// - Response: When successful, this command doesn't return anything. Instead, for each pattern, one message with the first element being the string `psubscribe` is pushed as a confirmation that the command succeeded.
    @inlinable
    public static func psubscribe(pattern: String) -> RESPCommand {
        RESPCommand("PSUBSCRIBE", pattern)
    }

    /// Listens for messages published to channels that match one or more patterns.
    ///
    /// - Documentation: [PSUBSCRIBE](https:/redis.io/docs/latest/commands/psubscribe)
    /// - Version: 2.0.0
    /// - Complexity: O(N) where N is the number of patterns to subscribe to.
    /// - Categories: @pubsub, @slow
    /// - Response: When successful, this command doesn't return anything. Instead, for each pattern, one message with the first element being the string `psubscribe` is pushed as a confirmation that the command succeeded.
    @inlinable
    public static func psubscribe(patterns: [String]) -> RESPCommand {
        RESPCommand("PSUBSCRIBE", patterns)
    }

    /// An internal command used in replication.
    ///
    /// - Documentation: [PSYNC](https:/redis.io/docs/latest/commands/psync)
    /// - Version: 2.8.0
    /// - Categories: @admin, @slow, @dangerous
    /// - Response: **Non-standard return value**, a bulk transfer of the data followed by `PING` and write requests from the master.
    @inlinable
    public static func psync(replicationid: String, offset: Int) -> RESPCommand {
        RESPCommand("PSYNC", replicationid, offset)
    }

    /// Returns the expiration time in milliseconds of a key.
    ///
    /// - Documentation: [PTTL](https:/redis.io/docs/latest/commands/pttl)
    /// - Version: 2.6.0
    /// - Complexity: O(1)
    /// - Categories: @keyspace, @read, @fast
    /// - Response: One of the following:
    ///     * [Integer](https:/redis.io/docs/reference/protocol-spec#integers): TTL in milliseconds.
    ///     * [Integer](https:/redis.io/docs/reference/protocol-spec#integers): `-1` if the key exists but has no associated expiration.
    ///     * [Integer](https:/redis.io/docs/reference/protocol-spec#integers): `-2` if the key does not exist.
    @inlinable
    public static func pttl(key: RedisKey) -> RESPCommand {
        RESPCommand("PTTL", key)
    }

    /// Posts a message to a channel.
    ///
    /// - Documentation: [PUBLISH](https:/redis.io/docs/latest/commands/publish)
    /// - Version: 2.0.0
    /// - Complexity: O(N+M) where N is the number of clients subscribed to the receiving channel and M is the total number of subscribed patterns (by any client).
    /// - Categories: @pubsub, @fast
    /// - Response: [Integer](https:/redis.io/docs/reference/protocol-spec#integers): the number of clients that received the message. Note that in a Redis Cluster, only clients that are connected to the same node as the publishing client are included in the count.
    @inlinable
    public static func publish(channel: String, message: String) -> RESPCommand {
        RESPCommand("PUBLISH", channel, message)
    }

    /// Returns the active channels.
    ///
    /// - Documentation: [PUBSUB CHANNELS](https:/redis.io/docs/latest/commands/pubsub-channels)
    /// - Version: 2.8.0
    /// - Complexity: O(N) where N is the number of active channels, and assuming constant time pattern matching (relatively short channels and patterns)
    /// - Categories: @pubsub, @slow
    /// - Response: [Array](https:/redis.io/docs/reference/protocol-spec#arrays): a list of active channels, optionally matching the specified pattern.
    @inlinable
    public static func pubsubChannels(pattern: String? = nil) -> RESPCommand {
        RESPCommand("PUBSUB", "CHANNELS", pattern)
    }

    /// Returns helpful text about the different subcommands.
    ///
    /// - Documentation: [PUBSUB HELP](https:/redis.io/docs/latest/commands/pubsub-help)
    /// - Version: 6.2.0
    /// - Complexity: O(1)
    /// - Categories: @slow
    /// - Response: [Array](https:/redis.io/docs/reference/protocol-spec#arrays): a list of sub-commands and their descriptions.
    @inlinable
    public static func pubsubHelp() -> RESPCommand {
        RESPCommand("PUBSUB", "HELP")
    }

    /// Returns a count of unique pattern subscriptions.
    ///
    /// - Documentation: [PUBSUB NUMPAT](https:/redis.io/docs/latest/commands/pubsub-numpat)
    /// - Version: 2.8.0
    /// - Complexity: O(1)
    /// - Categories: @pubsub, @slow
    /// - Response: [Integer](https:/redis.io/docs/reference/protocol-spec#integers): the number of patterns all the clients are subscribed to.
    @inlinable
    public static func pubsubNumpat() -> RESPCommand {
        RESPCommand("PUBSUB", "NUMPAT")
    }

    /// Returns a count of subscribers to channels.
    ///
    /// - Documentation: [PUBSUB NUMSUB](https:/redis.io/docs/latest/commands/pubsub-numsub)
    /// - Version: 2.8.0
    /// - Complexity: O(N) for the NUMSUB subcommand, where N is the number of requested channels
    /// - Categories: @pubsub, @slow
    /// - Response: [Array](https:/redis.io/docs/reference/protocol-spec#arrays): the number of subscribers per channel, each even element (including the 0th) is channel name, each odd element is the number of subscribers
    @inlinable
    public static func pubsubNumsub(channel: String? = nil) -> RESPCommand {
        RESPCommand("PUBSUB", "NUMSUB", channel)
    }

    /// Returns a count of subscribers to channels.
    ///
    /// - Documentation: [PUBSUB NUMSUB](https:/redis.io/docs/latest/commands/pubsub-numsub)
    /// - Version: 2.8.0
    /// - Complexity: O(N) for the NUMSUB subcommand, where N is the number of requested channels
    /// - Categories: @pubsub, @slow
    /// - Response: [Array](https:/redis.io/docs/reference/protocol-spec#arrays): the number of subscribers per channel, each even element (including the 0th) is channel name, each odd element is the number of subscribers
    @inlinable
    public static func pubsubNumsub(channels: [String]) -> RESPCommand {
        RESPCommand("PUBSUB", "NUMSUB", channels)
    }

    /// Returns the active shard channels.
    ///
    /// - Documentation: [PUBSUB SHARDCHANNELS](https:/redis.io/docs/latest/commands/pubsub-shardchannels)
    /// - Version: 7.0.0
    /// - Complexity: O(N) where N is the number of active shard channels, and assuming constant time pattern matching (relatively short shard channels).
    /// - Categories: @pubsub, @slow
    /// - Response: [Array](https:/redis.io/docs/reference/protocol-spec#arrays): a list of active channels, optionally matching the specified pattern.
    @inlinable
    public static func pubsubShardchannels(pattern: String? = nil) -> RESPCommand {
        RESPCommand("PUBSUB", "SHARDCHANNELS", pattern)
    }

    /// Returns the count of subscribers of shard channels.
    ///
    /// - Documentation: [PUBSUB SHARDNUMSUB](https:/redis.io/docs/latest/commands/pubsub-shardnumsub)
    /// - Version: 7.0.0
    /// - Complexity: O(N) for the SHARDNUMSUB subcommand, where N is the number of requested shard channels
    /// - Categories: @pubsub, @slow
    /// - Response: [Array](https:/redis.io/docs/reference/protocol-spec#arrays): the number of subscribers per shard channel, each even element (including the 0th) is channel name, each odd element is the number of subscribers.
    @inlinable
    public static func pubsubShardnumsub(shardchannel: String? = nil) -> RESPCommand {
        RESPCommand("PUBSUB", "SHARDNUMSUB", shardchannel)
    }

    /// Returns the count of subscribers of shard channels.
    ///
    /// - Documentation: [PUBSUB SHARDNUMSUB](https:/redis.io/docs/latest/commands/pubsub-shardnumsub)
    /// - Version: 7.0.0
    /// - Complexity: O(N) for the SHARDNUMSUB subcommand, where N is the number of requested shard channels
    /// - Categories: @pubsub, @slow
    /// - Response: [Array](https:/redis.io/docs/reference/protocol-spec#arrays): the number of subscribers per shard channel, each even element (including the 0th) is channel name, each odd element is the number of subscribers.
    @inlinable
    public static func pubsubShardnumsub(shardchannels: [String]) -> RESPCommand {
        RESPCommand("PUBSUB", "SHARDNUMSUB", shardchannels)
    }

    /// Stops listening to messages published to channels that match one or more patterns.
    ///
    /// - Documentation: [PUNSUBSCRIBE](https:/redis.io/docs/latest/commands/punsubscribe)
    /// - Version: 2.0.0
    /// - Complexity: O(N) where N is the number of patterns to unsubscribe.
    /// - Categories: @pubsub, @slow
    /// - Response: When successful, this command doesn't return anything. Instead, for each pattern, one message with the first element being the string `punsubscribe` is pushed as a confirmation that the command succeeded.
    @inlinable
    public static func punsubscribe(pattern: String? = nil) -> RESPCommand {
        RESPCommand("PUNSUBSCRIBE", pattern)
    }

    /// Stops listening to messages published to channels that match one or more patterns.
    ///
    /// - Documentation: [PUNSUBSCRIBE](https:/redis.io/docs/latest/commands/punsubscribe)
    /// - Version: 2.0.0
    /// - Complexity: O(N) where N is the number of patterns to unsubscribe.
    /// - Categories: @pubsub, @slow
    /// - Response: When successful, this command doesn't return anything. Instead, for each pattern, one message with the first element being the string `punsubscribe` is pushed as a confirmation that the command succeeded.
    @inlinable
    public static func punsubscribe(patterns: [String]) -> RESPCommand {
        RESPCommand("PUNSUBSCRIBE", patterns)
    }

    /// Closes the connection.
    ///
    /// - Documentation: [QUIT](https:/redis.io/docs/latest/commands/quit)
    /// - Version: 1.0.0
    /// - Complexity: O(1)
    /// - Categories: @fast, @connection
    /// - Response: [Simple string](https:/redis.io/docs/reference/protocol-spec#simple-strings): `OK`.
    @inlinable
    public static func quit() -> RESPCommand {
        RESPCommand("QUIT")
    }

    /// Returns a random key name from the database.
    ///
    /// - Documentation: [RANDOMKEY](https:/redis.io/docs/latest/commands/randomkey)
    /// - Version: 1.0.0
    /// - Complexity: O(1)
    /// - Categories: @keyspace, @read, @slow
    /// - Response: One of the following:
    ///     * [Null](https:/redis.io/docs/reference/protocol-spec#nulls): when the database is empty.
    ///     * [Bulk string](https:/redis.io/docs/reference/protocol-spec#bulk-strings): a random key in the database.
    @inlinable
    public static func randomkey() -> RESPCommand {
        RESPCommand("RANDOMKEY")
    }

    /// Enables read-only queries for a connection to a Redis Cluster replica node.
    ///
    /// - Documentation: [READONLY](https:/redis.io/docs/latest/commands/readonly)
    /// - Version: 3.0.0
    /// - Complexity: O(1)
    /// - Categories: @fast, @connection
    /// - Response: [Simple string](https:/redis.io/docs/reference/protocol-spec#simple-strings): `OK`.
    @inlinable
    public static func readonly() -> RESPCommand {
        RESPCommand("READONLY")
    }

    /// Enables read-write queries for a connection to a Reids Cluster replica node.
    ///
    /// - Documentation: [READWRITE](https:/redis.io/docs/latest/commands/readwrite)
    /// - Version: 3.0.0
    /// - Complexity: O(1)
    /// - Categories: @fast, @connection
    /// - Response: [Simple string](https:/redis.io/docs/reference/protocol-spec#simple-strings): `OK`.
    @inlinable
    public static func readwrite() -> RESPCommand {
        RESPCommand("READWRITE")
    }

    /// Renames a key and overwrites the destination.
    ///
    /// - Documentation: [RENAME](https:/redis.io/docs/latest/commands/rename)
    /// - Version: 1.0.0
    /// - Complexity: O(1)
    /// - Categories: @keyspace, @write, @slow
    /// - Response: [Simple string](https:/redis.io/docs/reference/protocol-spec#simple-strings): `OK`.
    @inlinable
    public static func rename(key: RedisKey, newkey: RedisKey) -> RESPCommand {
        RESPCommand("RENAME", key, newkey)
    }

    /// Renames a key only when the target key name doesn't exist.
    ///
    /// - Documentation: [RENAMENX](https:/redis.io/docs/latest/commands/renamenx)
    /// - Version: 1.0.0
    /// - Complexity: O(1)
    /// - Categories: @keyspace, @write, @fast
    /// - Response: One of the following:
    ///     * [Integer](https:/redis.io/docs/reference/protocol-spec#integers): `1` if _key_ was renamed to _newkey_.
    ///     * [Integer](https:/redis.io/docs/reference/protocol-spec#integers): `0` if _newkey_ already exists.
    @inlinable
    public static func renamenx(key: RedisKey, newkey: RedisKey) -> RESPCommand {
        RESPCommand("RENAMENX", key, newkey)
    }

    /// An internal command for configuring the replication stream.
    ///
    /// - Documentation: [REPLCONF](https:/redis.io/docs/latest/commands/replconf)
    /// - Version: 3.0.0
    /// - Complexity: O(1)
    /// - Categories: @admin, @slow, @dangerous
    /// - Response: [Simple string](https:/redis.io/docs/reference/protocol-spec#simple-strings): `OK`.
    @inlinable
    public static func replconf() -> RESPCommand {
        RESPCommand("REPLCONF")
    }

    public struct REPLICAOFArgsHostPort: RESPRenderable {
        @usableFromInline let host: String
        @usableFromInline let port: Int

        @inlinable
        public func writeToRESPBuffer(_ buffer: inout ByteBuffer) -> Int {
            var count = 0
            count += self.host.writeToRESPBuffer(&buffer)
            count += self.port.writeToRESPBuffer(&buffer)
            return count
        }
    }
    public struct REPLICAOFArgsNoOne: RESPRenderable {
        @usableFromInline let no: Bool
        @usableFromInline let one: Bool

        @inlinable
        public func writeToRESPBuffer(_ buffer: inout ByteBuffer) -> Int {
            var count = 0
            if self.no { count += "NO".writeToRESPBuffer(&buffer) }
            if self.one { count += "ONE".writeToRESPBuffer(&buffer) }
            return count
        }
    }
    public enum REPLICAOFArgs: RESPRenderable {
        case hostPort(REPLICAOFArgsHostPort)
        case noOne(REPLICAOFArgsNoOne)

        @inlinable
        public func writeToRESPBuffer(_ buffer: inout ByteBuffer) -> Int {
            switch self {
            case .hostPort(let hostPort): hostPort.writeToRESPBuffer(&buffer)
            case .noOne(let noOne): noOne.writeToRESPBuffer(&buffer)
            }
        }
    }
    /// Configures a server as replica of another, or promotes it to a master.
    ///
    /// - Documentation: [REPLICAOF](https:/redis.io/docs/latest/commands/replicaof)
    /// - Version: 5.0.0
    /// - Complexity: O(1)
    /// - Categories: @admin, @slow, @dangerous
    /// - Response: [Simple string](https:/redis.io/docs/reference/protocol-spec#simple-strings): `OK`.
    @inlinable
    public static func replicaof(args: REPLICAOFArgs) -> RESPCommand {
        RESPCommand("REPLICAOF", args)
    }

    /// Resets the connection.
    ///
    /// - Documentation: [RESET](https:/redis.io/docs/latest/commands/reset)
    /// - Version: 6.2.0
    /// - Complexity: O(1)
    /// - Categories: @fast, @connection
    /// - Response: [Simple string](https:/redis.io/docs/reference/protocol-spec#simple-strings): `RESET`.
    @inlinable
    public static func reset() -> RESPCommand {
        RESPCommand("RESET")
    }

    /// Creates a key from the serialized representation of a value.
    ///
    /// - Documentation: [RESTORE](https:/redis.io/docs/latest/commands/restore)
    /// - Version: 2.6.0
    /// - Complexity: O(1) to create the new key and additional O(N*M) to reconstruct the serialized value, where N is the number of Redis objects composing the value and M their average size. For small string values the time complexity is thus O(1)+O(1*M) where M is small, so simply O(1). However for sorted set values the complexity is O(N*M*log(N)) because inserting values into sorted sets is O(log(N)).
    /// - Categories: @keyspace, @write, @slow, @dangerous
    /// - Response: [Simple string](https:/redis.io/docs/reference/protocol-spec#simple-strings): `OK`.
    @inlinable
    public static func restore(key: RedisKey, ttl: Int, serializedValue: String, replace: Bool = false, absttl: Bool = false, seconds: Int? = nil, frequency: Int? = nil) -> RESPCommand {
        RESPCommand("RESTORE", key, ttl, serializedValue, RedisPureToken("REPLACE", replace), RedisPureToken("ABSTTL", absttl), RESPWithToken("IDLETIME", seconds), RESPWithToken("FREQ", frequency))
    }

    /// An internal command for migrating keys in a cluster.
    ///
    /// - Documentation: [RESTORE-ASKING](https:/redis.io/docs/latest/commands/restore-asking)
    /// - Version: 3.0.0
    /// - Complexity: O(1) to create the new key and additional O(N*M) to reconstruct the serialized value, where N is the number of Redis objects composing the value and M their average size. For small string values the time complexity is thus O(1)+O(1*M) where M is small, so simply O(1). However for sorted set values the complexity is O(N*M*log(N)) because inserting values into sorted sets is O(log(N)).
    /// - Categories: @keyspace, @write, @slow, @dangerous
    /// - Response: [Simple string](https:/redis.io/docs/reference/protocol-spec#simple-strings): `OK`.
    @inlinable
    public static func restoreAsking(key: RedisKey, ttl: Int, serializedValue: String, replace: Bool = false, absttl: Bool = false, seconds: Int? = nil, frequency: Int? = nil) -> RESPCommand {
        RESPCommand("RESTORE-ASKING", key, ttl, serializedValue, RedisPureToken("REPLACE", replace), RedisPureToken("ABSTTL", absttl), RESPWithToken("IDLETIME", seconds), RESPWithToken("FREQ", frequency))
    }

    /// Returns the replication role.
    ///
    /// - Documentation: [ROLE](https:/redis.io/docs/latest/commands/role)
    /// - Version: 2.8.12
    /// - Complexity: O(1)
    /// - Categories: @admin, @fast, @dangerous
    /// - Response: [Array](https:/redis.io/docs/reference/protocol-spec#arrays): where the first element is one of `master`, `slave`, or `sentinel`, and the additional elements are role-specific as illustrated above.
    @inlinable
    public static func role() -> RESPCommand {
        RESPCommand("ROLE")
    }

    /// Returns and removes the last elements of a list. Deletes the list if the last element was popped.
    ///
    /// - Documentation: [RPOP](https:/redis.io/docs/latest/commands/rpop)
    /// - Version: 1.0.0
    /// - Complexity: O(N) where N is the number of elements returned
    /// - Categories: @write, @list, @fast
    /// - Response: One of the following:
    ///     * [Null](https:/redis.io/docs/reference/protocol-spec#nulls): if the key does not exist.
    ///     * [Bulk string](https:/redis.io/docs/reference/protocol-spec#bulk-strings): when called without the _count_ argument, the value of the last element.
    ///     * [Array](https:/redis.io/docs/reference/protocol-spec#arrays): when called with the _count_ argument, a list of popped elements.
    @inlinable
    public static func rpop(key: RedisKey, count: Int? = nil) -> RESPCommand {
        RESPCommand("RPOP", key, count)
    }

    /// Returns the last element of a list after removing and pushing it to another list. Deletes the list if the last element was popped.
    ///
    /// - Documentation: [RPOPLPUSH](https:/redis.io/docs/latest/commands/rpoplpush)
    /// - Version: 1.2.0
    /// - Complexity: O(1)
    /// - Categories: @write, @list, @slow
    /// - Response: One of the following:
    ///     * [Bulk string](https:/redis.io/docs/reference/protocol-spec#bulk-strings): the element being popped and pushed.
    ///     * [Null](https:/redis.io/docs/reference/protocol-spec#nulls): if the source list is empty.
    @inlinable
    public static func rpoplpush(source: RedisKey, destination: RedisKey) -> RESPCommand {
        RESPCommand("RPOPLPUSH", source, destination)
    }

    /// Appends one or more elements to a list. Creates the key if it doesn't exist.
    ///
    /// - Documentation: [RPUSH](https:/redis.io/docs/latest/commands/rpush)
    /// - Version: 1.0.0
    /// - Complexity: O(1) for each element added, so O(N) to add N elements when the command is called with multiple arguments.
    /// - Categories: @write, @list, @fast
    /// - Response: [Integer](https:/redis.io/docs/reference/protocol-spec#integers): the length of the list after the push operation.
    @inlinable
    public static func rpush(key: RedisKey, element: String) -> RESPCommand {
        RESPCommand("RPUSH", key, element)
    }

    /// Appends one or more elements to a list. Creates the key if it doesn't exist.
    ///
    /// - Documentation: [RPUSH](https:/redis.io/docs/latest/commands/rpush)
    /// - Version: 1.0.0
    /// - Complexity: O(1) for each element added, so O(N) to add N elements when the command is called with multiple arguments.
    /// - Categories: @write, @list, @fast
    /// - Response: [Integer](https:/redis.io/docs/reference/protocol-spec#integers): the length of the list after the push operation.
    @inlinable
    public static func rpush(key: RedisKey, elements: [String]) -> RESPCommand {
        RESPCommand("RPUSH", key, elements)
    }

    /// Appends an element to a list only when the list exists.
    ///
    /// - Documentation: [RPUSHX](https:/redis.io/docs/latest/commands/rpushx)
    /// - Version: 2.2.0
    /// - Complexity: O(1) for each element added, so O(N) to add N elements when the command is called with multiple arguments.
    /// - Categories: @write, @list, @fast
    /// - Response: [Integer](https:/redis.io/docs/reference/protocol-spec#integers): the length of the list after the push operation.
    @inlinable
    public static func rpushx(key: RedisKey, element: String) -> RESPCommand {
        RESPCommand("RPUSHX", key, element)
    }

    /// Appends an element to a list only when the list exists.
    ///
    /// - Documentation: [RPUSHX](https:/redis.io/docs/latest/commands/rpushx)
    /// - Version: 2.2.0
    /// - Complexity: O(1) for each element added, so O(N) to add N elements when the command is called with multiple arguments.
    /// - Categories: @write, @list, @fast
    /// - Response: [Integer](https:/redis.io/docs/reference/protocol-spec#integers): the length of the list after the push operation.
    @inlinable
    public static func rpushx(key: RedisKey, elements: [String]) -> RESPCommand {
        RESPCommand("RPUSHX", key, elements)
    }

    /// Adds one or more members to a set. Creates the key if it doesn't exist.
    ///
    /// - Documentation: [SADD](https:/redis.io/docs/latest/commands/sadd)
    /// - Version: 1.0.0
    /// - Complexity: O(1) for each element added, so O(N) to add N elements when the command is called with multiple arguments.
    /// - Categories: @write, @set, @fast
    /// - Response: [Integer](https:/redis.io/docs/reference/protocol-spec#integers): the number of elements that were added to the set, not including all the elements already present in the set.
    @inlinable
    public static func sadd(key: RedisKey, member: String) -> RESPCommand {
        RESPCommand("SADD", key, member)
    }

    /// Adds one or more members to a set. Creates the key if it doesn't exist.
    ///
    /// - Documentation: [SADD](https:/redis.io/docs/latest/commands/sadd)
    /// - Version: 1.0.0
    /// - Complexity: O(1) for each element added, so O(N) to add N elements when the command is called with multiple arguments.
    /// - Categories: @write, @set, @fast
    /// - Response: [Integer](https:/redis.io/docs/reference/protocol-spec#integers): the number of elements that were added to the set, not including all the elements already present in the set.
    @inlinable
    public static func sadd(key: RedisKey, members: [String]) -> RESPCommand {
        RESPCommand("SADD", key, members)
    }

    /// Synchronously saves the database(s) to disk.
    ///
    /// - Documentation: [SAVE](https:/redis.io/docs/latest/commands/save)
    /// - Version: 1.0.0
    /// - Complexity: O(N) where N is the total number of keys in all databases
    /// - Categories: @admin, @slow, @dangerous
    /// - Response: [Simple string](https:/redis.io/docs/reference/protocol-spec#simple-strings): `OK`.
    @inlinable
    public static func save() -> RESPCommand {
        RESPCommand("SAVE")
    }

    /// Iterates over the key names in the database.
    ///
    /// - Documentation: [SCAN](https:/redis.io/docs/latest/commands/scan)
    /// - Version: 2.8.0
    /// - Complexity: O(1) for every call. O(N) for a complete iteration, including enough command calls for the cursor to return back to 0. N is the number of elements inside the collection.
    /// - Categories: @keyspace, @read, @slow
    /// - Response: [Array](https:/redis.io/docs/reference/protocol-spec#arrays): specifically, an array with two elements.
    ///     * The first element is a [Bulk string](https:/redis.io/docs/reference/protocol-spec#bulk-strings) that represents an unsigned 64-bit number, the cursor.
    ///     * The second element is an [Array](https:/redis.io/docs/reference/protocol-spec#arrays) with the names of scanned keys.
    @inlinable
    public static func scan(cursor: Int, pattern: String? = nil, count: Int? = nil, type: String? = nil) -> RESPCommand {
        RESPCommand("SCAN", cursor, RESPWithToken("MATCH", pattern), RESPWithToken("COUNT", count), RESPWithToken("TYPE", type))
    }

    /// Returns the number of members in a set.
    ///
    /// - Documentation: [SCARD](https:/redis.io/docs/latest/commands/scard)
    /// - Version: 1.0.0
    /// - Complexity: O(1)
    /// - Categories: @read, @set, @fast
    /// - Response: [Integer](https:/redis.io/docs/reference/protocol-spec#integers): The cardinality (number of elements) of the set, or 0 if the key does not exist.
    @inlinable
    public static func scard(key: RedisKey) -> RESPCommand {
        RESPCommand("SCARD", key)
    }

    public enum SCRIPTDEBUGMode: RESPRenderable {
        case yes
        case sync
        case no

        @inlinable
        public func writeToRESPBuffer(_ buffer: inout ByteBuffer) -> Int {
            switch self {
            case .yes: "YES".writeToRESPBuffer(&buffer)
            case .sync: "SYNC".writeToRESPBuffer(&buffer)
            case .no: "NO".writeToRESPBuffer(&buffer)
            }
        }
    }
    /// Sets the debug mode of server-side Lua scripts.
    ///
    /// - Documentation: [SCRIPT DEBUG](https:/redis.io/docs/latest/commands/script-debug)
    /// - Version: 3.2.0
    /// - Complexity: O(1)
    /// - Categories: @slow, @scripting
    /// - Response: [Simple string](https:/redis.io/docs/reference/protocol-spec#simple-strings): `OK`.
    @inlinable
    public static func scriptDebug(mode: SCRIPTDEBUGMode) -> RESPCommand {
        RESPCommand("SCRIPT", "DEBUG", mode)
    }

    /// Determines whether server-side Lua scripts exist in the script cache.
    ///
    /// - Documentation: [SCRIPT EXISTS](https:/redis.io/docs/latest/commands/script-exists)
    /// - Version: 2.6.0
    /// - Complexity: O(N) with N being the number of scripts to check (so checking a single script is an O(1) operation).
    /// - Categories: @slow, @scripting
    /// - Response: [Array](https:/redis.io/docs/reference/protocol-spec#arrays): an array of integers that correspond to the specified SHA1 digest arguments.
    @inlinable
    public static func scriptExists(sha1: String) -> RESPCommand {
        RESPCommand("SCRIPT", "EXISTS", sha1)
    }

    /// Determines whether server-side Lua scripts exist in the script cache.
    ///
    /// - Documentation: [SCRIPT EXISTS](https:/redis.io/docs/latest/commands/script-exists)
    /// - Version: 2.6.0
    /// - Complexity: O(N) with N being the number of scripts to check (so checking a single script is an O(1) operation).
    /// - Categories: @slow, @scripting
    /// - Response: [Array](https:/redis.io/docs/reference/protocol-spec#arrays): an array of integers that correspond to the specified SHA1 digest arguments.
    @inlinable
    public static func scriptExists(sha1s: [String]) -> RESPCommand {
        RESPCommand("SCRIPT", "EXISTS", sha1s)
    }

    public enum SCRIPTFLUSHFlushType: RESPRenderable {
        case async
        case sync

        @inlinable
        public func writeToRESPBuffer(_ buffer: inout ByteBuffer) -> Int {
            switch self {
            case .async: "ASYNC".writeToRESPBuffer(&buffer)
            case .sync: "SYNC".writeToRESPBuffer(&buffer)
            }
        }
    }
    /// Removes all server-side Lua scripts from the script cache.
    ///
    /// - Documentation: [SCRIPT FLUSH](https:/redis.io/docs/latest/commands/script-flush)
    /// - Version: 2.6.0
    /// - Complexity: O(N) with N being the number of scripts in cache
    /// - Categories: @slow, @scripting
    /// - Response: [Simple string](https:/redis.io/docs/reference/protocol-spec#simple-strings): `OK`.
    @inlinable
    public static func scriptFlush(flushType: SCRIPTFLUSHFlushType? = nil) -> RESPCommand {
        RESPCommand("SCRIPT", "FLUSH", flushType)
    }

    /// Returns helpful text about the different subcommands.
    ///
    /// - Documentation: [SCRIPT HELP](https:/redis.io/docs/latest/commands/script-help)
    /// - Version: 5.0.0
    /// - Complexity: O(1)
    /// - Categories: @slow, @scripting
    /// - Response: [Array](https:/redis.io/docs/reference/protocol-spec#arrays): a list of sub-commands and their descriptions.
    @inlinable
    public static func scriptHelp() -> RESPCommand {
        RESPCommand("SCRIPT", "HELP")
    }

    /// Terminates a server-side Lua script during execution.
    ///
    /// - Documentation: [SCRIPT KILL](https:/redis.io/docs/latest/commands/script-kill)
    /// - Version: 2.6.0
    /// - Complexity: O(1)
    /// - Categories: @slow, @scripting
    /// - Response: [Simple string](https:/redis.io/docs/reference/protocol-spec#simple-strings): `OK`.
    @inlinable
    public static func scriptKill() -> RESPCommand {
        RESPCommand("SCRIPT", "KILL")
    }

    /// Loads a server-side Lua script to the script cache.
    ///
    /// - Documentation: [SCRIPT LOAD](https:/redis.io/docs/latest/commands/script-load)
    /// - Version: 2.6.0
    /// - Complexity: O(N) with N being the length in bytes of the script body.
    /// - Categories: @slow, @scripting
    /// - Response: [Bulk string](https:/redis.io/docs/reference/protocol-spec#bulk-strings): the SHA1 digest of the script added into the script cache.
    @inlinable
    public static func scriptLoad(script: String) -> RESPCommand {
        RESPCommand("SCRIPT", "LOAD", script)
    }

    /// Returns the difference of multiple sets.
    ///
    /// - Documentation: [SDIFF](https:/redis.io/docs/latest/commands/sdiff)
    /// - Version: 1.0.0
    /// - Complexity: O(N) where N is the total number of elements in all given sets.
    /// - Categories: @read, @set, @slow
    /// - Response: [Array](https:/redis.io/docs/reference/protocol-spec#arrays): a list with the members of the resulting set.
    @inlinable
    public static func sdiff(key: RedisKey) -> RESPCommand {
        RESPCommand("SDIFF", key)
    }

    /// Returns the difference of multiple sets.
    ///
    /// - Documentation: [SDIFF](https:/redis.io/docs/latest/commands/sdiff)
    /// - Version: 1.0.0
    /// - Complexity: O(N) where N is the total number of elements in all given sets.
    /// - Categories: @read, @set, @slow
    /// - Response: [Array](https:/redis.io/docs/reference/protocol-spec#arrays): a list with the members of the resulting set.
    @inlinable
    public static func sdiff(keys: [RedisKey]) -> RESPCommand {
        RESPCommand("SDIFF", keys)
    }

    /// Stores the difference of multiple sets in a key.
    ///
    /// - Documentation: [SDIFFSTORE](https:/redis.io/docs/latest/commands/sdiffstore)
    /// - Version: 1.0.0
    /// - Complexity: O(N) where N is the total number of elements in all given sets.
    /// - Categories: @write, @set, @slow
    /// - Response: [Integer](https:/redis.io/docs/reference/protocol-spec#integers): the number of elements in the resulting set.
    @inlinable
    public static func sdiffstore(destination: RedisKey, key: RedisKey) -> RESPCommand {
        RESPCommand("SDIFFSTORE", destination, key)
    }

    /// Stores the difference of multiple sets in a key.
    ///
    /// - Documentation: [SDIFFSTORE](https:/redis.io/docs/latest/commands/sdiffstore)
    /// - Version: 1.0.0
    /// - Complexity: O(N) where N is the total number of elements in all given sets.
    /// - Categories: @write, @set, @slow
    /// - Response: [Integer](https:/redis.io/docs/reference/protocol-spec#integers): the number of elements in the resulting set.
    @inlinable
    public static func sdiffstore(destination: RedisKey, keys: [RedisKey]) -> RESPCommand {
        RESPCommand("SDIFFSTORE", destination, keys)
    }

    /// Changes the selected database.
    ///
    /// - Documentation: [SELECT](https:/redis.io/docs/latest/commands/select)
    /// - Version: 1.0.0
    /// - Complexity: O(1)
    /// - Categories: @fast, @connection
    /// - Response: [Simple string](https:/redis.io/docs/reference/protocol-spec#simple-strings): `OK`.
    @inlinable
    public static func select(index: Int) -> RESPCommand {
        RESPCommand("SELECT", index)
    }

    public enum SETCondition: RESPRenderable {
        case nx
        case xx

        @inlinable
        public func writeToRESPBuffer(_ buffer: inout ByteBuffer) -> Int {
            switch self {
            case .nx: "NX".writeToRESPBuffer(&buffer)
            case .xx: "XX".writeToRESPBuffer(&buffer)
            }
        }
    }
    public enum SETExpiration: RESPRenderable {
        case seconds(Int)
        case milliseconds(Int)
        case unixTimeSeconds(Date)
        case unixTimeMilliseconds(Date)
        case keepttl

        @inlinable
        public func writeToRESPBuffer(_ buffer: inout ByteBuffer) -> Int {
            switch self {
            case .seconds(let seconds): RESPWithToken("EX", seconds).writeToRESPBuffer(&buffer)
            case .milliseconds(let milliseconds): RESPWithToken("PX", milliseconds).writeToRESPBuffer(&buffer)
            case .unixTimeSeconds(let unixTimeSeconds): RESPWithToken("EXAT", unixTimeSeconds).writeToRESPBuffer(&buffer)
            case .unixTimeMilliseconds(let unixTimeMilliseconds): RESPWithToken("PXAT", unixTimeMilliseconds).writeToRESPBuffer(&buffer)
            case .keepttl: "KEEPTTL".writeToRESPBuffer(&buffer)
            }
        }
    }
    /// Sets the string value of a key, ignoring its type. The key is created if it doesn't exist.
    ///
    /// - Documentation: [SET](https:/redis.io/docs/latest/commands/set)
    /// - Version: 1.0.0
    /// - Complexity: O(1)
    /// - Categories: @write, @string, @slow
    /// - Response: Any of the following:
    ///     * [Null](https:/redis.io/docs/reference/protocol-spec#nulls): `GET` not given: Operation was aborted (conflict with one of the `XX`/`NX` options).
    ///     * [Simple string](https:/redis.io/docs/reference/protocol-spec#simple-strings): `OK`. `GET` not given: The key was set.
    ///     * [Null](https:/redis.io/docs/reference/protocol-spec#nulls): `GET` given: The key didn't exist before the `SET`.
    ///     * [Bulk string](https:/redis.io/docs/reference/protocol-spec#bulk-strings): `GET` given: The previous value of the key.
    @inlinable
    public static func set(key: RedisKey, value: String, condition: SETCondition? = nil, get: Bool = false, expiration: SETExpiration? = nil) -> RESPCommand {
        RESPCommand("SET", key, value, condition, RedisPureToken("GET", get), expiration)
    }

    /// Sets or clears the bit at offset of the string value. Creates the key if it doesn't exist.
    ///
    /// - Documentation: [SETBIT](https:/redis.io/docs/latest/commands/setbit)
    /// - Version: 2.2.0
    /// - Complexity: O(1)
    /// - Categories: @write, @bitmap, @slow
    /// - Response: [Integer](https:/redis.io/docs/reference/protocol-spec#integers): the original bit value stored at _offset_.
    @inlinable
    public static func setbit(key: RedisKey, offset: Int, value: Int) -> RESPCommand {
        RESPCommand("SETBIT", key, offset, value)
    }

    /// Sets the string value and expiration time of a key. Creates the key if it doesn't exist.
    ///
    /// - Documentation: [SETEX](https:/redis.io/docs/latest/commands/setex)
    /// - Version: 2.0.0
    /// - Complexity: O(1)
    /// - Categories: @write, @string, @slow
    /// - Response: [Simple string](https:/redis.io/docs/reference/protocol-spec#simple-strings): `OK`.
    @inlinable
    public static func setex(key: RedisKey, seconds: Int, value: String) -> RESPCommand {
        RESPCommand("SETEX", key, seconds, value)
    }

    /// Set the string value of a key only when the key doesn't exist.
    ///
    /// - Documentation: [SETNX](https:/redis.io/docs/latest/commands/setnx)
    /// - Version: 1.0.0
    /// - Complexity: O(1)
    /// - Categories: @write, @string, @fast
    /// - Response: One of the following:
    ///     * [Integer](https:/redis.io/docs/reference/protocol-spec#integers): `0` if the key was not set.
    ///     * [Integer](https:/redis.io/docs/reference/protocol-spec#integers): `1` if the key was set.
    @inlinable
    public static func setnx(key: RedisKey, value: String) -> RESPCommand {
        RESPCommand("SETNX", key, value)
    }

    /// Overwrites a part of a string value with another by an offset. Creates the key if it doesn't exist.
    ///
    /// - Documentation: [SETRANGE](https:/redis.io/docs/latest/commands/setrange)
    /// - Version: 2.2.0
    /// - Complexity: O(1), not counting the time taken to copy the new string in place. Usually, this string is very small so the amortized complexity is O(1). Otherwise, complexity is O(M) with M being the length of the value argument.
    /// - Categories: @write, @string, @slow
    /// - Response: [Integer](https:/redis.io/docs/reference/protocol-spec#integers): the length of the string after it was modified by the command.
    @inlinable
    public static func setrange(key: RedisKey, offset: Int, value: String) -> RESPCommand {
        RESPCommand("SETRANGE", key, offset, value)
    }

    public enum SHUTDOWNSaveSelector: RESPRenderable {
        case nosave
        case save

        @inlinable
        public func writeToRESPBuffer(_ buffer: inout ByteBuffer) -> Int {
            switch self {
            case .nosave: "NOSAVE".writeToRESPBuffer(&buffer)
            case .save: "SAVE".writeToRESPBuffer(&buffer)
            }
        }
    }
    /// Synchronously saves the database(s) to disk and shuts down the Redis server.
    ///
    /// - Documentation: [SHUTDOWN](https:/redis.io/docs/latest/commands/shutdown)
    /// - Version: 1.0.0
    /// - Complexity: O(N) when saving, where N is the total number of keys in all databases when saving data, otherwise O(1)
    /// - Categories: @admin, @slow, @dangerous
    /// - Response: [Simple string](https:/redis.io/docs/reference/protocol-spec#simple-strings): `OK` if _ABORT_ was specified and shutdown was aborted. On successful shutdown, nothing is returned because the server quits and the connection is closed. On failure, an error is returned.
    @inlinable
    public static func shutdown(saveSelector: SHUTDOWNSaveSelector? = nil, now: Bool = false, force: Bool = false, abort: Bool = false) -> RESPCommand {
        RESPCommand("SHUTDOWN", saveSelector, RedisPureToken("NOW", now), RedisPureToken("FORCE", force), RedisPureToken("ABORT", abort))
    }

    /// Returns the intersect of multiple sets.
    ///
    /// - Documentation: [SINTER](https:/redis.io/docs/latest/commands/sinter)
    /// - Version: 1.0.0
    /// - Complexity: O(N*M) worst case where N is the cardinality of the smallest set and M is the number of sets.
    /// - Categories: @read, @set, @slow
    /// - Response: [Array](https:/redis.io/docs/reference/protocol-spec#arrays): a list with the members of the resulting set.
    @inlinable
    public static func sinter(key: RedisKey) -> RESPCommand {
        RESPCommand("SINTER", key)
    }

    /// Returns the intersect of multiple sets.
    ///
    /// - Documentation: [SINTER](https:/redis.io/docs/latest/commands/sinter)
    /// - Version: 1.0.0
    /// - Complexity: O(N*M) worst case where N is the cardinality of the smallest set and M is the number of sets.
    /// - Categories: @read, @set, @slow
    /// - Response: [Array](https:/redis.io/docs/reference/protocol-spec#arrays): a list with the members of the resulting set.
    @inlinable
    public static func sinter(keys: [RedisKey]) -> RESPCommand {
        RESPCommand("SINTER", keys)
    }

    /// Returns the number of members of the intersect of multiple sets.
    ///
    /// - Documentation: [SINTERCARD](https:/redis.io/docs/latest/commands/sintercard)
    /// - Version: 7.0.0
    /// - Complexity: O(N*M) worst case where N is the cardinality of the smallest set and M is the number of sets.
    /// - Categories: @read, @set, @slow
    /// - Response: [Integer](https:/redis.io/docs/reference/protocol-spec#integers): the number of the elements in the resulting intersection.
    @inlinable
    public static func sintercard(key: RedisKey, limit: Int? = nil) -> RESPCommand {
        RESPCommand("SINTERCARD", 1, key, RESPWithToken("LIMIT", limit))
    }

    /// Returns the number of members of the intersect of multiple sets.
    ///
    /// - Documentation: [SINTERCARD](https:/redis.io/docs/latest/commands/sintercard)
    /// - Version: 7.0.0
    /// - Complexity: O(N*M) worst case where N is the cardinality of the smallest set and M is the number of sets.
    /// - Categories: @read, @set, @slow
    /// - Response: [Integer](https:/redis.io/docs/reference/protocol-spec#integers): the number of the elements in the resulting intersection.
    @inlinable
    public static func sintercard(keys: [RedisKey], limit: Int? = nil) -> RESPCommand {
        RESPCommand("SINTERCARD", RESPArrayWithCount(keys), RESPWithToken("LIMIT", limit))
    }

    /// Stores the intersect of multiple sets in a key.
    ///
    /// - Documentation: [SINTERSTORE](https:/redis.io/docs/latest/commands/sinterstore)
    /// - Version: 1.0.0
    /// - Complexity: O(N*M) worst case where N is the cardinality of the smallest set and M is the number of sets.
    /// - Categories: @write, @set, @slow
    /// - Response: [Integer](https:/redis.io/docs/reference/protocol-spec#integers): the number of the elements in the result set.
    @inlinable
    public static func sinterstore(destination: RedisKey, key: RedisKey) -> RESPCommand {
        RESPCommand("SINTERSTORE", destination, key)
    }

    /// Stores the intersect of multiple sets in a key.
    ///
    /// - Documentation: [SINTERSTORE](https:/redis.io/docs/latest/commands/sinterstore)
    /// - Version: 1.0.0
    /// - Complexity: O(N*M) worst case where N is the cardinality of the smallest set and M is the number of sets.
    /// - Categories: @write, @set, @slow
    /// - Response: [Integer](https:/redis.io/docs/reference/protocol-spec#integers): the number of the elements in the result set.
    @inlinable
    public static func sinterstore(destination: RedisKey, keys: [RedisKey]) -> RESPCommand {
        RESPCommand("SINTERSTORE", destination, keys)
    }

    /// Determines whether a member belongs to a set.
    ///
    /// - Documentation: [SISMEMBER](https:/redis.io/docs/latest/commands/sismember)
    /// - Version: 1.0.0
    /// - Complexity: O(1)
    /// - Categories: @read, @set, @fast
    /// - Response: One of the following:
    ///     * [Integer](https:/redis.io/docs/reference/protocol-spec#integers): `0` if the element is not a member of the set, or when the key does not exist.
    ///     * [Integer](https:/redis.io/docs/reference/protocol-spec#integers): `1` if the element is a member of the set.
    @inlinable
    public static func sismember(key: RedisKey, member: String) -> RESPCommand {
        RESPCommand("SISMEMBER", key, member)
    }

    public struct SLAVEOFArgsHostPort: RESPRenderable {
        @usableFromInline let host: String
        @usableFromInline let port: Int

        @inlinable
        public func writeToRESPBuffer(_ buffer: inout ByteBuffer) -> Int {
            var count = 0
            count += self.host.writeToRESPBuffer(&buffer)
            count += self.port.writeToRESPBuffer(&buffer)
            return count
        }
    }
    public struct SLAVEOFArgsNoOne: RESPRenderable {
        @usableFromInline let no: Bool
        @usableFromInline let one: Bool

        @inlinable
        public func writeToRESPBuffer(_ buffer: inout ByteBuffer) -> Int {
            var count = 0
            if self.no { count += "NO".writeToRESPBuffer(&buffer) }
            if self.one { count += "ONE".writeToRESPBuffer(&buffer) }
            return count
        }
    }
    public enum SLAVEOFArgs: RESPRenderable {
        case hostPort(SLAVEOFArgsHostPort)
        case noOne(SLAVEOFArgsNoOne)

        @inlinable
        public func writeToRESPBuffer(_ buffer: inout ByteBuffer) -> Int {
            switch self {
            case .hostPort(let hostPort): hostPort.writeToRESPBuffer(&buffer)
            case .noOne(let noOne): noOne.writeToRESPBuffer(&buffer)
            }
        }
    }
    /// Sets a Redis server as a replica of another, or promotes it to being a master.
    ///
    /// - Documentation: [SLAVEOF](https:/redis.io/docs/latest/commands/slaveof)
    /// - Version: 1.0.0
    /// - Complexity: O(1)
    /// - Categories: @admin, @slow, @dangerous
    /// - Response: [Simple string](https:/redis.io/docs/reference/protocol-spec#simple-strings): `OK`.
    @inlinable
    public static func slaveof(args: SLAVEOFArgs) -> RESPCommand {
        RESPCommand("SLAVEOF", args)
    }

    /// Returns the slow log's entries.
    ///
    /// - Documentation: [SLOWLOG GET](https:/redis.io/docs/latest/commands/slowlog-get)
    /// - Version: 2.2.12
    /// - Complexity: O(N) where N is the number of entries returned
    /// - Categories: @admin, @slow, @dangerous
    /// - Response: [Array](https:/redis.io/docs/reference/protocol-spec#arrays): a list of slow log entries per the above format.
    @inlinable
    public static func slowlogGet(count: Int? = nil) -> RESPCommand {
        RESPCommand("SLOWLOG", "GET", count)
    }

    /// Show helpful text about the different subcommands
    ///
    /// - Documentation: [SLOWLOG HELP](https:/redis.io/docs/latest/commands/slowlog-help)
    /// - Version: 6.2.0
    /// - Complexity: O(1)
    /// - Categories: @slow
    /// - Response: [Array](https:/redis.io/docs/reference/protocol-spec#arrays): a list of sub-commands and their descriptions.
    @inlinable
    public static func slowlogHelp() -> RESPCommand {
        RESPCommand("SLOWLOG", "HELP")
    }

    /// Returns the number of entries in the slow log.
    ///
    /// - Documentation: [SLOWLOG LEN](https:/redis.io/docs/latest/commands/slowlog-len)
    /// - Version: 2.2.12
    /// - Complexity: O(1)
    /// - Categories: @admin, @slow, @dangerous
    /// - Response: [Integer](https:/redis.io/docs/reference/protocol-spec#integers): the number of entries in the slow log.
    @inlinable
    public static func slowlogLen() -> RESPCommand {
        RESPCommand("SLOWLOG", "LEN")
    }

    /// Clears all entries from the slow log.
    ///
    /// - Documentation: [SLOWLOG RESET](https:/redis.io/docs/latest/commands/slowlog-reset)
    /// - Version: 2.2.12
    /// - Complexity: O(N) where N is the number of entries in the slowlog
    /// - Categories: @admin, @slow, @dangerous
    /// - Response: [Simple string](https:/redis.io/docs/reference/protocol-spec#simple-strings): `OK`.
    @inlinable
    public static func slowlogReset() -> RESPCommand {
        RESPCommand("SLOWLOG", "RESET")
    }

    /// Returns all members of a set.
    ///
    /// - Documentation: [SMEMBERS](https:/redis.io/docs/latest/commands/smembers)
    /// - Version: 1.0.0
    /// - Complexity: O(N) where N is the set cardinality.
    /// - Categories: @read, @set, @slow
    /// - Response: [Array](https:/redis.io/docs/reference/protocol-spec#arrays): all members of the set.
    @inlinable
    public static func smembers(key: RedisKey) -> RESPCommand {
        RESPCommand("SMEMBERS", key)
    }

    /// Determines whether multiple members belong to a set.
    ///
    /// - Documentation: [SMISMEMBER](https:/redis.io/docs/latest/commands/smismember)
    /// - Version: 6.2.0
    /// - Complexity: O(N) where N is the number of elements being checked for membership
    /// - Categories: @read, @set, @fast
    /// - Response: [Array](https:/redis.io/docs/reference/protocol-spec#arrays): a list representing the membership of the given elements, in the same order as they are requested.
    @inlinable
    public static func smismember(key: RedisKey, member: String) -> RESPCommand {
        RESPCommand("SMISMEMBER", key, member)
    }

    /// Determines whether multiple members belong to a set.
    ///
    /// - Documentation: [SMISMEMBER](https:/redis.io/docs/latest/commands/smismember)
    /// - Version: 6.2.0
    /// - Complexity: O(N) where N is the number of elements being checked for membership
    /// - Categories: @read, @set, @fast
    /// - Response: [Array](https:/redis.io/docs/reference/protocol-spec#arrays): a list representing the membership of the given elements, in the same order as they are requested.
    @inlinable
    public static func smismember(key: RedisKey, members: [String]) -> RESPCommand {
        RESPCommand("SMISMEMBER", key, members)
    }

    /// Moves a member from one set to another.
    ///
    /// - Documentation: [SMOVE](https:/redis.io/docs/latest/commands/smove)
    /// - Version: 1.0.0
    /// - Complexity: O(1)
    /// - Categories: @write, @set, @fast
    /// - Response: One of the following:
    ///     * [Integer](https:/redis.io/docs/reference/protocol-spec#integers): `1` if the element is moved.
    ///     * [Integer](https:/redis.io/docs/reference/protocol-spec#integers): `0` if the element is not a member of _source_ and no operation was performed.
    @inlinable
    public static func smove(source: RedisKey, destination: RedisKey, member: String) -> RESPCommand {
        RESPCommand("SMOVE", source, destination, member)
    }

    public struct SORTLimit: RESPRenderable {
        @usableFromInline let offset: Int
        @usableFromInline let count: Int

        @inlinable
        public func writeToRESPBuffer(_ buffer: inout ByteBuffer) -> Int {
            var count = 0
            count += self.offset.writeToRESPBuffer(&buffer)
            count += self.count.writeToRESPBuffer(&buffer)
            return count
        }
    }
    public enum SORTOrder: RESPRenderable {
        case asc
        case desc

        @inlinable
        public func writeToRESPBuffer(_ buffer: inout ByteBuffer) -> Int {
            switch self {
            case .asc: "ASC".writeToRESPBuffer(&buffer)
            case .desc: "DESC".writeToRESPBuffer(&buffer)
            }
        }
    }
    /// Sorts the elements in a list, a set, or a sorted set, optionally storing the result.
    ///
    /// - Documentation: [SORT](https:/redis.io/docs/latest/commands/sort)
    /// - Version: 1.0.0
    /// - Complexity: O(N+M*log(M)) where N is the number of elements in the list or set to sort, and M the number of returned elements. When the elements are not sorted, complexity is O(N).
    /// - Categories: @write, @set, @sortedset, @list, @slow, @dangerous
    /// - Response: [Array](https:/redis.io/docs/reference/protocol-spec#arrays): without passing the _STORE_ option, the command returns a list of sorted elements.
    ///     [Integer](https:/redis.io/docs/reference/protocol-spec#integers): when the _STORE_ option is specified, the command returns the number of sorted elements in the destination list.
    @inlinable
    public static func sort(key: RedisKey, byPattern: String? = nil, limit: SORTLimit? = nil, getPattern: String? = nil, order: SORTOrder? = nil, sorting: Bool = false, destination: RedisKey? = nil) -> RESPCommand {
        RESPCommand("SORT", key, RESPWithToken("BY", byPattern), RESPWithToken("LIMIT", limit), RESPWithToken("GET", getPattern), order, RedisPureToken("ALPHA", sorting), RESPWithToken("STORE", destination))
    }

    /// Sorts the elements in a list, a set, or a sorted set, optionally storing the result.
    ///
    /// - Documentation: [SORT](https:/redis.io/docs/latest/commands/sort)
    /// - Version: 1.0.0
    /// - Complexity: O(N+M*log(M)) where N is the number of elements in the list or set to sort, and M the number of returned elements. When the elements are not sorted, complexity is O(N).
    /// - Categories: @write, @set, @sortedset, @list, @slow, @dangerous
    /// - Response: [Array](https:/redis.io/docs/reference/protocol-spec#arrays): without passing the _STORE_ option, the command returns a list of sorted elements.
    ///     [Integer](https:/redis.io/docs/reference/protocol-spec#integers): when the _STORE_ option is specified, the command returns the number of sorted elements in the destination list.
    @inlinable
    public static func sort(key: RedisKey, byPattern: String? = nil, limit: SORTLimit? = nil, getPatterns: [String], order: SORTOrder? = nil, sorting: Bool = false, destination: RedisKey? = nil) -> RESPCommand {
        RESPCommand("SORT", key, RESPWithToken("BY", byPattern), RESPWithToken("LIMIT", limit), RESPWithToken("GET", getPatterns), order, RedisPureToken("ALPHA", sorting), RESPWithToken("STORE", destination))
    }

    public struct SORTROLimit: RESPRenderable {
        @usableFromInline let offset: Int
        @usableFromInline let count: Int

        @inlinable
        public func writeToRESPBuffer(_ buffer: inout ByteBuffer) -> Int {
            var count = 0
            count += self.offset.writeToRESPBuffer(&buffer)
            count += self.count.writeToRESPBuffer(&buffer)
            return count
        }
    }
    public enum SORTROOrder: RESPRenderable {
        case asc
        case desc

        @inlinable
        public func writeToRESPBuffer(_ buffer: inout ByteBuffer) -> Int {
            switch self {
            case .asc: "ASC".writeToRESPBuffer(&buffer)
            case .desc: "DESC".writeToRESPBuffer(&buffer)
            }
        }
    }
    /// Returns the sorted elements of a list, a set, or a sorted set.
    ///
    /// - Documentation: [SORT_RO](https:/redis.io/docs/latest/commands/sort_ro)
    /// - Version: 7.0.0
    /// - Complexity: O(N+M*log(M)) where N is the number of elements in the list or set to sort, and M the number of returned elements. When the elements are not sorted, complexity is O(N).
    /// - Categories: @read, @set, @sortedset, @list, @slow, @dangerous
    /// - Response: [Array](https:/redis.io/docs/reference/protocol-spec#arrays): a list of sorted elements.
    @inlinable
    public static func sortRo(key: RedisKey, byPattern: String? = nil, limit: SORTROLimit? = nil, getPattern: String? = nil, order: SORTROOrder? = nil, sorting: Bool = false) -> RESPCommand {
        RESPCommand("SORT_RO", key, RESPWithToken("BY", byPattern), RESPWithToken("LIMIT", limit), RESPWithToken("GET", getPattern), order, RedisPureToken("ALPHA", sorting))
    }

    /// Returns the sorted elements of a list, a set, or a sorted set.
    ///
    /// - Documentation: [SORT_RO](https:/redis.io/docs/latest/commands/sort_ro)
    /// - Version: 7.0.0
    /// - Complexity: O(N+M*log(M)) where N is the number of elements in the list or set to sort, and M the number of returned elements. When the elements are not sorted, complexity is O(N).
    /// - Categories: @read, @set, @sortedset, @list, @slow, @dangerous
    /// - Response: [Array](https:/redis.io/docs/reference/protocol-spec#arrays): a list of sorted elements.
    @inlinable
    public static func sortRo(key: RedisKey, byPattern: String? = nil, limit: SORTROLimit? = nil, getPatterns: [String], order: SORTROOrder? = nil, sorting: Bool = false) -> RESPCommand {
        RESPCommand("SORT_RO", key, RESPWithToken("BY", byPattern), RESPWithToken("LIMIT", limit), RESPWithToken("GET", getPatterns), order, RedisPureToken("ALPHA", sorting))
    }

    /// Returns one or more random members from a set after removing them. Deletes the set if the last member was popped.
    ///
    /// - Documentation: [SPOP](https:/redis.io/docs/latest/commands/spop)
    /// - Version: 1.0.0
    /// - Complexity: Without the count argument O(1), otherwise O(N) where N is the value of the passed count.
    /// - Categories: @write, @set, @fast
    /// - Response: One of the following:
    ///     * [Null](https:/redis.io/docs/reference/protocol-spec#nulls): if the key does not exist.
    ///     * [Bulk string](https:/redis.io/docs/reference/protocol-spec#bulk-strings): when called without the _count_ argument, the removed member.
    ///     * [Array](https:/redis.io/docs/reference/protocol-spec#arrays): when called with the _count_ argument, a list of the removed members.
    @inlinable
    public static func spop(key: RedisKey, count: Int? = nil) -> RESPCommand {
        RESPCommand("SPOP", key, count)
    }

    /// Post a message to a shard channel
    ///
    /// - Documentation: [SPUBLISH](https:/redis.io/docs/latest/commands/spublish)
    /// - Version: 7.0.0
    /// - Complexity: O(N) where N is the number of clients subscribed to the receiving shard channel.
    /// - Categories: @pubsub, @fast
    /// - Response: [Integer](https:/redis.io/docs/reference/protocol-spec#integers): the number of clients that received the message. Note that in a Redis Cluster, only clients that are connected to the same node as the publishing client are included in the count
    @inlinable
    public static func spublish(shardchannel: String, message: String) -> RESPCommand {
        RESPCommand("SPUBLISH", shardchannel, message)
    }

    /// Get one or multiple random members from a set
    ///
    /// - Documentation: [SRANDMEMBER](https:/redis.io/docs/latest/commands/srandmember)
    /// - Version: 1.0.0
    /// - Complexity: Without the count argument O(1), otherwise O(N) where N is the absolute value of the passed count.
    /// - Categories: @read, @set, @slow
    /// - Response: One of the following:
    ///     * [Bulk string](https:/redis.io/docs/reference/protocol-spec#bulk-strings): without the additional _count_ argument, the command returns a randomly selected member, or a [Null](https:/redis.io/docs/reference/protocol-spec#nulls) when _key_ doesn't exist.
    ///     * [Array](https:/redis.io/docs/reference/protocol-spec#arrays): when the optional _count_ argument is passed, the command returns an array of members, or an empty array when _key_ doesn't exist.
    @inlinable
    public static func srandmember(key: RedisKey, count: Int? = nil) -> RESPCommand {
        RESPCommand("SRANDMEMBER", key, count)
    }

    /// Removes one or more members from a set. Deletes the set if the last member was removed.
    ///
    /// - Documentation: [SREM](https:/redis.io/docs/latest/commands/srem)
    /// - Version: 1.0.0
    /// - Complexity: O(N) where N is the number of members to be removed.
    /// - Categories: @write, @set, @fast
    /// - Response: [Integer](https:/redis.io/docs/reference/protocol-spec#integers): Number of members that were removed from the set, not including non existing members.
    @inlinable
    public static func srem(key: RedisKey, member: String) -> RESPCommand {
        RESPCommand("SREM", key, member)
    }

    /// Removes one or more members from a set. Deletes the set if the last member was removed.
    ///
    /// - Documentation: [SREM](https:/redis.io/docs/latest/commands/srem)
    /// - Version: 1.0.0
    /// - Complexity: O(N) where N is the number of members to be removed.
    /// - Categories: @write, @set, @fast
    /// - Response: [Integer](https:/redis.io/docs/reference/protocol-spec#integers): Number of members that were removed from the set, not including non existing members.
    @inlinable
    public static func srem(key: RedisKey, members: [String]) -> RESPCommand {
        RESPCommand("SREM", key, members)
    }

    /// Iterates over members of a set.
    ///
    /// - Documentation: [SSCAN](https:/redis.io/docs/latest/commands/sscan)
    /// - Version: 2.8.0
    /// - Complexity: O(1) for every call. O(N) for a complete iteration, including enough command calls for the cursor to return back to 0. N is the number of elements inside the collection.
    /// - Categories: @read, @set, @slow
    /// - Response: [Array](https:/redis.io/docs/reference/protocol-spec#arrays): specifically, an array with two elements:
    ///     * The first element is a [Bulk string](https:/redis.io/docs/reference/protocol-spec#bulk-strings) that represents an unsigned 64-bit number, the cursor.
    ///     * The second element is an [Array](https:/redis.io/docs/reference/protocol-spec#arrays) with the names of scanned members.
    @inlinable
    public static func sscan(key: RedisKey, cursor: Int, pattern: String? = nil, count: Int? = nil) -> RESPCommand {
        RESPCommand("SSCAN", key, cursor, RESPWithToken("MATCH", pattern), RESPWithToken("COUNT", count))
    }

    /// Listens for messages published to shard channels.
    ///
    /// - Documentation: [SSUBSCRIBE](https:/redis.io/docs/latest/commands/ssubscribe)
    /// - Version: 7.0.0
    /// - Complexity: O(N) where N is the number of shard channels to subscribe to.
    /// - Categories: @pubsub, @slow
    /// - Response: When successful, this command doesn't return anything. Instead, for each shard channel, one message with the first element being the string 'ssubscribe' is pushed as a confirmation that the command succeeded. Note that this command can also return a -MOVED redirect.
    @inlinable
    public static func ssubscribe(shardchannel: String) -> RESPCommand {
        RESPCommand("SSUBSCRIBE", shardchannel)
    }

    /// Listens for messages published to shard channels.
    ///
    /// - Documentation: [SSUBSCRIBE](https:/redis.io/docs/latest/commands/ssubscribe)
    /// - Version: 7.0.0
    /// - Complexity: O(N) where N is the number of shard channels to subscribe to.
    /// - Categories: @pubsub, @slow
    /// - Response: When successful, this command doesn't return anything. Instead, for each shard channel, one message with the first element being the string 'ssubscribe' is pushed as a confirmation that the command succeeded. Note that this command can also return a -MOVED redirect.
    @inlinable
    public static func ssubscribe(shardchannels: [String]) -> RESPCommand {
        RESPCommand("SSUBSCRIBE", shardchannels)
    }

    /// Returns the length of a string value.
    ///
    /// - Documentation: [STRLEN](https:/redis.io/docs/latest/commands/strlen)
    /// - Version: 2.2.0
    /// - Complexity: O(1)
    /// - Categories: @read, @string, @fast
    /// - Response: [Integer](https:/redis.io/docs/reference/protocol-spec#integers): the length of the string stored at key, or 0 when the key does not exist.
    @inlinable
    public static func strlen(key: RedisKey) -> RESPCommand {
        RESPCommand("STRLEN", key)
    }

    /// Listens for messages published to channels.
    ///
    /// - Documentation: [SUBSCRIBE](https:/redis.io/docs/latest/commands/subscribe)
    /// - Version: 2.0.0
    /// - Complexity: O(N) where N is the number of channels to subscribe to.
    /// - Categories: @pubsub, @slow
    /// - Response: When successful, this command doesn't return anything. Instead, for each channel, one message with the first element being the string `subscribe` is pushed as a confirmation that the command succeeded.
    @inlinable
    public static func subscribe(channel: String) -> RESPCommand {
        RESPCommand("SUBSCRIBE", channel)
    }

    /// Listens for messages published to channels.
    ///
    /// - Documentation: [SUBSCRIBE](https:/redis.io/docs/latest/commands/subscribe)
    /// - Version: 2.0.0
    /// - Complexity: O(N) where N is the number of channels to subscribe to.
    /// - Categories: @pubsub, @slow
    /// - Response: When successful, this command doesn't return anything. Instead, for each channel, one message with the first element being the string `subscribe` is pushed as a confirmation that the command succeeded.
    @inlinable
    public static func subscribe(channels: [String]) -> RESPCommand {
        RESPCommand("SUBSCRIBE", channels)
    }

    /// Returns a substring from a string value.
    ///
    /// - Documentation: [SUBSTR](https:/redis.io/docs/latest/commands/substr)
    /// - Version: 1.0.0
    /// - Complexity: O(N) where N is the length of the returned string. The complexity is ultimately determined by the returned length, but because creating a substring from an existing string is very cheap, it can be considered O(1) for small strings.
    /// - Categories: @read, @string, @slow
    /// - Response: [Bulk string](https:/redis.io/docs/reference/protocol-spec#bulk-strings): the substring of the string value stored at key, determined by the offsets start and end (both are inclusive).
    @inlinable
    public static func substr(key: RedisKey, start: Int, end: Int) -> RESPCommand {
        RESPCommand("SUBSTR", key, start, end)
    }

    /// Returns the union of multiple sets.
    ///
    /// - Documentation: [SUNION](https:/redis.io/docs/latest/commands/sunion)
    /// - Version: 1.0.0
    /// - Complexity: O(N) where N is the total number of elements in all given sets.
    /// - Categories: @read, @set, @slow
    /// - Response: [Array](https:/redis.io/docs/reference/protocol-spec#arrays): a list with the members of the resulting set.
    @inlinable
    public static func sunion(key: RedisKey) -> RESPCommand {
        RESPCommand("SUNION", key)
    }

    /// Returns the union of multiple sets.
    ///
    /// - Documentation: [SUNION](https:/redis.io/docs/latest/commands/sunion)
    /// - Version: 1.0.0
    /// - Complexity: O(N) where N is the total number of elements in all given sets.
    /// - Categories: @read, @set, @slow
    /// - Response: [Array](https:/redis.io/docs/reference/protocol-spec#arrays): a list with the members of the resulting set.
    @inlinable
    public static func sunion(keys: [RedisKey]) -> RESPCommand {
        RESPCommand("SUNION", keys)
    }

    /// Stores the union of multiple sets in a key.
    ///
    /// - Documentation: [SUNIONSTORE](https:/redis.io/docs/latest/commands/sunionstore)
    /// - Version: 1.0.0
    /// - Complexity: O(N) where N is the total number of elements in all given sets.
    /// - Categories: @write, @set, @slow
    /// - Response: [Integer](https:/redis.io/docs/reference/protocol-spec#integers): Number of the elements in the resulting set.
    @inlinable
    public static func sunionstore(destination: RedisKey, key: RedisKey) -> RESPCommand {
        RESPCommand("SUNIONSTORE", destination, key)
    }

    /// Stores the union of multiple sets in a key.
    ///
    /// - Documentation: [SUNIONSTORE](https:/redis.io/docs/latest/commands/sunionstore)
    /// - Version: 1.0.0
    /// - Complexity: O(N) where N is the total number of elements in all given sets.
    /// - Categories: @write, @set, @slow
    /// - Response: [Integer](https:/redis.io/docs/reference/protocol-spec#integers): Number of the elements in the resulting set.
    @inlinable
    public static func sunionstore(destination: RedisKey, keys: [RedisKey]) -> RESPCommand {
        RESPCommand("SUNIONSTORE", destination, keys)
    }

    /// Stops listening to messages posted to shard channels.
    ///
    /// - Documentation: [SUNSUBSCRIBE](https:/redis.io/docs/latest/commands/sunsubscribe)
    /// - Version: 7.0.0
    /// - Complexity: O(N) where N is the number of shard channels to unsubscribe.
    /// - Categories: @pubsub, @slow
    /// - Response: When successful, this command doesn't return anything. Instead, for each shard channel, one message with the first element being the string `sunsubscribe` is pushed as a confirmation that the command succeeded.
    @inlinable
    public static func sunsubscribe(shardchannel: String? = nil) -> RESPCommand {
        RESPCommand("SUNSUBSCRIBE", shardchannel)
    }

    /// Stops listening to messages posted to shard channels.
    ///
    /// - Documentation: [SUNSUBSCRIBE](https:/redis.io/docs/latest/commands/sunsubscribe)
    /// - Version: 7.0.0
    /// - Complexity: O(N) where N is the number of shard channels to unsubscribe.
    /// - Categories: @pubsub, @slow
    /// - Response: When successful, this command doesn't return anything. Instead, for each shard channel, one message with the first element being the string `sunsubscribe` is pushed as a confirmation that the command succeeded.
    @inlinable
    public static func sunsubscribe(shardchannels: [String]) -> RESPCommand {
        RESPCommand("SUNSUBSCRIBE", shardchannels)
    }

    /// Swaps two Redis databases.
    ///
    /// - Documentation: [SWAPDB](https:/redis.io/docs/latest/commands/swapdb)
    /// - Version: 4.0.0
    /// - Complexity: O(N) where N is the count of clients watching or blocking on keys from both databases.
    /// - Categories: @keyspace, @write, @fast, @dangerous
    /// - Response: [Simple string](https:/redis.io/docs/reference/protocol-spec#simple-strings): `OK`.
    @inlinable
    public static func swapdb(index1: Int, index2: Int) -> RESPCommand {
        RESPCommand("SWAPDB", index1, index2)
    }

    /// An internal command used in replication.
    ///
    /// - Documentation: [SYNC](https:/redis.io/docs/latest/commands/sync)
    /// - Version: 1.0.0
    /// - Categories: @admin, @slow, @dangerous
    /// - Response: **Non-standard return value**, a bulk transfer of the data followed by `PING` and write requests from the master.
    @inlinable
    public static func sync() -> RESPCommand {
        RESPCommand("SYNC")
    }

    /// Returns the server time.
    ///
    /// - Documentation: [TIME](https:/redis.io/docs/latest/commands/time)
    /// - Version: 2.6.0
    /// - Complexity: O(1)
    /// - Categories: @fast
    /// - Response: [Array](https:/redis.io/docs/reference/protocol-spec#arrays): specifically, a two-element array consisting of the Unix timestamp in seconds and the microseconds' count.
    @inlinable
    public static func time() -> RESPCommand {
        RESPCommand("TIME")
    }

    /// Returns the number of existing keys out of those specified after updating the time they were last accessed.
    ///
    /// - Documentation: [TOUCH](https:/redis.io/docs/latest/commands/touch)
    /// - Version: 3.2.1
    /// - Complexity: O(N) where N is the number of keys that will be touched.
    /// - Categories: @keyspace, @read, @fast
    /// - Response: [Integer](https:/redis.io/docs/reference/protocol-spec#integers): the number of touched keys.
    @inlinable
    public static func touch(key: RedisKey) -> RESPCommand {
        RESPCommand("TOUCH", key)
    }

    /// Returns the number of existing keys out of those specified after updating the time they were last accessed.
    ///
    /// - Documentation: [TOUCH](https:/redis.io/docs/latest/commands/touch)
    /// - Version: 3.2.1
    /// - Complexity: O(N) where N is the number of keys that will be touched.
    /// - Categories: @keyspace, @read, @fast
    /// - Response: [Integer](https:/redis.io/docs/reference/protocol-spec#integers): the number of touched keys.
    @inlinable
    public static func touch(keys: [RedisKey]) -> RESPCommand {
        RESPCommand("TOUCH", keys)
    }

    /// Returns the expiration time in seconds of a key.
    ///
    /// - Documentation: [TTL](https:/redis.io/docs/latest/commands/ttl)
    /// - Version: 1.0.0
    /// - Complexity: O(1)
    /// - Categories: @keyspace, @read, @fast
    /// - Response: One of the following:
    ///     * [Integer](https:/redis.io/docs/reference/protocol-spec#integers): TTL in seconds.
    ///     * [Integer](https:/redis.io/docs/reference/protocol-spec#integers): `-1` if the key exists but has no associated expiration.
    ///     * [Integer](https:/redis.io/docs/reference/protocol-spec#integers): `-2` if the key does not exist.
    @inlinable
    public static func ttl(key: RedisKey) -> RESPCommand {
        RESPCommand("TTL", key)
    }

    /// Determines the type of value stored at a key.
    ///
    /// - Documentation: [TYPE](https:/redis.io/docs/latest/commands/type)
    /// - Version: 1.0.0
    /// - Complexity: O(1)
    /// - Categories: @keyspace, @read, @fast
    /// - Response: [Simple string](https:/redis.io/docs/reference/protocol-spec#simple-strings): the type of _key_, or `none` when _key_ doesn't exist.
    @inlinable
    public static func type(key: RedisKey) -> RESPCommand {
        RESPCommand("TYPE", key)
    }

    /// Asynchronously deletes one or more keys.
    ///
    /// - Documentation: [UNLINK](https:/redis.io/docs/latest/commands/unlink)
    /// - Version: 4.0.0
    /// - Complexity: O(1) for each key removed regardless of its size. Then the command does O(N) work in a different thread in order to reclaim memory, where N is the number of allocations the deleted objects where composed of.
    /// - Categories: @keyspace, @write, @fast
    /// - Response: [Integer](https:/redis.io/docs/reference/protocol-spec#integers): the number of keys that were unlinked.
    @inlinable
    public static func unlink(key: RedisKey) -> RESPCommand {
        RESPCommand("UNLINK", key)
    }

    /// Asynchronously deletes one or more keys.
    ///
    /// - Documentation: [UNLINK](https:/redis.io/docs/latest/commands/unlink)
    /// - Version: 4.0.0
    /// - Complexity: O(1) for each key removed regardless of its size. Then the command does O(N) work in a different thread in order to reclaim memory, where N is the number of allocations the deleted objects where composed of.
    /// - Categories: @keyspace, @write, @fast
    /// - Response: [Integer](https:/redis.io/docs/reference/protocol-spec#integers): the number of keys that were unlinked.
    @inlinable
    public static func unlink(keys: [RedisKey]) -> RESPCommand {
        RESPCommand("UNLINK", keys)
    }

    /// Stops listening to messages posted to channels.
    ///
    /// - Documentation: [UNSUBSCRIBE](https:/redis.io/docs/latest/commands/unsubscribe)
    /// - Version: 2.0.0
    /// - Complexity: O(N) where N is the number of channels to unsubscribe.
    /// - Categories: @pubsub, @slow
    /// - Response: When successful, this command doesn't return anything. Instead, for each channel, one message with the first element being the string `unsubscribe` is pushed as a confirmation that the command succeeded.
    @inlinable
    public static func unsubscribe(channel: String? = nil) -> RESPCommand {
        RESPCommand("UNSUBSCRIBE", channel)
    }

    /// Stops listening to messages posted to channels.
    ///
    /// - Documentation: [UNSUBSCRIBE](https:/redis.io/docs/latest/commands/unsubscribe)
    /// - Version: 2.0.0
    /// - Complexity: O(N) where N is the number of channels to unsubscribe.
    /// - Categories: @pubsub, @slow
    /// - Response: When successful, this command doesn't return anything. Instead, for each channel, one message with the first element being the string `unsubscribe` is pushed as a confirmation that the command succeeded.
    @inlinable
    public static func unsubscribe(channels: [String]) -> RESPCommand {
        RESPCommand("UNSUBSCRIBE", channels)
    }

    /// Forgets about watched keys of a transaction.
    ///
    /// - Documentation: [UNWATCH](https:/redis.io/docs/latest/commands/unwatch)
    /// - Version: 2.2.0
    /// - Complexity: O(1)
    /// - Categories: @fast, @transaction
    /// - Response: [Simple string](https:/redis.io/docs/reference/protocol-spec#simple-strings): `OK`.
    @inlinable
    public static func unwatch() -> RESPCommand {
        RESPCommand("UNWATCH")
    }

    /// Blocks until the asynchronous replication of all preceding write commands sent by the connection is completed.
    ///
    /// - Documentation: [WAIT](https:/redis.io/docs/latest/commands/wait)
    /// - Version: 3.0.0
    /// - Complexity: O(1)
    /// - Categories: @slow, @connection
    /// - Response: [Integer](https:/redis.io/docs/reference/protocol-spec#integers): the number of replicas reached by all the writes performed in the context of the current connection.
    @inlinable
    public static func wait(numreplicas: Int, timeout: Int) -> RESPCommand {
        RESPCommand("WAIT", numreplicas, timeout)
    }

    /// Blocks until all of the preceding write commands sent by the connection are written to the append-only file of the master and/or replicas.
    ///
    /// - Documentation: [WAITAOF](https:/redis.io/docs/latest/commands/waitaof)
    /// - Version: 7.2.0
    /// - Complexity: O(1)
    /// - Categories: @slow, @connection
    /// - Response: [Array](https:/redis.io/docs/reference/protocol-spec#arrays): The command returns an array of two integers:
    ///     1. The first is the number of local Redises (0 or 1) that have fsynced to AOF  all writes performed in the context of the current connection
    ///     2. The second is the number of replicas that have acknowledged doing the same.
    @inlinable
    public static func waitaof(numlocal: Int, numreplicas: Int, timeout: Int) -> RESPCommand {
        RESPCommand("WAITAOF", numlocal, numreplicas, timeout)
    }

    /// Monitors changes to keys to determine the execution of a transaction.
    ///
    /// - Documentation: [WATCH](https:/redis.io/docs/latest/commands/watch)
    /// - Version: 2.2.0
    /// - Complexity: O(1) for every key.
    /// - Categories: @fast, @transaction
    /// - Response: [Simple string](https:/redis.io/docs/reference/protocol-spec#simple-strings): `OK`.
    @inlinable
    public static func watch(key: RedisKey) -> RESPCommand {
        RESPCommand("WATCH", key)
    }

    /// Monitors changes to keys to determine the execution of a transaction.
    ///
    /// - Documentation: [WATCH](https:/redis.io/docs/latest/commands/watch)
    /// - Version: 2.2.0
    /// - Complexity: O(1) for every key.
    /// - Categories: @fast, @transaction
    /// - Response: [Simple string](https:/redis.io/docs/reference/protocol-spec#simple-strings): `OK`.
    @inlinable
    public static func watch(keys: [RedisKey]) -> RESPCommand {
        RESPCommand("WATCH", keys)
    }

    /// Returns the number of messages that were successfully acknowledged by the consumer group member of a stream.
    ///
    /// - Documentation: [XACK](https:/redis.io/docs/latest/commands/xack)
    /// - Version: 5.0.0
    /// - Complexity: O(1) for each message ID processed.
    /// - Categories: @write, @stream, @fast
    /// - Response: [Integer](https:/redis.io/docs/reference/protocol-spec#integers): The command returns the number of messages successfully acknowledged. Certain message IDs may no longer be part of the PEL (for example because they have already been acknowledged), and XACK will not count them as successfully acknowledged.
    @inlinable
    public static func xack(key: RedisKey, group: String, id: String) -> RESPCommand {
        RESPCommand("XACK", key, group, id)
    }

    /// Returns the number of messages that were successfully acknowledged by the consumer group member of a stream.
    ///
    /// - Documentation: [XACK](https:/redis.io/docs/latest/commands/xack)
    /// - Version: 5.0.0
    /// - Complexity: O(1) for each message ID processed.
    /// - Categories: @write, @stream, @fast
    /// - Response: [Integer](https:/redis.io/docs/reference/protocol-spec#integers): The command returns the number of messages successfully acknowledged. Certain message IDs may no longer be part of the PEL (for example because they have already been acknowledged), and XACK will not count them as successfully acknowledged.
    @inlinable
    public static func xack(key: RedisKey, group: String, ids: [String]) -> RESPCommand {
        RESPCommand("XACK", key, group, ids)
    }

    public enum XADDTrimStrategy: RESPRenderable {
        case maxlen
        case minid

        @inlinable
        public func writeToRESPBuffer(_ buffer: inout ByteBuffer) -> Int {
            switch self {
            case .maxlen: "MAXLEN".writeToRESPBuffer(&buffer)
            case .minid: "MINID".writeToRESPBuffer(&buffer)
            }
        }
    }
    public enum XADDTrimOperator: RESPRenderable {
        case equal
        case approximately

        @inlinable
        public func writeToRESPBuffer(_ buffer: inout ByteBuffer) -> Int {
            switch self {
            case .equal: "=".writeToRESPBuffer(&buffer)
            case .approximately: "~".writeToRESPBuffer(&buffer)
            }
        }
    }
    public struct XADDTrim: RESPRenderable {
        @usableFromInline let strategy: XADDTrimStrategy
        @usableFromInline let `operator`: XADDTrimOperator?
        @usableFromInline let threshold: String
        @usableFromInline let count: Int?

        @inlinable
        public func writeToRESPBuffer(_ buffer: inout ByteBuffer) -> Int {
            var count = 0
            count += self.strategy.writeToRESPBuffer(&buffer)
            count += self.operator.writeToRESPBuffer(&buffer)
            count += self.threshold.writeToRESPBuffer(&buffer)
            count += RESPWithToken("LIMIT", count).writeToRESPBuffer(&buffer)
            return count
        }
    }
    public enum XADDIdSelector: RESPRenderable {
        case autoId
        case id(String)

        @inlinable
        public func writeToRESPBuffer(_ buffer: inout ByteBuffer) -> Int {
            switch self {
            case .autoId: "*".writeToRESPBuffer(&buffer)
            case .id(let id): id.writeToRESPBuffer(&buffer)
            }
        }
    }
    public struct XADDData: RESPRenderable {
        @usableFromInline let field: String
        @usableFromInline let value: String

        @inlinable
        public func writeToRESPBuffer(_ buffer: inout ByteBuffer) -> Int {
            var count = 0
            count += self.field.writeToRESPBuffer(&buffer)
            count += self.value.writeToRESPBuffer(&buffer)
            return count
        }
    }
    /// Appends a new message to a stream. Creates the key if it doesn't exist.
    ///
    /// - Documentation: [XADD](https:/redis.io/docs/latest/commands/xadd)
    /// - Version: 5.0.0
    /// - Complexity: O(1) when adding a new entry, O(N) when trimming where N being the number of entries evicted.
    /// - Categories: @write, @stream, @fast
    /// - Response: One of the following:
    ///     * [Bulk string](https:/redis.io/docs/reference/protocol-spec#bulk-strings): The ID of the added entry. The ID is the one automatically generated if an asterisk (`*`) is passed as the _id_ argument, otherwise the command just returns the same ID specified by the user during insertion.
    ///     * [Null](https:/redis.io/docs/reference/protocol-spec#nulls): if the NOMKSTREAM option is given and the key doesn't exist.
    @inlinable
    public static func xadd(key: RedisKey, nomkstream: Bool = false, trim: XADDTrim? = nil, idSelector: XADDIdSelector, data: XADDData) -> RESPCommand {
        RESPCommand("XADD", key, RedisPureToken("NOMKSTREAM", nomkstream), trim, idSelector, data)
    }

    /// Appends a new message to a stream. Creates the key if it doesn't exist.
    ///
    /// - Documentation: [XADD](https:/redis.io/docs/latest/commands/xadd)
    /// - Version: 5.0.0
    /// - Complexity: O(1) when adding a new entry, O(N) when trimming where N being the number of entries evicted.
    /// - Categories: @write, @stream, @fast
    /// - Response: One of the following:
    ///     * [Bulk string](https:/redis.io/docs/reference/protocol-spec#bulk-strings): The ID of the added entry. The ID is the one automatically generated if an asterisk (`*`) is passed as the _id_ argument, otherwise the command just returns the same ID specified by the user during insertion.
    ///     * [Null](https:/redis.io/docs/reference/protocol-spec#nulls): if the NOMKSTREAM option is given and the key doesn't exist.
    @inlinable
    public static func xadd(key: RedisKey, nomkstream: Bool = false, trim: XADDTrim? = nil, idSelector: XADDIdSelector, datas: [XADDData]) -> RESPCommand {
        RESPCommand("XADD", key, RedisPureToken("NOMKSTREAM", nomkstream), trim, idSelector, datas)
    }

    /// Changes, or acquires, ownership of messages in a consumer group, as if the messages were delivered to as consumer group member.
    ///
    /// - Documentation: [XAUTOCLAIM](https:/redis.io/docs/latest/commands/xautoclaim)
    /// - Version: 6.2.0
    /// - Complexity: O(1) if COUNT is small.
    /// - Categories: @write, @stream, @fast
    /// - Response: [Array](https:/redis.io/docs/reference/protocol-spec#arrays), specifically, an array with three elements:
    ///     1. A stream ID to be used as the _start_ argument for the next call to XAUTOCLAIM.
    ///     2. An [Array](https:/redis.io/docs/reference/protocol-spec#arrays) containing all the successfully claimed messages in the same format as `XRANGE`.
    ///     3. An [Array](https:/redis.io/docs/reference/protocol-spec#arrays) containing message IDs that no longer exist in the stream, and were deleted from the PEL in which they were found.
    @inlinable
    public static func xautoclaim(key: RedisKey, group: String, consumer: String, minIdleTime: String, start: String, count: Int? = nil, justid: Bool = false) -> RESPCommand {
        RESPCommand("XAUTOCLAIM", key, group, consumer, minIdleTime, start, RESPWithToken("COUNT", count), RedisPureToken("JUSTID", justid))
    }

    /// Changes, or acquires, ownership of a message in a consumer group, as if the message was delivered a consumer group member.
    ///
    /// - Documentation: [XCLAIM](https:/redis.io/docs/latest/commands/xclaim)
    /// - Version: 5.0.0
    /// - Complexity: O(log N) with N being the number of messages in the PEL of the consumer group.
    /// - Categories: @write, @stream, @fast
    /// - Response: Any of the following:
    ///     * [Array](https:/redis.io/docs/reference/protocol-spec#arrays): when the _JUSTID_ option is specified, an array of IDs of messages successfully claimed.
    ///     * [Array](https:/redis.io/docs/reference/protocol-spec#arrays): an array of stream entries, each of which contains an array of two elements, the entry ID and the entry data itself.
    @inlinable
    public static func xclaim(key: RedisKey, group: String, consumer: String, minIdleTime: String, id: String, ms: Int? = nil, unixTimeMilliseconds: Date? = nil, count: Int? = nil, force: Bool = false, justid: Bool = false, lastid: String? = nil) -> RESPCommand {
        RESPCommand("XCLAIM", key, group, consumer, minIdleTime, id, RESPWithToken("IDLE", ms), RESPWithToken("TIME", unixTimeMilliseconds), RESPWithToken("RETRYCOUNT", count), RedisPureToken("FORCE", force), RedisPureToken("JUSTID", justid), RESPWithToken("LASTID", lastid))
    }

    /// Changes, or acquires, ownership of a message in a consumer group, as if the message was delivered a consumer group member.
    ///
    /// - Documentation: [XCLAIM](https:/redis.io/docs/latest/commands/xclaim)
    /// - Version: 5.0.0
    /// - Complexity: O(log N) with N being the number of messages in the PEL of the consumer group.
    /// - Categories: @write, @stream, @fast
    /// - Response: Any of the following:
    ///     * [Array](https:/redis.io/docs/reference/protocol-spec#arrays): when the _JUSTID_ option is specified, an array of IDs of messages successfully claimed.
    ///     * [Array](https:/redis.io/docs/reference/protocol-spec#arrays): an array of stream entries, each of which contains an array of two elements, the entry ID and the entry data itself.
    @inlinable
    public static func xclaim(key: RedisKey, group: String, consumer: String, minIdleTime: String, ids: [String], ms: Int? = nil, unixTimeMilliseconds: Date? = nil, count: Int? = nil, force: Bool = false, justid: Bool = false, lastid: String? = nil) -> RESPCommand {
        RESPCommand("XCLAIM", key, group, consumer, minIdleTime, ids, RESPWithToken("IDLE", ms), RESPWithToken("TIME", unixTimeMilliseconds), RESPWithToken("RETRYCOUNT", count), RedisPureToken("FORCE", force), RedisPureToken("JUSTID", justid), RESPWithToken("LASTID", lastid))
    }

    /// Returns the number of messages after removing them from a stream.
    ///
    /// - Documentation: [XDEL](https:/redis.io/docs/latest/commands/xdel)
    /// - Version: 5.0.0
    /// - Complexity: O(1) for each single item to delete in the stream, regardless of the stream size.
    /// - Categories: @write, @stream, @fast
    /// - Response: [Integer](https:/redis.io/docs/reference/protocol-spec#integers): the number of entries that were deleted.
    @inlinable
    public static func xdel(key: RedisKey, id: String) -> RESPCommand {
        RESPCommand("XDEL", key, id)
    }

    /// Returns the number of messages after removing them from a stream.
    ///
    /// - Documentation: [XDEL](https:/redis.io/docs/latest/commands/xdel)
    /// - Version: 5.0.0
    /// - Complexity: O(1) for each single item to delete in the stream, regardless of the stream size.
    /// - Categories: @write, @stream, @fast
    /// - Response: [Integer](https:/redis.io/docs/reference/protocol-spec#integers): the number of entries that were deleted.
    @inlinable
    public static func xdel(key: RedisKey, ids: [String]) -> RESPCommand {
        RESPCommand("XDEL", key, ids)
    }

    public enum XGROUPCREATEIdSelector: RESPRenderable {
        case id(String)
        case newId

        @inlinable
        public func writeToRESPBuffer(_ buffer: inout ByteBuffer) -> Int {
            switch self {
            case .id(let id): id.writeToRESPBuffer(&buffer)
            case .newId: "$".writeToRESPBuffer(&buffer)
            }
        }
    }
    /// Creates a consumer group.
    ///
    /// - Documentation: [XGROUP CREATE](https:/redis.io/docs/latest/commands/xgroup-create)
    /// - Version: 5.0.0
    /// - Complexity: O(1)
    /// - Categories: @write, @stream, @slow
    /// - Response: [Simple string](https:/redis.io/docs/reference/protocol-spec#simple-strings): `OK`.
    @inlinable
    public static func xgroupCreate(key: RedisKey, group: String, idSelector: XGROUPCREATEIdSelector, mkstream: Bool = false, entriesRead: Int? = nil) -> RESPCommand {
        RESPCommand("XGROUP", "CREATE", key, group, idSelector, RedisPureToken("MKSTREAM", mkstream), RESPWithToken("ENTRIESREAD", entriesRead))
    }

    /// Creates a consumer in a consumer group.
    ///
    /// - Documentation: [XGROUP CREATECONSUMER](https:/redis.io/docs/latest/commands/xgroup-createconsumer)
    /// - Version: 6.2.0
    /// - Complexity: O(1)
    /// - Categories: @write, @stream, @slow
    /// - Response: [Integer](https:/redis.io/docs/reference/protocol-spec#integers): the number of created consumers, either 0 or 1.
    @inlinable
    public static func xgroupCreateconsumer(key: RedisKey, group: String, consumer: String) -> RESPCommand {
        RESPCommand("XGROUP", "CREATECONSUMER", key, group, consumer)
    }

    /// Deletes a consumer from a consumer group.
    ///
    /// - Documentation: [XGROUP DELCONSUMER](https:/redis.io/docs/latest/commands/xgroup-delconsumer)
    /// - Version: 5.0.0
    /// - Complexity: O(1)
    /// - Categories: @write, @stream, @slow
    /// - Response: [Integer](https:/redis.io/docs/reference/protocol-spec#integers): the number of pending messages the consumer had before it was deleted.
    @inlinable
    public static func xgroupDelconsumer(key: RedisKey, group: String, consumer: String) -> RESPCommand {
        RESPCommand("XGROUP", "DELCONSUMER", key, group, consumer)
    }

    /// Destroys a consumer group.
    ///
    /// - Documentation: [XGROUP DESTROY](https:/redis.io/docs/latest/commands/xgroup-destroy)
    /// - Version: 5.0.0
    /// - Complexity: O(N) where N is the number of entries in the group's pending entries list (PEL).
    /// - Categories: @write, @stream, @slow
    /// - Response: [Integer](https:/redis.io/docs/reference/protocol-spec#integers): the number of destroyed consumer groups, either 0 or 1.
    @inlinable
    public static func xgroupDestroy(key: RedisKey, group: String) -> RESPCommand {
        RESPCommand("XGROUP", "DESTROY", key, group)
    }

    /// Returns helpful text about the different subcommands.
    ///
    /// - Documentation: [XGROUP HELP](https:/redis.io/docs/latest/commands/xgroup-help)
    /// - Version: 5.0.0
    /// - Complexity: O(1)
    /// - Categories: @stream, @slow
    /// - Response: [Array](https:/redis.io/docs/reference/protocol-spec#arrays): a list of sub-commands and their descriptions.
    @inlinable
    public static func xgroupHelp() -> RESPCommand {
        RESPCommand("XGROUP", "HELP")
    }

    public enum XGROUPSETIDIdSelector: RESPRenderable {
        case id(String)
        case newId

        @inlinable
        public func writeToRESPBuffer(_ buffer: inout ByteBuffer) -> Int {
            switch self {
            case .id(let id): id.writeToRESPBuffer(&buffer)
            case .newId: "$".writeToRESPBuffer(&buffer)
            }
        }
    }
    /// Sets the last-delivered ID of a consumer group.
    ///
    /// - Documentation: [XGROUP SETID](https:/redis.io/docs/latest/commands/xgroup-setid)
    /// - Version: 5.0.0
    /// - Complexity: O(1)
    /// - Categories: @write, @stream, @slow
    /// - Response: [Simple string](https:/redis.io/docs/reference/protocol-spec#simple-strings): `OK`.
    @inlinable
    public static func xgroupSetid(key: RedisKey, group: String, idSelector: XGROUPSETIDIdSelector, entriesread: Int? = nil) -> RESPCommand {
        RESPCommand("XGROUP", "SETID", key, group, idSelector, RESPWithToken("ENTRIESREAD", entriesread))
    }

    /// Returns a list of the consumers in a consumer group.
    ///
    /// - Documentation: [XINFO CONSUMERS](https:/redis.io/docs/latest/commands/xinfo-consumers)
    /// - Version: 5.0.0
    /// - Complexity: O(1)
    /// - Categories: @read, @stream, @slow
    /// - Response: [Array](https:/redis.io/docs/reference/protocol-spec#arrays): a list of consumers and their attributes.
    @inlinable
    public static func xinfoConsumers(key: RedisKey, group: String) -> RESPCommand {
        RESPCommand("XINFO", "CONSUMERS", key, group)
    }

    /// Returns a list of the consumer groups of a stream.
    ///
    /// - Documentation: [XINFO GROUPS](https:/redis.io/docs/latest/commands/xinfo-groups)
    /// - Version: 5.0.0
    /// - Complexity: O(1)
    /// - Categories: @read, @stream, @slow
    /// - Response: [Array](https:/redis.io/docs/reference/protocol-spec#arrays): a list of consumer groups.
    @inlinable
    public static func xinfoGroups(key: RedisKey) -> RESPCommand {
        RESPCommand("XINFO", "GROUPS", key)
    }

    /// Returns helpful text about the different subcommands.
    ///
    /// - Documentation: [XINFO HELP](https:/redis.io/docs/latest/commands/xinfo-help)
    /// - Version: 5.0.0
    /// - Complexity: O(1)
    /// - Categories: @stream, @slow
    /// - Response: [Array](https:/redis.io/docs/reference/protocol-spec#arrays): a list of sub-commands and their descriptions.
    @inlinable
    public static func xinfoHelp() -> RESPCommand {
        RESPCommand("XINFO", "HELP")
    }

    public struct XINFOSTREAMFullBlock: RESPRenderable {
        @usableFromInline let full: Bool
        @usableFromInline let count: Int?

        @inlinable
        public func writeToRESPBuffer(_ buffer: inout ByteBuffer) -> Int {
            var count = 0
            if self.full { count += "FULL".writeToRESPBuffer(&buffer) }
            count += RESPWithToken("COUNT", count).writeToRESPBuffer(&buffer)
            return count
        }
    }
    /// Returns information about a stream.
    ///
    /// - Documentation: [XINFO STREAM](https:/redis.io/docs/latest/commands/xinfo-stream)
    /// - Version: 5.0.0
    /// - Complexity: O(1)
    /// - Categories: @read, @stream, @slow
    /// - Response: One of the following:
    ///     * [Map](https:/redis.io/docs/reference/protocol-spec#maps): when the _FULL_ argument was not given, a list of information about a stream in summary form.
    ///     * [Map](https:/redis.io/docs/reference/protocol-spec#maps): when the _FULL_ argument was given, a list of information about a stream in extended form.
    @inlinable
    public static func xinfoStream(key: RedisKey, fullBlock: XINFOSTREAMFullBlock? = nil) -> RESPCommand {
        RESPCommand("XINFO", "STREAM", key, fullBlock)
    }

    /// Return the number of messages in a stream.
    ///
    /// - Documentation: [XLEN](https:/redis.io/docs/latest/commands/xlen)
    /// - Version: 5.0.0
    /// - Complexity: O(1)
    /// - Categories: @read, @stream, @fast
    /// - Response: [Integer](https:/redis.io/docs/reference/protocol-spec#integers): the number of entries of the stream at _key_.
    @inlinable
    public static func xlen(key: RedisKey) -> RESPCommand {
        RESPCommand("XLEN", key)
    }

    public struct XPENDINGFilters: RESPRenderable {
        @usableFromInline let minIdleTime: Int?
        @usableFromInline let start: String
        @usableFromInline let end: String
        @usableFromInline let count: Int
        @usableFromInline let consumer: String?

        @inlinable
        public func writeToRESPBuffer(_ buffer: inout ByteBuffer) -> Int {
            var count = 0
            count += RESPWithToken("IDLE", minIdleTime).writeToRESPBuffer(&buffer)
            count += self.start.writeToRESPBuffer(&buffer)
            count += self.end.writeToRESPBuffer(&buffer)
            count += self.count.writeToRESPBuffer(&buffer)
            count += self.consumer.writeToRESPBuffer(&buffer)
            return count
        }
    }
    /// Returns the information and entries from a stream consumer group's pending entries list.
    ///
    /// - Documentation: [XPENDING](https:/redis.io/docs/latest/commands/xpending)
    /// - Version: 5.0.0
    /// - Complexity: O(N) with N being the number of elements returned, so asking for a small fixed number of entries per call is O(1). O(M), where M is the total number of entries scanned when used with the IDLE filter. When the command returns just the summary and the list of consumers is small, it runs in O(1) time; otherwise, an additional O(N) time for iterating every consumer.
    /// - Categories: @read, @stream, @slow
    /// - Response: * [Array](https:/redis.io/docs/reference/protocol-spec#arrays): different data depending on the way XPENDING is called, as explained on this page.
    @inlinable
    public static func xpending(key: RedisKey, group: String, filters: XPENDINGFilters? = nil) -> RESPCommand {
        RESPCommand("XPENDING", key, group, filters)
    }

    /// Returns the messages from a stream within a range of IDs.
    ///
    /// - Documentation: [XRANGE](https:/redis.io/docs/latest/commands/xrange)
    /// - Version: 5.0.0
    /// - Complexity: O(N) with N being the number of elements being returned. If N is constant (e.g. always asking for the first 10 elements with COUNT), you can consider it O(1).
    /// - Categories: @read, @stream, @slow
    /// - Response: [Array](https:/redis.io/docs/reference/protocol-spec#arrays): a list of stream entries with IDs matching the specified range.
    @inlinable
    public static func xrange(key: RedisKey, start: String, end: String, count: Int? = nil) -> RESPCommand {
        RESPCommand("XRANGE", key, start, end, RESPWithToken("COUNT", count))
    }

    public struct XREADStreams: RESPRenderable {
        @usableFromInline let key: [RedisKey]
        @usableFromInline let id: [String]

        @inlinable
        public func writeToRESPBuffer(_ buffer: inout ByteBuffer) -> Int {
            var count = 0
            count += self.key.writeToRESPBuffer(&buffer)
            count += self.id.writeToRESPBuffer(&buffer)
            return count
        }
    }
    /// Returns messages from multiple streams with IDs greater than the ones requested. Blocks until a message is available otherwise.
    ///
    /// - Documentation: [XREAD](https:/redis.io/docs/latest/commands/xread)
    /// - Version: 5.0.0
    /// - Categories: @read, @stream, @slow, @blocking
    /// - Response: One of the following:
    ///     * [Map](https:/redis.io/docs/reference/protocol-spec#maps): A map of key-value elements where each element is composed of the key name and the entries reported for that key. The entries reported are full stream entries, having IDs and the list of all the fields and values. Field and values are guaranteed to be reported in the same order they were added by `XADD`.
    ///     * [Null](https:/redis.io/docs/reference/protocol-spec#nulls): if the _BLOCK_ option is given and a timeout occurs, or if there is no stream that can be served.
    @inlinable
    public static func xread(count: Int? = nil, milliseconds: Int? = nil, streams: XREADStreams) -> RESPCommand {
        RESPCommand("XREAD", RESPWithToken("COUNT", count), RESPWithToken("BLOCK", milliseconds), RESPWithToken("STREAMS", streams))
    }

    public struct XREADGROUPGroupBlock: RESPRenderable {
        @usableFromInline let group: String
        @usableFromInline let consumer: String

        @inlinable
        public func writeToRESPBuffer(_ buffer: inout ByteBuffer) -> Int {
            var count = 0
            count += self.group.writeToRESPBuffer(&buffer)
            count += self.consumer.writeToRESPBuffer(&buffer)
            return count
        }
    }
    public struct XREADGROUPStreams: RESPRenderable {
        @usableFromInline let key: [RedisKey]
        @usableFromInline let id: [String]

        @inlinable
        public func writeToRESPBuffer(_ buffer: inout ByteBuffer) -> Int {
            var count = 0
            count += self.key.writeToRESPBuffer(&buffer)
            count += self.id.writeToRESPBuffer(&buffer)
            return count
        }
    }
    /// Returns new or historical messages from a stream for a consumer in a group. Blocks until a message is available otherwise.
    ///
    /// - Documentation: [XREADGROUP](https:/redis.io/docs/latest/commands/xreadgroup)
    /// - Version: 5.0.0
    /// - Complexity: For each stream mentioned: O(M) with M being the number of elements returned. If M is constant (e.g. always asking for the first 10 elements with COUNT), you can consider it O(1). On the other side when XREADGROUP blocks, XADD will pay the O(N) time in order to serve the N clients blocked on the stream getting new data.
    /// - Categories: @write, @stream, @slow, @blocking
    /// - Response: One of the following:
    ///     * [Map](https:/redis.io/docs/reference/protocol-spec#maps): A map of key-value elements where each element is composed of the key name and the entries reported for that key. The entries reported are full stream entries, having IDs and the list of all the fields and values. Field and values are guaranteed to be reported in the same order they were added by `XADD`.
    ///     * [Null](https:/redis.io/docs/reference/protocol-spec#nulls): if the _BLOCK_ option is given and a timeout occurs, or if there is no stream that can be served.
    @inlinable
    public static func xreadgroup(groupBlock: XREADGROUPGroupBlock, count: Int? = nil, milliseconds: Int? = nil, noack: Bool = false, streams: XREADGROUPStreams) -> RESPCommand {
        RESPCommand("XREADGROUP", RESPWithToken("GROUP", groupBlock), RESPWithToken("COUNT", count), RESPWithToken("BLOCK", milliseconds), RedisPureToken("NOACK", noack), RESPWithToken("STREAMS", streams))
    }

    /// Returns the messages from a stream within a range of IDs in reverse order.
    ///
    /// - Documentation: [XREVRANGE](https:/redis.io/docs/latest/commands/xrevrange)
    /// - Version: 5.0.0
    /// - Complexity: O(N) with N being the number of elements returned. If N is constant (e.g. always asking for the first 10 elements with COUNT), you can consider it O(1).
    /// - Categories: @read, @stream, @slow
    /// - Response: [Array](https:/redis.io/docs/reference/protocol-spec#arrays): The command returns the entries with IDs matching the specified range. The returned entries are complete, which means that the ID and all the fields they are composed of are returned. Moreover, the entries are returned with their fields and values in the same order as `XADD` added them.
    @inlinable
    public static func xrevrange(key: RedisKey, end: String, start: String, count: Int? = nil) -> RESPCommand {
        RESPCommand("XREVRANGE", key, end, start, RESPWithToken("COUNT", count))
    }

    /// An internal command for replicating stream values.
    ///
    /// - Documentation: [XSETID](https:/redis.io/docs/latest/commands/xsetid)
    /// - Version: 5.0.0
    /// - Complexity: O(1)
    /// - Categories: @write, @stream, @fast
    /// - Response: [Simple string](https:/redis.io/docs/reference/protocol-spec#simple-strings): `OK`.
    @inlinable
    public static func xsetid(key: RedisKey, lastId: String, entriesAdded: Int? = nil, maxDeletedId: String? = nil) -> RESPCommand {
        RESPCommand("XSETID", key, lastId, RESPWithToken("ENTRIESADDED", entriesAdded), RESPWithToken("MAXDELETEDID", maxDeletedId))
    }

    public enum XTRIMTrimStrategy: RESPRenderable {
        case maxlen
        case minid

        @inlinable
        public func writeToRESPBuffer(_ buffer: inout ByteBuffer) -> Int {
            switch self {
            case .maxlen: "MAXLEN".writeToRESPBuffer(&buffer)
            case .minid: "MINID".writeToRESPBuffer(&buffer)
            }
        }
    }
    public enum XTRIMTrimOperator: RESPRenderable {
        case equal
        case approximately

        @inlinable
        public func writeToRESPBuffer(_ buffer: inout ByteBuffer) -> Int {
            switch self {
            case .equal: "=".writeToRESPBuffer(&buffer)
            case .approximately: "~".writeToRESPBuffer(&buffer)
            }
        }
    }
    public struct XTRIMTrim: RESPRenderable {
        @usableFromInline let strategy: XTRIMTrimStrategy
        @usableFromInline let `operator`: XTRIMTrimOperator?
        @usableFromInline let threshold: String
        @usableFromInline let count: Int?

        @inlinable
        public func writeToRESPBuffer(_ buffer: inout ByteBuffer) -> Int {
            var count = 0
            count += self.strategy.writeToRESPBuffer(&buffer)
            count += self.operator.writeToRESPBuffer(&buffer)
            count += self.threshold.writeToRESPBuffer(&buffer)
            count += RESPWithToken("LIMIT", count).writeToRESPBuffer(&buffer)
            return count
        }
    }
    /// Deletes messages from the beginning of a stream.
    ///
    /// - Documentation: [XTRIM](https:/redis.io/docs/latest/commands/xtrim)
    /// - Version: 5.0.0
    /// - Complexity: O(N), with N being the number of evicted entries. Constant times are very small however, since entries are organized in macro nodes containing multiple entries that can be released with a single deallocation.
    /// - Categories: @write, @stream, @slow
    /// - Response: [Integer](https:/redis.io/docs/reference/protocol-spec#integers): The number of entries deleted from the stream.
    @inlinable
    public static func xtrim(key: RedisKey, trim: XTRIMTrim) -> RESPCommand {
        RESPCommand("XTRIM", key, trim)
    }

    public enum ZADDCondition: RESPRenderable {
        case nx
        case xx

        @inlinable
        public func writeToRESPBuffer(_ buffer: inout ByteBuffer) -> Int {
            switch self {
            case .nx: "NX".writeToRESPBuffer(&buffer)
            case .xx: "XX".writeToRESPBuffer(&buffer)
            }
        }
    }
    public enum ZADDComparison: RESPRenderable {
        case gt
        case lt

        @inlinable
        public func writeToRESPBuffer(_ buffer: inout ByteBuffer) -> Int {
            switch self {
            case .gt: "GT".writeToRESPBuffer(&buffer)
            case .lt: "LT".writeToRESPBuffer(&buffer)
            }
        }
    }
    public struct ZADDData: RESPRenderable {
        @usableFromInline let score: Double
        @usableFromInline let member: String

        @inlinable
        public func writeToRESPBuffer(_ buffer: inout ByteBuffer) -> Int {
            var count = 0
            count += self.score.writeToRESPBuffer(&buffer)
            count += self.member.writeToRESPBuffer(&buffer)
            return count
        }
    }
    /// Adds one or more members to a sorted set, or updates their scores. Creates the key if it doesn't exist.
    ///
    /// - Documentation: [ZADD](https:/redis.io/docs/latest/commands/zadd)
    /// - Version: 1.2.0
    /// - Complexity: O(log(N)) for each item added, where N is the number of elements in the sorted set.
    /// - Categories: @write, @sortedset, @fast
    /// - Response: Any of the following:
    ///     * [Null](https:/redis.io/docs/reference/protocol-spec#nulls): if the operation was aborted because of a conflict with one of the _XX/NX/LT/GT_ options.
    ///     * [Integer](https:/redis.io/docs/reference/protocol-spec#integers): the number of new members when the _CH_ option is not used.
    ///     * [Integer](https:/redis.io/docs/reference/protocol-spec#integers): the number of new or updated members when the _CH_ option is used.
    ///     * [Double](https:/redis.io/docs/reference/protocol-spec#doubles): the updated score of the member when the _INCR_ option is used.
    @inlinable
    public static func zadd(key: RedisKey, condition: ZADDCondition? = nil, comparison: ZADDComparison? = nil, change: Bool = false, increment: Bool = false, data: ZADDData) -> RESPCommand {
        RESPCommand("ZADD", key, condition, comparison, RedisPureToken("CH", change), RedisPureToken("INCR", increment), data)
    }

    /// Adds one or more members to a sorted set, or updates their scores. Creates the key if it doesn't exist.
    ///
    /// - Documentation: [ZADD](https:/redis.io/docs/latest/commands/zadd)
    /// - Version: 1.2.0
    /// - Complexity: O(log(N)) for each item added, where N is the number of elements in the sorted set.
    /// - Categories: @write, @sortedset, @fast
    /// - Response: Any of the following:
    ///     * [Null](https:/redis.io/docs/reference/protocol-spec#nulls): if the operation was aborted because of a conflict with one of the _XX/NX/LT/GT_ options.
    ///     * [Integer](https:/redis.io/docs/reference/protocol-spec#integers): the number of new members when the _CH_ option is not used.
    ///     * [Integer](https:/redis.io/docs/reference/protocol-spec#integers): the number of new or updated members when the _CH_ option is used.
    ///     * [Double](https:/redis.io/docs/reference/protocol-spec#doubles): the updated score of the member when the _INCR_ option is used.
    @inlinable
    public static func zadd(key: RedisKey, condition: ZADDCondition? = nil, comparison: ZADDComparison? = nil, change: Bool = false, increment: Bool = false, datas: [ZADDData]) -> RESPCommand {
        RESPCommand("ZADD", key, condition, comparison, RedisPureToken("CH", change), RedisPureToken("INCR", increment), datas)
    }

    /// Returns the number of members in a sorted set.
    ///
    /// - Documentation: [ZCARD](https:/redis.io/docs/latest/commands/zcard)
    /// - Version: 1.2.0
    /// - Complexity: O(1)
    /// - Categories: @read, @sortedset, @fast
    /// - Response: [Integer](https:/redis.io/docs/reference/protocol-spec#integers): the cardinality (number of members) of the sorted set, or 0 if the key doesn't exist.
    @inlinable
    public static func zcard(key: RedisKey) -> RESPCommand {
        RESPCommand("ZCARD", key)
    }

    /// Returns the count of members in a sorted set that have scores within a range.
    ///
    /// - Documentation: [ZCOUNT](https:/redis.io/docs/latest/commands/zcount)
    /// - Version: 2.0.0
    /// - Complexity: O(log(N)) with N being the number of elements in the sorted set.
    /// - Categories: @read, @sortedset, @fast
    /// - Response: [Integer](https:/redis.io/docs/reference/protocol-spec#integers): the number of members in the specified score range.
    @inlinable
    public static func zcount(key: RedisKey, min: Double, max: Double) -> RESPCommand {
        RESPCommand("ZCOUNT", key, min, max)
    }

    /// Returns the difference between multiple sorted sets.
    ///
    /// - Documentation: [ZDIFF](https:/redis.io/docs/latest/commands/zdiff)
    /// - Version: 6.2.0
    /// - Complexity: O(L + (N-K)log(N)) worst case where L is the total number of elements in all the sets, N is the size of the first set, and K is the size of the result set.
    /// - Categories: @read, @sortedset, @slow
    /// - Response: * [Array](https:/redis.io/docs/reference/protocol-spec#arrays): the result of the difference including, optionally, scores when the _WITHSCORES_ option is used.
    @inlinable
    public static func zdiff(key: RedisKey, withscores: Bool = false) -> RESPCommand {
        RESPCommand("ZDIFF", 1, key, RedisPureToken("WITHSCORES", withscores))
    }

    /// Returns the difference between multiple sorted sets.
    ///
    /// - Documentation: [ZDIFF](https:/redis.io/docs/latest/commands/zdiff)
    /// - Version: 6.2.0
    /// - Complexity: O(L + (N-K)log(N)) worst case where L is the total number of elements in all the sets, N is the size of the first set, and K is the size of the result set.
    /// - Categories: @read, @sortedset, @slow
    /// - Response: * [Array](https:/redis.io/docs/reference/protocol-spec#arrays): the result of the difference including, optionally, scores when the _WITHSCORES_ option is used.
    @inlinable
    public static func zdiff(keys: [RedisKey], withscores: Bool = false) -> RESPCommand {
        RESPCommand("ZDIFF", RESPArrayWithCount(keys), RedisPureToken("WITHSCORES", withscores))
    }

    /// Stores the difference of multiple sorted sets in a key.
    ///
    /// - Documentation: [ZDIFFSTORE](https:/redis.io/docs/latest/commands/zdiffstore)
    /// - Version: 6.2.0
    /// - Complexity: O(L + (N-K)log(N)) worst case where L is the total number of elements in all the sets, N is the size of the first set, and K is the size of the result set.
    /// - Categories: @write, @sortedset, @slow
    /// - Response: [Integer](https:/redis.io/docs/reference/protocol-spec#integers): the number of members in the resulting sorted set at _destination_.
    @inlinable
    public static func zdiffstore(destination: RedisKey, key: RedisKey) -> RESPCommand {
        RESPCommand("ZDIFFSTORE", destination, 1, key)
    }

    /// Stores the difference of multiple sorted sets in a key.
    ///
    /// - Documentation: [ZDIFFSTORE](https:/redis.io/docs/latest/commands/zdiffstore)
    /// - Version: 6.2.0
    /// - Complexity: O(L + (N-K)log(N)) worst case where L is the total number of elements in all the sets, N is the size of the first set, and K is the size of the result set.
    /// - Categories: @write, @sortedset, @slow
    /// - Response: [Integer](https:/redis.io/docs/reference/protocol-spec#integers): the number of members in the resulting sorted set at _destination_.
    @inlinable
    public static func zdiffstore(destination: RedisKey, keys: [RedisKey]) -> RESPCommand {
        RESPCommand("ZDIFFSTORE", destination, RESPArrayWithCount(keys))
    }

    /// Increments the score of a member in a sorted set.
    ///
    /// - Documentation: [ZINCRBY](https:/redis.io/docs/latest/commands/zincrby)
    /// - Version: 1.2.0
    /// - Complexity: O(log(N)) where N is the number of elements in the sorted set.
    /// - Categories: @write, @sortedset, @fast
    /// - Response: [Double](https:/redis.io/docs/reference/protocol-spec#doubles): the new score of _member_.
    @inlinable
    public static func zincrby(key: RedisKey, increment: Int, member: String) -> RESPCommand {
        RESPCommand("ZINCRBY", key, increment, member)
    }

    public enum ZINTERAggregate: RESPRenderable {
        case sum
        case min
        case max

        @inlinable
        public func writeToRESPBuffer(_ buffer: inout ByteBuffer) -> Int {
            switch self {
            case .sum: "SUM".writeToRESPBuffer(&buffer)
            case .min: "MIN".writeToRESPBuffer(&buffer)
            case .max: "MAX".writeToRESPBuffer(&buffer)
            }
        }
    }
    /// Returns the intersect of multiple sorted sets.
    ///
    /// - Documentation: [ZINTER](https:/redis.io/docs/latest/commands/zinter)
    /// - Version: 6.2.0
    /// - Complexity: O(N*K)+O(M*log(M)) worst case with N being the smallest input sorted set, K being the number of input sorted sets and M being the number of elements in the resulting sorted set.
    /// - Categories: @read, @sortedset, @slow
    /// - Response: * [Array](https:/redis.io/docs/reference/protocol-spec#arrays): the result of the intersection including, optionally, scores when the _WITHSCORES_ option is used.
    @inlinable
    public static func zinter(key: RedisKey, weight: Int? = nil, aggregate: ZINTERAggregate? = nil, withscores: Bool = false) -> RESPCommand {
        RESPCommand("ZINTER", 1, key, RESPWithToken("WEIGHTS", weight), RESPWithToken("AGGREGATE", aggregate), RedisPureToken("WITHSCORES", withscores))
    }

    /// Returns the intersect of multiple sorted sets.
    ///
    /// - Documentation: [ZINTER](https:/redis.io/docs/latest/commands/zinter)
    /// - Version: 6.2.0
    /// - Complexity: O(N*K)+O(M*log(M)) worst case with N being the smallest input sorted set, K being the number of input sorted sets and M being the number of elements in the resulting sorted set.
    /// - Categories: @read, @sortedset, @slow
    /// - Response: * [Array](https:/redis.io/docs/reference/protocol-spec#arrays): the result of the intersection including, optionally, scores when the _WITHSCORES_ option is used.
    @inlinable
    public static func zinter(keys: [RedisKey], weights: [Int], aggregate: ZINTERAggregate? = nil, withscores: Bool = false) -> RESPCommand {
        RESPCommand("ZINTER", RESPArrayWithCount(keys), RESPWithToken("WEIGHTS", weights), RESPWithToken("AGGREGATE", aggregate), RedisPureToken("WITHSCORES", withscores))
    }

    /// Returns the number of members of the intersect of multiple sorted sets.
    ///
    /// - Documentation: [ZINTERCARD](https:/redis.io/docs/latest/commands/zintercard)
    /// - Version: 7.0.0
    /// - Complexity: O(N*K) worst case with N being the smallest input sorted set, K being the number of input sorted sets.
    /// - Categories: @read, @sortedset, @slow
    /// - Response: [Integer](https:/redis.io/docs/reference/protocol-spec#integers): the number of members in the resulting intersection.
    @inlinable
    public static func zintercard(key: RedisKey, limit: Int? = nil) -> RESPCommand {
        RESPCommand("ZINTERCARD", 1, key, RESPWithToken("LIMIT", limit))
    }

    /// Returns the number of members of the intersect of multiple sorted sets.
    ///
    /// - Documentation: [ZINTERCARD](https:/redis.io/docs/latest/commands/zintercard)
    /// - Version: 7.0.0
    /// - Complexity: O(N*K) worst case with N being the smallest input sorted set, K being the number of input sorted sets.
    /// - Categories: @read, @sortedset, @slow
    /// - Response: [Integer](https:/redis.io/docs/reference/protocol-spec#integers): the number of members in the resulting intersection.
    @inlinable
    public static func zintercard(keys: [RedisKey], limit: Int? = nil) -> RESPCommand {
        RESPCommand("ZINTERCARD", RESPArrayWithCount(keys), RESPWithToken("LIMIT", limit))
    }

    public enum ZINTERSTOREAggregate: RESPRenderable {
        case sum
        case min
        case max

        @inlinable
        public func writeToRESPBuffer(_ buffer: inout ByteBuffer) -> Int {
            switch self {
            case .sum: "SUM".writeToRESPBuffer(&buffer)
            case .min: "MIN".writeToRESPBuffer(&buffer)
            case .max: "MAX".writeToRESPBuffer(&buffer)
            }
        }
    }
    /// Stores the intersect of multiple sorted sets in a key.
    ///
    /// - Documentation: [ZINTERSTORE](https:/redis.io/docs/latest/commands/zinterstore)
    /// - Version: 2.0.0
    /// - Complexity: O(N*K)+O(M*log(M)) worst case with N being the smallest input sorted set, K being the number of input sorted sets and M being the number of elements in the resulting sorted set.
    /// - Categories: @write, @sortedset, @slow
    /// - Response: [Integer](https:/redis.io/docs/reference/protocol-spec#integers): the number of members in the resulting sorted set at the _destination_.
    @inlinable
    public static func zinterstore(destination: RedisKey, key: RedisKey, weight: Int? = nil, aggregate: ZINTERSTOREAggregate? = nil) -> RESPCommand {
        RESPCommand("ZINTERSTORE", destination, 1, key, RESPWithToken("WEIGHTS", weight), RESPWithToken("AGGREGATE", aggregate))
    }

    /// Stores the intersect of multiple sorted sets in a key.
    ///
    /// - Documentation: [ZINTERSTORE](https:/redis.io/docs/latest/commands/zinterstore)
    /// - Version: 2.0.0
    /// - Complexity: O(N*K)+O(M*log(M)) worst case with N being the smallest input sorted set, K being the number of input sorted sets and M being the number of elements in the resulting sorted set.
    /// - Categories: @write, @sortedset, @slow
    /// - Response: [Integer](https:/redis.io/docs/reference/protocol-spec#integers): the number of members in the resulting sorted set at the _destination_.
    @inlinable
    public static func zinterstore(destination: RedisKey, keys: [RedisKey], weights: [Int], aggregate: ZINTERSTOREAggregate? = nil) -> RESPCommand {
        RESPCommand("ZINTERSTORE", destination, RESPArrayWithCount(keys), RESPWithToken("WEIGHTS", weights), RESPWithToken("AGGREGATE", aggregate))
    }

    /// Returns the number of members in a sorted set within a lexicographical range.
    ///
    /// - Documentation: [ZLEXCOUNT](https:/redis.io/docs/latest/commands/zlexcount)
    /// - Version: 2.8.9
    /// - Complexity: O(log(N)) with N being the number of elements in the sorted set.
    /// - Categories: @read, @sortedset, @fast
    /// - Response: [Integer](https:/redis.io/docs/reference/protocol-spec#integers): the number of members in the specified score range.
    @inlinable
    public static func zlexcount(key: RedisKey, min: String, max: String) -> RESPCommand {
        RESPCommand("ZLEXCOUNT", key, min, max)
    }

    public enum ZMPOPWhere: RESPRenderable {
        case min
        case max

        @inlinable
        public func writeToRESPBuffer(_ buffer: inout ByteBuffer) -> Int {
            switch self {
            case .min: "MIN".writeToRESPBuffer(&buffer)
            case .max: "MAX".writeToRESPBuffer(&buffer)
            }
        }
    }
    /// Returns the highest- or lowest-scoring members from one or more sorted sets after removing them. Deletes the sorted set if the last member was popped.
    ///
    /// - Documentation: [ZMPOP](https:/redis.io/docs/latest/commands/zmpop)
    /// - Version: 7.0.0
    /// - Complexity: O(K) + O(M*log(N)) where K is the number of provided keys, N being the number of elements in the sorted set, and M being the number of elements popped.
    /// - Categories: @write, @sortedset, @slow
    /// - Response: One of the following:
    ///     * [Null](https:/redis.io/docs/reference/protocol-spec#nulls): when no element could be popped.
    ///     * [Array](https:/redis.io/docs/reference/protocol-spec#arrays): A two-element array with the first element being the name of the key from which elements were popped, and the second element is an array of the popped elements. Every entry in the elements array is also an array that contains the member and its score.
    @inlinable
    public static func zmpop(key: RedisKey, `where`: ZMPOPWhere, count: Int? = nil) -> RESPCommand {
        RESPCommand("ZMPOP", 1, key, `where`, RESPWithToken("COUNT", count))
    }

    /// Returns the highest- or lowest-scoring members from one or more sorted sets after removing them. Deletes the sorted set if the last member was popped.
    ///
    /// - Documentation: [ZMPOP](https:/redis.io/docs/latest/commands/zmpop)
    /// - Version: 7.0.0
    /// - Complexity: O(K) + O(M*log(N)) where K is the number of provided keys, N being the number of elements in the sorted set, and M being the number of elements popped.
    /// - Categories: @write, @sortedset, @slow
    /// - Response: One of the following:
    ///     * [Null](https:/redis.io/docs/reference/protocol-spec#nulls): when no element could be popped.
    ///     * [Array](https:/redis.io/docs/reference/protocol-spec#arrays): A two-element array with the first element being the name of the key from which elements were popped, and the second element is an array of the popped elements. Every entry in the elements array is also an array that contains the member and its score.
    @inlinable
    public static func zmpop(keys: [RedisKey], `where`: ZMPOPWhere, count: Int? = nil) -> RESPCommand {
        RESPCommand("ZMPOP", RESPArrayWithCount(keys), `where`, RESPWithToken("COUNT", count))
    }

    /// Returns the score of one or more members in a sorted set.
    ///
    /// - Documentation: [ZMSCORE](https:/redis.io/docs/latest/commands/zmscore)
    /// - Version: 6.2.0
    /// - Complexity: O(N) where N is the number of members being requested.
    /// - Categories: @read, @sortedset, @fast
    /// - Response: One of the following:
    ///     * [Null](https:/redis.io/docs/reference/protocol-spec#nulls): if the member does not exist in the sorted set.
    ///     * [Array](https:/redis.io/docs/reference/protocol-spec#arrays): a list of [Double](https:/redis.io/docs/reference/protocol-spec#doubles) _member_ scores as double-precision floating point numbers.
    @inlinable
    public static func zmscore(key: RedisKey, member: String) -> RESPCommand {
        RESPCommand("ZMSCORE", key, member)
    }

    /// Returns the score of one or more members in a sorted set.
    ///
    /// - Documentation: [ZMSCORE](https:/redis.io/docs/latest/commands/zmscore)
    /// - Version: 6.2.0
    /// - Complexity: O(N) where N is the number of members being requested.
    /// - Categories: @read, @sortedset, @fast
    /// - Response: One of the following:
    ///     * [Null](https:/redis.io/docs/reference/protocol-spec#nulls): if the member does not exist in the sorted set.
    ///     * [Array](https:/redis.io/docs/reference/protocol-spec#arrays): a list of [Double](https:/redis.io/docs/reference/protocol-spec#doubles) _member_ scores as double-precision floating point numbers.
    @inlinable
    public static func zmscore(key: RedisKey, members: [String]) -> RESPCommand {
        RESPCommand("ZMSCORE", key, members)
    }

    /// Returns the highest-scoring members from a sorted set after removing them. Deletes the sorted set if the last member was popped.
    ///
    /// - Documentation: [ZPOPMAX](https:/redis.io/docs/latest/commands/zpopmax)
    /// - Version: 5.0.0
    /// - Complexity: O(log(N)*M) with N being the number of elements in the sorted set, and M being the number of elements popped.
    /// - Categories: @write, @sortedset, @fast
    /// - Response: * [Array](https:/redis.io/docs/reference/protocol-spec#arrays): a list of popped elements and scores.
    @inlinable
    public static func zpopmax(key: RedisKey, count: Int? = nil) -> RESPCommand {
        RESPCommand("ZPOPMAX", key, count)
    }

    /// Returns the lowest-scoring members from a sorted set after removing them. Deletes the sorted set if the last member was popped.
    ///
    /// - Documentation: [ZPOPMIN](https:/redis.io/docs/latest/commands/zpopmin)
    /// - Version: 5.0.0
    /// - Complexity: O(log(N)*M) with N being the number of elements in the sorted set, and M being the number of elements popped.
    /// - Categories: @write, @sortedset, @fast
    /// - Response: * [Array](https:/redis.io/docs/reference/protocol-spec#arrays): a list of popped elements and scores.
    @inlinable
    public static func zpopmin(key: RedisKey, count: Int? = nil) -> RESPCommand {
        RESPCommand("ZPOPMIN", key, count)
    }

    public struct ZRANDMEMBEROptions: RESPRenderable {
        @usableFromInline let count: Int
        @usableFromInline let withscores: Bool

        @inlinable
        public func writeToRESPBuffer(_ buffer: inout ByteBuffer) -> Int {
            var count = 0
            count += self.count.writeToRESPBuffer(&buffer)
            if self.withscores { count += "WITHSCORES".writeToRESPBuffer(&buffer) }
            return count
        }
    }
    /// Returns one or more random members from a sorted set.
    ///
    /// - Documentation: [ZRANDMEMBER](https:/redis.io/docs/latest/commands/zrandmember)
    /// - Version: 6.2.0
    /// - Complexity: O(N) where N is the number of members returned
    /// - Categories: @read, @sortedset, @slow
    /// - Response: [Bulk string](https:/redis.io/docs/reference/protocol-spec#bulk-strings): without the additional _count_ argument, the command returns a randomly selected member, or [Null](https:/redis.io/docs/reference/protocol-spec#nulls) when _key_ doesn't exist.
    ///     [Array](https:/redis.io/docs/reference/protocol-spec#arrays): when the additional _count_ argument is passed, the command returns an array of members, or an empty array when _key_ doesn't exist. If the _WITHSCORES_ modifier is used, the reply is a list of members and their scores from the sorted set.
    @inlinable
    public static func zrandmember(key: RedisKey, options: ZRANDMEMBEROptions? = nil) -> RESPCommand {
        RESPCommand("ZRANDMEMBER", key, options)
    }

    public enum ZRANGESortby: RESPRenderable {
        case byscore
        case bylex

        @inlinable
        public func writeToRESPBuffer(_ buffer: inout ByteBuffer) -> Int {
            switch self {
            case .byscore: "BYSCORE".writeToRESPBuffer(&buffer)
            case .bylex: "BYLEX".writeToRESPBuffer(&buffer)
            }
        }
    }
    public struct ZRANGELimit: RESPRenderable {
        @usableFromInline let offset: Int
        @usableFromInline let count: Int

        @inlinable
        public func writeToRESPBuffer(_ buffer: inout ByteBuffer) -> Int {
            var count = 0
            count += self.offset.writeToRESPBuffer(&buffer)
            count += self.count.writeToRESPBuffer(&buffer)
            return count
        }
    }
    /// Returns members in a sorted set within a range of indexes.
    ///
    /// - Documentation: [ZRANGE](https:/redis.io/docs/latest/commands/zrange)
    /// - Version: 1.2.0
    /// - Complexity: O(log(N)+M) with N being the number of elements in the sorted set and M the number of elements returned.
    /// - Categories: @read, @sortedset, @slow
    /// - Response: [Array](https:/redis.io/docs/reference/protocol-spec#arrays): a list of members in the specified range with, optionally, their scores when the _WITHSCORES_ option is given.
    @inlinable
    public static func zrange(key: RedisKey, start: String, stop: String, sortby: ZRANGESortby? = nil, rev: Bool = false, limit: ZRANGELimit? = nil, withscores: Bool = false) -> RESPCommand {
        RESPCommand("ZRANGE", key, start, stop, sortby, RedisPureToken("REV", rev), RESPWithToken("LIMIT", limit), RedisPureToken("WITHSCORES", withscores))
    }

    public struct ZRANGEBYLEXLimit: RESPRenderable {
        @usableFromInline let offset: Int
        @usableFromInline let count: Int

        @inlinable
        public func writeToRESPBuffer(_ buffer: inout ByteBuffer) -> Int {
            var count = 0
            count += self.offset.writeToRESPBuffer(&buffer)
            count += self.count.writeToRESPBuffer(&buffer)
            return count
        }
    }
    /// Returns members in a sorted set within a lexicographical range.
    ///
    /// - Documentation: [ZRANGEBYLEX](https:/redis.io/docs/latest/commands/zrangebylex)
    /// - Version: 2.8.9
    /// - Complexity: O(log(N)+M) with N being the number of elements in the sorted set and M the number of elements being returned. If M is constant (e.g. always asking for the first 10 elements with LIMIT), you can consider it O(log(N)).
    /// - Categories: @read, @sortedset, @slow
    /// - Response: [Array](https:/redis.io/docs/reference/protocol-spec#arrays): a list of elements in the specified score range.
    @inlinable
    public static func zrangebylex(key: RedisKey, min: String, max: String, limit: ZRANGEBYLEXLimit? = nil) -> RESPCommand {
        RESPCommand("ZRANGEBYLEX", key, min, max, RESPWithToken("LIMIT", limit))
    }

    public struct ZRANGEBYSCORELimit: RESPRenderable {
        @usableFromInline let offset: Int
        @usableFromInline let count: Int

        @inlinable
        public func writeToRESPBuffer(_ buffer: inout ByteBuffer) -> Int {
            var count = 0
            count += self.offset.writeToRESPBuffer(&buffer)
            count += self.count.writeToRESPBuffer(&buffer)
            return count
        }
    }
    /// Returns members in a sorted set within a range of scores.
    ///
    /// - Documentation: [ZRANGEBYSCORE](https:/redis.io/docs/latest/commands/zrangebyscore)
    /// - Version: 1.0.5
    /// - Complexity: O(log(N)+M) with N being the number of elements in the sorted set and M the number of elements being returned. If M is constant (e.g. always asking for the first 10 elements with LIMIT), you can consider it O(log(N)).
    /// - Categories: @read, @sortedset, @slow
    /// - Response: * [Array](https:/redis.io/docs/reference/protocol-spec#arrays): a list of the members with, optionally, their scores in the specified score range.
    @inlinable
    public static func zrangebyscore(key: RedisKey, min: Double, max: Double, withscores: Bool = false, limit: ZRANGEBYSCORELimit? = nil) -> RESPCommand {
        RESPCommand("ZRANGEBYSCORE", key, min, max, RedisPureToken("WITHSCORES", withscores), RESPWithToken("LIMIT", limit))
    }

    public enum ZRANGESTORESortby: RESPRenderable {
        case byscore
        case bylex

        @inlinable
        public func writeToRESPBuffer(_ buffer: inout ByteBuffer) -> Int {
            switch self {
            case .byscore: "BYSCORE".writeToRESPBuffer(&buffer)
            case .bylex: "BYLEX".writeToRESPBuffer(&buffer)
            }
        }
    }
    public struct ZRANGESTORELimit: RESPRenderable {
        @usableFromInline let offset: Int
        @usableFromInline let count: Int

        @inlinable
        public func writeToRESPBuffer(_ buffer: inout ByteBuffer) -> Int {
            var count = 0
            count += self.offset.writeToRESPBuffer(&buffer)
            count += self.count.writeToRESPBuffer(&buffer)
            return count
        }
    }
    /// Stores a range of members from sorted set in a key.
    ///
    /// - Documentation: [ZRANGESTORE](https:/redis.io/docs/latest/commands/zrangestore)
    /// - Version: 6.2.0
    /// - Complexity: O(log(N)+M) with N being the number of elements in the sorted set and M the number of elements stored into the destination key.
    /// - Categories: @write, @sortedset, @slow
    /// - Response: [Integer](https:/redis.io/docs/reference/protocol-spec#integers): the number of elements in the resulting sorted set.
    @inlinable
    public static func zrangestore(dst: RedisKey, src: RedisKey, min: String, max: String, sortby: ZRANGESTORESortby? = nil, rev: Bool = false, limit: ZRANGESTORELimit? = nil) -> RESPCommand {
        RESPCommand("ZRANGESTORE", dst, src, min, max, sortby, RedisPureToken("REV", rev), RESPWithToken("LIMIT", limit))
    }

    /// Returns the index of a member in a sorted set ordered by ascending scores.
    ///
    /// - Documentation: [ZRANK](https:/redis.io/docs/latest/commands/zrank)
    /// - Version: 2.0.0
    /// - Complexity: O(log(N))
    /// - Categories: @read, @sortedset, @fast
    /// - Response: One of the following:
    ///     * [Null](https:/redis.io/docs/reference/protocol-spec#nulls): if the key does not exist or the member does not exist in the sorted set.
    ///     * [Integer](https:/redis.io/docs/reference/protocol-spec#integers): the rank of the member when _WITHSCORE_ is not used.
    ///     * [Array](https:/redis.io/docs/reference/protocol-spec#arrays): the rank and score of the member when _WITHSCORE_ is used.
    @inlinable
    public static func zrank(key: RedisKey, member: String, withscore: Bool = false) -> RESPCommand {
        RESPCommand("ZRANK", key, member, RedisPureToken("WITHSCORE", withscore))
    }

    /// Removes one or more members from a sorted set. Deletes the sorted set if all members were removed.
    ///
    /// - Documentation: [ZREM](https:/redis.io/docs/latest/commands/zrem)
    /// - Version: 1.2.0
    /// - Complexity: O(M*log(N)) with N being the number of elements in the sorted set and M the number of elements to be removed.
    /// - Categories: @write, @sortedset, @fast
    /// - Response: [Integer](https:/redis.io/docs/reference/protocol-spec#integers): the number of members removed from the sorted set, not including non-existing members.
    @inlinable
    public static func zrem(key: RedisKey, member: String) -> RESPCommand {
        RESPCommand("ZREM", key, member)
    }

    /// Removes one or more members from a sorted set. Deletes the sorted set if all members were removed.
    ///
    /// - Documentation: [ZREM](https:/redis.io/docs/latest/commands/zrem)
    /// - Version: 1.2.0
    /// - Complexity: O(M*log(N)) with N being the number of elements in the sorted set and M the number of elements to be removed.
    /// - Categories: @write, @sortedset, @fast
    /// - Response: [Integer](https:/redis.io/docs/reference/protocol-spec#integers): the number of members removed from the sorted set, not including non-existing members.
    @inlinable
    public static func zrem(key: RedisKey, members: [String]) -> RESPCommand {
        RESPCommand("ZREM", key, members)
    }

    /// Removes members in a sorted set within a lexicographical range. Deletes the sorted set if all members were removed.
    ///
    /// - Documentation: [ZREMRANGEBYLEX](https:/redis.io/docs/latest/commands/zremrangebylex)
    /// - Version: 2.8.9
    /// - Complexity: O(log(N)+M) with N being the number of elements in the sorted set and M the number of elements removed by the operation.
    /// - Categories: @write, @sortedset, @slow
    /// - Response: [Integer](https:/redis.io/docs/reference/protocol-spec#integers): Number of members removed.
    @inlinable
    public static func zremrangebylex(key: RedisKey, min: String, max: String) -> RESPCommand {
        RESPCommand("ZREMRANGEBYLEX", key, min, max)
    }

    /// Removes members in a sorted set within a range of indexes. Deletes the sorted set if all members were removed.
    ///
    /// - Documentation: [ZREMRANGEBYRANK](https:/redis.io/docs/latest/commands/zremrangebyrank)
    /// - Version: 2.0.0
    /// - Complexity: O(log(N)+M) with N being the number of elements in the sorted set and M the number of elements removed by the operation.
    /// - Categories: @write, @sortedset, @slow
    /// - Response: [Integer](https:/redis.io/docs/reference/protocol-spec#integers): Number of members removed.
    @inlinable
    public static func zremrangebyrank(key: RedisKey, start: Int, stop: Int) -> RESPCommand {
        RESPCommand("ZREMRANGEBYRANK", key, start, stop)
    }

    /// Removes members in a sorted set within a range of scores. Deletes the sorted set if all members were removed.
    ///
    /// - Documentation: [ZREMRANGEBYSCORE](https:/redis.io/docs/latest/commands/zremrangebyscore)
    /// - Version: 1.2.0
    /// - Complexity: O(log(N)+M) with N being the number of elements in the sorted set and M the number of elements removed by the operation.
    /// - Categories: @write, @sortedset, @slow
    /// - Response: [Integer](https:/redis.io/docs/reference/protocol-spec#integers): Number of members removed.
    @inlinable
    public static func zremrangebyscore(key: RedisKey, min: Double, max: Double) -> RESPCommand {
        RESPCommand("ZREMRANGEBYSCORE", key, min, max)
    }

    /// Returns members in a sorted set within a range of indexes in reverse order.
    ///
    /// - Documentation: [ZREVRANGE](https:/redis.io/docs/latest/commands/zrevrange)
    /// - Version: 1.2.0
    /// - Complexity: O(log(N)+M) with N being the number of elements in the sorted set and M the number of elements returned.
    /// - Categories: @read, @sortedset, @slow
    /// - Response: * [Array](https:/redis.io/docs/reference/protocol-spec#arrays): a list of members in the specified range, optionally with their scores if _WITHSCORE_ was used.
    @inlinable
    public static func zrevrange(key: RedisKey, start: Int, stop: Int, withscores: Bool = false) -> RESPCommand {
        RESPCommand("ZREVRANGE", key, start, stop, RedisPureToken("WITHSCORES", withscores))
    }

    public struct ZREVRANGEBYLEXLimit: RESPRenderable {
        @usableFromInline let offset: Int
        @usableFromInline let count: Int

        @inlinable
        public func writeToRESPBuffer(_ buffer: inout ByteBuffer) -> Int {
            var count = 0
            count += self.offset.writeToRESPBuffer(&buffer)
            count += self.count.writeToRESPBuffer(&buffer)
            return count
        }
    }
    /// Returns members in a sorted set within a lexicographical range in reverse order.
    ///
    /// - Documentation: [ZREVRANGEBYLEX](https:/redis.io/docs/latest/commands/zrevrangebylex)
    /// - Version: 2.8.9
    /// - Complexity: O(log(N)+M) with N being the number of elements in the sorted set and M the number of elements being returned. If M is constant (e.g. always asking for the first 10 elements with LIMIT), you can consider it O(log(N)).
    /// - Categories: @read, @sortedset, @slow
    /// - Response: [Array](https:/redis.io/docs/reference/protocol-spec#arrays): List of the elements in the specified score range.
    @inlinable
    public static func zrevrangebylex(key: RedisKey, max: String, min: String, limit: ZREVRANGEBYLEXLimit? = nil) -> RESPCommand {
        RESPCommand("ZREVRANGEBYLEX", key, max, min, RESPWithToken("LIMIT", limit))
    }

    public struct ZREVRANGEBYSCORELimit: RESPRenderable {
        @usableFromInline let offset: Int
        @usableFromInline let count: Int

        @inlinable
        public func writeToRESPBuffer(_ buffer: inout ByteBuffer) -> Int {
            var count = 0
            count += self.offset.writeToRESPBuffer(&buffer)
            count += self.count.writeToRESPBuffer(&buffer)
            return count
        }
    }
    /// Returns members in a sorted set within a range of scores in reverse order.
    ///
    /// - Documentation: [ZREVRANGEBYSCORE](https:/redis.io/docs/latest/commands/zrevrangebyscore)
    /// - Version: 2.2.0
    /// - Complexity: O(log(N)+M) with N being the number of elements in the sorted set and M the number of elements being returned. If M is constant (e.g. always asking for the first 10 elements with LIMIT), you can consider it O(log(N)).
    /// - Categories: @read, @sortedset, @slow
    /// - Response: * [Array](https:/redis.io/docs/reference/protocol-spec#arrays): a list of the members and, optionally, their scores in the specified score range.
    @inlinable
    public static func zrevrangebyscore(key: RedisKey, max: Double, min: Double, withscores: Bool = false, limit: ZREVRANGEBYSCORELimit? = nil) -> RESPCommand {
        RESPCommand("ZREVRANGEBYSCORE", key, max, min, RedisPureToken("WITHSCORES", withscores), RESPWithToken("LIMIT", limit))
    }

    /// Returns the index of a member in a sorted set ordered by descending scores.
    ///
    /// - Documentation: [ZREVRANK](https:/redis.io/docs/latest/commands/zrevrank)
    /// - Version: 2.0.0
    /// - Complexity: O(log(N))
    /// - Categories: @read, @sortedset, @fast
    /// - Response: One of the following:
    ///     * [Null](https:/redis.io/docs/reference/protocol-spec#nulls): if the key does not exist or the member does not exist in the sorted set.
    ///     * [Integer](https:/redis.io/docs/reference/protocol-spec#integers): The rank of the member when _WITHSCORE_ is not used.
    ///     * [Array](https:/redis.io/docs/reference/protocol-spec#arrays): The rank and score of the member when _WITHSCORE_ is used.
    @inlinable
    public static func zrevrank(key: RedisKey, member: String, withscore: Bool = false) -> RESPCommand {
        RESPCommand("ZREVRANK", key, member, RedisPureToken("WITHSCORE", withscore))
    }

    /// Iterates over members and scores of a sorted set.
    ///
    /// - Documentation: [ZSCAN](https:/redis.io/docs/latest/commands/zscan)
    /// - Version: 2.8.0
    /// - Complexity: O(1) for every call. O(N) for a complete iteration, including enough command calls for the cursor to return back to 0. N is the number of elements inside the collection.
    /// - Categories: @read, @sortedset, @slow
    /// - Response: [Array](https:/redis.io/docs/reference/protocol-spec#arrays): cursor and scan response in array form.
    @inlinable
    public static func zscan(key: RedisKey, cursor: Int, pattern: String? = nil, count: Int? = nil) -> RESPCommand {
        RESPCommand("ZSCAN", key, cursor, RESPWithToken("MATCH", pattern), RESPWithToken("COUNT", count))
    }

    /// Returns the score of a member in a sorted set.
    ///
    /// - Documentation: [ZSCORE](https:/redis.io/docs/latest/commands/zscore)
    /// - Version: 1.2.0
    /// - Complexity: O(1)
    /// - Categories: @read, @sortedset, @fast
    /// - Response: One of the following:
    ///     * [Double](https:/redis.io/docs/reference/protocol-spec#doubles): the score of the member (a double-precision floating point number).
    ///     * [Nil](https:/redis.io/docs/reference/protocol-spec#bulk-strings): if _member_ does not exist in the sorted set, or the key does not exist.
    @inlinable
    public static func zscore(key: RedisKey, member: String) -> RESPCommand {
        RESPCommand("ZSCORE", key, member)
    }

    public enum ZUNIONAggregate: RESPRenderable {
        case sum
        case min
        case max

        @inlinable
        public func writeToRESPBuffer(_ buffer: inout ByteBuffer) -> Int {
            switch self {
            case .sum: "SUM".writeToRESPBuffer(&buffer)
            case .min: "MIN".writeToRESPBuffer(&buffer)
            case .max: "MAX".writeToRESPBuffer(&buffer)
            }
        }
    }
    /// Returns the union of multiple sorted sets.
    ///
    /// - Documentation: [ZUNION](https:/redis.io/docs/latest/commands/zunion)
    /// - Version: 6.2.0
    /// - Complexity: O(N)+O(M*log(M)) with N being the sum of the sizes of the input sorted sets, and M being the number of elements in the resulting sorted set.
    /// - Categories: @read, @sortedset, @slow
    /// - Response: [Array](https:/redis.io/docs/reference/protocol-spec#arrays): the result of the union with, optionally, their scores when _WITHSCORES_ is used.
    @inlinable
    public static func zunion(key: RedisKey, weight: Int? = nil, aggregate: ZUNIONAggregate? = nil, withscores: Bool = false) -> RESPCommand {
        RESPCommand("ZUNION", 1, key, RESPWithToken("WEIGHTS", weight), RESPWithToken("AGGREGATE", aggregate), RedisPureToken("WITHSCORES", withscores))
    }

    /// Returns the union of multiple sorted sets.
    ///
    /// - Documentation: [ZUNION](https:/redis.io/docs/latest/commands/zunion)
    /// - Version: 6.2.0
    /// - Complexity: O(N)+O(M*log(M)) with N being the sum of the sizes of the input sorted sets, and M being the number of elements in the resulting sorted set.
    /// - Categories: @read, @sortedset, @slow
    /// - Response: [Array](https:/redis.io/docs/reference/protocol-spec#arrays): the result of the union with, optionally, their scores when _WITHSCORES_ is used.
    @inlinable
    public static func zunion(keys: [RedisKey], weights: [Int], aggregate: ZUNIONAggregate? = nil, withscores: Bool = false) -> RESPCommand {
        RESPCommand("ZUNION", RESPArrayWithCount(keys), RESPWithToken("WEIGHTS", weights), RESPWithToken("AGGREGATE", aggregate), RedisPureToken("WITHSCORES", withscores))
    }

    public enum ZUNIONSTOREAggregate: RESPRenderable {
        case sum
        case min
        case max

        @inlinable
        public func writeToRESPBuffer(_ buffer: inout ByteBuffer) -> Int {
            switch self {
            case .sum: "SUM".writeToRESPBuffer(&buffer)
            case .min: "MIN".writeToRESPBuffer(&buffer)
            case .max: "MAX".writeToRESPBuffer(&buffer)
            }
        }
    }
    /// Stores the union of multiple sorted sets in a key.
    ///
    /// - Documentation: [ZUNIONSTORE](https:/redis.io/docs/latest/commands/zunionstore)
    /// - Version: 2.0.0
    /// - Complexity: O(N)+O(M log(M)) with N being the sum of the sizes of the input sorted sets, and M being the number of elements in the resulting sorted set.
    /// - Categories: @write, @sortedset, @slow
    /// - Response: [Integer](https:/redis.io/docs/reference/protocol-spec#integers): the number of elements in the resulting sorted set.
    @inlinable
    public static func zunionstore(destination: RedisKey, key: RedisKey, weight: Int? = nil, aggregate: ZUNIONSTOREAggregate? = nil) -> RESPCommand {
        RESPCommand("ZUNIONSTORE", destination, 1, key, RESPWithToken("WEIGHTS", weight), RESPWithToken("AGGREGATE", aggregate))
    }

    /// Stores the union of multiple sorted sets in a key.
    ///
    /// - Documentation: [ZUNIONSTORE](https:/redis.io/docs/latest/commands/zunionstore)
    /// - Version: 2.0.0
    /// - Complexity: O(N)+O(M log(M)) with N being the sum of the sizes of the input sorted sets, and M being the number of elements in the resulting sorted set.
    /// - Categories: @write, @sortedset, @slow
    /// - Response: [Integer](https:/redis.io/docs/reference/protocol-spec#integers): the number of elements in the resulting sorted set.
    @inlinable
    public static func zunionstore(destination: RedisKey, keys: [RedisKey], weights: [Int], aggregate: ZUNIONSTOREAggregate? = nil) -> RESPCommand {
        RESPCommand("ZUNIONSTORE", destination, RESPArrayWithCount(keys), RESPWithToken("WEIGHTS", weights), RESPWithToken("AGGREGATE", aggregate))
    }

}

extension RedisConnection {
    /// Lists the ACL categories, or the commands inside a category.
    ///
    /// - Documentation: [ACL CAT](https:/redis.io/docs/latest/commands/acl-cat)
    /// - Version: 6.0.0
    /// - Complexity: O(1) since the categories and commands are a fixed set.
    /// - Categories: @slow
    /// - Returns: One of the following:
    ///     * [Array](https:/redis.io/docs/reference/protocol-spec#arrays): an array of [Bulk string](https:/redis.io/docs/reference/protocol-spec#bulk-strings) elements representing ACL categories or commands in a given category.
    ///     * [Simple error](https:/redis.io/docs/reference/protocol-spec#simple-errors): the command returns an error if an invalid category name is given.
    @inlinable
    public func aclCat(category: String? = nil) async throws -> [String] {
        try await send("ACL", "CAT", category).converting()
    }

    /// Deletes ACL users, and terminates their connections.
    ///
    /// - Documentation: [ACL DELUSER](https:/redis.io/docs/latest/commands/acl-deluser)
    /// - Version: 6.0.0
    /// - Complexity: O(1) amortized time considering the typical user.
    /// - Categories: @admin, @slow, @dangerous
    /// - Returns: [Integer](https:/redis.io/docs/reference/protocol-spec#integers): the number of users that were deleted. This number will not always match the number of arguments since certain users may not exist.
    @inlinable
    public func aclDeluser(username: String) async throws -> Int {
        try await send("ACL", "DELUSER", username).converting()
    }

    /// Deletes ACL users, and terminates their connections.
    ///
    /// - Documentation: [ACL DELUSER](https:/redis.io/docs/latest/commands/acl-deluser)
    /// - Version: 6.0.0
    /// - Complexity: O(1) amortized time considering the typical user.
    /// - Categories: @admin, @slow, @dangerous
    /// - Returns: [Integer](https:/redis.io/docs/reference/protocol-spec#integers): the number of users that were deleted. This number will not always match the number of arguments since certain users may not exist.
    @inlinable
    public func aclDeluser(usernames: [String]) async throws -> Int {
        try await send("ACL", "DELUSER", usernames).converting()
    }

    /// Simulates the execution of a command by a user, without executing the command.
    ///
    /// - Documentation: [ACL DRYRUN](https:/redis.io/docs/latest/commands/acl-dryrun)
    /// - Version: 7.0.0
    /// - Complexity: O(1).
    /// - Categories: @admin, @slow, @dangerous
    /// - Returns: Any of the following:
    ///     * [Simple string](https:/redis.io/docs/reference/protocol-spec#simple-strings): `OK` on success.
    ///     * [Bulk string](https:/redis.io/docs/reference/protocol-spec#bulk-strings): an error describing why the user can't execute the command.
    @inlinable
    public func aclDryrun(username: String, command: String, arg: String? = nil) async throws -> String? {
        try await send("ACL", "DRYRUN", username, command, arg).converting()
    }

    /// Simulates the execution of a command by a user, without executing the command.
    ///
    /// - Documentation: [ACL DRYRUN](https:/redis.io/docs/latest/commands/acl-dryrun)
    /// - Version: 7.0.0
    /// - Complexity: O(1).
    /// - Categories: @admin, @slow, @dangerous
    /// - Returns: Any of the following:
    ///     * [Simple string](https:/redis.io/docs/reference/protocol-spec#simple-strings): `OK` on success.
    ///     * [Bulk string](https:/redis.io/docs/reference/protocol-spec#bulk-strings): an error describing why the user can't execute the command.
    @inlinable
    public func aclDryrun(username: String, command: String, args: [String]) async throws -> String? {
        try await send("ACL", "DRYRUN", username, command, args).converting()
    }

    /// Generates a pseudorandom, secure password that can be used to identify ACL users.
    ///
    /// - Documentation: [ACL GENPASS](https:/redis.io/docs/latest/commands/acl-genpass)
    /// - Version: 6.0.0
    /// - Complexity: O(1)
    /// - Categories: @slow
    /// - Returns: [Bulk string](https:/redis.io/docs/reference/protocol-spec#bulk-strings): pseudorandom data. By default it contains 64 bytes, representing 256 bits of data. If `bits` was given, the output string length is the number of specified bits (rounded to the next multiple of 4) divided by 4.
    @inlinable
    public func aclGenpass(bits: Int? = nil) async throws -> String {
        try await send("ACL", "GENPASS", bits).converting()
    }

    /// Lists the ACL rules of a user.
    ///
    /// - Documentation: [ACL GETUSER](https:/redis.io/docs/latest/commands/acl-getuser)
    /// - Version: 6.0.0
    /// - Complexity: O(N). Where N is the number of password, command and pattern rules that the user has.
    /// - Categories: @admin, @slow, @dangerous
    /// - Returns: One of the following:
    ///     * [Map](https:/redis.io/docs/reference/protocol-spec#maps): a set of ACL rule definitions for the user
    ///     * [Null](https:/redis.io/docs/reference/protocol-spec#nulls): if user does not exist.
    @inlinable
    public func aclGetuser(username: String) async throws -> RESPToken? {
        try await send("ACL", "GETUSER", username).converting()
    }

    /// Returns helpful text about the different subcommands.
    ///
    /// - Documentation: [ACL HELP](https:/redis.io/docs/latest/commands/acl-help)
    /// - Version: 6.0.0
    /// - Complexity: O(1)
    /// - Categories: @slow
    /// - Returns: [Array](https:/redis.io/docs/reference/protocol-spec#arrays): a list of subcommands and their descriptions.
    @inlinable
    public func aclHelp() async throws -> [RESPToken] {
        try await send("ACL", "HELP").converting()
    }

    /// Dumps the effective rules in ACL file format.
    ///
    /// - Documentation: [ACL LIST](https:/redis.io/docs/latest/commands/acl-list)
    /// - Version: 6.0.0
    /// - Complexity: O(N). Where N is the number of configured users.
    /// - Categories: @admin, @slow, @dangerous
    /// - Returns: [Array](https:/redis.io/docs/reference/protocol-spec#arrays): an array of [Bulk string](https:/redis.io/docs/reference/protocol-spec#bulk-strings) elements.
    @inlinable
    public func aclList() async throws -> [String] {
        try await send("ACL", "LIST").converting()
    }

    /// Reloads the rules from the configured ACL file.
    ///
    /// - Documentation: [ACL LOAD](https:/redis.io/docs/latest/commands/acl-load)
    /// - Version: 6.0.0
    /// - Complexity: O(N). Where N is the number of configured users.
    /// - Categories: @admin, @slow, @dangerous
    /// - Returns: [Simple string](https:/redis.io/docs/reference/protocol-spec#simple-strings): `OK` on success.
    ///     
    ///     The command may fail with an error for several reasons: if the file is not readable, if there is an error inside the file, and in such cases, the error will be reported to the user in the error.
    ///     Finally, the command will fail if the server is not configured to use an external ACL file.
    @inlinable
    public func aclLoad() async throws {
        try await send("ACL", "LOAD")
    }

    /// Lists recent security events generated due to ACL rules.
    ///
    /// - Documentation: [ACL LOG](https:/redis.io/docs/latest/commands/acl-log)
    /// - Version: 6.0.0
    /// - Complexity: O(N) with N being the number of entries shown.
    /// - Categories: @admin, @slow, @dangerous
    /// - Returns: When called to show security events:
    ///     * [Array](https:/redis.io/docs/reference/protocol-spec#arrays): an array of [Bulk string](https:/redis.io/docs/reference/protocol-spec#bulk-strings) elements representing ACL security events.
    ///     When called with `RESET`:
    ///     * [Simple string](https:/redis.io/docs/reference/protocol-spec#simple-strings): `OK` if the security log was cleared.
    @inlinable
    public func aclLog(operation: RESPCommand.ACLLOGOperation? = nil) async throws -> [String]? {
        try await send("ACL", "LOG", operation).converting()
    }

    /// Saves the effective ACL rules in the configured ACL file.
    ///
    /// - Documentation: [ACL SAVE](https:/redis.io/docs/latest/commands/acl-save)
    /// - Version: 6.0.0
    /// - Complexity: O(N). Where N is the number of configured users.
    /// - Categories: @admin, @slow, @dangerous
    /// - Returns: [Simple string](https:/redis.io/docs/reference/protocol-spec#simple-strings): `OK`.
    ///     The command may fail with an error for several reasons: if the file cannot be written or if the server is not configured to use an external ACL file.
    @inlinable
    public func aclSave() async throws {
        try await send("ACL", "SAVE")
    }

    /// Creates and modifies an ACL user and its rules.
    ///
    /// - Documentation: [ACL SETUSER](https:/redis.io/docs/latest/commands/acl-setuser)
    /// - Version: 6.0.0
    /// - Complexity: O(N). Where N is the number of rules provided.
    /// - Categories: @admin, @slow, @dangerous
    /// - Returns: [Simple string](https:/redis.io/docs/reference/protocol-spec#simple-strings): `OK`.
    ///     If the rules contain errors, the error is returned.
    @inlinable
    public func aclSetuser(username: String, rule: String? = nil) async throws {
        try await send("ACL", "SETUSER", username, rule)
    }

    /// Creates and modifies an ACL user and its rules.
    ///
    /// - Documentation: [ACL SETUSER](https:/redis.io/docs/latest/commands/acl-setuser)
    /// - Version: 6.0.0
    /// - Complexity: O(N). Where N is the number of rules provided.
    /// - Categories: @admin, @slow, @dangerous
    /// - Returns: [Simple string](https:/redis.io/docs/reference/protocol-spec#simple-strings): `OK`.
    ///     If the rules contain errors, the error is returned.
    @inlinable
    public func aclSetuser(username: String, rules: [String]) async throws {
        try await send("ACL", "SETUSER", username, rules)
    }

    /// Lists all ACL users.
    ///
    /// - Documentation: [ACL USERS](https:/redis.io/docs/latest/commands/acl-users)
    /// - Version: 6.0.0
    /// - Complexity: O(N). Where N is the number of configured users.
    /// - Categories: @admin, @slow, @dangerous
    /// - Returns: [Array](https:/redis.io/docs/reference/protocol-spec#arrays): list of existing ACL users.
    @inlinable
    public func aclUsers() async throws -> [RESPToken] {
        try await send("ACL", "USERS").converting()
    }

    /// Returns the authenticated username of the current connection.
    ///
    /// - Documentation: [ACL WHOAMI](https:/redis.io/docs/latest/commands/acl-whoami)
    /// - Version: 6.0.0
    /// - Complexity: O(1)
    /// - Categories: @slow
    /// - Returns: [Bulk string](https:/redis.io/docs/reference/protocol-spec#bulk-strings): the username of the current connection.
    @inlinable
    public func aclWhoami() async throws -> String {
        try await send("ACL", "WHOAMI").converting()
    }

    /// Appends a string to the value of a key. Creates the key if it doesn't exist.
    ///
    /// - Documentation: [APPEND](https:/redis.io/docs/latest/commands/append)
    /// - Version: 2.0.0
    /// - Complexity: O(1). The amortized time complexity is O(1) assuming the appended value is small and the already present value is of any size, since the dynamic string library used by Redis will double the free space available on every reallocation.
    /// - Categories: @write, @string, @fast
    /// - Returns: [Integer](https:/redis.io/docs/reference/protocol-spec#integers): the length of the string after the append operation.
    @inlinable
    public func append(key: RedisKey, value: String) async throws -> Int {
        try await send("APPEND", key, value).converting()
    }

    /// Signals that a cluster client is following an -ASK redirect.
    ///
    /// - Documentation: [ASKING](https:/redis.io/docs/latest/commands/asking)
    /// - Version: 3.0.0
    /// - Complexity: O(1)
    /// - Categories: @fast, @connection
    /// - Returns: [Simple string](https:/redis.io/docs/reference/protocol-spec#simple-strings): `OK`.
    @inlinable
    public func asking() async throws {
        try await send("ASKING")
    }

    /// Authenticates the connection.
    ///
    /// - Documentation: [AUTH](https:/redis.io/docs/latest/commands/auth)
    /// - Version: 1.0.0
    /// - Complexity: O(N) where N is the number of passwords defined for the user
    /// - Categories: @fast, @connection
    /// - Returns: [Simple string](https:/redis.io/docs/reference/protocol-spec#simple-strings): `OK`, or an error if the password, or username/password pair, is invalid.
    @inlinable
    public func auth(username: String? = nil, password: String) async throws {
        try await send("AUTH", username, password)
    }

    /// Asynchronously rewrites the append-only file to disk.
    ///
    /// - Documentation: [BGREWRITEAOF](https:/redis.io/docs/latest/commands/bgrewriteaof)
    /// - Version: 1.0.0
    /// - Complexity: O(1)
    /// - Categories: @admin, @slow, @dangerous
    /// - Returns: [Bulk string](https:/redis.io/docs/reference/protocol-spec#bulk-strings): a simple string reply indicating that the rewriting started or is about to start ASAP when the call is executed with success.
    ///     
    ///     The command may reply with an error in certain cases, as documented above.
    @inlinable
    public func bgrewriteaof() async throws -> String {
        try await send("BGREWRITEAOF").converting()
    }

    /// Asynchronously saves the database(s) to disk.
    ///
    /// - Documentation: [BGSAVE](https:/redis.io/docs/latest/commands/bgsave)
    /// - Version: 1.0.0
    /// - Complexity: O(1)
    /// - Categories: @admin, @slow, @dangerous
    /// - Returns: One of the following:
    ///     * [Simple string](https:/redis.io/docs/reference/protocol-spec#simple-strings): `Background saving started`.
    ///     * [Simple string](https:/redis.io/docs/reference/protocol-spec#simple-strings): `Background saving scheduled`.
    @inlinable
    public func bgsave(schedule: Bool = false) async throws -> String {
        try await send("BGSAVE", RedisPureToken("SCHEDULE", schedule)).converting()
    }

    /// Counts the number of set bits (population counting) in a string.
    ///
    /// - Documentation: [BITCOUNT](https:/redis.io/docs/latest/commands/bitcount)
    /// - Version: 2.6.0
    /// - Complexity: O(N)
    /// - Categories: @read, @bitmap, @slow
    /// - Returns: [Integer](https:/redis.io/docs/reference/protocol-spec#integers): the number of bits set to 1.
    @inlinable
    public func bitcount(key: RedisKey, range: RESPCommand.BITCOUNTRange? = nil) async throws -> Int {
        try await send("BITCOUNT", key, range).converting()
    }

    /// Performs arbitrary bitfield integer operations on strings.
    ///
    /// - Documentation: [BITFIELD](https:/redis.io/docs/latest/commands/bitfield)
    /// - Version: 3.2.0
    /// - Complexity: O(1) for each subcommand specified
    /// - Categories: @write, @bitmap, @slow
    /// - Returns: One of the following:
    ///     * [Array](https:/redis.io/docs/reference/protocol-spec#arrays): each entry being the corresponding result of the sub-command given at the same position.
    ///     * [Null](https:/redis.io/docs/reference/protocol-spec#nulls): if OVERFLOW FAIL was given and overflows or underflows are detected.
    @inlinable
    public func bitfield(key: RedisKey, operation: RESPCommand.BITFIELDOperation? = nil) async throws -> [RESPToken]? {
        try await send("BITFIELD", key, operation).converting()
    }

    /// Performs arbitrary bitfield integer operations on strings.
    ///
    /// - Documentation: [BITFIELD](https:/redis.io/docs/latest/commands/bitfield)
    /// - Version: 3.2.0
    /// - Complexity: O(1) for each subcommand specified
    /// - Categories: @write, @bitmap, @slow
    /// - Returns: One of the following:
    ///     * [Array](https:/redis.io/docs/reference/protocol-spec#arrays): each entry being the corresponding result of the sub-command given at the same position.
    ///     * [Null](https:/redis.io/docs/reference/protocol-spec#nulls): if OVERFLOW FAIL was given and overflows or underflows are detected.
    @inlinable
    public func bitfield(key: RedisKey, operations: [RESPCommand.BITFIELDOperation]) async throws -> [RESPToken]? {
        try await send("BITFIELD", key, operations).converting()
    }

    /// Performs arbitrary read-only bitfield integer operations on strings.
    ///
    /// - Documentation: [BITFIELD_RO](https:/redis.io/docs/latest/commands/bitfield_ro)
    /// - Version: 6.0.0
    /// - Complexity: O(1) for each subcommand specified
    /// - Categories: @read, @bitmap, @fast
    /// - Returns: [Array](https:/redis.io/docs/reference/protocol-spec#arrays): each entry being the corresponding result of the sub-command given at the same position.
    @inlinable
    public func bitfieldRo(key: RedisKey, getBlock: RESPCommand.BITFIELDROGetBlock? = nil) async throws -> [RESPToken] {
        try await send("BITFIELD_RO", key, RESPWithToken("GET", getBlock)).converting()
    }

    /// Performs arbitrary read-only bitfield integer operations on strings.
    ///
    /// - Documentation: [BITFIELD_RO](https:/redis.io/docs/latest/commands/bitfield_ro)
    /// - Version: 6.0.0
    /// - Complexity: O(1) for each subcommand specified
    /// - Categories: @read, @bitmap, @fast
    /// - Returns: [Array](https:/redis.io/docs/reference/protocol-spec#arrays): each entry being the corresponding result of the sub-command given at the same position.
    @inlinable
    public func bitfieldRo(key: RedisKey, getBlocks: [RESPCommand.BITFIELDROGetBlock]) async throws -> [RESPToken] {
        try await send("BITFIELD_RO", key, RESPWithToken("GET", getBlocks)).converting()
    }

    /// Performs bitwise operations on multiple strings, and stores the result.
    ///
    /// - Documentation: [BITOP](https:/redis.io/docs/latest/commands/bitop)
    /// - Version: 2.6.0
    /// - Complexity: O(N)
    /// - Categories: @write, @bitmap, @slow
    /// - Returns: [Integer](https:/redis.io/docs/reference/protocol-spec#integers): the size of the string stored in the destination key is equal to the size of the longest input string.
    @inlinable
    public func bitop(operation: RESPCommand.BITOPOperation, destkey: RedisKey, key: RedisKey) async throws -> Int {
        try await send("BITOP", operation, destkey, key).converting()
    }

    /// Performs bitwise operations on multiple strings, and stores the result.
    ///
    /// - Documentation: [BITOP](https:/redis.io/docs/latest/commands/bitop)
    /// - Version: 2.6.0
    /// - Complexity: O(N)
    /// - Categories: @write, @bitmap, @slow
    /// - Returns: [Integer](https:/redis.io/docs/reference/protocol-spec#integers): the size of the string stored in the destination key is equal to the size of the longest input string.
    @inlinable
    public func bitop(operation: RESPCommand.BITOPOperation, destkey: RedisKey, keys: [RedisKey]) async throws -> Int {
        try await send("BITOP", operation, destkey, keys).converting()
    }

    /// Finds the first set (1) or clear (0) bit in a string.
    ///
    /// - Documentation: [BITPOS](https:/redis.io/docs/latest/commands/bitpos)
    /// - Version: 2.8.7
    /// - Complexity: O(N)
    /// - Categories: @read, @bitmap, @slow
    /// - Returns: One of the following:
    ///     * [Integer](https:/redis.io/docs/reference/protocol-spec#integers): the position of the first bit set to 1 or 0 according to the request
    ///     * [Integer](https:/redis.io/docs/reference/protocol-spec#integers): `-1`. In case the `bit` argument is 1 and the string is empty or composed of just zero bytes
    ///     
    ///     If we look for set bits (the bit argument is 1) and the string is empty or composed of just zero bytes, -1 is returned.
    ///     
    ///     If we look for clear bits (the bit argument is 0) and the string only contains bits set to 1, the function returns the first bit not part of the string on the right. So if the string is three bytes set to the value `0xff` the command `BITPOS key 0` will return 24, since up to bit 23 all the bits are 1.
    ///     
    ///     The function considers the right of the string as padded with zeros if you look for clear bits and specify no range or the _start_ argument **only**.
    ///     
    ///     However, this behavior changes if you are looking for clear bits and specify a range with both _start_ and _end_.
    ///     If a clear bit isn't found in the specified range, the function returns -1 as the user specified a clear range and there are no 0 bits in that range.
    @inlinable
    public func bitpos(key: RedisKey, bit: Int, range: RESPCommand.BITPOSRange? = nil) async throws -> Int {
        try await send("BITPOS", key, bit, range).converting()
    }

    /// Pops an element from a list, pushes it to another list and returns it. Blocks until an element is available otherwise. Deletes the list if the last element was moved.
    ///
    /// - Documentation: [BLMOVE](https:/redis.io/docs/latest/commands/blmove)
    /// - Version: 6.2.0
    /// - Complexity: O(1)
    /// - Categories: @write, @list, @slow, @blocking
    /// - Returns: One of the following:
    ///     * [Bulk string](https:/redis.io/docs/reference/protocol-spec#bulk-strings): the element being popped from the _source_ and pushed to the _destination_.
    ///     * [Null](https:/redis.io/docs/reference/protocol-spec#nulls): the operation timed-out
    @inlinable
    public func blmove(source: RedisKey, destination: RedisKey, wherefrom: RESPCommand.BLMOVEWherefrom, whereto: RESPCommand.BLMOVEWhereto, timeout: Double) async throws -> String? {
        try await send("BLMOVE", source, destination, wherefrom, whereto, timeout).converting()
    }

    /// Pops the first element from one of multiple lists. Blocks until an element is available otherwise. Deletes the list if the last element was popped.
    ///
    /// - Documentation: [BLMPOP](https:/redis.io/docs/latest/commands/blmpop)
    /// - Version: 7.0.0
    /// - Complexity: O(N+M) where N is the number of provided keys and M is the number of elements returned.
    /// - Categories: @write, @list, @slow, @blocking
    /// - Returns: One of the following:
    ///     * [Null](https:/redis.io/docs/reference/protocol-spec#nulls): when no element could be popped and the _timeout_ is reached.
    ///     * [Array](https:/redis.io/docs/reference/protocol-spec#arrays): a two-element array with the first element being the name of the key from which elements were popped, and the second element being an array of the popped elements.
    @inlinable
    public func blmpop(timeout: Double, key: RedisKey, `where`: RESPCommand.BLMPOPWhere, count: Int? = nil) async throws -> [RESPToken]? {
        try await send("BLMPOP", timeout, 1, key, `where`, RESPWithToken("COUNT", count)).converting()
    }

    /// Pops the first element from one of multiple lists. Blocks until an element is available otherwise. Deletes the list if the last element was popped.
    ///
    /// - Documentation: [BLMPOP](https:/redis.io/docs/latest/commands/blmpop)
    /// - Version: 7.0.0
    /// - Complexity: O(N+M) where N is the number of provided keys and M is the number of elements returned.
    /// - Categories: @write, @list, @slow, @blocking
    /// - Returns: One of the following:
    ///     * [Null](https:/redis.io/docs/reference/protocol-spec#nulls): when no element could be popped and the _timeout_ is reached.
    ///     * [Array](https:/redis.io/docs/reference/protocol-spec#arrays): a two-element array with the first element being the name of the key from which elements were popped, and the second element being an array of the popped elements.
    @inlinable
    public func blmpop(timeout: Double, keys: [RedisKey], `where`: RESPCommand.BLMPOPWhere, count: Int? = nil) async throws -> [RESPToken]? {
        try await send("BLMPOP", timeout, RESPArrayWithCount(keys), `where`, RESPWithToken("COUNT", count)).converting()
    }

    /// Removes and returns the first element in a list. Blocks until an element is available otherwise. Deletes the list if the last element was popped.
    ///
    /// - Documentation: [BLPOP](https:/redis.io/docs/latest/commands/blpop)
    /// - Version: 2.0.0
    /// - Complexity: O(N) where N is the number of provided keys.
    /// - Categories: @write, @list, @slow, @blocking
    /// - Returns: One of the following:
    ///     * [Null](https:/redis.io/docs/reference/protocol-spec#nulls): no element could be popped and the timeout expired
    ///     * [Array](https:/redis.io/docs/reference/protocol-spec#arrays): the key from which the element was popped and the value of the popped element.
    @inlinable
    public func blpop(key: RedisKey, timeout: Double) async throws -> [RESPToken]? {
        try await send("BLPOP", key, timeout).converting()
    }

    /// Removes and returns the first element in a list. Blocks until an element is available otherwise. Deletes the list if the last element was popped.
    ///
    /// - Documentation: [BLPOP](https:/redis.io/docs/latest/commands/blpop)
    /// - Version: 2.0.0
    /// - Complexity: O(N) where N is the number of provided keys.
    /// - Categories: @write, @list, @slow, @blocking
    /// - Returns: One of the following:
    ///     * [Null](https:/redis.io/docs/reference/protocol-spec#nulls): no element could be popped and the timeout expired
    ///     * [Array](https:/redis.io/docs/reference/protocol-spec#arrays): the key from which the element was popped and the value of the popped element.
    @inlinable
    public func blpop(keys: [RedisKey], timeout: Double) async throws -> [RESPToken]? {
        try await send("BLPOP", keys, timeout).converting()
    }

    /// Removes and returns the last element in a list. Blocks until an element is available otherwise. Deletes the list if the last element was popped.
    ///
    /// - Documentation: [BRPOP](https:/redis.io/docs/latest/commands/brpop)
    /// - Version: 2.0.0
    /// - Complexity: O(N) where N is the number of provided keys.
    /// - Categories: @write, @list, @slow, @blocking
    /// - Returns: One of the following:
    ///     * [Null](https:/redis.io/docs/reference/protocol-spec#nulls): no element could be popped and the timeout expired.
    ///     * [Array](https:/redis.io/docs/reference/protocol-spec#arrays): the key from which the element was popped and the value of the popped element
    @inlinable
    public func brpop(key: RedisKey, timeout: Double) async throws -> [RESPToken]? {
        try await send("BRPOP", key, timeout).converting()
    }

    /// Removes and returns the last element in a list. Blocks until an element is available otherwise. Deletes the list if the last element was popped.
    ///
    /// - Documentation: [BRPOP](https:/redis.io/docs/latest/commands/brpop)
    /// - Version: 2.0.0
    /// - Complexity: O(N) where N is the number of provided keys.
    /// - Categories: @write, @list, @slow, @blocking
    /// - Returns: One of the following:
    ///     * [Null](https:/redis.io/docs/reference/protocol-spec#nulls): no element could be popped and the timeout expired.
    ///     * [Array](https:/redis.io/docs/reference/protocol-spec#arrays): the key from which the element was popped and the value of the popped element
    @inlinable
    public func brpop(keys: [RedisKey], timeout: Double) async throws -> [RESPToken]? {
        try await send("BRPOP", keys, timeout).converting()
    }

    /// Pops an element from a list, pushes it to another list and returns it. Block until an element is available otherwise. Deletes the list if the last element was popped.
    ///
    /// - Documentation: [BRPOPLPUSH](https:/redis.io/docs/latest/commands/brpoplpush)
    /// - Version: 2.2.0
    /// - Complexity: O(1)
    /// - Categories: @write, @list, @slow, @blocking
    /// - Returns: One of the following:
    ///     * [Bulk string](https:/redis.io/docs/reference/protocol-spec#bulk-strings): the element being popped from _source_ and pushed to _destination_.
    ///     * [Null](https:/redis.io/docs/reference/protocol-spec#nulls): the timeout is reached.
    @inlinable
    public func brpoplpush(source: RedisKey, destination: RedisKey, timeout: Double) async throws -> String? {
        try await send("BRPOPLPUSH", source, destination, timeout).converting()
    }

    /// Removes and returns a member by score from one or more sorted sets. Blocks until a member is available otherwise. Deletes the sorted set if the last element was popped.
    ///
    /// - Documentation: [BZMPOP](https:/redis.io/docs/latest/commands/bzmpop)
    /// - Version: 7.0.0
    /// - Complexity: O(K) + O(M*log(N)) where K is the number of provided keys, N being the number of elements in the sorted set, and M being the number of elements popped.
    /// - Categories: @write, @sortedset, @slow, @blocking
    /// - Returns: One of the following:
    ///     * [Null](https:/redis.io/docs/reference/protocol-spec#nulls): when no element could be popped.
    ///     * [Array](https:/redis.io/docs/reference/protocol-spec#arrays): a two-element array with the first element being the name of the key from which elements were popped, and the second element is an array of the popped elements. Every entry in the elements array is also an array that contains the member and its score.
    @inlinable
    public func bzmpop(timeout: Double, key: RedisKey, `where`: RESPCommand.BZMPOPWhere, count: Int? = nil) async throws -> [RESPToken]? {
        try await send("BZMPOP", timeout, 1, key, `where`, RESPWithToken("COUNT", count)).converting()
    }

    /// Removes and returns a member by score from one or more sorted sets. Blocks until a member is available otherwise. Deletes the sorted set if the last element was popped.
    ///
    /// - Documentation: [BZMPOP](https:/redis.io/docs/latest/commands/bzmpop)
    /// - Version: 7.0.0
    /// - Complexity: O(K) + O(M*log(N)) where K is the number of provided keys, N being the number of elements in the sorted set, and M being the number of elements popped.
    /// - Categories: @write, @sortedset, @slow, @blocking
    /// - Returns: One of the following:
    ///     * [Null](https:/redis.io/docs/reference/protocol-spec#nulls): when no element could be popped.
    ///     * [Array](https:/redis.io/docs/reference/protocol-spec#arrays): a two-element array with the first element being the name of the key from which elements were popped, and the second element is an array of the popped elements. Every entry in the elements array is also an array that contains the member and its score.
    @inlinable
    public func bzmpop(timeout: Double, keys: [RedisKey], `where`: RESPCommand.BZMPOPWhere, count: Int? = nil) async throws -> [RESPToken]? {
        try await send("BZMPOP", timeout, RESPArrayWithCount(keys), `where`, RESPWithToken("COUNT", count)).converting()
    }

    /// Removes and returns the member with the highest score from one or more sorted sets. Blocks until a member available otherwise.  Deletes the sorted set if the last element was popped.
    ///
    /// - Documentation: [BZPOPMAX](https:/redis.io/docs/latest/commands/bzpopmax)
    /// - Version: 5.0.0
    /// - Complexity: O(log(N)) with N being the number of elements in the sorted set.
    /// - Categories: @write, @sortedset, @fast, @blocking
    /// - Returns: One of the following:
    ///     * [Null](https:/redis.io/docs/reference/protocol-spec#nulls): when no element could be popped and the _timeout_ expired.
    ///     * [Array](https:/redis.io/docs/reference/protocol-spec#arrays): the keyname, popped member, and its score.
    @inlinable
    public func bzpopmax(key: RedisKey, timeout: Double) async throws -> [RESPToken]? {
        try await send("BZPOPMAX", key, timeout).converting()
    }

    /// Removes and returns the member with the highest score from one or more sorted sets. Blocks until a member available otherwise.  Deletes the sorted set if the last element was popped.
    ///
    /// - Documentation: [BZPOPMAX](https:/redis.io/docs/latest/commands/bzpopmax)
    /// - Version: 5.0.0
    /// - Complexity: O(log(N)) with N being the number of elements in the sorted set.
    /// - Categories: @write, @sortedset, @fast, @blocking
    /// - Returns: One of the following:
    ///     * [Null](https:/redis.io/docs/reference/protocol-spec#nulls): when no element could be popped and the _timeout_ expired.
    ///     * [Array](https:/redis.io/docs/reference/protocol-spec#arrays): the keyname, popped member, and its score.
    @inlinable
    public func bzpopmax(keys: [RedisKey], timeout: Double) async throws -> [RESPToken]? {
        try await send("BZPOPMAX", keys, timeout).converting()
    }

    /// Removes and returns the member with the lowest score from one or more sorted sets. Blocks until a member is available otherwise. Deletes the sorted set if the last element was popped.
    ///
    /// - Documentation: [BZPOPMIN](https:/redis.io/docs/latest/commands/bzpopmin)
    /// - Version: 5.0.0
    /// - Complexity: O(log(N)) with N being the number of elements in the sorted set.
    /// - Categories: @write, @sortedset, @fast, @blocking
    /// - Returns: One of the following:
    ///     * [Null](https:/redis.io/docs/reference/protocol-spec#nulls): when no element could be popped and the _timeout_ expired.
    ///     * [Array](https:/redis.io/docs/reference/protocol-spec#arrays): the keyname, popped member, and its score.
    @inlinable
    public func bzpopmin(key: RedisKey, timeout: Double) async throws -> [RESPToken]? {
        try await send("BZPOPMIN", key, timeout).converting()
    }

    /// Removes and returns the member with the lowest score from one or more sorted sets. Blocks until a member is available otherwise. Deletes the sorted set if the last element was popped.
    ///
    /// - Documentation: [BZPOPMIN](https:/redis.io/docs/latest/commands/bzpopmin)
    /// - Version: 5.0.0
    /// - Complexity: O(log(N)) with N being the number of elements in the sorted set.
    /// - Categories: @write, @sortedset, @fast, @blocking
    /// - Returns: One of the following:
    ///     * [Null](https:/redis.io/docs/reference/protocol-spec#nulls): when no element could be popped and the _timeout_ expired.
    ///     * [Array](https:/redis.io/docs/reference/protocol-spec#arrays): the keyname, popped member, and its score.
    @inlinable
    public func bzpopmin(keys: [RedisKey], timeout: Double) async throws -> [RESPToken]? {
        try await send("BZPOPMIN", keys, timeout).converting()
    }

    /// Instructs the server whether to track the keys in the next request.
    ///
    /// - Documentation: [CLIENT CACHING](https:/redis.io/docs/latest/commands/client-caching)
    /// - Version: 6.0.0
    /// - Complexity: O(1)
    /// - Categories: @slow, @connection
    /// - Returns: [Simple string](https:/redis.io/docs/reference/protocol-spec#simple-strings): `OK` or an error if the argument is not "yes" or "no".
    @inlinable
    public func clientCaching(mode: RESPCommand.CLIENTCACHINGMode) async throws {
        try await send("CLIENT", "CACHING", mode)
    }

    /// Returns the name of the connection.
    ///
    /// - Documentation: [CLIENT GETNAME](https:/redis.io/docs/latest/commands/client-getname)
    /// - Version: 2.6.9
    /// - Complexity: O(1)
    /// - Categories: @slow, @connection
    /// - Returns: One of the following:
    ///     * [Bulk string](https:/redis.io/docs/reference/protocol-spec#bulk-strings): the connection name of the current connection.
    ///     * [Null](https:/redis.io/docs/reference/protocol-spec#nulls): the connection name was not set.
    @inlinable
    public func clientGetname() async throws -> String? {
        try await send("CLIENT", "GETNAME").converting()
    }

    /// Returns the client ID to which the connection's tracking notifications are redirected.
    ///
    /// - Documentation: [CLIENT GETREDIR](https:/redis.io/docs/latest/commands/client-getredir)
    /// - Version: 6.0.0
    /// - Complexity: O(1)
    /// - Categories: @slow, @connection
    /// - Returns: One of the following:
    ///     * [Integer](https:/redis.io/docs/reference/protocol-spec#integers): `0` when not redirecting notifications to any client.
    ///     * [Integer](https:/redis.io/docs/reference/protocol-spec#integers): `-1` if client tracking is not enabled.
    ///     * [Integer](https:/redis.io/docs/reference/protocol-spec#integers): the ID of the client to which notification are being redirected.
    @inlinable
    public func clientGetredir() async throws -> Int {
        try await send("CLIENT", "GETREDIR").converting()
    }

    /// Returns helpful text about the different subcommands.
    ///
    /// - Documentation: [CLIENT HELP](https:/redis.io/docs/latest/commands/client-help)
    /// - Version: 5.0.0
    /// - Complexity: O(1)
    /// - Categories: @slow, @connection
    /// - Returns: [Array](https:/redis.io/docs/reference/protocol-spec#arrays): a list of subcommands and their descriptions.
    @inlinable
    public func clientHelp() async throws -> [RESPToken] {
        try await send("CLIENT", "HELP").converting()
    }

    /// Returns the unique client ID of the connection.
    ///
    /// - Documentation: [CLIENT ID](https:/redis.io/docs/latest/commands/client-id)
    /// - Version: 5.0.0
    /// - Complexity: O(1)
    /// - Categories: @slow, @connection
    /// - Returns: [Integer](https:/redis.io/docs/reference/protocol-spec#integers): the ID of the client.
    @inlinable
    public func clientId() async throws -> Int {
        try await send("CLIENT", "ID").converting()
    }

    /// Returns information about the connection.
    ///
    /// - Documentation: [CLIENT INFO](https:/redis.io/docs/latest/commands/client-info)
    /// - Version: 6.2.0
    /// - Complexity: O(1)
    /// - Categories: @slow, @connection
    /// - Returns: [Bulk string](https:/redis.io/docs/reference/protocol-spec#bulk-strings): a unique string for the current client, as described at the `CLIENT LIST` page.
    @inlinable
    public func clientInfo() async throws -> String {
        try await send("CLIENT", "INFO").converting()
    }

    /// Terminates open connections.
    ///
    /// - Documentation: [CLIENT KILL](https:/redis.io/docs/latest/commands/client-kill)
    /// - Version: 2.4.0
    /// - Complexity: O(N) where N is the number of client connections
    /// - Categories: @admin, @slow, @dangerous, @connection
    /// - Returns: One of the following:
    ///     * [Simple string](https:/redis.io/docs/reference/protocol-spec#simple-strings): `OK` when called in 3 argument format and the connection has been closed.
    ///     * [Integer](https:/redis.io/docs/reference/protocol-spec#integers): when called in filter/value format, the number of clients killed.
    @inlinable
    public func clientKill(filter: RESPCommand.CLIENTKILLFilter) async throws -> Int? {
        try await send("CLIENT", "KILL", filter).converting()
    }

    /// Lists open connections.
    ///
    /// - Documentation: [CLIENT LIST](https:/redis.io/docs/latest/commands/client-list)
    /// - Version: 2.4.0
    /// - Complexity: O(N) where N is the number of client connections
    /// - Categories: @admin, @slow, @dangerous, @connection
    /// - Returns: [Bulk string](https:/redis.io/docs/reference/protocol-spec#bulk-strings): information and statistics about client connections.
    @inlinable
    public func clientList(clientType: RESPCommand.CLIENTLISTClientType? = nil, clientId: Int? = nil) async throws -> String {
        try await send("CLIENT", "LIST", RESPWithToken("TYPE", clientType), RESPWithToken("ID", clientId)).converting()
    }

    /// Lists open connections.
    ///
    /// - Documentation: [CLIENT LIST](https:/redis.io/docs/latest/commands/client-list)
    /// - Version: 2.4.0
    /// - Complexity: O(N) where N is the number of client connections
    /// - Categories: @admin, @slow, @dangerous, @connection
    /// - Returns: [Bulk string](https:/redis.io/docs/reference/protocol-spec#bulk-strings): information and statistics about client connections.
    @inlinable
    public func clientList(clientType: RESPCommand.CLIENTLISTClientType? = nil, clientIds: [Int]) async throws -> String {
        try await send("CLIENT", "LIST", RESPWithToken("TYPE", clientType), RESPWithToken("ID", clientIds)).converting()
    }

    /// Sets the client eviction mode of the connection.
    ///
    /// - Documentation: [CLIENT NO-EVICT](https:/redis.io/docs/latest/commands/client-no-evict)
    /// - Version: 7.0.0
    /// - Complexity: O(1)
    /// - Categories: @admin, @slow, @dangerous, @connection
    /// - Returns: [Simple string](https:/redis.io/docs/reference/protocol-spec#simple-strings): `OK`.
    @inlinable
    public func clientNoEvict(enabled: RESPCommand.CLIENTNOEVICTEnabled) async throws {
        try await send("CLIENT", "NO-EVICT", enabled)
    }

    /// Controls whether commands sent by the client affect the LRU/LFU of accessed keys.
    ///
    /// - Documentation: [CLIENT NO-TOUCH](https:/redis.io/docs/latest/commands/client-no-touch)
    /// - Version: 7.2.0
    /// - Complexity: O(1)
    /// - Categories: @slow, @connection
    /// - Returns: [Simple string](https:/redis.io/docs/reference/protocol-spec#simple-strings): `OK`.
    @inlinable
    public func clientNoTouch(enabled: RESPCommand.CLIENTNOTOUCHEnabled) async throws {
        try await send("CLIENT", "NO-TOUCH", enabled)
    }

    /// Suspends commands processing.
    ///
    /// - Documentation: [CLIENT PAUSE](https:/redis.io/docs/latest/commands/client-pause)
    /// - Version: 3.0.0
    /// - Complexity: O(1)
    /// - Categories: @admin, @slow, @dangerous, @connection
    /// - Returns: [Simple string](https:/redis.io/docs/reference/protocol-spec#simple-strings): `OK` or an error if the timeout is invalid.
    @inlinable
    public func clientPause(timeout: Int, mode: RESPCommand.CLIENTPAUSEMode? = nil) async throws {
        try await send("CLIENT", "PAUSE", timeout, mode)
    }

    /// Instructs the server whether to reply to commands.
    ///
    /// - Documentation: [CLIENT REPLY](https:/redis.io/docs/latest/commands/client-reply)
    /// - Version: 3.2.0
    /// - Complexity: O(1)
    /// - Categories: @slow, @connection
    /// - Returns: [Simple string](https:/redis.io/docs/reference/protocol-spec#simple-strings): `OK` when called with `ON`. When called with either `OFF` or `SKIP` sub-commands, no reply is made.
    @inlinable
    public func clientReply(action: RESPCommand.CLIENTREPLYAction) async throws {
        try await send("CLIENT", "REPLY", action)
    }

    /// Sets information specific to the client or connection.
    ///
    /// - Documentation: [CLIENT SETINFO](https:/redis.io/docs/latest/commands/client-setinfo)
    /// - Version: 7.2.0
    /// - Complexity: O(1)
    /// - Categories: @slow, @connection
    /// - Returns: [Simple string](https:/redis.io/docs/reference/protocol-spec#simple-strings): `OK` if the attribute name was successfully set.
    @inlinable
    public func clientSetinfo(attr: RESPCommand.CLIENTSETINFOAttr) async throws {
        try await send("CLIENT", "SETINFO", attr)
    }

    /// Sets the connection name.
    ///
    /// - Documentation: [CLIENT SETNAME](https:/redis.io/docs/latest/commands/client-setname)
    /// - Version: 2.6.9
    /// - Complexity: O(1)
    /// - Categories: @slow, @connection
    /// - Returns: [Simple string](https:/redis.io/docs/reference/protocol-spec#simple-strings): `OK` if the connection name was successfully set.
    @inlinable
    public func clientSetname(connectionName: String) async throws {
        try await send("CLIENT", "SETNAME", connectionName)
    }

    /// Controls server-assisted client-side caching for the connection.
    ///
    /// - Documentation: [CLIENT TRACKING](https:/redis.io/docs/latest/commands/client-tracking)
    /// - Version: 6.0.0
    /// - Complexity: O(1). Some options may introduce additional complexity.
    /// - Categories: @slow, @connection
    /// - Returns: [Simple string](https:/redis.io/docs/reference/protocol-spec#simple-strings): `OK` if the connection was successfully put in tracking mode or if the tracking mode was successfully disabled. Otherwise, an error is returned.
    @inlinable
    public func clientTracking(status: RESPCommand.CLIENTTRACKINGStatus, clientId: Int? = nil, prefix: String? = nil, bcast: Bool = false, optin: Bool = false, optout: Bool = false, noloop: Bool = false) async throws {
        try await send("CLIENT", "TRACKING", status, RESPWithToken("REDIRECT", clientId), RESPWithToken("PREFIX", prefix), RedisPureToken("BCAST", bcast), RedisPureToken("OPTIN", optin), RedisPureToken("OPTOUT", optout), RedisPureToken("NOLOOP", noloop))
    }

    /// Controls server-assisted client-side caching for the connection.
    ///
    /// - Documentation: [CLIENT TRACKING](https:/redis.io/docs/latest/commands/client-tracking)
    /// - Version: 6.0.0
    /// - Complexity: O(1). Some options may introduce additional complexity.
    /// - Categories: @slow, @connection
    /// - Returns: [Simple string](https:/redis.io/docs/reference/protocol-spec#simple-strings): `OK` if the connection was successfully put in tracking mode or if the tracking mode was successfully disabled. Otherwise, an error is returned.
    @inlinable
    public func clientTracking(status: RESPCommand.CLIENTTRACKINGStatus, clientId: Int? = nil, prefixs: [String], bcast: Bool = false, optin: Bool = false, optout: Bool = false, noloop: Bool = false) async throws {
        try await send("CLIENT", "TRACKING", status, RESPWithToken("REDIRECT", clientId), RESPWithToken("PREFIX", prefixs), RedisPureToken("BCAST", bcast), RedisPureToken("OPTIN", optin), RedisPureToken("OPTOUT", optout), RedisPureToken("NOLOOP", noloop))
    }

    /// Returns information about server-assisted client-side caching for the connection.
    ///
    /// - Documentation: [CLIENT TRACKINGINFO](https:/redis.io/docs/latest/commands/client-trackinginfo)
    /// - Version: 6.2.0
    /// - Complexity: O(1)
    /// - Categories: @slow, @connection
    /// - Returns: [Map](https:/redis.io/docs/reference/protocol-spec#maps): a list of tracking information sections and their respective values.
    @inlinable
    public func clientTrackinginfo() async throws -> RESPToken {
        try await send("CLIENT", "TRACKINGINFO").converting()
    }

    /// Unblocks a client blocked by a blocking command from a different connection.
    ///
    /// - Documentation: [CLIENT UNBLOCK](https:/redis.io/docs/latest/commands/client-unblock)
    /// - Version: 5.0.0
    /// - Complexity: O(log N) where N is the number of client connections
    /// - Categories: @admin, @slow, @dangerous, @connection
    /// - Returns: One of the following:
    ///     * [Integer](https:/redis.io/docs/reference/protocol-spec#integers): `0` if the client was unblocked successfully.
    ///     * [Integer](https:/redis.io/docs/reference/protocol-spec#integers): `1` if the client wasn't unblocked.
    @inlinable
    public func clientUnblock(clientId: Int, unblockType: RESPCommand.CLIENTUNBLOCKUnblockType? = nil) async throws -> Int {
        try await send("CLIENT", "UNBLOCK", clientId, unblockType).converting()
    }

    /// Resumes processing commands from paused clients.
    ///
    /// - Documentation: [CLIENT UNPAUSE](https:/redis.io/docs/latest/commands/client-unpause)
    /// - Version: 6.2.0
    /// - Complexity: O(N) Where N is the number of paused clients
    /// - Categories: @admin, @slow, @dangerous, @connection
    /// - Returns: [Simple string](https:/redis.io/docs/reference/protocol-spec#simple-strings): `OK`.
    @inlinable
    public func clientUnpause() async throws {
        try await send("CLIENT", "UNPAUSE")
    }

    /// Assigns new hash slots to a node.
    ///
    /// - Documentation: [CLUSTER ADDSLOTS](https:/redis.io/docs/latest/commands/cluster-addslots)
    /// - Version: 3.0.0
    /// - Complexity: O(N) where N is the total number of hash slot arguments
    /// - Categories: @admin, @slow, @dangerous
    /// - Returns: [Simple string](https:/redis.io/docs/reference/protocol-spec#simple-strings): `OK` if the command was successful. Otherwise an error is returned.
    @inlinable
    public func clusterAddslots(slot: Int) async throws {
        try await send("CLUSTER", "ADDSLOTS", slot)
    }

    /// Assigns new hash slots to a node.
    ///
    /// - Documentation: [CLUSTER ADDSLOTS](https:/redis.io/docs/latest/commands/cluster-addslots)
    /// - Version: 3.0.0
    /// - Complexity: O(N) where N is the total number of hash slot arguments
    /// - Categories: @admin, @slow, @dangerous
    /// - Returns: [Simple string](https:/redis.io/docs/reference/protocol-spec#simple-strings): `OK` if the command was successful. Otherwise an error is returned.
    @inlinable
    public func clusterAddslots(slots: [Int]) async throws {
        try await send("CLUSTER", "ADDSLOTS", slots)
    }

    /// Assigns new hash slot ranges to a node.
    ///
    /// - Documentation: [CLUSTER ADDSLOTSRANGE](https:/redis.io/docs/latest/commands/cluster-addslotsrange)
    /// - Version: 7.0.0
    /// - Complexity: O(N) where N is the total number of the slots between the start slot and end slot arguments.
    /// - Categories: @admin, @slow, @dangerous
    /// - Returns: [Simple string](https:/redis.io/docs/reference/protocol-spec#simple-strings): `OK` if the command was successful. Otherwise an error is returned.
    @inlinable
    public func clusterAddslotsrange(range: RESPCommand.CLUSTERADDSLOTSRANGERange) async throws {
        try await send("CLUSTER", "ADDSLOTSRANGE", range)
    }

    /// Assigns new hash slot ranges to a node.
    ///
    /// - Documentation: [CLUSTER ADDSLOTSRANGE](https:/redis.io/docs/latest/commands/cluster-addslotsrange)
    /// - Version: 7.0.0
    /// - Complexity: O(N) where N is the total number of the slots between the start slot and end slot arguments.
    /// - Categories: @admin, @slow, @dangerous
    /// - Returns: [Simple string](https:/redis.io/docs/reference/protocol-spec#simple-strings): `OK` if the command was successful. Otherwise an error is returned.
    @inlinable
    public func clusterAddslotsrange(ranges: [RESPCommand.CLUSTERADDSLOTSRANGERange]) async throws {
        try await send("CLUSTER", "ADDSLOTSRANGE", ranges)
    }

    /// Advances the cluster config epoch.
    ///
    /// - Documentation: [CLUSTER BUMPEPOCH](https:/redis.io/docs/latest/commands/cluster-bumpepoch)
    /// - Version: 3.0.0
    /// - Complexity: O(1)
    /// - Categories: @admin, @slow, @dangerous
    /// - Returns: One of the following:
    ///     * [Bulk string](https:/redis.io/docs/reference/protocol-spec#bulk-strings): `BUMPED` if the epoch was incremented.
    ///     * [Bulk string](https:/redis.io/docs/reference/protocol-spec#bulk-strings): `STILL` if the node already has the greatest configured epoch in the cluster.
    @inlinable
    public func clusterBumpepoch() async throws -> String {
        try await send("CLUSTER", "BUMPEPOCH").converting()
    }

    /// Returns the number of active failure reports active for a node.
    ///
    /// - Documentation: [CLUSTER COUNT-FAILURE-REPORTS](https:/redis.io/docs/latest/commands/cluster-count-failure-reports)
    /// - Version: 3.0.0
    /// - Complexity: O(N) where N is the number of failure reports
    /// - Categories: @admin, @slow, @dangerous
    /// - Returns: [Integer](https:/redis.io/docs/reference/protocol-spec#integers): the number of active failure reports for the node.
    @inlinable
    public func clusterCountFailureReports(nodeId: String) async throws -> Int {
        try await send("CLUSTER", "COUNT-FAILURE-REPORTS", nodeId).converting()
    }

    /// Returns the number of keys in a hash slot.
    ///
    /// - Documentation: [CLUSTER COUNTKEYSINSLOT](https:/redis.io/docs/latest/commands/cluster-countkeysinslot)
    /// - Version: 3.0.0
    /// - Complexity: O(1)
    /// - Categories: @slow
    /// - Returns: [Integer](https:/redis.io/docs/reference/protocol-spec#integers): The number of keys in the specified hash slot, or an error if the hash slot is invalid.
    @inlinable
    public func clusterCountkeysinslot(slot: Int) async throws -> Int {
        try await send("CLUSTER", "COUNTKEYSINSLOT", slot).converting()
    }

    /// Sets hash slots as unbound for a node.
    ///
    /// - Documentation: [CLUSTER DELSLOTS](https:/redis.io/docs/latest/commands/cluster-delslots)
    /// - Version: 3.0.0
    /// - Complexity: O(N) where N is the total number of hash slot arguments
    /// - Categories: @admin, @slow, @dangerous
    /// - Returns: [Simple string](https:/redis.io/docs/reference/protocol-spec#simple-strings): `OK` if the command was successful. Otherwise an error is returned.
    @inlinable
    public func clusterDelslots(slot: Int) async throws {
        try await send("CLUSTER", "DELSLOTS", slot)
    }

    /// Sets hash slots as unbound for a node.
    ///
    /// - Documentation: [CLUSTER DELSLOTS](https:/redis.io/docs/latest/commands/cluster-delslots)
    /// - Version: 3.0.0
    /// - Complexity: O(N) where N is the total number of hash slot arguments
    /// - Categories: @admin, @slow, @dangerous
    /// - Returns: [Simple string](https:/redis.io/docs/reference/protocol-spec#simple-strings): `OK` if the command was successful. Otherwise an error is returned.
    @inlinable
    public func clusterDelslots(slots: [Int]) async throws {
        try await send("CLUSTER", "DELSLOTS", slots)
    }

    /// Sets hash slot ranges as unbound for a node.
    ///
    /// - Documentation: [CLUSTER DELSLOTSRANGE](https:/redis.io/docs/latest/commands/cluster-delslotsrange)
    /// - Version: 7.0.0
    /// - Complexity: O(N) where N is the total number of the slots between the start slot and end slot arguments.
    /// - Categories: @admin, @slow, @dangerous
    /// - Returns: [Simple string](https:/redis.io/docs/reference/protocol-spec#simple-strings): `OK` if the command was successful. Otherwise an error is returned.
    @inlinable
    public func clusterDelslotsrange(range: RESPCommand.CLUSTERDELSLOTSRANGERange) async throws {
        try await send("CLUSTER", "DELSLOTSRANGE", range)
    }

    /// Sets hash slot ranges as unbound for a node.
    ///
    /// - Documentation: [CLUSTER DELSLOTSRANGE](https:/redis.io/docs/latest/commands/cluster-delslotsrange)
    /// - Version: 7.0.0
    /// - Complexity: O(N) where N is the total number of the slots between the start slot and end slot arguments.
    /// - Categories: @admin, @slow, @dangerous
    /// - Returns: [Simple string](https:/redis.io/docs/reference/protocol-spec#simple-strings): `OK` if the command was successful. Otherwise an error is returned.
    @inlinable
    public func clusterDelslotsrange(ranges: [RESPCommand.CLUSTERDELSLOTSRANGERange]) async throws {
        try await send("CLUSTER", "DELSLOTSRANGE", ranges)
    }

    /// Forces a replica to perform a manual failover of its master.
    ///
    /// - Documentation: [CLUSTER FAILOVER](https:/redis.io/docs/latest/commands/cluster-failover)
    /// - Version: 3.0.0
    /// - Complexity: O(1)
    /// - Categories: @admin, @slow, @dangerous
    /// - Returns: [Simple string](https:/redis.io/docs/reference/protocol-spec#simple-strings): `OK` if the command was accepted and a manual failover is going to be attempted. An error if the operation cannot be executed, for example if the client is connected to a node that is already a master.
    @inlinable
    public func clusterFailover(options: RESPCommand.CLUSTERFAILOVEROptions? = nil) async throws {
        try await send("CLUSTER", "FAILOVER", options)
    }

    /// Deletes all slots information from a node.
    ///
    /// - Documentation: [CLUSTER FLUSHSLOTS](https:/redis.io/docs/latest/commands/cluster-flushslots)
    /// - Version: 3.0.0
    /// - Complexity: O(1)
    /// - Categories: @admin, @slow, @dangerous
    /// - Returns: [Simple string](https:/redis.io/docs/reference/protocol-spec#simple-strings): `OK`.
    @inlinable
    public func clusterFlushslots() async throws {
        try await send("CLUSTER", "FLUSHSLOTS")
    }

    /// Removes a node from the nodes table.
    ///
    /// - Documentation: [CLUSTER FORGET](https:/redis.io/docs/latest/commands/cluster-forget)
    /// - Version: 3.0.0
    /// - Complexity: O(1)
    /// - Categories: @admin, @slow, @dangerous
    /// - Returns: [Simple string](https:/redis.io/docs/reference/protocol-spec#simple-strings): `OK` if the command was executed successfully. Otherwise an error is returned.
    @inlinable
    public func clusterForget(nodeId: String) async throws {
        try await send("CLUSTER", "FORGET", nodeId)
    }

    /// Returns the key names in a hash slot.
    ///
    /// - Documentation: [CLUSTER GETKEYSINSLOT](https:/redis.io/docs/latest/commands/cluster-getkeysinslot)
    /// - Version: 3.0.0
    /// - Complexity: O(N) where N is the number of requested keys
    /// - Categories: @slow
    /// - Returns: [Array](https:/redis.io/docs/reference/protocol-spec#arrays): an array with up to count elements.
    @inlinable
    public func clusterGetkeysinslot(slot: Int, count: Int) async throws -> [RESPToken] {
        try await send("CLUSTER", "GETKEYSINSLOT", slot, count).converting()
    }

    /// Returns helpful text about the different subcommands.
    ///
    /// - Documentation: [CLUSTER HELP](https:/redis.io/docs/latest/commands/cluster-help)
    /// - Version: 5.0.0
    /// - Complexity: O(1)
    /// - Categories: @slow
    /// - Returns: [Array](https:/redis.io/docs/reference/protocol-spec#arrays): a list of subcommands and their descriptions.
    @inlinable
    public func clusterHelp() async throws -> [RESPToken] {
        try await send("CLUSTER", "HELP").converting()
    }

    /// Returns information about the state of a node.
    ///
    /// - Documentation: [CLUSTER INFO](https:/redis.io/docs/latest/commands/cluster-info)
    /// - Version: 3.0.0
    /// - Complexity: O(1)
    /// - Categories: @slow
    /// - Returns: [Bulk string](https:/redis.io/docs/reference/protocol-spec#bulk-strings): A map between named fields and values in the form of <field>:<value> lines separated by newlines composed by the two bytes CRLF
    @inlinable
    public func clusterInfo() async throws -> String {
        try await send("CLUSTER", "INFO").converting()
    }

    /// Returns the hash slot for a key.
    ///
    /// - Documentation: [CLUSTER KEYSLOT](https:/redis.io/docs/latest/commands/cluster-keyslot)
    /// - Version: 3.0.0
    /// - Complexity: O(N) where N is the number of bytes in the key
    /// - Categories: @slow
    /// - Returns: [Integer](https:/redis.io/docs/reference/protocol-spec#integers): The hash slot number for the specified key
    @inlinable
    public func clusterKeyslot(key: String) async throws -> Int {
        try await send("CLUSTER", "KEYSLOT", key).converting()
    }

    /// Returns a list of all TCP links to and from peer nodes.
    ///
    /// - Documentation: [CLUSTER LINKS](https:/redis.io/docs/latest/commands/cluster-links)
    /// - Version: 7.0.0
    /// - Complexity: O(N) where N is the total number of Cluster nodes
    /// - Categories: @slow
    /// - Returns: [Array](https:/redis.io/docs/reference/protocol-spec#arrays): an array of [Map](https:/redis.io/docs/reference/protocol-spec#maps) where each map contains various attributes and their values of a cluster link.
    @inlinable
    public func clusterLinks() async throws -> [RESPToken] {
        try await send("CLUSTER", "LINKS").converting()
    }

    /// Forces a node to handshake with another node.
    ///
    /// - Documentation: [CLUSTER MEET](https:/redis.io/docs/latest/commands/cluster-meet)
    /// - Version: 3.0.0
    /// - Complexity: O(1)
    /// - Categories: @admin, @slow, @dangerous
    /// - Returns: [Simple string](https:/redis.io/docs/reference/protocol-spec#simple-strings): `OK` if the command was successful. If the address or port specified are invalid an error is returned.
    @inlinable
    public func clusterMeet(ip: String, port: Int, clusterBusPort: Int? = nil) async throws {
        try await send("CLUSTER", "MEET", ip, port, clusterBusPort)
    }

    /// Returns the ID of a node.
    ///
    /// - Documentation: [CLUSTER MYID](https:/redis.io/docs/latest/commands/cluster-myid)
    /// - Version: 3.0.0
    /// - Complexity: O(1)
    /// - Categories: @slow
    /// - Returns: [Bulk string](https:/redis.io/docs/reference/protocol-spec#bulk-strings): the node ID.
    @inlinable
    public func clusterMyid() async throws -> String {
        try await send("CLUSTER", "MYID").converting()
    }

    /// Returns the shard ID of a node.
    ///
    /// - Documentation: [CLUSTER MYSHARDID](https:/redis.io/docs/latest/commands/cluster-myshardid)
    /// - Version: 7.2.0
    /// - Complexity: O(1)
    /// - Categories: @slow
    /// - Returns: [Bulk string](https:/redis.io/docs/reference/protocol-spec#bulk-strings): the node's shard ID.
    @inlinable
    public func clusterMyshardid() async throws -> String {
        try await send("CLUSTER", "MYSHARDID").converting()
    }

    /// Returns the cluster configuration for a node.
    ///
    /// - Documentation: [CLUSTER NODES](https:/redis.io/docs/latest/commands/cluster-nodes)
    /// - Version: 3.0.0
    /// - Complexity: O(N) where N is the total number of Cluster nodes
    /// - Categories: @slow
    /// - Returns: [Bulk string](https:/redis.io/docs/reference/protocol-spec#bulk-strings): the serialized cluster configuration.
    @inlinable
    public func clusterNodes() async throws -> String {
        try await send("CLUSTER", "NODES").converting()
    }

    /// Lists the replica nodes of a master node.
    ///
    /// - Documentation: [CLUSTER REPLICAS](https:/redis.io/docs/latest/commands/cluster-replicas)
    /// - Version: 5.0.0
    /// - Complexity: O(N) where N is the number of replicas.
    /// - Categories: @admin, @slow, @dangerous
    /// - Returns: [Array](https:/redis.io/docs/reference/protocol-spec#arrays): a list of replica nodes replicating from the specified master node provided in the same format used by `CLUSTER NODES`.
    @inlinable
    public func clusterReplicas(nodeId: String) async throws -> [RESPToken] {
        try await send("CLUSTER", "REPLICAS", nodeId).converting()
    }

    /// Configure a node as replica of a master node.
    ///
    /// - Documentation: [CLUSTER REPLICATE](https:/redis.io/docs/latest/commands/cluster-replicate)
    /// - Version: 3.0.0
    /// - Complexity: O(1)
    /// - Categories: @admin, @slow, @dangerous
    /// - Returns: [Simple string](https:/redis.io/docs/reference/protocol-spec#simple-strings): `OK` if the command was successful. Otherwise an error is returned.
    @inlinable
    public func clusterReplicate(nodeId: String) async throws {
        try await send("CLUSTER", "REPLICATE", nodeId)
    }

    /// Resets a node.
    ///
    /// - Documentation: [CLUSTER RESET](https:/redis.io/docs/latest/commands/cluster-reset)
    /// - Version: 3.0.0
    /// - Complexity: O(N) where N is the number of known nodes. The command may execute a FLUSHALL as a side effect.
    /// - Categories: @admin, @slow, @dangerous
    /// - Returns: [Simple string](https:/redis.io/docs/reference/protocol-spec#simple-strings): `OK` if the command was successful. Otherwise an error is returned.
    @inlinable
    public func clusterReset(resetType: RESPCommand.CLUSTERRESETResetType? = nil) async throws {
        try await send("CLUSTER", "RESET", resetType)
    }

    /// Forces a node to save the cluster configuration to disk.
    ///
    /// - Documentation: [CLUSTER SAVECONFIG](https:/redis.io/docs/latest/commands/cluster-saveconfig)
    /// - Version: 3.0.0
    /// - Complexity: O(1)
    /// - Categories: @admin, @slow, @dangerous
    /// - Returns: [Simple string](https:/redis.io/docs/reference/protocol-spec#simple-strings): `OK` if the command was successful. Otherwise an error is returned.
    @inlinable
    public func clusterSaveconfig() async throws {
        try await send("CLUSTER", "SAVECONFIG")
    }

    /// Sets the configuration epoch for a new node.
    ///
    /// - Documentation: [CLUSTER SET-CONFIG-EPOCH](https:/redis.io/docs/latest/commands/cluster-set-config-epoch)
    /// - Version: 3.0.0
    /// - Complexity: O(1)
    /// - Categories: @admin, @slow, @dangerous
    /// - Returns: [Simple string](https:/redis.io/docs/reference/protocol-spec#simple-strings): `OK` if the command was successful. Otherwise an error is returned.
    @inlinable
    public func clusterSetConfigEpoch(configEpoch: Int) async throws {
        try await send("CLUSTER", "SET-CONFIG-EPOCH", configEpoch)
    }

    /// Binds a hash slot to a node.
    ///
    /// - Documentation: [CLUSTER SETSLOT](https:/redis.io/docs/latest/commands/cluster-setslot)
    /// - Version: 3.0.0
    /// - Complexity: O(1)
    /// - Categories: @admin, @slow, @dangerous
    /// - Returns: [Simple string](https:/redis.io/docs/reference/protocol-spec#simple-strings): all the sub-commands return `OK` if the command was successful. Otherwise an error is returned.
    @inlinable
    public func clusterSetslot(slot: Int, subcommand: RESPCommand.CLUSTERSETSLOTSubcommand) async throws {
        try await send("CLUSTER", "SETSLOT", slot, subcommand)
    }

    /// Returns the mapping of cluster slots to shards.
    ///
    /// - Documentation: [CLUSTER SHARDS](https:/redis.io/docs/latest/commands/cluster-shards)
    /// - Version: 7.0.0
    /// - Complexity: O(N) where N is the total number of cluster nodes
    /// - Categories: @slow
    /// - Returns: [Array](https:/redis.io/docs/reference/protocol-spec#arrays): a nested list of [Map](https:/redis.io/docs/reference/protocol-spec#maps) of hash ranges and shard nodes describing individual shards.
    @inlinable
    public func clusterShards() async throws -> [RESPToken] {
        try await send("CLUSTER", "SHARDS").converting()
    }

    /// Lists the replica nodes of a master node.
    ///
    /// - Documentation: [CLUSTER SLAVES](https:/redis.io/docs/latest/commands/cluster-slaves)
    /// - Version: 3.0.0
    /// - Complexity: O(N) where N is the number of replicas.
    /// - Categories: @admin, @slow, @dangerous
    /// - Returns: [Array](https:/redis.io/docs/reference/protocol-spec#arrays): a list of replica nodes replicating from the specified master node provided in the same format used by `CLUSTER NODES`.
    @inlinable
    public func clusterSlaves(nodeId: String) async throws -> [RESPToken] {
        try await send("CLUSTER", "SLAVES", nodeId).converting()
    }

    /// Returns the mapping of cluster slots to nodes.
    ///
    /// - Documentation: [CLUSTER SLOTS](https:/redis.io/docs/latest/commands/cluster-slots)
    /// - Version: 3.0.0
    /// - Complexity: O(N) where N is the total number of Cluster nodes
    /// - Categories: @slow
    /// - Returns: [Array](https:/redis.io/docs/reference/protocol-spec#arrays): nested list of slot ranges with networking information.
    @inlinable
    public func clusterSlots() async throws -> [RESPToken] {
        try await send("CLUSTER", "SLOTS").converting()
    }

    /// Returns detailed information about all commands.
    ///
    /// - Documentation: [COMMAND](https:/redis.io/docs/latest/commands/command)
    /// - Version: 2.8.13
    /// - Complexity: O(N) where N is the total number of Redis commands
    /// - Categories: @slow, @connection
    /// - Returns: [Array](https:/redis.io/docs/reference/protocol-spec#arrays): a nested list of command details. The order of the commands in the array is random.
    @inlinable
    public func command() async throws -> [RESPToken] {
        try await send("COMMAND").converting()
    }

    /// Returns a count of commands.
    ///
    /// - Documentation: [COMMAND COUNT](https:/redis.io/docs/latest/commands/command-count)
    /// - Version: 2.8.13
    /// - Complexity: O(1)
    /// - Categories: @slow, @connection
    /// - Returns: [Integer](https:/redis.io/docs/reference/protocol-spec#integers): the number of commands returned by `COMMAND`.
    @inlinable
    public func commandCount() async throws -> Int {
        try await send("COMMAND", "COUNT").converting()
    }

    /// Returns documentary information about one, multiple or all commands.
    ///
    /// - Documentation: [COMMAND DOCS](https:/redis.io/docs/latest/commands/command-docs)
    /// - Version: 7.0.0
    /// - Complexity: O(N) where N is the number of commands to look up
    /// - Categories: @slow, @connection
    /// - Returns: [Map](https:/redis.io/docs/reference/protocol-spec#maps): a map where each key is a command name, and each value is the documentary information.
    @inlinable
    public func commandDocs(commandName: String? = nil) async throws -> RESPToken {
        try await send("COMMAND", "DOCS", commandName).converting()
    }

    /// Returns documentary information about one, multiple or all commands.
    ///
    /// - Documentation: [COMMAND DOCS](https:/redis.io/docs/latest/commands/command-docs)
    /// - Version: 7.0.0
    /// - Complexity: O(N) where N is the number of commands to look up
    /// - Categories: @slow, @connection
    /// - Returns: [Map](https:/redis.io/docs/reference/protocol-spec#maps): a map where each key is a command name, and each value is the documentary information.
    @inlinable
    public func commandDocs(commandNames: [String]) async throws -> RESPToken {
        try await send("COMMAND", "DOCS", commandNames).converting()
    }

    /// Extracts the key names from an arbitrary command.
    ///
    /// - Documentation: [COMMAND GETKEYS](https:/redis.io/docs/latest/commands/command-getkeys)
    /// - Version: 2.8.13
    /// - Complexity: O(N) where N is the number of arguments to the command
    /// - Categories: @slow, @connection
    /// - Returns: [Array](https:/redis.io/docs/reference/protocol-spec#arrays): a list of keys from the given command.
    @inlinable
    public func commandGetkeys(command: String, arg: String? = nil) async throws -> [RESPToken] {
        try await send("COMMAND", "GETKEYS", command, arg).converting()
    }

    /// Extracts the key names from an arbitrary command.
    ///
    /// - Documentation: [COMMAND GETKEYS](https:/redis.io/docs/latest/commands/command-getkeys)
    /// - Version: 2.8.13
    /// - Complexity: O(N) where N is the number of arguments to the command
    /// - Categories: @slow, @connection
    /// - Returns: [Array](https:/redis.io/docs/reference/protocol-spec#arrays): a list of keys from the given command.
    @inlinable
    public func commandGetkeys(command: String, args: [String]) async throws -> [RESPToken] {
        try await send("COMMAND", "GETKEYS", command, args).converting()
    }

    /// Extracts the key names and access flags for an arbitrary command.
    ///
    /// - Documentation: [COMMAND GETKEYSANDFLAGS](https:/redis.io/docs/latest/commands/command-getkeysandflags)
    /// - Version: 7.0.0
    /// - Complexity: O(N) where N is the number of arguments to the command
    /// - Categories: @slow, @connection
    /// - Returns: [Array](https:/redis.io/docs/reference/protocol-spec#arrays): a list of keys from the given command and their usage flags.
    @inlinable
    public func commandGetkeysandflags(command: String, arg: String? = nil) async throws -> [RESPToken] {
        try await send("COMMAND", "GETKEYSANDFLAGS", command, arg).converting()
    }

    /// Extracts the key names and access flags for an arbitrary command.
    ///
    /// - Documentation: [COMMAND GETKEYSANDFLAGS](https:/redis.io/docs/latest/commands/command-getkeysandflags)
    /// - Version: 7.0.0
    /// - Complexity: O(N) where N is the number of arguments to the command
    /// - Categories: @slow, @connection
    /// - Returns: [Array](https:/redis.io/docs/reference/protocol-spec#arrays): a list of keys from the given command and their usage flags.
    @inlinable
    public func commandGetkeysandflags(command: String, args: [String]) async throws -> [RESPToken] {
        try await send("COMMAND", "GETKEYSANDFLAGS", command, args).converting()
    }

    /// Returns helpful text about the different subcommands.
    ///
    /// - Documentation: [COMMAND HELP](https:/redis.io/docs/latest/commands/command-help)
    /// - Version: 5.0.0
    /// - Complexity: O(1)
    /// - Categories: @slow, @connection
    /// - Returns: [Array](https:/redis.io/docs/reference/protocol-spec#arrays): a list of sub-commands and their descriptions.
    @inlinable
    public func commandHelp() async throws -> [RESPToken] {
        try await send("COMMAND", "HELP").converting()
    }

    /// Returns information about one, multiple or all commands.
    ///
    /// - Documentation: [COMMAND INFO](https:/redis.io/docs/latest/commands/command-info)
    /// - Version: 2.8.13
    /// - Complexity: O(N) where N is the number of commands to look up
    /// - Categories: @slow, @connection
    /// - Returns: [Array](https:/redis.io/docs/reference/protocol-spec#arrays): a nested list of command details.
    @inlinable
    public func commandInfo(commandName: String? = nil) async throws -> [RESPToken] {
        try await send("COMMAND", "INFO", commandName).converting()
    }

    /// Returns information about one, multiple or all commands.
    ///
    /// - Documentation: [COMMAND INFO](https:/redis.io/docs/latest/commands/command-info)
    /// - Version: 2.8.13
    /// - Complexity: O(N) where N is the number of commands to look up
    /// - Categories: @slow, @connection
    /// - Returns: [Array](https:/redis.io/docs/reference/protocol-spec#arrays): a nested list of command details.
    @inlinable
    public func commandInfo(commandNames: [String]) async throws -> [RESPToken] {
        try await send("COMMAND", "INFO", commandNames).converting()
    }

    /// Returns a list of command names.
    ///
    /// - Documentation: [COMMAND LIST](https:/redis.io/docs/latest/commands/command-list)
    /// - Version: 7.0.0
    /// - Complexity: O(N) where N is the total number of Redis commands
    /// - Categories: @slow, @connection
    /// - Returns: [Array](https:/redis.io/docs/reference/protocol-spec#arrays): a list of command names.
    @inlinable
    public func commandList(filterby: RESPCommand.COMMANDLISTFilterby? = nil) async throws -> [RESPToken] {
        try await send("COMMAND", "LIST", RESPWithToken("FILTERBY", filterby)).converting()
    }

    /// Returns the effective values of configuration parameters.
    ///
    /// - Documentation: [CONFIG GET](https:/redis.io/docs/latest/commands/config-get)
    /// - Version: 2.0.0
    /// - Complexity: O(N) when N is the number of configuration parameters provided
    /// - Categories: @admin, @slow, @dangerous
    /// - Returns: [Map](https:/redis.io/docs/reference/protocol-spec#maps): a list of configuration parameters matching the provided arguments.
    @inlinable
    public func configGet(parameter: String) async throws -> RESPToken {
        try await send("CONFIG", "GET", parameter).converting()
    }

    /// Returns the effective values of configuration parameters.
    ///
    /// - Documentation: [CONFIG GET](https:/redis.io/docs/latest/commands/config-get)
    /// - Version: 2.0.0
    /// - Complexity: O(N) when N is the number of configuration parameters provided
    /// - Categories: @admin, @slow, @dangerous
    /// - Returns: [Map](https:/redis.io/docs/reference/protocol-spec#maps): a list of configuration parameters matching the provided arguments.
    @inlinable
    public func configGet(parameters: [String]) async throws -> RESPToken {
        try await send("CONFIG", "GET", parameters).converting()
    }

    /// Returns helpful text about the different subcommands.
    ///
    /// - Documentation: [CONFIG HELP](https:/redis.io/docs/latest/commands/config-help)
    /// - Version: 5.0.0
    /// - Complexity: O(1)
    /// - Categories: @slow
    /// - Returns: [Array](https:/redis.io/docs/reference/protocol-spec#arrays): a list of sub-commands and their descriptions.
    @inlinable
    public func configHelp() async throws -> [RESPToken] {
        try await send("CONFIG", "HELP").converting()
    }

    /// Resets the server's statistics.
    ///
    /// - Documentation: [CONFIG RESETSTAT](https:/redis.io/docs/latest/commands/config-resetstat)
    /// - Version: 2.0.0
    /// - Complexity: O(1)
    /// - Categories: @admin, @slow, @dangerous
    /// - Returns: [Simple string](https:/redis.io/docs/reference/protocol-spec#simple-strings): `OK`.
    @inlinable
    public func configResetstat() async throws {
        try await send("CONFIG", "RESETSTAT")
    }

    /// Persists the effective configuration to file.
    ///
    /// - Documentation: [CONFIG REWRITE](https:/redis.io/docs/latest/commands/config-rewrite)
    /// - Version: 2.8.0
    /// - Complexity: O(1)
    /// - Categories: @admin, @slow, @dangerous
    /// - Returns: [Simple string](https:/redis.io/docs/reference/protocol-spec#simple-strings): `OK` when the configuration was rewritten properly. Otherwise an error is returned.
    @inlinable
    public func configRewrite() async throws {
        try await send("CONFIG", "REWRITE")
    }

    /// Sets configuration parameters in-flight.
    ///
    /// - Documentation: [CONFIG SET](https:/redis.io/docs/latest/commands/config-set)
    /// - Version: 2.0.0
    /// - Complexity: O(N) when N is the number of configuration parameters provided
    /// - Categories: @admin, @slow, @dangerous
    /// - Returns: [Simple string](https:/redis.io/docs/reference/protocol-spec#simple-strings): `OK` when the configuration was set properly. Otherwise an error is returned.
    @inlinable
    public func configSet(data: RESPCommand.CONFIGSETData) async throws {
        try await send("CONFIG", "SET", data)
    }

    /// Sets configuration parameters in-flight.
    ///
    /// - Documentation: [CONFIG SET](https:/redis.io/docs/latest/commands/config-set)
    /// - Version: 2.0.0
    /// - Complexity: O(N) when N is the number of configuration parameters provided
    /// - Categories: @admin, @slow, @dangerous
    /// - Returns: [Simple string](https:/redis.io/docs/reference/protocol-spec#simple-strings): `OK` when the configuration was set properly. Otherwise an error is returned.
    @inlinable
    public func configSet(datas: [RESPCommand.CONFIGSETData]) async throws {
        try await send("CONFIG", "SET", datas)
    }

    /// Copies the value of a key to a new key.
    ///
    /// - Documentation: [COPY](https:/redis.io/docs/latest/commands/copy)
    /// - Version: 6.2.0
    /// - Complexity: O(N) worst case for collections, where N is the number of nested items. O(1) for string values.
    /// - Categories: @keyspace, @write, @slow
    /// - Returns: One of the following:
    ///     * [Integer](https:/redis.io/docs/reference/protocol-spec#integers): `1` if _source_ was copied.
    ///     * [Integer](https:/redis.io/docs/reference/protocol-spec#integers): `0` if _source_ was not copied.
    @inlinable
    public func copy(source: RedisKey, destination: RedisKey, destinationDb: Int? = nil, replace: Bool = false) async throws -> Int {
        try await send("COPY", source, destination, RESPWithToken("DB", destinationDb), RedisPureToken("REPLACE", replace)).converting()
    }

    /// Returns the number of keys in the database.
    ///
    /// - Documentation: [DBSIZE](https:/redis.io/docs/latest/commands/dbsize)
    /// - Version: 1.0.0
    /// - Complexity: O(1)
    /// - Categories: @keyspace, @read, @fast
    /// - Returns: [Integer](https:/redis.io/docs/reference/protocol-spec#integers): the number of keys in the currently-selected database.
    @inlinable
    public func dbsize() async throws -> Int {
        try await send("DBSIZE").converting()
    }

    /// Decrements the integer value of a key by one. Uses 0 as initial value if the key doesn't exist.
    ///
    /// - Documentation: [DECR](https:/redis.io/docs/latest/commands/decr)
    /// - Version: 1.0.0
    /// - Complexity: O(1)
    /// - Categories: @write, @string, @fast
    /// - Returns: [Integer](https:/redis.io/docs/reference/protocol-spec#integers): the value of the key after decrementing it.
    @inlinable
    public func decr(key: RedisKey) async throws -> Int {
        try await send("DECR", key).converting()
    }

    /// Decrements a number from the integer value of a key. Uses 0 as initial value if the key doesn't exist.
    ///
    /// - Documentation: [DECRBY](https:/redis.io/docs/latest/commands/decrby)
    /// - Version: 1.0.0
    /// - Complexity: O(1)
    /// - Categories: @write, @string, @fast
    /// - Returns: [Integer](https:/redis.io/docs/reference/protocol-spec#integers): the value of the key after decrementing it.
    @inlinable
    public func decrby(key: RedisKey, decrement: Int) async throws -> Int {
        try await send("DECRBY", key, decrement).converting()
    }

    /// Deletes one or more keys.
    ///
    /// - Documentation: [DEL](https:/redis.io/docs/latest/commands/del)
    /// - Version: 1.0.0
    /// - Complexity: O(N) where N is the number of keys that will be removed. When a key to remove holds a value other than a string, the individual complexity for this key is O(M) where M is the number of elements in the list, set, sorted set or hash. Removing a single key that holds a string value is O(1).
    /// - Categories: @keyspace, @write, @slow
    /// - Returns: [Integer](https:/redis.io/docs/reference/protocol-spec#integers): the number of keys that were removed.
    @inlinable
    public func del(key: RedisKey) async throws -> Int {
        try await send("DEL", key).converting()
    }

    /// Deletes one or more keys.
    ///
    /// - Documentation: [DEL](https:/redis.io/docs/latest/commands/del)
    /// - Version: 1.0.0
    /// - Complexity: O(N) where N is the number of keys that will be removed. When a key to remove holds a value other than a string, the individual complexity for this key is O(M) where M is the number of elements in the list, set, sorted set or hash. Removing a single key that holds a string value is O(1).
    /// - Categories: @keyspace, @write, @slow
    /// - Returns: [Integer](https:/redis.io/docs/reference/protocol-spec#integers): the number of keys that were removed.
    @inlinable
    public func del(keys: [RedisKey]) async throws -> Int {
        try await send("DEL", keys).converting()
    }

    /// Discards a transaction.
    ///
    /// - Documentation: [DISCARD](https:/redis.io/docs/latest/commands/discard)
    /// - Version: 2.0.0
    /// - Complexity: O(N), when N is the number of queued commands
    /// - Categories: @fast, @transaction
    /// - Returns: [Simple string](https:/redis.io/docs/reference/protocol-spec#simple-strings): `OK`.
    @inlinable
    public func discard() async throws {
        try await send("DISCARD")
    }

    /// Returns a serialized representation of the value stored at a key.
    ///
    /// - Documentation: [DUMP](https:/redis.io/docs/latest/commands/dump)
    /// - Version: 2.6.0
    /// - Complexity: O(1) to access the key and additional O(N*M) to serialize it, where N is the number of Redis objects composing the value and M their average size. For small string values the time complexity is thus O(1)+O(1*M) where M is small, so simply O(1).
    /// - Categories: @keyspace, @read, @slow
    /// - Returns: One of the following:
    ///     * [Bulk string](https:/redis.io/docs/reference/protocol-spec#bulk-strings): the serialized value of the key.
    ///     * [Null](https:/redis.io/docs/reference/protocol-spec#nulls): the key does not exist.
    @inlinable
    public func dump(key: RedisKey) async throws -> String? {
        try await send("DUMP", key).converting()
    }

    /// Returns the given string.
    ///
    /// - Documentation: [ECHO](https:/redis.io/docs/latest/commands/echo)
    /// - Version: 1.0.0
    /// - Complexity: O(1)
    /// - Categories: @fast, @connection
    /// - Returns: [Bulk string](https:/redis.io/docs/reference/protocol-spec#bulk-strings): the given string.
    @inlinable
    public func echo(message: String) async throws -> String {
        try await send("ECHO", message).converting()
    }

    /// Executes a server-side Lua script.
    ///
    /// - Documentation: [EVAL](https:/redis.io/docs/latest/commands/eval)
    /// - Version: 2.6.0
    /// - Complexity: Depends on the script that is executed.
    /// - Categories: @slow, @scripting
    /// - Returns: The return value depends on the script that was executed.
    @inlinable
    public func eval(script: String, key: RedisKey? = nil, arg: String? = nil) async throws -> RESPToken {
        try await send("EVAL", script, 1, key, arg)
    }

    /// Executes a server-side Lua script.
    ///
    /// - Documentation: [EVAL](https:/redis.io/docs/latest/commands/eval)
    /// - Version: 2.6.0
    /// - Complexity: Depends on the script that is executed.
    /// - Categories: @slow, @scripting
    /// - Returns: The return value depends on the script that was executed.
    @inlinable
    public func eval(script: String, keys: [RedisKey], args: [String]) async throws -> RESPToken {
        try await send("EVAL", script, RESPArrayWithCount(keys), args)
    }

    /// Executes a server-side Lua script by SHA1 digest.
    ///
    /// - Documentation: [EVALSHA](https:/redis.io/docs/latest/commands/evalsha)
    /// - Version: 2.6.0
    /// - Complexity: Depends on the script that is executed.
    /// - Categories: @slow, @scripting
    /// - Returns: The return value depends on the script that was executed.
    @inlinable
    public func evalsha(sha1: String, key: RedisKey? = nil, arg: String? = nil) async throws -> RESPToken {
        try await send("EVALSHA", sha1, 1, key, arg)
    }

    /// Executes a server-side Lua script by SHA1 digest.
    ///
    /// - Documentation: [EVALSHA](https:/redis.io/docs/latest/commands/evalsha)
    /// - Version: 2.6.0
    /// - Complexity: Depends on the script that is executed.
    /// - Categories: @slow, @scripting
    /// - Returns: The return value depends on the script that was executed.
    @inlinable
    public func evalsha(sha1: String, keys: [RedisKey], args: [String]) async throws -> RESPToken {
        try await send("EVALSHA", sha1, RESPArrayWithCount(keys), args)
    }

    /// Executes a read-only server-side Lua script by SHA1 digest.
    ///
    /// - Documentation: [EVALSHA_RO](https:/redis.io/docs/latest/commands/evalsha_ro)
    /// - Version: 7.0.0
    /// - Complexity: Depends on the script that is executed.
    /// - Categories: @slow, @scripting
    /// - Returns: The return value depends on the script that was executed.
    @inlinable
    public func evalshaRo(sha1: String, key: RedisKey? = nil, arg: String? = nil) async throws -> RESPToken {
        try await send("EVALSHA_RO", sha1, 1, key, arg)
    }

    /// Executes a read-only server-side Lua script by SHA1 digest.
    ///
    /// - Documentation: [EVALSHA_RO](https:/redis.io/docs/latest/commands/evalsha_ro)
    /// - Version: 7.0.0
    /// - Complexity: Depends on the script that is executed.
    /// - Categories: @slow, @scripting
    /// - Returns: The return value depends on the script that was executed.
    @inlinable
    public func evalshaRo(sha1: String, keys: [RedisKey], args: [String]) async throws -> RESPToken {
        try await send("EVALSHA_RO", sha1, RESPArrayWithCount(keys), args)
    }

    /// Executes a read-only server-side Lua script.
    ///
    /// - Documentation: [EVAL_RO](https:/redis.io/docs/latest/commands/eval_ro)
    /// - Version: 7.0.0
    /// - Complexity: Depends on the script that is executed.
    /// - Categories: @slow, @scripting
    /// - Returns: The return value depends on the script that was executed.
    @inlinable
    public func evalRo(script: String, key: RedisKey? = nil, arg: String? = nil) async throws -> RESPToken {
        try await send("EVAL_RO", script, 1, key, arg)
    }

    /// Executes a read-only server-side Lua script.
    ///
    /// - Documentation: [EVAL_RO](https:/redis.io/docs/latest/commands/eval_ro)
    /// - Version: 7.0.0
    /// - Complexity: Depends on the script that is executed.
    /// - Categories: @slow, @scripting
    /// - Returns: The return value depends on the script that was executed.
    @inlinable
    public func evalRo(script: String, keys: [RedisKey], args: [String]) async throws -> RESPToken {
        try await send("EVAL_RO", script, RESPArrayWithCount(keys), args)
    }

    /// Executes all commands in a transaction.
    ///
    /// - Documentation: [EXEC](https:/redis.io/docs/latest/commands/exec)
    /// - Version: 1.2.0
    /// - Complexity: Depends on commands in the transaction
    /// - Categories: @slow, @transaction
    /// - Returns: One of the following:
    ///     * [Array](https:/redis.io/docs/reference/protocol-spec#arrays): each element being the reply to each of the commands in the atomic transaction.
    ///     * [Null](https:/redis.io/docs/reference/protocol-spec#nulls): the transaction was aborted because a `WATCH`ed key was touched.
    @inlinable
    public func exec() async throws -> [RESPToken]? {
        try await send("EXEC").converting()
    }

    /// Determines whether one or more keys exist.
    ///
    /// - Documentation: [EXISTS](https:/redis.io/docs/latest/commands/exists)
    /// - Version: 1.0.0
    /// - Complexity: O(N) where N is the number of keys to check.
    /// - Categories: @keyspace, @read, @fast
    /// - Returns: [Integer](https:/redis.io/docs/reference/protocol-spec#integers): the number of keys that exist from those specified as arguments.
    @inlinable
    public func exists(key: RedisKey) async throws -> Int {
        try await send("EXISTS", key).converting()
    }

    /// Determines whether one or more keys exist.
    ///
    /// - Documentation: [EXISTS](https:/redis.io/docs/latest/commands/exists)
    /// - Version: 1.0.0
    /// - Complexity: O(N) where N is the number of keys to check.
    /// - Categories: @keyspace, @read, @fast
    /// - Returns: [Integer](https:/redis.io/docs/reference/protocol-spec#integers): the number of keys that exist from those specified as arguments.
    @inlinable
    public func exists(keys: [RedisKey]) async throws -> Int {
        try await send("EXISTS", keys).converting()
    }

    /// Sets the expiration time of a key in seconds.
    ///
    /// - Documentation: [EXPIRE](https:/redis.io/docs/latest/commands/expire)
    /// - Version: 1.0.0
    /// - Complexity: O(1)
    /// - Categories: @keyspace, @write, @fast
    /// - Returns: One of the following:
    ///     * [Integer](https:/redis.io/docs/reference/protocol-spec#integers): `0` if the timeout was not set; for example, the key doesn't exist, or the operation was skipped because of the provided arguments.
    ///     * [Integer](https:/redis.io/docs/reference/protocol-spec#integers): `1` if the timeout was set.
    @inlinable
    public func expire(key: RedisKey, seconds: Int, condition: RESPCommand.EXPIRECondition? = nil) async throws -> Int {
        try await send("EXPIRE", key, seconds, condition).converting()
    }

    /// Sets the expiration time of a key to a Unix timestamp.
    ///
    /// - Documentation: [EXPIREAT](https:/redis.io/docs/latest/commands/expireat)
    /// - Version: 1.2.0
    /// - Complexity: O(1)
    /// - Categories: @keyspace, @write, @fast
    /// - Returns: One of the following:
    ///     * [Integer](https:/redis.io/docs/reference/protocol-spec#integers): `0` if the timeout was not set; for example, the key doesn't exist, or the operation was skipped because of the provided arguments.
    ///     * [Integer](https:/redis.io/docs/reference/protocol-spec#integers): `1` if the timeout was set.
    @inlinable
    public func expireat(key: RedisKey, unixTimeSeconds: Date, condition: RESPCommand.EXPIREATCondition? = nil) async throws -> Int {
        try await send("EXPIREAT", key, unixTimeSeconds, condition).converting()
    }

    /// Returns the expiration time of a key as a Unix timestamp.
    ///
    /// - Documentation: [EXPIRETIME](https:/redis.io/docs/latest/commands/expiretime)
    /// - Version: 7.0.0
    /// - Complexity: O(1)
    /// - Categories: @keyspace, @read, @fast
    /// - Returns: One of the following:
    ///     * [Integer](https:/redis.io/docs/reference/protocol-spec#integers): the expiration Unix timestamp in seconds.
    ///     * [Integer](https:/redis.io/docs/reference/protocol-spec#integers): `-1` if the key exists but has no associated expiration time.
    ///     * [Integer](https:/redis.io/docs/reference/protocol-spec#integers): `-2` if the key does not exist.
    @inlinable
    public func expiretime(key: RedisKey) async throws -> Int {
        try await send("EXPIRETIME", key).converting()
    }

    /// Starts a coordinated failover from a server to one of its replicas.
    ///
    /// - Documentation: [FAILOVER](https:/redis.io/docs/latest/commands/failover)
    /// - Version: 6.2.0
    /// - Complexity: O(1)
    /// - Categories: @admin, @slow, @dangerous
    /// - Returns: [Simple string](https:/redis.io/docs/reference/protocol-spec#simple-strings): `OK` if the command was accepted and a coordinated failover is in progress. An error if the operation cannot be executed.
    @inlinable
    public func failover(target: RESPCommand.FAILOVERTarget? = nil, abort: Bool = false, milliseconds: Int? = nil) async throws {
        try await send("FAILOVER", RESPWithToken("TO", target), RedisPureToken("ABORT", abort), RESPWithToken("TIMEOUT", milliseconds))
    }

    /// Invokes a function.
    ///
    /// - Documentation: [FCALL](https:/redis.io/docs/latest/commands/fcall)
    /// - Version: 7.0.0
    /// - Complexity: Depends on the function that is executed.
    /// - Categories: @slow, @scripting
    /// - Returns: The return value depends on the function that was executed.
    @inlinable
    public func fcall(function: String, key: RedisKey? = nil, arg: String? = nil) async throws -> RESPToken {
        try await send("FCALL", function, 1, key, arg)
    }

    /// Invokes a function.
    ///
    /// - Documentation: [FCALL](https:/redis.io/docs/latest/commands/fcall)
    /// - Version: 7.0.0
    /// - Complexity: Depends on the function that is executed.
    /// - Categories: @slow, @scripting
    /// - Returns: The return value depends on the function that was executed.
    @inlinable
    public func fcall(function: String, keys: [RedisKey], args: [String]) async throws -> RESPToken {
        try await send("FCALL", function, RESPArrayWithCount(keys), args)
    }

    /// Invokes a read-only function.
    ///
    /// - Documentation: [FCALL_RO](https:/redis.io/docs/latest/commands/fcall_ro)
    /// - Version: 7.0.0
    /// - Complexity: Depends on the function that is executed.
    /// - Categories: @slow, @scripting
    /// - Returns: The return value depends on the function that was executed.
    @inlinable
    public func fcallRo(function: String, key: RedisKey? = nil, arg: String? = nil) async throws -> RESPToken {
        try await send("FCALL_RO", function, 1, key, arg)
    }

    /// Invokes a read-only function.
    ///
    /// - Documentation: [FCALL_RO](https:/redis.io/docs/latest/commands/fcall_ro)
    /// - Version: 7.0.0
    /// - Complexity: Depends on the function that is executed.
    /// - Categories: @slow, @scripting
    /// - Returns: The return value depends on the function that was executed.
    @inlinable
    public func fcallRo(function: String, keys: [RedisKey], args: [String]) async throws -> RESPToken {
        try await send("FCALL_RO", function, RESPArrayWithCount(keys), args)
    }

    /// Removes all keys from all databases.
    ///
    /// - Documentation: [FLUSHALL](https:/redis.io/docs/latest/commands/flushall)
    /// - Version: 1.0.0
    /// - Complexity: O(N) where N is the total number of keys in all databases
    /// - Categories: @keyspace, @write, @slow, @dangerous
    /// - Returns: [Simple string](https:/redis.io/docs/reference/protocol-spec#simple-strings): `OK`.
    @inlinable
    public func flushall(flushType: RESPCommand.FLUSHALLFlushType? = nil) async throws {
        try await send("FLUSHALL", flushType)
    }

    /// Remove all keys from the current database.
    ///
    /// - Documentation: [FLUSHDB](https:/redis.io/docs/latest/commands/flushdb)
    /// - Version: 1.0.0
    /// - Complexity: O(N) where N is the number of keys in the selected database
    /// - Categories: @keyspace, @write, @slow, @dangerous
    /// - Returns: [Simple string](https:/redis.io/docs/reference/protocol-spec#simple-strings): `OK`.
    @inlinable
    public func flushdb(flushType: RESPCommand.FLUSHDBFlushType? = nil) async throws {
        try await send("FLUSHDB", flushType)
    }

    /// Deletes a library and its functions.
    ///
    /// - Documentation: [FUNCTION DELETE](https:/redis.io/docs/latest/commands/function-delete)
    /// - Version: 7.0.0
    /// - Complexity: O(1)
    /// - Categories: @write, @slow, @scripting
    /// - Returns: [Simple string](https:/redis.io/docs/reference/protocol-spec#simple-strings): `OK`.
    @inlinable
    public func functionDelete(libraryName: String) async throws {
        try await send("FUNCTION", "DELETE", libraryName)
    }

    /// Dumps all libraries into a serialized binary payload.
    ///
    /// - Documentation: [FUNCTION DUMP](https:/redis.io/docs/latest/commands/function-dump)
    /// - Version: 7.0.0
    /// - Complexity: O(N) where N is the number of functions
    /// - Categories: @slow, @scripting
    /// - Returns: [Bulk string](https:/redis.io/docs/reference/protocol-spec#bulk-strings): the serialized payload
    @inlinable
    public func functionDump() async throws -> String {
        try await send("FUNCTION", "DUMP").converting()
    }

    /// Deletes all libraries and functions.
    ///
    /// - Documentation: [FUNCTION FLUSH](https:/redis.io/docs/latest/commands/function-flush)
    /// - Version: 7.0.0
    /// - Complexity: O(N) where N is the number of functions deleted
    /// - Categories: @write, @slow, @scripting
    /// - Returns: [Simple string](https:/redis.io/docs/reference/protocol-spec#simple-strings): `OK`.
    @inlinable
    public func functionFlush(flushType: RESPCommand.FUNCTIONFLUSHFlushType? = nil) async throws {
        try await send("FUNCTION", "FLUSH", flushType)
    }

    /// Returns helpful text about the different subcommands.
    ///
    /// - Documentation: [FUNCTION HELP](https:/redis.io/docs/latest/commands/function-help)
    /// - Version: 7.0.0
    /// - Complexity: O(1)
    /// - Categories: @slow, @scripting
    /// - Returns: [Array](https:/redis.io/docs/reference/protocol-spec#arrays): a list of sub-commands and their descriptions.
    @inlinable
    public func functionHelp() async throws -> [RESPToken] {
        try await send("FUNCTION", "HELP").converting()
    }

    /// Terminates a function during execution.
    ///
    /// - Documentation: [FUNCTION KILL](https:/redis.io/docs/latest/commands/function-kill)
    /// - Version: 7.0.0
    /// - Complexity: O(1)
    /// - Categories: @slow, @scripting
    /// - Returns: [Simple string](https:/redis.io/docs/reference/protocol-spec#simple-strings): `OK`.
    @inlinable
    public func functionKill() async throws {
        try await send("FUNCTION", "KILL")
    }

    /// Returns information about all libraries.
    ///
    /// - Documentation: [FUNCTION LIST](https:/redis.io/docs/latest/commands/function-list)
    /// - Version: 7.0.0
    /// - Complexity: O(N) where N is the number of functions
    /// - Categories: @slow, @scripting
    /// - Returns: [Array](https:/redis.io/docs/reference/protocol-spec#arrays): information about functions and libraries.
    @inlinable
    public func functionList(libraryNamePattern: String? = nil, withcode: Bool = false) async throws -> [RESPToken] {
        try await send("FUNCTION", "LIST", RESPWithToken("LIBRARYNAME", libraryNamePattern), RedisPureToken("WITHCODE", withcode)).converting()
    }

    /// Creates a library.
    ///
    /// - Documentation: [FUNCTION LOAD](https:/redis.io/docs/latest/commands/function-load)
    /// - Version: 7.0.0
    /// - Complexity: O(1) (considering compilation time is redundant)
    /// - Categories: @write, @slow, @scripting
    /// - Returns: [Bulk string](https:/redis.io/docs/reference/protocol-spec#bulk-strings): the library name that was loaded.
    @inlinable
    public func functionLoad(replace: Bool = false, functionCode: String) async throws -> String {
        try await send("FUNCTION", "LOAD", RedisPureToken("REPLACE", replace), functionCode).converting()
    }

    /// Restores all libraries from a payload.
    ///
    /// - Documentation: [FUNCTION RESTORE](https:/redis.io/docs/latest/commands/function-restore)
    /// - Version: 7.0.0
    /// - Complexity: O(N) where N is the number of functions on the payload
    /// - Categories: @write, @slow, @scripting
    /// - Returns: [Simple string](https:/redis.io/docs/reference/protocol-spec#simple-strings): `OK`.
    @inlinable
    public func functionRestore(serializedValue: String, policy: RESPCommand.FUNCTIONRESTOREPolicy? = nil) async throws {
        try await send("FUNCTION", "RESTORE", serializedValue, policy)
    }

    /// Returns information about a function during execution.
    ///
    /// - Documentation: [FUNCTION STATS](https:/redis.io/docs/latest/commands/function-stats)
    /// - Version: 7.0.0
    /// - Complexity: O(1)
    /// - Categories: @slow, @scripting
    /// - Returns: [Map](https:/redis.io/docs/reference/protocol-spec#maps): information about the function that's currently running and information about the available execution engines.
    @inlinable
    public func functionStats() async throws -> RESPToken {
        try await send("FUNCTION", "STATS").converting()
    }

    /// Adds one or more members to a geospatial index. The key is created if it doesn't exist.
    ///
    /// - Documentation: [GEOADD](https:/redis.io/docs/latest/commands/geoadd)
    /// - Version: 3.2.0
    /// - Complexity: O(log(N)) for each item added, where N is the number of elements in the sorted set.
    /// - Categories: @write, @geo, @slow
    /// - Returns: [Integer](https:/redis.io/docs/reference/protocol-spec#integers): When used without optional arguments, the number of elements added to the sorted set (excluding score updates).  If the CH option is specified, the number of elements that were changed (added or updated).
    @inlinable
    public func geoadd(key: RedisKey, condition: RESPCommand.GEOADDCondition? = nil, change: Bool = false, data: RESPCommand.GEOADDData) async throws -> Int {
        try await send("GEOADD", key, condition, RedisPureToken("CH", change), data).converting()
    }

    /// Adds one or more members to a geospatial index. The key is created if it doesn't exist.
    ///
    /// - Documentation: [GEOADD](https:/redis.io/docs/latest/commands/geoadd)
    /// - Version: 3.2.0
    /// - Complexity: O(log(N)) for each item added, where N is the number of elements in the sorted set.
    /// - Categories: @write, @geo, @slow
    /// - Returns: [Integer](https:/redis.io/docs/reference/protocol-spec#integers): When used without optional arguments, the number of elements added to the sorted set (excluding score updates).  If the CH option is specified, the number of elements that were changed (added or updated).
    @inlinable
    public func geoadd(key: RedisKey, condition: RESPCommand.GEOADDCondition? = nil, change: Bool = false, datas: [RESPCommand.GEOADDData]) async throws -> Int {
        try await send("GEOADD", key, condition, RedisPureToken("CH", change), datas).converting()
    }

    /// Returns the distance between two members of a geospatial index.
    ///
    /// - Documentation: [GEODIST](https:/redis.io/docs/latest/commands/geodist)
    /// - Version: 3.2.0
    /// - Complexity: O(1)
    /// - Categories: @read, @geo, @slow
    /// - Returns: One of the following:
    ///     * [Null](https:/redis.io/docs/reference/protocol-spec#nulls): one or both of the elements are missing.
    ///     * [Bulk string](https:/redis.io/docs/reference/protocol-spec#bulk-strings): distance as a double (represented as a string) in the specified units.
    @inlinable
    public func geodist(key: RedisKey, member1: String, member2: String, unit: RESPCommand.GEODISTUnit? = nil) async throws -> String? {
        try await send("GEODIST", key, member1, member2, unit).converting()
    }

    /// Returns members from a geospatial index as geohash strings.
    ///
    /// - Documentation: [GEOHASH](https:/redis.io/docs/latest/commands/geohash)
    /// - Version: 3.2.0
    /// - Complexity: O(1) for each member requested.
    /// - Categories: @read, @geo, @slow
    /// - Returns: [Array](https:/redis.io/docs/reference/protocol-spec#arrays): An array where each element is the Geohash corresponding to each member name passed as an argument to the command.
    @inlinable
    public func geohash(key: RedisKey, member: String? = nil) async throws -> [RESPToken] {
        try await send("GEOHASH", key, member).converting()
    }

    /// Returns members from a geospatial index as geohash strings.
    ///
    /// - Documentation: [GEOHASH](https:/redis.io/docs/latest/commands/geohash)
    /// - Version: 3.2.0
    /// - Complexity: O(1) for each member requested.
    /// - Categories: @read, @geo, @slow
    /// - Returns: [Array](https:/redis.io/docs/reference/protocol-spec#arrays): An array where each element is the Geohash corresponding to each member name passed as an argument to the command.
    @inlinable
    public func geohash(key: RedisKey, members: [String]) async throws -> [RESPToken] {
        try await send("GEOHASH", key, members).converting()
    }

    /// Returns the longitude and latitude of members from a geospatial index.
    ///
    /// - Documentation: [GEOPOS](https:/redis.io/docs/latest/commands/geopos)
    /// - Version: 3.2.0
    /// - Complexity: O(1) for each member requested.
    /// - Categories: @read, @geo, @slow
    /// - Returns: [Array](https:/redis.io/docs/reference/protocol-spec#arrays): An array where each element is a two elements array representing longitude and latitude (x,y) of each member name passed as argument to the command. Non-existing elements are reported as [Null](https:/redis.io/docs/reference/protocol-spec#nulls) elements of the array.
    @inlinable
    public func geopos(key: RedisKey, member: String? = nil) async throws -> [RESPToken] {
        try await send("GEOPOS", key, member).converting()
    }

    /// Returns the longitude and latitude of members from a geospatial index.
    ///
    /// - Documentation: [GEOPOS](https:/redis.io/docs/latest/commands/geopos)
    /// - Version: 3.2.0
    /// - Complexity: O(1) for each member requested.
    /// - Categories: @read, @geo, @slow
    /// - Returns: [Array](https:/redis.io/docs/reference/protocol-spec#arrays): An array where each element is a two elements array representing longitude and latitude (x,y) of each member name passed as argument to the command. Non-existing elements are reported as [Null](https:/redis.io/docs/reference/protocol-spec#nulls) elements of the array.
    @inlinable
    public func geopos(key: RedisKey, members: [String]) async throws -> [RESPToken] {
        try await send("GEOPOS", key, members).converting()
    }

    /// Queries a geospatial index for members within a distance from a coordinate, optionally stores the result.
    ///
    /// - Documentation: [GEORADIUS](https:/redis.io/docs/latest/commands/georadius)
    /// - Version: 3.2.0
    /// - Complexity: O(N+log(M)) where N is the number of elements inside the bounding box of the circular area delimited by center and radius and M is the number of items inside the index.
    /// - Categories: @write, @geo, @slow
    /// - Returns: One of the following:
    ///     * If no `WITH*` option is specified, an [Array](https:/redis.io/docs/reference/protocol-spec#arrays) of matched member names
    ///     * If `WITHCOORD`, `WITHDIST`, or `WITHHASH` options are specified, the command returns an [Array](https:/redis.io/docs/reference/protocol-spec#arrays) of arrays, where each sub-array represents a single item:
    ///         1. The distance from the center as a floating point number, in the same unit specified in the radius.
    ///         1. The Geohash integer.
    ///         1. The coordinates as a two items x,y array (longitude,latitude).
    ///     
    ///     For example, the command `GEORADIUS Sicily 15 37 200 km WITHCOORD WITHDIST` will return each item in the following way:
    ///     
    ///     `["Palermo","190.4424",["13.361389338970184","38.115556395496299"]]`
    @inlinable
    public func georadius(key: RedisKey, longitude: Double, latitude: Double, radius: Double, unit: RESPCommand.GEORADIUSUnit, withcoord: Bool = false, withdist: Bool = false, withhash: Bool = false, countBlock: RESPCommand.GEORADIUSCountBlock? = nil, order: RESPCommand.GEORADIUSOrder? = nil, store: RESPCommand.GEORADIUSStore? = nil) async throws -> RESPToken {
        try await send("GEORADIUS", key, longitude, latitude, radius, unit, RedisPureToken("WITHCOORD", withcoord), RedisPureToken("WITHDIST", withdist), RedisPureToken("WITHHASH", withhash), countBlock, order, store)
    }

    /// Queries a geospatial index for members within a distance from a member, optionally stores the result.
    ///
    /// - Documentation: [GEORADIUSBYMEMBER](https:/redis.io/docs/latest/commands/georadiusbymember)
    /// - Version: 3.2.0
    /// - Complexity: O(N+log(M)) where N is the number of elements inside the bounding box of the circular area delimited by center and radius and M is the number of items inside the index.
    /// - Categories: @write, @geo, @slow
    /// - Returns: One of the following:
    ///     * If no `WITH*` option is specified, an [Array](https:/redis.io/docs/reference/protocol-spec#arrays) of matched member names
    ///     * If `WITHCOORD`, `WITHDIST`, or `WITHHASH` options are specified, the command returns an [Array](https:/redis.io/docs/reference/protocol-spec#arrays) of arrays, where each sub-array represents a single item:
    ///         * The distance from the center as a floating point number, in the same unit specified in the radius.
    ///         * The Geohash integer.
    ///         * The coordinates as a two items x,y array (longitude,latitude).
    @inlinable
    public func georadiusbymember(key: RedisKey, member: String, radius: Double, unit: RESPCommand.GEORADIUSBYMEMBERUnit, withcoord: Bool = false, withdist: Bool = false, withhash: Bool = false, countBlock: RESPCommand.GEORADIUSBYMEMBERCountBlock? = nil, order: RESPCommand.GEORADIUSBYMEMBEROrder? = nil, store: RESPCommand.GEORADIUSBYMEMBERStore? = nil) async throws -> RESPToken {
        try await send("GEORADIUSBYMEMBER", key, member, radius, unit, RedisPureToken("WITHCOORD", withcoord), RedisPureToken("WITHDIST", withdist), RedisPureToken("WITHHASH", withhash), countBlock, order, store)
    }

    /// Returns members from a geospatial index that are within a distance from a member.
    ///
    /// - Documentation: [GEORADIUSBYMEMBER_RO](https:/redis.io/docs/latest/commands/georadiusbymember_ro)
    /// - Version: 3.2.10
    /// - Complexity: O(N+log(M)) where N is the number of elements inside the bounding box of the circular area delimited by center and radius and M is the number of items inside the index.
    /// - Categories: @read, @geo, @slow
    /// - Returns: One of the following:
    ///     * If no `WITH*` option is specified, an [Array](https:/redis.io/docs/reference/protocol-spec#arrays) of matched member names
    ///     * If `WITHCOORD`, `WITHDIST`, or `WITHHASH` options are specified, the command returns an [Array](https:/redis.io/docs/reference/protocol-spec#arrays) of arrays, where each sub-array represents a single item:
    ///         * The distance from the center as a floating point number, in the same unit specified in the radius.
    ///         * The Geohash integer.
    ///         * The coordinates as a two items x,y array (longitude,latitude).
    @inlinable
    public func georadiusbymemberRo(key: RedisKey, member: String, radius: Double, unit: RESPCommand.GEORADIUSBYMEMBERROUnit, withcoord: Bool = false, withdist: Bool = false, withhash: Bool = false, countBlock: RESPCommand.GEORADIUSBYMEMBERROCountBlock? = nil, order: RESPCommand.GEORADIUSBYMEMBERROOrder? = nil) async throws -> RESPToken {
        try await send("GEORADIUSBYMEMBER_RO", key, member, radius, unit, RedisPureToken("WITHCOORD", withcoord), RedisPureToken("WITHDIST", withdist), RedisPureToken("WITHHASH", withhash), countBlock, order)
    }

    /// Returns members from a geospatial index that are within a distance from a coordinate.
    ///
    /// - Documentation: [GEORADIUS_RO](https:/redis.io/docs/latest/commands/georadius_ro)
    /// - Version: 3.2.10
    /// - Complexity: O(N+log(M)) where N is the number of elements inside the bounding box of the circular area delimited by center and radius and M is the number of items inside the index.
    /// - Categories: @read, @geo, @slow
    /// - Returns: One of the following:
    ///     * If no `WITH*` option is specified, an [Array](https:/redis.io/docs/reference/protocol-spec#arrays) of matched member names
    ///     * If `WITHCOORD`, `WITHDIST`, or `WITHHASH` options are specified, the command returns an [Array](https:/redis.io/docs/reference/protocol-spec#arrays) of arrays, where each sub-array represents a single item:
    ///         * The distance from the center as a floating point number, in the same unit specified in the radius.
    ///         * The Geohash integer.
    ///         * The coordinates as a two items x,y array (longitude,latitude).
    @inlinable
    public func georadiusRo(key: RedisKey, longitude: Double, latitude: Double, radius: Double, unit: RESPCommand.GEORADIUSROUnit, withcoord: Bool = false, withdist: Bool = false, withhash: Bool = false, countBlock: RESPCommand.GEORADIUSROCountBlock? = nil, order: RESPCommand.GEORADIUSROOrder? = nil) async throws -> RESPToken {
        try await send("GEORADIUS_RO", key, longitude, latitude, radius, unit, RedisPureToken("WITHCOORD", withcoord), RedisPureToken("WITHDIST", withdist), RedisPureToken("WITHHASH", withhash), countBlock, order)
    }

    /// Queries a geospatial index for members inside an area of a box or a circle.
    ///
    /// - Documentation: [GEOSEARCH](https:/redis.io/docs/latest/commands/geosearch)
    /// - Version: 6.2.0
    /// - Complexity: O(N+log(M)) where N is the number of elements in the grid-aligned bounding box area around the shape provided as the filter and M is the number of items inside the shape
    /// - Categories: @read, @geo, @slow
    /// - Returns: One of the following:
    ///     * If no `WITH*` option is specified, an [Array](https:/redis.io/docs/reference/protocol-spec#arrays) of matched member names
    ///     * If `WITHCOORD`, `WITHDIST`, or `WITHHASH` options are specified, the command returns an [Array](https:/redis.io/docs/reference/protocol-spec#arrays) of arrays, where each sub-array represents a single item:
    ///         * The distance from the center as a floating point number, in the same unit specified in the radius.
    ///         * The Geohash integer.
    ///         * The coordinates as a two items x,y array (longitude,latitude).
    @inlinable
    public func geosearch(key: RedisKey, from: RESPCommand.GEOSEARCHFrom, by: RESPCommand.GEOSEARCHBy, order: RESPCommand.GEOSEARCHOrder? = nil, countBlock: RESPCommand.GEOSEARCHCountBlock? = nil, withcoord: Bool = false, withdist: Bool = false, withhash: Bool = false) async throws -> RESPToken {
        try await send("GEOSEARCH", key, from, by, order, countBlock, RedisPureToken("WITHCOORD", withcoord), RedisPureToken("WITHDIST", withdist), RedisPureToken("WITHHASH", withhash))
    }

    /// Queries a geospatial index for members inside an area of a box or a circle, optionally stores the result.
    ///
    /// - Documentation: [GEOSEARCHSTORE](https:/redis.io/docs/latest/commands/geosearchstore)
    /// - Version: 6.2.0
    /// - Complexity: O(N+log(M)) where N is the number of elements in the grid-aligned bounding box area around the shape provided as the filter and M is the number of items inside the shape
    /// - Categories: @write, @geo, @slow
    /// - Returns: [Integer](https:/redis.io/docs/reference/protocol-spec#integers): the number of elements in the resulting set
    @inlinable
    public func geosearchstore(destination: RedisKey, source: RedisKey, from: RESPCommand.GEOSEARCHSTOREFrom, by: RESPCommand.GEOSEARCHSTOREBy, order: RESPCommand.GEOSEARCHSTOREOrder? = nil, countBlock: RESPCommand.GEOSEARCHSTORECountBlock? = nil, storedist: Bool = false) async throws -> Int {
        try await send("GEOSEARCHSTORE", destination, source, from, by, order, countBlock, RedisPureToken("STOREDIST", storedist)).converting()
    }

    /// Returns the string value of a key.
    ///
    /// - Documentation: [GET](https:/redis.io/docs/latest/commands/get)
    /// - Version: 1.0.0
    /// - Complexity: O(1)
    /// - Categories: @read, @string, @fast
    /// - Returns: One of the following:
    ///     * [Bulk string](https:/redis.io/docs/reference/protocol-spec#bulk-strings): the value of the key.
    ///     * [Null](https:/redis.io/docs/reference/protocol-spec#nulls): key does not exist.
    @inlinable
    public func get(key: RedisKey) async throws -> String? {
        try await send("GET", key).converting()
    }

    /// Returns a bit value by offset.
    ///
    /// - Documentation: [GETBIT](https:/redis.io/docs/latest/commands/getbit)
    /// - Version: 2.2.0
    /// - Complexity: O(1)
    /// - Categories: @read, @bitmap, @fast
    /// - Returns: The bit value stored at _offset_, one of the following:
    ///     * [Integer](https:/redis.io/docs/reference/protocol-spec#integers): `0`.
    ///     * [Integer](https:/redis.io/docs/reference/protocol-spec#integers): `1`.
    @inlinable
    public func getbit(key: RedisKey, offset: Int) async throws -> Int {
        try await send("GETBIT", key, offset).converting()
    }

    /// Returns the string value of a key after deleting the key.
    ///
    /// - Documentation: [GETDEL](https:/redis.io/docs/latest/commands/getdel)
    /// - Version: 6.2.0
    /// - Complexity: O(1)
    /// - Categories: @write, @string, @fast
    /// - Returns: One of the following:
    ///     * [Bulk string](https:/redis.io/docs/reference/protocol-spec#bulk-strings): the value of the key.
    ///     * [Null](https:/redis.io/docs/reference/protocol-spec#nulls): if the key does not exist or if the key's value type is not a string.
    @inlinable
    public func getdel(key: RedisKey) async throws -> String? {
        try await send("GETDEL", key).converting()
    }

    /// Returns the string value of a key after setting its expiration time.
    ///
    /// - Documentation: [GETEX](https:/redis.io/docs/latest/commands/getex)
    /// - Version: 6.2.0
    /// - Complexity: O(1)
    /// - Categories: @write, @string, @fast
    /// - Returns: [Bulk string](https:/redis.io/docs/reference/protocol-spec#bulk-strings): the value of `key`
    ///     [Null](https:/redis.io/docs/reference/protocol-spec#nulls): if `key` does not exist.
    @inlinable
    public func getex(key: RedisKey, expiration: RESPCommand.GETEXExpiration? = nil) async throws -> RESPToken {
        try await send("GETEX", key, expiration)
    }

    /// Returns a substring of the string stored at a key.
    ///
    /// - Documentation: [GETRANGE](https:/redis.io/docs/latest/commands/getrange)
    /// - Version: 2.4.0
    /// - Complexity: O(N) where N is the length of the returned string. The complexity is ultimately determined by the returned length, but because creating a substring from an existing string is very cheap, it can be considered O(1) for small strings.
    /// - Categories: @read, @string, @slow
    /// - Returns: [Bulk string](https:/redis.io/docs/reference/protocol-spec#bulk-strings): The substring of the string value stored at key, determined by the offsets start and end (both are inclusive).
    @inlinable
    public func getrange(key: RedisKey, start: Int, end: Int) async throws -> String {
        try await send("GETRANGE", key, start, end).converting()
    }

    /// Returns the previous string value of a key after setting it to a new value.
    ///
    /// - Documentation: [GETSET](https:/redis.io/docs/latest/commands/getset)
    /// - Version: 1.0.0
    /// - Complexity: O(1)
    /// - Categories: @write, @string, @fast
    /// - Returns: One of the following:
    ///     * [Bulk string](https:/redis.io/docs/reference/protocol-spec#bulk-strings): the old value stored at the key.
    ///     * [Null](https:/redis.io/docs/reference/protocol-spec#nulls): if the key does not exist.
    @inlinable
    public func getset(key: RedisKey, value: String) async throws -> String? {
        try await send("GETSET", key, value).converting()
    }

    /// Deletes one or more fields and their values from a hash. Deletes the hash if no fields remain.
    ///
    /// - Documentation: [HDEL](https:/redis.io/docs/latest/commands/hdel)
    /// - Version: 2.0.0
    /// - Complexity: O(N) where N is the number of fields to be removed.
    /// - Categories: @write, @hash, @fast
    /// - Returns: [Integer](https:/redis.io/docs/reference/protocol-spec#integers): The number of fields that were removed from the hash, excluding any specified but non-existing fields.
    @inlinable
    public func hdel(key: RedisKey, field: String) async throws -> Int {
        try await send("HDEL", key, field).converting()
    }

    /// Deletes one or more fields and their values from a hash. Deletes the hash if no fields remain.
    ///
    /// - Documentation: [HDEL](https:/redis.io/docs/latest/commands/hdel)
    /// - Version: 2.0.0
    /// - Complexity: O(N) where N is the number of fields to be removed.
    /// - Categories: @write, @hash, @fast
    /// - Returns: [Integer](https:/redis.io/docs/reference/protocol-spec#integers): The number of fields that were removed from the hash, excluding any specified but non-existing fields.
    @inlinable
    public func hdel(key: RedisKey, fields: [String]) async throws -> Int {
        try await send("HDEL", key, fields).converting()
    }

    /// Handshakes with the Redis server.
    ///
    /// - Documentation: [HELLO](https:/redis.io/docs/latest/commands/hello)
    /// - Version: 6.0.0
    /// - Complexity: O(1)
    /// - Categories: @fast, @connection
    /// - Returns: [Map](https:/redis.io/docs/reference/protocol-spec#maps): a list of server properties.
    ///     [Simple error](https:/redis.io/docs/reference/protocol-spec#simple-errors): if the `protover` requested does not exist.
    @inlinable
    public func hello(arguments: RESPCommand.HELLOArguments? = nil) async throws -> RESPToken {
        try await send("HELLO", arguments)
    }

    /// Determines whether a field exists in a hash.
    ///
    /// - Documentation: [HEXISTS](https:/redis.io/docs/latest/commands/hexists)
    /// - Version: 2.0.0
    /// - Complexity: O(1)
    /// - Categories: @read, @hash, @fast
    /// - Returns: One of the following:
    ///     * [Integer](https:/redis.io/docs/reference/protocol-spec#integers): `0` if the hash does not contain the field, or the key does not exist.
    ///     * [Integer](https:/redis.io/docs/reference/protocol-spec#integers): `1` if the hash contains the field.
    @inlinable
    public func hexists(key: RedisKey, field: String) async throws -> Int {
        try await send("HEXISTS", key, field).converting()
    }

    /// Returns the value of a field in a hash.
    ///
    /// - Documentation: [HGET](https:/redis.io/docs/latest/commands/hget)
    /// - Version: 2.0.0
    /// - Complexity: O(1)
    /// - Categories: @read, @hash, @fast
    /// - Returns: One of the following:
    ///     * [Bulk string](https:/redis.io/docs/reference/protocol-spec#bulk-strings): The value associated with the field.
    ///     * [Null](https:/redis.io/docs/reference/protocol-spec#nulls): If the field is not present in the hash or key does not exist.
    @inlinable
    public func hget(key: RedisKey, field: String) async throws -> String? {
        try await send("HGET", key, field).converting()
    }

    /// Returns all fields and values in a hash.
    ///
    /// - Documentation: [HGETALL](https:/redis.io/docs/latest/commands/hgetall)
    /// - Version: 2.0.0
    /// - Complexity: O(N) where N is the size of the hash.
    /// - Categories: @read, @hash, @slow
    /// - Returns: [Map](https:/redis.io/docs/reference/protocol-spec#maps): a map of fields and their values stored in the hash, or an empty list when key does not exist.
    @inlinable
    public func hgetall(key: RedisKey) async throws -> RESPToken {
        try await send("HGETALL", key).converting()
    }

    /// Increments the integer value of a field in a hash by a number. Uses 0 as initial value if the field doesn't exist.
    ///
    /// - Documentation: [HINCRBY](https:/redis.io/docs/latest/commands/hincrby)
    /// - Version: 2.0.0
    /// - Complexity: O(1)
    /// - Categories: @write, @hash, @fast
    /// - Returns: [Integer](https:/redis.io/docs/reference/protocol-spec#integers): the value of the field after the increment operation.
    @inlinable
    public func hincrby(key: RedisKey, field: String, increment: Int) async throws -> Int {
        try await send("HINCRBY", key, field, increment).converting()
    }

    /// Increments the floating point value of a field by a number. Uses 0 as initial value if the field doesn't exist.
    ///
    /// - Documentation: [HINCRBYFLOAT](https:/redis.io/docs/latest/commands/hincrbyfloat)
    /// - Version: 2.6.0
    /// - Complexity: O(1)
    /// - Categories: @write, @hash, @fast
    /// - Returns: [Bulk string](https:/redis.io/docs/reference/protocol-spec#bulk-strings): The value of the field after the increment operation.
    @inlinable
    public func hincrbyfloat(key: RedisKey, field: String, increment: Double) async throws -> String {
        try await send("HINCRBYFLOAT", key, field, increment).converting()
    }

    /// Returns all fields in a hash.
    ///
    /// - Documentation: [HKEYS](https:/redis.io/docs/latest/commands/hkeys)
    /// - Version: 2.0.0
    /// - Complexity: O(N) where N is the size of the hash.
    /// - Categories: @read, @hash, @slow
    /// - Returns: [Array](https:/redis.io/docs/reference/protocol-spec#arrays): a list of fields in the hash, or an empty list when the key does not exist.
    @inlinable
    public func hkeys(key: RedisKey) async throws -> [RESPToken] {
        try await send("HKEYS", key).converting()
    }

    /// Returns the number of fields in a hash.
    ///
    /// - Documentation: [HLEN](https:/redis.io/docs/latest/commands/hlen)
    /// - Version: 2.0.0
    /// - Complexity: O(1)
    /// - Categories: @read, @hash, @fast
    /// - Returns: [Integer](https:/redis.io/docs/reference/protocol-spec#integers): the number of the fields in the hash, or 0 when the key does not exist.
    @inlinable
    public func hlen(key: RedisKey) async throws -> Int {
        try await send("HLEN", key).converting()
    }

    /// Returns the values of all fields in a hash.
    ///
    /// - Documentation: [HMGET](https:/redis.io/docs/latest/commands/hmget)
    /// - Version: 2.0.0
    /// - Complexity: O(N) where N is the number of fields being requested.
    /// - Categories: @read, @hash, @fast
    /// - Returns: [Array](https:/redis.io/docs/reference/protocol-spec#arrays): a list of values associated with the given fields, in the same order as they are requested.
    @inlinable
    public func hmget(key: RedisKey, field: String) async throws -> [RESPToken] {
        try await send("HMGET", key, field).converting()
    }

    /// Returns the values of all fields in a hash.
    ///
    /// - Documentation: [HMGET](https:/redis.io/docs/latest/commands/hmget)
    /// - Version: 2.0.0
    /// - Complexity: O(N) where N is the number of fields being requested.
    /// - Categories: @read, @hash, @fast
    /// - Returns: [Array](https:/redis.io/docs/reference/protocol-spec#arrays): a list of values associated with the given fields, in the same order as they are requested.
    @inlinable
    public func hmget(key: RedisKey, fields: [String]) async throws -> [RESPToken] {
        try await send("HMGET", key, fields).converting()
    }

    /// Sets the values of multiple fields.
    ///
    /// - Documentation: [HMSET](https:/redis.io/docs/latest/commands/hmset)
    /// - Version: 2.0.0
    /// - Complexity: O(N) where N is the number of fields being set.
    /// - Categories: @write, @hash, @fast
    /// - Returns: [Simple string](https:/redis.io/docs/reference/protocol-spec#simple-strings): `OK`.
    @inlinable
    public func hmset(key: RedisKey, data: RESPCommand.HMSETData) async throws {
        try await send("HMSET", key, data)
    }

    /// Sets the values of multiple fields.
    ///
    /// - Documentation: [HMSET](https:/redis.io/docs/latest/commands/hmset)
    /// - Version: 2.0.0
    /// - Complexity: O(N) where N is the number of fields being set.
    /// - Categories: @write, @hash, @fast
    /// - Returns: [Simple string](https:/redis.io/docs/reference/protocol-spec#simple-strings): `OK`.
    @inlinable
    public func hmset(key: RedisKey, datas: [RESPCommand.HMSETData]) async throws {
        try await send("HMSET", key, datas)
    }

    /// Returns one or more random fields from a hash.
    ///
    /// - Documentation: [HRANDFIELD](https:/redis.io/docs/latest/commands/hrandfield)
    /// - Version: 6.2.0
    /// - Complexity: O(N) where N is the number of fields returned
    /// - Categories: @read, @hash, @slow
    /// - Returns: Any of the following:
    ///     * [Null](https:/redis.io/docs/reference/protocol-spec#nulls): if the key doesn't exist
    ///     * [Bulk string](https:/redis.io/docs/reference/protocol-spec#bulk-strings): a single, randomly selected field when the `count` option is not used
    ///     * [Array](https:/redis.io/docs/reference/protocol-spec#arrays): a list containing `count` fields when the `count` option is used, or an empty array if the key does not exists.
    ///     * [Array](https:/redis.io/docs/reference/protocol-spec#arrays): a list of fields and their values when `count` and `WITHVALUES` were both used.
    @inlinable
    public func hrandfield(key: RedisKey, options: RESPCommand.HRANDFIELDOptions? = nil) async throws -> RESPToken {
        try await send("HRANDFIELD", key, options)
    }

    /// Iterates over fields and values of a hash.
    ///
    /// - Documentation: [HSCAN](https:/redis.io/docs/latest/commands/hscan)
    /// - Version: 2.8.0
    /// - Complexity: O(1) for every call. O(N) for a complete iteration, including enough command calls for the cursor to return back to 0. N is the number of elements inside the collection.
    /// - Categories: @read, @hash, @slow
    /// - Returns: [Array](https:/redis.io/docs/reference/protocol-spec#arrays): a two-element array.
    ///     * The first element is a [Bulk string](https:/redis.io/docs/reference/protocol-spec#bulk-strings) that represents an unsigned 64-bit number, the cursor.
    ///     * The second element is an [Array](https:/redis.io/docs/reference/protocol-spec#arrays) of field/value pairs that were scanned.
    @inlinable
    public func hscan(key: RedisKey, cursor: Int, pattern: String? = nil, count: Int? = nil) async throws -> [RESPToken] {
        try await send("HSCAN", key, cursor, RESPWithToken("MATCH", pattern), RESPWithToken("COUNT", count)).converting()
    }

    /// Creates or modifies the value of a field in a hash.
    ///
    /// - Documentation: [HSET](https:/redis.io/docs/latest/commands/hset)
    /// - Version: 2.0.0
    /// - Complexity: O(1) for each field/value pair added, so O(N) to add N field/value pairs when the command is called with multiple field/value pairs.
    /// - Categories: @write, @hash, @fast
    /// - Returns: [Integer](https:/redis.io/docs/reference/protocol-spec#integers): the number of fields that were added.
    @inlinable
    public func hset(key: RedisKey, data: RESPCommand.HSETData) async throws -> Int {
        try await send("HSET", key, data).converting()
    }

    /// Creates or modifies the value of a field in a hash.
    ///
    /// - Documentation: [HSET](https:/redis.io/docs/latest/commands/hset)
    /// - Version: 2.0.0
    /// - Complexity: O(1) for each field/value pair added, so O(N) to add N field/value pairs when the command is called with multiple field/value pairs.
    /// - Categories: @write, @hash, @fast
    /// - Returns: [Integer](https:/redis.io/docs/reference/protocol-spec#integers): the number of fields that were added.
    @inlinable
    public func hset(key: RedisKey, datas: [RESPCommand.HSETData]) async throws -> Int {
        try await send("HSET", key, datas).converting()
    }

    /// Sets the value of a field in a hash only when the field doesn't exist.
    ///
    /// - Documentation: [HSETNX](https:/redis.io/docs/latest/commands/hsetnx)
    /// - Version: 2.0.0
    /// - Complexity: O(1)
    /// - Categories: @write, @hash, @fast
    /// - Returns: One of the following:
    ///     * [Integer](https:/redis.io/docs/reference/protocol-spec#integers): `0` if the field already exists in the hash and no operation was performed.
    ///     * [Integer](https:/redis.io/docs/reference/protocol-spec#integers): `1` if the field is a new field in the hash and the value was set.
    @inlinable
    public func hsetnx(key: RedisKey, field: String, value: String) async throws -> Int {
        try await send("HSETNX", key, field, value).converting()
    }

    /// Returns the length of the value of a field.
    ///
    /// - Documentation: [HSTRLEN](https:/redis.io/docs/latest/commands/hstrlen)
    /// - Version: 3.2.0
    /// - Complexity: O(1)
    /// - Categories: @read, @hash, @fast
    /// - Returns: [Integer](https:/redis.io/docs/reference/protocol-spec#integers): the string length of the value associated with the _field_, or zero when the _field_ isn't present in the hash or the _key_ doesn't exist at all.
    @inlinable
    public func hstrlen(key: RedisKey, field: String) async throws -> Int {
        try await send("HSTRLEN", key, field).converting()
    }

    /// Returns all values in a hash.
    ///
    /// - Documentation: [HVALS](https:/redis.io/docs/latest/commands/hvals)
    /// - Version: 2.0.0
    /// - Complexity: O(N) where N is the size of the hash.
    /// - Categories: @read, @hash, @slow
    /// - Returns: [Array](https:/redis.io/docs/reference/protocol-spec#arrays): a list of values in the hash, or an empty list when the key does not exist.
    @inlinable
    public func hvals(key: RedisKey) async throws -> [RESPToken] {
        try await send("HVALS", key).converting()
    }

    /// Increments the integer value of a key by one. Uses 0 as initial value if the key doesn't exist.
    ///
    /// - Documentation: [INCR](https:/redis.io/docs/latest/commands/incr)
    /// - Version: 1.0.0
    /// - Complexity: O(1)
    /// - Categories: @write, @string, @fast
    /// - Returns: [Integer](https:/redis.io/docs/reference/protocol-spec#integers): the value of the key after the increment.
    @inlinable
    public func incr(key: RedisKey) async throws -> Int {
        try await send("INCR", key).converting()
    }

    /// Increments the integer value of a key by a number. Uses 0 as initial value if the key doesn't exist.
    ///
    /// - Documentation: [INCRBY](https:/redis.io/docs/latest/commands/incrby)
    /// - Version: 1.0.0
    /// - Complexity: O(1)
    /// - Categories: @write, @string, @fast
    /// - Returns: [Integer](https:/redis.io/docs/reference/protocol-spec#integers): the value of the key after the increment.
    @inlinable
    public func incrby(key: RedisKey, increment: Int) async throws -> Int {
        try await send("INCRBY", key, increment).converting()
    }

    /// Increment the floating point value of a key by a number. Uses 0 as initial value if the key doesn't exist.
    ///
    /// - Documentation: [INCRBYFLOAT](https:/redis.io/docs/latest/commands/incrbyfloat)
    /// - Version: 2.6.0
    /// - Complexity: O(1)
    /// - Categories: @write, @string, @fast
    /// - Returns: [Bulk string](https:/redis.io/docs/reference/protocol-spec#bulk-strings): the value of the key after the increment.
    @inlinable
    public func incrbyfloat(key: RedisKey, increment: Double) async throws -> String {
        try await send("INCRBYFLOAT", key, increment).converting()
    }

    /// Returns information and statistics about the server.
    ///
    /// - Documentation: [INFO](https:/redis.io/docs/latest/commands/info)
    /// - Version: 1.0.0
    /// - Complexity: O(1)
    /// - Categories: @slow, @dangerous
    /// - Returns: [Bulk string](https:/redis.io/docs/reference/protocol-spec#bulk-strings): a map of info fields, one field per line in the form of `<field>:<value>` where the value can be a comma separated map like `<key>=<val>`. Also contains section header lines starting with `#` and blank lines.
    ///     
    ///     Lines can contain a section name (starting with a `#` character) or a property. All the properties are in the form of `field:value` terminated by `\r\n`.
    @inlinable
    public func info(section: String? = nil) async throws -> String {
        try await send("INFO", section).converting()
    }

    /// Returns information and statistics about the server.
    ///
    /// - Documentation: [INFO](https:/redis.io/docs/latest/commands/info)
    /// - Version: 1.0.0
    /// - Complexity: O(1)
    /// - Categories: @slow, @dangerous
    /// - Returns: [Bulk string](https:/redis.io/docs/reference/protocol-spec#bulk-strings): a map of info fields, one field per line in the form of `<field>:<value>` where the value can be a comma separated map like `<key>=<val>`. Also contains section header lines starting with `#` and blank lines.
    ///     
    ///     Lines can contain a section name (starting with a `#` character) or a property. All the properties are in the form of `field:value` terminated by `\r\n`.
    @inlinable
    public func info(sections: [String]) async throws -> String {
        try await send("INFO", sections).converting()
    }

    /// Returns all key names that match a pattern.
    ///
    /// - Documentation: [KEYS](https:/redis.io/docs/latest/commands/keys)
    /// - Version: 1.0.0
    /// - Complexity: O(N) with N being the number of keys in the database, under the assumption that the key names in the database and the given pattern have limited length.
    /// - Categories: @keyspace, @read, @slow, @dangerous
    /// - Returns: [Array](https:/redis.io/docs/reference/protocol-spec#arrays): a list of keys matching _pattern_.
    @inlinable
    public func keys(pattern: String) async throws -> [RESPToken] {
        try await send("KEYS", pattern).converting()
    }

    /// Returns the Unix timestamp of the last successful save to disk.
    ///
    /// - Documentation: [LASTSAVE](https:/redis.io/docs/latest/commands/lastsave)
    /// - Version: 1.0.0
    /// - Complexity: O(1)
    /// - Categories: @admin, @fast, @dangerous
    /// - Returns: [Integer](https:/redis.io/docs/reference/protocol-spec#integers): UNIX TIME of the last DB save executed with success.
    @inlinable
    public func lastsave() async throws -> Int {
        try await send("LASTSAVE").converting()
    }

    /// Returns a human-readable latency analysis report.
    ///
    /// - Documentation: [LATENCY DOCTOR](https:/redis.io/docs/latest/commands/latency-doctor)
    /// - Version: 2.8.13
    /// - Complexity: O(1)
    /// - Categories: @admin, @slow, @dangerous
    /// - Returns: [Verbatim string](https:/redis.io/docs/reference/protocol-spec#verbatim-strings): a human readable latency analysis report.
    @inlinable
    public func latencyDoctor() async throws -> String {
        try await send("LATENCY", "DOCTOR").converting()
    }

    /// Returns a latency graph for an event.
    ///
    /// - Documentation: [LATENCY GRAPH](https:/redis.io/docs/latest/commands/latency-graph)
    /// - Version: 2.8.13
    /// - Complexity: O(1)
    /// - Categories: @admin, @slow, @dangerous
    /// - Returns: [Bulk string](https:/redis.io/docs/reference/protocol-spec#bulk-strings): Latency graph
    @inlinable
    public func latencyGraph(event: String) async throws -> String {
        try await send("LATENCY", "GRAPH", event).converting()
    }

    /// Returns helpful text about the different subcommands.
    ///
    /// - Documentation: [LATENCY HELP](https:/redis.io/docs/latest/commands/latency-help)
    /// - Version: 2.8.13
    /// - Complexity: O(1)
    /// - Categories: @slow
    /// - Returns: [Array](https:/redis.io/docs/reference/protocol-spec#arrays): a list of sub-commands and their descriptions.
    @inlinable
    public func latencyHelp() async throws -> [RESPToken] {
        try await send("LATENCY", "HELP").converting()
    }

    /// Returns the cumulative distribution of latencies of a subset or all commands.
    ///
    /// - Documentation: [LATENCY HISTOGRAM](https:/redis.io/docs/latest/commands/latency-histogram)
    /// - Version: 7.0.0
    /// - Complexity: O(N) where N is the number of commands with latency information being retrieved.
    /// - Categories: @admin, @slow, @dangerous
    /// - Returns: [Map](https:/redis.io/docs/reference/protocol-spec#maps): a map where each key is a command name, and each value is a map with the total calls, and an inner map of the histogram time buckets.
    @inlinable
    public func latencyHistogram(command: String? = nil) async throws -> RESPToken {
        try await send("LATENCY", "HISTOGRAM", command).converting()
    }

    /// Returns the cumulative distribution of latencies of a subset or all commands.
    ///
    /// - Documentation: [LATENCY HISTOGRAM](https:/redis.io/docs/latest/commands/latency-histogram)
    /// - Version: 7.0.0
    /// - Complexity: O(N) where N is the number of commands with latency information being retrieved.
    /// - Categories: @admin, @slow, @dangerous
    /// - Returns: [Map](https:/redis.io/docs/reference/protocol-spec#maps): a map where each key is a command name, and each value is a map with the total calls, and an inner map of the histogram time buckets.
    @inlinable
    public func latencyHistogram(commands: [String]) async throws -> RESPToken {
        try await send("LATENCY", "HISTOGRAM", commands).converting()
    }

    /// Returns timestamp-latency samples for an event.
    ///
    /// - Documentation: [LATENCY HISTORY](https:/redis.io/docs/latest/commands/latency-history)
    /// - Version: 2.8.13
    /// - Complexity: O(1)
    /// - Categories: @admin, @slow, @dangerous
    /// - Returns: [Array](https:/redis.io/docs/reference/protocol-spec#arrays): an array where each element is a two elements array representing the timestamp and the latency of the event.
    @inlinable
    public func latencyHistory(event: String) async throws -> [RESPToken] {
        try await send("LATENCY", "HISTORY", event).converting()
    }

    /// Returns the latest latency samples for all events.
    ///
    /// - Documentation: [LATENCY LATEST](https:/redis.io/docs/latest/commands/latency-latest)
    /// - Version: 2.8.13
    /// - Complexity: O(1)
    /// - Categories: @admin, @slow, @dangerous
    /// - Returns: [Array](https:/redis.io/docs/reference/protocol-spec#arrays): an array where each element is a four elements array representing the event's name, timestamp, latest and all-time latency measurements.
    @inlinable
    public func latencyLatest() async throws -> [RESPToken] {
        try await send("LATENCY", "LATEST").converting()
    }

    /// Resets the latency data for one or more events.
    ///
    /// - Documentation: [LATENCY RESET](https:/redis.io/docs/latest/commands/latency-reset)
    /// - Version: 2.8.13
    /// - Complexity: O(1)
    /// - Categories: @admin, @slow, @dangerous
    /// - Returns: [Integer](https:/redis.io/docs/reference/protocol-spec#integers): the number of event time series that were reset.
    @inlinable
    public func latencyReset(event: String? = nil) async throws -> Int {
        try await send("LATENCY", "RESET", event).converting()
    }

    /// Resets the latency data for one or more events.
    ///
    /// - Documentation: [LATENCY RESET](https:/redis.io/docs/latest/commands/latency-reset)
    /// - Version: 2.8.13
    /// - Complexity: O(1)
    /// - Categories: @admin, @slow, @dangerous
    /// - Returns: [Integer](https:/redis.io/docs/reference/protocol-spec#integers): the number of event time series that were reset.
    @inlinable
    public func latencyReset(events: [String]) async throws -> Int {
        try await send("LATENCY", "RESET", events).converting()
    }

    /// Finds the longest common substring.
    ///
    /// - Documentation: [LCS](https:/redis.io/docs/latest/commands/lcs)
    /// - Version: 7.0.0
    /// - Complexity: O(N*M) where N and M are the lengths of s1 and s2, respectively
    /// - Categories: @read, @string, @slow
    /// - Returns: One of the following:
    ///     * [Bulk string](https:/redis.io/docs/reference/protocol-spec#bulk-strings): the longest common subsequence.
    ///     * [Integer](https:/redis.io/docs/reference/protocol-spec#integers): the length of the longest common subsequence when _LEN_ is given.
    ///     * [Map](https:/redis.io/docs/reference/protocol-spec#maps): a map with the LCS length and all the ranges in both the strings when _IDX_ is given.
    @inlinable
    public func lcs(key1: RedisKey, key2: RedisKey, len: Bool = false, idx: Bool = false, minMatchLen: Int? = nil, withmatchlen: Bool = false) async throws -> RESPToken {
        try await send("LCS", key1, key2, RedisPureToken("LEN", len), RedisPureToken("IDX", idx), RESPWithToken("MINMATCHLEN", minMatchLen), RedisPureToken("WITHMATCHLEN", withmatchlen))
    }

    /// Returns an element from a list by its index.
    ///
    /// - Documentation: [LINDEX](https:/redis.io/docs/latest/commands/lindex)
    /// - Version: 1.0.0
    /// - Complexity: O(N) where N is the number of elements to traverse to get to the element at index. This makes asking for the first or the last element of the list O(1).
    /// - Categories: @read, @list, @slow
    /// - Returns: One of the following:
    ///     * [Null](https:/redis.io/docs/reference/protocol-spec#nulls): when _index_ is out of range.
    ///     * [Bulk string](https:/redis.io/docs/reference/protocol-spec#bulk-strings): the requested element.
    @inlinable
    public func lindex(key: RedisKey, index: Int) async throws -> String? {
        try await send("LINDEX", key, index).converting()
    }

    /// Inserts an element before or after another element in a list.
    ///
    /// - Documentation: [LINSERT](https:/redis.io/docs/latest/commands/linsert)
    /// - Version: 2.2.0
    /// - Complexity: O(N) where N is the number of elements to traverse before seeing the value pivot. This means that inserting somewhere on the left end on the list (head) can be considered O(1) and inserting somewhere on the right end (tail) is O(N).
    /// - Categories: @write, @list, @slow
    /// - Returns: One of the following:
    ///     * [Integer](https:/redis.io/docs/reference/protocol-spec#integers): the list length after a successful insert operation.
    ///     * [Integer](https:/redis.io/docs/reference/protocol-spec#integers): `0` when the key doesn't exist.
    ///     * [Integer](https:/redis.io/docs/reference/protocol-spec#integers): `-1` when the pivot wasn't found.
    @inlinable
    public func linsert(key: RedisKey, `where`: RESPCommand.LINSERTWhere, pivot: String, element: String) async throws -> Int {
        try await send("LINSERT", key, `where`, pivot, element).converting()
    }

    /// Returns the length of a list.
    ///
    /// - Documentation: [LLEN](https:/redis.io/docs/latest/commands/llen)
    /// - Version: 1.0.0
    /// - Complexity: O(1)
    /// - Categories: @read, @list, @fast
    /// - Returns: [Integer](https:/redis.io/docs/reference/protocol-spec#integers): the length of the list.
    @inlinable
    public func llen(key: RedisKey) async throws -> Int {
        try await send("LLEN", key).converting()
    }

    /// Returns an element after popping it from one list and pushing it to another. Deletes the list if the last element was moved.
    ///
    /// - Documentation: [LMOVE](https:/redis.io/docs/latest/commands/lmove)
    /// - Version: 6.2.0
    /// - Complexity: O(1)
    /// - Categories: @write, @list, @slow
    /// - Returns: [Bulk string](https:/redis.io/docs/reference/protocol-spec#bulk-strings): the element being popped and pushed.
    @inlinable
    public func lmove(source: RedisKey, destination: RedisKey, wherefrom: RESPCommand.LMOVEWherefrom, whereto: RESPCommand.LMOVEWhereto) async throws -> String {
        try await send("LMOVE", source, destination, wherefrom, whereto).converting()
    }

    /// Returns multiple elements from a list after removing them. Deletes the list if the last element was popped.
    ///
    /// - Documentation: [LMPOP](https:/redis.io/docs/latest/commands/lmpop)
    /// - Version: 7.0.0
    /// - Complexity: O(N+M) where N is the number of provided keys and M is the number of elements returned.
    /// - Categories: @write, @list, @slow
    /// - Returns: One of the following:
    ///     * [Null](https:/redis.io/docs/reference/protocol-spec#nulls): if no element could be popped.
    ///     * [Array](https:/redis.io/docs/reference/protocol-spec#arrays): a two-element array with the first element being the name of the key from which elements were popped and the second element being an array of elements.
    @inlinable
    public func lmpop(key: RedisKey, `where`: RESPCommand.LMPOPWhere, count: Int? = nil) async throws -> [RESPToken]? {
        try await send("LMPOP", 1, key, `where`, RESPWithToken("COUNT", count)).converting()
    }

    /// Returns multiple elements from a list after removing them. Deletes the list if the last element was popped.
    ///
    /// - Documentation: [LMPOP](https:/redis.io/docs/latest/commands/lmpop)
    /// - Version: 7.0.0
    /// - Complexity: O(N+M) where N is the number of provided keys and M is the number of elements returned.
    /// - Categories: @write, @list, @slow
    /// - Returns: One of the following:
    ///     * [Null](https:/redis.io/docs/reference/protocol-spec#nulls): if no element could be popped.
    ///     * [Array](https:/redis.io/docs/reference/protocol-spec#arrays): a two-element array with the first element being the name of the key from which elements were popped and the second element being an array of elements.
    @inlinable
    public func lmpop(keys: [RedisKey], `where`: RESPCommand.LMPOPWhere, count: Int? = nil) async throws -> [RESPToken]? {
        try await send("LMPOP", RESPArrayWithCount(keys), `where`, RESPWithToken("COUNT", count)).converting()
    }

    /// Displays computer art and the Redis version
    ///
    /// - Documentation: [LOLWUT](https:/redis.io/docs/latest/commands/lolwut)
    /// - Version: 5.0.0
    /// - Categories: @read, @fast
    /// - Returns: [Verbatim string](https:/redis.io/docs/reference/protocol-spec#verbatim-strings): a string containing generative computer art and the Redis version.
    @inlinable
    public func lolwut(version: Int? = nil) async throws -> String {
        try await send("LOLWUT", RESPWithToken("VERSION", version)).converting()
    }

    /// Returns the first elements in a list after removing it. Deletes the list if the last element was popped.
    ///
    /// - Documentation: [LPOP](https:/redis.io/docs/latest/commands/lpop)
    /// - Version: 1.0.0
    /// - Complexity: O(N) where N is the number of elements returned
    /// - Categories: @write, @list, @fast
    /// - Returns: One of the following:
    ///     * [Null](https:/redis.io/docs/reference/protocol-spec#nulls): if the key does not exist.
    ///     * [Bulk string](https:/redis.io/docs/reference/protocol-spec#bulk-strings): when called without the _count_ argument, the value of the first element.
    ///     * [Array](https:/redis.io/docs/reference/protocol-spec#arrays): when called with the _count_ argument, a list of popped elements.
    @inlinable
    public func lpop(key: RedisKey, count: Int? = nil) async throws -> RESPToken {
        try await send("LPOP", key, count)
    }

    /// Returns the index of matching elements in a list.
    ///
    /// - Documentation: [LPOS](https:/redis.io/docs/latest/commands/lpos)
    /// - Version: 6.0.6
    /// - Complexity: O(N) where N is the number of elements in the list, for the average case. When searching for elements near the head or the tail of the list, or when the MAXLEN option is provided, the command may run in constant time.
    /// - Categories: @read, @list, @slow
    /// - Returns: Any of the following:
    ///     * [Null](https:/redis.io/docs/reference/protocol-spec#nulls): if there is no matching element.
    ///     * [Integer](https:/redis.io/docs/reference/protocol-spec#integers): an integer representing the matching element.
    ///     * [Array](https:/redis.io/docs/reference/protocol-spec#arrays): If the COUNT option is given, an array of integers representing the matching elements (or an empty array if there are no matches).
    @inlinable
    public func lpos(key: RedisKey, element: String, rank: Int? = nil, numMatches: Int? = nil, len: Int? = nil) async throws -> RESPToken {
        try await send("LPOS", key, element, RESPWithToken("RANK", rank), RESPWithToken("COUNT", numMatches), RESPWithToken("MAXLEN", len))
    }

    /// Prepends one or more elements to a list. Creates the key if it doesn't exist.
    ///
    /// - Documentation: [LPUSH](https:/redis.io/docs/latest/commands/lpush)
    /// - Version: 1.0.0
    /// - Complexity: O(1) for each element added, so O(N) to add N elements when the command is called with multiple arguments.
    /// - Categories: @write, @list, @fast
    /// - Returns: [Integer](https:/redis.io/docs/reference/protocol-spec#integers): the length of the list after the push operation.
    @inlinable
    public func lpush(key: RedisKey, element: String) async throws -> Int {
        try await send("LPUSH", key, element).converting()
    }

    /// Prepends one or more elements to a list. Creates the key if it doesn't exist.
    ///
    /// - Documentation: [LPUSH](https:/redis.io/docs/latest/commands/lpush)
    /// - Version: 1.0.0
    /// - Complexity: O(1) for each element added, so O(N) to add N elements when the command is called with multiple arguments.
    /// - Categories: @write, @list, @fast
    /// - Returns: [Integer](https:/redis.io/docs/reference/protocol-spec#integers): the length of the list after the push operation.
    @inlinable
    public func lpush(key: RedisKey, elements: [String]) async throws -> Int {
        try await send("LPUSH", key, elements).converting()
    }

    /// Prepends one or more elements to a list only when the list exists.
    ///
    /// - Documentation: [LPUSHX](https:/redis.io/docs/latest/commands/lpushx)
    /// - Version: 2.2.0
    /// - Complexity: O(1) for each element added, so O(N) to add N elements when the command is called with multiple arguments.
    /// - Categories: @write, @list, @fast
    /// - Returns: [Integer](https:/redis.io/docs/reference/protocol-spec#integers): the length of the list after the push operation.
    @inlinable
    public func lpushx(key: RedisKey, element: String) async throws -> Int {
        try await send("LPUSHX", key, element).converting()
    }

    /// Prepends one or more elements to a list only when the list exists.
    ///
    /// - Documentation: [LPUSHX](https:/redis.io/docs/latest/commands/lpushx)
    /// - Version: 2.2.0
    /// - Complexity: O(1) for each element added, so O(N) to add N elements when the command is called with multiple arguments.
    /// - Categories: @write, @list, @fast
    /// - Returns: [Integer](https:/redis.io/docs/reference/protocol-spec#integers): the length of the list after the push operation.
    @inlinable
    public func lpushx(key: RedisKey, elements: [String]) async throws -> Int {
        try await send("LPUSHX", key, elements).converting()
    }

    /// Returns a range of elements from a list.
    ///
    /// - Documentation: [LRANGE](https:/redis.io/docs/latest/commands/lrange)
    /// - Version: 1.0.0
    /// - Complexity: O(S+N) where S is the distance of start offset from HEAD for small lists, from nearest end (HEAD or TAIL) for large lists; and N is the number of elements in the specified range.
    /// - Categories: @read, @list, @slow
    /// - Returns: [Array](https:/redis.io/docs/reference/protocol-spec#arrays): a list of elements in the specified range, or an empty array if the key doesn't exist.
    @inlinable
    public func lrange(key: RedisKey, start: Int, stop: Int) async throws -> [RESPToken] {
        try await send("LRANGE", key, start, stop).converting()
    }

    /// Removes elements from a list. Deletes the list if the last element was removed.
    ///
    /// - Documentation: [LREM](https:/redis.io/docs/latest/commands/lrem)
    /// - Version: 1.0.0
    /// - Complexity: O(N+M) where N is the length of the list and M is the number of elements removed.
    /// - Categories: @write, @list, @slow
    /// - Returns: [Integer](https:/redis.io/docs/reference/protocol-spec#integers): the number of removed elements.
    @inlinable
    public func lrem(key: RedisKey, count: Int, element: String) async throws -> Int {
        try await send("LREM", key, count, element).converting()
    }

    /// Sets the value of an element in a list by its index.
    ///
    /// - Documentation: [LSET](https:/redis.io/docs/latest/commands/lset)
    /// - Version: 1.0.0
    /// - Complexity: O(N) where N is the length of the list. Setting either the first or the last element of the list is O(1).
    /// - Categories: @write, @list, @slow
    /// - Returns: [Simple string](https:/redis.io/docs/reference/protocol-spec#simple-strings): `OK`.
    @inlinable
    public func lset(key: RedisKey, index: Int, element: String) async throws {
        try await send("LSET", key, index, element)
    }

    /// Removes elements from both ends a list. Deletes the list if all elements were trimmed.
    ///
    /// - Documentation: [LTRIM](https:/redis.io/docs/latest/commands/ltrim)
    /// - Version: 1.0.0
    /// - Complexity: O(N) where N is the number of elements to be removed by the operation.
    /// - Categories: @write, @list, @slow
    /// - Returns: [Simple string](https:/redis.io/docs/reference/protocol-spec#simple-strings): `OK`.
    @inlinable
    public func ltrim(key: RedisKey, start: Int, stop: Int) async throws {
        try await send("LTRIM", key, start, stop)
    }

    /// Outputs a memory problems report.
    ///
    /// - Documentation: [MEMORY DOCTOR](https:/redis.io/docs/latest/commands/memory-doctor)
    /// - Version: 4.0.0
    /// - Complexity: O(1)
    /// - Categories: @slow
    /// - Returns: [Verbatim string](https:/redis.io/docs/reference/protocol-spec#verbatim-strings): a memory problems report.
    @inlinable
    public func memoryDoctor() async throws -> String {
        try await send("MEMORY", "DOCTOR").converting()
    }

    /// Returns helpful text about the different subcommands.
    ///
    /// - Documentation: [MEMORY HELP](https:/redis.io/docs/latest/commands/memory-help)
    /// - Version: 4.0.0
    /// - Complexity: O(1)
    /// - Categories: @slow
    /// - Returns: [Array](https:/redis.io/docs/reference/protocol-spec#arrays): a list of sub-commands and their descriptions.
    @inlinable
    public func memoryHelp() async throws -> [RESPToken] {
        try await send("MEMORY", "HELP").converting()
    }

    /// Returns the allocator statistics.
    ///
    /// - Documentation: [MEMORY MALLOC-STATS](https:/redis.io/docs/latest/commands/memory-malloc-stats)
    /// - Version: 4.0.0
    /// - Complexity: Depends on how much memory is allocated, could be slow
    /// - Categories: @slow
    /// - Returns: [Bulk string](https:/redis.io/docs/reference/protocol-spec#bulk-strings): The memory allocator's internal statistics report.
    @inlinable
    public func memoryMallocStats() async throws -> String {
        try await send("MEMORY", "MALLOC-STATS").converting()
    }

    /// Asks the allocator to release memory.
    ///
    /// - Documentation: [MEMORY PURGE](https:/redis.io/docs/latest/commands/memory-purge)
    /// - Version: 4.0.0
    /// - Complexity: Depends on how much memory is allocated, could be slow
    /// - Categories: @slow
    /// - Returns: [Simple string](https:/redis.io/docs/reference/protocol-spec#simple-strings): `OK`.
    @inlinable
    public func memoryPurge() async throws {
        try await send("MEMORY", "PURGE")
    }

    /// Returns details about memory usage.
    ///
    /// - Documentation: [MEMORY STATS](https:/redis.io/docs/latest/commands/memory-stats)
    /// - Version: 4.0.0
    /// - Complexity: O(1)
    /// - Categories: @slow
    /// - Returns: [Map](https:/redis.io/docs/reference/protocol-spec#maps): memory usage metrics and their values.
    @inlinable
    public func memoryStats() async throws -> RESPToken {
        try await send("MEMORY", "STATS").converting()
    }

    /// Estimates the memory usage of a key.
    ///
    /// - Documentation: [MEMORY USAGE](https:/redis.io/docs/latest/commands/memory-usage)
    /// - Version: 4.0.0
    /// - Complexity: O(N) where N is the number of samples.
    /// - Categories: @read, @slow
    /// - Returns: One of the following:
    ///     * [Integer](https:/redis.io/docs/reference/protocol-spec#integers): the memory usage in bytes.
    ///     * [Null](https:/redis.io/docs/reference/protocol-spec#nulls): if the key does not exist.
    @inlinable
    public func memoryUsage(key: RedisKey, count: Int? = nil) async throws -> Int? {
        try await send("MEMORY", "USAGE", key, RESPWithToken("SAMPLES", count)).converting()
    }

    /// Atomically returns the string values of one or more keys.
    ///
    /// - Documentation: [MGET](https:/redis.io/docs/latest/commands/mget)
    /// - Version: 1.0.0
    /// - Complexity: O(N) where N is the number of keys to retrieve.
    /// - Categories: @read, @string, @fast
    /// - Returns: [Array](https:/redis.io/docs/reference/protocol-spec#arrays): a list of values at the specified keys.
    @inlinable
    public func mget(key: RedisKey) async throws -> [RESPToken] {
        try await send("MGET", key).converting()
    }

    /// Atomically returns the string values of one or more keys.
    ///
    /// - Documentation: [MGET](https:/redis.io/docs/latest/commands/mget)
    /// - Version: 1.0.0
    /// - Complexity: O(N) where N is the number of keys to retrieve.
    /// - Categories: @read, @string, @fast
    /// - Returns: [Array](https:/redis.io/docs/reference/protocol-spec#arrays): a list of values at the specified keys.
    @inlinable
    public func mget(keys: [RedisKey]) async throws -> [RESPToken] {
        try await send("MGET", keys).converting()
    }

    /// Atomically transfers a key from one Redis instance to another.
    ///
    /// - Documentation: [MIGRATE](https:/redis.io/docs/latest/commands/migrate)
    /// - Version: 2.6.0
    /// - Complexity: This command actually executes a DUMP+DEL in the source instance, and a RESTORE in the target instance. See the pages of these commands for time complexity. Also an O(N) data transfer between the two instances is performed.
    /// - Categories: @keyspace, @write, @slow, @dangerous
    /// - Returns: One of the following:
    ///     * [Simple string](https:/redis.io/docs/reference/protocol-spec#simple-strings): `OK` on success.
    ///     * [Simple string](https:/redis.io/docs/reference/protocol-spec#simple-strings): `NOKEY` when no keys were found in the source instance.
    @inlinable
    public func migrate(host: String, port: Int, keySelector: RESPCommand.MIGRATEKeySelector, destinationDb: Int, timeout: Int, copy: Bool = false, replace: Bool = false, authentication: RESPCommand.MIGRATEAuthentication? = nil, keys: RedisKey? = nil) async throws -> String? {
        try await send("MIGRATE", host, port, keySelector, destinationDb, timeout, RedisPureToken("COPY", copy), RedisPureToken("REPLACE", replace), authentication, RESPWithToken("KEYS", keys)).converting()
    }

    /// Atomically transfers a key from one Redis instance to another.
    ///
    /// - Documentation: [MIGRATE](https:/redis.io/docs/latest/commands/migrate)
    /// - Version: 2.6.0
    /// - Complexity: This command actually executes a DUMP+DEL in the source instance, and a RESTORE in the target instance. See the pages of these commands for time complexity. Also an O(N) data transfer between the two instances is performed.
    /// - Categories: @keyspace, @write, @slow, @dangerous
    /// - Returns: One of the following:
    ///     * [Simple string](https:/redis.io/docs/reference/protocol-spec#simple-strings): `OK` on success.
    ///     * [Simple string](https:/redis.io/docs/reference/protocol-spec#simple-strings): `NOKEY` when no keys were found in the source instance.
    @inlinable
    public func migrate(host: String, port: Int, keySelector: RESPCommand.MIGRATEKeySelector, destinationDb: Int, timeout: Int, copy: Bool = false, replace: Bool = false, authentication: RESPCommand.MIGRATEAuthentication? = nil, keyss: [RedisKey]) async throws -> String? {
        try await send("MIGRATE", host, port, keySelector, destinationDb, timeout, RedisPureToken("COPY", copy), RedisPureToken("REPLACE", replace), authentication, RESPWithToken("KEYS", keyss)).converting()
    }

    /// Returns helpful text about the different subcommands.
    ///
    /// - Documentation: [MODULE HELP](https:/redis.io/docs/latest/commands/module-help)
    /// - Version: 5.0.0
    /// - Complexity: O(1)
    /// - Categories: @slow
    /// - Returns: [Array](https:/redis.io/docs/reference/protocol-spec#arrays): a list of sub-commands and their descriptions
    @inlinable
    public func moduleHelp() async throws -> [RESPToken] {
        try await send("MODULE", "HELP").converting()
    }

    /// Returns all loaded modules.
    ///
    /// - Documentation: [MODULE LIST](https:/redis.io/docs/latest/commands/module-list)
    /// - Version: 4.0.0
    /// - Complexity: O(N) where N is the number of loaded modules.
    /// - Categories: @admin, @slow, @dangerous
    /// - Returns: [Array](https:/redis.io/docs/reference/protocol-spec#arrays): list of loaded modules. Each element in the list represents a represents a module, and is a [Map](https:/redis.io/docs/reference/protocol-spec#maps) of property names and their values. The following properties is reported for each loaded module:
    ///     * name: the name of the module.
    ///     * ver: the version of the module.
    @inlinable
    public func moduleList() async throws -> [RESPToken] {
        try await send("MODULE", "LIST").converting()
    }

    /// Loads a module.
    ///
    /// - Documentation: [MODULE LOAD](https:/redis.io/docs/latest/commands/module-load)
    /// - Version: 4.0.0
    /// - Complexity: O(1)
    /// - Categories: @admin, @slow, @dangerous
    /// - Returns: [Simple string](https:/redis.io/docs/reference/protocol-spec#simple-strings): `OK` if the module was loaded.
    @inlinable
    public func moduleLoad(path: String, arg: String? = nil) async throws {
        try await send("MODULE", "LOAD", path, arg)
    }

    /// Loads a module.
    ///
    /// - Documentation: [MODULE LOAD](https:/redis.io/docs/latest/commands/module-load)
    /// - Version: 4.0.0
    /// - Complexity: O(1)
    /// - Categories: @admin, @slow, @dangerous
    /// - Returns: [Simple string](https:/redis.io/docs/reference/protocol-spec#simple-strings): `OK` if the module was loaded.
    @inlinable
    public func moduleLoad(path: String, args: [String]) async throws {
        try await send("MODULE", "LOAD", path, args)
    }

    /// Loads a module using extended parameters.
    ///
    /// - Documentation: [MODULE LOADEX](https:/redis.io/docs/latest/commands/module-loadex)
    /// - Version: 7.0.0
    /// - Complexity: O(1)
    /// - Categories: @admin, @slow, @dangerous
    /// - Returns: [Simple string](https:/redis.io/docs/reference/protocol-spec#simple-strings): `OK` if the module was loaded.
    @inlinable
    public func moduleLoadex(path: String, configs: RESPCommand.MODULELOADEXConfigs? = nil, args: String? = nil) async throws {
        try await send("MODULE", "LOADEX", path, RESPWithToken("CONFIG", configs), RESPWithToken("ARGS", args))
    }

    /// Loads a module using extended parameters.
    ///
    /// - Documentation: [MODULE LOADEX](https:/redis.io/docs/latest/commands/module-loadex)
    /// - Version: 7.0.0
    /// - Complexity: O(1)
    /// - Categories: @admin, @slow, @dangerous
    /// - Returns: [Simple string](https:/redis.io/docs/reference/protocol-spec#simple-strings): `OK` if the module was loaded.
    @inlinable
    public func moduleLoadex(path: String, configss: [RESPCommand.MODULELOADEXConfigs], argss: [String]) async throws {
        try await send("MODULE", "LOADEX", path, RESPWithToken("CONFIG", configss), RESPWithToken("ARGS", argss))
    }

    /// Unloads a module.
    ///
    /// - Documentation: [MODULE UNLOAD](https:/redis.io/docs/latest/commands/module-unload)
    /// - Version: 4.0.0
    /// - Complexity: O(1)
    /// - Categories: @admin, @slow, @dangerous
    /// - Returns: [Simple string](https:/redis.io/docs/reference/protocol-spec#simple-strings): `OK` if the module was unloaded.
    @inlinable
    public func moduleUnload(name: String) async throws {
        try await send("MODULE", "UNLOAD", name)
    }

    /// Listens for all requests received by the server in real-time.
    ///
    /// - Documentation: [MONITOR](https:/redis.io/docs/latest/commands/monitor)
    /// - Version: 1.0.0
    /// - Categories: @admin, @slow, @dangerous
    /// - Returns: **Non-standard return value**. Dumps the received commands in an infinite flow.
    @inlinable
    public func monitor() async throws -> RESPToken {
        try await send("MONITOR")
    }

    /// Moves a key to another database.
    ///
    /// - Documentation: [MOVE](https:/redis.io/docs/latest/commands/move)
    /// - Version: 1.0.0
    /// - Complexity: O(1)
    /// - Categories: @keyspace, @write, @fast
    /// - Returns: One of the following:
    ///     * [Integer](https:/redis.io/docs/reference/protocol-spec#integers): `1` if _key_ was moved.
    ///     * [Integer](https:/redis.io/docs/reference/protocol-spec#integers): `0` if _key_ wasn't moved.
    @inlinable
    public func move(key: RedisKey, db: Int) async throws -> Int {
        try await send("MOVE", key, db).converting()
    }

    /// Atomically creates or modifies the string values of one or more keys.
    ///
    /// - Documentation: [MSET](https:/redis.io/docs/latest/commands/mset)
    /// - Version: 1.0.1
    /// - Complexity: O(N) where N is the number of keys to set.
    /// - Categories: @write, @string, @slow
    /// - Returns: [Simple string](https:/redis.io/docs/reference/protocol-spec#simple-strings): always `OK` because `MSET` can't fail.
    @inlinable
    public func mset(data: RESPCommand.MSETData) async throws {
        try await send("MSET", data)
    }

    /// Atomically creates or modifies the string values of one or more keys.
    ///
    /// - Documentation: [MSET](https:/redis.io/docs/latest/commands/mset)
    /// - Version: 1.0.1
    /// - Complexity: O(N) where N is the number of keys to set.
    /// - Categories: @write, @string, @slow
    /// - Returns: [Simple string](https:/redis.io/docs/reference/protocol-spec#simple-strings): always `OK` because `MSET` can't fail.
    @inlinable
    public func mset(datas: [RESPCommand.MSETData]) async throws {
        try await send("MSET", datas)
    }

    /// Atomically modifies the string values of one or more keys only when all keys don't exist.
    ///
    /// - Documentation: [MSETNX](https:/redis.io/docs/latest/commands/msetnx)
    /// - Version: 1.0.1
    /// - Complexity: O(N) where N is the number of keys to set.
    /// - Categories: @write, @string, @slow
    /// - Returns: One of the following:
    ///     * [Integer](https:/redis.io/docs/reference/protocol-spec#integers): `0` if no key was set (at least one key already existed).
    ///     * [Integer](https:/redis.io/docs/reference/protocol-spec#integers): `1` if all the keys were set.
    @inlinable
    public func msetnx(data: RESPCommand.MSETNXData) async throws -> Int {
        try await send("MSETNX", data).converting()
    }

    /// Atomically modifies the string values of one or more keys only when all keys don't exist.
    ///
    /// - Documentation: [MSETNX](https:/redis.io/docs/latest/commands/msetnx)
    /// - Version: 1.0.1
    /// - Complexity: O(N) where N is the number of keys to set.
    /// - Categories: @write, @string, @slow
    /// - Returns: One of the following:
    ///     * [Integer](https:/redis.io/docs/reference/protocol-spec#integers): `0` if no key was set (at least one key already existed).
    ///     * [Integer](https:/redis.io/docs/reference/protocol-spec#integers): `1` if all the keys were set.
    @inlinable
    public func msetnx(datas: [RESPCommand.MSETNXData]) async throws -> Int {
        try await send("MSETNX", datas).converting()
    }

    /// Starts a transaction.
    ///
    /// - Documentation: [MULTI](https:/redis.io/docs/latest/commands/multi)
    /// - Version: 1.2.0
    /// - Complexity: O(1)
    /// - Categories: @fast, @transaction
    /// - Returns: [Simple string](https:/redis.io/docs/reference/protocol-spec#simple-strings): `OK`.
    @inlinable
    public func multi() async throws {
        try await send("MULTI")
    }

    /// Returns the internal encoding of a Redis object.
    ///
    /// - Documentation: [OBJECT ENCODING](https:/redis.io/docs/latest/commands/object-encoding)
    /// - Version: 2.2.3
    /// - Complexity: O(1)
    /// - Categories: @keyspace, @read, @slow
    /// - Returns: One of the following:
    ///     * [Null](https:/redis.io/docs/reference/protocol-spec#nulls): if the key doesn't exist.
    ///     * [Bulk string](https:/redis.io/docs/reference/protocol-spec#bulk-strings): the encoding of the object.
    @inlinable
    public func objectEncoding(key: RedisKey) async throws -> String? {
        try await send("OBJECT", "ENCODING", key).converting()
    }

    /// Returns the logarithmic access frequency counter of a Redis object.
    ///
    /// - Documentation: [OBJECT FREQ](https:/redis.io/docs/latest/commands/object-freq)
    /// - Version: 4.0.0
    /// - Complexity: O(1)
    /// - Categories: @keyspace, @read, @slow
    /// - Returns: One of the following:
    ///     [Integer](https:/redis.io/docs/reference/protocol-spec#integers): the counter's value.
    ///     [Null](https:/redis.io/docs/reference/protocol-spec#nulls): if _key_ doesn't exist.
    @inlinable
    public func objectFreq(key: RedisKey) async throws -> RESPToken {
        try await send("OBJECT", "FREQ", key)
    }

    /// Returns helpful text about the different subcommands.
    ///
    /// - Documentation: [OBJECT HELP](https:/redis.io/docs/latest/commands/object-help)
    /// - Version: 6.2.0
    /// - Complexity: O(1)
    /// - Categories: @keyspace, @slow
    /// - Returns: [Array](https:/redis.io/docs/reference/protocol-spec#arrays): a list of sub-commands and their descriptions.
    @inlinable
    public func objectHelp() async throws -> [RESPToken] {
        try await send("OBJECT", "HELP").converting()
    }

    /// Returns the time since the last access to a Redis object.
    ///
    /// - Documentation: [OBJECT IDLETIME](https:/redis.io/docs/latest/commands/object-idletime)
    /// - Version: 2.2.3
    /// - Complexity: O(1)
    /// - Categories: @keyspace, @read, @slow
    /// - Returns: One of the following:
    ///     [Integer](https:/redis.io/docs/reference/protocol-spec#integers): the idle time in seconds.
    ///     [Null](https:/redis.io/docs/reference/protocol-spec#nulls): if _key_ doesn't exist.
    @inlinable
    public func objectIdletime(key: RedisKey) async throws -> RESPToken {
        try await send("OBJECT", "IDLETIME", key)
    }

    /// Returns the reference count of a value of a key.
    ///
    /// - Documentation: [OBJECT REFCOUNT](https:/redis.io/docs/latest/commands/object-refcount)
    /// - Version: 2.2.3
    /// - Complexity: O(1)
    /// - Categories: @keyspace, @read, @slow
    /// - Returns: One of the following:
    ///     [Integer](https:/redis.io/docs/reference/protocol-spec#integers): the number of references.
    ///     [Null](https:/redis.io/docs/reference/protocol-spec#nulls): if _key_ doesn't exist.
    @inlinable
    public func objectRefcount(key: RedisKey) async throws -> RESPToken {
        try await send("OBJECT", "REFCOUNT", key)
    }

    /// Removes the expiration time of a key.
    ///
    /// - Documentation: [PERSIST](https:/redis.io/docs/latest/commands/persist)
    /// - Version: 2.2.0
    /// - Complexity: O(1)
    /// - Categories: @keyspace, @write, @fast
    /// - Returns: One of the following:
    ///     * [Integer](https:/redis.io/docs/reference/protocol-spec#integers): `0` if _key_ does not exist or does not have an associated timeout.
    ///     * [Integer](https:/redis.io/docs/reference/protocol-spec#integers): `1` if the timeout has been removed.
    @inlinable
    public func persist(key: RedisKey) async throws -> Int {
        try await send("PERSIST", key).converting()
    }

    /// Sets the expiration time of a key in milliseconds.
    ///
    /// - Documentation: [PEXPIRE](https:/redis.io/docs/latest/commands/pexpire)
    /// - Version: 2.6.0
    /// - Complexity: O(1)
    /// - Categories: @keyspace, @write, @fast
    /// - Returns: One of the following:
    ///     * [Integer](https:/redis.io/docs/reference/protocol-spec#integers): `0`if the timeout was not set. For example, if the key doesn't exist, or the operation skipped because of the provided arguments.
    ///     * [Integer](https:/redis.io/docs/reference/protocol-spec#integers): `1` if the timeout was set.
    @inlinable
    public func pexpire(key: RedisKey, milliseconds: Int, condition: RESPCommand.PEXPIRECondition? = nil) async throws -> Int {
        try await send("PEXPIRE", key, milliseconds, condition).converting()
    }

    /// Sets the expiration time of a key to a Unix milliseconds timestamp.
    ///
    /// - Documentation: [PEXPIREAT](https:/redis.io/docs/latest/commands/pexpireat)
    /// - Version: 2.6.0
    /// - Complexity: O(1)
    /// - Categories: @keyspace, @write, @fast
    /// - Returns: One of the following:
    ///     * [Integer](https:/redis.io/docs/reference/protocol-spec#integers): `1` if the timeout was set.
    ///     * [Integer](https:/redis.io/docs/reference/protocol-spec#integers): `0` if the timeout was not set. For example, if the key doesn't exist, or the operation was skipped due to the provided arguments.
    @inlinable
    public func pexpireat(key: RedisKey, unixTimeMilliseconds: Date, condition: RESPCommand.PEXPIREATCondition? = nil) async throws -> Int {
        try await send("PEXPIREAT", key, unixTimeMilliseconds, condition).converting()
    }

    /// Returns the expiration time of a key as a Unix milliseconds timestamp.
    ///
    /// - Documentation: [PEXPIRETIME](https:/redis.io/docs/latest/commands/pexpiretime)
    /// - Version: 7.0.0
    /// - Complexity: O(1)
    /// - Categories: @keyspace, @read, @fast
    /// - Returns: One of the following:
    ///     * [Integer](https:/redis.io/docs/reference/protocol-spec#integers): Expiration Unix timestamp in milliseconds.
    ///     * [Integer](https:/redis.io/docs/reference/protocol-spec#integers): `-1` if the key exists but has no associated expiration time.
    ///     * [Integer](https:/redis.io/docs/reference/protocol-spec#integers): `-2` if the key does not exist.
    @inlinable
    public func pexpiretime(key: RedisKey) async throws -> Int {
        try await send("PEXPIRETIME", key).converting()
    }

    /// Adds elements to a HyperLogLog key. Creates the key if it doesn't exist.
    ///
    /// - Documentation: [PFADD](https:/redis.io/docs/latest/commands/pfadd)
    /// - Version: 2.8.9
    /// - Complexity: O(1) to add every element.
    /// - Categories: @write, @hyperloglog, @fast
    /// - Returns: One of the following:
    ///     * [Integer](https:/redis.io/docs/reference/protocol-spec#integers): `1` if at least one HyperLogLog internal register was altered.
    ///     * [Integer](https:/redis.io/docs/reference/protocol-spec#integers): `0` if no HyperLogLog internal registers were altered.
    @inlinable
    public func pfadd(key: RedisKey, element: String? = nil) async throws -> Int {
        try await send("PFADD", key, element).converting()
    }

    /// Adds elements to a HyperLogLog key. Creates the key if it doesn't exist.
    ///
    /// - Documentation: [PFADD](https:/redis.io/docs/latest/commands/pfadd)
    /// - Version: 2.8.9
    /// - Complexity: O(1) to add every element.
    /// - Categories: @write, @hyperloglog, @fast
    /// - Returns: One of the following:
    ///     * [Integer](https:/redis.io/docs/reference/protocol-spec#integers): `1` if at least one HyperLogLog internal register was altered.
    ///     * [Integer](https:/redis.io/docs/reference/protocol-spec#integers): `0` if no HyperLogLog internal registers were altered.
    @inlinable
    public func pfadd(key: RedisKey, elements: [String]) async throws -> Int {
        try await send("PFADD", key, elements).converting()
    }

    /// Returns the approximated cardinality of the set(s) observed by the HyperLogLog key(s).
    ///
    /// - Documentation: [PFCOUNT](https:/redis.io/docs/latest/commands/pfcount)
    /// - Version: 2.8.9
    /// - Complexity: O(1) with a very small average constant time when called with a single key. O(N) with N being the number of keys, and much bigger constant times, when called with multiple keys.
    /// - Categories: @read, @hyperloglog, @slow
    /// - Returns: [Integer](https:/redis.io/docs/reference/protocol-spec#integers): the approximated number of unique elements observed via `PFADD`
    @inlinable
    public func pfcount(key: RedisKey) async throws -> Int {
        try await send("PFCOUNT", key).converting()
    }

    /// Returns the approximated cardinality of the set(s) observed by the HyperLogLog key(s).
    ///
    /// - Documentation: [PFCOUNT](https:/redis.io/docs/latest/commands/pfcount)
    /// - Version: 2.8.9
    /// - Complexity: O(1) with a very small average constant time when called with a single key. O(N) with N being the number of keys, and much bigger constant times, when called with multiple keys.
    /// - Categories: @read, @hyperloglog, @slow
    /// - Returns: [Integer](https:/redis.io/docs/reference/protocol-spec#integers): the approximated number of unique elements observed via `PFADD`
    @inlinable
    public func pfcount(keys: [RedisKey]) async throws -> Int {
        try await send("PFCOUNT", keys).converting()
    }

    /// Merges one or more HyperLogLog values into a single key.
    ///
    /// - Documentation: [PFMERGE](https:/redis.io/docs/latest/commands/pfmerge)
    /// - Version: 2.8.9
    /// - Complexity: O(N) to merge N HyperLogLogs, but with high constant times.
    /// - Categories: @write, @hyperloglog, @slow
    /// - Returns: [Simple string](https:/redis.io/docs/reference/protocol-spec#simple-strings): `OK`.
    @inlinable
    public func pfmerge(destkey: RedisKey, sourcekey: RedisKey? = nil) async throws {
        try await send("PFMERGE", destkey, sourcekey)
    }

    /// Merges one or more HyperLogLog values into a single key.
    ///
    /// - Documentation: [PFMERGE](https:/redis.io/docs/latest/commands/pfmerge)
    /// - Version: 2.8.9
    /// - Complexity: O(N) to merge N HyperLogLogs, but with high constant times.
    /// - Categories: @write, @hyperloglog, @slow
    /// - Returns: [Simple string](https:/redis.io/docs/reference/protocol-spec#simple-strings): `OK`.
    @inlinable
    public func pfmerge(destkey: RedisKey, sourcekeys: [RedisKey]) async throws {
        try await send("PFMERGE", destkey, sourcekeys)
    }

    /// An internal command for testing HyperLogLog values.
    ///
    /// - Documentation: [PFSELFTEST](https:/redis.io/docs/latest/commands/pfselftest)
    /// - Version: 2.8.9
    /// - Complexity: N/A
    /// - Categories: @hyperloglog, @admin, @slow, @dangerous
    /// - Returns: [Simple string](https:/redis.io/docs/reference/protocol-spec#simple-strings): `OK`.
    @inlinable
    public func pfselftest() async throws {
        try await send("PFSELFTEST")
    }

    /// Returns the server's liveliness response.
    ///
    /// - Documentation: [PING](https:/redis.io/docs/latest/commands/ping)
    /// - Version: 1.0.0
    /// - Complexity: O(1)
    /// - Categories: @fast, @connection
    /// - Returns: Any of the following:
    ///     * [Simple string](https:/redis.io/docs/reference/protocol-spec#simple-strings): `PONG` when no argument is provided.
    ///     * [Bulk string](https:/redis.io/docs/reference/protocol-spec#bulk-strings): the provided argument.
    @inlinable
    public func ping(message: String? = nil) async throws -> String {
        try await send("PING", message).converting()
    }

    /// Sets both string value and expiration time in milliseconds of a key. The key is created if it doesn't exist.
    ///
    /// - Documentation: [PSETEX](https:/redis.io/docs/latest/commands/psetex)
    /// - Version: 2.6.0
    /// - Complexity: O(1)
    /// - Categories: @write, @string, @slow
    /// - Returns: [Simple string](https:/redis.io/docs/reference/protocol-spec#simple-strings): `OK`.
    @inlinable
    public func psetex(key: RedisKey, milliseconds: Int, value: String) async throws {
        try await send("PSETEX", key, milliseconds, value)
    }

    /// Listens for messages published to channels that match one or more patterns.
    ///
    /// - Documentation: [PSUBSCRIBE](https:/redis.io/docs/latest/commands/psubscribe)
    /// - Version: 2.0.0
    /// - Complexity: O(N) where N is the number of patterns to subscribe to.
    /// - Categories: @pubsub, @slow
    /// - Returns: When successful, this command doesn't return anything. Instead, for each pattern, one message with the first element being the string `psubscribe` is pushed as a confirmation that the command succeeded.
    @inlinable
    public func psubscribe(pattern: String) async throws -> RESPToken {
        try await send("PSUBSCRIBE", pattern)
    }

    /// Listens for messages published to channels that match one or more patterns.
    ///
    /// - Documentation: [PSUBSCRIBE](https:/redis.io/docs/latest/commands/psubscribe)
    /// - Version: 2.0.0
    /// - Complexity: O(N) where N is the number of patterns to subscribe to.
    /// - Categories: @pubsub, @slow
    /// - Returns: When successful, this command doesn't return anything. Instead, for each pattern, one message with the first element being the string `psubscribe` is pushed as a confirmation that the command succeeded.
    @inlinable
    public func psubscribe(patterns: [String]) async throws -> RESPToken {
        try await send("PSUBSCRIBE", patterns)
    }

    /// An internal command used in replication.
    ///
    /// - Documentation: [PSYNC](https:/redis.io/docs/latest/commands/psync)
    /// - Version: 2.8.0
    /// - Categories: @admin, @slow, @dangerous
    /// - Returns: **Non-standard return value**, a bulk transfer of the data followed by `PING` and write requests from the master.
    @inlinable
    public func psync(replicationid: String, offset: Int) async throws -> RESPToken {
        try await send("PSYNC", replicationid, offset)
    }

    /// Returns the expiration time in milliseconds of a key.
    ///
    /// - Documentation: [PTTL](https:/redis.io/docs/latest/commands/pttl)
    /// - Version: 2.6.0
    /// - Complexity: O(1)
    /// - Categories: @keyspace, @read, @fast
    /// - Returns: One of the following:
    ///     * [Integer](https:/redis.io/docs/reference/protocol-spec#integers): TTL in milliseconds.
    ///     * [Integer](https:/redis.io/docs/reference/protocol-spec#integers): `-1` if the key exists but has no associated expiration.
    ///     * [Integer](https:/redis.io/docs/reference/protocol-spec#integers): `-2` if the key does not exist.
    @inlinable
    public func pttl(key: RedisKey) async throws -> Int {
        try await send("PTTL", key).converting()
    }

    /// Posts a message to a channel.
    ///
    /// - Documentation: [PUBLISH](https:/redis.io/docs/latest/commands/publish)
    /// - Version: 2.0.0
    /// - Complexity: O(N+M) where N is the number of clients subscribed to the receiving channel and M is the total number of subscribed patterns (by any client).
    /// - Categories: @pubsub, @fast
    /// - Returns: [Integer](https:/redis.io/docs/reference/protocol-spec#integers): the number of clients that received the message. Note that in a Redis Cluster, only clients that are connected to the same node as the publishing client are included in the count.
    @inlinable
    public func publish(channel: String, message: String) async throws -> Int {
        try await send("PUBLISH", channel, message).converting()
    }

    /// Returns the active channels.
    ///
    /// - Documentation: [PUBSUB CHANNELS](https:/redis.io/docs/latest/commands/pubsub-channels)
    /// - Version: 2.8.0
    /// - Complexity: O(N) where N is the number of active channels, and assuming constant time pattern matching (relatively short channels and patterns)
    /// - Categories: @pubsub, @slow
    /// - Returns: [Array](https:/redis.io/docs/reference/protocol-spec#arrays): a list of active channels, optionally matching the specified pattern.
    @inlinable
    public func pubsubChannels(pattern: String? = nil) async throws -> [RESPToken] {
        try await send("PUBSUB", "CHANNELS", pattern).converting()
    }

    /// Returns helpful text about the different subcommands.
    ///
    /// - Documentation: [PUBSUB HELP](https:/redis.io/docs/latest/commands/pubsub-help)
    /// - Version: 6.2.0
    /// - Complexity: O(1)
    /// - Categories: @slow
    /// - Returns: [Array](https:/redis.io/docs/reference/protocol-spec#arrays): a list of sub-commands and their descriptions.
    @inlinable
    public func pubsubHelp() async throws -> [RESPToken] {
        try await send("PUBSUB", "HELP").converting()
    }

    /// Returns a count of unique pattern subscriptions.
    ///
    /// - Documentation: [PUBSUB NUMPAT](https:/redis.io/docs/latest/commands/pubsub-numpat)
    /// - Version: 2.8.0
    /// - Complexity: O(1)
    /// - Categories: @pubsub, @slow
    /// - Returns: [Integer](https:/redis.io/docs/reference/protocol-spec#integers): the number of patterns all the clients are subscribed to.
    @inlinable
    public func pubsubNumpat() async throws -> Int {
        try await send("PUBSUB", "NUMPAT").converting()
    }

    /// Returns a count of subscribers to channels.
    ///
    /// - Documentation: [PUBSUB NUMSUB](https:/redis.io/docs/latest/commands/pubsub-numsub)
    /// - Version: 2.8.0
    /// - Complexity: O(N) for the NUMSUB subcommand, where N is the number of requested channels
    /// - Categories: @pubsub, @slow
    /// - Returns: [Array](https:/redis.io/docs/reference/protocol-spec#arrays): the number of subscribers per channel, each even element (including the 0th) is channel name, each odd element is the number of subscribers
    @inlinable
    public func pubsubNumsub(channel: String? = nil) async throws -> [RESPToken] {
        try await send("PUBSUB", "NUMSUB", channel).converting()
    }

    /// Returns a count of subscribers to channels.
    ///
    /// - Documentation: [PUBSUB NUMSUB](https:/redis.io/docs/latest/commands/pubsub-numsub)
    /// - Version: 2.8.0
    /// - Complexity: O(N) for the NUMSUB subcommand, where N is the number of requested channels
    /// - Categories: @pubsub, @slow
    /// - Returns: [Array](https:/redis.io/docs/reference/protocol-spec#arrays): the number of subscribers per channel, each even element (including the 0th) is channel name, each odd element is the number of subscribers
    @inlinable
    public func pubsubNumsub(channels: [String]) async throws -> [RESPToken] {
        try await send("PUBSUB", "NUMSUB", channels).converting()
    }

    /// Returns the active shard channels.
    ///
    /// - Documentation: [PUBSUB SHARDCHANNELS](https:/redis.io/docs/latest/commands/pubsub-shardchannels)
    /// - Version: 7.0.0
    /// - Complexity: O(N) where N is the number of active shard channels, and assuming constant time pattern matching (relatively short shard channels).
    /// - Categories: @pubsub, @slow
    /// - Returns: [Array](https:/redis.io/docs/reference/protocol-spec#arrays): a list of active channels, optionally matching the specified pattern.
    @inlinable
    public func pubsubShardchannels(pattern: String? = nil) async throws -> [RESPToken] {
        try await send("PUBSUB", "SHARDCHANNELS", pattern).converting()
    }

    /// Returns the count of subscribers of shard channels.
    ///
    /// - Documentation: [PUBSUB SHARDNUMSUB](https:/redis.io/docs/latest/commands/pubsub-shardnumsub)
    /// - Version: 7.0.0
    /// - Complexity: O(N) for the SHARDNUMSUB subcommand, where N is the number of requested shard channels
    /// - Categories: @pubsub, @slow
    /// - Returns: [Array](https:/redis.io/docs/reference/protocol-spec#arrays): the number of subscribers per shard channel, each even element (including the 0th) is channel name, each odd element is the number of subscribers.
    @inlinable
    public func pubsubShardnumsub(shardchannel: String? = nil) async throws -> [RESPToken] {
        try await send("PUBSUB", "SHARDNUMSUB", shardchannel).converting()
    }

    /// Returns the count of subscribers of shard channels.
    ///
    /// - Documentation: [PUBSUB SHARDNUMSUB](https:/redis.io/docs/latest/commands/pubsub-shardnumsub)
    /// - Version: 7.0.0
    /// - Complexity: O(N) for the SHARDNUMSUB subcommand, where N is the number of requested shard channels
    /// - Categories: @pubsub, @slow
    /// - Returns: [Array](https:/redis.io/docs/reference/protocol-spec#arrays): the number of subscribers per shard channel, each even element (including the 0th) is channel name, each odd element is the number of subscribers.
    @inlinable
    public func pubsubShardnumsub(shardchannels: [String]) async throws -> [RESPToken] {
        try await send("PUBSUB", "SHARDNUMSUB", shardchannels).converting()
    }

    /// Stops listening to messages published to channels that match one or more patterns.
    ///
    /// - Documentation: [PUNSUBSCRIBE](https:/redis.io/docs/latest/commands/punsubscribe)
    /// - Version: 2.0.0
    /// - Complexity: O(N) where N is the number of patterns to unsubscribe.
    /// - Categories: @pubsub, @slow
    /// - Returns: When successful, this command doesn't return anything. Instead, for each pattern, one message with the first element being the string `punsubscribe` is pushed as a confirmation that the command succeeded.
    @inlinable
    public func punsubscribe(pattern: String? = nil) async throws -> RESPToken {
        try await send("PUNSUBSCRIBE", pattern)
    }

    /// Stops listening to messages published to channels that match one or more patterns.
    ///
    /// - Documentation: [PUNSUBSCRIBE](https:/redis.io/docs/latest/commands/punsubscribe)
    /// - Version: 2.0.0
    /// - Complexity: O(N) where N is the number of patterns to unsubscribe.
    /// - Categories: @pubsub, @slow
    /// - Returns: When successful, this command doesn't return anything. Instead, for each pattern, one message with the first element being the string `punsubscribe` is pushed as a confirmation that the command succeeded.
    @inlinable
    public func punsubscribe(patterns: [String]) async throws -> RESPToken {
        try await send("PUNSUBSCRIBE", patterns)
    }

    /// Closes the connection.
    ///
    /// - Documentation: [QUIT](https:/redis.io/docs/latest/commands/quit)
    /// - Version: 1.0.0
    /// - Complexity: O(1)
    /// - Categories: @fast, @connection
    /// - Returns: [Simple string](https:/redis.io/docs/reference/protocol-spec#simple-strings): `OK`.
    @inlinable
    public func quit() async throws {
        try await send("QUIT")
    }

    /// Returns a random key name from the database.
    ///
    /// - Documentation: [RANDOMKEY](https:/redis.io/docs/latest/commands/randomkey)
    /// - Version: 1.0.0
    /// - Complexity: O(1)
    /// - Categories: @keyspace, @read, @slow
    /// - Returns: One of the following:
    ///     * [Null](https:/redis.io/docs/reference/protocol-spec#nulls): when the database is empty.
    ///     * [Bulk string](https:/redis.io/docs/reference/protocol-spec#bulk-strings): a random key in the database.
    @inlinable
    public func randomkey() async throws -> String? {
        try await send("RANDOMKEY").converting()
    }

    /// Enables read-only queries for a connection to a Redis Cluster replica node.
    ///
    /// - Documentation: [READONLY](https:/redis.io/docs/latest/commands/readonly)
    /// - Version: 3.0.0
    /// - Complexity: O(1)
    /// - Categories: @fast, @connection
    /// - Returns: [Simple string](https:/redis.io/docs/reference/protocol-spec#simple-strings): `OK`.
    @inlinable
    public func readonly() async throws {
        try await send("READONLY")
    }

    /// Enables read-write queries for a connection to a Reids Cluster replica node.
    ///
    /// - Documentation: [READWRITE](https:/redis.io/docs/latest/commands/readwrite)
    /// - Version: 3.0.0
    /// - Complexity: O(1)
    /// - Categories: @fast, @connection
    /// - Returns: [Simple string](https:/redis.io/docs/reference/protocol-spec#simple-strings): `OK`.
    @inlinable
    public func readwrite() async throws {
        try await send("READWRITE")
    }

    /// Renames a key and overwrites the destination.
    ///
    /// - Documentation: [RENAME](https:/redis.io/docs/latest/commands/rename)
    /// - Version: 1.0.0
    /// - Complexity: O(1)
    /// - Categories: @keyspace, @write, @slow
    /// - Returns: [Simple string](https:/redis.io/docs/reference/protocol-spec#simple-strings): `OK`.
    @inlinable
    public func rename(key: RedisKey, newkey: RedisKey) async throws {
        try await send("RENAME", key, newkey)
    }

    /// Renames a key only when the target key name doesn't exist.
    ///
    /// - Documentation: [RENAMENX](https:/redis.io/docs/latest/commands/renamenx)
    /// - Version: 1.0.0
    /// - Complexity: O(1)
    /// - Categories: @keyspace, @write, @fast
    /// - Returns: One of the following:
    ///     * [Integer](https:/redis.io/docs/reference/protocol-spec#integers): `1` if _key_ was renamed to _newkey_.
    ///     * [Integer](https:/redis.io/docs/reference/protocol-spec#integers): `0` if _newkey_ already exists.
    @inlinable
    public func renamenx(key: RedisKey, newkey: RedisKey) async throws -> Int {
        try await send("RENAMENX", key, newkey).converting()
    }

    /// An internal command for configuring the replication stream.
    ///
    /// - Documentation: [REPLCONF](https:/redis.io/docs/latest/commands/replconf)
    /// - Version: 3.0.0
    /// - Complexity: O(1)
    /// - Categories: @admin, @slow, @dangerous
    /// - Returns: [Simple string](https:/redis.io/docs/reference/protocol-spec#simple-strings): `OK`.
    @inlinable
    public func replconf() async throws {
        try await send("REPLCONF")
    }

    /// Configures a server as replica of another, or promotes it to a master.
    ///
    /// - Documentation: [REPLICAOF](https:/redis.io/docs/latest/commands/replicaof)
    /// - Version: 5.0.0
    /// - Complexity: O(1)
    /// - Categories: @admin, @slow, @dangerous
    /// - Returns: [Simple string](https:/redis.io/docs/reference/protocol-spec#simple-strings): `OK`.
    @inlinable
    public func replicaof(args: RESPCommand.REPLICAOFArgs) async throws {
        try await send("REPLICAOF", args)
    }

    /// Resets the connection.
    ///
    /// - Documentation: [RESET](https:/redis.io/docs/latest/commands/reset)
    /// - Version: 6.2.0
    /// - Complexity: O(1)
    /// - Categories: @fast, @connection
    /// - Returns: [Simple string](https:/redis.io/docs/reference/protocol-spec#simple-strings): `RESET`.
    @inlinable
    public func reset() async throws -> String {
        try await send("RESET").converting()
    }

    /// Creates a key from the serialized representation of a value.
    ///
    /// - Documentation: [RESTORE](https:/redis.io/docs/latest/commands/restore)
    /// - Version: 2.6.0
    /// - Complexity: O(1) to create the new key and additional O(N*M) to reconstruct the serialized value, where N is the number of Redis objects composing the value and M their average size. For small string values the time complexity is thus O(1)+O(1*M) where M is small, so simply O(1). However for sorted set values the complexity is O(N*M*log(N)) because inserting values into sorted sets is O(log(N)).
    /// - Categories: @keyspace, @write, @slow, @dangerous
    /// - Returns: [Simple string](https:/redis.io/docs/reference/protocol-spec#simple-strings): `OK`.
    @inlinable
    public func restore(key: RedisKey, ttl: Int, serializedValue: String, replace: Bool = false, absttl: Bool = false, seconds: Int? = nil, frequency: Int? = nil) async throws {
        try await send("RESTORE", key, ttl, serializedValue, RedisPureToken("REPLACE", replace), RedisPureToken("ABSTTL", absttl), RESPWithToken("IDLETIME", seconds), RESPWithToken("FREQ", frequency))
    }

    /// An internal command for migrating keys in a cluster.
    ///
    /// - Documentation: [RESTORE-ASKING](https:/redis.io/docs/latest/commands/restore-asking)
    /// - Version: 3.0.0
    /// - Complexity: O(1) to create the new key and additional O(N*M) to reconstruct the serialized value, where N is the number of Redis objects composing the value and M their average size. For small string values the time complexity is thus O(1)+O(1*M) where M is small, so simply O(1). However for sorted set values the complexity is O(N*M*log(N)) because inserting values into sorted sets is O(log(N)).
    /// - Categories: @keyspace, @write, @slow, @dangerous
    /// - Returns: [Simple string](https:/redis.io/docs/reference/protocol-spec#simple-strings): `OK`.
    @inlinable
    public func restoreAsking(key: RedisKey, ttl: Int, serializedValue: String, replace: Bool = false, absttl: Bool = false, seconds: Int? = nil, frequency: Int? = nil) async throws {
        try await send("RESTORE-ASKING", key, ttl, serializedValue, RedisPureToken("REPLACE", replace), RedisPureToken("ABSTTL", absttl), RESPWithToken("IDLETIME", seconds), RESPWithToken("FREQ", frequency))
    }

    /// Returns the replication role.
    ///
    /// - Documentation: [ROLE](https:/redis.io/docs/latest/commands/role)
    /// - Version: 2.8.12
    /// - Complexity: O(1)
    /// - Categories: @admin, @fast, @dangerous
    /// - Returns: [Array](https:/redis.io/docs/reference/protocol-spec#arrays): where the first element is one of `master`, `slave`, or `sentinel`, and the additional elements are role-specific as illustrated above.
    @inlinable
    public func role() async throws -> [RESPToken] {
        try await send("ROLE").converting()
    }

    /// Returns and removes the last elements of a list. Deletes the list if the last element was popped.
    ///
    /// - Documentation: [RPOP](https:/redis.io/docs/latest/commands/rpop)
    /// - Version: 1.0.0
    /// - Complexity: O(N) where N is the number of elements returned
    /// - Categories: @write, @list, @fast
    /// - Returns: One of the following:
    ///     * [Null](https:/redis.io/docs/reference/protocol-spec#nulls): if the key does not exist.
    ///     * [Bulk string](https:/redis.io/docs/reference/protocol-spec#bulk-strings): when called without the _count_ argument, the value of the last element.
    ///     * [Array](https:/redis.io/docs/reference/protocol-spec#arrays): when called with the _count_ argument, a list of popped elements.
    @inlinable
    public func rpop(key: RedisKey, count: Int? = nil) async throws -> RESPToken {
        try await send("RPOP", key, count)
    }

    /// Returns the last element of a list after removing and pushing it to another list. Deletes the list if the last element was popped.
    ///
    /// - Documentation: [RPOPLPUSH](https:/redis.io/docs/latest/commands/rpoplpush)
    /// - Version: 1.2.0
    /// - Complexity: O(1)
    /// - Categories: @write, @list, @slow
    /// - Returns: One of the following:
    ///     * [Bulk string](https:/redis.io/docs/reference/protocol-spec#bulk-strings): the element being popped and pushed.
    ///     * [Null](https:/redis.io/docs/reference/protocol-spec#nulls): if the source list is empty.
    @inlinable
    public func rpoplpush(source: RedisKey, destination: RedisKey) async throws -> String? {
        try await send("RPOPLPUSH", source, destination).converting()
    }

    /// Appends one or more elements to a list. Creates the key if it doesn't exist.
    ///
    /// - Documentation: [RPUSH](https:/redis.io/docs/latest/commands/rpush)
    /// - Version: 1.0.0
    /// - Complexity: O(1) for each element added, so O(N) to add N elements when the command is called with multiple arguments.
    /// - Categories: @write, @list, @fast
    /// - Returns: [Integer](https:/redis.io/docs/reference/protocol-spec#integers): the length of the list after the push operation.
    @inlinable
    public func rpush(key: RedisKey, element: String) async throws -> Int {
        try await send("RPUSH", key, element).converting()
    }

    /// Appends one or more elements to a list. Creates the key if it doesn't exist.
    ///
    /// - Documentation: [RPUSH](https:/redis.io/docs/latest/commands/rpush)
    /// - Version: 1.0.0
    /// - Complexity: O(1) for each element added, so O(N) to add N elements when the command is called with multiple arguments.
    /// - Categories: @write, @list, @fast
    /// - Returns: [Integer](https:/redis.io/docs/reference/protocol-spec#integers): the length of the list after the push operation.
    @inlinable
    public func rpush(key: RedisKey, elements: [String]) async throws -> Int {
        try await send("RPUSH", key, elements).converting()
    }

    /// Appends an element to a list only when the list exists.
    ///
    /// - Documentation: [RPUSHX](https:/redis.io/docs/latest/commands/rpushx)
    /// - Version: 2.2.0
    /// - Complexity: O(1) for each element added, so O(N) to add N elements when the command is called with multiple arguments.
    /// - Categories: @write, @list, @fast
    /// - Returns: [Integer](https:/redis.io/docs/reference/protocol-spec#integers): the length of the list after the push operation.
    @inlinable
    public func rpushx(key: RedisKey, element: String) async throws -> Int {
        try await send("RPUSHX", key, element).converting()
    }

    /// Appends an element to a list only when the list exists.
    ///
    /// - Documentation: [RPUSHX](https:/redis.io/docs/latest/commands/rpushx)
    /// - Version: 2.2.0
    /// - Complexity: O(1) for each element added, so O(N) to add N elements when the command is called with multiple arguments.
    /// - Categories: @write, @list, @fast
    /// - Returns: [Integer](https:/redis.io/docs/reference/protocol-spec#integers): the length of the list after the push operation.
    @inlinable
    public func rpushx(key: RedisKey, elements: [String]) async throws -> Int {
        try await send("RPUSHX", key, elements).converting()
    }

    /// Adds one or more members to a set. Creates the key if it doesn't exist.
    ///
    /// - Documentation: [SADD](https:/redis.io/docs/latest/commands/sadd)
    /// - Version: 1.0.0
    /// - Complexity: O(1) for each element added, so O(N) to add N elements when the command is called with multiple arguments.
    /// - Categories: @write, @set, @fast
    /// - Returns: [Integer](https:/redis.io/docs/reference/protocol-spec#integers): the number of elements that were added to the set, not including all the elements already present in the set.
    @inlinable
    public func sadd(key: RedisKey, member: String) async throws -> Int {
        try await send("SADD", key, member).converting()
    }

    /// Adds one or more members to a set. Creates the key if it doesn't exist.
    ///
    /// - Documentation: [SADD](https:/redis.io/docs/latest/commands/sadd)
    /// - Version: 1.0.0
    /// - Complexity: O(1) for each element added, so O(N) to add N elements when the command is called with multiple arguments.
    /// - Categories: @write, @set, @fast
    /// - Returns: [Integer](https:/redis.io/docs/reference/protocol-spec#integers): the number of elements that were added to the set, not including all the elements already present in the set.
    @inlinable
    public func sadd(key: RedisKey, members: [String]) async throws -> Int {
        try await send("SADD", key, members).converting()
    }

    /// Synchronously saves the database(s) to disk.
    ///
    /// - Documentation: [SAVE](https:/redis.io/docs/latest/commands/save)
    /// - Version: 1.0.0
    /// - Complexity: O(N) where N is the total number of keys in all databases
    /// - Categories: @admin, @slow, @dangerous
    /// - Returns: [Simple string](https:/redis.io/docs/reference/protocol-spec#simple-strings): `OK`.
    @inlinable
    public func save() async throws {
        try await send("SAVE")
    }

    /// Iterates over the key names in the database.
    ///
    /// - Documentation: [SCAN](https:/redis.io/docs/latest/commands/scan)
    /// - Version: 2.8.0
    /// - Complexity: O(1) for every call. O(N) for a complete iteration, including enough command calls for the cursor to return back to 0. N is the number of elements inside the collection.
    /// - Categories: @keyspace, @read, @slow
    /// - Returns: [Array](https:/redis.io/docs/reference/protocol-spec#arrays): specifically, an array with two elements.
    ///     * The first element is a [Bulk string](https:/redis.io/docs/reference/protocol-spec#bulk-strings) that represents an unsigned 64-bit number, the cursor.
    ///     * The second element is an [Array](https:/redis.io/docs/reference/protocol-spec#arrays) with the names of scanned keys.
    @inlinable
    public func scan(cursor: Int, pattern: String? = nil, count: Int? = nil, type: String? = nil) async throws -> [RESPToken] {
        try await send("SCAN", cursor, RESPWithToken("MATCH", pattern), RESPWithToken("COUNT", count), RESPWithToken("TYPE", type)).converting()
    }

    /// Returns the number of members in a set.
    ///
    /// - Documentation: [SCARD](https:/redis.io/docs/latest/commands/scard)
    /// - Version: 1.0.0
    /// - Complexity: O(1)
    /// - Categories: @read, @set, @fast
    /// - Returns: [Integer](https:/redis.io/docs/reference/protocol-spec#integers): The cardinality (number of elements) of the set, or 0 if the key does not exist.
    @inlinable
    public func scard(key: RedisKey) async throws -> Int {
        try await send("SCARD", key).converting()
    }

    /// Sets the debug mode of server-side Lua scripts.
    ///
    /// - Documentation: [SCRIPT DEBUG](https:/redis.io/docs/latest/commands/script-debug)
    /// - Version: 3.2.0
    /// - Complexity: O(1)
    /// - Categories: @slow, @scripting
    /// - Returns: [Simple string](https:/redis.io/docs/reference/protocol-spec#simple-strings): `OK`.
    @inlinable
    public func scriptDebug(mode: RESPCommand.SCRIPTDEBUGMode) async throws {
        try await send("SCRIPT", "DEBUG", mode)
    }

    /// Determines whether server-side Lua scripts exist in the script cache.
    ///
    /// - Documentation: [SCRIPT EXISTS](https:/redis.io/docs/latest/commands/script-exists)
    /// - Version: 2.6.0
    /// - Complexity: O(N) with N being the number of scripts to check (so checking a single script is an O(1) operation).
    /// - Categories: @slow, @scripting
    /// - Returns: [Array](https:/redis.io/docs/reference/protocol-spec#arrays): an array of integers that correspond to the specified SHA1 digest arguments.
    @inlinable
    public func scriptExists(sha1: String) async throws -> [RESPToken] {
        try await send("SCRIPT", "EXISTS", sha1).converting()
    }

    /// Determines whether server-side Lua scripts exist in the script cache.
    ///
    /// - Documentation: [SCRIPT EXISTS](https:/redis.io/docs/latest/commands/script-exists)
    /// - Version: 2.6.0
    /// - Complexity: O(N) with N being the number of scripts to check (so checking a single script is an O(1) operation).
    /// - Categories: @slow, @scripting
    /// - Returns: [Array](https:/redis.io/docs/reference/protocol-spec#arrays): an array of integers that correspond to the specified SHA1 digest arguments.
    @inlinable
    public func scriptExists(sha1s: [String]) async throws -> [RESPToken] {
        try await send("SCRIPT", "EXISTS", sha1s).converting()
    }

    /// Removes all server-side Lua scripts from the script cache.
    ///
    /// - Documentation: [SCRIPT FLUSH](https:/redis.io/docs/latest/commands/script-flush)
    /// - Version: 2.6.0
    /// - Complexity: O(N) with N being the number of scripts in cache
    /// - Categories: @slow, @scripting
    /// - Returns: [Simple string](https:/redis.io/docs/reference/protocol-spec#simple-strings): `OK`.
    @inlinable
    public func scriptFlush(flushType: RESPCommand.SCRIPTFLUSHFlushType? = nil) async throws {
        try await send("SCRIPT", "FLUSH", flushType)
    }

    /// Returns helpful text about the different subcommands.
    ///
    /// - Documentation: [SCRIPT HELP](https:/redis.io/docs/latest/commands/script-help)
    /// - Version: 5.0.0
    /// - Complexity: O(1)
    /// - Categories: @slow, @scripting
    /// - Returns: [Array](https:/redis.io/docs/reference/protocol-spec#arrays): a list of sub-commands and their descriptions.
    @inlinable
    public func scriptHelp() async throws -> [RESPToken] {
        try await send("SCRIPT", "HELP").converting()
    }

    /// Terminates a server-side Lua script during execution.
    ///
    /// - Documentation: [SCRIPT KILL](https:/redis.io/docs/latest/commands/script-kill)
    /// - Version: 2.6.0
    /// - Complexity: O(1)
    /// - Categories: @slow, @scripting
    /// - Returns: [Simple string](https:/redis.io/docs/reference/protocol-spec#simple-strings): `OK`.
    @inlinable
    public func scriptKill() async throws {
        try await send("SCRIPT", "KILL")
    }

    /// Loads a server-side Lua script to the script cache.
    ///
    /// - Documentation: [SCRIPT LOAD](https:/redis.io/docs/latest/commands/script-load)
    /// - Version: 2.6.0
    /// - Complexity: O(N) with N being the length in bytes of the script body.
    /// - Categories: @slow, @scripting
    /// - Returns: [Bulk string](https:/redis.io/docs/reference/protocol-spec#bulk-strings): the SHA1 digest of the script added into the script cache.
    @inlinable
    public func scriptLoad(script: String) async throws -> String {
        try await send("SCRIPT", "LOAD", script).converting()
    }

    /// Returns the difference of multiple sets.
    ///
    /// - Documentation: [SDIFF](https:/redis.io/docs/latest/commands/sdiff)
    /// - Version: 1.0.0
    /// - Complexity: O(N) where N is the total number of elements in all given sets.
    /// - Categories: @read, @set, @slow
    /// - Returns: [Array](https:/redis.io/docs/reference/protocol-spec#arrays): a list with the members of the resulting set.
    @inlinable
    public func sdiff(key: RedisKey) async throws -> [RESPToken] {
        try await send("SDIFF", key).converting()
    }

    /// Returns the difference of multiple sets.
    ///
    /// - Documentation: [SDIFF](https:/redis.io/docs/latest/commands/sdiff)
    /// - Version: 1.0.0
    /// - Complexity: O(N) where N is the total number of elements in all given sets.
    /// - Categories: @read, @set, @slow
    /// - Returns: [Array](https:/redis.io/docs/reference/protocol-spec#arrays): a list with the members of the resulting set.
    @inlinable
    public func sdiff(keys: [RedisKey]) async throws -> [RESPToken] {
        try await send("SDIFF", keys).converting()
    }

    /// Stores the difference of multiple sets in a key.
    ///
    /// - Documentation: [SDIFFSTORE](https:/redis.io/docs/latest/commands/sdiffstore)
    /// - Version: 1.0.0
    /// - Complexity: O(N) where N is the total number of elements in all given sets.
    /// - Categories: @write, @set, @slow
    /// - Returns: [Integer](https:/redis.io/docs/reference/protocol-spec#integers): the number of elements in the resulting set.
    @inlinable
    public func sdiffstore(destination: RedisKey, key: RedisKey) async throws -> Int {
        try await send("SDIFFSTORE", destination, key).converting()
    }

    /// Stores the difference of multiple sets in a key.
    ///
    /// - Documentation: [SDIFFSTORE](https:/redis.io/docs/latest/commands/sdiffstore)
    /// - Version: 1.0.0
    /// - Complexity: O(N) where N is the total number of elements in all given sets.
    /// - Categories: @write, @set, @slow
    /// - Returns: [Integer](https:/redis.io/docs/reference/protocol-spec#integers): the number of elements in the resulting set.
    @inlinable
    public func sdiffstore(destination: RedisKey, keys: [RedisKey]) async throws -> Int {
        try await send("SDIFFSTORE", destination, keys).converting()
    }

    /// Changes the selected database.
    ///
    /// - Documentation: [SELECT](https:/redis.io/docs/latest/commands/select)
    /// - Version: 1.0.0
    /// - Complexity: O(1)
    /// - Categories: @fast, @connection
    /// - Returns: [Simple string](https:/redis.io/docs/reference/protocol-spec#simple-strings): `OK`.
    @inlinable
    public func select(index: Int) async throws {
        try await send("SELECT", index)
    }

    /// Sets the string value of a key, ignoring its type. The key is created if it doesn't exist.
    ///
    /// - Documentation: [SET](https:/redis.io/docs/latest/commands/set)
    /// - Version: 1.0.0
    /// - Complexity: O(1)
    /// - Categories: @write, @string, @slow
    /// - Returns: Any of the following:
    ///     * [Null](https:/redis.io/docs/reference/protocol-spec#nulls): `GET` not given: Operation was aborted (conflict with one of the `XX`/`NX` options).
    ///     * [Simple string](https:/redis.io/docs/reference/protocol-spec#simple-strings): `OK`. `GET` not given: The key was set.
    ///     * [Null](https:/redis.io/docs/reference/protocol-spec#nulls): `GET` given: The key didn't exist before the `SET`.
    ///     * [Bulk string](https:/redis.io/docs/reference/protocol-spec#bulk-strings): `GET` given: The previous value of the key.
    @inlinable
    public func set(key: RedisKey, value: String, condition: RESPCommand.SETCondition? = nil, get: Bool = false, expiration: RESPCommand.SETExpiration? = nil) async throws -> String? {
        try await send("SET", key, value, condition, RedisPureToken("GET", get), expiration).converting()
    }

    /// Sets or clears the bit at offset of the string value. Creates the key if it doesn't exist.
    ///
    /// - Documentation: [SETBIT](https:/redis.io/docs/latest/commands/setbit)
    /// - Version: 2.2.0
    /// - Complexity: O(1)
    /// - Categories: @write, @bitmap, @slow
    /// - Returns: [Integer](https:/redis.io/docs/reference/protocol-spec#integers): the original bit value stored at _offset_.
    @inlinable
    public func setbit(key: RedisKey, offset: Int, value: Int) async throws -> Int {
        try await send("SETBIT", key, offset, value).converting()
    }

    /// Sets the string value and expiration time of a key. Creates the key if it doesn't exist.
    ///
    /// - Documentation: [SETEX](https:/redis.io/docs/latest/commands/setex)
    /// - Version: 2.0.0
    /// - Complexity: O(1)
    /// - Categories: @write, @string, @slow
    /// - Returns: [Simple string](https:/redis.io/docs/reference/protocol-spec#simple-strings): `OK`.
    @inlinable
    public func setex(key: RedisKey, seconds: Int, value: String) async throws {
        try await send("SETEX", key, seconds, value)
    }

    /// Set the string value of a key only when the key doesn't exist.
    ///
    /// - Documentation: [SETNX](https:/redis.io/docs/latest/commands/setnx)
    /// - Version: 1.0.0
    /// - Complexity: O(1)
    /// - Categories: @write, @string, @fast
    /// - Returns: One of the following:
    ///     * [Integer](https:/redis.io/docs/reference/protocol-spec#integers): `0` if the key was not set.
    ///     * [Integer](https:/redis.io/docs/reference/protocol-spec#integers): `1` if the key was set.
    @inlinable
    public func setnx(key: RedisKey, value: String) async throws -> Int {
        try await send("SETNX", key, value).converting()
    }

    /// Overwrites a part of a string value with another by an offset. Creates the key if it doesn't exist.
    ///
    /// - Documentation: [SETRANGE](https:/redis.io/docs/latest/commands/setrange)
    /// - Version: 2.2.0
    /// - Complexity: O(1), not counting the time taken to copy the new string in place. Usually, this string is very small so the amortized complexity is O(1). Otherwise, complexity is O(M) with M being the length of the value argument.
    /// - Categories: @write, @string, @slow
    /// - Returns: [Integer](https:/redis.io/docs/reference/protocol-spec#integers): the length of the string after it was modified by the command.
    @inlinable
    public func setrange(key: RedisKey, offset: Int, value: String) async throws -> Int {
        try await send("SETRANGE", key, offset, value).converting()
    }

    /// Synchronously saves the database(s) to disk and shuts down the Redis server.
    ///
    /// - Documentation: [SHUTDOWN](https:/redis.io/docs/latest/commands/shutdown)
    /// - Version: 1.0.0
    /// - Complexity: O(N) when saving, where N is the total number of keys in all databases when saving data, otherwise O(1)
    /// - Categories: @admin, @slow, @dangerous
    /// - Returns: [Simple string](https:/redis.io/docs/reference/protocol-spec#simple-strings): `OK` if _ABORT_ was specified and shutdown was aborted. On successful shutdown, nothing is returned because the server quits and the connection is closed. On failure, an error is returned.
    @inlinable
    public func shutdown(saveSelector: RESPCommand.SHUTDOWNSaveSelector? = nil, now: Bool = false, force: Bool = false, abort: Bool = false) async throws {
        try await send("SHUTDOWN", saveSelector, RedisPureToken("NOW", now), RedisPureToken("FORCE", force), RedisPureToken("ABORT", abort))
    }

    /// Returns the intersect of multiple sets.
    ///
    /// - Documentation: [SINTER](https:/redis.io/docs/latest/commands/sinter)
    /// - Version: 1.0.0
    /// - Complexity: O(N*M) worst case where N is the cardinality of the smallest set and M is the number of sets.
    /// - Categories: @read, @set, @slow
    /// - Returns: [Array](https:/redis.io/docs/reference/protocol-spec#arrays): a list with the members of the resulting set.
    @inlinable
    public func sinter(key: RedisKey) async throws -> [RESPToken] {
        try await send("SINTER", key).converting()
    }

    /// Returns the intersect of multiple sets.
    ///
    /// - Documentation: [SINTER](https:/redis.io/docs/latest/commands/sinter)
    /// - Version: 1.0.0
    /// - Complexity: O(N*M) worst case where N is the cardinality of the smallest set and M is the number of sets.
    /// - Categories: @read, @set, @slow
    /// - Returns: [Array](https:/redis.io/docs/reference/protocol-spec#arrays): a list with the members of the resulting set.
    @inlinable
    public func sinter(keys: [RedisKey]) async throws -> [RESPToken] {
        try await send("SINTER", keys).converting()
    }

    /// Returns the number of members of the intersect of multiple sets.
    ///
    /// - Documentation: [SINTERCARD](https:/redis.io/docs/latest/commands/sintercard)
    /// - Version: 7.0.0
    /// - Complexity: O(N*M) worst case where N is the cardinality of the smallest set and M is the number of sets.
    /// - Categories: @read, @set, @slow
    /// - Returns: [Integer](https:/redis.io/docs/reference/protocol-spec#integers): the number of the elements in the resulting intersection.
    @inlinable
    public func sintercard(key: RedisKey, limit: Int? = nil) async throws -> Int {
        try await send("SINTERCARD", 1, key, RESPWithToken("LIMIT", limit)).converting()
    }

    /// Returns the number of members of the intersect of multiple sets.
    ///
    /// - Documentation: [SINTERCARD](https:/redis.io/docs/latest/commands/sintercard)
    /// - Version: 7.0.0
    /// - Complexity: O(N*M) worst case where N is the cardinality of the smallest set and M is the number of sets.
    /// - Categories: @read, @set, @slow
    /// - Returns: [Integer](https:/redis.io/docs/reference/protocol-spec#integers): the number of the elements in the resulting intersection.
    @inlinable
    public func sintercard(keys: [RedisKey], limit: Int? = nil) async throws -> Int {
        try await send("SINTERCARD", RESPArrayWithCount(keys), RESPWithToken("LIMIT", limit)).converting()
    }

    /// Stores the intersect of multiple sets in a key.
    ///
    /// - Documentation: [SINTERSTORE](https:/redis.io/docs/latest/commands/sinterstore)
    /// - Version: 1.0.0
    /// - Complexity: O(N*M) worst case where N is the cardinality of the smallest set and M is the number of sets.
    /// - Categories: @write, @set, @slow
    /// - Returns: [Integer](https:/redis.io/docs/reference/protocol-spec#integers): the number of the elements in the result set.
    @inlinable
    public func sinterstore(destination: RedisKey, key: RedisKey) async throws -> Int {
        try await send("SINTERSTORE", destination, key).converting()
    }

    /// Stores the intersect of multiple sets in a key.
    ///
    /// - Documentation: [SINTERSTORE](https:/redis.io/docs/latest/commands/sinterstore)
    /// - Version: 1.0.0
    /// - Complexity: O(N*M) worst case where N is the cardinality of the smallest set and M is the number of sets.
    /// - Categories: @write, @set, @slow
    /// - Returns: [Integer](https:/redis.io/docs/reference/protocol-spec#integers): the number of the elements in the result set.
    @inlinable
    public func sinterstore(destination: RedisKey, keys: [RedisKey]) async throws -> Int {
        try await send("SINTERSTORE", destination, keys).converting()
    }

    /// Determines whether a member belongs to a set.
    ///
    /// - Documentation: [SISMEMBER](https:/redis.io/docs/latest/commands/sismember)
    /// - Version: 1.0.0
    /// - Complexity: O(1)
    /// - Categories: @read, @set, @fast
    /// - Returns: One of the following:
    ///     * [Integer](https:/redis.io/docs/reference/protocol-spec#integers): `0` if the element is not a member of the set, or when the key does not exist.
    ///     * [Integer](https:/redis.io/docs/reference/protocol-spec#integers): `1` if the element is a member of the set.
    @inlinable
    public func sismember(key: RedisKey, member: String) async throws -> Int {
        try await send("SISMEMBER", key, member).converting()
    }

    /// Sets a Redis server as a replica of another, or promotes it to being a master.
    ///
    /// - Documentation: [SLAVEOF](https:/redis.io/docs/latest/commands/slaveof)
    /// - Version: 1.0.0
    /// - Complexity: O(1)
    /// - Categories: @admin, @slow, @dangerous
    /// - Returns: [Simple string](https:/redis.io/docs/reference/protocol-spec#simple-strings): `OK`.
    @inlinable
    public func slaveof(args: RESPCommand.SLAVEOFArgs) async throws {
        try await send("SLAVEOF", args)
    }

    /// Returns the slow log's entries.
    ///
    /// - Documentation: [SLOWLOG GET](https:/redis.io/docs/latest/commands/slowlog-get)
    /// - Version: 2.2.12
    /// - Complexity: O(N) where N is the number of entries returned
    /// - Categories: @admin, @slow, @dangerous
    /// - Returns: [Array](https:/redis.io/docs/reference/protocol-spec#arrays): a list of slow log entries per the above format.
    @inlinable
    public func slowlogGet(count: Int? = nil) async throws -> [RESPToken] {
        try await send("SLOWLOG", "GET", count).converting()
    }

    /// Show helpful text about the different subcommands
    ///
    /// - Documentation: [SLOWLOG HELP](https:/redis.io/docs/latest/commands/slowlog-help)
    /// - Version: 6.2.0
    /// - Complexity: O(1)
    /// - Categories: @slow
    /// - Returns: [Array](https:/redis.io/docs/reference/protocol-spec#arrays): a list of sub-commands and their descriptions.
    @inlinable
    public func slowlogHelp() async throws -> [RESPToken] {
        try await send("SLOWLOG", "HELP").converting()
    }

    /// Returns the number of entries in the slow log.
    ///
    /// - Documentation: [SLOWLOG LEN](https:/redis.io/docs/latest/commands/slowlog-len)
    /// - Version: 2.2.12
    /// - Complexity: O(1)
    /// - Categories: @admin, @slow, @dangerous
    /// - Returns: [Integer](https:/redis.io/docs/reference/protocol-spec#integers): the number of entries in the slow log.
    @inlinable
    public func slowlogLen() async throws -> Int {
        try await send("SLOWLOG", "LEN").converting()
    }

    /// Clears all entries from the slow log.
    ///
    /// - Documentation: [SLOWLOG RESET](https:/redis.io/docs/latest/commands/slowlog-reset)
    /// - Version: 2.2.12
    /// - Complexity: O(N) where N is the number of entries in the slowlog
    /// - Categories: @admin, @slow, @dangerous
    /// - Returns: [Simple string](https:/redis.io/docs/reference/protocol-spec#simple-strings): `OK`.
    @inlinable
    public func slowlogReset() async throws {
        try await send("SLOWLOG", "RESET")
    }

    /// Returns all members of a set.
    ///
    /// - Documentation: [SMEMBERS](https:/redis.io/docs/latest/commands/smembers)
    /// - Version: 1.0.0
    /// - Complexity: O(N) where N is the set cardinality.
    /// - Categories: @read, @set, @slow
    /// - Returns: [Array](https:/redis.io/docs/reference/protocol-spec#arrays): all members of the set.
    @inlinable
    public func smembers(key: RedisKey) async throws -> [RESPToken] {
        try await send("SMEMBERS", key).converting()
    }

    /// Determines whether multiple members belong to a set.
    ///
    /// - Documentation: [SMISMEMBER](https:/redis.io/docs/latest/commands/smismember)
    /// - Version: 6.2.0
    /// - Complexity: O(N) where N is the number of elements being checked for membership
    /// - Categories: @read, @set, @fast
    /// - Returns: [Array](https:/redis.io/docs/reference/protocol-spec#arrays): a list representing the membership of the given elements, in the same order as they are requested.
    @inlinable
    public func smismember(key: RedisKey, member: String) async throws -> [RESPToken] {
        try await send("SMISMEMBER", key, member).converting()
    }

    /// Determines whether multiple members belong to a set.
    ///
    /// - Documentation: [SMISMEMBER](https:/redis.io/docs/latest/commands/smismember)
    /// - Version: 6.2.0
    /// - Complexity: O(N) where N is the number of elements being checked for membership
    /// - Categories: @read, @set, @fast
    /// - Returns: [Array](https:/redis.io/docs/reference/protocol-spec#arrays): a list representing the membership of the given elements, in the same order as they are requested.
    @inlinable
    public func smismember(key: RedisKey, members: [String]) async throws -> [RESPToken] {
        try await send("SMISMEMBER", key, members).converting()
    }

    /// Moves a member from one set to another.
    ///
    /// - Documentation: [SMOVE](https:/redis.io/docs/latest/commands/smove)
    /// - Version: 1.0.0
    /// - Complexity: O(1)
    /// - Categories: @write, @set, @fast
    /// - Returns: One of the following:
    ///     * [Integer](https:/redis.io/docs/reference/protocol-spec#integers): `1` if the element is moved.
    ///     * [Integer](https:/redis.io/docs/reference/protocol-spec#integers): `0` if the element is not a member of _source_ and no operation was performed.
    @inlinable
    public func smove(source: RedisKey, destination: RedisKey, member: String) async throws -> Int {
        try await send("SMOVE", source, destination, member).converting()
    }

    /// Sorts the elements in a list, a set, or a sorted set, optionally storing the result.
    ///
    /// - Documentation: [SORT](https:/redis.io/docs/latest/commands/sort)
    /// - Version: 1.0.0
    /// - Complexity: O(N+M*log(M)) where N is the number of elements in the list or set to sort, and M the number of returned elements. When the elements are not sorted, complexity is O(N).
    /// - Categories: @write, @set, @sortedset, @list, @slow, @dangerous
    /// - Returns: [Array](https:/redis.io/docs/reference/protocol-spec#arrays): without passing the _STORE_ option, the command returns a list of sorted elements.
    ///     [Integer](https:/redis.io/docs/reference/protocol-spec#integers): when the _STORE_ option is specified, the command returns the number of sorted elements in the destination list.
    @inlinable
    public func sort(key: RedisKey, byPattern: String? = nil, limit: RESPCommand.SORTLimit? = nil, getPattern: String? = nil, order: RESPCommand.SORTOrder? = nil, sorting: Bool = false, destination: RedisKey? = nil) async throws -> RESPToken {
        try await send("SORT", key, RESPWithToken("BY", byPattern), RESPWithToken("LIMIT", limit), RESPWithToken("GET", getPattern), order, RedisPureToken("ALPHA", sorting), RESPWithToken("STORE", destination))
    }

    /// Sorts the elements in a list, a set, or a sorted set, optionally storing the result.
    ///
    /// - Documentation: [SORT](https:/redis.io/docs/latest/commands/sort)
    /// - Version: 1.0.0
    /// - Complexity: O(N+M*log(M)) where N is the number of elements in the list or set to sort, and M the number of returned elements. When the elements are not sorted, complexity is O(N).
    /// - Categories: @write, @set, @sortedset, @list, @slow, @dangerous
    /// - Returns: [Array](https:/redis.io/docs/reference/protocol-spec#arrays): without passing the _STORE_ option, the command returns a list of sorted elements.
    ///     [Integer](https:/redis.io/docs/reference/protocol-spec#integers): when the _STORE_ option is specified, the command returns the number of sorted elements in the destination list.
    @inlinable
    public func sort(key: RedisKey, byPattern: String? = nil, limit: RESPCommand.SORTLimit? = nil, getPatterns: [String], order: RESPCommand.SORTOrder? = nil, sorting: Bool = false, destination: RedisKey? = nil) async throws -> RESPToken {
        try await send("SORT", key, RESPWithToken("BY", byPattern), RESPWithToken("LIMIT", limit), RESPWithToken("GET", getPatterns), order, RedisPureToken("ALPHA", sorting), RESPWithToken("STORE", destination))
    }

    /// Returns the sorted elements of a list, a set, or a sorted set.
    ///
    /// - Documentation: [SORT_RO](https:/redis.io/docs/latest/commands/sort_ro)
    /// - Version: 7.0.0
    /// - Complexity: O(N+M*log(M)) where N is the number of elements in the list or set to sort, and M the number of returned elements. When the elements are not sorted, complexity is O(N).
    /// - Categories: @read, @set, @sortedset, @list, @slow, @dangerous
    /// - Returns: [Array](https:/redis.io/docs/reference/protocol-spec#arrays): a list of sorted elements.
    @inlinable
    public func sortRo(key: RedisKey, byPattern: String? = nil, limit: RESPCommand.SORTROLimit? = nil, getPattern: String? = nil, order: RESPCommand.SORTROOrder? = nil, sorting: Bool = false) async throws -> [RESPToken] {
        try await send("SORT_RO", key, RESPWithToken("BY", byPattern), RESPWithToken("LIMIT", limit), RESPWithToken("GET", getPattern), order, RedisPureToken("ALPHA", sorting)).converting()
    }

    /// Returns the sorted elements of a list, a set, or a sorted set.
    ///
    /// - Documentation: [SORT_RO](https:/redis.io/docs/latest/commands/sort_ro)
    /// - Version: 7.0.0
    /// - Complexity: O(N+M*log(M)) where N is the number of elements in the list or set to sort, and M the number of returned elements. When the elements are not sorted, complexity is O(N).
    /// - Categories: @read, @set, @sortedset, @list, @slow, @dangerous
    /// - Returns: [Array](https:/redis.io/docs/reference/protocol-spec#arrays): a list of sorted elements.
    @inlinable
    public func sortRo(key: RedisKey, byPattern: String? = nil, limit: RESPCommand.SORTROLimit? = nil, getPatterns: [String], order: RESPCommand.SORTROOrder? = nil, sorting: Bool = false) async throws -> [RESPToken] {
        try await send("SORT_RO", key, RESPWithToken("BY", byPattern), RESPWithToken("LIMIT", limit), RESPWithToken("GET", getPatterns), order, RedisPureToken("ALPHA", sorting)).converting()
    }

    /// Returns one or more random members from a set after removing them. Deletes the set if the last member was popped.
    ///
    /// - Documentation: [SPOP](https:/redis.io/docs/latest/commands/spop)
    /// - Version: 1.0.0
    /// - Complexity: Without the count argument O(1), otherwise O(N) where N is the value of the passed count.
    /// - Categories: @write, @set, @fast
    /// - Returns: One of the following:
    ///     * [Null](https:/redis.io/docs/reference/protocol-spec#nulls): if the key does not exist.
    ///     * [Bulk string](https:/redis.io/docs/reference/protocol-spec#bulk-strings): when called without the _count_ argument, the removed member.
    ///     * [Array](https:/redis.io/docs/reference/protocol-spec#arrays): when called with the _count_ argument, a list of the removed members.
    @inlinable
    public func spop(key: RedisKey, count: Int? = nil) async throws -> RESPToken {
        try await send("SPOP", key, count)
    }

    /// Post a message to a shard channel
    ///
    /// - Documentation: [SPUBLISH](https:/redis.io/docs/latest/commands/spublish)
    /// - Version: 7.0.0
    /// - Complexity: O(N) where N is the number of clients subscribed to the receiving shard channel.
    /// - Categories: @pubsub, @fast
    /// - Returns: [Integer](https:/redis.io/docs/reference/protocol-spec#integers): the number of clients that received the message. Note that in a Redis Cluster, only clients that are connected to the same node as the publishing client are included in the count
    @inlinable
    public func spublish(shardchannel: String, message: String) async throws -> Int {
        try await send("SPUBLISH", shardchannel, message).converting()
    }

    /// Get one or multiple random members from a set
    ///
    /// - Documentation: [SRANDMEMBER](https:/redis.io/docs/latest/commands/srandmember)
    /// - Version: 1.0.0
    /// - Complexity: Without the count argument O(1), otherwise O(N) where N is the absolute value of the passed count.
    /// - Categories: @read, @set, @slow
    /// - Returns: One of the following:
    ///     * [Bulk string](https:/redis.io/docs/reference/protocol-spec#bulk-strings): without the additional _count_ argument, the command returns a randomly selected member, or a [Null](https:/redis.io/docs/reference/protocol-spec#nulls) when _key_ doesn't exist.
    ///     * [Array](https:/redis.io/docs/reference/protocol-spec#arrays): when the optional _count_ argument is passed, the command returns an array of members, or an empty array when _key_ doesn't exist.
    @inlinable
    public func srandmember(key: RedisKey, count: Int? = nil) async throws -> RESPToken {
        try await send("SRANDMEMBER", key, count)
    }

    /// Removes one or more members from a set. Deletes the set if the last member was removed.
    ///
    /// - Documentation: [SREM](https:/redis.io/docs/latest/commands/srem)
    /// - Version: 1.0.0
    /// - Complexity: O(N) where N is the number of members to be removed.
    /// - Categories: @write, @set, @fast
    /// - Returns: [Integer](https:/redis.io/docs/reference/protocol-spec#integers): Number of members that were removed from the set, not including non existing members.
    @inlinable
    public func srem(key: RedisKey, member: String) async throws -> Int {
        try await send("SREM", key, member).converting()
    }

    /// Removes one or more members from a set. Deletes the set if the last member was removed.
    ///
    /// - Documentation: [SREM](https:/redis.io/docs/latest/commands/srem)
    /// - Version: 1.0.0
    /// - Complexity: O(N) where N is the number of members to be removed.
    /// - Categories: @write, @set, @fast
    /// - Returns: [Integer](https:/redis.io/docs/reference/protocol-spec#integers): Number of members that were removed from the set, not including non existing members.
    @inlinable
    public func srem(key: RedisKey, members: [String]) async throws -> Int {
        try await send("SREM", key, members).converting()
    }

    /// Iterates over members of a set.
    ///
    /// - Documentation: [SSCAN](https:/redis.io/docs/latest/commands/sscan)
    /// - Version: 2.8.0
    /// - Complexity: O(1) for every call. O(N) for a complete iteration, including enough command calls for the cursor to return back to 0. N is the number of elements inside the collection.
    /// - Categories: @read, @set, @slow
    /// - Returns: [Array](https:/redis.io/docs/reference/protocol-spec#arrays): specifically, an array with two elements:
    ///     * The first element is a [Bulk string](https:/redis.io/docs/reference/protocol-spec#bulk-strings) that represents an unsigned 64-bit number, the cursor.
    ///     * The second element is an [Array](https:/redis.io/docs/reference/protocol-spec#arrays) with the names of scanned members.
    @inlinable
    public func sscan(key: RedisKey, cursor: Int, pattern: String? = nil, count: Int? = nil) async throws -> [RESPToken] {
        try await send("SSCAN", key, cursor, RESPWithToken("MATCH", pattern), RESPWithToken("COUNT", count)).converting()
    }

    /// Listens for messages published to shard channels.
    ///
    /// - Documentation: [SSUBSCRIBE](https:/redis.io/docs/latest/commands/ssubscribe)
    /// - Version: 7.0.0
    /// - Complexity: O(N) where N is the number of shard channels to subscribe to.
    /// - Categories: @pubsub, @slow
    /// - Returns: When successful, this command doesn't return anything. Instead, for each shard channel, one message with the first element being the string 'ssubscribe' is pushed as a confirmation that the command succeeded. Note that this command can also return a -MOVED redirect.
    @inlinable
    public func ssubscribe(shardchannel: String) async throws -> RESPToken {
        try await send("SSUBSCRIBE", shardchannel)
    }

    /// Listens for messages published to shard channels.
    ///
    /// - Documentation: [SSUBSCRIBE](https:/redis.io/docs/latest/commands/ssubscribe)
    /// - Version: 7.0.0
    /// - Complexity: O(N) where N is the number of shard channels to subscribe to.
    /// - Categories: @pubsub, @slow
    /// - Returns: When successful, this command doesn't return anything. Instead, for each shard channel, one message with the first element being the string 'ssubscribe' is pushed as a confirmation that the command succeeded. Note that this command can also return a -MOVED redirect.
    @inlinable
    public func ssubscribe(shardchannels: [String]) async throws -> RESPToken {
        try await send("SSUBSCRIBE", shardchannels)
    }

    /// Returns the length of a string value.
    ///
    /// - Documentation: [STRLEN](https:/redis.io/docs/latest/commands/strlen)
    /// - Version: 2.2.0
    /// - Complexity: O(1)
    /// - Categories: @read, @string, @fast
    /// - Returns: [Integer](https:/redis.io/docs/reference/protocol-spec#integers): the length of the string stored at key, or 0 when the key does not exist.
    @inlinable
    public func strlen(key: RedisKey) async throws -> Int {
        try await send("STRLEN", key).converting()
    }

    /// Listens for messages published to channels.
    ///
    /// - Documentation: [SUBSCRIBE](https:/redis.io/docs/latest/commands/subscribe)
    /// - Version: 2.0.0
    /// - Complexity: O(N) where N is the number of channels to subscribe to.
    /// - Categories: @pubsub, @slow
    /// - Returns: When successful, this command doesn't return anything. Instead, for each channel, one message with the first element being the string `subscribe` is pushed as a confirmation that the command succeeded.
    @inlinable
    public func subscribe(channel: String) async throws -> RESPToken {
        try await send("SUBSCRIBE", channel)
    }

    /// Listens for messages published to channels.
    ///
    /// - Documentation: [SUBSCRIBE](https:/redis.io/docs/latest/commands/subscribe)
    /// - Version: 2.0.0
    /// - Complexity: O(N) where N is the number of channels to subscribe to.
    /// - Categories: @pubsub, @slow
    /// - Returns: When successful, this command doesn't return anything. Instead, for each channel, one message with the first element being the string `subscribe` is pushed as a confirmation that the command succeeded.
    @inlinable
    public func subscribe(channels: [String]) async throws -> RESPToken {
        try await send("SUBSCRIBE", channels)
    }

    /// Returns a substring from a string value.
    ///
    /// - Documentation: [SUBSTR](https:/redis.io/docs/latest/commands/substr)
    /// - Version: 1.0.0
    /// - Complexity: O(N) where N is the length of the returned string. The complexity is ultimately determined by the returned length, but because creating a substring from an existing string is very cheap, it can be considered O(1) for small strings.
    /// - Categories: @read, @string, @slow
    /// - Returns: [Bulk string](https:/redis.io/docs/reference/protocol-spec#bulk-strings): the substring of the string value stored at key, determined by the offsets start and end (both are inclusive).
    @inlinable
    public func substr(key: RedisKey, start: Int, end: Int) async throws -> String {
        try await send("SUBSTR", key, start, end).converting()
    }

    /// Returns the union of multiple sets.
    ///
    /// - Documentation: [SUNION](https:/redis.io/docs/latest/commands/sunion)
    /// - Version: 1.0.0
    /// - Complexity: O(N) where N is the total number of elements in all given sets.
    /// - Categories: @read, @set, @slow
    /// - Returns: [Array](https:/redis.io/docs/reference/protocol-spec#arrays): a list with the members of the resulting set.
    @inlinable
    public func sunion(key: RedisKey) async throws -> [RESPToken] {
        try await send("SUNION", key).converting()
    }

    /// Returns the union of multiple sets.
    ///
    /// - Documentation: [SUNION](https:/redis.io/docs/latest/commands/sunion)
    /// - Version: 1.0.0
    /// - Complexity: O(N) where N is the total number of elements in all given sets.
    /// - Categories: @read, @set, @slow
    /// - Returns: [Array](https:/redis.io/docs/reference/protocol-spec#arrays): a list with the members of the resulting set.
    @inlinable
    public func sunion(keys: [RedisKey]) async throws -> [RESPToken] {
        try await send("SUNION", keys).converting()
    }

    /// Stores the union of multiple sets in a key.
    ///
    /// - Documentation: [SUNIONSTORE](https:/redis.io/docs/latest/commands/sunionstore)
    /// - Version: 1.0.0
    /// - Complexity: O(N) where N is the total number of elements in all given sets.
    /// - Categories: @write, @set, @slow
    /// - Returns: [Integer](https:/redis.io/docs/reference/protocol-spec#integers): Number of the elements in the resulting set.
    @inlinable
    public func sunionstore(destination: RedisKey, key: RedisKey) async throws -> Int {
        try await send("SUNIONSTORE", destination, key).converting()
    }

    /// Stores the union of multiple sets in a key.
    ///
    /// - Documentation: [SUNIONSTORE](https:/redis.io/docs/latest/commands/sunionstore)
    /// - Version: 1.0.0
    /// - Complexity: O(N) where N is the total number of elements in all given sets.
    /// - Categories: @write, @set, @slow
    /// - Returns: [Integer](https:/redis.io/docs/reference/protocol-spec#integers): Number of the elements in the resulting set.
    @inlinable
    public func sunionstore(destination: RedisKey, keys: [RedisKey]) async throws -> Int {
        try await send("SUNIONSTORE", destination, keys).converting()
    }

    /// Stops listening to messages posted to shard channels.
    ///
    /// - Documentation: [SUNSUBSCRIBE](https:/redis.io/docs/latest/commands/sunsubscribe)
    /// - Version: 7.0.0
    /// - Complexity: O(N) where N is the number of shard channels to unsubscribe.
    /// - Categories: @pubsub, @slow
    /// - Returns: When successful, this command doesn't return anything. Instead, for each shard channel, one message with the first element being the string `sunsubscribe` is pushed as a confirmation that the command succeeded.
    @inlinable
    public func sunsubscribe(shardchannel: String? = nil) async throws -> RESPToken {
        try await send("SUNSUBSCRIBE", shardchannel)
    }

    /// Stops listening to messages posted to shard channels.
    ///
    /// - Documentation: [SUNSUBSCRIBE](https:/redis.io/docs/latest/commands/sunsubscribe)
    /// - Version: 7.0.0
    /// - Complexity: O(N) where N is the number of shard channels to unsubscribe.
    /// - Categories: @pubsub, @slow
    /// - Returns: When successful, this command doesn't return anything. Instead, for each shard channel, one message with the first element being the string `sunsubscribe` is pushed as a confirmation that the command succeeded.
    @inlinable
    public func sunsubscribe(shardchannels: [String]) async throws -> RESPToken {
        try await send("SUNSUBSCRIBE", shardchannels)
    }

    /// Swaps two Redis databases.
    ///
    /// - Documentation: [SWAPDB](https:/redis.io/docs/latest/commands/swapdb)
    /// - Version: 4.0.0
    /// - Complexity: O(N) where N is the count of clients watching or blocking on keys from both databases.
    /// - Categories: @keyspace, @write, @fast, @dangerous
    /// - Returns: [Simple string](https:/redis.io/docs/reference/protocol-spec#simple-strings): `OK`.
    @inlinable
    public func swapdb(index1: Int, index2: Int) async throws {
        try await send("SWAPDB", index1, index2)
    }

    /// An internal command used in replication.
    ///
    /// - Documentation: [SYNC](https:/redis.io/docs/latest/commands/sync)
    /// - Version: 1.0.0
    /// - Categories: @admin, @slow, @dangerous
    /// - Returns: **Non-standard return value**, a bulk transfer of the data followed by `PING` and write requests from the master.
    @inlinable
    public func sync() async throws -> RESPToken {
        try await send("SYNC")
    }

    /// Returns the server time.
    ///
    /// - Documentation: [TIME](https:/redis.io/docs/latest/commands/time)
    /// - Version: 2.6.0
    /// - Complexity: O(1)
    /// - Categories: @fast
    /// - Returns: [Array](https:/redis.io/docs/reference/protocol-spec#arrays): specifically, a two-element array consisting of the Unix timestamp in seconds and the microseconds' count.
    @inlinable
    public func time() async throws -> [RESPToken] {
        try await send("TIME").converting()
    }

    /// Returns the number of existing keys out of those specified after updating the time they were last accessed.
    ///
    /// - Documentation: [TOUCH](https:/redis.io/docs/latest/commands/touch)
    /// - Version: 3.2.1
    /// - Complexity: O(N) where N is the number of keys that will be touched.
    /// - Categories: @keyspace, @read, @fast
    /// - Returns: [Integer](https:/redis.io/docs/reference/protocol-spec#integers): the number of touched keys.
    @inlinable
    public func touch(key: RedisKey) async throws -> Int {
        try await send("TOUCH", key).converting()
    }

    /// Returns the number of existing keys out of those specified after updating the time they were last accessed.
    ///
    /// - Documentation: [TOUCH](https:/redis.io/docs/latest/commands/touch)
    /// - Version: 3.2.1
    /// - Complexity: O(N) where N is the number of keys that will be touched.
    /// - Categories: @keyspace, @read, @fast
    /// - Returns: [Integer](https:/redis.io/docs/reference/protocol-spec#integers): the number of touched keys.
    @inlinable
    public func touch(keys: [RedisKey]) async throws -> Int {
        try await send("TOUCH", keys).converting()
    }

    /// Returns the expiration time in seconds of a key.
    ///
    /// - Documentation: [TTL](https:/redis.io/docs/latest/commands/ttl)
    /// - Version: 1.0.0
    /// - Complexity: O(1)
    /// - Categories: @keyspace, @read, @fast
    /// - Returns: One of the following:
    ///     * [Integer](https:/redis.io/docs/reference/protocol-spec#integers): TTL in seconds.
    ///     * [Integer](https:/redis.io/docs/reference/protocol-spec#integers): `-1` if the key exists but has no associated expiration.
    ///     * [Integer](https:/redis.io/docs/reference/protocol-spec#integers): `-2` if the key does not exist.
    @inlinable
    public func ttl(key: RedisKey) async throws -> Int {
        try await send("TTL", key).converting()
    }

    /// Determines the type of value stored at a key.
    ///
    /// - Documentation: [TYPE](https:/redis.io/docs/latest/commands/type)
    /// - Version: 1.0.0
    /// - Complexity: O(1)
    /// - Categories: @keyspace, @read, @fast
    /// - Returns: [Simple string](https:/redis.io/docs/reference/protocol-spec#simple-strings): the type of _key_, or `none` when _key_ doesn't exist.
    @inlinable
    public func type(key: RedisKey) async throws -> String {
        try await send("TYPE", key).converting()
    }

    /// Asynchronously deletes one or more keys.
    ///
    /// - Documentation: [UNLINK](https:/redis.io/docs/latest/commands/unlink)
    /// - Version: 4.0.0
    /// - Complexity: O(1) for each key removed regardless of its size. Then the command does O(N) work in a different thread in order to reclaim memory, where N is the number of allocations the deleted objects where composed of.
    /// - Categories: @keyspace, @write, @fast
    /// - Returns: [Integer](https:/redis.io/docs/reference/protocol-spec#integers): the number of keys that were unlinked.
    @inlinable
    public func unlink(key: RedisKey) async throws -> Int {
        try await send("UNLINK", key).converting()
    }

    /// Asynchronously deletes one or more keys.
    ///
    /// - Documentation: [UNLINK](https:/redis.io/docs/latest/commands/unlink)
    /// - Version: 4.0.0
    /// - Complexity: O(1) for each key removed regardless of its size. Then the command does O(N) work in a different thread in order to reclaim memory, where N is the number of allocations the deleted objects where composed of.
    /// - Categories: @keyspace, @write, @fast
    /// - Returns: [Integer](https:/redis.io/docs/reference/protocol-spec#integers): the number of keys that were unlinked.
    @inlinable
    public func unlink(keys: [RedisKey]) async throws -> Int {
        try await send("UNLINK", keys).converting()
    }

    /// Stops listening to messages posted to channels.
    ///
    /// - Documentation: [UNSUBSCRIBE](https:/redis.io/docs/latest/commands/unsubscribe)
    /// - Version: 2.0.0
    /// - Complexity: O(N) where N is the number of channels to unsubscribe.
    /// - Categories: @pubsub, @slow
    /// - Returns: When successful, this command doesn't return anything. Instead, for each channel, one message with the first element being the string `unsubscribe` is pushed as a confirmation that the command succeeded.
    @inlinable
    public func unsubscribe(channel: String? = nil) async throws -> RESPToken {
        try await send("UNSUBSCRIBE", channel)
    }

    /// Stops listening to messages posted to channels.
    ///
    /// - Documentation: [UNSUBSCRIBE](https:/redis.io/docs/latest/commands/unsubscribe)
    /// - Version: 2.0.0
    /// - Complexity: O(N) where N is the number of channels to unsubscribe.
    /// - Categories: @pubsub, @slow
    /// - Returns: When successful, this command doesn't return anything. Instead, for each channel, one message with the first element being the string `unsubscribe` is pushed as a confirmation that the command succeeded.
    @inlinable
    public func unsubscribe(channels: [String]) async throws -> RESPToken {
        try await send("UNSUBSCRIBE", channels)
    }

    /// Forgets about watched keys of a transaction.
    ///
    /// - Documentation: [UNWATCH](https:/redis.io/docs/latest/commands/unwatch)
    /// - Version: 2.2.0
    /// - Complexity: O(1)
    /// - Categories: @fast, @transaction
    /// - Returns: [Simple string](https:/redis.io/docs/reference/protocol-spec#simple-strings): `OK`.
    @inlinable
    public func unwatch() async throws {
        try await send("UNWATCH")
    }

    /// Blocks until the asynchronous replication of all preceding write commands sent by the connection is completed.
    ///
    /// - Documentation: [WAIT](https:/redis.io/docs/latest/commands/wait)
    /// - Version: 3.0.0
    /// - Complexity: O(1)
    /// - Categories: @slow, @connection
    /// - Returns: [Integer](https:/redis.io/docs/reference/protocol-spec#integers): the number of replicas reached by all the writes performed in the context of the current connection.
    @inlinable
    public func wait(numreplicas: Int, timeout: Int) async throws -> Int {
        try await send("WAIT", numreplicas, timeout).converting()
    }

    /// Blocks until all of the preceding write commands sent by the connection are written to the append-only file of the master and/or replicas.
    ///
    /// - Documentation: [WAITAOF](https:/redis.io/docs/latest/commands/waitaof)
    /// - Version: 7.2.0
    /// - Complexity: O(1)
    /// - Categories: @slow, @connection
    /// - Returns: [Array](https:/redis.io/docs/reference/protocol-spec#arrays): The command returns an array of two integers:
    ///     1. The first is the number of local Redises (0 or 1) that have fsynced to AOF  all writes performed in the context of the current connection
    ///     2. The second is the number of replicas that have acknowledged doing the same.
    @inlinable
    public func waitaof(numlocal: Int, numreplicas: Int, timeout: Int) async throws -> [RESPToken] {
        try await send("WAITAOF", numlocal, numreplicas, timeout).converting()
    }

    /// Monitors changes to keys to determine the execution of a transaction.
    ///
    /// - Documentation: [WATCH](https:/redis.io/docs/latest/commands/watch)
    /// - Version: 2.2.0
    /// - Complexity: O(1) for every key.
    /// - Categories: @fast, @transaction
    /// - Returns: [Simple string](https:/redis.io/docs/reference/protocol-spec#simple-strings): `OK`.
    @inlinable
    public func watch(key: RedisKey) async throws {
        try await send("WATCH", key)
    }

    /// Monitors changes to keys to determine the execution of a transaction.
    ///
    /// - Documentation: [WATCH](https:/redis.io/docs/latest/commands/watch)
    /// - Version: 2.2.0
    /// - Complexity: O(1) for every key.
    /// - Categories: @fast, @transaction
    /// - Returns: [Simple string](https:/redis.io/docs/reference/protocol-spec#simple-strings): `OK`.
    @inlinable
    public func watch(keys: [RedisKey]) async throws {
        try await send("WATCH", keys)
    }

    /// Returns the number of messages that were successfully acknowledged by the consumer group member of a stream.
    ///
    /// - Documentation: [XACK](https:/redis.io/docs/latest/commands/xack)
    /// - Version: 5.0.0
    /// - Complexity: O(1) for each message ID processed.
    /// - Categories: @write, @stream, @fast
    /// - Returns: [Integer](https:/redis.io/docs/reference/protocol-spec#integers): The command returns the number of messages successfully acknowledged. Certain message IDs may no longer be part of the PEL (for example because they have already been acknowledged), and XACK will not count them as successfully acknowledged.
    @inlinable
    public func xack(key: RedisKey, group: String, id: String) async throws -> Int {
        try await send("XACK", key, group, id).converting()
    }

    /// Returns the number of messages that were successfully acknowledged by the consumer group member of a stream.
    ///
    /// - Documentation: [XACK](https:/redis.io/docs/latest/commands/xack)
    /// - Version: 5.0.0
    /// - Complexity: O(1) for each message ID processed.
    /// - Categories: @write, @stream, @fast
    /// - Returns: [Integer](https:/redis.io/docs/reference/protocol-spec#integers): The command returns the number of messages successfully acknowledged. Certain message IDs may no longer be part of the PEL (for example because they have already been acknowledged), and XACK will not count them as successfully acknowledged.
    @inlinable
    public func xack(key: RedisKey, group: String, ids: [String]) async throws -> Int {
        try await send("XACK", key, group, ids).converting()
    }

    /// Appends a new message to a stream. Creates the key if it doesn't exist.
    ///
    /// - Documentation: [XADD](https:/redis.io/docs/latest/commands/xadd)
    /// - Version: 5.0.0
    /// - Complexity: O(1) when adding a new entry, O(N) when trimming where N being the number of entries evicted.
    /// - Categories: @write, @stream, @fast
    /// - Returns: One of the following:
    ///     * [Bulk string](https:/redis.io/docs/reference/protocol-spec#bulk-strings): The ID of the added entry. The ID is the one automatically generated if an asterisk (`*`) is passed as the _id_ argument, otherwise the command just returns the same ID specified by the user during insertion.
    ///     * [Null](https:/redis.io/docs/reference/protocol-spec#nulls): if the NOMKSTREAM option is given and the key doesn't exist.
    @inlinable
    public func xadd(key: RedisKey, nomkstream: Bool = false, trim: RESPCommand.XADDTrim? = nil, idSelector: RESPCommand.XADDIdSelector, data: RESPCommand.XADDData) async throws -> String? {
        try await send("XADD", key, RedisPureToken("NOMKSTREAM", nomkstream), trim, idSelector, data).converting()
    }

    /// Appends a new message to a stream. Creates the key if it doesn't exist.
    ///
    /// - Documentation: [XADD](https:/redis.io/docs/latest/commands/xadd)
    /// - Version: 5.0.0
    /// - Complexity: O(1) when adding a new entry, O(N) when trimming where N being the number of entries evicted.
    /// - Categories: @write, @stream, @fast
    /// - Returns: One of the following:
    ///     * [Bulk string](https:/redis.io/docs/reference/protocol-spec#bulk-strings): The ID of the added entry. The ID is the one automatically generated if an asterisk (`*`) is passed as the _id_ argument, otherwise the command just returns the same ID specified by the user during insertion.
    ///     * [Null](https:/redis.io/docs/reference/protocol-spec#nulls): if the NOMKSTREAM option is given and the key doesn't exist.
    @inlinable
    public func xadd(key: RedisKey, nomkstream: Bool = false, trim: RESPCommand.XADDTrim? = nil, idSelector: RESPCommand.XADDIdSelector, datas: [RESPCommand.XADDData]) async throws -> String? {
        try await send("XADD", key, RedisPureToken("NOMKSTREAM", nomkstream), trim, idSelector, datas).converting()
    }

    /// Changes, or acquires, ownership of messages in a consumer group, as if the messages were delivered to as consumer group member.
    ///
    /// - Documentation: [XAUTOCLAIM](https:/redis.io/docs/latest/commands/xautoclaim)
    /// - Version: 6.2.0
    /// - Complexity: O(1) if COUNT is small.
    /// - Categories: @write, @stream, @fast
    /// - Returns: [Array](https:/redis.io/docs/reference/protocol-spec#arrays), specifically, an array with three elements:
    ///     1. A stream ID to be used as the _start_ argument for the next call to XAUTOCLAIM.
    ///     2. An [Array](https:/redis.io/docs/reference/protocol-spec#arrays) containing all the successfully claimed messages in the same format as `XRANGE`.
    ///     3. An [Array](https:/redis.io/docs/reference/protocol-spec#arrays) containing message IDs that no longer exist in the stream, and were deleted from the PEL in which they were found.
    @inlinable
    public func xautoclaim(key: RedisKey, group: String, consumer: String, minIdleTime: String, start: String, count: Int? = nil, justid: Bool = false) async throws -> [RESPToken] {
        try await send("XAUTOCLAIM", key, group, consumer, minIdleTime, start, RESPWithToken("COUNT", count), RedisPureToken("JUSTID", justid)).converting()
    }

    /// Changes, or acquires, ownership of a message in a consumer group, as if the message was delivered a consumer group member.
    ///
    /// - Documentation: [XCLAIM](https:/redis.io/docs/latest/commands/xclaim)
    /// - Version: 5.0.0
    /// - Complexity: O(log N) with N being the number of messages in the PEL of the consumer group.
    /// - Categories: @write, @stream, @fast
    /// - Returns: Any of the following:
    ///     * [Array](https:/redis.io/docs/reference/protocol-spec#arrays): when the _JUSTID_ option is specified, an array of IDs of messages successfully claimed.
    ///     * [Array](https:/redis.io/docs/reference/protocol-spec#arrays): an array of stream entries, each of which contains an array of two elements, the entry ID and the entry data itself.
    @inlinable
    public func xclaim(key: RedisKey, group: String, consumer: String, minIdleTime: String, id: String, ms: Int? = nil, unixTimeMilliseconds: Date? = nil, count: Int? = nil, force: Bool = false, justid: Bool = false, lastid: String? = nil) async throws -> [RESPToken] {
        try await send("XCLAIM", key, group, consumer, minIdleTime, id, RESPWithToken("IDLE", ms), RESPWithToken("TIME", unixTimeMilliseconds), RESPWithToken("RETRYCOUNT", count), RedisPureToken("FORCE", force), RedisPureToken("JUSTID", justid), RESPWithToken("LASTID", lastid)).converting()
    }

    /// Changes, or acquires, ownership of a message in a consumer group, as if the message was delivered a consumer group member.
    ///
    /// - Documentation: [XCLAIM](https:/redis.io/docs/latest/commands/xclaim)
    /// - Version: 5.0.0
    /// - Complexity: O(log N) with N being the number of messages in the PEL of the consumer group.
    /// - Categories: @write, @stream, @fast
    /// - Returns: Any of the following:
    ///     * [Array](https:/redis.io/docs/reference/protocol-spec#arrays): when the _JUSTID_ option is specified, an array of IDs of messages successfully claimed.
    ///     * [Array](https:/redis.io/docs/reference/protocol-spec#arrays): an array of stream entries, each of which contains an array of two elements, the entry ID and the entry data itself.
    @inlinable
    public func xclaim(key: RedisKey, group: String, consumer: String, minIdleTime: String, ids: [String], ms: Int? = nil, unixTimeMilliseconds: Date? = nil, count: Int? = nil, force: Bool = false, justid: Bool = false, lastid: String? = nil) async throws -> [RESPToken] {
        try await send("XCLAIM", key, group, consumer, minIdleTime, ids, RESPWithToken("IDLE", ms), RESPWithToken("TIME", unixTimeMilliseconds), RESPWithToken("RETRYCOUNT", count), RedisPureToken("FORCE", force), RedisPureToken("JUSTID", justid), RESPWithToken("LASTID", lastid)).converting()
    }

    /// Returns the number of messages after removing them from a stream.
    ///
    /// - Documentation: [XDEL](https:/redis.io/docs/latest/commands/xdel)
    /// - Version: 5.0.0
    /// - Complexity: O(1) for each single item to delete in the stream, regardless of the stream size.
    /// - Categories: @write, @stream, @fast
    /// - Returns: [Integer](https:/redis.io/docs/reference/protocol-spec#integers): the number of entries that were deleted.
    @inlinable
    public func xdel(key: RedisKey, id: String) async throws -> Int {
        try await send("XDEL", key, id).converting()
    }

    /// Returns the number of messages after removing them from a stream.
    ///
    /// - Documentation: [XDEL](https:/redis.io/docs/latest/commands/xdel)
    /// - Version: 5.0.0
    /// - Complexity: O(1) for each single item to delete in the stream, regardless of the stream size.
    /// - Categories: @write, @stream, @fast
    /// - Returns: [Integer](https:/redis.io/docs/reference/protocol-spec#integers): the number of entries that were deleted.
    @inlinable
    public func xdel(key: RedisKey, ids: [String]) async throws -> Int {
        try await send("XDEL", key, ids).converting()
    }

    /// Creates a consumer group.
    ///
    /// - Documentation: [XGROUP CREATE](https:/redis.io/docs/latest/commands/xgroup-create)
    /// - Version: 5.0.0
    /// - Complexity: O(1)
    /// - Categories: @write, @stream, @slow
    /// - Returns: [Simple string](https:/redis.io/docs/reference/protocol-spec#simple-strings): `OK`.
    @inlinable
    public func xgroupCreate(key: RedisKey, group: String, idSelector: RESPCommand.XGROUPCREATEIdSelector, mkstream: Bool = false, entriesRead: Int? = nil) async throws {
        try await send("XGROUP", "CREATE", key, group, idSelector, RedisPureToken("MKSTREAM", mkstream), RESPWithToken("ENTRIESREAD", entriesRead))
    }

    /// Creates a consumer in a consumer group.
    ///
    /// - Documentation: [XGROUP CREATECONSUMER](https:/redis.io/docs/latest/commands/xgroup-createconsumer)
    /// - Version: 6.2.0
    /// - Complexity: O(1)
    /// - Categories: @write, @stream, @slow
    /// - Returns: [Integer](https:/redis.io/docs/reference/protocol-spec#integers): the number of created consumers, either 0 or 1.
    @inlinable
    public func xgroupCreateconsumer(key: RedisKey, group: String, consumer: String) async throws -> Int {
        try await send("XGROUP", "CREATECONSUMER", key, group, consumer).converting()
    }

    /// Deletes a consumer from a consumer group.
    ///
    /// - Documentation: [XGROUP DELCONSUMER](https:/redis.io/docs/latest/commands/xgroup-delconsumer)
    /// - Version: 5.0.0
    /// - Complexity: O(1)
    /// - Categories: @write, @stream, @slow
    /// - Returns: [Integer](https:/redis.io/docs/reference/protocol-spec#integers): the number of pending messages the consumer had before it was deleted.
    @inlinable
    public func xgroupDelconsumer(key: RedisKey, group: String, consumer: String) async throws -> Int {
        try await send("XGROUP", "DELCONSUMER", key, group, consumer).converting()
    }

    /// Destroys a consumer group.
    ///
    /// - Documentation: [XGROUP DESTROY](https:/redis.io/docs/latest/commands/xgroup-destroy)
    /// - Version: 5.0.0
    /// - Complexity: O(N) where N is the number of entries in the group's pending entries list (PEL).
    /// - Categories: @write, @stream, @slow
    /// - Returns: [Integer](https:/redis.io/docs/reference/protocol-spec#integers): the number of destroyed consumer groups, either 0 or 1.
    @inlinable
    public func xgroupDestroy(key: RedisKey, group: String) async throws -> Int {
        try await send("XGROUP", "DESTROY", key, group).converting()
    }

    /// Returns helpful text about the different subcommands.
    ///
    /// - Documentation: [XGROUP HELP](https:/redis.io/docs/latest/commands/xgroup-help)
    /// - Version: 5.0.0
    /// - Complexity: O(1)
    /// - Categories: @stream, @slow
    /// - Returns: [Array](https:/redis.io/docs/reference/protocol-spec#arrays): a list of sub-commands and their descriptions.
    @inlinable
    public func xgroupHelp() async throws -> [RESPToken] {
        try await send("XGROUP", "HELP").converting()
    }

    /// Sets the last-delivered ID of a consumer group.
    ///
    /// - Documentation: [XGROUP SETID](https:/redis.io/docs/latest/commands/xgroup-setid)
    /// - Version: 5.0.0
    /// - Complexity: O(1)
    /// - Categories: @write, @stream, @slow
    /// - Returns: [Simple string](https:/redis.io/docs/reference/protocol-spec#simple-strings): `OK`.
    @inlinable
    public func xgroupSetid(key: RedisKey, group: String, idSelector: RESPCommand.XGROUPSETIDIdSelector, entriesread: Int? = nil) async throws {
        try await send("XGROUP", "SETID", key, group, idSelector, RESPWithToken("ENTRIESREAD", entriesread))
    }

    /// Returns a list of the consumers in a consumer group.
    ///
    /// - Documentation: [XINFO CONSUMERS](https:/redis.io/docs/latest/commands/xinfo-consumers)
    /// - Version: 5.0.0
    /// - Complexity: O(1)
    /// - Categories: @read, @stream, @slow
    /// - Returns: [Array](https:/redis.io/docs/reference/protocol-spec#arrays): a list of consumers and their attributes.
    @inlinable
    public func xinfoConsumers(key: RedisKey, group: String) async throws -> [RESPToken] {
        try await send("XINFO", "CONSUMERS", key, group).converting()
    }

    /// Returns a list of the consumer groups of a stream.
    ///
    /// - Documentation: [XINFO GROUPS](https:/redis.io/docs/latest/commands/xinfo-groups)
    /// - Version: 5.0.0
    /// - Complexity: O(1)
    /// - Categories: @read, @stream, @slow
    /// - Returns: [Array](https:/redis.io/docs/reference/protocol-spec#arrays): a list of consumer groups.
    @inlinable
    public func xinfoGroups(key: RedisKey) async throws -> [RESPToken] {
        try await send("XINFO", "GROUPS", key).converting()
    }

    /// Returns helpful text about the different subcommands.
    ///
    /// - Documentation: [XINFO HELP](https:/redis.io/docs/latest/commands/xinfo-help)
    /// - Version: 5.0.0
    /// - Complexity: O(1)
    /// - Categories: @stream, @slow
    /// - Returns: [Array](https:/redis.io/docs/reference/protocol-spec#arrays): a list of sub-commands and their descriptions.
    @inlinable
    public func xinfoHelp() async throws -> [RESPToken] {
        try await send("XINFO", "HELP").converting()
    }

    /// Returns information about a stream.
    ///
    /// - Documentation: [XINFO STREAM](https:/redis.io/docs/latest/commands/xinfo-stream)
    /// - Version: 5.0.0
    /// - Complexity: O(1)
    /// - Categories: @read, @stream, @slow
    /// - Returns: One of the following:
    ///     * [Map](https:/redis.io/docs/reference/protocol-spec#maps): when the _FULL_ argument was not given, a list of information about a stream in summary form.
    ///     * [Map](https:/redis.io/docs/reference/protocol-spec#maps): when the _FULL_ argument was given, a list of information about a stream in extended form.
    @inlinable
    public func xinfoStream(key: RedisKey, fullBlock: RESPCommand.XINFOSTREAMFullBlock? = nil) async throws -> RESPToken {
        try await send("XINFO", "STREAM", key, fullBlock).converting()
    }

    /// Return the number of messages in a stream.
    ///
    /// - Documentation: [XLEN](https:/redis.io/docs/latest/commands/xlen)
    /// - Version: 5.0.0
    /// - Complexity: O(1)
    /// - Categories: @read, @stream, @fast
    /// - Returns: [Integer](https:/redis.io/docs/reference/protocol-spec#integers): the number of entries of the stream at _key_.
    @inlinable
    public func xlen(key: RedisKey) async throws -> Int {
        try await send("XLEN", key).converting()
    }

    /// Returns the information and entries from a stream consumer group's pending entries list.
    ///
    /// - Documentation: [XPENDING](https:/redis.io/docs/latest/commands/xpending)
    /// - Version: 5.0.0
    /// - Complexity: O(N) with N being the number of elements returned, so asking for a small fixed number of entries per call is O(1). O(M), where M is the total number of entries scanned when used with the IDLE filter. When the command returns just the summary and the list of consumers is small, it runs in O(1) time; otherwise, an additional O(N) time for iterating every consumer.
    /// - Categories: @read, @stream, @slow
    /// - Returns: * [Array](https:/redis.io/docs/reference/protocol-spec#arrays): different data depending on the way XPENDING is called, as explained on this page.
    @inlinable
    public func xpending(key: RedisKey, group: String, filters: RESPCommand.XPENDINGFilters? = nil) async throws -> RESPToken {
        try await send("XPENDING", key, group, filters)
    }

    /// Returns the messages from a stream within a range of IDs.
    ///
    /// - Documentation: [XRANGE](https:/redis.io/docs/latest/commands/xrange)
    /// - Version: 5.0.0
    /// - Complexity: O(N) with N being the number of elements being returned. If N is constant (e.g. always asking for the first 10 elements with COUNT), you can consider it O(1).
    /// - Categories: @read, @stream, @slow
    /// - Returns: [Array](https:/redis.io/docs/reference/protocol-spec#arrays): a list of stream entries with IDs matching the specified range.
    @inlinable
    public func xrange(key: RedisKey, start: String, end: String, count: Int? = nil) async throws -> [RESPToken] {
        try await send("XRANGE", key, start, end, RESPWithToken("COUNT", count)).converting()
    }

    /// Returns messages from multiple streams with IDs greater than the ones requested. Blocks until a message is available otherwise.
    ///
    /// - Documentation: [XREAD](https:/redis.io/docs/latest/commands/xread)
    /// - Version: 5.0.0
    /// - Categories: @read, @stream, @slow, @blocking
    /// - Returns: One of the following:
    ///     * [Map](https:/redis.io/docs/reference/protocol-spec#maps): A map of key-value elements where each element is composed of the key name and the entries reported for that key. The entries reported are full stream entries, having IDs and the list of all the fields and values. Field and values are guaranteed to be reported in the same order they were added by `XADD`.
    ///     * [Null](https:/redis.io/docs/reference/protocol-spec#nulls): if the _BLOCK_ option is given and a timeout occurs, or if there is no stream that can be served.
    @inlinable
    public func xread(count: Int? = nil, milliseconds: Int? = nil, streams: RESPCommand.XREADStreams) async throws -> RESPToken? {
        try await send("XREAD", RESPWithToken("COUNT", count), RESPWithToken("BLOCK", milliseconds), RESPWithToken("STREAMS", streams)).converting()
    }

    /// Returns new or historical messages from a stream for a consumer in a group. Blocks until a message is available otherwise.
    ///
    /// - Documentation: [XREADGROUP](https:/redis.io/docs/latest/commands/xreadgroup)
    /// - Version: 5.0.0
    /// - Complexity: For each stream mentioned: O(M) with M being the number of elements returned. If M is constant (e.g. always asking for the first 10 elements with COUNT), you can consider it O(1). On the other side when XREADGROUP blocks, XADD will pay the O(N) time in order to serve the N clients blocked on the stream getting new data.
    /// - Categories: @write, @stream, @slow, @blocking
    /// - Returns: One of the following:
    ///     * [Map](https:/redis.io/docs/reference/protocol-spec#maps): A map of key-value elements where each element is composed of the key name and the entries reported for that key. The entries reported are full stream entries, having IDs and the list of all the fields and values. Field and values are guaranteed to be reported in the same order they were added by `XADD`.
    ///     * [Null](https:/redis.io/docs/reference/protocol-spec#nulls): if the _BLOCK_ option is given and a timeout occurs, or if there is no stream that can be served.
    @inlinable
    public func xreadgroup(groupBlock: RESPCommand.XREADGROUPGroupBlock, count: Int? = nil, milliseconds: Int? = nil, noack: Bool = false, streams: RESPCommand.XREADGROUPStreams) async throws -> RESPToken? {
        try await send("XREADGROUP", RESPWithToken("GROUP", groupBlock), RESPWithToken("COUNT", count), RESPWithToken("BLOCK", milliseconds), RedisPureToken("NOACK", noack), RESPWithToken("STREAMS", streams)).converting()
    }

    /// Returns the messages from a stream within a range of IDs in reverse order.
    ///
    /// - Documentation: [XREVRANGE](https:/redis.io/docs/latest/commands/xrevrange)
    /// - Version: 5.0.0
    /// - Complexity: O(N) with N being the number of elements returned. If N is constant (e.g. always asking for the first 10 elements with COUNT), you can consider it O(1).
    /// - Categories: @read, @stream, @slow
    /// - Returns: [Array](https:/redis.io/docs/reference/protocol-spec#arrays): The command returns the entries with IDs matching the specified range. The returned entries are complete, which means that the ID and all the fields they are composed of are returned. Moreover, the entries are returned with their fields and values in the same order as `XADD` added them.
    @inlinable
    public func xrevrange(key: RedisKey, end: String, start: String, count: Int? = nil) async throws -> [RESPToken] {
        try await send("XREVRANGE", key, end, start, RESPWithToken("COUNT", count)).converting()
    }

    /// An internal command for replicating stream values.
    ///
    /// - Documentation: [XSETID](https:/redis.io/docs/latest/commands/xsetid)
    /// - Version: 5.0.0
    /// - Complexity: O(1)
    /// - Categories: @write, @stream, @fast
    /// - Returns: [Simple string](https:/redis.io/docs/reference/protocol-spec#simple-strings): `OK`.
    @inlinable
    public func xsetid(key: RedisKey, lastId: String, entriesAdded: Int? = nil, maxDeletedId: String? = nil) async throws {
        try await send("XSETID", key, lastId, RESPWithToken("ENTRIESADDED", entriesAdded), RESPWithToken("MAXDELETEDID", maxDeletedId))
    }

    /// Deletes messages from the beginning of a stream.
    ///
    /// - Documentation: [XTRIM](https:/redis.io/docs/latest/commands/xtrim)
    /// - Version: 5.0.0
    /// - Complexity: O(N), with N being the number of evicted entries. Constant times are very small however, since entries are organized in macro nodes containing multiple entries that can be released with a single deallocation.
    /// - Categories: @write, @stream, @slow
    /// - Returns: [Integer](https:/redis.io/docs/reference/protocol-spec#integers): The number of entries deleted from the stream.
    @inlinable
    public func xtrim(key: RedisKey, trim: RESPCommand.XTRIMTrim) async throws -> Int {
        try await send("XTRIM", key, trim).converting()
    }

    /// Adds one or more members to a sorted set, or updates their scores. Creates the key if it doesn't exist.
    ///
    /// - Documentation: [ZADD](https:/redis.io/docs/latest/commands/zadd)
    /// - Version: 1.2.0
    /// - Complexity: O(log(N)) for each item added, where N is the number of elements in the sorted set.
    /// - Categories: @write, @sortedset, @fast
    /// - Returns: Any of the following:
    ///     * [Null](https:/redis.io/docs/reference/protocol-spec#nulls): if the operation was aborted because of a conflict with one of the _XX/NX/LT/GT_ options.
    ///     * [Integer](https:/redis.io/docs/reference/protocol-spec#integers): the number of new members when the _CH_ option is not used.
    ///     * [Integer](https:/redis.io/docs/reference/protocol-spec#integers): the number of new or updated members when the _CH_ option is used.
    ///     * [Double](https:/redis.io/docs/reference/protocol-spec#doubles): the updated score of the member when the _INCR_ option is used.
    @inlinable
    public func zadd(key: RedisKey, condition: RESPCommand.ZADDCondition? = nil, comparison: RESPCommand.ZADDComparison? = nil, change: Bool = false, increment: Bool = false, data: RESPCommand.ZADDData) async throws -> RESPToken {
        try await send("ZADD", key, condition, comparison, RedisPureToken("CH", change), RedisPureToken("INCR", increment), data)
    }

    /// Adds one or more members to a sorted set, or updates their scores. Creates the key if it doesn't exist.
    ///
    /// - Documentation: [ZADD](https:/redis.io/docs/latest/commands/zadd)
    /// - Version: 1.2.0
    /// - Complexity: O(log(N)) for each item added, where N is the number of elements in the sorted set.
    /// - Categories: @write, @sortedset, @fast
    /// - Returns: Any of the following:
    ///     * [Null](https:/redis.io/docs/reference/protocol-spec#nulls): if the operation was aborted because of a conflict with one of the _XX/NX/LT/GT_ options.
    ///     * [Integer](https:/redis.io/docs/reference/protocol-spec#integers): the number of new members when the _CH_ option is not used.
    ///     * [Integer](https:/redis.io/docs/reference/protocol-spec#integers): the number of new or updated members when the _CH_ option is used.
    ///     * [Double](https:/redis.io/docs/reference/protocol-spec#doubles): the updated score of the member when the _INCR_ option is used.
    @inlinable
    public func zadd(key: RedisKey, condition: RESPCommand.ZADDCondition? = nil, comparison: RESPCommand.ZADDComparison? = nil, change: Bool = false, increment: Bool = false, datas: [RESPCommand.ZADDData]) async throws -> RESPToken {
        try await send("ZADD", key, condition, comparison, RedisPureToken("CH", change), RedisPureToken("INCR", increment), datas)
    }

    /// Returns the number of members in a sorted set.
    ///
    /// - Documentation: [ZCARD](https:/redis.io/docs/latest/commands/zcard)
    /// - Version: 1.2.0
    /// - Complexity: O(1)
    /// - Categories: @read, @sortedset, @fast
    /// - Returns: [Integer](https:/redis.io/docs/reference/protocol-spec#integers): the cardinality (number of members) of the sorted set, or 0 if the key doesn't exist.
    @inlinable
    public func zcard(key: RedisKey) async throws -> Int {
        try await send("ZCARD", key).converting()
    }

    /// Returns the count of members in a sorted set that have scores within a range.
    ///
    /// - Documentation: [ZCOUNT](https:/redis.io/docs/latest/commands/zcount)
    /// - Version: 2.0.0
    /// - Complexity: O(log(N)) with N being the number of elements in the sorted set.
    /// - Categories: @read, @sortedset, @fast
    /// - Returns: [Integer](https:/redis.io/docs/reference/protocol-spec#integers): the number of members in the specified score range.
    @inlinable
    public func zcount(key: RedisKey, min: Double, max: Double) async throws -> Int {
        try await send("ZCOUNT", key, min, max).converting()
    }

    /// Returns the difference between multiple sorted sets.
    ///
    /// - Documentation: [ZDIFF](https:/redis.io/docs/latest/commands/zdiff)
    /// - Version: 6.2.0
    /// - Complexity: O(L + (N-K)log(N)) worst case where L is the total number of elements in all the sets, N is the size of the first set, and K is the size of the result set.
    /// - Categories: @read, @sortedset, @slow
    /// - Returns: * [Array](https:/redis.io/docs/reference/protocol-spec#arrays): the result of the difference including, optionally, scores when the _WITHSCORES_ option is used.
    @inlinable
    public func zdiff(key: RedisKey, withscores: Bool = false) async throws -> RESPToken {
        try await send("ZDIFF", 1, key, RedisPureToken("WITHSCORES", withscores))
    }

    /// Returns the difference between multiple sorted sets.
    ///
    /// - Documentation: [ZDIFF](https:/redis.io/docs/latest/commands/zdiff)
    /// - Version: 6.2.0
    /// - Complexity: O(L + (N-K)log(N)) worst case where L is the total number of elements in all the sets, N is the size of the first set, and K is the size of the result set.
    /// - Categories: @read, @sortedset, @slow
    /// - Returns: * [Array](https:/redis.io/docs/reference/protocol-spec#arrays): the result of the difference including, optionally, scores when the _WITHSCORES_ option is used.
    @inlinable
    public func zdiff(keys: [RedisKey], withscores: Bool = false) async throws -> RESPToken {
        try await send("ZDIFF", RESPArrayWithCount(keys), RedisPureToken("WITHSCORES", withscores))
    }

    /// Stores the difference of multiple sorted sets in a key.
    ///
    /// - Documentation: [ZDIFFSTORE](https:/redis.io/docs/latest/commands/zdiffstore)
    /// - Version: 6.2.0
    /// - Complexity: O(L + (N-K)log(N)) worst case where L is the total number of elements in all the sets, N is the size of the first set, and K is the size of the result set.
    /// - Categories: @write, @sortedset, @slow
    /// - Returns: [Integer](https:/redis.io/docs/reference/protocol-spec#integers): the number of members in the resulting sorted set at _destination_.
    @inlinable
    public func zdiffstore(destination: RedisKey, key: RedisKey) async throws -> Int {
        try await send("ZDIFFSTORE", destination, 1, key).converting()
    }

    /// Stores the difference of multiple sorted sets in a key.
    ///
    /// - Documentation: [ZDIFFSTORE](https:/redis.io/docs/latest/commands/zdiffstore)
    /// - Version: 6.2.0
    /// - Complexity: O(L + (N-K)log(N)) worst case where L is the total number of elements in all the sets, N is the size of the first set, and K is the size of the result set.
    /// - Categories: @write, @sortedset, @slow
    /// - Returns: [Integer](https:/redis.io/docs/reference/protocol-spec#integers): the number of members in the resulting sorted set at _destination_.
    @inlinable
    public func zdiffstore(destination: RedisKey, keys: [RedisKey]) async throws -> Int {
        try await send("ZDIFFSTORE", destination, RESPArrayWithCount(keys)).converting()
    }

    /// Increments the score of a member in a sorted set.
    ///
    /// - Documentation: [ZINCRBY](https:/redis.io/docs/latest/commands/zincrby)
    /// - Version: 1.2.0
    /// - Complexity: O(log(N)) where N is the number of elements in the sorted set.
    /// - Categories: @write, @sortedset, @fast
    /// - Returns: [Double](https:/redis.io/docs/reference/protocol-spec#doubles): the new score of _member_.
    @inlinable
    public func zincrby(key: RedisKey, increment: Int, member: String) async throws -> Double {
        try await send("ZINCRBY", key, increment, member).converting()
    }

    /// Returns the intersect of multiple sorted sets.
    ///
    /// - Documentation: [ZINTER](https:/redis.io/docs/latest/commands/zinter)
    /// - Version: 6.2.0
    /// - Complexity: O(N*K)+O(M*log(M)) worst case with N being the smallest input sorted set, K being the number of input sorted sets and M being the number of elements in the resulting sorted set.
    /// - Categories: @read, @sortedset, @slow
    /// - Returns: * [Array](https:/redis.io/docs/reference/protocol-spec#arrays): the result of the intersection including, optionally, scores when the _WITHSCORES_ option is used.
    @inlinable
    public func zinter(key: RedisKey, weight: Int? = nil, aggregate: RESPCommand.ZINTERAggregate? = nil, withscores: Bool = false) async throws -> RESPToken {
        try await send("ZINTER", 1, key, RESPWithToken("WEIGHTS", weight), RESPWithToken("AGGREGATE", aggregate), RedisPureToken("WITHSCORES", withscores))
    }

    /// Returns the intersect of multiple sorted sets.
    ///
    /// - Documentation: [ZINTER](https:/redis.io/docs/latest/commands/zinter)
    /// - Version: 6.2.0
    /// - Complexity: O(N*K)+O(M*log(M)) worst case with N being the smallest input sorted set, K being the number of input sorted sets and M being the number of elements in the resulting sorted set.
    /// - Categories: @read, @sortedset, @slow
    /// - Returns: * [Array](https:/redis.io/docs/reference/protocol-spec#arrays): the result of the intersection including, optionally, scores when the _WITHSCORES_ option is used.
    @inlinable
    public func zinter(keys: [RedisKey], weights: [Int], aggregate: RESPCommand.ZINTERAggregate? = nil, withscores: Bool = false) async throws -> RESPToken {
        try await send("ZINTER", RESPArrayWithCount(keys), RESPWithToken("WEIGHTS", weights), RESPWithToken("AGGREGATE", aggregate), RedisPureToken("WITHSCORES", withscores))
    }

    /// Returns the number of members of the intersect of multiple sorted sets.
    ///
    /// - Documentation: [ZINTERCARD](https:/redis.io/docs/latest/commands/zintercard)
    /// - Version: 7.0.0
    /// - Complexity: O(N*K) worst case with N being the smallest input sorted set, K being the number of input sorted sets.
    /// - Categories: @read, @sortedset, @slow
    /// - Returns: [Integer](https:/redis.io/docs/reference/protocol-spec#integers): the number of members in the resulting intersection.
    @inlinable
    public func zintercard(key: RedisKey, limit: Int? = nil) async throws -> Int {
        try await send("ZINTERCARD", 1, key, RESPWithToken("LIMIT", limit)).converting()
    }

    /// Returns the number of members of the intersect of multiple sorted sets.
    ///
    /// - Documentation: [ZINTERCARD](https:/redis.io/docs/latest/commands/zintercard)
    /// - Version: 7.0.0
    /// - Complexity: O(N*K) worst case with N being the smallest input sorted set, K being the number of input sorted sets.
    /// - Categories: @read, @sortedset, @slow
    /// - Returns: [Integer](https:/redis.io/docs/reference/protocol-spec#integers): the number of members in the resulting intersection.
    @inlinable
    public func zintercard(keys: [RedisKey], limit: Int? = nil) async throws -> Int {
        try await send("ZINTERCARD", RESPArrayWithCount(keys), RESPWithToken("LIMIT", limit)).converting()
    }

    /// Stores the intersect of multiple sorted sets in a key.
    ///
    /// - Documentation: [ZINTERSTORE](https:/redis.io/docs/latest/commands/zinterstore)
    /// - Version: 2.0.0
    /// - Complexity: O(N*K)+O(M*log(M)) worst case with N being the smallest input sorted set, K being the number of input sorted sets and M being the number of elements in the resulting sorted set.
    /// - Categories: @write, @sortedset, @slow
    /// - Returns: [Integer](https:/redis.io/docs/reference/protocol-spec#integers): the number of members in the resulting sorted set at the _destination_.
    @inlinable
    public func zinterstore(destination: RedisKey, key: RedisKey, weight: Int? = nil, aggregate: RESPCommand.ZINTERSTOREAggregate? = nil) async throws -> Int {
        try await send("ZINTERSTORE", destination, 1, key, RESPWithToken("WEIGHTS", weight), RESPWithToken("AGGREGATE", aggregate)).converting()
    }

    /// Stores the intersect of multiple sorted sets in a key.
    ///
    /// - Documentation: [ZINTERSTORE](https:/redis.io/docs/latest/commands/zinterstore)
    /// - Version: 2.0.0
    /// - Complexity: O(N*K)+O(M*log(M)) worst case with N being the smallest input sorted set, K being the number of input sorted sets and M being the number of elements in the resulting sorted set.
    /// - Categories: @write, @sortedset, @slow
    /// - Returns: [Integer](https:/redis.io/docs/reference/protocol-spec#integers): the number of members in the resulting sorted set at the _destination_.
    @inlinable
    public func zinterstore(destination: RedisKey, keys: [RedisKey], weights: [Int], aggregate: RESPCommand.ZINTERSTOREAggregate? = nil) async throws -> Int {
        try await send("ZINTERSTORE", destination, RESPArrayWithCount(keys), RESPWithToken("WEIGHTS", weights), RESPWithToken("AGGREGATE", aggregate)).converting()
    }

    /// Returns the number of members in a sorted set within a lexicographical range.
    ///
    /// - Documentation: [ZLEXCOUNT](https:/redis.io/docs/latest/commands/zlexcount)
    /// - Version: 2.8.9
    /// - Complexity: O(log(N)) with N being the number of elements in the sorted set.
    /// - Categories: @read, @sortedset, @fast
    /// - Returns: [Integer](https:/redis.io/docs/reference/protocol-spec#integers): the number of members in the specified score range.
    @inlinable
    public func zlexcount(key: RedisKey, min: String, max: String) async throws -> Int {
        try await send("ZLEXCOUNT", key, min, max).converting()
    }

    /// Returns the highest- or lowest-scoring members from one or more sorted sets after removing them. Deletes the sorted set if the last member was popped.
    ///
    /// - Documentation: [ZMPOP](https:/redis.io/docs/latest/commands/zmpop)
    /// - Version: 7.0.0
    /// - Complexity: O(K) + O(M*log(N)) where K is the number of provided keys, N being the number of elements in the sorted set, and M being the number of elements popped.
    /// - Categories: @write, @sortedset, @slow
    /// - Returns: One of the following:
    ///     * [Null](https:/redis.io/docs/reference/protocol-spec#nulls): when no element could be popped.
    ///     * [Array](https:/redis.io/docs/reference/protocol-spec#arrays): A two-element array with the first element being the name of the key from which elements were popped, and the second element is an array of the popped elements. Every entry in the elements array is also an array that contains the member and its score.
    @inlinable
    public func zmpop(key: RedisKey, `where`: RESPCommand.ZMPOPWhere, count: Int? = nil) async throws -> [RESPToken]? {
        try await send("ZMPOP", 1, key, `where`, RESPWithToken("COUNT", count)).converting()
    }

    /// Returns the highest- or lowest-scoring members from one or more sorted sets after removing them. Deletes the sorted set if the last member was popped.
    ///
    /// - Documentation: [ZMPOP](https:/redis.io/docs/latest/commands/zmpop)
    /// - Version: 7.0.0
    /// - Complexity: O(K) + O(M*log(N)) where K is the number of provided keys, N being the number of elements in the sorted set, and M being the number of elements popped.
    /// - Categories: @write, @sortedset, @slow
    /// - Returns: One of the following:
    ///     * [Null](https:/redis.io/docs/reference/protocol-spec#nulls): when no element could be popped.
    ///     * [Array](https:/redis.io/docs/reference/protocol-spec#arrays): A two-element array with the first element being the name of the key from which elements were popped, and the second element is an array of the popped elements. Every entry in the elements array is also an array that contains the member and its score.
    @inlinable
    public func zmpop(keys: [RedisKey], `where`: RESPCommand.ZMPOPWhere, count: Int? = nil) async throws -> [RESPToken]? {
        try await send("ZMPOP", RESPArrayWithCount(keys), `where`, RESPWithToken("COUNT", count)).converting()
    }

    /// Returns the score of one or more members in a sorted set.
    ///
    /// - Documentation: [ZMSCORE](https:/redis.io/docs/latest/commands/zmscore)
    /// - Version: 6.2.0
    /// - Complexity: O(N) where N is the number of members being requested.
    /// - Categories: @read, @sortedset, @fast
    /// - Returns: One of the following:
    ///     * [Null](https:/redis.io/docs/reference/protocol-spec#nulls): if the member does not exist in the sorted set.
    ///     * [Array](https:/redis.io/docs/reference/protocol-spec#arrays): a list of [Double](https:/redis.io/docs/reference/protocol-spec#doubles) _member_ scores as double-precision floating point numbers.
    @inlinable
    public func zmscore(key: RedisKey, member: String) async throws -> [RESPToken]? {
        try await send("ZMSCORE", key, member).converting()
    }

    /// Returns the score of one or more members in a sorted set.
    ///
    /// - Documentation: [ZMSCORE](https:/redis.io/docs/latest/commands/zmscore)
    /// - Version: 6.2.0
    /// - Complexity: O(N) where N is the number of members being requested.
    /// - Categories: @read, @sortedset, @fast
    /// - Returns: One of the following:
    ///     * [Null](https:/redis.io/docs/reference/protocol-spec#nulls): if the member does not exist in the sorted set.
    ///     * [Array](https:/redis.io/docs/reference/protocol-spec#arrays): a list of [Double](https:/redis.io/docs/reference/protocol-spec#doubles) _member_ scores as double-precision floating point numbers.
    @inlinable
    public func zmscore(key: RedisKey, members: [String]) async throws -> [RESPToken]? {
        try await send("ZMSCORE", key, members).converting()
    }

    /// Returns the highest-scoring members from a sorted set after removing them. Deletes the sorted set if the last member was popped.
    ///
    /// - Documentation: [ZPOPMAX](https:/redis.io/docs/latest/commands/zpopmax)
    /// - Version: 5.0.0
    /// - Complexity: O(log(N)*M) with N being the number of elements in the sorted set, and M being the number of elements popped.
    /// - Categories: @write, @sortedset, @fast
    /// - Returns: * [Array](https:/redis.io/docs/reference/protocol-spec#arrays): a list of popped elements and scores.
    @inlinable
    public func zpopmax(key: RedisKey, count: Int? = nil) async throws -> RESPToken {
        try await send("ZPOPMAX", key, count)
    }

    /// Returns the lowest-scoring members from a sorted set after removing them. Deletes the sorted set if the last member was popped.
    ///
    /// - Documentation: [ZPOPMIN](https:/redis.io/docs/latest/commands/zpopmin)
    /// - Version: 5.0.0
    /// - Complexity: O(log(N)*M) with N being the number of elements in the sorted set, and M being the number of elements popped.
    /// - Categories: @write, @sortedset, @fast
    /// - Returns: * [Array](https:/redis.io/docs/reference/protocol-spec#arrays): a list of popped elements and scores.
    @inlinable
    public func zpopmin(key: RedisKey, count: Int? = nil) async throws -> RESPToken {
        try await send("ZPOPMIN", key, count)
    }

    /// Returns one or more random members from a sorted set.
    ///
    /// - Documentation: [ZRANDMEMBER](https:/redis.io/docs/latest/commands/zrandmember)
    /// - Version: 6.2.0
    /// - Complexity: O(N) where N is the number of members returned
    /// - Categories: @read, @sortedset, @slow
    /// - Returns: [Bulk string](https:/redis.io/docs/reference/protocol-spec#bulk-strings): without the additional _count_ argument, the command returns a randomly selected member, or [Null](https:/redis.io/docs/reference/protocol-spec#nulls) when _key_ doesn't exist.
    ///     [Array](https:/redis.io/docs/reference/protocol-spec#arrays): when the additional _count_ argument is passed, the command returns an array of members, or an empty array when _key_ doesn't exist. If the _WITHSCORES_ modifier is used, the reply is a list of members and their scores from the sorted set.
    @inlinable
    public func zrandmember(key: RedisKey, options: RESPCommand.ZRANDMEMBEROptions? = nil) async throws -> RESPToken {
        try await send("ZRANDMEMBER", key, options)
    }

    /// Returns members in a sorted set within a range of indexes.
    ///
    /// - Documentation: [ZRANGE](https:/redis.io/docs/latest/commands/zrange)
    /// - Version: 1.2.0
    /// - Complexity: O(log(N)+M) with N being the number of elements in the sorted set and M the number of elements returned.
    /// - Categories: @read, @sortedset, @slow
    /// - Returns: [Array](https:/redis.io/docs/reference/protocol-spec#arrays): a list of members in the specified range with, optionally, their scores when the _WITHSCORES_ option is given.
    @inlinable
    public func zrange(key: RedisKey, start: String, stop: String, sortby: RESPCommand.ZRANGESortby? = nil, rev: Bool = false, limit: RESPCommand.ZRANGELimit? = nil, withscores: Bool = false) async throws -> [RESPToken] {
        try await send("ZRANGE", key, start, stop, sortby, RedisPureToken("REV", rev), RESPWithToken("LIMIT", limit), RedisPureToken("WITHSCORES", withscores)).converting()
    }

    /// Returns members in a sorted set within a lexicographical range.
    ///
    /// - Documentation: [ZRANGEBYLEX](https:/redis.io/docs/latest/commands/zrangebylex)
    /// - Version: 2.8.9
    /// - Complexity: O(log(N)+M) with N being the number of elements in the sorted set and M the number of elements being returned. If M is constant (e.g. always asking for the first 10 elements with LIMIT), you can consider it O(log(N)).
    /// - Categories: @read, @sortedset, @slow
    /// - Returns: [Array](https:/redis.io/docs/reference/protocol-spec#arrays): a list of elements in the specified score range.
    @inlinable
    public func zrangebylex(key: RedisKey, min: String, max: String, limit: RESPCommand.ZRANGEBYLEXLimit? = nil) async throws -> [RESPToken] {
        try await send("ZRANGEBYLEX", key, min, max, RESPWithToken("LIMIT", limit)).converting()
    }

    /// Returns members in a sorted set within a range of scores.
    ///
    /// - Documentation: [ZRANGEBYSCORE](https:/redis.io/docs/latest/commands/zrangebyscore)
    /// - Version: 1.0.5
    /// - Complexity: O(log(N)+M) with N being the number of elements in the sorted set and M the number of elements being returned. If M is constant (e.g. always asking for the first 10 elements with LIMIT), you can consider it O(log(N)).
    /// - Categories: @read, @sortedset, @slow
    /// - Returns: * [Array](https:/redis.io/docs/reference/protocol-spec#arrays): a list of the members with, optionally, their scores in the specified score range.
    @inlinable
    public func zrangebyscore(key: RedisKey, min: Double, max: Double, withscores: Bool = false, limit: RESPCommand.ZRANGEBYSCORELimit? = nil) async throws -> RESPToken {
        try await send("ZRANGEBYSCORE", key, min, max, RedisPureToken("WITHSCORES", withscores), RESPWithToken("LIMIT", limit))
    }

    /// Stores a range of members from sorted set in a key.
    ///
    /// - Documentation: [ZRANGESTORE](https:/redis.io/docs/latest/commands/zrangestore)
    /// - Version: 6.2.0
    /// - Complexity: O(log(N)+M) with N being the number of elements in the sorted set and M the number of elements stored into the destination key.
    /// - Categories: @write, @sortedset, @slow
    /// - Returns: [Integer](https:/redis.io/docs/reference/protocol-spec#integers): the number of elements in the resulting sorted set.
    @inlinable
    public func zrangestore(dst: RedisKey, src: RedisKey, min: String, max: String, sortby: RESPCommand.ZRANGESTORESortby? = nil, rev: Bool = false, limit: RESPCommand.ZRANGESTORELimit? = nil) async throws -> Int {
        try await send("ZRANGESTORE", dst, src, min, max, sortby, RedisPureToken("REV", rev), RESPWithToken("LIMIT", limit)).converting()
    }

    /// Returns the index of a member in a sorted set ordered by ascending scores.
    ///
    /// - Documentation: [ZRANK](https:/redis.io/docs/latest/commands/zrank)
    /// - Version: 2.0.0
    /// - Complexity: O(log(N))
    /// - Categories: @read, @sortedset, @fast
    /// - Returns: One of the following:
    ///     * [Null](https:/redis.io/docs/reference/protocol-spec#nulls): if the key does not exist or the member does not exist in the sorted set.
    ///     * [Integer](https:/redis.io/docs/reference/protocol-spec#integers): the rank of the member when _WITHSCORE_ is not used.
    ///     * [Array](https:/redis.io/docs/reference/protocol-spec#arrays): the rank and score of the member when _WITHSCORE_ is used.
    @inlinable
    public func zrank(key: RedisKey, member: String, withscore: Bool = false) async throws -> RESPToken {
        try await send("ZRANK", key, member, RedisPureToken("WITHSCORE", withscore))
    }

    /// Removes one or more members from a sorted set. Deletes the sorted set if all members were removed.
    ///
    /// - Documentation: [ZREM](https:/redis.io/docs/latest/commands/zrem)
    /// - Version: 1.2.0
    /// - Complexity: O(M*log(N)) with N being the number of elements in the sorted set and M the number of elements to be removed.
    /// - Categories: @write, @sortedset, @fast
    /// - Returns: [Integer](https:/redis.io/docs/reference/protocol-spec#integers): the number of members removed from the sorted set, not including non-existing members.
    @inlinable
    public func zrem(key: RedisKey, member: String) async throws -> Int {
        try await send("ZREM", key, member).converting()
    }

    /// Removes one or more members from a sorted set. Deletes the sorted set if all members were removed.
    ///
    /// - Documentation: [ZREM](https:/redis.io/docs/latest/commands/zrem)
    /// - Version: 1.2.0
    /// - Complexity: O(M*log(N)) with N being the number of elements in the sorted set and M the number of elements to be removed.
    /// - Categories: @write, @sortedset, @fast
    /// - Returns: [Integer](https:/redis.io/docs/reference/protocol-spec#integers): the number of members removed from the sorted set, not including non-existing members.
    @inlinable
    public func zrem(key: RedisKey, members: [String]) async throws -> Int {
        try await send("ZREM", key, members).converting()
    }

    /// Removes members in a sorted set within a lexicographical range. Deletes the sorted set if all members were removed.
    ///
    /// - Documentation: [ZREMRANGEBYLEX](https:/redis.io/docs/latest/commands/zremrangebylex)
    /// - Version: 2.8.9
    /// - Complexity: O(log(N)+M) with N being the number of elements in the sorted set and M the number of elements removed by the operation.
    /// - Categories: @write, @sortedset, @slow
    /// - Returns: [Integer](https:/redis.io/docs/reference/protocol-spec#integers): Number of members removed.
    @inlinable
    public func zremrangebylex(key: RedisKey, min: String, max: String) async throws -> Int {
        try await send("ZREMRANGEBYLEX", key, min, max).converting()
    }

    /// Removes members in a sorted set within a range of indexes. Deletes the sorted set if all members were removed.
    ///
    /// - Documentation: [ZREMRANGEBYRANK](https:/redis.io/docs/latest/commands/zremrangebyrank)
    /// - Version: 2.0.0
    /// - Complexity: O(log(N)+M) with N being the number of elements in the sorted set and M the number of elements removed by the operation.
    /// - Categories: @write, @sortedset, @slow
    /// - Returns: [Integer](https:/redis.io/docs/reference/protocol-spec#integers): Number of members removed.
    @inlinable
    public func zremrangebyrank(key: RedisKey, start: Int, stop: Int) async throws -> Int {
        try await send("ZREMRANGEBYRANK", key, start, stop).converting()
    }

    /// Removes members in a sorted set within a range of scores. Deletes the sorted set if all members were removed.
    ///
    /// - Documentation: [ZREMRANGEBYSCORE](https:/redis.io/docs/latest/commands/zremrangebyscore)
    /// - Version: 1.2.0
    /// - Complexity: O(log(N)+M) with N being the number of elements in the sorted set and M the number of elements removed by the operation.
    /// - Categories: @write, @sortedset, @slow
    /// - Returns: [Integer](https:/redis.io/docs/reference/protocol-spec#integers): Number of members removed.
    @inlinable
    public func zremrangebyscore(key: RedisKey, min: Double, max: Double) async throws -> Int {
        try await send("ZREMRANGEBYSCORE", key, min, max).converting()
    }

    /// Returns members in a sorted set within a range of indexes in reverse order.
    ///
    /// - Documentation: [ZREVRANGE](https:/redis.io/docs/latest/commands/zrevrange)
    /// - Version: 1.2.0
    /// - Complexity: O(log(N)+M) with N being the number of elements in the sorted set and M the number of elements returned.
    /// - Categories: @read, @sortedset, @slow
    /// - Returns: * [Array](https:/redis.io/docs/reference/protocol-spec#arrays): a list of members in the specified range, optionally with their scores if _WITHSCORE_ was used.
    @inlinable
    public func zrevrange(key: RedisKey, start: Int, stop: Int, withscores: Bool = false) async throws -> RESPToken {
        try await send("ZREVRANGE", key, start, stop, RedisPureToken("WITHSCORES", withscores))
    }

    /// Returns members in a sorted set within a lexicographical range in reverse order.
    ///
    /// - Documentation: [ZREVRANGEBYLEX](https:/redis.io/docs/latest/commands/zrevrangebylex)
    /// - Version: 2.8.9
    /// - Complexity: O(log(N)+M) with N being the number of elements in the sorted set and M the number of elements being returned. If M is constant (e.g. always asking for the first 10 elements with LIMIT), you can consider it O(log(N)).
    /// - Categories: @read, @sortedset, @slow
    /// - Returns: [Array](https:/redis.io/docs/reference/protocol-spec#arrays): List of the elements in the specified score range.
    @inlinable
    public func zrevrangebylex(key: RedisKey, max: String, min: String, limit: RESPCommand.ZREVRANGEBYLEXLimit? = nil) async throws -> [RESPToken] {
        try await send("ZREVRANGEBYLEX", key, max, min, RESPWithToken("LIMIT", limit)).converting()
    }

    /// Returns members in a sorted set within a range of scores in reverse order.
    ///
    /// - Documentation: [ZREVRANGEBYSCORE](https:/redis.io/docs/latest/commands/zrevrangebyscore)
    /// - Version: 2.2.0
    /// - Complexity: O(log(N)+M) with N being the number of elements in the sorted set and M the number of elements being returned. If M is constant (e.g. always asking for the first 10 elements with LIMIT), you can consider it O(log(N)).
    /// - Categories: @read, @sortedset, @slow
    /// - Returns: * [Array](https:/redis.io/docs/reference/protocol-spec#arrays): a list of the members and, optionally, their scores in the specified score range.
    @inlinable
    public func zrevrangebyscore(key: RedisKey, max: Double, min: Double, withscores: Bool = false, limit: RESPCommand.ZREVRANGEBYSCORELimit? = nil) async throws -> RESPToken {
        try await send("ZREVRANGEBYSCORE", key, max, min, RedisPureToken("WITHSCORES", withscores), RESPWithToken("LIMIT", limit))
    }

    /// Returns the index of a member in a sorted set ordered by descending scores.
    ///
    /// - Documentation: [ZREVRANK](https:/redis.io/docs/latest/commands/zrevrank)
    /// - Version: 2.0.0
    /// - Complexity: O(log(N))
    /// - Categories: @read, @sortedset, @fast
    /// - Returns: One of the following:
    ///     * [Null](https:/redis.io/docs/reference/protocol-spec#nulls): if the key does not exist or the member does not exist in the sorted set.
    ///     * [Integer](https:/redis.io/docs/reference/protocol-spec#integers): The rank of the member when _WITHSCORE_ is not used.
    ///     * [Array](https:/redis.io/docs/reference/protocol-spec#arrays): The rank and score of the member when _WITHSCORE_ is used.
    @inlinable
    public func zrevrank(key: RedisKey, member: String, withscore: Bool = false) async throws -> RESPToken {
        try await send("ZREVRANK", key, member, RedisPureToken("WITHSCORE", withscore))
    }

    /// Iterates over members and scores of a sorted set.
    ///
    /// - Documentation: [ZSCAN](https:/redis.io/docs/latest/commands/zscan)
    /// - Version: 2.8.0
    /// - Complexity: O(1) for every call. O(N) for a complete iteration, including enough command calls for the cursor to return back to 0. N is the number of elements inside the collection.
    /// - Categories: @read, @sortedset, @slow
    /// - Returns: [Array](https:/redis.io/docs/reference/protocol-spec#arrays): cursor and scan response in array form.
    @inlinable
    public func zscan(key: RedisKey, cursor: Int, pattern: String? = nil, count: Int? = nil) async throws -> [RESPToken] {
        try await send("ZSCAN", key, cursor, RESPWithToken("MATCH", pattern), RESPWithToken("COUNT", count)).converting()
    }

    /// Returns the score of a member in a sorted set.
    ///
    /// - Documentation: [ZSCORE](https:/redis.io/docs/latest/commands/zscore)
    /// - Version: 1.2.0
    /// - Complexity: O(1)
    /// - Categories: @read, @sortedset, @fast
    /// - Returns: One of the following:
    ///     * [Double](https:/redis.io/docs/reference/protocol-spec#doubles): the score of the member (a double-precision floating point number).
    ///     * [Nil](https:/redis.io/docs/reference/protocol-spec#bulk-strings): if _member_ does not exist in the sorted set, or the key does not exist.
    @inlinable
    public func zscore(key: RedisKey, member: String) async throws -> RESPToken {
        try await send("ZSCORE", key, member)
    }

    /// Returns the union of multiple sorted sets.
    ///
    /// - Documentation: [ZUNION](https:/redis.io/docs/latest/commands/zunion)
    /// - Version: 6.2.0
    /// - Complexity: O(N)+O(M*log(M)) with N being the sum of the sizes of the input sorted sets, and M being the number of elements in the resulting sorted set.
    /// - Categories: @read, @sortedset, @slow
    /// - Returns: [Array](https:/redis.io/docs/reference/protocol-spec#arrays): the result of the union with, optionally, their scores when _WITHSCORES_ is used.
    @inlinable
    public func zunion(key: RedisKey, weight: Int? = nil, aggregate: RESPCommand.ZUNIONAggregate? = nil, withscores: Bool = false) async throws -> [RESPToken] {
        try await send("ZUNION", 1, key, RESPWithToken("WEIGHTS", weight), RESPWithToken("AGGREGATE", aggregate), RedisPureToken("WITHSCORES", withscores)).converting()
    }

    /// Returns the union of multiple sorted sets.
    ///
    /// - Documentation: [ZUNION](https:/redis.io/docs/latest/commands/zunion)
    /// - Version: 6.2.0
    /// - Complexity: O(N)+O(M*log(M)) with N being the sum of the sizes of the input sorted sets, and M being the number of elements in the resulting sorted set.
    /// - Categories: @read, @sortedset, @slow
    /// - Returns: [Array](https:/redis.io/docs/reference/protocol-spec#arrays): the result of the union with, optionally, their scores when _WITHSCORES_ is used.
    @inlinable
    public func zunion(keys: [RedisKey], weights: [Int], aggregate: RESPCommand.ZUNIONAggregate? = nil, withscores: Bool = false) async throws -> [RESPToken] {
        try await send("ZUNION", RESPArrayWithCount(keys), RESPWithToken("WEIGHTS", weights), RESPWithToken("AGGREGATE", aggregate), RedisPureToken("WITHSCORES", withscores)).converting()
    }

    /// Stores the union of multiple sorted sets in a key.
    ///
    /// - Documentation: [ZUNIONSTORE](https:/redis.io/docs/latest/commands/zunionstore)
    /// - Version: 2.0.0
    /// - Complexity: O(N)+O(M log(M)) with N being the sum of the sizes of the input sorted sets, and M being the number of elements in the resulting sorted set.
    /// - Categories: @write, @sortedset, @slow
    /// - Returns: [Integer](https:/redis.io/docs/reference/protocol-spec#integers): the number of elements in the resulting sorted set.
    @inlinable
    public func zunionstore(destination: RedisKey, key: RedisKey, weight: Int? = nil, aggregate: RESPCommand.ZUNIONSTOREAggregate? = nil) async throws -> Int {
        try await send("ZUNIONSTORE", destination, 1, key, RESPWithToken("WEIGHTS", weight), RESPWithToken("AGGREGATE", aggregate)).converting()
    }

    /// Stores the union of multiple sorted sets in a key.
    ///
    /// - Documentation: [ZUNIONSTORE](https:/redis.io/docs/latest/commands/zunionstore)
    /// - Version: 2.0.0
    /// - Complexity: O(N)+O(M log(M)) with N being the sum of the sizes of the input sorted sets, and M being the number of elements in the resulting sorted set.
    /// - Categories: @write, @sortedset, @slow
    /// - Returns: [Integer](https:/redis.io/docs/reference/protocol-spec#integers): the number of elements in the resulting sorted set.
    @inlinable
    public func zunionstore(destination: RedisKey, keys: [RedisKey], weights: [Int], aggregate: RESPCommand.ZUNIONSTOREAggregate? = nil) async throws -> Int {
        try await send("ZUNIONSTORE", destination, RESPArrayWithCount(keys), RESPWithToken("WEIGHTS", weights), RESPWithToken("AGGREGATE", aggregate)).converting()
    }

}
