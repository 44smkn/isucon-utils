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
        branch=$1
    fi
    local -r user=$USER
    for server in s1 s3; do
        ssh -F ${script_dir}/.sshconfig $server "/home/isucon/isucon-utils/server/deploy.sh $user $branch"
    done
}

main "$@"
