#!/bin/bash
set -u

. /repobuilder/scripts/utils/dist.sh
. /repobuilder/scripts/utils/messages.sh

cd ~

# -- rpmbuild

if [ "$1" != "--reuse" ]; then
	message INFO "image(${dist})" "Installing createrepo, rpmbuild and other base packages..."

	dnf install --assumeyes --setopt=install_weak_deps=False \
		findutils make \
		createrepo_c redhat-rpm-config rpm-build rpmdevtools \
		> dnf.log

	if [ "$?" -ne 0 ]; then
		cp dnf.log /repobuilder/output/
		message FAIL "image(${dist})" "Installing base packages failed; check \"dnf.log\" for more info"
		exit 2
	fi
	message OK "image(${dist})" "Base packages installed successfully"
fi

# -- update

message INFO "image(${dist})" "Updating all packages..."

dnf update --assumeyes --setopt=install_weak_deps=False > dnf.log

if [ "$?" -ne 0 ]; then
	cp dnf.log /repobuilder/output/
	message FAIL "image(${dist})" "Update failed; check \"dnf.log\" for more info"
	exit 1
fi
message OK "image(${dist})" "Update finished"

# -- BuildRequires

message INFO "image(${dist})" "Installing BuildRequires..."

find /repobuilder/packages -mindepth 2 -maxdepth 2 -name '*.spec' | \
	xargs -d $'\n' rpmspec --query --buildrequires | \
	xargs -d $'\n' dnf install --assumeyes --setopt=install_weak_deps=False \
	> dnf.log 2>/dev/null

if [ "$?" -ne 0 ]; then
	cp dnf.log /repobuilder/output/
	message FAIL "image(${dist})" "Installing BuildRequires failed; check \"dnf.log\" for more info"
	exit 3
fi

message OK "image(${dist})" "BuildRequires installed successfully"
