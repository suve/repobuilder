#!/bin/bash

dnf update --assumeyes --setopt=install_weak_deps=False

dnf install --assumeyes --setopt=install_weak_deps=False \
	findutils make redhat-rpm-config rpm-build rpmdevtools

find /repobuilder/packages -mindepth 2 -maxdepth 2 -name '*.spec' | \
	xargs -d $'\n' rpmspec --query --buildrequires | \
	xargs -d $'\n' dnf install --assumeyes --setopt=install_weak_deps=False
