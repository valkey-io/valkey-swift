import NIOCore
import RESP3

#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

extension RedisConnection {
    /// A container for Access List Control commands.
    /// Version: 6.0.0
    /// Complexity: Depends on subcommand.
    /// Categories: @slow
    public func acl() async throws -> RESP3Token {
        let response = try await send(aclCommand())
        return response
    }
    @inlinable
    public func aclCommand() -> RESP3Command {
        .init("ACL", arguments: [])
    }

    /// Lists the ACL categories, or the commands inside a category.
    /// Version: 6.0.0
    /// Complexity: O(1) since the categories and commands are a fixed set.
    /// Categories: @slow
    public func aclCat(category: String) async throws -> RESP3Token {
        let response = try await send(aclCatCommand(category: category))
        return response
    }
    @inlinable
    public func aclCatCommand(category: String) -> RESP3Command {
        .init("ACL", arguments: ["CAT", category])
    }

    /// Deletes ACL users, and terminates their connections.
    /// Version: 6.0.0
    /// Complexity: O(1) amortized time considering the typical user.
    /// Categories: @admin, @slow, @dangerous
    public func aclDeluser(username: String...) async throws -> RESP3Token {
        let response = try await send(aclDeluserCommand(username: username))
        return response
    }
    @inlinable
    public func aclDeluserCommand(username: [String]) -> RESP3Command {
        var arguments: [String] = ["DELUSER"]
        arguments.append(contentsOf: username)
        return .init("ACL", arguments: arguments)
    }

    /// Simulates the execution of a command by a user, without executing the command.
    /// Version: 7.0.0
    /// Complexity: O(1).
    /// Categories: @admin, @slow, @dangerous
    public func aclDryrun(username: String, command: String, arg: String...) async throws -> RESP3Token {
        let response = try await send(aclDryrunCommand(username: username, command: command, arg: arg))
        return response
    }
    @inlinable
    public func aclDryrunCommand(username: String, command: String, arg: [String]) -> RESP3Command {
        var arguments: [String] = ["DRYRUN"]
        arguments.append(username)
        arguments.append(command)
        arguments.append(contentsOf: arg)
        return .init("ACL", arguments: arguments)
    }

    /// Generates a pseudorandom, secure password that can be used to identify ACL users.
    /// Version: 6.0.0
    /// Complexity: O(1)
    /// Categories: @slow
    public func aclGenpass(bits: Int) async throws -> RESP3Token {
        let response = try await send(aclGenpassCommand(bits: bits))
        return response
    }
    @inlinable
    public func aclGenpassCommand(bits: Int) -> RESP3Command {
        .init("ACL", arguments: ["GENPASS", bits.description])
    }

    /// Lists the ACL rules of a user.
    /// Version: 6.0.0
    /// Complexity: O(N). Where N is the number of password, command and pattern rules that the user has.
    /// Categories: @admin, @slow, @dangerous
    public func aclGetuser(username: String) async throws -> RESP3Token {
        let response = try await send(aclGetuserCommand(username: username))
        return response
    }
    @inlinable
    public func aclGetuserCommand(username: String) -> RESP3Command {
        .init("ACL", arguments: ["GETUSER", username])
    }

    /// Returns helpful text about the different subcommands.
    /// Version: 6.0.0
    /// Complexity: O(1)
    /// Categories: @slow
    public func aclHelp() async throws -> RESP3Token {
        let response = try await send(aclHelpCommand())
        return response
    }
    @inlinable
    public func aclHelpCommand() -> RESP3Command {
        .init("ACL", arguments: ["HELP"])
    }

    /// Dumps the effective rules in ACL file format.
    /// Version: 6.0.0
    /// Complexity: O(N). Where N is the number of configured users.
    /// Categories: @admin, @slow, @dangerous
    public func aclList() async throws -> RESP3Token {
        let response = try await send(aclListCommand())
        return response
    }
    @inlinable
    public func aclListCommand() -> RESP3Command {
        .init("ACL", arguments: ["LIST"])
    }

    /// Reloads the rules from the configured ACL file.
    /// Version: 6.0.0
    /// Complexity: O(N). Where N is the number of configured users.
    /// Categories: @admin, @slow, @dangerous
    public func aclLoad() async throws -> RESP3Token {
        let response = try await send(aclLoadCommand())
        return response
    }
    @inlinable
    public func aclLoadCommand() -> RESP3Command {
        .init("ACL", arguments: ["LOAD"])
    }

    /// Saves the effective ACL rules in the configured ACL file.
    /// Version: 6.0.0
    /// Complexity: O(N). Where N is the number of configured users.
    /// Categories: @admin, @slow, @dangerous
    public func aclSave() async throws -> RESP3Token {
        let response = try await send(aclSaveCommand())
        return response
    }
    @inlinable
    public func aclSaveCommand() -> RESP3Command {
        .init("ACL", arguments: ["SAVE"])
    }

    /// Creates and modifies an ACL user and its rules.
    /// Version: 6.0.0
    /// Complexity: O(N). Where N is the number of rules provided.
    /// Categories: @admin, @slow, @dangerous
    public func aclSetuser(username: String, rule: String...) async throws -> RESP3Token {
        let response = try await send(aclSetuserCommand(username: username, rule: rule))
        return response
    }
    @inlinable
    public func aclSetuserCommand(username: String, rule: [String]) -> RESP3Command {
        var arguments: [String] = ["SETUSER"]
        arguments.append(username)
        arguments.append(contentsOf: rule)
        return .init("ACL", arguments: arguments)
    }

    /// Lists all ACL users.
    /// Version: 6.0.0
    /// Complexity: O(N). Where N is the number of configured users.
    /// Categories: @admin, @slow, @dangerous
    public func aclUsers() async throws -> RESP3Token {
        let response = try await send(aclUsersCommand())
        return response
    }
    @inlinable
    public func aclUsersCommand() -> RESP3Command {
        .init("ACL", arguments: ["USERS"])
    }

    /// Returns the authenticated username of the current connection.
    /// Version: 6.0.0
    /// Complexity: O(1)
    /// Categories: @slow
    public func aclWhoami() async throws -> RESP3Token {
        let response = try await send(aclWhoamiCommand())
        return response
    }
    @inlinable
    public func aclWhoamiCommand() -> RESP3Command {
        .init("ACL", arguments: ["WHOAMI"])
    }

    /// Appends a string to the value of a key. Creates the key if it doesn't exist.
    /// Version: 2.0.0
    /// Complexity: O(1). The amortized time complexity is O(1) assuming the appended value is small and the already present value is of any size, since the dynamic string library used by Redis will double the free space available on every reallocation.
    /// Categories: @write, @string, @fast
    public func append(key: RedisKey, value: String) async throws -> RESP3Token {
        let response = try await send(appendCommand(key: key, value: value))
        return response
    }
    @inlinable
    public func appendCommand(key: RedisKey, value: String) -> RESP3Command {
        .init("APPEND", arguments: [key.description, value])
    }

    /// Signals that a cluster client is following an -ASK redirect.
    /// Version: 3.0.0
    /// Complexity: O(1)
    /// Categories: @fast, @connection
    public func asking() async throws -> RESP3Token {
        let response = try await send(askingCommand())
        return response
    }
    @inlinable
    public func askingCommand() -> RESP3Command {
        .init("ASKING", arguments: [])
    }

    /// Authenticates the connection.
    /// Version: 1.0.0
    /// Complexity: O(N) where N is the number of passwords defined for the user
    /// Categories: @fast, @connection
    public func auth(username: String, password: String) async throws -> RESP3Token {
        let response = try await send(authCommand(username: username, password: password))
        return response
    }
    @inlinable
    public func authCommand(username: String, password: String) -> RESP3Command {
        .init("AUTH", arguments: [username, password])
    }

    /// Asynchronously rewrites the append-only file to disk.
    /// Version: 1.0.0
    /// Complexity: O(1)
    /// Categories: @admin, @slow, @dangerous
    public func bgrewriteaof() async throws -> RESP3Token {
        let response = try await send(bgrewriteaofCommand())
        return response
    }
    @inlinable
    public func bgrewriteaofCommand() -> RESP3Command {
        .init("BGREWRITEAOF", arguments: [])
    }

    /// Asynchronously saves the database(s) to disk.
    /// Version: 1.0.0
    /// Complexity: O(1)
    /// Categories: @admin, @slow, @dangerous
    public func bgsave(schedule: Bool) async throws -> RESP3Token {
        let response = try await send(bgsaveCommand(schedule: schedule))
        return response
    }
    @inlinable
    public func bgsaveCommand(schedule: Bool) -> RESP3Command {
        .init("BGSAVE", arguments: [schedule.description])
    }

    /// Removes and returns the first element in a list. Blocks until an element is available otherwise. Deletes the list if the last element was popped.
    /// Version: 2.0.0
    /// Complexity: O(N) where N is the number of provided keys.
    /// Categories: @write, @list, @slow, @blocking
    public func blpop(key: RedisKey..., timeout: Double) async throws -> RESP3Token {
        let response = try await send(blpopCommand(key: key, timeout: timeout))
        return response
    }
    @inlinable
    public func blpopCommand(key: [RedisKey], timeout: Double) -> RESP3Command {
        var arguments: [String] = key.map(\.description)
        arguments.append(timeout.description)
        return .init("BLPOP", arguments: arguments)
    }

    /// Removes and returns the last element in a list. Blocks until an element is available otherwise. Deletes the list if the last element was popped.
    /// Version: 2.0.0
    /// Complexity: O(N) where N is the number of provided keys.
    /// Categories: @write, @list, @slow, @blocking
    public func brpop(key: RedisKey..., timeout: Double) async throws -> RESP3Token {
        let response = try await send(brpopCommand(key: key, timeout: timeout))
        return response
    }
    @inlinable
    public func brpopCommand(key: [RedisKey], timeout: Double) -> RESP3Command {
        var arguments: [String] = key.map(\.description)
        arguments.append(timeout.description)
        return .init("BRPOP", arguments: arguments)
    }

    /// Pops an element from a list, pushes it to another list and returns it. Block until an element is available otherwise. Deletes the list if the last element was popped.
    /// Version: 2.2.0
    /// Complexity: O(1)
    /// Categories: @write, @list, @slow, @blocking
    public func brpoplpush(source: RedisKey, destination: RedisKey, timeout: Double) async throws -> RESP3Token {
        let response = try await send(brpoplpushCommand(source: source, destination: destination, timeout: timeout))
        return response
    }
    @inlinable
    public func brpoplpushCommand(source: RedisKey, destination: RedisKey, timeout: Double) -> RESP3Command {
        .init("BRPOPLPUSH", arguments: [source.description, destination.description, timeout.description])
    }

    /// Removes and returns the member with the highest score from one or more sorted sets. Blocks until a member available otherwise.  Deletes the sorted set if the last element was popped.
    /// Version: 5.0.0
    /// Complexity: O(log(N)) with N being the number of elements in the sorted set.
    /// Categories: @write, @sortedset, @fast, @blocking
    public func bzpopmax(key: RedisKey..., timeout: Double) async throws -> RESP3Token {
        let response = try await send(bzpopmaxCommand(key: key, timeout: timeout))
        return response
    }
    @inlinable
    public func bzpopmaxCommand(key: [RedisKey], timeout: Double) -> RESP3Command {
        var arguments: [String] = key.map(\.description)
        arguments.append(timeout.description)
        return .init("BZPOPMAX", arguments: arguments)
    }

    /// Removes and returns the member with the lowest score from one or more sorted sets. Blocks until a member is available otherwise. Deletes the sorted set if the last element was popped.
    /// Version: 5.0.0
    /// Complexity: O(log(N)) with N being the number of elements in the sorted set.
    /// Categories: @write, @sortedset, @fast, @blocking
    public func bzpopmin(key: RedisKey..., timeout: Double) async throws -> RESP3Token {
        let response = try await send(bzpopminCommand(key: key, timeout: timeout))
        return response
    }
    @inlinable
    public func bzpopminCommand(key: [RedisKey], timeout: Double) -> RESP3Command {
        var arguments: [String] = key.map(\.description)
        arguments.append(timeout.description)
        return .init("BZPOPMIN", arguments: arguments)
    }

    /// A container for client connection commands.
    /// Version: 2.4.0
    /// Complexity: Depends on subcommand.
    /// Categories: @slow
    public func client() async throws -> RESP3Token {
        let response = try await send(clientCommand())
        return response
    }
    @inlinable
    public func clientCommand() -> RESP3Command {
        .init("CLIENT", arguments: [])
    }

    /// Returns the name of the connection.
    /// Version: 2.6.9
    /// Complexity: O(1)
    /// Categories: @slow, @connection
    public func clientGetname() async throws -> RESP3Token {
        let response = try await send(clientGetnameCommand())
        return response
    }
    @inlinable
    public func clientGetnameCommand() -> RESP3Command {
        .init("CLIENT", arguments: ["GETNAME"])
    }

    /// Returns the client ID to which the connection's tracking notifications are redirected.
    /// Version: 6.0.0
    /// Complexity: O(1)
    /// Categories: @slow, @connection
    public func clientGetredir() async throws -> RESP3Token {
        let response = try await send(clientGetredirCommand())
        return response
    }
    @inlinable
    public func clientGetredirCommand() -> RESP3Command {
        .init("CLIENT", arguments: ["GETREDIR"])
    }

    /// Returns helpful text about the different subcommands.
    /// Version: 5.0.0
    /// Complexity: O(1)
    /// Categories: @slow, @connection
    public func clientHelp() async throws -> RESP3Token {
        let response = try await send(clientHelpCommand())
        return response
    }
    @inlinable
    public func clientHelpCommand() -> RESP3Command {
        .init("CLIENT", arguments: ["HELP"])
    }

    /// Returns the unique client ID of the connection.
    /// Version: 5.0.0
    /// Complexity: O(1)
    /// Categories: @slow, @connection
    public func clientId() async throws -> RESP3Token {
        let response = try await send(clientIdCommand())
        return response
    }
    @inlinable
    public func clientIdCommand() -> RESP3Command {
        .init("CLIENT", arguments: ["ID"])
    }

    /// Returns information about the connection.
    /// Version: 6.2.0
    /// Complexity: O(1)
    /// Categories: @slow, @connection
    public func clientInfo() async throws -> RESP3Token {
        let response = try await send(clientInfoCommand())
        return response
    }
    @inlinable
    public func clientInfoCommand() -> RESP3Command {
        .init("CLIENT", arguments: ["INFO"])
    }

    /// Sets the connection name.
    /// Version: 2.6.9
    /// Complexity: O(1)
    /// Categories: @slow, @connection
    public func clientSetname(connectionName: String) async throws -> RESP3Token {
        let response = try await send(clientSetnameCommand(connectionName: connectionName))
        return response
    }
    @inlinable
    public func clientSetnameCommand(connectionName: String) -> RESP3Command {
        .init("CLIENT", arguments: ["SETNAME", connectionName])
    }

    /// Returns information about server-assisted client-side caching for the connection.
    /// Version: 6.2.0
    /// Complexity: O(1)
    /// Categories: @slow, @connection
    public func clientTrackinginfo() async throws -> RESP3Token {
        let response = try await send(clientTrackinginfoCommand())
        return response
    }
    @inlinable
    public func clientTrackinginfoCommand() -> RESP3Command {
        .init("CLIENT", arguments: ["TRACKINGINFO"])
    }

    /// Resumes processing commands from paused clients.
    /// Version: 6.2.0
    /// Complexity: O(N) Where N is the number of paused clients
    /// Categories: @admin, @slow, @dangerous, @connection
    public func clientUnpause() async throws -> RESP3Token {
        let response = try await send(clientUnpauseCommand())
        return response
    }
    @inlinable
    public func clientUnpauseCommand() -> RESP3Command {
        .init("CLIENT", arguments: ["UNPAUSE"])
    }

    /// A container for Redis Cluster commands.
    /// Version: 3.0.0
    /// Complexity: Depends on subcommand.
    /// Categories: @slow
    public func cluster() async throws -> RESP3Token {
        let response = try await send(clusterCommand())
        return response
    }
    @inlinable
    public func clusterCommand() -> RESP3Command {
        .init("CLUSTER", arguments: [])
    }

    /// Assigns new hash slots to a node.
    /// Version: 3.0.0
    /// Complexity: O(N) where N is the total number of hash slot arguments
    /// Categories: @admin, @slow, @dangerous
    public func clusterAddslots(slot: Int...) async throws -> RESP3Token {
        let response = try await send(clusterAddslotsCommand(slot: slot))
        return response
    }
    @inlinable
    public func clusterAddslotsCommand(slot: [Int]) -> RESP3Command {
        var arguments: [String] = ["ADDSLOTS"]
        arguments.append(contentsOf: slot.map(\.description))
        return .init("CLUSTER", arguments: arguments)
    }

    /// Advances the cluster config epoch.
    /// Version: 3.0.0
    /// Complexity: O(1)
    /// Categories: @admin, @slow, @dangerous
    public func clusterBumpepoch() async throws -> RESP3Token {
        let response = try await send(clusterBumpepochCommand())
        return response
    }
    @inlinable
    public func clusterBumpepochCommand() -> RESP3Command {
        .init("CLUSTER", arguments: ["BUMPEPOCH"])
    }

    /// Returns the number of active failure reports active for a node.
    /// Version: 3.0.0
    /// Complexity: O(N) where N is the number of failure reports
    /// Categories: @admin, @slow, @dangerous
    public func clusterCountFailureReports(nodeId: String) async throws -> RESP3Token {
        let response = try await send(clusterCountFailureReportsCommand(nodeId: nodeId))
        return response
    }
    @inlinable
    public func clusterCountFailureReportsCommand(nodeId: String) -> RESP3Command {
        .init("CLUSTER", arguments: ["COUNT-FAILURE-REPORTS", nodeId])
    }

    /// Returns the number of keys in a hash slot.
    /// Version: 3.0.0
    /// Complexity: O(1)
    /// Categories: @slow
    public func clusterCountkeysinslot(slot: Int) async throws -> RESP3Token {
        let response = try await send(clusterCountkeysinslotCommand(slot: slot))
        return response
    }
    @inlinable
    public func clusterCountkeysinslotCommand(slot: Int) -> RESP3Command {
        .init("CLUSTER", arguments: ["COUNTKEYSINSLOT", slot.description])
    }

    /// Sets hash slots as unbound for a node.
    /// Version: 3.0.0
    /// Complexity: O(N) where N is the total number of hash slot arguments
    /// Categories: @admin, @slow, @dangerous
    public func clusterDelslots(slot: Int...) async throws -> RESP3Token {
        let response = try await send(clusterDelslotsCommand(slot: slot))
        return response
    }
    @inlinable
    public func clusterDelslotsCommand(slot: [Int]) -> RESP3Command {
        var arguments: [String] = ["DELSLOTS"]
        arguments.append(contentsOf: slot.map(\.description))
        return .init("CLUSTER", arguments: arguments)
    }

    /// Deletes all slots information from a node.
    /// Version: 3.0.0
    /// Complexity: O(1)
    /// Categories: @admin, @slow, @dangerous
    public func clusterFlushslots() async throws -> RESP3Token {
        let response = try await send(clusterFlushslotsCommand())
        return response
    }
    @inlinable
    public func clusterFlushslotsCommand() -> RESP3Command {
        .init("CLUSTER", arguments: ["FLUSHSLOTS"])
    }

    /// Removes a node from the nodes table.
    /// Version: 3.0.0
    /// Complexity: O(1)
    /// Categories: @admin, @slow, @dangerous
    public func clusterForget(nodeId: String) async throws -> RESP3Token {
        let response = try await send(clusterForgetCommand(nodeId: nodeId))
        return response
    }
    @inlinable
    public func clusterForgetCommand(nodeId: String) -> RESP3Command {
        .init("CLUSTER", arguments: ["FORGET", nodeId])
    }

    /// Returns the key names in a hash slot.
    /// Version: 3.0.0
    /// Complexity: O(N) where N is the number of requested keys
    /// Categories: @slow
    public func clusterGetkeysinslot(slot: Int, count: Int) async throws -> RESP3Token {
        let response = try await send(clusterGetkeysinslotCommand(slot: slot, count: count))
        return response
    }
    @inlinable
    public func clusterGetkeysinslotCommand(slot: Int, count: Int) -> RESP3Command {
        .init("CLUSTER", arguments: ["GETKEYSINSLOT", slot.description, count.description])
    }

    /// Returns helpful text about the different subcommands.
    /// Version: 5.0.0
    /// Complexity: O(1)
    /// Categories: @slow
    public func clusterHelp() async throws -> RESP3Token {
        let response = try await send(clusterHelpCommand())
        return response
    }
    @inlinable
    public func clusterHelpCommand() -> RESP3Command {
        .init("CLUSTER", arguments: ["HELP"])
    }

    /// Returns information about the state of a node.
    /// Version: 3.0.0
    /// Complexity: O(1)
    /// Categories: @slow
    public func clusterInfo() async throws -> RESP3Token {
        let response = try await send(clusterInfoCommand())
        return response
    }
    @inlinable
    public func clusterInfoCommand() -> RESP3Command {
        .init("CLUSTER", arguments: ["INFO"])
    }

    /// Returns the hash slot for a key.
    /// Version: 3.0.0
    /// Complexity: O(N) where N is the number of bytes in the key
    /// Categories: @slow
    public func clusterKeyslot(key: String) async throws -> RESP3Token {
        let response = try await send(clusterKeyslotCommand(key: key))
        return response
    }
    @inlinable
    public func clusterKeyslotCommand(key: String) -> RESP3Command {
        .init("CLUSTER", arguments: ["KEYSLOT", key])
    }

    /// Returns a list of all TCP links to and from peer nodes.
    /// Version: 7.0.0
    /// Complexity: O(N) where N is the total number of Cluster nodes
    /// Categories: @slow
    public func clusterLinks() async throws -> RESP3Token {
        let response = try await send(clusterLinksCommand())
        return response
    }
    @inlinable
    public func clusterLinksCommand() -> RESP3Command {
        .init("CLUSTER", arguments: ["LINKS"])
    }

    /// Forces a node to handshake with another node.
    /// Version: 3.0.0
    /// Complexity: O(1)
    /// Categories: @admin, @slow, @dangerous
    public func clusterMeet(ip: String, port: Int, clusterBusPort: Int) async throws -> RESP3Token {
        let response = try await send(clusterMeetCommand(ip: ip, port: port, clusterBusPort: clusterBusPort))
        return response
    }
    @inlinable
    public func clusterMeetCommand(ip: String, port: Int, clusterBusPort: Int) -> RESP3Command {
        .init("CLUSTER", arguments: ["MEET", ip, port.description, clusterBusPort.description])
    }

    /// Returns the ID of a node.
    /// Version: 3.0.0
    /// Complexity: O(1)
    /// Categories: @slow
    public func clusterMyid() async throws -> RESP3Token {
        let response = try await send(clusterMyidCommand())
        return response
    }
    @inlinable
    public func clusterMyidCommand() -> RESP3Command {
        .init("CLUSTER", arguments: ["MYID"])
    }

    /// Returns the shard ID of a node.
    /// Version: 7.2.0
    /// Complexity: O(1)
    /// Categories: @slow
    public func clusterMyshardid() async throws -> RESP3Token {
        let response = try await send(clusterMyshardidCommand())
        return response
    }
    @inlinable
    public func clusterMyshardidCommand() -> RESP3Command {
        .init("CLUSTER", arguments: ["MYSHARDID"])
    }

    /// Returns the cluster configuration for a node.
    /// Version: 3.0.0
    /// Complexity: O(N) where N is the total number of Cluster nodes
    /// Categories: @slow
    public func clusterNodes() async throws -> RESP3Token {
        let response = try await send(clusterNodesCommand())
        return response
    }
    @inlinable
    public func clusterNodesCommand() -> RESP3Command {
        .init("CLUSTER", arguments: ["NODES"])
    }

    /// Lists the replica nodes of a master node.
    /// Version: 5.0.0
    /// Complexity: O(N) where N is the number of replicas.
    /// Categories: @admin, @slow, @dangerous
    public func clusterReplicas(nodeId: String) async throws -> RESP3Token {
        let response = try await send(clusterReplicasCommand(nodeId: nodeId))
        return response
    }
    @inlinable
    public func clusterReplicasCommand(nodeId: String) -> RESP3Command {
        .init("CLUSTER", arguments: ["REPLICAS", nodeId])
    }

    /// Configure a node as replica of a master node.
    /// Version: 3.0.0
    /// Complexity: O(1)
    /// Categories: @admin, @slow, @dangerous
    public func clusterReplicate(nodeId: String) async throws -> RESP3Token {
        let response = try await send(clusterReplicateCommand(nodeId: nodeId))
        return response
    }
    @inlinable
    public func clusterReplicateCommand(nodeId: String) -> RESP3Command {
        .init("CLUSTER", arguments: ["REPLICATE", nodeId])
    }

    /// Forces a node to save the cluster configuration to disk.
    /// Version: 3.0.0
    /// Complexity: O(1)
    /// Categories: @admin, @slow, @dangerous
    public func clusterSaveconfig() async throws -> RESP3Token {
        let response = try await send(clusterSaveconfigCommand())
        return response
    }
    @inlinable
    public func clusterSaveconfigCommand() -> RESP3Command {
        .init("CLUSTER", arguments: ["SAVECONFIG"])
    }

    /// Sets the configuration epoch for a new node.
    /// Version: 3.0.0
    /// Complexity: O(1)
    /// Categories: @admin, @slow, @dangerous
    public func clusterSetConfigEpoch(configEpoch: Int) async throws -> RESP3Token {
        let response = try await send(clusterSetConfigEpochCommand(configEpoch: configEpoch))
        return response
    }
    @inlinable
    public func clusterSetConfigEpochCommand(configEpoch: Int) -> RESP3Command {
        .init("CLUSTER", arguments: ["SET-CONFIG-EPOCH", configEpoch.description])
    }

    /// Returns the mapping of cluster slots to shards.
    /// Version: 7.0.0
    /// Complexity: O(N) where N is the total number of cluster nodes
    /// Categories: @slow
    public func clusterShards() async throws -> RESP3Token {
        let response = try await send(clusterShardsCommand())
        return response
    }
    @inlinable
    public func clusterShardsCommand() -> RESP3Command {
        .init("CLUSTER", arguments: ["SHARDS"])
    }

    /// Lists the replica nodes of a master node.
    /// Version: 3.0.0
    /// Complexity: O(N) where N is the number of replicas.
    /// Categories: @admin, @slow, @dangerous
    public func clusterSlaves(nodeId: String) async throws -> RESP3Token {
        let response = try await send(clusterSlavesCommand(nodeId: nodeId))
        return response
    }
    @inlinable
    public func clusterSlavesCommand(nodeId: String) -> RESP3Command {
        .init("CLUSTER", arguments: ["SLAVES", nodeId])
    }

    /// Returns the mapping of cluster slots to nodes.
    /// Version: 3.0.0
    /// Complexity: O(N) where N is the total number of Cluster nodes
    /// Categories: @slow
    public func clusterSlots() async throws -> RESP3Token {
        let response = try await send(clusterSlotsCommand())
        return response
    }
    @inlinable
    public func clusterSlotsCommand() -> RESP3Command {
        .init("CLUSTER", arguments: ["SLOTS"])
    }

    /// Returns detailed information about all commands.
    /// Version: 2.8.13
    /// Complexity: O(N) where N is the total number of Redis commands
    /// Categories: @slow, @connection
    public func command() async throws -> RESP3Token {
        let response = try await send(commandCommand())
        return response
    }
    @inlinable
    public func commandCommand() -> RESP3Command {
        .init("COMMAND", arguments: [])
    }

    /// Returns a count of commands.
    /// Version: 2.8.13
    /// Complexity: O(1)
    /// Categories: @slow, @connection
    public func commandCount() async throws -> RESP3Token {
        let response = try await send(commandCountCommand())
        return response
    }
    @inlinable
    public func commandCountCommand() -> RESP3Command {
        .init("COMMAND", arguments: ["COUNT"])
    }

    /// Returns documentary information about one, multiple or all commands.
    /// Version: 7.0.0
    /// Complexity: O(N) where N is the number of commands to look up
    /// Categories: @slow, @connection
    public func commandDocs(commandName: String...) async throws -> RESP3Token {
        let response = try await send(commandDocsCommand(commandName: commandName))
        return response
    }
    @inlinable
    public func commandDocsCommand(commandName: [String]) -> RESP3Command {
        var arguments: [String] = ["DOCS"]
        arguments.append(contentsOf: commandName)
        return .init("COMMAND", arguments: arguments)
    }

    /// Extracts the key names from an arbitrary command.
    /// Version: 2.8.13
    /// Complexity: O(N) where N is the number of arguments to the command
    /// Categories: @slow, @connection
    public func commandGetkeys(command: String, arg: String...) async throws -> RESP3Token {
        let response = try await send(commandGetkeysCommand(command: command, arg: arg))
        return response
    }
    @inlinable
    public func commandGetkeysCommand(command: String, arg: [String]) -> RESP3Command {
        var arguments: [String] = ["GETKEYS"]
        arguments.append(command)
        arguments.append(contentsOf: arg)
        return .init("COMMAND", arguments: arguments)
    }

    /// Extracts the key names and access flags for an arbitrary command.
    /// Version: 7.0.0
    /// Complexity: O(N) where N is the number of arguments to the command
    /// Categories: @slow, @connection
    public func commandGetkeysandflags(command: String, arg: String...) async throws -> RESP3Token {
        let response = try await send(commandGetkeysandflagsCommand(command: command, arg: arg))
        return response
    }
    @inlinable
    public func commandGetkeysandflagsCommand(command: String, arg: [String]) -> RESP3Command {
        var arguments: [String] = ["GETKEYSANDFLAGS"]
        arguments.append(command)
        arguments.append(contentsOf: arg)
        return .init("COMMAND", arguments: arguments)
    }

    /// Returns helpful text about the different subcommands.
    /// Version: 5.0.0
    /// Complexity: O(1)
    /// Categories: @slow, @connection
    public func commandHelp() async throws -> RESP3Token {
        let response = try await send(commandHelpCommand())
        return response
    }
    @inlinable
    public func commandHelpCommand() -> RESP3Command {
        .init("COMMAND", arguments: ["HELP"])
    }

    /// Returns information about one, multiple or all commands.
    /// Version: 2.8.13
    /// Complexity: O(N) where N is the number of commands to look up
    /// Categories: @slow, @connection
    public func commandInfo(commandName: String...) async throws -> RESP3Token {
        let response = try await send(commandInfoCommand(commandName: commandName))
        return response
    }
    @inlinable
    public func commandInfoCommand(commandName: [String]) -> RESP3Command {
        var arguments: [String] = ["INFO"]
        arguments.append(contentsOf: commandName)
        return .init("COMMAND", arguments: arguments)
    }

    /// A container for server configuration commands.
    /// Version: 2.0.0
    /// Complexity: Depends on subcommand.
    /// Categories: @slow
    public func config() async throws -> RESP3Token {
        let response = try await send(configCommand())
        return response
    }
    @inlinable
    public func configCommand() -> RESP3Command {
        .init("CONFIG", arguments: [])
    }

    /// Returns the effective values of configuration parameters.
    /// Version: 2.0.0
    /// Complexity: O(N) when N is the number of configuration parameters provided
    /// Categories: @admin, @slow, @dangerous
    public func configGet(parameter: String...) async throws -> RESP3Token {
        let response = try await send(configGetCommand(parameter: parameter))
        return response
    }
    @inlinable
    public func configGetCommand(parameter: [String]) -> RESP3Command {
        var arguments: [String] = ["GET"]
        arguments.append(contentsOf: parameter)
        return .init("CONFIG", arguments: arguments)
    }

    /// Returns helpful text about the different subcommands.
    /// Version: 5.0.0
    /// Complexity: O(1)
    /// Categories: @slow
    public func configHelp() async throws -> RESP3Token {
        let response = try await send(configHelpCommand())
        return response
    }
    @inlinable
    public func configHelpCommand() -> RESP3Command {
        .init("CONFIG", arguments: ["HELP"])
    }

    /// Resets the server's statistics.
    /// Version: 2.0.0
    /// Complexity: O(1)
    /// Categories: @admin, @slow, @dangerous
    public func configResetstat() async throws -> RESP3Token {
        let response = try await send(configResetstatCommand())
        return response
    }
    @inlinable
    public func configResetstatCommand() -> RESP3Command {
        .init("CONFIG", arguments: ["RESETSTAT"])
    }

    /// Persists the effective configuration to file.
    /// Version: 2.8.0
    /// Complexity: O(1)
    /// Categories: @admin, @slow, @dangerous
    public func configRewrite() async throws -> RESP3Token {
        let response = try await send(configRewriteCommand())
        return response
    }
    @inlinable
    public func configRewriteCommand() -> RESP3Command {
        .init("CONFIG", arguments: ["REWRITE"])
    }

    /// Copies the value of a key to a new key.
    /// Version: 6.2.0
    /// Complexity: O(N) worst case for collections, where N is the number of nested items. O(1) for string values.
    /// Categories: @keyspace, @write, @slow
    public func copy(source: RedisKey, destination: RedisKey, destinationDb: Int, replace: Bool) async throws -> RESP3Token {
        let response = try await send(copyCommand(source: source, destination: destination, destinationDb: destinationDb, replace: replace))
        return response
    }
    @inlinable
    public func copyCommand(source: RedisKey, destination: RedisKey, destinationDb: Int, replace: Bool) -> RESP3Command {
        .init("COPY", arguments: [source.description, destination.description, destinationDb.description, replace.description])
    }

    /// Returns the number of keys in the database.
    /// Version: 1.0.0
    /// Complexity: O(1)
    /// Categories: @keyspace, @read, @fast
    public func dbsize() async throws -> RESP3Token {
        let response = try await send(dbsizeCommand())
        return response
    }
    @inlinable
    public func dbsizeCommand() -> RESP3Command {
        .init("DBSIZE", arguments: [])
    }

    /// A container for debugging commands.
    /// Version: 1.0.0
    /// Complexity: Depends on subcommand.
    /// Categories: @admin, @slow, @dangerous
    public func debug() async throws -> RESP3Token {
        let response = try await send(debugCommand())
        return response
    }
    @inlinable
    public func debugCommand() -> RESP3Command {
        .init("DEBUG", arguments: [])
    }

    /// Decrements the integer value of a key by one. Uses 0 as initial value if the key doesn't exist.
    /// Version: 1.0.0
    /// Complexity: O(1)
    /// Categories: @write, @string, @fast
    public func decr(key: RedisKey) async throws -> RESP3Token {
        let response = try await send(decrCommand(key: key))
        return response
    }
    @inlinable
    public func decrCommand(key: RedisKey) -> RESP3Command {
        .init("DECR", arguments: [key.description])
    }

    /// Decrements a number from the integer value of a key. Uses 0 as initial value if the key doesn't exist.
    /// Version: 1.0.0
    /// Complexity: O(1)
    /// Categories: @write, @string, @fast
    public func decrby(key: RedisKey, decrement: Int) async throws -> RESP3Token {
        let response = try await send(decrbyCommand(key: key, decrement: decrement))
        return response
    }
    @inlinable
    public func decrbyCommand(key: RedisKey, decrement: Int) -> RESP3Command {
        .init("DECRBY", arguments: [key.description, decrement.description])
    }

    /// Deletes one or more keys.
    /// Version: 1.0.0
    /// Complexity: O(N) where N is the number of keys that will be removed. When a key to remove holds a value other than a string, the individual complexity for this key is O(M) where M is the number of elements in the list, set, sorted set or hash. Removing a single key that holds a string value is O(1).
    /// Categories: @keyspace, @write, @slow
    public func del(key: RedisKey...) async throws -> RESP3Token {
        let response = try await send(delCommand(key: key))
        return response
    }
    @inlinable
    public func delCommand(key: [RedisKey]) -> RESP3Command {
        let arguments: [String] = key.map(\.description)
        return .init("DEL", arguments: arguments)
    }

    /// Discards a transaction.
    /// Version: 2.0.0
    /// Complexity: O(N), when N is the number of queued commands
    /// Categories: @fast, @transaction
    public func discard() async throws -> RESP3Token {
        let response = try await send(discardCommand())
        return response
    }
    @inlinable
    public func discardCommand() -> RESP3Command {
        .init("DISCARD", arguments: [])
    }

    /// Returns a serialized representation of the value stored at a key.
    /// Version: 2.6.0
    /// Complexity: O(1) to access the key and additional O(N*M) to serialize it, where N is the number of Redis objects composing the value and M their average size. For small string values the time complexity is thus O(1)+O(1*M) where M is small, so simply O(1).
    /// Categories: @keyspace, @read, @slow
    public func dump(key: RedisKey) async throws -> RESP3Token {
        let response = try await send(dumpCommand(key: key))
        return response
    }
    @inlinable
    public func dumpCommand(key: RedisKey) -> RESP3Command {
        .init("DUMP", arguments: [key.description])
    }

    /// Returns the given string.
    /// Version: 1.0.0
    /// Complexity: O(1)
    /// Categories: @fast, @connection
    public func echo(message: String) async throws -> RESP3Token {
        let response = try await send(echoCommand(message: message))
        return response
    }
    @inlinable
    public func echoCommand(message: String) -> RESP3Command {
        .init("ECHO", arguments: [message])
    }

    /// Executes a server-side Lua script.
    /// Version: 2.6.0
    /// Complexity: Depends on the script that is executed.
    /// Categories: @slow, @scripting
    public func eval(script: String, numkeys: Int, key: RedisKey..., arg: String...) async throws -> RESP3Token {
        let response = try await send(evalCommand(script: script, numkeys: numkeys, key: key, arg: arg))
        return response
    }
    @inlinable
    public func evalCommand(script: String, numkeys: Int, key: [RedisKey], arg: [String]) -> RESP3Command {
        var arguments: [String] = [script]
        arguments.append(numkeys.description)
        arguments.append(contentsOf: key.map(\.description))
        arguments.append(contentsOf: arg)
        return .init("EVAL", arguments: arguments)
    }

    /// Executes a server-side Lua script by SHA1 digest.
    /// Version: 2.6.0
    /// Complexity: Depends on the script that is executed.
    /// Categories: @slow, @scripting
    public func evalsha(sha1: String, numkeys: Int, key: RedisKey..., arg: String...) async throws -> RESP3Token {
        let response = try await send(evalshaCommand(sha1: sha1, numkeys: numkeys, key: key, arg: arg))
        return response
    }
    @inlinable
    public func evalshaCommand(sha1: String, numkeys: Int, key: [RedisKey], arg: [String]) -> RESP3Command {
        var arguments: [String] = [sha1]
        arguments.append(numkeys.description)
        arguments.append(contentsOf: key.map(\.description))
        arguments.append(contentsOf: arg)
        return .init("EVALSHA", arguments: arguments)
    }

    /// Executes a read-only server-side Lua script by SHA1 digest.
    /// Version: 7.0.0
    /// Complexity: Depends on the script that is executed.
    /// Categories: @slow, @scripting
    public func evalshaRo(sha1: String, numkeys: Int, key: RedisKey..., arg: String...) async throws -> RESP3Token {
        let response = try await send(evalshaRoCommand(sha1: sha1, numkeys: numkeys, key: key, arg: arg))
        return response
    }
    @inlinable
    public func evalshaRoCommand(sha1: String, numkeys: Int, key: [RedisKey], arg: [String]) -> RESP3Command {
        var arguments: [String] = [sha1]
        arguments.append(numkeys.description)
        arguments.append(contentsOf: key.map(\.description))
        arguments.append(contentsOf: arg)
        return .init("EVALSHA_RO", arguments: arguments)
    }

    /// Executes a read-only server-side Lua script.
    /// Version: 7.0.0
    /// Complexity: Depends on the script that is executed.
    /// Categories: @slow, @scripting
    public func evalRo(script: String, numkeys: Int, key: RedisKey..., arg: String...) async throws -> RESP3Token {
        let response = try await send(evalRoCommand(script: script, numkeys: numkeys, key: key, arg: arg))
        return response
    }
    @inlinable
    public func evalRoCommand(script: String, numkeys: Int, key: [RedisKey], arg: [String]) -> RESP3Command {
        var arguments: [String] = [script]
        arguments.append(numkeys.description)
        arguments.append(contentsOf: key.map(\.description))
        arguments.append(contentsOf: arg)
        return .init("EVAL_RO", arguments: arguments)
    }

    /// Executes all commands in a transaction.
    /// Version: 1.2.0
    /// Complexity: Depends on commands in the transaction
    /// Categories: @slow, @transaction
    public func exec() async throws -> RESP3Token {
        let response = try await send(execCommand())
        return response
    }
    @inlinable
    public func execCommand() -> RESP3Command {
        .init("EXEC", arguments: [])
    }

    /// Determines whether one or more keys exist.
    /// Version: 1.0.0
    /// Complexity: O(N) where N is the number of keys to check.
    /// Categories: @keyspace, @read, @fast
    public func exists(key: RedisKey...) async throws -> RESP3Token {
        let response = try await send(existsCommand(key: key))
        return response
    }
    @inlinable
    public func existsCommand(key: [RedisKey]) -> RESP3Command {
        let arguments: [String] = key.map(\.description)
        return .init("EXISTS", arguments: arguments)
    }

    /// Returns the expiration time of a key as a Unix timestamp.
    /// Version: 7.0.0
    /// Complexity: O(1)
    /// Categories: @keyspace, @read, @fast
    public func expiretime(key: RedisKey) async throws -> RESP3Token {
        let response = try await send(expiretimeCommand(key: key))
        return response
    }
    @inlinable
    public func expiretimeCommand(key: RedisKey) -> RESP3Command {
        .init("EXPIRETIME", arguments: [key.description])
    }

    /// Invokes a function.
    /// Version: 7.0.0
    /// Complexity: Depends on the function that is executed.
    /// Categories: @slow, @scripting
    public func fcall(function: String, numkeys: Int, key: RedisKey..., arg: String...) async throws -> RESP3Token {
        let response = try await send(fcallCommand(function: function, numkeys: numkeys, key: key, arg: arg))
        return response
    }
    @inlinable
    public func fcallCommand(function: String, numkeys: Int, key: [RedisKey], arg: [String]) -> RESP3Command {
        var arguments: [String] = [function]
        arguments.append(numkeys.description)
        arguments.append(contentsOf: key.map(\.description))
        arguments.append(contentsOf: arg)
        return .init("FCALL", arguments: arguments)
    }

    /// Invokes a read-only function.
    /// Version: 7.0.0
    /// Complexity: Depends on the function that is executed.
    /// Categories: @slow, @scripting
    public func fcallRo(function: String, numkeys: Int, key: RedisKey..., arg: String...) async throws -> RESP3Token {
        let response = try await send(fcallRoCommand(function: function, numkeys: numkeys, key: key, arg: arg))
        return response
    }
    @inlinable
    public func fcallRoCommand(function: String, numkeys: Int, key: [RedisKey], arg: [String]) -> RESP3Command {
        var arguments: [String] = [function]
        arguments.append(numkeys.description)
        arguments.append(contentsOf: key.map(\.description))
        arguments.append(contentsOf: arg)
        return .init("FCALL_RO", arguments: arguments)
    }

    /// A container for function commands.
    /// Version: 7.0.0
    /// Complexity: Depends on subcommand.
    /// Categories: @slow
    public func function() async throws -> RESP3Token {
        let response = try await send(functionCommand())
        return response
    }
    @inlinable
    public func functionCommand() -> RESP3Command {
        .init("FUNCTION", arguments: [])
    }

    /// Deletes a library and its functions.
    /// Version: 7.0.0
    /// Complexity: O(1)
    /// Categories: @write, @slow, @scripting
    public func functionDelete(libraryName: String) async throws -> RESP3Token {
        let response = try await send(functionDeleteCommand(libraryName: libraryName))
        return response
    }
    @inlinable
    public func functionDeleteCommand(libraryName: String) -> RESP3Command {
        .init("FUNCTION", arguments: ["DELETE", libraryName])
    }

    /// Dumps all libraries into a serialized binary payload.
    /// Version: 7.0.0
    /// Complexity: O(N) where N is the number of functions
    /// Categories: @slow, @scripting
    public func functionDump() async throws -> RESP3Token {
        let response = try await send(functionDumpCommand())
        return response
    }
    @inlinable
    public func functionDumpCommand() -> RESP3Command {
        .init("FUNCTION", arguments: ["DUMP"])
    }

    /// Returns helpful text about the different subcommands.
    /// Version: 7.0.0
    /// Complexity: O(1)
    /// Categories: @slow, @scripting
    public func functionHelp() async throws -> RESP3Token {
        let response = try await send(functionHelpCommand())
        return response
    }
    @inlinable
    public func functionHelpCommand() -> RESP3Command {
        .init("FUNCTION", arguments: ["HELP"])
    }

    /// Terminates a function during execution.
    /// Version: 7.0.0
    /// Complexity: O(1)
    /// Categories: @slow, @scripting
    public func functionKill() async throws -> RESP3Token {
        let response = try await send(functionKillCommand())
        return response
    }
    @inlinable
    public func functionKillCommand() -> RESP3Command {
        .init("FUNCTION", arguments: ["KILL"])
    }

    /// Returns information about all libraries.
    /// Version: 7.0.0
    /// Complexity: O(N) where N is the number of functions
    /// Categories: @slow, @scripting
    public func functionList(libraryNamePattern: String, withcode: Bool) async throws -> RESP3Token {
        let response = try await send(functionListCommand(libraryNamePattern: libraryNamePattern, withcode: withcode))
        return response
    }
    @inlinable
    public func functionListCommand(libraryNamePattern: String, withcode: Bool) -> RESP3Command {
        .init("FUNCTION", arguments: ["LIST", libraryNamePattern, withcode.description])
    }

    /// Creates a library.
    /// Version: 7.0.0
    /// Complexity: O(1) (considering compilation time is redundant)
    /// Categories: @write, @slow, @scripting
    public func functionLoad(replace: Bool, functionCode: String) async throws -> RESP3Token {
        let response = try await send(functionLoadCommand(replace: replace, functionCode: functionCode))
        return response
    }
    @inlinable
    public func functionLoadCommand(replace: Bool, functionCode: String) -> RESP3Command {
        .init("FUNCTION", arguments: ["LOAD", replace.description, functionCode])
    }

    /// Returns information about a function during execution.
    /// Version: 7.0.0
    /// Complexity: O(1)
    /// Categories: @slow, @scripting
    public func functionStats() async throws -> RESP3Token {
        let response = try await send(functionStatsCommand())
        return response
    }
    @inlinable
    public func functionStatsCommand() -> RESP3Command {
        .init("FUNCTION", arguments: ["STATS"])
    }

    /// Returns members from a geospatial index as geohash strings.
    /// Version: 3.2.0
    /// Complexity: O(1) for each member requested.
    /// Categories: @read, @geo, @slow
    public func geohash(key: RedisKey, member: String...) async throws -> RESP3Token {
        let response = try await send(geohashCommand(key: key, member: member))
        return response
    }
    @inlinable
    public func geohashCommand(key: RedisKey, member: [String]) -> RESP3Command {
        var arguments: [String] = [key.description]
        arguments.append(contentsOf: member)
        return .init("GEOHASH", arguments: arguments)
    }

    /// Returns the longitude and latitude of members from a geospatial index.
    /// Version: 3.2.0
    /// Complexity: O(1) for each member requested.
    /// Categories: @read, @geo, @slow
    public func geopos(key: RedisKey, member: String...) async throws -> RESP3Token {
        let response = try await send(geoposCommand(key: key, member: member))
        return response
    }
    @inlinable
    public func geoposCommand(key: RedisKey, member: [String]) -> RESP3Command {
        var arguments: [String] = [key.description]
        arguments.append(contentsOf: member)
        return .init("GEOPOS", arguments: arguments)
    }

    /// Returns the string value of a key.
    /// Version: 1.0.0
    /// Complexity: O(1)
    /// Categories: @read, @string, @fast
    public func get(key: RedisKey) async throws -> RESP3Token {
        let response = try await send(getCommand(key: key))
        return response
    }
    @inlinable
    public func getCommand(key: RedisKey) -> RESP3Command {
        .init("GET", arguments: [key.description])
    }

    /// Returns a bit value by offset.
    /// Version: 2.2.0
    /// Complexity: O(1)
    /// Categories: @read, @bitmap, @fast
    public func getbit(key: RedisKey, offset: Int) async throws -> RESP3Token {
        let response = try await send(getbitCommand(key: key, offset: offset))
        return response
    }
    @inlinable
    public func getbitCommand(key: RedisKey, offset: Int) -> RESP3Command {
        .init("GETBIT", arguments: [key.description, offset.description])
    }

    /// Returns the string value of a key after deleting the key.
    /// Version: 6.2.0
    /// Complexity: O(1)
    /// Categories: @write, @string, @fast
    public func getdel(key: RedisKey) async throws -> RESP3Token {
        let response = try await send(getdelCommand(key: key))
        return response
    }
    @inlinable
    public func getdelCommand(key: RedisKey) -> RESP3Command {
        .init("GETDEL", arguments: [key.description])
    }

    /// Returns a substring of the string stored at a key.
    /// Version: 2.4.0
    /// Complexity: O(N) where N is the length of the returned string. The complexity is ultimately determined by the returned length, but because creating a substring from an existing string is very cheap, it can be considered O(1) for small strings.
    /// Categories: @read, @string, @slow
    public func getrange(key: RedisKey, start: Int, end: Int) async throws -> RESP3Token {
        let response = try await send(getrangeCommand(key: key, start: start, end: end))
        return response
    }
    @inlinable
    public func getrangeCommand(key: RedisKey, start: Int, end: Int) -> RESP3Command {
        .init("GETRANGE", arguments: [key.description, start.description, end.description])
    }

    /// Returns the previous string value of a key after setting it to a new value.
    /// Version: 1.0.0
    /// Complexity: O(1)
    /// Categories: @write, @string, @fast
    public func getset(key: RedisKey, value: String) async throws -> RESP3Token {
        let response = try await send(getsetCommand(key: key, value: value))
        return response
    }
    @inlinable
    public func getsetCommand(key: RedisKey, value: String) -> RESP3Command {
        .init("GETSET", arguments: [key.description, value])
    }

    /// Deletes one or more fields and their values from a hash. Deletes the hash if no fields remain.
    /// Version: 2.0.0
    /// Complexity: O(N) where N is the number of fields to be removed.
    /// Categories: @write, @hash, @fast
    public func hdel(key: RedisKey, field: String...) async throws -> RESP3Token {
        let response = try await send(hdelCommand(key: key, field: field))
        return response
    }
    @inlinable
    public func hdelCommand(key: RedisKey, field: [String]) -> RESP3Command {
        var arguments: [String] = [key.description]
        arguments.append(contentsOf: field)
        return .init("HDEL", arguments: arguments)
    }

    /// Determines whether a field exists in a hash.
    /// Version: 2.0.0
    /// Complexity: O(1)
    /// Categories: @read, @hash, @fast
    public func hexists(key: RedisKey, field: String) async throws -> RESP3Token {
        let response = try await send(hexistsCommand(key: key, field: field))
        return response
    }
    @inlinable
    public func hexistsCommand(key: RedisKey, field: String) -> RESP3Command {
        .init("HEXISTS", arguments: [key.description, field])
    }

    /// Returns the value of a field in a hash.
    /// Version: 2.0.0
    /// Complexity: O(1)
    /// Categories: @read, @hash, @fast
    public func hget(key: RedisKey, field: String) async throws -> RESP3Token {
        let response = try await send(hgetCommand(key: key, field: field))
        return response
    }
    @inlinable
    public func hgetCommand(key: RedisKey, field: String) -> RESP3Command {
        .init("HGET", arguments: [key.description, field])
    }

    /// Returns all fields and values in a hash.
    /// Version: 2.0.0
    /// Complexity: O(N) where N is the size of the hash.
    /// Categories: @read, @hash, @slow
    public func hgetall(key: RedisKey) async throws -> RESP3Token {
        let response = try await send(hgetallCommand(key: key))
        return response
    }
    @inlinable
    public func hgetallCommand(key: RedisKey) -> RESP3Command {
        .init("HGETALL", arguments: [key.description])
    }

    /// Increments the integer value of a field in a hash by a number. Uses 0 as initial value if the field doesn't exist.
    /// Version: 2.0.0
    /// Complexity: O(1)
    /// Categories: @write, @hash, @fast
    public func hincrby(key: RedisKey, field: String, increment: Int) async throws -> RESP3Token {
        let response = try await send(hincrbyCommand(key: key, field: field, increment: increment))
        return response
    }
    @inlinable
    public func hincrbyCommand(key: RedisKey, field: String, increment: Int) -> RESP3Command {
        .init("HINCRBY", arguments: [key.description, field, increment.description])
    }

    /// Increments the floating point value of a field by a number. Uses 0 as initial value if the field doesn't exist.
    /// Version: 2.6.0
    /// Complexity: O(1)
    /// Categories: @write, @hash, @fast
    public func hincrbyfloat(key: RedisKey, field: String, increment: Double) async throws -> RESP3Token {
        let response = try await send(hincrbyfloatCommand(key: key, field: field, increment: increment))
        return response
    }
    @inlinable
    public func hincrbyfloatCommand(key: RedisKey, field: String, increment: Double) -> RESP3Command {
        .init("HINCRBYFLOAT", arguments: [key.description, field, increment.description])
    }

    /// Returns all fields in a hash.
    /// Version: 2.0.0
    /// Complexity: O(N) where N is the size of the hash.
    /// Categories: @read, @hash, @slow
    public func hkeys(key: RedisKey) async throws -> RESP3Token {
        let response = try await send(hkeysCommand(key: key))
        return response
    }
    @inlinable
    public func hkeysCommand(key: RedisKey) -> RESP3Command {
        .init("HKEYS", arguments: [key.description])
    }

    /// Returns the number of fields in a hash.
    /// Version: 2.0.0
    /// Complexity: O(1)
    /// Categories: @read, @hash, @fast
    public func hlen(key: RedisKey) async throws -> RESP3Token {
        let response = try await send(hlenCommand(key: key))
        return response
    }
    @inlinable
    public func hlenCommand(key: RedisKey) -> RESP3Command {
        .init("HLEN", arguments: [key.description])
    }

    /// Returns the values of all fields in a hash.
    /// Version: 2.0.0
    /// Complexity: O(N) where N is the number of fields being requested.
    /// Categories: @read, @hash, @fast
    public func hmget(key: RedisKey, field: String...) async throws -> RESP3Token {
        let response = try await send(hmgetCommand(key: key, field: field))
        return response
    }
    @inlinable
    public func hmgetCommand(key: RedisKey, field: [String]) -> RESP3Command {
        var arguments: [String] = [key.description]
        arguments.append(contentsOf: field)
        return .init("HMGET", arguments: arguments)
    }

    /// Sets the value of a field in a hash only when the field doesn't exist.
    /// Version: 2.0.0
    /// Complexity: O(1)
    /// Categories: @write, @hash, @fast
    public func hsetnx(key: RedisKey, field: String, value: String) async throws -> RESP3Token {
        let response = try await send(hsetnxCommand(key: key, field: field, value: value))
        return response
    }
    @inlinable
    public func hsetnxCommand(key: RedisKey, field: String, value: String) -> RESP3Command {
        .init("HSETNX", arguments: [key.description, field, value])
    }

    /// Returns the length of the value of a field.
    /// Version: 3.2.0
    /// Complexity: O(1)
    /// Categories: @read, @hash, @fast
    public func hstrlen(key: RedisKey, field: String) async throws -> RESP3Token {
        let response = try await send(hstrlenCommand(key: key, field: field))
        return response
    }
    @inlinable
    public func hstrlenCommand(key: RedisKey, field: String) -> RESP3Command {
        .init("HSTRLEN", arguments: [key.description, field])
    }

    /// Returns all values in a hash.
    /// Version: 2.0.0
    /// Complexity: O(N) where N is the size of the hash.
    /// Categories: @read, @hash, @slow
    public func hvals(key: RedisKey) async throws -> RESP3Token {
        let response = try await send(hvalsCommand(key: key))
        return response
    }
    @inlinable
    public func hvalsCommand(key: RedisKey) -> RESP3Command {
        .init("HVALS", arguments: [key.description])
    }

    /// Increments the integer value of a key by one. Uses 0 as initial value if the key doesn't exist.
    /// Version: 1.0.0
    /// Complexity: O(1)
    /// Categories: @write, @string, @fast
    public func incr(key: RedisKey) async throws -> RESP3Token {
        let response = try await send(incrCommand(key: key))
        return response
    }
    @inlinable
    public func incrCommand(key: RedisKey) -> RESP3Command {
        .init("INCR", arguments: [key.description])
    }

    /// Increments the integer value of a key by a number. Uses 0 as initial value if the key doesn't exist.
    /// Version: 1.0.0
    /// Complexity: O(1)
    /// Categories: @write, @string, @fast
    public func incrby(key: RedisKey, increment: Int) async throws -> RESP3Token {
        let response = try await send(incrbyCommand(key: key, increment: increment))
        return response
    }
    @inlinable
    public func incrbyCommand(key: RedisKey, increment: Int) -> RESP3Command {
        .init("INCRBY", arguments: [key.description, increment.description])
    }

    /// Increment the floating point value of a key by a number. Uses 0 as initial value if the key doesn't exist.
    /// Version: 2.6.0
    /// Complexity: O(1)
    /// Categories: @write, @string, @fast
    public func incrbyfloat(key: RedisKey, increment: Double) async throws -> RESP3Token {
        let response = try await send(incrbyfloatCommand(key: key, increment: increment))
        return response
    }
    @inlinable
    public func incrbyfloatCommand(key: RedisKey, increment: Double) -> RESP3Command {
        .init("INCRBYFLOAT", arguments: [key.description, increment.description])
    }

    /// Returns information and statistics about the server.
    /// Version: 1.0.0
    /// Complexity: O(1)
    /// Categories: @slow, @dangerous
    public func info(section: String...) async throws -> RESP3Token {
        let response = try await send(infoCommand(section: section))
        return response
    }
    @inlinable
    public func infoCommand(section: [String]) -> RESP3Command {
        let arguments: [String] = section
        return .init("INFO", arguments: arguments)
    }

    /// Returns the Unix timestamp of the last successful save to disk.
    /// Version: 1.0.0
    /// Complexity: O(1)
    /// Categories: @admin, @fast, @dangerous
    public func lastsave() async throws -> RESP3Token {
        let response = try await send(lastsaveCommand())
        return response
    }
    @inlinable
    public func lastsaveCommand() -> RESP3Command {
        .init("LASTSAVE", arguments: [])
    }

    /// A container for latency diagnostics commands.
    /// Version: 2.8.13
    /// Complexity: Depends on subcommand.
    /// Categories: @slow
    public func latency() async throws -> RESP3Token {
        let response = try await send(latencyCommand())
        return response
    }
    @inlinable
    public func latencyCommand() -> RESP3Command {
        .init("LATENCY", arguments: [])
    }

    /// Returns a human-readable latency analysis report.
    /// Version: 2.8.13
    /// Complexity: O(1)
    /// Categories: @admin, @slow, @dangerous
    public func latencyDoctor() async throws -> RESP3Token {
        let response = try await send(latencyDoctorCommand())
        return response
    }
    @inlinable
    public func latencyDoctorCommand() -> RESP3Command {
        .init("LATENCY", arguments: ["DOCTOR"])
    }

    /// Returns a latency graph for an event.
    /// Version: 2.8.13
    /// Complexity: O(1)
    /// Categories: @admin, @slow, @dangerous
    public func latencyGraph(event: String) async throws -> RESP3Token {
        let response = try await send(latencyGraphCommand(event: event))
        return response
    }
    @inlinable
    public func latencyGraphCommand(event: String) -> RESP3Command {
        .init("LATENCY", arguments: ["GRAPH", event])
    }

    /// Returns helpful text about the different subcommands.
    /// Version: 2.8.13
    /// Complexity: O(1)
    /// Categories: @slow
    public func latencyHelp() async throws -> RESP3Token {
        let response = try await send(latencyHelpCommand())
        return response
    }
    @inlinable
    public func latencyHelpCommand() -> RESP3Command {
        .init("LATENCY", arguments: ["HELP"])
    }

    /// Returns the cumulative distribution of latencies of a subset or all commands.
    /// Version: 7.0.0
    /// Complexity: O(N) where N is the number of commands with latency information being retrieved.
    /// Categories: @admin, @slow, @dangerous
    public func latencyHistogram(command: String...) async throws -> RESP3Token {
        let response = try await send(latencyHistogramCommand(command: command))
        return response
    }
    @inlinable
    public func latencyHistogramCommand(command: [String]) -> RESP3Command {
        var arguments: [String] = ["HISTOGRAM"]
        arguments.append(contentsOf: command)
        return .init("LATENCY", arguments: arguments)
    }

    /// Returns timestamp-latency samples for an event.
    /// Version: 2.8.13
    /// Complexity: O(1)
    /// Categories: @admin, @slow, @dangerous
    public func latencyHistory(event: String) async throws -> RESP3Token {
        let response = try await send(latencyHistoryCommand(event: event))
        return response
    }
    @inlinable
    public func latencyHistoryCommand(event: String) -> RESP3Command {
        .init("LATENCY", arguments: ["HISTORY", event])
    }

    /// Returns the latest latency samples for all events.
    /// Version: 2.8.13
    /// Complexity: O(1)
    /// Categories: @admin, @slow, @dangerous
    public func latencyLatest() async throws -> RESP3Token {
        let response = try await send(latencyLatestCommand())
        return response
    }
    @inlinable
    public func latencyLatestCommand() -> RESP3Command {
        .init("LATENCY", arguments: ["LATEST"])
    }

    /// Resets the latency data for one or more events.
    /// Version: 2.8.13
    /// Complexity: O(1)
    /// Categories: @admin, @slow, @dangerous
    public func latencyReset(event: String...) async throws -> RESP3Token {
        let response = try await send(latencyResetCommand(event: event))
        return response
    }
    @inlinable
    public func latencyResetCommand(event: [String]) -> RESP3Command {
        var arguments: [String] = ["RESET"]
        arguments.append(contentsOf: event)
        return .init("LATENCY", arguments: arguments)
    }

    /// Finds the longest common substring.
    /// Version: 7.0.0
    /// Complexity: O(N*M) where N and M are the lengths of s1 and s2, respectively
    /// Categories: @read, @string, @slow
    public func lcs(key1: RedisKey, key2: RedisKey, len: Bool, idx: Bool, minMatchLen: Int, withmatchlen: Bool) async throws -> RESP3Token {
        let response = try await send(lcsCommand(key1: key1, key2: key2, len: len, idx: idx, minMatchLen: minMatchLen, withmatchlen: withmatchlen))
        return response
    }
    @inlinable
    public func lcsCommand(key1: RedisKey, key2: RedisKey, len: Bool, idx: Bool, minMatchLen: Int, withmatchlen: Bool) -> RESP3Command {
        .init(
            "LCS",
            arguments: [key1.description, key2.description, len.description, idx.description, minMatchLen.description, withmatchlen.description]
        )
    }

    /// Returns an element from a list by its index.
    /// Version: 1.0.0
    /// Complexity: O(N) where N is the number of elements to traverse to get to the element at index. This makes asking for the first or the last element of the list O(1).
    /// Categories: @read, @list, @slow
    public func lindex(key: RedisKey, index: Int) async throws -> RESP3Token {
        let response = try await send(lindexCommand(key: key, index: index))
        return response
    }
    @inlinable
    public func lindexCommand(key: RedisKey, index: Int) -> RESP3Command {
        .init("LINDEX", arguments: [key.description, index.description])
    }

    /// Returns the length of a list.
    /// Version: 1.0.0
    /// Complexity: O(1)
    /// Categories: @read, @list, @fast
    public func llen(key: RedisKey) async throws -> RESP3Token {
        let response = try await send(llenCommand(key: key))
        return response
    }
    @inlinable
    public func llenCommand(key: RedisKey) -> RESP3Command {
        .init("LLEN", arguments: [key.description])
    }

    /// Displays computer art and the Redis version
    /// Version: 5.0.0
    /// Complexity:
    /// Categories: @read, @fast
    public func lolwut(version: Int) async throws -> RESP3Token {
        let response = try await send(lolwutCommand(version: version))
        return response
    }
    @inlinable
    public func lolwutCommand(version: Int) -> RESP3Command {
        .init("LOLWUT", arguments: [version.description])
    }

    /// Returns the first elements in a list after removing it. Deletes the list if the last element was popped.
    /// Version: 1.0.0
    /// Complexity: O(N) where N is the number of elements returned
    /// Categories: @write, @list, @fast
    public func lpop(key: RedisKey, count: Int) async throws -> RESP3Token {
        let response = try await send(lpopCommand(key: key, count: count))
        return response
    }
    @inlinable
    public func lpopCommand(key: RedisKey, count: Int) -> RESP3Command {
        .init("LPOP", arguments: [key.description, count.description])
    }

    /// Returns the index of matching elements in a list.
    /// Version: 6.0.6
    /// Complexity: O(N) where N is the number of elements in the list, for the average case. When searching for elements near the head or the tail of the list, or when the MAXLEN option is provided, the command may run in constant time.
    /// Categories: @read, @list, @slow
    public func lpos(key: RedisKey, element: String, rank: Int, numMatches: Int, len: Int) async throws -> RESP3Token {
        let response = try await send(lposCommand(key: key, element: element, rank: rank, numMatches: numMatches, len: len))
        return response
    }
    @inlinable
    public func lposCommand(key: RedisKey, element: String, rank: Int, numMatches: Int, len: Int) -> RESP3Command {
        .init("LPOS", arguments: [key.description, element, rank.description, numMatches.description, len.description])
    }

    /// Prepends one or more elements to a list. Creates the key if it doesn't exist.
    /// Version: 1.0.0
    /// Complexity: O(1) for each element added, so O(N) to add N elements when the command is called with multiple arguments.
    /// Categories: @write, @list, @fast
    public func lpush(key: RedisKey, element: String...) async throws -> RESP3Token {
        let response = try await send(lpushCommand(key: key, element: element))
        return response
    }
    @inlinable
    public func lpushCommand(key: RedisKey, element: [String]) -> RESP3Command {
        var arguments: [String] = [key.description]
        arguments.append(contentsOf: element)
        return .init("LPUSH", arguments: arguments)
    }

    /// Prepends one or more elements to a list only when the list exists.
    /// Version: 2.2.0
    /// Complexity: O(1) for each element added, so O(N) to add N elements when the command is called with multiple arguments.
    /// Categories: @write, @list, @fast
    public func lpushx(key: RedisKey, element: String...) async throws -> RESP3Token {
        let response = try await send(lpushxCommand(key: key, element: element))
        return response
    }
    @inlinable
    public func lpushxCommand(key: RedisKey, element: [String]) -> RESP3Command {
        var arguments: [String] = [key.description]
        arguments.append(contentsOf: element)
        return .init("LPUSHX", arguments: arguments)
    }

    /// Returns a range of elements from a list.
    /// Version: 1.0.0
    /// Complexity: O(S+N) where S is the distance of start offset from HEAD for small lists, from nearest end (HEAD or TAIL) for large lists; and N is the number of elements in the specified range.
    /// Categories: @read, @list, @slow
    public func lrange(key: RedisKey, start: Int, stop: Int) async throws -> RESP3Token {
        let response = try await send(lrangeCommand(key: key, start: start, stop: stop))
        return response
    }
    @inlinable
    public func lrangeCommand(key: RedisKey, start: Int, stop: Int) -> RESP3Command {
        .init("LRANGE", arguments: [key.description, start.description, stop.description])
    }

    /// Removes elements from a list. Deletes the list if the last element was removed.
    /// Version: 1.0.0
    /// Complexity: O(N+M) where N is the length of the list and M is the number of elements removed.
    /// Categories: @write, @list, @slow
    public func lrem(key: RedisKey, count: Int, element: String) async throws -> RESP3Token {
        let response = try await send(lremCommand(key: key, count: count, element: element))
        return response
    }
    @inlinable
    public func lremCommand(key: RedisKey, count: Int, element: String) -> RESP3Command {
        .init("LREM", arguments: [key.description, count.description, element])
    }

    /// Sets the value of an element in a list by its index.
    /// Version: 1.0.0
    /// Complexity: O(N) where N is the length of the list. Setting either the first or the last element of the list is O(1).
    /// Categories: @write, @list, @slow
    public func lset(key: RedisKey, index: Int, element: String) async throws -> RESP3Token {
        let response = try await send(lsetCommand(key: key, index: index, element: element))
        return response
    }
    @inlinable
    public func lsetCommand(key: RedisKey, index: Int, element: String) -> RESP3Command {
        .init("LSET", arguments: [key.description, index.description, element])
    }

    /// Removes elements from both ends a list. Deletes the list if all elements were trimmed.
    /// Version: 1.0.0
    /// Complexity: O(N) where N is the number of elements to be removed by the operation.
    /// Categories: @write, @list, @slow
    public func ltrim(key: RedisKey, start: Int, stop: Int) async throws -> RESP3Token {
        let response = try await send(ltrimCommand(key: key, start: start, stop: stop))
        return response
    }
    @inlinable
    public func ltrimCommand(key: RedisKey, start: Int, stop: Int) -> RESP3Command {
        .init("LTRIM", arguments: [key.description, start.description, stop.description])
    }

    /// A container for memory diagnostics commands.
    /// Version: 4.0.0
    /// Complexity: Depends on subcommand.
    /// Categories: @slow
    public func memory() async throws -> RESP3Token {
        let response = try await send(memoryCommand())
        return response
    }
    @inlinable
    public func memoryCommand() -> RESP3Command {
        .init("MEMORY", arguments: [])
    }

    /// Outputs a memory problems report.
    /// Version: 4.0.0
    /// Complexity: O(1)
    /// Categories: @slow
    public func memoryDoctor() async throws -> RESP3Token {
        let response = try await send(memoryDoctorCommand())
        return response
    }
    @inlinable
    public func memoryDoctorCommand() -> RESP3Command {
        .init("MEMORY", arguments: ["DOCTOR"])
    }

    /// Returns helpful text about the different subcommands.
    /// Version: 4.0.0
    /// Complexity: O(1)
    /// Categories: @slow
    public func memoryHelp() async throws -> RESP3Token {
        let response = try await send(memoryHelpCommand())
        return response
    }
    @inlinable
    public func memoryHelpCommand() -> RESP3Command {
        .init("MEMORY", arguments: ["HELP"])
    }

    /// Returns the allocator statistics.
    /// Version: 4.0.0
    /// Complexity: Depends on how much memory is allocated, could be slow
    /// Categories: @slow
    public func memoryMallocStats() async throws -> RESP3Token {
        let response = try await send(memoryMallocStatsCommand())
        return response
    }
    @inlinable
    public func memoryMallocStatsCommand() -> RESP3Command {
        .init("MEMORY", arguments: ["MALLOC-STATS"])
    }

    /// Asks the allocator to release memory.
    /// Version: 4.0.0
    /// Complexity: Depends on how much memory is allocated, could be slow
    /// Categories: @slow
    public func memoryPurge() async throws -> RESP3Token {
        let response = try await send(memoryPurgeCommand())
        return response
    }
    @inlinable
    public func memoryPurgeCommand() -> RESP3Command {
        .init("MEMORY", arguments: ["PURGE"])
    }

    /// Returns details about memory usage.
    /// Version: 4.0.0
    /// Complexity: O(1)
    /// Categories: @slow
    public func memoryStats() async throws -> RESP3Token {
        let response = try await send(memoryStatsCommand())
        return response
    }
    @inlinable
    public func memoryStatsCommand() -> RESP3Command {
        .init("MEMORY", arguments: ["STATS"])
    }

    /// Estimates the memory usage of a key.
    /// Version: 4.0.0
    /// Complexity: O(N) where N is the number of samples.
    /// Categories: @read, @slow
    public func memoryUsage(key: RedisKey, count: Int) async throws -> RESP3Token {
        let response = try await send(memoryUsageCommand(key: key, count: count))
        return response
    }
    @inlinable
    public func memoryUsageCommand(key: RedisKey, count: Int) -> RESP3Command {
        .init("MEMORY", arguments: ["USAGE", key.description, count.description])
    }

    /// Atomically returns the string values of one or more keys.
    /// Version: 1.0.0
    /// Complexity: O(N) where N is the number of keys to retrieve.
    /// Categories: @read, @string, @fast
    public func mget(key: RedisKey...) async throws -> RESP3Token {
        let response = try await send(mgetCommand(key: key))
        return response
    }
    @inlinable
    public func mgetCommand(key: [RedisKey]) -> RESP3Command {
        let arguments: [String] = key.map(\.description)
        return .init("MGET", arguments: arguments)
    }

    /// A container for module commands.
    /// Version: 4.0.0
    /// Complexity: Depends on subcommand.
    /// Categories: @slow
    public func module() async throws -> RESP3Token {
        let response = try await send(moduleCommand())
        return response
    }
    @inlinable
    public func moduleCommand() -> RESP3Command {
        .init("MODULE", arguments: [])
    }

    /// Returns helpful text about the different subcommands.
    /// Version: 5.0.0
    /// Complexity: O(1)
    /// Categories: @slow
    public func moduleHelp() async throws -> RESP3Token {
        let response = try await send(moduleHelpCommand())
        return response
    }
    @inlinable
    public func moduleHelpCommand() -> RESP3Command {
        .init("MODULE", arguments: ["HELP"])
    }

    /// Returns all loaded modules.
    /// Version: 4.0.0
    /// Complexity: O(N) where N is the number of loaded modules.
    /// Categories: @admin, @slow, @dangerous
    public func moduleList() async throws -> RESP3Token {
        let response = try await send(moduleListCommand())
        return response
    }
    @inlinable
    public func moduleListCommand() -> RESP3Command {
        .init("MODULE", arguments: ["LIST"])
    }

    /// Loads a module.
    /// Version: 4.0.0
    /// Complexity: O(1)
    /// Categories: @admin, @slow, @dangerous
    public func moduleLoad(path: String, arg: String...) async throws -> RESP3Token {
        let response = try await send(moduleLoadCommand(path: path, arg: arg))
        return response
    }
    @inlinable
    public func moduleLoadCommand(path: String, arg: [String]) -> RESP3Command {
        var arguments: [String] = ["LOAD"]
        arguments.append(path)
        arguments.append(contentsOf: arg)
        return .init("MODULE", arguments: arguments)
    }

    /// Unloads a module.
    /// Version: 4.0.0
    /// Complexity: O(1)
    /// Categories: @admin, @slow, @dangerous
    public func moduleUnload(name: String) async throws -> RESP3Token {
        let response = try await send(moduleUnloadCommand(name: name))
        return response
    }
    @inlinable
    public func moduleUnloadCommand(name: String) -> RESP3Command {
        .init("MODULE", arguments: ["UNLOAD", name])
    }

    /// Listens for all requests received by the server in real-time.
    /// Version: 1.0.0
    /// Complexity:
    /// Categories: @admin, @slow, @dangerous
    public func monitor() async throws -> RESP3Token {
        let response = try await send(monitorCommand())
        return response
    }
    @inlinable
    public func monitorCommand() -> RESP3Command {
        .init("MONITOR", arguments: [])
    }

    /// Moves a key to another database.
    /// Version: 1.0.0
    /// Complexity: O(1)
    /// Categories: @keyspace, @write, @fast
    public func move(key: RedisKey, db: Int) async throws -> RESP3Token {
        let response = try await send(moveCommand(key: key, db: db))
        return response
    }
    @inlinable
    public func moveCommand(key: RedisKey, db: Int) -> RESP3Command {
        .init("MOVE", arguments: [key.description, db.description])
    }

    /// Starts a transaction.
    /// Version: 1.2.0
    /// Complexity: O(1)
    /// Categories: @fast, @transaction
    public func multi() async throws -> RESP3Token {
        let response = try await send(multiCommand())
        return response
    }
    @inlinable
    public func multiCommand() -> RESP3Command {
        .init("MULTI", arguments: [])
    }

    /// A container for object introspection commands.
    /// Version: 2.2.3
    /// Complexity: Depends on subcommand.
    /// Categories: @slow
    public func object() async throws -> RESP3Token {
        let response = try await send(objectCommand())
        return response
    }
    @inlinable
    public func objectCommand() -> RESP3Command {
        .init("OBJECT", arguments: [])
    }

    /// Returns the internal encoding of a Redis object.
    /// Version: 2.2.3
    /// Complexity: O(1)
    /// Categories: @keyspace, @read, @slow
    public func objectEncoding(key: RedisKey) async throws -> RESP3Token {
        let response = try await send(objectEncodingCommand(key: key))
        return response
    }
    @inlinable
    public func objectEncodingCommand(key: RedisKey) -> RESP3Command {
        .init("OBJECT", arguments: ["ENCODING", key.description])
    }

    /// Returns the logarithmic access frequency counter of a Redis object.
    /// Version: 4.0.0
    /// Complexity: O(1)
    /// Categories: @keyspace, @read, @slow
    public func objectFreq(key: RedisKey) async throws -> RESP3Token {
        let response = try await send(objectFreqCommand(key: key))
        return response
    }
    @inlinable
    public func objectFreqCommand(key: RedisKey) -> RESP3Command {
        .init("OBJECT", arguments: ["FREQ", key.description])
    }

    /// Returns helpful text about the different subcommands.
    /// Version: 6.2.0
    /// Complexity: O(1)
    /// Categories: @keyspace, @slow
    public func objectHelp() async throws -> RESP3Token {
        let response = try await send(objectHelpCommand())
        return response
    }
    @inlinable
    public func objectHelpCommand() -> RESP3Command {
        .init("OBJECT", arguments: ["HELP"])
    }

    /// Returns the time since the last access to a Redis object.
    /// Version: 2.2.3
    /// Complexity: O(1)
    /// Categories: @keyspace, @read, @slow
    public func objectIdletime(key: RedisKey) async throws -> RESP3Token {
        let response = try await send(objectIdletimeCommand(key: key))
        return response
    }
    @inlinable
    public func objectIdletimeCommand(key: RedisKey) -> RESP3Command {
        .init("OBJECT", arguments: ["IDLETIME", key.description])
    }

    /// Returns the reference count of a value of a key.
    /// Version: 2.2.3
    /// Complexity: O(1)
    /// Categories: @keyspace, @read, @slow
    public func objectRefcount(key: RedisKey) async throws -> RESP3Token {
        let response = try await send(objectRefcountCommand(key: key))
        return response
    }
    @inlinable
    public func objectRefcountCommand(key: RedisKey) -> RESP3Command {
        .init("OBJECT", arguments: ["REFCOUNT", key.description])
    }

    /// Removes the expiration time of a key.
    /// Version: 2.2.0
    /// Complexity: O(1)
    /// Categories: @keyspace, @write, @fast
    public func persist(key: RedisKey) async throws -> RESP3Token {
        let response = try await send(persistCommand(key: key))
        return response
    }
    @inlinable
    public func persistCommand(key: RedisKey) -> RESP3Command {
        .init("PERSIST", arguments: [key.description])
    }

    /// Returns the expiration time of a key as a Unix milliseconds timestamp.
    /// Version: 7.0.0
    /// Complexity: O(1)
    /// Categories: @keyspace, @read, @fast
    public func pexpiretime(key: RedisKey) async throws -> RESP3Token {
        let response = try await send(pexpiretimeCommand(key: key))
        return response
    }
    @inlinable
    public func pexpiretimeCommand(key: RedisKey) -> RESP3Command {
        .init("PEXPIRETIME", arguments: [key.description])
    }

    /// Adds elements to a HyperLogLog key. Creates the key if it doesn't exist.
    /// Version: 2.8.9
    /// Complexity: O(1) to add every element.
    /// Categories: @write, @hyperloglog, @fast
    public func pfadd(key: RedisKey, element: String...) async throws -> RESP3Token {
        let response = try await send(pfaddCommand(key: key, element: element))
        return response
    }
    @inlinable
    public func pfaddCommand(key: RedisKey, element: [String]) -> RESP3Command {
        var arguments: [String] = [key.description]
        arguments.append(contentsOf: element)
        return .init("PFADD", arguments: arguments)
    }

    /// Returns the approximated cardinality of the set(s) observed by the HyperLogLog key(s).
    /// Version: 2.8.9
    /// Complexity: O(1) with a very small average constant time when called with a single key. O(N) with N being the number of keys, and much bigger constant times, when called with multiple keys.
    /// Categories: @read, @hyperloglog, @slow
    public func pfcount(key: RedisKey...) async throws -> RESP3Token {
        let response = try await send(pfcountCommand(key: key))
        return response
    }
    @inlinable
    public func pfcountCommand(key: [RedisKey]) -> RESP3Command {
        let arguments: [String] = key.map(\.description)
        return .init("PFCOUNT", arguments: arguments)
    }

    /// Internal commands for debugging HyperLogLog values.
    /// Version: 2.8.9
    /// Complexity: N/A
    /// Categories: @write, @hyperloglog, @admin, @slow, @dangerous
    public func pfdebug(subcommand: String, key: RedisKey) async throws -> RESP3Token {
        let response = try await send(pfdebugCommand(subcommand: subcommand, key: key))
        return response
    }
    @inlinable
    public func pfdebugCommand(subcommand: String, key: RedisKey) -> RESP3Command {
        .init("PFDEBUG", arguments: [subcommand, key.description])
    }

    /// Merges one or more HyperLogLog values into a single key.
    /// Version: 2.8.9
    /// Complexity: O(N) to merge N HyperLogLogs, but with high constant times.
    /// Categories: @write, @hyperloglog, @slow
    public func pfmerge(destkey: RedisKey, sourcekey: RedisKey...) async throws -> RESP3Token {
        let response = try await send(pfmergeCommand(destkey: destkey, sourcekey: sourcekey))
        return response
    }
    @inlinable
    public func pfmergeCommand(destkey: RedisKey, sourcekey: [RedisKey]) -> RESP3Command {
        var arguments: [String] = [destkey.description]
        arguments.append(contentsOf: sourcekey.map(\.description))
        return .init("PFMERGE", arguments: arguments)
    }

    /// An internal command for testing HyperLogLog values.
    /// Version: 2.8.9
    /// Complexity: N/A
    /// Categories: @hyperloglog, @admin, @slow, @dangerous
    public func pfselftest() async throws -> RESP3Token {
        let response = try await send(pfselftestCommand())
        return response
    }
    @inlinable
    public func pfselftestCommand() -> RESP3Command {
        .init("PFSELFTEST", arguments: [])
    }

    /// Returns the server's liveliness response.
    /// Version: 1.0.0
    /// Complexity: O(1)
    /// Categories: @fast, @connection
    public func ping(message: String) async throws -> RESP3Token {
        let response = try await send(pingCommand(message: message))
        return response
    }
    @inlinable
    public func pingCommand(message: String) -> RESP3Command {
        .init("PING", arguments: [message])
    }

    /// Sets both string value and expiration time in milliseconds of a key. The key is created if it doesn't exist.
    /// Version: 2.6.0
    /// Complexity: O(1)
    /// Categories: @write, @string, @slow
    public func psetex(key: RedisKey, milliseconds: Int, value: String) async throws -> RESP3Token {
        let response = try await send(psetexCommand(key: key, milliseconds: milliseconds, value: value))
        return response
    }
    @inlinable
    public func psetexCommand(key: RedisKey, milliseconds: Int, value: String) -> RESP3Command {
        .init("PSETEX", arguments: [key.description, milliseconds.description, value])
    }

    /// An internal command used in replication.
    /// Version: 2.8.0
    /// Complexity:
    /// Categories: @admin, @slow, @dangerous
    public func psync(replicationid: String, offset: Int) async throws -> RESP3Token {
        let response = try await send(psyncCommand(replicationid: replicationid, offset: offset))
        return response
    }
    @inlinable
    public func psyncCommand(replicationid: String, offset: Int) -> RESP3Command {
        .init("PSYNC", arguments: [replicationid, offset.description])
    }

    /// Returns the expiration time in milliseconds of a key.
    /// Version: 2.6.0
    /// Complexity: O(1)
    /// Categories: @keyspace, @read, @fast
    public func pttl(key: RedisKey) async throws -> RESP3Token {
        let response = try await send(pttlCommand(key: key))
        return response
    }
    @inlinable
    public func pttlCommand(key: RedisKey) -> RESP3Command {
        .init("PTTL", arguments: [key.description])
    }

    /// Posts a message to a channel.
    /// Version: 2.0.0
    /// Complexity: O(N+M) where N is the number of clients subscribed to the receiving channel and M is the total number of subscribed patterns (by any client).
    /// Categories: @pubsub, @fast
    public func publish(channel: String, message: String) async throws -> RESP3Token {
        let response = try await send(publishCommand(channel: channel, message: message))
        return response
    }
    @inlinable
    public func publishCommand(channel: String, message: String) -> RESP3Command {
        .init("PUBLISH", arguments: [channel, message])
    }

    /// A container for Pub/Sub commands.
    /// Version: 2.8.0
    /// Complexity: Depends on subcommand.
    /// Categories: @slow
    public func pubsub() async throws -> RESP3Token {
        let response = try await send(pubsubCommand())
        return response
    }
    @inlinable
    public func pubsubCommand() -> RESP3Command {
        .init("PUBSUB", arguments: [])
    }

    /// Returns helpful text about the different subcommands.
    /// Version: 6.2.0
    /// Complexity: O(1)
    /// Categories: @slow
    public func pubsubHelp() async throws -> RESP3Token {
        let response = try await send(pubsubHelpCommand())
        return response
    }
    @inlinable
    public func pubsubHelpCommand() -> RESP3Command {
        .init("PUBSUB", arguments: ["HELP"])
    }

    /// Returns a count of unique pattern subscriptions.
    /// Version: 2.8.0
    /// Complexity: O(1)
    /// Categories: @pubsub, @slow
    public func pubsubNumpat() async throws -> RESP3Token {
        let response = try await send(pubsubNumpatCommand())
        return response
    }
    @inlinable
    public func pubsubNumpatCommand() -> RESP3Command {
        .init("PUBSUB", arguments: ["NUMPAT"])
    }

    /// Returns a count of subscribers to channels.
    /// Version: 2.8.0
    /// Complexity: O(N) for the NUMSUB subcommand, where N is the number of requested channels
    /// Categories: @pubsub, @slow
    public func pubsubNumsub(channel: String...) async throws -> RESP3Token {
        let response = try await send(pubsubNumsubCommand(channel: channel))
        return response
    }
    @inlinable
    public func pubsubNumsubCommand(channel: [String]) -> RESP3Command {
        var arguments: [String] = ["NUMSUB"]
        arguments.append(contentsOf: channel)
        return .init("PUBSUB", arguments: arguments)
    }

    /// Returns the count of subscribers of shard channels.
    /// Version: 7.0.0
    /// Complexity: O(N) for the SHARDNUMSUB subcommand, where N is the number of requested shard channels
    /// Categories: @pubsub, @slow
    public func pubsubShardnumsub(shardchannel: String...) async throws -> RESP3Token {
        let response = try await send(pubsubShardnumsubCommand(shardchannel: shardchannel))
        return response
    }
    @inlinable
    public func pubsubShardnumsubCommand(shardchannel: [String]) -> RESP3Command {
        var arguments: [String] = ["SHARDNUMSUB"]
        arguments.append(contentsOf: shardchannel)
        return .init("PUBSUB", arguments: arguments)
    }

    /// Closes the connection.
    /// Version: 1.0.0
    /// Complexity: O(1)
    /// Categories: @fast, @connection
    public func quit() async throws -> RESP3Token {
        let response = try await send(quitCommand())
        return response
    }
    @inlinable
    public func quitCommand() -> RESP3Command {
        .init("QUIT", arguments: [])
    }

    /// Returns a random key name from the database.
    /// Version: 1.0.0
    /// Complexity: O(1)
    /// Categories: @keyspace, @read, @slow
    public func randomkey() async throws -> RESP3Token {
        let response = try await send(randomkeyCommand())
        return response
    }
    @inlinable
    public func randomkeyCommand() -> RESP3Command {
        .init("RANDOMKEY", arguments: [])
    }

    /// Enables read-only queries for a connection to a Redis Cluster replica node.
    /// Version: 3.0.0
    /// Complexity: O(1)
    /// Categories: @fast, @connection
    public func readonly() async throws -> RESP3Token {
        let response = try await send(readonlyCommand())
        return response
    }
    @inlinable
    public func readonlyCommand() -> RESP3Command {
        .init("READONLY", arguments: [])
    }

    /// Enables read-write queries for a connection to a Reids Cluster replica node.
    /// Version: 3.0.0
    /// Complexity: O(1)
    /// Categories: @fast, @connection
    public func readwrite() async throws -> RESP3Token {
        let response = try await send(readwriteCommand())
        return response
    }
    @inlinable
    public func readwriteCommand() -> RESP3Command {
        .init("READWRITE", arguments: [])
    }

    /// Renames a key and overwrites the destination.
    /// Version: 1.0.0
    /// Complexity: O(1)
    /// Categories: @keyspace, @write, @slow
    public func rename(key: RedisKey, newkey: RedisKey) async throws -> RESP3Token {
        let response = try await send(renameCommand(key: key, newkey: newkey))
        return response
    }
    @inlinable
    public func renameCommand(key: RedisKey, newkey: RedisKey) -> RESP3Command {
        .init("RENAME", arguments: [key.description, newkey.description])
    }

    /// Renames a key only when the target key name doesn't exist.
    /// Version: 1.0.0
    /// Complexity: O(1)
    /// Categories: @keyspace, @write, @fast
    public func renamenx(key: RedisKey, newkey: RedisKey) async throws -> RESP3Token {
        let response = try await send(renamenxCommand(key: key, newkey: newkey))
        return response
    }
    @inlinable
    public func renamenxCommand(key: RedisKey, newkey: RedisKey) -> RESP3Command {
        .init("RENAMENX", arguments: [key.description, newkey.description])
    }

    /// An internal command for configuring the replication stream.
    /// Version: 3.0.0
    /// Complexity: O(1)
    /// Categories: @admin, @slow, @dangerous
    public func replconf() async throws -> RESP3Token {
        let response = try await send(replconfCommand())
        return response
    }
    @inlinable
    public func replconfCommand() -> RESP3Command {
        .init("REPLCONF", arguments: [])
    }

    /// Resets the connection.
    /// Version: 6.2.0
    /// Complexity: O(1)
    /// Categories: @fast, @connection
    public func reset() async throws -> RESP3Token {
        let response = try await send(resetCommand())
        return response
    }
    @inlinable
    public func resetCommand() -> RESP3Command {
        .init("RESET", arguments: [])
    }

    /// Creates a key from the serialized representation of a value.
    /// Version: 2.6.0
    /// Complexity: O(1) to create the new key and additional O(N*M) to reconstruct the serialized value, where N is the number of Redis objects composing the value and M their average size. For small string values the time complexity is thus O(1)+O(1*M) where M is small, so simply O(1). However for sorted set values the complexity is O(N*M*log(N)) because inserting values into sorted sets is O(log(N)).
    /// Categories: @keyspace, @write, @slow, @dangerous
    public func restore(
        key: RedisKey,
        ttl: Int,
        serializedValue: String,
        replace: Bool,
        absttl: Bool,
        seconds: Int,
        frequency: Int
    ) async throws -> RESP3Token {
        let response = try await send(
            restoreCommand(
                key: key,
                ttl: ttl,
                serializedValue: serializedValue,
                replace: replace,
                absttl: absttl,
                seconds: seconds,
                frequency: frequency
            )
        )
        return response
    }
    @inlinable
    public func restoreCommand(
        key: RedisKey,
        ttl: Int,
        serializedValue: String,
        replace: Bool,
        absttl: Bool,
        seconds: Int,
        frequency: Int
    ) -> RESP3Command {
        .init(
            "RESTORE",
            arguments: [
                key.description, ttl.description, serializedValue, replace.description, absttl.description, seconds.description,
                frequency.description,
            ]
        )
    }

    /// An internal command for migrating keys in a cluster.
    /// Version: 3.0.0
    /// Complexity: O(1) to create the new key and additional O(N*M) to reconstruct the serialized value, where N is the number of Redis objects composing the value and M their average size. For small string values the time complexity is thus O(1)+O(1*M) where M is small, so simply O(1). However for sorted set values the complexity is O(N*M*log(N)) because inserting values into sorted sets is O(log(N)).
    /// Categories: @keyspace, @write, @slow, @dangerous
    public func restoreAsking(
        key: RedisKey,
        ttl: Int,
        serializedValue: String,
        replace: Bool,
        absttl: Bool,
        seconds: Int,
        frequency: Int
    ) async throws -> RESP3Token {
        let response = try await send(
            restoreAskingCommand(
                key: key,
                ttl: ttl,
                serializedValue: serializedValue,
                replace: replace,
                absttl: absttl,
                seconds: seconds,
                frequency: frequency
            )
        )
        return response
    }
    @inlinable
    public func restoreAskingCommand(
        key: RedisKey,
        ttl: Int,
        serializedValue: String,
        replace: Bool,
        absttl: Bool,
        seconds: Int,
        frequency: Int
    ) -> RESP3Command {
        .init(
            "RESTORE-ASKING",
            arguments: [
                key.description, ttl.description, serializedValue, replace.description, absttl.description, seconds.description,
                frequency.description,
            ]
        )
    }

    /// Returns the replication role.
    /// Version: 2.8.12
    /// Complexity: O(1)
    /// Categories: @admin, @fast, @dangerous
    public func role() async throws -> RESP3Token {
        let response = try await send(roleCommand())
        return response
    }
    @inlinable
    public func roleCommand() -> RESP3Command {
        .init("ROLE", arguments: [])
    }

    /// Returns and removes the last elements of a list. Deletes the list if the last element was popped.
    /// Version: 1.0.0
    /// Complexity: O(N) where N is the number of elements returned
    /// Categories: @write, @list, @fast
    public func rpop(key: RedisKey, count: Int) async throws -> RESP3Token {
        let response = try await send(rpopCommand(key: key, count: count))
        return response
    }
    @inlinable
    public func rpopCommand(key: RedisKey, count: Int) -> RESP3Command {
        .init("RPOP", arguments: [key.description, count.description])
    }

    /// Returns the last element of a list after removing and pushing it to another list. Deletes the list if the last element was popped.
    /// Version: 1.2.0
    /// Complexity: O(1)
    /// Categories: @write, @list, @slow
    public func rpoplpush(source: RedisKey, destination: RedisKey) async throws -> RESP3Token {
        let response = try await send(rpoplpushCommand(source: source, destination: destination))
        return response
    }
    @inlinable
    public func rpoplpushCommand(source: RedisKey, destination: RedisKey) -> RESP3Command {
        .init("RPOPLPUSH", arguments: [source.description, destination.description])
    }

    /// Appends one or more elements to a list. Creates the key if it doesn't exist.
    /// Version: 1.0.0
    /// Complexity: O(1) for each element added, so O(N) to add N elements when the command is called with multiple arguments.
    /// Categories: @write, @list, @fast
    public func rpush(key: RedisKey, element: String...) async throws -> RESP3Token {
        let response = try await send(rpushCommand(key: key, element: element))
        return response
    }
    @inlinable
    public func rpushCommand(key: RedisKey, element: [String]) -> RESP3Command {
        var arguments: [String] = [key.description]
        arguments.append(contentsOf: element)
        return .init("RPUSH", arguments: arguments)
    }

    /// Appends an element to a list only when the list exists.
    /// Version: 2.2.0
    /// Complexity: O(1) for each element added, so O(N) to add N elements when the command is called with multiple arguments.
    /// Categories: @write, @list, @fast
    public func rpushx(key: RedisKey, element: String...) async throws -> RESP3Token {
        let response = try await send(rpushxCommand(key: key, element: element))
        return response
    }
    @inlinable
    public func rpushxCommand(key: RedisKey, element: [String]) -> RESP3Command {
        var arguments: [String] = [key.description]
        arguments.append(contentsOf: element)
        return .init("RPUSHX", arguments: arguments)
    }

    /// Adds one or more members to a set. Creates the key if it doesn't exist.
    /// Version: 1.0.0
    /// Complexity: O(1) for each element added, so O(N) to add N elements when the command is called with multiple arguments.
    /// Categories: @write, @set, @fast
    public func sadd(key: RedisKey, member: String...) async throws -> RESP3Token {
        let response = try await send(saddCommand(key: key, member: member))
        return response
    }
    @inlinable
    public func saddCommand(key: RedisKey, member: [String]) -> RESP3Command {
        var arguments: [String] = [key.description]
        arguments.append(contentsOf: member)
        return .init("SADD", arguments: arguments)
    }

    /// Synchronously saves the database(s) to disk.
    /// Version: 1.0.0
    /// Complexity: O(N) where N is the total number of keys in all databases
    /// Categories: @admin, @slow, @dangerous
    public func save() async throws -> RESP3Token {
        let response = try await send(saveCommand())
        return response
    }
    @inlinable
    public func saveCommand() -> RESP3Command {
        .init("SAVE", arguments: [])
    }

    /// Returns the number of members in a set.
    /// Version: 1.0.0
    /// Complexity: O(1)
    /// Categories: @read, @set, @fast
    public func scard(key: RedisKey) async throws -> RESP3Token {
        let response = try await send(scardCommand(key: key))
        return response
    }
    @inlinable
    public func scardCommand(key: RedisKey) -> RESP3Command {
        .init("SCARD", arguments: [key.description])
    }

    /// A container for Lua scripts management commands.
    /// Version: 2.6.0
    /// Complexity: Depends on subcommand.
    /// Categories: @slow
    public func script() async throws -> RESP3Token {
        let response = try await send(scriptCommand())
        return response
    }
    @inlinable
    public func scriptCommand() -> RESP3Command {
        .init("SCRIPT", arguments: [])
    }

    /// Determines whether server-side Lua scripts exist in the script cache.
    /// Version: 2.6.0
    /// Complexity: O(N) with N being the number of scripts to check (so checking a single script is an O(1) operation).
    /// Categories: @slow, @scripting
    public func scriptExists(sha1: String...) async throws -> RESP3Token {
        let response = try await send(scriptExistsCommand(sha1: sha1))
        return response
    }
    @inlinable
    public func scriptExistsCommand(sha1: [String]) -> RESP3Command {
        var arguments: [String] = ["EXISTS"]
        arguments.append(contentsOf: sha1)
        return .init("SCRIPT", arguments: arguments)
    }

    /// Returns helpful text about the different subcommands.
    /// Version: 5.0.0
    /// Complexity: O(1)
    /// Categories: @slow, @scripting
    public func scriptHelp() async throws -> RESP3Token {
        let response = try await send(scriptHelpCommand())
        return response
    }
    @inlinable
    public func scriptHelpCommand() -> RESP3Command {
        .init("SCRIPT", arguments: ["HELP"])
    }

    /// Terminates a server-side Lua script during execution.
    /// Version: 2.6.0
    /// Complexity: O(1)
    /// Categories: @slow, @scripting
    public func scriptKill() async throws -> RESP3Token {
        let response = try await send(scriptKillCommand())
        return response
    }
    @inlinable
    public func scriptKillCommand() -> RESP3Command {
        .init("SCRIPT", arguments: ["KILL"])
    }

    /// Loads a server-side Lua script to the script cache.
    /// Version: 2.6.0
    /// Complexity: O(N) with N being the length in bytes of the script body.
    /// Categories: @slow, @scripting
    public func scriptLoad(script: String) async throws -> RESP3Token {
        let response = try await send(scriptLoadCommand(script: script))
        return response
    }
    @inlinable
    public func scriptLoadCommand(script: String) -> RESP3Command {
        .init("SCRIPT", arguments: ["LOAD", script])
    }

    /// Returns the difference of multiple sets.
    /// Version: 1.0.0
    /// Complexity: O(N) where N is the total number of elements in all given sets.
    /// Categories: @read, @set, @slow
    public func sdiff(key: RedisKey...) async throws -> RESP3Token {
        let response = try await send(sdiffCommand(key: key))
        return response
    }
    @inlinable
    public func sdiffCommand(key: [RedisKey]) -> RESP3Command {
        let arguments: [String] = key.map(\.description)
        return .init("SDIFF", arguments: arguments)
    }

    /// Stores the difference of multiple sets in a key.
    /// Version: 1.0.0
    /// Complexity: O(N) where N is the total number of elements in all given sets.
    /// Categories: @write, @set, @slow
    public func sdiffstore(destination: RedisKey, key: RedisKey...) async throws -> RESP3Token {
        let response = try await send(sdiffstoreCommand(destination: destination, key: key))
        return response
    }
    @inlinable
    public func sdiffstoreCommand(destination: RedisKey, key: [RedisKey]) -> RESP3Command {
        var arguments: [String] = [destination.description]
        arguments.append(contentsOf: key.map(\.description))
        return .init("SDIFFSTORE", arguments: arguments)
    }

    /// Changes the selected database.
    /// Version: 1.0.0
    /// Complexity: O(1)
    /// Categories: @fast, @connection
    public func select(index: Int) async throws -> RESP3Token {
        let response = try await send(selectCommand(index: index))
        return response
    }
    @inlinable
    public func selectCommand(index: Int) -> RESP3Command {
        .init("SELECT", arguments: [index.description])
    }

    /// Sets or clears the bit at offset of the string value. Creates the key if it doesn't exist.
    /// Version: 2.2.0
    /// Complexity: O(1)
    /// Categories: @write, @bitmap, @slow
    public func setbit(key: RedisKey, offset: Int, value: Int) async throws -> RESP3Token {
        let response = try await send(setbitCommand(key: key, offset: offset, value: value))
        return response
    }
    @inlinable
    public func setbitCommand(key: RedisKey, offset: Int, value: Int) -> RESP3Command {
        .init("SETBIT", arguments: [key.description, offset.description, value.description])
    }

    /// Sets the string value and expiration time of a key. Creates the key if it doesn't exist.
    /// Version: 2.0.0
    /// Complexity: O(1)
    /// Categories: @write, @string, @slow
    public func setex(key: RedisKey, seconds: Int, value: String) async throws -> RESP3Token {
        let response = try await send(setexCommand(key: key, seconds: seconds, value: value))
        return response
    }
    @inlinable
    public func setexCommand(key: RedisKey, seconds: Int, value: String) -> RESP3Command {
        .init("SETEX", arguments: [key.description, seconds.description, value])
    }

    /// Set the string value of a key only when the key doesn't exist.
    /// Version: 1.0.0
    /// Complexity: O(1)
    /// Categories: @write, @string, @fast
    public func setnx(key: RedisKey, value: String) async throws -> RESP3Token {
        let response = try await send(setnxCommand(key: key, value: value))
        return response
    }
    @inlinable
    public func setnxCommand(key: RedisKey, value: String) -> RESP3Command {
        .init("SETNX", arguments: [key.description, value])
    }

    /// Overwrites a part of a string value with another by an offset. Creates the key if it doesn't exist.
    /// Version: 2.2.0
    /// Complexity: O(1), not counting the time taken to copy the new string in place. Usually, this string is very small so the amortized complexity is O(1). Otherwise, complexity is O(M) with M being the length of the value argument.
    /// Categories: @write, @string, @slow
    public func setrange(key: RedisKey, offset: Int, value: String) async throws -> RESP3Token {
        let response = try await send(setrangeCommand(key: key, offset: offset, value: value))
        return response
    }
    @inlinable
    public func setrangeCommand(key: RedisKey, offset: Int, value: String) -> RESP3Command {
        .init("SETRANGE", arguments: [key.description, offset.description, value])
    }

    /// Returns the intersect of multiple sets.
    /// Version: 1.0.0
    /// Complexity: O(N*M) worst case where N is the cardinality of the smallest set and M is the number of sets.
    /// Categories: @read, @set, @slow
    public func sinter(key: RedisKey...) async throws -> RESP3Token {
        let response = try await send(sinterCommand(key: key))
        return response
    }
    @inlinable
    public func sinterCommand(key: [RedisKey]) -> RESP3Command {
        let arguments: [String] = key.map(\.description)
        return .init("SINTER", arguments: arguments)
    }

    /// Returns the number of members of the intersect of multiple sets.
    /// Version: 7.0.0
    /// Complexity: O(N*M) worst case where N is the cardinality of the smallest set and M is the number of sets.
    /// Categories: @read, @set, @slow
    public func sintercard(numkeys: Int, key: RedisKey..., limit: Int) async throws -> RESP3Token {
        let response = try await send(sintercardCommand(numkeys: numkeys, key: key, limit: limit))
        return response
    }
    @inlinable
    public func sintercardCommand(numkeys: Int, key: [RedisKey], limit: Int) -> RESP3Command {
        var arguments: [String] = [numkeys.description]
        arguments.append(contentsOf: key.map(\.description))
        arguments.append(limit.description)
        return .init("SINTERCARD", arguments: arguments)
    }

    /// Stores the intersect of multiple sets in a key.
    /// Version: 1.0.0
    /// Complexity: O(N*M) worst case where N is the cardinality of the smallest set and M is the number of sets.
    /// Categories: @write, @set, @slow
    public func sinterstore(destination: RedisKey, key: RedisKey...) async throws -> RESP3Token {
        let response = try await send(sinterstoreCommand(destination: destination, key: key))
        return response
    }
    @inlinable
    public func sinterstoreCommand(destination: RedisKey, key: [RedisKey]) -> RESP3Command {
        var arguments: [String] = [destination.description]
        arguments.append(contentsOf: key.map(\.description))
        return .init("SINTERSTORE", arguments: arguments)
    }

    /// Determines whether a member belongs to a set.
    /// Version: 1.0.0
    /// Complexity: O(1)
    /// Categories: @read, @set, @fast
    public func sismember(key: RedisKey, member: String) async throws -> RESP3Token {
        let response = try await send(sismemberCommand(key: key, member: member))
        return response
    }
    @inlinable
    public func sismemberCommand(key: RedisKey, member: String) -> RESP3Command {
        .init("SISMEMBER", arguments: [key.description, member])
    }

    /// A container for slow log commands.
    /// Version: 2.2.12
    /// Complexity: Depends on subcommand.
    /// Categories: @slow
    public func slowlog() async throws -> RESP3Token {
        let response = try await send(slowlogCommand())
        return response
    }
    @inlinable
    public func slowlogCommand() -> RESP3Command {
        .init("SLOWLOG", arguments: [])
    }

    /// Returns the slow log's entries.
    /// Version: 2.2.12
    /// Complexity: O(N) where N is the number of entries returned
    /// Categories: @admin, @slow, @dangerous
    public func slowlogGet(count: Int) async throws -> RESP3Token {
        let response = try await send(slowlogGetCommand(count: count))
        return response
    }
    @inlinable
    public func slowlogGetCommand(count: Int) -> RESP3Command {
        .init("SLOWLOG", arguments: ["GET", count.description])
    }

    /// Show helpful text about the different subcommands
    /// Version: 6.2.0
    /// Complexity: O(1)
    /// Categories: @slow
    public func slowlogHelp() async throws -> RESP3Token {
        let response = try await send(slowlogHelpCommand())
        return response
    }
    @inlinable
    public func slowlogHelpCommand() -> RESP3Command {
        .init("SLOWLOG", arguments: ["HELP"])
    }

    /// Returns the number of entries in the slow log.
    /// Version: 2.2.12
    /// Complexity: O(1)
    /// Categories: @admin, @slow, @dangerous
    public func slowlogLen() async throws -> RESP3Token {
        let response = try await send(slowlogLenCommand())
        return response
    }
    @inlinable
    public func slowlogLenCommand() -> RESP3Command {
        .init("SLOWLOG", arguments: ["LEN"])
    }

    /// Clears all entries from the slow log.
    /// Version: 2.2.12
    /// Complexity: O(N) where N is the number of entries in the slowlog
    /// Categories: @admin, @slow, @dangerous
    public func slowlogReset() async throws -> RESP3Token {
        let response = try await send(slowlogResetCommand())
        return response
    }
    @inlinable
    public func slowlogResetCommand() -> RESP3Command {
        .init("SLOWLOG", arguments: ["RESET"])
    }

    /// Returns all members of a set.
    /// Version: 1.0.0
    /// Complexity: O(N) where N is the set cardinality.
    /// Categories: @read, @set, @slow
    public func smembers(key: RedisKey) async throws -> RESP3Token {
        let response = try await send(smembersCommand(key: key))
        return response
    }
    @inlinable
    public func smembersCommand(key: RedisKey) -> RESP3Command {
        .init("SMEMBERS", arguments: [key.description])
    }

    /// Determines whether multiple members belong to a set.
    /// Version: 6.2.0
    /// Complexity: O(N) where N is the number of elements being checked for membership
    /// Categories: @read, @set, @fast
    public func smismember(key: RedisKey, member: String...) async throws -> RESP3Token {
        let response = try await send(smismemberCommand(key: key, member: member))
        return response
    }
    @inlinable
    public func smismemberCommand(key: RedisKey, member: [String]) -> RESP3Command {
        var arguments: [String] = [key.description]
        arguments.append(contentsOf: member)
        return .init("SMISMEMBER", arguments: arguments)
    }

    /// Moves a member from one set to another.
    /// Version: 1.0.0
    /// Complexity: O(1)
    /// Categories: @write, @set, @fast
    public func smove(source: RedisKey, destination: RedisKey, member: String) async throws -> RESP3Token {
        let response = try await send(smoveCommand(source: source, destination: destination, member: member))
        return response
    }
    @inlinable
    public func smoveCommand(source: RedisKey, destination: RedisKey, member: String) -> RESP3Command {
        .init("SMOVE", arguments: [source.description, destination.description, member])
    }

    /// Returns one or more random members from a set after removing them. Deletes the set if the last member was popped.
    /// Version: 1.0.0
    /// Complexity: Without the count argument O(1), otherwise O(N) where N is the value of the passed count.
    /// Categories: @write, @set, @fast
    public func spop(key: RedisKey, count: Int) async throws -> RESP3Token {
        let response = try await send(spopCommand(key: key, count: count))
        return response
    }
    @inlinable
    public func spopCommand(key: RedisKey, count: Int) -> RESP3Command {
        .init("SPOP", arguments: [key.description, count.description])
    }

    /// Post a message to a shard channel
    /// Version: 7.0.0
    /// Complexity: O(N) where N is the number of clients subscribed to the receiving shard channel.
    /// Categories: @pubsub, @fast
    public func spublish(shardchannel: String, message: String) async throws -> RESP3Token {
        let response = try await send(spublishCommand(shardchannel: shardchannel, message: message))
        return response
    }
    @inlinable
    public func spublishCommand(shardchannel: String, message: String) -> RESP3Command {
        .init("SPUBLISH", arguments: [shardchannel, message])
    }

    /// Get one or multiple random members from a set
    /// Version: 1.0.0
    /// Complexity: Without the count argument O(1), otherwise O(N) where N is the absolute value of the passed count.
    /// Categories: @read, @set, @slow
    public func srandmember(key: RedisKey, count: Int) async throws -> RESP3Token {
        let response = try await send(srandmemberCommand(key: key, count: count))
        return response
    }
    @inlinable
    public func srandmemberCommand(key: RedisKey, count: Int) -> RESP3Command {
        .init("SRANDMEMBER", arguments: [key.description, count.description])
    }

    /// Removes one or more members from a set. Deletes the set if the last member was removed.
    /// Version: 1.0.0
    /// Complexity: O(N) where N is the number of members to be removed.
    /// Categories: @write, @set, @fast
    public func srem(key: RedisKey, member: String...) async throws -> RESP3Token {
        let response = try await send(sremCommand(key: key, member: member))
        return response
    }
    @inlinable
    public func sremCommand(key: RedisKey, member: [String]) -> RESP3Command {
        var arguments: [String] = [key.description]
        arguments.append(contentsOf: member)
        return .init("SREM", arguments: arguments)
    }

    /// Listens for messages published to shard channels.
    /// Version: 7.0.0
    /// Complexity: O(N) where N is the number of shard channels to subscribe to.
    /// Categories: @pubsub, @slow
    public func ssubscribe(shardchannel: String...) async throws -> RESP3Token {
        let response = try await send(ssubscribeCommand(shardchannel: shardchannel))
        return response
    }
    @inlinable
    public func ssubscribeCommand(shardchannel: [String]) -> RESP3Command {
        let arguments: [String] = shardchannel
        return .init("SSUBSCRIBE", arguments: arguments)
    }

    /// Returns the length of a string value.
    /// Version: 2.2.0
    /// Complexity: O(1)
    /// Categories: @read, @string, @fast
    public func strlen(key: RedisKey) async throws -> RESP3Token {
        let response = try await send(strlenCommand(key: key))
        return response
    }
    @inlinable
    public func strlenCommand(key: RedisKey) -> RESP3Command {
        .init("STRLEN", arguments: [key.description])
    }

    /// Listens for messages published to channels.
    /// Version: 2.0.0
    /// Complexity: O(N) where N is the number of channels to subscribe to.
    /// Categories: @pubsub, @slow
    public func subscribe(channel: String...) async throws -> RESP3Token {
        let response = try await send(subscribeCommand(channel: channel))
        return response
    }
    @inlinable
    public func subscribeCommand(channel: [String]) -> RESP3Command {
        let arguments: [String] = channel
        return .init("SUBSCRIBE", arguments: arguments)
    }

    /// Returns a substring from a string value.
    /// Version: 1.0.0
    /// Complexity: O(N) where N is the length of the returned string. The complexity is ultimately determined by the returned length, but because creating a substring from an existing string is very cheap, it can be considered O(1) for small strings.
    /// Categories: @read, @string, @slow
    public func substr(key: RedisKey, start: Int, end: Int) async throws -> RESP3Token {
        let response = try await send(substrCommand(key: key, start: start, end: end))
        return response
    }
    @inlinable
    public func substrCommand(key: RedisKey, start: Int, end: Int) -> RESP3Command {
        .init("SUBSTR", arguments: [key.description, start.description, end.description])
    }

    /// Returns the union of multiple sets.
    /// Version: 1.0.0
    /// Complexity: O(N) where N is the total number of elements in all given sets.
    /// Categories: @read, @set, @slow
    public func sunion(key: RedisKey...) async throws -> RESP3Token {
        let response = try await send(sunionCommand(key: key))
        return response
    }
    @inlinable
    public func sunionCommand(key: [RedisKey]) -> RESP3Command {
        let arguments: [String] = key.map(\.description)
        return .init("SUNION", arguments: arguments)
    }

    /// Stores the union of multiple sets in a key.
    /// Version: 1.0.0
    /// Complexity: O(N) where N is the total number of elements in all given sets.
    /// Categories: @write, @set, @slow
    public func sunionstore(destination: RedisKey, key: RedisKey...) async throws -> RESP3Token {
        let response = try await send(sunionstoreCommand(destination: destination, key: key))
        return response
    }
    @inlinable
    public func sunionstoreCommand(destination: RedisKey, key: [RedisKey]) -> RESP3Command {
        var arguments: [String] = [destination.description]
        arguments.append(contentsOf: key.map(\.description))
        return .init("SUNIONSTORE", arguments: arguments)
    }

    /// Stops listening to messages posted to shard channels.
    /// Version: 7.0.0
    /// Complexity: O(N) where N is the number of shard channels to unsubscribe.
    /// Categories: @pubsub, @slow
    public func sunsubscribe(shardchannel: String...) async throws -> RESP3Token {
        let response = try await send(sunsubscribeCommand(shardchannel: shardchannel))
        return response
    }
    @inlinable
    public func sunsubscribeCommand(shardchannel: [String]) -> RESP3Command {
        let arguments: [String] = shardchannel
        return .init("SUNSUBSCRIBE", arguments: arguments)
    }

    /// Swaps two Redis databases.
    /// Version: 4.0.0
    /// Complexity: O(N) where N is the count of clients watching or blocking on keys from both databases.
    /// Categories: @keyspace, @write, @fast, @dangerous
    public func swapdb(index1: Int, index2: Int) async throws -> RESP3Token {
        let response = try await send(swapdbCommand(index1: index1, index2: index2))
        return response
    }
    @inlinable
    public func swapdbCommand(index1: Int, index2: Int) -> RESP3Command {
        .init("SWAPDB", arguments: [index1.description, index2.description])
    }

    /// An internal command used in replication.
    /// Version: 1.0.0
    /// Complexity:
    /// Categories: @admin, @slow, @dangerous
    public func sync() async throws -> RESP3Token {
        let response = try await send(syncCommand())
        return response
    }
    @inlinable
    public func syncCommand() -> RESP3Command {
        .init("SYNC", arguments: [])
    }

    /// Returns the server time.
    /// Version: 2.6.0
    /// Complexity: O(1)
    /// Categories: @fast
    public func time() async throws -> RESP3Token {
        let response = try await send(timeCommand())
        return response
    }
    @inlinable
    public func timeCommand() -> RESP3Command {
        .init("TIME", arguments: [])
    }

    /// Returns the number of existing keys out of those specified after updating the time they were last accessed.
    /// Version: 3.2.1
    /// Complexity: O(N) where N is the number of keys that will be touched.
    /// Categories: @keyspace, @read, @fast
    public func touch(key: RedisKey...) async throws -> RESP3Token {
        let response = try await send(touchCommand(key: key))
        return response
    }
    @inlinable
    public func touchCommand(key: [RedisKey]) -> RESP3Command {
        let arguments: [String] = key.map(\.description)
        return .init("TOUCH", arguments: arguments)
    }

    /// Returns the expiration time in seconds of a key.
    /// Version: 1.0.0
    /// Complexity: O(1)
    /// Categories: @keyspace, @read, @fast
    public func ttl(key: RedisKey) async throws -> RESP3Token {
        let response = try await send(ttlCommand(key: key))
        return response
    }
    @inlinable
    public func ttlCommand(key: RedisKey) -> RESP3Command {
        .init("TTL", arguments: [key.description])
    }

    /// Determines the type of value stored at a key.
    /// Version: 1.0.0
    /// Complexity: O(1)
    /// Categories: @keyspace, @read, @fast
    public func type(key: RedisKey) async throws -> RESP3Token {
        let response = try await send(typeCommand(key: key))
        return response
    }
    @inlinable
    public func typeCommand(key: RedisKey) -> RESP3Command {
        .init("TYPE", arguments: [key.description])
    }

    /// Asynchronously deletes one or more keys.
    /// Version: 4.0.0
    /// Complexity: O(1) for each key removed regardless of its size. Then the command does O(N) work in a different thread in order to reclaim memory, where N is the number of allocations the deleted objects where composed of.
    /// Categories: @keyspace, @write, @fast
    public func unlink(key: RedisKey...) async throws -> RESP3Token {
        let response = try await send(unlinkCommand(key: key))
        return response
    }
    @inlinable
    public func unlinkCommand(key: [RedisKey]) -> RESP3Command {
        let arguments: [String] = key.map(\.description)
        return .init("UNLINK", arguments: arguments)
    }

    /// Stops listening to messages posted to channels.
    /// Version: 2.0.0
    /// Complexity: O(N) where N is the number of channels to unsubscribe.
    /// Categories: @pubsub, @slow
    public func unsubscribe(channel: String...) async throws -> RESP3Token {
        let response = try await send(unsubscribeCommand(channel: channel))
        return response
    }
    @inlinable
    public func unsubscribeCommand(channel: [String]) -> RESP3Command {
        let arguments: [String] = channel
        return .init("UNSUBSCRIBE", arguments: arguments)
    }

    /// Forgets about watched keys of a transaction.
    /// Version: 2.2.0
    /// Complexity: O(1)
    /// Categories: @fast, @transaction
    public func unwatch() async throws -> RESP3Token {
        let response = try await send(unwatchCommand())
        return response
    }
    @inlinable
    public func unwatchCommand() -> RESP3Command {
        .init("UNWATCH", arguments: [])
    }

    /// Blocks until the asynchronous replication of all preceding write commands sent by the connection is completed.
    /// Version: 3.0.0
    /// Complexity: O(1)
    /// Categories: @slow, @connection
    public func wait(numreplicas: Int, timeout: Int) async throws -> RESP3Token {
        let response = try await send(waitCommand(numreplicas: numreplicas, timeout: timeout))
        return response
    }
    @inlinable
    public func waitCommand(numreplicas: Int, timeout: Int) -> RESP3Command {
        .init("WAIT", arguments: [numreplicas.description, timeout.description])
    }

    /// Blocks until all of the preceding write commands sent by the connection are written to the append-only file of the master and/or replicas.
    /// Version: 7.2.0
    /// Complexity: O(1)
    /// Categories: @slow, @connection
    public func waitaof(numlocal: Int, numreplicas: Int, timeout: Int) async throws -> RESP3Token {
        let response = try await send(waitaofCommand(numlocal: numlocal, numreplicas: numreplicas, timeout: timeout))
        return response
    }
    @inlinable
    public func waitaofCommand(numlocal: Int, numreplicas: Int, timeout: Int) -> RESP3Command {
        .init("WAITAOF", arguments: [numlocal.description, numreplicas.description, timeout.description])
    }

    /// Monitors changes to keys to determine the execution of a transaction.
    /// Version: 2.2.0
    /// Complexity: O(1) for every key.
    /// Categories: @fast, @transaction
    public func watch(key: RedisKey...) async throws -> RESP3Token {
        let response = try await send(watchCommand(key: key))
        return response
    }
    @inlinable
    public func watchCommand(key: [RedisKey]) -> RESP3Command {
        let arguments: [String] = key.map(\.description)
        return .init("WATCH", arguments: arguments)
    }

    /// Returns the number of messages that were successfully acknowledged by the consumer group member of a stream.
    /// Version: 5.0.0
    /// Complexity: O(1) for each message ID processed.
    /// Categories: @write, @stream, @fast
    public func xack(key: RedisKey, group: String, id: String...) async throws -> RESP3Token {
        let response = try await send(xackCommand(key: key, group: group, id: id))
        return response
    }
    @inlinable
    public func xackCommand(key: RedisKey, group: String, id: [String]) -> RESP3Command {
        var arguments: [String] = [key.description]
        arguments.append(group)
        arguments.append(contentsOf: id)
        return .init("XACK", arguments: arguments)
    }

    /// Changes, or acquires, ownership of messages in a consumer group, as if the messages were delivered to as consumer group member.
    /// Version: 6.2.0
    /// Complexity: O(1) if COUNT is small.
    /// Categories: @write, @stream, @fast
    public func xautoclaim(
        key: RedisKey,
        group: String,
        consumer: String,
        minIdleTime: String,
        start: String,
        count: Int,
        justid: Bool
    ) async throws -> RESP3Token {
        let response = try await send(
            xautoclaimCommand(key: key, group: group, consumer: consumer, minIdleTime: minIdleTime, start: start, count: count, justid: justid)
        )
        return response
    }
    @inlinable
    public func xautoclaimCommand(
        key: RedisKey,
        group: String,
        consumer: String,
        minIdleTime: String,
        start: String,
        count: Int,
        justid: Bool
    ) -> RESP3Command {
        .init("XAUTOCLAIM", arguments: [key.description, group, consumer, minIdleTime, start, count.description, justid.description])
    }

    /// Changes, or acquires, ownership of a message in a consumer group, as if the message was delivered a consumer group member.
    /// Version: 5.0.0
    /// Complexity: O(log N) with N being the number of messages in the PEL of the consumer group.
    /// Categories: @write, @stream, @fast
    public func xclaim(
        key: RedisKey,
        group: String,
        consumer: String,
        minIdleTime: String,
        id: String...,
        ms: Int,
        unixTimeMilliseconds: Date,
        count: Int,
        force: Bool,
        justid: Bool,
        lastid: String
    ) async throws -> RESP3Token {
        let response = try await send(
            xclaimCommand(
                key: key,
                group: group,
                consumer: consumer,
                minIdleTime: minIdleTime,
                id: id,
                ms: ms,
                unixTimeMilliseconds: unixTimeMilliseconds,
                count: count,
                force: force,
                justid: justid,
                lastid: lastid
            )
        )
        return response
    }
    @inlinable
    public func xclaimCommand(
        key: RedisKey,
        group: String,
        consumer: String,
        minIdleTime: String,
        id: [String],
        ms: Int,
        unixTimeMilliseconds: Date,
        count: Int,
        force: Bool,
        justid: Bool,
        lastid: String
    ) -> RESP3Command {
        var arguments: [String] = [key.description]
        arguments.append(group)
        arguments.append(consumer)
        arguments.append(minIdleTime)
        arguments.append(contentsOf: id)
        arguments.append(ms.description)
        arguments.append(unixTimeMilliseconds.description)
        arguments.append(count.description)
        arguments.append(force.description)
        arguments.append(justid.description)
        arguments.append(lastid)
        return .init("XCLAIM", arguments: arguments)
    }

    /// Returns the number of messages after removing them from a stream.
    /// Version: 5.0.0
    /// Complexity: O(1) for each single item to delete in the stream, regardless of the stream size.
    /// Categories: @write, @stream, @fast
    public func xdel(key: RedisKey, id: String...) async throws -> RESP3Token {
        let response = try await send(xdelCommand(key: key, id: id))
        return response
    }
    @inlinable
    public func xdelCommand(key: RedisKey, id: [String]) -> RESP3Command {
        var arguments: [String] = [key.description]
        arguments.append(contentsOf: id)
        return .init("XDEL", arguments: arguments)
    }

    /// A container for consumer groups commands.
    /// Version: 5.0.0
    /// Complexity: Depends on subcommand.
    /// Categories: @slow
    public func xgroup() async throws -> RESP3Token {
        let response = try await send(xgroupCommand())
        return response
    }
    @inlinable
    public func xgroupCommand() -> RESP3Command {
        .init("XGROUP", arguments: [])
    }

    /// Creates a consumer in a consumer group.
    /// Version: 6.2.0
    /// Complexity: O(1)
    /// Categories: @write, @stream, @slow
    public func xgroupCreateconsumer(key: RedisKey, group: String, consumer: String) async throws -> RESP3Token {
        let response = try await send(xgroupCreateconsumerCommand(key: key, group: group, consumer: consumer))
        return response
    }
    @inlinable
    public func xgroupCreateconsumerCommand(key: RedisKey, group: String, consumer: String) -> RESP3Command {
        .init("XGROUP", arguments: ["CREATECONSUMER", key.description, group, consumer])
    }

    /// Deletes a consumer from a consumer group.
    /// Version: 5.0.0
    /// Complexity: O(1)
    /// Categories: @write, @stream, @slow
    public func xgroupDelconsumer(key: RedisKey, group: String, consumer: String) async throws -> RESP3Token {
        let response = try await send(xgroupDelconsumerCommand(key: key, group: group, consumer: consumer))
        return response
    }
    @inlinable
    public func xgroupDelconsumerCommand(key: RedisKey, group: String, consumer: String) -> RESP3Command {
        .init("XGROUP", arguments: ["DELCONSUMER", key.description, group, consumer])
    }

    /// Destroys a consumer group.
    /// Version: 5.0.0
    /// Complexity: O(N) where N is the number of entries in the group's pending entries list (PEL).
    /// Categories: @write, @stream, @slow
    public func xgroupDestroy(key: RedisKey, group: String) async throws -> RESP3Token {
        let response = try await send(xgroupDestroyCommand(key: key, group: group))
        return response
    }
    @inlinable
    public func xgroupDestroyCommand(key: RedisKey, group: String) -> RESP3Command {
        .init("XGROUP", arguments: ["DESTROY", key.description, group])
    }

    /// Returns helpful text about the different subcommands.
    /// Version: 5.0.0
    /// Complexity: O(1)
    /// Categories: @stream, @slow
    public func xgroupHelp() async throws -> RESP3Token {
        let response = try await send(xgroupHelpCommand())
        return response
    }
    @inlinable
    public func xgroupHelpCommand() -> RESP3Command {
        .init("XGROUP", arguments: ["HELP"])
    }

    /// A container for stream introspection commands.
    /// Version: 5.0.0
    /// Complexity: Depends on subcommand.
    /// Categories: @slow
    public func xinfo() async throws -> RESP3Token {
        let response = try await send(xinfoCommand())
        return response
    }
    @inlinable
    public func xinfoCommand() -> RESP3Command {
        .init("XINFO", arguments: [])
    }

    /// Returns a list of the consumers in a consumer group.
    /// Version: 5.0.0
    /// Complexity: O(1)
    /// Categories: @read, @stream, @slow
    public func xinfoConsumers(key: RedisKey, group: String) async throws -> RESP3Token {
        let response = try await send(xinfoConsumersCommand(key: key, group: group))
        return response
    }
    @inlinable
    public func xinfoConsumersCommand(key: RedisKey, group: String) -> RESP3Command {
        .init("XINFO", arguments: ["CONSUMERS", key.description, group])
    }

    /// Returns a list of the consumer groups of a stream.
    /// Version: 5.0.0
    /// Complexity: O(1)
    /// Categories: @read, @stream, @slow
    public func xinfoGroups(key: RedisKey) async throws -> RESP3Token {
        let response = try await send(xinfoGroupsCommand(key: key))
        return response
    }
    @inlinable
    public func xinfoGroupsCommand(key: RedisKey) -> RESP3Command {
        .init("XINFO", arguments: ["GROUPS", key.description])
    }

    /// Returns helpful text about the different subcommands.
    /// Version: 5.0.0
    /// Complexity: O(1)
    /// Categories: @stream, @slow
    public func xinfoHelp() async throws -> RESP3Token {
        let response = try await send(xinfoHelpCommand())
        return response
    }
    @inlinable
    public func xinfoHelpCommand() -> RESP3Command {
        .init("XINFO", arguments: ["HELP"])
    }

    /// Return the number of messages in a stream.
    /// Version: 5.0.0
    /// Complexity: O(1)
    /// Categories: @read, @stream, @fast
    public func xlen(key: RedisKey) async throws -> RESP3Token {
        let response = try await send(xlenCommand(key: key))
        return response
    }
    @inlinable
    public func xlenCommand(key: RedisKey) -> RESP3Command {
        .init("XLEN", arguments: [key.description])
    }

    /// Returns the messages from a stream within a range of IDs.
    /// Version: 5.0.0
    /// Complexity: O(N) with N being the number of elements being returned. If N is constant (e.g. always asking for the first 10 elements with COUNT), you can consider it O(1).
    /// Categories: @read, @stream, @slow
    public func xrange(key: RedisKey, start: String, end: String, count: Int) async throws -> RESP3Token {
        let response = try await send(xrangeCommand(key: key, start: start, end: end, count: count))
        return response
    }
    @inlinable
    public func xrangeCommand(key: RedisKey, start: String, end: String, count: Int) -> RESP3Command {
        .init("XRANGE", arguments: [key.description, start, end, count.description])
    }

    /// Returns the messages from a stream within a range of IDs in reverse order.
    /// Version: 5.0.0
    /// Complexity: O(N) with N being the number of elements returned. If N is constant (e.g. always asking for the first 10 elements with COUNT), you can consider it O(1).
    /// Categories: @read, @stream, @slow
    public func xrevrange(key: RedisKey, end: String, start: String, count: Int) async throws -> RESP3Token {
        let response = try await send(xrevrangeCommand(key: key, end: end, start: start, count: count))
        return response
    }
    @inlinable
    public func xrevrangeCommand(key: RedisKey, end: String, start: String, count: Int) -> RESP3Command {
        .init("XREVRANGE", arguments: [key.description, end, start, count.description])
    }

    /// An internal command for replicating stream values.
    /// Version: 5.0.0
    /// Complexity: O(1)
    /// Categories: @write, @stream, @fast
    public func xsetid(key: RedisKey, lastId: String, entriesAdded: Int, maxDeletedId: String) async throws -> RESP3Token {
        let response = try await send(xsetidCommand(key: key, lastId: lastId, entriesAdded: entriesAdded, maxDeletedId: maxDeletedId))
        return response
    }
    @inlinable
    public func xsetidCommand(key: RedisKey, lastId: String, entriesAdded: Int, maxDeletedId: String) -> RESP3Command {
        .init("XSETID", arguments: [key.description, lastId, entriesAdded.description, maxDeletedId])
    }

    /// Returns the number of members in a sorted set.
    /// Version: 1.2.0
    /// Complexity: O(1)
    /// Categories: @read, @sortedset, @fast
    public func zcard(key: RedisKey) async throws -> RESP3Token {
        let response = try await send(zcardCommand(key: key))
        return response
    }
    @inlinable
    public func zcardCommand(key: RedisKey) -> RESP3Command {
        .init("ZCARD", arguments: [key.description])
    }

    /// Returns the count of members in a sorted set that have scores within a range.
    /// Version: 2.0.0
    /// Complexity: O(log(N)) with N being the number of elements in the sorted set.
    /// Categories: @read, @sortedset, @fast
    public func zcount(key: RedisKey, min: Double, max: Double) async throws -> RESP3Token {
        let response = try await send(zcountCommand(key: key, min: min, max: max))
        return response
    }
    @inlinable
    public func zcountCommand(key: RedisKey, min: Double, max: Double) -> RESP3Command {
        .init("ZCOUNT", arguments: [key.description, min.description, max.description])
    }

    /// Returns the difference between multiple sorted sets.
    /// Version: 6.2.0
    /// Complexity: O(L + (N-K)log(N)) worst case where L is the total number of elements in all the sets, N is the size of the first set, and K is the size of the result set.
    /// Categories: @read, @sortedset, @slow
    public func zdiff(numkeys: Int, key: RedisKey..., withscores: Bool) async throws -> RESP3Token {
        let response = try await send(zdiffCommand(numkeys: numkeys, key: key, withscores: withscores))
        return response
    }
    @inlinable
    public func zdiffCommand(numkeys: Int, key: [RedisKey], withscores: Bool) -> RESP3Command {
        var arguments: [String] = [numkeys.description]
        arguments.append(contentsOf: key.map(\.description))
        arguments.append(withscores.description)
        return .init("ZDIFF", arguments: arguments)
    }

    /// Stores the difference of multiple sorted sets in a key.
    /// Version: 6.2.0
    /// Complexity: O(L + (N-K)log(N)) worst case where L is the total number of elements in all the sets, N is the size of the first set, and K is the size of the result set.
    /// Categories: @write, @sortedset, @slow
    public func zdiffstore(destination: RedisKey, numkeys: Int, key: RedisKey...) async throws -> RESP3Token {
        let response = try await send(zdiffstoreCommand(destination: destination, numkeys: numkeys, key: key))
        return response
    }
    @inlinable
    public func zdiffstoreCommand(destination: RedisKey, numkeys: Int, key: [RedisKey]) -> RESP3Command {
        var arguments: [String] = [destination.description]
        arguments.append(numkeys.description)
        arguments.append(contentsOf: key.map(\.description))
        return .init("ZDIFFSTORE", arguments: arguments)
    }

    /// Increments the score of a member in a sorted set.
    /// Version: 1.2.0
    /// Complexity: O(log(N)) where N is the number of elements in the sorted set.
    /// Categories: @write, @sortedset, @fast
    public func zincrby(key: RedisKey, increment: Int, member: String) async throws -> RESP3Token {
        let response = try await send(zincrbyCommand(key: key, increment: increment, member: member))
        return response
    }
    @inlinable
    public func zincrbyCommand(key: RedisKey, increment: Int, member: String) -> RESP3Command {
        .init("ZINCRBY", arguments: [key.description, increment.description, member])
    }

    /// Returns the number of members of the intersect of multiple sorted sets.
    /// Version: 7.0.0
    /// Complexity: O(N*K) worst case with N being the smallest input sorted set, K being the number of input sorted sets.
    /// Categories: @read, @sortedset, @slow
    public func zintercard(numkeys: Int, key: RedisKey..., limit: Int) async throws -> RESP3Token {
        let response = try await send(zintercardCommand(numkeys: numkeys, key: key, limit: limit))
        return response
    }
    @inlinable
    public func zintercardCommand(numkeys: Int, key: [RedisKey], limit: Int) -> RESP3Command {
        var arguments: [String] = [numkeys.description]
        arguments.append(contentsOf: key.map(\.description))
        arguments.append(limit.description)
        return .init("ZINTERCARD", arguments: arguments)
    }

    /// Returns the number of members in a sorted set within a lexicographical range.
    /// Version: 2.8.9
    /// Complexity: O(log(N)) with N being the number of elements in the sorted set.
    /// Categories: @read, @sortedset, @fast
    public func zlexcount(key: RedisKey, min: String, max: String) async throws -> RESP3Token {
        let response = try await send(zlexcountCommand(key: key, min: min, max: max))
        return response
    }
    @inlinable
    public func zlexcountCommand(key: RedisKey, min: String, max: String) -> RESP3Command {
        .init("ZLEXCOUNT", arguments: [key.description, min, max])
    }

    /// Returns the score of one or more members in a sorted set.
    /// Version: 6.2.0
    /// Complexity: O(N) where N is the number of members being requested.
    /// Categories: @read, @sortedset, @fast
    public func zmscore(key: RedisKey, member: String...) async throws -> RESP3Token {
        let response = try await send(zmscoreCommand(key: key, member: member))
        return response
    }
    @inlinable
    public func zmscoreCommand(key: RedisKey, member: [String]) -> RESP3Command {
        var arguments: [String] = [key.description]
        arguments.append(contentsOf: member)
        return .init("ZMSCORE", arguments: arguments)
    }

    /// Returns the highest-scoring members from a sorted set after removing them. Deletes the sorted set if the last member was popped.
    /// Version: 5.0.0
    /// Complexity: O(log(N)*M) with N being the number of elements in the sorted set, and M being the number of elements popped.
    /// Categories: @write, @sortedset, @fast
    public func zpopmax(key: RedisKey, count: Int) async throws -> RESP3Token {
        let response = try await send(zpopmaxCommand(key: key, count: count))
        return response
    }
    @inlinable
    public func zpopmaxCommand(key: RedisKey, count: Int) -> RESP3Command {
        .init("ZPOPMAX", arguments: [key.description, count.description])
    }

    /// Returns the lowest-scoring members from a sorted set after removing them. Deletes the sorted set if the last member was popped.
    /// Version: 5.0.0
    /// Complexity: O(log(N)*M) with N being the number of elements in the sorted set, and M being the number of elements popped.
    /// Categories: @write, @sortedset, @fast
    public func zpopmin(key: RedisKey, count: Int) async throws -> RESP3Token {
        let response = try await send(zpopminCommand(key: key, count: count))
        return response
    }
    @inlinable
    public func zpopminCommand(key: RedisKey, count: Int) -> RESP3Command {
        .init("ZPOPMIN", arguments: [key.description, count.description])
    }

    /// Returns the index of a member in a sorted set ordered by ascending scores.
    /// Version: 2.0.0
    /// Complexity: O(log(N))
    /// Categories: @read, @sortedset, @fast
    public func zrank(key: RedisKey, member: String, withscore: Bool) async throws -> RESP3Token {
        let response = try await send(zrankCommand(key: key, member: member, withscore: withscore))
        return response
    }
    @inlinable
    public func zrankCommand(key: RedisKey, member: String, withscore: Bool) -> RESP3Command {
        .init("ZRANK", arguments: [key.description, member, withscore.description])
    }

    /// Removes one or more members from a sorted set. Deletes the sorted set if all members were removed.
    /// Version: 1.2.0
    /// Complexity: O(M*log(N)) with N being the number of elements in the sorted set and M the number of elements to be removed.
    /// Categories: @write, @sortedset, @fast
    public func zrem(key: RedisKey, member: String...) async throws -> RESP3Token {
        let response = try await send(zremCommand(key: key, member: member))
        return response
    }
    @inlinable
    public func zremCommand(key: RedisKey, member: [String]) -> RESP3Command {
        var arguments: [String] = [key.description]
        arguments.append(contentsOf: member)
        return .init("ZREM", arguments: arguments)
    }

    /// Removes members in a sorted set within a lexicographical range. Deletes the sorted set if all members were removed.
    /// Version: 2.8.9
    /// Complexity: O(log(N)+M) with N being the number of elements in the sorted set and M the number of elements removed by the operation.
    /// Categories: @write, @sortedset, @slow
    public func zremrangebylex(key: RedisKey, min: String, max: String) async throws -> RESP3Token {
        let response = try await send(zremrangebylexCommand(key: key, min: min, max: max))
        return response
    }
    @inlinable
    public func zremrangebylexCommand(key: RedisKey, min: String, max: String) -> RESP3Command {
        .init("ZREMRANGEBYLEX", arguments: [key.description, min, max])
    }

    /// Removes members in a sorted set within a range of indexes. Deletes the sorted set if all members were removed.
    /// Version: 2.0.0
    /// Complexity: O(log(N)+M) with N being the number of elements in the sorted set and M the number of elements removed by the operation.
    /// Categories: @write, @sortedset, @slow
    public func zremrangebyrank(key: RedisKey, start: Int, stop: Int) async throws -> RESP3Token {
        let response = try await send(zremrangebyrankCommand(key: key, start: start, stop: stop))
        return response
    }
    @inlinable
    public func zremrangebyrankCommand(key: RedisKey, start: Int, stop: Int) -> RESP3Command {
        .init("ZREMRANGEBYRANK", arguments: [key.description, start.description, stop.description])
    }

    /// Removes members in a sorted set within a range of scores. Deletes the sorted set if all members were removed.
    /// Version: 1.2.0
    /// Complexity: O(log(N)+M) with N being the number of elements in the sorted set and M the number of elements removed by the operation.
    /// Categories: @write, @sortedset, @slow
    public func zremrangebyscore(key: RedisKey, min: Double, max: Double) async throws -> RESP3Token {
        let response = try await send(zremrangebyscoreCommand(key: key, min: min, max: max))
        return response
    }
    @inlinable
    public func zremrangebyscoreCommand(key: RedisKey, min: Double, max: Double) -> RESP3Command {
        .init("ZREMRANGEBYSCORE", arguments: [key.description, min.description, max.description])
    }

    /// Returns members in a sorted set within a range of indexes in reverse order.
    /// Version: 1.2.0
    /// Complexity: O(log(N)+M) with N being the number of elements in the sorted set and M the number of elements returned.
    /// Categories: @read, @sortedset, @slow
    public func zrevrange(key: RedisKey, start: Int, stop: Int, withscores: Bool) async throws -> RESP3Token {
        let response = try await send(zrevrangeCommand(key: key, start: start, stop: stop, withscores: withscores))
        return response
    }
    @inlinable
    public func zrevrangeCommand(key: RedisKey, start: Int, stop: Int, withscores: Bool) -> RESP3Command {
        .init("ZREVRANGE", arguments: [key.description, start.description, stop.description, withscores.description])
    }

    /// Returns the index of a member in a sorted set ordered by descending scores.
    /// Version: 2.0.0
    /// Complexity: O(log(N))
    /// Categories: @read, @sortedset, @fast
    public func zrevrank(key: RedisKey, member: String, withscore: Bool) async throws -> RESP3Token {
        let response = try await send(zrevrankCommand(key: key, member: member, withscore: withscore))
        return response
    }
    @inlinable
    public func zrevrankCommand(key: RedisKey, member: String, withscore: Bool) -> RESP3Command {
        .init("ZREVRANK", arguments: [key.description, member, withscore.description])
    }

    /// Returns the score of a member in a sorted set.
    /// Version: 1.2.0
    /// Complexity: O(1)
    /// Categories: @read, @sortedset, @fast
    public func zscore(key: RedisKey, member: String) async throws -> RESP3Token {
        let response = try await send(zscoreCommand(key: key, member: member))
        return response
    }
    @inlinable
    public func zscoreCommand(key: RedisKey, member: String) -> RESP3Command {
        .init("ZSCORE", arguments: [key.description, member])
    }

}
