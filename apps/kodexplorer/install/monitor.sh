appname=kodexplorer #monlor-kodexplorer
App_enable=$(uci get monlor.$appname.enable)  #monlor-kodexplorer
result=$(ps | grep nginx | grep -v sysa | grep -v grep | wc -l)  #monlor-kodexplorer
if [ "$App_enable" = '1' ];then  #monlor-kodexplorer
	if [ `uci get monlor.$appname.restart` -eq 1 ]; then  #monlor-kodexplorer
		logsh "【KodExplorer】" "kodexplorer配置已修改，正在重启kodexplorer服务..."  #monlor-kodexplorer
		restartline=$(cat $monlorconf | grep -n kodrestart | cut -d: -f1)  #monlor-kodexplorer
		if [ ! -z $restartline ];then    #monlor-kodexplorer
			sed -i "`expr $restartline + 1`s/.*/\$uciset\.restart=\"0\"/" $monlorconf  #monlor-kodexplorer
		else    #monlor-kodexplorer
			logsh "【KodExplorer】" "kodexplorer配置文件出现问题"    #monlor-kodexplorer
		fi    #monlor-kodexplorer
		$monlorpath/apps/$appname/script/$appname.sh restart  #monlor-kodexplorer
	elif [ "$result" == '0' ]; then #monlor-kodexplorer
		logsh "【KodExplorer】" "kodexplorer运行异常，正在重启..."  #monlor-kodexplorer
		$monlorpath/apps/$appname/script/$appname.sh restart  #monlor-kodexplorer
	fi  #monlor-kodexplorer
elif [ "$App_enable" = '0' ];then  #monlor-kodexplorer
	if [ "$result" != '0' ]; then    #monlor-kodexplorer
		logsh "【KodExplorer】" "kodexplorer配置已修改，正在停止kodexplorer服务..."    #monlor-kodexplorer
		$monlorpath/apps/$appname/script/$appname.sh stop    #monlor-kodexplorer
	fi    #monlor-kodexplorer
fi  #monlor-kodexplorer

