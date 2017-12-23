#!/bin/ash
#copyright by monlor
logger -p 1 -t "【Tools】" "监测脚本monitor.sh启动..."
source /etc/monlor/scripts/base.sh

[ ! -f "$monlorconf" ] && logsh "【Tools】" "找不到配置文件，工具箱异常！" && exit
result=$(ps | grep {monitor.sh} | grep -v grep | wc -l)
[ "$result" -gt '2' ] && logsh "【Tools】" "检测到monitor.sh已在运行" && exit
# result=$(cat /tmp/messages | wc -l)
# if [ "$result" -gt 12000 ]; then
# 	logsh "【Tools】" "检测到系统日志占用内存过多，正在清除..."
#	echo > /tmp/messages
# fi

logger -s -t "【Tools】" "运行工具箱配置文件，检查配置更新"
$userdisk/.monlor.conf
uci commit monlor
logger -s -t "【Tools】" "检查软件安装配置"
uci show monlor | grep install_ | awk -F "_|=" '{print$2}' | while read line
do
	install=$(uci get monlor.tools.install_$line)    #0表示不安装，1表示安装
	installed=$(checkuci $line)    #0表示uci存在，已安装
	if [ "$install" == '1' ] && [ "$installed" == '1' ]; then
		logsh "【Tools】" "$line配置文件已修改，正在安装$line服务..."
		$monlorpath/scripts/appmanage.sh add $line
	fi
	if [ "$install"  == '0' ] && [ "$installed" == '0' ]; then
		md5_1=$(md5sum $monlorconf)
		md5_2=$(md5sum $monlorpath/config/monlor.conf)
		if [ "$md5_1" != "$md5_2" ]; then
			logsh "【Tools】" "$line配置文件已修改，正在卸载$line服务..."
			$monlorpath/scripts/appmanage.sh del $line
		fi
	fi
done
logger -s -t "【Tools】" "检查工具箱卸载配置"
result=$(uci -q get monlor.tools.uninstall)
if [ "$result" == '1' ]; then
	sleep 60 && $monlorpath/scripts/uninstall.sh &
	exit
fi
logger -s -t "【Tools】" "检查工具箱更新配置"
result=$(uci -q get monlor.tools.update)
if [ "$result" == '1' ]; then
	$monlorpath/scripts/update.sh
	[ $? -ne 0 ] && logsh "【Tools】" "更新失败！" && exit
fi
#检查samba共享目录
logger -s -t "【Tools】" "检查samba共享目录配置"
samba_path=$(uci -q get monlor.tools.samba_path)
if [ ! -z "$samba_path" ]; then
	result=$(cat /etc/samba/smb.conf | grep -A 5 XiaoMi | grep -w $samba_path | awk '{print$3}')
	if [ "$result" != "$samba_path" ]; then
		logsh "【Tools】" "检测到samba路径被修改, 正在设置..."
		cp /etc/samba/smb.conf /tmp/smb.conf.bak
		sambaline=$(grep -A 1 -n "XiaoMi" /etc/samba/smb.conf | tail -1 | cut -d- -f1)
		[ ! -z "$sambaline" ] && sed -i ""$sambaline"s#.*#        path = $samba_path#" /etc/samba/smb.conf
		[ $? -ne 0 ] && mv /tmp/smb.conf.bak /etc/samba/smb.conf || rm -rf /tmp/smb.conf.bak
	fi
fi

#监控运行状态
logger -s -t "【Tools】" "检查插件运行状态"
uci show monlor | grep =config | grep -v tools | awk -F "\.|=" '{print$2}' | while read line
do
	monitor $line
done
