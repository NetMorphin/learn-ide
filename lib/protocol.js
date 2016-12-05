protocol = require('register-protocol-win32')

protocol.install('learn-ide', process.execPath + ' "%1"')
	.then(function() {
		console.log('succes')
	}).catch(function(err) {
		console.log(err)
	})