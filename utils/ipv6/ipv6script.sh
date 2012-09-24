#!/bin/bash

# Function takes two arguments - first is the regexp for searching line of a IP address where we want the
# instance of JBoss bind to.
# The second argument says whether you want to add zone id to the returned address.
function getAddr() 
{
  # echo `ifconfig -a | grep $1 | head -n 1 | sed 's/^[ \t]*inet6 addr:[ \t]*\([^\/]*\).*/\1/'`

  local REGEXP="$1"
  local IS_DEV=$2
  local DEV=
  local ADDR=

  /sbin/ifconfig -a | {
    declare -a ALL_ADDR
    while read line; do
      # we try to find out which dev is in use
      local DEV_TMP=`echo "$line" | grep -o '^[^ ]*     ' | sed 's/^\([^ ]*\).*$/\1/'`
      if [ "x$DEV_TMP" != "x" ]; then
        DEV=$DEV_TMP
      fi

      # now we get IP address according to regexp
      local ADDR=`echo "$line" | grep "$REGEXP" | head -n 1 | sed 's/^[ \t]*inet6 addr:[ \t]*\([^\/]*\).*/\1/'`
      if [ "x$ADDR" != "x" ]; then
        # we want to add dev name to the address
        if [ "x$IS_DEV" != "x" ]; then
          ADDR=${ADDR}%${DEV}
        fi
        ALL_ADDR[${#ALL_ADDR[*]}]=$ADDR
      fi
    done

    # returning array
    echo ${ALL_ADDR[@]}
    return 0
  }
}


export IPV6_ADDR_HOST=`getAddr Scope:Host`
export IPV6_ADDR_GLOBAL=(`getAddr Scope:Global`)
export IPV6_ADDR_SITE=`getAddr Scope:Site`
export IPV6_ADDR_LINK=`getAddr Scope:Link`
export IPV6_ADDR_LINK_ZONEID=`getAddr Scope:Link 1`
