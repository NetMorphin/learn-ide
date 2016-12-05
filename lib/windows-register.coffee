Registry = require 'winreg'


regConfig = [
  {key: '\\learn-ide', name: '', value: 'URL:Learn IDE Protocol'},
  {key: '\\learn-ide', name: 'URL Protocol', value: ''},
  {key: '\\learn-ide\\shell\\open\\command', name: '', value: process.execPath}
]


regKeys.forEach (reg) ->
  reg = new Registry({hive: Registry.HKCR, key: reg.key})

  reg.create(->
    reg.set reg.name, Registry.REG_SZ, reg.value, ->
      console.log("Registered key #{reg.key}: #{reg.name}: #{reg.value}")
  )
