# ``Valkey/ValkeyConnectionProtocol``

## Topics
<!-- Created these sets following the ordering at https://valkey.io/commands/ -->

### Operations on the bitmap data type

- ``bitcount(key:range:)``
- ``bitfield(key:operation:)``
- ``bitfieldRo(key:getBlock:)``
- ``bitop(operation:destkey:key:)``
- ``bitpos(key:bit:range:)``
- ``getbit(key:offset:)``
- ``setbit(key:offset:value:)``

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
- ``clusterAddslotsrange(range:)``
- ``clusterBumpepoch()``
- ``clusterCountFailureReports(nodeId:)``
- ``clusterCountkeysinslot(slot:)``
- ``clusterDelslots(slot:)``
- ``clusterDelslotsrange(range:)``
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
cluster_save-config-epoch?
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
- ``clientCapa(capability:)``
- ``clientGetname()``
- ``clientGetredir()``
- ``clientHelp()``
- ``clientId()``
- ``clientImportSource(enabled:)``
- ``clientInfo()``
- ``clientKill(filter:)``
- ``clientList(clientType:clientId:username:addr:laddr:skipme:maxage:)``
- ``clientNoEvict(enabled:)``
- ``clientNoTouch(enabled:)``
- ``clientPause(timeout:mode:)``
- ``clientReply(action:)``
- ``clientSetinfo(attr:)``
- ``clientSetname(connectionName:)``
- ``clientTracking(status:clientId:prefix:bcast:optin:optout:noloop:)``
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
- ``del(key:)``
- ``dump(key:)``
- ``exists(key:)``
- ``expire(key:seconds:condition:)``
- ``expireat(key:unixTimeSeconds:condition:)``
- ``expiretime(key:)``
- ``keys(pattern:)``
- ``migrate(host:port:keySelector:destinationDb:timeout:copy:replace:authentication:keys:)``
- ``move(key:db:)``

- ``objectEncoding(key:)``
- ``objectFreq(key:)``
- ``objectHelp()``
- ``objectIdletime(key:)``
- ``objectRefcount(key:)``
- ``persist(key:)``
- ``pexpire(key:milliseconds:condition:)``
- ``pexpireat(key:unixTimeMilliseconds:condition:)``
- ``pexpiretime(key:)``
- ``pttl(key:)``
- ``randomkey()``
- ``rename(key:newkey:)``
- ``renamenx(key:newkey:)``
- ``restore(key:ttl:serializedValue:replace:absttl:seconds:frequency:)``
- ``scan(cursor:pattern:count:type:)``
- ``sort(key:byPattern:limit:getPattern:order:sorting:destination:)``
- ``sortRo(key:byPattern:limit:getPattern:order:sorting:)``
- ``touch(key:)``
- ``ttl(key:)``
- ``type(key:)``
- ``unlink(key:)``
- ``wait(numreplicas:timeout:)``
- ``waitaof(numlocal:numreplicas:timeout:)``

### Geospatial Indices

- ``geoadd(key:condition:change:data:)``
- ``geodist(key:member1:member2:unit:)``
- ``geohash(key:member:)``
- ``geopos(key:member:)``
- ``georadius(key:longitude:latitude:radius:unit:withcoord:withdist:withhash:countBlock:order:store:)``
- ``georadiusbymember(key:member:radius:unit:withcoord:withdist:withhash:countBlock:order:store:)``
- ``georadiusbymemberRo(key:member:radius:unit:withcoord:withdist:withhash:countBlock:order:)``
- ``georadiusRo(key:longitude:latitude:radius:unit:withcoord:withdist:withhash:countBlock:order:)``
- ``geosearch(key:from:by:order:countBlock:withcoord:withdist:withhash:)``
- ``geosearchstore(destination:source:from:by:order:countBlock:storedist:)``

### Hash Operations

- ``hdel(key:field:)``
- ``hexists(key:field:)``
- ``hget(key:field:)``
- ``hgetall(key:)``
- ``hincrby(key:field:increment:)``
- ``hincrbyfloat(key:field:increment:)``
- ``hkeys(key:)``
- ``hlen(key:)``
- ``hmget(key:field:)``
- ``hmset(key:data:)``
- ``hrandfield(key:options:)``
- ``hscan(key:cursor:pattern:count:novalues:)``
- ``hset(key:data:)``
- ``hsetnx(key:field:value:)``
- ``hstrlen(key:field:)``
- ``hvals(key:)``

### Operations on the Hyperlog Data Type

- ``pfadd(key:element:)``
- ``pfcount(key:)``
pfdebug
- ``pfmerge(destkey:sourcekey:)``
pfselftest

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
- ``blmpop(timeout:key:where:count:)``
- ``blpop(key:timeout:)``
- ``brpop(key:timeout:)``
- ``brpoplpush(source:destination:timeout:)``
- ``lindex(key:index:)``
- ``linsert(key:where:pivot:element:)``
- ``llen(key:)``
- ``lmove(source:destination:wherefrom:whereto:)``
- ``lmpop(key:where:count:)``
- ``lpop(key:count:)``
- ``lpos(key:element:rank:numMatches:len:)``
- ``lpush(key:element:)``
- ``lpushx(key:element:)``
- ``lrange(key:start:stop:)``
- ``lrem(key:count:element:)``
- ``lset(key:index:element:)``
- ``ltrim(key:start:stop:)``
- ``rpop(key:count:)``
- ``rpoplpush(source:destination:)``
- ``lpush(key:element:)``
- ``lpushx(key:element:)``
- ``lrange(key:start:stop:)``
- ``lrem(key:count:element:)``
- ``lset(key:index:element:)``
- ``ltrim(key:start:stop:)``
- ``rpop(key:count:)``
- ``rpoplpush(source:destination:)``
- ``rpush(key:element:)``
- ``rpushx(key:element:)``

### PUB/SUB commands

psubscribe
- ``publish(channel:message:)``

- ``pubsubChannels(pattern:)``
- ``pubsubHelp()``
- ``pubsubNumpat()``
- ``pubsubNumsub(channel:)``
- ``pubsubShardchannels(pattern:)``
- ``pubsubShardnumsub(shardchannel:)``
punsubscribe
- ``spublish(shardchannel:message:)``
ssubscribe
subscribe
sunsubscribe
unsubscribe

### Server side Scripting and Functions

- ``eval(script:key:arg:)``
- ``evalsha(sha1:key:arg:)``
- ``evalshaRo(sha1:key:arg:)``
- ``evalRo(script:key:arg:)``
- ``fcall(function:key:arg:)``
- ``fcallRo(function:key:arg:)``

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
- ``scriptExists(sha1:)``
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
- ``aclDeluser(username:)``
- ``aclDryrun(username:command:arg:)``
- ``aclGenpass(bits:)``
- ``aclGetuser(username:)``
- ``aclHelp()``
- ``aclList()``
- ``aclLoad()``
- ``aclLog(operation:)``
- ``aclSave()``
- ``aclSetuser(username:rule:)``
- ``aclUsers()``
- ``aclWhoami()``
- ``bgrewriteaof()``
- ``bgsave(operation:)``
- ``command()``
- ``commandCount()``
- ``commandDocs(commandName:)``
- ``commandGetkeys(command:arg:)``
- ``commandGetkeysandflags(command:arg:)``
- ``commandHelp()``
- ``commandInfo(commandName:)``
- ``commandList(filterby:)``

- ``commandlogGet(count:type:)``
- ``commandlogHelp()``
- ``commandlogLen(type:)``
- ``commandlogReset(type:)``

- ``configGet(parameter:)``
- ``configHelp()``
- ``configResetstat()``
- ``configRewrite()``
- ``configSet(data:)``
- ``dbsize()``
debug
- ``failover(target:abort:milliseconds:)``
- ``flushall(flushType:)``
- ``info(section:)``
- ``lastsave()``

- ``latencyDoctor()``
- ``latencyGraph(event:)``
- ``latencyHelp()``
- ``latencyHistogram(command:)``
- ``latencyHistory(event:)``
- ``latencyLatest()``
- ``latencyReset(event:)``
- ``lolwut(version:)``

- ``memoryDoctor()``
- ``memoryHelp()``
- ``memoryMallocStats()``
- ``memoryPurge()``
- ``memoryUsage(key:count:)``

- ``moduleHelp()``
- ``moduleList()``
- ``moduleLoad(path:arg:)``
- ``moduleLoadex(path:configs:args:)``
- ``moduleUnload(name:)``
- ``monitor()``
- ``psync(replicationid:offset:)``
replconf
- ``replicaof(args:)``
restore-asking
- ``role()``
- ``save()``
- ``shutdown(abortSelector:)``
- ``slaveof(args:)``
slowlog
- ``slowlogGet(count:)``
- ``slowlogHelp()``
- ``slowlogLen()``
- ``slowlogReset()``
- ``swapdb(index1:index2:)``
- ``sync()``
- ``time()``

### Operations on the SET data tyoe

- ``sadd(key:member:)``
- ``scard(key:)``
- ``sdiff(key:)``
- ``sdiffstore(destination:key:)``
- ``sinter(key:)``
- ``sintercard(key:limit:)``
- ``sinterstore(destination:key:)``
- ``sismember(key:member:)``
- ``smembers(key:)``
- ``smismember(key:member:)``
- ``smove(source:destination:member:)``
- ``spop(key:count:)``
- ``srandmember(key:count:)``
- ``srem(key:member:)``
- ``sscan(key:cursor:pattern:count:)``
- ``sunion(key:)``
- ``sunionstore(destination:key:)``

### operations on the sorted set data type

- ``bzmpop(timeout:key:where:count:)``
- ``bzpopmax(key:timeout:)``
- ``bzpopmin(key:timeout:)``
- ``zadd(key:condition:comparison:change:increment:data:)``
- ``zcard(key:)``
- ``zcount(key:min:max:)``
- ``zdiff(key:withscores:)``
- ``zdiffstore(destination:key:)``
- ``zincrby(key:increment:member:)``
- ``zinter(key:weight:aggregate:withscores:)``
- ``zintercard(key:limit:)``
- ``zinterstore(destination:key:weight:aggregate:)``
- ``zlexcount(key:min:max:)
- ``zmpop(key:where:count:)``
- ``zmscore(key:member:)``
- ``zpopmax(key:count:)``
- ``zpopmin(key:count:)``
- ``zrandmember(key:options:)``
- ``zrange(key:start:stop:sortby:rev:limit:withscores:)``
- ``zrangebylex(key:min:max:limit:)``
- ``zrangebyscore(key:min:max:withscores:limit:)``
- ``zrangestore(dst:src:min:max:sortby:rev:limit:)``
- ``zrank(key:member:withscore:)``
- ``zrem(key:member:)``
- ``zremrangebylex(key:min:max:)``
- ``zremrangebyrank(key:start:stop:)``
- ``zremrangebyscore(key:min:max:)``
- ``zrevrange(key:start:stop:withscores:)``
- ``zrevrangebylex(key:max:min:limit:)``
- ``zrevrangebyscore(key:max:min:withscores:limit:)``
- ``zrevrank(key:member:withscore:)``
- ``zscan(key:cursor:pattern:count:noscores:)``
- ``zscore(key:member:)``
- ``zunion(key:weight:aggregate:withscores:)``
- ``zunionstore(destination:key:weight:aggregate:)``

### Operations on the Stream data type

- ``xack(key:group:id:)``
- ``xadd(key:nomkstream:trim:idSelector:data:)``
- ``xautoclaim(key:group:consumer:minIdleTime:start:count:justid:)``
- ``xclaim(key:group:consumer:minIdleTime:id:ms:unixTimeMilliseconds:count:force:justid:lastid:)``
- ``xdel(key:id:)``
xgroup
- ``xgroupCreate(key:group:idSelector:mkstream:entriesread:)``
- ``xgroupCreateconsumer(key:group:consumer:)``
- ``xgroupDelconsumer(key:group:consumer:)``
- ``xgroupDestroy(key:group:)``
- ``xgroupHelp()``
- ``xgroupSetid(key:group:idSelector:entriesread:)``
xinfo
- ``xinfoConsumers(key:group:)``
- ``xinfoGroups(key:)``
- ``xinfoHelp()``
- ``xinfoStream(key:fullBlock:)``
- ``xlen(key:)``
- ``xpending(key:group:filters:)``
- ``xrange(key:start:end:count:)``
- ``xread(count:milliseconds:streams:)``
- ``xreadgroup(groupBlock:count:milliseconds:noack:streams:)``
- ``xrevrange(key:end:start:count:)``
- ``xsetid(key:lastId:entriesAdded:maxDeletedId:)``
- ``xtrim(key:trim:)``

### Operations on the String Data type

- ``append(key:value:)``
- ``decr(key:)``
- ``decrby(key:decrement:)``
delifeq
- ``get(key:)``
- ``getdel(key:)``
- ``getex(key:expiration:)``
- ``getrange(key:start:end:)``
- ``getset(key:value:)``
- ``incr(key:)``
- ``incrby(key:increment:)``
- ``incrbyfloat(key:increment:)``
- ``lcs(key1:key2:len:idx:minMatchLen:withmatchlen:)``
- ``mget(key:)``
- ``mset(data:)``
- ``msetnx(data:)``
- ``psetex(key:milliseconds:value:)``
- ``set(key:value:condition:get:expiration:)``
- ``setex(key:seconds:value:)``
- ``setnx(key:value:)``
- ``setrange(key:offset:value:)``
- ``strlen(key:)``
- ``substr(key:start:end:)``

### Transaction management
https://valkey.io/commands/#transactions

discard
exec
multi
unwatch
watch

