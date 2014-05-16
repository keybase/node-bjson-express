
{hasBody}                = require 'type-is'
getBody                  = require 'raw-body'
bodyParser               = require 'body-parser'

{mime_types_r,mime_types,decode,decode_json_obj} = require 'keybase-bjson-core'

#===============================================================

parse_msgpack_body = ({req, res, opts, encoding}, cb) ->
  params = 
    limit    : opts.limit || '1000kb'
    length   : req.headers['content-length']
    encoding : null
  await getBody req, params, defer err, buf
  unless err?
    [err, body] = decode { buf, encoding }
    req.body = body unless err?
  cb err

#===============================================================

exports.msgpack_parser = msgpack_parser = (opts = {}) -> (req, res, next) ->
  err = null
  go = false

  ct = req.headers['content-type']

  if hasBody(req) and (encoding = mime_types_r[ct])? and (encoding in ['msgpack', 'msgpack64'])
    await parse_msgpack_body {req, res, opts, encoding}, defer err

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
