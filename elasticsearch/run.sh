#!/bin/bash

set -euo pipefail

if [ ${DEBUG:-""} = "true" ]; then
 set -x
fi

export KUBERNETES_AUTH_TRYKUBECONFIG="false"
ES_REST_BASEURL=http://localhost:9200
LOG_FILE=elasticsearch_connect_log.txt
RETRY_COUNT=600		# how many times
RETRY_INTERVAL=2	# how often (in sec)

retry=$RETRY_COUNT
max_time=$(( RETRY_COUNT * RETRY_INTERVAL ))	# should be integer
timeouted=false

mkdir -p /elasticsearch/$CLUSTER_NAME
secret_dir=/etc/elasticsearch/secret

BYTES_PER_MEG=$((1024*1024))
BYTES_PER_GIG=$((1024*${BYTES_PER_MEG}))

MAX_ES_MEMORY_BYTES=$((64*${BYTES_PER_GIG}))
MIN_ES_MEMORY_BYTES=$((256*${BYTES_PER_MEG}))

# the amount of RAM allocated should be half of available instance RAM.
# ref. https://www.elastic.co/guide/en/elasticsearch/guide/current/heap-sizing.html#_give_half_your_memory_to_lucene
# parts inspired by https://github.com/fabric8io-images/run-java-sh/blob/master/fish-pepper/run-java-sh/fp-files/java-container-options
regex='^([[:digit:]]+)([GgMm])i?$'
if [[ "${INSTANCE_RAM:-}" =~ $regex ]]; then
    num=${BASH_REMATCH[1]}
    unit=${BASH_REMATCH[2]}
    if [[ $unit =~ [Gg] ]]; then
        ((num = num * ${BYTES_PER_GIG})) # enables math to work out for odd Gi
    elif [[ $unit =~ [Mm] ]]; then
        ((num = num * ${BYTES_PER_MEG})) # enables math to work out for odd Gi
    fi

    #determine if req is less then max recommended by ES
    echo "Comparing the specificed RAM to the maximum recommended for ElasticSearch..."
    if [ ${MAX_ES_MEMORY_BYTES} -lt ${num} ]; then
        ((num = ${MAX_ES_MEMORY_BYTES}))
        echo "Downgrading the INSTANCE_RAM to $(($num / BYTES_PER_MEG))m because ${INSTANCE_RAM} will result in a larger heap then recommended."
    fi

    #determine max allowable memory
    echo "Inspecting the maximum RAM available..."
    mem_file="/sys/fs/cgroup/memory/memory.limit_in_bytes"
    if [ -r "${mem_file}" ]; then
        max_mem="$(cat ${mem_file})"
        if [ ${max_mem} -lt ${num} ]; then
            ((num = ${max_mem}))
            echo "Setting the maximum allowable RAM to $(($num / BYTES_PER_MEG))m which is the largest amount available"
        fi
    else
        echo "Unable to determine the maximum allowable RAM for this host in order to configure ElasticSearch"
        exit 1
    fi

    if [[ $num -lt $MIN_ES_MEMORY_BYTES ]]; then
        echo "A minimum of $(($MIN_ES_MEMORY_BYTES/$BYTES_PER_MEG))m is required but only $(($num/$BYTES_PER_MEG))m is available or was specified"
        exit 1
    fi
    export ES_JAVA_OPTS="${ES_JAVA_OPTS:-} -Xms$(($num/2/BYTES_PER_MEG))m -Xmx$(($num/2/BYTES_PER_MEG))m"
    echo "ES_JAVA_OPTS: '${ES_JAVA_OPTS}'"
else
    echo "INSTANCE_RAM env var is invalid: ${INSTANCE_RAM:-}"
    exit 1
fi

# Wait for Elasticsearch port to be opened. Fail on timeout or if response from Elasticsearch is unexpected.
wait_for_port_open() {
    rm -f $LOG_FILE
    # test for ES to be up first and that our SG index has been created
    echo -n "Checking if Elasticsearch is ready on $ES_REST_BASEURL "
    while ! response_code=$(curl -s \
        --max-time $max_time \
        -o $LOG_FILE -w '%{response_code}' \
        $ES_REST_BASEURL) || test $response_code != "200"
do
    echo -n "."
    sleep $RETRY_INTERVAL
    (( retry -= 1 ))
    if (( retry == 0 )) ; then
        timeouted=true
        break
    fi
done

if [ $timeouted = true ] ; then
    echo -n "[timeout] "
else
    rm -f $LOG_FILE
    return 0
fi
echo "failed"
cat $LOG_FILE
rm -f $LOG_FILE
exit 1
}

# Since we use Java security manager we probably want all configs/certs in one place
# this is not easily achievable with configmaps
cp /usr/share/elasticsearch/config/* /etc/elasticsearch/

exec /usr/share/elasticsearch/bin/elasticsearch -Epath.conf=$ES_CONF
