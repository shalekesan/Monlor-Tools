#!/bin/bash
cd ~/Documents/GitHub/Monlor-Tools
find  .  -name  '.*'  -type  f  -print  -exec  rm  -rf  {} \;
if [ `uname -s` == "Darwin" ]; then
	md5=md5 
	flag="\"\""
else 
	md5=md5sum
	flag=""
fi

pack() {
	mkdir -p monlor/apps/
	cp -rf config/ monlor/config
	cp -rf scripts/ monlor/scripts
	if [ "$1" == "test" ]; then
		sed -i $flag '4s/monlorurl/#monlorurl/' monlor/scripts/base.sh
		sed -i $flag '5s/#//' monlor/scripts/base.sh
	fi
	tar -zcvf monlor.tar.gz monlor/
	#zip -r monlor.zip monlor/
	rm -rf appstore/*
	mv monlor.tar.gz appstore/
	rm -rf monlor/
	cd apps/
	ls | while read line
	do
		tar -zcvf $line.tar.gz $line/
	done 
	cd ..
	mv apps/*.tar.gz appstore/
	$md5 appstore/* > md5.txt
}

localgit() {
	git add .
	git commit -m "`date +%Y-%m-%d`"
}

github() {
	git remote rm origin
	git remote add origin https://github.com/monlor/Monlor-Tools.git
	git push origin master
}

coding() {
	git remote rm origin
	git remote add origin https://git.coding.net/monlor/Monlor-Tools.git
	git push origin master
}

test() {
	git remote rm origin
	git remote add origin https://git.coding.net/monlor/Monlor-Test.git
	git push origin master
}

case $1 in 
	all) 
		pack
		localgit
		github
		coding
		;;
	github)
		pack
		localgit
		github		
		;;
	coding)
		pack
		localgit
		coding
		;;
	push)
		localgit
		github
		coding
		;;
	pack) 
		pack
		;;
	test)
		pack test
		localgit
		test
		;;
esac
