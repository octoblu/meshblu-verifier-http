shmock = require 'shmock'
Verifier = require '../src/verifier'

describe 'Verifier', ->
  beforeEach (done) ->
    @meshblu = shmock done

  beforeEach ->
    meshbluConfig = server: 'localhost', port: @meshblu.address().port
    @sut = new Verifier {meshbluConfig, nonce: 'some-nonce'}

  afterEach (done) ->
    @meshblu.close done

  describe '-> verify', ->
    beforeEach ->
      @registerRequest = @meshblu.post('/devices')
      @whoamiRequest = @meshblu.get('/v2/whoami')
      @updateRequest = @meshblu.patch('/v2/devices/device-uuid')
      @whoamiUpdateRequest = @meshblu.get('/v2/whoami')
      @unregisterRequest = @meshblu.delete('/devices/device-uuid')

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
          .reply(200, uuid: 'device-uuid', type: 'meshblu:verifier', nonce: 'some-nonce')

        @unregisterHandler = @unregisterRequest
          .reply(204)

        @sut.verify (@error) =>
          done @error

      it 'should not error', ->
        expect(@error).not.to.exist
        expect(@registerHandler.isDone).to.be.true
        expect(@whoamiHandler.isDone).to.be.true
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

    context 'when update fails', ->
      beforeEach (done) ->
        @registerHandler = @registerRequest
          .send(type: 'meshblu:verifier')
          .reply(201, uuid: 'device-uuid')

        @whoamiHandler = @whoamiRequest
          .reply(200, uuid: 'device-uuid', type: 'meshblu:verifier')

        @updateHandler = @updateRequest
          .reply(500)

        @sut.verify (@error) =>
          done()

      it 'should error', ->
        expect(@error).to.exist
        expect(@registerHandler.isDone).to.be.true
        expect(@whoamiHandler.isDone).to.be.true
        expect(@updateHandler.isDone).to.be.true

    context 'when unregister fails', ->
      beforeEach (done) ->
        @registerHandler = @registerRequest
          .send(type: 'meshblu:verifier')
          .reply(201, uuid: 'device-uuid')

        @whoamiHandler = @whoamiRequest
          .reply(200, uuid: 'device-uuid', type: 'meshblu:verifier')

        @updateHandler = @updateRequest
          .reply(204)

        @whoamiUpdateHandler = @whoamiUpdateRequest
          .reply(200, uuid: 'device-uuid', type: 'meshblu:verifier', nonce: 'some-nonce')

        @unregisterHandler = @unregisterRequest
          .reply(500)

        @sut.verify (@error) =>
          done()

      it 'should error', ->
        expect(@error).to.exist
        expect(@registerHandler.isDone).to.be.true
        expect(@whoamiHandler.isDone).to.be.true
        expect(@updateHandler.isDone).to.be.true
        expect(@unregisterHandler.isDone).to.be.true
