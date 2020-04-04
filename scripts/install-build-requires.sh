#!/bin/bash

. /repobuilder/scripts/messages.sh

cd ~

# -- update

message INFO "image" "Updating base packages..."

dnf update --assumeyes --setopt=install_weak_deps=False > dnf.log

if [ "$?" -ne 0 ]; then
	cp dnf.log /repobuilder/output/
	message FAIL "image" "Update failed; check \"dnf.log\" for more info"
	exit 1
fi
message OK "image" "Update finished"

# -- rpmbuild

message INFO "image" "Installing rpmbuild and related packages..."

dnf install --assumeyes --setopt=install_weak_deps=False \
	findutils make redhat-rpm-config rpm-build rpmdevtools \
	> dnf.log

if [ "$?" -ne 0 ]; then
	cp dnf.log /repobuilder/output/
	message FAIL "image" "Installing rpmbuild failed; check \"dnf.log\" for more info"
	exit 2
fi
message OK "image" "rpmbuild installed successfully"

# -- BuildRequires

message INFO "image" "Installing BuildRequires..."

find /repobuilder/packages -mindepth 2 -maxdepth 2 -name '*.spec' | \
	xargs -d $'\n' rpmspec --query --buildrequires | \
	xargs -d $'\n' dnf install --assumeyes --setopt=install_weak_deps=False \
	> dnf.log 2>/dev/null

if [ "$?" -ne 0 ]; then
	cp dnf.log /repobuilder/output/
	message FAIL "image" "Installing BuildRequires failed; check \"dnf.log\" for more info"
	exit 3
fi

message OK "image" "BuildRequires installed successfully"
