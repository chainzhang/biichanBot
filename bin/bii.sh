# bii slack status
# 

export bii_dir="$(dirname "$0")"
export bot_name="bii"
export slack_port="6464"

case $1 in
"slack")
    . "$bii_dir/slack.sh"
;;
esac



