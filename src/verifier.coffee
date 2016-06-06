async       = require 'async'
MeshbluHttp = require 'meshblu-http'
request     = require 'request'

class Verifier
  constructor: ({meshbluConfig, @meshbluStreamingConfig, @nonce}) ->
    @nonce ?= Date.now()
    @meshblu = new MeshbluHttp meshbluConfig

  _message: (callback) =>
    url = "#{@meshbluStreamingConfig.protocol}://#{@meshbluStreamingConfig.hostname}:#{@meshbluStreamingConfig.port}/subscribe"
    options =
      auth:
        username: @meshblu.uuid
        password: @meshblu.token
      json:
        types: ['received']

    response = request.get url, options
    response.on 'data', (message) =>
      response.abort()
      message = JSON.parse message.toString()
      return callback new Error 'wrong message received' unless message?.payload == @nonce
      callback()
    response.on 'response', (response) =>
      return callback new Error 'failed' if response.statusCode > 499

    setTimeout =>
      message =
        devices: [@meshblu.uuid]
        payload: @nonce

      @meshblu.message message
    , 500

  _register: (callback) =>
    @meshblu.register type: 'meshblu:verifier', (error, @device) =>
      return callback error if error?
      @meshblu.uuid = @device.uuid
      @meshblu.token = @device.token
      callback()

  _whoami: (callback) =>
    @meshblu.whoami callback

  _update: (callback) =>
    return callback() unless @device?

    params =
      uuid: @meshblu.uuid
      nonce: @nonce

    @meshblu.update @meshblu.uuid, params, (error) =>
      return callback error if error?
      @meshblu.whoami (error, data) =>
        return callback error if error?
        return callback new Error 'update failed' unless data?.nonce == @nonce
        callback()

  _unregister: (callback) =>
    return callback() unless @device?
    @meshblu.unregister @device, callback

  verify: (callback) =>
    async.series [
      @_register
      @_whoami
      @_message
      @_update
      @_unregister
    ], callback

module.exports = Verifier
