require('./helpers')
_ = require('underscore')

describe 'redis-keyspace prefix for keys', () ->
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
  it 'should delete keys is different keyspaces', () ->
    runBlock 'exists in keyspace A', (done) ->
      client.exists('someKey', testAsync (error, reply) ->
        expect(error).toBeNull()
        expect(reply).toEqual(1)
        done()
      )
    runBlock 'del in keyspace A', (done) ->
      client.del('someKey', testAsync (error, reply) ->
        expect(error).toBeNull()
        expect(reply).toEqual(1)
        done()
      )
    runBlock 'do not exists in keyspace A', (done) ->
      client.exists('someKey', testAsync (error, reply) ->
        expect(error).toBeNull()
        expect(reply).toEqual(0)
        done()
      )
  it 'should rename keys in different keyspaces', () ->
    runBlock 'rename in keyspace B', (done) ->
      client2.rename('someKey', 'renamedKey', testAsync (error, reply) ->
        expect(error).toBeNull()
        expect(reply).toEqual('OK')
        done()
      )
    runBlock 'renamed exists in keyspace B', (done) ->
      client2.exists('renamedKey', testAsync (error, reply) ->
        expect(error).toBeNull()
        expect(reply).toEqual(1)
        done()
      )
    runBlock 'renamenx in keyspace A', (done) ->
      client.renamenx('someKey', 'otherRenamedKey', testAsync (error, reply) ->
        expect(error).toBeNull()
        expect(reply).toEqual(1)
        done()
      )
    runBlock 'renamednx exists in keyspace A', (done) ->
      client.exists('otherRenamedKey', testAsync (error, reply) ->
        expect(error).toBeNull()
        expect(reply).toEqual(1)
        done()
      )
  it 'should get the type of a key', () ->
    runBlock 'type of key', (done) ->
      client.type('someKey', testAsync (error, reply) ->
        expect(error).toBeNull()
        expect(reply).toEqual('string')
        done()
      )
  it 'should manage keys expirations', () ->
    runBlock 'expire key', (done) ->
      client.expire('someKey', 10, testAsync (error, reply) ->
        expect(error).toBeNull()
        expect(reply).toEqual(1)
        done()
      )
    runBlock 'ttl key', (done) ->
      client.ttl('someKey', testAsync (error,reply) ->
        expect(error).toBeNull()
        expect(reply).toEqual(10)
        done()
      )
    runBlock 'persist key', (done) ->
      client.persist('someKey', testAsync (error, reply) ->
        expect(error).toBeNull()
        expect(reply).toEqual(1)
        done()
      )
    runBlock 'expireat key', (done) ->
      client.expireat('someKey', +new Date() + 20000, testAsync (error, reply) ->
        expect(error).toBeNull()
        expect(reply).toEqual(1)
        done()
      )
    runBlock 'ttl key after expireat', (done) ->
      client.ttl('someKey', testAsync (error,reply) ->
        expect(error).toBeNull()
        expect(reply).toBeGreaterThan(1000000000000)
        done()
      )
  it 'should move keys between db', () ->
    runBlock 'prepare client on other db', (done) ->
      @client3 = getClientWithPrefixAndDB keyspace_name
      @client3.select(14, testError)
      done()
    runBlock 'move key', (done) ->
      client.move('someKey', 14, testAsync (error, reply) ->
        expect(error).toBeNull()
        expect(reply).toEqual(1)
        done()
      )
    runBlock 'exists moved key', (done) ->
      @client3.exists('someKey', testAsync (error, reply) ->
        expect(error).toBeNull()
        expect(reply).toEqual(1)
        done()
      )
    runBlock 'do not exists moved key', (done) ->
      client.exists('someKey', testAsync (error, reply) ->
        expect(error).toBeNull()
        expect(reply).toEqual(0)
        done()
      )
    runBlock 'del other db key', (done) ->
      @client3.del('someKey', testAsync (error, reply) ->
        expect(error).toBeNull()
        expect(reply).toEqual(1)
        done()
      )
    runBlock 'close other db client', (done) ->
      @client3.quit()
      done()
  it 'should get object in keyspace', () ->
    runBlock 'object refcount key', (done) ->
      client.object('REFCOUNT', 'someKey', testAsync (error, reply) ->
        expect(error).toBeNull()
        expect(reply).toEqual(1)
        done()
      )
    runBlock 'object encoding key', (done) ->
      client.object('ENCODING', 'someKey', testAsync (error, reply) ->
        expect(error).toBeNull()
        expect(reply).toEqual('raw')
        done()
      )
    runBlock 'object idletime key', (done) ->
      client.object('IDLETIME', 'someKey', testAsync (error, reply) ->
        expect(error).toBeNull()
        expect(reply).toEqual(0)
        done()
      )
  it 'should get the keys by pattern', () ->
    runBlock 'keys*', (done) ->
      client.keys('*', testAsync (error, reply) ->
        expect(error).toBeNull()
        expect(reply).toEqual(['someKey'])
        done()
      )
    runBlock 'keys someKey', (done) ->
      client.keys('someKey', testAsync (error,reply) ->
        expect(error).toBeNull()
        expect(reply).toEqual(['someKey'])
        done()
      )
  it 'should get randomkey inside keyspace', () ->
    client.rename('someKey', 'r1', testError)
    client.set('r2', 'v2', testError)
    client.set('r3', 'v3', testError)
    client.set('r4', 'v4', testError)
    client.set('r5', 'v5', testError)
    runBlock 'randomkey', (done) ->
      client.randomkey(testAsync (error,reply) ->
        expect(error).toBeNull()
        expect(_.include(['r1','r2','r3','r4','r5'], reply)).toBeTruthy()
        done()
      )
    