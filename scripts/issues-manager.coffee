jsdom = require 'jsdom'
$ = require('jquery')(jsdom.jsdom().parentWindow)

fixed_size = (str, size) ->
    remaind = size - str.length
    if remaind > 0
        while remaind -= 1
            str += " "
        str

module.exports = (robot) ->
    robot.router.post '/bii/hear/b3m_repos', (req, res) ->
        action = req.body.action || req.query.action
        content = req.body.pull_request.title + "\n" + req.body.pull_request.body || req.query.body
        merged = req.body.pull_request.merged || req.query.merged
        if (not action?) or (action isnt "closed") or (not merged)
            return res.send 'OK, but I\'m not interested about that. ^ ^;'
        robot.logger.info "B3M pull request"
        matched = content.match(/(http:\/\/redm04\.maql\.co\.jp\/.*)/g)
        if not matched
            return res.send 'OK, but I\'m not interested about that. ^ ^;'
        mgr = new IssueManager(robot)
        count = 0
        for ticket in matched
            if mgr.is_assigned(ticket)
                mgr.solve_issue(ticket)
                count++
        if count > 0 then robot.emit "b3m_pull_req_merged", {solved: matched}
        res.send 'OK, I would check it out. ^ ^'

    robot.on "b3m_pull_req_merged" , (data) ->
        solved = []
        mgr = new IssueManager(robot)
        all_solved = mgr.all_solved_issues()
        user = all_solved[data.solved[0]].user
        robot.messageRoom '#B3M', '@' + user + ' ' + data.solved.join('、') + ' 関連のプルリクがマージされましたので、解決っていうことですね。'


    robot.respond /(.*)を?(やる|やります|対応中?)/i, (msg) ->
        mgr = new IssueManager(robot)
        user = msg.message.user || {'name':'demo'}
        ticket = msg.match[1].replace('を', '').trim()
        if not mgr.valid_ticket(ticket) then return

        tag = mgr.get_tag(ticket)
        if not tag
            msg.reply 'それって何のチケット？'
            return
        solved = mgr.is_solved(ticket)
        if solved
            msg.reply "そのチケットは@#{solved.user}が#{solved.solved_time}に対応しました。"
            return
        assigned = mgr.is_assigned(ticket)
        if assigned
            msg.reply "そのチケットは#{assigned.user}が対応してますよ。"
            return

        issue_obj = {
            'user' : user.name,
            'issue': ticket,
            'tag'  : tag
        }
        mgr.assign_issue_to(issue_obj, user)
        msg.reply "はい、#{tag}のチケットですね、頑張って下さい！"

    robot.respond /(.*)(を?)(解決|おけ|オケ|OK|対応済み|完了|やり直し|やり直す|やり直します)ー?/i, (msg) ->
        mgr = new IssueManager(robot)
        ticket = msg.match[1].replace('を', '').trim()
        if not mgr.valid_ticket(ticket) then return
        command = msg.match[3].replace(/(　)/i, '').trim()
        if command in ['解決', 'おけ', 'オケ', 'OK', '対応済み', '完了']
            if not mgr.is_assigned(ticket)
                msg.reply "そのチケットに対応している人はいませんよ。"
                return
            mgr.solve_issue(ticket)
            msg.reply "お疲れ様でした〜"
        if command in ['やり直し', 'やり直す', 'やり直します']
            if not mgr.is_solved(ticket)
                msg.reply "そのチケットはまだ完了していません。"
                return
            mgr.reset_solved_issue(ticket)
            msg.reply "あらあら〜"

    robot.respond /(チケット|ticket|tickets)(.*)/i, (msg) ->
        mgr = new IssueManager(robot)
        if not msg.message.user?
            msg.reply "あなたって誰？"
            return
        command = msg.match[2].trim()
        if command not in ['見せて','みせて','みたい','見たい'] then return
        result = mgr.all_issues()
        my_tickets = []
        username = msg.message.user.name
        for k, v of result
            if v.user is username then my_tickets.push(fixed_size(v.tag, 12) + v.issue)
        if my_tickets.length is 0
            msg.reply "今対応中のチケットはありませんよ"
            return
        msg.reply "今対応中のチケットは：\n" + my_tickets.sort().join("\n")

    robot.respond /(.*)の(チケット|tickets?)を?(クリア|clear|完了)/i, (msg) ->
        mgr = new IssueManager(robot)
        user = msg.message.user || {'name':'demo'}
        tag = msg.match[1].replace('の', '').toLowerCase()
        all_issues = mgr.all_issues()
        count = 0
        for k, v of all_issues
            if tag is v.tag.toLowerCase()
                if v.user is user.name
                    mgr.solve_issue(k)
                    count++
        if count is 0
            msg.reply "今対応中のチケットはありませんよ"
            return
        msg.reply "お疲れ様でした〜"


    robot.respond /みんなの(.*)の?(チケット|ticket)を?(みせて|見せて|みたい|見たい)/i, (msg) ->
        mgr = new IssueManager(robot)
        tag = msg.match[1].replace('の', '').toLowerCase()
        for k, v of mgr.get_tags()
            if tag is v.toLowerCase()
                the_tag = tag
                tag_title = v
                break;
            return
        result = {}
        count = 0
        for k, v of mgr.all_issues()
            if v.tag.toLowerCase() is the_tag
                if not result[v.user]? then result[v.user] = []
                result[v.user].push(k)
                count++

        if count is 0
            msg.reply "#{tag_title}のチケットをやってる人はまだいません〜"
            return
        print_out = "こんな感じです\n"
        for u, issues of result
            print_out += u + " さん\n"
            print_out += "-------------------------\n"
            print_out += i + "\n" for i in issues
            print_out += "\n"

        msg.reply print_out


class IssueManager
    _robot : undefined
    _tags: {
        'redm04\\.maql\\.co\\.jp'  : 'B3M',
        'github\\.com\/befool-inc\/madcity' : 'madcity'
    }

    constructor: (robot) ->
        @_robot = robot

    get_tags: ->
        @_tags

    get_tag: (ticket) ->
        for pattern, tag of @_tags
            p = RegExp('https?:\\/\\/' + pattern + '\\/.*', 'g')
            if ticket.match(p) then return tag
        null

    is_number: (obj) ->
        not $.isArray( obj ) && (obj - parseFloat( obj ) + 1) >= 0

    all_issues: ->
        issues = @_robot.brain.get "issue:manager:pool"
        if issues?
            JSON.parse(issues)
        else
            {}
    all_solved_issues: ->
        issues = @_robot.brain.get "issue:manager:solved_pool"
        if issues?
            JSON.parse(issues)
        else
            {}

    assign_issue_to : (issue_obj, user) ->
        issue_pool = @all_issues()
        issue_pool[issue_obj.issue] = issue_obj
        @_robot.brain.set "issue:manager:pool", JSON.stringify(issue_pool)

    get_ticket_num: (ticket) ->
        ticket.split('/').pop()

    is_assigned: (issue) ->
        issue_pool = @all_issues()
        if issue_pool[issue]? then return issue_pool[issue]
        return false

    is_solved: (ticket) ->
        solved_pool = @all_solved_issues()
        if solved_pool[ticket]? then return solved_pool[ticket]
        return false

    solve_issue: (issue) ->
        issue_pool = @all_issues()
        solved_pool = @all_solved_issues()
        the_issue = issue_pool[issue]
        if not the_issue? then return
        now = new Date
        year    = now.getFullYear()
        month   = now.getMonth()+1
        day     = now.getDate()
        the_issue['solved_time'] = year + '.' + month + '.' + day
        solved_pool[the_issue.issue] = the_issue
        @_robot.brain.set "issue:manager:solved_pool", JSON.stringify(solved_pool)
        delete issue_pool[issue]
        @_robot.brain.set "issue:manager:pool", JSON.stringify(issue_pool)

    reset_solved_issue: (ticket) ->
        issue_pool = @all_issues()
        solved_pool = @all_solved_issues()
        the_issue = solved_pool[ticket]
        delete the_issue['solved_time']
        issue_pool[ticket] = the_issue
        @_robot.brain.set "issue:manager:pool", JSON.stringify(issue_pool)
        delete solved_pool[ticket]
        @_robot.brain.set "issue:manager:solved_pool", JSON.stringify(solved_pool)

    is_url: (ticket) ->
        exp = /https?:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{2,256}\.[a-z]{2,6}\b([-a-zA-Z0-9@:%_\+.~#?&//=]*)/gi
        if ticket.match(exp)? then return true
        false

    valid_ticket: (ticket) ->
        if not @is_url(ticket) then return false
        ticket_num = @get_ticket_num(ticket)
        # console.log(ticket_num)
        if not @is_number(ticket_num) then return false
        return true
###
    get_issues = (user) ->
        #issue_pool = all_issues
        #user_issues = []
        #[]
        #user_issues.push issue for issue in issue_pool when issue.user is user
###