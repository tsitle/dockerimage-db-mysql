#!/bin/bash

#
# by TS, Jan 2019
#

VAR_MYNAME="$(basename "$0")"
VAR_MYDIR="$(realpath "$0")"
VAR_MYDIR="$(dirname "$VAR_MYDIR")"

# ----------------------------------------------------------

function showUsage() {
	echo "Usage: $VAR_MYNAME [--grant-super] <DBHOST> <DBPORT> <DBROOTPASS> <DBSCHEMANAME> <DBUSERNAME> <DBUSERPASS>" >/dev/stderr
	echo "Example: $VAR_MYNAME 127.0.0.1 3306 rootpass testdb testuser testpass" >/dev/stderr
	exit 1
}

if [ $# -eq 0 ] || [ "$1" = "--help" -o "$1" = "-h" ]; then
	showUsage
fi

OPT_GRANT_SUPER=false
if [ "$1" = "--grant-super" ]; then
	OPT_GRANT_SUPER=true
	shift
fi

if [ $# -ne 6 ]; then
	showUsage
fi

PAR_DBHOST="$1"
PAR_DBPORT="$2"
PAR_DBROOTPW="$3"
PAR_DBN="$4"
PAR_DBU="$5"
PAR_DBP="$6"

#echo "HOST=$PAR_DBHOST"
#echo "PORT=$PAR_DBPORT"
#echo "N=$PAR_DBN"
#echo "U=$PAR_DBU"
#echo "P=$PAR_DBP"

if [ -z "$PAR_DBHOST" -o -z "$PAR_DBPORT" -o -z "$PAR_DBROOTPW" -o -z "$PAR_DBN" -o -z "$PAR_DBU" -o -z "$PAR_DBP" ]; then
	showUsage
fi

# ----------------------------------------------------------

. "$VAR_MYDIR"/inc-dbmysql.sh || exit 1

VAR_MYSQL_VER="$(dbmysqlGetDbServerVersion)"

VAR_MYSQL_IS_MARIADB=false
dbmysqlGetIsDbServerMariaDb && VAR_MYSQL_IS_MARIADB=true
#echo "VER='$VAR_MYSQL_VER'"
#echo -n "ISMDB="
#[ "$VAR_MYSQL_IS_MARIADB" = "true" ] && echo y || echo n

# ----------------------------------------------------------

#
echo "$VAR_MYNAME: Dropping old DB if exists and creating new one..."
TMPCMD="DROP DATABASE IF EXISTS \`$PAR_DBN\`; \
		CREATE DATABASE \`$PAR_DBN\` CHARACTER SET utf8 COLLATE utf8_general_ci;"
mysql \
		-h "$PAR_DBHOST" \
		--port=$PAR_DBPORT \
		-u "root" \
		--password="$PAR_DBROOTPW" \
		-e "$TMPCMD" || exit 1

echo "$VAR_MYNAME: Creating DB-User if necessary and setting password..."
TMPCMD="CREATE USER IF NOT EXISTS '$PAR_DBU'@'%' IDENTIFIED WITH mysql_native_password;"
if [ "$VAR_MYSQL_IS_MARIADB" = "true" ]; then
	TMPCMD="${TMPCMD} \
			SET PASSWORD FOR '$PAR_DBU'@'%' = PASSWORD('$PAR_DBP');"
else
	TMPCMD="${TMPCMD} \
			SET PASSWORD FOR '$PAR_DBU'@'%' = '$PAR_DBP';"
fi
mysql \
		-h "$PAR_DBHOST" \
		--port=$PAR_DBPORT \
		-u "root" \
		--password="$PAR_DBROOTPW" \
		-e "$TMPCMD" || exit 1

echo "$VAR_MYNAME: Setting privileges for DB-User..."
echo "  Revoke all privileges (in case the user already existed)..."
TMPCMD="REVOKE ALL PRIVILEGES ON \`$PAR_DBN\`.* FROM '$PAR_DBU'@'%';"
mysql \
		-h "$PAR_DBHOST" \
		--port=$PAR_DBPORT \
		-u "root" \
		--password="$PAR_DBROOTPW" \
		-e "$TMPCMD" >/dev/null 2>&1

echo "  Grant all default privileges..."
TMPCMD="GRANT ALL PRIVILEGES ON \`$PAR_DBN\`.* TO '$PAR_DBU'@'%';"
mysql \
		-h "$PAR_DBHOST" \
		--port=$PAR_DBPORT \
		-u "root" \
		--password="$PAR_DBROOTPW" \
		-e "$TMPCMD" || exit 1

if [ "$OPT_GRANT_SUPER" = "true" ]; then
	echo "  Grant SUPER privilege..."
	TMPCMD=""
	if [ "$VAR_MYSQL_VER" = "5.x" ]; then
		# MySQL 5.5 or MySQL 5.6 or MariaDB 10.1 (^= MySQL 5.7)
		TMPCMD="GRANT SUPER ON *.* TO '$PAR_DBU'@'%' REQUIRE NONE WITH MAX_QUERIES_PER_HOUR 0 MAX_CONNECTIONS_PER_HOUR 0 MAX_UPDATES_PER_HOUR 0 MAX_USER_CONNECTIONS 0;"
	elif [ "$VAR_MYSQL_VER" = "8.x" ]; then
		# MySQL 8.0.x
		TMPCMD="GRANT SUPER ON *.* TO '$PAR_DBU'@'%' WITH GRANT OPTION;"
	else
		echo "$VAR_MYNAME: incompatible MySQL/MariaDB version specified. Aborting." >/dev/stderr
		exit 1
	fi
	mysql \
			-h "$PAR_DBHOST" \
			--port=$PAR_DBPORT \
			-u "root" \
			--password="$PAR_DBROOTPW" \
			-e "$TMPCMD" || exit 1
fi

echo "$VAR_MYNAME: Done."
