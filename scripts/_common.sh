#!/bin/bash

#=================================================
# COMMON VARIABLES AND CUSTOM HELPERS
#=================================================

nodejs_version="22"

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

    pushd "$sourcedir/frontend" || ynh_die "Could not pushd $sourcedir/frontend"
        ynh_hide_warnings ynh_exec_as_app node_load_PATH" \
            npm ci --no-audit --ignore-scripts
        ynh_hide_warnings ynh_exec_as_app node_load_PATH" \
            npm run build
        ynh_hide_warnings ynh_exec_as_app node_load_PATH" \
            npm cache clean --force
    popd || ynh_die "Could not popd"

    ynh_safe_rm "$targetdir"
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
