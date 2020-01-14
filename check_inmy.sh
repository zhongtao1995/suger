#!/bin/bash

    #cpu负载检查
#    iotid2=`ssh $i" sudo  iotop -b -n 1 " |head -4 | tail -1 | awk '{print $1}'`
#    iotid1=`ssh $i" sudo  iotop -b -n 1 " |head -3 | tail -1 | awk '{print $1}'`
#ip地址
    ip=`ifconfig | grep "inet addr:" | grep -v "127.0.0" | awk -F ':' '{print $2}' | awk '{print $1}'`
#iowait超过5s
    iowait=` iostat | head -4 | tail -1 | awk '{print $4}'`
    ti=`echo "5 > $iowait"|bc `
#io空闲
    iofree=` iostat  | head -4 | tail -1 | awk '{print $6}'`
#io使用率
    iouse=`awk -v x=100 -v y=$iofree 'BEGIN{printf "%.2f\n",x-y}'`
#cpu使用最高进程
    cpuhigbest=`top -n 1 -b | head -9 | tail -2| awk '{print $1}'| head -1 `
#cpu使用最高进程的cpu使用率
    cpuhcp=`top -n 1 -b | head -9 | tail -2| awk '{print $1,$9}'| head -1 | awk '{print $2}'`
#cpu使用最高进程io
    cpuhio=`pidstat -p $cpuhigbest -d | tail -1 | awk '{print $4}'`
#cpu使用第二高进程
    cpuhigbest2=`top -n 1 -b | head -9 | tail -2| awk '{print $1}'| tail -1 `
#cpu使用第二高进程的cpu使用率
    cpuhcp2=`top -n 1 -b | head -9 | tail -2| awk '{print $1,$9}'| tail -1 | awk '{print $2}'`
#cpu使用第二高进程io
    cpuhio2=`pidstat -p $cpuhigbest2 -d | tail -1 | awk '{print $4}'`
#检查是否为java进程
    jp=`ps aux | grep javapro | awk '{print $2}'| grep -w "$cpuhigbest"`
#判断java进程是否存在，java进程的old区
    if [[ -n "$jp" ]];then        
         jold=`sudo -u javapro /usr/local/java/bin/jstat -gcutil $cpuhigbest | tail -1 | awk '{print $4}'`
    fi 
#cpu空闲
    cpufree=` top -b -n 1 | head -3| tail -1 | awk '{print $5}' | sed 's/%//g' | sed 's/id//g' | sed 's/,//g'` 
#cpu使用率
    cpuuse=`awk -v x=100 -v y=$cpufree 'BEGIN{printf "%.2f\n",x-y}'`
#用户数
    user=`who | wc -l`
#cpu负载1s，5s，15s
    cpuload1=` w |grep average |awk '{print $(NF-2)}'|sed 's/,//g'`
    cpuload5=` w |grep average |awk '{print $(NF-1)}'|sed 's/,//g'`
    cpuload15=` w |grep average |awk '{print $(NF)}'`
#空闲内存
    freemem=` free -h|grep - | awk '{print $4}'`
#游戏进程数
    javaprocess=`/usr/local/java/bin/jps -l |grep 'gamebase.jar'|wc -l`
#磁盘空间
    diskusage=`df -h|grep '/data' |awk '{print $5}'`
#cpu空闲率
    cpuidle=` vmstat|tail -n +3 |awk '{print $13}'`
#平均负载5s
    cpuloadnew=`echo $cpuload5|awk -F "." '{print $1}'`
#空闲内存是否大于28G
    freememnew=`echo $freemem|sed 's/G//g'`
    freememnew2=`echo "$freememnew > 28"|bc `
    diskusagenew=`echo $diskusage|sed 's/%//g'`
#    declare -i fileLines
#    fileLines=`sed -n '$=' $1  $iplist`
#    let linesCount=$linesCount+$fileLines
    let filesCount=$filesCount+1
    if [[ "$freememnew2" -eq "1"  && "$cpuloadnew" -lt "13" && "$diskusagenew" -lt "70" && "$ti" -eq "1" ]];then
        
        echo -e "\033[32m$filesCount IP地址：$ip  用户数：$user  cpu使用率 $cpuuse%  平均负载：$cpuload1  $cpuload5  $cpuload15 cpu空闲率：$cpuidle 空闲内存：$freemem  游戏进程数：$javaprocess  磁盘空间使用：$diskusage \033[0m" 


    elif [[ "$freememnew2" -ne "1" ]];then        
        echo -e "\033[32m IP地址：$ip  用户数：$user cpu使用率 $cpuuse% 磁盘空间使用：$diskusage 平均负载：$cpuload1  $cpuload5  $cpuload15 cpu空闲率：$cpuidle \033[0m \033[31m 空闲内存：$freemem \033[0m \033[32m 游戏进程数：$javaprocess \033[0m"
        echo -e "\033[32m cpu使用最高进程：$cpuhigbest    cpu使用第二高进程:$cpuhigbest2      cpu使用最高进程的cpu使用率: $cpuhcp  cpu使用第二高进程的cpu使用率: $cpuhcp2  \033[0m"
        echo -e "\033[32m cpu使用最高进程io读写: $cpuhio  cpu使用第二高进程io读写: $cpuhio2   io使用率：$iouse%                    old : $jold  \033[0m"

    elif [[ "$cpuloadnew" -gt "13" ]];then
        echo -e "\033[32m IP地址：$ip  用户数：$user cpu使用率 $cpuuse% 磁盘空间使用：$diskusage \033[0m  \033[31m 平均负载：$cpuload1  $cpuload5  $cpuload15 \033[0m \033[32m cpu空闲率：$cpuidle 空闲内存：$freemem  游戏进程数：$javaprocess \033[0m"
        echo -e "\033[32m cpu使用最高进程：$cpuhigbest    cpu使用第二高进程:$cpuhigbest2      cpu使用最高进程的cpu使用率: $cpuhcp  cpu使用第二高进程的cpu使用率: $cpuhcp2   \033[0m"
        echo -e "\033[32m cpu使用最高进程io读写: $cpuhio  cpu使用第二高进程io读写: $cpuhio2   io使用率：$iouse%                    old : $jold  \033[0m"

    elif [[ "$diskusagenew" -gt "70" ]];then
        echo -e "\033[32m IP地址：$ip  用户数：$user cpu使用率 $cpuuse% \033[0m  \033[31m 磁盘空间使用：$diskusage \033[0m  \033[32m 平均负载：$cpuload1  $cpuload5  $cpuload15  cpu空闲率：$cpuidle 空闲内存：$freemem  游戏进程数：$javaprocess \033[0m"
        echo -e "\033[32m cpu使用最高进程：$cpuhigbest    cpu使用第二高进程:$cpuhigbest2     cpu使用最高进程的cpu使用率: $cpuhcp  cpu使用第二高进程的cpu使用率: $cpuhcp2   \033[0m"
        echo -e "\033[32m cpu使用最高进程io读写: $cpuhio  cpu使用第二高进程io读写: $cpuhio2   io使用率：$iouse%                   old : $jold  \033[0m"

    elif [[ "$freememnew2" -ne "1"  && "$cpuloadnew" -gt "13" ]];then
        echo -e "\033[32m IP地址：$ip  用户数：$user cpu使用率 $cpuuse%  磁盘空间使用：$diskusage \033[0m  \033[31m 平均负载：$cpuload1  $cpuload5  $cpuload15  空闲内存：$freemem \033[0m \033[32m cpu空闲率：$cpuidle  游戏进程数：$javaprocess \033[0m"
        echo -e "\033[32m cpu使用最高进程：$cpuhigbest    cpu使用第二高进程:$cpuhigbest2     cpu使用最高进程的cpu使用率: $cpuhcp  cpu使用第二高进程的cpu使用率: $cpuhcp2   \033[0m"    
        echo -e "\033[32m cpu使用最高进程io读写: $cpuhio  cpu使用第二高进程io读写: $cpuhio2   io使用率：$iouse%                   old : $jold  \033[0m"

    elif [[ "$cpuloadnew" -gt "13" && "$diskusagenew" -gt "70" ]];then
        echo -e "\033[32m IP地址：$ip  用户数：$user cpu使用率 $cpuuse% \033[0m \033[31m 磁盘空间使用：$diskusage  平均负载：$cpuload1  $cpuload5  $cpuload15 \033[0m  \033[32m 空闲内存：$freemem  cpu空闲率：$cpuidle  游戏进程数：$javaprocess \033[0m"
        echo -e "\033[32m cpu使用最高进程：$cpuhigbest    cpu使用第二高进程:$cpuhigbest2      cpu使用最高进程的cpu使用率: $cpuhcp  cpu使用第二高进程的cpu使用率: $cpuhcp2   \033[0m" 
        echo -e "\033[32m cpu使用最高进程io读写: $cpuhio  cpu使用第二高进程io读写: $cpuhio2   io使用率：$iouse%                    old : $jold  \033[0m"

    elif [[ "$freememnew2" -ne "1" && "$diskusagenew" -gt "70" ]];then
        echo -e "\033[32m IP地址：$ip  用户数：$user cpu使用率 $cpuuse% \033[0m \033[31m 磁盘空间使用：$diskusage \033[0m \033[32m 平均负载：$cpuload1  $cpuload5  $cpuload15 \033[0m  \033[31m 空闲内存：$freemem \033[0m \033[32m cpu空闲率：$cpuidle  游戏进程数：$javaprocess \033[0m"
        echo -e "\033[32m cpu使用最高进程：$cpuhigbest    cpu使用第二高进程:$cpuhigbest2      cpu使用最高进程的cpu使用率: $cpuhcp  cpu使用第二高进程的cpu使用率: $cpuhcp2  \033[0m"
        echo -e "\033[32m cpu使用最高进程io读写: $cpuhio  cpu使用第二高进程io读写: $cpuhio2   io使用率：$iouse%                    old : $jold  \033[0m"

    elif [[ "$freememnew2" -ne "1" && "$diskusagenew" -gt "70" && "$cpuloadnew" -gt "13" ]];then 
         echo -e "\033[32m IP地址：$ip  用户数：$user cpu使用率 $cpuuse% \033[0m \033[31m 磁盘空间使用：$diskusage  平均负载：$cpuload1  $cpuload5  $cpuload15  空闲内存：$freemem \033[0m \033[32m cpu空闲率：$cpuidle  游戏进程数：$javaprocess \033[0m"
     	 echo -e "\033[32m cpu使用最高进程：$cpuhigbest    cpu使用第二高进程:$cpuhigbest2      cpu使用最高进程的cpu使用率: $cpuhcp  cpu使用第二高进程的cpu使用率: $cpuhcp2   \033[0m"        
         echo -e "\033[32m cpu使用最高进程io读写: $cpuhio  cpu使用第二高进程io读写: $cpuhio2   io使用率：$iouse%                    old : $jold  \033[0m"
	fi 
#Help(){
#    echo -e "\033[31;1m#########################################################\033[0m"
#    echo -e "\033[31;1m#Usage: sh $0 -a agent                  #\033[0m"
#    echo -e "\033[31;1m#-h 查看帮助                                            #\033[0m"
#    echo -e "\033[31;1m#-a 指定游戏平台                                        #\033[0m"
#    echo -e "\033[31;1m#########################################################\033[0m"
#    exit
#}
#if [ $# -eq 0 ];then
#   Help
#else
#    case $1 in
#        -h|--help)
#        Help
#        ;;
#        -a|--agent)
#        agent=$2
#        check_every
#        ;;
#        *)
#        Help
#    esac
#fi
