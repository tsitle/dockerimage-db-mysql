#!/bin/bash

set -eo pipefail

[ -z "$CF_DB_ROOT_PASSWORD" ] && exit 1

TMP_CHECK="$(echo 'SELECT 1;' | mysql -h127.0.0.1 -uroot -p${CF_DB_ROOT_PASSWORD} 2>/dev/null | head -n1)"

[ "${TMP_CHECK}" = "1" ] && exit 0

exit 1
