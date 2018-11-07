
#!/bin/sh

DIR=`pwd`

mkdir -p .downloads

cd .downloads


LOGSTASH_VERSION=6.4.3

if [ ! -f ${DIR}/blobs/logstash/logstash-${LOGSTASH_VERSION}.tar.gz ];then
    curl -L -O -J https://artifacts.elastic.co/downloads/logstash/logstash-${LOGSTASH_VERSION}.tar.gz
    bosh add-blob --dir=${DIR} logstash-${LOGSTASH_VERSION}.tar.gz logstash/logstash-${LOGSTASH_VERSION}.tar.gz
fi

cd -
