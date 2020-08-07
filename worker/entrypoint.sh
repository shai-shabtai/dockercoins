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
#consul kv put worker/SRVRNGPORT 80
#consul kv put worker/SRVHASHERPORT 80
#consul kv put worker/SRVRNGNAME rng
#consul kv put worker/SRVHASHERNAME hasher
#consul kv put worker/REDISCONNECTION redis
#echo  "----------------"

curl \
    --request PUT \
    --data rng \
    http://consul:8500/v1/kv/worker/SRVRNGNAME

curl \
    --request PUT \
    --data hasher \
    http://consul:8500/v1/kv/worker/SRVHASHERNAME

curl \
    --request PUT \
    --data redis \
    http://consul:8500/v1/kv/worker/REDISCONNECTION

curl \
    --request PUT \
    --data 80 \
    http://consul:8500/v1/kv/worker/SRVRNGPORT

curl \
    --request PUT \
    --data 80 \
    http://consul:8500/v1/kv/worker/SRVHASHERPORT


envconsul -kill-signal=SIGHUP -upcase -sanitize -prefix worker -consul $CONSULADDR -log-level debug "$@"
