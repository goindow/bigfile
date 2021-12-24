#!/bin/bash

# 写入文件
echo 'Hello World!' > ./data
echo '生成源文件'
echo '  Hello World!' && sleep 0.5

# 分片
../../../../bigfile.sh shard -t -b 40 -d ./shards/ ./data &> /dev/null
test $? -eq 0 && echo '压缩分片' || echo '分片失败'

sleep 0.5

# 推送
cp ./shards/* ../ftp/
echo '推送完成'
