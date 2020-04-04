#!/bin/bash

. /repobuilder/scripts/ansi-codes.sh

cd ~

# -- update

echo "${ANSI_CYAN}[INFO]${ANSI_RESET} image: Updating base packages..."

dnf update --assumeyes --setopt=install_weak_deps=False > dnf.log

if [ "$?" -ne 0 ]; then
	cp dnf.log /repobuilder/output/
	echo "${ANSI_RED}[FAIL]${ANSI_RESET} image: Update failed; check dnf.log for more info"
	exit 1
fi
echo "${ANSI_GREEN}[ OK ]${ANSI_RESET} image: Update finished"

# -- rpmbuild

echo "${ANSI_CYAN}[INFO]${ANSI_RESET} image: Installing rpmbuild and related packages..."

dnf install --assumeyes --setopt=install_weak_deps=False \
	findutils make redhat-rpm-config rpm-build rpmdevtools \
	> dnf.log

if [ "$?" -ne 0 ]; then
	cp dnf.log /repobuilder/output/
	echo "${ANSI_RED}[FAIL]${ANSI_RESET} image: Installing rpmbuild failed; check dnf.log for more info"
	exit 2
fi
echo "${ANSI_GREEN}[ OK ]${ANSI_RESET} image: rpmbuild installed successfully"

# -- BuildRequires

echo "${ANSI_CYAN}[INFO]${ANSI_RESET} image: Installing BuildRequires..."

find /repobuilder/packages -mindepth 2 -maxdepth 2 -name '*.spec' | \
	xargs -d $'\n' rpmspec --query --buildrequires | \
	xargs -d $'\n' dnf install --assumeyes --setopt=install_weak_deps=False \
	> dnf.log 2>/dev/null

if [ "$?" -ne 0 ]; then
	cp dnf.log /repobuilder/output/
	echo "${ANSI_RED}[FAIL]${ANSI_RESET} image: Installing BuildRequires failed; check dnf.log for more info"
	exit 3
fi

echo "${ANSI_GREEN}[ OK ]${ANSI_RESET} image: BuildRequires installed successfully"
