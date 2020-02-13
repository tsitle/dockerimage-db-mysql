#!/bin/bash

#
# by TS, Feb 2019
#

# ----------------------------------------------------------

#
# apache-php56-mysql55 (debian:wheezy):
#   Ver 14.14 Distrib 5.5.60,
# apache-php56-mysql56 (debian:wheezy):
#   Ver 14.14 Distrib 5.6.39,
# apache-php56/70/71/72/73-mariadb101 (debian:stretch):
#   Ver 15.1 Distrib 10.1.37-MariaDB,
# mariadb101 (debian:stretch):
#   Ver 15.1 Distrib 10.1.38-MariaDB,
# mariadb104 (debian:stretch):
#   Ver 15.1 Distrib 10.4.2-MariaDB,
#

# @return string Version string (e.g. "5.x", "8.x") -- or empty string if no compatible version could be found
function dbmysqlGetDbServerVersion() {
	TMP_MYSQL_VER=""
	TMP_MYSQL_VERSTR="$(mysql --version)"
	if \
			`echo "$TMP_MYSQL_VERSTR" | grep -q -e " Ver 14\.14 Distrib 5\.5\..*,"` || \
			`echo "$TMP_MYSQL_VERSTR" | grep -q -e " Ver 14\.14 Distrib 5\.6\..*,"` || \
			`echo "$TMP_MYSQL_VERSTR" | grep -q -e " Ver 14\.14 Distrib 5\.7\..*,"` || \
			`echo "$TMP_MYSQL_VERSTR" | grep -q -e " Ver 15\.1 Distrib 10\.1\..*\-MariaDB,"` \
			; then
		# MySQL 5.5 or MySQL 5.6 or MySQL 5.7 or MariaDB 10.1 (^= MySQL 5.7)
		TMP_MYSQL_VER="5.x"
	elif \
			`echo "$TMP_MYSQL_VERSTR" | grep -q -e " Ver 8\.0\..* for "` || \
			`echo "$TMP_MYSQL_VERSTR" | grep -q -e " Ver 15\.1 Distrib 10\.4\..*\-MariaDB,"` \
			; then
		# MySQL 8.0 or MariaDB 10.4 (^= MySQL 8.0)
		TMP_MYSQL_VER="8.x"
	else
		echo "dbmysqlGetDbServerVersion(): cannot find a compatible MySQL/MariaDB version !" >/dev/stderr
	fi
	echo "$TMP_MYSQL_VER"
}

# @return int 0=true, 1=false
function dbmysqlGetIsDbServerMariaDb() {
	TMP_MYSQL_IS_MARIADB=false
	TMP_MYSQL_VERSTR="$(mysql --version)"
	if `echo "$TMP_MYSQL_VERSTR" | grep -q -e " Ver .*\..* Distrib .*\-MariaDB,"`; then
		TMP_MYSQL_IS_MARIADB=true
	fi
	[ "$TMP_MYSQL_IS_MARIADB" = "true" ] && return 0 || return 1
}

# ----------------------------------------------------------
