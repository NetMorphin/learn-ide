{CompositeDisposable} = require 'atom'
Terminal = require './models/terminal'
SyncedFS = require './models/synced-fs'
TerminalView = require './views/terminal'
SyncedFSView = require './views/synced-fs'
{EventEmitter} = require 'events'
ipc = require 'ipc'
xhr = require 'xhr'
imgur = require 'imgur'
clipboard = require 'clipboard-js'
screenshot = require 'electron-screenshot'
LearnUpdater = require './models/learn-updater'

module.exports =
  config:
    oauthToken:
      type: 'string'
      title: 'OAuth Token'
      description: 'Your learn.co oauth token'
      default: "Paste your learn.co oauth token here"

  termViewState: null
  fsViewState: null
  subscriptions: null

  activate: (state) ->
    @oauthToken = atom.config.get('integrated-learn-environment.oauthToken')
    openPath = atom.blobStore.get('learnOpenUrl', 'learn-open-url-key')
    atom.blobStore.delete('learnOpenUrl')
    atom.blobStore.save()

    isTerminalWindow = atom.isTerminalWindow

# DNS GSLB
    @term = new Terminal("ws://ide.learn.co:4463?token=" + @oauthToken, isTerminalWindow)
# HA Proxy by URL Path
#    @term = new Terminal("wss://ile.learn.co/term?token=" + @oauthToken, isTerminalWindow)
    @termView = new TerminalView(state, @term, openPath, isTerminalWindow)

    if isTerminalWindow
      document.getElementsByClassName('terminal-view-resize-handle')[0].setAttribute('style', 'display:none;')
      document.getElementsByClassName('inset-panel')[0].setAttribute('style', 'display:none;')
      document.getElementsByClassName('learn-terminal')[0].style.height = '448px'
      workspaceView = atom.views.getView(atom.workspace)
      atom.commands.dispatch(workspaceView, 'tree-view:toggle')

# DNS GSLB
    @fs = new SyncedFS("ws://ide.learn.co:4464?token=" + @oauthToken, isTerminalWindow)
# HA Proxy by URL Path
#    @fs = new SyncedFS("wss://ile.learn.co/fs?token=" + @oauthToken, isTerminalWindow)
    @fsViewEmitter = new EventEmitter
    @fsView = new SyncedFSView(state, @fs, @fsViewEmitter, isTerminalWindow)

    @sendScreenshot = (token) ->
     # request = new xhr({
     #   method: "POST",
     #   url: "https://api.imgur.com/3/upload",
     #   body: JSON.stringify(getBase64Image(image)),
     #   headers: {'Authorization': 'Client-ID d620062b90324ea'}
     # }, (err, resp, body) -> console.log(body))
      imgur.setClientId('d620062b90324ea') 
      imgur.uploadFile('/Users/devin/Desktop/foo.png').then((json) ->
        console.log(json.data.link)
        clipboard.copy(json.data.link)
        notif = new Notification "Screenshot",
          body: json.data.link
        notif.onclick = ->
          notif.close()
        console.log("Screenshot successful: " + token)
        return
      ).catch (err) ->
        console.error err.message
        return

    @subscriptions = new CompositeDisposable
    @subscriptions.add atom.commands.add 'atom-workspace', 'integrated-learn-environment:screenshot': =>
      screenshot(filename:"/Users/devin/Desktop/foo.png", @sendScreenshot(@oauthToken))
    @subscriptions.add atom.commands.add 'atom-workspace', 'integrated-learn-environment:toggleTerminal': =>
      @termView.toggle()
    @subscriptions.add atom.commands.add 'atom-workspace', 'integrated-learn-environment:reset': =>
      @term.term.write('\n\rReconnecting...\r')
      ipc.send 'reset-connection'
      ipc.send 'connection-state-request'
    @subscriptions.add atom.commands.add 'atom-workspace', 'application:update-ile': =>
      updater = new LearnUpdater
      updater.checkForUpdate()

    @passingIcon = 'http://i.imgbox.com/pAjW8tY1.png'
    @failingIcon = 'http://i.imgbox.com/vVZZG1Gx.png'

    ipc.send 'register-for-notifications', @oauthToken

    ipc.on 'remote-log', (msg) ->
      console.log(msg)

    ipc.on 'new-notification', (data) =>
      icon = if data.passing == 'true' then @passingIcon else @failingIcon

      notif = new Notification data.displayTitle,
        body: data.message
        icon: icon

      notif.onclick = ->
        notif.close()

    ipc.on 'in-app-notification', (notifData) =>
      atom.notifications['add' + notifData.type.charAt(0).toUpperCase() + notifData.type.slice(1)] notifData.message, {detail: notifData.detail, dismissable: notifData.dismissable}

    @fsViewEmitter.on 'toggleTerminal', (focus) =>
      @termView.toggle(focus)

    autoUpdater = new LearnUpdater(true)
    autoUpdater.checkForUpdate()

  deactivate: ->
    @termView = null
    @fsView = null
    @subscriptions.dispose()

    ipc.send 'deactivate-listener'

  consumeStatusBar: (statusBar) ->
    @statusBarTile = statusBar.addRightTile(item: @fsView, priority: 5000)

  serialize: ->
    termViewState: @termView.serialize()
    fsViewState: @fsView.serialize()
