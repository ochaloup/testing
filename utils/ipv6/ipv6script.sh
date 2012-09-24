#!/bin/bash

# Function takes two arguments - first is the regexp for searching line of a IP address where we want the
# instance of JBoss bind to.
# The second argument says whether you want to add zone id to the returned address.
function getAddr() 
{
  # echo `ifconfig -a | grep $1 | head -n 1 | sed 's/^[ \t]*inet6 addr:[ \t]*\([^\/]*\).*/\1/'`

  REGEXP="$1"
  DEV=
  ADDR=

  /sbin/ifconfig -a | {
    while read line; do
      DEV_TMP=`echo "$line" | grep -o '^[^ ]*     ' | sed 's/^\([^ ]*\).*$/\1/'`
      if [ "x$DEV_TMP" != "x" ]; then
        DEV=$DEV_TMP
      fi

      ADDR=`echo "$line" | grep "$REGEXP" | head -n 1 | sed 's/^[ \t]*inet6 addr:[ \t]*\([^\/]*\).*/\1/'`
      if [ "x$ADDR" != "x" ]; then
        break
      fi
    done

    if [ "x$2" != "x" ]; then
      ADDR=${ADDR}%${DEV}
    fi
    echo "$ADDR"
  }
}

export IPV6_ADDR_HOST=`getAddr Scope:Host`
export IPV6_ADDR_GLOBAL=`getAddr Scope:Global`
export IPV6_ADDR_SITE=`getAddr Scope:Site`
export IPV6_ADDR_LINK=`getAddr Scope:Link`
export IPV6_ADDR_LINK_ZONEID=`getAddr Scope:Link 1`
