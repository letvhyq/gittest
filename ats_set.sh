#!/bin/bash

remove_dev='xxxxxx' 
for k in `df -h|grep "dev/sd"|awk '{print $1}'|sed 's/[0-9].*//g'`
    do
        remove_dev+=\|$k #找出已经挂载的盘，要排除这些盘
    done

ssd=`hwconfig|grep SSD|awk '{print "/dev/"$2}'|egrep -v "$remove_dev"`  #找出未挂载的ssd盘符

remove_ssd='xxxxxx'
for k in $ssd
    do 
        remove_ssd+=\|$k
    done

/bin/sed -i 's/^\/dev\/sd.*//g' /etc/trafficserver/storage.config
/bin/sed -i '/^$/d' /etc/trafficserver/storage.config
/sbin/fdisk -l|grep "Disk /dev/sd"|egrep -v "$remove_dev|$remove_ssd"|awk '{print $2}'|sed 's/://g' >>/etc/trafficserver/storage.config    #非裸盘和ssd盘不写入storage.config

/bin/sed -i "s#LOCAL proxy.config.cache.interim.storage STRING .*#LOCAL proxy.config.cache.interim.storage STRING $ssd#g" /etc/trafficserver/records.config  #ssd盘写入records.config


udev_set=''
for k in `/sbin/fdisk -l|grep "Disk /dev/sd"|egrep -v "$remove_dev"|awk '{print $2}'|sed 's/\/dev\/sd\(.\):/\1/g'`
    do
        udev_set+=$k   #找出裸盘最后一个字母
    done

echo SUBSYSTEM==\"block\", KERNEL==\"sd[$udev_set]\", OWNER=\"ats\",GROUP=\"ats\" >/etc/udev/rules.d/99-ats.rules

/sbin/udevadm trigger --subsystem-match=block

/etc/init.d/trafficserver restart
