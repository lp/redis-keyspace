require('./helpers')

describe 'redis-keyspace prefix for strings', () ->
  client = null
  client2 = null
  beforeEach () ->
    client = getClientWithPrefixAndDB keyspace_name
    client2 = getClientWithPrefixAndDB 'other_prefix'
    client.set('someKey', 'someValue', testError )
    client2.set('someKey', 'otherValue', testError )
  afterEach () ->
    client.FLUSHDB testError
    client.quit()
    client2.quit()
    
  it 'should work with get and set in different keyspaces', () ->
    runBlock 'set in keyspace A', (done) ->
      client.set('newKey', 'someValue', testAsync (error, reply) ->
        expect(error).toBeNull()
        expect(reply).toEqual('OK')
        done()
      )
    runBlock 'set in keyspace B', (done) ->
      client2.set('newKey', 'otherValue', testAsync (error, reply) ->
        expect(error).toBeNull()
        expect(reply).toEqual('OK')
        done()
      )
    runBlock 'get in keyspace A', (done) ->
      client.get('newKey', testAsync (error, reply) ->
        expect(error).toBeNull()
        expect(reply).toEqual('someValue')
        done()
      )
    runBlock 'get in keyspace B', (done) ->
      client2.get('newKey', testAsync (error, reply) ->
        expect(error).toBeNull()
        expect(reply).toEqual('otherValue')
        done()
      )
    runBlock 'getset in keyspace A', (done) ->
      client.getset('someKey', 'newValue', testAsync (error, reply) ->
        expect(error).toBeNull()
        expect(reply).toEqual('someValue')
        done()
      )
    runBlock 'getset in keyspace B', (done) ->
      client2.getset('someKey', 'newValue', testAsync (error, reply) ->
        expect(error).toBeNull()
        expect(reply).toEqual('otherValue')
        done()
      )
  
  it 'should setnx in different keyspaces', () ->
    runBlock 'setnx fails in keyspace B', (done) ->
      client2.setnx('someKey','newValue', testAsync (error, reply) ->
        expect(error).toBeNull()
        expect(reply).toEqual(0)
        done()
      )
    runBlock 'setnx succeed in keyspace B', (done) ->
      client2.setnx('newKey','newValue', testAsync (error, reply) ->
        expect(error).toBeNull()
        expect(reply).toEqual(1)
        done()
      )
  
  it 'should append in different keyspaces', () ->
    runBlock 'append to existing key in keyspace B', (done) ->
      client2.append('someKey', "more", testAsync (error, reply) ->
        expect(error).toBeNull()
        expect(reply).toEqual(14)
        done()
      )
    runBlock 'append to new key in keyspace A', (done) ->
      client.append('someKey', "more", testAsync (error, reply) ->
        expect(error).toBeNull()
        expect(reply).toEqual(13)
        done()
      )
    runBlock 'confirms appended key exist in keyspace B', (done) ->
      client2.get('someKey', testAsync (error, reply) ->
        expect(error).toBeNull()
        expect(reply).toEqual('otherValuemore')
        done()
      )
  it 'should setrange and getrange in different keyspaces', () ->
    runBlock 'setrange in keyspace A', (done) ->
      client.setrange('someKey', 1, 'ZZZ', testAsync (error, reply) ->
        expect(error).toBeNull()
        expect(reply).toEqual(9)
        done()
      )
    runBlock 'setrange in keyspace B', (done) ->
      client2.setrange('someKey', 8, 'ZZZ', testAsync (error, reply) ->
        expect(error).toBeNull()
        expect(reply).toEqual(11)
        done()
      )
    runBlock 'getrange from keyspace A', (done) ->
      client.getrange('someKey', 0, 1, testAsync (error, reply) ->
        expect(error).toBeNull()
        expect(reply).toEqual('sZ')
        done()
      )
    runBlock 'getrange from keyspace B', (done) ->
      client2.getrange('someKey', 7, 9, testAsync (error, reply) ->
        expect(error).toBeNull()
        expect(reply).toEqual('lZZ')
        done()
      )
  it 'should mset and mget in different keyspaces', () ->
    runBlock 'mset in keyspace A', (done) ->
      client.mset('key1', 'valueA1', 'key2', 'valueA2', testAsync (error, reply) ->
        expect(error).toBeNull()
        expect(reply).toEqual('OK')
        done()
      )
    runBlock 'mset in keyspace B', (done) ->
      client2.mset('key1', 'valueB1', 'key2', 'valueB2', testAsync (error, reply) ->
        expect(error).toBeNull()
        expect(reply).toEqual('OK')
        done()
      )
    runBlock 'mget in keyspace A', (done) ->
      client.mget('key1', 'key2', testAsync (error, reply) ->
        expect(error).toBeNull()
        expect(reply).toEqual(['valueA1', 'valueA2'])
        done()
      )
    runBlock 'mget in keyspace B', (done) ->
      client2.mget('key1', 'key2', testAsync (error, reply) ->
        expect(error).toBeNull()
        expect(reply).toEqual(['valueB1', 'valueB2'])
        done()
      )    
  it 'should msetnx in different keyspaces', () ->
    runBlock 'msetnx fail in keyspace A', (done) ->
      client.msetnx('key1', 'valueA1', 'key2', 'valueA2', 'someKey', 'someValue', testAsync (error, reply) ->
        expect(error).toBeNull()
        expect(reply).toEqual(0)
        done()
      )
    runBlock 'msetnx fail in keyspace A', (done) ->
      client.msetnx('key1', 'valueA1', 'key2', 'valueA2', testAsync (error, reply) ->
        expect(error).toBeNull()
        expect(reply).toEqual(1)
        done()
      )
    runBlock 'msetnx fail in keyspace B', (done) ->
      client2.msetnx('key1', 'valueA1', 'key2', 'valueA2', 'someKey', 'someValue', testAsync (error, reply) ->
        expect(error).toBeNull()
        expect(reply).toEqual(0)
        done()
      )
    runBlock 'msetnx fail in keyspace B', (done) ->
      client2.msetnx('key1', 'valueA1', 'key2', 'valueA2', testAsync (error, reply) ->
        expect(error).toBeNull()
        expect(reply).toEqual(1)
        done()
      )
    runBlock 'mget to confirm msetnx in keyspace A', (done) ->
      client.mget('key1', 'key2', testAsync (error, reply) ->
        expect(error).toBeNull()
        expect(reply).toEqual(['valueA1', 'valueA2'])
        done()
      )
    runBlock 'mget to confirm msetnx in keyspace B', (done) ->
      client2.mget('key1', 'key2', testAsync (error, reply) ->
        expect(error).toBeNull()
        expect(reply).toEqual(['valueA1', 'valueA2'])
        done()
      )
  it 'should incr and decr in different keyspaces', () ->
    runBlock 'incr in keyspace A', (done) ->
      client.incr('count', testAsync (error, reply) ->
        expect(error).toBeNull()
        expect(reply).toEqual(1)
        done()
      )
    runBlock 'incr in keyspace B', (done) ->
      client2.incr('count', testAsync (error, reply) ->
        expect(error).toBeNull()
        expect(reply).toEqual(1)
        done()
      )
    runBlock 'decr in keyspace A', (done) ->
      client.decr('count', testAsync (error, reply) ->
        expect(error).toBeNull()
        expect(reply).toEqual(0)
        done()
      )
    runBlock 'decr in keyspace B', (done) ->
      client2.decr('count', testAsync (error, reply) ->
        expect(error).toBeNull()
        expect(reply).toEqual(0)
        done()
      )
    runBlock 'incrby in keyspace A', (done) ->
      client.incrby('count', 10, testAsync (error, reply) ->
        expect(error).toBeNull()
        expect(reply).toEqual(10)
        done()
      )
    runBlock 'incrby in keyspace B', (done) ->
      client2.incrby('count', 5, testAsync (error, reply) ->
        expect(error).toBeNull()
        expect(reply).toEqual(5)
        done()
      )
    runBlock 'decrby in keyspace A', (done) ->
      client.decrby('count', 3, testAsync (error, reply) ->
        expect(error).toBeNull()
        expect(reply).toEqual(7)
        done()
      )
    runBlock 'decrby in keyspace B', (done) ->
      client2.decrby('count', 2, testAsync (error, reply) ->
        expect(error).toBeNull()
        expect(reply).toEqual(3)
        done()
      )
  it 'should get strlen', () ->
    runBlock 'strlen in keyspace A', (done) ->
      client.strlen('someKey', testAsync (error, reply) ->
        expect(error).toBeNull()
        expect(reply).toEqual(9)
        done()
      )
    runBlock 'strlen in keyspace B', (done) ->
      client2.strlen('someKey', testAsync (error, reply) ->
        expect(error).toBeNull()
        expect(reply).toEqual(10)
        done()
      )
  it 'should setbit and getbit', () ->
    runBlock 'setbit in keyspace A', (done) ->
      client.setbit('bitkey', 0, 1, testAsync (error, reply) ->
        expect(error).toBeNull()
        expect(reply).toEqual(0)
        done()
      )
    runBlock 'setbit in keyspace B', (done) ->
      client2.setbit('bitkey', 0, 0, testAsync (error, reply) ->
        expect(error).toBeNull()
        expect(reply).toEqual(0)
        done()
      )
    runBlock 'getbit in keyspace A', (done) ->
      client.getbit('bitkey', 0, testAsync (error, reply) ->
        expect(error).toBeNull()
        expect(reply).toEqual(1)
        done()
      )
    runBlock 'getbit in keyspace B', (done) ->
      client2.getbit('bitkey', 0, testAsync (error, reply) ->
        expect(error).toBeNull()
        expect(reply).toEqual(0)
        done()
      )
  it 'should setex', () ->
    runBlock 'setex in keyspace A', (done) ->
      client.setex('exkey', 10, 'exvalue', testAsync (error, reply) ->
        expect(error).toBeNull()
        expect(reply).toEqual('OK')
        done()
      )
    runBlock 'setex in keyspace B', (done) ->
      client2.setex('exkey', 20, 'exvalue', testAsync (error, reply) ->
        expect(error).toBeNull()
        expect(reply).toEqual('OK')
        done()
      )

