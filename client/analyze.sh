#!/bin/bash

main() {
    local -r server=$1
    local -r user=$USER

    local -r script_dir=$(
        cd $(dirname $0)
        pwd
    )

    ssh -F ${script_dir}/.sshconfig $server "/home/isucon/isucon-utils/server/analyze.sh $user"
}

main "$@"
