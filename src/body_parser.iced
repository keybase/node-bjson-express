
{hasBody}                = require 'type-is'
getBody                  = require 'raw-body'
bodyParser               = require 'body-parser'

{mime_types,decode,decode_json_obj} = require 'keybase-jbson-core'

#===============================================================

parse_msgpack_body = ({req, res, opts }, cb) ->
  params = 
    limit    : opts.limit || '1000kb'
    length   : req.headers['content-length']
    encoding : if opts.base64 then 'base64' else 'binary'
  await getBody req, params, defer err, buf
  unless err?
    try
      req.body = decode { buf, mpack : true } 
    catch e
      err = e
  cb err

#===============================================================

exports.msgpack_parser = (opts = {}) -> (req, res, next) ->
  err = null
  go = false

  ct = req.headers['content-type']

  if not hasBody(req) then # noop
  else if ct is mime_types.msgpack   then go = true
  else if ct is mime_types.msgpack64 then opts.base64 = go = true
  
  if go then await parse_msgpack_body {req, res, opts}, defer err

  next err

#===============================================================

exports.json_bufferizer = json_bufferizer = (opts = {}) -> (req, res, next) ->

  # These are the conditions that the json() parse of 
  # body-parser middleware sets
  if req._body and req.body and typeof(req.body) is 'object'
    req.body = decode_json_obj req.body 
  next()

#===============================================================

exports.bjson_parser = bjson_parser = (opts = {}) ->
  hooks = [
    bodyParser.json(opts)
    json_bufferizer(opts)
    msgpack_parser(opts) 
  ]
  (req, res, cb) ->
    err = null
    for h in hooks when not err?
      await h req, res, defer err
    cb err

#===============================================================
