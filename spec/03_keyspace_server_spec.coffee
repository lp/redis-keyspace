require('./helpers')

describe 'redis-keyspace with redis server commands', () ->
  client = null
  beforeEach () ->
    client = getClientWithPrefixAndDB keyspace_name
  afterEach () ->
    client.quit()
  it 'should have an INFO command', () ->
    client.info( testAsync (error, reply) ->
      expect(error).toBeNull()
      expect(reply).toContain('redis_version:')
    )