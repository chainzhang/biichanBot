jQuery = require "jquery"
j = jQuery

module.exports = (robot) ->
  robot.router.get '/bii/befool/publish', (req, res) ->

    res.send 'OK'