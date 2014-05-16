
mods = [
  require('./body_parser')
  require('./respond')
]
for mod in mods
  for k,v of mod
    exports[k] = v
