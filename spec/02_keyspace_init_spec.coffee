require('./helpers')
rk = require('../index')

describe 'redis-keyspace initialization', () ->
  it 'should createClient with no extra arguments', () ->
    expect( rk.createClient()).toBeDefined()
  it 'should createClient with extra arguments', () ->
    expect( rk.createClient(6379, '127.0.0.1', {'prefix': keyspace_name})).toBeDefined()
    
