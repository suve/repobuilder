#!/bin/bash
set -u

# !! NOTE
# install-build-requires.sh is a specific script, as it uses exit codes >= 10 to signify an error.
# exit code 1 should still be considered a success.

. /repobuilder/scripts/utils/dist.sh
. /repobuilder/scripts/utils/messages.sh

cd ~

# -- parse args

opt_reuse=0
opt_update=0
packages=""
while [ "$#" -gt 0 ]; do
	if [ "$1" == "--package" ]; then
		packages="$2"
		shift
	elif [ "$1" == "--reuse" ]; then
		opt_reuse=1
	elif [ "$1" == "--update" ]; then
		opt_reuse=1
	else
		message FAIL "image(${dist})" "Unknown option \"$1\" passed to install-build-requires.sh"
		exit 10
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

# -- dnf stats

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

DNF_INSTALLED=0
DNF_UPGRADED=0
DNF_STATS="no change"

function calc_dnf_stats() {
	local all="$(grep -E -e '^(Install|Upgrade)[ ]+[0-9]+[ ]+Packages?$' /var/log/dnf.log)"
	local installed="$(echo "${all}" | grep '^Install' | grep -E --only-matching '[0-9]+' | sed -e 's/^/+ /g' | xargs expr -- 0)"
	local upgraded="$(echo "${all}" | grep '^Upgrade' | grep -E --only-matching '[0-9]+' | sed -e 's/^/+ /g' | xargs expr -- 0)"

	if [ "${installed}" -gt 0 ]; then
		if [ "${upgraded}" -gt 0 ]; then
			DNF_STATS="${installed} new $(plural ${installed}) installed, ${upgraded} $(plural ${upgraded}) updated"
		else
			DNF_STATS="${installed} new $(plural ${installed}) installed"
		fi
	else
		if [ "${upgraded}" -gt 0 ]; then
			DNF_STATS="${upgraded} $(plural ${upgraded}) updated"
		else
			DNF_STATS="no change"
		fi
	fi

	if [ "${installed}" -gt 0 ]; then
		DNF_INSTALLED=$(expr "${DNF_INSTALLED}" '+' "${installed}")
	fi
	if [ "${upgraded}" -gt 0 ]; then
		DNF_UPGRADED=$(expr "${DNF_UPGRADED}" '+' "${upgraded}")
	fi

	rm /var/log/dnf.log
}

# -- rpmbuild

if [ "${opt_reuse}" -eq 0 ]; then
	message INFO "image(${dist}/pkgs)" "Installing createrepo, rpmbuild and other base packages..."

	dnf install --assumeyes --setopt=install_weak_deps=False \
		findutils make \
		createrepo_c redhat-rpm-config rpm-build rpmdevtools \
		> dnf.log

	if [ "$?" -ne 0 ]; then
		cp dnf.log /repobuilder/output/
		message FAIL "image(${dist}/pkgs)" "Installing base packages failed; check \"dnf.log\" for more info"
		exit 11
	fi

	calc_dnf_stats
	message OK "image(${dist}/pkgs)" "Base packages installed successfully (${DNF_STATS})"
fi

# -- update

if [ "${opt_update}" -eq 1 ]; then
	message INFO "image(${dist}/pkgs)" "Updating all packages..."

	dnf update --assumeyes --setopt=install_weak_deps=False > dnf.log

	if [ "$?" -ne 0 ]; then
		cp dnf.log /repobuilder/output/
		message FAIL "image(${dist}/pkgs)" "Update failed; check \"dnf.log\" for more info"
		exit 12
	fi

	calc_dnf_stats
	message OK "image(${dist}/pkgs)" "Update finished (${DNF_STATS})"
fi

# -- BuildRequires

message INFO "image(${dist}/pkgs)" "Installing BuildRequires..."

echo "${specfiles}" | \
	xargs -d $'\n' rpmspec --query --buildrequires 2>/dev/null | \
	xargs -d $'\n' dnf install --best --assumeyes --setopt=install_weak_deps=False \
	> dnf.log 2>/dev/null

if [ "$?" -ne 0 ]; then
	cp dnf.log /repobuilder/output/
	message FAIL "image(${dist}/pkgs)" "Installing BuildRequires failed; check \"dnf.log\" for more info"
	exit 13
fi

calc_dnf_stats
message OK "image(${dist}/pkgs)" "BuildRequires installed successfully (${DNF_STATS})"

if [[ "${DNF_INSTALLED}" -gt 0 ]] || [[ "${DNF_UPGRADED}" -gt 0 ]]; then
	exit 1
else
	exit 0
fi

