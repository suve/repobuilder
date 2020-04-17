#!/bin/bash
set -u

. /repobuilder/scripts/utils/dist.sh
. /repobuilder/scripts/utils/messages.sh

pkg="$1"
shift

extra_args="$@"

pkgdir="/repobuilder/packages/${pkg}"
if [ ! -d "${pkgdir}" ]; then
	message FAIL "build(${dist}/${pkg})" "No such directory: \"${pkgdir}\""
	exit 1
fi

if [ ! -f "${pkgdir}/${pkg}.spec" ]; then
	message FAIL "build(${dist}/${pkg})" "spec file not found: \"${pkgdir}/${pkg}.spec\""
	exit 1
fi

cd ~
rpmdev-setuptree

cd "${pkgdir}"
for file in *; do
	if [ "$file" == "${pkg}.spec" ]; then
		ln -s "${pkgdir}/${file}" ~/rpmbuild/SPECS
	else
		ln -s "${pkgdir}/${file}" ~/rpmbuild/SOURCES
	fi
done

cd ~
rpmbuild -bb ${extra_args} "./rpmbuild/SPECS/${pkg}.spec" 1> "${pkg}.build.log" 2>&1
if [ "$?" -ne 0 ]; then
	cp "${pkg}.build.log" /repobuilder/output/

	message FAIL "build(${dist}/${pkg})" "rpmbuild failed - check \"${pkg}.build.log\" for details"
	exit 1
fi

find ~/rpmbuild/RPMS/ -name '*.rpm' -exec cp '{}' /repobuilder/output/ ';'
message OK "build(${dist}/${pkg})" "Finished successfully"
