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
  afterEach () ->
    client.quit()
    client2.quit()
    
  it 'should work with keys in different keyspaces', () ->
    runBlock 'set in keyspace A', (done) ->
      client.set('someKey', 'someValue', testAsync (error, reply) ->
        expect(error).toBeNull()
        expect(reply).toEqual('OK')
        done()
      )
    runBlock 'set in keyspace B', (done) ->
      client2.set('someKey', 'otherValue', testAsync (error, reply) ->
        expect(error).toBeNull()
        expect(reply).toEqual('OK')
        done()
      )
    runBlock 'get in keyspace A', (done) ->
      client.get('someKey', testAsync (error, reply) ->
        expect(error).toBeNull()
        expect(reply).toEqual('someValue')
        done()
      )
    runBlock 'get in keyspace B', (done) ->
      client2.get('someKey', testAsync (error, reply) ->
        expect(error).toBeNull()
        expect(reply).toEqual('otherValue')
        done()
      )
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
    runBlock 'setnx fails in keyspace B', (done) ->
      client2.setnx('renamedKey','newValue', testAsync (error, reply) ->
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
    runBlock 'append to existing key in keyspace B', (done) ->
      client2.append('newKey', "more", testAsync (error, reply) ->
        expect(error).toBeNull()
        expect(reply).toEqual(12)
        done()
      )
    runBlock 'append to new key in keyspace A', (done) ->
      client.append('newKey', "more", testAsync (error, reply) ->
        expect(error).toBeNull()
        expect(reply).toEqual(4)
        done()
      )
    runBlock 'confirms appended key exist in keyspace B', (done) ->
      client2.get('newKey', testAsync (error, reply) ->
        expect(error).toBeNull()
        expect(reply).toEqual('newValuemore')
        done()
      )
    runBlock 'getrange from keyspace A', (done) ->
      client.getrange('newKey', 0, 1, testAsync (error, reply) ->
        expect(error).toBeNull()
        expect(reply).toEqual('mo')
        done()
      )
    runBlock 'getrange from keyspace B', (done) ->
      client2.getrange('newKey', 1, 2, testAsync (error, reply) ->
        expect(error).toBeNull()
        expect(reply).toEqual('ew')
        done()
      )
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
    



