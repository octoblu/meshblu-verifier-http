_           = require 'lodash'
commander   = require 'commander'
debug       = require('debug')('meshblu-verifier-http:command')
packageJSON = require './package.json'

class Command
  parseInt: (str) =>
    parseInt str

  parseOptions: =>
    commander
      .version packageJSON.version
      # .option '-t, --timeout <45>', 'seconds to wait for a next job.', @parseInt, 45
      .parse process.argv

    # {@namespace,@singleRun,@timeout} = commander

  run: =>
    @parseOptions()

  die: (error) =>
    return process.exit(0) unless error?
    console.error error.stack
    process.exit 1

commandWork = new Command()
commandWork.run()
