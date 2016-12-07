async       = require 'async'
debug       = require('debug')('meshblu-verifier-http:verifier')
_           = require 'lodash'
MeshbluHttp = require 'meshblu-http'

class Verifier
  constructor: ({@meshbluConfig, @nonce}) ->
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

    @meshblu.message devices: [@meshbluConfig.uuid], payload: @nonce, (error) =>
      return callback @_injectStep error, 'message' if error?
      return callback()

  _register: (callback) =>
    debug '_register'
    @meshblu.register type: 'meshblu:verifier', (error, @device) =>
      return callback @_injectStep error, 'register' if error?
      @meshbluConfig = _.defaults _.pick(@device, 'uuid', 'token'), @meshbluConfig
      @meshblu = new MeshbluHttp @meshbluConfig
      callback()

  _unregister: (callback) =>
    debug '_unregister'
    return callback(@_injectStep(new Error('@device is missing'), 'unregister')) unless @device?

    @meshblu.unregister @device, (error) =>
      return callback @_injectStep error, 'unregister' if error?
      callback()

  _update: (callback) =>
    return callback(@_injectStep(new Error('@device is missing'), 'update')) unless @device?

    params =
      uuid: @meshbluConfig.uuid
      nonce: @nonce

    @meshblu.update @meshbluConfig.uuid, params, (error) =>
      return callback @_injectStep error, 'update' if error?
      @meshblu.whoami (error, data) =>
        return callback @_injectStep error, 'update' if error?
        return callback @_injectStep new Error('update failed'), 'update' unless data?.nonce == @nonce
        callback()

  _whoami: (callback) =>
    debug '_whoami'
    @meshblu.whoami (error) =>
      return callback @_injectStep error, 'whoami' if error?
      callback()

  _injectStep: (error, step) =>
    error.step = step
    return error

module.exports = Verifier
