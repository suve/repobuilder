#!/bin/bash

. /repobuilder/scripts/ansi-codes.sh

pkg="$1"
if [ "${pkg:0:9}" == "packages/" ]; then
	pkg="${pkg:9:65535}"
fi

pkgdir="/repobuilder/packages/${pkg}"
if [ ! -d "${pkgdir}" ]; then
	echo "${ANSI_RED}[FAIL]${ANSI_RESET} build(${pkg}): No such directory: \"${pkgdir}\"" >&2
	exit 1
fi

if [ ! -f "${pkgdir}/${pkg}.spec" ]; then
	echo "${ANSI_RED}[FAIL]${ANSI_RESET} build(${pkg}): spec file not found: \"${pkgdir}/${pkg}.spec\"" >&2
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
rpmbuild -bb --nodebuginfo "./rpmbuild/SPECS/${pkg}.spec" 1> "${pkg}.build.log" 2>&1
if [ "$?" -ne 0 ]; then
	cp "${pkg}.build.log" /repobuilder/output/

	echo "${ANSI_RED}[FAIL]${ANSI_RESET} build(${pkg}): rpmbuild failed - check the build log for details" >&2
	exit 1
fi

find ~/rpmbuild/RPMS/ -name '*.rpm' -exec cp '{}' /repobuilder/output/ ';'
echo "${ANSI_GREEN}[ OK ]${ANSI_RESET} build(${pkg}): Finished successfully"
