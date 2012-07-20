#!/bin/sh
#
# Functions of portable SVN client operations
#

#
#  Usage:
#    qalib_svn_checkout <URL> <dir>
#      URL = URL for checking out
#      dir = directory where to check out (doesn't need to exist)
function qalib_svn_checkout() {
	if [ "${2}x" == "x" ]; then
		echo "DIR parameter is ommited!"
		return 1
	fi
	if [ "${1}x" == "x" ]; then
		echo "URL parameter is ommited!"
		return 1
	fi

	VERSION=$(expr "`cat /etc/redhat-release`" : '.*release \([^ .]*\)')
	if [ $VERSION -eq 4 ]; then
		echo p | svn co $1 $2
	else
		svn co --non-interactive --trust-server-cert $1 $2
	fi
}
