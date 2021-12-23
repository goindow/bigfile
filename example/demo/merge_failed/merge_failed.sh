#! /bin/bash

echo 'modify shard_aa'
echo 'modify' > ./shards/shard_aa
echo '---------------------------------------'

../../../bigfile.sh merge ./shards/md5

if test $? -ne 0; then
  echo '---------------------------------------'
  echo 'Signature verification failed for the following files(cat md5.failed): '
  cat ./shards/md5.failed
fi


