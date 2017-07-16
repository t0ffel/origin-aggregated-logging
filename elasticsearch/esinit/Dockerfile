FROM centos:centos7

MAINTAINER OpenShift Development <dev@lists.openshift.redhat.com>

EXPOSE 9200
EXPOSE 9300
USER 0

ENV HOME=/opt/app-root/src \
  JAVA_VER=1.8.0 \
  ES_VER=5.4.0 \
  SG_VER=5.4.0-12 \
  INSTANCE_RAM=512G \
  NODE_QUORUM=1 \
  RECOVER_AFTER_NODES=1 \
  RECOVER_EXPECTED_NODES=1 \
  RECOVER_AFTER_TIME=5m \
  PLUGIN_LOGLEVEL=INFO \
  ES_JAVA_OPTS="-Dmapper.allow_dots_in_name=true"

LABEL io.k8s.description="Elasticsearch container to serve as EFK aggregated logging backend" \
  io.k8s.display-name="Elasticsearch ${ES_VER}" \
  io.openshift.expose-services="9200:https, 9300:https" \
  io.openshift.tags="logging,elasticsearch"

# install the RPMs in a separate step so it can be cached
RUN yum install -y --setopt=tsflags=nodocs \
                java-1.8.0-openjdk-headless \
                unzip \
                PyYAML && \
    yum update -y && \
    yum clean all

#ADD ../index_templates/ /usr/share/elasticsearch/index_templates/
#ADD ../index_patterns/ /usr/share/elasticsearch/index_patterns/
ADD sgconfig/ ${HOME}/sgconfig/
ADD install.sh ${HOME}/
RUN ${HOME}/install.sh
ADD run.sh ${HOME}/
COPY utils/** /usr/local/bin/

WORKDIR ${HOME}
USER 1000
CMD ["sh", "/opt/app-root/src/run.sh"]
