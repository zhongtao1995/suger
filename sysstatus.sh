#!/bin/bash
#. ./get.sh
#. ./color.sh
#
#
#颜色函数设置
###########################################################################################################################
#echo -e "\033[30m 黑色字 \033[0m"
#echo -e "\033[31m 红色字 \033[0m"
#echo -e "\033[32m 绿色字 \033[0m"
#echo -e "\033[33m 黄色字 \033[0m"
#echo -e "\033[34m 蓝色字 \033[0m"
#echo -e "\033[35m 紫色字 \033[0m"
#echo -e "\033[36m 天蓝字 \033[0m"
#echo -e "\033[37m 白色字 \033[0m"

#返回红色字体
red() {
	echo -e "\033[31m$1 $2 $3\033[0m"		
}

#返回绿色字体
green() {
	echo -e "\033[32m$1 $2 $3\033[0m"
}

#返回黄色字体
yellow() {
	echo -e "\033[33m$1 $2 $3\033[0m"
}
#############################################################################################################################
#判断是否具有iotop命令
judgeiotop() {
	flag=$(yum list installed | grep "iotop")
	if [ -n "$flag" ]
	then
		echo -n ""	
	elif [ -z "$flag" ]
	then
		yum install -q -y iotop
		echo -n ""	
	fi
}
judgeiotop
#获取top一次的输出,将输出重定向到/tmp/top.tmp,减少多次查询造成资源消耗,脚本运行缓慢

echo "正在查询数据......"
top -n 1 -b > /tmp/top.tmp
topDir="/tmp/top.tmp"
#获取iostat,同top
iostat -x -k -d 1 3 | grep -v "Device" | grep -v "Linux" | grep -v "^$" | sort -n -k1,1 > /tmp/iostat.tmp
iostatDir="/tmp/iostat.tmp"
#获取iotop,同top
#		iotop  -n 3 -b -u javapro> /tmp/iotop.tmp
#		iotopDir="/tmp/iotop.tmp"
#cpuavg
iostat -c 1 3 | grep -v "^$" | grep -v "avg" | grep -v "Lin" > /tmp/cpu_avg.tmp
avgDir="/tmp/cpu_avg.tmp"
#获取本地ip地址
getLocalIp() {
	echo "$(ifconfig | grep "inet addr:" | grep -v "127.0.0" | awk -F ':' '{print $2}' | awk '{print $1}')"
}

#获取公共ip地址
getPublicIp() {
	echo "$(curl -s icanhazip.com)"
}

#获取在线用户数量
getUsers() {
	echo "$(who | wc -l)"
}

#获取tcp连接数
getTcpLinks() {
	echo "$(netstat -nat | grep -i "80" | wc -l)"
}

#获取java用户
getJavaprouser() {
	user=$(ps -ef | grep java | awk '{print $1}' | grep -v root | head -n 1)
	echo $user
}

#获取java进程数量 
getJavapro() {
#	echo "$(sudo -u $(getJavaprouser) $[ $($(which jps) | wc -l) -1 ])"
	num=$(sudo -u $(getJavaprouser) $(which jps) | wc -l)
	num=$[ $num - 1 ]
	if [ $num -ge 9 ] || [ $num -lt 0 ]
	then
		echo "$(red $num)"
	else
		echo "$(green $num)"
	fi
}


#获取总的cpu使用率
getCpuTotalUsed() {
	#cpu空闲值
	idleNum=$(cat $topDir | grep "Cpu(s)" | awk -F ',' '{print $4}' | awk -F '%' '{print $1}')
	#计算cpu百分比
	percentage=$(printf "%.2f" $(echo "scale=2;100-$idleNum" | bc))
	#返回百分比
	echo "$percentage"
}

#获取总的内存/未使用的内存/内存使用率
getTotalMemoryUsed() {
	#内存总值
	total="$(free -g | sed -n '2,2p' | awk -F: '{print $2}' | awk '{print $1}')"
	#内存使用值
	totalUsed="$(free -g | sed -n '2,2p' | awk -F: '{print $2}' | awk '{print $2}')"
	#缓存区
	buffers="$(free -g | sed -n '2,2p' | awk -F: '{print $2}' | awk '{print $5}')"
	cache="$(free -g | sed -n '2,2p' | awk -F: '{print $2}' | awk '{print $6}')"
	#实际使用量
	truelyUsed="$[$totalUsed - $buffers - $cache]"
	#
	#计算内存使用百分比
	percentage=$(printf "%.2f" $(echo "scale=2;($truelyUsed / $total) * 100" | bc))
	#返回百分比
	echo "$percentage"
}
#获取服务器核心数
getCores() {
	cores=$(lscpu | grep "^CPU(s)" | awk -F ':' '{print $2}')
	echo $cores
}
#obtain load
#uptime / w获取
getOneLoad() {	
	#获取1分钟平均load
	echo "$(uptime | awk -F ',' '{print $4}' | awk -F ':' '{print $2}')"	
}

getFiveLoad() {
	#获取5分钟平均load
	echo "$($1uptime | awk -F ',' '{print $5}')"
}

getFifteenLoad() {
	#获取15分钟平均load
	echo "$(uptime | awk -F ',' '{print $6}')"
}
#####################################################################################################################################

#获得cpu使用率最高的两个进程pid和cpu使用率

getFirst() {
	pid=$(cat $topDir | sed -n '8,$p' | sort -nr -k 9 | head -n 1 | awk '{print $1}')	
	cpu=$(cat $topDir | sed -n '8,$p' | sort -nr -k 9 | head -n 1 | awk '{print $9}')
	com=$(cat $topDir | sed -n '8,$p' | sort -nr -k 9 | head -n 1 | awk '{print $12}')
	echo "$pid,$cpu,$com"
}

getSecond() {
	pid=$(cat $topDir | sed -n '8,$p' | sort -nr -k 9 | head -n 2 | tail -n 1 | awk '{print $1}')
	cpu=$(cat $topDir | sed -n '8,$p' | sort -nr -k 9 | head -n 2 | tail -n 1 | awk '{print $9}')
	com=$(cat $topDir | sed -n '8,$p' | sort -nr -k 9 | head -n 1 | tail -n 1 | awk '{print $12}')
	echo "$pid,$cpu,$com"
}

#获取cpu使用最高两个进程的io读写

getFirstIo() {
	pid=$(echo $(getFirst) | awk -F ',' '{print $1}')
	percentage=$(cat $iotopDir | sed -n '3,$p' | awk '{print $1,$10}' | sed 's/ /,/g' | grep ^$pid, | awk -F ',' '{print $2}')
	echo "$percentage"
}

getSecondIo() {
	pid=$(echo $(getSecond) | awk -F ',' '{print $1}')
	percentage=$(cat $iotopDir | sed -n '3,$p' | awk '{print $1,$10}' | sed 's/ /,/g' | grep ^$pid, | awk -F ',' '{print $2'})
	echo "$percentage"
}
getFirstRW() {
	pid=$(echo $(getFirst) | awk -F ',' '{print $1}')
	re=$(pidstat -d |sed -n '4,$p' | awk '{print $2,$3,$4}' | grep -w "$pid" | awk '{print $2}')	
	w=$(pidstat -d |sed -n '4,$p' | awk '{print $2,$3,$4}' | grep -w "$pid" | awk '{print $3}')
	echo "$pid,$re,$w"
}
getSecondRW() {
	pid=$(echo $(getSecond) | awk -F ',' '{print $1}')
        re=$(pidstat -d |sed -n '4,$p' | awk '{print $2,$3,$4}' | grep -w "$pid" | awk '{print $2}')
        w=$(pidstat -d |sed -n '4,$p' | awk '{print $2,$3,$4}' | grep -w "$pid" | awk '{print $3}')
        echo "${pid},${re},${w}"
}
#cpu使用最高的两个进程
getTotalCpuInformation() {
	pid1=$(echo $(getFirst) | awk -F ',' '{print $1}')
	pid2=$(echo $(getSecond) | awk -F ',' '{print $1}')
	cpu1=$(echo $(getFirst) | awk -F ',' '{print $2}')
	cpu2=$(echo $(getSecond) | awk -F ',' '{print $2}')
	com1=$(echo $(getFirst) | awk -F ',' '{print $3}')
	com2=$(echo $(getSecond) | awk -F ',' '{print $3}')
	read1=$(echo $(getFirstRW) | awk -F ',' '{print $2}')
	write1=$(echo $(getFirstRW) | awk -F ',' '{print $3}')
	read2=$(echo $(getSecondRW) | awk -F ',' '{print $2}')
	write2=$(echo $(getSecondRW) | awk -F ',' '{print $3}')
	echo "cpu使用率最高的两个进程 "
	echo -n "		进程一: pid>>$(green ${pid1}) cpu使用率>>$(red ${cpu1}%) 每秒读>>$(green ${read1}kB_rd/s) 每秒写>>$(green ${write1}kB_wr/s)"
	#first
	if [ $com1="java" ]
	then
		old=$(sudo -u $(getJavaprouser) $(which jstat) -gcutil $pid1 | sed -n '2,2p' | awk '{print $4}')
		if [ $(echo "scale=2;old>80" | bc) -eq 1 ]
		then
			echo "java old 区>>$(red ${old}%)"
		else
			echo "java old 区>>$(green ${old}%)"
		fi
	else
		echo
	fi
	echo 	
	#second	
	echo -n "		进程二: pid>>$(green ${pid2}) cpu使用率>>$(red ${cpu2}%) 每秒读>>$(green ${read2}kB_rd/s) 每秒写>>$(green ${write2}kB_wr/s)"	
	 if [ $com2="java" ]
        then
                old=$(sudo -u $(getJavaprouser) $(which jstat) -gcutil $pid2 | sed -n '2,2p' | awk '{print $4}')
                if [ $(echo "scale=2;old>80" | bc) -eq 1 ]
                then
                        echo "java old 区>>$(red ${old}%)"
                else
                        echo "java old 区>>$(green ${old}%)"
                fi
        else
                echo 
        fi
	echo	
}
#total io use & wait
getTotalIoInformation() {
        lines=$(cat "$iostatDir" | wc -l)
        total=$[$lines / 3]
        a=0
        echo  "服务器读写:"
        while [ $a -lt $total ] 
        do
                line=$[$a * $total + 1]
                line_3=$[$a * $total +3]
                device=$(cat /tmp/iostat.tmp | sed -n "${line},${line_3}p" | sort -nr -k10,10 | awk '{print $1}' | head -n 1)
                iowait=$(cat /tmp/iostat.tmp | sed -n "${line},${line_3}p" | sort -nr -k10,10 | awk '{print $10}' | head -n 1)
                ioUsed=$(cat /tmp/iostat.tmp | sed -n "${line},${line_3}p" | sort -nr -k14,14 | awk '{print $14}' | head -n 1)
#              	echo "$device $iowait $util"
                a=$[$a + 1]
                #判断io使用率是否超过75%
                if [ $(echo "$ioUsed > 75" | bc) -eq 1 ] 
                then
                        ioUsed="$(red ${ioUsed}%)"
                else
                        ioUsed="$(green ${ioUsed}%)"
                fi
                #判断iowait时间是否超过5s
                if [ $(echo "$iowait > 5000" | bc) -eq 1 ]
                then
                        iowait="$(red ${iowait}/ms)"
                else
                        iowait="$(green ${iowait}/ms)"
                fi
                echo "$device{ io_util:${ioUsed}  wait:$iowait}"
        done
}

#cpuavg
cpuavg() {
        avg_iowait=$(cat $avgDir | sort -nr -k4,4 | head -n 1 | awk '{print $4}')
        avg_cpu_idle=$(cat $avgDir | sort  -n -k6,6 | head -n 1 | awk '{print $6}')
	echo "cpu 平均idle和iowait:"
        echo "	iowait>>$(green $avg_iowait /ms) idle>>$(green $avg_cpu_idle %)"
}
#iotop first and second 
io() {
        line2=$[$(cat $iotopDir | grep -n "TID  PRIO  USER     DISK READ  DISK WRITE  SWAPIN      IO    COMMAND" | sed -n '2,2p' | awk -F ':' '{print $1}') + 1] 
	line2_1=$[$line2 + 1]
        line3=$[$(cat $iotopDir | grep -n "TID  PRIO  USER     DISK READ  DISK WRITE  SWAPIN      IO    COMMAND" | sed -n '3,3p' | awk -F ':' '{print $1}') + 1]
        line3_1=$[$line3 + 1]
        tmpDir="/tmp/iotop.tmp.tmp"
        cat $iotopDir | sed -n '3,4p' > /tmp/iotop.tmp.tmp
        cat $iotopDir | sed -n "${line2},${line2_1}p" >> /tmp/iotop.tmp.tmp
        cat $iotopDir | sed -n "${line3},${line3_1}p" >> /tmp/iotop.tmp.tmp
        firstpid="$(cat $tmpDir | sort -nr -k 10 | awk '{print $1}' | head -n 1)"
        firstuse="$(cat $tmpDir | sort -nr -k 10 | awk '{print $10}' | head -n 1)"
        pids="$(cat $tmpDir | sort -nr -k 10 | awk '{print $1,$10}' | grep -v $firstpid)"
        secondpid="$(echo $pids | awk '{print $1}')"
        seconduse="$(echo $pids | awk '{print $2}')"
	echo "服务器占用io最高的两个进程:"
	echo "		第一个进程:pid>>$(green $firstpid) io使用百分比>>$(red $firstuse %)"
	echo "		第二个进程:pid>>$(green $secondpid) io使用百分比>>$(red $seconduse %)"
}
#判断cpu使用是否超过75%
cpu() {
	flag=$(echo "scale=2;$cpuTotalUsed > 75" | bc)
	if [ $flag -eq 1 ]
	then
		echo "$(red $cpuTotalUsed%)"
	else
		echo "$(green $cpuTotalUsed%)"
	fi
}

#判断memory使用是否超过75%
mem() {
	flag=$(echo "scale=2;$memTotalUsed > 75" | bc)
        if [ $flag -eq 1 ]
        then
                echo "$(red $memTotalUsed%)"
        else
                echo "$(green $memTotalUsed%)"
        fi	
}

#判断服务器负载情况,用来决定是否处理过载情况
load() {
        cores=$(getCores)
        #如果等于1超负荷
        loadOne=$(echo "scale=2;$(getOneLoad) > ( 2 * $cores )" | bc)
        loadFive=$(echo "scale=2;$(getFiveLoad) > ( 2 * $cores )" | bc)
        loadFifteenLoad=$(echo "sclae=2;$(getFifteenLoad) > (2 * $cores )" | bc)
        if [ $loadOne -eq 1 ] || [ $loadFive -eq 1 ] || [ $loadFifteenLoad -eq 1 ]
	then
		echo "over"
	else 
		echo "low"
	fi

}
#负载过高时的进程
high() {
	if [ $(load)="over" ]
	then
		#ioinformation=$(getTotalIoInformation)
		#cpuinformation=$(getTotalCpuInformation)
		getTotalIoInformation
		getTotalCpuInformation
#		io
		cpuavg
	elif [ $(load)="low" ]
	then	
		exit 0
	fi
		
}
#用来判定负载输出颜色
loadEvery() {
	cores=$(getCores)
        #如果等于1超负荷
        loadOne=$(echo "scale=2;$(getOneLoad) > ( 2 * $cores )" | bc)
        loadFive=$(echo "scale=2;$(getFiveLoad) > ( 2 * $cores )" | bc)
        loadFifteenLoad=$(echo "sclae=2;$(getFifteenLoad) > (2 * $cores )" | bc)
	one=""
	five=""
	fifteen=""
	#one
	if [ $loadOne -eq 1 ]
	then
		one=$(echo "$(red $(getOneLoad))")
	else
		one=$(echo "$(green $(getOneLoad))")
	fi
	#five
	if [ $loadFive -eq 1 ]
        then
                five=$(echo "$(red $(getFiveLoad))")
        else
                five=$(echo "$(green $(getFiveLoad))")
        fi
	#fifteen
	if [ $loadFifteenLoad -eq 1 ]
        then
                fifteen=$(echo "$(red $(getFifteenLoad))")
        else
                fifteen=$(echo "$(green $(getFifteenLoad))")
        fi		
	echo "$one $five $fifteen"
}


ipAddress=$(getPublicIp)
#获取在线用户数
loginedUsers=$(getUsers)
#获取java进程数量
javaProNum=$(getJavapro)
#获取tcp连接数
tcplinks=$(getTcpLinks)
#获取总的cpu使用率
cpuTotalUsed=$(getCpuTotalUsed)
#获取总的内存使用率
memTotalUsed=$(getTotalMemoryUsed)
#打印ip地址
echo -n "服务器IP地址："
echo "$(green $ipAddress)"
#打印在线用户数
echo -n "在线用户数:"
echo "$(green $loginedUsers)"
#打印java进程数量
echo -n "java 进程数:"
echo "$javaProNum"
#打印tcp连接数
echo -n "tcp 连接数:"
echo "$(green $tcplinks)"
#打印cpu使用率
echo -n "cpu 使用率:"
echo "$(cpu)"
#打印mem使用率
echo -n "memory 使用率:"
echo "$(mem)"
echo -n "服务器当前负载:"
echo "$(loadEvery)"
high
