require('./helpers')

describe 'redis-keyspace prefix for hashes', () ->
  client = null
  client2 = null
  beforeEach () ->
    client = getClientWithPrefixAndDB keyspace_name
    client2 = getClientWithPrefixAndDB 'other_prefix'
    client.hmset('testhash', {
      key1: 'value1',
      key2: 'value2',
      key3: 'value3'
    }, testError)
    client2.hmset('testhash', {
      key4: 'value4',
      key5: 'value5',
      key6: 'value6',
      key7: 'value7'
    }, testError)
  afterEach () ->
    client.FLUSHDB testError
    client.quit()
    client2.quit()
    
  it 'should get hash length with hlen', () ->
    runBlock 'hlen', (done) ->
      client.hlen('testhash', testAsync (error, reply) ->
        expect(error).toBeNull()
        expect(reply).toEqual(3)
        done()
      )