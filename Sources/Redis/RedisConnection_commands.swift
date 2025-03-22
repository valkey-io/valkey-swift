import NIOCore
import RESP3

#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

extension RedisConnection {
    /// A container for Access List Control commands.
    ///
    /// Version: 6.0.0
    /// Complexity: Depends on subcommand.
    /// Categories: @slow
    @inlinable
    public func acl() async throws -> RESP3Token {
        let response = try await send(aclCommand())
        return response
    }

    @inlinable
    public func aclCommand() -> RESPCommand {
        RESPCommand("ACL")
    }

    /// Lists the ACL categories, or the commands inside a category.
    ///
    /// Version: 6.0.0
    /// Complexity: O(1) since the categories and commands are a fixed set.
    /// Categories: @slow
    @inlinable
    public func aclCat(category: String?) async throws -> RESP3Token {
        let response = try await send(aclCatCommand(category: category))
        return response
    }

    @inlinable
    public func aclCatCommand(category: String?) -> RESPCommand {
        RESPCommand("ACL", "CAT", category)
    }

    /// Deletes ACL users, and terminates their connections.
    ///
    /// Version: 6.0.0
    /// Complexity: O(1) amortized time considering the typical user.
    /// Categories: @admin, @slow, @dangerous
    @inlinable
    public func aclDeluser(username: String...) async throws -> RESP3Token {
        let response = try await send(aclDeluserCommand(username: username))
        return response
    }

    @inlinable
    public func aclDeluserCommand(username: [String]) -> RESPCommand {
        RESPCommand("ACL", "DELUSER", username)
    }

    /// Simulates the execution of a command by a user, without executing the command.
    ///
    /// Version: 7.0.0
    /// Complexity: O(1).
    /// Categories: @admin, @slow, @dangerous
    @inlinable
    public func aclDryrun(username: String, command: String, arg: String...) async throws -> RESP3Token {
        let response = try await send(aclDryrunCommand(username: username, command: command, arg: arg))
        return response
    }

    @inlinable
    public func aclDryrunCommand(username: String, command: String, arg: [String]) -> RESPCommand {
        RESPCommand("ACL", "DRYRUN", username, command, arg)
    }

    /// Generates a pseudorandom, secure password that can be used to identify ACL users.
    ///
    /// Version: 6.0.0
    /// Complexity: O(1)
    /// Categories: @slow
    @inlinable
    public func aclGenpass(bits: Int?) async throws -> RESP3Token {
        let response = try await send(aclGenpassCommand(bits: bits))
        return response
    }

    @inlinable
    public func aclGenpassCommand(bits: Int?) -> RESPCommand {
        RESPCommand("ACL", "GENPASS", bits)
    }

    /// Lists the ACL rules of a user.
    ///
    /// Version: 6.0.0
    /// Complexity: O(N). Where N is the number of password, command and pattern rules that the user has.
    /// Categories: @admin, @slow, @dangerous
    @inlinable
    public func aclGetuser(username: String) async throws -> RESP3Token {
        let response = try await send(aclGetuserCommand(username: username))
        return response
    }

    @inlinable
    public func aclGetuserCommand(username: String) -> RESPCommand {
        RESPCommand("ACL", "GETUSER", username)
    }

    /// Returns helpful text about the different subcommands.
    ///
    /// Version: 6.0.0
    /// Complexity: O(1)
    /// Categories: @slow
    @inlinable
    public func aclHelp() async throws -> RESP3Token {
        let response = try await send(aclHelpCommand())
        return response
    }

    @inlinable
    public func aclHelpCommand() -> RESPCommand {
        RESPCommand("ACL", "HELP")
    }

    /// Dumps the effective rules in ACL file format.
    ///
    /// Version: 6.0.0
    /// Complexity: O(N). Where N is the number of configured users.
    /// Categories: @admin, @slow, @dangerous
    @inlinable
    public func aclList() async throws -> RESP3Token {
        let response = try await send(aclListCommand())
        return response
    }

    @inlinable
    public func aclListCommand() -> RESPCommand {
        RESPCommand("ACL", "LIST")
    }

    /// Reloads the rules from the configured ACL file.
    ///
    /// Version: 6.0.0
    /// Complexity: O(N). Where N is the number of configured users.
    /// Categories: @admin, @slow, @dangerous
    @inlinable
    public func aclLoad() async throws -> RESP3Token {
        let response = try await send(aclLoadCommand())
        return response
    }

    @inlinable
    public func aclLoadCommand() -> RESPCommand {
        RESPCommand("ACL", "LOAD")
    }

    public enum ACLLOGOperation: RESPRepresentable {
        case count(Int)
        case reset

        @inlinable
        public func writeToRESPBuffer(_ buffer: inout ByteBuffer) {
            switch self {
            case .count(let count): count.writeToRESPBuffer(&buffer)
            case .reset: "RESET".writeToRESPBuffer(&buffer)
            }
        }
    }
    /// Lists recent security events generated due to ACL rules.
    ///
    /// Version: 6.0.0
    /// Complexity: O(N) with N being the number of entries shown.
    /// Categories: @admin, @slow, @dangerous
    @inlinable
    public func aclLog(operation: ACLLOGOperation?) async throws -> RESP3Token {
        let response = try await send(aclLogCommand(operation: operation))
        return response
    }

    @inlinable
    public func aclLogCommand(operation: ACLLOGOperation?) -> RESPCommand {
        RESPCommand("ACL", "LOG", operation)
    }

    /// Saves the effective ACL rules in the configured ACL file.
    ///
    /// Version: 6.0.0
    /// Complexity: O(N). Where N is the number of configured users.
    /// Categories: @admin, @slow, @dangerous
    @inlinable
    public func aclSave() async throws -> RESP3Token {
        let response = try await send(aclSaveCommand())
        return response
    }

    @inlinable
    public func aclSaveCommand() -> RESPCommand {
        RESPCommand("ACL", "SAVE")
    }

    /// Creates and modifies an ACL user and its rules.
    ///
    /// Version: 6.0.0
    /// Complexity: O(N). Where N is the number of rules provided.
    /// Categories: @admin, @slow, @dangerous
    @inlinable
    public func aclSetuser(username: String, rule: String...) async throws -> RESP3Token {
        let response = try await send(aclSetuserCommand(username: username, rule: rule))
        return response
    }

    @inlinable
    public func aclSetuserCommand(username: String, rule: [String]) -> RESPCommand {
        RESPCommand("ACL", "SETUSER", username, rule)
    }

    /// Lists all ACL users.
    ///
    /// Version: 6.0.0
    /// Complexity: O(N). Where N is the number of configured users.
    /// Categories: @admin, @slow, @dangerous
    @inlinable
    public func aclUsers() async throws -> RESP3Token {
        let response = try await send(aclUsersCommand())
        return response
    }

    @inlinable
    public func aclUsersCommand() -> RESPCommand {
        RESPCommand("ACL", "USERS")
    }

    /// Returns the authenticated username of the current connection.
    ///
    /// Version: 6.0.0
    /// Complexity: O(1)
    /// Categories: @slow
    @inlinable
    public func aclWhoami() async throws -> RESP3Token {
        let response = try await send(aclWhoamiCommand())
        return response
    }

    @inlinable
    public func aclWhoamiCommand() -> RESPCommand {
        RESPCommand("ACL", "WHOAMI")
    }

    /// Appends a string to the value of a key. Creates the key if it doesn't exist.
    ///
    /// Version: 2.0.0
    /// Complexity: O(1). The amortized time complexity is O(1) assuming the appended value is small and the already present value is of any size, since the dynamic string library used by Redis will double the free space available on every reallocation.
    /// Categories: @write, @string, @fast
    @inlinable
    public func append(key: RedisKey, value: String) async throws -> RESP3Token {
        let response = try await send(appendCommand(key: key, value: value))
        return response
    }

    @inlinable
    public func appendCommand(key: RedisKey, value: String) -> RESPCommand {
        RESPCommand("APPEND", key, value)
    }

    /// Signals that a cluster client is following an -ASK redirect.
    ///
    /// Version: 3.0.0
    /// Complexity: O(1)
    /// Categories: @fast, @connection
    @inlinable
    public func asking() async throws -> RESP3Token {
        let response = try await send(askingCommand())
        return response
    }

    @inlinable
    public func askingCommand() -> RESPCommand {
        RESPCommand("ASKING")
    }

    /// Authenticates the connection.
    ///
    /// Version: 1.0.0
    /// Complexity: O(N) where N is the number of passwords defined for the user
    /// Categories: @fast, @connection
    @inlinable
    public func auth(username: String?, password: String) async throws -> RESP3Token {
        let response = try await send(authCommand(username: username, password: password))
        return response
    }

    @inlinable
    public func authCommand(username: String?, password: String) -> RESPCommand {
        RESPCommand("AUTH", username, password)
    }

    /// Asynchronously rewrites the append-only file to disk.
    ///
    /// Version: 1.0.0
    /// Complexity: O(1)
    /// Categories: @admin, @slow, @dangerous
    @inlinable
    public func bgrewriteaof() async throws -> RESP3Token {
        let response = try await send(bgrewriteaofCommand())
        return response
    }

    @inlinable
    public func bgrewriteaofCommand() -> RESPCommand {
        RESPCommand("BGREWRITEAOF")
    }

    /// Asynchronously saves the database(s) to disk.
    ///
    /// Version: 1.0.0
    /// Complexity: O(1)
    /// Categories: @admin, @slow, @dangerous
    @inlinable
    public func bgsave(schedule: Bool) async throws -> RESP3Token {
        let response = try await send(bgsaveCommand(schedule: schedule))
        return response
    }

    @inlinable
    public func bgsaveCommand(schedule: Bool) -> RESPCommand {
        RESPCommand("BGSAVE", RedisPureToken("SCHEDULE", schedule))
    }

    public enum BITCOUNTRangeUnit: RESPRepresentable {
        case byte
        case bit

        @inlinable
        public func writeToRESPBuffer(_ buffer: inout ByteBuffer) {
            switch self {
            case .byte: "BYTE".writeToRESPBuffer(&buffer)
            case .bit: "BIT".writeToRESPBuffer(&buffer)
            }
        }
    }
    public struct BITCOUNTRange: RESPRepresentable {
        @usableFromInline let start: Int
        @usableFromInline let end: Int
        @usableFromInline let unit: BITCOUNTRangeUnit?

        @inlinable
        public func writeToRESPBuffer(_ buffer: inout ByteBuffer) {
            self.start.writeToRESPBuffer(&buffer)
            self.end.writeToRESPBuffer(&buffer)
            self.unit.writeToRESPBuffer(&buffer)
        }
    }
    /// Counts the number of set bits (population counting) in a string.
    ///
    /// Version: 2.6.0
    /// Complexity: O(N)
    /// Categories: @read, @bitmap, @slow
    @inlinable
    public func bitcount(key: RedisKey, range: BITCOUNTRange?) async throws -> RESP3Token {
        let response = try await send(bitcountCommand(key: key, range: range))
        return response
    }

    @inlinable
    public func bitcountCommand(key: RedisKey, range: BITCOUNTRange?) -> RESPCommand {
        RESPCommand("BITCOUNT", key, range)
    }

    public struct BITFIELDOperationGetBlock: RESPRepresentable {
        @usableFromInline let encoding: String
        @usableFromInline let offset: Int

        @inlinable
        public func writeToRESPBuffer(_ buffer: inout ByteBuffer) {
            self.encoding.writeToRESPBuffer(&buffer)
            self.offset.writeToRESPBuffer(&buffer)
        }
    }
    public enum BITFIELDOperationWriteOverflowBlock: RESPRepresentable {
        case wrap
        case sat
        case fail

        @inlinable
        public func writeToRESPBuffer(_ buffer: inout ByteBuffer) {
            switch self {
            case .wrap: "WRAP".writeToRESPBuffer(&buffer)
            case .sat: "SAT".writeToRESPBuffer(&buffer)
            case .fail: "FAIL".writeToRESPBuffer(&buffer)
            }
        }
    }
    public struct BITFIELDOperationWriteWriteOperationSetBlock: RESPRepresentable {
        @usableFromInline let encoding: String
        @usableFromInline let offset: Int
        @usableFromInline let value: Int

        @inlinable
        public func writeToRESPBuffer(_ buffer: inout ByteBuffer) {
            self.encoding.writeToRESPBuffer(&buffer)
            self.offset.writeToRESPBuffer(&buffer)
            self.value.writeToRESPBuffer(&buffer)
        }
    }
    public struct BITFIELDOperationWriteWriteOperationIncrbyBlock: RESPRepresentable {
        @usableFromInline let encoding: String
        @usableFromInline let offset: Int
        @usableFromInline let increment: Int

        @inlinable
        public func writeToRESPBuffer(_ buffer: inout ByteBuffer) {
            self.encoding.writeToRESPBuffer(&buffer)
            self.offset.writeToRESPBuffer(&buffer)
            self.increment.writeToRESPBuffer(&buffer)
        }
    }
    public enum BITFIELDOperationWriteWriteOperation: RESPRepresentable {
        case setBlock(BITFIELDOperationWriteWriteOperationSetBlock)
        case incrbyBlock(BITFIELDOperationWriteWriteOperationIncrbyBlock)

        @inlinable
        public func writeToRESPBuffer(_ buffer: inout ByteBuffer) {
            switch self {
            case .setBlock(let setBlock): RESPWithToken("SET", setBlock).writeToRESPBuffer(&buffer)
            case .incrbyBlock(let incrbyBlock): RESPWithToken("INCRBY", incrbyBlock).writeToRESPBuffer(&buffer)
            }
        }
    }
    public struct BITFIELDOperationWrite: RESPRepresentable {
        @usableFromInline let overflowBlock: BITFIELDOperationWriteOverflowBlock?
        @usableFromInline let writeOperation: BITFIELDOperationWriteWriteOperation

        @inlinable
        public func writeToRESPBuffer(_ buffer: inout ByteBuffer) {
            self.overflowBlock.writeToRESPBuffer(&buffer)
            self.writeOperation.writeToRESPBuffer(&buffer)
        }
    }
    public enum BITFIELDOperation: RESPRepresentable {
        case getBlock(BITFIELDOperationGetBlock)
        case write(BITFIELDOperationWrite)

        @inlinable
        public func writeToRESPBuffer(_ buffer: inout ByteBuffer) {
            switch self {
            case .getBlock(let getBlock): RESPWithToken("GET", getBlock).writeToRESPBuffer(&buffer)
            case .write(let write): write.writeToRESPBuffer(&buffer)
            }
        }
    }
    /// Performs arbitrary bitfield integer operations on strings.
    ///
    /// Version: 3.2.0
    /// Complexity: O(1) for each subcommand specified
    /// Categories: @write, @bitmap, @slow
    @inlinable
    public func bitfield(key: RedisKey, operation: BITFIELDOperation...) async throws -> RESP3Token {
        let response = try await send(bitfieldCommand(key: key, operation: operation))
        return response
    }

    @inlinable
    public func bitfieldCommand(key: RedisKey, operation: [BITFIELDOperation]) -> RESPCommand {
        RESPCommand("BITFIELD", key, operation)
    }

    public struct BITFIELDROGetBlock: RESPRepresentable {
        @usableFromInline let encoding: String
        @usableFromInline let offset: Int

        @inlinable
        public func writeToRESPBuffer(_ buffer: inout ByteBuffer) {
            self.encoding.writeToRESPBuffer(&buffer)
            self.offset.writeToRESPBuffer(&buffer)
        }
    }
    /// Performs arbitrary read-only bitfield integer operations on strings.
    ///
    /// Version: 6.0.0
    /// Complexity: O(1) for each subcommand specified
    /// Categories: @read, @bitmap, @fast
    @inlinable
    public func bitfieldRo(key: RedisKey, getBlock: BITFIELDROGetBlock...) async throws -> RESP3Token {
        let response = try await send(bitfieldRoCommand(key: key, getBlock: getBlock))
        return response
    }

    @inlinable
    public func bitfieldRoCommand(key: RedisKey, getBlock: [BITFIELDROGetBlock]) -> RESPCommand {
        RESPCommand("BITFIELD_RO", key, RESPWithToken("GET", getBlock))
    }

    public enum BITOPOperation: RESPRepresentable {
        case and
        case or
        case xor
        case not

        @inlinable
        public func writeToRESPBuffer(_ buffer: inout ByteBuffer) {
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
    /// Version: 2.6.0
    /// Complexity: O(N)
    /// Categories: @write, @bitmap, @slow
    @inlinable
    public func bitop(operation: BITOPOperation, destkey: RedisKey, key: RedisKey...) async throws -> RESP3Token {
        let response = try await send(bitopCommand(operation: operation, destkey: destkey, key: key))
        return response
    }

    @inlinable
    public func bitopCommand(operation: BITOPOperation, destkey: RedisKey, key: [RedisKey]) -> RESPCommand {
        RESPCommand("BITOP", operation, destkey, key)
    }

    public enum BITPOSRangeEndUnitBlockUnit: RESPRepresentable {
        case byte
        case bit

        @inlinable
        public func writeToRESPBuffer(_ buffer: inout ByteBuffer) {
            switch self {
            case .byte: "BYTE".writeToRESPBuffer(&buffer)
            case .bit: "BIT".writeToRESPBuffer(&buffer)
            }
        }
    }
    public struct BITPOSRangeEndUnitBlock: RESPRepresentable {
        @usableFromInline let end: Int
        @usableFromInline let unit: BITPOSRangeEndUnitBlockUnit?

        @inlinable
        public func writeToRESPBuffer(_ buffer: inout ByteBuffer) {
            self.end.writeToRESPBuffer(&buffer)
            self.unit.writeToRESPBuffer(&buffer)
        }
    }
    public struct BITPOSRange: RESPRepresentable {
        @usableFromInline let start: Int
        @usableFromInline let endUnitBlock: BITPOSRangeEndUnitBlock?

        @inlinable
        public func writeToRESPBuffer(_ buffer: inout ByteBuffer) {
            self.start.writeToRESPBuffer(&buffer)
            self.endUnitBlock.writeToRESPBuffer(&buffer)
        }
    }
    /// Finds the first set (1) or clear (0) bit in a string.
    ///
    /// Version: 2.8.7
    /// Complexity: O(N)
    /// Categories: @read, @bitmap, @slow
    @inlinable
    public func bitpos(key: RedisKey, bit: Int, range: BITPOSRange?) async throws -> RESP3Token {
        let response = try await send(bitposCommand(key: key, bit: bit, range: range))
        return response
    }

    @inlinable
    public func bitposCommand(key: RedisKey, bit: Int, range: BITPOSRange?) -> RESPCommand {
        RESPCommand("BITPOS", key, bit, range)
    }

    public enum BLMOVEWherefrom: RESPRepresentable {
        case left
        case right

        @inlinable
        public func writeToRESPBuffer(_ buffer: inout ByteBuffer) {
            switch self {
            case .left: "LEFT".writeToRESPBuffer(&buffer)
            case .right: "RIGHT".writeToRESPBuffer(&buffer)
            }
        }
    }
    public enum BLMOVEWhereto: RESPRepresentable {
        case left
        case right

        @inlinable
        public func writeToRESPBuffer(_ buffer: inout ByteBuffer) {
            switch self {
            case .left: "LEFT".writeToRESPBuffer(&buffer)
            case .right: "RIGHT".writeToRESPBuffer(&buffer)
            }
        }
    }
    /// Pops an element from a list, pushes it to another list and returns it. Blocks until an element is available otherwise. Deletes the list if the last element was moved.
    ///
    /// Version: 6.2.0
    /// Complexity: O(1)
    /// Categories: @write, @list, @slow, @blocking
    @inlinable
    public func blmove(source: RedisKey, destination: RedisKey, wherefrom: BLMOVEWherefrom, whereto: BLMOVEWhereto, timeout: Double) async throws -> RESP3Token {
        let response = try await send(blmoveCommand(source: source, destination: destination, wherefrom: wherefrom, whereto: whereto, timeout: timeout))
        return response
    }

    @inlinable
    public func blmoveCommand(source: RedisKey, destination: RedisKey, wherefrom: BLMOVEWherefrom, whereto: BLMOVEWhereto, timeout: Double) -> RESPCommand {
        RESPCommand("BLMOVE", source, destination, wherefrom, whereto, timeout)
    }

    public enum BLMPOPWhere: RESPRepresentable {
        case left
        case right

        @inlinable
        public func writeToRESPBuffer(_ buffer: inout ByteBuffer) {
            switch self {
            case .left: "LEFT".writeToRESPBuffer(&buffer)
            case .right: "RIGHT".writeToRESPBuffer(&buffer)
            }
        }
    }
    /// Pops the first element from one of multiple lists. Blocks until an element is available otherwise. Deletes the list if the last element was popped.
    ///
    /// Version: 7.0.0
    /// Complexity: O(N+M) where N is the number of provided keys and M is the number of elements returned.
    /// Categories: @write, @list, @slow, @blocking
    @inlinable
    public func blmpop(timeout: Double, numkeys: Int, key: RedisKey..., where: BLMPOPWhere, count: Int?) async throws -> RESP3Token {
        let response = try await send(blmpopCommand(timeout: timeout, numkeys: numkeys, key: key, where: `where`, count: count))
        return response
    }

    @inlinable
    public func blmpopCommand(timeout: Double, numkeys: Int, key: [RedisKey], where: BLMPOPWhere, count: Int?) -> RESPCommand {
        RESPCommand("BLMPOP", timeout, numkeys, key, `where`, RESPWithToken("COUNT", count))
    }

    /// Removes and returns the first element in a list. Blocks until an element is available otherwise. Deletes the list if the last element was popped.
    ///
    /// Version: 2.0.0
    /// Complexity: O(N) where N is the number of provided keys.
    /// Categories: @write, @list, @slow, @blocking
    @inlinable
    public func blpop(key: RedisKey..., timeout: Double) async throws -> RESP3Token {
        let response = try await send(blpopCommand(key: key, timeout: timeout))
        return response
    }

    @inlinable
    public func blpopCommand(key: [RedisKey], timeout: Double) -> RESPCommand {
        RESPCommand("BLPOP", key, timeout)
    }

    /// Removes and returns the last element in a list. Blocks until an element is available otherwise. Deletes the list if the last element was popped.
    ///
    /// Version: 2.0.0
    /// Complexity: O(N) where N is the number of provided keys.
    /// Categories: @write, @list, @slow, @blocking
    @inlinable
    public func brpop(key: RedisKey..., timeout: Double) async throws -> RESP3Token {
        let response = try await send(brpopCommand(key: key, timeout: timeout))
        return response
    }

    @inlinable
    public func brpopCommand(key: [RedisKey], timeout: Double) -> RESPCommand {
        RESPCommand("BRPOP", key, timeout)
    }

    /// Pops an element from a list, pushes it to another list and returns it. Block until an element is available otherwise. Deletes the list if the last element was popped.
    ///
    /// Version: 2.2.0
    /// Complexity: O(1)
    /// Categories: @write, @list, @slow, @blocking
    @inlinable
    public func brpoplpush(source: RedisKey, destination: RedisKey, timeout: Double) async throws -> RESP3Token {
        let response = try await send(brpoplpushCommand(source: source, destination: destination, timeout: timeout))
        return response
    }

    @inlinable
    public func brpoplpushCommand(source: RedisKey, destination: RedisKey, timeout: Double) -> RESPCommand {
        RESPCommand("BRPOPLPUSH", source, destination, timeout)
    }

    public enum BZMPOPWhere: RESPRepresentable {
        case min
        case max

        @inlinable
        public func writeToRESPBuffer(_ buffer: inout ByteBuffer) {
            switch self {
            case .min: "MIN".writeToRESPBuffer(&buffer)
            case .max: "MAX".writeToRESPBuffer(&buffer)
            }
        }
    }
    /// Removes and returns a member by score from one or more sorted sets. Blocks until a member is available otherwise. Deletes the sorted set if the last element was popped.
    ///
    /// Version: 7.0.0
    /// Complexity: O(K) + O(M*log(N)) where K is the number of provided keys, N being the number of elements in the sorted set, and M being the number of elements popped.
    /// Categories: @write, @sortedset, @slow, @blocking
    @inlinable
    public func bzmpop(timeout: Double, numkeys: Int, key: RedisKey..., where: BZMPOPWhere, count: Int?) async throws -> RESP3Token {
        let response = try await send(bzmpopCommand(timeout: timeout, numkeys: numkeys, key: key, where: `where`, count: count))
        return response
    }

    @inlinable
    public func bzmpopCommand(timeout: Double, numkeys: Int, key: [RedisKey], where: BZMPOPWhere, count: Int?) -> RESPCommand {
        RESPCommand("BZMPOP", timeout, numkeys, key, `where`, RESPWithToken("COUNT", count))
    }

    /// Removes and returns the member with the highest score from one or more sorted sets. Blocks until a member available otherwise.  Deletes the sorted set if the last element was popped.
    ///
    /// Version: 5.0.0
    /// Complexity: O(log(N)) with N being the number of elements in the sorted set.
    /// Categories: @write, @sortedset, @fast, @blocking
    @inlinable
    public func bzpopmax(key: RedisKey..., timeout: Double) async throws -> RESP3Token {
        let response = try await send(bzpopmaxCommand(key: key, timeout: timeout))
        return response
    }

    @inlinable
    public func bzpopmaxCommand(key: [RedisKey], timeout: Double) -> RESPCommand {
        RESPCommand("BZPOPMAX", key, timeout)
    }

    /// Removes and returns the member with the lowest score from one or more sorted sets. Blocks until a member is available otherwise. Deletes the sorted set if the last element was popped.
    ///
    /// Version: 5.0.0
    /// Complexity: O(log(N)) with N being the number of elements in the sorted set.
    /// Categories: @write, @sortedset, @fast, @blocking
    @inlinable
    public func bzpopmin(key: RedisKey..., timeout: Double) async throws -> RESP3Token {
        let response = try await send(bzpopminCommand(key: key, timeout: timeout))
        return response
    }

    @inlinable
    public func bzpopminCommand(key: [RedisKey], timeout: Double) -> RESPCommand {
        RESPCommand("BZPOPMIN", key, timeout)
    }

    /// A container for client connection commands.
    ///
    /// Version: 2.4.0
    /// Complexity: Depends on subcommand.
    /// Categories: @slow
    @inlinable
    public func client() async throws -> RESP3Token {
        let response = try await send(clientCommand())
        return response
    }

    @inlinable
    public func clientCommand() -> RESPCommand {
        RESPCommand("CLIENT")
    }

    public enum CLIENTCACHINGMode: RESPRepresentable {
        case yes
        case no

        @inlinable
        public func writeToRESPBuffer(_ buffer: inout ByteBuffer) {
            switch self {
            case .yes: "YES".writeToRESPBuffer(&buffer)
            case .no: "NO".writeToRESPBuffer(&buffer)
            }
        }
    }
    /// Instructs the server whether to track the keys in the next request.
    ///
    /// Version: 6.0.0
    /// Complexity: O(1)
    /// Categories: @slow, @connection
    @inlinable
    public func clientCaching(mode: CLIENTCACHINGMode) async throws -> RESP3Token {
        let response = try await send(clientCachingCommand(mode: mode))
        return response
    }

    @inlinable
    public func clientCachingCommand(mode: CLIENTCACHINGMode) -> RESPCommand {
        RESPCommand("CLIENT", "CACHING", mode)
    }

    /// Returns the name of the connection.
    ///
    /// Version: 2.6.9
    /// Complexity: O(1)
    /// Categories: @slow, @connection
    @inlinable
    public func clientGetname() async throws -> RESP3Token {
        let response = try await send(clientGetnameCommand())
        return response
    }

    @inlinable
    public func clientGetnameCommand() -> RESPCommand {
        RESPCommand("CLIENT", "GETNAME")
    }

    /// Returns the client ID to which the connection's tracking notifications are redirected.
    ///
    /// Version: 6.0.0
    /// Complexity: O(1)
    /// Categories: @slow, @connection
    @inlinable
    public func clientGetredir() async throws -> RESP3Token {
        let response = try await send(clientGetredirCommand())
        return response
    }

    @inlinable
    public func clientGetredirCommand() -> RESPCommand {
        RESPCommand("CLIENT", "GETREDIR")
    }

    /// Returns helpful text about the different subcommands.
    ///
    /// Version: 5.0.0
    /// Complexity: O(1)
    /// Categories: @slow, @connection
    @inlinable
    public func clientHelp() async throws -> RESP3Token {
        let response = try await send(clientHelpCommand())
        return response
    }

    @inlinable
    public func clientHelpCommand() -> RESPCommand {
        RESPCommand("CLIENT", "HELP")
    }

    /// Returns the unique client ID of the connection.
    ///
    /// Version: 5.0.0
    /// Complexity: O(1)
    /// Categories: @slow, @connection
    @inlinable
    public func clientId() async throws -> RESP3Token {
        let response = try await send(clientIdCommand())
        return response
    }

    @inlinable
    public func clientIdCommand() -> RESPCommand {
        RESPCommand("CLIENT", "ID")
    }

    /// Returns information about the connection.
    ///
    /// Version: 6.2.0
    /// Complexity: O(1)
    /// Categories: @slow, @connection
    @inlinable
    public func clientInfo() async throws -> RESP3Token {
        let response = try await send(clientInfoCommand())
        return response
    }

    @inlinable
    public func clientInfoCommand() -> RESPCommand {
        RESPCommand("CLIENT", "INFO")
    }

    public enum CLIENTKILLFilterNewFormatClientType: RESPRepresentable {
        case normal
        case master
        case slave
        case replica
        case pubsub

        @inlinable
        public func writeToRESPBuffer(_ buffer: inout ByteBuffer) {
            switch self {
            case .normal: "NORMAL".writeToRESPBuffer(&buffer)
            case .master: "MASTER".writeToRESPBuffer(&buffer)
            case .slave: "SLAVE".writeToRESPBuffer(&buffer)
            case .replica: "REPLICA".writeToRESPBuffer(&buffer)
            case .pubsub: "PUBSUB".writeToRESPBuffer(&buffer)
            }
        }
    }
    public enum CLIENTKILLFilterNewFormatSkipme: RESPRepresentable {
        case yes
        case no

        @inlinable
        public func writeToRESPBuffer(_ buffer: inout ByteBuffer) {
            switch self {
            case .yes: "YES".writeToRESPBuffer(&buffer)
            case .no: "NO".writeToRESPBuffer(&buffer)
            }
        }
    }
    public enum CLIENTKILLFilterNewFormat: RESPRepresentable {
        case clientId(Int?)
        case clientType(CLIENTKILLFilterNewFormatClientType?)
        case username(String?)
        case addr(String?)
        case laddr(String?)
        case skipme(CLIENTKILLFilterNewFormatSkipme?)

        @inlinable
        public func writeToRESPBuffer(_ buffer: inout ByteBuffer) {
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
    public enum CLIENTKILLFilter: RESPRepresentable {
        case oldFormat(String)
        case newFormat([CLIENTKILLFilterNewFormat])

        @inlinable
        public func writeToRESPBuffer(_ buffer: inout ByteBuffer) {
            switch self {
            case .oldFormat(let oldFormat): oldFormat.writeToRESPBuffer(&buffer)
            case .newFormat(let newFormat): newFormat.writeToRESPBuffer(&buffer)
            }
        }
    }
    /// Terminates open connections.
    ///
    /// Version: 2.4.0
    /// Complexity: O(N) where N is the number of client connections
    /// Categories: @admin, @slow, @dangerous, @connection
    @inlinable
    public func clientKill(filter: CLIENTKILLFilter) async throws -> RESP3Token {
        let response = try await send(clientKillCommand(filter: filter))
        return response
    }

    @inlinable
    public func clientKillCommand(filter: CLIENTKILLFilter) -> RESPCommand {
        RESPCommand("CLIENT", "KILL", filter)
    }

    public enum CLIENTLISTClientType: RESPRepresentable {
        case normal
        case master
        case replica
        case pubsub

        @inlinable
        public func writeToRESPBuffer(_ buffer: inout ByteBuffer) {
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
    /// Version: 2.4.0
    /// Complexity: O(N) where N is the number of client connections
    /// Categories: @admin, @slow, @dangerous, @connection
    @inlinable
    public func clientList(clientType: CLIENTLISTClientType?, clientId: Int...) async throws -> RESP3Token {
        let response = try await send(clientListCommand(clientType: clientType, clientId: clientId))
        return response
    }

    @inlinable
    public func clientListCommand(clientType: CLIENTLISTClientType?, clientId: [Int]) -> RESPCommand {
        RESPCommand("CLIENT", "LIST", RESPWithToken("TYPE", clientType), RESPWithToken("ID", clientId))
    }

    public enum CLIENTNOEVICTEnabled: RESPRepresentable {
        case on
        case off

        @inlinable
        public func writeToRESPBuffer(_ buffer: inout ByteBuffer) {
            switch self {
            case .on: "ON".writeToRESPBuffer(&buffer)
            case .off: "OFF".writeToRESPBuffer(&buffer)
            }
        }
    }
    /// Sets the client eviction mode of the connection.
    ///
    /// Version: 7.0.0
    /// Complexity: O(1)
    /// Categories: @admin, @slow, @dangerous, @connection
    @inlinable
    public func clientNoEvict(enabled: CLIENTNOEVICTEnabled) async throws -> RESP3Token {
        let response = try await send(clientNoEvictCommand(enabled: enabled))
        return response
    }

    @inlinable
    public func clientNoEvictCommand(enabled: CLIENTNOEVICTEnabled) -> RESPCommand {
        RESPCommand("CLIENT", "NO-EVICT", enabled)
    }

    public enum CLIENTNOTOUCHEnabled: RESPRepresentable {
        case on
        case off

        @inlinable
        public func writeToRESPBuffer(_ buffer: inout ByteBuffer) {
            switch self {
            case .on: "ON".writeToRESPBuffer(&buffer)
            case .off: "OFF".writeToRESPBuffer(&buffer)
            }
        }
    }
    /// Controls whether commands sent by the client affect the LRU/LFU of accessed keys.
    ///
    /// Version: 7.2.0
    /// Complexity: O(1)
    /// Categories: @slow, @connection
    @inlinable
    public func clientNoTouch(enabled: CLIENTNOTOUCHEnabled) async throws -> RESP3Token {
        let response = try await send(clientNoTouchCommand(enabled: enabled))
        return response
    }

    @inlinable
    public func clientNoTouchCommand(enabled: CLIENTNOTOUCHEnabled) -> RESPCommand {
        RESPCommand("CLIENT", "NO-TOUCH", enabled)
    }

    public enum CLIENTPAUSEMode: RESPRepresentable {
        case write
        case all

        @inlinable
        public func writeToRESPBuffer(_ buffer: inout ByteBuffer) {
            switch self {
            case .write: "WRITE".writeToRESPBuffer(&buffer)
            case .all: "ALL".writeToRESPBuffer(&buffer)
            }
        }
    }
    /// Suspends commands processing.
    ///
    /// Version: 3.0.0
    /// Complexity: O(1)
    /// Categories: @admin, @slow, @dangerous, @connection
    @inlinable
    public func clientPause(timeout: Int, mode: CLIENTPAUSEMode?) async throws -> RESP3Token {
        let response = try await send(clientPauseCommand(timeout: timeout, mode: mode))
        return response
    }

    @inlinable
    public func clientPauseCommand(timeout: Int, mode: CLIENTPAUSEMode?) -> RESPCommand {
        RESPCommand("CLIENT", "PAUSE", timeout, mode)
    }

    public enum CLIENTREPLYAction: RESPRepresentable {
        case on
        case off
        case skip

        @inlinable
        public func writeToRESPBuffer(_ buffer: inout ByteBuffer) {
            switch self {
            case .on: "ON".writeToRESPBuffer(&buffer)
            case .off: "OFF".writeToRESPBuffer(&buffer)
            case .skip: "SKIP".writeToRESPBuffer(&buffer)
            }
        }
    }
    /// Instructs the server whether to reply to commands.
    ///
    /// Version: 3.2.0
    /// Complexity: O(1)
    /// Categories: @slow, @connection
    @inlinable
    public func clientReply(action: CLIENTREPLYAction) async throws -> RESP3Token {
        let response = try await send(clientReplyCommand(action: action))
        return response
    }

    @inlinable
    public func clientReplyCommand(action: CLIENTREPLYAction) -> RESPCommand {
        RESPCommand("CLIENT", "REPLY", action)
    }

    public enum CLIENTSETINFOAttr: RESPRepresentable {
        case libname(String)
        case libver(String)

        @inlinable
        public func writeToRESPBuffer(_ buffer: inout ByteBuffer) {
            switch self {
            case .libname(let libname): RESPWithToken("LIB-NAME", libname).writeToRESPBuffer(&buffer)
            case .libver(let libver): RESPWithToken("LIB-VER", libver).writeToRESPBuffer(&buffer)
            }
        }
    }
    /// Sets information specific to the client or connection.
    ///
    /// Version: 7.2.0
    /// Complexity: O(1)
    /// Categories: @slow, @connection
    @inlinable
    public func clientSetinfo(attr: CLIENTSETINFOAttr) async throws -> RESP3Token {
        let response = try await send(clientSetinfoCommand(attr: attr))
        return response
    }

    @inlinable
    public func clientSetinfoCommand(attr: CLIENTSETINFOAttr) -> RESPCommand {
        RESPCommand("CLIENT", "SETINFO", attr)
    }

    /// Sets the connection name.
    ///
    /// Version: 2.6.9
    /// Complexity: O(1)
    /// Categories: @slow, @connection
    @inlinable
    public func clientSetname(connectionName: String) async throws -> RESP3Token {
        let response = try await send(clientSetnameCommand(connectionName: connectionName))
        return response
    }

    @inlinable
    public func clientSetnameCommand(connectionName: String) -> RESPCommand {
        RESPCommand("CLIENT", "SETNAME", connectionName)
    }

    public enum CLIENTTRACKINGStatus: RESPRepresentable {
        case on
        case off

        @inlinable
        public func writeToRESPBuffer(_ buffer: inout ByteBuffer) {
            switch self {
            case .on: "ON".writeToRESPBuffer(&buffer)
            case .off: "OFF".writeToRESPBuffer(&buffer)
            }
        }
    }
    /// Controls server-assisted client-side caching for the connection.
    ///
    /// Version: 6.0.0
    /// Complexity: O(1). Some options may introduce additional complexity.
    /// Categories: @slow, @connection
    @inlinable
    public func clientTracking(status: CLIENTTRACKINGStatus, clientId: Int?, prefix: String..., bcast: Bool, optin: Bool, optout: Bool, noloop: Bool) async throws -> RESP3Token {
        let response = try await send(clientTrackingCommand(status: status, clientId: clientId, prefix: prefix, bcast: bcast, optin: optin, optout: optout, noloop: noloop))
        return response
    }

    @inlinable
    public func clientTrackingCommand(status: CLIENTTRACKINGStatus, clientId: Int?, prefix: [String], bcast: Bool, optin: Bool, optout: Bool, noloop: Bool) -> RESPCommand {
        RESPCommand("CLIENT", "TRACKING", status, RESPWithToken("REDIRECT", clientId), RESPWithToken("PREFIX", prefix), RedisPureToken("BCAST", bcast), RedisPureToken("OPTIN", optin), RedisPureToken("OPTOUT", optout), RedisPureToken("NOLOOP", noloop))
    }

    /// Returns information about server-assisted client-side caching for the connection.
    ///
    /// Version: 6.2.0
    /// Complexity: O(1)
    /// Categories: @slow, @connection
    @inlinable
    public func clientTrackinginfo() async throws -> RESP3Token {
        let response = try await send(clientTrackinginfoCommand())
        return response
    }

    @inlinable
    public func clientTrackinginfoCommand() -> RESPCommand {
        RESPCommand("CLIENT", "TRACKINGINFO")
    }

    public enum CLIENTUNBLOCKUnblockType: RESPRepresentable {
        case timeout
        case error

        @inlinable
        public func writeToRESPBuffer(_ buffer: inout ByteBuffer) {
            switch self {
            case .timeout: "TIMEOUT".writeToRESPBuffer(&buffer)
            case .error: "ERROR".writeToRESPBuffer(&buffer)
            }
        }
    }
    /// Unblocks a client blocked by a blocking command from a different connection.
    ///
    /// Version: 5.0.0
    /// Complexity: O(log N) where N is the number of client connections
    /// Categories: @admin, @slow, @dangerous, @connection
    @inlinable
    public func clientUnblock(clientId: Int, unblockType: CLIENTUNBLOCKUnblockType?) async throws -> RESP3Token {
        let response = try await send(clientUnblockCommand(clientId: clientId, unblockType: unblockType))
        return response
    }

    @inlinable
    public func clientUnblockCommand(clientId: Int, unblockType: CLIENTUNBLOCKUnblockType?) -> RESPCommand {
        RESPCommand("CLIENT", "UNBLOCK", clientId, unblockType)
    }

    /// Resumes processing commands from paused clients.
    ///
    /// Version: 6.2.0
    /// Complexity: O(N) Where N is the number of paused clients
    /// Categories: @admin, @slow, @dangerous, @connection
    @inlinable
    public func clientUnpause() async throws -> RESP3Token {
        let response = try await send(clientUnpauseCommand())
        return response
    }

    @inlinable
    public func clientUnpauseCommand() -> RESPCommand {
        RESPCommand("CLIENT", "UNPAUSE")
    }

    /// A container for Redis Cluster commands.
    ///
    /// Version: 3.0.0
    /// Complexity: Depends on subcommand.
    /// Categories: @slow
    @inlinable
    public func cluster() async throws -> RESP3Token {
        let response = try await send(clusterCommand())
        return response
    }

    @inlinable
    public func clusterCommand() -> RESPCommand {
        RESPCommand("CLUSTER")
    }

    /// Assigns new hash slots to a node.
    ///
    /// Version: 3.0.0
    /// Complexity: O(N) where N is the total number of hash slot arguments
    /// Categories: @admin, @slow, @dangerous
    @inlinable
    public func clusterAddslots(slot: Int...) async throws -> RESP3Token {
        let response = try await send(clusterAddslotsCommand(slot: slot))
        return response
    }

    @inlinable
    public func clusterAddslotsCommand(slot: [Int]) -> RESPCommand {
        RESPCommand("CLUSTER", "ADDSLOTS", slot)
    }

    public struct CLUSTERADDSLOTSRANGERange: RESPRepresentable {
        @usableFromInline let startSlot: Int
        @usableFromInline let endSlot: Int

        @inlinable
        public func writeToRESPBuffer(_ buffer: inout ByteBuffer) {
            self.startSlot.writeToRESPBuffer(&buffer)
            self.endSlot.writeToRESPBuffer(&buffer)
        }
    }
    /// Assigns new hash slot ranges to a node.
    ///
    /// Version: 7.0.0
    /// Complexity: O(N) where N is the total number of the slots between the start slot and end slot arguments.
    /// Categories: @admin, @slow, @dangerous
    @inlinable
    public func clusterAddslotsrange(range: CLUSTERADDSLOTSRANGERange...) async throws -> RESP3Token {
        let response = try await send(clusterAddslotsrangeCommand(range: range))
        return response
    }

    @inlinable
    public func clusterAddslotsrangeCommand(range: [CLUSTERADDSLOTSRANGERange]) -> RESPCommand {
        RESPCommand("CLUSTER", "ADDSLOTSRANGE", range)
    }

    /// Advances the cluster config epoch.
    ///
    /// Version: 3.0.0
    /// Complexity: O(1)
    /// Categories: @admin, @slow, @dangerous
    @inlinable
    public func clusterBumpepoch() async throws -> RESP3Token {
        let response = try await send(clusterBumpepochCommand())
        return response
    }

    @inlinable
    public func clusterBumpepochCommand() -> RESPCommand {
        RESPCommand("CLUSTER", "BUMPEPOCH")
    }

    /// Returns the number of active failure reports active for a node.
    ///
    /// Version: 3.0.0
    /// Complexity: O(N) where N is the number of failure reports
    /// Categories: @admin, @slow, @dangerous
    @inlinable
    public func clusterCountFailureReports(nodeId: String) async throws -> RESP3Token {
        let response = try await send(clusterCountFailureReportsCommand(nodeId: nodeId))
        return response
    }

    @inlinable
    public func clusterCountFailureReportsCommand(nodeId: String) -> RESPCommand {
        RESPCommand("CLUSTER", "COUNT-FAILURE-REPORTS", nodeId)
    }

    /// Returns the number of keys in a hash slot.
    ///
    /// Version: 3.0.0
    /// Complexity: O(1)
    /// Categories: @slow
    @inlinable
    public func clusterCountkeysinslot(slot: Int) async throws -> RESP3Token {
        let response = try await send(clusterCountkeysinslotCommand(slot: slot))
        return response
    }

    @inlinable
    public func clusterCountkeysinslotCommand(slot: Int) -> RESPCommand {
        RESPCommand("CLUSTER", "COUNTKEYSINSLOT", slot)
    }

    /// Sets hash slots as unbound for a node.
    ///
    /// Version: 3.0.0
    /// Complexity: O(N) where N is the total number of hash slot arguments
    /// Categories: @admin, @slow, @dangerous
    @inlinable
    public func clusterDelslots(slot: Int...) async throws -> RESP3Token {
        let response = try await send(clusterDelslotsCommand(slot: slot))
        return response
    }

    @inlinable
    public func clusterDelslotsCommand(slot: [Int]) -> RESPCommand {
        RESPCommand("CLUSTER", "DELSLOTS", slot)
    }

    public struct CLUSTERDELSLOTSRANGERange: RESPRepresentable {
        @usableFromInline let startSlot: Int
        @usableFromInline let endSlot: Int

        @inlinable
        public func writeToRESPBuffer(_ buffer: inout ByteBuffer) {
            self.startSlot.writeToRESPBuffer(&buffer)
            self.endSlot.writeToRESPBuffer(&buffer)
        }
    }
    /// Sets hash slot ranges as unbound for a node.
    ///
    /// Version: 7.0.0
    /// Complexity: O(N) where N is the total number of the slots between the start slot and end slot arguments.
    /// Categories: @admin, @slow, @dangerous
    @inlinable
    public func clusterDelslotsrange(range: CLUSTERDELSLOTSRANGERange...) async throws -> RESP3Token {
        let response = try await send(clusterDelslotsrangeCommand(range: range))
        return response
    }

    @inlinable
    public func clusterDelslotsrangeCommand(range: [CLUSTERDELSLOTSRANGERange]) -> RESPCommand {
        RESPCommand("CLUSTER", "DELSLOTSRANGE", range)
    }

    public enum CLUSTERFAILOVEROptions: RESPRepresentable {
        case force
        case takeover

        @inlinable
        public func writeToRESPBuffer(_ buffer: inout ByteBuffer) {
            switch self {
            case .force: "FORCE".writeToRESPBuffer(&buffer)
            case .takeover: "TAKEOVER".writeToRESPBuffer(&buffer)
            }
        }
    }
    /// Forces a replica to perform a manual failover of its master.
    ///
    /// Version: 3.0.0
    /// Complexity: O(1)
    /// Categories: @admin, @slow, @dangerous
    @inlinable
    public func clusterFailover(options: CLUSTERFAILOVEROptions?) async throws -> RESP3Token {
        let response = try await send(clusterFailoverCommand(options: options))
        return response
    }

    @inlinable
    public func clusterFailoverCommand(options: CLUSTERFAILOVEROptions?) -> RESPCommand {
        RESPCommand("CLUSTER", "FAILOVER", options)
    }

    /// Deletes all slots information from a node.
    ///
    /// Version: 3.0.0
    /// Complexity: O(1)
    /// Categories: @admin, @slow, @dangerous
    @inlinable
    public func clusterFlushslots() async throws -> RESP3Token {
        let response = try await send(clusterFlushslotsCommand())
        return response
    }

    @inlinable
    public func clusterFlushslotsCommand() -> RESPCommand {
        RESPCommand("CLUSTER", "FLUSHSLOTS")
    }

    /// Removes a node from the nodes table.
    ///
    /// Version: 3.0.0
    /// Complexity: O(1)
    /// Categories: @admin, @slow, @dangerous
    @inlinable
    public func clusterForget(nodeId: String) async throws -> RESP3Token {
        let response = try await send(clusterForgetCommand(nodeId: nodeId))
        return response
    }

    @inlinable
    public func clusterForgetCommand(nodeId: String) -> RESPCommand {
        RESPCommand("CLUSTER", "FORGET", nodeId)
    }

    /// Returns the key names in a hash slot.
    ///
    /// Version: 3.0.0
    /// Complexity: O(N) where N is the number of requested keys
    /// Categories: @slow
    @inlinable
    public func clusterGetkeysinslot(slot: Int, count: Int) async throws -> RESP3Token {
        let response = try await send(clusterGetkeysinslotCommand(slot: slot, count: count))
        return response
    }

    @inlinable
    public func clusterGetkeysinslotCommand(slot: Int, count: Int) -> RESPCommand {
        RESPCommand("CLUSTER", "GETKEYSINSLOT", slot, count)
    }

    /// Returns helpful text about the different subcommands.
    ///
    /// Version: 5.0.0
    /// Complexity: O(1)
    /// Categories: @slow
    @inlinable
    public func clusterHelp() async throws -> RESP3Token {
        let response = try await send(clusterHelpCommand())
        return response
    }

    @inlinable
    public func clusterHelpCommand() -> RESPCommand {
        RESPCommand("CLUSTER", "HELP")
    }

    /// Returns information about the state of a node.
    ///
    /// Version: 3.0.0
    /// Complexity: O(1)
    /// Categories: @slow
    @inlinable
    public func clusterInfo() async throws -> RESP3Token {
        let response = try await send(clusterInfoCommand())
        return response
    }

    @inlinable
    public func clusterInfoCommand() -> RESPCommand {
        RESPCommand("CLUSTER", "INFO")
    }

    /// Returns the hash slot for a key.
    ///
    /// Version: 3.0.0
    /// Complexity: O(N) where N is the number of bytes in the key
    /// Categories: @slow
    @inlinable
    public func clusterKeyslot(key: String) async throws -> RESP3Token {
        let response = try await send(clusterKeyslotCommand(key: key))
        return response
    }

    @inlinable
    public func clusterKeyslotCommand(key: String) -> RESPCommand {
        RESPCommand("CLUSTER", "KEYSLOT", key)
    }

    /// Returns a list of all TCP links to and from peer nodes.
    ///
    /// Version: 7.0.0
    /// Complexity: O(N) where N is the total number of Cluster nodes
    /// Categories: @slow
    @inlinable
    public func clusterLinks() async throws -> RESP3Token {
        let response = try await send(clusterLinksCommand())
        return response
    }

    @inlinable
    public func clusterLinksCommand() -> RESPCommand {
        RESPCommand("CLUSTER", "LINKS")
    }

    /// Forces a node to handshake with another node.
    ///
    /// Version: 3.0.0
    /// Complexity: O(1)
    /// Categories: @admin, @slow, @dangerous
    @inlinable
    public func clusterMeet(ip: String, port: Int, clusterBusPort: Int?) async throws -> RESP3Token {
        let response = try await send(clusterMeetCommand(ip: ip, port: port, clusterBusPort: clusterBusPort))
        return response
    }

    @inlinable
    public func clusterMeetCommand(ip: String, port: Int, clusterBusPort: Int?) -> RESPCommand {
        RESPCommand("CLUSTER", "MEET", ip, port, clusterBusPort)
    }

    /// Returns the ID of a node.
    ///
    /// Version: 3.0.0
    /// Complexity: O(1)
    /// Categories: @slow
    @inlinable
    public func clusterMyid() async throws -> RESP3Token {
        let response = try await send(clusterMyidCommand())
        return response
    }

    @inlinable
    public func clusterMyidCommand() -> RESPCommand {
        RESPCommand("CLUSTER", "MYID")
    }

    /// Returns the shard ID of a node.
    ///
    /// Version: 7.2.0
    /// Complexity: O(1)
    /// Categories: @slow
    @inlinable
    public func clusterMyshardid() async throws -> RESP3Token {
        let response = try await send(clusterMyshardidCommand())
        return response
    }

    @inlinable
    public func clusterMyshardidCommand() -> RESPCommand {
        RESPCommand("CLUSTER", "MYSHARDID")
    }

    /// Returns the cluster configuration for a node.
    ///
    /// Version: 3.0.0
    /// Complexity: O(N) where N is the total number of Cluster nodes
    /// Categories: @slow
    @inlinable
    public func clusterNodes() async throws -> RESP3Token {
        let response = try await send(clusterNodesCommand())
        return response
    }

    @inlinable
    public func clusterNodesCommand() -> RESPCommand {
        RESPCommand("CLUSTER", "NODES")
    }

    /// Lists the replica nodes of a master node.
    ///
    /// Version: 5.0.0
    /// Complexity: O(N) where N is the number of replicas.
    /// Categories: @admin, @slow, @dangerous
    @inlinable
    public func clusterReplicas(nodeId: String) async throws -> RESP3Token {
        let response = try await send(clusterReplicasCommand(nodeId: nodeId))
        return response
    }

    @inlinable
    public func clusterReplicasCommand(nodeId: String) -> RESPCommand {
        RESPCommand("CLUSTER", "REPLICAS", nodeId)
    }

    /// Configure a node as replica of a master node.
    ///
    /// Version: 3.0.0
    /// Complexity: O(1)
    /// Categories: @admin, @slow, @dangerous
    @inlinable
    public func clusterReplicate(nodeId: String) async throws -> RESP3Token {
        let response = try await send(clusterReplicateCommand(nodeId: nodeId))
        return response
    }

    @inlinable
    public func clusterReplicateCommand(nodeId: String) -> RESPCommand {
        RESPCommand("CLUSTER", "REPLICATE", nodeId)
    }

    public enum CLUSTERRESETResetType: RESPRepresentable {
        case hard
        case soft

        @inlinable
        public func writeToRESPBuffer(_ buffer: inout ByteBuffer) {
            switch self {
            case .hard: "HARD".writeToRESPBuffer(&buffer)
            case .soft: "SOFT".writeToRESPBuffer(&buffer)
            }
        }
    }
    /// Resets a node.
    ///
    /// Version: 3.0.0
    /// Complexity: O(N) where N is the number of known nodes. The command may execute a FLUSHALL as a side effect.
    /// Categories: @admin, @slow, @dangerous
    @inlinable
    public func clusterReset(resetType: CLUSTERRESETResetType?) async throws -> RESP3Token {
        let response = try await send(clusterResetCommand(resetType: resetType))
        return response
    }

    @inlinable
    public func clusterResetCommand(resetType: CLUSTERRESETResetType?) -> RESPCommand {
        RESPCommand("CLUSTER", "RESET", resetType)
    }

    /// Forces a node to save the cluster configuration to disk.
    ///
    /// Version: 3.0.0
    /// Complexity: O(1)
    /// Categories: @admin, @slow, @dangerous
    @inlinable
    public func clusterSaveconfig() async throws -> RESP3Token {
        let response = try await send(clusterSaveconfigCommand())
        return response
    }

    @inlinable
    public func clusterSaveconfigCommand() -> RESPCommand {
        RESPCommand("CLUSTER", "SAVECONFIG")
    }

    /// Sets the configuration epoch for a new node.
    ///
    /// Version: 3.0.0
    /// Complexity: O(1)
    /// Categories: @admin, @slow, @dangerous
    @inlinable
    public func clusterSetConfigEpoch(configEpoch: Int) async throws -> RESP3Token {
        let response = try await send(clusterSetConfigEpochCommand(configEpoch: configEpoch))
        return response
    }

    @inlinable
    public func clusterSetConfigEpochCommand(configEpoch: Int) -> RESPCommand {
        RESPCommand("CLUSTER", "SET-CONFIG-EPOCH", configEpoch)
    }

    public enum CLUSTERSETSLOTSubcommand: RESPRepresentable {
        case importing(String)
        case migrating(String)
        case node(String)
        case stable

        @inlinable
        public func writeToRESPBuffer(_ buffer: inout ByteBuffer) {
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
    /// Version: 3.0.0
    /// Complexity: O(1)
    /// Categories: @admin, @slow, @dangerous
    @inlinable
    public func clusterSetslot(slot: Int, subcommand: CLUSTERSETSLOTSubcommand) async throws -> RESP3Token {
        let response = try await send(clusterSetslotCommand(slot: slot, subcommand: subcommand))
        return response
    }

    @inlinable
    public func clusterSetslotCommand(slot: Int, subcommand: CLUSTERSETSLOTSubcommand) -> RESPCommand {
        RESPCommand("CLUSTER", "SETSLOT", slot, subcommand)
    }

    /// Returns the mapping of cluster slots to shards.
    ///
    /// Version: 7.0.0
    /// Complexity: O(N) where N is the total number of cluster nodes
    /// Categories: @slow
    @inlinable
    public func clusterShards() async throws -> RESP3Token {
        let response = try await send(clusterShardsCommand())
        return response
    }

    @inlinable
    public func clusterShardsCommand() -> RESPCommand {
        RESPCommand("CLUSTER", "SHARDS")
    }

    /// Lists the replica nodes of a master node.
    ///
    /// Version: 3.0.0
    /// Complexity: O(N) where N is the number of replicas.
    /// Categories: @admin, @slow, @dangerous
    @inlinable
    public func clusterSlaves(nodeId: String) async throws -> RESP3Token {
        let response = try await send(clusterSlavesCommand(nodeId: nodeId))
        return response
    }

    @inlinable
    public func clusterSlavesCommand(nodeId: String) -> RESPCommand {
        RESPCommand("CLUSTER", "SLAVES", nodeId)
    }

    /// Returns the mapping of cluster slots to nodes.
    ///
    /// Version: 3.0.0
    /// Complexity: O(N) where N is the total number of Cluster nodes
    /// Categories: @slow
    @inlinable
    public func clusterSlots() async throws -> RESP3Token {
        let response = try await send(clusterSlotsCommand())
        return response
    }

    @inlinable
    public func clusterSlotsCommand() -> RESPCommand {
        RESPCommand("CLUSTER", "SLOTS")
    }

    /// Returns detailed information about all commands.
    ///
    /// Version: 2.8.13
    /// Complexity: O(N) where N is the total number of Redis commands
    /// Categories: @slow, @connection
    @inlinable
    public func command() async throws -> RESP3Token {
        let response = try await send(commandCommand())
        return response
    }

    @inlinable
    public func commandCommand() -> RESPCommand {
        RESPCommand("COMMAND")
    }

    /// Returns a count of commands.
    ///
    /// Version: 2.8.13
    /// Complexity: O(1)
    /// Categories: @slow, @connection
    @inlinable
    public func commandCount() async throws -> RESP3Token {
        let response = try await send(commandCountCommand())
        return response
    }

    @inlinable
    public func commandCountCommand() -> RESPCommand {
        RESPCommand("COMMAND", "COUNT")
    }

    /// Returns documentary information about one, multiple or all commands.
    ///
    /// Version: 7.0.0
    /// Complexity: O(N) where N is the number of commands to look up
    /// Categories: @slow, @connection
    @inlinable
    public func commandDocs(commandName: String...) async throws -> RESP3Token {
        let response = try await send(commandDocsCommand(commandName: commandName))
        return response
    }

    @inlinable
    public func commandDocsCommand(commandName: [String]) -> RESPCommand {
        RESPCommand("COMMAND", "DOCS", commandName)
    }

    /// Extracts the key names from an arbitrary command.
    ///
    /// Version: 2.8.13
    /// Complexity: O(N) where N is the number of arguments to the command
    /// Categories: @slow, @connection
    @inlinable
    public func commandGetkeys(command: String, arg: String...) async throws -> RESP3Token {
        let response = try await send(commandGetkeysCommand(command: command, arg: arg))
        return response
    }

    @inlinable
    public func commandGetkeysCommand(command: String, arg: [String]) -> RESPCommand {
        RESPCommand("COMMAND", "GETKEYS", command, arg)
    }

    /// Extracts the key names and access flags for an arbitrary command.
    ///
    /// Version: 7.0.0
    /// Complexity: O(N) where N is the number of arguments to the command
    /// Categories: @slow, @connection
    @inlinable
    public func commandGetkeysandflags(command: String, arg: String...) async throws -> RESP3Token {
        let response = try await send(commandGetkeysandflagsCommand(command: command, arg: arg))
        return response
    }

    @inlinable
    public func commandGetkeysandflagsCommand(command: String, arg: [String]) -> RESPCommand {
        RESPCommand("COMMAND", "GETKEYSANDFLAGS", command, arg)
    }

    /// Returns helpful text about the different subcommands.
    ///
    /// Version: 5.0.0
    /// Complexity: O(1)
    /// Categories: @slow, @connection
    @inlinable
    public func commandHelp() async throws -> RESP3Token {
        let response = try await send(commandHelpCommand())
        return response
    }

    @inlinable
    public func commandHelpCommand() -> RESPCommand {
        RESPCommand("COMMAND", "HELP")
    }

    /// Returns information about one, multiple or all commands.
    ///
    /// Version: 2.8.13
    /// Complexity: O(N) where N is the number of commands to look up
    /// Categories: @slow, @connection
    @inlinable
    public func commandInfo(commandName: String...) async throws -> RESP3Token {
        let response = try await send(commandInfoCommand(commandName: commandName))
        return response
    }

    @inlinable
    public func commandInfoCommand(commandName: [String]) -> RESPCommand {
        RESPCommand("COMMAND", "INFO", commandName)
    }

    public enum COMMANDLISTFilterby: RESPRepresentable {
        case moduleName(String)
        case category(String)
        case pattern(String)

        @inlinable
        public func writeToRESPBuffer(_ buffer: inout ByteBuffer) {
            switch self {
            case .moduleName(let moduleName): RESPWithToken("MODULE", moduleName).writeToRESPBuffer(&buffer)
            case .category(let category): RESPWithToken("ACLCAT", category).writeToRESPBuffer(&buffer)
            case .pattern(let pattern): RESPWithToken("PATTERN", pattern).writeToRESPBuffer(&buffer)
            }
        }
    }
    /// Returns a list of command names.
    ///
    /// Version: 7.0.0
    /// Complexity: O(N) where N is the total number of Redis commands
    /// Categories: @slow, @connection
    @inlinable
    public func commandList(filterby: COMMANDLISTFilterby?) async throws -> RESP3Token {
        let response = try await send(commandListCommand(filterby: filterby))
        return response
    }

    @inlinable
    public func commandListCommand(filterby: COMMANDLISTFilterby?) -> RESPCommand {
        RESPCommand("COMMAND", "LIST", RESPWithToken("FILTERBY", filterby))
    }

    /// A container for server configuration commands.
    ///
    /// Version: 2.0.0
    /// Complexity: Depends on subcommand.
    /// Categories: @slow
    @inlinable
    public func config() async throws -> RESP3Token {
        let response = try await send(configCommand())
        return response
    }

    @inlinable
    public func configCommand() -> RESPCommand {
        RESPCommand("CONFIG")
    }

    /// Returns the effective values of configuration parameters.
    ///
    /// Version: 2.0.0
    /// Complexity: O(N) when N is the number of configuration parameters provided
    /// Categories: @admin, @slow, @dangerous
    @inlinable
    public func configGet(parameter: String...) async throws -> RESP3Token {
        let response = try await send(configGetCommand(parameter: parameter))
        return response
    }

    @inlinable
    public func configGetCommand(parameter: [String]) -> RESPCommand {
        RESPCommand("CONFIG", "GET", parameter)
    }

    /// Returns helpful text about the different subcommands.
    ///
    /// Version: 5.0.0
    /// Complexity: O(1)
    /// Categories: @slow
    @inlinable
    public func configHelp() async throws -> RESP3Token {
        let response = try await send(configHelpCommand())
        return response
    }

    @inlinable
    public func configHelpCommand() -> RESPCommand {
        RESPCommand("CONFIG", "HELP")
    }

    /// Resets the server's statistics.
    ///
    /// Version: 2.0.0
    /// Complexity: O(1)
    /// Categories: @admin, @slow, @dangerous
    @inlinable
    public func configResetstat() async throws -> RESP3Token {
        let response = try await send(configResetstatCommand())
        return response
    }

    @inlinable
    public func configResetstatCommand() -> RESPCommand {
        RESPCommand("CONFIG", "RESETSTAT")
    }

    /// Persists the effective configuration to file.
    ///
    /// Version: 2.8.0
    /// Complexity: O(1)
    /// Categories: @admin, @slow, @dangerous
    @inlinable
    public func configRewrite() async throws -> RESP3Token {
        let response = try await send(configRewriteCommand())
        return response
    }

    @inlinable
    public func configRewriteCommand() -> RESPCommand {
        RESPCommand("CONFIG", "REWRITE")
    }

    public struct CONFIGSETData: RESPRepresentable {
        @usableFromInline let parameter: String
        @usableFromInline let value: String

        @inlinable
        public func writeToRESPBuffer(_ buffer: inout ByteBuffer) {
            self.parameter.writeToRESPBuffer(&buffer)
            self.value.writeToRESPBuffer(&buffer)
        }
    }
    /// Sets configuration parameters in-flight.
    ///
    /// Version: 2.0.0
    /// Complexity: O(N) when N is the number of configuration parameters provided
    /// Categories: @admin, @slow, @dangerous
    @inlinable
    public func configSet(data: CONFIGSETData...) async throws -> RESP3Token {
        let response = try await send(configSetCommand(data: data))
        return response
    }

    @inlinable
    public func configSetCommand(data: [CONFIGSETData]) -> RESPCommand {
        RESPCommand("CONFIG", "SET", data)
    }

    /// Copies the value of a key to a new key.
    ///
    /// Version: 6.2.0
    /// Complexity: O(N) worst case for collections, where N is the number of nested items. O(1) for string values.
    /// Categories: @keyspace, @write, @slow
    @inlinable
    public func copy(source: RedisKey, destination: RedisKey, destinationDb: Int?, replace: Bool) async throws -> RESP3Token {
        let response = try await send(copyCommand(source: source, destination: destination, destinationDb: destinationDb, replace: replace))
        return response
    }

    @inlinable
    public func copyCommand(source: RedisKey, destination: RedisKey, destinationDb: Int?, replace: Bool) -> RESPCommand {
        RESPCommand("COPY", source, destination, RESPWithToken("DB", destinationDb), RedisPureToken("REPLACE", replace))
    }

    /// Returns the number of keys in the database.
    ///
    /// Version: 1.0.0
    /// Complexity: O(1)
    /// Categories: @keyspace, @read, @fast
    @inlinable
    public func dbsize() async throws -> RESP3Token {
        let response = try await send(dbsizeCommand())
        return response
    }

    @inlinable
    public func dbsizeCommand() -> RESPCommand {
        RESPCommand("DBSIZE")
    }

    /// A container for debugging commands.
    ///
    /// Version: 1.0.0
    /// Complexity: Depends on subcommand.
    /// Categories: @admin, @slow, @dangerous
    @inlinable
    public func debug() async throws -> RESP3Token {
        let response = try await send(debugCommand())
        return response
    }

    @inlinable
    public func debugCommand() -> RESPCommand {
        RESPCommand("DEBUG")
    }

    /// Decrements the integer value of a key by one. Uses 0 as initial value if the key doesn't exist.
    ///
    /// Version: 1.0.0
    /// Complexity: O(1)
    /// Categories: @write, @string, @fast
    @inlinable
    public func decr(key: RedisKey) async throws -> RESP3Token {
        let response = try await send(decrCommand(key: key))
        return response
    }

    @inlinable
    public func decrCommand(key: RedisKey) -> RESPCommand {
        RESPCommand("DECR", key)
    }

    /// Decrements a number from the integer value of a key. Uses 0 as initial value if the key doesn't exist.
    ///
    /// Version: 1.0.0
    /// Complexity: O(1)
    /// Categories: @write, @string, @fast
    @inlinable
    public func decrby(key: RedisKey, decrement: Int) async throws -> RESP3Token {
        let response = try await send(decrbyCommand(key: key, decrement: decrement))
        return response
    }

    @inlinable
    public func decrbyCommand(key: RedisKey, decrement: Int) -> RESPCommand {
        RESPCommand("DECRBY", key, decrement)
    }

    /// Deletes one or more keys.
    ///
    /// Version: 1.0.0
    /// Complexity: O(N) where N is the number of keys that will be removed. When a key to remove holds a value other than a string, the individual complexity for this key is O(M) where M is the number of elements in the list, set, sorted set or hash. Removing a single key that holds a string value is O(1).
    /// Categories: @keyspace, @write, @slow
    @inlinable
    public func del(key: RedisKey...) async throws -> RESP3Token {
        let response = try await send(delCommand(key: key))
        return response
    }

    @inlinable
    public func delCommand(key: [RedisKey]) -> RESPCommand {
        RESPCommand("DEL", key)
    }

    /// Discards a transaction.
    ///
    /// Version: 2.0.0
    /// Complexity: O(N), when N is the number of queued commands
    /// Categories: @fast, @transaction
    @inlinable
    public func discard() async throws -> RESP3Token {
        let response = try await send(discardCommand())
        return response
    }

    @inlinable
    public func discardCommand() -> RESPCommand {
        RESPCommand("DISCARD")
    }

    /// Returns a serialized representation of the value stored at a key.
    ///
    /// Version: 2.6.0
    /// Complexity: O(1) to access the key and additional O(N*M) to serialize it, where N is the number of Redis objects composing the value and M their average size. For small string values the time complexity is thus O(1)+O(1*M) where M is small, so simply O(1).
    /// Categories: @keyspace, @read, @slow
    @inlinable
    public func dump(key: RedisKey) async throws -> RESP3Token {
        let response = try await send(dumpCommand(key: key))
        return response
    }

    @inlinable
    public func dumpCommand(key: RedisKey) -> RESPCommand {
        RESPCommand("DUMP", key)
    }

    /// Returns the given string.
    ///
    /// Version: 1.0.0
    /// Complexity: O(1)
    /// Categories: @fast, @connection
    @inlinable
    public func echo(message: String) async throws -> RESP3Token {
        let response = try await send(echoCommand(message: message))
        return response
    }

    @inlinable
    public func echoCommand(message: String) -> RESPCommand {
        RESPCommand("ECHO", message)
    }

    /// Executes a server-side Lua script.
    ///
    /// Version: 2.6.0
    /// Complexity: Depends on the script that is executed.
    /// Categories: @slow, @scripting
    @inlinable
    public func eval(script: String, numkeys: Int, key: RedisKey..., arg: String...) async throws -> RESP3Token {
        let response = try await send(evalCommand(script: script, numkeys: numkeys, key: key, arg: arg))
        return response
    }

    @inlinable
    public func evalCommand(script: String, numkeys: Int, key: [RedisKey], arg: [String]) -> RESPCommand {
        RESPCommand("EVAL", script, numkeys, key, arg)
    }

    /// Executes a server-side Lua script by SHA1 digest.
    ///
    /// Version: 2.6.0
    /// Complexity: Depends on the script that is executed.
    /// Categories: @slow, @scripting
    @inlinable
    public func evalsha(sha1: String, numkeys: Int, key: RedisKey..., arg: String...) async throws -> RESP3Token {
        let response = try await send(evalshaCommand(sha1: sha1, numkeys: numkeys, key: key, arg: arg))
        return response
    }

    @inlinable
    public func evalshaCommand(sha1: String, numkeys: Int, key: [RedisKey], arg: [String]) -> RESPCommand {
        RESPCommand("EVALSHA", sha1, numkeys, key, arg)
    }

    /// Executes a read-only server-side Lua script by SHA1 digest.
    ///
    /// Version: 7.0.0
    /// Complexity: Depends on the script that is executed.
    /// Categories: @slow, @scripting
    @inlinable
    public func evalshaRo(sha1: String, numkeys: Int, key: RedisKey..., arg: String...) async throws -> RESP3Token {
        let response = try await send(evalshaRoCommand(sha1: sha1, numkeys: numkeys, key: key, arg: arg))
        return response
    }

    @inlinable
    public func evalshaRoCommand(sha1: String, numkeys: Int, key: [RedisKey], arg: [String]) -> RESPCommand {
        RESPCommand("EVALSHA_RO", sha1, numkeys, key, arg)
    }

    /// Executes a read-only server-side Lua script.
    ///
    /// Version: 7.0.0
    /// Complexity: Depends on the script that is executed.
    /// Categories: @slow, @scripting
    @inlinable
    public func evalRo(script: String, numkeys: Int, key: RedisKey..., arg: String...) async throws -> RESP3Token {
        let response = try await send(evalRoCommand(script: script, numkeys: numkeys, key: key, arg: arg))
        return response
    }

    @inlinable
    public func evalRoCommand(script: String, numkeys: Int, key: [RedisKey], arg: [String]) -> RESPCommand {
        RESPCommand("EVAL_RO", script, numkeys, key, arg)
    }

    /// Executes all commands in a transaction.
    ///
    /// Version: 1.2.0
    /// Complexity: Depends on commands in the transaction
    /// Categories: @slow, @transaction
    @inlinable
    public func exec() async throws -> RESP3Token {
        let response = try await send(execCommand())
        return response
    }

    @inlinable
    public func execCommand() -> RESPCommand {
        RESPCommand("EXEC")
    }

    /// Determines whether one or more keys exist.
    ///
    /// Version: 1.0.0
    /// Complexity: O(N) where N is the number of keys to check.
    /// Categories: @keyspace, @read, @fast
    @inlinable
    public func exists(key: RedisKey...) async throws -> RESP3Token {
        let response = try await send(existsCommand(key: key))
        return response
    }

    @inlinable
    public func existsCommand(key: [RedisKey]) -> RESPCommand {
        RESPCommand("EXISTS", key)
    }

    public enum EXPIRECondition: RESPRepresentable {
        case nx
        case xx
        case gt
        case lt

        @inlinable
        public func writeToRESPBuffer(_ buffer: inout ByteBuffer) {
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
    /// Version: 1.0.0
    /// Complexity: O(1)
    /// Categories: @keyspace, @write, @fast
    @inlinable
    public func expire(key: RedisKey, seconds: Int, condition: EXPIRECondition?) async throws -> RESP3Token {
        let response = try await send(expireCommand(key: key, seconds: seconds, condition: condition))
        return response
    }

    @inlinable
    public func expireCommand(key: RedisKey, seconds: Int, condition: EXPIRECondition?) -> RESPCommand {
        RESPCommand("EXPIRE", key, seconds, condition)
    }

    public enum EXPIREATCondition: RESPRepresentable {
        case nx
        case xx
        case gt
        case lt

        @inlinable
        public func writeToRESPBuffer(_ buffer: inout ByteBuffer) {
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
    /// Version: 1.2.0
    /// Complexity: O(1)
    /// Categories: @keyspace, @write, @fast
    @inlinable
    public func expireat(key: RedisKey, unixTimeSeconds: Date, condition: EXPIREATCondition?) async throws -> RESP3Token {
        let response = try await send(expireatCommand(key: key, unixTimeSeconds: unixTimeSeconds, condition: condition))
        return response
    }

    @inlinable
    public func expireatCommand(key: RedisKey, unixTimeSeconds: Date, condition: EXPIREATCondition?) -> RESPCommand {
        RESPCommand("EXPIREAT", key, unixTimeSeconds, condition)
    }

    /// Returns the expiration time of a key as a Unix timestamp.
    ///
    /// Version: 7.0.0
    /// Complexity: O(1)
    /// Categories: @keyspace, @read, @fast
    @inlinable
    public func expiretime(key: RedisKey) async throws -> RESP3Token {
        let response = try await send(expiretimeCommand(key: key))
        return response
    }

    @inlinable
    public func expiretimeCommand(key: RedisKey) -> RESPCommand {
        RESPCommand("EXPIRETIME", key)
    }

    public struct FAILOVERTarget: RESPRepresentable {
        @usableFromInline let host: String
        @usableFromInline let port: Int
        @usableFromInline let force: Bool

        @inlinable
        public func writeToRESPBuffer(_ buffer: inout ByteBuffer) {
            self.host.writeToRESPBuffer(&buffer)
            self.port.writeToRESPBuffer(&buffer)
            if self.force { "FORCE".writeToRESPBuffer(&buffer) }
        }
    }
    /// Starts a coordinated failover from a server to one of its replicas.
    ///
    /// Version: 6.2.0
    /// Complexity: O(1)
    /// Categories: @admin, @slow, @dangerous
    @inlinable
    public func failover(target: FAILOVERTarget?, abort: Bool, milliseconds: Int?) async throws -> RESP3Token {
        let response = try await send(failoverCommand(target: target, abort: abort, milliseconds: milliseconds))
        return response
    }

    @inlinable
    public func failoverCommand(target: FAILOVERTarget?, abort: Bool, milliseconds: Int?) -> RESPCommand {
        RESPCommand("FAILOVER", RESPWithToken("TO", target), RedisPureToken("ABORT", abort), RESPWithToken("TIMEOUT", milliseconds))
    }

    /// Invokes a function.
    ///
    /// Version: 7.0.0
    /// Complexity: Depends on the function that is executed.
    /// Categories: @slow, @scripting
    @inlinable
    public func fcall(function: String, numkeys: Int, key: RedisKey..., arg: String...) async throws -> RESP3Token {
        let response = try await send(fcallCommand(function: function, numkeys: numkeys, key: key, arg: arg))
        return response
    }

    @inlinable
    public func fcallCommand(function: String, numkeys: Int, key: [RedisKey], arg: [String]) -> RESPCommand {
        RESPCommand("FCALL", function, numkeys, key, arg)
    }

    /// Invokes a read-only function.
    ///
    /// Version: 7.0.0
    /// Complexity: Depends on the function that is executed.
    /// Categories: @slow, @scripting
    @inlinable
    public func fcallRo(function: String, numkeys: Int, key: RedisKey..., arg: String...) async throws -> RESP3Token {
        let response = try await send(fcallRoCommand(function: function, numkeys: numkeys, key: key, arg: arg))
        return response
    }

    @inlinable
    public func fcallRoCommand(function: String, numkeys: Int, key: [RedisKey], arg: [String]) -> RESPCommand {
        RESPCommand("FCALL_RO", function, numkeys, key, arg)
    }

    public enum FLUSHALLFlushType: RESPRepresentable {
        case async
        case sync

        @inlinable
        public func writeToRESPBuffer(_ buffer: inout ByteBuffer) {
            switch self {
            case .async: "ASYNC".writeToRESPBuffer(&buffer)
            case .sync: "SYNC".writeToRESPBuffer(&buffer)
            }
        }
    }
    /// Removes all keys from all databases.
    ///
    /// Version: 1.0.0
    /// Complexity: O(N) where N is the total number of keys in all databases
    /// Categories: @keyspace, @write, @slow, @dangerous
    @inlinable
    public func flushall(flushType: FLUSHALLFlushType?) async throws -> RESP3Token {
        let response = try await send(flushallCommand(flushType: flushType))
        return response
    }

    @inlinable
    public func flushallCommand(flushType: FLUSHALLFlushType?) -> RESPCommand {
        RESPCommand("FLUSHALL", flushType)
    }

    public enum FLUSHDBFlushType: RESPRepresentable {
        case async
        case sync

        @inlinable
        public func writeToRESPBuffer(_ buffer: inout ByteBuffer) {
            switch self {
            case .async: "ASYNC".writeToRESPBuffer(&buffer)
            case .sync: "SYNC".writeToRESPBuffer(&buffer)
            }
        }
    }
    /// Remove all keys from the current database.
    ///
    /// Version: 1.0.0
    /// Complexity: O(N) where N is the number of keys in the selected database
    /// Categories: @keyspace, @write, @slow, @dangerous
    @inlinable
    public func flushdb(flushType: FLUSHDBFlushType?) async throws -> RESP3Token {
        let response = try await send(flushdbCommand(flushType: flushType))
        return response
    }

    @inlinable
    public func flushdbCommand(flushType: FLUSHDBFlushType?) -> RESPCommand {
        RESPCommand("FLUSHDB", flushType)
    }

    /// A container for function commands.
    ///
    /// Version: 7.0.0
    /// Complexity: Depends on subcommand.
    /// Categories: @slow
    @inlinable
    public func function() async throws -> RESP3Token {
        let response = try await send(functionCommand())
        return response
    }

    @inlinable
    public func functionCommand() -> RESPCommand {
        RESPCommand("FUNCTION")
    }

    /// Deletes a library and its functions.
    ///
    /// Version: 7.0.0
    /// Complexity: O(1)
    /// Categories: @write, @slow, @scripting
    @inlinable
    public func functionDelete(libraryName: String) async throws -> RESP3Token {
        let response = try await send(functionDeleteCommand(libraryName: libraryName))
        return response
    }

    @inlinable
    public func functionDeleteCommand(libraryName: String) -> RESPCommand {
        RESPCommand("FUNCTION", "DELETE", libraryName)
    }

    /// Dumps all libraries into a serialized binary payload.
    ///
    /// Version: 7.0.0
    /// Complexity: O(N) where N is the number of functions
    /// Categories: @slow, @scripting
    @inlinable
    public func functionDump() async throws -> RESP3Token {
        let response = try await send(functionDumpCommand())
        return response
    }

    @inlinable
    public func functionDumpCommand() -> RESPCommand {
        RESPCommand("FUNCTION", "DUMP")
    }

    public enum FUNCTIONFLUSHFlushType: RESPRepresentable {
        case async
        case sync

        @inlinable
        public func writeToRESPBuffer(_ buffer: inout ByteBuffer) {
            switch self {
            case .async: "ASYNC".writeToRESPBuffer(&buffer)
            case .sync: "SYNC".writeToRESPBuffer(&buffer)
            }
        }
    }
    /// Deletes all libraries and functions.
    ///
    /// Version: 7.0.0
    /// Complexity: O(N) where N is the number of functions deleted
    /// Categories: @write, @slow, @scripting
    @inlinable
    public func functionFlush(flushType: FUNCTIONFLUSHFlushType?) async throws -> RESP3Token {
        let response = try await send(functionFlushCommand(flushType: flushType))
        return response
    }

    @inlinable
    public func functionFlushCommand(flushType: FUNCTIONFLUSHFlushType?) -> RESPCommand {
        RESPCommand("FUNCTION", "FLUSH", flushType)
    }

    /// Returns helpful text about the different subcommands.
    ///
    /// Version: 7.0.0
    /// Complexity: O(1)
    /// Categories: @slow, @scripting
    @inlinable
    public func functionHelp() async throws -> RESP3Token {
        let response = try await send(functionHelpCommand())
        return response
    }

    @inlinable
    public func functionHelpCommand() -> RESPCommand {
        RESPCommand("FUNCTION", "HELP")
    }

    /// Terminates a function during execution.
    ///
    /// Version: 7.0.0
    /// Complexity: O(1)
    /// Categories: @slow, @scripting
    @inlinable
    public func functionKill() async throws -> RESP3Token {
        let response = try await send(functionKillCommand())
        return response
    }

    @inlinable
    public func functionKillCommand() -> RESPCommand {
        RESPCommand("FUNCTION", "KILL")
    }

    /// Returns information about all libraries.
    ///
    /// Version: 7.0.0
    /// Complexity: O(N) where N is the number of functions
    /// Categories: @slow, @scripting
    @inlinable
    public func functionList(libraryNamePattern: String?, withcode: Bool) async throws -> RESP3Token {
        let response = try await send(functionListCommand(libraryNamePattern: libraryNamePattern, withcode: withcode))
        return response
    }

    @inlinable
    public func functionListCommand(libraryNamePattern: String?, withcode: Bool) -> RESPCommand {
        RESPCommand("FUNCTION", "LIST", RESPWithToken("LIBRARYNAME", libraryNamePattern), RedisPureToken("WITHCODE", withcode))
    }

    /// Creates a library.
    ///
    /// Version: 7.0.0
    /// Complexity: O(1) (considering compilation time is redundant)
    /// Categories: @write, @slow, @scripting
    @inlinable
    public func functionLoad(replace: Bool, functionCode: String) async throws -> RESP3Token {
        let response = try await send(functionLoadCommand(replace: replace, functionCode: functionCode))
        return response
    }

    @inlinable
    public func functionLoadCommand(replace: Bool, functionCode: String) -> RESPCommand {
        RESPCommand("FUNCTION", "LOAD", RedisPureToken("REPLACE", replace), functionCode)
    }

    public enum FUNCTIONRESTOREPolicy: RESPRepresentable {
        case flush
        case append
        case replace

        @inlinable
        public func writeToRESPBuffer(_ buffer: inout ByteBuffer) {
            switch self {
            case .flush: "FLUSH".writeToRESPBuffer(&buffer)
            case .append: "APPEND".writeToRESPBuffer(&buffer)
            case .replace: "REPLACE".writeToRESPBuffer(&buffer)
            }
        }
    }
    /// Restores all libraries from a payload.
    ///
    /// Version: 7.0.0
    /// Complexity: O(N) where N is the number of functions on the payload
    /// Categories: @write, @slow, @scripting
    @inlinable
    public func functionRestore(serializedValue: String, policy: FUNCTIONRESTOREPolicy?) async throws -> RESP3Token {
        let response = try await send(functionRestoreCommand(serializedValue: serializedValue, policy: policy))
        return response
    }

    @inlinable
    public func functionRestoreCommand(serializedValue: String, policy: FUNCTIONRESTOREPolicy?) -> RESPCommand {
        RESPCommand("FUNCTION", "RESTORE", serializedValue, policy)
    }

    /// Returns information about a function during execution.
    ///
    /// Version: 7.0.0
    /// Complexity: O(1)
    /// Categories: @slow, @scripting
    @inlinable
    public func functionStats() async throws -> RESP3Token {
        let response = try await send(functionStatsCommand())
        return response
    }

    @inlinable
    public func functionStatsCommand() -> RESPCommand {
        RESPCommand("FUNCTION", "STATS")
    }

    public enum GEOADDCondition: RESPRepresentable {
        case nx
        case xx

        @inlinable
        public func writeToRESPBuffer(_ buffer: inout ByteBuffer) {
            switch self {
            case .nx: "NX".writeToRESPBuffer(&buffer)
            case .xx: "XX".writeToRESPBuffer(&buffer)
            }
        }
    }
    public struct GEOADDData: RESPRepresentable {
        @usableFromInline let longitude: Double
        @usableFromInline let latitude: Double
        @usableFromInline let member: String

        @inlinable
        public func writeToRESPBuffer(_ buffer: inout ByteBuffer) {
            self.longitude.writeToRESPBuffer(&buffer)
            self.latitude.writeToRESPBuffer(&buffer)
            self.member.writeToRESPBuffer(&buffer)
        }
    }
    /// Adds one or more members to a geospatial index. The key is created if it doesn't exist.
    ///
    /// Version: 3.2.0
    /// Complexity: O(log(N)) for each item added, where N is the number of elements in the sorted set.
    /// Categories: @write, @geo, @slow
    @inlinable
    public func geoadd(key: RedisKey, condition: GEOADDCondition?, change: Bool, data: GEOADDData...) async throws -> RESP3Token {
        let response = try await send(geoaddCommand(key: key, condition: condition, change: change, data: data))
        return response
    }

    @inlinable
    public func geoaddCommand(key: RedisKey, condition: GEOADDCondition?, change: Bool, data: [GEOADDData]) -> RESPCommand {
        RESPCommand("GEOADD", key, condition, RedisPureToken("CH", change), data)
    }

    public enum GEODISTUnit: RESPRepresentable {
        case m
        case km
        case ft
        case mi

        @inlinable
        public func writeToRESPBuffer(_ buffer: inout ByteBuffer) {
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
    /// Version: 3.2.0
    /// Complexity: O(1)
    /// Categories: @read, @geo, @slow
    @inlinable
    public func geodist(key: RedisKey, member1: String, member2: String, unit: GEODISTUnit?) async throws -> RESP3Token {
        let response = try await send(geodistCommand(key: key, member1: member1, member2: member2, unit: unit))
        return response
    }

    @inlinable
    public func geodistCommand(key: RedisKey, member1: String, member2: String, unit: GEODISTUnit?) -> RESPCommand {
        RESPCommand("GEODIST", key, member1, member2, unit)
    }

    /// Returns members from a geospatial index as geohash strings.
    ///
    /// Version: 3.2.0
    /// Complexity: O(1) for each member requested.
    /// Categories: @read, @geo, @slow
    @inlinable
    public func geohash(key: RedisKey, member: String...) async throws -> RESP3Token {
        let response = try await send(geohashCommand(key: key, member: member))
        return response
    }

    @inlinable
    public func geohashCommand(key: RedisKey, member: [String]) -> RESPCommand {
        RESPCommand("GEOHASH", key, member)
    }

    /// Returns the longitude and latitude of members from a geospatial index.
    ///
    /// Version: 3.2.0
    /// Complexity: O(1) for each member requested.
    /// Categories: @read, @geo, @slow
    @inlinable
    public func geopos(key: RedisKey, member: String...) async throws -> RESP3Token {
        let response = try await send(geoposCommand(key: key, member: member))
        return response
    }

    @inlinable
    public func geoposCommand(key: RedisKey, member: [String]) -> RESPCommand {
        RESPCommand("GEOPOS", key, member)
    }

    public enum GEORADIUSUnit: RESPRepresentable {
        case m
        case km
        case ft
        case mi

        @inlinable
        public func writeToRESPBuffer(_ buffer: inout ByteBuffer) {
            switch self {
            case .m: "M".writeToRESPBuffer(&buffer)
            case .km: "KM".writeToRESPBuffer(&buffer)
            case .ft: "FT".writeToRESPBuffer(&buffer)
            case .mi: "MI".writeToRESPBuffer(&buffer)
            }
        }
    }
    public struct GEORADIUSCountBlock: RESPRepresentable {
        @usableFromInline let count: Int
        @usableFromInline let any: Bool

        @inlinable
        public func writeToRESPBuffer(_ buffer: inout ByteBuffer) {
            self.count.writeToRESPBuffer(&buffer)
            if self.any { "ANY".writeToRESPBuffer(&buffer) }
        }
    }
    public enum GEORADIUSOrder: RESPRepresentable {
        case asc
        case desc

        @inlinable
        public func writeToRESPBuffer(_ buffer: inout ByteBuffer) {
            switch self {
            case .asc: "ASC".writeToRESPBuffer(&buffer)
            case .desc: "DESC".writeToRESPBuffer(&buffer)
            }
        }
    }
    public enum GEORADIUSStore: RESPRepresentable {
        case storekey(RedisKey)
        case storedistkey(RedisKey)

        @inlinable
        public func writeToRESPBuffer(_ buffer: inout ByteBuffer) {
            switch self {
            case .storekey(let storekey): RESPWithToken("STORE", storekey).writeToRESPBuffer(&buffer)
            case .storedistkey(let storedistkey): RESPWithToken("STOREDIST", storedistkey).writeToRESPBuffer(&buffer)
            }
        }
    }
    /// Queries a geospatial index for members within a distance from a coordinate, optionally stores the result.
    ///
    /// Version: 3.2.0
    /// Complexity: O(N+log(M)) where N is the number of elements inside the bounding box of the circular area delimited by center and radius and M is the number of items inside the index.
    /// Categories: @write, @geo, @slow
    @inlinable
    public func georadius(key: RedisKey, longitude: Double, latitude: Double, radius: Double, unit: GEORADIUSUnit, withcoord: Bool, withdist: Bool, withhash: Bool, countBlock: GEORADIUSCountBlock?, order: GEORADIUSOrder?, store: GEORADIUSStore?) async throws -> RESP3Token {
        let response = try await send(georadiusCommand(key: key, longitude: longitude, latitude: latitude, radius: radius, unit: unit, withcoord: withcoord, withdist: withdist, withhash: withhash, countBlock: countBlock, order: order, store: store))
        return response
    }

    @inlinable
    public func georadiusCommand(key: RedisKey, longitude: Double, latitude: Double, radius: Double, unit: GEORADIUSUnit, withcoord: Bool, withdist: Bool, withhash: Bool, countBlock: GEORADIUSCountBlock?, order: GEORADIUSOrder?, store: GEORADIUSStore?) -> RESPCommand {
        RESPCommand("GEORADIUS", key, longitude, latitude, radius, unit, RedisPureToken("WITHCOORD", withcoord), RedisPureToken("WITHDIST", withdist), RedisPureToken("WITHHASH", withhash), countBlock, order, store)
    }

    public enum GEORADIUSBYMEMBERUnit: RESPRepresentable {
        case m
        case km
        case ft
        case mi

        @inlinable
        public func writeToRESPBuffer(_ buffer: inout ByteBuffer) {
            switch self {
            case .m: "M".writeToRESPBuffer(&buffer)
            case .km: "KM".writeToRESPBuffer(&buffer)
            case .ft: "FT".writeToRESPBuffer(&buffer)
            case .mi: "MI".writeToRESPBuffer(&buffer)
            }
        }
    }
    public struct GEORADIUSBYMEMBERCountBlock: RESPRepresentable {
        @usableFromInline let count: Int
        @usableFromInline let any: Bool

        @inlinable
        public func writeToRESPBuffer(_ buffer: inout ByteBuffer) {
            self.count.writeToRESPBuffer(&buffer)
            if self.any { "ANY".writeToRESPBuffer(&buffer) }
        }
    }
    public enum GEORADIUSBYMEMBEROrder: RESPRepresentable {
        case asc
        case desc

        @inlinable
        public func writeToRESPBuffer(_ buffer: inout ByteBuffer) {
            switch self {
            case .asc: "ASC".writeToRESPBuffer(&buffer)
            case .desc: "DESC".writeToRESPBuffer(&buffer)
            }
        }
    }
    public enum GEORADIUSBYMEMBERStore: RESPRepresentable {
        case storekey(RedisKey)
        case storedistkey(RedisKey)

        @inlinable
        public func writeToRESPBuffer(_ buffer: inout ByteBuffer) {
            switch self {
            case .storekey(let storekey): RESPWithToken("STORE", storekey).writeToRESPBuffer(&buffer)
            case .storedistkey(let storedistkey): RESPWithToken("STOREDIST", storedistkey).writeToRESPBuffer(&buffer)
            }
        }
    }
    /// Queries a geospatial index for members within a distance from a member, optionally stores the result.
    ///
    /// Version: 3.2.0
    /// Complexity: O(N+log(M)) where N is the number of elements inside the bounding box of the circular area delimited by center and radius and M is the number of items inside the index.
    /// Categories: @write, @geo, @slow
    @inlinable
    public func georadiusbymember(key: RedisKey, member: String, radius: Double, unit: GEORADIUSBYMEMBERUnit, withcoord: Bool, withdist: Bool, withhash: Bool, countBlock: GEORADIUSBYMEMBERCountBlock?, order: GEORADIUSBYMEMBEROrder?, store: GEORADIUSBYMEMBERStore?) async throws -> RESP3Token {
        let response = try await send(georadiusbymemberCommand(key: key, member: member, radius: radius, unit: unit, withcoord: withcoord, withdist: withdist, withhash: withhash, countBlock: countBlock, order: order, store: store))
        return response
    }

    @inlinable
    public func georadiusbymemberCommand(key: RedisKey, member: String, radius: Double, unit: GEORADIUSBYMEMBERUnit, withcoord: Bool, withdist: Bool, withhash: Bool, countBlock: GEORADIUSBYMEMBERCountBlock?, order: GEORADIUSBYMEMBEROrder?, store: GEORADIUSBYMEMBERStore?) -> RESPCommand {
        RESPCommand("GEORADIUSBYMEMBER", key, member, radius, unit, RedisPureToken("WITHCOORD", withcoord), RedisPureToken("WITHDIST", withdist), RedisPureToken("WITHHASH", withhash), countBlock, order, store)
    }

    public enum GEORADIUSBYMEMBERROUnit: RESPRepresentable {
        case m
        case km
        case ft
        case mi

        @inlinable
        public func writeToRESPBuffer(_ buffer: inout ByteBuffer) {
            switch self {
            case .m: "M".writeToRESPBuffer(&buffer)
            case .km: "KM".writeToRESPBuffer(&buffer)
            case .ft: "FT".writeToRESPBuffer(&buffer)
            case .mi: "MI".writeToRESPBuffer(&buffer)
            }
        }
    }
    public struct GEORADIUSBYMEMBERROCountBlock: RESPRepresentable {
        @usableFromInline let count: Int
        @usableFromInline let any: Bool

        @inlinable
        public func writeToRESPBuffer(_ buffer: inout ByteBuffer) {
            self.count.writeToRESPBuffer(&buffer)
            if self.any { "ANY".writeToRESPBuffer(&buffer) }
        }
    }
    public enum GEORADIUSBYMEMBERROOrder: RESPRepresentable {
        case asc
        case desc

        @inlinable
        public func writeToRESPBuffer(_ buffer: inout ByteBuffer) {
            switch self {
            case .asc: "ASC".writeToRESPBuffer(&buffer)
            case .desc: "DESC".writeToRESPBuffer(&buffer)
            }
        }
    }
    /// Returns members from a geospatial index that are within a distance from a member.
    ///
    /// Version: 3.2.10
    /// Complexity: O(N+log(M)) where N is the number of elements inside the bounding box of the circular area delimited by center and radius and M is the number of items inside the index.
    /// Categories: @read, @geo, @slow
    @inlinable
    public func georadiusbymemberRo(key: RedisKey, member: String, radius: Double, unit: GEORADIUSBYMEMBERROUnit, withcoord: Bool, withdist: Bool, withhash: Bool, countBlock: GEORADIUSBYMEMBERROCountBlock?, order: GEORADIUSBYMEMBERROOrder?) async throws -> RESP3Token {
        let response = try await send(georadiusbymemberRoCommand(key: key, member: member, radius: radius, unit: unit, withcoord: withcoord, withdist: withdist, withhash: withhash, countBlock: countBlock, order: order))
        return response
    }

    @inlinable
    public func georadiusbymemberRoCommand(key: RedisKey, member: String, radius: Double, unit: GEORADIUSBYMEMBERROUnit, withcoord: Bool, withdist: Bool, withhash: Bool, countBlock: GEORADIUSBYMEMBERROCountBlock?, order: GEORADIUSBYMEMBERROOrder?) -> RESPCommand {
        RESPCommand("GEORADIUSBYMEMBER_RO", key, member, radius, unit, RedisPureToken("WITHCOORD", withcoord), RedisPureToken("WITHDIST", withdist), RedisPureToken("WITHHASH", withhash), countBlock, order)
    }

    public enum GEORADIUSROUnit: RESPRepresentable {
        case m
        case km
        case ft
        case mi

        @inlinable
        public func writeToRESPBuffer(_ buffer: inout ByteBuffer) {
            switch self {
            case .m: "M".writeToRESPBuffer(&buffer)
            case .km: "KM".writeToRESPBuffer(&buffer)
            case .ft: "FT".writeToRESPBuffer(&buffer)
            case .mi: "MI".writeToRESPBuffer(&buffer)
            }
        }
    }
    public struct GEORADIUSROCountBlock: RESPRepresentable {
        @usableFromInline let count: Int
        @usableFromInline let any: Bool

        @inlinable
        public func writeToRESPBuffer(_ buffer: inout ByteBuffer) {
            self.count.writeToRESPBuffer(&buffer)
            if self.any { "ANY".writeToRESPBuffer(&buffer) }
        }
    }
    public enum GEORADIUSROOrder: RESPRepresentable {
        case asc
        case desc

        @inlinable
        public func writeToRESPBuffer(_ buffer: inout ByteBuffer) {
            switch self {
            case .asc: "ASC".writeToRESPBuffer(&buffer)
            case .desc: "DESC".writeToRESPBuffer(&buffer)
            }
        }
    }
    /// Returns members from a geospatial index that are within a distance from a coordinate.
    ///
    /// Version: 3.2.10
    /// Complexity: O(N+log(M)) where N is the number of elements inside the bounding box of the circular area delimited by center and radius and M is the number of items inside the index.
    /// Categories: @read, @geo, @slow
    @inlinable
    public func georadiusRo(key: RedisKey, longitude: Double, latitude: Double, radius: Double, unit: GEORADIUSROUnit, withcoord: Bool, withdist: Bool, withhash: Bool, countBlock: GEORADIUSROCountBlock?, order: GEORADIUSROOrder?) async throws -> RESP3Token {
        let response = try await send(georadiusRoCommand(key: key, longitude: longitude, latitude: latitude, radius: radius, unit: unit, withcoord: withcoord, withdist: withdist, withhash: withhash, countBlock: countBlock, order: order))
        return response
    }

    @inlinable
    public func georadiusRoCommand(key: RedisKey, longitude: Double, latitude: Double, radius: Double, unit: GEORADIUSROUnit, withcoord: Bool, withdist: Bool, withhash: Bool, countBlock: GEORADIUSROCountBlock?, order: GEORADIUSROOrder?) -> RESPCommand {
        RESPCommand("GEORADIUS_RO", key, longitude, latitude, radius, unit, RedisPureToken("WITHCOORD", withcoord), RedisPureToken("WITHDIST", withdist), RedisPureToken("WITHHASH", withhash), countBlock, order)
    }

    public struct GEOSEARCHFromFromlonlat: RESPRepresentable {
        @usableFromInline let longitude: Double
        @usableFromInline let latitude: Double

        @inlinable
        public func writeToRESPBuffer(_ buffer: inout ByteBuffer) {
            self.longitude.writeToRESPBuffer(&buffer)
            self.latitude.writeToRESPBuffer(&buffer)
        }
    }
    public enum GEOSEARCHFrom: RESPRepresentable {
        case member(String)
        case fromlonlat(GEOSEARCHFromFromlonlat)

        @inlinable
        public func writeToRESPBuffer(_ buffer: inout ByteBuffer) {
            switch self {
            case .member(let member): RESPWithToken("FROMMEMBER", member).writeToRESPBuffer(&buffer)
            case .fromlonlat(let fromlonlat): RESPWithToken("FROMLONLAT", fromlonlat).writeToRESPBuffer(&buffer)
            }
        }
    }
    public enum GEOSEARCHByCircleUnit: RESPRepresentable {
        case m
        case km
        case ft
        case mi

        @inlinable
        public func writeToRESPBuffer(_ buffer: inout ByteBuffer) {
            switch self {
            case .m: "M".writeToRESPBuffer(&buffer)
            case .km: "KM".writeToRESPBuffer(&buffer)
            case .ft: "FT".writeToRESPBuffer(&buffer)
            case .mi: "MI".writeToRESPBuffer(&buffer)
            }
        }
    }
    public struct GEOSEARCHByCircle: RESPRepresentable {
        @usableFromInline let radius: Double
        @usableFromInline let unit: GEOSEARCHByCircleUnit

        @inlinable
        public func writeToRESPBuffer(_ buffer: inout ByteBuffer) {
            self.radius.writeToRESPBuffer(&buffer)
            self.unit.writeToRESPBuffer(&buffer)
        }
    }
    public enum GEOSEARCHByBoxUnit: RESPRepresentable {
        case m
        case km
        case ft
        case mi

        @inlinable
        public func writeToRESPBuffer(_ buffer: inout ByteBuffer) {
            switch self {
            case .m: "M".writeToRESPBuffer(&buffer)
            case .km: "KM".writeToRESPBuffer(&buffer)
            case .ft: "FT".writeToRESPBuffer(&buffer)
            case .mi: "MI".writeToRESPBuffer(&buffer)
            }
        }
    }
    public struct GEOSEARCHByBox: RESPRepresentable {
        @usableFromInline let width: Double
        @usableFromInline let height: Double
        @usableFromInline let unit: GEOSEARCHByBoxUnit

        @inlinable
        public func writeToRESPBuffer(_ buffer: inout ByteBuffer) {
            self.width.writeToRESPBuffer(&buffer)
            self.height.writeToRESPBuffer(&buffer)
            self.unit.writeToRESPBuffer(&buffer)
        }
    }
    public enum GEOSEARCHBy: RESPRepresentable {
        case circle(GEOSEARCHByCircle)
        case box(GEOSEARCHByBox)

        @inlinable
        public func writeToRESPBuffer(_ buffer: inout ByteBuffer) {
            switch self {
            case .circle(let circle): circle.writeToRESPBuffer(&buffer)
            case .box(let box): box.writeToRESPBuffer(&buffer)
            }
        }
    }
    public enum GEOSEARCHOrder: RESPRepresentable {
        case asc
        case desc

        @inlinable
        public func writeToRESPBuffer(_ buffer: inout ByteBuffer) {
            switch self {
            case .asc: "ASC".writeToRESPBuffer(&buffer)
            case .desc: "DESC".writeToRESPBuffer(&buffer)
            }
        }
    }
    public struct GEOSEARCHCountBlock: RESPRepresentable {
        @usableFromInline let count: Int
        @usableFromInline let any: Bool

        @inlinable
        public func writeToRESPBuffer(_ buffer: inout ByteBuffer) {
            self.count.writeToRESPBuffer(&buffer)
            if self.any { "ANY".writeToRESPBuffer(&buffer) }
        }
    }
    /// Queries a geospatial index for members inside an area of a box or a circle.
    ///
    /// Version: 6.2.0
    /// Complexity: O(N+log(M)) where N is the number of elements in the grid-aligned bounding box area around the shape provided as the filter and M is the number of items inside the shape
    /// Categories: @read, @geo, @slow
    @inlinable
    public func geosearch(key: RedisKey, from: GEOSEARCHFrom, by: GEOSEARCHBy, order: GEOSEARCHOrder?, countBlock: GEOSEARCHCountBlock?, withcoord: Bool, withdist: Bool, withhash: Bool) async throws -> RESP3Token {
        let response = try await send(geosearchCommand(key: key, from: from, by: by, order: order, countBlock: countBlock, withcoord: withcoord, withdist: withdist, withhash: withhash))
        return response
    }

    @inlinable
    public func geosearchCommand(key: RedisKey, from: GEOSEARCHFrom, by: GEOSEARCHBy, order: GEOSEARCHOrder?, countBlock: GEOSEARCHCountBlock?, withcoord: Bool, withdist: Bool, withhash: Bool) -> RESPCommand {
        RESPCommand("GEOSEARCH", key, from, by, order, countBlock, RedisPureToken("WITHCOORD", withcoord), RedisPureToken("WITHDIST", withdist), RedisPureToken("WITHHASH", withhash))
    }

    public struct GEOSEARCHSTOREFromFromlonlat: RESPRepresentable {
        @usableFromInline let longitude: Double
        @usableFromInline let latitude: Double

        @inlinable
        public func writeToRESPBuffer(_ buffer: inout ByteBuffer) {
            self.longitude.writeToRESPBuffer(&buffer)
            self.latitude.writeToRESPBuffer(&buffer)
        }
    }
    public enum GEOSEARCHSTOREFrom: RESPRepresentable {
        case member(String)
        case fromlonlat(GEOSEARCHSTOREFromFromlonlat)

        @inlinable
        public func writeToRESPBuffer(_ buffer: inout ByteBuffer) {
            switch self {
            case .member(let member): RESPWithToken("FROMMEMBER", member).writeToRESPBuffer(&buffer)
            case .fromlonlat(let fromlonlat): RESPWithToken("FROMLONLAT", fromlonlat).writeToRESPBuffer(&buffer)
            }
        }
    }
    public enum GEOSEARCHSTOREByCircleUnit: RESPRepresentable {
        case m
        case km
        case ft
        case mi

        @inlinable
        public func writeToRESPBuffer(_ buffer: inout ByteBuffer) {
            switch self {
            case .m: "M".writeToRESPBuffer(&buffer)
            case .km: "KM".writeToRESPBuffer(&buffer)
            case .ft: "FT".writeToRESPBuffer(&buffer)
            case .mi: "MI".writeToRESPBuffer(&buffer)
            }
        }
    }
    public struct GEOSEARCHSTOREByCircle: RESPRepresentable {
        @usableFromInline let radius: Double
        @usableFromInline let unit: GEOSEARCHSTOREByCircleUnit

        @inlinable
        public func writeToRESPBuffer(_ buffer: inout ByteBuffer) {
            self.radius.writeToRESPBuffer(&buffer)
            self.unit.writeToRESPBuffer(&buffer)
        }
    }
    public enum GEOSEARCHSTOREByBoxUnit: RESPRepresentable {
        case m
        case km
        case ft
        case mi

        @inlinable
        public func writeToRESPBuffer(_ buffer: inout ByteBuffer) {
            switch self {
            case .m: "M".writeToRESPBuffer(&buffer)
            case .km: "KM".writeToRESPBuffer(&buffer)
            case .ft: "FT".writeToRESPBuffer(&buffer)
            case .mi: "MI".writeToRESPBuffer(&buffer)
            }
        }
    }
    public struct GEOSEARCHSTOREByBox: RESPRepresentable {
        @usableFromInline let width: Double
        @usableFromInline let height: Double
        @usableFromInline let unit: GEOSEARCHSTOREByBoxUnit

        @inlinable
        public func writeToRESPBuffer(_ buffer: inout ByteBuffer) {
            self.width.writeToRESPBuffer(&buffer)
            self.height.writeToRESPBuffer(&buffer)
            self.unit.writeToRESPBuffer(&buffer)
        }
    }
    public enum GEOSEARCHSTOREBy: RESPRepresentable {
        case circle(GEOSEARCHSTOREByCircle)
        case box(GEOSEARCHSTOREByBox)

        @inlinable
        public func writeToRESPBuffer(_ buffer: inout ByteBuffer) {
            switch self {
            case .circle(let circle): circle.writeToRESPBuffer(&buffer)
            case .box(let box): box.writeToRESPBuffer(&buffer)
            }
        }
    }
    public enum GEOSEARCHSTOREOrder: RESPRepresentable {
        case asc
        case desc

        @inlinable
        public func writeToRESPBuffer(_ buffer: inout ByteBuffer) {
            switch self {
            case .asc: "ASC".writeToRESPBuffer(&buffer)
            case .desc: "DESC".writeToRESPBuffer(&buffer)
            }
        }
    }
    public struct GEOSEARCHSTORECountBlock: RESPRepresentable {
        @usableFromInline let count: Int
        @usableFromInline let any: Bool

        @inlinable
        public func writeToRESPBuffer(_ buffer: inout ByteBuffer) {
            self.count.writeToRESPBuffer(&buffer)
            if self.any { "ANY".writeToRESPBuffer(&buffer) }
        }
    }
    /// Queries a geospatial index for members inside an area of a box or a circle, optionally stores the result.
    ///
    /// Version: 6.2.0
    /// Complexity: O(N+log(M)) where N is the number of elements in the grid-aligned bounding box area around the shape provided as the filter and M is the number of items inside the shape
    /// Categories: @write, @geo, @slow
    @inlinable
    public func geosearchstore(destination: RedisKey, source: RedisKey, from: GEOSEARCHSTOREFrom, by: GEOSEARCHSTOREBy, order: GEOSEARCHSTOREOrder?, countBlock: GEOSEARCHSTORECountBlock?, storedist: Bool) async throws -> RESP3Token {
        let response = try await send(geosearchstoreCommand(destination: destination, source: source, from: from, by: by, order: order, countBlock: countBlock, storedist: storedist))
        return response
    }

    @inlinable
    public func geosearchstoreCommand(destination: RedisKey, source: RedisKey, from: GEOSEARCHSTOREFrom, by: GEOSEARCHSTOREBy, order: GEOSEARCHSTOREOrder?, countBlock: GEOSEARCHSTORECountBlock?, storedist: Bool) -> RESPCommand {
        RESPCommand("GEOSEARCHSTORE", destination, source, from, by, order, countBlock, RedisPureToken("STOREDIST", storedist))
    }

    /// Returns the string value of a key.
    ///
    /// Version: 1.0.0
    /// Complexity: O(1)
    /// Categories: @read, @string, @fast
    @inlinable
    public func get(key: RedisKey) async throws -> RESP3Token {
        let response = try await send(getCommand(key: key))
        return response
    }

    @inlinable
    public func getCommand(key: RedisKey) -> RESPCommand {
        RESPCommand("GET", key)
    }

    /// Returns a bit value by offset.
    ///
    /// Version: 2.2.0
    /// Complexity: O(1)
    /// Categories: @read, @bitmap, @fast
    @inlinable
    public func getbit(key: RedisKey, offset: Int) async throws -> RESP3Token {
        let response = try await send(getbitCommand(key: key, offset: offset))
        return response
    }

    @inlinable
    public func getbitCommand(key: RedisKey, offset: Int) -> RESPCommand {
        RESPCommand("GETBIT", key, offset)
    }

    /// Returns the string value of a key after deleting the key.
    ///
    /// Version: 6.2.0
    /// Complexity: O(1)
    /// Categories: @write, @string, @fast
    @inlinable
    public func getdel(key: RedisKey) async throws -> RESP3Token {
        let response = try await send(getdelCommand(key: key))
        return response
    }

    @inlinable
    public func getdelCommand(key: RedisKey) -> RESPCommand {
        RESPCommand("GETDEL", key)
    }

    public enum GETEXExpiration: RESPRepresentable {
        case seconds(Int)
        case milliseconds(Int)
        case unixTimeSeconds(Date)
        case unixTimeMilliseconds(Date)
        case persist

        @inlinable
        public func writeToRESPBuffer(_ buffer: inout ByteBuffer) {
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
    /// Version: 6.2.0
    /// Complexity: O(1)
    /// Categories: @write, @string, @fast
    @inlinable
    public func getex(key: RedisKey, expiration: GETEXExpiration?) async throws -> RESP3Token {
        let response = try await send(getexCommand(key: key, expiration: expiration))
        return response
    }

    @inlinable
    public func getexCommand(key: RedisKey, expiration: GETEXExpiration?) -> RESPCommand {
        RESPCommand("GETEX", key, expiration)
    }

    /// Returns a substring of the string stored at a key.
    ///
    /// Version: 2.4.0
    /// Complexity: O(N) where N is the length of the returned string. The complexity is ultimately determined by the returned length, but because creating a substring from an existing string is very cheap, it can be considered O(1) for small strings.
    /// Categories: @read, @string, @slow
    @inlinable
    public func getrange(key: RedisKey, start: Int, end: Int) async throws -> RESP3Token {
        let response = try await send(getrangeCommand(key: key, start: start, end: end))
        return response
    }

    @inlinable
    public func getrangeCommand(key: RedisKey, start: Int, end: Int) -> RESPCommand {
        RESPCommand("GETRANGE", key, start, end)
    }

    /// Returns the previous string value of a key after setting it to a new value.
    ///
    /// Version: 1.0.0
    /// Complexity: O(1)
    /// Categories: @write, @string, @fast
    @inlinable
    public func getset(key: RedisKey, value: String) async throws -> RESP3Token {
        let response = try await send(getsetCommand(key: key, value: value))
        return response
    }

    @inlinable
    public func getsetCommand(key: RedisKey, value: String) -> RESPCommand {
        RESPCommand("GETSET", key, value)
    }

    /// Deletes one or more fields and their values from a hash. Deletes the hash if no fields remain.
    ///
    /// Version: 2.0.0
    /// Complexity: O(N) where N is the number of fields to be removed.
    /// Categories: @write, @hash, @fast
    @inlinable
    public func hdel(key: RedisKey, field: String...) async throws -> RESP3Token {
        let response = try await send(hdelCommand(key: key, field: field))
        return response
    }

    @inlinable
    public func hdelCommand(key: RedisKey, field: [String]) -> RESPCommand {
        RESPCommand("HDEL", key, field)
    }

    public struct HELLOArgumentsAuth: RESPRepresentable {
        @usableFromInline let username: String
        @usableFromInline let password: String

        @inlinable
        public func writeToRESPBuffer(_ buffer: inout ByteBuffer) {
            self.username.writeToRESPBuffer(&buffer)
            self.password.writeToRESPBuffer(&buffer)
        }
    }
    public struct HELLOArguments: RESPRepresentable {
        @usableFromInline let protover: Int
        @usableFromInline let auth: HELLOArgumentsAuth?
        @usableFromInline let clientname: String?

        @inlinable
        public func writeToRESPBuffer(_ buffer: inout ByteBuffer) {
            self.protover.writeToRESPBuffer(&buffer)
            self.auth.writeToRESPBuffer(&buffer)
            self.clientname.writeToRESPBuffer(&buffer)
        }
    }
    /// Handshakes with the Redis server.
    ///
    /// Version: 6.0.0
    /// Complexity: O(1)
    /// Categories: @fast, @connection
    @inlinable
    public func hello(arguments: HELLOArguments?) async throws -> RESP3Token {
        let response = try await send(helloCommand(arguments: arguments))
        return response
    }

    @inlinable
    public func helloCommand(arguments: HELLOArguments?) -> RESPCommand {
        RESPCommand("HELLO", arguments)
    }

    /// Determines whether a field exists in a hash.
    ///
    /// Version: 2.0.0
    /// Complexity: O(1)
    /// Categories: @read, @hash, @fast
    @inlinable
    public func hexists(key: RedisKey, field: String) async throws -> RESP3Token {
        let response = try await send(hexistsCommand(key: key, field: field))
        return response
    }

    @inlinable
    public func hexistsCommand(key: RedisKey, field: String) -> RESPCommand {
        RESPCommand("HEXISTS", key, field)
    }

    /// Returns the value of a field in a hash.
    ///
    /// Version: 2.0.0
    /// Complexity: O(1)
    /// Categories: @read, @hash, @fast
    @inlinable
    public func hget(key: RedisKey, field: String) async throws -> RESP3Token {
        let response = try await send(hgetCommand(key: key, field: field))
        return response
    }

    @inlinable
    public func hgetCommand(key: RedisKey, field: String) -> RESPCommand {
        RESPCommand("HGET", key, field)
    }

    /// Returns all fields and values in a hash.
    ///
    /// Version: 2.0.0
    /// Complexity: O(N) where N is the size of the hash.
    /// Categories: @read, @hash, @slow
    @inlinable
    public func hgetall(key: RedisKey) async throws -> RESP3Token {
        let response = try await send(hgetallCommand(key: key))
        return response
    }

    @inlinable
    public func hgetallCommand(key: RedisKey) -> RESPCommand {
        RESPCommand("HGETALL", key)
    }

    /// Increments the integer value of a field in a hash by a number. Uses 0 as initial value if the field doesn't exist.
    ///
    /// Version: 2.0.0
    /// Complexity: O(1)
    /// Categories: @write, @hash, @fast
    @inlinable
    public func hincrby(key: RedisKey, field: String, increment: Int) async throws -> RESP3Token {
        let response = try await send(hincrbyCommand(key: key, field: field, increment: increment))
        return response
    }

    @inlinable
    public func hincrbyCommand(key: RedisKey, field: String, increment: Int) -> RESPCommand {
        RESPCommand("HINCRBY", key, field, increment)
    }

    /// Increments the floating point value of a field by a number. Uses 0 as initial value if the field doesn't exist.
    ///
    /// Version: 2.6.0
    /// Complexity: O(1)
    /// Categories: @write, @hash, @fast
    @inlinable
    public func hincrbyfloat(key: RedisKey, field: String, increment: Double) async throws -> RESP3Token {
        let response = try await send(hincrbyfloatCommand(key: key, field: field, increment: increment))
        return response
    }

    @inlinable
    public func hincrbyfloatCommand(key: RedisKey, field: String, increment: Double) -> RESPCommand {
        RESPCommand("HINCRBYFLOAT", key, field, increment)
    }

    /// Returns all fields in a hash.
    ///
    /// Version: 2.0.0
    /// Complexity: O(N) where N is the size of the hash.
    /// Categories: @read, @hash, @slow
    @inlinable
    public func hkeys(key: RedisKey) async throws -> RESP3Token {
        let response = try await send(hkeysCommand(key: key))
        return response
    }

    @inlinable
    public func hkeysCommand(key: RedisKey) -> RESPCommand {
        RESPCommand("HKEYS", key)
    }

    /// Returns the number of fields in a hash.
    ///
    /// Version: 2.0.0
    /// Complexity: O(1)
    /// Categories: @read, @hash, @fast
    @inlinable
    public func hlen(key: RedisKey) async throws -> RESP3Token {
        let response = try await send(hlenCommand(key: key))
        return response
    }

    @inlinable
    public func hlenCommand(key: RedisKey) -> RESPCommand {
        RESPCommand("HLEN", key)
    }

    /// Returns the values of all fields in a hash.
    ///
    /// Version: 2.0.0
    /// Complexity: O(N) where N is the number of fields being requested.
    /// Categories: @read, @hash, @fast
    @inlinable
    public func hmget(key: RedisKey, field: String...) async throws -> RESP3Token {
        let response = try await send(hmgetCommand(key: key, field: field))
        return response
    }

    @inlinable
    public func hmgetCommand(key: RedisKey, field: [String]) -> RESPCommand {
        RESPCommand("HMGET", key, field)
    }

    public struct HMSETData: RESPRepresentable {
        @usableFromInline let field: String
        @usableFromInline let value: String

        @inlinable
        public func writeToRESPBuffer(_ buffer: inout ByteBuffer) {
            self.field.writeToRESPBuffer(&buffer)
            self.value.writeToRESPBuffer(&buffer)
        }
    }
    /// Sets the values of multiple fields.
    ///
    /// Version: 2.0.0
    /// Complexity: O(N) where N is the number of fields being set.
    /// Categories: @write, @hash, @fast
    @inlinable
    public func hmset(key: RedisKey, data: HMSETData...) async throws -> RESP3Token {
        let response = try await send(hmsetCommand(key: key, data: data))
        return response
    }

    @inlinable
    public func hmsetCommand(key: RedisKey, data: [HMSETData]) -> RESPCommand {
        RESPCommand("HMSET", key, data)
    }

    public struct HRANDFIELDOptions: RESPRepresentable {
        @usableFromInline let count: Int
        @usableFromInline let withvalues: Bool

        @inlinable
        public func writeToRESPBuffer(_ buffer: inout ByteBuffer) {
            self.count.writeToRESPBuffer(&buffer)
            if self.withvalues { "WITHVALUES".writeToRESPBuffer(&buffer) }
        }
    }
    /// Returns one or more random fields from a hash.
    ///
    /// Version: 6.2.0
    /// Complexity: O(N) where N is the number of fields returned
    /// Categories: @read, @hash, @slow
    @inlinable
    public func hrandfield(key: RedisKey, options: HRANDFIELDOptions?) async throws -> RESP3Token {
        let response = try await send(hrandfieldCommand(key: key, options: options))
        return response
    }

    @inlinable
    public func hrandfieldCommand(key: RedisKey, options: HRANDFIELDOptions?) -> RESPCommand {
        RESPCommand("HRANDFIELD", key, options)
    }

    /// Iterates over fields and values of a hash.
    ///
    /// Version: 2.8.0
    /// Complexity: O(1) for every call. O(N) for a complete iteration, including enough command calls for the cursor to return back to 0. N is the number of elements inside the collection.
    /// Categories: @read, @hash, @slow
    @inlinable
    public func hscan(key: RedisKey, cursor: Int, pattern: String?, count: Int?) async throws -> RESP3Token {
        let response = try await send(hscanCommand(key: key, cursor: cursor, pattern: pattern, count: count))
        return response
    }

    @inlinable
    public func hscanCommand(key: RedisKey, cursor: Int, pattern: String?, count: Int?) -> RESPCommand {
        RESPCommand("HSCAN", key, cursor, RESPWithToken("MATCH", pattern), RESPWithToken("COUNT", count))
    }

    public struct HSETData: RESPRepresentable {
        @usableFromInline let field: String
        @usableFromInline let value: String

        @inlinable
        public func writeToRESPBuffer(_ buffer: inout ByteBuffer) {
            self.field.writeToRESPBuffer(&buffer)
            self.value.writeToRESPBuffer(&buffer)
        }
    }
    /// Creates or modifies the value of a field in a hash.
    ///
    /// Version: 2.0.0
    /// Complexity: O(1) for each field/value pair added, so O(N) to add N field/value pairs when the command is called with multiple field/value pairs.
    /// Categories: @write, @hash, @fast
    @inlinable
    public func hset(key: RedisKey, data: HSETData...) async throws -> RESP3Token {
        let response = try await send(hsetCommand(key: key, data: data))
        return response
    }

    @inlinable
    public func hsetCommand(key: RedisKey, data: [HSETData]) -> RESPCommand {
        RESPCommand("HSET", key, data)
    }

    /// Sets the value of a field in a hash only when the field doesn't exist.
    ///
    /// Version: 2.0.0
    /// Complexity: O(1)
    /// Categories: @write, @hash, @fast
    @inlinable
    public func hsetnx(key: RedisKey, field: String, value: String) async throws -> RESP3Token {
        let response = try await send(hsetnxCommand(key: key, field: field, value: value))
        return response
    }

    @inlinable
    public func hsetnxCommand(key: RedisKey, field: String, value: String) -> RESPCommand {
        RESPCommand("HSETNX", key, field, value)
    }

    /// Returns the length of the value of a field.
    ///
    /// Version: 3.2.0
    /// Complexity: O(1)
    /// Categories: @read, @hash, @fast
    @inlinable
    public func hstrlen(key: RedisKey, field: String) async throws -> RESP3Token {
        let response = try await send(hstrlenCommand(key: key, field: field))
        return response
    }

    @inlinable
    public func hstrlenCommand(key: RedisKey, field: String) -> RESPCommand {
        RESPCommand("HSTRLEN", key, field)
    }

    /// Returns all values in a hash.
    ///
    /// Version: 2.0.0
    /// Complexity: O(N) where N is the size of the hash.
    /// Categories: @read, @hash, @slow
    @inlinable
    public func hvals(key: RedisKey) async throws -> RESP3Token {
        let response = try await send(hvalsCommand(key: key))
        return response
    }

    @inlinable
    public func hvalsCommand(key: RedisKey) -> RESPCommand {
        RESPCommand("HVALS", key)
    }

    /// Increments the integer value of a key by one. Uses 0 as initial value if the key doesn't exist.
    ///
    /// Version: 1.0.0
    /// Complexity: O(1)
    /// Categories: @write, @string, @fast
    @inlinable
    public func incr(key: RedisKey) async throws -> RESP3Token {
        let response = try await send(incrCommand(key: key))
        return response
    }

    @inlinable
    public func incrCommand(key: RedisKey) -> RESPCommand {
        RESPCommand("INCR", key)
    }

    /// Increments the integer value of a key by a number. Uses 0 as initial value if the key doesn't exist.
    ///
    /// Version: 1.0.0
    /// Complexity: O(1)
    /// Categories: @write, @string, @fast
    @inlinable
    public func incrby(key: RedisKey, increment: Int) async throws -> RESP3Token {
        let response = try await send(incrbyCommand(key: key, increment: increment))
        return response
    }

    @inlinable
    public func incrbyCommand(key: RedisKey, increment: Int) -> RESPCommand {
        RESPCommand("INCRBY", key, increment)
    }

    /// Increment the floating point value of a key by a number. Uses 0 as initial value if the key doesn't exist.
    ///
    /// Version: 2.6.0
    /// Complexity: O(1)
    /// Categories: @write, @string, @fast
    @inlinable
    public func incrbyfloat(key: RedisKey, increment: Double) async throws -> RESP3Token {
        let response = try await send(incrbyfloatCommand(key: key, increment: increment))
        return response
    }

    @inlinable
    public func incrbyfloatCommand(key: RedisKey, increment: Double) -> RESPCommand {
        RESPCommand("INCRBYFLOAT", key, increment)
    }

    /// Returns information and statistics about the server.
    ///
    /// Version: 1.0.0
    /// Complexity: O(1)
    /// Categories: @slow, @dangerous
    @inlinable
    public func info(section: String...) async throws -> RESP3Token {
        let response = try await send(infoCommand(section: section))
        return response
    }

    @inlinable
    public func infoCommand(section: [String]) -> RESPCommand {
        RESPCommand("INFO", section)
    }

    /// Returns all key names that match a pattern.
    ///
    /// Version: 1.0.0
    /// Complexity: O(N) with N being the number of keys in the database, under the assumption that the key names in the database and the given pattern have limited length.
    /// Categories: @keyspace, @read, @slow, @dangerous
    @inlinable
    public func keys(pattern: String) async throws -> RESP3Token {
        let response = try await send(keysCommand(pattern: pattern))
        return response
    }

    @inlinable
    public func keysCommand(pattern: String) -> RESPCommand {
        RESPCommand("KEYS", pattern)
    }

    /// Returns the Unix timestamp of the last successful save to disk.
    ///
    /// Version: 1.0.0
    /// Complexity: O(1)
    /// Categories: @admin, @fast, @dangerous
    @inlinable
    public func lastsave() async throws -> RESP3Token {
        let response = try await send(lastsaveCommand())
        return response
    }

    @inlinable
    public func lastsaveCommand() -> RESPCommand {
        RESPCommand("LASTSAVE")
    }

    /// A container for latency diagnostics commands.
    ///
    /// Version: 2.8.13
    /// Complexity: Depends on subcommand.
    /// Categories: @slow
    @inlinable
    public func latency() async throws -> RESP3Token {
        let response = try await send(latencyCommand())
        return response
    }

    @inlinable
    public func latencyCommand() -> RESPCommand {
        RESPCommand("LATENCY")
    }

    /// Returns a human-readable latency analysis report.
    ///
    /// Version: 2.8.13
    /// Complexity: O(1)
    /// Categories: @admin, @slow, @dangerous
    @inlinable
    public func latencyDoctor() async throws -> RESP3Token {
        let response = try await send(latencyDoctorCommand())
        return response
    }

    @inlinable
    public func latencyDoctorCommand() -> RESPCommand {
        RESPCommand("LATENCY", "DOCTOR")
    }

    /// Returns a latency graph for an event.
    ///
    /// Version: 2.8.13
    /// Complexity: O(1)
    /// Categories: @admin, @slow, @dangerous
    @inlinable
    public func latencyGraph(event: String) async throws -> RESP3Token {
        let response = try await send(latencyGraphCommand(event: event))
        return response
    }

    @inlinable
    public func latencyGraphCommand(event: String) -> RESPCommand {
        RESPCommand("LATENCY", "GRAPH", event)
    }

    /// Returns helpful text about the different subcommands.
    ///
    /// Version: 2.8.13
    /// Complexity: O(1)
    /// Categories: @slow
    @inlinable
    public func latencyHelp() async throws -> RESP3Token {
        let response = try await send(latencyHelpCommand())
        return response
    }

    @inlinable
    public func latencyHelpCommand() -> RESPCommand {
        RESPCommand("LATENCY", "HELP")
    }

    /// Returns the cumulative distribution of latencies of a subset or all commands.
    ///
    /// Version: 7.0.0
    /// Complexity: O(N) where N is the number of commands with latency information being retrieved.
    /// Categories: @admin, @slow, @dangerous
    @inlinable
    public func latencyHistogram(command: String...) async throws -> RESP3Token {
        let response = try await send(latencyHistogramCommand(command: command))
        return response
    }

    @inlinable
    public func latencyHistogramCommand(command: [String]) -> RESPCommand {
        RESPCommand("LATENCY", "HISTOGRAM", command)
    }

    /// Returns timestamp-latency samples for an event.
    ///
    /// Version: 2.8.13
    /// Complexity: O(1)
    /// Categories: @admin, @slow, @dangerous
    @inlinable
    public func latencyHistory(event: String) async throws -> RESP3Token {
        let response = try await send(latencyHistoryCommand(event: event))
        return response
    }

    @inlinable
    public func latencyHistoryCommand(event: String) -> RESPCommand {
        RESPCommand("LATENCY", "HISTORY", event)
    }

    /// Returns the latest latency samples for all events.
    ///
    /// Version: 2.8.13
    /// Complexity: O(1)
    /// Categories: @admin, @slow, @dangerous
    @inlinable
    public func latencyLatest() async throws -> RESP3Token {
        let response = try await send(latencyLatestCommand())
        return response
    }

    @inlinable
    public func latencyLatestCommand() -> RESPCommand {
        RESPCommand("LATENCY", "LATEST")
    }

    /// Resets the latency data for one or more events.
    ///
    /// Version: 2.8.13
    /// Complexity: O(1)
    /// Categories: @admin, @slow, @dangerous
    @inlinable
    public func latencyReset(event: String...) async throws -> RESP3Token {
        let response = try await send(latencyResetCommand(event: event))
        return response
    }

    @inlinable
    public func latencyResetCommand(event: [String]) -> RESPCommand {
        RESPCommand("LATENCY", "RESET", event)
    }

    /// Finds the longest common substring.
    ///
    /// Version: 7.0.0
    /// Complexity: O(N*M) where N and M are the lengths of s1 and s2, respectively
    /// Categories: @read, @string, @slow
    @inlinable
    public func lcs(key1: RedisKey, key2: RedisKey, len: Bool, idx: Bool, minMatchLen: Int?, withmatchlen: Bool) async throws -> RESP3Token {
        let response = try await send(lcsCommand(key1: key1, key2: key2, len: len, idx: idx, minMatchLen: minMatchLen, withmatchlen: withmatchlen))
        return response
    }

    @inlinable
    public func lcsCommand(key1: RedisKey, key2: RedisKey, len: Bool, idx: Bool, minMatchLen: Int?, withmatchlen: Bool) -> RESPCommand {
        RESPCommand("LCS", key1, key2, RedisPureToken("LEN", len), RedisPureToken("IDX", idx), RESPWithToken("MINMATCHLEN", minMatchLen), RedisPureToken("WITHMATCHLEN", withmatchlen))
    }

    /// Returns an element from a list by its index.
    ///
    /// Version: 1.0.0
    /// Complexity: O(N) where N is the number of elements to traverse to get to the element at index. This makes asking for the first or the last element of the list O(1).
    /// Categories: @read, @list, @slow
    @inlinable
    public func lindex(key: RedisKey, index: Int) async throws -> RESP3Token {
        let response = try await send(lindexCommand(key: key, index: index))
        return response
    }

    @inlinable
    public func lindexCommand(key: RedisKey, index: Int) -> RESPCommand {
        RESPCommand("LINDEX", key, index)
    }

    public enum LINSERTWhere: RESPRepresentable {
        case before
        case after

        @inlinable
        public func writeToRESPBuffer(_ buffer: inout ByteBuffer) {
            switch self {
            case .before: "BEFORE".writeToRESPBuffer(&buffer)
            case .after: "AFTER".writeToRESPBuffer(&buffer)
            }
        }
    }
    /// Inserts an element before or after another element in a list.
    ///
    /// Version: 2.2.0
    /// Complexity: O(N) where N is the number of elements to traverse before seeing the value pivot. This means that inserting somewhere on the left end on the list (head) can be considered O(1) and inserting somewhere on the right end (tail) is O(N).
    /// Categories: @write, @list, @slow
    @inlinable
    public func linsert(key: RedisKey, where: LINSERTWhere, pivot: String, element: String) async throws -> RESP3Token {
        let response = try await send(linsertCommand(key: key, where: `where`, pivot: pivot, element: element))
        return response
    }

    @inlinable
    public func linsertCommand(key: RedisKey, where: LINSERTWhere, pivot: String, element: String) -> RESPCommand {
        RESPCommand("LINSERT", key, `where`, pivot, element)
    }

    /// Returns the length of a list.
    ///
    /// Version: 1.0.0
    /// Complexity: O(1)
    /// Categories: @read, @list, @fast
    @inlinable
    public func llen(key: RedisKey) async throws -> RESP3Token {
        let response = try await send(llenCommand(key: key))
        return response
    }

    @inlinable
    public func llenCommand(key: RedisKey) -> RESPCommand {
        RESPCommand("LLEN", key)
    }

    public enum LMOVEWherefrom: RESPRepresentable {
        case left
        case right

        @inlinable
        public func writeToRESPBuffer(_ buffer: inout ByteBuffer) {
            switch self {
            case .left: "LEFT".writeToRESPBuffer(&buffer)
            case .right: "RIGHT".writeToRESPBuffer(&buffer)
            }
        }
    }
    public enum LMOVEWhereto: RESPRepresentable {
        case left
        case right

        @inlinable
        public func writeToRESPBuffer(_ buffer: inout ByteBuffer) {
            switch self {
            case .left: "LEFT".writeToRESPBuffer(&buffer)
            case .right: "RIGHT".writeToRESPBuffer(&buffer)
            }
        }
    }
    /// Returns an element after popping it from one list and pushing it to another. Deletes the list if the last element was moved.
    ///
    /// Version: 6.2.0
    /// Complexity: O(1)
    /// Categories: @write, @list, @slow
    @inlinable
    public func lmove(source: RedisKey, destination: RedisKey, wherefrom: LMOVEWherefrom, whereto: LMOVEWhereto) async throws -> RESP3Token {
        let response = try await send(lmoveCommand(source: source, destination: destination, wherefrom: wherefrom, whereto: whereto))
        return response
    }

    @inlinable
    public func lmoveCommand(source: RedisKey, destination: RedisKey, wherefrom: LMOVEWherefrom, whereto: LMOVEWhereto) -> RESPCommand {
        RESPCommand("LMOVE", source, destination, wherefrom, whereto)
    }

    public enum LMPOPWhere: RESPRepresentable {
        case left
        case right

        @inlinable
        public func writeToRESPBuffer(_ buffer: inout ByteBuffer) {
            switch self {
            case .left: "LEFT".writeToRESPBuffer(&buffer)
            case .right: "RIGHT".writeToRESPBuffer(&buffer)
            }
        }
    }
    /// Returns multiple elements from a list after removing them. Deletes the list if the last element was popped.
    ///
    /// Version: 7.0.0
    /// Complexity: O(N+M) where N is the number of provided keys and M is the number of elements returned.
    /// Categories: @write, @list, @slow
    @inlinable
    public func lmpop(numkeys: Int, key: RedisKey..., where: LMPOPWhere, count: Int?) async throws -> RESP3Token {
        let response = try await send(lmpopCommand(numkeys: numkeys, key: key, where: `where`, count: count))
        return response
    }

    @inlinable
    public func lmpopCommand(numkeys: Int, key: [RedisKey], where: LMPOPWhere, count: Int?) -> RESPCommand {
        RESPCommand("LMPOP", numkeys, key, `where`, RESPWithToken("COUNT", count))
    }

    /// Displays computer art and the Redis version
    ///
    /// Version: 5.0.0
    /// Categories: @read, @fast
    @inlinable
    public func lolwut(version: Int?) async throws -> RESP3Token {
        let response = try await send(lolwutCommand(version: version))
        return response
    }

    @inlinable
    public func lolwutCommand(version: Int?) -> RESPCommand {
        RESPCommand("LOLWUT", RESPWithToken("VERSION", version))
    }

    /// Returns the first elements in a list after removing it. Deletes the list if the last element was popped.
    ///
    /// Version: 1.0.0
    /// Complexity: O(N) where N is the number of elements returned
    /// Categories: @write, @list, @fast
    @inlinable
    public func lpop(key: RedisKey, count: Int?) async throws -> RESP3Token {
        let response = try await send(lpopCommand(key: key, count: count))
        return response
    }

    @inlinable
    public func lpopCommand(key: RedisKey, count: Int?) -> RESPCommand {
        RESPCommand("LPOP", key, count)
    }

    /// Returns the index of matching elements in a list.
    ///
    /// Version: 6.0.6
    /// Complexity: O(N) where N is the number of elements in the list, for the average case. When searching for elements near the head or the tail of the list, or when the MAXLEN option is provided, the command may run in constant time.
    /// Categories: @read, @list, @slow
    @inlinable
    public func lpos(key: RedisKey, element: String, rank: Int?, numMatches: Int?, len: Int?) async throws -> RESP3Token {
        let response = try await send(lposCommand(key: key, element: element, rank: rank, numMatches: numMatches, len: len))
        return response
    }

    @inlinable
    public func lposCommand(key: RedisKey, element: String, rank: Int?, numMatches: Int?, len: Int?) -> RESPCommand {
        RESPCommand("LPOS", key, element, RESPWithToken("RANK", rank), RESPWithToken("COUNT", numMatches), RESPWithToken("MAXLEN", len))
    }

    /// Prepends one or more elements to a list. Creates the key if it doesn't exist.
    ///
    /// Version: 1.0.0
    /// Complexity: O(1) for each element added, so O(N) to add N elements when the command is called with multiple arguments.
    /// Categories: @write, @list, @fast
    @inlinable
    public func lpush(key: RedisKey, element: String...) async throws -> RESP3Token {
        let response = try await send(lpushCommand(key: key, element: element))
        return response
    }

    @inlinable
    public func lpushCommand(key: RedisKey, element: [String]) -> RESPCommand {
        RESPCommand("LPUSH", key, element)
    }

    /// Prepends one or more elements to a list only when the list exists.
    ///
    /// Version: 2.2.0
    /// Complexity: O(1) for each element added, so O(N) to add N elements when the command is called with multiple arguments.
    /// Categories: @write, @list, @fast
    @inlinable
    public func lpushx(key: RedisKey, element: String...) async throws -> RESP3Token {
        let response = try await send(lpushxCommand(key: key, element: element))
        return response
    }

    @inlinable
    public func lpushxCommand(key: RedisKey, element: [String]) -> RESPCommand {
        RESPCommand("LPUSHX", key, element)
    }

    /// Returns a range of elements from a list.
    ///
    /// Version: 1.0.0
    /// Complexity: O(S+N) where S is the distance of start offset from HEAD for small lists, from nearest end (HEAD or TAIL) for large lists; and N is the number of elements in the specified range.
    /// Categories: @read, @list, @slow
    @inlinable
    public func lrange(key: RedisKey, start: Int, stop: Int) async throws -> RESP3Token {
        let response = try await send(lrangeCommand(key: key, start: start, stop: stop))
        return response
    }

    @inlinable
    public func lrangeCommand(key: RedisKey, start: Int, stop: Int) -> RESPCommand {
        RESPCommand("LRANGE", key, start, stop)
    }

    /// Removes elements from a list. Deletes the list if the last element was removed.
    ///
    /// Version: 1.0.0
    /// Complexity: O(N+M) where N is the length of the list and M is the number of elements removed.
    /// Categories: @write, @list, @slow
    @inlinable
    public func lrem(key: RedisKey, count: Int, element: String) async throws -> RESP3Token {
        let response = try await send(lremCommand(key: key, count: count, element: element))
        return response
    }

    @inlinable
    public func lremCommand(key: RedisKey, count: Int, element: String) -> RESPCommand {
        RESPCommand("LREM", key, count, element)
    }

    /// Sets the value of an element in a list by its index.
    ///
    /// Version: 1.0.0
    /// Complexity: O(N) where N is the length of the list. Setting either the first or the last element of the list is O(1).
    /// Categories: @write, @list, @slow
    @inlinable
    public func lset(key: RedisKey, index: Int, element: String) async throws -> RESP3Token {
        let response = try await send(lsetCommand(key: key, index: index, element: element))
        return response
    }

    @inlinable
    public func lsetCommand(key: RedisKey, index: Int, element: String) -> RESPCommand {
        RESPCommand("LSET", key, index, element)
    }

    /// Removes elements from both ends a list. Deletes the list if all elements were trimmed.
    ///
    /// Version: 1.0.0
    /// Complexity: O(N) where N is the number of elements to be removed by the operation.
    /// Categories: @write, @list, @slow
    @inlinable
    public func ltrim(key: RedisKey, start: Int, stop: Int) async throws -> RESP3Token {
        let response = try await send(ltrimCommand(key: key, start: start, stop: stop))
        return response
    }

    @inlinable
    public func ltrimCommand(key: RedisKey, start: Int, stop: Int) -> RESPCommand {
        RESPCommand("LTRIM", key, start, stop)
    }

    /// A container for memory diagnostics commands.
    ///
    /// Version: 4.0.0
    /// Complexity: Depends on subcommand.
    /// Categories: @slow
    @inlinable
    public func memory() async throws -> RESP3Token {
        let response = try await send(memoryCommand())
        return response
    }

    @inlinable
    public func memoryCommand() -> RESPCommand {
        RESPCommand("MEMORY")
    }

    /// Outputs a memory problems report.
    ///
    /// Version: 4.0.0
    /// Complexity: O(1)
    /// Categories: @slow
    @inlinable
    public func memoryDoctor() async throws -> RESP3Token {
        let response = try await send(memoryDoctorCommand())
        return response
    }

    @inlinable
    public func memoryDoctorCommand() -> RESPCommand {
        RESPCommand("MEMORY", "DOCTOR")
    }

    /// Returns helpful text about the different subcommands.
    ///
    /// Version: 4.0.0
    /// Complexity: O(1)
    /// Categories: @slow
    @inlinable
    public func memoryHelp() async throws -> RESP3Token {
        let response = try await send(memoryHelpCommand())
        return response
    }

    @inlinable
    public func memoryHelpCommand() -> RESPCommand {
        RESPCommand("MEMORY", "HELP")
    }

    /// Returns the allocator statistics.
    ///
    /// Version: 4.0.0
    /// Complexity: Depends on how much memory is allocated, could be slow
    /// Categories: @slow
    @inlinable
    public func memoryMallocStats() async throws -> RESP3Token {
        let response = try await send(memoryMallocStatsCommand())
        return response
    }

    @inlinable
    public func memoryMallocStatsCommand() -> RESPCommand {
        RESPCommand("MEMORY", "MALLOC-STATS")
    }

    /// Asks the allocator to release memory.
    ///
    /// Version: 4.0.0
    /// Complexity: Depends on how much memory is allocated, could be slow
    /// Categories: @slow
    @inlinable
    public func memoryPurge() async throws -> RESP3Token {
        let response = try await send(memoryPurgeCommand())
        return response
    }

    @inlinable
    public func memoryPurgeCommand() -> RESPCommand {
        RESPCommand("MEMORY", "PURGE")
    }

    /// Returns details about memory usage.
    ///
    /// Version: 4.0.0
    /// Complexity: O(1)
    /// Categories: @slow
    @inlinable
    public func memoryStats() async throws -> RESP3Token {
        let response = try await send(memoryStatsCommand())
        return response
    }

    @inlinable
    public func memoryStatsCommand() -> RESPCommand {
        RESPCommand("MEMORY", "STATS")
    }

    /// Estimates the memory usage of a key.
    ///
    /// Version: 4.0.0
    /// Complexity: O(N) where N is the number of samples.
    /// Categories: @read, @slow
    @inlinable
    public func memoryUsage(key: RedisKey, count: Int?) async throws -> RESP3Token {
        let response = try await send(memoryUsageCommand(key: key, count: count))
        return response
    }

    @inlinable
    public func memoryUsageCommand(key: RedisKey, count: Int?) -> RESPCommand {
        RESPCommand("MEMORY", "USAGE", key, RESPWithToken("SAMPLES", count))
    }

    /// Atomically returns the string values of one or more keys.
    ///
    /// Version: 1.0.0
    /// Complexity: O(N) where N is the number of keys to retrieve.
    /// Categories: @read, @string, @fast
    @inlinable
    public func mget(key: RedisKey...) async throws -> RESP3Token {
        let response = try await send(mgetCommand(key: key))
        return response
    }

    @inlinable
    public func mgetCommand(key: [RedisKey]) -> RESPCommand {
        RESPCommand("MGET", key)
    }

    public enum MIGRATEKeySelector: RESPRepresentable {
        case key(RedisKey)
        case emptyString

        @inlinable
        public func writeToRESPBuffer(_ buffer: inout ByteBuffer) {
            switch self {
            case .key(let key): key.writeToRESPBuffer(&buffer)
            case .emptyString: "".writeToRESPBuffer(&buffer)
            }
        }
    }
    public struct MIGRATEAuthenticationAuth2: RESPRepresentable {
        @usableFromInline let username: String
        @usableFromInline let password: String

        @inlinable
        public func writeToRESPBuffer(_ buffer: inout ByteBuffer) {
            self.username.writeToRESPBuffer(&buffer)
            self.password.writeToRESPBuffer(&buffer)
        }
    }
    public enum MIGRATEAuthentication: RESPRepresentable {
        case auth(String)
        case auth2(MIGRATEAuthenticationAuth2)

        @inlinable
        public func writeToRESPBuffer(_ buffer: inout ByteBuffer) {
            switch self {
            case .auth(let auth): RESPWithToken("AUTH", auth).writeToRESPBuffer(&buffer)
            case .auth2(let auth2): RESPWithToken("AUTH2", auth2).writeToRESPBuffer(&buffer)
            }
        }
    }
    /// Atomically transfers a key from one Redis instance to another.
    ///
    /// Version: 2.6.0
    /// Complexity: This command actually executes a DUMP+DEL in the source instance, and a RESTORE in the target instance. See the pages of these commands for time complexity. Also an O(N) data transfer between the two instances is performed.
    /// Categories: @keyspace, @write, @slow, @dangerous
    @inlinable
    public func migrate(host: String, port: Int, keySelector: MIGRATEKeySelector, destinationDb: Int, timeout: Int, copy: Bool, replace: Bool, authentication: MIGRATEAuthentication?, keys: RedisKey...) async throws -> RESP3Token {
        let response = try await send(migrateCommand(host: host, port: port, keySelector: keySelector, destinationDb: destinationDb, timeout: timeout, copy: copy, replace: replace, authentication: authentication, keys: keys))
        return response
    }

    @inlinable
    public func migrateCommand(host: String, port: Int, keySelector: MIGRATEKeySelector, destinationDb: Int, timeout: Int, copy: Bool, replace: Bool, authentication: MIGRATEAuthentication?, keys: [RedisKey]) -> RESPCommand {
        RESPCommand("MIGRATE", host, port, keySelector, destinationDb, timeout, RedisPureToken("COPY", copy), RedisPureToken("REPLACE", replace), authentication, RESPWithToken("KEYS", keys))
    }

    /// A container for module commands.
    ///
    /// Version: 4.0.0
    /// Complexity: Depends on subcommand.
    /// Categories: @slow
    @inlinable
    public func module() async throws -> RESP3Token {
        let response = try await send(moduleCommand())
        return response
    }

    @inlinable
    public func moduleCommand() -> RESPCommand {
        RESPCommand("MODULE")
    }

    /// Returns helpful text about the different subcommands.
    ///
    /// Version: 5.0.0
    /// Complexity: O(1)
    /// Categories: @slow
    @inlinable
    public func moduleHelp() async throws -> RESP3Token {
        let response = try await send(moduleHelpCommand())
        return response
    }

    @inlinable
    public func moduleHelpCommand() -> RESPCommand {
        RESPCommand("MODULE", "HELP")
    }

    /// Returns all loaded modules.
    ///
    /// Version: 4.0.0
    /// Complexity: O(N) where N is the number of loaded modules.
    /// Categories: @admin, @slow, @dangerous
    @inlinable
    public func moduleList() async throws -> RESP3Token {
        let response = try await send(moduleListCommand())
        return response
    }

    @inlinable
    public func moduleListCommand() -> RESPCommand {
        RESPCommand("MODULE", "LIST")
    }

    /// Loads a module.
    ///
    /// Version: 4.0.0
    /// Complexity: O(1)
    /// Categories: @admin, @slow, @dangerous
    @inlinable
    public func moduleLoad(path: String, arg: String...) async throws -> RESP3Token {
        let response = try await send(moduleLoadCommand(path: path, arg: arg))
        return response
    }

    @inlinable
    public func moduleLoadCommand(path: String, arg: [String]) -> RESPCommand {
        RESPCommand("MODULE", "LOAD", path, arg)
    }

    public struct MODULELOADEXConfigs: RESPRepresentable {
        @usableFromInline let name: String
        @usableFromInline let value: String

        @inlinable
        public func writeToRESPBuffer(_ buffer: inout ByteBuffer) {
            self.name.writeToRESPBuffer(&buffer)
            self.value.writeToRESPBuffer(&buffer)
        }
    }
    /// Loads a module using extended parameters.
    ///
    /// Version: 7.0.0
    /// Complexity: O(1)
    /// Categories: @admin, @slow, @dangerous
    @inlinable
    public func moduleLoadex(path: String, configs: MODULELOADEXConfigs..., args: String...) async throws -> RESP3Token {
        let response = try await send(moduleLoadexCommand(path: path, configs: configs, args: args))
        return response
    }

    @inlinable
    public func moduleLoadexCommand(path: String, configs: [MODULELOADEXConfigs], args: [String]) -> RESPCommand {
        RESPCommand("MODULE", "LOADEX", path, RESPWithToken("CONFIG", configs), RESPWithToken("ARGS", args))
    }

    /// Unloads a module.
    ///
    /// Version: 4.0.0
    /// Complexity: O(1)
    /// Categories: @admin, @slow, @dangerous
    @inlinable
    public func moduleUnload(name: String) async throws -> RESP3Token {
        let response = try await send(moduleUnloadCommand(name: name))
        return response
    }

    @inlinable
    public func moduleUnloadCommand(name: String) -> RESPCommand {
        RESPCommand("MODULE", "UNLOAD", name)
    }

    /// Listens for all requests received by the server in real-time.
    ///
    /// Version: 1.0.0
    /// Categories: @admin, @slow, @dangerous
    @inlinable
    public func monitor() async throws -> RESP3Token {
        let response = try await send(monitorCommand())
        return response
    }

    @inlinable
    public func monitorCommand() -> RESPCommand {
        RESPCommand("MONITOR")
    }

    /// Moves a key to another database.
    ///
    /// Version: 1.0.0
    /// Complexity: O(1)
    /// Categories: @keyspace, @write, @fast
    @inlinable
    public func move(key: RedisKey, db: Int) async throws -> RESP3Token {
        let response = try await send(moveCommand(key: key, db: db))
        return response
    }

    @inlinable
    public func moveCommand(key: RedisKey, db: Int) -> RESPCommand {
        RESPCommand("MOVE", key, db)
    }

    public struct MSETData: RESPRepresentable {
        @usableFromInline let key: RedisKey
        @usableFromInline let value: String

        @inlinable
        public func writeToRESPBuffer(_ buffer: inout ByteBuffer) {
            self.key.writeToRESPBuffer(&buffer)
            self.value.writeToRESPBuffer(&buffer)
        }
    }
    /// Atomically creates or modifies the string values of one or more keys.
    ///
    /// Version: 1.0.1
    /// Complexity: O(N) where N is the number of keys to set.
    /// Categories: @write, @string, @slow
    @inlinable
    public func mset(data: MSETData...) async throws -> RESP3Token {
        let response = try await send(msetCommand(data: data))
        return response
    }

    @inlinable
    public func msetCommand(data: [MSETData]) -> RESPCommand {
        RESPCommand("MSET", data)
    }

    public struct MSETNXData: RESPRepresentable {
        @usableFromInline let key: RedisKey
        @usableFromInline let value: String

        @inlinable
        public func writeToRESPBuffer(_ buffer: inout ByteBuffer) {
            self.key.writeToRESPBuffer(&buffer)
            self.value.writeToRESPBuffer(&buffer)
        }
    }
    /// Atomically modifies the string values of one or more keys only when all keys don't exist.
    ///
    /// Version: 1.0.1
    /// Complexity: O(N) where N is the number of keys to set.
    /// Categories: @write, @string, @slow
    @inlinable
    public func msetnx(data: MSETNXData...) async throws -> RESP3Token {
        let response = try await send(msetnxCommand(data: data))
        return response
    }

    @inlinable
    public func msetnxCommand(data: [MSETNXData]) -> RESPCommand {
        RESPCommand("MSETNX", data)
    }

    /// Starts a transaction.
    ///
    /// Version: 1.2.0
    /// Complexity: O(1)
    /// Categories: @fast, @transaction
    @inlinable
    public func multi() async throws -> RESP3Token {
        let response = try await send(multiCommand())
        return response
    }

    @inlinable
    public func multiCommand() -> RESPCommand {
        RESPCommand("MULTI")
    }

    /// A container for object introspection commands.
    ///
    /// Version: 2.2.3
    /// Complexity: Depends on subcommand.
    /// Categories: @slow
    @inlinable
    public func object() async throws -> RESP3Token {
        let response = try await send(objectCommand())
        return response
    }

    @inlinable
    public func objectCommand() -> RESPCommand {
        RESPCommand("OBJECT")
    }

    /// Returns the internal encoding of a Redis object.
    ///
    /// Version: 2.2.3
    /// Complexity: O(1)
    /// Categories: @keyspace, @read, @slow
    @inlinable
    public func objectEncoding(key: RedisKey) async throws -> RESP3Token {
        let response = try await send(objectEncodingCommand(key: key))
        return response
    }

    @inlinable
    public func objectEncodingCommand(key: RedisKey) -> RESPCommand {
        RESPCommand("OBJECT", "ENCODING", key)
    }

    /// Returns the logarithmic access frequency counter of a Redis object.
    ///
    /// Version: 4.0.0
    /// Complexity: O(1)
    /// Categories: @keyspace, @read, @slow
    @inlinable
    public func objectFreq(key: RedisKey) async throws -> RESP3Token {
        let response = try await send(objectFreqCommand(key: key))
        return response
    }

    @inlinable
    public func objectFreqCommand(key: RedisKey) -> RESPCommand {
        RESPCommand("OBJECT", "FREQ", key)
    }

    /// Returns helpful text about the different subcommands.
    ///
    /// Version: 6.2.0
    /// Complexity: O(1)
    /// Categories: @keyspace, @slow
    @inlinable
    public func objectHelp() async throws -> RESP3Token {
        let response = try await send(objectHelpCommand())
        return response
    }

    @inlinable
    public func objectHelpCommand() -> RESPCommand {
        RESPCommand("OBJECT", "HELP")
    }

    /// Returns the time since the last access to a Redis object.
    ///
    /// Version: 2.2.3
    /// Complexity: O(1)
    /// Categories: @keyspace, @read, @slow
    @inlinable
    public func objectIdletime(key: RedisKey) async throws -> RESP3Token {
        let response = try await send(objectIdletimeCommand(key: key))
        return response
    }

    @inlinable
    public func objectIdletimeCommand(key: RedisKey) -> RESPCommand {
        RESPCommand("OBJECT", "IDLETIME", key)
    }

    /// Returns the reference count of a value of a key.
    ///
    /// Version: 2.2.3
    /// Complexity: O(1)
    /// Categories: @keyspace, @read, @slow
    @inlinable
    public func objectRefcount(key: RedisKey) async throws -> RESP3Token {
        let response = try await send(objectRefcountCommand(key: key))
        return response
    }

    @inlinable
    public func objectRefcountCommand(key: RedisKey) -> RESPCommand {
        RESPCommand("OBJECT", "REFCOUNT", key)
    }

    /// Removes the expiration time of a key.
    ///
    /// Version: 2.2.0
    /// Complexity: O(1)
    /// Categories: @keyspace, @write, @fast
    @inlinable
    public func persist(key: RedisKey) async throws -> RESP3Token {
        let response = try await send(persistCommand(key: key))
        return response
    }

    @inlinable
    public func persistCommand(key: RedisKey) -> RESPCommand {
        RESPCommand("PERSIST", key)
    }

    public enum PEXPIRECondition: RESPRepresentable {
        case nx
        case xx
        case gt
        case lt

        @inlinable
        public func writeToRESPBuffer(_ buffer: inout ByteBuffer) {
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
    /// Version: 2.6.0
    /// Complexity: O(1)
    /// Categories: @keyspace, @write, @fast
    @inlinable
    public func pexpire(key: RedisKey, milliseconds: Int, condition: PEXPIRECondition?) async throws -> RESP3Token {
        let response = try await send(pexpireCommand(key: key, milliseconds: milliseconds, condition: condition))
        return response
    }

    @inlinable
    public func pexpireCommand(key: RedisKey, milliseconds: Int, condition: PEXPIRECondition?) -> RESPCommand {
        RESPCommand("PEXPIRE", key, milliseconds, condition)
    }

    public enum PEXPIREATCondition: RESPRepresentable {
        case nx
        case xx
        case gt
        case lt

        @inlinable
        public func writeToRESPBuffer(_ buffer: inout ByteBuffer) {
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
    /// Version: 2.6.0
    /// Complexity: O(1)
    /// Categories: @keyspace, @write, @fast
    @inlinable
    public func pexpireat(key: RedisKey, unixTimeMilliseconds: Date, condition: PEXPIREATCondition?) async throws -> RESP3Token {
        let response = try await send(pexpireatCommand(key: key, unixTimeMilliseconds: unixTimeMilliseconds, condition: condition))
        return response
    }

    @inlinable
    public func pexpireatCommand(key: RedisKey, unixTimeMilliseconds: Date, condition: PEXPIREATCondition?) -> RESPCommand {
        RESPCommand("PEXPIREAT", key, unixTimeMilliseconds, condition)
    }

    /// Returns the expiration time of a key as a Unix milliseconds timestamp.
    ///
    /// Version: 7.0.0
    /// Complexity: O(1)
    /// Categories: @keyspace, @read, @fast
    @inlinable
    public func pexpiretime(key: RedisKey) async throws -> RESP3Token {
        let response = try await send(pexpiretimeCommand(key: key))
        return response
    }

    @inlinable
    public func pexpiretimeCommand(key: RedisKey) -> RESPCommand {
        RESPCommand("PEXPIRETIME", key)
    }

    /// Adds elements to a HyperLogLog key. Creates the key if it doesn't exist.
    ///
    /// Version: 2.8.9
    /// Complexity: O(1) to add every element.
    /// Categories: @write, @hyperloglog, @fast
    @inlinable
    public func pfadd(key: RedisKey, element: String...) async throws -> RESP3Token {
        let response = try await send(pfaddCommand(key: key, element: element))
        return response
    }

    @inlinable
    public func pfaddCommand(key: RedisKey, element: [String]) -> RESPCommand {
        RESPCommand("PFADD", key, element)
    }

    /// Returns the approximated cardinality of the set(s) observed by the HyperLogLog key(s).
    ///
    /// Version: 2.8.9
    /// Complexity: O(1) with a very small average constant time when called with a single key. O(N) with N being the number of keys, and much bigger constant times, when called with multiple keys.
    /// Categories: @read, @hyperloglog, @slow
    @inlinable
    public func pfcount(key: RedisKey...) async throws -> RESP3Token {
        let response = try await send(pfcountCommand(key: key))
        return response
    }

    @inlinable
    public func pfcountCommand(key: [RedisKey]) -> RESPCommand {
        RESPCommand("PFCOUNT", key)
    }

    /// Internal commands for debugging HyperLogLog values.
    ///
    /// Version: 2.8.9
    /// Complexity: N/A
    /// Categories: @write, @hyperloglog, @admin, @slow, @dangerous
    @inlinable
    public func pfdebug(subcommand: String, key: RedisKey) async throws -> RESP3Token {
        let response = try await send(pfdebugCommand(subcommand: subcommand, key: key))
        return response
    }

    @inlinable
    public func pfdebugCommand(subcommand: String, key: RedisKey) -> RESPCommand {
        RESPCommand("PFDEBUG", subcommand, key)
    }

    /// Merges one or more HyperLogLog values into a single key.
    ///
    /// Version: 2.8.9
    /// Complexity: O(N) to merge N HyperLogLogs, but with high constant times.
    /// Categories: @write, @hyperloglog, @slow
    @inlinable
    public func pfmerge(destkey: RedisKey, sourcekey: RedisKey...) async throws -> RESP3Token {
        let response = try await send(pfmergeCommand(destkey: destkey, sourcekey: sourcekey))
        return response
    }

    @inlinable
    public func pfmergeCommand(destkey: RedisKey, sourcekey: [RedisKey]) -> RESPCommand {
        RESPCommand("PFMERGE", destkey, sourcekey)
    }

    /// An internal command for testing HyperLogLog values.
    ///
    /// Version: 2.8.9
    /// Complexity: N/A
    /// Categories: @hyperloglog, @admin, @slow, @dangerous
    @inlinable
    public func pfselftest() async throws -> RESP3Token {
        let response = try await send(pfselftestCommand())
        return response
    }

    @inlinable
    public func pfselftestCommand() -> RESPCommand {
        RESPCommand("PFSELFTEST")
    }

    /// Returns the server's liveliness response.
    ///
    /// Version: 1.0.0
    /// Complexity: O(1)
    /// Categories: @fast, @connection
    @inlinable
    public func ping(message: String?) async throws -> RESP3Token {
        let response = try await send(pingCommand(message: message))
        return response
    }

    @inlinable
    public func pingCommand(message: String?) -> RESPCommand {
        RESPCommand("PING", message)
    }

    /// Sets both string value and expiration time in milliseconds of a key. The key is created if it doesn't exist.
    ///
    /// Version: 2.6.0
    /// Complexity: O(1)
    /// Categories: @write, @string, @slow
    @inlinable
    public func psetex(key: RedisKey, milliseconds: Int, value: String) async throws -> RESP3Token {
        let response = try await send(psetexCommand(key: key, milliseconds: milliseconds, value: value))
        return response
    }

    @inlinable
    public func psetexCommand(key: RedisKey, milliseconds: Int, value: String) -> RESPCommand {
        RESPCommand("PSETEX", key, milliseconds, value)
    }

    /// Listens for messages published to channels that match one or more patterns.
    ///
    /// Version: 2.0.0
    /// Complexity: O(N) where N is the number of patterns to subscribe to.
    /// Categories: @pubsub, @slow
    @inlinable
    public func psubscribe(pattern: String...) async throws -> RESP3Token {
        let response = try await send(psubscribeCommand(pattern: pattern))
        return response
    }

    @inlinable
    public func psubscribeCommand(pattern: [String]) -> RESPCommand {
        RESPCommand("PSUBSCRIBE", pattern)
    }

    /// An internal command used in replication.
    ///
    /// Version: 2.8.0
    /// Categories: @admin, @slow, @dangerous
    @inlinable
    public func psync(replicationid: String, offset: Int) async throws -> RESP3Token {
        let response = try await send(psyncCommand(replicationid: replicationid, offset: offset))
        return response
    }

    @inlinable
    public func psyncCommand(replicationid: String, offset: Int) -> RESPCommand {
        RESPCommand("PSYNC", replicationid, offset)
    }

    /// Returns the expiration time in milliseconds of a key.
    ///
    /// Version: 2.6.0
    /// Complexity: O(1)
    /// Categories: @keyspace, @read, @fast
    @inlinable
    public func pttl(key: RedisKey) async throws -> RESP3Token {
        let response = try await send(pttlCommand(key: key))
        return response
    }

    @inlinable
    public func pttlCommand(key: RedisKey) -> RESPCommand {
        RESPCommand("PTTL", key)
    }

    /// Posts a message to a channel.
    ///
    /// Version: 2.0.0
    /// Complexity: O(N+M) where N is the number of clients subscribed to the receiving channel and M is the total number of subscribed patterns (by any client).
    /// Categories: @pubsub, @fast
    @inlinable
    public func publish(channel: String, message: String) async throws -> RESP3Token {
        let response = try await send(publishCommand(channel: channel, message: message))
        return response
    }

    @inlinable
    public func publishCommand(channel: String, message: String) -> RESPCommand {
        RESPCommand("PUBLISH", channel, message)
    }

    /// A container for Pub/Sub commands.
    ///
    /// Version: 2.8.0
    /// Complexity: Depends on subcommand.
    /// Categories: @slow
    @inlinable
    public func pubsub() async throws -> RESP3Token {
        let response = try await send(pubsubCommand())
        return response
    }

    @inlinable
    public func pubsubCommand() -> RESPCommand {
        RESPCommand("PUBSUB")
    }

    /// Returns the active channels.
    ///
    /// Version: 2.8.0
    /// Complexity: O(N) where N is the number of active channels, and assuming constant time pattern matching (relatively short channels and patterns)
    /// Categories: @pubsub, @slow
    @inlinable
    public func pubsubChannels(pattern: String?) async throws -> RESP3Token {
        let response = try await send(pubsubChannelsCommand(pattern: pattern))
        return response
    }

    @inlinable
    public func pubsubChannelsCommand(pattern: String?) -> RESPCommand {
        RESPCommand("PUBSUB", "CHANNELS", pattern)
    }

    /// Returns helpful text about the different subcommands.
    ///
    /// Version: 6.2.0
    /// Complexity: O(1)
    /// Categories: @slow
    @inlinable
    public func pubsubHelp() async throws -> RESP3Token {
        let response = try await send(pubsubHelpCommand())
        return response
    }

    @inlinable
    public func pubsubHelpCommand() -> RESPCommand {
        RESPCommand("PUBSUB", "HELP")
    }

    /// Returns a count of unique pattern subscriptions.
    ///
    /// Version: 2.8.0
    /// Complexity: O(1)
    /// Categories: @pubsub, @slow
    @inlinable
    public func pubsubNumpat() async throws -> RESP3Token {
        let response = try await send(pubsubNumpatCommand())
        return response
    }

    @inlinable
    public func pubsubNumpatCommand() -> RESPCommand {
        RESPCommand("PUBSUB", "NUMPAT")
    }

    /// Returns a count of subscribers to channels.
    ///
    /// Version: 2.8.0
    /// Complexity: O(N) for the NUMSUB subcommand, where N is the number of requested channels
    /// Categories: @pubsub, @slow
    @inlinable
    public func pubsubNumsub(channel: String...) async throws -> RESP3Token {
        let response = try await send(pubsubNumsubCommand(channel: channel))
        return response
    }

    @inlinable
    public func pubsubNumsubCommand(channel: [String]) -> RESPCommand {
        RESPCommand("PUBSUB", "NUMSUB", channel)
    }

    /// Returns the active shard channels.
    ///
    /// Version: 7.0.0
    /// Complexity: O(N) where N is the number of active shard channels, and assuming constant time pattern matching (relatively short shard channels).
    /// Categories: @pubsub, @slow
    @inlinable
    public func pubsubShardchannels(pattern: String?) async throws -> RESP3Token {
        let response = try await send(pubsubShardchannelsCommand(pattern: pattern))
        return response
    }

    @inlinable
    public func pubsubShardchannelsCommand(pattern: String?) -> RESPCommand {
        RESPCommand("PUBSUB", "SHARDCHANNELS", pattern)
    }

    /// Returns the count of subscribers of shard channels.
    ///
    /// Version: 7.0.0
    /// Complexity: O(N) for the SHARDNUMSUB subcommand, where N is the number of requested shard channels
    /// Categories: @pubsub, @slow
    @inlinable
    public func pubsubShardnumsub(shardchannel: String...) async throws -> RESP3Token {
        let response = try await send(pubsubShardnumsubCommand(shardchannel: shardchannel))
        return response
    }

    @inlinable
    public func pubsubShardnumsubCommand(shardchannel: [String]) -> RESPCommand {
        RESPCommand("PUBSUB", "SHARDNUMSUB", shardchannel)
    }

    /// Stops listening to messages published to channels that match one or more patterns.
    ///
    /// Version: 2.0.0
    /// Complexity: O(N) where N is the number of patterns to unsubscribe.
    /// Categories: @pubsub, @slow
    @inlinable
    public func punsubscribe(pattern: String...) async throws -> RESP3Token {
        let response = try await send(punsubscribeCommand(pattern: pattern))
        return response
    }

    @inlinable
    public func punsubscribeCommand(pattern: [String]) -> RESPCommand {
        RESPCommand("PUNSUBSCRIBE", pattern)
    }

    /// Closes the connection.
    ///
    /// Version: 1.0.0
    /// Complexity: O(1)
    /// Categories: @fast, @connection
    @inlinable
    public func quit() async throws -> RESP3Token {
        let response = try await send(quitCommand())
        return response
    }

    @inlinable
    public func quitCommand() -> RESPCommand {
        RESPCommand("QUIT")
    }

    /// Returns a random key name from the database.
    ///
    /// Version: 1.0.0
    /// Complexity: O(1)
    /// Categories: @keyspace, @read, @slow
    @inlinable
    public func randomkey() async throws -> RESP3Token {
        let response = try await send(randomkeyCommand())
        return response
    }

    @inlinable
    public func randomkeyCommand() -> RESPCommand {
        RESPCommand("RANDOMKEY")
    }

    /// Enables read-only queries for a connection to a Redis Cluster replica node.
    ///
    /// Version: 3.0.0
    /// Complexity: O(1)
    /// Categories: @fast, @connection
    @inlinable
    public func readonly() async throws -> RESP3Token {
        let response = try await send(readonlyCommand())
        return response
    }

    @inlinable
    public func readonlyCommand() -> RESPCommand {
        RESPCommand("READONLY")
    }

    /// Enables read-write queries for a connection to a Reids Cluster replica node.
    ///
    /// Version: 3.0.0
    /// Complexity: O(1)
    /// Categories: @fast, @connection
    @inlinable
    public func readwrite() async throws -> RESP3Token {
        let response = try await send(readwriteCommand())
        return response
    }

    @inlinable
    public func readwriteCommand() -> RESPCommand {
        RESPCommand("READWRITE")
    }

    /// Renames a key and overwrites the destination.
    ///
    /// Version: 1.0.0
    /// Complexity: O(1)
    /// Categories: @keyspace, @write, @slow
    @inlinable
    public func rename(key: RedisKey, newkey: RedisKey) async throws -> RESP3Token {
        let response = try await send(renameCommand(key: key, newkey: newkey))
        return response
    }

    @inlinable
    public func renameCommand(key: RedisKey, newkey: RedisKey) -> RESPCommand {
        RESPCommand("RENAME", key, newkey)
    }

    /// Renames a key only when the target key name doesn't exist.
    ///
    /// Version: 1.0.0
    /// Complexity: O(1)
    /// Categories: @keyspace, @write, @fast
    @inlinable
    public func renamenx(key: RedisKey, newkey: RedisKey) async throws -> RESP3Token {
        let response = try await send(renamenxCommand(key: key, newkey: newkey))
        return response
    }

    @inlinable
    public func renamenxCommand(key: RedisKey, newkey: RedisKey) -> RESPCommand {
        RESPCommand("RENAMENX", key, newkey)
    }

    /// An internal command for configuring the replication stream.
    ///
    /// Version: 3.0.0
    /// Complexity: O(1)
    /// Categories: @admin, @slow, @dangerous
    @inlinable
    public func replconf() async throws -> RESP3Token {
        let response = try await send(replconfCommand())
        return response
    }

    @inlinable
    public func replconfCommand() -> RESPCommand {
        RESPCommand("REPLCONF")
    }

    public struct REPLICAOFArgsHostPort: RESPRepresentable {
        @usableFromInline let host: String
        @usableFromInline let port: Int

        @inlinable
        public func writeToRESPBuffer(_ buffer: inout ByteBuffer) {
            self.host.writeToRESPBuffer(&buffer)
            self.port.writeToRESPBuffer(&buffer)
        }
    }
    public struct REPLICAOFArgsNoOne: RESPRepresentable {
        @usableFromInline let no: Bool
        @usableFromInline let one: Bool

        @inlinable
        public func writeToRESPBuffer(_ buffer: inout ByteBuffer) {
            if self.no { "NO".writeToRESPBuffer(&buffer) }
            if self.one { "ONE".writeToRESPBuffer(&buffer) }
        }
    }
    public enum REPLICAOFArgs: RESPRepresentable {
        case hostPort(REPLICAOFArgsHostPort)
        case noOne(REPLICAOFArgsNoOne)

        @inlinable
        public func writeToRESPBuffer(_ buffer: inout ByteBuffer) {
            switch self {
            case .hostPort(let hostPort): hostPort.writeToRESPBuffer(&buffer)
            case .noOne(let noOne): noOne.writeToRESPBuffer(&buffer)
            }
        }
    }
    /// Configures a server as replica of another, or promotes it to a master.
    ///
    /// Version: 5.0.0
    /// Complexity: O(1)
    /// Categories: @admin, @slow, @dangerous
    @inlinable
    public func replicaof(args: REPLICAOFArgs) async throws -> RESP3Token {
        let response = try await send(replicaofCommand(args: args))
        return response
    }

    @inlinable
    public func replicaofCommand(args: REPLICAOFArgs) -> RESPCommand {
        RESPCommand("REPLICAOF", args)
    }

    /// Resets the connection.
    ///
    /// Version: 6.2.0
    /// Complexity: O(1)
    /// Categories: @fast, @connection
    @inlinable
    public func reset() async throws -> RESP3Token {
        let response = try await send(resetCommand())
        return response
    }

    @inlinable
    public func resetCommand() -> RESPCommand {
        RESPCommand("RESET")
    }

    /// Creates a key from the serialized representation of a value.
    ///
    /// Version: 2.6.0
    /// Complexity: O(1) to create the new key and additional O(N*M) to reconstruct the serialized value, where N is the number of Redis objects composing the value and M their average size. For small string values the time complexity is thus O(1)+O(1*M) where M is small, so simply O(1). However for sorted set values the complexity is O(N*M*log(N)) because inserting values into sorted sets is O(log(N)).
    /// Categories: @keyspace, @write, @slow, @dangerous
    @inlinable
    public func restore(key: RedisKey, ttl: Int, serializedValue: String, replace: Bool, absttl: Bool, seconds: Int?, frequency: Int?) async throws -> RESP3Token {
        let response = try await send(restoreCommand(key: key, ttl: ttl, serializedValue: serializedValue, replace: replace, absttl: absttl, seconds: seconds, frequency: frequency))
        return response
    }

    @inlinable
    public func restoreCommand(key: RedisKey, ttl: Int, serializedValue: String, replace: Bool, absttl: Bool, seconds: Int?, frequency: Int?) -> RESPCommand {
        RESPCommand("RESTORE", key, ttl, serializedValue, RedisPureToken("REPLACE", replace), RedisPureToken("ABSTTL", absttl), RESPWithToken("IDLETIME", seconds), RESPWithToken("FREQ", frequency))
    }

    /// An internal command for migrating keys in a cluster.
    ///
    /// Version: 3.0.0
    /// Complexity: O(1) to create the new key and additional O(N*M) to reconstruct the serialized value, where N is the number of Redis objects composing the value and M their average size. For small string values the time complexity is thus O(1)+O(1*M) where M is small, so simply O(1). However for sorted set values the complexity is O(N*M*log(N)) because inserting values into sorted sets is O(log(N)).
    /// Categories: @keyspace, @write, @slow, @dangerous
    @inlinable
    public func restoreAsking(key: RedisKey, ttl: Int, serializedValue: String, replace: Bool, absttl: Bool, seconds: Int?, frequency: Int?) async throws -> RESP3Token {
        let response = try await send(restoreAskingCommand(key: key, ttl: ttl, serializedValue: serializedValue, replace: replace, absttl: absttl, seconds: seconds, frequency: frequency))
        return response
    }

    @inlinable
    public func restoreAskingCommand(key: RedisKey, ttl: Int, serializedValue: String, replace: Bool, absttl: Bool, seconds: Int?, frequency: Int?) -> RESPCommand {
        RESPCommand("RESTORE-ASKING", key, ttl, serializedValue, RedisPureToken("REPLACE", replace), RedisPureToken("ABSTTL", absttl), RESPWithToken("IDLETIME", seconds), RESPWithToken("FREQ", frequency))
    }

    /// Returns the replication role.
    ///
    /// Version: 2.8.12
    /// Complexity: O(1)
    /// Categories: @admin, @fast, @dangerous
    @inlinable
    public func role() async throws -> RESP3Token {
        let response = try await send(roleCommand())
        return response
    }

    @inlinable
    public func roleCommand() -> RESPCommand {
        RESPCommand("ROLE")
    }

    /// Returns and removes the last elements of a list. Deletes the list if the last element was popped.
    ///
    /// Version: 1.0.0
    /// Complexity: O(N) where N is the number of elements returned
    /// Categories: @write, @list, @fast
    @inlinable
    public func rpop(key: RedisKey, count: Int?) async throws -> RESP3Token {
        let response = try await send(rpopCommand(key: key, count: count))
        return response
    }

    @inlinable
    public func rpopCommand(key: RedisKey, count: Int?) -> RESPCommand {
        RESPCommand("RPOP", key, count)
    }

    /// Returns the last element of a list after removing and pushing it to another list. Deletes the list if the last element was popped.
    ///
    /// Version: 1.2.0
    /// Complexity: O(1)
    /// Categories: @write, @list, @slow
    @inlinable
    public func rpoplpush(source: RedisKey, destination: RedisKey) async throws -> RESP3Token {
        let response = try await send(rpoplpushCommand(source: source, destination: destination))
        return response
    }

    @inlinable
    public func rpoplpushCommand(source: RedisKey, destination: RedisKey) -> RESPCommand {
        RESPCommand("RPOPLPUSH", source, destination)
    }

    /// Appends one or more elements to a list. Creates the key if it doesn't exist.
    ///
    /// Version: 1.0.0
    /// Complexity: O(1) for each element added, so O(N) to add N elements when the command is called with multiple arguments.
    /// Categories: @write, @list, @fast
    @inlinable
    public func rpush(key: RedisKey, element: String...) async throws -> RESP3Token {
        let response = try await send(rpushCommand(key: key, element: element))
        return response
    }

    @inlinable
    public func rpushCommand(key: RedisKey, element: [String]) -> RESPCommand {
        RESPCommand("RPUSH", key, element)
    }

    /// Appends an element to a list only when the list exists.
    ///
    /// Version: 2.2.0
    /// Complexity: O(1) for each element added, so O(N) to add N elements when the command is called with multiple arguments.
    /// Categories: @write, @list, @fast
    @inlinable
    public func rpushx(key: RedisKey, element: String...) async throws -> RESP3Token {
        let response = try await send(rpushxCommand(key: key, element: element))
        return response
    }

    @inlinable
    public func rpushxCommand(key: RedisKey, element: [String]) -> RESPCommand {
        RESPCommand("RPUSHX", key, element)
    }

    /// Adds one or more members to a set. Creates the key if it doesn't exist.
    ///
    /// Version: 1.0.0
    /// Complexity: O(1) for each element added, so O(N) to add N elements when the command is called with multiple arguments.
    /// Categories: @write, @set, @fast
    @inlinable
    public func sadd(key: RedisKey, member: String...) async throws -> RESP3Token {
        let response = try await send(saddCommand(key: key, member: member))
        return response
    }

    @inlinable
    public func saddCommand(key: RedisKey, member: [String]) -> RESPCommand {
        RESPCommand("SADD", key, member)
    }

    /// Synchronously saves the database(s) to disk.
    ///
    /// Version: 1.0.0
    /// Complexity: O(N) where N is the total number of keys in all databases
    /// Categories: @admin, @slow, @dangerous
    @inlinable
    public func save() async throws -> RESP3Token {
        let response = try await send(saveCommand())
        return response
    }

    @inlinable
    public func saveCommand() -> RESPCommand {
        RESPCommand("SAVE")
    }

    /// Iterates over the key names in the database.
    ///
    /// Version: 2.8.0
    /// Complexity: O(1) for every call. O(N) for a complete iteration, including enough command calls for the cursor to return back to 0. N is the number of elements inside the collection.
    /// Categories: @keyspace, @read, @slow
    @inlinable
    public func scan(cursor: Int, pattern: String?, count: Int?, type: String?) async throws -> RESP3Token {
        let response = try await send(scanCommand(cursor: cursor, pattern: pattern, count: count, type: type))
        return response
    }

    @inlinable
    public func scanCommand(cursor: Int, pattern: String?, count: Int?, type: String?) -> RESPCommand {
        RESPCommand("SCAN", cursor, RESPWithToken("MATCH", pattern), RESPWithToken("COUNT", count), RESPWithToken("TYPE", type))
    }

    /// Returns the number of members in a set.
    ///
    /// Version: 1.0.0
    /// Complexity: O(1)
    /// Categories: @read, @set, @fast
    @inlinable
    public func scard(key: RedisKey) async throws -> RESP3Token {
        let response = try await send(scardCommand(key: key))
        return response
    }

    @inlinable
    public func scardCommand(key: RedisKey) -> RESPCommand {
        RESPCommand("SCARD", key)
    }

    /// A container for Lua scripts management commands.
    ///
    /// Version: 2.6.0
    /// Complexity: Depends on subcommand.
    /// Categories: @slow
    @inlinable
    public func script() async throws -> RESP3Token {
        let response = try await send(scriptCommand())
        return response
    }

    @inlinable
    public func scriptCommand() -> RESPCommand {
        RESPCommand("SCRIPT")
    }

    public enum SCRIPTDEBUGMode: RESPRepresentable {
        case yes
        case sync
        case no

        @inlinable
        public func writeToRESPBuffer(_ buffer: inout ByteBuffer) {
            switch self {
            case .yes: "YES".writeToRESPBuffer(&buffer)
            case .sync: "SYNC".writeToRESPBuffer(&buffer)
            case .no: "NO".writeToRESPBuffer(&buffer)
            }
        }
    }
    /// Sets the debug mode of server-side Lua scripts.
    ///
    /// Version: 3.2.0
    /// Complexity: O(1)
    /// Categories: @slow, @scripting
    @inlinable
    public func scriptDebug(mode: SCRIPTDEBUGMode) async throws -> RESP3Token {
        let response = try await send(scriptDebugCommand(mode: mode))
        return response
    }

    @inlinable
    public func scriptDebugCommand(mode: SCRIPTDEBUGMode) -> RESPCommand {
        RESPCommand("SCRIPT", "DEBUG", mode)
    }

    /// Determines whether server-side Lua scripts exist in the script cache.
    ///
    /// Version: 2.6.0
    /// Complexity: O(N) with N being the number of scripts to check (so checking a single script is an O(1) operation).
    /// Categories: @slow, @scripting
    @inlinable
    public func scriptExists(sha1: String...) async throws -> RESP3Token {
        let response = try await send(scriptExistsCommand(sha1: sha1))
        return response
    }

    @inlinable
    public func scriptExistsCommand(sha1: [String]) -> RESPCommand {
        RESPCommand("SCRIPT", "EXISTS", sha1)
    }

    public enum SCRIPTFLUSHFlushType: RESPRepresentable {
        case async
        case sync

        @inlinable
        public func writeToRESPBuffer(_ buffer: inout ByteBuffer) {
            switch self {
            case .async: "ASYNC".writeToRESPBuffer(&buffer)
            case .sync: "SYNC".writeToRESPBuffer(&buffer)
            }
        }
    }
    /// Removes all server-side Lua scripts from the script cache.
    ///
    /// Version: 2.6.0
    /// Complexity: O(N) with N being the number of scripts in cache
    /// Categories: @slow, @scripting
    @inlinable
    public func scriptFlush(flushType: SCRIPTFLUSHFlushType?) async throws -> RESP3Token {
        let response = try await send(scriptFlushCommand(flushType: flushType))
        return response
    }

    @inlinable
    public func scriptFlushCommand(flushType: SCRIPTFLUSHFlushType?) -> RESPCommand {
        RESPCommand("SCRIPT", "FLUSH", flushType)
    }

    /// Returns helpful text about the different subcommands.
    ///
    /// Version: 5.0.0
    /// Complexity: O(1)
    /// Categories: @slow, @scripting
    @inlinable
    public func scriptHelp() async throws -> RESP3Token {
        let response = try await send(scriptHelpCommand())
        return response
    }

    @inlinable
    public func scriptHelpCommand() -> RESPCommand {
        RESPCommand("SCRIPT", "HELP")
    }

    /// Terminates a server-side Lua script during execution.
    ///
    /// Version: 2.6.0
    /// Complexity: O(1)
    /// Categories: @slow, @scripting
    @inlinable
    public func scriptKill() async throws -> RESP3Token {
        let response = try await send(scriptKillCommand())
        return response
    }

    @inlinable
    public func scriptKillCommand() -> RESPCommand {
        RESPCommand("SCRIPT", "KILL")
    }

    /// Loads a server-side Lua script to the script cache.
    ///
    /// Version: 2.6.0
    /// Complexity: O(N) with N being the length in bytes of the script body.
    /// Categories: @slow, @scripting
    @inlinable
    public func scriptLoad(script: String) async throws -> RESP3Token {
        let response = try await send(scriptLoadCommand(script: script))
        return response
    }

    @inlinable
    public func scriptLoadCommand(script: String) -> RESPCommand {
        RESPCommand("SCRIPT", "LOAD", script)
    }

    /// Returns the difference of multiple sets.
    ///
    /// Version: 1.0.0
    /// Complexity: O(N) where N is the total number of elements in all given sets.
    /// Categories: @read, @set, @slow
    @inlinable
    public func sdiff(key: RedisKey...) async throws -> RESP3Token {
        let response = try await send(sdiffCommand(key: key))
        return response
    }

    @inlinable
    public func sdiffCommand(key: [RedisKey]) -> RESPCommand {
        RESPCommand("SDIFF", key)
    }

    /// Stores the difference of multiple sets in a key.
    ///
    /// Version: 1.0.0
    /// Complexity: O(N) where N is the total number of elements in all given sets.
    /// Categories: @write, @set, @slow
    @inlinable
    public func sdiffstore(destination: RedisKey, key: RedisKey...) async throws -> RESP3Token {
        let response = try await send(sdiffstoreCommand(destination: destination, key: key))
        return response
    }

    @inlinable
    public func sdiffstoreCommand(destination: RedisKey, key: [RedisKey]) -> RESPCommand {
        RESPCommand("SDIFFSTORE", destination, key)
    }

    /// Changes the selected database.
    ///
    /// Version: 1.0.0
    /// Complexity: O(1)
    /// Categories: @fast, @connection
    @inlinable
    public func select(index: Int) async throws -> RESP3Token {
        let response = try await send(selectCommand(index: index))
        return response
    }

    @inlinable
    public func selectCommand(index: Int) -> RESPCommand {
        RESPCommand("SELECT", index)
    }

    public enum SETCondition: RESPRepresentable {
        case nx
        case xx

        @inlinable
        public func writeToRESPBuffer(_ buffer: inout ByteBuffer) {
            switch self {
            case .nx: "NX".writeToRESPBuffer(&buffer)
            case .xx: "XX".writeToRESPBuffer(&buffer)
            }
        }
    }
    public enum SETExpiration: RESPRepresentable {
        case seconds(Int)
        case milliseconds(Int)
        case unixTimeSeconds(Date)
        case unixTimeMilliseconds(Date)
        case keepttl

        @inlinable
        public func writeToRESPBuffer(_ buffer: inout ByteBuffer) {
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
    /// Version: 1.0.0
    /// Complexity: O(1)
    /// Categories: @write, @string, @slow
    @inlinable
    public func set(key: RedisKey, value: String, condition: SETCondition?, get: Bool, expiration: SETExpiration?) async throws -> RESP3Token {
        let response = try await send(setCommand(key: key, value: value, condition: condition, get: get, expiration: expiration))
        return response
    }

    @inlinable
    public func setCommand(key: RedisKey, value: String, condition: SETCondition?, get: Bool, expiration: SETExpiration?) -> RESPCommand {
        RESPCommand("SET", key, value, condition, RedisPureToken("GET", get), expiration)
    }

    /// Sets or clears the bit at offset of the string value. Creates the key if it doesn't exist.
    ///
    /// Version: 2.2.0
    /// Complexity: O(1)
    /// Categories: @write, @bitmap, @slow
    @inlinable
    public func setbit(key: RedisKey, offset: Int, value: Int) async throws -> RESP3Token {
        let response = try await send(setbitCommand(key: key, offset: offset, value: value))
        return response
    }

    @inlinable
    public func setbitCommand(key: RedisKey, offset: Int, value: Int) -> RESPCommand {
        RESPCommand("SETBIT", key, offset, value)
    }

    /// Sets the string value and expiration time of a key. Creates the key if it doesn't exist.
    ///
    /// Version: 2.0.0
    /// Complexity: O(1)
    /// Categories: @write, @string, @slow
    @inlinable
    public func setex(key: RedisKey, seconds: Int, value: String) async throws -> RESP3Token {
        let response = try await send(setexCommand(key: key, seconds: seconds, value: value))
        return response
    }

    @inlinable
    public func setexCommand(key: RedisKey, seconds: Int, value: String) -> RESPCommand {
        RESPCommand("SETEX", key, seconds, value)
    }

    /// Set the string value of a key only when the key doesn't exist.
    ///
    /// Version: 1.0.0
    /// Complexity: O(1)
    /// Categories: @write, @string, @fast
    @inlinable
    public func setnx(key: RedisKey, value: String) async throws -> RESP3Token {
        let response = try await send(setnxCommand(key: key, value: value))
        return response
    }

    @inlinable
    public func setnxCommand(key: RedisKey, value: String) -> RESPCommand {
        RESPCommand("SETNX", key, value)
    }

    /// Overwrites a part of a string value with another by an offset. Creates the key if it doesn't exist.
    ///
    /// Version: 2.2.0
    /// Complexity: O(1), not counting the time taken to copy the new string in place. Usually, this string is very small so the amortized complexity is O(1). Otherwise, complexity is O(M) with M being the length of the value argument.
    /// Categories: @write, @string, @slow
    @inlinable
    public func setrange(key: RedisKey, offset: Int, value: String) async throws -> RESP3Token {
        let response = try await send(setrangeCommand(key: key, offset: offset, value: value))
        return response
    }

    @inlinable
    public func setrangeCommand(key: RedisKey, offset: Int, value: String) -> RESPCommand {
        RESPCommand("SETRANGE", key, offset, value)
    }

    public enum SHUTDOWNSaveSelector: RESPRepresentable {
        case nosave
        case save

        @inlinable
        public func writeToRESPBuffer(_ buffer: inout ByteBuffer) {
            switch self {
            case .nosave: "NOSAVE".writeToRESPBuffer(&buffer)
            case .save: "SAVE".writeToRESPBuffer(&buffer)
            }
        }
    }
    /// Synchronously saves the database(s) to disk and shuts down the Redis server.
    ///
    /// Version: 1.0.0
    /// Complexity: O(N) when saving, where N is the total number of keys in all databases when saving data, otherwise O(1)
    /// Categories: @admin, @slow, @dangerous
    @inlinable
    public func shutdown(saveSelector: SHUTDOWNSaveSelector?, now: Bool, force: Bool, abort: Bool) async throws -> RESP3Token {
        let response = try await send(shutdownCommand(saveSelector: saveSelector, now: now, force: force, abort: abort))
        return response
    }

    @inlinable
    public func shutdownCommand(saveSelector: SHUTDOWNSaveSelector?, now: Bool, force: Bool, abort: Bool) -> RESPCommand {
        RESPCommand("SHUTDOWN", saveSelector, RedisPureToken("NOW", now), RedisPureToken("FORCE", force), RedisPureToken("ABORT", abort))
    }

    /// Returns the intersect of multiple sets.
    ///
    /// Version: 1.0.0
    /// Complexity: O(N*M) worst case where N is the cardinality of the smallest set and M is the number of sets.
    /// Categories: @read, @set, @slow
    @inlinable
    public func sinter(key: RedisKey...) async throws -> RESP3Token {
        let response = try await send(sinterCommand(key: key))
        return response
    }

    @inlinable
    public func sinterCommand(key: [RedisKey]) -> RESPCommand {
        RESPCommand("SINTER", key)
    }

    /// Returns the number of members of the intersect of multiple sets.
    ///
    /// Version: 7.0.0
    /// Complexity: O(N*M) worst case where N is the cardinality of the smallest set and M is the number of sets.
    /// Categories: @read, @set, @slow
    @inlinable
    public func sintercard(numkeys: Int, key: RedisKey..., limit: Int?) async throws -> RESP3Token {
        let response = try await send(sintercardCommand(numkeys: numkeys, key: key, limit: limit))
        return response
    }

    @inlinable
    public func sintercardCommand(numkeys: Int, key: [RedisKey], limit: Int?) -> RESPCommand {
        RESPCommand("SINTERCARD", numkeys, key, RESPWithToken("LIMIT", limit))
    }

    /// Stores the intersect of multiple sets in a key.
    ///
    /// Version: 1.0.0
    /// Complexity: O(N*M) worst case where N is the cardinality of the smallest set and M is the number of sets.
    /// Categories: @write, @set, @slow
    @inlinable
    public func sinterstore(destination: RedisKey, key: RedisKey...) async throws -> RESP3Token {
        let response = try await send(sinterstoreCommand(destination: destination, key: key))
        return response
    }

    @inlinable
    public func sinterstoreCommand(destination: RedisKey, key: [RedisKey]) -> RESPCommand {
        RESPCommand("SINTERSTORE", destination, key)
    }

    /// Determines whether a member belongs to a set.
    ///
    /// Version: 1.0.0
    /// Complexity: O(1)
    /// Categories: @read, @set, @fast
    @inlinable
    public func sismember(key: RedisKey, member: String) async throws -> RESP3Token {
        let response = try await send(sismemberCommand(key: key, member: member))
        return response
    }

    @inlinable
    public func sismemberCommand(key: RedisKey, member: String) -> RESPCommand {
        RESPCommand("SISMEMBER", key, member)
    }

    public struct SLAVEOFArgsHostPort: RESPRepresentable {
        @usableFromInline let host: String
        @usableFromInline let port: Int

        @inlinable
        public func writeToRESPBuffer(_ buffer: inout ByteBuffer) {
            self.host.writeToRESPBuffer(&buffer)
            self.port.writeToRESPBuffer(&buffer)
        }
    }
    public struct SLAVEOFArgsNoOne: RESPRepresentable {
        @usableFromInline let no: Bool
        @usableFromInline let one: Bool

        @inlinable
        public func writeToRESPBuffer(_ buffer: inout ByteBuffer) {
            if self.no { "NO".writeToRESPBuffer(&buffer) }
            if self.one { "ONE".writeToRESPBuffer(&buffer) }
        }
    }
    public enum SLAVEOFArgs: RESPRepresentable {
        case hostPort(SLAVEOFArgsHostPort)
        case noOne(SLAVEOFArgsNoOne)

        @inlinable
        public func writeToRESPBuffer(_ buffer: inout ByteBuffer) {
            switch self {
            case .hostPort(let hostPort): hostPort.writeToRESPBuffer(&buffer)
            case .noOne(let noOne): noOne.writeToRESPBuffer(&buffer)
            }
        }
    }
    /// Sets a Redis server as a replica of another, or promotes it to being a master.
    ///
    /// Version: 1.0.0
    /// Complexity: O(1)
    /// Categories: @admin, @slow, @dangerous
    @inlinable
    public func slaveof(args: SLAVEOFArgs) async throws -> RESP3Token {
        let response = try await send(slaveofCommand(args: args))
        return response
    }

    @inlinable
    public func slaveofCommand(args: SLAVEOFArgs) -> RESPCommand {
        RESPCommand("SLAVEOF", args)
    }

    /// A container for slow log commands.
    ///
    /// Version: 2.2.12
    /// Complexity: Depends on subcommand.
    /// Categories: @slow
    @inlinable
    public func slowlog() async throws -> RESP3Token {
        let response = try await send(slowlogCommand())
        return response
    }

    @inlinable
    public func slowlogCommand() -> RESPCommand {
        RESPCommand("SLOWLOG")
    }

    /// Returns the slow log's entries.
    ///
    /// Version: 2.2.12
    /// Complexity: O(N) where N is the number of entries returned
    /// Categories: @admin, @slow, @dangerous
    @inlinable
    public func slowlogGet(count: Int?) async throws -> RESP3Token {
        let response = try await send(slowlogGetCommand(count: count))
        return response
    }

    @inlinable
    public func slowlogGetCommand(count: Int?) -> RESPCommand {
        RESPCommand("SLOWLOG", "GET", count)
    }

    /// Show helpful text about the different subcommands
    ///
    /// Version: 6.2.0
    /// Complexity: O(1)
    /// Categories: @slow
    @inlinable
    public func slowlogHelp() async throws -> RESP3Token {
        let response = try await send(slowlogHelpCommand())
        return response
    }

    @inlinable
    public func slowlogHelpCommand() -> RESPCommand {
        RESPCommand("SLOWLOG", "HELP")
    }

    /// Returns the number of entries in the slow log.
    ///
    /// Version: 2.2.12
    /// Complexity: O(1)
    /// Categories: @admin, @slow, @dangerous
    @inlinable
    public func slowlogLen() async throws -> RESP3Token {
        let response = try await send(slowlogLenCommand())
        return response
    }

    @inlinable
    public func slowlogLenCommand() -> RESPCommand {
        RESPCommand("SLOWLOG", "LEN")
    }

    /// Clears all entries from the slow log.
    ///
    /// Version: 2.2.12
    /// Complexity: O(N) where N is the number of entries in the slowlog
    /// Categories: @admin, @slow, @dangerous
    @inlinable
    public func slowlogReset() async throws -> RESP3Token {
        let response = try await send(slowlogResetCommand())
        return response
    }

    @inlinable
    public func slowlogResetCommand() -> RESPCommand {
        RESPCommand("SLOWLOG", "RESET")
    }

    /// Returns all members of a set.
    ///
    /// Version: 1.0.0
    /// Complexity: O(N) where N is the set cardinality.
    /// Categories: @read, @set, @slow
    @inlinable
    public func smembers(key: RedisKey) async throws -> RESP3Token {
        let response = try await send(smembersCommand(key: key))
        return response
    }

    @inlinable
    public func smembersCommand(key: RedisKey) -> RESPCommand {
        RESPCommand("SMEMBERS", key)
    }

    /// Determines whether multiple members belong to a set.
    ///
    /// Version: 6.2.0
    /// Complexity: O(N) where N is the number of elements being checked for membership
    /// Categories: @read, @set, @fast
    @inlinable
    public func smismember(key: RedisKey, member: String...) async throws -> RESP3Token {
        let response = try await send(smismemberCommand(key: key, member: member))
        return response
    }

    @inlinable
    public func smismemberCommand(key: RedisKey, member: [String]) -> RESPCommand {
        RESPCommand("SMISMEMBER", key, member)
    }

    /// Moves a member from one set to another.
    ///
    /// Version: 1.0.0
    /// Complexity: O(1)
    /// Categories: @write, @set, @fast
    @inlinable
    public func smove(source: RedisKey, destination: RedisKey, member: String) async throws -> RESP3Token {
        let response = try await send(smoveCommand(source: source, destination: destination, member: member))
        return response
    }

    @inlinable
    public func smoveCommand(source: RedisKey, destination: RedisKey, member: String) -> RESPCommand {
        RESPCommand("SMOVE", source, destination, member)
    }

    public struct SORTLimit: RESPRepresentable {
        @usableFromInline let offset: Int
        @usableFromInline let count: Int

        @inlinable
        public func writeToRESPBuffer(_ buffer: inout ByteBuffer) {
            self.offset.writeToRESPBuffer(&buffer)
            self.count.writeToRESPBuffer(&buffer)
        }
    }
    public enum SORTOrder: RESPRepresentable {
        case asc
        case desc

        @inlinable
        public func writeToRESPBuffer(_ buffer: inout ByteBuffer) {
            switch self {
            case .asc: "ASC".writeToRESPBuffer(&buffer)
            case .desc: "DESC".writeToRESPBuffer(&buffer)
            }
        }
    }
    /// Sorts the elements in a list, a set, or a sorted set, optionally storing the result.
    ///
    /// Version: 1.0.0
    /// Complexity: O(N+M*log(M)) where N is the number of elements in the list or set to sort, and M the number of returned elements. When the elements are not sorted, complexity is O(N).
    /// Categories: @write, @set, @sortedset, @list, @slow, @dangerous
    @inlinable
    public func sort(key: RedisKey, byPattern: String?, limit: SORTLimit?, getPattern: String..., order: SORTOrder?, sorting: Bool, destination: RedisKey?) async throws -> RESP3Token {
        let response = try await send(sortCommand(key: key, byPattern: byPattern, limit: limit, getPattern: getPattern, order: order, sorting: sorting, destination: destination))
        return response
    }

    @inlinable
    public func sortCommand(key: RedisKey, byPattern: String?, limit: SORTLimit?, getPattern: [String], order: SORTOrder?, sorting: Bool, destination: RedisKey?) -> RESPCommand {
        RESPCommand("SORT", key, RESPWithToken("BY", byPattern), RESPWithToken("LIMIT", limit), RESPWithToken("GET", getPattern), order, RedisPureToken("ALPHA", sorting), RESPWithToken("STORE", destination))
    }

    public struct SORTROLimit: RESPRepresentable {
        @usableFromInline let offset: Int
        @usableFromInline let count: Int

        @inlinable
        public func writeToRESPBuffer(_ buffer: inout ByteBuffer) {
            self.offset.writeToRESPBuffer(&buffer)
            self.count.writeToRESPBuffer(&buffer)
        }
    }
    public enum SORTROOrder: RESPRepresentable {
        case asc
        case desc

        @inlinable
        public func writeToRESPBuffer(_ buffer: inout ByteBuffer) {
            switch self {
            case .asc: "ASC".writeToRESPBuffer(&buffer)
            case .desc: "DESC".writeToRESPBuffer(&buffer)
            }
        }
    }
    /// Returns the sorted elements of a list, a set, or a sorted set.
    ///
    /// Version: 7.0.0
    /// Complexity: O(N+M*log(M)) where N is the number of elements in the list or set to sort, and M the number of returned elements. When the elements are not sorted, complexity is O(N).
    /// Categories: @read, @set, @sortedset, @list, @slow, @dangerous
    @inlinable
    public func sortRo(key: RedisKey, byPattern: String?, limit: SORTROLimit?, getPattern: String..., order: SORTROOrder?, sorting: Bool) async throws -> RESP3Token {
        let response = try await send(sortRoCommand(key: key, byPattern: byPattern, limit: limit, getPattern: getPattern, order: order, sorting: sorting))
        return response
    }

    @inlinable
    public func sortRoCommand(key: RedisKey, byPattern: String?, limit: SORTROLimit?, getPattern: [String], order: SORTROOrder?, sorting: Bool) -> RESPCommand {
        RESPCommand("SORT_RO", key, RESPWithToken("BY", byPattern), RESPWithToken("LIMIT", limit), RESPWithToken("GET", getPattern), order, RedisPureToken("ALPHA", sorting))
    }

    /// Returns one or more random members from a set after removing them. Deletes the set if the last member was popped.
    ///
    /// Version: 1.0.0
    /// Complexity: Without the count argument O(1), otherwise O(N) where N is the value of the passed count.
    /// Categories: @write, @set, @fast
    @inlinable
    public func spop(key: RedisKey, count: Int?) async throws -> RESP3Token {
        let response = try await send(spopCommand(key: key, count: count))
        return response
    }

    @inlinable
    public func spopCommand(key: RedisKey, count: Int?) -> RESPCommand {
        RESPCommand("SPOP", key, count)
    }

    /// Post a message to a shard channel
    ///
    /// Version: 7.0.0
    /// Complexity: O(N) where N is the number of clients subscribed to the receiving shard channel.
    /// Categories: @pubsub, @fast
    @inlinable
    public func spublish(shardchannel: String, message: String) async throws -> RESP3Token {
        let response = try await send(spublishCommand(shardchannel: shardchannel, message: message))
        return response
    }

    @inlinable
    public func spublishCommand(shardchannel: String, message: String) -> RESPCommand {
        RESPCommand("SPUBLISH", shardchannel, message)
    }

    /// Get one or multiple random members from a set
    ///
    /// Version: 1.0.0
    /// Complexity: Without the count argument O(1), otherwise O(N) where N is the absolute value of the passed count.
    /// Categories: @read, @set, @slow
    @inlinable
    public func srandmember(key: RedisKey, count: Int?) async throws -> RESP3Token {
        let response = try await send(srandmemberCommand(key: key, count: count))
        return response
    }

    @inlinable
    public func srandmemberCommand(key: RedisKey, count: Int?) -> RESPCommand {
        RESPCommand("SRANDMEMBER", key, count)
    }

    /// Removes one or more members from a set. Deletes the set if the last member was removed.
    ///
    /// Version: 1.0.0
    /// Complexity: O(N) where N is the number of members to be removed.
    /// Categories: @write, @set, @fast
    @inlinable
    public func srem(key: RedisKey, member: String...) async throws -> RESP3Token {
        let response = try await send(sremCommand(key: key, member: member))
        return response
    }

    @inlinable
    public func sremCommand(key: RedisKey, member: [String]) -> RESPCommand {
        RESPCommand("SREM", key, member)
    }

    /// Iterates over members of a set.
    ///
    /// Version: 2.8.0
    /// Complexity: O(1) for every call. O(N) for a complete iteration, including enough command calls for the cursor to return back to 0. N is the number of elements inside the collection.
    /// Categories: @read, @set, @slow
    @inlinable
    public func sscan(key: RedisKey, cursor: Int, pattern: String?, count: Int?) async throws -> RESP3Token {
        let response = try await send(sscanCommand(key: key, cursor: cursor, pattern: pattern, count: count))
        return response
    }

    @inlinable
    public func sscanCommand(key: RedisKey, cursor: Int, pattern: String?, count: Int?) -> RESPCommand {
        RESPCommand("SSCAN", key, cursor, RESPWithToken("MATCH", pattern), RESPWithToken("COUNT", count))
    }

    /// Listens for messages published to shard channels.
    ///
    /// Version: 7.0.0
    /// Complexity: O(N) where N is the number of shard channels to subscribe to.
    /// Categories: @pubsub, @slow
    @inlinable
    public func ssubscribe(shardchannel: String...) async throws -> RESP3Token {
        let response = try await send(ssubscribeCommand(shardchannel: shardchannel))
        return response
    }

    @inlinable
    public func ssubscribeCommand(shardchannel: [String]) -> RESPCommand {
        RESPCommand("SSUBSCRIBE", shardchannel)
    }

    /// Returns the length of a string value.
    ///
    /// Version: 2.2.0
    /// Complexity: O(1)
    /// Categories: @read, @string, @fast
    @inlinable
    public func strlen(key: RedisKey) async throws -> RESP3Token {
        let response = try await send(strlenCommand(key: key))
        return response
    }

    @inlinable
    public func strlenCommand(key: RedisKey) -> RESPCommand {
        RESPCommand("STRLEN", key)
    }

    /// Listens for messages published to channels.
    ///
    /// Version: 2.0.0
    /// Complexity: O(N) where N is the number of channels to subscribe to.
    /// Categories: @pubsub, @slow
    @inlinable
    public func subscribe(channel: String...) async throws -> RESP3Token {
        let response = try await send(subscribeCommand(channel: channel))
        return response
    }

    @inlinable
    public func subscribeCommand(channel: [String]) -> RESPCommand {
        RESPCommand("SUBSCRIBE", channel)
    }

    /// Returns a substring from a string value.
    ///
    /// Version: 1.0.0
    /// Complexity: O(N) where N is the length of the returned string. The complexity is ultimately determined by the returned length, but because creating a substring from an existing string is very cheap, it can be considered O(1) for small strings.
    /// Categories: @read, @string, @slow
    @inlinable
    public func substr(key: RedisKey, start: Int, end: Int) async throws -> RESP3Token {
        let response = try await send(substrCommand(key: key, start: start, end: end))
        return response
    }

    @inlinable
    public func substrCommand(key: RedisKey, start: Int, end: Int) -> RESPCommand {
        RESPCommand("SUBSTR", key, start, end)
    }

    /// Returns the union of multiple sets.
    ///
    /// Version: 1.0.0
    /// Complexity: O(N) where N is the total number of elements in all given sets.
    /// Categories: @read, @set, @slow
    @inlinable
    public func sunion(key: RedisKey...) async throws -> RESP3Token {
        let response = try await send(sunionCommand(key: key))
        return response
    }

    @inlinable
    public func sunionCommand(key: [RedisKey]) -> RESPCommand {
        RESPCommand("SUNION", key)
    }

    /// Stores the union of multiple sets in a key.
    ///
    /// Version: 1.0.0
    /// Complexity: O(N) where N is the total number of elements in all given sets.
    /// Categories: @write, @set, @slow
    @inlinable
    public func sunionstore(destination: RedisKey, key: RedisKey...) async throws -> RESP3Token {
        let response = try await send(sunionstoreCommand(destination: destination, key: key))
        return response
    }

    @inlinable
    public func sunionstoreCommand(destination: RedisKey, key: [RedisKey]) -> RESPCommand {
        RESPCommand("SUNIONSTORE", destination, key)
    }

    /// Stops listening to messages posted to shard channels.
    ///
    /// Version: 7.0.0
    /// Complexity: O(N) where N is the number of shard channels to unsubscribe.
    /// Categories: @pubsub, @slow
    @inlinable
    public func sunsubscribe(shardchannel: String...) async throws -> RESP3Token {
        let response = try await send(sunsubscribeCommand(shardchannel: shardchannel))
        return response
    }

    @inlinable
    public func sunsubscribeCommand(shardchannel: [String]) -> RESPCommand {
        RESPCommand("SUNSUBSCRIBE", shardchannel)
    }

    /// Swaps two Redis databases.
    ///
    /// Version: 4.0.0
    /// Complexity: O(N) where N is the count of clients watching or blocking on keys from both databases.
    /// Categories: @keyspace, @write, @fast, @dangerous
    @inlinable
    public func swapdb(index1: Int, index2: Int) async throws -> RESP3Token {
        let response = try await send(swapdbCommand(index1: index1, index2: index2))
        return response
    }

    @inlinable
    public func swapdbCommand(index1: Int, index2: Int) -> RESPCommand {
        RESPCommand("SWAPDB", index1, index2)
    }

    /// An internal command used in replication.
    ///
    /// Version: 1.0.0
    /// Categories: @admin, @slow, @dangerous
    @inlinable
    public func sync() async throws -> RESP3Token {
        let response = try await send(syncCommand())
        return response
    }

    @inlinable
    public func syncCommand() -> RESPCommand {
        RESPCommand("SYNC")
    }

    /// Returns the server time.
    ///
    /// Version: 2.6.0
    /// Complexity: O(1)
    /// Categories: @fast
    @inlinable
    public func time() async throws -> RESP3Token {
        let response = try await send(timeCommand())
        return response
    }

    @inlinable
    public func timeCommand() -> RESPCommand {
        RESPCommand("TIME")
    }

    /// Returns the number of existing keys out of those specified after updating the time they were last accessed.
    ///
    /// Version: 3.2.1
    /// Complexity: O(N) where N is the number of keys that will be touched.
    /// Categories: @keyspace, @read, @fast
    @inlinable
    public func touch(key: RedisKey...) async throws -> RESP3Token {
        let response = try await send(touchCommand(key: key))
        return response
    }

    @inlinable
    public func touchCommand(key: [RedisKey]) -> RESPCommand {
        RESPCommand("TOUCH", key)
    }

    /// Returns the expiration time in seconds of a key.
    ///
    /// Version: 1.0.0
    /// Complexity: O(1)
    /// Categories: @keyspace, @read, @fast
    @inlinable
    public func ttl(key: RedisKey) async throws -> RESP3Token {
        let response = try await send(ttlCommand(key: key))
        return response
    }

    @inlinable
    public func ttlCommand(key: RedisKey) -> RESPCommand {
        RESPCommand("TTL", key)
    }

    /// Determines the type of value stored at a key.
    ///
    /// Version: 1.0.0
    /// Complexity: O(1)
    /// Categories: @keyspace, @read, @fast
    @inlinable
    public func type(key: RedisKey) async throws -> RESP3Token {
        let response = try await send(typeCommand(key: key))
        return response
    }

    @inlinable
    public func typeCommand(key: RedisKey) -> RESPCommand {
        RESPCommand("TYPE", key)
    }

    /// Asynchronously deletes one or more keys.
    ///
    /// Version: 4.0.0
    /// Complexity: O(1) for each key removed regardless of its size. Then the command does O(N) work in a different thread in order to reclaim memory, where N is the number of allocations the deleted objects where composed of.
    /// Categories: @keyspace, @write, @fast
    @inlinable
    public func unlink(key: RedisKey...) async throws -> RESP3Token {
        let response = try await send(unlinkCommand(key: key))
        return response
    }

    @inlinable
    public func unlinkCommand(key: [RedisKey]) -> RESPCommand {
        RESPCommand("UNLINK", key)
    }

    /// Stops listening to messages posted to channels.
    ///
    /// Version: 2.0.0
    /// Complexity: O(N) where N is the number of channels to unsubscribe.
    /// Categories: @pubsub, @slow
    @inlinable
    public func unsubscribe(channel: String...) async throws -> RESP3Token {
        let response = try await send(unsubscribeCommand(channel: channel))
        return response
    }

    @inlinable
    public func unsubscribeCommand(channel: [String]) -> RESPCommand {
        RESPCommand("UNSUBSCRIBE", channel)
    }

    /// Forgets about watched keys of a transaction.
    ///
    /// Version: 2.2.0
    /// Complexity: O(1)
    /// Categories: @fast, @transaction
    @inlinable
    public func unwatch() async throws -> RESP3Token {
        let response = try await send(unwatchCommand())
        return response
    }

    @inlinable
    public func unwatchCommand() -> RESPCommand {
        RESPCommand("UNWATCH")
    }

    /// Blocks until the asynchronous replication of all preceding write commands sent by the connection is completed.
    ///
    /// Version: 3.0.0
    /// Complexity: O(1)
    /// Categories: @slow, @connection
    @inlinable
    public func wait(numreplicas: Int, timeout: Int) async throws -> RESP3Token {
        let response = try await send(waitCommand(numreplicas: numreplicas, timeout: timeout))
        return response
    }

    @inlinable
    public func waitCommand(numreplicas: Int, timeout: Int) -> RESPCommand {
        RESPCommand("WAIT", numreplicas, timeout)
    }

    /// Blocks until all of the preceding write commands sent by the connection are written to the append-only file of the master and/or replicas.
    ///
    /// Version: 7.2.0
    /// Complexity: O(1)
    /// Categories: @slow, @connection
    @inlinable
    public func waitaof(numlocal: Int, numreplicas: Int, timeout: Int) async throws -> RESP3Token {
        let response = try await send(waitaofCommand(numlocal: numlocal, numreplicas: numreplicas, timeout: timeout))
        return response
    }

    @inlinable
    public func waitaofCommand(numlocal: Int, numreplicas: Int, timeout: Int) -> RESPCommand {
        RESPCommand("WAITAOF", numlocal, numreplicas, timeout)
    }

    /// Monitors changes to keys to determine the execution of a transaction.
    ///
    /// Version: 2.2.0
    /// Complexity: O(1) for every key.
    /// Categories: @fast, @transaction
    @inlinable
    public func watch(key: RedisKey...) async throws -> RESP3Token {
        let response = try await send(watchCommand(key: key))
        return response
    }

    @inlinable
    public func watchCommand(key: [RedisKey]) -> RESPCommand {
        RESPCommand("WATCH", key)
    }

    /// Returns the number of messages that were successfully acknowledged by the consumer group member of a stream.
    ///
    /// Version: 5.0.0
    /// Complexity: O(1) for each message ID processed.
    /// Categories: @write, @stream, @fast
    @inlinable
    public func xack(key: RedisKey, group: String, id: String...) async throws -> RESP3Token {
        let response = try await send(xackCommand(key: key, group: group, id: id))
        return response
    }

    @inlinable
    public func xackCommand(key: RedisKey, group: String, id: [String]) -> RESPCommand {
        RESPCommand("XACK", key, group, id)
    }

    public enum XADDTrimStrategy: RESPRepresentable {
        case maxlen
        case minid

        @inlinable
        public func writeToRESPBuffer(_ buffer: inout ByteBuffer) {
            switch self {
            case .maxlen: "MAXLEN".writeToRESPBuffer(&buffer)
            case .minid: "MINID".writeToRESPBuffer(&buffer)
            }
        }
    }
    public enum XADDTrimOperator: RESPRepresentable {
        case equal
        case approximately

        @inlinable
        public func writeToRESPBuffer(_ buffer: inout ByteBuffer) {
            switch self {
            case .equal: "=".writeToRESPBuffer(&buffer)
            case .approximately: "~".writeToRESPBuffer(&buffer)
            }
        }
    }
    public struct XADDTrim: RESPRepresentable {
        @usableFromInline let strategy: XADDTrimStrategy
        @usableFromInline let `operator`: XADDTrimOperator?
        @usableFromInline let threshold: String
        @usableFromInline let count: Int?

        @inlinable
        public func writeToRESPBuffer(_ buffer: inout ByteBuffer) {
            self.strategy.writeToRESPBuffer(&buffer)
            self.operator.writeToRESPBuffer(&buffer)
            self.threshold.writeToRESPBuffer(&buffer)
            self.count.writeToRESPBuffer(&buffer)
        }
    }
    public enum XADDIdSelector: RESPRepresentable {
        case autoId
        case id(String)

        @inlinable
        public func writeToRESPBuffer(_ buffer: inout ByteBuffer) {
            switch self {
            case .autoId: "*".writeToRESPBuffer(&buffer)
            case .id(let id): id.writeToRESPBuffer(&buffer)
            }
        }
    }
    public struct XADDData: RESPRepresentable {
        @usableFromInline let field: String
        @usableFromInline let value: String

        @inlinable
        public func writeToRESPBuffer(_ buffer: inout ByteBuffer) {
            self.field.writeToRESPBuffer(&buffer)
            self.value.writeToRESPBuffer(&buffer)
        }
    }
    /// Appends a new message to a stream. Creates the key if it doesn't exist.
    ///
    /// Version: 5.0.0
    /// Complexity: O(1) when adding a new entry, O(N) when trimming where N being the number of entries evicted.
    /// Categories: @write, @stream, @fast
    @inlinable
    public func xadd(key: RedisKey, nomkstream: Bool, trim: XADDTrim?, idSelector: XADDIdSelector, data: XADDData...) async throws -> RESP3Token {
        let response = try await send(xaddCommand(key: key, nomkstream: nomkstream, trim: trim, idSelector: idSelector, data: data))
        return response
    }

    @inlinable
    public func xaddCommand(key: RedisKey, nomkstream: Bool, trim: XADDTrim?, idSelector: XADDIdSelector, data: [XADDData]) -> RESPCommand {
        RESPCommand("XADD", key, RedisPureToken("NOMKSTREAM", nomkstream), trim, idSelector, data)
    }

    /// Changes, or acquires, ownership of messages in a consumer group, as if the messages were delivered to as consumer group member.
    ///
    /// Version: 6.2.0
    /// Complexity: O(1) if COUNT is small.
    /// Categories: @write, @stream, @fast
    @inlinable
    public func xautoclaim(key: RedisKey, group: String, consumer: String, minIdleTime: String, start: String, count: Int?, justid: Bool) async throws -> RESP3Token {
        let response = try await send(xautoclaimCommand(key: key, group: group, consumer: consumer, minIdleTime: minIdleTime, start: start, count: count, justid: justid))
        return response
    }

    @inlinable
    public func xautoclaimCommand(key: RedisKey, group: String, consumer: String, minIdleTime: String, start: String, count: Int?, justid: Bool) -> RESPCommand {
        RESPCommand("XAUTOCLAIM", key, group, consumer, minIdleTime, start, RESPWithToken("COUNT", count), RedisPureToken("JUSTID", justid))
    }

    /// Changes, or acquires, ownership of a message in a consumer group, as if the message was delivered a consumer group member.
    ///
    /// Version: 5.0.0
    /// Complexity: O(log N) with N being the number of messages in the PEL of the consumer group.
    /// Categories: @write, @stream, @fast
    @inlinable
    public func xclaim(key: RedisKey, group: String, consumer: String, minIdleTime: String, id: String..., ms: Int?, unixTimeMilliseconds: Date?, count: Int?, force: Bool, justid: Bool, lastid: String?) async throws -> RESP3Token {
        let response = try await send(xclaimCommand(key: key, group: group, consumer: consumer, minIdleTime: minIdleTime, id: id, ms: ms, unixTimeMilliseconds: unixTimeMilliseconds, count: count, force: force, justid: justid, lastid: lastid))
        return response
    }

    @inlinable
    public func xclaimCommand(key: RedisKey, group: String, consumer: String, minIdleTime: String, id: [String], ms: Int?, unixTimeMilliseconds: Date?, count: Int?, force: Bool, justid: Bool, lastid: String?) -> RESPCommand {
        RESPCommand("XCLAIM", key, group, consumer, minIdleTime, id, RESPWithToken("IDLE", ms), RESPWithToken("TIME", unixTimeMilliseconds), RESPWithToken("RETRYCOUNT", count), RedisPureToken("FORCE", force), RedisPureToken("JUSTID", justid), RESPWithToken("LASTID", lastid))
    }

    /// Returns the number of messages after removing them from a stream.
    ///
    /// Version: 5.0.0
    /// Complexity: O(1) for each single item to delete in the stream, regardless of the stream size.
    /// Categories: @write, @stream, @fast
    @inlinable
    public func xdel(key: RedisKey, id: String...) async throws -> RESP3Token {
        let response = try await send(xdelCommand(key: key, id: id))
        return response
    }

    @inlinable
    public func xdelCommand(key: RedisKey, id: [String]) -> RESPCommand {
        RESPCommand("XDEL", key, id)
    }

    /// A container for consumer groups commands.
    ///
    /// Version: 5.0.0
    /// Complexity: Depends on subcommand.
    /// Categories: @slow
    @inlinable
    public func xgroup() async throws -> RESP3Token {
        let response = try await send(xgroupCommand())
        return response
    }

    @inlinable
    public func xgroupCommand() -> RESPCommand {
        RESPCommand("XGROUP")
    }

    public enum XGROUPCREATEIdSelector: RESPRepresentable {
        case id(String)
        case newId

        @inlinable
        public func writeToRESPBuffer(_ buffer: inout ByteBuffer) {
            switch self {
            case .id(let id): id.writeToRESPBuffer(&buffer)
            case .newId: "$".writeToRESPBuffer(&buffer)
            }
        }
    }
    /// Creates a consumer group.
    ///
    /// Version: 5.0.0
    /// Complexity: O(1)
    /// Categories: @write, @stream, @slow
    @inlinable
    public func xgroupCreate(key: RedisKey, group: String, idSelector: XGROUPCREATEIdSelector, mkstream: Bool, entriesRead: Int?) async throws -> RESP3Token {
        let response = try await send(xgroupCreateCommand(key: key, group: group, idSelector: idSelector, mkstream: mkstream, entriesRead: entriesRead))
        return response
    }

    @inlinable
    public func xgroupCreateCommand(key: RedisKey, group: String, idSelector: XGROUPCREATEIdSelector, mkstream: Bool, entriesRead: Int?) -> RESPCommand {
        RESPCommand("XGROUP", "CREATE", key, group, idSelector, RedisPureToken("MKSTREAM", mkstream), RESPWithToken("ENTRIESREAD", entriesRead))
    }

    /// Creates a consumer in a consumer group.
    ///
    /// Version: 6.2.0
    /// Complexity: O(1)
    /// Categories: @write, @stream, @slow
    @inlinable
    public func xgroupCreateconsumer(key: RedisKey, group: String, consumer: String) async throws -> RESP3Token {
        let response = try await send(xgroupCreateconsumerCommand(key: key, group: group, consumer: consumer))
        return response
    }

    @inlinable
    public func xgroupCreateconsumerCommand(key: RedisKey, group: String, consumer: String) -> RESPCommand {
        RESPCommand("XGROUP", "CREATECONSUMER", key, group, consumer)
    }

    /// Deletes a consumer from a consumer group.
    ///
    /// Version: 5.0.0
    /// Complexity: O(1)
    /// Categories: @write, @stream, @slow
    @inlinable
    public func xgroupDelconsumer(key: RedisKey, group: String, consumer: String) async throws -> RESP3Token {
        let response = try await send(xgroupDelconsumerCommand(key: key, group: group, consumer: consumer))
        return response
    }

    @inlinable
    public func xgroupDelconsumerCommand(key: RedisKey, group: String, consumer: String) -> RESPCommand {
        RESPCommand("XGROUP", "DELCONSUMER", key, group, consumer)
    }

    /// Destroys a consumer group.
    ///
    /// Version: 5.0.0
    /// Complexity: O(N) where N is the number of entries in the group's pending entries list (PEL).
    /// Categories: @write, @stream, @slow
    @inlinable
    public func xgroupDestroy(key: RedisKey, group: String) async throws -> RESP3Token {
        let response = try await send(xgroupDestroyCommand(key: key, group: group))
        return response
    }

    @inlinable
    public func xgroupDestroyCommand(key: RedisKey, group: String) -> RESPCommand {
        RESPCommand("XGROUP", "DESTROY", key, group)
    }

    /// Returns helpful text about the different subcommands.
    ///
    /// Version: 5.0.0
    /// Complexity: O(1)
    /// Categories: @stream, @slow
    @inlinable
    public func xgroupHelp() async throws -> RESP3Token {
        let response = try await send(xgroupHelpCommand())
        return response
    }

    @inlinable
    public func xgroupHelpCommand() -> RESPCommand {
        RESPCommand("XGROUP", "HELP")
    }

    public enum XGROUPSETIDIdSelector: RESPRepresentable {
        case id(String)
        case newId

        @inlinable
        public func writeToRESPBuffer(_ buffer: inout ByteBuffer) {
            switch self {
            case .id(let id): id.writeToRESPBuffer(&buffer)
            case .newId: "$".writeToRESPBuffer(&buffer)
            }
        }
    }
    /// Sets the last-delivered ID of a consumer group.
    ///
    /// Version: 5.0.0
    /// Complexity: O(1)
    /// Categories: @write, @stream, @slow
    @inlinable
    public func xgroupSetid(key: RedisKey, group: String, idSelector: XGROUPSETIDIdSelector, entriesread: Int?) async throws -> RESP3Token {
        let response = try await send(xgroupSetidCommand(key: key, group: group, idSelector: idSelector, entriesread: entriesread))
        return response
    }

    @inlinable
    public func xgroupSetidCommand(key: RedisKey, group: String, idSelector: XGROUPSETIDIdSelector, entriesread: Int?) -> RESPCommand {
        RESPCommand("XGROUP", "SETID", key, group, idSelector, RESPWithToken("ENTRIESREAD", entriesread))
    }

    /// A container for stream introspection commands.
    ///
    /// Version: 5.0.0
    /// Complexity: Depends on subcommand.
    /// Categories: @slow
    @inlinable
    public func xinfo() async throws -> RESP3Token {
        let response = try await send(xinfoCommand())
        return response
    }

    @inlinable
    public func xinfoCommand() -> RESPCommand {
        RESPCommand("XINFO")
    }

    /// Returns a list of the consumers in a consumer group.
    ///
    /// Version: 5.0.0
    /// Complexity: O(1)
    /// Categories: @read, @stream, @slow
    @inlinable
    public func xinfoConsumers(key: RedisKey, group: String) async throws -> RESP3Token {
        let response = try await send(xinfoConsumersCommand(key: key, group: group))
        return response
    }

    @inlinable
    public func xinfoConsumersCommand(key: RedisKey, group: String) -> RESPCommand {
        RESPCommand("XINFO", "CONSUMERS", key, group)
    }

    /// Returns a list of the consumer groups of a stream.
    ///
    /// Version: 5.0.0
    /// Complexity: O(1)
    /// Categories: @read, @stream, @slow
    @inlinable
    public func xinfoGroups(key: RedisKey) async throws -> RESP3Token {
        let response = try await send(xinfoGroupsCommand(key: key))
        return response
    }

    @inlinable
    public func xinfoGroupsCommand(key: RedisKey) -> RESPCommand {
        RESPCommand("XINFO", "GROUPS", key)
    }

    /// Returns helpful text about the different subcommands.
    ///
    /// Version: 5.0.0
    /// Complexity: O(1)
    /// Categories: @stream, @slow
    @inlinable
    public func xinfoHelp() async throws -> RESP3Token {
        let response = try await send(xinfoHelpCommand())
        return response
    }

    @inlinable
    public func xinfoHelpCommand() -> RESPCommand {
        RESPCommand("XINFO", "HELP")
    }

    public struct XINFOSTREAMFullBlock: RESPRepresentable {
        @usableFromInline let full: Bool
        @usableFromInline let count: Int?

        @inlinable
        public func writeToRESPBuffer(_ buffer: inout ByteBuffer) {
            if self.full { "FULL".writeToRESPBuffer(&buffer) }
            self.count.writeToRESPBuffer(&buffer)
        }
    }
    /// Returns information about a stream.
    ///
    /// Version: 5.0.0
    /// Complexity: O(1)
    /// Categories: @read, @stream, @slow
    @inlinable
    public func xinfoStream(key: RedisKey, fullBlock: XINFOSTREAMFullBlock?) async throws -> RESP3Token {
        let response = try await send(xinfoStreamCommand(key: key, fullBlock: fullBlock))
        return response
    }

    @inlinable
    public func xinfoStreamCommand(key: RedisKey, fullBlock: XINFOSTREAMFullBlock?) -> RESPCommand {
        RESPCommand("XINFO", "STREAM", key, fullBlock)
    }

    /// Return the number of messages in a stream.
    ///
    /// Version: 5.0.0
    /// Complexity: O(1)
    /// Categories: @read, @stream, @fast
    @inlinable
    public func xlen(key: RedisKey) async throws -> RESP3Token {
        let response = try await send(xlenCommand(key: key))
        return response
    }

    @inlinable
    public func xlenCommand(key: RedisKey) -> RESPCommand {
        RESPCommand("XLEN", key)
    }

    public struct XPENDINGFilters: RESPRepresentable {
        @usableFromInline let minIdleTime: Int?
        @usableFromInline let start: String
        @usableFromInline let end: String
        @usableFromInline let count: Int
        @usableFromInline let consumer: String?

        @inlinable
        public func writeToRESPBuffer(_ buffer: inout ByteBuffer) {
            self.minIdleTime.writeToRESPBuffer(&buffer)
            self.start.writeToRESPBuffer(&buffer)
            self.end.writeToRESPBuffer(&buffer)
            self.count.writeToRESPBuffer(&buffer)
            self.consumer.writeToRESPBuffer(&buffer)
        }
    }
    /// Returns the information and entries from a stream consumer group's pending entries list.
    ///
    /// Version: 5.0.0
    /// Complexity: O(N) with N being the number of elements returned, so asking for a small fixed number of entries per call is O(1). O(M), where M is the total number of entries scanned when used with the IDLE filter. When the command returns just the summary and the list of consumers is small, it runs in O(1) time; otherwise, an additional O(N) time for iterating every consumer.
    /// Categories: @read, @stream, @slow
    @inlinable
    public func xpending(key: RedisKey, group: String, filters: XPENDINGFilters?) async throws -> RESP3Token {
        let response = try await send(xpendingCommand(key: key, group: group, filters: filters))
        return response
    }

    @inlinable
    public func xpendingCommand(key: RedisKey, group: String, filters: XPENDINGFilters?) -> RESPCommand {
        RESPCommand("XPENDING", key, group, filters)
    }

    /// Returns the messages from a stream within a range of IDs.
    ///
    /// Version: 5.0.0
    /// Complexity: O(N) with N being the number of elements being returned. If N is constant (e.g. always asking for the first 10 elements with COUNT), you can consider it O(1).
    /// Categories: @read, @stream, @slow
    @inlinable
    public func xrange(key: RedisKey, start: String, end: String, count: Int?) async throws -> RESP3Token {
        let response = try await send(xrangeCommand(key: key, start: start, end: end, count: count))
        return response
    }

    @inlinable
    public func xrangeCommand(key: RedisKey, start: String, end: String, count: Int?) -> RESPCommand {
        RESPCommand("XRANGE", key, start, end, RESPWithToken("COUNT", count))
    }

    public struct XREADStreams: RESPRepresentable {
        @usableFromInline let key: [RedisKey]
        @usableFromInline let id: [String]

        @inlinable
        public func writeToRESPBuffer(_ buffer: inout ByteBuffer) {
            self.key.writeToRESPBuffer(&buffer)
            self.id.writeToRESPBuffer(&buffer)
        }
    }
    /// Returns messages from multiple streams with IDs greater than the ones requested. Blocks until a message is available otherwise.
    ///
    /// Version: 5.0.0
    /// Categories: @read, @stream, @slow, @blocking
    @inlinable
    public func xread(count: Int?, milliseconds: Int?, streams: XREADStreams) async throws -> RESP3Token {
        let response = try await send(xreadCommand(count: count, milliseconds: milliseconds, streams: streams))
        return response
    }

    @inlinable
    public func xreadCommand(count: Int?, milliseconds: Int?, streams: XREADStreams) -> RESPCommand {
        RESPCommand("XREAD", RESPWithToken("COUNT", count), RESPWithToken("BLOCK", milliseconds), RESPWithToken("STREAMS", streams))
    }

    public struct XREADGROUPGroupBlock: RESPRepresentable {
        @usableFromInline let group: String
        @usableFromInline let consumer: String

        @inlinable
        public func writeToRESPBuffer(_ buffer: inout ByteBuffer) {
            self.group.writeToRESPBuffer(&buffer)
            self.consumer.writeToRESPBuffer(&buffer)
        }
    }
    public struct XREADGROUPStreams: RESPRepresentable {
        @usableFromInline let key: [RedisKey]
        @usableFromInline let id: [String]

        @inlinable
        public func writeToRESPBuffer(_ buffer: inout ByteBuffer) {
            self.key.writeToRESPBuffer(&buffer)
            self.id.writeToRESPBuffer(&buffer)
        }
    }
    /// Returns new or historical messages from a stream for a consumer in a group. Blocks until a message is available otherwise.
    ///
    /// Version: 5.0.0
    /// Complexity: For each stream mentioned: O(M) with M being the number of elements returned. If M is constant (e.g. always asking for the first 10 elements with COUNT), you can consider it O(1). On the other side when XREADGROUP blocks, XADD will pay the O(N) time in order to serve the N clients blocked on the stream getting new data.
    /// Categories: @write, @stream, @slow, @blocking
    @inlinable
    public func xreadgroup(groupBlock: XREADGROUPGroupBlock, count: Int?, milliseconds: Int?, noack: Bool, streams: XREADGROUPStreams) async throws -> RESP3Token {
        let response = try await send(xreadgroupCommand(groupBlock: groupBlock, count: count, milliseconds: milliseconds, noack: noack, streams: streams))
        return response
    }

    @inlinable
    public func xreadgroupCommand(groupBlock: XREADGROUPGroupBlock, count: Int?, milliseconds: Int?, noack: Bool, streams: XREADGROUPStreams) -> RESPCommand {
        RESPCommand("XREADGROUP", RESPWithToken("GROUP", groupBlock), RESPWithToken("COUNT", count), RESPWithToken("BLOCK", milliseconds), RedisPureToken("NOACK", noack), RESPWithToken("STREAMS", streams))
    }

    /// Returns the messages from a stream within a range of IDs in reverse order.
    ///
    /// Version: 5.0.0
    /// Complexity: O(N) with N being the number of elements returned. If N is constant (e.g. always asking for the first 10 elements with COUNT), you can consider it O(1).
    /// Categories: @read, @stream, @slow
    @inlinable
    public func xrevrange(key: RedisKey, end: String, start: String, count: Int?) async throws -> RESP3Token {
        let response = try await send(xrevrangeCommand(key: key, end: end, start: start, count: count))
        return response
    }

    @inlinable
    public func xrevrangeCommand(key: RedisKey, end: String, start: String, count: Int?) -> RESPCommand {
        RESPCommand("XREVRANGE", key, end, start, RESPWithToken("COUNT", count))
    }

    /// An internal command for replicating stream values.
    ///
    /// Version: 5.0.0
    /// Complexity: O(1)
    /// Categories: @write, @stream, @fast
    @inlinable
    public func xsetid(key: RedisKey, lastId: String, entriesAdded: Int?, maxDeletedId: String?) async throws -> RESP3Token {
        let response = try await send(xsetidCommand(key: key, lastId: lastId, entriesAdded: entriesAdded, maxDeletedId: maxDeletedId))
        return response
    }

    @inlinable
    public func xsetidCommand(key: RedisKey, lastId: String, entriesAdded: Int?, maxDeletedId: String?) -> RESPCommand {
        RESPCommand("XSETID", key, lastId, RESPWithToken("ENTRIESADDED", entriesAdded), RESPWithToken("MAXDELETEDID", maxDeletedId))
    }

    public enum XTRIMTrimStrategy: RESPRepresentable {
        case maxlen
        case minid

        @inlinable
        public func writeToRESPBuffer(_ buffer: inout ByteBuffer) {
            switch self {
            case .maxlen: "MAXLEN".writeToRESPBuffer(&buffer)
            case .minid: "MINID".writeToRESPBuffer(&buffer)
            }
        }
    }
    public enum XTRIMTrimOperator: RESPRepresentable {
        case equal
        case approximately

        @inlinable
        public func writeToRESPBuffer(_ buffer: inout ByteBuffer) {
            switch self {
            case .equal: "=".writeToRESPBuffer(&buffer)
            case .approximately: "~".writeToRESPBuffer(&buffer)
            }
        }
    }
    public struct XTRIMTrim: RESPRepresentable {
        @usableFromInline let strategy: XTRIMTrimStrategy
        @usableFromInline let `operator`: XTRIMTrimOperator?
        @usableFromInline let threshold: String
        @usableFromInline let count: Int?

        @inlinable
        public func writeToRESPBuffer(_ buffer: inout ByteBuffer) {
            self.strategy.writeToRESPBuffer(&buffer)
            self.operator.writeToRESPBuffer(&buffer)
            self.threshold.writeToRESPBuffer(&buffer)
            self.count.writeToRESPBuffer(&buffer)
        }
    }
    /// Deletes messages from the beginning of a stream.
    ///
    /// Version: 5.0.0
    /// Complexity: O(N), with N being the number of evicted entries. Constant times are very small however, since entries are organized in macro nodes containing multiple entries that can be released with a single deallocation.
    /// Categories: @write, @stream, @slow
    @inlinable
    public func xtrim(key: RedisKey, trim: XTRIMTrim) async throws -> RESP3Token {
        let response = try await send(xtrimCommand(key: key, trim: trim))
        return response
    }

    @inlinable
    public func xtrimCommand(key: RedisKey, trim: XTRIMTrim) -> RESPCommand {
        RESPCommand("XTRIM", key, trim)
    }

    public enum ZADDCondition: RESPRepresentable {
        case nx
        case xx

        @inlinable
        public func writeToRESPBuffer(_ buffer: inout ByteBuffer) {
            switch self {
            case .nx: "NX".writeToRESPBuffer(&buffer)
            case .xx: "XX".writeToRESPBuffer(&buffer)
            }
        }
    }
    public enum ZADDComparison: RESPRepresentable {
        case gt
        case lt

        @inlinable
        public func writeToRESPBuffer(_ buffer: inout ByteBuffer) {
            switch self {
            case .gt: "GT".writeToRESPBuffer(&buffer)
            case .lt: "LT".writeToRESPBuffer(&buffer)
            }
        }
    }
    public struct ZADDData: RESPRepresentable {
        @usableFromInline let score: Double
        @usableFromInline let member: String

        @inlinable
        public func writeToRESPBuffer(_ buffer: inout ByteBuffer) {
            self.score.writeToRESPBuffer(&buffer)
            self.member.writeToRESPBuffer(&buffer)
        }
    }
    /// Adds one or more members to a sorted set, or updates their scores. Creates the key if it doesn't exist.
    ///
    /// Version: 1.2.0
    /// Complexity: O(log(N)) for each item added, where N is the number of elements in the sorted set.
    /// Categories: @write, @sortedset, @fast
    @inlinable
    public func zadd(key: RedisKey, condition: ZADDCondition?, comparison: ZADDComparison?, change: Bool, increment: Bool, data: ZADDData...) async throws -> RESP3Token {
        let response = try await send(zaddCommand(key: key, condition: condition, comparison: comparison, change: change, increment: increment, data: data))
        return response
    }

    @inlinable
    public func zaddCommand(key: RedisKey, condition: ZADDCondition?, comparison: ZADDComparison?, change: Bool, increment: Bool, data: [ZADDData]) -> RESPCommand {
        RESPCommand("ZADD", key, condition, comparison, RedisPureToken("CH", change), RedisPureToken("INCR", increment), data)
    }

    /// Returns the number of members in a sorted set.
    ///
    /// Version: 1.2.0
    /// Complexity: O(1)
    /// Categories: @read, @sortedset, @fast
    @inlinable
    public func zcard(key: RedisKey) async throws -> RESP3Token {
        let response = try await send(zcardCommand(key: key))
        return response
    }

    @inlinable
    public func zcardCommand(key: RedisKey) -> RESPCommand {
        RESPCommand("ZCARD", key)
    }

    /// Returns the count of members in a sorted set that have scores within a range.
    ///
    /// Version: 2.0.0
    /// Complexity: O(log(N)) with N being the number of elements in the sorted set.
    /// Categories: @read, @sortedset, @fast
    @inlinable
    public func zcount(key: RedisKey, min: Double, max: Double) async throws -> RESP3Token {
        let response = try await send(zcountCommand(key: key, min: min, max: max))
        return response
    }

    @inlinable
    public func zcountCommand(key: RedisKey, min: Double, max: Double) -> RESPCommand {
        RESPCommand("ZCOUNT", key, min, max)
    }

    /// Returns the difference between multiple sorted sets.
    ///
    /// Version: 6.2.0
    /// Complexity: O(L + (N-K)log(N)) worst case where L is the total number of elements in all the sets, N is the size of the first set, and K is the size of the result set.
    /// Categories: @read, @sortedset, @slow
    @inlinable
    public func zdiff(numkeys: Int, key: RedisKey..., withscores: Bool) async throws -> RESP3Token {
        let response = try await send(zdiffCommand(numkeys: numkeys, key: key, withscores: withscores))
        return response
    }

    @inlinable
    public func zdiffCommand(numkeys: Int, key: [RedisKey], withscores: Bool) -> RESPCommand {
        RESPCommand("ZDIFF", numkeys, key, RedisPureToken("WITHSCORES", withscores))
    }

    /// Stores the difference of multiple sorted sets in a key.
    ///
    /// Version: 6.2.0
    /// Complexity: O(L + (N-K)log(N)) worst case where L is the total number of elements in all the sets, N is the size of the first set, and K is the size of the result set.
    /// Categories: @write, @sortedset, @slow
    @inlinable
    public func zdiffstore(destination: RedisKey, numkeys: Int, key: RedisKey...) async throws -> RESP3Token {
        let response = try await send(zdiffstoreCommand(destination: destination, numkeys: numkeys, key: key))
        return response
    }

    @inlinable
    public func zdiffstoreCommand(destination: RedisKey, numkeys: Int, key: [RedisKey]) -> RESPCommand {
        RESPCommand("ZDIFFSTORE", destination, numkeys, key)
    }

    /// Increments the score of a member in a sorted set.
    ///
    /// Version: 1.2.0
    /// Complexity: O(log(N)) where N is the number of elements in the sorted set.
    /// Categories: @write, @sortedset, @fast
    @inlinable
    public func zincrby(key: RedisKey, increment: Int, member: String) async throws -> RESP3Token {
        let response = try await send(zincrbyCommand(key: key, increment: increment, member: member))
        return response
    }

    @inlinable
    public func zincrbyCommand(key: RedisKey, increment: Int, member: String) -> RESPCommand {
        RESPCommand("ZINCRBY", key, increment, member)
    }

    public enum ZINTERAggregate: RESPRepresentable {
        case sum
        case min
        case max

        @inlinable
        public func writeToRESPBuffer(_ buffer: inout ByteBuffer) {
            switch self {
            case .sum: "SUM".writeToRESPBuffer(&buffer)
            case .min: "MIN".writeToRESPBuffer(&buffer)
            case .max: "MAX".writeToRESPBuffer(&buffer)
            }
        }
    }
    /// Returns the intersect of multiple sorted sets.
    ///
    /// Version: 6.2.0
    /// Complexity: O(N*K)+O(M*log(M)) worst case with N being the smallest input sorted set, K being the number of input sorted sets and M being the number of elements in the resulting sorted set.
    /// Categories: @read, @sortedset, @slow
    @inlinable
    public func zinter(numkeys: Int, key: RedisKey..., weight: Int..., aggregate: ZINTERAggregate?, withscores: Bool) async throws -> RESP3Token {
        let response = try await send(zinterCommand(numkeys: numkeys, key: key, weight: weight, aggregate: aggregate, withscores: withscores))
        return response
    }

    @inlinable
    public func zinterCommand(numkeys: Int, key: [RedisKey], weight: [Int], aggregate: ZINTERAggregate?, withscores: Bool) -> RESPCommand {
        RESPCommand("ZINTER", numkeys, key, RESPWithToken("WEIGHTS", weight), RESPWithToken("AGGREGATE", aggregate), RedisPureToken("WITHSCORES", withscores))
    }

    /// Returns the number of members of the intersect of multiple sorted sets.
    ///
    /// Version: 7.0.0
    /// Complexity: O(N*K) worst case with N being the smallest input sorted set, K being the number of input sorted sets.
    /// Categories: @read, @sortedset, @slow
    @inlinable
    public func zintercard(numkeys: Int, key: RedisKey..., limit: Int?) async throws -> RESP3Token {
        let response = try await send(zintercardCommand(numkeys: numkeys, key: key, limit: limit))
        return response
    }

    @inlinable
    public func zintercardCommand(numkeys: Int, key: [RedisKey], limit: Int?) -> RESPCommand {
        RESPCommand("ZINTERCARD", numkeys, key, RESPWithToken("LIMIT", limit))
    }

    public enum ZINTERSTOREAggregate: RESPRepresentable {
        case sum
        case min
        case max

        @inlinable
        public func writeToRESPBuffer(_ buffer: inout ByteBuffer) {
            switch self {
            case .sum: "SUM".writeToRESPBuffer(&buffer)
            case .min: "MIN".writeToRESPBuffer(&buffer)
            case .max: "MAX".writeToRESPBuffer(&buffer)
            }
        }
    }
    /// Stores the intersect of multiple sorted sets in a key.
    ///
    /// Version: 2.0.0
    /// Complexity: O(N*K)+O(M*log(M)) worst case with N being the smallest input sorted set, K being the number of input sorted sets and M being the number of elements in the resulting sorted set.
    /// Categories: @write, @sortedset, @slow
    @inlinable
    public func zinterstore(destination: RedisKey, numkeys: Int, key: RedisKey..., weight: Int..., aggregate: ZINTERSTOREAggregate?) async throws -> RESP3Token {
        let response = try await send(zinterstoreCommand(destination: destination, numkeys: numkeys, key: key, weight: weight, aggregate: aggregate))
        return response
    }

    @inlinable
    public func zinterstoreCommand(destination: RedisKey, numkeys: Int, key: [RedisKey], weight: [Int], aggregate: ZINTERSTOREAggregate?) -> RESPCommand {
        RESPCommand("ZINTERSTORE", destination, numkeys, key, RESPWithToken("WEIGHTS", weight), RESPWithToken("AGGREGATE", aggregate))
    }

    /// Returns the number of members in a sorted set within a lexicographical range.
    ///
    /// Version: 2.8.9
    /// Complexity: O(log(N)) with N being the number of elements in the sorted set.
    /// Categories: @read, @sortedset, @fast
    @inlinable
    public func zlexcount(key: RedisKey, min: String, max: String) async throws -> RESP3Token {
        let response = try await send(zlexcountCommand(key: key, min: min, max: max))
        return response
    }

    @inlinable
    public func zlexcountCommand(key: RedisKey, min: String, max: String) -> RESPCommand {
        RESPCommand("ZLEXCOUNT", key, min, max)
    }

    public enum ZMPOPWhere: RESPRepresentable {
        case min
        case max

        @inlinable
        public func writeToRESPBuffer(_ buffer: inout ByteBuffer) {
            switch self {
            case .min: "MIN".writeToRESPBuffer(&buffer)
            case .max: "MAX".writeToRESPBuffer(&buffer)
            }
        }
    }
    /// Returns the highest- or lowest-scoring members from one or more sorted sets after removing them. Deletes the sorted set if the last member was popped.
    ///
    /// Version: 7.0.0
    /// Complexity: O(K) + O(M*log(N)) where K is the number of provided keys, N being the number of elements in the sorted set, and M being the number of elements popped.
    /// Categories: @write, @sortedset, @slow
    @inlinable
    public func zmpop(numkeys: Int, key: RedisKey..., where: ZMPOPWhere, count: Int?) async throws -> RESP3Token {
        let response = try await send(zmpopCommand(numkeys: numkeys, key: key, where: `where`, count: count))
        return response
    }

    @inlinable
    public func zmpopCommand(numkeys: Int, key: [RedisKey], where: ZMPOPWhere, count: Int?) -> RESPCommand {
        RESPCommand("ZMPOP", numkeys, key, `where`, RESPWithToken("COUNT", count))
    }

    /// Returns the score of one or more members in a sorted set.
    ///
    /// Version: 6.2.0
    /// Complexity: O(N) where N is the number of members being requested.
    /// Categories: @read, @sortedset, @fast
    @inlinable
    public func zmscore(key: RedisKey, member: String...) async throws -> RESP3Token {
        let response = try await send(zmscoreCommand(key: key, member: member))
        return response
    }

    @inlinable
    public func zmscoreCommand(key: RedisKey, member: [String]) -> RESPCommand {
        RESPCommand("ZMSCORE", key, member)
    }

    /// Returns the highest-scoring members from a sorted set after removing them. Deletes the sorted set if the last member was popped.
    ///
    /// Version: 5.0.0
    /// Complexity: O(log(N)*M) with N being the number of elements in the sorted set, and M being the number of elements popped.
    /// Categories: @write, @sortedset, @fast
    @inlinable
    public func zpopmax(key: RedisKey, count: Int?) async throws -> RESP3Token {
        let response = try await send(zpopmaxCommand(key: key, count: count))
        return response
    }

    @inlinable
    public func zpopmaxCommand(key: RedisKey, count: Int?) -> RESPCommand {
        RESPCommand("ZPOPMAX", key, count)
    }

    /// Returns the lowest-scoring members from a sorted set after removing them. Deletes the sorted set if the last member was popped.
    ///
    /// Version: 5.0.0
    /// Complexity: O(log(N)*M) with N being the number of elements in the sorted set, and M being the number of elements popped.
    /// Categories: @write, @sortedset, @fast
    @inlinable
    public func zpopmin(key: RedisKey, count: Int?) async throws -> RESP3Token {
        let response = try await send(zpopminCommand(key: key, count: count))
        return response
    }

    @inlinable
    public func zpopminCommand(key: RedisKey, count: Int?) -> RESPCommand {
        RESPCommand("ZPOPMIN", key, count)
    }

    public struct ZRANDMEMBEROptions: RESPRepresentable {
        @usableFromInline let count: Int
        @usableFromInline let withscores: Bool

        @inlinable
        public func writeToRESPBuffer(_ buffer: inout ByteBuffer) {
            self.count.writeToRESPBuffer(&buffer)
            if self.withscores { "WITHSCORES".writeToRESPBuffer(&buffer) }
        }
    }
    /// Returns one or more random members from a sorted set.
    ///
    /// Version: 6.2.0
    /// Complexity: O(N) where N is the number of members returned
    /// Categories: @read, @sortedset, @slow
    @inlinable
    public func zrandmember(key: RedisKey, options: ZRANDMEMBEROptions?) async throws -> RESP3Token {
        let response = try await send(zrandmemberCommand(key: key, options: options))
        return response
    }

    @inlinable
    public func zrandmemberCommand(key: RedisKey, options: ZRANDMEMBEROptions?) -> RESPCommand {
        RESPCommand("ZRANDMEMBER", key, options)
    }

    public enum ZRANGESortby: RESPRepresentable {
        case byscore
        case bylex

        @inlinable
        public func writeToRESPBuffer(_ buffer: inout ByteBuffer) {
            switch self {
            case .byscore: "BYSCORE".writeToRESPBuffer(&buffer)
            case .bylex: "BYLEX".writeToRESPBuffer(&buffer)
            }
        }
    }
    public struct ZRANGELimit: RESPRepresentable {
        @usableFromInline let offset: Int
        @usableFromInline let count: Int

        @inlinable
        public func writeToRESPBuffer(_ buffer: inout ByteBuffer) {
            self.offset.writeToRESPBuffer(&buffer)
            self.count.writeToRESPBuffer(&buffer)
        }
    }
    /// Returns members in a sorted set within a range of indexes.
    ///
    /// Version: 1.2.0
    /// Complexity: O(log(N)+M) with N being the number of elements in the sorted set and M the number of elements returned.
    /// Categories: @read, @sortedset, @slow
    @inlinable
    public func zrange(key: RedisKey, start: String, stop: String, sortby: ZRANGESortby?, rev: Bool, limit: ZRANGELimit?, withscores: Bool) async throws -> RESP3Token {
        let response = try await send(zrangeCommand(key: key, start: start, stop: stop, sortby: sortby, rev: rev, limit: limit, withscores: withscores))
        return response
    }

    @inlinable
    public func zrangeCommand(key: RedisKey, start: String, stop: String, sortby: ZRANGESortby?, rev: Bool, limit: ZRANGELimit?, withscores: Bool) -> RESPCommand {
        RESPCommand("ZRANGE", key, start, stop, sortby, RedisPureToken("REV", rev), RESPWithToken("LIMIT", limit), RedisPureToken("WITHSCORES", withscores))
    }

    public struct ZRANGEBYLEXLimit: RESPRepresentable {
        @usableFromInline let offset: Int
        @usableFromInline let count: Int

        @inlinable
        public func writeToRESPBuffer(_ buffer: inout ByteBuffer) {
            self.offset.writeToRESPBuffer(&buffer)
            self.count.writeToRESPBuffer(&buffer)
        }
    }
    /// Returns members in a sorted set within a lexicographical range.
    ///
    /// Version: 2.8.9
    /// Complexity: O(log(N)+M) with N being the number of elements in the sorted set and M the number of elements being returned. If M is constant (e.g. always asking for the first 10 elements with LIMIT), you can consider it O(log(N)).
    /// Categories: @read, @sortedset, @slow
    @inlinable
    public func zrangebylex(key: RedisKey, min: String, max: String, limit: ZRANGEBYLEXLimit?) async throws -> RESP3Token {
        let response = try await send(zrangebylexCommand(key: key, min: min, max: max, limit: limit))
        return response
    }

    @inlinable
    public func zrangebylexCommand(key: RedisKey, min: String, max: String, limit: ZRANGEBYLEXLimit?) -> RESPCommand {
        RESPCommand("ZRANGEBYLEX", key, min, max, RESPWithToken("LIMIT", limit))
    }

    public struct ZRANGEBYSCORELimit: RESPRepresentable {
        @usableFromInline let offset: Int
        @usableFromInline let count: Int

        @inlinable
        public func writeToRESPBuffer(_ buffer: inout ByteBuffer) {
            self.offset.writeToRESPBuffer(&buffer)
            self.count.writeToRESPBuffer(&buffer)
        }
    }
    /// Returns members in a sorted set within a range of scores.
    ///
    /// Version: 1.0.5
    /// Complexity: O(log(N)+M) with N being the number of elements in the sorted set and M the number of elements being returned. If M is constant (e.g. always asking for the first 10 elements with LIMIT), you can consider it O(log(N)).
    /// Categories: @read, @sortedset, @slow
    @inlinable
    public func zrangebyscore(key: RedisKey, min: Double, max: Double, withscores: Bool, limit: ZRANGEBYSCORELimit?) async throws -> RESP3Token {
        let response = try await send(zrangebyscoreCommand(key: key, min: min, max: max, withscores: withscores, limit: limit))
        return response
    }

    @inlinable
    public func zrangebyscoreCommand(key: RedisKey, min: Double, max: Double, withscores: Bool, limit: ZRANGEBYSCORELimit?) -> RESPCommand {
        RESPCommand("ZRANGEBYSCORE", key, min, max, RedisPureToken("WITHSCORES", withscores), RESPWithToken("LIMIT", limit))
    }

    public enum ZRANGESTORESortby: RESPRepresentable {
        case byscore
        case bylex

        @inlinable
        public func writeToRESPBuffer(_ buffer: inout ByteBuffer) {
            switch self {
            case .byscore: "BYSCORE".writeToRESPBuffer(&buffer)
            case .bylex: "BYLEX".writeToRESPBuffer(&buffer)
            }
        }
    }
    public struct ZRANGESTORELimit: RESPRepresentable {
        @usableFromInline let offset: Int
        @usableFromInline let count: Int

        @inlinable
        public func writeToRESPBuffer(_ buffer: inout ByteBuffer) {
            self.offset.writeToRESPBuffer(&buffer)
            self.count.writeToRESPBuffer(&buffer)
        }
    }
    /// Stores a range of members from sorted set in a key.
    ///
    /// Version: 6.2.0
    /// Complexity: O(log(N)+M) with N being the number of elements in the sorted set and M the number of elements stored into the destination key.
    /// Categories: @write, @sortedset, @slow
    @inlinable
    public func zrangestore(dst: RedisKey, src: RedisKey, min: String, max: String, sortby: ZRANGESTORESortby?, rev: Bool, limit: ZRANGESTORELimit?) async throws -> RESP3Token {
        let response = try await send(zrangestoreCommand(dst: dst, src: src, min: min, max: max, sortby: sortby, rev: rev, limit: limit))
        return response
    }

    @inlinable
    public func zrangestoreCommand(dst: RedisKey, src: RedisKey, min: String, max: String, sortby: ZRANGESTORESortby?, rev: Bool, limit: ZRANGESTORELimit?) -> RESPCommand {
        RESPCommand("ZRANGESTORE", dst, src, min, max, sortby, RedisPureToken("REV", rev), RESPWithToken("LIMIT", limit))
    }

    /// Returns the index of a member in a sorted set ordered by ascending scores.
    ///
    /// Version: 2.0.0
    /// Complexity: O(log(N))
    /// Categories: @read, @sortedset, @fast
    @inlinable
    public func zrank(key: RedisKey, member: String, withscore: Bool) async throws -> RESP3Token {
        let response = try await send(zrankCommand(key: key, member: member, withscore: withscore))
        return response
    }

    @inlinable
    public func zrankCommand(key: RedisKey, member: String, withscore: Bool) -> RESPCommand {
        RESPCommand("ZRANK", key, member, RedisPureToken("WITHSCORE", withscore))
    }

    /// Removes one or more members from a sorted set. Deletes the sorted set if all members were removed.
    ///
    /// Version: 1.2.0
    /// Complexity: O(M*log(N)) with N being the number of elements in the sorted set and M the number of elements to be removed.
    /// Categories: @write, @sortedset, @fast
    @inlinable
    public func zrem(key: RedisKey, member: String...) async throws -> RESP3Token {
        let response = try await send(zremCommand(key: key, member: member))
        return response
    }

    @inlinable
    public func zremCommand(key: RedisKey, member: [String]) -> RESPCommand {
        RESPCommand("ZREM", key, member)
    }

    /// Removes members in a sorted set within a lexicographical range. Deletes the sorted set if all members were removed.
    ///
    /// Version: 2.8.9
    /// Complexity: O(log(N)+M) with N being the number of elements in the sorted set and M the number of elements removed by the operation.
    /// Categories: @write, @sortedset, @slow
    @inlinable
    public func zremrangebylex(key: RedisKey, min: String, max: String) async throws -> RESP3Token {
        let response = try await send(zremrangebylexCommand(key: key, min: min, max: max))
        return response
    }

    @inlinable
    public func zremrangebylexCommand(key: RedisKey, min: String, max: String) -> RESPCommand {
        RESPCommand("ZREMRANGEBYLEX", key, min, max)
    }

    /// Removes members in a sorted set within a range of indexes. Deletes the sorted set if all members were removed.
    ///
    /// Version: 2.0.0
    /// Complexity: O(log(N)+M) with N being the number of elements in the sorted set and M the number of elements removed by the operation.
    /// Categories: @write, @sortedset, @slow
    @inlinable
    public func zremrangebyrank(key: RedisKey, start: Int, stop: Int) async throws -> RESP3Token {
        let response = try await send(zremrangebyrankCommand(key: key, start: start, stop: stop))
        return response
    }

    @inlinable
    public func zremrangebyrankCommand(key: RedisKey, start: Int, stop: Int) -> RESPCommand {
        RESPCommand("ZREMRANGEBYRANK", key, start, stop)
    }

    /// Removes members in a sorted set within a range of scores. Deletes the sorted set if all members were removed.
    ///
    /// Version: 1.2.0
    /// Complexity: O(log(N)+M) with N being the number of elements in the sorted set and M the number of elements removed by the operation.
    /// Categories: @write, @sortedset, @slow
    @inlinable
    public func zremrangebyscore(key: RedisKey, min: Double, max: Double) async throws -> RESP3Token {
        let response = try await send(zremrangebyscoreCommand(key: key, min: min, max: max))
        return response
    }

    @inlinable
    public func zremrangebyscoreCommand(key: RedisKey, min: Double, max: Double) -> RESPCommand {
        RESPCommand("ZREMRANGEBYSCORE", key, min, max)
    }

    /// Returns members in a sorted set within a range of indexes in reverse order.
    ///
    /// Version: 1.2.0
    /// Complexity: O(log(N)+M) with N being the number of elements in the sorted set and M the number of elements returned.
    /// Categories: @read, @sortedset, @slow
    @inlinable
    public func zrevrange(key: RedisKey, start: Int, stop: Int, withscores: Bool) async throws -> RESP3Token {
        let response = try await send(zrevrangeCommand(key: key, start: start, stop: stop, withscores: withscores))
        return response
    }

    @inlinable
    public func zrevrangeCommand(key: RedisKey, start: Int, stop: Int, withscores: Bool) -> RESPCommand {
        RESPCommand("ZREVRANGE", key, start, stop, RedisPureToken("WITHSCORES", withscores))
    }

    public struct ZREVRANGEBYLEXLimit: RESPRepresentable {
        @usableFromInline let offset: Int
        @usableFromInline let count: Int

        @inlinable
        public func writeToRESPBuffer(_ buffer: inout ByteBuffer) {
            self.offset.writeToRESPBuffer(&buffer)
            self.count.writeToRESPBuffer(&buffer)
        }
    }
    /// Returns members in a sorted set within a lexicographical range in reverse order.
    ///
    /// Version: 2.8.9
    /// Complexity: O(log(N)+M) with N being the number of elements in the sorted set and M the number of elements being returned. If M is constant (e.g. always asking for the first 10 elements with LIMIT), you can consider it O(log(N)).
    /// Categories: @read, @sortedset, @slow
    @inlinable
    public func zrevrangebylex(key: RedisKey, max: String, min: String, limit: ZREVRANGEBYLEXLimit?) async throws -> RESP3Token {
        let response = try await send(zrevrangebylexCommand(key: key, max: max, min: min, limit: limit))
        return response
    }

    @inlinable
    public func zrevrangebylexCommand(key: RedisKey, max: String, min: String, limit: ZREVRANGEBYLEXLimit?) -> RESPCommand {
        RESPCommand("ZREVRANGEBYLEX", key, max, min, RESPWithToken("LIMIT", limit))
    }

    public struct ZREVRANGEBYSCORELimit: RESPRepresentable {
        @usableFromInline let offset: Int
        @usableFromInline let count: Int

        @inlinable
        public func writeToRESPBuffer(_ buffer: inout ByteBuffer) {
            self.offset.writeToRESPBuffer(&buffer)
            self.count.writeToRESPBuffer(&buffer)
        }
    }
    /// Returns members in a sorted set within a range of scores in reverse order.
    ///
    /// Version: 2.2.0
    /// Complexity: O(log(N)+M) with N being the number of elements in the sorted set and M the number of elements being returned. If M is constant (e.g. always asking for the first 10 elements with LIMIT), you can consider it O(log(N)).
    /// Categories: @read, @sortedset, @slow
    @inlinable
    public func zrevrangebyscore(key: RedisKey, max: Double, min: Double, withscores: Bool, limit: ZREVRANGEBYSCORELimit?) async throws -> RESP3Token {
        let response = try await send(zrevrangebyscoreCommand(key: key, max: max, min: min, withscores: withscores, limit: limit))
        return response
    }

    @inlinable
    public func zrevrangebyscoreCommand(key: RedisKey, max: Double, min: Double, withscores: Bool, limit: ZREVRANGEBYSCORELimit?) -> RESPCommand {
        RESPCommand("ZREVRANGEBYSCORE", key, max, min, RedisPureToken("WITHSCORES", withscores), RESPWithToken("LIMIT", limit))
    }

    /// Returns the index of a member in a sorted set ordered by descending scores.
    ///
    /// Version: 2.0.0
    /// Complexity: O(log(N))
    /// Categories: @read, @sortedset, @fast
    @inlinable
    public func zrevrank(key: RedisKey, member: String, withscore: Bool) async throws -> RESP3Token {
        let response = try await send(zrevrankCommand(key: key, member: member, withscore: withscore))
        return response
    }

    @inlinable
    public func zrevrankCommand(key: RedisKey, member: String, withscore: Bool) -> RESPCommand {
        RESPCommand("ZREVRANK", key, member, RedisPureToken("WITHSCORE", withscore))
    }

    /// Iterates over members and scores of a sorted set.
    ///
    /// Version: 2.8.0
    /// Complexity: O(1) for every call. O(N) for a complete iteration, including enough command calls for the cursor to return back to 0. N is the number of elements inside the collection.
    /// Categories: @read, @sortedset, @slow
    @inlinable
    public func zscan(key: RedisKey, cursor: Int, pattern: String?, count: Int?) async throws -> RESP3Token {
        let response = try await send(zscanCommand(key: key, cursor: cursor, pattern: pattern, count: count))
        return response
    }

    @inlinable
    public func zscanCommand(key: RedisKey, cursor: Int, pattern: String?, count: Int?) -> RESPCommand {
        RESPCommand("ZSCAN", key, cursor, RESPWithToken("MATCH", pattern), RESPWithToken("COUNT", count))
    }

    /// Returns the score of a member in a sorted set.
    ///
    /// Version: 1.2.0
    /// Complexity: O(1)
    /// Categories: @read, @sortedset, @fast
    @inlinable
    public func zscore(key: RedisKey, member: String) async throws -> RESP3Token {
        let response = try await send(zscoreCommand(key: key, member: member))
        return response
    }

    @inlinable
    public func zscoreCommand(key: RedisKey, member: String) -> RESPCommand {
        RESPCommand("ZSCORE", key, member)
    }

    public enum ZUNIONAggregate: RESPRepresentable {
        case sum
        case min
        case max

        @inlinable
        public func writeToRESPBuffer(_ buffer: inout ByteBuffer) {
            switch self {
            case .sum: "SUM".writeToRESPBuffer(&buffer)
            case .min: "MIN".writeToRESPBuffer(&buffer)
            case .max: "MAX".writeToRESPBuffer(&buffer)
            }
        }
    }
    /// Returns the union of multiple sorted sets.
    ///
    /// Version: 6.2.0
    /// Complexity: O(N)+O(M*log(M)) with N being the sum of the sizes of the input sorted sets, and M being the number of elements in the resulting sorted set.
    /// Categories: @read, @sortedset, @slow
    @inlinable
    public func zunion(numkeys: Int, key: RedisKey..., weight: Int..., aggregate: ZUNIONAggregate?, withscores: Bool) async throws -> RESP3Token {
        let response = try await send(zunionCommand(numkeys: numkeys, key: key, weight: weight, aggregate: aggregate, withscores: withscores))
        return response
    }

    @inlinable
    public func zunionCommand(numkeys: Int, key: [RedisKey], weight: [Int], aggregate: ZUNIONAggregate?, withscores: Bool) -> RESPCommand {
        RESPCommand("ZUNION", numkeys, key, RESPWithToken("WEIGHTS", weight), RESPWithToken("AGGREGATE", aggregate), RedisPureToken("WITHSCORES", withscores))
    }

    public enum ZUNIONSTOREAggregate: RESPRepresentable {
        case sum
        case min
        case max

        @inlinable
        public func writeToRESPBuffer(_ buffer: inout ByteBuffer) {
            switch self {
            case .sum: "SUM".writeToRESPBuffer(&buffer)
            case .min: "MIN".writeToRESPBuffer(&buffer)
            case .max: "MAX".writeToRESPBuffer(&buffer)
            }
        }
    }
    /// Stores the union of multiple sorted sets in a key.
    ///
    /// Version: 2.0.0
    /// Complexity: O(N)+O(M log(M)) with N being the sum of the sizes of the input sorted sets, and M being the number of elements in the resulting sorted set.
    /// Categories: @write, @sortedset, @slow
    @inlinable
    public func zunionstore(destination: RedisKey, numkeys: Int, key: RedisKey..., weight: Int..., aggregate: ZUNIONSTOREAggregate?) async throws -> RESP3Token {
        let response = try await send(zunionstoreCommand(destination: destination, numkeys: numkeys, key: key, weight: weight, aggregate: aggregate))
        return response
    }

    @inlinable
    public func zunionstoreCommand(destination: RedisKey, numkeys: Int, key: [RedisKey], weight: [Int], aggregate: ZUNIONSTOREAggregate?) -> RESPCommand {
        RESPCommand("ZUNIONSTORE", destination, numkeys, key, RESPWithToken("WEIGHTS", weight), RESPWithToken("AGGREGATE", aggregate))
    }

}
