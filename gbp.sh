#!/bin/bash

# handle commandline arguments
_url=
_revision=
eval set -- "$OPTIONS"
while true; do
	case $1 in
		--url)
			_url="$2"
			;;
		--revision)
			_revision=$2
			;;
	esac
	shift 2
done

if [ -z "$url" ] || [ -z "$revision" ]; then
	echo "Mandatory arguments missing, cannot continue!"
	exit 1
fi

echo "Done"
exit 0
