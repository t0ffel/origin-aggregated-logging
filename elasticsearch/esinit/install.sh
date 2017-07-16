#!/bin/bash

set -ex

mkdir -p ${HOME}/sg
cd ${HOME}/sg

curl -L -O https://search.maven.org/remotecontent?filepath=com/floragunn/search-guard-5/${SG_VER}/search-guard-5-${SG_VER}-sgadmin-standalone.zip
unzip search-guard-5-${SG_VER}-sgadmin-standalone.zip

chmod -R og+w ${HOME}

chmod +x ${HOME}/sg/tools/sgadmin.sh

ls -l ${HOME}/

PASSWD=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 20 | head -n 1)
cat > ${HOME}/sgconfig/sg_internal_users.yml << CONF
  $(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 8 | head -n 1):
    hash: $PASSWD
CONF
