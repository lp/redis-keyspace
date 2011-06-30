rk = require('../index')
redis = require('redis')

describe('reality check', () ->
  it('should assert true when true', () ->
    expect(true).toBeTruthy()
  )
)

describe 'redis-keyspace initialization', () ->

  it 'should createClient with no extra arguments', () ->
    expect( rk.createClient('dummy')).toBeDefined()
  
  it 'should createClient with extra arguments', () ->
    expect( rk.createClient('dummy', 6379, '127.0.0.1')).toBeDefined()
  
  it 'should createKeyspace with no extra arguments', () ->
    expect( rk.createKeyspace('dummy')).toBeDefined()
  
  it 'should createKeyspace with extra arguments', () ->
    expect( rk.createKeyspace('dummy', redis.createClient())).toBeDefined()
    
  it 'should fail with createClient with wrong arguments', () ->
    expect( rk.createClient('dummy', 'noport', '127.0.0.1')).not.toBeDefined()
    expect( rk.createClient('dummy', '127.0.0.1', 6379)).not.toBeDefined()
    
  it 'should fail with createKeyspace with wrong arguments', () ->
    expect( rk.createKeyspace('dummy', 'noredis')).not.toBeDefined()

