jsdom = require 'jsdom'
$ = require('jquery')(jsdom.jsdom().parentWindow)

module.exports = (robot) ->
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
            'issue': ticket
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
            if v.user is username then my_tickets.push(v.issue)
        if my_tickets.length is 0
            msg.reply "今対応中のチケットはありませんよ"
            return
        msg.reply "今対応中のチケットは：\n" + my_tickets.join("\n")



class IssueManager
    _robot : undefined
    _tags: {
        'redm04.maql.co.jp'  : 'B3M'
    }

    constructor: (robot) ->
        @_robot = robot

    get_tag: (ticket) ->
        domain = ticket.replace('http://','').replace('https://','').split(/[/?#]/)[0]
        @_tags[domain] || null

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