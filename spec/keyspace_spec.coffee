_ = require('underscore')
rk = require('../index')

db_num = 15
keyspace_name = 'test_ks'

getClientWithPrefix = (prefix) ->
  ready = false
  isReady = () -> ready
  client = rk.createClient(6379, '127.0.0.1', {'prefix': prefix})
  client.on 'ready', () -> ready = true
  waitsFor isReady
  client.select(db_num, (err, reply) ->
    if err?
      throw 'Cannot select redis db ' + db_num + ' for testing.  Aborting!'
  )
  client

testAsync = (test) ->
  (err, ret) ->
    test(err, ret)
    
testError = () ->
  (err, ret) ->
    if err?
      throw 'BAILING OUT: ' + err

runBlock = (name, func) ->
  complete = false
  completed = () -> complete
  done = () -> complete = true
  runs () ->
    console.log "\n-> " + name
    func(done)
  waitsFor completed
  
xrunBlock = (name, func) ->
  runs () ->
    console.log "\nxSKIP< " + name + " >"
    
describe 'decent test environment', () ->
  client = null
  beforeEach () ->
    client = getClientWithPrefix keyspace_name
  afterEach () ->
    client.quit()
  it 'should not have any keys inside db 15', () ->
    runBlock 'keys * in db 15 == 0', (done) ->
      client.keys('*', testAsync (error, reply) ->
        expect(error).toBeNull()
        expect(reply.length).toEqual(0)
        done()
      )

describe 'redis-keyspace initialization', () ->
  it 'should createClient with no extra arguments', () ->
    expect( rk.createClient()).toBeDefined()
  it 'should createClient with extra arguments', () ->
    expect( rk.createClient(6379, '127.0.0.1', {'prefix': keyspace_name})).toBeDefined()


describe 'redis-keyspace with redis commands', () ->
  client = null
  beforeEach () ->
    client = getClientWithPrefix keyspace_name
  afterEach () ->
    client.quit()
  it 'should have an INFO command', () ->
    client.info( testAsync (error, reply) ->
      expect(error).toBeNull()
      expect(reply).toContain('redis_version:')
    )
    
describe 'redis-keyspace prefix for keys', () ->
  client = null
  client2 = null
  beforeEach () ->
    client = getClientWithPrefix keyspace_name
    client2 = getClientWithPrefix 'other_prefix'
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
      @client3 = getClientWithPrefix keyspace_name
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

describe 'redis-keyspace prefix in complex sort', () ->
  client = null
  client2 = null
  beforeEach () ->
    client = getClientWithPrefix keyspace_name
    client2 = getClientWithPrefix 'other_prefix'
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

describe 'redis-keyspace prefix for strings', () ->
  client = null
  client2 = null
  beforeEach () ->
    client = getClientWithPrefix keyspace_name
    client2 = getClientWithPrefix 'other_prefix'
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


describe 'redis-keyspace test cleanup', () ->
  client = null
  beforeEach () ->
    client = getClientWithPrefix keyspace_name
  afterEach () ->
    client.quit()
  
  it 'should flush the test db', () ->
    runBlock 'flushdb', (done) ->
      client.FLUSHDB( testAsync (error, reply) ->
        expect(error).toBeNull()
        expect(reply).toEqual('OK')
        done()
      )
    runBlock 'dbsize, confirms db empty', (done) ->
      client.dbsize( testAsync (error, reply) ->
        expect(error).toBeNull()
        expect(reply).toEqual(0)
        done()
      )
    



