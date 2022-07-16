#!/usr/bin/env bash
#
# サーバ上にあるデプロイスクリプトをキックする

set -eu

echo_err() {
    echo "$1" 1>&2
}

main() {
    local -r script_dir=$(
        cd $(dirname $0)
        pwd
    )

    # 参考: https://blog.yuuk.io/entry/web-operations-isucon
    local branch=main
    if [ $# -gt 0 ]; then
        branch=$2
    fi
    local server=$1
    local -r user=$USER
    ssh isucon@$server "/home/isucon/isucon-utils/server/deploy.sh $user $branch"
}

main "$@"
