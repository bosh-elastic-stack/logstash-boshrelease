
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

LOGSTASH_VERSION=7.8.1

if [ ! -f ${DIR}/blobs/logstash/logstash-${LOGSTASH_VERSION}.tar.gz ];then
    curl -L -J -o logstash-${LOGSTASH_VERSION}.tar.gz https://artifacts.elastic.co/downloads/logstash/logstash-oss-${LOGSTASH_VERSION}.tar.gz
    bosh add-blob --dir=${DIR} logstash-${LOGSTASH_VERSION}.tar.gz logstash/logstash-${LOGSTASH_VERSION}.tar.gz
fi

blob_download python2.7 https://www.python.org/ftp/python/2.7.15/Python-2.7.15.tgz Python-2.7.15.tgz

cd -
