#!/bin/sh
#copyright by monlor

monlorurl="https://coding.net/u/monlor/p/Monlor-Tools/git/raw/master"
#monlorurl="https://coding.net/u/monlor/p/Monlor-Test/git/raw/master"
#monlorurl="https://raw.githubusercontent.com/monlor/Monlor-Tools/master"
monlorpath="/etc/monlor"
userdisk=$(uci -q get monlor.tools.userdisk)
monlorconf="$monlorpath/scripts/monlor"

result=$(cat /proc/xiaoqiang/model)
if [ "$result" == "R1D" -o "$result" == "R2D" -o "$result" == "R3D"  ]; then
	model=arm
elif [ "$result" == "R3" -o "$result" == "R3P" -o "$result" == "R3G" ]; then
	model=mips
fi

checkuci() {
	if [ -z $(uci -q get monlor.$1) ]; then
		echo 1
	else
		echo 0
	fi
}

cutsh() {

	test1=$1
	test2=$2
	[ -z "$test2" ] && test2=$test1
	echo `echo $test1 | cut -d, -f$test2`

}

logsh() {
	
	logger -s -p 1 -t "$1" "$2"
	
}

monitor() {
	appname=$1
	service=`uci -q get monlor.$1.service`
	if [ -z $appname ] || [ -z $service ]; then
		logsh "【Tools】" "uci配置出现问题！"
	fi
	App_enable=$(uci -q get monlor.$appname.enable) 
	result=$($monlorpath/apps/$appname/script/$appname.sh status | tail -1) 
	restart=$(uci get monlor.$appname.restart)
	#执行重启命令
	if [ "$restart" == '1' ]; then 
		logsh "【$service】" "$appname配置已修改，正在重启$appname服务..." 
		restartline=$(cat $monlorconf | grep -n "$appname"restart | cut -d: -f1) 
		if [ ! -z $restartline ];then   
			if [ "$App_enable" == '1' ]; then
				$monlorpath/apps/$appname/script/$appname.sh restart 
			else
				$monlorpath/apps/$appname/script/$appname.sh stop
			fi
			sed -i "`expr $restartline + 1`s/.*/\$uciset\.restart=\"0\"/" $monlorconf 
		else   
			logsh "【$service】" "$appname配置文件出现问题"
		fi 
		return  
	fi
	#检查插件运行异常情况
	result=$($monlorpath/apps/$appname/script/$appname.sh status | tail -1) 
	if [ "$App_enable" == '1' -a "$result" == '0' ]; then
		logsh "【$service】" "$appname运行异常，正在重启..." 
		$monlorpath/apps/$appname/script/$appname.sh restart 
	elif [ "$App_enable" == '0' -a "$result" == '1' ]; then
		logsh "【$service】" "$appname配置已修改，正在停止$appname服务..."   
		$monlorpath/apps/$appname/script/$appname.sh stop
	fi

}
