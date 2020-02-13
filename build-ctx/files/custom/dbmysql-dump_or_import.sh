#!/bin/bash

#
# by TS, Jan 2019
#

VAR_MYNAME="$(basename "$0")"

# ----------------------------------------------------------

CF_SYSUSR_MYSQL_USER_ID=${CF_SYSUSR_MYSQL_USER_ID:-911}
CF_SYSUSR_MYSQL_GROUP_ID=${CF_SYSUSR_MYSQL_GROUP_ID:-911}

# ----------------------------------------------------------

function showUsage() {
	echo "Usage: $VAR_MYNAME dump|import|ls [<DBHOST> <DBPORT> <DBROOTPASS> <DBSCHEMENAME> <DBUSERNAME> <DBUSERPASS> <FILENAME>]|[<SUBDIR>]" >/dev/stderr
	echo "Examples: $VAR_MYNAME ls" >/dev/stderr
	echo "          $VAR_MYNAME ls SugarCRM-DB-BFB-190215-dev" >/dev/stderr
	echo "          $VAR_MYNAME import 127.0.0.1 3306 rootpass testdb testuser testpass dbdump.sql" >/dev/stderr
	echo "          $VAR_MYNAME import 127.0.0.1 3306 rootpass testdb testuser testpass dbdump.sql.gz" >/dev/stderr
	echo "          $VAR_MYNAME dump 127.0.0.1 3306 rootpass testdb testuser testpass dbdump.sql" >/dev/stderr
	exit 1
}

if [ $# -lt 1 ]; then
	showUsage
fi

PAR_CMD="$1"

if [ "$PAR_CMD" != "dump" -a "$PAR_CMD" != "import" -a "$PAR_CMD" != "imp" -a "$PAR_CMD" != "ls" ]; then
	showUsage
fi

if [ "$PAR_CMD" != "ls" -a $# -lt 8 ]; then
	showUsage
fi

shift

PAR_DBHOST_OR_SUBDIR="$1"

PAR_DBHOST=""
PAR_SUBDIR=""
if [ "$PAR_CMD" != "ls" ]; then
	PAR_DBHOST="$PAR_DBHOST_OR_SUBDIR"
else
	PAR_SUBDIR="$PAR_DBHOST_OR_SUBDIR"
fi

PAR_DBPORT="$2"
PAR_DBROOTPW="$3"
PAR_DBN="$4"
PAR_DBU="$5"
PAR_DBP="$6"
PAR_FN="$7"

if [ "$PAR_CMD" != "ls" ]; then
	if [ -z "$PAR_DBHOST" -o -z "$PAR_DBPORT" -o -z "$PAR_DBROOTPW" -o -z "$PAR_DBN" -o -z "$PAR_DBU" -o -z "$PAR_DBP" -o -z "$PAR_FN" ]; then
		showUsage
	fi
fi

# ----------------------------------------------------------

cd /root || exit 1

. /root/inc-dbmysql.sh || exit 1

VAR_MYSQL_VER="$(dbmysqlGetDbServerVersion)"

VAR_MYSQL_IS_MARIADB=false
dbmysqlGetIsDbServerMariaDb && VAR_MYSQL_IS_MARIADB=true
#echo "VER='$VAR_MYSQL_VER'"
#echo -n "ISMDB="
#[ "$VAR_MYSQL_IS_MARIADB" = "true" ] && echo y || echo n

VAR_EXTDBFILES_DIR="extDbFiles"

# ----------------------------------------------------------

if [ "$PAR_CMD" = "ls" ]; then
	# List files
	cd "$VAR_EXTDBFILES_DIR" || exit 1
	if [ -n "$PAR_SUBDIR" ]; then
		echo -e "\nListing of subdirectory '$VAR_EXTDBFILES_DIR/$PAR_SUBDIR':\n"
		ls -l "$PAR_SUBDIR"
	else
		echo -e "\nListing of directory '$VAR_EXTDBFILES_DIR/':\n"
		ls -l
	fi
elif [ "$PAR_CMD" = "dump" ]; then
	# Dump Database Scheme to SQL file
	if [ -d "$PAR_FN" ] || ! `echo -n "$PAR_FN" | grep -q -e "\.sql$" -e "\.gz$" -e "\.gz\.aa$"`; then
		# if we were provided with a directory name then turn it into a filename
		PAR_FN="$(echo -n "$PAR_FN" | sed -e 's/\/$//')"
		PAR_FN="$PAR_FN/$(basename "${PAR_FN}").sql"
	fi
	echo -n "$PAR_FN" | grep -q "\.gz$" && {
		PAR_FN="$(echo -n "$PAR_FN" | sed -e 's/\.gz$//')"
	}
	echo -n "$PAR_FN" | grep -q "\.gz\.aa$" && {
		PAR_FN="$(echo -n "$PAR_FN" | sed -e 's/\.gz\.aa$//')"
	}
	#echo -n "$PAR_FN" | grep -q "\.sql$" || {
	#	PAR_FN="${PAR_FN}.sql"
	#}

	cd "/root/$VAR_EXTDBFILES_DIR" || exit 1

	if `echo -n "$PAR_FN" | grep -q "/"`; then
		TMP_DIRN="$(dirname "$PAR_FN")"
		mkdir -p "$TMP_DIRN" || exit 1
		chown $CF_SYSUSR_MYSQL_USER_ID:$CF_SYSUSR_MYSQL_GROUP_ID "$TMP_DIRN"

		TMP_DIRN="$(echo -n "$TMP_DIRN" | sed -e "s/^$VAR_EXTDBFILES_DIR\///")"
		if `echo -n "$TMP_DIRN" | grep -q "/"`; then
			while [ 1 ]; do
				TMP_DIRN="$(dirname "$TMP_DIRN")"
				[ "$TMP_DIRN" = "." -o "$TMP_DIRN" = "./" -o -z "$TMP_DIRN" ] && break

				chown $CF_SYSUSR_MYSQL_USER_ID:$CF_SYSUSR_MYSQL_GROUP_ID "/root/$VAR_EXTDBFILES_DIR/$TMP_DIRN"
			done
		fi
	fi

	rm "${PAR_FN}".gz.* 2> /dev/null
	rm "${PAR_FN}".gz 2> /dev/null

	echo "$VAR_MYNAME: Dumping DB to '${PAR_FN}'..."
	mysqldump \
			"$PAR_DBN" \
			-h "$PAR_DBHOST" \
			--port=$PAR_DBPORT \
			-u "$PAR_DBU" \
			--password="$PAR_DBP" \
			--add-drop-table > "$PAR_FN" || exit 1
	echo "$VAR_MYNAME: Gzipping SQL file..."
	gzip -c "$PAR_FN" | split -b $(( 1024 * 1024 * 100 )) - "${PAR_FN}.gz."
	if [ -f "${PAR_FN}.gz.aa" -a ! -f "${PAR_FN}.gz.ab" ]; then
		mv "${PAR_FN}.gz.aa" "${PAR_FN}.gz"
	fi
	rm "$PAR_FN"
	chown $CF_SYSUSR_MYSQL_USER_ID:$CF_SYSUSR_MYSQL_GROUP_ID "${PAR_FN}.gz"*
else
	# Import SQL file
	cd "/root/$VAR_EXTDBFILES_DIR" || exit 1

	if [ -d "$PAR_FN" ]; then
		# if we were provided with a directory name then turn it into a filename
		PAR_FN="$(echo -n "$PAR_FN" | sed -e 's/\/$//')"
		PAR_FN="$PAR_FN/$(basename "${PAR_FN}").sql"
	fi
	if [ ! -f "$PAR_FN" -a ! -f "${PAR_FN}.gz" -a ! -f "${PAR_FN}.gz.aa" ]; then
		echo "$VAR_MYNAME: File '$PAR_FN' not found!" >/dev/stderr
		exit 1
	fi

	#
	/root/dbmysql-create_db_and_user.sh \
			"$PAR_DBHOST" \
			$PAR_DBPORT \
			"$PAR_DBROOTPW" \
			"$PAR_DBN" \
			"$PAR_DBU" \
			"$PAR_DBP" || exit 1

	cd "/root/$VAR_EXTDBFILES_DIR" || exit 1

	#
	echo "$VAR_MYNAME: Importing DB..."
	echo -n "$PAR_FN" | grep -q -e "\.gz$" -e "\.gz\.aa$"
	if [ $? -ne 0 ]; then
		if [ -f "${PAR_FN}.gz.aa" ]; then
			PAR_FN="${PAR_FN}.gz.aa"
		elif [ -f "${PAR_FN}.gz" ]; then
			PAR_FN="${PAR_FN}.gz"
		fi
	fi

	echo -n "$PAR_FN" | grep -q -e "\.gz$" -e "\.gz\.aa$"
	if [ $? -eq 0 ]; then
		echo -n "$PAR_FN" | grep -q "\.gz$"
		if [ $? -eq 0 ]; then
			LOC_BFN="$(basename "$PAR_FN" ".gz")"
			gunzip -c "$(dirname "$PAR_FN")/${LOC_BFN}.gz" | \
					mysql \
							"$PAR_DBN" \
							-h "$PAR_DBHOST" \
							--port=$PAR_DBPORT \
							-u "$PAR_DBU" \
							--password="$PAR_DBP" || exit 1
		else
			LOC_BFN="$(basename "$PAR_FN" ".aa")"
			cat "$(dirname "$PAR_FN")"/"${LOC_BFN}".* | gunzip | \
					mysql \
						"$PAR_DBN" \
						-h "$PAR_DBHOST" \
						--port=$PAR_DBPORT \
						-u "$PAR_DBU" \
						--password="$PAR_DBP" || exit 1
		fi
	else
		mysql \
				"$PAR_DBN" \
				-h "$PAR_DBHOST" \
				--port=$PAR_DBPORT \
				-u "$PAR_DBU" \
				--password="$PAR_DBP" < "$PAR_FN" || exit 1
	fi
fi

if [ "$PAR_CMD" != "ls" ]; then
	echo "$VAR_MYNAME: Done."
fi
