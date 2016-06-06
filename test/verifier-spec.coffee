shmock = require 'shmock'
Verifier = require '../src/verifier'
enableDestroy = require 'server-destroy'

describe 'Verifier', ->
  beforeEach (done) ->
    @meshblu = shmock done
    enableDestroy @meshblu

  beforeEach (done) ->
    @meshbluStreaming = shmock done
    enableDestroy @meshbluStreaming

  beforeEach ->
    @nonce = Date.now()
    meshbluConfig = server: 'localhost', port: @meshblu.address().port, protocol: 'http'
    meshbluStreamingConfig = hostname: 'localhost', port: @meshbluStreaming.address().port, protocol: 'http'
    @sut = new Verifier {meshbluConfig, meshbluStreamingConfig, nonce: @nonce}

  afterEach (done) ->
    @meshbluStreaming.destroy done

  afterEach (done) ->
    @meshblu.destroy done

  describe '-> verify', ->
    beforeEach ->
      @registerRequest = @meshblu.post '/devices'
      @whoamiRequest = @meshblu.get '/v2/whoami'
      @updateRequest = @meshblu.patch '/v2/devices/device-uuid'
      @whoamiUpdateRequest = @meshblu.get '/v2/whoami'
      @unregisterRequest = @meshblu.delete '/devices/device-uuid'
      @subscribeRequest = @meshbluStreaming.get '/subscribe'

    context 'when everything works', ->
      beforeEach (done) ->
        @registerHandler = @registerRequest
          .send(type: 'meshblu:verifier')
          .reply(201, uuid: 'device-uuid')

        @whoamiHandler = @whoamiRequest
          .reply(200, uuid: 'device-uuid', type: 'meshblu:verifier')

        @updateHandler = @updateRequest
          .reply(204)

        @whoamiUpdateHandler = @whoamiUpdateRequest
          .reply(200, uuid: 'device-uuid', type: 'meshblu:verifier', nonce: @nonce)

        @unregisterHandler = @unregisterRequest
          .reply(204)

        @subscribeHandler = @subscribeRequest
          .send(types: ['received'])
          .reply(200, payload: @nonce)

        @sut.verify (@error) =>
          done @error

      it 'should not error', ->
        expect(@error).not.to.exist
        expect(@registerHandler.isDone).to.be.true
        expect(@whoamiHandler.isDone).to.be.true
        expect(@subscribeHandler.isDone).to.be.true
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
        expect(@registerHandler.isDone).to.be.true

    context 'when whoami fails', ->
      beforeEach (done) ->
        @registerHandler = @registerRequest
          .send(type: 'meshblu:verifier')
          .reply(201, uuid: 'device-uuid')

        @whoamiHandler = @whoamiRequest
          .reply(500)

        @sut.verify (@error) =>
          done()

      it 'should error', ->
        expect(@error).to.exist
        expect(@registerHandler.isDone).to.be.true
        expect(@whoamiHandler.isDone).to.be.true

    context 'when message fails', ->
      beforeEach (done) ->
        @registerHandler = @registerRequest
          .send(type: 'meshblu:verifier')
          .reply(201, uuid: 'device-uuid')

        @whoamiHandler = @whoamiRequest
          .reply(200, uuid: 'device-uuid', type: 'meshblu:verifier')

        @subscribeHandler = @subscribeRequest
          .reply(500)

        @sut.verify (@error) =>
          done()

      it 'should error', ->
        expect(@error).to.exist
        expect(@registerHandler.isDone).to.be.true
        expect(@whoamiHandler.isDone).to.be.true
        expect(@subscribeHandler.isDone).to.be.true

    context 'when update fails', ->
      beforeEach (done) ->
        @registerHandler = @registerRequest
          .send(type: 'meshblu:verifier')
          .reply(201, uuid: 'device-uuid')

        @whoamiHandler = @whoamiRequest
          .reply(200, uuid: 'device-uuid', type: 'meshblu:verifier')

        @subscribeHandler = @subscribeRequest
          .send(types: ['received'])
          .reply(200, payload: @nonce)

        @updateHandler = @updateRequest
          .reply(500)

        @sut.verify (@error) =>
          done()

      it 'should error', ->
        expect(@error).to.exist
        expect(@registerHandler.isDone).to.be.true
        expect(@whoamiHandler.isDone).to.be.true
        expect(@subscribeHandler.isDone).to.be.true
        expect(@updateHandler.isDone).to.be.true

    context 'when unregister fails', ->
      beforeEach (done) ->
        @registerHandler = @registerRequest
          .send(type: 'meshblu:verifier')
          .reply(201, uuid: 'device-uuid')

        @whoamiHandler = @whoamiRequest
          .reply(200, uuid: 'device-uuid', type: 'meshblu:verifier')

        @subscribeHandler = @subscribeRequest
          .send(types: ['received'])
          .reply(200, payload: @nonce)

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
        expect(@registerHandler.isDone).to.be.true
        expect(@whoamiHandler.isDone).to.be.true
        expect(@subscribeHandler.isDone).to.be.true
        expect(@updateHandler.isDone).to.be.true
        expect(@unregisterHandler.isDone).to.be.true
