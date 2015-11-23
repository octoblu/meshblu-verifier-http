async = require 'async'
MeshbluHttp = require 'meshblu-http'

class Verifier

  constructor: ({meshbluConfig}) ->
    @meshbluHttp = new MeshbluHttp meshbluConfig

  _register: (callback) =>
    @meshbluHttp.register type: 'meshblu:verifier', (error, @device) =>
      return callback error if error?
      @meshbluHttp.uuid = @device.uuid
      @meshbluHttp.token = @device.token
      callback()

  _whoami: (callback) =>
    @meshbluHttp.whoami callback

  _unregister: (callback) =>
    return callback() unless @device?
    @meshbluHttp.unregister @device, callback

  verify: (callback) =>
    async.series [
      @_register
      @_whoami
      @_unregister
    ], callback

module.exports = Verifier
