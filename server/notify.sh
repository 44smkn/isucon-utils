#!/bin/bash
#
# 特定のチャンネルに通知を行います
set -ex

echo_err() {
    echo "$1" 1>&2
}

main() {
    local -r script_dir=$(
        cd $(dirname $0)
        pwd
    )

    local -r message=$1
    local -r webhook_url=$(cat ${script_dir}/webhook_url.txt)
    curl -X POST -H 'Content-type: application/json' --data "{\"text\":\"${message}\"}" $webhook_url
}

main "$@"
