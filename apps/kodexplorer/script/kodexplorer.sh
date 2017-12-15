#!/bin/ash /etc/rc.common
source /etc/monlor/scripts/base.sh

START=95
STOP=95
SERVICE_USE_PID=1
SERVICE_WRITE_PID=1
SERVICE_DAEMONIZE=1

service=KodExplorer
appname=kodexplorer
port=81
PHPBIN=/opt/bin/spawn-fcgi
NGINXBIN=/opt/sbin/nginx
NGINXCONF=/opt/etc/nginx/nginx.conf
PHPCONF=/opt/etc/php.ini
WWW=/opt/share/nginx/html
LOG=/var/log/$appname.log

set_config() {

	if [ ! -f $PHPBIN ] || [ ! -f $NGINXBIN ]; then
	 	logsh "【$service】" "检测到第一次启动【$appname】服务， 正在安装..."
	 	opkg update
		opkg install php7-cgi php7-mod-curl php7-mod-gd php7-mod-iconv php7-mod-json php7-mod-mbstring php7-mod-opcache php7-mod-session php7-mod-zip nginx spawn-fcgi zoneinfo-core zoneinfo-asia
		#修改nginx配置文件
		logsh "【$service】" "修改nginx配置文件"
		sed -i 's/nobody/root/' $NGINXCONF
		sed -i 's/listen       80;/listen       81;/' $NGINXCONF
		phpstart=`cat $NGINXCONF | grep -nC 3 fastcgi_index | cut -d- -f1 | head -1`
		phpend=`cat $NGINXCONF | grep -nC 3 fastcgi_index | cut -d- -f1 | tail -1`
		[ ! -z "$phpstart" -a ! -z "phpend" ] && sed -i ""$phpstart","$phpend"s/#//g" $NGINXCONF
		sed -i '/#/d' $NGINXCONF
		sed -i 's/index.html/index.php index.html/' $NGINXCONF
		sed -i 's#root           html#root           /opt/share/nginx/html#' $NGINXCONF
		sed -i 's/\/scripts/\$document_root/' $NGINXCONF
		sed -i 's/9000/9009/' $NGINXCONF
		#修改php配置文件
		logsh "【$service】" "修改php配置文件"
		docline=`cat $PHPCONF | grep -n doc_root | cut -d: -f1 | tail -1`
		baseline=`cat $PHPCONF | grep -n open_basedir | cut -d: -f1 | head -1`
		[ ! -z "$docline" ] && sed -i ""$docline"s#.*#doc_root = \"/opt/share/nginx/html\"#" $PHPCONF
		[ ! -z "$baseline" ] && sed -i ""$baseline"s#.*#open_basedir = \"/opt/share/nginx/html\"#" $PHPCONF
		sed -i 's/memory_limit = 8M/memory_limit = 20M/' $PHPCONF
		sed -i 's/upload_max_filesize = 2M/upload_max_filesize = 2000M/' $PHPCONF

		echo "<?php phpinfo(); ?>" > $WWW/info.php
		rm -rf $WWW/index.html
	fi
	if [ ! -d /opt/share/nginx/html/app/kod/ ]; then
		logsh "【$service】" "未检测到$appname文件，正在下载"
		curl -sLo /tmp/kodexplorer.zip $monlorurl/temp/kodexplorer.zip
		[ $? -ne 0 ] && logsh "【$service】" "$appname文件下载失败" && exit
		unzip /tmp/kodexplorer.zip -d $WWW
		rm -rf /tmp/kodexplorer.zip
	fi
	path=$(uci get monlor.$appname.path)
	if [ ! -z "$path" ]; then
		if [ -d $WWW/data/User/admin/home ]; then
			mount -o blind $path $WWW/data/User/admin/home
		else
			logsh "【$service】" "检测到$appname服务未配置，无法挂载管理目录"
		fi
	fi
}

start () {

	result=$(ps | grep -E 'nginx|php-cgi' | grep -v sysa | grep -v grep | wc -l)
    	if [ "$result" != '0' ];then
		logsh "【$service】" "$appname已经在运行！"
		exit 1
	fi
	logsh "【$service】" "正在启动$appname服务... "
	#检查entware状态
	result1=$(uci -q get monlor.entware)
	result2=$(ls /opt | grep etc)
	if [ -z "$result1" ] || [ -z "$result2" ]; then 
		logsh "【$service】" "检测到【Entware】服务未启动或未安装"
		exit
	else
		result3=$(echo $PATH | grep opt)
		[ -z "$result3" ] && export PATH=/opt/bin/:/opt/sbin:$PATH
	fi

	set_config
	
	iptables -I INPUT -p tcp --dport $port -m comment --comment "monlor-$appname" -j ACCEPT 
	/opt/etc/init.d/S80nginx start >> /tmp/messages 2>&1
	if [ $? -ne 0 ]; then
		logsh "【$service】" "启动nginx服务失败！"
		exit
	fi
	$PHPBIN -a 127.0.0.1 -p 9009 -C 2 -f /opt/bin/php-cgi >> /tmp/messages 2>&1   
	if [ $? -ne 0 ]; then
                logsh "【$service】" "启动php服务失败！"
		exit
        fi
        logsh "【$service】" "$appname服务启动完成"

}

stop () {

	logsh "【$service】" "正在停止$appname服务... "
	/opt/etc/init.d/S80nginx stop >> /tmp/messages 2>&1
	killall php-cgi >> /tmp/messages 2>&1
	umount $WWW/data/User/admin/home > /dev/null 2>&1
	iptables -D INPUT -p tcp --dport $port -m comment --comment "monlor-$appname" -j ACCEPT > /dev/null 2>&1

}

restart () {

	stop
	sleep 1
	start

}

