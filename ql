#!/usr/bin/env bash
# shellcheck disable=SC2181

clear

echo -e "\e[36m
   ▄▄▄▄       ██                         ▄▄▄▄                                   
  ██▀▀██      ▀▀                         ▀▀██                                   
 ██    ██   ████     ██▄████▄   ▄███▄██    ██       ▄████▄   ██▄████▄   ▄███▄██ 
 ██    ██     ██     ██▀   ██  ██▀  ▀██    ██      ██▀  ▀██  ██▀   ██  ██▀  ▀██ 
 ██    ██     ██     ██    ██  ██    ██    ██      ██    ██  ██    ██  ██    ██ 
  ██▄▄██▀  ▄▄▄██▄▄▄  ██    ██  ▀██▄▄███    ██▄▄▄   ▀██▄▄██▀  ██    ██  ▀██▄▄███ 
   ▀▀▀██   ▀▀▀▀▀▀▀▀  ▀▀    ▀▀   ▄▀▀▀ ██     ▀▀▀▀     ▀▀▀▀    ▀▀    ▀▀   ▄▀▀▀ ██ 
       ▀                        ▀████▀▀                                 ▀████▀▀
\e[0m\n"

DOCKER_IMG_NAME="whyour/qinglong"
QL_PATH=""
SHELL_FOLDER=$(pwd)
CONTAINER_NAME=""
TAG="latest"
NETWORK="bridge"
QL_PORT=5700

HAS_IMAGE=false
PULL_IMAGE=true
HAS_CONTAINER=false
DEL_CONTAINER=true
INSTALL_WATCH=false
ENABLE_HANGUP=true
ENABLE_WEB_PANEL=true
OLD_IMAGE_ID=""

log() {
    echo -e "\e[32m\n$1 \e[0m\n"
}

inp() {
    echo -e "\e[33m\n$1 \e[0m\n"
}

opt() {
    echo -n -e "\e[36m输入您的选择->\e[0m"
}

warn() {
    echo -e "\e[31m$1 \e[0m\n"
}

cancelrun() {
    if [ $# -gt 0 ]; then
        echo -e "\e[31m $1 \e[0m"
    fi
    exit 1
}

docker_install() {
    echo "检测 Docker......"
    if [ -x "$(command -v docker)" ]; then
        echo "检测到 Docker 已安装!"
    else
        if [ -r /etc/os-release ]; then
            lsb_dist="$(. /etc/os-release && echo "$ID")"
        fi
        if [ "$lsb_dist" == "openwrt" ]; then
            echo "openwrt 环境请自行安装 docker"
            exit 1
        else
            echo "安装 docker 环境..."
            curl -fsSL https://get.docker.com | bash -s docker --mirror Aliyun
            echo "安装 docker 环境...安装完成!"
            systemctl enable docker
            systemctl start docker
        fi
    fi
}

docker_install
warn "降低学习成本，小白回车到底，一路默认选择"
# 配置文件保存目录
echo -n -e "\e[33m一、请输入配置文件保存的绝对路径（示例：/root/ql1)，回车默认为 当前目录/ql:\e[0m"
read -r ql_path
if [ -z "$ql_path" ]; then
    mkdir -p "$SHELL_FOLDER"/ql
    QL_PATH=$SHELL_FOLDER/ql
elif [ -d "$ql_path" ]; then
    QL_PATH=$ql_path
else
    mkdir -p "$ql_path"
    QL_PATH=$ql_path
fi

# 检测镜像是否存在
if [ -n "$(docker images -q $DOCKER_IMG_NAME:$TAG 2>/dev/null)" ]; then
    HAS_IMAGE=true
    OLD_IMAGE_ID=$(docker images -q --filter reference=$DOCKER_IMG_NAME:$TAG)
    inp "检测到先前已经存在的镜像，是否拉取最新的镜像：\n1) 拉取[默认]\n2) 不拉取"
    opt
    read -r update
    if [ "$update" = "2" ]; then
        PULL_IMAGE=false
    fi
fi

# 检测容器是否存在
查询集装箱名称（）{
    如果 docker ps -a | grep "$CONTAINER_NAME" 2>/dev/null; 然后
        HAS_CONTAINER=true
        inp "检测到先前已经存在的容器，是否删除先前的容器：\n1) 删除[默认]\n2) 不删除"
        选择
        读-r 更新
        如果[“$update”=“2”]; 然后
            PULL_IMAGE=假
            inp "您之前选择了未删除的集装箱，需要重新输入集装箱名称"
            输入容器名称
        菲
    菲
}

# 容器名称
输入容器名称（）{
    echo -n -e "\e[33m\n二、请输入要创建的Docker容器名称[默认为：qinglong]->\e[0m"
    读取-r容器名称
    if [ -z "$container_name" ]; 然后
        CONTAINER_NAME="青龙"
    除了
        CONTAINER_NAME=$container_name
    菲
    查询集装箱名称
}
输入容器名称

# 是否安装WatchTower
inp " 是否安装 containsrrr/watchtower 自动更新 Docker 容器：\n1) 安装\n2) 不安装[默认]"
选择
读 -r 了望塔
如果[“$watchtower”=“1”]; 然后
    INSTALL_WATCH=true
菲

inp "请选择容器的网络类型：\n1) host\n2)bridge[默认]"
选择
读网络
如果[“$net”=“1”]; 然后
    网络=“主机”
    MAPPING_QL_PORT=""
菲

inp "是否在启动容器时自动启动挂机程序：\n1) 开启[默认]\n2) 关闭"
选择
读取-rhang_s
如果[“$hang_s”=“2”]; 然后
    ENABLE_HANGUP=假
菲

inp "是否启用青龙面板：\n1) 启用[默认]\n2) 不启用"
选择
读取-r面板
如果[“$面板”=“2”]; 然后
    ENABLE_WEB_PANEL=假
菲

# 端口问题
修改_ql_端口（）{
    inp "是否修改青龙端口[默认5700]：\n1) 修改\n2) 不修改[默认]"
    选择
    读取-rchange_ql_port
    如果[“$change_ql_port”=“1”]; 然后
        回显-n -e“\e
