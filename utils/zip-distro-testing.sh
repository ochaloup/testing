#! /bin/bash

# Finishing on error of any command in this script
# set -e 

# what is working directory where all stuff will be put to
OUTPUT_DIR=`pwd`
DOWNLOAD_DIR_NAME="downloaded_zip"
# arguments passed to the script refers to ziped/unpacked EWS distributions
UNPACKED=0
# what will be added on classpath of java commands
CLASSPATH_ADD=
# code that will be used for exiting when st goes to be reason for special exit
EXIT_CODE=0
# go to debug mode
IS_DEBUG=

# Declaration of global variables
declare -a INPUT_PARAMS
declare -a INPUT_DIRS

######################## FUNCTIONS ########################
function debug() {
  if [ "x$IS_DEBUG" != "x" ]; then
  	echo "+ $1"
  fi
}

function just_name() {
	local FILENAME=`basename "$1"`
  local RESULT="${FILENAME%.*}"

  if [ "x$2" == "x" ]; then
  	echo "$RESULT"
  else
    eval $2="'$RESULT'"
  fi
}

# unzip file output_dir result_var_name
# creating dir automatically 
function unzip_with_dir() {
  just_name "$1" FILENAME_WITHOUT_EXT
  local OUT_ZIP_DIR="${2}/${FILENAME_WITHOUT_EXT}"
  mkdir "$OUT_ZIP_DIR"
  #if [ $? -ne 0 ]; then
  #	echo "Folder $OUT_ZIP_DIR can't be created and zip file $1 can't be unzipped. Exiting..."
  #	exit 2
  #fi
	echo "Unzipping $1 to $OUT_ZIP_DIR"
	unzip -oq "$1" -d "$OUT_ZIP_DIR"
	
	# returning value with passing value to the variable name in last arg 
	if [ "x$3" != "x" ]; then
		eval $3="'$OUT_ZIP_DIR'"
	fi
}

# wget_all_linked_zip web_page_link output_dir result_var_name
# get all zip files from the passed webpage name
function wget_all_linked_zip() {
	local TO_DOWN=`echo "$1" | sed "s/^\(.*\)[/]$/\1/"` # strip off the last slash in the address
	wget -qO /dev/null "$1" # check existence of the page
	if [ $? -ne 0 ]; then
		echo "Web page '$1' is not available. Exiting..."
		exit 2
	fi
  wget -qO - "$TO_DOWN" | grep -ioP "<a\b[^<>]*?\b(href=\s*(?:\"[^\"]*\"|'[^']*'|\S+))" |\
  sed "s/.*href=[ \t'\"]*[\/]*\([^'\"]*\).*/\1/" | grep -ioP ".*\.zip$" |\
  while read ZIPFILE; do
  	wget -P "$2" "${TO_DOWN}/${ZIPFILE}"
  	break; #TODO - delete
  done
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


# all rest of params of this script
INPUT_PARAMS=($@)
# processing params
if [ $UNPACKED -gt 0 ]; then
  # already unpacked
  INPUT_DIRS=("${INPUT_PARAMS[@]}")
else
  for LOOP_ITEM in "${INPUT_PARAMS[@]}"; do
  	
  	# Download web page
  	if [ ! -d "$LOOP_ITEM" -a ! -s "$LOOP_ITEM" ]; then
	  	# where zip could be downloaded
			DIR_TO_DOWNLOAD_ZIPS="$OUTPUT_DIR/$DOWNLOAD_DIR_NAME"
			if [ ! -d "$DIR_TO_DOWNLOAD_ZIPS" ]; then
			  mkdir -p "$DIR_TO_DOWNLOAD_ZIPS"
			fi
  		# wget_all_linked_zip "$LOOP_ITEM" "$DIR_TO_DOWNLOAD_ZIPS"
  		LOOP_ITEM="$DIR_TO_DOWNLOAD_ZIPS"
  	fi
  	debug "Processing item from arguments (already processed by web page routine): $LOOP_ITEM"
  	
    # Getting list of unzipped directories
    if [ -d "$LOOP_ITEM" ]; then # directory - unzip all zip files
      for I in $LOOP_ITEM/*.zip; do
  	    unzip_with_dir "$I" "$OUTPUT_DIR" UNZIPPED_DIR
  	    debug "Returned unzipped dir $UNZIPPED_DIR" #DEBUG
  	    INPUT_DIRS[${#INPUT_DIRS[@]}]="$UNZIPPED_DIR"
      done
    elif [ -s "$LOOP_ITEM" ]; then
      unzip_with_dir "$LOOP_ITEM" "$OUTPUT_DIR" UNZIPPED_DIR
      debug "Returned unzipped dir $UNZIPPED_DIR" #DEBUG
      INPUT_DIRS=("$UNZIPPED_DIR")
    else 
      echo "The item to process ($LOOP_ITEM) is neither file nor directory. Exiting..."
      exit 3   
    fi
    
  done
fi

