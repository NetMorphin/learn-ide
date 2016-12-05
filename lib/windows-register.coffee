ProtocolRegistration = require './protocol-registration'

new ProtocolRegistration('\\learn-ide',
  [
    {key: '', name: '', 'URL:Learn IDE Protocol'},
    {key: '', name: 'URL Protocol', value: ''},
    {key: 'shell\\open\\command', name: '', value: process.execPath}
  ]
).register =>
  console.log('registered key')
