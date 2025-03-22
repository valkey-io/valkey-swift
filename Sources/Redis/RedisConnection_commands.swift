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
        return RESPCommand("ACL")
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
        return RESPCommand("ACL", "CAT", category)
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
        return RESPCommand("ACL", "DELUSER", username)
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
        return RESPCommand("ACL", "DRYRUN", username, command, arg)
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
        return RESPCommand("ACL", "GENPASS", bits)
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
        return RESPCommand("ACL", "GETUSER", username)
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
        return RESPCommand("ACL", "HELP")
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
        return RESPCommand("ACL", "LIST")
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
        return RESPCommand("ACL", "LOAD")
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
        return RESPCommand("ACL", "LOG", operation)
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
        return RESPCommand("ACL", "SAVE")
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
        return RESPCommand("ACL", "SETUSER", username, rule)
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
        return RESPCommand("ACL", "USERS")
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
        return RESPCommand("ACL", "WHOAMI")
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
        return RESPCommand("APPEND", key, value)
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
        return RESPCommand("ASKING")
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
        return RESPCommand("AUTH", username, password)
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
        return RESPCommand("BGREWRITEAOF")
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
        return RESPCommand("BGSAVE", RedisPureToken("SCHEDULE", schedule))
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
        return RESPCommand("BITOP", operation, destkey, key)
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
        return RESPCommand("BLMOVE", source, destination, wherefrom, whereto, timeout)
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
        return RESPCommand("BLMPOP", timeout, numkeys, key, `where`, RESPWithToken("COUNT", count))
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
        return RESPCommand("BLPOP", key, timeout)
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
        return RESPCommand("BRPOP", key, timeout)
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
        return RESPCommand("BRPOPLPUSH", source, destination, timeout)
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
        return RESPCommand("BZMPOP", timeout, numkeys, key, `where`, RESPWithToken("COUNT", count))
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
        return RESPCommand("BZPOPMAX", key, timeout)
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
        return RESPCommand("BZPOPMIN", key, timeout)
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
        return RESPCommand("CLIENT")
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
        return RESPCommand("CLIENT", "CACHING", mode)
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
        return RESPCommand("CLIENT", "GETNAME")
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
        return RESPCommand("CLIENT", "GETREDIR")
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
        return RESPCommand("CLIENT", "HELP")
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
        return RESPCommand("CLIENT", "ID")
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
        return RESPCommand("CLIENT", "INFO")
    }

    public enum CLIENTKILLFilter: RESPRepresentable {
        case oldFormat(String)
        case newFormat(String)

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
        return RESPCommand("CLIENT", "KILL", filter)
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
        return RESPCommand("CLIENT", "LIST", RESPWithToken("TYPE", clientType), RESPWithToken("ID", clientId))
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
        return RESPCommand("CLIENT", "NO-EVICT", enabled)
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
        return RESPCommand("CLIENT", "NO-TOUCH", enabled)
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
        return RESPCommand("CLIENT", "PAUSE", timeout, mode)
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
        return RESPCommand("CLIENT", "REPLY", action)
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
        return RESPCommand("CLIENT", "SETINFO", attr)
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
        return RESPCommand("CLIENT", "SETNAME", connectionName)
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
        return RESPCommand("CLIENT", "TRACKING", status, RESPWithToken("REDIRECT", clientId), RESPWithToken("PREFIX", prefix), RedisPureToken("BCAST", bcast), RedisPureToken("OPTIN", optin), RedisPureToken("OPTOUT", optout), RedisPureToken("NOLOOP", noloop))
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
        return RESPCommand("CLIENT", "TRACKINGINFO")
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
        return RESPCommand("CLIENT", "UNBLOCK", clientId, unblockType)
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
        return RESPCommand("CLIENT", "UNPAUSE")
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
        return RESPCommand("CLUSTER")
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
        return RESPCommand("CLUSTER", "ADDSLOTS", slot)
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
        return RESPCommand("CLUSTER", "BUMPEPOCH")
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
        return RESPCommand("CLUSTER", "COUNT-FAILURE-REPORTS", nodeId)
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
        return RESPCommand("CLUSTER", "COUNTKEYSINSLOT", slot)
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
        return RESPCommand("CLUSTER", "DELSLOTS", slot)
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
        return RESPCommand("CLUSTER", "FAILOVER", options)
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
        return RESPCommand("CLUSTER", "FLUSHSLOTS")
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
        return RESPCommand("CLUSTER", "FORGET", nodeId)
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
        return RESPCommand("CLUSTER", "GETKEYSINSLOT", slot, count)
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
        return RESPCommand("CLUSTER", "HELP")
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
        return RESPCommand("CLUSTER", "INFO")
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
        return RESPCommand("CLUSTER", "KEYSLOT", key)
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
        return RESPCommand("CLUSTER", "LINKS")
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
        return RESPCommand("CLUSTER", "MEET", ip, port, clusterBusPort)
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
        return RESPCommand("CLUSTER", "MYID")
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
        return RESPCommand("CLUSTER", "MYSHARDID")
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
        return RESPCommand("CLUSTER", "NODES")
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
        return RESPCommand("CLUSTER", "REPLICAS", nodeId)
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
        return RESPCommand("CLUSTER", "REPLICATE", nodeId)
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
        return RESPCommand("CLUSTER", "RESET", resetType)
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
        return RESPCommand("CLUSTER", "SAVECONFIG")
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
        return RESPCommand("CLUSTER", "SET-CONFIG-EPOCH", configEpoch)
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
        return RESPCommand("CLUSTER", "SETSLOT", slot, subcommand)
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
        return RESPCommand("CLUSTER", "SHARDS")
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
        return RESPCommand("CLUSTER", "SLAVES", nodeId)
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
        return RESPCommand("CLUSTER", "SLOTS")
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
        return RESPCommand("COMMAND")
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
        return RESPCommand("COMMAND", "COUNT")
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
        return RESPCommand("COMMAND", "DOCS", commandName)
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
        return RESPCommand("COMMAND", "GETKEYS", command, arg)
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
        return RESPCommand("COMMAND", "GETKEYSANDFLAGS", command, arg)
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
        return RESPCommand("COMMAND", "HELP")
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
        return RESPCommand("COMMAND", "INFO", commandName)
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
        return RESPCommand("COMMAND", "LIST", RESPWithToken("FILTERBY", filterby))
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
        return RESPCommand("CONFIG")
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
        return RESPCommand("CONFIG", "GET", parameter)
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
        return RESPCommand("CONFIG", "HELP")
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
        return RESPCommand("CONFIG", "RESETSTAT")
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
        return RESPCommand("CONFIG", "REWRITE")
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
        return RESPCommand("COPY", source, destination, RESPWithToken("DB", destinationDb), RedisPureToken("REPLACE", replace))
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
        return RESPCommand("DBSIZE")
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
        return RESPCommand("DEBUG")
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
        return RESPCommand("DECR", key)
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
        return RESPCommand("DECRBY", key, decrement)
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
        return RESPCommand("DEL", key)
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
        return RESPCommand("DISCARD")
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
        return RESPCommand("DUMP", key)
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
        return RESPCommand("ECHO", message)
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
        return RESPCommand("EVAL", script, numkeys, key, arg)
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
        return RESPCommand("EVALSHA", sha1, numkeys, key, arg)
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
        return RESPCommand("EVALSHA_RO", sha1, numkeys, key, arg)
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
        return RESPCommand("EVAL_RO", script, numkeys, key, arg)
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
        return RESPCommand("EXEC")
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
        return RESPCommand("EXISTS", key)
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
        return RESPCommand("EXPIRE", key, seconds, condition)
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
        return RESPCommand("EXPIREAT", key, unixTimeSeconds, condition)
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
        return RESPCommand("EXPIRETIME", key)
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
        return RESPCommand("FCALL", function, numkeys, key, arg)
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
        return RESPCommand("FCALL_RO", function, numkeys, key, arg)
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
        return RESPCommand("FLUSHALL", flushType)
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
        return RESPCommand("FLUSHDB", flushType)
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
        return RESPCommand("FUNCTION")
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
        return RESPCommand("FUNCTION", "DELETE", libraryName)
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
        return RESPCommand("FUNCTION", "DUMP")
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
        return RESPCommand("FUNCTION", "FLUSH", flushType)
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
        return RESPCommand("FUNCTION", "HELP")
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
        return RESPCommand("FUNCTION", "KILL")
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
        return RESPCommand("FUNCTION", "LIST", RESPWithToken("LIBRARYNAME", libraryNamePattern), RedisPureToken("WITHCODE", withcode))
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
        return RESPCommand("FUNCTION", "LOAD", RedisPureToken("REPLACE", replace), functionCode)
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
        return RESPCommand("FUNCTION", "RESTORE", serializedValue, policy)
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
        return RESPCommand("FUNCTION", "STATS")
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
        return RESPCommand("GEODIST", key, member1, member2, unit)
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
        return RESPCommand("GEOHASH", key, member)
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
        return RESPCommand("GEOPOS", key, member)
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
        return RESPCommand("GET", key)
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
        return RESPCommand("GETBIT", key, offset)
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
        return RESPCommand("GETDEL", key)
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
        return RESPCommand("GETEX", key, expiration)
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
        return RESPCommand("GETRANGE", key, start, end)
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
        return RESPCommand("GETSET", key, value)
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
        return RESPCommand("HDEL", key, field)
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
        return RESPCommand("HEXISTS", key, field)
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
        return RESPCommand("HGET", key, field)
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
        return RESPCommand("HGETALL", key)
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
        return RESPCommand("HINCRBY", key, field, increment)
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
        return RESPCommand("HINCRBYFLOAT", key, field, increment)
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
        return RESPCommand("HKEYS", key)
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
        return RESPCommand("HLEN", key)
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
        return RESPCommand("HMGET", key, field)
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
        return RESPCommand("HSCAN", key, cursor, RESPWithToken("MATCH", pattern), RESPWithToken("COUNT", count))
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
        return RESPCommand("HSETNX", key, field, value)
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
        return RESPCommand("HSTRLEN", key, field)
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
        return RESPCommand("HVALS", key)
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
        return RESPCommand("INCR", key)
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
        return RESPCommand("INCRBY", key, increment)
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
        return RESPCommand("INCRBYFLOAT", key, increment)
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
        return RESPCommand("INFO", section)
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
        return RESPCommand("KEYS", pattern)
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
        return RESPCommand("LASTSAVE")
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
        return RESPCommand("LATENCY")
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
        return RESPCommand("LATENCY", "DOCTOR")
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
        return RESPCommand("LATENCY", "GRAPH", event)
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
        return RESPCommand("LATENCY", "HELP")
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
        return RESPCommand("LATENCY", "HISTOGRAM", command)
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
        return RESPCommand("LATENCY", "HISTORY", event)
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
        return RESPCommand("LATENCY", "LATEST")
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
        return RESPCommand("LATENCY", "RESET", event)
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
        return RESPCommand("LCS", key1, key2, RedisPureToken("LEN", len), RedisPureToken("IDX", idx), RESPWithToken("MINMATCHLEN", minMatchLen), RedisPureToken("WITHMATCHLEN", withmatchlen))
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
        return RESPCommand("LINDEX", key, index)
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
        return RESPCommand("LINSERT", key, `where`, pivot, element)
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
        return RESPCommand("LLEN", key)
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
        return RESPCommand("LMOVE", source, destination, wherefrom, whereto)
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
        return RESPCommand("LMPOP", numkeys, key, `where`, RESPWithToken("COUNT", count))
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
        return RESPCommand("LOLWUT", RESPWithToken("VERSION", version))
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
        return RESPCommand("LPOP", key, count)
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
        return RESPCommand("LPOS", key, element, RESPWithToken("RANK", rank), RESPWithToken("COUNT", numMatches), RESPWithToken("MAXLEN", len))
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
        return RESPCommand("LPUSH", key, element)
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
        return RESPCommand("LPUSHX", key, element)
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
        return RESPCommand("LRANGE", key, start, stop)
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
        return RESPCommand("LREM", key, count, element)
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
        return RESPCommand("LSET", key, index, element)
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
        return RESPCommand("LTRIM", key, start, stop)
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
        return RESPCommand("MEMORY")
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
        return RESPCommand("MEMORY", "DOCTOR")
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
        return RESPCommand("MEMORY", "HELP")
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
        return RESPCommand("MEMORY", "MALLOC-STATS")
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
        return RESPCommand("MEMORY", "PURGE")
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
        return RESPCommand("MEMORY", "STATS")
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
        return RESPCommand("MEMORY", "USAGE", key, RESPWithToken("SAMPLES", count))
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
        return RESPCommand("MGET", key)
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
        return RESPCommand("MODULE")
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
        return RESPCommand("MODULE", "HELP")
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
        return RESPCommand("MODULE", "LIST")
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
        return RESPCommand("MODULE", "LOAD", path, arg)
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
        return RESPCommand("MODULE", "UNLOAD", name)
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
        return RESPCommand("MONITOR")
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
        return RESPCommand("MOVE", key, db)
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
        return RESPCommand("MULTI")
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
        return RESPCommand("OBJECT")
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
        return RESPCommand("OBJECT", "ENCODING", key)
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
        return RESPCommand("OBJECT", "FREQ", key)
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
        return RESPCommand("OBJECT", "HELP")
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
        return RESPCommand("OBJECT", "IDLETIME", key)
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
        return RESPCommand("OBJECT", "REFCOUNT", key)
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
        return RESPCommand("PERSIST", key)
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
        return RESPCommand("PEXPIRE", key, milliseconds, condition)
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
        return RESPCommand("PEXPIREAT", key, unixTimeMilliseconds, condition)
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
        return RESPCommand("PEXPIRETIME", key)
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
        return RESPCommand("PFADD", key, element)
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
        return RESPCommand("PFCOUNT", key)
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
        return RESPCommand("PFDEBUG", subcommand, key)
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
        return RESPCommand("PFMERGE", destkey, sourcekey)
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
        return RESPCommand("PFSELFTEST")
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
        return RESPCommand("PING", message)
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
        return RESPCommand("PSETEX", key, milliseconds, value)
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
        return RESPCommand("PSUBSCRIBE", pattern)
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
        return RESPCommand("PSYNC", replicationid, offset)
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
        return RESPCommand("PTTL", key)
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
        return RESPCommand("PUBLISH", channel, message)
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
        return RESPCommand("PUBSUB")
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
        return RESPCommand("PUBSUB", "CHANNELS", pattern)
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
        return RESPCommand("PUBSUB", "HELP")
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
        return RESPCommand("PUBSUB", "NUMPAT")
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
        return RESPCommand("PUBSUB", "NUMSUB", channel)
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
        return RESPCommand("PUBSUB", "SHARDCHANNELS", pattern)
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
        return RESPCommand("PUBSUB", "SHARDNUMSUB", shardchannel)
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
        return RESPCommand("PUNSUBSCRIBE", pattern)
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
        return RESPCommand("QUIT")
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
        return RESPCommand("RANDOMKEY")
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
        return RESPCommand("READONLY")
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
        return RESPCommand("READWRITE")
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
        return RESPCommand("RENAME", key, newkey)
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
        return RESPCommand("RENAMENX", key, newkey)
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
        return RESPCommand("REPLCONF")
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
        return RESPCommand("RESET")
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
        return RESPCommand("RESTORE", key, ttl, serializedValue, RedisPureToken("REPLACE", replace), RedisPureToken("ABSTTL", absttl), RESPWithToken("IDLETIME", seconds), RESPWithToken("FREQ", frequency))
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
        return RESPCommand("RESTORE-ASKING", key, ttl, serializedValue, RedisPureToken("REPLACE", replace), RedisPureToken("ABSTTL", absttl), RESPWithToken("IDLETIME", seconds), RESPWithToken("FREQ", frequency))
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
        return RESPCommand("ROLE")
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
        return RESPCommand("RPOP", key, count)
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
        return RESPCommand("RPOPLPUSH", source, destination)
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
        return RESPCommand("RPUSH", key, element)
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
        return RESPCommand("RPUSHX", key, element)
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
        return RESPCommand("SADD", key, member)
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
        return RESPCommand("SAVE")
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
        return RESPCommand("SCAN", cursor, RESPWithToken("MATCH", pattern), RESPWithToken("COUNT", count), RESPWithToken("TYPE", type))
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
        return RESPCommand("SCARD", key)
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
        return RESPCommand("SCRIPT")
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
        return RESPCommand("SCRIPT", "DEBUG", mode)
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
        return RESPCommand("SCRIPT", "EXISTS", sha1)
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
        return RESPCommand("SCRIPT", "FLUSH", flushType)
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
        return RESPCommand("SCRIPT", "HELP")
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
        return RESPCommand("SCRIPT", "KILL")
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
        return RESPCommand("SCRIPT", "LOAD", script)
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
        return RESPCommand("SDIFF", key)
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
        return RESPCommand("SDIFFSTORE", destination, key)
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
        return RESPCommand("SELECT", index)
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
        return RESPCommand("SET", key, value, condition, RedisPureToken("GET", get), expiration)
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
        return RESPCommand("SETBIT", key, offset, value)
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
        return RESPCommand("SETEX", key, seconds, value)
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
        return RESPCommand("SETNX", key, value)
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
        return RESPCommand("SETRANGE", key, offset, value)
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
        return RESPCommand("SHUTDOWN", saveSelector, RedisPureToken("NOW", now), RedisPureToken("FORCE", force), RedisPureToken("ABORT", abort))
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
        return RESPCommand("SINTER", key)
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
        return RESPCommand("SINTERCARD", numkeys, key, RESPWithToken("LIMIT", limit))
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
        return RESPCommand("SINTERSTORE", destination, key)
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
        return RESPCommand("SISMEMBER", key, member)
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
        return RESPCommand("SLOWLOG")
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
        return RESPCommand("SLOWLOG", "GET", count)
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
        return RESPCommand("SLOWLOG", "HELP")
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
        return RESPCommand("SLOWLOG", "LEN")
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
        return RESPCommand("SLOWLOG", "RESET")
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
        return RESPCommand("SMEMBERS", key)
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
        return RESPCommand("SMISMEMBER", key, member)
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
        return RESPCommand("SMOVE", source, destination, member)
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
        return RESPCommand("SPOP", key, count)
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
        return RESPCommand("SPUBLISH", shardchannel, message)
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
        return RESPCommand("SRANDMEMBER", key, count)
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
        return RESPCommand("SREM", key, member)
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
        return RESPCommand("SSCAN", key, cursor, RESPWithToken("MATCH", pattern), RESPWithToken("COUNT", count))
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
        return RESPCommand("SSUBSCRIBE", shardchannel)
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
        return RESPCommand("STRLEN", key)
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
        return RESPCommand("SUBSCRIBE", channel)
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
        return RESPCommand("SUBSTR", key, start, end)
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
        return RESPCommand("SUNION", key)
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
        return RESPCommand("SUNIONSTORE", destination, key)
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
        return RESPCommand("SUNSUBSCRIBE", shardchannel)
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
        return RESPCommand("SWAPDB", index1, index2)
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
        return RESPCommand("SYNC")
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
        return RESPCommand("TIME")
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
        return RESPCommand("TOUCH", key)
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
        return RESPCommand("TTL", key)
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
        return RESPCommand("TYPE", key)
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
        return RESPCommand("UNLINK", key)
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
        return RESPCommand("UNSUBSCRIBE", channel)
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
        return RESPCommand("UNWATCH")
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
        return RESPCommand("WAIT", numreplicas, timeout)
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
        return RESPCommand("WAITAOF", numlocal, numreplicas, timeout)
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
        return RESPCommand("WATCH", key)
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
        return RESPCommand("XACK", key, group, id)
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
        return RESPCommand("XAUTOCLAIM", key, group, consumer, minIdleTime, start, RESPWithToken("COUNT", count), RedisPureToken("JUSTID", justid))
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
        return RESPCommand("XCLAIM", key, group, consumer, minIdleTime, id, RESPWithToken("IDLE", ms), RESPWithToken("TIME", unixTimeMilliseconds), RESPWithToken("RETRYCOUNT", count), RedisPureToken("FORCE", force), RedisPureToken("JUSTID", justid), RESPWithToken("LASTID", lastid))
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
        return RESPCommand("XDEL", key, id)
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
        return RESPCommand("XGROUP")
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
        return RESPCommand("XGROUP", "CREATE", key, group, idSelector, RedisPureToken("MKSTREAM", mkstream), RESPWithToken("ENTRIESREAD", entriesRead))
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
        return RESPCommand("XGROUP", "CREATECONSUMER", key, group, consumer)
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
        return RESPCommand("XGROUP", "DELCONSUMER", key, group, consumer)
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
        return RESPCommand("XGROUP", "DESTROY", key, group)
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
        return RESPCommand("XGROUP", "HELP")
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
        return RESPCommand("XGROUP", "SETID", key, group, idSelector, RESPWithToken("ENTRIESREAD", entriesread))
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
        return RESPCommand("XINFO")
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
        return RESPCommand("XINFO", "CONSUMERS", key, group)
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
        return RESPCommand("XINFO", "GROUPS", key)
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
        return RESPCommand("XINFO", "HELP")
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
        return RESPCommand("XLEN", key)
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
        return RESPCommand("XRANGE", key, start, end, RESPWithToken("COUNT", count))
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
        return RESPCommand("XREVRANGE", key, end, start, RESPWithToken("COUNT", count))
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
        return RESPCommand("XSETID", key, lastId, RESPWithToken("ENTRIESADDED", entriesAdded), RESPWithToken("MAXDELETEDID", maxDeletedId))
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
        return RESPCommand("ZCARD", key)
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
        return RESPCommand("ZCOUNT", key, min, max)
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
        return RESPCommand("ZDIFF", numkeys, key, RedisPureToken("WITHSCORES", withscores))
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
        return RESPCommand("ZDIFFSTORE", destination, numkeys, key)
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
        return RESPCommand("ZINCRBY", key, increment, member)
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
        return RESPCommand("ZINTER", numkeys, key, RESPWithToken("WEIGHTS", weight), RESPWithToken("AGGREGATE", aggregate), RedisPureToken("WITHSCORES", withscores))
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
        return RESPCommand("ZINTERCARD", numkeys, key, RESPWithToken("LIMIT", limit))
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
        return RESPCommand("ZINTERSTORE", destination, numkeys, key, RESPWithToken("WEIGHTS", weight), RESPWithToken("AGGREGATE", aggregate))
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
        return RESPCommand("ZLEXCOUNT", key, min, max)
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
        return RESPCommand("ZMPOP", numkeys, key, `where`, RESPWithToken("COUNT", count))
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
        return RESPCommand("ZMSCORE", key, member)
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
        return RESPCommand("ZPOPMAX", key, count)
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
        return RESPCommand("ZPOPMIN", key, count)
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
        return RESPCommand("ZRANK", key, member, RedisPureToken("WITHSCORE", withscore))
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
        return RESPCommand("ZREM", key, member)
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
        return RESPCommand("ZREMRANGEBYLEX", key, min, max)
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
        return RESPCommand("ZREMRANGEBYRANK", key, start, stop)
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
        return RESPCommand("ZREMRANGEBYSCORE", key, min, max)
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
        return RESPCommand("ZREVRANGE", key, start, stop, RedisPureToken("WITHSCORES", withscores))
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
        return RESPCommand("ZREVRANK", key, member, RedisPureToken("WITHSCORE", withscore))
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
        return RESPCommand("ZSCAN", key, cursor, RESPWithToken("MATCH", pattern), RESPWithToken("COUNT", count))
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
        return RESPCommand("ZSCORE", key, member)
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
        return RESPCommand("ZUNION", numkeys, key, RESPWithToken("WEIGHTS", weight), RESPWithToken("AGGREGATE", aggregate), RedisPureToken("WITHSCORES", withscores))
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
        return RESPCommand("ZUNIONSTORE", destination, numkeys, key, RESPWithToken("WEIGHTS", weight), RESPWithToken("AGGREGATE", aggregate))
    }

}
