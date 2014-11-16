# jquery
jsdom = require 'jsdom'
$ = require('jquery')(jsdom.jsdom().parentWindow)
parseString = require('xml2js').parseString;

template = {
    single: [':first かな!',
             ':first だよ',
             ':first だと思うよ'],
    double: [':first か、:otherか、どっちかな'
             ':first と :other、どっちも使えるかしら..?'],
    multi:  [':first かな、:other ともいうらしいよ、どれがいいかな^ ^;',
             'いっぱいあるよ：:first、:other']
}

apply_template = (words) ->
    type = 'single'
    if words.length is 2 then type = 'double'
    if words.length > 2 then type = 'multi' 
    template[type][Math.floor(Math.random() * template[type].length)].replace(/:first/g, words.shift()).replace(/:other/g, words.join('、'))

search_word = (word) ->
    "http://public.dejizo.jp/NetDicV09.asmx/SearchDicItemLite?Dic=EdictJE&Word=#{word}&Scope=HEADWORD&Match=
STARTWITH&Merge=AND&Prof=XHTML&PageSize=20&PageIndex=0"

search_words_by_id = (id) ->
    "http://public.dejizo.jp/NetDicV09.asmx/GetDicItemLite?Dic=EdictJE&Item=#{id}&Loc=&Prof=XHTML"

module.exports = (robot) ->
    robot.respond /(.*)を英語で(.*)/i, (msg) ->
        word = msg.match[1]
        if word.replace(/(　)/g, '').split(' ').join('').length == 0
            if robot.adapterName isnt 'twitter' then  msg.reply "何を？"
            return
        console.log(word.match(/^[A-Za-z0-9 _]*[A-Za-z0-9][A-Za-z0-9 _]*$/))
        if word.match(/^[A-Za-z0-9 _]*[A-Za-z0-9][A-Za-z0-9 _]*$/)?
            if robot.adapterName isnt 'twitter' then msg.reply "それって日本語？(・ε・｀).."
            return
        robot.logger.info "#{word}を調べています..."
        if robot.adapterName isnt 'twitter' then msg.reply msg.random ['ちょっと待って・・', '少々お待ち...']
        robot.http(search_word(word))
        .get() (err, res, body) ->
            if err? then return
            parseString body, (err, result) ->
                if err? then return
                if result.SearchDicItemResult.ItemCount[0] == '0'
                    msg.reply '＞＜。わからない・・'
                    return
                item_id = result.SearchDicItemResult.TitleList[0].DicItemTitle[0].ItemID[0]
                if item_id?
                    robot.http(search_words_by_id(item_id))
                    .get() (err, res, body) ->
                        $words = $(body).find('.NetDicBody').children('div').children('div')
                        words = []
                        $words.each (i, w) ->
                            robot.logger.info $(w).text()
                            the_word = $(w).text()
                            the_chars = the_word.split(' ')
                            if the_chars.length > 0
                                the_word = []
                                $(the_chars).each (i, c) ->
                                    the_word.push(c.replace(/\s*\(.*?\)\s*/g, ''))

                                the_word = the_word.join(' ')
                                the_word = the_word.replace(/\s*\(.*?\)\s*/g, '')

                            if the_word.length > 0 then words.push(the_word.trim())

                        words.pop()
                        if words.length is 0
                            msg.reply 'ごめんなさい、わかりません＞＜'
                            return
                        msg.reply apply_template(words)
                        ###

            ###
            