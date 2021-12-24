# 重拉次数
recount=0
# 重拉次数限制
recount_limit=3

# $1 模拟失败次数，默认 1 次
# $2 当前重拉次数
function damage() {
  if test $2 -lt $1; then
    echo "模拟损坏 $((1+$recount)) 次" && sleep 0.5
    if test $2 -eq 0; then
      echo > ./shards/shard_aa
      echo > ./shards/shard_ab
    else
      echo > ./shards/shard_ab
    fi
  fi
}

# 1. 拉取 md5 文件
cp ../ftp/md5 ./shards/
echo '拉取 md5 文件' && sleep 0.5

shards=$(cat ./shards/md5 | grep -v 'source' | cut -d ' ' -f 2 )
while
  ### 循环语句 ###
  test $recount -gt $recount_limit && echo '已达最大重试次数，退出程序!' && exit 1
  echo "--------------- $recount ---------------"
  
  # 2. 拉取
  test $recount -eq 0 && echo "拉取全部分片" || echo "拉取损坏分片[重拉 $recount 次]"
  for shard in $shards; do
    cp ../ftp/$shard ./shards/
    sleep 0.5 && echo "  $shard"
  done
  
  # 模拟分片损坏
  damage ${1:-1} $recount

  # 3. 合并
  ../../../../bigfile.sh merge ./shards/md5 &> /dev/null

  if test $? -eq 0; then
    ## 4. 合并成功
    shards=
    echo "合并成功" && sleep 0.5
    echo '解压文件' && sleep 0.5
    tar -zxf ./shards/source -C ./shards/
    echo '读取源文件'
    echo -e "  $(cat ./shards/data)"
  else
    ## 4. 合并失败
    shards=$(cat ./shards/md5.failed)
    echo "合并失败 ( 损坏的分片: $(echo $shards | tr '\n' ' '))"
    ((recount++)) && sleep 1
  fi
  
  ### 退出循环条件 ###
  # 5. 有损坏的分片继续执行
  test ! -z "$shards"
do :; done

