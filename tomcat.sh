#!/bin/bash
#############################################
# this script is Tomcat Management tool                                                                    #
#############################################
#

# functions这个脚本是给/etc/init.d里边的文件使用的。
# https://www.cnblogs.com/image-eye/archive/2011/10/26/2220405.html
. /etc/init.d/functions

# 通过setenv函数设置的环境变量只在本进程，而且是本次执行中有效。
# set env
export PATH=$PATH:/bin:/sbin:/usr/sbin
# 设置中文字符
export LANG="zh_CN.UTF-8"
# 设置tomcat启动脚本
export tomcatStart=/usr/local/tomcat/bin/startup.sh
# 设置项目部署目录
DeployDir="/usr/local/tomcat/webapps/SSM_Demo/"
# 设置当前目录绝对路径
work_path=$(dirname $(readlink -f $0))
# 监控日志路径
LogDir=/usr/local/share/applications/nginx-1.13.7/logs/host.access.log
# 取日志文件名 cut 使用 / 将 LogDir 分割为4个域
LogName=$(echo "$LogDir" | cut -d '/' -f 4 )
# API日志文件
DebugDir=/usr/local/tomcat/webapps/SSM_Demo/WEB-INF/log/log.log
# 系统版本
OS_NAME=$(cat /etc/system-release)
# 监控网口名
eth=eth0

# 检测是否以root权限运行脚本
# whoami是操作系统中用于查看当前有效用户名的命令
# >&2 以错误的提示方式输出此句话 0 代表???入 1 代表?幕?出
if [[ "$(whoami)" != "root" ]]; then
    echo "请以root用户运行此脚本" >&2
    exit 1
fi

# /etc/init.d/functions 这个脚本是给/etc/init.d里边的文件使用的,函数库
#. /etc/init.d/functions

#if [ ! -f /opt/software/apache-tomcat-7.0.72/bin/startup.sh ]
# 1 -f 判断文件是否存在
# http://blog.51cto.com/kangyang/810182
if [ ! -f ${tomcatStart} ]
    then
    echo "tomcat 未安装,请安装后执行"
    exit 1
# 用fi表示if语句块的结束
fi
# 启动
function start(){
    # ps -ef |grep java|grep -v grep|grep -v sh
    # ps -ef |grep java 显示 ps -ef 中包含java的行
    # grep -v $value 反向查找,输出不包含变量的行
    # |grep -v grep 过滤掉包含grep的行,当执行grep时ps -ef也会显示出执行命令
    # |grep -v sh 过滤掉包含sh的行
    # |wc -l 统计过滤后的行数
    # $1 -eq $2 对比是否相等
    if [ `ps -ef |grep java|grep -v grep|grep -v sh|wc -l` -eq 0 ]
        # true 执行 then
        then

            # /dev/null 代表空设备文件
            # >  ：代表重定向到哪里，例如：echo "123" > /home/123.txt
            # 1  ：表示stdout标准输出，系统默认值是1，所以">/dev/null"等同于"1>/dev/null"
            # 2  ：表示stderr标准错误
            # &  ：表示等同于的意思，2>&1，表示2的输出重定向等同于1
            # 1 > /dev/null 2>&1 语句含义
            /bin/sh ${tomcatStart} >/dev/null 2>&1
            action "tmocat 启动中..."

            # 0表示成功（Zero - Success）
            # 非0表示失败（Non-Zero  - Failure）
            # 2表示用法不当（Incorrect Usage）
            # 127表示命令没有找到（Command Not Found）
            # 126表示不是可执行的（Not an executable）
            # >=128 信号产生
            # $? 上一个命令的退出码
            [ $? -eq 0 ]&&\
            # 进程休眠1秒钟
            sleep 5
            # /bin/true 命令啥都不做，只设置退出码为0。
            action "tmocat 已启动." /bin/true
        else
            action "tomcat 是启动的." /bin/true
            exit 3
    # if语句结束
    fi
}
# 停止
function stop(){
    if [ `ps -ef |grep java|grep -v grep|grep -v sh|wc -l` -gt 0  ]
        then
            PID=`ps -ef |grep java|grep -v grep|awk '{print $2}'`
            kill -9 $PID
            echo "tomcat 停止中..."
            [ $? -eq 0 ]&&\
            sleep 2
            action "tomcat 已经停止了." /bin/true
         else
            action "tomcat 是停止的." /bin/true
            exit 4
    fi
}
# 重启
function restart(){
    if [ `ps -ef |grep java |grep -v grep|grep -v sh|wc -l` -gt 0  ]
        then
         PID1=`ps -ef |grep java|grep -v grep|awk '{print $2}'`
            kill -9 $PID1
            [ $? -eq 0 ]&&/bin/sh ${tomcatStart} >/dev/null 2>&1
            [ $? -eq 0 ]&&echo "tomcat 重启中 ..."
            sleep 5
            action "tomcat 已重启 ." /bin/true
        else
            action "tomcat 没有运行,正在启动中 ..." /bin/true
            [ $? -eq 0 ]&&/bin/sh ${tomcatStart} >/dev/null 2>&1
            [ $? -eq 0 ]&&\
            sleep 5
            action "tomcat 已启动 ." /bin/true
    fi
}
# 查看状态
function status(){
    if [ `ps -ef |grep java |grep -v grep|wc -l` -gt 0  ]
            then
                 action "tomcat 正在运行"  /bin/true
            else
                  action "tomcat 已停止运行" /bin/false
    fi
}

# 部署
function deployDir(){
    echo "准备部署中..."
    if [ -d "$DeployDir" ]
        then
          echo "项目SSM_Demo已存在是否需要重新部署? (y/n) "
          # 接收输入的值 赋值给answer
          read -p "(默认: n):" answer
          # -z  如果string 为空
          [ -z ${answer} ] && answer="n"
          if [ "${answer}" == "y" ] || [ "${answer}" == "Y" ]
           then
             echo "开始清理原目录 ${DeployDir} ..."
             # 删除原始目录
             rm -rf ${DeployDir} >/dev/null 2>&1
             sleep 1
             action "原项目已清理完成"  /bin/true
          else
              echo "已退出部署"
              exit 1
          fi
    fi
    #解压项目到本目录
    echo "解压项目到 ${work_path}/SSM_Demo 中 ..."
    unzip -oq SSM_Demo.war -d ${work_path}/SSM_Demo >/dev/null 2>&1
    # 防止解压未完成
    sleep 5
    if [ $? -ne 0 ]
        then
            action "SSM_Demo.war 解压失败!"  /bin/false
            exit 1
    fi
    # 上面命令解压成功为 0
    if [ $? -eq 0 ]
        then
            action "解压完成"  /bin/true
            echo "部署中 ..."
            mv ${work_path}/SSM_Demo ${DeployDir} >/dev/null 2>&1
    fi
    sleep 3
    if [ $? -eq 0 ]
        then
            action "部署完成 ..."  /bin/true
            # 清理解压文件
            rm -rf ${work_path}/SSM_Demo >/dev/null 2>&1
            # 部署完成重启tomcat
            restart
            action "清理解压文件完成 ..."  /bin/true
            exit 0
    else
        action "部署失败 ..."  /bin/false
        # 清理解压文件
        exit 1
    fi
}

#监控
  if [ ! -d /sys/class/net/$eth ];
      echo -e "You system have network-interface:\n`ls /sys/class/net`"
  while [ "1" ]
  do
    # 查看访问数次超过100的ip
    TopIp10=$(cat "$LogDir" | awk '{print $1}' | sort | uniq -c | sort -rn | head -n 10)
    # 查看访问最频繁的10个页面
    TopUrl5=$(grep -v "-" "$LogDir" | awk '{print $9}' | sort | uniq -c | sort -rn | head -n 5)
    # 每分钟请求数
    TopTime5=$(awk '{print $2}' "$LogDir"| cut -c 16-17 | sort | uniq -c | sort -nr | head -n 5)
    # 传输时间大于10ms的页面

    # 接口响应时间
    # 当前访问url
    JustUrl=$(cat "$LogDir" | tail -n 1 | awk '{print $5}')
    # Controller响应信息
    # DB 响应信息
    # 后端页面生成时间
    # Nginx 页面传输时间
        NginxCreateWebTimer=$(cat "$LogDir" | tail -n 1 | awk '{print $NF * 1000"ms"}')


    # 内存
    # 空闲内存 NR>2{print p}{p=$1}:去掉最后一行和第一行
    FreeMem=$(free -m | awk -F : '{print $2}' |awk '{print $3}' | awk 'NR>2{print p}{p=$1}')
    # 空闲swap内存 END{print}: 取最后一行
    FreeSwap=$(free -m | awk -F : '{print $2}' |awk '{print $3}' |  awk 'END{print}')

    # 网卡状态
    STATUS="fine"

    # 获取当前时刻网口接收与发送的流量
    RXpre=$(cat /proc/net/dev | grep $eth | tr : " " | awk '{print $2}')
    TXpre=$(cat /proc/net/dev | grep $eth | tr : " " | awk '{print $10}')

    # 获取1秒后网口接收与发送的流量
    sleep 1
    RXnext=$(cat /proc/net/dev | grep $eth | tr : " " | awk '{print $2}')
    TXnext=$(cat /proc/net/dev | grep $eth | tr : " " | awk '{print $10}')
    clear

    # 获取这1秒钟实际的进出流量
    RX=$((${RXnext}-${RXpre}))
    TX=$((${TXnext}-${TXpre}))

    # 判断接收流量如果大于MB数量级则显示MB单位,否则显示KB数量级
    if [[ $RX -lt 1024 ]];then
      RX="${RX}B/s"
    elif [[ $RX -gt 1048576 ]];then
      RX=$(echo $RX | awk '{print $1/1048576 "MB/s"}')
      $STATUS="busy"
    else
      RX=$(echo $RX | awk '{print $1/1024 "KB/s"}')
    fi

    # 判断发送流量如果大于MB数量级则显示MB单位,否则显示KB数量级
    if [[ $TX -lt 1024 ]];
      then
        TX="${TX}B/s"
      elif [[ $TX -gt 1048576 ]];
      then
        TX=$(echo $TX | awk '{print $1/1048576 "MB/s"}')
    else
      TX=$(echo $TX | awk '{print $1/1024 "KB/s"}')
    fi

    # 打印信息
    echo -e "==================================="
    echo -e "TomCat 监控工具"
    echo -e "version 1.0"
    echo "      o   ^__^ " 
    echo "       o  (oo)\_______" 
    echo "          (__)\       )\/\ " 
    echo "              ||----w |    "   
    echo "              ||     ||    "
    echo -e "==================================="
    echo -e "System: $OS_NAME"
    echo -e "DateTime:   `date +%F`  `date +%k:%M:%S`"
    echo -e "MemFree:${FreeMem}M SwapFree:${FreeSwap}M"
    echo -e "Status: $STATUS"
    status
    echo -e  " \t     RX \tTX"
    echo "------------------------------"
    # 打印实时流量
    echo -e "$eth \t $RX   $TX "
    echo "===== $LogName ====="
    echo "----- 最近一次接口响应数据 -----"
    echo "访问url: $JustUrl"
    echo -e "Controller信息:\t$ControllerTimer"
    echo -e "DB接口信息: \t$DBTimer"
    echo "后端页面生成时间:   $ServiceCreateWebTimer"
    echo "服务器页面传输时间: $NginxCreateWebTimer"
    echo "------------------------------"
    echo -e "\t Top10 ip"
    echo "访问次数 IP"
    echo "$TopIp10"
    echo "------------------------------"
    echo -e "\t Top5 页面"
    echo "访问次数 页面"
    echo "$TopUrl5"
    echo "------------------------------"
    echo -e "\t Top5 传输时间大于10ms的页面"
    echo "统计次数 页面"
    echo "$TopTime"
    echo "------------------------------"

    echo -e "\t Top5 并发(每分钟)"
    echo -e " 并发数 时间"
    echo "$TopTime5"
    echo "------------------------------"
    # 退出信息
    echo -e "Press 'Ctrl+C' to exit"
  done
}

# 将脚本后的第一个单词匹配到$1
case $1 in
    # 如果是start 执行 start()
    start)
    start
;;
    stop)
    stop
;;
    restart)
    restart
;;
    status)
    status
;;
    deploy)
    deployDir
;;
    monitor)
    Monitor
;;
    # 如果没有匹配到 输出echo语句
    *)
    echo "请在脚本后添加正确的执行参数:start|stop|restart|status|deploy|monitor"
#结束case
esac
