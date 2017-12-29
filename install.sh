#!/bin/ash
#copyright by monlor

clear
echo -n "是否要安装Monlor Tools工具箱? 按任意键继续(Ctrl + C 退出)."
read answer
model=$(cat /proc/xiaoqiang/model)
if [ "$model" == "R1D" -o "$model" == "R2D" -o "$model" == "R3D"  ]; then
	userdisk="/userdisk/data"
elif [ "$model" == "R3" -o "$model" == "R3P" -o "$model" == "R3G" ]; then
	# if [ $(df|grep -Ec '\/extdisks\/sd[a-z][0-9]?') -eq 0 ]; then
	# 	echo -n "没有检测到外置储存，是否将配置文件将放在/etc目录?[y/n] "
	# 	read answer
	# 	[ "$answer" == 'y' ] && userdisk=/etc || exit
	# else
	userdisk=$(df|awk '/\/extdisks\/sd[a-z][0-9]?/{print $6;exit}')
	# fi
else
	echo "不支持你的路由器！"
	exit
fi

mount -o remount,rw /
echo "下载工具箱文件..."
rm -rf /tmp/monlor.tar.gz > /dev/null 2>&1
curl -skLo /tmp/monlor.tar.gz https://coding.net/u/monlor/p/Monlor-Tools/git/raw/master/appstore/monlor.tar.gz
[ $? -ne 0 ] && echo "文件下载失败！" && exit
echo "解压工具箱文件"
tar -zxvf /tmp/monlor.tar.gz -C /tmp > /dev/null 2>&1
[ $? -ne 0 ] && echo "文件解压失败！" && exit
cp -rf /tmp/monlor /etc
chmod -R +x /etc/monlor/*
echo "初始化工具箱..."
[ ! -f "/etc/config/monlor" ] && cp -rf /etc/monlor/config/monlor.uci /etc/config/monlor
uci set monlor.tools.userdisk="$userdisk"
uci commit monlor

# if [ -f "$userdisk/.monlor.conf.bak" ]; then
# 	echo -n "检测到备份的配置，是否要恢复？[y/n] "
# 	read answer
# 	if [ "$answer" == 'y' ]; then
# 		mv $userdisk/.monlor.conf.bak $userdisk/.monlor.conf
# 	else
# 		[ ! -f $userdisk/.monlor.conf ] && cp /etc/monlor/config/monlor.conf $userdisk/.monlor.conf
# 	fi
# fi
kill -9 $(ps | grep monlor | grep -v grep | awk '{print$1}') > /dev/null 2>&1
/etc/monlor/scripts/init.sh
rm -rf /tmp/monlor.tar.gz
rm -rf /tmp/monlor
echo "工具箱安装完成!"

echo "运行monlor命令即可配置工具箱"
rm -rf /tmp/install.sh
