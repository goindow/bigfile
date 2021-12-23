#!/bin/bash

# 数字签名文件名，第一行为源文件的 md5，余下的是每个分片的 md5
md5_file_name=md5
# 合并分片文件名，source 的 md5 等于源文件 md5（用来校验合并分片后文件的完整性）
merge_file_name=source

# -t，二进制文件分片前是否打包压缩，只有 -b 二进制文件分片才支持 -t 参数
tar=false
# -b，二进制文件分片，按字节分片，默认单位 b，也可以带单位 k、m 
shard_byte_count=
# -l，文本文件分片，按行数分片，不支持 -t 参数，默认按 -l 分片，如果 -b 有值，则忽略 -l
shard_line_count=1000
# -d，分片文件目录
shard_dir=.
# -p，分片文件前缀
shard_prefix=shard_
# -s，分片文件后缀位数
shard_suffix_length=2

function usage() {
  cat << 'EOF'
Usage: bigfile COMMAND [ARGS...]
  
  File sharding and merging.

Commands:
  shard                     File sharding
  merge                     Merge shards

Run 'bigfile help COMMAND' for more details on a command.
EOF
}

function usage_shard() {
  cat << 'EOF'
Usage: bigfile shard [-b byte_count<(b)|k|m>] [-d shard_dir] [-l line_count] [-p shard_prefix] 
                     [-s shard_suffix_length] [-t] source

  Sharding the file according to the specified rules

Options:
  -b            Sharding by byte_count bytes(default unit "b", only be <(b)|k|m>)
  -d            Shards storage directory(default "./")
  -l            Sharding by line_count lines(default "1000")
  -p            Shard file prefix(default "shard_", like shard_aa, shard_ab...)
  -s            Shard file suffix length(default 2)
  -t            Specify whether compression is required before sharding(default uncompressed)
EOF
}

function usage_merge() {
  cat << 'EOF'
Usage: bigfile merge md5_file

  Merge Shards. verify the signatures of all shards according to the md5 file. 
  if the verification fails, write the failed shards to the "md5.failed" file.

EOF
}

function dialog() {
  case $1 in
    fatal) printf '%s\n' "$2" && exit 1;;
    error) printf '%s\n\n%s\n' "$2" "For more details, see \"${3:-'bigfile help'}\"." && exit 1;;
    info)  printf '%s\n' "$2";;
    ok)    echo 'OK.';;
    exit)  echo 'exited.';;
  esac
  exit 0
}

function help() {
  test -z $1 && usage && exit
  type -t usage_$1 &> /dev/null && usage_$1 || dialog error "$1: command not found."
}

function opts() {
  while getopts 'b:d:l:m:p:s:t' options; do
    case $options in
      b) shard_byte_count=$OPTARG;;
      d) shard_dir=${OPTARG/%\//};;
      l) shard_line_count=$OPTARG;;
      p) shard_prefix=$OPTARG && test $(dirname $shard_prefix) = '.' && shard_prefix=$(basename $shard_prefix) || dialog error '-p: option shard_prefix not allowed to contain paths.';;
      s) shard_suffix_length=$OPTARG;;
      t) tar=$OPTARG && test -z $tar && tar=true;;
    esac
  done
  return $(($OPTIND - 1))
}

function md5sign() {
  # 源文件
  printf '%s %s\n' $(md5sum $1 | cut -b 1-32) $merge_file_name > $shard_dir/$md5_file_name
  # 分片
  for s in $(ls $shard_dir/$shard_prefix*); do
    printf '%s %s\n' $(md5sum $s | cut -b 1-32) $(basename $s) >> $shard_dir/$md5_file_name
  done
}

# 文件分片
# bigfile shard [-b byte_count<k|m>] [-d shard_dir] [-l line_count] [-p shard_prefix] [-s shard_suffix_length] [-t] source
function shard() {
  opts $@ || shift $?
  # 源文件
  test -z $1 && dialog error 'Requires a source file as the argement.'
  test -e $1 && source=$1 || dialog error "$1, no such file."
  # 分片文件目录
  if test -d $shard_dir; then
    rm -rf $shard_dir/$merge_file_name && rm -rf $shard_dir/$shard_prefix*
  else
    mkdir -p $shard_dir || dialog error 'No permission, failed to create shard directory.'
  fi
  # 分片
  if test ! -z $shard_byte_count; then
    # 打包压缩源文件
    if test 'true' = "$tar"; then
      source_dir=$(dirname $source)
      source_name=$(basename $source)
      # 使用压缩后的文件替代源文件做分片
      source=$source.tar.gz
      tar -zcf $source -C $source_dir $source_name
    fi
    # 二进制文件
    split -b $shard_byte_count -a $shard_suffix_length $source $shard_dir/$shard_prefix
  else
    # 文本文件
    split -l $shard_line_count -a $shard_suffix_length $source $shard_dir/$shard_prefix
  fi
  # md5 签名
  test $? -eq 0 && md5sign $source && dialog ok
}

# 文件合并
# bigfile merge md5_file
function merge() {
  # md5 文件
  test -z $1 && dialog error 'Requires a md5 file as the argement.'
  test -e $1 && md5_file=$1 || dialog error "$1: no such file."
  # 源文件信息
  merge_file_name=$(head -n 1 $md5_file | cut -d ' ' -f 2)
  # 分片信息
  shards=$(cat $md5_file | grep -v $merge_file_name | cut -d ' ' -f 2 | tr '\n' ' ')
  # 合并
  cd $(dirname $md5_file) && cat $shards > $merge_file_name || dialog fatal 'Merge failed.'
  # 校验签名
  md5sum -c $(basename $md5_file) | grep -v "$merge_file_name: " | grep -v ': OK' | grep -v ": WARNING" | cut -d ':' -f 1 > md5.failed
  # 计算结果
  test ! -z $(cat md5.failed) && rm -rf $merge_file_name && dialog error 'Signature verification failed.' 'cat md5.failed'
  dialog ok
}

# main
test ! -x "$(command -v md5sum)" && dialog fatal 'md5sum: command not found.'
case $1 in
  shard) shift && shard $@;;
  merge) shift && merge $@;;
  help)  shift && help $1;;
  *)     usage;;
esac
