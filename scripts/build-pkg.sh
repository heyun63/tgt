#!/bin/bash
#
# Copyright (C) 2012 Roi Dayan <roid@mellanox.com>
#

version=$1
release=$2

usage() {
    echo "Usage: `basename $0` version release"
    exit 1
}

if [ $# != 2 ];then
    echo “the number of parameters:$# is not equal to 2.”
    usage
fi
echo "Building version: $version-$release"

DIR=$(cd `dirname $0`; pwd)
BASE=`cd $DIR/.. ; pwd`
_TOP="$BASE/pkg"
SPEC="tgtd.spec"
_CP="/usr/bin/cp"

cp_src() {
    local dest=$1
    $_CP -a conf $dest
    $_CP -a doc $dest
    $_CP -a scripts $dest
    $_CP -a usr $dest
    $_CP -a README $dest
    $_CP -a Makefile $dest
}

check() {
    local rc=$?
    local msg="$1"
    if (( rc )) ; then
        echo $msg
        exit 1
    fi
}

build_rpm() {
    name=scsi-target-utils-$version-$release
    TARBALL=$name.tgz
    SRPM=$_TOP/SRPMS/$name.src.rpm

    echo "Creating rpm build dirs under $_TOP"
    mkdir -p $_TOP/{RPMS,SRPMS,SOURCES,BUILD,SPECS,tmp}
    mkdir -p $_TOP/tmp/$name

    cp_src $_TOP/tmp/$name
    
    echo "Creating tgz $TARBALL"
    tar -czf $_TOP/SOURCES/$TARBALL -C $_TOP/tmp $name
    $_CP $_TOP/tmp/$name/scripts/tgtd $_TOP/SOURCES/
    $_CP $_TOP/tmp/$name/scripts/log4crc $_TOP/SOURCES/

    
    echo "Creating rpm"
    sed -r "s/^Version:(\s*).*/Version:\1$version/;s/^Release:(\s*).*/Release:\1$release/" scripts/$SPEC > $_TOP/SPECS/$SPEC
    rpmbuild -bs --define="_topdir $_TOP" $_TOP/SPECS/$SPEC
    check "Failed to create source rpm."

    rpmbuild -bb --define="_topdir $_TOP" $_TOP/SPECS/$SPEC 2>&1
    check "Failed to build rpm."

    $_CP $_TOP/RPMS/x86_64/$name.x86_64.rpm scripts/
    /usr/bin/rm -rf $_TOP
}

cd $BASE
build_rpm
echo "Done."
