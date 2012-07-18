#! /bin/bash

# Finishing on error of any command in this script
# set -e

# Paths and others
SCRIPT_PATH="$0"
SCRIPT_DIR=${0%\/*}
QALIB_DIR=${QALIB_DIR:-"${SCRIPT_DIR}/../qalib/"}
SVN_INIT_SCRIPT=${SVN_INIT_SCRIPT:-"${QALIB_DIR}/svn-init.sh"}
DIST_DIFF_INIT_SCRIPT=${DIST_DIFF_INIT_SCRIPT:-"${QALIB_DIR}/dist-diff-init.sh"}
DIST_DIFF_ANT_XML=${DIST_DIFF_ANT_XML:-"${QALIB_DIR}/dist-diff.xml"}
TATTLETALE_SCRIPT=${TATTLETALE_SCRIPT:-"tattletale.groovy"}
ANT_BIN=${ANT_BIN:-ant} # in default taking ant from PATH
GROOVY_JAR=${GROOVY_JAR:-/usr/share/java/groovy.jar} # path to groovy.jar file 
                                                     # in case that is not defined, trying to take from dist-diff svn

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
# quiet mode
IS_QUIET=

# Declaration of constants
TATTLETALE_REPORT_DIR_NAME="tattletale_reports"
TOMCAT_DIR_NAME_REGEXP='tomcat'
TOMCAT_DIR_NAME_REXEXP_NOT='doc\|conf'
EWS_DIST_NAME_PREFIX='jboss-ews-'
UNZIPED_JAR_DIR_SUFFIX=".unzipped"
# Declaration of global variables
declare -a INPUT_PARAMS
declare -a INPUT_DIRS

######################## FUNCTIONS ########################
function debug() {
  if [ "x$IS_DEBUG" != "x" ]; then
  	eecho "+ $1"
  fi
}

# echo function which respects IS_QUIET flag
function eecho() {
 if [ "x$IS_QUIET" == "x" ]; then
    echo "$1"
  fi
}

function just_name() {
  local FILENAME=`basename "$1"`
  local RESULT="${FILENAME%.*}"

  if [ "x$2" == "x" ]; then
  	echo -n "$RESULT"
  else
    eval $2="'$RESULT'"
  fi
}

trim() {
  local RESULT=$1
  RESULT="${RESULT#"${RESULT%%[![:space:]]*}"}" # remove leading whitespace characters
  RESULT="${RESULT%"${RESULT##*[![:space:]]}"}" # remove trailing whitespace characters
  
  if [ "x$2" == "x" ]; then
    echo -n "$RESULT"
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
  #	eecho "Folder $OUT_ZIP_DIR can't be created and zip file $1 can't be unzipped. Exiting..."
  #	exit 2
  #fi
	eecho "Unzipping $1 to $OUT_ZIP_DIR"
	unzip -oq "$1" -d "$OUT_ZIP_DIR"
	
	# returning value with passing value to the variable name in last arg 
	if [ "x$3" != "x" ]; then
		eval $3="'$OUT_ZIP_DIR'"
	fi
}

# wget_all_linked_zip web_page_link output_dir result_var_name
# get all zip files from the passed webpage name
# param1: http link to a page with list of zip files
function wget_all_linked_zip() {
	local TO_DOWN=`echo "$1" | sed "s/^\(.*\)[/]$/\1/"` # strip off the last slash in the address
	wget -qO /dev/null "$1" # check existence of the page
	if [ $? -ne 0 ]; then
		eecho "Web page '$1' is not available. Exiting..."
		exit 2
	fi
  wget -qO - "$TO_DOWN" | grep -ioP "<a\b[^<>]*?\b(href=\s*(?:\"[^\"]*\"|'[^']*'|\S+))" |\
  sed "s/.*href=[ \t'\"]*[\/]*\([^'\"]*\).*/\1/" | grep -ioP ".*\.zip$" |\
  while read ZIPFILE; do
  	wget -P "$2" "${TO_DOWN}/${ZIPFILE}"
  	# break; #TODO - delete
  done
}

# is the parameter a jar
# param1: name of file with path that will be tested to be jar
is_jar() {
  local JAR_NAME="$1"
  local EXTENSION=`echo ${JAR_NAME##*.} | tr '[:upper:]' '[:lower:]'`
  file --brief "$JAR_NAME" | grep -iq 'zip archive'
  if [ $? -eq 0 -a -s "$JAR_NAME" -a "$EXTENSION" = 'jar' ]; then
    return 0;
  else
    return 1
  fi
}

# calculate md5checksum on the dir recursively in case of jar files
# param1: dir to process
# param2: file where the checksums will be added
# param3: checksum filter regex (it could be e.g. '.*\.jar' or '.*' or nothing then '.*' is taken
# param4: will we jump to dir by cd (changing pwd)
calculate_md5checksums() {
  local DIR_TO_PROCESS="$1"
  local MD5_REPORT_FILE="$2"
  trim "$3" FILTER
  [ -z "$FILTER" ] && FILTER='.*'
  trim "$4" IS_START_DIR
  [ "x$IS_START_DIR" == "x" -o "$IS_START_DIR" == "0" ] && IS_START_DIR=
  
  [ -f "$MD5_REPORT_FILE" ] || touch "$MD5_REPORT_FILE"
  MD5_REPORT_FILE=`readlink -f "$MD5_REPORT_FILE"` # getting abs filepath
  debug "calculate_md5checksums params: DIR_TO_PROCESS=$DIR_TO_PROCESS, MD5_REPORT_FILE=$MD5_REPORT_FILE, FILTER=$FILTER,  IS_START_DIR=$IS_START_DIR"
  
  if [ "x$IS_START_DIR" != "x" ]; then 
  	cd "$DIR_TO_PROCESS"
  	DIR_TO_PROCESS="./"
  fi
  
  find "$DIR_TO_PROCESS" -iregex "$FILTER" | while read I; do
  	if [ -f "$I" ]; then
      md5sum "$I" >> "$MD5_REPORT_FILE"
      is_jar "$I"
      if [ $? -eq 0 ]; then # on jar recursively going down
      	local DIR_TO_UNZIP="${I}${UNZIPED_JAR_DIR_SUFFIX}"
        unzip -oq "$I" -d "$DIR_TO_UNZIP"
        calculate_md5checksums "$DIR_TO_UNZIP" "$MD5_REPORT_FILE" "$FILTER"
      fi
    fi
  done
  [ "x$IS_START_DIR" != "x" ] && cd -
}

# Cleaning directory and md5 report file after its creation
clean_after_md5calculation() {
  local DIR_TO_PROCESS="$1"
  local MD5_REPORT_FILE="$2"

  debug "Deleting temporarily unzipped jar files with suffix $UNZIPED_JAR_DIR_SUFFIX from $DIR_TO_PROCESS"
  find "$DIR_TO_PROCESS" -name "*${UNZIPED_JAR_DIR_SUFFIX}" | xargs rm -rf 
  debug "Sorting $MD5_REPORT_FILE..."
  sort -u -k2 "$MD5_REPORT_FILE" > "$MD5_REPORT_FILE.tmp"
  mv -f "$MD5_REPORT_FILE.tmp" "$MD5_REPORT_FILE"
}


######################## START OF EXECUTION ########################
# Option processing
#!/bin/sh
while [ $# -gt 0 ]; do
  case "$1" in
    -o | -output | --output)
      shift
      OUTPUT_DIR="$1"
      if [ ! -d "$OUTPUT_DIR" ]; then
      	mkdir -p "$OUTPUT_DIR"
      fi
      ;;
    -u | -unpacked | --unpacked)
      UNPACKED=1
      ;;
    -cp | -classpath | --classpath)
      shift
      CLASSPATH_ADD="$1"
      ;;
    -d | -debug | --debug)
      IS_DEBUG=1
      ;;
    -dd | -ddebug | --ddebug)
      IS_DEBUG=1
      set -x
      ;;
    -q | -quiet | --quiet)
      IS_QUIET=1
      ;;
      

    -h | --help)
      echo "Usage:"
      echo `basename $0` " [-ud] [-o output_dir] [-cp classpath_addition] file/dir/web_address"
      echo -e "-u or --unpacked             the arguments are directories which are already unpacked EWS distributions"
      echo -e "-o or --output dir           output directory"
      echo -e "-cp or --classpath classes   list of classes split by colon sing as it is normal in Linux."\
           "This Argument will be added as argument '-cp' of java programs."
      echo -e "-q or --quiet                quiet - no output messages please"
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
	eecho "The script needs parameter where it can find the zip files."
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
        wget_all_linked_zip "$LOOP_ITEM" "$DIR_TO_DOWNLOAD_ZIPS"
        LOOP_ITEM="$DIR_TO_DOWNLOAD_ZIPS"
    fi
    debug "Processing item from arguments (after checking by web page routine): $LOOP_ITEM"
  	
    # Getting list of unzipped directories
    if [ -d "$LOOP_ITEM" ]; then # directory - unzip all zip files
      while read I; do
  	    unzip_with_dir "$I" "$OUTPUT_DIR" UNZIPPED_DIR
        debug "Returned unzipped dir $UNZIPPED_DIR" #DEBUG
  	    INPUT_DIRS[${#INPUT_DIRS[@]}]="$UNZIPPED_DIR"
      done < <(find "$LOOP_ITEM" -iname '*.zip')
    elif [ -s "$LOOP_ITEM" ]; then
      unzip_with_dir "$LOOP_ITEM" "$OUTPUT_DIR" UNZIPPED_DIR
      debug "Returned unzipped dir $UNZIPPED_DIR" #DEBUG
      INPUT_DIRS[${#INPUT_DIRS[@]}]="$UNZIPPED_DIR"
    else 
      eecho "The item to process ($LOOP_ITEM) is neither file nor directory. Exiting..."
      exit 3   
    fi
    
  done
fi

# Do we have something to do?
if [ ${#INPUT_DIRS[@]} -lt 1 ]; then
  eecho "No files found to process. Exiting..."
  exit 11
fi

# Prepare directory structure
TATTLETALE_REPORT_DIR="${OUTPUT_DIR}/${TATTLETALE_REPORT_DIR_NAME}"
mkdir -p "$TATTLETALE_REPORT_DIR"
rm -rf "$TATTLETALE_REPORT_DIR"/*


####################### Tattletale + MD5 reports #######################
# for DIR_TO_PROCESS in "${INPUT_DIRS[@]}"; do
for DIR_TO_PROCESS in "${INPUT_DIRSS[@]}"; do
  DIR_TO_PROCESS_BASENAME=`basename "${DIR_TO_PROCESS}"`
  
  # Tattletale
  # Share dir contains tomcat distribution
  eecho "Processing tattletale report for $DIR_TO_PROCESS"
  TATTLETE_OUTPUT="${TATTLETALE_REPORT_DIR}/${DIR_TO_PROCESS_BASENAME}"
  mkdir -p "$TATTLETE_OUTPUT" 
  while read TOMCAT_DIR; do
    echo "groovy -Doutput=\"$TATTLETE_OUTPUT\" -Dtestdir=\"$TOMCAT_DIR\" \"${SCRIPT_DIR}/${TATTLETALE_SCRIPT}\""
    groovy -Doutput="$TATTLETE_OUTPUT" -Dtestdir="$TOMCAT_DIR" "${SCRIPT_DIR}/${TATTLETALE_SCRIPT}"
  done < <( find "$DIR_TO_PROCESS" -type d -name "*$TOMCAT_DIR_NAME_REGEXP*" | grep -v -e "$TOMCAT_DIR_NAME_REXEXP_NOT" )
  # TODO: currently just directories of tomcat is taken for tattletale script - at least maybe symbolic links could be take to aware of
  eecho "Tattletale report created for $DIR_TO_PROCESS. Output placed in $TATTLETE_OUTPUT"

  # MD5 checksums
  eecho "Calculating checksum on directory $DIR_TO_PROCESS"
  MD5_REPORT="${OUTPUT_DIR}/${DIR_TO_PROCESS_BASENAME}.md5"
  rm -rf "$MD5_REPORT"
  calculate_md5checksums "$DIR_TO_PROCESS" "$MD5_REPORT" '.*' 1
  clean_after_md5calculation "$DIR_TO_PROCESS" "$MD5_REPORT"
  # Filter for .class and .jar files
  MD5_REPORT_JARS_FILTERED="${OUTPUT_DIR}/${DIR_TO_PROCESS_BASENAME}.jars.md5"
  cat "$MD5_REPORT" | grep -e '\.class$\|\.jar$' > "$MD5_REPORT_JARS_FILTERED"
  eecho "MD5 checksum report created in $MD5_REPORT and $MD5_REPORT_JARS_FILTERED" 
  
  # MD5 checksum for just for jar files
  # eecho "Calculating checksum for jar files on directory $DIR_TO_PROCESS"
  # MD5_REPORT="${OUTPUT_DIR}/${DIR_TO_PROCESS_BASENAME}.jars.md5"
  # rm -rf "$MD5_REPORT"
  # calculate_md5checksums "$DIR_TO_PROCESS" "$MD5_REPORT" '.*\.jar\|.*\.class' 1
  # clean_after_md5calculation "$DIR_TO_PROCESS" "$MD5_REPORT"
  # eecho "MD5 checksum report created in $MD5_REPORT"
done


####################### DIST DIFF #######################
# Process dist-diff script on directories with similar content
which "$ANT_BIN" 2&> /dev/null && [ $? == 0 ] &&\
  echod "Ant command was not found on $ANT_BIN. Set ANT_BIN env variable correctly." && exit 1
# 
PREFIXES=
while read ITEM_FOLDER; do
  BASE_NAME=`basename "$ITEM_FOLDER"`; #httpd-2.0.0-ER5-RHEL6-x86_64
  WITHOUT_PREFIX=${BASE_NAME##$EWS_DIST_NAME_PREFIX}; #2.0.0-ER5-RHEL6-x86_64
  PROCESSING_PREFIX=${WITHOUT_PREFIX%%-*} # 2.0.0
  echo $PREFIXES | grep "$PROCESSING_PREFIX" > /dev/null # prefixes have to be unique
  if [ $? != 0 ]; then
    PREFIXES="$PREFIXES $PROCESSING_PREFIX "
  fi
done < <( find "$OUTPUT_DIR" -maxdepth 1 -type d | grep "$EWS_DIST_NAME_PREFIX" )
debug "Dir prefixes to work with: $PREFIXES"

# Download dist diff script from SVN
source "$SVN_INIT_SCRIPT"
source "$DIST_DIFF_INIT_SCRIPT"
DIST_DIFF_DIR="${OUTPUT_DIR}/dist-diff"
# property taken DISTDIFF_JAR from the function (function returns value to it) 
qalib_distdiff_init "$DIST_DIFF_DIR" DISTDIFF_JAR 

# checking existence of groovy jar
if [ ! -f "$GROOVY_JAR" ]; then
  GROOVY_JAR="${DIST_DIFF_DIR}/lib/groovy*jar" # trying to find groovy.jar in lib dir of dist-diff script
  [ ! -f "$GROOVY_JAR" ] &&\
    echod "Groovy lib jar was not found in $GROOVY_JAR. Set GROOVY_JAR env variable correctly." &&\
    exit 1
fi

# go through prefixes and for the same one do dist diff over each folder to each folder
for PREFIX in $PREFIXES; do
  PREFIX_EXPANDED="${OUTPUT_DIR}/${EWS_DIST_NAME_PREFIX}${PREFIX}"
  debug "Using dir prefix for dist diff: $PREFIX_EXPANDED"
  for I_OUTER_CYCLE in "$PREFIX_EXPANDED"*; do
  	# let's process dist diff - let's assume that we have three directories to compare 'a', 'b' and 'c'
  	# first outer cycle is filled by 'a', the inner cycle gets 'a' and then is_process is set to 1
  	# and we continue to 'b', 'a' is compared with 'b' and in next cycle with 'c'
  	# outer_cycle is filled by 'b', the inner cycle continue to next one because of is_process == 0
  	# then the i outer and inner are equals so is_process is set to 1 and continue to compare 'b' with 'c'
  	# cycle with c will do nothing
  	IS_PROCESS=0
    [ -d "$I_OUTER_CYCLE" ] && for I_INNER_CYCLE in "$PREFIX_EXPANDED"*; do
      [ "$I_OUTER_CYCLE" == "$I_INNER_CYCLE" ] && IS_PROCESS=1 && continue
      [ $IS_PROCESS -eq 0 ] && continue 
      if [ -d "$I_INNER_CYCLE" ]; then
      	eecho $I_OUTER_CYCLE
      	ORIG=`readlink -f "$I_OUTER_CYCLE"`
        NEW=`readlink -f "$I_INNER_CYCLE"`
        DIST_DIFF_LOG="${OUTPUT_DIR}/distdiff-${ORIG##*$PREFIX}--VS-${NEW##*$PREFIX}.log"
        $ANT_BIN -f "$DIST_DIFF_ANT_XML" -Dgroovyjar="$GROOVY_JAR" -Ddistdiffjar="$DISTDIFF_JAR" -Doriginal="$ORIG" -Dnew="$NEW" > "$DIST_DIFF_LOG"
        eecho "Dist diff log created in $DIST_DIFF_LOG"  
      fi
    done
  done
done