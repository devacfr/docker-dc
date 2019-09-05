#!/bin/bash

source ./setenv.sh

# OS specific support.  $var _must_ be set to either true or false.
cygwin=false;
darwin=false;
mingw=false
case "`uname`" in
  CYGWIN*) cygwin=true ;;
  MINGW*) mingw=true;;
esac

dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

if $cygwin ; then
  [ -n "$dir" ] &&
    dir=`cygpath --unix "$dir"`
fi

docker run --name dnsmasq -d	 \
  -p "53:53/udp" \
	-p "5380:8080" \
	-v ${dir}/opt/dnsmasq.conf:/etc/dnsmasq.conf \
	--log-opt "max-size=100m" \
  --cap-add=NET_ADMIN \
	--restart always \
	jpillora/dnsmasq