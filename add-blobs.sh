
#!/bin/sh

DIR=`pwd`

mkdir -p .downloads

cd .downloads

blob_download() {
  set -eu
  local package=$1
  local url=$2
  local f=$3
  if [ ! -f ${DIR}/blobs/${package}/${f} ];then
    curl -L -J ${url} -o ${f}
    bosh add-blob --dir=${DIR} ${f} ${package}/${f}
  fi
}

LOGSTASH_VERSION=6.5.4

blob_download logstash https://artifacts.elastic.co/downloads/logstash/logstash-${LOGSTASH_VERSION}.tar.gz logstash-${LOGSTASH_VERSION}.tar.gz
blob_download python2.7 https://www.python.org/ftp/python/2.7.15/Python-2.7.15.tgz Python-2.7.15.tgz

cd -
