async       = require 'async'
debug       = require('debug')('meshblu-verifier-http:verifier')
_           = require 'lodash'
MeshbluHttp = require 'meshblu-http'
request     = require 'request'
url         = require 'url'

class Verifier
  constructor: ({@meshbluConfig, @meshbluStreamingConfig, @nonce}) ->
    @nonce ?= Date.now()
    @meshblu = new MeshbluHttp @meshbluConfig

  verify: (callback) =>
    async.series [
      @_register
      @_whoami
      @_message
      @_update
      @_unregister
    ], callback

  _message: (callback) =>
    debug '_message'
    {protocol, hostname, port} = @meshbluStreamingConfig
    uri = url.format {protocol, hostname, port, pathname: '/subscribe'}
    options =
      auth:
        username: @meshbluConfig.uuid
        password: @meshbluConfig.token
      json:
        types: ['received']

    response = request.get uri, options
    response.on 'data', (message) =>
      response.abort()
      message = JSON.parse message.toString()
      return callback new Error 'wrong message received' unless message?.payload == @nonce
      callback()
    response.on 'response', (response) =>
      return callback new Error 'failed' if response.statusCode > 499

    setTimeout =>
      message =
        devices: [@meshbluConfig.uuid]
        payload: @nonce

      @meshblu.message message
    , 500

  _register: (callback) =>
    debug '_register'
    @meshblu.register type: 'meshblu:verifier', (error, @device) =>
      return callback error if error?
      @meshbluConfig = _.defaults _.pick(@device, 'uuid', 'token'), @meshbluConfig
      @meshblu = new MeshbluHttp @meshbluConfig
      callback()

  _unregister: (callback) =>
    debug '_unregister'
    return callback() unless @device?
    @meshblu.unregister @device, callback

  _update: (callback) =>
    debug '_update'
    return callback() unless @device?

    params =
      uuid: @meshbluConfig.uuid
      nonce: @nonce

    @meshblu.update @meshbluConfig.uuid, params, (error) =>
      return callback error if error?
      @meshblu.whoami (error, data) =>
        return callback error if error?
        return callback new Error 'update failed' unless data?.nonce == @nonce
        callback()

  _whoami: (callback) =>
    debug '_whoami'
    @meshblu.whoami callback

module.exports = Verifier
