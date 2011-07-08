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