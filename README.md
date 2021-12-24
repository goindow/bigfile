# bigfile
大文件的分片与合并

## 使用场景
- 大文件网络传输场景下，将大文件拆分为多个小文件再传输
- 拉取合并分片时，基于 md5 数字签名，过滤不完整分片，便于重传，保证文件传输的完整性

## 功能列表
- 文件分片
- 分片合并

## 样例
- [文本文件](https://github.com/goindow/bigfile/tree/main/example/demo/text_file_sharding)
- [二进制文件](https://github.com/goindow/bigfile/tree/main/example/demo/binary_file_sharding)
- [分片前打包压缩](https://github.com/goindow/bigfile/tree/main/example/demo/sharding_after_compressed)
- [分片合并验签失败](https://github.com/goindow/bigfile/tree/main/example/demo/merge_failed)
- [FTP数据交换](https://github.com/goindow/bigfile/tree/main/example/demo/push_ftp_pull)

## 使用说明
```shell
Usage: bigfile COMMAND [ARGS...]

  File sharding and merging.

Commands:
  shard                     File sharding
  merge                     Merge shards

Run 'bigfile help COMMAND' for more details on a command.
```

## 文件分片
- 默认按行数分片(-l)，如果指定了 -b 参数，则按字节分片（忽略 -l 参数）
- 按行数分片(-l)，不支持操作前压缩打包（忽略 -t 参数）
- 分片前是否打包压缩(-t)，只有按字节分片(-b)才支持 -t 参数，如果指定了 -t 参数，那么源文件是打包压缩后的文件
- 分片完成后，在指定的分片存储目录(-d)中会生成签名文件(md5)，其中第一行记录原始文件的 md5 信息，其后记录所有分片的 md5 信息
```shell
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
```

## 分片合并
- 合并分片是基于 shard 命令生成的签名文件(md5)进行的，必须同时拿到该文件，才能合并分片，并完成验签
- 验签通过，则合并为原始文件(source)
- 验签失败，则过滤出失败的分片，写入到 md5.failed 文件，便于重传
```shell
Usage: bigfile merge md5_file

  Merge Shards. verify the signatures of all shards according to the md5 file.
  if the verification fails, write the failed shards to the "md5.failed" file.

```