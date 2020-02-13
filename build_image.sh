#!/bin/bash

#
# by TS, Feb 2020
#

VAR_MYNAME="$(basename "$0")"

# ----------------------------------------------------------

# Outputs CPU architecture string
#
# @param string $1 debian_rootfs|debian_dist
#
# @return int EXITCODE
function _getCpuArch() {
	case "$(uname -m)" in
		x86_64*)
			if [ "$1" = "qemu" ]; then
				# NOTE: qemu not available for this CPU architecture
				echo -n "amd64_bogus"
			elif [ "$1" = "alpine_dist" ]; then
				echo -n "x86_64"
			else
				echo -n "amd64"
			fi
			;;
		i686*)
			if [ "$1" = "qemu" ]; then
				echo -n "i386"
			elif [ "$1" = "s6_overlay" -o "$1" = "alpine_dist" ]; then
				echo -n "x86"
			else
				echo -n "i386"
			fi
			;;
		aarch64*)
			if [ "$1" = "debian_rootfs" ]; then
				echo -n "arm64v8"
			elif [ "$1" = "debian_dist" ]; then
				echo -n "arm64"
			elif [ "$1" = "s6_overlay" -o "$1" = "alpine_dist" -o "$1" = "qemu" ]; then
				echo -n "aarch64"
			else
				echo "$VAR_MYNAME: Error: invalid arg '$1'" >/dev/stderr
				return 1
			fi
			;;
		armv7*)
			if [ "$1" = "debian_rootfs" ]; then
				echo -n "arm32v7"
			elif [ "$1" = "debian_dist" ]; then
				echo -n "armhf"
			elif [ "$1" = "s6_overlay" -o "$1" = "qemu" ]; then
				echo -n "armhf"
			elif [ "$1" = "alpine_dist" ]; then
				echo -n "armv7"
			else
				echo "$VAR_MYNAME: Error: invalid arg '$1'" >/dev/stderr
				return 1
			fi
			;;
		*)
			echo "$VAR_MYNAME: Error: Unknown CPU architecture '$(uname -m)'" >/dev/stderr
			return 1
			;;
	esac
	return 0
}

_getCpuArch debian_dist >/dev/null || exit 1

# ----------------------------------------------------------

cd build-ctx || exit 1

# ----------------------------------------------------------

LVAR_GITHUB_BASE="https://raw.githubusercontent.com/tsitle/docker_images_common_files/master"

LVAR_DEBIAN_DIST="$(_getCpuArch debian_dist)"
LVAR_DEBIAN_RELEASE="stretch"
LVAR_DEBIAN_VERSION="9.11"

LVAR_MYSQL_VERSION="5.7"

LVAR_IMAGE_NAME="db-mysql-$LVAR_DEBIAN_DIST"
LVAR_IMAGE_VER="$LVAR_MYSQL_VERSION"

echo

docker build \
		--build-arg CF_CPUARCH_DEB_DIST="$LVAR_DEBIAN_DIST" \
		--build-arg CF_DEBIAN_RELEASE="$LVAR_DEBIAN_RELEASE" \
		--build-arg CF_DEBIAN_VERSION="$LVAR_DEBIAN_VERSION" \
		--build-arg CF_MYSQL_VERSION="$LVAR_MYSQL_VERSION" \
		-t "$LVAR_IMAGE_NAME":"$LVAR_IMAGE_VER" \
		.
