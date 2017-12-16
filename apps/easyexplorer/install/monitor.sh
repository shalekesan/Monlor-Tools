appname=easyexplorer #monlor-easyexplorer
App_enable=$(uci get monlor.$appname.enable)  #monlor-easyexplorer
result=$(ps | grep $monlorpath | grep easyexplorer | grep -v grep | wc -l)  #monlor-easyexplorer
if [ "$App_enable" = '1' ];then  #monlor-easyexplorer
	if [ `uci get monlor.$appname.restart` -eq 1 ]; then  #monlor-easyexplorer
		logsh "【EasyExplorer】" "easyexplorer配置已修改，正在重启easyexplorer服务..."  #monlor-easyexplorer
		restartline=$(cat $monlorconf | grep -n easyexplorerrestart | cut -d: -f1)  #monlor-easyexplorer
		if [ ! -z $restartline ];then    #monlor-easyexplorer
			sed -i "`expr $restartline + 1`s/.*/\$uciset\.restart=\"0\"/" $monlorconf  #monlor-easyexplorer
		else    #monlor-easyexplorer
			logsh "【EasyExplorer】" "easyexplorer配置文件出现问题"    #monlor-easyexplorer
		fi    #monlor-easyexplorer
		$monlorpath/apps/$appname/script/$appname.sh restart  #monlor-easyexplorer
	elif [ "$result" == '0' ]; then #monlor-easyexplorer
		logsh "【EasyExplorer】" "easyexplorer运行异常，正在重启..."  #monlor-easyexplorer
		$monlorpath/apps/$appname/script/$appname.sh restart  #monlor-easyexplorer
	fi  #monlor-easyexplorer
elif [ "$App_enable" = '0' ];then  #monlor-easyexplorer
	if [ "$result" != '0' ]; then    #monlor-easyexplorer
		logsh "【EasyExplorer】" "easyexplorer配置已修改，正在停止easyexplorer服务..."    #monlor-easyexplorer
		$monlorpath/apps/$appname/script/$appname.sh stop    #monlor-easyexplorer
	fi    #monlor-easyexplorer
fi  #monlor-easyexplorer

