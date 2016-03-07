async = require 'async'
MeshbluHttp = require 'meshblu-http'

class Verifier
  constructor: ({meshbluConfig, @nonce}) ->
    @nonce ?= Date.now()
    @meshbluHttp = new MeshbluHttp meshbluConfig

  _register: (callback) =>
    @meshbluHttp.register type: 'meshblu:verifier', (error, @device) =>
      return callback error if error?
      @meshbluHttp.uuid = @device.uuid
      @meshbluHttp.token = @device.token
      callback()

  _whoami: (callback) =>
    @meshbluHttp.whoami callback

  _update: (callback) =>
    return callback() unless @device?

    params =
      uuid: @meshbluHttp.uuid
      nonce: @nonce

    @meshbluHttp.update @meshbluHttp.uuid, params, (error) =>
      return callback error if error?
      @meshbluHttp.whoami (error, data) =>
        return callback error if error?
        return callback new Error 'update failed' unless data?.nonce == @nonce
        callback()

  _unregister: (callback) =>
    return callback() unless @device?
    @meshbluHttp.unregister @device, callback

  verify: (callback) =>
    async.series [
      @_register
      @_whoami
      @_update
      @_unregister
    ], callback

module.exports = Verifier
