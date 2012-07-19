#!/bin/bash
# The script takes argument of a dist-diff file 
# or you can pass the output of dist-diff to standard input of this script
# Then it takes data from the dist-diff file and parse the output
# and tries to show just important differences

# Constants
readonly NO_STATE=0
readonly ADDITION_STATE=1
readonly REMOVAL_STATE=2
readonly DIFF_STATE=3
readonly IS_ORIG="original";
readonly IS_NEW="new";
readonly DIFF_FILENAME="tmpdiff"

# RegExp
ACTION_REGEXP='^\[dist-diff\] 	\([a-zA-Z0-9\-\_]\+\)' # egrep (without -P) takes only ^V<tab>
FILE_REGEXP='^\[dist-diff\] 		\(.*\)'
ADDITION_FNC_REGEXP='Additions'
REMOVAL_FNC_REGEXP='Removals'
DIFF_FNC_REGEXP='Modifications'
ORIG_DIR_REGEXP='^.*Original dir:[	 ]*\(.*\)$'
NEW_DIR_REGEXP='^.*New dir:[	 ]*\(.*\)$'
JAR_REGEXP='\([^!]\+\)!\(.*\)'

# Variables
STATE=0
ORIGINAL_DIR=
NEW_DIR=
JARS=()
TMP_DIR=
IS_DEBUG=
IN_COLOR=
IS_SHOW_TEXT_DIFF=

# ########################## FUNCTIONS ####################################
echod() {
  if [ $IS_DEBUG ]; then echo "$1"; fi
}
echoc() {
  if [ $IN_COLOR ]; then echo -e "\e[00;31m${1}\e[00m"; else echo "$1"; fi
}

check() {
  echo "$1" | grep -qe "$2"
  return $?
}

# check whether element exists and add it to array
jar_exists() {
  if [ -z "$1" ]; then
    return 0
  fi

  local POS=0
  for I in ${JARS[@]}; do
    if [ "$I" == "$1" ]; then
      return 1
    else
      POS=$POS+1
    fi
  done
  JARS[$POS]="$1"
  return 0
}

# returns 1 for state of printing, 2 for state of check differences
# 0 for not defined state
get_state() {
  if check "$1" "$ADDITION_FNC_REGEXP"; then return $ADDITION_STATE; fi
  if check "$1" "$REMOVAL_FNC_REGEXP"; then return $REMOVAL_STATE; fi
  if check "$1" "$DIFF_FNC_REGEXP"; then return $DIFF_STATE; fi
  return $NO_STATE
}

# try to find information about directory in first argument
check_dir() {
  if check "$1" "$ORIG_DIR_REGEXP"; then ORIGINAL_DIR=`echo "$1" | sed "s/${ORIG_DIR_REGEXP}/\1/"`; echod "origdir: $ORIGINAL_DIR"; return 0; fi
  if check "$1" "$NEW_DIR_REGEXP"; then NEW_DIR=`echo "$1" | sed "s/${NEW_DIR_REGEXP}/\1/"`; echod "newdir: $NEW_DIR"; return 0; fi
}

# checking state of file on basis of current state
check_file() {
  echod
  echod "We are in state: $STATE"
  case $STATE in
    $ADDITION_STATE)
      get_filename "$1" "$IS_NEW"
      action_rule_existence "$ABS_FILENAME"
    ;;
    $REMOVAL_STATE)
      get_filename "$1" "$IS_ORIG" 
      action_rule_existence "$ABS_FILENAME"
    ;;
    $DIFF_STATE)
      get_filename "$1" "$IS_NEW" 
      local FILE_ORIG=$ABS_FILENAME
      get_filename "$1" "$IS_ORIG"
      local FILE_NEW=$ABS_FILENAME
      action_rule_diff "$FILE_ORIG" "$FILE_NEW"
    ;;
    *)
      echod "File ${1} was not parsed - undefined state."
    ;;
  esac
  echod
}

# set filenames 
get_filename() {
  local FILE="$1"
  local INNER_STATE="$2"
  # on basis of passed state defining dir where file could be found
  if [ "$INNER_STATE" == "$IS_NEW" ]; then DIR="$NEW_DIR"; fi
  if [ "$INNER_STATE" == "$IS_ORIG" ]; then DIR="$ORIGINAL_DIR"; fi
  ABS_FILENAME="${DIR}/${FILE}"

  # check whether the name is jar with some filename  
  if check "$FILE" "$JAR_REGEXP"; then 
    JAR_NAME=`echo "$FILE" | sed "s/${JAR_REGEXP}/\1/"`
    JAR_FILE_IN_ARCHIVE=`echo "$FILE" | sed "s/${JAR_REGEXP}/\2/"`
    echod "${FILE} is jar file - parsed to: ${JAR_NAME}:${JAR_FILE_IN_ARCHIVE}"
    
    if jar_exists "${JAR_NAME}-${INNER_STATE}"; then 
      echod "'${JAR_NAME}-${INNER_STATE}' did not exist in jar array - it was added"; 
      unzip_jar "$JAR_NAME" "$INNER_STATE"
    fi
    # setting path to unzipped content
    ABS_FILENAME="${TMP_DIR}/${INNER_STATE}/${JAR_NAME}/${JAR_FILE_IN_ARCHIVE}"
  fi
  echod "get_filename(): file: $FILE, inner state: $INNER_STATE, absolute path to file: $ABS_FILENAME"
}

# trying to unzip jar
unzip_jar() {
  JAR_NAME="$1"
  TMP_STATE_DIR="$2"

  create_tmp_dir

  # data unzipping
  TMP_DEST_DIR="${TMP_DIR}/${TMP_STATE_DIR}/${JAR_NAME}"
  mkdir -p "$TMP_DEST_DIR"
  unzip -q "${DIR}/${1}" -d "$TMP_DEST_DIR"
}

create_tmp_dir() {
  if [ ! -d "$TMP_DIR" ]; then
    TMP_DIR=`mktemp -d --suffix="#distdiff"`
    echod "Tmp dir created: ${TMP_DIR}"
  fi
}

get_type() {
  local FILETOCHECK="$1"
  # set +H
  TYPE=`file -b ${FILETOCHECK}`
  echod "TYPE=\`file -b \"${FILETOCHECK}\"\`, typeis: $TYPE"
}

action_rule_existence() {
  local FILE="$1"
  get_type "$FILE"

  case $TYPE in
    [dD]irectory) 
       # Directory will be skipped
       echod "$RAW_FILENAME is directory - skipping"
    ;;
    *)
      # Other types can't be added or removed anyway
      echoc $RAW_FILENAME
    ;;
  esac
}

action_rule_diff() {
  # original file
  local FILE_ORIG="$1"
  get_type "$FILE_ORIG"
  local TYPE_ORIG=$TYPE
  # new file
  local FILE_NEW="$2"
  get_type "$FILE_NEW"
  local TYPE_NEW=$TYPE

  case $TYPE in
    [dD]irectory*) 
      # Directory will be skipped (echoed as debug)
      echod "$RAW_FILENAME is a directory - skipping"
    ;;
    *ELF*|*PE*executable*)
      # Binary file (echoed as debug)
      echod "$RAW_FILENAME is a binary file - skipping"
    ;;
    *[Jj]ava*)
       # Decompile java file and check differencies 
       local ORIG_DIR=${FILE_ORIG%/*}
       local NEW_DIR=${FILE_NEW%/*}
       local ORIG_BASENAME=`basename "$FILE_ORIG"`
       local NEW_BASENAME=`basename "$FILE_NEW"`
       local ORIG_JUST_NAME=${ORIG_BASENAME%.*}
       local NEW_JUST_NAME=${NEW_BASENAME%.*}
       local ORIG_JAVA_FILE="${ORIG_DIR}/${ORIG_JUST_NAME}.java"
       local NEW_JAVA_FILE="${NEW_DIR}/${NEW_JUST_NAME}.java"
       javap -classpath "$ORIG_DIR" "$ORIG_JUST_NAME" > "$ORIG_JAVA_FILE" 
       javap -classpath "$NEW_DIR" "$NEW_JUST_NAME" > "$NEW_JAVA_FILE"
       action_diff_text "$ORIG_JAVA_FILE" "$NEW_JAVA_FILE" "Java file: $RAW_FILENAME"
    ;;
    *text*) 
       # Check text file differences
       echod "Files '$FILE_ORIG' and '$FILE_NEW' are text files - need to check them"
       action_diff_text "$FILE_ORIG" "$FILE_NEW" "Text file: $RAW_FILENAME"
    ;;
    *)
      # Other types can't be checked
      echoc $RAW_FILENAME
    ;;
  esac
}

action_diff_text() {
  local FILE_ORIG="$1"
  local FILE_NEW="$2"
  local TO_PRINT=${3:-`basename $FILE_ORIG`}
  local TMP_FILE="${TMP_DIR}/${DIFF_FILENAME}"
  
  diff --strip-trailing-cr "$FILE_ORIG" "$FILE_NEW" > "$TMP_FILE" 

  if [ -s "$TMP_FILE" ]; then
  	echo "$TO_PRINT"
  	[ $IS_SHOW_TEXT_DIFF ] && cat "$TMP_FILE" && echo
  else
    echod "Nodiff in files $FILE_ORIG and $FILE_NEW" 
  fi
}

# ########################## START OF EXECUTION ####################################
while getopts "dhct" opt; do
  case $opt in
    d) 
      IS_DEBUG=TRUE 
      echod "Setting debug printing mode..."
    ;;
    c) 
      IN_COLOR=TRUE 
      echod "Color printing mode..."
    ;;
    t)
      IS_SHOW_TEXT_DIFF=TRUE
      echod "Text diff will be printed"
    ;;
    ?)
     echo "Usage: $0 [-d] [-h] [-t] filename"
     echo "  -d  debug printing mode"
     echo "  -h  prints this help"
     echo "  -c  prints in colors"
     echo "  -t  prints text diffs (for text files or decompiled java files)"
     exit;
    ;;
  esac
done
# shifting last opt to get name of file
shift $(( OPTIND - 1 )) 
# echo "[otheropts]==> $@"

# Creating tmp dir where files will be unzipped and diffed
create_tmp_dir

while read line; do 
  # checking state here
  if check "$line" "$ACTION_REGEXP"; then
    STR_STATE=`echo "$line" | sed "s/${ACTION_REGEXP}/\1/"`
    get_state "$STR_STATE"
    STATE="$?"
    echod "Setting state to $STR_STATE ($STATE)"
    echo $line
    continue
  fi
  
  # in case of defined state and existence of directories of comparision 
  # and the current line contains $FILE_REGEXP pattern - then do check on file
  if [ $STATE != 0 ] && [ -n $ORIG_DIR ] && [ -n $NEW_DIR ] && check "$line" "$FILE_REGEXP"; then
    RAW_FILENAME=`echo "$line" | sed "s/${FILE_REGEXP}/\1/"`
    check_file "$RAW_FILENAME"
    continue
  fi

  # check definition of directory - especially on first lines (looking e.g. for .*Original dir: path_to_dir) 
  # we need to know where the files of comparision could be found 
  check_dir "$line"
  # no other info for what to do - print line
  echo $line

# Bash magic - reading from file (first arg) or from stdin
# The substitution ${1:-...} takes $1 if defined otherwise the file name of the standard input of the own process is used.
# ${$} is the process id of the current shell.
done  < "${1:-/proc/${$}/fd/0}"

# echo "TMP directory $TMP_DIR was not removed!"
if [ -d "$TMP_DIR" ]; then
 echo "Removing everything from $TMP_DIR"
 rm -rf "$TMP_DIR"
fi
