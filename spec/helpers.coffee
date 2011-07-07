rk = require('../index')

global.keyspace_name = 'test_ks'

global.getClientWithPrefixAndDB = (prefix,db_num=15) ->
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

global.testAsync = (test) ->
  (err, ret) ->
    test(err, ret)
    
global.testError = () ->
  (err, ret) ->
    if err?
      throw 'BAILING OUT: ' + err

global.runBlock = (name, func) ->
  complete = false
  completed = () -> complete
  done = () -> complete = true
  runs () ->
    console.log "\n-> " + name
    func(done)
  waitsFor completed
  
global.xrunBlock = (name, func) ->
  runs () ->
    console.log "\nxSKIP< " + name + " >"