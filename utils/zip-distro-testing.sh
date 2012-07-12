#! /bin/bash

# what is working directory where all stuff will be put to
OUTPUT_DIR=`pwd`
# arguments passed to the script refers to ziped/unpacked EWS distributions
UNPACKED=0
# what will be added on classpath of java commands
CLASSPATH_ADD=
# code that will be used for exiting when st goes to be reason for special exit
EXIT_CODE=0
# go to debug mode
IS_DEBUG=

declare -a INPUT_PARAMS
declare -a INPUT_DIRS

######################## FUNCTIONS ########################
function debug() {
  if [ "x$IS_DEBUG" != "x" ]; then
  	echo "+ $1"
  fi
}

# unzip $file $output_dir 
function f_unzip() {
	unzip -q "$1" -d "$2"
}            

######################## START OF EXECUTION ########################
# Option processing
#!/bin/sh
while [ $# -gt 0 ]; do
  case "$1" in
    -o | --output)
      shift
      OUTPUT_DIR="$1"
      if [ ! -d "$OUTPUT_DIR" ]; then
      	mkdir -p "$OUTPUT_DIR"
      fi
      ;;
    -u | --unpacked)
      UNPACKED=1
      ;;
    -cp | --classpath)
      shift
      CLASSPATH_ADD="$1"
      ;;
    -d | -debug)
      IS_DEBUG=1
      ;;
    -dd | --ddebug)
      IS_DEBUG=1
      set -x
      ;;
      

    -h | --help)
      echo "Usage:"
      echo `basename $0` " [-ud] [-o output_dir] [-cp classpath_addition] file/dir/web_address"
      echo -e "-u or --unpacked             the arguments are directories which are already unpacked EWS distributions"
      echo -e "-o or --output dir           output directory"
      echo -e "-cp or --classpath classes   list of classes split by colon sing as it is normal in Linux."\
           "This Argument will be added as argument '-cp' of java programs."
      echo -e "-d or --debug                debug mode on"
      echo -e "-h or --help                 will show this help"           
      exit $EXIT_CODE
      ;;   
      
    # Special cases
    --)
      break
      ;;
    --* | -?)
      echo "Unknown option $1"
      EXIT_CODE=1
      set -- $1 -h # let's help the user understand (setting positional arguments to -h)
      ;;
    -*)
      # Split apart combined short options
      split=$1
      shift
      set -- $(echo "$split" | cut -c 2- | sed 's/./-& /g') "$@"
      continue
      ;;
    *)   # Done with options
      break
      ;;
  esac
  debug "Debugging position options: $1" #DEBUG
  shift
done

debug "Arguments [$#]: $@" #DEBUG
if [ $# -lt 1 ]; then
	echo "The script needs parameter where it can find the zip files."
	exit 1
fi
INPUT_PARAMS=($@)

if [ $UNPACKED -gt 0 ]; then
  # already unpacked
  INPUT_DIRS=("${INPUT_PARAMS[@]}")
else
  for ARR_ITEM in "${INPUT_PARAMS[@]}"; do
    # Getting list of ZIPs - checking for file, dir or web address
    if [ -d "$ZIP_INPUT" ]; then # directory - unzip all zip files
      for I in *zip; do
  	    echo $I
      done
    elif [ -s "$ZIP_INPUT" ]; then
      echo "This is a file"
    else 
      echo "This is not a file"
    fi
  fi
fi

