#!/bin/sh
#
# Initialization of DistDiff script
# Function which prepares dist diff jar. 

# DistDiff SVN trunk repo
QALIB_DISTDIFF_SVNTRUNK=${QALIB_DISTDIFF_SVNTRUNK:-https://svn.devel.redhat.com/repos/jboss-soa/trunk/qa/dist-diff/}
DIST_DIFF_ANT_CONFIG=${DIST_DIFF_ANT_CONFIG:-build-tasks.xml}
ANT_BIN=${ANT_BIN:-ant}

#
# Usage:
#   qalib_distdiff_init
#   Downloading dist-diff sources from svn and compile it
#   param1: directory name where the dist-diff distro will be downloaded to
#   param2: return variable name - dist-diff jar location will be returned
function qalib_distdiff_init() {
  local TO_DIR=${1:-"dist-diff"}
  local DIST_DIFF_LIB_NAME="dist-diff.jar"
	
  local OLD_PWD=`pwd`
  qalib_svn_checkout "$QALIB_DISTDIFF_SVNTRUNK" "$TO_DIR"
  [ $? != 0 ] && echo "Command qalib_svn_checkout is not known" && return 1
  cd "$TO_DIR"
  "$ANT_BIN" -f "$DIST_DIFF_ANT_CONFIG" compile
  [ $? != 0 ] && return 1
  rm -f "../${DIST_DIFF_LIB_NAME}"
  cd output/classes
  jar cf "../../${DIST_DIFF_LIB_NAME}" *
  cd "$OLD_PWD"
  
  # returning where the dist-diff.jar could be found
  if [ "x$2" != "x" ]; then
  	local JAR_FILE=`readlink -f "${TO_DIR}/${DIST_DIFF_LIB_NAME}"`
    eval $2="'$JAR_FILE'"
  fi
}
