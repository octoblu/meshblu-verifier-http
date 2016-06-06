_           = require 'lodash'
commander   = require 'commander'
debug       = require('debug')('meshblu-verifier-http:command')
packageJSON = require './package.json'
Verifier    = require './src/verifier'
MeshbluConfig = require 'meshblu-config'

class Command
  parseOptions: =>
    commander
      .version packageJSON.version
      .parse process.argv

  run: =>
    process.on 'uncaughtException', @die
    @parseOptions()
    timeoutSeconds = 30
    timeoutSeconds = parseInt(process.env.TIMEOUT_SECONDS) if process.env.TIMEOUT_SECONDS
    setTimeout @timeoutAndDie, timeoutSeconds * 1000
    meshbluConfig = new MeshbluConfig().toJSON()
    meshbluStreamingConfig = new MeshbluConfig({}, {
      filename: 'meshblu-streaming.json'
      server_env_name: 'MESHBLU_STREAMING_HOSTNAME'
      hostname_env_name: 'MESHBLU_STREAMING_HOSTNAME'
      port_env_name: 'MESHBLU_STREAMING_PORT'
      protocol_env_name: 'MESHBLU_STREAMING_PROTOCOL'
    }).toJSON()
    verifier = new Verifier {meshbluConfig, meshbluStreamingConfig}
    verifier.verify (error) =>
      @die error if error?
      console.log 'meshblu-verifier-http successful'
      process.exit 0

  die: (error) =>
    return process.exit(0) unless error?
    console.log 'meshblu-verifier-http error'
    console.error error.stack
    process.exit 1

  timeoutAndDie: =>
    console.log 'meshblu-verifier-http timeout'
    @die new Error 'Timeout Exceeded'

commandWork = new Command()
commandWork.run()
