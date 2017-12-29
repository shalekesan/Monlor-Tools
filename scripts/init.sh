#!/bin/ash
#copyright by monlor
logger -p 1 -t "【Tools】" "初始化脚本init.sh启动..."
source /etc/monlor/scripts/base.sh
mount -o remount,rw /

result=`ps | grep init.sh | grep -v grep | wc -l`
if [ "$result" -gt '2' ]; then
        logsh "【Tools】" "检测到init.sh已在运行"
        exit
fi

logsh "【Tools】" "检查工具箱uci配置文件"
if [ ! -f "/etc/config/monlor" ]; then
	$monlorpath/config/uciset.sh
fi

logsh "【Tools】" "检查环境变量配置"
result=$(cat /etc/profile | grep monlor | wc -l)
if [ "$result" == 0 ]; then
	sed -i "s#/usr/sbin#/usr/sbin:$monlorpath/scripts#" /etc/profile
fi

logsh "【Tools】" "检查定时任务配置"
result=$(cat /etc/crontabs/root | grep monitor.sh | wc -l)
if [ "$result" == '0' ]; then
	echo "* * * * * $monlorpath/scripts/monitor.sh " >> /etc/crontabs/root
fi

result=$(cat /etc/crontabs/root | grep dayjob.sh | wc -l)
if [ "$result" == '0' ]; then
	echo "30 5 * * * $monlorpath/scripts/dayjob.sh " >> /etc/crontabs/root
fi

logsh "【Tools】" "检查工具箱开机启动配置"
result=$(cat /etc/firewall.user | grep init.sh | wc -l) > /dev/null 2>&1
if [ "$result" == '0' ]; then
	echo "$monlorpath/scripts/init.sh" > /etc/firewall.user
fi

# logsh "【Tools】" "检查工具箱配置文件"
# if [ ! -f "$monlorconf" ]; then
# 	cp $monlorpath/config/monlor.conf $monlorconf
# 	chmod +x $monlorconf
# fi
logsh "【Tools】" "获取更新插件列表(每天一次)"
rm -rf /tmp/applist.txt
curl -skLo /tmp/applist.txt $monlorurl/config/applist.txt
if [ $? -eq 0 ]; then
	mv /tmp/applist.txt $monlorpath/config
else 
	logsh "【Tools】" "获取失败，检查网络问题！"
fi

logsh "【Tools】" "获取插件版本信息"
rm -rf /tmp/tools_version.txt
curl -skLo /tmp/tools_version.txt $monlorurl/config/version.txt 
mkdir -p /tmp/version > /dev/null 2>&1
cat $monlorpath/config/applist.txt | while read line
do
	[ ! -z $line ] && curl -skLo /tmp/version/$line.txt $monlorurl/apps/$line/config/version.txt 
done


logsh "【Tools】" "运行monitor.sh监控脚本"
$monlorpath/scripts/monitor.sh

logsh "【Tools】" "检查迅雷配置"
xunlei_enable=$(uci -q get monlor.tools.xunlei)
xunlei_enabled=$(ps | grep -E 'etm|xunlei' | grep -v grep | wc -l)
if [ "$xunlei_enable" == '1' -a "$xunlei_enabled" != '0' ]; then
	[ -f /usr/sbin/xunlei.sh ] && mv /usr/sbin/xunlei.sh /usr/sbin/xunlei.sh.bak
	killall xunlei > /dev/null 2>&1
	killall etm > /dev/null 2>&1
	/etc/init.d/xunlei stop &
	# rm -rf $userdisk/TDDOWNLOAD 
	# rm -rf $userdisk/ThunderDB
else
	[ ! -f /usr/sbin/xunlei.sh ] && mv /usr/sbin/xunlei.sh.bak /usr/sbin/xunlei.sh
	/etc/init.d/xunlei start &
fi

logsh "【Tools】" "检查ssh外网访问配置"
ssh_enabled=$(iptables -S | grep -c "monlor-ssh")
if [ "$ssh_enabled" == '0' ]; then
	iptables -I INPUT -p tcp --dport 22 -m comment --comment "monlor-ssh" -j ACCEPT > /dev/null 2>&1
fi

logsh "【Tools】" "运行用户自定义脚本"
$monlorpath/scripts/userscript.sh

