
{request} = require 'keybase-bjson-client'
express = require 'express'
{respond,bjson_parser} = require '../../lib/main'
http = require 'http'
{prng} = require 'crypto'

#=====================================================================================

PORT = 4058
server = null

#=====================================================================================

make_url = (path) ->
  return {
    hostname : "localhost"
    port : PORT
    pathname : path
    protocol : "http:"
  }

#=======================================================================

make_obj = () ->
  obj =
    id : prng(10)
    uid : prng(12)
    foos : [10, 20, 30, prng(40) ],
    uids : [[prng(3), prng(10),[prng(4), [prng(5)]]], prng(20) ]
    bars :
      pgp_fingerprint : prng(20)
      buxes : 
        x_id : prng(4)
        y_id : prng(3)
        dog : prng(6)
      dig : 10
      blah : prng(5)
  return obj

#=======================================================================

handler = (req, res) ->
  parts = req.url.split '.'
  err = respond { res, obj : req.body, encoding : parts[-1...][0] }
  throw err if err?

#----------------------------------------

exports.init = (T,cb) ->
  app = express()
  app.set 'port', PORT
  app.use bjson_parser()
  app.post /\/test\.(json|msgpack|msgpack64)/, handler
  server = http.createServer(app)
  await server.listen PORT, defer err
  cb err

#=====================================================================================

send = (T, incoding, outcoding, cb) ->
  indata = make_obj()
  opts = 
    url : make_url "/test.#{outcoding}"
    arg :
      encoding : incoding
      data : indata
    method : "POST"
  await request opts, defer err, res, outdata
  T.no_error err
  T.equal indata, outdata, "got the right data back"
  cb()

#=====================================================================================

encodings = [ 'json', 'msgpack', 'msgpack64' ]
for i in encodings
  for j in encodings
    ((a,b) -> 
      exports["send_#{a}_#{b}"] = (T,cb) -> send T, a, b, cb
    )(i,j)

#=====================================================================================

exports.destroy = (T,cb) ->
  await server.close defer()
  cb()

#=====================================================================================


