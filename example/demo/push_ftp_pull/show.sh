#!/bin/bash

cd ./push

echo '[Server@Push] 模拟上传到 ftp 服务器'
./push.sh
sleep 2

cd ../pull

echo -e "\n\n[Server@Pull] 模拟从 ftp 服务器下载（模拟顺利，一次成功）" && sleep 3
./pull.sh 0
sleep 2

echo -e "\n\n[Server@Pull] 模拟从 ftp 服务器下载（模拟故障，重试成功）" && sleep 3
./pull.sh 2
sleep 2

echo -e "\n\n[Server@Pull] 模拟从 ftp 服务器下载（模拟持续故障，超过重试次数）" && sleep 3
./pull.sh 5
sleep 2
