module.exports = (robot) ->
    robot.router.get '/bii/say', (req, res) ->
         channel  = req.query.channel
         text     = req.query.text
         username = req.query.username
         secret   = req.params.secret

         message = "#{text}"
         if username? then message = "@#{username} " + message

         robot.logger.info "Say #{message} in ##{channel}"
         robot.messageRoom '#'+channel, message
         res.send 'OK'