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