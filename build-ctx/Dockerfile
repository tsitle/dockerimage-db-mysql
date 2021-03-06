#
# Based on
#   https://github.com/docker-library/mysql/blob/master/5.7/Dockerfile
#

ARG CF_SRC_OS_IMAGE

FROM ${CF_SRC_OS_IMAGE}

ARG CF_CPUARCH_DEB_DIST
ENV CF_CPUARCH_DEB_DIST=${CF_CPUARCH_DEB_DIST}

ARG CF_MYSQL_VERSION

# ------------------------------------------------------------------------------

ENV DEBIAN_FRONTEND="noninteractive"

#
RUN \
	apt-get update \
	&& apt-get upgrade -y \
	&& apt-get dist-upgrade -y

# ------------------------------------------------------------------------------
# ------------------------------------------------------------------------------
# beg docker-library/mysql (v5.7)
# ------------------------------------------------------------------------------
# ------------------------------------------------------------------------------

# add our user and group first to make sure their IDs get assigned consistently,
# regardless of whatever dependencies get added
RUN \
	groupadd -r mysql \
	&& useradd -r -g mysql mysql

#RUN \
#	apt-get update \
#	&& apt-get install -y --no-install-recommends \
#			gnupg dirmngr \
#	#& rm -rf /var/lib/apt/lists/*

RUN \
	apt-get install -y --no-install-recommends \
			mysql-server-${CF_MYSQL_VERSION} \
			mysql-client-${CF_MYSQL_VERSION}

# add gosu for easy step-down from root
ENV GOSU_VERSION 1.7
RUN \
	set -x \
	#&& apt-get update \
	#&& apt-get install -y --no-install-recommends \
	#		ca-certificates wget \
	#&& rm -rf /var/lib/apt/lists/* \
	&& wget -O /usr/local/bin/gosu "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$(dpkg --print-architecture)" \
	&& wget -O /usr/local/bin/gosu.asc "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$(dpkg --print-architecture).asc" \
	|| exit 1; \
	#
	#export GNUPGHOME="$(mktemp -d)"; \
	echo -n \
	#
	#key="B42F6819007F00F88E364FD4036A9C25BF357DD4"; \
	##&& gpg --batch --keyserver ha.pool.sks-keyservers.net --recv-keys "$key" \
	#gpg --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys "$key" \
	#|| gpg --keyserver hkp://ipv4.pool.sks-keyservers.net --recv-keys "$key" \
	#|| gpg --keyserver hkp://pgp.mit.edu:80 --recv-keys "$key" \
	#|| exit 1; \
	#gpg --batch --verify /usr/local/bin/gosu.asc /usr/local/bin/gosu \
	#&& gpgconf --kill all \
	#&& rm -rf "$GNUPGHOME" /usr/local/bin/gosu.asc \
	&& chmod +x /usr/local/bin/gosu \
	&& gosu nobody true \
	&& echo -n
	#&& apt-get purge -y --auto-remove \
	#		ca-certificates wget

RUN \
	mkdir /docker-entrypoint-initdb.d

RUN \
	apt-get update \
	&& apt-get install -y --no-install-recommends \
			# for MYSQL_RANDOM_ROOT_PASSWORD
				pwgen \
			# for mysql_ssl_rsa_setup
				openssl \
			# FATAL ERROR: please install the following Perl modules before executing /usr/local/mysql/scripts/mysql_install_db:
				# File::Basename
				# File::Copy
				# Sys::Hostname
				# Data::Dumper
					perl \
	&& rm -rf /var/lib/apt/lists/*

#RUN \
#	set -ex; \
#	# gpg: key 5072E1F5: public key "MySQL Release Engineering <mysql-build@oss.oracle.com>" imported
#	key='A4A9406876FCBD3C456770C88C718D3B5072E1F5'; \
#	export GNUPGHOME="$(mktemp -d)"; \
#	#
#	#gpg --batch --keyserver ha.pool.sks-keyservers.net --recv-keys "$key"; \
#	gpg --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys "$key" \
#	|| gpg --keyserver hkp://ipv4.pool.sks-keyservers.net --recv-keys "$key" \
#	|| gpg --keyserver hkp://pgp.mit.edu:80 --recv-keys "$key" \
#	|| exit 1; \
#	#
#	gpg --batch --export "$key" > /etc/apt/trusted.gpg.d/mysql.gpg; \
#	gpgconf --kill all; \
#	rm -rf "$GNUPGHOME"; \
#	apt-key list > /dev/null

#ENV MYSQL_VERSION 5.7.29-1debian9

#RUN \
#	echo "deb http://repo.mysql.com/apt/debian/ ${CF_DEBIAN_RELEASE} mysql-${CF_MYSQL_VERSION}" > /etc/apt/sources.list.d/mysql.list

# the "/var/lib/mysql" stuff here is because the mysql-server postinst doesn't have an explicit way to disable the mysql_install_db codepath besides having a database already "configured" (ie, stuff in /var/lib/mysql/mysql)
# also, we set debconf keys to make APT a little quieter
RUN { \
		echo mysql-community-server mysql-community-server/data-dir select ''; \
		echo mysql-community-server mysql-community-server/root-pass password ''; \
		echo mysql-community-server mysql-community-server/re-root-pass password ''; \
		echo mysql-community-server mysql-community-server/remove-test-db select false; \
	} | debconf-set-selections \
	#&& apt-get update \
	#&& apt-get install -y \
	#		mysql-server="${MYSQL_VERSION}" \
	#&& rm -rf /var/lib/apt/lists/* \
	#
	&& test -d /var/lib/mysql && rm -rf /var/lib/mysql \
	|| echo -n; \
	mkdir -p /var/lib/mysql /var/run/mysqld \
	&& chown -R mysql:mysql /var/lib/mysql /var/run/mysqld \
	# ensure that /var/run/mysqld (used for socket and lock files) is writable regardless of the UID our mysqld instance ends up having at runtime
	&& chmod 777 /var/run/mysqld \
	# comment out a few problematic configuration values
	&& find /etc/mysql/ -name '*.cnf' -print0 \
		| xargs -0 grep -lZE '^(bind-address|log)' \
		| xargs -rt -0 sed -Ei 's/^(bind-address|log)/#&/' \
	# don't reverse lookup hostnames, they are usually another container
	#&& test -d /etc/mysql/conf.d || mkdir -p /etc/mysql/conf.d; \
	&& echo '[mysqld]\nskip-host-cache\nskip-name-resolve' > /etc/mysql/conf.d/docker.cnf

VOLUME /var/lib/mysql

COPY files/docker-entrypoint-vendor.sh /usr/local/bin/
RUN \
	chown root:root /usr/local/bin/docker-entrypoint-vendor.sh \
	&& chmod a+x /usr/local/bin/docker-entrypoint-vendor.sh
	#&& ln -s usr/local/bin/docker-entrypoint.sh /entrypoint.sh # backwards compat
#ENTRYPOINT ["docker-entrypoint.sh"]

#EXPOSE 3306 33060
CMD ["mysqld"]

# ------------------------------------------------------------------------------
# ------------------------------------------------------------------------------
# end docker-library/mysql (v5.7)
# ------------------------------------------------------------------------------
# ------------------------------------------------------------------------------

#
ENV DEBIAN_FRONTEND=dialog

# copy MySQL-Server config
COPY files/mysql-conf.d/* /etc/mysql/conf.d/

# startup script
COPY files/custom/docker-entrypoint.sh /usr/local/bin/

# healthcheck script
COPY files/custom/healthcheck.sh /usr/local/bin/

# other scripts
COPY \
	files/custom/update_db_root_pw.sh \
	files/custom/dbmysql-create_db_and_user.sh \
	files/custom/dbmysql-dump_or_import.sh \
	files/custom/inc-dbmysql.sh \
	/root/

RUN \
	mkdir /root/extDbFiles \
	&& chmod 700 \
			/usr/local/bin/docker-entrypoint.sh \
			/usr/local/bin/healthcheck.sh \
			/root/update_db_root_pw.sh \
			/root/dbmysql-create_db_and_user.sh \
			/root/dbmysql-dump_or_import.sh \
			/root/inc-dbmysql.sh \
	&& chown root:root \
			/usr/local/bin/docker-entrypoint.sh \
			/usr/local/bin/healthcheck.sh \
			/root/update_db_root_pw.sh \
			/root/dbmysql-create_db_and_user.sh \
			/root/dbmysql-dump_or_import.sh \
			/root/inc-dbmysql.sh

# ------------------------------------------------------------------------------

EXPOSE 3306

WORKDIR /root/

ENTRYPOINT ["docker-entrypoint.sh"]
