# jquery
jsdom = require 'jsdom'
$ = require('jquery')(jsdom.jsdom().parentWindow)

# configal vars
config = {}
config.BEFOOL_HOMEPAGE_URL = 'http://befool.co.jp'
config.UPDATE_BRANCH       = 'public'
config.REPOS_NAME          = 'befool-inc/homepage'

# tweets
tweet_msg = (post) ->
    # templates of the tweet, would be select in random
    template = ['新しいブログ記事を読んでみな〜 :title :link  #befool',
                'ブログ更新：:title :link #befool',
                'befoolのブログ更新したよ：:title :link #befool',
                'やった！新しい記事がアップされた!：:title :link #befool']
    template[Math.floor(Math.random() * template.length)].replace(/:title/g, '『'+post.title+'』').replace(/:link/g, post.link)

module.exports = (robot) ->
    # listen to webhook
    robot.router.post '/bii/befool/publish', (req, res) ->
        ref = req.body.ref
        repos = req.body.repository.full_name
        if ref.split('/').pop() isnt config.UPDATE_BRANCH 
            return res.send 'OK, but I\'m not interested about that. ^ ^;'
        robot.logger.info "Befool blog updated"
        robot.emit "befool_homepage_published", {repos: repos}
        res.send 'OK, I would check it out. ^ ^'

    # on published
    robot.on "befool_homepage_published", (datas) ->
        robot.http('http://befool.co.jp/blog')
        .get() (err, res, body) ->
            $posts = $(body).find("#blog-archives").find(".entry-title");
            posts           = []
            old_posts       = JSON.parse(robot.brain.get 'befool:homepage:old:posts') || []
            published_posts = []
            $posts.each (i, post) ->
                post_title = $(post).find('a').text().replace(/\\n/g, '')
                post_link  = $(post).find('a').attr('href')
                if post_link not in old_posts
                    published_posts.push {title: post_title, link: config.BEFOOL_HOMEPAGE_URL + post_link}
                posts.push(post_link)

            if published_posts.length > 0
                if datas.repos is config.REPOS_NAME
                    robot.emit "tweet_new_posts_in_befool_blog", published_posts.reverse()
                    robot.brain.set 'befool:homepage:old:posts', JSON.stringify(posts)
                else
                    $(published_posts.reverse()).each (i, post) ->
                        robot.logger.info "I would post :" + post.title
            else
                robot.logger.info "But there is not post updated."

    # send the tweet
    robot.on "tweet_new_posts_in_befool_blog", (posts, msg) ->
        sent = []
        $(posts).each (i, post) ->
            # robot.send undefined, tweet_msg(post)
            sent.push(post.title)
        robot.emit "befool_blog_tweeted", sent

    # on tweeted
    robot.on "befool_blog_tweeted", (sent) ->
        robot.logger.info "post tweeted: \n" + sent.join("\n")
