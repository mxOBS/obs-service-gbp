#!/bin/bash -e

# parse arguments
s=0
OPTIONS=`getopt -n "$0" -o "" -l "outdir:,url:,revision:" -- "$@"` || s=$?
if [ $s -ne 0 ]; then
	# usage
	exit 1
fi

# evaluate arguments
_outdir=
_url=
_revision=
eval set -- "$OPTIONS"
while true; do
	case $1 in
		--outdir)
			_outdir="$2"
			shift 2
			;;
		--url)
			_url="$2"
			shift 2
			;;
		--revision)
			_revision=$2
			shift 2
			;;
		--)
			shift
			break
			;;
	esac
done

# check if all required arguments have been given
if [ -z "$_outdir" ] || [ -z "$_url" ] || [ -z "$_revision" ]; then
	echo "Mandatory arguments missing!"
	exit 1
fi

# check that git-buildpackage is actually installed
r=0
which gbp 2>&1 >/dev/null || r=$?
if [ $r != 0 ]; then
	echo "gbp (git-buildpackage) not found in the PATH!"
	exit 1
fi

# check that git is installed
r=0
which git 2>&1 >/dev/null || r=$?
if [ $r != 0 ]; then
	echo "git not found in the PATH!"
	exit 1
fi

# cleanup function to use on errors
function cleanup() {
	rm -rf *
}

# clone repository
r=0
git clone "$_url" "repo" || r=$?
if [ $r != 0 ]; then
	echo "An error occured while cloning the remote repository!"
	cleanup
	exit 1
fi

# check out user-select branch/commit/tag
pushd "repo"
r=0
git checkout $_revision 2>&1 >/dev/null || r=$?
popd
if [ $r != 0 ]; then
	echo "An error occured while checking out the requested revision!"
	cleanup
	exit 1
fi

# build source package
pushd "repo"
r=0
gbp buildpackage --git-force-create --git-ignore-branch --git-builder="dpkg-source -i.git -b ." || r=$?
popd
if [ $r != 0 ]; then
	echo "An error occured while creating the source package!"
	cleanup
	exit 1
fi

# move created files to outdir
r=0
find . -maxdepth 1 -type f -exec mv {} "$_outdir/" \; || r=$?
if [ $r != 0 ]; then
	echo "An error occured while moving the generated files to their destination!"
	cleanup
	exit 1
fi

# all done
cleanup
echo "Done"
exit 0
