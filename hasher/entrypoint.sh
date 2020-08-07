#!/bin/ash
set -eo pipefail
#shopt -s nullglob

attempt_counter=0
max_attempts=15
CONSULADDR=consul:8500
export CONSUL_HTTP_ADDR=$CONSULADDR
until $(curl --output /dev/null --silent --head --fail http://consul:8500); do
    if [ ${attempt_counter} -eq ${max_attempts} ];then
      echo "Max attempts reached"
      exit 1
    fi

    printf '.'
    attempt_counter=$(($attempt_counter+1))
    sleep 5
done
echo "----------------"

#echo ADDING NEW KEY/VALUE IN CONSUL REMOTE 
#consul kv put hasher/SRVHASHERPORT 80
#consul kv put app/SRVHASHERNAME hasher
#echo  "----------------"

curl \
    --request PUT \
    --data 80 \
    http://consul:8500/v1/kv/hasher/SRVHASHERPORT

envconsul -kill-signal=SIGHUP -upcase -sanitize -prefix hasher -consul $CONSULADDR -log-level debug "$@"
