#!/bin/bash

#
# Change DB root password - only possible if it was empty before
#
# by TS, May 2019
#

VAR_MYNAME="$(basename "$0")"

# ----------------------------------------------------------------------

function _updateRootPw() {
	local TMP_SLEN=0
	# test for empty password variable, if it's set to 0 or less than 4 characters
	if [ -n "$CF_DB_ROOT_PASSWORD" ]; then
		TMP_SLEN=${#CF_DB_ROOT_PASSWORD}
	fi

	local TMP_RES=0
	if [ $TMP_SLEN -lt 4 ]; then
		echo "$VAR_MYNAME: Error: length of DB root password in CF_DB_ROOT_PASSWORD is < 4. Aborting" >/dev/stderr
		return 1
	fi
	echo "$VAR_MYNAME: Updating DB root password from CF_DB_ROOT_PASSWORD..."
	mysqladmin -u root password "$CF_DB_ROOT_PASSWORD"
	TMP_RES=$?

	if [ $TMP_RES -eq 0 ]; then
		echo "$VAR_MYNAME: Done."
	else
		echo "$VAR_MYNAME: Error: errcode=$TMP_RES !" >/dev/stderr
	fi
	return $TMP_RES
}

_updateRootPw

exit $?
