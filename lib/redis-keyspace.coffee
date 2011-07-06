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

_ = require('underscore')
net = require('net')
redis = require('redis')
RedisClient = redis.RedisClient
Multi = redis.Multi

exports.createClient = (port=6379, host='127.0.0.1', options={}) ->
  if _(port).isNumber() and _(host).isString()
    new RedisKeyspace(port, host, options)
    
exports.print = (err, reply) ->
  redis.print(err, reply)


NO_KEY = -1
FIRST_KEY = 0
LAST_KEY = 1
NOT_FIRST_KEY = 2
NOT_LAST_KEY = 3
ALL_KEYS = 4
ODDS_KEY = 5
SORT_KEY = 6
UNKNOWN_KEY = 7
COMMANDS = 
  append: FIRST_KEY
  blpop: NOT_LAST_KEY
  brpop: NOT_LAST_KEY
  brpoplpush: NOT_LAST_KEY
  "debug object": FIRST_KEY
  decr: FIRST_KEY
  decrby: FIRST_KEY
  del: ALL_KEYS
  exists: FIRST_KEY
  expire: FIRST_KEY
  expireat: FIRST_KEY
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
  keys: FIRST_KEY
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
  move: FIRST_KEY
  mset: ODDS_KEY
  msetnx: ODDS_KEY
  object: LAST_KEY
  persist: FIRST_KEY
  rename: ALL_KEYS
  renamenx: ALL_KEYS
  rpop: FIRST_KEY
  rpoplpush: ALL_KEYS
  rpush: FIRST_KEY
  rpushx: FIRST_KEY
  sadd: FIRST_KEY
  scard: FIRST_KEY
  sdiff: ALL_KEYS
  sdiffstore: ALL_KEYS
  set: FIRST_KEY
  setbit: FIRST_KEY
  setex: FIRST_KEY
  setnx: FIRST_KEY
  setrange: FIRST_KEY
  sinter: ALL_KEYS
  sinterstore: ALL_KEYS
  sismember: FIRST_KEY
  smembers: FIRST_KEY
  smove: NOT_LAST_KEY
  sort: SORT_KEY
  spop: FIRST_KEY
  srandmember: FIRST_KEY
  srem: FIRST_KEY
  strlen: FIRST_KEY
  sunion: ALL_KEYS
  sunionstore: ALL_KEYS
  ttl: FIRST_KEY
  type: FIRST_KEY
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

parse_hmset_args = (args) ->
  if args.length >= 2 and typeof args[0] is 'string' and typeof args[1] is 'object'
    tmp_args = [args[0]]
    _.each( _.keys(args[1]), (key) ->
      tmp_args.push(key)
      tmp_args.push(args[1][key]))
    tmp_args
  else
    args
    
generate_key = (key, prefix) ->
  if prefix?
    prefix + ":" + key
  else
    key
    
isEven = (num) ->
  if num % 2 is 0
    true
  else
    false
    
parse_sort_keys = (args, prefix) ->
  new_args = []
  _.each(args, (arg, index) ->
    if index is 0 or arg.substr(-1) is '*' or (index is args.length-1 and args[index-1] is 'STORE')
      new_args.push generate_key(arg, prefix)
    else
      new_args.push arg
  )
  new_args

prefix_args = (args, key_pos, prefix) ->
  if key_pos is FIRST_KEY
    args[0] = generate_key(args[0], prefix)
  else if key_pos is LAST_KEY
    args[args.length - 1] = generate_key(args[args.length - 1], prefix)
  else if key_pos is ALL_KEYS or key_pos is NOT_FIRST_KEY or key_pos is NOT_LAST_KEY or key_pos is ODDS_KEY
    loop_start = 0
    loop_end = args.length
    if key_pos is NOT_FIRST_KEY
      loop_start++
    else if key_pos is NOT_LAST_KEY
      loop_end--
    i = loop_start
    while i < loop_end
      if key_pos is ODDS_KEY and isEven i
        args[i] = generate_key(args[i], prefix)
      else if key_pos isnt ODDS_KEY
        args[i] = generate_key(args[i], prefix)
      i++
  else if key_pos is SORT_KEY
    args = parse_sort_keys(args, prefix)
  args

class MultiKeyspace extends Multi
  constructor: (client,args) ->
    if client.options['prefix']?
      @prefix = client.options['prefix']
    else
      @prefix = null
    super(client,args)
    
  exec: (callback) ->
    @queue = _.map(@queue, (args) ->
      if COMMANDS[args[0]]?
        if args[0] is 'hmset' or args[0] is 'HMSET'
          args = parse_hmset_args(args[1..args.length])
          args.unshift('hmset')
        key_pos = COMMANDS[args[0]]
        prefix_args(args, key_pos, @prefix)
      else
        args
    )
    super callback

class RedisKeyspace extends RedisClient
  constructor: (@port, @host, @options) ->
    for name, key_pos of COMMANDS
      do (name, key_pos) ->
        cmd_func = (_args...) ->
          args = _.toArray(_args)
          func = null
          if typeof args[args.length-1] is 'function'
            func = args.pop()
          if name is 'hmset'
            args = parse_hmset_args(args)
            
          args = prefix_args(args, key_pos, @options['prefix'])
          if func?
            @send_command name, args, func
          else
            @send_command name, args
        RedisKeyspace::[name] = cmd_func
        RedisKeyspace::[name.toUpperCase()] = cmd_func
    net_client = net.createConnection(port, host)
    super(net_client, @options)
  
  multi: (args) -> new MultiKeyspace(this, args)
  MULTI: (args) -> new MultiKeyspace(this, args)

