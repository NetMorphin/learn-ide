ProtocolRegistration = require './protocol-registration'

new ProtocolRegistration('\\learn-ide',
  [
    {name: '', 'URL:Learn IDE Protocol'},
    {name: 'URL Protocol', value: ''},
    {key: 'shell\\open\\command', name: '', value: process.execPath}
  ]
).register =>
  console.log('registered key')
