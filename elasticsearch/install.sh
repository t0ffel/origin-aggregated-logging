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
<<<<<<< ff7e56f6b03416e9638561f2b72beab2c0d7f041
chmod +x /usr/share/elasticsearch/plugins/openshift-elasticsearch/sgadmin.sh

PASSWD=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 20 | head -n 1)
cat > ${HOME}/sgconfig/sg_internal_users.yml << CONF
---
  $(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 8 | head -n 1):
    hash: $PASSWD
CONF


