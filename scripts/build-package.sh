#!/bin/bash

pkg="$1"
pkgdir="/repobuilder/packages/${pkg}"
if [ ! -d "${pkgdir}" ]; then
	echo "No such directory: \"${pkgdir}\"" >&2
	exit 1
fi

if [ ! -f "${pkgdir}/${pkg}.spec" ]; then
	echo "Spec file not found: \"${pkgdir}/${pkg}.spec\"" >&2
	exit 1
fi

cd ~
rpmdev-setuptree

cd "${pkgdir}"
for file in $(ls ./); do
	if [ "$file" == "${pkg}.spec" ]; then
		ln -s "${pkgdir}/${file}" ~/rpmbuild/SPECS
	else
		ln -s "${pkgdir}/${file}" ~/rpmbuild/SOURCES
	fi
done

cd ~
rpmbuild -bb --nodebuginfo "./rpmbuild/SPECS/${pkg}.spec"

find ~/rpmbuild/RPMS/ -name '*.rpm' -exec cp '{}' /repobuilder/output/ ';'
