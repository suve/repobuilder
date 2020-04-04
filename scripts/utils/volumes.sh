vol_packages="--volume ./packages:/repobuilder/packages:ro,noexec"
vol_output="--volume ./output/${dist}:/repobuilder/output:rw,noexec"

vol_scripts_container="--volume ./scripts/container:/repobuilder/scripts/container:ro,exec"
vol_scripts_utils="--volume ./scripts/utils:/repobuilder/scripts/utils:ro,exec"
vol_scripts="${vol_scripts_container} ${vol_scripts_utils}"

vol_all="${vol_packages} ${vol_output} ${vol_scripts}"
