ImportView = require './import-view'

module.exports =
  importView: null

  activate: (state) ->
    @importView = new ImportView(state.importViewState)

  deactivate: ->
    @importView.destroy()

  serialize: ->
    importViewState: @importView.serialize()
