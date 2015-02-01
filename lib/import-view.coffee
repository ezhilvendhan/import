{EditorView, View} = require 'atom'
exec = require('child_process').exec
path = require 'path'
fs = require 'fs'

module.exports =
class ImportView extends View
  @content: ->
    @div class: 'import overlay from-top padded', =>
      @div class: 'inset-panel', =>
        @div class: 'panel-heading', =>
          @span outlet: 'title'
        @div class: 'panel-body padded', =>
          @div outlet: 'form', =>
            @subview 'urlEditor', new EditorView(mini:true, placeholderText: 'Enter url to clone')
            @div class: 'pull-right', =>
              @button outlet: 'importButton', class: 'btn btn-primary', 'Clone & Import'
          @div outlet: 'progressIndicator', =>
            @span class: 'loading loading-spinner-medium'
          @div outlet: 'status'

  initialize: (serializeState) ->
    @handleEvents()
    atom.commands.add 'atom-workspace',
      'import:toggle': =>
        @toggle()
    #atom.workspaceView.command "import:toggle", => @toggle()

  # Returns an object that can be retrieved when package is activated
  serialize: ->

  # Tear down any state and detach
  destroy: ->
    @detach()

  toggle: ->
    @showForm()
    atom.views.getView(atom.workspace).appendChild(this[0])
    #atom.workspaceView.append(this)
    @urlEditor.focus()

  doImport: ->
    @showProgressIndicator()
    url = @urlEditor.getText()
    workspace = atom?.config?.settings?.core?.projectHome
    _home = process.env.HOME or process.env.HOMEPATH or process.env.USERPROFILE
    defaultWorkspace = process.env.ATOM_REPOS_HOME or
                        path.join(_home, 'github')
    workspace = defaultWorkspace if not workspace?
    projDir = /(.*\/)?(.*)/ig.exec(url).pop()?.replace(/(.git)$/, '')
    importPath = path.resolve(workspace, projDir)
    isProjImportedAlready = fs.existsSync(importPath)

    cb = (err, stdout, stderr) =>
      @showStatus()
      if err?
        @status.text 'Could not import the project'
      else
        @status.text 'The project is successfully imported'
        if @hasParent()
          @detach()
        else
          atom.workspaceView.append(this)

    if isProjImportedAlready
      exec @getAppLaunchCmd() + " #{importPath}",
        env: process.env,
        cb
    else
      exec @getCreateDirIfNotExistsAndCloneCmd(workspace, url, importPath),
        env: process.env,
        cb

  handleEvents: ->
    @importButton.on 'click', => @doImport()
    @urlEditor.on 'core:confirm', => @doImport()
    @urlEditor.on 'core:cancel', => @detach()

  showForm: ->
    @title.text "Clone & Import a Git project"
    @form.show()
    @status.hide()
    @progressIndicator.hide()

  showProgressIndicator: ->
    @form.hide()
    @status.hide()
    @progressIndicator.show()

  showStatus: ->
    @status.show()
    @progressIndicator.hide()
    @form.show()

  getCreateDirIfNotExistsAndCloneCmd: (workspace, url, importPath) ->
    platform = process.platform
    if /^win/.test platform
       return "mkdir #{importPath} && git clone #{url} #{importPath} && #{@getAppLaunchCmd()} #{importPath}"
    else
       return "mkdir -p #{workspace} && git clone #{url} #{importPath} && #{@getAppLaunchCmd()} #{importPath}"

  getAppLaunchCmd: ->
    platform = process.platform
    if platform == 'linux'
       return "atom "
    else if /^win/.test platform
       return "start atom"
    else
       return "open -a atom.app "
