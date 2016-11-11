utf8 = require 'utf8'
{EventEmitter} = require 'events'
SingleSocket = require 'single-socket'
atomHelper = require './atom-helper'
logger = require './logger'
path = require 'path'

module.exports = class Terminal extends EventEmitter
  constructor: (args) ->
    args || (args = {})

    @host = args.host
    @port = args.port
    @path = args.path
    @token = args.token

    @isConnected = false
    @hasFailed = false

    @connect()

  connect: (token) ->
    @waitForSocket = new Promise (resolve, reject) =>
      @socket = new WebSocket @url()
      console.log(@url())
      console.log(@socket)

      @socket.onopen = =>
        console.log('term:open')
        @isConnected = true
        @hasFailed = false
        @emit 'open'
        resolve()

      @socket.onmessage = (msg) =>
        console.log(msg.data)
        console.log('term:msg', {msg: msg})
        @emit 'message', utf8.decode(window.atob(msg.data))

      @socket.onclose = =>
        @isConnected = false
        @hasFailed = true
        @emit 'close'
        logger.info('term:close')

      @socket.onerror = (e) =>
        @isConnected = false
        @hasFailed = true
        @emit 'error', e
        console.log('term:error', {debug: @debugInfo(), error: e})
        reject(e)

  url: ->
    protocol = if @port == 443 then 'wss' else 'ws'
    "#{protocol}://#{@host}:#{@port}/#{@path}?token=#{@token}"

  reset: ->
    logger.info('term:reset')
    @socket.close().then =>
      @connect()
    .catch (err) =>
      @emit 'error', err

  send: (msg) ->
    logger.info('term:send', {msg: msg})
    if @isConnected
      @socket.send(msg)
    else
      if @hasFailed
        @reset()
        setTimeout =>
          @waitForSocket.then =>
            @socket.send(msg)
        , 200
      else
        @waitForSocket.then =>
          @socket.send(msg)

  debugInfo: ->
    {
      host: @host,
      port: @port,
      path: @path,
      token: @token,
      isConnected: @isConnected,
      hasFailed: @hasFailed,
      socket: @socket
    }
