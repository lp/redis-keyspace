require('./helpers')

describe 'redis-keyspace prefix for hashes', () ->
  client = null
  client2 = null
  beforeEach () ->
    client = getClientWithPrefixAndDB keyspace_name
    client2 = getClientWithPrefixAndDB 'other_prefix'
    client.rpush('testlist', 'val1', testError)
    client.rpush('testlist', 'val2', testError)
    client.rpush('testlist', 'val3', testError)
    client2.rpush('testlist', 'val4', testError)
    client2.rpush('testlist', 'val5', testError)
    client2.rpush('testlist', 'val6', testError)
    client2.rpush('testlist', 'val7', testError)
  afterEach () ->
    client.FLUSHDB testError
    client.quit()
    client2.quit()
    
  it 'should get the length of a list with llen', () ->
    runBlock 'llen', (done) ->
      client.llen('testlist', testAsync (error, reply) ->
        expect(error).toBeNull()
        expect(reply).toEqual(3)
        done()
      )
  it 'should remove from a list with lrem', () ->
    runBlock 'lrem', (done) ->
      client.lrem('testlist', 0, 'val2', testAsync (error,reply) ->
        expect(error).toBeNull()
        expect(reply).toEqual(1)
        done()
      )
  it 'should add an member to a list with lpush', () ->
    runBlock 'lpush', (done) ->
      client2.lpush('testlist', 'val3', testAsync (error,reply) ->
        expect(error).toBeNull()
        expect(reply).toEqual(5)
        done()
      )
  it 'should add an member to a list with rpush', () ->
    runBlock 'rpush', (done) ->
      client2.rpush('testlist', 'val8', testAsync (error,reply) ->
        expect(error).toBeNull()
        expect(reply).toEqual(5)
        done()
      )
  it 'should add an member to a list only if a list exist with lpushx', () ->
    runBlock 'lpushx', (done) ->
      client2.lpushx('newlist', 'val0', testAsync (error,reply) ->
        expect(error).toBeNull()
        expect(reply).toEqual(0)
        done()
      )
  it 'should add an member to a list only if a list exist with rpushx', () ->
    runBlock 'rpushx', (done) ->
      client2.rpushx('testlist', 'val8', testAsync (error,reply) ->
        expect(error).toBeNull()
        expect(reply).toEqual(5)
        done()
      )
  it 'should get a member by its index with lindex', () ->
    runBlock 'lindex', (done) ->
      client.lindex('testlist',2, testAsync (error,reply) ->
        expect(error).toBeNull()
        expect(reply).toEqual('val3')
        done()
      )
  it 'should get a range of members with lrange', () ->
    runBlock 'lrange', (done) ->
      client.lrange('testlist',1,10, testAsync (error,reply) ->
        expect(error).toBeNull()
        expect(reply).toEqual(['val2','val3'])
        done()
      )
  it 'should pop the first member with lpop', () ->
    runBlock 'lpop', (done) ->
      client.lpop('testlist', testAsync (error,reply) ->
        expect(error).toBeNull()
        expect(reply).toEqual('val1')
        done()
      )