# MySQL DB-Server Docker Image for AARCH64, ARMv7l, X86 and X64

Provides a MySQL database server.

## DB-Server TCP Port
The DB-Server is listening on TCP port 3306 by default.

## Healthcheck script
The image also contains a healthcheck script at `/usr/local/bin/healthcheck.sh`.  
This script can be used in a docker-compose.yaml file like this:

```
version: '3.5'
services:
  db:
    image: "db-mysql-<ARCH>:<VERSION>"
    ports:
      - "3306:3306"
    volumes:
      - "$PWD/mpdata/mysql/<VERSION>/intern:/var/lib/mysql"
      - "$PWD/mpdata/mysql/<VERSION>/extern:/root/extDbFiles"
    environment:
      - CF_SYSUSR_MYSQL_USER_ID=<YOUR_UID>
      - CF_SYSUSR_MYSQL_GROUP_ID=<YOUR_GID>
      - CF_DB_ROOT_PASSWORD=<PASSWORD>
    healthcheck:
      test: ["CMD", "/usr/local/bin/healthcheck.sh"]
      interval: 30s
      timeout: 10s
      retries: 5
```

## Docker Container usage
See the related GitHub repository [https://github.com/tsitle/dockercontainer-db-mysql](https://github.com/tsitle/dockercontainer-db-mysql)

## Docker Container configuration
- CF\_SYSUSR\_MYSQL\_USER\_ID [int]: User-ID for user that ownes the database files
- CF\_SYSUSR\_MYSQL\_GROUP\_ID [int]: Group-ID for group that ownes the database files
- CF\_MYSQL\_MAX\_ALLOWED\_PACKET [string]: Size string (e.g. "128M")
- CF\_MYSQL\_INNODB\_BUFFER\_POOL\_SIZE [string]: Size string (e.g. "8G")
- CF\_MYSQL\_INNODB\_LOG\_FILE\_SIZE [string]: Size string (e.g. "64M")
- CF\_MYSQL\_SQLMODE [string]: List of options for sql_mode (e.g. "STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO")
- CF\_LANG [string]: Language to use (en\_EN.UTF-8 or de\_DE.UTF-8)
- CF\_TIMEZONE [string]: Timezone (e.g. 'Europe/Berlin')

Only when the internal data directory doesn't already exist:

- CF\_ENABLE\_DB\_INIT\_DEBUG [bool]: Enable debugging output when DB is initialized?  
Warning: This will print DB user passwords to the log output
- CF\_DB\_ROOT\_PASSWORD [string]: Password for DB root user (>= 4 chars)
- to create a new DB scheme when a container is started:
	- CF\_DB\_USER\_NAME [string]: Create a DB user with this name
	- CF\_DB\_USER\_PASS [string]: Password for CF\_DB\_USER\_NAME (>= 4 chars)
	- CF\_DB\_SCHEME\_NAME [string]: Create a DB scheme that CF\_DB\_USER\_NAME can access
