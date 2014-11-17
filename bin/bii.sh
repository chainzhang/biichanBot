#!/bin/bash

export bii_dir="$(dirname "$0")"
export bot_name="bii"
export slack_port="6464"

case $1 in
"slack")
    . "$bii_dir/slack.sh"
;;
"twitter")
    . "$bii_dir/twitter.sh"
;;
esac
