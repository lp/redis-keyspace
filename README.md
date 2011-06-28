# redis-keyspace
Similar in use to Ruby's [redis-namespace](https://github.com/defunkt/redis-namespace) for node.

# Install
	npm install redis-keyspace
	or
	npm install redis redis-keyspace  # will also install the redis adapter
	or
	npm install hiredis redis redis-keyspace  # will also install the high performance redis C adapter

# Use
Use this library just as you would [node_redis](https://github.com/mranney/node_redis)
    
    redis = require("redis")
    redis_client = redis.createClient()
    redis_keyspace = require('redis-keyspace')
    client = redis_keyspace.createClient('your_keyspace', redis_client)
    
    client.set('KOO', 'DOO', (err, reply) -> console.log( 'set reply: ' + reply + " err: " + err ))
    client.get('KOO', (err, reply) -> console.log( 'get reply: ' + reply + " err: " + err ))

# Thanks
This is a CoffeeScript spinoff of ['node-redis-namespace'](https://github.com/arschles/node-redis-namespace) from ['Aaron Schlesinger'](https://github.com/arschles).
