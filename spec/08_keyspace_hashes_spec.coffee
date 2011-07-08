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
  it 'should set key in hash with hset', () ->
    runBlock 'hset', (done) ->
      client2.hset('testhash', 'keymore', 'valuemore', testAsync (error, reply) ->
        expect(error).toBeNull()
        expect(reply).toEqual(1)
        done()
      )
    runBlock 'hlen to confirm hset', (done) ->
      client2.hlen('testhash', testAsync (error, reply) ->
        expect(error).toBeNull()
        expect(reply).toEqual(5)
        done()
      )
  it 'should get key in hash with hget', () ->
    runBlock 'hget', (done) ->
      client.hget('testhash', 'key2', testAsync (error, reply) ->
        expect(error).toBeNull()
        expect(reply).toEqual('value2')
        done()
      )
  it 'should delete a key in hash with hdel', () ->
    runBlock 'hdel', (done) ->
      client.hdel('testhash', 'key3', testAsync (error, reply) ->
        expect(error).toBeNull()
        expect(reply).toEqual(1)
        done()
      )
    runBlock 'hlen to confirm hdel', (done) ->
      client.hlen('testhash', testAsync (error, reply) ->
        expect(error).toBeNull()
        expect(reply).toEqual(2)
        done()
      )
  it 'should tell if a key exist with hexists', () ->
    runBlock 'hexists', (done) ->
      client.hexists('testhash', 'key2', testAsync (error, reply) ->
        expect(error).toBeNull()
        expect(reply).toEqual(1)
        done()
      )
  it 'should return all key and values with hgetall', () ->
    runBlock 'hgetall', (done) ->
      client.hgetall('testhash', testAsync (error, reply) ->
        expect(error).toBeNull()
        expect(reply).toEqual({key1:'value1',key2:'value2',key3:'value3'})
        done()
      )
  it 'should return all keys with hkeys', () ->
    runBlock 'hkeys', (done) ->
      client.hkeys('testhash', testAsync (error, reply) ->
        expect(error).toBeNull()
        expect(reply).toEqual(['key1','key2','key3'])
        done()
      )
  it 'should return all values with hvals', () ->
    runBlock 'hvals', (done) ->
      client.hvals('testhash', testAsync (error, reply) ->
        expect(error).toBeNull()
        expect(reply).toEqual(['value1','value2','value3'])
        done()
      )