# ``Valkey/ValkeyConnectionProtocol``

## Topics
<!-- Created these sets following the ordering at https://valkey.io/commands/ -->

### Operations on the bitmap data type
- ``bitcount(_:range:)``
- ``bitcount(_:range:)``
- ``bitfield(_:operations:)``
- ``bitfieldRo(_:getBlocks:)``
- ``bitop(operation:destkey:keys:)``
- ``bitpos(_:bit:range:)``
- ``getbit(_:offset:)``
- ``setbit(_:offset:value:)``

### Operations on the Bloom filter data type

bf.add
bf.card
bf.exists
bf.info
bf.insert
bf.load
bf.madd
bf.mexists
bf.reserve

### Valkey cluster management commands

- ``asking()``

- ``clusterAddslots(slots:)``
- ``clusterAddslotsrange(ranges:)``
- ``clusterBumpepoch()``
- ``clusterCountFailureReports(nodeId:)``
- ``clusterCountkeysinslot(slot:)``
- ``clusterDelslots(slots:)``
- ``clusterDelslotsrange(ranges:)``
- ``clusterFailover(options:)``
- ``clusterFlushslots()``
- ``clusterForget(nodeId:)``
- ``clusterGetkeysinslot(slot:count:)``
- ``clusterHelp()``
- ``clusterInfo()``
- ``clusterLinks()``
- ``clusterMeet(ip:port:clusterBusPort:)``
- ``clusterMyid()``
- ``clusterMyshardid()``
- ``clusterNodes()``
- ``clusterReplicas(nodeId:)``
- ``clusterReplicate(nodeId:)``
- ``clusterReset(resetType:)``
- ``clusterSaveconfig()``
<!-- cluster_save-config-epoch? -->
- ``clusterSetslot(slot:subcommand:timeout:)``
- ``clusterShards()``
- ``clusterSlaves(nodeId:)``
- ``clusterSlots()``
- ``clusterSlotStats(filter:)``
- ``readonly()``
- ``readwrite()``

#### Client Connections Management

- ``auth(username:password:)``
- ``client()``
- ``clientCaching(mode:)``
- ``clientCapa(capabilities:)``
- ``clientGetname()``
- ``clientGetredir()``
- ``clientHelp()``
- ``clientId()``
- ``clientImportSource(enabled:)``
- ``clientInfo()``
- ``clientKill(filter:)``
- ``clientList(clientType:clientIds:username:addr:laddr:skipme:maxage:)``
- ``clientNoEvict(enabled:)``
- ``clientNoTouch(enabled:)``
- ``clientPause(timeout:mode:)``
- ``clientReply(action:)``
- ``clientSetinfo(attr:)``
- ``clientSetname(connectionName:)``
- ``clientTracking(status:clientId:prefixs:bcast:optin:optout:noloop:)``
- ``clientTrackinginfo()``
- ``clientUnblock(clientId:unblockType:)``
- ``clientUnpause()``
- ``echo(message:)``
- ``hello(arguments:)``
- ``ping(message:)``
- ``quit()``
- ``reset()``
- ``select(index:)``

### Generic Commands

- ``copy(source:destination:destinationDb:replace:)``
- ``del(keys:)``
- ``dump(_:)``
- ``exists(keys:)``
- ``expire(_:seconds:condition:)``
- ``expireat(_:unixTimeSeconds:condition:)``
- ``expiretime(_:)``
- ``keys(pattern:)``
- ``migrate(host:port:keySelector:destinationDb:timeout:copy:replace:authentication:keys:)``
- ``move(_:db:)``

- ``objectEncoding(_:)``
- ``objectFreq(_:)``
- ``objectHelp()``
- ``objectIdletime(_:)``
- ``objectRefcount(_:)``
- ``persist(_:)``
- ``pexpire(_:milliseconds:condition:)``
- ``pexpireat(_:unixTimeMilliseconds:condition:)``
- ``pexpiretime(_:)``
- ``pttl(_:)``
- ``randomkey()``
- ``rename(_:newkey:)``
- ``renamenx(_:newkey:)``
- ``restore(_:ttl:serializedValue:replace:absttl:seconds:frequency:)``
- ``scan(cursor:pattern:count:type:)``
- ``sort(_:byPattern:limit:getPatterns:order:sorting:destination:)``
- ``sortRo(_:byPattern:limit:getPatterns:order:sorting:)``
- ``touch(keys:)``
- ``ttl(_:)``
- ``type(_:)``
- ``unlink(keys:)``
- ``wait(numreplicas:timeout:)``
- ``waitaof(numlocal:numreplicas:timeout:)``

### Geospatial Indices

- ``geoadd(_:condition:change:data:)``
- ``geodist(_:member1:member2:unit:)``
- ``geohash(_:members:)``
- ``geopos(_:members:)``
- ``georadius(_:longitude:latitude:radius:unit:withcoord:withdist:withhash:countBlock:order:store:)``
- ``georadiusbymember(_:member:radius:unit:withcoord:withdist:withhash:countBlock:order:store:)``
- ``georadiusbymemberRo(_:member:radius:unit:withcoord:withdist:withhash:countBlock:order:)``
- ``georadiusRo(_:longitude:latitude:radius:unit:withcoord:withdist:withhash:countBlock:order:)``
- ``geosearch(_:from:by:order:countBlock:withcoord:withdist:withhash:)``
- ``geosearchstore(destination:source:from:by:order:countBlock:storedist:)``

### Hash Operations

- ``hdel(_:fields:)``
- ``hexists(_:field:)``
- ``hget(_:field:)``
- ``hgetall(_:)``
- ``hincrby(_:field:increment:)``
- ``hincrbyfloat(_:field:increment:)``
- ``hkeys(_:)``
- ``hlen(_:)``
- ``hmget(_:fields:)``
- ``hmset(_:data:)``
- ``hrandfield(_:options:)``
- ``hscan(_:cursor:pattern:count:novalues:)``
- ``hset(_:data:)``
- ``hsetnx(_:field:value:)``
- ``hstrlen(_:field:)``
- ``hvals(_:)``

### Operations on the Hyperlog Data Type

- ``pfadd(_:elements:)``
- ``pfcount(keys:)``
<!--pfdebug-->
- ``pfmerge(destkey:sourcekeys:)``
<!--pfselftest-->

### Operations on the JSON data type

json.arrappend
json.arrindex
json.addinsert
json.arrlen
json.arrpop
json.arrtrim
json.clear
json.debug
json.del
json.forget
json.get
json.mget
json.mset
json.numincrby
json.nummultby
json.objkeys
json.objlen
json.resp
json.set
json.strappend
json.strlen
json.toggle
json.type

### Operations on the List data type

- ``blmove(source:destination:wherefrom:whereto:timeout:)``
- ``blmpop(timeout:keys:where:count:)``
- ``blpop(keys:timeout:)``
- ``brpop(keys:timeout:)``
- ``brpoplpush(source:destination:timeout:)``
- ``lindex(_:index:)``
- ``linsert(_:where:pivot:element:)``
- ``llen(_:)``
- ``lmove(source:destination:wherefrom:whereto:)``
- ``lmpop(keys:where:count:)``
- ``lpop(_:count:)``
- ``lpos(_:element:rank:numMatches:len:)``
- ``lpush(_:elements:)``
- ``lpushx(_:elements:)``
- ``lrange(_:start:stop:)``
- ``lrem(_:count:element:)``
- ``lset(_:index:element:)``
- ``ltrim(_:start:stop:)``
- ``rpop(_:count:)``
- ``rpoplpush(source:destination:)``
- ``lpush(_:elements:)``
- ``lpushx(_:elements:)``
- ``lrange(_:start:stop:)``
- ``lrem(_:count:element:)``
- ``lset(_:index:element:)``
- ``ltrim(_:start:stop:)``
- ``rpop(_:count:)``
- ``rpoplpush(source:destination:)``
- ``rpush(_:elements:)``
- ``rpushx(_:elements:)``

### PUB/SUB commands

psubscribe
- ``publish(channel:message:)``

- ``pubsubChannels(pattern:)``
- ``pubsubHelp()``
- ``pubsubNumpat()``
- ``pubsubNumsub(channels:)``
- ``pubsubShardchannels(pattern:)``
- ``pubsubShardnumsub(shardchannels:)``
<!--punsubscribe-->
- ``spublish(shardchannel:message:)``
<!--ssubscribe-->
<!--subscribe-->
<!--sunsubscribe-->
<!--unsubscribe-->

### Server side Scripting and Functions

- ``eval(script:keys:args:)``
- ``evalsha(sha1:keys:args:)``
- ``evalshaRo(sha1:keys:args:)``
- ``evalRo(script:keys:args:)``
- ``fcall(function:keys:args:)``
- ``fcallRo(function:keys:args:)``

- ``functionDelete(libraryName:)``
- ``functionDump()``
- ``functionFlush(flushType:)``
- ``functionHelp()``
- ``functionKill()``
- ``functionList(libraryNamePattern:withcode:)``
- ``functionLoad(replace:functionCode:)``
- ``functionRestore(serializedValue:policy:)``
- ``functionStats()``

- ``scriptDebug(mode:)``
- ``scriptExists(sha1s:)``
- ``scriptHelp()``
- ``scriptKill()``
- ``scriptLoad(script:)``
- ``scriptShow(sha1:)``

### Search - VECTOR SIMILARITY SEARCH ENGINE OPTIMIZED FOR AI-DRIVEN WORKLOADS

ft.create
ft.dropindex
ft.info
ft.search
ft.list

### Server Management Commands

- ``aclCat(category:)``
- ``aclDeluser(usernames:)``
- ``aclDryrun(username:command:args:)``
- ``aclGenpass(bits:)``
- ``aclGetuser(username:)``
- ``aclHelp()``
- ``aclList()``
- ``aclLoad()``
- ``aclLog(operation:)``
- ``aclSave()``
- ``aclSetuser(username:rules:)``
- ``aclUsers()``
- ``aclWhoami()``
- ``bgrewriteaof()``
- ``bgsave(operation:)``
- ``command()``
- ``commandCount()``
- ``commandDocs(commandNames:)``
- ``commandGetkeys(command:args:)``
- ``commandGetkeysandflags(command:args:)``
- ``commandHelp()``
- ``commandInfo(commandNames:)``
- ``commandList(filterby:)``

- ``commandlogGet(count:type:)``
- ``commandlogHelp()``
- ``commandlogLen(type:)``
- ``commandlogReset(type:)``

- ``configGet(parameters:)``
- ``configHelp()``
- ``configResetstat()``
- ``configRewrite()``
- ``configSet(data:)``
- ``dbsize()``
<!--debug-->
- ``failover(target:abort:milliseconds:)``
- ``flushall(flushType:)``
- ``info(sections:)``
- ``lastsave()``

- ``latencyDoctor()``
- ``latencyGraph(event:)``
- ``latencyHelp()``
- ``latencyHistogram(commands:)``
- ``latencyHistory(event:)``
- ``latencyLatest()``
- ``latencyReset(events:)``
- ``lolwut(version:)``

- ``memoryDoctor()``
- ``memoryHelp()``
- ``memoryMallocStats()``
- ``memoryPurge()``
- ``memoryUsage(_:count:)``

- ``moduleHelp()``
- ``moduleList()``
- ``moduleLoad(path:args:)``
- ``moduleLoadex(path:configs:args:)``
- ``moduleUnload(name:)``
- ``monitor()``
- ``psync(replicationid:offset:)``
<!--replconf-->
- ``replicaof(args:)``
<!--restore-asking-->
- ``role()``
- ``save()``
- ``shutdown(abortSelector:)``
- ``slaveof(args:)``
<!--slowlog-->
- ``slowlogGet(count:)``
- ``slowlogHelp()``
- ``slowlogLen()``
- ``slowlogReset()``
- ``swapdb(index1:index2:)``
- ``sync()``
- ``time()``

### Operations on the SET data tyoe

- ``sadd(_:members:)``
- ``scard(_:)``
- ``sdiff(keys:)``
- ``sdiffstore(destination:keys:)``
- ``sinter(keys:)``
- ``sintercard(keys:limit:)``
- ``sinterstore(destination:keys:)``
- ``sismember(_:member:)``
- ``smembers(_:)``
- ``smismember(_:members:)``
- ``smove(source:destination:member:)``
- ``spop(_:count:)``
- ``srandmember(_:count:)``
- ``srem(_:members:)``
- ``sscan(_:cursor:pattern:count:)``
- ``sunion(keys:)``
- ``sunionstore(destination:keys:)``

### operations on the sorted set data type

- ``bzmpop(timeout:keys:where:count:)``
- ``bzpopmax(keys:timeout:)``
- ``bzpopmin(keys:timeout:)``
- ``zadd(_:condition:comparison:change:increment:data:)``
- ``zcard(_:)``
- ``zcount(_:min:max:)``
- ``zdiff(keys:withscores:)``
- ``zdiffstore(destination:keys:)``
- ``zincrby(_:increment:member:)``
- ``zinter(keys:weights:aggregate:withscores:)``
- ``zintercard(keys:limit:)``
- ``zinterstore(destination:keys:weights:aggregate:)``
- ``zlexcount(_:min:max:)``
- ``zmpop(keys:where:count:)``
- ``zmscore(_:members:)``
- ``zpopmax(_:count:)``
- ``zpopmin(_:count:)``
- ``zrandmember(_:options:)``
- ``zrange(_:start:stop:sortby:rev:limit:withscores:)``
- ``zrangebylex(_:min:max:limit:)``
- ``zrangebyscore(_:min:max:withscores:limit:)``
- ``zrangestore(dst:src:min:max:sortby:rev:limit:)``
- ``zrank(_:member:withscore:)``
- ``zrem(_:members:)``
- ``zremrangebylex(_:min:max:)``
- ``zremrangebyrank(_:start:stop:)``
- ``zremrangebyscore(_:min:max:)``
- ``zrevrange(_:start:stop:withscores:)``
- ``zrevrangebylex(_:max:min:limit:)``
- ``zrevrangebyscore(_:max:min:withscores:limit:)``
- ``zrevrank(_:member:withscore:)``
- ``zscan(_:cursor:pattern:count:noscores:)``
- ``zscore(_:member:)``
- ``zunion(keys:weights:aggregate:withscores:)``
- ``zunionstore(destination:keys:weights:aggregate:)``

### Operations on the Stream data type

- ``xack(_:group:ids:)``
- ``xadd(_:nomkstream:trim:idSelector:data:)``
- ``xautoclaim(_:group:consumer:minIdleTime:start:count:justid:)``
- ``xclaim(_:group:consumer:minIdleTime:ids:ms:unixTimeMilliseconds:count:force:justid:lastid:)``
- ``xdel(_:ids:)``

- ``xgroupCreate(_:group:idSelector:mkstream:entriesread:)``
- ``xgroupCreateconsumer(_:group:consumer:)``
- ``xgroupDelconsumer(_:group:consumer:)``
- ``xgroupDestroy(_:group:)``
- ``xgroupHelp()``
- ``xgroupSetid(_:group:idSelector:entriesread:)``

- ``xinfoConsumers(_:group:)``
- ``xinfoGroups(_:)``
- ``xinfoHelp()``
- ``xinfoStream(_:fullBlock:)``
- ``xlen(_:)``
- ``xpending(_:group:filters:)``
- ``xrange(_:start:end:count:)``
- ``xread(count:milliseconds:streams:)``
- ``xreadgroup(groupBlock:count:milliseconds:noack:streams:)``
- ``xrevrange(_:end:start:count:)``
- ``xsetid(_:lastId:entriesAdded:maxDeletedId:)``
- ``xtrim(_:trim:)``

### Operations on the String Data type

- ``append(_:value:)``
- ``decr(_:)``
- ``decrby(_:decrement:)``
<!--delifeq-->
- ``get(_:)``
- ``getdel(_:)``
- ``getex(_:expiration:)``
- ``getrange(_:start:end:)``
- ``getset(_:value:)``
- ``incr(_:)``
- ``incrby(_:increment:)``
- ``incrbyfloat(_:increment:)``
- ``lcs(key1:key2:len:idx:minMatchLen:withmatchlen:)``
- ``mget(keys:)``
- ``mset(data:)``
- ``msetnx(data:)``
- ``psetex(_:milliseconds:value:)``
- ``set(_:value:condition:get:expiration:)``
- ``setex(_:seconds:value:)``
- ``setnx(_:value:)``
- ``setrange(_:offset:value:)``
- ``strlen(_:)``
- ``substr(_:start:end:)``

### Transaction management
https://valkey.io/commands/#transactions

discard
exec
multi
unwatch
watch

