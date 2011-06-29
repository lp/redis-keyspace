# Copyright (C) 2011 by Louis-Philippe Perron
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

exports.createClient = (prefix, port=6379, host='127.0.0.1') ->
  new RedisKeyspace(prefix, require("redis").createClient(port,host))
  
exports.createKeyspace = (prefix, redis) ->
  if not redis?
    redis = require("redis").createClient()
  new RedisKeyspace(prefix, redis)

NO_KEY = -1
FIRST_KEY = 0
LAST_KEY = 1
NOT_FIRST_KEY = 2
NOT_LAST_KEY = 3
ALL_KEYS = 4
ODDS_KEY = 5
UNKNOWN_KEY = 6
COMMANDS = 
  append: FIRST_KEY
  auth: NO_KEY
  bgrewriteaof: NO_KEY
  bgsave: NO_KEY
  blpop: NOT_LAST_KEY
  brpop: NOT_LAST_KEY
  brpoplpush: NOT_LAST_KEY
  "config get": NO_KEY
  "config set": NO_KEY
  "config resetstat": NO_KEY
  dbsize: NO_KEY
  "debug object": FIRST_KEY
  "debug segfault": NO_KEY
  decr: FIRST_KEY
  decrby: FIRST_KEY
  del: ALL_KEYS
  discard: NO_KEY
  echo: NO_KEY
  exec: NO_KEY
  exists: FIRST_KEY
  expire: FIRST_KEY
  expireat: FIRST_KEY
  flushall: NO_KEY
  flushdb: NO_KEY
  get: FIRST_KEY
  getbit: FIRST_KEY
  getrange: FIRST_KEY
  getset: FIRST_KEY
  hdel: FIRST_KEY
  hexists: FIRST_KEY
  hget: FIRST_KEY
  hgetall: FIRST_KEY
  hincrby: FIRST_KEY
  hkeys: FIRST_KEY
  hlen: FIRST_KEY
  hmget: FIRST_KEY
  hmset: FIRST_KEY
  hset: FIRST_KEY
  hsetnx: FIRST_KEY
  hvals: FIRST_KEY
  incr: FIRST_KEY
  incrby: FIRST_KEY
  info: NO_KEY
  keys: FIRST_KEY
  lastsave: NO_KEY
  lindex: FIRST_KEY
  linsert: FIRST_KEY
  llen: FIRST_KEY
  lpop: FIRST_KEY
  lpush: FIRST_KEY
  lpushx: FIRST_KEY
  lrange: FIRST_KEY
  lrem: FIRST_KEY
  lset: FIRST_KEY
  ltrim: FIRST_KEY
  mget: ALL_KEYS
  monitor: NO_KEY
  move: FIRST_KEY
  mset: ODDS_KEY
  msetnx: ODDS_KEY
  multi: NO_KEY
  object: NO_KEY
  persist: FIRST_KEY
  ping: NO_KEY
  psubscribe: NO_KEY
  publish: NO_KEY
  punsubscribe: NO_KEY
  quit: NO_KEY
  randomkey: NO_KEY
  rename: ALL_KEYS
  renamenx: ALL_KEYS
  rpop: FIRST_KEY
  rpoplpush: ALL_KEYS
  rpush: FIRST_KEY
  rpushx: FIRST_KEY
  sadd: FIRST_KEY
  save: NO_KEY
  scard: FIRST_KEY
  sdiff: ALL_KEYS
  sdiffstore: ALL_KEYS
  select: NO_KEY
  set: FIRST_KEY
  setbit: FIRST_KEY
  setex: FIRST_KEY
  setnx: FIRST_KEY
  setrange: FIRST_KEY
  shutdown: NO_KEY
  sinter: ALL_KEYS
  sinterstore: ALL_KEYS
  sismember: FIRST_KEY
  slaveof: NO_KEY
  smembers: FIRST_KEY
  smove: NOT_LAST_KEY
  sort: FIRST_KEY
  spop: FIRST_KEY
  srandmember: FIRST_KEY
  srem: FIRST_KEY
  strlen: FIRST_KEY
  subscribe: NO_KEY
  sunion: ALL_KEYS
  sunionstore: ALL_KEYS
  sync: NO_KEY
  ttl: FIRST_KEY
  type: FIRST_KEY
  unsubscribe: NO_KEY
  unwatch: NO_KEY
  watch: ALL_KEYS
  zadd: FIRST_KEY
  zcard: FIRST_KEY
  zcount: FIRST_KEY
  zincrby: FIRST_KEY
  zinterstore: UNKNOWN_KEY
  zrange: FIRST_KEY
  zrangebyscore: FIRST_KEY
  zrank: FIRST_KEY
  zrem: FIRST_KEY
  zremrangebyrank: FIRST_KEY
  zremrangebyscore: FIRST_KEY
  zrevrange: FIRST_KEY
  zrevrangebyscore: FIRST_KEY
  zrevrank: FIRST_KEY
  zscore: FIRST_KEY
  zunionstore: UNKNOWN_KEY

class RedisKeyspace
  constructor: (@prefix, @redis) ->
    @reply_parser = @redis.reply_parser
    generate_key = (key) -> prefix + ":" + key
    for name, key_pos of COMMANDS
      do (name, key_pos) ->
        RedisKeyspace::[name] = (args...) ->
          func = args.pop()
          if key_pos is FIRST_KEY
            args[0] = generate_key(args[0])
          else if key_pos is LAST_KEY
            args[args.length - 1] == generate_key(args[args.length - 1])
          else if key_pos is ALL_KEYS or key_pos is NOT_FIRST_KEY or key_pos is NOT_LAST_KEY
            loop_start = 0
            loop_end = args.length
            if key_pos is NOT_FIRST_KEY
              loop_start++
            else if key_pos is NOT_LAST_KEY
              loop_end--
            i = loop_start
            while i < loop_end
              args[i] = generate_key(args[i])
              i++
          @redis.send_command name, args, func
