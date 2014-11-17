#!/bin/bash

export HUBOT_TWITTER_ACCOUNT_NAME="bii_befool"
export twitter_port="7272"

function twitter_start {
    # git pull origin slack

    process_num=$(ps -ef | grep "bin/hubot -a twitter -n bii_befool" | grep -v "grep" | wc -l)

    if [ $process_num = "1" ]; then
        printf "[%-3s]   %s\n" "INF" "Bii is already running"
        exit $?
    fi

    export HUBOT_TWITTER_KEY="wuwbLOEtcb65y4T5oHI1Km08y"
    export HUBOT_TWITTER_SECRET="7qeHOYHHuVaasphs4o01OcNByeOt0tiSYeqSwiLC4kjD3OqZlZ"
    export HUBOT_TWITTER_TOKEN="2886288859-ecl5Ck4vOVuAhuwEfb39DIG4IyWMVdS8uALuW7O"
    export HUBOT_TWITTER_TOKEN_SECRET="QSAigKJyd0Db0kigLK0hGRJ7x7XhujDnC5d2xS77jpHiA"

    PORT=$twitter_port bin/hubot -a twitter -n bii_befool > logs/hubot.twitter.log 2>&1 &
    if [ $? -eq 0 ]; then
        printf "[%-3s]   %s\n" "OK" "Bii now is running"
    fi
}

function twitter_stop {
    pkill -f "bin/hubot -a twitter -n bii_befool" slack
    if [ $? -eq 0 ]; then
        printf "[%-3s]   %s\n" "OK" "Bii Stopped."
    fi
}

case $2 in
"start")
    printf "[%-3s]   %s\n" "RUN" "Starting Bii"
    twitter_start
;;

"stop")
    printf "[%-3s]   %s\n" "RUN" "Stoping Bii"
    twitter_stop
;;

"restart")
    printf "[%-3s]   %s\n" "RUN" "Restarting Bii"
    twitter_stop
    twitter_start
;;

"status")
    process_num=$(ps -ef | grep "bin/hubot -a twitter -n bii_befool" | grep -v "grep" | wc -l)

    if [ $process_num = "1" ]; then
        printf "[%-3s]   %s\n" "OK" "Bii is running"
    else
        printf "[%-3s]   %s\n" "OK" "Bii is sleeping"
    fi
;;
"update")
    git pull origin twitter
    twitter_stop
    twitter_start
;;
"log")
    tail -f logs/hubot.twitter.log
;;
esac