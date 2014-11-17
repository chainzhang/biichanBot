module.exports = (robot) ->
    robot.router.get '/bii/say', (req, res) ->
         room     = req.query.room
         text     = req.query.text
         username = req.query.username
         secret   = req.params.secret

         message = "#{text}"
         if username? then message = "@#{username} " + message

         robot.messageRoom room, message
         res.send 'OK'