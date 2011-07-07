require('./helpers')

describe 'decent test environment', () ->
  client = null
  beforeEach () ->
    client = getClientWithPrefixAndDB keyspace_name
  afterEach () ->
    client.quit()
  it 'should not have any keys inside db 15', () ->
    runBlock 'keys * in db 15 == 0', (done) ->
      client.keys('*', testAsync (error, reply) ->
        expect(error).toBeNull()
        expect(reply.length).toEqual(0)
        done()
      )