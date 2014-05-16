
{to_content_type_and_body} = require 'keybase-bjson-core'

#===================================================================================================

exports.respond = ({res, obj, encoding, code}) ->
  [err, ct, body] = to_content_type_and_body { encoding, obj }
  unless err?
    res.set { 'Content-Type' : ct }
    code or= 200
    res.send code, body
  return err

#===================================================================================================
