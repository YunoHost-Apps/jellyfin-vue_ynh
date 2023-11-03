#!/bin/bash

#=================================================
# COMMON VARIABLES
#=================================================

nodejs_version=20

#=================================================
# PERSONAL HELPERS
#=================================================

_patch_config_json() {
    sourcedir=$1

    # Required for sub-path installation
    sed -i \
        "s|'/config.json'|import.meta.env.BASE_URL + 'config.json'|" \
        "$1/frontend/src/utils/external-config.ts"
}

_npm_build_install() {
    sourcedir=$1
    targetdir=$2
    subpath=$3

    pushd "$sourcedir" || ynh_die "Could not pushd $sourcedir"
        ynh_use_nodejs
        ynh_exec_warn_less ynh_exec_as "$app" env "$ynh_node_load_PATH" \
            "$ynh_npm" ci --no-audit --ignore-scripts
        ynh_exec_warn_less ynh_exec_as "$app" env "$ynh_node_load_PATH" \
            "$ynh_npm" run build -- --base="$subpath/"
    popd || ynh_die "Could not popd"

    mv "$sourcedir/frontend/dist" "$targetdir"
}


_list_jellyfin_urls() {
    yunohost app list --full --json \
        | jq -r '.apps[] | select(.manifest.id=="jellyfin") | .domain_path'
}

PYTHON_APPEND_TO_SERVER_URLS='
import sys
import json
file = sys.argv[1]
url = sys.argv[2]
with open(file, encoding="utf-8") as configfile:
    data = json.load(configfile)
if url not in data["defaultServerURLs"]:
    data["defaultServerURLs"].append(url)
with open(file, "w", encoding="utf-8") as configfile:
    configfile.write(json.dumps(data, indent=2))
'

_append_to_server_urls() {
    python3 -c "$PYTHON_APPEND_TO_SERVER_URLS" "$@"
}

#=================================================
# EXPERIMENTAL HELPERS
#=================================================

#=================================================
# FUTURE OFFICIAL HELPERS
#=================================================
