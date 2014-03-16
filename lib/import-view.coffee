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
    atom.workspaceView.command "import:toggle", => @toggle()

  # Returns an object that can be retrieved when package is activated
  serialize: ->

  # Tear down any state and detach
  destroy: ->
    @detach()

  toggle: ->
    @showForm()
    atom.workspaceView.append(this)
    @urlEditor.focus()

  doImport: ->
    @showProgressIndicator()
    url = @urlEditor.getText()
    base = atom.config.settings.core.projectHome
    base = process.env.HOME if not base?
    dir = /(.*\/)?(.*)/ig.exec(url).pop()?.replace(/(.git)$/, '')
    console.log dir, base, url
    isDirExist = fs.existsSync(path.resolve(base, dir))
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
    if isDirExist
      exec "open -a atom.app #{dir}",
        cwd: base
        env: process.env,
        cb
    else
      exec "git clone #{url} #{dir} && open -a atom.app #{dir}",
        cwd: base
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
