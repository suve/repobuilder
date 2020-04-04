vol_packages="--volume ./packages:/repobuilder/packages:ro,noexec"
vol_output="--volume ./output/${dist}:/repobuilder/output:rw,noexec"
vol_scripts="--volume ./scripts:/repobuilder/scripts:ro,exec"
vol_all="${vol_packages} ${vol_output} ${vol_scripts}"
