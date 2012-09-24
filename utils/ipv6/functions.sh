#!/bin/bash
function strip_linklocal_id() {
  echo "$1" | sed 's/^\([^%]*\).*/\1/'
}

function wait_for_server() {
   local ADDRESS_ORIG="$1"
   local ADDRESS=`strip_linklocal_id "$1"`
   local PORT=${2:-9999}
  
    # simple busy waiting until server is started
    local LOOP=10
    while [ $LOOP -gt 0 ]; do
      LOOP=$((LOOP-1))
      local RET=1
      sh "${EAP6_PATH}/bin/jboss-cli.sh" -c command=:read-attribute\(name=server-state\) --controller=[$ADDRESS]:$PORT || RET=0
      if [ "x$RET" = "x1" ]; then
        LOOP=-1
      else 
        sleep 3
      fi
      echo "Server on $ADDRESS was started"
    done
}

function stop_server() {
    local ADDRESS_ORIG="$1"
    local ADDRESS=`strip_linklocal_id "$1"`
    local PORT=${2:-9999}
 
    # stop the server
    sh ${EAP6_PATH}/bin/jboss-cli.sh --connect command=:shutdown --controller=[$ADDRESS]:$PORT
    echo "Server on $A was successfully stopped"
}

