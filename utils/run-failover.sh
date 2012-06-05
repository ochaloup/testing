#!/bin/bash

# check that the firewall is stopped
# service ip6tables stop

IS_START_SERVERS=$1 # shoud be servers start at first?
MULTI_ADDR=${MULTI_ADDR:-FF0E::1} # IPv4 is e.g. 230.0.0.4
MANAGEMENT_PORT=${MANAGEMENT_PORT:-9999}
MANAGEMENT_PORT_WITH_OFFSET=${MANAGEMENT_PORT}
PORT_OFFSET=100
RUN_COMMAND='bin/standalone.sh -c=standalone-ha.xml -Djboss.node.name=$SERVER -Djboss.bind.address=$BINDADDR -Djboss.bind.address.management=$BINDADDR -Djboss.bind.address.unsecure=$BINDADDR -Djboss.default.multicast.address=$MULTI_ADDR -Djava.net.preferIPv4Stack=false -Djava.net.preferIPv6Addresses=true'
OFFSET_PARAM='-Djboss.socket.binding.port-offset=$PORTOFFSET'

# declaring associative arrays where config and info about run will be saved
unset SERVER_CONFIGS
unset SERVER_NAMES
unset SERVER_PIDS
declare -A SERVER_CONFIGS
declare -a SERVER_NAMES  # not ass.array
declare -A SERVER_PIDS

JBOSS_DEPLOYMENT_PATH="standalone/deployments"
DEPLOYMENT_NAME="myejb.jar"
PATH_TO_DEPLOYMENT="/mnt/mountpoint/$DEPLOYMENT_NAME"
SERVER_NAME_PREFIX=${SERVER_NAME_PREFIX:-server}
JBOSS_HOME_BASE_PATH=${JBOSS_HOME_BASE_PATH:-`pwd`} 
#how the path to jboss home will be constructed
JBOSS_HOME_PATH="${JBOSS_HOME_BASE_PATH}/${SERVER_NAME_PREFIX}1" 
JBOSS_CLI="bin/jboss-cli.sh"
JBOSS_CLI_PATH=${JBOSS_HOME_PATH}/${JBOSS_CLI}

function waitUntilServerStarts() 
{
  local LOOP=3
  local SLEEP_TIME=4
  while [ $LOOP -gt 0 ]; do
    LOOP=$((LOOP-1))
    serverState $1 $2
    if [ $? -eq 0 ]; then
      LOOP=-999
      break
    fi
    echo "Sleeping ${SLEEP_TIME}s during waiting on the server to start"
    sleep $SLEEP_TIME
  done

  [ $LOOP -eq -999 ] && return 0 || return 1
}

function startServer() 
{
  local SERVER=$1
  local JBOSS_PATH=$2
  local BINDADDR=$3 # passed to $RUN_COMMAND
  local MNGMT_PORT=$4
  local PORTOFFSET=$(($MANAGEMENT_PORT_WITH_OFFSET-$MANAGEMENT_PORT)) #passed to $OFFSET_PARAM

  local PIDS_BEFORE=
  local PIDS_AFTER=
  getPIDs PIDS_BEFORE

  local TO_EVAL="nohup $JBOSS_PATH/$RUN_COMMAND $OFFSET_PARAM > $SERVER.log &" # prepare command for run the server
  echo "Starting server $SERVER on path $JBOSS_PATH on address $BINDADDR on port offset $PORTOFFSET"
  eval "echo \"$TO_EVAL\"" # showing to user what has been run

  eval "$TO_EVAL" # run the server
  waitUntilServerStarts $BINDADDR $MNGMT_PORT 
  local IS_SERVER_STARTED=$?

  # get pids of this server (at least probably of this server) - using diff of ps output 
  getPIDs PIDS_AFTER
  local PIDS_NOW=`getChanges "$PIDS_BEFORE" "$PIDS_AFTER"`
  SERVER_PIDS[$SERVER]=$PIDS_NOW
  echo "Server $SERVER has PIDs: " ${SERVER_PIDS[$SERVER]}

  # when the server fails to start we are going to stop it and exit
  if [ $IS_SERVER_STARTED -eq 0 ]; then 
    echo "Server $SERVER started" 
    eval "echo \"$TO_EVAL\"" # showing to user what has been run
  else 
    echo "Server $SERVER has a problem. Not started properly. Please fix the problem before continuing."
    echo "Last lines of log $SERVER.log ---------"
    tail $SERVER.log
    echo "---------------------------------------"
    killServer "${SERVER_PIDS[$SERVER]}"
    # stopServer $BINDADDR $MNGMT_PORT 
    # exit 1
  fi
}

function stopServer() 
{
  sh "$JBOSS_CLI_PATH" -c command=":shutdown" --controller=[$1]:$2
}

function undeploy()
{
  echo "Undeploying $DEPLOYMENT_NAME on [$1]:$2"
  sh "$JBOSS_CLI_PATH" -c command="undeploy $DEPLOYMENT_NAME" --controller=[$1]:$2
}

function deploy()
{
  echo "Deploying $DEPLOYMENT_NAME on [$1]:$2"
  sh "$JBOSS_CLI_PATH" -c command="deploy $DEPLOYMENT_NAME" --force --controller=[$1]:$2
}

function removeDeployment()
{
  echo "Removing all jar/ear files from $1/$JBOSS_DEPLOYMENT_PATH/"
  rm -rf `echo $1/$JBOSS_DEPLOYMENT_PATH/*jar*`
  rm -rf `echo $1/$JBOSS_DEPLOYMENT_PATH/*ear*`
}

function copyDeployment()
{
  echo "Copying deployment $PATH_TO_DEPLOYMENT to $1/$JBOSS_DEPLOYMENT_PATH/"
  cp "$PATH_TO_DEPLOYMENT" "$1/$JBOSS_DEPLOYMENT_PATH/"
}

function serverState()
{
  echo "Server state [$1]:$2"
  sh "$JBOSS_CLI_PATH" -c command=:read-attribute\(name=server-state\) --controller=[$1]:$2
}

function getPIDs()
{
  local  __resultvar=$1
  local result=`ps aux | grep java | grep jboss | grep standalone | sed 's/^[^ ]*[ ]*\([0-9]*\).*/\1/'`
  if [[ "$__resultvar" ]]; then
    eval $__resultvar="'$result'"
  else
    echo "$result"
  fi
}

function killServer() 
{
  if [ "x$1" == "x" ]; then
    echo "Nothing to kill in killServer method. Skipping..."
  else 
    echo "Killing processes with PID:" $1
    # Not put into apostrophes "
    kill -9 $1  
    sleep 1
    echo 
  fi
}

function killAll() 
{
  killServer "$(getPIDs)"
}

function getChanges() 
{
  diff -w <(echo "$1") <(echo "$2") | grep '>' | sed 's/^>[ ]*//'
}

function waitUntilKey() 
{
  local input=
  if [ "x$1" != "x" ]; then
    while [ "$input" != "$1" ]; do
      echo "Waiting for you to enter [$1]"
      read input
    done
  else 
    echo "Please press a key..."
    read input
  fi
}

# hack from http://stackoverflow.com/questions/4069188/how-to-pass-an-associative-array-as-argument-to-a-function-in-bash
function printServers()
{
  echo
  echo "Available servers:"
  for NAME in "${SERVER_NAMES[@]}"; do 
    local TMP_ARR=$(declare -p ${SERVER_CONFIGS[$NAME]}) 
    eval "declare -A DATA=${TMP_ARR#*=}"
    echo "${DATA[NAME]} => ${DATA[JBOSS_HOME]} [${DATA[IP_ADDRESS]}]:${DATA[M_PORT]}"
  done
}


####################################################
##################### STARTING #####################
####################################################
source ./ipv6script.sh

# variables where addresses are saved
# ADDRESSES=( IPV6_ADDR_HOST IPV6_ADDR_GLOBAL IPV6_ADDR_SITE IPV6_ADDR_LINK IPV6_ADDR_LINK_ZONEID ) 
ADDR_TO_USE=( ${IPV6_ADDR_GLOBAL[0]} ${IPV6_ADDR_GLOBAL[1]} ${IPV6_ADDR_LINK[0]} ${IPV6_ADDR_LINK[1]} )
ADDRESSES=( ADDR_TO_USE ) 


# stopping all java processes
#A=`diff -w <(ps aux | grep java | grep jboss | grep standalone | sed 's/^[^ ]*[ ]* \([0-9]*\).*/\1/') <(cat go) | grep '>' | sed 's/^> //'`
# killAll

# remote jndi calls - calling for all addresses defined in $ADDRESSES array
for A in "${ADDRESSES[@]}"; do 
  # really hacky :/ - getting array from loop
  ARR_ADDRESSES=($(eval echo \${$A[*]}))

  if [ ${#ARR_ADDRESSES[@]} -eq 0 ]; then
    # no address like this
    echo "No IP address in array - skipping to next loop"
    continue
  fi

  # echo ${ARR_ADDRESSES[@]}
  if [ ${#ARR[@]} -eq 1 ]; then
    ARR_ADDRESSES[${#ARR_ADDRESSES[*]}]=${ARR_ADDRESSES[0]}
    MANAGEMENT_PORT_WITH_OFFSET=$((MANAGEMENT_PORT+$PORT_OFFSET))
  fi

  # Get configuration for ALL servers and start them
  IS_FIRST_RUN=1
  NUMBER=0
  MNGMT_PORT=$MANAGEMENT_PORT
  for ADDR in "${ARR_ADDRESSES[@]}"; do
    NUMBER=$(($NUMBER+1))
    SERVER_NAME="${SERVER_NAME_PREFIX}${NUMBER}"
    unset MYCONFIG
    declare -A MYCONFIG
    MYCONFIG[NAME]="$SERVER_NAME"
    MYCONFIG[JBOSS_HOME]="${JBOSS_HOME_BASE_PATH}/$SERVER_NAME"
    MYCONFIG[M_PORT]="$MNGMT_PORT"
    MYCONFIG[IP_ADDRESS]="$ADDR"
    declare -p MYCONFIG

    if [ ! -d ${MYCONFIG[JBOSS_HOME]} ]; then
      echo "${MYCONFIG[JBOSS_HOME]} is not a directory. Server won't be run. Please check where the problem is."
      continue
    fi

    # Setting global variables which pass all info about servers to start in the script
    SERVER_NAMES[$NUMBER]="$SERVER_NAME"
    # hacky way how to pass associative array to an another variable
    TMP_ARR=$(declare -p MYCONFIG)
    CONFIG_NAME="SERVER_CONFIG_${SERVER_NAME}"  #global variable name where to save ass.array
    eval "declare -A $CONFIG_NAME=${TMP_ARR#*=}" # declaring global variable name as ass.array with content from TMP_ARR
    SERVER_CONFIGS[$SERVER_NAME]=$CONFIG_NAME

    # Setting path to cli script
    if [ $IS_FIRST_RUN -eq 1 ]; then  # we are in the first run
      JBOSS_HOME_PATH=${MYCONFIG[JBOSS_HOME]}
      JBOSS_CLI_PATH=$JBOSS_HOME_PATH/$JBOSS_CLI
      MNGMT_PORT=$MANAGEMENT_PORT_WITH_OFFSET
      IS_FIRST_RUN=0
    fi

    if [ "x$IS_START_SERVERS" != "x" ]; then
      # Making maintanance on server home
      removeDeployment ${MYCONFIG[JBOSS_HOME]}
      # Run server
      startServer "$SERVER_NAME" "${MYCONFIG[JBOSS_HOME]}" ${MYCONFIG[IP_ADDRESS]} ${MYCONFIG[M_PORT]} 
      # (Re)deploying files which should be deployed
      copyDeployment ${MYCONFIG[JBOSS_HOME]}
    fi
  done

  input=
  while [ "x$input" != "xq" ]; do
    printServers
    echo "Deploy [d servername], Undeploy [u servername], Start [s servername], Stop [st servername], Kill [k servername], " 
    echo "Copy deployment [c], Remove deployment[r], Status/state of server [status servername], Kill all jbosses [killall], " 
    echo "Set multicast address [multi address], " 
    echo "Quit [q]"
    printf "Choose your action: "
    read input
    
    set -- $input
    SERVERNAME=${2:-nothing}
    SERVERCONFIG=
    ACTION=

    if [[ "x$1" == "xkillall" ]]; then
      ACTION="$1"
    elif [[ "x$1" == "xmulti" && "x$2" != "x" ]]; then
      ACTION="$1"
      PARAM="$2"
    fi

    if [[ "x$ACTION" == "x" ]]; then
      # Which server should be used
      if [ "x${SERVER_CONFIGS[$SERVERNAME]}" != "x" ]; then
        SERVERCONFIG=${SERVER_CONFIGS[$SERVERNAME]}
      elif [ "x${SERVER_NAMES[$SERVERNAME]}" != "x" ]; then
        SERVERNAME=${SERVER_NAMES[$SERVERNAME]}
        SERVERCONFIG=${SERVER_CONFIGS[$SERVERNAME]}
      else
        SERVERCONFIG=
      fi

      # Get data from the server the we wan to use
      if [[ "x$SERVERCONFIG" != "x" ]]; then
        ACTION=$1
        # to take ass.array
        unset TTT
        unset DATA
        TTT=$(declare -p ${SERVER_CONFIGS[$SERVERNAME]}) 
        eval "declare -A DATA=${TTT#*=}"
      else 
        ACTION="next-round"
      fi
    fi

    # What we will do
    case $ACTION in
      s|start)
        startServer "$SERVERNAME" "${DATA[JBOSS_HOME]}" ${DATA[IP_ADDRESS]} ${DATA[M_PORT]} 
        ;;
      st|sstop)
	stopServer ${DATA[IP_ADDRESS]} ${DATA[M_PORT]}
        ;;
      k|kkill)
	killServer "${SERVER_PIDS[$SERVERNAME]}"
        ;;
      d|deploy)
	deploy ${DATA[IP_ADDRESS]} ${DATA[M_PORT]}
        ;;
      u|undeploy)
	undeploy ${DATA[IP_ADDRESS]} ${DATA[M_PORT]}
        ;; 
      c|copy)
        copyDeployment "${DATA[JBOSS_HOME]}"
        ;; 
      r|remove)
        removeDeployment "${DATA[JBOSS_HOME]}"
        ;; 
      state|status)
        serverState ${DATA[IP_ADDRESS]} ${DATA[M_PORT]}
        ;;
      ka|killall)
        killAll
        ;;
      mm|multi|multicast)
	MULTI_ADDR=$PARAM
        ;;
      q|quit|exit)
        input="q" ;;
      *)
        echo "Chosen action '$ACTION $SERVERNAME' was not recognized" ;;
    esac
  done

  # kill all jboss java processes
  killAll
  # removeDeployment $JBOSS_HOME_1
  # removeDeployment $JBOSS_HOME_2
done
