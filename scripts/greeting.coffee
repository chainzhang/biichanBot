module.exports = (robot) ->
    robot.respond /(.*)は(.*)の誕生日/i, (msg)->
        the_day = msg.match[1]
        the_target = msg.match[2]
        msg.send the_day + "なんだ。おめでとう〜"