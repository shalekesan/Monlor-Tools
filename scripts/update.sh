#!/bin/ash
#copyright by monlor
source /etc/monlor/scripts/base.sh

logsh "【Tools】" "正在更新工具箱程序... "
#检查更新
rm -rf /tmp/version.txt
curl -skLo /tmp/version.txt $monlorurl/config/version.txt 
[ $? -ne 0 ] && logsh "【Tools】" "检查更新失败！" && exit
newver=$(cat /tmp/version.txt)
oldver=$(cat $monlorpath/config/version.txt)
logsh "【Tools】" "当前版本$oldver，最新版本$newver"
[ "$newver" == "$oldver" ] && logsh "【Tools】" "工具箱已经是最新版！" && exit
logsh "【Tools】" "版本不一致，正在更新工具箱..."
rm -rf /tmp/monlor.tar.gz
rm -rf /tmp/monlor
result=$(wget.sh "/tmp/monlor.tar.gz" "$monlorurl/appstore/monlor.tar.gz")
[ "$result" != '0' ] && logsh "【Tools】" "文件下载失败！" && exit
logsh "【Tools】" "解压工具箱文件"
tar -zxvf /tmp/monlor.tar.gz -C /tmp > /dev/null 2>&1
[ $? -ne 0 ] && logsh "【Tools】" "文件解压失败！" && exit
logsh "【Tools】" "更新工具箱脚本文件"
rm -rf /tmp/monlor/scripts/dayjob.sh
rm -rf /tmp/monlor/scripts/monlor
cp /tmp/monlor/scripts/* $monlorpath/scripts
logsh "【Tools】" "更新工具箱配置文件"
cp /tmp/monlor/config/* $monlorpath/config
logsh "【Tools】" "赋予可执行权限"
chmod -R +x $monlorpath/scripts/*
chmod -R +x $monlorpath/config/*

#删除临时文件
rm -rf /tmp/monlor.tar.gz
rm -rf /tmp/monlor
logsh "【Tools】" "工具箱更新完成！"