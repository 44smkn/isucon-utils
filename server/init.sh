#!/usr/bin/env bash
#
# サーバに必要な分析ツール類などをインストールする
# ISUCON本番: ./deploy.sh REPLACE_YOUR_SLACK_WEBHOOK_URL
# ISUCON準備: ./deploy.sh REPLACE_YOUR_SLACK_WEBHOOK_URL true

set -eux

# Set global variable
USERS=(44smkn karrybit)
ALP_VERSION="v1.0.10"

#######################################
# Linuxのアーキテクチャを返す
# Arguments:
#   None
# Outputs:
#   amd64 or arm64
#######################################
function get_arch() {
    case $(uname -m) in
    x86_64)
        arch=amd64
        ;;
    arm64)
        arch=arm64
        ;;
    *)
        arch=amd64
        ;;
    esac
    echo ${arch}
}

#######################################
# 競技参加者のssh公開鍵を配置する
# Globals:
#   USERS
# Arguments:
#   None
#######################################
function add_auhorized_keys() {
    local -r ssh_dir="/home/isucon/.ssh"
    if [ ! -e $ssh_dir ]; then
        mkdir -p $ssh_dir
    fi

    rm -f "${ssh_dir}/authorized_keys"
    for user in "${USERS[@]}"; do
        curl "https://github.com/${user}.keys" >>"${ssh_dir}/authorized_keys"
    done
}

#######################################
# アクセスログを解析するためのツール alp をインストールする
# Globals:
#   ALP_VERSION
# Arguments:
#   Arch such as "amd64" or "arm64"
#######################################
install_alp() {
    local -r alp_cmd=$(which alp)
    if [[ ! -z $alp_cmd ]]; then
        echo "alp has already been installed. So, skip installation process of alp."
        return
    fi

    local -r arch="$1"
    curl -sL -o alp.zip "https://github.com/tkuchiki/alp/releases/download/${ALP_VERSION}/alp_linux_${arch}.zip"
    unzip alp.zip
    rm -f alp.zip
    sudo install -o root -g root -m 0755 alp /usr/local/bin/alp
    alp --version && echo "Success Install alp 🎉"
}

#######################################
# package systemを抽象化してinstallする
# Arguments:
#   Package name
#######################################
install_with_pkgsys() {
    local -r name=$1

    local yum_cmd=$(which yum)
    local apt_cmd=$(which apt)

    if [[ ! -z $yum_cmd ]]; then
        sudo yum update
        sudo yum install -y $name
    elif [[ ! -z $apt_cmd ]]; then
        sudo apt update
        sudo apt install -y $name
    else
        echo "can't find package system."
    fi
}

#######################################
# スロークエリログの分析に利用するpt-query-digestをinstallする
# Arguments:
#   None
#######################################
install_pt_query_digest() {
    # https://www.percona.com/doc/percona-toolkit/3.0/installation.html
    install_with_pkgsys percona-toolkit
    pt-query-digest --version && echo "Success Install pt-query-digest 🎉"
}

#######################################
# pt-query-digestのwrapperスクリプト
# Arguments:
#   None
#######################################
install_query_digester() {
    local -r query_digester_cmd=$(which query-digester)
    if [[ ! -z $query_digester_cmd ]]; then
        echo "query-digester has already been installed. So, skip installation process of query-digester."
        return
    fi

    # https://github.com/kazeburo/query-digester
    curl -sL https://raw.githubusercontent.com/kazeburo/query-digester/main/query-digester
    sudo install -o root -g root -m 0755 query-digester /usr/local/bin/query-digester
    echo "Success Install query-digester 🎉"
}

#######################################
# pprofの依存ライブラリをinstallする
# Arguments:
#   None
#######################################
install_graphviz() {
    # https://blog.zoe.tools/entry/2020/07/26/181836
    install_with_pkgsys graphviz
    dot -V && echo "Success Install graphviz 🎉"
}

#######################################
# nginxのLogFormatを変更する
# Arguments:
#   None
#######################################
change_nginx_logformat() {
    local -r log_format_conf_file="/etc/nginx/conf.d/log_format.conf"
    if [ -e $log_format_conf_file ]; then
        cp "${log_format_conf_file}" "${log_format_conf_file}.origin"
        echo "${log_format_conf_file} has already existed. Pleease check ${log_format_conf_file}.origin."
    fi
    echo 'log_format ltsv "time:$time_local"
                "\thost:$remote_addr"
                "\tforwardedfor:$http_x_forwarded_for"
                "\treq:$request"
                "\tstatus:$status"
                "\tmethod:$request_method"
                "\turi:$request_uri"
                "\tsize:$body_bytes_sent"
                "\treferer:$http_referer"
                "\tua:$http_user_agent"
                "\treqtime:$request_time"
                "\tcache:$upstream_http_x_cache"
                "\truntime:$upstream_http_x_runtime"
                "\tapptime:$upstream_response_time"
                "\tvhost:$host";
access_log /var/log/nginx/access.log ltsv;' | sudo tee "${log_format_conf_file}" >/dev/null
    echo "${log_format_conf_file} has been created!"
}

#######################################
# slow query log出力する設定にする
# Arguments:
#   None
#######################################
add_slow_query_config() {
    local -r my_cnf_file="/etc/mysql/my.cnf"
    local -r slow_query_log="/var/log/mysql/slow.log"

    if [ -e $slow_query_log ]; then
        echo "${slow_query_log} has already existed. Skip configuration change for slow query."
        return
    fi

    echo '[mysqld]
slow_query_log = 1
slow_query_log_file = /var/log/mysql/slow.log
long_query_time = 0' | sudo tee -a /etc/mysql/my.cnf >/dev/null
    echo "add slow query config to /etc/mysql/my.cnf"
}

main() {
    local -r webhook_url=$1
    local -r create_authorized_keys=$2
    local -r script_dir=$(
        cd $(dirname $0)
        pwd
    )
    echo "${webhook_url}" >"${script_dir}/webhook_url.txt"

    # Is this needed?
    if [ $create_authorized_keys = "true" ]; then
        add_auhorized_keys
    fi

    # Install some packages or binaries
    local -r arch=$(get_arch)
    install_alp $arch
    install_pt_query_digest
    install_graphviz

    # Change log format
    change_nginx_logformat
    add_slow_query_config
}

main "$@"
