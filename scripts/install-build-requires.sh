#!/bin/bash

dnf install --assumeyes --setopt=install_weak_deps=False \
	findutils redhat-rpm-config rpm-build rpmdevtools xargs

find /packages -mindepth 2 -maxdepth 2 -name '*.spec' | \
	xargs -d $'\n' rpmspec --query --buildrequires | \
	xargs -d $'\n' dnf install --assumeyes --setopt=install_weak_deps=False
