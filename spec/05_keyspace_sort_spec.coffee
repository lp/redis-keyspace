require('./helpers')

describe 'redis-keyspace prefix in complex sort', () ->
  client = null
  client2 = null
  beforeEach () ->
    client = getClientWithPrefixAndDB keyspace_name
    client2 = getClientWithPrefixAndDB 'other_prefix'
    client.rpush('sortlist', 'a', testError)
    client.rpush('sortlist', 'b', testError)
    client.rpush('sortlist', 'c', testError)
    client.set('weight_a', 2, testError)
    client.set('weight_b', 3, testError)
    client.set('weight_c', 1, testError)
    client.set('object_a', 'object-a', testError)
    client.set('object_b', 'object-b', testError)
    client.set('object_c', 'object-c', testError)
  afterEach () ->
    client.FLUSHDB testError
    client.quit()
    client2.quit()
  it 'should sort simply', () ->
    runBlock 'sort list', (done) ->
      client.sort('sortlist', testAsync (error, reply) ->
        expect(error).toBeNull()
        expect(reply).toEqual(['a', 'b', 'c'])
        done()
      )
    runBlock 'sort list BY weight_*', (done) ->
      client.sort('sortlist', 'BY', 'weight_*', testAsync (error, reply) ->
        expect(error).toBeNull()
        expect(reply).toEqual(['c', 'a', 'b'])
        done()
      )
    runBlock 'sort list BY weight_* GET object_*', (done) ->
      client.sort('sortlist', 'BY', 'weight_*', 'GET', 'object_*', testAsync (error, reply) ->
        expect(error).toBeNull()
        expect(reply).toEqual(['object-c', 'object-a', 'object-b'])
        done()
      )
    runBlock 'sort list BY weight_* GET object_* STORE newlist', (done) ->
      client.sort('sortlist', 'BY', 'weight_*', 'GET', 'object_*', 'STORE', 'newlist', testAsync (error, reply) ->
        expect(error).toBeNull()
        expect(reply).toEqual(3)
        done()
      )
    runBlock 'sort stored verification', (done) ->
      client.lindex('newlist',1, testAsync (error, reply) ->
        expect(error).toBeNull()
        expect(reply).toEqual('object-a')
        done()
      )
