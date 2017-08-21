#!/bin/bash -e

set -x

# parse arguments
s=0
OPTIONS=`getopt -n "$0" -o "" -l "outdir:,url:,debian-branch:,revision:,enable-submodules:,enable-pristine-tar:" -- "$@"` || s=$?
if [ $s -ne 0 ]; then
	# usage
	exit 1
fi

# evaluate arguments
_outdir=
_url=
_debianbranch=master
_revision=HEAD
_enablesubmodules=no
_enablepristinetar=no
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
		--debian-branch)
			_debianbranch=$2
			shift 2
			;;
		--revision)
			_revision=$2
			shift 2
			;;
		--enable-submodules)
			_enablesubmodules=$2
			shift 2
			;;
		--enable-pristine-tar)
			_enablepristinetar=$2
			shift 2
			;;
		--)
			shift
			break
			;;
	esac
done

# check if all required arguments have been given
if [ -z "$_outdir" ] || [ -z "$_url" ] \
|| ( [ "x$_enablesubmodules" != "xno" ] && [ "x$_enablesubmodules" != "xyes" ] ) \
|| ( [ "x$_enablepristinetar" != "xno" ] && [ "x$_enablepristinetar" != "xyes" ] ); then
	echo "Mandatory arguments missing, or have invalid values!"
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
git clone --branch "$_debianbranch" "$_url" "repo" || r=$?
if [ $r != 0 ]; then
	echo "An error occured while cloning the remote repository!"
	cleanup
	exit 1
fi

# check out user-select commit/tag
pushd "repo"
r=0
git checkout -b $_debianbranch-$_revision $_revision 2>&1 >/dev/null || r=$?
popd
if [ $r != 0 ]; then
	echo "An error occured while checking out the requested revision!"
	cleanup
	exit 1
fi

# checkout-out submodules if requested
pushd "repo"
if [ "x$_enablesubmodules" = "xyes" ]; then
	r=0
	git submodule update --init 2>&1 >/dev/null || r=$?
	if [ $r != 0 ]; then
		echo "An error occured while checking out submodules!"
		cleanup
		exit 1
	fi
fi
popd

# save a timestamp to decide between new and old files
touch * timestamp

# find out source package name and version to guess source folder name
s=0
sourcepkgname=$(dpkg-parsechangelog -lrepo/debian/changelog | grep "Source: " | sed -e "s;^Source: ;;") || s=$?
sourcepkgversion=$(dpkg-parsechangelog -lrepo/debian/changelog | grep "Version: " | sed -e "s;^Version: ;;" -e "s;-*;;g") || s=$?
if [ $s -eq 0 ]; then
	# rename folder
	mv repo $sourcepkgname-$sourcepkgversion

	# and save its name
	repotree=$sourcepkgname-$sourcepkgversion
else
	# if package name or version couldn't be guessed, just continue
	repotree="repo"
fi

# deal with pristine-tar
if [ "x$_enablepristinetar" = "xyes" ]; then
	# make sure the pristine-tar branch exists locally
	pushd "$repotree"
	git branch --track pristine-tar origin/pristine-tar
	popd

	# generate argument to gbp-buildpackage
	PRISTINETAR=--git-pristine-tar
else
	# generate argument to gbp-buildpackage
	PRISTINETAR=--git-no-pristine-tar
fi

# build source package
pushd "$repotree"
r=0
gbp buildpackage --git-ignore-branch --git-builder="dpkg-source -i.git -b ." $PRISTINETAR || r=$?
popd
if [ $r != 0 ]; then
	echo "An error occured while creating the source package!"
	cleanup
	exit 1
fi

# move created files to outdir
r=0
find . -maxdepth 1 -type f -cnewer timestamp -exec mv {} "$_outdir/" \; || r=$?
if [ $r != 0 ]; then
	echo "An error occured while moving the generated files to their destination!"
	cleanup
	exit 1
fi

# all done
cleanup
echo "Done"
exit 0
