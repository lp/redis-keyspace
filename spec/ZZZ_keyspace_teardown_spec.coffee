require('./helpers')

describe 'redis-keyspace test cleanup', () ->
  client = null
  beforeEach () ->
    client = getClientWithPrefixAndDB keyspace_name
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
    

