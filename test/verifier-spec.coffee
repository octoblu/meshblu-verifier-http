shmock = require 'shmock'
Verifier = require '../src/verifier'

describe 'Verifier', ->
  beforeEach ->
    @meshblu = shmock 0xd00d

  afterEach (done) ->
    @meshblu.close => done()

  describe '-> verify', ->
    context 'when everything works', ->
      beforeEach ->
        meshbluConfig = server: 'localhost', port: 0xd00d
        @sut = new Verifier {meshbluConfig}

      beforeEach (done) ->
        @registerHandler = @meshblu.post('/devices')
          .send(type: 'meshblu:verifier')
          .reply(201, uuid: 'device-uuid')

        @whoamiHandler = @meshblu.get('/v2/whoami')
          .reply(200, uuid: 'device-uuid', type: 'meshblu:verifier')

        @unregisterHandler = @meshblu.delete('/devices/device-uuid')
          .reply(204)

        @sut.verify (@error) =>
          done @error

      it 'should not error', ->
        expect(@error).not.to.exist
        expect(@registerHandler.isDone).to.be.true
        expect(@whoamiHandler.isDone).to.be.true
        expect(@unregisterHandler.isDone).to.be.true

    context 'when register fails', ->
      beforeEach ->
        meshbluConfig = server: 'localhost', port: 0xd00d
        @sut = new Verifier {meshbluConfig}

      beforeEach (done) ->
        @registerHandler = @meshblu.post('/devices')
          .send(type: 'meshblu:verifier')
          .reply(500)

        @sut.verify (@error) =>
          done()

      it 'should error', ->
        expect(@error).to.exist
        expect(@registerHandler.isDone).to.be.true

    context 'when whoami fails', ->
      beforeEach ->
        meshbluConfig = server: 'localhost', port: 0xd00d
        @sut = new Verifier {meshbluConfig}

      beforeEach (done) ->
        @registerHandler = @meshblu.post('/devices')
          .send(type: 'meshblu:verifier')
          .reply(201, uuid: 'device-uuid')

        @whoamiHandler = @meshblu.get('/v2/whoami')
          .reply(500)

        @sut.verify (@error) =>
          done()

      it 'should error', ->
        expect(@error).to.exist
        expect(@registerHandler.isDone).to.be.true
        expect(@whoamiHandler.isDone).to.be.true

    context 'when unregister fails', ->
      beforeEach ->
        meshbluConfig = server: 'localhost', port: 0xd00d
        @sut = new Verifier {meshbluConfig}

      beforeEach (done) ->
        @registerHandler = @meshblu.post('/devices')
          .send(type: 'meshblu:verifier')
          .reply(201, uuid: 'device-uuid')

        @whoamiHandler = @meshblu.get('/v2/whoami')
          .reply(200, uuid: 'device-uuid', type: 'meshblu:verifier')

        @unregisterHandler = @meshblu.delete('/devices/device-uuid')
          .reply(500)

        @sut.verify (@error) =>
          done()

      it 'should error', ->
        expect(@error).to.exist
        expect(@registerHandler.isDone).to.be.true
        expect(@whoamiHandler.isDone).to.be.true
        expect(@unregisterHandler.isDone).to.be.true
