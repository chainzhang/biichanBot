function slack_start {
    # git pull origin slack

    process_num=$(ps -ef | grep "bin/hubot --adapter slack" | grep -v "grep" | wc -l)

    if [ $process_num = "1" ]; then
        printf "[%-3s]   %s\n" "INF" "Bii is already running"
        exit $?
    fi

    export HUBOT_SLACK_TOKEN=""
    export HUBOT_SLACK_TEAM=""
    export HUBOT_SLACK_BOTNAME="$bot_name"
    export HUBOT_SLACK_CHANNELMODE=""
    export HUBOT_SLACK_CHANNELS=""
    export HUBOT_SLACK_LINK_NAMES=""

    PORT=$slack_port bin/hubot --adapter slack > logs/hubot.slack.log 2>&1 &
    if [ $? -eq 0 ]; then
        printf "[%-3s]   %s\n" "OK" "Bii now is running"
    fi
}

function slack_stop {
    pkill -f bin/hubot --adapter slack
    if [ $? -eq 0 ]; then
        printf "[%-3s]   %s\n" "OK" "Bii Stopped."
    fi
}

case $2 in
"start")
    printf "[%-3s]   %s\n" "RUN" "Starting Bii"
    slack_start
;;

"stop")
    printf "[%-3s]   %s\n" "RUN" "Stoping Bii"
    slack_stop
;;

"restart")
    printf "[%-3s]   %s\n" "RUN" "Restarting Bii"
    slack_stop
    slack_start
;;

"status")
    process_num=$(ps -ef | grep "bin/hubot --adapter slack" | grep -v "grep" | wc -l)

    if [ $process_num = "1" ]; then
        printf "[%-3s]   %s\n" "OK" "Bii is running"
    else
        printf "[%-3s]   %s\n" "OK" "Bii is sleeping"
    fi
;;
esac