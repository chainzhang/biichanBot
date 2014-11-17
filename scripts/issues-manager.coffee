###
jsdom = require 'jsdom'
$ = require('jquery')(jsdom.jsdom().parentWindow)

module.exports = (robot) ->
    robot.respond /(.*)を?[や|対応]/i, (msg) ->
        mgr = new IssueManager(robot)
        user = msg.message.user || {'name':'demo'}
        ticket = msg.match[1].replace('を', '')
        if not mgr.valid_ticket(ticket) then return

        tag = mgr.get_tag(ticket)
        if not tag
            msg.reply 'これって何のチケット？'
            return
        if mgr.is_assigned(ticket)
            msg.reply "このチケットは#{user.name}が対応してますよ。"
            return

        issue_obj = {
            'user' : user.name,
            'issue': ticket
        }
        mgr.assign_issue_to(issue_obj, user)
        msg.reply "はい、#{tag}のチケットですね、頑張って下さい！"

    robot.respond /(.*)(を?)(解決|OK|オッケ|おっけ|おけ|オケ|対応済み|終了)ー?/i, (msg) ->
        mgr = new IssueManager(robot)
        ticket = msg.match[1]
        if not mgr.valid_ticket(ticket) then return
        if not mgr.is_assigned(ticket)
            msg.reply "このチケットに対応している人はいませんよ。"
            return
        mgr.solve_issue(ticket)
        msg.reply "お疲れ様でした〜"

    robot.respond /(チケット|ticket|tickets)(.*)/i, (msg) ->
        command = msg.match[2]
        msg.reply command



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

    assign_issue_to : (issue_obj, user) ->
        issue_pool = @all_issues()
        issue_pool[issue_obj.issue] = issue_obj
        @_robot.brain.set "issue:manager:pool", JSON.stringify(issue_pool)

    get_ticket_num: (ticket) ->
        ticket.split('/').pop()

    is_assigned: (issue) ->
        issue_pool = @all_issues()
        if issue_pool[issue]? then return true
        return false

    solve_issue: (issue) ->
        issue_pool = @all_issues()
        delete issue_pool[issue]
        @_robot.brain.set "issue:manager:pool", JSON.stringify(issue_pool)

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



    #get_issues = (user) ->
        #issue_pool = all_issues
        #user_issues = []
        #[]
        #user_issues.push issue for issue in issue_pool when issue.user is user
###