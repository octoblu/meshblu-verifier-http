{afterEach, beforeEach, context, describe, it} = global
{expect} = require 'chai'

shmock = require 'shmock'
Verifier = require '../src/verifier'
enableDestroy = require 'server-destroy'

describe 'Verifier', ->
  beforeEach 'start Meshblu', (done) ->
    @meshblu = shmock done
    enableDestroy @meshblu

  beforeEach 'instantiate Verifier', ->
    @nonce = Date.now()
    meshbluConfig = hostname: 'localhost', port: @meshblu.address().port, protocol: 'http'
    @sut = new Verifier {meshbluConfig, nonce: @nonce}

  afterEach 'destroy Meshblu', (done) ->
    @meshblu.destroy done

  describe '-> verify', ->
    beforeEach ->
      @registerRequest = @meshblu.post '/devices'
      @messageRequest = @meshblu.post '/messages'
      @whoamiRequest = @meshblu.get '/v2/whoami'
      @updateRequest = @meshblu.patch '/v2/devices/device-uuid'
      @whoamiUpdateRequest = @meshblu.get '/v2/whoami'
      @unregisterRequest = @meshblu.delete '/devices/device-uuid'

    context 'when everything works', ->
      beforeEach 'create handlers', (done) ->
        @registerHandler = @registerRequest
          .send(type: 'meshblu:verifier')
          .reply(201, uuid: 'device-uuid', token: 'device-token')

        @whoamiHandler = @whoamiRequest
          .reply(200, uuid: 'device-uuid', type: 'meshblu:verifier')

        @messageHandler = @messageRequest
          .send devices: ['device-uuid'], payload: @nonce
          .reply 204

        @updateHandler = @updateRequest
          .reply(204)

        @whoamiUpdateHandler = @whoamiUpdateRequest
          .reply(200, uuid: 'device-uuid', type: 'meshblu:verifier', nonce: @nonce)

        @unregisterHandler = @unregisterRequest
          .reply(204)

        @sut.verify (@error) =>
          done @error

      it 'should not error', ->
        expect(@error).not.to.exist
        expect(@registerHandler.isDone).to.be.true
        expect(@whoamiHandler.isDone).to.be.true
        expect(@messageHandler.isDone).to.be.true
        expect(@updateHandler.isDone).to.be.true
        expect(@whoamiUpdateHandler.isDone).to.be.true
        expect(@unregisterHandler.isDone).to.be.true

    context 'when register fails', ->
      beforeEach (done) ->
        @registerHandler = @registerRequest
          .send(type: 'meshblu:verifier')
          .reply(500)

        @sut.verify (@error) =>
          done()

      it 'should error', ->
        expect(@error).to.exist
        expect(@error.step).to.deep.equal "register"
        expect(@registerHandler.isDone).to.be.true

    context 'when whoami fails', ->
      beforeEach (done) ->
        @registerHandler = @registerRequest
          .send(type: 'meshblu:verifier')
          .reply(201, uuid: 'device-uuid', token: 'device-token')

        @whoamiHandler = @whoamiRequest
          .reply(500)

        @sut.verify (@error) =>
          done()

      it 'should error', ->
        expect(@error).to.exist
        expect(@error.step).to.deep.equal "whoami"
        expect(@registerHandler.isDone).to.be.true
        expect(@whoamiHandler.isDone).to.be.true

    context 'when message fails', ->
      beforeEach (done) ->
        @registerHandler = @registerRequest
          .send(type: 'meshblu:verifier')
          .reply(201, uuid: 'device-uuid', token: 'device-token')

        @whoamiHandler = @whoamiRequest
          .reply(200, uuid: 'device-uuid', type: 'meshblu:verifier')

        @messageHandler = @messageRequest
          .send devices: ['device-uuid'], payload: @nonce
          .reply 504

        @sut.verify (@error) =>
          done()

      it 'should error', ->
        expect(@error).to.exist
        expect(@error.step).to.deep.equal "message"
        expect(@registerHandler.isDone).to.be.true
        expect(@whoamiHandler.isDone).to.be.true
        expect(@messageHandler.isDone).to.be.true

    context 'when update fails', ->
      beforeEach (done) ->
        @registerHandler = @registerRequest
          .send(type: 'meshblu:verifier')
          .reply(201, uuid: 'device-uuid', token: 'device-token')

        @whoamiHandler = @whoamiRequest
          .reply(200, uuid: 'device-uuid', type: 'meshblu:verifier')

        @messageHandler = @messageRequest
          .send devices: ['device-uuid'], payload: @nonce
          .reply 204

        @updateHandler = @updateRequest
          .reply(500)

        @sut.verify (@error) =>
          done()

      it 'should error', ->
        expect(@error).to.exist
        expect(@error.step).to.deep.equal "update"
        expect(@registerHandler.isDone).to.be.true
        expect(@whoamiHandler.isDone).to.be.true
        expect(@messageHandler.isDone).to.be.true
        expect(@updateHandler.isDone).to.be.true

    context 'when unregister fails', ->
      beforeEach (done) ->
        @registerHandler = @registerRequest
          .send(type: 'meshblu:verifier')
          .reply(201, uuid: 'device-uuid', token: 'device-token')

        @whoamiHandler = @whoamiRequest
          .reply(200, uuid: 'device-uuid', type: 'meshblu:verifier')

        @messageHandler = @messageRequest
          .send devices: ['device-uuid'], payload: @nonce
          .reply 204

        @updateHandler = @updateRequest
          .reply(204)

        @whoamiUpdateHandler = @whoamiUpdateRequest
          .reply(200, uuid: 'device-uuid', type: 'meshblu:verifier', nonce: @nonce)

        @unregisterHandler = @unregisterRequest
          .reply(500)

        @sut.verify (@error) =>
          done()

      it 'should error', ->
        expect(@error).to.exist
        expect(@error.step).to.deep.equal "unregister"
        expect(@registerHandler.isDone).to.be.true
        expect(@whoamiHandler.isDone).to.be.true
        expect(@messageHandler.isDone).to.be.true
        expect(@updateHandler.isDone).to.be.true
        expect(@unregisterHandler.isDone).to.be.true
