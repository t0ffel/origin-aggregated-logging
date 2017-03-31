#!/bin/bash

set -ex

mkdir -p ${HOME}
cd ${HOME}/
curl -O https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-${ES_VER}.rpm
rpm -ivh elasticsearch-${ES_VER}.rpm
rm elasticsearch-${ES_VER}.rpm


ln -s /usr/share/elasticsearch /usr/share/java/elasticsearch

/usr/share/elasticsearch/bin/elasticsearch-plugin install io.fabric8:elasticsearch-cloud-kubernetes:${ES_CLOUD_K8S_VER}


mkdir /elasticsearch
mkdir -p $ES_CONF
chmod -R og+w $ES_CONF
chmod -R og+w /usr/share/java/elasticsearch ${HOME} /elasticsearch
chmod -R o+rx /etc/elasticsearch


