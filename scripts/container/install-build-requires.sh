#!/bin/bash
set -u

. /repobuilder/scripts/utils/dist.sh
. /repobuilder/scripts/utils/messages.sh

cd ~

# -- parse args

opt_reuse=0
packages=""
while [ "$#" -gt 0 ]; do
	if [ "$1" == "--package" ]; then
		packages="$2"
		shift
	elif [ "$1" == "--reuse" ]; then
		opt_reuse=1
	else
		message FAIL "image(${dist})" "Unknown option \"$1\" passed to install-build-requires.sh"
		exit 1
	fi
	shift
done

specfiles=""
if [ "${packages}" != "" ]; then
	for pkg in ${packages}; do
		specfiles="/repobuilder/packages/${pkg}/${pkg}.spec"$'\n'"${specfiles}"
	done
else	
	specfiles="$(find /repobuilder/packages -mindepth 2 -maxdepth 2 -name '*.spec')"
fi

# -- functions

# Remove the dnf log so we have a clean slate
rm -f /var/log/dnf.log*

function plural() {
	local number="$1"

	if [ "${number}" -eq 1 ]; then
		echo "package"
	else
		echo "packages"
	fi
}

function dnf_stats() {
	local all="$(grep -E -e '^(Install|Upgrade)[ ]+[0-9]+[ ]+Packages?$' /var/log/dnf.log)"
	local installed="$(echo "${all}" | grep '^Install' | grep -E --only-matching '[0-9]+' | sed -e 's/^/+ /g' | xargs expr -- 0)"
	local upgraded="$(echo "${all}" | grep '^Upgrade' | grep -E --only-matching '[0-9]+' | sed -e 's/^/+ /g' | xargs expr -- 0)"

	if [ "${installed}" -gt 0 ]; then
		if [ "${upgraded}" -gt 0 ]; then
			echo "${installed} new $(plural ${installed}) installed, ${upgraded} $(plural ${upgraded}) updated"
		else
			echo "${installed} new $(plural ${installed}) installed"
		fi
	else
		if [ "${upgraded}" -gt 0 ]; then
			echo "${upgraded} $(plural ${upgraded}) updated"
		else
			echo "no change"
		fi
	fi

	rm /var/log/dnf.log
}

# -- rpmbuild

if [ "${opt_reuse}" -eq 0 ]; then
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
	message OK "image(${dist})" "Base packages installed successfully ($(dnf_stats))"
fi

# -- update

message INFO "image(${dist})" "Updating all packages..."

dnf update --assumeyes --setopt=install_weak_deps=False > dnf.log

if [ "$?" -ne 0 ]; then
	cp dnf.log /repobuilder/output/
	message FAIL "image(${dist})" "Update failed; check \"dnf.log\" for more info"
	exit 1
fi
message OK "image(${dist})" "Update finished ($(dnf_stats))"

# -- BuildRequires

message INFO "image(${dist})" "Installing BuildRequires..."

echo "${specfiles}" | \
	xargs -d $'\n' rpmspec --query --buildrequires | \
	xargs -d $'\n' dnf install --assumeyes --setopt=install_weak_deps=False \
	> dnf.log 2>/dev/null

if [ "$?" -ne 0 ]; then
	cp dnf.log /repobuilder/output/
	message FAIL "image(${dist})" "Installing BuildRequires failed; check \"dnf.log\" for more info"
	exit 3
fi

message OK "image(${dist})" "BuildRequires installed successfully ($(dnf_stats))"
