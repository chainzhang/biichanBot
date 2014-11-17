# bii slack status
# 

export bii_dir="$(dirname "$0")"
export bot_name="bii"
export slack_port="6464"

if [ -z $BII_BOT_DIR ]; then
    printf "[%-3s]   %s\n" "ERR" "You should define BII_BOT_DIR before use bii command."
    exit $?
fi

cd $BII_BOT_DIR

case $1 in
"slack")
    . "$bii_dir/slack.sh"
;;
"twitter")
    . "$bii_dir/twitter.sh"
;;
esac



