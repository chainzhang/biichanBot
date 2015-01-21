module.exports = (robot) ->
    robot.router.get '/bii/say', (req, res) ->
         envelope = {}
         channel  = req.query.channel || 'random'
         text     = req.query.text
         username = req.query.username
         secret   = req.params.secret

         message = "#{text}"
         envelope.room = "#{channel}"

         if username? then message = "@#{username} " + message

         robot.logger.info "Say #{message} in ##{channel}"
         robot.send envelope, message
         res.send('OK')