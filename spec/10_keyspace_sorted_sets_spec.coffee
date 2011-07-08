require('./helpers')

describe 'redis-keyspace prefix for sorted sets', () ->
  client = null
  client2 = null
  beforeEach () ->
    client = getClientWithPrefixAndDB keyspace_name
    client2 = getClientWithPrefixAndDB 'other_prefix'
    client.zadd('myzset', 1, 'one', testError)
    client.zadd('myzset', 2, 'two', testError)
    client.zadd('myzset', 3, 'three', testError)
    client.zadd('myzset', 4, 'four', testError)
    client2.zadd('myzset', 5, 'five', testError)
    client2.zadd('myzset', 6, 'six', testError)
    client2.zadd('myzset', 7, 'seven', testError)
  afterEach () ->
    client.FLUSHDB testError
    client.quit()
    client2.quit()
  
  it 'should zadd to sorted sets in keyspace', () ->
    runBlock 'zadd new member', (done) ->
      client2.zadd('myzset', 9, 'nine', testAsync (error, reply) ->
        expect(error).toBeNull()
        expect(reply).toEqual(1)
        done()
      )
    runBlock 'zadd existing member', (done) ->
      client.zadd('myzset', 5, 'two', testAsync (error, reply) ->
        expect(error).toBeNull()
        expect(reply).toEqual(0)
        done()
      )
  it 'should get the number of member in a sorted set with zcard', () ->
    runBlock 'zcard', (done) ->
      client.zcard('myzset', testAsync (error, reply) ->
        expect(error).toBeNull()
        expect(reply).toEqual(4)
        done()
      )
  it 'should get the number of members within a score range with zcount', () ->
    runBlock 'zcount', (done) ->
      client.zcount('myzset', 2, 4, testAsync (error, reply) ->
        expect(error).toBeNull()
        expect(reply).toEqual(3)
        done()
      )
  it 'should get the score associated with a given member with zscore', () ->
    runBlock 'zscore', (done) ->
      client.zscore('myzset', 'three', testAsync (error, reply) ->
        expect(error).toBeNull()
        expect(reply).toEqual('3')
        done()
      )
  it 'should determine the index of a member with zrank', () ->
    runBlock 'zrank', (done) ->
      client.zrank('myzset', 'three', testAsync (error, reply) ->
        expect(error).toBeNull()
        expect(reply).toEqual(2)
        done()
      )
  it 'should determine the reversed index of a member with zrevrank', () ->
    runBlock 'zrank', (done) ->
      client.zrevrank('myzset', 'three', testAsync (error, reply) ->
        expect(error).toBeNull()
        expect(reply).toEqual(1)
        done()
      )
  it 'should return members within an index range with zrange', () ->
    runBlock 'zrange', (done) ->
      client.zrange('myzset', 1, 3, testAsync (error, reply) ->
        expect(error).toBeNull()
        expect(reply).toEqual(['two','three','four'])
        done()
      )
    runBlock 'zrange WITHSCORES', (done) ->
      client.zrange('myzset', 1, 3, 'WITHSCORES', testAsync (error, reply) ->
        expect(error).toBeNull()
        expect(reply).toEqual(['two','2','three','3','four','4'])
        done()
      )
  it 'should return members within a reversed index range with zrevrange', () ->
    runBlock 'zrevrange', (done) ->
      client.zrevrange('myzset', 1, 3, testAsync (error, reply) ->
        expect(error).toBeNull()
        expect(reply).toEqual(['three','two', 'one'])
        done()
      )
    runBlock 'zrevrange WITHSCORES', (done) ->
      client.zrevrange('myzset', 1, 3, 'WITHSCORES', testAsync (error, reply) ->
        expect(error).toBeNull()
        expect(reply).toEqual(['three','3','two','2','one','1'])
        done()
      )
  it 'should return members within a score range with zrangebyscore', () ->
    runBlock 'zrangebyscore', (done) ->
      client.zrangebyscore('myzset', 2, 4, testAsync (error, reply) ->
        expect(error).toBeNull()
        expect(reply).toEqual(['two','three','four'])
        done()
      )
    runBlock 'zrangebyscore WITHSCORES', (done) ->
      client.zrangebyscore('myzset', 2, 4, 'WITHSCORES', testAsync (error, reply) ->
        expect(error).toBeNull()
        expect(reply).toEqual(['two','2','three','3','four','4'])
        done()
      )
  it 'should return members within a reversed score range with zrevrangebyscore', () ->
    runBlock 'zrevrangebyscore', (done) ->
      client.zrevrangebyscore('myzset', 3, 1, testAsync (error, reply) ->
        expect(error).toBeNull()
        expect(reply).toEqual(['three','two', 'one'])
        done()
      )
    runBlock 'zrevrangebyscore WITHSCORES', (done) ->
      client.zrevrangebyscore('myzset', 3, 1, 'WITHSCORES', testAsync (error, reply) ->
        expect(error).toBeNull()
        expect(reply).toEqual(['three','3','two','2','one','1'])
        done()
      )
  it 'should remove a member with zrem', () ->
    runBlock 'zrem', (done) ->
      client.zrem('myzset','one', testAsync (error, reply) ->
        expect(error).toBeNull()
        expect(reply).toEqual(1)
        done()
      )
    runBlock 'zscore', (done) ->
      client.zscore('myzset', 'one', testAsync (error, reply) ->
        expect(error).toBeNull()
        expect(reply).toBeNull()
        done()
      )