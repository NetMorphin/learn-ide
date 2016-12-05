Registry = require 'winreg'

reg = new Registry({hive: Registry.HKCR, key: '\\learn-ide'})

reg.create(->
  reg.set 'test', Registry.REG_SZ, 'wutang', ->
    console.log('registered')
)
