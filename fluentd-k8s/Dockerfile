FROM centos:centos7

MAINTAINER OpenShift Development <dev@lists.openshift.redhat.com>

ENV HOME=/opt/app-root/src \
  PATH=/opt/app-root/src/bin:/opt/app-root/bin:$PATH \
  RUBY_VERSION=2.0 \
  FLUENTD_VERSION=0.12.6 \
  GEM_HOME=/opt/app-root/src \
  THROTTLE_CONF_LOCATION=/etc/throttle-settings

LABEL io.k8s.description="Fluentd container for collecting of docker container logs" \
  io.k8s.display-name="Fluentd 0.12.6" \
  io.openshift.expose-services="9200:http, 9300:http" \
  io.openshift.tags="logging,elk,fluentd"

RUN rpmkeys --import file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-7 && \
  yum install -y --setopt=tsflags=nodocs \
  gcc-c++ \
  ruby \
  ruby-devel \
  libcurl-devel \
  git \
  rubygem-rake \
  make && \
  mkdir -p ${HOME} && \
  gem install --no-ri bundler fluentd fluent-plugin-elasticsearch && \
  bundle install && \
  git clone https://github.com/t0ffel/fluent-plugin-kubernetes_metadata_input && \
  cd fluent-plugin-kubernetes_metadata_input && \
  rake install


ADD fluent.conf /etc/fluent/fluent.conf
ADD run.sh ${HOME}/

WORKDIR ${HOME}

CMD ["sh", "run.sh"]
